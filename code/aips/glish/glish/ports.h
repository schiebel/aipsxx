/* $Id: ports.h,v 19.12 2004/11/03 20:39:00 cvsmgr Exp $
** Copyright (c) 1993 The Regents of the University of California.
** Copyright (c) 1997,2000 Associated Universities Inc.
*/

/* Port numbers used by Glish. */


/* Default port used by Glish interpreter.  If it's in use, the interpreter
 * may switch to another port.*/

#define INTERPRETER_DEFAULT_PORT 2000

/* Port always used by Glish daemon; there's only ever one daemon
 * per host.
 */
#define DAEMON_PORT 2833
