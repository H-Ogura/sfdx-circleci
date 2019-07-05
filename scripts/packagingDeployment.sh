#!/bin/bash

# Default values
BRANCH=$1
SFDX_CLI_EXEC="sfdx"
TARGET_ORG='packaging@trailheadapps.org'
TARGETDEVHUBUSERNAME="ogurah@curious-panda-m1t97k.com"
PACKAGENAME="DXVerificationCi"
RESULT=0

# Defining Salesforce CLI exec, depending if it's CI or local dev machine
# CircleCiで実行する場合、$CIは常にtrue.
# ローカルで実行した場合はここを通らない。
if [ $CI ]; then
  echo "Script is running on CI"
  SFDX_CLI_EXEC="sfdx"
  TARGET_ORG="DXVerification"
fi
$SFDX_CLI_EXEC force:package:create --name $PACKAGENAME --packagetype Unlocked --path force-app
PACKAGE_VERSION="$($SFDX_CLI_EXEC force:package:version:create -p $PACKAGENAME -x -w 10 --json)"
RESULT="$(echo $PACKAGE_VERSION | jq '.status')"
echo "Result is $RESULT"

if [ -z $RESULT ]; then
  exit 1
fi

if [ $RESULT -gt 0 ]; then
  echo $PACKAGE_VERSION
  exit 1
else
  sleep 300
fi

PACKAGE_VERSION="$(echo $PACKAGE_VERSION | jq '.result.SubscriberPackageVersionId' | tr -d '"')"

# 参考のために残す
# $SFDX_CLI_EXEC force:package:install --package $PACKAGE_VERSION -w 10 -u $TARGET_ORG -r
$SFDX_CLI_EXEC force:package:version:promote -p $PACKAGE_VERSION -n -v $TARGETDEVHUBUSERNAME
$SFDX_CLI_EXEC force:package:install --package $PACKAGE_VERSION -w 10 -u $TARGET_ORG -r

echo "Done"
