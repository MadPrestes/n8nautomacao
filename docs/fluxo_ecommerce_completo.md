# Fluxo completo do e-commerce no n8n

Este fluxo integra:

- WhatsApp via Evolution API
- n8n como orquestrador
- PostgreSQL para clientes, sessões, produtos e pedidos
- mensagens automáticas para catálogo, carrinho e Pix

---

## 1. Estrutura geral

```text
WhatsApp → Evolution API → Webhook n8n → PostgreSQL → Respostas automáticas via Evolution API
```

---

## 2. Fluxo principal

### A. Recepção e identificação
- O WhatsApp envia uma mensagem para a Evolution API
- O webhook do n8n recebe o payload
- O número do cliente é normalizado
- O cliente é buscado na tabela `clientes`
- Se não existir, é criado automaticamente
- A sessão do cliente é lida em `sessoes`

### B. Navegação e catálogo
- O cliente envia `1` ou `CATALOGO`
- O n8n consulta os produtos com `ativo = TRUE`
- O catálogo é formatado e enviado ao cliente por WhatsApp
- O usuário responde com o número do produto
- O item entra no carrinho em JSONB dentro de `sessoes.dados_temporarios`

### C. Fechamento do pedido
- O cliente envia `3` ou `CONFIRMAR`
- O pedido é criado na tabela `pedidos`
- Os itens do carrinho são calculados para gerar o total
- O Pix é gerado e salvo em `pedidos.pix_copia_cola`
- A mensagem com o Pix é enviada ao cliente

### D. Pós-venda
- O cliente confirma o pagamento com `PAGO`
- O status do pedido pode ser atualizado para `PAGO`
- Futuramente pode ser estendido para `EM_SEPARACAO`, `ENVIADO`, `ENTREGUE`

---

## 3. Workflow recomendado

Importe o arquivo:

- [n8n/workflows/ecommerce_whatsapp_full.json](../n8n/workflows/ecommerce_whatsapp_full.json)

---

## 4. Variáveis de ambiente do n8n

Configure no painel do n8n:

```bash
EVOLUTION_API_URL=http://192.168.0.152:8080
EVOLUTION_API_KEY=sua_chave_secreta_aqui
```

Também é necessário configurar a conexão do PostgreSQL no n8n com:

```text
Host: postgres
Port: 5432
Database: n8n
User: n8n
Password: n8n_password
```

---

## 5. Estrutura do payload do webhook

O webhook recebe um payload no formato da Evolution API, e o trecho principal é geralmente algo como:

```json
{
  "from": "5511999999999",
  "text": "1",
  "instance": "default",
  "type": "text"
}
```

---

## 6. Próximos refinamentos

Para produção, o fluxo pode evoluir para:

- autenticação por sessão
- validação de endereço
- tabela de itens do pedido em banco
- histórico de mensagens por cliente
- pagamento real com API externa
- notificação de envio e rastreio

---

## 7. Fluxo de banco envolvido

A lógica usa as tabelas:

- `clientes`
- `produtos`
- `sessoes`
- `pedidos`
- `itens_pedido`

---

## 8. Observação importante

Este workflow é um ponto de partida funcional e bem estruturado para o seu e-commerce conversacional. Ele deve ser ajustado com base nas regras reais da sua operação, especialmente em:

- nome da instância da Evolution
- chave da API
- estrutura exata do webhook da Evolution
- regra de Pix/checkout real

---

Se você quiser, posso continuar e montar a segunda parte, onde eu te entrego:

1. os nós de PostgreSQL para inserir `itens_pedido` em lote
2. o fluxo de confirmação de pagamento
3. a lógica de notificação de envio e entrega
4. um arquivo JSON final já pronto para importação com itens mais refinados
