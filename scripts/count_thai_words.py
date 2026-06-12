#!/usr/bin/env python3
"""Count Thai words in Markdown files using PyThaiNLP.

Install dependency:
  macOS / Ubuntu:
    python -m pip install pythainlp

Usage:
  python scripts/count_thai_words.py draft.md
  python scripts/count_thai_words.py part2.md part3.md --limit 5000

Exit codes:
  0 = count completed and is within --limit, or no limit was provided
  1 = count exceeded --limit
  2 = usage/dependency/file error
"""

from __future__ import annotations

import argparse
import re
import string
import sys
from pathlib import Path


def _load_tokenizer():
    try:
        from pythainlp.tokenize import word_tokenize
    except ImportError as exc:
        raise RuntimeError(
            "PyThaiNLP is required. Install with: python -m pip install pythainlp"
        ) from exc
    return word_tokenize


def strip_markdown(text: str) -> str:
    text = re.sub(r"```.*?```", " ", text, flags=re.DOTALL)
    text = re.sub(r"`[^`]*`", " ", text)
    text = re.sub(r"!\[[^\]]*\]\([^)]+\)", " ", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"^#{1,6}\s*", "", text, flags=re.MULTILINE)
    text = re.sub(r"^\s*[-*+]\s+", "", text, flags=re.MULTILINE)
    text = re.sub(r"^\s*\d+\.\s+", "", text, flags=re.MULTILINE)
    text = re.sub(r"[*_~>#|]", " ", text)
    text = re.sub(r"<[^>]+>", " ", text)
    return text


def count_words(text: str) -> int:
    word_tokenize = _load_tokenizer()
    punctuation = set(string.punctuation) | set("ๆฯ“”‘’…–—•·")
    tokens = word_tokenize(strip_markdown(text), engine="newmm")
    return sum(
        1
        for token in tokens
        if token.strip() and not all(char in punctuation for char in token.strip())
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Count Thai words in Markdown files.")
    parser.add_argument("paths", nargs="+", type=Path, help="Markdown file path(s)")
    parser.add_argument("--limit", type=int, default=None, help="Fail if total word count exceeds N")
    args = parser.parse_args(argv)

    total = 0
    try:
        for path in args.paths:
            text = path.read_text(encoding="utf-8")
            count = count_words(text)
            total += count
            print(f"{path}: {count}")
    except FileNotFoundError as exc:
        print(f"ERROR: file not found: {exc.filename}", file=sys.stderr)
        return 2
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    print(f"TOTAL: {total}")
    if args.limit is not None and total > args.limit:
        print(f"ERROR: word count {total} exceeds limit {args.limit}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
