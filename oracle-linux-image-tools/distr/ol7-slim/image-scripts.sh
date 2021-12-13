#!/usr/bin/env bash
#
# image scripts for OL7
#
# Copyright (c) 2019,2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl
#
# Description: this module provides a single function:
#   distr::image_cleanup: distribution specific actions to cleanup the image
#     This function is optional
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

#######################################
# Validate distribution parameters
# Globals:
#   ROOT_FS
# Arguments:
#   None
# Returns:
#   None
#######################################
distr::validate() {
[[ "${ROOT_FS,,}" =~ ^(xfs)|(btrfs)|(lvm)$ ]] || error "ROOT_FS must be xfs, btrfs or lvm"
  readonly ROOT_FS
  [[ "${UEK_RELEASE}" =~ ^[56]$ ]] || error "UEK_RELEASE must be 5 or 6"
    readonly UEK_RELEASE
}

#######################################
# Kickcstart fixup
# Globals:
#   ROOT_FS
# Arguments:
#   kickstart file name
# Returns:
#   None
#######################################
distr::kickstart() {
  local ks_file="$1"

  local btrfs="\
part btrfs.01 --fstype=\"btrfs\"  --ondisk=sda --size=4096 --grow\n\
btrfs none  --label=btrfs_vol --data=single btrfs.01\n\
btrfs /     --subvol --name=root LABEL=btrfs_vol\n\
btrfs /home --subvol --name=home LABEL=btrfs_vol\
"
  local lvm="\
part pv.01 --ondisk=sda --size=8192 --grow\n\
volgroup vg_main pv.01\n\
logvol swap   --fstype=\"swap\" --vgname=vg_main --size=8192 --name=lv_swap\n\
logvol /      --fstype=\"xfs\"  --vgname=vg_main --size=8192 --name=lv_root --grow\
"

  # Kickstart file is populated for xfs
  if [[ "${ROOT_FS,,}" = "btrfs" ]]; then
    sed -i -e 's!^part / .*$!'"${btrfs}"'!' "${ks_file}"
  elif [[ "${ROOT_FS,,}" = "lvm" ]]; then
    sed -i -e '/^part swap/d' -e 's!^part / .*$!'"${lvm}"'!' "${ks_file}"
  fi

  # Pass kernel selection
  sed -i -e 's!^KERNEL=.*$!KERNEL='"${KERNEL}"'!' "${ks_file}"
  sed -i -e 's!^UEK_RELEASE=.*$!UEK_RELEASE='"${UEK_RELEASE}"'!' "${ks_file}"
}

#######################################
# Cleanup actions run directly on the image
# Globals:
#   WORKSPACE VM_NAME BUILD_INFO
# Arguments:
#   root filesystem directory
#   boot filesystem directory
# Returns:
#   None
#######################################
distr::image_cleanup() {
  local root_fs="$1"
  local boot_fs="$2"

  # Ensure we don't blindly cleanup local host!
  [[ -z ${root_fs} ]] && error "Undefined root filesystem"
  [[ -z ${boot_fs} ]] && error "Undefined boot filesystem"

  if [[ -n ${BUILD_INFO} && -d "${root_fs}${BUILD_INFO}" ]]; then
    find "${root_fs}${BUILD_INFO}" -type f -exec cp {} "${WORKSPACE}/${VM_NAME}/" \;
  fi

  sudo chroot "${root_fs}" /bin/bash <<-EOF
  : > /var/log/wtmp
  : > /var/log/lastlog
	rm -f /var/log/audit/audit.log
	rm -f /var/log/tuned/tuned.log
	rm -rf /root/.gemrc /root/.gem
	rm -rf /var/spool/root /var/spool/mail/root
	rm -rf /var/lib/NetworkManager
	rm -rf /var/tmp/*
  [[ -n "${BUILD_INFO}" ]] && rm -rf "${BUILD_INFO}"
	EOF
}
