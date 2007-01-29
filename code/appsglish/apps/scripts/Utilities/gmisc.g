# gmisc.g:  Provide interface to convenience functions
#
#   Copyright (C) 1995,1996,1997,1999,2001
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: gmisc.g,v 19.2 2004/08/25 02:08:46 cvsmgr Exp $
#
#----------------------------------------------------------------------------

pragma include once;

include "misc.g";

stripleadingblanks := ref du.stripleadingblanks;
striptrailingblanks := ref du.striptrailingblanks;
patternmatch := ref du.patternmatch;
dir := ref du.dir;
parentDir := ref du.parentDir;
fileType := ref du.fileType;
tableType := ref du.tableType;
fopen := ref du.fopen;
fclose := ref du.fclose;
fgets := ref du.fgets;
fread := ref du.fread;
fwrite := ref du.fwrite;

