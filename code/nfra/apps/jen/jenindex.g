# jenindex.g: indexing tool to step through arrays.

# Copyright (C) 1996,1997,1998,1999
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
# $Id: jenindex.g,v 19.0 2003/07/16 03:38:33 aips2adm Exp $

#---------------------------------------------------------
pragma include once
# print 'include jenindex.g  h01sep99'


#==========================================================================
#--------------------------------------------------------------------------
# Functions that help iterate through a nD array to get successive slices
# of any dimension. It returns an index-record, or F if finished. 
# (Public, so that they can also be used by other objects, via jenindex...)

#==========================================================================
#==========================================================================

jenindex := function (origin='origin', showprogress=T, autofinish=T,
			                    forwardonly=F) {
    private := [=];
    public := [=];

    private.origin := origin;				# input argument
    private.autofinish := autofinish;			# input argument
    private.showprogress := showprogress;		# input argument
    private.forwardonly := forwardonly;			# input argument

    public.agent := create_agent();			# communication 
    whenever public.agent -> * do {
	# print 'jenindex event:',public.agent;
    }
    whenever public.agent -> abort do {
	print '\n\n ** jenindex abort event:',$value;
	public.abort($value);
    }
    whenever public.agent -> suspend do {
	# print 'jenindex suspend event:',$value;
	private.suspend := $value;
    }
    whenever public.agent -> progress_control do {
	# print 'jenindex: progress_control event:',$value;
	private[$value]();				# call relevant function
    }
    whenever public.agent -> stride_control do {
	# print 'jenindex: stride_control event:',$value;
	private[$value]();				# call relevant function
    }


    private.echo := client ('echo_client');		# make client
    whenever private.echo -> echo do {
	# print 'echo event, value=',$value;
    }
    private.timer := client ('timer');			# make client
    whenever private.timer -> ready do {
	# print 'timer ready event: value=',$value;
    }


    public.done := function () {
	wider private;
	print 'jenindex: done(): suspend()';
	public.suspend();				# just in case
	print 'jenindex: done(): abort()';
	public.abort();					# just in case
	print 'jenindex: done(): val private := F';
	val private := F;
	return T;
    }

    public.suspend := function(tf=T) {
	wider private;
	private.suspend := tf;
	public.agent -> suspend(private.suspend);
	return T;
    }

    public.abort := function(txt) {
	wider private;
	private.abort := T;
	public.agent -> abort(private.abort);
	if (has_field(private,'finished')) {
	    return private.finished();
	} else {
	    print 'jenindex.abort(): no field private.finished()'
	    return F;
	}
    }

    public.getcurrentindex := function() {
	for (i in private.index) {
	    if (len(i)>0 && i==0) return F;		# not started yet
	}
	return private.index;
    }

#---------------------------------------------------------------------------
# Initialise the index:

    public.init := function (dim, axes=[], axes_label=[=], step=1) {
	wider private;
	private.dim := dim;				# e.g. [4,6,2,8]
	public.suspend(F);
	private.abort := F;				# switch
	private.once := F;				# switch
	private.axes := axes[1];			# may be vector
	for (axis in axes) {				# weed out doubles
	    if (!any(private.axes==axis)) private.axes := [private.axes,axis];
	}
	private.ndim := len(private.dim);		# nr of dimensions
	private.idim := 0;				# fastest running dim
	private.step := private.check_step(step);	# check first
	private.stepstep := 1;
	private.index := [=];				# indexing record
	dim1 := dim;
	nn := 1;
	private.stepsizes := [];			# 
	private.istepsizes := 1;			# index			
	for (i in ind(private.dim)) {
	    private.index[i] := 1;			# initialise
	    if (private.step<0) private.index[i] := private.dim[i];
	    if (any(private.axes==i)) {			# one of the slice axes
		private.index[i] := [];			# take entire dimension
		private.dim[i] := 0;			# indicate
		dim1[i] := 1;				# for nmax below
	    } else {
		private.stepsizes := [private.stepsizes,nn];	# in this order!
		nn *:= private.dim[i];				# in this order!
		if (private.idim==0 && private.dim[i]>1) {	# first only
		    private.idim := i;			# fastest actually running dim
	    	    private.index[i] -:= private.step;	# initialise
		}
	    }
	}
	private.iposmax := prod(dim1);			# total nr of 
	private.ipos := 0;				# overall position...
	if (private.iposmax<=0) {
	    print s := paste('init problem:',private);
	    fail(s);
	}
	private.progressframe := F;			# indicator
	if (private.showprogress) {			# only if required
	    private.make_progressframe();
	}
	private.deal_with_axes_label(axes_label);	# even if not provided
	# print 'init:',private;			# debugging
	return T;
    }

# Some helper functions:

    private.check_step := function (step=F) {
	if (step==0) step := 1;				# step==0 not allowed
	if (step>1) step := 1;				# only abs(step)==1 (?)
	if (step<-1) step := -1;			# only abs(step)==1 (?)
	return step;
    }

# Optional labels, displayed by progress control panel:
# If none provided ([=]), make default ones:

    private.deal_with_axes_label := function (ref axes_label=[=]) {
	wider private;
	private.text := F;				# see display_progress
	# if (!private.showprogress) return F;		# not needed...
	private.axes_name := field_names(axes_label);
	if (len(private.axes_name) == len(private.dim)) {
	    private.axes_label := axes_label;
	} else {
	    private.axes_label := [=];			# 
	    private.axes_name := ' ';			# just in case
	    for (i in ind(private.dim)) {
		name := spaste(i,'axis');		# ...?
		private.axes_name[i] := name;
		n := private.dim[i];
		private.axes_label[name] := ' ';
		if (n>0) {
		    private.axes_label[name] := split(paste([1:n]));
		    # print 'axis=',name,len(private.axes_label[name]);
		}
	    }
	}
	return T;
    }

#--------------------------------------------------------------------------
# Make a user display-and-control frame:

    public.user_message := function (text=' ') {
	wider private;
	if (is_boolean(private.progressframe)) {	# not defined
	    print '_index.user_message(): not active, ignored:',text;
	    return F;
	} else if (is_boolean(private.userframe)) {
	    private.userframe := frame(private.progressframe);
	    private.user_message := [=];
	    private.userbuttonframe := F;
	    private.usermessageframe := F;
	}
	if (is_boolean(private.userbuttonframe)) {
	    private.usermessageframe := frame(private.userframe);
	}
	n := 1 + len(private.user_message);
	private.user_message[n] := message(private.usermessageframe, 
					   text, width=300);
	return ref private.user_message[n];
    }

    public.user_button_frame := function () {
	wider private;
	if (is_boolean(private.progressframe)) {	# not defined
	    print '_index.user_button(): not active, ignored:',text;
	    return F;
	} else if (is_boolean(private.userframe)) {
	    private.userframe := frame(private.progressframe);
	    private.user_message := [=];
	    private.userbuttonframe := F;
	    private.usermessageframe := F;
	}
	if (is_boolean(private.userbuttonframe)) {
	    private.userbuttonframe := frame(private.userframe, side='right');
	    private.user_button := [=];
	    private.user_callback := [=];
	    private.userbuttonmessageframe := frame(private.userbuttonframe)
	    private.userbuttonmessage := message(private.userbuttonmessageframe)
	    private.userbuttonmessage -> text(' ');	# erase 'message'
	}
	return ref private.userbuttonframe;
    }


    public.user_button := function (text, ref callback=F, ref bagent=F, menu=F) {
	wider private;
	if (is_boolean(public.user_button_frame())) return F;	# problem
	n := 1 + len(private.user_button);
	if (is_boolean(bagent)) bagent := ref private.userbuttonframe;
	if (menu) {
	    private.user_button[n] := button(bagent,text, value=n, type='menu');
	} else {
	    private.user_button[n] := button(bagent,text, value=n);
	}
	private.user_callback[n] := callback;
	whenever private.user_button[n] -> press do {
	    n := $value;
	    if (private.is_suspended()) {		# only if suspended!
		# print 'user_button',n,'pressed';
		if (is_function(private.user_callback[n])) {
		    s := private.user_callback[n]();	# should return string!	
		    private.userbuttonmessage -> text(paste(s));  # display
		}
	    }
	}
	return ref private.user_button[n];		# ....?
    }

# Make progress frame:

    private.make_progressframe := function() {
	wider private;
	val private.progressframe := F;			# remove earlier frame
	private.progressframe := frame(title=private.origin);
	private.messageframe := frame(private.progressframe);
	private.message := message(private.messageframe, width=300);
	private.buttonframe := frame(private.progressframe, 
					   side='left', relief='raised');
	private.make_stepframe();
	private.userframe := F;				# see user_button

	#------------------------------------------------------------------------
	public.suspend(T);
	private.message -> text('press the green button to start\n')
	#------------------------------------------------------------------------

        if (!private.forwardonly) {
	    private.bw_button := button(private.buttonframe,'<<');
	    whenever private.bw_button->press do {
		private.go_backward();
	    }

	    private.bw1_button := button(private.buttonframe,'|<');
	    whenever private.bw1_button->press do {
		private.step_backward();
	    }
	}

	private.suspend_button := button(private.buttonframe,'suspend',
						background='yellow');
	whenever private.suspend_button->press do {
	    private.do_suspend();
	}

	private.fw1_button := button(private.buttonframe,'>|');
	whenever private.fw1_button->press do {
	    private.step_forward();
	}

	private.fw_button := button(private.buttonframe,'>>',
					 	background='green');
	whenever private.fw_button->press do {
	    private.go_forward();
	}

	private.abort_button := button(private.buttonframe,'break',
					  	background='red');
	whenever private.abort_button->press do {
	    private.do_abort();
	}
	private.update_stride_message();
	return T;
    }

# Helper functions for progress control:

    private.go_backward := function () {
	wider private;
        if (private.forwardonly) {
	    print 'mode is forward-only';
	} else if (private.is_suspended()) {
	    public.suspend(F);
	    private.once := F;
	    private.step := -abs(private.step);
	    # private.text :='continue backwards'
	    private.update_stride_message();
	}
	return T;
    }

    private.step_backward := function () {
	wider private;
        if (private.forwardonly) {
	    print 'mode is forward-only';
	} else if (private.is_suspended()) {
	    private.step := -abs(private.step);
	    # private.text := 'one step backward'
	    private.update_stride_message();
	    if (private.ipos+private.step>0) {
		public.suspend(F);
		private.once := T;
	    }
	}
	return T;
    }

    private.go_forward := function () {
	wider private;
	if (private.is_suspended()) {
	    public.suspend(F);
	    private.once := F;
	    private.step := abs(private.step);
	    # private.text := 'continue forwards'
	    private.update_stride_message();
	}
	return T;
    }

    private.step_forward := function () {
	wider private;
	if (private.is_suspended()) {
	    private.step := abs(private.step);
	    # private.text := 'one step forward'
	    private.update_stride_message();
	    if (private.ipos+private.step<=private.iposmax) {
		public.suspend(F);
		private.once := T;
	    }
	}
	return T;
    }

    private.do_suspend := function () {
	wider private;
	public.suspend(T);
	private.once := F;
	s := 'index.do_suspend(): suspend button pressed';
	print '\n\n',s,'\n\n';
	# private.text := 'suspend button pressed'
	return T;
    }

    private.do_abort := function () {
	wider private;
	# if (private.is_suspended()) {		# for safety?
	private.abort := T;	
	private.once := F;
	public.suspend(F);
	private.text := 'break out of the loop';
	# }						# for safety?
	return T;
    }

#--------------------------------------------------------------------------
# Make special frame for step-control and display:

    private.make_stepframe := function () {
	wider private;
	if (private.forwardonly) return T;		# frame not needed

	private.stepframe := frame(private.progressframe, 
					   side='left', relief='groove');
	private.stride_incr := button(private.stepframe,'+1');
	whenever private.stride_incr->press do {
	    private.stride_incr();
	}
	private.stride_decr := button(private.stepframe,'-1');
	whenever private.stride_decr->press do {
	    private.stride_decr();
	}
	private.stride_double := button(private.stepframe,'*2');
	whenever private.stride_double->press do {
	    private.stride_double();
	}
	private.stride_halve := button(private.stepframe,'/2');
	whenever private.stride_halve->press do {
	    private.stride_halve();
	}
	private.stride_dimens := button(private.stepframe,'stride');
	whenever private.stride_dimens->press do {
	    private.stride_dim();
	}
	private.stride_message := message(private.stepframe,'stride');
	return T;
    }

# Helper functions:

    private.stride_dim := function () {
	wider private;
        if (private.forwardonly) {
	    print 'mode is forward-only';
	} else if (private.is_suspended()) {
	    k := private.istepsizes +:= 1;
	    if (k>len(private.stepsizes)) k := 1;
	    private.step := private.stepsizes[k];
	    private.stepstep := abs(private.step);
	    private.istepsizes := k;
	    private.update_stride_message();
	}
	return T;
    }

    private.stride_incr := function () {
	return private.stride_mod(private.stepstep);
    }
    private.stride_decr := function () {
	return private.stride_mod(-private.stepstep);
    }
    private.stride_mod := function (stepstep=0) {
	wider private;
        if (private.forwardonly) { 
	    print 'mode is forward-only';
	} else if (private.is_suspended()) {
	    newstep := private.step + stepstep;
	    if (newstep==0) newstep := stepstep;
	    newpos := private.ipos + newstep;     # tentative   
	    if (newpos>0 && newpos<=private.iposmax) {  # OK
		private.step := newstep;          # modify
		private.update_stride_message();  
	    } else {
		print 'index.stride_mod(): no change:',newpos,private.iposmax;
	    }
	}
	return T;
    }

    private.stride_double := function () {
	wider private;
        if (private.forwardonly) {
	    print 'mode is forward-only';
	} else if (private.is_suspended()) {
	    private.step *:= 2;
	    private.update_stride_message();
	}
	return T;
    }

    private.stride_halve := function () {
	wider private;
        if (private.forwardonly) {
	    print 'mode is forward-only';
	} else if (private.is_suspended()) {
	    if (private.step<0) {
		private.step := as_integer((private.step-1)/2);
	    } else {
		private.step := as_integer((private.step+1)/2);
	    }
	    private.update_stride_message();
	}
	return T;
    }

# Helper function (displays current step, if possible):

    private.update_stride_message := function () {
	s := paste('stride=',private.step); 
	if (has_field(private,'stride_message')) {
	    private.stride_message -> text(s);
	}
    }

    public.get_stride_message := function () {
	s := paste('stride=',private.step);
	# print 'get_stride_message:',s; 
	return s;
    }

    public.get_suspend_message := function () {
	if (private.suspend) return 'suspended';
	return '.suspend.';
    }

# Helper function:

    private.is_suspended := function () {
	wider private;
	if (private.suspend) {
	    private.text := F;
	    return T;
	} else {
	    print s := paste('suspend loop first!')
	    private.text := s;
	    return F;
	}
    }


#-----------------------------------------------------------------------
# Get the contents of a field:

    public.get := function(fname) {
	if (has_field(private,fname)) return private[fname];
	print 'jenindex.get(): field not recognised:',fname;
	return F;
    }

    public.is_aborted := function() {return private.abort}
    public.is_suspended := function() {return private.suspend}


#-----------------------------------------------------------------------
# Get the next index-record 'index' (return F if finished, T if not):

    public.next := function (ref index, step=F, text=F) {
	# print '++++ next:',step,text;
	wider private;
	if (is_string(text)) private.text := text;	# new text given
	if (is_integer(step)) {				# new step given
	    private.step := private.check_step(step);	# before events!
	}

	if (private.showprogress) {
	    private.deal_with_events();
	} else {
	    private.deal_with_events();
	} 
	# NB: private.step may change in .deal_with_events()

	if (private.abort) return private.finished();	# clean up

	more := private.step_index();			# make a step
	if (!more) {					# F: finished
	    if (private.autofinish) {
	    	s := paste('finished',private.ipos,private.iposmax);
	    	if (private.showprogress) {
	    	    # print s;
	    	    private.message -> text(s);
	    	} else {
	    	    print s;
	    	}
	    	return private.finished();		# clean up
	    } else {
		s := 'the loop is finished but suspended!' 
		s := paste(s,'\n press the break button to escape')
		private.message -> text(s);		# display
		public.suspend(T);
	    }

	} else if (private.showprogress) {
	    private.display_progress ();
	}
	val index := private.index;			# incremented record		
	return T;					# T: not finished
       }

#-----------------------------------------------------------------------
# Deal with events (abort, suspend, continue, etc), see .next():

    private.deal_with_events := function() {
	wider private;

	# print 'send echo event:';
	private.echo -> echo();				# allow events
	await private.echo -> echo;			# wait

	while (private.suspend) {
	    # print 'send timer event, interval=0.3';
	    private.timer -> interval(0.3);
	    # private.timer -> interval(2);
	    await private.timer -> ready;
	}
	private.timer -> interval(0);			# disable timer

	if (private.once) {				# one step
	    private.once := F;
	    public.suspend(T);
	}
	return T;
    }

#-----------------------------------------------------------------------
# Clean up when finished:

    private.finished := function () {
	wider private;

	private.fw_button -> background('grey');	# no longer needed..
	private.abort_button -> background('grey');
	private.suspend_button -> background('grey');
	private.fw_button -> foreground('grey');
	private.abort_button -> foreground('grey');
	private.suspend_button -> foreground('grey');

	private.timer -> ready();			# just in case
	private.timer -> interval(0);			# disable timer
	val private.progressframe := F;			# remove frame
    	val private.echo := F;				# remove client
    	val private.timer := F;				# remove client
	private.progressframe -> unmap();		# Darrell's trick

	abort := private.abort;
	suspend := private.suspend;
	private := [=];
	private.abort := abort;				# can be tested 
	public.suspend(suspend);			# can be tested
	# print 'finished: private=',private;
	return F;					# mandatory
    }

#-----------------------------------------------------------------------
# Display the progress:

    public.get_progress_message := function () {
	s := public.getlabel(full=T);			# see below
	if (is_string(private.text)) {
	    # s := paste(s,'\n',private.text);          # '\n'
	    s := paste(s,private.text);                 # ....?               
	} else {
	    # s := spaste(s,'  \n');                    #....
	}
	return s;
    }

    private.display_progress := function () {
	s := public.get_progress_message();
	private.message -> text(s);			# display
	# print 'display_progress:',s;
	return T;
    }

# Part of it is also obtainable from outside:

    public.getlabel := function(full=F) {
	s := ' ';
	ii := [];
	first := T;
	for (i in ind(private.index)) {
	    k := private.index[i];
	    # print 'getlabel:',i,k;
	    if (len(k)==0) {
	    	ii[i] := 0;
	    } else if (k<=0) {
		ii[i] := k;
		if (!first) s := spaste(s,' ');		# separator
		s := spaste(s,private.axes_name[i],'-');
		first := F;
	    } else {
		ii[i] := k;
		if (!first) s := spaste(s,' ');		# separator
		s := spaste(s,private.axes_name[i]);
		cc := split(spaste(private.axes_label[i][k]),'');
		cc := cc[cc!='['];			# remove any [
		cc := cc[cc!=']'];			# remove any ]
		s := spaste(s,spaste(cc));		# repaste
		first := F;
	    }
	}
	if (full) {
	    s := spaste(s,'   ',ii,' ',private.ipos,'/',private.iposmax)
	    # print s;
	}
	return s;
    }

#---------------------------------------------------------------------
# Get a 'slice' of encoded (integer) index 'fields (ussed in jenplot)

    public.get_encoded := function(trace=F, dim=[4,0,0,5]) {
	test := T;
	if (has_field(private,'dim')) {
	    dim := private.dim;
	    test := F;
	}
	ii := ind(dim)[dim>0];		                # active dims
	if (len(ii)<=0 || len(ii)>2) {
	    print 'jenindex.get_encoded(): too many/few active indices!';
	    return F;
	} 

	rr := [=];                                      # output record
	subdim := dim[ii];
	rr.encoded := rep(0,prod(subdim));
	rr.encoded::shape := subdim;
	if (trace) print 'jenindex.get_encoded() dim=',dim,'->',subdim; 

	if (len(ii)==1) {
	    for (i in [1:subdim[1]]) {
		rr.encoded[i] := code := i;
		if (trace) {
		    index := public.decode_index(code, dim=dim);
		    print i,'code=',code,'-> index=',index;
		}
	    }
	} else if (len(ii)==2) {
	    ix := ii[1];
	    iy := ii[2];
	    if (!test) {
		rr.xdescr := private.axes_name[ix];
		rr.ydescr := private.axes_name[iy];
		rr.xannot := private.axes_label[ix];
		rr.yannot := private.axes_label[iy];
	    }
	    for (i in [1:subdim[1]]) {
		for (j in [1:subdim[2]]) {
		    code := public.encode_index([i,j], dim=subdim);
		    rr.encoded[i,j] := code;
		    if (trace) {
			index := public.decode_index(code, dim=dim, trace=F);
			print i,j,'code=',code,'-> index=',index;
		    }
		}
	    }
	}

	if (trace) print rr;
	return rr;                                      # return record
    }


# Translate given index (record) into ipos (integer):

    public.index2ipos := function(index=F, dim=[4,0,0,20], trace=F) {
	ii := ind(dim)[dim>0];
	if (trace) print 'index2ipos(): index=',index,' (dim=',dim,')';
	ipos := 1;
	mult := 1;
	for (i in ii) {
	    if (index[i]<=0 || index[i]>dim[i]) {
		print i,'jenindex.index2ipos: out of range:',index[i],dim[i];
	    }
	    ipos +:= (index[i]-1)*mult;
	    if (trace) print '..index2ipos:',index[i],'*',mult,'->ipos=',ipos;
	    mult *:= dim[i];
	}
	return ipos;
    }

# Encode the given index (record) into a unique integer (code):

    public.encode_index := function(index=F, dim=[4,0,0,20], trace=F) {
	ii := ind(dim)[dim>0];
	if (trace) print 'encode_index(): index=',index,' (dim=',dim,')';
	code := 0;
	mult := 1;
	for (i in ii) {
	    if (index[i]<=0 || index[i]>dim[i]) {
		print i,'jenindex.encode_index: out of range:',index[i],dim[i];
	    }
	    code +:= index[i]*mult;
	    if (trace) print '..encode:',index[i],'*',mult,'->',code;
	    # mult *:= dim[i];
	    mult *:= (1+dim[i]);
	}
	if (trace) {
	    decoded := public.decode_index(code, trace=F);
	    print '-> code=',code,'->',decoded;
	}
	return code;
    }

# Reverse of .encode_index();

    public.decode_index := function(code=F, dim=[4,0,0,20], trace=F) {
	ii := ind(dim)[dim>0];
	mult := prod(1+dim[ii]);
	if (trace) print 'decode_index(): code=',code,' (dim=',dim,')',mult;
	index := [=];
	for (i in ind(dim)) index[i] := [];
	for (i in [len(dim):1]) {               # reverse order
	    if (dim[i]<=0) next;                # inactive: skip
	    # mult /:= dim[i];
	    mult /:= (1+dim[i]);
	    index[i] := as_integer(code/mult); 
	    if (index[i]<=0 || index[i]>dim[i]) {
		print i,'jenindex.deccode_index: out of range:',index[i],dim[i];
	    }
	    if (trace) print '..decode:',code,'/',mult,'->',index[i];
	    code -:= mult*index[i];             # remainder
	}
	return index;
    }


#---------------------------------------------------------------------
# Set the control parameter private.iwos to such a value that it will
# produce the array with corresponding to the given index (record) at
# the next step. (Alternative: give the integer code of the encoded index).

    public.set_to_index := function (index=F, code=F, trace=F) {
	wider private;
	if (is_record(index)) {                  # index given: use it
	    # see below
	} else if (is_integer(code)) {           # code given -> index
	    index := public.decode_index(code, dim=private.dim, trace=trace);
	} else {                                 # neither given: error
	    s := paste('jenindex.set_to_index(',index,code,') error!');
	    return s;
	}
	ipos := public.index2ipos(index, dim=private.dim, trace=trace);
	private.ipos := ipos - private.step;     # see step_index() below
	s := paste('jenindex.set_to_index(',index,code,') -> ipos=',ipos);
	if (trace) print s;
	return s;
    }


#---------------------------------------------------------------------
# Index-stepping function (across dim boundaries):

    private.step_index := function() {
	wider private;

	newpos := private.ipos + private.step;		# tentative 

	debugprint := F;				# debugging
	if (debugprint) {
	    s := paste('step_index:',private.iposmax,private.dim);
	    s := paste(s,'step=',private.step);
	    print s := paste('\n',s,'ipos=',newpos);
	}

	if (newpos<=0 || newpos>private.iposmax) {
	    if (debugprint) print 'step_index: finished',newpos,private.iposmax;
	    return F;					# finished
	}

	private.ipos := newpos;				# actually inc/decrement
	decipos := private.ipos;			# to be used up below
	nn := private.iposmax;				# total product
	ii := ind(private.dim)[private.dim>1];		# running dims (>1) only

	if (len(ii)<=0) {				# no running dims
	    ii := ind(private.dim)[private.dim>0];	# active dims (>0)
	    private.index[ii] := 1;			# only possible value
	    s := paste(s,'no running dims: index=',private.index);
	    if (debugprint) print s;

	} else {					# some running dim(s)
	    for (j in [len(ii):1]) {			# backwards
		i := ii[j];
		if (debugprint) s := paste('-',i,imin,private.dim[i],':')
		    if (j==1) {				# fastest actually varying index
			private.index[i] := decipos;
		    } else {
			nn /:= private.dim[i];		# size of inner hypercube
			rem := (decipos-1)%nn; 		# remainder
			private.index[i] := 1+as_integer((decipos-rem)/nn); 
			if (debugprint) s := paste(s,decipos-1,'%',nn,'->',rem);
			decipos := rem+1;
		    }
		if (debugprint) print s := paste(s,'index[i]=',private.index[i]);
	    }
	}

	ipostest := T;
	if (ipostest) {                                 # testing only
	    ipos := public.index2ipos(private.index, dim=private.dim, trace=F);
	    if (ipos != private.ipos) {
		print 'index=',private.index,'ipos=',private.ipos,'!=',ipos;
	    }
	}

	return T;					# OK, continue
    }


#----------------------------------------------------------------------
# Finished. Initialise and return the public interface:

    return ref public;					# 

};						# closing bracket of jenindex
#=======================================================================
#=======================================================================




