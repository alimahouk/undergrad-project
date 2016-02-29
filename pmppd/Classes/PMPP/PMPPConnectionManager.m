//
//  PMPPConnectionManager.m
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#import "PMPPConnectionManager.h"

#import <arpa/inet.h>
#import <ifaddrs.h>
#include <netdb.h>

#import "AppDelegate.h"
#import "GCDAsyncSocket.h"
#import "PMPPConnection.h"
#import "PMPPIdentifier.h"
#import "PMPPMessage.h"
#import "PMPPMessageManager.h"
#import "PMPPModelManager.h"
#import "PMPPPresenceManager.h"
#import "PMPPServer.h"
#import "PMPPServerManager.h"
#import "PMPPService.h"
#import "PMPPUtil.h"
#import "PortMapper.h"
#import "Reachability.h"

@implementation PMPPConnectionManager

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        /*
         *  For LAN scanning, we use a comination of Bonjour (multicasting)
         *  & traditional unicasting. The latter is a fallback in case the
         *  router or AP does not support multicasting. Bonjour is preferred
         *  since it's much faster.
         */
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        NSError *e;
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        
        isListening = NO;
        MQ = [NSMutableSet set]; // Message queue for holding messages waiting to go over TCP.
        _networkState = 0;
        networkThread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        portMappers = [NSMutableArray array];
        _previousNetworkState = 0;
        _sharedServerIdentifier = nil;
        
        LANSocketTCP = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:networkThread];
        LANSocketUDP = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:networkThread];
        serverSocketTCP = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:networkThread];
        serverSocketUDP = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:networkThread];
        serviceSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:networkThread];
        
        appDelegate.this.TCPConnection.interface = _networkState;
        appDelegate.this.TCPConnection.privateAddress = [self privateIPAddress];
        appDelegate.this.TCPConnection.socket = serverSocketTCP;
        appDelegate.this.UDPConnection.interface = _networkState;
        appDelegate.this.UDPConnection.privateAddress = appDelegate.this.TCPConnection.privateAddress;
        
        [self reachabilityDidChange:[reachability currentReachabilityStatus]];
        
        reachability.reachableBlock = ^(Reachability *reach)
        {
            // The following block should only execute if a user is logged in.
            if ( appDelegate.this.identifier.string )
            {
                NetworkStatus status = [reach currentReachabilityStatus];
                
                [self reachabilityDidChange:status];
            }
        };
        
        reachability.unreachableBlock = ^(Reachability *reach)
        {
            // The following block should only execute if a user is logged in.
            if ( appDelegate.this.identifier.string )
            {
                [self reachabilityDidChange:NotReachable];
            }
        };
        
        [reachability startNotifier];
        
        if ( ![serviceSocket acceptOnPort:PMPP_PORT_SERVICES error:&e] )
        {
            NSLog(@"Error starting services socket: %@", e);
        }
    }
    
    return self;
}

#pragma mark -
#pragma mark Reachability updates

- (void)reachabilityDidChange:(NetworkStatus)status
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    _previousNetworkState = _networkState;
    
    if ( status == ReachableViaWiFi )
    {
        NSLog(@"REACHABLE (LAN)");
        _networkState = PMPPConnectionInterfaceLAN;
    }
    else if ( status == ReachableViaWWAN )
    {
        NSLog(@"REACHABLE (Cellular)");
        _networkState = PMPPConnectionInterfaceCellular;
    }
    else if ( status == NotReachable )
    {
        NSLog(@"UNREACHABLE!");
        _networkState = PMPPConnectionInterfaceNone;
    }
    
    appDelegate.this.TCPConnection.interface = _networkState;
    appDelegate.this.UDPConnection.interface = _networkState;
    
    if ( _previousNetworkState != _networkState )
    {
        if ( isListening )
        {
            PortMapper *TCPMapper;
            PortMapper *UDPMapper;
            
            [self removeMappersForServer:appDelegate.this];
            [self TCPMapper:&TCPMapper
                  UDPMapper:&UDPMapper
              forIdentifier:appDelegate.this.identifier
                       port:appDelegate.this.TCPConnection.publicPort];
            
            if ( TCPMapper )
            {
                [self obtainPublicAddress:TCPMapper];
            }
            
            if ( UDPMapper )
            {
                [self obtainPublicAddress:UDPMapper];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [appDelegate.presenceManager currentPresenceChanged];
        });
    }
}

