# COVID-NL APP iOS Makefile

BREW_PATH="/usr/local/bin/brew2"
XCODE_TEMPLATE_PATH_SRC="tools/Xcode Templates/Component.xctemplate"
XCODE_TEMPLATE_PATH_DST="~/Library/Developer/Xcode/Templates/File Templates/COVID-NL"

# Creates xcodeproj
project: 
	xcodegen
	open EN.xcodeproj

# Initializes dev environment
dev: install_xcode_templates install_dev_deps

install_xcode_templates:
	@echo "Installing latest xcode template"
	@mkdir -p ${XCODE_TEMPLATE_PATH_DST}
	@cp -rf ${XCODE_TEMPLATE_PATH_SRC} ${XCODE_TEMPLATE_PATH_DST}

install_dev_deps:
ifeq (, $(shell which brew))
 $(error "Please install homebrew (https://brew.sh) to continue")
endif

# install xcodegen, used for unit tests
ifeq (, $(shell which xcodegen))
	echo "Installing xcodegen"
	brew install xcodegen
endif

# install mockolo, used for unit tests
ifeq (, $(shell which mockolo))
	echo "Installing mockolo"
	brew install mockolo
endif

	@echo "All dependencies are installed"
	@echo "You're ready to go"
