# Guia de Deploy no Render

Este guia explica como fazer o deploy da aplicação GoFit Backend no Render.

## Pré-requisitos

- Conta no [Render](https://render.com)
- Repositório Git com o código (GitHub, GitLab, etc.)
- PostgreSQL já criado no Render (conforme mencionado)

## Opção 1: Deploy Automático via render.yaml (Recomendado)

### Passo 1: Conectar o repositório

1. Faça login no [Render Dashboard](https://dashboard.render.com)
2. Clique em "New +" → "Blueprint"
3. Conecte seu repositório Git
4. O Render detectará automaticamente o arquivo `render.yaml`

### Passo 2: Ajustar o render.yaml

Antes de fazer o deploy, edite o arquivo `render.yaml` e ajuste:

- **PHX_HOST**: Altere `gofitback.onrender.com` para o domínio que você vai usar
- **Database name**: Se você já criou um banco PostgreSQL, você pode:
  - Opção A: Usar o banco existente - remova a seção `databases` do render.yaml e configure manualmente a variável `DATABASE_URL`
  - Opção B: Deixar o Render criar um novo banco usando a configuração do arquivo

### Passo 3: Configurar Database URL (se usar banco existente)

Se você já tem um PostgreSQL no Render:

1. Vá até seu serviço de banco de dados no Render
2. Copie a "Internal Database URL" ou "External Database URL"
3. Na configuração do seu web service, adicione a variável de ambiente:
   - `DATABASE_URL`: cole a URL do banco

## Opção 2: Deploy Manual

### Passo 1: Criar o Web Service

1. No Render Dashboard, clique em "New +" → "Web Service"
2. Conecte seu repositório
3. Configure:
   - **Name**: `gofitback` (ou o nome que preferir)
   - **Region**: `Oregon` (ou a região mais próxima)
   - **Branch**: `main`
   - **Runtime**: `Docker`
   - **Dockerfile Path**: `./Dockerfile`
   - **Docker Build Context Directory**: `.`
   - **Plan**: `Free` (ou o plano que preferir)

### Passo 2: Configurar Variáveis de Ambiente

Adicione as seguintes variáveis de ambiente:

#### Obrigatórias:

- `DATABASE_URL`: URL de conexão do seu PostgreSQL (obtida do banco que você criou)
  - Formato: `ecto://USER:PASSWORD@HOST/DATABASE`
  - Exemplo: `ecto://gofitback:sua_senha@dpg-xxxxx.oregon-postgres.render.com/gofitback_prod`

- `SECRET_KEY_BASE`: Gere um secret executando localmente:
  ```bash
  mix phx.gen.secret
  ```

- `TOKEN_SIGNING_SECRET`: Gere outro secret:
  ```bash
  mix phx.gen.secret
  ```

- `PHX_HOST`: Seu domínio no Render
  - Formato: `seu-app.onrender.com`
  - Ou use seu domínio customizado se tiver

- `MIX_ENV`: `prod`

- `PORT`: `10000` (porta padrão do Render)

#### Opcionais:

- `POOL_SIZE`: `10` (número de conexões com o banco)
- `ECTO_IPV6`: `false` (ou `true` se precisar de IPv6)

### Passo 3: Deploy

1. Clique em "Create Web Service"
2. O Render vai:
   - Fazer build da imagem Docker
   - Executar as migrations automaticamente (via `/app/bin/migrate`)
   - Iniciar o servidor

## Verificando o Deploy

### Logs

Acompanhe os logs do deploy na aba "Logs" do seu serviço no Render.

### Health Check

O Render faz automaticamente health checks na rota `/`. Certifique-se de que sua aplicação responde nessa rota.

### Migrations

As migrations são executadas automaticamente antes do servidor iniciar, conforme configurado no Dockerfile:

```dockerfile
CMD ["sh", "-c", "/app/bin/migrate && /app/bin/server"]
```

## Obtendo a DATABASE_URL do PostgreSQL no Render

1. Vá até "Databases" no Render Dashboard
2. Selecione seu banco de dados PostgreSQL
3. Na aba "Info", você verá:
   - **Internal Database URL**: Use esta se o backend estiver no Render (mais rápido)
   - **External Database URL**: Use esta para conexões externas

4. A URL estará no formato:
   ```
   postgres://USER:PASSWORD@HOST/DATABASE
   ```

5. **IMPORTANTE**: Converta para o formato Ecto:
   ```
   ecto://USER:PASSWORD@HOST/DATABASE
   ```
   (Apenas troque `postgres://` por `ecto://`)

## Testando a Aplicação

Após o deploy bem-sucedido:

1. Acesse: `https://seu-app.onrender.com`
2. Teste os endpoints da API
3. Verifique os logs se houver problemas

## Troubleshooting

### Build Failure

- Verifique os logs de build
- Certifique-se de que todas as dependências estão no `mix.exs`
- Verifique se o Dockerfile está correto

### Migration Errors

- Verifique se a `DATABASE_URL` está correta
- Confirme que o banco de dados está acessível
- Veja os logs da migration

### Connection Errors

- Verifique se `PHX_HOST` está configurado corretamente
- Confirme que `PORT` está em `10000`
- Verifique se `SECRET_KEY_BASE` e `TOKEN_SIGNING_SECRET` estão definidos

### SSL Connection

Se tiver problemas de SSL com o banco:

1. Edite `config/runtime.exs`
2. Descomente a linha:
   ```elixir
   config :gofitback, Gofitback.Repo,
     ssl: true,
     url: database_url,
     # ...
   ```

## Atualizações

Para fazer deploy de novas versões:

1. Faça push para o branch configurado (ex: `main`)
2. O Render detecta automaticamente e faz redeploy
3. Ou você pode fazer deploy manual no Dashboard

## Notas Importantes

- O plano Free do Render pode ter limitações de CPU e memória
- Serviços gratuitos entram em "sleep" após 15 minutos de inatividade
- O primeiro request após o sleep pode demorar ~30 segundos
- Para produção, considere usar um plano pago

## Recursos Adicionais

- [Documentação do Render](https://render.com/docs)
- [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)
- [Render PostgreSQL](https://render.com/docs/databases)
