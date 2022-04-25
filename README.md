# firebird_to_sql

Como fazer para ler do pássaro de fogo e jogar para o servidor de sequências

## Uso

```powershell
transfere.py [-h] -a ARQUIVO -t TABELA
```

parâmetros:  
  -h, --help            exibe esta mensagem e encerra  
  
  -a ARQUIVO, --arquivo ARQUIVO  
        Especifica o arquivo onde se encontra a query  
  
  -t TABELA, --tabela TABELA  
        Especifica nome da tabela a ser gravada no SQL  

## Instalação de clients

Primeiro instalar o [client do firebird](https://firebirdsql.org/en/firebird-3-0-9/) e
o [ODBC para sql](https://docs.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server?view=sql-server-ver15)

Depois os requisitos

```powershell
pip install -r requirements.txt
```

## Docker

[container de firebird](https://hub.docker.com/r/jacobalberty/firebird/)

[container de sql](https://hub.docker.com/_/microsoft-mssql-server)

