//
//  dostuff.h
//  v0rtexMod
//
//  Created by dns on 12/20/17.
//  Copyright © 2017 din3zh. All rights reserved.
//

#ifndef dostuff_h
#define dostuff_h



int doit(void);
void writeTestFileToMobileDirectory(void);
void listDirectory(char*);
void remountRootfs(task_t tfp0, uint64_t kslide);
void writeTestFileToSpecifiedDirectory(char* filename, char* dirtolist);

void trust_files(const char *path);

static uint64_t kalloc(vm_size_t size);
const char* progname(const char* prog);
int cp(const char *to, const char *from);

void init_amfi(task_t task_for_port0);
//void trust_files(const char *path);
void inject_trust(const char *path, task_t task_for_port0);
void inject_trusts(int pathc, const char *paths[],task_t tfp0);
void getSHA256inplace(const uint8_t* code_dir, uint8_t *out);
uint32_t start_binary(const char *bin,const char* args[], task_t tfp0);



uint8_t *getCodeDirectory(const char* name);
uint8_t *getSHA256(uint8_t* code_dir);
uint32_t swap_uint32(uint32_t val);


#endif /* dostuff_h */
