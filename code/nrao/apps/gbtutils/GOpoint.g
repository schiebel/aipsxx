include 'quanta.g';
include 'gfitgauss.g';
include 'polyfitter.g';
include 'pgplotter.g';
include 'measures.g';
include 'statistics.g';

gopointfit := polyfitter();
gopointpg := pgplotter();
gopointpg.title('IARDS Pointing/Continuum Display');

GOpoint:=function(proj,minsc,maxsc=0,rx=0,passthreshold='LOOSE')
{
    global lpc_az1,lpc_az2,lpc_el;
    private.scan_num := -1;
    private.rcvrNum := -1;
    private.phaseNum := -1;
    private.scantable := F;

    rangetest := function(expected,vals,pct)
    {
	for (i in 1:len(vals));
	if ((vals[i]/expected) < 1-pct/100 || (vals[i]/expected) > 1+pct/100) {
	    return F;
	}
	return T;
    }

    getRPmask := function(rcvr,phase) 
    {
	wider private;
	allrcvrs := private.scantable.getcol("NRAO_GBT_SAMPLER_ID");
	allphases := private.scantable.getcol("NRAO_GBT_STATE_ID");
	uniquercvrs := unique(allrcvrs);
	uniquephases := unique(allphases);
	rcvrmask:=uniquercvrs[as_integer(rcvr)+1]==allrcvrs;
	phasemask:=uniquephases[as_integer(phase)+1]==allphases;
	mask := rcvrmask&phasemask;
	return mask;
    }

    test_srp := function(s,r,p)
    {
	wider private;
	test := unique(private.maintable.getcol('SCAN_NUMBER'));
	if (len(test[test==s])==0) {
	    return T;
	}
	if (len(private.nrx[private.nrx==r])==0) {
	    return T;
	}
	if (len(private.nph[private.nph==p])==0) {
	    return T;
	}
	return F;
    }
 
    getGO := function(scan)
    {
	wider private;
	rec := [=];
	GOSubTable := private.GOSubTable.query(paste("SCAN == ",scan,sep=""));
	if (is_fail(GOSubTable)) {
	    dl.log(message='No GO info found',priority='SEVERE',postcli=T);
	    return F;
	}
	if (GOSubTable.nrows() == 0) {
	    dl.log(message='No GO info found: nrows=0',priority='SEVERE',postcli=T);
	    return F;
	}
	if (GOSubTable.nrows() != 1) 
	    dl.log(message='GO subtable has > 1 entries.  Using the first.',
		   priority='WARN',postcli=T);
	trow := tablerow(GOSubTable);
	rec := trow.get(1);
	GOSubTable.close();
	trow.close();
	if (rec.COORDSYS != 'RADEC') {
	    dl.log(message='Cannot handle that coordinate system',priority='SEVERE',postcli=T);
	    return F;
	}
	if (!has_field(rec,'RA')) {
	    rec.RA := rec.MAJOR;
	    rec.DEC := rec.MINOR;
	}
	if (rec.EQUINOX == 1950) {
	    b1950_position := dm.direction('B1950',paste(rec.RA,'deg',sep=""),
					   paste(rec.DEC,'deg',sep=""));
	    j2000_position := dm.measure(b1950_position,'J2000');
	    rec.RA := j2000_position.m0.value/pi*180;
	    rec.DEC := j2000_position.m1.value/pi*180;
	}
	else if (rec.EQUINOX != 2000) {
	    dl.log(message='Cannot handle the Equinox',priority='SEVERE',postcli=T);
	    return F;
	}
	return rec;
    }

    gauss:=function(xarray,yarray,ht,wd,ctr,plotflag=1) {
	wider private;
	ok:=setState([height=ht,width=wd,center=ctr]);
	ok:=setMaxIter(15);
	ymax := max(yarray);
	x2 := xarray[yarray>(ymax/2.5)];
	y2 := yarray[yarray>(ymax/2.5)];
	result:=fitGauss(x2,y2);
	yfit:=evalGauss(xarray);
	resid:=yarray-yfit;
	xarrayplot := seq(xarray[1],xarray[len(xarray)],
			  (xarray[len(xarray)]-xarray[1])/200);
	yfitplot := evalGauss(xarrayplot);
	result.x := xarrayplot;
	result.y := yfitplot;
	if (plotflag) {
	    gopointpg.plotxy(xarrayplot,yfitplot,T,F,,,,3);
	}
	result.chisq2 := sum(((yarray-yfit)^2/yfit))/(len(yarray)-3);
	return result;
    }

   getDcrTcalValues := function()
    {
	wider private;
	# returns the vector of tcal values appropriate for the current
	# private.scantable - one value per CHANNELID in the DCR FITS
	# file for this scan.
	# in the filled MS - NRAO_GBT_SAMPLER_ID corresponds to CHANNELID
	samplerIds := private.scantable.getcol('NRAO_GBT_SAMPLER_ID')+1;
	dataDescIds := private.scantable.getcol('DATA_DESC_ID')+1;
	uChanIds := unique(samplerIds);
	result := array(1.0, len(uChanIds));

	caltime := private.calTable.getcol('TIME');
	timemask := private.scantable.getcol('TIME')[1]==caltime;

	global calRows := [1:private.calTable.nrows()][timemask];
	calQuery := private.calTable.query('rownumber() in $calRows');
	if (calQuery.nrows() < 1) {
	    dl.log(message='Error in Tcal retrieval',priority='SEVERE',
		   postcli=T);
	    dl.log(message='Using Tcal = 1',priority='SEVERE',postcli=T);
	    dl.log(message='Contact Jim Braatz about this.',priority='SEVERE',
		   postcli=T);
	    print calQuery.nrows();
	} else {
	    # ddids and feedis for each unique CHANNELID
	    ddids := array(-1,len(uChanIds));
	    feedids := array(-1,len(uChanIds));
	    feedCol := private.scantable.getcol('FEED1');
	    ddidCol := private.scantable.getcol('DATA_DESC_ID')+1;
	    for (chanid in uChanIds) {
		repRow := (ind(samplerIds)[samplerIds==chanid])[1];
		ddids[chanid] := ddidCol[repRow];
		feedids[chanid] := feedCol[repRow];
	    }
	    # it might make sense to just cache the pol IDs and data 
	    # desc IDs from the main table
	    polidCol := private.dataDescTable.getcol('POLARIZATION_ID');
	    spwidCol := private.dataDescTable.getcol('SPECTRAL_WINDOW_ID');
	    tcalErrorGiven := False;
	    for (ddrow in unique(ddids)) {
		theseFeeds := unique(feedids[ddids==ddrow]);
		thisSpwId := spwidCol[ddrow];
		# DCR always has rcpt1==rcpt2, no cross-corr and currently 
		# there's just one corr per row of the MS
		thisCorrProd := private.polTable.getcell('CORR_PRODUCT',
							 (polidCol[ddrow]+1));
		rcpt1 := thisCorrProd[1,1]+1;
		for (thisFeed in theseFeeds) {
		    # final selection - time was already done in calQuery
		    thisCalQuery := calQuery.query(spaste('FEED_ID==',
                                        thisFeed,' && SPECTRAL_WINDOW_ID==',
							  thisSpwId));
		    tcalMask := (feedids == thisFeed) & (ddids==ddrow);
		    if ((len(tcalMask) < 1 || thisCalQuery.nrows() != 1) && 
			!tcalErrorGiven) {
			dl.log(message='Partial error in Tcal retrieval',
			       priority='SEVERE',postcli=T);
			dl.log(message='Using Tcal = 1 for some feeds',
			       priority='SEVERE',postcli=T);
			dl.log(message='Contact Jim Braatz about this.',
			       priority='SEVERE',postcli=T);
			print thisFeed, ddrow, len(tcalMask), 
			    thisCalQuery.nrows();
			tcalErrorGiven := True; # only emit that once
		    } else {
			# all these rows should now have the same shape, 
			# pull off rcpt1 from them
			result[tcalMask] := 
			    thisCalQuery.getcell('TCAL',1)[rcpt1];
		    }
		    thisCalQuery.done();
		}
	    }
	    calQuery.done();
	}
	
	return result;
    }
 
    getscan := function(scan) {
	wider private;
	private.currentscan := [=];
	if ( private.scan_num != scan ) {
	    private.scan_num := scan;
	    if ( ! is_boolean(private.scantable) ) private.scantable.done();
	    slist := unique(private.maintable.getcol('SCAN_NUMBER'));
	    if (len(slist[slist==scan])==0) {
		dl.log(message='Scan not found.',priority='SEVERE',postcli=T);
		return F;
	    }
	    private.scantable:=private.maintable.query(paste('SCAN_NUMBER == ',scan));
	    mask1 := getRPmask(0,0);
	    thetime:=private.scantable.getcol('TIME');
	    private.currentscan.time := thetime[mask1];
	    private.currentscan.GO_header := getGO(scan);
	    if (is_boolean(private.currentscan.GO_header)) return F;
	    data  := private.scantable.getcol('FLOAT_DATA');
	    private.nrx := unique(private.scantable.getcol('NRAO_GBT_SAMPLER_ID'));
	    private.nph := unique(private.scantable.getcol('NRAO_GBT_STATE_ID'));
	    private.currentscan.data := array(0,len(private.nrx),len(private.nph),
					      len(private.currentscan.time));
	    if (len(private.currentscan.time)<2) {
		dl.log(message='Configuration error.',priority='SEVERE',postcli=T);
		return F;
	    }
	    for (i in (private.nrx+1))
		for (j in (private.nph+1)) {
		    mask1 := getRPmask(i-1,j-1);
		    private.currentscan.data[i,j,] :=data[mask1];
		}
	    pointtime:= private.pointTable.getcol('TIME');
	    big_pointdir := private.pointTable.getcol('DIRECTION');
	    pointdir := array(0,2,len(private.currentscan.time));

	    # The if blocks that follow include a fairly unsophisticated attempt to
	    # correct a scan which includes DCR data but no corresponding antenna
	    # position, which can occassionally happen at the end of a scan.

	    maskErrorFlag := F;
	    for (i in 1:len(private.currentscan.time)) {
		mask := pointtime==private.currentscan.time[i];
		if (sum(mask)!=1) {
		    if (!maskErrorFlag) {
			dl.log(message='There is no corresponding antenna pointing information for some of the data.',
                               priority='SEVERE',postcli=T);
			dl.log(message='This often means there is a problem with the antenna FITS file.',
			       priority='SEVERE',postcli=T);
			dl.log(message='Attempting to fix it.  Check results carefully.',
			       priority='WARNING',postcli=T);
		    }
		    maskErrorFlag := T;
		    if (i>1) {
			pointdir[,i] := pointdir[,i-1];
		    } else {
			dl.log(message='Cannot fix error due to missing antenna pointings.',priority='SEVERE',postcli=T);
			return F;
		    }
		} else {
		    pointdir[,i] := big_pointdir[,1,mask];
		}
	    }
	    private.ra := pointdir[1,];
	    private.dec := pointdir[2,];
	    private.scan_num := scan;
	    private.rcvrNum:=-2;
	    private.phaseNum:=-2;
	    private.tcalvalue := getDcrTcalValues();
	}
	return T;
    }

     point1:=function(scan,receiver,xaxis=0,cal_value=1,basepct=10,plotflag=1)
    {
	wider private;
	if (scan != private.scan_num) {
	    ok := getscan(scan);
	    if (!ok) return F;
	}
	if (len(private.nph)!=2 & len(private.nph)!=4) {
	    dl.log(message='Bad number of phases.',priority='SEVERE',postcli=T);
	    return F;
	}
	if (test_srp(scan,receiver,0)) {
	    dl.log(message='Scan or receiver not found',priority='SEVERE',postcli=T);
	    return F;
	}
	maintime := private.scantable.getcol('TIME');
	data1 := private.scantable.getcol("FLOAT_DATA")[1,1,];
	receiver := as_integer(receiver);
	mask1 := getRPmask(receiver, 0);
	mask2 := getRPmask(receiver, 1);
	maintime := maintime[mask1];
 
	if (xaxis==0)
	{
	    ra_range := abs(private.ra[len(private.ra)]- private.ra[1]);
	    dec_range := abs(private.dec[len(private.dec)]- private.dec[1]);
	    if (ra_range > dec_range) xaxis:=1;
	    else xaxis := 2;
	}
 
        hasSkyfreq := has_field(private.currentscan.GO_header,'SKYFREQ');

	pointdir := array(0,2,len(maintime));
	pointdir[1,]:=private.ra;
	pointdir[2,]:=private.dec;
 
	cmd_position := dm.direction('J2000','0h0m0s','0d0m0s');

	#
	#  This will have problems if the scan crosses the meridian
	#

	if (private.currentscan.GO_header.RA > 180) {
	    cmd_position.m0.value := private.currentscan.GO_header.RA/180*pi-2*pi;
	} else {
	    cmd_position.m0.value := private.currentscan.GO_header.RA/180*pi;
	}
	cmd_position.m1.value := private.currentscan.GO_header.DEC/180*pi;
  
	# calculate Az, El for the commanded position
 
	j_time := [=];
	j_time.m0.value := maintime[as_integer(len(maintime)/2)];
	j_time.m0.unit := 's';
	j_time.refer:='UTC';
	j_time.type:='epoch';
	j_pos := dm.observatory('GBT');
	dm.doframe(j_time);
	dm.doframe(j_pos);
	azel1 := dm.measure(cmd_position,'azel');
 
	pointdir[1,] -:= cmd_position.m0.value;
	pointdir[2,] -:= cmd_position.m1.value;
	pointdir[1,] *:= (180/pi)*60*cos(cmd_position.m1.value);
	pointdir[2,] *:= (180/pi)*60;
 
	if (len(private.nph)==2) {
	    data_ph1 := data1[mask1];
	    data_ph2 := data1[mask2];
	    counts_per_K := sum((data_ph2 - data_ph1) / cal_value) / length(data_ph2);
	    cal_data := data_ph1 / counts_per_K;
	}
	else if (len(private.nph)==4) {
	    if (hasSkyfreq && 
	        private.currentscan.GO_header.SKYFREQ < 12e9) {
		dl.log(message='Frequency not in the expected range for beam switched data.',
		       priority='SEVERE',postcli=T);
		return F;
	    }
	    data_ph1 := data1[mask1];
	    data_ph2 := data1[mask2];
	    mask3 := getRPmask(receiver, 2);
	    mask4 := getRPmask(receiver, 3);
	    data_ph3 := data1[mask3];
	    data_ph4 := data1[mask4];
	    counts_per_K1 := sum((data_ph2 - data_ph1) / cal_value) / length(data_ph2);
	    counts_per_K2 := sum((data_ph4 - data_ph3) / cal_value) / length(data_ph4);
	    #   cal_data_ref := data_ph1 / counts_per_K1
	    #   cal_data_sig := data_ph3 / counts_per_K2
	    cal_data_sig := data_ph1 / counts_per_K1;
	    cal_data_ref := data_ph3 / counts_per_K2;
	    cal_data := cal_data_sig - cal_data_ref;
	}
	if (xaxis==1) 
	{
	    xval := pointdir[1,];
	    dirstring := 'RA';
	} else {
	    xval := pointdir[2,];
	    dirstring := 'Dec';
	}
	basefit := as_integer(basepct/100*len(cal_data)+0.5);
	suby[1:basefit]:=cal_data[1:basefit];
	suby[(basefit+1):(2*basefit)]:=cal_data[(len(cal_data)+1-basefit):len(cal_data)];
	subx[1:basefit] := xval[1:basefit];
	subx[(basefit+1):(2*basefit)] := xval[(len(xval)+1-basefit):len(xval)];
	ok:=gopointfit.fit(coeff,coefferrs,chisq,subx,suby,order=1,sigma=1);
	bfit_y:=coeff[2]*xval + coeff[1];
	flat_y:=cal_data - bfit_y;
	if (plotflag==1)
	{
	    gopointpg.clear();
	    gopointpg.plotxy(xval,flat_y,T,T,'Offset (min)','Power',
			     paste(scan,":",receiver,":",private.currentscan.GO_header.OBJECT,
				   ":",dirstring));
	}
	peak_guess := max(flat_y);
	xval_peak := xval[flat_y==peak_guess];
	if (len(xval_peak)==0) {
	    dl.log(message='Cannot reduce this data.',priority='SEVERE',postcli=T);
	    return F;
	}

	if (!hasSkyfreq) {
	    dl.log(message='Cannot determine guess at FWHM because freq is missing from GO info.',
		   priority='WARNING',postcli=T);
	    dl.log(message='Guessing FWHM=1',priority='WARNING',postcli=T);
	    fwhm_guess := 1;
	} else {
	    fwhm_guess := 1.3*3.0E8/private.currentscan.GO_header.SKYFREQ/100*180/pi*60;
	}
	res := gauss(xval,flat_y,peak_guess,fwhm_guess,xval_peak,plotflag);
	obs_position := cmd_position;
	if (xaxis==1) {
	    obs_position.m0.value := cmd_position.m0.value + 
		res.center/((180/pi)*60*cos(cmd_position.m1.value));
	} else {
	    obs_position.m1.value := cmd_position.m1.value + res.center/((180/pi)*60);
	}
	azel2 := dm.measure(obs_position,'azel');
	rec := [=];
	rec.d_az := (azel2.m0.value - azel1.m0.value)*(180/pi)*60*cos(azel2.m1.value);
	rec.d_el := (azel2.m1.value - azel1.m1.value)*(180/pi)*60;
	rec.x := xval;
	rec.data := flat_y;
	rec.fitx := res.x;
	rec.fit := res.y;
	rec.center := res.center;
	rec.width := res.width;
	rec.height := res.height;
	rec.chisq := res.chisq2;
	rec.title := paste(scan,':',receiver,':',
			   private.currentscan.GO_header.OBJECT,':',dirstring);
	rec.az := azel1.m0.value;
	rec.el := azel1.m1.value;
	rec.xaxis := xaxis;
	rec.src_name := private.currentscan.GO_header.OBJECT;
	if (len(private.nph)==2) rec.tsys := mean(bfit_y);
	else rec.tsys := mean(cal_data_ref);
	return rec;
    }
 
    point2:=function(scan,receiver,cal_value=1)
    {
	wider private;
	private.scan_num := F;
	private.scantable := F;
	p2_rec := [=];
	twoscan:=scan:(scan + 1);
	j:=0; az_sum := 0; el_sum := 0;
	for (nscan in twoscan) {
	    j +:= 1;
	    p1_rec := point1(nscan,receiver,plotflag=0,cal_value=cal_value);
	    if (is_boolean(p1_rec)) return F;
	    az_sum +:= p1_rec.d_az;
	    el_sum +:= p1_rec.d_el;
	    if (j==1) {
		plot_x := array(0,2,len(p1_rec.x));
		plot_data := array(0,2,len(p1_rec.x));
		plot_fitx := array(0,2,len(p1_rec.fitx));
		plot_fit := array(0,2,len(p1_rec.fitx));
	    }
	    plot_x[j,]    := p1_rec.x;
	    plot_data[j,] := p1_rec.data;
	    plot_fitx[j,] := p1_rec.fitx;
	    plot_fit[j,]  := p1_rec.fit;
	    plot_d_az[j] := p1_rec.d_az;
	    plot_d_el[j] := p1_rec.d_el;
	    plot_lab[j] := p1_rec.title;
	    plot_center[j] := p1_rec.center;
	    plot_width[j] := p1_rec.width;
	    plot_height[j] := p1_rec.height;
	    plot_tsys[j] := p1_rec.tsys;
	    p2_rec.full_az := p1_rec.az;
	    p2_rec.full_el := p1_rec.el;
	    p2_rec.chisq[j] := p1_rec.chisq;
	    ok := (p1_rec.center < 1e4) & (p1_rec.center > -1e4) &
		(p1_rec.width  > 0  ) & (p1_rec.width  < 100 ) &
		    (p1_rec.height > 0  ) & (p1_rec.height < 1e4 );
	    if (!ok) {
		plot_center[j] := 0;
		plot_width[j]  := 0;
		plot_height[j] := 0;
		plot_fit[j,]   := 0;
		plot_d_az[j]   := 0;
		plot_d_el[j]   := 0;
	    }
	}
	gopointpg.clear();
	gopointpg.subp(2,1);
	gopointpg.sch(1.5);
	for (i in 1:j) {
	    gopointpg.sci(1);
	    gopointpg.plotxy(plot_x[i,],plot_data[i,]);
	    gopointpg.lab('Offset (min)','T',plot_lab[i]);
	    gopointpg.sci(3);
	    gopointpg.line(plot_fitx[i,],plot_fit[i,]);
	    gopointpg.sci(1);
	    gopointpg.mtxt('T',-2,.03,0,sprintf('Ctr: %4.3f',plot_center[i]));
	    gopointpg.mtxt('T',-3,.03,0,sprintf('Wid: %4.3f',plot_width[i]));
	    gopointpg.mtxt('T',-4,.03,0,sprintf('Hgt: %4.3f',plot_height[i]));
	    gopointpg.mtxt('T',-2,.6,0,sprintf('dAz:  %7.3f',plot_d_az[i]));
	    gopointpg.mtxt('T',-3,.6,0,sprintf('dEl:  %7.3f',plot_d_el[i]));
	    gopointpg.mtxt('T',-4,.6,0,sprintf('Tsys: %7.3f',plot_tsys[i]));
	    gopointpg.sls(2);
	    gopointpg.sci(15);
	    gopointpg.line([-1000,1000],[0,0]);
	    gopointpg.line([0,0],[-1000,1000]);
	    gopointpg.sls(1);
	}
	p2_rec.az := az_sum/2;
	p2_rec.el := el_sum/2;
	p2_rec.center := plot_center;
	p2_rec.width := plot_width;
	p2_rec.height := plot_height;
	return p2_rec;
    }

    if (len(dos.dir('/tmp','gopoint*'))>0) {
	dos.remove('/tmp/gopoint*');
	if (len(dos.dir('/tmp','gopoint*'))>0) 
	    print 'Warning: there are files in /tmp which I cannot clean up.';
    }
    tstamp := as_integer(time());
    ok := shell(paste('gbtmsfiller project=',proj,' minscan=',minsc,' maxscan=',
		      minsc+1,' msrootname=gopoint',tstamp,' msdirectory=/tmp',sep=""));

    fname := paste('/tmp/gopoint',tstamp,'DCR',sep="");
    private.maintable:=table(fname, lockoptions='usernoread',ack=F);
    if (is_fail(private.maintable)) {
	dl.log(message='Error loading table',priority='SEVERE',postcli=T);
	return F;
    }
   
    gokw := 'GBT_GO';
    kws := private.maintable.keywordnames();
    if (!any(kws == gokw)) {
	gokw := 'NRAO_GBT_GO';
	if (!any(kws == gokw)) {
	    gokw := 'NRAO_GBT_GLISH';
	    if (!any(kws == gokw)) {
		dl.log(message='Configuration problem.  No GO information available.',
		       priority='SEVERE',postcli=T);
		return F;
	    }
	}
    }
    private.GOSubTable := table(private.maintable.getkeyword(gokw),
				lockoptions='usernoread', ack=F);
    private.pointTable := table(private.maintable.getkeyword('POINTING'),
				lockoptions='usernoread', ack=F);
    private.pModelTable := 
	table(private.maintable.getkeyword('NRAO_GBT_POINTING_MODEL'),
	      lockoptions='usernoread', ack=F);
    private.calTable := table(private.maintable.getkeyword('SYSCAL'),
			      lockoptions='usernoread', ack=F);
    private.dataDescTable := 
	table(private.maintable.getkeyword('DATA_DESCRIPTION'),
	      lockoptions='usernoread', ack=F);
    private.polTable := table(private.maintable.getkeyword('POLARIZATION'),
			      lockoptions='usernoread', ack=F);
    if (is_fail(private.pointTable) || is_fail(private.pModelTable)
	|| is_fail(private.calTable) || is_fail(private.dataDescTable)
	|| is_fail(private.polTable)) {
	dl.log(message='Configuration problem.  Cannot process this data.',priority='SEVERE',
	       postcli=T);
	for (field in private) {
	    if (is_table(field)) field.done();
	}
	return F;
    }

    lpc_az1 := unique(private.pModelTable.getcol('LPC_AZ1'));
    lpc_az2 := unique(private.pModelTable.getcol('LPC_AZ2'));
    lpc_el := unique(private.pModelTable.getcol('LPC_EL'));
    if ((len(lpc_az1)!=1) || (len(lpc_az2)!=1) || (len(lpc_el)!=1)) {
	dl.log(message='Too many LPC entries.  Can not handle this.',priority='SEVERE',postcli=T);
	return F;
    }
    
    # this is a no-op so long as the scan called in point1 and point2 is the
    # same scan number as here.  Do it here so that the tcal values can be known.
    if (getscan(minsc)) {
       print 'Tcal = ',private.tcalvalue[rx+1];
       print '';
    } else {
       print 'there is a problem in the scan'
       ok := dos.remove('/tmp/gopoint*');
       return F;
    }
    
    rec := point2(minsc,rx,private.tcalvalue[rx+1]);
    if (is_boolean(rec)) {
        ok := dos.remove('/tmp/gopoint*');
        return F;
    }
    
    for (field in private) {
	if (is_table(field)) {
	    field.done();
	}
    }
    ok := dos.remove('/tmp/gopoint*');
    
    result := [=];
    result.az := rec.full_az;
    result.el := rec.full_el;
    result.d_az := rec.az;
    result.d_el := rec.el;
    # Just pass az1 value through.  Is it correct to multiply by 60?
    result.oldaz1 := lpc_az1*60;
    result.oldaz2 := lpc_az2*60;
    result.oldel := lpc_el*60;
    result.newaz1 := result.oldaz1;
    result.newaz2 := result.oldaz2 + result.d_az;
    result.newel := result.oldel + result.d_el;
    result.chisq := rec.chisq;
    result.center := rec.center;
    result.width := rec.width;
    result.height := rec.height;
    
    # Determine if the result should be accepted
    
    result.pass := T;
    hasSkyfreq := has_field(private.currentscan.GO_header,'SKYFREQ');
    if (hasSkyfreq) {
        expectedwidth := 1.3*3.0E8/private.currentscan.GO_header.SKYFREQ/100*180/pi*60;
    } else {
        expectedwidth := 0;
    }
    if (passthreshold=='NORM')
    {	if (!hasSkyfreq) {
	    result.pass := F;
            print 'Autopass Failed: missing frequency information in GO info.';
        } else {
	    if (!rangetest(expectedwidth,result.width,20)) {
	        result.pass := F;
	        print 'Autopass Failed: Expected width = ',expectedwidth;
	    }
        }
	if (!rangetest(mean(result.width),result.width,20)) {
	    result.pass := F;
	    print 'Autopass Failed: widths of two scans inconsistent';
	}
	if (!rangetest(mean(result.height),result.height,20)) {
	    result.pass := F;
	    print 'Autopass Failed: heights of two scans inconsistent';
	}
	for (i in 1:len(result.center))
	    if (result.center[i] < -25 || result.center[i] > 25) {
		result.pass := F;
		print 'Autopass Failed: peak not close enough to center of scan';
	    }
    }
    else if (passthreshold=='LOOSE')
    {
        if (!hasSkyfreq) {
            result.pass := F;
            print 'Autopass Failed: missing frequency information in GO info.';
        } else {
	    if (!rangetest(expectedwidth,result.width,80)) {
	        result.pass := F;
	        print 'Autopass Failed: Expected width = ',expectedwidth;
	    }
        }
	if (!rangetest(mean(result.width),result.width,80)) {
	    result.pass := F;
	    print 'Autopass Failed: widths of two scans inconsistent';
	}
	if (!rangetest(mean(result.height),result.height,80)) {
	    result.pass := F;
	    print 'Autopass Failed: heights of two scans inconsistent';
	}
	for (i in 1:len(result.center))
	    if (result.center[i] < -80 || result.center[i] > 80) {
		result.pass := F;
		print 'Autopass Failed: peak not close enough to center of scan';
	    }
    }
    if (!result.pass) {
	print '                 Pointing correction will not be auto-updated.';
	print '                 Enter the corrections by hand if you want to apply.';
    }
    gopointpg.sci(1);
    gopointpg.mtxt('T',-5,.6,0,sprintf('Pass: %s',as_string(result.pass)));
    if (result.az < 0) result.az +:= 2*pi;
    printf('    Az: %7.3f      El: %7.3f\n\n',result.az*180/pi,result.el*180/pi);
    printf('OldAz1: %7.3f  OldAz2: %7.3f  OldEl: %7.3f\n',
	   result.oldaz1,result.oldaz2,result.oldel);
    printf('                   dAz2: %7.3f    dEl: %7.3f\n',
	   result.d_az,result.d_el);
    printf('NewAz1: %7.3f  NewAz2: %7.3f  NewEl: %7.3f\n',
	   result.newaz1,result.newaz2,result.newel);
    print '--------------------------------------------------------------------';
    return result;
}

