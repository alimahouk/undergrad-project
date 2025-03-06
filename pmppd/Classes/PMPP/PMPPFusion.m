//
//  PMPPFusion.m
//  pmppd
//
//  Created by Ali.cpp on 12/11/15.
//
//

#import "PMPPFusion.h"

#import "constants.h"
#import "PMPPHistory.h"
#import "PMPPIdentifier.h"
#import "PMPPMessage.h"
#import "PMPPUtil.h"

@implementation PMPPFusion

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        _identifier = _identifier = [PMPPIdentifier identifierForEntityType:PMPPEntityFusion];
        itemList = [NSArray array];
        _messageCount = 0;
        _pending = [NSMutableArray array];
        _receivedHistory = [PMPPHistory history];
        _sentHistory = [PMPPHistory history];
    }
    
    return self;
}

#pragma mark -

- (NSString *)dump
{
    NSString *description = [NSString stringWithFormat:@"%@\t%d\f"
                             @"%@\t%@\f"
                             @"%@\t%d\f"
                             @"%@\t%@\f"
                             @"%@\t%@\f"
                             @"%@\t%@\f"
                             @"%@\t%@\f", PMPP_DATA_ENTITY, PMPPEntityFusion, PMPP_DATA_CONTEXT, _identifier, PMPP_DATA_MESSAGE_COUNT, _messageCount, PMPP_DATA_RECEIVED_HISTORY, _receivedHistory.value, PMPP_DATA_RECEIVED_HISTORY_TIME, [PMPPUtil dateAsString:_receivedHistory.timestamp], PMPP_DATA_SENT_HISTORY, _sentHistory.value, PMPP_DATA_SENT_HISTORY_TIME, [PMPPUtil dateAsString:_sentHistory.timestamp]];
    
    for ( NSString *item in itemList )
    {
        description = [description stringByAppendingFormat:@"%@\t%@\f", PMPP_DATA_CONTEXT_ITEM, item];
    }
    
    for ( PMPPMessage *message in _pending )
    {
        description = [description stringByAppendingFormat:@"%@\t%@\f", PMPP_DATA_CONTEXT_ITEM, [message description]];
    }
    
    return description;
}

#pragma mark -

- (void)computeIdentifierForItems
{
    /*
     * Call this method whenever the fusion items change.
     */
    NSString *result = [PMPPUtil addStrings:itemList];
    _identifier.string = [PMPPUtil SHA1:result];
}

#pragma mark -
#pragma mark Class methods

+ (PMPPFusion *)fusion
{
    return [[PMPPFusion alloc] init];
}

+ (PMPPFusion *)fusionWithItems:(NSArray *)items
{
    PMPPFusion *fusion = [[PMPPFusion alloc] init];
    fusion.items = [items mutableCopy];
    
    return fusion;
}

#pragma mark -
#pragma mark Overrides

- (NSUInteger)hash
{
    return [_identifier hash];
}

- (BOOL)isEqual:(id)object
{
    PMPPFusion *temp = (PMPPFusion *)object;
    
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

- (NSArray *)items
{
    return itemList;
}

- (void)setItems:(NSMutableArray *)items
{
    itemList = items;
    
    [self computeIdentifierForItems];
    
    if ( !_sentHistory.value )
    {
        _sentHistory = [PMPPHistory freshHistory:_identifier];
    }
    
    if ( !_receivedHistory.value )
    {
        _receivedHistory = [PMPPHistory freshHistory:_identifier];
    }
}

@end