#pragma mark -

- (void)received:(PMPPMessage *)message from:(PMPPConnection *)connection
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    NSLog(@"Received over %@: %@", message.transport == TransportTypeTCP ? @"TCP" : @"UDP", [message asDictionary]);
    
    if ( message && message.version <= PMPP_VERSION )
    {
        if ( message.sendingService && message.sendingService.identifier )
        {
            [appDelegate.messageManager didReceiveServiceMessage:message];
        }
        else
        {
            [appDelegate.messageManager didReceiveServerMessage:message from:connection];
        }
    }
}

- (void)sendServerMessage:(PMPPMessage *)message
{
    if ( !message || !message.recipientServer )
    {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        // keepalive connections use a retained TCP connection. Nothing goes over UDP.
        if ( message.transport == TransportTypeTCP || message.recipientServer.TCPConnection.keepAlive )
        {
            if ( message.recipientServer.TCPConnection.socket &&
                message.recipientServer.TCPConnection.socket.isConnected )
            {//NSLog(@"sending %@", [message asDictionary]);
                NSMutableData *messageData = [[[message description] dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
                
                [messageData appendData:[GCDAsyncSocket CRLFData]];
                [message.recipientServer.TCPConnection.socket writeData:messageData withTimeout:-1 tag:1];
                
                if ( message.sendingService && message.sendingService.identifier )
                {
                    [appDelegate.messageManager didSendServiceMessage:message];
                }
                else
                {
                    [appDelegate.messageManager didSendServerMessage:message];
                }
                
                // EOT messages don't reset the timer.
                if ( message.type != PMPPServerEventEOT )
                {
                    [message.recipientServer resetTCPIdleTimer];
                }
            }
            else if ( message.type != PMPPServerEventEOT ) // Connect. EOTs shouldn't open a connection if one doesn't exist.
            {
                NSError *error;
                NSString *host = message.recipientServer.TCPConnection.publicAddress;
                UInt16 port = message.recipientServer.TCPConnection.publicPort;
                
                if ( !message.recipientServer.TCPConnection.socket )
                {
                    message.recipientServer.TCPConnection.socket = [self freshTCPSocket];
                }
                
                if ( message.recipientServer.TCPConnection.publicAddress.length == 0 ||
                    [message.recipientServer.TCPConnection.publicAddress isEqualToString:appDelegate.this.TCPConnection.publicAddress] )
                {
                    host = message.recipientServer.TCPConnection.privateAddress;
                    port = message.recipientServer.TCPConnection.privatePort;
                }
                
                if ( _sharedServerIdentifier )
                {
                    message.recipientServer.TCPConnection.keepAlive = YES;
                }
                else
                {
                    message.recipientServer.TCPConnection.keepAlive = NO;
                }
                
                if ( ![message.recipientServer.TCPConnection.socket connectToHost:host
                                                                           onPort:port
                                                                     viaInterface:nil
                                                                      withTimeout:NETWORK_CONNECTION_TIMEOUT
                                                                            error:&error] )
                {
                    NSLog(@"TCP error connecting to peer %@: %@", host, error);
                }
                else
                {
                    [MQ addObject:message];
                }
            }
        }
        else
        {
            GCDAsyncUdpSocket *UDPSocket = serverSocketUDP;
            NSData *messageData = [[message description] dataUsingEncoding:NSUTF8StringEncoding];
            NSString *host = message.recipientServer.UDPConnection.publicAddress;
            UInt16 port = message.recipientServer.UDPConnection.publicPort;
            
            if ( message.recipientServer.UDPConnection.publicAddress.length == 0 ||
                [message.recipientServer.UDPConnection.publicAddress isEqualToString:appDelegate.this.UDPConnection.publicAddress] )
            {
                host = message.recipientServer.UDPConnection.privateAddress;
                port = message.recipientServer.UDPConnection.privatePort;
                UDPSocket = LANSocketUDP;
            }
            
            if ( host && host.length > 0 && port != 0 )
            {
                [UDPSocket sendData:messageData
                             toHost:host
                               port:port
                        withTimeout:-1
                                tag:1];
                
                if ( message.sendingService && message.sendingService.identifier )
                {
                    [appDelegate.messageManager didSendServiceMessage:message];
                }
                else
                {
                    [appDelegate.messageManager didSendServerMessage:message];
                }
            }
            else
            {
                NSLog(@"UDP error: attempting to send to invalid address: '%@:%d'", host, port);
            }
        }
    });
}

- (void)sendServiceMessage:(PMPPMessage *)message
{
    if ( !message )
    {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
    });
}

