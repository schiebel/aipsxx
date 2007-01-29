#!/usr/local/bin/perl5
# the above standard path will be automaticlly replaced at installation time 
# with an appropriate local path to the glish-capable perl.
#--------------------------------------------------------------------------
# gbtlogviewutil.pl:  a perl script for use with glish-extended Perl 5.001
# which supplies dates and time information to the gbtlogview.g program
#
#   Copyright (C) 1995, 1996
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
#   $Id: gbtlogviewutil.pl,v 19.0 2003/07/16 03:42:24 aips2adm Exp $
#
#--------------------------------------------------------------------------
use Glish;
#--------------------------------------------------------------------------
# beginning of implicit main

# print STDERR "Glish perl client started";

if (standalone()) {
  print STDERR " in stand alone mode.\n";
  exit(1);
  } 

($key,$val,$attr) = nextevent($type,$isrequest);

while ($key) {
  #print "Got $key ($type):\n";
  #displayGlishValue ($val,"\t");
  #if ($attr) {print "with attribute:\n"; displayGlishValue ($attr,"\t");}
  $returnValue = -99;
  if ($key eq "currentTime") {
    $currentTime = `date '+%m/%d/%Y,%H:%M:%S'`;
    #displayGlishValue ($currentTime,"\t");
    #print "about to return currentTime from perl: ", $currentTime, "\n";
    postevent ($key, $currentTime);
    }
  elsif ($key eq "test") {
    $t = time ();
    $formattedTime = formatToUniversalTime ($t);
    print $formattedTime, "\n";
    postevent ($key, $formattedTime);
    }
  elsif ($key eq "lastHour") {
    $secondsSince1970 = time ();
    $returnValue {"seconds"} = $secondsSince1970;
    $returnValue {"endTime"} = formatToUniversalTime ($secondsSince1970);
    $returnValue {"startTime"} = 
         formatToUniversalTime ($secondsSince1970 - (60 * 60));
    postevent ($key, \%returnValue);
    }
  elsif ($key eq "lastDay") {
    $secondsSince1970 = time ();
    $returnValue {"seconds"} = $secondsSince1970;
    $returnValue {"endTime"} = formatToUniversalTime ($secondsSince1970);
    $returnValue {"startTime"} = 
       formatToUniversalTime ($secondsSince1970 - (60 * 60 * 24));
    postevent ($key, \%returnValue);
    }
  elsif ($key eq "lastWeek") {
    $secondsSince1970 = time ();
    $returnValue {"seconds"} = $secondsSince1970;
    $returnValue {"endTime"} = formatToUniversalTime ($secondsSince1970);
    $returnValue {"startTime"} = 
      formatToUniversalTime ($secondsSince1970 - (60 * 60 * 24 * 7));
    postevent ($key, \%returnValue);
    }
  elsif ($key eq "standardizeDate") {
    #displayGlishValue ($val, "\t");
    $fixedDateString = '';
    $fixedDateString = &fixDate ($val);
    # print "about to post: ", $fixedDateString, "\n";
    #displayGlishValue ($fixedDateString, "\t");
    postevent ($key, $fixedDateString);
    }
  else {
    print "got unrecognized event\n";
    postevent ($key,$returnValue);
    }
  ($key,$val,$attr) = nextevent ($type,$isrequest);
  }

