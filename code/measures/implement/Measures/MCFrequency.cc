//# MCFrequency.cc: MFrequency conversion routines 
//# Copyright (C) 1995,1996,1997,1998,2000,2001,2002,2003
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
//# $Id: MCFrequency.cc,v 19.4 2004/11/30 17:50:33 ddebonis Exp $

//# Includes
#include <casa/BasicSL/Constants.h>
#include <measures/Measures/MCFrequency.h>
#include <measures/Measures/MCFrame.h>
#include <casa/Quanta/MVPosition.h>
#include <casa/Quanta/MVDirection.h>
#include <measures/Measures/Aberration.h>
#include <measures/Measures/MeasTable.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Statics
Bool MCFrequency::stateMade_p = False;
uInt MCFrequency::ToRef_p[N_Routes][3] = {
  {MFrequency::LSRD,	MFrequency::BARY,	0},
  {MFrequency::BARY,	MFrequency::LSRD,	0},
  {MFrequency::BARY,	MFrequency::GEO,	0},
  {MFrequency::GEO,	MFrequency::TOPO,	0},
  {MFrequency::GEO,	MFrequency::BARY,	0},
  {MFrequency::TOPO,	MFrequency::GEO,	0},
  {MFrequency::LSRD,	MFrequency::GALACTO,	0},
  {MFrequency::GALACTO,	MFrequency::LSRD,	0},
  {MFrequency::LSRK,	MFrequency::BARY,	0},
  {MFrequency::BARY,	MFrequency::LSRK,	0},
  {MFrequency::BARY,	MFrequency::LGROUP,	0},
  {MFrequency::LGROUP,	MFrequency::BARY,	0},
  {MFrequency::BARY,	MFrequency::CMB,	0},
  {MFrequency::CMB,	MFrequency::BARY,	0},
  {MFrequency::REST,	MFrequency::LSRK,	3},
  {MFrequency::LSRK,	MFrequency::REST,	3} };
uInt MCFrequency::FromTo_p[MFrequency::N_Types][MFrequency::N_Types];


//# Constructors
MCFrequency::MCFrequency() :
  MVPOS1(0), MVDIR1(0), ABERFROM(0), ABERTO(0) {
  if (!stateMade_p) {
    MFrequency::checkMyTypes();
    MCBase::makeState(MCFrequency::stateMade_p, MCFrequency::FromTo_p[0],
		      MFrequency::N_Types, MCFrequency::N_Routes,
		      MCFrequency::ToRef_p);
  };
}

//# Destructor
MCFrequency::~MCFrequency() {
  clearConvert();
}

//# Operators

//# Member functions

void MCFrequency::getConvert(MConvertBase &mc,
			     const MRBase &inref, 
			     const MRBase &outref) {

  Int iin  = inref.getType();
  Int iout = outref.getType();
  Int tmp;
  while (iin != iout) {
    tmp = FromTo_p[iin][iout];
    iin = ToRef_p[tmp][1];
    mc.addMethod(tmp);
    initConvert(tmp, mc);
  };
}

void MCFrequency::clearConvert() {
  delete MVPOS1; MVPOS1 = 0;
  delete MVDIR1; MVDIR1 = 0;
  delete ABERFROM; ABERFROM = 0;
  delete ABERTO; ABERTO = 0;
}

//# Conversion routines
void MCFrequency::initConvert(uInt which, MConvertBase &mc) {

  if (False) initConvert(which, mc);	// Stop warning

  if (!MVPOS1) MVPOS1 = new MVPosition();
  if (!MVDIR1) MVDIR1 = new MVDirection();

  switch (which) {
      
  case BARY_GEO:
    if (ABERFROM) delete ABERFROM;
    ABERFROM = new Aberration(Aberration::STANDARD);
    mc.addFrameType(MeasFrame::EPOCH);
    mc.addFrameType(MeasFrame::DIRECTION);
    break;
      
  case GEO_BARY:
    if (ABERTO) delete ABERTO;
    ABERTO = new Aberration(Aberration::STANDARD);
    mc.addFrameType(MeasFrame::EPOCH);
    mc.addFrameType(MeasFrame::DIRECTION);
    break;

  case LSRD_BARY:
  case BARY_LSRD:
  case LSRD_GALACTO:
  case GALACTO_LSRD:
  case LSRK_BARY:
  case BARY_LSRK:
  case LGROUP_BARY:
  case BARY_LGROUP:
  case CMB_BARY:
  case BARY_CMB:
    mc.addFrameType(MeasFrame::DIRECTION);
    break;

  case GEO_TOPO:
  case TOPO_GEO:
    mc.addFrameType(MeasFrame::EPOCH);
    mc.addFrameType(MeasFrame::DIRECTION);
    mc.addFrameType(MeasFrame::POSITION);
    break;

  case REST_LSRK:
  case LSRK_REST:      
    mc.addFrameType(MeasFrame::DIRECTION);
    mc.addFrameType(MeasFrame::VELOCITY);
    break;

  default:
    break;
  }
}