#pragma mark -

- (void)obtainPublicAddress:(PortMapper *)mapper
{
    // Now open the port mapping (asynchronously).
    if ( [mapper open] )
    {
        // Remove any previously registered notifications.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:PortMapperChangedNotification object:mapper];
        
        // Now listen for notifications to find out when the mapping opens, fails, or changes.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(portMappingChanged:)
                                                     name:PortMapperChangedNotification
                                                   object:mapper];
    }
    else
    {
        if ( mapper.error )
        {
            // PortMapper failed - this is unlikely, but be graceful.
            NSLog(@"Error: PortMapper wouldn't start: %i", (int)mapper.error);
        }
        
        [self updateMapping:mapper];
    }
}

- (void)startListening
{
    if ( !isListening )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        NSError *error;
        PortMapper *TCPMapper;
        PortMapper *UDPMapper;
        
        isListening = YES;
        
        if ( appDelegate.this.TCPConnection.publicPort == 0 )
        {
            appDelegate.this.TCPConnection.publicPort = PMPP_PORT_SERVERS; // Reset.
        }
        
        if ( appDelegate.this.UDPConnection.publicPort == 0 )
        {
            appDelegate.this.UDPConnection.publicPort = PMPP_PORT_SERVERS;
        }
        
        [self connectionManagerDidObtainPublicTCPAddress:nil UDPAddress:nil for:appDelegate.this.identifier];
        [self TCPMapper:&TCPMapper
              UDPMapper:&UDPMapper
          forIdentifier:appDelegate.this.identifier
                   port:appDelegate.this.TCPConnection.publicPort];
        
        if ( ![serverSocketTCP acceptOnPort:appDelegate.this.TCPConnection.publicPort error:&error] )
        {
            NSLog(@"Error starting server socket: %@", error);
        }
        
        if ( ![LANSocketTCP acceptOnPort:PMPP_PORT_LAN error:&error] )
        {
            NSLog(@"Error starting LAN socket: %@", error);
        }
        
        if ( ![LANSocketUDP bindToPort:PMPP_PORT_LAN error:&error] )
        {
            NSLog(@"Error binding LAN UDP: %@", error);
        }
        else
        {
            if ( ![LANSocketUDP beginReceiving:&error] )
            {
                NSLog(@"Error receiving on LAN UDP: %@", error);
            }
        }
        
        if ( ![serverSocketUDP bindToPort:appDelegate.this.UDPConnection.publicPort error:&error] )
        {
            NSLog(@"Error binding UDP: %@", error);
        }
        else
        {
            if ( ![serverSocketUDP beginReceiving:&error] )
            {
                NSLog(@"Error receiving on UDP: %@", error);
            }
        }
        
        if ( TCPMapper )
        {
            [self obtainPublicAddress:TCPMapper];
        }
        
        if ( UDPMapper )
        {
            [self obtainPublicAddress:UDPMapper];
        }
    }
}

