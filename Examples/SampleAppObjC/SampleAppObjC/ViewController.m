//
//  ViewController.m
//  SampleAppObjC
//
//  Created by Abhishek Pandey on 18/03/22.
//

#import "ViewController.h"
@import Rudder;


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSDate *birthday = [[NSDate alloc] init];
    [[RSClient sharedInstance] identify:@"New User 2" traits: @{
        @"birthday": birthday,
        @"address": @{
            @"city": @"Kolkata",
            @"country": @"India"
        },
        @"firstname": @"Shweta",
        @"lastname": @"Salvi",
        @"name": @"Shweta",
        @"gender": @"female",
        @"phone": @"0123456789",
        @"email": @"User1@gmail.com",
        @"key-1": @"value-1",
        @"key-2": @1234
    }];
    
    [[RSClient sharedInstance] track:@"New Track event"];
    
    [[RSClient sharedInstance] track:@"New Track event" properties:@{
        @"key_1" : @"value_1",
        @"key_2" : @"value_2"
    }];
    
    [[RSClient sharedInstance] alias:@"New User 2"];
    
}


@end
