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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //Writing stuff directly here during the test phase coz am lazy to click the button
    
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
        }else{
            printf("doit failed!\n");
        }
    }
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
            printf("w00tw00t doit() successed!!\n");
            setuid(0);
            
            
        }else{
            printf("doit failed!\n");
        }
    }
    
}
@end
