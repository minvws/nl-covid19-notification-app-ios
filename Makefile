# COVID-NL APP iOS Makefile

XCODE_TEMPLATE_PATH_SRC="tools/Xcode Templates/Component.xctemplate"
XCODE_TEMPLATE_PATH_DST="${HOME}/Library/Developer/Xcode/Templates/File Templates/COVID-NL"

EN_MOCKS_PATH="Sources/ENTests/Mocks.swift"
EN_CORE_MOCKS_PATH="Sources/ENCoreTests/Mocks.swift"

# Creates xcodeproj
project: touch_mock_files_if_needed
	vendor/XcodeGen/.build/release/xcodegen
	open EN.xcodeproj

generate_project: touch_mock_files_if_needed
	vendor/XcodeGen/.build/release/xcodegen

# Initializes dev environment
dev: install_xcode_templates install_dev_deps

install_xcode_templates:
	@echo "Installing latest xcode template"
	@mkdir -p ${XCODE_TEMPLATE_PATH_DST}
	@cp -rf ${XCODE_TEMPLATE_PATH_SRC} ${XCODE_TEMPLATE_PATH_DST}

install_dev_deps: build_xcodegen build_swiftformat build_mockolo
	@echo "All dependencies are installed"
	@echo "You're ready to go"

install_ci_deps: build_xcodegen build_mockolo
	@echo "All CI dependencies are installed"

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

buildinfo:
	@echo "Generating buildinfo.."
	bash -c tools/scripts/buildinfo.sh release > .buildinfo
	cat .buildinfo

touch_mock_files_if_needed:
ifneq ($(wildcard ${EN_MOCKS_PATH}), "")
	@touch ${EN_MOCKS_PATH}
endif
ifneq ($(wildcard ${EN_CORE_MOCKS_PATH}), "")
	@touch ${EN_CORE_MOCKS_PATH}
endif
