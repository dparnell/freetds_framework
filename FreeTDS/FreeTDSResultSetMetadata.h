//
//  FreeTDSResultSetMetadata.h
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
