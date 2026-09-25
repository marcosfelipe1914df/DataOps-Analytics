-- ============================================================
-- Projeto: DataOps Analytics
-- Script: 08_insights_portfolio.sql
-- Objetivo:
-- Consolidar os principais insights analíticos do projeto.
--
-- Observação:
-- Todos os dados utilizados neste projeto são sintéticos.
-- Os resultados representam um cenário simulado.
-- ============================================================


-- ============================================================
-- INSIGHT 1
-- DESEMPENHO DOS CANAIS DE VENDA
--
-- Objetivo:
-- Comparar participação no valor vendido, cancelamentos
-- e atrasos logísticos por canal.
-- ============================================================

WITH vendas_canal AS (
    SELECT
        canal_venda,
        SUM(valor_item) AS valor_vendido
    FROM analytics.fato_vendas
    WHERE status_pedido = 'Concluido'
    GROUP BY canal_venda
),

participacao AS (
    SELECT
        canal_venda,
        valor_vendido,
        100.0 * valor_vendido
            / SUM(valor_vendido) OVER ()
            AS participacao_percentual
    FROM vendas_canal
),

cancelamentos AS (
    SELECT
        canal_venda,
        COUNT(*) AS total_pedidos,

        COUNT(*) FILTER (
            WHERE status_pedido = 'Cancelado'
        ) AS pedidos_cancelados,

        100.0
        * COUNT(*) FILTER (
            WHERE status_pedido = 'Cancelado'
        )
        / COUNT(*) AS taxa_cancelamento
    FROM raw.pedidos
    GROUP BY canal_venda
),

atrasos AS (
    SELECT
        p.canal_venda,

        COUNT(*) FILTER (
            WHERE fe.status_entrega = 'Entregue'
        ) AS entregas_concluidas,

        COUNT(*) FILTER (
            WHERE fe.entrega_atrasada = TRUE
        ) AS entregas_atrasadas,

        100.0
        * COUNT(*) FILTER (
            WHERE fe.entrega_atrasada = TRUE
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE fe.status_entrega = 'Entregue'
            ),
            0
        ) AS taxa_atraso

    FROM analytics.fato_entregas fe

    INNER JOIN raw.pedidos p
        ON fe.id_pedido = p.id_pedido

    GROUP BY p.canal_venda
)

SELECT
    p.canal_venda,

    ROUND(p.valor_vendido, 2)
        AS valor_vendido,

    ROUND(p.participacao_percentual, 2)
        AS participacao_percentual,

    c.total_pedidos,
    c.pedidos_cancelados,

    ROUND(c.taxa_cancelamento, 2)
        AS taxa_cancelamento_percentual,

    a.entregas_concluidas,
    a.entregas_atrasadas,

    ROUND(a.taxa_atraso, 2)
        AS taxa_atraso_percentual

FROM participacao p

INNER JOIN cancelamentos c
    ON p.canal_venda = c.canal_venda

INNER JOIN atrasos a
    ON p.canal_venda = a.canal_venda

ORDER BY p.valor_vendido DESC;


-- ============================================================
-- RESULTADO OBSERVADO
--
-- Site:
-- participação nas vendas = 44,94%
-- cancelamento = 7,17%
-- atraso = 24,50%
--
-- App:
-- participação nas vendas = 35,03%
-- cancelamento = 7,44%
-- atraso = 25,14%
--
-- Marketplace:
-- participação nas vendas = 20,02%
-- cancelamento = 7,47%
-- atraso = 25,71%
--
-- Interpretação:
-- No cenário sintético, o Site concentrou a maior participação
-- no valor vendido e apresentou taxas ligeiramente menores
-- de cancelamento e atraso.
-- ============================================================



-- ============================================================
-- INSIGHT 2
-- RISCO DE ESTOQUE POR CATEGORIA
--
-- Objetivo:
-- Avaliar a situação de estoque no snapshot mais recente.
-- ============================================================

WITH ultimo_snapshot AS (
    SELECT
        MAX(data_referencia) AS data_referencia
    FROM analytics.fato_estoque
)