#==========================================================================
#================================================ Testing routine =========
#==========================================================================

test_jenindex := function (slice_axes="freq ifr") {
# test_jenindex := function (slice_axes="freq") {
    private := [=];
    public := [=];
    print 'test_jenindex: slice_axes=',slice_axes;

    private.index := jenindex('test_jenindex', 
				showprogress=T,
				autofinish=T, forwardonly=T);
    data_axes := "corr freq ifr time";
    dim := [4,16,5,10];

    slice_dims := [];				# 
    for (axis in slice_axes) {
	slice_dims := [slice_dims,ind(data_axes)[data_axes==axis]];
    }

    axes_label := [=];
    for (i in ind(data_axes)) {
	axis := data_axes[i];
  	axes_label[axis] := F;
	if (!any(axis==slice_axes)) {
	    ii := seq(dim[i]);
	    ss := ' ';
	    for (j in seq(dim[i])) ss[j] := spaste(j);
	    axes_label[axis] := ss;
	} 
    }

    # r := private.index.init(dim, slice_dims, axes_label); 
    r := private.index.init(dim, slice_dims); 
    if (is_fail(r)) fail(r);				# something wrong

    count := 0;
    while (private.index.next(index)) {	
	# do something
	print count+:=1,index;
    }
    if (private.index.is_aborted()) print 'status=aborted' 
    return ref private.index;
};
# index := test_jenindex();			# run test-routine




#=======================================================================
# Future work:
# better name: recordIndex.g (?)
# - ri := recordIndex()
# - ri.init()
#	forwardonly etc
# - ri.next(index)          used in while-loop, returns index record
# - index := ri.next_index()
# - slice := ri.next_slice()
# Incorporate the array to be navigated:
# - ri.array := function (ref array, ref flags=F, ref labels)
#                labels is record, with a field per array axis
# - ri.slice_axes (labels)


