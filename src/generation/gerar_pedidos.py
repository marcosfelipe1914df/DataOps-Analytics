from pathlib import Path
import random

import numpy as np
import pandas as pd


SEED = 42
TOTAL_PEDIDOS = 50_000

random.seed(SEED)
np.random.seed(SEED)

BASE_DIR = Path(__file__).resolve().parents[2]

CLIENTES_FILE = BASE_DIR / "data" / "raw" / "clientes.csv"
OUTPUT_FILE = BASE_DIR / "data" / "raw" / "pedidos.csv"


def carregar_clientes():
    """Carrega os clientes utilizados como referência."""

    clientes = pd.read_csv(CLIENTES_FILE)

    if clientes.empty:
        raise ValueError("O dataset de clientes está vazio.")

    if not clientes["id_cliente"].is_unique:
        raise ValueError("Existem IDs duplicados em clientes.")

    return clientes


def gerar_pedidos(clientes):
    """Gera os pedidos sintéticos da DataOps Commerce."""

    ids_pedidos = np.arange(1, TOTAL_PEDIDOS + 1)

    ids_clientes = np.random.choice(
        clientes["id_cliente"].to_numpy(),
        size=TOTAL_PEDIDOS,
        replace=True,
    )

    inicio = pd.Timestamp("2024-01-01 00:00:00")
    fim = pd.Timestamp("2025-12-31 23:59:59")

    total_segundos = int((fim - inicio).total_seconds())

    segundos_aleatorios = np.random.randint(
        0,
        total_segundos + 1,
        size=TOTAL_PEDIDOS,
    )

    datas_pedido = inicio + pd.to_timedelta(
        segundos_aleatorios,
        unit="s",
    )

    canais = np.random.choice(
        ["Site", "App", "Marketplace"],
        size=TOTAL_PEDIDOS,
        p=[0.45, 0.35, 0.20],
    )

    status = np.random.choice(
        [
            "Concluido",
            "Cancelado",
            "Em processamento",
        ],
        size=TOTAL_PEDIDOS,
        p=[0.88, 0.07, 0.05],
    )

    valores_frete = np.round(
        np.random.uniform(0, 35, size=TOTAL_PEDIDOS),
        2,
    )

    # Parte dos pedidos terá frete grátis.
    frete_gratis = np.random.random(TOTAL_PEDIDOS) < 0.15
    valores_frete[frete_gratis] = 0.0

    descontos = np.round(
        np.random.choice(
            [0, 5, 10, 15, 20, 25, 30],
            size=TOTAL_PEDIDOS,
            p=[0.55, 0.10, 0.10, 0.08, 0.07, 0.05, 0.05],
        ),
        2,
    )

    pedidos = pd.DataFrame(
        {
            "id_pedido": ids_pedidos,
            "id_cliente": ids_clientes,
            "data_pedido": datas_pedido,
            "canal_venda": canais,
            "status_pedido": status,
            "valor_frete": valores_frete,
            "desconto_pedido": descontos,
            "valor_total": pd.NA,
        }
    )

    pedidos = pedidos.sort_values(
        "id_pedido"
    ).reset_index(drop=True)

    return pedidos


def validar_pedidos(pedidos, clientes):
    """Executa validações iniciais dos pedidos."""

    assert len(pedidos) == TOTAL_PEDIDOS, (
        "Quantidade incorreta de pedidos."
    )

    assert pedidos["id_pedido"].is_unique, (
        "Existem IDs de pedidos duplicados."
    )

    assert pedidos["id_pedido"].notna().all()
    assert pedidos["id_cliente"].notna().all()
    assert pedidos["data_pedido"].notna().all()

    clientes_validos = set(
        clientes["id_cliente"].tolist()
    )

    clientes_pedidos = set(
        pedidos["id_cliente"].tolist()
    )

    clientes_inexistentes = (
        clientes_pedidos - clientes_validos
    )

    assert not clientes_inexistentes, (
        "Existem pedidos associados a clientes inexistentes."
    )

    assert (
        pedidos["data_pedido"].min()
        >= pd.Timestamp("2024-01-01")
    )

    assert (
        pedidos["data_pedido"].max()
        <= pd.Timestamp("2025-12-31 23:59:59")
    )

    assert (pedidos["valor_frete"] >= 0).all()

    assert (pedidos["desconto_pedido"] >= 0).all()

    assert pedidos["canal_venda"].isin(
        ["Site", "App", "Marketplace"]
    ).all()

    assert pedidos["status_pedido"].isin(
        [
            "Concluido",
            "Cancelado",
            "Em processamento",
        ]
    ).all()


def main():
    clientes = carregar_clientes()

    pedidos = gerar_pedidos(clientes)

    validar_pedidos(
        pedidos,
        clientes,
    )

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    pedidos.to_csv(
        OUTPUT_FILE,
        index=False,
        encoding="utf-8",
        date_format="%Y-%m-%d %H:%M:%S",
    )

    print("=== DataOps Analytics ===")
    print("Dataset: Pedidos")
    print(f"Registros gerados: {len(pedidos):,}")
    print(
        f"IDs únicos: "
        f"{pedidos['id_pedido'].nunique():,}"
    )
    print(
        f"Clientes presentes: "
        f"{pedidos['id_cliente'].nunique():,}"
    )
    print(
        "Período:",
        pedidos["data_pedido"].min(),
        "a",
        pedidos["data_pedido"].max(),
    )
    print(f"Arquivo: {OUTPUT_FILE}")
    print(
        "Integridade Clientes -> Pedidos validada."
    )
    print("Validações concluídas com sucesso.")


if __name__ == "__main__":
    main()