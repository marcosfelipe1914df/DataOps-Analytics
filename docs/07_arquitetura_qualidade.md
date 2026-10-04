\# Arquitetura e Qualidade de Dados — DataOps Analytics



\## 1. Objetivo



Este documento registra as principais decisões técnicas, regras de qualidade, validações e correções realizadas durante o desenvolvimento do projeto \*\*DataOps Analytics\*\*.



O objetivo não é apenas apresentar as tecnologias utilizadas, mas demonstrar como problemas de qualidade e consistência foram identificados, analisados e tratados durante o pipeline.



> Todos os dados utilizados são sintéticos e destinados exclusivamente a estudo e portfólio.



\---



\# 2. Visão geral da arquitetura



O projeto utiliza duas implementações complementares.



\## Ambiente local



```text

Arquivos CSV / Excel

&#x20;       ↓

Python / Pandas

&#x20;       ↓

Validação e enriquecimento

&#x20;       ↓

PostgreSQL em Docker

&#x20;       ↓

RAW

&#x20;       ↓

Analytics

&#x20;       ↓

SQL / Excel / Power BI

```



\## Databricks



```text

Arquivos

&#x20;  ↓

Bronze

&#x20;  ↓

Silver

&#x20;  ↓

Gold

&#x20;  ↓

SQL Analytics

```



A arquitetura permite demonstrar conceitos de:



\- ingestão;

\- transformação;

\- modelagem dimensional;

\- qualidade de dados;

\- reconciliação;

\- análise;

\- visualização;

\- versionamento.



\---



\# 3. Tecnologias



Principais tecnologias utilizadas:



```text

Python

Pandas

SQL

PostgreSQL

Docker

Excel

Power BI

Databricks

Git

GitHub

```



Também foram utilizados:



```text

SQLAlchemy

psycopg

python-dotenv

requests

openpyxl

```



\---



\# 4. Camadas PostgreSQL



O PostgreSQL utiliza dois schemas principais.



\## RAW



Responsável por armazenar dados próximos às fontes.



```text

raw.clientes

raw.produtos

raw.pedidos

raw.itens\_pedido

raw.pagamentos

raw.estoque

raw.entregas

```



\## Analytics



Responsável pelo modelo dimensional utilizado nas análises.



```text

analytics.dim\_cliente

analytics.dim\_produto

analytics.dim\_data

analytics.fato\_vendas

analytics.fato\_entregas

analytics.fato\_estoque

```



\---



\# 5. Arquitetura Medallion no Databricks



O Databricks utiliza três camadas.



\## Bronze



Recebe os dados com mínima transformação.



Objetivos:



\- preservar os dados de origem;

\- permitir rastreabilidade;

\- criar uma camada inicial para processamento.



\## Silver



Responsável por:



\- conversão de tipos;

\- padronização;

\- limpeza;

\- tratamento de strings;

\- validações;

\- aplicação de regras de qualidade.



\## Gold



Responsável pelo consumo analítico.



Modelo:



```text

dim\_cliente

dim\_produto

dim\_data

fato\_vendas

fato\_entregas

fato\_estoque

```



\---



\# 6. Princípios de qualidade



As validações foram organizadas em quatro grupos principais.



\## Unicidade



Verificação de duplicidade em chaves como:



```text

id\_cliente

id\_produto

id\_pedido

id\_item

id\_pagamento

id\_entrega

id\_estoque

```



\## Completude



Verificação de campos obrigatórios e valores nulos.



\## Integridade referencial



Exemplos:



```text

pedido → cliente

item → pedido

item → produto

pagamento → pedido

entrega → pedido

estoque → produto

```



\## Consistência



Validação de regras como:



```text

preço > custo

estoque >= 0

quantidade reservada <= quantidade disponível

datas coerentes

status compatíveis

```



\---



\# 7. Caso de qualidade — cálculo do valor dos pedidos



Durante a geração dos pedidos, o valor total foi reconciliado com os itens.



A regra utilizada foi:



```text

subtotal dos itens

\- desconto do pedido

\+ frete

= valor total

```



Durante a validação foram encontrados dois pedidos em que o desconto original poderia consumir todo o subtotal.



Exemplos identificados:



```text

Pedido 23863

Subtotal: R$ 23,50

Desconto original: R$ 25,00



Pedido 42018

Subtotal: R$ 24,66

Desconto original: R$ 25,00

```



Isso poderia gerar pedidos com valor total igual a zero.



\## Correção



Foi definida a regra:



```text

desconto máximo do pedido = 50% do subtotal

```



Após a correção:



```text

50.000 pedidos reconciliados

0 pedidos com valor total <= 0

```



\### Aprendizado



A validação mostrou que dados sintéticos também precisam respeitar regras de negócio para permanecerem analiticamente coerentes.



\---



\# 8. Caso de qualidade — definição de atraso



Durante a análise das entregas, uma primeira comparação utilizou diretamente timestamps.



Essa abordagem classificou:



```text

35.934 entregas

```



como atrasadas.



