#!/bin/bash

MOCKOLO_PATH=`which mockolo`
GIT=`which git`
REPO_ROOT=`${GIT} rev-parse --show-toplevel`
EXCLUDES="Images,Strings"

if [[ ! -f ${MOCKOLO_PATH} ]]; then
    echo "Unit tests rely on mock generation using Mockolo. Please run 'make dev' before continuing"
    exit 1
fi

SRC="${REPO_ROOT}/Sources/ENCore"
DEST="${REPO_ROOT}/Sources/ENCoreUnitTests/Mocks.swift"
${MOCKOLO_PATH} -s ${SRC} -d ${DEST} -x ${EXCLUDES} -i ENCore
