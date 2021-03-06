//
//  CapabilitiesDto.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/11/15.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "OCCapabilities.h"

@interface CapabilitiesDto : OCCapabilities

//The relation between the user and the capabilities. For use in the App
@property (nonatomic) NSInteger idCapabilities;
@property (nonatomic) NSInteger idUser;

@end
