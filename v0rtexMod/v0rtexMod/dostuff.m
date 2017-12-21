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
#include <mach-o/dyld.h>


#include "v0rtex.h"
#include "common.h"
#include "dostuff.h"

#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>

#include <dirent.h>
#include "remountrootrw.h"

#include "patchfinder64.h"

#include "kernelutils.h"
#import "libjb.h"


#import <mach-o/loader.h>// mach_vm_allocate + others
#import <CommonCrypto/CommonDigest.h>
#include <spawn.h>

#define BOOTSTRAP_PREFIX "bootstrap"




task_t tfp0;
uint64_t trust_cache;
uint64_t amficache;

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
            printf("kernel_task = 0x%x\n", tfp0);
            if(MACH_PORT_VALID(tfp0))
            {
                
                setuid(0); //replace this with a function and then create function to setuid back to original else panic
             //   writeTestFileToMobileDirectory();
                
                init_patchfinder(tfp0, kslide + 0xFFFFFFF007004000, NULL);
                
                 init_amfi(tfp0);
                init_kernel(tfp0);
                
                remountRootfs(tfp0, kslide);
                writeTestFileToSpecifiedDirectory(".dnstest0003", "/");
                unlink(".dnstest0001");
                
             
                
            }
        }
    }
    return ret;
}

//void writeTestFileToMobileDirectory(void)
//{
//    printf("####writeTestFileToMobileDirectory called !!");
//    setuid(0);
//    FILE *f = fopen("/var/mobile/dnstry01", "w");
//    if (f == 0) {
//        printf("Write to %p failed!!\n", f);
//        listDirectory("/var/mobile/");
//    } else {
//        printf("Successfully wrote to %p!!\n", f);
//        listDirectory("/var/mobile/");
//    }
//    fclose(f);
//}

void writeTestFileToSpecifiedDirectory(char* filename, char* dirtolist)
{
    printf("####writeTestFileToSpecifiedDirectory called !!");
    setuid(0);
    FILE *f = fopen(filename, "w");
    if (f == 0) {
        printf("Write to %s failed!!\n", filename);
     //   listDirectory(dirtolist);
    } else {
        printf("Successfully wrote to %s!!\n", filename);
      //  listDirectory(dirtolist);
    }
    fclose(f);
}

void remountRootfs(task_t tfp0, uint64_t kslide)
{
    int remountStatus = remountrootrw(tfp0, kslide);
    printf("remountStatus=%d",remountStatus);
    if (remountStatus == 0) {
        printf("\nremount success\n");
    }
    
}

void listDirectory(char* dir){
    printf("####listDirectory called !!");
    DIR *dirpointer;
    struct dirent *xp;
    dirpointer = opendir(dir);
    if (dirpointer != NULL){
        while (xp = readdir(dirpointer)){
            printf("%s\n",xp->d_name);
        }
        (void)closedir(dirpointer);
    } else {
        printf("Failed to open dir\n");
    }
}

void init_amfi(task_t task_for_port0) {
    tfp0 = task_for_port0;
    trust_cache = find_trustcache();
    amficache = find_amficache();
    
    term_kernel();
    
    printf("trust_cache = 0x%llx \n", trust_cache);
    printf("amficache = 0x%llx \n", amficache);
}
//
//void copyFiles(char* iOSapplicationPath){
//    printf("####copyFiles called !!\n");
//    printf ("iOSapplicationPath=%s\n",iOSapplicationPath);
//    mkdir("/dnstestdir1/", 0755);
//    cpFile(concatTwoStrings(iOSapplicationPath,"/tar"), "/dnstestdir1/tar");
//}
//
//// from https://stackoverflow.com/questions/5901181/c-string-append
//char* concatTwoStrings(char *str1, char *str2){
//    char * new_str ;
//    if((new_str = malloc(strlen(str1)+strlen(str2)+1)) != NULL){
//        new_str[0] = '\0';   // ensures the memory is an empty string
//        strcat(new_str,str1);
//        strcat(new_str,str2);
//    }else {
//        printf("malloc failed");
//        fprintf(stderr,"malloc failed!\n");
//        // exit?
//    }
//    return new_str;
//}
// creds to xerub for grab_hashes (and ty for libjb update!)
void trust_files(const char *path) {
    struct trust_mem mem;
    mem.next = rk64_with_tfp0(tfp0, trust_cache);
    *(uint64_t *)&mem.uuid[0] = 0xabadbabeabadbabe;
    *(uint64_t *)&mem.uuid[8] = 0xabadbabeabadbabe;
    
    grab_hashes(path, tfp0_kread, amficache, mem.next);
    
    size_t length = (sizeof(mem) + numhash * 20 + 0xFFFF) & ~0xFFFF;
    
    uint64_t kernel_trust;
    mach_vm_allocate(tfp0, (mach_vm_address_t *)&kernel_trust, length, VM_FLAGS_ANYWHERE);
    
    mem.count = numhash;
    kwrite(kernel_trust, &mem, sizeof(mem));
    kwrite(kernel_trust + sizeof(mem), allhash, numhash * 20);
    kwrite_uint64(trust_cache, kernel_trust);
    
    free(allhash);
    free(allkern);
    free(amfitab);
    
    printf("amfi patches applied at %s (%d files) \n", path, numhash);
}

