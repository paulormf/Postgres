# PostgreSQL via Docker

## Base ficticia de e-commerce

O diretorio `sql/` e montado em `/docker-entrypoint-initdb.d` e executado automaticamente quando o volume e criado pela primeira vez:

- `01_schema.sql`: cria o schema relacional transacional `ecommerce`.
- `02_reference_data.sql`: carrega clientes, enderecos, categorias, marcas, produtos, variantes, armazens e estoque.
- `03_generate_large_data.sql`: gera 1 milhao de pedidos, aproximadamente 3 milhoes de itens, pagamentos, envios e 10 milhoes de eventos.
- `04_views_operacionais.sql`: cria views operacionais para detalhes de pedidos e posicao de estoque.
- `05_indices.sql`: cria indices depois da carga para melhorar as consultas.

Como os scripts de inicializacao so rodam em um banco vazio, recrie o volume para gerar a base:

```powershell
docker compose down -v
docker compose --env-file .env up -d
docker compose logs -f postgres
```

O comando `down -v` apaga os dados do volume. Use-o somente para recriar a base ficticia.

Para conectar:

```powershell
docker compose exec postgres psql -U app -d appdb
```

Exemplos de consultas:

```sql
SET search_path = ecommerce, public;
SELECT * FROM vw_detalhes_pedidos ORDER BY realizado_em DESC LIMIT 20;
SELECT * FROM vw_posicao_estoque ORDER BY quantidade_livre ASC LIMIT 20;
SELECT count(*) FROM eventos_clientes;
```

Este projeto executa PostgreSQL 16 com armazenamento persistente em um volume Docker.

## Iniciar

No servidor, dentro desta pasta:

```bash
cp .env.example .env
```

Edite `.env` e defina uma senha longa e aleatória. Depois execute:

```bash
docker compose up -d
docker compose ps
docker compose logs -f postgres
```

O banco ficará acessível pela porta `POSTGRES_PORT` do servidor. Por exemplo:

```text
postgresql://app:SENHA@IP_PUBLICO_DO_SERVIDOR:5432/appdb
```

O hostname deve ser o IP ou DNS público do servidor, e a porta deve estar liberada no firewall e no security group da hospedagem.

## Parar e administrar

```bash
docker compose stop
docker compose start
docker compose down
```

`docker compose down` preserva os dados no volume. Para remover também os dados, use `docker compose down -v` somente se essa perda for intencional.

## Segurança antes de publicar

Expor a porta 5432 diretamente à internet permite tentativas de login e exploração contínuas. Antes de colocar o servidor em produção:

1. Restrinja a porta 5432 no firewall para os IPs que realmente precisam acessar o banco. Se não for possível, use uma porta externa diferente e mantenha o firewall restritivo.
2. Use uma senha longa e exclusiva no `.env`; não version-e esse arquivo.
3. Prefira VPN ou túnel SSH. Para clientes externos diretos, configure TLS no PostgreSQL e exija `sslmode=verify-full`.
4. Faça backups testados e monitore tentativas de conexão.

O Compose publica a porta em todas as interfaces (`0.0.0.0`) para permitir o acesso externo solicitado. A proteção da exposição deve ser feita no firewall, VPN/TLS e regras de rede do provedor.
