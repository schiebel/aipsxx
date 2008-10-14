# iono_plot.g: Plotting utilities for ionosphere-related stuff
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
#   $Id: iono_plot.g,v 19.2 2004/08/25 01:21:51 cvsmgr Exp $

pragma include once

#
# iono_plot(pgplot options[,frame][,pgplot agent])
#
# Constructs an ionoplotter. Several forms are available:
#
# To use an existing PGPlot agent:
#   iono_plot(pg);                
# To create a new frame & agent:   
#   iono_plot([pgplot_options]); 
# To create a new agent and open a device file:
#   iono_plot([pgplot_options,] open=filename);
# To create a new agent attached to an existing frame: 
#   iono_plot([pgplot_options,] frm=frm);  
#
const iono_plot := function (...,open=F,ref frm=F)  
{
  public := [=];
  pg := F;
  if( num_args(...) )
    pg := nth_arg(1,...);
  # use existing agent
  if( is_agent(pg) )
  {
    const public.pg := ref pg;
  }
  # else construct agent
  else 
  {
    if( is_boolean(frm) )
      frm := frame();
    const public.frame := ref frm;
    const public.pg := pgplot(frm,...);
    if( is_string(open) )
      public.pg->open(open);
  }
    
# Returns reference to pgplot agent
  const public.pgp := function ()
  {
    wider public;
    return ref public.pg;
  }

# singleplot(x,y[,ls][,sym][,ci])
#   Plots a single x-y line and/or symbol plot
#   ls=F for no lines, sym=F for no symbols
#   domain may be set to an int array of domain indices 
#   that is the same size as x and y; in this case disjoint lines are 
#   drawn for different domains
  const public.singleplot := function(x,y,ls=F,sym=F,ci=1,domain=[])
  {
    wider public;
    public.pg->sci(ci);
    if( !is_boolean(sym) )
      public.pg->pt(x,y,sym);
    if( !is_boolean(ls) )
    {
      public.pg->sls(ls);
      if( len(domain)<1 )
        public.pg->line(x,y);
      else
        for( dom in min(domain):max(domain) )
        {
          mask := domain==dom;
          public.pg->line(x[mask],y[mask]);
        }
      public.pg->sls(1);
    }
    public.pg->sci(1);
    return T;
  }
# multiplot(x,y[,ls][,sym][,ci]) 
#   plots x-y[1..M] line and/or point plots, possibly using different
#   linestyles/symbols/colors
  # x    is an [N] vector 
  # y    is an [N,M] matrix (or [N] vector, for a single plot)
  # ls   is a linestyle, or F for no line, or an [M] vector of styles
  # sym  is a symbol #, or F for no symbols, or an [M] vector of symbol #s
  # ci   is a color index, or an [M] vector of such
  const public.multiplot := function(x,y,ls=F,sym=F,ci=1,domain=[])
  {
    wider public;
    if( len(y::shape) == 1 )
      return public.singleplot(x,y,ls,sym,ci,domain);
    else
      for( i in 1:len(y[1,]) )
        public.singleplot(x,y[,i],
              ls[min(i,len(ls))],sym[min(i,len(sym))],
              ci[min(i,len(ci))],domain);
    return T;
  }
# duoplot(...)
  # Universal function for plotting a dual plot (one X axis, two Y axis)
  # This function is mainly intended to be called from other plotting funcs. 
  const public.duoplot := function(x,xlab,y1,y1r,y1lab,y1ls,y1sym,y1ci,
                                   y2,y2r,y2lab,y2ls,y2sym,y2ci,tlab,grid,domain=[])
  {
    wider public;
    wider public;
    # compute X and Y ranges
    local xr := range(x);
    if( is_boolean(y1r) )
      y1r := range(y1);
    if( is_boolean(y2r) )
      y2r := range(y2);
    # environment for X and Y1
    public.pg->env(xr[1],xr[2],y1r[1],y1r[2],0,-2);
    # X axis
    xopt := "BCNST BCGNST";  # options selected by grid argument
    public.pg->sci(1);
    public.pg->box(xopt[grid+1],0,0,'',0,0);
    public.pg->lab(xlab,'',tlab);
    # Y1 axis
    yopt := "BNST BGNST";  # options selected by grid argument
    public.pg->sci(y1ci[1]);
    public.pg->box('',0,0,yopt[grid+1],0,0);
    public.pg->lab('',y1lab,'');
    public.multiplot(x,y1,y1ls,y1sym,y1ci,domain=domain);
    # Y2 axis
    public.pg->swin(xr[1],xr[2],y2r[1],y2r[2]);
    public.pg->sci(y2ci[1]);
    public.pg->box('',0,0,'CMST',0,0);
    public.pg->mtxt('R',2.5,.5,.5,y2lab);
    public.multiplot(x,y2,y2ls,y2sym,y2ci,domain=domain);
    # label
    public.pg->sls(1);
    return T;
  }
  #
# azel()
#   Produces time-azimuth-elevation plot
#   Default az/el range is full sky, but you can override this via
#   the azrange/elrange parameters. Set them to 'F' to have the ranges
#   computed from the supplied.
  const public.azel := function (x,az,el,azrange=[-180,180],elrange=[0,90],
                                 azls=2,azci=3,azsym=F,
                                 ells=1,elci=1,elsym=F,
                                 tlab='',xlab='Hours UTC',grid=F,domain=[])
  {
    wider public;
    return public.duoplot(x,xlab,
                   el,[0,90],'Elevation, deg.',ells,elsym,elci,
                   az,[-180,180],'Azimuth, deg.',azls,azsym,azci,
                   tlab,grid=grid,domain=domain);
                   
  }
# frtec()
#   Produces time-FR-TEC plot
  const public.frtec := function (x,fr,tec,
                                  frrange=F,tecrange=F,
                                  frls=1,frci=1,frsym=F,
                                  tecls=4,tecci=3,tecsym=F,
                                  tlab='',xlab='Hours UTC',grid=F,domain=[])
  {
    wider public;
    return public.duoplot(x,xlab,
                   fr,frrange,'Faraday rotation, deg.',frls,frsym,frci,
                   tec,tecrange,'TEC',tecls,tecsym,tecci,
                   tlab,grid=grid,domain=domain);
  }
# bparalt()
#   Produces time-Bpar-Altitude plot
  const public.bparalt := function (x,b,alt,
                                    brange=F,altrange=F,
                                    bls=1,bci=1,bsym=F,
                                    altls=4,altci=3,altsym=F,
                                    tlab='',xlab='Hours UTC',grid=F,domain=[])
  {
    wider public;
    return public.duoplot(x,xlab,
                   b,brange,'Bpar, Gauss',bls,bsym,bci,
                   alt,altrange,'Altitude, km',altls,altsym,altci,
                   tlab,grid=grid,domain=domain);
  }
# bpartec()
#   Produces time-Bpar-TEC plot
  const public.bpartec := function (x,b,tec,
                                    brange=F,tecrange=F,
                                    bls=1,bci=1,bsym=F,
                                    tecls=4,tecci=3,tecsym=F,
                                    tlab='',xlab='Hours UTC',grid=F,domain=[])
  {
    wider public;
    return public.duoplot(x,xlab,
                   b,brange,'Bpar, Gauss',bls,bsym,bci,
                   tec,tecrange,'TEC',tecls,tecsym,tecci,
                   tlab,grid=grid,domain=domain);
  }
# bparmaxalt()
#   Produces time-Bpar-Alt_of_max_EDP plot
#   B and EDP are two [NALT,NP] arrays
#   ALT is an [NALT] vector
#
  const public.bparmaxalt := function (x,b,alt,edp,
                                    bls=1,bci=1,bsym=F,
                                    altls=4,altci=3,altsym=F,
                                    tlab='',xlab='Hours UTC',grid=F,domain=[])
  {
    wider public;
    local nalt := edp::shape[1];
    local np := edp::shape[2];
    local bmax := array(0.0,np);
    local altmax := bmax;
    for( i in 1:np )
    {
      mask := ( edp[,i] == max(edp[,i]) );
      bmax[i] := sum(b[mask,i])/len(mask);
      if( len(alt::shape)>1 )
        altmax[i] := sum(alt[mask,i])/sum(mask);
      else
        altmax[i] := sum(alt[mask])/sum(mask);
    }    
    return public.duoplot(pg,x,xlab,
                   bmax,F,'Bpar at max ED, Gauss',bls,bsym,bci,
                   altmax,F,'Altitude of max ED, km',altls,altsym,altci,
                   tlab,grid=grid,domain=domain);
  }
# edpalt()
# Produces EDP-altitude (i.e. ED profile), plus optionally Bpar plot,
# plus optionally EDP*Bpar
#   ALT is [N] vector
#   EDP is [N,M] array
#   BPAR is an [N] vector, of F for none
#   ALTRANGE is akltitude range (default 0-1000 km), or F/T for full
  const public.edpalt := function (edp,alt,bpar=F,
                                   edpls=1,edpci=F,edpsym=F,
                                   bls=1,bci=F,bsym=F,
                                   altrange=[0,1000],
                                   altlab='Altitude, km.',
                                   prodls=F,prodci=F,prodsym=F,
                                   tlab='')
  {
    wider public;
    wider public;
    # determine number of profiles to plot
    if( len(shape(edp))<2 )
    {
      edp::shape := [len(edp),1];
      nprof := 1;
    }
    else
      nprof := edp::shape[2];
    # altitude range & mask of valid stuff
    if( is_boolean(altrange) )
    {
      altrange := range(alt);
      mask := array(T,len(alt));
    }
    else
      mask := (alt>=altrange[1] && alt<=altrange[2]);
    # by default, use sequential ci's for EDPs and Bpar
    if( is_boolean(edpci) )
      edpci := 1:nprof;
    # set up for drawing profiles
    public.pg->env(min(edp[mask,]),max(edp[mask,]),altrange[1],altrange[2],0,-2);
    # draw EDP and Alt axis
    #    if no Bpar, then complete box, else no top axis
    local xopt := 'BNST';
    if( is_boolean(bpar) )
      xopt := 'BCNST';
    public.pg->sci(1);
    public.pg->box(xopt,0,0,'BCNST',0,0);
    public.pg->lab('Electron density, TECU/cm^2',altlab,tlab);
    for( i in 1:nprof )
      public.singleplot(edp[mask,i],alt[mask],
            edpls[min(i,len(edpls))],edpsym[min(i,len(edpsym))],
            edpci[min(i,len(edpci))]);
    # have Bpar? Plot it then
    if( !is_boolean(bpar) )
    {
      if( is_boolean(bci) )
        bci := max(edpci)+1;
      public.pg->sci(bci);
      public.pg->swin(min(bpar[mask]),max(bpar[mask]),altrange[1],altrange[2]);
      public.pg->box('CMST',0,0,'',0,0);
      cs := ip.pg->qcs(4);
      public.pg->ptxt(max(bpar[mask]),altrange[2]-cs[2],0,1,'Bpar, Gauss ');
      public.singleplot(bpar[mask],alt[mask],bls,bsym,bci);
      # should the product be plotted as well?
      if( !is_boolean(prodci) || !is_boolean(prodls) || !is_boolean(prodsym) )
      {
        # compute product of EDP(i)*Bpar
        product := edp[mask,]*array(bpar[mask],sum(mask),nprof);
        prange := range(product);
        public.pg->swin(prange[1],prange[2],altrange[1],altrange[2]);
        # copy unset linestyles/symbols from EDP
        if( is_boolean(prodci) )
          prodci := edpci;
        if( is_boolean(prodls) )
          prodls := edpls;
        if( is_boolean(prodsym) )
          prodsym := edpsym;
        # plot products
        for( i in 1:nprof )
          public.singleplot(product[,i],alt[mask],
                prodls[min(i,len(prodls))],prodsym[min(i,len(prodsym))],
                prodci[min(i,len(prodci))]);
      }
      
    }
    return T;
  }
  
  
  return public; 
} # end of iono_plot constructor
