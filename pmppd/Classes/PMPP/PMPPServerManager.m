//
//  PMPPServerManager.m
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#import "PMPPServerManager.h"

#import "AppDelegate.h"
#import "Constants.h"
#import "GCDAsyncSocket.h"
#import "PMPPConnection.h"
#import "PMPPIdentifier.h"
#import "PMPPMessageManager.h"
#import "PMPPConnectionManager.h"
#import "PMPPMessage.h"
#import "PMPPModelManager.h"
#import "PMPPPresenceManager.h"
#import "PMPPServer.h"
#import "PMPPUtil.h"

@implementation PMPPServerManager

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        _peers = [NSMutableSet set];
    }
    
    return self;
}

#pragma mark -

- (void)loadServers
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *identifiers = [PMPPModelManager masterServerList];
        NSMutableArray *servers = [NSMutableArray array];
        
        for ( NSString *identifier in identifiers )
        {
            PMPPServer *server = [PMPPModelManager entityForContext:identifier];
            server.didConnect = NO;
            
            if ( server )
            {
                [servers addObject:server];
            }
        }
        
        _peers = [NSMutableSet setWithArray:servers];
        
        [self serverManagerDidLoadStoredServers:servers];
    });
}

- (NSArray *)meetingPoints
{
    // This just returns 5 random servers at the moment.
    NSMutableSet *list = [NSMutableSet set];
    NSArray *allPeers = [_peers allObjects];
    
    for ( int i = 0; i < 5 && i < allPeers.count; i++ )
    {
        unsigned int index = arc4random_uniform((unsigned int)allPeers.count);
        
        [list addObject:allPeers[index]];
    }
    
    return [list allObjects];
}

- (void)resetPendingPeers
{
    
}

- (void)startPeerTimer
{
    if ( !peerConnectionTimer )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            peerConnectionTimer = [NSTimer scheduledTimerWithTimeInterval:PEER_CONNECTION_TIMER
                                                                   target:self
                                                                 selector:@selector(connectToPendingPeers)
                                                                 userInfo:nil
                                                                  repeats:YES];
        });
    }
}

- (void)stopPeerTimer
{
    [peerConnectionTimer invalidate];
    peerConnectionTimer = nil;
}

#pragma mark -

- (void)addServer:(PMPPServer *)server
{
    if ( server )
    {
        server.didConnect = NO;
        
        if ( !server.identifier )
        {
            NSLog(@"WARNING: adding a server without an identifier!");
        }
        
        [_peers addObject:server];
    }
}

- (void)connect:(PMPPServer *)server
{
    if ( server && !server.didConnect )
    {
        BOOL exists = NO;
        
        for ( PMPPServer *peer in _peers )
        {
            if ( [peer isEqual:server] )
            {
                exists = YES;
                
                break;
            }
        }
        
        if ( !exists )
        {
            /*
             *  Just some attempts at hole patching.
             *  The address is usually the same for both TCP & UDP.
             */
            if ( server.TCPConnection.privateAddress.length == 0 &&
                server.UDPConnection.privateAddress.length > 0 )
            {
                server.TCPConnection.privateAddress = server.UDPConnection.privateAddress;
            }
            
            if ( server.UDPConnection.privateAddress.length == 0 &&
                server.TCPConnection.privateAddress.length > 0 )
            {
                server.UDPConnection.privateAddress = server.TCPConnection.privateAddress;
            }
            
            if ( server.TCPConnection.publicAddress.length == 0 &&
                server.UDPConnection.publicAddress.length > 0 )
            {
                server.TCPConnection.publicAddress = server.UDPConnection.publicAddress;
            }
            
            if ( server.UDPConnection.publicAddress.length == 0 &&
                server.TCPConnection.publicAddress.length > 0 )
            {
                server.UDPConnection.publicAddress = server.TCPConnection.publicAddress;
            }
            
            AppDelegate *appDelegate = [AppDelegate sharedDelegate];
            PMPPMessage *connect = [PMPPMessage messageOfType:PMPPServerEventConnect];
            connect.contents = @{@"connectionInterface": [NSNumber numberWithInt:appDelegate.this.UDPConnection.interface],
                                 @"userAgent": USER_AGENT};
            connect.recipientServer = server;
            
            server.didConnect = YES; // Flag so it doesn't keep re-connecting.
            
            [self addServer:server];
            [appDelegate.messageManager sendServerMessage:connect];
        }
    }
}

- (void)connectToPendingPeers
{
    for ( PMPPServer *peer in _peers )
    {
        if ( peer.presence == PMPPPresenceOnline )
        {
            peer.pings++;
            
            if ( peer.pings % 5 == 0 )
            {
                [self ping:peer];
            }
        }
        else if ( peer.presence == PMPPPresenceNone )
        {
            [self connect:peer];
        }
    }
}

