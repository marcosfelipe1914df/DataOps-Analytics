from pathlib import Path
import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text


# ============================================================
# Projeto: DataOps Analytics
# Script: carregar_estoque.py
# Objetivo:
# Ler estoque.xlsx, validar a qualidade dos dados e carregar
# a tabela raw.estoque no PostgreSQL.
# ============================================================


# ------------------------------------------------------------
# 1. CAMINHOS DO PROJETO
# ------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parents[2]
ARQUIVO_ESTOQUE = BASE_DIR / "data" / "raw" / "estoque.xlsx"
ARQUIVO_ENV = BASE_DIR / ".env"


# ------------------------------------------------------------
# 2. VARIÁVEIS DE AMBIENTE
# ------------------------------------------------------------

load_dotenv(ARQUIVO_ENV)

USUARIO = os.getenv("POSTGRES_USER")
SENHA = os.getenv("POSTGRES_PASSWORD")
HOST = os.getenv("POSTGRES_HOST")
PORTA = os.getenv("POSTGRES_PORT")
BANCO = os.getenv("POSTGRES_DB")

variaveis_obrigatorias = {
    "POSTGRES_USER": USUARIO,
    "POSTGRES_PASSWORD": SENHA,
    "POSTGRES_HOST": HOST,
    "POSTGRES_PORT": PORTA,
    "POSTGRES_DB": BANCO,
}

variaveis_ausentes = [
    nome
    for nome, valor in variaveis_obrigatorias.items()
    if not valor
]

if variaveis_ausentes:
    raise ValueError(
        "Variáveis de ambiente ausentes: "
        + ", ".join(variaveis_ausentes)
    )


# ------------------------------------------------------------
# 3. CONEXÃO COM O POSTGRESQL
# ------------------------------------------------------------

URL_CONEXAO = (
    f"postgresql+psycopg://{USUARIO}:{SENHA}"
    f"@{HOST}:{PORTA}/{BANCO}"
)


# ------------------------------------------------------------
# 4. LEITURA DO EXCEL
# ------------------------------------------------------------

print("Lendo estoque.xlsx...")

df = pd.read_excel(ARQUIVO_ESTOQUE)

print(f"Registros encontrados: {len(df)}")


# ------------------------------------------------------------
# 5. VALIDAÇÃO DA ESTRUTURA
# ------------------------------------------------------------

colunas_esperadas = [
    "id_estoque",
    "id_produto",
    "data_referencia",
    "quantidade_disponivel",
    "estoque_minimo",
    "quantidade_reservada",
]

if list(df.columns) != colunas_esperadas:
    raise ValueError(
        "As colunas de estoque.xlsx são diferentes das esperadas."
    )


# ------------------------------------------------------------
# 6. VALIDAÇÕES DE QUALIDADE
# ------------------------------------------------------------

if df.isna().any().any():
    raise ValueError("Existem valores nulos em estoque.xlsx.")

if df["id_estoque"].duplicated().any():
    raise ValueError("Existem id_estoque duplicados.")

if df.duplicated(
    subset=["id_produto", "data_referencia"]
).any():
    raise ValueError(
        "Existem registros duplicados de produto + data."
    )

if (df["quantidade_disponivel"] < 0).any():
    raise ValueError(
        "Existem quantidades disponíveis negativas."
    )

if (df["estoque_minimo"] < 0).any():
    raise ValueError(
        "Existem valores de estoque mínimo negativos."
    )

if (df["quantidade_reservada"] < 0).any():
    raise ValueError(
        "Existem quantidades reservadas negativas."
    )

if (
    df["quantidade_reservada"]
    > df["quantidade_disponivel"]
).any():
    raise ValueError(
        "Existem quantidades reservadas maiores "
        "que as quantidades disponíveis."
    )

print("Validações locais concluídas com sucesso.")


# ------------------------------------------------------------
# 7. CONEXÃO COM O POSTGRESQL
# ------------------------------------------------------------

engine = create_engine(URL_CONEXAO)

print("Conectando ao PostgreSQL...")


# ------------------------------------------------------------
# 8. VALIDAÇÃO DAS CHAVES DE PRODUTO
# ------------------------------------------------------------

with engine.connect() as conexao:

    produtos_banco = pd.read_sql(
        """
        SELECT id_produto
        FROM raw.produtos
        """,
        conexao,
    )

ids_produtos_banco = set(produtos_banco["id_produto"])
ids_produtos_estoque = set(df["id_produto"])

produtos_invalidos = (
    ids_produtos_estoque - ids_produtos_banco
)

if produtos_invalidos:
    raise ValueError(
        "Existem produtos inexistentes no banco: "
        f"{sorted(produtos_invalidos)[:10]}"
    )

print("Chaves de produto validadas com sucesso.")


# ------------------------------------------------------------
# 9. CARGA
# ------------------------------------------------------------

print("Carregando dados no PostgreSQL...")

with engine.begin() as conexao:

    # Permite reexecutar esta carga sem duplicar registros.
    conexao.execute(
        text("TRUNCATE TABLE raw.estoque")
    )

    df.to_sql(
        name="estoque",
        con=conexao,
        schema="raw",
        if_exists="append",
        index=False,
        method="multi",
        chunksize=1000,
    )


# ------------------------------------------------------------
# 10. VALIDAÇÃO PÓS-CARGA
# ------------------------------------------------------------

with engine.connect() as conexao:

    resultado = conexao.execute(
        text(
            """
            SELECT
                COUNT(*) AS total_registros,
                COUNT(DISTINCT id_estoque) AS ids_unicos,
                COUNT(DISTINCT id_produto) AS produtos,
                COUNT(DISTINCT data_referencia) AS meses,

                COUNT(*) FILTER (
                    WHERE quantidade_disponivel < estoque_minimo
                ) AS abaixo_minimo,

                COUNT(*) FILTER (
                    WHERE quantidade_disponivel = 0
                ) AS estoque_zero

            FROM raw.estoque
            """
        )
    ).mappings().one()


# ------------------------------------------------------------
# 11. RECONCILIAÇÃO
# ------------------------------------------------------------

print("\n=== RESULTADO DA CARGA ===")
print(f"Registros no Excel: {len(df)}")
print(
    "Registros no PostgreSQL: "
    f"{resultado['total_registros']}"
)
print(f"IDs únicos: {resultado['ids_unicos']}")
print(f"Produtos: {resultado['produtos']}")
print(f"Meses: {resultado['meses']}")
print(
    "Posições abaixo do mínimo: "
    f"{resultado['abaixo_minimo']}"
)
print(
    "Posições com estoque zero: "
    f"{resultado['estoque_zero']}"
)

if resultado["total_registros"] != len(df):
    raise ValueError(
        "A quantidade no PostgreSQL não corresponde ao Excel."
    )

if resultado["ids_unicos"] != len(df):
    raise ValueError(
        "Existem divergências na unicidade de id_estoque."
    )

if resultado["produtos"] != 500:
    raise ValueError(
        "A quantidade de produtos no estoque não é 500."
    )

if resultado["meses"] != 24:
    raise ValueError(
        "A quantidade de meses no estoque não é 24."
    )

print("Carga de estoque concluída com sucesso!")