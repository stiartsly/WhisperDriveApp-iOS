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
#import "ECSDefine.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, ECSSessionMode) {
    ECSSessionModeLan               =   0,
    ECSSessionModePunch             =   1,
    ECSSessionModeRelay             =   2,
    ECSSessionModeDisconnected      =   3,
};

/*!
 *  ECSSession information
 */
@interface ECSSessionInfo : NSObject

/*!
 *  0: Ready, 1: Error
 */
@property (nonatomic, assign) int status;

/*!
 *  Channel number
 */
@property (nonatomic, assign) int channelNumber;

/*!
 * 0: Lan, 1: Punch, 2: Relay, 3: Disconnected
 */
@property (nonatomic, assign) ECSSessionMode mode;

/*!
 * 0: As a Client, 1: As a Device
 */
@property (nonatomic, assign) int role;

/*!
 * 设备的UID.
 */
@property (nonatomic, copy) NSString *remotePeerID;

/*!
 * session remote IP address
 */
@property (nonatomic, copy) NSString *remoteIP;

/*!
 * bytes of sent
 */
@property (nonatomic, assign) UInt64 bytesOfSent;

/*!
 * bytes of received
 */
@property (nonatomic, assign) UInt64 bytesofReceived;

@end


@protocol ECSSessionDelegate;

/*!
 *  ECSSession
 */
@interface ECSSession : NSObject

/*!
 *  session ID
 */
@property (nonatomic, assign, readonly) int sessionID;

/*!
 *  session delegate
 */
@property (nonatomic, weak, nullable) id<ECSSessionDelegate> delegate;

/*!
 *  session informaiton
 */
@property (nonatomic, strong, readonly, nullable) ECSSessionInfo *sessionInfo;

/*!
 *  use session write data
 *
 *  @param data            data
 *  @param error           error value if failed to write
 */
- (BOOL)writeData:(NSData *)data channel:(int)channelID error:(NSError **)error;

@end

/*!
 *  ECSSession Delegate
 */
@protocol ECSSessionDelegate <NSObject>

@optional
/*!
 *  called when session received data from channel
 *
 *  @param session   session
 *  @param channelID channel ID
 *  @param data      数据
 */
- (void)ecsSession:(ECSSession *)session channel:(int)channelID didReceiveData:(NSData *)data;

/*!
 *  called when session was closed
 *
 *  @param session session
 *  @param reason  clsoed reason
 */
- (void)ecsSession:(ECSSession *)session didCloseWithReason:(ECSSessionCloseReason)reason;
@end

NS_ASSUME_NONNULL_END
