from argparse import ArgumentParser
import configs
import pandas as pd

def schema():
    conf = configs.le_configs()["sql"]
    return conf["schema"]

def query_do_arquivo(arquivo):
    print(f"lendo query de {arquivo}")
    with open(arquivo, 'r') as f:
        query = f.read()
    return query

def transfere(query, tabela, linhas_leitura=None, linhas_gravacao=None):
    conn_fb = configs.conexao_firebird()
    conn_sql = configs.conexao_sql()
    conf_linhas = configs.le_configs()["linhas"]
    if not linhas_leitura:
        linhas_leitura = conf_linhas["leitura"]
    if not linhas_gravacao:
        linhas_gravacao = conf_linhas["gravacao"]

    chunks = pd.read_sql(query, con=conn_fb, chunksize=linhas_leitura)
    num_recs = 0
    print(f"gravando a cada {linhas_gravacao} linhas")

    for chunk, df in enumerate(chunks):
        print(f"gravando trecho #{chunk}")
        if_exists = 'replace' if chunk == 0 else 'append'
        df.to_sql(tabela, conn_sql, schema=schema(), if_exists=if_exists, chunksize=linhas_gravacao)
        num_recs += len(df)

    return num_recs

def main(arquivo, tabela):
    query = query_do_arquivo(arquivo)
    linhas = transfere(query, tabela)
    print(f"{linhas} linhas transferidas")

if __name__ == "__main__":
    parser = ArgumentParser(description="Lê dados no firebird e manda pro sql")
    parser.add_argument("-a", "--arquivo", dest="arquivo", required=True,
                    help="Especifica o arquivo onde se encontra a query")
    parser.add_argument("-t", "--tabela", dest="tabela", required=True,
                    help="Especifica nome da tabela a ser gravada no SQL")
    args = parser.parse_args()
    
    main(args.arquivo, args.tabela)
