pragma include once

system.client.ping := 30;

include 'sysinfo.g';
include 'timer.g'
include 'gbtgoclient.g';
include 'logger.g';

iardslog := "";
found := drc.find(iardslog,'iards.logfile','iards.log');
# the value of found doesn't matter here, its okay if not found
aipshome := drc.aipshome();
logFilePath := spaste(aipshome,'/',iardslog);

if (!dl.attach(logFilePath)) {
    dl.note('Could not attach to IARDS log file, falling back to temporary file')
    dl.attach('');
}

# set paths correctly so that IARDS will work
# get the base of this installation - assume linux since victor is linux

thisbase := spaste(sysinfo().root(),'/linux');
thislib := spaste(thisbase,'/lib');
thisbin := spaste(thisbase,'/bin');
if (!has_field(system,'path')) system.path := [=];
if (!has_field(system.path,'lib')) system.path.lib := [=];
if (!has_field(system.path,'bin')) system.path.bin := [=];
if (!has_field(system.path.lib,iards_client_host)) 
    system.path.lib[iards_client_host] := as_string([]);
if (!has_field(system.path.bin,iards_client_host,)) 
    system.path.bin[iards_client_host] := as_string([]);
# only add it in if it isn't already there
if (!any(system.path.lib[iards_client_host] == thislib))
    system.path.lib[iards_client_host] := [thislib,system.path.lib[iards_client_host]];
if (!any(system.path.bin[iards_client_host] == thisbin))
    system.path.bin[iards_client_host] := [thisbin,system.path.bin[iards_client_host]];

global go_aips2 := [=]

const check_goclient := function() 
{
    global go_aips2;
    ans := F;
    if (has_field(go_aips2,'active'))
	if (go_aips2.active == 1) ans := T;
    return ans;
}

ok := F
go_aips2 := client(iards_client_name, host=iards_client_host);
timer.wait(1)
if (is_agent(go_aips2)) {
    ok := check_goclient();
}
if (ok) {
    print 'IARDS is connected to gbtgoclient';
} else {
    print 'Failure in connecting to gbtgoclient.';
    exit;
}

include 'GOpoint.g';
include 'GOspec.g';

whenever go_aips2->GOproc do {
  print "IARDS event received of type", $value.type
  file := spaste('/home/gbtdata/',$value.project_id)
  if ($value.type == 'point') {
    point_update := GOpoint(file,$value.scan)
    go_aips2->IARDSpoint([d_az=point_update.d_az,d_el=point_update.d_el,status=point_update.pass])
    }
  else if ($value.type == 'focus') {
    focus_update := GOfocus(file,$value.scan)
    go_aips2->IARDSfocus([y=focus_update,status=T])
    }
  else if ($value.type == 'spectrum')
    GOspec(file,$value.scan)
  else if ($value.type == 'track')
    GOtrack(file,$value.scan)
  else if ($value.type == 'tip')
    print 'I cannot handle tip yet'
  else if ($value.type == 'other')
    print 'I cannot handle type other yet.'
}

print 'IARDS is ready.';
