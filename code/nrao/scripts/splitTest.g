#
pragma include once;

include 'sysinfo.g';
include 'logger.g';
include 'ms.g';


system.output.olog := 'SSGTesting.log'

splitTest := function() {
stime := time()
nametest := 'MS split test';

myms1:=ms('phIII_64ant.ms', readonly=F);

#myms1:=ms('3C273XC1.ms', readonly=F);

#Output average 60 channel from spw 3 (which has 64 channels) 
# to 1 output channel 
myms1.split(outputms='Cont3mm.ms', fieldids=[3], spwids=[3], 
		  nchan=1, start=3, step=60, whichcol='CORRECTED_DATA');

#select 48 channel no averaging from spw 7 (which has 256 channels)

myms1.split(outputms='Line3mm.ms', fieldids=[3], spwids=[7], nchan=48, 
 start=105, step=1, whichcol='CORRECTED_DATA');

# select multiple spw and average

myms1.split(outputms='Cont1mm.ms', fieldids=[3], spwids=[11,12,15,16,19,2], 
            nchan=1, start=4, step=58, whichcol='CORRECTED_DATA');


# Similar thing could be achieved this way with different selections
# for each spw if needed....


myms1.split(outputms='Cont1mmb.ms', fieldids=[3], spwids=[11,12,15,16,19,2], 
            nchan=[1,1,1,1,1,1], start=[4,4,4,4,4,4], 
            step=[58,58,58,58,58,58], whichcol='CORRECTED_DATA');

testms := ms('Cont1mmb.ms');

#-------------------------------------------------------------
thistest := (min(testms.range().amplitude) + max(testms.range().amplitude))/2;
col:=tablecreatescalarcoldesc("split-rows",as_float(1));
td:=tablecreatedesc(col);

temp:=dos.dir();
if (!any(temp=='testTable')) {
tab:=table("testTable", readonly=F, tabledesc=td, nrow = 1)
table('testTable').addcols(td);
table('testTable').putcol('split-rows', thistest);
} else {

     for ( cname in  table('testTable').colnames()) {
       if(cname == 'split-rows' ) {
         storedval := table('testTable').getcol('split-rows');
         if(abs(storedval - thistest) < 0.05)
           print spaste('### ', nametest, '... passed');
         else
           print spaste('### ', nametest, '... Faild ');
       }
     }
     if( !table('testTable').getcol('split-rows') ) {
       table('testTable').addcols(td);
       table('testTable').putcol('split-rows', thistest);
       print "### add a split-rows column to table";
     }
}

myms1.close()
myms1.done()
testms.close()
testms.done()

print "----------------------------------------------------------"
print "The pass criterion of this test is the difference of the "; 
print "average amplitute of the splited ms with the first test ";
print "is less than 5%"

etime := time();
print spaste('### Finished in run time = ', (etime - stime), ' seconds');

}


