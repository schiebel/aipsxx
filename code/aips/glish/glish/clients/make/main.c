/*
 * Copyright (c) 1988, 1989, 1990 The Regents of the University of California.
 * Copyright (c) 1988, 1989 by Adam de Boor
 * Copyright (c) 1989 by Berkeley Softworks
 * All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * Adam de Boor.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef lint
char copyright[] =
"@(#) Copyright (c) 1989 The Regents of the University of California.\n\
 All rights reserved.\n";
#endif /* not lint */

#ifndef lint
/* from: static char sccsid[] = "@(#)main.c	5.25 (Berkeley) 4/1/91"; */
static char *rcsid = "$Id: main.c,v 19.0 2003/07/16 05:15:32 aips2adm Exp $";
#endif /* not lint */

/*-
 * main.c --
 *	The main file for this entire program. Exit routines etc
 *	reside here.
 *
 * Utility functions defined in this file:
 *	Main_ParseArgLine	Takes a line of arguments, breaks them and
 *				treats them as if they were given when first
 *				invoked. Used by the parse module to implement
 *				the .MFLAGS target.
 *
 *	Error			Print a tagged error message. The global
 *				MAKE variable must have been defined. This
 *				takes a format string and two optional
 *				arguments for it.
 *
 *	Fatal			Print an error message and exit. Also takes
 *				a format string and two arguments.
 *
 *	Punt			Aborts all jobs and exits with a message. Also
 *				takes a format string and two arguments.
 *
 *	Finish			Finish things up by printing the number of
 *				errors which occured, as passed to it, and
 *				exiting.
 */

#include <sys/types.h>
#include <sys/time.h>
#include <sys/param.h>
#include <sys/resource.h>
#include <sys/signal.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#ifdef __STDC__
#include <stdarg.h>
#else
#include <varargs.h>
#endif
#include "make.h"
#include "hash.h"
#include "dir.h"
#include "job.h"
#include "pathnames.h"
#include "make_client.h"

#ifndef	DEFMAXLOCAL
#define	DEFMAXLOCAL DEFMAXJOBS
#endif

#define	MAKEFLAGS	".MAKEFLAGS"

Lst			create;		/* Targets to be made */
time_t			now;		/* Time at start of make */
GNode			*DEFAULT;	/* .DEFAULT node */
Boolean			allPrecious;	/* .PRECIOUS given on line by itself */

static Lst		makefiles;	/* ordered list of makefiles to read */
static int		maxLocal;	/* -L argument */
Boolean			debug;		/* -d flag */
Boolean			noExecute;	/* -n flag */
Boolean			keepgoing;	/* -k flag */
Boolean			queryFlag;	/* -q flag */
Boolean			touchFlag;	/* -t flag */
Boolean			usePipes;	/* !-P flag */
Boolean			ignoreErrors;	/* -i flag */
Boolean			beSilent;	/* -s flag */
Boolean			oldVars;	/* variable substitution style */
Boolean			checkEnvFirst;	/* -e flag */
Boolean			ackEvent;	/* -A flag */
static Boolean		jobsRunning;	/* TRUE if the jobs might be running */

static Boolean		ReadMakefile();
static void		usage();

static char *curdir;			/* startup directory */
static char *objdir;			/* where we chdir'ed to */

#if !defined(BSD4_4) && !defined(HAVE__PROGNAME)
const char *__progname;
#endif

/*
 * On some systems MACHINE is defined as something other than
 * what we want.
 */
#ifdef FORCE_MACHINE
# undef MACHINE
# define MACHINE FORCE_MACHINE
#endif

/*-
 * MainParseArgs --
 *	Parse a given argument vector. Called from main() and from
 *	Main_ParseArgLine() when the .MAKEFLAGS target is used.
 *
 *	XXX: Deal with command line overriding .MAKEFLAGS in makefile
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	Various global and local flags will be set depending on the flags
 *	given
 */
