import os
import asyncio
import requests
from fastmcp import Client

GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
REPO = os.environ["REPO"]
PR_NUMBER = os.environ["PR_NUMBER"]
GMS_URL = os.environ["DATAHUB_GMS_URL"]

HEADERS = {
    "Authorization": f"Bearer {GITHUB_TOKEN}",
    "Accept": "application/vnd.github+json",
}

def get_changed_files():
    url = f"https://api.github.com/repos/{REPO}/pulls/{PR_NUMBER}/files"
    resp = requests.get(url, headers=HEADERS)
    resp.raise_for_status()
    return [f["filename"] for f in resp.json()]

def extract_table_names(files):
    tables = []
    for f in files:
        if f.startswith("models/") and f.endswith(".sql"):
            tables.append(f.split("/")[-1].replace(".sql", ""))
    return tables

def build_urn(table_name):
    return f"urn:li:dataset:(urn:li:dataPlatform:dbt,jaffle_shop.main.{table_name},PROD)"

async def get_downstream(table_name):
    config = {
        "mcpServers": {
            "datahub": {
                "command": "mcp-server-datahub",
                "env": {"DATAHUB_GMS_URL": GMS_URL}
            }
        }
    }
    async with Client(config) as client:
        result = await client.call_tool("get_lineage", {
            "urn": build_urn(table_name),
            "upstream": False,
            "max_hops": 2
        })
        return result.data

def format_comment(table_name, lineage_data):
    downstreams = lineage_data.get("downstreams", {}).get("searchResults", [])
    if not downstreams:
        return f"✅ **Cross-Domain Break Predictor**: No downstream dependents found for `{table_name}`. This change looks low-risk."

    lines = [f"⚠️ **Cross-Domain Break Predictor**: `{table_name}` has {len(downstreams)} downstream dependent(s):\n"]
    for d in downstreams:
        entity = d["entity"]
        name = entity.get("name", "unknown")
        owners = entity.get("ownership", {}).get("owners", [])
        owner_names = [
            o["owner"]["properties"]["displayName"]
            for o in owners
            if "properties" in o.get("owner", {})
        ]
        owner_str = ", ".join(owner_names) if owner_names else "no listed owner"
        lines.append(f"- **{name}** (owner: {owner_str})")

    lines.append("\nPlease confirm with the listed owners before merging this change.")
    return "\n".join(lines)

def post_comment(body):
    url = f"https://api.github.com/repos/{REPO}/issues/{PR_NUMBER}/comments"
    resp = requests.post(url, headers=HEADERS, json={"body": body})
    resp.raise_for_status()

def main():
    files = get_changed_files()
    tables = extract_table_names(files)

    if not tables:
        post_comment("ℹ️ **Cross-Domain Break Predictor**: No dbt model files changed — nothing to check.")
        return

    comments = []
    for table in tables:
        try:
            lineage_data = asyncio.run(get_downstream(table))
            comments.append(format_comment(table, lineage_data))
        except Exception as e:
            comments.append(f"⚠️ Could not check lineage for `{table}`: {e}")

    post_comment("\n\n---\n\n".join(comments))

if __name__ == "__main__":
    main()
