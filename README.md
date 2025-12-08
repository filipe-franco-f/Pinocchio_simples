# Pinocchio Proof-of-Concept (Simplified)

Este repositório contém uma implementação **didática** e **simplificada** do protocolo
**[Pinocchio](https://www.andrew.cmu.edu/user/bparno/papers/pinocchio.pdf)** (SNARK baseado em QAPs), escrita em **SageMath**.  
O objetivo é fornecer um código funcional e legível que permita entender os
componentes principais do sistema:

- Representação de circuitos como **QAPs**
- Geração de chaves
- Provação
- Verificação
- Estrutura algebraica necessária para um SNARK do tipo Pinocchio

A implementação **não** é segura para uso em produção.  
Serve exclusivamente para fins educativos e experimentação.

---

## 📁 Estrutura dos Arquivos

### **`pinocchio_simple.sage`**
Arquivo principal do sistema.  
Contém:

- Implementação simplificada do protocolo Pinocchio
  - `KeyGen`
  - `Prove`
  - `Verify`
- Um simulador de grupos bilineares (placeholders) usado para evitar dependência de bibliotecas mais avançadas.
- Utilização do arquivo `SimpleQAP.sage' para obter um QAP de um circuito simples.
- Execução completa do fluxo de prova → verificação para o circuito em questão.

Este arquivo é o **ponto de entrada** do projeto.

---

### **`SimpleQAP.sage`**
Define a estrutura de um **QAP simplificado**, incluindo:

- Armazenamento dos polinômios  
  `v_i(x), w_i(x), y_i(x), t(x)`
- Avaliação dos polinômios em pontos escolhidos
- Montagem da prova para o QAP
- Funções auxiliares relacionadas à algebra polinomial

É uma pequena biblioteca auxiliar usada por `pinocchio_simple.sage`.

---

## ▶️ Como Executar

### **Pré-requisitos**
- Python 3
- **SageMath** instalado (versão ≥ 9 recomendado)

### **Executando**

1. Abra um terminal na pasta do projeto.
2. Rode o arquivo principal com o interpretador do Sage:

```bash
sage pinocchio_simple.sage
