#-----------------------------------------------------------------------------
# AIPS++ admin/system directory makefile
#-----------------------------------------------------------------------------
#
#   Copyright (C) 1992-1994,1997
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#-----------------------------------------------------------------------------
# GNU makefile used to install administrative utilities and databases.
#
# Original: 1994/03/24 by Mark Calabretta, ATNF
# $Id: makefile,v 19.0 2003/07/16 04:39:13 aips2adm Exp $
#-----------------------------------------------------------------------------

# AIPS++ fundamentals.
#---------------------
AIPSROOT := $(word 1, $(AIPSPATH))
AIPSARCH := $(AIPSROOT)/$(word 2, $(AIPSPATH))
include $(AIPSARCH)/makedefs


# Source lists.
#--------------
SCRIPTS  := astat


# Pattern rules.
#---------------
$(ARCHBIND)/% :: $(CODEDIR)/%
	@ $(RM) $@
	  cp $< $@
	@ chmod 775 $@


# Static and static pattern rules.
#---------------------------------
allsys : $(SCRIPTS)

# Scripts
$(SCRIPTS) : % : $(ARCHBIND)/% ;

show_local :
	-@ echo ""
	-@ echo "Variables defined in the sysadmin makefile"
	-@ echo "=========================================="
	-@ echo ""
	-@ echo "SCRIPTS =$(SCRIPTS)"

help ::
	-@ echo ""
	-@ echo "Targets defined in the sysadmin makefile"
	-@ echo "========================================"
	-@ echo ""
	-@ echo "System"
	-@ echo "------"
	-@ echo "  (SCRIPTS): install sysadmin scripts."
