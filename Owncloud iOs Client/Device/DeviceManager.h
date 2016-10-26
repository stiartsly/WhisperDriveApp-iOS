//
//  CameraManager.h
//  Tapestry
//
//  Created by suleyu on 15/6/30.
//  Copyright (c) 2015年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Device.h"

#define kNotificationDeviceListUpdated      @"kNotificationDeviceListUpdated"
#define kNotificationDeviceListUpdateFailed @"kNotificationDeviceListUpdateFailed"

@interface DeviceManager : NSObject

@property (nonatomic, strong, readonly) NSArray *devices;
@property (nonatomic, strong) Device *currentDevice;

+ (DeviceManager *)sharedManager;

- (void)updateDeviceList;

- (void)getDeviceName:(NSString *)deviceID
      completionBlock:(void (^)(NSString *deviceName, NSError *error))completionBlock;

- (void)setDeviceName:(Device *)device
              newName:(NSString *)newName
      completionBlock:(void (^)(NSError *error))completionBlock;

- (void)pairWithDevice:(NSString *)deviceID
                  name:(NSString *)deviceName
              passWord:(NSString *)password
       completionBlock:(void (^)(NSError *error, BOOL alreadyPaired))completionBlock;

- (void)unPairDevice:(Device *)device
     completionBlock:(void (^)(NSError *error))completionBlock;

@end
