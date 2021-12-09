#!/usr/bin/env bash
#
# Creates OVF file for VMware environments
#
# Copyright (c) 2019,2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl
#
# Sample usage:
# mk-envelope -r "OL7" -u "8" -b "1" -s "15" -f "OL7U8_x86_64-vmware-b1-disk001.vmdk" -n "OL7U8_x86_64-vmware-b1"
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

readonly PGM=$(basename "$0")
readonly PGM_DIR=$( cd "$(dirname "$0")" && pwd -P )

help() {
  echo ""
  echo "Creates OVF file for VMware environments"
  echo ""
  echo "Usage:"
  echo "  ${PGM} -r OL_RELEASE -u OL_UPDATE  -v VERSION -s DISK_SIZE"
  echo "      -r OL_RELEASE, OL7"
  echo "      -u OL_UPDATE, 0..9"
  echo "      -b BUILD_NUMBER, like 1"
  echo "      -s DISK_SIZE in GB, like 10"
  echo "      `-f` VMDK_FILE, like OL7U8_x86_64-vmware-b1-disk001.vmdk"
  echo "      -n VM_NAME, like OL7U8_x86_64-vmware-b1"
  echo ""
}

init_parameter() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r)
        shift
        if [[ -n $1 ]]; then
          OL_RELEASE="$1"
          shift
        fi
        ;;
      -u)
        shift
        if [[ -n $1 ]]; then
          OL_UPDATE="$1"
          shift
        fi
        ;;
      -b)
        shift
        if [[ -n $1 ]]; then
          BUILD_NUMBER="$1"
          shift
        fi
        ;;
      -s)
        shift
        if [[ -n $1 ]]; then
          CAPACITY=$(( $1 * 1 ))
          shift
        fi
        ;;
      -f)
        shift
        if [[ -n $1 ]]; then
          VMDK_FILE="$1"
          shift
        fi
        ;;
      -n)
        shift
        if [[ -n $1 ]]; then
          VM_NAME="$1"
          shift
        fi
        ;;
      -h|-help|--help)
        help
        exit 0
        ;;
      *)
        help
        exit 0
        ;;
    esac
  done
}

#
# MAIN
#

if [[ $# -eq 0 ]]; then
  help
  exit 1
fi

init_parameter "$@"

# Output filename
readonly VMDK_FILE_SIZE=$(stat --printf=%s "$VMDK_FILE")

# Replace variables in template
sed -e "s/\\\${OL_RELEASE}/${OL_RELEASE}/" \
    -e "s/\\\${OL_UPDATE}/${OL_UPDATE}/" \
    -e "s/\\\${BUILD_NUMBER}/${BUILD_NUMBER}/" \
    -e "s/\\\${CAPACITY}/${CAPACITY}/" \
    -e "s/\\\${VMDK_FILE_SIZE}/${VMDK_FILE_SIZE}/" \
    -e "s/\\\${VMDK_FILE}/${VMDK_FILE}/" \
    < "${PGM_DIR}"/VMW_TEMPLATE.ovf > "${VM_NAME}.ovf"

openssl sha1 "${VMDK_FILE}" "${VM_NAME}.ovf" > "${VM_NAME}.mf"

tar cf "${VM_NAME}.ova" "${VM_NAME}.ovf" "${VMDK_FILE}" "${VM_NAME}.mf"

# Cleanup
rm "${VM_NAME}.ovf" "${VM_NAME}.mf"

exit 0