O resultado foi investigado e verificou-se que diferenças de horário estavam sendo interpretadas como atraso, mesmo quando a entrega ocorreu no mesmo dia previsto.



\## Regra corrigida



Foi adotada a comparação no nível da data:



```sql

CAST(data\_entrega AS DATE) >

CAST(data\_prevista AS DATE)

```



Após a correção:



```text

11.187 entregas atrasadas

```



entre:



```text

44.814 entregas concluídas

```



Taxa:



```text

24,96%

```



\### Aprendizado



Uma regra tecnicamente válida pode produzir uma métrica incorreta quando não representa adequadamente o conceito de negócio.



\---



\# 9. Caso de qualidade — tentativas de entrega



Uma validação inicial tratava registros com:



```text

tentativas\_entrega = 0

```



como possíveis erros.



Foram encontrados:



```text

1.523 registros

```



nessa situação.



Ao investigar os dados, verificou-se que esses registros correspondiam a entregas ainda:



```text

Em trânsito

```



Portanto, zero tentativas era um estado válido.



\## Regra refinada



A validação passou a considerar inválido somente:



```text

status\_entrega = Entregue

AND

tentativas\_entrega <= 0

```



\### Aprendizado



Regras de qualidade devem considerar o contexto e o estado do processo, e não apenas limites numéricos isolados.



\---



\# 10. Caso de qualidade — estoque crítico



Uma classificação simples:



```text

quantidade\_disponivel < estoque\_minimo

```



inclui também produtos com estoque igual a zero.



Isso pode gerar dupla contagem quando também existe uma categoria específica para produtos zerados.



\## Classificação adotada



\### ZERADO



```text

quantidade\_disponivel = 0

```



\### ABAIXO DO MÍNIMO



```text

quantidade\_disponivel > 0

AND

quantidade\_disponivel < estoque\_minimo

```



\### NORMAL



Demais casos.



No último snapshot:



```text

ZERADO: 44

ABAIXO DO MÍNIMO: 31

CRÍTICOS: 75

```



As categorias são mutuamente exclusivas.



\### Aprendizado



A definição das categorias precisa impedir sobreposição para evitar dupla contagem nos indicadores.



\---



\# 11. Enriquecimento de clientes via API



Os dados iniciais de clientes possuíam os campos:



```text

cep

cidade

uf

```



sem preenchimento.



Foi criado um pipeline Python utilizando a BrasilAPI para enriquecimento geográfico.



Fluxo:



```text

clientes.csv

&#x20;    ↓

Python

&#x20;    ↓

Consulta de CEP

&#x20;    ↓

Cache local

&#x20;    ↓

clientes\_enriquecidos.csv

&#x20;    ↓

PostgreSQL

```



Foram utilizados CEPs de referência válidos para diferentes cidades e UFs.



Resultado:



```text

5.000 clientes enriquecidos

5.000 com CEP

5.000 com cidade

5.000 com UF

10 cidades

10 UFs

```



\---



\# 12. Cache da API



Para evitar consultas externas repetidas, foi criado:



```text

data/external/cache\_ceps.json

```



Antes de consultar a API, o pipeline verifica se o CEP já está presente no cache.



Fluxo:



```text

CEP

&#x20;↓

Existe no cache?

&#x20;├── Sim → utiliza cache

&#x20;└── Não → consulta API → salva cache

```



Benefícios:



\- menor número de requisições;

\- execução mais rápida;

\- menor dependência da disponibilidade da API;

\- maior reprodutibilidade.



O arquivo de cache não é versionado no Git.



\---



\# 13. Logging



Os pipelines Python registram informações de execução em arquivos de log.



Exemplo:



```text

logs/enriquecimento\_clientes.log

```



Os logs permitem acompanhar:



\- início da execução;

\- quantidade de registros;

\- consultas à API;

\- utilização do cache;

\- erros;

\- conclusão do processamento.



A pasta `logs/` não é versionada.



\---



\# 14. Idempotência



Um dos objetivos foi permitir reexecuções sem produzir alterações desnecessárias.



Na atualização da dimensão de clientes foi utilizada uma lógica equivalente a:



```sql

IS DISTINCT FROM

```



para atualizar apenas registros que realmente possuam diferenças.



Primeira execução:



```text

UPDATE 5000

```



Segunda execução, sem alterações na fonte:



```text

UPDATE 0

```



Isso demonstra comportamento idempotente nessa etapa do pipeline.



\---



\# 15. Reconciliação RAW → Analytics



Após a carga do modelo dimensional, foram realizadas comparações entre as camadas.



Principais volumes:



```text

Clientes:        5.000

Produtos:          500

Datas:             731

Vendas:        109.982

Entregas:       46.337

Estoque:        12.000

```



A reconciliação busca garantir que a transformação não introduza perdas ou duplicidades inesperadas.



\---



\# 16. Reconciliação Databricks



O mesmo princípio foi aplicado entre:



```text

Bronze

&#x20; ↓

Silver

&#x20; ↓

Gold

```



Principais volumes Gold:



