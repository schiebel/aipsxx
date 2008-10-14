#! /usr/bin/perl -w
# e2epipedaemon
#
# Time-stamp: <2002-04-05 02:20:59 bwaters>

# Copyright (C) 2002
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#

use strict;
use POSIX qw(setsid);

#$ENV{PATH} = "/bin:/usr/bin"

umask 0;

open STDIN, '/dev/null'
	or die "Failure when redirecting STDIN to /dev/null: $!\n";


# make a log file
my $log = sprintf( "e2epipe-log-%d", time);

open STDOUT, ">$log"
	or die "Failure when redirecting STDOUT to $log: $!\n";

my $errlog = sprintf("e2epipe-err-%d", time);

open STDERR, ">$errlog"
	or die "Failure when redirecting STDERR to $errlog: $!\n";

defined(my $pid = fork)
	or die "Can't fork: $!\n";

exit if $pid;

# DAEMON CODE FOLLOWS THIS LINE
setsid
	or die "Can't start a new session: $!\n";

my @command = ("glish", "e2epipedriver.g");

system @command;

