pragma include once;

include 'imager.g'
include 'measures.g'
include 'logger.g'

system.output.olog := 'SSGTesting.log'

multiSpwTest := function(){
stime := time();
nametest := 'Multi-spectral window test';

#Example of multi-spectral window imaging (also demonstrates velocity domain
#gridding - Uses GBT G40-14 data set (Lockman)
#

dir:=dm.direction('GALACTIC','0.698131701rad', '-0.244346095rad')

myim:=imager('temp07_SP')

###select 2 spw...and start, step and nchan of data could be 
### independently selected.. here i am using slightly more on each
### (as i do not know which channel match the beg and end of velocity i want in ### the image.
### 1 was observed in LSRK and 3 in TOPO

myim.setdata(mode='channel',start=[590, 590],step=[1,1],nchan=[320, 320],fieldid=1,spwid=[1,3]);


#### define the image in velocity domain and each plane is 2km/s wide 
###

myim.setimage(nx=216,ny=216,cellx='3arcmin',celly='3arcmin',mode='velocity',nchan=150, mstart='-125km/s', mstep='2km/s', phasecenter=dir, doshift=T, spwid=[1,3])

### Voila and it checks if the topo observed has shifted in time 
### and recorrects as its going throgh the data...so that a 
### given line remain fixed in LSRK !!

myim.setoptions(ftmachine='sd',gridfunction='BOX');
ok := myim.makeimage(image='G40m14_s2_b.im',type='singledish');

myim.close()
myim.done()

if(ok)
print spaste('### ', nametest, '... passed');
else
print spaste('### ', nametest, '... failed');
print "----------------------------------------------------------";
print "The pass criterion of this test is the multi-spectral window ";
print "image can be generated ";


etime := time();
print spaste('### Finished in run time = ', (etime - stime), ' seconds');
}
