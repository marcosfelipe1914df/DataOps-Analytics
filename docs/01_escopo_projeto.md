# DataOps Analytics — Escopo do Projeto

## 1. Visão Geral

O DataOps Analytics é um projeto de portfólio end-to-end de Dados e Business Intelligence, desenvolvido a partir de um cenário empresarial fictício.

O projeto simula uma empresa de comércio eletrônico chamada DataOps Commerce, que possui informações relacionadas a vendas, clientes, produtos, estoque e entregas provenientes de diferentes fontes de dados.

O objetivo é construir uma solução capaz de integrar, tratar, validar, armazenar e analisar esses dados, disponibilizando indicadores para apoio à tomada de decisão.

---

## 2. Problema de Negócio

A DataOps Commerce possui dados de vendas, clientes, produtos, estoque e entregas provenientes de diferentes fontes.

Atualmente, essas informações encontram-se distribuídas entre arquivos CSV/Excel, banco de dados e fontes externas, dificultando a criação de uma visão integrada da operação.

Essa fragmentação dificulta a análise consistente de indicadores relacionados a vendas, comportamento dos clientes, desempenho dos produtos, disponibilidade de estoque e eficiência logística.

O projeto DataOps Analytics busca construir uma solução de dados end-to-end capaz de integrar, tratar, validar e organizar essas informações para disponibilizar indicadores confiáveis de vendas e operações.

---

## 3. Objetivo Geral

Desenvolver uma solução de Dados e BI que cubra o fluxo desde a ingestão dos dados até sua disponibilização para análise, aplicando práticas de engenharia, qualidade, modelagem e visualização de dados.

---

## 4. Objetivos Analíticos

A solução deverá permitir investigar perguntas como:

- Como a receita e a quantidade de pedidos evoluem ao longo do tempo?
- Quais produtos e categorias concentram maior volume de vendas?
- Qual é o ticket médio dos pedidos?
- Quais canais concentram mais pedidos?
- Quais canais apresentam maior ocorrência de cancelamentos?
- Quais clientes apresentam maior recorrência de compras?
- Quais produtos apresentam maior movimentação de estoque?
- Existem produtos com risco de indisponibilidade?
- Qual é o tempo médio de entrega?
- Onde estão concentrados os atrasos nas entregas?
- Existem relações relevantes entre vendas, estoque e desempenho logístico?

---

## 5. Fontes de Dados

O projeto deverá integrar diferentes tipos de fontes, incluindo:

- Arquivos CSV;
- Arquivos Excel;
- API pública;
- PostgreSQL.

A origem, estrutura e quantidade real de registros de cada fonte serão documentadas conforme os dados forem implementados.

Dados sintéticos ou fictícios utilizados no projeto serão identificados explicitamente na documentação.

---

## 6. Tecnologias

### Python e Pandas
Utilizados para ingestão, limpeza, transformação, validação e integração dos dados.

### PostgreSQL
Utilizado para armazenamento relacional, consultas SQL, validações e análises.

### SQL
Utilizado para consultas envolvendo JOINs, agregações, CTEs, subconsultas e funções de janela, conforme forem implementadas no projeto.

### Docker
Utilizado para criar um ambiente local reproduzível e executar componentes da solução em containers.

### Microsoft Azure
Utilizado para disponibilizar componentes da arquitetura de dados em ambiente de nuvem.

### Databricks
Utilizado para processamento e transformação de dados com SQL e PySpark, adotando a organização em camadas Bronze, Silver e Gold.

### Power BI
Utilizado para modelagem dimensional, criação de medidas DAX, indicadores e dashboards.

### Excel
Utilizado para análises complementares e reconciliação dos resultados, incluindo tabelas dinâmicas, PROCX/PROCV, SOMASES, fórmulas lógicas e tratamento de erros.

### Git e GitHub
Utilizados para versionamento do código, histórico de alterações e documentação do projeto.

### Jira Software
Utilizado para gerenciamento do desenvolvimento por meio de épicos, tarefas, backlog, sprints, bugs e critérios de aceite.

---

## 7. Qualidade de Dados

O projeto deverá implementar verificações relacionadas a:

- Unicidade de identificadores;
- Completude de campos obrigatórios;
- Integridade entre tabelas;
- Consistência de valores;
- Validade de datas;
- Tratamento de valores nulos;
- Identificação e tratamento de duplicidades;
- Validação de regras de negócio.

Também será realizada reconciliação entre resultados obtidos em SQL, Excel e Power BI quando aplicável.

---

## 8. Arquitetura de Dados

O processamento analítico deverá utilizar três camadas principais:

### Bronze
Dados brutos provenientes das fontes, preservando o conteúdo original sempre que possível.

### Silver
Dados tratados, tipados, padronizados, deduplicados e submetidos às regras de qualidade.

### Gold
Dados preparados para consumo analítico, indicadores e modelo dimensional.

---

## 9. Escopo Analítico

O projeto contemplará cinco áreas principais:

1. Vendas;
2. Clientes;
3. Produtos;
4. Estoque;
5. Logística e entregas.

---

## 10. Limitações

Este projeto possui finalidade educacional e de portfólio.

A empresa DataOps Commerce é fictícia.

Quando forem utilizados dados sintéticos, os resultados representarão exclusivamente o conjunto de dados analisado e não deverão ser interpretados como resultados de uma empresa real.

O projeto não afirmará aumento de vendas, redução de custos, redução de atrasos ou qualquer outro impacto empresarial que não tenha sido efetivamente implementado e medido.

As recomendações analíticas serão baseadas somente nos resultados observados nos dados utilizados.

---

## 11. Critérios de Sucesso

O projeto será considerado concluído quando possuir:

- Pipeline de ingestão reproduzível;
- Integração de CSV, Excel e API;
- Banco PostgreSQL estruturado;
- Ambiente utilizando Docker;
- Processamento utilizando Databricks;
- Componentes implementados no Microsoft Azure;
- Camadas Bronze, Silver e Gold;
- Modelo dimensional documentado;
- Consultas SQL documentadas;
- Regras de qualidade de dados;
- Reconciliação de métricas;
- Medidas DAX documentadas;
- Dashboard Power BI;
- Análises e insights sustentados pelos dados;
- Documentação técnica completa;
- Código versionado no GitHub;
- Histórico de desenvolvimento organizado no Jira Software.

---

## 12. Controle de Alterações

As alterações relevantes no escopo, arquitetura, regras de negócio e métricas deverão ser registradas no Git/GitHub e, quando relacionadas ao desenvolvimento, vinculadas aos respectivos tickets do Jira.