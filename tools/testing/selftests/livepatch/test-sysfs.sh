#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022 Song Liu <song@kernel.org>

. $(dirname $0)/functions.sh

MOD_LIVEPATCH=test_klp_livepatch
MOD_LIVEPATCH2=test_klp_callbacks_demo
MOD_LIVEPATCH3=test_klp_syscall

setup_config

# - load a livepatch and verifies the sysfs entries work as expected

start_test "sysfs test"

load_lp $MOD_LIVEPATCH

check_sysfs_rights "$MOD_LIVEPATCH" "" "drwxr-xr-x"
check_sysfs_rights "$MOD_LIVEPATCH" "enabled" "-rw-r--r--"
check_sysfs_value  "$MOD_LIVEPATCH" "enabled" "1"
check_sysfs_rights "$MOD_LIVEPATCH" "force" "--w-------"
check_sysfs_rights "$MOD_LIVEPATCH" "replace" "-r--r--r--"
check_sysfs_rights "$MOD_LIVEPATCH" "stack_order" "-r--r--r--"
check_sysfs_value  "$MOD_LIVEPATCH" "stack_order" "1"
check_sysfs_rights "$MOD_LIVEPATCH" "transition" "-r--r--r--"
check_sysfs_value  "$MOD_LIVEPATCH" "transition" "0"
check_sysfs_rights "$MOD_LIVEPATCH" "vmlinux/patched" "-r--r--r--"
check_sysfs_value  "$MOD_LIVEPATCH" "vmlinux/patched" "1"

disable_lp $MOD_LIVEPATCH

unload_lp $MOD_LIVEPATCH

check_result "% insmod test_modules/$MOD_LIVEPATCH.ko
livepatch: enabling patch '$MOD_LIVEPATCH'
livepatch: '$MOD_LIVEPATCH': initializing patching transition
livepatch: '$MOD_LIVEPATCH': starting patching transition
livepatch: '$MOD_LIVEPATCH': completing patching transition
livepatch: '$MOD_LIVEPATCH': patching complete
% echo 0 > $SYSFS_KLP_DIR/$MOD_LIVEPATCH/enabled
livepatch: '$MOD_LIVEPATCH': initializing unpatching transition
livepatch: '$MOD_LIVEPATCH': starting unpatching transition
livepatch: '$MOD_LIVEPATCH': completing unpatching transition
livepatch: '$MOD_LIVEPATCH': unpatching complete
% rmmod $MOD_LIVEPATCH"

start_test "sysfs test object/patched"

MOD_LIVEPATCH=test_klp_callbacks_demo
MOD_TARGET=test_klp_callbacks_mod
load_lp $MOD_LIVEPATCH

# check the "patch" file changes as target module loads/unloads
check_sysfs_value  "$MOD_LIVEPATCH" "$MOD_TARGET/patched" "0"
load_mod $MOD_TARGET
check_sysfs_value  "$MOD_LIVEPATCH" "$MOD_TARGET/patched" "1"
unload_mod $MOD_TARGET
check_sysfs_value  "$MOD_LIVEPATCH" "$MOD_TARGET/patched" "0"

disable_lp $MOD_LIVEPATCH
unload_lp $MOD_LIVEPATCH

