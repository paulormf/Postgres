CREATE SCHEMA IF NOT EXISTS ecommerce;
SET search_path = ecommerce, public;

CREATE TABLE clientes (
    cliente_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_completo   varchar(150) NOT NULL,
    email           varchar(254) NOT NULL UNIQUE,
    telefone        varchar(30),
    data_nascimento date,
    status_cliente  varchar(20) NOT NULL DEFAULT 'ATIVO',
    criado_em       timestamptz NOT NULL,
    atualizado_em   timestamptz NOT NULL
);

CREATE TABLE enderecos_clientes (
    endereco_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id        bigint NOT NULL REFERENCES clientes(cliente_id),
    tipo_endereco     varchar(20) NOT NULL,
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
    marca_id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_marca      varchar(120) NOT NULL UNIQUE,
    criado_em       timestamptz NOT NULL
);

CREATE TABLE categorias (
    categoria_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    categoria_pai_id  integer REFERENCES categorias(categoria_id),
    nome_categoria    varchar(120) NOT NULL,
    criado_em         timestamptz NOT NULL
);

CREATE TABLE produtos (
    produto_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    marca_id        integer NOT NULL REFERENCES marcas(marca_id),
    categoria_id    integer NOT NULL REFERENCES categorias(categoria_id),
    nome_produto    varchar(180) NOT NULL,
    descricao       text,
    status_produto  varchar(20) NOT NULL DEFAULT 'ATIVO',
    criado_em       timestamptz NOT NULL,
    atualizado_em   timestamptz NOT NULL
);

CREATE TABLE variantes_produtos (
    variante_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    produto_id      bigint NOT NULL REFERENCES produtos(produto_id),
    sku             varchar(60) NOT NULL UNIQUE,
    nome_variante   varchar(120) NOT NULL,
    preco_custo     numeric(12,2) NOT NULL,
    preco_venda     numeric(12,2) NOT NULL,
    peso_gramas     integer NOT NULL,
    ativo           boolean NOT NULL DEFAULT true,
    criado_em       timestamptz NOT NULL,
    atualizado_em   timestamptz NOT NULL
);

CREATE TABLE armazens (
    armazem_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_armazem    varchar(120) NOT NULL,
    cidade          varchar(100) NOT NULL,
    estado          char(2) NOT NULL,
    criado_em       timestamptz NOT NULL
);

CREATE TABLE estoque (
    armazem_id             integer NOT NULL REFERENCES armazens(armazem_id),
    variante_id            bigint NOT NULL REFERENCES variantes_produtos(variante_id),
    quantidade_disponivel  integer NOT NULL DEFAULT 0,
    quantidade_reservada   integer NOT NULL DEFAULT 0,
    atualizado_em           timestamptz NOT NULL,
    PRIMARY KEY (armazem_id, variante_id)
);

CREATE TABLE pedidos (
    pedido_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id      bigint NOT NULL REFERENCES clientes(cliente_id),
    endereco_cobranca_id bigint NOT NULL REFERENCES enderecos_clientes(endereco_id),
    endereco_entrega_id  bigint NOT NULL REFERENCES enderecos_clientes(endereco_id),
    status_pedido   varchar(25) NOT NULL,
    canal_venda     varchar(30) NOT NULL,
    moeda           char(3) NOT NULL DEFAULT 'BRL',
    subtotal        numeric(14,2) NOT NULL DEFAULT 0,
    desconto_total  numeric(14,2) NOT NULL DEFAULT 0,
    frete_total     numeric(14,2) NOT NULL DEFAULT 0,
    total_pedido    numeric(14,2) NOT NULL DEFAULT 0,
    realizado_em    timestamptz NOT NULL,
    atualizado_em   timestamptz NOT NULL
);

CREATE TABLE itens_pedido (
    item_pedido_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id       bigint NOT NULL REFERENCES pedidos(pedido_id),
    variante_id     bigint NOT NULL REFERENCES variantes_produtos(variante_id),
    quantidade      integer NOT NULL,
    preco_unitario  numeric(12,2) NOT NULL,
    desconto_total  numeric(12,2) NOT NULL DEFAULT 0,
    total_item      numeric(14,2) NOT NULL
);

CREATE TABLE pagamentos (
    pagamento_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id           bigint NOT NULL REFERENCES pedidos(pedido_id),
    metodo_pagamento   varchar(30) NOT NULL,
    status_pagamento   varchar(25) NOT NULL,
    valor              numeric(14,2) NOT NULL,
    parcelas           smallint NOT NULL DEFAULT 1,
    referencia_transacao varchar(100),
    pago_em            timestamptz,
    criado_em          timestamptz NOT NULL
);

CREATE TABLE envios (
    envio_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id       bigint NOT NULL REFERENCES pedidos(pedido_id),
    armazem_id      integer NOT NULL REFERENCES armazens(armazem_id),
    transportadora  varchar(80) NOT NULL,
    codigo_rastreamento varchar(100),
    status_envio    varchar(25) NOT NULL,
    enviado_em      timestamptz,
    entregue_em     timestamptz,
    custo_frete     numeric(12,2) NOT NULL DEFAULT 0,
    criado_em       timestamptz NOT NULL
);

CREATE TABLE avaliacoes_produtos (
    avaliacao_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id      bigint NOT NULL REFERENCES clientes(cliente_id),
    produto_id      bigint NOT NULL REFERENCES produtos(produto_id),
    pedido_id       bigint REFERENCES pedidos(pedido_id),
    nota            smallint NOT NULL,
    titulo_avaliacao varchar(180),
    texto_avaliacao text,
    criado_em       timestamptz NOT NULL
);

CREATE TABLE eventos_clientes (
    evento_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id      bigint REFERENCES clientes(cliente_id),
    sessao_id       uuid NOT NULL,
    tipo_evento     varchar(40) NOT NULL,
    produto_id      bigint REFERENCES produtos(produto_id),
    pedido_id       bigint REFERENCES pedidos(pedido_id),
    tipo_dispositivo varchar(20) NOT NULL,
    origem          varchar(40) NOT NULL,
    dados_evento    jsonb NOT NULL DEFAULT '{}'::jsonb,
    ocorrido_em     timestamptz NOT NULL
);
