-- Databricks notebook source
SELECT 'clientes' AS tabela, COUNT(*) AS registros FROM workspace.bronze.clientes
UNION ALL
SELECT 'produtos', COUNT(*) FROM workspace.bronze.produtos
UNION ALL
SELECT 'pedidos', COUNT(*) FROM workspace.bronze.pedidos
UNION ALL
SELECT 'itens_pedido', COUNT(*) FROM workspace.bronze.itens_pedido
UNION ALL
SELECT 'pagamentos', COUNT(*) FROM workspace.bronze.pagamentos
UNION ALL
SELECT 'estoque', COUNT(*) FROM workspace.bronze.estoque
UNION ALL
SELECT 'entregas', COUNT(*) FROM workspace.bronze.entregas;

-- COMMAND ----------

SELECT COUNT(*) AS total_entregas
FROM workspace.bronze.entregas;

-- COMMAND ----------

SELECT COUNT(*) AS total_estoque
FROM workspace.bronze.estoque;

-- COMMAND ----------

SELECT COUNT(*) AS total_pagamentos
FROM workspace.bronze.pagamentos;

-- COMMAND ----------

SELECT COUNT(*) AS total_itens
FROM workspace.bronze.itens_pedido;

-- COMMAND ----------

SELECT COUNT(*) AS total_pedidos
FROM workspace.bronze.pedidos;

-- COMMAND ----------

CREATE SCHEMA IF NOT EXISTS workspace.bronze;
CREATE SCHEMA IF NOT EXISTS workspace.silver;
CREATE SCHEMA IF NOT EXISTS workspace.gold;

-- COMMAND ----------

SELECT COUNT(*) AS total_clientes
FROM workspace.bronze.clientes;

-- COMMAND ----------

SELECT COUNT(*) AS total_produtos
FROM workspace.bronze.produtos;