# sditerator.g: Manipulate sditerators
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
# $Id: sditerator.g,v 19.1 2004/08/25 01:51:03 cvsmgr Exp $

pragma include once;

# sdit := sditerator(filename, readonly = T, selection = [=], lockoptions='auto')
#   sdit2 := sdit.select(selection = [=]) # new from this with selection
#   sdit.resync()       # resync with disk copy
#   sdit.flush()       # flush to disk - a no-op for read-only sditerators
#   sdit.reselect()     # apply the original selection again
#   sdit.deepcopy(newname)     # make a copy of the table and all subtables
#   sdit.unlock()       # unlock any tables associated with this
#   sdit.lock(nattempts)# lock any tables, trying nattempts on each one
#   sdit.origin()	# set iterator to origin
#   more := sdit.more() # any records after current (return = Bool)
#   sdit.next()		# step iterator to next record, if at end, do nothin
#   sdit.previous()	# step iterator to previous record, if at end do nothing.
#   sdit.setlocation(loc) # set iterator to record = loc
#   sdit.location()	# return current record number
#   sdit.length()	# returns total number of records
#   sdit.iswritable()	# returns True if SDRecords can be stored here
#   rec := sdit.get()	# return the current SDRecord
#   ok := sdit.getempty(rec, nchan, nstokes) # get an empty SDRecord (rec) having nchan, nstokes shape
#   ok := sdit.put(rec) # save rec at the current location, False if an error
#   ok := sdit.appendrec(rec) # save rec at the end of the iterator, False if an error
#   ok := sdit.deleterec() # delete rec at current location, False if an error
#   head := sdit.getheader() # return header of current record
#   nshead := sdit.getother() # return other of current record
#   data := sdit.getdata() # returns current data record
#   desc := sdit.getdesc() # returns current desc record
#   rvec := sdit.getvectors(template) # fill rvecs with all values from the 
#					current iterator for fields found in template
#   hist := sdit.history(newHistory) # returns the current history vector 
#   sdit.appendHistory(newHistory) # appends newHistory (may be a vector) to history vector
#   myname := sdit.name()	# returns the name of this iterator
#   mytype := sdit.type()	# returns the type of this iterator (MeasurementSet, Table, or Image)
#   srec := sdit.stringfields() # returns a record containing just the scalar string fields
#                               # used in this iterator.  Used during selection parsing.
#   ok := sdit.done() # closes this iterator


# first, set up the DO server
include "servers.g";
include "note.g";
include "catalog.g";

# the range parsing stuff is here
include "dish_util.g";

# there is a problem using [=] as an argument, use this to signal an
# empty record

__emptyRecord := [empty=T];

# users aren't to use this.
# The basic sditerator client functionality
# The fully in-memory sditerator doesn't use this, although it needs
# to define the same functions, so make sure that public functions added here
# are also added there.

