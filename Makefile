.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
SHELLSCRIPTS := bootstrap.sh tui.sh lib/*.sh macos/*.sh .githooks/pre-commit

.PHONY: help bootstrap fresh migrate lint test doctor scan

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Install deps and launch the TUI
	./bootstrap.sh

fresh: ## Run the TUI (fresh setup). Dry-run: make fresh DRY_RUN=1
	DRY_RUN=$(DRY_RUN) ./tui.sh

migrate: ## Run the TUI straight into migrate (same entry point)
	./tui.sh

lint: ## shellcheck all shell scripts
	shellcheck $(SHELLSCRIPTS)

test: ## Run the bats test suite
	bats test

scan: ## Scan the whole tree for secrets (hard gate before pushing)
	gitleaks detect --source . --no-git --redact --verbose

doctor: ## Report config drift (nonzero if chezmoi would change files)
	@chezmoi verify && echo "doctor: no drift" || { echo "doctor: drift detected" >&2; exit 1; }
