-- ============================================================
-- Projeto: DataOps Analytics
-- Script: 03_validacao_raw.sql
-- Objetivo:
-- Executar validações de qualidade e integridade dos dados
-- carregados no schema RAW.
-- ============================================================


-- ============================================================
-- 1. CONTAGEM DAS 7 TABELAS
-- ============================================================

SELECT 'clientes' AS tabela, COUNT(*) AS registros
FROM raw.clientes

UNION ALL

SELECT 'produtos', COUNT(*)
FROM raw.produtos

UNION ALL

SELECT 'pedidos', COUNT(*)
FROM raw.pedidos

UNION ALL

SELECT 'itens_pedido', COUNT(*)
FROM raw.itens_pedido

UNION ALL

SELECT 'pagamentos', COUNT(*)
FROM raw.pagamentos

UNION ALL

SELECT 'estoque', COUNT(*)
FROM raw.estoque

UNION ALL

SELECT 'entregas', COUNT(*)
FROM raw.entregas

ORDER BY tabela;


-- ============================================================
-- 2. UNICIDADE DAS CHAVES PRIMÁRIAS
-- ============================================================

SELECT
    'clientes' AS tabela,
    COUNT(*) AS total,
    COUNT(DISTINCT id_cliente) AS ids_unicos
FROM raw.clientes

UNION ALL

SELECT
    'produtos',
    COUNT(*),
    COUNT(DISTINCT id_produto)
FROM raw.produtos

UNION ALL

SELECT
    'pedidos',
    COUNT(*),
    COUNT(DISTINCT id_pedido)
FROM raw.pedidos

UNION ALL

SELECT
    'itens_pedido',
    COUNT(*),
    COUNT(DISTINCT id_item)
FROM raw.itens_pedido

UNION ALL

SELECT
    'pagamentos',
    COUNT(*),
    COUNT(DISTINCT id_pagamento)
FROM raw.pagamentos

UNION ALL

SELECT
    'estoque',
    COUNT(*),
    COUNT(DISTINCT id_estoque)
FROM raw.estoque

UNION ALL

SELECT
    'entregas',
    COUNT(*),
    COUNT(DISTINCT id_entrega)
FROM raw.entregas

ORDER BY tabela;


-- ============================================================
-- 3. PEDIDOS COM CLIENTES INEXISTENTES
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS pedidos_cliente_inexistente
FROM raw.pedidos p
LEFT JOIN raw.clientes c
    ON p.id_cliente = c.id_cliente
WHERE c.id_cliente IS NULL;


-- ============================================================
-- 4. ITENS COM PEDIDOS INEXISTENTES
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS itens_pedido_inexistente
FROM raw.itens_pedido i
LEFT JOIN raw.pedidos p
    ON i.id_pedido = p.id_pedido
WHERE p.id_pedido IS NULL;


-- ============================================================
-- 5. ITENS COM PRODUTOS INEXISTENTES
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS itens_produto_inexistente
FROM raw.itens_pedido i
LEFT JOIN raw.produtos p
    ON i.id_produto = p.id_produto
WHERE p.id_produto IS NULL;


-- ============================================================
-- 6. PEDIDOS SEM ITENS
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS pedidos_sem_itens
FROM raw.pedidos p
LEFT JOIN raw.itens_pedido i
    ON p.id_pedido = i.id_pedido
WHERE i.id_pedido IS NULL;


-- ============================================================
-- 7. PAGAMENTOS APROVADOS COM VALOR DIVERGENTE
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS divergencias_pagamento
FROM raw.pagamentos pg
INNER JOIN raw.pedidos p
    ON pg.id_pedido = p.id_pedido
WHERE pg.status_pagamento = 'Aprovado'
  AND pg.valor_pagamento <> p.valor_total;


-- ============================================================
-- 8. PEDIDOS CONCLUÍDOS SEM PAGAMENTO APROVADO
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS concluidos_sem_pagamento_aprovado
FROM raw.pedidos p
LEFT JOIN raw.pagamentos pg
    ON p.id_pedido = pg.id_pedido
   AND pg.status_pagamento = 'Aprovado'
WHERE p.status_pedido = 'Concluido'
  AND pg.id_pagamento IS NULL;


-- ============================================================
-- 9. PEDIDOS CANCELADOS COM ENTREGA
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS cancelados_com_entrega
FROM raw.pedidos p
INNER JOIN raw.entregas e
    ON p.id_pedido = e.id_pedido
WHERE p.status_pedido = 'Cancelado';


-- ============================================================
-- 10. ENTREGAS CONCLUÍDAS SEM DATA DE ENTREGA
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS entregues_sem_data
FROM raw.entregas
WHERE status_entrega = 'Entregue'
  AND data_entrega IS NULL;


-- ============================================================
-- 11. ENTREGAS EM TRÂNSITO COM DATA DE ENTREGA
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS em_transito_com_data_entrega
FROM raw.entregas
WHERE status_entrega = 'Em transito'
  AND data_entrega IS NOT NULL;


-- ============================================================
-- 12. ENTREGAS ATRASADAS
-- Regra de negócio:
-- atraso é medido pela DATA, e não pelo horário.
-- Esperado: 11187
-- ============================================================

SELECT
    COUNT(*) AS entregas_atrasadas
FROM raw.entregas
WHERE status_entrega = 'Entregue'
  AND data_entrega::date > data_prevista::date;


-- ============================================================
-- 13. ESTOQUE COM VALORES NEGATIVOS
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS estoque_valores_negativos
FROM raw.estoque
WHERE quantidade_disponivel < 0
   OR estoque_minimo < 0
   OR quantidade_reservada < 0;


-- ============================================================
-- 14. ESTOQUE RESERVADO MAIOR QUE DISPONÍVEL
-- Esperado: 0
-- ============================================================

SELECT
    COUNT(*) AS reserva_maior_disponivel
FROM raw.estoque
WHERE quantidade_reservada > quantidade_disponivel;


-- ============================================================
-- 15. INDICADORES DE ESTOQUE
-- Esperado:
-- abaixo_minimo = 1736
-- estoque_zero  = 963
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE quantidade_disponivel < estoque_minimo
    ) AS abaixo_minimo,

    COUNT(*) FILTER (
        WHERE quantidade_disponivel = 0
    ) AS estoque_zero

FROM raw.estoque;


-- ============================================================
-- 16. PERÍODO DOS PEDIDOS
-- ============================================================

SELECT
    MIN(data_pedido) AS primeira_data,
    MAX(data_pedido) AS ultima_data
FROM raw.pedidos;