static void
MainParseArgs(argc, argv)
	int argc;
	char **argv;
{
	extern int optind;
	extern char *optarg;
	int c;

#if !defined(BSD4_4) && !defined(HAVE__PROGNAME)
	if (argv[0] != 0) {		/* if called by Main_ParseArgLine() */
		if (__progname = strrchr(argv[0], '/'))
			__progname++;
		else
			__progname = argv[0];
	}
#endif
	if (argv[0] == 0)
		argv[0] = "";		/* avoid problems in getopt */

	optind = 1;	/* since we're called more than once */
# define OPTFLAGS "D:I:d:ef:A"
rearg:	while((c = getopt(argc, argv, OPTFLAGS)) != EOF) {
		switch(c) {
		case 'D':
			Var_Set(optarg, "1", VAR_GLOBAL);
			Var_Append(MAKEFLAGS, "-D", VAR_GLOBAL);
			Var_Append(MAKEFLAGS, optarg, VAR_GLOBAL);
			break;
		case 'I':
			Parse_AddIncludeDir(optarg);
			Var_Append(MAKEFLAGS, "-I", VAR_GLOBAL);
			Var_Append(MAKEFLAGS, optarg, VAR_GLOBAL);
			break;
		case 'd': {
			char *modules = optarg;

			for (; *modules; ++modules)
				switch (*modules) {
				case 'A':
					debug = ~0;
					break;
				case 'd':
					debug |= DEBUG_DIR;
					break;
				case 'f':
					debug |= DEBUG_FOR;
					break;
				case 'g':
					if (modules[1] == '1') {
						debug |= DEBUG_GRAPH1;
						++modules;
					}
					else if (modules[1] == '2') {
						debug |= DEBUG_GRAPH2;
						++modules;
					}
					break;
				case 'm':
					debug |= DEBUG_MAKE;
					break;
				case 's':
					debug |= DEBUG_SUFF;
					break;
				case 't':
					debug |= DEBUG_TARG;
					break;
				case 'v':
					debug |= DEBUG_VAR;
					break;
				default:
					(void)fprintf(stderr,
				"make: illegal argument to d option -- %c\n",
					    *modules);
					usage();
				}
			Var_Append(MAKEFLAGS, "-d", VAR_GLOBAL);
			Var_Append(MAKEFLAGS, optarg, VAR_GLOBAL);
			break;
		}
		case 'A':
			ackEvent = TRUE;
			Var_Append(MAKEFLAGS, "-N", VAR_GLOBAL);
			break;
		case 'e':
			checkEnvFirst = TRUE;
			Var_Append(MAKEFLAGS, "-e", VAR_GLOBAL);
			break;
		case 'f':
			(void)Lst_AtEnd(makefiles, (ClientData)optarg);
			break;
		default:
		case '?':
#ifdef MAKE_BOOTSTRAP
			fprintf(stderr, "getopt(%s) -> %d (%c)\n",
				OPTFLAGS, c, c);
#endif
			usage();
		}
	}

	oldVars = TRUE;

	/*
	 * See if the rest of the arguments are variable assignments and
	 * perform them if so. Else take them to be targets and stuff them
	 * on the end of the "create" list.
	 */
	for (argv += optind, argc -= optind; *argv; ++argv, --argc)
		if (Parse_IsVar(*argv))
			Parse_DoVar(*argv, VAR_CMD);
		else {
			if (!**argv)
				Punt("illegal (null) argument.");
			if (**argv == '-') {
				if ((*argv)[1])
					optind = 0;     /* -flag... */
				else
					optind = 1;     /* - */
				goto rearg;
			}
			(void)Lst_AtEnd(create, (ClientData)strdup(*argv));
		}
}

/*-
 * Main_ParseArgLine --
 *  	Used by the parse module when a .MFLAGS or .MAKEFLAGS target
 *	is encountered and by main() when reading the .MAKEFLAGS envariable.
 *	Takes a line of arguments and breaks it into its
 * 	component words and passes those words and the number of them to the
 *	MainParseArgs function.
 *	The line should have all its leading whitespace removed.
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	Only those that come from the various arguments.
 */
