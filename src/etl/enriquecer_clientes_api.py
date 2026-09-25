from pathlib import Path
import json
import logging
import time

import pandas as pd
import requests


# ============================================================
# Projeto: DataOps Analytics
# Script: enriquecer_clientes_api.py
#
# Objetivo:
# Demonstrar integração com uma API pública para enriquecer
# os dados sintéticos de clientes com CEP, cidade e UF.
#
# Estratégia:
# - consultar poucos CEPs de referência;
# - armazenar respostas em cache local;
# - evitar chamadas repetidas;
# - registrar execução e erros em log;
# - gerar um novo arquivo enriquecido sem sobrescrever
#   o arquivo RAW original.
#
# IMPORTANTE:
# Todos os clientes deste projeto são sintéticos.
# ============================================================


# ------------------------------------------------------------
# 1. CAMINHOS
# ------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parents[2]

ARQUIVO_CLIENTES = (
    BASE_DIR / "data" / "raw" / "clientes.csv"
)

PASTA_EXTERNAL = (
    BASE_DIR / "data" / "external"
)

PASTA_LOGS = (
    BASE_DIR / "logs"
)

ARQUIVO_CACHE = (
    PASTA_EXTERNAL / "cache_ceps.json"
)

ARQUIVO_SAIDA = (
    PASTA_EXTERNAL / "clientes_enriquecidos.csv"
)

ARQUIVO_LOG = (
    PASTA_LOGS / "enriquecimento_clientes.log"
)


# ------------------------------------------------------------
# 2. CRIAÇÃO DAS PASTAS
# ------------------------------------------------------------

PASTA_EXTERNAL.mkdir(
    parents=True,
    exist_ok=True,
)

PASTA_LOGS.mkdir(
    parents=True,
    exist_ok=True,
)


# ------------------------------------------------------------
# 3. CONFIGURAÇÃO DE LOGGING
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
# 4. CONFIGURAÇÕES DA API
# ------------------------------------------------------------

URL_API = (
    "https://brasilapi.com.br/api/cep/v1/{cep}"
)

TIMEOUT = 10

INTERVALO_REQUISICOES = 1


# ------------------------------------------------------------
# 5. CEPS DE REFERÊNCIA
#
# Como os clientes são sintéticos, usamos um conjunto pequeno
# de CEPs para demonstrar enriquecimento geográfico.
#
# O objetivo NÃO é realizar milhares de chamadas à API.
# ------------------------------------------------------------

CEPS_REFERENCIA = [
    "01001000",
    "20040002",
    "30140071",
    "40020000",
    "50010000",
    "60060000",
    "70040901",
    "80010000",
    "88010000",
    "90010000",
]


# ------------------------------------------------------------
# 6. FUNÇÃO PARA CARREGAR CACHE
# ------------------------------------------------------------

def carregar_cache():
    if not ARQUIVO_CACHE.exists():
        logger.info(
            "Cache ainda não existe. "
            "Será criado nesta execução."
        )
        return {}

    try:
        with open(
            ARQUIVO_CACHE,
            "r",
            encoding="utf-8",
        ) as arquivo:
            cache = json.load(arquivo)

        logger.info(
            "Cache carregado com %s CEPs.",
            len(cache),
        )

        return cache

    except (
        json.JSONDecodeError,
        OSError,
    ) as erro:
        logger.error(
            "Erro ao carregar cache: %s",
            erro,
        )
        return {}


# ------------------------------------------------------------
# 7. FUNÇÃO PARA SALVAR CACHE
# ------------------------------------------------------------

def salvar_cache(cache):
    with open(
        ARQUIVO_CACHE,
        "w",
        encoding="utf-8",
    ) as arquivo:
        json.dump(
            cache,
            arquivo,
            ensure_ascii=False,
            indent=4,
        )


# ------------------------------------------------------------
# 8. CONSULTA À API
# ------------------------------------------------------------

def consultar_cep(cep, cache):

    if cep in cache:
        logger.info(
            "CEP %s encontrado no cache.",
            cep,
        )
        return cache[cep]

    logger.info(
        "Consultando CEP %s na BrasilAPI...",
        cep,
    )

    try:
        resposta = requests.get(
            URL_API.format(cep=cep),
            timeout=TIMEOUT,
        )

        resposta.raise_for_status()

        dados = resposta.json()

        resultado = {
            "cep": dados.get("cep"),
            "cidade": dados.get("city"),
            "uf": dados.get("state"),
        }

        if not all(resultado.values()):
            raise ValueError(
                "Resposta da API possui "
                "campos obrigatórios ausentes."
            )

        cache[cep] = resultado

        # Salvamos após cada consulta bem-sucedida.
        # Assim o progresso não é perdido caso uma
        # execução seja interrompida.
        salvar_cache(cache)

        logger.info(
            "CEP %s consultado com sucesso: %s/%s.",
            cep,
            resultado["cidade"],
            resultado["uf"],
        )

        time.sleep(INTERVALO_REQUISICOES)

        return resultado

    except requests.RequestException as erro:
        logger.error(
            "Falha HTTP ao consultar CEP %s: %s",
            cep,
            erro,
        )
        return None

    except (
        ValueError,
        KeyError,
        TypeError,
    ) as erro:
        logger.error(
            "Resposta inválida para CEP %s: %s",
            cep,
            erro,
        )
        return None


