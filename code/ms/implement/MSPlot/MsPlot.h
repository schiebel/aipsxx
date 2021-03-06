//# MsPlot.h: this defines MsPlot, which display MS data in various combinations.
//# Copyright (C) 2003
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
//#! ========================================================================
//#!                Attention!  Programmers read this!
//#!
//#! This file is a template to guide you in creating a header file
//#! for your new class.   By following this template, you will create
//#! a permanent reference document for your class, suitable for both
//#! the novice client programmer, the seasoned veteran, and anyone in 
//#! between.  It is essential that you write the documentation portions 
//#! of this file with as much care as you do the source code.
//#!
//#! This file has some special lexical features which need explanation:
//#!
//#!    -  "replacement" tokens
//#!    -  Comment conventions (in addition to the normal C++ "//")
//#!    -  Markup tags, for the documentation extractor
//#!
//#!                         Replacement Tokens
//#!                         ------------------
//#!
//#! These are character strings enclosed in angle brackets, on a commented
//#! line.  Two are found on the first line of this file:
//#!
//#!   <ClassFileName.h> <ClassName>
//#!
//#! You should remove the angle brackets, and replace the characters within
//#! the brackets with names specific to your class.  Mimic the capitalization
//#! and punctuation of the original.  For example, you would change
//#!
//#!   <ClassFileName.h>  to   LatticeIter.h
//#!   <ClassName>        to   LatticeIterator
//#!
//#! Another replacement token will be found in the "include guard" just
//#! a few lines below.
//#!
//#!  #define <AIPS_CLASSFILENAME_H>  to  #define AIPS_LATTICEITER_H
//#!
//#!
//#!              Comment conventions used in this file.
//#!              --------------------------------------
//#!
//#! 1. Lines beginning with "//#!" are instructions to you, the reader of
//#!    template-class-h, which explain how to adapt this file to create
//#!    your own ClassFileName.h.  These lines should *not* appear in the
//#!    the final version of your ClassFileName.h.
//#! 2. Lines beginning with the shorter sequence "//#" stay in the file
//#!    permanently, but they are ignored by the document extractor and,
//#!    of course, by the compiler.  The license agreement (above) is
//#!    a good example.
//#! 3. Lines beginning with the traditional C++ comment token, "//",
//#!    may include tags to be used by the documentation extractor.
//#!
//#!
//#!              Markup tags for the documentation extractor
//#!              -------------------------------------------
//#!
//#! These tags are roughly similar to those found in the well-known
//#! HTML (hyper-text markup language) used on the world-wide-web.
//#! They identify sections of the documentation so that the extractor
//#! (a standard aips++ utility) can manipulate them, and create
//#! programmer documentation.
//#!   (See http://www.cv.nrao.edu/aips++/docs/html/cxx2html.html)
//#! These tags also serve as helpful organization clues to anyone who
//#! reads the text directly, serving as section titles.
//#!
//#! Tags are set up like this:
//#!
//#!       <tag>  Contents (or body) of tagged section
//#!       </tag>
//#!
//#! Please note that, with few exceptions, all tags are accompanied by
//#! explicit "end tags".  So <summary> must be paired with </summary> 
//#! and <src> with </src>.
//#!
//#! Exceptions to this rule:
//#!
//#!  <li>     which identifies "list items".  They are only found in the 
//#!           body of <ul> or <ol> tags, and their implicit end tags are 
//#!           deduced from the surrounding context.
//#!
//#!  <use...> a tag which has no body, only attributes.
//#!
//#!                          ------------
//#!
//#! Here are some of the tags we use:
//#!
//#!   <summary>:           A one line description of this class.
//#!
//#!   <prerequisite>:      Classes and concepts the reader should
//#!                        understand before tackling this one.
//#!
//#!   <etymology>:         Explains why "ClassName" was selected.
//#!
//#!   <synopsis>:          A medium-to-long description of this class.
//#!                        You may wish to break up a longish synopsis
//#!                        section with a standard HTML tag -- for instance
//#!                          <h3>  some subtitle </h3> 
//#!                        will insert a 'level 3' heading into the 
//#!                        html file.
//#!
//#!   <motivation>:        The circumstances which led to the creation of
//#!                        this class.
//#!
//#!   <todo>:              A list of bugs, missing features, planned
//#!                        extensions.
//#!
//#!   <reviewed>:          By whom, when, and with what test and demo
//#!                        programs. The body of this tag will contain
//#!                        any comments the reviewer wishes to make.
//#!
//#!   <use...>:            Describes the intended use of the class.  
//#!                        Currently, there is only one attribute, 
//#!                        'visibility' which has the value 'local'
//#!                        or 'export'.
//#!
//#!   <ul>:                Introduces the beginning of a unnumbered list.
//#!
//#!   <ol>:                Introduces an ordered (numbered) list.
//#!
//#!   <li>:                Indicates one item in a list.
//#!
//#!   <srcblock>:          A section of text -- sample code, for example --
//#!                        that will be presented in a distinct
//#!                        font and without reformatting. This tag should
//#!                        be used for multi-line source code text.
//#!                        (This is for illustrative code only, hidden
//#!                        from the compiler in commet lines.  It is not
//#!                        for real, live C++ code.)
//#!
//#!   <src>:               Just like <srcblock>, but for code fragments
//#!                        which are quite short, quoted "inline" in the
//#!                        midst of regular explanatory comments.
//#!
//#!   <note role=tip>:     Helpful advice for the programmer who will use this
//#!                        class.
//#!
//#!   <note role=caution>: Explains why certain use of the class may be
//#!                        a bit tricky, and needs some care.
//#!
//#!   <note role=warning>: Warns the programmer of dangerous coding practices.
//#!
//#!   <templating arg=T>:  A templated class often requires certain
//#!                        member functions in the template arguments.
//#!                        (see example below for a full explanation).
//#!
//#!   <thrown>:            Provide a list of exceptions thrown before
//#!                        the declaration of the function that throws them.
//#!
//#!   <group>,
//#!   <group name=xxx>:    Use this tag to apply a single comment to a
//#!                        group of related functions.  If you use the
//#!                        'name' attribute, then the document extractor
//#!                        will generate an anchor for this group --
//#!                        meaning that the group can be reached via a
//#!                        hyper-text link.  (This link will appear only in
//#!                        the present file, and will appear in addition to
//#!                        the usual links generated for each member function.
//#!                        To generate a link in some *other* class file,
//#!                        which points to this file, use the <linkfrom> tag.
//#!
//#!   <linkto ...>:        This creates a link to an anchor in another
//#!                        document.  
//#!                        Please consult
//#!                   http://www.cv.nrao.edu/aips++/docs/html/cxx2html.html
//#!                        and read the section titled "LINKTO"
//#!
//#!   <linkfrom...>:       This tag instructs the document extractor to
//#!                        create an anchor in *another* document -- that is,
//#!                        a hyper-text link whose destination is here.
//#!                        There are several attributes to this tag, and
//#!                        there is also the associated <here> tag.
//#!                        Please consult
//#!                   http://www.cv.nrao.edu/aips++/docs/html/cxx2html.html
//#!                        and read the section titled "LINKFROM"
//#!
//#!   <here>:              Provides the text of the HTML anchor that will
//#!                        be placed in the *other* file named in the 
//#!                        linkfrom tag.  See example below.
//#!
//#!   <module>             This tag tells the document extractor that
//#!                        the enclosed text describes a set of related
//#!                        classes, organized into their own directory.
//#!                        This tag is found only in module header files,
//#!                        where it encloses  most of the contents
//#!                        of the module header file.  
//#!
//#!   Some tags (i.e., "reviewed" and "todo") have attributes -- key/value
//#!   pairs like this:
//#!
//#!      <reviewed reviewer="Paul Shannon" date="1994/11/10">
//#!       ...comments...
//#!      </reviewed>
//#!
//#!      <todo asof="1994/11/02">
//#!         <li> add default ctor
//#!      </todo>
//#!
//#!   The keywords (reviewer, date, asof) are fixed.
//#!   Their values ("Paul Shannon", "1994/11/10", "1994/11/02") should be 
//#!   enclosed in double quotes.  Dates must be in the standard format:
//#!   yyyy/mm/dd.
//#!
//#! ==========================================================================
//#! The following RCS (Revision Control System) identifier serves a dual 
//#! purpose:  it records version control information for the template 
//#! template-module-h,  and (after you delete the appropriate characters) 
//#! it becomes the RCS identifier for *your* module header file.  The 
//#! characters to delete are all those in the RCS Id, below, from the first
//#! colon up to the trailing dollar sign.
//#! (RCS expands the 'Id' token, surrounded by dollar signs, into the file
//#! name, with version number and date of last change.
//#! ==========================================================================
//#
//# $Id: MsPlot.h,v 1.10 2006/07/23 23:58:31 mmarquar Exp $

