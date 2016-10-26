/*
 * Copyright (C) 2015 Elastos.org
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef ECSDefine_h
#define ECSDefine_h


/*!
 *  pair mode
 */
typedef NS_ENUM(int, ECSPairMode) {
    ECSPairModeDeny                     =   0,
    ECSPairModeGuest                    =   1,
    ECSPairModeHost                     =   2,
};

/*!
 *  offline reason
 */
typedef NS_ENUM(int, ECSOfflineReason) {
    ECSOfflineReasonNetWork             =   0,
};

/*!
 *  ECSSession close reason
 */
typedef NS_ENUM(int, ECSSessionCloseReason) {
    ECSSessionCloseReasonOK             =   0,
    ECSSessionCloseReasonNetWork        =   1,
};

/*!
 *  pair result
 */
typedef NS_ENUM(int, ECSPairResult) {
    ECSPairResultOK                     =   0,
    ECSPairResultWrongCredential        =   1,
    ECSPairResultAlreadyPair            =   2,
    ECSPairResultNoDevice               =   3,
    ECSPairResultDeviceOffLine          =   4,
    ECSPairResultDeny                   =   5,
    ECSPairResultUnkonw                 =   6,
};


/*!
 *  device Event
 */
typedef NS_ENUM(int, ECSDeviceEvent){
    ECSDeviceEventOnline                =   1,  // Device becomes online
    ECSDeviceEventOffline               =   2,  // Device becomes offline.
    ECSDeviceEventDenied                =   3,  // Pairing to device was denied.
    ECSDeviceEventHost                  =   4,  // Host pairing to device is authorized.
    ECSDeviceEventGuest                 =   5,  // Guest pairing to device is authorized.
    ECSDeviceEventUnkown                =   6,
};


/*!
 *  device crential
 */
typedef NS_ENUM(int, ECSDeviceCredential) {
    ECSDeviceCredentialOK               =   0,
    ECSDeviceCredentialBad              =   1,
    ECSDeviceCredentialLimit            =   2,
    ECSDeviceCredentialUnknow           =   3,
};


FOUNDATION_EXTERN NSString * const ECSDKErrorDomain;

/*!
 *  ECSClient error code
 */
typedef NS_ENUM(NSUInteger, ECSDevErrorCode) {
    ECSDevErrorCode_NoError              =   0,
    
    ECSDevErrorCode_UnknowCarrier        =   0x80001001,
    ECSDevErrorCode_BadCarrier           =   0x80001002,
    ECSDevErrorCode_BadHttpsServer       =   0x80001003,
    
    ECSDevErrorCode_AlreadyStarted       =   0x80001005,
    ECSDevErrorCode_NoPeerStart          =   0x80001006,
    
    ECSDevErrorCode_ClientOffLine        =   0x80001020,
    ECSDevErrorCode_DeviceOffLine        =   0x80001021,
    ECSDevErrorCode_ClientExist          =   0x80001022,
    ECSDevErrorCode_NoClient             =   0x80001023,
    ECSDevErrorCode_NoDevice             =   0x80001024,
    ECSDevErrorCode_BadSignature         =   0x80001025,
    ECSDevErrorCode_BadCredential        =   0x80001026,
    ECSDevErrorCode_BadClient            =   0x80001027,
    ECSDevErrorCode_BadAppID             =   0x80001028,
    ECSDevErrorCode_PermDenied           =   0x80001029,
    ECSDevErrorCode_BadPhoneNumber       =   0x80001030,
    ECSDevErrorCode_BadVerifyCode        =   0x80001031,
    ECSDevErrorCode_NetWork              =   0x80001032,
    ECSDevErrorCode_Limit                =   0x80001033,
    ECSDevErrorCode_NoAppId              =   0x80001034,
    ECSDevErrorCode_NoAppKey             =   0x80001035,
    ECSDevErrorCode_BadClientId          =   0x80001036,
    ECSDevErrorCode_BadClientKey         =   0x80001037,
    
    ECSDevErrorCode_BadParam             =   0x80001040,
    ECSDevErrorCode_OOM                  =   0x80001041,
    ECSDevErrorCode_NotImplemented       =   0x80001042,
    ECSDevErrorCode_TimeOut              =   0x80001043,
    ECSDevErrorCode_Socket               =   0x80001044,
    ECSDevErrorCode_Https                =   0x80001045,
    ECSDevErrorCode_Json                 =   0x80001046,
    
    ECSDevErrorCode_Unknow               =   0x80001099
};

/*!
 *  ECSSession error code
 */
