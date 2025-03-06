//
//  PMPPServiceManager.m
//  pmppd
//
//  Created by Ali.cpp on 12/13/15.
//
//

#import "PMPPServiceManager.h"

#import "AppDelegate.h"
#import "constants.h"
#import "GCDAsyncSocket.h"
#import "PMPPConnection.h"
#import "PMPPIdentifier.h"
#import "PMPPMessage.h"
#import "PMPPMessageManager.h"
#import "PMPPService.h"

@implementation PMPPServiceManager

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        _services = [NSMutableSet set];
    }
    
    return self;
}

#pragma mark -

- (void)didRegisterService:(PMPPService *)service
{
    if ( service )
    {
        [_services addObject:service];
        
        // Notify delegate.
        [self serviceManagerDidRegisterService:service];
    }
    else
    {
        [self serviceManagerFailedToRegisterService:service];
    }
}

- (PMPPService *)acceptedConnection:(PMPPConnection *)connection
{
    PMPPService *service = [PMPPService service];
    service.connection = connection;
    
    [_services addObject:service];
    
    return service;
}

#pragma mark -

- (void)send:(PMPPMessage *)message to:(PMPPService *)service
{
    if ( message && service )
    {
        for ( PMPPService *s in _services )
        {
            if ( [s isEqual:service] )
            {
                AppDelegate *appDelegate = [AppDelegate sharedDelegate];
                
                [appDelegate.messageManager sendServiceMessage:message];
                
                break;
            }
        }
    }
}

#pragma mark -

- (PMPPService *)serviceForIdentifier:(PMPPIdentifier *)identifier
{
    if ( identifier )
    {
        for ( PMPPService *service in _services )
        {
            if ( [service.identifier isEqual:identifier] )
            {
                return service;
            }
        }
    }
    
    return nil;
}

- (PMPPService *)serviceForSocket:(GCDAsyncSocket *)socket
{
    if ( socket )
    {
        for ( PMPPService *service in _services )
        {
            if ( [service.connection.socket isEqual:socket] )
            {
                return service;
            }
        }
    }
    
    return nil; // Not found.
}

#pragma mark -
#pragma mark Class methods

+ (BOOL)socketIsService:(GCDAsyncSocket *)socket
{
    if ( [socket.localHost isEqualToString:LOCALHOST] &&
        socket.localPort == PMPP_PORT_SERVICES )
    {
        return YES;
    }
    
    return NO;
}

#pragma mark -
#pragma mark PMPPServiceManagerDelegate methods

- (void)serviceManagerDidRegisterService:(PMPPService *)service
{
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(serviceManagerDidRegisterService:)] )
        {
            [_delegate serviceManagerDidRegisterService:service];
        }
    });
}

- (void)serviceManagerFailedToRegisterService:(PMPPService *)service
{
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(serviceManagerDidRegisterService:)] )
        {
            [_delegate serviceManagerDidRegisterService:service];
        }
    });
}

@end
