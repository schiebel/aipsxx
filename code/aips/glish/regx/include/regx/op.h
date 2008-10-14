/*    op.h
 *
 *    $Id: op.h,v 19.0 2003/07/16 05:17:58 aips2adm Exp $
 *    Copyright (c) 1991-1997, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifndef op_h_
#define op_h_

#ifdef __cplusplus
extern "C" {
#endif

/*
 * The fields of BASEOP are:
 *	op_next		Pointer to next ppcode to execute after this one.
 *			(Top level pre-grafted op points to first op,
 *			but this is replaced when op is grafted in, when
 *			this op will point to the real next op, and the new
 *			parent takes over role of remembering starting op.)
 *	op_ppaddr	Pointer to current ppcode's function.
 *	op_type		The type of the operation.
 *	op_flags	Flags common to all operations.  See OPf_* below.
 *	op_private	Flags peculiar to a particular operation (BUT,
 *			by default, set to the number of children until
 *			the operation is privatized by a check routine,
 *			which may or may not check number of children).
 */

typedef U32 PADOFFSET;

#ifdef DEBUGGING_OPS
#define OPCODE opcode
#else
#define OPCODE U16
#endif

#define BASEOP				\
    OP*		op_next;		\
    OP*		op_sibling;		\
    OP*		(*op_ppaddr)();		\
    PADOFFSET	op_targ;		\
    OPCODE	op_type;		\
    U16		op_seq;			\
    U8		op_flags;		\
    U8		op_private;

/* Public flags */

#define OPf_WANT	3	/* Mask for "want" bits: */
#define  OPf_WANT_VOID	 1	/*   Want nothing */
#define  OPf_WANT_SCALAR 2	/*   Want single value */
#define  OPf_WANT_LIST	 3	/*   Want list of any length */
#define OPf_KIDS	4	/* There is a firstborn child. */
#define OPf_PARENS	8	/* This operator was parenthesized. */
				/*  (Or block needs explicit scope entry.) */
#define OPf_REF		16	/* Certified reference. */
				/*  (Return container, not containee). */
#define OPf_MOD		32	/* Will modify (lvalue). */
#define OPf_STACKED	64	/* Some arg is arriving on the stack. */
#define OPf_SPECIAL	128	/* Do something weird for this op: */
				/*  On local LVAL, don't init local value. */
				/*  On OP_SORT, subroutine is inlined. */
				/*  On OP_NOT, inversion was implicit. */
				/*  On OP_LEAVE, don't restore curpm. */
				/*  On truncate, we truncate filehandle */
				/*  On control verbs, we saw no label */
				/*  On flipflop, we saw ... instead of .. */
				/*  On UNOPs, saw bare parens, e.g. eof(). */
				/*  On OP_ENTERSUB || OP_NULL, saw a "do". */
				/*  On OP_(ENTER|LEAVE)EVAL, don't clear $@ */

struct op {
    BASEOP
};

struct pmop {
    BASEOP
    OP *	op_first;
    OP *	op_last;
    U32		op_children;
    OP *	op_pmreplroot;
    OP *	op_pmreplstart;
    PMOP *	op_pmnext;		/* list of all scanpats */
    REGEXP *	op_pmregexp;		/* compiled expression */
    SV *	op_pmshort;		/* for a fast bypass of execute() */
    U16		op_pmflags;
    U16		op_pmpermflags;
    char	op_pmslen;
};

#define PMf_USED	0x0001		/* pm has been used once already */
#define PMf_ONCE	0x0002		/* use pattern only once per reset */
#define PMf_SCANFIRST	0x0004		/* initial constant not anchored */
#define PMf_ALL		0x0008		/* initial constant is whole pat */
#define PMf_SKIPWHITE	0x0010		/* skip leading whitespace for split */
#define PMf_FOLD	0x0020		/* case insensitivity */
#define PMf_CONST	0x0040		/* subst replacement is constant */
#define PMf_KEEP	0x0080		/* keep 1st runtime pattern forever */
#define PMf_GLOBAL	0x0100		/* pattern had a g modifier */
#define PMf_CONTINUE	0x0200		/* don't reset pos() if //g fails */
#define PMf_EVAL	0x0400		/* evaluating replacement as expr */
#define PMf_WHITE	0x0800		/* pattern is \s+ */
#define PMf_MULTILINE	0x1000		/* assume multiple lines */
#define PMf_SINGLELINE	0x2000		/* assume single line */
#define PMf_LOCALE	0x4000		/* use locale for character types */
#define PMf_EXTENDED	0x8000		/* chuck embedded whitespace */

#ifdef __cplusplus
	}
#endif

#endif
