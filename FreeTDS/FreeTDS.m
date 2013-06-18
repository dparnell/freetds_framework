//
//  FreeTDS.m
//  FreeTDS
//
//  Created by Daniel Parnell on 19/10/11.
//  Copyright (c) 2011 Automagic Software Pty Ltd. All rights reserved.
//

#import "FreeTDS.h"

#define DEFAULT_PROTOCOL_VERSION 5

const NSString* FREETDS_SERVER = @"Server";
const NSString* FREETDS_USER = @"User";
const NSString* FREETDS_PASS = @"Password";
const NSString* FREETDS_DATABASE = @"Database";
const NSString* FREETDS_APPLICATION = @"Application";
const NSString* FREETDS_HOST = @"Host";
const NSString* FREETDS_PORT = @"Port";
const NSString* FREETDS_PROTOCOL_VERSION = @"Protocol Version";

const NSString* FREETDS_OS_ERROR = @"OS Error Description";
const NSString* FREETDS_OS_CODE = @"OS Error Code";
const NSString* FREETDS_DB_ERROR = @"Database Error";
const NSString* FREETDS_DB_CODE = @"Database Error Code";
const NSString* FREETDS_SEVERITY = @"Severity";
const NSString* FREETDS_MESSAGE = @"Message";
const NSString* FREETDS_MESSAGE_NUMBER = @"Message Number";
const NSString* FREETDS_MESSAGE_STATE = @"Message State";
const NSString* FREETDS_PROC_NAME = @"Procedure Name";
const NSString* FREETDS_LINE = @"Line";

const NSLock* login_lock = nil;

@interface FreeTDS (Private)

- (BOOL) checkForError:(NSError**)error;
- (void) reset;

@end

@implementation FreeTDS

@synthesize login, process, delegate;


#pragma mark -
#pragma mark Error handlers

static __strong NSError* login_error = nil;

static id string_or_null(const char* s) {
    if(s) {
        return [NSString stringWithCString: s encoding: NSUTF8StringEncoding];
    }
    
    return [NSNull null];
}

static int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr) {
    int return_value = INT_CANCEL;
    
    if(dbproc) {
        FreeTDS* free_tds = (__bridge FreeTDS*)(void*)dbgetuserdata(dbproc);

        NSLog(@"err_handler: %p %d %d %d %s %s", dbproc, severity, dberr, oserr, dberrstr, oserrstr);

        int cancel = 0;
        switch(dberr) {
            case 100: /* SYBEVERDOWN */
                return INT_CANCEL;
            case SYBESMSG:
                return return_value;
            case SYBEICONVI:
                return INT_CANCEL;
            case SYBEFCON:
            case SYBESOCK:
            case SYBECONN:
                return_value = INT_CANCEL;
                break;
            case SYBESEOF: {
                if (free_tds && free_tds->timing_out) {
                    return_value = INT_TIMEOUT;
                } else {
                    return INT_CANCEL;
                }
                break;
            }
            case SYBETIME: {
                if (free_tds) {
                    if (free_tds->timing_out) {
                        return INT_CONTINUE;
                    } else {
                        free_tds->timing_out = YES;
                    }
                }
                cancel = 1;
                break;
            }
            case SYBEWRIT: {
                if (free_tds && (free_tds->dbsqlok_sent || free_tds->dbcancel_sent))
                    return INT_CANCEL;
                cancel = 1;
                break;
            }
            case SYBEREAD:
                cancel = 1;
                break;
        }

        NSError* er = [NSError errorWithDomain: [NSString stringWithCString: dberrstr encoding: NSUTF8StringEncoding]
                                          code: dberr 
                                      userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
                                                           string_or_null(oserrstr), FREETDS_OS_ERROR,
                                                           [NSNumber numberWithInt: oserr], FREETDS_OS_CODE,
                                                           string_or_null(dberrstr), FREETDS_DB_ERROR,
                                                           [NSNumber numberWithInt: dberr], FREETDS_DB_CODE,
                                                           [NSNumber numberWithInt: severity], FREETDS_SEVERITY,
                                                           nil]];

        if(cancel) {
            dbcancel(dbproc);
        }

        if(free_tds) {
            if(free_tds->last_error == nil) {
                free_tds->last_error = er;
            }
        } else {
            login_error = er;
        }    
    }
    return return_value;
}

static int msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate, int severity, char *msgtext, char *srvname, char *procname, int line) {
    if(dbproc) {
        FreeTDS* free_tds = (__bridge FreeTDS*)(void*)dbgetuserdata(dbproc);
        
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys: 
                              string_or_null(msgtext), FREETDS_MESSAGE,
                              [NSNumber numberWithInt: msgno], FREETDS_MESSAGE_NUMBER,
                              [NSNumber numberWithInt: msgstate], FREETDS_MESSAGE_STATE,
                              string_or_null(srvname), FREETDS_SERVER,
                              string_or_null(procname), FREETDS_PROC_NAME,
                              [NSNumber numberWithInt: line], FREETDS_LINE,
                              [NSNumber numberWithInt: severity], FREETDS_SEVERITY,
                              nil];
//        NSLog(@"info = %@", info);
        
        if(severity>10) {
            NSError* er = [NSError errorWithDomain: [NSString stringWithCString: msgtext encoding: NSUTF8StringEncoding] 
                                              code: msgno 
                                          userInfo: info];
            
            if(free_tds) {
                free_tds->last_error = er;
            } else {
                login_error = er;
            }        
        } else {
            if (free_tds && free_tds->delegate) {
                return [free_tds->delegate handleMessage: info withSeverity: severity from: free_tds];
            }
        }
        
    }
    return  0;
}


