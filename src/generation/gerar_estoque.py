from pathlib import Path
import random

import numpy as np
import pandas as pd


SEED = 42

random.seed(SEED)
np.random.seed(SEED)

BASE_DIR = Path(__file__).resolve().parents[2]

PRODUTOS_FILE = BASE_DIR / "data" / "raw" / "produtos.xlsx"
OUTPUT_FILE = BASE_DIR / "data" / "raw" / "estoque.xlsx"


def carregar_produtos():
    """Carrega o cadastro de produtos."""

    produtos = pd.read_excel(PRODUTOS_FILE)

    if produtos.empty:
        raise ValueError("O dataset de produtos está vazio.")

    if not produtos["id_produto"].is_unique:
        raise ValueError(
            "Existem IDs duplicados no dataset de produtos."
        )

    return produtos


def gerar_estoque(produtos):
    """Gera posições mensais de estoque para cada produto."""

    # Uma posição no último dia de cada mês.
    datas_referencia = pd.date_range(
        start="2024-01-31",
        end="2025-12-31",
        freq="ME",
    )

    registros = []
    id_estoque = 1

    for produto in produtos.itertuples(index=False):

        # Cada produto possui um estoque mínimo relativamente estável.
        estoque_minimo = int(
            np.random.randint(5, 31)
        )

        # Posição inicial.
        quantidade_atual = int(
            np.random.randint(
                estoque_minimo,
                estoque_minimo + 121,
            )
        )

        for data_referencia in datas_referencia:

            # Simula entradas e saídas mensais.
            variacao = int(
                np.random.randint(-40, 41)
            )

            quantidade_atual = max(
                0,
                quantidade_atual + variacao,
            )

            # Uma parcela do estoque pode estar reservada.
            if quantidade_atual == 0:
                quantidade_reservada = 0
            else:
                limite_reserva = min(
                    quantidade_atual,
                    20,
                )

                quantidade_reservada = int(
                    np.random.randint(
                        0,
                        limite_reserva + 1,
                    )
                )

            registros.append(
                {
                    "id_estoque": id_estoque,
                    "id_produto": int(
                        produto.id_produto
                    ),
                    "data_referencia": data_referencia,
                    "quantidade_disponivel": quantidade_atual,
                    "estoque_minimo": estoque_minimo,
                    "quantidade_reservada": quantidade_reservada,
                }
            )

            id_estoque += 1

    return pd.DataFrame(registros)


def validar_estoque(estoque, produtos):
    """Executa validações do histórico de estoque."""

    total_esperado = len(produtos) * 24

    assert len(estoque) == total_esperado, (
        "Quantidade incorreta de registros de estoque."
    )

    assert estoque["id_estoque"].is_unique, (
        "Existem IDs de estoque duplicados."
    )

    assert estoque["id_produto"].isin(
        produtos["id_produto"]
    ).all(), (
        "Existem registros associados "
        "a produtos inexistentes."
    )

    assert estoque[
        [
            "id_estoque",
            "id_produto",
            "data_referencia",
            "quantidade_disponivel",
            "estoque_minimo",
            "quantidade_reservada",
        ]
    ].notna().all().all(), (
        "Existem valores nulos no estoque."
    )

    assert (
        estoque["quantidade_disponivel"] >= 0
    ).all(), (
        "Existem quantidades disponíveis negativas."
    )

    assert (
        estoque["estoque_minimo"] > 0
    ).all(), (
        "Existem valores inválidos de estoque mínimo."
    )

    assert (
        estoque["quantidade_reservada"] >= 0
    ).all(), (
        "Existem quantidades reservadas negativas."
    )

    assert (
        estoque["quantidade_reservada"]
        <= estoque["quantidade_disponivel"]
    ).all(), (
        "Existem reservas superiores "
        "ao estoque disponível."
    )

    # Cada produto deve possuir exatamente
    # uma posição para cada mês.
    duplicados = estoque.duplicated(
        subset=[
            "id_produto",
            "data_referencia",
        ]
    ).sum()

    assert duplicados == 0, (
        "Existem posições mensais duplicadas."
    )

    registros_por_produto = (
        estoque.groupby("id_produto")
        .size()
    )

    assert (
        registros_por_produto == 24
    ).all(), (
        "Existem produtos sem 24 posições mensais."
    )


def main():
    produtos = carregar_produtos()

    estoque = gerar_estoque(produtos)

    validar_estoque(
        estoque,
        produtos,
    )

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    estoque.to_excel(
        OUTPUT_FILE,
        index=False,
        sheet_name="estoque",
        engine="openpyxl",
    )

    abaixo_minimo = (
        estoque["quantidade_disponivel"]
        < estoque["estoque_minimo"]
    ).sum()

    estoque_zerado = (
        estoque["quantidade_disponivel"] == 0
    ).sum()

    print("=== DataOps Analytics ===")
    print("Dataset: Estoque")

    print(
        f"Registros gerados: "
        f"{len(estoque):,}"
    )

    print(
        f"IDs únicos: "
        f"{estoque['id_estoque'].nunique():,}"
    )

    print(
        f"Produtos representados: "
        f"{estoque['id_produto'].nunique():,}"
    )

    print(
        "Meses por produto: 24"
    )

    print(
        "Posições abaixo do estoque mínimo:",
        abaixo_minimo,
    )

    print(
        "Posições com estoque zerado:",
        estoque_zerado,
    )

    print(f"Arquivo: {OUTPUT_FILE}")

    print(
        "Integridade Produtos -> Estoque validada."
    )

    print(
        "Validações concluídas com sucesso."
    )


if __name__ == "__main__":
    main()