-- ============================================================
-- Projeto: DataOps Analytics
-- Script: 07_analises_negocio.sql
-- Objetivo:
-- Realizar análises de negócio utilizando SQL.
--
-- Conceitos demonstrados:
-- JOIN
-- GROUP BY
-- agregações
-- CTE
-- subquery
-- window functions
-- ranking
-- comparação temporal
-- ============================================================


-- ============================================================
-- 1. VISÃO GERAL DAS VENDAS
--
-- Consideramos somente pedidos concluídos para os indicadores
-- de vendas realizadas.
-- ============================================================

SELECT
    COUNT(DISTINCT id_pedido) AS pedidos_concluidos,
    SUM(quantidade) AS unidades_vendidas,
    ROUND(SUM(valor_item), 2) AS valor_itens,
    ROUND(
        SUM(valor_item) / COUNT(DISTINCT id_pedido),
        2
    ) AS valor_medio_itens_por_pedido
FROM analytics.fato_vendas
WHERE status_pedido = 'Concluido';


-- ============================================================
-- 2. VENDAS POR CANAL
-- JOIN + GROUP BY + AGREGAÇÕES
-- ============================================================

SELECT
    canal_venda,
    COUNT(DISTINCT id_pedido) AS pedidos,
    SUM(quantidade) AS unidades,
    ROUND(SUM(valor_item), 2) AS valor_vendido
FROM analytics.fato_vendas
WHERE status_pedido = 'Concluido'
GROUP BY canal_venda
ORDER BY valor_vendido DESC;


-- ============================================================
-- 3. VENDAS POR CATEGORIA
-- JOIN entre fato e dimensão
-- ============================================================

SELECT
    dp.categoria,
    COUNT(DISTINCT fv.id_pedido) AS pedidos,
    SUM(fv.quantidade) AS unidades,
    ROUND(SUM(fv.valor_item), 2) AS valor_vendido
FROM analytics.fato_vendas fv
INNER JOIN analytics.dim_produto dp
    ON fv.id_produto = dp.id_produto
WHERE fv.status_pedido = 'Concluido'
GROUP BY dp.categoria
ORDER BY valor_vendido DESC;


-- ============================================================
-- 4. EVOLUÇÃO MENSAL
-- CTE
-- ============================================================

WITH vendas_mensais AS (
    SELECT
        DATE_TRUNC('month', data)::date AS mes,
        COUNT(DISTINCT id_pedido) AS pedidos,
        SUM(quantidade) AS unidades,
        SUM(valor_item) AS valor_vendido
    FROM analytics.fato_vendas
    WHERE status_pedido = 'Concluido'
    GROUP BY DATE_TRUNC('month', data)
)

SELECT
    mes,
    pedidos,
    unidades,
    ROUND(valor_vendido, 2) AS valor_vendido
FROM vendas_mensais
ORDER BY mes;


-- ============================================================
-- 5. CRESCIMENTO MENSAL DAS VENDAS
--
-- CTE + window function LAG
-- ============================================================

WITH vendas_mensais AS (
    SELECT
        DATE_TRUNC('month', data)::date AS mes,
        SUM(valor_item) AS valor_vendido
    FROM analytics.fato_vendas
    WHERE status_pedido = 'Concluido'
    GROUP BY DATE_TRUNC('month', data)
),

comparacao AS (
    SELECT
        mes,
        valor_vendido,
        LAG(valor_vendido) OVER (
            ORDER BY mes
        ) AS valor_mes_anterior
    FROM vendas_mensais
)

SELECT
    mes,
    ROUND(valor_vendido, 2) AS valor_vendido,
    ROUND(valor_mes_anterior, 2) AS valor_mes_anterior,

    ROUND(
        (
            (valor_vendido - valor_mes_anterior)
            / NULLIF(valor_mes_anterior, 0)
        ) * 100,
        2
    ) AS crescimento_percentual

FROM comparacao
ORDER BY mes;


-- ============================================================
-- 6. TOP 10 PRODUTOS POR VALOR VENDIDO
--
-- JOIN + GROUP BY
-- ============================================================

SELECT
    dp.id_produto,
    dp.nome_produto,
    dp.categoria,
    dp.marca,
    SUM(fv.quantidade) AS unidades_vendidas,
    ROUND(SUM(fv.valor_item), 2) AS valor_vendido
