# COVID-NL APP iOS Makefile

XCODE_TEMPLATE_PATH_SRC="tools/Xcode Templates/Component.xctemplate"
XCODE_TEMPLATE_PATH_DST="${HOME}/Library/Developer/Xcode/Templates/File Templates/COVID-NL"

# Creates xcodeproj
project:
	vendor/XcodeGen/.build/release/xcodegen
	open EN.xcodeproj

generate_project:
	vendor/XcodeGen/.build/release/xcodegen

# Initializes dev environment
dev: install_xcode_templates install_dev_deps ignore_mocks_changes

install_xcode_templates:
	@echo "Installing latest xcode template"
	@mkdir -p ${XCODE_TEMPLATE_PATH_DST}
	@cp -rf ${XCODE_TEMPLATE_PATH_SRC} ${XCODE_TEMPLATE_PATH_DST}

ignore_mocks_changes:
	git update-index --skip-worktree Sources/ENCoreUnitTests/Mocks.swift 

install_dev_deps: build_xcodegen build_swiftformat build_mockolo build_openssl
	@echo "All dependencies are installed"
	@echo "You're ready to go"

build_mockolo:
	cd vendor/mockolo && swift build -c release

build_xcodegen:
	cd vendor/XcodeGen && swift build -c release -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.13"

build_swiftformat:
	cd vendor/SwiftFormat && swift build -c release
	$(shell sh tools/scripts/pre-commit.sh)

build_openssl:
	cd vendor/OpenSSL-for-iPhone && ./build-libssl.sh && ./create-openssl-framework.sh

push_notification:
	@xcrun simctl push booted nl.rijksoverheid.en tools/push/payload.apns

clean_snapshots:
	@echo "Removing all __Snapshot__ folders"
	@rm -rf `find Sources/ -type d -name __Snapshots__`
	@echo "Re-run tests for current Snapshot tests to be generated"
