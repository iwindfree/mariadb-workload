#
# Name: workload_setup
# Author: YJ
# Created : 2016.07.08
# Last Updated: 2016.08.22
# Desc: Settings for Gather DB workload
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

insert into workload_setup (expire_snapshot_days) values (7);