GOtrack:=function(proj,jscan,cal_value=1)
{
    private := [=];
    
    getRPmask := function(rcvr,phase)
    {
	wider private;
	allrcvrs := private.maintable.getcol("NRAO_GBT_SAMPLER_ID");
	allphases := private.maintable.getcol("NRAO_GBT_STATE_ID");
	uniquercvrs := unique(allrcvrs);
	uniquephases := unique(allphases);
	rcvrmask:=uniquercvrs[as_integer(rcvr)+1]==allrcvrs;
	phasemask:=uniquephases[as_integer(phase)+1]==allphases;
	mask := rcvrmask&phasemask;
	return mask;
    }
    
    getGO := function(scan)
    {
	wider private;
	rec := [=];
	GOSubTable := private.GOSubTable.query(paste("SCAN == ",scan,sep=""));
	if (is_fail(GOSubTable)) {
	    dl.log(message='No GO info found.',priority='SEVERE',postcli=T);
	    return F;
	}
	if (GOSubTable.nrows() == 0) {
	    dl.log(message='No GO info found: nrows=0',priority='SEVERE',postcli=T);
	    return F;
	}
	if (GOSubTable.nrows() != 1) 
	    dl.log(message='GO subtable has > 1 entries.  Using the first.',priority='WARN',
		   postcli=T);
	trow := tablerow(GOSubTable);
	rec := trow.get(1);
	GOSubTable.close();
	trow.close();
	if (rec.COORDSYS != 'RADEC') {
	    dl.log(message='Cannot handle this coordinate system',priority='SEVERE',postcli=T);
	    return F;
	}
	if (!has_field(rec,'RA')) {
	    rec.RA := rec.MAJOR;
	    rec.DEC := rec.MINOR;
	}
	if (rec.EQUINOX == 1950) {
	    b1950_position := dm.direction('B1950',paste(rec.RA,'deg',sep=""),
					   paste(rec.DEC,'deg',sep=""));
	    j2000_position := dm.measure(b1950_position,'J2000');
	    rec.RA := j2000_position.m0.value/pi*180;
	    rec.DEC := j2000_position.m1.value/pi*180;
	}
	else if (rec.EQUINOX != 2000) {
	    dl.log(message='Cannot handle the Equinox.',priority='SEVERE',postcli=T);
	    return F;
	}
	return rec;
    }
    
    gettrackscan := function(scan)
    {
	wider private;
	private.currentscan := [=];
	if ( private.scan_num != scan ) {
	    private.scan_num := scan;
	    mask1 := getRPmask(0,0);
	    thetime:=private.maintable.getcol('TIME');
	    private.currentscan.time := thetime[mask1];
	    private.currentscan.GO_header := getGO(scan);
	    if (is_boolean(private.currentscan.GO_header)) return F;
	    data  := private.maintable.getcol('FLOAT_DATA');
	    private.nrx := unique(private.maintable.getcol('NRAO_GBT_SAMPLER_ID'));
	    private.nph := unique(private.maintable.getcol('NRAO_GBT_STATE_ID'));
	    private.currentscan.data := array(0,len(private.nrx),len(private.nph),
					      len(private.currentscan.time));
	    if (len(private.currentscan.time)<2) {
		dl.log(message='Configuration problem.',priority='SEVERE',postcli=T);
		return F;
	    }
	    for (i in (private.nrx+1))
		for (j in (private.nph+1)) {
		    mask1 := getRPmask(i-1,j-1);
		    private.currentscan.data[i,j,] :=data[mask1];
		}
	    private.scan_num := scan;
	    private.rcvrNum:=-2;
	    private.phaseNum:=-2;
	}
	return T;
    }
    
    private.scan_num := F;
    tstamp := as_integer(time());
    ok := shell(paste('gbtmsfiller project=',proj,' minscan=',jscan,' maxscan=',
		      jscan,' msrootname=gotrack',tstamp,' msdirectory=/tmp',sep=""));
    
    fname := paste('/tmp/gotrack',tstamp,'DCR',sep="");
    private.maintable:=table(fname, lockoptions='usernoread', ack=F);
    if (is_fail(private.maintable)) {
	dl.log(message='Error loading table',priority='SEVERE',postcli=T);
	return F;
    }
    
    gokw := 'GBT_GO';
    kws := private.maintable.keywordnames();
    if (!any(kws == gokw)) {
	gokw := 'NRAO_GBT_GO';
	if (!any(kws == gokw)) {
	    gokw := 'NRAO_GBT_GLISH';
	    if (!any(kws == gokw)) {
		dl.log(message='Configuration problem.  No GO information found.',
		       priority='SEVERE',postcli=T);
		return F;
	    }
	}
    }
    private.GOSubTable := table(private.maintable.getkeyword(gokw),
				lockoptions='usernoread', ack=F);

    gopointpg.clear();
    ok := gettrackscan(jscan);
    if (!ok) return F;
    tyme := private.currentscan.time-private.currentscan.time[1];
    for (receiver in (private.nrx+1)) {
	data_ph1 := private.currentscan.data[receiver,1,];
	data_ph2 := private.currentscan.data[receiver,2,];
	counts_per_K := sum((data_ph2-data_ph1)/cal_value)/len(data_ph2);
	cal_data := data_ph1 / counts_per_K;
	gopointpg.plotxy1(tyme,cal_data,'Time (sec)',paste('Tant RX',receiver-1),
			  paste('Antenna Temperature', private.currentscan.GO_header.OBJECT));
    }
    private.GOSubTable.done();
    private.maintable.done();
    ok := dos.remove('/tmp/gotrack*');
}



