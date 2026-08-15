#!/usr/bin/env bash
# Static checks for the privacy-counsel plugin. Fast, token-free, run before every commit.
set -u
cd "$(dirname "$0")/.."
fail=0
err() { echo "FAIL: $1"; fail=1; }

# 1. Hook syntax
for h in hooks/*.sh; do bash -n "$h" || err "bash syntax: $h"; done

# 2. Manifest JSON validity
for j in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
  python3 -m json.tool "$j" > /dev/null 2>&1 || err "invalid JSON: $j"
done

# 3. Zero personal references.
#    The names this plugin was de-personalized FROM are deliberately not
#    written here: a check that greps for a name has to spell it, and this
#    repo is public. Supply them at run time instead —
#      PC_FORBIDDEN_NAMES='Smith|\bJane\b' scripts/static-checks.sh
#    — which is what the maintainer runs, while the published check carries
#    nothing to leak. The de-personalization ARTIFACTS (stray pronouns,
#    broken possessives, sentence case) are caught unconditionally by 7a-7c.
if [ -n "${PC_FORBIDDEN_NAMES:-}" ]; then
  refscan() {
    grep -rnE "$PC_FORBIDDEN_NAMES" --include="*.md" --include="*.json" --include="*.sh" . \
      | grep -v "^\./\.git/" | grep -v "^\./\.scratch/runs/" \
      | grep -v "scripts/static-checks.sh"
  }
  if refscan | grep -q .; then
    refscan
    err "personal reference found (PC_FORBIDDEN_NAMES)"
  fi
fi

# 4. Every skill hidden
for s in skills/*/SKILL.md; do
  grep -q "user-invocable: false" "$s" || err "skill not hidden: $s"
done

# 5. No stale upstream config paths in shipped skills/profile
if grep -rn "plugins/config/claude-for-legal" skills profile commands hooks references 2>/dev/null | grep -q .; then
  grep -rn "plugins/config/claude-for-legal" skills profile commands hooks references
  err "upstream config path survived adaptation"
fi

# 6. No stale predecessor-plugin name in shipped files. Same reasoning as
#    check 3: naming it here would publish it. Supply it at run time,
#    alongside the personal names, via PC_FORBIDDEN_NAMES.

# 7a. Grammar audit: no gendered pronouns for the user (de-personalization artifacts).
#     Deliberately BROAD — the historical artifacts sit nowhere near the words
#     "partner"/"user", so a narrower pattern would have near-zero recall.
#     Escape hatch for legitimate third-party legal prose in files we must not
#     edit (vendored Apache-2.0 imports): scripts/static-checks-allow.txt path
#     prefixes, or an inline `<!-- static-checks: allow-pronoun -->` marker.
#     Scans shipped prose only — LICENSE/NOTICE files are excluded on purpose.
#     An allowlist entry may be content-scoped — `<path-prefix>::<substring>`
#     exempts only lines containing that substring, so exempting one line of
#     third-party legal prose no longer blinds the check across the rest of
#     the file. Bare path prefixes still work (verbatim vendored files that
#     must not be edited at all), and any entry that stops matching anything
#     fails the build rather than rotting into a silent hole.
SHIPPED="skills profile commands hooks references README.md TESTING.md VENDORED.md STATE.md"
ALLOWFILE="${ALLOWFILE:-scripts/static-checks-allow.txt}"
STALEFILE="$(mktemp -t pc-allow-stale)"
trap 'rm -f "$STALEFILE"' EXIT

