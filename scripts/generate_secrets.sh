#!/bin/bash

# Script para gerar os secrets necessários para o deploy no Render

echo "Gerando secrets para deploy no Render..."
echo ""
echo "=== SECRET_KEY_BASE ==="
mix phx.gen.secret
echo ""
echo "=== TOKEN_SIGNING_SECRET ==="
mix phx.gen.secret
echo ""
echo "Copie esses valores e configure como variáveis de ambiente no Render!"