//#! Create an include 'guard', containing your class name in the all
//#! upper case format implied below.  This prevents multiple inclusion
//#! of this header file during pre-processing.
//#!
//#! Note that the leading "AIPS_" identifies the package to which your class
//#! belongs.  Other packages include dish, vlbi, nfra, synthesis, atnf...
//#! If you are contributing a new class to one of these packages, be
//#! sure to replace "AIPS_" with (for instance) "DISH_" or "ATNF_".

#if !defined AIPS_MSPLOT_H
#define AIPS_MSPLOT_H

//#! Includes go here
#include <casa/BasicSL/String.h>
#include <casa/string.h>
//
#include <tables/TablePlot/TablePlot.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSSelection.h>
//
#include <measures/Measures/MPosition.h>
// tasking is supposed to be used only in appsglish directory
//#include <tasking/Glish/GlishRecord.h>
//
namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations

// <summary>
//#! A one line summary of the class.   This summary (shortened a bit
//#! if necessary so that it fits along with the "ClassFileName.h" in 75
//#! characters) should also appear as the first line of this file.
//#! Be sure to use the word "abstract" here if this class is, indeed,
//#! an abstract base class.
// </summary>

// <use visibility=local>   or   <use visibility=export>
//#! If a class is intended for use by application programmers, or
//#! people writing other libraries, then specify that this class
//#! has an "export" visibility:  it defines an interface that
//#! will be seen outside of its module.  On the other hand, if the
//#! class has a "local" visibility, then it is known and used only
//#! within its module.

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
//#! for example:
//#!  <reviewed reviewer="pshannon@nrao.edu" date="1994/10/10" tests="tMyClass, t1MyClass" demos="dMyClass, d1MyClass">
//#!  This is a well-designed class, without any obvious problems.
//#!  However, the addition of several more demo programs would
//#!  go a *long* way towards making it more usable.
//#!  </reviewed>
//#!
//#! (In time, the documentation extractor will be able handle reviewed
//#! attributes spread over more than one line.)
//#!
//#! see "Coding Standards and Guidelines"  (AIPS++ note 167) and
//#! "AIPS++ Code Review Process" (note 170) for a full explanation
//#! It is up to the class author (the programmer) to fill in these fields:
//#!     tests, demos
//#! The reviewer fills in
//#!     reviewer, date
// </reviewed>

