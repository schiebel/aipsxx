// $Id: Sysinfo.h,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 2002 Associated Universities Inc.
#ifndef sysinfo_h_
#define sysinfo_h_

class Sysinfo {
    public:
	Sysinfo( ) : valid(1), cpus(0) { machine_initialize( ); update_info( ); }
	~Sysinfo( ) { machine_finalize( ); valid = 0; }

	void Update( ) { if ( valid ) update_info( ); }

	int Memory( ) const { return valid ? memory_free + memory_used : -1; }
	int MemoryUsed( ) const { return valid ? memory_used : -1; }
	int MemoryFree( ) const { return valid ? memory_free : -1; }

	int Swap( ) const { return valid ? swap_free + swap_used : -1; }
	int SwapUsed( ) const { return valid ? swap_used : -1; };
	int SwapFree( ) const { return valid ? swap_free : -1; }

	int NumCpus( ) const { return valid ? cpus : 0; }

    protected:

	int memory_used;
	int memory_free;
	int swap_used;
	int swap_free;
	int cpus;

	int valid;

    private:

	void machine_initialize( );
	void machine_finalize( );
	void update_info( );
};

#endif
