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

@protocol ECSSessionManagerDelegate;
@class ECSSession;

/*!
 *  ECSSessionManager,管理session对象
 */
@interface ECSSessionManager : NSObject

/*!
 *  ECSSessionManager delegate
 */
@property (nonatomic, weak, nullable) id<ECSSessionManagerDelegate> delegate;

/*!
 *  ECSSessionManager
 *
 *  @return ECSSessionManager
 */
+(ECSSessionManager *)shareInstance;

/*!
 *  init session model
 *
 *  @param nMaxSessions the max session number you can want create
 *
 *  @return init success or fail
 */
-(BOOL)initialize:(int)nMaxSessions error:(NSError **)error;

/*!
 *  destory model
 *
 */
- (void)moduleDestroy;

/*!
 *  call this function to create ECSSession object
 *
 *  @param deviceID   device ID
 *  @param serviceID  serviceID
 *  @param channelNum channel num
 *  @param error      return error message
 *
 *  @return ECSSession
 */
-(nullable ECSSession *)openSession:(NSString *)deviceID service:(nullable NSString *)serviceID channels:(int)channelNum error:(NSError **)error;

/*!
 *  call this function to close a session
 *
 *  @param session   session
 *  @param error     return error message
 *
 *  @return session closed
 */
- (BOOL)closeSession:(ECSSession *)session error:(NSError **)error;
@end

/*!
 *  ECSSessionManagerDelegate
 */
@protocol ECSSessionManagerDelegate <NSObject>

@optional

/*!
 *  对端请求创建session的回调
 *
 *  @param serviceID service ID
 *  @param peerID    peer ID
 *
 *  @return YES表示同意建立，NO表示拒绝建立连接
 */
- (BOOL)ecsSessionShouldOpenForService:(nullable NSString *)serviceID peerID:(NSString *)peerID;

/*!
 *  和对端建立完session之后的回调
 */
- (void)ecsSessionDidOpen:(ECSSession *)session;

@end

NS_ASSUME_NONNULL_END