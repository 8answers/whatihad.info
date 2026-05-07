#!/usr/bin/env python3
"""
Daily updater for actual market prices in food CSV currency columns.

It fetches live local-currency prices per item via PricesAPI and writes an
updated output CSV while preserving the original input file.

Important:
- This does NOT convert INR to other currencies.
- It writes real country-market offer prices when available.
- Unsupported or unresolved items keep their existing CSV values.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import socket
import statistics
import time
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

API_BASE = "https://api.pricesapi.io/api/v1"

# PricesAPI supported countries mapped to your CSV currency columns.
# CNY is not currently supported by this provider.
CURRENCY_COUNTRY_MAP: Dict[str, str] = {
    "USD": "us",
    "EUR": "de",
    "GBP": "gb",
    "INR": "in",
    "BRL": "br",
    "JPY": "jp",
    "AUD": "au",
    "CAD": "ca",
    "SGD": "sg",
    "AED": "ae",
    "SAR": "sa",
}

ALL_CURRENCY_COLUMNS = [
    "USD",
    "EUR",
    "GBP",
    "INR",
    "CNY",
    "BRL",
    "JPY",
    "AUD",
    "CAD",
    "SGD",
    "AED",
    "SAR",
]


@dataclass
class FetchResult:
    price: float
    product_id: str
    product_title: str
    source: str


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_iso(ts: str) -> Optional[datetime]:
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except Exception:
        return None


def csv_default_output(input_csv: Path) -> Path:
    return input_csv.with_name(f"{input_csv.stem}_actual_market_daily.csv")


def cache_default_path(output_csv: Path) -> Path:
    return output_csv.with_suffix(".cache.json")


def load_cache(path: Path) -> dict:
    if not path.exists():
        return {"schema_version": 1, "updated_at": now_iso(), "items": {}}
    try:
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict) or "items" not in data:
            raise ValueError("invalid cache schema")
        if not isinstance(data["items"], dict):
            raise ValueError("invalid cache items")
        return data
    except Exception:
        # Recover safely by starting a fresh cache instead of failing the run.
        return {"schema_version": 1, "updated_at": now_iso(), "items": {}}


def save_cache(path: Path, cache: dict) -> None:
    cache["updated_at"] = now_iso()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=2, sort_keys=True)


def read_csv(path: Path) -> Tuple[List[str], List[dict]]:
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames:
            raise ValueError("CSV has no header row")
        rows = list(reader)
        return reader.fieldnames, rows


def write_csv(path: Path, fieldnames: List[str], rows: List[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def parse_float(value: str) -> Optional[float]:
    try:
        return float(str(value).strip())
    except Exception:
        return None


def build_query(item_name: str, quantity: str, quantity_type: str) -> str:
    item = (item_name or "").strip()
    q = (quantity or "").strip()
    qt = (quantity_type or "").strip()
    if not item:
        return ""
    # Prefer plain item names for better marketplace matching and fewer timeouts.
    # Quantity qualifiers are often too specific for retail catalog search.
    return item


def make_cache_key(
    currency: str, item_name: str, quantity: str, quantity_type: str
) -> str:
    return "||".join(
        [
            currency.upper(),
            (item_name or "").strip().lower(),
            (quantity or "").strip().lower(),
            (quantity_type or "").strip().lower(),
        ]
    )


def is_cache_fresh(entry: dict, ttl_days: int) -> bool:
    fetched_at = entry.get("fetched_at")
    if not fetched_at:
        return False
    dt = parse_iso(fetched_at)
    if not dt:
        return False
    return dt >= datetime.now(timezone.utc) - timedelta(days=ttl_days)


def api_get_json(
    url: str,
    api_key: str,
    timeout_sec: int = 45,
    retry_count: int = 2,
    retry_sleep_sec: float = 2.0,
    debug_errors_left: Optional[List[int]] = None,
) -> dict:
    req = Request(url, headers={"x-api-key": api_key, "Accept": "application/json"})
    for attempt in range(retry_count + 1):
        try:
            with urlopen(req, timeout=timeout_sec) as resp:
                raw = resp.read()
            return json.loads(raw.decode("utf-8"))
        except HTTPError as err:
            body_text = ""
            try:
                body_text = err.read().decode("utf-8", errors="ignore")
            except Exception:
                body_text = ""
            body_short = " ".join(body_text.split())[:220]
            should_retry = err.code in {408, 425, 429, 500, 502, 503, 504}
            if should_retry and attempt < retry_count:
                delay = retry_sleep_sec * (attempt + 1)
                time.sleep(delay)
                continue
            if debug_errors_left is not None and debug_errors_left[0] > 0:
                print(
                    "HTTP error:",
                    f"status={err.code}",
                    f"url={url}",
                    f"body={body_short or '<empty>'}",
                    flush=True,
                )
                debug_errors_left[0] -= 1
            raise
        except (URLError, TimeoutError, socket.timeout, json.JSONDecodeError) as err:
            if attempt < retry_count:
                delay = retry_sleep_sec * (attempt + 1)
                time.sleep(delay)
                continue
            if debug_errors_left is not None and debug_errors_left[0] > 0:
                print(
                    "Transport/decode error:",
                    f"type={type(err).__name__}",
                    f"url={url}",
                    f"message={str(err)}",
                    flush=True,
                )
                debug_errors_left[0] -= 1
            raise


def fetch_live_price(
    api_key: str,
    query: str,
    country: str,
    expected_currency: str,
    sleep_sec: float = 0.15,
    request_timeout_sec: int = 20,
    retry_count: int = 2,
    retry_sleep_sec: float = 2.0,
    use_search_price_only: bool = False,
    debug_errors_left: Optional[List[int]] = None,
) -> Tuple[Optional[FetchResult], int]:
    if not query:
        return None, 0

    calls_used = 0

    # 1) Search product candidates (keep limit low for speed).
    search_qs = urlencode({"q": query, "country": country, "limit": 1})
    search_url = f"{API_BASE}/products/search?{search_qs}"

    try:
        data = api_get_json(
            search_url,
            api_key,
            timeout_sec=request_timeout_sec,
            retry_count=retry_count,
            retry_sleep_sec=retry_sleep_sec,
            debug_errors_left=debug_errors_left,
        )
    except (HTTPError, URLError, TimeoutError, socket.timeout, json.JSONDecodeError):
        return None, 1
    calls_used += 1

    data_block = data.get("data", {}) if isinstance(data, dict) else {}
    results = []
    if isinstance(data_block, dict):
        # API docs now return `products`; older examples may use `results`.
        raw_results = data_block.get("products")
        if not isinstance(raw_results, list):
            raw_results = data_block.get("results")
        if isinstance(raw_results, list):
            results = raw_results
    if not results:
        return None, calls_used

    first = results[0]
    # API docs use `pid`; support legacy `id` as fallback.
    product_id = str(first.get("pid") or first.get("id") or "").strip()
    product_title = str(first.get("title", "")).strip()
    if not product_id:
        return None, calls_used

    # Fast path: reuse the top search price instead of live-offers scraping.
    # This dramatically reduces timeout risk and API spend.
    search_price = parse_float(first.get("price"))
    search_currency = str(first.get("currency") or "").strip().upper()
    if search_price is not None and search_price > 0:
        if use_search_price_only or search_currency == expected_currency.upper():
            return (
                FetchResult(
                    price=search_price,
                    product_id=product_id,
                    product_title=product_title,
                    source="search",
                ),
                calls_used,
            )

    time.sleep(sleep_sec)

    # 2) Fetch live offers.
    # Keep offers pagination bounded to reduce long-running scrape time.
    offers_qs = urlencode({"country": country, "limit": 10})
    offers_url = f"{API_BASE}/products/{product_id}/offers?{offers_qs}"
    try:
        offers_data = api_get_json(
            offers_url,
            api_key,
            timeout_sec=request_timeout_sec,
            retry_count=retry_count,
            retry_sleep_sec=retry_sleep_sec,
            debug_errors_left=debug_errors_left,
        )
    except (HTTPError, URLError, TimeoutError, socket.timeout, json.JSONDecodeError):
        return None, calls_used + 1
    calls_used += 1

    offers = offers_data.get("data", {}).get("offers", []) if isinstance(offers_data, dict) else []
    prices = []
    for offer in offers:
        p = parse_float(offer.get("price"))
        if p is not None and p > 0:
            prices.append(p)

    if not prices:
        return None, calls_used

    # Use a robust representative market price:
    # median of up to 7 cheapest offers.
    prices_sorted = sorted(prices)
    sample = prices_sorted[:7]
    representative = float(statistics.median(sample))
    return (
        FetchResult(
            price=representative,
            product_id=product_id,
            product_title=product_title,
            source="offers",
        ),
        calls_used,
    )


def format_price(value: float, currency: str) -> str:
    # Keep JPY as no decimals; others as 2 decimals.
    if currency == "JPY":
        return f"{round(value):.0f}"
    return f"{value:.2f}"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update CSV currency columns with actual market prices."
    )
    parser.add_argument(
        "--input",
        default="/Users/prajna/Downloads/main_food_items_list 2.csv",
        help="Input CSV path",
    )
    parser.add_argument(
        "--output",
        default="",
        help="Output CSV path (default: <input>_actual_market_daily.csv)",
    )
    parser.add_argument(
        "--cache",
        default="",
        help="Cache JSON path (default: next to output file)",
    )
    parser.add_argument(
        "--ttl-days",
        type=int,
        default=7,
        help="Cache freshness in days before re-fetching",
    )
    parser.add_argument(
        "--max-api-calls",
        type=int,
        default=800,
        help="Max API calls per run (search+offers count separately)",
    )
    parser.add_argument(
        "--sleep-sec",
        type=float,
        default=0.15,
        help="Delay between API calls to reduce rate-limit errors",
    )
    parser.add_argument(
        "--request-timeout-sec",
        type=int,
        default=20,
        help="Per-request timeout in seconds",
    )
    parser.add_argument(
        "--progress-every",
        type=int,
        default=200,
        help="Print progress every N processed cells",
    )
    parser.add_argument(
        "--checkpoint-every-rows",
        type=int,
        default=200,
        help="Persist CSV+cache every N rows to avoid losing long-run progress",
    )
    parser.add_argument(
        "--retry-count",
        type=int,
        default=2,
        help="Retry count for transient HTTP/network errors",
    )
    parser.add_argument(
        "--retry-sleep-sec",
        type=float,
        default=2.0,
        help="Base sleep between retries (linear backoff)",
    )
    parser.add_argument(
        "--debug-errors",
        action="store_true",
        help="Print first few API/transport errors for diagnosis",
    )
    parser.add_argument(
        "--debug-errors-max",
        type=int,
        default=10,
        help="Maximum number of debug error lines",
    )
    parser.add_argument(
        "--only-missing",
        action="store_true",
        help="Fetch only when target cell is empty",
    )
    parser.add_argument(
        "--currencies",
        default="",
        help="Comma-separated currency codes to process (default: all)",
    )
    parser.add_argument(
        "--use-search-price-only",
        action="store_true",
        help="Use top /search price directly and skip /offers lookup",
    )
    parser.add_argument(
        "--stop-on-budget-hit",
        action="store_true",
        help="Stop run immediately when max API call budget is reached",
    )
    args = parser.parse_args()

    api_key = os.getenv("PRICESAPI_KEY", "").strip()
    if not api_key:
        print(
            "Missing PRICESAPI_KEY environment variable. "
            "Create one from https://pricesapi.io/signup",
        )
        return 2

    input_csv = Path(args.input).expanduser().resolve()
    output_csv = (
        Path(args.output).expanduser().resolve()
        if args.output
        else csv_default_output(input_csv)
    )
    cache_path = (
        Path(args.cache).expanduser().resolve()
        if args.cache
        else cache_default_path(output_csv)
    )

    if not input_csv.exists():
        print(f"Input file not found: {input_csv}")
        return 2

    fieldnames, rows = read_csv(input_csv)
    missing_cols = [c for c in ALL_CURRENCY_COLUMNS if c not in fieldnames]
    if missing_cols:
        print(f"Input CSV is missing currency columns: {', '.join(missing_cols)}")
        return 2

    cache = load_cache(cache_path)
    cache_items = cache.setdefault("items", {})

    currencies_to_process = ALL_CURRENCY_COLUMNS
    if args.currencies.strip():
        requested = [
            code.strip().upper()
            for code in args.currencies.split(",")
            if code.strip()
        ]
        currencies_to_process = [
            code for code in ALL_CURRENCY_COLUMNS if code in requested
        ]
        if not currencies_to_process:
            print("No valid currencies selected. Available:", ", ".join(ALL_CURRENCY_COLUMNS))
            return 2

    # In-run dedupe so identical queries across rows do not repeat API calls.
    live_cache: Dict[str, Optional[FetchResult]] = {}
    api_calls = 0
    updated_cells = 0
    used_cached_cells = 0
    unresolved_cells = 0
    skipped_rate_limit_cells = 0
    unsupported_currency_cells = 0
    budget_exhausted = False
    processed_cells = 0
    possible_cells = len(rows) * len(currencies_to_process)

    print(
        "Starting price update...",
        f"rows={len(rows)}",
        f"possible_cells={possible_cells}",
        f"currencies={','.join(currencies_to_process)}",
        f"max_api_calls={args.max_api_calls}",
        sep=" ",
        flush=True,
    )
    debug_errors_left = [max(0, int(args.debug_errors_max))] if args.debug_errors else None

    def maybe_print_progress() -> None:
        if args.progress_every > 0 and (processed_cells % args.progress_every) == 0:
            print(
                "Progress:",
                f"{processed_cells}/{possible_cells} cells",
                f"api_calls={api_calls}",
                f"updated={updated_cells}",
                f"cache_hits={used_cached_cells}",
                f"unresolved={unresolved_cells}",
                flush=True,
            )

    for row_index, row in enumerate(rows, start=1):
        item_name = (row.get("item_name") or "").strip()
        quantity = (row.get("quantity") or "").strip()
        quantity_type = (row.get("quantity_type") or "").strip()
        query = build_query(item_name, quantity, quantity_type)

        for currency in currencies_to_process:
            processed_cells += 1
            country = CURRENCY_COUNTRY_MAP.get(currency)
            if not country:
                # Keep existing value for unsupported providers (e.g. CNY here).
                unsupported_currency_cells += 1
                maybe_print_progress()
                continue

            if args.only_missing and str(row.get(currency, "")).strip():
                maybe_print_progress()
                continue

            key = make_cache_key(currency, item_name, quantity, quantity_type)
            entry = cache_items.get(key)
            if isinstance(entry, dict) and is_cache_fresh(entry, args.ttl_days):
                p = parse_float(entry.get("price"))
                if p is not None and p > 0:
                    row[currency] = format_price(p, currency)
                    used_cached_cells += 1
                    maybe_print_progress()
                    continue

            live_key = f"{country}||{query}".lower()
            if live_key in live_cache:
                result = live_cache[live_key]
                calls_used = 0
            else:
                if api_calls >= args.max_api_calls:
                    skipped_rate_limit_cells += 1
                    budget_exhausted = True
                    maybe_print_progress()
                    if args.stop_on_budget_hit:
                        break
                    continue

                result, calls_used = fetch_live_price(
                    api_key=api_key,
                    query=query,
                    country=country,
                    expected_currency=currency,
                    sleep_sec=args.sleep_sec,
                    request_timeout_sec=max(5, int(args.request_timeout_sec)),
                    retry_count=max(0, int(args.retry_count)),
                    retry_sleep_sec=max(0.1, float(args.retry_sleep_sec)),
                    use_search_price_only=bool(args.use_search_price_only),
                    debug_errors_left=debug_errors_left,
                )
                if calls_used > 0:
                    api_calls += calls_used
                live_cache[live_key] = result
                time.sleep(args.sleep_sec)

            if result is None:
                unresolved_cells += 1
                maybe_print_progress()
                continue

            cache_items[key] = {
                "price": result.price,
                "currency": currency,
                "country": country,
                "query": query,
                "product_id": result.product_id,
                "product_title": result.product_title,
                "source": result.source,
                "fetched_at": now_iso(),
            }
            row[currency] = format_price(result.price, currency)
            updated_cells += 1
            maybe_print_progress()

        if budget_exhausted and args.stop_on_budget_hit:
            break

        if (
            args.checkpoint_every_rows > 0
            and (row_index % args.checkpoint_every_rows) == 0
        ):
            write_csv(output_csv, fieldnames, rows)
            save_cache(cache_path, cache)
            print(
                "Checkpoint saved:",
                f"rows={row_index}/{len(rows)}",
                f"api_calls={api_calls}",
                flush=True,
            )

    write_csv(output_csv, fieldnames, rows)
    save_cache(cache_path, cache)

    print(f"Input:  {input_csv}")
    print(f"Output: {output_csv}")
    print(f"Cache:  {cache_path}")
    print(f"Rows:   {len(rows)}")
    print(f"API calls used:             {api_calls}")
    print(f"Cells updated from live:    {updated_cells}")
    print(f"Cells filled from cache:    {used_cached_cells}")
    print(f"Unresolved cells:           {unresolved_cells}")
    print(f"Skipped by API call budget: {skipped_rate_limit_cells}")
    print(f"Unsupported currency cells: {unsupported_currency_cells} (e.g. CNY)")
    if budget_exhausted and args.stop_on_budget_hit:
        print("Stopped early: API call budget reached.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
