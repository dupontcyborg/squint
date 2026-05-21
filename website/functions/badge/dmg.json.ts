// Cloudflare Pages Function: serves a shields.io `endpoint` badge with the
// human-formatted size of the latest Squint.dmg on the GitHub releases page.
//
// Used by README.md as:
//   https://img.shields.io/endpoint?url=https://squint.sh/badge/dmg.json

interface ReleaseAsset {
    name: string;
    size: number;
}

interface Release {
    assets?: ReleaseAsset[];
}

function formatBytes(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

export const onRequestGet: PagesFunction = async () => {
    const res = await fetch(
        "https://api.github.com/repos/dupontcyborg/squint/releases/latest",
        { headers: { "user-agent": "squint-badge" } }
    );

    let message = "unknown";
    if (res.ok) {
        const data: Release = await res.json();
        const dmg = data.assets?.find((a) => a.name === "Squint.dmg");
        if (dmg) message = formatBytes(dmg.size);
    }

    return new Response(
        JSON.stringify({
            schemaVersion: 1,
            label: "DMG",
            message,
            color: "blue",
        }),
        {
            headers: {
                "content-type": "application/json",
                // Cache at the edge for 1h — shields.io polls infrequently and
                // the underlying GitHub API has a 60 req/h unauth limit per IP.
                "cache-control": "public, max-age=3600",
            },
        }
    );
};