```text

dim\_cliente:      5.000

dim\_produto:        500

dim\_data:           731

fato\_vendas:    109.982

fato\_entregas:   46.337

fato\_estoque:    12.000

```



Também foram validadas:



\- chaves;

\- nulos;

\- granularidade;

\- regras de negócio;

\- indicadores.



\---



\# 17. Reconciliação entre ferramentas



Indicadores principais foram comparados entre:



```text

PostgreSQL

Excel

Power BI

Databricks

```



Valores de referência:



```text

Pedidos:                   50.000

Pedidos concluídos:        43.937

Valor dos itens: R$ 64.251.128,33

Unidades vendidas:        137.583

Entregas atrasadas:        11.187

Taxa de atraso:            24,96%

Produtos críticos:             75

```



A reconciliação reduz o risco de apresentar KPIs diferentes dependendo da ferramenta utilizada.



\---



\# 18. Controle de versão



O código e a documentação são versionados utilizando:



```text

Git

GitHub

```



O repositório contém:



\- scripts Python;

\- scripts SQL;

\- notebooks Databricks;

\- documentação;

\- estrutura do projeto;

\- arquivos necessários para reprodução.



Arquivos locais ou sensíveis são ignorados.



Exemplos:



```text

.env

.venv/

logs/

\_\_pycache\_\_/

data/external/cache\_ceps.json

```



\---



\# 19. Segredos e configuração



As credenciais do PostgreSQL não são inseridas diretamente nos scripts.



São carregadas a partir do arquivo:



```text

.env

```



Esse arquivo é excluído do versionamento por meio do:



```text

.gitignore

```



Isso separa configuração de código e reduz o risco de exposição acidental de credenciais.



\---



\# 20. Docker e PostgreSQL



O PostgreSQL utilizado pelo projeto é executado em container Docker.



Isso permite:



\- ambiente reproduzível;

\- isolamento;

\- configuração padronizada;

\- facilidade para iniciar e encerrar o banco.



A porta utilizada no host é:



```text

5433

```



A alteração foi necessária porque uma instalação local do PostgreSQL já utilizava a porta padrão:



```text

5432

```



\---



\# 21. Decisões de modelagem



O modelo analítico utiliza abordagem dimensional.



Dimensões:



```text

dim\_cliente

dim\_produto

dim\_data

```



Fatos:



```text

fato\_vendas

fato\_entregas

fato\_estoque

```



Cada fato possui uma granularidade diferente.



```text

fato\_vendas

→ item de pedido



fato\_entregas

→ entrega



fato\_estoque

→ produto por snapshot mensal

```



Conhecer essa granularidade é essencial para evitar contagens duplicadas.



\---



\# 22. Decisão semântica — valor dos itens



A fato de vendas possui granularidade de item.



A métrica:



```text

SUM(valor\_item)

```



representa o valor dos itens vendidos.



Ela não deve ser apresentada automaticamente como faturamento contábil porque:



\- existe desconto no nível do pedido;

\- existe frete;

\- pagamentos possuem ciclo próprio;

\- não existe fato financeira dedicada no modelo atual.



Por isso foi adotado o nome:



```text

Valor dos Itens Vendidos

```



\---



\# 23. Limitações atuais



O projeto possui algumas limitações intencionais.



\### Dados sintéticos



Nenhum resultado representa uma empresa real.



\### Pagamentos



Existe fonte de pagamentos, porém ainda não existe uma fato financeira dedicada na camada analítica.



O cenário possui apenas um registro de pagamento por pedido.



Não são simulados em profundidade:



\- múltiplas tentativas;

\- pagamentos divididos;

\- chargebacks;

\- estornos;

\- devoluções.



\### Causalidade



Diferenças observadas entre:



```text

canal

transportadora

cancelamento

atraso

```



são análises descritivas.



Não devem ser interpretadas automaticamente como relações causais.



\### Microsoft Azure



A implementação prática no Azure não faz parte da versão atual porque não havia assinatura disponível durante o desenvolvimento.



Azure permanece registrado como possível evolução futura, sem ser apresentado como tecnologia implementada.



\---



\# 24. Principais aprendizados



O desenvolvimento demonstrou que um pipeline de dados não consiste apenas em carregar informações.



Foi necessário:



1\. validar a qualidade das fontes;

2\. identificar inconsistências;

3\. definir regras de negócio;

4\. corrigir regras que produziam resultados enganosos;

5\. preservar a granularidade;

6\. reconciliar camadas;

7\. documentar métricas;

8\. garantir reprodutibilidade;

9\. separar configuração e código;

10\. versionar as alterações.



Esses princípios são aplicáveis a ambientes reais de Engenharia de Dados, Analytics Engineering e Business Intelligence.



\---



\# 25. Próximas evoluções



Possíveis extensões futuras:



```text

Azure / Cloud

orquestração automatizada

CI/CD

testes automatizados adicionais

camada financeira de pagamentos

monitoramento de qualidade

incremental load

Power BI Service

```



Essas evoluções não são consideradas implementadas na versão atual.