check_result "% insmod test_modules/test_klp_callbacks_demo.ko
livepatch: enabling patch 'test_klp_callbacks_demo'
livepatch: 'test_klp_callbacks_demo': initializing patching transition
test_klp_callbacks_demo: pre_patch_callback: vmlinux
livepatch: 'test_klp_callbacks_demo': starting patching transition
livepatch: 'test_klp_callbacks_demo': completing patching transition
test_klp_callbacks_demo: post_patch_callback: vmlinux
livepatch: 'test_klp_callbacks_demo': patching complete
% insmod test_modules/test_klp_callbacks_mod.ko
livepatch: applying patch 'test_klp_callbacks_demo' to loading module 'test_klp_callbacks_mod'
test_klp_callbacks_demo: pre_patch_callback: test_klp_callbacks_mod -> [MODULE_STATE_COMING] Full formed, running module_init
test_klp_callbacks_demo: post_patch_callback: test_klp_callbacks_mod -> [MODULE_STATE_COMING] Full formed, running module_init
test_klp_callbacks_mod: test_klp_callbacks_mod_init
% rmmod test_klp_callbacks_mod
test_klp_callbacks_mod: test_klp_callbacks_mod_exit
test_klp_callbacks_demo: pre_unpatch_callback: test_klp_callbacks_mod -> [MODULE_STATE_GOING] Going away
livepatch: reverting patch 'test_klp_callbacks_demo' on unloading module 'test_klp_callbacks_mod'
test_klp_callbacks_demo: post_unpatch_callback: test_klp_callbacks_mod -> [MODULE_STATE_GOING] Going away
% echo 0 > $SYSFS_KLP_DIR/test_klp_callbacks_demo/enabled
livepatch: 'test_klp_callbacks_demo': initializing unpatching transition
test_klp_callbacks_demo: pre_unpatch_callback: vmlinux
livepatch: 'test_klp_callbacks_demo': starting unpatching transition
livepatch: 'test_klp_callbacks_demo': completing unpatching transition
test_klp_callbacks_demo: post_unpatch_callback: vmlinux
livepatch: 'test_klp_callbacks_demo': unpatching complete
% rmmod test_klp_callbacks_demo"

start_test "sysfs test replace enabled"

MOD_LIVEPATCH=test_klp_atomic_replace
load_lp $MOD_LIVEPATCH replace=1

check_sysfs_rights "$MOD_LIVEPATCH" "replace" "-r--r--r--"
check_sysfs_value  "$MOD_LIVEPATCH" "replace" "1"

disable_lp $MOD_LIVEPATCH
unload_lp $MOD_LIVEPATCH

check_result "% insmod test_modules/$MOD_LIVEPATCH.ko replace=1
livepatch: enabling patch '$MOD_LIVEPATCH'
livepatch: '$MOD_LIVEPATCH': initializing patching transition
livepatch: '$MOD_LIVEPATCH': starting patching transition
livepatch: '$MOD_LIVEPATCH': completing patching transition
livepatch: '$MOD_LIVEPATCH': patching complete
% echo 0 > $SYSFS_KLP_DIR/$MOD_LIVEPATCH/enabled
livepatch: '$MOD_LIVEPATCH': initializing unpatching transition
livepatch: '$MOD_LIVEPATCH': starting unpatching transition
livepatch: '$MOD_LIVEPATCH': completing unpatching transition
livepatch: '$MOD_LIVEPATCH': unpatching complete
% rmmod $MOD_LIVEPATCH"

start_test "sysfs test replace disabled"

load_lp $MOD_LIVEPATCH replace=0

check_sysfs_rights "$MOD_LIVEPATCH" "replace" "-r--r--r--"
check_sysfs_value  "$MOD_LIVEPATCH" "replace" "0"

disable_lp $MOD_LIVEPATCH
unload_lp $MOD_LIVEPATCH

check_result "% insmod test_modules/$MOD_LIVEPATCH.ko replace=0
livepatch: enabling patch '$MOD_LIVEPATCH'
livepatch: '$MOD_LIVEPATCH': initializing patching transition
livepatch: '$MOD_LIVEPATCH': starting patching transition
livepatch: '$MOD_LIVEPATCH': completing patching transition
livepatch: '$MOD_LIVEPATCH': patching complete
% echo 0 > $SYSFS_KLP_DIR/$MOD_LIVEPATCH/enabled
livepatch: '$MOD_LIVEPATCH': initializing unpatching transition
livepatch: '$MOD_LIVEPATCH': starting unpatching transition
livepatch: '$MOD_LIVEPATCH': completing unpatching transition
livepatch: '$MOD_LIVEPATCH': unpatching complete
% rmmod $MOD_LIVEPATCH"