- (void)stopListening
{
    if ( isListening )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        isListening = NO;
        
        [appDelegate.serverManager stopPeerTimer];
        [appDelegate.serverManager disconnect];
        [serverSocketTCP setDelegate:nil];
        [serverSocketTCP disconnect];
        [serverSocketTCP setDelegate:self];
        
        [LANSocketTCP setDelegate:nil];
        [LANSocketTCP disconnect];
        [LANSocketTCP setDelegate:self];
        
        [LANSocketUDP setDelegate:nil];
        [LANSocketUDP closeAfterSending];
        [LANSocketUDP setDelegate:self];
        
        [serverSocketUDP setDelegate:nil];
        [serverSocketUDP closeAfterSending];
        [serverSocketUDP setDelegate:self];
        [self removeAllMappers];
    }
}

- (void)updateMapping:(PortMapper *)mapper
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    PMPPConnection *address = [PMPPConnection connection];
    
    if ( [mapper.identifier isEqual:appDelegate.this.identifier] ) // Local machine's mapper.
    {
        BOOL shouldDisconnect = NO;
        
        if ( ![mapper.publicAddress isEqualToString:appDelegate.this.UDPConnection.publicAddress] ||
            mapper.publicPort != appDelegate.this.UDPConnection.publicPort ) // Our IP address/port has changed.
        {
            // Disconnect everybody.
            //NSLog(@"Everybody GTFO…");
            shouldDisconnect = YES;
        }
        
        if ( shouldDisconnect )
        {
            [appDelegate.serverManager reconnect];
        }
        
        [appDelegate.serverManager startPeerTimer];
    }
    
    if ( mapper.isMapped )
    {
        address.publicAddress = mapper.publicAddress;
        address.publicPort = mapper.publicPort;
    }
    else
    {
        address.publicAddress = @"";
        address.publicPort = 0;
    }
    
    if ( [mapper.identifier isEqual:appDelegate.this.identifier] &&
        !_sharedServerIdentifier &&
        appDelegate.this.UDPConnection.publicAddress.length == 0 )
    {
        // Find someone to share an address with.
        for ( PMPPServer *peer in appDelegate.serverManager.peers )
        {
            if ( peer.presence == PMPPPresenceOnline &&
                peer.UDPConnection.publicAddress.length > 0 )
            {
                // Send the request.
                [appDelegate.serverManager requestPublicAddressFrom:peer];
                
                break;
            }
        }
    }
    
    PMPPConnection *TCPAddress = [PMPPConnection connection];
    PMPPConnection *UDPAddress = [PMPPConnection connection];
    PortMapper *complimentaryMapper;
    
    if ( mapper.mapTCP ) // Get the UDP counterpart.
    {
        [self TCPMapper:nil UDPMapper:&complimentaryMapper forIdentifier:mapper.identifier port:address.publicPort];
        
        TCPAddress = address;
        
        if ( complimentaryMapper.isMapped )
        {
            UDPAddress.publicAddress = complimentaryMapper.publicAddress;
            UDPAddress.publicPort = complimentaryMapper.publicPort;
        }
        else
        {
            UDPAddress.publicAddress = @"";
            UDPAddress.publicPort = 0;
        }
    }
    else if ( mapper.mapUDP ) // Get the TCP counterpart.
    {
        [self TCPMapper:&complimentaryMapper UDPMapper:nil forIdentifier:mapper.identifier port:address.publicPort];
        
        UDPAddress = address;
        
        if ( complimentaryMapper.isMapped )
        {
            TCPAddress.publicAddress = complimentaryMapper.publicAddress;
            TCPAddress.publicPort = complimentaryMapper.publicPort;
        }
        else
        {
            TCPAddress.publicAddress = @"";
            TCPAddress.publicPort = 0;
        }
    }
    
    [self connectionManagerDidObtainPublicTCPAddress:TCPAddress
                                          UDPAddress:UDPAddress
                                                 for:mapper.identifier];
}

