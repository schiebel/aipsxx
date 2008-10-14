# mydish_standard.gp
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1998,1999,2000,2001,2002,2003
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
#    $Id: mydish_standard.gp,v 19.8 2006/09/06 19:22:50 bgarwood Exp $
#
#------------------------------------------------------------------------------
#test case
pragma include once;
include 'dishgmeasure.g';
include 'sdaverager.g';

mydish_standard := [=];

mydish_standard.attach := function (ref public) {

private := [=];
private.averager := F;

if (!has_field(public.unirec,'astack')) {
 public.uniput('astack',F)
 public.uniput('acount',0)
 public.uniput('edrop',0)
 public.uniput('bdrop',0)
 public.uniput('echan',0)
 public.uniput('bchan',0)
 public.uniput('emoment',0)
 public.uniput('bmoment',0)
 public.uniput('numaccum',0)
 public.uniput('nfit',0);
 public.uniput('vref',F);
 public.uniput('vsig',F);
 public.uniput('globalscan1',F);
 public.uniput('nregion','[1,100000]')
 public.uniput('nregionArr',[1,100000])
 }


        #new function
	public.clip := function(cliplevel,channelrange=F,clipdir='high') {
		wider public;
		#flags as bad anything in range
                print 'Clipping spectrum at ',cliplevel;
                a:=public.rm().getlastviewed()
                #get indices of where need to clip
		if (clipdir=='high'){
                   myflag:=a.value.data.arr>cliplevel
		} else {
		   myflag:=a.value.data.arr<cliplevel
		};
                if (!is_boolean(channelrange)) {
		tmp:=array(F,myflag::shape[1],len(channelrange))
		   for (i in 1:myflag::shape[1]) {
                        tmp[i,]:=myflag[i,channelrange];
		   }
                        a.value.data.flag[,channelrange]:=
				a.value.data.flag[,channelrange] | tmp;
                } else {
                        a.value.data.flag:=a.value.data.flag | myflag;
                }
                public.rm().add(a.name,a.description,a.value,type="SDRECORD");
                rmsize:=public.rm().size();
                public.rm().select(rmsize);
                return;
}

#		keep this vestige of the old spline interp version
#		indices:=ind(a.value.data.arr[1,])[myflag]
#		interp:=interpolate1d();
#		x:=(1:len(a.value.data.arr[1,]))[!myflag];
#		y:=(a.value.data.arr[1,])[!myflag];	
#		interp.initialize(x,y,'spline');
#		newvals:=interp.interpolate(indices);
#		for (i in 1:len(indices)) {
#			a.value.data.arr[indices[i]]:=newvals[i];
#		}

# other functions go here
#	public.otherfunction := function(input1,input2,etc) {
#              some code goes here to do something
#              return; # can return a value too if you like
#       }
#	public.etc...
#

## lsoutfile Description: List scans in the outfile
##           Example:     lsoutfile();
##                        [1 2]
##           Returns:     a list of scans
##           Produces:    a vector of scan numbers
public.lsoutfile := function() {
    filenames := public.files(T)
    ws := symbol_value(filenames.fileout)
    if (is_sditerator(ws)) {
       scannums:=ws.getheadervector('scan_number')[1];
       return unique(scannums);
       }
    else {
       dl.log(message='Bad selection: no fileout is specified or the outfile is empty.', priority='SEVERE',postcli=T);
       return F
       }
}

public.gsget := function() {
 wider public
 r := public.uniget('globalscan1')
 if (is_sdrecord(r)) return r
 else {
   dl.log(message='No record currently available in globalscan1',priority='SEVERE',postcli=T)
   return F
   }
}

public.gsput := function(sdrec) {
 wider public
 if (is_sdrecord(sdrec)) {
   public.uniput('globalscan1',sdrec);
   return T
   }
 else {
  dl.log(message='Not an appropriate record.',priority='SEVERE',postcli=T)
  return F
  }
}

public.fold := function(scan,flipit=F,flipfold=F) {
 wider public;
# temporary since there is no indication of the frequency switch
  tmp1:=public.getscan(scan,1);
  tmp2:=public.getscan(scan,3);
  switch:=abs(tmp1.data.desc.chan_freq.value[1]-
                tmp2.data.desc.chan_freq.value[1]);
  res:=tmp1.header.resolution;
  switch_chan:=switch/res;
  public.getfs(scan,flipsigref=flipit)
  a_sig:=public.uniget('globalscan1')
  shp:=a_sig.data.arr::shape;
  public.getfs(scan,flipsigref=!flipit)
  a_ref:=public.uniget('globalscan1')
  a_avg:=array(0,shp[1],shp[2])
#  a_avg:=a_sig.data.arr;
  if (!flipfold) {
        startch:=1;
        endch:=switch_chan-1;
        flipch:=switch_chan;
        flagst:=flipch+1;
        flagen:=shp[2];
  } else {
        startch:=switch_chan+1;
        endch:=shp[2];
        flipch:=-switch_chan;
        flagst:=startch+flipch;
        flagen:=endch+flipch;
  };

  a_avg[,startch:endch] := (a_sig.data.arr[,startch:endch]+
                a_ref.data.arr[,(startch+flipch):(endch+flipch)])/2

  a_sig.data.arr:=a_avg
#  a_sig.data.flag[,flagst:flagen]:=T;
  public.uniput('globalscan1',a_sig);
  return T;
}

public.galactic := function(quiet=F) {
 wider public
 dq.setformat('long','+deg')
 dq.setformat('lat','deg')
 gl := public.uniget('globalscan1');
 if (!is_sdrecord(gl)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 dm.doframe(gl.header.time)
 dm.doframe(dm.observatory('GBT'))
 position := gl.header.direction
 gal := dm.measure(position,'GALACTIC')
 galrec.lon := gal.m0.value*180/pi
 galrec.lat := gal.m1.value*180/pi
 if (galrec.lon < 0) galrec.lon := galrec.lon+360
 if (quiet)
  return galrec
 else
  print dm.dirshow(gal)
 return T
}

public.avgFeeds := function() {
 wider public
 dl.log(message='This function is now called avgpols.  Use that name instead.',postcli=T,priority='NORMAL')
 public.avgpols()
}

public.avgpols := function() {
 wider public
  Ta := public.uniget('globalscan1');
 if (!is_sdrecord(Ta)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 sum := F
 for (i in 1:Ta.data.arr::shape[1]) sum +:= Ta.data.arr[i,]
 Ta.data.arr[1,] := sum/Ta.data.arr::shape[1]
 if (Ta.data.arr::shape[1] > 1) {
     Ta.data.desc.corr_type:=spaste(Ta.data.desc.corr_type[1],',',
                        Ta.data.desc.corr_type[2])
  };
  x:=public.getpol(Ta,1);
  public.uniput('globalscan1',x);
 return T
}

public.getvf := function(chan,dop='RADIO',refframe='LSRK') {
 wider public
 gs1 := public.gsget()
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 max := len(gs1.data.arr[1,])
 if (!is_integer(chan)) {
  dl.log(message='Channel number must be an integer.',priority='SEVERE',postcli=T)
  return F
  }
 if (chan<1 || chan>max) {
  dl.log(message='Channel out of range.',priority='SEVERE',postcli=T)
  return F
  }
 vfarr := public.getvfarray(dop,refframe)
 print 'Channel ',chan,'   ',dop,refframe,vfarr.f[chan],vfarr.v[chan]
 return T
}

public.getvfarray := function(dop='RADIO',refframe='LSRK') {
 wider public
 if (!any(dop==['RADIO','OPTICAL','TRUE'])) {
   dl.log(message='dop must be RADIO, OPTICAL or TRUE',priority='SEVERE',postcli=T)
   return F
   }
 if (!any(refframe==['LSRK','BARY','LSRD','GEO','TOPO','GALACTO'])) {
   dl.log(message='refframe must be LSRK, LSRD, BARY, GEO, TOPO or GALACTO',priority='SEVERE',postcli=T)
   return F
   }
 ret := [=]
 gs1 := public.gsget()
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 ret.doppler:=dop
 ret.refframe:=refframe
 freq.type := 'frequency'
 freq.refer := public.plotter.csys.conversiontype('spectral')
 freq.m0 := gs1.data.desc.chan_freq
 dm.doframe(gs1.header.direction)
 freqarr := dm.measure(freq,refframe)
 ret.v := public.plotter.csys.ftv(freqarr.m0.value,doppler=dop)
 ret.f := freqarr.m0.value
 return ret
}

public.writeascii := function(file,dop=F,refframe=F) {
    wider public;
    if (!is_string(file)) {
	dl.log(message='Enter a string for file name',priority='SEVERE',postcli=T);
	return F;
    }
    if (is_boolean(dop))
	dop := to_upper(public.plotter.ips.getdoppler());
    if (is_boolean(refframe))
	refframe := to_upper(public.plotter.csys.conversiontype('spectral'));
    yval := public.gsget().data.arr;
    npols := yval::shape[1];
    nchans := yval::shape[2];
    if (any(public.plotter.ips.getabcissaunit()==['GHz','MHz','kHz','Hz']))
	xval := public.getvfarray(dop,refframe).f;
    else if (any(public.plotter.ips.getabcissaunit()==['km/s','m/s']))
	xval := public.getvfarray(dop,refframe).v;
    else
	xval := 1:nchans;
    file_id := open(spaste('> ',file));
    fprintf(file_id,'%s    %s\n',dop,refframe);
    for (i in 1:nchans) {
	fprintf(file_id,'%12.2f ',xval[i]);
	for (j in 1:npols) 
	    fprintf(file_id,'%12.6f ',yval[j,i]);
	fprintf(file_id,'\n');
    }
    return T;
}

public.gswrite := function(file) {
 gs1 := public.uniget('globalscan1');
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 if (!is_string(file)) {
  dl.log(message='file must be a string',priority='SEVERE',postcli=T)
  return F
 }
 if (dos.fileexists(file))
  dl.log(message='That file exists and will be overwritten',priority='SEVERE',postcli=T)
 write_value(gs1,file)
 dl.log(message=spaste('globalscan saved to ',file),priority='NORMAL',postcli=T)
}

public.gsread := function(file) {
 wider public
 if (!is_string(file)) {
  dl.log(message='file must be a string',priority='SEVERE',postcli=T)
  return F
 }
 if (!dos.fileexists(file)) {
  dl.log(message='file does not exist',priority='SEVERE',postcli=T)
  return F
 }
 public.uniput('globalscan1',read_value(file))
 dl.log(message=spaste('globalscan retrieved from ',file),priority='NORMAL',postcli=T)
}

public.accum := function(scans=F, nif=F) {
    wider public, private;
    if (is_boolean(scans)) private.accumgs();
    else
	for (i in scans) {
	    ok := d.getc(i, nif=nif);
	    if (is_boolean(ok)) return F;
	    ok := private.accumgs();
	    if (!ok) return F;
	}
    return T;
}

private.accumgs := function() {
    wider public, private;
    gl := public.uniget('globalscan1');
    if (!is_sdrecord(gl)) {
	dl.log(message='No globalscan available.',priority='SEVERE',postcli=T);
	return F;
    }
    if (is_boolean(private.averager)) {
	private.averager := sdaverager();
	private.averager.setweighting('TSYS');
	# all other defaults are okay - no alignment
    }
    public.uniput('numaccum',public.uniget('numaccum')+1);
    # replace any NaNs with 0s and make sure flag is also set there
    # average does not cope well with NaNs, even if already flagged
    npol := gl.data.arr::shape[1];
    for (i in 1:npol) {
	glnans := is_nan(gl.data.arr[i,]);
	if (sum(glnans) > 0) {
	    gl.data.arr[i,glnans] := as_float(0.0);
	    gl.data.weight[i,glnans] := as_float(0.0);
	    gl.data.flag[i,glnans] := T;
	}
    }
    return private.averager.accumulate(gl)
}

public.sclear := function() {
    wider public,private;
    result := T;
    if (!is_boolean(private.averager)) result := private.averager.clear();
    public.uniput('numaccum',0);
    dl.log(message='Accumulator cleared',priority='NORMAL',postcli=T);
    return result;
}

public.ave := function(sclear=T) {
    wider public,private;
    result := T;
    if (public.uniget('numaccum')>0) {
	ac := public.uniget('globalscan1');
	result := private.averager.average(ac);
	if (!result) {
	    dl.log(message='There was an unexpected problem with the average, can not continue',
		   priority='SEVERE',postcli=T);
	} else {
	    public.uniput('globalscan1',ac);
	    dl.log(message=spaste('Averaged ',public.uniget('numaccum'),' records'),
		   priority='NORMAL',postcli=T);
	    if (sclear) public.sclear();
	}
    } else {
        dl.log(message='Nothing to average',priority='SEVERE',postcli=T);
    }
    return result;
}

public.stats := function(quiet=F,feed=0,bchan=0,echan=0) {
    wider public 
    gl := public.uniget('globalscan1');
    if (!is_sdrecord(gl)) {
     dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
     return F
     }
    if (bchan==0) {
      bchan := public.uniget('bchan');
      if (bchan==0)
        bchan := 1
      }
    else
      public.uniput('bchan',bchan);
    if (echan==0) {
      echan := public.uniget('echan');
      if (echan==0)
        echan := gl.data.arr::shape[2]
      }
    else
      public.uniput('echan',echan);
    if (feed==0) {
     begin := 1
     end := gl.data.arr::shape[1]
     }
    else {
     begin := feed
     end := feed
     }
    if (bchan > gl.data.arr::shape[2] || echan > gl.data.arr::shape[2]) {
      dl.log(message=spaste('Channel boundaries out of range.  bchan = ',bchan,' echan = ',echan),priority='SEVERE',postcli=T)
      return F
      }
    for (ifeed in begin:end) {
     data := gl.data.arr[ifeed,bchan:echan]
     data_mean := mean(data)
     rms := stddev(data)
     printf('Feed : %-5d   bchan: %-6d   rms  : %-12.6f   min  : %-12.6f\n',
      ifeed,bchan,rms,min(data))
     printf('Npts : %-5d   echan: %-6d   mean : %-12.6f   max  : %-12.6f\n',
      len(data),echan,data_mean,max(data))
     printf('\n')
     }
    return T
}

private.privateshow := function(gs1) {
 wider public,private
 if (!is_sdrecord(gs1)) {
  dl.log(message='Not an sdrecord',priority='SEVERE',postcli=T)
  return F
  }
 bdrop := public.uniget('bdrop');
 edrop := public.uniget('edrop');
 if (gs1.data.arr::shape[2] - (bdrop+edrop) < 0) {
  dl.log(message='edrop and bdrop exclude all data points',priority='SEVERE',postcli=T)
  return F
  }
 if (bdrop==0 && edrop==0)
  public.plotscan(gs1)
 else {
  print 'Plot using bdrop = ',bdrop, 'and edrop = ',edrop
  if (bdrop==0) begin := 1
  else begin := bdrop
  if (edrop==0) end := gs1.data.arr::shape[2]
  else end := gs1.data.arr::shape[2]-edrop
  temp := gs1
  for (i in 1:gs1.data.arr::shape[1]) {
    temp.data.flag[i,1:begin] := T
    temp.data.flag[i,end:gs1.data.arr::shape[2]] := T
  }
  public.plotter.plotrec(temp)
  public.gsput(gs1)
  }
 return T;
}

public.show := function() {
 wider public, private
 gs1 := public.uniget('globalscan1');
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 private.privateshow(gs1)
 return T;
}

public.show1 := function(pol) {
 wider public, private
 gs := public.gsget()
 gs1 := public.getpol(gs,pol)
 private.privateshow(gs1)
 public.gsput(gs)
 return T;
}

public.showref := function() {
 wider public, private
 refscan := public.uniget('vref');
 if (!is_sdrecord(refscan)) {
  dl.log(message='No refscan available.',priority='SEVERE',postcli=T)
  return F
  }
 private.privateshow(refscan)
 return T
}

public.nregion := function(...) {
 wider public
 if (num_args(...)== 0) {
#  nr := public.unirec.nregion
  nr := public.uniget('nregion');
  print 'nregion currently set to: ',nr
  print 'To modify these values, use this function as follows:'
  print 'nregion(1,256,850,1023)'
  return T
  }
 if (num_args(...)%2 != 0) {
  dl.log(message='An even number of arguments is required for nregion',priority='SEVERE',postcli=T)
  return F
  }
 for (i in 1:num_args(...))
  limit[i] := nth_arg(i,...)
 if (limit != sort(limit)) {
  dl.log(message='Arguments must be sorted from lowest to highest',priority='SEVERE',postcli=T)
  return T
  }
 nr := ''
 for (i in 1:(len(limit)/2))
  nr := spaste(nr,'[',limit[i*2-1],',',limit[i*2],']')
# public.unirec.nregion := nr
 public.uniput('nregion',nr);
# public.unirec.nregionArr := limit
 public.uniput('nregionArr',limit);
 return T
}

public.baseline := function() {
 wider public
 # Set global unipops-like variables nfit and nregion prior to calling this.
 # e.g. nfit(2)
 #      nregion(1,256,512,1024)
 #      baseline()
 nfit:=d.uniget('nfit');
 nregion:=d.uniget('nregion');
 scanrec:=d.uniget('globalscan1');
 if (!is_sdrecord(scanrec)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
# public.unirec.globalscan1 := d.base(scanrec=public.unirec.globalscan1,
#               order=public.unirec.nfit,action='subtract',
#               range=public.unirec.nregion, autoplot=F)
 result:=public.base(scanrec=scanrec,order=nfit,action='subtract',range=nregion,
	autoplot=F);
 public.uniput('globalscan1',result);
 public.rms(F)
 return T
}

public.rms := function(printFlag=T) {
 wider public
 gl := public.gsget()
 if (!is_sdrecord(gl)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 nr := public.uniget('nregionArr');
 if (nr[1] < 1) {
  note('First entry in nregion must be > 0 to calculate baseline stats.')
  note('Calculating stats starting at pixel 1.')
  nr[1] := 1
  }
 if (nr[len(nr)] > gl.data.arr::shape[2]) {
  note('Last entry in nregion too large.')
  note('Using ',gl.data.arr::shape[2],' for calculating baseline stats.')
  nr[len(nr)] := gl.data.arr::shape[2]
  }
 return_val := T
 if (!printFlag) return_val := [=]
 for (feed in 1:(gl.data.arr::shape[1])) {
  data := F
  mask := array(F,gl.data.arr::shape[2])
  for (i in 1:(len(nr)/2))
   mask[nr[i*2-1]:nr[i*2]]:= T & !gl.data.flag[feed,nr[i*2-1]:nr[i*2]]
  if (!any(mask==T)) {
   dl.log(message='Bad range, or all data are flagged.',priority='SEVERE',postcli=T)
   return F
   }
  data := gl.data.arr[feed,mask]
  data_mean := mean(data)
  rms := stddev(data)
  if (printFlag) {
   print '== Feed ',feed,' ==='
   print 'RMS   = ',rms,'   Mean = ',data_mean,'   Num points = ',len(data)
   print 'max   = ',max(data),'  min = ',min(data)
   print 'nregion = ',nr
   }
  else {
   note('== Feed ',feed,' ===')
   note('RMS   = ',rms,'   Mean = ',data_mean,'   Num points = ',len(data))
   note('max   = ',max(data),'  min = ',min(data))
   note('nregion = ',nr)
   return_val.rms[feed] := rms
   return_val.max[feed] := max(data)
   return_val.min[feed] := min(data)
   return_val.mean[feed] := data_mean
   }
  }
 return return_val
}

public.dcbase := function() {
 wider public
 # Set global unipops-like variable nregion prior to calling dcbase.
 # e.g. nregion(1,256,512,1024)
 #      dcbase()
# gs1 := public.unirec.globalscan1
 gs1 := public.uniget('globalscan1');
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 range:=public.uniget('nregion');
 public.base(scanrec=gs1,order=0,action='subtract',range=range)
 public.uniput('globalscan1',public.rm().getvalues(d.rm().size()));
 return T
}

public.bshape := function() {
 wider public
 scanrec:=public.uniget('globalscan1');
 if (!is_sdrecord(scanrec)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 order:=public.uniget('nfit');
 region:=public.uniget('nregion');
# d.base(scanrec=public.unirec.globalscan1,order=public.unirec.nfit,
#        action='show',range=public.unirec.nregion)
 public.base(scanrec=scanrec,order=order,action='show',range=region);
 return T
}

public.scale := function(factor) {
    wider public;
# gs1 := public.unirec.globalscan1
    gs1 := public.uniget('globalscan1');
    if (!is_sdrecord(gs1)) {
	dl.log(message='No globalscan available.',priority='SEVERE',postcli=T);
	return F;
    }
    if (len(factor)==1) factor := array(factor,gs1.data.arr::shape[1]);
    if ((len(factor)==gs1.data.arr::shape[1])) {
	for (i in 1:gs1.data.arr::shape[1])
	    gs1.data.arr[i,] *:= factor[i];
    } else {
	dl.log(message='Length of factor does not match data shape',priority='SEVERE',postcli=T);
	return F;
    }
    public.uniput('globalscan1',gs1);
    return T
}

public.bias := function(factor) {
    wider public;
    gs1 := public.uniget('globalscan1');
    if (!is_sdrecord(gs1)) {
	dl.log(message='No globalscan available.',priority='SEVERE',postcli=T);
	return F;
    }
    if (len(factor)==1) factor := array(factor,gs1.data.arr::shape[1]);
    if ((len(factor)==gs1.data.arr::shape[1])) {
	for (i in 1:gs1.data.arr::shape[1])
	    gs1.data.arr[i,] +:= factor[i];
    } else {
	dl.log(message='Length of factor does not match data shape',priority='SEVERE',postcli=T);
	return F;
    }
    public.uniput('globalscan1',gs1);
    return T
}

public.addstack := function(beg,end=beg,inc=1) {
 wider public
 astack := public.uniget('astack')
 acount := public.uniget('acount')
 if (!is_boolean(astack) && acount != len(astack))
  dl.log(message='acount lost track of astack',priority='SEVERE',postcli=T)
 for (i in seq(beg,end,inc)) {
  acount := acount + 1
  if (!(any(astack==i))) 
   astack[acount] := i
  }
 public.uniput('astack',astack)
 public.uniput('acount',acount)
 return T
}

public.empty := function() {
 wider public
 public.uniput('acount',0);
 public.uniput('astack',F);
 return T
}

public.delete := function(value) {
 wider public
 astack := public.uniget('astack')
 acount := 0
 for (i in 1:len(astack))
  if (astack[i] != value) {
   acount +:= 1
   newastack[acount] := astack[i]
   }
 public.uniput('astack',newastack)
 public.uniput('acount',acount)
 return T

}

public.tellstack := function() {
 wider public
 astack := public.uniget('astack')
 acount := public.uniget('acount')
 if (is_boolean(astack))
  print 'No entries currently in the stack.'
 else {
  print acount,' entries in the stack.'
  }
 return astack
}

public.utable := function() {
 bdrop := public.uniget('bdrop')
 edrop := public.uniget('edrop')
 globalscan1 := public.uniget('globalscan1')
 if (!is_sdrecord(globalscan1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 if (bdrop==0) begin := 1
 else begin := bdrop
 if (edrop==0) end := globalscan1.data.arr::shape[2]
 else end := edrop
 for (i in begin:end)
  print i,globalscan1.data.arr[,i]
 return T
}

public.saxis := function(strval) {
 wider public
 if (any(strval==['GHz','MHz','kHz','Hz','km/s','m/s','pix','index'])) {
  public.plotter.ips.setabcissaunit(strval)
  public.plotter.ips->unitchange(strval);
 } else {
  dl.log(message='Invalid units; use one of: GHz, MHz, kHz, Hz, km/s, m/s, pix, index',priority='SEVERE',postcli=T)
 };
 return T
}

set_int := function(param,value) {
 if (is_boolean(value))
   return public.uniget(param)
 else if (is_integer(value))
   public.uniput(param,value)
 else
   dl.log(message='integer value required',priority='SEVERE',postcli=T)
 return T
}

set_float := function(param,value) {
 if (is_boolean(value))
   return public.uniget(param)
 else if (is_integer(value) || is_float(value))
   public.uniput(param,value)
 else
   dl.log(message='real value required',priority='SEVERE',postcli=T)
 return T
}

public.bgauss := function(value=T) { set_int('bgauss',value) }
public.egauss := function(value=T) { set_int('egauss',value) }
public.center := function(value=T) { set_float('center',value) }
public.hwidth := function(value=T) { set_float('hwidth',value) }
public.height := function(value=T) { set_float('height',value) }
public.bmoment := function(value=T) { set_int('bmoment',value) }
public.emoment := function(value=T) { set_int('emoment',value) }
public.bdrop := function(value=T) { set_int('bdrop',value) }
public.edrop := function(value=T) { set_int('edrop',value) }
public.nfit := function(value=T) { set_int('nfit',value) }

#public.moment := function(quiet=F) {
# wider public
# bmoment := public.uniget('bmoment')
# emoment := public.uniget('emoment')
# globalscan1 := public.uniget('globalscan1')
# if (bmoment==0) bmoment := 1
# if (emoment==0) emoment := len(globalscan1.data.arr[1,])
#
# xval := 1:len(globalscan1.data.arr[1,])
# yval := globalscan1.data.arr
#
## not currently supported ... only channels are.
# unit := d.plotter.ips.getabcissaunit()
#
# globalscan1 := public.uniget('globalscan1')
# if (emoment==len(globalscan1.data.arr[1,])) emoment -:= 1
# for (ipol in 1:(globalscan1.data.arr::shape[1])) {
#  moment1 := 0
#  moment2 := 0
#  sumweights := 0
#  for (i in bmoment:emoment) {
#   moment1 +:= (xval[i+1]-xval[i])*yval[ipol,i]
#   moment2 +:= xval[i]*yval[ipol,i]*(xval[i+1]-xval[i])
#   }
#  moment2 /:= moment1
#  if (!quiet) print 'Integrated Intensity = ', moment1, 'Centroid = ', moment2
#  public.uniput('mom_int',moment1)
#  public.uniput('mom_cent',moment2)
# }
# return T
#}

public.push := function() {
 wider public
 public.uniput('offscan1',public.uniget('globalscan1'));
 return T
}

const public.minus := function() {
 wider public;
 globalscan1 := public.uniget('globalscan1')
 if (!is_sdrecord(globalscan1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 offscan1 := public.uniget('offscan1')
 if (!is_sdrecord(offscan1)) {
  dl.log(message='No offscan available.',priority='SEVERE',postcli=T)
  return F
  }
 if (globalscan1::shape!=offscan1::shape) {
	dl.log(message='Shapes of globalscan and offscan do not match.',
	       priority='SEVERE',postcli=T)
	return F;
 };
 globalscan1.data.arr := globalscan1.data.arr-offscan1.data.arr
 public.uniput('globalscan1',globalscan1)
 return T
}

const public.plus := function() {
 wider public;
 globalscan1 := public.uniget('globalscan1')
 if (!is_sdrecord(globalscan1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 offscan1 := public.uniget('offscan1')
 if (!is_sdrecord(offscan1)) {
  dl.log(message='No offscan available.',priority='SEVERE',postcli=T)
  return F
  }
 if (globalscan1::shape!=offscan1::shape) {
	dl.log(message='Shapes of globalscan and offscan do not match.',
	       priority='SEVERE',postcli=T)
	return F;
 };
 globalscan1.data.arr := globalscan1.data.arr+offscan1.data.arr
 public.uniput('globalscan1',globalscan1)
 return T
}

const public.multiply := function() {
 wider public;
 globalscan1 := public.uniget('globalscan1')
 if (!is_sdrecord(globalscan1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 offscan1 := public.uniget('offscan1')
 if (!is_sdrecord(offscan1)) {
  dl.log(message='No offscan available.',priority='SEVERE',postcli=T)
  return F
  }
 if (globalscan1::shape!=offscan1::shape) {
	dl.log(message='Shapes of globalscan and offscan do not match.',
	       priority='SEVERE',postcli=T)
	return F;
 };
 globalscan1.data.arr := globalscan1.data.arr * offscan1.data.arr
 public.uniput('globalscan1',globalscan1)
 return T
}

public.divide := function() {
 wider public
 globalscan1 := public.uniget('globalscan1')
 if (!is_sdrecord(globalscan1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 offscan1 := public.uniget('offscan1')
 if (!is_sdrecord(offscan1)) {
  dl.log(message='No offscan available.',priority='SEVERE',postcli=T)
  return F
  }
 if (globalscan1::shape!=offscan1::shape) {
	dl.log(message='Shapes of globalscan and offscan do not match.',
	       priority='SEVERE',postcli=T)
	return F;
 };
 globalscan1.data.arr := globalscan1.data.arr / offscan1.data.arr
 public.uniput('globalscan1',globalscan1)
 return T
}

public.copy := function(fromhere,tohere) {
 wider public;
 public.uniput(tohere,public.uniget(fromhere))
 return T
}

public.upr := function(...) {
 wider public
 if (num_args(...)==0) {
  allparams := public.uniget()
  for (i in field_names(allparams))
   if (is_record(allparams[i]))
    print i,' = a record'
   else
    print i,' = ',allparams[i]
 } else {
  for (i in 1:num_args(...)) {
   if (!is_fail(public.uniget(nth_arg(i,...)))) {
    value := public.uniget(nth_arg(i,...))
    print nth_arg(i,...),' = ',value
   } else
    print nth_arg(i,...),' = not available'
   }
  }
 return T
}

public.peak := function(quiet=F) {
 wider public
 dl.log(message='Be aware that peak only work properly if a baseline has been subtracted.',priority='NORMAL',postcli=T)
 gs1 := public.uniget('globalscan1');
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 start := public.uniget('bdrop');
 stop := len(gs1.data.arr[1,]) - public.uniget('edrop');
 if (start<=0) start := 1
 if (stop>len(gs1.data.arr[1,])) stop := len(gs1.data.arr[1,])

# not currently supported ... only channels are.
 unit := public.plotter.ips.getabcissaunit()
 yval := gs1.data.arr
 for (ipol in 1:(gs1.data.arr::shape[1])) {
  height := yval[ipol,start]
  sumweights := 0
  for (i in start:stop) {
   if (yval[ipol,i]>height) {
       height:=yval[ipol,i]
       center:=i
   }
  }
  for (i in start:center)
   if (yval[ipol,i]<=height/2)
       hw1:=i
  for (i in center:stop)
   if (yval[ipol,i]>=height/2)
       hw2:=i
  hwidth:=abs(hw2-hw1)
  egauss:=center-hwidth
  bgauss:=center+hwidth
  if (!quiet) print 'Center=',center, 'Hwidth=', hwidth, 'Height=', height
  public.uniput('center',center)
  public.uniput('height',height)
  public.uniput('bgauss',egauss)
  public.uniput('egauss',bgauss)
  public.uniput('hwidth',hwidth)
  }
 return T
}

public.lscans := ref public.listscans

#chngfile?
#kget?


public.keep := function() {
 wider public
 if (is_boolean(d.files(T).fileout)) {
  dl.log(message='No fileout specified.',priority='SEVERE',postcli=T)
  return F
  }
 gs1 := public.uniget('globalscan1');
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 d.save(gs1)
 print 'globalscan saved to ',d.files(T).fileout
 return T
}

public.klscans := ref public.lsoutfile

public.hanning := function() {
 wider public
 gs1 := public.uniget('globalscan1')
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 gs2 := d.smooth(gs1,'HANNING',,,T,F)
 public.uniput('globalscan1',gs2)
 return T
}

public.boxcar := function(smooth_width=3) {
 wider public
 gs1 := public.uniget('globalscan1')
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 gs2 := d.smooth(gs1,'BOXCAR',smooth_width,,T,F)
 dl.log(message=spaste('Smoothed with boxcar width = ',smooth_width),
	priority='NORMAL',postcli=T)
 public.uniput('globalscan1',gs2)
 return T
}

public.chngres := function(smooth_width) {
 wider public
 gs1 := public.uniget('globalscan1')
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 gs2 := d.smooth(gs1,'GAUSSIAN',smooth_width,,T,F)
 public.uniput('globalscan1',gs2)
 return T
}

public.setYUnit := function(unit) {
 wider public
 gs1 := public.uniget('globalscan1')
 if (!is_sdrecord(gs1)) {
  dl.log(message='No globalscan available.',priority='SEVERE',postcli=T)
  return F
  }
 gs1.data.desc.units := unit
 public.uniput('globalscan1',gs1)
 return T
}

public.store := function() {
 wider public
 params := public.uniget()
 write_value(params,spaste(shell('echo $HOME'),'/.uni2params'))
}

public.restore := function() {
 tst := dos.fileexists('~/.uni2params')
 if (tst) {
  params := read_value(spaste(shell('echo $HOME'),'/.uni2params'))
# should modify uniput so that all these can be entered at once
  public.uniput('astack',params.astack)
  public.uniput('acount',params.acount)
  public.uniput('edrop',params.edrop)
  public.uniput('bdrop',params.bdrop)
  public.uniput('echan',params.echan)
  public.uniput('bchan',params.bchan)
  public.uniput('emoment',params.emoment)
  public.uniput('bmoment',params.bmoment)
  public.uniput('nfit',params.nfit);
  public.uniput('numaccum',params.numaccum);
  public.uniput('vref',params.vref);
  public.uniput('vsig',params.vsig);
  public.uniput('globalscan1',params.globalscan1);
  public.uniput('nregion',params.nregion)
  public.uniput('nregionArr',params.nregionArr)
  return T
  }
 else {
  dl.log(message='Parameters are not available',priority='SEVERE',postcli=T)
  return F
  }
}

public.flag := function(scan=F,ints=F,polarization=F,channel=F,flag=T) {
    wider public;

    #retrieve name of active sditerator
    #technique to avoid sticky table locking issues
    rmname:=eval(public.files(T).filein);
    msname:=rmname.name();
    ok:=rmname.unlock();
    tab:=table(msname,readonly=F);
    if (is_fail(tab)) print 'table creation failed';

    #if no scan specified, then do whole MS
    if (is_boolean(scan)) {
	scan:=public.listscans();
    };

    global scanlist:=scan;
    subtab:=tab.query('SCAN_NUMBER in $scanlist');
    if (subtab.nrows()==0) {
	dl.log(message='No scans found',priority='SEVERE',postcli=T);
	ok:=subtab.done();
	ok:=tab.done();
	ok:=rmname.lock(0);
	return F;
    };

    if (is_boolean(ints)) {
	ints:=1:subtab.nrows();
    } else if (is_integer(ints)) {
	scanstats:=public.qscan(scan[1]);
        ok:=rmname.unlock();
	# there are scanstats.row/scanstats.ints rows per integration
	# turn ints into actual rows in the table
	rowPerInt := scanstats.rows/scanstats.ints;
	if (rowPerInt > 1) {
	    bint:=1+(ints-1)*rowPerInt;
	    ints := bint;
	    for (i in 2:rowPerInt) {
		bint +:= 1;
		ints := [ints,bint];
	    }
	}
	if (min(ints) < 1 || max(ints) > subtab.nrows()) {
	    dl.log(message=spaste('integration (ints) are numbered from 1 through ',
				  scanstats.ints,
				  '; invalid integration requested'),
		   priority='SEVERE',postcli=T);
	    ok:=subtab.done();
	    ok:=tab.done();
	    ok:=rmname.lock(0);	
	    return F;
	};
    } else {
	dl.log(message='subscan range must be integer',priority='SEVERE',postcli=T);
	ok:=subtab.done();
	ok:=tab.done();
	ok:=rmname.lock(0);
	return F;
    };

    flags:=subtab.getcol('FLAG');
    #now check inputs
    #if no channels specified, use all channels
    if (is_boolean(channel)) {
	channel:=1:flags::shape[2];
    } else {
	if (!is_integer(channel)) {
	    dl.log(message='channel range must be integer',priority='SEVERE',postcli=T);
	    ok:=subtab.done();
	    ok:=tab.done();
	    ok:=rmname.lock(0);
	    return F;
	};
	if (min(channel) < 1 || max(channel) > flags::shape[2]) {
	    dl.log(message=spaste('channels are numbered from 1 through ',flags::shape[2],
				  '; invalid channel requested'),
		   priority='SEVERE', postcli=T);
	    ok:=subtab.done();
	    ok:=tab.done();
	    ok:=rmname.lock(0);
	    return F;
	}
    }
    if (is_boolean(polarization)) {
	polarization:=1:flags::shape[1];
    } else {
	if (!is_integer(polarization)) {
	    dl.log(message='polarization range must be integer',priority='SEVERE',postcli=T);
	    ok:=subtab.done();
	    ok:=tab.done();
	    ok:=rmname.lock(0);	
	    return F;
	};
	if (min(polarization) < 1 || max(polarization) > flags::shape[1]) {
	    dl.log(message=spaste('polarizations are numbered from 1 through ',flags::shape[2],
				  '; invalid polarization requested'),
		   priority='SEVERE', postcli=T);
	    ok:=subtab.done();
	    ok:=tab.done();
	    ok:=rmname.lock(0);
	    return F;
	}
    }
    flags[polarization,channel,ints]:=flag;
    ok:=rmname.unlock();
    ok:=subtab.putcol('FLAG',flags);
    ok:=subtab.flush();
    ok:=subtab.done();
    ok:=tab.done();
    rmname.lock(0);
    return T;
};

public.setregion := function() {
 region := ''
 public.saxis('pix')
 public.show()
 print 'Use the left button to set location, right button to exit'
 inc := 0
 plot_limits := public.plotter.qwin()
 while(T) {
  curs_val := public.plotter.curs()
  if (curs_val.ch=='X') break;
  if (curs_val.ch=='A') {
   inc +:= 1
   val1[inc] := as_integer(curs_val.x+0.5)
   public.plotter.line([val1[inc],val1[inc]],[plot_limits[3],plot_limits[4]])
   }
  }
 val1 := sort(val1)
 if (inc%2!=0)
  val2[1:(inc-1)] := val1[1:(inc-1)]
 else
  val2 := val1
 for (i in 1:(len(val2)/2))
  region := spaste(region,'[',val2[i*2-1],',',val2[i*2],']')
 public.uniput('nregion',region)
 public.uniput('nregionArr',val2)
 printf('region = (')
 for (i in 1:(len(val2)-1)) printf('%3d,',val2[i])
 printf('%3d)\n',val2[len(val2)])
 public.show()
 meanval := (plot_limits[3]+plot_limits[4])/2
 public.plotter.sci(1)
 for (i in seq(1,len(val2),2))
  public.plotter.line([val2[i],val2[i+1]],[meanval,meanval])
 return T
}

public.gsflag := function(pol=0,bchan=F,echan=bchan,flagval=T) {
 if (!is_boolean(flagval)) {
   dl.log(message='flagval must be T or F',priority='SEVERE',postcli=T)
   return F
   }
 gs := public.uniget('globalscan1')
 if (pol==0) pol := 1:gs.data.arr::shape[1]
 if (pol < 0 || pol > gs.data.arr::shape[1]) {
   dl.log(message='illegal polarization -- nothing flagged',priority='SEVERE',postcli=T)
   return F
   }
 if (!is_boolean(echan) && is_boolean(bchan))
   bchan := 1
 if (!is_boolean(bchan)) {
   if (bchan < 1 ) {
     dl.log(message='bchan<1 illegal -- using bchan=1',priority='WARN',postcli=T)
     bchan := 1
     }
   if (echan < 1 ) {
     dl.log(message='echan<1 illegal -- using echan=bchan',priority='WARN',postcli=T)
     echan := bchan
     }
   if (bchan > gs.data.arr::shape[2]) {
     dl.log(message=paste('bchan illegal -- using bchan=',gs.data.arr::shape[2]),priority='WARN',postcli=T)
     bchan := gs.data.arr::shape[2]
     }
   if (echan > gs.data.arr::shape[2]) {
     dl.log(message=paste('echan illegal -- using echan=',gs.data.arr::shape[2]),priority='WARN',postcli=T)
     echan := gs.data.arr::shape[2]
     }
   if (bchan > echan) {
     tmp := echan; echan := bchan; bchan := tmp
     }
   gs.data.flag[pol,bchan:echan] := flagval
   return T
   }
 public.saxis('pix')
 public.show()
 print 'left button   : set flag range boundary'
 print 'middle button : zoom'
 print 'right button  : when finished'
 inc := 0
 plot_limits := public.plotter.qwin()
 while(T) {
  curs_val := public.plotter.curs()
  if (curs_val.ch=='X') break;
  if (curs_val.ch=='A') {
   inc +:= 1
   val1[inc] := as_integer(curs_val.x+0.5)
   if (val1[inc] < 1) val1[inc] := 1
   if (val1[inc] > gs.data.arr::shape[2]) val1[inc] := gs.data.arr::shape[2]
   public.plotter.line([val1[inc],val1[inc]],[plot_limits[3],plot_limits[4]])
   if (inc==2) {
    inc := 0
    gs.data.flag[pol,val1[1]:val1[2]] := flagval
    public.uniput('globalscan1',gs)
    public.show()
    }
   }
  }
  return T
}



	public.msr := function() {
		wider public;
		return dishgmeasure(public);
	};

return T;

}