// <prerequisite>
//#! Classes or concepts you should understand before using this class.
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
//#! Except when it is obvious (e.g., "Array") explain how the class name
//#! expresses the role of this class.  Example: IPosition is short for
//#! "Integral Position" - a specialized integer vector for specifying
//#! array dimensions and indices.
// </etymology>
//
// <synopsis>
//#! What does the class do?  How?  For whom?  This should include code
//#! fragments as appropriate to support text.  Code fragments shall be
//#! delimited by <srcblock> </srcblock> tags.  The synopsis section will
//#! usually be dozens of lines long.
// </synopsis>
//
// <example>
//#! One or two concise (~10-20 lines) examples, with a modest amount of
//#! text to support code fragments.  Use <srcblock> and </srcblock> to
//#! delimit example code.
// </example>
//
// <motivation>
//#! Insight into a class is often provided by a description of
//#! the circumstances that led to its conception and design.  Describe
//#! them here.
// </motivation>
//
// <templating arg=T>
//#! A list of member functions that must be provided by classes that
//#! appear as actual template arguments.  For example:  imagine that you
//#! are writing a templated sort class, which does a quicksort on a
//#! list of arbitrary objects.  Anybody who uses your templated class
//#! must make sure that the actual argument class (say, Int or
//#! String or Matrix) has comparison operators defined.
//#! This tag must be repeated for each template formal argument in the
//#! template class definition -- that's why this tag has the "arg" attribute.
//#! (Most templated classes, however, are templated on only a single
//#! argument.)
//    <li>
//    <li>
// </templating>
//
// <thrown>
//#! A list of exceptions thrown if errors are discovered in the function.
//#! This tag will appear in the body of the header file, preceding the
//#! declaration of each function which throws an exception.
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//#! A List of bugs, limitations, extensions or planned refinements.
//#! The programmer should fill in a date in the "asof" field, which
//#! will usually be the date at which the class is submitted for review.
//#! If, during the review, new "todo" items come up, then the "asof"
//#! date should be changed to the end of the review period.
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

