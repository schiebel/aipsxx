/*    cop.h
 *
 *    $Id: cop.h,v 19.0 2003/07/16 05:18:02 aips2adm Exp $
 *    Copyright (c) 1991-1997, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

typedef struct cop COP;
struct cop {
    BASEOP
    char *	cop_label;	/* label for this construct */
    HV *	cop_stash;	/* package line was compiled in */
    GV *	cop_filegv;	/* file the following line # is from */
    U32		cop_seq;	/* parse sequence number */
    I32		cop_arybase;	/* array base this line was compiled with */
    I32         cop_line;       /* line # of this command */
};

#define Nullcop Null(COP*)

