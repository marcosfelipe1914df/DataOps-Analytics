# DataOps Analytics — Fontes e Estratégia de Dados

## 1. Contexto

O DataOps Analytics utilizará uma base principal sintética que representa as operações da empresa fictícia DataOps Commerce.

Os dados sintéticos serão utilizados para permitir a construção controlada de um cenário de e-commerce envolvendo vendas, clientes, produtos, pagamentos, estoque e logística.

Também será utilizada uma API pública real para enriquecimento de dados.

---

## 2. Período de Análise

Período planejado:

01/01/2024 a 31/12/2025

O período contém dois anos completos, permitindo análises temporais, comparações mensais, sazonais e anuais.

---

## 3. Volumes Planejados

Os volumes abaixo representam estimativas iniciais e poderão sofrer alterações durante a geração e validação dos dados.

| Entidade | Volume planejado |
|---|---:|
| Clientes | 5.000 |
| Produtos | 500 |
| Pedidos | 50.000 |
| Itens dos pedidos | Aproximadamente 100.000 |
| Pagamentos | Aproximadamente 50.000 |
| Estoque | A definir conforme granularidade |
| Entregas | Aproximadamente 45.000 |

Os números reais serão registrados posteriormente após a geração e validação dos datasets.

---

# 4. Entidades

## 4.1 Clientes

Arquivo planejado:

`clientes.csv`

Finalidade:

Armazenar informações dos clientes da DataOps Commerce.

Campos:

| Campo | Tipo planejado | Descrição |
|---|---|---|
| id_cliente | INTEGER | Identificador único do cliente |
| nome_cliente | VARCHAR | Nome fictício do cliente |
| data_cadastro | DATE | Data de cadastro |
| cep | VARCHAR | CEP |
| cidade | VARCHAR | Cidade |
| uf | CHAR(2) | Unidade federativa |
| segmento_cliente | VARCHAR | Segmentação do cliente |
| status_cliente | VARCHAR | Situação cadastral |

Chave primária:

`id_cliente`

---

## 4.2 Produtos

Arquivo planejado:

`produtos.xlsx`

Finalidade:

Armazenar o cadastro de produtos comercializados.

Campos:

| Campo | Tipo planejado | Descrição |
|---|---|---|
| id_produto | INTEGER | Identificador único |
| nome_produto | VARCHAR | Nome do produto |
| categoria | VARCHAR | Categoria |
| subcategoria | VARCHAR | Subcategoria |
| marca | VARCHAR | Marca |
| custo_unitario | DECIMAL | Custo unitário |
| preco_unitario | DECIMAL | Preço de venda |
| status_produto | VARCHAR | Ativo ou inativo |

Chave primária:

`id_produto`

---

## 4.3 Pedidos

Arquivo planejado:

`pedidos.csv`

Finalidade:

Representar os pedidos realizados pelos clientes.

Campos:

| Campo | Tipo planejado | Descrição |
|---|---|---|
| id_pedido | INTEGER | Identificador único |
| id_cliente | INTEGER | Cliente responsável pelo pedido |
| data_pedido | TIMESTAMP | Data e hora |
| canal_venda | VARCHAR | Canal utilizado |
| status_pedido | VARCHAR | Situação do pedido |
| valor_frete | DECIMAL | Frete cobrado |
| desconto_pedido | DECIMAL | Desconto aplicado |
| valor_total | DECIMAL | Valor final do pedido |

Chave primária:

`id_pedido`

Chave estrangeira:

`id_cliente → clientes.id_cliente`

---

## 4.4 Itens do Pedido

Arquivo planejado:

`itens_pedido.csv`

Finalidade:

Registrar os produtos existentes em cada pedido.

Campos:

| Campo | Tipo planejado | Descrição |
|---|---|---|
| id_item | INTEGER | Identificador único |
| id_pedido | INTEGER | Pedido |
| id_produto | INTEGER | Produto |
| quantidade | INTEGER | Quantidade comprada |
| preco_unitario | DECIMAL | Preço aplicado na venda |
| desconto_item | DECIMAL | Desconto do item |
| valor_item | DECIMAL | Valor final do item |

Chave primária:

`id_item`

Chaves estrangeiras:

`id_pedido → pedidos.id_pedido`

`id_produto → produtos.id_produto`

---

## 4.5 Pagamentos

Arquivo planejado:

`pagamentos.csv`

Finalidade:

Registrar informações financeiras dos pedidos.

Campos:

