// Cloudflare Pages Function: intercepts requests for /appcast.xml.
//
// Logs anonymized client metadata (app version, macOS version, CPU arch,
// Sparkle version) from the User-Agent header to an Analytics Engine dataset,
// then serves the static appcast.xml from the Pages assets bundle.
//
// IP addresses are NOT recorded. No cookies, no persistent identifiers.
// Privacy details: see /privacy.

interface Env {
    APPCAST_ANALYTICS: AnalyticsEngineDataset;
    ASSETS: Fetcher;
}

interface AnalyticsEngineDataset {
    writeDataPoint(event: { blobs?: string[]; doubles?: number[]; indexes?: string[] }): void;
}

// Sparkle's default User-Agent looks like:
//   "Squint/1.0.0 Sparkle/2.9.2"           (older Sparkle)
//   "Squint/1.0.0 (macOS 14.4; arm64) Sparkle/2.9.2"  (Sparkle with system profile)
const UA_RE = /Squint\/(\S+)(?:\s+\(([^;]+);\s*([^)]+)\))?\s+Sparkle\/(\S+)/;

export const onRequestGet: PagesFunction<Env> = async (context) => {
    const { request, env } = context;

    const ua = request.headers.get("user-agent") ?? "";
    const match = ua.match(UA_RE);
    if (match) {
        const [, appVersion, osVersion, arch, sparkleVersion] = match;
        env.APPCAST_ANALYTICS.writeDataPoint({
            // blobs are strings; indexes are queryable. The first index lets us
            // filter matched vs. unmatched; the second indexes by app version.
            blobs: [appVersion, osVersion?.trim() ?? "", arch?.trim() ?? "", sparkleVersion],
            indexes: ["matched", appVersion],
        });
    } else {
        // Log unmatched requests so we can alarm on a sudden spike (regex broke,
        // Sparkle changed UA format, etc.). Truncate the UA to 120 chars to
        // avoid logging giant strings from rogue bots.
        env.APPCAST_ANALYTICS.writeDataPoint({
            blobs: [ua.slice(0, 120)],
            indexes: ["unmatched"],
        });
    }

    // Serve the static file directly. ASSETS.fetch bypasses this function,
    // so there's no recursion risk.
    return env.ASSETS.fetch(request);
};
