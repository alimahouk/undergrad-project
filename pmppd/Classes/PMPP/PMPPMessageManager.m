//
//  PMPPMessageManager.m
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//  
//

#import "PMPPMessageManager.h"

#import "AppDelegate.h"
#import "Constants.h"
#import "GCDAsyncSocket.h"
#import "PMPPConnection.h"
#import "PMPPConnectionManager.h"
#import "PMPPFusion.h"
#import "PMPPHistory.h"
#import "PMPPIdentifier.h"
#import "PMPPMessage.h"
#import "PMPPModelManager.h"
#import "PMPPServer.h"
#import "PMPPServerManager.h"
#import "PMPPService.h"
#import "PMPPUtil.h"

@implementation PMPPMessageManager

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        MQ = [NSMutableSet set];
        
        // Fill MQ with all pending messages.
        for ( PMPPServer *server in appDelegate.serverManager.peers )
        {
            for ( NSString *context in server.contexts )
            {
                PMPPFusion *fusion = [PMPPModelManager entityForContext:context];
                
                [MQ addObjectsFromArray:fusion.pending];
            }
        }
    }
    
    return self;
}

#pragma mark -

- (void)flush:(PMPPServer *)server
{
    
}

- (void)purgePendingPingsForServer:(PMPPServer *)server
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableSet *toRemove = [NSMutableSet set];
        
        for ( PMPPMessage *queued in MQ )
        {
            if ( [queued.recipientServer isEqual:server] &&
                queued.type == PMPPServerEventPing )
            {
                [toRemove addObject:queued];
                
                // Don't break at this point because there might be multiple copies.
            }
        }
        
        [MQ minusSet:toRemove];
    });
}

#pragma mark -

- (void)acknowledgeDelivery:(PMPPMessage *)message
{
    if ( message )
    {
        
    }
}

- (void)sendServerMessage:(PMPPMessage *)message
{
    if ( message )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        // Now, we need to update sent history with this recipient.
        PMPPFusion *fusion = [PMPPFusion fusionWithItems:@[message.sendingServer.identifier.string, message.recipientServer.identifier.string]];
        message.identifier.string = [fusion.sentHistory progressTo:message.timestamp];
        message.receivedHistory = fusion.receivedHistory;
        message.sentHistory = fusion.sentHistory;
        
        switch ( message.type )
        {
            case PMPPServerEventConnect:
            case PMPPServerEventConnectAck:
            case PMPPServerEventEOT:
            case PMPPServerEventMeetingPoints:
            case PMPPServerEventMeetingPointsResponse:
            case PMPPServerEventMessage:
            case PMPPServerEventPublicKey:
            case PMPPServerEventSharedKey:
            case PMPPServiceEventMessage:
                message.transport = TransportTypeTCP;
                break;
                
            default:
                message.transport = TransportTypeUDP;
                break;
        }
        
        /*
         *  Not all sent messages are part of relevant contexts,
         *  as is the case in LAN scans, for example.
         */
        if ( message.recipientServer.identified )
        {
            [PMPPModelManager dump:fusion];
        }
        
        /*
         *  TCP messages, UDP acks, & disconnect messages don't
         *  need acknowledgements.
         */
        if ( message.transport == TransportTypeUDP &&
            !message.ackIdentifier &&
            message.type != PMPPServerEventDisconnect )
        {
            [MQ addObject:message]; // Add it to the queue.
        }
        
        [appDelegate.connectionManager sendServerMessage:message];
    }
}

- (void)sendServiceMessage:(PMPPMessage *)message
{
    if ( message )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        message.transport = TransportTypeTCP;
        
        [appDelegate.connectionManager sendServiceMessage:message];
    }
}

#pragma mark -

- (void)didDeliverServerMessage:(PMPPMessage *)message
{
    // Notify delegate.
    [self messageManagerDidDeliverMessage:message];
}

- (void)didDeliverServiceMessage:(PMPPMessage *)message
{
    
}

