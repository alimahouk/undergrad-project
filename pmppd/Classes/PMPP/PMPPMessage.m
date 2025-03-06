//
//  PMPPMessage.m
//  Pingamate
//
//  Created by Ali.cpp on 10/2/15.
//  Copyright © 2015 Pingamate. All rights reserved.
//

#import "PMPPMessage.h"

#import "AppDelegate.h"
#import "GCDAsyncSocket.h"
#import "PMPPConnection.h"
#import "PMPPHistory.h"
#import "PMPPIdentifier.h"
#import "PMPPServer.h"
#import "PMPPService.h"
#import "PMPPUtil.h"

@implementation PMPPMessage

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        _encrypted = NO;
        _identifier = [PMPPIdentifier identifierForEntityType:PMPPEntityMessage];
        _timestamp = [NSDate date];
        _transport = TransportTypeUDP;
        _version = PMPP_VERSION;
    }
    
    return self;
}

#pragma mark -

- (NSDictionary *)asDictionary
{
    NSString *messageContainer = @"";
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithObject:_session
                                                                     forKey:@"session"];
    if ( _sendingServer )
    {
        if ( _sendingServer.identifier.string )
        {
            [header setObject:_sendingServer.identifier.string forKey:@"sendingServerIdentifier"];
        }
        
        if ( _sendingServer.TCPConnection.privateAddress &&
            _sendingServer.TCPConnection.privateAddress.length > 0 )
        {
            [header setObject:_sendingServer.TCPConnection.privateAddress forKey:@"sendingServerPrivateAddress"];
        }
        
        if ( _sendingServer.TCPConnection.privatePort > 0 )
        {
            [header setObject:[NSString stringWithFormat:@"%d", _sendingServer.TCPConnection.privatePort] forKey:@"sendingServerPrivatePort"];
        }
        
        if ( _sendingServer.TCPConnection.publicAddress &&
            _sendingServer.TCPConnection.publicAddress.length > 0 )
        {
            [header setObject:_sendingServer.TCPConnection.publicAddress forKey:@"sendingServerPublicAddress"];
        }
        
        if ( _sendingServer.TCPConnection.publicPort > 0 )
        {
            [header setObject:[NSString stringWithFormat:@"%d", _sendingServer.TCPConnection.publicPort] forKey:@"sendingServerPublicPortTCP"];
        }
        
        if ( _sendingServer.UDPConnection.publicAddress &&
            _sendingServer.UDPConnection.publicAddress.length > 0 &&
            _sendingServer.UDPConnection.publicPort > 0)
        {
            [header setObject:[NSString stringWithFormat:@"%d", _sendingServer.UDPConnection.publicPort] forKey:@"sendingServerPublicPortUDP"];
        }
    }
    
    if ( _recipientServer )
    {
        if ( _recipientServer.identifier.string )
        {
            [header setObject:_recipientServer.identifier.string forKey:@"recipientServerIdentifier"];
        }
        
        if ( _recipientServer.TCPConnection.privateAddress &&
            _recipientServer.TCPConnection.privateAddress.length > 0 )
        {
            [header setObject:_recipientServer.TCPConnection.privateAddress forKey:@"recipientServerPrivateAddress"];
        }
        
        if ( _recipientServer.TCPConnection.privatePort > 0 )
        {
            [header setObject:[NSString stringWithFormat:@"%d", _recipientServer.TCPConnection.privatePort] forKey:@"recipientServerPrivatePort"];
        }
        
        if ( _recipientServer.TCPConnection.publicAddress &&
            _recipientServer.TCPConnection.publicAddress.length > 0 )
        {
            [header setObject:_recipientServer.TCPConnection.publicAddress forKey:@"recipientServerPublicAddress"];
        }
        
        if ( _recipientServer.TCPConnection.publicPort > 0 )
        {
            [header setObject:[NSString stringWithFormat:@"%d", _recipientServer.TCPConnection.publicPort] forKey:@"recipientServerPublicPortTCP"];
        }
        
        if ( _recipientServer.UDPConnection.publicAddress &&
            _recipientServer.UDPConnection.publicAddress.length > 0 &&
            _recipientServer.UDPConnection.publicPort > 0) // No need to re-include the public address with the UDP port.
        {
            [header setObject:[NSNumber numberWithInt:_recipientServer.UDPConnection.publicPort] forKey:@"recipientServerPublicPortUDP"];
        }
        
        if ( _sentHistory && _sentHistory.value )
        {
            [header setObject:_sentHistory.value forKey:@"sentHistory"];
            [header setObject:[PMPPUtil dateAsString:_sentHistory.timestamp] forKey:@"sentHistoryTime"];
        }
        
        if ( _receivedHistory && _receivedHistory.value )
        {
            [header setObject:_receivedHistory.value forKey:@"receivedHistory"];
            [header setObject:[PMPPUtil dateAsString:_receivedHistory.timestamp] forKey:@"receivedHistoryTime"];
        }
    }
    
    if ( _sendingService )
    {
        if ( _sendingService.identifier.string )
        {
            [header setObject:_sendingService.identifier.string forKey:@"sendingServiceIdentifier"];
        }
    }
    
    if ( _recipientService )
    {
        if ( _recipientService.identifier.string )
        {
            [header setObject:_recipientService.identifier.string forKey:@"recipientServiceIdentifier"];
        }
    }
    
    if ( _ackIdentifier )
    {
        [header setObject:_ackIdentifier forKey:@"ack"];
    }
    
    if ( _identifier.string )
    {
        [header setObject:_identifier.string forKey:@"identifier"];
    }
    
    if ( _contents )
    {
        if ( [_contents isKindOfClass:[NSDictionary class]] ||
             [_contents isKindOfClass:[NSArray class]])
        {
            NSData *JSONData = [NSJSONSerialization dataWithJSONObject:_contents options:kNilOptions error:nil];
            messageContainer = [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
            
            if ( !messageContainer )
            {
                messageContainer = @"";
            }
        }
        else
        {
            messageContainer = [NSString stringWithFormat:@"%@", _contents];
        }
    }
    
    NSDictionary *dict = @{@"event": [NSNumber numberWithInt:_type],
                           @"contents": messageContainer,
                           @"PM": header,
                           @"timestamp": [PMPPUtil dateAsString:_timestamp],
                           @"version": [NSNumber numberWithFloat:_version]};
    return dict;
}

