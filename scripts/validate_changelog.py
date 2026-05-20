import sys
import os
import yaml

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 validate-changelog.py <tag>")
        sys.exit(1)

    tag = sys.argv[1]
    changelog_path = "changelog.yml"

    if not os.path.exists(changelog_path):
        print(f"Error: {changelog_path} not found in repository root.")
        sys.exit(1)

    try:
        with open(changelog_path, 'r') as f:
            data = yaml.safe_load(f)
    except Exception as e:
        print(f"Error parsing changelog.yml: {e}")
        sys.exit(1)

    if not data or tag not in data:
        print(f"::error::Tag '{tag}' not found in changelog.yml.")
        print(f"Please add a '{tag}' section to changelog.yml before tagging.")
        sys.exit(1)

    release_info = data[tag]
    title = release_info.get('title', f"Release {tag}")
    notes = release_info.get('notes', "")

    os.makedirs("build", exist_ok=True)

    # Write title and notes to temporary files to be consumed by the workflow
    with open("build/release_title.txt", "w") as f:
        f.write(title)

    with open("build/release_notes.md", "w") as f:
        f.write(notes)

    print(f"Changelog verified for {tag}: '{title}'")

if __name__ == "__main__":
    main()
