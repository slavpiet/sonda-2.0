.PHONY: help
help: ## Show this help message
	@echo 'Sonda 2.0 - Network Monitoring Stack'
	@echo ''
	@echo 'Usage:'
	@echo '  make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: check
check: ## Validate project structure
	@echo "Validating project structure..."
	@bash tests/test-structure.sh

.PHONY: install-deps
install-deps: ## Install Python and Ansible dependencies
	pip3 install -r ansible/requirements.txt
	ansible-galaxy collection install -r ansible/requirements.yml

.PHONY: lint
lint: ## Run ansible-lint on playbooks
	ansible-lint ansible/playbooks/

.PHONY: syntax-check
syntax-check: ## Check Ansible playbook syntax
	ansible-playbook ansible/playbooks/site.yml --syntax-check

.PHONY: test-connection
test-connection: ## Test SSH connection to servers
	ansible -i ansible/inventories/development all -m ping

# DEPLOYMENT TARGETS

.PHONY: deploy-dev
deploy-dev: ## Deploy to development environment
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/site.yml

.PHONY: deploy-staging
deploy-staging: ## Deploy to staging environment
	ansible-playbook -i ansible/inventories/staging \
		ansible/playbooks/site.yml

.PHONY: deploy-prod
deploy-prod: ## Deploy to production environment
	@echo "⚠️  WARNING: Deploying to PRODUCTION"
	@read -p "Are you sure? Type 'yes' to continue: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		ansible-playbook -i ansible/inventories/production \
			ansible/playbooks/site.yml; \
	else \
		echo "Deployment cancelled."; \
	fi

# STAGE-SPECIFIC DEPLOYMENT

.PHONY: stage1
stage1: ## Run Stage 1: Prepare (system, storage, docker)
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/01_prepare.yml

.PHONY: stage2
stage2: ## Run Stage 2: Deploy (compose stack)
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/02_deploy.yml

.PHONY: stage3
stage3: ## Run Stage 3: Configure (post-deployment)
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/03_configure.yml

.PHONY: stage4
stage4: ## Run Stage 4: Validate (health checks)
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/04_validate.yml

# UTILITIES

.PHONY: start
start: ## Start all services
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/utilities/start.yml

.PHONY: stop
stop: ## Stop all services
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/utilities/stop.yml

.PHONY: restart
restart: ## Restart all services
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/utilities/restart.yml

.PHONY: logs
logs: ## Fetch logs from all services
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/utilities/logs.yml

.PHONY: validate
validate: ## Run health checks
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/04_validate.yml

.PHONY: cleanup
cleanup: ## Clean up deployment
	ansible-playbook -i ansible/inventories/development \
		ansible/playbooks/utilities/cleanup.yml

# LOCAL COMPOSE TESTING

.PHONY: compose-up
compose-up: ## Test compose locally (no Ansible)
	@echo "Starting services with docker compose..."
	cd compose && docker compose up -d

.PHONY: compose-down
compose-down: ## Stop local compose
	cd compose && docker compose down

.PHONY: compose-logs
compose-logs: ## View compose logs
	cd compose && docker compose logs -f

# TESTING

.PHONY: test
test: check syntax-check ## Run all tests

.PHONY: molecule
molecule: ## Run molecule tests
	cd ansible/roles/common && molecule test
