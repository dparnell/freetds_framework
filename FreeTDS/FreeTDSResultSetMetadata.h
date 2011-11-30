//
//  FreeTDSResultSetMetadata.h
//  FreeTDS
//
//  Created by Daniel Parnell on 21/10/11.
//  Copyright (c) 2011 Automagic Software Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FreeTDS/sybfront.h>
#import <FreeTDS/sybdb.h>

@class FreeTDS;

@interface FreeTDSResultSetMetadata : NSObject {
@private
    __weak FreeTDS* free_tds;
}

- (id) initWithFreeTDS:(FreeTDS*)connection;

- (int) getColumnCount;
- (NSString*) getColumnName:(int)index error:(NSError**)error;
- (int) getColumnType:(int)index error:(NSError**)error;
- (NSString*) getColumnTypeName:(int)index error:(NSError**)error;

@end
