//
//  UserDto.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/18/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UserDto.h"
#import "DeviceManager.h"

@implementation UserDto

- (NSString *)url {
    if (_deviceID) {
        for (Device *device in [DeviceManager sharedManager].devices) {
            if ([device.deviceID isEqualToString:_deviceID]) {
                if (device.localPort) {
                    if (_ssl) {
                        return [NSString stringWithFormat:@"https://localhost:%d/owncloud/", device.localPort];
                    }
                    else {
                        return [NSString stringWithFormat:@"http://localhost:%d/owncloud/", device.localPort];
                    }
                }
                else if (device.status == ECSDeviceEventOnline) {
                    [device connect];
                }
                break;
            }
        }
        
        return @"";
    }
    else {
        return _url;
    }
}

- (NSString *)deviceName {
    if (_deviceID) {
        for (Device *device in [DeviceManager sharedManager].devices) {
            if ([device.deviceID isEqualToString:_deviceID]) {
                return device.deviceName;
            }
        }
    }
    
    return nil;
}

@end
