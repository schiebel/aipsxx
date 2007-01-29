s/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][ T][0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9]\{1,3\}/----------T--:--:--.---/g
s/Cache saved to '*/Cache saved to '----'/g
s/Manager hostname generated using localhost address: '.*'/Manager hostname generated using localhost address: '---'/g
s/\/acsdata\/tmp\/acs_local_log_\([a-z,A-Z,0-9,_,-]*\)_[0-9]*/\/acsdata\/tmp\/acs_local_log_\1_xxxx/g