# COVID-NL APP iOS Makefile

BREW_PATH=`which brew`
XCODE_TEMPLATE_PATH_SRC="tools/Xcode Templates/Component.xctemplate"
XCODE_TEMPLATE_PATH_DST="${HOME}/Library/Developer/Xcode/Templates/File Templates/COVID-NL"

# Creates xcodeproj
project: 
	xcodegen
	open EN.xcodeproj

# Initializes dev environment
dev: install_xcode_templates install_dev_deps ignore_mocks_changes

install_xcode_templates:
	@echo "Installing latest xcode template"
	@mkdir -p ${XCODE_TEMPLATE_PATH_DST}
	@cp -rf ${XCODE_TEMPLATE_PATH_SRC} ${XCODE_TEMPLATE_PATH_DST}

ignore_mocks_changes:
	git update-index --skip-worktree ENUnitTests/Mocks.swift 

install_dev_deps: check_homebrew_installed install_xcodegen install_mockolo install_carthage run_carthage
	@echo "All dependencies are installed"
	@echo "You're ready to go"

check_homebrew_installed:
ifeq (, $(shell which brew))
 $(error "Please install homebrew (https://brew.sh) to continue")
endif

install_xcodegen:
# install xcodegen, used for project generation
ifeq (, $(shell which xcodegen))
	@echo "Installing xcodegen"
	@brew install xcodegen
endif

install_mockolo:
# install mockolo, used for unit tests
ifeq (, $(shell which mockolo))
	@echo "Installing mockolo"
	@brew install mockolo
endif

install_carthage:
# install carthage, used for swift package management
ifeq (, $(shell which carthage))
	@echo "Installing carthage"
	@brew install carthage
endif

run_carthage:
	@carthage bootstrap --platform ios
