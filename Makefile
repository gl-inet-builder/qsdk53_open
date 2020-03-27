# Makefile for OpenWrt
#
# Copyright (C) 2007 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

TOPDIR:=${CURDIR}
LC_ALL:=C
LANG:=C
export TOPDIR LC_ALL LANG

empty:=
space:= $(empty) $(empty)
$(if $(findstring $(space),$(TOPDIR)),$(error ERROR: The path to the OpenWrt directory must not include any spaces))

world:

include $(TOPDIR)/include/host.mk

ifneq ($(OPENWRT_BUILD),1)
  _SINGLE=export MAKEFLAGS=$(space);

  override OPENWRT_BUILD=1
  export OPENWRT_BUILD
  GREP_OPTIONS=
  export GREP_OPTIONS
  include $(TOPDIR)/include/debug.mk
  include $(TOPDIR)/include/depends.mk
  include $(TOPDIR)/include/toplevel.mk
else
  include rules.mk
  include $(INCLUDE_DIR)/depends.mk
  include $(INCLUDE_DIR)/subdir.mk
  include target/Makefile
  include package/Makefile
  include tools/Makefile
  include toolchain/Makefile

$(toolchain/stamp-install): $(tools/stamp-install)
$(target/stamp-compile): $(toolchain/stamp-install) $(tools/stamp-install) $(BUILD_DIR)/.prepared
$(package/stamp-compile): $(target/stamp-compile) $(package/stamp-cleanup)
$(package/stamp-install): $(package/stamp-compile)
$(target/stamp-install): $(package/stamp-compile) $(package/stamp-install)

printdb:
	@true

prepare: $(target/stamp-compile)

clean_kernel:
ifdef CONFIG_EXTERNAL_KERNEL_TREE
	make target/linux/clean
else
	@true
endif

clean: FORCE clean_kernel
	 rm -rf $(BUILD_DIR) $(STAGING_DIR) $(BIN_DIR) $(BUILD_LOG_DIR)

si: FORCE
	tar xf single_img_dir_simple.tar.gz
	rm -f $(TOPDIR)/single_img_dir/IPQ4019.ILQ.5.0/common/build/ipq/openwrt*
	rm -f $(TOPDIR)/single_img_dir/IPQ4019.ILQ.5.0/common/build/bin/*
	rm -f $(TOPDIR)/single_img_dir/IPQ4019.ILQ.5.0/common/build/*.log
	cp $(TOPDIR)/bin/ipq806x/openwrt* $(TOPDIR)/single_img_dir/IPQ4019.ILQ.5.0/common/build/ipq
	cp $(TOPDIR)/single_img_dir/IPQ4019.ILQ.5.0/common/build/*-flash.conf $(TOPDIR)/single_img_dir/IPQ4019.ILQ.5.0/common/build/ipq
	cd single_img_dir/IPQ4019.ILQ.5.0/common/build; \
	python pack.py -t nor -B -F appsboardconfig_premium -o ../../../b1300-nor-apps.img ./ipq; \
	python pack.py -t norplusemmc -B -F appsboardconfig_premium -o ../../../s1300-noremmc-apps.img ./ipq; \
	python pack.py -t norplusnand -B -F boardconfig_premium -o ../../../ap1300-nornand-full.img ./ipq; \
	python pack.py -t norplusnand -B -F appsboardconfig_premium -o ../../../ap1300-nornand-apps.img ./ipq

dirclean: clean
	rm -rf $(STAGING_DIR_HOST) $(TOOLCHAIN_DIR) $(BUILD_DIR_HOST) $(BUILD_DIR_TOOLCHAIN)
	rm -rf $(TMP_DIR)

ifndef DUMP_TARGET_DB
$(BUILD_DIR)/.prepared: Makefile
	@mkdir -p $$(dirname $@)
	@touch $@

tmp/.prereq_packages: .config
	unset ERROR; \
	for package in $(sort $(prereq-y) $(prereq-m)); do \
		$(_SINGLE)$(NO_TRACE_MAKE) -s -r -C package/$$package prereq || ERROR=1; \
	done; \
	if [ -n "$$ERROR" ]; then \
		echo "Package prerequisite check failed."; \
		false; \
	fi
	touch $@
endif

# check prerequisites before starting to build
prereq: $(target/stamp-prereq) tmp/.prereq_packages
	@if [ ! -f "$(INCLUDE_DIR)/site/$(ARCH)" ]; then \
		echo 'ERROR: Missing site config for architecture "$(ARCH)" !'; \
		echo '       The missing file will cause configure scripts to fail during compilation.'; \
		echo '       Please provide a "$(INCLUDE_DIR)/site/$(ARCH)" file and restart the build.'; \
		exit 1; \
	fi

prepare: .config $(tools/stamp-install) $(toolchain/stamp-install)
world: prepare $(target/stamp-compile) $(package/stamp-compile) $(package/stamp-install) $(target/stamp-install) FORCE
	$(_SINGLE)$(SUBMAKE) -r package/index

.PHONY: clean dirclean prereq prepare world package/symlinks package/symlinks-install package/symlinks-clean

endif
