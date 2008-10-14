#! /usr/bin/perl -w
# e2eforms.pl

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
use CGI;
use IO::Socket::INET qw(:crlf);

use constant EMAIL  => scalar "e2e-webmaster\@aoc.nrao.edu";
use constant TITLE 	=> scalar "Echo CGI Results";
use constant ERR_TTL=> scalar "VLA Archive Error";
use constant HOST	=> scalar "localhost";
use constant PORT	=> scalar 7002;
use constant SHUT_WR=> scalar 1;

my $query = new CGI;

my @names = $query->param;

	# ask the browser to hold onto these results for five minutes
print $query->header( -expires => '+5m' );
error_msg("No query parameters specified.") unless @names;

# build the data string -- we use CRLF as line delimter
# we do this in order to url-decode the data;
# otherwise we could have simply used the CONTENT environment variable
#
my $dataStream;
foreach (@names) {
	$dataStream .= "$_=";
	$dataStream .= $query->param($_);
	$dataStream .= CRLF;
}

# open a socket to the server and blast the dataStream across
my $client = new IO::Socket::INET
	(
	 PeerAddr	=> HOST,
	 PeerPort	=> PORT,
	 Proto		=> 'tcp'
	 );

error_msg("Cannot send data to Glish: no socket.") unless defined $client;

$client->autoflush(1);
my $chars_sent = $client->send( $dataStream );
$client->shutdown( SHUT_WR );


######

#print $query->h1( TITLE );


# now wait for data back from the Glish socket
my $xml;


#error_msg("Didn't receive a response from Glish.") if (not defined $xml);

#print $query->start_html( TITLE );

print "<html><head><title>" . TITLE . "</title><body>\n";	 

#print "\n<p>Client sent $chars_sent bytes.\n</p>\n";
#print "<hr />\n";
#print "<h2>Response from Glish</h2>\n";
#print "<pre>\n";
while( defined($xml = <$client>)) {
	print $xml;
}
#print "</pre>\n";

print $query->end_html;

1;
#END OF MAIN

sub error_msg {
	my $msg = shift;
	#print $query->header;
	print $query->start_html( ERR_TTL );
	print $query->h1( ERR_TTL );
	print <<END_HTML;
<p>
An error occurred while processing your request.
Please try again. If this error happens again, please
contact the web administrator.
</p>
<p class="errorMsg">$msg</p>
END_HTML

	print "<p><a href=\"mailto:";
	print EMAIL;
	print "</a></p>\n";
	print $query->end_html();

	die;
}


sub dump_cgi {
	print $query->header;
	print $query->start_html( TITLE );
	print $query->h1( TITLE );
	print "\n<pre>\n";

	foreach (@names) {
		print "$_\t = ";
		print $query->param($_);
		print "\n";
	}

	print "</pre>\n";
	print  $query->end_html;
}