- (NSDictionary *)contentsAsDictionary
{
    if ( _contents && [_contents isKindOfClass:[NSString class]] )
    {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[_contents dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableLeaves
                                                               error:nil];
        return dict;
    }
    
    return nil;
}

#pragma mark -
#pragma mark Class methods

+ (PMPPMessage *)messageOfType:(PMPPEvent)type
{
    // Returns a new message with the current user set as the sender.
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    PMPPMessage *message = [[PMPPMessage alloc] init];
    message.sendingServer = appDelegate.this;
    message.session = appDelegate.session;
    message.type = type;
    
    return message;
}

+ (PMPPMessage *)messageWithDictionary:(NSDictionary *)dict
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    PMPPMessage *message = [[PMPPMessage alloc] init];
    message.receivedHistory = [PMPPHistory history];
    message.recipientServer = [PMPPServer server];
    message.sentHistory = [PMPPHistory history];
    message.sendingServer = [PMPPServer server];
    
    if ( dict && [dict objectForKey:@"PM"] )
    {
        for ( NSString *key in dict.allKeys )
        {
            if ( [key isEqualToString:@"PM"] )
            {
                NSDictionary *header = [dict objectForKey:key];
                
                for ( NSString *identificationKey in header.allKeys )
                {
                    if ( [identificationKey isEqualToString:@"identifier"] )
                    {
                        message.identifier.string = [header objectForKey:identificationKey];
                    }
                    else if ( [identificationKey isEqualToString:@"ack"] )
                    {
                        message.ackIdentifier = [header objectForKey:identificationKey];
                    }
                    else if ( [identificationKey isEqualToString:@"sendingServerIdentifier"] )
                    {
                        message.sendingServer.identifier.string = [header objectForKey:identificationKey];
                    }
                    else if ( [identificationKey isEqualToString:@"sendingServerPrivateAddress"] )
                    {
                        message.sendingServer.TCPConnection.privateAddress = [header objectForKey:identificationKey];
                        message.sendingServer.UDPConnection.privateAddress = [header objectForKey:identificationKey];
                    }
                    else if ( [identificationKey isEqualToString:@"sendingServerPrivatePort"] )
                    {
                        message.sendingServer.TCPConnection.privatePort = [[header objectForKey:identificationKey] intValue];
                        message.sendingServer.UDPConnection.privatePort = [[header objectForKey:identificationKey] intValue];
                    }
                    else if ( [identificationKey isEqualToString:@"sendingServerPublicAddress"] )
                    {
                        message.sendingServer.TCPConnection.publicAddress = [header objectForKey:identificationKey];
                        message.sendingServer.UDPConnection.publicAddress = [header objectForKey:identificationKey];
                    }
                    else if ( [identificationKey isEqualToString:@"sendingServerPublicPortTCP"] )
                    {
                        message.sendingServer.TCPConnection.publicPort = [[header objectForKey:identificationKey] intValue];
                    }
                    else if ( [identificationKey isEqualToString:@"sendingServerPublicPortUDP"] )
                    {
                        message.sendingServer.UDPConnection.publicPort = [[header objectForKey:identificationKey] intValue];
                    }
                    else if ( [identificationKey isEqualToString:@"sendingServiceIdentifier"] )
                    {
                        if ( !message.sendingService )
                        {
                            PMPPService *sender = [PMPPService service];
                            message.sendingService = sender;
                        }
                        
                        message.sendingService.identifier.string = [header objectForKey:identificationKey];
                    }
                    else if ( [identificationKey isEqualToString:@"recipientServerIdentifier"] )
                    {
                        message.recipientServer.identifier.string = [header objectForKey:identificationKey];
                    }
                    else if ( [identificationKey isEqualToString:@"recipientServerPrivateAddress"] )
                    {
                        message.recipientServer.TCPConnection.privateAddress = [header objectForKey:identificationKey];
                        message.recipientServer.UDPConnection.privateAddress = [header objectForKey:identificationKey];
                    }
                    else if ( [identificationKey isEqualToString:@"recipientServerPrivatePort"] )
                    {
                        message.recipientServer.TCPConnection.privatePort = [[header objectForKey:identificationKey] intValue];
                        message.recipientServer.UDPConnection.privatePort = [[header objectForKey:identificationKey] intValue];
                    }
                    else if ( [identificationKey isEqualToString:@"recipientServerPublicAddress"] )
                    {
                        message.recipientServer.TCPConnection.publicAddress = [header objectForKey:identificationKey];
                        message.recipientServer.UDPConnection.publicAddress = [header objectForKey:identificationKey];
                    }
                    else if ( [identificationKey isEqualToString:@"recipientServerPublicPortTCP"] )
                    {
                        message.recipientServer.TCPConnection.publicPort = [[header objectForKey:identificationKey] intValue];
                    }
                    else if ( [identificationKey isEqualToString:@"recipientServerPublicPortUDP"] )
                    {
                        message.recipientServer.UDPConnection.publicPort = [[header objectForKey:identificationKey] intValue];
                    }
                    else if ( [identificationKey isEqualToString:@"recipientServiceIdentifier"] )
                    {
                        if ( !message.recipientService )
                        {
                            PMPPService *recipient = [PMPPService service];
                            message.recipientService = recipient;
                        }
                        
                        message.recipientService.identifier.string = [header objectForKey:identificationKey];
                    }
                    else if ( [identificationKey isEqualToString:@"receivedHistory"] )
                    {
                        message.receivedHistory.value = [header objectForKey:identificationKey];
                        message.receivedHistory.timestamp = [PMPPUtil stringAsDate:[header objectForKey:@"receivedHistoryTime"]];
                    }
                    else if ( [identificationKey isEqualToString:@"sentHistory"] )
                    {
                        message.sentHistory.value = [header objectForKey:identificationKey];
                        message.sentHistory.timestamp = [PMPPUtil stringAsDate:[header objectForKey:@"sentHistoryTime"]];
                    }
                    else if ( [identificationKey isEqualToString:@"session"] )
                    {
                        message.session = [header objectForKey:identificationKey];
                    }
                }
            }
            else
            {
                message.contents = [dict objectForKey:@"contents"];
                message.timestamp = [PMPPUtil stringAsDate:[dict objectForKey:@"timestamp"]];
                message.type = [[dict objectForKey:@"event"] intValue];
                message.version = [[dict objectForKey:@"version"] floatValue];
            }
        }
        
        // Now attempt to reference the actual instance of the servers.
        PMPPServer *recipientServer = [appDelegate.serverManager serverForIdentifier:message.recipientServer.identifier];
        PMPPServer *sendingServer = [appDelegate.serverManager serverForIdentifier:message.sendingServer.identifier];
        
        if ( !recipientServer )
        {
            recipientServer = [appDelegate.serverManager serverForTCPConnection:message.recipientServer.TCPConnection
                                                                  UDPConnection:message.recipientServer.UDPConnection];
        }
        
        if ( recipientServer )
        {
            PMPPIdentifier *sentIdentifier = message.recipientServer.identifier;
            
            if ( !recipientServer.identified )
            {
                recipientServer.identifier = sentIdentifier;
            }
            
            message.recipientServer = recipientServer;
        }
        
        if ( !sendingServer )
        {
            sendingServer = [appDelegate.serverManager serverForTCPConnection:message.sendingServer.TCPConnection
                                                                UDPConnection:message.sendingServer.UDPConnection];
        }
        
        if ( sendingServer )
        {
            PMPPIdentifier *sentIdentifier = message.sendingServer.identifier;
            
            /*
             *  Careful not to overwrite what the server sent as its
             *  identifier with our local temporary identifier!
             */
            if ( !sendingServer.identified )
            {
                sendingServer.identifier = sentIdentifier;
            }
            
            message.sendingServer = sendingServer;
        }
        
        message.recipientServer.identified = YES;
        message.sendingServer.identified = YES;
        
        return message;
    }
    
    // Message does not conform to the PMPP protocol if this point is reached.
    return nil;
}