void
Main_ParseArgLine(line)
	char *line;			/* Line to fracture */
{
	char **argv;			/* Manufactured argument vector */
	int argc;			/* Number of arguments in argv */

	if (line == NULL)
		return;
	for (; *line == ' '; ++line)
		continue;
	if (!*line)
		return;

#ifndef POSIX
	{
		/*
		 * $MAKE may simply be naming the make(1) binary
		 */
		char *cp;

		if (!(cp = strrchr(line, '/')))
			cp = line;
		if ((cp = strstr(cp, "make")) &&
		    strcmp(cp, "make") == 0)
			return;
	}
#endif
	argv = brk_string(line, &argc, TRUE);
	MainParseArgs(argc, argv);
}

/*-
 * main --
 *	The main function, for obvious reasons. Initializes variables
 *	and a few modules, then parses the arguments give it in the
 *	environment and on the command line. Reads the system makefile
 *	followed by either Makefile, makefile or the file given by the
 *	-f argument. Sets the .MAKEFLAGS PMake variable based on all the
 *	flags it has received by then uses either the Make or the Compat
 *	module to create the initial list of targets.
 *
 * Results:
 *	If -q was given, exits -1 if anything was out-of-date. Else it exits
 *	0.
 *
 * Side Effects:
 *	The program exits when done. Targets are created. etc. etc. etc.
 */
