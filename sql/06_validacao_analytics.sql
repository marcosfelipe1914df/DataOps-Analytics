-- ============================================================
-- Projeto: DataOps Analytics
-- Script: 06_validacao_analytics.sql
-- Objetivo:
-- Validar a integridade e reconciliar as camadas
-- RAW e Analytics.
-- ============================================================


-- ============================================================
-- 1. CLIENTES: RAW x ANALYTICS
-- Esperado: diferença = 0
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM raw.clientes) AS raw_clientes,
    (SELECT COUNT(*) FROM analytics.dim_cliente) AS analytics_clientes,
    (SELECT COUNT(*) FROM raw.clientes)
        - (SELECT COUNT(*) FROM analytics.dim_cliente)
        AS diferenca;


-- ============================================================
-- 2. PRODUTOS: RAW x ANALYTICS
-- Esperado: diferença = 0
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM raw.produtos) AS raw_produtos,
    (SELECT COUNT(*) FROM analytics.dim_produto) AS analytics_produtos,
    (SELECT COUNT(*) FROM raw.produtos)
        - (SELECT COUNT(*) FROM analytics.dim_produto)
        AS diferenca;


-- ============================================================
-- 3. ITENS x FATO VENDAS
-- Esperado: diferença = 0
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM raw.itens_pedido) AS raw_itens,
    (SELECT COUNT(*) FROM analytics.fato_vendas) AS fato_vendas,
    (SELECT COUNT(*) FROM raw.itens_pedido)
        - (SELECT COUNT(*) FROM analytics.fato_vendas)
        AS diferenca;


-- ============================================================
-- 4. ENTREGAS: RAW x ANALYTICS
-- Esperado: diferença = 0
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM raw.entregas) AS raw_entregas,
    (SELECT COUNT(*) FROM analytics.fato_entregas) AS fato_entregas,
    (SELECT COUNT(*) FROM raw.entregas)
        - (SELECT COUNT(*) FROM analytics.fato_entregas)
        AS diferenca;


-- ============================================================
-- 5. ESTOQUE: RAW x ANALYTICS
-- Esperado: diferença = 0
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM raw.estoque) AS raw_estoque,
    (SELECT COUNT(*) FROM analytics.fato_estoque) AS fato_estoque,
    (SELECT COUNT(*) FROM raw.estoque)
        - (SELECT COUNT(*) FROM analytics.fato_estoque)
        AS diferenca;


-- ============================================================
-- 6. IDs DE CLIENTES SEM CORRESPONDÊNCIA
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS clientes_sem_correspondencia
FROM analytics.fato_vendas fv
LEFT JOIN analytics.dim_cliente dc
    ON fv.id_cliente = dc.id_cliente
WHERE dc.id_cliente IS NULL;


-- ============================================================
-- 7. IDs DE PRODUTOS SEM CORRESPONDÊNCIA
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS produtos_sem_correspondencia
FROM analytics.fato_vendas fv
LEFT JOIN analytics.dim_produto dp
    ON fv.id_produto = dp.id_produto
WHERE dp.id_produto IS NULL;


-- ============================================================
-- 8. DATAS DE VENDA SEM CORRESPONDÊNCIA
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS datas_venda_sem_correspondencia
FROM analytics.fato_vendas fv
LEFT JOIN analytics.dim_data dd
    ON fv.data = dd.data
WHERE dd.data IS NULL;


-- ============================================================
-- 9. DATAS DE ENTREGA SEM CORRESPONDÊNCIA
-- Usa data_pedido como relacionamento com dim_data.
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS datas_entrega_sem_correspondencia
FROM analytics.fato_entregas fe
LEFT JOIN analytics.dim_data dd
    ON fe.data_pedido = dd.data
WHERE dd.data IS NULL;


-- ============================================================
-- 10. DATAS DE ESTOQUE SEM CORRESPONDÊNCIA
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS datas_estoque_sem_correspondencia
FROM analytics.fato_estoque fe
LEFT JOIN analytics.dim_data dd
    ON fe.data_referencia = dd.data
WHERE dd.data IS NULL;


