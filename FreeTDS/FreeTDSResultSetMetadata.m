//
//  FreeTDSResultSetMetadata.m
//  FreeTDS
//
//  Created by Daniel Parnell on 21/10/11.
//  Copyright (c) 2011 Automagic Software Pty Ltd. All rights reserved.
//

#import "FreeTDSResultSetMetadata.h"
#import "FreeTDS.h"

@interface FreeTDS (Private)

- (void) checkForError:(NSError**)error;

@end

@implementation FreeTDSResultSetMetadata

- (id) initWithFreeTDS:(FreeTDS*)connection {
    self = [super init];
    
    if(self) {
        free_tds = connection;
    }
    
    return  self;
}

- (int) getColumnCount {
    return dbnumcols(free_tds.process);
}

- (NSString*) getColumnName:(int)index error:(NSError **)error{
    char *colname = dbcolname(free_tds.process, index+1);
    [free_tds checkForError: error];
    
    return [NSString stringWithCString: colname encoding: NSUTF8StringEncoding];
}

- (int) getColumnType:(int)index error:(NSError**)error {
    int result = dbcoltype(free_tds.process, index + 1);
    [free_tds checkForError: error];
    
    return result;
}

- (NSString*) getColumnTypeName:(int)index error:(NSError **)error {
    const char* typename = dbprtype([self getColumnType: index error: error]);
    
    return [NSString stringWithCString: typename encoding: NSUTF8StringEncoding];
}

@end
