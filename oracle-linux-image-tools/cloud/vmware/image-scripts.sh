#!/usr/bin/env bash
#
# Cleanup and package image for the "None" image
#
# Copyright (c) 2019 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl
#
# Description: this module provides 2 functions:
#   cloud::image_cleanup: cloud specific actions to cleanup the image
#     This function is optional
#   cloud::image_package: Package the raw image for the target cloud.
#     This function must be defined either at cloud or cloud/distribution level
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

#######################################
# Cleanup actions run directly on the image
# Globals:
#   None
# Arguments:
#   root filesystem directory
#   boot filesystem directory
# Returns:
#   None
#######################################
cloud::image_cleanup() {
  :
}

#######################################
# Image packaging - creates a VMWare OVA
# Globals:
#   CLOUD_DIR CLOUD DISTR_NAME BUILD_NUMBER VM_NAME DISK_SIZE_GB
# Arguments:
#   None
# Returns:
#   None
#######################################
cloud::image_package() {
  yum install -y openssl

  local vmdk=$(grep "ovf:href" "${VM_NAME}.ovf" | sed -r -e 's/.*ovf:href="([^"]+)".*/\1/')
  vboxmanage convertfromraw System.img --format VMDK "${vmdk}" --variant Stream
  rm System.img

  local mk_envelope="${CLOUD_DIR}/${CLOUD}/mk-envelope.sh"

  # Decompose Build Name into Release/update/platform
  local build_rel="${DISTR_NAME%U*}"
  local build_upd="${DISTR_NAME#*U}"
  local build_upd="${build_upd%%_*}"

  ${mk_envelope} \
    -r "${build_rel}" \
    -u "${build_upd##U}" \
    -b "${BUILD_NUMBER}" \
    -s "${DISK_SIZE_GB}" \
    -f "${vmdk}" \
    -n "${VM_NAME}"

  rm "${vmdk}"
}

