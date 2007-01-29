//# PGPlotterGlish.h: Transfer plotting commands to Glish for plotting
//# Copyright (C) 1997,2000,2001
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
//# $Id: PGPlotterGlish.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/PGPlotterGlish.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <tasking/Tasking/ObjectController.h>

#include <casa/Exceptions/Error.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Containers/Record.h>

#include <casa/stdio.h>

namespace casa { //# NAMESPACE CASA - BEGIN

PGPlotterGlish::PGPlotterGlish(const String &name, uInt mincolors, 
			       uInt maxcolors, uInt sizex, uInt sizey)
    : name_p(name), bbuf_p(0), attached_p(False)
{
    String error;
    ObjectController *controller = 
	ApplicationEnvironment::objectController();
    if (controller == 0) {
	error = "no object controller";
    } else {
	attached_p = controller->makePlotterIfNecessary(error, name, mincolors,
							maxcolors, sizex, sizey);
    }
    if (!attached_p) {
	throw(AipsError(String("PGPlotterGlish::PGPlotterGlish error attaching"
			       " to plotter (") + error + ")"));
    }
}

PGPlotterGlish::~PGPlotterGlish()
{
    name_p = "I AM DESTRUCTED";
    bbuf_p = 0;
    GlishValue tmp;
    send(tmp);
}

Bool PGPlotterGlish::isAttached() const
{
    return attached_p;
}

void PGPlotterGlish::message(const String &text)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "message").add("text", text);
    accumulate(tmp);
}

void PGPlotterGlish::resetPlotNumber ()
{
    ok();
    GlishRecord tmp, tmp2;
    tmp.add("_method", "resetplotnumber");
    accumulate(tmp);
    send(tmp2);
}


Record PGPlotterGlish::curs(Float x, Float y)
{
    ok();
    GlishRecord tmp, qret;
    tmp.add("_method", "curs");
    tmp.add("x", x);
    tmp.add("y", y);
    accumulate(qret, tmp);
    Record out;
    qret.toRecord(out);
    return out;
}

void PGPlotterGlish::arro(Float x1, Float y1, Float x2, Float y2)
{
    ok();
    GlishRecord tmp; 
    tmp.add("_method", "arro").add("x1", x1).add("y1", y1).add("x2", x2).
	add("y2", y2);
    accumulate(tmp);
}

void PGPlotterGlish::ask(Bool flag)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "ask").add("flag", flag);
    accumulate(tmp);
}

void PGPlotterGlish::bbuf()
{
    ok();
    GlishRecord tmp;
    bbuf_p++;
    tmp.add("_method", "bbuf");
    accumulate(tmp);
}

void PGPlotterGlish::box(const String &xopt, Float xtick, Int nxsub, 
	     const String &yopt, Float ytick, Int nysub)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "box").
	add("xopt", xopt).add("xtick", xtick).add("nxsub", nxsub).
	add("yopt", yopt).add("ytick", ytick).add("nysub", nysub);
    accumulate(tmp);
}

void PGPlotterGlish::circ(Float xcent, Float ycent, Float radius)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "circ").add("xcent", xcent).add("ycent", ycent).
	add("radius", radius);
    accumulate(tmp);
}

void PGPlotterGlish::draw(Float x, Float y)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "draw").add("x", x).add("y", y);
    accumulate(tmp);
}

void PGPlotterGlish::ebuf()
{
    ok();
    GlishRecord tmp;
    bbuf_p--;
    tmp.add("_method", "ebuf");
    accumulate(tmp);
}

void PGPlotterGlish::env(Float xmin, Float xmax, Float ymin, Float ymax, 
			 Int just, Int axis)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "env").
	add("xmin", xmin).add("xmax", xmax).add("ymin", ymin).add("ymax", ymax).
	add("just", just).add("axis", axis);
    accumulate(tmp);
}

void PGPlotterGlish::eras()
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "eras");
    accumulate(tmp);
}

void PGPlotterGlish::errb(Int dir, const Vector<Float> &x, 
			  const Vector<Float> &y, const Vector<Float> &e, 
			  Float t)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "errb").add("dir", dir).add("x", x).add("y", y).
	add("e", e).add("t", t);
    accumulate(tmp);
}

