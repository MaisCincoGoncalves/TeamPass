# Makefile para automação do projeto TeamPass no k3s

.PHONY: build build-legacy deploy deploy-latest deploy-legacy clean help

# Build da imagem atual
build:
	.\scripts\build-teampass-arm64.ps1

# Build da imagem legada
build-legacy:
	.\scripts\build-teampass-3.1.4.30-arm64.ps1

# Deploy da configuração padrão
deploy:
	kubectl apply -k .\k8s

# Deploy da versão latest
deploy-latest:
	kubectl kustomize --load-restrictor LoadRestrictionsNone .\k8s\overlays\latest | kubectl apply -f -

# Deploy da versão legacy
deploy-legacy:
	kubectl kustomize --load-restrictor LoadRestrictionsNone .\k8s\overlays\legacy-3.1.4.30 | kubectl apply -f -

# Limpar recursos (cuidado!)
clean:
	kubectl delete -k .\k8s

# Ajuda
help:
	@echo "Comandos disponíveis:"
	@echo "  make build          - Construir imagem arm64 atual"
	@echo "  make build-legacy   - Construir imagem legada"
	@echo "  make deploy         - Aplicar configuração padrão no k3s"
	@echo "  make deploy-latest  - Aplicar versão latest"
	@echo "  make deploy-legacy  - Aplicar versão legacy"
	@echo "  make clean          - Remover recursos do k3s"
	@echo "  make help           - Mostrar esta ajuda"