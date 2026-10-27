# Fluxo inicial do n8n com Evolution API

Este guia cria um fluxo básico para receber mensagens do WhatsApp via Evolution API e responder automaticamente.

## 1. Importar o workflow

Importe o arquivo:

- [n8n/workflows/whatsapp_evolution_workflow.json](../n8n/workflows/whatsapp_evolution_workflow.json)

No n8n, acesse:
- Workflows
- Import
- Selecione o arquivo JSON

---

## 2. Configurar as variáveis de ambiente no n8n

No painel do n8n, defina as variáveis de ambiente ou use `Environment Variables`:

```bash
EVOLUTION_API_URL=http://192.168.0.152:8080
EVOLUTION_API_KEY=sua_chave_secreta_aqui
```

> Ajuste o IP para o host correto da sua máquina ou servidor.

---

## 3. Configurar a Evolution API

Na Evolution API, garanta que a instância do WhatsApp esteja ativa e que o webhook esteja apontando para o n8n.

Exemplo de webhook do Evolution:

```text
http://192.168.0.152:5678/webhook/evolution-webhook
```

> O n8n cria a URL pública do webhook depois de salvar o workflow. Verifique o endpoint em `Webhook Evolution`.

---

## 4. Estrutura do fluxo

### Webhook Evolution
- Recebe o POST do Evolution API
- Captura dados de entrada: telefone, texto e tipo da mensagem

### Extrair dados do WhatsApp
- Normaliza os dados da mensagem
- Gera um payload pronto para o processamento

### Responder via Evolution API
- Envia uma resposta para o mesmo número via:

```http
POST /message/sendText/{instanceName}
```

Exemplo de corpo:

```json
{
  "number": "5511999999999",
  "text": "Olá! Recebi sua mensagem."
}
```

---

## 5. Próximo passo do e-commerce

A partir deste fluxo base, você pode adicionar:

- validação do cliente em PostgreSQL
- busca do catálogo em `produtos`
- montagens do carrinho em `sessoes.dados_temporarios`
- geração de pedido e Pix
- envio de notificações pós-venda

---

## 6. Dica de segurança

Em produção, evite deixar a chave da API em texto livre. Use:

- credenciais do n8n
- variáveis de ambiente do host
- proxy reverso com HTTPS e autenticação

---

## 7. Fluxo de integração sugerido

```text
WhatsApp → Evolution API → Webhook n8n → PostgreSQL → Resposta via Evolution API
```

Isso cria a base para um bot de e-commerce conversacional com rastreio, carrinho, pedidos e pagamentos.
