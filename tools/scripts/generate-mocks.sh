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
${MOCKOLO_PATH} -s ${SRC} -d ${DEST} -x ${EXCLUDES} -i EN

# Shield import of ExposureManager
ORIGINAL="import ExposureNotification"
REPLACEMENT='#if canImport(ExposureNotification) \
    import ExposureNotification \
#endif'

sed -i '' "s/${ORIGINAL}/${REPLACEMENT}/g" ${DEST}

# Mark EMManaging class as iOS 13.5 only
ORIGINAL="class ENManagingMock: ENManaging"
REPLACEMENT='@available(iOS 13.5, *) \
class ENManagingMock: ENManaging'

sed -i '' "s/${ORIGINAL}/${REPLACEMENT}/g" ${DEST}
