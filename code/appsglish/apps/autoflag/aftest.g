# Make test MS
include 'imager.g';
shell('rm -rf ./3C273XC1.ms');
#shell('tar xpzf 3C273XC1.ms.tgz');
imagermaketestms('3C273XC1.ms');

# Run autoflag tool
include 'autoflag.g';
af:=autoflag('3C273XC1.ms');
af.setdata();
af.settimemed(thr=6,hw=5);
af.setuvbin(nbins=100,thr=.01);
af.settimemed(thr=5,hw=5,expr="- ABS RR LL");
af.setselect(autocorr=T,quack=[60,120]);
af.run(trial=T);
af.run();
af.reset("timemed");
af.run(trial=T);
af.run();
af.done();

system.output.pager.limit:=-1;
include 'ms.g'
myms:=ms('3C273XC1.ms');
print "It takes awhile for the history log to be printed...";
myms.summary(verbose=T);
exit
