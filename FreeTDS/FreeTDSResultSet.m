//
//  FreeTDSResultSet.m
//  FreeTDS
//
//  Created by Daniel Parnell on 21/10/11.
//  Copyright (c) 2011 Automagic Software Pty Ltd. All rights reserved.
//

#import "FreeTDSResultSet.h"

@implementation FreeTDSResultSet

- (id) initWithProcess:(DBPROCESS*)dbprocess {
    self = [super init];
    
    if(self) {
        process = dbprocess;
    }
    
    return self;
}

@end