start_test "sysfs test stack_order value"

load_lp $MOD_LIVEPATCH

check_sysfs_value  "$MOD_LIVEPATCH" "stack_order" "1"

load_lp $MOD_LIVEPATCH2

check_sysfs_value  "$MOD_LIVEPATCH2" "stack_order" "2"

load_lp $MOD_LIVEPATCH3

check_sysfs_value  "$MOD_LIVEPATCH3" "stack_order" "3"

disable_lp $MOD_LIVEPATCH2
unload_lp $MOD_LIVEPATCH2

check_sysfs_value  "$MOD_LIVEPATCH" "stack_order" "1"
check_sysfs_value  "$MOD_LIVEPATCH3" "stack_order" "2"

disable_lp $MOD_LIVEPATCH3
unload_lp $MOD_LIVEPATCH3

disable_lp $MOD_LIVEPATCH
unload_lp $MOD_LIVEPATCH

check_result "% insmod test_modules/$MOD_LIVEPATCH.ko
livepatch: enabling patch '$MOD_LIVEPATCH'
livepatch: '$MOD_LIVEPATCH': initializing patching transition
livepatch: '$MOD_LIVEPATCH': starting patching transition
livepatch: '$MOD_LIVEPATCH': completing patching transition
livepatch: '$MOD_LIVEPATCH': patching complete
% insmod test_modules/$MOD_LIVEPATCH2.ko
livepatch: enabling patch '$MOD_LIVEPATCH2'
livepatch: '$MOD_LIVEPATCH2': initializing patching transition
$MOD_LIVEPATCH2: pre_patch_callback: vmlinux
livepatch: '$MOD_LIVEPATCH2': starting patching transition
livepatch: '$MOD_LIVEPATCH2': completing patching transition
$MOD_LIVEPATCH2: post_patch_callback: vmlinux
livepatch: '$MOD_LIVEPATCH2': patching complete
% insmod test_modules/$MOD_LIVEPATCH3.ko
livepatch: enabling patch '$MOD_LIVEPATCH3'
livepatch: '$MOD_LIVEPATCH3': initializing patching transition
livepatch: '$MOD_LIVEPATCH3': starting patching transition
livepatch: '$MOD_LIVEPATCH3': completing patching transition
livepatch: '$MOD_LIVEPATCH3': patching complete
% echo 0 > $SYSFS_KLP_DIR/$MOD_LIVEPATCH2/enabled
livepatch: '$MOD_LIVEPATCH2': initializing unpatching transition
$MOD_LIVEPATCH2: pre_unpatch_callback: vmlinux
livepatch: '$MOD_LIVEPATCH2': starting unpatching transition
livepatch: '$MOD_LIVEPATCH2': completing unpatching transition
$MOD_LIVEPATCH2: post_unpatch_callback: vmlinux
livepatch: '$MOD_LIVEPATCH2': unpatching complete
% rmmod $MOD_LIVEPATCH2
% echo 0 > $SYSFS_KLP_DIR/$MOD_LIVEPATCH3/enabled
livepatch: '$MOD_LIVEPATCH3': initializing unpatching transition
livepatch: '$MOD_LIVEPATCH3': starting unpatching transition
livepatch: '$MOD_LIVEPATCH3': completing unpatching transition
livepatch: '$MOD_LIVEPATCH3': unpatching complete
% rmmod $MOD_LIVEPATCH3
% echo 0 > $SYSFS_KLP_DIR/$MOD_LIVEPATCH/enabled
livepatch: '$MOD_LIVEPATCH': initializing unpatching transition
livepatch: '$MOD_LIVEPATCH': starting unpatching transition
livepatch: '$MOD_LIVEPATCH': completing unpatching transition
livepatch: '$MOD_LIVEPATCH': unpatching complete
% rmmod $MOD_LIVEPATCH"

exit 0