void MCFrequency::doConvert(MeasValue &in,
			    MRBase &inref,
			    MRBase &outref,
			    const MConvertBase &mc) {
  doConvert(*(MVFrequency*)&in,
	    inref, outref, mc);
}

void MCFrequency::doConvert(MVFrequency &in,
			    MRBase &inref,
			    MRBase &outref,
			    const MConvertBase &mc) {
  Double g1, g2, g3, lengthE, tdbTime;

  MCFrame::make(inref.getFrame());
  MCFrame::make(outref.getFrame());

  for (Int i=0; i<mc.nMethod(); i++) {

    switch (mc.getMethod(i)) {

    case LSRD_BARY: {
      *MVPOS1 = MVPosition(MeasTable::velocityLSR(0));
      ((MCFrame *)(MFrequency::Ref::frameDirection(outref, inref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = (*MVPOS1 * *MVDIR1) / C::c;
      g2 = in.getValue();
      in = g2*sqrt((1+g1)/(1-g1));
    }
    break;

    case BARY_LSRD: {
      *MVPOS1 = MVPosition(MeasTable::velocityLSR(0));
      ((MCFrame *)(MFrequency::Ref::frameDirection(inref, outref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = (*MVPOS1 * *MVDIR1) / C::c;
      g2 = in.getValue();
      in = g2*sqrt((1-g1)/(1+g1));
    }
    break;

    case BARY_GEO: {
      ((MCFrame *)(MFrequency::Ref::frameEpoch(outref, inref).
		   getMCFramePoint()))->
	getTDB(tdbTime);
      *MVPOS1 = ABERFROM->operator()(tdbTime);
      ((MCFrame *)(MFrequency::Ref::frameDirection(outref, inref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = *MVPOS1 * *MVDIR1;
      g2 = in.getValue();
      in = g2*sqrt((1+g1)/(1-g1));
    }	
    break;

    case GEO_TOPO: {
      ((MCFrame *)(MFrequency::Ref::frameEpoch(outref, inref).
		   getMCFramePoint()))->
	getLASTr(g1);
      ((MCFrame *)(MFrequency::Ref::framePosition(outref, inref).
		   getMCFramePoint()))->
	getRadius(lengthE);
      ((MCFrame *)(MFrequency::Ref::frameEpoch(outref, inref).
		   getMCFramePoint()))->
	getTDB(tdbTime);
      ((MCFrame *)(MFrequency::Ref::framePosition(outref, inref).
		   getMCFramePoint()))->
	getLat(g3);
      g2 = MeasTable::diurnalAber(lengthE, tdbTime);
      *MVPOS1 = MVDirection(C::pi_2 + g1, 0.0);
      MVPOS1->readjust(g2 * cos(g3));
      ((MCFrame *)(MFrequency::Ref::frameDirection(outref, inref).
		   getMCFramePoint()))->
	getApp(*MVDIR1);
      g1 = *MVPOS1 * *MVDIR1;
      g2 = in.getValue();
      in = g2*sqrt((1+g1)/(1-g1));
    }
    break;

    case GEO_BARY: {
      ((MCFrame *)(MFrequency::Ref::frameEpoch(inref, outref).
		   getMCFramePoint()))->
	getTDB(tdbTime);
      *MVPOS1 = ABERTO->operator()(tdbTime);
      ((MCFrame *)(MFrequency::Ref::frameDirection(outref, inref).
		   getMCFramePoint()))->
	getApp(*MVDIR1);
      g1 = *MVPOS1 * *MVDIR1;
      g2 = in.getValue();
      in = g2*sqrt((1-g1)/(1+g1));
    }	
    break;

    case TOPO_GEO: {
      ((MCFrame *)(MFrequency::Ref::frameEpoch(inref, outref).
		   getMCFramePoint()))->
	getLASTr(g1);
      ((MCFrame *)(MFrequency::Ref::framePosition(inref, outref).
		   getMCFramePoint()))->
	getRadius(lengthE);
      ((MCFrame *)(MFrequency::Ref::frameEpoch(inref, outref).
		   getMCFramePoint()))->
	getTDB(tdbTime);
      ((MCFrame *)(MFrequency::Ref::framePosition(inref, outref).
		   getMCFramePoint()))->
	getLat(g3);
      g2 = MeasTable::diurnalAber(lengthE, tdbTime);
      *MVPOS1 = MVDirection(C::pi_2 + g1, 0.0);
      MVPOS1->readjust(g2);
      ((MCFrame *)(MFrequency::Ref::frameDirection(outref, inref).
		   getMCFramePoint()))->
	getApp(*MVDIR1);
      g1 = *MVPOS1 * *MVDIR1;
      g2 = in.getValue();
      in = g2*sqrt((1-g1)/(1+g1));
    }
    break;

    case LSRD_GALACTO:
      *MVPOS1 = MVPosition(MeasTable::velocityLSRGal(0));
      ((MCFrame *)(MFrequency::Ref::frameDirection(inref, outref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = (*MVPOS1 * *MVDIR1) / C::c;
      g2 = in.getValue();
      in = g2*sqrt((1-g1)/(1+g1));
      break;
      
    case GALACTO_LSRD:
      *MVPOS1 = MVPosition(MeasTable::velocityLSRGal(0));
      ((MCFrame *)(MFrequency::Ref::frameDirection(outref, inref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = (*MVPOS1 * *MVDIR1) / C::c;
      g2 = in.getValue();
      in = g2*sqrt((1+g1)/(1-g1));
      break;

    case LSRK_BARY:
      *MVPOS1 = MVPosition(MeasTable::velocityLSRK(0));
      ((MCFrame *)(MFrequency::Ref::frameDirection(outref, inref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = (*MVPOS1 * *MVDIR1) / C::c;
      g2 = in.getValue();
      in = g2*sqrt((1+g1)/(1-g1));
      break;

    case BARY_LSRK:
      *MVPOS1 = MVPosition(MeasTable::velocityLSRK(0));
      ((MCFrame *)(MFrequency::Ref::frameDirection(inref, outref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = (*MVPOS1 * *MVDIR1) / C::c;
      g2 = in.getValue();
      in = g2*sqrt((1-g1)/(1+g1));
      break;

    case LGROUP_BARY:
      *MVPOS1 = MVPosition(MeasTable::velocityLGROUP(0));
      ((MCFrame *)(MFrequency::Ref::frameDirection(outref, inref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = (*MVPOS1 * *MVDIR1) / C::c;
      g2 = in.getValue();
      in = g2*sqrt((1+g1)/(1-g1));
      break;

    case BARY_LGROUP:
      *MVPOS1 = MVPosition(MeasTable::velocityLGROUP(0));
      ((MCFrame *)(MFrequency::Ref::frameDirection(inref, outref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = (*MVPOS1 * *MVDIR1) / C::c;
      g2 = in.getValue();
      in = g2*sqrt((1-g1)/(1+g1));
      break;

    case CMB_BARY:
      *MVPOS1 = MVPosition(MeasTable::velocityCMB(0));
      ((MCFrame *)(MFrequency::Ref::frameDirection(outref, inref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = (*MVPOS1 * *MVDIR1) / C::c;
      g2 = in.getValue();
      in = g2*sqrt((1+g1)/(1-g1));
      break;

    case BARY_CMB:
      *MVPOS1 = MVPosition(MeasTable::velocityCMB(0));
      ((MCFrame *)(MFrequency::Ref::frameDirection(inref, outref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 = (*MVPOS1 * *MVDIR1) / C::c;
      g2 = in.getValue();
      in = g2*sqrt((1-g1)/(1+g1));
      break;

    case REST_LSRK:
      ((MCFrame *)(MFrequency::Ref::frameRadialVelocity(inref, outref).
		   getMCFramePoint()))->
	  getLSR(g1);
      ((MCFrame *)(MFrequency::Ref::frameDirection(inref, outref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 /= C::c;
      g2 = in.getValue();
      in = g2*sqrt((1-g1)/(1+g1));
      break;

    case LSRK_REST:
      ((MCFrame *)(MFrequency::Ref::frameRadialVelocity(inref, outref).
		   getMCFramePoint()))->
	getLSR(g1);
      ((MCFrame *)(MFrequency::Ref::frameDirection(inref, outref).
		   getMCFramePoint()))->
	getJ2000(*MVDIR1);
      g1 /= C::c;
      g2 = in.getValue();
      in = g2*sqrt((1+g1)/(1-g1));
      break;

    default:
      break;
    }; // switch
  }; //for
}

String MCFrequency::showState() {
  if (!stateMade_p) {
    MFrequency::checkMyTypes();
    MCBase::makeState(MCFrequency::stateMade_p, MCFrequency::FromTo_p[0],
		      MFrequency::N_Types, MCFrequency::N_Routes,
		      MCFrequency::ToRef_p);
  };
  return MCBase::showState(MCFrequency::stateMade_p, MCFrequency::FromTo_p[0],
			   MFrequency::N_Types, MCFrequency::N_Routes,
			   MCFrequency::ToRef_p);
}

} //# NAMESPACE CASA - END

