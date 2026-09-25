from pathlib import Path
import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text


# ============================================================
# Projeto: DataOps Analytics
# Script: carregar_produtos.py
# Objetivo:
# Ler produtos.xlsx, validar os dados e carregar a tabela
# raw.produtos no PostgreSQL.
# ============================================================


# ------------------------------------------------------------
# 1. CAMINHOS DO PROJETO
# ------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parents[2]
ARQUIVO_PRODUTOS = BASE_DIR / "data" / "raw" / "produtos.xlsx"
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

print("Lendo produtos.xlsx...")

df = pd.read_excel(ARQUIVO_PRODUTOS)

print(f"Registros encontrados: {len(df)}")


# ------------------------------------------------------------
# 5. VALIDAÇÕES DE QUALIDADE
# ------------------------------------------------------------

colunas_esperadas = [
    "id_produto",
    "nome_produto",
    "categoria",
    "subcategoria",
    "marca",
    "custo_unitario",
    "preco_unitario",
    "status_produto",
]

if list(df.columns) != colunas_esperadas:
    raise ValueError(
        "As colunas de produtos.xlsx são diferentes das esperadas."
    )

if df["id_produto"].isna().any():
    raise ValueError("Existem produtos sem id_produto.")

if df["id_produto"].duplicated().any():
    raise ValueError("Existem id_produto duplicados.")

if df.isna().any().any():
    raise ValueError("Existem valores nulos em produtos.xlsx.")

if (df["custo_unitario"] < 0).any():
    raise ValueError("Existem produtos com custo negativo.")

if (df["preco_unitario"] <= df["custo_unitario"]).any():
    raise ValueError(
        "Existem produtos cujo preço é menor ou igual ao custo."
    )

print("Validações de qualidade concluídas com sucesso.")


# ------------------------------------------------------------
# 6. CONEXÃO E CARGA
# ------------------------------------------------------------

engine = create_engine(URL_CONEXAO)

print("Conectando ao PostgreSQL...")

with engine.begin() as conexao:

    conexao.execute(text("SELECT 1"))

    # Permite reexecutar a carga sem duplicar produtos.
    conexao.execute(
        text("TRUNCATE TABLE raw.produtos CASCADE")
    )

    df.to_sql(
        name="produtos",
        con=conexao,
        schema="raw",
        if_exists="append",
        index=False,
        method="multi",
        chunksize=500,
    )


# ------------------------------------------------------------
# 7. VALIDAÇÃO PÓS-CARGA
# ------------------------------------------------------------

with engine.connect() as conexao:

    total_banco = conexao.execute(
        text("SELECT COUNT(*) FROM raw.produtos")
    ).scalar_one()

    produtos_unicos = conexao.execute(
        text(
            """
            SELECT COUNT(DISTINCT id_produto)
            FROM raw.produtos
            """
        )
    ).scalar_one()


# ------------------------------------------------------------
# 8. RECONCILIAÇÃO
# ------------------------------------------------------------

print("\n=== RESULTADO DA CARGA ===")
print(f"Registros no Excel: {len(df)}")
print(f"Registros no PostgreSQL: {total_banco}")
print(f"Produtos únicos: {produtos_unicos}")

if total_banco != len(df):
    raise ValueError(
        "A quantidade carregada no PostgreSQL não corresponde ao Excel."
    )

if produtos_unicos != len(df):
    raise ValueError(
        "A quantidade de produtos únicos não corresponde ao esperado."
    )

print("Carga de produtos concluída com sucesso!")