from firebird.driver import connect, driver_config
from sqlalchemy import create_engine
import json

def le_configs(arquivo = "./configs.txt"):
    with open(arquivo, 'r') as f:
        config = f.read()

    jc = json.loads(config)

    return jc

def conexao_firebird():
    conf = le_configs()["firebird"]
    driver_config.server_defaults.host.value = conf['host']
    conn_fb = connect(conf["base"], user=conf["user"], password=conf["pass"])
    return conn_fb

def conexao_sql():
    conf = le_configs()["sql"]
    conn_string = "mssql+pyodbc://{us}:{pd}@{hs}:{po}/{db}?driver=SQL+Server".format(
        us=conf["user"],
        pd=conf["pass"],
        hs=conf["host"],
        po=conf["port"],
        db=conf["base"],
    )
    engine = create_engine(conn_string)
    conn_sql = engine.connect()
    return conn_sql

