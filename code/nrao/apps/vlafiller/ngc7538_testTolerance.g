###############################################################
### ngc7538_testTolerance.g -- scripts to test the frequency tolerance using VLA NGC7538
### 
###############################################################
## Include relevant tools if not already done:
##
include 'vlafiller.g';
include 'os.g';      

system.output.olog := 'ALMATST1_regTest.log';

ngc7538_testTolerance := function(){
   print "Testing NGC7538 ......";
   print "--------------------------------------------------";
###############################################################

MSFILE := 'ngc7538.ms'

###########################################################
### global variables
dirs :=dos.dir();
###########################################################
## Fill Data:
## 
        if( any(dirs==MSFILE )) shell('rm -rf ngc7538.ms'); 
        vlafillerfromdisk(filename='data/N7538/AP314_A950519.xp1',
                msname=MSFILE,
                overwrite=T,
                bandname='K',
                async=F, freqTolerance=60000000 );
        vlafillerfromdisk(filename='data/N7538/AP314_A950519.xp2',
                msname=MSFILE,
                overwrite=F,
                bandname='K',
                async=F, freqTolerance=60000000 );

        vlafillerfromdisk(filename='data/N7538/AP314_A950519.xp3',
                msname=MSFILE,
                overwrite=F,
                bandname='K',
                async=F, freqTolerance=60000000 );


############################################################
} ##end of ngc7538_regTest function
ngc7538_testTolerance();
#############################################################################