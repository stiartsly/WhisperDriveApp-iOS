//
//  UtilsUrls.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 16/10/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UtilsUrls.h"
#import "constants.h"
#import "UserDto.h"
#import <UIKit/UIKit.h>
#import "ManageUsersDB.h"
#import "Customization.h"
#import "FileDto.h"
#import "ManageUploadsDB.h"


@implementation UtilsUrls

+ (NSString *) getOwnCloudFilePath {
    NSString *output = @"";
    
    //We get the current folder to create the local tree
    //TODO: uncomment this to use the shared folder
    
    NSString *bundleSecurityGroup = [self getBundleOfSecurityGroup];
    
    output = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:bundleSecurityGroup] path];
    
    if (!output) {
        NSLog(@"ERROR Getting the AppGroup: You will not be able to use neither the Document Provider or other extensions. This problem is related to the generation of certificates, provisioning profiles and the AppGroup. Please, read the Documentation of the project to fix it (https://github.com/owncloud/ios/blob/develop/SETUP.md)");
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        output = paths.firstObject;
    }
        
    output = [NSString stringWithFormat:@"%@/%@",output, k_owncloud_folder];
    
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:output isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
        [[NSFileManager defaultManager] createDirectoryAtPath:output
                                  withIntermediateDirectories:YES
                                                   attributes:attr
                                                        error:&error];
        if (error) {
            NSLog(@"Error creating directory path: %@", [error localizedDescription]);
        } else {
            [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:output]];
        }
    }
    
    output = [output stringByAppendingString:@"/"];
    
    return output;
}

+ (NSString *)getBundleOfSecurityGroup {
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource: @"Owncloud iOs Client" ofType: @"entitlements"];
    
    NSPropertyListFormat format;
    NSDictionary *entitlement = [NSPropertyListSerialization propertyListFromData:[[NSFileManager defaultManager] contentsAtPath:path] mutabilityOption:NSPropertyListImmutable format:&format errorDescription:nil];
    NSArray *securityGroups = [entitlement objectForKey:@"com.apple.security.application-groups"];
    
    return [securityGroups objectAtIndex:0];
}

+ (NSString *)bundleSeedID {
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)kSecClass,
                           @"bundleSeedID", kSecAttrAccount,
                           @"", kSecAttrService,
                           (id)kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecItemNotFound)
        status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status != errSecSuccess)
        return nil;
    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kSecAttrAccessGroup];
    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
    NSString *bundleSeedID = [[components objectEnumerator] nextObject];
    CFRelease(result);
    return bundleSeedID;
}

+ (NSString *) getFullBundleSecurityGroup {
    
    NSString *output;
    
    output = [NSString stringWithFormat:@"%@.%@", [self bundleSeedID], [self getBundleOfSecurityGroup]];
    
    return output;
    
}

+ (NSString *) getThumbnailFolderPath {
    return [NSString stringWithFormat:@"%@%@", [self getOwnCloudFilePath], k_thumbnails_cache_folder_name];
}

//Method to skip a file to a iCloud backup
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    
    BOOL success = NO;
    
    NSString *reqSysVer = @"5.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    
    if ([URL path]!=nil && ![currSysVer isEqualToString:reqSysVer]) {
        assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
        
        NSError *error = nil;
        
        success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                 forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
        
        return success;
        
    }else{
        return success;
    }
    
}

///-----------------------------------
/// @name getRemovedPartOfFilePathAnd
///-----------------------------------
/**
 * Return the part of the path to be removed
 *
 * @param mUserDto -> user dto
 *
 *  http://domain/sub1/sub2/remote.php/webdav/
 * @return  partToRemove -> /sub1/sub2/remote.php/webdav
 *                          /(subfolders)/k_url_wevdav_server/
 */
