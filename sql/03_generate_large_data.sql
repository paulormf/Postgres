-- Carga transacional grande: 1 milhao de pedidos, cerca de 3 milhoes de itens e 10 milhoes de eventos.
SET search_path = ecommerce, public;
SELECT setseed(0.314159);

INSERT INTO pedidos (cliente_id, endereco_cobranca_id, endereco_entrega_id, status_pedido, canal_venda,
                     subtotal, desconto_total, frete_total, total_pedido, realizado_em, atualizado_em)
SELECT cliente_id, cliente_id, cliente_id,
       (ARRAY['ENTREGUE','ENTREGUE','ENTREGUE','ENVIADO','PROCESSANDO','CANCELADO','DEVOLVIDO'])[1 + (n % 7)],
       (ARRAY['SITE','APLICATIVO','MARKETPLACE','SOCIAL'])[1 + (n % 4)],
       0, 0, round((9 + random() * 35)::numeric, 2), 0,
       timestamp '2021-01-01' + floor(random() * 1826) * interval '1 day' + (n % 86400) * interval '1 second',
       timestamp '2021-01-01' + floor(random() * 1826) * interval '1 day'
FROM generate_series(1, 1000000) AS g(n)
JOIN clientes c ON c.cliente_id = 1 + ((n * 17) % 200000);

INSERT INTO itens_pedido (pedido_id, variante_id, quantidade, preco_unitario, desconto_total, total_item)
SELECT p.pedido_id,
       1 + ((p.pedido_id * 17 + numero_item * 7919) % 100000),
       1 + ((p.pedido_id + numero_item) % 3),
       v.preco_venda,
       round((v.preco_venda * ((p.pedido_id + numero_item) % 20) / 100.0)::numeric, 2),
       round((v.preco_venda * (1 - ((p.pedido_id + numero_item) % 20) / 100.0) * (1 + ((p.pedido_id + numero_item) % 3)))::numeric, 2)
FROM pedidos p
CROSS JOIN LATERAL generate_series(1, 1 + (p.pedido_id % 5)) AS itens(numero_item)
JOIN variantes_produtos v ON v.variante_id = 1 + ((p.pedido_id * 17 + numero_item * 7919) % 100000);

UPDATE pedidos p
SET subtotal = totais.subtotal,
    desconto_total = totais.desconto_total,
    total_pedido = round((totais.subtotal - totais.desconto_total + p.frete_total)::numeric, 2),
    atualizado_em = p.atualizado_em + interval '1 hour'
FROM (
    SELECT pedido_id, sum(preco_unitario * quantidade) AS subtotal, sum(desconto_total) AS desconto_total
    FROM itens_pedido GROUP BY pedido_id
) totais
WHERE totais.pedido_id = p.pedido_id;

INSERT INTO pagamentos (pedido_id, metodo_pagamento, status_pagamento, valor, parcelas, referencia_transacao, pago_em, criado_em)
SELECT p.pedido_id, (ARRAY['CARTAO_CREDITO','PIX','BOLETO','CARTEIRA'])[1 + (p.pedido_id % 4)],
       CASE WHEN p.status_pedido = 'CANCELADO' THEN 'ESTORNADO' ELSE 'APROVADO' END,
       p.total_pedido, 1 + (p.pedido_id % 12), 'TX-' || md5(p.pedido_id::text),
       CASE WHEN p.status_pedido = 'CANCELADO' THEN NULL ELSE p.realizado_em + interval '5 minutes' END,
       p.realizado_em
FROM pedidos p;

INSERT INTO envios (pedido_id, armazem_id, transportadora, codigo_rastreamento, status_envio, enviado_em, entregue_em, custo_frete, criado_em)
SELECT p.pedido_id, 1 + (p.pedido_id % 5),
       (ARRAY['Correios','Jadlog','Loggi','Total Express'])[1 + (p.pedido_id % 4)],
       CASE WHEN p.status_pedido IN ('PROCESSANDO','CANCELADO') THEN NULL ELSE 'BR' || lpad(p.pedido_id::text, 12, '0') END,
       CASE p.status_pedido WHEN 'ENTREGUE' THEN 'ENTREGUE' WHEN 'ENVIADO' THEN 'EM_TRANSITO' WHEN 'CANCELADO' THEN 'CANCELADO' ELSE 'PENDENTE' END,
       CASE WHEN p.status_pedido IN ('PROCESSANDO','CANCELADO') THEN NULL ELSE p.realizado_em + interval '2 days' END,
       CASE WHEN p.status_pedido = 'ENTREGUE' THEN p.realizado_em + interval '7 days' ELSE NULL END,
       p.frete_total, p.realizado_em
FROM pedidos p;

INSERT INTO avaliacoes_produtos (cliente_id, produto_id, pedido_id, nota, titulo_avaliacao, texto_avaliacao, criado_em)
SELECT p.cliente_id, v.produto_id, p.pedido_id, 1 + (p.pedido_id % 5),
       'Avaliacao do produto', 'Comentario ficticio do cliente sobre a compra.', p.realizado_em + interval '10 days'
FROM pedidos p
JOIN itens_pedido ip ON ip.pedido_id = p.pedido_id
JOIN variantes_produtos v ON v.variante_id = ip.variante_id
WHERE p.pedido_id % 4 = 0;

INSERT INTO eventos_clientes (cliente_id, sessao_id, tipo_evento, produto_id, pedido_id, tipo_dispositivo, origem, dados_evento, ocorrido_em)
SELECT 1 + floor(random() * 200000)::bigint,
       md5(n::text || '-sessao')::uuid,
       (ARRAY['visualizacao_pagina','busca','visualizacao_produto','adicao_carrinho','inicio_checkout','compra','login','favorito'])[1 + (n % 8)],
       CASE WHEN n % 8 IN (2,3,4,5,7) THEN 1 + (n * 31 % 100000) ELSE NULL END,
       CASE WHEN n % 8 = 5 THEN 1 + (n % 1000000) ELSE NULL END,
       (ARRAY['celular','computador','tablet'])[1 + (n % 3)],
       (ARRAY['organico','busca_paga','email','afiliado','direto'])[1 + (n % 5)],
       jsonb_build_object('campanha', 'campanha_' || (n % 25), 'grupo_teste', CASE WHEN n % 2 = 0 THEN 'A' ELSE 'B' END),
       timestamp '2021-01-01' + floor(random() * 1826) * interval '1 day' + (n % 86400) * interval '1 second'
FROM generate_series(1, 10000000) AS g(n);

ANALYZE;