const _define_sditerator := function(ref agent, id)
{
    private := [=];
    public := [=];

    private.agent := ref agent;
    private.id := id;

    private.hist := F;

     # I'm begining to think that the caller is responsible for keeping the 
    # history up to date and accurate
    # I'm not sure this is a good thing that this is public, but in
    # order for the main constructor to set this appropriately, it seems
    # to need to be public
    public.sel2string := function(selrec) {
	wider public;
	if (!is_record(selrec)) return as_string(selrec);


	res := '[';
	count := 0;
	for (name in field_names(selrec)) {
	    if (count > 0) res := spaste(res,',');
	    res := spaste(res,name,'=');
	    if (is_record(selrec[name])) {
		res := spaste(res,public.sel2string(selrec[name]));
	    } else {
		v := selrec[name];
		v::shape := F;
		if (is_string(v)) {
		    res := spaste(res,'\"',v,'\"');
		} else {
		    if (len(v) == 1) {
			res := spaste(res,v);
		    } else {
			res := spaste(res,paste(split(v),sep=','));
		    }
		}
	    }
	    count +:= 1;
	}
	return spaste(res,']');
    }

    private.sdut := sdutil();
    # the recursive part of the selection parsing
    private.parseSelRec := function(selrec, sfields) {
	wider private;
	result := [=];
	for (field in field_names(selrec)) {
	    if (is_record(selrec[field])) {
		# recursive, using sfield subrecord if available
		rec := [=];
		if (has_field(sfields,field) && is_record(sfields[field])) {
		    rec := sfields[field];
		}
		result[field] := private.parseSelRec(selrec[field],rec);
	    } else {
		if (is_string(selrec[field])) {
		    # if this field exists in sfields, it is a string field
		    if (has_field(sfields, field) && is_boolean(sfields[field])) {
			# parse it as if it were a string field
			# I don't believe that processing such a field twice is a problem
			result[field] := private.sdut.parsestringlist(selrec[field]);
		    } else {
			# parse it as if this is a numeric range
			result[field] := private.sdut.parseranges(selrec[field]);
		    }
		} else {
		    # don't do anything here with non-string selrec fields
		    result[field] := selrec[field];
		}
	    }
	}
	return result;
    }

    # the top level of the selection parsing
    private.parseselection := function(selrec) {
	wider private;
	wider public;
	# ignore the empty record
	if (all(field_names(selrec) == "empty") && selrec.empty==T) return;
	sfields := public.stringfields();
	return private.parseSelRec(selrec, sfields);
    }

    private.as_double := function(arecord) {
	wider private;
	result := [=];
	for (field in field_names(arecord)) {
	    if (is_record(arecord[field])) {
		result[field] := private.as_double(arecord[field]);
	    } else {
		if (is_integer(arecord[field]) || is_float(arecord[field])) {
		    result[field] := as_double(arecord[field]);
		} else {
		    result[field] := arecord[field];
		}
	    }
	}
	return result;
    }

    # the point here is that its simpler to change the type of a field in
    # the sdrecord here than it is in C++ if necessary.
    # the trick, though is that any changed to the SDRecord expected types
    # need to be reflected here.  These are the field which currently matter.
    # Try and reduce these.  The most difficult ones to eliminate are the
    # array types.  Don't bother with string types, if they are not a
    # string already, its a serious problem.
    private.sdtypes := [=];
    private.sdtypes.data.float := "arr weight sigma";
    private.sdtypes.data.bool := "flag";
    private.sdtypes.header.int := "scan_number";
    private.sdtypes.header.float := "tcal trx tsys";
    private.sdtypes.header.double := "exposure duration";
    private.sdtypes.other.sdfits := [=];
    private.sdtypes.other.sdfits.float := "subscan";
    # these are fields which should have a shape attribute.  That is only
    # important if the field being saved has only one elements (most likely
    # for the fields in header when there is only one polarization present).
    # if the sdshapes is "vector" then there is one axis and if the sdshapes
    # is matrix then there should be two axes.
    private.sdshapes := [=];
    private.sdshapes.data := [=];
    private.sdshapes.data.matrix := "arr flag weight sigma";
    private.sdshapes.data.desc := [=];
    private.sdshapes.data.desc.vector := "corr_type";
    private.sdshapes.header := [=];
    private.sdshapes.header.vector := "tcal trx tsys";
    # helper function
    private.coerceToType := function(ref arecord, fields, checker, coercer) {
	for (field in fields) {
	    if (has_field(arecord,field) && !checker(arecord[field])) {
		arecord[field] := coercer(arecord[field]);
	    }
	}
    }
    # the one to do it with
    private.coercetypes := function(ref arecord, types=private.sdtypes) {
	wider private;
	for (type in field_names(types)) {
	    if (has_field(arecord, type) && is_record(arecord[type]) && is_record(types[type])) {
		# decend down a level
		private.coercetypes(arecord[type], types[type]);
	    } else {
		coercer := F;
		checker := F;
		if (type == "double") {
		    coercer := as_double;
		    checker := is_double;
		} else {
		    if (type == "float") {
			coercer := as_float;
			checker := is_float;
		    } else { 
			if (type == "int") {
			    coercer := as_integer;
			    checker := is_integer;
			} else {
			    if (type == "bool") {
				coercer := as_boolean;
				checker := is_boolean;
			    }
			}
		    }
		}
		if (is_function(checker) && is_function(coercer)) {
		    private.coerceToType(arecord, types[type], checker, coercer);
		}
	    }
	}
    }

    private.setshapes := function(ref arecord, fields, ashape) {
	for (field in fields) {
	    if (has_field(arecord,field) &&
		len(arecord[field]) == 1 && !has_field(arecord[field]::,"shape")) {
		# this field is missing an expected shape attribute and it has 1 element
		arecord[field]::shape := ashape;
	    }
	}
    }

    private.coerceshapes := function(ref arecord, shapes=private.sdshapes) {
	wider private;
	for (ashape in field_names(shapes)) {
	    if (has_field(arecord, ashape) && 
		is_record(arecord[ashape]) && is_record(shapes[ashape])) {
		# decend down a level
		private.coerceshapes(arecord[ashape], shapes[ashape]);
	    } else {
		if (ashape == "vector") {
		    private.setshapes(arecord, shapes[ashape], [1]);
		} else {
		    # it must be a matrix
		    private.setshapes(arecord, shapes[ashape], [1,1]);
		}
	    }
	}
	# this is a kludge - the hist record has a shape, which
	# apparently it is easy to get wrong
	if (has_field(arecord,'hist') &&
	    is_string(arecord.hist)) arecord.hist::shape := len(arecord.hist);
    }

    private.selectRec := [_method="select", _sequence=private.id._sequence];
    public.select := function(selection = __emptyRecord) {
        wider private;
	wider public;
	# first, parse the selection
	selection := private.parseselection(selection);
	if (is_fail(selection)) fail;

	# and make sure its all doubles where appropriate
        private.selectRec["selection"] := private.as_double(selection);
	# now actually try and do the selection
        retval := defaultservers.run(private.agent, private.selectRec);
	if (is_fail(retval)) fail 'Selection failed';
        # retval is an object ID, make an object
        id := private.id; # host etc will all be the same
	id._sequence := retval.sequence;
	id.objectid := retval;
       
        newIt := ref _define_sditerator(private.agent, id);
	newIt.appendHistory(public.history());
	ssel := public.sel2string(selection);
	newIt.appendHistory(spaste('select(',ssel,')'));
	return ref newIt;
    }

    private.resyncRec := [_method="resync", _sequence=private.id._sequence];
    public.resync := function() {
	wider private;
	defaultservers.run(private.agent, private.resyncRec);
    }

    private.flushRec := [_method="flush", _sequence=private.id._sequence];
    public.flush := function() {
	wider private;
	defaultservers.run(private.agent, private.flushRec);
    }

    private.reselectRec := [_method="reselect", _sequence=private.id._sequence];
    public.reselect := function() {
	wider private;
	defaultservers.run(private.agent, private.reselectRec);
    }

    private.deepcopyRec := [_method="deepcopy", _sequence=private.id._sequence];
    public.deepcopy := function(newname) {
	wider private;
	private.deepcopyRec["newname"] := newname;
	defaultservers.run(private.agent, private.deepcopyRec);
    }

    private.unlockRec := [_method="unlock", _sequence=private.id._sequence]
    public.unlock := function() {
	wider private;
	return defaultservers.run(private.agent, private.unlockRec);
    }

    private.lockRec := [_method="lock", _sequence=private.id._sequence]
    public.lock := function(nattempts) {
	wider private;
	private.lockRec["nattempts"] := nattempts
	return defaultservers.run(private.agent, private.lockRec);
    }

    private.originRec := [_method="origin", _sequence=private.id._sequence]
    public.origin := function() {
	wider private;
	defaultservers.run(private.agent, private.originRec);
    }

    private.moreRec := [_method="more", _sequence=private.id._sequence]
    public.more := function() {
	wider private;
	return defaultservers.run(private.agent, private.moreRec);
    }

    private.nextRec := [_method="next", _sequence=private.id._sequence]
    public.next := function() {
	wider private;
	defaultservers.run(private.agent, private.nextRec);
    }

    private.previousRec := [_method="previous", _sequence=private.id._sequence]
    public.previous := function() {
	wider private;
	defaultservers.run(private.agent, private.previousRec);
    }

    private.setlocationRec := [_method="setlocation", _sequence=private.id._sequence]
    public.setlocation := function(location) {
	wider private;
	private.setlocationRec["location"] := location
	return defaultservers.run(private.agent, private.setlocationRec);
    }

    private.locationRec := [_method="location", _sequence=private.id._sequence]
    public.location := function() {
	wider private;
	return defaultservers.run(private.agent, private.locationRec);
    }

    private.lengthRec := [_method="length", _sequence=private.id._sequence]
    public.length := function() {
	wider private;
	return defaultservers.run(private.agent, private.lengthRec);
    }

    private.iswritableRec := [_method="iswritable", _sequence=private.id._sequence]
    public.iswritable := function() {
	wider private;
	return defaultservers.run(private.agent, private.iswritableRec);
    }

    private.getRec := [_method="get", _sequence=private.id._sequence]
    public.get := function() {
	wider private;
	wider public;
	rec := defaultservers.run(private.agent, private.getRec);
	newHistory := public.history();
	start := len(rec.hist)+1;
	end := start + len(newHistory) - 1;
	rec.hist[start:end] := newHistory;
	rec.hist[len(rec.hist)+1] := paste('get()');
	rec.hist::shape := [len(rec.hist)];
	return rec;
    }

    private.getemptyRec := [_method="getempty", _sequence=private.id._sequence]
    public.getempty := function(ref rec, nchan, nstokes) {
	wider private;
	private.getemptyRec["rec"] := rec;
	private.getemptyRec["nchan"] := nchan;
	private.getemptyRec["nstokes"] := nstokes;
	returnval :=  defaultservers.run(private.agent, private.getemptyRec);
	if (returnval) {
	    val rec := private.getemptyRec.rec;
	}
	return returnval;
    }

    private.putRec := [_method="put", _sequence=private.id._sequence]
    public.put := function(rec) {
	wider private;
	private.coercetypes(rec);
	private.coerceshapes(rec);
	private.putRec["rec"] := rec;
	return defaultservers.run(private.agent, private.putRec);
    }

    private.appendRec := [_method="appendrec", _sequence=private.id._sequence];
    public.appendrec := function(rec) {
	wider private;
	private.coercetypes(rec);
	private.coerceshapes(rec);
	private.appendRec["rec"] := rec;
	return defaultservers.run(private.agent, private.appendRec);
    }

    private.deleteRec := [_method="deleterec", _sequence=private.id._sequence];
    public.deleterec := function() {
	wider private;
	return defaultservers.run(private.agent, private.deleteRec);
    }

    private.getheaderRec := [_method="getheader", _sequence=private.id._sequence]
    public.getheader := function() {
	wider private;
	return defaultservers.run(private.agent, private.getheaderRec);
    }

    private.getotherRec := [_method="getother", _sequence=private.id._sequence]
    public.getother := function() {
	wider private;
	return defaultservers.run(private.agent, private.getotherRec);
    }

    private.getdataRec := [_method="getdata", _sequence=private.id._sequence]
    public.getdata := function() {
	wider private;
	return defaultservers.run(private.agent, private.getdataRec);
    }

    private.getdescRec := [_method="getdesc", _sequence=private.id._sequence]
    public.getdesc := function() {
	wider private;
	return defaultservers.run(private.agent, private.getdescRec);
    }

    private.getvectorsRec := [_method="getvectors", _sequence=private.id._sequence]
    public.getvectors := function(template) {
	wider private;
	private.getvectorsRec["template"] := template
	return defaultservers.run(private.agent, private.getvectorsRec);
    }

    private.makeTemplate := function(recordName, fieldNames) {
        wider private;
        temp := [=];
        temp[recordName] := [=];
        if (len(fieldNames) == 0) return;
        if (len(fieldNames) == 1) temp[recordName][fieldNames] := F;
        else
           for (i in fieldNames) temp[recordName][i] := F;
        return temp;
    }
 
    public.getheadervector := function(fieldNames) {
	wider private;
	return (public.getvectors(private.makeTemplate("header",fieldNames))).header;
    }

    public.getdescvector := function(fieldNames) {
	wider private;
	temp := [=];
	temp.data := private.makeTemplate("desc",fieldNames);
	return (public.getvectors(temp)).data.desc;
    }

    private.useCorrectedDataRec := [_method="usecorrecteddata",
				    _sequence=private.id._sequence];
    public.usecorrecteddata := function(correcteddata) {
	wider private;
	private.useCorrectedDataRec["correcteddata"] := correcteddata;
	return defaultservers.run(private.agent, private.useCorrectedDataRec);
    }

    private.correctedDataRec := [_method="correcteddata",
				 _sequence=private.id._sequence];
    public.correcteddata := function() {
	wider private;
	return defaultservers.run(private.agent, private.correctedDataRec);
    }

    private.nameRec := [_method="name", _sequence=private.id._sequence]
    public.name := function() {
	wider private;
	return defaultservers.run(private.agent, private.nameRec);
    }

    private.typeRec := [_method="type", _sequence=private.id._sequence]
    public.type := function() {
	wider private;
        if (is_record(private)) {
	    return defaultservers.run(private.agent, private.typeRec);
	} else {
	    return F;
	}
    }

    # return the id
    public.id := function() {
	wider private;
	return private.id;
    }

    public.history := function() {
	wider private;
	if (is_boolean(private.hist)) return '';
	return private.hist;
    }

    public.appendHistory := function(newHistory) {
	wider private;
	if (!is_string(newHistory)) fail;
	if (is_boolean(private.hist)) private.hist := newHistory;
	else {
	    start := len(private.hist)+1;
	    end := start+len(newHistory)-1;
	    private.hist[start:end] := newHistory;
	}
    }

    private.stringFieldsRec := [_method="stringfields", _sequence=private.id._sequence]
    public.stringfields := function() {
	wider private;
	wider public;
	rec := defaultservers.run(private.agent, private.stringFieldsRec);
	return rec;
    }

    public.done := function()
    {
	wider private, public;
	ok := defaultservers.done(private.agent, public.id().objectid);
	if (is_fail(ok)) fail;

	val private := F;
	val public := F;

	return ok;
    }

#    # for debugging purposes, turn off before this is part of the system
    public.debug := function() {
       wider private;
       return private;
    }

    return ref public;

} # _define_sditerator()

