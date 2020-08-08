#!/bin/bash

BUILD_CONFIGURATION="$1"
git_version=$(git log -1 --format="%h")
git_branch=$(git symbolic-ref --short -q HEAD)
git_tag=$(git describe --tags --exact-match 2>/dev/null)

build_time=$(date)
git_branch_or_tag="${git_branch:-${git_tag}}"

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
  CI-Runnumber: ${GITHUB_RUN_NUMBER}
  CI-Actor: ${GITHUB_ACTOR}
  CI-Repository: ${GITHUB_REPOSITORY}
  CI-Eventname: ${GITHUB_EVENT_NAME}
  CI-Workspace: ${GITHUB_WORKSPACE}
  CI-SHA: ${GITHUB_SHA}
  CI-Ref: ${GITHUB_REF}
EOF


printf 'Installed-Build-Depends:\n'
cat <<EOF
  xcodeselect_path: $(xcode-select -p)
  xcodebuild_version: $(xcodebuild -version| grep Xcode)
  openssl_version: $(openssl version)
  swift_version: $(swift --version| grep -m1 -)
  xcodegen_version: $(vendor/XcodeGen/.build/release/XcodeGen --version)
EOF


printf 'Environment:\n'
ENV_WHITELIST=
# Toolchain.
ENV_WHITELIST="$ENV_WHITELIST CC CPP CXX OBJC OBJCXX PC FC M2C AS LD AR RANLIB MAKE AWK LEX YACC"
# Toolchain flags.
ENV_WHITELIST="$ENV_WHITELIST CFLAGS CPPFLAGS CXXFLAGS OBJCFLAGS OBJCXXFLAGS GCJFLAGS FFLAGS LDFLAGS ARFLAGS MAKEFLAGS"
# Dynamic linker, see ld(1).
ENV_WHITELIST="$ENV_WHITELIST LD_LIBRARY_PATH"
# Locale, see locale(1).
ENV_WHITELIST="$ENV_WHITELIST LANG LC_ALL LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION"
for var in $ENV_WHITELIST
do
    eval value=\$$var
    test -n "$value" && printf '  %s="%s"\n' "$var" "$value"
done

printf 'Packageresults:\n'
#IPA_Sha: $(openssl sha1 $resultsdir/$builtIPA | awk '{print $2}')
cat <<EOF
  IPA_Sha: TODO
  IPA_Name: TODO
  IPA_Type: TODO
EOF

exit 0