int
bMake_Init(argc, argv)
	int argc;
	char **argv;
{
	struct stat sb, sa;
	char *p, *p1, *path, *pwd, *getenv(), *getcwd();
	char mdpath[MAXPATHLEN + 1];
	char obpath[MAXPATHLEN + 1];
	char cdpath[MAXPATHLEN + 1];

	/*
	 * Find where we are and take care of PWD for the automounter...
	 * All this code is so that we know where we are when we start up
	 * on a different machine with pmake.
	 */
	curdir = cdpath;
	if (getcwd(curdir, MAXPATHLEN) == NULL) {
		(void)fprintf(stderr, "make: %s.\n", curdir);
		exit(2);
	}

	if (stat(curdir, &sa) == -1) {
	    (void)fprintf(stderr, "make: %s: %s.\n",
			  curdir, strerror(errno));
	    exit(2);
	}

	if ((pwd = getenv("PWD")) != NULL) {
	    if (stat(pwd, &sb) == 0 && sa.st_ino == sb.st_ino &&
		sa.st_dev == sb.st_dev) 
		(void) strcpy(curdir, pwd);
	}


	/*
	 * if the MAKEOBJDIR (or by default, the _PATH_OBJDIR) directory
	 * exists, change into it and build there.  Once things are
	 * initted, have to add the original directory to the search path,
	 * and modify the paths for the Makefiles apropriately.  The
	 * current directory is also placed as a variable for make scripts.
	 */
	if (!(path = getenv("MAKEOBJDIR"))) {
		path = _PATH_OBJDIR;
		(void) sprintf(mdpath, "%s.%s", path, MACHINE);
	}
	else
		(void) strncpy(mdpath, path, MAXPATHLEN + 1);
	
	if (stat(mdpath, &sb) == 0 && S_ISDIR(sb.st_mode)) {

		if (chdir(mdpath)) {
			(void)fprintf(stderr, "make warning: %s: %s.\n",
				      mdpath, strerror(errno));
			objdir = curdir;
		}
		else {
			if (mdpath[0] != '/') {
				(void) sprintf(obpath, "%s/%s", curdir, mdpath);
				objdir = obpath;
			}
			else
				objdir = mdpath;
		}
	}
	else {
		if (stat(path, &sb) == 0 && S_ISDIR(sb.st_mode)) {

			if (chdir(path)) {
				(void)fprintf(stderr, "make warning: %s: %s.\n",
					      path, strerror(errno));
				objdir = curdir;
			}
			else {
				if (path[0] != '/') {
					(void) sprintf(obpath, "%s/%s", curdir,
						       path);
					objdir = obpath;
				}
				else
					objdir = obpath;
			}
		}
		else
			objdir = curdir;
	}

	setenv("PWD", objdir, 1);

	create = Lst_Init(FALSE);
	makefiles = Lst_Init(FALSE);
	beSilent = TRUE;		/* Print commands as executed */
	ignoreErrors = FALSE;		/* Pay attention to non-zero returns */
	noExecute = FALSE;		/* Execute all commands */
	keepgoing = FALSE;		/* Stop on error */
	allPrecious = FALSE;		/* Remove targets when interrupted */
	queryFlag = FALSE;		/* This is not just a check-run */
	touchFlag = FALSE;		/* Actually update targets */
	usePipes = TRUE;		/* Catch child output in pipes */
/*	debug = 0;*/			/* No debug verbosity, please. */
	jobsRunning = FALSE;

	maxLocal = DEFMAXLOCAL;		/* Set default local max concurrency */

	/*
	 * Initialize the parsing, directory and variable modules to prepare
	 * for the reading of inclusion paths and variable settings on the
	 * command line
	 */
	Dir_Init();		/* Initialize directory structures so -I flags
				 * can be processed correctly */
	Parse_Init();		/* Need to initialize the paths of #include
				 * directories */
	Var_Init();		/* As well as the lists of variables for
				 * parsing arguments */
        str_init();
	if (objdir != curdir)
		Dir_AddDir(dirSearchPath, curdir);
	Var_Set(".CURDIR", curdir, VAR_GLOBAL);
	Var_Set(".OBJDIR", objdir, VAR_GLOBAL);

	/*
	 * Initialize various variables.
	 *	MAKE also gets this name, for compatibility
	 *	.MAKEFLAGS gets set to the empty string just in case.
	 *	MFLAGS also gets initialized empty, for compatibility.
	 */
	Var_Set("MAKE", argv[0], VAR_GLOBAL);
	Var_Set(MAKEFLAGS, "", VAR_GLOBAL);
	Var_Set("MFLAGS", "", VAR_GLOBAL);
#ifdef MACHINE
	Var_Set("MACHINE", MACHINE, VAR_GLOBAL);
#endif
#ifdef MACHINE_ARCH
	Var_Set("MACHINE_ARCH", MACHINE_ARCH, VAR_GLOBAL);
#endif

	MainParseArgs(argc, argv);

	/*
	 * Initialize archive, target and suffix modules in preparation for
	 * parsing the makefile(s)
	 */
	Arch_Init();
	Targ_Init();
	Suff_Init();

	DEFAULT = NILGNODE;
	(void)time(&now);

	/*
	 * Set up the .TARGETS variable to contain the list of targets to be
	 * created. If none specified, make the variable empty -- the parser
	 * will fill the thing in with the default or .MAIN target.
	 */
	if (!Lst_IsEmpty(create)) {
		LstNode ln;

		for (ln = Lst_First(create); ln != NILLNODE;
		    ln = Lst_Succ(ln)) {
			char *name = (char *)Lst_Datum(ln);

			Var_Append(".TARGETS", name, VAR_GLOBAL);
		}
	} else
		Var_Set(".TARGETS", "", VAR_GLOBAL);

	if (!Lst_IsEmpty(makefiles)) {
		LstNode ln;

		ln = Lst_Find(makefiles, (ClientData)NULL, ReadMakefile);
		if (ln != NILLNODE)
			Fatal("make: cannot open %s.", (char *)Lst_Datum(ln));
	}

	Var_Append("MFLAGS", Var_Value(MAKEFLAGS, VAR_GLOBAL, &p1), VAR_GLOBAL);
	if (p1)
	    free(p1);

	/* Install all the flags into the MAKE envariable. */
	if (((p = Var_Value(MAKEFLAGS, VAR_GLOBAL, &p1)) != NULL) && *p)
#ifdef POSIX
		setenv("MAKEFLAGS", p, 1);
#else
		setenv("MAKE", p, 1);
#endif
	if (p1)
	    free(p1);

	/*
	 * For compatibility, look at the directories in the VPATH variable
	 * and add them to the search path, if the variable is defined. The
	 * variable's value is in the same format as the PATH envariable, i.e.
	 * <directory>:<directory>:<directory>...
	 */
	if (Var_Exists("VPATH", VAR_CMD)) {
		char *vpath, *path, *cp, savec;
		/*
		 * GCC stores string constants in read-only memory, but
		 * Var_Subst will want to write this thing, so store it
		 * in an array
		 */
		static char VPATH[] = "${VPATH}";

		vpath = Var_Subst(NULL, VPATH, VAR_CMD, FALSE);
		path = vpath;
		do {
			/* skip to end of directory */
			for (cp = path; *cp != ':' && *cp != '\0'; cp++)
				continue;
			/* Save terminator character so know when to stop */
			savec = *cp;
			*cp = '\0';
			/* Add directory to search path */
			Dir_AddDir(dirSearchPath, path);
			*cp = savec;
			path = cp + 1;
		} while (savec == ':');
		(void)free((Address)vpath);
	}

	/*
	 * Now that all search paths have been read for suffixes et al, it's
	 * time to add the default search path to their lists...
	 */
	Suff_DoPaths();
	return( 0 );
}

