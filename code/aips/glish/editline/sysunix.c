/*  $Id: sysunix.c,v 19.4 2004/02/02 17:43:04 wyoung Exp $
**
**  Unix system-dependant routines for editline library.
**
** Copyright (c) 1992,1993 Simmule Turner and Rich Salz.  All rights reserved.
** Copyright (c) 1997 Associated Universities Inc.    All rights reserved.
*/

#include "config.h"
#include "editline.h"
RCSID("@(#) $Id: sysunix.c,v 19.4 2004/02/02 17:43:04 wyoung Exp $")
#include <signal.h>

#if	defined(HAVE_TCGETATTR)
#if	defined(HAVE_TERMIO_H) || defined(HAVE_TERMIOS_H)
#include <termios.h>
#endif

void
rl_ttyset(Reset)
    int				Reset;
{
    static int mucked = 0;
    static struct termios	old;
    struct termios		new;

    if ( Reset == 0 ) {
        if ( ! mucked++ ) {
	    (void)tcgetattr(0, &old);
	    rl_erase = old.c_cc[VERASE];
	    rl_kill = old.c_cc[VKILL];
	    rl_eof = old.c_cc[VEOF];
	    rl_intr = old.c_cc[VINTR];
	    rl_quit = old.c_cc[VQUIT];
#if	defined(DO_SIGTSTP) && defined(SIGTSTP)
	    rl_susp = old.c_cc[VSUSP];
#endif	/* defined(DO_SIGTSTP) */

	    new = old;
	    new.c_lflag &= ~(ECHO | ICANON | ISIG);
	    new.c_iflag &= ~(ISTRIP | INPCK);
	    new.c_cc[VMIN] = 1;
	    new.c_cc[VTIME] = 0;
	    (void)tcsetattr(0, TCSADRAIN, &new);
	}
    }
    else if ( ! --mucked )
	(void)tcsetattr(0, TCSADRAIN, &old);
}

#else
#if	defined(HAVE_TERMIO_H)
#include <termio.h>

void
rl_ttyset(Reset)
    int				Reset;
{
    static struct termio	old;
    struct termio		new;

    if (Reset == 0) {
	(void)ioctl(0, TCGETA, &old);
	rl_erase = old.c_cc[VERASE];
	rl_kill = old.c_cc[VKILL];
	rl_eof = old.c_cc[VEOF];
	rl_intr = old.c_cc[VINTR];
	rl_quit = old.c_cc[VQUIT];
#if	defined(DO_SIGTSTP) && defined(SIGTSTP)
	rl_susp = old.c_cc[VSUSP];
#endif	/* defined(DO_SIGTSTP) */

	new = old;
	new.c_lflag &= ~(ECHO | ICANON | ISIG);
	new.c_iflag &= ~(ISTRIP | INPCK);
	new.c_cc[VMIN] = 1;
	new.c_cc[VTIME] = 0;
	(void)ioctl(0, TCSETAW, &new);
    }
    else
	(void)ioctl(0, TCSETAW, &old);
}

#else
#include <sgtty.h>

void
rl_ttyset(Reset)
    int				Reset;
{
    static struct sgttyb	old_sgttyb;
    static struct tchars	old_tchars;
    struct sgttyb		new_sgttyb;
    struct tchars		new_tchars;
#if	defined(DO_SIGTSTP) && defined(SIGTSTP)
    struct ltchars		old_ltchars;
#endif	/* defined(DO_SIGTSTP) */

    if (Reset == 0) {
	(void)ioctl(0, TIOCGETP, &old_sgttyb);
	rl_erase = old_sgttyb.sg_erase;
	rl_kill = old_sgttyb.sg_kill;

	(void)ioctl(0, TIOCGETC, &old_tchars);
	rl_eof = old_tchars.t_eofc;
	rl_intr = old_tchars.t_intrc;
	rl_quit = old_tchars.t_quitc;

#if	defined(DO_SIGTSTP) && defined(SIGTSTP)
	(void)ioctl(0, TIOCGLTC, &old_ltchars);
	rl_susp = old_ltchars.t_suspc;
#endif	/* defined(DO_SIGTSTP) */

	new_sgttyb = old_sgttyb;
	new_sgttyb.sg_flags &= ~ECHO;
	new_sgttyb.sg_flags |= RAW;
#if	defined(PASS8)
	new_sgttyb.sg_flags |= PASS8;
#endif	/* defined(PASS8) */
	(void)ioctl(0, TIOCSETP, &new_sgttyb);

	new_tchars = old_tchars;
	new_tchars.t_intrc = -1;
	new_tchars.t_quitc = -1;
	(void)ioctl(0, TIOCSETC, &new_tchars);
    }
    else {
	(void)ioctl(0, TIOCSETP, &old_sgttyb);
	(void)ioctl(0, TIOCSETC, &old_tchars);
    }
}
#endif	/* defined(HAVE_TERMIO_H) */
#endif	/* defined(HAVE_TCGETATTR) */

void
rl_add_slash(path, p)
    char	*path;
    char	*p;
{
    struct stat	Sb;

    if (stat(path, &Sb) >= 0)
	(void)strcat(p, S_ISDIR(Sb.st_mode) ? "/" : " ");
}
