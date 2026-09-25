from pathlib import Path
import logging
import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text


# ============================================================
# Projeto: DataOps Analytics
# Script: carregar_clientes_enriquecidos.py
#
# Objetivo:
# Atualizar no PostgreSQL os dados geográficos obtidos
# pelo processo de enriquecimento via API pública.
#
# Estratégia:
# - ler clientes_enriquecidos.csv;
# - validar estrutura e qualidade;
# - validar correspondência dos IDs com raw.clientes;
# - atualizar somente cep, cidade e uf;
# - executar tudo dentro de uma transação;
# - reconciliar o resultado após a atualização.
#
# Não utiliza TRUNCATE para preservar relacionamentos.
# ============================================================


# ------------------------------------------------------------
# 1. CAMINHOS E VARIÁVEIS DE AMBIENTE
# ------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parents[2]

ARQUIVO_CLIENTES = (
    BASE_DIR
    / "data"
    / "external"
    / "clientes_enriquecidos.csv"
)

ARQUIVO_ENV = BASE_DIR / ".env"

PASTA_LOGS = BASE_DIR / "logs"

PASTA_LOGS.mkdir(
    parents=True,
    exist_ok=True,
)

ARQUIVO_LOG = (
    PASTA_LOGS
    / "carga_clientes_enriquecidos.log"
)

load_dotenv(ARQUIVO_ENV)


# ------------------------------------------------------------
# 2. LOGGING
# ------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format=(
        "%(asctime)s | "
        "%(levelname)s | "
        "%(message)s"
    ),
    handlers=[
        logging.FileHandler(
            ARQUIVO_LOG,
            encoding="utf-8",
        ),
        logging.StreamHandler(),
    ],
)

logger = logging.getLogger(__name__)


# ------------------------------------------------------------
# 3. CONEXÃO
# ------------------------------------------------------------

POSTGRES_DB = os.getenv("POSTGRES_DB")
POSTGRES_USER = os.getenv("POSTGRES_USER")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")
POSTGRES_HOST = os.getenv("POSTGRES_HOST")
POSTGRES_PORT = os.getenv("POSTGRES_PORT")


variaveis_obrigatorias = {
    "POSTGRES_DB": POSTGRES_DB,
    "POSTGRES_USER": POSTGRES_USER,
    "POSTGRES_PASSWORD": POSTGRES_PASSWORD,
    "POSTGRES_HOST": POSTGRES_HOST,
    "POSTGRES_PORT": POSTGRES_PORT,
}

variaveis_ausentes = [
    nome
    for nome, valor in variaveis_obrigatorias.items()
    if not valor
]

if variaveis_ausentes:
    raise RuntimeError(
        "Variáveis ausentes no .env: "
        + ", ".join(variaveis_ausentes)
    )


URL_BANCO = (
    f"postgresql+psycopg://"
    f"{POSTGRES_USER}:"
    f"{POSTGRES_PASSWORD}@"
    f"{POSTGRES_HOST}:"
    f"{POSTGRES_PORT}/"
    f"{POSTGRES_DB}"
)

engine = create_engine(URL_BANCO)


# ------------------------------------------------------------
# 4. LEITURA E VALIDAÇÃO DO CSV
# ------------------------------------------------------------

def carregar_arquivo():

    logger.info(
        "Lendo arquivo de clientes enriquecidos."
    )

    df = pd.read_csv(
        ARQUIVO_CLIENTES,
        dtype={
            "id_cliente": "int64",
            "cep": "string",
            "cidade": "string",
            "uf": "string",
        },
    )

    colunas_obrigatorias = {
        "id_cliente",
        "nome_cliente",
        "data_cadastro",
        "cep",
        "cidade",
        "uf",
        "segmento_cliente",
        "status_cliente",
    }

    faltantes = (
        colunas_obrigatorias
        - set(df.columns)
    )

    if faltantes:
        raise ValueError(
            "Colunas ausentes: "
            + ", ".join(sorted(faltantes))
        )

    if df.empty:
        raise ValueError(
            "O arquivo de clientes está vazio."
        )

    if df["id_cliente"].isna().any():
        raise ValueError(
            "Existem clientes sem id_cliente."
        )

    if df["id_cliente"].duplicated().any():
        raise ValueError(
            "Existem id_cliente duplicados."
        )

    campos_localizacao = [
        "cep",
        "cidade",
        "uf",
    ]

    if (
        df[campos_localizacao]
        .isna()
        .any()
        .any()
    ):
        raise ValueError(
            "Existem dados de localização nulos."
        )

    logger.info(
        "Arquivo validado: %s clientes.",
        len(df),
    )

    return df


