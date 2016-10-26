//
//  DeviceSettingViewController.m
//  PortForward
//
//  Created by suleyu on 16/5/3.
//  Copyright © 2016年 kortide. All rights reserved.
//

#import "DeviceSettingViewController.h"
#import "MBProgressHUD.h"
#import "DeviceManager.h"

@interface DeviceSettingViewController () <UITextFieldDelegate>

@end

@implementation DeviceSettingViewController

- (instancetype)init
{
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView name:kNotificationDeviceListUpdated object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"设备设置";
    
    self.tableView.rowHeight = 55.0f;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:kNotificationDeviceListUpdated object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reload
{
    if (![[DeviceManager sharedManager].devices containsObject:self.device]) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 4 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reuseIdentifier"];
        cell.textLabel.font = [UIFont systemFontOfSize:16.0f];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // Configure the cell...
    if (indexPath.section == 0) {
        UITextField *textField = (UITextField*)cell.accessoryView;
        if (textField == nil) {
            textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width - 120, 50)];
            textField.font = [UIFont systemFontOfSize:14.0f];
            textField.textAlignment = NSTextAlignmentRight;
            textField.delegate = self;
            cell.accessoryView = textField;
        }
        
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"设备序列号";
                textField.text = self.device.deviceID;
                textField.textColor = UIColorFromRGB(0x666666);
                textField.enabled = NO;
                break;
                
            case 1:
                cell.textLabel.text = @"设备名称";
                textField.text = self.device.deviceName;
                textField.textColor = [UIColor blackColor];
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.enabled = YES;
                textField.tag = 1;
                break;
                
            case 2:
                cell.textLabel.text = @"服务器";
                textField.text = self.device.remoteHost;
                textField.textColor = [UIColor blackColor];
                textField.keyboardType = UIKeyboardTypeDecimalPad;
                textField.enabled = YES;
                textField.tag = 2;
                break;
                
            case 3:
                cell.textLabel.text = @"端口";
                textField.text = [NSString stringWithFormat:@"%d", self.device.remotePort];
                textField.textColor = [UIColor blackColor];
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.enabled = YES;
                textField.tag = 3;
                break;
        }
    }
    else {
        cell.textLabel.text = @"删除设备";
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.accessoryView = nil;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[DeviceManager sharedManager] unPairDevice:self.device completionBlock:^(NSError *error) {
            if (error) {
                hud.minSize = CGSizeZero;
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"删除失败";
                [hud hide:YES afterDelay:1];
            }
            else {
                [hud hide:YES];
                //[self.navigationController popViewControllerAnimated:YES];
            }
        }];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (![MBProgressHUD HUDForView:self.view]) {
        [textField resignFirstResponder];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == 1) {
        if (![textField.text isEqualToString:self.device.deviceName]) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [[DeviceManager sharedManager] setDeviceName:self.device newName:textField.text completionBlock:^(NSError *error) {
                if (error) {
                    hud.minSize = CGSizeZero;
                    hud.mode = MBProgressHUDModeText;
                    hud.labelText = @"设置设备名称失败";
                    [hud hide:YES afterDelay:1];
                    //textField.text = self.device.deviceName;
                }
                else {
                    [hud hide:YES];
                }
            }];
        }
    }
    else if (textField.tag == 2) {
        self.device.remoteHost = textField.text;
        if (self.device == [DeviceManager sharedManager].currentDevice) {
            [self.device connect];
        }
    }
    else if (textField.tag == 3) {
        self.device.remotePort = [textField.text intValue];
        if (self.device == [DeviceManager sharedManager].currentDevice) {
            [self.device connect];
        }
    }
}
@end
