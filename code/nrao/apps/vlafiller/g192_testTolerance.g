###########################################################################
## Test the tolerance for VLAFiller.
## g192_testTolerance.g--test the frequency tolearance of VLA filler using VLA data G192.
##
###########################################################################
## Include relevant tools if not already done:
##
include 'vlafiller.g';      

system.output.olog := 'ALMATST1_regTest.log'

g192_toleranceTest := function(){
   print "Testing G192 ......";
   print "--------------------------------------------------";

###########################################################
## Fill Data:
## The default tolerance for frequency is good enough for G192, so no need to 
## pass a value to freqTolerance to vlafillerfromdisk().
    if (any(dirs=='g192_a.ms')) shell('rm -rf g192_a.ms');
    vlafillerfromdisk(filename='data/G192/AS758_C030425.xp1',msname='g192_a.ms',
       overwrite=T,bandname='K',async=F, freqTolerance=150000.0);
    vlafillerfromdisk(filename='data/G192/AS758_C030425.xp2',msname='g192_a.ms',
       overwrite=F,bandname='K',async=F, freqTolerance=150000.0); 
    vlafillerfromdisk(filename='data/G192/AS758_C030425.xp3',msname='g192_a.ms',
       overwrite=F,bandname='K',async=F, freqTolerance=150000.0);
    vlafillerfromdisk(filename='data/G192/AS758_C030426.xp4',msname='g192_a.ms',
       overwrite=F,bandname='K',async=F, freqTolerance=150000.0);
    vlafillerfromdisk(filename='data/G192/AS758_C030426.xp5',msname='g192_a.ms',
    overwrite=F,bandname='K',async=F, freqTolerance=150000.0);
} ## end of the g192_toleranceTest function.
  g192_toleranceTest();
  ## dl.printtofile();
  exit;
#############################################################################