static int
MainStrDup( cmdp, lstp )
    ClientData cmdp;
    ClientData lstp;
{
  Lst lst = (Lst)lstp;
  Lst_AtEnd( lst, strdup((char*)cmdp) );
  return(0);
}

static int
CleanTargs( gnp, lstp )
    ClientData gnp;
    ClientData lstp;
{
    GNode *gn = (GNode*) gnp;
    if ( gn->type & OP_GENERATED ) Targ_Delete( gn );
    return 0;
}

static int
MainUnmake( gn, dummy )
    ClientData gn;
    ClientData dummy;
{
    int count = 0;
    GNode *targ = (GNode*) gn;
    targ->made = UNMADE;
    targ->childMade = FALSE;
    Var_Set(">","",targ);
    Var_Set("?","",targ);
    Lst_Destroy(targ->commands, NOFREE);
    targ->commands = Lst_Init (FALSE);
    Lst_ForEach( targ->orig_cmds, MainStrDup, (ClientData)targ->commands );
    return 0;
}

int
bMake( )
{
	Lst targs;	/* target nodes to create -- passed to Make_Init */

	Targ_FlagGNs ( );
	/* print the initial graph, if the user requested it */
	if (DEBUG(GRAPH1))
		Targ_PrintGraph(1);

	targs = Targ_FindList(create, TARG_CREATE);

	Compat_Run(targs);

	Targ_NoFlagGNs ( );
	Targ_ForEach( CleanTargs, (ClientData)NULL );

	Lst_Destroy(targs, NOFREE);

	Targ_ForEach( MainUnmake, (ClientData)NULL );

	return( 0 );
}

int
bMake_Finish( void )
{
	Lst_Destroy(makefiles, NOFREE);
	Lst_Destroy(create, (void (*) __P((ClientData))) free);

	/* print the graph now it's been processed if the user requested it */
	if (DEBUG(GRAPH2))
		Targ_PrintGraph(2);

	Suff_End();
        Targ_End();
	Arch_End();
	str_end();
	Var_End();
	Parse_End();
	Dir_End();
	return(0);
}

/*-
 * ReadMakefile  --
 *	Open and parse the given makefile.
 *
 * Results:
 *	TRUE if ok. FALSE if couldn't open file.
 *
 * Side Effects:
 *	lots
 */
static Boolean
ReadMakefile(fname)
	char *fname;		/* makefile to read */
{
	extern Lst parseIncPath, sysIncPath;
	FILE *stream;
	char *name, path[MAXPATHLEN + 1];

	if (!strcmp(fname, "-")) {
		Parse_File("(stdin)", stdin);
		Var_Set("MAKEFILE", "", VAR_GLOBAL);
	} else {
		if ((stream = fopen(fname, "r")) != NULL)
			goto found;
		/* if we've chdir'd, rebuild the path name */
		if (curdir != objdir && *fname != '/') {
			(void)sprintf(path, "%s/%s", curdir, fname);
			if ((stream = fopen(path, "r")) != NULL) {
				fname = path;
				goto found;
			}
		}
		/* look in -I and system include directories. */
		name = Dir_FindFile(fname, parseIncPath);
		if (!name)
			name = Dir_FindFile(fname, sysIncPath);
		if (!name || !(stream = fopen(name, "r")))
			return(FALSE);
		fname = name;
		/*
		 * set the MAKEFILE variable desired by System V fans -- the
		 * placement of the setting here means it gets set to the last
		 * makefile specified, as it is set by SysV make.
		 */
found:		Var_Set("MAKEFILE", fname, VAR_GLOBAL);
		Parse_File(fname, stream);
		(void)fclose(stream);
	}
	return(TRUE);
}

