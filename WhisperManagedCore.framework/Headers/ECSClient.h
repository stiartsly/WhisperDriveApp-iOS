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

/**
 * Context to be necessary for device/client to run.
 */
@interface ECSContextInfo : NSObject
@property (nonatomic, copy) NSString *turnServer;       // service IP address
@property (nonatomic, assign) int turnPort;             // service port
@end



/*!
 *  SubscriberInfo
 */
@interface ECSSubscriberInfo : NSObject
@property (nonatomic, copy, nullable) NSString *clientName; // client name
@property (nonatomic, copy) NSString *clientID;             // client ID
@property (nonatomic, assign) ECSPairMode mode;             // client pair mode
@property (nonatomic, assign, getter=isCurrentClient) BOOL currentClient;   // check is current client
@end



/*!
 *  设备信息类
 */
@interface ECSDeviceInfo : NSObject

@property (nonatomic, copy) NSString *deviceID;                 // device ID

@property (nonatomic, copy, nullable) NSString *displayName;    // device displayName

@property (nonatomic, copy, nullable) NSString *name;           // device name

@property (nonatomic, assign) int type;                         // device type

@property (nonatomic, assign) ECSDeviceEvent status;            // device status

@property (nonatomic, assign) ECSPairMode mode;                 // device pair mode
@end




@protocol ECSClientDelegate;

/*!
 *  ECSClient
 */
@interface ECSClient : NSObject

@property (nonatomic, weak, readonly, nullable) id<ECSClientDelegate> delegate;  // ECSClient delegate

/*!
 *  create a ECSClient object
 *
 *  @return ECSClient
 */
+(ECSClient *)shareInstance;

/*!
 *  start a client to connection with the device
 *
 *  @param error  return error message
 *
 *  @return success or fail
 */
- (BOOL)startClient:(id<ECSClientDelegate>)delegate error:(NSError **)error;

/*!
 *  stop client
*/
- (void)stopClient;

/*!
 * Get current client Id.
 *
 *  @param error return error message
 *
 *  @return the current client Id
 */
-(nullable NSString *)getClientId:(NSError **)error;

/*!
 *  set client name
 *
 *  @param name new name
 *
 *  @param error return error message
 *
 *  @return set sucess or fail
 */
- (BOOL)setClientName:(NSString *)name error:(NSError **)error;

/*!
 *  use this function to pair with the device
 *
 *  @param deviceID        device ID
 *  @param serviceID       service ID
 *  @param mode            pari mode
 *  @param option          pair option,when the pair mode is Host,the param is password, when pair mode is GUEST,the parm is pair message,can't be nil.
 *  @param error  return error message
 */
- (BOOL)pair:(NSString *)deviceID
     service:(nullable NSString *)serviceID
    pairMode:(ECSPairMode)mode
      option:(NSString *)option
alreadyPaired:(BOOL *)alreadyPaired
       error:(NSError **)error;

/*!
 *  unpair with the device
 *
 *  @param deviceID        device ID
 *  @param serviceID       service ID
 *  @param error           return error message
 */
- (BOOL)unPair:(NSString *)deviceID
       service:(nullable NSString *)serviceID
         error:(NSError **)error;

/*!
 *  confirm pair request form other client, the current client must pair the device used HOST mode.
 *
 *  @param deviceID        deive ID
 *  @param clientID        service ID
 *  @param mode            pir mode
 *  @param error           return error message
 */
- (BOOL)confirmPairRequest:(NSString *)deviceID
                 serviceID:(nullable NSString *)serviceID
                  clientID:(NSString *)clientID
                      mode:(ECSPairMode)mode
                     error:(NSError **)error;

/*!
 *  get the devices paird with current client
 *
 *  @param error return error message
 *
 *  @return      the device list.
 */
- (nullable NSArray<ECSDeviceInfo *> *)getDevices:(NSError **)error;

/*!
 *  get Subcribers pair with the device
 *
 *  @param deviceID device ID
 *  @param error    return error message
 *
 *  @return         Subcribers list ,ECSSubscriberInfo object.
 */
- (nullable NSArray<ECSSubscriberInfo *> *)getSubcribers:(NSString *)deviceID error:(NSError **)error;

/*!
 *  change the pair mode for speical client
 *
 *  @param deviceID        device ID
 *  @param clientID        client ID
 *  @param mode            new pair mode
 *  @param error           return error message
 */
- (BOOL)setSubscriberMode:(NSString *)deviceID
               Subscriber:(NSString *)clientID
                     mode:(ECSPairMode)mode
                    error:(NSError **)error;

