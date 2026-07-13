import os
import sys
import psycopg2

password = os.environ.get("PGPASS")
if not password:
    print("PGPASS env var not set"); sys.exit(1)

conn = psycopg2.connect(
    host="db.qavrkkgcgqgtrlrmqyfe.supabase.co",
    port=5432,
    user="postgres",
    password=password,
    dbname="postgres",
    sslmode="require",
)
conn.autocommit = True
cur = conn.cursor()

with open(os.path.join(os.path.dirname(__file__), "_staging_bootstrap.sql")) as f:
    sql = f.read()

try:
    cur.execute(sql)
    print("DONE — bootstrap ran successfully")
except Exception as e:
    print("ERROR:", e)
    sys.exit(1)
finally:
    cur.close()
    conn.close()
