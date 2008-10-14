/*
**  This is a greatly MODIFIED version of a "top" machine dependent file.
**  The only resemblance it bears to the original is with respect to the
**  mechanics of finding various system details. The copyright details
**  follow.
**
**  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
**
**  Top users/processes display for Unix
**  Version 3
**
**  This program may be freely redistributed,
**  but this entire comment MUST remain intact.
**
**  Copyright (c) 1984, 1989, William LeFebvre, Rice University
**  Copyright (c) 1989 - 1994, William LeFebvre, Northwestern University
**  Copyright (c) 1994, 1995, William LeFebvre, Argonne National Laboratory
**  Copyright (c) 1996, William LeFebvre, Group sys Consulting
**  Copyright (c) 2002, Associated Universities Inc.
*/

/*
**          AUTHOR:       Darrell Schiebel  <drs@nrao.edu>
**
** ORIGINAL AUTHORS:      Richard Henderson <rth@tamu.edu>
**                        Alexey Klimkin    <kad@klon.tme.mcst.ru>
**
** $Id: linux.cc,v 19.0 2003/07/16 05:16:54 aips2adm Exp $
**
*/

#include <string.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/vfs.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include "Sysinfo.h"

#if 0
#include <linux/proc_fs.h>	/* for PROC_SUPER_MAGIC */
#else
#define PROC_SUPER_MAGIC 0x9fa0
#endif

#define PROCFS  "/proc"
#define CPUINFO "/proc/cpuinfo"
#define MEMINFO "/proc/meminfo"

#define bytetok(x)	(((x) + 512) >> 10)

static inline char *
skip_ws(const char *p)
{
    while (isspace(*p)) p++;
    return (char *)p;
}
    
static inline char *
skip_token(const char *p)
{
    while (isspace(*p)) p++;
    while (*p && !isspace(*p)) p++;
    return (char *)p;
}

void Sysinfo::machine_finalize( ) { }
 
void Sysinfo::machine_initialize( )
{
    /* make sure the proc filesystem is mounted */
    {
	struct statfs sb;
	if (statfs(PROCFS, &sb) < 0 || sb.f_type != PROC_SUPER_MAGIC)
	{
	    fprintf( stderr, "proc filesystem not mounted on " PROCFS "\n" );
	    valid = 0;
	    return;
	}
    }

    /* get number of CPUs */
    {
	char buffer[4096+1];
	int fd, len;

	cpus = 0;
	fd = open(CPUINFO, O_RDONLY);
	len = read(fd, buffer, sizeof(buffer)-1);
	close(fd);
	buffer[len] = '\0';
	char *p = buffer;

	/* be prepared for extra columns to appear by seeking
	   to ends of lines */

	while ( *p ) 
	{
	    if ( ! strncmp( p, "processor", 9 ) ) ++cpus;
	    p = strchr(p, '\n');
	    if ( *p == '\n' ) ++p;
	}
    }

}

void Sysinfo::update_info( )
{
    char buffer[4096+1];
    int fd, len;
    char *p;

    /* get system wide memory usage */
    {
	char *p;

	fd = open( MEMINFO, O_RDONLY);
	len = read(fd, buffer, sizeof(buffer)-1);
	close(fd);
	buffer[len] = '\0';

	/* be prepared for extra columns to appear be seeking
	   to ends of lines */

	p = strchr(buffer, '\n');
	p = skip_token(p);			/* "Mem:" */
	p = skip_token(p);			/* total memory */
	memory_used = bytetok(strtoul(p, &p, 10));
        memory_free = bytetok(strtoul(p, &p, 10));

	p = strchr(p, '\n');
	p = skip_token(p);			/* "Swap:" */
	p = skip_token(p);			/* total swap */
	swap_used = bytetok(strtoul(p, &p, 10));
	swap_free = bytetok(strtoul(p, &p, 10));
    }
}

