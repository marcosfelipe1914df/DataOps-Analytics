-- ============================================================
-- Projeto: DataOps Analytics
-- Script: 04_criar_modelo_analytics.sql
-- Objetivo:
-- Criar o modelo dimensional da camada Analytics.
--
-- Modelo:
-- Dimensões:
--   dim_cliente
--   dim_produto
--   dim_data
--
-- Fatos:
--   fato_vendas
--   fato_entregas
--   fato_estoque
-- ============================================================


-- ============================================================
-- 1. DIMENSÃO CLIENTE
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.dim_cliente (
    id_cliente INTEGER PRIMARY KEY,
    nome_cliente VARCHAR(150) NOT NULL,
    data_cadastro DATE NOT NULL,
    cep VARCHAR(10),
    cidade VARCHAR(100),
    uf VARCHAR(2),
    segmento_cliente VARCHAR(30) NOT NULL,
    status_cliente VARCHAR(20) NOT NULL
);


-- ============================================================
-- 2. DIMENSÃO PRODUTO
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.dim_produto (
    id_produto INTEGER PRIMARY KEY,
    nome_produto VARCHAR(150) NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    subcategoria VARCHAR(100) NOT NULL,
    marca VARCHAR(100) NOT NULL,
    custo_unitario NUMERIC(12,2) NOT NULL,
    preco_unitario NUMERIC(12,2) NOT NULL,
    status_produto VARCHAR(20) NOT NULL
);


-- ============================================================
-- 3. DIMENSÃO DATA
-- Uma linha para cada dia do período analítico.
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.dim_data (
    data DATE PRIMARY KEY,
    ano INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    nome_mes VARCHAR(20) NOT NULL,
    dia INTEGER NOT NULL,
    dia_semana INTEGER NOT NULL,
    nome_dia_semana VARCHAR(20) NOT NULL,
    fim_de_semana BOOLEAN NOT NULL
);


-- ============================================================
-- 4. FATO VENDAS
--
-- Granularidade:
-- uma linha por ITEM vendido em cada pedido.
--
-- Essa granularidade permite analisar vendas por:
-- cliente, produto, data, canal e pedido.
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.fato_vendas (
    id_item INTEGER PRIMARY KEY,
    id_pedido INTEGER NOT NULL,
    id_cliente INTEGER NOT NULL,
    id_produto INTEGER NOT NULL,
    data_pedido TIMESTAMP NOT NULL,
    data DATE NOT NULL,
    canal_venda VARCHAR(30) NOT NULL,
    status_pedido VARCHAR(30) NOT NULL,
    quantidade INTEGER NOT NULL,
    preco_unitario NUMERIC(12,2) NOT NULL,
    desconto_item NUMERIC(12,2) NOT NULL,
    valor_item NUMERIC(12,2) NOT NULL,

    CONSTRAINT fk_fato_vendas_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES analytics.dim_cliente(id_cliente),

    CONSTRAINT fk_fato_vendas_produto
        FOREIGN KEY (id_produto)
        REFERENCES analytics.dim_produto(id_produto),

    CONSTRAINT fk_fato_vendas_data
        FOREIGN KEY (data)
        REFERENCES analytics.dim_data(data)
);


-- ============================================================
-- 5. FATO ENTREGAS
--
-- Granularidade:
-- uma linha por entrega.
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.fato_entregas (
    id_entrega INTEGER PRIMARY KEY,
    id_pedido INTEGER NOT NULL UNIQUE,
    data_pedido DATE NOT NULL,
    data_envio DATE NOT NULL,
    data_prevista DATE NOT NULL,
    data_entrega DATE,
    transportadora VARCHAR(100) NOT NULL,
    status_entrega VARCHAR(30) NOT NULL,
    tentativas_entrega INTEGER NOT NULL,
    custo_logistico NUMERIC(12,2) NOT NULL,
    dias_atraso INTEGER,
    entrega_atrasada BOOLEAN NOT NULL,

    CONSTRAINT fk_fato_entregas_data
        FOREIGN KEY (data_pedido)
        REFERENCES analytics.dim_data(data)
);


-- ============================================================
-- 6. FATO ESTOQUE
--
-- Granularidade:
-- uma linha por produto em cada fechamento mensal.
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.fato_estoque (
    id_estoque INTEGER PRIMARY KEY,
    id_produto INTEGER NOT NULL,
    data_referencia DATE NOT NULL,
    quantidade_disponivel INTEGER NOT NULL,
    estoque_minimo INTEGER NOT NULL,
    quantidade_reservada INTEGER NOT NULL,
    abaixo_estoque_minimo BOOLEAN NOT NULL,
    estoque_zerado BOOLEAN NOT NULL,

    CONSTRAINT fk_fato_estoque_produto
        FOREIGN KEY (id_produto)
        REFERENCES analytics.dim_produto(id_produto),

    CONSTRAINT fk_fato_estoque_data
        FOREIGN KEY (data_referencia)
        REFERENCES analytics.dim_data(data),

    CONSTRAINT uq_fato_estoque_produto_data
        UNIQUE (id_produto, data_referencia)
);


-- ============================================================
-- 7. VERIFICAÇÃO
-- ============================================================

SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'analytics'
ORDER BY table_name;