- (void)disconnect
{
    // This method disconnects everybody.
    for ( PMPPServer *peer in _peers )
    {
        [self disconnect:peer];
    }
}

- (void)disconnect:(PMPPServer *)server
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( server )
    {
        PMPPMessage *disconnect = [PMPPMessage messageOfType:PMPPServerEventDisconnect];
        disconnect.recipientServer = server;
        
        [appDelegate.messageManager sendServerMessage:disconnect];
    }
}

- (void)exchangeMeetingPointsWith:(PMPPServer *)server response:(BOOL)isResponse
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    NSMutableArray *list = [NSMutableArray array];
    PMPPEvent eventType = PMPPServerEventMeetingPoints;
    
    if ( isResponse )
    {
        eventType = PMPPServerEventMeetingPointsResponse;
    }
    
    for ( PMPPServer *meetingPoint in [self meetingPoints] )
    {
        NSDictionary *info = @{@"identifier": meetingPoint.identifier.string,
                               @"publicAddress": meetingPoint.UDPConnection.publicAddress,
                               @"publicPortTCP": [NSNumber numberWithInt:meetingPoint.TCPConnection.publicPort],
                               @"publicPortUDP": [NSNumber numberWithInt:meetingPoint.UDPConnection.publicPort]};
        [list addObject:info];
    }
    
    PMPPMessage *meetingPoints = [PMPPMessage messageOfType:eventType];
    meetingPoints.contents = list;
    meetingPoints.recipientServer = server;
    
    [appDelegate.messageManager sendServerMessage:meetingPoints];
}

- (void)ping:(PMPPServer *)server
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( server &&
        server.presence != PMPPPresenceOffline &&
        server.presence != PMPPPresenceConnecting )
    {
        if ( server.pings / 5 >= PING_THRESHOLD &&
            !server.isBeingProbed )
        {
            // Start probing.
            
        }
        else
        {
            NSDictionary *options = @{@"connectionInterface": [NSNumber numberWithInt:appDelegate.this.UDPConnection.interface]};
            PMPPMessage *ping = [PMPPMessage messageOfType:PMPPServerEventPing];
            ping.contents = options;
            ping.recipientServer = server;
            
            [appDelegate.messageManager sendServerMessage:ping];
        }
    }
}

- (void)reconnect
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( PMPPServer *peer in _peers )
        {
            // Sending a ping includes all the new info.
            [self ping:peer];
        }
    });
}

- (void)removeServer:(PMPPServer *)server
{
    if ( server )
    {
        [PMPPModelManager remove:server];
        [_peers removeObject:server];
    }
}

- (void)requestPublicAddressFrom:(PMPPServer *)server
{
    if ( server )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        PMPPMessage *shareRequest = [PMPPMessage messageOfType:PMPPServerEventAddressRequest];
        shareRequest.recipientServer = server;
        
        [appDelegate.messageManager sendServerMessage:shareRequest];
    }
}

- (void)updateInfoForServer:(PMPPServer *)server with:(PMPPServer *)update
{
    // Overwrite the connection's values with what the peer sent.
    server.TCPConnection.privateAddress = update.TCPConnection.privateAddress;
    server.TCPConnection.publicAddress = update.TCPConnection.publicAddress;
    server.TCPConnection.privatePort = update.TCPConnection.privatePort;
    server.TCPConnection.publicPort = update.TCPConnection.publicPort;
    server.UDPConnection.privateAddress = update.UDPConnection.privateAddress;
    server.UDPConnection.publicAddress = update.UDPConnection.publicAddress;
    server.UDPConnection.privatePort = update.UDPConnection.privatePort;
    server.UDPConnection.publicPort = update.UDPConnection.publicPort;
    server.identifier = update.identifier;
}

#pragma mark -
#pragma mark TCP connection handling

- (PMPPServer *)acceptedConnection:(PMPPConnection *)connection
{
    PMPPServer *server = [self serverForTCPConnection:connection
                                        UDPConnection:nil];
    if ( !server )
    {
        server = [PMPPServer server];
        server.identified = NO;
        server.identifier.string = [PMPPUtil uniqueIdentifier]; // Assign a temporary identifier.
        server.TCPConnection = connection;
        
        [self addServer:server];
    }
    else
    {
        NSLog(@"Overwriting connection for %@ (%@)", server.TCPConnection.publicAddress, server.TCPConnection.privateAddress);
        
        [server killSocket];
    }
    
    server.TCPConnection.socket = connection.socket;
    
    return server;
}

