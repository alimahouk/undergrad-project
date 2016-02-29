//
//  PMPPHistory.m
//  pmppd
//
//  Created by Ali.cpp on 12/29/15.
//
//

#import "PMPPHistory.h"

#import "PMPPIdentifier.h"
#import "PMPPUtil.h"

@implementation PMPPHistory

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        _timestamp = [NSDate date];
    }
    
    return self;
}

#pragma mark -

- (NSString *)progressTo:(NSDate *)time
{
    /*
     *  History progresses by adding the given time to the
     *  previous history.
     */
    NSString *moment = [PMPPUtil addStrings:@[_value, [PMPPUtil dateAsString:time]]];
    _timestamp = [NSDate date];
    _value = [PMPPUtil SHA1:moment];
    
    return _value;
}

#pragma mark -
#pragma mark Class methods

+ (PMPPHistory *)freshHistory:(PMPPIdentifier *)identifier
{
    NSString *blank = [PMPPUtil SHA1:@""];
    NSString *history = [NSString stringWithFormat:@"%@%@", blank, identifier];
    PMPPHistory *fresh = [[PMPPHistory alloc] init];
    fresh.value = [PMPPUtil SHA1:history];
    
    return fresh;
}

+ (PMPPHistory *)history
{
    return [[PMPPHistory alloc] init];
}

@end
