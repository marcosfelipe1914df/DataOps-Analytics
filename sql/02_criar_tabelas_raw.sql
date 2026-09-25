-- ============================================================
-- Projeto: DataOps Analytics
-- Script: 02_criar_tabelas_raw.sql
-- Objetivo: Criar as tabelas da camada RAW
-- ============================================================


-- ============================================================
-- 1. CLIENTES
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.clientes (
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
-- 2. PRODUTOS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.produtos (
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
-- 3. PEDIDOS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.pedidos (
    id_pedido INTEGER PRIMARY KEY,
    id_cliente INTEGER NOT NULL,
    data_pedido TIMESTAMP NOT NULL,
    canal_venda VARCHAR(30) NOT NULL,
    status_pedido VARCHAR(30) NOT NULL,
    valor_frete NUMERIC(12,2) NOT NULL,
    desconto_pedido NUMERIC(12,2) NOT NULL,
    valor_total NUMERIC(12,2) NOT NULL,

    CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES raw.clientes(id_cliente)
);


-- ============================================================
-- 4. ITENS DO PEDIDO
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.itens_pedido (
    id_item INTEGER PRIMARY KEY,
    id_pedido INTEGER NOT NULL,
    id_produto INTEGER NOT NULL,
    quantidade INTEGER NOT NULL,
    preco_unitario NUMERIC(12,2) NOT NULL,
    desconto_item NUMERIC(12,2) NOT NULL,
    valor_item NUMERIC(12,2) NOT NULL,

    CONSTRAINT fk_itens_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES raw.pedidos(id_pedido),

    CONSTRAINT fk_itens_produto
        FOREIGN KEY (id_produto)
        REFERENCES raw.produtos(id_produto)
);


-- ============================================================
-- 5. PAGAMENTOS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.pagamentos (
    id_pagamento INTEGER PRIMARY KEY,
    id_pedido INTEGER NOT NULL UNIQUE,
    forma_pagamento VARCHAR(50) NOT NULL,
    numero_parcelas INTEGER NOT NULL,
    valor_pagamento NUMERIC(12,2) NOT NULL,
    status_pagamento VARCHAR(30) NOT NULL,
    data_pagamento TIMESTAMP,

    CONSTRAINT fk_pagamentos_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES raw.pedidos(id_pedido)
);


-- ============================================================
-- 6. ESTOQUE
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.estoque (
    id_estoque INTEGER PRIMARY KEY,
    id_produto INTEGER NOT NULL,
    data_referencia DATE NOT NULL,
    quantidade_disponivel INTEGER NOT NULL,
    estoque_minimo INTEGER NOT NULL,
    quantidade_reservada INTEGER NOT NULL,

    CONSTRAINT fk_estoque_produto
        FOREIGN KEY (id_produto)
        REFERENCES raw.produtos(id_produto),

    CONSTRAINT uq_estoque_produto_data
        UNIQUE (id_produto, data_referencia)
);


-- ============================================================
-- 7. ENTREGAS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.entregas (
    id_entrega INTEGER PRIMARY KEY,
    id_pedido INTEGER NOT NULL UNIQUE,
    transportadora VARCHAR(100) NOT NULL,
    data_envio TIMESTAMP NOT NULL,
    data_prevista TIMESTAMP NOT NULL,
    data_entrega TIMESTAMP,
    status_entrega VARCHAR(30) NOT NULL,
    tentativas_entrega INTEGER NOT NULL,
    custo_logistico NUMERIC(12,2) NOT NULL,

    CONSTRAINT fk_entregas_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES raw.pedidos(id_pedido)
);


-- ============================================================
-- VERIFICAÇÃO
-- Lista as tabelas existentes no schema RAW
-- ============================================================

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'raw'
ORDER BY table_name;