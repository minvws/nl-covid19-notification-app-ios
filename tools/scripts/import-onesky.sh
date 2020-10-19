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
	ONESKY_LOCALIZABLE="$ONESKY_ROOT/Localizable.strings"
	ORIGIN_LOCALIZABLE="$ONESKY_LOCALIZABLE/$language/Localizable.strings"
	ENCORE_LOCALIZABLE="$SOURCE_ROOT/ENCore/Resources/${language}.lproj/Localizable.strings"

	ONESKY_MAIN="$ONESKY_ROOT/Main.strings" 	
	ORIGIN_MAIN="$ONESKY_MAIN/$language/Main.strings"
	EN_LOCALIZABLE="$SOURCE_ROOT/EN/Resources/${language}.lproj/Localizable.strings"		
	
	echo "Copying Localizable.strings to \"ENCore/../$language.lproj/Localizable.strings\""
	cp "$ORIGIN_LOCALIZABLE" "$ENCORE_LOCALIZABLE"
	
	echo "Copying Main.strings to \"EN/.../$language.lproj/Localizable.strings\""
	cp "$ORIGIN_MAIN" "$EN_LOCALIZABLE"
	
	if [ "$language" = "en" ]; then
		EN_BASE_LOCALIZABLE="$SOURCE_ROOT/EN/Resources/Base.lproj/Localizable.strings"		
		ENCORE_BASE_LOCALIZABLE="$SOURCE_ROOT/ENCore/Resources/Base.lproj/Localizable.strings"
	
		echo "Copying Localizable.strings to \"ENCore/../Base.lproj/Localizable.strings\""
		cp "$ORIGIN_LOCALIZABLE" "$ENCORE_BASE_LOCALIZABLE"
		echo "Copying Main.strings to \"EN/.../Base.lproj/Localizable.strings\""
		cp "$ORIGIN_MAIN" "$EN_BASE_LOCALIZABLE"	
	fi
done