# if the default arguments are changed here, make sure that is reflected
# below in how the history is constructed
const sditerator := function(filename, readonly = T, selection = __emptyRecord,
			     lockoptions = 'auto', correcteddata = F,
			     host='', forcenewserver=F, shm=F)
{
    # don't bother unless filename is a Other Table type of file
    # use the defaultcatalog
    # eventually recognize MeasurementSets and Images here
    whatIsIt := dc.whatis(filename);
    if (!whatIsIt.istable || (whatIsIt.type != 'Other Table' && whatIsIt.type != 'Measurement Set')) {
	if (whatIsIt.type == 'FITS') {
	    note(paste(filename," is a FITS file - automatic conversion to an AIPS++ table is not yet implemented."),
		 priority='SEVERE', origin='sditerator()');
	}
        return throw(paste(filename,"is not an AIPS++ table"),
                     origin='sditerator()');
    }
    if (shm) print "sditerator: shared memory not implemented - ignoring"
#       turn this on when shm is an option for activate()
#    agent := defaultservers.activate("sditerator", host, forcenewserver, shm);
    agent := defaultservers.activate("sditerator", host, forcenewserver);
    # ALL selection happens later
    id := defaultservers.create(agent, "sditerator", "sditerator",
				[filename=filename, readonly=readonly, 
				 selection=__emptyRecord,
				 lockoptions=lockoptions,
				 correcteddata=correcteddata]);
    if (is_fail(id)) fail;
    newIt := ref _define_sditerator(agent, id);
    # construct the history for this, refer to arguments by name and only
    # use them when they do not have the default values.  This is more 
    # likely to be closest to what the user typed and it allows for
    # the addition of new, defaulted arguments without the risk of making
    # previously saved histories useless.
    # filename must always be supplied
    cmd := spaste('sditerator(filename=\'',filename,'\'');
    if (readonly != T) {
	cmd := spaste(cmd,',readonly=',readonly);
    }
    if (!has_field(selection,'empty')) {
	cmd := spaste(cmd,',selection=',newIt.sel2string(selection));
    }
    if (lockoptions != 'auto') {
	cmd := spaste(cmd,',lockoptions=\'',lockoptions,'\'');
    }
    if (correcteddata != F) {
	cmd := spaste(cmd,',correcteddata=',correcteddata);
    }
    if (host != '') {
	cmd := spaste(cmd,',host=\'',host,'\'');
    }
    if (forcenewserver != F) {
	cmd := spaste(cmd,',forcenewserver=',forcenewserver);
    }
    if (shm != F) {
	cmd := spaste(cmd,',shm=',shm);
    }
    cmd := spaste(cmd,')');
    newIt.appendHistory(cmd);
    # do any selection
    if (!(all(field_names(selection) == "empty") && selection.empty==T)) {
	selectedIt := newIt.select(selection);
	# whatever just happened, we're done with newIt
	newIt.done();
	if (is_fail(selectedIt)) fail;
	newIt := ref selectedIt;
    }

    return ref newIt;
} # sditerator()

