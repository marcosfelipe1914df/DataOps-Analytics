-- Databricks notebook source

SELECT
    COUNT(*) AS total_datas,
    COUNT(DISTINCT data) AS datas_unicas,
    MIN(data) AS primeira_data,
    MAX(data) AS ultima_data,
    COUNT(DISTINCT ano) AS anos,
    COUNT(DISTINCT mes) AS meses
FROM workspace.gold.dim_data;

-- COMMAND ----------


SELECT 'Clientes' AS tabela,
       (SELECT COUNT(*) FROM workspace.silver.clientes) AS silver,
       (SELECT COUNT(*) FROM workspace.gold.dim_cliente) AS gold

UNION ALL

SELECT 'Produtos',
       (SELECT COUNT(*) FROM workspace.silver.produtos),
       (SELECT COUNT(*) FROM workspace.gold.dim_produto)

UNION ALL

SELECT 'Itens / Fato Vendas',
       (SELECT COUNT(*) FROM workspace.silver.itens_pedido),
       (SELECT COUNT(*) FROM workspace.gold.fato_vendas)

UNION ALL

SELECT 'Entregas',
       (SELECT COUNT(*) FROM workspace.silver.entregas),
       (SELECT COUNT(*) FROM workspace.gold.fato_entregas)

UNION ALL

SELECT 'Estoque',
       (SELECT COUNT(*) FROM workspace.silver.estoque),
       (SELECT COUNT(*) FROM workspace.gold.fato_estoque);

-- COMMAND ----------


SELECT
    SUM(CASE
        WHEN quantidade_disponivel < estoque_minimo
        THEN 1 ELSE 0
    END) AS total_abaixo_minimo_incluindo_zerados,

    SUM(CASE
        WHEN quantidade_disponivel = 0
        THEN 1 ELSE 0
    END) AS zerados,

    SUM(CASE
        WHEN quantidade_disponivel > 0
             AND quantidade_disponivel < estoque_minimo
        THEN 1 ELSE 0
    END) AS abaixo_minimo_sem_zerados

FROM workspace.gold.fato_estoque;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT id_produto) AS produtos,
    COUNT(DISTINCT data_referencia) AS snapshots,

    SUM(CASE
        WHEN quantidade_disponivel < 0
        THEN 1 ELSE 0
    END) AS estoque_negativo,

    SUM(CASE
        WHEN status_estoque = 'ZERADO'
        THEN 1 ELSE 0
    END) AS estoque_zerado,

    SUM(CASE
        WHEN status_estoque = 'ABAIXO DO MÍNIMO'
        THEN 1 ELSE 0
    END) AS abaixo_minimo,

    SUM(CASE
        WHEN status_estoque = 'NORMAL'
        THEN 1 ELSE 0
    END) AS estoque_normal

FROM workspace.gold.fato_estoque;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.gold.fato_estoque AS
SELECT
    id_estoque,
    id_produto,
    data_referencia,
    quantidade_disponivel,
    estoque_minimo,
    quantidade_reservada,

    CASE
        WHEN quantidade_disponivel = 0
        THEN 'ZERADO'

        WHEN quantidade_disponivel < estoque_minimo
        THEN 'ABAIXO DO MÍNIMO'

        ELSE 'NORMAL'
    END AS status_estoque

FROM workspace.silver.estoque;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_entregas,
    COUNT(DISTINCT id_entrega) AS entregas_unicas,
    COUNT(DISTINCT id_pedido) AS pedidos_unicos,

    SUM(CASE
        WHEN status_entrega = 'Entregue'
        THEN 1 ELSE 0
    END) AS entregues,

    SUM(CASE
        WHEN status_entrega = 'Em transito'
        THEN 1 ELSE 0
    END) AS em_transito,

    SUM(CASE
        WHEN entrega_atrasada = TRUE
        THEN 1 ELSE 0
    END) AS entregas_atrasadas,

    MAX(dias_atraso) AS maior_atraso_dias,

    SUM(CASE
        WHEN dias_atraso < 0
        THEN 1 ELSE 0
    END) AS atraso_negativo

FROM workspace.gold.fato_entregas;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.gold.fato_entregas AS
SELECT
    e.id_entrega,
    e.id_pedido,
    CAST(p.data_pedido AS DATE) AS data_pedido,
    CAST(e.data_envio AS DATE) AS data_envio,
    CAST(e.data_prevista AS DATE) AS data_prevista,
    CAST(e.data_entrega AS DATE) AS data_entrega,
    e.transportadora,
    e.status_entrega,
    e.tentativas_entrega,
    e.custo_logistico,

    CASE
        WHEN e.status_entrega = 'Entregue'
             AND CAST(e.data_entrega AS DATE) > CAST(e.data_prevista AS DATE)
        THEN TRUE
        ELSE FALSE
    END AS entrega_atrasada,

    CASE
        WHEN e.status_entrega = 'Entregue'
             AND CAST(e.data_entrega AS DATE) > CAST(e.data_prevista AS DATE)
        THEN DATEDIFF(
            CAST(e.data_entrega AS DATE),
            CAST(e.data_prevista AS DATE)
        )
        ELSE 0
    END AS dias_atraso

FROM workspace.silver.entregas e
INNER JOIN workspace.silver.pedidos p
    ON e.id_pedido = p.id_pedido;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_linhas,
    COUNT(DISTINCT id_item) AS itens_unicos,
    COUNT(DISTINCT id_pedido) AS pedidos,
    COUNT(DISTINCT id_cliente) AS clientes,
    COUNT(DISTINCT id_produto) AS produtos,
    SUM(CASE WHEN id_cliente IS NULL THEN 1 ELSE 0 END) AS cliente_nulo,
    SUM(CASE WHEN id_produto IS NULL THEN 1 ELSE 0 END) AS produto_nulo
FROM workspace.gold.fato_vendas;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.gold.fato_vendas AS
SELECT
    i.id_item,
    i.id_pedido,
    p.id_cliente,
    i.id_produto,
    p.data_pedido,
    CAST(p.data_pedido AS DATE) AS data,
    p.canal_venda,
    p.status_pedido,
    i.quantidade,
    i.preco_unitario,
    i.desconto_item,
    i.valor_item
FROM workspace.silver.itens_pedido i
INNER JOIN workspace.silver.pedidos p
    ON i.id_pedido = p.id_pedido;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.gold.dim_data AS
SELECT
    data,
    YEAR(data) AS ano,
    QUARTER(data) AS trimestre,
    MONTH(data) AS mes,
    DAY(data) AS dia,
    DATE_FORMAT(data, 'MMMM') AS nome_mes,
    DAYOFWEEK(data) AS dia_semana,
    DATE_FORMAT(data, 'EEEE') AS nome_dia_semana
FROM (
    SELECT EXPLODE(
        SEQUENCE(
            TO_DATE('2024-01-01'),
            TO_DATE('2025-12-31'),
            INTERVAL 1 DAY
        )
    ) AS data
);

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.gold.dim_produto AS
SELECT
    id_produto,
    nome_produto,
    categoria,
    subcategoria,
    marca,
    custo_unitario,
    preco_unitario,
    status_produto
FROM workspace.silver.produtos;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.gold.dim_cliente AS
SELECT
    id_cliente,
    nome_cliente,
    data_cadastro,
    cep,
    cidade,
    uf,
    segmento_cliente,
    status_cliente
FROM workspace.silver.clientes;