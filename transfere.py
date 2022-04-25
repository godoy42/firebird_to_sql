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

def transfere(query, tabela, linhas_leitura=10000, linhas_gravacao=100):
    conn_fb = configs.conexao_firebird()
    conn_sql = configs.conexao_sql()

    chunks = pd.read_sql(query, con=conn_fb, chunksize=linhas_leitura)
    num_recs = 0
    print(f"gravando a cada {linhas_gravacao} linhas")

    for chunk, df in enumerate(chunks):
        print(f"gravando trecho #{chunk}")
        if_exists = 'replace' if chunk == 0 else 'append'
        df.to_sql(tabela, conn_sql, schema=schema(), if_exists=if_exists, chunksize=linhas_gravacao)
        num_recs += len(df)

    return num_recs

def main(arquivo, tabela, linhas_leitura, linhas_gravacao):
    query = query_do_arquivo(arquivo)
    linhas = transfere(query, tabela, linhas_leitura, linhas_gravacao)
    print(f"{linhas} linhas transferidas")

if __name__ == "__main__":
    parser = ArgumentParser(description="Lê dados no firebird e manda pro sql")
    parser.add_argument("-a", "--arquivo", dest="arquivo", required=True,
                    help="Especifica o arquivo onde se encontra a query")
    parser.add_argument("-t", "--tabela", dest="tabela", required=True,
                    help="Especifica nome da tabela a ser gravada no SQL")
    conf_linhas = configs.le_configs()["linhas"]
    parser.add_argument("-l", "--leitura", dest="leitura", required=False, default=conf_linhas["leitura"],
                    help="Especifica quantidade de linhas na leitura")
    parser.add_argument("-g", "--gravacao", dest="gravacao", required=False, default=conf_linhas["gravacao"],
                    help="Especifica quantidade de linhas na gravação")
    args = parser.parse_args()
    
    main(args.arquivo, args.tabela, args.leitura, args.gravacao)
