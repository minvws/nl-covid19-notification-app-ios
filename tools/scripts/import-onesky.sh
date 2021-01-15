#!/bin/bash

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "Usage: $0 path-to-onesky-folder-without-spaces"


# Remove spaces from passed path
ONESKY_ROOT=$(printf %q "$1")
CURRENT_DIR=`pwd`
SOURCE_ROOT="$CURRENT_DIR/../../Sources"

LANGUAGES=("ar" "en" "bg-BG" "de" "es" "fr" "nl" "pl" "ro" "tr")

for language in ${LANGUAGES[@]}; do
	ONESKY_LOCALIZABLE="$ONESKY_ROOT/"
	ORIGIN_LOCALIZABLE="$ONESKY_LOCALIZABLE/$language/Localizable.strings"
	ENCORE_LOCALIZABLE="$SOURCE_ROOT/ENCore/Resources/${language}.lproj/Localizable.strings"
	
	echo "Copying Localizable.strings from \"$ORIGIN_LOCALIZABLE\"  to \"ENCore/../$language.lproj/Localizable.strings\""
	cp "$ORIGIN_LOCALIZABLE" "$ENCORE_LOCALIZABLE"
	
	if [ "$language" = "en" ]; then
		ENCORE_BASE_LOCALIZABLE="$SOURCE_ROOT/ENCore/Resources/Base.lproj/Localizable.strings"
	
		echo "Copying Localizable.strings to \"ENCore/../Base.lproj/Localizable.strings\""
		cp "$ORIGIN_LOCALIZABLE" "$ENCORE_BASE_LOCALIZABLE"
	fi
done
