#
# Author: YJ
# Date  : 2016.07.08
# Desc  : Global Status Snapshot
#
drop table if exists workload_global_status;

create table workload_global_status
(
snap_id int unsigned not null comment 'snapshot id',
variable_name varchar(64) not null,
variable_value varchar(2048) not null,
primary key (snap_id, variable_name)
)
engine = 'MyISAM'
charset = 'utf8'
collate = 'utf8_general_ci'
comment = 'DB workload - snapshot of global status'
;
