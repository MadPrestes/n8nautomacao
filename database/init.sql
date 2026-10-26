-- =============================================================
-- E-commerce WhatsApp Bot - Inicialização do Banco de Dados
-- =============================================================

-- 1. Tabela de Clientes
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    telefone VARCHAR(20) UNIQUE NOT NULL,
    nome VARCHAR(100),
    cpf VARCHAR(14),
    endereco TEXT,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabela de Produtos
CREATE TABLE IF NOT EXISTS produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    preco NUMERIC(10, 2) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabela de Sessões (Estado do bot)
CREATE TABLE IF NOT EXISTS sessoes (
    telefone VARCHAR(20) PRIMARY KEY,
    etapa VARCHAR(50) NOT NULL DEFAULT 'INICIO',
    dados_temporarios JSONB DEFAULT '{}'::jsonb,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabela de Pedidos
CREATE TABLE IF NOT EXISTS pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id) ON DELETE CASCADE,
    valor_total NUMERIC(10, 2) NOT NULL,
    status VARCHAR(30) DEFAULT 'PENDENTE',
    pix_copia_cola TEXT,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Itens do Pedido
CREATE TABLE IF NOT EXISTS itens_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id INT REFERENCES pedidos(id) ON DELETE CASCADE,
    produto_id INT REFERENCES produtos(id),
    quantidade INT NOT NULL,
    preco_unitario NUMERIC(10, 2) NOT NULL
);

-- Inserir alguns produtos de exemplo para testes iniciais
INSERT INTO produtos (nome, descricao, preco) VALUES 
('Café Especial 250g', 'Café em grãos 100% Arábica torra média', 35.00),
('Mel Silvestre 500g', 'Mel puro de florada silvestre', 45.00),
('Azeite Artesanal 500ml', 'Azeite extra virgem extravirgido a frio', 65.00)
ON CONFLICT DO NOTHING;
