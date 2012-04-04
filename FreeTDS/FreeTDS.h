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
#import <FreeTDS/FreeTDSResultSet.h>

const extern NSString* FREETDS_SERVER;
const extern NSString* FREETDS_HOST;
const extern NSString* FREETDS_PORT;
const extern NSString* FREETDS_USER;
const extern NSString* FREETDS_PASS;
const extern NSString* FREETDS_DATABASE;
const extern NSString* FREETDS_APPLICATION;
const extern NSString* FREETDS_PROTOCOL_VERSION;

const extern NSString* FREETDS_OS_ERROR;
const extern NSString* FREETDS_OS_CODE;
const extern NSString* FREETDS_DB_ERROR;
const extern NSString* FREETDS_DB_CODE;
const extern NSString* FREETDS_SEVERITY;
const extern NSString* FREETDS_MESSAGE;
const extern NSString* FREETDS_MESSAGE_NUMBER;
const extern NSString* FREETDS_MESSAGE_STATE;
const extern NSString* FREETDS_PROC_NAME;
const extern NSString* FREETDS_LINE;

@class FreeTDS;

@protocol FreeTDSDelegate <NSObject>

- (int) handleMessage:(NSDictionary*) message withSeverity:(int)severity from:(FreeTDS*)free_tds;

@end

@interface FreeTDS : NSObject {
@private
    __unsafe_unretained id <FreeTDSDelegate> delegate;
    NSError* last_error;
    
    LOGINREC* login;
    DBPROCESS* process;
    BOOL timing_out;
    BOOL dbsqlok_sent;
    BOOL dbcancel_sent;    
}

+ (FreeTDS*) connectionWithDictionary:(NSDictionary*)dictionary andError:(NSError**)error;
- (BOOL) loginWithDictionary:(NSDictionary*)dictionary andError:(NSError**)error;

- (FreeTDSResultSet*) executeQuery:(NSString*) sql withParameters:(NSDictionary*)parameters andError: (NSError**)error;
- (void) close;

@property (readonly) LOGINREC* login;
@property (readonly) DBPROCESS* process;
@property (nonatomic, assign) id <FreeTDSDelegate> delegate;

@end
