//
//  ManageUsersDB.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 21/06/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageUsersDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "UserDto.h"
#import "UtilsUrls.h"
#import "OCKeychain.h"
#import "CredentialsDto.h"
#import "UtilsCookies.h"
#import "constants.h"
#import "ManageCapabilitiesDB.h"

#ifdef CONTAINER_APP
#import "AppDelegate.h"
#import "Owncloud_iOs_Client-Swift.h"
#elif FILE_PICKER
#import "ownCloudExtApp-Swift.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "ownCloudExtAppFileProvider-Swift.h"
#endif

@implementation ManageUsersDB


/*
 * Method that add user into database
 * @userDto -> userDto (Object of a user info)
 */
+(void) insertUser:(UserDto *)userDto {
    
    DLog(@"Insert user: url:%@ / username:%@ / password:%@ / ssl:%d / activeaccount:%d / urlRedirected:%@ ", userDto.url, userDto.username, userDto.password, userDto.ssl, userDto.activeaccount, userDto.urlRedirected);
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO users(device_id, url, ssl, activeaccount, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, has_capabilities_support, url_redirected) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", userDto.deviceID, userDto.deviceID ? nil : userDto.url, [NSNumber numberWithBool:userDto.ssl],  [NSNumber numberWithBool:userDto.activeaccount] , [NSNumber numberWithInteger:userDto.hasShareApiSupport], [NSNumber numberWithInteger:userDto.hasShareeApiSupport], [NSNumber numberWithBool:userDto.hasCookiesSupport], [NSNumber numberWithInteger:userDto.hasForbiddenCharactersSupport], [NSNumber numberWithInteger:userDto.hasCapabilitiesSupport], userDto.urlRedirected];
        
        if (!correctQuery) {
            DLog(@"Error in insertUser");
        }
        
    }];
    
    //Insert last user inserted in the keychain
    UserDto *lastUser = [self getLastUserInserted];
    NSString *idString = [NSString stringWithFormat:@"%ld", (long)lastUser.idUser];
    
    if (![OCKeychain setCredentialsById:idString withUsername:userDto.username andPassword:userDto.password]) {
        DLog(@"Failed setting credentials");
    }
    
}

/*
 * This method return the active user of the app
 */
+ (UserDto *) getActiveUser {
    
    DLog(@"getActiveUser");
    
    __block UserDto *output = nil;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, device_id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_sharee_api_support, has_cookies_support, has_capabilities_support, has_forbidden_characters_support, instant_upload, background_instant_upload, path_instant_upload, only_wifi_instant_upload, timestamp_last_instant_upload, url_redirected, sorting_type FROM users WHERE activeaccount = 1  ORDER BY id ASC LIMIT 1"];
        
        DLog(@"RSColumnt count: %d", rs.columnCount);
        
        
        while ([rs next]) {
            
            output=[UserDto new];
            
            output.idUser = [rs intForColumn:@"id"];
            output.deviceID = [rs stringForColumn:@"device_id"];
            if (output.deviceID.length == 0) {
                output.url = [rs stringForColumn:@"url"];
            }
            output.ssl = [rs intForColumn:@"ssl"];
            output.activeaccount = [rs intForColumn:@"activeaccount"];
            output.storageOccupied = [rs longForColumn:@"storage_occupied"];
            output.storage = [rs longForColumn:@"storage"];
            output.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            output.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            output.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            output.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            output.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            output.instantUpload = [rs intForColumn:@"instant_upload"];
            output.backgroundInstantUpload  = [rs intForColumn:@"background_instant_upload"];
            output.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            output.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            output.timestampInstantUpload = [rs doubleForColumn:@"timestamp_last_instant_upload"];
            
            output.urlRedirected = [rs stringForColumn:@"url_redirected"];
            
            NSString *idString = [NSString stringWithFormat:@"%ld", (long)output.idUser];
            
            CredentialsDto *credDto = [OCKeychain getCredentialsById:idString];
            output.username = credDto.userName;
            output.password = credDto.password;
            
            output.sortingType = [rs intForColumn:@"sorting_type"];
        }
        
        [rs close];
        
    }];
    
    if (output) {
        output.capabilitiesDto = [ManageCapabilitiesDB getCapabilitiesOfUserId: output.idUser];
    }
    
    return output;
}

/*
 * This method return the active user of the app without user name and password
 */
