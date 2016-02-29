//
//  PMPPServer.m
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#import "PMPPServer.h"

#import "AppDelegate.h"
#import "GCDAsyncSocket.h"
#import "PMPPConnection.h"
#import "PMPPIdentifier.h"
#import "PMPPMessage.h"
#import "PMPPUtil.h"

@implementation PMPPServer

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        _backwardMeetingPoints = [NSMutableSet set];
        _contexts = [NSMutableArray array];
        _didConnect = NO;
        _identified = YES;
        _identifier = [PMPPIdentifier identifierForEntityType:PMPPEntityServer];
        _isBeingProbed = NO;
        _isContact = NO;
        _forwardMeetingPoints = [NSMutableSet set];
        _pings = 0;
        _presence = PMPPPresenceNone;
        _TCPConnection = [PMPPConnection connection];
        _UDPConnection = [PMPPConnection connection];
        _watchers = [NSMutableSet set];
    }
    
    return self;
}

#pragma mark -

- (NSString *)dump
{
    // Set this timestamp to a blank whitespace if it's nil, otherwise it'll print (null).
    NSString *lastConnection = @" ";
    
    if ( _UDPConnection.timestamp )
    {
        lastConnection = [PMPPUtil dateAsString:_UDPConnection.timestamp];
    }
    
    NSString *description = [NSString stringWithFormat:@"%@\t%d\f"
                             @"%@\t%@\f"
                             @"%@\t%@\f"
                             @"%@\t%@\f"
                             @"%@\t%@\f"
                             @"%@\t%d\f"
                             @"%@\t%d\f"
                             @"%@\t%d\f", PMPP_DATA_ENTITY, PMPPEntityServer, PMPP_DATA_CONTEXT, self.identifier, PMPP_DATA_ADDRESS_PRIVATE, _UDPConnection.privateAddress, PMPP_DATA_ADDRESS_PUBLIC, _UDPConnection.publicAddress, PMPP_DATA_LAST_CONNECTION, lastConnection, PMPP_DATA_PORT_PRIVATE, _UDPConnection.privatePort, PMPP_DATA_PORT_PUBLIC_TCP, _TCPConnection.publicPort, PMPP_DATA_PORT_PUBLIC_UDP, _UDPConnection.publicPort];
    
    for ( NSString *meetingPoint in _backwardMeetingPoints )
    {
        description = [description stringByAppendingFormat:@"%@\t%@\f", PMPP_DATA_BACKWARD_MEETING_POINT, meetingPoint];
    }
    
    for ( NSString *meetingPoint in _forwardMeetingPoints )
    {
        description = [description stringByAppendingFormat:@"%@\t%@\f", PMPP_DATA_FORWARD_MEETING_POINT, meetingPoint];
    }
    
    for ( NSString *context in _contexts )
    {
        description = [description stringByAppendingFormat:@"%@\t%@\f", PMPP_DATA_CONTEXT_ITEM, context];
    }
    
    for ( NSString *watcher in _watchers )
    {
        description = [description stringByAppendingFormat:@"%@\t%@\f", PMPP_DATA_WATCHER, watcher];
    }
    
    return description;
}

#pragma mark -

- (void)killSocket
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Signal end of transmission.
    _TCPConnection.socket.endOfTransmission = YES;
    
    PMPPMessage *EOT = [PMPPMessage messageOfType:PMPPServerEventEOT];
    EOT.recipientServer = self;
    
    [appDelegate.messageManager sendServerMessage:EOT];
}

- (void)resetTCPIdleTimer
{
    [self stopTCPIdleTimer];
    [self startTCPIdleTimer];
}

- (void)startTCPIdleTimer
{
    if ( !_TCPConnection.keepAlive )
    {
        [self stopTCPIdleTimer]; // Cancel possibly running timer.
        
        dispatch_async(dispatch_get_main_queue(), ^{
            TCPIdleTimer = [NSTimer scheduledTimerWithTimeInterval:TCP_IDLE_TIMEOUT
                                                            target:self
                                                          selector:@selector(killSocket)
                                                          userInfo:nil
                                                           repeats:NO];
        });
    }
}

- (void)stopTCPIdleTimer
{
    if ( TCPIdleTimer )
    {
        [TCPIdleTimer invalidate];
        
        TCPIdleTimer = nil;
    }
}

#pragma mark -
#pragma mark Class methods

+ (PMPPServer *)server
{
    return [[PMPPServer alloc] init];
}

+ (PMPPServer *)serverWithDictionary:(NSDictionary *)dict
{
    PMPPServer *server = [[PMPPServer alloc] init];
    
    for ( NSString *key in dict )
    {
        if ( [key isEqualToString:@"connectionInterface"] )
        {
            server.TCPConnection.interface = [[dict objectForKey:key] intValue];
            server.UDPConnection.interface = [[dict objectForKey:key] intValue];
        }
        else if ( [key isEqualToString:@"identifier"] && [[dict objectForKey:key] length] > 0 )
        {
            server.identifier = [dict objectForKey:key];
        }
        else if ( [key isEqualToString:@"presence"] )
        {
            server.presence = [[dict objectForKey:key] intValue];
        }
        else if ( [key isEqualToString:@"userAgent"] )
        {
            
        }
    }
    
    return server;
}

+ (PMPPServer *)serverWithIdentifier:(PMPPIdentifier *)identifier
{
    PMPPServer *server = [[PMPPServer alloc] init];
    server.identifier = identifier;
    
    return server;
}

+ (PMPPServer *)serverWithServer:(PMPPServer *)server
{
    PMPPServer *copy = [[PMPPServer alloc] init];
    copy.identifier = server.identifier;
    copy.isBeingProbed = server.isBeingProbed;
    copy.isContact = server.isContact;
    copy.presence = server.presence;
    copy.TCPConnection = server.TCPConnection;
    copy.UDPConnection = server.UDPConnection;
    
    return copy;
}

#pragma mark -
#pragma mark Overrides

- (NSString *)description
{
    return _identifier.string;
}

- (NSUInteger)hash
{
    return [_identifier hash];
}

- (BOOL)isEqual:(id)object
{
    PMPPServer *temp = (PMPPServer *)object;
    
    /*
     *  Identifier comparisons only make sense when
     *  we're using permanent identifiers, not temp ones.
     *
     *  What cases involve temp identifiers?
     *  When a server is added for the first time, we still
     *  have no idea what its real identifier is until we
     *  connect to it at least once.
     */
    if ( _identified && temp.identified )
    {
        if ( temp.identifier && self.identifier &&
            temp.identifier.string.length > 0 && self.identifier.string.length > 0 )
        {
            if ( [self.identifier isEqual:temp.identifier] ||
                [temp.UDPConnection isEqual:_UDPConnection] )
            {
                return YES;
            }
        }
    }
    else
    {
        if ( [temp.TCPConnection isEqual:_TCPConnection] )
        {
            return YES;
        }
    }
    
    return NO;
}

@end
