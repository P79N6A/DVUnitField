//
//  ViewController.m
//  ADUnitField
//
//  Created by David on 2018/12/17.
//  Copyright © 2018年 ADIOS. All rights reserved.
//

#import "ViewController.h"
#import "ADUnitField.h"

@interface ViewController () <ADUnitFieldDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    ADUnitField *unitField = [[ADUnitField alloc]initWithStyle:ADUnitFieldStyleUnderline count:3];
    unitField.delegate = self;
    [self.view addSubview:unitField];
    unitField.frame = CGRectMake(0, 100, 200, 50);
}

- (BOOL)unitField:(ADUnitField *)uniField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

@end
