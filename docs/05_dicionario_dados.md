\# Dicionário de Dados — DataOps Analytics



\## 1. Objetivo



Este documento descreve as principais estruturas de dados utilizadas no projeto \*\*DataOps Analytics\*\*, incluindo granularidade, chaves, campos e significado analítico.



> Todos os dados utilizados no projeto são sintéticos e destinados exclusivamente a estudos e portfólio.



\---



\# 2. Visão geral do modelo



O projeto trabalha com dados relacionados a:



\- clientes;

\- produtos;

\- pedidos;

\- itens de pedido;

\- pagamentos;

\- estoque;

\- entregas.



No PostgreSQL, os dados são organizados em:



```text

raw

&#x20;├── clientes

&#x20;├── produtos

&#x20;├── pedidos

&#x20;├── itens\_pedido

&#x20;├── pagamentos

&#x20;├── estoque

&#x20;└── entregas



analytics

&#x20;├── dim\_cliente

&#x20;├── dim\_produto

&#x20;├── dim\_data

&#x20;├── fato\_vendas

&#x20;├── fato\_entregas

&#x20;└── fato\_estoque

```



No Databricks, a arquitetura utiliza:



```text

Bronze

&#x20;  ↓

Silver

&#x20;  ↓

Gold

```



A camada Gold reproduz o modelo analítico principal.



\---



\# 3. Volumes de referência



| Entidade | Registros |

|---|---:|

| Clientes | 5.000 |

| Produtos | 500 |

| Pedidos | 50.000 |

| Itens de pedido | 109.982 |

| Pagamentos | 50.000 |

| Estoque | 12.000 |

| Entregas | 46.337 |

| Datas | 731 |



Período principal:



```text

01/01/2024 a 31/12/2025

```



\---



\# 4. Dados operacionais / RAW



\## 4.1 clientes



\*\*Granularidade:\*\* um registro por cliente.



\*\*Chave primária:\*\* `id\_cliente`



| Campo | Descrição |

|---|---|

| id\_cliente | Identificador único do cliente |

| nome\_cliente | Nome sintético do cliente |

| data\_cadastro | Data de cadastro |

| cep | CEP do cliente |

| cidade | Cidade |

| uf | Unidade federativa |

| segmento\_cliente | Segmentação comercial do cliente |

| status\_cliente | Situação cadastral |



\### Segmentos



```text

Novo

Recorrente

VIP

```



\### Status



```text

Ativo

Inativo

```



Os campos de localização são inicialmente vazios na fonte RAW e posteriormente enriquecidos por API.



\---



\## 4.2 produtos



\*\*Granularidade:\*\* um registro por produto.



\*\*Chave primária:\*\* `id\_produto`



| Campo | Descrição |

|---|---|

| id\_produto | Identificador único do produto |

| nome\_produto | Nome sintético |

| categoria | Categoria comercial |

| subcategoria | Subcategoria |

| marca | Marca |

| custo\_unitario | Custo unitário |

| preco\_unitario | Preço unitário |

| status\_produto | Situação do produto |



Categorias presentes:



```text

Beleza

Casa

Eletrônicos

Esporte

Informática

```



\---



\## 4.3 pedidos



\*\*Granularidade:\*\* um registro por pedido.



\*\*Chave primária:\*\* `id\_pedido`



\*\*Chave estrangeira:\*\* `id\_cliente`



| Campo | Descrição |

|---|---|

| id\_pedido | Identificador único do pedido |

| id\_cliente | Cliente responsável pelo pedido |

| data\_pedido | Data e horário do pedido |

| canal\_venda | Canal utilizado |

| status\_pedido | Situação do pedido |

| valor\_frete | Frete do pedido |

| desconto\_pedido | Desconto no nível do pedido |

| valor\_total | Valor final calculado do pedido |



\### Canais



```text

Site

App

Marketplace

```



\### Status



```text

Concluido

Cancelado

Em processamento

```



\---



\## 4.4 itens\_pedido



\*\*Granularidade:\*\* um item de produto dentro de um pedido.



\*\*Chave primária:\*\* `id\_item`



\*\*Chaves estrangeiras:\*\*



\- `id\_pedido`

\- `id\_produto`



| Campo | Descrição |

|---|---|

| id\_item | Identificador único do item |

| id\_pedido | Pedido relacionado |

| id\_produto | Produto relacionado |

| quantidade | Quantidade comprada |

| preco\_unitario | Preço aplicado ao item |

| desconto\_item | Desconto aplicado ao item |

| valor\_item | Valor final do item |



O projeto possui:



```text

109.982 itens

```



