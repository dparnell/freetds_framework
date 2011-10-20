//
//  FreeTDS.h
//  FreeTDS
//
//  Created by Daniel Parnell on 19/10/11.
//  Copyright (c) 2011 Automagic Software Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FreeTDS/sybfront.h>
#import <FreeTDS/sybdb.h>

const extern NSString* FREETDS_SERVER;
const extern NSString* FREETDS_USER;
const extern NSString* FREETDS_PASS;
const extern NSString* FREETDS_DATABASE;

const extern NSString* FREETDS_OS_ERROR;
const extern NSString* FREETDS_OS_CODE;
const extern NSString* FREETDS_DB_ERROR;
const extern NSString* FREETDS_DB_CODE;
const extern NSString* FREETDS_SEVERITY;

@class FreeTDS;

@protocol FreeTDSDelegate <NSObject>

- (int) handleMessage:(NSString*) message from:(FreeTDS*)free_tds;

@end

@interface FreeTDS : NSObject {
@private
    LOGINREC* login;
    DBPROCESS* process;

    NSException* to_throw;
}

+ (FreeTDS*) connectionWithDictionary:(NSDictionary*)dictionary;
- (id) initWithDictionary:(NSDictionary*)dictionary;

@property (readonly) LOGINREC* login;
@property (readonly) DBPROCESS* process;

@end