/*-
 * Error --
 *	Print an error message given its format.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The message is printed.
 */
/* VARARGS */
void
#ifdef __STDC__
Error(char *fmt, ...)
#else
Error(va_alist)
	va_dcl
#endif
{
	va_list ap;
#ifdef __STDC__
	va_start(ap, fmt);
#else
	char *fmt;

	va_start(ap);
	fmt = va_arg(ap, char *);
#endif
	(void)vfprintf(stderr, fmt, ap);
	va_end(ap);
	(void)fprintf(stderr, "\n");
	(void)fflush(stderr);
}


extern void handle_fatal_error( const char * );

/*-
 * Fatal --
 *	Produce a Fatal error message. If jobs are running, waits for them
 *	to finish.
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	The program exits
 */
/* VARARGS */
void
#ifdef __STDC__
Fatal(char *fmt, ...)
#else
Fatal(va_alist)
	va_dcl
#endif
{
	char buff[2048];
	va_list ap;
#ifdef __STDC__
	va_start(ap, fmt);
#else
	char *fmt;

	va_start(ap);
	fmt = va_arg(ap, char *);
#endif
	if (jobsRunning)
		Job_Wait();

	(void)vsprintf(buff, fmt, ap);
	va_end(ap);

	if (DEBUG(GRAPH2))
		Targ_PrintGraph(2);

	handle_fatal_error( buff );
}

/*
 * Punt --
 *	Major exception once jobs are being created. Kills all jobs, prints
 *	a message and exits.
 *
 * Results:
 *	None 
 *
 * Side Effects:
 *	All children are killed indiscriminately and the program Lib_Exits
 */
/* VARARGS */
void
#ifdef __STDC__
Punt(char *fmt, ...)
#else
Punt(va_alist)
	va_dcl
#endif
{
	va_list ap;
#ifdef __STDC__
	va_start(ap, fmt);
#else
	char *fmt;

	va_start(ap);
	fmt = va_arg(ap, char *);
#endif

	(void)fprintf(stderr, "make: ");
	(void)vfprintf(stderr, fmt, ap);
	va_end(ap);
	(void)fprintf(stderr, "\n");
	(void)fflush(stderr);

	DieHorribly();
}

/*-
 * DieHorribly --
 *	Exit without giving a message.
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	A big one...
 */
void
DieHorribly()
{
	if (jobsRunning)
		Job_AbortAll();
	if (DEBUG(GRAPH2))
		Targ_PrintGraph(2);
	exit(2);		/* Not 1, so -q can distinguish error */
}

/*
 * Finish --
 *	Called when aborting due to errors in child shell to signal
 *	abnormal exit. 
 *
 * Results:
 *	None 
 *
 * Side Effects:
 *	The program exits
 */
void
Finish(errors)
	int errors;	/* number of errors encountered in Make_Make */
{
	Fatal("%d error%s", errors, errors == 1 ? "" : "s");
}

/*
 * emalloc --
 *	malloc, but die on error.
 */
char *
emalloc(len)
	size_t len;
{
	char *p;

	if ((p = (char *) malloc(len)) == NULL)
		enomem();
	return(p);
}

/*
 * enomem --
 *	die when out of memory.
 */
void
enomem()
{
	(void)fprintf(stderr, "make: %s.\n", strerror(errno));
	exit(2);
}

/*
 * usage --
 *	exit with usage message
 */
static void
usage()
{
	(void)fprintf(stderr,
"usage: make [-eiknqrst] [-D variable] [-d flags] [-f makefile ]\n\
            [-I directory] [-j max_jobs] [variable=value]\n");
	exit(2);
}


