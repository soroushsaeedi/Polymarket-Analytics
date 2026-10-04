import json
import time
import requests
import sys

from pipeline.api import fetch_closed_markets, fetch_price_history
from pipeline.db import connect

def load_markets(max_volume=None, pages=20, page_size=100):
    conn = connect()
    cursor = conn.cursor()
    if max_volume is None:
        max_volume = cursor.execute(
            "SELECT MIN(TRY_CAST(JSON_VALUE(payload, '$.volumeNum') AS FLOAT)) FROM raw.markets"
        ).fetchval()
    print("loading markets below volume", max_volume)
    total = 0
    for page in range(pages):
        markets = fetch_closed_markets(limit=page_size, offset=page * page_size, max_volume=max_volume)
        if not markets:
            break
        cursor.executemany(
            "INSERT INTO raw.markets (market_id, payload) VALUES (?, ?)",
            [(m["id"], json.dumps(m)) for m in markets],
        )
        conn.commit()
        total += len(markets)
        print(f"page {page + 1}: {total} markets")
        time.sleep(0.2)
    conn.close()
    return total


def load_price_histories():
    conn = connect()
    cursor = conn.cursor()
    markets = cursor.execute(
        "SELECT DISTINCT market_id, JSON_VALUE(payload, '$.clobTokenIds') "
        "FROM raw.markets "
        "WHERE JSON_VALUE(payload, '$.clobTokenIds') IS NOT NULL "
        "AND JSON_VALUE(JSON_VALUE(payload, '$.outcomes'), '$[0]') = 'Yes' "
        "AND market_id NOT IN (SELECT market_id FROM raw.price_history)"
    ).fetchall()

    for i, (market_id, token_ids) in enumerate(markets, start=1):
        yes_token = json.loads(token_ids)[0]
        try:
            history = fetch_price_history(yes_token)
        except requests.RequestException as e:
            print(f"skipped {market_id}: {e}")
            continue
        cursor.execute(
            "INSERT INTO raw.price_history (market_id, token_id, payload) VALUES (?, ?, ?)",
            market_id, yes_token, json.dumps(history),
        )
        conn.commit()
        if i % 100 == 0:
            print(f"{i}/{len(markets)} histories")
        time.sleep(0.2)

    conn.close()
    return len(markets)


if __name__ == "__main__":
    max_volume = float(sys.argv[1]) if len(sys.argv) > 1 else None
    print(load_markets(max_volume), "markets loaded")
    print(load_price_histories(), "price histories loaded")