// $Id: Channel.h,v 19.12 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.
#ifndef channel_h
#define channel_h
#include "sos/io.h"

// Channels manage a communication channel to a process.  The channel
// consists of two file descriptors, one for reading from the process
// and the other for writing to the process.
//
// The Channel class doesn't do much at the moment.  It used to do a lot
// more (providing buffering and line-oriented reads) but presently Glish
// clients use binary I/O to transmit messages, so Channel's have become
// little more than a way to bundle together two file descriptors.  We
// retain some of the Channel abstraction, however, in case in the future
// we wish to return to buffering.

// Channels have a state associated with them.  CHAN_VALID is an ordinary
// channel.  CHAN_IN_USE is a channel that is presently being read from.
// CHAN_INVALID marks a channel that would have been deleted except that
// it was "in use"; it should be deleted as soon as it is no longer being used.
//
// Note that the value of the channel status is managed *externally*,
// and not by the member functions of the class.  ChannelState() may
// be used to access and modify the internal state variable.
//
// The state is initialized to CHAN_VALID.

#include <Glish/Object.h>

typedef enum { CHAN_VALID, CHAN_IN_USE, CHAN_INVALID } ChanState;

class Channel : public GlishRef {
    public:

	// Create a new Channel with the given input and output fd's.
	Channel( int rfd, int wfd ) : source(rfd, &common), sink(wfd, &common)
		{ state = CHAN_VALID; }

	// True if data pending in channel read buf.  This is a vestigial
	// remnant from when the Channel class used to buffer its input.
	// It remains here so that if later we find we need to return to
	// buffering, we can do so easily.
	int DataInBuffer()
		{ return 0; }

	// Note we do *not* return a "const ChanState&"; the user is
	// free to modify the channel state.
	ChanState& ChannelState()	{ return state; }

	sos_fd_sink &Sink()	{ return sink; }
	sos_fd_source &Source()	{ return source; }

    protected:
	ChanState state;
	sos_common common;
	sos_fd_source source;
	sos_fd_sink sink;
	};

#endif	/* channel_h */
