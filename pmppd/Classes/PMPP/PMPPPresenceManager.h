//
//  PMPPPresenceManager.h
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#ifndef PMPPPRESENCEMANAGER_H
#define PMPPPRESENCEMANAGER_H

#import <Foundation/Foundation.h>

@class PMPPServer;

@protocol PMPPPresenceManagerDelegate<NSObject>
@optional

- (void)currentPresenceDidChange;
- (void)presenceDidChangeForServer:(PMPPServer *)server;

@end

@interface PMPPPresenceManager : NSObject
{
    BOOL didNotifyDelegateOnlinePresence;
    BOOL didNotifyDelegateOfflinePresence;
}

@property (nonatomic, weak) id <PMPPPresenceManagerDelegate> delegate;

- (void)refreshPresenceForAll;
- (void)resetPresenceForAll;
//-----------------------------------------------------
- (void)currentPresenceChanged;
- (void)presenceChangedForServer:(PMPPServer *)server;

@end

#endif