- (PMPPServer *)connectedTo:(PMPPConnection *)connection
{
    PMPPServer *server = [self serverForTCPConnection:connection
                                        UDPConnection:nil];
    if ( !server )
    {
        server = [PMPPServer server];
        server.identified = NO;
        server.identifier.string = [PMPPUtil uniqueIdentifier]; // Assign a temporary identifier.
        server.TCPConnection = connection;
        
        [self addServer:server];
    }
    
    return server;
}

#pragma mark -

- (void)didConnectWithServer:(PMPPServer *)server
{
    [server.UDPConnection connected];
    
    server.identified = YES;
    server.isBeingProbed = NO;
    server.pings = 0;
    server.presence = PMPPPresenceConnecting; // Still not done!
}

- (void)didDisconnectFromServer:(PMPPServer *)server
{
    if ( server.presence != PMPPPresenceOffline )
    {
        server.presence = PMPPPresenceNone;
    }
    
    // Notify delegate.
    [self serverManagerDidDisconnectFromServer:server];
}

- (void)didShakeHandsWithServer:(PMPPServer *)server
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    server.presence = PMPPPresenceOnline;
    
    if ( !appDelegate.connectionManager.sharedServerIdentifier &&
        appDelegate.this.UDPConnection.publicAddress.length == 0 )
    {
        if ( server.UDPConnection.publicAddress.length > 0 )
        {
            [self requestPublicAddressFrom:server];
        }
    }
    
    // Notify delegate.
    [self serverManagerDidConnectWithServer:server];
}

#pragma mark -

- (PMPPServer *)serverForTCPConnection:(PMPPConnection *)TCPConnection
                         UDPConnection:(PMPPConnection *)UDPConnection
{
    /*
     *  The loose flag indicates whether we care about
     *  the LAN flag when matching connections. If set
     *  to YES, the LAN flag is ignored.
     */
    for ( PMPPServer *server in _peers )
    {
        if ( TCPConnection )
        {
            if ( [server.TCPConnection isEqual:TCPConnection] )
            {
                return server;
            }
        }
        else if ( UDPConnection )
        {
            if ( [server.UDPConnection isEqual:UDPConnection] )
            {
                return server;
            }
        }
    }
    
    return nil; // Not found.
}

- (PMPPServer *)serverForIdentifier:(PMPPIdentifier *)identifier
{
    if ( identifier )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        if ( [identifier isEqual:appDelegate.this.identifier] )
        {
            return appDelegate.this;
        }
        
        for ( PMPPServer *server in _peers )
        {
            if ( [server.identifier isEqual:identifier] )
            {
                return server;
            }
        }
    }
    
    return nil; // Not found.
}

- (PMPPServer *)serverForSocket:(GCDAsyncSocket *)socket
{
    if ( socket )
    {
        for ( PMPPServer *server in _peers )
        {
            if ( [server.TCPConnection.socket isEqual:socket] )
            {
                return server;
            }
        }
    }
    
    return nil; // Not found.
}

#pragma mark -
#pragma mark Class methods

+ (NSArray *)meetingPointsForServer:(PMPPServer *)server;
{
    if ( server )
    {
        NSMutableArray *list = [NSMutableArray array];
        
        // The 1st element is always the static server.
        PMPPServer *staticServer = [PMPPServer server];
        staticServer.UDPConnection.publicAddress = STATIC_SERVER_ADDRESS;
        staticServer.UDPConnection.publicPort = STATIC_SERVER_PORT;
        
        [list addObject:staticServer];
        
        for ( NSString *identifier in server.backwardMeetingPoints )
        {
            PMPPServer *meetingPoint = [PMPPModelManager entityForContext:identifier];
            
            if ( meetingPoint )
            {
                [list addObject:meetingPoint];
            }
        }
        
        return list;
    }
    
    return nil;
}

#pragma mark -
#pragma mark PMPPServerManagerDelegate methods

- (void)serverManagerDidConnectWithServer:(PMPPServer *)server
{
    [PMPPModelManager dump:server];
    
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(serverManagerDidConnectWithServer:)] )
        {
            [_delegate serverManagerDidConnectWithServer:server];
        }
    });
}

- (void)serverManagerDidDisconnectFromServer:(PMPPServer *)server
{
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(serverManagerDidDisconnectFromServer:)] )
        {
            [_delegate serverManagerDidDisconnectFromServer:server];
        }
    });
}

- (void)serverManagerDidLoadStoredServers:(NSArray *)servers
{
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(serverManagerDidLoadStoredServers:)] )
        {
            [_delegate serverManagerDidLoadStoredServers:servers];
        }
    });
}

@end
