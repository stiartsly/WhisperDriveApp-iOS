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

#import <Foundation/Foundation.h>
#import "ECSClient.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ECSDeviceDelegate;
@interface ECSDevice : NSObject

/*!
 *  delegate
 */
@property (nonatomic, weak, nullable) id<ECSDeviceDelegate> delegate;

/*!
 *  device
 *
 *  @return device
 */
+ (ECSDevice *)shareInstance;

/*!
 *  call this function to start a device.
 *
 *  @param deviceID  设备的ID
 *  @param serviceID serviceID
 *  @param error     返回的错误信息
 *
 *  @return 设备是否开启成功
 */
- (BOOL)start:(NSString *)deviceID service:(nullable NSString *)serviceID error:(NSError **)error;

/*!
 *  stop device.
 */
- (void)stop;

@end


@protocol ECSDeviceDelegate <NSObject>

@optional

/*!
 *  device online callback
 *
 *  @param ContextInfo ContextInfo
 */
- (void)ECSDeviceOnOnline:(ECSContextInfo *)ContextInfo;

/*!
 *  device offline callback
 *
 *  @param reason offline reason
 */
- (void)ECSDeviceOnOffline:(ECSOfflineReason)reason;

/*!
 *  Used when client want to pair the device by password.
 *
 *  @param clientID   clientID
 *  @param Credential Credential
 *
 *  @return should be one of following values:
 *                      CREDENTIAL_OK,
 *                      CREDENTIAL_E_BAD,
 *                      CREDENTIAL_E_LIMIT.
 */
- (ECSDeviceCredential)ECSDeviceOnCredential:(NSString *)clientID credential:(NSString *)Credential;

/*!
 *  device receive data call back
 *
 *  @param serviceID service ID
 *  @param clientID  client ID
 *  @param message   message
 */
- (void)ECSDeviceOnMessage:(nullable NSString *)serviceID
                    client:(NSString *)clientID
                   message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END