// NTDCoordinates.cc: implementation of NTD Coordinates
//
//  Copyright (C) 2005, 2006
//# Associated Universities, Inc. Washington DC, USA.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//
//
//////////////////////////////////////////////////////////////////////
#include "NTDCoordinates.h"

using namespace casa;

// Methods of NTDCoordinates class
// The constructor
NTDCoordinates::NTDCoordinates()
{
   // Measured by TJC from Google Earth
   itsWestVPos=MVPosition(Quantity(87, "m"),
			  Quantity(151.09735, "deg"),
			  Quantity(-33.774201, "deg"));
   itsWestPos=MPosition(itsWestVPos, MPosition::WGS84);

   // We'll need to convert to ITRF
   MPosition::Convert toITRF(itsWestPos, MPosition::ITRF);
   itsWestPos=toITRF(itsWestPos);
   itsWestVPos=itsWestPos.getValue();

   itsEastVPos=MVPosition(Quantity(87, "m"),
			  Quantity(151.09825, "deg"),
			  Quantity(-33.774784, "deg"));
   itsEastPos=MPosition(itsEastVPos, MPosition::WGS84);
   itsEastPos=toITRF(itsEastPos);
   itsEastVPos=itsEastPos.getValue();

   //   cout << "Eastern antenna at " << itsEastPos << " (ITRF)" << endl;
   //   cout << "Western antenna at " << itsWestPos << " (ITRF)" << endl;

   // Now we can calculate the baseline in ITRF
   itsVBaseline=MVBaseline(itsEastVPos, itsWestVPos);
   //   cout << "Baseline is " << itsVBaseline << endl;
}

// The destructor
NTDCoordinates::~NTDCoordinates() {
}

// Use the internally known antenna locations
// to calculate the uvw for a given source direction
// at a given Epoch
MDirection NTDCoordinates::calcAzEl(MEpoch& epoch, MDirection& source) {
  MeasFrame mf(epoch, source, itsEastPos);
  MDirection::Ref from(MDirection::J2000, mf);
  MDirection::Ref to(MDirection::AZEL, mf);
  MDirection::Convert dirConv(from, to);
  MDirection azel(dirConv(source));
  return azel;
}

// Use the internally known antenna locations
// to calculate the uvw for a given source direction
// at a given Epoch
Muvw NTDCoordinates::calcUVW(MEpoch& epoch, MDirection& source) {
  MeasFrame mf(epoch, itsEastPos);
  MDirection haDec(MDirection::HADEC);
  {
    MDirection::Ref dirRef(MDirection::HADEC, mf);
    MDirection::Convert toHaDec(source, dirRef);
    haDec=toHaDec(source);
  }
  Muvw muvw(MVuvw(itsVBaseline, haDec.getValue()), Muvw::J2000);
  return muvw;
}

MPosition NTDCoordinates::getEast() {
  return itsEastPos;
}

MPosition NTDCoordinates::getWest() {
  return itsWestPos;
}
