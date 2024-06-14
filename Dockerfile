# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
FROM centos:centos7.9.2009
MAINTAINER sbloodys
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y sudo wget nmap-ncat jq java-1.8.0-openjdk

# Install Python3
RUN yum install -y centos-release-scl && yum install -y rh-python38 yum-utils
RUN ln -s /opt/rh/rh-python38/root/usr/bin/python3 /usr/bin/python3 && ln -s /opt/rh/rh-python38/root/usr/bin/pip3 /usr/bin/pip3

RUN /usr/bin/pip3 install robotframework
RUN mkdir -p /etc/security/keytabs && chmod -R a+wr /etc/security/keytabs
ADD https://repo.maven.apache.org/maven2/org/jboss/byteman/byteman/4.0.4/byteman-4.0.4.jar /opt/byteman.jar
RUN chmod o+r /opt/byteman.jar
RUN mkdir -p /opt/profiler && \
    cd /opt/profiler && \
    curl -L https://github.com/jvm-profiling-tools/async-profiler/releases/download/v1.5/async-profiler-1.5-linux-x64.tar.gz | tar xvz
ENV JAVA_HOME=/usr/lib/jvm/jre/
ENV PATH $PATH:/opt/hadoop/bin

# Add Tini
ARG TARGETPLATFORM
ENV TINI_VERSION v0.19.0
RUN echo "TARGETPLATFORM: $TARGETPLATFORM"
RUN if [ "$TARGETPLATFORM" == "linux/amd64" ];then \
        TINI_PLATFORM=amd64; \
        wget --no-check-certificate -O /usr/sbin/tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-$TINI_PLATFORM; \
    fi
RUN if [ "$TARGETPLATFORM" == "linux/arm64" ];then \
        TINI_PLATFORM=arm64; \
        wget --no-check-certificate -O /usr/sbin/tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-$TINI_PLATFORM; \
    fi
RUN if [ "$TARGETPLATFORM" == "linux/arm/v7" ];then \
        TINI_PLATFORM=armhf; \
        wget --no-check-certificate -O /usr/sbin/tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${TINI_PLATFORM}; \
    fi
RUN chmod +x /usr/sbin/tini

RUN groupadd --gid 1000 hadoop
RUN useradd --uid 1000 hadoop --gid 100 --home /opt/hadoop
RUN echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN chown hadoop /opt
ADD scripts /opt/
ADD scripts/krb5.conf /etc/
RUN yum install -y krb5-workstation
RUN mkdir -p /etc/hadoop && mkdir -p /var/log/hadoop && chmod 1777 /etc/hadoop && chmod 1777 /var/log/hadoop
ENV HADOOP_LOG_DIR=/var/log/hadoop
ENV HADOOP_CONF_DIR=/etc/hadoop
WORKDIR /opt/hadoop

VOLUME /data
USER hadoop

WORKDIR /opt
RUN wget --no-check-certificate https://archive.apache.org/dist/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
RUN sudo rm -rf /opt/hadoop && mv hadoop-*.tar.gz hadoop.tar.gz && tar -zxf hadoop.tar.gz && rm hadoop.tar.gz && mv hadoop* hadoop && rm -rf /opt/hadoop/share/doc
WORKDIR /opt/hadoop
ADD log4j.properties /opt/hadoop/etc/hadoop/log4j.properties
RUN sudo chown -R hadoop:users /opt/hadoop/etc/hadoop/*
ENV HADOOP_CONF_DIR /opt/hadoop/etc/hadoop

ENTRYPOINT ["/usr/sbin/tini", "--", "/opt/starter.sh"]
