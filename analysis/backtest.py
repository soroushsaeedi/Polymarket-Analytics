import pandas as pd
from pipeline.db import connect
from analysis.calibration import TIERS, LABELS
from scipy.stats import ttest_1samp

QUERY = "SELECT closed_at, yes_price, yes_won, volume_usd FROM mart.calibration_sample"

def load_sample():
    conn = connect()
    cur = conn.cursor()
    cur.execute(QUERY)
    rows = [tuple(r) for r in cur.fetchall()]
    conn.close()
    df = pd.DataFrame(rows, columns=["closed_at", "yes_price", "yes_won", "volume_usd"])
    df[["yes_price", "yes_won", "volume_usd"]] = df[["yes_price", "yes_won", "volume_usd"]].astype(float)
    return df

if __name__ == "__main__":
    df = load_sample()
    df["ret"] = df["yes_won"] / df["yes_price"] - 1
    trades = df[(df["yes_price"] >= 0.10) & (df["yes_price"] < 0.30)]
    print(len(trades), "trades")
    print("average return:", round(trades["ret"].mean(), 3))
    cutoff = trades["closed_at"].median()
    old = trades[trades["closed_at"] < cutoff]
    new = trades[trades["closed_at"] >= cutoff]
    print("cutoff:", cutoff)
    print("old:", len(old), round(old["ret"].mean(), 3))
    print("new:", len(new), round(new["ret"].mean(), 3))
    tier = pd.cut(trades["volume_usd"], TIERS, labels=LABELS, right=False)
    print(trades.groupby(tier, observed=True)["ret"].agg(["count", "mean"]).round(3))
    for name, g in trades.groupby(tier, observed=True):
        print(name, "p =", round(ttest_1samp(g["ret"], 0).pvalue, 3))
    COST = 0.02
    net = trades["yes_won"] / (trades["yes_price"] * (1 + COST)) - 1
    print("net of 2% cost:", round(net.mean(), 3))