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

- (void) checkForError;

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

- (NSString*) getColumnName:(int)index {
    char *colname = dbcolname(free_tds.process, index+1);
    
    return [NSString stringWithCString: colname encoding: NSUTF8StringEncoding];
}

- (int) getColumnType:(int)index {
    int result = dbcoltype(free_tds.process, index + 1);
    [free_tds checkForError];
    
    return result;
}

- (NSString*) getColumnTypeName:(int)index {
    const char* typename = dbprtype([self getColumnType: index]);
    [free_tds checkForError];
    
    return [NSString stringWithCString: typename encoding: NSUTF8StringEncoding];
}

@end
