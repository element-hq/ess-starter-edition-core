# Copyright 2023 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later



FROM quay.io/operator-framework/ansible-operator:v1.31.0
ARG TARGETPLATFORM
ARG BUILDPLATFORM

ENV HELM_VERSION=v3.10.2


USER root
RUN yum install -y python39-psycopg2 python39-requests git

COPY requirements.txt /root/requirements.txt
RUN pip3 install -r /root/requirements.txt && rm /root/requirements.txt

# Install Helm
RUN yum install -y wget && \
  export HELM_ARCH=$( sh -c 'echo ${TARGETPLATFORM#"linux/"}') && \
  echo https://get.helm.sh/helm-${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz && \
  wget https://get.helm.sh/helm-${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz && \
  tar xf helm-${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz && \
  cp linux-${HELM_ARCH}/helm /usr/local/bin && \
  rm -rfv linux-${HELM_ARCH} helm-${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz && \
  yum remove -y wget

USER ${USER_UID}
RUN mkdir ${HOME}/element.io
WORKDIR ${HOME}/element.io
ENV ANSIBLE_ROLES_PATH ${HOME}/element.io/roles


COPY requirements.yml ${HOME}/element.io/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/element.io/requirements.yml \
  && chmod -R ug+rwx ${HOME}/.ansible

COPY LICENSES/operator ${HOME}/element.io/LICENSES
COPY watches.yaml ${HOME}/element.io/watches.yaml
COPY roles/ ${HOME}/element.io/roles/
COPY playbooks/ ${HOME}/element.io/playbooks/
USER root
RUN yum remove -y git
RUN rm -rf ${HOME}/element.io/roles/elementdeployment ${HOME}/element.io/playbooks/elementdeployment.yml
USER ${USER_UID}
