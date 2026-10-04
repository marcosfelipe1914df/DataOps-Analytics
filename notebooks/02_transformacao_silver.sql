-- Databricks notebook source

SELECT
    COUNT(*) AS total_entregas,
    COUNT(DISTINCT id_entrega) AS ids_unicos,

    SUM(CASE
        WHEN id_pedido IS NULL
        THEN 1 ELSE 0
    END) AS pedido_nulo,

    SUM(CASE
        WHEN transportadora IS NULL
        THEN 1 ELSE 0
    END) AS transportadora_nula,

    SUM(CASE
        WHEN data_envio IS NULL
        THEN 1 ELSE 0
    END) AS envio_nulo,

    SUM(CASE
        WHEN data_prevista IS NULL
        THEN 1 ELSE 0
    END) AS prevista_nula,

    SUM(CASE
        WHEN status_entrega = 'Entregue'
             AND tentativas_entrega <= 0
        THEN 1 ELSE 0
    END) AS tentativas_invalidas,

    SUM(CASE
        WHEN custo_logistico < 0
        THEN 1 ELSE 0
    END) AS custo_negativo,

    SUM(CASE
        WHEN status_entrega = 'Entregue'
             AND data_entrega IS NULL
        THEN 1 ELSE 0
    END) AS entregue_sem_data

FROM workspace.silver.entregas;

-- COMMAND ----------


SELECT
    status_entrega,
    COUNT(*) AS total,
    MIN(tentativas_entrega) AS minimo_tentativas,
    MAX(tentativas_entrega) AS maximo_tentativas
FROM workspace.silver.entregas
GROUP BY status_entrega
ORDER BY status_entrega;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_entregas,
    COUNT(DISTINCT id_entrega) AS ids_unicos,
    SUM(CASE WHEN id_pedido IS NULL THEN 1 ELSE 0 END) AS pedido_nulo,
    SUM(CASE WHEN transportadora IS NULL THEN 1 ELSE 0 END) AS transportadora_nula,
    SUM(CASE WHEN data_envio IS NULL THEN 1 ELSE 0 END) AS envio_nulo,
    SUM(CASE WHEN data_prevista IS NULL THEN 1 ELSE 0 END) AS prevista_nula,
    SUM(CASE WHEN tentativas_entrega <= 0 THEN 1 ELSE 0 END) AS tentativas_invalidas,
    SUM(CASE WHEN custo_logistico < 0 THEN 1 ELSE 0 END) AS custo_negativo,
    SUM(
        CASE
            WHEN status_entrega = 'Entregue'
             AND data_entrega IS NULL
            THEN 1 ELSE 0
        END
    ) AS entregue_sem_data
FROM workspace.silver.entregas;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.silver.entregas AS
SELECT
    CAST(id_entrega AS BIGINT) AS id_entrega,
    CAST(id_pedido AS BIGINT) AS id_pedido,
    TRIM(transportadora) AS transportadora,
    CAST(data_envio AS TIMESTAMP) AS data_envio,
    CAST(data_prevista AS TIMESTAMP) AS data_prevista,
    CAST(data_entrega AS TIMESTAMP) AS data_entrega,
    TRIM(status_entrega) AS status_entrega,
    CAST(tentativas_entrega AS INT) AS tentativas_entrega,
    ROUND(CAST(custo_logistico AS DECIMAL(12,2)), 2) AS custo_logistico
FROM workspace.bronze.entregas;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_estoque,
    COUNT(DISTINCT id_estoque) AS ids_unicos,
    SUM(CASE WHEN id_produto IS NULL THEN 1 ELSE 0 END) AS produto_nulo,
    SUM(CASE WHEN data_referencia IS NULL THEN 1 ELSE 0 END) AS data_nula,
    SUM(CASE WHEN quantidade_disponivel < 0 THEN 1 ELSE 0 END) AS qtd_negativa,
    SUM(CASE WHEN estoque_minimo < 0 THEN 1 ELSE 0 END) AS minimo_negativo,
    SUM(CASE WHEN quantidade_reservada < 0 THEN 1 ELSE 0 END) AS reservada_negativa,
    SUM(CASE WHEN quantidade_reservada > quantidade_disponivel THEN 1 ELSE 0 END) AS reservado_maior_disponivel,
    MIN(data_referencia) AS primeira_data,
    MAX(data_referencia) AS ultima_data
