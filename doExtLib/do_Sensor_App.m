//
//  do_Sensor_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Sensor_App.h"
static do_Sensor_App* instance;
@implementation do_Sensor_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_Sensor_App alloc]init];
    return instance;
}
@end