#pragma mark -
#pragma mark Init and dealloc

+ (void) initialize {
    login_lock = [NSLock new];
}

+ (FreeTDS*) connectionWithDictionary:(NSDictionary*)dictionary andError:(NSError **)error {
    FreeTDS* result = [FreeTDS new];
    if([result loginWithDictionary: dictionary andError: error]) {
        return result;
    }
    
    return nil;
}

- (void)dealloc {
    [self close];
    
}


#pragma mark -


- (BOOL) loginWithDictionary:(NSDictionary*)dictionary andError:(NSError**) error {
    NSString* user = [dictionary objectForKey: FREETDS_USER];
    NSString* password = [dictionary objectForKey: FREETDS_PASS];
    NSString* server = [dictionary objectForKey: FREETDS_SERVER];
    NSString* database = [dictionary objectForKey: FREETDS_DATABASE];
    NSString* application = [dictionary objectForKey: FREETDS_APPLICATION];
    NSNumber* protocol = [dictionary objectForKey: FREETDS_PROTOCOL_VERSION];
    
    if(dbinit() == FAIL) {
        @throw [NSException exceptionWithName: @"FreeTDS" reason: NSLocalizedString(@"Could not initialize FreeTDS", @"dbinit failed") userInfo: nil];
    }
    dbsetifile((char *)[[[NSBundle bundleForClass: [FreeTDS class]] pathForResource: @"freetds" ofType: @"conf"] UTF8String]);
    
    dberrhandle(err_handler);
    dbmsghandle(msg_handler);
    
    login = dblogin();
    if(user) {
        dbsetluser(login, [user UTF8String]);
    }
    if(password) {
        dbsetlpwd(login, [password UTF8String]);
    }
    if(application) {
        dbsetlapp(login, [application UTF8String]);
    }
    if(protocol) {
        dbsetlversion(login, [protocol intValue]);
    } else {
        dbsetlversion(login, DEFAULT_PROTOCOL_VERSION);
    }
    
    if(server == nil) {
        NSString* host = [dictionary objectForKey: FREETDS_HOST];
        NSNumber* port = [dictionary objectForKey: FREETDS_PORT];

        if(port == nil) {
            server = [host stringByAppendingString: @":1433"];
        } else {
            server = [host stringByAppendingFormat: @":%d", [port intValue]];
        }
    }
        
    @synchronized(login_lock) {
        login_error = nil;
        process = dbopen(login, [server UTF8String]);
        if(login_error && error) {
            *error = login_error;
        }
    }
    
    if(process) {
        dbsetuserdata(process, (__bridge void*)self);
        
        if(database) {
            dbuse(process, [database UTF8String]);
            return [self checkForError: error];
        }
        
        return YES;
    }
    
    return NO;
}

- (void) close {
    if(login) {
        dbloginfree(login);
        login = nil;
    }
    if(process) {
        dbclose(process);
        process = nil;
    }
}

- (NSString*) quote:(id)value {
    if(value == nil || [value isKindOfClass: [NSNull class]]) {
        return @"NULL";
    } else {
        if([value isKindOfClass: [NSString class]]) {
            return [NSString stringWithFormat: @"'%@'", [value stringByReplacingOccurrencesOfString: @"'" withString: @"''"]];
        } else if([value isKindOfClass: [NSNumber class]]) {
            return [value stringValue];
        } else if([value isKindOfClass: [NSData class]]) {
            NSString* hex = [[[value description] stringByReplacingOccurrencesOfString: @" " withString: @""] stringByTrimmingCharactersInSet: [NSCharacterSet symbolCharacterSet]];
            return [NSString stringWithFormat: @"0x%@", hex];
        } else if([value isKindOfClass: [NSDate class]]) {
            return [value descriptionWithCalendarFormat: @"'%m-%d-%Y %H:%M%S'"];
        }        
    }
    
    @throw [NSException exceptionWithName: @"FreeTDS" reason: @"Unhandled value type" userInfo: [NSDictionary dictionaryWithObject: value forKey: @"value"]];
}

- (FreeTDSResultSet*) executeQuery:(NSString*) sql withParameters:(NSDictionary*)parameters andError:(NSError **)error{
    FreeTDSResultSet* result = nil;
    
    if(parameters) {
        for(NSString* param in parameters) {
            NSString* quoted_value = [self quote: [parameters objectForKey: param]];
            sql = [sql stringByReplacingOccurrencesOfString: param withString: quoted_value];
        }
    }
    
    [self reset];
    if(dbcmd(process, [sql UTF8String]) == SUCCEED) {    
        if(dbsqlsend(process) == SUCCEED) {
            result = [[FreeTDSResultSet alloc] initWithFreeTDS: self];
        }
    }
    [self checkForError:error];
    
    return result;    
}

#pragma mark -
#pragma mark Private stuff

- (BOOL) checkForError:(NSError**)error {
    if(last_error) {
        if (error) {
            *error = last_error;
        }
        
        last_error = nil;
        return NO;
    }
    
    return YES;
}

- (void) reset {
    last_error = nil;
    timing_out = NO;
    dbsqlok_sent = NO;
    dbcancel_sent = NO;    
}

@end
