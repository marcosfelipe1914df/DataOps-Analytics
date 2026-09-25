# Arquitetura — DataOps Analytics

```mermaid
flowchart LR

    subgraph FONTES["Fontes de Dados"]
        CSV["CSV"]
        XLS["Excel"]
        API["API Pública"]
    end

    subgraph INGESTAO["Ingestão"]
        PY["Python + Pandas"]
    end

    subgraph AZURE["Microsoft Azure"]
        STORAGE["Azure Storage"]

        subgraph DBX["Azure Databricks"]
            BRONZE["Bronze<br/>Dados Brutos"]
            SILVER["Silver<br/>Dados Tratados"]
            GOLD["Gold<br/>Dados Analíticos"]
        end
    end

    subgraph BI["Camada Analítica"]
        STAR["Modelo Estrela"]
        PBI["Power BI"]
        EXCEL["Excel<br/>Reconciliação"]
    end

    subgraph LOCAL["Ambiente Local"]
        DOCKER["Docker"]
        POSTGRES["PostgreSQL"]
        SQL["SQL<br/>Análises + Qualidade"]
    end

    CSV --> PY
    XLS --> PY
    API --> PY

    PY --> STORAGE

    STORAGE --> BRONZE
    BRONZE --> SILVER
    SILVER --> GOLD

    GOLD --> STAR
    STAR --> PBI
    STAR --> EXCEL

    PY --> POSTGRES
    DOCKER --> POSTGRES
    POSTGRES --> SQL

    SQL -. Validação .-> PBI
    EXCEL -. Reconciliação .-> PBI