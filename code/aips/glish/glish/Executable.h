// $Id: Executable.h,v 19.12 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.
#ifndef executable_h
#define executable_h

#include "Glish/List.h"
#include "system.h"

// Searches PATH for the given executable; returns a malloc()'d copy
// of the path to the executable, which the caller should delete when
// done with.
char* which_executable( const char* exec_name );
void set_executable_path( charptr *path, int len );

// Given a fully qualified path, this checks to see if the file can
// be executed.
int can_execute( const char* name );

class Exec GC_FINAL_CLASS {
    public:
	friend class ExecMinder;
	Exec( );
	virtual ~Exec( );
    protected:
	virtual int pid();
	virtual void SetStatus( int );
};

class ExecMinder;
glish_declare(PList,ExecMinder);

//
// look after waiting on children
//
class ExecMinder GC_FINAL_CLASS {
    public:
	// look after this Exec
	ExecMinder( Exec * );
	// do nothing
	ExecMinder( );
	~ExecMinder( );
	int pid() { return lexec ? lexec->pid() : 0 ; }

	// can be called after a fork (where an exec is not done)
	// to clean up all pid information from the parent
	static void ForkReset( );

    protected:
	static void sigchld( );
	static PList(ExecMinder) *active_list;
	void SetStatus( int s ) { if ( lexec ) lexec->SetStatus( s ); }
	Exec *lexec;
};

class Executable : public Exec {
    public:
	Executable( const char* arg_executable );
	virtual ~Executable();

	int ExecError()	{ return exec_error; }

	// true if the executable is still "out there"
	virtual int Active() = 0;
	void Deactivate( ) { deactivated = 1; }
	virtual void Ping() = 0;

	virtual void DoneReceived();

    protected:
	char* executable;
	int exec_error;
	int has_exited;
	int deactivated;
	};

#endif	/* executable_h */
