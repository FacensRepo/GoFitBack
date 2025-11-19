# Render Deploy - Guia Rápido

## Checklist de Deploy

- [ ] Repositório Git conectado ao Render
- [ ] PostgreSQL criado no Render
- [ ] Variáveis de ambiente configuradas
- [ ] Primeiro deploy realizado
- [ ] Health check passando
- [ ] Migrations executadas

## Passo a Passo Rápido

### 1. Gerar Secrets

Execute localmente:

```bash
./scripts/generate_secrets.sh
```

Ou manualmente:

```bash
mix phx.gen.secret  # Para SECRET_KEY_BASE
mix phx.gen.secret  # Para TOKEN_SIGNING_SECRET
```

### 2. Obter Database URL

1. Acesse seu PostgreSQL no Render Dashboard
2. Vá em "Info" → "Internal Database URL"
3. Copie a URL e **troque** `postgres://` por `ecto://`

Exemplo:
```
# URL do Render:
postgres://user:pass@host/db

# URL para configurar:
ecto://user:pass@host/db
```

### 3. Configurar Variáveis de Ambiente no Render

No Dashboard do Render, adicione:

```
DATABASE_URL=ecto://... (obtido no passo 2)
SECRET_KEY_BASE=... (gerado no passo 1)
TOKEN_SIGNING_SECRET=... (gerado no passo 1)
PHX_HOST=seu-app.onrender.com
PORT=10000
MIX_ENV=prod
POOL_SIZE=10
```

### 4. Deploy

**Opção A - Blueprint (Recomendado):**

1. Ajuste o `render.yaml` com suas configurações
2. No Render: "New +" → "Blueprint"
3. Selecione seu repositório
4. Clique em "Apply"

**Opção B - Manual:**

1. No Render: "New +" → "Web Service"
2. Selecione seu repositório
3. Configure Runtime como "Docker"
4. Adicione as variáveis de ambiente
5. Clique em "Create Web Service"

### 5. Verificar

Acompanhe o deploy nos logs:

```
✓ Building Docker image...
✓ Running migrations...
✓ Starting server...
✓ Health check passed!
```

Acesse: `https://seu-app.onrender.com`

## Comandos Úteis

### Testar Build Localmente

```bash
# Build da imagem
docker build -t gofitback .

# Rodar localmente (ajuste as env vars)
docker run -p 4000:4000 \
  -e DATABASE_URL=ecto://... \
  -e SECRET_KEY_BASE=... \
  -e TOKEN_SIGNING_SECRET=... \
  -e PHX_HOST=localhost \
  -e PORT=4000 \
  gofitback
```

### Executar Migrations Manualmente

Se precisar rodar migrations separadamente:

1. Acesse o shell do container no Render
2. Execute:
```bash
/app/bin/migrate
```

### Ver Logs

No Render Dashboard:
- Vá até seu serviço
- Clique em "Logs"
- Filtre por tipo (build, deploy, runtime)

## Troubleshooting Rápido

### Erro: "DATABASE_URL missing"

→ Configure a variável `DATABASE_URL` no Render

### Erro: "SECRET_KEY_BASE missing"

→ Gere com `mix phx.gen.secret` e configure no Render

### Erro: SSL connection failed

→ Verifique se `ssl: true` está ativo em `config/runtime.exs` (já configurado)

### Build demora muito

→ Normal no primeiro deploy. Próximos builds usam cache.

### Serviço em "sleep"

→ Plano Free entra em sleep após 15min de inatividade
→ Primeiro request após sleep demora ~30s

### Migrations não executaram

→ Verifique os logs de deploy
→ Confirme que `DATABASE_URL` está correta
→ Verifique se o Dockerfile executa `/app/bin/migrate`

## Arquivos Importantes

```
Dockerfile              # Configuração Docker multi-stage
render.yaml            # Blueprint para deploy automático
config/runtime.exs     # Configurações de produção
rel/overlays/bin/      # Scripts de release (migrate, server)
DEPLOY.md             # Guia completo de deploy
.env.example          # Template de variáveis de ambiente
```

## URLs Úteis

- **Render Dashboard**: https://dashboard.render.com
- **Documentação Render**: https://render.com/docs
- **Phoenix Deployment**: https://hexdocs.pm/phoenix/deployment.html

## Próximos Passos

Após deploy bem-sucedido:

1. [ ] Configure domínio customizado (opcional)
2. [ ] Configure monitoring/alertas
3. [ ] Configure backups do banco
4. [ ] Configure CI/CD para testes antes do deploy
5. [ ] Considere upgrade do plano para produção

## Observações

- Free tier tem limitações de CPU/RAM
- Banco PostgreSQL Free tem limite de 1GB
- Considere planos pagos para produção
- Configure secrets adequados (não commite no Git!)
