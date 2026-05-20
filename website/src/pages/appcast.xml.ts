import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { APIRoute } from "astro";
import { parse as parseYaml } from "yaml";

// changelog.yml at the repo root is the source of truth for releases.
// Entries gain `signature`, `size`, and `date` after CI signs the DMG.
// Entries without those fields haven't shipped yet and are skipped here.
interface ReleaseEntry {
    title: string;
    notes: string;
    signature?: string;
    size?: number;
    date?: string;
}

const REPO_URL = "https://github.com/dupontcyborg/squint";
const DMG_BASE = "https://squint.sh/download";

function escapeXml(s: string): string {
    return s
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");
}

function rfc822(iso: string): string {
    return new Date(iso).toUTCString().replace("GMT", "+0000");
}

export const GET: APIRoute = () => {
    const path = resolve(process.cwd(), "..", "changelog.yml");
    const raw = readFileSync(path, "utf8");
    const all = parseYaml(raw) as Record<string, ReleaseEntry>;

    const shipped = Object.entries(all).filter(
        ([, e]) => e.signature && typeof e.size === "number" && e.date
    );

    // Newest first by date (release order, not lex order on version tags).
    shipped.sort(([, a], [, b]) => (b.date as string).localeCompare(a.date as string));

    const items = shipped
        .map(([tag, e]) => {
            const cleanVersion = tag.replace(/^v/, "");
            const dmgUrl = `${DMG_BASE}/${tag}/Squint.dmg`;
            const notesUrl = `${REPO_URL}/releases/tag/${tag}`;
            return `    <item>
      <title>${escapeXml(`Version ${cleanVersion}`)}</title>
      <sparkle:releaseNotesLink>${escapeXml(notesUrl)}</sparkle:releaseNotesLink>
      <pubDate>${rfc822(e.date as string)}</pubDate>
      <enclosure url="${escapeXml(dmgUrl)}" sparkle:version="${escapeXml(cleanVersion)}" sparkle:shortVersionString="${escapeXml(cleanVersion)}" length="${e.size}" type="application/octet-stream" sparkle:edSignature="${escapeXml(e.signature as string)}" />
    </item>`;
        })
        .join("\n");

    const body = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Squint Updates</title>
    <language>en</language>
${items}
  </channel>
</rss>
`;

    return new Response(body, {
        headers: { "content-type": "application/xml; charset=utf-8" },
    });
};
