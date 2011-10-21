//
//  FreeTDSResultSet.h
//  FreeTDS
//
//  Created by Daniel Parnell on 21/10/11.
//  Copyright (c) 2011 Automagic Software Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FreeTDS/sybfront.h>
#import <FreeTDS/sybdb.h>

@class FreeTDS;
@class FreeTDSResultSetMetadata;

@interface FreeTDSResultSet : NSObject {
@private
    __weak FreeTDS* free_tds;
    BOOL dbsqlok_sent;
    RETCODE dbsqlok_result;
    BOOL dbresults_sent;
    RETCODE dbresults_result;
}

- (id) initWithFreeTDS:(FreeTDS*)connection;

- (FreeTDSResultSetMetadata*) getMetadata;

- (BOOL) hasResults;

- (BOOL) next;
- (void) close;
- (id) getObject:(int)index;

@end
