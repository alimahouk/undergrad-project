//
//  PMPPService.m
//  pmppd
//
//  Created by Ali.cpp on 12/11/15.
//
//

#import "PMPPService.h"

#import "PMPPConnection.h"
#import "PMPPIdentifier.h"
#import "PMPPUtil.h"

@implementation PMPPService

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        _connection = [PMPPConnection connection];
        _identifier = [PMPPIdentifier identifierForEntityType:PMPPEntityService];
    }
    
    return self;
}

#pragma mark -

- (NSString *)dump
{
    NSString *lastConnection = @" ";
    
    if ( _connection.timestamp )
    {
        lastConnection = [PMPPUtil dateAsString:_connection.timestamp];
    }
    
    NSString *description = [NSString stringWithFormat:@"%@\t%d\f"
                             @"%@\t%@\f"
                             @"%@\t%@\f", PMPP_DATA_ENTITY, PMPPEntityService, PMPP_DATA_CONTEXT, self.identifier, PMPP_DATA_LAST_CONNECTION, lastConnection];
    
    return description;
}

#pragma mark -
#pragma mark Class methods

+ (PMPPService *)service
{
    return [[PMPPService alloc] init];
}

#pragma mark -
#pragma mark Overrides

- (NSUInteger)hash
{
    return [_identifier hash];
}

- (BOOL)isEqual:(id)object
{
    PMPPService *temp = (PMPPService *)object;
    
    if ( temp.identifier && _identifier &&
        temp.identifier.string.length > 0 && _identifier.string.length > 0 )
    {
        if ( [_identifier isEqual:temp.identifier] )
        {
            return YES;
        }
    }
    
    return NO;
}

@end
