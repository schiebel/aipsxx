# Copyright (C) 2000,2002 Associated Universities, Inc. Washington DC, USA.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 
# Correspondence concerning GBT software should be addressed as follows:
#		GBT Operations
#		National Radio Astronomy Observatory
#		P. O. Box 2
#		Green Bank, WV 24944-0002 USA

# $Id: testIARDS.g,v 19.0 2003/07/16 03:44:52 aips2adm Exp $

# Utilities for GBT antenna control

pragma include once

global go_aips2 := F;
global start_time := time()

#IARDS change: comment out the next line and uncomment out the 2nd line
#global iards_client_name := 'go_aips2_g';
global iards_client_name := '/home/aips++/weekly/linux/bin/gbtgoclient';
global iards_client_host := 'victor';

# this procedures attempts to test a spectral line scan

testSpecLine := function (howmany)
{
   for (i in 1:howmany) {
	   iards_type := 'Spectral Line'
	   iards ('standards_04', 23, 24, iards_type);
           print "testSpecLine Awaiting NEXT",i,time()-start_time
	   print alloc_info()
	   await go_aips2->NEXT
   }
}

go_aips2_status := function() 
{
    if (!is_agent(go_aips2) ) {
	print " ";
	print "go_aips2 client failed - client did not start";
	print " ";
	return;
    }
    if (!has_field(go_aips2,'active')){
	print " ";
	print "go_aips2 client failed to connect - no active field";
	print " ";
	return;
    }
    if (go_aips2.active == 0) {
	print " ";
	print "go_aips2 client no longer active";
	print " ";
	return;
    }
}

go_aips2_start := function()
{
    global go_aips2;
    go_aips2OK := F;


    go_aips2 := client(iards_client_name, host=iards_client_host);

    whenever go_aips2->established do {
	go_aips2OK := T;
	print " ";
	print "go_aips2 client started";
	print " ";
    }
    
    whenever go_aips2->fail, go_aips2->done do {
	# the client has ended
	go_aips2OK := F;
	# if you care how it ended
	if ($name == 'fail') {
	    print " ";
	    print "go_aips2 client failed";
	    print "     ",$value; 
	    print " ";
	} else {
	    print " ";
	    print "go_aips2 client stopped gracefully";
	    print " ";
	}
    }
}

iards := function(data_name, start_scan, last_scan, type_iards) {
    global go_aips2;
#    global __go_values;

    if (!is_agent(go_aips2)) {
	go_aips2_start();
	go_aips2_status();
    }				

#    real_time_display := getparameter('real_time_display');
#    if (is_boolean(real_time_display)) return F;

    full_name := spaste('\'/home/gbtdata/',data_name,'\'');
    print '\nRunning GOspec(',full_name,',',start_scan,')\n';
    go_aips2->iards([projectID=data_name,begin_scan=start_scan,
		     end_scan=last_scan, type=type_iards]);
    
    return T;
}

testGOpoint := function(howmany)
{
   for (i in 1:howmany) {
 	fit_lpc('standards_04',57,58);
        print "testGOpoint Awaiting NEXT",i,time()-start_time
	await go_aips2->NEXT
	fit_lpc('standards_04',59,60);
        print "testGOpoint Awaiting NEXT",i,time()-start_time
	print alloc_info()
	await go_aips2->NEXT
   }
}

run_test := function(howmany)
{
    for (i in 1:howmany) {
	testGOpoint(10000)
	testSpecLine(10000)
    }
}

fit_lpc := function(data_name, start_scan, last_scan) {
    global go_aips2;
    global __go_values;

    dLpc := [=];
    newLpc := [=];

    if (!is_agent(go_aips2)) {
	go_aips2_start();
	go_aips2_status();
    }

    full_name := spaste('\'/home/gbtdata/',data_name,'\'');
    print '\nRunning GOpoint(',full_name,',',start_scan,',',last_scan,')\n';
    go_aips2->run([projectID=data_name,begin_scan=start_scan,
		   end_scan=last_scan, auto='Yes']);
    dLpc := wait_for_result();
    print "result received =",dLpc;

    return T;
}

wait_for_result := function() {
    wait_update := create_agent();

    wait_z := client('timer', interval=120, oneshot=T);
    whenever wait_z->ready do {
	wait_z := 0;
	wait_update->end();
	wait_az := 0.;
	wait_el := 0.;
    }
    
    whenever go_aips2->result do {
	wait_az := $value.d_az;
	wait_el := $value.d_el;
	wait_z := 0;
	wait_update->end();
    }

    await wait_update->end;    
    print " ";
    print "d_az = ",wait_az;
    print "d_el = ",wait_el;
    return([d_az=wait_az, d_el=wait_el]);
}