#	this MUST have the same host and server
const sditfromsdit := function(sdit, selection = __emptyRecord)
{
    # verify that sdit has a select member
    if (!has_field(sdit, "select")) {
	return throw('first argument is not an sditerator',
		     origin='sditfromsdit');
    }
    return ref sdit.select(selection);
} # sditfromsdit()

# the default type here will be switched to MeasurementSet when available
# if the default arguments are changed here, make sure that is reflected
# below in how the history is constructed
const newsditerator := function(filename, type='Table', lockoptions='auto',
				host='', forcenewserver=F, shm=F)
{
    if (shm) print "newsditerator: shared memory not implemented - ignoring";
#       turn this on when shm is an option for activate();
#       agent := defaultservers.activate("sditerator",host,forcenewserver,shm);
    agent := defaultservers.activate("sditerator",host,forcenewserver);
    id := defaultservers.create(agent, "sditerator", "newsditerator",
				[filename=filename,type=type,lockoptions=lockoptions]);
    newIt := ref _define_sditerator(agent, id);
    # this history item is useful for recreating this iterator AFTER it has
    # already been created once.  i.e. its most useful by the results manager
    # when recreating the current state.  However, it doesn't accurately
    # reflect its true history.  This issue needs to be more cleanly
    # resolved eventually.
    # construct the history for this, refer to arguments by name and only
    # use them when they do not have the default values.  This is more 
    # likely to be closest to what the user typed and it allows for
    # the addition of new, defaulted arguments without the risk of making
    # previously saved histories useless.
    # the only arguments that might be preserved here, for use by the
    # standard sditerator ctor are filename, lockopions, host, forcenewserver
    # and shm.
    # filename must always be supplied
    cmd := spaste('sditerator(filename=\'',filename,'\'');
    if (lockoptions != 'auto') {
	cmd := spaste(cmd,',lockoptions=\'',lockoptions,'\'');
    }
    if (host != '') {
	cmd := spaste(cmd,',host=\'',host,'\'');
    }
    if (forcenewserver!=F) {
	cmd := spaste(cmd,',forcenewserver=',forcenewserver);
    }
    if (shm!=F) {
	cmd := spaste(cmd,',shm=',shm);
    }
    cmd := spaste(cmd,')');
    newIt.appendHistory(cmd);
    return ref newIt;
}

