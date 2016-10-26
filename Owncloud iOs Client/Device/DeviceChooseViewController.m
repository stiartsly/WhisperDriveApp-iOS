//
//  DeviceChooseViewController.m
//  ForwardingPort
//
//  Created by suleyu on 16/4/15.
//  Copyright © 2016年 kortide. All rights reserved.
//

#import "DeviceChooseViewController.h"
#import "DeviceSettingViewController.h"
#import "ScanViewController.h"
#import "InputDeviceIDViewController.h"
#import "MBProgressHUD.h"
#import "DeviceManager.h"

@interface DeviceChooseViewController ()

@end

@implementation DeviceChooseViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView name:kNotificationDeviceListUpdated object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"所有设备";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDevice)];
    
    self.tableView.rowHeight = 55.0f;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorInset = UIEdgeInsetsZero;
//    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
//        self.tableView.layoutMargins = UIEdgeInsetsZero;
//    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:kNotificationDeviceListUpdated object:nil];
    [[DeviceManager sharedManager] updateDeviceList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cancel
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)addDevice
{
    UIViewController *viewController = nil;
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusRestricted) {
        viewController = [[InputDeviceIDViewController alloc] init];
    } else {
        viewController = [[ScanViewController alloc] init];
    }
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [DeviceManager sharedManager].devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"reuseIdentifier"];
        cell.textLabel.textColor = UIColorFromRGB(0x666666);
        cell.textLabel.font = [UIFont systemFontOfSize:16.0f];
        cell.detailTextLabel.textColor = UIColorFromRGB(0xB3B3B3);
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    // Configure the cell...
    Device *device = [DeviceManager sharedManager].devices[indexPath.row];
    cell.textLabel.text = device.deviceName;
    cell.detailTextLabel.text = device.deviceID;
    if (device == [DeviceManager sharedManager].currentDevice) {
        cell.imageView.image = [UIImage imageNamed:@"select"];
    }
    else {
        cell.imageView.image = [UIImage imageNamed:@"unselect"];
    }
    
    return cell;
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    cell.separatorInset = UIEdgeInsetsZero;
//    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
//        cell.layoutMargins = UIEdgeInsetsZero;
//    }
//}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        Device *device = [DeviceManager sharedManager].devices[indexPath.row];
        [[DeviceManager sharedManager] unPairDevice:device completionBlock:^(NSError *error) {
            if (error) {
                hud.minSize = CGSizeZero;
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"删除失败";
                [hud hide:YES afterDelay:1];
            }
            else {
                [hud hide:YES];
                //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Device *device = [DeviceManager sharedManager].devices[indexPath.row];
    if (device != [DeviceManager sharedManager].currentDevice) {
        [[DeviceManager sharedManager].currentDevice disconnect];
        [DeviceManager sharedManager].currentDevice = device;
        [self.tableView reloadData];
        //[self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    DeviceSettingViewController *vc = [[DeviceSettingViewController alloc] init];
    vc.device = [DeviceManager sharedManager].devices[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
