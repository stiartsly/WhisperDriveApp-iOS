//
//  Camera.m
//  Tapestry
//
//  Created by suleyu on 15/6/23.
//  Copyright (c) 2015年 Kortide. All rights reserved.
//

#import "Device.h"
#import "GCDAsyncSocket.h"

static NSString * const KEY_RemoteHost = @"portForwardingRemoteHost";
static NSString * const KEY_RemotePort = @"portForwardingRemotePort";

static const int g_channelID = 3;

@interface Device () <ECSSessionDelegate>
{
    int _localPort;
    dispatch_queue_t dispatchQueue;
}

@property (nonatomic, strong) NSString *deviceName;
@property (nonatomic, strong) ECSSession *session;
@property (nonatomic, assign) int portForwardingID;
@property (nonatomic, strong) NSString *forwardingRemoteHost;
@property (nonatomic, assign) int forwardingRemotePort;

@property (atomic, assign) BOOL connecting;
@end

@implementation Device

- (instancetype)initWithDeviceId:(NSString *)deviceId name:(NSString *)deviceName
{
    if (self = [super init]) {
        _deviceID = deviceId;
        _deviceName = deviceName;
        
        NSDictionary *deviceConfig = [[NSUserDefaults standardUserDefaults] objectForKey:_deviceID];
        if (deviceConfig) {
            _remoteHost = deviceConfig[KEY_RemoteHost];
            if (_remoteHost == nil) {
                _remoteHost = @"127.0.0.1";
            }
            
            NSNumber *port = deviceConfig[KEY_RemotePort];
            if (port) {
                _remotePort = [port intValue];
            }
            else {
                _remotePort = 80;
            }
        }
        else {
            _remoteHost = @"127.0.0.1";
            _remotePort = 80;
        }
    }
    return self;
}

- (void)dealloc
{
    //[self disconnect];
    if (self.session) {
        ECSSession * session = self.session;
        int portForwardingID = self.portForwardingID;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            if (portForwardingID > 0) {
                NSLog(@"Try to close port forwarding: %d", portForwardingID);
                [[ECSTunnel shareInstance] deletePortForwarding:portForwardingID session:session.sessionID channel:g_channelID error:&error];
                if (error) {
                    NSLog(@"Failed to close port forwarding: %d", (int)error.code);
                    error = nil;
                }
                else {
                    NSLog(@"Success to close port forwarding: %d", portForwardingID);
                }
            }
            
            NSLog(@"Try to close session: %d", session.sessionID);
            [[ECSSessionManager shareInstance] closeSession:session error:&error];
            if (error) {
                NSLog(@"Failed to close session: 0x%X", (int)error.code);
                error = nil;
            }
            else {
                NSLog(@"Success to close session: %d", session.sessionID);
            }
        });
    }
    dispatchQueue = NULL;
}

- (BOOL)connect
{
    if (_localPort > 0) {
        return YES;
    }
    
    if (_status != ECSDeviceEventOnline) {
        DLog(@"Server device is offline");
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:nil];
    }
    
    if (self.connecting) {
        return NO;
    }
    
    self.connecting = YES;
    
    if (dispatchQueue == NULL) {
        dispatchQueue = dispatch_queue_create("dispatchQueue", NULL);
    }
    
    dispatch_async(dispatchQueue, ^{
        @autoreleasepool {
            if (!self.connecting) {
                return;
            }
            
            NSError *error = nil;
            
            if (self.session == nil) {
                NSLog(@"Connecting to device : %@", self.deviceID);
                self.session = [[ECSSessionManager shareInstance] openSession:self.deviceID service:@"" channels:g_channelID error:&error];
                if (error) {
                    NSLog(@"Failed to connect device, error: 0x%X", (int)error.code);
                    self.connecting = NO;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:@{@"error": error}];
                    return;
                }
                
                self.session.delegate = self;
                NSLog(@"Success to connect device, session mode: %d", self.session.sessionInfo.mode);
                
                if (!self.connecting) {
                    return;
                }
            }
            
            uint16_t localPort = 0;
            while (self.portForwardingID <= 0 || ![self.forwardingRemoteHost isEqualToString:self.remoteHost] || self.forwardingRemotePort != self.remotePort) {
                if (self.portForwardingID > 0) {
                    NSLog(@"Try to close port forwarding: %d", self.portForwardingID);
                    [[ECSTunnel shareInstance] deletePortForwarding:self.portForwardingID session:self.session.sessionID channel:g_channelID error:&error];
                    if (error) {
                        NSLog(@"Failed to close port forwarding: %d", (int)error.code);
                        error = nil;
                    }
                    else {
                        NSLog(@"Success to close port forwarding: %d", self.portForwardingID);
                    }
                    self.portForwardingID = 0;
                }
                
                if (!self.connecting) {
                    return;
                }
                
                localPort = [self getAvailableLocalPort:&error];
                if (localPort == 0) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:@{@"error": error}];
                    return;
                }
                
                NSLog(@"Try to open port forwarding");
                self.forwardingRemoteHost = self.remoteHost;
                self.forwardingRemotePort = self.remotePort;
                self.portForwardingID = [[ECSTunnel shareInstance] addPortForwarding:self.session.sessionID
                                                                                 channel:g_channelID
                                                                                    host:nil
                                                                                    port:localPort
                                                                              remoteHost:self.forwardingRemoteHost
                                                                              remotePort:self.forwardingRemotePort
                                                                                    mode:ECSPortForwardingModeTCP
                                                                                   error:&error];
                if ([self.forwardingRemoteHost isEqualToString:self.remoteHost] && self.forwardingRemotePort == self.remotePort) {
                    if (error) {
                        NSLog(@"Failed to open port forwarding : %d", (int)error.code);
                        self.connecting = NO;
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:@{@"error": error}];
                        return;
                    }
                    
                    NSLog(@"Success to open port forwarding : %d, loacl port : %d", self.portForwardingID, localPort);
                }
                
                if (!self.connecting) {
                    return;
                }
            }
            
            _localPort = localPort;
            self.connecting = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnected object:self userInfo:nil];
        }
    });
    return NO;
}