- (void)didReceiveServerMessage:(PMPPMessage *)message from:(PMPPConnection *)connection
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    /*
     *  ============
     *  | PMPP 1.0 |
     *  ============
     */
    if ( [message.recipientServer isEqual:appDelegate.this] )
    {
        PMPPServer *sender = [appDelegate.serverManager serverForTCPConnection:connection
                                                                 UDPConnection:connection];
        /*
         *  TODO LIST
         *  --
         *  PMPPServerEventDeliveredToServer,
         *  PMPPServerEventDeliveredToServerAck,
         *  PMPPServerEventDeliveredToService,
         *  PMPPServerEventDeliveredToServiceAck,
         *  PMPPServerEventAddressHandoff,
         *  PMPPServerEventPublicKey,
         *  PMPPServerEventSharedKey,
         */
        if ( message.type == PMPPServerEventConnect )
        {
            NSDictionary *options = [message contentsAsDictionary];
            
            if ( options )
            {
                if ( !sender )
                {
                    sender = [PMPPServer serverWithDictionary:options];
                }
                
                sender.TCPConnection.socket = connection.socket;
                
                [self purgePendingPingsForServer:sender];
                [appDelegate.serverManager updateInfoForServer:sender with:message.sendingServer];
                [appDelegate.serverManager didConnectWithServer:sender];
                
                // Send back an ack. Since it's over TCP, no need for an ack identifier.
                PMPPMessage *ack = [PMPPMessage messageOfType:PMPPServerEventConnectAck];
                ack.contents = @{@"connectionInterface": [NSNumber numberWithInt:appDelegate.this.UDPConnection.interface],
                                 @"userAgent": USER_AGENT};
                ack.recipientServer = sender;
                
                [self sendServerMessage:ack];
            }
        }
        else if ( message.type == PMPPServerEventConnectAck )
        {
            NSDictionary *options = [message contentsAsDictionary];
            
            if ( options )
            {
                if ( !sender )
                {
                    sender = [PMPPServer serverWithDictionary:options];
                }
                
                [self purgePendingPingsForServer:sender];
                [appDelegate.serverManager updateInfoForServer:sender with:message.sendingServer];
                [appDelegate.serverManager didConnectWithServer:sender];
                [appDelegate.serverManager exchangeMeetingPointsWith:sender response:NO];
            }
        }
        else
        {
            if ( ![message.recipientServer isEqual:appDelegate.this] )
            {
                PMPPFusion *fusion;
                
                if ( sender )
                {
                    fusion = [PMPPFusion fusionWithItems:@[sender.identifier, message.recipientServer.identifier]];
                }
                else
                {
                    fusion = [PMPPFusion fusionWithItems:@[message.sendingServer.identifier, message.recipientServer.identifier]];
                }
                
                NSLog(@"Received message for offline delivery…");
                
                [fusion.pending addObject:message];
                [PMPPModelManager dump:fusion];
            }
            
            // If this is an ack, remove the original message.
            if ( message.ackIdentifier )
            {
                NSMutableSet *toRemove = [NSMutableSet set];
                
                for ( PMPPMessage *queued in MQ )
                {
                    if ( [queued.identifier.string isEqualToString:message.ackIdentifier] )
                    {
                        [toRemove addObject:queued];
                        
                        // Don't break at this point because there might be multiple copies.
                    }
                }
                
                [MQ minusSet:toRemove];
            }
            
            switch ( message.type )
            {
                case PMPPServerEventAddressRequest:
                {
                    if ( sender )
                    {
                        [appDelegate.connectionManager requestPortForServer:sender];
                    }
                    
                    break;
                }
                    
                case PMPPServerEventAddressResponse:
                {
                    if ( sender )
                    {
                        NSDictionary *options = [message contentsAsDictionary];
                        
                        if ( options )
                        {
                            PMPPConnection *TCPInfo = [PMPPConnection connection];
                            TCPInfo.publicAddress = sender.TCPConnection.publicAddress;
                            TCPInfo.publicPort = [[options objectForKey:@"portTCP"] intValue];
                            
                            PMPPConnection *UDPInfo = [PMPPConnection connection];
                            UDPInfo.publicAddress = sender.UDPConnection.publicAddress;
                            UDPInfo.publicPort = [[options objectForKey:@"portUDP"] intValue];
                            
                            [appDelegate.connectionManager updateSharedTCPAddress:TCPInfo
                                                                       UDPAddress:UDPInfo
                                                                             with:sender];
                        }
                    }
                    
                    break;
                }
                    
                case PMPPServerEventDisconnect:
                {
                    if ( sender )
                    {
                        sender.presence = PMPPPresenceOffline;
                        
                        [appDelegate.serverManager didDisconnectFromServer:sender];
                    }
                    
                    break;
                }
                    
                case PMPPServerEventEOT:
                {
                    if ( sender )
                    {
                        sender.TCPConnection.socket.endOfTransmission = YES;
                        
                        [sender.TCPConnection.socket disconnectAfterWriting];
                    }
                    
                    break;
                }
                    
                case PMPPServerEventMeetingPoints:
                {
                    if ( sender )
                    {
                        [appDelegate.serverManager exchangeMeetingPointsWith:sender response:YES];
                        [appDelegate.serverManager didShakeHandsWithServer:sender];
                    }
                    
                    break;
                }
                    
                case PMPPServerEventMeetingPointsResponse:
                {
                    if ( sender )
                    {
                        NSDictionary *options = [message contentsAsDictionary];
                        
                        if ( options )
                        {
                            [appDelegate.serverManager didShakeHandsWithServer:sender];
                        }
                    }
                    
                    break;
                }
                    
                case PMPPServerEventMessage:
                {
                    if ( sender )
                    {
                        
                    }
                    
                    break;
                }
                    
                case PMPPServerEventPing:
                {
                    NSDictionary *options = [message contentsAsDictionary];
                    
                    if ( options && [options objectForKey:@"connectionInterface"] )
                    {
                        sender.TCPConnection.interface = [[options objectForKey:@"connectionInterface"] intValue];
                        sender.UDPConnection.interface = [[options objectForKey:@"connectionInterface"] intValue];
                    }
                    
                    if ( sender )
                    {
                        sender.pings = 0;
                        
                        if ( sender.presence == PMPPPresenceOnline )
                        {
                            PMPPMessage *ack = [PMPPMessage messageOfType:PMPPServerEventPingAck];
                            ack.ackIdentifier = message.identifier.string;
                            ack.recipientServer = sender;
                            
                            [appDelegate.messageManager sendServerMessage:ack];
                        }
                        else
                        {
                            [appDelegate.serverManager connect:sender];
                        }
                    }
                    
                    break;
                }
                    
                case PMPPServerEventPingAck:
                {
                    if ( sender )
                    {
                        sender.pings = 0;
                    }
                    
                    break;
                }
                    
                case PMPPServerEventProbe:
                {
                    if ( sender )
                    {
                        
                    }
                    
                    break;
                }
                    
                case PMPPServerEventProbeTarget:
                {
                    if ( sender )
                    {
                        
                    }
                    
                    break;
                }
                    
                default:
                {
                    
                    break;
                }
            }
        }
    }
    else // Message intended for someone sharing our address.
    {
        PMPPServer *recipient = [appDelegate.serverManager serverForIdentifier:message.recipientServer.identifier];
        
        if ( !recipient ) // This happens when there's no recipient identifier, usually during initial connection.
        {
            // Search mappers to find matching server.
            if ( message.recipientServer.TCPConnection.publicPort != 0 )
            {
                PMPPIdentifier *identifier = [appDelegate.connectionManager identifierForPort:message.recipientServer.TCPConnection.publicPort];
                recipient = [appDelegate.serverManager serverForIdentifier:identifier];
            }
        }
        
        if ( !recipient )
        {
            if ( message.recipientServer.UDPConnection.publicPort != 0 )
            {
                PMPPIdentifier *identifier = [appDelegate.connectionManager identifierForPort:message.recipientServer.UDPConnection.publicPort];
                recipient = [appDelegate.serverManager serverForIdentifier:identifier];
            }
        }
        
        if ( recipient )
        {
            message.recipientServer = recipient;
            
            [self sendServerMessage:message];
        }
    }
}

