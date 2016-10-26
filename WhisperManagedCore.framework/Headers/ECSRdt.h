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

/*!
 *  RDT message info
 */
@interface ECSRdtInfo : NSObject
/*!
 *  session ID
 */
@property (nonatomic, assign) int sessionID;
/*!
 *  channel ID
 */
@property (nonatomic, assign) int channelID;
/*!
 *  the bytes of received
 */
@property (nonatomic, assign) UInt64     bytesOfReceived;
/*!
 *  bytes of sent
 */
@property (nonatomic, assign) UInt64     bytesOfSent;
@end

@protocol ECSRdtDelegate;

/*!
 *  ECSRdt object
 */
@interface ECSRdt : NSObject
/*!
 *  RDT delegate
 */
@property (nonatomic, weak, nullable) id<ECSRdtDelegate> delegate;

/*!
 *  RDT channel ID
 */
@property (nonatomic, assign, readonly) int rdtID;

/*!
 *  RDT message info
 */
@property (nonatomic, strong, readonly, nullable) ECSRdtInfo * rdtInfo;

/*!
 *  use RDT to wite data
 *
 *  @param data             the data you want write
 *  @param error            error value if failed to write
 */
- (BOOL)writeData:(NSData *)data error:(NSError **)error;

@end

/*!
 *  RDT delegate
 */
@protocol ECSRdtDelegate <NSObject>

@optional
/*!
 *  called when RDT get data
 *
 *  @param rdt  rdt
 *  @param data data
 */
- (void)ecsRdt:(ECSRdt *)rdt didReceiveData:(NSData *)data;

/*!
 *  called when RDT channel closed
 *
 *  @param rdt    RDT
 *  @param reason closed reason
 */
- (void)ecsRdt:(ECSRdt *)rdt didCloseWithReason:(int)reason;

@end

NS_ASSUME_NONNULL_END
