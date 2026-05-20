import os
import sys
import json
import urllib.request
from datetime import datetime, timedelta, timezone

def github_api_request(url, token):
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("User-Agent", "Squint-Metrics-Accumulator")
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode())
    except Exception as e:
        print(f"Error calling GitHub API at {url}: {e}")
        return None

def main():
    token = os.environ.get("GITHUB_TOKEN")
    repo = os.environ.get("GITHUB_REPOSITORY") # Format: "owner/repo"

    if not token or not repo:
        print("Error: GITHUB_TOKEN and GITHUB_REPOSITORY environment variables must be set.")
        sys.exit(1)

    # 1. Fetch download counts for releases
    releases_url = f"https://api.github.com/repos/{repo}/releases"
    releases = github_api_request(releases_url, token)
    
    total_downloads = 0
    if releases:
        for release in releases:
            for asset in release.get("assets", []):
                if asset.get("name") == "Squint.dmg":
                    total_downloads += asset.get("download_count", 0)
    print(f"Total Squint.dmg downloads: {total_downloads}")

    # 2. Fetch traffic clones
    clones_url = f"https://api.github.com/repos/{repo}/traffic/clones"
    clones_data = github_api_request(clones_url, token)

    # Backfill all complete days returned by the API (excludes today, which is partial).
    # GitHub returns up to 14 days; this protects against missed cron runs.
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    daily_clones = {}
    if clones_data and "clones" in clones_data:
        for day in clones_data["clones"]:
            day_str = day.get("timestamp", "").split("T")[0]
            if day_str and day_str != today_str:
                daily_clones[day_str] = (day.get("count", 0), day.get("uniques", 0))

    # 3. Read or create metrics CSV file. The workflow writes to /tmp so the
    #    working tree on `main` stays clean before checking out `stats`.
    csv_path = os.environ.get("METRICS_CSV_PATH", "stats/metrics.csv")
    os.makedirs(os.path.dirname(csv_path) or ".", exist_ok=True)

    header = "date,total_downloads,daily_clones,unique_clones\n"

    existing_rows = {}
    if os.path.exists(csv_path):
        with open(csv_path, "r") as f:
            for line in f.readlines()[1:]:
                parts = line.strip().split(",")
                if len(parts) >= 4:
                    existing_rows[parts[0]] = line.strip()

    for date_key, (count, uniques) in daily_clones.items():
        existing_rows[date_key] = f"{date_key},{total_downloads},{count},{uniques}"

    with open(csv_path, "w") as f:
        f.write(header)
        for date_key in sorted(existing_rows.keys()):
            f.write(existing_rows[date_key] + "\n")

    print(f"Updated {csv_path}: backfilled {len(daily_clones)} day(s) of clone data, total_downloads={total_downloads}")

if __name__ == "__main__":
    main()
