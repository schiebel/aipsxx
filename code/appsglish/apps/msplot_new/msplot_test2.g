# This script tests the msplot_new tool
# Testing the functions: uvCoverage(), array(), etc.
# create a msplot tool, set tables and plot amplitude vs uvdist.
# 
# In multiple panel case( when using iterplot ), flagdata() fails!
# In multiple panel case( when using iterplot ), zoomplot() fails!
#
  include 'msplot.g';
#############################################################################################################
# define the control variables
  SETDATA    := F;
  SETLABEL   := F;
  UVCOVERAGE := F;
  ARRAY      := F;
  UVDIST     := F;
  GAINTIME   := F;
  GAINCHANNEL:= F;
  PLOTXY     := F;
  BASELINE   := F;
  HOURANGLE  := F; 
  AZIMUTH    := F;
  ELEVATION  := T;
  PARALLACTIC:= T;  
  ITER_PLOT := F;
  MARK_FLAG := F;
  FLAG_DATA := F;
  ZOOM_PLOT := F;
  CLEAR_FLAG := F;
############################################################################################################
## Create an msplot tool
    msp := msplot( msname=['./data/3C273XC1.ms']);
    # msp.settables(tabnames=['3c273.ms','3c48.ms']);
    # msp := msplot( msname=['./data/ngc7538.ms']);
#############################################################################################################
if( SETDATA ){
     ## msp.setdata();  # if failed, falles to next command, i.e. msp.setaxes().
     ## msp.setdata( antennaNames=[ '1', '2', '3', '4' ]); ## works. Input vector<string>
     ## msp.setdata( antennaNames='5 & 6');                ## works.
     ## msp.setdata( antennaNames='5,6,7');                ## works.
     ## msp.setdata( antennaNames='5 & *' );               ## works.
     ## msp.setdata( antennaNames='(5-8) & (9,10)' );      ## works.
     ## msp.setdata( antennaNames='(5-8) & *' );           ## works.
     ## msp.setdata( antennaNames='VLA:N*' );              ## works. 
     ## msp.setdata( antennaNames='5:R & *');              ## works.
     ## msp.setdata( antennaNames='5:R & 7:L');            ## did not work.
     ## msp.setdata( antennaNames='5:R & (3,4,7,8):L');    ## did not work.
     ## msp.setdata( antennaIndex=[1,2,3,4]);              ## works after modifing MsPlot::antennaSelection(). # input vector<int>
     ## msp.setdata( spwNames=['63*'] );                   ## did not work, tried ngc7538.ms. Input vector<string>
     ## msp.setdata( spwIndex=[0,1] );                     ## works for 3C273XC1.ms and ngc7538.ms. Input vector<int>
     ## msp.setdata( spwIndex=[0] );                       ## works for 3C273XC1.ms
     ## msp.setdata( spwNames='1:16-40' );                 ## did not work.
     ## msp.setdata( fieldNames=['3C*'] );                 ## works for 3C273XC1.ms. Input vector<string>
     ## msp.setdata( fieldIndex=[0]);                      ## works for 3C273XC1.ms. Index starts from 0!
     ## msp.setdata( fieldNames=['NGC*,1328*'] );          ## works for ngc7538.ms.
     ## msp.setdata( fieldNames=['A'] );                   ## works for ngc7538.ms. select all fields with CODE='A'.
     ## msp.setdata( fieldIndex= [0-3] );                  ## did not work.
     ## msp.setdata( fieldNames=['>3'] );                  ## did not work.
     ## msp.setdata( fieldIndex=[0,1,3] );                 ## works for ngc7538.ms
     ## msp.setdata( uvDists=['>0l'] );                    ## works.
     ## msp.setdata( uvDists=['>25kl'] );                  ## works.
     ## msp.setdata( uvDists=['<25kl'] );                  ## works.
     ## msp.setdata( uvDists=['10-25kl'] );                ## works.
     ## msp.setdata( uvDists=['25kl:5%'] );                ## works.
     ## msp.setdata( uvDists=['0.02Ml:5%'] );              ## did not work.
     ## msp.setdata( times=['1989/06/27/03:31:40'] );      ## did not work. type mismatch!
     ## msp.setdata( correlations=[ 'LR'] );               ## only works for RR, RL, LR, LL.
     ## next statement tested working.
     ## msp.setdata( antennaNames=[''], antennaIndex=[-1], spwNames=[''], spwIndex=[0],fieldNames=['3C273'], fieldIndex=[0],uvDists=[''],times=[''],correlations=['RR'] )
     ## test uvdist()
     ## msp.setdata( spwNames=['(0,1):[1-3]'], correlations=['RR RL'] ); ## works for ngc7538.ms. no matching polarrization indices, ignore the correlations.
     ## msp.setdata( spwNames=['(0,1):[1-3]'], correlations=['RR'] );  ## works for ngc7538.ms
     msp.setdata( spwNames=['(0):[1]'], correlations=['RR RL'] );  ## works for 3C273XC1.ms
     ## msp.setdata( spwNames=['(0,1):[3-6]'],  correlations=['RL'] );  ## works for ngc7538.ms
     ## msp.setdata( spwNames=['(0,1):[1,3]'], correlations=['RR'] );  ## works for ngc7538.ms
}
####################################################################################################################3
if( SETLABEL ){
     plotopts.nxpanels := 1;      
     plotopts.nypanels := 1; 
     plotopts.plotcolour := 21;
     #plotopts.plotstyle := 1;     
     plotopts.windowsize := 8;    
     plotopts.aspectratio := 0.7; 
     plotopts.fontsize := 2.0; 
     labels := ['UV Coverage of the Antennas','U coordinate','V coordinate']; # UV coverage lables
     ## labels := ['Amplitude vs UVdist ( antenna 5 & 6 only )','uvdist','amplitude'];
     ## labels := ['Amplitude vs Time','time','amplitude'];
     ## labels := ['Amplitude vs Antenna1','Antenna1','amplitude'];
     msp.setlabels( poption=plotopts, labels=labels );
}
##################################################################################################################################
# Plot uv coverage
  if( UVCOVERAGE ){
     msp.uvcoverage();
   }