+ (UserDto *) getActiveUserWithoutUserNameAndPassword {
    
    DLog(@"getActiveUser");
    
    __block UserDto *output = nil;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, device_id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, instant_upload, background_instant_upload, path_instant_upload, only_wifi_instant_upload, timestamp_last_instant_upload, url_redirected, sorting_type FROM users WHERE activeaccount = 1  ORDER BY id ASC LIMIT 1"];
        
        DLog(@"RSColumnt count: %d", rs.columnCount);
        
        
        while ([rs next]) {
            
            output=[UserDto new];
            
            output.idUser = [rs intForColumn:@"id"];
            output.deviceID = [rs stringForColumn:@"device_id"];
            if (output.deviceID.length == 0) {
                output.url = [rs stringForColumn:@"url"];
            }
            output.ssl = [rs intForColumn:@"ssl"];
            output.activeaccount = [rs intForColumn:@"activeaccount"];
            output.storageOccupied = [rs longForColumn:@"storage_occupied"];
            output.storage = [rs longForColumn:@"storage"];
            output.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            output.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            output.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            output.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            
            output.instantUpload = [rs intForColumn:@"instant_upload"];
            output.backgroundInstantUpload = [rs intForColumn:@"background_instant_upload"];
            output.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            output.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            output.timestampInstantUpload = [rs doubleForColumn:@"timestamp_last_instant_upload"];
            
            output.urlRedirected = [rs stringForColumn:@"url_redirected"];
            
            output.username = nil;
            output.password = nil;
            
            output.sortingType = [rs intForColumn:@"sorting_type"];
        }
        
        [rs close];
        
    }];
    
    
    return output;
}


/*
 * This method change the password of the an user
 * @user -> user object
 */
+(void) updatePassword: (UserDto *) user {
    
    
    if(user.password != nil) {
        
        NSString *idString = [NSString stringWithFormat:@"%ld", (long)user.idUser];
        
        if (![OCKeychain updatePasswordById:idString withNewPassword:user.password]) {
            DLog(@"Error update the password keychain");
        }
        
#ifdef CONTAINER_APP
        //Set the user password
        if (user.activeaccount) {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            app.activeUser = user;
            
            NSString *connectURL =[NSString stringWithFormat:@"%@%@",app.activeUser.url,k_url_webdav_server];
            
            [UtilsCookies eraseCredentialsWithURL:connectURL];
            [UtilsCookies eraseURLCache];
        }
#endif
        
    }
}


/*
 * Method that return the user object of the idUser
 * @idUser -> id User.
 */
+ (UserDto *) getUserByIdUser:(NSInteger) idUser {
    
    DLog(@"getUserByIdUser:(int) idUser");
    
    __block UserDto *output = nil;
    
    output=[UserDto new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, device_id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, has_capabilities_support, instant_upload, background_instant_upload, path_instant_upload, only_wifi_instant_upload, timestamp_last_instant_upload, url_redirected, sorting_type FROM users WHERE id = ?", [NSNumber numberWithInteger:idUser]];
        
        while ([rs next]) {
            
            output.idUser = [rs intForColumn:@"id"];
            output.deviceID = [rs stringForColumn:@"device_id"];
            if (output.deviceID.length == 0) {
                output.url = [rs stringForColumn:@"url"];
            }
            output.ssl = [rs intForColumn:@"ssl"];
            output.activeaccount = [rs intForColumn:@"activeaccount"];
            output.storageOccupied = [rs longForColumn:@"storage_occupied"];
            output.storage = [rs longForColumn:@"storage"];
            output.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            output.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            output.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            output.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            output.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            output.instantUpload = [rs intForColumn:@"instant_upload"];
            output.backgroundInstantUpload = [rs intForColumn:@"background_instant_upload"];
            output.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            output.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            output.timestampInstantUpload = [rs doubleForColumn:@"timestamp_last_instant_upload"];
            
            output.urlRedirected = [rs stringForColumn:@"url_redirected"];
            
            NSString *idString = [NSString stringWithFormat:@"%ld", (long)output.idUser];
            
            CredentialsDto *credDto = [OCKeychain getCredentialsById:idString];
            output.username = credDto.userName;
            output.password = credDto.password;
            
            output.sortingType = [rs intForColumn:@"sorting_type"];
        }
        
        [rs close];
        
    }];
    
    
    return output;
}

