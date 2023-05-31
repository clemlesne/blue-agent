.PHONY: test

test:
	npx --yes prettier@2.8.8 --write .
	find . -name "Dockerfile*" -exec hadolint {} \;
