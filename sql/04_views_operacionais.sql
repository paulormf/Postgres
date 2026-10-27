SET search_path = ecommerce, public;

CREATE OR REPLACE VIEW vw_detalhes_pedidos AS
SELECT p.pedido_id, p.realizado_em, p.status_pedido, p.canal_venda,
       c.cliente_id, c.nome_completo, c.email,
       p.subtotal, p.desconto_total, p.frete_total, p.total_pedido
FROM pedidos p
JOIN clientes c ON c.cliente_id = p.cliente_id;

CREATE OR REPLACE VIEW vw_posicao_estoque AS
SELECT a.armazem_id, a.nome_armazem, vp.variante_id, vp.sku,
       pr.produto_id, pr.nome_produto, e.quantidade_disponivel, e.quantidade_reservada,
       e.quantidade_disponivel - e.quantidade_reservada AS quantidade_livre, e.atualizado_em
FROM estoque e
JOIN armazens a ON a.armazem_id = e.armazem_id
JOIN variantes_produtos vp ON vp.variante_id = e.variante_id
JOIN produtos pr ON pr.produto_id = vp.produto_id;
