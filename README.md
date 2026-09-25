\# DataOps Analytics



Projeto de portfólio desenvolvido para demonstrar competências práticas em \*\*Análise de Dados, Business Intelligence e DataOps\*\*, utilizando Python, SQL, PostgreSQL, Docker e Git.



O projeto simula um ambiente de dados de uma operação de vendas, integrando informações de clientes, produtos, pedidos, pagamentos, estoque e entregas.



> \*\*Importante:\*\* todos os dados utilizados neste projeto são sintéticos e foram gerados exclusivamente para fins educacionais e de portfólio. Os resultados não representam uma empresa real.



\---



\## 🎯 Objetivo do projeto



Construir um pipeline analítico reproduzível capaz de:



\- gerar e organizar dados sintéticos;

\- realizar validações de qualidade;

\- carregar dados em PostgreSQL;

\- estruturar camadas RAW e Analytics;

\- construir um modelo dimensional;

\- realizar análises utilizando SQL;

\- reconciliar dados entre diferentes camadas;

\- identificar indicadores relevantes para vendas, logística e estoque;

\- documentar regras de negócio e decisões técnicas;

\- aplicar conceitos de DataOps, versionamento e reprodutibilidade.



\---



\## 🏗️ Arquitetura atual



```text

Arquivos CSV / Excel

&#x20;       │

&#x20;       ▼

Python / Pandas

&#x20;       │

&#x20;       ▼

PostgreSQL

&#x20;       │

&#x20;       ├── raw

&#x20;       │

&#x20;       └── analytics

&#x20;               │

&#x20;               ▼

&#x20;       Modelo Dimensional

&#x20;               │

&#x20;               ▼

&#x20;         SQL Analítico

&#x20;               │

&#x20;               ▼

&#x20;       Insights de Negócio

```



O PostgreSQL é executado em container Docker.



No ambiente local:



```text

Windows

&#x20;  │

&#x20;  └── localhost:5433

&#x20;         │

&#x20;         ▼

&#x20;      Docker

&#x20;         │

&#x20;         ▼

&#x20;PostgreSQL :5432

```



\---



\## 🛠️ Tecnologias



\### Implementadas



\- Python

\- Pandas

\- PostgreSQL 17

\- SQL

\- Docker

\- Docker Compose

\- Git

\- GitHub

\- SQLAlchemy

\- Psycopg

\- OpenPyXL

\- python-dotenv



\### Próximas etapas



\- Excel analítico

\- Power BI

\- API pública

\- Databricks

\- Microsoft Azure

\- documentação final de métricas e modelo



\---



\## 📊 Dados do projeto



O cenário possui dados relacionados a:



\- clientes;

\- produtos;

\- pedidos;

\- itens de pedido;

\- pagamentos;

\- estoque;

\- entregas.



\### Volumes atuais



| Fonte | Registros |

|---|---:|

| Clientes | 5.000 |

| Produtos | 500 |

| Pedidos | 50.000 |

| Itens de pedido | 109.982 |

| Pagamentos | 50.000 |

| Estoque | 12.000 |

| Entregas | 46.337 |



Período dos pedidos:



\*\*01/01/2024 a 31/12/2025\*\*



\---



\## 🗄️ Estrutura do banco



Foram criados dois schemas principais:



\### `raw`



Responsável por armazenar os dados em estrutura próxima às fontes.



Tabelas:



```text

raw.clientes

raw.produtos

raw.pedidos

raw.itens\_pedido

raw.pagamentos

raw.estoque

raw.entregas

```



\### `analytics`



Camada preparada para análise e consumo analítico.



Tabelas:



```text

analytics.dim\_cliente

analytics.dim\_produto

analytics.dim\_data

analytics.fato\_vendas

analytics.fato\_entregas

analytics.fato\_estoque

```



\---



\## ⭐ Modelo dimensional



O modelo Analytics utiliza conceitos de modelagem dimensional.



\### Dimensões



\*\*dim\_cliente\*\*



Informações cadastrais e segmentação dos clientes.



\*\*dim\_produto\*\*



Informações de produtos, categorias, subcategorias e marcas.



\*\*dim\_data\*\*



Calendário analítico utilizado para análises temporais.



\### Tabelas fato



\*\*fato\_vendas\*\*



Granularidade:



> um item por pedido.



\*\*fato\_entregas\*\*



Granularidade:



> uma entrega por pedido elegível para entrega.



\*\*fato\_estoque\*\*



