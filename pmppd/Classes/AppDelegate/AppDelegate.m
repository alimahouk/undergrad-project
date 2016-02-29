//
//  AppDelegate.m
//  pmppd
//
//  Created by Ali.cpp on 12/8/15.
//
//

#import "AppDelegate.h"

#import "GCDAsyncSocket.h"
#import "PMPPConnection.h"
#import "PMPPIdentifier.h"
#import "PMPPMessage.h"
#import "PMPPModelManager.h"
#import "PMPPServer.h"
#import "PMPPService.h"
#import "PMPPUtil.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _session = [PMPPUtil MD5:[PMPPUtil dateAsString:[NSDate date]]];
    _this = [PMPPServer server];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    _dataDirectory = [[paths firstObject] stringByAppendingFormat:@"/%@", PMPPD_DIR];
    
    // Read current server identifier from NSUserDefaults.
    _this.identifier.string = [[NSUserDefaults standardUserDefaults] objectForKey:@"PMPPIdentifier"];
    
    // If this is the 1st run, we need to do some preparation.
    if ( !_this.identifier )
    {
        [self firstRun];
    }
    else
    {
        PMPPServer *cache = (PMPPServer *)[PMPPModelManager entityForContext:_this.identifier.string];
        
        if ( !cache )
        {
            [self firstRun];
        }
        else
        {
            _this = cache;
        }
    }
    
    NSLog(@"Identifier: %@", _this.identifier);
    
    // Init sequence.
    /*1*/_connectionManager = [[PMPPConnectionManager alloc] init];
    _connectionManager.delegate = self;
    
    /*2*/_serverManager = [[PMPPServerManager alloc] init];
    _serverManager.delegate = self;
    
    /*3*/_messageManager = [[PMPPMessageManager alloc] init];
    _messageManager.delegate = self;
    
    /*4*/_presenceManager = [[PMPPPresenceManager alloc] init];
    _presenceManager.delegate = self;
    
    /*5*/_serviceManager = [[PMPPServiceManager alloc] init];
    _serviceManager.delegate = self;
    
    [_serverManager loadServers];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [PMPPModelManager dump:_this];
    
    if ( _connectionManager )
    {
        [_connectionManager stopListening];
    }
}

#pragma mark -

- (BOOL)firstRun
{
    NSError *e;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ( ![fileManager createDirectoryAtPath:_dataDirectory withIntermediateDirectories:YES attributes:nil error:&e] )
    {
        NSLog(@"Error creating pmppd data directory: %@", e);
        
        return NO;
    }
    
    _this.TCPConnection.privatePort = PMPP_PORT_LAN;
    _this.TCPConnection.publicPort = PMPP_PORT_SERVERS;
    _this.UDPConnection.privatePort = PMPP_PORT_LAN;
    _this.UDPConnection.publicPort = PMPP_PORT_SERVERS;
    
    if ( !_this.identifier )
    {
        _this.identifier.string = [PMPPUtil uniqueIdentifier]; // Generate an identifier for this server.
    }
    
    [PMPPModelManager dump:_this];
    [userDefaults setObject:_this.identifier forKey:@"PMPPIdentifier"];
    [userDefaults synchronize];
    
    return YES;
}

#pragma mark -
#pragma mark Class methods

+ (AppDelegate *)sharedDelegate
{
    return (AppDelegate *)[[NSApplication sharedApplication] delegate];
}

#pragma mark -
#pragma mark PMPPConnectionManagerDelegate methdods

