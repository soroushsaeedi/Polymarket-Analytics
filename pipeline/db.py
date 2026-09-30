import os
from pathlib import Path

import pyodbc

def load_env(path=".env"):
    for line in Path(path).read_text().splitlines():
        if "=" in line and not line.startswith("#"):
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())

def connect():
    load_env()
    conn_str = (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=127.0.0.1,14330;"
        "DATABASE=polymarket;"
        "UID=sa;"
        f"PWD={{{os.environ['MSSQL_SA_PASSWORD']}}};"
        "TrustServerCertificate=yes;"
    )
    return pyodbc.connect(conn_str)

if __name__ == "__main__":
    conn = connect()
    print(conn.execute("SELECT DB_NAME(), SUSER_NAME()").fetchone())
    conn.close()