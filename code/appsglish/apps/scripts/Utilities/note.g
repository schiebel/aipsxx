# note.g: Write message to logger or screen, with or without fail.
#
#   Copyright (C) 1998,2002
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
#   $Id: note.g,v 19.2 2004/08/25 02:09:26 cvsmgr Exp $
#


pragma include once

# summary: 
# note('a message', priority='NORMAL', origin='Glish', time='',
#       postglobally=T, postlocally=T)
# return throw('a message', origin='Glish')
#
# Messages go to logger if it exists, otherwise the terminal.

const note := function(..., priority='NORMAL', origin='Glish', time='',
		       postglobally=T, postlocally=T, postcli=F)
{
    message := spaste(...);
    if (is_defined('defaultlogger') && has_field(defaultlogger,'log') &&
	is_function(defaultlogger.log)) {
	defaultlogger.log(time, priority, message, origin, postglobally,
			  postlocally, postcli);
    } else {
	print spaste(priority, ': ', message);
    }

    return T;
}

const throw := function(..., origin='Glish', postcli=F)
{
    message := spaste(...);
    note(message, priority='SEVERE', origin=origin, postcli=postcli);
    fail message;
}