//We remove the part of the remote file path that is not necesary
+(NSString *) getRemovedPartOfFilePathAnd:(UserDto *)mUserDto {
    
    NSArray *userUrlSplited = [[self getFullRemoteServerPath:mUserDto] componentsSeparatedByString:@"/"];
    
    NSString *partToRemove = @"";
    
    for(int i = 3 ; i < [userUrlSplited count] ; i++) {
        partToRemove = [NSString stringWithFormat:@"%@/%@", partToRemove, [userUrlSplited objectAtIndex:i]];
        //NSLog(@"partRemoved: %@", partRemoved);
    }
    
    //We remove the first and the last "/"
    if ( [partToRemove length] > 0) {
        partToRemove = [partToRemove substringFromIndex:1];
    }
    if ( [partToRemove length] > 0) {
        partToRemove = [partToRemove substringToIndex:[partToRemove length] - 1];
    }
    
    
    if([partToRemove length] <= 0) {
        partToRemove = [NSString stringWithFormat:@"/%@", k_url_webdav_server];
    } else {
        partToRemove = [NSString stringWithFormat:@"/%@/%@", partToRemove, k_url_webdav_server];
    }
    
    return partToRemove;
}

///-----------------------------------
/// @name getLocalFolderByFilePath:andFileName:andUserDto
///-----------------------------------
/**
 * Return the file path without
 *
 * @param filePath -> /sub1/sub2/remote.php/webdav/
 *                    /(subfolders)/k_url_wevdav_server/
 * @param filename -> (subfolders_file)/
 * @param mUser -> user dto
 *
 * @return newLocalFolder -> full local path
 */
//We generate de local path of the files dinamically
+(NSString *)getLocalFolderByFilePath:(NSString*) filePath andFileName:(NSString*) fileName andUserDto:(UserDto *) mUser {
    
    //NSString *newLocalFolder= [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", mUser.idUser]];
    NSString *newLocalFolder= [[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", (int)mUser.idUser]];
    
    newLocalFolder = [NSString stringWithFormat:@"%@/%@%@", newLocalFolder,filePath,fileName];
    
    //We remove the http encoding
    newLocalFolder = [newLocalFolder stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    
    //NSLog(@"newLocalFolder: %@", newLocalFolder);
    return newLocalFolder;
}

//Get the relative path of the document provider using an absolute path
+ (NSString *)getRelativePathForDocumentProviderUsingAboslutePath:(NSString *) abosolutePath{
    
    __block NSString *relativePath;
    
    NSArray *listItems = [abosolutePath componentsSeparatedByString:@"/"];
    
    [listItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *part = (NSString*) obj;
        
        if (idx == listItems.count - 2) {
            relativePath = part;
            *stop = YES;
        }
        
    }];
    
    relativePath = [NSString stringWithFormat:@"/%@/%@",relativePath,abosolutePath.lastPathComponent];
    
    return relativePath;
}

+ (NSString *) getTempFolderForUploadFiles {
    NSString * output = [NSString stringWithFormat:@"%@temp/",[UtilsUrls getOwnCloudFilePath]];
    
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:output]) {
        NSError *error;
        
        if (![[NSFileManager defaultManager] createDirectoryAtPath:output
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error])
        {
            NSLog(@"Create directory error: %@", error);
        }
    }
    
    return  output;
}


//----------------------------------------------
/// @name getFilePathOnDBByFilePathOnFileDto
///---------------------------------------------
/**
 * Return the part of file path that is valid in the data base by filePath on FileDto
 *
 * @param filePathOnFileDto -> root folder -> /(subfoldersServer)/k_url_webdav_server/
 *                          -> subfolders  -> /(subfoldersServer)/k_url_webdav_server/(subfoldersDB)
 * @param user
 *
 * @return pathOnDB -> root folder -> @""
 *                  -> subfolders  -> @"(subfoldersDB)/"
 *
 */
+ (NSString *) getFilePathOnDBByFilePathOnFileDto:(NSString *) filePathOnFileDto andUser:(UserDto *) user {
    
    NSString *pathOnDB =@"";
    
    NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:user];
    if([filePathOnFileDto hasPrefix:partToRemove]){
        pathOnDB = [filePathOnFileDto substringFromIndex:[partToRemove length]];
    }
    
    return pathOnDB;
}