void PGPlotterGlish::erry(const Vector<Float> &x, const Vector<Float> &y1,
	      const Vector<Float> &y2, Float t)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "erry").add("x", x).add("y1", y1).add("y2", y2).
	add("t", t);
    accumulate(tmp);
}

void PGPlotterGlish::hist(const Vector<Float> &data, Float datmin, 
			  Float datmax, Int nbin, Int pcflag)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "hist").add("data", data).add("datmin", datmin).
	add("datmax", datmax).add("nbin", nbin).add("pcflag", pcflag);
    accumulate(tmp);
}

void PGPlotterGlish::lab(const String &xlbl, const String &ylbl, 
		   const String &toplbl)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "lab").add("xlbl", xlbl).add("ylbl", ylbl).
	add("toplbl", toplbl);
    accumulate(tmp);
}

void PGPlotterGlish::line(const Vector<Float> &xpts, const Vector<Float> &ypts)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "line").add("xpts", xpts).add("ypts", ypts);
    accumulate(tmp);
}

void PGPlotterGlish::move(Float x, Float y)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "move").add("x", x).add("y", y);
    accumulate(tmp);
}

void PGPlotterGlish::mtxt(const String &side, Float disp, Float coord, 
			  Float fjust, const String &text)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "mtxt").add("side", side).add("disp", disp).
	add("coord", coord).add("fjust", fjust).add("text", text);
    accumulate(tmp);
}

void PGPlotterGlish::page()
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "page");
    accumulate(tmp);
}

void PGPlotterGlish::poly(const Vector<Float> &xpts, const Vector<Float> &ypts)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "poly").add("xpts", xpts).add("ypts", ypts);
    accumulate(tmp);
}

void PGPlotterGlish::pt(const Vector<Float> &xpts, const Vector<Float> &ypts, 
		  Int symbol)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "pt").add("xpts", xpts).add("ypts", ypts).
	add("symbol", symbol);
    accumulate(tmp);
}

void PGPlotterGlish::ptxt(Float x, Float y, Float angle, Float fjust, 
		    const String &text)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "ptxt").add("x", x).add("y", y).add("angle", angle).
	add("fjust", fjust).add("text", text);
    accumulate(tmp);
}

Int PGPlotterGlish::qci()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qci");
    accumulate(gret, tmp);
    Int retval; gret.get(retval); return retval;
}

Int PGPlotterGlish::qtbg()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qtbg");
    accumulate(gret, tmp);
    Int retval; gret.get(retval); return retval;
}

Vector<Float> PGPlotterGlish::qtxt(Float x, Float y, Float angle, Float fjust, 
		    const String &text)
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qtxt").add("x", x).add("y", y).add("angle", angle).
	add("fjust", fjust).add("text", text);
    accumulate(gret, tmp);
    Vector<Float> retval; gret.get(retval); return retval;
}

Vector<Float> PGPlotterGlish::qwin()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qwin");
    accumulate(gret, tmp);
    Vector<Float> retval; gret.get(retval); return retval;
}

void PGPlotterGlish::rect(Float x1, Float x2, Float y1, Float y2)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "rect").add("x1", x1).add("x2", x2).add("y1", y1).
	add("y2", y2);
    accumulate(tmp);
}

void PGPlotterGlish::sah(Int fs, Float angle, Float vent)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "sah").add("fs", fs).add("angle", angle).
	add("vent", vent);
    accumulate(tmp);
}

void PGPlotterGlish::save()
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "save");
    accumulate(tmp);
}

void PGPlotterGlish::sch(Float size)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "sch").add("size", size);
    accumulate(tmp);
}

void PGPlotterGlish::sci(Int ci)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "sci").add("ci", ci);
    accumulate(tmp);
}

void PGPlotterGlish::scr(Int ci, Float cr, Float cg, Float cb)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "scr").add("ci", ci).add("cr", cr).add("cg", cg).
	add("cb", cb);
    accumulate(tmp);
}

void PGPlotterGlish::sfs(Int fs)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "sfs").add("fs", fs);
    accumulate(tmp);
}

void PGPlotterGlish::sls(Int ls)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "sls").add("ls", ls);
    accumulate(tmp);
}

void PGPlotterGlish::slw(Int lw)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "slw").add("lw", lw);
    accumulate(tmp);
}

void PGPlotterGlish::stbg(Int tbci)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "stbg").add("tbci", tbci);
    accumulate(tmp);
}