# an in-memory (all in glish) sditerator
# the name is used only as an aid here, nothing is currently save
# to disk
const memsditerator := function(name)
{
    private := [=];
    public := [=];

    private.name := name;
    private.hist := F

    # the actual records are placed here, indexed by number
    private.recs := [=];
    # this is a vector of record numbers (ints) 
    # this is needed in order to support selection and deletion
    private.recno := F;
    # pointer to current element of recno
    private.currec := 1;
    # the max number in recno
    private.maxrec := 0;

    public.select := function(selection = __emptyRecord) {
	wider private;
	wider public;
	fail "selection not yet support on memsditerators";
    }

    public.origin := function() {
	wider private;
	private.currec := 1;
	return T;
    }

    public.length := function() {
	wider private;
	if (is_boolean(private.recno)) return 0;
	else return len(private.recno);
    }

    public.more := function() {
	wider private;
	wider public;
	return (private.currec < public.length());
    }

    public.next := function() {
	wider private;
	wider public;
	if (public.more()) private.currec +:= 1;
	return T;
    }

    public.previous := function() {
	wider private;
	if (private.currec > 1) private.currec -:= 1;
	return T;
    }

    public.setlocation := function(location) {
	wider private;
	wider public;
	if (location > 0 && location < public.length()) private.currec := location;
	return T;
    }

    public.location := function() {
	wider private;
	return private.currec;
    }

    public.iswritable := function() { return T; }

    public.get := function() {
	wider private;
	wider public;
	if (public.length() <= 0) {
	    # would be nice to return an empty SDRecord, but fail for now
	    fail "no records available in this in-memory sditerator";
	}
	return private.recs[private.recno[private.currec]];
    }

    public.put := function(sdrec) {
	wider private;
	wider public;
	# no sanity check here, there probably should be
	if (public.length() <= 0) {
	    fail "no records in this in-memory sditerator, nothing to replace";
	}
	private.recs[private.recno[private.currec]] := sdrec;
	return T;
    }

    public.appendrec := function(sdrec) {
	wider private;
	wider public;
	# no sanity check here, there probably should be
	private.maxrec +:= 1;
	private.currec := public.length() + 1;
	private.recno[private.currec] := private.maxrec;
	public.put(sdrec);
	return T;
    }

    public.deleterec := function() {
	wider private;
	wider public;
	if (public.length() > 0) {
	    # zero out that record
	    private.recs[private.recno[private.currec]] := [=];
	    # forget about it
	    mask := array(T,public.length());
	    mask[private.currec] := F;
	    private.recno := private.recno[mask];
	}
	return T;
    }

    public.getheader := function() {
	wider public;
	return public.get().header;
    }

    public.getother := function() {
	wider public;
	return public.get().other;
    }

    public.getdata := function() {
	wider public;
	return public.get().data;
    }

    public.getdesc := function() {
	wider public;
	return public.get().desc;
    }

    private.makeVectorRec := function(template, curr)
    {
	wider private;
	wider public;
	result := [=];
	# add fields to result found in template 
	# if they also exist in curr, using curr 
	# as the type and making them arrays of 1-dim
	# larger than the input and having a length
	# the length of this iterator.  -whew

	for (fieldName in field_names(template)) {
	    if (has_field(curr, fieldName)) {
		if (is_record(template[fieldName])) {
		    result[fieldName] := private.makeVectorRec(template[fieldName],
							    curr[fieldName]);
		} else {
		    nels := len(curr[fieldName]) * public.length();
		    shape := [nels];
		    if (has_field(curr[fieldName]::, 'shape')) {
			shape := curr[fieldName]::shape;
			shape[len(shape)+1] := public.length();
		    }
		    result[fieldName] := array(curr[fieldName],nels);
		    result[fieldName]::shape := shape;
		}
	    }
	}
	return result;
    }

    private.vecCopier := function(ref result, curr, location)
    { 
	wider private;
	for (fieldName in field_names(result)) {
	    if (has_field(curr, fieldName)) {
		if (is_record(result[fieldName])) {
		    val result[fieldName] := private.vecCopier(result[fieldName],
							curr[fieldName],
							location);
		} else {
		    shape := result[fieldName]::shape;
		    offset := 1;
		    if (len(shape) > 1) {
			offset := prod(shape[1:(len(shape)-1)]);
		    }
		    startAt := 1 + offset*(location-1);
		    stopAt := startAt + len(curr[fieldName]) - 1;
		    val result[fieldName][startAt:stopAt] := 
			curr[fieldName];
		}
	    }
	}
	return result;
    }

    public.getvectors := function(template) {
	wider public;
	wider private;
	# reset iterator to top, remember where we are
	posn := public.location();
	# get the first one
	public.origin();
	curr := public.get();
	# make up the receptical for the result, to be filled
	# in as we go along.
	result := private.makeVectorRec(template, curr);
	# iterate to the end, starting with the one we already have
	for (i in 1:public.length()) {
	    private.vecCopier(result, curr, public.location());
	    public.next();
            curr := public.get();
	}
	# return the iterator to its last user set location
	public.setlocation(posn);
	return result;
    }

    private.makeTemplate := function(recordName, fieldNames) {
        wider private;
        temp := [=];
        temp[recordName] := [=];
        if (len(fieldNames) == 0) return;
        if (len(fieldNames) == 1) temp[recordName][fieldNames] := F;
        else
           for (i in fieldNames) temp[recordName][i] := F;
        return temp;
    }
 
    public.getheadervector := function(fieldNames) {
	wider private;
	return (public.getvectors(private.makeTemplate("header",fieldNames))).header;
    }

    public.getdescvector := function(fieldNames) {
	wider private;
	temp := [=];
	temp.data := private.makeTemplate("desc",fieldNames);
	return (public.getvectors(temp)).data.desc;
    }

    public.name := function() {
	wider private;
	return private.name;
    }

    public.type := function() {
	wider private;
	return private.type;
    }

    public.id := function() {
	# this has no DO id, functions expecting one will need to deal with this
	return F;
    }

    public.history := function() {
	wider private;
	if (is_boolean(private.hist)) return '';
	return private.hist;
    }

    public.appendHistory := function(newHistory) {
	wider private;
	if (!is_string(newHistory)) fail;
	if (is_boolean(private.hist)) private.hist := newHistory;
	else {
	    start := len(private.hist)+1;
	    end := start+len(newHistory)-1;
	    private.hist[start:end] := newHistory;
	}
    }

    public.done := function() {
	wider private, public;
	private := F;
	val public := F;
	return T;
    }

    public.private := function() {
	wider private;
	return private;
    }

    return ref public;
}
   

