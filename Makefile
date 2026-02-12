# Makefile



# --- matrx-cli ─────────────────────────────────────
ship:
	@bash scripts/matrx/ship.sh "$(MSG)"

ship-minor:
	@bash scripts/matrx/ship.sh --minor "$(MSG)"

ship-major:
	@bash scripts/matrx/ship.sh --major "$(MSG)"

ship-status:
	@bash scripts/matrx/ship.sh status

ship-history:
	@bash scripts/matrx/ship.sh history

ship-update:
	@bash scripts/matrx/ship.sh update

ship-help:
	@bash scripts/matrx/ship.sh help

env-pull:
	@bash scripts/matrx/env-sync.sh pull

env-push:
	@bash scripts/matrx/env-sync.sh push

env-diff:
	@bash scripts/matrx/env-sync.sh diff

env-status:
	@bash scripts/matrx/env-sync.sh status

env-sync:
	@bash scripts/matrx/env-sync.sh sync

env-pull-force:
	@bash scripts/matrx/env-sync.sh pull --force

env-push-force:
	@bash scripts/matrx/env-sync.sh push --force

.PHONY: ship ship-minor ship-major ship-status ship-history ship-update ship-help env-pull env-push env-diff env-status env-sync env-pull-force env-push-force
