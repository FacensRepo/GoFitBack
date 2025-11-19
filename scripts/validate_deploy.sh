#!/bin/bash

# Script de validação para verificar se tudo está pronto para deploy no Render

echo "🔍 Validando configuração para deploy no Render..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de problemas
ISSUES=0

# Função para checkar arquivos
check_file() {
  if [ -f "$1" ]; then
    echo -e "${GREEN}✓${NC} $1 existe"
  else
    echo -e "${RED}✗${NC} $1 não encontrado"
    ((ISSUES++))
  fi
}

# Função para checar diretórios
check_dir() {
  if [ -d "$1" ]; then
    echo -e "${GREEN}✓${NC} $1 existe"
  else
    echo -e "${RED}✗${NC} $1 não encontrado"
    ((ISSUES++))
  fi
}

echo "=== Arquivos Essenciais ==="
check_file "Dockerfile"
check_file "mix.exs"
check_file "config/runtime.exs"
check_file "config/prod.exs"
check_file ".dockerignore"
echo ""

echo "=== Scripts de Release ==="
check_file "rel/overlays/bin/migrate"
check_file "rel/overlays/bin/server"
check_file "lib/gofitback/release.ex"
echo ""

echo "=== Arquivos de Deploy ==="
check_file "render.yaml"
check_file "DEPLOY.md"
check_file ".env.example"
echo ""

echo "=== Configurações de Produção ==="

# Verificar se SSL está habilitado
if grep -q "ssl: true" config/runtime.exs; then
  echo -e "${GREEN}✓${NC} SSL habilitado para PostgreSQL"
else
  echo -e "${YELLOW}⚠${NC} SSL não habilitado em config/runtime.exs (recomendado para Render)"
  ((ISSUES++))
fi

# Verificar se SECRET_KEY_BASE está configurado
if grep -q "SECRET_KEY_BASE" config/runtime.exs; then
  echo -e "${GREEN}✓${NC} SECRET_KEY_BASE configurado em runtime.exs"
else
  echo -e "${RED}✗${NC} SECRET_KEY_BASE não encontrado em runtime.exs"
  ((ISSUES++))
fi

# Verificar se DATABASE_URL está configurado
if grep -q "DATABASE_URL" config/runtime.exs; then
  echo -e "${GREEN}✓${NC} DATABASE_URL configurado em runtime.exs"
else
  echo -e "${RED}✗${NC} DATABASE_URL não encontrado em runtime.exs"
  ((ISSUES++))
fi

echo ""
echo "=== Dependências ==="

# Verificar se mix.lock existe
if [ -f "mix.lock" ]; then
  echo -e "${GREEN}✓${NC} mix.lock existe (dependências locked)"
else
  echo -e "${YELLOW}⚠${NC} mix.lock não encontrado - execute 'mix deps.get'"
  ((ISSUES++))
fi

echo ""
echo "=== Dockerfile ==="

# Verificar se Dockerfile contém migrations
if grep -q "bin/migrate" Dockerfile; then
  echo -e "${GREEN}✓${NC} Dockerfile configurado para rodar migrations"
else
  echo -e "${RED}✗${NC} Migrations não configuradas no Dockerfile"
  ((ISSUES++))
fi

# Verificar se Dockerfile contém server
if grep -q "bin/server" Dockerfile; then
  echo -e "${GREEN}✓${NC} Dockerfile configurado para iniciar servidor"
else
  echo -e "${RED}✗${NC} Servidor não configurado no Dockerfile"
  ((ISSUES++))
fi

echo ""
echo "=== Git ==="

# Verificar se está em um repositório git
if [ -d ".git" ]; then
  echo -e "${GREEN}✓${NC} Repositório Git inicializado"

  # Verificar branch
  BRANCH=$(git branch --show-current)
  echo -e "${GREEN}✓${NC} Branch atual: $BRANCH"

  # Verificar se há mudanças não commitadas
  if [ -z "$(git status --porcelain)" ]; then
    echo -e "${GREEN}✓${NC} Nenhuma mudança pendente"
  else
    echo -e "${YELLOW}⚠${NC} Há mudanças não commitadas"
  fi
else
  echo -e "${RED}✗${NC} Não é um repositório Git"
  ((ISSUES++))
fi

echo ""
echo "=== Resumo ==="

if [ $ISSUES -eq 0 ]; then
  echo -e "${GREEN}✓ Tudo pronto para deploy no Render!${NC}"
  echo ""
  echo "Próximos passos:"
  echo "1. Execute './scripts/generate_secrets.sh' para gerar os secrets"
  echo "2. Configure as variáveis de ambiente no Render"
  echo "3. Faça o deploy!"
  exit 0
else
  echo -e "${RED}✗ Encontrados $ISSUES problema(s) - corrija antes de fazer deploy${NC}"
  exit 1
fi
