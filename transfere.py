# -*- coding: utf-8 -*-
from argparse import ArgumentParser
import configs
import pandas as pd
import logging

logger = logging.getLogger()

def busca_schema():
    conf = configs.le_configs()["sql"]
    return conf["schema"]

def query_do_arquivo(arquivo):
    logger.info(f"lendo query de {arquivo}")
    with open(arquivo, 'r') as f:
        query = f.read()
    return query

def transfere(query, tabela, linhas_leitura=100000, linhas_gravacao=100):
    logger.info("Conectando no firebird")
    conn_fb = configs.conexao_firebird()
    logger.info("Conectando no sql")
    conn_sql = configs.conexao_sql()

    logger.info("Fazendo leitura no firebird")
    chunks = pd.read_sql(query, con=conn_fb, chunksize=linhas_leitura)
    num_recs = 0
    schema=busca_schema()
    
    logger.info(f"Iniciando a gravação no sql")

    for chunk, df in enumerate(chunks):
        logger.info(f"gravando trecho #{chunk}")
        if chunk == 0:
            logger.info(f"Limpando tabela [{schema}].[{tabela}]")
            try:
                conn_sql.execute(f"TRUNCATE TABLE {schema}.{tabela}")
                conn_sql.execute(f"COMMIT TRAN")
            except Exception as e:
                logger.warning(str(e))
        
        chunksize = 2099 // len(df.columns)
        if chunksize > 999:
            #[42000] [Microsoft][ODBC Driver 17 for SQL Server][SQL Server]The number of row value expressions in the INSERT statement exceeds the maximum allowed number of 1000 row values. (10738) (SQLExecDirectW)
            chunksize = 999
        
        df.to_sql(tabela, conn_sql, schema=schema, if_exists='append', chunksize=chunksize)
        num_recs += len(df)

    return num_recs

def main(arquivo, tabela, linhas_leitura, linhas_gravacao):
    query = query_do_arquivo(arquivo)
    linhas = transfere(query, tabela, linhas_leitura, linhas_gravacao)
    logger.info(f"{linhas} linhas transferidas")

if __name__ == "__main__":
    parser = ArgumentParser(description="Le dados no firebird e manda pro sql")
    parser.add_argument("-a", "--arquivo", dest="arquivo", required=True,
                    help="Especifica o arquivo onde se encontra a query")
    parser.add_argument("-t", "--tabela", dest="tabela", required=True,
                    help="Especifica nome da tabela a ser gravada no SQL")
    conf_linhas = configs.le_configs()["linhas"]
    parser.add_argument("-l", "--leitura", dest="leitura", required=False, default=conf_linhas["leitura"],
                    help="Especifica quantidade de linhas na leitura")
    parser.add_argument("-g", "--gravacao", dest="gravacao", required=False, default=conf_linhas["gravacao"],
                    help="Especifica quantidade de linhas na gravacao")
    args = parser.parse_args()
    
    main(args.arquivo, args.tabela, args.leitura, args.gravacao)
