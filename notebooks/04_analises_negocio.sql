-- Databricks notebook source

WITH vendas AS (
    SELECT
        ROUND(SUM(valor_item), 2) AS valor_vendido,
        COUNT(DISTINCT id_pedido) AS pedidos_concluidos,
        SUM(quantidade) AS unidades_vendidas
    FROM workspace.gold.fato_vendas
    WHERE status_pedido = 'Concluido'
),

logistica AS (
    SELECT
        COUNT(*) AS entregas_concluidas,
        SUM(CASE
            WHEN entrega_atrasada = TRUE
            THEN 1 ELSE 0
        END) AS entregas_atrasadas
    FROM workspace.gold.fato_entregas
    WHERE status_entrega = 'Entregue'
),

estoque AS (
    SELECT
        SUM(CASE
            WHEN status_estoque IN ('ZERADO', 'ABAIXO DO MÍNIMO')
            THEN 1 ELSE 0
        END) AS produtos_estoque_critico
    FROM workspace.gold.fato_estoque
    WHERE data_referencia = (
        SELECT MAX(data_referencia)
        FROM workspace.gold.fato_estoque
    )
)

SELECT
    v.valor_vendido,
    v.pedidos_concluidos,
    v.unidades_vendidas,

    ROUND(
        100.0 * l.entregas_atrasadas / l.entregas_concluidas,
        2
    ) AS taxa_atraso_geral_pct,

    e.produtos_estoque_critico

FROM vendas v
CROSS JOIN logistica l
CROSS JOIN estoque e;

-- COMMAND ----------


WITH demanda AS (
    SELECT
        id_produto,
        SUM(quantidade) AS unidades_vendidas,
        ROUND(SUM(valor_item), 2) AS valor_vendido
    FROM workspace.gold.fato_vendas
    WHERE status_pedido = 'Concluido'
    GROUP BY id_produto
),

ranking_demanda AS (
    SELECT
        id_produto,
        unidades_vendidas,
        valor_vendido,
        RANK() OVER (
            ORDER BY unidades_vendidas DESC
        ) AS ranking_unidades
    FROM demanda
),

ultima_data AS (
    SELECT MAX(data_referencia) AS data_referencia
    FROM workspace.gold.fato_estoque
)

SELECT
    r.ranking_unidades,
    p.id_produto,
    p.nome_produto,
    p.categoria,
    r.unidades_vendidas,
    r.valor_vendido,
    e.quantidade_disponivel,
    e.estoque_minimo,
    e.status_estoque

FROM ranking_demanda r

INNER JOIN workspace.gold.dim_produto p
    ON r.id_produto = p.id_produto

INNER JOIN workspace.gold.fato_estoque e
    ON r.id_produto = e.id_produto

INNER JOIN ultima_data u
    ON e.data_referencia = u.data_referencia

WHERE r.ranking_unidades <= 50
  AND e.status_estoque IN ('ZERADO', 'ABAIXO DO MÍNIMO')

ORDER BY r.ranking_unidades;

-- COMMAND ----------


WITH ultima_data AS (
    SELECT MAX(data_referencia) AS data_referencia
    FROM workspace.gold.fato_estoque
)

SELECT
    p.categoria,

    COUNT(*) AS total_produtos,

    SUM(
        CASE
            WHEN e.status_estoque = 'ZERADO'
            THEN 1 ELSE 0
        END
    ) AS produtos_zerados,

    SUM(
        CASE
            WHEN e.status_estoque = 'ABAIXO DO MÍNIMO'
            THEN 1 ELSE 0
        END
    ) AS produtos_abaixo_minimo,

    SUM(
        CASE
            WHEN e.status_estoque IN ('ZERADO', 'ABAIXO DO MÍNIMO')
            THEN 1 ELSE 0
        END
    ) AS produtos_estoque_critico,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN e.status_estoque IN ('ZERADO', 'ABAIXO DO MÍNIMO')
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS taxa_estoque_critico_pct

FROM workspace.gold.fato_estoque e

INNER JOIN workspace.gold.dim_produto p
    ON e.id_produto = p.id_produto

INNER JOIN ultima_data u
    ON e.data_referencia = u.data_referencia

GROUP BY p.categoria
ORDER BY taxa_estoque_critico_pct DESC;

-- COMMAND ----------


SELECT
    transportadora,

    COUNT(*) AS entregas_concluidas,

    SUM(
        CASE
            WHEN entrega_atrasada = TRUE
            THEN 1 ELSE 0
        END
    ) AS entregas_atrasadas,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN entrega_atrasada = TRUE
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS taxa_atraso_pct,

    ROUND(
        AVG(
            CASE
                WHEN entrega_atrasada = TRUE
                THEN dias_atraso
            END
        ),
        2
    ) AS media_dias_atraso

FROM workspace.gold.fato_entregas

WHERE status_entrega = 'Entregue'

GROUP BY transportadora

ORDER BY taxa_atraso_pct DESC;

-- COMMAND ----------


WITH pedidos AS (
    SELECT DISTINCT
        id_pedido,
        canal_venda
    FROM workspace.gold.fato_vendas
),

entregas_canal AS (
    SELECT
        p.canal_venda,
        COUNT(*) AS entregas_concluidas,

        SUM(
            CASE
                WHEN e.entrega_atrasada = TRUE
                THEN 1 ELSE 0
            END
        ) AS entregas_atrasadas

    FROM workspace.gold.fato_entregas e
    INNER JOIN pedidos p
        ON e.id_pedido = p.id_pedido

    WHERE e.status_entrega = 'Entregue'

    GROUP BY p.canal_venda
)

SELECT
    canal_venda,
    entregas_concluidas,
    entregas_atrasadas,

    ROUND(
        100.0 * entregas_atrasadas / entregas_concluidas,
        2
    ) AS taxa_atraso_pct

FROM entregas_canal
ORDER BY taxa_atraso_pct DESC;

-- COMMAND ----------


SELECT
    canal_venda,
    COUNT(DISTINCT id_pedido) AS total_pedidos,

    COUNT(DISTINCT CASE
        WHEN status_pedido = 'Cancelado'
        THEN id_pedido
    END) AS pedidos_cancelados,

    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN status_pedido = 'Cancelado'
            THEN id_pedido
        END)
        / COUNT(DISTINCT id_pedido),
        2
    ) AS taxa_cancelamento_pct

FROM workspace.gold.fato_vendas
GROUP BY canal_venda
ORDER BY taxa_cancelamento_pct DESC;

-- COMMAND ----------


WITH vendas_canal AS (
    SELECT
        canal_venda,
        COUNT(DISTINCT id_pedido) AS pedidos_concluidos,
        SUM(quantidade) AS unidades_vendidas,
        ROUND(SUM(valor_item), 2) AS valor_vendido
    FROM workspace.gold.fato_vendas
    WHERE status_pedido = 'Concluido'
    GROUP BY canal_venda
)

SELECT
    canal_venda,
    pedidos_concluidos,
    unidades_vendidas,
    valor_vendido,
    ROUND(
        100.0 * valor_vendido / SUM(valor_vendido) OVER (),
        2
    ) AS participacao_valor_pct
FROM vendas_canal
ORDER BY valor_vendido DESC;