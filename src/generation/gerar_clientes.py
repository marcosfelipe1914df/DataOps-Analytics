from pathlib import Path
import random

import numpy as np
import pandas as pd


# Configurações
SEED = 42
TOTAL_CLIENTES = 5_000

random.seed(SEED)
np.random.seed(SEED)

# Caminho raiz do projeto
BASE_DIR = Path(__file__).resolve().parents[2]
OUTPUT_FILE = BASE_DIR / "data" / "raw" / "clientes.csv"


def gerar_clientes():
    """Gera o dataset sintético de clientes da DataOps Commerce."""

    ids = np.arange(1, TOTAL_CLIENTES + 1)

    datas_cadastro = pd.to_datetime(
        np.random.choice(
            pd.date_range("2024-01-01", "2025-12-31", freq="D"),
            size=TOTAL_CLIENTES,
        )
    )

    segmentos = np.random.choice(
        ["Novo", "Recorrente", "VIP"],
        size=TOTAL_CLIENTES,
        p=[0.55, 0.35, 0.10],
    )

    status = np.random.choice(
        ["Ativo", "Inativo"],
        size=TOTAL_CLIENTES,
        p=[0.92, 0.08],
    )

    clientes = pd.DataFrame(
        {
            "id_cliente": ids,
            "nome_cliente": [
                f"Cliente {id_cliente:05d}"
                for id_cliente in ids
            ],
            "data_cadastro": datas_cadastro,
            "cep": pd.NA,
            "cidade": pd.NA,
            "uf": pd.NA,
            "segmento_cliente": segmentos,
            "status_cliente": status,
        }
    )

    clientes = clientes.sort_values("id_cliente").reset_index(drop=True)

    return clientes


def validar_clientes(clientes):
    """Executa validações iniciais no dataset."""

    assert len(clientes) == TOTAL_CLIENTES, "Quantidade incorreta de clientes."
    assert clientes["id_cliente"].is_unique, "Existem IDs duplicados."
    assert clientes["id_cliente"].notna().all(), "Existem IDs nulos."
    assert clientes["nome_cliente"].notna().all(), "Existem nomes nulos."
    assert clientes["data_cadastro"].notna().all(), "Existem datas nulas."

    data_minima = clientes["data_cadastro"].min()
    data_maxima = clientes["data_cadastro"].max()

    assert data_minima >= pd.Timestamp("2024-01-01")
    assert data_maxima <= pd.Timestamp("2025-12-31")


def main():
    clientes = gerar_clientes()

    validar_clientes(clientes)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

    clientes.to_csv(
        OUTPUT_FILE,
        index=False,
        encoding="utf-8",
        date_format="%Y-%m-%d",
    )

    print("=== DataOps Analytics ===")
    print("Dataset: Clientes")
    print(f"Registros gerados: {len(clientes):,}")
    print(f"IDs únicos: {clientes['id_cliente'].nunique():,}")
    print(
        "Período de cadastro:",
        clientes["data_cadastro"].min().date(),
        "a",
        clientes["data_cadastro"].max().date(),
    )
    print(f"Arquivo: {OUTPUT_FILE}")
    print("Validações concluídas com sucesso.")


if __name__ == "__main__":
    main()