from pathlib import Path
import random

import numpy as np
import pandas as pd


SEED = 42

random.seed(SEED)
np.random.seed(SEED)

BASE_DIR = Path(__file__).resolve().parents[2]

PEDIDOS_FILE = BASE_DIR / "data" / "raw" / "pedidos.csv"
PRODUTOS_FILE = BASE_DIR / "data" / "raw" / "produtos.xlsx"
OUTPUT_FILE = BASE_DIR / "data" / "raw" / "itens_pedido.csv"


def carregar_dados():
    """Carrega pedidos e produtos utilizados como referência."""

    pedidos = pd.read_csv(PEDIDOS_FILE)
    produtos = pd.read_excel(PRODUTOS_FILE)

    if pedidos.empty:
        raise ValueError("O dataset de pedidos está vazio.")

    if produtos.empty:
        raise ValueError("O dataset de produtos está vazio.")

    if not pedidos["id_pedido"].is_unique:
        raise ValueError("Existem IDs duplicados em pedidos.")

    if not produtos["id_produto"].is_unique:
        raise ValueError("Existem IDs duplicados em produtos.")

    return pedidos, produtos


def gerar_itens(pedidos, produtos):
    """Gera os itens associados aos pedidos."""

    registros = []
    id_item = 1

    produtos_lookup = produtos.set_index("id_produto")

    ids_produtos = produtos["id_produto"].to_numpy()

    for id_pedido in pedidos["id_pedido"]:

        quantidade_produtos = np.random.choice(
            [1, 2, 3, 4, 5],
            p=[0.35, 0.30, 0.20, 0.10, 0.05],
        )

        produtos_pedido = np.random.choice(
            ids_produtos,
            size=quantidade_produtos,
            replace=False,
        )

        for id_produto in produtos_pedido:

            quantidade = int(
                np.random.choice(
                    [1, 2, 3, 4],
                    p=[0.70, 0.20, 0.08, 0.02],
                )
            )

            preco_catalogo = float(
                produtos_lookup.loc[
                    id_produto,
                    "preco_unitario",
                ]
            )

            desconto_percentual = float(
                np.random.choice(
                    [0, 0.05, 0.10, 0.15],
                    p=[0.70, 0.15, 0.10, 0.05],
                )
            )

            desconto_item = round(
                preco_catalogo
                * quantidade
                * desconto_percentual,
                2,
            )

            valor_bruto = round(
                preco_catalogo * quantidade,
                2,
            )

            valor_item = round(
                valor_bruto - desconto_item,
                2,
            )

            registros.append(
                {
                    "id_item": id_item,
                    "id_pedido": int(id_pedido),
                    "id_produto": int(id_produto),
                    "quantidade": quantidade,
                    "preco_unitario": round(
                        preco_catalogo,
                        2,
                    ),
                    "desconto_item": desconto_item,
                    "valor_item": valor_item,
                }
            )

            id_item += 1

    return pd.DataFrame(registros)


def validar_itens(itens, pedidos, produtos):
    """Executa validações iniciais dos itens."""

    assert not itens.empty, (
        "O dataset de itens está vazio."
    )

    assert itens["id_item"].is_unique, (
        "Existem IDs de itens duplicados."
    )

    assert itens["id_item"].notna().all()
    assert itens["id_pedido"].notna().all()
    assert itens["id_produto"].notna().all()

    assert itens["id_pedido"].isin(
        pedidos["id_pedido"]
    ).all(), (
        "Existem itens associados a pedidos inexistentes."
    )

    assert itens["id_produto"].isin(
        produtos["id_produto"]
    ).all(), (
        "Existem itens associados a produtos inexistentes."
    )

    assert (itens["quantidade"] > 0).all()

    assert (itens["preco_unitario"] > 0).all()

    assert (itens["desconto_item"] >= 0).all()

    assert (itens["valor_item"] > 0).all()

    pedidos_sem_itens = (
        set(pedidos["id_pedido"])
        - set(itens["id_pedido"])
    )

    assert not pedidos_sem_itens, (
        "Existem pedidos sem itens."
    )

    duplicidade_produto_pedido = itens.duplicated(
        subset=["id_pedido", "id_produto"]
    ).sum()

    assert duplicidade_produto_pedido == 0, (
        "Um mesmo produto aparece repetido no mesmo pedido."
    )


def main():
    pedidos, produtos = carregar_dados()

    itens = gerar_itens(
        pedidos,
        produtos,
    )

    validar_itens(
        itens,
        pedidos,
        produtos,
    )

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    itens.to_csv(
        OUTPUT_FILE,
        index=False,
        encoding="utf-8",
    )

    print("=== DataOps Analytics ===")
    print("Dataset: Itens do Pedido")
    print(f"Registros gerados: {len(itens):,}")
    print(
        f"IDs únicos: "
        f"{itens['id_item'].nunique():,}"
    )
    print(
        f"Pedidos representados: "
        f"{itens['id_pedido'].nunique():,}"
    )
    print(
        f"Produtos utilizados: "
        f"{itens['id_produto'].nunique():,}"
    )
    print(f"Arquivo: {OUTPUT_FILE}")
    print(
        "Integridade Pedidos -> Itens validada."
    )
    print(
        "Integridade Produtos -> Itens validada."
    )
    print("Validações concluídas com sucesso.")


if __name__ == "__main__":
    main()