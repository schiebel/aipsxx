// $Id: RemoteExec.h,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.
#ifndef remoteexec_h
#define remoteexec_h

#include "Executable.h"

class Channel;

class RemoteExec : public Executable {
    public:
	RemoteExec( Channel* daemon_channel, const char* arg_executable,
		    const char * arg_name, const char** argv );
	~RemoteExec();

	int Active();
	void Ping();

    protected:
	char* id;
	char *name;			// name as registered with glishd
	Channel* daemon_channel;
	};

#endif	/* remoteexec_h */