Granularidade:



> um produto por snapshot mensal.



\---



\## 🔎 Qualidade de dados



O projeto possui validações para:



\- chaves primárias duplicadas;

\- valores nulos;

\- integridade entre chaves estrangeiras;

\- pedidos sem itens;

\- pagamentos divergentes;

\- entregas associadas a pedidos cancelados;

\- inconsistências de status;

\- estoque negativo;

\- quantidade reservada maior que disponível;

\- reconciliação entre RAW e Analytics.



\---



\## 🧠 Regra de atraso de entrega



Durante a validação foi identificada uma diferença importante na definição da métrica de atraso.



Uma comparação direta:



```sql

data\_entrega > data\_prevista

```



classificava entregas realizadas no mesmo dia como atrasadas porque `data\_prevista` estava armazenada à meia-noite enquanto `data\_entrega` possuía horário.



A regra foi corrigida para comparar as datas:



```sql

data\_entrega::date > data\_prevista::date

```



Com a regra corrigida, foram identificadas:



\*\*11.187 entregas atrasadas.\*\*



Esse ajuste demonstra a importância da definição de regras de negócio antes da interpretação dos indicadores.



\---



\## 💻 SQL aplicado



O projeto contém consultas utilizando:



\- `INNER JOIN`;

\- `LEFT JOIN`;

\- `GROUP BY`;

\- `SUM`;

\- `AVG`;

\- `COUNT`;

\- `FILTER`;

\- CTEs;

\- subconsultas;

\- funções de janela;

\- `LAG`;

\- `RANK`;

\- `SUM() OVER()`.



As consultas estão documentadas em:



```text

sql/07\_analises\_negocio.sql

sql/08\_insights\_portfolio.sql

```



\---



\## 📈 Análises realizadas



Entre as análises desenvolvidas estão:



\- participação das vendas por canal;

\- evolução mensal das vendas;

\- crescimento mês contra mês;

\- produtos mais vendidos;

\- ranking de produtos por categoria;

\- clientes com maior volume de compras;

\- desempenho das transportadoras;

\- atrasos por canal;

\- cancelamentos por canal;

\- estoque crítico;

\- produtos de alta demanda com estoque abaixo do mínimo.



\---



\# 🔍 Principais insights



\## 1. Canais de venda



Considerando o valor dos itens de pedidos concluídos:



| Canal | Participação | Cancelamento | Atraso |

|---|---:|---:|---:|

| Site | 44,94% | 7,17% | 24,50% |

| App | 35,03% | 7,44% | 25,14% |

| Marketplace | 20,02% | 7,47% | 25,71% |



No cenário sintético, o \*\*Site concentra a maior participação no valor dos itens vendidos\*\* e apresenta taxas ligeiramente menores de cancelamento e atraso.



As diferenças operacionais entre os canais são pequenas e não permitem atribuir causalidade.



\---



\## 2. Estoque por categoria



No snapshot de \*\*31/12/2025\*\*, a categoria Eletrônicos apresentou:



\- 97 produtos;

\- 20 abaixo do estoque mínimo;

\- 12 com estoque zerado;

\- 20,62% dos produtos abaixo do mínimo.



Entre as categorias analisadas, foi a maior proporção de produtos abaixo do estoque mínimo nesse snapshot.



Uma possível ação no cenário simulado seria priorizar o acompanhamento de reposição dessa categoria.



\---



\## 3. Alta demanda × estoque crítico



A análise combinando demanda e posição de estoque identificou \*\*9 produtos com posição de demanda até 50\*\* que terminaram o período abaixo do estoque mínimo.



Um exemplo é:



```text

Produto: Futebol SportMax 0255

Ranking de demanda: 1

Unidades vendidas: 344

Estoque disponível: 22

Estoque mínimo: 25

```



Também foram encontrados produtos de alta demanda com estoque zerado.



Essa análise demonstra como vendas e estoque podem ser combinados para apoiar uma priorização simulada de reposição.



\---



\## 🐍 ETL com Python



A camada Python utiliza:



\- Pandas;

\- SQLAlchemy;

\- Psycopg;

\- OpenPyXL;

\- python-dotenv.



Os scripts atuais realizam:



\- leitura de Excel;

\- validação de estrutura;

\- verificação de nulos;

\- verificação de duplicidades;

\- validação de regras de negócio;

\- validação de chaves;

\- carga no PostgreSQL;

\- reconciliação pós-carga.



Scripts:



