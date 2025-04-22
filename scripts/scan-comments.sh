#!/usr/bin/env python3
import sys
import re
from pathlib import Path
from typing import Tuple

# Check if the terminal supports colors
IS_TTY = sys.stdout.isatty()
# ANSI escape codes for colors
COLORS = {
    "RED": "\033[31m",
    "YELLOW": "\033[33m",
    "GREEN": "\033[32m",
    "BLUE": "\033[34m",
    "BRIGHT_WHITE": "\033[37m",
    "GRAY": "\033[90m",
    "BOLD": "\033[1m",
    "BG_RED": "\033[41m",
    "RESET": "\033[0m",
}

# Define comment categories
BLOCKING_COMMENTS = {}
WARNING_COMMENTS = {
    "TODO": "BLUE",
    "WARN": "YELLOW",
    "FIXME": "RED",
    "BUG": "RED",
    "ERROR": "BG_RED",
    "CRITICAL": "BG_RED",
}

# Supported file extensions
SUPPORTED_EXTENSIONS = (".js", ".ts", ".jsx", ".tf", ".py", ".sh", ".kt")

# Paths to ignore during scanning
IGNORED_PATHS = [
    "node_modules",
    ".venv",
    "__pycache__",
    ".git",
    ".release-workspace",
    ".next",
    "dist",
]

# Regex patterns for different comment syntaxes
# C-like single line comments
COMMENT_PATTERNS_C = re.compile(r"//\s*(\w+)", re.IGNORECASE)
# Python/bash single line comments
COMMENT_PATTERNS_BASH = re.compile(r"#\s*(\w+)", re.IGNORECASE)
# Block comments (start)
COMMENT_PATTERNS_BLOCK = re.compile(r"/\*+\s*(\w+)", re.IGNORECASE)

# Language-specific comment patterns
LANGUAGE_COMMENT_PATTERNS = {
    ".js": [COMMENT_PATTERNS_C, COMMENT_PATTERNS_BLOCK],
    ".ts": [COMMENT_PATTERNS_C, COMMENT_PATTERNS_BLOCK],
    ".tsx": [COMMENT_PATTERNS_C, COMMENT_PATTERNS_BLOCK],
    ".jsx ": [COMMENT_PATTERNS_C, COMMENT_PATTERNS_BLOCK],
    ".tf": [COMMENT_PATTERNS_BASH, COMMENT_PATTERNS_C, COMMENT_PATTERNS_BLOCK],
    ".py": [COMMENT_PATTERNS_BASH],
    ".sh": [COMMENT_PATTERNS_BASH],
    ".kt": [COMMENT_PATTERNS_C, COMMENT_PATTERNS_BLOCK],
}

COMMENT_TRUNCATED_LENGTH = 120


def color(color: str, text: str) -> str:
    if not IS_TTY:
        return text
    return COLORS.get(color, "") + text + COLORS.get("RESET", "")


def extract_comment_type(line: str, extension: str) -> str:
    patterns = LANGUAGE_COMMENT_PATTERNS.get(extension, [])
    for pattern in patterns:
        match = pattern.search(line)
        if match:
            return match.group(1).upper()
    return None


def check_comments(
    file_path: Path, blocking: dict[str, str], warnings: dict[str, str]
) -> Tuple[bool, bool]:
    ext = file_path.suffix
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    found_blocking = False
    found_warning = False

    for i, line in enumerate(lines, 1):
        comment_type = extract_comment_type(line, ext)
        trimmed_line = (
            (line.strip()[: COMMENT_TRUNCATED_LENGTH - 3] + "...")
            if len(line.strip()) > COMMENT_TRUNCATED_LENGTH
            else line.strip()
        )
        if comment_type in blocking:
            print(
                f"{color('RED', '[ERROR]')} {color('BOLD', color(blocking[comment_type], comment_type))} found in {color('BRIGHT_WHITE', f'{file_path}:{i}')}: {color('GRAY', trimmed_line)}"
            )
            found_blocking = True
        elif comment_type in warnings:
            print(
                f"{color('YELLOW', '[WARNING]')} {color('BOLD', color(warnings[comment_type], comment_type))} found in {color('BRIGHT_WHITE', f'{file_path}:{i}')}: {color('GRAY', trimmed_line)}"
            )
            found_warning = True

    return found_blocking, found_warning


def is_ignored(file_path: Path) -> bool:
    return any(part in IGNORED_PATHS for part in file_path.parts)


def main():
    # Use current directory or user-supplied path
    target_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()

    if not target_dir.exists() or not target_dir.is_dir():
        print(
            f"{COLORS['RED']}[ERROR]{COLORS['RESET']} Provided path '{target_dir}' is not a valid directory."
        )
        sys.exit(1)

    files_to_check = [
        file
        for file in target_dir.rglob("*")
        if file.suffix in SUPPORTED_EXTENSIONS
        and file.is_file()
        and not is_ignored(file)
    ]

    has_blocking_comments = False

    for file in files_to_check:
        blocking, _ = check_comments(file, BLOCKING_COMMENTS, WARNING_COMMENTS)
        if blocking:
            has_blocking_comments = True

    if has_blocking_comments:
        print(
            f"\n{COLORS['RED']}[FAIL]{COLORS['RESET']} Commit rejected due to blocking issues."
        )
        sys.exit(1)
    else:
        print(
            f"\n{COLORS['GREEN']}[SUCCESS]{COLORS['RESET']} No blocking issues found."
        )
        sys.exit(0)


if __name__ == "__main__":
    main()
