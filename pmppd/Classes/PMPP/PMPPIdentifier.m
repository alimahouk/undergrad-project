//
//  PMPPIdentifier.m
//  pmppd
//
//  Created by Ali.cpp on 2/2/16.
//
//

#import "PMPPIdentifier.h"

@implementation PMPPIdentifier

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        _entityType = PMPPEntityNone;
    }
    
    return self;
}

#pragma mark -
#pragma mark Class methods

+ (PMPPIdentifier *)identifier:(NSString *)identifier forEntityType:(PMPPEntityType)type
{
    PMPPIdentifier *i = [[PMPPIdentifier alloc] init];
    i.entityType = type;
    i.string = identifier;
    
    return i;
}

+ (PMPPIdentifier *)identifierForEntityType:(PMPPEntityType)type
{
    PMPPIdentifier *i = [[PMPPIdentifier alloc] init];
    i.entityType = type;
    
    return i;
}

#pragma mark -
#pragma mark Overrides

- (BOOL)isEqual:(id)object
{
    if ( object &&
        [object isKindOfClass:[PMPPIdentifier class]] )
    {
        PMPPIdentifier *temp = (PMPPIdentifier *)object;
        
        if ( _entityType == temp.entityType &&
            [_string isEqualToString:temp.string] )
        {
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)description
{
    return _string;
}

- (NSUInteger)hash
{
    return [_string hash];
}

@end
