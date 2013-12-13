//
//  FreeTDSResultSetMetadata.m
//  FreeTDS
//
//  Created by Daniel Parnell on 21/10/11.
//  Copyright (c) 2011 Automagic Software Pty Ltd. All rights reserved.
/* This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

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
