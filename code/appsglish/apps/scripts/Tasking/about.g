# about.g: Startup script for about DO servers
#
#   Copyright (C) 1996,1997,1998
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
#   $Id: about.g,v 19.2 2004/08/25 02:01:47 cvsmgr Exp $
#
pragma include once


include "sysinfo.g"
include "guicomponents.g"
include "note.g";

about := function(use_gui = have_gui())
{
    self   := [=]
    public := [=]

    if (! have_gui()) {
	self.gui := F
    } else {
	self.gui := use_gui
    }

    self.message := '\t AIPS++ (Astronomical Information Processing System)\n\n'

    info := sysinfo()

    info.version(formatted=version,dolog=F)
    self.message := paste(self.message, 'AIPS++ version: ',version,'\n',sep='' )
    arch := info.arch()
    self.message := paste(self.message, 'Architecture: ',arch,sep='' )
    self.message := paste(self.message, ' (memory=',as_string(info.memory()),
			', #CPU=',as_string(info.numcpu()), ')\n',sep='')
    self.message := paste(self.message, 'site=',info.site(),sep='' )
    self.message := paste(self.message, ' host=',info.host(),sep='' )
    self.message := paste(self.message, ' root=',info.root(),'\n\n',sep='' )
    self.message := paste(self.message,
'Contact information:\n\
www:    http://aips2.nrao.edu/aips++/docs/html/aips++.html\n\
email:  aips2-request@nrao.edu\n\n\n\
Copyright (C) 1995-2000 Associated Universities, Inc. Washington DC, USA.\n\
\n\
This program is free software; you can redistribute it and/or modify it\n\
under the terms of the GNU General Public License as published by the Free\n\
Software Foundation; either version 2 of the License, or (at your option)\n\
any later version.\n\
 \n\
This program is distributed in the hope that it will be useful, but WITHOUT\n\
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or\n\
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for\n\
more details.\n\
 \n\
You should have received a copy of the GNU General Public License along\n\
with this program; if not, write to the Free Software Foundation, Inc.,\n\
675 Massachusetts Ave, Cambridge, MA 02139, USA.\n\
 \n\
Correspondence concerning AIPS++ should be addressed as follows:\n\
\tInternet email: aips2-request@nrao.edu.\n\
\tPostal address: AIPS++ Project Office\n\
\t\tNational Radio Astronomy Observatory\n\
\t\tPO Box O\n\
\t\tSocorro, NM, 87801 USA')



    if (!self.gui) {
	note(self.message, origin='about')
        return T
    }

    self.mb := messagebox(self.message, 'lightgrey', maxrows=20)
    return T;
}
