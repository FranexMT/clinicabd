import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import mysql.connector
from config import NODOS

TIMEOUT = 2
_cache_estado = {}
_cache_ts = 0
_CACHE_TTL = 5

def get_conn(nodo_id):
    cfg = NODOS[nodo_id]
    return mysql.connector.connect(
        host=cfg["host"],
        port=cfg["port"],
        user=cfg["user"],
        password=cfg["password"],
        database=cfg["database"],
        connection_timeout=TIMEOUT
    )

def query(nodo_id, sql, params=()):
    try:
        conn = get_conn(nodo_id)
        cur  = conn.cursor(dictionary=True)
        cur.execute(sql, params)
        rows = cur.fetchall()
        conn.close()
        return rows
    except Exception as e:
        print(f"[NODO {nodo_id}] Error query: {e}")
        return []

def execute(nodo_id, sql, params=()):
    try:
        conn = get_conn(nodo_id)
        cur  = conn.cursor()
        cur.execute(sql, params)
        conn.commit()
        lid = cur.lastrowid
        conn.close()
        return True, lid
    except Exception as e:
        return False, str(e)

def _ping_one(nodo_id):
    try:
        conn = get_conn(nodo_id)
        conn.close()
        return nodo_id, True
    except:
        return nodo_id, False

def ping(nodo_id):
    return _ping_one(nodo_id)[1]

def ping_all():
    global _cache_estado, _cache_ts
    now = time.time()
    if now - _cache_ts < _CACHE_TTL and _cache_estado:
        return _cache_estado
    result = {}
    with ThreadPoolExecutor(max_workers=5) as ex:
        futures = [ex.submit(_ping_one, nid) for nid in NODOS]
        for f in as_completed(futures):
            nid, ok = f.result()
            result[nid] = ok
    _cache_estado = result
    _cache_ts = now
    return result
