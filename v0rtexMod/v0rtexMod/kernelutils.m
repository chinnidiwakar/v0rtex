//
//  kernelutils.m
//  v0rtexMod
//
//  Created by dns on 12/20/17.
//  Copyright © 2017 din3zh. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "kernelutils.h"

#include <mach/mach.h>
#include <mach-o/loader.h>

#include <stdio.h>
#include <stdlib.h>

#include "patchfinder64.h"

task_t tfp0;

void init_kernel(task_t task_for_port0) {
    tfp0 = task_for_port0;
}



static uint8_t *kernel = NULL;
static uint64_t xnucore_base = 0;
static uint64_t xnucore_size = 0;
static uint64_t prelink_base = 0;
static uint64_t prelink_size = 0;
static uint64_t cstring_base = 0;
static uint64_t cstring_size = 0;
static uint64_t pstring_base = 0;
static uint64_t pstring_size = 0;
static uint64_t kerndumpbase = -1;
static uint64_t kernel_entry = 0;
static uint64_t kernel_delta = 0;
static size_t kernel_size = 0;
static void *kernel_mh = 0;


uint64_t rk64_with_tfp0(task_t tfp0, uint64_t kaddr) {
    uint64_t lower = rk32_with_tfp0(tfp0, kaddr);
    uint64_t higher = rk32_with_tfp0(tfp0, kaddr + 4);
    return ((higher << 32) | lower);
}


uint32_t rk32_with_tfp0(task_t tfp0, uint64_t kaddr) {
    kern_return_t err;
    uint32_t val = 0;
    mach_vm_size_t outsize = 0;
    
    kern_return_t mach_vm_write(
                                vm_map_t target_task,
                                mach_vm_address_t address,
                                vm_offset_t data,
                                mach_msg_type_number_t dataCnt);
    
    err = mach_vm_read_overwrite(tfp0,
                                 (mach_vm_address_t)kaddr,
                                 (mach_vm_size_t)sizeof(uint32_t),
                                 (mach_vm_address_t)&val,
                                 &outsize);
    
    if (err != KERN_SUCCESS) {
        // printf("tfp0 read failed %s addr: 0x%llx err:%x port:%x\n", mach_error_string(err), kaddr, err, tfp0);
        // sleep(3);
        return 0;
    }
    
    if (outsize != sizeof(uint32_t)) {
        // printf("tfp0 read was short (expected %lx, got %llx\n", sizeof(uint32_t), outsize);
        // sleep(3);
        return 0;
    }
    
    return val;
}

void wk64_with_tfp0(task_t tfp0,uint64_t kaddr, uint64_t val) {
    uint32_t lower = (uint32_t)(val & 0xffffffff);
    uint32_t higher = (uint32_t)(val >> 32);
    wk32_with_tfp0(tfp0, kaddr, lower);
    wk32_with_tfp0(tfp0, kaddr + 4, higher);
}


void wk32_with_tfp0(task_t tfp0, uint64_t kaddr, uint32_t val) {
    if (tfp0 == MACH_PORT_NULL) {
        // printf("attempt to write to kernel memory before any kernel memory write primitives available\n");
        // sleep(3);
        return;
    }
    
    kern_return_t err;
    err = mach_vm_write(tfp0,
                        (mach_vm_address_t)kaddr,
                        (vm_offset_t)&val,
                        (mach_msg_type_number_t)sizeof(uint32_t));
    
    if (err != KERN_SUCCESS) {
        // printf("tfp0 write failed: %s %x\n", mach_error_string(err), err);
        return;
    }
}



//uint64_t find_strref(const char *string, int n, int prelink){
//    uint8_t *str;
//    uint64_t base = cstring_base;
//    uint64_t size = cstring_size;
//    if (prelink) {
//        base = pstring_base;
//        size = pstring_size;
//    }
//    str = boyermoore_horspool_memmem(kernel + base, size, (uint8_t *)string, strlen(string));
//    if (!str) {
//        return 0;
//    }
//    return find_reference(str - kernel + kerndumpbase, n, prelink);
//}
size_t tfp0_kread(uint64_t where, void *p, size_t size)
{
    int rv;
    size_t offset = 0;
    while (offset < size) {
        mach_vm_size_t sz, chunk = 2048;
        if (chunk > size - offset) {
            chunk = size - offset;
        }
        rv = mach_vm_read_overwrite(tfp0, where + offset, chunk, (mach_vm_address_t)p + offset, &sz);
        
        if (rv || sz == 0) {
            break;
        }
        
        offset += sz;
    }
    return offset;
}


size_t kwrite(uint64_t where, const void *p, size_t size) {
    int rv;
    size_t offset = 0;
    while (offset < size) {
        size_t chunk = 2048;
        if (chunk > size - offset) {
            chunk = size - offset;
        }
        rv = mach_vm_write(tfp0,
                           where + offset,
                           (mach_vm_offset_t)p + offset,
                           (mach_msg_type_number_t)chunk);
        
        if (rv) {
            printf("[kernel] error copying buffer into region: @%p \n", (void *)(offset + where));
            break;
        }
        
        offset +=chunk;
    }
    
    return offset;
}

size_t kwrite_uint64(uint64_t where, uint64_t value) {
    return kwrite(where, &value, sizeof(value));
}

int cp(const char *to, const char *from)
{
    int fd_to, fd_from;
    char buf[4096];
    ssize_t nread;
    int saved_errno;
    
    fd_from = open(from, O_RDONLY);
    if (fd_from < 0)
        return -1;
    
    fd_to = open(to, O_WRONLY | O_CREAT | O_EXCL, 0666);
    if (fd_to < 0)
        goto out_error;
    
    while (nread = read(fd_from, buf, sizeof buf), nread > 0)
    {
        char *out_ptr = buf;
        ssize_t nwritten;
        
        do {
            nwritten = write(fd_to, out_ptr, nread);
            
            if (nwritten >= 0)
            {
                nread -= nwritten;
                out_ptr += nwritten;
            }
            else if (errno != EINTR)
            {
                goto out_error;
            }
        } while (nread > 0);
    }
    
    if (nread == 0)
    {
        if (close(fd_to) < 0)
        {
            fd_to = -1;
            goto out_error;
        }
        close(fd_from);
        
        /* Success! */
        return 0;
    }
    
out_error:
    saved_errno = errno;
    
    close(fd_from);
    if (fd_to >= 0)
        close(fd_to);
    
    errno = saved_errno;
    return -1;
}
