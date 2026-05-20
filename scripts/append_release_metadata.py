"""Append signature/size/date to a release entry in changelog.yml.

Invoked from .github/workflows/release.yml after the DMG is built and signed.
The Astro endpoint at website/src/pages/appcast.xml.ts reads changelog.yml at
build time and emits a properly-namespaced RSS feed; this script never touches
XML.

Usage:
    python3 scripts/append_release_metadata.py <tag> <signature> <size>
"""

import sys
from datetime import datetime, timezone
from pathlib import Path

from ruamel.yaml import YAML

CHANGELOG = Path("changelog.yml")


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: python3 append_release_metadata.py <tag> <signature> <size>")
        return 2

    tag, signature, size_str = sys.argv[1], sys.argv[2], sys.argv[3]
    size = int(size_str)

    # ruamel preserves block scalars (the `notes: |` style) and comments,
    # so changelog.yml stays human-friendly across automated edits.
    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.indent(mapping=2, sequence=4, offset=2)

    data = yaml.load(CHANGELOG)
    if tag not in data:
        print(f"Error: tag '{tag}' not found in {CHANGELOG}.")
        return 1

    entry = data[tag]
    entry["signature"] = signature
    entry["size"] = size
    entry["date"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    with CHANGELOG.open("w") as f:
        yaml.dump(data, f)

    print(f"Appended release metadata to {tag} in {CHANGELOG}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
