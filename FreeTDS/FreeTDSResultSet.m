//
//  FreeTDSResultSet.m
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


#import "FreeTDSResultSet.h"
#import "FreeTDS.h"
#import "FreeTDSResultSetMetadata.h"
#import <time.h>

@interface FreeTDS (Private)

- (BOOL) checkForError:(NSError**)error;

@end

@implementation FreeTDSResultSet

- (id) initWithFreeTDS:(FreeTDS*)connection {
    self = [super init];
    
    if(self) {
        free_tds = connection;
        dbsqlok_sent = NO;
        dbresults_sent = NO;
    }
    
    return self;
}


#pragma mark -
#pragma mark Internal methods

- (RETCODE) sendOK:(NSError**)error {
    if(!dbsqlok_sent) {
        dbsqlok_sent = YES;
        dbsqlok_result = dbsqlok(free_tds.process);
        [free_tds checkForError: error];
        return dbsqlok_result;
    }
    
    return SUCCEED;
}

- (RETCODE) sendResults:(NSError**)error {
    if(!dbresults_sent) {
        dbresults_sent = YES;
        dbresults_result = dbresults(free_tds.process);
        [free_tds checkForError: error];
        return dbresults_result;
    }
    
    return SUCCEED;
}

#pragma mark -
#pragma mark Published Methods

- (FreeTDSResultSetMetadata*) getMetadata:(NSError**)error {
    if([self sendOK: error] == SUCCEED) {
        if([self sendResults: error] == SUCCEED) {
            return [[FreeTDSResultSetMetadata alloc] initWithFreeTDS: free_tds];
        }
    }
    
    return  nil;
}

- (void) reset {
    dbsqlok_sent = NO;
    dbresults_sent = NO;
}

- (BOOL) hasResults:(NSError**)error {
    return [self sendResults: error] == SUCCEED;
}

- (BOOL) next:(NSError**)error {
    if([self sendOK: error] == SUCCEED) {
        if([self sendResults: error] == SUCCEED) {    
            BOOL result = dbnextrow(free_tds.process) != NO_MORE_ROWS;        
            [free_tds checkForError: error];
        
            return result;
        }
    }
    
    dbresults_sent = NO;
    return NO;
}

- (BOOL) close:(NSError**)error {
    if([self sendOK: error] == SUCCEED) {    
        dbcancel([free_tds process]);
        return [free_tds checkForError: error];
    }
    
    return NO;
}

- (id) getObject:(int) index error:(NSError**) error{
    if([self sendOK: error] == SUCCEED) {    
        int col = index + 1;
        DBPROCESS* process = free_tds.process;
    
        int coltype = dbcoltype(process, col);
        [free_tds checkForError: error];
        BYTE *data = dbdata(process, col);
        [free_tds checkForError: error];
        DBINT data_len = dbdatlen(process, col);
        [free_tds checkForError: error];
    
        id result;
        
        int null_val = ((data == NULL) && (data_len == 0));
        if (null_val) {
            result = [NSNull null];
        } else {
            if(data == NULL) {
                return [NSNull null];
            }
            switch(coltype) {
                case SYBINT1:
                    result = [NSNumber numberWithInt: *(DBTINYINT *)data];
                    break;
                case SYBINT2:
                    result = [NSNumber numberWithInt: *(DBSMALLINT *)data];
                    break;
                case SYBINT4:
                    result = [NSNumber numberWithInt: *(DBINT *)data];
                    break;
                case SYBINT8:
                    result = [NSNumber numberWithLongLong: *(DBBIGINT *)data];
                    break;
                case SYBBIT:
                    result = [NSNumber numberWithBool: *(int *)data != 0];
                    break;
                case SYBNUMERIC:
                case SYBDECIMAL: { 
                    DBTYPEINFO *data_info = dbcoltypeinfo(process, col);
                    [free_tds checkForError: error];
                    int data_slength = (int)data_info->precision + (int)data_info->scale + 1;
                    char converted_decimal[data_slength];
                    dbconvert(process, coltype, data, data_len, SYBVARCHAR, (BYTE *)converted_decimal, -1);
                    [free_tds checkForError: error];
                    result = [NSDecimalNumber decimalNumberWithString: [NSString stringWithCString: &converted_decimal[0] encoding: NSUTF8StringEncoding]];
                    break;
                }
                case SYBFLT8: {
                    result = [NSNumber numberWithDouble: *(double *)data];
                    break;
                }
                case SYBREAL: {
                    result = [NSNumber numberWithFloat: *(float *)data];
                    break;
                }
                case SYBMONEY: {
                    DBMONEY *money = (DBMONEY *)data;
                    long long money_value = ((long long)money->mnyhigh << 32) | money->mnylow;
                    result = [[NSDecimalNumber decimalNumberWithString: [NSString stringWithFormat: @"%lld", money_value]] decimalNumberByMultiplyingByPowerOf10: -4];
                    break;
                }
                case SYBMONEY4: {
                    DBMONEY4 *money = (DBMONEY4 *)data;
                    
                    result = [NSNumber numberWithFloat: money->mny4 / 10000.0];
                    break;
                }
                case SYBBINARY:
                case SYBIMAGE:
                    result = [NSData dataWithBytes: data length: data_len];
                    break;
                case 36: { // SYBUNIQUE
                    char converted_unique[37];
                    dbconvert(process, coltype, data, 37, SYBVARCHAR, (BYTE *)converted_unique, -1);
                    result = [NSString stringWithCString: &converted_unique[0] encoding: NSUTF8StringEncoding];
                    break;
                }
                case SYBDATETIME4: {
                    DBDATETIME new_data;
                    dbconvert(process, coltype, data, data_len, SYBDATETIME, (BYTE *)&new_data, sizeof(new_data));            
                    data = (BYTE *)&new_data;
//                    data_len = sizeof(new_data);
                }
                case SYBDATETIME: {
                    DBDATEREC date_rec;
                    dbdatecrack(process, &date_rec, (DBDATETIME *)data);
                    
                    if (date_rec.dateyear+date_rec.datemonth+date_rec.datedmonth+date_rec.datehour+date_rec.dateminute+date_rec.datesecond != 0) {
                        struct tm time;
                        time_t seconds;
                        
                        time.tm_year = date_rec.dateyear - 1900;
                        time.tm_mon = date_rec.datemonth;
                        time.tm_mday = date_rec.datedmonth;
                        time.tm_hour = date_rec.datehour;
                        time.tm_min = date_rec.dateminute;
                        time.tm_sec = date_rec.datesecond;
                        time.tm_gmtoff = 0;
                        time.tm_zone = nil;
                        
                        seconds = mktime(&time);
                        result = [NSDate dateWithTimeIntervalSince1970: seconds + (date_rec.datemsecond / 1000)];
                    } else {
                        result = [NSNull null];
                    }
                    break;
                }
                case SYBCHAR:
                case SYBTEXT:
                    result = [[NSString alloc] initWithBytes: data length: data_len encoding: NSUTF8StringEncoding];
                    break;
                default:
                    result = [[NSString alloc] initWithBytes: data length: data_len encoding: NSUTF8StringEncoding];
                    break;
            }
        }

        return result;
    }
    
    return nil;
}


@end
