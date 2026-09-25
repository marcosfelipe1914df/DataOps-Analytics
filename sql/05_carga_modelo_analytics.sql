-- ============================================================
-- Projeto: DataOps Analytics
-- Script: 05_carga_modelo_analytics.sql
-- Objetivo:
-- Popular dimensões e fatos do schema analytics
-- a partir dos dados validados do schema raw.
-- ============================================================


-- ============================================================
-- 1. LIMPEZA PARA PERMITIR REEXECUÇÃO
-- ============================================================

TRUNCATE TABLE
    analytics.fato_vendas,
    analytics.fato_entregas,
    analytics.fato_estoque,
    analytics.dim_cliente,
    analytics.dim_produto,
    analytics.dim_data
CASCADE;


-- ============================================================
-- 2. DIMENSÃO CLIENTE
-- ============================================================

INSERT INTO analytics.dim_cliente (
    id_cliente,
    nome_cliente,
    data_cadastro,
    cep,
    cidade,
    uf,
    segmento_cliente,
    status_cliente
)
SELECT
    id_cliente,
    nome_cliente,
    data_cadastro,
    cep,
    cidade,
    uf,
    segmento_cliente,
    status_cliente
FROM raw.clientes;


-- ============================================================
-- 3. DIMENSÃO PRODUTO
-- ============================================================

INSERT INTO analytics.dim_produto (
    id_produto,
    nome_produto,
    categoria,
    subcategoria,
    marca,
    custo_unitario,
    preco_unitario,
    status_produto
)
SELECT
    id_produto,
    nome_produto,
    categoria,
    subcategoria,
    marca,
    custo_unitario,
    preco_unitario,
    status_produto
FROM raw.produtos;


-- ============================================================
-- 4. DIMENSÃO DATA
--
-- Gera uma linha para cada dia de 2024 e 2025.
-- ============================================================

INSERT INTO analytics.dim_data (
    data,
    ano,
    trimestre,
    mes,
    nome_mes,
    dia,
    dia_semana,
    nome_dia_semana,
    fim_de_semana
)
SELECT
    d::date AS data,

    EXTRACT(YEAR FROM d)::integer AS ano,

    EXTRACT(QUARTER FROM d)::integer AS trimestre,

    EXTRACT(MONTH FROM d)::integer AS mes,

    CASE EXTRACT(MONTH FROM d)::integer
        WHEN 1 THEN 'Janeiro'
        WHEN 2 THEN 'Fevereiro'
        WHEN 3 THEN 'Março'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Maio'
        WHEN 6 THEN 'Junho'
        WHEN 7 THEN 'Julho'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Setembro'
        WHEN 10 THEN 'Outubro'
        WHEN 11 THEN 'Novembro'
        WHEN 12 THEN 'Dezembro'
    END AS nome_mes,

    EXTRACT(DAY FROM d)::integer AS dia,

    EXTRACT(ISODOW FROM d)::integer AS dia_semana,

    CASE EXTRACT(ISODOW FROM d)::integer
        WHEN 1 THEN 'Segunda-feira'
        WHEN 2 THEN 'Terça-feira'
        WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira'
        WHEN 5 THEN 'Sexta-feira'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS nome_dia_semana,

    CASE
        WHEN EXTRACT(ISODOW FROM d) IN (6, 7)
            THEN TRUE
        ELSE FALSE
    END AS fim_de_semana

FROM generate_series(
    DATE '2024-01-01',
    DATE '2025-12-31',
    INTERVAL '1 day'
) AS d;


-- ============================================================
-- 5. FATO VENDAS
--
-- Granularidade:
-- uma linha por item do pedido.
-- ============================================================

INSERT INTO analytics.fato_vendas (
    id_item,
    id_pedido,
    id_cliente,
    id_produto,
    data_pedido,
    data,
    canal_venda,
    status_pedido,
    quantidade,
    preco_unitario,
    desconto_item,
    valor_item
)
SELECT
    i.id_item,
    p.id_pedido,
    p.id_cliente,
    i.id_produto,
    p.data_pedido,
    p.data_pedido::date,
    p.canal_venda,
    p.status_pedido,
    i.quantidade,
    i.preco_unitario,
    i.desconto_item,
    i.valor_item

FROM raw.itens_pedido i

INNER JOIN raw.pedidos p
    ON i.id_pedido = p.id_pedido;


-- ============================================================
-- 6. FATO ENTREGAS
--
-- Regra:
-- entrega atrasada = data_entrega > data_prevista,
-- comparando somente a DATA.
--
-- Para entregas ainda em trânsito:
-- dias_atraso permanece NULL e entrega_atrasada = FALSE.
-- ============================================================

INSERT INTO analytics.fato_entregas (
    id_entrega,
    id_pedido,
    data_pedido,
    data_envio,
    data_prevista,
    data_entrega,
    transportadora,
    status_entrega,
    tentativas_entrega,
    custo_logistico,
    dias_atraso,
    entrega_atrasada
)
SELECT
    e.id_entrega,
    e.id_pedido,
    p.data_pedido::date,
    e.data_envio::date,
    e.data_prevista::date,
    e.data_entrega::date,
    e.transportadora,
    e.status_entrega,
    e.tentativas_entrega,
    e.custo_logistico,

    CASE
        WHEN e.data_entrega IS NULL
            THEN NULL

        WHEN e.data_entrega::date > e.data_prevista::date
            THEN (
                e.data_entrega::date
                - e.data_prevista::date
            )

        ELSE 0
    END AS dias_atraso,

    CASE
        WHEN e.status_entrega = 'Entregue'
         AND e.data_entrega::date > e.data_prevista::date
            THEN TRUE
        ELSE FALSE
    END AS entrega_atrasada

FROM raw.entregas e

INNER JOIN raw.pedidos p
    ON e.id_pedido = p.id_pedido;


-- ============================================================
-- 7. FATO ESTOQUE
-- ============================================================

INSERT INTO analytics.fato_estoque (
    id_estoque,
    id_produto,
    data_referencia,
    quantidade_disponivel,
    estoque_minimo,
    quantidade_reservada,
    abaixo_estoque_minimo,
    estoque_zerado
)
SELECT
    id_estoque,
    id_produto,
    data_referencia,
    quantidade_disponivel,
    estoque_minimo,
    quantidade_reservada,

    CASE
        WHEN quantidade_disponivel < estoque_minimo
            THEN TRUE
        ELSE FALSE
    END AS abaixo_estoque_minimo,

    CASE
        WHEN quantidade_disponivel = 0
            THEN TRUE
        ELSE FALSE
    END AS estoque_zerado

FROM raw.estoque;


-- ============================================================
-- 8. VALIDAÇÃO DAS CARGAS
-- ============================================================

SELECT 'dim_cliente' AS tabela, COUNT(*) AS registros
FROM analytics.dim_cliente

UNION ALL

SELECT 'dim_produto', COUNT(*)
FROM analytics.dim_produto

UNION ALL

SELECT 'dim_data', COUNT(*)
FROM analytics.dim_data

UNION ALL

SELECT 'fato_vendas', COUNT(*)
FROM analytics.fato_vendas

UNION ALL

SELECT 'fato_entregas', COUNT(*)
FROM analytics.fato_entregas

UNION ALL

SELECT 'fato_estoque', COUNT(*)
FROM analytics.fato_estoque

ORDER BY tabela;