# ------------------------------------------------------------
# 5. ATUALIZAÇÃO NO POSTGRESQL
# ------------------------------------------------------------

def atualizar_clientes(df):

    registros = (
        df[
            [
                "id_cliente",
                "cep",
                "cidade",
                "uf",
            ]
        ]
        .to_dict(orient="records")
    )

    with engine.begin() as conexao:

        # ----------------------------------------------------
        # Validação antes da alteração
        # ----------------------------------------------------

        resultado = conexao.execute(
            text(
                """
                SELECT
                    COUNT(*) AS total,
                    COUNT(DISTINCT id_cliente)
                        AS ids_unicos
                FROM raw.clientes;
                """
            )
        ).mappings().one()

        total_banco = resultado["total"]
        ids_unicos_banco = resultado["ids_unicos"]

        logger.info(
            "PostgreSQL antes da atualização: "
            "%s clientes / %s IDs únicos.",
            total_banco,
            ids_unicos_banco,
        )

        if total_banco != len(df):
            raise ValueError(
                "Quantidade de clientes do CSV "
                "difere de raw.clientes."
            )

        # ----------------------------------------------------
        # Validação de correspondência das chaves
        # ----------------------------------------------------

        ids_banco = {
            linha[0]
            for linha in conexao.execute(
                text(
                    """
                    SELECT id_cliente
                    FROM raw.clientes;
                    """
                )
            )
        }

        ids_arquivo = set(
            df["id_cliente"].tolist()
        )

        if ids_banco != ids_arquivo:

            somente_banco = (
                ids_banco - ids_arquivo
            )

            somente_arquivo = (
                ids_arquivo - ids_banco
            )

            raise ValueError(
                "Divergência de IDs. "
                f"Somente no banco: "
                f"{len(somente_banco)}. "
                f"Somente no arquivo: "
                f"{len(somente_arquivo)}."
            )

        # ----------------------------------------------------
        # UPDATE parametrizado
        #
        # SQLAlchemy executará o mesmo comando para os
        # registros fornecidos, sem concatenar valores
        # diretamente na instrução SQL.
        # ----------------------------------------------------

        logger.info(
            "Atualizando localização dos clientes."
        )

        comando_update = text(
            """
            UPDATE raw.clientes
            SET
                cep = :cep,
                cidade = :cidade,
                uf = :uf
            WHERE id_cliente = :id_cliente;
            """
        )

        conexao.execute(
            comando_update,
            registros,
        )

        # ----------------------------------------------------
        # Reconciliação ainda dentro da transação
        # ----------------------------------------------------

        validacao = conexao.execute(
            text(
                """
                SELECT
                    COUNT(*) AS total_clientes,

                    COUNT(*) FILTER (
                        WHERE cep IS NOT NULL
                    ) AS clientes_com_cep,

                    COUNT(*) FILTER (
                        WHERE cidade IS NOT NULL
                    ) AS clientes_com_cidade,

                    COUNT(*) FILTER (
                        WHERE uf IS NOT NULL
                    ) AS clientes_com_uf,

                    COUNT(DISTINCT cidade)
                        AS cidades,

                    COUNT(DISTINCT uf)
                        AS ufs

                FROM raw.clientes;
                """
            )
        ).mappings().one()

        if (
            validacao["clientes_com_cep"]
            != len(df)
            or validacao["clientes_com_cidade"]
            != len(df)
            or validacao["clientes_com_uf"]
            != len(df)
        ):
            raise ValueError(
                "A reconciliação da atualização falhou."
            )

        logger.info(
            "Reconciliação concluída com sucesso."
        )

        return dict(validacao)


# ------------------------------------------------------------
# 6. EXECUÇÃO
# ------------------------------------------------------------

def main():

    logger.info(
        "Iniciando carga de clientes enriquecidos."
    )

    df = carregar_arquivo()

    resultado = atualizar_clientes(df)

    logger.info(
        "Carga concluída com sucesso."
    )

    print(
        "\n=== RESULTADO DA CARGA ==="
    )

    print(
        f"Clientes no PostgreSQL: "
        f"{resultado['total_clientes']}"
    )

    print(
        f"Clientes com CEP: "
        f"{resultado['clientes_com_cep']}"
    )

    print(
        f"Clientes com cidade: "
        f"{resultado['clientes_com_cidade']}"
    )

    print(
        f"Clientes com UF: "
        f"{resultado['clientes_com_uf']}"
    )

    print(
        f"Cidades diferentes: "
        f"{resultado['cidades']}"
    )

    print(
        f"UFs diferentes: "
        f"{resultado['ufs']}"
    )


if __name__ == "__main__":
    main()