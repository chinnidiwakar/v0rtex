//
//  ViewController.m
//  v0rtexMod
//
//  Created by dns on 12/20/17.
//  Copyright © 2017 din3zh. All rights reserved.
//

#import "ViewController.h"
#import "v0rtex.h"
#import "symbols.h"
#import "dostuff.h"
#include <sys/stat.h> //mkdir
#include <dlfcn.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#include "kernelutils.h"
#include "patchfinder64.h"

#define BOOTSTRAP_PREFIX "bootstrap"


task_t tfp0;
//
//void init_kernel(task_t task_for_port0) {
//    tfp0 = task_for_port0;
//}

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //Writing stuff directly here during the test phase coz am lazy to click the button
    
   
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)startButton:(id)sender {
    NSLog(@"And it starts !!");
//    kern_return_t ret = v0rtex(NULL, NULL);
//
//    if(ret == KERN_SUCCESS)
//    {
//        printf("ret == KERN_SUCCESS");
//    }
    
    //Initialize the symbols
    if (init_symbols()) {
        printf("Symbols found will proceed.\n");
    }else{
        printf("Device not supported.");
        return;
    }
    
    if(getuid() != 0)
    {
        NSLog(@"getuid() != 0\n");
        
        if(doit()==0)
        {
            
            printf("w00tw00t!!\n");
            setuid(0);
            
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            NSString *bundlePath = [NSString stringWithFormat:@"%s", bundle_path()];
            
            [fileMgr removeItemAtPath:@"/dnsfiles/dropbear" error:nil];
            [fileMgr removeItemAtPath:@"/dnsfiles/bootstrap.tar" error:nil];
            [fileMgr removeItemAtPath:@"/dnsfiles/gnubinpack.tar" error:nil];
            [fileMgr removeItemAtPath:@"/dnsfiles/tar" error:nil];
            [fileMgr removeItemAtPath:@"/dnsfiles/bins" error:nil];
            [fileMgr removeItemAtPath:@"/dnsfiles" error:nil];
            [fileMgr removeItemAtPath:@"/bin/sh" error:nil];
            
            mkdir("/dnsfiles", 0777);
            mkdir("/dnsfiles/bins", 0777);
            mkdir("/dnsfiles/logs", 0777);
            
            printf("Copying Binary files now");
            
            [fileMgr copyItemAtPath:[bundlePath stringByAppendingString:@"/bootstrap.tar"]
                             toPath:@"/dnsfiles/bootstrap.tar" error: nil];
            [fileMgr copyItemAtPath:[bundlePath stringByAppendingString:@"/dropbear"]
                             toPath:@"/dnsfiles/dropbear" error: nil];
            
            [fileMgr copyItemAtPath:[bundlePath stringByAppendingString:@"/tar"]
                             toPath:@"/dnsfiles/tar" error:nil];
            [fileMgr copyItemAtPath:[bundlePath stringByAppendingString:@"/bash"]
                             toPath:@"/bin/sh" error:nil];
            
            chmod("/dnsfiles/dropbear", 0777);
            chmod("/dnsfiles/tar", 0777);
            chmod("/bin/sh", 0777);
            
            
            mkdir("/etc", 0777);
            mkdir("/etc/dropbear", 0777);
            mkdir("/var", 0777);
            mkdir("/var/log", 0777);
            FILE *lastLog = fopen("/var/log/lastlog", "ab+");
            fclose(lastLog);
            
            mkdir("/dnsfiles/etc", 0777);
            mkdir("/dnsfiles/etc/dropbear", 0777);
            mkdir("/dnsfiles/var", 0777);
            mkdir("/dnsfiles/var/log", 0777);
            
            inject_trust("/bin/sh",tfp0);
            inject_trust("/dnsfiles/dropbear",tfp0);
            inject_trust("/dnsfiles/tar",tfp0);
            
            
            start_binary("/dnsfiles/tar", (char **)&(const char*[]){"/dnsfiles/tar","-xpf","/dnsfiles/bootstrap.tar", "-C", "/dnsfiles",NULL}, tfp0);
            
            trust_files("/dnsfiles/bins");
            
            start_binary("/dnsfiles/dropbear", (char **)&(const char*[]){"/dnsfiles/dropbear", "-R", "-E", "-m", "-F", "-S", "/", NULL}, tfp0);
            
        }else{
            printf("doit failed!\n");
        }
    }
    
}
char* bundle_path() {
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
    int len = 4096;
    char* path = malloc(len);
    
    CFURLGetFileSystemRepresentation(resourcesURL, TRUE, (UInt8*)path, len);
    
    return path;
}

char* appendString(char *str1, char *str2){
    char * new_str ;
    if((new_str = malloc(strlen(str1)+strlen(str2)+1)) != NULL){
        new_str[0] = '\0';   // ensures the memory is an empty string
        strcat(new_str,str1);
        strcat(new_str,str2);
    }
    return new_str;
}

@end
