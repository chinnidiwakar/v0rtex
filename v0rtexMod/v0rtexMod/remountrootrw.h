//
//  remountrootrw.h
//  v0rtexMod
//
//  Created by dns on 12/20/17.
//  Copyright © 2017 din3zh. All rights reserved.
//
#include <mach/mach.h>
#include <sys/mount.h>

#ifndef remountrootrw_h
#define remountrootrw_h

int remountrootrw(task_t tfp0, uint64_t kslide);

#endif /* remountrootrw_h */
