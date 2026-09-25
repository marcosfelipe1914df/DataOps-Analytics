-- ============================================================
-- Projeto: DataOps Analytics
-- Arquivo: 09_atualizar_dim_cliente.sql
--
-- Objetivo:
-- Sincronizar os dados geográficos enriquecidos em
-- raw.clientes com analytics.dim_cliente.
--
-- Campos atualizados:
--   - cep
--   - cidade
--   - uf
--
-- Estratégia:
--   1. validar correspondência entre RAW e Analytics;
--   2. atualizar somente os atributos geográficos;
--   3. reconciliar os dados após a atualização.
--
-- Não há alteração nas tabelas fato.
-- ============================================================


-- ------------------------------------------------------------
-- 1. VALIDAÇÃO ANTES DA ATUALIZAÇÃO
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_dim_cliente,

    COUNT(*) FILTER (
        WHERE cep IS NOT NULL
    ) AS clientes_com_cep,

    COUNT(*) FILTER (
        WHERE cidade IS NOT NULL
    ) AS clientes_com_cidade,

    COUNT(*) FILTER (
        WHERE uf IS NOT NULL
    ) AS clientes_com_uf

FROM analytics.dim_cliente;


-- ------------------------------------------------------------
-- 2. VERIFICAR CLIENTES DA RAW AUSENTES NA DIMENSÃO
--
-- Resultado esperado: 0
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS clientes_raw_ausentes_dim

FROM raw.clientes r

LEFT JOIN analytics.dim_cliente d
    ON d.id_cliente = r.id_cliente

WHERE d.id_cliente IS NULL;


-- ------------------------------------------------------------
-- 3. VERIFICAR CLIENTES DA DIMENSÃO AUSENTES NA RAW
--
-- Resultado esperado: 0
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS clientes_dim_ausentes_raw

FROM analytics.dim_cliente d

LEFT JOIN raw.clientes r
    ON r.id_cliente = d.id_cliente

WHERE r.id_cliente IS NULL;


-- ------------------------------------------------------------
-- 4. ATUALIZAÇÃO
--
-- UPDATE ... FROM permite atualizar a dimensão utilizando
-- raw.clientes como fonte.
-- ------------------------------------------------------------

UPDATE analytics.dim_cliente AS d

SET
    cep = r.cep,
    cidade = r.cidade,
    uf = r.uf

FROM raw.clientes AS r

WHERE d.id_cliente = r.id_cliente

AND (
       d.cep IS DISTINCT FROM r.cep
    OR d.cidade IS DISTINCT FROM r.cidade
    OR d.uf IS DISTINCT FROM r.uf
);


-- ------------------------------------------------------------
-- 5. VALIDAÇÃO APÓS A ATUALIZAÇÃO
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_clientes,

    COUNT(*) FILTER (
        WHERE cep IS NOT NULL
    ) AS clientes_com_cep,

    COUNT(*) FILTER (
        WHERE cidade IS NOT NULL
    ) AS clientes_com_cidade,

    COUNT(*) FILTER (
        WHERE uf IS NOT NULL
    ) AS clientes_com_uf,

    COUNT(DISTINCT cidade)
        AS cidades,

    COUNT(DISTINCT uf)
        AS ufs

FROM analytics.dim_cliente;


-- ------------------------------------------------------------
-- 6. RECONCILIAÇÃO RAW x ANALYTICS
--
-- Procura qualquer divergência entre os três campos.
--
-- Resultado esperado: 0
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS divergencias_raw_analytics

FROM raw.clientes r

INNER JOIN analytics.dim_cliente d
    ON d.id_cliente = r.id_cliente

WHERE
       d.cep IS DISTINCT FROM r.cep
    OR d.cidade IS DISTINCT FROM r.cidade
    OR d.uf IS DISTINCT FROM r.uf;


-- ------------------------------------------------------------
-- 7. DISTRIBUIÇÃO POR UF
--
-- Serve também como uma pequena validação analítica.
-- ------------------------------------------------------------

SELECT
    uf,
    COUNT(*) AS quantidade_clientes,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_clientes

FROM analytics.dim_cliente

GROUP BY uf

ORDER BY quantidade_clientes DESC, uf;


-- ------------------------------------------------------------
-- 8. DISTRIBUIÇÃO POR CIDADE
-- ------------------------------------------------------------

SELECT
    cidade,
    uf,
    COUNT(*) AS quantidade_clientes

FROM analytics.dim_cliente

GROUP BY
    cidade,
    uf

ORDER BY
    quantidade_clientes DESC,
    cidade;