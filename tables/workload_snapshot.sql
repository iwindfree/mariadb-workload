#
# Author: YJ
# Date  : 2016.07.08
# Desc  : snapshot history
#
drop table if exists workload_snapshot;

create table workload_snapshot
(
snap_id int unsigned auto_increment not null comment 'snapshot id',
begin_snap_time datetime not null default current_timestamp() comment 'snap start time',
end_snap_time datetime comment 'snap end time',
state varchar(10) not null comment 'RUNNING,COMPLETED,ERRORED',
err_msg varchar(1024) comment 'error messages are recorded only when there is an exception.',
primary key (snap_id),
index ix_begin_snap_time (begin_snap_time)
)
engine = 'MyISAM'
charset = 'utf8'
collate = 'utf8_general_ci'
comment = 'DB workload - setting for snapshot'
;
