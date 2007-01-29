include 'gbtmsfiller.g'
include 'popuphelp.g'

include 'printer.g'

global polFlag := F
global intFlag := F
global ifFlag := 1
global bscan := F
global current_scan := F

whenever system->exit do
 shell('rm -rf /tmp/go* > /dev/null 2>&1')

include 'dish.g'
d := dish()

# Eliminate some dish plotter buttons to make room for iards stuff
d.plotter.gfit->text('')
d.plotter.gfit->disabled(T)
d.plotter.lineidb->text('')
d.plotter.lineidb->disabled(T)
d.plotter.title('IARDS Spectral Line')
d.nogui()

polSet := button(d.plotter.userframe(),'Pol',type='menu')
popuphelp(polSet,'Set the polarization feed displayed')
for (i in "both 1 2")
 polButton[i] := button(polSet,i,type='radio')
whenever polButton['both']->press do {
 polFlag := F
 updatePlot()
 }
whenever polButton['1']->press do {
 polFlag := 1
 updatePlot()
 }
whenever polButton['2']->press do {
 polFlag := 2
 updatePlot()
 }
polButton['both']->state(T)

intSet := button(d.plotter.userframe(),'Int',type='menu')
popuphelp(intSet,'Set the integration number displayed')
for (i in "all 1 2 3 4 enter")
 intButton[i] := button(intSet,i,type='radio')
whenever intButton['all']->press do {
 intFlag := F
 updatePlot()
 }
whenever intButton['1']->press do {
 intFlag := 1
 updatePlot()
 }
whenever intButton['2']->press do {
 check := d.qscan(current_scan)
 if (check.ints < 2) {
  dl.log(message=spaste('Selection out of range.  There are ',check.ints, 'integrations.'),priority='SEVERE',postcli=T)
  intButton['all']->state(T)
  }
 else {
  intFlag := 2
  updatePlot()
  }
 }
whenever intButton['3']->press do {
 check := d.qscan(current_scan)
 if (check.ints < 3) {
  dl.log(message=spaste('Selection out of range.  There are ',check.ints, 'integrations.'),priority='SEVERE',postcli=T)
  intButton['all']->state(T)
  }
 else {
  intFlag := 3
  updatePlot()
  }
 }
whenever intButton['4']->press do {
 check := d.qscan(current_scan)
 if (check.ints < 4) {
  dl.log(message=spaste('Selection out of range.  There are ',check.ints, 'integrations.'),priority='SEVERE',postcli=T)
  intButton['all']->state(T)
  }
 else {
  intFlag := 4
  updatePlot()
  }
 }
whenever intButton['enter']->press do {
 inValue := readline('Enter integration number: ')
 intVal := as_integer(inValue)
 check := d.qscan(current_scan)
 if (intVal > 0 && intVal <= check.ints) {
  intFlag := intVal
  updatePlot()
  }
 else {
  dl.log(message=spaste('Selection out of range.  There are ',check.ints, 'integrations.'),priority='SEVERE',postcli=T)
  intButton['all']->state(T)
  }
 }
intButton['all']->state(T)

ifSet := button(d.plotter.userframe(),'IF',type='menu')
popuphelp(ifSet,'Set the IF number displayed')
for (i in "1 2 3 4 enter")
 ifButton[i] := button(ifSet,i,type='radio')
whenever ifButton['1']->press do {
 ifFlag := 1
 updatePlot()
 }
whenever ifButton['2']->press do {
 check := d.qscan(current_scan)
 if (check.ifs < 2) {
  dl.log(message=spaste('Selection out of range.  There are ',check.ifs, 'IFs.'),priority='SEVERE',postcli=T)
  ifButton['1']->state(T)
  }
 else {
  ifFlag := 2
  updatePlot()
  }
 }
whenever ifButton['3']->press do {
 check := d.qscan(current_scan)
 if (check.ifs < 3) {
  dl.log(message=spaste('Selection out of range.  There are ',check.ifs, 'IFs.'),priority='SEVERE',postcli=T)
  ifButton['1']->state(T)
  }
 else {
  ifFlag := 3
  updatePlot()
  }
 }