# end of implicit main
#--------------------------------------------------------------------------
sub displayGlishValue {

  my($val) = @_[0];
  my($tab) = @_[1];

  if (ref($val) eq "HASH") {
    print "incoming glish value is a record\n";
    foreach $i (keys %$val) {
      if (ref ($$val{$i})) {
        print "$tab$i ->\n";
        displayGlishValue ($$val{$i},$tab."\t");
        } 
      else {
        print "$tab$i -> ",$$val{$i},"\n";
        }
      } # foreach
    } # if hash
  elsif (ref ($val) eq "ARRAY") {
    print "incoming glish value is an array\n";
    foreach $i (@$val) {
      print "$tab$i\n";
      }
    }
  else {
    print "incoming glish value is a scalar\n";
    print "$tab$val\n";
    }

} # displayGlishValue
#--------------------------------------------------------------------------
sub fixDate {
# transform '26' 'Nov' '1995' '17:40:30'
# into '11/26/1995,17:40:30'

  local (@dateString);
  local ($result);
  local ($monthName);
  local ($monthNumber);
  local ($dayString, $yearString, $timeString);

  $dateString = @_ [0];
  #print ("in sub fixDate ---------------\n");
  #displayGlishValue (@dateString,"\t");

  #print ("in sub fixDate ---------------\n");
  #foreach $s (@$dateString) {
  #  print $s, "\n";
  #  }

  $monthName = @$dateString [1];
  if ($monthName =~ /^jan/i) {
    $monthNumber = 1;
    }
  elsif ($monthName =~ /^feb/i) {
    $monthNumber = 2;
    }
  elsif ($monthName =~ /^mar/i) {
    $monthNumber = 3;
    }
  elsif ($monthName =~ /^apr/i) {
    $monthNumber = 4;
    }
  elsif ($monthName =~ /^may/i) {
    $monthNumber = 5;
    }
  elsif ($monthName =~ /^jun/i) {
    $monthNumber = 6;
    }
  elsif ($monthName =~ /^jul/i) {
    $monthNumber = 7;
    }
  elsif ($monthName =~ /^aug/i) {
    $monthNumber = 8;
    }
  elsif ($monthName =~ /^sep/i) {
    $monthNumber = 9;
    }
  elsif ($monthName =~ /^oct/i) {
    $monthNumber = 10;
    }
  elsif ($monthName =~ /^nov/i) {
    $monthNumber = 11;
    }
  elsif ($monthName =~ /^dec/i) {
    $monthNumber = 12;
    }
  else {  # todo: need an exception thrown here, or something....
    $monthNumber = 0;
    }

  $dayString = @$dateString [0];
  $yearString = @$dateString [2];
  $timeString = @$dateString [3];

  $result = '';
  $result = 
    sprintf ("%2d/%s/%s,%s", $monthNumber, $dayString, $yearString, $timeString);

  #print "perl result: ", $result, "\n";

  $result;
}
#--------------------------------------------------------------------------
sub formatToLocalTime {

  local ($secondsSince1970, $localTime, $dayOfWeek, $month,
         $dayOfMonth, $clockTime, $year, $formattedTime);

  $secondsSince1970 = @_ [0];

  $localTime = localtime ($secondsSince1970);
  $dayOfWeek = substr ($localTime, 0,3);
  $month = substr ($localTime, 4, 3);
  $dayOfMonth = substr ($localTime, 8, 2);

  if (substr ($dayOfMonth, 0, 1) eq ' ') { # transform ' 8' into '08'
    substr ($dayOfMonth, 0, 1) = '0';
    }

  $clockTime = substr ($localTime, 11, 8);
  $year = substr ($localTime, 20, 4);
  $formattedTime = 
       $dayOfMonth . " " . $month . " " . $year . " " . $clockTime;
  $formattedTime;

}
#--------------------------------------------------------------------------
sub formatToUniversalTime {

  local ($secondsSince1970, $universalTime, $dayOfWeek, $month,
         $dayOfMonth, $clockTime, $year, $formattedTime);

  $secondsSince1970 = @_ [0];

  $universalTime = gmtime ($secondsSince1970);
  $dayOfWeek = substr ($universalTime, 0,3);
  $month = substr ($universalTime, 4, 3);
  $dayOfMonth = substr ($universalTime, 8, 2);

  if (substr ($dayOfMonth, 0, 1) eq ' ') { # transform ' 8' into '08'
    substr ($dayOfMonth, 0, 1) = '0';
    }

  $clockTime = substr ($universalTime, 11, 8);
  $year = substr ($universalTime, 20, 4);
  $formattedTime = 
       $dayOfMonth . " " . $month . " " . $year . " " . $clockTime;
  $formattedTime;

}
#--------------------------------------------------------------------------