- (void)connectionManagerDidObtainPublicTCPAddress:(PMPPConnection *)TCPAddress
                                        UDPAddress:(PMPPConnection *)UDPAddress
                                               for:(PMPPIdentifier *)identifier
{
    if ( [identifier isEqual:_this.identifier] )
    {
        NSString *privateAddress = [_connectionManager privateIPAddress];
        
        if ( privateAddress && privateAddress.length > 0 )
        {
            _this.TCPConnection.privateAddress = privateAddress;
            _this.UDPConnection.privateAddress = privateAddress;
            
            NSLog(@"private address: %@:%d", _this.TCPConnection.privateAddress, _this.TCPConnection.privatePort);
            [privateAddressLabel setStringValue:[NSString stringWithFormat:@"%@:%d", _this.TCPConnection.privateAddress, _this.TCPConnection.privatePort]];
            [subnetMaskLabel setStringValue:_connectionManager.subnetMask];
        }
        else
        {
            _this.TCPConnection.privateAddress = @"";
            _this.UDPConnection.privateAddress = @"";
            
            NSLog(@"no private address!");
            [privateAddressLabel setStringValue:@"…"];
            [subnetMaskLabel setStringValue:@"…"];
        }
        
        if ( TCPAddress && TCPAddress.publicAddress.length > 0 )
        {
            _this.TCPConnection.publicAddress = TCPAddress.publicAddress;
            _this.TCPConnection.publicPort = TCPAddress.publicPort;
            
            NSLog(@"public TCP address: %@:%d", _this.TCPConnection.publicAddress, _this.TCPConnection.publicPort);
            [publicTCPAddressLabel setStringValue:[NSString stringWithFormat:@"%@:%d", _this.TCPConnection.publicAddress, _this.TCPConnection.publicPort]];
        }
        else
        {
            _this.TCPConnection.publicAddress = @"";
            _this.TCPConnection.publicPort = 0;
            
            NSLog(@"no public TCP address!");
            [publicTCPAddressLabel setStringValue:@"…"];
        }
        
        if ( UDPAddress && UDPAddress.publicAddress.length > 0 )
        {
            _this.UDPConnection.publicAddress = UDPAddress.publicAddress;
            _this.UDPConnection.publicPort = UDPAddress.publicPort;
            
            NSLog(@"public UDP address: %@:%d", _this.UDPConnection.publicAddress, _this.UDPConnection.publicPort);
            [publicUDPAddressLabel setStringValue:[NSString stringWithFormat:@"%@:%d", _this.UDPConnection.publicAddress, _this.UDPConnection.publicPort]];
        }
        else
        {
            _this.UDPConnection.publicAddress = @"";
            _this.UDPConnection.publicPort = 0;
            
            NSLog(@"no public UDP address!");
            [publicUDPAddressLabel setStringValue:@"…"];
        }
        
        [PMPPModelManager dump:_this];
    }
    else // Sharing our address with a peer.
    {
        PMPPMessage *addressResponse = [PMPPMessage messageOfType:PMPPServerEventAddressResponse];
        addressResponse.contents = @{@"portTCP": [NSNumber numberWithInt:TCPAddress.publicPort],
                                     @"portUDP": [NSNumber numberWithInt:UDPAddress.publicPort]};
        addressResponse.recipientServer = [_serverManager serverForIdentifier:identifier];
        
        [_messageManager sendServerMessage:addressResponse];
    }
}

#pragma mark -
#pragma mark PMPPMessageManagerDelegate methods

- (void)messageManagerDidDeliverMessage:(PMPPMessage *)message
{
    
}

- (void)messageManagerDidReceiveMessage:(PMPPMessage *)message
{
    
}

- (void)messageManagerDidSendMessage:(PMPPMessage *)message
{
    
}

#pragma mark -
#pragma mark PMPPPresenceManagerDelegate methods

- (void)currentPresenceDidChange
{
    NSString *networkStatus = @"";
    
    if ( _connectionManager.networkState == PMPPConnectionInterfaceCellular )
    {
        networkStateLabel.textColor = [NSColor grayColor];
        networkStatus = @"Connected to cellular";
    }
    else if ( _connectionManager.networkState == PMPPConnectionInterfaceLAN )
    {
        networkStateLabel.textColor = [NSColor greenColor];
        networkStatus = @"Connected to LAN";
    }
    else
    {
        networkStateLabel.textColor = [NSColor redColor];
        networkStatus = @"Disconnected";
    }
    
    [networkStateLabel setStringValue:networkStatus];
}

- (void)presenceDidChangeForServer:(PMPPServer *)server
{
    
}

#pragma mark -
#pragma mark PMPPServerManagerDelegate methods

- (void)serverManagerDidConnectWithServer:(PMPPServer *)server
{
    
}

- (void)serverManagerDidDisconnectFromServer:(PMPPServer *)server
{
    
}