template<class T> class MsPlot : public TablePlot<T>
{
public:

//#! Please arrange class members in the sections laid out below.  A
//#! possible exception (there may be others) -- some operator functions
//#! may perform the same task as "General Member Functions", and so you
//#! may wish to group them together.

//#! Friends

//#! Enumerations

//#! Constructors
// Constructor
   MsPlot();
   MsPlot( const MeasurementSet& ms );

//#! Destructor
// Destructor
   ~MsPlot();

//#! Operators

//#! General Member Functions
// General Member Functions
// Determine subset of MS based on ANTENNA parameters
Bool antennaSelection( const Vector<String>& antennaNames, const Vector<Int>& antennaIndex = -1 );
// Determine subset of MS based on SPECTRAL_WINDOW parameters
Bool spwSelection( const Vector<String>& spwNames, const Vector<Int>& spwIndex=-1 );
Bool fieldSelection( const Vector<String>& fieldNames, const Vector<Int>& fieldIndex = -1);
Bool uvDistSelection( const Vector<String>& uvDists );
// Bool scanSelection( Vector<LString> scans );
Bool timeSelection( const Vector<String>& times );
Bool corrSelection( const String& correlations );
//#! Select a subset of the data (MeasurementSet )
Bool setData( const Vector<String>& antennaNames, const Vector<Int>& antennaIndex,
              const Vector<String>& spwNames, const Vector<Int>& spwIndex,
				  const Vector<String>& fieldNames,  const Vector<Int>& fieldIndex,
				  const Vector<String>& uvDists,
				  const Vector<String>& times,
				  const String& correlations 
            );
// set the plotting axes ( X and Y )
Bool setAxes( PtrBlock<BasePlot<T>* > &BPS, Vector<String> & dataStr );
// set the plot labels and plot attributes
Bool setLabels( TPPlotter<T> &TPLP, Record &plotOption, Vector<String> &labels );
// Convert the antenna coordinates into local frame and put the antenna positions into a MemoryTable.
Bool antennaPositions( Table& ants );
// Plot the data
Int plot( PtrBlock<BasePlot<T>* > &BPS, TPPlotter<T> &TPLP, Int panel );
// help function to transform the coordinates from the global geocentric frame( e.g ITRF ) to
// the local topocentric frame ( origin: observatory=center of antenna array; x-axis: local east;
// y-axis: local north; z-axis: local radial direction. ). Here we are not worrying about the effect
// of the earth's ellipticity even though did use latitude instead of the angle between the earth
// pole and the local radial direction. The error stemed from this is about 1/300.
// Parameter:  
// obervatroy: observatory position in the geocentric frame. It is the origin of the local frame;
// posGeo: MPositions in geocentric frame
// xTopo, yTopo, zTopo: x,y z components of posGet after converting into local topocentric frame.
void global2local( const MPosition& observatory,
                             const Vector<MPosition>& posGeo,
			                     Vector<Double>& xTopo,
			                     Vector<Double>& yTopo,
			                     Vector<Double>& zTopo ); 
void spwParser( const String& spwExpr, Vector<Int>& spwIndex, Vector<Int>& chanIndex, Vector<String>& chanRange );
void corrParser( const String& corrExpr, Vector<String>& stokesNames );
Bool polarIndices( const Vector<Int> spwIDs, PtrBlock<Vector<Int>* >& polarsIndices );
Bool containStokes( const Vector<Int> corrType, const Vector<String>& stokesNames, Vector<Int>& polarIndices );
Bool polarNchannel( PtrBlock<Vector<Int>* >& polarsIndices, Vector<Int>& chanIndices, Vector<String>& chanRange );
Bool derivedValues( Vector<Double>& derivedQuan, const String& quanType );
Int toltalAntenna();
protected:

//#! Data Members

//#! Constructors

//#! Inheritable Member Functions

private:
	 // indicating if the TablePlot::TABS_P is set. Before calling plot if TABS_P is still
	 // not set, assign m_ms to it ( this means to use the original MS, instead of its subset. )
	 Bool m_dataIsSet;
	 MeasurementSet m_ms, m_subMS;
	 // used by TablePlot::getData();
	 // PtrBlock<BasePlot<T>* > m_BPS;
	 //TPPlotter<T> m_TPLP;
	 //Bool m_firstPlot;
	 //Record m_plotOption;
	 // number of panels
	 //Int m_nPanels;
	 //Int m_nXPanels, m_nYPanels;
	 Bool m_dbg; 
//#! Data Members
	 MSSelection m_select;
	 String m_spwExpr;
	 String m_corrExpr;
	 Vector<String> m_antennaNames;
	 Vector<Int> m_antennaIndex;
	 PtrBlock<BasePlot<T>* > *m_BPS;
//#! Constructors
// We do not provide copy constructor and assignment operator. So declare them as private.
    MsPlot( const MsPlot &other );
	 MsPlot &operator =( const MsPlot &other );
//#! Private Member Functions

};

