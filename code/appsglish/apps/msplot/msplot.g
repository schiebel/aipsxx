# msplot.g: Display and interactively flag data from a measurement set
#
#   Copyright (C) 1998,1999,2000,2001,2002,2003
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
#   $Id: msplot.g,v 19.4 2005/01/27 23:10:34 gmoellen Exp $

pragma include once;

# The following must be here to define unset
include 'unset.g';
# The following include must be here to define ddlws
include 'ddlws.g';

#print 'DEBUGGING VERSION'

#msplot := function (ref msfile=unset, edit=F,
const msplot := function (ref msfile=unset, edit=F,
                          flagfile=unset,  nrows=unset,
                          displaywidth=600, displayheight=400,
                          widgetset=ddlws)
{
  if (!have_gui()) {
    return throw('msplot needs a windowing environment.\n',
                 'Perhaps the DISPLAY environment variable is not ',
                 'correctly set.', origin='msplot');
  }


  include 'table.g';
  include 'note.g';
  include 'widgetserver.g';

  include "quanta.g";
  include "measures.g";
  include "mathematics.g";
  include "ms.g";
  
  if (!is_unset(msfile) && !tableexists(msfile)) {
    return throw('measurement set named \'', msfile, '\' does not exist',
                 origin='msplot');
  }
  
  public  := [=];    # public functions
  private := [=];    # private data and helpers
  private.display := [=]; # functions and data used in raster mode.
  private.plot := [=];  # functions and data used by in plot mode.
  private.tools := [=]; # aips++ tools that are created are cached in here

  private.datatype := 'syn';
  private.stokes := ['I', 'Q', 'U', 'V', 'RR', 'RL', 'LR', 'LL',
                     'XX', 'XY', 'YX', 'YY', 'RX', 'RY', 'LX', 'LY',
                     'XR', 'XL', 'YR', 'YL', 'PP', 'PQ', 'QP', 'QQ',
                     'RCircular', 'LCircular', 'Linear',
                     'Ptotal', 'Plinear', 'PFtotal', 'PFlinear', 'Pangle'];
  private.stokes::shape[1] := length(private.stokes);
       
  if (!is_widgetserver(widgetset)) {
    return throw('The widgetset argument does not contain a widgetserver tool',
                 origin='msplot');
  }
  private.tools.widgetserver := widgetset;
  private.tools.guientry := private.tools.widgetserver.guientry(expand='x');
  private.lastplot := 'plotxy';
  
  private.filecount := 0;
  
  if (is_unset(nrows)) {
    private.nrows := 2E6;
  } else {
    private.nrows := nrows;
  }

  private.edit := edit;
  private.pausemode := 'Pause';
  
  private.increment := 1;
  
  private.displaywidth := displaywidth;
  private.displayheight := displayheight;
  
  private.angle := 0;
  private.nslices := 1;
  
#
# The frame for the GUI
#
  private.frames := [=];
  private.frames.top := F;
  
  private.isbusy := F;
  
  private.whenevers := [=];
  private.whenevers.default := [];
  private.whenevers.viewer := [];
  private.pushwhenever := function(category=unset) {
    wider private;
    if (is_unset(category)) {
      private.whenevers.default[len(private.whenevers.default) + 1] := 
        last_whenever_executed();
    } else {
      if (!has_field(private.whenevers, category)) {
        private.whenevers[category] := [];
      }
      private.whenevers[category][len(private.whenevers[category]) + 1] := 
        last_whenever_executed();
    }
  }
  
  private.deactivatewhenever := function(category=unset) {
    wider private;
    if (is_unset(category)) {
      deactivate private.whenevers.default;
      private.whenevers.default := [];
    } else {
      if (has_field(private.whenevers, category)) {
        deactivate private.whenevers[category];
        private.whenevers[category] := [];
      }
    }
  }

  private.initos := function() {
    wider private;
    include 'os.g';
    include 'serverexists.g';
    local usedefault := serverexists('defaultos', 'os', defaultos);
    if (usedefault) {
      private.tools.os := ref defaultos;
      private.tools.os::doneit := F;
    } else {
      private.tools.os := os();
      private.tools.os::doneit := T;
    }
    return usedefault;
  }

  private.donetools := function() {
    wider private;
    for (tool in "os") {
      if (has_field(private.tools, tool) && private.tools[tool]::doneit) {
        private.tools[tool].done();
      }
    }
  }

  private.closegui := function() {
    wider private;
    private.plot.donegui();
    private.display.donegui();
    private.tools.widgetserver.tk_hold();
    private.frames.top -> title('msplot: no measurement set');
    private.frames.top -> disable();
    private.filebutton -> enable();
    private.filemenu.openro -> enable();
    private.filemenu.openrw -> enable();
    private.donebutton -> enable();
    private.dismissbutton -> enable();
    private.filemenu.close -> disable();
    private.filemenu.show -> disable();
    private.tools.widgetserver.tk_release();
  }

#
# Because I cannot change the menu of a guientry.check widget I need
# to done the old widget and make a new one. This process is
# encapsulated here.
#
  private.redopolarizationgui := function(defaultpolid=unset) {
    wider private;
    private.operations['Polarization selection'].button.polid.selector.done();
    const ge := ref private.tools.guientry;
    local npol := length(private.data.polarization);
    local pollabels := array('', npol);
    for (p in 1:npol) {
      pollabels[p] := spaste(p, ': (', private.data.polarization[p], ')');
    }
    private.operations['Polarization selection'].button.polid.selector := 
      ge.choice(private.operations['Polarization selection'].frames.polid,
                options=pollabels, allowunset=T);
    if (!is_unset(defaultpolid)) {
      private.operations['Polarization selection'].button.polid.selector.
        insert(defaultpolid);
    } else {
      private.update.polarization(private.polid[1]);
    }
    whenever private.operations['Polarization selection'].button.polid.
      selector->value do {
        value := as_integer($value);
        ok := private.update.polarization(value);
        if (is_fail(ok)) {
          note('Selected polarization not changed.',
               origin='msplot', priority='SEVERE');
        }
      } private.pushwhenever();
  }

  private.opengui := function(edit) {
    wider private;
    private.tools.widgetserver.tk_hold();
# restore the state from the input table, otherwise set some defaults.
    if (private.restorestate() == F) { 
      local spw := unique(private.spwid);
      private.operations['Spectral selection'].button.spwid.selector.insert(spw);
      private.update.spectral(spw);
      private.redopolarizationgui();
    }
    {
      msname := private.ms.name();
      local access := '(read only)';
      if (edit) access := '(editable)';
      private.frames.top->title(paste('msplot: ', msname, access));
    }
    private.selectdatatype();
    {
      local cols := private.table.colnames();
      for (axis in "X Y Z") {
        if (!any(cols == 'CORRECTED_DATA')) {
          private.toolbar[axis].submenu.Data.submenu.What.button.corrected->disabled(T);
          private.toolbar[axis].submenu.Data.submenu.What.button.residual->disabled(T);
          private.toolbar[axis].submenu.Data.submenu.What.button.ratio->disabled(T);
          private.toolbar[axis].submenu.Data.submenu.What.button.observed->state(T);
          private.axis.Y := private.axes.amplitude;
          private.axis.Z := private.axes.amplitude;
        }
        if (!any(cols == 'MODEL_DATA')) {
          private.toolbar[axis].submenu.Data.submenu.What.button.model->disabled(T);
          private.toolbar[axis].submenu.Data.submenu.What.button.residual->disabled(T);
          private.toolbar[axis].submenu.Data.submenu.What.button.ratio->disabled(T);
          private.toolbar[axis].submenu.Data.submenu.What.button.observed->state(T);
          private.axis.Y := ref private.axes.amplitude;
          private.axis.Z := ref private.axes.amplitude;
        }
      }
    }
    
    private.frames.top->enable();
    private.filemenu.openro ->disable();
    private.filemenu.openrw ->disable();
    private.filemenu.close ->enable();
    private.filemenu.show ->enable();
    private.donebutton -> enable();
    private.donebutton -> enable();
    private.tools.widgetserver.tk_release();
  }

  private.lock := function(type='plot') {
    wider private;
    if (private.isbusy) {
      return F;
    }
    private.type := type;
    private.isbusy := T;
    private.frames.top->disable();
    private.action.stop->enable();
    private.frames.top->cursor('watch');
    if (private.type != 'top' && 
        has_field(private[private.type], 'topframe') &&
        is_agent(private[private.type].topframe)){
      private[private.type].topframe->map();
      private[private.type].topframe->cursor('watch');
    }
    return T;
  }

  private.unlock := function() {
    wider private;
    private.isbusy := F;
    private.frames.top->cursor('left_ptr');

    private.frames.top->enable();
    if (private.type != 'top' && has_field(private[private.type], 'topframe')){
      private[private.type].topframe->cursor('left_ptr');
    }
    return T;
  }
#
# Stop an executing iteration ?
#
  private.stop := F;
  
  private.stopnow := function() {
    wider private;
    if (private.stop) {
      note('Stopping at your request', priority='WARN',
           origin='msplot.stopnow');
      private.stop := F;
      private.unlock();
      return T;
    }
    if (private.pausemode == 'Pause') {
      include 'choice.g';
      local ch := choice('msplot: Continue to next plot?',
                         choices=['yes', 'stop', 'do not ask again'],
                         types=['action', 'halt', ''],
                         timeout=30);
      if (ch == 'stop') {
        private.stop := T;
        private.unlock();
        return T;
      } else if (ch == 'yes') {
        return F;
      } else {
        private.pausemode := 'Continue';
        private.action.pause.selectvalue(private.pausemode);
        return F;
      }
    } else {
      return F;
    }
    return F;
  }
#
# Various allowed types
#
  private.showtypes.all := ['Plot X vs Y',
                            'Plot UV Coverage',
                            'Plot Y versus reprojected U axis',
                            'Plot Longitude, Latitude Coverage',
                            'Plot Y versus reprojected Longitude axis',
                            'Display data as an image',
                            'Summarize MS in logger',
                            'List MS to logger'];
  
  private.showtypes.syn := ['Plot X vs Y',
                               'Plot UV Coverage',
                               'Plot Y versus reprojected U axis',
                               'Display data as an image',
                               'Summarize MS in logger'];
#                              'List MS to logger'];
  
  private.showtypes.sd := ['Plot X vs Y',
                           'Plot Longitude, Latitude Coverage',
                           'Plot Y versus reprojected Longitude axis',
                           'Display data as an image',
                           'Summarize MS in logger'];
#                             'List MS to logger'];
  
  private.rangetypes := "antenna1 antenna2 antennas feed1 feed2 field_id fields ifr_number scan_number time u v w uvdist";
  
  private.plottypes.syn := "antenna1 antenna2 feed1 feed2 field_id ifr_number scan_number time channel frequency u v w uvdist weight data";
  
  private.plottypes.sd := "antenna1 antenna2 feed1 feed2 field_id scan_number time data";
  
  private.plottypes.all := "antenna1 antenna2 feed1 feed2 field_id ifr_number scan_number time channel frequency u v w uvdist weight data";
  
  private.viswhats.syn := "observed corrected model residual ratio";
  
  private.visvalues.syn := "amplitude phase real imaginary";
  
  private.viswhats.sd := "observed";
  
  private.visvalues.sd := "float_data";
  
  private.viswhats.all := "observed corrected model residual ratio";
  
  private.visvalues.all := "amplitude phase real imaginary float_data";
  
  private.selecttypes.syn := "zerospacing antennas ifr_number feeds fields u v w uvdist scan_number time";
  
  private.selecttypes.sd := "antennas feeds fields scan_number time";
  
  private.selecttypes.all := "zerospacing antennas ifr_number feeds fields scan_number u v w uvdist time";
  
  private.selectlabels.syn := ['Show Zero Spacing', 'Antennas',
                                  'Interferometer Number', 
                                  'Feeds', 'Field Id',
                                  'U', 'V', 'W', 'Uvdist',
                                  'Scan Number', 'Time'];
  
  private.selectlabels.sd := ['Antennas', 
                                 'Feeds', 'Field Id', 'Scan Number',
                                 'Time'];
  
  private.selectlabels.all := ['Show Zero Spacing', 'Antennas', 'Interferometer Number', 
                                  'Feeds', 'Field Id', 'Scan Number', 
                                  'U', 'V', 'W', 'Uvdist', 'Time'];
  
  private.types.spectral := [nchan='scalar', start='scalar',
                                inc='scalar'];
  
  private.labels.spectral := [nchan='Number of output (plotted) channels NCHAN=',
                                 start='Input channel START=',
                                 inc='Input channel STEP='];
  if (!private.edit) {
    # Flagging with averaged channels is not supported (yet);
    private.labels.spectral.width := 'Input channel WIDTH (to average)=';
    private.types.spectral.width := 'scalar';
  }
  
  private.selectiontypes := ['X, Y plot limits', 'Data selection', 'Spectral selection',
                             'Polarization selection'];
  
  private.iterationlabels := ['Antenna1', 'Antenna2', 'Spectral Window/Polarization Id',
                              'Feed1', 'Feed2',
                              'Field Id', 'Scan Number', 'Time'];
#
# Data
#
  private.data := [=];
#
# Deleted the selected MS
#
  private.deleteselectedms := function() {
    wider private;
    if (has_field(private, 'selectedms') && is_ms(private.selectedms)) {
      selectedmsname := private.selectedms.name();
      private.selectedms.done();
      ok := tabledelete(selectedmsname, checksubtables=T, ack=F);
      if (is_fail(ok)) {
        return throw('Cannot delete the selected ms called ',
                     selectedmsname, '. Error was:\n',
                     ok::message, origin='msplot.deleteselectedms');
      }
    }
  }
#
# Deleted any temporary images
#
  private.display.deleteimages := function() {
    wider private;
    # deactivate all whenevers associated with the current display data.
    private.deactivatewhenever('viewer');
    # Shut down the display data's. Otherwise it will hold a lock on
    # the image.
    if (has_field(private, 'viewerdd') &&
        is_record(private.viewerdd) &&
        has_field(private.viewerdd, 'done') && 
        is_function(private.viewerdd.done)) {
#      private.viewerdp.unregister(private.viewerdd);
      private.viewerdd.done();
      timer.wait(0.5);
    }
# Now delete the images. The image names are assumed to exist in
# private.display.imagename[] & private.display.imagenameall
    if (has_field(private, 'display')) {
      if (has_field(private.display, 'imagenameall') &&
          is_string(private.display.imagenameall) && 
          tableexists(private.display.imagenameall)) {
        local imagename := private.display.imagenameall;
        local ok := tabledelete(imagename, checksubtables=T, ack=F);
        if (is_fail(ok)) {
          return throw('Cannot delete the scratch image called ',
                       imagename, '. Error was:\n',
                       ok::message, origin='msplot.deleteimages');
        }
      }
      if (has_field(private.display, 'imagename') && 
          length(private.display.imagename) > 0) {
        local nimages := length(private.display.imagename);
        for (i in 1:nimages) {
          local imagename := private.display.imagename[i];
          if (is_string(imagename) && tableexists(imagename)) {
            local ok := tabledelete(imagename, checksubtables=T, ack=F);
            if (is_fail(ok)) {
              return throw('Cannot delete the scratch image called ',
                           imagename, '. Error was:\n',
                           ok::message, origin='msplot.deleteimages');
            }
          }
        }
      }
    }
  }
#
# Plot definition
#
  private.makeplot := function () {
    plot := [=];
    plot.axis := [=];
    plot.label := [=];
    plot.values := [=];
    plot.npages := 0;
    plot.scales := [=];
    plot.ready := F;
    plot.npoints := 0;
    return plot;
  }
  private.thisplot := private.makeplot();
  
  
  private.generatefilename := function(base=unset, ext='') {
    wider private;
    originalbase := base;
    if (is_unset(base) || !is_string(base)) {
      base := 'msplot';
    }
    include 'quanta.g';
    base := spaste(base, '.', 
                   split(dq.time(dq.quantity('today'),
                                 form="dmy local"), '/')[1]);
    base := spaste(base, ':', private.filecount);
    private.filecount := private.filecount + 1;
    if (len(ext) > 0) {
      base := spaste(base, '.', ext);
    }
    private.initos();
    if (private.tools.os.fileexists(base)) {
      return private.generatefilename(originalbase, ext);
    } else {
      return base;
    }
  }
  
  #
  # Define the edit commands
  #
  private.defineeditcommands := function() {
    wider private;
    
    private.display.busy := F;
    private.display.select := [=];
    private.display.select.records := [=];
    private.display.select.nrecords := 0;
    
    private.display.select.start := function() {
      wider private;
      private.display.select.records := [=];
      private.display.select.nrecords := 0;
      return T;
    }

    private.display.select.clear := function() {
      wider private;
      private.display.select.records := [=];
      private.display.select.nrecords := 0;
      return T;
    }
    
    private.display.select.addquery := function(taql, english) {
      wider private;
      local n := private.display.select.nrecords;
      if (!has_field(private.display.select.records[n], 'taql')||
          private.display.select.records[n].taql == '') {
        private.display.select.records[n].taql := taql;
        private.display.select.records[n].english := english;
      } else {
        private.display.select.records[n].taql := 
          spaste(private.display.select.records[n].taql, '&&',
                 taql);
        private.display.select.records[n].english := 
          spaste(private.display.select.records[n].english,
                 ' AND ', english);
      }
      private.display.select.records[n].valid := T;
    }
    
    private.display.select.addchannels := function(value) {
      wider private;
      local n := private.display.select.nrecords;
      private.display.select.records[n].valid := T;
      private.display.select.records[n].channels := value;
    }
    
    private.display.select.addcorrelations := function(value) {
      wider private;
      local n := private.display.select.nrecords;
      private.display.select.records[n].valid := T;
      private.display.select.records[n].correlations := value;
    }
    
    private.display.select.next := function() {
      wider private;
      local nrec := length(private.display.select.records);
      private.display.select.nrecords := nrec + 1;
      if (nrec > 0) {
        for (i in 1:nrec) {
          if (!private.display.select.records[i].valid) {
            private.display.select.nrecords := i;
            break;
          }
        }
      }
      if (private.display.select.nrecords > nrec) {
        private.display.select.records[private.display.select.nrecords] :=
          [correlations=[], channels=[], taql='', english='', valid=F];
      }
    }
    
    private.display.select.edit := function() {
      wider private;
      
      # First get the current selection
      local fullquery := '';
      local nq := 0;
      local tempdir := private.tempdir();
      if (is_fail(tempdir)) fail;
      local flagmsname := spaste(tempdir, '.selectedtoflag');
      tabledelete(flagmsname, ack=F);
      local before := 0;
      local beforerows := 0;
      local after := 0;
      local afterrows := 0;
      local numshapes := length(unique(private.data.spectral.numchan));
      for (rec in private.display.select.records) {
        if (is_record(rec) && has_field(rec, 'valid') && rec.valid &&
            strlen(rec.taql) > 0 ) {
          nq +:= 1;
          local flagms;
          if (numshapes == 1) {
            flagms :=
              private.ms.command(flagmsname, rec.taql, readonly=F);
          } else {
            flagms := 
              private.selectedms.command(flagmsname, rec.taql, readonly=F);
          }
          local flagdata := flagms.getdata("FLAG FLAG_ROW");
          before +:= sum(flagdata.flag);
          beforerows +:= sum(flagdata.flag_row);
          if (length(rec.channels) > 0) {
            if (length(rec.correlations) > 0) {
              flagdata.flag[rec.correlations, rec.channels,] := 
                private.display.flag;
            } else {
              flagdata.flag[,rec.channels,] := private.display.flag;
            }
          } else {
            if (length(rec.correlations) > 0) {
              flagdata.flag[rec.correlations,,] := private.display.flag;
            } else {
              flagdata.flag[,,] := private.display.flag;
            }
          }
          for (r in ind(flagdata.flag[1,1,])) {
            flagdata.flag_row[r] := all(flagdata.flag[,,r]);
          }
          after +:= sum(flagdata.flag);
          afterrows +:= sum(flagdata.flag_row);
          flagms.putdata(flagdata);
          flagdata := F;
          flagms.done();
          tabledelete(flagmsname, ack=F);
        }
      }
      if (nq == 0) {
        note('Cannot flag data as no data has been selected.', 
             priority='WARN', origin='msplot.display.select.edit');
        return 0;
      } else {
        if (numshapes > 1) {
          note('Cannot apply the flags to the entire measurement set ',
               'as the data shape varies.\nApplying the flagging commands ',
               'to the selected (displayed) portion of the measurement set ',
               'only.', priority='WARN',origin='msplot.display.select.edit');
        }
        private.flagged := T;
      }
      if (after > before) {
        note('Flagged ', after-before, ' data points',
             origin='msplot.display.select.edit');
      } else if (after < before) {
        note('Unflagged ', before-after, ' data points ',
             origin='msplot.display.select.edit');
      } else {
        note('Flagged no data', priority='WARN',
             origin='msplot.display.select.edit');
      }
      private.display.select.records := [=];
      return nq;
    }
    
    private.display.select.cancel := function() {
      wider private;
      local n :=  private.display.select.nrecords;
      if (n <= 0) return T;
      for (i in n:1) {
        if (private.display.select.records[i].valid) { 
          private.display.select.records[i] :=
            [correlations=[], channels=[], taql='', english='', valid=F];
          private.display.status->
            post(spaste('Deleting the last edit command (number ', i, ')'));
          break;
        }
      }
      return T;
    }
    
    private.display.select.listone := function(which=unset) {
      wider private;
      local n := private.display.select.nrecords;
      if (!is_unset(which)) n := which;
      local rec := private.display.select.records[n];
      if (is_record(rec) && has_field(rec, 'valid') && rec.valid) {
        note('Defined editing command ', n, 
             origin='msplot.display.select.listone');
        channels := rec.channels;
        channels::print.limit := 10;
        if (length(channels) > 0) {
          note('   channels    : ', channels,
               origin='msplot.display.select.listone');
        }
        if (length(rec.correlations) > 0) {
          # Its assumed that all displayed data descriptions
          # correspond have the same polarisation id (otherwise how do
          # you label the correlation axis). So I only need to find
          # out what one of these data descriptions is.
          local sampledd := private.display.dd[1];
          local corrnames := private.data.polarization[private.polid[sampledd]];
          note('   correlations: ', corrnames[rec.correlations],
               origin='msplot.display.select.listone');
        }
        note('   query       : ', rec.english,
             origin='msplot.display.select.listone');
        return T;
      }
      return F;
    }
    
    private.display.select.list := function() {
      wider private;
      somevalid := F;
      for (n in 1:private.display.select.nrecords) {
        somevalid |:= private.display.select.listone(n);
      }
      if (!somevalid) {
        note('No editing commands', origin='msplot.display.select.list');
      }
      return F;
    }
    
    private.plot.busy := F;
    private.plot.select := [=];
    private.plot.select.nrecords := 0;
    private.plot.select.records := [=];
    
    private.plot.select.addregion := function(blc, trc) {
      wider private;
      local tblc := [min(blc[1], trc[1]), min(blc[2], trc[2])];
      local ttrc := [max(blc[1], trc[1]), max(blc[2], trc[2])];
      const n := private.plot.select.nrecords;
      private.plot.select.records[n].valid := T;
      private.plot.select.records[n].region := [blc=tblc, trc=ttrc];
      local ci := private.plot.pgplotter.qci();
      local fs := private.plot.pgplotter.qfs();
      private.plot.pgplotter.sfs(4);
      private.plot.pgplotter.sci(3);
      private.plot.pgplotter.rect(tblc[1], ttrc[1], tblc[2], ttrc[2]);
      private.plot.pgplotter.sci(ci);
      private.plot.pgplotter.sfs(fs);
      if (n > 0) {
        private.plot.status->post(spaste('Finished edit command ', n));
      }
      private.plot.select.nrecords +:= 1;
      private.plot.select.records[private.plot.select.nrecords] :=
	[region=[blc=F, trc=F], valid=F];
    }
    
    private.plot.select.cancel := function() {
      wider private;
      const n := private.plot.select.nrecords;
      if (n > 1) {
        private.plot.status->post(spaste('Cancelled edit command ', n));
      }
      local blc := private.plot.select.records[n].region.blc;
      local trc := private.plot.select.records[n].region.trc;
      local ci := private.plot.pgplotter.qci();
      local fs := private.plot.pgplotter.qfs();
      private.plot.pgplotter.sfs(4);
      private.plot.pgplotter.sci(15);
      private.plot.pgplotter.rect(blc[1], trc[1], blc[2], trc[2]);
      private.plot.pgplotter.sci(ci);
      private.plot.pgplotter.sfs(fs);
      private.plot.select.records[n] := [region=[blc=F, trc=F], valid=F];
      private.plot.select.list();
    }
    
    private.plot.select.cancelall := function() {
      wider private;
      for (i in 1:length(private.plot.select.nrecords)) {
        blc := private.plot.select.records[i].region.blc;
        trc := private.plot.select.records[i].region.trc;
        ci := private.plot.pgplotter.qci();
        fs := private.plot.pgplotter.qfs();
        private.plot.pgplotter.sfs(4);
        private.plot.pgplotter.sci(15);
        private.plot.pgplotter.rect(blc[1], trc[1], blc[2], trc[2]);
        private.plot.pgplotter.sci(ci);
        private.plot.pgplotter.sfs(fs);
      }
      private.plot.select.editing := T;
      private.plot.select.records := [=];
      private.plot.select.nrecords := 1;
      private.plot.select.records[1] := [region=[blc=F, trc=F], valid=F];
    }
    
    private.plot.select.list := function() {
      wider private;
      local somevalid := F;
      local i := 0;
      for (rec in private.plot.select.records) {
        if (is_record(rec) && has_field(rec, 'valid') && rec.valid) {
          somevalid := T;
          note('Editing command ', i, origin='msplot.plot.select.list');
	  local action := 'flag';
          if (!private.plot.flag) action := 'unflag';
	  note('   Will ', action, ' all points in the region:',
	       origin='msplot.plot.select.list');
          note('   blc: ', rec.region.blc, origin='msplot.plot.select.list');
          note('   trc: ', rec.region.trc, origin='msplot.plot.select.list');
        }
      }
      if (!somevalid) {
        note('No valid records to list', origin='msplot.plot.select.list');
      } else {
        note('End of editing commands', origin='msplot.plot.select.list');
      }
      return F;
    }
    
    private.plot.callbacks.button1 := function(rec) {
      wider private;
      if (!private.plot.busy) {
        private.plot.select.done := F;
        private.plot.select.blc := rec.world;
        private.plot.pgplotter.cursor('rect', color=1, 
				      x=rec.world[1], y=rec.world[2]);
      }
    }

    private.plot.callbacks.buttonup := function(rec) {
      wider private;
      if (!private.plot.busy) {
        private.plot.select.done := T;
        private.plot.select.trc := rec.world;
        private.plot.select.addregion(private.plot.select.blc,
                                      private.plot.select.trc);
        private.plot.pgplotter.cursor('norm');
        private.plot.status->post(paste('Region is ', private.plot.select.blc,
					'to ', private.plot.select.trc));
      }
    }
    
    private.plot.select.start := function() {
      wider private;
      if (private.thisplot.npages == 1) {
        private.plot.topmodeframe->map();
      } else {
        private.plot.status->post('Editing not possible for multipage plots: change selection and try again');
      }
      private.plot.select.editing := T;
      private.plot.select.records := [=];
      private.plot.select.nrecords := 1;
      private.plot.select.records[1] := [region=[blc=F, trc=F], valid=F];
      for (what in field_names(private.plot.callbacks)) {
	local cbnum := private.plot.callbacknumbers[what];
	private.plot.pgplotter.activatecallback(cbnum);
      }
      return T;
    }
    
    private.plot.select.clear := function() {
      wider private;
      const ci := private.plot.pgplotter.qci();
      const fs := private.plot.pgplotter.qfs();
      private.plot.pgplotter.sfs(4);
      private.plot.pgplotter.sci(15);
      for (i in 1:length(private.plot.select.records)) {
        local blc := private.plot.select.records[i].region.blc;
        local trc := private.plot.select.records[i].region.trc;
        private.plot.pgplotter.rect(blc[1], trc[1], blc[2], trc[2]);
      }
      private.plot.pgplotter.sci(ci);
      private.plot.pgplotter.sfs(fs);
      private.plot.select.start();
    }
    
    private.plot.select.stop := function() {
      wider private;
      private.plot.select.editing := F;
      if (is_record(private.plot.pgplotter)) {
        for (what in field_names(private.plot.callbacks)) {
	  local cbnum := private.plot.callbacknumbers[what]
          private.plot.pgplotter.deactivatecallback(cbnum);
        }
      }
      return T;
    }
  }

  private.plot.save := function(file) {
    wider private;
    if (is_record(private.plot.pgplotter)&&
       has_field(private.plot.pgplotter, 'postscript')) {
      if (is_unset(file) || !is_string(file)) {
        file := private.generatefilename(ext='plot');
      }
      note('Writing plot table ', file, origin='msplot.plot.save');
      private.plot.pgplotter.plotfile(file);
    }
  }
  
  private.plot.print := function(file) {
    wider private;
    if (is_record(private.plot.pgplotter)&&
       has_field(private.plot.pgplotter, 'postscript')) {
      if (is_unset(file) || !is_string(file)) {
        file := private.generatefilename(ext='plot');
      }
      note('Writing postscript file ', file, origin='msplot.plot.print');
      private.plot.pgplotter.postscript(file);
      include 'printer.g';
      private.printer := printer();
      private.printer.gui(files=file);
    }
  }
#
# Editing routines
#
  private.defineeditcommands();
#
# Formatting routines
#
  private.world :=[=];
  
  private.world.print :=[=];
  private.world.print.generic := function (value) {
    if (is_unset(value)) return "<unset>";
    if (is_numeric(value)) {
      return sprintf('%g', value);
    } else {
      return sprintf('%s', as_string(value));
    }
  }
  private.world.print.ifr_number := function (value) {
    if (is_unset(value)) return "<unset>";
    ant1 := as_integer(as_integer(value)/1000);
    ant2 := as_integer(as_integer(value) - 1000*ant1);
    if (has_field(private.data.antenna, 'name')) {
      name1 := private.data.antenna.name[ant1];
      name2 := private.data.antenna.name[ant2];
      station1 := private.data.antenna.station[ant1];
      station2 := private.data.antenna.station[ant2];
      return sprintf('Ant1 Id: %4d (name %s, station %s) Ant2 Id: %4d (name %s, station %s)',
                     ant1, name1, station1, ant2, name2, station2);
    } else {
      return sprintf('Antenna1 Id: %4d Antenna2 Id: %4d', ant1, ant2);
    }
  }
  private.world.print.packed_ifr_number := function (value) {
    if (is_unset(value)) return "<unset>";
    value := as_integer(value);
    if (value<1) value:=1;
    if (value>len(private.ranges.ifr_number)) value:=len(private.ranges.ifr_number);
    avalue := private.ranges.ifr_number[value];
    ant1 := as_integer(as_integer(avalue)/1000);
    ant2 := as_integer(as_integer(avalue) - 1000*ant1);
    if (has_field(private.data.antenna, 'name')) {
      name1 := private.data.antenna.name[ant1];
      name2 := private.data.antenna.name[ant2];
      station1 := private.data.antenna.station[ant1];
      station2 := private.data.antenna.station[ant2];
      return sprintf('Ant1 Id: %4d (name %s, station %s) Ant2 Id: %4d (name %s, station %s)',
                     ant1, name1, station1, ant2, name2, station2);
    } else {
      return sprintf('Antenna1 Id: %4d Antenna2 Id: %4d', ant1, ant2);
    }
  }
  private.world.print.packed_row := function (value) {
    if (is_unset(value)) return "<unset>";
    value := as_integer(value);
    if (value<1) value:=1;
    if (value>len(private.data.packedtimes)) value:=len(private.data.packedtimes);
    avalue := private.data.packedtimes[value];
    dd := private.display.dd[value];
    ff := private.display.ff[value];
    fn := private.fieldnames[ff];
    spw := private.spwid[dd];
    pol := private.polid[dd];
    return sprintf ('%g Time: %s Data Desc Id: %d Spec Win Id: %d Pol Id: %d Field: %s', value,
                    avalue, dd, spw, pol, fn);
  }
  private.world.print.time := function (value) {
    if (is_unset(value)) return "<unset>";
    return sprintf('%s', dq.time(dq.quantity(value, 's'), form='ymd'));
  }
  private.world.print.Row := private.world.print.packed_row;
  private.world.print.Interferometer := private.world.print.packed_ifr_number;

  private.world.print.Channel := function(value) {
    return spaste('value ', value);
    # the value is between 0 and nChan - 1
#    if (is_unset(value)) return "<unset>";
#    chan := as_integer(value+1.5);
#    avalue := private.world.freqs[chan]; 
#    return sprintf ('%g   Frequency: %g Hz', chan, avalue);
  }

  private.world.print.Correlation := function(value) {
    return spaste('value ', value);
#    wider private;
#    if (is_unset(value)) return "<unset>";
#    pol := as_integer(value+0.5);
#    avalue := private.data.polarization[pol];
#    return sprintf ('%g   Polarization: %s', pol, avalue);
  }
  
  private.world.toindex :=[=];
  private.world.toindex.generic := function (value) {
    if (is_unset(value)) return unset;
    return as_integer(value+0.5);
  }

  private.world.toindex.ifr_number := function (value) {
    if (is_unset(value)) return unset;
    local ifr_number := private.display.ifr_number[value];
    ant := [=];
    ant.ant1 := as_integer(ifr_number/1000);
    ant.ant2 := ifr_number - 1000*ant[1];
    return ant;
  }

  private.world.toindex.packed_ifr_number := function (value, value2=unset) {
    wider private;
    if (is_unset(value)) return unset;
    value := as_integer(value+1.5-1E-7);
    if (!is_unset(value2)) {
      value2 := as_integer(value2+1.5-1E-7);
      value := seq(value, value2);
    }   
    return private.world.toindex.ifr_number(value);
  }

  private.world.toindex.packed_row := function (value) {
    if (is_unset(value)) return unset;
    value := as_integer(value+0.5);
    if (value<1) value:=1;
    if (value>len(private.data.packedtimes)) value:=len(private.data.packedtimes);
    return private.data.packedtimes[value];
  }
  
  private.world.toindex.time := function (value) {
    if (is_unset(value)) return unset;
    return dq.time(dq.quantity(value+0.5, 's'), form='ymd');
  }
  
  private.world.from :=[=];
  private.world.from.generic := function (value) {
    return value;
  }
  private.world.from.ifr_number := function (value) {
    return value;
  }
  private.world.from.packed_ifr_number := function (value) {
    if (is_unset(value)) return "<unset>";
    value := as_integer(value);
    if (value<1) value:=1;
    if (value>len(private.ranges.ifr_number))
        value:=len(private.ranges.ifr_number);
    return private.ranges.ifr_number[value];
  }
  private.world.from.packed_row := function (value) {
    value := as_integer(value);
    if (value<1) value:=1;
    if (value>len(private.data.packedtimes)) value:=len(private.data.packedtimes);
    return private.world.from.time(private.data.packedtimes[value]);
  }
  private.world.from.time := function (value) {
    result := dq.convert(dq.quantity(value,'s'));
    if (is_record(result)&&has_field(result, 'value')) {
      return result.value;
    } else {
      return 'Error';
    }
  }
#
# Add an axis to the definitions
#
  private.addaxis := function(name, label='', type='generic', help='',
                              selecthelp='', units='') {
    
    wider private;
    private.axes[name]:= [=];
    private.axes[name].name := name;
    private.axes[name].label:=label;
    private.axes[name].type:=type;
    private.axes[name].help:=help;
    private.axes[name].selecthelp:=selecthelp;
    private.axes[name].printworld:= ref private.world.print[type];
    private.axes[name].fromworld:= ref private.world.from[type];
    private.axes[name].worldtoindex:= ref private.world.toindex[type];
    private.axes[name].offset:=0;
    private.axes[name].min:=F;
    private.axes[name].max:=F;
    private.axes[name].units:=units;
    return T;
  }
#
# Define all the axes we know about
#
  private.axes := [=];
  
  private.addaxis("amplitude", "Observed data amplitude", units="Jy");
  private.addaxis("corrected_amplitude", "Corrected data amplitude", units="Jy");
  private.addaxis("model_amplitude", "Model data amplitude", units="Jy");
  private.addaxis("residual_amplitude", "Residual data amplitude", units="Jy");
  private.addaxis("ratio_amplitude", "Data ratio amplitude");
  private.addaxis("antenna1", "Antenna1", selecthelp='Required value(s) of antenna1 (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("antenna2", "Antenna2", selecthelp='Required value(s) of antenna2 (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("antennas", "Antennas", selecthelp='Required value(s) of antennas (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("polarization_id", "Polarization id", selecthelp='Required value(s) of the polarization_id (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("spectral_window_id", "Spectral Window id", selecthelp='Required value(s) of the spectral_window_id (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("frequency", "Frequency",units="GHz");
  private.addaxis("channel", "Channel");
  private.addaxis("data", "Observed data data");
  private.addaxis("corrected_data", "Corrected data data", units="Jy");
  private.addaxis("model_data", "Model data data", units="Jy");
  private.addaxis("residual_data", "Residual data data", units="Jy");
  private.addaxis("ratio_data", "Data ratio data");
  private.addaxis("float_data", "Total power data");
  private.addaxis("feeds", "Feeds", selecthelp='Required value(s) of feed1 and feed2 (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("feed1", "Feed1", selecthelp='Required value(s) of feed1 (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("feed2", "Feed2", selecthelp='Required value(s) of feed2 (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("field_id", "Field id", selecthelp='Required value(s) of field_id (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("fields", "Fields", selecthelp='Required value(s) of field_id (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("ifr_number", "Interferometer", type="ifr_number", selecthelp='Required value(s) of ifr_number (1000*antenna1+antenna2) (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("packed_ifr_number", "Interferometer", type="packed_ifr_number", selecthelp='Required value(s) of ifr_number (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("imaginary", "Observed imaginary data", units="Jy");
  private.addaxis("corrected_imaginary", "Corrected imaginary data", units="Jy");
  private.addaxis("model_imaginary", "Model imaginary data", units="Jy");
  private.addaxis("residual_imaginary", "Residual imaginary data", units="Jy");
  private.addaxis("ratio_imaginary", "Data ratio imaginary");
  private.addaxis("imaging_weight", "Imaging weight");
  private.addaxis("phase", "Observed data phase", units='degrees');
  private.addaxis("corrected_phase", "Corrected data phase", units='degrees');
  private.addaxis("model_phase", "Model data phase", units='degrees');
  private.addaxis("residual_phase", "Residual data phase", units='degrees');
  private.addaxis("ratio_phase", "Data ratio phase");
  private.addaxis("phase_dir", "Phase directions");
  private.addaxis("real", "Observed real data", units="Jy");
  private.addaxis("corrected_real", "Corrected real data", units="Jy");
  private.addaxis("model_real", "Model real data", units="Jy");
  private.addaxis("residual_real", "Residual real data", units="Jy");
  private.addaxis("ratio_real", "Data ratio real");
  private.addaxis("ref_frequency", "Reference frequency", units="Hz");
  private.addaxis("packed_row", "Row", type='packed_row');
  private.addaxis("scan_number", "Scan number", selecthelp='Required value(s) of scan_number (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("time", "Time", type="time", selecthelp='Required range of time in measures format e.g. 1998/07/22:15:53.05.000 1998/07/22:16:53.05.000 (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("xr", "Rotated X (arcsec)");
  private.addaxis("ur", "Rotated U", units='m');
  private.addaxis("u", "U", selecthelp='Required range of u (Press Range button to get range of values from the MeasurementSet.)', units='m');
  private.addaxis("v", "V", selecthelp='Required range of v (Press Range button to get range of values from the MeasurementSet.)', units='m');
  private.addaxis("w", "W", selecthelp='Required range of w (Press Range button to get range of values from the MeasurementSet.)', units='m');
  private.addaxis("uvdist ", "UV Distance", selecthelp='Required range of UV distance (Press Range button to get range of values from the MeasurementSet.)', units='m');
  private.addaxis("weight", "Data weight");
  private.addaxis("data", "data", units='Jy');
  private.addaxis("zerospacing", "Show Zero Spacing", selecthelp='Show zero spacing in plots of synthesis data?');
  private.addaxis("longitude", "Longitude", selecthelp='Required range of longitude (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("longituder", "Rotated Longitude", selecthelp='Required range of rotated longitude (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("latitude", "Latitude", selecthelp='Required range of latitude (Press Range button to get range of values from the MeasurementSet.)');
  private.addaxis("w", "W", selecthelp='Required range of w (Press Range button to get range of values from the MeasurementSet.)', units='m');
#
# Default axes
#
  private.axis:=[=];
  
  if (private.datatype == 'syn') {
    private.axis.X := private.axes.uvdist;
    private.axis.Y := private.axes.corrected_amplitude;
    private.axis.Z := private.axes.corrected_amplitude;
  } else {
    private.axis.X := private.axes.time;
    private.axis.Y := private.axes.float_data;
    private.axis.Z := private.axes.float_data;
  }
  
#
# Copy the flag columns from the ms to a separate table
#
  private.saveflaginfo := function() {
    wider private;
    flagcoldesc :=
      tablecreatearraycoldesc('FLAG', F, ndim=2,
                              datamanagertype='TiledShapeStMan',
                              datamanagergroup='flag');

    flagrowcoldesc := 
      tablecreatescalarcoldesc('FLAG_ROW', F, 
                               datamanagertype='StandardStMan',
                               datamanagergroup='flag_row');

    flagtabledesc := tablecreatedesc(flagrowcoldesc, flagcoldesc);
    tabledefinehypercolumn(flagtabledesc, 'flag', 3, 'FLAG');
    local flagdmi := [=];
    local msdmi :=  private.table.getdminfo();
    for (d in ind(msdmi)) {
      if (any(msdmi[d].COLUMNS == 'FLAG')) break;
    }
    flagdmi[1] := [TYPE='TiledShapeStMan',
                   NAME='flag',
                   SPEC=msdmi[d].SPEC,
                   COLUMNS='FLAG'];
    local totalrows := private.table.nrows();
    flagtable := table(private.flagfile, flagtabledesc, totalrows,
                       dminfo=flagdmi, lockoptions='permanent', readonly=F,
                       ack=F);

    if (!is_table(flagtable)) {
      return throw('Cannot create the flag table called', flagfile, ':',
                   flagtable::message, origin='msplot.saveflaginfo');
    }
    local stepsize := 4096;
    if (has_field(flagdmi[1].SPEC, 'DEFAULTTILESHAPE') &&
        is_integer(flagdmi[1].SPEC.DEFAULTTILESHAPE) &&
        length(flagdmi[1].SPEC.DEFAULTTILESHAPE) > 0) {
      lastdim := length(flagdmi[1].SPEC.DEFAULTTILESHAPE);
      stepsize := flagdmi[1].SPEC.DEFAULTTILESHAPE[lastdim];
    }
    local bar := F;
    if (totalrows > 10*stepsize) {
      include 'progress.g';
      bar := progress(0, totalrows, 'Flags copied',
                      minlabel = '0', maxlabel=as_string(totalrows));
    }
    local cols := "FLAG_ROW FLAG";
    local tabledesc := private.table.getdesc();
    for (startrow in seq(1, totalrows, stepsize)) {
      if (is_record(bar)) bar.update(startrow);
      local nrows := stepsize;
      if (startrow + nrows > totalrows) {
        nrows := totalrows - startrow + 1;
      }
      for (col in cols) {
        local sr := startrow;
        local coldesc := tabledesc[col];
        local isarray := 
          has_field(coldesc, 'ndim') && is_integer(coldesc.ndim) &&
            (coldesc.ndim > 0);
        if (isarray) {
          local flagshapes :=
            private.table.getcolshapestring(col, startrow, nrows);
          if (any(flagshapes != flagshapes[1])) { 
            for (r in 1:(nrows-1)) {
              if (flagshapes[r] != flagshapes[r+1]) {
                local rowstocopy := r-sr+startrow;
                local flags := private.table.getcol(col, sr, rowstocopy);
#               note('Copied ', rowstocopy, ' rows of column ', col,
#                    ' starting at ', sr);
                ok := flagtable.putcol(col, flags, sr, rowstocopy);
                if (is_fail(ok)) fail;
                sr := startrow + r;
                nrows -:= rowstocopy;
              }
            }
          }
        }
        local flags := private.table.getcol(col, sr, nrows);
#       note('Copied ', nrows, ' rows of column ', col, ' starting at ', sr);
        ok := flagtable.putcol(col, flags, sr, nrows);
        if (is_fail(ok)) fail;
      }
    }
    if (is_record(bar)) bar.update(totalrows);
    flagtable.putkeyword('Measurement Set', private.table.name());
    flagtable.done();
    private.flagged := F;
    return T;
  }

  private.restoreflaginfo := function(keepflags=F) {
    wider private;
      private.flagfile;
    if (private.flagged == F) return T;
    local flagtable := table(private.flagfile, lockoptions='permanent',
                             readonly=F);
    if (!is_table(flagtable)) {
      return throw('Cannot open the table called ', private.flagfile, 
                   origin='msplot.restoreflaginfo');
    }
    if (all(flagtable.keywordnames() != 'Measurement Set') ||
        all(flagtable.colnames() != 'FLAG') ||
        all(flagtable.colnames() != 'FLAG_ROW')) {
      return throw('The table called ', private.flagfile, 
                   ' does not appear to be a flag table.',
                   origin='msplot.restoreflaginfo');
    }
    if ((flagtable.getkeyword('Measurement Set') != private.table.name()) || 
        (flagtable.nrows() != private.table.nrows())) {
      return throw('The table called ', private.flagfile, 
                   ' does not correspond with the current measurement set',
                   origin='msplot.restoreflaginfo');
    }
    # Close the ms and re-open it at the end so that the new flags are seen
    private.ms.done();

    local flagdmi := flagtable.getdminfo();
    local cols := "FLAG_ROW FLAG";
    local totalrows := private.table.nrows();
    local stepsize := 4096;
    if (has_field(flagdmi[1].SPEC, 'DEFAULTTILESHAPE') &&
        is_integer(flagdmi[1].SPEC.DEFAULTTILESHAPE) &&
        length(flagdmi[1].SPEC.DEFAULTTILESHAPE) > 0) {
      lastdim := length(flagdmi[1].SPEC.DEFAULTTILESHAPE);
      stepsize := flagdmi[1].SPEC.DEFAULTTILESHAPE[lastdim];
    }
    local bar := F;
    if (totalrows > 10*stepsize) {
      include 'progress.g';
      bar := progress(0, totalrows, 'Flags copied',
                      minlabel = '0', maxlabel=as_string(totalrows));
    }
    local tabledesc := private.table.getdesc();
    for (startrow in seq(1, totalrows, stepsize)) {
      if (is_record(bar)) bar.update(startrow);
      local nrows := stepsize;
      if (startrow + nrows > totalrows) {
        nrows := totalrows - startrow + 1;
      }
      for (col in cols) {
        local sr := startrow;
        local coldesc := tabledesc[col];
        if (has_field(coldesc, 'ndim') && is_integer(coldesc.ndim) &&
            (coldesc.ndim > 0)) {
          local flagshapes :=
            private.table.getcolshapestring(col, startrow, nrows);
          if (any(flagshapes != flagshapes[1])) { 
            for (r in 1:(nrows-1)) {
              if (flagshapes[r] != flagshapes[r+1]) {
                local rowstocopy := r-sr+startrow;
                local oldflags := flagtable.getcol(col, sr, rowstocopy);
                if (keepflags) {
                  local newflags := private.table.getcol(col, sr, rowstocopy);
                  flagtable.putcol(col, newflags, sr, rowstocopy);
                }
#               note('Copied ', rowstocopy, ' rows of column ', col,
#                    ' starting at ', sr, origin='msplot.restoreflaginfo');
                private.table.putcol(col, oldflags, sr, rowstocopy);
                sr := startrow + r;
                nrows -:= rowstocopy;
              }
            }
          }
        }
        local oldflags := flagtable.getcol(col, sr, nrows);
        if (keepflags) {
          local newflags := private.table.getcol(col, sr, nrows);
          flagtable.putcol(col, newflags, sr, nrows);
        }
#       note('Copied ', nrows, ' rows of column ', col, ' starting at ', sr,
#            origin='msplot.restoreflaginfo');
        private.table.putcol(col, oldflags, sr, nrows);
      }
    }
    if (is_record(bar)) bar.update(totalrows);
    flagtable.done();
    private.table.flush();
    private.ms := ms(private.table.name(), lock=F, readonly=!private.edit);
    return T;
  }
#
# Close the ms. Assumes that the data files are open.
#
  private.close := function () {
    wider private;
    
    private.savestate();
    if (private.edit) {
      if (private.flagged) {
        include 'choice.g';
        local keepflags := choice('Keep new flags?', "yes no", 
                                  timeout=30);
        if (keepflags == 'yes') {
          note('The initial flags of this measurement set are saved in the ',
               private.flagfile, ' table.\nThe msplotapplyflags ',
               'function can be used to replace the flags in this ',
               'measurement set\nwith the ones you started with ',
               'if you need to back out of your edits.',
               origin='msplot.close');
        } else {
          note('The flags you just made will be saved in the ',
               private.flagfile, ' table.\nThe msplotapplyflags ',
               'function can be used to replace the flags in this ',
               'measurement set\nwith the ones you just created.',
               origin='msplot.close');
          if (is_fail(private.restoreflaginfo(keepflags=T))) fail;
        }
      } else {
        note('Deleting the unused flag table called ', private.flagfile,
             origin='msplot.close');
        tabledelete(private.flagfile, ack=F);
      }
    }

# Done the table object
    private.table.done();

# done the main ms first in case the selected ms is a reference
    msname := private.ms.name();
    private.ms.done();
    private.taql := '<unset>';
    note ('Closed the measurement set called ', msname, '.',
          origin='msplot.close');
# Delete the scratch selected ms.
    private.deleteselectedms();
# Disable all the irrelevant bits of the gui
    private.closegui();
    return T;
  }

  private.savestate := function(label='lastsave') {
    wider private;
    rec := [=];
    rec.msname := private.ms.name();
    rec.increment := private.action.increment.get();
    for (field in private.selectiontypes) {
      for (entry in field_names(private.operations[field].button)) {
        if (has_field(private.operations[field].button[entry].selector,
                      'get')) {
          rec[entry] := private.operations[field].button[entry].selector.get();
        }
      }
    }
    include 'inputsmanager.g';
    inputs.savevalues('msplot', 'gui', rec, label, dosave=T);
    if (has_field(private.display, 'ddoptions')) {
      inputs.savevalues('msplot', 'display', private.display.ddoptions,
                        label, dosave=T);
    }
    return T;
  }
#
# restore the inputs from a saved table. Returns F if there where no
# inputs to restore.
#
  private.restorestate := function(label='lastsave', checkms=T) {
    wider private;
    include 'inputsmanager.g';
    rec :=  inputs.getvalues('msplot', 'gui', label);
    if (length(rec) == 0) return F;
    local msname := private.ms.name();
    if (has_field(rec, 'msname') && rec.msname != msname) {
      if (checkms) {
        return F;
      } else {
        note('Restoring parameters last used for the measurement set named:\n',
             rec.msname, '.\nPlease check parameters are still valid for ',
             'the current measurement set called:\n', msname,priority='WARN');
      }
    }
    if (has_field(rec, 'increment')) {
      private.action.increment.insert(rec.increment);
    }
    for (entry in field_names(rec)) {
      for (field in private.selectiontypes) {
        if (any(field_names(private.operations[field].button) == entry)) {
          if (has_field(private.operations[field].button[entry].selector,
                        'insert')) {
            if (entry !='polid') {
              private.operations[field].button[entry].selector.
                insert(rec[entry]);
            } else {
              private.redopolarizationgui(rec[entry]);
            }
          }
        }
      }
    }
    private.display.ddoptions := inputs.getvalues('msplot', 'display', label);
    return T;
  }
#
# ReOpen the ms if necessary
#
  private.checkdatachanged := function () {
  
    wider private;
  
#
# Check for data changed
#
    if (has_field(private, 'table') && is_table(private.table)) {
      if (private.table.datachanged()) {
        note('Another tool has added columns: reopening the Measurement Set',
             priority='WARN');
        return T;
      } else {
        return F;
      }
    }
  
# done the main ms first in case the selected ms is a reference
    if (has_field(private, 'ms') && is_ms(private.ms)) {
      private.ms.done();
    }
    private.deleteselectedms();

    private.ms := ms(private.table.name(), lock=F, readonly=!private.edit);
    if (!is_ms(private.ms)) {
      return throw( paste("cannot open ", file));
    }
    private.flagged:=F;
  
    private.datachanged := private.table.datachanged();
  
#
# Now disable the columns that do not exist or which
# we cannot access
#
    cols := private.table.colnames();
    tpexists := any(cols == 'FLOAT_DATA');
    if (tpexists) {
      note('Total power data found');
    }

    const ws := ref private.tools.widgetserver;
    ws.tk_hold();
    for (axis in "X Y Z") {
    
      private.toolbar[axis].submenu.Data.submenu.Value.button.float_data->disabled(!tpexists);
    
      exists := any(cols == 'CORRECTED_DATA');
      private.toolbar[axis].submenu.Data.submenu.What.button.corrected->disabled(!exists);
      private.toolbar[axis].submenu.Data.submenu.What.button.residual->disabled(!exists);
      private.toolbar[axis].submenu.Data.submenu.What.button.ratio->disabled(!exists);
      private.toolbar[axis].submenu.Data.submenu.What.button.observed->state(!exists);
    
      exists := any(cols == 'MODEL_DATA');
      private.toolbar[axis].submenu.Data.submenu.What.button.model->disabled(!exists);
      private.toolbar[axis].submenu.Data.submenu.What.button.residual->disabled(!exists);
      private.toolbar[axis].submenu.Data.submenu.What.button.ratio->disabled(!exists);
      private.toolbar[axis].submenu.Data.submenu.What.button.observed->state(!exists);
    }
    ws.tk_release();
  
  
    return T;
  }
#
# Initialise the msplot tool using the supplied ms.  whichms must be
# either a string or an ms tool. It is assumed that msplot is not
# already attached to a file.
#
   private.open := function(whichms, edit, flagfile) {
    wider private;
# The input can be either an ms tool or a filename.
    private.edit := F;
    if (is_ms(whichms)) {
      private.ms := whichms;
      note('Attached to the measurement set called ', whichms.name(), '.',
           origin='msplot.open');
    } else {
      if (!is_string(whichms) || length(whichms) != 1) {
        return throw('The measurement name specified is not a string.',
                     origin='msplot.open');
      }
      if (!tableexists(whichms)) {
        return throw('The specified measurement set does not exist.',
                     origin='msplot.open');
      }
      private.edit := edit;
      private.ms := ms(whichms, lock=F, readonly=!private.edit);
      if (is_ms(private.ms)) {
        local access := 'readonly';
        if (private.edit) access := 'read/write';
        note('Opened the measurement set called ', whichms, ' for ', access,
             ' access.', origin='msplot.open');
      } else {
        message := spaste('Cannot open the measurement set called \'', 
                          whichms, '\'.');
        if (is_fail(private.ms)) {
          message := spaste(message, ' The error was:\n', private.ms::message);
        }
        return throw(message, origin='msplot.open');
      }
    }
    local msname := private.ms.name();
# send a summary to the logger (to distract the user while we do some work)
    private.ms.summary();
# No flagging done (yet).
    if (private.edit == T && is_unset(flagfile)) {
      for (i in 1:100) {
        flagfile := spaste(msname, '.flags.', i);
        if (!tableexists(flagfile)) break;
      }
    }
    private.flagfile := flagfile;
    private.flagged := F;
# The table tool is used for raw access to the MS and its subtables.
    private.table := table(msname, readonly=!private.edit, ack=F);
    if (!is_table(private.table)) {
      return throw('Cannot open ', msname, ' as a table.', 
                   origin='msplot.open');
    }
# Mark the current state of the main table so we can detect any changes.
    private.datachanged := private.table.datachanged();
# Data description info
    local ddtable := table(spaste(msname, '/DATA_DESCRIPTION'),
                           readonly=T, ack=F);
    if (!is_table(ddtable)) {
      return throw ('Cannot open ', msname, '/DATA_DESCRIPTION as a table.',
                    origin='msplot.open');
    }
    private.spwid := ddtable.getcol('SPECTRAL_WINDOW_ID') + 1;
    private.polid := ddtable.getcol('POLARIZATION_ID') + 1;
    private.datadescid := 1:length(private.spwid);
    ddtable.done();
# Spectral window info
    local spwtable := table(spaste(msname, '/SPECTRAL_WINDOW'),
                            readonly=T, ack=F);
    if (!is_table(spwtable)) {
      return throw ('Cannot open ', msname, '/SPECTRAL_WINDOW as a table.',
                    origin='msplot.open');
    }
    private.data.spectral := [=];
    private.data.spectral.numchan := spwtable.getcol('NUM_CHAN');
    local reffreq := spwtable.getcol('REF_FREQUENCY');
    reffreq::print.precision := 6;
    for (r in ind(reffreq)) {
      private.data.spectral.name[r] := spaste(reffreq[r]/1E6, 'MHz');
    }
    reffreq := F;
    spwtable.done();
# Antenna info
    private.data.antenna := [=];
    local anttable := table(spaste(msname, '/ANTENNA'), readonly=T, ack=F);
    if (!is_table(anttable)) {
      note('No antenna information available', priority='WARN',
           origin='msplot.open');
    } else {
      private.data.antenna.station := anttable.getcol('STATION');
      private.data.antenna.name := anttable.getcol('NAME');
      anttable.done();
    }
# Pointing info
    private.data.pointing := [=];
    local pnttable := table(spaste(msname, '/POINTING'), readonly=T, ack=F);
    if (!is_table(pnttable)) {
      note('No pointing information available', priority='WARN',
           origin='msplot.open');
    } else {
      if (!all(pnttable.getcol('NUM_POLY') == 0)) {
        note('Cannot handle directions that vary with time.\n',
             'Pointing table ignored.', priority='WARN', origin='msplot.open');
      } else {
        private.data.pointing.target := pnttable.getcol('TARGET');
        private.data.pointing.direction := pnttable.getcol('DIRECTION');
        private.data.pointing.time := pnttable.getcol('TIME');
        private.data.pointing.interval := pnttable.getcol('INTERVAL');
      }
      pnttable.done();
    }
# Field info
    private.data.field := [=];
    local fldtable := table(spaste(msname, '/FIELD'), readonly=T, ack=F);
    if (!is_table(fldtable)) {
      note('No field information ie. field names or positions available',
           priority='WARN', origin='msplot.open');
    } else {
      private.data.fld.name := fldtable.getcol('NAME');
      if (all(strlen(private.data.fld.name) == 0)) {
        local refdir := fldtable.getcol('REFERENCE_DIR');
        include 'quanta.g';
        local nflds := shape(refdir)[3]
        if (nflds > 0) {
          for (r in 1:nflds) {
            local lat := dq.quantity(refdir[1,1,r], 'rad');
            local long := dq.quantity(refdir[2,1,r], 'rad');
            private.data.fld.name[r] := spaste(dq.time(lat, 6), ',' ,
                                            dq.angle(lat, 6));
          }
        }
      }
      fldtable.done();
    }
# Observation info
    private.data.obs := [=];
    local obstable := table(spaste(msname, '/OBSERVATION'), readonly=T, ack=F);
    if (!is_table(obstable)) {
      note('No observation information ie. OBSERVER, TELESCOPE available',
           priority='WARN', origin='msplot.open');
    } else {
      private.data.obs.telescope_name := obstable.getcol('TELESCOPE_NAME');
      private.data.obs.observer := obstable.getcol('OBSERVER');
      private.data.obs.project := obstable.getcol('PROJECT');
      obstable.done();
    }
# Polarization info
    local poltable := table(spaste(msname, '/POLARIZATION'),
                            readonly=T, ack=F);
    if (!is_table(poltable)) {
      return throw ('Cannot open ', msname, '/POLARIZATION as a table.',
                    origin='msplot.open');
    }
    local npols := poltable.nrows();
    if (npols < 1) {
      return throw ('No polarization setups defined.', origin='msplot.open');
    }
    private.data.polarization := [=];
    for (p in 1:npols) {
      local poldata := poltable.getcell('CORR_TYPE', p);
      private.data.polarization[p] := private.stokes[poldata];
    }
    poltable.done();
# Copy the current flags to another table
    if (private.edit) private.saveflaginfo();
# Update the ranges. Here we get the limited subset that we need
    local result := private.getranges();
    if (is_fail(result)) fail;
    private.ranges := result;
    private.datatype := 'syn';
    if (private.ranges.uvdist[2] == 0.0) private.datatype := 'sd';
    private.fields := private.ranges.field_id;
    private.fieldnames := private.ranges.fields;
# Update the current state of the gui now that we know something about the ms.
    private.opengui(private.edit);
    return T;
  }
#
# Call back function to display the world coordinates in
# an appropriate format
#
  private.plot.getworldcoords := function(rec) {
    wider private;
    ret := [=];
#
# Now we can calculate X, Y world coordinates
#
    ret.X := paste(private.thisplot.axis.X.label,
                   private.thisplot.axis.X.printworld(private.thisplot.axis.X.offset+rec.world[1]));
    ret.Y := paste(private.thisplot.axis.Y.label,
                      private.thisplot.axis.Y.printworld(private.thisplot.axis.Y.offset+rec.world[2]));
    return ret;
  }

  private.plot.worldcoords := function(rec) {
    wider private;
    # Need to lock out this motion callback when active otherwise
    # the events become jumbled
    if (!private.worldcbactive) {
      private.worldcbactive := T;
      ret := private.plot.getworldcoords(rec);
      for (axis in "X Y") {
        if (has_field(private.plot.feedback.world, axis)) {
          width := private.plot.feedback.world[axis].frame->width();
          private.plot.feedback.world[axis].message->width(0.75*width);
          private.plot.feedback.world[axis].message->text(ret[axis]);
        }
      }
      private.worldcbactive := F;
    }
  }

  private.display.getzcoord := function(rec) {
    wider private;
    ret := [=];
    if (has_field(private.display, 'ddoptions')) {
      zname := private.display.ddoptions.zaxis.value;
      ret.Z := paste(zname, private.world.print[zname](rec));
      return ret;
    } else {
      return [Z=''];
    }
  }

  private.display.worldcoords := function(rec) {
    wider private;
    local displayaxes := "xaxis yaxis";
    for (i in ind(displayaxes)) {
      local axisname := private.display.ddoptions[displayaxes[i]].value;
      if (axisname == 'Interferometer_Number') {
        local nifr := length(private.display.ifr_number);
        local index := private.display.lineartoindex(rec.linear[i], nifr);
        local ants := private.world.toindex.ifr_number(index);
        local antnames := [''];
        antnames[1] := private.data.antenna.name[ants[1]];
        antnames[2] := private.data.antenna.name[ants[2]];
        local statnames := [''];
        statnames[1] := private.data.antenna.station[ants[1]];
        statnames[2] := private.data.antenna.station[ants[2]];
        local ifrstring := spaste(private.display.ifr_number[index],
                                  ' (',  antnames[1], '=', statnames[1],
                                  ',',  antnames[2], '=', statnames[2], ')');
        private.display.feedback.ifr.message -> text(ifrstring);
      } else if (axisname == 'Time') {
        local slot := as_integer(rec.world[i]+0.5-1E-7);
        slot := max(slot, 1); # At the lower edge rec.world[i] == 0
        local fieldnum := private.display.ff[slot];
        local fieldname := spaste(fieldnum, ' (', 
                                  private.data.fld.name[fieldnum], ')');
        private.display.feedback.field.message -> text(fieldname);
        local dd := private.display.dd[slot];
        local spwnum := private.spwid[dd];
        local spwname := spaste(spwnum, ' (', 
                                private.data.spectral.name[spwnum], ')');
        private.display.feedback.spw.message -> text(spwname);
        local time := private.data.packedtimes[slot];
        private.display.feedback.time.message -> text(time);
      }
    }
    return T;
  }

  private.display.zcoord := function(rec) {
    wider private;
    # Need to lock out this motion callback when active otherwise
    # the events become jumbled
#    print 'private.display.zcoord: stubbed';
#     if (!private.display.busy&&!private.worldcbactive) {
#       private.worldcbactive := T;
#       ret := private.display.getzcoord(rec);
#       width := private.display.feedback.world.Z.frame->width();
#       private.display.feedback.world.Z.message->width(0.75*width);
#       private.display.feedback.world.Z.message->text(ret.Z);
#       private.worldcbactive := F;
#     }
  }

  private.display.nametoindex:=function(name) {
    wider private;
    for (i in ind(private.display.axisnames)) {
      if (private.display.axisnames[i] == name) return i;
    }
    return throw('Cannot flag ', name, ' on this view: try the other view',
                 origin='msplot.nametoindex');
  }

  private.display.lineartoindex := function(linear, maxval) {
    pvalue := as_integer(linear+1.5-1E-7);
    return min(maxval, max(1, pvalue));
  }

  private.display.callbacks.Antenna := function(rec, axis) {
    wider private;
    local nifr := length(private.display.ifr_number);
    if (is_record(rec) && rec.type == 'point') {
      rec := private.display.lineartoindex(rec.linear[axis], nifr);
    }
    if (!is_record(rec)) {
      local ant := private.world.toindex.ifr_number(rec);
      private.display.select.
        addquery(spaste('((ANTENNA1==',ant[1]-1,')||',
                        '(ANTENNA2==',ant[1]-1,'))'),
                 spaste('Antenna = ', ant[1]));
      private.display.status->
        postnoforward(spaste('Selected antenna ', ant[1]));
    } else if (rec.type == 'box') {
      local pvalue1 :=
        private.display.lineartoindex(rec.linear.blc[axis], nifr);
      local pvalue2 :=
        private.display.lineartoindex(rec.linear.trc[axis], nifr);
      local ant := private.world.toindex.ifr_number(seq(pvalue1, pvalue2));
      local ant1 := [];
      for (i in ind(ant[1])) {
        ant1 := [ant1, ant[1]];
      }
      ant1 := unique(ant1);
      local query := '(';
      local message := '';
      for (i in ind(ant1)) {
        if (i > 1) {
          query := spaste(query, '||');
          message := spaste(message, ', ');
        }
        query := spaste(query, '(ANTENNA1==', ant1[i]-1,'||',
                        'ANTENNA2==', ant1[i]-1, ')');
        message := spaste(message, ant1[i]);
      }
      query := spaste(query, ')');
      private.display.select.
        addquery(query, spaste('Antennas = ', message));
      private.display.status->
        postnoforward(spaste('Selected antennas ', message));
    }
    return T;
  }

  private.display.callbacks.Interferometer_Number := function(rec, axis) {
    wider private;
    local nifr := length(private.display.ifr_number);
    if (is_record(rec) && rec.type == 'point') {
      rec := private.display.lineartoindex(rec.linear[axis], nifr);
    }
    if (!is_record(rec)) {
      local ant := private.world.toindex.ifr_number(rec);
      private.display.select.
        addquery(spaste('((ANTENNA1==',ant[1]-1,'&&ANTENNA2==',ant[2]-1,')||',
                        '(ANTENNA1==',ant[2]-1,'&&ANTENNA2==',ant[1]-1,'))'),
                 spaste('Interferometer = ', ant[1], '-', ant[2]));
      private.display.status->
        postnoforward(spaste('Selected interferometer ', ant[1], '-', ant[2]));
    } else if (rec.type == 'box') {
      local pvalue1 :=
        private.display.lineartoindex(rec.linear.blc[axis], nifr);
      local pvalue2 :=
        private.display.lineartoindex(rec.linear.trc[axis], nifr);
      local ant := private.world.toindex.ifr_number(seq(pvalue1, pvalue2));
      local query := '(';
      local message := '';
      for (i in ind(ant[1])) {
        if (i > 1) {
          query := spaste(query, '||');
          message := spaste(message, ', ');
        }
        query := spaste(query, '(ANTENNA1==', ant.ant1[i]-1, 
                        '&&ANTENNA2==',ant.ant2[i]-1, ')||',
                        '(ANTENNA2==', ant.ant1[i]-1, 
                        '&&ANTENNA1==',ant.ant2[i]-1, ')');
        message := spaste(message, ant.ant1[i], '-', ant.ant2[i]);
      }
      query := spaste(query, ')');
      private.display.select.
        addquery(query, spaste('Interferometer = ', message));
      private.display.status->
        postnoforward(spaste('Selected interferometers ', message));
    }
    return T;
  }

  private.display.callbacks.Time := function(rec, axis) {
    wider private;
    local nslots := length(private.data.packedtimes);
    if (is_record(rec) && rec.type == 'point') {
      rec := private.display.lineartoindex(rec.linear[axis], nslots);
    }
    if (!is_record(rec)) {
      local time := private.display.times[rec];
      time::print.precision := 16;
      local timesting := private.data.packedtimes[rec];
      private.display.select.
        addquery(spaste('(near(TIME, ', time, ', 2.0e-12))'),
                 spaste('Time = ', timestring));
      private.display.status->postnoforward(spaste('Selected time ', 
						   timestring));
    } else if (rec.type == 'box') {
      local pvalue1 :=
        private.display.lineartoindex(rec.linear.blc[axis], nslots);
      local pvalue2 :=
        private.display.lineartoindex(rec.linear.trc[axis], nslots);
      local start := private.display.times[pvalue1];
      start::print.precision := 16;
      local stop := private.display.times[pvalue2];
      stop::print.precision := 16;
      local startstring := private.data.packedtimes[pvalue1];
      local stopstring := private.data.packedtimes[pvalue2];
      const tol := 1E-3;
      private.display.select.
        addquery(spaste('(TIME in [{', start-tol, ',', stop+tol, '}])'),
                 spaste('time between ', startstring, ' and ', stopstring));
      private.display.status->
        postnoforward(spaste('Selected timerange ', startstring, 
			     ' to ', stopstring));
    }
    return T;
  }

  private.display.callbacks.Data_Descriptions := function(rec, axis) {
    wider private;
    local nslots := length(private.display.dd);
    if (is_record(rec) && rec.type == 'point') {
      rec := private.display.lineartoindex(rec.linear[axis], nslots);
    }
    local dd;
    if (!is_record(rec)) {
      dd := private.display.dd[rec];
    } else if (rec.type == 'box') {
      local pvalue1 :=
        private.display.lineartoindex(rec.linear.blc[axis], nslots);
      local pvalue2 :=
        private.display.lineartoindex(rec.linear.trc[axis], nslots);
      dd := unique(private.display.dd[seq(pvalue1, pvalue2)]);
    }
    if (length(dd) == 1) {
      private.display.select.
        addquery(spaste('(DATA_DESC_ID==', dd-1, ')'),
                 spaste('Selected data description ', dd));
      private.display.status->
        postnoforward(spaste('Selected data description ', dd));
    } else {
      private.display.select.
        addquery(spaste('(DATA_DESC_ID IN ', as_evalstr(dd-1), ')'),
                 spaste('Selected data descriptions ', dd));
      private.display.status->
        postnoforward(spaste('Selected data descriptions ', dd));
    }
    return T;
  }

  private.display.callbacks.Channel := function(rec, axis) {
    wider private;
    local nchan := length(private.display.channels);
    if (is_record(rec) && rec.type == 'point') {
      rec := private.display.lineartoindex(rec.linear[axis], nchan);
    }
    if (!is_record(rec)) { #If its not a record its an index
      local chan := private.display.channels[rec];
      private.display.select.addchannels(chan);
      private.display.status->postnoforward(spaste('Selected channel ', chan));
    } else if (rec.type == 'box') {
      local pvalue1 := 
        private.display.lineartoindex(rec.linear.blc[axis], nchan);
      local pvalue2 :=
        private.display.lineartoindex(rec.linear.trc[axis], nchan);
      local chans := private.display.channels[seq(pvalue1, pvalue2)];
      private.display.select.addchannels(chans);
      private.display.status->
        postnoforward(spaste('Selected displayed channels between ', chans[1],
                             ' and ', chans[length(chans)]));
    }
    return T;
  }

  private.display.callbacks.Correlation := function(rec, axis) {
    wider private;
    local ncorr := length(private.display.corr_axis);
    if (is_record(rec) && rec.type == 'point') {
      rec := private.display.lineartoindex(rec.linear[axis], ncorr);
    }
    if (is_record(rec) && rec.type == 'box') {
      local pvalue1 := 
        private.display.lineartoindex(rec.linear.blc[axis], ncorr);
      local pvalue2 :=
        private.display.lineartoindex(rec.linear.trc[axis], ncorr);
      rec := seq(pvalue1, pvalue2);
    }
    corrnames := private.display.corr_axis[rec];
    local dds := unique(private.display.dd);
    if (length(dds) > 1 && dds[1] == 0) {
      dds := dds[2:(length(dds))];
    }
    local polid := unique(private.polid[dds]);
    if (length(polid) > 1) {
      throw('Cannot select specific correlations as this varies ', 
            'throughout the observation.\nPlease select data with ',
            'a constant polarization', 
            origin='msplot.display.callbacks.Correlation');
    }
    polnums := 1:length(private.data.polarization[polid]);
    index := [];
    for (c in corrnames) {
      index := [index, polnums[private.data.polarization[polid] == c]];
    }
    private.display.select.addcorrelations(index);
    return T;
  }

  private.display.callbacks.All := function(rec) {
    wider private;
    if (all(rec.type != "point box")) {
      return throw('Need to use point or box regions to select data.\n',
                   'Other selections are ignored.',
                   origin='private.display.callbacks.All');
    }
    ok := T;
    private.display.select.next();
    for (i in ind(private.display.axisnames)) {
      local pvalue := unset;
      if (i > 2) {
        if (i == 3) {
          pvalue := rec.zindex;
        } else if (i == 4) {
          pvalue := private.viewerdd.getoptions().haxis1.value;
        } else {
          return throw('Cannot have an image with more than 4 dimensions',
                       origin='msplot.display.callbacks.All');
        }
      }
      if (is_unset(pvalue)) {
        pvalue := rec;
      }
      axisname := private.display.axisnames[i];
      if (axisname == 'Time') {
        if (!private.display.policyframe['spectral windows']->state()) {
          ok &:= private.display.callbacks.Data_Descriptions(pvalue, i);
        }
        if (!private.display.policyframe.times->state()) {
          ok &:= private.display.callbacks.Time(pvalue, i);
        }
      } else if (axisname == 'Channel') {
        if (!private.display.policyframe.channels->state()) {
          ok &:= private.display.callbacks.Channel(pvalue, i);
        }
      } else if (axisname == 'Correlation') {
        if (!private.display.policyframe.correlations->state()) {
          ok &:= private.display.callbacks.Correlation(pvalue, i);
        }
      } else if (axisname == 'Interferometer_Number') {
        if (private.display.policyframe.antennas->state()) {
          ok &:= private.display.callbacks.Antenna(pvalue, i);
        } else if (!private.display.policyframe.interferometers->state()) {
          ok &:= private.display.callbacks.Interferometer_Number(pvalue, i);
        }
      }
    }
    if (ok) {
      private.display.select.listone();
      private.display.status->
        postnoforward(spaste('Defined edit command ',
                             private.display.select.nrecords));
    }
    return T;
  }

#
# Intialize the current pgplotter
#
  private.plot.initialize := function(addcontrol=F) {
    wider private;
    private.thisplot := private.makeplot();
    private.plot.busy := T;
    private.getaxes();
    private.plot.gui();
    if (addcontrol) {
      private.plot.controlframe->map();
    } else {
      private.plot.controlframe->unmap();
    }
    local cbnum := private.plot.callbacknumbers.motion
    private.plot.pgplotter.deactivatecallback(cbnum);
    private.worldcbactive := F;
    private.thisplot.npages := 0;
    return T;
  }
#
# Make coordinate system
#
  private.display.makecoordsys := function(axisinfo, roworigin) {
    wider private;
    include 'coordsys.g';
    cs := coordsys(stokes=axisinfo.corr_axis, spectral=T, tabular=T);
    # Eventually I will be able to make two tabular coords in the constructor
    cs.addcoordinate(linear=T);

    cs.setnames("Correlation Channel Interferometer_Number Time");
    cs.setunits(type='tabular', value='', overwrite=T, which=3);
    cs.setunits(type='linear', value='', overwrite=T, which=4);

    refvalues := cs.referencevalue();
    refvalues[3] := 1001;
    refvalues[4] := roworigin;
    cs.setreferencevalue(refvalues);

    # Spectral Coordinate.  (Note that it is set only according to spectral
    # window 1; it will probably be incorrect for other spectral windows).
    # We avoid inserting a full table of frequencies into it
    # if the frequency increment between channels is constant.

    private.world.freqs := axisinfo.freq_axis.chan_freq[,1];
    fr := private.world.freqs;
    nchan := length(fr);
    incr := axisinfo.freq_axis.resolution[1,1];
    linearsp := T;
    if (nchan >= 2) {
      avgincr := (fr[nchan]-fr[1])/(nchan-1);
      if(avgincr!=0) {		# (for safety; should be true).
	for(i in 2:nchan) {
	  if( (fr[i]-fr[i-1] - avgincr)/avgincr > 1e-7 ) {
	    linearsp := F; break;  }  }		# uneven spacing.
	if(linearsp) incr := avgincr;  }  }	# all channels evenly spaced.

    if(linearsp) {	# sp. coord has straight linear frequencies
      cs.setreferencevalue(type='spectral', value=fr[1]);
      if(incr!=0) cs.setincrement(type='spectral', value=incr);  }

    else {		# must pass in the whole table of frequencies.
      cs.setspectral(frequencies=dq.quantity(fr, 'Hz'));  }



    if (length(axisinfo.ifr_axis.ifr_number) > 1) {
      cs.settabular(1:length(axisinfo.ifr_axis.ifr_number),
                    axisinfo.ifr_axis.ifr_number, which=1);
    } else {
      refvalues := cs.referencevalue();
      refvalues[3] :=  axisinfo.ifr_axis.ifr_number[1]; 
      cs.setreferencevalue(refvalues);
    }
    if (has_field(private.data.obs, 'observer') &&
        (length(private.data.obs.observer) > 0)) {
      cs.setobserver(private.data.obs.observer[1]);
      cs.settelescope(private.data.obs.telescope_name[1]);
    }
    return cs;
  }
#
# Intialize the current viewer
#
  private.display.initialize := function() {
    wider private;
    private.thisplot := private.makeplot();
    private.getaxes();
    private.display.gui();
    private.worldcbactive := F;
    private.display.busy := T;
    private.thisplot.npages := 0;
    return T;
  }
#
# Finalize
#
  private.plot.finalize := function() {
    wider private;
    local cbnum := private.plot.callbacknumbers.motion;
    private.plot.pgplotter.activatecallback(cbnum);
    if (private.optionsmenu.multipanel->state()) {
      private.setplotterpages();
    }
    if (private.thisplot.npages > 0) {
      note('Plotted ', private.thisplot.npoints, ' points on ',
           private.thisplot.npages, ' pages');
    }
    private.plot.status->postnoforward('Ready');
    private.plot.busy := F;
    return T;
  }
#
# Finalize
#
  private.display.finalize := function() {
    wider private;
    private.selectedms.iterend();
    private.display.status->postnoforward('Ready');
    private.display.busy := F;
    return T;
  }
#
# Get the plot scales
#
  private.getscales := function() {
    wider private;

    # These are always needed to annotate the plot
    local find := 'data_desc_id field_id';
    local chan_num := F;
    for (select in "X Y") {
      local name := private.axis[select].name;
      if (name == 'ur') {
        find := paste(find, 'uvdist');
      } else if (name=='channel') {
        chan_num:=T;
	find := paste(find, 'chan_freq')
      } else if (name=='frequency') {
	find := paste(find, 'chan_freq')
      } else {
        find := paste(find, name);
      }
    }
    find := unique(split(find));

    private.data.statistics := 
      private.selectedms.range(find,
                               !(private.optionsmenu.plotflagged->state()));

    # Apply channel selection explicitly (ms.range did not)
    if (chan_num | has_field(private.data.statistics,'chan_freq')) {
       local c:=private.getchannel();
       local f;
       f:=private.data.statistics.chan_freq/1.0e9;

       private.data.statistics.chan_num:=array(0.0,c.nchan);
       private.data.statistics.chan_freq:=array(0.0,c.nchan,shape(f)[2]);
       for (isp in [1:shape(f)[2]]) {
         for (ich in [1:c.nchan]) {
           a:=c.start + (ich-1)*c.inc;
           b:=a + c.width-1;
           private.data.statistics.chan_num[ich]:=mean([a:b]);
           private.data.statistics.chan_freq[ich,isp]:=mean(f[a:b,isp]);
         }
       }
    }

    for (axis in "X Y") {
      local value := 
        private.operations['X, Y plot limits'].button[axis].selector.get();
      if (!is_unset(value) && length(value) == 2) {
        private.thisplot.scales[axis][1] :=
          private.thisplot.axis[axis].fromworld(value[1]);
        private.thisplot.scales[axis][2] :=
          private.thisplot.axis[axis].fromworld(value[2]);
      } else {
        local name := private.axis[axis].name;
	if (name == 'ur') name := 'uvdist';
	if (name == 'channel') name := 'chan_num'
	if (name == 'frequency') name := 'chan_freq'
#       if (has_field(private.data.statistics, name) && 
#           !is_fail(private.data.statistics[name])) {
        local scales := private.data.statistics[name];
        private.thisplot.scales[axis][1] :=
          private.thisplot.axis[axis].fromworld(min(scales));
        private.thisplot.scales[axis][2]:=
          private.thisplot.axis[axis].fromworld(max(scales));
#       } else {
#         throw('Cannot determine the range of values to plot\n',
#               'Perhaps you need to select a subset that is all ',
#               'the same shape', origin='msplot.getscales');
#       }
      }
    }
    
  }

#
# Return the selection criteria that can be used in by the ms.select function
# This does not include selections that can be done using TaQL
#
  private.getselection := function() {
    wider private;
    rec := [=];
    for (select in "ifr_number") {
      local value := private.getvalue[select]();
      if (select == 'ifr_number' && is_unset(value)) {
# Need to get the range of ifr_numbers in the selected ms. Otherwise
# the ms iterator will use a value that is appropriate only to the
# current iteration and this may lead to different axis lengths (if
# some antennas go on or offline) along the interferometer axis. This
# is only a problem when displaying data as an image.
        value := private.selectedms.range("ifr_number").ifr_number;
      }
      if (!is_unset(value)) {
        rec[select] := value;
      }
    }
    return rec;
  }
#
# Return a TaQL string that can be used, by the command function, to
# select some of the data. Some selections cannot be done using TaQL,
# like ifr_number, channel or polarization.
#
  private.getselectionasquery := function() {
    wider private;
    local indextypes := "antenna1 data_desc_id feed1 feed2 field_id scan_number";
    local taqlname := [antenna1='ANTENNA1', 
                       feed1='FEED1', feed2='FEED2',
                       field_id='FIELD_ID',
                       flag_row='FLAG_ROW',
                       data_desc_id='DATA_DESC_ID',
                       scan_number='SCAN_NUMBER',
                       u='UVW[1]', v='UVW[2]', w='UVW[3]',
                       uvdist='SQRT(UVW[1]^2+UVW[2]^2)',
                       time='TIME'];
    local rootquery := [taql='', english=''];

    local entries := 
      'antenna1 data_desc_id feed1 feed2 field_id time flag_row';
    if (private.datatype == 'sd') {
      entries := split(paste(entries, 'scan_number'));
    } else {
      entries := split(paste(entries, 'u v w uvdist scan_number zerospacing'));
    }
    for (field in entries) {
      local value := private.getvalue[field]();
      if (is_fail(value)) fail;
      if (!is_unset(value)) {
        local thisquery := [taql='', english=''];
        if (field == 'zerospacing') {
          if (value == F) {
            thisquery.taql := '(ANTENNA1 != ANTENNA2)';
            thisquery.english := 'ANTENNA1 is not the same as ANTENNA2';
          }
        } else if (field == 'flag_row') {
          if (value == F) {
            thisquery.taql := '(FLAG_ROW == F)';
            thisquery.english := 'FLAG_ROW == False';
          }
        } else {

          if (any(indextypes==field)) {
            # these are the index list selections:
            local indices := value;
            if (field!='scan_number') {
              indices:=indices-1;  # correct for 0-basedness
            };
            local tfield := taqlname[field];

            if (length(indices) == 1) {
              taqltmp:=spaste('==',as_evalstr(indices))
              engltmp:=spaste(' = ',as_evalstr(value))
            } else {            
              taqltmp:=spaste(' IN ',as_evalstr(indices))
              engltmp:=spaste(' in ',as_evalstr(value))
            }

            if (field=='antenna1') {
              # joint selection on ANTENNA? columns:
              thisquery.taql := spaste( '(','(ANTENNA1',taqltmp,')',' || ',
                                            '(ANTENNA2',taqltmp,')',')' );
              thisquery.english := spaste('antennas',engltmp);
            } else {
              thisquery.taql := spaste('(',tfield,taqltmp,')');
              thisquery.english := spaste(tfield,engltmp);
            }

          } else {

            # these are the non-index "range-type" selections:
            local rvalue := value;
            # needed to avoid rounding problems when converting to a string:
            rvalue::print.precision := 20; 

            local tfield := taqlname[field];

            if (field == 'time') value := private.getvalue.time(T);

            if (length(rvalue) == 2) {
              thisquery.taql := spaste('(',tfield,' IN [',
                                       as_evalstr(rvalue[1]), '=:=',
                                       as_evalstr(rvalue[2]), '])');
              thisquery.english := spaste(tfield,' in the range ',
                                        as_evalstr(rvalue[1]), ' to ',
                                        as_evalstr(rvalue[2]));
            } else {
              note(spaste('No selection on ',field,'.'),
                   'Please specify exactly TWO endpoint values')
            }
          } 
        }
        if (strlen(thisquery.taql) > 0) {
          if (strlen(rootquery.taql) == 0) {
            rootquery := thisquery;
          } else {
            rootquery.taql := spaste(rootquery.taql, '&&', thisquery.taql);
            rootquery.english := spaste(rootquery.english, ' AND ',
                                        thisquery.english);
          }
        }
      }
    }
    return rootquery;
  }
  
#
# Get the ranges of all possible selections. These will be
# set in the associated values so that the user may know
# what values are allowed
#
  private.getranges := function(doselect=F) {
    wider private;
#
# Get the specified selection from the user interface
#
    if (doselect) {
      if (is_fail(private.select())) fail;
    }
    note('Reading MS to get ranges for selected data: ',
         'this may take a while...', origin='msplot.getranges');
    rec := private.ms.range(private.rangetypes);
    note('...found all ranges', origin='msplot.getranges');
    if (is_fail(rec)) fail;
#
# Have to convert times from numeric (e.g. 4.56279873eE9)
# to text form (e.g. 1991/03/09:03:56:34)
#
    newtime := array("", 2);
    newtime[1] := private.world.print.time(rec.time[1]);
    newtime[2] := private.world.print.time(rec.time[2]);
    rec.time := newtime;
    
    return rec;
  }

#
# return a directory where we will put temporary files
#
  private.tempdir := function() {
    include 'serverexists.g';
    include 'aipsrc.g';
    local usemyaipsrc := 
      !serverexists('defaultaipsrc', 'aipsrc', defaultaipsrc);
    local myarc;
    if (usemyaipsrc) {
      myarc := aipsrcbase();
    } else {
      myarc := ref defaultaipsrc;
    }
    private.initos();
    local tempdir;
    local msname := private.ms.name();
    local defaultdir := split(paste(private.tools.os.dirname(msname), '.'));
    if (!myarc.find(tempdir, 'user.directories.work')) {
      tempdir := defaultdir;
    } else {
      tempdir := split(paste(tempdir, defaultdir));
    }
    if (usemyaipsrc) {
      myarc.done();
    }
    local i := 1;
    local ndirs := length(tempdir);
    local basename := private.tools.os.basename(msname);
    while (i <= ndirs) {
      local testname := spaste(tempdir[i], '/', basename, '.msplot');
      if (private.tools.os.isvalidpathname(testname)) break;
      i +:= 1;
    }
    if (i > ndirs) {
      return throw('Cannot create any temporary files ',
                   'as none of the following directories are writable.\n',
                   tempdir, origin='msplot.tempdir');
    }
    return spaste(tempdir[i], '/', basename);
  }

#
# Created a selected ms
#
  private.select := function() {
    wider private;
     if (!has_field(private, 'ms') || !is_ms(private.ms)) {
       return throw ('MeasurementSet not defined', origin='msplot.select');
     }
#
# Created the selected ms
#
    local query := private.getselectionasquery();
    if (is_fail(query)) fail;
    if (!has_field(private, 'taql') || private.taql != query.taql) {
      local selectedmsname := F;
      if (has_field(private, 'selectedms') && is_ms(private.selectedms) &&
          private.selectedms.name() != private.ms.name()) {
        private.deleteselectedms();
      }    
      note('Selecting a subset of the measurement set.\n',
           'This may take a while, particularly for a complicated selection.',
           origin='msplot.select');
      private.taql := query.taql;
      if (!is_string(selectedmsname)) {
        local tempdir := private.tempdir();
        if (is_fail(tempdir)) fail;
        selectedmsname := spaste(tempdir, '.selected');
      }
      if (strlen(private.taql) > 0) {
        private.selectedms := 
          private.ms.command(selectedmsname, private.taql, !private.edit);
      } else {
        private.selectedms := private.ms;
      }
      note('...subset has ',  private.selectedms.nrow(), ' rows.',
           origin='msplot.select');
    }
    if (private.selectedms.nrow() == 0) {
      return throw('No data selected - selection criteria is too narrow.',
                   origin='msplot.select');
    }
#
# Need to call selectinit in order to do further selections on
# ifr_number, polarization and channel
#
    private.selectedms.selectinit(reset=T);
    {
      dd := private.getvalue.data_desc_id();
      if (is_unset(dd)) dd := private.datadescid;
      if (is_fail(dd)) fail;
      if (length(dd) == 1) {
        local ok := private.selectedms.selectinit(datadescid=dd);
        if (!ok) return F;
      } else {
# Check if all the data is the same shape. Otherwise further
# selections will fail.
        local nchans := private.data.spectral.numchan[private.spwid[dd]];
        local ncorrs := [];
        for (i in [1:length(dd)]) {
          local polid := private.polid[dd[i]];
          ncorrs[i] := length(private.data.polarization[polid]);
        }
        if (all(nchans == nchans[1]) & all(ncorrs == ncorrs[1])) {
          local ok := private.selectedms.selectinit(datadescid=dd);
          if (is_fail(ok) || ok == F) fail;
        } else {
          local error := spaste('It is not possible to select the data',
                               ' with the requested spectral &\n',
                               'polarization id\'s as',
                               ' the data shape (number of correlations',
                               ' & channels) changes');
          return throw(error, origin='msplot.select');
        }
      }
    }
#
# Select on ifr_numbers
#
    local othersels := private.getselection();
    if (length(othersels) > 0) {
      private.selectedms.select(othersels);
    }
#    
# Select the polarizations we want
#
    local polarization := private.getpolarization();
    if (is_fail(polarization)) fail;
    if (!is_unset(polarization)) {
      local ok := private.selectedms.selectpolarization(split(polarization));
      if (is_fail(ok) || ok == F) {
        return throw('Polarization selection is incorrect', 
                     origin='msplot.select');
      }
    }
#    
# Select the channels we want
#
    local c := private.getchannel();
    if (!is_unset(c)) {
      local ok := 
        private.selectedms.selectchannel(c.nchan, c.start, c.width, c.inc);
      if (is_fail(ok) || ok == F) {
        return throw('Channel selection is incorrect', origin='msplot.select');
      }
    }
    return T;
  }
#
# Initialize the iteration
#
  private.iterinit := function(dobyrows=T, getaxes=T) {
    wider private;
#
# Select a subset of the data
#    
    local ok := private.select();
    if (is_fail(ok)) fail;
    if (!ok) return F;
#
# Now we can get the scales *before* the iteration is set up so that
# we can get the entire range of values.
#
    if (getaxes) private.getscales();
#
# Get the iteration scheme from the user interface
#
    iteration := private.getiteration();
    if (length(iteration) > 0) {
      note('Reading all rows by ', iteration, ' and time',
           origin='msplot.iterinit');
#      local allcolumns := "DATA_DESC_ID FIELD_ID SCAN_NUMBER TIME";
      local allcolumns := "DATA_DESC_ID FIELD_ID TIME";
      local columns := split(to_upper(iteration));
      for (column in allcolumns) {
        if (!any(columns == column)) {
          columns := [columns, column];
        }
      }
      if (is_fail(private.selectedms.iterinit(columns=columns,
                                              interval=1e9,
                                              maxrows=private.nrows))) fail;
    } else if (dobyrows) {
      note('Reading by row', origin='msplot.iterinit');
      if (is_fail(private.selectedms.
                  iterinit(columns="OBSERVATION_ID ARRAY_ID SCAN_NUMBER", interval=1e30,
                           maxrows=private.nrows, adddefaultsortcolumns=F))
          ) fail;
    } else {
      note('Reading data in time order', origin='msplot.iterinit');
      if (is_fail(private.selectedms.
                  iterinit(columns='TIME', interval=60*60,
                           maxrows=private.nrows,
                           adddefaultsortcolumns=F))) fail;
    }

    if (is_fail(private.selectedms.iterorigin())) fail;
    private.iteration.last := [=];
  
    return T;
  }
#
  private.iternext := function() {
    wider private;
    if (private.stop) {
      note('Stopping at your request', priority='WARN');
      private.stop := F;
      return F;
    }
    return private.selectedms.iternext();
  }   
#
# Get the names of the specified axes
#
  private.getaxes := function() {
    wider private;
    for (axis in "X Y Z") {
      for (type in private.plottypes[private.datatype]) {
        if (axis != 'Z') {
          if (private.toolbar[axis].button[type]->state()) {
            private.axis[axis] := private.axes[type];
            break;
          }
        }
      }
      if (type == 'data') {
        awhat := 'observed';
        avalue := 'amplitude';
        for (what in private.viswhats[private.datatype]) {
          if (private.toolbar[axis].submenu.Data.submenu.What.button[what]->state()) {
            awhat := what;
            break; 
          }
        }
        for (value in private.visvalues[private.datatype]) {
          if (private.toolbar[axis].submenu.Data.submenu.Values.button[value]->state()) {
            avalue:=value;
            break;
          }
        }
        if (avalue == 'float_data') {
          private.axis[axis] := private.axes[avalue];
        } else if (awhat == 'observed') {
          private.axis[axis] := private.axes[avalue];
        } else {
          private.axis[axis] := private.axes[spaste(awhat, '_', avalue)];
        }
      }
      private.thisplot.axis[axis] := ref private.axis[axis];
    }
  }
#
# Returns a string vector containing the axes to iterate over.
#
  private.getiteration := function() {
    wider private;
    result := "";
    for (select in private.iterationtypes) {
      if (private.action.iterate.button[select]->state()) {
        result := paste(result ,select);
      }
    }
    return split(result);
  }

  private.getpolarization := function() {
    wider private;
    local vals := 
      private.operations['Polarization selection'].button.polarizations.
        selector.get();
    if (length(vals) == 0) {
      note('No polarizations selected, using all polarizations.', 
           origin='msplot.getpolarization', priority='WARN');
      return unset;
    }
    local allowedPols := to_upper(private.stokes);
    vals := split(to_upper(vals));
    for (v in vals) {
      if (!any(allowedPols == v)) {
        return throw ('Illegal polarization ', v, ' : must be drawn from ',
                      private.stokes, origin='msplot.getpolarization');
      }
    }
# If the user has selected all polarizations then return unset. This is
# to work around defect #3130
    local pnames := '';
    for (p in unique(private.polid)) {
      pnames := paste(pnames, private.data.polarization[p]);
    }
    pnames := unique(split(pnames));
    if (length(vals) == length(pnames) && all(sort(vals) == pnames)) {
      return unset;
    }
    return vals;
  }
#
# get values the data descriptions the user has selected
#
  private.getvalue.data_desc_id := function() {
    wider private;
    local spwids := 
      private.operations['Spectral selection'].button.spwid.selector.get();
    local polids := 
      private.operations['Polarization selection'].button.polid.selector.get();
    # An unset value means all allowable values
    if (is_unset(spwids) & is_unset(polids)) return unset;
    if (is_unset(spwids)) spwids := private.spwid;
    if (is_unset(polids)) {
      polids := private.polid;
    } else {
      polids := as_integer(polids)
    }
    local datadescid := [];
    for (pol in polids) {
      for (spw in spwids) {
        for (dd in private.datadescid) {
          if ((private.spwid[dd] == spw) && (private.polid[dd] == pol)) {
            datadescid := [datadescid, dd];
            break;
          }
        }
      }
    }
    if (length(datadescid) == 0) {
      return throw('Specified spectral & polarization id\'s do not ',
                   'correspond to any data in this measurement set.', 
                   origin='msplot.getvalue.data_desc_id');
    }
    datadescid := unique(datadescid);
    if ((length(datadescid) == length(private.datadescid)) &&
        all(datadescid == private.datadescid)) return unset;
    return datadescid;
  }

  private.getvalue.zerospacing := function() {
    wider private;
    if (private.operations['Data selection'].
        button.zerospacing.selector.get() == F) {
      return F;
    } else {
      return unset;
    }
  }

  private.getvalue.flag_row := function() {
    wider private;
    return private.optionsmenu.plotflagged->state();
  }

  private.getvalue.field_id := function() {
    wider private;
    local guivalue := 
      private.operations['Data selection'].button.fields.selector.get();
    if (!is_unset(guivalue) && length(guivalue) > 0) {
      return unique(guivalue);
    } else {
      return unset;
    }
  }

  private.getvalue.antenna1 := function() {
    wider private;
    local guivalue := 
      private.operations['Data selection'].button.antennas.selector.get();
    if (!is_unset(guivalue) && length(guivalue) > 0) {
      return unique(guivalue);
    } else {
      return unset;
    }
  }

  private.getvalue.antenna2 := function() {
    return private.getvalue.antenna1();
  }

  private.getvalue.feed1 := function() {
    wider private;
    local guivalue := 
      private.operations['Data selection'].button.feeds.selector.get();
    if (!is_unset(guivalue) && length(guivalue) > 0) {
      return unique(guivalue);
    } else {
      return unset;
    }
  }

  private.getvalue.feed2 := function() {
    return private.getvalue.feed1();
  }

  private.getvalue.ifr_number := function() {
    wider private;
    local guivalue := 
      private.operations['Data selection'].button.ifr_number.selector.get();
    if (!is_unset(guivalue) && length(guivalue) > 0) {
      return unique(guivalue);
    } else {
      return unset;
#      private.ranges.ifr_number;
    }
  }

  private.getvalue.scan_number := function() {
    wider private;
    local guivalue := 
      private.operations['Data selection'].button.scan_number.selector.get();
    if (!is_unset(guivalue) && length(guivalue) > 0) {
      return unique(guivalue);
    } else {
      return unset;
    }
  }

  private.getvalue.time := function(as_string=F) {
    wider private;
    local guivalue := 
      private.operations['Data selection'].button.time.selector.get();
    local timestring;
    if (!is_unset(guivalue) && length(guivalue) > 0) {
      timestring := unique(guivalue);
    } else {
      if (as_string) {
        return private.ranges.time;
      } else {
        return unset;
      }
    }
    include 'quanta.g';
    local timequanta := dq.quantity(timestring);
    local timeinsecs := array(0, 2);
    timeinsecs[1] := dq.getvalue(dq.convert(timequanta[1], 's'));
    timeinsecs[2] := dq.getvalue(dq.convert(timequanta[2], 's'));
    return timeinsecs;
  }

  private.getvalue.u := function() {
    wider private;
    local guivalue := 
      private.operations['Data selection'].button.u.selector.get();
    if (!is_unset(guivalue) && length(guivalue) > 0) {
      return unique(guivalue);
    } else {
      return unset;
    }
  }

  private.getvalue.v := function() {
    wider private;
    local guivalue := 
      private.operations['Data selection'].button.v.selector.get();
    if (!is_unset(guivalue) && length(guivalue) > 0) {
      return unique(guivalue);
    } else {
      return unset;
    }
  }

  private.getvalue.w := function() {
    wider private;
    local guivalue := 
      private.operations['Data selection'].button.w.selector.get();
    if (!is_unset(guivalue) && length(guivalue) > 0) {
      return unique(guivalue);
    } else {
      return unset;
    }
  }

  private.getvalue.uvdist := function() {
    wider private;
    local guivalue := 
      private.operations['Data selection'].button.uvdist.selector.get();
    if (!is_unset(guivalue) && length(guivalue) > 0) {
      return unique(guivalue);
    } else {
      return unset;
    }
  }

  private.getchannel := function() {
    wider private;
    local rec := [=];
    rec.nchan := 
      private.operations['Spectral selection'].button.nchan.selector.get();
    if (is_unset(rec.nchan)) return unset;
    rec.start :=
      private.operations['Spectral selection'].button.start.selector.get();
    if (is_unset(rec.start)) rec.start := 1;
    if (!private.edit) {
      rec.width :=
        private.operations['Spectral selection'].button.width.selector.get();
      if (is_unset(rec.width)) rec.width := 1;
    } else {
      rec.width := 1;
    }
    rec.inc := 
      private.operations['Spectral selection'].button.inc.selector.get();
    if (is_unset(rec.inc)) rec.inc := 1;
    return rec;
  }

  private.getaxisranges := function(x, y, ref minx, ref maxx, 
                                    ref miny, ref maxy) {
    wider private;
  
    if (has_field(private.thisplot.scales, 'X')) {
      val minx := private.thisplot.scales.X[1];
      val maxx := private.thisplot.scales.X[2];
    } else {
      val minx := min(x);
      val maxx := max(x);
      vals[1] := minx;
      vals[2] := maxx;
      private.thisplot.scales.X := vals;
    }
    if (has_field(private.thisplot.scales, 'Y')) {
      val miny := private.thisplot.scales.Y[1];
      val maxy := private.thisplot.scales.Y[2];
    } else {
      val miny := min(y);
      val maxy := max(y);
      vals[1] := miny;
      vals[2] := maxy;
      private.thisplot.scales.Y := vals;
    }
  }

  private.plot.standardscaling := function(ref x, ref y, ref xaxis, ref yaxis){
    wider private;
  
    minx := miny := maxx := maxy := F;
    private.getaxisranges(x, y, minx, maxx, miny, maxy);
  
    xlabel := xaxis.label;
    ylabel := yaxis.label;

    if (xaxis.name == 'time') {
      val xaxis.offset := 86400.0*as_integer(minx/86400.0);
      val x -:= xaxis.offset;
      minx -:= xaxis.offset;
      maxx -:= xaxis.offset;
      xlabel := paste(xlabel, '(offset from ', 
                      private.world.print.time(xaxis.offset), ')');
    } else if (xaxis.name == 'phase' | xaxis.name == "corrected_phase" | xaxis.name == "model_phase" | xaxis.name == "residual_phase" | xaxis.name == "ratio_phase") {
      val xaxis.scale := 180.0/pi;
      val x *:= xaxis.scale;
      minx := min(x);
      maxx := max(x);
    } else if (xaxis.name == 'scan_number') {
      val xaxis.offset := 10.0*as_integer(minx/10);
      val x -:= xaxis.offset;
      minx -:= xaxis.offset;
      maxx -:= xaxis.offset;
      xlabel := 
        paste(xlabel, '(offset from ', 
              private.world.print.generic(as_integer(xaxis.offset)), ')');
    }
    if (yaxis.name == 'time') {
      val yaxis.offset := 86400.0*as_integer(miny/86400.0);
      val y-:= yaxis.offset;
      miny -:= yaxis.offset;
      maxy -:= yaxis.offset;
      ylabel := paste(ylabel, '(offset from ', 
                      private.world.print.time(yaxis.offset), ')');
    } else if (yaxis.name == 'phase' | yaxis.name == "corrected_phase" | yaxis.name == "model_phase" | yaxis.name == "residual_phase" | yaxis.name == "ratio_phase") {
      val yaxis.scale := 180.0/pi;
      val y *:= yaxis.scale;
      miny := min(y);
      maxy := max(y);
    } else if (yaxis.name == 'scan_number') {
      val yaxis.offset := 10.0*as_integer(miny/10);
      val y -:= yaxis.offset;
      miny -:= yaxis.offset;
      maxy -:= yaxis.offset;
      ylabel := 
        paste(ylabel, '(offset from ', 
              private.world.print.generic(as_integer(yaxis.offset)), ')');
    }
  
    if (xaxis.units != '') xlabel := spaste(xlabel, ' (', xaxis.units, ')');
    if (yaxis.units != '') ylabel := spaste(ylabel, ' (', yaxis.units, ')');
    
#    if (xaxis.name == 'u' | xaxis.name == 'v') {
#      maxx := max(abs(maxx), abs(minx));
#      minx := -maxx;
#    }
#    if (yaxis.name == 'u' | yaxis.name == 'v') {
#      maxy := max(abs(maxy), abs(miny));
#      miny := -maxy;
#    }
    local equalaxes := F;
    if ((xaxis.name == 'u' & yaxis.name == 'v') | 
	(xaxis.name == 'v' & yaxis.name == 'u')) {
      maxx := max(abs(maxx), abs(minx), abs(maxy), abs(maxy), abs(miny));
      maxy := maxx;
      miny := minx := -maxx;
      equalaxes := T;
    }

    if (maxx == minx) {
      minx := 0.0;
      if (maxx == 0.0) maxx := 1.0;
    }
    if (maxy == miny) {
      miny := 0.0;
      if (maxy == 0.0) maxy := 1.0;
    }

    local needaxes := private.needaxes();
    if (needaxes) {
      if ((private.thisplot.npages > 0) && private.stopnow()) {
        return F;
      }
      private.plot.pgplotter.page();
      private.plot.pgplotter.sci(1);
      if (xaxis.name == 'time') {
        xopt := 'BCNSTZ';
      } else if (xaxis.name == 'longitude') {
        xopt := 'BCNSTZXH';
      } else {
        xopt := 'BCNST';
      }
      if (yaxis.name == 'time') {
        yopt := 'BCNSTZ';
      } else if (yaxis.name == 'latitude') {
        yopt := 'BCNSTZD';
      } else {
        yopt := 'BCNST';
      }
      rangex := maxx - minx;
      rangey := maxy - miny;
      minx := minx - 0.05 * rangex;
      maxx := maxx + 0.05 * rangex;
      miny := miny - 0.05 * rangey;
      maxy := maxy + 0.05 * rangey;
      if (equalaxes) {
	private.plot.pgplotter.wnad(minx, maxx, miny, maxy);
      } else {
	private.plot.pgplotter.swin(minx, maxx, miny, maxy);
      }
      private.plot.pgplotter.tbox(xopt, 0.0, 0, yopt, 0.0, 0);
      private.plot.standardlabel(xlabel, ylabel);
      private.thisplot.ready := T;
      private.thisplot.npages +:= 1;
    }
    return T;
  }

  private.plot.standardlabel := function(xlabel='', ylabel='', toplabel='') {
    wider private;
    iteration := private.getiteration();
    dd := unset;
    ff := unset;
    if (any(iteration == 'data_desc_id')) {
      dd := private.iteration.last.data_desc_id;
    }
    if (any(iteration == 'field_id')) {
      ff := private.iteration.last.field_id;
    }
    title := private.plot.title(dd, ff);
    subtitle := '';
    for (type in split(iteration)) {
      if ((type != 'data_desc_id') && (type != 'field_id')) {
        for (i in 1:length(private.iterationtypes)) {
          value := private.iteration.last[type];
          if (type == private.iterationtypes[i]) {
            if (type == 'time') {
              subtitle := paste(subtitle, private.iterationlabels[i], "=",
                                private.world.print.time(value));
            } else {
              subtitle := paste(subtitle, private.iterationlabels[i], "=",
                                value);
            }
            break;
          }
        }
      }
    }
    private.thisplot.label.X := xlabel;
    private.thisplot.label.Y := ylabel;
    private.thisplot.label.top := title;
    private.thisplot.label.sub := subtitle;
  
    private.plot.pgplotter.lab(xlabel, ylabel, title);
    if (strlen(subtitle) > 0) {
      private.plot.pgplotter.mtxt(side='t', disp=0.75, coord=0.5, fjust=0.5, 
                             text=subtitle);
    }

    if (private.optionsmenu.identify->state()) {
      private.plot.pgplotter.iden();
    }
  }
#
  private.plot.title := function(dd=unset, ff=unset) {
  
    wider private;
  
    msname := paste('ms name:', private.ms.name());
    const maxlen := 4;
    if (is_unset(dd)) {
      dd := unique(private.data.statistics.data_desc_id);
    }
    spw := as_string(unique(private.spwid[dd]));
    if (length(spw) > maxlen) {
      spw := paste(paste(spw[1:maxlen]), '...');
    }
    pol := as_string(unique(private.polid[dd]));
    if (length(pol) > maxlen) {
      pol := paste(paste(pol[1:maxlen]), '...');
    }
    if (is_unset(ff)) {
      ff := unique(private.data.statistics.field_id);
    }
    fld := private.fieldnames[ff];
    if (length(fld) > maxlen) {
      fld := paste(paste(fld[1:maxlen]), '...');
    }
    title := paste(msname, 'Spectral Window:', spw, 'Polarization:', pol,
                   'Fields:', fld);
    return title;
  }
#
  private.display.title := function() {
  
    wider private;
  
    title := 'msplot';
    if (is_record(private.ms)) {
      title := paste(title, private.ms.name());
    }
    return title;
  }

  private.setplotterpages := function () {
  
    wider private;
  
    npages := private.thisplot.npages;
  
    if (npages<2) return T;
  
    nx := as_integer(sqrt(npages));
    ny := as_integer(npages/nx);
    if ((nx*ny)<npages) nx+:=1;
    if ((nx*ny)<npages) ny+:=1;
  
    # OK, find the 'settings' call: should be first
    command := [=];
    where := 0;
    n := private.plot.pgplotter.displaylist().ndrawlist();
    for (i in 1:n) {
      tmp := private.plot.pgplotter.displaylist().get(i);
      if (is_record(tmp) && has_field(tmp, '_method')) {
        if (tmp._method == 'settings') {
          command := tmp;
          where := i;
          break;
        }
      }
    }    
  
    if (!where) {
      return throw('pages - no \'settings\' command in drawlist!');
    }
  
    command.nxsub := nx;
    command.nysub := ny;
  
    private.plot.pgplotter.displaylist().set(where, command);
    private.plot.pgplotter.refresh();
  
  }     

  private.update := [=];

# 
# Sets default values for the numchan, start, width & inc fields if a
# user specifies one or a number of spwid's.
#
  private.update.spectral := function(spwid) {
    wider private;
    numchans := private.data.spectral.numchan[spwid];
    if ((length(numchans) == 1) || all(numchans == numchans[1])) {
      numchans := numchans[1];
    } else {
      note('Specified spectral windows have a differing number of channels.\n',
           'Defaulting the number of channels to the smallest value.',
           origin='msplot.update.spectral', priority='WARN');
      numchans := min(numchans);
    }
    private.operations['Spectral selection'].button.nchan.selector.
      insert(numchans);
    for (type in "start width inc") {
      if (!private.edit || type != 'width') {
        private.operations['Spectral selection'].button[type].selector.
          insert(1);
        private.operations['Spectral selection'].button[type].selector.
          insert(1);
      }
    }
  }

#
# adjusts the polarization names in the gui so that it shows
# all the values possible for the specified polarization id's. 
#
  private.update.polarization := function(polid) {
    wider private;
    if (is_unset(polid)) polid := unique(private.polid);
    local polNames := paste(private.data.polarization[polid[1]]);
    nid := length(polid);
    if (nid > 1) {
      for (p in polid[2:nid]) {
        polNames := paste(polNames, private.data.polarization[p]);
      }
      polNames := paste(unique(split(polNames)));
    }
    private.operations['Polarization selection'].
      button.polarizations.selector.insert(polNames);
  }
#
# This switches on the gui
#
  private.gui := function() {
    wider private;
#
# If the topframe is an agent then we can just map it
#
    if (is_agent(private.frames.top)) {
      private.frames.top->map();
      return T;
    }
# 
# Build the main GUI
#-------------------------------------------------------------
    const ws := ref private.tools.widgetserver;
    const ge := ref private.tools.guientry;
# Hold the widgets until all are ready
    ws.tk_hold();
# The top frame
    private.frames.top := ws.frame(title='msplot', side='top');
#
# A menu bar containing File, Special, Options, Help
    private.menubar :=
      ws.frame(private.frames.top, side='left', relief='raised', expand='x');
# File Menu 
    private.filebutton :=
      ws.button(private.menubar, 'File', relief='flat', type='menu');
    ws.popuphelp(private.filebutton, 
                 'Operations such as opening and closing a measurement set');
    private.filemenu := [=];
    private.filemenu.openro := ws.button(private.filebutton,
                                       'Open MS (readonly)');
    private.filemenu.openrw := ws.button(private.filebutton,
                                         'Open MS (editable)');
    # these fields are used in the associated whenever
    private.filemenu.openro.edit := F;
    private.filemenu.openrw.edit := T;
    private.filemenu.close := ws.button(private.filebutton, 'Close MS');
    private.filemenu.show :=
      ws.button(private.filebutton, 'Show existing plotter or display');
    private.filemenu.dismiss :=
      ws.button(private.filebutton, 'Dismiss', type='dismiss');
    private.filemenu.exit :=
      ws.button(private.filebutton, 'Done', type='halt');
# Options menu
    private.optionsbutton :=
      ws.button(private.menubar, 'Options', relief='flat', type='menu');
    ws.popuphelp(private.optionsbutton, 'Set various options for operation');
    private.optionsmenu := [=];
    private.optionsmenu.identify :=
      ws.button(private.optionsbutton, 'Add your name to plot', type='check');
    private.optionsmenu.plotflagged := 
      ws.button(private.optionsbutton, 'Plot flagged data points?',
                type='check');
    private.optionsmenu.multipanel :=
      ws.button(private.optionsbutton, 'Make multipanel plots?', type='check');
# Set the options
    private.options := [=];
    private.options.identify := T;
    private.options.plotflagged := F;
    private.options.multipanel := T;
    for (option in field_names(private.options)) {
      private.optionsmenu[option]->state(private.options[option]);
    }
# Finally the Help menu
    private.rightmenubar := ws.frame(private.menubar,side='right', expand='x');
    private.helpmenu :=
      ws.helpmenu(private.rightmenubar, menuitems='msplot',
                  refmanitems='Refman:msplot');

# Now we add a toolbar
#    
    private.actionframe := 
      ws.frame(private.frames.top, side='left', expand='x');

    private.actionlabel :=
      ws.label(private.actionframe, 'Show: ');
    private.action.show :=
      ws.optionmenu(private.actionframe, private.showtypes.all, 
                    relief='raised');
    whenever private.action.show->select do {
      private.selectaction();
    } private.pushwhenever();

# Iterate button
    private.action.iterate :=
      ws.button(private.actionframe, 'Iteration selection', type='menu',
                relief='raised');
    ws.popuphelp(private.action.iterate,
                 paste('Set the iteration variables. One plot is made for',
                       'each value of the variable (e.g. pressing field_id',
                       'will give one plot for each field)'));
    private.action.iterate.button := [=];
    i := 0;
    const private.iterationtypes := 
      "antenna1 antenna2 data_desc_id feed1 feed2 field_id scan_number time";
    for (select in private.iterationtypes) {
      i +:= 1;
      private.action.iterate.button[select] :=
        ws.button(private.action.iterate, private.iterationlabels[i],
                  type='check');
      private.action.iterate.button[select]->state(F);
    }

    private.action.pause :=
      ws.optionmenu(private.actionframe, 
                    labels=['Pause between plots', 'Continue between plots'],
                    values="Pause Continue",
                    hlp=spaste('Controls whether there is a pause ',
                               'between successive plots'));
    whenever private.action.pause->select do {
      private.pausemode := split($value.label)[1];
      note(spaste('msplot will ', to_lower(private.pausemode),
                  ' between plots'), origin='msplot.pause');
    } private.pushwhenever();

# Increment button
    private.action.incrementlabel :=
      ws.label(private.actionframe, 'Skip by:', relief='flat');
    ws.popuphelp(private.action.incrementlabel,
                 paste('Skip by this number of points when plotting',
                       'i.e. 10 will cause every tenth point to be plotted'));

    private.action.increment :=
      ge.scalar(private.actionframe, value=1, default=1, allowunset=F);
    private.action.increment.setwidth(4);
    private.action.go :=
      ws.button(private.actionframe, 'Go', type='action', relief='raised');
    ws.popuphelp(private.action.go, 
                 'Go make the desired plot, display, or listing.');
    private.action.stop :=
      ws.button(private.actionframe, 'Stop', type='halt', relief='raised');
    ws.popuphelp(private.action.stop, 
                 'Stop the current operation (if possible)');

#
# Now we add a toolbar for the X, Y, and Image axes
#    
    private.toolbarframe :=
      ws.frame(private.frames.top, side='left', expand='x');
    private.lefttoolbarframe :=
      ws.frame(private.toolbarframe, side='right', expand='x');
    private.toolbarlabel := 
      ws.label(private.toolbarframe, 'Select:');

    private.toolbar := [=];
    for (axis in "X Y Z") {
      private.toolbar[axis]:= [=];
      private.toolbar[axis].button := [=];
# X and Y axes can have more plot types than Z
      if (axis != 'Z') {
        private.toolbar[axis].topbutton :=
          ws.button(private.toolbarframe, spaste(axis, ' axis'), type='menu',
                    relief='raised');
        ws.popuphelp(private.toolbar[axis].topbutton,
                     paste('Select the plot', axis,
                           'axis from the list of allowed axes.'));
        for (type in private.plottypes.all) {
          private.toolbar[axis].button[type] :=
            ws.button(private.toolbar[axis].topbutton, type, type='radio');
          # Add on the submenu for data
          if (type == 'data') {
            private.toolbar[axis].button.datasubmenu :=
              ws.button(private.toolbar[axis].topbutton, type, type='menu');
          }
        }
# The Z axis is for the pixel intensity in the raster mode.
      } else {
        private.toolbar[axis].button.datasubmenu :=
          ws.button(private.toolbarframe, 'Image pixels', type='menu',
                    relief='raised');
        ws.popuphelp(private.toolbar[axis].button.datasubmenu,
                     paste('Set the data axis to be displayed as the',
                           'brightness in an image. The image axes are',
                           'Interferometer, Time(Row), Channel, and',
                           'Polarization.'));
      }

      private.toolbar[axis].submenu := [=];
      private.toolbar[axis].submenu.Data.button := [=];
#     private.toolbar[axis].button[private.axis[axis].name]->state(T);

      private.toolbar[axis].submenu.Data.submenu := [=];
# Build the data submenus for all axes
      private.toolbar[axis].submenu.Data.submenu.What :=
        ws.button(private.toolbar[axis].button.datasubmenu, 'What',
                  type='menu', relief='raised');
      ws.popuphelp(private.toolbar[axis].submenu.Data.submenu.What,
                   paste('What type of data to plot? eg., observed, model,',
                         'corrected, residual, ratio'));
      private.toolbar[axis].submenu.Data.submenu.Values :=
        ws.button(private.toolbar[axis].button.datasubmenu, 'Value',
                  type='menu', relief='raised');
      ws.popuphelp(private.toolbar[axis].submenu.Data.submenu.Values,
                   paste('Set values of data to plot eg., amplitude, phase, ',
                         'real, imaginary, data (i.e. complex))'));
# Fill in the 'What' part of the data submenu
      private.toolbar[axis].submenu.Data.submenu.What.button := [=];
      for (type in private.viswhats.all) {
        private.toolbar[axis].submenu.Data.submenu.What.button[type] :=
          ws.button(private.toolbar[axis].submenu.Data.submenu.What, type,
                    type='radio', relief='raised');
        private.toolbar[axis].submenu.Data.submenu.What.button[type]->state(F);
      }
# Fill in the 'Values' part of the data submenu
      private.toolbar[axis].submenu.Data.submenu.Values.button := [=];
      for (type in private.visvalues.all) {
        private.toolbar[axis].submenu.Data.submenu.Values.button[type] :=
          ws.button(private.toolbar[axis].submenu.Data.submenu.Values, type,
                    type='radio', relief='raised');
        private.toolbar[axis].submenu.Data.submenu.Values.button[type]->state(F);
      }
    }
# Set initial values for What and Values parts of data submenus
    private.toolbar.X.button.uvdist->state(T);
    private.toolbar.X.submenu.Data.submenu.Values.button.phase->state(T); 
    private.toolbar.X.submenu.Data.submenu.What.button.corrected->state(T); 
    # Switch off the data submenus if data not selected.
# These whenevers do NOT work because the the data button only emits a
# press event when it is pressed and not when another button in the
# group is pressed. Hence this code can never disable the
# data sub-menu. This should be fixed up by re-engineering the interface.
#    whenever private.toolbar.X.button.data->press do {
#       if (private.toolbar.X.button.data->state()) {
#       private.toolbar.X.submenu.Data.topbutton->disabled(F);
#       } else {
#       private.toolbar.X.submenu.Data.topbutton->disabled(T);
#       }
#    } private.pushwhenever();

    private.toolbar.Y.button.data->state(T);
    private.toolbar.Y.submenu.Data.submenu.Values.button.amplitude->state(T); 
    private.toolbar.Y.submenu.Data.submenu.What.button.corrected->state(T); 
#    whenever private.toolbar.Y.button.data->press do {
# See above for why this code is commented out.
#       if (private.toolbar.Y.button.data->state()) {
#       private.toolbar.Y.button.datasubmenu->disabled(F);
#       } else {
#       private.toolbar.Y.button.datasubmenu->disabled(T);
#       }
#    } private.pushwhenever();
    private.toolbar.Z.submenu.Data.submenu.Values.button.amplitude->state(T); 
    private.toolbar.Z.submenu.Data.submenu.What.button.corrected->state(T); 
    private.righttoolbarframe :=
      ws.frame(private.toolbarframe, side='right', expand='x');
  
# 
# The tab holds four subframes.
#
    private.tabdialog := ws.tabdialog(private.frames.top, colmax=4, hlthickness=2,
                                      title=unset);
    private.frames.tab := private.tabdialog.dialogframe();
    private.operations := [=];

    helptext['X, Y plot limits'] :=
      'Select x and y min, max for plotting: this affects the next plot.'
    helptext['Data selection'] :=
        'Select ranges of the data to be plotted e.g. antennas, uvdist, etc.';
    helptext['Spectral selection'] := 
      'Select spectral windows, channels to be plotted.';
    helptext['Polarization selection'] := 
      'Select polarizations to be plotted.';
    for (type in private.selectiontypes) {
      private.operations[type] := [=];
      private.operations[type].topframe :=
        ws.frame(private.frames.tab, side='top', expand='x', relief='ridge');
      private.tabdialog.add(private.operations[type].topframe, type, 
                            helptext[type]);
      private.operations[type].label :=
        ws.label(private.operations[type].topframe, helptext[type]);
    }
# Set up the 'X, Y plot limits' subframe.
    private.operations['X, Y plot limits'].frames := [=];
    private.operations['X, Y plot limits'].button := [=];
    for (select in "X Y") {
      private.operations['X, Y plot limits'].frames[select] :=
        ws.frame(private.operations['X, Y plot limits'].topframe, side='left',
                 expand='x');
      private.operations['X, Y plot limits'].button[select] := [=];
      private.operations['X, Y plot limits'].button[select].label :=
        ws.label(private.operations['X, Y plot limits'].frames[select],select);
      private.operations['X, Y plot limits'].button[select].selector :=
        ge.array(private.operations['X, Y plot limits'].frames[select], unset,
                 allowunset=T);
      ws.popuphelp(private.operations['X, Y plot limits'].button[select].label,
                   paste('X, Y plot limits (min, max) for', select, 
                         'axis. Press the Selection button to see values for',
                         'min, max for current plot axes.'));
      private.operations['X, Y plot limits'].getbutton[select] :=
        ws.button(private.operations['X, Y plot limits'].frames[select], 
                  'Range');
      private.operations['X, Y plot limits'].getbutton[select].range := select;
      ws.popuphelp(private.operations['X, Y plot limits'].getbutton[select],
                   paste('Get full range for', select, 'from the plot'));
      whenever private.operations['X, Y plot limits'].getbutton[select]->press do {
        if (private.lock('top')) {
          axis := $agent.range;
          if (private.thisplot.npages) {
            if (has_field(private.thisplot.scales, axis)) {
              if (private.thisplot.axis[axis].type != 'time') {
                vals[1] := private.thisplot.axis[axis].printworld(private.thisplot.scales[axis][1]);
                vals[2] := private.thisplot.axis[axis].printworld(private.thisplot.scales[axis][2]);
                private.operations['X, Y plot limits'].button[axis].selector.insert(paste(as_string(vals)));
              } else {
                note('Please select time ranges using the Time field in ',
                     'the \'Data selection\' tab.',
                     origin='msplot', priority='WARN');
              }
            } else {
              note('The current plot does not have any axes. This is a bug.', 
                   origin='msplot', priority='SEVERE');
            }
          } else {
            note('You need to make a plot before its ranges can be pasted.', 
                 origin='msplot', priority='WARN');
          }
          private.unlock();
        }
      } private.pushwhenever();
    }
# Set up the 'Data selection' subframe.
    private.operations['Data selection'].button := [=];
    private.operations['Data selection'].getbutton := [=];
    private.operations['Data selection'].frames := [=];
    private.operations['Data selection'].button := [=];
    i := 0;
    for (select in private.selecttypes.all) {
      i +:= 1;
      private.operations['Data selection'].frames[select] :=
        ws.frame(private.operations['Data selection'].topframe, side='left',
                 expand='x');
      private.operations['Data selection'].button[select].label :=
        ws.label(private.operations['Data selection'].frames[select],
                 private.selectlabels.all[i], justify='left');
      ws.popuphelp(private.operations['Data selection'].button[select].label,
                   private.axes[select].selecthelp);
      if (select == 'zerospacing') {
        private.operations['Data selection'].button[select].selector :=
          ge.boolean(private.operations['Data selection'].frames[select],
                     value=F, default=F, allowunset=F);
      } else if (select == 'time') {
        private.operations['Data selection'].button[select].selector :=
          ge.string(private.operations['Data selection'].frames.time,
                    unset, allowunset=T, onestring=F);
      } else if (select == 'antennas') {
        private.operations['Data selection'].button[select].selector :=
          ge.antennas(private.operations['Data selection'].frames[select],
                      unset, allowunset=T);
      } else if (select == 'feeds') {
        private.operations['Data selection'].button[select].selector :=
          ge.array(private.operations['Data selection'].frames[select], unset,
                   allowunset=T);
      } else if (select == 'fields') {
        private.operations['Data selection'].button[select].selector :=
          ge.fields(private.operations['Data selection'].frames[select], unset,
                    allowunset=T);
      } else if (select == 'ifr_number') {
        private.operations['Data selection'].button[select].selector :=
          ge.baselines(private.operations['Data selection'].frames[select],
                       unset, allowunset=T);
      } else {
        private.operations['Data selection'].button[select].selector :=
          ge.array(private.operations['Data selection'].frames[select], unset,
                   allowunset=T);
      }
      if (is_string(msfile) && (msfile != '')) {
        private.operations['Data selection'].
          button[select].selector.setcontext('ms', msfile);
      }
      if (select != 'zerospacing') {
        private.operations['Data selection'].getbutton[select] :=
          ws.button(private.operations['Data selection'].frames[select],
                    'Range');
        private.operations['Data selection'].getbutton[select].range := select;
        ws.popuphelp(private.operations['Data selection'].getbutton[select],
                     paste('Get full range for', select, 
                           'from the MeasurementSet'));
        whenever private.operations['Data selection'].getbutton[select]->press do {
          if (private.lock('top')) {
            field := $agent.range;
            if (field == 'antennas') {
              result := unique([private.ranges.antenna1,
                                private.ranges.antenna2]);
            } else if (field == 'feeds') {
              result := unique([private.ranges.feed1, private.ranges.feed2]);
            } else if (field == 'fields') {
              result := private.ranges.field_id;
            } else {
              result := private.ranges[field];
            }
            if (!is_fail(result)) {
              if (is_string(result)) {
                private.operations['Data selection'].button[field].selector.insert(result);
              } else {
# If the number is a double we need to ensure that the range displayed
# is rounded away from zero to include all the relevant
# numbers. Otherwise selecting data based on the displayed range may
# miss some points at the edge.
                if (is_double(result)) {
                  local scale := max(abs(result))/1E8;
                  if (scale != 0.0) {
                    local sign := array(1, len(result));
                    sign[result < 0.0] := -1;
                    sign[result == 0.0] := 0;
                    result := as_integer(result/scale + sign) * scale;
                  }
                }
                private.operations['Data selection'].button[field].selector.insert(as_string(result));
              }
            }
            private.unlock();
          }
        } private.pushwhenever();
      }
    }
    private.operations['Data selection'].frames.update :=
      ws.frame(private.operations['Data selection'].topframe, side='right',
               expand='x');
    private.operations['Data selection'].button.update.selector :=
      ws.button(private.operations['Data selection'].frames.update,
                'Update', type='action');
    private.operations['Data selection'].frames.updateleft :=
      ws.frame(private.operations['Data selection'].frames.update,
               side='left', expand='x');
    private.operations['Data selection'].button.update.label :=
      ws.label(private.operations['Data selection'].frames.updateleft,
               'Update ranges', justify='left');
    ws.popuphelp(private.operations['Data selection'].button.update.label,
                 'Press to update the Range buttons for the current selection');

    whenever private.operations['Data selection'].button.update.selector->press do {
      if (private.lock('top')) {
        result := private.getranges(T);
        if (!is_fail(result)) {
          private.ranges := result;
          note('Selection buttons updated with ranges for selected data');
        }
        private.unlock();
      }
    } private.pushwhenever();

# Set up the 'Spectral selection' subframe.
    private.operations['Spectral selection'].button := [=];
    private.operations['Spectral selection'].frames := [=];
    private.operations['Spectral selection'].rframe := [=];
    private.operations['Spectral selection'].getbutton := [=];
    private.operations['Spectral selection'].frames.spwid :=
      ws.frame(private.operations['Spectral selection'].topframe,
               side='right', expand='x');
    private.operations['Spectral selection'].button.spwid.selector :=
      ge.array(private.operations['Spectral selection'].frames.spwid,
               value=[1], allowunset=F);
    private.operations['Spectral selection'].button.spwid.label :=
      ws.label(private.operations['Spectral selection'].frames.spwid,
               'List of spectral windows');
    whenever private.operations['Spectral selection'].button.spwid.selector->value do {
      value := $value;
      private.update.spectral(value);
    } private.pushwhenever();
    for (type in field_names(private.types.spectral)) {
      private.operations['Spectral selection'].frames[type] :=
        ws.frame(private.operations['Spectral selection'].topframe,
                 side='right', expand='x');
      thisdatatype := ref private.types.spectral[type];
      thisframe := ref private.operations['Spectral selection'].frames[type];
      private.operations['Spectral selection'].button[type].selector :=
        ge[thisdatatype](thisframe, value=1, default=1, allowunset=F);
      private.operations['Spectral selection'].button[type].label :=
        ws.label(private.operations['Spectral selection'].frames[type],
                 private.labels.spectral[type]);
      ws.popuphelp(private.operations['Spectral selection'].button[type].label,
                   paste('Channel specification: set NCHAN, START, STEP, and',
                         'WIDTH, e.g. NCHAN=3, START=2, STEP=3, WIDTH=5 produces',
			 '3 output channels starting with input channel 2,',
			 'stepping by 3 and averaging in chunks of 5, i.e.,',
			 'the three output channels will be averages of channels',
			 '[2,3,4,5,6], [5,6,7,8,9], and [8,9,10,11,12], respectively.',
			 '(Note: channel averaging with WIDTH is not supported in',
			 'edit=T mode)'));
    }
# Set up the 'Polarization selection' subframe.
    private.operations['Polarization selection'].button := [=];
    private.operations['Polarization selection'].frames := [=];
    private.operations['Polarization selection'].rframe := [=];
    private.operations['Polarization selection'].getbutton := [=];
    private.operations['Polarization selection'].frames.polid :=
      ws.frame(private.operations['Polarization selection'].topframe,
               side='left', expand='x');
    private.operations['Polarization selection'].button.polid.label :=
      ws.label(private.operations['Polarization selection'].frames.polid,
               'Polarization id');
    private.operations['Polarization selection'].button.polid.selector :=
      ge.choice(private.operations['Polarization selection'].frames.polid,
               options="unset");
    private.operations['Polarization selection'].frames.polarizations :=
      ws.frame(private.operations['Polarization selection'].topframe,
               side='right', expand='x');
    thisframe := 
      ref private.operations['Polarization selection'].frames.polarizations;
    private.operations['Polarization selection'].button.polarizations.
      selector := ge.string(thisframe, value='', allowunset=F);
    private.operations['Polarization selection'].button.polarizations.label :=
      ws.label(private.operations['Polarization selection'].frames.
               polarizations, 'Polarization names');
    ws.popuphelp(private.operations['Polarization selection'].button.
                 polarizations.label,
                 paste('Allowed polarizations e.g. RR RL LL XX YY XY.',
                       'Except when flagging derived polarizations like ',
                       'I Q U V are also allowed.'));
# 
# The bottom frame
#
    private.bottomframe :=
      ws.frame(private.frames.top, side='left', expand='x');
    # Menu for controlling inputs
    private.inputsbutton := 
      ws.button(private.bottomframe, 'Arguments', relief='groove', type='menu');
    ws.popuphelp(private.inputsbutton,
                 'Various operations on inputs of currently selected function');
    private.inputsmenu := [=];

    private.inputsmenu.save := 
      ws.button(private.inputsbutton, 'Save arguments to named location');
    # Save button
    whenever private.inputsmenu.save->press do {
      if (private.lock('top')) {
        label :=  private.inputsname.get();
        if (strlen(label) > 0) {
          ws.tk_hold();
          private.savestate(label);
          ws.tk_release();
        }
        private.unlock();
      }
    } private.pushwhenever();

    private.inputsmenu.restore :=
      ws.button(private.inputsbutton, 'Restore arguments from named location');
    whenever private.inputsmenu.restore->press do {
      if (private.lock('top')) {
        label :=  private.inputsname.get();
        if (strlen(label) > 0) {
          ws.tk_hold();
          private.restorestate(label, checkms=F);
          ws.tk_release();
        }
        private.unlock();
      }
    } private.pushwhenever();

   private.inputsname :=
     ge.string(private.bottomframe, value='lastsave', onestring=T);

    private.bottomrightframe :=
      ws.frame(private.bottomframe, side='right', expand='x');
    private.dismissbutton :=
      ws.button(private.bottomrightframe, 'Dismiss', type='dismiss');
    ws.popuphelp(private.dismissbutton, 
                 paste('Hides the msplot windows. ',
                       'Get them back using the gui function.'));
    private.donebutton :=
      ws.button(private.bottomrightframe, 'Done', type='halt');
    ws.popuphelp(private.donebutton, 'Shuts down msplot');
    ws.tk_release();
# Put the gui into its closed state;
    private.closegui();

# Now service the various events that are generated by the GUI
#-------------------------------------------------------------
#
# Open a file. Close any existing MS.
#
    whenever private.filemenu.openro->press,private.filemenu.openrw->press do {
      local edit := $agent.edit;
      local title := 'to plot'; 
      if (edit == T) title := 'to edit';
      include 'minicatalog.g';
      mcat := minicatalog(allowedtypes=['Measurement Set', 'Directory'],
                          title=paste('Select a measurement set', title),
                          hasbuttons=T);
      await mcat->doubleclick, mcat->done;
      local name := $name; local value := $value;
      mcat.done();
      if (name == 'doubleclick') {
        public.open(value.fname, edit);
      }
    } private.pushwhenever();
#
# Close an MS
#
    whenever private.filemenu.close->press do {
      private.close();
    } private.pushwhenever();
#
# Reshow the action GUI
#
    whenever private.filemenu.show->press do {
      if (private.lock('top')) {
        private.plot.status->postnoforward(spaste('Showing existing ',
                                                  private.type));
        private[private.type].topframe->map();
        private.unlock();
      }
    } private.pushwhenever();
#
# Now process go actions
#
    whenever private.action.go->press do {
      wider private;
      action := private.action.show.getlabel();
      if (action == private.showtypes.all[1]) {
        if (private.lock('plot')) {
          private.plot.initialize();
          result := private.plotxy(F);
          if (is_fail(result)) private.plot.status->post(result::message);
          private.plot.finalize();
          private.unlock();
          if (private.edit) private.plot.select.start();
        }
      } else if (action == private.showtypes.all[2]) {
        if (private.lock('plot')) {
          private.plot.initialize();
          result := private.plotuv();
          if (is_fail(result)) private.plot.status->post(result::message);
          private.plot.finalize();
        private.unlock();
      }
    } else if (action == private.showtypes.all[3]) {
      if (private.lock('plot')) {
          private.plot.initialize(T);
          private.plot.topframe->map();
          private.axis.X := private.axes.ur;
          private.thisplot.axis.X := ref private.axis.X;
          result := private.plotuvslice();
          if (is_fail(result)) private.plot.status->post(result::message);
          private.plot.finalize();
          if (private.edit) private.plot.select.start();
        private.unlock();
      }
    } else if (action == private.showtypes.all[4]) {
      if (private.lock('plot')) {
          private.plot.initialize();
          private.plot.topframe->map();
          result := private.plotlonglat();
          if (is_fail(result)) private.plot.status->post(result::message);
          private.plot.finalize();
        private.unlock();
      }
    } else if (action == private.showtypes.all[5]) {
      if (private.lock('plot')) {
          private.plot.initialize(T);
          private.plot.topframe->map();
          private.axis.X := private.axes.longituder;
          private.thisplot.axis.X := ref private.axis.X;
          result := private.plotlonglatslice();
          if (is_fail(result)) private.plot.status->post(result::message);
          private.plot.finalize();
          if (private.edit) private.plot.select.start();
          private.unlock();
      }
    } else if (action == private.showtypes.all[6]) {
      if (private.lock('display')) {
        private.display.initialize();
        result := private.displayvis(private.axis.Z);
        if (is_fail(result)) throw(result::message);
        private.display.finalize();
        private.display.select.start();
        private.unlock();
      }
    } else if (action == private.showtypes.all[7]) {
      private.ms.summary(verbose=T);
    } else if (action == private.showtypes.all[8]) {
        private.listvis();
      }
    } private.pushwhenever();
#
# Stop the current operation
#
    whenever private.action.stop->press do {
      if (is_record(private.plot.pgplotter)) {
        note('Stopping at next possible opportunity', priority='WARN');
        private.stop:=T;
      }
    } private.pushwhenever();
#
# Exit msplot (as much as we can do!)
#
    whenever private.filemenu.exit->press, private.donebutton->press do {
      public.done();
    } private.pushwhenever();

# Dismiss the gui
    whenever private.filemenu.dismiss->press, private.dismissbutton->press do {
      public.dismiss();
    } private.pushwhenever();
# That's it: we've made the Main GUI
    return T;
  }
#
# ensure that all agents associated with the gui are deleted.
#
  private.donegui := function() {
    wider private;
    const ws := ref private.tools.widgetserver;
    private.plot.donegui();
    private.display.donegui();

# Now do the main gui.
    ws.popupremove(private.filebutton);
    ws.popupremove(private.optionsbutton);
    private.helpmenu.done();
    private.action.show.done();
    ws.popupremove(private.action.iterate)
    private.action.pause.done();
    ws.popupremove(private.action.incrementlabel);
    private.action.increment.done();
    ws.popupremove(private.action.go);
    ws.popupremove(private.action.stop);
    for (axis in "X Y Z") {
      ws.popupremove(private.toolbar[axis].submenu.Data.submenu.What);
      ws.popupremove(private.toolbar[axis].submenu.Data.submenu.Values);
      if (axis != 'Z') {
        ws.popupremove(private.toolbar[axis].topbutton);
      } else {
        ws.popupremove(private.toolbar[axis].button.datasubmenu);
      }
    }
    private.tabdialog.done();
    for (select in "X Y") {
      private.operations['X, Y plot limits'].button[select].selector.done();
      ws.popupremove(private.operations['X, Y plot limits'].button[select].label);
      ws.popupremove(private.operations['X, Y plot limits'].getbutton[select]);
    }
    for (select in private.selecttypes.all) {
      private.operations['Data selection'].button[select].selector.done();
      ws.popupremove(private.operations['Data selection'].button[select].label);
      if (select != 'zerospacing') {
        ws.popupremove(private.operations['Data selection'].getbutton[select]);
      }
    }
    ws.popupremove(private.operations['Data selection'].button.update.label);
    #remove the following line when defect 2862 is fixed.
    val private.operations['Data selection'].frames.time := F; 
    private.operations['Spectral selection'].button.spwid.selector.done();
    for (type in field_names(private.types.spectral)) {
      private.operations['Spectral selection'].button[type].selector.done();
      for (type in "nchan start width inc") {
        if (type == 'width' && !private.edit) {
          ws.popupremove(private.operations['Spectral selection'].button[type].label);
        }
      }
    }
    private.operations['Polarization selection'].button.polid.selector.done();
    private.operations['Polarization selection'].button.polarizations.selector.done();
    ws.popupremove(private.operations['Polarization selection'].button.polarizations.label);
    ws.popupremove(private.inputsbutton);
    private.inputsname.done();
    ws.popupremove(private.donebutton);
# #!#!# Look at this again when defect 2787 has been fixed.
#     for (field in "plot display") {
#       if (has_field(private, field) && is_record(private[field])) {
#       popupremove(private[field].topframe)
#       }
#     }
# #!#!#
#     for (field in field_names(private.frames)) {
# #      private.frames[field]->unmap();
# #     private.frames[field] := F;
#     }
  }
#
# Generate a plot window.
#
  private.plot.gui := function() {
    wider private;
# If the window already exists then just map it.
    if (is_agent(private.plot.topframe)) {
      private.plot.topframe->map();
      return T;
    }
# Looks like the window needs to be built from scratch
    const ws := ref private.tools.widgetserver;
    const ge := ref private.tools.guientry;
    ws.tk_hold();

    private.plot.topframe := ws.frame(title='msplot: plot');
    if (private.edit) {
      private.plot.holderframe :=
        ws.frame(private.plot.topframe, side='top', expand='x');
      private.plot.topmodeframe :=
        ws.frame(private.plot.holderframe, side='top', relief='ridge',
                 expand='x');
      private.plot.label :=
        ws.label(private.plot.topmodeframe, 'Editing commands');
      
      private.plot.modeframe :=
        ws.frame(private.plot.topmodeframe, side='left', expand='x');
      private.plot.policyframe :=
        ws.frame(private.plot.topmodeframe, side='left', expand='x');
      private.plot.mode := [=];
      private.plot.mode.policylabel :=
        ws.label(private.plot.policyframe, 'Flag all ');
      private.plot.mode.policy := [=];
      for (b in "channels correlations") {
        private.plot.mode.policy[b] :=
          ws.button(private.plot.policyframe, b, type='check');
        ws.popuphelp(private.plot.mode.policy[b],
                     paste('Check this button to flag all the', b, 
                           'in the baseline if any point is inside the',
                           'selected region. This button is disabled if you',
                           'do not plot all the', b, '.'));
      }
      
      private.plot.mode.list := ws.button(private.plot.modeframe, 'List');
      ws.popuphelp(private.plot.mode.list, 'List all editing definitions');
      whenever private.plot.mode.list->press do {
	private.plot.flag := T;
	private.plot.select.list();
	private.plot.status->postnoforward('List all editing definitions');
      } private.pushwhenever();
      private.plot.mode.cancel := ws.button(private.plot.modeframe, 'Cancel');
      ws.popuphelp(private.plot.mode.cancel, 'Cancel last editing definition');
      whenever private.plot.mode.cancel->press do {
	private.plot.select.cancel();
	private.plot.status->post('Canceling last editing definition');
      } private.pushwhenever();
      private.plot.mode.clear := ws.button(private.plot.modeframe, 'Clear');
      ws.popuphelp(private.plot.mode.clear, 'Clear all edits');
      whenever private.plot.mode.clear->press do {
	private.plot.select.clear();
	private.plot.status->post('Edits cleared');
      } private.pushwhenever();
      
      private.plot.rightmodeframe:=
	ws.frame(private.plot.modeframe, side='right', expand='x');
      private.plot.mode.Unflag :=
	ws.button(private.plot.rightmodeframe, 'Unflag', type='action');
      ws.popuphelp(private.plot.mode.Unflag, 'Unflag using the defined edits');
      private.plot.mode.Flag :=
	ws.button(private.plot.rightmodeframe, 'Flag', type='action');
      ws.popuphelp(private.plot.mode.Flag, 'Flag using the defined edits');
      whenever private.plot.mode.Flag->press do {
	if (private.lock('plot')) {
	  private.plot.select.stop();
	  private.plot.flag := T;
	  private.plot.select.list();
	  private.plot.initialize();
	  result := private[private.lastplot](T);
	  if (is_fail(result)) return throw(result::message);
	  private.plot.finalize();
	  private.plot.select.start();
	  private.unlock();
	}
      } private.pushwhenever();
      whenever private.plot.mode.Unflag->press do {
        if (private.lock('plot')) {
          private.plot.select.stop();
          private.plot.flag := F;
          private.plot.select.list();
          private.plot.initialize();
          result := private[private.lastplot](T)
            if (is_fail(result)) return throw(result::message);
          private.plot.finalize();
          private.plot.select.start();
          private.unlock();
        }
      } private.pushwhenever();
      private.plot.mode.Locate :=
        ws.button(private.plot.rightmodeframe, 'Locate', type='action');
      ws.popuphelp(private.plot.mode.Locate,
                   'Locate and list data defined by the edits');
      whenever private.plot.mode.Locate->press do {
        if (private.lock('plot')) {
          result := private.locatexy();
          private.plot.flag := F;
          if (is_fail(result)) return throw(result::message);
          private.plot.select.cancelall();
          private.unlock();
        }
      } private.pushwhenever();
      private.plot.mode.Revert :=
	ws.button(private.plot.rightmodeframe, 'Revert');
      ws.popuphelp(private.plot.mode.Revert,
		   paste('Revert to flag status at start of msplot.',
			 'All edits since startup are discarded.'));
      whenever private.plot.mode.Revert->press do {
        if (private.lock('plot')) {
          private.restoreflaginfo(keepflags=F);
          private.plot.select.stop();
          private.plot.initialize();
          result := private[private.lastplot](T);
          if (is_fail(result)) return throw(result::message);
          private.plot.finalize();
          private.plot.status->postnoforward('Flags reverted to original state.');
          private.plot.select.start();
          private.unlock();
        }
      } private.pushwhenever();
      
      private.plot.mode.Help := ws.button(private.plot.rightmodeframe, 'Help');
      ws.popuphelp(private.plot.mode.Help,
                   'Drives your browser to help on editing using msplot.');
      whenever private.plot.mode.Help->press do {
        include 'aips2help.g';
        private.plot.status->postnoforward('Driving browser to help on editing');
        help('Refman:general.ms.msplot');
      } private.pushwhenever();
    }
    
    private.plot.controlholderframe :=
      ws.frame(private.plot.topframe, side='top', expand='x', height=0);
    private.plot.controlframe :=
      ws.frame(private.plot.controlholderframe, side='left', relief='ridge',
               expand='x', height=0);
    private.plot.holder := [=];
    private.plot.holder.pf := 
      ws.button(private.plot.controlframe, 'Plot', type='action');
    ws.popuphelp(private.plot.holder.pf, 'Plot at current angle?');
    whenever private.plot.holder.pf->press do {
      if (private.lock('plot')) {
        private.plot.initialize(T);
        private.axis.X := private.axes.ur;
        private.thisplot.axis.X := ref private.axis.X;
        if (private.datatype == 'syn') {
          result := private.plotuvslice();
        } else {
          result := private.plotlonglatslice();
        }
        if (is_fail(result)) private.plot.status->post(result::message);
        private.plot.finalize();
        if (private.edit) private.plot.select.start();
        private.unlock();
      }
    } private.pushwhenever();
    private.plot.holder.s :=
      ws.scale(private.plot.controlframe, 0, 180, length=190,
               text='Angle of slice');
    ws.popuphelp(private.plot.holder.s,
                 'Angle of slice: 0=>x or u, 90=>y or v');
    whenever private.plot.holder.s->value do {
      private.angle := $value;
    } private.pushwhenever();
    
    private.plot.holder.inclabel :=
      ws.label(private.plot.controlframe, 'Number of slices');
    private.plot.holder.inc :=
      ge.scalar(private.plot.controlframe, value=1, default=1, allowunset=F);
    private.plot.holder.inc.setwidth(4);
    whenever private.plot.holder.inc->value do {
      private.nslices := max(private.plot.holder.inc.get(), 1);
      note('Plotting slices for increments in angle = ', 180.0/private.nslices,
           ' degrees');
    } private.pushwhenever();
    private.plot.controlframe->unmap();
  
    private.plot.feedback := [=];
    private.plot.feedback.textframe :=
      ws.frame(private.plot.topframe, side='top',relief='ridge', expand='x');
    
    private.plot.feedback.label :=
      ws.label(private.plot.feedback.textframe, 'Coordinate values');
    private.plot.feedback.world := [=];
    private.plot.feedback.world.X := [=];
    private.plot.feedback.world.X.frame :=
      ws.frame(private.plot.feedback.textframe,side='left', relief='flat');
    private.plot.feedback.world.X.label :=
      ws.label(private.plot.feedback.world.X.frame, 'World X');
    private.plot.feedback.world.X.message :=
      ws.message(private.plot.feedback.world.X.frame, '', fill='x',
                 relief='flat');
    private.plot.feedback.world.Y := [=];
    private.plot.feedback.world.Y.frame :=
      ws.frame(private.plot.feedback.textframe, side='left', relief='flat');
    private.plot.feedback.world.Y.label :=
      ws.label(private.plot.feedback.world.Y.frame, 'World Y') ;
    private.plot.feedback.world.Y.message :=
      ws.message(private.plot.feedback.world.Y.frame, '', fill='x',
                 relief='flat');
  
    private.plot.statusframe :=
      ws.frame(private.plot.topframe, relief='ridge', expand='x');
    private.plot.status := ws.messageline(private.plot.statusframe);
# The pgplotwidget goes in here.
    private.plot.viewframe := ws.frame(private.plot.topframe);
    include 'pgplotwidget.g';
    private.plot.pgplotter :=
      pgplotwidget(private.plot.viewframe, background='white',
		   foreground='black', havemessages=F, widgetset=ws);
    if (is_fail(private.plot.pgplotter)) {
      return throw('Failed to make pgplot widget: ', 
                   private.plot.pgplotter::message, 
                   origin='msplot.plot.gui');
    }
    private.plot.callbacknumbers.motion :=
      private.plot.pgplotter.setcallback('motion', private.plot.worldcoords);
    local cbnum := private.plot.callbacknumbers.motion;
    private.plot.pgplotter.deactivatecallback(cbnum);
    if (private.edit) {
      for (what in field_names(private.plot.callbacks)) {
        private.plot.callbacknumbers[what] :=
         private.plot.pgplotter.setcallback(what,private.plot.callbacks[what]);
	cbnum := private.plot.callbacknumbers[what];
	private.plot.pgplotter.deactivatecallback(cbnum);
      }
    }
# Now the bottom frame.
    private.plot.bottomframe :=
      ws.frame(private.plot.topframe, side='left', expand='x');
    private.plot.savebutton :=
      ws.button(private.plot.bottomframe, 'Save');
    ws.popuphelp(private.plot.savebutton, 'Save plot to an AIPS++ plot file');
    whenever private.plot.savebutton->press do {
      if (private.lock('plot')) {
        file := private.plot.filename.get();
        private.plot.save(file);
        private.unlock();
      }
    } private.pushwhenever();
    private.plot.printbutton := ws.button(private.plot.bottomframe, 'Print');
    ws.popuphelp(private.plot.printbutton, 'Print plot as a postscript file');
    whenever private.plot.printbutton->press do {
      if (private.lock('plot')) {
        file := private.plot.filename.get();
        private.plot.print(file);
        private.unlock();
      }
    } private.pushwhenever();
    private.plot.filename :=
      ge.file(private.plot.bottomframe, value=unset,
              types=['Postscript', 'Plot file'], allowunset=T);
    private.plot.bottomrightframe :=
      ws.frame(private.plot.bottomframe, side='right', expand='x');
    private.plot.dismiss :=
      ws.button(private.plot.bottomrightframe, 'Dismiss', type='dismiss');
    private.plot.dismiss.type := 'plot';
    whenever private.plot.dismiss->press do {
      private.plot.topframe->unmap();
    } private.pushwhenever();
#
# Now the plot GUI is build so we can release the widgets
#
    ws.tk_release();
    return T;
  }
#
# Deletes the plot window. Should clean up all the agents and remove the frame.
#
  private.plot.donegui := function() {
    wider private;
    # Short circuit if a plot gui was never created. 
    if (!has_field(private.plot, 'topframe') || 
        !is_agent(private.plot.topframe)) {
      return T;
    }

    const ws := ref private.tools.widgetserver;
    const ge := ref private.tools.guientry;
    ws.tk_hold();
    # Delete the widgets in reverse order to their creation. Its not
    # clear to me that this helps. Other deletion orders also seem work.
    private.plot.filename.done();
    ws.popupremove(private.plot.printbutton);
    ws.popupremove(private.plot.savebutton);
    private.plot.pgplotter.done();
    private.plot.status.done();
    val private.plot.statusframe := F; #remove this when defect 2862 is fixed
    private.plot.holder.inc.done();
    ws.popupremove(private.plot.holder.s);
    ws.popupremove(private.plot.holder.pf);
    if (private.edit) {
      ws.popupremove(private.plot.mode.Help);
      ws.popupremove(private.plot.mode.Revert);
      ws.popupremove(private.plot.mode.Locate);
      ws.popupremove(private.plot.mode.Flag);
      ws.popupremove(private.plot.mode.Unflag);
      ws.popupremove(private.plot.mode.clear);
      ws.popupremove(private.plot.mode.cancel);
      ws.popupremove(private.plot.mode.list);
      for (b in "channels correlations") {
        ws.popupremove(private.plot.mode.policy[b]);
      }
    }
    private.plot.topframe := F;
    ws.tk_release();
    return T;
 }
 
  private.display.gui := function() {
    wider private;
#
# If the topframe is an agent then we can just map it
#
    if (is_agent(private.display.topframe)) {
      private.display.topframe->map();
      return T;
    }
# 
# Build the display windows. These are unmapped until needed.
#--------------------------------------------------------------------
    const ws := ref private.tools.widgetserver;
    const ge := ref private.tools.guientry;
    ws.tk_hold();
#
# Now define the display layouts
#
    private.display.topframe := ws.frame(title='msplot: raster display');
    if (private.edit) {
      private.display.holderframe :=
        ws.frame(private.display.topframe, side='top', expand='x');
      private.display.topmodeframe :=
        ws.frame(private.display.holderframe, side='top', relief='ridge',
                 expand='x');
      private.display.label :=
        ws.label(private.display.topmodeframe, 'Editing commands');
      
      private.display.modeframe :=
        ws.frame(private.display.topmodeframe, side='left', expand='x');
  
      private.display.mode := [=];
#      private.display.mode :=
#       ge.check(private.display.policyframe, value='',
#                options = "Antenna Interferometer Time Channel Correlation",
#                nperline=3, allowunset=F,
#                hlp=paste('Sets how data are selected for editing: ',
#                          'by antenna, interferometer, time (range),',
#                          'channel (range), correlation (range)'));
      
#       private.display.mode.policylabel :=
#       ws.label(private.display.policyframe, 'Extend selection over all');
      
# @      local policies := "interferometers antennas times correlations channels spectral_windows";
#       local policies := "interferometers antennas";
#       private.display.mode.policy := [=];
#       for (b in policies) {
#       private.display.mode.policy[b] :=
#         ws.button(private.display.policyframe, b, type='radio', width=20);
# #     ws.popuphelp(private.display.mode.policy[b],
# #                  paste('Check this button to flag all the', b, 
# #                        'in the baseline if any point is inside the',
# #                        'selected region. This button is disabled if you',
# #                        'do not plot all the', b, '.'));
#       }
      
      private.display.mode.list := ws.button(private.display.modeframe, 'List');
      ws.popuphelp(private.display.mode.list, 'List all editing definitions');
      whenever private.display.mode.list->press do {
        private.display.select.list();
        private.display.status->postnoforward('List all editing definitions');
      } private.pushwhenever();
      private.display.mode.cancel := 
        ws.button(private.display.modeframe, 'Cancel');
      ws.popuphelp(private.display.mode.cancel,
                   'Cancel last editing definition');
      whenever private.display.mode.cancel->press do {
        private.display.select.cancel();
      } private.pushwhenever();
      private.display.mode.clear :=
        ws.button(private.display.modeframe, 'Clear');
      ws.popuphelp(private.display.mode.clear, 'Clear all edits');
      whenever private.display.mode.clear->press do {
        private.display.select.clear();
        private.display.status->post('Deleting all editing commands');
      } private.pushwhenever();
      
      private.display.rightmodeframe:=
        ws.frame(private.display.modeframe, side='right', expand='x');
      private.display.mode.Unflag :=
        ws.button(private.display.rightmodeframe, 'Unflag', type='action');
      ws.popuphelp(private.display.mode.Unflag,
                   'Unflag using the defined edits');
      private.display.mode.Flag :=
        ws.button(private.display.rightmodeframe, 'Flag', type='action');
      ws.popuphelp(private.display.mode.Flag, 'Flag using the defined edits');
      whenever private.display.mode.Flag->press do {
        if (private.lock('display')) {
          private.display.flag := T;
          private.display.select.list();
          if (private.display.select.edit() > 0) {
            private.display.initialize();
            result := private.displayvis(private.axis.Z);
            if (is_fail(result)) return throw(result::message);
            private.display.finalize();
          }
          private.unlock();
          private.display.select.start();
        }
      } private.pushwhenever();
      whenever private.display.mode.Unflag->press do {
        if (private.lock('display')) {
          private.display.select.list();
          private.display.flag := F;
          if (private.display.select.edit() > 0) {
            private.display.initialize();
            result := private.displayvis(private.axis.Z);
            if (is_fail(result)) return throw(result::message);
            private.display.finalize();
          }
          private.unlock();
          private.display.select.start();
        }
      } private.pushwhenever();
      private.display.mode.Revert :=
        ws.button(private.display.rightmodeframe, 'Revert');
      ws.popuphelp(private.display.mode.Revert,
                   paste('Revert to flag status at start of msplot.',
                         'All edits since startup are discarded.'));
      whenever private.display.mode.Revert->press do {
        if (private.lock('display')) {
          private.restoreflaginfo(keepflags=F);
          private.display.initialize();
          result := private.displayvis(private.axis.Z);
          if (is_fail(result)) return throw(result::message);
          private.display.finalize();
          private.display.status->postnoforward('Flags reverted to original state.');
          private.display.select.start();
          private.unlock();
        }
       } private.pushwhenever();
      private.display.mode.Help := 
        ws.button(private.display.rightmodeframe, 'Help');
      ws.popuphelp(private.display.mode.Help,
                   'Drives your browser to help on editing using msplot.');
      whenever private.display.mode.Help->press do {
        include 'aips2help.g';
        private.display.status->postnoforward('Driving browser to help on editing');
        help('Refman:general.ms.msplot');
      } private.pushwhenever();
      private.display.policyframe :=
        ws.frame(private.display.topmodeframe, side='top', expand='x');
      private.policygui(private.display.policyframe, ws);
      if (private.datatype == 'sd') {
        private.display.policyframe.antennas -> disable();
        private.display.policyframe.interferometers -> disable();
      }
    }
    
    private.display.feedback := [=];
    private.display.feedback :=
      ws.frame(private.display.topframe, side='top',relief='ridge',expand='x');
    private.display.feedback.top :=
      ws.frame(private.display.feedback, side='left',expand='x');
    private.display.feedback.bottom :=
      ws.frame(private.display.feedback, side='left',expand='x');
    private.display.feedback.field := [=];
    private.display.feedback.field :=
      ws.frame(private.display.feedback.top, side='left', relief='flat');
    private.display.feedback.field.label :=
      ws.label(private.display.feedback.field, 'Field:');
    private.display.feedback.field.message :=
      ws.label(private.display.feedback.field, '', fill='x', width=22,
               justify='right', anchor='w');
    private.display.feedback.spw := [=];
    private.display.feedback.spw :=
      ws.frame(private.display.feedback.top, side='left', relief='flat');
    private.display.feedback.spw.label :=
      ws.label(private.display.feedback.spw, 'Spectral window:') ;
    private.display.feedback.spw.message :=
      ws.label(private.display.feedback.spw, '', fill='x', width=29,
               justify='right', anchor='w');
    private.display.feedback.time := [=];
    private.display.feedback.time :=
      ws.frame(private.display.feedback.bottom, side='left', relief='flat');
    private.display.feedback.time.label :=
      ws.label(private.display.feedback.time, 'Time:');
    private.display.feedback.time.message :=
      ws.label(private.display.feedback.time, '', fill='x', width=23,
               justify='right', anchor='w'); 
    private.display.feedback.ifr := [=];
    private.display.feedback.ifr :=
      ws.frame(private.display.feedback.bottom, side='left', relief='flat');
    private.display.feedback.ifr.label :=
      ws.label(private.display.feedback.ifr, 'Interferometer:');
    private.display.feedback.ifr.message :=
      ws.label(private.display.feedback.ifr, '', fill='x', width=29,
               justify='right', anchor='w');
   
    private.display.statusframe :=
      ws.frame(private.display.topframe, relief='ridge', expand='x');
    private.display.status := ws.messageline(private.display.statusframe);
# This is the viewer display panel
    private.display.viewframe := ws.frame(private.display.topframe);
    include 'viewer.g';
    private.viewer := viewer();
    if (is_fail(private.viewer)) {
      ws.tk_release();
      return throw('Cannot start the viewer. The error was:',
                   private.viewer::message, origin='msplot.display.gui');
    }
    private.viewerdpframe := ws.frame(private.display.viewframe, side='top');
    private.viewerdp :=
      private.viewer.newdisplaypanel(parent=private.viewerdpframe,
                                     width=private.displaywidth,
                                     height=private.displayheight,
                                     hasgui=T, guihasmenubar=F,
                                     isolationmode=T);
    if (is_fail(private.viewerdp)) {
      ws.tk_release();
      return throw('Failed to construct displaypanel:',
                   private.viewerdp::message,
                   origin='msplot.display.gui');
    }
    private.viewerdp.setoptions([rightmarginspacepg=[value=2],
				 leftmarginspacepg=[value=12],
				 topmarginspacepg=[value=3],
				 bottommarginspacepg=[value=7]]);
    
# Now the bottom frame.
    private.display.bottomframe :=
      ws.frame(private.display.topframe, side='left', expand='x');
    private.display.bottomrightframe :=
      ws.frame(private.display.bottomframe, side='right', expand='x');
    private.display.dismiss :=
      ws.button(private.display.bottomrightframe, 'Dismiss', type='dismiss');
    whenever private.display.dismiss->press do {
      private.display.topframe->unmap();
    } private.pushwhenever();
#
# Now the display GUI is build so we can release the widgets
#
    ws.tk_release();
    return T;
  }    
#
# Deletes the display window. Should clean up all the agents and remove the 
# frame.
#
  private.display.donegui := function() {
    wider private;
    # Short circuit if a display gui was never created. 
    if (!has_field(private.display, 'topframe') ||
        !is_agent(private.display.topframe)) {
      return T;
    }

    const ws := ref private.tools.widgetserver;
# Delete the scratch images.
    private.display.deleteimages();
    ws.tk_hold();
    # Delete the widgets in reverse order to their creation. Its not
    # clear to me that this helps. Other deletion orders also seem work.
    private.viewerdp.done();
    val private.viewerdpframe := F;
    private.viewer.done();
    private.display.status.done();
    if (private.edit) {
      ws.popupremove(private.display.mode.list);
      ws.popupremove(private.display.mode.cancel);
      ws.popupremove(private.display.mode.clear);
      ws.popupremove(private.display.mode.Unflag);
      ws.popupremove(private.display.mode.Flag);
      ws.popupremove(private.display.mode.Revert);
      ws.popupremove(private.display.mode.Help);
    }
    private.display.ddoptions := [=];
#    private.display.feedback.spw := F;
#    private.display.feedback.field := F;
#    private.display.feedback.bottom := F;
#    private.display.feedback.top := F;
#    private.display.feedback := F;
    private.display.topframe := F;
    ws.tk_release();
    return T;
  }

#
# Make a scoping policy gui. The supplied parent frame must have side='top'.
# 
  private.policygui := function(ref parent, ws) {
    parent.label := ws.label(parent, 'Extend selection over all:');
    local bwidth := 16;
    local banchor := 'w';
    local btype := 'check';
    local policies := [=];
    policies.top := "interferometers antennas times";
    policies.bottom := ['correlations', 'channels', 'spectral windows'];
    for (f in "top bottom") {
      parent[f] := ws.frame(parent, side='left', expand='x');
      for (p in policies[f]) {
        parent[p] :=
          ws.button(parent[f], p, type=btype, width=bwidth, anchor=banchor);
        if (p != 'antennas') {
          ws.popuphelp(parent[p],
                       paste('Check this button to extend the selection to',
                             'include all the', p,
                             'in the selected measurement set',
                             '(and not just the ones you have marked).'));
        } else {
          ws.popuphelp(parent[p],
                       paste('Check this button to extend the selection to',
                             'include all the data, in the selected',
                             'measurement set, with the same antenna as',
                             'the first antenna in the data you have marked'));
        }
      }
    }

    wider private;
    whenever parent.antennas -> press do {
      if (parent.antennas->state() && parent.interferometers->state()) {
        parent.interferometers->state(F);
      }
    } private.pushwhenever();
    
    whenever parent.interferometers -> press do {
      if (parent.interferometers->state() && parent.antennas->state() ) {
        parent.antennas->state(F);
      }
    } private.pushwhenever();
  }

#
# Set up the GUI according to the data type. Thus we
# have to disable various buttons, etc.
#
  private.selectdatatype := function() {
    wider private;
  
    for (select in private.selecttypes.all) {
      private.operations['Data selection'].frames[select]->unmap();
    }
    for (select in private.selecttypes[private.datatype]) {
      private.operations['Data selection'].frames[select]->map();
    }
  
    for (axis in "X Y") {
      for (type in private.plottypes.all) {
        private.toolbar[axis].button[type]->disabled(T);
      }
      for (type in private.plottypes[private.datatype]) {
        private.toolbar[axis].button[type]->disabled(F);
      }
    }
#
# Now disable selections for X, Y, Z
#
    for (axis in "X Y Z") {
      for (v in private.visvalues.all) {
        private.toolbar[axis].submenu.Data.submenu.Values.button[v]->disabled(T);
      }
      for (v in private.visvalues[private.datatype]) {
        private.toolbar[axis].submenu.Data.submenu.Values.button[v]->disabled(F);
      }
      for (w in private.viswhats.all) {
        private.toolbar[axis].submenu.Data.submenu.What.button[w]->disabled(T);
      }
      for (w in private.viswhats[private.datatype]) {
        private.toolbar[axis].submenu.Data.submenu.What.button[w]->disabled(F);
      }
    }
    if (private.datatype == 'syn') {
      private.toolbar.X.button.uvdist->state(T);
      private.toolbar.Y.button.data->state(T);
      private.toolbar.Y.submenu.Data.submenu.What.button.corrected->state(T);
      private.toolbar.Y.submenu.Data.submenu.Values.button.amplitude->state(T);
      private.toolbar.Z.submenu.Data.submenu.What.button.corrected->state(T);
      private.toolbar.Z.submenu.Data.submenu.Values.button.amplitude->state(T);
    } else {
      private.toolbar.X.button.time->state(T);
      private.toolbar.Y.button.data->state(T);
      private.toolbar.Y.submenu.Data.submenu.What.button.observed->state(T);
      private.toolbar.Y.submenu.Data.submenu.Values.button.float_data->state(T);
      private.toolbar.Z.submenu.Data.submenu.What.button.observed->state(T);
      private.toolbar.Z.submenu.Data.submenu.Values.button.float_data->state(T);
    }
    private.action.show.replace(private.showtypes[private.datatype]);
  }
#
# Set up the GUI according to the data type. Thus we
# have to disable various buttons, etc.
#
  private.selectaction := function() {
    wider private;
    
# Enable everything
    for (axis in "X Y") {
      private.toolbar[axis].topbutton->disabled(F);
    }
    private.toolbar.Z.button.datasubmenu->disabled(F);
    private.action.iterate->disabled(F);
    private.action.stop->disabled(F);
    private.action.pause->disabled(F);

    local action := private.action.show.getlabel();
    if (action == private.showtypes.all[1]) { # xy
      private.toolbar.Z.button.datasubmenu->disabled(T);
    } else if (action == private.showtypes.all[2]) { # uv
      for (axis in "X Y") {
        private.toolbar[axis].topbutton->disabled(T);
      }
      private.toolbar.Z.button.datasubmenu->disabled(T);
    } else if (action == private.showtypes.all[3]) { # uv slice
      private.toolbar.X.topbutton->disabled(T);
      private.toolbar.Z.button.datasubmenu->disabled(T);
    } else if (action == private.showtypes.all[4]) { # long lat
      for (axis in "X Y") {
        private.toolbar[axis].topbutton->disabled(T);
      }
      private.toolbar.Z.button.datasubmenu->disabled(T);
    } else if (action == private.showtypes.all[5]) { # long slice
      private.toolbar.X.topbutton->disabled(T);
      private.toolbar.Z.button.datasubmenu->disabled(T);
    } else if (action == private.showtypes.all[6]) { # image
      for (axis in "X Y") {
        private.toolbar[axis].topbutton->disabled(T);
      }
    } else if (action == private.showtypes.all[7]) { # summarize
      for (axis in "X Y") {
        private.toolbar[axis].topbutton->disabled(T);
      }
      private.action.pause->disabled(T);
      private.action.iterate->disabled(T);
      private.action.stop->disabled(T);
      private.toolbar.Z.button.datasubmenu->disabled(T);
    } else if (action == private.showtypes.all[8]) { # list
      for (axis in "X Y") {
        private.toolbar[axis].topbutton->disabled(T);
      }
      private.action.pause->disabled(T);
      private.action.iterate->disabled(T);
      private.action.stop->disabled(T);
      private.toolbar.Z.button.datasubmenu->disabled(T);
    }
  }
#
# Do we need some new axes? Check to see if any of the
# data being iterated over have changed. If so then new
# axes are needed.
# 
  private.needaxes := function() {
    wider private;
  
    local needaxes := (private.thisplot.npages == 0);
  
    local iteration := private.getiteration();
    if (length(iteration) > 0) {
      local iterationdata := private.selectedms.range(to_upper(iteration));
      for (field in field_names(iterationdata)) {
        local value := unique(iterationdata[field]);
        if (has_field(private.iteration.last, field)) {
          if (private.iteration.last[field] != value) {
            needaxes := T;
          }
        } else {
          needaxes := T;
        }
        private.iteration.last[field] := value;
      }
    }
    return needaxes;
  }

  private.getvisdata := function(xaxis, yaxis) {
  
    wider private;

#
# Now we're going to get the actual data. First we have to do 
# some special things for various x and y axes
#
    const what := unique([xaxis.name, yaxis.name, 'flag',
                          'flag_row', 'antenna1', 'antenna2',
                          'time', 'field_id', 'data_desc_id',
                          'axis_info']);
#    local data := private.selectedms.getdata(what);
    local data := private.selectedms.getdata(what[what!='channel' & what!='frequency']);

    if (any(what=='channel')) {
      local dshape:=shape(data.flag);
      data.channel:=array(0,dshape[1],dshape[2],dshape[3]);
      for (i in 1:dshape[1]) {
        data.channel[i,,]:=array(private.data.statistics['chan_num'],dshape[2],dshape[3]);
      }
    }

    if (any(what=='frequency')) {
      local dshape:=shape(data.flag);
      data.frequency:=array(0,dshape[1],dshape[2],dshape[3]);
      for (i in 1:dshape[3]) { 
        for (j in 1:dshape[1]) {
          data.frequency[j,,i]:=private.data.statistics.chan_freq[,data.data_desc_id[i]];
        }
      }
    }


    if (!has_field(data, xaxis.name)) {
      return throw('Illegal x axis ', xaxis.name, origin='msplot.getvisdata');
    }
    if (!has_field(data, yaxis.name)) {
      return throw('Illegal y axis ', yaxis.name, origin='msplot.getvisdata');
    }
    private.increment := as_integer(private.action.increment.get());
    if (private.increment <= 1) {
      data.x := ref data[xaxis.name];
      data.y := ref data[yaxis.name];
      return data;
    }
# Only return some rows
    local rec := [=];
    const selectedrows := seq(1, length(data.time), private.increment);
    if (is_fail(selectedrows)) fail;
    for (f in what) {
      if (f != 'axis_info') {
	local colshape := shape(data[f]);
	local ndim := len(colshape);
	if (ndim == 3) {
	  rec[f] := data[f][,,selectedrows];
# glish removes degenerate axes ie., where length == 1. Put them back here.
	  if (any(colshape[1:2] == 1)) {
	    rec[f]::shape := [colshape[1], colshape[2], len(selectedrows)];
	  }
	} else if (ndim == 2) {
	  rec[f] := data[f][,selectedrows];
	  if (colshape[1] == 1) {
	    rec[f]::shape := [colshape[1],len(selectedrows)];
	  }
	} else if (ndim == 1) {
	  rec[f] := data[f][selectedrows];
	}
      } else {
	rec.axis_info := data.axis_info;
      }
    }
    rec.x := ref rec[xaxis.name];
    rec.y := ref rec[yaxis.name];
    return rec;
  }

  private.datashape := function() {
    local dd := private.getvalue.data_desc_id();
    if (is_unset(dd)) dd := private.datadescid;
    if (is_fail(dd)) fail;
    local polid := private.polid[dd[1]];
    local ncorrs := length(private.data.polarization[polid]);
    local nchan := private.data.spectral.numchan[private.spwid[dd[1]]];
    return [ncorrs, nchan];
  }

  private.allcorrelations := function() {
    local dd := private.getvalue.data_desc_id();
    if (is_unset(dd)) dd := private.datadescid;
    if (is_fail(dd)) fail;
    return  private.data.spectral.numchan[private.spwid[dd[1]]];
  }

  private.putvisflags := function(flag, flag_row) {
    wider private;
    rec := [flag=flag, flag_row=flag_row];
    return private.selectedms.putdata(rec);
  }

#
# Get the actual visdata. Here we select clumps of rows.
# 
  private.getuvdata := function() {
  
    wider private;
#    
# Now we're going to get the actual data. First we have to do 
# some special things for various x and y axes
#
    local data := private.selectedms.getdata(['U', 'V', 'axis_info']);
    if (!has_field(data, 'u')) {
      return throw('u axis not valid', origin='msplot.getuvdata');
    }
    if (!has_field(data, 'v')) {
      return throw('v axis not valid', origin='msplot.getuvdata');
    }
    private.increment := as_integer(private.action.increment.get());
    if (private.increment <= 1) {
      data.x := ref data.u;
      data.y := ref data.v;
      return data;
    }
    local rec := [=];
    const selectedrows := seq(1, length(data.u), private.increment);
    if (is_fail(selectedrows)) fail;
    rec.x := data.u[selectedrows];
    rec.y := data.v[selectedrows];
    rec.axis_info := data.axis_info;
    data := F;
    return rec;
  }

  private.getlonglat := function (times=F) {
    wider private;
    rec := [=];
    if (!has_field(private.data.pointing, 'time')) {
      return throw('No pointing information available');
    }
    if (!is_boolean(times)) {
      rec.time := times;
      rec.direction := [=];
      rec.direction.longitude := array(0.0, length(rec.time));
      rec.direction.latitude  := array(0.0, length(rec.time));
      rec.target := [=];
      rec.target.longitude := array(0.0, length(rec.time));
      rec.target.latitude  := array(0.0, length(rec.time));
      ilast := 1;
      for (j in 1:length(rec.time)) {
        for (i in ilast:length(private.data.pointing.time)) {
          if (abs(private.data.pointing.time[i]-rec.time[j])<
             private.data.pointing.interval[i]) {
            rec.direction.longitude[j] :=
                private.data.pointing.direction[1,1,i];
            rec.direction.latitude[j]  :=
                private.data.pointing.direction[2,1,i];
            rec.target.longitude[j] :=
                private.data.pointing.target[1,1,i];
            rec.target.latitude[j]  :=
                private.data.pointing.target[2,1,i];
            ilast := i;
            break;
          }
        }
      }
    } else {
      rec.direction := [=];
      rec.direction.longitude := private.data.pointing.direction[1,,];
      rec.direction.latitude  := private.data.pointing.direction[2,,];
      rec.target := [=];
      rec.target.longitude := private.data.pointing.target[1,,];
      rec.target.latitude  := private.data.pointing.target[2,,];
    }
    rec.direction.longitude +:= 2*pi;
    rec.target.longitude    +:= 2*pi;
    rec.direction.latitude  +:= 2*pi;
    rec.target.latitude     +:= 2*pi;

    return rec;
  }

  private.getlonglatdata := function() {
  
    wider private;
#    
# Now we're going to get the actual data. First we have to do 
# some special things for various x and y axes
#
    data := private.selectedms.getdata(['time', 'axis_info']);
    private.increment := as_integer(private.action.increment.get());
    ss := seq(1, length(data.time), private.increment);
    times := data.time[ss];
    rec := private.getlonglat(times);
    rec.axis_info := data.axis_info;
    data := F;
  
    return rec;
  }

#
# Get the interferometer-based data: axes are (pol, ifr, chan, row)
#
  private.getifrdata := function(zaxis) {
  
    wider private;
    local data := private.selectedms.
      getdata([zaxis.name, 'flag', 'flag_row',
               'field_id', 'data_desc_id', 'axis_info'], T);
    if (!has_field(data, zaxis.name)) {
      return throw(paste("Illegal z axis ", zaxis.name));
    }
    rec := [=];
    rec.z := data[zaxis.name];
    rec.flag := data.flag;
    rec.flag_row := data.flag_row;
    rec.field_id := data.field_id;
    rec.data_desc_id := data.data_desc_id;
    rec.axis_info := data.axis_info;
    return rec;
  }

#
# Specialized uv plotter: knows to reflect axes. Errors cause a 
# fail.
#
  private.plotuv := function() {
  
    wider private;
  
    private.plot.pgplotter.clear();
  
    private.axis.X := private.axes.u;      
    private.thisplot.axis.X := ref private.axis.X;
    private.axis.Y := private.axes.v;
    private.thisplot.axis.Y := ref private.axis.Y;
  
    private.plot.status->
      post(paste('*************** Plot UV coverage ***************'));
    if (is_fail(private.iterinit())) fail;
    
    local rec := private.getuvdata();
    while (!is_fail(rec)) {
      if (!private.plot.standardscaling(rec.x, rec.y,
					private.axes.u,
					private.axes.v)) return T;
      private.plot.pgplotter.sci(1);
      private.plot.pgplotter.pt(rec.x, rec.y, -1);
      private.plot.pgplotter.sci(2);
      private.plot.pgplotter.pt(-rec.x, -rec.y, -1);
      private.plot.pgplotter.sci(1);
      private.thisplot.npoints +:= 2 * length(rec.x);
      if (!private.iternext()) break;
      rec := private.getuvdata();
    }
  
    if (private.thisplot.npages > 0) {
      return T;
    } else {
      return throw('No valid data for UV coverage', origin='msplot.plotuv');
    }
  }

#
# Specialized long lat plotter
#
  private.plotlonglat := function() {
  
    wider private;
  
    private.plot.pgplotter.clear();
  
    private.axis.X := private.axes.longitude;      
    private.thisplot.axis.X := ref private.axis.X;
    private.axis.Y := private.axes.latitude;
    private.thisplot.axis.Y := ref private.axis.Y;
  
    private.plot.status->post(paste('*************** Plot Longitude, Latitude coverage ***************'));
  
    if (is_fail(private.iterinit())) fail;
  
    rec := private.getlonglatdata();
    private.data.pointing.rec := rec;
    while (!is_fail(rec)) {
      if (!private.plot.standardscaling(rec.direction.longitude,
                                  rec.direction.latitude,
                                  private.axes.longitude,
                                  private.axes.latitude)) return T;
      private.plot.pgplotter.sci(1);
      private.plot.pgplotter.pt(rec.direction.longitude, rec.direction.latitude, -1);
      private.plot.pgplotter.sci(2);
      private.plot.pgplotter.pt(rec.target.longitude, rec.target.latitude, -1);
      private.plot.pgplotter.sci(1);
      private.thisplot.npoints +:= length(rec.direction.longitude);
      if (!private.iternext()) break;
      rec := private.getlonglatdata();
    }
  
    if (private.thisplot.npages > 0) {
      return T;
    } else {
      return throw('No valid data for long lat coverage');
    }
  }

  private.plotrec := function(rec) {
    wider private;
  
    const colors := [1, 2, 7, 4, 3, 5, 6, 8];
    const polnames := rec.axis_info.corr_axis;
    const flagshape := shape(rec.flag);
    const ncorr := flagshape[1];
    const nchan := flagshape[2];
    const xshape := shape(rec.x);
    const xdim := len(xshape);
    const yshape := shape(rec.y);
    const ydim := len(yshape);
    if (xdim > 1 | ydim > 1) {
      for (corr in 1:ncorr) {
	private.plot.pgplotter.sci(colors[corr]);
	private.plot.pgplotter.mtxt(side='t', disp=1.0,
				    coord=0.01+0.05*(corr-1),
				    fjust=0.5, text=polnames[corr]);
      }
    }

    # All channels and correlators are done
    if (ydim == 1) {
      if (xdim == 1) {
	local npts := flagshape[3];
	local mask := array(T, npts);
        if (!private.optionsmenu.plotflagged->state()) {
	  for (corr in 1:ncorr) {
	    for (chan in 1:nchan) {
	      mask &:= rec.flag[corr, chan,];
	    }
	  }
	  mask |:= rec.flag_row;
	  mask := !mask;
	  npts := sum(mask);
	}
	if (npts > 0) {
	  private.plot.pgplotter.sci(colors[1]);
	  private.plot.pgplotter.pt(rec.x[mask], rec.y[mask], 1);
	  private.thisplot.npoints +:= npts;
	}
      } else {
        for (corr in 1:ncorr) {
	  private.plot.pgplotter.sci(colors[corr]);
	  if (xdim == 3) {
	    for (chan in 1:nchan) {
	      local npts := flagshape[3];
	      local mask := array(T, npts);
	      if (!private.optionsmenu.plotflagged->state()) {
		mask := !(rec.flag_row | rec.flag[corr,chan,]);
		npts := sum(mask);
	      }
	      if (npts > 0) {
		private.plot.pgplotter.pt(rec.x[corr,chan,][mask], 
					  rec.y[mask], 1);
		private.thisplot.npoints +:= npts;
	      }
	    }
	  } else if (xdim == 2) {
	    local npts := flagshape[3];
	    local mask := array(T, npts);
	    if (!private.optionsmenu.plotflagged->state()) {
	      for (chan in 1:nchan) {
		mask &:= rec.flag[corr,chan,];
	      }
	      mask |:= rec.flag_row;
	      mask := !mask;
	      npts := sum(mask);
	    }
	    if (npts > 0) {
	      private.plot.pgplotter.pt(rec.x[corr,][mask], rec.y[mask], 1);
	      private.thisplot.npoints +:= npts;
	    }
          }
        }
      }
    } else { # rec.y is 1 or 2D (+1 dimension for the row)
      if (xdim == 1) {
        for (corr in 1:ncorr) {
	  private.plot.pgplotter.sci(colors[corr]);
          if (ydim == 3) { 
            for (chan in 1:nchan) {
	      local npts := flagshape[3];
	      local mask := array(T, npts);
	      if (!private.optionsmenu.plotflagged->state()) {
		mask := !(rec.flag_row | rec.flag[corr,chan,]);
		npts := sum(mask);
	      }
              if (npts > 0) {
		private.plot.pgplotter.pt(rec.x[mask],
					  rec.y[corr,chan,][mask], 1);
		private.thisplot.npoints +:= npts;
	      }
            }
          } else if (ydim == 2) { 
	    local npts := flagshape[3];
	    local mask := array(T, npts);
	    if (!private.optionsmenu.plotflagged->state()) {
	      for (chan in 1:nchan) {
		mask &:= rec.flag[corr,chan,];
	      }
	      mask |:= rec.flag_row;
	      mask := !mask;
	      npts := sum(mask);
	    }
	    if (npts > 0) {
	      private.plot.pgplotter.pt(rec.x[mask], rec.y[corr,][mask], 1);
	      private.thisplot.npoints +:= npts;
	    }
          }
        }
      } else {
	if ((xdim != ydim) || any(xshape != yshape)) {
	  return throw('x and y axes not the same shape',
		       origin='msplot.plotrec');
	}
        for (corr in 1:ncorr) {
	  private.plot.pgplotter.sci(colors[corr]);
	  if (ydim == 3) {
	    for (chan in 1:nchan) {
	      local npts := flagshape[3];
	      local mask := array(T, npts);
	      if (!private.optionsmenu.plotflagged->state()) {
		mask := !(rec.flag_row | rec.flag[corr,chan,]);
		npts := sum(mask);
	      }
	      if (npts > 0) {
		private.plot.pgplotter.pt(rec.x[corr,chan,][mask],
					  rec.y[corr,chan,][mask], 1);
		private.thisplot.npoints +:= npts;
	      }
	    }
	  } else if (ydim == 2) {
	    local npts := flagshape[3];
	    local mask := array(T, npts);
	    if (!private.optionsmenu.plotflagged->state()) {
	      for (chan in 1:nchan) {
		mask &:= rec.flag[corr,chan,];
	      }
	      mask |:= rec.flag_row;
	      mask := !mask;
	      npts := sum(mask);
	    }
	    if (npts > 0) {
	      private.plot.pgplotter.pt(rec.x[corr,][mask],
					rec.y[corr,][mask], 1);
	      private.thisplot.npoints +:= npts;
	    }
	  }
        }
      }
    }
    return T;
  }

  private.flagrec := function(ref rec) {
    wider private;
# The editing policy. This needs to be applied as we flag the data,
# and not as a separate step otherwise there is no way to distinguish
# between the data that was already flagged (to which the editing
# policy should *NOT* be applied) and the data that was just editted
# (to which the editing policy should be applied).
    local doallcorrs := private.plot.mode.policy.correlations->state();
    local doallchans := private.plot.mode.policy.channels->state();
    local nvis  := shape(rec.flag)[3];
    local nchan := shape(rec.flag)[2];
    local ncorr := shape(rec.flag)[1];
    local xdim := len(shape(rec.x)); 
    local ydim := len(shape(rec.y)); 
    if (ydim == 1) {
      if (xdim == 1) {
        for (frec in private.plot.select.records) {
          if (is_record(frec) && has_field (frec, 'valid') && frec.valid) {
            local blc := frec.region.blc;
            local trc := frec.region.trc;
            local mask := ((rec.x > blc[1]) & (rec.x < trc[1])) & 
                          ((rec.y > blc[2]) & (rec.y < trc[2]));
            # All channels and correlators are flagged
            for (corr in 1:ncorr) {
              for (chan in 1:nchan) {
                rec.flag[corr,chan,][mask] := private.plot.flag;
              }
            }
          }
        }
      } else { # assumes xdim is three
        for (frec in private.plot.select.records) {
          if (is_record(frec) && has_field(frec, 'valid') && frec.valid) {
            local blc := frec.region.blc;
            local trc := frec.region.trc;
            local maskx := ((rec.x > blc[1]) & (rec.x < trc[1]));
            local masky := ((rec.y > blc[2]) & (rec.y < trc[2]));
            private.flagrec13(masky, maskx, rec.flag, doallchans , doallcorrs);
          }
        }
      }
    } else { # assumes ydim is three
      if (xdim == 1) {
        for (frec in private.plot.select.records) {
          if (is_record(frec) && has_field(frec, 'valid') && frec.valid) {
            local blc := frec.region.blc;
            local trc := frec.region.trc;
            local maskx := ((rec.x > blc[1]) & (rec.x < trc[1]));
            local masky := ((rec.y > blc[2]) & (rec.y < trc[2]));
            private.flagrec13(maskx, masky, rec.flag, doallchans , doallcorrs);
          }
        }
      } else { # assumes xdim & ydim are three
        if (shape(rec.y) != shape(rec.x)) {
          return throw('x and y axes not the same shape',
                       origin='msplot.flagrec');
        }
        for (frec in private.plot.select.records) {
          if (is_record(frec) && has_field(frec, 'valid') && frec.valid) {
            local blc := frec.region.blc;
            local trc := frec.region.trc;
            local maskx := ((rec.x > blc[1]) & (rec.x < trc[1]));
            local masky := ((rec.y > blc[2]) & (rec.y < trc[2]));
            for (corr in 1:ncorr) {
              for (chan in 1:nchan) {
                local mask := maskx[corr,chan,] & masky[corr,chan,];
                rec.flag[corr,chan,][mask] := private.plot.flag;
              }
            }
          }
        }
      }
    }
    if (private.datashape() == [ncorr, nchan]) {
      for (row in 1:nvis) {
        rec.flag_row[row] := all(rec.flag[,,row]);
      }
    }
    val rec.flag := rec.flag;
    val rec.flag_row := rec.flag_row;
    private.flagged := T;
    return T;
  }


  private.flagrec13 := function(maskx, masky, ref flag, 
                                doallchans, doallcorrs) {
    local nvis  := shape(flag)[3];
    local nchan := shape(flag)[2];
    local ncorr := shape(flag)[1];
    if (doallchans & doallcorrs) {
# Policy == 'Channels' && 'Correlations'
      local mask := array(F, nvis);
      for (corr in 1:ncorr) {
        for (chan in 1:nchan) {
          mask |:= masky[corr,chan,];
        }
      }
      mask &:= maskx;
      for (corr in 1:ncorr) {
        for (chan in 1:nchan) {
          flag[corr,chan,][mask] := private.plot.flag;
        }
      }
    } else if (doallcorrs) {
# Policy == 'Correlations'
      local mask := masky[1,,];
      if (nchan == 1) mask::shape := [1, nvis];
      if (ncorr > 1) {
        for (corr in 2:ncorr) {
          mask |:= masky[corr,,];
        }
      }
      for (nchan in 1:nchan) {
        mask[nchan,] &:= maskx;
      }
      for (corr in 1:ncorr) {
        flag[corr,,][mask] := private.plot.flag;
      }
    } else if (doallchans) {
# Policy == 'Channels'
      local mask := masky[,1,];
      if (ncorr == 1) mask::shape := [1, nvis];
      if (nchan > 1) {
        for (chan in 2:nchan) {
          mask |:= masky[,chan,];
        }
      }
      for (ncorr in 1:ncorr) {
        mask[ncorr,] &:= maskx;
      }
      for (chan in 1:nchan) {
        flag[,chan,][mask] := private.plot.flag;
      }
    } else {
# Policy == none
      for (corr in 1:ncorr) {
        for (chan in 1:nchan) {
          local mask := maskx & masky[corr,chan,];
          flag[corr,chan,][mask] := private.plot.flag;
        }
      }
    }
  }

  private.listrec := function(rec) {
    wider private;
  
    local select := rec.flag;
    const flagshape := shape(select);
    const ncorr := flagshape[1];
    const nchan := flagshape[2];
    const xshape := shape(rec.x);
    const xdim := len(xshape);
    const yshape := shape(rec.y);
    const ydim := len(yshape);

    if (abs(private.axis.X.offset) > 0) rec.x -:= private.axis.X.offset;
    if (abs(private.axis.Y.offset) > 0) rec.y -:= private.axis.Y.offset;
    # All channels and correlators are done
    if (ydim == 1) {
      if (xdim == 1) {
        for (frec in private.plot.select.records) {
          if (frec.valid) {
            local blc := frec.region.blc;
            local trc := frec.region.trc;
            local mask := (rec.x > blc[1]) & (rec.x < trc[1]) &
	                  (rec.y > blc[2]) & (rec.y < trc[2]);
            select[,,mask] := T;
          }
        }
      } else {
        for (frec in private.plot.select.records) {
          if (frec.valid) {
            local blc := frec.region.blc;
            local trc := frec.region.trc;
            local maskx := (rec.x > blc[1]) & (rec.x < trc[1]);
            local masky := (rec.y > blc[2]) & (rec.y < trc[2]);
            for (corr in 1:ncorr) {
              for (chan in 1:nchan) {
                local newmask := maskx[corr,chan,] & masky;
		select[corr,chan,][newmask] := T;
              }
            }
          }
        }
      }
    } else {
      if (xdim == 1) {
        for (frec in private.plot.select.records) {
          if (frec.valid) {
            local blc := frec.region.blc;
            local trc := frec.region.trc;
            local maskx := (rec.x > blc[1]) & (rec.x < trc[1]);
            local masky := (rec.y>blc[2])&(rec.y<trc[2]);
            for (corr in 1:ncorr) {
              for (chan in 1:nchan) {
                local newmask := maskx & masky[corr,chan,];
                select[corr,chan,][newmask]:=T;
              }
            }
          }
        }
      } else {
	if ((xdim != ydim) || any(xshape != yshape)) {
	  return throw('x and y axes not the same shape',
		       origin='msplot.listrec');
	}
        for (frec in private.plot.select.records) {
          if (frec.valid) {
            local blc := frec.region.blc;
            local trc := frec.region.trc;
            local maskx := ((rec.x>blc[1]) & (rec.x<trc[1]));
            local masky := ((rec.y>blc[2]) & (rec.y<trc[2]));
            for (corr in 1:ncorr) {
              for (chan in 1:nchan) {
                local newmask := maskx[corr,chan,] & masky[corr,chan,];
                select[corr,chan,][newmask] := T;
              }
            }
          }
        }
      }
    }
    const nvis := flagshape[3];
    select &:= !rec.flag;
    local listeddata := F;
    for (vis in 1:nvis) {
      if (any(select[,,vis])) {
	listeddata := T;
	local dd := rec.data_desc_id[vis];
	if (rec.antenna1[vis] == rec.antenna2[vis]) {
	  note('Antenna ', rec.antenna1[vis],
	       ' Field ', rec.field_id[vis],
	       ' Sp. Win. Id ', private.spwid[dd],
	       ' Pol. Id ', private.polid[dd],
	       ' Time ',  private.world.print.time(rec.time[vis]),
	       origin='msplot.listrec');
	} else {
	  note('Interferometer ', rec.antenna1[vis], '-',
	       rec.antenna2[vis], 
	       ' Field ', rec.field_id[vis],
	       ' Sp. Win. Id ', private.spwid[dd],
	       ' Pol. Id ', private.polid[dd],
	       ' Time ',  private.world.print.time(rec.time[vis]),
	       origin='msplot.listrec');
	}
      }
    }
    if (!listeddata) {
      note('No data in selected region', priority='WARN',
	   origin='msplot.listrec');
    }
    return T;
  }
#
# Specialized data plotter. Knows to iterate over correlator
# and channels
#
  private.plotxy := function(flag=F) {
    wider private;
  
    xaxis := private.axis.X;
    yaxis := private.axis.Y;
  
    private.lastplot := 'plotxy';
  
    private.plot.pgplotter.clear();
  
    private.plot.status->post(paste('********** Plot', yaxis.label, 
                                    'versus', xaxis.label, '**********'));
  
#
# Initialize the iteration
#
    if (is_fail(private.iterinit())) fail;

    rec := private.getvisdata(xaxis, yaxis);

    if (private.edit) {
      local datashape := private.datashape();
      local flagshape := shape(rec.flag);
      if (flagshape[1] < datashape[1]) {
        private.plot.mode.policy.correlations->state(F);
        private.plot.mode.policy.correlations->disabled(T);
      } else {
        private.plot.mode.policy.correlations->disabled(F);
      }
      if (flagshape[2] < datashape[2]) {
        private.plot.mode.policy.channels->state(F);
        private.plot.mode.policy.channels->disabled(T);
      } else {
        private.plot.mode.policy.channels->disabled(F);
      }
    }
    while (!is_fail(rec)) {
      if (has_field(rec, 'x') && has_field(rec, 'y')) {
        if (!private.plot.standardscaling(rec.x, rec.y,
                                          private.axis.X, private.axis.Y)) {
          private.stopnow();
          return T;
        }
#
# Do the various cases
#
        if (flag) {
          private.flagrec(rec);
        }
        private.plotrec(rec);
        if (private.edit && flag) {
          private.putvisflags(rec.flag, rec.flag_row);
        }
      }
      private.plot.pgplotter.sci(1);
      if (!private.iternext()) break;
      rec := private.getvisdata(xaxis, yaxis);
    }
    private.selectedms.iterend();
    if (private.thisplot.npages > 0) {
      return T;
    } else {
      return throw('No data plotted.', origin='msplot.plotxy');
    }
  }

  private.locatexy := function() {
  
    wider private;
  
    local xaxis := private.axis.X;
    local yaxis := private.axis.Y;
  
#
# Initialize the iteration
#
    if (is_fail(private.iterinit())) fail;
  
    local rec := private.getvisdata(xaxis, yaxis);
    while (!is_fail(rec)) {
      if (has_field(rec, 'x') && has_field(rec, 'y')) {
        private.listrec(rec);
      }
      if (!private.iternext()) break;
      rec := private.getvisdata(xaxis, yaxis);
    }
  }
#
# Specialized data plotter. Knows to iterate over correlator
# and channels
#
  private.plotuvslice := function(flag=F) {
  
    wider private;
  
    if (private.edit) private.plot.holderframe->map();
  
    xaxis := private.axis.X;
    yaxis := private.axis.Y;
          
    private.lastplot := 'plotuvslice';
  
    private.plot.pgplotter.clear();
    private.thisplot.npages := 0;
  
    private.plot.status->post(paste('**************** Plot', yaxis.label,
                                    'versus rotated U ***************'));
  
    if (is_fail(private.iterinit())) fail;
  
    rec := private.selectedms.getdata(['u', 'v', 'uvdist', 'flag', 'flag_row',
                                       'axis_info', yaxis.name]);
  
    if (len(rec[yaxis.name]::shape) != 3) {
      return throw(paste("Data has unexpected shape",
			 rec[yaxis.name]::shape), origin='msplot.plotuvslice');
    }
    minx := miny := maxx := maxy := F;
    private.getaxisranges(rec.uvdist, rec[yaxis.name], minx, maxx,
                          miny, maxy);
    minx := -maxx;
  
    private.data.ur := rec.u;
    private.plot.pgplotter.clear();
    private.thisplot.npages := 0;
    private.nslices := max(private.plot.holder.inc.get(), 1);
    if (private.nslices > 1) {
      note('Plotting slices for increments in angle = ', 180.0/private.nslices,
           ' degrees', origin);
    }
    for (slice in 1:private.nslices) {
      uvsliceangle := (slice-1)*pi/private.nslices+pi*private.angle/180.0;
    
      rec.x := rec.u*cos(uvsliceangle) + rec.v*sin(uvsliceangle);
      rec.y := rec[yaxis.name];
    
      xlabel := paste('Rotated U axis : angle = ', 180.0*uvsliceangle/pi,
                      'degrees');
      ylabel := private.axis.Y.label;
      colors := [1, 2, 7, 4];
      private.plot.pgplotter.sci(1);
      private.plot.pgplotter.env(minx, maxx, miny, maxy, 0, 0);
      private.thisplot.npages +:= 1;
      private.thisplot.ready := T;
      private.plot.standardlabel(xlabel, ylabel);
      if (flag) {
        private.flagrec(rec);
      }
      private.plotrec(rec);
    }
    if (private.edit && flag) {
      private.putvisflags(rec.flag, rec.flag_row);
    }
    private.plot.pgplotter.sci(1);
  
    private.setplotterpages();
    if (private.edit) private.plot.select.start();
  
    return T;
  }
#
# Specialized data plotter. Knows to iterate over correlator
# and channels
#
  private.plotlonglatslice := function(flag=F) {
  
    wider private;
  
    sot := 24.0*3600.0/(2.0*pi);

    if (private.edit) private.plot.holderframe->map();
  
    xaxis := private.axis.X;
    yaxis := private.axis.Y;
          
    private.lastplot := 'plotlonglatslice';
  
    private.plot.pgplotter.clear();
    private.thisplot.npages := 0;
  
    private.plot.status->post(paste('**************** Plot', yaxis.label,
                                    'versus rotated Longitude ***************'));
  
    if (is_fail(private.iterinit())) fail;
  
    orec := private.selectedms.getdata(['flag', 'flag_row', 'axis_info', yaxis.name]);
    rec := private.getlonglat(orec.time);
    rec.flag := orec.flag;
    rec.flag_row := orec.flag_row;
    include 'statistics.g';
    rec.direction.longitude -:= mean(rec.direction.longitude);
    rec.direction.latitude  -:= mean(rec.direction.latitude);
    rec[yaxis.name] := orec[yaxis.name];
    rec.axis_info := orec.axis_info;
    orec := F;
  
    if (len(rec[yaxis.name]::shape) != 3)
        return throw(paste("Data has unexpected shape", rec[yaxis.name]::shape));
  
    minx:=F; miny:=F; maxx:=F; maxy:=F;
    minx := -maxx;
  
    private.data.longituder:=rec.direction.longitude;
    private.getaxisranges(rec.direction.longitude, rec[yaxis.name], minx, maxx,
                          miny, maxy);
    private.plot.pgplotter.clear();
    private.thisplot.npages := 0;
    private.nslices := max(private.plot.holder.inc.get(), 1);
    if (private.nslices>1) {
      note('Plotting slices for increments in angle = ', 180.0/private.nslices,
           ' degrees');
    }
    for (slice in 1:private.nslices) {
      xysliceangle:=(slice-1)*pi/private.nslices+pi*private.angle/180.0;
    
      rec.x:=(rec.direction.longitude * cos(xysliceangle)+
              rec.direction.latitude  * sin(xysliceangle))*sot;
      rec.y:=rec[yaxis.name];
    
      xlabel := paste('Rotated Longitude axis : angle = ', 180.0*xysliceangle/pi,
                      'degrees');
      ylabel := private.axis.Y.label;
      colors := [1, 2, 7, 4];
      private.plot.pgplotter.sci(1);
      private.plot.pgplotter.env(minx*sot, maxx*sot, miny, maxy, 0, 0);
      private.thisplot.npages+:=1;
      private.thisplot.ready := T;
      private.plot.standardlabel(xlabel, ylabel);
      if (flag) {
        private.flagrec(rec);
      }
      private.plotrec(rec);
    }
    if (private.edit&&flag) {
      private.putvisflags(rec.flag, rec.flag_row);
    }
    private.plot.pgplotter.sci(1);
  
    private.setplotterpages();
    if (private.edit) private.plot.select.start();
  
    return T;
  }
  private.listvis := function() {
  
    wider private;
#
# Initialize the iteration
#
    if (is_fail(private.iterinit())) fail;
  
    private.getaxes();
  
    timerange := private.operations.Selection.button.time.selector.get();
    if (!is_unset(timerange)&&length(timerange) == 2) {
      private.ms.lister(timerange[1], timerange[2]);
    } else {
      private.ms.lister(private.data.packedtimes[1], 
                        private.data.packedtimes[len(private.data.packedtimes)]);
    }
  }

  private.displayvis := function(ref zaxis) {
    wider private;
    local tempdir := private.tempdir();
    if (is_fail(tempdir)) fail;
    include 'image.g';
    private.display.deleteimages();
    note('Displaying image of ', zaxis.label, origin='msplot.displayvis');
    private.display.imagename := [''];
    private.display.imagenameall := spaste(tempdir, '.msplot.image.all');
    private.data.packedtimes := [];
    private.display.dd := [];
    private.display.ff := [];
    private.display.times := [];
    local startrow := [1.0];
    local previousshape := F;
    local index := 0;
    local scratchimage := F;
    local ok := private.iterinit(F, F);
    if (is_fail(ok)) fail;
    local dochunk := T;
    while (dochunk) {
      index +:= 1;
      local rec := private.getifrdata(zaxis);
      local nslots := length(rec.data_desc_id);
      local packedtimes := array('', nslots);
      for (i in 1:nslots) {
        packedtimes[i] :=
          private.world.print.time(rec.axis_info.time_axis.MJDseconds[i]);
      }
      private.data.packedtimes := [private.data.packedtimes, packedtimes];
      private.display.times := [private.display.times,
                                rec.axis_info.time_axis.MJDseconds];
      private.display.dd := [private.display.dd, rec.data_desc_id];
      private.display.ff := [private.display.ff, rec.field_id];
      if (index == 1) {
        private.display.ifr_number := rec.axis_info.ifr_axis.ifr_number;
        private.display.corr_axis := rec.axis_info.corr_axis;
        local chans := private.getchannel();
        private.display.channels := chans.start +chans.inc*(0:(chans.nchan-1));
      }
      if (index > 1) {
        startrow +:= previousshape[4];
      }
      previousshape := rec.z::shape;
      local cs := private.display.makecoordsys(rec.axis_info, startrow);
      private.display.imagename[index] := 
        spaste(tempdir, '.msplot.image.', as_string(index));
#      tabledelete(private.display.imagename[index]);
      scratchimage := 
        imagefromarray(private.display.imagename[index],
                       pixels=as_float(rec.z), csys=cs);
      if (!private.getvalue.flag_row()) {
        scratchimage.putregion(pixelmask=!rec.flag);
      }
      cs.done();
      if (is_fail(scratchimage)) {
        return throw('Failed to construct scratch image. Error was:\n',
                     scratchimage::message, origin='msplot.displayvis');
      }
      dochunk := private.iternext();
      scratchimage.done();
      rec := F;
    }
#
# Now concatenate all the scratch images
#
    if (index > 1) {
      # relax=T is needed in order to plot different spw's side by side.
      scratchimage := imageconcat(private.display.imagenameall,
                                  private.display.imagename[1:index],
                                  axis=4, relax=T);
    } else {
      scratchimage := imagefromimage(private.display.imagenameall,
                                     private.display.imagename[1]);
    }
    if (is_fail(scratchimage)) {
      return throw('Failed to construct scratch image. Error was:\n',
                   scratchimage::message, origin='msplot.displayvis');
    }

    local imagecoords := scratchimage.coordsys();
# The following are needed later
    local coordnames := imagecoords.names();
    local imageshape := scratchimage.shape();
    imagecoords.done();
    scratchimage.done();
#    private.thisplot.axis.Z.values := [];

    note('Data have time range from ', private.data.packedtimes[1], ' to ',
         private.data.packedtimes[len(private.data.packedtimes)],
         origin='msplot.displayvis');
#
# Now make the display panel and attach motion callbacks
#
    private.viewerdpwe := [];
#
# Now hold the viewer so that we can add the displaydatas
#
    private.viewer.hold();
    private.viewerdd := private.viewer.loaddata(private.display.imagenameall,
                                                drawtype = 'raster');
    if (is_fail(private.viewerdd)) {
      private.viewer.release();
      return throw('Failed to construct displaydata. Error was:\n',
                   private.viewerdd::message, origin='msplot.displayvis');
    }
  
#    private.axis.Y := private.axes.packed_ifr_number;      
#    private.axis.X := private.axes.packed_row;

# 
# Now set the options for display
#

# If there are no options from the previous session.
    if (!has_field(private.display, 'ddoptions') || 
        length(private.display.ddoptions) == 0) {
      private.display.ddoptions := private.viewerdd.getoptions();
# Modify them for this particular image
      private.display.ddoptions.titletext.value := private.display.title();
      private.display.ddoptions.axislabelswitch.value := T;
      private.display.ddoptions.pixeltreatment.value := 'edge';
      private.display.ddoptions.aspect.value := 'flexible';
      private.display.ddoptions.axislabelspectralunit.value := 'GHz';
      private.display.ddoptions.spectralunit.value := 'GHz';
# Special cases. 
# 1. If nchan is one and Correlation is non-zero put correlation on
# the third axis. 
      if (private.datatype == 'sd') {
        private.display.ddoptions.xaxis.value := coordnames[4];
        private.display.ddoptions.yaxis.value := coordnames[2];
        private.display.ddoptions.zaxis.value := coordnames[1];
        private.display.ddoptions.haxis1.listname := coordnames[3];
      } else { # synthesis data
        if ((imageshape[2] == 1) && (imageshape[1] > 1)) { # Only one channel
          private.display.ddoptions.xaxis.value := coordnames[4];
          private.display.ddoptions.yaxis.value := coordnames[3];
          private.display.ddoptions.zaxis.value := coordnames[1];
          private.display.ddoptions.haxis1.listname := coordnames[2];
        } else { # Spectral line
          private.display.ddoptions.xaxis.value := coordnames[4];
          private.display.ddoptions.yaxis.value := coordnames[3];
          private.display.ddoptions.zaxis.value := coordnames[2];
          private.display.ddoptions.haxis1.listname := coordnames[1];
        }
      }
      include 'inputsmanager.g';
      label :=  private.inputsname.get();
      inputs.savevalues('msplot', 'display', private.display.ddoptions,
                        label, dosave=T);
    }
    private.viewerdd.setoptions(private.display.ddoptions);
    private.display.axisnames :=
      [private.display.ddoptions.xaxis.value,
       private.display.ddoptions.yaxis.value,
       private.display.ddoptions.zaxis.value,
       private.display.ddoptions.haxis1.listname];
    private.display.logaxes();
#
# Now register the displaydata
#
    private.viewerdp.register(private.viewerdd);
    private.viewerdp.animator().goto(as_integer(imageshape[2]/2));
#
# setup the whenevers
#
# 1. animator emits a state event whenever a new plane is displayed.
# NOT NEEDED
#    whenever private.viewerdp.animator()->state do {
#      note ('Animator emitted a state event.\nValue was: ', $value,
#           priority='WARN');
#       private.display.zcoord($value.value);
#    } private.pushwhenever('viewer');
# # private.viewerdpwe[length(private.viewerdpwe)+1] :=
# #     last_whenever_executed();

# 2. display data emits a motion event whenever the cursor is moved
# inside the displayed image.
    whenever private.viewerdd->motion do {
#      note ('Display data emitted a motion event.\nValue was: ', $value,
#           priority='WARN');
      # Need to lock out this motion callback when active otherwise
      # the events become jumbled
#      if (!private.display.busy && !private.worldcbactive) {
#       private.worldcbactive := T;
      private.display.worldcoords($value);
#       private.worldcbactive := F;
#      }
#      private.display.zcoord(private.viewerdp.animator().currentframe());
    } private.pushwhenever('viewer');

# 3. display panel emits a pseudoregionready event whenever a box or
# polygon region is 'emitted', or a pseudoposition whenever the cursor
# position is 'emitted'. This is used when editing.
    if (private.edit) {
      whenever private.viewerdp -> pseudoregion do {
          private.display.callbacks.All($value);
        } private.pushwhenever('viewer');
      whenever private.viewerdp -> pseudoposition do {
          # (respond to crosshair only on button release)
          if($value.evtype=='up') private.display.callbacks.All($value);
        } private.pushwhenever('viewer');
    }

# 4. display data emits an options event whenever an option is changed
# in the adjust gui. This is needed in edit mode to keep track of what
# axes are being displayed, and hence make the conversion to from
# regions to flagging commands It is needed in both modes that that
# the display data options get saved to the inputs table.
    whenever private.viewerdd -> options do {
      wider private;
      local ddoptions := $value;
      local changed := F;
      local i := 1;
      for (a in "xaxis yaxis zaxis haxis1") {
        if (has_field(ddoptions, a) && 
            private.display.axisnames[i] != as_string(ddoptions[a].value)) {
          changed := T;
          if (a != 'haxis1') {
            private.display.axisnames[i] := ddoptions[a].value;
          } else {
            private.display.axisnames[i] := ddoptions[a].listname;
          }
        }
        i +:= 1;
      }
      if (changed) private.display.logaxes();
      for (f in field_names(ddoptions)) {
        private.display.ddoptions[f] := ddoptions[f];
      }
      label :=  private.inputsname.get();
      inputs.savevalues('msplot', 'display', private.display.ddoptions,
                        label, dosave=T);
    } private.pushwhenever('viewer');
#
# And release the display
#
    private.viewer.release();
    return T;
  }

  private.display.logaxes := function() {
    note('New display axes are:\n\t',
         private.display.axisnames[1], ' (x)\t',
         private.display.axisnames[2], ' (y)\n\t', 
         private.display.axisnames[3], ' (z/animation)\t', 
         private.display.axisnames[4], ' (hidden).', origin='msplot');
  }
#
# Start up the GUI
#

  public.gui := function() {
    wider private;
    private.gui();
    return T;
  }
  
  public.open := function(whichms, edit=F, flagfile=unset) {
    wider private;
    if (private.lock('top')) {
      ok := private.open(whichms, edit, flagfile);
      private.unlock();
      if (is_fail(ok)) {
        return throw('Problem opening the measurement set. The error was:\n',
                     ok::message, origin='msplot.open');
      }
    }
  }

  public.dismiss := function() {
    wider private;
    if (is_agent(private.frames.top)) {
      note('Hiding the msplot windows. Bring them back with the gui function.',
           origin='msplot.dismiss');
      private.frames.top->unmap();
    }
  }

  public.done := function() {
    wider private, public;
    
    private.deactivatewhenever();
    if (has_field(private, 'ms') && is_ms(private.ms)) {
      result := private.close();
    }

    private.donegui();
    private.donetools();
    val private := F;
    val public := F;
    return T;
  }

  public.type := function() {
    return 'msplot';
  }
#
# Now open any ms 
#
  public.gui();

  if (!is_unset(msfile)) {
    ok := public.open(msfile, edit, flagfile);
    if (is_fail(ok)) {
      public.done();
      fail;
    }
  }
  
  public.debug := function() {return ref private};

  private.selectaction();
  return ref public;
}

#
# Copy the flags from a flag table back to the measurement set
#
msplotapplyflags := function(flagfile, msfile=unset, merge=F) {
  include 'table.g';
  include 'note.g';
  local flagtable := table(flagfile, readonly=T, ack=F);
  if (!is_table(flagtable)) {
    return throw('Cannot open the table called ', flagfile, 
                 origin='msplotapplyflags');
  }

  if (all(flagtable.keywordnames() != 'Measurement Set') ||
      all(flagtable.colnames() != 'FLAG') ||
      all(flagtable.colnames() != 'FLAG_ROW')) {
    flagtable.done();
    return throw('The table called ', flagfile, 
                 ' does not appear to be a flag table.',
                 origin='msplotapplyflags');
  }

  if (is_unset(msfile)) {
    msfile := flagtable.getkeyword('Measurement Set');
  } else {
    include 'os.g';
    if (dos.basename(msfile) != 
        dos.basename(flagtable.getkeyword('Measurement Set'))) {
      local doit := 
        choice(spaste('The measurement set that generated the flag table\n',
                      'has a different name from the measurement set\n',
                      'you are applying the flag table to. This will\n',
                      'cause problems if the data shapes are different.\n',
                      'Do you want to proceed?'),
               "no yes");
      if (doit == 'no') {
        flagtable.done();
        return F;
      }
    }
  }
  
  if (!tableexists(msfile)) {
    flagtable.done();
    return throw('Original measurement set does not exist',
                 origin='msplotapplyflags');
  }
  
  mstable := table(msfile, readonly=F, ack=F);
  if (!is_table(mstable)) {
    flagtable.done();
    return throw ('Cannot open the measurement set called ', msfile,
                  origin='msplotapplyflags');
  }

  if (flagtable.nrows() != mstable.nrows()) {
    flagtable.done();
    mstable.done();
    return throw('Flag column table and ms have different number of rows',
                 origin='msplotapplyflags');
  }

  cols := "FLAG FLAG_ROW";
  if (merge) {
    note('Merging the flags from the flag table called ', flagfile,
         ' with the flags in the measurement set called ', msfile,
         origin='msplotapplyflags');
  } else {
    note('Replacing the flags in the measurement set called ', msfile,
         ' with the flags in the flag table called ', flagfile,
         origin='msplotapplyflags');
  }

  local cols := "FLAG FLAG_ROW";
  local totalrows := mstable.nrows();
  local stepsize := 16384;
  local tabledesc := mstable.getdesc();
  for (col in cols) {
    for (startrow in seq(1, totalrows, stepsize)) {
      local sr := startrow;
      local nrows := stepsize;
      if (startrow + nrows > totalrows) {
        nrows := totalrows - startrow + 1;
      }
      local coldesc := tabledesc[col];
      if (has_field(coldesc, 'ndim') && is_integer(coldesc.ndim) &&
          (coldesc.ndim > 0)) {
        local flagshapes :=
          flagtable.getcolshapestring(col, startrow, nrows);
        if (any(flagshapes != 
                mstable.getcolshapestring(col, startrow, nrows))) {
          mstable.done();
          flagtable.done();
          return throw('Cannot copy all the flags as shapes are different\n',
                       'between the flag table and the measurement set.\n',
                       'Aborting the operation at row ', startrow,
                       origin='msplotapplyflags');
        }
        if (any(flagshapes != flagshapes[1])) { 
          for (r in 1:(nrows-1)) {
            if (flagshapes[r] != flagshapes[r+1]) {
              local rowstocopy := r-sr+1;
              local flags := flagtable.getcol(col, sr, rowstocopy);
              if (merge) {
                flags |:= mstable.getcol(col, sr, rowstocopy);
              }
              mstable.putcol(col, flags, sr, rowstocopy);
              sr := r+1;
              nrows -:= rowstocopy;
            }
          }
        }
      }
      local flags := flagtable.getcol(col, sr, nrows);
      if (merge) {
        flags |:= mstable.getcol(col, sr, nrows);
      }
      mstable.putcol(col, flags, sr, nrows);
    }
  }
  mstable.done();
  flagtable.done();
  return T;
}