- (void)serverManagerDidLoadStoredServers:(NSArray *)servers
{
    NSLog(@"Loaded server list: %@", servers);
    
    [_connectionManager startListening];
    
    if ( servers.count > 0 )
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for ( PMPPServer *server in servers )
            {
                [_serverManager connect:server];
            }
        });
    }
}

#pragma mark -
#pragma mark PMPPServiceManagerDelegate methods

- (void)serviceManagerDidRegisterService:(PMPPService *)service
{
    
}

- (void)serviceManagerFailedToRegisterService:(PMPPService *)service
{
    NSLog(@"Failed to register service: %@", service.identifier);
}

#pragma mark -
#pragma mark Tests

- (IBAction)addAddress:(id)sender
{
    /*PMPPMessage *message = [PMPPMessage messageOfType:PMPPServiceEventAddHost];
    message.contents = @{@"host": @"192.168.0.151",
                         @"port": @"5222"};
    
    [self send:message];*/
    
    NSString *address = textView.string;
    
    if ( address.length == 0 )
    {
        address = @"192.168.0.151:6221";
    }
    
    if ( address.length > 0 )
    {
        NSArray *components = [address componentsSeparatedByString:@":"];
        
        if ( components.count == 2 )
        {
            PMPPServer *server = [PMPPServer server];
            server.identified = NO;
            server.identifier.string = [PMPPUtil uniqueIdentifier];
            server.TCPConnection.privateAddress = components[0];
            server.TCPConnection.privatePort = [components[1] intValue];
            server.UDPConnection.privateAddress = components[0];
            server.UDPConnection.privatePort = [components[1] intValue];
            
            [_serverManager connect:server];
        }
    }
    else
    {
        [textView becomeFirstResponder];
    }
}

- (IBAction)generateIdentifier:(id)sender
{
    identifierField.stringValue = [PMPPUtil uniqueIdentifier];
}

- (IBAction)registerService:(id)sender
{
    NSString *serviceIdentifier = identifierField.stringValue;
    
    if ( !testSocket )
    {
        testSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    if ( serviceIdentifier.length > 0 )
    {
        if ( !testSocket.isConnected )
        {
            [testSocket connectToHost:@"localhost"
                               onPort:PMPP_PORT_SERVICES
                         viaInterface:nil
                          withTimeout:NETWORK_CONNECTION_TIMEOUT
                                error:nil];
        }
    }
    else
    {
        [identifierField becomeFirstResponder];
    }
}

- (IBAction)sendMessage:(id)sender
{
    NSString *serviceIdentifier = identifierField.stringValue;
    NSString *text = textView.string;
    
    if ( text.length > 0 && serviceIdentifier.length > 0 )
    {
        for ( PMPPServer *peer in _serverManager.peers )
        {
            PMPPMessage *message = [PMPPMessage messageOfType:PMPPServiceEventMessage];
            message.contents = text;
            message.recipientServer = peer;
            
            [self send:message];
            
            textView.string = @"";
        }
    }
    else
    {
        [identifierField becomeFirstResponder];
    }
}

- (void)send:(PMPPMessage *)message
{
    NSString *serviceIdentifier = identifierField.stringValue;
    
    if ( serviceIdentifier.length > 0 )
    {
        message.sendingService = [PMPPService service];
        message.sendingService.identifier.string = serviceIdentifier;
        NSMutableData *messageData = [[[message description] dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
        
        [messageData appendData:[GCDAsyncSocket CRLFData]];
        [testSocket writeData:messageData withTimeout:-1 tag:1];
    }
    else
    {
        [identifierField becomeFirstResponder];
    }
}

#pragma mark -

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    [sock readDataWithTimeout:-1 tag:0]; // Wait for incoming messages.
    NSLog(@"Service did connect to localhost");
    
    PMPPMessage *message = [PMPPMessage messageOfType:PMPPServiceEventRegister];
    
    [self send:message];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:tag]; // Wait for incoming messages.
    
    NSString *ping = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *pingData = [NSJSONSerialization JSONObjectWithData:[ping dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableLeaves
                                                               error:nil];
    NSLog(@"A service sent: %@", pingData);
}

@end
