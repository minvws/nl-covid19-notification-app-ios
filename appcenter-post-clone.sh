#!/usr/bin/env bash

echo $USE_DEVELOPER_MENU
echo $NETWORK_CONFIGURATION

env

if [ -z "$USE_DEVELOPER_MENU" ]
then
      USE_DEVELOPER_MENU=true
fi


if [ -z "$NETWORK_CONFIGURATION" ]
then
      NETWORK_CONFIGURATION="LabTest"
fi

brew install yq
yq w -i project.yml "targets.ENCore.settings.base.USE_DEVELOPER_MENU" ${USE_DEVELOPER_MENU}
yq w -i project.yml "targets.EN.settings.base.NETWORK_CONFIGURATION" ${NETWORK_CONFIGURATION}

make install_dev_deps && make generate_project
