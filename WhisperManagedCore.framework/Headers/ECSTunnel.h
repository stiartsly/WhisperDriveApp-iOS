/*
 * Copyright (C) 2016 Elastos.org
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
 *  ECSTunnel class
 */
@interface ECSTunnel : NSObject

/*!
 *  There can only be only one SessTunnel
 *
 *  @return ECSTunnel objcet;
 */
+ (ECSTunnel *)shareInstance;


FOUNDATION_EXTERN NSString *const ECSTunnelErrorDomain;

typedef NS_ENUM(NSUInteger, ECSTunnelError) {
    ECSTunnelError_OK,
    ECSTunnelError_InvalidArgument,
    ECSTunnelError_LowMemory,
    ECSTunnelError_Multiple,
};

/*!
 *  Initialize the SessTunnel
 *
 *  @param error            return error message
 *
 *  @return initialize success or fail
 */
- (BOOL)initialize:(NSError **)error;

/*!
 *  Releases all resources associated with the tunnel.
 *
 *  If any calls were ongoing, these will be forcibly terminated without
 *  notifying peers. After calling this function, no other functions may be
 *  called and the SessTunnel pointer becomes invalid.
 */
- (void)moduleDestroy;

/*!
 *  Start SessTunnel, begin process data packets.
 */
- (void)start;


FOUNDATION_EXTERN NSString *const ECSPortForwardingErrorDomain;

typedef NS_ENUM(NSUInteger, ECSPortForwardingError) {
    ECSPortForwardingError_OK,
    ECSPortForwardingError_InvalidArgument,
    ECSPortForwardingError_LowMemory,
    ECSPortForwardingError_NetworkError,
};

typedef NS_ENUM(NSInteger, ECSPortForwardingMode) {
    ECSPortForwardingModeTCP                =   0,
    ECSPortForwardingModeUDP                =   1,
};

/*!
 *  open port forwarding
 *
 *  @param sessionID        session ID
 *  @param channelID        channel ID
 *  @param host             bind local host
 *  @param port             bind local port
 *  @param remoteHost       bind remote host
 *  @param remotePort       bind remote port
 *  @param mode             port forwarding mode
 *  @param error            return error message
 *
 *  @return port forwarding id. return value >= 0 on success, < 0 on error
 */
- (int)addPortForwarding:(int)sessionID
                 channel:(int)channelID
                    host:(nullable NSString *)host
                    port:(UInt16)port
              remoteHost:(nullable NSString *)remoteHost
              remotePort:(UInt16)remotePort
                    mode:(ECSPortForwardingMode)mode
                   error:(NSError **)error __attribute__((swift_error(nonnull_error)));

/*!
 *  close the special port forwarding
 *
 *  @param portForwardingID port forwarding ID
 *  @param sessionID        session ID
 *  @param channelID        channel ID
 *  @param error            return error message
 *
 *  @return close success or failed
 */
- (BOOL)deletePortForwarding:(int)portForwardingID
                     session:(int)sessionID
                     channel:(int)channelID
                       error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