/*!
 *  remove the Subscriber.
 *
 *  @param deviceID        device ID
 *  @param clientID        client ID
 *  @param error           return error message
 */
- (BOOL)removeSubscriber:(NSString *)deviceID
              Subscriber:(NSString *)clientID
                   error:(NSError **)error;

/*!
 *  set devie name
 *
 *  @param deviceID device ID
 *  @param name     new device Name
 *  @param error    return error message
 *
 *  @return         set result
 */
- (BOOL)setDeviceName:(NSString *)deviceID
                 name:(NSString *)name error:(NSError **)error;

/*!
 *  get device name
 *
 *  @param deviceID device ID
 *  @param error    return error message
 *
 *  @return         the devie name
 */
- (nullable NSString *)getDeviceName:(NSString *)deviceID error:(NSError **)error;

/*!
 *  set the device displayName
 *
 *  @param deviceID device ID
 *  @param name     device name
 *  @param error    return error message
 *
 *  @return         set result
 */
- (BOOL)setDeviceDisplayName:(NSString *)deviceID
                        name:(NSString *)name
                       error:(NSError **)error;

/*!
 *  get verify code
 *
 *  @param phoneNumber the phone number
 *  @param error       return error message
 *
 *  @return            result
 */
- (BOOL)getVerifyCode:(NSString *)phoneNumber error:(NSError **)error;

/*!
 *  sign current client
 *
 *  @param phoneNumber phone number
 *  @param code        verify code
 *  @param error       return error message
 *
 *  @return            result
 */
- (BOOL)signIn:(NSString *)phoneNumber
    verifyCode:(NSString *)code error:(NSError **)error;

/*!
 *  sign out current client
 *
 *  @param error return error message
 *
 *  @return      sign out result
 */
- (BOOL)signOut:(NSError **)error;

/*!
 *  send message the other client
 *
 *  @param peerId      other peer ID
 *  @param serviceID   serice ID
 *  @param data        send data
 *  @param deliverFlag deliverFlag description
 *  @param lifetime    lifetime
 *  @param error       retutn message
 *
 *  @return            send result.
 */
- (BOOL)sendMessage:(NSString *)peerId
            service:(nullable NSString *)serviceID
               data:(NSData *)data
        deliverFlag:(NSInteger)deliverFlag
           lifetime:(NSInteger)lifetime
              error:(NSError **)error;

@end

@protocol ECSClientDelegate <NSObject>

@required
- (nullable NSString *)ECSClientGetPreference:(NSString *)key;

- (void)ECSClientSetPreference:(NSString *)key value:(NSString *)value;

@optional

/*!
 *  called when client have register to service
 *
 *  @param ECSServiceInfo   the contex info published when becoming online
 */
- (void)ECSClientOnOnLine:(ECSContextInfo *)ECSServiceInfo;

/*!
 *  called when client disconnect form service
 *
 *  @param reason offline reason
 */
- (void)ECSClientOnOffLine:(ECSOfflineReason)reason;

/*!
 *  called when receive pair request from other client.
 *
 *  @param deviceID   device ID
 *  @param deviceName device name
 *  @param cleintID   other client ID
 *  @param clientName other client name
 *  @param message    other message
 */
- (void)ECSClientOnPairRequest:(NSString *)deviceID
                    deviceName:(nullable NSString *)deviceName
                       service:(nullable NSString *)serviceID
                      clientID:(NSString *)cleintID
                    clientName:(nullable NSString *)clientName
                       message:(nullable NSString *)message;


/*!
 *   called when receive pair confirm
 *
 *  @param deviceID device ID
 *  @param mode     pair mode
 *  @param error    error message
 */
- (void)ECSClientOnPairConfirm:(NSString *)deviceID
                       service:(nullable NSString *)serviceID
                          mode:(ECSPairMode)mode
                         error:(NSError *)error;

/*!
 *  called when device event changed
 *
 *  @param deviceID device ID
 *  @param event    event
 */
- (void)ECSClientOnDeviceEvent:(NSString *)deviceID
                         event:(ECSDeviceEvent)event;

/*!
 *  receive message form other client
 *
 *  @param serviceID serice DI
 *  @param deviceID  device ID
 *  @param message   message
 */
- (void)ECSClientOnMessage:(nullable NSString *)serviceID
                    device:(NSString *)deviceID
                   message:(NSString *)message;
@end

NS_ASSUME_NONNULL_END
