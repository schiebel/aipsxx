//# VLASDA: 
//# Copyright (C) 1999,2000,2003
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
//# $Id: VLASDA.h,v 19.4 2004/11/30 17:50:43 ddebonis Exp $

#ifndef NRAO_VLASDA_H
#define NRAO_VLASDA_H

#include <casa/aips.h>
#include <nrao/VLA/VLAEnum.h>
#include <casa/IO/ByteSource.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MFrequency.h>
#include <measures/Measures/MDoppler.h>
#include <measures/Measures/Stokes.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
template <class T> class Vector;
template <class T> class Matrix;
class String;
} //# NAMESPACE CASA - END


// <summary>
// Interprets the data in an sub-array data area of a VLA logical record.
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> The VLA archive format as described in VLA computer memo 188
// </prerequisite>
//
// <etymology> The sub-array data is, in memo 188, frequently shortened to the
// acronym SDA. As this is specific to the VLA the name VLAADA seemed
// appropriate.
// </etymology>
//
// <synopsis>
// This class contains functions which access and interpret the data in the
// sub-array data area of a VLA logical record. 
//
// The functions in this class access the specified data in the sub-array data
// area and may convert the units and data types to something more suitable for
// general use. They also interpret the data and provide some derived
// quantities eg., the nPol function.
// </synopsis>
//
// <example>

// This code fragment shows how to initialise a VLASDA object and then use
// this object to determine how much data is in this record. It is assumed that
// the Bytesource object contains a VLA Logical record.
// <srcblock>
//   ByteSource VLARecord(...);
//   VLARCA rca;
//   VLASDA sda(VLARecord, rca.SDAOffset());
//   cout << "The record has " << rca.nAntennas() <<  " antennas." << endl;
//   for (uInt c = 0; c < 4; c++) {
//       cout << "CDA " << c;
//     if (rca.CDAOffset() == 0) {
//       cout << " is not used." << endl;
//     else {
//       cout << " has " << sda.nChannels(c) << " spectral channels and"
//            << sda.npol(c) << " polarisations." << endl;
//     }
//   }
// </srcblock>
// </example>
//
// <motivation>
// This class was needed as part of the VLA filler application. 
// </motivation>
//
// <thrown>
// This class will throw an exception (AipSError) if you the correlator data
// area argument is four or more. When compiled in debug mode this class does a
// lot of consistancy checking. If it detects anomolies it will throw an
// exception (AipsError).
// </thrown>
//
// <todo asof="1999/08/13">
//   <li> The member functions should probably be rounded out.
// </todo>

class VLASDA
{
public:
  // The default constructor creates a unusable object. You need to use the
  // assignment operator or the attach function to create a usable object.
  VLASDA();

  // Construct this object to read data from the SDA of the given VLA logical
  // record. The SDA must begin at the specified number of bytes from the
  // beginning of the record (see the example above).
  VLASDA(ByteSource& record, uInt offset);

  // The destructor is trivial;
  ~VLASDA();

  // The copy constructor uses reference semantics.
  VLASDA(const VLASDA& other);

  // The assignment constructor uses reference semantics.
  VLASDA& operator=(const VLASDA& other);
    
  // Re-initialise this object so that it now reads data from the given VLA
  // logical record.  The sub-array data area that will be used begins at the
  // specified number of bytes from the beginning of the record.
  void attach(ByteSource& record, uInt offset);

  // returns the number of data channels in the specified CDA (including
  // the average channel)
  uInt trueChannels(VLAEnum::CDA cda) const;
    
  // returns the number of spectral channels in the specified CDA (excludes
  // channel zero)
  uInt nChannels(VLAEnum::CDA cda) const;
    
  // returns the observed frequency (in Hz), at the band centre for the
  // specified CDA. This is the observed frequency after Doppler tracking has
  // been applied. It will correspond to the middle of the centre channel if
  // there are an odd number of channels and takes into account that some
  // channels may have been correlated but discarded prior to archiving.
  Double obsFrequency(VLAEnum::CDA cda) const;
    
  // returns the observed frequency at the lower edge of the band, after
  // correcting for channels that have been correlated and discarded prior to
  // archiving the data. ie it returns the observed frequency of the lower edge
  // of the first channel in the data.
  Double edgeFrequency(VLAEnum::CDA cda) const;

  // returns true if Doppler tracking has been turned on for the specified
  // CDA. If so then the observed frequency is calculated from the source
  // radial velocity, the line rest frequency and the component of the earths
  // velocity relative to the source (in the specified reference Frame).
  Bool dopplerTracking(VLAEnum::CDA cda) const;

