from __future__ import annotations

import json
import re
import time
from collections import defaultdict
from html import unescape
from pathlib import Path

import cloudscraper
from bs4 import BeautifulSoup


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "WrathCombo"
OUTPUT_PATH = ROOT / "tools" / "huiji-action-map.json"
ACTION_API = "https://ff14.huijiwiki.com/api.php?action=parse&page=Action:{id}&prop=text&format=json"


def collect_action_ids() -> dict[int, set[str]]:
    by_id: dict[int, set[str]] = defaultdict(set)
    regex = re.compile(r"(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?P<id>\d+),")

    for relative in ("Combos/PvE", "Combos/PvP"):
        for path in (SOURCE_ROOT / relative).rglob("*.cs"):
            text = path.read_text(encoding="utf-8")
            for match in regex.finditer(text):
                action_id = int(match.group("id"))
                if action_id > 0:
                    by_id[action_id].add(match.group("name"))

    return by_id


def load_existing() -> dict[str, dict]:
    if not OUTPUT_PATH.exists():
        return {}
    return json.loads(OUTPUT_PATH.read_text(encoding="utf-8")).get("by_id", {})


def symbol_to_english(symbol: str) -> str:
    words = re.findall(r"[A-Z]+(?=[A-Z][a-z]|\d|$)|[A-Z]?[a-z]+|\d+", symbol)
    if not words:
        return symbol
    return " ".join(words)


def parse_names(html_text: str) -> tuple[str, str, str]:
    soup = BeautifulSoup(html_text, "html.parser")
    zh_node = soup.select_one(".tooltip-item--name-title")
    small_node = soup.find("font")

    zh = zh_node.get_text(strip=True) if zh_node else ""
    small = unescape(small_node.get_text(" ", strip=True)) if small_node else ""
    small = small.replace("\u3000", " ").strip()

    en = ""
    ja = ""
    match = re.match(r"^(?P<ja>.*?)\s{2,}(?P<en>[A-Za-z][A-Za-z0-9'()./&,:+\- ]*)$", small)
    if match:
        ja = match.group("ja").strip()
        en = match.group("en").strip()
    elif re.search(r"[A-Za-z]", small):
        split_index = small.find(" ")
        if split_index > 0:
            ja = small[:split_index].strip()
            en = small[split_index:].strip()
        else:
            en = small.strip()
    else:
        ja = small.strip()

    return zh, ja, en


def fetch_action(scraper: cloudscraper.CloudScraper, action_id: int) -> dict | None:
    response = scraper.get(ACTION_API.format(id=action_id), timeout=30)
    response.raise_for_status()
    payload = response.json()
    if "parse" not in payload:
        return None
    html_text = payload["parse"]["text"]["*"]
    zh, ja, en = parse_names(html_text)
    return {
        "zh": zh,
        "ja": ja,
        "en": en,
        "source_url": f"https://ff14.huijiwiki.com/wiki/Action:{action_id}",
    }


def main() -> None:
    action_ids = collect_action_ids()
    existing = load_existing()
    scraper = cloudscraper.create_scraper(
        browser={"browser": "chrome", "platform": "windows", "mobile": False}
    )

    by_id: dict[str, dict] = {}
    for index, action_id in enumerate(sorted(action_ids)):
        key = str(action_id)
        record = existing.get(key, {})
        if not record.get("zh") or not record.get("en"):
            record = fetch_action(scraper, action_id)
            if record is None:
                continue
            time.sleep(0.15)

        record["symbols"] = sorted(action_ids[action_id])
        by_id[key] = record

        if (index + 1) % 50 == 0:
            print(f"processed {index + 1}/{len(action_ids)} action ids")

    by_en = {
        record["en"]: record["zh"]
        for record in by_id.values()
        if record.get("en") and record.get("zh")
    }
    for record in by_id.values():
        zh = record.get("zh")
        if not zh:
            continue
        for symbol in record.get("symbols", []):
            alias = symbol_to_english(symbol)
            if alias and alias not in by_en:
                by_en[alias] = zh

    output = {
        "source": "huijiwiki-action-pages",
        "generated_from": "tools/Build-HuijiActionMap.py",
        "count": len(by_id),
        "by_id": by_id,
        "by_en": dict(sorted(by_en.items(), key=lambda item: item[0].lower())),
    }
    OUTPUT_PATH.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"wrote {len(by_id)} actions to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
