-- Banco transacional ficticio de e-commerce.
-- Volume: 200 mil clientes, 100 mil produtos, 1 milhao de pedidos,
-- aproximadamente 3 milhoes de itens e 10 milhoes de eventos.

CREATE SCHEMA IF NOT EXISTS ecommerce;
SET search_path = ecommerce, public;
SELECT setseed(0.314159);

CREATE TABLE clientes (
    cliente_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_completo   varchar(150) NOT NULL,
    email           varchar(254) NOT NULL UNIQUE,
    telefone        varchar(30),
    data_nascimento date,
    status_cliente  varchar(20) NOT NULL CHECK (status_cliente IN ('ATIVO', 'INATIVO')),
    criado_em       timestamptz NOT NULL,
    atualizado_em   timestamptz NOT NULL
);

CREATE TABLE enderecos_clientes (
    endereco_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id        bigint NOT NULL REFERENCES clientes(cliente_id),
    tipo_endereco     varchar(20) NOT NULL CHECK (tipo_endereco IN ('ENTREGA', 'COBRANCA')),
    nome_destinatario varchar(150) NOT NULL,
    cep               varchar(12) NOT NULL,
    rua               varchar(180) NOT NULL,
    numero            varchar(20) NOT NULL,
    complemento       varchar(120),
    bairro            varchar(100),
    cidade            varchar(100) NOT NULL,
    estado            char(2) NOT NULL,
    pais              char(2) NOT NULL DEFAULT 'BR',
    padrao            boolean NOT NULL DEFAULT false,
    criado_em         timestamptz NOT NULL
);

CREATE TABLE marcas (
    marca_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_marca varchar(120) NOT NULL UNIQUE,
    criado_em  timestamptz NOT NULL
);

CREATE TABLE categorias (
    categoria_id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    categoria_pai_id integer REFERENCES categorias(categoria_id),
    nome_categoria   varchar(120) NOT NULL,
    criado_em        timestamptz NOT NULL
);

CREATE TABLE produtos (
    produto_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    marca_id        integer NOT NULL REFERENCES marcas(marca_id),
    categoria_id    integer NOT NULL REFERENCES categorias(categoria_id),
    nome_produto    varchar(180) NOT NULL,
    descricao       text,
    status_produto  varchar(20) NOT NULL CHECK (status_produto IN ('ATIVO', 'INATIVO')),
    criado_em       timestamptz NOT NULL,
    atualizado_em   timestamptz NOT NULL
);

CREATE TABLE variantes_produtos (
    variante_id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    produto_id    bigint NOT NULL REFERENCES produtos(produto_id),
    sku           varchar(60) NOT NULL UNIQUE,
    nome_variante varchar(120) NOT NULL,
    preco_custo   numeric(12,2) NOT NULL CHECK (preco_custo >= 0),
    preco_venda   numeric(12,2) NOT NULL CHECK (preco_venda >= preco_custo),
    peso_gramas   integer NOT NULL CHECK (peso_gramas > 0),
    ativo         boolean NOT NULL DEFAULT true,
    criado_em     timestamptz NOT NULL,
    atualizado_em timestamptz NOT NULL
);

CREATE TABLE armazens (
    armazem_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_armazem varchar(120) NOT NULL,
    cidade       varchar(100) NOT NULL,
    estado       char(2) NOT NULL,
    criado_em    timestamptz NOT NULL
);

CREATE TABLE estoque (
    armazem_id            integer NOT NULL REFERENCES armazens(armazem_id),
    variante_id           bigint NOT NULL REFERENCES variantes_produtos(variante_id),
    quantidade_disponivel integer NOT NULL CHECK (quantidade_disponivel >= 0),
    quantidade_reservada  integer NOT NULL CHECK (quantidade_reservada >= 0),
    atualizado_em         timestamptz NOT NULL,
    PRIMARY KEY (armazem_id, variante_id)
);

