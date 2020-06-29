# COVID-NL APP iOS Makefile

BREW_PATH=`which brew`
XCODE_TEMPLATE_PATH_SRC="tools/Xcode Templates/Component.xctemplate"
XCODE_TEMPLATE_PATH_DST="${HOME}/Library/Developer/Xcode/Templates/File Templates/COVID-NL"

# Creates xcodeproj
project:
	vendor/XcodeGen/.build/release/xcodegen
	open EN.xcodeproj

# Initializes dev environment
dev: install_xcode_templates install_dev_deps ignore_mocks_changes

install_xcode_templates:
	@echo "Installing latest xcode template"
	@mkdir -p ${XCODE_TEMPLATE_PATH_DST}
	@cp -rf ${XCODE_TEMPLATE_PATH_SRC} ${XCODE_TEMPLATE_PATH_DST}

ignore_mocks_changes:
	git update-index --skip-worktree Sources/ENCoreUnitTests/Mocks.swift 

install_dev_deps: check_homebrew_installed build_xcodegen build_swiftformat build_mockolo
	@echo "All dependencies are installed"
	@echo "You're ready to go"

check_homebrew_installed:
ifeq (, $(shell which brew))
 $(error "Please install homebrew (https://brew.sh) to continue")
endif

build_mockolo:
	cd vendor/mockolo && swift build -c release

build_xcodegen:
	cd vendor/XcodeGen && swift build -c release

build_swiftformat:
	cd vendor/SwiftFormat && swift build -c release
	$(shell sh tools/scripts/pre-commit.sh)

push_notification:
	@xcrun simctl push booted nl.rijksoverheid.en tools/push/payload.apns
