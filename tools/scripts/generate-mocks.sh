#!/bin/bash

GIT=`which git`
REPO_ROOT=`${GIT} rev-parse --show-toplevel`
MOCKOLO_PATH="${REPO_ROOT}/vendor/mockolo/.build/release/mockolo"
EXCLUDES="Images,Strings"

echo ${MOCKOLO_PATH}

SRC="${REPO_ROOT}/Sources/ENCore"
DEST="${REPO_ROOT}/Sources/ENCoreTests/Mocks.swift"
${MOCKOLO_PATH} -s ${SRC} -d ${DEST} -x ${EXCLUDES} -i ENCore