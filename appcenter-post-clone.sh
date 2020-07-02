#!/usr/bin/env bash

env

if [ -z "$USE_DEVELOPER_MENU" ]
then
      USE_DEVELOPER_MENU=true
fi


if [ -z "$NETWORK_CONFIGURATION" ]
then
      NETWORK_CONFIGURATION="LabTest"
fi

if [ -z "$LOG_LEVEL" ]
then
      LOG_LEVEL="debug"
fi

brew install yq
yq w -i project.yml "targets.EN.settings.base.NETWORK_CONFIGURATION" ${NETWORK_CONFIGURATION}
yq w -i project.yml "targets.EN.settings.base.LOG_LEVEL" ${LOG_LEVEL}

if [ -n "$USE_DEVELOPER_MENU" ]
then
	yq w -i project.yml -- "targets.ENCore.settings.base.OTHER_SWIFT_FLAGS" -DUSE_DEVELOPER_MENU
fi

cat project.yml

make install_dev_deps && make generate_project
