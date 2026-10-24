.ONESHELL:
SHELL := /bin/bash
all: help
PROJECT_NAME := mantel

################################################################################
# APP
SWIFT_SOURCES := Package.swift Sources Tests

check: lint docs-lint test ## lint, docs-lint, test; must be green before every commit

# Symlink, not core.hooksPath: that would turn off other hooks in .git/hooks (e.g. git-lfs).
hooks: ## install the git pre-commit hook (runs make check)
	ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit

lint: ## format + safe autofixes + lint + typecheck, fails on what's left
	swift format format --in-place --recursive --parallel $(SWIFT_SOURCES)
	swift format lint --strict --recursive --parallel $(SWIFT_SOURCES)
	swift build --build-tests -Xswiftc -warnings-as-errors

test: ## run tests, filter with ARGS=<pattern>
	swift test $(if $(ARGS),--filter $(ARGS))

dev: run ## run the app in dev mode

run: ## run the project
	swift run

build: ## build the project
	swift build

build-release: ## build the project in release mode
	swift build -c release

clean: ## clean build artifacts
	swift package clean
	rm -rf .build


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

release-github: build-release
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

release-brew:
	@VERSION=$$(cat VERSION); \
	MACOS_URL="https://github.com/Dimfred/$(PROJECT_NAME)/releases/download/v$${VERSION}/$(PROJECT_NAME)-v$${VERSION}-arm64"; \
	MACOS_BIN="releases/$(PROJECT_NAME)-v$${VERSION}-arm64"; \
	test -f "$$MACOS_BIN" || { echo "Missing $$MACOS_BIN, run make release-github first"; exit 1; }; \
	MACOS_SHA=$$(shasum -a 256 "$$MACOS_BIN" | cut -d' ' -f1); \
	echo "macOS SHA256: $$MACOS_SHA"; \
	sed -i '' "s|^  url \".*\"|  url \"$$MACOS_URL\"|" package/brew/$(PROJECT_NAME).rb; \
	sed -i '' "s|^  version \".*\"|  version \"$$VERSION\"|" package/brew/$(PROJECT_NAME).rb; \
	sed -i '' "s|^  sha256 \".*\"|  sha256 \"$$MACOS_SHA\"|" package/brew/$(PROJECT_NAME).rb; \
	echo "Formula updated for v$$VERSION"; \
	mkdir -p ../homebrew-tap/Formula; \
	cp package/brew/$(PROJECT_NAME).rb ../homebrew-tap/Formula/; \
	cd ../homebrew-tap; \
	if [ -f Casks/$(PROJECT_NAME).rb ]; then git rm -q Casks/$(PROJECT_NAME).rb; fi; \
	git add . && git commit -m "Update $(PROJECT_NAME) to v$$VERSION" && git push; \
	echo "Pushed to homebrew-tap"

release-commit:
	@VERSION=$$(cat VERSION); \
	git add package/; \
	git commit --amend --no-edit; \
	git push; \
	echo "Pushed release v$$VERSION"

################################################################################
# DOCS
docs-lint: ## check task format, task / feature / architecture links
	./scripts/docs-lint.sh docs

feature-gaps: ## list FEATURES.md sections no task links to
	./scripts/feature-gaps.sh docs

#########################################################################
# HELP
help: ## print this help
	@awk '/^##+$$/ { \
		getline; \
		if ($$0 ~ /^# /) { \
			gsub(/^# /, ""); \
			printf "\n\033[1;34m%s\033[0m\n", $$0; \
		} \
	} \
	/^[a-zA-Z0-9_-]+:.*?## / { \
		split($$0, a, ":.*?## "); \
		printf "  \033[32m%-28s\033[0m %s\n", a[1], a[2]; \
	}' $(MAKEFILE_LIST)
