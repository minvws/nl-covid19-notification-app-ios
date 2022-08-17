#!/usr/bin/env bash

env

brew update
brew install yq

BUNDLE_VERSION=$(yq e ".targets.EN.info.properties.CFBundleShortVersionString" project.yml)
BUNDLE_VERSION=${BUNDLE_VERSION%%-tst}
BUNDLE_VERSION=${BUNDLE_VERSION%%-tst-13-5}
BUNDLE_VERSION=${BUNDLE_VERSION%%-acc}
BUNDLE_VERSION=${BUNDLE_VERSION%%-acc-13-5}

if [ -z "$NETWORK_CONFIGURATION" ]
then
      NETWORK_CONFIGURATION="Test"
fi

if [ -z "$LOG_LEVEL" ]
then
      LOG_LEVEL="debug"
fi

if [ -z "$BUILD_ID" ]
then
      BUILD_ID="$(( $GITHUB_RUN_NUMBER + 179478 ))"
fi

if [ -z "$BUNDLE_IDENTIFIER" ]
then
      BUNDLE_IDENTIFIER="nl.rijksoverheid.en"
fi

if [ -z "$BUNDLE_SHORT_VERSION" ]
then
      BUNDLE_SHORT_VERSION="${BUNDLE_VERSION}"
else
      BUNDLE_SHORT_VERSION="${BUNDLE_VERSION}-${BUNDLE_SHORT_VERSION}"
fi

if [ -z "$BUNDLE_DISPLAY_NAME" ]
then
      BUNDLE_DISPLAY_NAME="🐞 CoronaMelder"
fi

if [ -z "$RELEASE_PROVISIONING_PROFILE" ]
then
      RELEASE_PROVISIONING_PROFILE="EN Tracing development"
fi

if [ -z "$SHARE_LOGS_ENABLED" ]
then
      SHARE_LOGS_ENABLED="false"
fi

if [ -z "$EN_DEVELOPER_REGION" ]
then
      EN_DEVELOPER_REGION="TEST_NL_TEST"
fi

yq e ".targets.EN.info.properties.SHARE_LOGS_ENABLED = ${SHARE_LOGS_ENABLED}" -i project.yml
yq e ".targets.EN.info.properties.NETWORK_CONFIGURATION = \"${NETWORK_CONFIGURATION}\"" -i project.yml
yq e ".targets.EN.info.properties.LOG_LEVEL = \"${LOG_LEVEL}\"" -i project.yml
yq e ".targets.EN.info.properties.CFBundleShortVersionString = \"${BUNDLE_SHORT_VERSION}\"" -i project.yml
yq e ".targets.EN.info.properties.CFBundleDisplayName = \"${BUNDLE_DISPLAY_NAME}\"" -i project.yml
yq e ".targets.EN.info.properties.CFBundleVersion = \"${BUILD_ID}\"" -i project.yml
yq e ".targets.EN.info.properties.ENDeveloperRegion = \"${EN_DEVELOPER_REGION}\"" -i project.yml
yq e ".targets.EN.settings.base.PRODUCT_BUNDLE_IDENTIFIER = \"${BUNDLE_IDENTIFIER}\"" -i project.yml
yq e ".targets.EN.settings.configs.Release.PROVISIONING_PROFILE_SPECIFIER = \"${RELEASE_PROVISIONING_PROFILE}\"" -i project.yml
yq e ".targets.EN.info.properties.GitHash = \"$(git rev-parse --short=7 HEAD)\"" -i project.yml

if [ ! -z "$USE_DEVELOPER_MENU" ]
then
    yq e ".targets.ENCore.settings.base.OTHER_SWIFT_FLAGS = \"-DUSE_DEVELOPER_MENU\"" -i project.yml
else
    yq e "del(.targets.ENCore.settings.base.OTHER_SWIFT_FLAGS)" -i project.yml
fi

cat project.yml

if [ ! -f vendor/XcodeGen/.build/release/xcodegen ] || [ ! -f vendor/mockolo/.build/release/mockolo ];
then
      make install_ci_deps
fi
make generate_project
