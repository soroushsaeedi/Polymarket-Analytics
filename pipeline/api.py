import requests
import json

GAMMA_URL = "https://gamma-api.polymarket.com"
CLOB_URL = "https://clob.polymarket.com" 

def fetch_closed_markets(limit=100, offset=0):
    params = {"closed": "true", "limit": limit, "offset": offset, "order": "volumeNum", "ascending": "false"}
    resp = requests.get(f"{GAMMA_URL}/markets", params=params, timeout=30)
    resp.raise_for_status()
    return resp.json()

def fetch_price_history(token_id):
    params = {"market": token_id, "interval": "max", "fidelity": 1440}
    resp = requests.get(f"{CLOB_URL}/prices-history", params=params, timeout=30)
    resp.raise_for_status()
    return resp.json()["history"]

if __name__ == "__main__":
    market = fetch_closed_markets(limit=1)[0]
    yes_token = json.loads(market["clobTokenIds"])[0]
    history = fetch_price_history(yes_token)

    print(market["question"], "-", len(history), "days")
    for point in history[:3] + history[-3:]:
        print(point)