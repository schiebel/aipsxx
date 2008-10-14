# atoms.g: Access to ACC
# Copyright (C) 1999,2000
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: atoms.g,v 19.0 2003/07/16 03:34:26 aips2adm Exp $
#
pragma include once

include 'servers.g';
include 'aipsrc.g';
include 'timer.g';
include 'note.g';
include 'quanta.g';
include 'table.g';

#
##defaultservers.trace(T)
##defaultservers.suspend(T)
#
# Global methods
#
#
# Server
#
  const atoms := function(host='', forcenewserver = F) {
    if (is_defined("defaultatoms") && has_field(defaultatoms, 'connect')) {
      return const ref defaultatoms;
    };
    global system;
    private := [=];
    public := [=];
    private.agent := defaultservers.activate("atoms", host,
					     forcenewserver);

    if (is_fail(private.agent)) return F;
    private.id := defaultservers.create(private.agent, "atoms");
#
# Public methods
#
# Connect
#
    const public.connect := function(serv='captar00-ep') {
      wider private;
      connectRec :=		[_method="connect",
				_sequence=private.id._sequence];
      connectRec["arg"] := serv;
      private.served := serv;
      return defaultservers.run(private.agent, connectRec);
    }
#
# Connect captar00-ep
#
    const public.c00ep := function() {
      return public.connect('captar00-ep');
    }
#
# Connect captar02
#
    const public.c02 := function() {
      return public.connect('captar02');
    }
#
# Disconnect
#
    const public.disconnect := function(serv='') {
      wider private;
      disconnectRec :=		[_method="disconnect",
				_sequence=private.id._sequence];
      disconnectRec["arg"] := serv;
      private.served := serv;
      return defaultservers.run(private.agent, disconnectRec);
    }
#
# get pos from GetInfo
#
    const public.getpos := function() {
      getposRec :=		[_method="getpos",
				_sequence=private.id._sequence];
      return defaultservers.run(private.agent, getposRec);
    }      
#
# get short info
#
    const public.getshort := function() {
      getshortRec :=		[_method="getshort",
				_sequence=private.id._sequence];
      return defaultservers.run(private.agent, getshortRec);
    }      
#
# Get info
#
    const public.getinfo := function() {
      getinfoRec :=		[_method="getinfo",
				_sequence=private.id._sequence];
      return defaultservers.run(private.agent, getinfoRec);
    }
#
# Get name(s)
#
    const public.getname := function(t="status") {
      getnameRec :=		[_method="getname",
				_sequence=private.id._sequence];
      getnameRec.arg := t;
      return defaultservers.run(private.agent, getnameRec);
    }
#
# get short info names
#
    const public.getsnames := function() {
      getsnamesRec :=		[_method="getsnames",
				_sequence=private.id._sequence];
      return defaultservers.run(private.agent, getsnamesRec);
    }
#
# Read short info
#
    const public.readsinfo := function(lst=[0,2,1]) {
      readsinfoRec :=		[_method="readsinfo",
				_sequence=private.id._sequence];
      readsinfoRec.arg := lst;
      return defaultservers.run(private.agent, readsinfoRec);
    }
#
# Show info
#
    const public.showinfo := function(t=1.0) {
      wider private;
      global system;
      system.print.precision := 3;
      dq.setformat('lat', 'dms');
      dq.setformat('long', 'dms');
      private.frame := frame(title='ACC info');
      private.frame.f0 := frame(private.frame, side='left');
      private.frame.f0.serv := label(private.frame.f0, ' ',
				     relief='groove',
				     width=16);
      private.frame.f0.fill0 := frame(private.frame.f0);
      private.frame.f0.stamp := label(private.frame.f0, ' ',
				      background ='white', width=24);
      private.frame.f0a := frame(private.frame, side='left');
      private.frame.f0a.serv := label(private.frame.f0a, 'Estimate',
				      relief='groove',
				      width=16);
      private.frame.f0a.fill0 := frame(private.frame.f0a);
      private.frame.f0a.stamp := label(private.frame.f0a, ' ',
				       background ='white', width=24);
      private.frame.f1 := frame(private.frame, side='left');
      private.frame.f1.stat := label(private.frame.f1, 'Status', width=16);
      private.frame.f1.az := label(private.frame.f1, '90.0', width=16);
      private.frame.f1.el := label(private.frame.f1, '80.0', width=16);
      private.frame.f1a := frame(private.frame, side='left');
      private.frame.f1a.stat := label(private.frame.f1a, 'Request', width=16);
      private.frame.f1a.raz := label(private.frame.f1a, '90.0', width=16);
      private.frame.f1a.rel := label(private.frame.f1a, '80.0', width=16);
      private.frame.f1b := frame(private.frame, side='left');
      private.frame.f1b.stat := label(private.frame.f1b, 'Error', width=16);
      private.frame.f1b.raz := label(private.frame.f1b, '0.0', width=16);
      private.frame.f1b.rel := label(private.frame.f1b, '0.0', width=16);
      private.frame.f2 := frame(private.frame, side='left');
      private.frame.f2.cpu0 := label(private.frame.f2, 'CPU:  ');
      private.frame.f2.cpu1 := label(private.frame.f2, ' ', width = 24);
      private.frame.f2.mem0 := label(private.frame.f2, '  MEM:  ');
      private.frame.f2.mem1 := label(private.frame.f2, ' ', width = 24);
      private.frame.id := timer.execute(private.reinfo, t, oneshot=T);
      return T;
    }
#
# stop info
#
    const public.stopinfo := function() {
      wider private;
      if (has_field(private, 'frame') &&
	  has_field(private.frame, 'id')) {
	timer.remove(private.frame.id);
	private.frame := F;
      };
      return T;
    }
#
# re-show info at specified interval (1s default)
#
    const private.reinfo := function(t,u) {
      wider private;
      ## wider system;
      res := public.getinfo();
      private.frame.f0.serv->text(private.served);
      private.frame.f0.stamp->text(dq.time(res.stamp, form="ymd"));
      private.frame.f0a.stamp->text(dq.time(res.esttime, form="ymd"));
      private.frame.f1.stat->text(res.state);
      private.frame.f1.az->text(dq.form.long(dq.unit(res.pos.value[1],
						     res.pos.unit)));
      private.frame.f1.el->text(dq.form.lat(dq.unit(res.pos.value[2],
						    res.pos.unit)));
      private.frame.f1a.raz->text(dq.form.long(dq.unit(res.reqpos.value[1],
						       res.reqpos.unit)));
      private.frame.f1a.rel->text(dq.form.lat(dq.unit(res.reqpos.value[2],
						      res.reqpos.unit)));
      private.frame.f1b.raz->
	text(dq.form.long(dq.sub(dq.unit(res.pos.value[1],
					 res.pos.unit),
				 dq.unit(res.reqpos.value[1],
					 res.reqpos.unit))));
      private.frame.f1b.rel->
	text(dq.form.long(dq.sub(dq.unit(res.pos.value[2],
					 res.pos.unit),
				 dq.unit(res.reqpos.value[2],
					 res.reqpos.unit))));
      res := public.getname("cpu memory");
      ## a := system.print.precision;
      ## system.print.precision := 3;
      private.frame.f2.mem1->text(paste(res.memory[3]/1000000.,
					res.memory[4]/1000000.,
					'Mb'));
      private.frame.f2.cpu1->text(paste(res.cpu[1]*100.,
					res.cpu[2]*100.,
					'%'));
      ## system.print.precision := a;
      private.frame.id := timer.execute(private.reinfo, t, oneshot=T);
    }
#
# Test for connection
#
    public.test := function() {
      testconnectRec :=		[_method="testconnect",
				_sequence=private.id._sequence];
      return defaultservers.run(private.agent, testconnectRec);
    }
#
# Get short info into table name for ln seconds
#
    public.getsinfo := function(name='short', ln=120) {
      if (!public.test()) fail("No connection established");
      cnam := public.getsnames();
      if (length(cnam) < 3) fail("Not enough names");
      istat := 0;
      ipos := 0;
      irpos := 0;
      for (i in 1:length(cnam)) {
	if (cnam[i] == 'STATE') istat := i;
	if (cnam[i] == 'POS') ipos := i;
	if (cnam[i] == 'REQPOS') irpos := i;
      };
      if (istat*ipos*irpos == 0) fail("Incorrect names");
      ilst := [istat-1, ipos-1, irpos-1];
      if (tableexists(name)) {
	if (tableexists(spaste(name, '.old'))) {
	  tabledelete(spaste(name, '.old'));
	};
	tablerename(name, spaste(name, '.old'));
      };
      td0 := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
      td1 := tablecreatescalarcoldesc("STATE", 0, "IncrementalStMan");
      td2 := tablecreatescalarcoldesc("POSAZ", 0.0, "IncrementalStMan");
      td3 := tablecreatescalarcoldesc("POSEL", 0.0, "IncrementalStMan");
      td4 := tablecreatescalarcoldesc("RPOSAZ", 0.0, "IncrementalStMan");
      td5 := tablecreatescalarcoldesc("RPOSEL", 0.0, "IncrementalStMan");
      td6 := tablecreatescalarcoldesc("ERRAZ", 0.0, "IncrementalStMan");
      td7 := tablecreatescalarcoldesc("ERREL", 0.0, "IncrementalStMan");
      desc  := tablecreatedesc(td0, td1, td2, td3, td4, td5, td6, td7);
      global t;
      if (is_defined('t') && is_table(t)) t.close();
      t := table(name, tabledesc=desc, readonly=F);
      if (is_table(t)) {
	t.putkeyword('MJD0', as_double(0.0));
	t.putkeyword('DATE0', 'yyyy/mm/dd/hh:mm:ss.ttt');
	t.putkeyword('VS_CREATE', dq.time('today', prec=4, form="ymd clean"));
	t.putkeyword('VS_DATE', dq.time('today', prec=4, form="ymd clean"));
	t.putkeyword('VS_VERSION', sprintf('%09.4f', 1.001)); 
	t.putkeyword('VS_TYPE', 'Atoms info');
	t.putinfo([type='ATOMS', subType='shortinfo']);
      } else {
	fail("Cannot create short info table");
      };
# Count rows
      cnt := 0;
      while (cnt < 10*ln) {
	offmjd := 0.0;
	if (cnt != 0) offmjd := t.getkeyword('MJD0');
	aa := public.readsinfo(ilst);
	t.addrows(length(aa));
	if (length(aa) > 0) {
	  if (cnt == 0) {
	    offmjd := aa[1].stamp;
	    t.putkeyword('MJD0', as_double(offmjd));
	    t.putkeyword('DATE0', 
			 dq.time(dq.unit(t.getkeyword('MJD0'),'us'),
				 prec=9,form='ymd')); 	
	  };	  
	  for (i in 1:length(aa)) {
	    t.putcell('MJD', i+cnt, (aa[i].stamp - offmjd)/1.0e6); 
	    t.putcell('STATE', i+cnt, aa[i].state); 
	    t.putcell('POSAZ', i+cnt, aa[i].posaz/pi*180.); 
	    t.putcell('POSEL', i+cnt, aa[i].posel/pi*180.); 
	    t.putcell('RPOSAZ', i+cnt, aa[i].rposaz/pi*180.); 
	    t.putcell('RPOSEL', i+cnt, aa[i].rposel/pi*180.); 
	    t.putcell('ERRAZ', i+cnt, (aa[i].posaz - aa[i].rposaz)/pi*180.); 
	    t.putcell('ERREL', i+cnt, (aa[i].posel - aa[i].rposel)/pi*180.); 
	  };
	};
	cnt := t.nrows();
	if (length(aa) < 100) wait(10.0);
      };
      print 'Table short has now', t.nrows(), 'rows';
      return t;
    }
#
# End server constructor
#
    return ref public;

  } # constructor
#
# Create a defaultserver
#
      ;
  defaultatoms := atoms();
  const defaultatoms := defaultatoms;
  const dat := ref defaultatoms;
#
# Start-up messages
#
  if (!is_boolean(dat)) {
    note('defaultatoms (dat) ready', priority='NORMAL', 
	 origin='atoms');
  };

# Add defaultatoms to the GUI if necessary
if (any(symbol_names(is_record)=='objrepository') &&
    has_field(objrepository, 'notice')) {
	objrepository.notice('defaultatoms', 'atoms');
};



