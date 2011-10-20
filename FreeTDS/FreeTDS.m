//
//  FreeTDS.m
//  FreeTDS
//
//  Created by Daniel Parnell on 19/10/11.
//  Copyright (c) 2011 Automagic Software Pty Ltd. All rights reserved.
//

#import "FreeTDS.h"

const NSString* FREETDS_SERVER = @"Server";
const NSString* FREETDS_USER = @"User";
const NSString* FREETDS_PASS = @"Password";
const NSString* FREETDS_DATABASE = @"Database";

const NSString* FREETDS_OS_ERROR = @"OS Error Description";
const NSString* FREETDS_OS_CODE = @"OS Error Code";
const NSString* FREETDS_DB_ERROR = @"Database Error";
const NSString* FREETDS_DB_CODE = @"Database Error Code";
const NSString* FREETDS_SEVERITY = @"Severity";

const NSLock* login_lock = nil;

@implementation FreeTDS

@synthesize login, process;


#pragma mark -
#pragma mark Error handlers

static NSException* login_exception = nil;

static int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr) {
    NSException* ex = [NSException exceptionWithName: @"FreeTDS" 
                                              reason: [NSString stringWithFormat: @"%d - %s", dberr, dberrstr] 
                                            userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
                                                       [NSString stringWithCString: oserrstr encoding: NSUTF8StringEncoding], FREETDS_OS_ERROR,
                                                       [NSNumber numberWithInt: oserr], FREETDS_OS_CODE,
                                                       [NSString stringWithCString: dberrstr encoding: NSUTF8StringEncoding], FREETDS_DB_ERROR,
                                                       [NSNumber numberWithInt: dberr], FREETDS_DB_CODE,
                                                       [NSNumber numberWithInt: severity], FREETDS_SEVERITY,
                                                       nil]];
    
    FreeTDS* free_tds = (FreeTDS*)dbgetuserdata(dbproc);
    if(free_tds) {
        free_tds->to_throw = ex;
    } else {
        login_exception = ex;
    }
    
    return INT_CONTINUE;
}

static int msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate, int severity, char *msgtext, char *srvname, char *procname, int line) {
    
    return  0;
}


#pragma mark -
#pragma mark Init and dealloc

+ (void) initialize {
    login_lock = [[NSLock new] retain];
}

+ (FreeTDS*) connectionWithDictionary:(NSDictionary*)dictionary {
    return [[[FreeTDS alloc] initWithDictionary: dictionary] autorelease];
}

- (id) initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        NSString* user = [dictionary objectForKey: FREETDS_USER];
        NSString* password = [dictionary objectForKey: FREETDS_PASS];
        NSString* server = [dictionary objectForKey: FREETDS_SERVER];
        NSString* database = [dictionary objectForKey: FREETDS_DATABASE];
        
        if(dbinit() == FAIL) {
            @throw [NSException exceptionWithName: @"FreeTDS" reason: NSLocalizedString(@"Could not initialize FreeTDS", @"dbinit failed") userInfo: nil];
        }
        
        dberrhandle(err_handler);
        dbmsghandle(msg_handler);
        
        login = dblogin();
        if(user) {
            dbsetluser(login, [user UTF8String]);
        }
        if(password) {
            dbsetlpwd(login, [password UTF8String]);
        }

        [login_lock lock];
        @try {
            login_exception = nil;
            process = dbopen(login, [server UTF8String]);
            if(login_exception) {
                @throw login_exception;
            }
        } @finally {
            login_exception = nil;
            [login_lock unlock];
        }
        
        if(process) {
            
            
            if(database) {
                dbuse(process, [database UTF8String]);
            }
        } else {
        }
    }
    return self;
}

- (void)dealloc {
    
    [super dealloc];
}

@end
