.PHONY: test lint build-docker docs build-docs

# Required parameters
flavor ?= null
version ?= null
# Dynamic parameters
prefix ?= $(shell hostname | tr "[:upper:]" "[:lower:]" | tr "." "-")
deployment_name ?= $(prefix)-$(flavor)
# Deployment outputs
bicep_outputs ?= $(shell az deployment sub show --name "$(deployment_name)" | yq '.properties.outputs')
job_name ?= $(shell echo $(bicep_outputs) | yq '.jobName.value')
rg_name ?= $(shell echo $(bicep_outputs) | yq '.rgName.value')
# Container App Job environment
container_specs ?= $(shell az containerapp job show --name "$(job_name)" --resource-group "$(rg_name)" | yq '.properties.template.containers[0]')
job_image ?= $(shell echo $(container_specs) | yq '.image')
job_env ?= $(shell echo $(container_specs) | yq '.env | map("\(.name)=\(.value // \"secretref:\" + .secretRef)") | .[]')

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
	$(MAKE) deploy-bicep-iac

	@echo "➡️ Wait for the Bicep output to be available"
	sleep 10

	$(MAKE) deploy-bicep-template

deploy-bicep-iac:
	@echo "➡️ Decrypting Bicep parameters"
	sops -d test/bicep/test.enc.json > test/bicep/test.json

	@echo "➡️ Deploying Bicep"
	az deployment sub create \
		--location westeurope \
		--name $(deployment_name) \
		--no-prompt \
		--parameters \
			test/bicep/test.json \
			imageFlavor=$(flavor) \
			imageVersion=$(version) \
		--template-file src/bicep/main.bicep

	@echo "➡️ Cleaning up Bicep parameters"
	rm test/bicep/test.json

deploy-bicep-template:
	@echo "➡️ Starting template job"
	az containerapp job start \
		--env-vars $(job_env) AZP_TEMPLATE_JOB=1 \
		--image $(job_image) \
		--name $(job_name) \
		--resource-group $(rg_name)

destroy-bicep:
	@echo "➡️ Destroying Azure resources"
	az group delete \
		--name "$(rg_name)" \
		--yes

integration:
	$(MAKE) integration-run
	$(MAKE) integration-cleanup

integration-run:
	@bash test/integration-run.sh $(prefix) $(flavor) $(version) $(job_name)

integration-cleanup:
	@bash test/integration-cleanup.sh $(job_name)

docs:
	cd docs && hugo server

build-docker:
	@bash cicd/docker-build-local.sh

build-docs:
	cd docs && hugo --gc --minify