void PGPlotterGlish::subp(Int nxsub, Int nysub)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "subp").add("nxsub", nxsub).add("nysub", nysub);
    accumulate(tmp);
}

void PGPlotterGlish::svp(Float xleft, Float xright, Float ybot, Float ytop)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "svp").add("xleft", xleft).add("xright", xright).
	add("ybot", ybot).add("ytop", ytop);
    accumulate(tmp);
}

void PGPlotterGlish::swin(Float x1, Float x2, Float y1, Float y2)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "swin").add("x1",x1).add("x2",x2).add("y1",y1).
	add("y2",y2);
    accumulate(tmp);
}

void PGPlotterGlish::tbox(const String &xopt, Float xtick, Int nxsub,
		    const String &yopt, Float ytick, Int nysub)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "tbox").add("xopt", xopt).add("xtick", xtick).
	add("nxsub", nxsub).add("yopt", yopt).add("ytick", ytick).
	add("nysub", nysub);
    accumulate(tmp);
}

void PGPlotterGlish::text(Float x, Float y, const String &text)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "text").add("x",x).add("y",y).add("text",text);
    accumulate(tmp);
}

void PGPlotterGlish::unsa()
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "unsa");
    accumulate(tmp);
}

void PGPlotterGlish::updt()
{
}

void PGPlotterGlish::vstd()
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "vstd");
    accumulate(tmp);
}

void PGPlotterGlish::wnad(Float x1, Float x2, Float y1, Float y2)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "wnad").add("x1",x1).add("x2",x2).add("y1",y1).
	add("y2",y2);
    accumulate(tmp);
}

void PGPlotterGlish::conl(const Matrix<Float> &a, Float c,
		      const Vector<Float> &tr, const String &label,
		      Int intval, Int minint)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "conl").add("a", a).add("c", c).add("tr", tr).
	add("label", label).add("intval", intval).add("minint", minint);
    accumulate(tmp);
}

void PGPlotterGlish::cont(const Matrix<Float> &a, const Vector<Float> &c,
		      Bool nc, const Vector<Float> &tr)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "cont").add("a", a).add("c", c).add("nc", nc).
	add("tr", tr);
    accumulate(tmp);
}

void PGPlotterGlish::ctab(const Vector<Float> &l, const Vector<Float> &r,
		      const Vector<Float> &g, const Vector<Float> &b,
		      Float contra, Float bright)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "ctab").add("l", l).add("r", r).add("g", g).add("b", b).
	add("contra", contra).add("bright", bright);
    accumulate(tmp);
}
void PGPlotterGlish::gray(const Matrix<Float> &a, Float fg, Float bg,
		      const Vector<Float> &tr)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "gray").add("a",a).add("fg",fg).add("bg",bg).add("tr",tr);
    accumulate(tmp);
} 

void PGPlotterGlish::iden()
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "iden");
    accumulate(tmp);
}

void PGPlotterGlish::imag(const Matrix<Float> &a, Float a1, Float a2,
		      const Vector<Float> &tr)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "imag").add("a",a).add("a1",a1).add("a2",a2).
	add("tr",tr);
    accumulate(tmp);
}

Vector<Int> PGPlotterGlish::qcir()
{
    ok();
    GlishRecord tmp; GlishArray qret;
    tmp.add("_method", "qcir");
    accumulate(qret, tmp);
    Vector<Int> retval; qret.get(retval);
    return retval;
}

Vector<Int> PGPlotterGlish::qcol()
{
    ok();
    GlishRecord tmp; GlishArray qret;
    tmp.add("_method", "qcol");
    accumulate(qret, tmp);
    Vector<Int> retval; qret.get(retval);
    return retval;
}

void PGPlotterGlish::scir(Int icilo, Int icihi)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "scir").add("icilo",icilo).add("icihi",icihi);
    accumulate(tmp);
}

void PGPlotterGlish::sitf(Int itf)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "sitf").add("itf", itf);
    accumulate(tmp);
}

void PGPlotterGlish::bin(const Vector<Float> &x, const Vector<Float> &data,
		     Bool center)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "bin").add("x",x).add("data",data).add("center",center);
    accumulate(tmp);
}

void PGPlotterGlish::conb(const Matrix<Float> &a, const Vector<Float> &c,
		      const Vector<Float> &tr, Float blank)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "conb").add("a",a).add("c",c).add("tr",tr).
	add("blank",blank);
    accumulate(tmp);
}