/*
 * Method that return if the user exist or not
 * @userDto -> user object
 */
+ (BOOL) isExistUser: (UserDto *) userDto {
    
    __block BOOL output = NO;
    
    NSArray *allUsers = [self getAllUsers];
    
    for (UserDto *user in allUsers) {
        if ([user.username isEqualToString:userDto.username] ) {
            if (user.deviceID.length > 0 && userDto.deviceID.length > 0) {
                if ([user.deviceID isEqualToString:userDto.deviceID]) {
                    output = YES;
                    break;
                }
            }
            else if (user.deviceID.length == 0 && userDto.deviceID.length == 0) {
                if ([user.url isEqualToString:userDto.url]) {
                    output = YES;
                    break;
                }
            }
        }
    }
    
    return output;
}

/*
 * Method that return an array with all users
 */
+ (NSMutableArray *) getAllUsers {
    
    DLog(@"getAllUsers");
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, device_id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, has_capabilities_support, instant_upload, background_instant_upload, path_instant_upload, only_wifi_instant_upload, timestamp_last_instant_upload, url_redirected, sorting_type FROM users ORDER BY id ASC"];
        
        UserDto *current = nil;
        
        while ([rs next]) {
            
            current = [UserDto new];
            
            current.idUser= [rs intForColumn:@"id"];
            current.deviceID = [rs stringForColumn:@"device_id"];
            if (current.deviceID.length == 0) {
                current.url = [rs stringForColumn:@"url"];
            }
            current.ssl = [rs intForColumn:@"ssl"];
            current.activeaccount = [rs intForColumn:@"activeaccount"];
            current.storageOccupied = [rs longForColumn:@"storage_occupied"];
            current.storage = [rs longForColumn:@"storage"];
            current.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            current.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            current.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            current.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            current.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            current.instantUpload = [rs intForColumn:@"instant_upload"];
            current.backgroundInstantUpload = [rs intForColumn:@"background_instant_upload"];
            current.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            current.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            current.timestampInstantUpload = [rs doubleForColumn:@"timestamp_last_instant_upload"];
            
            current.urlRedirected = [rs stringForColumn:@"url_redirected"];
            
            NSString *idString = [NSString stringWithFormat:@"%ld", (long)current.idUser];
            
            CredentialsDto *credDto = [OCKeychain getCredentialsById:idString];
            current.username = credDto.userName;
            current.password = credDto.password;
            
            current.sortingType = [rs intForColumn:@"sorting_type"];
            
            [output addObject:current];
            
        }
        
        [rs close];
        
    }];
    
    
    
    return output;
}

+ (NSMutableArray *) getAllUsersWithOutCredentialInfo{
    
    DLog(@"getAllUsersWithOutCredentialInfo");
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, device_id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, has_capabilities_support, instant_upload, background_instant_upload, path_instant_upload, only_wifi_instant_upload, timestamp_last_instant_upload, sorting_type FROM users ORDER BY id ASC"];
        
        UserDto *current = nil;
        
        while ([rs next]) {
            
            current = [UserDto new];
            
            current.idUser= [rs intForColumn:@"id"];
            current.deviceID = [rs stringForColumn:@"device_id"];
            if (current.deviceID.length == 0) {
                current.url = [rs stringForColumn:@"url"];
            }
            current.ssl = [rs intForColumn:@"ssl"];
            current.activeaccount = [rs intForColumn:@"activeaccount"];
            current.storageOccupied = [rs longForColumn:@"storage_occupied"];
            current.storage = [rs longForColumn:@"storage"];
            current.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            current.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            current.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            current.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            current.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            current.instantUpload = [rs intForColumn:@"instant_upload"];
            current.backgroundInstantUpload = [rs intForColumn:@"background_instant_upload"];
            current.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            current.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            current.timestampInstantUpload = [rs doubleForColumn:@"timestamp_last_instant_upload"];
            
            current.urlRedirected = @"";
            
            current.sortingType = [rs intForColumn:@"sorting_type"];
            
            [output addObject:current];
            
        }
        
        [rs close];
        
    }];
    
    
    return output;
    
}

/*
 * Method that return an array with all users.
 * This method is only used with the old structure of the table used until version 9
 * And is only used in the update database method
 */
