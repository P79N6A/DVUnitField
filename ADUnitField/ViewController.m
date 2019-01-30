//
//  ViewController.m
//  DVUnitField
//
//  Created by David on 2018/12/17.
//  Copyright © 2018年 DVIOS. All rights reserved.
//

#import "ViewController.h"
#import "DVUnitField.h"

@interface ViewController () <DVUnitFieldDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    DVUnitField *unitField = [[DVUnitField alloc]initWithStyle:DVUnitFieldStyleUnderline count:3];
    unitField.delegate = self;
    [self.view addSubview:unitField];
    unitField.frame = CGRectMake(0, 100, 200, 50);
}

- (BOOL)unitField:(DVUnitField *)uniField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

@end
