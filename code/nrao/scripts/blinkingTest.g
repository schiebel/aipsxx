##
# Blinking Demo
#
#  This script copies over two AIPS++ data cubes
#  and demonstrates the use of blinking.

pragma include once;

include 'timer.g'
include 'viewer.g'
include 'note.g'
include 'logger.g'

system.output.olog := 'SSGTesting.log'

blinkingTest := function() {
stime := time();
nametest := 'Image blinking test'

# get data files and place them in current directory
shell('cp -r /aips++/data/bima/test/sgrb2n.spw1.dirty .');
shell('cp -r /aips++/data/bima/test/sgrb2n.spw1.restored .');
mdp := dv.newdisplaypanel();
mdd1 := dv.loaddata('sgrb2n.spw1.dirty', 'raster');
mdd2 := dv.loaddata('sgrb2n.spw1.restored', 'raster');
mdp.register(mdd1);
mdp.register(mdd2);
# (For '/aips++', you may need to substitute the directory where
# aips++ is installed on your system).
an := mdp.animator();
an.goto(61);
an.setmode('blink');
an.forwardplay(); 

ok := T;
if(ok)
print spaste('### ', nametest, '... passed');
else
print spaste('### ', nametest, '... failed');

t := timer.wait(5)
an.stop();
mdp.done();
print "The criterion of passing the blinking test is "
print "the blinking image showes on the screen"

etime := time();
print spaste('### Finished in run time = ', (etime - stime), ' seconds');

}