########################################################################################################################
#  plot antenna distribution
   if( ARRAY ){
      msp.array();
   }
########################################################################################################################
# Plot various quantities versus uv distance
   if( UVDIST ){
      # create the msplot object and setdata() first
      msp.uvdist( column=['data'], what=['amp']);       # works for nng7538.ms
   }
########################################################################################################################
# Plot various quantities versus gaintime
   if( GAINTIME ){
      # create the msplot object and setdata() first
      # msp.gaintime( column=['data'], what=['amp'] );       # works for ngc7538.ms
      # msp.gaintime( column=['data'], what=['amp'], iteration=['baseline']); # works for ngc7538.ms
      msp.gaintime( column=['data'], what=['amp'], iteration=['antenna']); # works for ngc7538.ms
   }
########################################################################################################################
# Plot various quantities versus channel
   if( GAINCHANNEL ){
      # create the msplot object and setdata() first
       msp.gainchannel( column=['data'], what=['amp'] );       # works for ngc7538.ms
      # msp.gainchannel( column=['data'], what=['amp'], iteration=['baseline']); # works for ngc7538.ms
      # msp.gainchannel( column=['data'], what=['amp'], iteration=['antenna']); # works for ngc7538.ms
      msp.gainchannel( column=['data'], what=['amp'], iteration=['time']); # works for ngc7538.ms
   }
########################################################################################################################
# Plot various quantities versus uv distance
   if( PLOTXY ){
      # create the msplot object and setdata() first
      #msp.plotxy();                               ## using default values for all parameter. Works for 3C273XC1.ms
      #msp.plotxy( X='antenna1', Y='antenna1' );   ## draw nothing. Works for 3C273XC1.ms
      #msp.plotxy( X='antenna1', Y='antenna2' );    ## Works for 3C273XC1.ms
      #msp.plotxy( X='channel', Y='antenna2' );     ## draw nothing. Works for 3C273XC1.ms
      #msp.plotxy( X='antenna1', Y='data' );       ## using default values for parameter what. Works for 3C273XC1.ms
      msp.plotxy( X='uvdist', Y='data', iteration='antenna1' ); ## using default values for parameter what. Works for 3C273XC1.ms
      #msp.plotxy( X='antenna1', Y='feed1' );      ## Works for 3C273XC1.ms
   }
########################################################################################################################
# Plot various quantities versus baseline
   if( BASELINE ){
      # create the msplot object and setdata() first
       msp.baseline( column=['data'], what=['amp'] );       # works for 3C273XC1.ms and ngc7538.ms
      # msp.baseline( column=['data'], what=['phase'] );       # works for 3C273XC1.ms and ngc7538.ms
   }
########################################################################################################################
# Plot various quantities versus hour angle
   if( HOURANGLE ){
      # create the msplot object and setdata() first
      msp.hourangle( column=['data'], what=['amp'] );       # works for ngc7538.ms
   }
########################################################################################################################
# Plot various quantities versus azimuth
   if( AZIMUTH ){
      # create the msplot object and setdata() first
      msp.azimuth( column=['data'], what=['amp'] );       # works for ngc7538.ms
   }
########################################################################################################################
# Plot various quantities versus elevation
   if( ELEVATION ){
      # create the msplot object and setdata() first
      msp.elevation( column=['data'], what=['amp'] );       # works for ngc7538.ms
   }
########################################################################################################################
# Plot various quantities versus parallactic angle
   if( PARALLACTIC ){
      # create the msplot object and setdata() first
      msp.parallacticangle( column=['data'], what=['amp'] );       # works for ngc7538.ms
   }
########################################################################################################################
# iterplotstart()--iterplotnext()--iterplotstop()
  if( ITER_PLOT ){
     plotopts.nxpanels := 1;
     plotopts.nypanels := 3;
     plotopts.windowsize := 8;    
     plotopts.aspectratio := 0.8; 
     plotopts.fontsize := 3.0;  
     msp.setdata( fieldNames=['3C273'] );                 ## works. Input vector<string>  
     labels := ['Amplitude vs UVdist (iterating over Antenna1)','uvdist','amplitude'];
     xystr := ['SQRT(SUMSQUARE(UVW[1:2]))','AMPLITUDE(DATA[1,1])'];
     iteraxes := ['ANTENNA1'];
     msp.iterplotstart(poption=plotopts,labels=labels,datastr=xystr,iteraxes=iteraxes);
     ## interplotstart() calls iterplotnext() once already!
     ret := msp.iterplotnext();
     ret := msp.iterplotnext();
     msp.iterplotstop();
  }

# Mark flag
  if( MARK_FLAG ){
     msp.markflags(panel=1);
     #msp.markflags(panel=2);
  }
# Perform flagging
  if( FLAG_DATA ){
     msp.flagdata(diskwrite=1,rowflag=0);
  }
# Zoom data
  if( ZOOM_PLOT ){
     msp.zoomplot(panel=1,direction=1);
     #msp.zoomplot(panel=1,direction=0);
  }
# Clear all flags
  if( CLEAR_FLAG ){
     msp := msplot( msname=['./data/3C273XC1.ms']);
     ##msp.setdata( fieldIndex=[0] );
     msp.clearflags();
     #msp.done();
  }

#  msp.done();
#