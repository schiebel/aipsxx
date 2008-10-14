# tmisc: test the misc functions
#
#   Copyright (C) 1996,1997,1998,1999
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
#          Postal address: AIPS++/ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: tmisc.g,v 19.1 2004/08/25 01:35:47 cvsmgr Exp $
#

pragma include once;

include 'misc.g'

tmisc := function() 
{
    # tests misc functions
    print 'testing regex related misc functions';
    t := dms.escapespecial('#*()|');
    if (t != '\\#\\*\\(\\)\\|') throw('escapespecial failed');

    tstr := '  \t  \Hello World  \t  ';
    if (dms.stripleadingblanks(tstr) != 'Hello World  \t  ')
	throw('stripleadingblanks failed.');

    if (dms.striptrailingblanks(tstr) != '  \t  \Hello World')
	throw('striptrailingblanks failed.');

    tpat := 'abc*gh';
    if (len(dms.patternmatch(tpat, tstr))) throw('patternmatch failed');
    tpat := 'foo.{a[b-d],g*}';
    str := "foo.a foo.ac foo.ab foo.ag foo.f foo.abc foo.g foo.gwhatever";
    if (dms.patternmatch(tpat,str) != "foo.ac foo.ab foo.g foo.gwhatever") throw('patternmatch failed');

    print 'testing shellcmd - output will go to logger'
    if (!dms.shellcmd('ls -l')) throw('shellcmd failed');

    print 'testing file and related';
    # '.' should always exist
    if (!dms.fileexists('.')) throw('fileexists fails');

    # dir() can be excersized, but I'm not sure how to validate
    # the result.
    listing := dms.dir();

    # ditto on the parentdir()
    parent := dms.parentdir();

    # and the file types
    for (i in listing) ftype := dms.filetype(i);
    # readfile is not tested here
    # buf := dms.readfile('/home/sngldsh/bgarwood/data/galactic/g777.raw');

    sourcename := 'mySource';
    hour := 12;
    minute := 4;
    seconds := 42.3;
    fp := dms.fopen(fname,'w');
    dms.fprintf(fp,'Name %s at %2.2d%2.2d%4.1f\n',
	       sourcename, hour, minute, seconds);
    dms.fclose(fp);

    fp := dms.fopen(fname, 'r');
    a := dms.fgets(fp);
    dms.fclose(fp);
    if (a != 'Name mySource at 120442.3') throw('fgets failure');

    # not test for init and kill spinner

    print "ok";
    return T;
}
