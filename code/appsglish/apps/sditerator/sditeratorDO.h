//# sditeratorDO: this defines sditerator, which is the DO interface to SDIterator
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: sditeratorDO.h,v 19.4 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_SDITERATORDO_H
#define APPSGLISH_SDITERATORDO_H

#include <casa/aips.h>
#include <tables/Tables/TableLock.h>
#include <tasking/Tasking.h>
#include <tasking/Tasking/Index.h>
#include <dish/SDIterators/SDIterator.h>
#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
template<class T> class Vector;
class String;
class GlishRecord;


// <summary>
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class sditerator : public ApplicationObject
{
public:
    // Method enumerations
    enum Methods { SELECT=0, RESYNC, FLUSH, RESELECT, DEEPCOPY, LOCK, UNLOCK,
		   ORIGIN, MORE, NEXT,
		   PREVIOUS, SETLOCATION, LOCATION, LENGTH, ISWRITABLE, GET, 
		   GETEMPTY, PUT, APPENDREC, DELETEREC, GETHEADER, GETOTHER, 
		   GETDATA, GETDESC, GETVECTORS, NAME, STRINGFIELDS, 
		   USECORRECTEDDATA, CORRECTEDDATA, TYPE, NUMBER_METHODS};

    // "sditerator" ctors
    // make a new iterator (no selection possible, always NOT readOnly)
    sditerator(const String &fileName, const String &type, 
	       const String &lockoptions);

    // From an exiting file, with optional selection, deduce type from the file
    sditerator(const String &fileName, Bool readOnly, 
	       const GlishRecord &selection,
	       const String &lockoptions, Bool correcteddata);
    // From another iterator with optional selection, creates one having the same 
    // type and lockoptions.
    sditerator(const sditerator& other, const GlishRecord &selection);

    // copy constructor
    sditerator(const sditerator &other);
    // assignment operator, types must match
    sditerator &operator=(const sditerator &other);
    // destructor
    ~sditerator();

    // make a new object from this one with selection
    ObjectID select(const GlishRecord& selection);

    // resync with the underlying table
    void resync() {iter_p->resync();}

    // flush to the underlying table, a no-op for read-only sditerators
    void flush() {iter_p->flush();}

    // reselect - reapply any previously applied selection
    void reselect() {iter_p->reselect();}

    // make a deep copy - main table and any subtables
    void deepcopy(const String &newname) {iter_p->deepCopy(newname);}

    // unlock all tables associated with this sditerator
    Bool unlock() {return iter_p->unlock();}

    // lock all tables associated with this sditerator
    // Try nattempts before giving up - one per second.
    Bool lock(uInt nattempts) {return iter_p->lock(nattempts);}

    // reset the iterator to the top
    void origin() {iter_p->origin();}

    // are there more records after the current one
    Bool more() {return iter_p->more();}

    // move to the next one, if at end, nothing changes
    void next() {(*iter_p)++;}

    // move to the previous one, it at origin, nothing changes
    void previous() {(*iter_p)--;}

    // set the location to a specific record, return False if out of bounds
    Bool setlocation(Index loc);

    // the current record number
    //Index location() {return Index(iter_p->where());}
    Index location();

    // how many records are in this iterator
    Int length() {return iter_p->nrecords();}

    // Is this iterator writable
    Bool iswritable() {return iter_p->isWritable();}

    // get the current record
    GlishRecord get();

    // get an empty record having the indicated number of
    // chanels and stokes values
    Bool getempty(GlishRecord &rec, Int nchan, Int nstokes);

    // put the current record, return False if iswritable() is False;
    Bool put(const GlishRecord& rec);

    // append this record to the end of the iteratorator, return False
    // if this isn't writable.  The iterator pointer is set to the
    // end of the iterator
    Bool appendRec(const GlishRecord &rec);

    // delete the record at the current pointer, return False if this
    // isn't writable.  The iterator pointer remains set at the same
    // location (which will then contain the record following the one
    // which was deleted or the previous one if the deleted record was
    // at the end).
    Bool deleteRec();

    // get the current header
    GlishRecord getheader();

    // get the current other header
    GlishRecord getother();

    // get the current data record
    GlishRecord getdata();

    // get the current data description record
    GlishRecord getdesc();

    // get all values from the iterator for the fields
    // specified in the template from all rows
    GlishRecord getvectors(const GlishRecord& recTemplate);

    // return the name of the iterator
    String name() const {return iter_p->name();}

    // return a record containing bools for each field in the sdrecord which
    // is a scalar string field
    GlishRecord stringfields();

    // Toggle the use of the CORRECTED_DATA column, when available.
    // If no CORRECTED_DATA column is available, this function returns False.
    Bool usecorrecteddata(Bool correctedData)
    {return iter_p->useCorrectedData(correctedData);}

    // Report the current value of the correctedata toggle.
    Bool correcteddata() const {return iter_p->correctedData();}

    // return the type for this iterator
    String type() const {return iter_p->type();}

    // this is used internally, after construction
    Bool iterOK() const {return iter_p->ok();}

    // Non-DO methods used by sdaverager instead of the ones that
    // return GlishRecords (i.e. the true DO methods)
    // get the current record as an SDRecord
    const SDRecord &getsdrecord();

    // get the current data record
    const Record &getData();

    // get the current header record
    const Record &getHeader();

    // get the current other record
    const Record &getOther();

    // Stuff needed for distributing this class
    virtual String className() const {return "sditerator";}
    virtual Vector<String> methods() const;
    virtual Vector<String> noTraceMethods() const;

    // If your object has more than one method
    virtual MethodResult runMethod(uInt which, 
				   ParameterSet &inputRecord,
				   Bool runMethod);
private:
    SDIterator *iter_p;

    // deduce the type based on the file
    String deduceType(const String &fileName);

    TableLock::LockOption translateOption(const String &lockoptions);
};

class sditeratorFactory : public ApplicationObjectFactory
{
    virtual MethodResult make(ApplicationObject *&newObject,
			      const String &whichConstructor,
			      ParameterSet &inputRecord,
			      Bool runConstructor);
};

} //# NAMESPACE CASA - END

#endif