+ (PMPPMessage *)messageWithMessage:(PMPPMessage *)message
{
    PMPPMessage *copy = [[PMPPMessage alloc] init];
    copy.ackIdentifier = message.ackIdentifier;
    copy.contents = message.contents;
    copy.encrypted = message.encrypted;
    copy.identifier = message.identifier;
    copy.recipientServer = message.recipientServer;
    copy.recipientService = message.recipientService;
    copy.sendingServer = message.sendingServer;
    copy.sendingService = message.sendingService;
    copy.receivedHistory = message.receivedHistory;
    copy.sentHistory = message.sentHistory;
    copy.session = message.session;
    copy.timestamp = message.timestamp;
    copy.transport = message.transport;
    copy.type = message.type;
    copy.version = message.version;
    
    return copy;
}

#pragma mark -
#pragma mark Overrides

- (NSString *)description
{
    NSDictionary *JSON = [self asDictionary];
    NSError *e;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSON options:kNilOptions error:&e];
    NSString *JSONString = [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
    
    if ( e )
    {
        NSLog(@"Error encoding PMPPMessage!");
    }
    
    return JSONString;
}

- (NSUInteger)hash
{
    return [_identifier hash];
}

- (BOOL)isEqual:(id)object
{
    if ( object )
    {
        if ( [object isKindOfClass:[PMPPMessage class]] )
        {
            PMPPMessage *temp = (PMPPMessage *)object;
            
            if ( temp.identifier && _identifier &&
                temp.identifier.string.length > 0 && _identifier.string.length > 0 )
            {
                if ( [temp.identifier isEqual:_identifier] )
                {
                    return YES;
                }
            }
        }
        else if ( [object isKindOfClass:[NSString class]] ) // Comparing directly to an identifier.
        {
            NSString *temp = (NSString *)object;
            
            if ( temp && _identifier &&
                temp.length > 0 && _identifier.string.length > 0 )
            {
                if ( [temp isEqual:_identifier] )
                {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

@end
