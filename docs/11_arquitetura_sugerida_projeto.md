# Pré-requisitos
- baixo custo (relatório montados, enviado no Teams)
- ferramentas que o time já tenha conhecimento
- controle total dos serviços e recursos
- escalabilidade
- elaticidade
- d-1 até h-1

---

## Cloud

#### Estrutura usando somente serviços em cloud com **lock-in na Azure**
- powerBI
- Azure Analysis Services
- Azure Runbook (H-1) ou Data Factory (M-15)
  - runbooks já temos o conhecimento e scripts para fazer reuso
- Azure SQL Server Data Warehouse
- Data lake (blob storage)
- Azure Data Factory (orquestração)
- Máquina virtual na Azure
  - gateway
  - escalável e elástico para momentos de grande uso do sistema poder redimensionar   
  - usar uma vpn para criar um tunelamento na rede interna da softplan
  - menor custo pois é possível gerenciar o horário de funcionamento
  - fácil de gerenciar os logs
  - fácil de metrificar tanto a própria máquina virtual quanto o gateway
- Azure monitor 
 - log analytics
 - log analytics solution (para tratar eventuais problema relatados nos logs)
- Azure dashboard
 - para ver as métricas dos serviços


#### Estutura usando somente serviços em cloud **sem locki-In** de cloud
- powerBI
- Máquina virtual na Azure
  - gateway
  - Analysis Services (container)
  - SISS (container)
  - SQL Server (container)
  - Data lake (blob storage)
  - grafana para metricas

---

## On-premises
Estrutura sem utilizar serviços em cloud

- powerBI
- Máquina virtual para:
  - Analysis Services
  - SISS
  - SQL Server (dw)
- Máquina virtual para:
 - data lake (mongo ou cassandra)
 - data integration (etl)
- Máquina virtual para:
 - grafana para métricas