pron_hits="$(grep -rniwE "he|him|his" $SHIPPED 2>/dev/null | awk -v allowfile="$ALLOWFILE" '
    BEGIN {
      n = 0
      while ((getline line < allowfile) > 0) {
        sub(/[ \t]+$/, "", line); sub(/^[ \t]+/, "", line)
        if (line == "" || line ~ /^#/) continue
        n++
        raw[n] = line
        sep = index(line, "::")
        if (sep > 0) { apath[n] = substr(line, 1, sep - 1); atext[n] = substr(line, sep + 2) }
        else         { apath[n] = line; atext[n] = "" }
      }
    }
    {
      if (index($0, "static-checks: allow-pronoun") > 0) next
      path = $0; sub(/:.*/, "", path)
      for (i = 1; i <= n; i++) {
        if (index(path, apath[i]) != 1) continue
        if (atext[i] != "" && index($0, atext[i]) == 0) continue
        used[i] = 1
        next
      }
      print
    }
    END { for (i = 1; i <= n; i++) if (!used[i]) print raw[i] > "'"$STALEFILE"'" }
')"
if [ -n "$pron_hits" ]; then
  printf '%s\n' "$pron_hits"
  err "gendered pronoun referring to the user (use they/them, restructure, or allowlist it — see scripts/static-checks-allow.txt)"
fi
if [ -s "$STALEFILE" ]; then
  sed 's/^/  exempts nothing: /' "$STALEFILE"
  err "stale allowlist entry — delete it or fix its path/substring"
fi

# 7b. Grammar audit: "the partner" must not start a sentence in lowercase.
#     Delegated to a real parser: this corpus hard-wraps at ~72 columns, so a
#     line start is not a sentence start and no line-anchored regex can tell
#     the difference. See scripts/check-sentence-case.py.
# 7c. Grammar audit: a de-personalized possessive that lost its apostrophe.
#     "<name>'s playbook" → find-replace on the name → "the partner playbook".
#     All seven vendored §4(b) notices carried this; 7a and 7b cannot see it
#     (no pronoun, no sentence start). The noun list is deliberately short —
#     only words that read as possessed objects, never verbs.
POSSNOUNS="playbook|practice|voice|register|standard|position|preference|edit|review|note|memo|draft|judgment|matter|firm"
if grep -rniE "the partner ($POSSNOUNS)\b" $SHIPPED 2>/dev/null | grep -q .; then
  grep -rniE "the partner ($POSSNOUNS)\b" $SHIPPED 2>/dev/null
  err "de-personalized possessive missing its apostrophe (\"the partner playbook\" → \"the partner's playbook\", or restructure)"
fi

if ! python3 scripts/check-sentence-case.py --self-test; then
  err "check-sentence-case tokenizer regression (see its SELF_TEST cases)"
fi
if ! python3 scripts/check-sentence-case.py $SHIPPED; then
  err "lowercase 'the partner' starting a sentence"
fi

# 9. Apache-2.0 §4(b): attribution and reality must agree, in both directions.
#    VENDORED.md's table is the source of truth. A vendored skill missing its
#    modification notice is a redistribution defect; a notice on a skill the
#    table does not list means someone imported code and never recorded it.
[ -f LICENSE ] || err "no root LICENSE (Apache-2.0 required)"
[ -f NOTICE ] || err "no NOTICE file"
listed="$(sed -n 's/^| `skills\/\([a-z-]*\)` .*/\1/p' VENDORED.md | sort -u)"
noticed="$(grep -rl "MODIFIED from anthropics/claude-for-legal" skills 2>/dev/null \
           | sed 's|^skills/*||; s|/SKILL\.md$||' | sort -u)"
for s in $listed; do
  case "
$noticed" in *"
$s"*) ;; *) err "VENDORED.md lists skills/$s as vendored but it carries no §4(b) modification notice" ;; esac
done
for s in $noticed; do
  case "
$listed" in *"
$s"*) ;; *) err "skills/$s carries a vendored-code notice but VENDORED.md does not list it" ;; esac
done

# 8. Harness self-test — pure bash, no tokens. An assertion helper that
#    cannot fail is worse than no assertion, so this runs on every commit.
if [ -x tests/selftest.sh ]; then
  tests/selftest.sh > /dev/null 2>&1 || { tests/selftest.sh; err "harness self-test failed"; }
fi

[ $fail -eq 0 ] && echo "static checks: OK"
exit $fail
