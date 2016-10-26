//
//  manualAddDeviceIDViewController.m
//  addDeviceByManual
//
//  Created by Kortide on 15/6/8.
//  Copyright (c) 2015年 Kortide. All rights reserved.
//

#import "AddDeviceViewController.h"
#import "InputDeviceIDViewController.h"
#import "ImageUtils.h"
#import "MBProgressHUD.h"
#import "DeviceManager.h"

@interface InputDeviceIDViewController()<UITextFieldDelegate>
@property (nonatomic, strong) UIButton *commitButton;
@property (nonatomic, strong) UITextField *inputTextFeild;
@end

@implementation InputDeviceIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self addIntroduceLabel];
    [self addInputTextFeild];
    [self addCommitButton];
    [self.view setBackgroundColor: UIColorFromRGB(0xF2F2F2)];
    self.navigationItem.title = NSLocalizedString(@"输入序列号", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)addIntroduceLabel
{
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, self.view.bounds.size.width-20, 30)];
    label.text = NSLocalizedString(@"请输入产品包装上的设备序列号。",nil);
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = UIColorFromRGB(0x9E9E9E);
    [self.view addSubview: label];
}

- (void)addInputTextFeild
{
    CGRect rect = CGRectMake(0, 44, self.view.bounds.size.width, 32);
    UIView *view = [[UIView alloc] initWithFrame:rect];
    view.layer.borderWidth = 0.5f;
    view.layer.borderColor = [UIColorFromRGB(0xD9D9D9) CGColor];
    view.backgroundColor = UIColorFromRGB(0xFFFFFF);
    rect.origin.x = rect.origin.x + 10;
    rect.size.width = rect.size.width - 20;
    UITextField *inputTextFeild = [[UITextField alloc]initWithFrame:rect];
    inputTextFeild.keyboardType = UIKeyboardTypeASCIICapable;
    inputTextFeild.delegate = self;
    [inputTextFeild addTarget:self action:@selector(textFieldEditObserver)forControlEvents:UIControlEventEditingChanged];
    _inputTextFeild = inputTextFeild;
    [self.view addSubview: view];
    [self.view addSubview: inputTextFeild];
}

-(void)addCommitButton
{
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(7, 94, self.view.bounds.size.width-14,32)];
    [button setTitle:NSLocalizedString(@"添加",nil) forState:UIControlStateNormal];
    [button setBackgroundColor:UIColorFromRGB(0x0077d9)];
    [button setBackgroundImage:[ImageUtils imageWithColor:[UIColor grayColor]] forState:UIControlStateDisabled];
    [button.layer setMasksToBounds:YES];
    [button.layer setCornerRadius:4.0];
    [button addTarget:self action:@selector(commitInputDeviceID) forControlEvents:UIControlEventTouchUpInside];
    [button setEnabled:NO];

    _commitButton = button;
    [self.view addSubview: button];
}

- (void)commitInputDeviceID
{
    [self.inputTextFeild resignFirstResponder];

    if (self.inputTextFeild.text.length > 0)
    {
        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
        if (hud) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            hud.mode = MBProgressHUDModeIndeterminate;
            hud.labelText = NSLocalizedString(@"正在处理",nil);
        }
        else {
            hud = [[MBProgressHUD alloc] initWithView:self.view];
            hud.removeFromSuperViewOnHide = YES;
            hud.labelText = NSLocalizedString(@"正在处理",nil);
            [self.view addSubview:hud];
            [hud show:YES];
        }
        
        __weak __typeof(self) weakSelf = self;
        [[DeviceManager sharedManager] getDeviceName:self.inputTextFeild.text completionBlock:^(NSString *deviceName, NSError *error) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                if (error == nil) {
                    [hud hide:YES];
                    
                    AddDeviceViewController* addDeviceViewController = [[AddDeviceViewController alloc]init];
                    addDeviceViewController.deviceID = strongSelf.inputTextFeild.text;
                    addDeviceViewController.deviceName = deviceName;
                    [strongSelf.navigationController pushViewController:addDeviceViewController animated:YES];
                }
                else
                {
                    NSString *errorText = NSLocalizedString(@"验证设备失败", nil);
                    if (error.code == ECSDevErrorCode_BadParam || error.code == ECSDevErrorCode_NoDevice) {
                        errorText = NSLocalizedString(@"设备不存在", nil);
                    }
                    
                    hud.mode = MBProgressHUDModeText;
                    hud.labelText = errorText;
                    [hud hide:YES afterDelay:1];
                }
            }
        }];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_inputTextFeild resignFirstResponder];
    [self commitInputDeviceID];
    return YES;
}

-(void)textFieldEditObserver
{
    if(_inputTextFeild.text.length > 0)
    {
        [_commitButton setEnabled:YES];
    }
    else
    {
        [_commitButton setEnabled:NO];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.inputTextFeild resignFirstResponder];
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
