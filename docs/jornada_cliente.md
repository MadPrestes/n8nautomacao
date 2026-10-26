# Jornada do Cliente — E-commerce WhatsApp Bot (n8n)

> Documentação da jornada conversacional do cliente no sistema automatizado de e-commerce via WhatsApp, orquestrado pelo n8n.

---

## Visão Geral do Fluxo

```
[WhatsApp] → [Webhook n8n] → [Identificação] → [Catálogo] → [Carrinho] → [Pagamento Pix] → [Pós-Venda]
```

---

## Etapa 1 — Recepção e Triagem

**Trigger:** Webhook recebido pelo n8n a partir do WhatsApp Business API.

### Fluxo
1. O cliente envia qualquer mensagem para o número do WhatsApp.
2. O n8n recebe o payload via **Webhook HTTP** (método POST).
3. O número de telefone é extraído do campo `from` do payload.
4. Uma consulta é realizada na tabela `clientes` para verificar se o contato já está cadastrado.
   - **Cliente novo:** inserido na tabela `clientes` com `telefone` e `criado_em`.
   - **Cliente existente:** dados carregados para personalizar a resposta.
5. A sessão do cliente é lida ou criada na tabela `sessoes` com `etapa = 'INICIO'`.

### Tabelas envolvidas
| Tabela    | Operação          |
|-----------|-------------------|
| `clientes` | `SELECT` / `INSERT` |
| `sessoes`  | `SELECT` / `INSERT` |

### Resposta ao cliente (exemplo)
> *"Olá! 👋 Bem-vindo à nossa loja. Como posso te ajudar hoje?*
> *1️⃣ Ver produtos*
> *2️⃣ Meus pedidos*
> *0️⃣ Falar com atendente"*

---

## Etapa 2 — Navegação e Seleção de Produtos

**Estado da sessão:** `etapa = 'CATALOGO'` ou `etapa = 'CARRINHO'`

### Fluxo
1. O cliente digita `1` (ou equivalente) para ver o catálogo.
2. O n8n consulta a tabela `produtos` filtrando `ativo = TRUE`.
3. A lista de produtos é formatada e enviada ao cliente.
4. O cliente informa o **ID ou nome do produto** e a **quantidade** desejada.
5. O item é adicionado ao campo `dados_temporarios` (JSONB) da tabela `sessoes`, funcionando como um **carrinho em memória**.

### Estrutura do carrinho (JSONB em `sessoes.dados_temporarios`)
```json
{
  "carrinho": [
    { "produto_id": 1, "nome": "Café Especial 250g", "quantidade": 2, "preco_unitario": 35.00 },
    { "produto_id": 3, "nome": "Azeite Artesanal 500ml", "quantidade": 1, "preco_unitario": 65.00 }
  ],
  "valor_total": 135.00
}
```

### Tabelas envolvidas
| Tabela    | Operação          |
|-----------|-------------------|
| `produtos` | `SELECT WHERE ativo = TRUE` |
| `sessoes`  | `UPDATE dados_temporarios` |

### Resposta ao cliente (exemplo)
> *"🛒 Carrinho atualizado!*
> *• 2x Café Especial 250g — R$ 70,00*
> *• 1x Azeite Artesanal 500ml — R$ 65,00*
> *Total: R$ 135,00*
>
> *Digite 'C' para continuar comprando ou 'F' para fechar o pedido."*

---

## Etapa 3 — Fechamento e Pagamento

**Estado da sessão:** `etapa = 'PAGAMENTO'`

### Fluxo
1. O cliente confirma o pedido digitando `F` (fechar).
2. O n8n verifica se o endereço de entrega está cadastrado em `clientes.endereco`.
   - Se não estiver, solicita o endereço e atualiza o cadastro.
3. Um registro é criado na tabela `pedidos` com `status = 'PENDENTE'`.
4. Os itens do carrinho são inseridos na tabela `itens_pedido`.
5. A integração com a API Pix gera o **código copia e cola** e o **QR Code**.
6. O código Pix é salvo em `pedidos.pix_copia_cola`.
7. O código e QR Code são enviados ao cliente via WhatsApp.
8. O n8n aguarda confirmação de pagamento (webhook do banco ou polling).
9. Ao confirmar, o `pedidos.status` é atualizado para `'PAGO'`.

### Tabelas envolvidas
| Tabela         | Operação                       |
|----------------|--------------------------------|
| `clientes`      | `UPDATE endereco`              |
| `pedidos`       | `INSERT` / `UPDATE status`     |
| `itens_pedido`  | `INSERT` (bulk dos itens)      |
| `sessoes`       | `UPDATE etapa = 'AGUARDANDO_PAGAMENTO'` |

### Resposta ao cliente (exemplo)
> *"✅ Pedido #42 gerado com sucesso!*
> *💳 Pague via Pix:*
> *Copia e cola: `00020126...`*
>
> *Após o pagamento, você receberá a confirmação aqui. 🙏"*

---

## Etapa 4 — Pós-Venda e Notificações de Envio

**Estado da sessão:** `etapa = 'POS_VENDA'`

### Fluxo
1. Após confirmação do pagamento, o status do pedido muda para `'PAGO'`.
2. O n8n dispara uma mensagem de confirmação ao cliente.
3. Quando o pedido é separado/despachado (atualização manual ou via painel), o status muda para `'ENVIADO'`.
4. O n8n detecta a mudança de status (via polling ou trigger) e envia a notificação ao cliente com o código de rastreio.
5. Ao ser entregue, o status é atualizado para `'ENTREGUE'`.
6. Uma mensagem de pós-venda é enviada solicitando feedback.

### Estados do pedido (`pedidos.status`)
| Status             | Descrição                              |
|--------------------|----------------------------------------|
| `PENDENTE`         | Pedido gerado, aguardando pagamento    |
| `PAGO`             | Pagamento confirmado                   |
| `EM_SEPARACAO`     | Pedido sendo preparado                 |
| `ENVIADO`          | Pedido despachado para entrega         |
| `ENTREGUE`         | Entrega confirmada                     |
| `CANCELADO`        | Pedido cancelado                       |

### Tabelas envolvidas
| Tabela    | Operação                      |
|-----------|-------------------------------|
| `pedidos`  | `UPDATE status`               |
| `sessoes`  | `UPDATE etapa = 'FINALIZADO'` |

### Notificações ao cliente (exemplos)
> *"🎉 Pagamento confirmado! Seu pedido #42 está sendo preparado."*

> *"📦 Seu pedido #42 foi enviado! Rastreie em: [link]"*

> *"✨ Pedido entregue! Esperamos que tenha gostado. Avalie sua experiência respondendo de 1 a 5 ⭐"*

---

## Diagrama de Estados da Sessão

```
INICIO
  └─→ CATALOGO
        └─→ CARRINHO
              └─→ COLETANDO_ENDERECO
                    └─→ PAGAMENTO
                          └─→ AGUARDANDO_PAGAMENTO
                                └─→ POS_VENDA
                                      └─→ FINALIZADO
```

---

*Documentação gerada para o projeto [n8nautomacao](https://github.com/MadPrestes/n8nautomacao).*