+ (NSMutableArray *) getAllOldUsersUntilVersion10 {
    
    DLog(@"getAllUsers");
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, url, username, password, ssl, activeaccount, storage_occupied, storage, has_share_api_support FROM users ORDER BY id ASC"];
        
        UserDto *current = nil;
        
        while ([rs next]) {
            
            current = [UserDto new];
            
            current.idUser= [rs intForColumn:@"id"];
            current.url = [rs stringForColumn:@"url"];
            current.username = [rs stringForColumn:@"username"];
            current.password = [rs stringForColumn:@"password"];
            current.ssl = [rs intForColumn:@"ssl"];
            current.activeaccount = [rs intForColumn:@"activeaccount"];
            current.storageOccupied = [rs longForColumn:@"storage_occupied"];
            current.storage = [rs longForColumn:@"storage"];
            current.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            
            DLog(@"id user: %ld", (long)current.idUser);
            
            DLog(@"url user: %@", current.url);
            DLog(@"username user: %@", current.username);
            DLog(@"password user: %@", current.password);
            
            
            [output addObject:current];
            
        }
        
        [rs close];
        
    }];
    
    return output;
    
}

/*
 * Method that set a user like a active account
 * @idUser -> id user
 */
+(void) setActiveAccountByIdUser: (NSInteger) idUser {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET activeaccount=1 WHERE id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            DLog(@"Error setting the active account");
        }
        
    }];
    
}


/*
 * Method that set all acount as a no active.
 * This method is used before that set active account.
 */
+(void) setAllUsersNoActive {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET activeaccount=0"];
        
        if (!correctQuery) {
            DLog(@"Error setting no active all acounts");
        }
        
    }];
    
}

/*
 * Method that select one account active automatically
 */
+(void) setActiveAccountAutomatically {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET activeaccount=1 WHERE id = (SELECT id FROM users ORDER BY id limit 1)"];
        
        if (!correctQuery) {
            DLog(@"Error setting on account active automatically");
        }
        
    }];
    
}

/*
 * Method that remove user data in all tables
 * @idUser -> id user
 */
+(void) removeUserAndDataByIdUser:(NSInteger)idUser {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM users WHERE id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            DLog(@"Error delete files from files users table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            DLog(@"Error delete files from files files table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM files_backup WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            DLog(@"Error delete files from files_backup backup table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM uploads_offline WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            DLog(@"Error delete files from uploads uploads_offline table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM shared WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            DLog(@"Error delete info of shared table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM cookies_storage WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            DLog(@"Error delete info of cookies_storage table");
            
        }
        
    }];
    
    NSString *idString = [NSString stringWithFormat:@"%ld", (long)idUser];
    if (![OCKeychain removeCredentialsById:idString]) {
        DLog(@"Error delete keychain credentials");
        
    }
}

/*
 * Method that set the user storage of a user
 */
+(void) updateStorageByUserDto:(UserDto *) user {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET storage_occupied=?, storage=? WHERE id = ?", [NSNumber numberWithLong:user.storageOccupied], [NSNumber numberWithLong:user.storage], [NSNumber numberWithInteger:user.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error updating storage of user");
        }
        
    }];
    
}

/*
 * Method that return last user inserted on the Database
 */
+ (UserDto *) getLastUserInserted {
    
    __block UserDto *output = nil;
    
    output=[UserDto new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, device_id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, has_capabilities_support, instant_upload, background_instant_upload, path_instant_upload, only_wifi_instant_upload, timestamp_last_instant_upload, url_redirected, sorting_type FROM users ORDER BY id DESC LIMIT 1"];
        
        while ([rs next]) {
            
            output.idUser = [rs intForColumn:@"id"];
            output.deviceID = [rs stringForColumn:@"device_id"];
            if (output.deviceID.length == 0) {
                output.url = [rs stringForColumn:@"url"];
            }
            output.ssl = [rs intForColumn:@"ssl"];
            output.activeaccount = [rs intForColumn:@"activeaccount"];
            output.storageOccupied = [rs longForColumn:@"storage_occupied"];
            output.storage = [rs longForColumn:@"storage"];
            output.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            output.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            output.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            output.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            output.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            output.instantUpload = [rs intForColumn:@"instant_upload"];
            output.backgroundInstantUpload = [rs intForColumn:@"background_instant_upload"];
            output.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            output.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            output.timestampInstantUpload = [rs doubleForColumn:@"timestamp_last_instant_upload"];
            
            output.urlRedirected = [rs stringForColumn:@"url_redirected"];
            
            output.sortingType = [rs intForColumn:@"sorting_type"];
        }
        
        [rs close];
        
    }];
    
    return output;
}