int
PrintAddr(a, b)
    ClientData a;
    ClientData b;
{
    printf("%lx ", (unsigned long) a);
    return b ? 0 : 0;
}

void
bMake_Define( var, var_len, val, val_len )
    const char **var;
    int var_len;
    const char **val;
    int val_len;
{
    int len = var_len < val_len ? var_len : var_len;
    int i = 0, j=0;
    int j_incr = 1;
    if ( ! var || var_len <= 0 ) return;
    if ( ! val || val_len <= 0 ) return;
    if ( var_len > 1 && val_len == 1 ) {
        len = var_len;
	j_incr = 0;
    }
    for ( ; i < len; ++i,j+=j_incr )
        Var_Set( (char*)var[i], (char*)val[j], VAR_GLOBAL );
}

void
bMake_TargetDef( tag, tag_len, cmd, cmd_len, depend, depend_len )
    const char **tag;
    int tag_len;
    const char **cmd;
    int cmd_len;
    const char **depend;
    int depend_len;
{
    int i = 0, x = 0;
    GNode *gn,*dep;
    /*** do we have a tag? ***/
    if ( ! tag || tag_len <= 0 ) return;
    /*** do we have a command? ***/
    if ( ! cmd || cmd_len <= 0 ) return;
    for ( x=0; x < tag_len; ++x ) {
        gn = Targ_FindNode( (char*)tag[x], TARG_CREATE );
        if ( cmd && cmd_len > 0 )
            for ( i=0; i < cmd_len; ++i )
                Cmd_AtEnd( gn, strdup(cmd[i]) );
        if ( depend && depend_len > 0 ) {
            gn->type |= OP_DEPENDS;
            for ( i=0; i < depend_len; ++i ) {
                dep = Targ_FindNode ((char*)depend[i], TARG_CREATE);
                if (Lst_Member (gn->children, (ClientData)dep) == NILLNODE) {
                    (void)Lst_AtEnd (gn->children, (ClientData)dep);
                    gn->unmade += 1;
                }
                if (Lst_Member (dep->parents, (ClientData)gn) == NILLNODE) {
		    (void)Lst_AtEnd (dep->parents, (ClientData)gn);
                }
            }
        }
    }
}

void
bMake_SuffixDef( tag, tag_len, cmd, cmd_len )
    const char **tag;
    int tag_len;
    const char **cmd;
    int cmd_len;
{
    int i = 0, x = 0;
    int dot_count = 0;
    GNode *gn;
    const char *end;
    char buf[256];
    char *bp = 0;

    /*** do we have a command? ***/
    if ( ! cmd || cmd_len <= 0 ) return;
    /*** does it look like a suffix rule? ***/
    if ( ! tag || tag_len <= 0 ) return;    
    /*** how many dots does it have? ***/
    for ( x=0; x < tag_len; ++x ) {
        if ( *tag[x] != '.' ) return;
	dot_count = 0;
	for ( end=tag[x]; *end; ++end )
	    if ( *end == '.' ) ++dot_count;
	if ( dot_count != 2 ) return;
    }

    for ( x=0; x < tag_len; ++x ) {
        bp = buf;
        *bp++ = '.';
        for ( end = tag[x]+1; *end && *end != '.'; *bp++ = *end++ );
        *bp = '\0';
        Suff_AddSuffix((char*)buf);
        Suff_AddSuffix((char*)end);
        gn = Suff_AddTransform((char*)tag[x]);

        for ( i=0; i < cmd_len; ++i )
            Cmd_AtEnd( gn, strdup(cmd[i]) );
    }
}

void
bMake_SetMain( tgt, len )
    const char **tgt;
    int len;
{
    int i=0;
    if ( ! Lst_IsEmpty(create)) {
        Lst_Destroy( create, NOFREE);
	create = Lst_Init( FALSE );
    }
    if ( ! tgt || len <= 0 ) return;
    for ( i=0; i < len; ++i )
        Lst_AtEnd( create, strdup(tgt[i]) );
}

int
bMake_HasMain( )
{
    return Lst_IsEmpty(create) ? 0 : 1;
}