-- ============================================================
-- 11. RECONCILIAÇÃO DO VALOR DOS ITENS
--
-- Compara o valor total dos itens na RAW
-- com o valor total carregado em fato_vendas.
--
-- Esperado: diferença = 0.00
-- ============================================================

SELECT
    ROUND(
        (SELECT SUM(valor_item) FROM raw.itens_pedido),
        2
    ) AS valor_raw,

    ROUND(
        (SELECT SUM(valor_item) FROM analytics.fato_vendas),
        2
    ) AS valor_analytics,

    ROUND(
        (SELECT SUM(valor_item) FROM raw.itens_pedido)
        -
        (SELECT SUM(valor_item) FROM analytics.fato_vendas),
        2
    ) AS diferenca;


-- ============================================================
-- 12. QUANTIDADE VENDIDA: RAW x ANALYTICS
-- Esperado: diferença = 0
-- ============================================================

SELECT
    (SELECT SUM(quantidade) FROM raw.itens_pedido)
        AS quantidade_raw,

    (SELECT SUM(quantidade) FROM analytics.fato_vendas)
        AS quantidade_analytics,

    (SELECT SUM(quantidade) FROM raw.itens_pedido)
    -
    (SELECT SUM(quantidade) FROM analytics.fato_vendas)
        AS diferenca;


-- ============================================================
-- 13. VALIDAÇÃO DA REGRA DE ATRASO
--
-- Compara a regra diretamente na RAW com a flag
-- criada na camada Analytics.
--
-- Esperado:
-- RAW = 11187
-- Analytics = 11187
-- diferença = 0
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM raw.entregas
        WHERE status_entrega = 'Entregue'
          AND data_entrega::date > data_prevista::date
    ) AS atrasadas_raw,

    (
        SELECT COUNT(*)
        FROM analytics.fato_entregas
        WHERE entrega_atrasada = TRUE
    ) AS atrasadas_analytics,

    (
        SELECT COUNT(*)
        FROM raw.entregas
        WHERE status_entrega = 'Entregue'
          AND data_entrega::date > data_prevista::date
    )
    -
    (
        SELECT COUNT(*)
        FROM analytics.fato_entregas
        WHERE entrega_atrasada = TRUE
    ) AS diferenca;


-- ============================================================
-- 14. VALIDAÇÃO DA REGRA DE ESTOQUE ABAIXO DO MÍNIMO
--
-- Esperado:
-- RAW = 1736
-- Analytics = 1736
-- diferença = 0
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM raw.estoque
        WHERE quantidade_disponivel < estoque_minimo
    ) AS abaixo_minimo_raw,

    (
        SELECT COUNT(*)
        FROM analytics.fato_estoque
        WHERE abaixo_estoque_minimo = TRUE
    ) AS abaixo_minimo_analytics,

    (
        SELECT COUNT(*)
        FROM raw.estoque
        WHERE quantidade_disponivel < estoque_minimo
    )
    -
    (
        SELECT COUNT(*)
        FROM analytics.fato_estoque
        WHERE abaixo_estoque_minimo = TRUE
    ) AS diferenca;


-- ============================================================
-- 15. VALIDAÇÃO DA REGRA DE ESTOQUE ZERADO
--
-- Esperado:
-- RAW = 963
-- Analytics = 963
-- diferença = 0
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM raw.estoque
        WHERE quantidade_disponivel = 0
    ) AS estoque_zero_raw,

    (
        SELECT COUNT(*)
        FROM analytics.fato_estoque
        WHERE estoque_zerado = TRUE
    ) AS estoque_zero_analytics,

    (
        SELECT COUNT(*)
        FROM raw.estoque
        WHERE quantidade_disponivel = 0
    )
    -
    (
        SELECT COUNT(*)
        FROM analytics.fato_estoque
        WHERE estoque_zerado = TRUE
    ) AS diferenca;


-- ============================================================
-- 16. DIMENSÃO DATA
--
-- Período esperado:
-- 2024-01-01 até 2025-12-31
-- 731 registros
-- ============================================================

SELECT
    COUNT(*) AS total_datas,
    MIN(data) AS primeira_data,
    MAX(data) AS ultima_data
FROM analytics.dim_data;