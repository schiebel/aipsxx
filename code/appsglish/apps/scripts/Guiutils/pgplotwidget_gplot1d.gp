# pgplotwidget_gplot1d

pragma include once
note('gplot1d plugin included');

include 'types.g'

pgplotwidget_gplot1d := [=];

pgplotwidget_gplot1d.attach := function(ref public) {

private.data := [=]

private.is_env:= function()
{
 wider private
 ret := F
 for (i in 1:public.displaylist().ndrawlist())
  {
  temprec:=public.displaylist().get(i)
  if (temprec._method=='env' && ret == F) ret := T
  else if (temprec._method=='env' && ret == T) {
   dl.log(message='Plotter displaylist has > 1 ENV statement, incompatible with gplot1d emulator functions.',priority='WARN',postcli=T)
   return T
   }
  }
 return ret
}

private.is_page:= function()
{
 wider private
 for (i in 1:public.displaylist().ndrawlist())
  {
  temprec:=public.displaylist().get(i)
  if (temprec._method=='page') return T
  }
 return F
}

private.is_firsty2 := function()
{
 wider private
 ret := T
 for (i in 1:len(private.data.axis))
  if (private.data.axis[i]==2) ret := F
 return ret
}

private.checklims:= function(x,y,axis)
{
 wider public, private
 change := F
 ymin10 := min(y)-0.1*(max(y)-min(y))
 ymax10 := max(y)+0.1*(max(y)-min(y))
 if (axis==1)
  {
  if (min(x)<private.data.xmin1) {private.data.xmin1 := min(x); change := T }
  if (max(x)>private.data.xmax1) {private.data.xmax1 := max(x); change := T }
  if (ymin10<private.data.ymin1) {private.data.ymin1 := ymin10; change := T }
  if (ymax10>private.data.ymax1) {private.data.ymax1 := ymax10; change := T }
  }
 else
  {
  if (min(x)<private.data.xmin2) {private.data.xmin2 := min(x); change := T }
  if (max(x)>private.data.xmax2) {private.data.xmax2 := max(x); change := T }
  if (ymin10<private.data.ymin2) {private.data.ymin2 := ymin10; change := T }
  if (ymax10>private.data.ymax2) {private.data.ymax2 := ymax10; change := T }
  }
 return change
}

private.change_env:= function()
{
 wider private
 temprec:=[=];
 for (i in 1:public.displaylist().ndrawlist())
  {
  temprec:=public.displaylist().get(i)
  if (temprec._method=='env') break
  }
 temprec.xmin := private.data.xmin1
 temprec.ymin := private.data.ymin1
 temprec.xmax := private.data.xmax1
 temprec.ymax := private.data.ymax1
 public.displaylist().set(i,temprec)
}

private.change_swin:= function(axis)
{
 wider private
 temprec:=[=];
 cnt := 1
 for (i in 1:public.displaylist().ndrawlist())
  {
  temprec:=public.displaylist().get(i)
  if (temprec._method=='swin') 
   {
   cnt +:= 1
   if (axis==1 && private.data.axis[cnt]==1)
    {
    temprec.x1 := private.data.xmin1
    temprec.y1 := private.data.ymin1
    temprec.x2 := private.data.xmax1
    temprec.y2 := private.data.ymax1
    } 
   else if (axis==2 && private.data.axis[cnt]==2)
    {
    temprec.x1 := private.data.xmin2
    temprec.y1 := private.data.ymin2
    temprec.x2 := private.data.xmax2
    temprec.y2 := private.data.ymax2
    }
   public.displaylist().set(i,temprec)
   }
  }
}

private.setaxis1:= function(x,y,xlab,ylab,tlab,timeflag)
{
 wider private
 if (private.is_page())
   dl.log(message='gplot1d functions (e.g. plotxy1) are not compatible with the pgplot page function',priority='WARN',postcli=T)
 if (private.is_env()==F)
  {
  xmin := min(x)
  xmax := max(x)
  ymin := min(y)-0.1*(max(y)-min(y))
  ymax := max(y)+0.1*(max(y)-min(y))
  private.data.xmin1 := xmin
  private.data.xmax1 := xmax
  private.data.ymin1 := ymin
  private.data.ymax1 := ymax
  public.env(xmin,xmax,ymin,ymax,0,-1);
  public.slw(3);
  public.sci(1);
  if (timeflag)
   public.tbox('bstzhn',0,0,'bstn',0,0);
  else
   public.box('bnst',0,0,'bnst',0,0);
  private.data.count := 0
  private.data.axis := 0
  public.sci(1)
  public.lab(xlab,ylab,tlab)
  }
 else
  {
  change := private.checklims(x,y,1) 
  if (change) 
   {
   private.change_env()
   private.change_swin(1)
   public.refresh()
   }
  public.swin(private.data.xmin1,private.data.xmax1,
              private.data.ymin1,private.data.ymax1)
  }
}

private.setaxis2:= function(x,y,xlab,ylab,tlab,timeflag)
{
 wider private
 if (private.is_page())
   dl.log(message='gplot1d functions (e.g. plotxy1) are not compatible with the pgplot page function',priority='WARN',postcli=T)
 if (private.is_env()==F) {
  dl.log(message='Plot to y1 axis first',priority='SEVERE',postcli=T)
  return F
  }
 else if (private.is_firsty2()==T)
  {
  xmin := min(x)
  xmax := max(x)
  ymin := min(y)-0.1*(max(y)-min(y))
  ymax := max(y)+0.1*(max(y)-min(y))
  private.data.xmin2 := xmin
  private.data.xmax2 := xmax
  private.data.ymin2 := ymin
  private.data.ymax2 := ymax
  public.swin(xmin,xmax,ymin,ymax);
  public.slw(3);
  public.sci(5);
  public.box('cstm',0,0,'cstm',0,0);
  }
 else
  {
  change := private.checklims(x,y,2) 
  if (change) 
   {
   private.change_swin(2)
   public.refresh()
   }
  public.swin(private.data.xmin2,private.data.xmax2,
              private.data.ymin2,private.data.ymax2)
  }
 return T
}

public.plotxy1 := function(xx,yy,xlab='',ylab='',tlab='',plotlines=T,ptsymbol=2)
{
 wider public, private;

 if (!is_numeric(xx) || !is_numeric(yy) || is_complex(xx) ||
     is_complex(yy) || length(xx) == 0 || length(yy)==0) {
     dl.log(message='plotxy1: x, y must be real vectors',priority='SEVERE',postcli=T)
     return F
     }

 public.bbuf()
 private.setaxis1(xx,yy,xlab,ylab,tlab,F)
 private.data.count +:= 1;
 private.data.axis[private.data.count] := 1
 public.sci(1+private.data.count);
 if (plotlines)
  public.line(xx,yy);
 else {
  if (!is_integer(ptsymbol)) ptsymbol := 2
  public.pt(xx,yy,ptsymbol)
 }
 labloc:=-.8-private.data.count;
 public.mtxt('t',labloc,0.02,0,ylab);
 public.ebuf();
 return T;
}


public.ploty := function(yy,xlab='',ylab='',tlab='',plotlines=T,ptsymbol=2)
{
 wider public, private;
 public.plotxy1(1:len(yy),yy,xlab,ylab,tlab,plotlines,ptsymbol)
}


public.ploty2 := function(yy,xlab='',ylab='',tlab='',plotlines=T,ptsymbol=2) 
{
 wider public, private;
 public.plotxy2(1:len(yy),yy,xlab,ylab,tlab,plotlines,ptsymbol)
}

public.plotxy2 := function(xx,yy,xlab='',ylab='',tlab='',plotlines=T,ptsymbol=2) 
{
 wider public, private;

 if (!is_numeric(xx) || !is_numeric(yy) || is_complex(xx) ||
     is_complex(yy) || length(xx) == 0 || length(yy)==0) {
     dl.log(message='plotxy2: x, y must be real vectors',priority='SEVERE',postcli=T)
     return F
     }
 if (private.data.count == F) {
     dl.log(message='plotxy2 must be used in conjunction with plotxy1',priority='SEVERE',postcli=T)
     return F
     }

 public.bbuf()
 if (!private.setaxis2(xx,yy,xlab,ylab,tlab,F)) return F
 private.data.count +:= 1;
 private.data.axis[private.data.count] := 2
 public.sci(1+private.data.count);
 if (plotlines)
  public.line(xx,yy);
 else {
  if (!is_integer(ptsymbol)) ptsymbol := 2
  public.pt(xx,yy,ptsymbol)
 }
 labloc:=-.8-private.data.count;
 public.mtxt('b',labloc,0.02,0,ylab);
 public.sci(1)
 public.ebuf();
 return T;
}

public.timey := function(xx,yy,xlab='',ylab='',tlab='',plotlines=T,ptsymbol=2) 
{
 wider public, private;

 if (!is_numeric(xx) || !is_numeric(yy) || is_complex(xx) ||
    is_complex(yy) || length(xx) == 0 || length(yy)==0) {
     dl.log(message='timey: x, y must be real vectors',priority='SEVERE',postcli=T)
     return F
    }

 public.bbuf()
 private.setaxis1(xx,yy,xlab,ylab,tlab,T)
 private.data.count +:= 1;
 private.data.axis[private.data.count] := 1
 public.sci(1+private.data.count);
 if (plotlines)
  public.line(xx,yy);
 else {
  if (!is_integer(ptsymbol)) ptsymbol := 2
  public.pt(xx,yy,ptsymbol)
 }
 labloc:=-.8-private.data.count;
 public.mtxt('t',labloc,0.02,0,ylab);
 public.ebuf();
 return T;
}


public.timey2 := function(xx,yy,xlab='',ylab='',tlab='',plotlines=T,ptsymbol=2)
{
 wider public, private;

 if (!is_numeric(xx) || !is_numeric(yy) || is_complex(xx) ||
    is_complex(yy) || length(xx) == 0 || length(yy)==0) {
     dl.log(message='timey: x, y must be real vectors',priority='SEVERE',postcli=T)
     return F
    }

 minx:=min(xx);
 maxx:=max(xx);
 ymin:=min(yy)-0.1*(max(yy)-min(yy));
 ymax:=max(yy)+0.1*(max(yy)-min(yy));
 public.bbuf()
 public.swin(minx,maxx,ymin,ymax);
 public.slw(3);
 public.sci(1);
 public.tbox('cstmz',0,0,'cstm',0,0);
 private.data.count +:= 1;
 private.data.axis[private.data.count] := 2
 public.sci(1+private.data.count);
 if (plotlines)
  public.line(xx,yy);
 else {
  if (!is_integer(ptsymbol)) ptsymbol := 2
  public.pt(xx,yy,ptsymbol)
 }
 labloc:=-.8-private.data.count;
 public.mtxt('t',labloc,0.02,0,ylab);
 public.sci(1)
 public.lab(xlab,ylab,tlab)
 public.ebuf();
 return T;
}

public.setxscale:=function(xmin,xmax)
{
 wider private, public;
 private.data.xmin1 := xmin
 private.data.xmax1 := xmax
 dum:=public.qwin();
 private.data.ymin1 := dum[3];
 private.data.ymax1 := dum[4];
 private.change_env()
 private.change_swin(1)
 public.refresh()
 return T;
}

public.setx2scale:=function(xmin,xmax)
{
 wider private, public;
 private.data.xmin2 := xmin
 private.data.xmax2 := xmax
 private.change_swin(2)
 public.refresh()
 return T;
}

public.setyscale:=function(ymin,ymax)
{
 wider private, public;
 private.data.ymin1 := ymin
 private.data.ymax1 := ymax
 dum:=public.qwin();
 private.data.xmin1 := dum[1];
 private.data.xmax1 := dum[2];
 private.change_env()
 private.change_swin(1)
 public.refresh()
 return T;
}

public.sety2scale:=function(ymin,ymax)
{
 wider private, public;
 private.data.ymin2 := ymin
 private.data.ymax2 := ymax
 private.change_swin(2)
 public.refresh()
 return T;
}

	public.setxaxisgrid:=function(on=T) {
		wider public;
        # Find the original env command and alter it to the
        # appropriate value
		if (on) {
                for (di in 1:public.displaylist().ndrawlist()) {
                        temprec:=public.displaylist().get(di);
                        temprec2:=public.displaylist().get(di+1);
                        if (temprec._method=='env' && temprec2._method=='box'){
                                temprec2.xopt:=spaste(temprec2.yopt,'g');
                                public.displaylist().set(di+1,temprec2);
                        }       # end if looking through env commands
                }    # end di loop through drawlist
		} else {
		for (di in 1:public.displaylist().ndrawlist()) {
                        temprec:=public.displaylist().get(di);
                        temprec2:=public.displaylist().get(di+1);
                        if (temprec._method=='env' && temprec2._method=='box'){
                                temprec2.xopt:=split(temprec2.yopt,'g')[1];
                                public.displaylist().set(di+1,temprec2);
                        }       # end if looking through env commands
                }    # end di loop through drawlist
		}    # end on loop

                public.refresh();
                return T;
        }

        public.setyaxisgrid:=function(on=T) {
                wider public;
        # Find the original env command and alter it to the
        # appropriate value
		if (on) {
                for (di in 1:public.displaylist().ndrawlist()) {
                        temprec:=public.displaylist().get(di);
                        temprec2:=public.displaylist().get(di+1);
                        if (temprec._method=='env' && temprec2._method=='box'){
                                temprec2.yopt:=spaste(temprec2.yopt,'g');
                                public.displaylist().set(di+1,temprec2);
                        }       # end if looking through env commands
                }    # end di loop through drawlist
		} else {
		                for (di in 1:public.displaylist().ndrawlist()) {
                        temprec:=public.displaylist().get(di);
                        temprec2:=public.displaylist().get(di+1);
                        if (temprec._method=='env' && temprec2._method=='box'){
                                temprec2.yopt:=split(temprec2.yopt,'g')[1];
                                public.displaylist().set(di+1,temprec2);
                        }       # end if looking through env commands
                }    # end di loop through drawlist
		}    # end on loop
                public.refresh();
                return T;
        }

	public.sety2axisgrid:=function(on=T) {
		wider public;
	# Find the original env command and alter it to the
        # appropriate value
		if (on) {
                for (di in 1:public.displaylist().ndrawlist()) {
                        temprec:=public.displaylist().get(di);
			temprec2:=public.displaylist().get(di+1);
                        if (temprec._method=='swin' && temprec2._method=='box'){
                                temprec2.yopt:=spaste(temprec2.yopt,'g');
                                public.displaylist().set(di+1,temprec2);
                        }       # end if looking through env commands
                }    # end di loop through drawlist
		} else {
                for (di in 1:public.displaylist().ndrawlist()) {
                        temprec:=public.displaylist().get(di);
                        temprec2:=public.displaylist().get(di+1);
                        if (temprec._method=='swin' && temprec2._method=='box'){
                                temprec2.yopt:=split(temprec2.yopt,'g')[1];
                                public.displaylist().set(di+1,temprec2);
                        }       # end if looking through env commands
                }    # end di loop through drawlist
		}    # end on loop
                public.refresh();
                return T;
        }

	public.setcolor:=function(ci=2) {
		wider public;
		ok:=public.sci(ci);
		return T;
	}

	public.setplottitle:=function(title='') {
		wider public;
                if (!is_string(title)) {
                   note('title is not a string; set to blank',priority='WARN');
                }
		public.mtxt(side='t',disp=1.8,coord=0.5,fjust=0.5,text=title);
		return T;
	}

	public.setxaxislabel:=function(xlabel='') {
		wider public;
                if (!is_string(xlabel)) {
                   note('xlabel is not a string; set to blank',priority='WARN');
                }
		public.mtxt(side='b',disp=2.0,coord=0.5,fjust=0.5,text=xlabel);
		return T;
	}

	public.setyaxislabel:=function(ylabel='') {
		wider public;
		if (!is_string(ylabel)) {
	           note('ylabel is not a string; set to blank',priority='WARN');
  		}
		public.mtxt(side='l',disp=2.0,coord=0.5,fjust=0.5,text=ylabel);
		return T;
	}

	public.psprint:=function() {
		wider public;
            file := dsh.command('echo /tmp/aipstmp_$$.ps').lines;
            public.postscript(file);
            ok := dsh.command('pri /tmp/aipstmp_$$.ps');
            if (ok.status != 0) note('Error printing file : ', file, '\n',
                                     spaste(ok.errlines), priority='WARN');
            dsh.command('rm -f /tmp/aipstmp_$$.ps');
	}

	public.psprinttofile:=ref public.postscript;


	return T;
}
