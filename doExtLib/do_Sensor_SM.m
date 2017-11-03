//
//  do_Sensor_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Sensor_SM.h"
#import <UIKit/UIKit.h>

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonHelper.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"
#import <CoreMotion/CoreMotion.h>

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

@implementation do_Sensor_SM
{
    __block NSMutableDictionary *_data;
    CMMotionManager *_motionMgr;
}
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
- (instancetype)init
{
    self = [super init];
    if (self) {
        _motionMgr = [[CMMotionManager alloc] init];
        _motionMgr.deviceMotionUpdateInterval = .1;
        _data = [NSMutableDictionary dictionary];
        
        //初始化各种传感器数据
        for(int i=1;i<6;i++)
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [_data setObject:dict forKey:@(i)];
        }
    }
    return self;
}
//同步
- (void)getSensorData:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    int sensorType = [doJsonHelper GetOneInteger:_dictParas :@"sensorType" :0];
    if (sensorType<0 || sensorType>5) {
        return;
    }
    //_invokeResult设置返回值
    NSMutableDictionary *data = [_data objectForKey:@(sensorType)];
    if (sensorType==1) {
        if (!_motionMgr.accelerometerAvailable) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"加速度传感器不可用"];
            return;
        }
    }else if (sensorType==2){
        if (!_motionMgr.magnetometerAvailable) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"罗盘传感器不可用"];
            return;
        }
    }else if (sensorType==3){
        if (!_motionMgr.isDeviceMotionAvailable) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"转角传感器不可用"];
            return;
        }
    }else if (sensorType==4){
        if (!_motionMgr.isGyroAvailable) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"陀螺仪传感器不可用"];
            return;
        }
    }else if (sensorType==5){
        [UIDevice currentDevice].proximityMonitoringEnabled=YES;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(proximity) name:UIDeviceProximityStateDidChangeNotification object:nil];
    }
    if (data) {
        [_invokeResult SetResultNode:data];
    }
}
- (void)start:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //_invokeResult设置返回值
    
    int sensorType = [doJsonHelper GetOneInteger:_dictParas :@"sensorType" :0];
    if (sensorType<0 || sensorType>5) {
        return;
    }
    
    if (sensorType==1) {
        if (!_motionMgr.accelerometerAvailable) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"加速度传感器不可用"];
            return;
        }
        [_motionMgr startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
            CMAccelerometerData *accelData = _motionMgr.accelerometerData;
            double x = accelData.acceleration.x;
            double y = accelData.acceleration.y;
            double z = accelData.acceleration.z;

            [self fireEvent:x :y :z :sensorType];
        }];
        return;
    }else if (sensorType==2){
        if (!_motionMgr.magnetometerAvailable) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"罗盘传感器不可用"];
            return;
        }
        [_motionMgr startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
            CMMagneticField field = _motionMgr.magnetometerData.magneticField;

            [self fireEvent:field.x :field.y :field.z :sensorType];
        }];
        return;
    }else if (sensorType==3){
        if (!_motionMgr.isDeviceMotionAvailable) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"转角传感器不可用"];
            return;
        }
        [_motionMgr startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *data, NSError *error) {
            CMAttitude *attitude = _motionMgr.deviceMotion.attitude;
            
            double x = RADIANS_TO_DEGREES(attitude.pitch);
            double y = RADIANS_TO_DEGREES(attitude.roll);
            double z = RADIANS_TO_DEGREES(attitude.yaw);
            
            [self fireEvent:x :y :z :sensorType];
        }];
        return;
    }else if (sensorType==4){
        if (!_motionMgr.isGyroAvailable) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"陀螺仪传感器不可用"];
            return;
        }
        [_motionMgr startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
            double x = gyroData.rotationRate.x;
            double y = gyroData.rotationRate.y;
            double z = gyroData.rotationRate.z;
            
            [self fireEvent:x :y :z :sensorType];
        }];
        return;
    }else if (sensorType==5){
        [UIDevice currentDevice].proximityMonitoringEnabled=YES;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(proximity) name:UIDeviceProximityStateDidChangeNotification object:nil];
    }
}

- (void)proximity
{
    if ([UIDevice currentDevice].proximityState) {
        [self fireEvent:1 :0 :0 :5];
    }else
        [self fireEvent:0 :0 :0 :5];
}
- (void)fireEvent:(double)x :(double)y :(double)z :(int)type
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableDictionary *dict1 = [NSMutableDictionary dictionary];
    [dict setObject:@(x) forKey:@"x"];
    [dict setObject:@(y) forKey:@"y"];
    [dict setObject:@(z) forKey:@"z"];
    
    [dict1 setObject:@(type) forKey:@"sensorType"];
    [dict1 setObject:dict forKey:@"data"];
    
    [_data setObject:dict1 forKey:@(type)];
    
    doInvokeResult *invokeResult = [doInvokeResult new];
    [invokeResult SetResultNode:dict1];
    [self.EventCenter FireEvent:@"change" :invokeResult];
}
- (void)stop:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //_invokeResult设置返回值
    int sensorType = [doJsonHelper GetOneInteger:_dictParas :@"sensorType" :0];
    if (sensorType<0 || sensorType>5) {
        return;
    }
    if (sensorType==1) {
        [_motionMgr stopAccelerometerUpdates];
    }else if (sensorType==2){
        [_motionMgr stopMagnetometerUpdates];
    }else if (sensorType==3){
        [_motionMgr stopDeviceMotionUpdates];
    }else if (sensorType==4){
        [_motionMgr stopGyroUpdates];
    }else if (sensorType==5){
        [UIDevice currentDevice].proximityMonitoringEnabled=NO;
        [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil ];
    }
}
//异步

@end