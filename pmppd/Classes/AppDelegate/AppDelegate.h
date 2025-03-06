//
//  AppDelegate.h
//  pmppd
//
//  Created by Ali.cpp on 12/8/15.
//
//

#ifndef APPDELEGATE_H
#define APPDELEGATE_H

#import <Cocoa/Cocoa.h>

#import "PMPPConnectionManager.h"
#import "PMPPMessageManager.h"
#import "PMPPPresenceManager.h"
#import "PMPPServerManager.h"
#import "PMPPServiceManager.h"

@class GCDAsyncSocket;
@class PMPPServer;

@interface AppDelegate : NSObject <NSApplicationDelegate,
                                    PMPPConnectionManagerDelegate,
                                    PMPPMessageManagerDelegate,
                                    PMPPPresenceManagerDelegate,
                                    PMPPServerManagerDelegate,
                                    PMPPServiceManagerDelegate>
{
    GCDAsyncSocket *testSocket;
    IBOutlet NSTextField *identifierField;
    IBOutlet NSTextField *networkStateLabel;
    IBOutlet NSTextField *privateAddressLabel;
    IBOutlet NSTextField *publicTCPAddressLabel;
    IBOutlet NSTextField *publicUDPAddressLabel;
    IBOutlet NSTextField *subnetMaskLabel;
    IBOutlet NSTextView *textView;
}

@property (nonatomic) NSString *dataDirectory;
@property (nonatomic) NSString *session;
@property (weak) IBOutlet NSWindow *window;
@property (nonatomic) PMPPConnectionManager *connectionManager;
@property (nonatomic) PMPPMessageManager *messageManager;
@property (nonatomic) PMPPPresenceManager *presenceManager;
@property (nonatomic) PMPPServer *this;
@property (nonatomic) PMPPServerManager *serverManager;
@property (nonatomic) PMPPServiceManager *serviceManager;

- (IBAction)addAddress:(id)sender;
- (IBAction)generateIdentifier:(id)sender;
- (IBAction)registerService:(id)sender;
- (IBAction)sendMessage:(id)sender;

+ (AppDelegate *)sharedDelegate;

@end

#endif