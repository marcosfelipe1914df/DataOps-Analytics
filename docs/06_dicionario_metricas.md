\# Dicionário de Métricas — DataOps Analytics



\## 1. Objetivo



Este documento define os principais indicadores utilizados no projeto \*\*DataOps Analytics\*\*, garantindo consistência entre SQL/PostgreSQL, Excel, Power BI e Databricks.



> Todos os dados são sintéticos e utilizados exclusivamente para estudo e portfólio.



\---



\# 2. Valor dos Itens Vendidos



\*\*Definição:\*\* soma do valor dos itens pertencentes a pedidos concluídos.



\*\*Fonte principal:\*\* `fato\_vendas`



\*\*Regra conceitual:\*\*



```text

Somar valor\_item

onde status\_pedido = Concluido

```



\*\*Resultado validado:\*\*



```text

R$ 64.251.128,33

```



\### Observação



Esta métrica não deve ser chamada automaticamente de faturamento contábil.



`valor\_item` representa o valor dos itens e não incorpora necessariamente todos os efeitos de:



\- desconto no nível do pedido;

\- frete;

\- pagamentos;

\- estornos ou devoluções.



Por isso, o projeto utiliza o nome:



> Valor dos Itens Vendidos



\---



\# 3. Pedidos Totais



\*\*Definição:\*\* quantidade distinta de pedidos existentes na base.



```text

COUNT DISTINCT id\_pedido

```



\*\*Resultado:\*\*



```text

50.000 pedidos

```



\---



\# 4. Pedidos Concluídos



\*\*Definição:\*\* quantidade distinta de pedidos cujo status é `Concluido`.



```text

status\_pedido = Concluido

```



\*\*Resultado validado:\*\*



```text

43.937 pedidos

```



\---



\# 5. Taxa de Conclusão



\*\*Definição:\*\* percentual dos pedidos que foram concluídos.



\*\*Fórmula:\*\*



```text

Pedidos Concluídos

\------------------ × 100

&#x20; Pedidos Totais

```



\*\*Valores utilizados:\*\*



```text

43.937 / 50.000

```



\*\*Resultado aproximado:\*\*



```text

87,87%

```



Nos dashboards o valor pode ser apresentado arredondado como:



```text

87,9%

```



\---



\# 6. Pedidos Cancelados



\*\*Definição:\*\* quantidade de pedidos cujo status é `Cancelado`.



\*\*Resultado:\*\*



```text

3.663 pedidos

```



\---



\# 7. Taxa de Cancelamento



\*\*Definição:\*\* percentual de pedidos cancelados em relação ao total de pedidos do agrupamento analisado.



\*\*Fórmula:\*\*



```text

Pedidos Cancelados

\------------------ × 100

&#x20; Pedidos Totais

```



\## Resultado por canal



| Canal | Taxa de cancelamento |

|---|---:|

| Marketplace | 7,47% |

| App | 7,44% |

| Site | 7,17% |



\### Interpretação



Marketplace apresentou a maior taxa no conjunto sintético, enquanto Site apresentou a menor.



A diferença observada é descritiva e não demonstra causalidade.



\---



\# 8. Unidades Vendidas



\*\*Definição:\*\* soma da quantidade dos itens pertencentes a pedidos concluídos.



```text

SUM(quantidade)

onde status\_pedido = Concluido

```



\*\*Resultado validado:\*\*



```text

137.583 unidades

```



\---



\# 9. Ticket Médio



\*\*Definição utilizada no dashboard:\*\* Valor dos Itens Vendidos dividido pela quantidade de pedidos concluídos.



\*\*Fórmula:\*\*



```text

Valor dos Itens Vendidos

\-------------------------

&#x20;  Pedidos Concluídos

```



\*\*Resultado:\*\*



```text

R$ 1.462,35

```



\### Observação



Como o numerador utiliza `valor\_item`, este indicador representa o ticket médio baseado no valor dos itens vendidos, e não necessariamente o ticket financeiro/contábil final do pedido.



\---



\# 10. Clientes