- (void)disconnect
{
    self.connecting = NO;
    _localPort = 0;
    
    if (dispatchQueue) {
        dispatch_async(dispatchQueue, ^{
            @autoreleasepool {
                _localPort = 0;
                
                NSError *error = nil;
                if (self.portForwardingID > 0) {
                    NSLog(@"Try to close port forwarding: %d", self.portForwardingID);
                    [[ECSTunnel shareInstance] deletePortForwarding:self.portForwardingID session:self.session.sessionID channel:g_channelID error:&error];
                    if (error) {
                        NSLog(@"Failed to close port forwarding: %d", (int)error.code);
                        error = nil;
                    }
                    else {
                        NSLog(@"Success to close port forwarding: %d", self.portForwardingID);
                    }
                    self.portForwardingID = 0;
                }
                
                if (self.session) {
                    NSLog(@"Disconnecting from device %@, close session: %d", self.deviceID, self.session.sessionID);
                    self.session.delegate = nil;
                    [[ECSSessionManager shareInstance] closeSession:self.session error:&error];
                    if (error) {
                        NSLog(@"Failed to close session: 0x%X", (int)error.code);
                        error = nil;
                    }
                    else {
                        NSLog(@"Success to close session: %d", self.session.sessionID);
                    }
                    self.session = nil;
                }
            }
        });
    }
}

- (void)setRemoteHost:(NSString *)remoteHost
{
    if (remoteHost.length == 0) {
        return;
    }
    
    NSString *expression = @"^((25[0-5]|2[0-4]\\d|((1\\d{2})|([1-9]?\\d)))\\.){3}(25[0-5]|2[0-4]\\d|((1\\d{2})|([1-9]?\\d)))$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression options:0 error:nil];
    if ([regex firstMatchInString:remoteHost options:0 range:NSMakeRange(0, remoteHost.length)] == nil) {
        return;
    }
    
    if (![_remoteHost isEqualToString:remoteHost]) {
        _remoteHost = remoteHost;
        
        if (_localPort > 0) {
            _localPort = 0;
        }
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *deviceConfig = [[userDefaults objectForKey:_deviceID] mutableCopy];
        if (deviceConfig == nil) {
            deviceConfig = [NSMutableDictionary dictionaryWithCapacity:1];
        }
        deviceConfig[KEY_RemoteHost] = remoteHost;
        [userDefaults setObject:deviceConfig forKey:_deviceID];
        [userDefaults synchronize];
    }
}

- (void)setRemotePort:(int)remotePort
{
    if (_remotePort != remotePort) {
        _remotePort = remotePort;
        
        if (_localPort > 0) {
            _localPort = 0;
        }
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *deviceConfig = [[userDefaults objectForKey:_deviceID] mutableCopy];
        if (deviceConfig == nil) {
            deviceConfig = [NSMutableDictionary dictionaryWithCapacity:1];
        }
        deviceConfig[KEY_RemotePort] = @(remotePort);
        [userDefaults setObject:deviceConfig forKey:_deviceID];
        [userDefaults synchronize];
    }
}

- (uint16_t)getAvailableLocalPort:(NSError * __autoreleasing *)error
{
    static dispatch_queue_t serverQueue;
    static GCDAsyncSocket *asyncSocket;
    static dispatch_once_t onceTag;
    dispatch_once(&onceTag, ^{
        serverQueue = dispatch_queue_create("HTTPServer", NULL);
        asyncSocket = [[GCDAsyncSocket alloc] init];
        asyncSocket.delegateQueue = serverQueue;
    });
    
    uint16_t localPort = 0;
    asyncSocket.delegate = self;
    if ([asyncSocket acceptOnInterface:@"127.0.0.1" port:0 error:error]) {
        localPort = [asyncSocket localPort];
        NSLog(@"localPort: %d", localPort);
        [asyncSocket disconnect];
    } else {
        NSLog(@"get free localPort failed: %@", *error);
    }
    return localPort;
}

#pragma mark - ECSSessionDelegate
- (void)ecsSession:(ECSSession *)session didCloseWithReason:(ECSSessionCloseReason)reason
{
    if (session == self.session) {
        NSLog(@"Session closed: %lu", (unsigned long)reason);
        self.session = nil;
        _localPort = 0;
        
        if (self.portForwardingID > 0) {
            [[ECSTunnel shareInstance] deletePortForwarding:self.portForwardingID session:self.session.sessionID channel:g_channelID error:nil];
            self.portForwardingID = 0;
        }
    }
}

@end
