from pathlib import Path
import random

import numpy as np
import pandas as pd


SEED = 42

random.seed(SEED)
np.random.seed(SEED)

BASE_DIR = Path(__file__).resolve().parents[2]

PEDIDOS_FILE = BASE_DIR / "data" / "raw" / "pedidos.csv"
OUTPUT_FILE = BASE_DIR / "data" / "raw" / "pagamentos.csv"


def carregar_pedidos():
    """Carrega os pedidos utilizados como referência."""

    pedidos = pd.read_csv(
        PEDIDOS_FILE,
        parse_dates=["data_pedido"],
    )

    if pedidos.empty:
        raise ValueError("O dataset de pedidos está vazio.")

    if not pedidos["id_pedido"].is_unique:
        raise ValueError(
            "Existem IDs duplicados no dataset de pedidos."
        )

    if pedidos["valor_total"].isna().any():
        raise ValueError(
            "Existem pedidos sem valor_total calculado."
        )

    return pedidos


def gerar_pagamentos(pedidos):
    """Gera os pagamentos associados aos pedidos."""

    registros = []

    for id_pagamento, pedido in enumerate(
        pedidos.itertuples(index=False),
        start=1,
    ):
        forma_pagamento = np.random.choice(
            [
                "Pix",
                "Cartao de credito",
                "Cartao de debito",
                "Boleto",
            ],
            p=[0.35, 0.40, 0.15, 0.10],
        )

        # Parcelamento depende da forma de pagamento.
        if forma_pagamento == "Cartao de credito":
            numero_parcelas = int(
                np.random.choice(
                    [1, 2, 3, 4, 5, 6, 8, 10, 12],
                    p=[
                        0.25,
                        0.15,
                        0.15,
                        0.10,
                        0.08,
                        0.08,
                        0.07,
                        0.07,
                        0.05,
                    ],
                )
            )
        else:
            numero_parcelas = 1

        # Pedidos cancelados terão pagamento cancelado.
        if pedido.status_pedido == "Cancelado":
            status_pagamento = "Cancelado"
            valor_pagamento = 0.0

        # Pedidos ainda em processamento podem ter
        # pagamento aprovado ou pendente.
        elif pedido.status_pedido == "Em processamento":
            status_pagamento = np.random.choice(
                ["Aprovado", "Pendente"],
                p=[0.70, 0.30],
            )

            if status_pagamento == "Aprovado":
                valor_pagamento = round(
                    float(pedido.valor_total),
                    2,
                )
            else:
                valor_pagamento = 0.0

        # Pedidos concluídos precisam possuir
        # pagamento aprovado.
        else:
            status_pagamento = "Aprovado"
            valor_pagamento = round(
                float(pedido.valor_total),
                2,
            )

        # Data do pagamento.
        if status_pagamento == "Aprovado":
            minutos_ate_pagamento = int(
                np.random.randint(0, 121)
            )

            data_pagamento = (
                pedido.data_pedido
                + pd.Timedelta(
                    minutes=minutos_ate_pagamento
                )
            )

        else:
            data_pagamento = pd.NaT

        registros.append(
            {
                "id_pagamento": id_pagamento,
                "id_pedido": int(pedido.id_pedido),
                "forma_pagamento": forma_pagamento,
                "numero_parcelas": numero_parcelas,
                "valor_pagamento": valor_pagamento,
                "status_pagamento": status_pagamento,
                "data_pagamento": data_pagamento,
            }
        )

    return pd.DataFrame(registros)


