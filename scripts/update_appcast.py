import os
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

def main():
    if len(sys.argv) < 6:
        print("Usage: python3 update_appcast.py <version> <signature> <size> <dmg_url> <notes_url>")
        sys.exit(1)

    version = sys.argv[1]
    signature = sys.argv[2]
    size = sys.argv[3]
    dmg_url = sys.argv[4]
    notes_url = sys.argv[5]

    appcast_path = "website/public/appcast.xml"
    
    # Initialize empty appcast if not exists
    if not os.path.exists(appcast_path):
        os.makedirs(os.path.dirname(appcast_path), exist_ok=True)
        root = ET.Element("rss", {
            "version": "2.0",
            "xmlns:sparkle": "http://www.andymatuschak.org/xml-namespaces/sparkle",
            "xmlns:dc": "http://purl.org/dc/elements/1.1/"
        })
        channel = ET.SubElement(root, "channel")
        ET.SubElement(channel, "title").text = "Squint Updates"
        ET.SubElement(channel, "language").text = "en"
        indent(root)
        tree = ET.ElementTree(root)
        tree.write(appcast_path, encoding="utf-8", xml_declaration=True)

    # Register Sparkle namespace to prevent ns0 prefixes
    ET.register_namespace("sparkle", "http://www.andymatuschak.org/xml-namespaces/sparkle")
    ET.register_namespace("dc", "http://purl.org/dc/elements/1.1/")

    tree = ET.parse(appcast_path)
    root = tree.getroot()
    channel = root.find("channel")

    if channel is None:
        print("Error: Invalid appcast structure (missing channel).")
        sys.exit(1)

    # Check if version already exists to avoid duplicates
    for item in channel.findall("item"):
        enclosure = item.find("enclosure")
        if enclosure is not None:
            # Check version attribute in Sparkle namespace
            ver_attr = enclosure.attrib.get("{http://www.andymatuschak.org/xml-namespaces/sparkle}version")
            if ver_attr == version:
                print(f"Version {version} already exists in appcast.xml. Skipping append.")
                return

    # Create new item
    item = ET.Element("item")
    
    title = ET.SubElement(item, "title")
    title.text = f"Version {version}"
    
    release_notes = ET.SubElement(item, "sparkle:releaseNotesLink")
    release_notes.text = notes_url
    
    pub_date = ET.SubElement(item, "pubDate")
    # Format: Wed, 20 May 2026 15:55:00 +0000
    pub_date.text = datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")
    
    enclosure = ET.SubElement(item, "enclosure", {
        "url": dmg_url,
        "sparkle:version": version,
        "sparkle:shortVersionString": version,
        "length": size,
        "type": "application/octet-stream",
        "sparkle:edSignature": signature
    })

    # Insert new item at the top of the item list (index after channel metadata like title/language)
    # Find the index of the first item, or append if no items exist
    insert_idx = 0
    for idx, child in enumerate(channel):
        if child.tag == "item":
            insert_idx = idx
            break
    else:
        insert_idx = len(channel)

    channel.insert(insert_idx, item)

    # Pretty-print indentation
    indent(root)

    # Write back to file
    tree.write(appcast_path, encoding="utf-8", xml_declaration=True)
    print(f"Successfully added version {version} to appcast.xml")

def indent(elem, level=0):
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

if __name__ == "__main__":
    main()