\*\*Definição:\*\* quantidade distinta de clientes presentes na dimensão de clientes.



```text

COUNT DISTINCT id\_cliente

```



\*\*Resultado:\*\*



```text

5.000 clientes

```



\---



\# 11. Valor Médio por Cliente



\*\*Definição:\*\* Valor dos Itens Vendidos dividido pelo número de clientes.



\*\*Fórmula:\*\*



```text

R$ 64.251.128,33

\----------------

&#x20; 5.000 clientes

```



\*\*Resultado aproximado:\*\*



```text

R$ 12.850,23 por cliente

```



A interpretação deve considerar os filtros aplicados no dashboard.



\---



\# 12. Participação de Valor por Canal



\*\*Definição:\*\* participação de cada canal no Valor dos Itens Vendidos.



\## Resultados



| Canal | Valor dos itens | Participação |

|---|---:|---:|

| Site | R$ 28.877.271,35 | 44,94% |

| App | R$ 22.508.335,49 | 35,03% |

| Marketplace | R$ 12.865.521,49 | 20,02% |



Diferenças residuais podem ocorrer devido ao arredondamento dos percentuais.



\---



\# 13. Entregas Concluídas



\*\*Definição:\*\* quantidade de entregas com status de entrega concluída.



\*\*Resultado validado:\*\*



```text

44.814 entregas

```



O conjunto completo de entregas possui:



```text

46.337 registros

```



e inclui também entregas ainda em trânsito.



\---



\# 14. Entregas Atrasadas



\*\*Definição:\*\* entrega concluída cuja data efetiva é posterior à data prevista.



\*\*Regra:\*\*



```sql

CAST(data\_entrega AS DATE) > CAST(data\_prevista AS DATE)

```



\*\*Resultado validado:\*\*



```text

11.187 entregas atrasadas

```



\### Decisão de qualidade



A comparação é realizada no nível da \*\*data\*\*, e não do timestamp.



Durante a validação, uma comparação baseada diretamente em timestamp classificava casos como atrasados apenas por diferenças de horário.



A regra foi ajustada para representar corretamente a definição de negócio adotada no projeto.



\---



\# 15. Taxa Geral de Atraso



\*\*Definição:\*\* percentual das entregas concluídas classificadas como atrasadas.



\*\*Fórmula:\*\*



```text

Entregas Atrasadas

\------------------- × 100

Entregas Concluídas

```



\*\*Valores:\*\*



```text

11.187 / 44.814

```



\*\*Resultado:\*\*



```text

24,96%

```



\---



\# 16. Taxa de Atraso por Canal



| Canal | Entregas concluídas | Atrasadas | Taxa |

|---|---:|---:|---:|

| Marketplace | 8.897 | 2.287 | 25,71% |

| App | 15.767 | 3.964 | 25,14% |

| Site | 20.150 | 4.936 | 24,50% |



\### Interpretação



Marketplace apresentou a maior taxa de atraso do conjunto sintético.



As diferenças são descritivas e não comprovam que o canal seja a causa dos atrasos.



\---



\# 17. Taxa de Atraso por Transportadora



| Transportadora | Entregas concluídas | Atrasadas | Taxa |

|---|---:|---:|---:|

| EntregaMax | 6.797 | 1.732 | 25,48% |

| LogExpress | 15.702 | 3.947 | 25,14% |

| TransBrasil | 9.038 | 2.234 | 24,72% |

| RapidGo | 13.277 | 3.274 | 24,66% |



\### Interpretação



As taxas são próximas entre si.



Não é adequado concluir apenas com esses números que uma transportadora é responsável pelo desempenho logístico global.



\---



\# 18. Dias Médios de Atraso



\*\*Definição:\*\* média de dias de atraso considerando as entregas atrasadas.



Resultados observados:



| Transportadora | Média de dias |

|---|---:|

| EntregaMax | 2,43 |

| LogExpress | 2,47 |

| TransBrasil | 2,51 |

| RapidGo | 2,45 |



\---



\# 19. Estoque Zerado



\*\*Definição:\*\* produto com quantidade disponível igual a zero no snapshot analisado.