///-----------------------------------
/// @name getFullRemoteServerPath
///-----------------------------------
/**
 * Return the full server path
 *
 * @param mUserDto -> user dto
 *
 * @return  fullPath -> http://domain/sub1/sub2/...
 *                   -> http://domain/(subfoldersServer)
 */
+ (NSString *) getFullRemoteServerPath:(UserDto *)mUserDto {
    
    NSString *fullPath = nil;
    
    //If urlServerRedirected is nil the server is not redirected
    if (mUserDto.urlRedirected) {
        fullPath = mUserDto.urlRedirected;
    } else {
        fullPath = mUserDto.url;
    }

    return fullPath;
}

///-----------------------------------
/// @name getFullRemoteServerPathWithWebDav
///-----------------------------------
/**
 * Return the full server path with webdav components
 *
 * @param mUserDto -> user dto
 *
 * @return  fullPath -> http://domain/(subfolders)/k_url_webdav_server/
 *                      http://domain/sub1/sub2/remote.php/webdav/
 *
 */
+ (NSString *) getFullRemoteServerPathWithWebDav:(UserDto *)mUserDto {
    
    NSString *fullWevDavPath = nil;
    
    fullWevDavPath = [NSString stringWithFormat: @"%@%@", [self getFullRemoteServerPath:mUserDto],k_url_webdav_server];
    
    return fullWevDavPath;

}


///-----------------------------------
/// @name getPathWithAppName
///-----------------------------------
/**
 * Return the appName with the path file components whithout percent escape encoding
 *
 * @param destinyPath -> /Documents/...
 * @param user -> user dto
 *
 * @return  pathWithAppName -> appName/Documents/...
 *                          -> appName/
 */
+ (NSString *)getPathWithAppNameByDestinyPath:(NSString *)destinyPath andUser:(UserDto *)mUserDto {
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];

    NSString *pathWithAppName = [NSString stringWithFormat:@"%@/%@",appName,destinyPath];
    
    return  [pathWithAppName stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
    
}


+ (NSString *) getUrlServerWithoutHttpOrHttps:(NSString*) url {

    //    NSMutableString *url = [NSMutableString new];
    //
    //    NSArray *splitedUrl = [[UtilsUrls getFullRemoteServerPath:mUserDto] componentsSeparatedByString:@"/"];
    //
    //    NSString *sentence;
    //    for (int i=0; i<[splitedUrl count]; i++) {
    //
    //        if (i==0 || i==1) {
    //            //Nothing
    //        }else if (i==2){
    //            sentence = [NSString stringWithFormat:@"%@", [splitedUrl objectAtIndex:i]];
    //            [url appendString:sentence];
    //        }else{
    //            sentence = [NSString stringWithFormat:@"/%@", [splitedUrl objectAtIndex:i]];
    //            [url appendString:sentence];
    //        }
    //    }
    
    if ([[url lowercaseString] hasPrefix:@"http://"]) {
        url = [url substringFromIndex:7];
    } else if ([[url lowercaseString] hasPrefix:@"https://"]) {
        url = [url substringFromIndex:8];
    }

    return url;
}


//----------------------------------------------
/// @name getFullRemoteServerFilePathByFile
///---------------------------------------------
/**
 * Method to get full file path
 *
 * @param file -> fileDto
 * @param user -> userDto
 *
 * @return fullFilePath ->subfolders  -> http://domain/(subfoldersServer)/k_url_webdav_server/(subfoldersDB)/(filename)
 *
 */
+ (NSString *)getFullRemoteServerFilePathByFile:(FileDto *) file andUser:(UserDto *) user {
    
    NSString *fullFilePath = [NSString stringWithFormat:@"%@%@%@",[UtilsUrls getFullRemoteServerPathWithWebDav:user],file.filePath,file.fileName];
    
    DLog(@"fullFilePath: %@", fullFilePath);
    
    return fullFilePath;
}

//----------------------------------------------
/// @name getFullRemoteServerParentPathByFile
///---------------------------------------------
/**
 * Method to get full file path
 *
 * @param file -> fileDto
 * @param user -> userDto
 *
 * @return fullFilePath ->subfolders  -> http://domain/(subfoldersServer)/k_url_webdav_server/(subfoldersDB)
 *
 */
