//
//  Device.h
//
//  Created by suleyu on 15/6/23.
//  Copyright (c) 2015年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WhisperManagedCore/WhisperManagedCore.h>

#define kNotificationDeviceConnected        @"kNotificationDeviceConnected"
#define kNotificationDeviceConnectFailed    @"kNotificationDeviceConnectFailed"

@interface Device : NSObject

@property (nonatomic, strong, readonly) NSString *deviceID;
@property (nonatomic, strong, readonly) NSString *deviceName;
@property (nonatomic, assign) ECSDeviceEvent status;
@property (nonatomic, strong) NSString *remoteHost;
@property (nonatomic, assign) int remotePort;
@property (nonatomic, assign, readonly) int localPort;

- (instancetype)initWithDeviceId:(NSString *)deviceId name:(NSString *)deviceName;

- (BOOL)connect;
- (void)disconnect;

@end