- (void)didReceiveServiceMessage:(PMPPMessage *)message
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    switch ( message.type)
    {
        case PMPPServiceEventMessage:
        {
            if ( [message.sendingServer isEqual:appDelegate.this] )
            {
                [self sendServerMessage:message];
            }
            else
            {
                PMPPMessage *receipt = [PMPPMessage messageOfType:PMPPServerEventDeliveredToServer];
                receipt.contents = message.identifier.string;
                receipt.recipientServer = message.sendingServer;
                
                [self sendServerMessage:receipt];
            }
            
            break;
        }
            
        default:
            break;
    }
    
    // Notify delegate.
    [self messageManagerDidReceiveMessage:message];
}

- (void)didSendServerMessage:(PMPPMessage *)message
{
    
}

- (void)didSendServiceMessage:(PMPPMessage *)message
{
    // Notify delegate.
    [self messageManagerDidSendMessage:message];
}

#pragma mark -
#pragma mark PMserverManagerDelegate methods

- (void)messageManagerDidDeliverMessage:(PMPPMessage *)message
{
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(messageManagerDidDeliverMessage:)] )
        {
            [_delegate messageManagerDidDeliverMessage:message];
        }
    });
}

- (void)messageManagerDidReceiveMessage:(PMPPMessage *)message
{
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(messageManagerDidReceiveMessage:)] )
        {
            [_delegate messageManagerDidReceiveMessage:message];
        }
    });
}

- (void)messageManagerDidSendMessage:(PMPPMessage *)message
{
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(messageManagerDidSendMessage:)] )
        {
            [_delegate messageManagerDidSendMessage:message];
        }
    });
}

@end