FROM analytics.fato_vendas fv
INNER JOIN analytics.dim_produto dp
    ON fv.id_produto = dp.id_produto
WHERE fv.status_pedido = 'Concluido'
GROUP BY
    dp.id_produto,
    dp.nome_produto,
    dp.categoria,
    dp.marca
ORDER BY valor_vendido DESC
LIMIT 10;


-- ============================================================
-- 7. RANKING DOS PRODUTOS DENTRO DE CADA CATEGORIA
--
-- CTE + window function RANK
-- ============================================================

WITH vendas_produto AS (
    SELECT
        dp.id_produto,
        dp.nome_produto,
        dp.categoria,
        SUM(fv.valor_item) AS valor_vendido
    FROM analytics.fato_vendas fv
    INNER JOIN analytics.dim_produto dp
        ON fv.id_produto = dp.id_produto
    WHERE fv.status_pedido = 'Concluido'
    GROUP BY
        dp.id_produto,
        dp.nome_produto,
        dp.categoria
),

ranking AS (
    SELECT
        id_produto,
        nome_produto,
        categoria,
        valor_vendido,

        RANK() OVER (
            PARTITION BY categoria
            ORDER BY valor_vendido DESC
        ) AS posicao_categoria

    FROM vendas_produto
)

SELECT
    id_produto,
    nome_produto,
    categoria,
    ROUND(valor_vendido, 2) AS valor_vendido,
    posicao_categoria
FROM ranking
WHERE posicao_categoria <= 3
ORDER BY
    categoria,
    posicao_categoria;


-- ============================================================
-- 8. CLIENTES COM MAIOR VALOR DE COMPRAS
-- ============================================================

SELECT
    dc.id_cliente,
    dc.nome_cliente,
    dc.segmento_cliente,
    COUNT(DISTINCT fv.id_pedido) AS pedidos,
    ROUND(SUM(fv.valor_item), 2) AS valor_compras
FROM analytics.fato_vendas fv
INNER JOIN analytics.dim_cliente dc
    ON fv.id_cliente = dc.id_cliente
WHERE fv.status_pedido = 'Concluido'
GROUP BY
    dc.id_cliente,
    dc.nome_cliente,
    dc.segmento_cliente
ORDER BY valor_compras DESC
LIMIT 10;


-- ============================================================
-- 9. CLIENTES ACIMA DA MÉDIA
--
-- CTE + subquery
-- ============================================================

WITH vendas_cliente AS (
    SELECT
        id_cliente,
        SUM(valor_item) AS valor_compras
    FROM analytics.fato_vendas
    WHERE status_pedido = 'Concluido'
    GROUP BY id_cliente
)

SELECT
    vc.id_cliente,
    dc.nome_cliente,
    dc.segmento_cliente,
    ROUND(vc.valor_compras, 2) AS valor_compras
FROM vendas_cliente vc
INNER JOIN analytics.dim_cliente dc
    ON vc.id_cliente = dc.id_cliente
WHERE vc.valor_compras > (
    SELECT AVG(valor_compras)
    FROM vendas_cliente
)
ORDER BY vc.valor_compras DESC;


-- ============================================================
-- 10. DESEMPENHO DAS TRANSPORTADORAS
--
-- IMPORTANTE:
-- taxa de atraso usa somente entregas já concluídas.
-- ============================================================

SELECT
    transportadora,

    COUNT(*) AS total_registros,

    COUNT(*) FILTER (
        WHERE status_entrega = 'Entregue'
    ) AS entregas_concluidas,

    COUNT(*) FILTER (
        WHERE entrega_atrasada = TRUE
    ) AS entregas_atrasadas,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE entrega_atrasada = TRUE
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE status_entrega = 'Entregue'
            ),
            0
        ),
        2
    ) AS taxa_atraso_percentual,

    ROUND(
        AVG(dias_atraso) FILTER (
            WHERE entrega_atrasada = TRUE
        ),
        2
    ) AS media_dias_atraso,

    ROUND(
        AVG(custo_logistico),
        2
    ) AS custo_logistico_medio

FROM analytics.fato_entregas
GROUP BY transportadora
ORDER BY taxa_atraso_percentual DESC;


