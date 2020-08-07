#!/bin/bash

export BUILD_CONFIGURATION="$1"; shift
git_version=$(git log -1 --format="%h")
git_branch=$(git symbolic-ref --short -q HEAD)
git_tag=$(git describe --tags --exact-match 2>/dev/null)

build_time=$(date)
git_branch_or_tag="${git_branch:-${git_tag}}"

info_plist="${GITHUB_WORKSPACE}/Sources/EN/Resources/Info.plist"

cat <<EOF
Build-Architecture: $(uname -m)
Build-Origin: $(uname -a)
Build-Date: $(date -R)
Build-Configuration: ${BUILD_CONFIGURATION}
EOF

printf 'CI:\n'
cat <<EOF
  CI-Workflow: ${GITHUB_WORKFLOW}
  CI-Runid: ${GITHUB_RUN_ID}
  CI-Runnumber ${GITHUB_RUN_NUMBER}
  CI-Actor: ${GITHUB_ACTOR}
  CI-Repository: ${GITHUB_REPOSITORY}
  CI-Eventname: ${GITHUB_EVENT_NAME}
  CI-Workspace: ${GITHUB_WORKSPACE}
  CI-SHA: ${GITHUB_SHA}
  CI-Ref: ${GITHUB_REF}
EOF


printf 'Installed-Build-Depends:\n'
cat <<EOF
  swift_version: $(swift --version| grep -m1 -)
  xcodegen_version: $(vendor/XcodeGen/.build/release/XcodeGen --version)
  mockolo_version: TODO
EOF


printf 'Environment:\n'

# whitelist stolen from Debian's dpkg:
# https://anonscm.debian.org/git/dpkg/dpkg.git/tree/scripts/Dpkg/Build/Info.pm#n50
ENV_WHITELIST=
# Toolchain.
ENV_WHITELIST="$ENV_WHITELIST CC CPP CXX OBJC OBJCXX PC FC M2C AS LD AR RANLIB MAKE AWK LEX YACC"
# Toolchain flags.
ENV_WHITELIST="$ENV_WHITELIST CFLAGS CPPFLAGS CXXFLAGS OBJCFLAGS OBJCXXFLAGS GCJFLAGS FFLAGS LDFLAGS ARFLAGS MAKEFLAGS"
# Dynamic linker, see ld(1).
ENV_WHITELIST="$ENV_WHITELIST LD_LIBRARY_PATH"
# Locale, see locale(1).
ENV_WHITELIST="$ENV_WHITELIST LANG LC_ALL LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION"
ENV_WHITELIST="$ENV_WHITELIST SOURCE_DATE_EPOCH"
for var in $ENV_WHITELIST
do
    eval value=\$$var
    test -n "$value" && printf '  %s="%s"\n' "$var" "$value"
done

# plist
#/usr/libexec/PlistBuddy -c "Set :CFBundleVersion '${git_branch_or_tag}-${git_version}'" "${info_plist}"
#/usr/libexec/PlistBuddy -c "Set :BuildTime '${build_time}'" "${info_plist}"

#printf 'other:\n'
#cat <<EOF
#  EN_MOCKS_PATH:
#  EN_CORE_MOCKS_PATH:
#  XCODE_TEMPLATE_PATH_SRC:
#  XCODE_TEMPLATE_PATH_DST:
#EOF

printf 'Packageresults:\n'
#IPA_Sha: $(openssl sha1 $resultsdir/$builtIPA | awk '{print $2}')
cat <<EOF
  IPA_Sha: TODO
  IPA_Name: TODO 
  IPA_TYPE: TODO
  BUNDLE_Development_region: $(/usr/libexec/PlistBuddy -c "Print: CFBundleDevelopmentRegion" $info_plist)
  BUNDLE_Executable: $(/usr/libexec/PlistBuddy -c "Print: CFBundleExecutable" $info_plist)
  BUNDLE_Identifier: $(/usr/libexec/PlistBuddy -c "Print: CFBundleIdentifier" $info_plist)
  BUNDLE_Infodictversion: $(/usr/libexec/PlistBuddy -c "Print: CFBundleInfoDictionaryVersion" $info_plist)
  BUNDLE_Name: $(/usr/libexec/PlistBuddy -c "Print: CFBundleName" $info_plist)
  BUNDLE_Packagetype: $(/usr/libexec/PlistBuddy -c "Print: CFBundlePackageType" $info_plist)
  BUNDLE_Shortversion: $(/usr/libexec/PlistBuddy -c "Print: CFBundleShortVersionString" $info_plist)
  BUNDLE_Version: $(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" $info_plist)
EOF

exit 0
