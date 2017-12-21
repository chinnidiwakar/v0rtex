//
//  kernelutils.h
//  v0rtexMod
//
//  Created by dns on 12/20/17.
//  Copyright © 2017 din3zh. All rights reserved.
//

#ifndef kernelutils_h
#define kernelutils_h
#include <mach/mach.h>

uint64_t rk64_with_tfp0(task_t tfp0, uint64_t kaddr);
uint32_t rk32_with_tfp0(task_t tfp0, uint64_t kaddr);
void wk32_with_tfp0(task_t tfp0, uint64_t kaddr, uint32_t val);
void init_kernel(task_t tfp0);
size_t tfp0_kread(uint64_t where, void *p, size_t size);

void wk64_with_tfp0(task_t tfp, uint64_t kaddr, uint64_t val);


size_t kwrite(uint64_t where, const void *p, size_t size);
size_t kwrite_uint64(uint64_t where, uint64_t value);



kern_return_t mach_vm_write(
                            vm_map_t target_task,
                            mach_vm_address_t address,
                            vm_offset_t data,
                            mach_msg_type_number_t dataCnt);

kern_return_t mach_vm_read_overwrite(
                                     vm_map_t target_task,
                                     mach_vm_address_t address,
                                     mach_vm_size_t size,
                                     mach_vm_address_t data,
                                     mach_vm_size_t *outsize);

kern_return_t mach_vm_allocate(vm_map_t, mach_vm_address_t *, mach_vm_size_t, int);


#endif /* kernelutils_h */
