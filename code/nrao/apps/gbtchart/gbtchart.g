# pragma include once;

#make this const when done

chart := function() 
{
self := [=];
public := [=];

  self.chartErase := function(x,y) {
	wider self;
	self.pg->sci(0);
	self.pg->line(x,y);
	self.pg->sci(3)
  }

  public.chartGui:=function() {
	wider self;
	tk_hold();
	self.f:=frame(title='Receiver Chart Recorder');
	self.chartf:=frame(self.f,side='left',borderwidth=0);
	self.pg:=pgplot(self.chartf,width=400,height=250,background="black",
		foreground="white",region=[0,1,0,1]);
	self.pg->eras()
#	self.pg->svp(0.03,0.43,0.59,.99);
	self.pg->pap(4,0.6);
	self.pg->swin(-1,1,0,1000);
	self.pg->box("bc",0,0,"bc",0,0);
#	self.pg:=pgplot(self.chartf,width=600,height=400);
#	self.pg->pap(0,0.5);
#	self.pg->pap(0,0.5); # bug that it is required twice
#	self.pg->env(0,1000,-1,1,0,-2)
#
  	self.scanf:=frame(self.f,side='left',borderwidth=0);
	self.sl := status_line(self.scanf);
  	self.sl.show('Time  0:00:00    Scan 1       ObsMode Test     01/01/00');
#
	self.ctrlModef:=frame(self.f,side='left',borderwidth=0);
	self.modeLabel:=message(self.ctrlModef,"Mode:       ");
  	self.mode1:=button(self.ctrlModef,'Auto Display',type='radio');
  	self.mode2:=button(self.ctrlModef,'Review Mode',type='radio');
	self.mode3:=button(self.ctrlModef,'Test',type='radio');
	self.mode2->state(T);
#
# Mode Button Actions
#
        whenever self.mode1->press do {
                self.mtime->disabled(T);
                self.ptime->disabled(T);
                self.sof->disabled(T);
                self.eof->disabled(T);
                self.defaults->disabled(T);
                self.ts1->disabled(T);
                self.ts2->disabled(T);
                self.ts3->disabled(T);
                self.ts4->disabled(T);
		self.ts1->state(F);
		self.ts2->state(F);
		self.ts3->state(F);
		self.ts4->state(F);
                }
        whenever self.mode2->press do {
                self.mtime->disabled(F);
                self.ptime->disabled(F);
                self.sof->disabled(F);
                self.eof->disabled(F);
                self.defaults->disabled(F);
                self.ts1->disabled(F);
                self.ts2->disabled(F);
                self.ts3->disabled(F);
                self.ts4->disabled(F);
                }
        whenever self.mode3->press do {
                self.mtime->disabled(T);
                self.ptime->disabled(T);
                self.sof->disabled(T);
                self.eof->disabled(T);
                self.defaults->disabled(T);
                self.ts1->disabled(T);
                self.ts2->disabled(T);
                self.ts3->disabled(T);
                self.ts4->disabled(T);
                public.test();
                }
#
	self.ctrltsf:=frame(self.f,side='left',borderwidth=0);
	self.stepLabel:=message(self.ctrltsf,'Step Size');
  	self.ts1:=button(self.ctrltsf,'10 Min',type='radio');
	self.ts1->state(T);
	self.TimeStep := dm.unit(paste(0.006944,"d"));
  	self.ts2:=button(self.ctrltsf,'1 Hour',type='radio');
  	self.ts3:=button(self.ctrltsf,'2 Hours',type='radio');
  	self.ts4:=button(self.ctrltsf,'4 Hours',type='radio');
#
# Time Step Button Actions
#
	whenever self.ts1->press do {
		self.TimeStep := dm.unit(paste(0.006944,"d"));
		}
	whenever self.ts2->press do {
		self.TimeStep := dm.unit(paste(0.04167,"d"));
		}
	whenever self.ts3->press do {
		self.TimeStep := dm.unit(paste(0.08333,"d"));
		}
	whenever self.ts4->press do {
		self.TimeStep := dm.unit(paste(0.16667,"d"));
		}
#
	self.tsAction:=frame(self.f,side='left',borderwidth=0);
	self.mtime := button(self.tsAction,'-Time');
	self.ptime := button(self.tsAction,'+Time');
	self.sof := button(self.tsAction,'Start of File');
	self.eof := button(self.tsAction,'End of File');
	self.selchan := button(self.tsAction,'Select Channels');
#
# Time Button Actions
#
	whenever self.mtime->press do {
		self.newTime:=public.subtractTime(self.currentTime,self.TimeStep);
		self.currentTime:=self.newTime
		self.newIndex  := public.findIndex(self.currentTime);
		public.chartCompute(self.newIndex);
		public.chartPlot();
		public.writeToSL(self.newIndex);
	}
	whenever self.ptime->press do {
		self.newTime := public.addTime(self.currentTime,self.TimeStep);
		self.currentTime:=self.newTime
		self.newIndex := public.findIndex(self.currentTime);
		public.chartCompute(self.newIndex);
		public.chartPlot();
		public.writeToSL(self.newIndex);
	}
	whenever self.sof->press do {
        	self.currentTime := dm.unit(paste(self.timeStamp[1],"d"))
		public.chartCompute(1);
		public.chartPlot();
		public.writeToSL(1);
	}
	whenever self.eof->press do {
		endval := self.datlen - 400;
        	self.currentTime := dm.unit(paste(self.timeStamp[endval],"d"))
		public.chartCompute(endval);
#		public.chartPlot(self.a,self.b,self.minx,self.maxx,self.miny,self.maxy);
		public.chartPlot();
		public.writeToSL(endval);
	}
#
	tk_release();
#
        whenever self.mode3->press do {
                self.mtime->disabled(T);
                self.ptime->disabled(T);
                self.sof->disabled(T);
                self.eof->disabled(T);
                self.defaults->disabled(T);
                self.ts1->disabled(T);
                self.ts2->disabled(T);
                self.ts3->disabled(T);
                self.ts4->disabled(T);
		public.test();
                }
# select channels action
#
        self.chanf:=frame(self.f,side='left',borderwidth=0);
        self.c1tp:=button(self.chanf,'Chan 1',type='check');
        self.c2tp:=button(self.chanf,'Chan 2',type='check');
        self.c3tp:=button(self.chanf,'Chan 3',type='check');
	self.cdis:=button(self.chanf,'Dismiss');
	self.c1sp->state(T);
	self.c1tp->state(T);
	self.chanf->unmap();
#
	whenever self.selchan->press do {
		self.chanf->map();
	}
	whenever self.cdis->press do {
		self.chanf->unmap();
	}
	whenever self.c1tp->press do {
		self.pg->eras();
		self.nchan:=1;
		public.chartPlot();
		}
	whenever self.c2tp->press do {
		self.pg->eras();
		self.nchan:=2;
		public.chartPlot();
		}
	self.nchan:=1;
#	

  }

  public.test := function() {
        wider self;     
	self.pg->eras()
	self.pg->slw(3);
	self.pg->box('bcn',0,0,'bc',0,0);
	self.pg->sci(3);
	self.pg->subp(2,1);
	self.pg->panl(2,1);
	self.pg->eras();
	self.pg->panl(1,1);
        self.y:=1:1000;
        count:=0;
        self.x:=sin(self.y/10);
        for (i in 1:100) {
                self.pg->bbuf();
                self.chartErase(self.x,self.y);
                count +:= 1;
                self.x:=sin(self.y/10+count);
                self.pg->line(self.x,self.y);
                self.pg->ebuf();       
                }
	self.pg->subp(1,1);
	self.pg->sci(1);
  }

  public.chartRead := function() {
	wider self;
	self.fileId := du.fopen('./chart.dat','r');
#bug that these must be predefined
	self.chartLines := ["test","here"];
	self.timeStamp := [1.2,3.4];
	self.mode := ["test","here"];
	self.scanNumber := [1, 2];
	self.tp1 := [1.2,3.4];
	self.tp2 := [1.2,3.4];
	self.sp1 := [1.2,3.4];
	self.sp2 := [1.2,3.4];
	self.scan := "test";
	self.comment := "test";
	scnt:=0;
	cnt:=0;
#
	for (i in 1:1000) {
		tempie := du.fgets(self.fileId);
		if(tempie==0) {
			break
		}
		self.chartLines[i]:=tempie;
		self.data := split(self.chartLines[i]);
		if (len(self.data)==7) {
			self.c3tp->disable(T);
			self.timeStamp[i] := as_double(self.data[1]);
			self.mode[i] := as_string(self.data[2]);
			self.scanNumber[i] := as_integer(self.data[3]);
			self.tp1[i] := as_double(self.data[4]);
			self.sp1[i] := as_double(self.data[5]);
			self.tp2[i] := as_double(self.data[6]);
			self.sp2[i] := as_double(self.data[7]);
			if (self.scanNumber[i]!=self.scanNumber[i-1]&&i>=2){
				scnt+:=1;
				txtscan := as_string(self.data[3]);
				self.scan[scnt]:=as_string(paste(self.data[2]," ",txtscan));
				self.spt[scnt]:=i;
			};;
		}
		else {
			cnt+:=1;
			self.comment[cnt] := as_string(paste(self.data[1]," ",self.data[2]," ",self.data[3]));
			self.cpt[cnt] := i;
		};
	}
	self.datlen := len(self.mode);
        self.currentTime := dm.unit(paste(self.timeStamp[1],"d"))
        public.chartCompute(1);
        public.chartPlot();
        public.writeToSL(1);
#	print self.datlen,self.tp1[1:10];
  }

  public.writeToSL := function(indie) {
	wider self;
	self.timemjd := dm.unit(paste(self.timeStamp[indie],"d"));
	self.timedmy := split(dm.time(self.timemjd,form="dmy"),'/');
	self.time := self.timedmy[2];
	self.date := self.timedmy[1];
	self.messg := paste('Time  ',self.time,'  Scan ',self.scanNumber[indie],'  ObsMode ',self.mode[indie],' ',self.date);
	self.sl.show(self.messg);
  }	

  public.subtractTime := function(beg,fin) {
	wider self;
	self.ptime->disabled(F);
	thetime := dm.sub(beg,fin);
	this := thetime.value;
	that := self.timeStamp[1];
	if (this<that) {
#		print "Exceeds first time point in file";
		self.mtime->disabled(T)
		return beg;}
	else {
		return thetime;}
  }

  public.addTime := function(beg,fin) {
	wider self;
	self.mtime->disabled(F);
	thetime := dm.add(beg,fin);
	this:=thetime.value;
	that:=self.timeStamp[self.datlen];
	if (this>that) {
#		print "Exceeds last time point in file";
		self.ptime->disabled(T);
		return beg;}
	else {
		return thetime;}
  }

  public.findIndex := function(starttyme) {
	wider self;
	check :=starttyme.value;
	for (i in 1:(self.datlen-1)) {
		if (check >= self.timeStamp[i] && check < self.timeStamp[i+1]){	
			indie := i;
			break;
		};;
	}
	return indie;
  }

  public.chartCompute := function(v) {
	wider self;
	u:=v+400;
	if (v>=(self.datlen-400)) {
		v:=self.datlen-400;
		u:=self.datlen;
	};;
	self.a := self.tp1[v:u];
	self.b := v:u;
	self.c := self.sp1[v:u];
	self.e := self.tp2[v:u];
	self.g := self.sp2[v:u];
	self.minx1 := min(self.a,self.c);
	self.maxx1 := max(self.a,self.c);
	self.minx2 := min(self.e,self.g);
	self.maxx2 := max(self.e,self.g);
	self.miny := min(self.b);
	self.maxy := max(self.b);
  }
  public.chartPlot := function() {
	wider self;
	if (self.nchan==1) {
		self.pg->sci(1);
		self.pg->subp(1,1);
		self.pg->panl(1,1);
		self.pg->eras();
		self.pg->swin(self.minx1,self.maxx1,self.miny,self.maxy);
		self.pg->sch(2);
		self.pg->box('bctns',0,0,'bc',0,0);
		self.pg->sci(15);
		self.pg->box('',0,0,'g',0,0);
		self.pg->sci(2);
		self.pg->line(self.a,self.b);
		self.pg->sci(3);
		self.pg->line(self.c,self.b);
		self.pg->sci(7);
		self.pg->sch(1.7);
		for (i in 1:len(self.comment)) {
			self.pg->ptxt(self.minx1,self.cpt[i],0,0,self.comment[i]);
		};;
		self.pg->sci(5);
		for (i in 1:len(self.scan)) {
			self.pg->ptxt(self.maxx1,self.spt[i],0,1,self.scan[i]);
		};;
		self.pg->sch(1);
		self.pg->sci(1);
	};;
	if (self.nchan==2) {
                self.pg->sci(1);
                self.pg->subp(2,1);
                self.pg->panl(1,1);
                self.pg->eras();
		self.pg->swin(self.minx1,self.maxx1,self.miny,self.maxy);
                self.pg->sch(2);
                self.pg->box('bctns',0,0,'bc',0,0);
                self.pg->sci(15);
                self.pg->box('',0,0,'g',0,0);
                self.pg->sci(2);
                self.pg->line(self.a,self.b);
                self.pg->sci(3);
                self.pg->line(self.c,self.b);
                self.pg->sci(7);
                self.pg->sch(1.7);
                for (i in 1:len(self.comment)) {
                        self.pg->ptxt(self.minx1,self.cpt[i],0,0,self.comment[i]);
                };;
                self.pg->sci(5);
                for (i in 1:len(self.scan)) {
                        self.pg->ptxt(self.maxx1,self.spt[i],0,1,self.scan[i]);
                };;
                self.pg->sch(1);
                self.pg->sci(1);
		self.pg->panl(2,1);
                self.pg->eras();
                self.pg->swin(self.minx2,self.maxx2,self.miny,self.maxy);
                self.pg->sch(2);
                self.pg->box('bctns',0,0,'bc',0,0);
                self.pg->sci(15);
                self.pg->box('',0,0,'g',0,0);
                self.pg->sci(2);
                self.pg->line(self.e,self.b);
                self.pg->sci(3);
                self.pg->line(self.g,self.b);
                self.pg->sci(7);
                self.pg->sch(1.7);
                for (i in 1:len(self.comment)) {
                        self.pg->ptxt(self.minx2,self.cpt[i],0,0,self.comment[i]);
                };;
                self.pg->sci(5);
                for (i in 1:len(self.scan)) {
                        self.pg->ptxt(self.maxx2,self.spt[i],0,1,self.scan[i]);
                };;
                self.pg->sch(1);
                self.pg->sci(1);
        };;
  }

  public.self := function() 
  {
	wider self;
	return self;
  }

return public;

}

# make this const when done
ch:=chart();
ch.chartGui();
ch.chartRead();
