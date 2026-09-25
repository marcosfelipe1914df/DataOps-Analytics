from pathlib import Path

import numpy as np
import pandas as pd


BASE_DIR = Path(__file__).resolve().parents[2]

PEDIDOS_FILE = BASE_DIR / "data" / "raw" / "pedidos.csv"
ITENS_FILE = BASE_DIR / "data" / "raw" / "itens_pedido.csv"


def carregar_dados():
    """Carrega pedidos e itens utilizados no cálculo."""

    pedidos = pd.read_csv(PEDIDOS_FILE)
    itens = pd.read_csv(ITENS_FILE)

    if pedidos.empty:
        raise ValueError("O dataset de pedidos está vazio.")

    if itens.empty:
        raise ValueError("O dataset de itens está vazio.")

    return pedidos, itens


def calcular_totais(pedidos, itens):
    """Calcula o valor total dos pedidos a partir dos itens."""

    # Soma o valor dos itens de cada pedido.
    subtotal_por_pedido = (
        itens.groupby(
            "id_pedido",
            as_index=False,
        )["valor_item"]
        .sum()
        .rename(
            columns={
                "valor_item": "subtotal_itens"
            }
        )
    )

    subtotal_por_pedido["subtotal_itens"] = (
        subtotal_por_pedido["subtotal_itens"]
        .round(2)
    )

    # Remove valor_total caso o script esteja sendo
    # executado novamente.
    pedidos = pedidos.drop(
        columns=["valor_total"],
        errors="ignore",
    )

    # Adiciona o subtotal calculado aos pedidos.
    pedidos = pedidos.merge(
        subtotal_por_pedido,
        on="id_pedido",
        how="left",
        validate="one_to_one",
    )

    # Regra de negócio:
    # o desconto do pedido não pode ultrapassar
    # 50% do subtotal dos itens.
    desconto_maximo = (
        pedidos["subtotal_itens"] * 0.50
    ).round(2)

    pedidos["desconto_pedido"] = np.minimum(
        pedidos["desconto_pedido"],
        desconto_maximo,
    ).round(2)

    desconto_aplicado = pedidos["desconto_pedido"]

    # Calcula o valor final do pedido.
    pedidos["valor_total"] = (
        pedidos["subtotal_itens"]
        - desconto_aplicado
        + pedidos["valor_frete"]
    ).round(2)

    return pedidos


def validar_totais(pedidos):
    """Valida os valores calculados e as regras de negócio."""

    assert pedidos["subtotal_itens"].notna().all(), (
        "Existem pedidos sem subtotal."
    )

    assert pedidos["valor_total"].notna().all(), (
        "Existem pedidos sem valor total."
    )

    assert pedidos["desconto_pedido"].notna().all(), (
        "Existem pedidos sem desconto definido."
    )

    assert (pedidos["subtotal_itens"] > 0).all(), (
        "Existem subtotais inválidos."
    )

    assert (pedidos["valor_frete"] >= 0).all(), (
        "Existem valores de frete negativos."
    )

    assert (pedidos["desconto_pedido"] >= 0).all(), (
        "Existem descontos negativos."
    )

    # Confirma que nenhum desconto ultrapassa
    # 50% do subtotal.
    desconto_maximo = (
        pedidos["subtotal_itens"] * 0.50
    ).round(2)

    assert (
        pedidos["desconto_pedido"]
        <= desconto_maximo
    ).all(), (
        "Existem descontos superiores a 50% do subtotal."
    )

    # Nenhum pedido poderá possuir total
    # igual ou inferior a zero.
    assert (pedidos["valor_total"] > 0).all(), (
        "Existem pedidos com valor total menor ou igual a zero."
    )

    # Reconciliação financeira.
    desconto_aplicado = pedidos["desconto_pedido"]

    valor_esperado = (
        pedidos["subtotal_itens"]
        - desconto_aplicado
        + pedidos["valor_frete"]
    ).round(2)

    diferenca = (
        pedidos["valor_total"]
        - valor_esperado
    ).abs()

    assert (diferenca <= 0.01).all(), (
        "Falha na reconciliação dos valores."
    )


def main():
    pedidos, itens = carregar_dados()

    pedidos = calcular_totais(
        pedidos,
        itens,
    )

    validar_totais(pedidos)

    # subtotal_itens é uma coluna auxiliar utilizada
    # somente durante cálculo e validação.
    pedidos_saida = pedidos.drop(
        columns=["subtotal_itens"]
    )

    pedidos_saida.to_csv(
        PEDIDOS_FILE,
        index=False,
        encoding="utf-8",
    )

    print("=== DataOps Analytics ===")
    print("Reconciliação: Pedidos x Itens")

    print(
        f"Pedidos processados: "
        f"{len(pedidos_saida):,}"
    )

    print(
        "Valores totais preenchidos:",
        pedidos_saida["valor_total"]
        .notna()
        .sum(),
    )

    print(
        "Pedidos com valor total <= 0:",
        (
            pedidos_saida["valor_total"] <= 0
        ).sum(),
    )

    print(
        "Menor valor total:",
        round(
            pedidos_saida["valor_total"].min(),
            2,
        ),
    )

    print(
        "Maior valor total:",
        round(
            pedidos_saida["valor_total"].max(),
            2,
        ),
    )

    print(
        "Maior desconto aplicado:",
        round(
            pedidos_saida["desconto_pedido"].max(),
            2,
        ),
    )

    print(
        "Reconciliação concluída com sucesso."
    )

    print(
        f"Arquivo atualizado: {PEDIDOS_FILE}"
    )


if __name__ == "__main__":
    main()