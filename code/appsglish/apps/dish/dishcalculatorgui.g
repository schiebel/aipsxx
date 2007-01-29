# dishcalculatorgui.g: DISH calculator.
#------------------------------------------------------------------------------
# Copyright (C) 1999,2000,2002,2003
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
#------------------------------------------------------------------------------
pragma include once;

include 'widgetserver.g';
include 'interpolate1d.g';

const dishcalculatorgui := subsequence (parent, itsdish, widgetset=dws)
{

    private := [=];     # mostly private data
    private.dish := itsdish;
    private.op := itsdish.ops().calculator;
    private.logcommand := itsdish.logcommand;
    private.intserver := F;
    private.fftserver := F;

    widgetset.tk_hold();
    private.outerFrame := widgetset.frame(parent, side='top', relief='ridge');
#
# Stack counter is for labeling the stack values.
# lbcntr=listbox counter is for keeping track of#  values in listbox-this is
# necessary because deleting values within the listbox causes problems
# in the indexing and you need to get the one before the end.  There doesn't
# seem to be any way to actually know how many items are in the listbox from
# the listbox itself.
    private.stackcntr:=0;
    private.lbcntr := 0;
    private.descriptions := [=];

    private.labelFrame := widgetset.frame (private.outerFrame,expand='x',borderwidth=0);
    private.mainLabel  := widgetset.label (private.labelFrame,'DISH Calculator');
    private.mainFrame := widgetset.frame (private.outerFrame, side='right', relief='ridge');
#
# Operation frame
#
    private.operf:=widgetset.frame(private.mainFrame);
#
    private.toprowf:=widgetset.frame(private.operf,side='left');
    private.secrowf:=widgetset.frame(private.operf,side='left');
    private.thirowf:=widgetset.frame(private.operf,side='left');
    private.fourowf:=widgetset.frame(private.operf,side='left');
    private.fifrowf:=widgetset.frame(private.operf,side='left');
    private.sixrowf:=widgetset.frame(private.operf,side='left');
    private.sevrowf:=widgetset.frame(private.operf,side='left');
    private.botrowf:=widgetset.frame(private.operf,side='left');
#
    private.divide  := widgetset.button(private.toprowf,'   /   ',type='action');
    popuphelp(private.divide,hlp='Divide two values.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.multiply:= widgetset.button(private.toprowf,'   *   ',type='action');
    popuphelp(private.multiply,hlp='Multiply two values.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.minus   := widgetset.button(private.toprowf,'   -   ',type='action');
    popuphelp(private.minus,hlp='Subtract two values.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.plus    := widgetset.button(private.toprowf,'   +   ',type='action');
    popuphelp(private.plus,hlp='Add two values.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
#
    private.sine    := widgetset.button(private.secrowf,'  sin  ',type='action');
    popuphelp(private.sine,hlp='Sine of a value (degrees).',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.cose    := widgetset.button(private.secrowf,'  cos  ',type='action');
    popuphelp(private.cose,hlp='Cosine of a value (degrees).',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.tang    := widgetset.button(private.secrowf,'  tan  ',type='action');
    popuphelp(private.tang,hlp='Tangent of a value (degrees).',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.fftrans := widgetset.button(private.secrowf,'  fft  ',type='action');
    popuphelp(private.fftrans,hlp='FFT of a value.',
	      txt='Values may be either vectors or records (uses data array).',
	      combi=T);
#
    private.asine   := widgetset.button(private.thirowf,'  asin ',type='action');
    popuphelp(private.asine,hlp='Arcsine of a value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.acose   := widgetset.button(private.thirowf,'  acos ',type='action');
    popuphelp(private.acose,hlp='Arccosine of a value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.atang   := widgetset.button(private.thirowf,'  atan ',type='action');
    popuphelp(private.atang,hlp='Arctangent of a value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.ifftrans:= widgetset.button(private.thirowf,'  ifft ',type='action');
    popuphelp(private.ifftrans,hlp='IFFT of a value.',
	      txt='Values may be either vectors or records (uses data array).',
	      combi=T);
#
    private.sqroot  := widgetset.button(private.fourowf,'   sqrt   ',type='action');
    popuphelp(private.sqroot,hlp='Square root of a value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.sqr     := widgetset.button(private.fourowf,'   sqr     ',type='action');
    popuphelp(private.sqr,hlp='Square of a value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.xroot   := widgetset.button(private.fourowf,'  xroot   ',type='action');
    popuphelp(private.xroot,hlp='xth root of a value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
#
    private.ytox    := widgetset.button(private.fifrowf,'   y^x    ',type='action');
    popuphelp(private.ytox,hlp='Raise y to the x value power.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.tentox  := widgetset.button(private.fifrowf,'  10^x     ',type='action');
    popuphelp(private.tentox,hlp='Raise 10 to the x value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.logx    := widgetset.button(private.fifrowf,'  logx    ',type='action');
    popuphelp(private.logx,hlp='Logarithm of a value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
#
    private.recipx  := widgetset.button(private.sixrowf,'   1/x    ',type='action');
    popuphelp(private.recipx,hlp='Reciprocal of a value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.etox    := widgetset.button(private.sixrowf,'   e^x     ',type='action');
    popuphelp(private.etox,hlp='Raise e to a value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
    private.lnx     := widgetset.button(private.sixrowf,'   lnx    ',type='action');
    popuphelp(private.lnx,hlp='Natural logarithm of a value.',
	      txt='Values may be either numbers, vectors or records (uses data array).',
	      combi=T);
#
    private.torm    := widgetset.button(private.sevrowf,' Selected to RM  ',type='action');
    popuphelp(private.torm,hlp='Send to Results Manager',
	      txt='Selected value in stack is sent to the results manager.',
	      combi=T);
    private.dels    := widgetset.button(private.sevrowf,'   Clear Entry   ',type='action');
    popuphelp(private.dels,hlp='Clear entry value',
	      txt='',combi=T);
#
    private.enter   := widgetset.button(private.botrowf,'   enter  ',type='action');
    popuphelp(private.enter,hlp='Value on entry line will be added to stack.',
	      txt='',combi=T);
    private.clear   := widgetset.button(private.botrowf,'clear stack',type='action');
    popuphelp(private.clear,hlp='Clear stack and entry field.',
	      txt='Resets stack counter.',combi=T);
    private.dismiss := widgetset.button(private.botrowf,'  dismiss ',type='dismiss');
    popuphelp(private.dismiss,hlp='Close calculator',
	      txt='',combi=T);
#
# Stack and command line frame
#
    private.stackf  := widgetset.frame(private.mainFrame);
    private.lbf1    := widgetset.frame(private.stackf,side='top');
    private.lbflabel:= widgetset.label(private.lbf1,'Stack');
    private.lbf2    := widgetset.frame(private.lbf1,side='left');
    private.lb      := widgetset.listbox(private.lbf2,width=32,height=8);
    popuphelp(private.lbflabel,hlp='The calculator stack',
	      txt='Keeps a record of calculations performed in the stack. New values are decorated with an underscore and the value of the stack number.',
	      combi=T);
#       # add the copy/paste popup
    private.lbf.copypastemenu :=
	widgetset.popupselectmenu(private.lb, ['Copy to clipboard', 
					 'Paste from clipboard']);
    whenever private.lbf.copypastemenu->select do {
	wider private;
	option := $value;
	if (option == 'Paste from clipboard') {
	    private.paste();
	} else if (option == 'Copy to clipboard') {
	    private.copy();
	}
    }
#
    private.sb      := scrollbar(private.lbf2);
#
    private.ef      := widgetset.frame(private.stackf,side='right');
    private.en      := widgetset.entry(private.ef);
    private.eflabel := widgetset.label(private.ef,'Entry');
    popuphelp(private.eflabel,hlp='Entry field',
	      txt='Enter values (numbers, vectors or records) into this field. Selecting on a value in the stack will send a value to the entry field.',
	      combi=T);
#
    widgetset.tk_release();
#
###
#
    whenever private.sb->scroll do
        private.lb->view($value);
    whenever private.lb->yscroll do
        private.sb->view($value);
#
###
    whenever private.enter->press,private.en->return do {
	private.addToLB(private.en->get());
	private.en->delete('start','end');
	private.lb->see('end');
    }

    # increments stackcntr and lbcntr and clears the top
    # when the stackcntr gets large
    private.addToLB := function(newname) {
	wider private;
        private.stackcntr+:=1;
        private.lbcntr+:=1;
        if (private.lbcntr>=26) {
	    private.lb->delete('0','0');
	    private.lbcntr -:= 1;
        }       # end stack clearing
	private.lb->insert(spaste(private.stackcntr,':',newname));
    }

    private.paste := function() {
	wider private;
	thisval:=dcb.paste();
        if (is_record(thisval)) { 
	    if (has_field(thisval,'names') &&
		has_field(thisval,'descriptions') &&
		has_field(thisval,'values')) {
		# just grab the first one in all cases
		thisname := thisval.names[1];
		thisdesc := thisval.descriptions[1];
		# stackcntr has not yet been incremented 
		newname:=spaste(thisname,'_',as_string(private.stackcntr+1));
		# we always create a new one here by appending the stackcntr
		tmp := symbol_set(newname,thisval.values[thisname]);
		if (is_fail(tmp)) {
		    return throw(paste('Unexpected failure in creating named value :',newname),
				 origin='dishcalculator');
		}
		private.descriptions[newname] := thisdesc;
		private.addToLB(newname);
	    } else {
		return throw('Unrecognized contents of clipboard - can not be pasted to dishcalculator',
			     origin='dishcalculator');
	    }
        } else {
	    # it is a vector or number
	    private.addToLB(as_string(thisval));
        }
        private.en->delete("start","end");
        private.lb->see('end');
	return T;
    }

    self.paste := private.paste;

    self.outerframe := function() {
	wider private;
	return private.outerFrame;
    }

    self.done := function() {
	wider private,self;
	state:=[=];
	if (!is_boolean(private.fftserver)) {
	    private.fftserver.done();
	    private.fftserver := F;
	}
	if (!is_boolean(private.intserver)) {
	    private.intserver.done();
	    private.intserver := F;
	}
	val private.outerFrame := F;
	private := [=];
	self->done(state);
    }

    private.copy := function() {
	wider private;
        push:=private.lb->selection();
	# if there is no selection then push will have zero length
	if (len(push)>0) {
	    private.vl:=split(private.lb->get(push),':');
	    thisName := private.vl[2];
	    testit:=symbol_value(thisName);
	    if (is_sdrecord(testit)) {
		thisDesc := '';
		if (has_field(private.descriptions, thisName)) {
		    thisDesc := private.descriptions[thisName];
		} else {
		    thisDesc := 'sdrecord from calculator';
		}
		dcb.copy(private.makeRecord(testit, thisDesc, thisName));
	    } else {
#	  print private.vl[2];
		dcb.copy(thisName);
	    }
	}
    }
    self.copy := private.copy;
    
#
    private.recplotfn := ref private.dish.view_sdrec;
#

    whenever private.clear->press do {
        private.lb->delete("start","end");
        private.en->delete("start","end");
        private.stackcntr:=0;
	private.lbcntr:=0;
	private.descriptions := [=];
    }
    whenever private.dismiss->press do {
	self->dismiss(private.op.opmenuname());
    }
    whenever private.lb->select do {
        push:=private.lb->selection();
	private.vl:=split(private.lb->get(push),':');
	private.en->delete('start','end');
        private.en->insert(private.vl[2]);
	if (is_sdrecord(symbol_value(private.vl[2]))) {
	    private.recplotfn(symbol_value(private.vl[2]),private.vl[2]);
	}
	temp:=F;
    }
#  whenever private.dels->press do {
#	push:=private.lb->selection()
#	if (len(push)!=0) {
#	  push:=as_string(push);
#          private.lb->delete(push,push);
#          private.stackcntr-:=1;
#	  private.en->delete("start","end");
#	}
#  }
    whenever private.dels->press do {
        private.en->delete("start","end");
    }


    self.setstate := function(state) {
	wider private;
	# reset to default value;
        private.lb->delete("start","end");
        private.en->delete("start","end");
        private.stackcntr:=0;
        private.lbcntr:=0;
	private.descriptions := [=];
	if (has_field(state,'lbcntr') && has_field(state,'stackcntr') &&
	    has_field(state,'name') && has_field(state,'rec') &&
	    has_field(state,'descriptions')) {
	    private.stackcntr := state.stackcntr;
	    if (state.lbcntr > 0 && 
		len(state.name) == state.lbcntr &&
		len(state.rec) == state.lbcntr &&
		len(state.descriptions) == state.lbcntr) {
		
		for (i in 1:state.lbcntr) {
		    # state.rec[i] must be a record, or it gets skipped, silently
		    if (is_record(state.rec[i])) {
			thisLBName := state.name[i];
			tmp := split(thisLBName,':');
			thisName := tmp[2];
			thisVal := state.rec[i];
			isASymbol := T;
			thisDesc :=state.descriptions[i];
			if (has_field(thisVal,'_notARecord')) {
			    isASymbol := has_field(thisVal,'_notASymbol');
			    thisVal := thisVal._notARecord;
			}
			private.lb->insert(thisLBName);
			private.lbcntr +:= 1;
			# don't set this symbol if its already defined
			if (isASymbol) {
			    if (!is_defined(thisName)) {
				tmp := symbol_set(thisName,thisVal);
				if (is_fail(tmp)) {
				    return throw(paste('Unexpected failure in creating named value :',thisName),
						 origin='dishcalculator');
				}
			    }
			    if (is_sdrecord(thisVal)) {
				private.descriptions[thisName] := thisDesc;
			    }
			} # else it wasn't a symbol before, so it isn't one now either
		    } 
		}
	    }
	}
	if (private.lbcntr > 0) {
	    private.lb->see('end');
	}
	return T;
    }

    self.getstate := function() {
	wider private;
	state:=[=];
	state.rec:=[=];
	state.name:=as_string([]);
	state.descriptions:=as_string([]);
	state.stackcntr := private.stackcntr;
	state.lbcntr := private.lbcntr;
	if (private.lbcntr > 0) {
	    myrange := 1:private.lbcntr;
	    for (i in myrange) {
		state.name[i]:=private.lb->get(i-1);
		newstring:=split(state.name[i],':');
		if (is_defined(newstring[2])) {
		    thisval := symbol_value(newstring[2]);
		    if (is_record(thisval)) {
			state.rec[i] := thisval;
			thisDesc := '';
			if (has_field(private.descriptions,newstring[2])) {
			    thisDesc := private.descriptions[newstring[2]];
			}
			state.descriptions[i] := thisDesc;
		    } else {
			phonyRec := [=];
			phonyRec._notARecord := thisVal;
			state.rec[i] := phonyRec;
			state.descriptions[i] := '';
		    }
		} else {
		    phonyRec := [=];
		    phonyRec._notARecord := F;
		    phonyRec._notASymbol := T;
		    state.rec[i] := phonyRec;
		    state.descriptions[i] := '';
		}
	    }
	}
	return state;
    }
#
    whenever private.multiply->press do {
	mydata:=private.getdata();
	newdat:=mydata[1]*mydata[2];
#        print 'mydata are ',mydata[1][1],mydata[1]::shape;
#	 print 'mydata2 are ',mydata[2][1],mydata[2]::shape;;
#        print 'newdat are ',newdat[1],newdat::shape;
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    oldshape:=myrec.values[myrec.names[1]].data.arr::shape;
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    myrec.values[myrec.names[1]].data.arr::shape:=oldshape;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end multiply button event
#
    whenever private.divide->press do {
	mydata:=private.getdata();
 	newdat:=mydata[2]/mydata[1];
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    oldshape:=myrec.values[myrec.names[1]].data.arr::shape;
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    myrec.values[myrec.names[1]].data.arr::shape:=oldshape;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end divide button event
#
    whenever private.minus->press do {
	mydata:=private.getdata();
	newdat:=mydata[2]-mydata[1];
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    oldshape:=myrec.values[myrec.names[1]].data.arr::shape;
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    myrec.values[myrec.names[1]].data.arr::shape:=oldshape;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    } 	# end minus button event
#
    whenever private.plus->press do {
	mydata:=private.getdata();
	newdat:=mydata[2]+mydata[1];
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    oldshape:=myrec.values[myrec.names[1]].data.arr::shape;
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    myrec.values[myrec.names[1]].data.arr::shape:=oldshape;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end plus button event
#
    whenever private.sine->press do {
	mydata:=private.getdata(onlyone=T);
	newdat:=sin((pi/180.)*mydata[1]);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    } 	# end sin button event
# 
    whenever private.cose->press do {
        mydata:=private.getdata(onlyone=T);
        newdat:=cos((pi/180.)*mydata[1]);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }     # end cos button event
#
    whenever private.tang->press do {
        mydata:=private.getdata(onlyone=T);
	newdat:=tan((pi/180.)*mydata[1]);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }     # end tangent button event
#
    whenever private.fftrans->press do {
	mydata:=private.getdata(onlyone=T);
	if (is_boolean(private.fftserver)) {
	    private.fftserver := fftserver();
	}
	myfft:=private.fftserver;
#	newdat:=myfft.realtocomplexfft(mydata[1]);
        newdat:=mydata;
	# it would be useful if getdata returned the flags as well
	if (is_record(mydata[3])) {
	    myrec := mydata[3];
	    flag := myrec.values[myrec.names[1]].data.flag;
	    # watch for flagged data - interpolate around them
	    for (i in 1:flag::shape[1]) {
		if (any(flag[i,])) {
		    # need to supply interpolated values for the flagged data
		    indgood := ind((newdat[1])[i,])[!flag[i,]];
		    if (is_boolean(private.intserver)) private.intserver := interpolate1d();
		    private.intserver.initialize(indgood,(newdat[1])[i,indgood]);
		    indbad := ind((newdat[1])[i,])[flag[i,]];
		    (newdat[1])[i,indbad] := private.intserver.interpolate(indbad); 
		    # unflag it all
		    myrec.values[myrec.names[1]].data.flag[i,]:=F;
		}
#		ok := myfft.complexfft((newdat[1])[i,],1);
	    }
	    ok := myfft.complexfft((newdat[1]),1);
	    #plotter has difficulty with imaginary numbers so only give it real
	    myrec.values[myrec.names[1]].data.arr:=(newdat[1]);
	    ok:=private.stackh(myrec);
	} else {
	    ok:=myfft.complexfft(newdat[1],1);
	    result:=as_string(newdat[1]);
	    ok:=private.stackh(result);
	}
    }	# end fft button event
#
    whenever private.ifftrans->press do {
        mydata:=private.getdata(onlyone=T);
	if (is_boolean(private.fftserver)) {
	    private.fftserver := fftserver();
	}
	myfft:=private.fftserver;
	newdat:=mydata;
        ok:=myfft.complexfft(newdat[1],-1);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat[1];
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat[1]);
	    ok:=private.stackh(result);
        }
    }     # end fft button event
#
    whenever private.asine->press do {
        mydata:=private.getdata(onlyone=T);
        newdat:=(180./pi)*asin(mydata[1]);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }     # end arcsin button event
#
    whenever private.acose->press do {
        mydata:=private.getdata(onlyone=T);
        newdat:=(180./pi)*acos(mydata[1]);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }     # end arccos button event
#
    whenever private.atang->press do {
        mydata:=private.getdata(onlyone=T);
        newdat:=(180./pi)*atan(mydata[1]);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }     # end arctangent button event
#
    whenever private.sqroot->press do {
        mydata:=private.getdata(onlyone=T);
        newdat:=sqrt(mydata[1]);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }     # end square root button event
#
    whenever private.sqr->press do {
	mydata:=private.getdata(onlyone=T);
        newdat:=mydata[1]*mydata[1];
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end square button event
#
    whenever private.xroot->press do {
        mydata:=private.getdata();
        newdat:=mydata[2]^(1/mydata[1]);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    oldshape:=myrec.values[myrec.names[1]].data.arr::shape;
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    myrec.values[myrec.names[1]].data.arr::shape:=oldshape;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end xroot button event
#
    whenever private.ytox->press do {
        mydata:=private.getdata();
        newdat:=mydata[2]^mydata[1];
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    oldshape:=myrec.values[myrec.names[1]].data.arr::shape;
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    myrec.values[myrec.names[1]].data.arr::shape:=oldshape;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end y to x power button event
#
    whenever private.tentox->press do {
        mydata:=private.getdata(onlyone=T);
	newdat:=10^mydata[1];
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
	} else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end 10 to x power button event
#
    whenever private.logx->press do {
        mydata:=private.getdata(onlyone=T);
    	newdat:=log(mydata[1]);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end logx button event
#
     whenever private.recipx->press do {
        mydata:=private.getdata(onlyone=T);
        newdat:=1./mydata[1];
#	 print 'mydata are ',mydata[1][1:10];
#        print 'newdat are ',newdat[1:10];
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end reciprocal of x button event
#
    whenever private.etox->press do {
        mydata:=private.getdata(onlyone=T);
	newdat:=e^mydata[1];
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end e to x power button event
#
    whenever private.lnx->press do {
        mydata:=private.getdata(onlyone=T);
        newdat:=ln(mydata[1]);
        if (is_record(mydata[3])) {
	    myrec:=mydata[3];
	    myrec.values[myrec.names[1]].data.arr:=newdat;
	    ok:=private.stackh(myrec);
        } else {
	    result:=as_string(newdat);
	    ok:=private.stackh(result);
        }
    }	# end lnx button event
    whenever private.torm->press do {
	wider private;
	# just use the private copy to move it to the clipboard
	private.copy();
	# then use the RM paste function to grab it from the CB
	private.dish.rm().paste();
    }

    private.makeRecord := function(avalue, adescription, aname) {
	# this is the structure expected in the copy/paste syntax and
	# it also used internally to hand around the associated information
	# with the value
	rec := [=];
	# ensure that names and descriptions are single element strings
	rec.names := paste(aname);
	rec.descriptions := paste(adescription);
	rec.values := [=];
	rec.values[rec.names] := avalue;
	# is this a global symbol?
	rec.valueIsGlobal := is_defined(aname);

	return rec;
    }
 #
# functions to handle the data in the stack
#
    private.stackh  := function(stackdata) {
	wider private;
        if (!is_record(stackdata)) {
	    # only used internall, stackdata must already be a string
	    private.addToLB(stackdata);
	} else {
	    # only used internally so don't need to check fields here
	    thisname := stackdata.names[1];
	    newname := spaste(thisname,'_',as_string(private.stackcntr));
	    thisdesc := stackdata.descriptions[1];
	    thisval:=stackdata.values[thisname];
	    # always generate a new symbol here
	    tmp := symbol_set(newname,thisval);
	    if (is_fail(tmp)) {
		return throw(paste('Unexpected failure in creating named value :',newname),
			     origin='dishcalculator');
	    }
	    private.descriptions[newname] := thisdesc;
	    private.addToLB(newname);
#
	    if (is_sdrecord(thisval)) {
		# plot and select this from the stack
		# first, clear the current selection
		private.lb->clear(private.lb->selection());
		# then select the last one
		private.lb->select('end');
                private.recplotfn(thisval,newname);
	    }
#
	}
	private.en->delete("start","end");
	private.lb->see('end');

	return T;
    }	# end stack handling function
#

     # returns a record constructed from the entry, if its not blank, and
    # (if onlyone is T) from the end of the stack.  The order of the
    # fields in the record is [1] = value from entry (data.arr if sdrecord
    # or double corresponding to entry text if not), [2] = value from
    # bottom of stack or F if onlyone is F), [3] full value if entry
    # is an sdrecord (private.makeRecord is used to construct the
    # record containing the name and description (if it is an sdrecord) 
    # along with the full value and [4] the full value of the bottom of 
    # the stack if onlyone is T and it is an sdrecord else F.
    private.getdata := function(onlyone=F) {
	wider private;
	myrec:=F;
	myrec2:=F;
	onen := F;
        twon:=F;
	calcdata:=[=];
	oneName := private.en->get();
	twoName := F;
	# establish whether the info on the entry line is a record or not
	# determine if there is anything on the command line or
	# do we need to look at the stack to perform the operation
        if (strlen(oneName)>0) {				# entry is not blank
	    # print 'entry is not blank'
	    # now check on the value in the stack (in case it's needed)
	    if (!onlyone) {
		twoFields := split(private.lb->get(private.lbcntr-1),':');
		twoName := twoFields[2];
	    }
 	} else {	# entry is blank
	    oneFields:=split(private.lb->get(private.lbcntr-1),':');
	    oneName := oneFields[2];
	    # and get the next up on the stack if necessary
	    if (!onlyone) {
		twoFields := split(private.lb->get(private.lbcntr-2),':');
		twoName := twoFields[2];
	    }
	} # end loop determining if number or sdrecord

	# handle first value -> myrec, and onen;
	thisval:=symbol_value(oneName);
	if (is_sdrecord(thisval)) {       	# first value is an sd record
	    # print 'first value is an sd record';
	    onen:=thisval.data.arr;
	    thisDesc := '';
	    if (has_field(private.descriptions,oneName)) {
		thisDesc := private.descriptions[oneName];
	    }
	    myrec := private.makeRecord(thisval, thisDesc, oneName);
	} else {              # first value isn't an sd record
	    # print 'first value isnt an sd record';
	    newvalue:=spaste("\'",oneName,"\'");
	    onen:=as_double(eval(newvalue));
	} # end condition of first value being an sd record

	# handle second value if necessary
	if (!is_boolean(twoName)) {
	    thisval:=symbol_value(twoName);
	    if (is_sdrecord(thisval)) {	# second value is an sd record
		twon:=thisval.data.arr;
		thisDesc := '';
		if (has_field(private.descriptions,twoName)) {
		    thisDesc := private.descriptions[twoName];
		}
		myrec2 := private.makeRecord(thisval, thisDesc, twoName);
	    } else {
		newvalue:=spaste("\'",twoName,"\'");
		twon:=as_double(eval(newvalue));
	    }
	}

	if (is_record(myrec2) & !is_record(myrec)) {
	    tmp := myrec2;
	    myrec:=myrec2;
	    myrec2 := tmp;
	}
	if (len(onen)>1 && len(twon)>1 && len(onen)!=len(twon)) fail 'did this actually happen';
	# print 'lengths are',len(onen),len(twon);
	calcdata[1]:=onen;
	calcdata[2]:=twon;
	calcdata[3]:=myrec;
	calcdata[4]:=myrec2;
	return calcdata;
    }	# end data retrieval function
	public.getdata:=ref private.getdata;

}	# end sdcalc_manager