const is_sditerator := function (candidate) 
{
  if (is_record (candidate) &&    
      has_field (candidate,'setlocation') && 
      has_field (candidate,'getdata') && 
      has_field (candidate,'getheader') && 
      has_field (candidate,'getother') && 
      has_field (candidate,'getheadervector'))
    return T;
  else
     return F;
}

const is_sdrecord := function (candidate) 
{
  if (is_record (candidate) && 
      has_field (candidate, 'data') && 
      has_field (candidate, 'header') && 
      has_field (candidate, 'hist'))
    return T;
  else
    return F;
}

tsditerator := function(it, repeat = 1)
{
    if (!is_sditerator(it)) {
	fail ('it is not an sditerator');
    }
    pvt := [=];
    pvt.elapsedLog := function(t0, npts) {
	elapsedT := time()-t0;
	print "Elapsed: ", elapsedT, " avg : ", elapsedT/npts, " rate : ", npts/elapsedT;
    }

   itlen := it.length();

   print "next from 1 to ",it.length()," - repeated ", repeat, " times"
   it.origin();
   t0 := time();
   for (n in 1:repeat) 
   { for (n in 1:itlen) it.next(); }
   pvt.elapsedLog(t0,itlen);

   print "more from 1 to ",it.length()," - repeated ", repeat, " times"
   it.origin();
   t0 := time();
   for (n in 1:repeat) 
   { for (n in 1:itlen) junk := it.more(); }
   pvt.elapsedLog(t0,itlen);

   print "get from 1 to ",it.length()," - repeated ", repeat, " times"
   it.origin();
   t0 := time();
   for (n in 1:repeat) 
   { for (n in 1:itlen) r := it.get(); }
   pvt.elapsedLog(t0,itlen);

   print "get with next and more from 1 to ",it.length()," - repeated ", repeat, " times"
   it.origin();
   t0 := time();
   for (n in 1:repeat) {
      r := it.get(); 
      if (!is_sdrecord(r)) fail('r is not an sdrecord');
      while(it.more()) {
	it.next();
        r := it.get();
      }
   }
   pvt.elapsedLog(t0,itlen);
}
