pragma include once;

include 'ddlws.g'
include 'viewer.g'

multidisplay := subsequence(ID=1, title='Livedata Viewer') {
    its := [=];
    its.ID := ID
    its.title := title;
    its.whenevers := [];
    its.pushwhenever := function() {
        wider its;
        its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
        return T;
    }
    const its.deactivate := function(which) {
        if (is_integer(which)) {
            n := length(which);
            if (n>0) {
                for (i in 1:n) {
                    ok := whenever_active(which[i]);
                    if (is_fail(ok)) {
                    } else {
                        if (ok) {
			    deactivate which[i];
			}
                    }
                }
            }
        }
        return T;
    }

    self.done := function() {
      wider its, self;
#      its.axdd.done();
#      its.dd.done();
#      its.pd.done();
      its.deactivate(its.whenevers);
      #its.viewer.done();
      its := F;
      self := F;
    }

    #its.viewer := viewer('pksmonitor');
    #vw := ref its.viewer;
    
    vw := ref defaultviewer;
    layout := [=];
    layout.file := T;
    layout.tools := F;
    layout.displaydata := F;
    its.pd := vw.newdisplaypanel(maptype='index', newcmap=T,
				 guihasmenubar=layout);
    its.pd.setoptions([bottommarginspacepg=9, leftmarginspacepg=10])

    its.dd := vw.loaddata(unset,'pksmultibeam');    

    its.axdd := vw.loaddata(unset,'worldaxes');
    its.axdd.setoptions([titletext=its.title]);
    its.pd.register(its.dd);

    its.pd.register(its.axdd);

    whenever self->terminate do {
	self.done();
    } its.pushwhenever();

    whenever self->scrollBufAddImage do {
	rec := [=];
	rec.update:=[=];
	rec.update.value:= $value;
	its.dd.setoptions(rec);
    } its.pushwhenever();

    whenever self->scrollBufBegin do {
        self->imageID(its.ID)
	rec := [=]; rec.init := [=];
	rec.init.value := $value;
	its.dd.setoptions(rec);
    } its.pushwhenever();

    whenever self->unmap do {
        its.pd.dismiss()
    } its.pushwhenever();

    whenever self->map do {
        its.pd.gui()
    } its.pushwhenever();

#    print 'multidisplay created.';
}
