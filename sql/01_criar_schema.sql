-- ============================================================
-- Projeto: DataOps Analytics
-- Script: 01_criar_schema.sql
-- Objetivo: Criar os schemas utilizados no projeto
-- ============================================================

-- Schema responsável por armazenar os dados brutos
-- provenientes das fontes originais.
CREATE SCHEMA IF NOT EXISTS raw;

-- Schema responsável pelos dados tratados e preparados
-- para análises e consumo pelas ferramentas de BI.
CREATE SCHEMA IF NOT EXISTS analytics;

-- Confirma os schemas existentes no banco.
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'analytics')
ORDER BY schema_name;