para:



```text

50.000 pedidos

```



\---



\## 4.5 pagamentos



\*\*Granularidade:\*\* um registro de pagamento por pedido no cenário sintético.



\*\*Chave primária:\*\* `id\_pagamento`



\*\*Chave estrangeira:\*\* `id\_pedido`



| Campo | Descrição |

|---|---|

| id\_pagamento | Identificador do pagamento |

| id\_pedido | Pedido relacionado |

| forma\_pagamento | Meio de pagamento |

| numero\_parcelas | Número de parcelas |

| valor\_pagamento | Valor registrado |

| status\_pagamento | Situação do pagamento |

| data\_pagamento | Data do pagamento |



\### Regra



Pagamentos aprovados possuem valor correspondente ao pedido.



Pagamentos pendentes ou cancelados possuem valor igual a zero no cenário simulado.



\---



\## 4.6 estoque



\*\*Granularidade:\*\* um produto por snapshot mensal.



\*\*Chave primária:\*\* `id\_estoque`



\*\*Chave estrangeira:\*\* `id\_produto`



| Campo | Descrição |

|---|---|

| id\_estoque | Identificador do registro |

| id\_produto | Produto |

| data\_referencia | Data do snapshot |

| quantidade\_disponivel | Estoque disponível |

| estoque\_minimo | Limite mínimo definido |

| quantidade\_reservada | Quantidade reservada |



O conjunto possui:



```text

500 produtos × 24 snapshots = 12.000 registros

```



Período:



```text

jan/2024 a dez/2025

```



\---



\## 4.7 entregas



\*\*Granularidade:\*\* uma entrega por pedido elegível para entrega.



\*\*Chave primária:\*\* `id\_entrega`



\*\*Chave estrangeira:\*\* `id\_pedido`



| Campo | Descrição |

|---|---|

| id\_entrega | Identificador da entrega |

| id\_pedido | Pedido relacionado |

| transportadora | Transportadora responsável |

| data\_envio | Data de envio |

| data\_prevista | Previsão de entrega |

| data\_entrega | Data efetiva |

| status\_entrega | Situação logística |

| tentativas\_entrega | Número de tentativas |

| custo\_logistico | Custo logístico sintético |



Transportadoras:



```text

EntregaMax

LogExpress

RapidGo

TransBrasil

```



\---



\# 5. Modelo analítico



\## 5.1 dim\_cliente



\*\*Granularidade:\*\* um cliente.



\*\*Chave:\*\* `id\_cliente`



Utilizada para análises por:



\- cliente;

\- segmento;

\- localização;

\- status cadastral.



Principais campos:



```text

id\_cliente

nome\_cliente

data\_cadastro

cep

cidade

uf

segmento\_cliente

status\_cliente

```



\---



\## 5.2 dim\_produto



\*\*Granularidade:\*\* um produto.



\*\*Chave:\*\* `id\_produto`



Permite análises por:



\- produto;

\- categoria;

\- subcategoria;

\- marca.



Principais campos:



```text

id\_produto

nome\_produto

categoria

subcategoria

marca

custo\_unitario

preco\_unitario

status\_produto

```



\---



\## 5.3 dim\_data



\*\*Granularidade:\*\* um dia.



\*\*Chave:\*\* `data`



Período:



```text

01/01/2024 a 31/12/2025

```



Total:



```text

731 dias

```



Principais atributos:



```text

data

ano

trimestre

mes

dia

nome\_mes

dia\_semana

nome\_dia\_semana

```



\---



\# 6. Tabelas fato



\## 6.1 fato\_vendas



\*\*Granularidade:\*\* um item por pedido.



Quantidade de registros:



```text

109.982

```



Principais chaves:



```text

id\_item

id\_pedido

id\_cliente

id\_produto

data

```



Principais atributos e medidas:



```text

canal\_venda

status\_pedido

quantidade

preco\_unitario

desconto\_item

valor\_item

```



\### Atenção semântica



`valor\_item` representa o valor dos itens.



Ele não deve ser automaticamente interpretado como faturamento contábil, pois descontos e frete no nível do pedido possuem tratamento separado.



Por esse motivo, os dashboards utilizam a expressão:



> Valor dos Itens Vendidos



\---



\## 6.2 fato\_entregas



\*\*Granularidade:\*\* uma entrega por pedido elegível.



Quantidade:



```text

46.337

```



Principais campos:



```text

id\_entrega

id\_pedido

data\_pedido

data\_envio

data\_prevista

data\_entrega

transportadora

status\_entrega

tentativas\_entrega

custo\_logistico

entrega\_atrasada

dias\_atraso

```



