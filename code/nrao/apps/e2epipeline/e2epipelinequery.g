# e2epipelinequery: Queries for pipeline processing
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: e2epipelinequery.g,v 19.0 2003/07/16 03:44:48 aips2adm Exp $
#

pragma include once;

e2epipelinequery := function(catalogname='SUMCATALOG') {

  public := [=];
  private := [=];

  private.tables := [=];
  include 'table.g';

  private.st := F;
#
# COnvert times from possible formats
#
  private.converttime := function(t) {
    wider private, public;
    include 'quanta.g';
    if(is_quantity(t)) {
      result := dq.convert(t, 'd');
      return result.value;
    }
    else if(is_string(t)) {
      result := dq.totime(t);
      if(is_quantity(result)) {
	return result.value;
      }
      return t;
    }
    else {
      return t;
    }
  }
#
# Find the right catalog to open and open it
#    
  private.gettelescopename := function(project) {
    wider private;
    
    if(project ~ m/^A/) {
      return telescope := 'VLA';
    }
    else if(project ~ m/^B/) {
      return telescope := 'VLBA';
    }
    else if(project ~ m/^C/) {
      return telescope := 'GBT';
    }
    return 'NRAO';
  }
  private.getcatalog := function(project=unset, telescopename=unset) { 
    wider private;
    
    if(!is_unset(project)) {
      if(is_unset(telescopename)) {
	telescopename := private.gettelescopename(project);
	if(is_fail(telescopename)) return telescopename;
      }
    }
#
    catalogplace := 'NRAO';
    if((is_unset(telescopename))||(telescopename=='VLA')||(telescopename=='VLBA')||
       (telescopename=='GBT')) {
      catalogplace := 'NRAO';
    }
    private.catalog    := spaste('/users/e2emgr/e2e/archive/catalogs/', catalogplace, '/',
				 catalogname) ~ s!//!/!g;
    if(has_field(environ, 'E2EROOT')) {
      private.catalog    := spaste(environ.E2EROOT, '/archive/catalogs/', catalogplace, '/',
				   catalogname) ~ s!//!/!g;
    }

    private.data    := spaste('/users/e2emgr/e2e/archive/data/', telescopename) ~ s!//!/!g;
    if(has_field(environ, 'E2EROOT')) {
      private.data    := spaste(environ.E2EROOT, '/archive/data/', telescopename) ~ s!//!/!g;
    }

    for (subtable in "main antenna archive datadesc observation subarray") {
      if(has_field(private.tables, subtable)&&is_table(private.tables[subtable])) {
	private.tables[subtable].done();
      }
      if(subtable=="main") {
	private.tables[subtable] := table(private.catalog, ack=F);
      }
      else {
	private.tables[subtable] := table(spaste(private.catalog, '/', to_upper(subtable)), ack=F);
      }
      if(!is_table(private.tables[subtable])) {
	return throw('No catalog information for telescope ', telescopename);
      }
    }
  }
  private.getprojectsubtable := function(project, tbeg=unset, tend=unset, subtable='archive') {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    query := spaste('(PROJECT_CODE==\'', project, '\')');
    if(any(private.tables[subtable].colnames()=='STARTTIME')) {
      if(!is_unset(tbeg)) {
	query := spaste(query, ' && (STARTTIME >= ', tbeg, ')');
      }
      if(!is_unset(tend)) {
	query := spaste(query, ' && (STOPTIME <= ', tend, ')');
      }
    }
    st := private.tables[subtable].query(query);
    if(!is_table(st)||(st.nrows()==0)) {
      return throw('No valid data found project ', project, ' for specified time range');
    }
    return st;
  }
#
# Common requests
#
  public.getcontext := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    if(is_fail(private.getcatalog(project, telescopename))) fail;
    st := private.getprojectsubtable(project, tbeg, tend, 'datadesc');
    if(is_fail(st)) fail;
#
# Rule is good for VLA
#
    nchan := st.getcol('SUB_NUM_CHANS');
    if(is_fail(nchan)) nchan:=1;
    if(telescopename=='VLA') {
      if(max(nchan)>8) {
	return "spectralline";
      }
      else {
	return "continuum";
      }
    }
    else {
      return "continuum";
    }
  }
  public.getarchfiles := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    if(is_fail(private.getcatalog(project, telescopename))) fail;
    st := private.getprojectsubtable(project, tbeg, tend);
    if(is_fail(st)) fail;
