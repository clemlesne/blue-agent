.PHONY: test lint build-docker docs build-docs

flavor ?= null
instance ?= $(shell hostname | tr '[:upper:]' '[:lower:]')
version ?= null

test:
	@echo "➡️ Running Prettier"
	npx --yes prettier@2.8.8 --editorconfig --check .

	@echo "➡️ Running Hadolint"
	find . -name "Dockerfile*" -exec bash -c "echo 'File {}:' && hadolint {}" \;

	@echo "➡️ Running Azure Bicep Validate"
	az deployment sub validate \
		--location westeurope \
		--no-prompt \
		--parameters test/bicep/lint.example.json \
		--template-file src/bicep/main.bicep \
		--verbose

lint:
	@echo "➡️ Running Prettier"
	npx --yes prettier@2.8.8 --editorconfig --write .

	@echo "➡️ Running Hadolint"
	find . -name "Dockerfile*" -exec bash -c "echo 'File {}:' && hadolint {}" \;

	@echo "➡️ Running Bicep lint"
	az bicep lint \
		--file src/bicep/main.bicep \
		--verbose

deploy-bicep:
	@echo "➡️ Decrypting Bicep parameters"
	sops -d test/bicep/test.enc.json > test/bicep/test.json

	@echo "➡️ Deploying Bicep"
	az deployment sub create \
		--location westeurope \
		--name "$(instance)-$(flavor)" \
		--no-prompt \
		--parameters \
			test/bicep/test.json \
			imageFlavor=$(flavor) \
			imageVersion=$(version) \
		--template-file src/bicep/main.bicep

	@echo "➡️ Cleaning up Bicep parameters"
	rm test/bicep/test.json

	@echo "➡️ Starting init job"
	az containerapp job start \
		--name "apa-$(instance)-$(flavor)" \
		--resource-group "apa-$(instance)-$(flavor)"

destroy-bicep:
	@echo "➡️ Destroying"
	az group delete \
		--name "apa-$(instance)-$(flavor)" \
		--yes

integration:
	@bash test/integration.sh $(instance) $(flavor)

docs:
	cd docs && hugo server

build-docker:
	@bash cicd/docker-build-local.sh

build-docs:
	cd docs && hugo --gc --minify