  // returns the assumed rest frequency of the source radiation in Hz (for the
  // specified CDA). This number is supplied by the observer and used in the
  // doppler tracking calculations. The returned value is not meaningful if
  // doppler tracking is not used.
  Double restFrequency(VLAEnum::CDA cda) const;
    
  // returns the assumed radial velocity of the source in m/sec (for the
  // specified CDA). This number is supplied by the observer and used in the
  // doppler tracking calculations. The returned value is not meaningful if
  // doppler tracking is not used.
  Double radialVelocity(VLAEnum::CDA cda) const;

  // Return the assumed rest frame that will be used when calculating the
  // observers motion relative to the source (for the specified CDA). This
  // frame is supplied by the observer and used in the Doppler tracking
  // calculations. The returned value is not meaningful of Doppler tracking is
  // not used.
  MFrequency::Types restFrame(VLAEnum::CDA cda) const;

  // Return the definition of Doppler shift used to convert the radial
  // velocity to a frequency (for the specified CDA). This is supplied by the
  // observer and used in the Doppler tracking calculations. The returned value
  // is not meaningful of Doppler tracking is not used.
  MDoppler::Types dopplerDefn(VLAEnum::CDA cda) const;

  // returns the bandwidth of an individual channel, in Hz, of the data in the
  // specified CDA.
  Double channelWidth(VLAEnum::CDA cda) const;

  // returns the total bandwidth, in Hz, over all the channels of the data in
  // the specified CDA. Throws an exception if which > 3.
  Double correlatedBandwidth(VLAEnum::CDA cda) const;

  // returns the total bandwidth, in Hz, of the front end filter in the
  // specified CDA. Throws an exception if which > 3.
  Double filterBandwidth(VLAEnum::CDA cda) const;

  // Return the correlator mode for this record. Only useful if you know what
  // these codes are. The functions immediatly following this one are probably
  // more useful as they interpret this code for you.
  VLAEnum::CorrMode correlatorMode() const;

  // Return the 'electronic path' that the data in the specified CDA has
  // travveled through. Returns 0 if the data in the specified CDA is from IF's
  // A or C and 1 if the data is from IF's B or D. The returned value is
  // meaningless if the CDA is not used in the current record. This information
  // is obtained from knowing what the correlator modes represent.
  uInt electronicPath(VLAEnum::CDA cda) const;

  // Return the number of polarisations in the specified CDA. This information
  // is obtained from knowing what the correlator modes represent.
  uInt npol(VLAEnum::CDA cda) const;

  // return a Matrix indicating which if's contributed to which correlations
  // within the specified CDA. The return Matrix always has two columns and the
  // same number of rows as there are correlations. Each row indicates which IF
  // from antennas one & two respectrively contributed to thw correlation. This
  // function encodes the information in Appendix F1 of memo 188.
  Matrix<VLAEnum::IF> ifUsage(VLAEnum::CDA cda) const;

  // Return the subarray ID. This is a number between 1 and 4 indicating which
  // subarray this data corresponds to.
  uInt subArray() const;

  // Return the Array configuration as a string. The string will contain at
  // between one and two characters and be somethings like "A", "D", "AD", etc
  String arrayConfig() const;

  // Return the source RA and Dec at the standard epoch of this integration
  // (given by the epoch function). The returned Vector will always have two
  // elements being the RA and Dec in radians.
  Vector<Double> sourceDir() const;

  // Return the source name as typed in by the observer.
  String sourceName() const;

  // Return the source qualifier as typed in by the observer. This is really
  // the scan number. 
  Int sourceQual() const;

  // Return the integration time in seconds. 
  Double intTime() const;

  // Return the observation time in seconds of the centre of this
  // integration.  Zero seconds means midnight on the day specified win the
  // RCA.
  Double obsTime() const;

  // Return the observation program id.
  String obsId() const;

  // Return the observing mode
  String obsMode() const;

  // Return the observing mode in full glory
  String obsModeFull() const;

  // Return the calibration code.
  String calCode() const;

  // return the reference frame for the field directions.
  MDirection::Types epoch() const;

  // returns whether the data spectrum has been Hanning smoothed (and every
  // second channel discarded). Always returns False for continuum data.
  Bool smoothed() const;

private:
  //# Contains a logical record
  mutable ByteSource itsRecord;
  // the offset to the start of this SDA in the record. An offset of zero means
  // this SDA is not used in this record.
  uInt itsOffset;
};
#endif