FROM workspace.silver.estoque;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.silver.estoque AS
SELECT
    CAST(id_estoque AS BIGINT) AS id_estoque,
    CAST(id_produto AS BIGINT) AS id_produto,
    CAST(data_referencia AS DATE) AS data_referencia,
    CAST(quantidade_disponivel AS INT) AS quantidade_disponivel,
    CAST(estoque_minimo AS INT) AS estoque_minimo,
    CAST(quantidade_reservada AS INT) AS quantidade_reservada
FROM workspace.bronze.estoque;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_pagamentos,
    COUNT(DISTINCT id_pagamento) AS ids_unicos,
    SUM(CASE WHEN id_pedido IS NULL THEN 1 ELSE 0 END) AS pedido_nulo,
    SUM(CASE WHEN forma_pagamento IS NULL THEN 1 ELSE 0 END) AS forma_nula,
    SUM(CASE WHEN numero_parcelas <= 0 THEN 1 ELSE 0 END) AS parcelas_invalidas,
    SUM(CASE WHEN valor_pagamento < 0 THEN 1 ELSE 0 END) AS valor_negativo,
    SUM(CASE WHEN status_pagamento IS NULL THEN 1 ELSE 0 END) AS status_nulo,
    SUM(
        CASE
            WHEN status_pagamento = 'Aprovado'
                 AND data_pagamento IS NULL
            THEN 1 ELSE 0
        END
    ) AS aprovado_sem_data
FROM workspace.silver.pagamentos;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.silver.pagamentos AS
SELECT
    CAST(id_pagamento AS BIGINT) AS id_pagamento,
    CAST(id_pedido AS BIGINT) AS id_pedido,
    TRIM(forma_pagamento) AS forma_pagamento,
    CAST(numero_parcelas AS INT) AS numero_parcelas,
    ROUND(CAST(valor_pagamento AS DECIMAL(14,2)), 2) AS valor_pagamento,
    TRIM(status_pagamento) AS status_pagamento,
    CAST(data_pagamento AS TIMESTAMP) AS data_pagamento
FROM workspace.bronze.pagamentos;

-- COMMAND ----------


SELECT
    SUM(CASE WHEN p.id_pedido IS NULL THEN 1 ELSE 0 END) AS pedidos_inexistentes,
    SUM(CASE WHEN pr.id_produto IS NULL THEN 1 ELSE 0 END) AS produtos_inexistentes
FROM workspace.silver.itens_pedido i
LEFT JOIN workspace.silver.pedidos p
    ON i.id_pedido = p.id_pedido
LEFT JOIN workspace.silver.produtos pr
    ON i.id_produto = pr.id_produto;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_itens,
    COUNT(DISTINCT id_item) AS ids_unicos,
    SUM(CASE WHEN id_pedido IS NULL THEN 1 ELSE 0 END) AS pedido_nulo,
    SUM(CASE WHEN id_produto IS NULL THEN 1 ELSE 0 END) AS produto_nulo,
    SUM(CASE WHEN quantidade <= 0 THEN 1 ELSE 0 END) AS quantidade_invalida,
    SUM(CASE WHEN preco_unitario <= 0 THEN 1 ELSE 0 END) AS preco_invalido,
    SUM(CASE WHEN desconto_item < 0 THEN 1 ELSE 0 END) AS desconto_invalido,
    SUM(CASE WHEN valor_item <= 0 THEN 1 ELSE 0 END) AS valor_invalido
FROM workspace.silver.itens_pedido;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.silver.itens_pedido AS
SELECT
    CAST(id_item AS BIGINT) AS id_item,
    CAST(id_pedido AS BIGINT) AS id_pedido,
    CAST(id_produto AS BIGINT) AS id_produto,
    CAST(quantidade AS INT) AS quantidade,
    ROUND(CAST(preco_unitario AS DECIMAL(12,2)), 2) AS preco_unitario,
    ROUND(CAST(desconto_item AS DECIMAL(12,2)), 2) AS desconto_item,
    ROUND(CAST(valor_item AS DECIMAL(14,2)), 2) AS valor_item
FROM workspace.bronze.itens_pedido;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_pedidos,
    COUNT(DISTINCT id_pedido) AS ids_unicos,
    SUM(CASE WHEN id_cliente IS NULL THEN 1 ELSE 0 END) AS cliente_nulo,
    SUM(CASE WHEN data_pedido IS NULL THEN 1 ELSE 0 END) AS data_nula,
    SUM(CASE WHEN valor_frete < 0 THEN 1 ELSE 0 END) AS frete_negativo,
    SUM(CASE WHEN desconto_pedido < 0 THEN 1 ELSE 0 END) AS desconto_negativo,
    SUM(CASE WHEN valor_total <= 0 THEN 1 ELSE 0 END) AS total_invalido,
    MIN(data_pedido) AS primeira_data,
    MAX(data_pedido) AS ultima_data
