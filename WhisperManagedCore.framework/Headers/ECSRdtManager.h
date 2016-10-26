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

NS_ASSUME_NONNULL_BEGIN

@class ECSRdt;
@protocol ECSRdtManagerDelegate;

/*!
 *  RDT manager
 */
@interface ECSRdtManager : NSObject

/*!
 *  RDTmanager delegate
 */
@property (nonatomic, weak, nullable) id<ECSRdtManagerDelegate> delegate;

/*!
 *  create a singal tongle ECSRdtManager object
 *
 *  @return ECSRdtManager
 */
+(ECSRdtManager *)shareInstance;

/*!
 *  init RDT model
 *
 *  @param error error message
 *
 *  @return weather init successful
 */
- (BOOL)initialize:(NSError **)error;

/*!
 *  Destory model
 */
- (void)moduleDestroy;

/*!
 *  open a RDT channel
 *
 *  @param sessionID session ID
 *  @param channelID channel ID
 *  @param error     return error message
 *
 *  @return RDT
 */
- (nullable ECSRdt *)openRdt:(int)sessionID channel:(int)channelID error:(NSError **)error;

/*!
 *  close a RDT channel
 *
 *  @param rdt   RDT channel
 *  @param error return error message
 *
 *  @return close success or failed
 */
- (BOOL)closeRdt:(ECSRdt *)rdt error:(NSError **)error;

@end

@protocol ECSRdtManagerDelegate <NSObject>

@optional
- (void)ecsRdtDidOpen:(ECSRdt *)rdt;

@end

NS_ASSUME_NONNULL_END