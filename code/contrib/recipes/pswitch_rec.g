# AIPS++ Recipes Repository script recipe template
#
#RECIPE: Script to calibrate Position Switched GBT data
#
#CATEGORY: Single Dish
#
#GOALS: Calibrate a GBT Position Switched scan
#
#USING: dish tool
#
#RESULTS: AIPS++ MeasurementSet has the calibration results written to it.
#
#ASSUME: There is a dish tool running (d). GBT data is a M&C v3.6, FITS v.x, 
filler v.x
#
#SYNOPSIS:
# First open AIPS++ MS. Review the contents, calibrate  and display the data.
#


#SCRIPTNAME: pswitch_rec.g

#SCRIPT:

d.open('exampleSP')			      #open the desired MS
d.gms()                                       #provide brief summary
d.plotr(42,1)                                 #plot the raw(observed) data
                                              #for the first phase of scan
                                              #42. Since no integration
                                              #value is specified, it averages
                                              #all phase 1 data (in this case
                                              #this is all data with CAL ON.
d.calib(42)                                   #this will calibrate scan 42 
                                              #according to the way the
                                              #the data were taken (i.e., the
                                              #observing procedure

                                              #You can also baseline the data
                                              #most efficiently at this stage:
                                              #d.calib(42,baseline=T,
                                              #range=[300:600,800:1000]);

d.plotc(42)                                   #plot the calibrated data for
                                              #scan 42. Since no integration
                                              #was specified, all data is
                                              #averaged.
d.plotc(42,1)                                 #plots the first integration of
                                              #the calibrated data for 42.
d.plotc(42,3,2)                               #plots the third integration of
                                              #the second polarization for 
                                              #scan 42.
d.plotc(scan=42,int=3,pol=2)                  #same using the explicit names
                                              #for the arguments.  
#
#OUTPUT:
#output from d.gms();
#Scan     Object   Proctype    SWState   SWtchsig   Procseqn   Procsize
#  35         S8      Track    FSWITCH      FSW01          1          1
#  36         S8      Track    FSWITCH      FSW12          1          1
#  37         S8      Track    FSWITCH      FSW12          1          1
#  38         S8      OffOn PSWITCHOFF   TPWCALSP          1          2
#  40         S8      OnOff  PSWITCHON   TPWCALSP          1          2
#  42         S8      Track       NONE   TPWCALSP          1          1
# 
# The MS is written to and now contains the calibration results for the scan.

#CONCLUSION: 
#
#

#SUBMITTER: J. McMullin
#SUBMITAFFL: NRAO-AOC
#SUBMITDATE: 2002-Aug-31
