/*
 * Copyright (C) 2015 Elastos.org
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#import "DeviceManager.h"
#import "TSMessage.h"
#import <WhisperManagedCore/WhisperManagedCore.h>

static NSString * const ElastosCarrierService = @"192.168.7.195:18080";
static NSString * const ElastosCarrierAPIservice = @"192.168.7.195:8443";
static NSString * const APPID = @"3DF1AC53C8BE42EFB14426DECEA2BFDD";
static int const KMaxSessionNum = 2;

static NSString * const KEY_CurrentDeviceID = @"currentDeviceID";
static NSString * const KEY_CurrentDeviceName = @"currentDeviceName";


typedef NS_ENUM (int, ServerConnectStatus) {
    ServerConnectStatusDisconnected = 0,
    ServerConnectStatusConnecting   = 1,
    ServerConnectStatusConnected    = 2,
};

@interface DeviceManager () <ECSClientDelegate>
{
    BOOL initializerd;
    ServerConnectStatus connectStatus;
    BOOL needUpdateDeviceList;
    NSMutableArray *_devices;
    dispatch_queue_t managerDeviceQueue;
}

@end

@implementation DeviceManager

+ (DeviceManager *)sharedManager
{
    static DeviceManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

-(instancetype)init {
    if (self = [super init]) {
        _devices = [[NSMutableArray alloc] init];
        
        NSString *currentDeviceID = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_CurrentDeviceID];
        if (currentDeviceID) {
            NSString *currentDeviceName = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_CurrentDeviceName];
            _currentDevice = [[Device alloc] initWithDeviceId:currentDeviceID name:currentDeviceName];
            _currentDevice.status = ECSDeviceEventOffline;
            [_devices addObject:_currentDevice];
        }
        
        managerDeviceQueue = dispatch_queue_create("managerDeviceQueue", NULL);
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    if (initializerd || connectStatus == ServerConnectStatusConnecting) {
        return;
    }
    
    connectStatus = ServerConnectStatusConnecting;
    
    dispatch_async(managerDeviceQueue, ^{
        NSError *error = nil;
        initializerd = [[ECSClient shareInstance] startClient:self error:&error];
        if (error && error.code == ECSDevErrorCode_AlreadyStarted) {
            initializerd = YES;
            error = nil;
        }
        
        if (initializerd) {
            initializerd = [[ECSSessionManager shareInstance] initialize:KMaxSessionNum error:&error];
            if (error && error.code == ECSSessionErrorCode_AlreadyStarted) {
                initializerd = YES;
                error = nil;
            }
            
            if (initializerd) {
                initializerd = [[ECSTunnel shareInstance] initialize:&error];
                if (initializerd) {
                    [[ECSTunnel shareInstance] start];
                }
            }
        }
        else {
            connectStatus = ServerConnectStatusDisconnected;
        }
    });
}

- (void)setCurrentDevice:(Device *)device
{
    if (device == nil) {
        _currentDevice = nil;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_CurrentDeviceID];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_CurrentDeviceName];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if (device != _currentDevice && [_devices containsObject:device]) {
        _currentDevice = device;
        [[NSUserDefaults standardUserDefaults] setObject:device.deviceID forKey:KEY_CurrentDeviceID];
        [[NSUserDefaults standardUserDefaults] setObject:device.deviceName forKey:KEY_CurrentDeviceName];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (_currentDevice.status == ECSDeviceEventOnline)
        {
            [_currentDevice connect];
        }
        else {
            DLog(@"Current device status : %d", _currentDevice.status);
        }
    }
}

- (void)updateDeviceList
{
    if (connectStatus != ServerConnectStatusConnected) {
        needUpdateDeviceList = YES;
        [self initialize];
        return;
    }
    
    dispatch_async(managerDeviceQueue, ^{
        NSError *error = nil;
        NSArray *deviceInfo = [[ECSClient shareInstance] getDevices:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (deviceInfo == nil) {
                NSLog(@"get device list failed : %@", error);
                if (error.code == ECSDevErrorCode_ClientOffLine) {
                    for (Device *device in _devices) {
                        [device disconnect];
                    }
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdateFailed object:nil userInfo:nil];
                return;
            } else {
                NSMutableArray *deletedDevices = [NSMutableArray arrayWithArray:_devices];
                for (ECSDeviceInfo *device in deviceInfo) {
                    BOOL existed = NO;
                    for (Device *oldDevice in deletedDevices) {
                        if ([device.deviceID isEqualToString:oldDevice.deviceID]) {
                            [oldDevice performSelectorOnMainThread:@selector(setDeviceName:) withObject:device.name waitUntilDone:YES];
                            oldDevice.status = device.status;
                            [deletedDevices removeObject:oldDevice];
                            existed = YES;
                            break;
                        }
                    }
                    
                    if (!existed) {
                        Device *newDevice = [[Device alloc] initWithDeviceId:device.deviceID name:device.name];
                        newDevice.status = device.status;
                        [_devices addObject:newDevice];
                    }
                }
                
                if (deletedDevices.count > 0) {
                    [_devices removeObjectsInArray:deletedDevices];
                    if (_devices.count == 0 || [deletedDevices containsObject:_currentDevice]) {
                        self.currentDevice = nil;
                    }
                }
                
                if (_currentDevice) {
                    if (![_currentDevice.deviceName isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:KEY_CurrentDeviceName]]) {
                        [[NSUserDefaults standardUserDefaults] setObject:_currentDevice.deviceName forKey:KEY_CurrentDeviceName];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    
                    [_currentDevice connect];
                }
//                else if (_devices.count > 0) {
//                    self.currentDevice = _devices[0];
//                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];
            }
        });
    });
}

- (void)getDeviceName:(NSString *)deviceID
      completionBlock:(void (^)(NSString *deviceName, NSError *error))completionBlock
{
    dispatch_async(managerDeviceQueue, ^{
        NSError *error = nil;
        NSString *deviceName = [[ECSClient shareInstance] getDeviceName:deviceID error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock != nil) {
                completionBlock(deviceName, error);
            }
        });
    });
}

- (void)setDeviceName:(Device *)device
              newName:(NSString *)newName
      completionBlock:(void (^)(NSError *error))completionBlock
{
    dispatch_async(managerDeviceQueue, ^{
        NSError *error = nil;
        BOOL result = [[ECSClient shareInstance] setDeviceName:device.deviceID name:newName error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result && error == nil) {
                [device performSelectorOnMainThread:@selector(setDeviceName:) withObject:newName waitUntilDone:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];
            }
            completionBlock(error);
        });
    });
}

- (void)pairWithDevice:(NSString *)deviceID
                  name:(NSString *)deviceName
              passWord:(NSString *)password
       completionBlock:(void (^)(NSError *error, BOOL alreadyPaired))completionBlock
{
    dispatch_async(managerDeviceQueue, ^{
        NSError *error = nil;
        BOOL paired = NO;
        BOOL result = [[ECSClient shareInstance] pair:deviceID service:@"" pairMode:ECSPairModeHost option:password alreadyPaired:&paired error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result && !paired) {
                Device *newDevice = [[Device alloc] initWithDeviceId:deviceID name:deviceName];
                newDevice.status = ECSDeviceEventOnline;
                [_devices addObject:newDevice];
                
                if (_currentDevice == nil) {
                    self.currentDevice = newDevice;
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];
            }
            completionBlock(error, paired);
        });
    });
}

- (void)unPairDevice:(Device *)device
     completionBlock:(void (^)(NSError *error))completionBlock
{
    dispatch_async(managerDeviceQueue, ^{
        NSError *error = nil;
        BOOL result = [[ECSClient shareInstance] unPair:device.deviceID service:@"" error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                [device disconnect];
                [_devices removeObject:device];
                
                if (device == _currentDevice) {
                    if (_devices.count == 0) {
                        self.currentDevice = nil;
                    }
                    else {
                        self.currentDevice = _devices[0];
                    }
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];
            }
            completionBlock(error);
        });
    });
}

#pragma mark - ECDeviceManagerDelegate

-(void)ECSClientSetPreference:(NSString *)key value:(NSString *)value {
    NSLog(@"ECSClientSetPreference key : %@, value : %@", key, value);
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:value forKey:key];
    [userDefault synchronize];
}

- (NSString *)ECSClientGetPreference:(NSString *)key {
    NSString *result = nil;
    if ([key isEqualToString:@"carrier.server.host"]) {
        result = ElastosCarrierService;
    } else if ([key isEqualToString:@"api.carrier.server.host"]) {
        result = ElastosCarrierAPIservice;
    } else if ([key isEqualToString:@"app.Id"]) {
        result = APPID;
    } else if ([key isEqualToString:@"app.key"]) {
        result = APPID;
    }
    else {
        result = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        NSLog(@"ECSClientGetPreference key : %@, value : %@", key, result);
    }
    return result;
}

-(void)ECSClientOnOnLine:(ECSContextInfo *)ECSServiceInfo {
    connectStatus = ServerConnectStatusConnected;
    [[ECSClient shareInstance] setClientName:[UIDevice currentDevice].name error:nil];
    if (needUpdateDeviceList) {
        needUpdateDeviceList = NO;
        [self updateDeviceList];
    }
}

-(void)ECSClientOnOffLine:(ECSOfflineReason)reason {
    DLog(@"ECSClientOnOffLine: %d", reason);
    
    connectStatus = ServerConnectStatusDisconnected;
    for (Device *device in self.devices) {
        [device disconnect];
    }
    
    if (needUpdateDeviceList) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdateFailed object:nil userInfo:nil];
    }
//    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
//        //[MBProgressHUD showToast:NSLocalizedString(@"连接服务器失败", nil) inView:[UIApplication sharedApplication].delegate.window duration:3 animated:YES];
//        [TSMessage showNotificationWithTitle:NSLocalizedString(@"连接服务器失败", nil)
//                                    subtitle:nil
//                                        type:TSMessageNotificationTypeError];
//    }
}

-(void)ECSClientOnDeviceEvent:(NSString *)deviceID event:(ECSDeviceEvent)event {
    for (Device *device in self.devices) {
        if ([device.deviceID isEqualToString:deviceID]) {
            switch (event) {
                case ECSDeviceEventOnline:
                    device.status = event;
                    [device connect];
                    break;
                    
                case ECSDeviceEventOffline:
                    device.status = event;
                    [device disconnect];
                    break;
                    
                default:
                    break;
            }
            
            break;
        }
    }
}

@end
