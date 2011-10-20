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

@interface FreeTDSResultSet : NSObject {
@private
    DBPROCESS* process;
}

- (BOOL) next;

@end
