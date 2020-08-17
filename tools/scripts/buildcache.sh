#/bin/sh

if [ "$1" == "copy" ];
then
	if [ ! -d cache ]; 
	then
		mkdir cache
	fi
	if [ -f vendor/XcodeGen/.build/release/xcodegen ];
	then
		cp vendor/XcodeGen/.build/release/xcodegen cache/
	fi

	if [ -f vendor/mockolo/.build/release/mockolo ];
	then
		cp vendor/mockolo/.build/release/mockolo cache/
	fi
else 
	if [ -f cache/xcodegen ];
	then
		mkdir -p vendor/XcodeGen/.build/release
		cp cache/xcodegen vendor/XcodeGen/.build/release/xcodegen
	fi
	if [ -f cache/mockolo ];
	then
		mkdir -p vendor/mockolo/.build/release
		cp cache/mockolo vendor/mockolo/.build/release/mockolo
	fi
fi


