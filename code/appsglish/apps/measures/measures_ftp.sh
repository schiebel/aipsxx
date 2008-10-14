#!/bin/sh
# measures_ftp.sh: Shell commands to read an ftp file
#   Copyright (C) 1997,2001
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
#   $Id: measures_ftp.sh,v 19.1 2004/08/25 01:29:32 cvsmgr Exp $
#
#=============================================================================
#
# To ftp a FILE from ADDR at DIR into ftp_file.in do:
# (FTPDATA='ADDR DIR FILE'; export FTPDATA; sh measures_ftp.sh)
#
# Fundamentals
#
  if [ ! "$AIPSPATH" ]
  then
     echo "measures_ftp: AIPSPATH is not defined, abort!"
     exit 1
  fi
  AIPSROOT=`echo $AIPSPATH | awk '{ print $1 }'`
#
# Get data
#
  AIPSUSER=${USER}@`domainname`
  FTPADDR=`echo $FTPDATA | awk '{ print $1 }'`
  FTPDIR=`echo $FTPDATA | awk '{ print $2 }'`
  FTPFILE=`echo $FTPDATA | awk '{ print $3 }'`
  FTPOFILE=`echo $FTPDATA | awk '{ print $4 }'`
#
# ftp file
#
  ftp -n -v -i ${FTPADDR} <<_EOD_
quote user anonymous
quote pass ${AIPSUSER}
ascii
cd ${FTPDIR}
get ${FTPFILE} ${FTPOFILE}
quit
_EOD_
unset FTPDATA
#
# if the source file is empty then exit with
# a failure, otherwise OK
#
if [ -s $FTPOFILE ] ; then
  rstatus=0
else
  rstatus=1
fi
exit $rstatus