```text

src/etl/carregar\_produtos.py

src/etl/carregar\_estoque.py

```



\---



\## 🔐 Segurança das configurações



As credenciais locais não são armazenadas diretamente nos scripts Python ou no `compose.yaml`.



As configurações são carregadas por variáveis de ambiente através de:



```text

.env

```



O arquivo `.env` está incluído no `.gitignore` e não deve ser versionado.



Exemplo de estrutura necessária:



```env

POSTGRES\_DB=seu\_banco

POSTGRES\_USER=seu\_usuario

POSTGRES\_PASSWORD=sua\_senha

POSTGRES\_HOST=localhost

POSTGRES\_PORT=5433

```



\---



\## 🐳 Docker



O PostgreSQL é executado utilizando Docker Compose.



Para iniciar o ambiente:



```bash

docker compose up -d

```



Verificar os containers:



```bash

docker compose ps

```



Encerrar:



```bash

docker compose down

```



O volume do PostgreSQL permite persistir os dados entre reinicializações do container.



\---



\## 📁 Estrutura do repositório



```text

DataOps-Analytics/

│

├── data/

│   └── raw/

│

├── docs/

│   ├── diagramas/

│   ├── 01\_escopo\_projeto.md

│   ├── 02\_arquitetura\_tecnica.md

│   ├── 03\_fontes\_dados.md

│   └── 04\_configuracao\_ambiente.md

│

├── sql/

│   ├── 01\_criar\_schema.sql

│   ├── 02\_criar\_tabelas\_raw.sql

│   ├── 03\_validacao\_raw.sql

│   ├── 04\_criar\_modelo\_analytics.sql

│   ├── 05\_carga\_modelo\_analytics.sql

│   ├── 06\_validacao\_analytics.sql

│   ├── 07\_analises\_negocio.sql

│   └── 08\_insights\_portfolio.sql

│

├── src/

│   ├── etl/

│   └── generation/

│

├── .gitignore

├── compose.yaml

├── requirements.txt

└── README.md

```



\---



\## ▶️ Como executar



\### 1. Clonar o repositório



```bash

git clone <URL\_DO\_REPOSITORIO>

```



\### 2. Criar ambiente virtual



Windows:



```bash

python -m venv .venv

.venv\\Scripts\\activate

```



\### 3. Instalar dependências



```bash

pip install -r requirements.txt

```



\### 4. Criar `.env`



Utilize a estrutura apresentada na seção de segurança e defina suas próprias credenciais locais.



\### 5. Iniciar PostgreSQL



```bash

docker compose up -d

```



\### 6. Executar os scripts SQL



Os scripts da pasta `sql/` estão numerados de acordo com a sequência lógica de execução.



\---



\# 🚧 Roadmap



O projeto continuará sendo expandido com:



\- \[x] geração de dados sintéticos;

\- \[x] PostgreSQL;

\- \[x] Docker;

\- \[x] modelagem RAW;

\- \[x] modelo dimensional Analytics;

\- \[x] validações de qualidade;

\- \[x] reconciliação RAW × Analytics;

\- \[x] SQL analítico;

\- \[x] CTEs e funções de janela;

\- \[x] ETL Python/Pandas inicial;

\- \[x] Git e GitHub;

\- \[ ] ETL com API pública;

\- \[ ] logging e tratamento estruturado de erros;

\- \[ ] melhoria da estratégia de cargas idempotentes;

\- \[ ] análise e reconciliação em Excel;

\- \[ ] dashboard no Power BI;

\- \[ ] dicionário de dados e métricas;

\- \[ ] Databricks;

\- \[ ] Microsoft Azure;

\- \[ ] documentação final da arquitetura.



\---



\## 📌 Limitações atuais



\- Os dados são totalmente sintéticos.

\- Não há impacto financeiro real associado aos insights.

\- A camada de pagamentos ainda não possui uma fato específica no modelo Analytics.

\- O ETL Python ainda será expandido para incluir API pública e logging.

\- As cargas Python atuais ainda serão aprimoradas para uma estratégia de reexecução mais robusta.

\- Power BI, Azure e Databricks ainda fazem parte do roadmap.

\- A análise não pretende demonstrar causalidade entre canal, cancelamento e atraso.



\---



\## 👤 Autor



\*\*Marcos Felipe\*\*



Projeto desenvolvido como portfólio prático para estudos e oportunidades nas áreas de \*\*Dados, BI e DataOps\*\*.