#
# This part is telescope specific
#
    if(telescopename=='VLA') {
      archfiles := unique(st.getcol('ARCH_FILE'));
      for (i in 1:len(archfiles)) {
	archfiles[i] := spaste(private.data, '/tapes/', archfiles[i]);
	if(!(archfiles[i] ~ m/file_/ )) archfiles[i] :=  archfiles[i] ~ s!_!/file_!g;
	archfiles[i] := archfiles[i] ~ s!//!/!g;
      }
      return archfiles;
    }
    else {
      return unique(st.getcol('ARCH_FILE'));
    }
  }
  public.getallarchfiles := function(telescopename) {
    wider private, public;

    if(is_fail(private.getcatalog(telescopename))) fail;

    st := private.tables['archive'];
#
# This part is telescope specific
#
    archfiles := unique(st.getcol('ARCH_FILE'));
      for (i in 1:len(archfiles)) {
	if(!(archfiles[i] ~ m/file_/ )) archfiles[i] :=  archfiles[i] ~ s!_!/file_!g;
	archfiles[i] := archfiles[i] ~ s!//!/!g;
      }
    }
    else {
      return unique(st.getcol('ARCH_FILE'));
    }
  }
  public.getcatalogname := function(telescopename=unset) {
    wider private, public;
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    if(is_fail(private.getcatalog(telescopename=telescopename))) fail;
    return private.catalog;
  }
  public.getprojects := function(telescopename=unset) {
    wider private, public;
    if(is_fail(private.getcatalog(telescopename=telescopename))) fail;
    return unique(private.tables['main'].getcol('PROJECT_CODE'));
  }
  public.getobserver := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    if(is_fail(private.getcatalog(project, telescopename))) fail;
    st := private.getprojectsubtable(project, tbeg=tbeg, tend=tend, subtable='main');
    if(is_fail(st)) fail;
    return unique(st.getcol('OBSERVER'))
  }

  public.gettimes := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    if(is_fail(private.getcatalog(project, telescopename))) fail;
    st := private.getprojectsubtable(project, tbeg=tbeg, tend=tend, subtable='main');
    if(is_fail(st)) fail;
    return [first=st.getcol('FIRSTTIME'), last=st.getcol('LASTTIME'), proprietary=st.getcol('PROPRIETARY')]
  }

  public.getbands := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    if(is_fail(private.getcatalog(project, telescopename))) fail;
    st := private.getprojectsubtable(project, tbeg=tbeg, tend=tend, subtable='main');
    if(is_fail(st)) fail;
    return st.getcol('OBS_BANDS');
  }

  public.getepochs := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    if(is_fail(private.getcatalog(project, telescopename))) fail;
    st := private.getprojectsubtable(project, tbeg=tbeg, tend=tend);
    if(is_fail(st)) fail;
    return [start=st.getcol('STARTTIME'), stop=st.getcol('STOPTIME')]
  }

  public.browse := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    if(is_table(private.st)) private.st.done();
    if(is_fail(private.getcatalog(project, telescopename))) fail;
    st := private.getprojectsubtable(project, tbeg, tend);
    if(is_fail(st)) fail;
    private.st := st;
    return private.st.browse();
  }

  public.gettelescope := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    if(is_fail(private.getcatalog(project, telescopename))) fail;
    st := private.getprojectsubtable(project, tbeg, tend);
    if(is_fail(st)) fail;
    return [telescope=st.getcol('TELESCOPE'), config=st.getcol('TELESCOPE_CONFIG')]
  }

  public.getfrequency := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    if(is_fail(private.getcatalog(project, telescopename))) fail;
    st := private.getprojectsubtable(project, tbeg, tend, 'datadesc');
    if(is_fail(st)) fail;
    f := unique(st.getcol('IF_REF_FREQ'));
    freq := '';
    for (i in 1:length(f)) {
      freq[i] := spaste(f[i]/1e9, 'GHz');
    }
    return freq;
  }
#
# Get all the sources for a catalog
#
  public.getsources := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider private, public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    st := private.getprojectsubtable(project, tbeg, tend, 'observation');
    if(is_fail(st)) fail;
    allsources := st.getcol('SOURCE_ID');
    caltype := st.getcol('CALIB_TYPE') ~ s/  //g;
    result := [=];
    mask := caltype=='';
    result.calsources := unique(allsources[!mask]);
    result.sources    := unique(allsources[mask]);
    possibles := "1331+305 1328+307 3C286 3C48 0134+329 0137+331 3C147 0538+498 0542+498 3C138 0518+165 0521+166 1934-638 3C295 1409_524 1411+522";
    result.allsources := unique(allsources);
    result.targetsources := '';
    i := 0;
    for (source in result.allsources) {
      if(!any(result.calsources==source)) {
	i+:=1;
	result.targetsources[i] := source;
      }
    }
    result.fluxsource := '';
    i := 0;
    for (fluxsource in possibles) {
      if(any(result.calsources==fluxsource)) {
	i+:=1;
	result.fluxsource[i] := fluxsource;
      }
    }
    return result;
  }


  public.summary := function(project, telescopename=unset, tbeg=unset, tend=unset) {
    wider public;
    tbeg := private.converttime(tbeg);
    tend := private.converttime(tend);
    if(is_unset(telescopename)) telescopename := private.gettelescopename(project);
    note('Project = ', project);
    note('   Type          ', public.getcontext(project, telescopename, tbeg=tbeg, tend=tend));
    note('   Observer      ', public.getobserver(project, telescopename, tbeg=tbeg, tend=tend));
    note('   Archive files ', public.getrachfiles(project, telescopename, tbeg=tbeg, tend=tend));
    note('   Source        ', public.getsources(project, telescopename, tbeg=tbeg, tend=tend));
    note('   Telescope     ', public.gettelescope(project, telescopename, tbeg=tbeg, tend=tend));
    note('   Frequency     ', public.getfrequency(project, telescopename, tbeg=tbeg, tend=tend));
    note('   Bands         ', public.getbands(project, telescopename, tbeg=tbeg, tend=tend));
    note('   Times         ', public.gettimes(project, telescopename, tbeg=tbeg, tend=tend));
    note('   Epochs        ', public.getepochs(project, telescopename, tbeg=tbeg, tend=tend));
    return T;
  }

  public.type := function() {
    return "e2epipelinequery";
  }

  public.done := function() {
    wider private, public;
    for (subtable in "main antenna archive datadesc observation subarray") {
      private.tables[subtable].done();
    }
  }
  return public;
}


e2epipelinequerytest := function(project='AB973', telescopename='VLA') {
  mypq := e2epipelinequery();
  note('Name of ', telescopename, ' catalog               = ', mypq.getcatalogname(telescopename=telescopename));
  note('Number of projects in ' , telescopename,' catalog = ', length(mypq.getprojects(telescopename=telescopename)));
  mypq.summary(project, telescopename);
  return T;
}
