.PHONY: help setup system zsh git docker apps devtools workspace verify \
        dry-run lint clean test-docker test-docker-live

SHELL := /bin/bash

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

setup: ## Run full setup (interactive)
	bash setup.sh

dry-run: ## Run full setup in dry-run mode
	bash setup.sh --dry-run

system: ## Phase 01: System packages
	bash setup.sh --phase=01

zsh: ## Phase 02: ZSH + dotfiles
	bash setup.sh --phase=02

git: ## Phase 03: Git + GitHub CLI
	bash setup.sh --phase=03

docker: ## Phase 04: Docker + quay.io
	bash setup.sh --phase=04

apps: ## Phase 05: Desktop applications
	bash setup.sh --phase=05

devtools: ## Phase 06: Dev tools (nvm, bun)
	bash setup.sh --phase=06

workspace: ## Phase 07: Clone workspace repos
	bash setup.sh --phase=07

verify: ## Phase 08: Post-install verification
	bash setup.sh --phase=08

lint: ## Run ShellCheck on all scripts
	shellcheck setup.sh scripts/*.sh

clean: ## Remove stow symlinks
	cd dotfiles && stow -t ~ -D zsh ghostty 2>/dev/null || true

UBUNTU ?= 20.04

test-docker: ## Dry-run in Docker (UBUNTU=20.04|22.04|24.04)
	docker build --build-arg UBUNTU_VERSION=$(UBUNTU) \
	-f Dockerfile.test -t laptop-setup-test:$(UBUNTU) .
	docker run --rm laptop-setup-test:$(UBUNTU)

test-docker-live: ## Interactive shell in Docker for manual testing
	docker build --build-arg UBUNTU_VERSION=$(UBUNTU) \
	-f Dockerfile.test -t laptop-setup-test:$(UBUNTU) .
	docker run --rm -it laptop-setup-test:$(UBUNTU) bash
