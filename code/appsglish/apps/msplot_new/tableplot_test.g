# This script tests the tableplot tool
# create a tableplot tool, set tables and plot amplitude vs uvdist 
# for two Measurement Set tables.
# 
# In multiple panel case( when using iterplot ), flagdata() fails!
# In multiple panel case( when using iterplot ), zoomplot() fails!
#
  include 'tableplot.g';
# define the control variables
  PLOT_DATA := F;
  ITER_PLOT := T;
  MARK_FLAG := T;
  FLAG_DATA := T;
  ZOOM_PLOT := T;
  CLEAR_FLAG := F;
  tp := tableplot();
# tp.settables(tabnames=['3c273.ms','3c48.ms']);
  tp.settables(tabnames=['./data/3C273XC1.ms']);
#
# Clear all flags
  if( CLEAR_FLAG ){
     tp.clearflags();
  }
# Plot data
  if( PLOT_DATA ){
     plotopts.nxpanels := 1;      
     plotopts.nypanels := 2;      
     plotopts.windowsize := 8;    
     plotopts.aspectratio := 0.8; 
     plotopts.fontsize := 1.0;    
     labels := ['Amplitude vs UVdist','uvdist','amplitude'];
     xystr := ['SQRT(SUMSQUARE(UVW[1:2]))','AMPLITUDE(DATA[1:2,1])'];
     tp.plotdata(poption=plotopts,labels=labels,datastr=xystr);
   }
# iterplotstart()--iterplotnext()--iterplotstop()
  if( ITER_PLOT ){
     plotopts.nxpanels := 1;
     plotopts.nypanels := 2;
     plotopts.windowsize := 8;    
     plotopts.aspectratio := 0.8; 
     plotopts.fontsize := 2.0;    
     labels := ['Amplitude vs UVdist (iterating over Antenna1)','uvdist','amplitude'];
     xystr := ['SQRT(SUMSQUARE(UVW[1:2]))','AMPLITUDE(DATA[1,1])'];
     iteraxes := ['ANTENNA1'];
     tp.iterplotstart(poption=plotopts,labels=labels,datastr=xystr,iteraxes=iteraxes);
     #ret := tp.iterplotnext();
     #ret := tp.iterplotnext();
     #ret := tp.iterplotnext();
     #ret := tp.iterplotnext();
     #ret := tp.iterplotnext();
     tp.iterplotstop();
  }

# Mark flag
  if( MARK_FLAG ){
     tp.markflags(panel=1);
     #tp.markflags(panel=2);
  }
# Perform flagging
  if( FLAG_DATA ){
     tp.flagdata(diskwrite=1,rowflag=0);
  }
# Zoom data
  if( ZOOM_PLOT ){
     tp.zoomplot(panel=1,direction=1);
     #tp.zoomplot(panel=1,direction=0);
  }
# Clear all flags
  if( CLEAR_FLAG ){
     #tp.clearflags();
  }

#  tp.done();
#