# ------------------------------------------------------------
# 9. PROCESSAMENTO PRINCIPAL
# ------------------------------------------------------------

def main():

    logger.info(
        "Iniciando enriquecimento de clientes."
    )

    # --------------------------------------------------------
    # Leitura
    # --------------------------------------------------------

    df = pd.read_csv(
        ARQUIVO_CLIENTES,
        dtype={
            "id_cliente": "int64",
            "cep": "string",
            "cidade": "string",
            "uf": "string",
        },
    )

    logger.info(
        "Clientes carregados: %s",
        len(df),
    )


    # --------------------------------------------------------
    # Validação da estrutura
    # --------------------------------------------------------

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
            "Colunas ausentes no arquivo: "
            + ", ".join(sorted(faltantes))
        )


    # --------------------------------------------------------
    # Qualidade dos dados
    # --------------------------------------------------------

    if df["id_cliente"].isna().any():
        raise ValueError(
            "Existem clientes sem id_cliente."
        )

    if df["id_cliente"].duplicated().any():
        raise ValueError(
            "Existem id_cliente duplicados."
        )


    # --------------------------------------------------------
    # Cache + API
    # --------------------------------------------------------

    cache = carregar_cache()

    localidades = []

    for cep in CEPS_REFERENCIA:

        resultado = consultar_cep(
            cep,
            cache,
        )

        if resultado is not None:
            localidades.append(resultado)


    # --------------------------------------------------------
    # Verificação das consultas
    # --------------------------------------------------------

    if not localidades:
        raise RuntimeError(
            "Nenhum CEP pôde ser obtido "
            "pela API ou pelo cache."
        )

    logger.info(
        "Localidades disponíveis: %s",
        len(localidades),
    )


    # --------------------------------------------------------
    # Distribuição determinística
    #
    # O id_cliente determina a localidade.
    # Dessa forma, executar novamente o script produz
    # o mesmo resultado.
    # --------------------------------------------------------

    quantidade_localidades = len(localidades)

    def obter_localidade(id_cliente):

        indice = (
            int(id_cliente) - 1
        ) % quantidade_localidades

        return localidades[indice]


    dados_localizacao = (
        df["id_cliente"]
        .apply(obter_localidade)
    )


    df["cep"] = dados_localizacao.apply(
        lambda x: x["cep"]
    )

    df["cidade"] = dados_localizacao.apply(
        lambda x: x["cidade"]
    )

    df["uf"] = dados_localizacao.apply(
        lambda x: x["uf"]
    )


    # --------------------------------------------------------
    # Validação pós-enriquecimento
    # --------------------------------------------------------

    colunas_localizacao = [
        "cep",
        "cidade",
        "uf",
    ]

    if (
        df[colunas_localizacao]
        .isna()
        .any()
        .any()
    ):
        raise ValueError(
            "Existem clientes sem localização "
            "após o enriquecimento."
        )


    # --------------------------------------------------------
    # Exportação
    # --------------------------------------------------------

    df.to_csv(
        ARQUIVO_SAIDA,
        index=False,
        encoding="utf-8",
    )


    # --------------------------------------------------------
    # Reconciliação
    # --------------------------------------------------------

    df_saida = pd.read_csv(
        ARQUIVO_SAIDA,
        dtype={"cep": "string"},
    )

    if len(df_saida) != len(df):
        raise ValueError(
            "A quantidade de clientes na saída "
            "é diferente da origem."
        )

    if (
        df_saida["id_cliente"]
        .nunique()
        != df["id_cliente"].nunique()
    ):
        raise ValueError(
            "Divergência nos IDs após enriquecimento."
        )


    # --------------------------------------------------------
    # Resumo
    # --------------------------------------------------------

    logger.info(
        "Enriquecimento concluído com sucesso."
    )

    print(
        "\n=== RESULTADO DO ENRIQUECIMENTO ==="
    )

    print(
        f"Clientes processados: {len(df)}"
    )

    print(
        "Localidades utilizadas: "
        f"{quantidade_localidades}"
    )

    print(
        "UFs diferentes: "
        f"{df['uf'].nunique()}"
    )

    print(
        "Cidades diferentes: "
        f"{df['cidade'].nunique()}"
    )

    print(
        "Arquivo gerado:"
    )

    print(
        ARQUIVO_SAIDA
    )

    print(
        "\nAmostra:"
    )

    print(
        df[
            [
                "id_cliente",
                "nome_cliente",
                "cep",
                "cidade",
                "uf",
            ]
        ].head(10)
    )


# ------------------------------------------------------------
# 10. EXECUÇÃO
# ------------------------------------------------------------

if __name__ == "__main__":
    main()