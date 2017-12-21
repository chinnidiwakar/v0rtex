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
#include "dostuff.h"

#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#include <dirent.h>

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
            printf("kernel_task = 0x%x", tfp0);
            if(MACH_PORT_VALID(tfp0))
            {
                writeTestFileToMobileDirectory();
            }
        }
    }
    return ret;
}

void writeTestFileToMobileDirectory(void)
{
    printf("####writeTestFileToMobileDirectory called !!");
    setuid(0);
    FILE *f = fopen("/var/mobile/dnstry01", "w");
    if (f == 0) {
        printf("Write to %p failed!!\n", f);
        listDirectory("/var/mobile/");
    } else {
        printf("Successfully wrote to %p!!\n", f);
        listDirectory("/var/mobile/");
    }
    fclose(f);
}

void listDirectory(char* dir){
    printf("####listDirectory called !!");
    DIR *dirpointer;
    struct dirent *xp;
    dirpointer = opendir(dir);
    if (dirpointer != NULL){
        while (xp == readdir(dirpointer)){
            printf("%s\n",xp->d_name);
        }
        (void)closedir(dirpointer);
    } else {
        printf("Failed to open dir\n");
    }
}