SELECT
    dp.categoria,

    COUNT(*) AS total_produtos,

    COUNT(*) FILTER (
        WHERE fe.abaixo_estoque_minimo = TRUE
    ) AS produtos_abaixo_minimo,

    COUNT(*) FILTER (
        WHERE fe.estoque_zerado = TRUE
    ) AS produtos_zerados,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE fe.abaixo_estoque_minimo = TRUE
        )
        / COUNT(*),
        2
    ) AS percentual_abaixo_minimo

FROM analytics.fato_estoque fe

INNER JOIN analytics.dim_produto dp
    ON fe.id_produto = dp.id_produto

WHERE fe.data_referencia = (
    SELECT data_referencia
    FROM ultimo_snapshot
)

GROUP BY dp.categoria

ORDER BY percentual_abaixo_minimo DESC;


-- ============================================================
-- RESULTADO OBSERVADO
--
-- Eletrônicos:
-- 97 produtos
-- 20 abaixo do mínimo
-- 12 zerados
-- 20,62% abaixo do mínimo
--
-- Interpretação:
-- No snapshot de 31/12/2025, Eletrônicos apresentou a maior
-- proporção de produtos abaixo do estoque mínimo.
--
-- Recomendação no cenário simulado:
-- priorizar o acompanhamento de reposição dessa categoria,
-- principalmente itens zerados e abaixo do estoque mínimo.
-- ============================================================



-- ============================================================
-- INSIGHT 3
-- PRODUTOS DE ALTA DEMANDA COM ESTOQUE CRÍTICO
--
-- Objetivo:
-- Identificar produtos entre os 50 de maior demanda que
-- terminaram o período abaixo do estoque mínimo.
-- ============================================================

WITH vendas_produto AS (
    SELECT
        id_produto,
        SUM(quantidade) AS unidades_vendidas,
        SUM(valor_item) AS valor_vendido
    FROM analytics.fato_vendas
    WHERE status_pedido = 'Concluido'
    GROUP BY id_produto
),

ultimo_estoque AS (
    SELECT
        id_produto,
        quantidade_disponivel,
        estoque_minimo,
        estoque_zerado,
        abaixo_estoque_minimo
    FROM analytics.fato_estoque
    WHERE data_referencia = (
        SELECT MAX(data_referencia)
        FROM analytics.fato_estoque
    )
),

ranking_demanda AS (
    SELECT
        vp.id_produto,
        dp.nome_produto,
        dp.categoria,
        vp.unidades_vendidas,
        vp.valor_vendido,
        ue.quantidade_disponivel,
        ue.estoque_minimo,
        ue.estoque_zerado,
        ue.abaixo_estoque_minimo,

        RANK() OVER (
            ORDER BY vp.unidades_vendidas DESC
        ) AS ranking_demanda

    FROM vendas_produto vp

    INNER JOIN analytics.dim_produto dp
        ON vp.id_produto = dp.id_produto

    INNER JOIN ultimo_estoque ue
        ON vp.id_produto = ue.id_produto
)

SELECT
    id_produto,
    nome_produto,
    categoria,
    ranking_demanda,
    unidades_vendidas,

    ROUND(valor_vendido, 2)
        AS valor_vendido,

    quantidade_disponivel,
    estoque_minimo,
    estoque_zerado

FROM ranking_demanda

WHERE ranking_demanda <= 50
  AND abaixo_estoque_minimo = TRUE

ORDER BY ranking_demanda;


-- ============================================================
-- RESULTADO OBSERVADO
--
-- 9 produtos entre os 50 de maior demanda terminaram
-- o período abaixo do estoque mínimo.
--
-- Exemplo:
-- Futebol SportMax 0255
-- ranking de demanda: 1
-- unidades vendidas: 344
-- estoque disponível: 22
-- estoque mínimo: 25
--
-- Também foram identificados produtos de alta demanda
-- com estoque zerado no último snapshot.
--
-- Interpretação:
-- A combinação de demanda elevada e estoque crítico indica
-- itens que merecem prioridade no planejamento de reposição
-- dentro do cenário simulado.
-- ============================================================