export GO111MODULE ?= on

PACKAGES = $(shell go list ./...)
PACKAGES_PATH = $(shell go list -f '{{ .Dir }}' ./...)
LATEST_DEPENDENCIES = $(shell go list -f '{{if not (or .Main .Indirect)}}{{.Path}}{{end}}' -m all)

APP_NAME=zero
VERSION := 0.0.1

.PHONY: all
all: check_tools ensure-deps fmt imports linter test

.PHONY: check_tools
check_tools:
	@type "golangci-lint" > /dev/null 2>&1 || echo 'Please install golangci-lint. : https://golangci-lint.run/usage/install/#local-installation'
	@type "goimports" > /dev/null 2>&1 || echo 'Please install goimports: go get golang.org/x/tools/cmd/goimports'

.PHONY: update-libs
update-libs:
	@echo "=> Updating libraries to latest version"
	@go get $(LATEST_DEPENDENCIES)

.PHONY: ensure-deps
ensure-deps:
	@echo "=> Syncing dependencies with go mod tidy"
	@go mod tidy -compat=1.17

.PHONY: fmt
fmt:
	@echo "=> Executing go fmt"
	@go fmt $(PACKAGES)

.PHONY: imports
imports:
	@echo "=> Executing goimports"
	@goimports -w $(PACKAGES_PATH)

# Runs golangci-lint with arguments if provided.
.PHONY: linter
linter:
	@echo "=> Executing golangci-lint$(if $(FLAGS), with flags: $(FLAGS))"
	@golangci-lint run ./... $(FLAGS)

.PHONY: test
test:
	@echo "=> Running tests"
	@go test ./... -covermode=atomic -coverpkg=./... -count=1 -race

.PHONY: coverage
coverage:
	@echo "=> Running tests and generating report"
	@go test ./... -covermode=atomic -coverprofile=/tmp/coverage.out -coverpkg=./... -count=1
	@go tool cover -html=/tmp/coverage.out

.PHONY: test-cover
test-cover: service-up coverage service-down

build:
	@echo "==> Building..."
	go build -o ./$(APP_NAME) ./cmd

setup: all build

run:
	@./zero
