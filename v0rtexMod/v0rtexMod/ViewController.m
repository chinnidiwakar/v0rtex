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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
        LOG("Symbols found will proceed.");
    }else{
        LOG("Device not supported.");
        return;
    }
}
@end
