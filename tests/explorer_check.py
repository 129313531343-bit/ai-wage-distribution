"""Acceptance check for the explorer (run with Playwright for Python):

    python tests/explorer_check.py

It serves explorer/ locally, loads the page at 375 px wide, and checks that:
  - there is one JSON row per v1.2 unit (358) and one list item per row;
  - every field the page displays is a column in data/out/explorer_units.csv;
  - the disclaimer is visible;
  - nothing scrolls sideways at 375 px, with every unit expanded.
It saves a screenshot to explorer/check_375px.png and exits non-zero on any failure.
"""
import csv
import functools
import http.server
import json
import pathlib
import re
import sys
import threading

from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXPLORER = ROOT / "explorer"
DISCLAIMER = "Descriptive; not a job-loss or career-risk score; not advice."

failures = []


def check(cond, msg):
    if not cond:
        failures.append(msg)


rows = json.loads((EXPLORER / "explorer_units.json").read_text())
with open(ROOT / "data" / "out" / "explorer_units.csv", newline="") as f:
    csv_cols = next(csv.reader(f))
check(len(rows) == 358, f"expected 358 JSON rows, found {len(rows)}")
check(len({r["unit"] for r in rows}) == len(rows), "duplicate units in JSON")
check(set(rows[0].keys()) == set(csv_cols), "JSON fields differ from CSV columns")

html = (EXPLORER / "index.html").read_text()
fields = re.findall(r'\["([a-z0-9_]+)", "', html)
displayed = set(fields) | {"unit", "title", "major_group", "usage_display", "usage_band", "below_usage_threshold"}
missing = sorted(displayed - set(csv_cols))
check(not missing, f"displayed fields not in CSV: {missing}")
check(not any("aioe" in c.lower() for c in csv_cols), "AIOE column present")

handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(EXPLORER))
server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{server.server_address[1]}/index.html"

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 375, "height": 812})
    page.goto(url)
    page.wait_for_selector("li.unit")
    check(page.locator("li.unit").count() == 358, "list does not show 358 units")
    check(page.get_by_text(DISCLAIMER).is_visible(), "disclaimer not visible")
    page.screenshot(path=str(EXPLORER / "check_375px.png"))
    page.eval_on_selector_all("li.unit", "els => els.forEach(e => e.classList.add('open'))")
    width = page.evaluate("document.documentElement.scrollWidth")
    check(width <= 375, f"horizontal scroll at 375 px: page is {width}px wide")
    page.fill("#q", "2613")
    check(page.locator("li.unit").count() == 1, "code search for 2613 did not return one unit")
    page.fill("#q", "nurse")
    check(page.locator("li.unit").count() >= 1, "title search for 'nurse' returned nothing")
    browser.close()
server.shutdown()

if failures:
    print("Explorer check FAILED:\n - " + "\n - ".join(failures))
    sys.exit(1)
print("Explorer check passed: 358 units, fields match CSV, disclaimer visible, no horizontal scroll at 375 px.")
