#!/usr/bin/env bash

env

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
      BUILD_ID="1"
fi

brew install yq
yq w -i project.yml "targets.EN.settings.base.NETWORK_CONFIGURATION" ${NETWORK_CONFIGURATION}
yq w -i project.yml "targets.EN.settings.base.LOG_LEVEL" ${LOG_LEVEL}
yq w -i project.yml --tag '!!str' "targets.EN.info.properties.CFBundleVersion" ${BUILD_ID}

if [ ! -z "$USE_DEVELOPER_MENU" ]
then
	yq w -i project.yml -- "targets.ENCore.settings.base.OTHER_SWIFT_FLAGS" -DUSE_DEVELOPER_MENU
fi

cat project.yml

make install_ci_deps && make generate_project