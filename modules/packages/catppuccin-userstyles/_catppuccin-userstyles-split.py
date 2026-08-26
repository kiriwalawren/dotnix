#!/usr/bin/env python3
"""`@-moz-document` only takes effect in privileged sheets, not the plain
<style> a content script injects into a page (Firefox bug 1035091), so
Stylus needs the real domain/url-prefix/regexp targets in its own
sections[].domains/urlPrefixes/regexps fields, not left embedded in the
code where Gecko silently ignores them.

Splits a compiled catppuccin userstyle into:
  - stdout: the bare CSS rules inside the outermost `@-moz-document { ... }`
    block (or the whole input, unchanged, if no such block is found)
  - stderr: one "<type>\t<value>" line per matcher call found in the
    `@-moz-document <matchers> { ... }` header

A plain regex can't find the right `{`/`}` boundaries here: matcher
strings can themselves contain braces (e.g. a `{2}` regex quantifier) and
parens (nested groups), and some files have Less content (e.g. a mixin
definition) after the closing brace of the block. This scans character by
character instead, treating quoted string content as opaque so braces and
parens inside matcher strings can't be mistaken for structural ones.
"""

import re
import sys


def skip_string(text, i):
    j = i + 1
    n = len(text)
    while j < n:
        c = text[j]
        if c == "\\":
            j += 2
            continue
        if c == '"':
            return j + 1
        j += 1
    return j


def main():
    with open(sys.argv[1]) as f:
        text = f.read()

    keyword = "@-moz-document"
    start = text.find(keyword)
    if start == -1:
        sys.stdout.write(text)
        return

    n = len(text)
    i = start + len(keyword)
    matchers = []
    brace_at = None
    while i < n:
        c = text[i]
        if c == '"':
            j = skip_string(text, i)
            matchers.append(text[i:j])
            i = j
            continue
        if c == "{":
            brace_at = i
            break
        matchers.append(c)
        i += 1

    if brace_at is None:
        sys.stdout.write(text)
        return

    depth = 0
    body_start = brace_at + 1
    body_end = None
    j = brace_at
    while j < n:
        c = text[j]
        if c == '"':
            j = skip_string(text, j)
            continue
        if c == "{":
            depth += 1
            j += 1
            continue
        if c == "}":
            depth -= 1
            if depth == 0:
                body_end = j
                break
            j += 1
            continue
        j += 1

    if body_end is None:
        sys.stdout.write(text)
        return

    sys.stdout.write(text[body_start:body_end])

    matcher_text = "".join(matchers)
    for m in re.finditer(
        r'\b(domain|regexp|url-prefix|url)\("((?:[^"\\]|\\.)*)"\)', matcher_text
    ):
        sys.stderr.write(f"{m.group(1)}\t{m.group(2)}\n")


if __name__ == "__main__":
    main()
