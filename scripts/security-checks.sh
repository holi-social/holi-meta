#!/usr/bin/env python3
import sys
from pathlib import Path
import re

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

PRECOMMIT_CONFIG_GITLEAKS_PATTERN = re.compile(r"^\s*-\s+id:\s*gitleaks")


def check_gitleaks_hook(config_path: Path) -> bool:
    if not config_path.exists():
        print("[ERROR] .pre-commit-config.yaml not found.")
        return True

    try:
        with config_path.open("r", encoding="utf-8") as f:
            lines = f.readlines()
            for line in lines:
                if PRECOMMIT_CONFIG_GITLEAKS_PATTERN.search(line.strip()):
                    return False
    except Exception as e:
        print(f"[ERROR] Failed to read {config_path}: {e}")
        return True

    print(f"[ERROR] gitleaks hook not configured in {config_path}")
    return True


def is_ignored(file_path: Path) -> bool:
    return any(part in IGNORED_PATHS for part in file_path.parts)


def main():
    # Use current directory or user-supplied path
    target_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()

    if not target_dir.exists() or not target_dir.is_dir():
        print(f"[ERROR] Provided path '{target_dir}' is not a valid directory.")
        sys.exit(1)

    files_to_check = [
        file
        for file in target_dir.rglob("*.pre-commit-config.yaml")
        if file.is_file() and not is_ignored(file)
    ]

    has_blocking = False

    for file in files_to_check:
        blocking = check_gitleaks_hook(file)
        if blocking:
            has_blocking = True

    if has_blocking:
        print("\n[FAIL] Commit rejected due to blocking issues.")
        sys.exit(1)
    else:
        print("\n[SUCCESS] No blocking issues found.")
        sys.exit(0)


if __name__ == "__main__":
    main()
