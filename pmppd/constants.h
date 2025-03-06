//
//  Constants.h
//  pmppd
//
//  Created by Ali.cpp on 12/8/15.
//
//

#ifndef CONSTANTS_H
#define CONSTANTS_H

// All delays are in seconds.
#define ASCII_RANGE                             127
#define LOCALHOST                               @"127.0.0.1"
#define MASTER_LIST_SERVERS                     @"masterServers"
#define MESSAGE_INTERVAL                        0.05
#define MESSAGE_THRESHOLD                       5
#define NETWORK_CONNECTION_ATTEMPT_TIMEOUT      3
#define NETWORK_CONNECTION_TIMEOUT              5       
#define NETWORK_PORT_MAP_DELAY                  4       
#define PEER_CONNECTION_TIMER                   6
#define PING_THRESHOLD                          4
#define PMPP_PORT_LAN                           6221
#define PMPP_PORT_SERVERS                       6223
#define PMPP_PORT_SERVICES                      6222
#define PMPP_VERSION                            1.0
#define PMPP_DATA_ENTITY                        @"entity"
#define PMPP_DATA_CONTEXT                       @"context"
#define PMPP_DATA_CONTEXT_ITEM                  @"contextItem"
#define PMPP_DATA_ADDRESS_PRIVATE               @"addressPrivate"
#define PMPP_DATA_ADDRESS_PUBLIC                @"addressPublic"
#define PMPP_DATA_LAST_CONNECTION               @"lastConnection"
#define PMPP_DATA_BACKWARD_MEETING_POINT        @"backwardMeetingPoint"
#define PMPP_DATA_FORWARD_MEETING_POINT         @"forwardMeetingPoint"
#define PMPP_DATA_MESSAGE_COUNT                 @"messageCount"
#define PMPP_DATA_PENDING_ITEM                  @"pending"
#define PMPP_DATA_PORT_PRIVATE                  @"portPrivate"
#define PMPP_DATA_PORT_PUBLIC_TCP               @"portPublicTCP"
#define PMPP_DATA_PORT_PUBLIC_UDP               @"portPublicUDP"
#define PMPP_DATA_RECEIVED_HISTORY              @"receivedHistory"
#define PMPP_DATA_RECEIVED_HISTORY_TIME         @"receivedHistoryTime"
#define PMPP_DATA_SENT_HISTORY                  @"sentHistory"
#define PMPP_DATA_SENT_HISTORY_TIME             @"sentHistoryTime"
#define PMPP_DATA_WATCHER                       @"watcher"
#define PMPPD_DIR                               @"pmppd"
#define STATIC_SERVER_ADDRESS                   @"178.79.166.153"
#define STATIC_SERVER_PORT                      6222
#define TCP_IDLE_TIMEOUT                        60 * 3 // 3 mins.
#define USER_AGENT                              @"PMPPD_OS_X"

typedef enum {
    PMPPConnectionInterfaceNone = 1,
    PMPPConnectionInterfaceCellular,
    PMPPConnectionInterfaceLAN
} PMPPConnectionInterface;

typedef enum {
    PMPPEntityNone = 1,
    PMPPEntityServer,
    PMPPEntityService,
    PMPPEntityFusion,
    PMPPEntityMessage
} PMPPEntityType;

typedef enum {
    PMPPServerEventNone = 1,
    PMPPServerEventAddressHandoff,
    PMPPServerEventAddressRequest,
    PMPPServerEventAddressResponse,
    PMPPServerEventConnect,
    PMPPServerEventConnectAck,
    PMPPServerEventDisconnect,
    PMPPServerEventDeliveredToServer,
    PMPPServerEventDeliveredToServerAck,
    PMPPServerEventDeliveredToService,
    PMPPServerEventDeliveredToServiceAck,
    PMPPServerEventEOT,
    PMPPServerEventMessage,
    PMPPServerEventMeetingPoints,
    PMPPServerEventMeetingPointsResponse,
    PMPPServerEventPublicKey,
    PMPPServerEventSharedKey,
    PMPPServerEventPing,
    PMPPServerEventPingAck,
    PMPPServerEventProbe,
    PMPPServerEventProbeAck,
    PMPPServerEventProbeTarget,
    PMPPServerEventProbeTargetAck,
    PMPPServiceEventAddHost,
    PMPPServiceEventAddressUpdate,
    PMPPServiceEventConnected,
    PMPPServiceEventDisconnected,
    PMPPServiceEventRemoveHost,
    PMPPServiceEventDelivered,
    PMPPServiceEventMessage,
    PMPPServiceEventRegister,
    PMPPServiceEventRequestAddress
} PMPPEvent;

typedef enum {
    PMPPMessageStatusNone = 1,
    PMPPMessageStatusSent,
    PMPPMessageStatusDelivered
} PMPPMessageStatus;

typedef enum {
    PMPPPresenceNone = 1,
    PMPPPresenceOffline,
    PMPPPresenceConnecting,
    PMPPPresenceOnline
} PMPPPresenceType;

typedef enum {
    TransportTypeNone = 1,
    TransportTypeTCP,
    TransportTypeUDP
} TransportType;

#endif