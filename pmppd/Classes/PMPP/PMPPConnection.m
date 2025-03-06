//
//  PMPPConnection.m
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#import "PMPPConnection.h"

#import "GCDAsyncSocket.h"

@implementation PMPPConnection

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        _connectionAttempts = 0;
        _interface = PMPPConnectionInterfaceNone;
        _keepAlive = NO;
        _privateAddress = @"";
        _privatePort = PMPP_PORT_LAN; // Set to default LAN port.
        _publicAddress = @"";
        _publicPort = 0;
        _timestamp = [NSDate date];
        _type = TransportTypeNone;
    }
    
    return self;
}

#pragma mark -

- (void)connected
{
    _connectionAttempts = 0;
    _timestamp = [NSDate date];
}

#pragma mark -
#pragma mark Class methods

+ (PMPPConnection *)connection
{
    return [[PMPPConnection alloc] init];
}

#pragma mark -
#pragma mark Overrides

- (NSString *)description
{
    return [NSString stringWithFormat:@"public: %@:%d / private: %@:%d", _publicAddress, _publicPort, _privateAddress, _privatePort];
}

- (BOOL)isEqual:(id)object
{
    PMPPConnection *temp = (PMPPConnection *)object;
    
    if ( _socket && temp.socket )
    {
        if ( [_socket isEqual:temp.socket] )
        {
            return YES;
        }
    }
    
    if ( _publicAddress && temp.publicAddress )
    {
        if ( _publicAddress.length > 0 && temp.publicAddress.length > 0 )
        {
            if ( [temp.publicAddress isEqualToString:_publicAddress] && temp.publicPort == _publicPort )
            {
                return YES;
            }
        }
        else if ( _privateAddress && temp.privateAddress )
        {
            /*
             *  This block is intended for the times that 2 nodes
             *  happen to be on the same LAN & not have a public
             *  address (e.g. if port mapping is blocked).
             */
            if ( [temp.privateAddress isEqualToString:_privateAddress] && temp.privatePort == _privatePort )
            {
                return YES;
            }
        }
    }
    
    if ( _privateAddress && temp.privateAddress )
    {
        if ( [temp.publicAddress isEqualToString:_publicAddress] )
        {
            if ( [temp.privateAddress isEqualToString:_privateAddress] && temp.privatePort == _privatePort )
            {
                return YES;
            }
        }
    }
    
    return NO;
}

@end
