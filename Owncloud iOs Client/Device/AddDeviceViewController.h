//
//  deviceIDinputCompletedViewController.h
//  Tapestry
//
//  Created by Kortide on 15/6/10.
//  Copyright (c) 2015年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddDeviceViewController : UIViewController<UITextFieldDelegate>
@property (nonatomic, strong) NSString* deviceID;
@property (nonatomic, strong) NSString* deviceName;
@end