void PGPlotterGlish::cons(const Matrix<Float> &a, const Vector<Float> &c,
		      const Vector<Float> &tr)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "cons").add("a",a).add("c",c).add("tr",tr);
    accumulate(tmp);
}

void PGPlotterGlish::errx(const Vector<Float> &x1, const Vector<Float> &x2,
		      const Vector<Float> &y, Float t)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "errx").add("x1",x1).add("x2",x2).add("y",y).add("t",t);
    accumulate(tmp);
}

void PGPlotterGlish::hi2d(const Matrix<Float> &data, const Vector<Float> &x,
		      Int ioff, Float bias, Bool center, 
		      const Vector<Float> &ylims)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "hi2d").add("data",data).add("x",x).add("ioff",ioff).
	add("bias",bias).add("center",center).add("ylims",ylims);
    accumulate(tmp);
}

void PGPlotterGlish::ldev()
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "ldev");
    accumulate(tmp);
}

Vector<Float> PGPlotterGlish::len(Int units, const String &string)
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "len").add("units",units).add("string",string);
    accumulate(tmp, gret);
    Vector<Float> retval;
    gret.get(retval);
    return retval;
}

String PGPlotterGlish::numb(Int mm, Int pp, Int form)
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "numb").add("mm",mm).add("pp",pp).add("form",form);
    accumulate(tmp, gret);
    String retval;
    gret.get(retval);
    return retval;
}

void PGPlotterGlish::panl(Int ix, Int iy)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "panl").add("ix",ix).add("iy",iy);
    accumulate(tmp);
}

void PGPlotterGlish::pap(Float width, Float aspect)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "pap").add("width",width).add("aspect",aspect);
    accumulate(tmp);
}

void PGPlotterGlish::pixl(const Matrix<Int> &ia, Float x1, Float x2,
		      Float y1, Float y2)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "pixl").add("ia",ia).add("x1",x1).add("x2",x2).
	add("y1",y1).add("y2",y2);
    accumulate(tmp);
}

void PGPlotterGlish::pnts(const Vector<Float> &x, const Vector<Float> &y,
		      const Vector<Int> symbol)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "pnts").add("x",x).add("y",y).add("symbol",symbol);
    accumulate(tmp);
}

Vector<Float>  PGPlotterGlish::qah()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qah");
    accumulate(tmp, gret);
    Vector<Float> retval;
    gret.get(retval);
    return retval;
}

Int PGPlotterGlish::qcf()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qcf");
    accumulate(tmp, gret);
    Int retval;
    gret.get(retval);
    return retval;
}

Float PGPlotterGlish::qch()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qch");
    accumulate(tmp, gret);
    Float retval;
    gret.get(retval);
    return retval;
}

Vector<Float> PGPlotterGlish::qcr(Int ci)
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qcr").add("ci",ci);
    accumulate(tmp, gret);
    Vector<Float> retval;
    gret.get(retval);
    return retval;
}

Vector<Float> PGPlotterGlish::qcs(Int units)
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qcs").add("units",units);
    accumulate(tmp, gret);
    Vector<Float> retval;
    gret.get(retval);
    return retval;
}

Int PGPlotterGlish::qfs()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qfs");
    accumulate(tmp, gret);
    Int retval;
    gret.get(retval);
    return retval;
}

Vector<Float> PGPlotterGlish::qhs()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qhs");
    accumulate(tmp, gret);
    Vector<Float> retval;
    gret.get(retval);
    return retval;
}

Int PGPlotterGlish::qid()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qid");
    accumulate(tmp, gret);
    Int retval;
    gret.get(retval);
    return retval;
}

String PGPlotterGlish::qinf(const String &item)
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qinf").add("item",item);
    accumulate(tmp, gret);
    String retval;
    gret.get(retval);
    return retval;
}

Int PGPlotterGlish::qitf()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qitf");
    accumulate(tmp, gret);
    Int retval;
    gret.get(retval);
    return retval;
}

Int PGPlotterGlish::qls()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qls");
    accumulate(tmp, gret);
    Int retval;
    gret.get(retval);
    return retval;
}

Int PGPlotterGlish::qlw()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qlw");
    accumulate(tmp, gret);
    Int retval;
    gret.get(retval);
    return retval;
}

