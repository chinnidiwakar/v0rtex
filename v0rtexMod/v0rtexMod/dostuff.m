//
//  dostuff.m
//  v0rtexMod
//
//  Created by dns on 12/20/17.
//  Copyright © 2017 din3zh. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/mach_port.h>
#include <mach/mach_time.h>
#include <mach/mach_traps.h>
#include <mach/mach_voucher_types.h>
#include <mach/port.h>

#include "v0rtex.h"
#include "common.h"

#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

int doit(void)
{
    printf("Starting work");
    int ret = 0;
    //confirm again if (getuid() != 0)
    if(getuid() != 0){
        printf("getuid() != 0)");
        
        vm_address_t kbase = 0;
        task_t tfp0 = MACH_PORT_NULL;
        kptr_t kslide = 0;
        kern_return_t v0rtex(task_t *tfp0, kptr_t *kslide);
        kern_return_t ret = v0rtex(&tfp0, &kslide);
        
        if(ret == KERN_SUCCESS)
        {
            printf("\nIn ret == KERN_SUCCESS\n");
        }
    }
    printf("ret=%d: ",ret);
    return ret;
}
