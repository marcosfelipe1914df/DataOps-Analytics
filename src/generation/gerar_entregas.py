from pathlib import Path
import random

import numpy as np
import pandas as pd


SEED = 42

random.seed(SEED)
np.random.seed(SEED)

BASE_DIR = Path(__file__).resolve().parents[2]

PEDIDOS_FILE = BASE_DIR / "data" / "raw" / "pedidos.csv"
OUTPUT_FILE = BASE_DIR / "data" / "raw" / "entregas.csv"


def carregar_pedidos():
    """Carrega os pedidos utilizados como referência."""

    pedidos = pd.read_csv(
        PEDIDOS_FILE,
        parse_dates=["data_pedido"],
    )

    if pedidos.empty:
        raise ValueError(
            "O dataset de pedidos está vazio."
        )

    if not pedidos["id_pedido"].is_unique:
        raise ValueError(
            "Existem IDs duplicados em pedidos."
        )

    return pedidos


def gerar_entregas(pedidos):
    """Gera as entregas dos pedidos não cancelados."""

    # Pedidos cancelados não geram entrega.
    pedidos_entregaveis = pedidos[
        pedidos["status_pedido"] != "Cancelado"
    ].copy()

    registros = []

    transportadoras = [
        "LogExpress",
        "RapidGo",
        "TransBrasil",
        "EntregaMax",
    ]

    for id_entrega, pedido in enumerate(
        pedidos_entregaveis.itertuples(index=False),
        start=1,
    ):
        transportadora = np.random.choice(
            transportadoras,
            p=[0.35, 0.30, 0.20, 0.15],
        )

        # Expedição entre 0 e 2 dias após o pedido.
        horas_ate_envio = int(
            np.random.randint(4, 49)
        )

        data_envio = (
            pedido.data_pedido
            + pd.Timedelta(
                hours=horas_ate_envio
            )
        )

        # Prazo prometido entre 2 e 8 dias
        # após a expedição.
        prazo_dias = int(
            np.random.randint(2, 9)
        )

        data_prevista = (
            data_envio
            + pd.Timedelta(days=prazo_dias)
        ).normalize()

        # Pedidos em processamento podem ainda
        # estar em trânsito.
        if pedido.status_pedido == "Em processamento":
            status_entrega = np.random.choice(
                ["Entregue", "Em transito"],
                p=[0.35, 0.65],
            )
        else:
            status_entrega = "Entregue"

        if status_entrega == "Entregue":

            # Variação em relação à data prevista:
            # negativo = antecipada
            # zero = no prazo
            # positivo = atrasada
            variacao_dias = int(
                np.random.choice(
                    [-2, -1, 0, 1, 2, 3, 4, 5],
                    p=[
                        0.08,
                        0.12,
                        0.55,
                        0.08,
                        0.06,
                        0.05,
                        0.035,
                        0.025,
                    ],
                )
            )

            data_entrega = (
                data_prevista
                + pd.Timedelta(
                    days=variacao_dias
                )
                + pd.Timedelta(
                    hours=int(
                        np.random.randint(8, 20)
                    )
                )
            )

            # Atrasos possuem maior chance
            # de exigir novas tentativas.
            if variacao_dias > 0:
                tentativas_entrega = int(
                    np.random.choice(
                        [1, 2, 3],
                        p=[0.70, 0.25, 0.05],
                    )
                )
            else:
                tentativas_entrega = int(
                    np.random.choice(
                        [1, 2],
                        p=[0.95, 0.05],
                    )
                )

        else:
            data_entrega = pd.NaT
            tentativas_entrega = 0

        # Custo logístico sintético.
        custo_logistico = round(
            float(
                np.random.uniform(
                    8.00,
                    65.00,
                )
            ),
            2,
        )

        registros.append(
            {
                "id_entrega": id_entrega,
                "id_pedido": int(
                    pedido.id_pedido
                ),
                "transportadora": transportadora,
                "data_envio": data_envio,
                "data_prevista": data_prevista,
                "data_entrega": data_entrega,
                "status_entrega": status_entrega,
                "tentativas_entrega": tentativas_entrega,
                "custo_logistico": custo_logistico,
            }
        )

    return pd.DataFrame(registros)


