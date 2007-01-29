#include <stdio.h>
#include <string.h>
#include "config.h"

/*
** #if defined(F2C)
** MAIN__() { }
** #endif
*/

/*
	From the PGPLOT docs.
CHR(1:1) = `H' if the device is a hardcopy device, `I' if it is an
interactive
device. On an interactive device, the image is visible as it is being drawn,
while on a hardcopy device it cannot be viewed until the workstation is
closed. 

	CHR(2:2) = `C' if a cursor is available, `X' if a cursor is
available and opcode 27 is accepted by the handler, `N' if there is no
cursor. PGPLOT cannot emulate a cursor if none is available.

	CHR(3:3) = `D' if the hardware can draw dashed lines, `N' if
it cannot.  PGPLOT emulates dashed lines by drawing line
segments. Software emulation is usually superior to hardware dashed
lines, and not much slower, so CHR(3:3) = `N' is recommended.

	CHR(4:4) = `A' if the hardware can fill arbitrary polygons
with solid color, `N' if it cannot. PGPLOT emulates polygon fill by
drawing horizontal or vertical lines spaced by the pen diameter (see
OPCODE = 3).

	CHR(5:5) = `T' if the hardware can draw lines of variable
width, `N' if it cannot. PGPLOT emulates thick lines by drawing
multiple strokes. Note that thick lines are supposed to have rounded
ends, as if they had been drawn by a circular nib of the specified
diameter.

	CHR(6:6) = `R' if the hardware can fill rectangles with solid
color, `N' if it cannot. If this feature is not available, PGPLOT will
treat the rectangle as an arbitrary polygon. In this context, a
`rectangle' is assumed to have its edges parallel to the
device-coordinate axes.

	CHR(7:7) = `P' if the handler understands the pixel
primitives, 'Q' if it understands the image primitives (opcode 26), or
`N' otherwise (see the description of opcode 26).

	CHR(8:8) = `V' if PGPLOT should issue an extra prompt to the
user before closing the device (in PGEND), `N' otherwise. Use `V' for
devices where the PGPLOT window is deleted from the screen when the
device is closed.

	CHR(9:9) = `Y' if the handler accepts color representation
queries (opcode 29), `N' if it does not.

CHR(10:10) = `M' if the device handler accepts opcode 28 to draw graph
markers; `N' otherwise. 

*/
/*
1) Hardcopy device. May be changed in future.
2) No cursor is available. May be changed in future.
3) Can't draw dashed lines (PGPLOT recommendation).
4) Can fill arbitrary polygons with solid color.
5) Can draw lines of variable width
6) Can fill rectangles with solid color
7) Handler doesn't understand the pixel primitives.
8) PGPLOT should not issue an extra prompt to the user before closing device.
9) Handler accepts color representation queries (opcode 29).
10)No markers.
*/

/* The dispatcher for PGPLOT. */
static int NUMDRIVERS = 6;
extern int PSDRIV(int *ifunc, float *rbuf, int *nbuf, char *chr,
					int *lchr, int *mode, int chr_len);
extern int tkdriv(int *ifunc, float *rbuf, int *nbuf, char *chr, int *lchr, int len);

int (*display_library_pgplot_driver)(int *, float *, int *, char *, int *, int *, int) = 0;

int grexec_(int *idev, int *ifunc, float *rbuf, int *nbuf,
		char *chr, int *lchr, int chr_len)
{
char *dl_dev_name = "WCPGFILTER (WorldCanvas driver for DisplayLibrary)";
int num,i;

	switch (*idev) {
	case 0:
		rbuf[0] = NUMDRIVERS;
		*nbuf = 1;
		break;
	case 1:
		tkdriv(ifunc, rbuf, nbuf, chr, lchr, chr_len);
		break;
	case 2:
		num = 1;
		psdriv_(ifunc, rbuf, nbuf, chr, lchr, &num, chr_len);
		break;
	case 3:
		num = 2;
		psdriv_(ifunc, rbuf, nbuf, chr, lchr, &num, chr_len);
		break;
	case 4:
		num = 3;
		psdriv_(ifunc, rbuf, nbuf, chr, lchr, &num, chr_len);
		break;
	case 5:
		num = 4;
		psdriv_(ifunc, rbuf, nbuf, chr, lchr, &num, chr_len);
		break;
	case 6:
		num = 5;
		if ( display_library_pgplot_driver )
			(*display_library_pgplot_driver)(ifunc, rbuf, nbuf, chr, lchr, &num, chr_len);
		else if ( *ifunc == 1 )
			{
			strncpy(chr, dl_dev_name, chr_len);
			*lchr = strlen(dl_dev_name);
			for(i = *lchr; i < chr_len; i++)
				chr[i] = ' ';
			}
		break;
	default:
		fprintf(stderr, "grexec: Unknown device code %d\n", *idev);
		break;
	}
	return 0;
}