| Campo | Tipo planejado | Descrição |
|---|---|---|
| id_pagamento | INTEGER | Identificador |
| id_pedido | INTEGER | Pedido relacionado |
| forma_pagamento | VARCHAR | Forma utilizada |
| numero_parcelas | INTEGER | Quantidade de parcelas |
| valor_pagamento | DECIMAL | Valor pago |
| status_pagamento | VARCHAR | Situação do pagamento |
| data_pagamento | TIMESTAMP | Data do pagamento |

Chave primária:

`id_pagamento`

Chave estrangeira:

`id_pedido → pedidos.id_pedido`

---

## 4.6 Estoque

Arquivo planejado:

`estoque.xlsx`

Finalidade:

Registrar a posição de estoque dos produtos ao longo do tempo.

Campos:

| Campo | Tipo planejado | Descrição |
|---|---|---|
| id_estoque | INTEGER | Identificador |
| id_produto | INTEGER | Produto |
| data_referencia | DATE | Data da posição |
| quantidade_disponivel | INTEGER | Estoque disponível |
| estoque_minimo | INTEGER | Limite mínimo |
| quantidade_reservada | INTEGER | Quantidade reservada |

Chave primária:

`id_estoque`

Chave estrangeira:

`id_produto → produtos.id_produto`

A granularidade definitiva do histórico de estoque será definida durante a implementação.

---

## 4.7 Entregas

Arquivo planejado:

`entregas.csv`

Finalidade:

Registrar informações relacionadas à operação logística.

Campos:

| Campo | Tipo planejado | Descrição |
|---|---|---|
| id_entrega | INTEGER | Identificador |
| id_pedido | INTEGER | Pedido |
| transportadora | VARCHAR | Responsável pela entrega |
| data_envio | TIMESTAMP | Data de expedição |
| data_prevista | DATE | Previsão |
| data_entrega | TIMESTAMP | Entrega efetiva |
| status_entrega | VARCHAR | Situação |
| tentativas_entrega | INTEGER | Número de tentativas |
| custo_logistico | DECIMAL | Custo da operação |

Chave primária:

`id_entrega`

Chave estrangeira:

`id_pedido → pedidos.id_pedido`

---

# 5. Relacionamentos

Relacionamentos planejados:

Clientes
1:N
Pedidos

Pedidos
1:N
Itens do Pedido

Produtos
1:N
Itens do Pedido

Pedidos
1:N
Pagamentos

Produtos
1:N
Estoque

Pedidos
1:0..1
Entregas

Representação simplificada:

CLIENTES
   |
   v
PEDIDOS ---- PAGAMENTOS
   |
   +--------- ENTREGAS
   |
   v
ITENS_PEDIDO
   |
   v
PRODUTOS
   |
   v
ESTOQUE

---

# 6. API Pública

O projeto utilizará uma API pública para demonstrar integração entre fontes internas e externas.

A API deverá possuir finalidade relacionada ao contexto do projeto.

Inicialmente está prevista a utilização de dados geográficos associados aos CEPs utilizados no dataset de clientes.

A API definitiva, endpoints utilizados, regras de consumo e campos incorporados serão documentados durante a implementação.

---

# 7. Estratégia de Geração

Os dados sintéticos serão gerados antes da realização das análises.

O processo deverá produzir variações plausíveis relacionadas a:

- Volume de pedidos;
- Produtos;
- Categorias;
- Clientes;
- Canais de venda;
- Formas de pagamento;
- Descontos;
- Cancelamentos;
- Estoque;
- Prazos de entrega;
- Atrasos logísticos.

Os resultados analíticos serão obtidos somente depois da geração dos dados.

Não serão modificados dados posteriormente com o objetivo de fabricar conclusões ou indicadores específicos.

---

# 8. Qualidade

Durante a geração e ingestão deverão ser verificadas regras como:

- IDs únicos;
- Chaves estrangeiras válidas;
- Quantidades maiores que zero;
- Valores monetários válidos;
- Datas consistentes;
- Campos obrigatórios preenchidos;
- Ausência de duplicidades indevidas;
- Integridade entre pedidos e itens;
- Integridade entre pedidos e pagamentos;
- Integridade entre pedidos e entregas.

Anomalias intencionais utilizadas para testes de qualidade deverão ser documentadas.

---

# 9. Transparência dos Dados

A DataOps Commerce é uma empresa fictícia.

Os dados operacionais principais utilizados neste projeto serão sintéticos.

Fontes externas reais serão identificadas separadamente.

Nenhuma conclusão obtida a partir dos dados sintéticos será apresentada como resultado de uma empresa real.