def validar_entregas(entregas, pedidos):
    """Executa as validações do dataset de entregas."""

    pedidos_cancelados = pedidos[
        pedidos["status_pedido"] == "Cancelado"
    ]

    pedidos_entregaveis = pedidos[
        pedidos["status_pedido"] != "Cancelado"
    ]

    assert len(entregas) == len(
        pedidos_entregaveis
    ), (
        "Quantidade de entregas diferente da "
        "quantidade de pedidos entregáveis."
    )

    assert entregas["id_entrega"].is_unique, (
        "Existem IDs de entrega duplicados."
    )

    assert entregas["id_pedido"].is_unique, (
        "Existem múltiplas entregas para "
        "o mesmo pedido."
    )

    assert entregas["id_pedido"].isin(
        pedidos["id_pedido"]
    ).all(), (
        "Existem entregas associadas "
        "a pedidos inexistentes."
    )

    # Nenhum pedido cancelado pode possuir entrega.
    cancelados_com_entrega = entregas[
        entregas["id_pedido"].isin(
            pedidos_cancelados["id_pedido"]
        )
    ]

    assert cancelados_com_entrega.empty, (
        "Existem pedidos cancelados com entrega."
    )

    assert entregas[
        [
            "id_entrega",
            "id_pedido",
            "transportadora",
            "data_envio",
            "data_prevista",
            "status_entrega",
            "tentativas_entrega",
            "custo_logistico",
        ]
    ].notna().all().all(), (
        "Existem nulos em campos obrigatórios."
    )

    assert (
        entregas["custo_logistico"] > 0
    ).all(), (
        "Existem custos logísticos inválidos."
    )

    assert (
        entregas["tentativas_entrega"] >= 0
    ).all(), (
        "Existem tentativas de entrega inválidas."
    )

    assert entregas["status_entrega"].isin(
        [
            "Entregue",
            "Em transito",
        ]
    ).all()

    # Entregas concluídas devem possuir
    # data de entrega.
    entregues_sem_data = entregas[
        (entregas["status_entrega"] == "Entregue")
        & (entregas["data_entrega"].isna())
    ]

    assert entregues_sem_data.empty, (
        "Existem entregas concluídas sem data."
    )

    # Entregas em trânsito não devem possuir
    # data de entrega.
    transito_com_data = entregas[
        (entregas["status_entrega"] == "Em transito")
        & (entregas["data_entrega"].notna())
    ]

    assert transito_com_data.empty, (
        "Existem entregas em trânsito "
        "com data de entrega."
    )

    # Data de envio não pode ser anterior
    # à data do pedido.
    validacao_datas = entregas.merge(
        pedidos[
            [
                "id_pedido",
                "data_pedido",
            ]
        ],
        on="id_pedido",
        how="left",
        validate="one_to_one",
    )

    validacao_datas["data_pedido"] = pd.to_datetime(
        validacao_datas["data_pedido"]
    )

    validacao_datas["data_envio"] = pd.to_datetime(
        validacao_datas["data_envio"]
    )

    assert (
        validacao_datas["data_envio"]
        >= validacao_datas["data_pedido"]
    ).all(), (
        "Existem envios anteriores ao pedido."
    )


def main():
    pedidos = carregar_pedidos()

    entregas = gerar_entregas(pedidos)

    validar_entregas(
        entregas,
        pedidos,
    )

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    entregas.to_csv(
        OUTPUT_FILE,
        index=False,
        encoding="utf-8",
        date_format="%Y-%m-%d %H:%M:%S",
    )

    entregues = entregas[
        entregas["status_entrega"] == "Entregue"
    ].copy()

    entregues["data_entrega"] = pd.to_datetime(
        entregues["data_entrega"]
    )

    entregues["data_prevista"] = pd.to_datetime(
        entregues["data_prevista"]
    )

    atrasadas = (
        entregues["data_entrega"].dt.normalize()
        > entregues["data_prevista"]
    ).sum()

    no_prazo_ou_antecipadas = (
        entregues["data_entrega"].dt.normalize()
        <= entregues["data_prevista"]
    ).sum()

    print("=== DataOps Analytics ===")
    print("Dataset: Entregas")

    print(
        f"Registros gerados: "
        f"{len(entregas):,}"
    )

    print(
        f"IDs únicos: "
        f"{entregas['id_entrega'].nunique():,}"
    )

    print(
        f"Pedidos representados: "
        f"{entregas['id_pedido'].nunique():,}"
    )

    print(
        "Entregas concluídas:",
        len(entregues),
    )

    print(
        "Entregas em trânsito:",
        (
            entregas["status_entrega"]
            == "Em transito"
        ).sum(),
    )

    print(
        "Entregas atrasadas:",
        atrasadas,
    )

    print(
        "No prazo ou antecipadas:",
        no_prazo_ou_antecipadas,
    )

    print(f"Arquivo: {OUTPUT_FILE}")

    print(
        "Integridade Pedidos -> Entregas validada."
    )

    print(
        "Validações concluídas com sucesso."
    )


if __name__ == "__main__":
    main()