-- ============================================================
-- 11. ATRASOS POR CANAL DE VENDA
--
-- fato_entregas é ligada aos pedidos da camada RAW pelo
-- id_pedido para recuperar o canal.
-- ============================================================

SELECT
    p.canal_venda,

    COUNT(*) FILTER (
        WHERE fe.status_entrega = 'Entregue'
    ) AS entregas_concluidas,

    COUNT(*) FILTER (
        WHERE fe.entrega_atrasada = TRUE
    ) AS entregas_atrasadas,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE fe.entrega_atrasada = TRUE
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE fe.status_entrega = 'Entregue'
            ),
            0
        ),
        2
    ) AS taxa_atraso_percentual

FROM analytics.fato_entregas fe
INNER JOIN raw.pedidos p
    ON fe.id_pedido = p.id_pedido
GROUP BY p.canal_venda
ORDER BY taxa_atraso_percentual DESC;


-- ============================================================
-- 12. TAXA DE CANCELAMENTO POR CANAL
--
-- Aqui usamos raw.pedidos porque a granularidade correta
-- para cancelamento é uma linha por pedido.
-- ============================================================

SELECT
    canal_venda,
    COUNT(*) AS total_pedidos,

    COUNT(*) FILTER (
        WHERE status_pedido = 'Cancelado'
    ) AS pedidos_cancelados,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE status_pedido = 'Cancelado'
        )
        / COUNT(*),
        2
    ) AS taxa_cancelamento_percentual

FROM raw.pedidos
GROUP BY canal_venda
ORDER BY taxa_cancelamento_percentual DESC;


-- ============================================================
-- 13. SITUAÇÃO DO ESTOQUE POR CATEGORIA
--
-- Considera somente o snapshot mais recente do estoque.
-- ============================================================

WITH ultimo_snapshot AS (
    SELECT MAX(data_referencia) AS data_referencia
    FROM analytics.fato_estoque
)

SELECT
    dp.categoria,

    COUNT(*) AS produtos,

    SUM(fe.quantidade_disponivel)
        AS quantidade_disponivel,

    COUNT(*) FILTER (
        WHERE fe.abaixo_estoque_minimo = TRUE
    ) AS produtos_abaixo_minimo,

    COUNT(*) FILTER (
        WHERE fe.estoque_zerado = TRUE
    ) AS produtos_zerados

FROM analytics.fato_estoque fe

INNER JOIN analytics.dim_produto dp
    ON fe.id_produto = dp.id_produto

WHERE fe.data_referencia = (
    SELECT data_referencia
    FROM ultimo_snapshot
)

GROUP BY dp.categoria
ORDER BY produtos_abaixo_minimo DESC;


-- ============================================================
-- 14. PRODUTOS COM ESTOQUE CRÍTICO NO ÚLTIMO SNAPSHOT
--
-- Subquery + JOIN
-- ============================================================

SELECT
    dp.id_produto,
    dp.nome_produto,
    dp.categoria,
    fe.quantidade_disponivel,
    fe.estoque_minimo,
    fe.quantidade_reservada
FROM analytics.fato_estoque fe
INNER JOIN analytics.dim_produto dp
    ON fe.id_produto = dp.id_produto
WHERE fe.data_referencia = (
    SELECT MAX(data_referencia)
    FROM analytics.fato_estoque
)
AND fe.abaixo_estoque_minimo = TRUE
ORDER BY
    fe.quantidade_disponivel ASC,
    dp.nome_produto;


-- ============================================================
-- 15. PARTICIPAÇÃO DOS CANAIS NAS VENDAS
--
-- CTE + window function SUM OVER
-- ============================================================

WITH vendas_canal AS (
    SELECT
        canal_venda,
        SUM(valor_item) AS valor_vendido
    FROM analytics.fato_vendas
    WHERE status_pedido = 'Concluido'
    GROUP BY canal_venda
)

SELECT
    canal_venda,
    ROUND(valor_vendido, 2) AS valor_vendido,

    ROUND(
        100.0 * valor_vendido
        / SUM(valor_vendido) OVER (),
        2
    ) AS participacao_percentual

FROM vendas_canal
ORDER BY valor_vendido DESC;