//-----------------------------------
/// @name Update user by user
///-----------------------------------

/**
 * Method to update a user setting anything just sending the user
 *
 * @param UserDto -> user
 */
+ (void) updateUserByUserDto:(UserDto *) user {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET device_id=?, url=?, ssl=?, activeaccount=?, storage_occupied=?, storage=?, has_share_api_support=?, has_sharee_api_support=?, has_cookies_support=?, has_forbidden_characters_support=?, has_capabilities_support=?, instant_upload=?, background_instant_upload=?, path_instant_upload=?, only_wifi_instant_upload=?, timestamp_last_instant_upload=?, url_redirected=?, sorting_type=? WHERE id = ?", user.deviceID, user.deviceID ? nil : user.url, [NSNumber numberWithBool:user.ssl], [NSNumber numberWithBool:user.activeaccount], [NSNumber numberWithLong:user.storageOccupied], [NSNumber numberWithLong:user.storage], [NSNumber numberWithInteger:user.hasShareApiSupport], [NSNumber numberWithInteger:user.hasShareeApiSupport], [NSNumber numberWithInteger:user.hasCookiesSupport], [NSNumber numberWithInteger:user.hasForbiddenCharactersSupport], [NSNumber numberWithInteger:user.hasCapabilitiesSupport], [NSNumber numberWithBool:user.instantUpload], [NSNumber numberWithBool:user.backgroundInstantUpload], user.pathInstantUpload, [NSNumber numberWithBool:user.onlyWifiInstantUpload], [NSNumber numberWithLong:user.timestampInstantUpload], user.urlRedirected, [NSNumber numberWithInteger:user.sortingType], [NSNumber numberWithInteger:user.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error updating a user");
        }
        
    }];
    
}

//-----------------------------------
/// @name Has the Server Of the Active User Forbidden Character Support
///-----------------------------------

/**
 * Method to get YES/NO depend if the server of the active user has forbidden character support.
 *
 * @return BOOL
 */
+ (BOOL) hasTheServerOfTheActiveUserForbiddenCharactersSupport{
    
    BOOL isForbiddenCharacterSupport = NO;
    
    UserDto *activeUser = [ManageUsersDB getActiveUser];
    
    if (activeUser.hasForbiddenCharactersSupport == serverFunctionalitySupported) {
        isForbiddenCharacterSupport = YES;
    }
    
    return isForbiddenCharacterSupport;
}

//-----------------------------------
/// @name Update sorting choice by user
///-----------------------------------

/**
 * Method to update a user sorting choice for a user
 *
 * @param UserDto -> user
 */
+ (void) updateSortingWayForUserDto:(UserDto *)user {
    
    DLog(@"updateSortingTypeTo");
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET sorting_type=? WHERE id = ?", [NSNumber numberWithInteger:user.sortingType], [NSNumber numberWithInteger:user.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error updating sorting type");
        }
    }];
}

#pragma mark - urlRedirected

+(void)updateUrlRedirected:(NSString *)newValue byUserDto:(UserDto *)user {
    DLog(@"Updated url redirected");
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET url_redirected=? WHERE id = ?", newValue, [NSNumber numberWithInteger:user.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error updating url_redirected");
        }
    }];
}

+(NSString *)getUrlRedirectedByUserDto:(UserDto *)user {
    DLog(@"getUrlRedirected");
    
    __block NSString *output;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT url_redirected FROM users  WHERE id = ?", [NSNumber numberWithInteger:user.idUser]];
        
        while ([rs next]) {
            
            output = [rs stringForColumn:@"url_redirected"];
        }
        
    }];
    
    return output;
}

/*
 * Method that return if exist any user on the DB
 */
+(BOOL)isUsers {
    
    __block BOOL output = NO;
    __block int size = 0;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT count(*) FROM users"];
        
        while ([rs next]) {
            
            size = [rs intForColumnIndex:0];
        }
        
        if(size > 0) {
            output = YES;
        }
        
    }];
    
    return output;
    
}

@end
