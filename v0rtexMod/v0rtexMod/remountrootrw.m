//
//  remountrootrw.m
//  v0rtexMod
//
//  Created by dns on 12/20/17.
//  Copyright © 2017 din3zh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "remountrootrw.h"
#include "kernelutils.h"
#include "symbols.h"

// Remount / as rw based off xerub patch
// unset the MNT_ROOTFS flag and then remount and then set it back

#define KSTRUCT_OFFSET_MOUNT_MNT_FLAG   0x70
#define KSTRUCT_OFFSET_VNODE_V_UN       0xd8 //vm_offset_t off = 0xd8;

int remountrootrw(task_t tfp0, uint64_t kslide) {
    uint64_t _rootnode = OFFSET_ROOT_MOUNT_V_NODE + kslide;
    uint64_t rootfs_vnode = rk64_with_tfp0(tfp0, _rootnode);
    
    // read the original flags
    uint64_t v_mount = rk64_with_tfp0(tfp0, rootfs_vnode + KSTRUCT_OFFSET_VNODE_V_UN);
    uint32_t v_flag = rk32_with_tfp0(tfp0, v_mount + KSTRUCT_OFFSET_MOUNT_MNT_FLAG + 1);
    //   uint32_t v_flag = rk32_via_tfp0(tfp0, v_mount + 0x71);
    
    // unsetting the rootfs flag
    wk32_with_tfp0(tfp0, v_mount + KSTRUCT_OFFSET_MOUNT_MNT_FLAG + 1, v_flag & ~(MNT_ROOTFS >> 8));
    //wk32_with_tfp0(tfp0, v_mount + KSTRUCT_OFFSET_MOUNT_MNT_FLAG + 1, v_flag & ~(1 << 6));
    
    // remounting it
    char *nmz = strdup("/dev/disk0s1s1");
    kern_return_t rv = mount("hfs", "/", MNT_UPDATE, (void *)&nmz);
    
    // reset the original flags
    v_mount = rk64_with_tfp0(tfp0, rootfs_vnode + KSTRUCT_OFFSET_VNODE_V_UN);
    wk32_with_tfp0(tfp0, v_mount + KSTRUCT_OFFSET_MOUNT_MNT_FLAG + 1, v_flag);
    //  rv = mount("hfs", "/Developer", MNT_UPDATE, (void *)&nmz);
    
    return rv;
}