FROM workspace.silver.pedidos;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.silver.pedidos AS
SELECT
    CAST(id_pedido AS BIGINT) AS id_pedido,
    CAST(id_cliente AS BIGINT) AS id_cliente,
    CAST(data_pedido AS TIMESTAMP) AS data_pedido,
    TRIM(canal_venda) AS canal_venda,
    TRIM(status_pedido) AS status_pedido,
    ROUND(CAST(valor_frete AS DECIMAL(12,2)), 2) AS valor_frete,
    ROUND(CAST(desconto_pedido AS DECIMAL(12,2)), 2) AS desconto_pedido,
    ROUND(CAST(valor_total AS DECIMAL(14,2)), 2) AS valor_total
FROM workspace.bronze.pedidos;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_produtos,
    COUNT(DISTINCT id_produto) AS ids_unicos,
    SUM(CASE WHEN nome_produto IS NULL THEN 1 ELSE 0 END) AS nome_nulo,
    SUM(CASE WHEN categoria IS NULL THEN 1 ELSE 0 END) AS categoria_nula,
    SUM(CASE WHEN custo_unitario < 0 THEN 1 ELSE 0 END) AS custo_negativo,
    SUM(CASE WHEN preco_unitario <= custo_unitario THEN 1 ELSE 0 END) AS preco_menor_igual_custo,
    COUNT(DISTINCT categoria) AS categorias
FROM workspace.silver.produtos;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.silver.produtos AS
SELECT
    CAST(id_produto AS BIGINT) AS id_produto,
    TRIM(nome_produto) AS nome_produto,
    TRIM(categoria) AS categoria,
    TRIM(subcategoria) AS subcategoria,
    TRIM(marca) AS marca,
    ROUND(CAST(custo_unitario AS DECIMAL(12,2)), 2) AS custo_unitario,
    ROUND(CAST(preco_unitario AS DECIMAL(12,2)), 2) AS preco_unitario,
    TRIM(status_produto) AS status_produto
FROM workspace.bronze.produtos;

-- COMMAND ----------


CREATE OR REPLACE TABLE workspace.silver.clientes AS
SELECT
    CAST(id_cliente AS BIGINT) AS id_cliente,
    TRIM(nome_cliente) AS nome_cliente,
    CAST(data_cadastro AS DATE) AS data_cadastro,
    LPAD(CAST(cep AS STRING), 8, '0') AS cep,
    TRIM(cidade) AS cidade,
    UPPER(TRIM(uf)) AS uf,
    TRIM(segmento_cliente) AS segmento_cliente,
    TRIM(status_cliente) AS status_cliente
FROM workspace.bronze.clientes_enriquecidos;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_clientes,
    COUNT(DISTINCT id_cliente) AS ids_unicos,
    SUM(CASE WHEN cep IS NULL THEN 1 ELSE 0 END) AS cep_nulo,
    SUM(CASE WHEN LENGTH(cep) <> 8 THEN 1 ELSE 0 END) AS cep_invalido,
    SUM(CASE WHEN cidade IS NULL THEN 1 ELSE 0 END) AS cidade_nula,
    SUM(CASE WHEN uf IS NULL THEN 1 ELSE 0 END) AS uf_nula,
    COUNT(DISTINCT cidade) AS cidades,
    COUNT(DISTINCT uf) AS ufs
FROM workspace.silver.clientes;

-- COMMAND ----------


SELECT
    COUNT(*) AS total_clientes,
    COUNT(DISTINCT id_cliente) AS ids_unicos,
    SUM(CASE WHEN nome_cliente IS NULL THEN 1 ELSE 0 END) AS nome_nulo,
    SUM(CASE WHEN data_cadastro IS NULL THEN 1 ELSE 0 END) AS data_nula,
    SUM(CASE WHEN cep IS NULL THEN 1 ELSE 0 END) AS cep_nulo,
    SUM(CASE WHEN cidade IS NULL THEN 1 ELSE 0 END) AS cidade_nula,
    SUM(CASE WHEN uf IS NULL THEN 1 ELSE 0 END) AS uf_nula
FROM workspace.bronze.clientes;