- (void)updateSharedTCPAddress:(PMPPConnection *)TCPInfo
                    UDPAddress:(PMPPConnection *)UDPInfo
                          with:(PMPPServer *)server
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    BOOL shouldDisconnect = NO;
    PMPPConnection *address = [PMPPConnection connection];
    address.privateAddress = [self privateIPAddress];
    
    if ( TCPInfo && UDPInfo )
    {
        if ( _networkState != _previousNetworkState ||
            ![TCPInfo.publicAddress isEqualToString:appDelegate.this.TCPConnection.publicAddress] ||
            ![UDPInfo.publicAddress isEqualToString:appDelegate.this.UDPConnection.publicAddress] ||
            TCPInfo.publicPort != appDelegate.this.TCPConnection.publicPort ||
            UDPInfo.publicPort != appDelegate.this.UDPConnection.publicPort ) // Our IP address/port has changed.
        {
            // Disconnect everybody.
            NSLog(@"Everybody GTFO…");
            shouldDisconnect = YES;
        }
        
        _sharedServerIdentifier = server.identifier;
    }
    else
    {
        _sharedServerIdentifier = nil;
        shouldDisconnect = YES;
    }
    
    if ( shouldDisconnect )
    {
        
        [self connectionManagerDidObtainPublicTCPAddress:TCPInfo
                                              UDPAddress:UDPInfo
                                                     for:appDelegate.this.identifier];
        [appDelegate.serverManager reconnect];
    }
}

#pragma mark -

- (GCDAsyncSocket *)freshTCPSocket
{
    GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:networkThread];
    socket.endOfTransmission = YES;
    
    return socket;
}

- (NSString *)privateIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // Retrieve the current interfaces - returns 0 on success.
    success = getifaddrs(&interfaces);
    
    if ( success == 0 )
    {
        temp_addr = interfaces;
        
        while ( temp_addr != NULL )
        {
            if ( temp_addr->ifa_addr->sa_family == AF_INET )
            {
                address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                _subnetMask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    return address;
}

- (PMPPIdentifier *)identifierForPort:(uint16_t)port
{
    PMPPIdentifier *identifier;
    
    for ( PortMapper *mapper in portMappers )
    {
        if ( mapper.publicPort == port )
        {
            identifier = mapper.identifier;
            
            break;
        }
    }
    
    return identifier;
}

- (void)TCPMapper:(PortMapper **)TCPMapper
        UDPMapper:(PortMapper **)UDPMapper
    forIdentifier:(PMPPIdentifier *)identifier
             port:(uint16_t)port
{
    /*
     *  If mappers for the requested identifier don't exist,
     *  this method will create & return new copies.
     */
    PortMapper *mTCP;
    PortMapper *mUDP;
    
    for ( PortMapper *m in portMappers )
    {
        if ( [m.identifier isEqual:identifier] &&
            m.mapTCP )
        {
            mTCP = m;
            
            break;
        }
    }
    
    for ( PortMapper *m in portMappers )
    {
        if ( [m.identifier isEqual:identifier] &&
            m.mapUDP )
        {
            mUDP = m;
            
            break;
        }
    }
    
    if ( !mTCP )
    {
        mTCP = [[PortMapper alloc] initWithPort:port];
        mTCP.desiredPublicPort = port;
        mTCP.identifier = identifier;
        mTCP.mapTCP = YES;
        mTCP.mapUDP = NO;
        
        [portMappers addObject:mTCP];
    }
    
    if ( !mUDP )
    {
        mUDP = [[PortMapper alloc] initWithPort:port];
        mUDP.desiredPublicPort = port;
        mUDP.identifier = identifier;
        mUDP.mapTCP = NO;
        mUDP.mapUDP = YES;
        
        [portMappers addObject:mUDP];
    }
    
    if ( TCPMapper )
    {
        *TCPMapper = mTCP;
    }
    
    if ( UDPMapper )
    {
        *UDPMapper = mUDP;
    }
}

#pragma mark -
#pragma mark Address sharing

- (void)removeAllMappers
{
    for ( long i = portMappers.count - 1; i >= 0; i-- )
    {
        PortMapper *mapper = portMappers[i];
        
        [mapper close];
        [portMappers removeObjectAtIndex:i];
    }
}

- (void)removeMappersForServer:(PMPPServer *)server
{
    for ( int i = 0; i < portMappers.count; i++ )
    {
        PortMapper *mapper = portMappers[i];
        
        if ( [mapper.identifier isEqual:server.identifier] )
        {
            [mapper close];
            [portMappers removeObjectAtIndex:i];
            
            i--;
        }
    }
}

- (void)requestPortForServer:(PMPPServer *)server
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( !_sharedServerIdentifier &&
        appDelegate.this.UDPConnection.publicAddress.length > 0 )
    {
        PortMapper *TCPMapper;
        PortMapper *UDPMapper;
        
        [self TCPMapper:&TCPMapper UDPMapper:&UDPMapper forIdentifier:server.identifier port:appDelegate.this.TCPConnection.publicPort];
        
        if ( TCPMapper )
        {
            [self obtainPublicAddress:TCPMapper];
        }
        
        if ( UDPMapper )
        {
            [self obtainPublicAddress:UDPMapper];
        }
    }
}

#pragma mark -
#pragma mark Port mapping notifications

- (void)portMappingChanged:(NSNotification*)notification
{
    /*
     *  This is where we get notified that the mapping was created,
     *   or that no mapping exists, or that mapping failed.
     */
    PortMapper *mapper = (PortMapper *)notification.object;
    
    [self updateMapping:mapper];
    
    if ( mapper.error )
    {
        NSLog(@"Port mapper error %i", (int)mapper.error);
        
        [mapper close];
        
        // Remove any previously registered notifications.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:PortMapperChangedNotification object:mapper];
    }
    else
    {
        if ( !mapper.isMapped )
        {
            if ( _networkState != PMPPConnectionInterfaceCellular )
            {
                // Close & retry.
                long double delayInSeconds = NETWORK_PORT_MAP_DELAY;
                
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [mapper close];
                    [self obtainPublicAddress:mapper];
                });
            }
        }
    }
}