+ (NSString *)getFullRemoteServerParentPathByFile:(FileDto *) file andUser:(UserDto *) user {
    
    NSString *fullFilePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getFullRemoteServerPathWithWebDav:user],file.filePath];
    
    DLog(@"fullFilePath: %@", fullFilePath);
    
    return fullFilePath;
}




+ (NSString *) getUserAgent {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *userAgentWithAppVersion = [NSString stringWithFormat:@"%@%@",k_user_agent,appVersion];
    
    return userAgentWithAppVersion;
    
}

+ (BOOL) isFileUploadingWithPath:(NSString *)path andUser: (UserDto *) user {
    
    BOOL isFileUploading = NO;
    
    //Check remote path and user with current uploads
    NSMutableArray *uploads = [ManageUploadsDB getUploadsByStatus:generatedByDocumentProvider];
    
     NSString *checkPath = nil;
    
    for (UploadsOfflineDto *current in uploads) {
        
        checkPath = [NSString stringWithFormat:@"%@%@", current.destinyFolder, current.uploadFileName];
        
        if ([checkPath isEqualToString:path] && current.userId == user.idUser) {
            
            isFileUploading = YES;
            break;
        }

    }
    
    return isFileUploading;
}

///-----------------------------------
/// @name getKeyByLocalPath
///-----------------------------------
/**
 * Return the key that identify a file in the dictionary for download a full folder
 *
 * @param localPath -> /Users/Javi/Library/Developer/CoreSimulator/Devices/3A4FE170-2053-4D9E-9FF0-D2F5FC65C2D4/data/Containers/Shared/AppGroup/8F60BA9F-0A8B-472E-AC05-00A8A66F6CFC/cache_folder/3/Documents/
 *                    -> /Users/Javi/Library/Developer/CoreSimulator/Devices/3A4FE170-2053-4D9E-9FF0-D2F5FC65C2D4/data/Containers/Shared/AppGroup/8F60BA9F-0A8B-472E-AC05-00A8A66F6CFC/cache_folder/3/Documents/File.pdf
 *
 * @return  pathWithAppName -> Documents/
 *                          -> Documents/File.pdf
 */
+ (NSString *) getKeyByLocalFolder:(NSString *) localFolder {
    
    NSString *key = [localFolder substringFromIndex:[[self getOwnCloudFilePath] length]];
    NSArray *pathDivided = [key componentsSeparatedByString:@"/"];
    
    key = [key substringFromIndex:[[pathDivided objectAtIndex:0] length] + 1];
    
    return key;
}

//-----------------------------------
/// @name getFileLocalSystemPathByFileDto
///-----------------------------------

/**
 * Method used to get the system path of a file according to a fileDto and a user
 *
 * @param FileDto ->  fileDto
 * @param UserDto ->  user
 *
 * @return NSString fullLocalDestiny --> /fullLocalSystemPath/idUser/folderA/fileA.txt
 *
 */
+ (NSString *) getFileLocalSystemPathByFileDto:(FileDto *)fileDto andUser:(UserDto *)user{
    
    NSString *ocLocalFolder = [[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)user.idUser]];
    NSString *fullDBPath = [fileDto.filePath stringByAppendingPathComponent:fileDto.fileName];
    NSString *fullLocalDestiny = [NSString stringWithFormat:@"%@/%@",ocLocalFolder,[fullDBPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    return fullLocalDestiny;
}

//-----------------------------------
/// @name getLocalCertificatesPath
///-----------------------------------

/**
 * Method used to get the system path of the certificates
 *
 * @return NSString localCertificatesPath --> /fullLocalSystemPath/Certificates/
 *
 */
+ (NSString *) getLocalCertificatesPath{
    
    NSString *documentsDirectory = [UtilsUrls getOwnCloudFilePath];
    
    NSString *localCertificatesPath = [NSString stringWithFormat:@"%@Certificates/",documentsDirectory];
    
    return localCertificatesPath;
}

@end