typedef NS_ENUM(NSUInteger, ECSSessionErrorCode) {
    ECSSessionErrorCode_BadParam                =   0x80002001,
    ECSSessionErrorCode_OOM                     =   0x80002002,
    ECSSessionErrorCode_AlreadyStarted          =   0x80002003,
    ECSSessionErrorCode_NotStart                =   0x80002004,
    ECSSessionErrorCode_BadSession              =   0x80002008,
    ECSSessionErrorCode_ExceedLimit             =   0x80002009,
    ECSSessionErrorCode_NetWork                 =   0x8000200A,
    ECSSessionErrorCode_Unknown                 =   0x8000200B,
    
    ECSSessionErrorCode_PJUnknown               =   0x80002201,
    ECSSessionErrorCode_PJPending               =   0x80002202,
    ECSSessionErrorCode_PJTooManyConn           =   0x80002203,
    ECSSessionErrorCode_PJInval                 =   0x80002204,
    ECSSessionErrorCode_PJNameToolLong          =   0x80002205,
    ECSSessionErrorCode_PJNotFound              =   0x80002206,
    ECSSessionErrorCode_PJNoMem                 =   0x80002207,
    ECSSessionErrorCode_PJBug                   =   0x80002208,
    ECSSessionErrorCode_PJTimedOut              =   0x80002209,
    ECSSessionErrorCode_PJTooMany               =   0x8000220A,
    ECSSessionErrorCode_PJBusy                  =   0x8000220B,
    ECSSessionErrorCode_PJNotSup                =   0x8000220C,
    ECSSessionErrorCode_PJInvalidop             =   0x8000220D,
    ECSSessionErrorCode_PJCancelled             =   0x8000220E,
    ECSSessionErrorCode_PJExists                =   0x8000220F,
    ECSSessionErrorCode_PJEof                   =   0x80002210,
    ECSSessionErrorCode_PJTooBig                =   0x80002211,
    ECSSessionErrorCode_PJResolve               =   0x80002212,
    ECSSessionErrorCode_PJTooSmall              =   0x80002213,
    ECSSessionErrorCode_PJIgnored               =   0x80002214,
    ECSSessionErrorCode_PJIPV6NotSup            =   0x80002215,
    ECSSessionErrorCode_PJAFnotSup              =   0x80002216,
    ECSSessionErrorCode_PJGone                  =   0x80002217,
    ECSSessionErrorCode_PJSocketStop            =   0x80002218,
    
    ECSSessionErrorCode_Einstunmsg              =   0x80002230,
    ECSSessionErrorCode_Einstunmsglen           =   0x80002231,
    ECSSessionErrorCode_Einstunmsgtype          =   0x80002232,
    ECSSessionErrorCode_StuntimerOut            =   0x80002233,
    ECSSessionErrorCode_Estuntoomanyattr        =   0x80002234,
    ECSSessionErrorCode_Estuninattrlen          =   0x80002235,
    ECSSessionErrorCode_Estundupattr            =   0x80002236,
    ECSSessionErrorCode_Estunfingerprint        =   0x80002237,
    ECSSessionErrorCode_EstunmsgIntpos          =   0x80002238,
    ECSSessionErrorCode_Estunfingerpos          =   0x80002239,
    ECSSessionErrorCode_Estunnnomappedaddr      =   0x8000223A,
    ECSSessionErrorCode_Estunipv6Notsupp        =   0x8000223B,
    ECSSessionErrorCode_Einvaf                  =   0x8000223C,
    ECSSessionErrorCode_Estuninserver           =   0x8000223D,
    ECSSessionErrorCode_Estundestroyed          =   0x8000223E,
    ECSSessionErrorCode_Enotice                 =   0x8000223F,
    ECSSessionErrorCode_Eiceinprogress          =   0x80002240,
    ECSSessionErrorCode_Eicefailed              =   0x80002241,
    ECSSessionErrorCode_EicMismatch             =   0x80002242,
    ECSSessionErrorCode_Eiceincompid            =   0x80002243,
    ECSSessionErrorCode_Eiceincandid            =   0x80002244,
    ECSSessionErrorCode_Eiceinsrcaddr           =   0x80002245,
    ECSSessionErrorCode_EicemissIngsdp          =   0x80002246,
    ECSSessionErrorCode_Eiceincandsdp           =   0x80002247,
    ECSSessionErrorCode_Eicenohostcand          =   0x80002248,
    ECSSessionErrorCode_Eicenomtimeout          =   0x80002249,
    ECSSessionErrorCode_EturnIntp               =   0x8000224a
};

/*!
 *  ECSRdt error code
 */
typedef NS_ENUM(NSUInteger, ECSRdtErrorCode) {
    ECSRdtErrorCode_BadParam                    =   0x80003001,
    ECSRdtErrorCode_OOM                         =   0x80003002,
    ECSRdtErrorCode_AlreadyStarted              =   0x80003003,
    ECSRdtErrorCode_NotStarted                  =   0x80003004,
    ECSRdtErrorCode_BadRdtTunnel                =   0x80003008,
    ECSRdtErrorCode_ExceedLimit                 =   0x80003009,
    ECSRdtErrorCode_NetWork                     =   0x8000300A,
    ECSRdtErrorCode_Unknown                     =   0x8000300B,
    ECSRdtErrorCode_NotImplemented              =   0x8000300C,
};

/*!
 *  ECSUdt error code
 */
typedef NS_ENUM(NSUInteger, ECSUdtErrorCode) {
    ECSUdtErrorCode_BadParam                    =   0x80004001,
    ECSUdtErrorCode_OOM                         =   0x80004002,
    ECSUdtErrorCode_AlreadyStarted              =   0x80004003,
    ECSUdtErrorCode_NotStarted                  =   0x80004004,
    ECSUdtErrorCode_BadRdtTunnel                =   0x80004008,
    ECSUdtErrorCode_ExceedLimit                 =   0x80004009,
    ECSUdtErrorCode_NetWork                     =   0x8000400A,
    ECSUdtErrorCode_Unknown                     =   0x8000400B,
    ECSUdtErrorCode_NotImplemented              =   0x8000400C,
};

#endif /* ECSDefine_h */
