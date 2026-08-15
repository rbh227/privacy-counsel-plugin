#!/usr/bin/env python3
"""Fail when "the partner" starts a sentence in lowercase.

Why this is not a grep: this corpus hard-wraps Markdown at ~72 columns, so a
LINE start is not a SENTENCE start. Anchoring on `^` both misses real hits
(`- the partner ...`, `> the partner ...`, `| the partner |`) and fires on
correct prose (a wrapped line that merely happens to begin "the partner
decides, not Claude.", or an abbreviation period as in "(e.g. the partner
asks ...)"). So: unwrap each block into logical lines, strip Markdown
prefixes, then locate real sentence boundaries before matching.

Usage: check-sentence-case.py PATH [PATH ...]   # files or directories
       check-sentence-case.py --self-test       # tokenizer regression cases
Prints `path:line: text` for each hit; exit 1 if any, 0 if clean.
"""

import os
import re
import sys

TARGET = re.compile(r"the partner\b")

# A physical line that opens a new logical line rather than continuing one.
STRUCTURAL = re.compile(
    r"""^[ \t]*(
          \#{1,6}\s        # heading
        | [-*+]\s          # bullet
        | \d+[.)]\s        # ordered item
        | >                # blockquote
        | \|               # table row
        | (-{3,}|\*{3,}|_{3,})[ \t]*$   # horizontal rule
    )""",
    re.VERBOSE,
)

# Leading Markdown furniture to strip before looking for sentence starts.
PREFIX = re.compile(
    r"^[ \t]*(?:>[ \t]*)*(?:\#{1,6}[ \t]+|[-*+][ \t]+|\d+[.)][ \t]+)?"
)

# Characters that may sit between a sentence start and its first word.
OPENERS = "*_`\"'([{~"

FENCE = re.compile(r"^[ \t]*(```|~~~)")

# A period that ends one of these is an abbreviation, not a sentence end.
ABBREV = re.compile(
    r"(?:"
    r"\b(?:e\.g|i\.e|etc|cf|viz|resp|approx|art|arts|no|nos|inc|ltd|llc|co|"
    r"corp|plc|sec|secs|reg|regs|ch|para|paras|pp|al|vs|v|ff|fig|figs|ed|eds|"
    r"dr|mr|mrs|ms|jr|sr|st|mo|yr|min|max)\."
    r"|\b[A-Za-z]\."          # single initial: the "S." of "U.S.", "e.g."
    r")$",
    re.IGNORECASE,
)

# End of a sentence: . ! or ? possibly closed off, then whitespace.
BOUNDARY = re.compile(r"[.!?][\"')\]]*\s+")

# Spans whose insides are not prose: inline code and link destinations. The
# period in `config.md. the partner` or in a URL is punctuation inside a
# token, not the end of a sentence.
CODE_SPAN = re.compile(r"(`+)(.+?)\1", re.DOTALL)
LINK_DEST = re.compile(r"\]\(([^)]*)\)")


def mask_spans(text):
    """Blank out code/link interiors, preserving length so offsets stay valid.

    Two false positives die here: a boundary invented by a period inside a
    span, and a "the partner" that is a code sample rather than prose.
    """
    out = list(text)
    for pattern, group in ((CODE_SPAN, 2), (LINK_DEST, 1)):
        for m in pattern.finditer(text):
            for i in range(m.start(group), m.end(group)):
                if not out[i].isspace():
                    out[i] = "x"
    return "".join(out)


def sentence_starts(text):
    """Offsets in `text` where a sentence begins."""
    starts = [0]
    for m in BOUNDARY.finditer(text):
        if ABBREV.search(text[: m.start() + 1]):
            continue
        starts.append(m.end())
    return starts


def logical_lines(lines):
    """Yield (first_physical_lineno, unwrapped_text) per logical line."""
    buf, start_no, in_fence = [], None, False

    def flush():
        nonlocal buf, start_no
        if buf:
            yielded = (start_no, " ".join(buf))
            buf, start_no = [], None
            return yielded
        return None

    for no, raw in enumerate(lines, 1):
        if FENCE.match(raw):
            out = flush()
            if out:
                yield out
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if not raw.strip():
            out = flush()
            if out:
                yield out
            continue
        if STRUCTURAL.match(raw) or not buf:
            out = flush()
            if out:
                yield out
            buf, start_no = [raw.strip()], no
        else:
            buf.append(raw.strip())
    out = flush()
    if out:
        yield out


def segments(text):
    """Split a logical line into segments, each paired with whether its START
    is a sentence start.

    A table cell is a fragment, not a sentence: `| Reviewer | the partner |`
    is correct prose. Flagging it was worse than useless — the documented way
    out was to allowlist the whole file, which blinded the pronoun check
    across every line in it. So a cell's start is never a sentence start;
    only a real boundary inside the cell is.
    """
    body = PREFIX.sub("", text)
    if body.lstrip().startswith("|"):
        return [(cell.strip(), False) for cell in body.split("|")]
    return [(body, True)]


def check_file(path):
    try:
        lines = open(path, encoding="utf-8").read().splitlines()
    except (OSError, UnicodeDecodeError):
        return []
    return [(path, no, text) for no, text in check_lines(lines)]


# Cases the checker got wrong before, plus the ones it must keep catching.
# Run by scripts/static-checks.sh, so a tokenizer change that reintroduces a
# false positive fails the commit rather than teaching someone to allowlist
# a whole vendored skill.
SELF_TEST = [
    ("| Reviewer | the partner |", False, "table cell is a fragment"),
    ("| Note | Done. the partner signs. |", True, "real boundary inside a cell"),
    ("Use `config.md. the partner` in the path.", False, "period inside inline code"),
    ("See [docs](http://x.io/a.b) the partner reads it.", False, "link destination"),
    ("A sentence. the partner reviews it.", True, "plain violation"),
    ("- the partner reviews it.", True, "bullet opens a sentence"),
    ("Ask (e.g. the partner) about it.", False, "abbreviation, not a boundary"),
    ("Signed by the partner. Done.", False, "mid-sentence mention"),
    ("The partner reviews it.", False, "correctly capitalized"),
]


def self_test():
    bad = 0
    for text, want_hit, why in SELF_TEST:
        got = bool(check_lines(text.splitlines()))
        if got != want_hit:
            bad += 1
            print(f"self-test FAIL ({why}): {text!r} → hit={got}, wanted {want_hit}")
    if bad:
        print(f"check-sentence-case self-test: {bad} of {len(SELF_TEST)} failed")
    return 1 if bad else 0


def check_lines(lines):
    """check_file's logic against in-memory lines (used by the self-test)."""
    hits = []
    for no, text in logical_lines(lines):
        for seg, start_is_sentence in segments(text):
            masked = mask_spans(seg)
            starts = sentence_starts(masked)
            if not start_is_sentence and starts and starts[0] == 0:
                starts = starts[1:]
            for pos in starts:
                rest = masked[pos:].lstrip(OPENERS)
                if TARGET.match(rest):
                    hits.append((no, seg[:100]))
                    break
            else:
                continue
            break
    return hits


def main(argv):
    if "--self-test" in argv:
        return self_test()
    targets = []
    for arg in argv:
        if os.path.isdir(arg):
            for root, dirs, files in os.walk(arg):
                dirs[:] = [d for d in dirs if not d.startswith(".")]
                targets += [
                    os.path.join(root, f) for f in sorted(files) if f.endswith(".md")
                ]
        elif arg.endswith(".md"):
            targets.append(arg)
    hits = [h for t in sorted(targets) for h in check_file(t)]
    for path, no, text in hits:
        print(f"{path}:{no}: {text}")
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
