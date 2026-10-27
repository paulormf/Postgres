SET search_path = ecommerce, public;

-- Indices secundarios criados depois da carga em lote.
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
CREATE INDEX ix_avaliacoes_produto ON avaliacoes_produtos (produto_id, criado_em);
CREATE INDEX ix_eventos_ocorrido_em ON eventos_clientes (ocorrido_em);
CREATE INDEX ix_eventos_cliente_tempo ON eventos_clientes (cliente_id, ocorrido_em);

ANALYZE;
