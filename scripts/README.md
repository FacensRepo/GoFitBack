# Scripts de Deploy

Esta pasta contém scripts auxiliares para facilitar o processo de deploy no Render.

## Scripts Disponíveis

### `generate_secrets.sh`

Gera os secrets necessários para configurar as variáveis de ambiente no Render.

**Como usar:**
```bash
./scripts/generate_secrets.sh
```

**Output:**
- `SECRET_KEY_BASE`: Para criptografia de cookies e sessões
- `TOKEN_SIGNING_SECRET`: Para assinatura de tokens

**Quando usar:**
- Antes do primeiro deploy
- Quando precisar regenerar secrets por motivos de segurança

---

### `validate_deploy.sh`

Valida se todas as configurações necessárias para o deploy estão presentes e corretas.

**Como usar:**
```bash
./scripts/validate_deploy.sh
```

**O que verifica:**
- ✓ Arquivos essenciais (Dockerfile, configs, etc.)
- ✓ Scripts de release (migrate, server)
- ✓ Arquivos de documentação
- ✓ Configurações de produção (SSL, variáveis de ambiente)
- ✓ Dependências (mix.lock)
- ✓ Dockerfile (migrations e servidor)
- ✓ Git (repositório, branch, mudanças pendentes)

**Quando usar:**
- Antes de fazer deploy
- Após fazer alterações nas configurações
- Para troubleshooting

---

## Troubleshooting

### Erro: "Permission denied"

Se receber erro de permissão ao executar os scripts:

```bash
chmod +x scripts/*.sh
```

### Scripts não executam no Windows

Se estiver no Windows/WSL e os scripts não executarem:

1. Verifique line endings:
```bash
dos2unix scripts/*.sh
```

2. Ou reconfigure git:
```bash
git config core.autocrlf input
```

## Notas

- Todos os scripts devem ser executados da raiz do projeto
- Os scripts são seguros e não modificam arquivos (exceto validate_deploy.sh que só lê)
- Nunca commite os secrets gerados no Git!
