// $Id: Daemon.h,v 19.12 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.
#ifndef daemon_h
#define daemon_h
#include <system.h>

class Channel;
class Value;

// Possible states a daemon can be in.
typedef enum
	{
	DAEMON_OK,	// all is okay
	DAEMON_REPLY_PENDING,	// we're waiting for reply to last probe
	DAEMON_LOST	// we've lost connectivity
	} daemon_states;

// A RemoteDaemon keeps track of a glishd running on a remote host.
// This includes the Channel used to communicate with the daemon and
// modifiable state indicating whether we're currently waiting for
// a probe response from the daemon.
class RemoteDaemon GC_FINAL_CLASS {
public:
	RemoteDaemon( const char* daemon_host, Channel* channel )
		{
		host = string_dup(daemon_host);
		chan = channel;
		SetState( DAEMON_OK );
		}

	const char* Host()		{ return host; }
	Channel* DaemonChannel()	{ return chan; }
	daemon_states State()		{ return state; }
	void SetState( daemon_states s )	{ state = s; }

	void UpdateBinPath( const Value * );
	void UpdateLdPath( const char * );

	~RemoteDaemon() { free_memory(host); }

protected:
	char* host;
	Channel* chan;
	daemon_states state;
	};



Channel *start_remote_daemon( const char *host );
Channel *start_local_daemon( );
RemoteDaemon *connect_to_daemon(const char *host, int &err);

#endif