void inject_trust(const char *path, task_t tfp0) {
    printf("Inside inject_trust");
    typedef char hash_t[20];
    
    struct trust_chain {
        uint64_t next;
        unsigned char uuid[16];
        unsigned int count;
        hash_t hash[1];
    };
    
    struct trust_chain fake_chain;
    
    fake_chain.next = rk64_with_tfp0(tfp0,trust_cache);
    *(uint64_t *)&fake_chain.uuid[0] = 0xabadbabeabadbabe;
    *(uint64_t *)&fake_chain.uuid[8] = 0xabadbabeabadbabe;
    fake_chain.count = 1;
    
    uint8_t *codeDir = getCodeDirectory(path);
    if (codeDir == NULL) {
        printf("[amfi] was given null code dir for %s ! \n", path);
        return;
    }
    
    uint8_t *hash = getSHA256(codeDir);
    memmove(fake_chain.hash[0], hash, 20);
    
    free(hash);
    
    uint64_t kernel_trust = 0;
    mach_vm_allocate(tfp0, &kernel_trust, sizeof(fake_chain), VM_FLAGS_ANYWHERE);
    
    kwrite(kernel_trust, &fake_chain, sizeof(fake_chain));
    wk64_with_tfp0(tfp0,trust_cache, kernel_trust);
    
    
    printf("[amfi] signed %s \n", path);
}


void inject_trusts(int pathc, const char *paths[],task_t tfp0) {
    for (int i = 0; i != pathc; ++i) {
        inject_trust(paths[i], tfp0);
    }
    return;
    
    typedef char hash_t[20];
    
    struct trust_chain {
        uint64_t next;                 // +0x00 - the next struct trust_mem
        unsigned char uuid[16];        // +0x08 - The uuid of the trust_mem (it doesn't seem important or checked apart from when importing a new trust chain)
        unsigned int count;            // +0x18 - Number of hashes there are
        // hash_t hash[pathc];             // +0x1C - The hashes
    };
    
    int chain_size = sizeof(struct trust_chain) + pathc * sizeof(hash_t);
    struct trust_chain* fake_chain = malloc(chain_size);
    
    uint8_t hashto[CC_SHA256_DIGEST_LENGTH];
    
    hash_t *cur_hash = (hash_t *)((uint8_t*)fake_chain + sizeof(fake_chain));
    for (int i = 0; i != pathc; ++i) {
        getSHA256inplace(getCodeDirectory(paths[i]), hashto);
        memmove(cur_hash, hashto, 20);
        ++cur_hash;
    }
    
    *(uint64_t *)&fake_chain->uuid[0] = 0xabadbabeabadbabe;
    *(uint64_t *)&fake_chain->uuid[8] = 0xabadbabeabadbabe;
    fake_chain->count = pathc;
    
    uint64_t tc = find_trustcache();
    
    printf("trust cache at: %016llx\n", rk64_with_tfp0(tfp0,tc));
    
    fake_chain->next = rk64_with_tfp0(tfp0,tc);
    
    uint64_t kernel_trust = kalloc(chain_size);
    kwrite(kernel_trust, fake_chain, chain_size);
    
    free(fake_chain);
    
    // Comment this line out to see `amfid` saying there is no signature on test_fsigned (or your binary)
    wk64_with_tfp0(tfp0,tc, kernel_trust);
}

static uint64_t kalloc(vm_size_t size){
    mach_vm_address_t address = 0;
    mach_vm_allocate(tfp0, (mach_vm_address_t *)&address, size, VM_FLAGS_ANYWHERE);
    return address;
}

// creds to nullpixel

