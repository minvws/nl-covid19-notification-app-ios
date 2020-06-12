#!/bin/bash

MOCKOLO_PATH="/usr/local/bin/mockolo"
REPO_ROOT=`git rev-parse --show-toplevel`
EXCLUDES="Images,Strings"

if [[ ! -f ${MOCKOLO_PATH} ]]; then
    echo "Unit tests rely on mock generation using Mockolo. Please run 'make dev' before continuing"
    exit 1
fi

SRC="${REPO_ROOT}/EN"
DEST="${REPO_ROOT}/ENUnitTests/Mocks.swift"
${MOCKOLO_PATH} -s ${SRC} -d ${DEST}.tmp -x ${EXCLUDES} -i EN

# Filter out import of ExposureManager
cat ${DEST}.tmp | grep -v "import ExposureNotification" > ${DEST}
rm ${DEST}.tmp