\### Regra de atraso



Uma entrega é considerada atrasada quando:



```sql

CAST(data\_entrega AS DATE) > CAST(data\_prevista AS DATE)

```



A comparação utiliza a data e não o timestamp completo para evitar falsos atrasos causados pelo horário.



\---



\## 6.3 fato\_estoque



\*\*Granularidade:\*\* um produto por snapshot mensal.



Quantidade:



```text

12.000

```



Principais campos:



```text

id\_estoque

id\_produto

data\_referencia

quantidade\_disponivel

estoque\_minimo

quantidade\_reservada

status\_estoque

```



\### Classificação



```text

ZERADO

ABAIXO DO MÍNIMO

NORMAL

```



Regras:



```text

quantidade\_disponivel = 0

→ ZERADO



quantidade\_disponivel > 0

e quantidade\_disponivel < estoque\_minimo

→ ABAIXO DO MÍNIMO



demais casos

→ NORMAL

```



As categorias são mutuamente exclusivas para evitar dupla contagem.



\---



\# 7. Databricks



\## Bronze



Mantém os dados próximos às fontes.



```text

workspace.bronze.clientes

workspace.bronze.produtos

workspace.bronze.pedidos

workspace.bronze.itens\_pedido

workspace.bronze.pagamentos

workspace.bronze.estoque

workspace.bronze.entregas

workspace.bronze.clientes\_enriquecidos

```



`clientes\_enriquecidos` funciona como artefato intermediário para transportar ao Databricks o resultado do enriquecimento Python/API.



\---



\## Silver



Camada de tratamento e qualidade.



```text

workspace.silver.clientes

workspace.silver.produtos

workspace.silver.pedidos

workspace.silver.itens\_pedido

workspace.silver.pagamentos

workspace.silver.estoque

workspace.silver.entregas

```



Operações aplicadas incluem:



\- casts de tipos;

\- limpeza de strings;

\- padronização;

\- tratamento de CEP;

\- verificações de nulos;

\- verificações de unicidade;

\- validação de regras de negócio.



\---



\## Gold



Camada de consumo analítico.



```text

workspace.gold.dim\_cliente

workspace.gold.dim\_produto

workspace.gold.dim\_data

workspace.gold.fato\_vendas

workspace.gold.fato\_entregas

workspace.gold.fato\_estoque

```



A Gold reproduz a lógica dimensional utilizada no ambiente PostgreSQL/Power BI.



\---



\# 8. Regras de qualidade importantes



\## Unicidade



As principais chaves devem permanecer únicas em suas respectivas granularidades.



Exemplos:



```text

id\_cliente

id\_produto

id\_pedido

id\_item

id\_pagamento

id\_entrega

id\_estoque

```



\---



\## Integridade referencial



São verificadas relações como:



```text

pedido → cliente

item → pedido

item → produto

pagamento → pedido

entrega → pedido

estoque → produto

```



\---



\## Tentativas de entrega



A regra de qualidade considera o status da entrega.



É inválido:



```text

status\_entrega = Entregue

e

tentativas\_entrega <= 0

```



Uma entrega em trânsito pode possuir zero tentativas sem representar erro.



\---



\## Estoque



Não são esperados:



```text

estoque disponível negativo

quantidade reservada maior que a disponível

```



\---



\# 9. Reconciliação



O projeto executa reconciliações entre diferentes etapas.



```text

Arquivos

&#x20;  ↓

RAW

&#x20;  ↓

Analytics

```



e:



```text

Bronze

&#x20;  ↓

Silver

&#x20;  ↓

Gold

```



Também são comparados indicadores produzidos em:



```text

PostgreSQL

Excel

Power BI

Databricks

```



Principais valores reconciliados:



```text

Clientes:              5.000

Produtos:                500

Pedidos:               50.000

Itens:                109.982

Entregas:              46.337

Estoque:                12.000



Pedidos concluídos:     43.937

Unidades vendidas:     137.583

Valor dos itens: R$ 64.251.128,33

Entregas atrasadas:     11.187

Taxa geral atraso:      24,96%

Estoque crítico:            75

```



\---



\# 10. Observações



\- Os dados são totalmente sintéticos.

\- As métricas não representam uma empresa real.

\- Não são feitas afirmações de impacto financeiro real.

\- As análises de canal, cancelamento, transportadora e atraso não demonstram causalidade.

\- A camada de pagamentos ainda não possui uma fato dedicada no modelo dimensional.

\- Microsoft Azure permanece como evolução futura condicionada à disponibilidade de uma assinatura.

