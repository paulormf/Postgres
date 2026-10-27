SET search_path = ecommerce, public;

INSERT INTO marcas (nome_marca, criado_em)
SELECT 'Marca ' || lpad(n::text, 4, '0'), timestamp '2020-01-01' + (n % 1800) * interval '1 day'
FROM generate_series(1, 500) AS g(n);

INSERT INTO categorias (nome_categoria, criado_em)
SELECT 'Categoria ' || lpad(n::text, 3, '0'), timestamp '2020-01-01' + (n % 1800) * interval '1 day'
FROM generate_series(1, 100) AS g(n);

INSERT INTO armazens (nome_armazem, cidade, estado, criado_em)
VALUES
    ('Centro de Distribuicao Sudeste', 'Jundiai', 'SP', '2020-01-01'),
    ('Centro de Distribuicao Sul', 'Curitiba', 'PR', '2020-01-01'),
    ('Centro de Distribuicao Nordeste', 'Recife', 'PE', '2020-01-01'),
    ('Centro de Distribuicao Centro-Oeste', 'Goiania', 'GO', '2020-01-01'),
    ('Centro de Distribuicao Norte', 'Belem', 'PA', '2020-01-01');

INSERT INTO clientes (nome_completo, email, telefone, data_nascimento, status_cliente, criado_em, atualizado_em)
SELECT 'Cliente ' || lpad(n::text, 8, '0'),
       'cliente' || n || '@example.test',
       '+55' || lpad((1100000000 + n)::text, 11, '0'),
       date '1960-01-01' + (n % 18000),
       CASE WHEN n % 17 = 0 THEN 'INATIVO' ELSE 'ATIVO' END,
       timestamp '2020-01-01' + (n % 2400) * interval '1 day',
       timestamp '2020-01-01' + (n % 2400) * interval '1 day' + (n % 86400) * interval '1 second'
FROM generate_series(1, 200000) AS g(n);

INSERT INTO enderecos_clientes (cliente_id, tipo_endereco, nome_destinatario, cep, rua, numero,
                                complemento, bairro, cidade, estado, padrao, criado_em)
SELECT c.cliente_id,
       'ENTREGA', c.nome_completo, lpad((10000000 + c.cliente_id)::text, 8, '0'),
       'Rua Principal ' || (c.cliente_id % 500), (1 + c.cliente_id % 9999)::text,
       CASE WHEN c.cliente_id % 4 = 0 THEN 'Apto ' || (1 + c.cliente_id % 900) ELSE NULL END,
       'Centro',
       (ARRAY['Sao Paulo','Rio de Janeiro','Belo Horizonte','Curitiba','Porto Alegre','Salvador','Recife','Goiania'])[1 + (c.cliente_id % 8)],
       (ARRAY['SP','RJ','MG','PR','RS','BA','PE','GO'])[1 + (c.cliente_id % 8)],
       true, c.criado_em
FROM clientes c;

INSERT INTO produtos (marca_id, categoria_id, nome_produto, descricao, status_produto, criado_em, atualizado_em)
SELECT 1 + (n % 500), 1 + (n % 100),
       'Produto catalogo ' || lpad(n::text, 8, '0'),
       'Descricao do produto ' || n,
       CASE WHEN n % 23 = 0 THEN 'INATIVO' ELSE 'ATIVO' END,
       timestamp '2020-01-01' + (n % 1800) * interval '1 day',
       timestamp '2020-01-01' + (n % 1800) * interval '1 day'
FROM generate_series(1, 100000) AS g(n);

INSERT INTO variantes_produtos (produto_id, sku, nome_variante, preco_custo, preco_venda, peso_gramas, ativo, criado_em, atualizado_em)
SELECT p.produto_id, 'SKU-' || lpad(p.produto_id::text, 8, '0'), 'Padrao',
       round((10 + random() * 490)::numeric, 2),
       round((25 + random() * 975)::numeric, 2),
       100 + (p.produto_id % 4900), true, p.criado_em, p.atualizado_em
FROM produtos p;

INSERT INTO estoque (armazem_id, variante_id, quantidade_disponivel, quantidade_reservada, atualizado_em)
SELECT w.armazem_id, v.variante_id, 20 + ((w.armazem_id * v.variante_id) % 500), 0, now()
FROM armazens w CROSS JOIN variantes_produtos v;

ANALYZE;