```text

quantidade\_disponivel = 0

```



No último snapshot:



```text

44 produtos

```



\---



\# 20. Estoque Abaixo do Mínimo



\*\*Definição:\*\* produto que possui estoque disponível maior que zero, porém inferior ao estoque mínimo.



```text

quantidade\_disponivel > 0

AND

quantidade\_disponivel < estoque\_minimo

```



No último snapshot:



```text

31 produtos

```



\---



\# 21. Estoque Crítico



\*\*Definição:\*\* união das categorias mutuamente exclusivas:



```text

ZERADO

\+

ABAIXO DO MÍNIMO

```



No último snapshot:



```text

44 + 31 = 75 produtos críticos

```



\---



\# 22. Taxa de Estoque Crítico



\*\*Definição:\*\* percentual de produtos classificados como críticos dentro do agrupamento analisado.



\*\*Fórmula:\*\*



```text

Produtos críticos

\------------------ × 100

&#x20;Total de produtos

```



\## Resultado por categoria no último snapshot



| Categoria | Produtos | Críticos | Taxa crítica |

|---|---:|---:|---:|

| Eletrônicos | 97 | 20 | 20,62% |

| Esporte | 102 | 17 | 16,67% |

| Informática | 80 | 12 | 15,00% |

| Beleza | 115 | 17 | 14,78% |

| Casa | 106 | 9 | 8,49% |



\---



\# 23. Produtos de Alta Demanda com Estoque Crítico



\*\*Definição:\*\* produtos que aparecem entre os 50 maiores em quantidade vendida e que também apresentam estoque crítico no snapshot mais recente.



\*\*Resultado:\*\*



```text

9 produtos

```



Destes:



```text

4 estavam com estoque zerado

```



Esse indicador permite cruzar comportamento de vendas com disponibilidade de estoque.



\---



\# 24. Granularidade das métricas



A interpretação das métricas deve respeitar a granularidade das tabelas.



```text

fato\_vendas

→ item de pedido



fato\_entregas

→ entrega/pedido



fato\_estoque

→ produto/snapshot mensal

```



Por exemplo:



```text

COUNT(id\_pedido)

```



diretamente sobre `fato\_vendas` pode contar o mesmo pedido várias vezes.



Para contar pedidos nessa fato deve-se utilizar:



```text

COUNT(DISTINCT id\_pedido)

```



\---



\# 25. Contexto de filtros



As métricas podem mudar de acordo com filtros como:



```text

Ano

Segmento do cliente

Canal de venda

Categoria

Produto

Transportadora

```



Os valores documentados neste arquivo representam os resultados globais validados no conjunto sintético, salvo quando explicitamente indicado outro agrupamento.



\---



\# 26. Reconciliação



Os principais KPIs foram comparados entre diferentes etapas e ferramentas do projeto.



```text

PostgreSQL

&#x20;   ↓

Excel

&#x20;   ↓

Power BI

&#x20;   ↓

Databricks

```



Valores de referência:



| Indicador | Resultado |

|---|---:|

| Clientes | 5.000 |

| Pedidos | 50.000 |

| Pedidos concluídos | 43.937 |

| Valor dos itens vendidos | R$ 64.251.128,33 |

| Unidades vendidas | 137.583 |

| Ticket médio | R$ 1.462,35 |

| Entregas | 46.337 |

| Entregas concluídas | 44.814 |

| Entregas atrasadas | 11.187 |

| Taxa geral de atraso | 24,96% |

| Produtos críticos no último snapshot | 75 |



\---



\# 27. Limitações



\- Todos os dados são sintéticos.

\- As métricas não representam resultados financeiros de uma empresa real.

\- `valor\_item` não deve ser confundido com receita contábil.

\- O modelo analítico não possui atualmente uma fato específica de pagamentos.

\- Não existem dados reais de devoluções ou chargebacks.

\- Correlações observadas entre canal, transportadora, cancelamento e atraso não estabelecem causalidade.

\- Os resultados devem ser interpretados dentro do escopo educacional do projeto.

