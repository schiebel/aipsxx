# histogramgui: Gui for selection of data min and max, and display of histogram
# Copyright (C) 2002
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
# $Id: 
pragma include once;

include 'popuphelp.g'
include 'optionmenu.g'
include 'mathematics.g'

histogramgui := subsequence(xmin=0, xmax=1, array=unset, 
			  units='unknown', widgetset=dws, 
			    title='Unknown Image')  # Within viewer ddlws
{
    #Store constructor arguments etc.
     
    its := [=];
    its.whenevers := [];
    its.ws := widgetset;
    its.brightnessunit := units; 
    its.gui := [=];
    its.plot := [=];
    its.loghist := array;
    its.title := spaste(title, ' - Histogram (AIPS++)');
    its.plot.defaultzoom := 99.99;
    its.plot.totalpixels := -1;
    its.tol.scroll := 0.06;

    # Manage the widgets state;
    its.states := [=];                                         

    its.states.currentstate := 0;        #-1 - Problem (no data)
                                         #0 - Unselected
                                         #1 - Selected
                                         #2 - Being dragged
                                         #22 - About to be dragged
                                         #3 - Being resized (start)
                                         #4 - Being resized (end)
                                         #33 - About to be resized (start)
                                         #44 - About to be resized (end)
                                         #5 - About to be  created
                                         #55 - Being created

    its.states.startzoombox := F;
    its.states.log := T;                # Log by default
    its.states.startbusy := F;
    its.states.stopbusy := F;
    its.states.movebusy := F;
    its.states.dragbusy := F;

    its.states.medianmarker := F;
    its.states.meanmarker := F;
    
    its.states.cur := 0;                #0 - Normal
                                        #1 - Move
                                        #2 - Left Resize
                                        #3 - Right Resize

    its.plot.axis := -2;                #No box, axis or labels
    its.plot.just := 0;	                #Axes scaled independently
    its.thecolor := 7;                  #Default color

    its.stats := [=];
    its.stats.median := 0;
    its.stats.mean := 0;
    
    its.checksel := function() {
	wider its;	

        #Switch min and max if the thing is drawn the wrong way.
	if (its.plot.startsel > its.plot.stopsel) {
	    temp := its.plot.startsel;
	    its.plot.startsel := its.plot.stopsel;
	    its.plot.stopsel := temp;
	    its.redraw();
	}
    }

    its.buildgui := function() {
	wider its;
	its.ws.tk_hold();
		
	its.gui.frame := its.ws.frame(title=its.title, side='bottom', 
				      cursor='watch');
	its.gui.dismissframe := its.ws.frame(its.gui.frame, side='right', 
					     expand='x');
	its.gui.toolframe := its.ws.frame(its.gui.frame, side = 'bottom', 
					  relief = 'ridge', 
					  expand = 'x');

	its.gui.colorframe := its.ws.frame(its.gui.toolframe, side = 'left', 
					   expand = 'x');
	its.gui.scaleframe := its.ws.frame(its.gui.toolframe, side = 'left', 
					   expand ='x');
	its.gui.sigmaframe := its.ws.frame(its.gui.toolframe, side='left',
					   expand='x');
	its.gui.percentageframe := its.ws.frame(its.gui.toolframe, 
						side = 'left',expand='x');
	
	its.gui.labelframe := its.ws.frame(its.gui.frame, side ='top', 
					   expand='x');
	its.gui.cursorlabel := its.ws.label(its.gui.labelframe, 
					    text='Show current cursor');
	its.ws.popuphelp(its.gui.cursorlabel, 'Current cursor position (x)');

	its.gui.dismiss := its.ws.button(its.gui.dismissframe, type='dismiss', 
					 text='Dismiss');
	its.gui.reset := its.ws.button(its.gui.dismissframe, text='Reset');

	its.gui.rangelabel := its.ws.label(its.gui.percentageframe, 
					   'Show percentile: ');
	its.gui.percentageboxframe := its.ws.frame(its.gui.percentageframe, 
						   side = 'right', 
						   expand = 'x');
	its.gui.percentsymbol := its.ws.label(its.gui.percentageboxframe, '%');
	its.gui.range := its.ws.extendoptionmenu(its.gui.percentageboxframe, 
				   labels = ['<unset>', '95', '98', '99.9'],
				   relief = 'raised',
				   callback2 = its.checkpercentage,
			 hlp = 'Select percentage of pixels to show...',
		  hlp2 = 'e.g. Selecting 95% will cause the upper and lower 2.5% percent of pixels to be excluded from selection.',
	         		   borderwidth = 1);
	its.gui.firstsigmaframe := its.ws.frame(its.gui.sigmaframe, 
						side = 'left');
	its.gui.secondsigmaframe := its.ws.frame(its.gui.sigmaframe, 
						 side = 'right');
	
	its.gui.sigmalabel := its.ws.label(its.gui.firstsigmaframe, 
					   text='Show +/-:');

	its.gui.nsigma := its.ws.extendoptionmenu(its.gui.firstsigmaframe, 
				      labels = ['<unset>', '3', '5', '10'],
						  relief = 'raised',
						  callback2 = its.checksigma,
		    	  hlp = 'Select number of standard deviations...',
       			  hlp2 = 'Select the range of standard deviations from the mean / median to show', 
						  borderwidth = 1);
	its.sigmatext := its.ws.label(its.gui.firstsigmaframe, 'sigma');
	its.gui.whichsigma := its.ws.optionmenu(its.gui.secondsigmaframe, 
						labels = ['mean', 'median'],
						names = ['mean', 'median'],
						values = ['mean','median'],
						relief = 'raised',
						hlp = 'Crop using what as a starting point...',
						hlp2 = 'Selecting mean will cause the selection to be +- n sigma from the mean. Likewise for median.', 
						borderwidth = 1);
	its.gui.sigmatwolabel := its.ws.label(its.gui.secondsigmaframe, 
					      text := 'from:');

	its.gui.scalelabel := its.ws.label(its.gui.scaleframe, 
					   'Scale for count axis: ');
	its.gui.scaleframebox := its.ws.frame(its.gui.scaleframe, 
					      side = 'right');

	its.gui.scale := its.ws.optionmenu(its.gui.scaleframebox, 
					   labels = ['logarithmic','linear'], 
					   names = ['logarithmic','linear'], 
					   values = [T, F],
					   relief = 'raised',
					   hlp = 'Scale.', 
			     hlp2 = 'Select scale to use on the counts axis',
					   borderwidth = 1);

	its.gui.colorlabel := its.ws.label(its.gui.colorframe, 'Fill Color: ');
	its.gui.colorframebox := its.ws.frame(its.gui.colorframe, 
					      side = 'right');

	its.gui.colors := its.ws.extendoptionmenu(its.gui.colorframebox, 
			       labels = ['yellow', 'red', 'blue', 'green'], 
						  relief = 'raised',
						  callback2 = its.checkcolor,
						  hlp = 'Selection  color.', 
						  hlp2 = 'Select color to use to highlight a section of the histogram',
						  borderwidth = 1);
	
	its.gui.mainframe := its.ws.frame(its.gui.frame, side = 'top', 
					  borderwidth = 0, padx = 0, pady = 0);
	its.gui.plotarea := its.ws.pgplot(its.gui.mainframe, width=210, 
					  height=160, 
					  padx=1, pady=1);

	its.gui.scroller := its.ws.scrollbar(its.gui.mainframe, 
					     orient = 'horizontal',
					     width = 10);
	its.ws.popuphelp(its.gui.scroller, 'Plot area control.... \n\n- To select a region, click and drag using the left (Button 1) mouse button. Once a region is selected, you can move the region by dragging in the middle or resize the ends of the region by dragging them or clicking outside the region.\n\n- You can scroll through x using the scroll bar. Zooming inside the plot area is controlled by the middle (Button 2) mouse button. Clicking once with Button - 2 allows you to drag out a zoom region and clicking again zooms into the new region. Clicking <Control - Button - 2> allows you to unzoom.');
	its.gui.frame->cursor('top_left_arrow');
	its.ws.tk_release();
	
	if (its.states.currentstate != -1) {
	    its.autozoom();
	    its.scroll();
	}
	its.redraw();
	
	#Binds
	its.gui.plotarea->bind('<Button-1>', 'start');
	its.gui.plotarea->bind('<Button-2>', 'zoom');
	its.gui.plotarea->bind('<ButtonRelease-1>', 'stop');
	its.gui.plotarea->bind('<B1-Motion>', 'drag');
	its.gui.plotarea->bind('<Motion>', 'move');
	its.gui.plotarea->bind('<Control-Button-2>', 'unzoom');
	
	#Whenevers	
	whenever its.gui.dismiss->press do {
	    self.dismiss();
	}
	its.pushwhenever();

	whenever its.gui.plotarea->move do {
       	    if (!its.states.movebusy && its.states.currentstate != -1) {

		its.states.movebusy := T;		
		its.plot.grabevent := $value;
	        
		if (its.states.startzoombox) {
		    
		    if ( (  its.plot.grabevent.world[1] > 
			  its.plot.totalwindow[1]) &&
			(its.plot.grabevent.world[1] < 
			 its.plot.totalwindow[2]) &&
			(its.plot.grabevent.world[2] > 
			 its.plot.totalwindow[3]) && 
			(its.plot.grabevent.world[2] < 
			 its.plot.totalwindow[4]) ) {
			
			its.plot.zoomboxx2 := its.plot.grabevent.world[1];
			its.plot.zoomboxy2 := its.plot.grabevent.world[2];
			
			its.redraw(F);
			its.gui.plotarea->sfs(2);
			its.gui.plotarea->rect(its.plot.zoomboxx, 
					       its.plot.zoomboxx2, 
					       its.plot.zoomboxy, 
					       its.plot.zoomboxy2);
		    } else if ( (its.plot.grabevent.world[1] > 
				 its.plot.totalwindow[1]) &&
			       (its.plot.grabevent.world[1] < 
				its.plot.totalwindow[2]) &&
			       (its.plot.grabevent.world[2] < 
				its.plot.totalwindow[3])
			       ) {

			its.plot.zoomboxx2 := its.plot.grabevent.world[1];
			its.plot.zoomboxy2 := its.plot.totalwindow[3];
			
			its.redraw(F);
			its.gui.plotarea->sfs(2);
			its.gui.plotarea->rect(its.plot.zoomboxx, 
					       its.plot.zoomboxx2, 
					       its.plot.zoomboxy, 
					       its.plot.zoomboxy2);

		    }

		} else {
		    
		    if (!((its.states.currentstate == 55) || 
			  (its.states.currentstate == 4) || 
			  (its.states.currentstate == 3) || 
			  (its.states.currentstate == 2))) {
		   its.gui.cursorlabel->text(sprintf("X-Position: %5.2f %s", 
						 its.plot.grabevent.world[1], 
						     its.brightnessunit));
		    }
		    its.checkifresize(its.plot.grabevent);
		}
	    }
	    its.states.movebusy := F;
	}
	its.pushwhenever();
	
	
	whenever its.gui.plotarea->start do {
	    if (!its.states.startbusy && its.states.currentstate != -1) {
		
		its.states.startbusy := T;
		its.plot.starttemp := $value;
	
		if (its.states.currentstate == 0) {
		    its.states.currentstate := 5;
		}
		else if ((its.states.currentstate == 33) || 
			 (its.states.currentstate == 44)) {
		    its.handleresize(its.plot.starttemp);
		}
		else if (its.states.currentstate == 22) {
		    its.handlemove(its.plot.starttemp);
		}
		
		else if(its.states.currentstate == 1) {
		    its.handleclickresize(its.plot.starttemp);
		}
	    }
	    its.states.startbusy:=F;
	}
	its.pushwhenever();
	
	
	whenever its.gui.plotarea->stop do {
	   if (!its.states.stopbusy && its.states.currentstate != -1) { 

	       its.states.stopbusy := T;
	       its.plot.stoptemp := $value;

	       if ((its.states.currentstate == 2) || 
		   (its.states.currentstate == 3) || 
		   (its.states.currentstate == 4)) {

		   its.states.currentstate := its.states.currentstate * 11;
		   its.setminmax(its.plot.startsel, its.plot.stopsel);

	       } else if (its.states.currentstate == 5) {
		   its.states.currentstate := 0;
	       } else if (its.states.currentstate == 55) {
		   its.plot.stopsel := its.plot.stoptemp.world[1];
		   its.checksel();

		   if ((its.plot.stopsel - its.plot.startsel) 
		       > 0.02 * its.plot.totalx) {
		       its.states.currentstate := 1;
		       its.setminmax(its.plot.startsel, its.plot.stopsel);
		   } else {
		       its.states.currentstate := 0;
		   }
	       }

	       its.redraw();
	       its.states.stopbusy := F;
	   }
	}
	its.pushwhenever();

	whenever its.gui.plotarea->drag do {  
	    if (!its.states.dragbusy && 
		its.states.currentstate != -1) {
		
		its.plot.tempdrag := $value;
		its.states.dragbusy:=T;
		
		deactivate its.whenevers[5]; #This whenever - seemed to help		   
		
		its.gui.cursorlabel->text(sprintf("Min:%5.2f, Max:%5.2f (%s)", 
		      			  its.plot.startsel, its.plot.stopsel
						  ,its.brightnessunit));
		
		if (its.states.currentstate==2) {
		    its.handlemove(its.plot.tempdrag);   #Dragging
		} else if (its.states.currentstate==3) {
		    its.handleresize(its.plot.tempdrag); #Do the start resize
		} else if (its.states.currentstate==4) {
		    its.handleresize(its.plot.tempdrag); #Do the end resize
		} else if ((its.states.currentstate==5)
			   ||(its.states.currentstate==55)) {
		    its.makenewsel(its.plot.tempdrag); #Do the creation
		}
		
		activate its.whenevers[5] ;	#This whenever
		its.states.dragbusy:=F;
	    }
	}
	its.pushwhenever();
	
	whenever its.gui.plotarea->unzoom do {
	    if (its.states.currentstate != -1) {

		if (its.states.currentstate == 0) {
		    its.autozoom();
		} else {
		    #normal
		    temp := its.getmiddle(its.plot.defaultzoom);	    
		    its.plot.zoomstart := temp[1];
		    its.plot.zoomend := temp[2];
		    
		    its.plot.yzoomstart := its.plot.ymin;
		    its.plot.yzoomend := its.plot.ymax;

		    #Then check we are showing all of the selection
		    if (its.plot.startsel < its.plot.zoomstart) {
			its.plot.zoomstart := its.plot.startsel;
		    }
		    if (its.plot.stopsel > its.plot.zoomend) {
			its.plot.zoomend := its.plot.stopsel;
		    }

                    #Then add a bit
		    buffer := 
			(abs (its.plot.zoomend - its.plot.zoomstart) * 0.15);
		    its.plot.zoomstart := its.plot.zoomstart - buffer;
		    its.plot.zoomend := its.plot.zoomend + buffer;
		    its.plot.zoomrange := 
			abs(its.plot.zoomend - its.plot.zoomstart);
		}

		its.plot.sliderstart := 
		    its.plot.zoomstart - (0.15 * its.plot.zoomrange);
		its.plot.sliderend := 
		    its.plot.zoomend + (0.15 * its.plot.zoomrange);
		its.plot.sliderrange := 
		    abs(its.plot.zoomend - its.plot.zoomstart);
		
		its.slide();
		its.redraw();
		}
	}
	its.pushwhenever();

	whenever its.gui.plotarea->zoom do {
	    if (its.states.startzoombox) {
		its.states.startzoombox := F;

		if ( (its.plot.zoomboxx2 > its.plot.totalwindow[1]) &&
		    (its.plot.zoomboxx2 < its.plot.totalwindow[2]) &&
		    (its.plot.zoomboxy2 > its.plot.totalwindow[3]) && 
		    (its.plot.zoomboxy2 < its.plot.totalwindow[4]) ) {
		    
		    its.plot.zoomboxx2 := $value.world[1];
		    its.plot.zoomboxy2 := $value.world[2];
		}
		
		if (its.plot.zoomboxx < its.plot.zoomboxx2) {

		    its.plot.zoomstart := its.plot.zoomboxx;
		    its.plot.zoomend := its.plot.zoomboxx2;

		} else {
		    its.plot.zoomstart := its.plot.zoomboxx2;
		    its.plot.zoomend := its.plot.zoomboxx;
		}

		if (its.plot.zoomboxy < its.plot.zoomboxy2) {
		    its.plot.yzoomstart := its.plot.zoomboxy;
		    its.plot.yzoomend := its.plot.zoomboxy2;
		} else {
		    its.plot.yzoomstart := its.plot.zoomboxy2;
		    its.plot.yzoomend := its.plot.zoomboxy;
		}
		
		if (its.states.log) {
		    its.plot.yzoomstart := 10 ^ its.plot.yzoomstart;
		    its.plot.yzoomend := 10 ^ its.plot.yzoomend;
		}

		its.plot.zoomrange := 
		    abs(its.plot.zoomend - its.plot.zoomstart);
		its.plot.yzoomrange := 
		    abs(its.plot.yzoomend - its.plot.yzoomstart);
		    
		its.slide();
		its.redraw();

	    } else {
		its.states.startzoombox := T;

		its.plot.zoomboxx := $value.world[1];
		its.plot.zoomboxy := $value.world[2];

	    }
	    
	    its.redraw();
	}
	its.pushwhenever();

	whenever its.gui.scroller->scroll do {
	    redrawsc := F;
	    if (its.states.currentstate != -1){
		temp := split($value);

		if (temp[2] == 'scroll') {
		    
		    if ((temp[3] == '-1') && 
			(its.plot.zoomstart > its.plot.sliderstart)) {
			its.plot.zoomstart := 
			    its.plot.zoomstart - (its.plot.zoomrange * 0.05);

			its.plot.zoomend := 
			    its.plot.zoomstart + its.plot.zoomrange;
			redrawsc := T;
		    }
		    else if ((temp[3] == '1') && 
			     ((its.plot.zoomstart + its.plot.zoomrange) 
						  < (its.plot.sliderend))) {
			its.plot.zoomstart := 
			    its.plot.zoomstart + (its.plot.zoomrange * 0.05);
			its.plot.zoomend := 
			    its.plot.zoomstart + its.plot.zoomrange;
			redrawsc := T;
		    }

		} else if (temp[2] == 'moveto') {
		    relativestart := as_float(temp[3]);

		    if ((((relativestart*its.plot.sliderrange) 
			  + its.plot.sliderstart) 
			 > its.plot.sliderstart) && 
			((relativestart * its.plot.sliderrange) 
			 + its.plot.sliderstart + its.plot.zoomrange < 
			 its.plot.sliderend) ) {
	   
			its.plot.zoomstart := 
			    (relativestart * its.plot.sliderrange) + 
				its.plot.sliderstart;
			its.plot.zoomend := 
			    its.plot.zoomstart + its.plot.zoomrange;
			redrawsc := T;
		    }
		    
		}
	    }
	    if (redrawsc) {
		its.slide();
		its.redraw();
	    }
	}
	its.pushwhenever();
	
	whenever its.gui.frame->resize do {
	    its.redraw();
	}
	its.pushwhenever();

	whenever its.gui.reset->press do {
	    if (its.states.currentstate != -1) {
		selection :=  [its.plot.xmin, its.plot.xmax];
		its.resetcontrols();
		its.setselection(selection);
		its.autozoom();
		its.redraw();
		its.setminmax(selection[1], selection[2]);
		its.slide();
	    } 
	}
	its.pushwhenever();

	whenever its.gui.scale->select do {
	    if (its.states.currentstate != -1) {
		its.states.log := $value.value;
		if (its.states.log) its.updatelog();
		its.redraw();
	    }
	}
	its.pushwhenever();

	whenever its.gui.nsigma->select do {
	    if (its.states.currentstate != -1) {

		temp := $value.value;

		its.gui.range.selectlabel('<unset>');

		if (temp == '<unset>') {
		    its.states.meanmarker := F;
		    its.states.medianmarker := F;
		    newSelection := [its.plot.xmin, its.plot.xmax];
		    its.setselection(newSelection);
		    its.setminmax(newSelection[1], newSelection[2]); 
		    its.autozoom();
		    
		    its.redraw();
		} else {

		    if (its.gui.whichsigma.getlabel() == 'mean') 
			its.states.meanmarker := T;
		    else if (its.gui.whichsigma.getlabel() == 'median') 
			its.states.medianmarker := T;

		    its.getsigma(as_float(temp), 
				 its.gui.whichsigma.getlabel());
		    
		}
	    }
	}
	its.pushwhenever();
	
	
	whenever its.gui.whichsigma->select do {
	    if (its.states.currentstate != -1) {
		temp := $value.value;

		if ((its.gui.nsigma.getlabel()) != '<unset>') {
		    its.gui.range.selectlabel('<unset>');
		    if (temp == 'mean') {
			its.states.meanmarker := T;
			its.states.medianmarker := F;
		    } else if (temp == 'median') {
			its.states.medianmarker := T;
			its.states.meanmarker := F;
		    }
		    its.getsigma(as_float(its.gui.nsigma.getlabel()), temp);
		}
	    }
	}
	its.pushwhenever();   
	    
	whenever its.gui.range->select do {
	    if (its.states.currentstate != -1) {
		
		temp := $value.value;
		its.gui.nsigma.selectlabel('<unset>');
		its.states.meanmarker := F;
		its.states.medianmarker := F;

		if (temp == '<unset>') {

		    newSelection := [its.plot.xmin, its.plot.xmax];
		    its.setselection(newSelection, forcenosel = T);
		    its.setminmax(newSelection[1], newSelection[2]); 
		    its.autozoom();
		    its.redraw();

		} else {
		    newSelection := its.getmiddle(as_float(temp));
		    its.setselection(newSelection, forceselection = T);
		    its.autozoom();
		    its.redraw();
		    its.setminmax(newSelection[1], newSelection[2]); 

		}
	    }
	}
	its.pushwhenever();

	whenever its.gui.colors->select do {
	    if (its.states.currentstate != -1) {
		c := to_lower(its.gui.colors.getlabel());
		#Standard colors...
		if (c == 'yellow') its.thecolor := 7;
		else if (c == 'red') its.thecolor := 2;
		else if (c == 'green') its.thecolor := 3;
		else if (c == 'blue') its.thecolor := 4;
		else {
		    its.thecolor := 20 + its.gui.colors.getindex();
		}
		its.redraw();
	    }
	}
	its.pushwhenever();
    }
    
    
    its.slide := function() {
	wider its;
	relativestart := abs(its.plot.zoomstart - its.plot.sliderstart) / 
	    its.plot.sliderrange;
	relativewidth := its.plot.zoomrange / its.plot.sliderrange;

	its.gui.scroller->view([relativestart, relativestart + relativewidth]);
    }

    
    its.getsigma := function(n, from = 'mean') {
	wider its;

	if (from == 'mean') {
	    if (is_boolean(its.plot.mean) || is_boolean(its.plot.stddev)) {
		
		if (is_boolean(its.plot.mean) && is_boolean(its.plot.stddev)) {
		    self->newstats(['mean', 'stddev']);
		} else if (is_boolean(its.plot.mean)) {
		    self->newstats(['mean']);
		} else if (is_boolean(its.plot.stddev)) {
		    self->newstats(['stddev']);
		}

		#Needed so that setstats can pick up when the stats arrive
		its.states.oldstate := its.states.currentstate;
		its.states.waitingforstats := T;
		its.states.currentstate := -1;
		its.redraw();

	    } else {
		#Everything is ok. 
		newsel := 
		    [its.plot.mean - 
		     (as_float(its.gui.nsigma.getlabel()) * its.plot.stddev), 
		     its.plot.mean + (as_float(its.gui.nsigma.getlabel()) 
				      * its.plot.stddev)];

		its.setselection(newsel);
		its.setminmax(newsel[1], newsel[2]);
		its.autozoom();
		its.redraw();
	    } 
	    
	} else if (from == 'median') {
	    if (is_boolean(its.plot.median) || is_boolean(its.plot.stddev)) {

		if (is_boolean(its.plot.median) && 
		    is_boolean(its.plot.stddev)) {
		    
		    self->newstats(['median', 'stddev']);
		} else if (is_boolean(its.plot.median)) {
		    self->newstats(['median']);
		} else if (is_boolean(its.plot.stddev)) {
		    self->newstats(['stddev']);
		}
		
		#Needed so that setstats can pick up when the stats arrive
		its.states.oldstate := its.states.currentstate;
		its.states.waitingforstats := T;
		its.states.currentstate := -1;
		its.redraw();

	    } else {
		#Everything is ok
		newsel := 
		    [its.plot.median - 
		     (as_float(its.gui.nsigma.getlabel()) * its.plot.stddev), 
		     its.plot.median + (as_float(its.gui.nsigma.getlabel()) 
					* its.plot.stddev)];
		its.setselection(newsel);
		its.setminmax(newsel[1], newsel[2]);
		its.autozoom();
		its.redraw();

	    }
	}
    }

    its.autozoom := function () {
	wider its;

	if (its.states.currentstate == 0) {
	    #Autozoom with no selection

	    #Get the defaultzoom
	    temp := its.getmiddle(its.plot.defaultzoom);	    
	    its.plot.zoomstart := temp[1];
	    its.plot.zoomend := temp[2];
	    its.plot.zoomrange := abs(its.plot.zoomend - its.plot.zoomstart);
	    
	    its.plot.yzoomstart := its.plot.ymin;
	    its.plot.yzoomend := its.plot.ymax;

	    #Then add a bit
	    buffer := (abs (its.plot.zoomend - its.plot.zoomstart) * 0.15);
	    its.plot.zoomstart := its.plot.zoomstart - buffer;
	    its.plot.zoomend := its.plot.zoomend + buffer;

	} else {
	    #Autozoom around selection
	    buffer := (abs (its.plot.stopsel - its.plot.startsel) * 0.15);
	    its.plot.zoomstart := its.plot.startsel - buffer;
	    its.plot.zoomend := its.plot.stopsel + buffer;
	}

	#Default to min max on y
	its.plot.zoomrange := abs(its.plot.zoomend - its.plot.zoomstart);
	its.plot.yzoomstart := its.plot.ymin;
	its.plot.yzoomend := its.plot.ymax;
	its.plot.yzoomrange := abs(its.plot.ymax - its.plot.ymin);

	#Slider update
	if ((its.plot.zoomstart - (its.plot.zoomrange * 0.15)) < 
	    its.plot.xmin) {
	    its.plot.sliderstart := 
		its.plot.zoomstart - (its.plot.zoomrange * 0.15);
	} else {
	    its.plot.sliderstart := its.plot.xmin;
	}

	if ((its.plot.zoomend + (its.plot.zoomrange * 0.15)) > 
	    its.plot.xmax) {
	    its.plot.sliderend := 
		its.plot.zoomend + (its.plot.zoomrange * 0.15);
	} else {
	    its.plot.sliderend := its.plot.xmax;
	}

	its.plot.sliderrange := abs(its.plot.sliderend - its.plot.sliderstart);
	its.slide();
    }
    
    its.getmiddle := function(percentage) {
	wider its;
	
	
	chopoff := ( (100 - percentage) / 100 ) * its.totalpixels();
	chopoffside := chopoff / 2;
	
	#Off the start
	choppedstart := 0;
	indexstart := 0;
	
	while (choppedstart < chopoffside) {
	    indexstart := indexstart + 1;
	    choppedstart := choppedstart + (its.hist.counts[indexstart]);
	}
	
	#off the end
	choppedend := 0;
	indexend := len(its.hist.counts) + 1;
	
	while (choppedend < chopoffside) {
	    indexend := indexend - 1;
	    choppedend := choppedend + (its.hist.counts[indexend]);
	}
	
	#Just in case nothing needed to be chopped.
	if (indexstart == 0) indexstart := 1; 
	if (indexend == (len(its.hist.counts) +1)) 
	    indexend := len(its.hist.counts);

	return[its.hist.values[indexstart], its.hist.values[indexend]];
	
    }
    
    its.setminmax := function(xmin, xmax) {
	
	wider its;
	self->change([xmin, xmax]);
    }
    

    its.pushwhenever := function() {
	wider its;
	its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
	return T;    
    }
    
    
    its.checkifresize := function(evvalue) {
	
	wider its;
	its.states.oldcur := its.states.cur;

	if (its.states.currentstate != 0) {
	    its.states.tempinybounds := F;
	    
	    if ((evvalue.world[2] < its.plot.totalwindow[4]) 
		&& (evvalue.world[2] > its.plot.totalwindow[3])) {	       
		its.states.tempinybounds := T;
		its.states.cur := 0;		
		its.states.currentstate := 1;
	    } else {
		its.states.cur := 0;
		its.states.currentstate := 1;
	    }
	    
	    if ((abs(evvalue.world[1]-its.plot.startsel) 
		 < (0.025 * its.plot.totalx)) 
		&& its.states.tempinybounds) {		 
		its.states.currentstate := 33;		    		    
		its.states.cur := 2;

	    }
	    
	    if ((abs(evvalue.world[1]-its.plot.stopsel) 
		 < (0.025 * its.plot.totalx)) 
		&& its.states.tempinybounds) {   
		its.states.currentstate := 44;
		its.states.cur := 3;

	    }
	    
	    if ((its.states.currentstate ==  1) 
		&& (evvalue.world[1] > its.plot.startsel) 
		&& (evvalue.world[1] < its.plot.stopsel) 
		&& (evvalue.world[1] > its.plot.totalwindow[1] )
		&& (evvalue.world[1] < its.plot.totalwindow[2] )
		&& (its.states.tempinybounds)) {
		its.states.cur := 1;
		its.states.currentstate := 22;
	       
	    }
	    
	}
	
	if (its.states.currentstate == 0) {
	    its.states.cur := 0;
	}
	
	if (its.states.oldcur != its.states.cur) {
	    if (its.states.cur == 0 ) {
		its.gui.frame->cursor('top_left_arrow');
	    } else if (its.states.cur == 1 ) {
		its.gui.frame->cursor('crosshair');
	    } else if (its.states.cur == 2 ) {
		its.gui.frame->cursor('right_side');
	    } else if (its.states.cur == 3 ) {
		its.gui.frame->cursor('left_side');
	    }
	}
    }
    
    its.updatelog := function() {
	wider its;
	
	for (i in 1:len(its.hist.counts)) {	    
	    its.loghist.counts[i] := log(its.hist.counts[i]);	    
	} 
    }
    
    its.reset := function () {
	wider its;	   
	its.states.currentstate := 0;
	its.redraw();
    }
    
    its.makenewsel := function (value)
    {
	wider its;
	if (its.states.currentstate == 5) { 
	    if ( (value.world[1] > its.plot.totalwindow[1]) 
		&& (value.world[1] < its.plot.totalwindow[2])
		&& (value.world[2] > its.plot.totalwindow[3]) 
		&& (value.world[2] < its.plot.totalwindow[4]) ) { 
		its.plot.startsel := value.world[1];
		its.states.currentstate := 55;
	    }
	}
	
	if (its.states.currentstate == 55) {

	    if (value.world[1] > (its.plot.totalwindow[2] 
				  - (0.06 * its.plot.totalx))) {
		its.plot.zoomend := its.plot.totalwindow[2] 
		    + (0.06 * its.plot.totalx);
		its.plot.zoomrange := abs(its.plot.zoomend 
					  - its.plot.zoomstart);

		if (its.plot.zoomend > its.plot.sliderend) {
		    its.plot.sliderend := its.plot.zoomend;
		    its.plot.sliderrange := 
			abs(its.plot.sliderend - its.plot.sliderstart);
		    its.slide();
		}
	    } else if (value.world[1] < (its.plot.totalwindow[1] 
					 + (0.1 * its.plot.totalx))) {
		its.plot.zoomstart := 
		    its.plot.totalwindow[1] - (0.1 * its.plot.totalx);
		its.plot.zoomrange := 
		    abs(its.plot.zoomend - its.plot.zoomstart);
		if (its.plot.zoomstart < its.plot.sliderstart) {
		    its.plot.sliderstart := its.plot.zoomstart;
		    its.plot.sliderrange := 
			abs(its.plot.sliderend - its.plot.sliderstart);
		    its.slide();
		}
	    }

	    
	    its.plot.stopsel := value.world[1];

	    its.redraw(shading=F);

            #Check for no 'backwards' dragging (R -> L)
	    if (its.plot.startsel > its.plot.stopsel) { 
		its.setminmax(its.plot.stopsel, its.plot.startsel);
	    } else {
		its.setminmax(its.plot.startsel, its.plot.stopsel);
	    }

	}
    }
	
    its.handleclickresize := function(value) {
	wider its;
	
	if (value.world[2] > its.plot.totalwindow[3] 
	    && value.world[2] < its.plot.totalwindow[4]) {
	    if (value.world[1] > its.plot.stopsel) {
		its.plot.stopsel := value.world[1];
		if (its.gui.range.getlabel() != '<unset>') {
		    its.gui.range.selectlabel('<unset>');
		    its.states.meanmarker := F;
		    its.states.medianmarker := F;
		}
		if (its.gui.nsigma.getlabel() != '<unset>') {
		    its.gui.nsigma.selectlabel('<unset>');
		    its.states.meanmarker := F;
		    its.states.medianmarker := F;
		}
	    } else if (value.world[1] < its.plot.startsel) {
		its.plot.startsel := value.world[1];
		if (its.gui.range.getlabel() != '<unset>') {		 
		    its.gui.range.selectlabel('<unset>');
		    its.states.meanmarker := F;
		    its.states.medianmarker := F;
		}
		if (its.gui.nsigma.getlabel() != '<unset>'){
		    its.gui.nsigma.selectlabel('<unset>');
		    its.states.meanmarker := F;
		    its.states.medianmarker := F;
		}
	    }
	    
	    its.setselection([its.plot.startsel, its.plot.stopsel]);
	    its.setminmax(its.plot.startsel, its.plot.stopsel);
	}
    }
    
    its.handleresize := function(value) {
	wider its;
	

	#About to be resized
	if (its.states.currentstate == 33) {
	    its.states.currentstate := 3;
	    its.plot.widthsel := abs(its.plot.stopsel - its.plot.startsel);
	}
	
	if (its.states.currentstate == 44) {
	    its.states.currentstate := 4;
	    its.plot.widthsel := abs(its.plot.stopsel - its.plot.startsel);
	}
	
	#End being resized
	if (its.states.currentstate == 4) {
	    if ((value.world[1] > its.plot.startsel)) {

		#Moving off to the right of screen??
		if (value.world[1] > (its.plot.totalwindow[2] - 
				      (its.tol.scroll * its.plot.zoomrange))) {

		    #Can we move or are we at the end of the slider run? 
		    if ((its.plot.totalwindow[2] + 
			 (its.tol.scroll * its.plot.zoomrange)) < 
			its.plot.sliderend) {
			
			#Can move:
			its.plot.zoomend := 
			    its.plot.totalwindow[2] +
				 (its.tol.scroll * its.plot.zoomrange);
			its.plot.zoomrange := 
			    abs(its.plot.zoomend - its.plot.zoomstart);

			its.plot.stopsel := value.world[1];
		    } else {
			#End of slider:
			its.plot.zoomend := its.plot.sliderend;
			its.plot.zoomrange := 
			    abs(its.plot.zoomend - its.plot.zoomstart);

			if (value.world[1] < its.plot.sliderend) {
			    its.plot.stopsel := value.world[1];
			} else {
			    its.plot.stopsel := its.plot.sliderend;
			}

		    }
		    its.slide();
		
		#Or moving off to left of screen?
		} else if (value.world[1] < (its.plot.totalwindow[1] +
				(its.tol.scroll * its.plot.zoomrange))) {
		    
		    #We should be able to move since we are > startsel
		    if ((its.plot.totalwindow[1] - 
			 (its.tol.scroll * its.plot.zoomrange)) > 
			its.plot.startsel) {
			
			#Can move:
			its.plot.zoomstart := 
			    its.plot.totalwindow[1] - 
				(its.tol.scroll * its.plot.zoomrange);
			its.plot.zoomend := 
			    its.plot.totalwindow[2] - 
				(its.tol.scroll * its.plot.zoomrange);
			its.plot.zoomrange := 
			    abs(its.plot.zoomend - its.plot.zoomstart);

			its.plot.stopsel := value.world[1];
		    } else {
			#Can't move:
			#Move the window
			its.plot.zoomstart := 
			    its.plot.totalwindow[1] - 
				(its.tol.scroll * its.plot.zoomrange);
			its.plot.zoomrange := 
			    abs(its.plot.zoomend - its.plot.zoomstart);
			
			#Update our position
			if (value.world[1] > its.plot.startsel) {
			    its.plot.stopsel := value.world[1];
			} else {
			    its.plot.stopsel := 
				its.plot.startsel + 
				    (its.tol.scroll * its.plot.zoomrange);
			}
		    }
		    
		} else {
		    its.plot.stopsel := value.world[1];
		}

	    }
	    
	    if ((its.gui.range.getlabel() != '<unset>') || 
		(its.gui.nsigma.getlabel() != '<unset>')) {
		its.unsetboth();
	    }
	    
	    its.slide();
	    its.redraw(shading = F);
	    its.setminmax(its.plot.startsel, its.plot.stopsel);
	}
	
	#Start being resized
	if (its.states.currentstate == 3) {
	    if ( (value.world[1] < its.plot.stopsel)) {

		#Are we going past the right hand side of view window?
		if (value.world[1] > (its.plot.totalwindow[2] -
				      (its.tol.scroll * its.plot.zoomrange))) {

		    #Can we move?
		    if (its.plot.totalwindow[2] + 
			(its.tol.scroll * its.plot.zoomrange) < 
			its.plot.stopsel ) { 
			#Can move
			its.plot.zoomend := 
			    its.plot.zoomend + 
				(its.tol.scroll * its.plot.zoomrange);
			its.plot.zoomstart := 
			    its.plot.zoomstart + 
				(its.tol.scroll * its.plot.zoomrange);
			its.plot.zoomrange := 
			    abs(its.plot.zoomend - its.plot.zoomstart);
			its.plot.stopsel := value.world[1];
		    } else {
			#Can't move
                        #Move the window
			its.plot.zoomend := 
			    its.plot.totalwindow[2] + 
				(its.tol.scroll * its.plot.zoomrange);
			its.plot.zoomrange := 
			    abs(its.plot.zoomend - its.plot.zoomstart);
			
			#Update our position
			if (value.world[1] < its.plot.stopsel) {
			    its.plot.startsel := value.world[1];
			} else {
			    its.plot.startsel := 
				its.plot.stopsel - 
				    (its.tol.scroll * its.plot.zoomrange);
			}

		    } 

		#Are we going past the left hand side of the view window?
		} else if (value.world[1] < 
			   (its.plot.totalwindow[1] + 
			    (its.tol.scroll * its.plot.zoomrange))) {
		    #Are we ok for move?
		    if (its.plot.zoomstart - 
			(its.tol.scroll * its.plot.zoomrange) > 
			its.plot.sliderstart) {
			# Can Move
			its.plot.zoomstart := 
			    its.plot.totalwindow[1] - 
				(its.tol.scroll * its.plot.zoomrange);
			its.plot.zoomrange := 
			    abs(its.plot.zoomend - its.plot.zoomstart);
			its.plot.startsel := value.world[1];
			
		    } else {
			# Can't move - End of slider
			its.plot.zoomstart := its.plot.sliderstart;
			its.plot.zoomrange := 
			    abs(its.plot.zoomend - its.plot.zoomstart);

			if (value.world[1] > its.plot.sliderstart) {
			    its.plot.startsel := value.world[1];
			} else {
			    its.plot.startsel := its.plot.sliderstart;
			}
			
		    }
			
		} else {
		    its.plot.startsel := value.world[1];
		}
		
		its.slide();
		its.redraw(shading = F);
		its.setminmax(its.plot.startsel, its.plot.stopsel);
		if ((its.gui.range.getlabel() != '<unset>') || 
		    (its.gui.nsigma.getlabel() != '<unset>')) {
		    its.unsetboth();
		}
		
	    } # End < stopsel
	}# End currenstate == 3
    }# End handleresize    
    
    its.handlemove := function(cursor) {
	wider its;
	#Starting
       	if (its.states.currentstate == 22) {
	    its.states.currentstate := 2;
	    its.plot.relposdrag := abs(cursor.world[1] - its.plot.startsel);
	    its.plot.widthsel := abs(its.plot.stopsel - its.plot.startsel);
	}
	
	#Dragging
	if (its.states.currentstate == 2) {
	    
	    #Check if we are being dragged off screen to the left;
	    if (((cursor.world[1] - its.plot.relposdrag) 
		 < its.plot.totalwindow[1] + 
		 (its.tol.scroll * its.plot.zoomrange)) &&
		 (cursor.world[1] - its.plot.relposdrag > 
		    its.plot.totalwindow[1] - 
		    (its.tol.scroll * its.plot.zoomrange))) {
		
		#Can we drag?
		if ((its.plot.zoomstart - 
		     (its.tol.scroll * its.plot.zoomrange)) >
		     its.plot.sliderstart) {
		    # Can Move
		    its.plot.zoomstart := 
			its.plot.totalwindow[1] - 
			    (its.tol.scroll * its.plot.zoomrange);
		    its.plot.zoomend := 
			its.plot.totalwindow[2] - 
			    (its.tol.scroll * its.plot.zoomrange);
			its.plot.zoomrange := 
			    abs(its.plot.zoomend - its.plot.zoomstart);

			its.plot.startsel := 
			    cursor.world[1] - its.plot.relposdrag;
			its.plot.stopsel := 
			    its.plot.startsel + its.plot.widthsel;
		    } else {
			# Can't move - Start of slider
			its.plot.zoomstart := its.plot.sliderstart;
			its.plot.zoomend := 
			    its.plot.sliderstart + its.plot.zoomrange;

			if (cursor.world[1] - its.plot.relposdrag > 
			    its.plot.sliderstart) {
			    its.plot.startsel := 
				cursor.world[1] - its.plot.relposdrag;
			    its.plot.stopsel := 
				its.plot.startsel + its.plot.widthsel;
			} else {
			    its.plot.startsel := its.plot.sliderstart;
			    its.plot.stopsel := 
				its.plot.startsel + its.plot.widthsel;
			}
		    }
	    #Or to the right
	    } else if ((cursor.world[1] - its.plot.relposdrag + 
			its.plot.widthsel >
		        its.plot.totalwindow[2] - 
			(its.tol.scroll * its.plot.zoomrange)) &&
		        cursor.world[1] - its.plot.relposdrag + 
		       its.plot.widthsel < its.plot.totalwindow[2] + 
		       (its.tol.scroll * its.plot.zoomrange)){ 
		#Can we drag?
		if (its.plot.zoomend + (its.tol.scroll * its.plot.zoomrange) < 
		    its.plot.sliderend) {
		    #Can drag
		    its.plot.zoomstart := 
			its.plot.totalwindow[1] + 
			    (its.tol.scroll * its.plot.zoomrange);
		    its.plot.zoomend := 
			its.plot.totalwindow[2] + 
			    (its.tol.scroll * its.plot.zoomrange);
		    its.plot.zoomrange := 
			abs(its.plot.zoomend - its.plot.zoomstart);

		    its.plot.startsel := cursor.world[1] - its.plot.relposdrag;
		    its.plot.stopsel := its.plot.startsel + its.plot.widthsel;
		} else {
		    #Cant drag
		    its.plot.zoomend := its.plot.sliderend;
		    its.plot.zoomstart := 
			its.plot.sliderend - its.plot.zoomrange;
		    
		    if (cursor.world[1] - its.plot.relposdrag + 
			its.plot.widthsel < its.plot.sliderend) {
			its.plot.startsel := 
			    cursor.world[1] - its.plot.relposdrag;
			its.plot.stopsel := 
			    its.plot.startsel + its.plot.widthsel;
		    } else {
			its.plot.stopsel := its.plot.sliderend;
			its.plot.startsel := 
			    its.plot.stopsel - its.plot.widthsel;
		    }
		}

	    } else if (((cursor.world[1] - its.plot.relposdrag) > 
			its.plot.sliderstart) &&
		       cursor.world[1] - its.plot.relposdrag + 
		       its.plot.widthsel < its.plot.sliderend) {
		its.plot.startsel := cursor.world[1] - its.plot.relposdrag;
		its.plot.stopsel := its.plot.startsel + its.plot.widthsel;
	    }

	    if ((its.gui.range.getlabel() != '<unset>') || 
		(its.gui.nsigma.getlabel() != '<unset>')) {
		its.unsetboth();
	    }
	} #end states == 2

	its.slide();
	its.setminmax(its.plot.startsel, its.plot.stopsel);
	its.redraw(shading = F);              	
    } #End moving
    
    const its.deactivate := function(which) 
    {
	if (is_integer(which)) {
	    n := length(which);
	    if (n>0) {
		for (i in 1:n) {
		    ok := whenever_active(which[i]);
		    if (is_fail(ok)) {
		    } else {
			if (ok) deactivate which[i];
		    }
		}
	    }
	}
	return T;
    }
    
    its.redrawbare := function() {
	wider its;
	
	its.gui.plotarea->eras();
	
	if (its.states.currentstate != -1) {
	    
	    if (its.states.log) {
		if (its.plot.yzoomstart != 0) {
		    its.plot.lyzoomstart := log(its.plot.yzoomstart);
		} else {
		    its.plot.lyzoomstart := 0;
		}
		
		if (its.plot.yzoomend != 0) {
		    its.plot.lyzoomend := log(its.plot.yzoomend);
		} else { 
		    its.plot.lyzoomend := 0;
		}
		
		its.gui.plotarea->env((its.plot.zoomstart), 
				      (its.plot.zoomend + 
				       (0.01 * its.plot.zoomrange)), 
				      its.plot.lyzoomstart, 
				      its.plot.lyzoomend, 
				      its.plot.just, its.plot.axis);
	    } else {
		its.gui.plotarea->env((its.plot.zoomstart), 
				      (its.plot.zoomend + 
				       (0.01 * its.plot.zoomrange)), 
				      (its.plot.yzoomstart), 
				      (its.plot.yzoomend), 
				      its.plot.just, its.plot.axis);
	    }
	    
	    
	    its.gui.plotarea->svp(0.05 ,0.95 , 0.175 , 0.95);
	    its.gui.plotarea->sch(2);
	    its.gui.plotarea->box('BINTS', 0.0, 0.0, 'B', 0.0, 0.0);
	    
	    its.gui.plotarea->sch(2);
	    its.gui.plotarea->mtxt('B', 2.75, 0.5, 0.5, its.brightnessunit);

	    if (!its.states.log) {
		its.gui.plotarea->mtxt('L', 0.5, 0.5, 0.5, 'Counts');
	    } else {
		its.gui.plotarea->mtxt('L', 0.5, 0.5, 0.5, 'log  ( Counts )');
	    }
	    
	    if (!its.states.log) {
		its.gui.plotarea->line(its.hist);
	    } else {
		its.gui.plotarea->line(its.loghist);
	    }
	    
	    its.plot.totalwindow := its.gui.plotarea->qwin();
	    its.plot.totalx := 
		(abs(its.plot.totalwindow[2] - its.plot.totalwindow[1]));
	    
	} else {
	    
	    its.gui.plotarea->env(0,10,0,10, its.plot.just, its.plot.axis);
	    its.gui.plotarea->sch(3);
	    its.gui.plotarea->ptxt(5,5, 0.0, 0.5, "AWAITING DATA FOR DISPLAY");
	    its.gui.plotarea->ptxt(5, 3, 0.0, 0.5, "WINDOW DISABLED");
	    its.gui.plotarea->sch(1);
	}	
	
    }
    
    its.totalpixels := function() {
	wider its;

	if (its.plot.totalpixels == -1) {
	    its.plot.totalpixels := 0;
	    
	    for (i in 1:len(its.hist.counts)) {
		its.plot.totalpixels := 
		    its.plot.totalpixels + its.hist.counts[i];
	    }
	}
	return its.plot.totalpixels;
	    
    }

    its.redraw := function(shading=T) {
	wider its;
  
	if ((!is_numeric(its.plot.zoomstart) || 
	      !is_numeric(its.plot.zoomend)) && 
	    (its.states.currentstate != -1)) 
	    its.autozoom();

	its.redrawbare();
	
	if (its.states.currentstate != 0 && its.states.currentstate !=-1) {
	    its.gui.plotarea->sci(its.thecolor);       
	    
	    if (shading) {    
		its.gui.plotarea->sfs(3);
		its.gui.plotarea->shs(45, 5, 0);
		
		its.gui.plotarea->rect(its.plot.startsel, 
				       its.plot.stopsel, 
				       its.plot.totalwindow[3], 
				       its.plot.totalwindow[4]);
	    }
	    
	    if(its.states.medianmarker) {
		its.gui.plotarea->sls(2);
		if (!is_boolean(its.plot.median)) {
		    its.gui.plotarea->line([its.plot.median, its.plot.median], 
					   [its.plot.totalwindow[3], 
					    its.plot.totalwindow[4]] );
		}

		its.gui.plotarea->sls(1);
	    }

	    if(its.states.meanmarker) {
		its.gui.plotarea->sls(2);
		if (!is_boolean(its.plot.mean)) {
		    its.gui.plotarea->line([its.plot.mean, its.plot.mean], 
					   [its.plot.totalwindow[3], 
					    its.plot.totalwindow[4]] );
		}
		its.gui.plotarea->sls(1);
	    }
	    
	    its.gui.plotarea->sci(its.thecolor);
	    its.gui.plotarea->sfs(2);
	    its.gui.plotarea->rect(its.plot.startsel, 
				   its.plot.stopsel, 
				   its.plot.totalwindow[3], 
				   its.plot.totalwindow[4]);
	    its.gui.plotarea->sci(1);
	    
	}
    }
    
    its.checksigma := function(newvalue, labels, nothing) {
	valid := F;

	reg := m/[a-zA-Z~!@'#'$%^&*()_=+\/\<>:;"'|"]+/;

	if (!(newvalue =~ reg)) {
	    newvalue := as_float(newvalue);
	    if (newvalue > 0 && is_float(newvalue)) valid := T;
	}
	return valid;
    }

    its.checkcolor := function (newvalue, labels, nothing) {
	wider its;
	valid := F;
	newvalue := to_lower(newvalue);
	position := 20 + len(its.gui.colors.getlabels());
	success :=  its.gui.plotarea->scrn(position, newvalue);
	if (!success) valid := T;
	return valid;
    }

    its.resetcontrols := function () {
	wider its;
	its.unsetboth();
	its.gui.whichsigma.selectvalue('mean');		
	its.gui.colors.selectlabel('yellow');
	its.thecolor := 7;
	its.gui.scale.selectvalue(T);
	its.states.log := T;
	its.states.meanmarker := F;
	its.states.medianmarker := F;
    }

    its.checkpercentage := function(newvalue, labels, nothing)
    {
	wider its;
	valid := F;
	reg := m/[a-zA-Z~!@'#'$^&*()_=+\/\<>:;"'|"]+/;
	if (!(newvalue =~ reg)) {
	    newvalue =~ s/[%]+//g;
	    newvalue := as_float(newvalue);
	    if (newvalue > 0 && newvalue <= 100) valid := T;
	}
	return valid;
    }

    
    #####
    #####  PUBLIC METHODS
    #####
    
    self.gui := function() {
	wider its;
	
	if (length(its.gui) == 0) {
	    ok := its.buildgui();
	    if (is_fail(ok)) fail;
	}
	
	return its.gui.frame->map();
    }
    
    self.disable := function() {
	###   
    }
    
    self.enable := function() {
	###
    }
    
    self.setstats := function(mean = F, median = F, stddev = F) {
	wider its;

	if (!is_boolean(mean)) {
	    its.plot.mean := mean;
	}
	if (!is_boolean(median)) {
	    its.plot.median := median;
	}
	if (!is_boolean(stddev)) {
	    its.plot.stddev := stddev;
	}
	newsel := F;
	
	if (its.states.waitingforstats) {
	    if (its.gui.whichsigma.getvalue() == 'mean' 
		&& !is_boolean(its.plot.mean)
		&& !is_boolean(its.plot.stddev)) {
		
                #Success!
		its.states.waitingforstats := F;
		its.states.currentstate := its.states.oldstate;
		newsel := [its.plot.mean - 
			   (as_float(its.gui.nsigma.getlabel()) * 
			    its.plot.stddev), 
			   its.plot.mean + 
			   (as_float(its.gui.nsigma.getlabel()) * 
			    its.plot.stddev)];
		its.setselection(newsel);
		its.setminmax(newsel[1], newsel[2]);
		its.autozoom();
		its.redraw();
		
	    } else if ( its.gui.whichsigma.getvalue() == 'median' &&
		        !is_boolean(its.plot.median) &&
		        !is_boolean(its.plot.stddev) ) {
		its.states.waitingforstats := F;
		its.states.currentstate := its.states.oldstate;
		newsel := [its.plot.median - 
			   (as_float(its.gui.nsigma.getlabel()) * 
			    its.plot.stddev), 
			   its.plot.median + 
			   (as_float(its.gui.nsigma.getlabel()) * 
			    its.plot.stddev)];
		its.setselection(newsel);
		its.setminmax(newsel[1], newsel[2]);
		its.autozoom();
		its.redraw();

	    }
	    
	}
    }


    self.newdata := function(array=F, xmin=F, xmax=F) {
	wider its;
	its.plot.totalpixels := -1;
	
	if (is_record(array) && 
	    has_field(array, "values") && 
	    has_field(array, "counts")) {
	    
	    its.hist := array;
	    its.loghist := array;
	    if (its.states.log) its.updatelog();
	    
	    #Absolute values from the array given.
	    its.plot.xmin := min(its.hist.values);
	    its.plot.xmax := max(its.hist.values);
	    its.plot.ymin := min(its.hist.counts);
	    its.plot.ymax := max(its.hist.counts);	
	    
	    its.plot.xrange := abs(its.plot.xmax - its.plot.xmin);
	    its.plot.yrange := abs(its.plot.ymax - its.plot.ymin);
	    
	    if(its.states.log) {
		its.updatelog();
	    }
	    
	    if (is_numeric(xmin) && is_numeric(xmax)) {	   
		if ((abs(its.plot.xmin-as_double(xmin)) < 
		     (0.005*its.plot.xrange)) &&
		     (abs(its.plot.xmax-as_double(xmax)) < 
			(0.005*its.plot.xrange))) {
		    its.states.currentstate := 0;
		} else {
		    its.plot.startsel := as_double(xmin);
		    its.plot.stopsel := as_double(xmax);
		    its.states.currentstate := 1;
		}
		its.setselection([xmin,xmax]);
	    }

	} else {
	    its.states.currentstate := -1;
	}

	if (its.states.currentstate != 1 && 
	    is_agent(its.gui.frame)) its.autozoom();

	its.plot.mean := F;
	its.plot.median := F;
	its.plot.stddev := F;
	its.states.waitingforstats := F;

	its.states.meanmarker := F;
	its.states.medianmarker := F;
	
	if (is_agent(its.gui.plotarea) && is_agent(its.gui.range)) {
	    its.unsetboth();
	    its.redraw();
	}
    }

    its.unsetboth := function() {
	wider its;

	its.gui.range.selectlabel('<unset>');
	its.gui.nsigma.selectlabel('<unset>');     
	its.states.meanmarker := F;
	its.states.medianmarker := F;
    }

    its.setselection := function(sel, forcenosel=F, forceselection=F) {
	wider its;

	if (its.states.currentstate != -1) {
	    if (((abs(its.plot.xmin - as_double(sel[1])) < 
		  (0.005 * its.plot.xrange)) && 
		 (abs(its.plot.xmax - as_double(sel[2])) < 
		  (0.005 * its.plot.xrange)) || 
		 forcenosel) && !forceselection) {

		#No selection
		its.plot.startsel := its.plot.xmin;
		its.plot.stopsel := its.plot.xmax;
		its.states.currentstate := 0;
		
	    } else {
		#Selection
		its.plot.startsel := as_double(sel[1]);
		its.plot.stopsel := as_double(sel[2]);
		its.states.currentstate := 1;
	    }
	}
    }

    self.setselection := function(sel, forcenosel=F, forceselection=F) {
	#External set selection.
	wider its;
	its.setselection(sel, forcenosel, forceselection);
	its.unsetboth();
	its.autozoom();
	its.redraw();
    }
    
    self.dismiss := function() {
	wider its;
	its.gui.frame->unmap();
	return T;
    }
    
    self.done := function() {
	wider its,self;
	self->close();
	its.deactivate(len(its.whenevers));
	val its := F;
	val self := F;
    }
	
    self.newdata(array, xmin, xmax);
    
    return T;
}









