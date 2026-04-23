.ONESHELL:
SHELL := /bin/bash
all: help

################################################################################
# PROJECT CONFIG
PROJECT_NAME := mantel

################################################################################
# APP
build: ## build the project
	swift build

build-release: ## build the project in release mode
	swift build -c release

build-macos: ## build for macOS (arm64)
	swift build -c release --arch arm64

run: ## run the project
	swift run

clean: ## clean build artifacts
	swift package clean
	rm -rf .build

################################################################################
# TEST
test: ## run all tests
	swift test

################################################################################
# LINT
lint: ## run swiftlint
	swiftlint

lint-fix: ## run swiftlint with auto-fix
	swiftlint --fix

format: ## format code with swift-format
	swift-format -i -r Sources/ Tests/

check: format lint test ## run all checks (format, lint, test)

################################################################################
# INSTALL
PLIST_NAME := com.dimfred.$(PROJECT_NAME).plist
PLIST_DST := ~/Library/LaunchAgents/$(PLIST_NAME)

install: build-release ## install binary and launchd service
	sudo cp .build/release/$(PROJECT_NAME) /usr/local/bin/
	cp $(PLIST_NAME) $(PLIST_DST)
	-launchctl bootout gui/$$(id -u) $(PLIST_DST)
	launchctl bootstrap gui/$$(id -u) $(PLIST_DST)

uninstall: ## uninstall binary and launchd service
	launchctl bootout gui/$$(id -u) $(PLIST_DST)
	sudo rm -f /usr/local/bin/$(PROJECT_NAME)
	rm -f $(PLIST_DST)

################################################################################
# RELEASE
release: version-patch release-github release-brew release-commit ## full release: bump + github + brew + commit

release-github: build-macos ## create GitHub release with platform binaries
	@VERSION=$$(grep -m1 'version:' Package.swift 2>/dev/null || grep -m1 '"[0-9]\+\.[0-9]\+\.[0-9]\+"' VERSION 2>/dev/null | tr -d '"' || echo "0.1.0"); \
	if [ -f VERSION ]; then VERSION=$$(cat VERSION); fi; \
	mkdir -p releases; \
	cp .build/arm64-apple-macosx/release/$(PROJECT_NAME) "releases/$(PROJECT_NAME)-v$${VERSION}-arm64"; \
	echo "Binary copied to releases/"; \
	if gh release view "v$$VERSION" >/dev/null 2>&1; then \
		echo "Release v$$VERSION already exists"; \
		read -p "Delete and recreate? [y/N] " -n 1 -r; \
		echo; \
		if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
			gh release delete "v$$VERSION" -y; \
		else \
			exit 1; \
		fi; \
	fi; \
	gh release create "v$$VERSION" \
		"releases/$(PROJECT_NAME)-v$${VERSION}-arm64" \
		--title "v$$VERSION" \
		--notes "$(PROJECT_NAME) v$$VERSION" \
		--latest; \
	echo "Released v$$VERSION"

release-brew: ## update brew formula, commit and push to homebrew-tap
	@VERSION=$$(cat VERSION); \
	MACOS_URL="https://github.com/Dimfred/$(PROJECT_NAME)/releases/download/v$${VERSION}/$(PROJECT_NAME)-v$${VERSION}-arm64"; \
	echo "Fetching macOS SHA..."; \
	MACOS_SHA=$$(curl -sL "$$MACOS_URL" | shasum -a 256 | cut -d' ' -f1); \
	echo "macOS SHA256: $$MACOS_SHA"; \
	sed -i '' "s|version \".*\"|version \"$$VERSION\"|" package/brew/$(PROJECT_NAME).rb; \
	sed -i '' "s|url \".*macos-.*\"|url \"$$MACOS_URL\"|" package/brew/$(PROJECT_NAME).rb; \
	sed -i '' "/$(PROJECT_NAME)-v/{n;s|sha256 \".*\"|sha256 \"$$MACOS_SHA\"|;}" package/brew/$(PROJECT_NAME).rb; \
	echo "Formula updated for v$$VERSION"; \
	cp package/brew/$(PROJECT_NAME).rb ../homebrew-tap/Formula/; \
	cd ../homebrew-tap && git add . && git commit -m "Update $(PROJECT_NAME) to v$$VERSION" && git push; \
	echo "Pushed to homebrew-tap"

release-commit: ## commit and push package updates
	@VERSION=$$(cat VERSION); \
	git add package/; \
	git commit --amend --no-edit; \
	git push; \
	echo "Pushed release v$$VERSION"

version-patch: ## bump patch version (0.1.0 -> 0.1.1)
	@if [ ! -f VERSION ]; then echo "0.1.0" > VERSION; fi; \
	CURRENT=$$(cat VERSION); \
	IFS='.' read -r MAJOR MINOR PATCH <<< "$$CURRENT"; \
	NEW_PATCH=$$((PATCH + 1)); \
	NEW_VERSION="$$MAJOR.$$MINOR.$$NEW_PATCH"; \
	echo "$$NEW_VERSION" > VERSION; \
	echo "Version bumped from $$CURRENT to $$NEW_VERSION"; \
	git add VERSION; \
	git commit -m "chore: bump v$$NEW_VERSION"; \
	echo "Committed version bump"

################################################################################
# INIT
init: ## initialize dev environment
	brew install swiftlint swift-format

################################################################################
# HELP
help: ## print this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'