def validar_pagamentos(pagamentos, pedidos):
    """Executa as validações do dataset de pagamentos."""

    assert len(pagamentos) == len(pedidos), (
        "Quantidade de pagamentos diferente da "
        "quantidade de pedidos."
    )

    assert pagamentos["id_pagamento"].is_unique, (
        "Existem IDs de pagamentos duplicados."
    )

    assert pagamentos["id_pagamento"].notna().all()

    assert pagamentos["id_pedido"].notna().all()

    assert pagamentos["id_pedido"].isin(
        pedidos["id_pedido"]
    ).all(), (
        "Existem pagamentos associados "
        "a pedidos inexistentes."
    )

    # Nesta versão do modelo existe exatamente
    # um registro de pagamento por pedido.
    assert pagamentos["id_pedido"].is_unique, (
        "Existem múltiplos pagamentos para "
        "o mesmo pedido."
    )

    assert (
        pagamentos["numero_parcelas"] >= 1
    ).all(), (
        "Existem quantidades de parcelas inválidas."
    )

    # Somente cartão de crédito pode ter
    # mais de uma parcela.
    parcelas_invalidas = pagamentos[
        (pagamentos["forma_pagamento"]
         != "Cartao de credito")
        & (pagamentos["numero_parcelas"] != 1)
    ]

    assert parcelas_invalidas.empty, (
        "Existem parcelamentos inválidos."
    )

    assert (
        pagamentos["valor_pagamento"] >= 0
    ).all(), (
        "Existem valores de pagamento negativos."
    )

    assert pagamentos["status_pagamento"].isin(
        [
            "Aprovado",
            "Pendente",
            "Cancelado",
        ]
    ).all()

    # Pagamentos aprovados devem possuir data.
    aprovados_sem_data = pagamentos[
        (pagamentos["status_pagamento"] == "Aprovado")
        & (pagamentos["data_pagamento"].isna())
    ]

    assert aprovados_sem_data.empty, (
        "Existem pagamentos aprovados sem data."
    )

    # Pendentes e cancelados não devem possuir
    # valor efetivamente pago.
    nao_aprovados_com_valor = pagamentos[
        (pagamentos["status_pagamento"] != "Aprovado")
        & (pagamentos["valor_pagamento"] != 0)
    ]

    assert nao_aprovados_com_valor.empty, (
        "Existem pagamentos não aprovados "
        "com valor pago."
    )

    # Pedidos concluídos devem estar aprovados.
    validacao = pagamentos.merge(
        pedidos[
            [
                "id_pedido",
                "status_pedido",
                "valor_total",
            ]
        ],
        on="id_pedido",
        how="left",
        validate="one_to_one",
    )

    concluidos_invalidos = validacao[
        (validacao["status_pedido"] == "Concluido")
        & (validacao["status_pagamento"] != "Aprovado")
    ]

    assert concluidos_invalidos.empty, (
        "Existem pedidos concluídos "
        "sem pagamento aprovado."
    )

    # Pedidos cancelados devem possuir
    # pagamento cancelado.
    cancelados_invalidos = validacao[
        (validacao["status_pedido"] == "Cancelado")
        & (validacao["status_pagamento"] != "Cancelado")
    ]

    assert cancelados_invalidos.empty, (
        "Existem pedidos cancelados com "
        "status de pagamento incompatível."
    )

    # Reconciliação:
    # pagamentos aprovados devem ser iguais
    # ao valor total do pedido.
    aprovados = validacao[
        validacao["status_pagamento"] == "Aprovado"
    ].copy()

    diferenca = (
        aprovados["valor_pagamento"]
        - aprovados["valor_total"]
    ).abs()

    assert (diferenca <= 0.01).all(), (
        "Falha na reconciliação "
        "Pedidos x Pagamentos."
    )


def main():
    pedidos = carregar_pedidos()

    pagamentos = gerar_pagamentos(pedidos)

    validar_pagamentos(
        pagamentos,
        pedidos,
    )

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    pagamentos.to_csv(
        OUTPUT_FILE,
        index=False,
        encoding="utf-8",
        date_format="%Y-%m-%d %H:%M:%S",
    )

    print("=== DataOps Analytics ===")
    print("Dataset: Pagamentos")

    print(
        f"Registros gerados: "
        f"{len(pagamentos):,}"
    )

    print(
        f"IDs únicos: "
        f"{pagamentos['id_pagamento'].nunique():,}"
    )

    print(
        f"Pedidos representados: "
        f"{pagamentos['id_pedido'].nunique():,}"
    )

    print(
        "Pagamentos aprovados:",
        (
            pagamentos["status_pagamento"]
            == "Aprovado"
        ).sum(),
    )

    print(
        "Pagamentos pendentes:",
        (
            pagamentos["status_pagamento"]
            == "Pendente"
        ).sum(),
    )

    print(
        "Pagamentos cancelados:",
        (
            pagamentos["status_pagamento"]
            == "Cancelado"
        ).sum(),
    )

    print(f"Arquivo: {OUTPUT_FILE}")

    print(
        "Integridade Pedidos -> Pagamentos validada."
    )

    print(
        "Reconciliação Pedidos x Pagamentos validada."
    )

    print(
        "Validações concluídas com sucesso."
    )


if __name__ == "__main__":
    main()