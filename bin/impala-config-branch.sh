# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# Variables in the file override the default values from impala-config.sh.
# Config changes for release or features branches should go here so they
# can be version controlled but not conflict with changes on the master
# branch.

# To facilitate building and testing across many possible CDH components,
# we use $CDH_GBN to specify which build we are working against.
# This is determined as follows.
# 1. If $GLOBAL_BUILD_NUMBER is set, use that for $CDH_GBN.
#    In a Cauldron build, this will be set, as well as CAULDRON_DOCKER_PLATFORM.
# 2. If toolchain/cdh_components/cdh-gbn.sh exists, source it to set
#    $CDH_GBN. This will cause subsequent builds in the same $IMPALA_HOME
#    to continue using the same cdh components. 
# 3. Query BuildDB for the latest CDH build tagged with impala-minicluster-tarballs,
#    and use that. The result is cached in cdh-gbn.sh so that a workspace
#    continues to use the same components.
# In addition to being used by bin/bootstrap-toolchain.sh to download the
# tarballs to support the minicluster, CDH_GBN is used in {fe,testdata}/pom.xml
# to choose a Maven repository with jars from that specific GBN.
#
# Furthermore, a cdh.properties file matching the GBN is used
# to figure out the CDH component versions.

# Defer to $GLOBAL_BUILD_NUMBER OR $CDH_GBN, in that order.
export CDH_GBN=${GLOBAL_BUILD_NUMBER:-${CDH_GBN:-}}
VERSION="6.x"
BRANCH="cdh${VERSION}"
CDH_GBN_CONFIG="${IMPALA_HOME}/toolchain/cdh_components/cdh-gbn.sh"
WGET="wget --no-verbose -O -"
# Defined in the context of a cauldron build
CAULDRON_DOCKER_PLATFORM=${CAULDRON_DOCKER_PLATFORM:-}

if [ ! "${CDH_GBN}" ]; then
  if [ -f "${CDH_GBN_CONFIG}" ]; then
    . "${CDH_GBN_CONFIG}"
    echo "Using CDH_GBN ${CDH_GBN} based on ${CDH_GBN_CONFIG}"
  else
    BUILDDB_QUERY='http://builddb.infra.cloudera.com/query?product=cdh;tag=impala-minicluster-tarballs,official;version='"${VERSION}"
    export CDH_GBN=$($WGET "${BUILDDB_QUERY}")
    [ "${CDH_GBN}" ]  # Assert we got something
    mkdir -p "$(dirname ${CDH_GBN_CONFIG})"
    echo "export CDH_GBN=${CDH_GBN}" > "${CDH_GBN_CONFIG}"
    echo "Using CDH_GBN ${CDH_GBN} based on BuildDB query ${BUILDDB_QUERY}."
  fi
fi
export CDH_BUILD_NUMBER=${CDH_GBN}

# Defer to IMPALA_MAVEN_OPTIONS_OVERRIDE. If not set, download an m2-settings.xml file
# and re-configure to use it.
if [ "${IMPALA_MAVEN_OPTIONS_OVERRIDE:-}" ]; then
  export IMPALA_MAVEN_OPTIONS=${IMPALA_MAVEN_OPTIONS_OVERRIDE}
elif [ -z "$CAULDRON_DOCKER_PLATFORM" ]; then
  # If we're not in a cauldron build, set up an m2-settings file
  MAVEN_CONFIG_FILE="${IMPALA_HOME}/toolchain/cdh_components/m2-settings.xml"
  if [ ! -e "${MAVEN_CONFIG_FILE}" ]; then
    mkdir -p "$(dirname ${MAVEN_CONFIG_FILE})"
    $WGET https://github.infra.cloudera.com/raw/CDH/cdh/${BRANCH}/gbn-m2-settings.xml \
      -O "${MAVEN_CONFIG_FILE}"
  fi
  export IMPALA_MAVEN_OPTIONS="-s ${MAVEN_CONFIG_FILE}"
fi

BUILD_REPO="http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/${CDH_GBN}"
BUILD_REPO_BASE="${BUILD_REPO}/impala-minicluster-tarballs"

if [ -z "$CAULDRON_DOCKER_PLATFORM" ]; then
  # Outside of a Cauldron build, download CDH_PROPERTIES_FILE:
  CDH_PROPERTIES_FILE="${IMPALA_HOME}/toolchain/cdh_components/cdh.properties.${CDH_GBN}"
  if [ ! -f "${CDH_PROPERTIES_FILE}" ]; then
    $WGET "${BUILD_REPO}"/cdh-properties/cdh.properties \
      -O "${CDH_PROPERTIES_FILE}"
  fi
else
  # Inside of Cauldron build, grab it from the repo
  CDH_PROPERTIES_FILE="${CAULDRON_OUTPUT}/cdh-properties/cdh.properties"
  [ -f "$CDH_PROPERTIES_FILE" ]
fi

# Get Java version strings from cdh.properties. Tarballs
# append a -<GBN> to these versions, and never use -SNAPSHOT.
# The java versions are managed in ../impala-parent/pom.xml
# and inherit from the CDH root pom.
export IMPALA_HADOOP_VERSION=$(cat $CDH_PROPERTIES_FILE | grep ^cdh.hadoop.version | cut -d= -f2 | sed -e s,-SNAPSHOT,,)-${CDH_GBN}
[[ -n $IMPALA_HADOOP_VERSION ]]
export IMPALA_HADOOP_URL=${BUILD_REPO_BASE}/hadoop-${IMPALA_HADOOP_VERSION}.tar.gz
export IMPALA_HBASE_VERSION=$(cat $CDH_PROPERTIES_FILE | grep ^cdh.hbase.version | cut -d= -f2 | sed -e s,-SNAPSHOT,,)-${CDH_GBN}
[[ -n $IMPALA_HBASE_VERSION ]]
export IMPALA_HBASE_URL=${BUILD_REPO_BASE}/hbase-${IMPALA_HBASE_VERSION}.tar.gz
export IMPALA_HIVE_VERSION=$(cat $CDH_PROPERTIES_FILE | grep ^cdh.hive.version | cut -d= -f2 | sed -e s,-SNAPSHOT,,)-${CDH_GBN}
[[ -n $IMPALA_HIVE_VERSION ]]
export IMPALA_KUDU_VERSION=$(cat $CDH_PROPERTIES_FILE | grep ^cdh.kudu.version | cut -d= -f2 | sed -e s,-SNAPSHOT,,)-${CDH_GBN}
export IMPALA_HIVE_URL=${BUILD_REPO_BASE}/hive-${IMPALA_HIVE_VERSION}.tar.gz
[[ -n $IMPALA_KUDU_VERSION ]]
export IMPALA_SENTRY_VERSION=$(cat $CDH_PROPERTIES_FILE | grep ^cdh.sentry.version | cut -d= -f2 | sed -e s,-SNAPSHOT,,)-${CDH_GBN}
export IMPALA_KUDU_URL=${BUILD_REPO_BASE}/kudu-${IMPALA_KUDU_VERSION}-'%(platform_label)'.tar.gz
[[ -n $IMPALA_SENTRY_VERSION ]]
export IMPALA_SENTRY_URL=${BUILD_REPO_BASE}/sentry-${IMPALA_SENTRY_VERSION}.tar.gz
