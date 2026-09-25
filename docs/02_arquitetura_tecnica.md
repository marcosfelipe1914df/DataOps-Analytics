# DataOps Analytics — Arquitetura Técnica

## 1. Objetivo

Este documento descreve a arquitetura técnica planejada para o projeto DataOps Analytics, desde a obtenção dos dados até sua disponibilização para análise no Power BI.

A arquitetura foi definida para permitir a prática de ingestão, transformação, armazenamento, qualidade, modelagem e visualização de dados utilizando ferramentas presentes em ambientes de Dados e Business Intelligence.

---

## 2. Visão Geral do Fluxo

O fluxo principal será:

CSV / Excel / API Pública
→ Python e Pandas
→ Azure Storage
→ Azure Databricks
→ Bronze
→ Silver
→ Gold
→ Modelo Dimensional
→ Power BI

Em paralelo, Docker e PostgreSQL serão utilizados como ambiente relacional local para armazenamento, desenvolvimento de consultas SQL, testes e validações.

Git/GitHub serão utilizados para controle de versão e documentação.

Jira Software será utilizado para gerenciamento das atividades do projeto.

---

## 3. Fontes de Dados

O projeto utilizará diferentes tipos de fontes:

- Arquivos CSV;
- Arquivos Excel;
- API pública.

Os arquivos representarão informações relacionadas às áreas de vendas, clientes, produtos, estoque e logística.

A API pública será definida posteriormente e deverá possuir uma finalidade analítica clara dentro do projeto.

---

## 4. Python e Pandas

Python e Pandas serão utilizados no processo inicial de ingestão e tratamento.

Entre as atividades previstas estão:

- Leitura de arquivos CSV;
- Leitura de arquivos Excel;
- Consumo de API pública;
- Conversão de tipos;
- Tratamento de valores nulos;
- Identificação de registros duplicados;
- Validação de chaves;
- Aplicação de regras de qualidade;
- Registro de erros;
- Preparação dos dados para carga.

O pipeline deverá ser desenvolvido de forma que possa ser executado novamente sem exigir alterações manuais no código sempre que possível.

---

## 5. Docker

Docker será utilizado para criar um ambiente local reproduzível.

Inicialmente, o PostgreSQL será executado em container.

A configuração do ambiente deverá ser documentada e versionada no GitHub por meio dos arquivos necessários para reprodução do ambiente.

---

## 6. PostgreSQL

PostgreSQL será utilizado como ambiente relacional local para:

- Criação das estruturas de banco;
- Carga de dados;
- Consultas analíticas;
- Testes de qualidade;
- Validação de relacionamentos;
- Reconciliação de métricas.

As consultas SQL do projeto deverão demonstrar, quando aplicável:

- JOINs;
- Agregações;
- CTEs;
- Subconsultas;
- CASE;
- Funções de janela.

---

## 7. Microsoft Azure

Microsoft Azure será utilizado como plataforma de nuvem do projeto.

A arquitetura prevê armazenamento de dados em serviço de armazenamento do Azure e integração com o ambiente Databricks.

Somente serviços efetivamente implementados serão apresentados posteriormente como experiência prática do projeto.

---

## 8. Azure Databricks

Databricks será utilizado para processamento e transformação dos dados utilizando PySpark e Spark SQL.

O processamento será organizado utilizando as camadas Bronze, Silver e Gold.

### Bronze

A camada Bronze armazenará os dados brutos provenientes das fontes, preservando sua estrutura original sempre que possível.

### Silver

A camada Silver conterá dados tratados e validados.

Entre os processos previstos estão:

- Padronização;
- Conversão de tipos;
- Tratamento de valores nulos;
- Deduplicação;
- Validação de chaves;
- Aplicação de regras de qualidade.

### Gold

A camada Gold disponibilizará dados preparados para consumo analítico.

Nessa camada serão construídas estruturas adequadas para indicadores, análises e modelagem dimensional.

---

## 9. Modelo Dimensional

Os dados destinados ao consumo analítico serão organizados utilizando modelagem dimensional.

A solução deverá possuir tabelas fato e dimensão relacionadas às áreas de:

- Vendas;
- Clientes;
- Produtos;
- Datas;
- Canais;
- Estoque;
- Logística.

A estrutura definitiva será definida após a análise das fontes de dados.

---

## 10. Power BI

Power BI será utilizado como camada de visualização e análise.

As principais atividades previstas incluem:

- Conexão aos dados analíticos;
- Modelagem;
- Criação de relacionamentos;
- Desenvolvimento de medidas DAX;
- Criação de indicadores;
- Desenvolvimento de dashboards;
- Validação das métricas apresentadas.

---

## 11. Excel

Excel será utilizado tanto como fonte quanto como ferramenta complementar de validação e análise.

O projeto deverá demonstrar:

- Tabelas dinâmicas;
- PROCX e/ou PROCV;
- SOMASES;
- Fórmulas lógicas;
- Tratamento de erros;
- Reconciliação de métricas.

Quando aplicável, métricas calculadas em Excel serão comparadas aos resultados obtidos em SQL e Power BI.

---

## 12. Qualidade e Reconciliação

O projeto implementará verificações de qualidade relacionadas a:

- Unicidade;
- Completude;
- Consistência;
- Integridade referencial;
- Duplicidades;
- Validade de valores;
- Regras de negócio.

Também será realizada reconciliação de indicadores entre diferentes componentes da solução.

Exemplo:

SQL
↔ Excel
↔ Power BI

Diferenças identificadas deverão ser investigadas e documentadas.

---

## 13. Git e GitHub

Git será utilizado para controle de versão.

GitHub será utilizado para armazenar:

- Código Python;
- Consultas SQL;
- Configurações Docker;
- Notebooks;
- Documentação;
- Evidências relevantes;
- Histórico de alterações.

---

## 14. Jira Software

Jira Software será utilizado para gerenciamento do projeto.

O desenvolvimento será organizado por meio de:

- Épicos;
- Backlog;
- Tarefas;
- Critérios de aceite;
- Sprints;
- Bugs;
- Status de execução.

Os tickets deverão representar atividades realmente executadas durante o desenvolvimento.

---

## 15. Arquitetura Resumida

Fluxo principal:

CSV / Excel / API
        |
        v
Python / Pandas
        |
        v
Azure Storage
        |
        v
Azure Databricks
        |
        v
Bronze
        |
        v
Silver
        |
        v
Gold
        |
        v
Modelo Dimensional
        |
        v
Power BI

Ambiente local:

Docker
   |
   v
PostgreSQL
   |
   v
SQL / Qualidade / Validação

Governança do desenvolvimento:

Jira → Planejamento e acompanhamento

Git/GitHub → Código, versionamento e documentação