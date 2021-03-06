#   Copyright (C) 1999
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
#   $Id: chpag.awk,v 19.0 2003/07/16 03:36:53 aips2adm Exp $
#
# This little awk program reads the *.toc and puts out pagenumbers for chapters
#
BEGIN { FS = "\}\{|\{|\}| \{" 
        last_page = 0;
      }
/chapter/{ sub(" ", "", $5);
           if(last_page < 1){
             printf "-o %s.ps  -pp %d-", $5, $(NF-1)
           } else {
             printf "%d\n-o %s.ps  -pp %d-", $(NF-1)-1, $5, $(NF-1)
           }
         }
!/chapter/{last_page = $(NF-1)};
END { printf "%d\n", last_page;}