whenever ifButton['4']->press do {
 check := d.qscan(current_scan)
 if (check.ifs < 4) {
  dl.log(message=spaste('Selection out of range.  There are ',check.ifs, 'IFs.'),priority='SEVERE',postcli=T)
  ifButton['1']->state(T)
  }
 else {
  ifFlag := 4
  updatePlot()
  }
 }
whenever ifButton['enter']->press do {
 inValue := readline('Enter IF number: ')
 intVal := as_integer(inValue)
 check := d.qscan(current_scan)
 if (intVal > 0 && intVal <= check.ifs) {
  ifFlag := intVal
  updatePlot()
  }
 else {
  dl.log(message=spaste('Selection out of range.  There are ',check.ifs, 'IFs.'),priority='SEVERE',postcli=T)
  ifButton['1']->state(T)
  }
 }
ifButton['1']->state(T)


GOspec := function(proj,nscan) {
 global bscan
 global current_scan := nscan
# d.clearrm()
 tstamp := as_integer(time())
 polSet->disabled(T)
 ifSet->disabled(T)
 intSet->disabled(T)
 if (len(dos.dir('/tmp','gospec*'))>0) {
   shell('rm -rf /tmp/go* > /dev/null 2>&1')
   if (len(dos.dir('/tmp','gospec*'))>0)
     dl.log(message='There are files in /tmp which I cannot clean up.',priority='SEVERE',postcli=T)
   }

 if (is_boolean(bscan)) bscan := nscan
 if ((nscan-bscan)>2) bscan := nscan
 ttt := time()
 printf('Filling .... ')
 if (!is_boolean(d.files(T).filein)) d.close(d.files(T).filein)
 ok := d.import(proj,paste('gospectrum',tstamp,sep=""),'/tmp',bscan,nscan)
 if (!ok) {
   printf('\n')
   dl.log(message='There is a problem filling this data.',priority='SEVERE',postcli=T)
   polSet->disabled(F)
   ifSet->disabled(F)
   intSet->disabled(F)
   return F
   }
 printf('            done. %5.2f\nRetrieving scan info ... ',time()-ttt)
 firstscan := d.getscan(nscan,1,setgs=F)
 if (!is_sdrecord(firstscan)) {
   dl.log(message='There is a problem accessing the data.',priority='SEVERE',postcli=T)
   return F
   }
 if (!has_field(firstscan.other,'gbt_go')) {
   dl.log(message='No GO information is available.  This is a problem.',priority='SEVERE',postcli=T)
  return F
  }
 check := d.qscan(nscan)
 for (i in "1 2 3 4") {
  if (as_integer(i) <= check.ifs)
   ifButton[i]->disabled(F)
  else
   ifButton[i]->disabled(T)
  if (as_integer(i) <= check.ints)
   intButton[i]->disabled(F)
  else
   intButton[i]->disabled(T)
  }
 npols := firstscan.data.arr::shape[1]
 if (npols > 2) {
  dl.log(message='You have more than 2 pol channels ---',priority='WARN',postcli=T)
  dl.log(message='Contact Jim to expand the capabilities of GOspec to accomodate this.',priority='WARN',postcli=T)
  }
 for (i in "1 2") {
  if (as_integer(i) <= npols)
   polButton[i]->disabled(F)
  else
   polButton[i]->disabled(T)
 }
 header := firstscan.other.gbt_go
 if (is_boolean(firstscan)) return F
 if (header.PROCSEQN == header.PROCSIZE) bscan := F
 if (!(header.PROCNAME == 'OffOn' || header.PROCNAME == 'OnOff' ||
       header.PROCNAME == 'Nod' )) bscan := F
 printf('done. %5.2f\nCalibrating ...',time()-ttt)
 d.calib(nscan)
 printf('      done. %5.2f\nPlotting ...',time()-ttt)
 updatePlot()
 printf('             done. %5.2f\n',time()-ttt)
 polSet->disabled(F)
 ifSet->disabled(F)
 intSet->disabled(F)
 return T
}

updatePlot := function() {
 global current_scan
 d.plotc(current_scan,int=intFlag,pol=polFlag,nif=ifFlag)
 d.plotter.resetzoom()
}
