//
//  PMPPPresenceManager.m
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#import "PMPPPresenceManager.h"

#import "AppDelegate.h"
#import "GCDAsyncSocket.h"
#import "PMPPConnection.h"
#import "PMPPServerManager.h"
#import "PMPPMessageManager.h"
#import "PMPPConnectionManager.h"
#import "PMPPMessage.h"
#import "PMPPServer.h"
#import "PMPPUtil.h"

@implementation PMPPPresenceManager

- (instancetype)init
{
    self = [super init];
    
    if ( self )
    {
        didNotifyDelegateOnlinePresence = NO;
        didNotifyDelegateOfflinePresence = NO;
        
        [self resetPresenceForAll];
    }
    
    return self;
}

#pragma mark -

- (void)refreshPresenceForAll
{
    
}

- (void)resetPresenceForAll
{
    
}
#pragma mark -

- (void)currentPresenceChanged
{
    [self currentPresenceDidChange];
}

- (void)presenceChangedForServer:(PMPPServer *)server
{
    
}

#pragma mark -
#pragma mark SHPresenceManagerDelegate methods

- (void)currentPresenceDidChange
{
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(currentPresenceDidChange)] )
        {
            [_delegate currentPresenceDidChange];
        }
    });
}

- (void)presenceDidChangeForServer:(PMPPServer *)server
{
    // Make sure all delegate methods are called on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [_delegate respondsToSelector:@selector(presenceDidChangeForServer:)] )
        {
            [_delegate presenceDidChangeForServer:server];
        }
    });
}

@end
