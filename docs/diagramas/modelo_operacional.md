# Modelo Operacional — DataOps Analytics

Este diagrama representa as principais entidades previstas nas fontes de dados operacionais do projeto.

```mermaid
erDiagram

    CLIENTES ||--o{ PEDIDOS : realiza
    PEDIDOS ||--|{ ITENS_PEDIDO : possui
    PRODUTOS ||--o{ ITENS_PEDIDO : compoe
    PEDIDOS ||--o{ PAGAMENTOS : recebe
    PRODUTOS ||--o{ ESTOQUE : possui
    PEDIDOS ||--o| ENTREGAS : gera

    CLIENTES {
        int id_cliente PK
        string nome_cliente
        date data_cadastro
        string cep
        string cidade
        string uf
        string segmento_cliente
        string status_cliente
    }

    PRODUTOS {
        int id_produto PK
        string nome_produto
        string categoria
        string subcategoria
        string marca
        decimal custo_unitario
        decimal preco_unitario
        string status_produto
    }

    PEDIDOS {
        int id_pedido PK
        int id_cliente FK
        datetime data_pedido
        string canal_venda
        string status_pedido
        decimal valor_frete
        decimal desconto_pedido
        decimal valor_total
    }

    ITENS_PEDIDO {
        int id_item PK
        int id_pedido FK
        int id_produto FK
        int quantidade
        decimal preco_unitario
        decimal desconto_item
        decimal valor_item
    }

    PAGAMENTOS {
        int id_pagamento PK
        int id_pedido FK
        string forma_pagamento
        int numero_parcelas
        decimal valor_pagamento
        string status_pagamento
        datetime data_pagamento
    }

    ESTOQUE {
        int id_estoque PK
        int id_produto FK
        date data_referencia
        int quantidade_disponivel
        int estoque_minimo
        int quantidade_reservada
    }

    ENTREGAS {
        int id_entrega PK
        int id_pedido FK
        string transportadora
        datetime data_envio
        date data_prevista
        datetime data_entrega
        string status_entrega
        int tentativas_entrega
        decimal custo_logistico
    }
```

## Observação

Este modelo representa as entidades operacionais planejadas para as fontes de dados.

Ele não representa o modelo dimensional final utilizado no Power BI.

O modelo analítico será desenvolvido posteriormente a partir das transformações realizadas nas camadas Bronze, Silver e Gold.