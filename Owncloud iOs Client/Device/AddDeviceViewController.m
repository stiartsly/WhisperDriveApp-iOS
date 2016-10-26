//
//  deviceIDinputCompletedViewController.m
//  Tapestry
//
//  Created by Kortide on 15/6/10.
//  Copyright (c) 2015年 Kortide. All rights reserved.
//

#import "AddDeviceViewController.h"
#import "MBProgressHUD.h"
#import "DeviceManager.h"

@interface AddDeviceViewController()
@property (nonatomic, strong) UITextField *inputTextFeild;
@end

@implementation AddDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self setupDeviceImage];
    [self setupDeviceIDLabel];
    [self setupDevicePasswordTextField];
    [self setupCommitButton];
    [self.view setBackgroundColor: UIColorFromRGB(0xF2F2F2)];
    self.navigationItem.title = NSLocalizedString(@"结果", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setupDeviceImage
{
    UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"device_pre"]];
    imageView.center = CGPointMake(self.view.bounds.size.width/2, imageView.image.size.height/2+50);
    [self.view addSubview:imageView];
}

- (void)setupDeviceIDLabel
{
    UILabel * deviceIDLabel= [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 32)];
    deviceIDLabel.backgroundColor = [UIColor clearColor];
    deviceIDLabel.textColor = UIColorFromRGB(0xABABAB);
    deviceIDLabel.textAlignment = NSTextAlignmentCenter;
    deviceIDLabel.text = self.deviceName.length > 0 ? self.deviceName : self.deviceID;
    deviceIDLabel.center = CGPointMake(self.view.bounds.size.width/2, 212);
    [self.view addSubview:deviceIDLabel];
}

- (void)setupDevicePasswordTextField
{
    CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width-10, 32);
    UITextField *inputTextFeild = [[UITextField alloc]initWithFrame:rect];
    inputTextFeild.delegate = self;
    inputTextFeild.backgroundColor = UIColorFromRGB(0xFFFFFF);
    inputTextFeild.placeholder = NSLocalizedString(@"请输入密码",nil);
    inputTextFeild.attributedPlaceholder =
       [[NSAttributedString alloc] initWithString:NSLocalizedString(@"请输入密码",nil)
                                       attributes:@{NSForegroundColorAttributeName:UIColorFromRGB(0xCCCCCC)}];
    inputTextFeild.center = CGPointMake(self.view.bounds.size.width/2, 260);
    inputTextFeild.borderStyle = UITextBorderStyleRoundedRect;
    inputTextFeild.keyboardType = UIKeyboardTypeASCIICapable;
    inputTextFeild.secureTextEntry = YES;
    [self.view addSubview: inputTextFeild];
    self.inputTextFeild = inputTextFeild;
}

-(void)setupCommitButton
{
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width-10,30)];
    button.center = CGPointMake(self.view.bounds.size.width/2, 312);
    [button.layer setMasksToBounds:YES];
    [button.layer setCornerRadius:4.0];
    [button setTitle:NSLocalizedString(@"确定",nil) forState:UIControlStateNormal];
    [button setBackgroundColor :UIColorFromRGB(0x0077D9)];
    [button addTarget:self action:@selector(commitDeviceID) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview: button];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.inputTextFeild resignFirstResponder];
    [self commitDeviceID];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.inputTextFeild resignFirstResponder];
}

-(void)commitDeviceID
{
    MBProgressHUD *hubAlertView = [[MBProgressHUD alloc] initWithView:self.view];
    hubAlertView.removeFromSuperViewOnHide = YES;
    hubAlertView.minSize = CGSizeMake(135.f, 135.f);
    [self.view addSubview:hubAlertView];
    
    hubAlertView.labelText = NSLocalizedString(@"正在添加",nil);
    [hubAlertView show:YES];
    [self addDeviceByID];
}

-(void)addDeviceByID
{
    __weak __typeof(self) weakSelf = self;
    [[DeviceManager sharedManager] pairWithDevice:self.deviceID
                                             name:self.deviceName
                                         passWord:self.inputTextFeild.text
                                  completionBlock:^(NSError *error, BOOL alreadyPaired)
     {
         __strong __typeof(weakSelf) strongSelf = weakSelf;
         if (strongSelf == nil) {
             return;
         }
         
         MBProgressHUD *hud = [MBProgressHUD HUDForView:strongSelf.view];
         
         if (error == nil)
         {
             if (alreadyPaired) {
                 hud.minSize = CGSizeZero;
                 hud.mode = MBProgressHUDModeText;
                 hud.labelText = NSLocalizedString(@"已添加过该设备", nil);
                 [strongSelf performSelector:@selector(popToRootView) withObject:strongSelf afterDelay:1];
             }
             else if (strongSelf.inputTextFeild.text.length > 0) {
                 UIImage *image = [UIImage imageNamed:@"check_ok"];
                 hud.customView = [[UIImageView alloc] initWithImage:image];
                 hud.mode = MBProgressHUDModeCustomView;
                 hud.labelText = NSLocalizedString(@"添加成功", nil);
                 
                 [strongSelf performSelector:@selector(popToRootView) withObject:strongSelf afterDelay:1];
             }
             else {
                 hud.minSize = CGSizeZero;
                 hud.mode = MBProgressHUDModeText;
                 hud.labelText = NSLocalizedString(@"授权申请已发送至主人", nil);
                 //[hud hide:YES afterDelay:1];
                 [strongSelf performSelector:@selector(popToRootView) withObject:strongSelf afterDelay:1];
             }
         }
         else
         {
             NSString *errorText = NSLocalizedString(@"添加失败", nil);
             if (error.code == ECSDevErrorCode_NoDevice) {
                 errorText = NSLocalizedString(@"设备不存在", nil);
             }
             else if (error.code == ECSDevErrorCode_DeviceOffLine) {
                 errorText = NSLocalizedString(@"设备不在线", nil);
             }
             else if (error.code == ECSDevErrorCode_BadCredential) {
                 errorText = NSLocalizedString(@"密码错误", nil);
             }
             
             NSLog(@"pairWithDevice failed : 0x%X", (int)error.code);
             hud.minSize = CGSizeZero;
             hud.mode = MBProgressHUDModeText;
             hud.labelText = errorText;
             [hud hide:YES afterDelay:1];
         }
     }];
}

-(void)popToRootView
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