uint8_t *getCodeDirectory(const char* name) {
    FILE* fd = fopen(name, "r");
    
    struct mach_header_64 mh;
    fread(&mh, sizeof(struct mach_header_64), 1, fd);
    
    long off = sizeof(struct mach_header_64);
    for (int i = 0; i < mh.ncmds; i++) {
        const struct load_command cmd;
        fseek(fd, off, SEEK_SET);
        fread(&cmd, sizeof(struct load_command), 1, fd);
        if (cmd.cmd == 0x1d) {
            uint32_t off_cs;
            fread(&off_cs, sizeof(uint32_t), 1, fd);
            uint32_t size_cs;
            fread(&size_cs, sizeof(uint32_t), 1, fd);
            
            uint8_t *cd = malloc(size_cs);
            fseek(fd, off_cs, SEEK_SET);
            fread(cd, size_cs, 1, fd);
            
            return cd;
        } else {
            off += cmd.cmdsize;
        }
    }
    
    return NULL;
}

// creds to nullpixel
void getSHA256inplace(const uint8_t* code_dir, uint8_t *out) {
    if (code_dir == NULL) {
        printf("NULL passed to getSHA256inplace!\n");
        return;
    }
    uint32_t* code_dir_int = (uint32_t*)code_dir;
    
    uint32_t realsize = 0;
    for (int j = 0; j < 10; j++) {
        if (swap_uint32(code_dir_int[j]) == 0xfade0c02) {
            realsize = swap_uint32(code_dir_int[j+1]);
            code_dir += 4*j;
        }
    }
    //    printf("%08x\n", realsize);
    
    CC_SHA256(code_dir, realsize, out);
}

uint8_t *getSHA256(uint8_t* code_dir) {
    uint8_t *out = malloc(CC_SHA256_DIGEST_LENGTH);
    
    uint32_t* code_dir_int = (uint32_t*)code_dir;
    
    uint32_t realsize = 0;
    for (int j = 0; j < 10; j++) {
        if (swap_uint32(code_dir_int[j]) == 0xfade0c02) {
            realsize = swap_uint32(code_dir_int[j+1]);
            code_dir += 4*j;
        }
    }
    
    CC_SHA256(code_dir, realsize, out);
    
    return out;
}

uint32_t swap_uint32(uint32_t val) {
    val = ((val << 8) & 0xFF00FF00) | ((val >> 8) & 0xFF00FF);
    return (val << 16) | (val >> 16);
}

uint32_t start_binary(const char *bin,const char* args[], task_t tfp0){
    //inject trust
    inject_trust(bin,tfp0);
    
    //return 0;
    
    printf("Spawning binary application: %s\n",bin);
    int pid;
    int rv = posix_spawn(&pid, bin, NULL, NULL, (char**)args, NULL);
    printf("Application started, has pid: %d, rv=%d\n",pid,rv);
    //waitpid(pid, NULL, 0);
    sleep(5);
    return pid;
}


int process_binlist(const char *path) {
    // first line -- count since I'm too lazy
    
    FILE *binlist = fopen(path, "r");
    
    if (binlist == NULL) {
        printf("WTF no binlist?!\n");
        return -1;
    }
    
    int pathcount;
    fscanf(binlist, " %u", &pathcount);
    
    char **paths = malloc(sizeof(char*) * pathcount);
    size_t len = 4096;
    ssize_t nread;
    char readpath[4096];
    
    strcpy(readpath, "/" BOOTSTRAP_PREFIX "/");
    char *readto = readpath + strlen("/" BOOTSTRAP_PREFIX "/");
    
   
    int i;
    for (i = 0; i != pathcount;) {
        // XXX can getline change readto?..
        nread = getline(&readto, &len, binlist);
        
        if (nread == -1) break;
        if (readto[nread - 1] == '\n') readto[nread - 1] = '\0';
        
        struct stat statmedaddy;
        int rv = stat(readpath, &statmedaddy);
        if (rv == 0 && S_ISREG(statmedaddy.st_mode)) {
            paths[i] = strdup(readpath);
            ++i;
        } else {
            printf("(/" BOOTSTRAP_PREFIX "/)'%s' in binlist but isn't file/doesn't exist\n", readto);
        }
    }
    
    // XXX can be negative huh
    pathcount = i - 1;
    
    inject_trusts(pathcount, (const char**)paths, tfp0);
    
    printf("\nhey am at end of processbinlist\n");
//    for (i = 0; i != pathcount; ++i) {
//        free(paths[i]);
//    }
//    free(paths);
//    fclose(binlist);
    
    return 0;
}


const char* progname(const char* prog) {
    char path[4096];
    uint32_t size = sizeof(path);
    
    _NSGetExecutablePath(path, &size);
    char *pt = realpath(path, NULL);
    
    NSString *execpath = [[NSString stringWithUTF8String:pt] stringByDeletingLastPathComponent];
    
    NSString *bootstrap = [execpath stringByAppendingPathComponent:[NSString stringWithUTF8String:prog]];
    return [bootstrap UTF8String];
}

