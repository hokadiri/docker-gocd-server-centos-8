# Copyright 2018 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################################
# This file is autogenerated by the repository at https://github.com/gocd/gocd.
# Please file any issues or PRs at https://github.com/gocd/gocd
###############################################################################################

FROM alpine:latest as gocd-server-unzip
ARG UID=1000
RUN \
  apk --no-cache upgrade && \
  apk add --no-cache curl && \
  curl --fail --location --silent --show-error "https://download.gocd.org/binaries/20.3.0-11530/generic/go-server-20.3.0-11530.zip" > /tmp/go-server-20.3.0-11530.zip
RUN unzip /tmp/go-server-20.3.0-11530.zip -d /
RUN mv /go-server-20.3.0 /go-server && chown -R ${UID}:0 /go-server && chmod -R g=u /go-server

FROM centos:8
MAINTAINER ThoughtWorks, Inc. <support@thoughtworks.com>

LABEL gocd.version="20.3.0" \
  description="GoCD server based on centos version 8" \
  maintainer="ThoughtWorks, Inc. <support@thoughtworks.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="20.3.0-11530" \
  gocd.git.sha="f54d0bae7a39fe7add5460f3f8676a7936abf698"

# the ports that go server runs on
EXPOSE 8153

ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini-static-amd64 /usr/local/sbin/tini

# force encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"

ARG UID=1000

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
# add user to root group for gocd to work on openshift
  useradd -u ${UID} -g root -d /home/go -m go && \
  yum install --assumeyes glibc-langpack-en && \
  yum update -y && \
  yum install --assumeyes git mercurial subversion openssh-clients bash unzip curl procps procps-ng coreutils-single && \
  yum clean all && \
  curl --fail --location --silent --show-error 'https://github.com/AdoptOpenJDK/openjdk13-binaries/releases/download/jdk-13.0.2%2B8/OpenJDK13U-jre_x64_linux_hotspot_13.0.2_8.tar.gz' --output /tmp/jre.tar.gz && \
  mkdir -p /gocd-jre && \
  tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
  rm -rf /tmp/jre.tar.gz && \
  mkdir -p /go-server /docker-entrypoint.d /go-working-dir /godata

ADD docker-entrypoint.sh /

COPY --from=gocd-server-unzip /go-server /go-server
# ensure that logs are printed to console output
COPY --chown=go:root logback-include.xml /go-server/config/logback-include.xml
COPY --chown=go:root install-gocd-plugins /usr/local/sbin/install-gocd-plugins
COPY --chown=go:root git-clone-config /usr/local/sbin/git-clone-config

RUN chown -R go:root /docker-entrypoint.d /go-working-dir /godata /docker-entrypoint.sh \
    && chmod -R g=u /docker-entrypoint.d /go-working-dir /godata /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

USER go
