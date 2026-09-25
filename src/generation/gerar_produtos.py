from pathlib import Path
import random

import numpy as np
import pandas as pd


SEED = 42
TOTAL_PRODUTOS = 500

random.seed(SEED)
np.random.seed(SEED)

BASE_DIR = Path(__file__).resolve().parents[2]
OUTPUT_FILE = BASE_DIR / "data" / "raw" / "produtos.xlsx"


CATALOGO = {
    "Eletrônicos": {
        "subcategorias": ["Fones", "Caixas de Som", "Smartwatches", "Acessórios"],
        "marcas": ["TechOne", "SoundMax", "NextGear", "DigitalPro"],
        "faixa_custo": (40, 800),
    },
    "Informática": {
        "subcategorias": ["Teclados", "Mouses", "Monitores", "Webcams"],
        "marcas": ["ByteTech", "ProWare", "NextGear", "DigitalPro"],
        "faixa_custo": (30, 1500),
    },
    "Casa": {
        "subcategorias": ["Cozinha", "Organização", "Iluminação", "Decoração"],
        "marcas": ["HomePlus", "CasaNova", "PraticLar", "UrbanHome"],
        "faixa_custo": (15, 500),
    },
    "Esporte": {
        "subcategorias": ["Fitness", "Corrida", "Futebol", "Acessórios"],
        "marcas": ["MoveFit", "SportMax", "ActivePro", "Energy"],
        "faixa_custo": (20, 600),
    },
    "Beleza": {
        "subcategorias": ["Cabelo", "Cuidados Pessoais", "Barbear", "Acessórios"],
        "marcas": ["BellaCare", "Vitta", "StylePro", "Essence"],
        "faixa_custo": (10, 350),
    },
}


def gerar_produtos():
    """Gera o cadastro sintético de produtos."""

    registros = []

    categorias = list(CATALOGO.keys())

    for id_produto in range(1, TOTAL_PRODUTOS + 1):
        categoria = random.choice(categorias)
        configuracao = CATALOGO[categoria]

        subcategoria = random.choice(configuracao["subcategorias"])
        marca = random.choice(configuracao["marcas"])

        custo_minimo, custo_maximo = configuracao["faixa_custo"]

        custo = round(
            random.uniform(custo_minimo, custo_maximo),
            2,
        )

        # Margem bruta planejada entre aproximadamente 20% e 55%
        markup = random.uniform(1.20, 1.55)
        preco = round(custo * markup, 2)

        status = random.choices(
            ["Ativo", "Inativo"],
            weights=[95, 5],
            k=1,
        )[0]

        registros.append(
            {
                "id_produto": id_produto,
                "nome_produto": f"{subcategoria} {marca} {id_produto:04d}",
                "categoria": categoria,
                "subcategoria": subcategoria,
                "marca": marca,
                "custo_unitario": custo,
                "preco_unitario": preco,
                "status_produto": status,
            }
        )

    return pd.DataFrame(registros)


def validar_produtos(produtos):
    """Executa validações iniciais no cadastro."""

    assert len(produtos) == TOTAL_PRODUTOS, (
        "Quantidade incorreta de produtos."
    )

    assert produtos["id_produto"].is_unique, (
        "Existem IDs de produtos duplicados."
    )

    assert produtos["id_produto"].notna().all()
    assert produtos["nome_produto"].notna().all()
    assert produtos["categoria"].notna().all()
    assert produtos["subcategoria"].notna().all()
    assert produtos["marca"].notna().all()

    assert (produtos["custo_unitario"] > 0).all(), (
        "Existem custos inválidos."
    )

    assert (
        produtos["preco_unitario"]
        > produtos["custo_unitario"]
    ).all(), "Existem produtos com preço menor ou igual ao custo."

    assert produtos["status_produto"].isin(
        ["Ativo", "Inativo"]
    ).all()


def main():
    produtos = gerar_produtos()

    validar_produtos(produtos)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

    produtos.to_excel(
        OUTPUT_FILE,
        index=False,
        sheet_name="produtos",
        engine="openpyxl",
    )

    print("=== DataOps Analytics ===")
    print("Dataset: Produtos")
    print(f"Registros gerados: {len(produtos):,}")
    print(f"IDs únicos: {produtos['id_produto'].nunique():,}")
    print(f"Categorias: {produtos['categoria'].nunique()}")
    print(f"Marcas: {produtos['marca'].nunique()}")
    print(f"Arquivo: {OUTPUT_FILE}")
    print("Validações concluídas com sucesso.")


if __name__ == "__main__":
    main()