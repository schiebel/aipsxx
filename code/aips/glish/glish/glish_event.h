/* $Id: glish_event.h,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $ 
** Copyright (c) 1993 The Regents of the University of California.
** Copyright (c) 1997 Associated Universities Inc.
*/
#ifndef glish_event_h
#define glish_event_h

/* Glish inter-client protocol version. */
#define GLISH_CLIENT_PROTO_VERSION 4

/* Bits in the flags that are transmitted with each event. */
/*                                                         */
/*    NOTE: we only have a byte to work with here, so      */
/*          after 0x80 we'll need to look for more space   */
/*          in the SOS header (there's a spare short).     */
/*                                                         */
#define GLISH_HAS_ATTRIBUTE	0x1
#define GLISH_REQUEST_EVENT	0x2
#define GLISH_REPLY_EVENT 	0x4
#define GLISH_STRING_EVENT 	0x8
#define GLISH_PROXY_EVENT 	0x10
#define GLISH_QUIET_EVENT 	0x20
#define GLISH_EVENT_BUNDLE 	0x40

#endif /* glish_event_h */
