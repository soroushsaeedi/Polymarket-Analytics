import pandas as pd
from scipy.stats import binomtest
from pipeline.db import connect

QUERY = "SELECT yes_price, yes_won FROM mart.calibration_sample"


def load_sample():
    conn = connect()
    cur = conn.cursor()
    cur.execute(QUERY)
    rows = [tuple(r) for r in cur.fetchall()]
    conn.close()
    return pd.DataFrame(rows, columns=["yes_price", "yes_won"]).astype(float)


def bucket_table(df):
    df["bucket"] = (df["yes_price"] * 10).clip(upper=9).astype(int) / 10
    rows = []
    for bucket, g in df.groupby("bucket"):
        n = len(g)
        wins = int(g["yes_won"].sum())
        price = g["yes_price"].mean()
        test = binomtest(wins, n, price)
        ci = test.proportion_ci(method="wilson")
        rows.append({"bucket": bucket, "n": n, "avg_price": price,
                     "win_rate": wins / n, "ci_low": ci.low,
                     "ci_high": ci.high, "p_value": test.pvalue})
    return pd.DataFrame(rows)


def plot(table, path="analysis/calibration.png"):
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(6, 6))
    ax.plot([0, 1], [0, 1], "--", color="gray", label="perfect calibration")
    ax.errorbar(table["avg_price"], table["win_rate"],
                yerr=[table["win_rate"] - table["ci_low"],
                      table["ci_high"] - table["win_rate"]],
                fmt="o", capsize=4, label="Polymarket (95% CI)")
    ax.set_xlabel("Price 7 days before close")
    ax.set_ylabel("Actual win rate")
    ax.set_title(f"Calibration (n = {table['n'].sum()})")
    ax.legend()
    fig.savefig(path, dpi=150, bbox_inches="tight")
    print("saved", path)


if __name__ == "__main__":
    table = bucket_table(load_sample())
    print(table.round(3).to_string(index=False))
    plot(table)