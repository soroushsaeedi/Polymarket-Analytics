import pandas as pd
from scipy.stats import ttest_1samp
from pipeline.db import connect

FACTORS = ["yes_price", "momentum_7d", "volatility_30d", "age_days"]

def load_factors():
    conn = connect()
    cur = conn.cursor()
    cur.execute("SELECT yes_won, " + ", ".join(FACTORS) + " FROM mart.factors")
    rows = [tuple(r) for r in cur.fetchall()]
    conn.close()
    df = pd.DataFrame(rows, columns=["yes_won"] + FACTORS).astype(float)
    df["error"] = df["yes_won"] - df["yes_price"]
    return df

def factor_table(df, factor, target="error"):
    d = df.dropna(subset=[factor]).copy()
    d["group"] = pd.qcut(d[factor].rank(method="first"), 3, labels=["low", "mid", "high"])
    rows = []
    for group, g in d.groupby("group", observed=True):
        test = ttest_1samp(g[target], 0)
        ci = test.confidence_interval()
        rows.append({"factor": factor, "group": group, "n": len(g),
                     "factor_mean": g[factor].mean(), "avg_error": g[target].mean(),
                     "ci_low": ci.low, "ci_high": ci.high, "p_value": test.pvalue})
    return pd.DataFrame(rows)

if __name__ == "__main__":
    df = load_factors()
    table = pd.concat([factor_table(df, f) for f in FACTORS])
    print(table.round(3).to_string(index=False))
    df["bucket"] = (df["yes_price"] * 10).clip(upper=9).astype(int)
    df["bucket_error"] = df.groupby("bucket")["error"].transform("mean")
    df["error_adj"] = df["error"] - df["bucket_error"]
    print()
    adj = pd.concat([factor_table(df, f, "error_adj") for f in FACTORS[1:]])
    print(adj.round(3).to_string(index=False))