# Test script for ATCA specific processes
# Copied from newAssay.g in aips++/weekly/code/nrao/scripts
#
# Tara Murphy
#

include 'sysinfo.g'
include 'aipsrc.g'
include 'ms.g'
include 'os.g'
include 'note.g'

include 'atcaCalibrationTests.g'

# Runs each function in the list and checks for a fail.
# Tracks the number of fails and reports at the end. 
# Returns the number of fails.

const atcaAssay := function(){

  self.tests := ['primaryCalib1384', 'primaryCalib2496', 
                 'primaryCalib4800', 'primaryCalib8640', 
                 'primaryCalib1384multi', 'primaryCalib2496multi', 
                 'primaryCalib4800multi','primaryCalib8640multi',
                 'secondaryCalib1384', 'secondaryCalib8640', 
                 'secondaryCalib2496linpol', 'secondaryCalib4800flux', 
                 'secondaryCalib1384fluxalt', 
                 'targetCalib1384', 'targetCalib4800', 
                 'targetCalib2496calave', 'targetCalib8640calave']

#  self.tests := ['test1']

  const self.dontfail:=function(f) {
    if(!is_defined(f)) return 'argument must be defined'
    if(!is_string(f)) return 'argument must be a string'
    if(!is_function(eval(f))) return paste(f, 'is not a function')
    result:=eval(spaste(f,'()'))
    if(is_fail(result)){
      print f, 'fails: ', result::message
      return result::message
    }
    return ''
  }
  
  const public.try:=function(functionlist) {
    if(!is_string(functionlist)) fail "Need list of functions"
    if(functionlist=='') fail "Need list of functions"
    funclist:=split(functionlist)
    messages:=array('', len(funclist))
    for (i in 1:len(funclist)) {
      messages[i]:=self.dontfail(funclist[i])
    }
    failed:=''
    numberfailed:=0
    for (i in 1:len(funclist)) {
	if(messages[i]!='') {
	  note(paste(funclist[i], 'failed: ', messages[i]))
	  numberfailed+:=1
	}
    }  
    return numberfailed
  }
  
# Print tests
  const public.tests := function(){return self.tests}

  const public.cleanup := function(){
    dos.remove('testdata/C1026.ms', mustexist=F)
    dos.remove('testdata/C972.ms', mustexist=F)
    dos.remove('tabG', mustexist=F)
    dos.remove('tabB', mustexist=F)
    dos.remove('tabD', mustexist=F)
  }

  const public.gettestdata := function(){
    if(!dos.fileexists('testdata'))
      dos.mkdir('testdata')

    datadir := spaste(drc.aipsroot(), '/data/atnf/scripts/')
    dos.remove('testdata/C1026.ms', mustexist=F)
    dos.remove('testdata/C972.ms', mustexist=F)
#    dos.copy(spaste(datadir, 'C1026.ms'), 'testdata/C1026.ms')
#    dos.copy(spaste(datadir, 'C972.ms'), 'testdata/C972.ms')

    mirfiles := dos.dir(datadir, pattern='*.atnf')
    for(i in mirfiles)
      dos.copy(spaste(datadir, '/', i), spaste('testdata/', i), overwrite=T)

    dos.copy('/data/VOID_1/mur339/C1026.ms', 'testdata/C1026.ms')
    dos.copy('/data/VOID_1/mur339/C972.ms', 'testdata/C972.ms')

    if(!dos.fileexists('testdata/C972.ms') || !dos.fileexists('testdata/C1026.ms')){
      print 'ERROR: test data has not been copied correctly, exiting...'
      exit
    }
    return T    
  }


# Assay all tests
  const public.trytests := function(tests=F){

    public.gettestdata()

    if(is_string(tests)&&strlen(tests)) {
	   return public.try(tests)
    }
    else {
	return public.try(self.tests)
    }
  }

  const public.all:=function() {return trytests()}

  const public.type:=function() {return "atcaAssay"}
  
  return ref public
}

