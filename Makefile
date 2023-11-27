.PHONY: test lint build-docker docs build-docs

test:
	@echo "➡️ Running Prettier..."
	npx --yes prettier@2.8.8 --editorconfig --check .

	@echo "➡️ Running Hadolint..."
	find . -name "Dockerfile*" -exec bash -c "echo 'File {}:' && hadolint {}" \;

lint:
	@echo "➡️ Running Prettier..."
	npx --yes prettier@2.8.8 --editorconfig --write .

	@echo "➡️ Running Hadolint..."
	find . -name "Dockerfile*" -exec bash -c "echo 'File {}:' && hadolint {}" \;

docs:
	cd docs && hugo server

build-docker:
	bash cicd/docker-build-local.sh

build-docs:
	cd docs && hugo --gc --minify