#pragma mark -
#pragma mark GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    [newSocket readDataWithTimeout:-1 tag:0]; // Wait for incoming messages.
    NSLog(@"socket:%@ didAcceptSocket:%@ peer:%@ port:%d", sock, newSocket, newSocket.connectedHost, newSocket.localPort);
    
    newSocket.endOfTransmission = YES;
    
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    PMPPConnection *newConnection = [PMPPConnection connection];
    newConnection.interface = PMPPConnectionInterfaceNone;
    newConnection.socket = newSocket;
    
    if ( newSocket.localPort == PMPP_PORT_SERVICES )
    {
        [appDelegate.serviceManager acceptedConnection:newConnection];
    }
    else
    {
        if ( newSocket.localPort == PMPP_PORT_LAN )
        {
            newConnection.publicAddress = newSocket.connectedHost;
            newConnection.publicPort = newSocket.connectedPort;
        }
        else
        {
            newConnection.publicAddress = newSocket.connectedHost;
            newConnection.publicPort = newSocket.connectedPort;
        }
        
        [appDelegate.serverManager acceptedConnection:newConnection];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    [sock readDataWithTimeout:-1 tag:0]; // Wait for incoming messages.
    NSLog(@"socket:%@ didConnectToPeer:%@ port:%d", sock, host, port);
    
    sock.endOfTransmission = NO;
    
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    PMPPConnection *newConnection = [PMPPConnection connection];
    newConnection.interface = _networkState;
    newConnection.socket = sock;
    
    if ( [PMPPServiceManager socketIsService:sock] )
    {
        NSLog(@"A service disconnected!");
    }
    else
    {
        if ( port == PMPP_PORT_LAN )
        {
            newConnection.privateAddress = host;
        }
        else
        {
            newConnection.publicAddress = host;
            newConnection.publicPort = port;
        }
        
        PMPPServer *peer = [appDelegate.serverManager connectedTo:newConnection];
        
        if ( peer )
        {
            newConnection = peer.TCPConnection;
            
            // Send any queued messages.
            NSMutableSet *toRemove = [NSMutableSet set];
            
            for ( PMPPMessage *message in MQ )
            {
                if ( [message.recipientServer.TCPConnection isEqual:newConnection] )
                {
                    [self sendServerMessage:message];
                    [toRemove addObject:message];
                }
            }
            
            // Remove sent messages.
            [MQ minusSet:toRemove];
        }
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if ( sock )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        if ( [PMPPServiceManager socketIsService:sock] ) // A service disconnected.
        {
            NSLog(@"A service disconnected!");
        }
        else
        {
            PMPPServer *peer = [appDelegate.serverManager serverForSocket:sock];
            
            if ( peer )
            {
                if ( !peer.TCPConnection.socket.endOfTransmission )
                {
                    NSLog(@"Transmission interrupted with %@ (%@)", peer.TCPConnection.publicAddress, peer.TCPConnection.privateAddress);
                    
                    [appDelegate.serverManager didDisconnectFromServer:peer];
                }
                else
                {
                    NSLog(@"Transmission ended with %@ (%@).", peer.TCPConnection.publicAddress, peer.TCPConnection.privateAddress);
                }
                
                [self removeMappersForServer:peer];
            }
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:tag]; // Wait for incoming messages.
    
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    NSString *ping = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *pingData = [NSJSONSerialization JSONObjectWithData:[ping dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableLeaves
                                                               error:nil];
    // Message is not in PMPP.
    if ( !pingData )
    {
        /*
         *  Developers can request identifiers for their apps
         *  by telnetting into the services port & sending a single
         *  command. The response is an identifier sent as plain
         *  text.
         */
        ping = [ping stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ( [ping isEqualToString:@"reqid"] )
        {
            NSMutableData *identifier = [[[PMPPUtil uniqueIdentifier] dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
            
            [identifier appendData:[GCDAsyncSocket CRLFData]];
            [sock writeData:identifier withTimeout:-1 tag:1];
            [sock disconnectAfterWriting];
        }
        else
        {
            NSLog(@"Received a non-PMPP message: %@", ping);
        }
        
        return;
    }
    
    PMPPMessage *message = [PMPPMessage messageWithDictionary:pingData];
    message.transport = TransportTypeTCP;
    
    if ( [PMPPServiceManager socketIsService:sock] )
    {
        PMPPService *service = [appDelegate.serviceManager serviceForSocket:sock];
        service.identifier = message.sendingService.identifier;
        
        if ( service )
        {
            message.sendingService = service;
            
            [self received:message from:service.connection];
        }
    }
    else
    {
        PMPPServer *peer = [appDelegate.serverManager serverForSocket:sock];
        
        if ( peer )
        {
            [self received:message from:peer.TCPConnection];
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    [sock readDataWithTimeout:-1 tag:0]; // Wait for incoming messages.
    
    NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

#pragma mark -
#pragma mark GCDAsyncUdpSocketDelegate methods

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"Sent over UDP…");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"UDP sending error: %@", error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSString *ping = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *host = nil;
    NSDictionary *pingData = [NSJSONSerialization JSONObjectWithData:[ping dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableLeaves
                                                               error:nil];
    UInt16 port = 0;
    
    // Message is not in PMPP.
    if ( !pingData )
    {
        return;
    }
    
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
    
    PMPPConnection *connection = [PMPPConnection connection];
    PMPPMessage *message = [PMPPMessage messageWithDictionary:pingData];
    message.transport = TransportTypeUDP;
    
    if ( port == PMPP_PORT_LAN )
    {
        connection.privateAddress = host;
    }
    else
    {
        connection.publicAddress = host;
        connection.publicPort = port;
    }
    
    [self received:message from:connection];
}

#pragma mark -
#pragma mark PMPPConnectionManagerDelegate methdods

- (void)connectionManagerDidObtainPublicTCPAddress:(PMPPConnection *)TCPAddress
                                        UDPAddress:(PMPPConnection *)UDPAddress
                                               for:(PMPPIdentifier *)identifier
{
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(connectionManagerDidObtainPublicTCPAddress:UDPAddress:for:)] )
        {
            [_delegate connectionManagerDidObtainPublicTCPAddress:TCPAddress
                                                       UDPAddress:UDPAddress
                                                              for:identifier];
        }
    });
}

@end
