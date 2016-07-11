#
# Author: YJ
# Date  : 2016.07.08
# Desc  : setting value for gather db workload
#
drop table if exists workload_setup;

create table workload_setup
(
expire_snapshot_days int unsigned not null comment 'days to retain snapshots',
primary key (expire_snapshot_days)
)
engine = 'MyISAM'
charset = 'utf8'
collate = 'utf8_general_ci'
comment = 'DB workload - setting for snapshot'
;