GOfocus:=function(proj,jscan) {
    private := [=];
    
    getRPmask := function(rcvr,phase) {
	wider private;
	allrcvrs := private.maintable.getcol("NRAO_GBT_SAMPLER_ID");
	allphases := private.maintable.getcol("NRAO_GBT_STATE_ID");
	uniquercvrs := unique(allrcvrs);
	uniquephases := unique(allphases);
	rcvrmask:=uniquercvrs[as_integer(rcvr)+1]==allrcvrs;
	phasemask:=uniquephases[as_integer(phase)+1]==allphases;
	mask := rcvrmask&phasemask;
	return mask;
    }
    
    getGO := function(scan) {
	wider private;
	rec := [=];
	GOSubTable := private.GOSubTable.query(paste("SCAN == ",scan,sep=""));
	if (is_fail(GOSubTable)) {
	    dl.log(message='No GO info.',priority='SEVERE',postcli=T);
	    return F;
	}
	if (GOSubTable.nrows() == 0) {
	    dl.log(message='No GO info.',priority='SEVERE',postcli=T);
	    return F;
	}
	if (GOSubTable.nrows() != 1) 
	    dl.log(message='GO subtable has > 1 entries.  Using the first.',
		   priority='WARN',postcli=T);
	trow := tablerow(GOSubTable);
	rec := trow.get(1);
	GOSubTable.close();
	trow.close();
	if (!has_field(rec,'RA')) {
	    rec.RA := rec.MAJOR;
	    rec.DEC := rec.MINOR;
	}
	if (rec.EQUINOX == 1950) {
	    b1950_position := dm.direction('B1950',paste(rec.RA,'deg',sep=""),
					   paste(rec.DEC,'deg',sep=""));
	    j2000_position := dm.measure(b1950_position,'J2000');
	    rec.RA := j2000_position.m0.value/pi*180;
	    rec.DEC := j2000_position.m1.value/pi*180;
	}
	else if (rec.EQUINOX != 2000) {
	    dl.log(message='Cannot handle the Equinox',priority='SEVERE',postcli=T);
	    return F;
	}
	return rec;
    }
    
   getDcrTcalValues := function()
    {
	wider private;
	# returns the vector of tcal values appropriate for the current
	# private.maintable - one value per CHANNELID in the DCR FITS
	# file for this scan.
	# in the filled MS - NRAO_GBT_SAMPLER_ID corresponds to CHANNELID
	# in GOfocus, only one scan is ever filled
	samplerIds := private.maintable.getcol('NRAO_GBT_SAMPLER_ID')+1;
	dataDescIds := private.maintable.getcol('DATA_DESC_ID')+1;
	uChanIds := unique(samplerIds);
	result := array(1.0, len(uChanIds));

	caltime := private.calTable.getcol('TIME');
	timemask := private.maintable.getcol('TIME')[1]==caltime;

	global calRows := [1:private.calTable.nrows()][timemask];
	calQuery := private.calTable.query('rownumber() in $calRows');
	if (calQuery.nrows() < 1) {
	    dl.log(message='Error in Tcal retrieval',priority='SEVERE',
		   postcli=T);
	    dl.log(message='Using Tcal = 1',priority='SEVERE',postcli=T);
	    dl.log(message='Contact Jim Braatz about this.',priority='SEVERE',
		   postcli=T);
	    print calQuery.nrows();
	} else {
	    # ddids and feedis for each unique CHANNELID
	    ddids := array(-1,len(uChanIds));
	    feedids := array(-1,len(uChanIds));
	    feedCol := private.maintable.getcol('FEED1');
	    ddidCol := private.maintable.getcol('DATA_DESC_ID')+1;
	    for (chanid in uChanIds) {
		repRow := (ind(samplerIds)[samplerIds==chanid])[1];
		ddids[chanid] := ddidCol[repRow];
		feedids[chanid] := feedCol[repRow];
	    }
	    # it might make sense to just cache the pol IDs and data 
	    # desc IDs from the main table
	    polidCol := private.dataDescTable.getcol('POLARIZATION_ID');
	    spwidCol := private.dataDescTable.getcol('SPECTRAL_WINDOW_ID');
	    tcalErrorGiven := False;
	    for (ddrow in unique(ddids)) {
		theseFeeds := unique(feedids[ddids==ddrow]);
		thisSpwId := spwidCol[ddrow];
		# DCR always has rcpt1==rcpt2, no cross-corr and currently 
		# there's just one corr per row of the MS
		thisCorrProd := private.polTable.getcell('CORR_PRODUCT',
							 (polidCol[ddrow]+1));
		rcpt1 := thisCorrProd[1,1]+1;
		for (thisFeed in theseFeeds) {
		    # final selection - time was already done in calQuery
		    thisCalQuery := calQuery.query(spaste('FEED_ID==',
                                        thisFeed,' && SPECTRAL_WINDOW_ID==',
							  thisSpwId));
		    tcalMask := (feedids == thisFeed) & (ddids==ddrow);
		    if ((len(tcalMask) < 1 || thisCalQuery.nrows() != 1) && 
			!tcalErrorGiven) {
			dl.log(message='Partial error in Tcal retrieval',
			       priority='SEVERE',postcli=T);
			dl.log(message='Using Tcal = 1 for some feeds',
			       priority='SEVERE',postcli=T);
			dl.log(message='Contact Jim Braatz about this.',
			       priority='SEVERE',postcli=T);
			print thisFeed, ddrow, len(tcalMask), 
			    thisCalQuery.nrows();
			tcalErrorGiven := True; # only emit that once
		    } else {
			# all these rows should now have the same shape, 
			# pull off rcpt1 from them
			result[tcalMask] := 
			    thisCalQuery.getcell('TCAL',1)[rcpt1];
		    }
		    thisCalQuery.done();
		}
	    }
	    calQuery.done();
	}
	
	return result;
    }

    getfocusscan := function(scan) {
	wider private;
	private.currentscan := [=];
	if ( private.scan_num != scan ) {
	    private.scan_num := scan;
	    mask1 := getRPmask(0,0);
	    thetime:=private.maintable.getcol('TIME');
	    private.currentscan.time := thetime[mask1];
	    private.currentscan.GO_header := getGO(scan);
	    if (is_boolean(private.currentscan.GO_header)) return F;
	    
	    #  This will have problems if the scan crosses the meridian
	    cmd_position := dm.direction('J2000','0h0m0s','0d0m0s');
	    if (private.currentscan.GO_header.RA > 180)
		cmd_position.m0.value := private.currentscan.GO_header.RA/180*pi-2*pi;
	    else
		cmd_position.m0.value := private.currentscan.GO_header.RA/180*pi;
	    cmd_position.m1.value := private.currentscan.GO_header.DEC/180*pi;
	    j_time := [=];
	    maintime := private.currentscan.time;
	    j_time.m0.value := maintime[as_integer(len(maintime)/2)];
	    j_time.m0.unit := 's';
	    j_time.refer:='UTC';
	    j_time.type:='epoch';
	    j_pos := dm.observatory('GBT');
	    dm.doframe(j_time);
	    dm.doframe(j_pos);
	    azel1 := dm.measure(cmd_position,'azel');
	    elevation := azel1.m1.value;
#	    model := -5.842 + 0.392*sin(elevation) + 7.234*cos(elevation);
	    model := -6.8565 + 2.3898*sin(elevation) + 7.5297*cos(elevation);
	    model *:= 25.4;
	    print 'calculated model focus offset = ',model;
	    
	    
	    data  := private.maintable.getcol('FLOAT_DATA');
	    private.nrx := unique(private.maintable.getcol('NRAO_GBT_SAMPLER_ID'));
	    private.nph := unique(private.maintable.getcol('NRAO_GBT_STATE_ID'));
	    private.currentscan.data := array(0,len(private.nrx),len(private.nph),
					      len(private.currentscan.time));
	    if (len(private.currentscan.time)<2) {
		dl.log(message='There is a problem with the configuration.',priority='SEVERE',
		       postcli=T);
		return F;
	    }
	    for (i in (private.nrx+1))
		for (j in (private.nph+1)) {
		    mask1 := getRPmask(i-1,j-1);
		    private.currentscan.data[i,j,] :=data[mask1];
		}
	    private.focus := private.focustable.getcol('SR_YP');
	    private.focus -:= model;
	    private.scan_num := scan;
	    private.rcvrNum:=-2;
	    private.phaseNum:=-2;
	    private.tcalvalue := getDcrTcalValues();
	}
	if (len(private.focus) < 5 ) {
	    dl.log(message='You are not sampling often enough.',priority='SEVERE',postcli=T);
	    return F;
	}
	if (len(private.focus) != len(private.currentscan.data[1,1,])) {
	    dl.log(message='Error in getfocusscan -- incompatible array sizes',priority='SEVERE',
		   postcli=T);
	    return F;
	}
	return T;
    }
    
    private.scan_num := F;
    tstamp := as_integer(time());
    ok := shell(paste('gbtmsfiller project=',proj,' minscan=',jscan,' maxscan=',
		      jscan,' msrootname=gofocus',tstamp,' msdirectory=/tmp',sep=""));
    
    fname := paste('/tmp/gofocus',tstamp,'DCR',sep="");
    private.maintable:=table(fname, lockoptions='usernoread', ack=F);
    if (is_fail(private.maintable)) {
	dl.log(message='Error loading table',priority='SEVERE',postcli=T);
	return F;
    }
    
    gokw := 'GBT_GO';
    kws := private.maintable.keywordnames();
    if (!any(kws == gokw)) {
	gokw := 'NRAO_GBT_GO';
	if (!any(kws == gokw)) {
	    gokw := 'NRAO_GBT_GLISH';
	    if (!any(kws == gokw)) {
		dl.log(message='Configuration problem.  No GO FITS file found.',
		       priority='SEVERE',postcli=T);
		return F;
	    }
	}
    }
    private.GOSubTable := table(private.maintable.getkeyword(gokw),
				lockoptions='usernoread', ack=F);
    private.focustable := 
	table(private.maintable.getkeyword('NRAO_GBT_MEAN_FOCUS'),
	      lockoptions='usernoread', ack=F);
    private.calTable := table(private.maintable.getkeyword('SYSCAL'),
			      lockoptions='usernoread', ack=F);
    private.dataDescTable := 
	table(private.maintable.getkeyword('DATA_DESCRIPTION'),
	      lockoptions='usernoread', ack=F);
    private.polTable := table(private.maintable.getkeyword('POLARIZATION'),
			      lockoptions='usernoread', ack=F);
    
    if (is_fail(private.focustable) || is_fail(private.calTable) ||
	is_fail(private.dataDescTable) || is_fail(private.polTable)) {
	dl.log(message='Configuration problem.',priority='SEVERE',postcli=T);
	for (field in private) {
	    if (is_table(field)) field.done();
	}
	return F;
    }
    
    
    gopointpg.clear();
    ok := getfocusscan(jscan);
    if (!ok) return F;	# 
    
    print 'Tcal = ',private.tcalvalue;
    print '';
    
    # for (receiver in (private.nrx+1)) {
    for (receiver in 1:2) {
	if (len(private.nph)==2) {
	    data_ph1 := private.currentscan.data[receiver,1,];
	    data_ph2 := private.currentscan.data[receiver,2,];
	    counts_per_K := sum((data_ph2-data_ph1)/private.tcalvalue[receiver])/len(data_ph1);
	    cal_data := (data_ph1+data_ph2) / 2 / counts_per_K;
	    print 'Receiver ',receiver,'  Tcal ',private.tcalvalue[receiver];
	}
	else if (len(private.nph)==4) {
	    data_ph1 := private.currentscan.data[receiver,1,];
	    data_ph2 := private.currentscan.data[receiver,2,];
	    data_ph3 := private.currentscan.data[receiver,3,];
	    data_ph4 := private.currentscan.data[receiver,4,];
	    counts_per_K := sum((data_ph4-data_ph3)/private.tcalvalue[receiver])/len(data_ph3);
	    data_avg := ((data_ph1+data_ph2) - (data_ph3+data_ph4))/2;
	    cal_data := data_avg / counts_per_K;
	    print 'Receiver ',receiver,'  Tcal ',private.tcalvalue[receiver];
	}
	
	gopointpg.plotxy1(private.focus,cal_data,'Focus (mm)',
			  paste('Tant ',receiver-1), paste('Focus Curve', 
							   private.currentscan.GO_header.OBJECT));
	
	ok := gopointfit.fit(coeff,coefferrs,chisq,private.focus,cal_data,
			     order=3,sigma=1);
	fitvals := coeff[4]*private.focus^3 + coeff[3]*private.focus^2 +
	    coeff[2]*private.focus   + coeff[1];
	gopointpg.plotxy1(private.focus,fitvals);
	bestfocus[receiver] := -9999;
	jmask := fitvals==max(fitvals);
	if (sum(jmask) != 1) print 'Ahhhhhhh!!!!!';
	bestfocus[receiver] := private.focus[jmask];
    }
    for (field in private) {
	if (is_table(field)) {
	    field.done();
	}
    }
    ok := dos.remove('/tmp/gofocus*');
    mask := bestfocus!=-9999;
    print 'Best Focus = ',bestfocus,'    Mean = ',mean(bestfocus[mask]);
    return mean(bestfocus[mask]);
}