Vector<Float> PGPlotterGlish::qpos()
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qpos");
    accumulate(tmp, gret);
    Vector<Float> retval;
    gret.get(retval);
    return retval;
}

Vector<Float> PGPlotterGlish::qvp(Int units)
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qvp").add("units",units);
    accumulate(tmp, gret);
    Vector<Float> retval;
    gret.get(retval);
    return retval;
}

Vector<Float> PGPlotterGlish::qvsz(Int units)
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "qvsz").add("units",units);
    accumulate(tmp, gret);
    Vector<Float> retval;
    gret.get(retval);
    return retval;
}

Float PGPlotterGlish::rnd(Float x, Int nsub)
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "rnd").add("x",x).add("nsub",nsub);
    accumulate(tmp, gret);
    Float retval;
    gret.get(retval);
    return retval;
}

Vector<Float> PGPlotterGlish::rnge(Float x1, Float x2)
{
    ok();
    GlishRecord tmp; GlishArray gret;
    tmp.add("_method", "rnge").add("x1",x1).add("x2",x2);
    accumulate(tmp, gret);
    Vector<Float> retval;
    gret.get(retval);
    return retval;
}

void PGPlotterGlish::scf(Int font)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "scf").add("font",font);
    accumulate(tmp);
}

void PGPlotterGlish::scrn(Int ci, const String &name)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "scrn").add("ci",ci).add("name",name);
    accumulate(tmp);
}

void PGPlotterGlish::shls(Int ci, Float ch, Float cl, Float cs)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "shls").add("ci",ci).add("ch",ch).add("cl",cl).
	add("cs",cs);
    accumulate(tmp);
}

void PGPlotterGlish::shs(Float angle, Float sepn, Float phase)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "shs").add("angle",angle).add("sepn",sepn).
	add("phase",phase);
    accumulate(tmp);
}

void PGPlotterGlish::vect(const Matrix<Float> &a, const Matrix<Float> &b,
		      Float c, Int nc, 
		      const Vector<Float> &tr, Float blank)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "vect").add("a",a).add("b",b).add("c",c).add("nc",nc).
	add("tr",tr).add("blank",blank);
    accumulate(tmp);
}

void PGPlotterGlish::vsiz(Float xleft, Float xright, Float ybot,
		      Float ytop)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "vsiz").add("xleft",xleft).add("xright",xright).
	add("ybot",ybot).add("ytop",ytop);
    accumulate(tmp);
}

void PGPlotterGlish::wedg(const String &side, Float disp, Float width,
		      Float fg, Float bg, const String &label)
{
    ok();
    GlishRecord tmp;
    tmp.add("_method", "wedg").add("side",side).add("disp",disp).
	add("width",width).add("fg",fg).add("bg",bg).add("label",label);
    accumulate(tmp);
}

uInt PGPlotterGlish::count()
{
    return accumulated_p.nelements();
}

void PGPlotterGlish::accumulate(const GlishRecord &plotcommand)
{
    int n = count()+1;
    char buf[10];
    sprintf(&buf[0], "*%d", n);
    accumulated_p.add(buf, plotcommand);
    if (bbuf_p <= 0) {
	GlishValue out;
	send(out);
	bbuf_p = 0;
    }
}

void PGPlotterGlish::accumulate(GlishValue &out, const GlishRecord &plotcommand)
{
    int n = count()+1;
    char buf[10];
    sprintf(&buf[0], "*%d", n);
    accumulated_p.add(buf, plotcommand);
    if (bbuf_p <= 0) {
	send(out);
	bbuf_p = 0;
    }
}

void PGPlotterGlish::send(GlishValue &out)
{
    ok();
    if (count() > 0) {
	ObjectController *controller = 
	    ApplicationEnvironment::objectController();
	if (controller == 0) {
	    throw(AipsError("PGPlotterGlish::send - no object controller!"));
	}
	String error;
	attached_p = controller->sendPlotCommands(error, out, name_p, 
					       accumulated_p);
	GlishRecord empty;
	accumulated_p = empty;
	if (!attached_p) {
	    throw(AipsError(String("PGPlotterGlish::send - Not attached (") + 
			    error + ")"));
	}
    }
}

void PGPlotterGlish::ok()
{
    if (!attached_p) {
	throw(AipsError("PGPlotterGlish - attempt to plot a command to"
			" with no plotter"));
    }
}

} //# NAMESPACE CASA - END