CREATE TABLE pedidos (
    pedido_id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id            bigint NOT NULL REFERENCES clientes(cliente_id),
    endereco_cobranca_id  bigint NOT NULL REFERENCES enderecos_clientes(endereco_id),
    endereco_entrega_id   bigint NOT NULL REFERENCES enderecos_clientes(endereco_id),
    status_pedido         varchar(25) NOT NULL CHECK (status_pedido IN ('ENTREGUE','ENVIADO','PROCESSANDO','CANCELADO','DEVOLVIDO')),
    canal_venda           varchar(30) NOT NULL,
    moeda                 char(3) NOT NULL DEFAULT 'BRL',
    subtotal              numeric(14,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    desconto_total        numeric(14,2) NOT NULL DEFAULT 0 CHECK (desconto_total >= 0),
    frete_total           numeric(14,2) NOT NULL DEFAULT 0 CHECK (frete_total >= 0),
    total_pedido          numeric(14,2) NOT NULL DEFAULT 0 CHECK (total_pedido >= 0),
    realizado_em          timestamptz NOT NULL,
    atualizado_em         timestamptz NOT NULL
);

CREATE TABLE itens_pedido (
    item_pedido_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id      bigint NOT NULL REFERENCES pedidos(pedido_id),
    variante_id    bigint NOT NULL REFERENCES variantes_produtos(variante_id),
    quantidade     integer NOT NULL CHECK (quantidade > 0),
    preco_unitario numeric(12,2) NOT NULL CHECK (preco_unitario >= 0),
    desconto_total numeric(12,2) NOT NULL DEFAULT 0 CHECK (desconto_total >= 0),
    total_item     numeric(14,2) NOT NULL CHECK (total_item >= 0)
);

CREATE TABLE pagamentos (
    pagamento_id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id            bigint NOT NULL REFERENCES pedidos(pedido_id),
    metodo_pagamento     varchar(30) NOT NULL,
    status_pagamento     varchar(25) NOT NULL CHECK (status_pagamento IN ('APROVADO', 'ESTORNADO')),
    valor                numeric(14,2) NOT NULL CHECK (valor >= 0),
    parcelas             smallint NOT NULL CHECK (parcelas > 0),
    referencia_transacao varchar(100) NOT NULL UNIQUE,
    pago_em              timestamptz,
    criado_em            timestamptz NOT NULL
);

CREATE TABLE envios (
    envio_id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id            bigint NOT NULL REFERENCES pedidos(pedido_id),
    armazem_id           integer NOT NULL REFERENCES armazens(armazem_id),
    transportadora       varchar(80) NOT NULL,
    codigo_rastreamento  varchar(100) UNIQUE,
    status_envio         varchar(25) NOT NULL,
    enviado_em           timestamptz,
    entregue_em          timestamptz,
    custo_frete          numeric(12,2) NOT NULL CHECK (custo_frete >= 0),
    criado_em            timestamptz NOT NULL
);

CREATE TABLE eventos_clientes (
    evento_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id       bigint REFERENCES clientes(cliente_id),
    sessao_id        uuid NOT NULL,
    tipo_evento      varchar(40) NOT NULL,
    produto_id       bigint REFERENCES produtos(produto_id),
    pedido_id        bigint REFERENCES pedidos(pedido_id),
    tipo_dispositivo varchar(20) NOT NULL,
    origem           varchar(40) NOT NULL,
    dados_evento     jsonb NOT NULL DEFAULT '{}'::jsonb,
    ocorrido_em      timestamptz NOT NULL
);

INSERT INTO marcas (nome_marca, criado_em)
SELECT 'Marca ' || lpad(n::text, 4, '0'), timestamp '2020-01-01' + (n % 1800) * interval '1 day'
FROM generate_series(1, 500) AS g(n);

INSERT INTO categorias (nome_categoria, criado_em)
SELECT 'Categoria ' || lpad(n::text, 3, '0'), timestamp '2020-01-01' + (n % 1800) * interval '1 day'
FROM generate_series(1, 100) AS g(n);

INSERT INTO armazens (nome_armazem, cidade, estado, criado_em) VALUES
    ('Centro de Distribuicao Sudeste', 'Jundiai', 'SP', '2020-01-01'),
    ('Centro de Distribuicao Sul', 'Curitiba', 'PR', '2020-01-01'),
    ('Centro de Distribuicao Nordeste', 'Recife', 'PE', '2020-01-01'),
    ('Centro de Distribuicao Centro-Oeste', 'Goiania', 'GO', '2020-01-01'),
    ('Centro de Distribuicao Norte', 'Belem', 'PA', '2020-01-01');

INSERT INTO clientes (nome_completo, email, telefone, data_nascimento, status_cliente, criado_em, atualizado_em)
SELECT 'Cliente ' || lpad(n::text, 8, '0'), 'cliente' || n || '@example.test',
       '+55' || lpad((1100000000 + n)::text, 11, '0'), date '1960-01-01' + (n % 18000),
       CASE WHEN n % 17 = 0 THEN 'INATIVO' ELSE 'ATIVO' END,
       timestamp '2020-01-01' + (n % 2400) * interval '1 day',
       timestamp '2020-01-01' + (n % 2400) * interval '1 day' + (n % 86400) * interval '1 second'
FROM generate_series(1, 200000) AS g(n);

INSERT INTO enderecos_clientes (cliente_id, tipo_endereco, nome_destinatario, cep, rua, numero, complemento, bairro, cidade, estado, padrao, criado_em)
SELECT c.cliente_id, 'ENTREGA', c.nome_completo, lpad((10000000 + c.cliente_id)::text, 8, '0'),
       'Rua Principal ' || (c.cliente_id % 500), (1 + c.cliente_id % 9999)::text,
       CASE WHEN c.cliente_id % 4 = 0 THEN 'Apto ' || (1 + c.cliente_id % 900) ELSE NULL END,
       'Centro', (ARRAY['Sao Paulo','Rio de Janeiro','Belo Horizonte','Curitiba','Porto Alegre','Salvador','Recife','Goiania'])[1 + (c.cliente_id % 8)],
       (ARRAY['SP','RJ','MG','PR','RS','BA','PE','GO'])[1 + (c.cliente_id % 8)], 'BR', true, c.criado_em
FROM clientes c;

INSERT INTO produtos (marca_id, categoria_id, nome_produto, descricao, status_produto, criado_em, atualizado_em)
SELECT 1 + (n % 500), 1 + (n % 100), 'Produto catalogo ' || lpad(n::text, 8, '0'),
       'Descricao do produto ' || n, CASE WHEN n % 23 = 0 THEN 'INATIVO' ELSE 'ATIVO' END,
       timestamp '2020-01-01' + (n % 1800) * interval '1 day', timestamp '2020-01-01' + (n % 1800) * interval '1 day'
FROM generate_series(1, 100000) AS g(n);

INSERT INTO variantes_produtos (produto_id, sku, nome_variante, preco_custo, preco_venda, peso_gramas, ativo, criado_em, atualizado_em)
SELECT p.produto_id, 'SKU-' || lpad(p.produto_id::text, 8, '0'), 'Padrao',
       c.preco_custo, c.preco_custo + round((15 + random() * 800)::numeric, 2),
       100 + (p.produto_id % 4900), true, p.criado_em, p.atualizado_em
FROM produtos p
CROSS JOIN LATERAL (SELECT round((10 + random() * 490)::numeric, 2) AS preco_custo) c;

INSERT INTO estoque (armazem_id, variante_id, quantidade_disponivel, quantidade_reservada, atualizado_em)
SELECT a.armazem_id, v.variante_id, 20 + ((a.armazem_id * v.variante_id) % 500), 0, now()
FROM armazens a CROSS JOIN variantes_produtos v;

INSERT INTO pedidos (cliente_id, endereco_cobranca_id, endereco_entrega_id, status_pedido, canal_venda, frete_total, realizado_em, atualizado_em)
SELECT c.cliente_id, c.cliente_id, c.cliente_id,
       (ARRAY['ENTREGUE','ENTREGUE','ENTREGUE','ENVIADO','PROCESSANDO','CANCELADO','DEVOLVIDO'])[1 + (n % 7)],
       (ARRAY['SITE','APLICATIVO','MARKETPLACE','SOCIAL'])[1 + (n % 4)],
       round((9 + random() * 35)::numeric, 2),
       timestamp '2021-01-01' + floor(random() * 1826) * interval '1 day' + (n % 86400) * interval '1 second',
       timestamp '2021-01-01' + floor(random() * 1826) * interval '1 day'
FROM generate_series(1, 1000000) AS g(n)
JOIN clientes c ON c.cliente_id = 1 + ((n * 17) % 200000);

INSERT INTO itens_pedido (pedido_id, variante_id, quantidade, preco_unitario, desconto_total, total_item)
SELECT p.pedido_id, 1 + ((p.pedido_id * 17 + item_numero * 7919) % 100000),
       quantidade, v.preco_venda,
       round((v.preco_venda * percentual_desconto * quantidade / 100.0)::numeric, 2),
       round((v.preco_venda * quantidade * (1 - percentual_desconto / 100.0))::numeric, 2)
FROM pedidos p
CROSS JOIN LATERAL generate_series(1, 1 + (p.pedido_id % 5)) AS itens(item_numero)
CROSS JOIN LATERAL (SELECT 1 + ((p.pedido_id + item_numero) % 3) AS quantidade,
                           ((p.pedido_id + item_numero) % 20) AS percentual_desconto) dados
JOIN variantes_produtos v ON v.variante_id = 1 + ((p.pedido_id * 17 + item_numero * 7919) % 100000);

UPDATE pedidos p
SET subtotal = totais.subtotal,
    desconto_total = totais.desconto_total,
    total_pedido = round((totais.total_itens + p.frete_total)::numeric, 2),
    atualizado_em = p.atualizado_em + interval '1 hour'
FROM (
    SELECT pedido_id, sum(preco_unitario * quantidade) AS subtotal,
           sum(desconto_total) AS desconto_total, sum(total_item) AS total_itens
    FROM itens_pedido GROUP BY pedido_id
) totais
WHERE totais.pedido_id = p.pedido_id;

INSERT INTO pagamentos (pedido_id, metodo_pagamento, status_pagamento, valor, parcelas, referencia_transacao, pago_em, criado_em)
SELECT p.pedido_id, (ARRAY['CARTAO_CREDITO','PIX','BOLETO','CARTEIRA'])[1 + (p.pedido_id % 4)],
       CASE WHEN p.status_pedido = 'CANCELADO' THEN 'ESTORNADO' ELSE 'APROVADO' END,
       p.total_pedido, 1 + (p.pedido_id % 12), 'TX-' || md5(p.pedido_id::text),
       CASE WHEN p.status_pedido = 'CANCELADO' THEN NULL ELSE p.realizado_em + interval '5 minutes' END, p.realizado_em
FROM pedidos p;

INSERT INTO envios (pedido_id, armazem_id, transportadora, codigo_rastreamento, status_envio, enviado_em, entregue_em, custo_frete, criado_em)
SELECT p.pedido_id, 1 + (p.pedido_id % 5), (ARRAY['Correios','Jadlog','Loggi','Total Express'])[1 + (p.pedido_id % 4)],
       CASE WHEN p.status_pedido IN ('PROCESSANDO','CANCELADO') THEN NULL ELSE 'BR' || lpad(p.pedido_id::text, 12, '0') END,
       CASE p.status_pedido WHEN 'ENTREGUE' THEN 'ENTREGUE' WHEN 'ENVIADO' THEN 'EM_TRANSITO' WHEN 'CANCELADO' THEN 'CANCELADO' ELSE 'PENDENTE' END,
       CASE WHEN p.status_pedido IN ('PROCESSANDO','CANCELADO') THEN NULL ELSE p.realizado_em + interval '2 days' END,
       CASE WHEN p.status_pedido = 'ENTREGUE' THEN p.realizado_em + interval '7 days' ELSE NULL END,
       p.frete_total, p.realizado_em
FROM pedidos p;

INSERT INTO eventos_clientes (cliente_id, sessao_id, tipo_evento, produto_id, pedido_id, tipo_dispositivo, origem, dados_evento, ocorrido_em)
SELECT 1 + floor(random() * 200000)::bigint, md5(n::text || '-sessao')::uuid,
       (ARRAY['visualizacao_pagina','busca','visualizacao_produto','adicao_carrinho','inicio_checkout','compra','login','favorito'])[1 + (n % 8)],
       CASE WHEN n % 8 IN (2,3,4,5,7) THEN 1 + (n * 31 % 100000) ELSE NULL END,
       CASE WHEN n % 8 = 5 THEN 1 + (n % 1000000) ELSE NULL END,
       (ARRAY['celular','computador','tablet'])[1 + (n % 3)],
       (ARRAY['organico','busca_paga','email','afiliado','direto'])[1 + (n % 5)],
       jsonb_build_object('campanha', 'campanha_' || (n % 25), 'grupo_teste', CASE WHEN n % 2 = 0 THEN 'A' ELSE 'B' END),
       timestamp '2021-01-01' + floor(random() * 1826) * interval '1 day' + (n % 86400) * interval '1 second'
FROM generate_series(1, 10000000) AS g(n);

CREATE INDEX ix_enderecos_clientes_cliente ON enderecos_clientes (cliente_id);
CREATE INDEX ix_produtos_categoria ON produtos (categoria_id);
CREATE INDEX ix_produtos_marca ON produtos (marca_id);
CREATE INDEX ix_variantes_produto ON variantes_produtos (produto_id);
CREATE INDEX ix_pedidos_cliente_data ON pedidos (cliente_id, realizado_em);
CREATE INDEX ix_pedidos_status_data ON pedidos (status_pedido, realizado_em);
CREATE INDEX ix_itens_pedido_pedido ON itens_pedido (pedido_id);
CREATE INDEX ix_itens_pedido_variante ON itens_pedido (variante_id);
CREATE INDEX ix_pagamentos_pedido ON pagamentos (pedido_id);
CREATE INDEX ix_envios_pedido ON envios (pedido_id);
CREATE INDEX ix_eventos_ocorrido_em ON eventos_clientes (ocorrido_em);
CREATE INDEX ix_eventos_cliente_tempo ON eventos_clientes (cliente_id, ocorrido_em);

ANALYZE;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pedidos p
        JOIN (SELECT pedido_id, sum(total_item) AS total_itens FROM itens_pedido GROUP BY pedido_id) i USING (pedido_id)
        WHERE p.total_pedido <> round((i.total_itens + p.frete_total)::numeric, 2)
    ) THEN RAISE EXCEPTION 'Integridade invalida: total dos pedidos nao bate com os itens'; END IF;

    IF EXISTS (
        SELECT 1 FROM pedidos p JOIN pagamentos pg USING (pedido_id)
        WHERE p.total_pedido <> pg.valor
    ) THEN RAISE EXCEPTION 'Integridade invalida: pagamentos nao batem com pedidos'; END IF;

    IF EXISTS (
        SELECT 1 FROM pedidos p LEFT JOIN itens_pedido i USING (pedido_id)
        WHERE i.pedido_id IS NULL
    ) THEN RAISE EXCEPTION 'Integridade invalida: pedido sem item'; END IF;

    IF EXISTS (
        SELECT 1 FROM pedidos p LEFT JOIN envios e USING (pedido_id)
        WHERE e.pedido_id IS NULL
    ) THEN RAISE EXCEPTION 'Integridade invalida: pedido sem envio'; END IF;

    IF EXISTS (
        SELECT 1 FROM pedidos p JOIN envios e USING (pedido_id)
        WHERE p.frete_total <> e.custo_frete
    ) THEN RAISE EXCEPTION 'Integridade invalida: frete do pedido nao bate com o envio'; END IF;
END $$;