//#!                        global functions
//#!                        ----------------
//#!
//#! (see note 167, Standards and Guidelines, section 2.3, for help
//#! in deciding when global functions should be declared in a class
//#! header file, and when they should be declared in their own
//#! own header file.)

//#! comments that shed light on the following group of functions.
//#! this group is surrounded by <group> and </group> -- the comments
//#! apply to *every* function in the group.  there may be any number
//#! of these groups, but be sure to use a unique string for each group

// <linkfrom anchor=unique-string-within-this-file classes="class-1,...,class-n">
//     <here> Global functions </here> for foo and bar.
// </linkfrom>

// comments for this group of related global functions
// go here...

// <group name=unique-string-within-this-file>  
//#! your first group of related functions are declared here
//#! (a group may have only one member)
// </group>

// comments about the following group
// <group name=another-unique-string-within-this-file>
//#! another group of related functions are declared here
// </group>



//#!                        some explanation
//#!                        ----------------
//#!
//#! <unique-string-within-this-file>: should be replaced with a
//#!         string of your choosing.  this gives a label (an HTML anchor)
//#!         to this group of functions -- the anchor will appear towards
//#!         the top of the extracted HTML file, allowing quick and easy
//#!         navigation to these related functions
//#!
//#!                           example
//#!                           -------
//#!
//#! here is an example from Slicer.h, in which one global
//#! function is "grouped" and introduced by one line of
//#! comment.  "ostream" is the <unique-string-within-this-file>.
//#! two classes (Slicer and ostream) -- which appear as arguments to
//#! the two functions -- are named in the argument list.

//#!  // Write a text description of the Slicer to an output stream.
//#!
//#!  // <group name=ostream)
//#!  ostream &operator<< (ostream &, const Slicer &);
//#!  // <group>

} //# NAMESPACE CASA - END
#ifndef AIPS_NO_TEMPLATE_SRC
#include <ms/MSPlot/MsPlot.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif


