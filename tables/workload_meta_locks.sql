#
# Author: YJ
# Date  : 2016.07.08
# Desc  : Metadata Lock Snapshot
#
drop table if exists workload_meta_locks;

create table workload_meta_locks
(
snap_id int unsigned not null comment 'snapshot id',
thread_id     bigint unsigned not null comment 'MySQL thread ID. Can be used for joining with PROCESSLIST on ID',
user_host     varchar(200) comment 'user@host',
lock_mode     varchar(24) comment 'One of MDL_INTENTION_EXCLUSIVE, MDL_SHARED, MDL_SHARED_HIGH_PRIO, MDL_SHARED_READ, MDL_SHARED_WRITE, MDL_SHARED_NO_WRITE, MDL_SHARED_NO_READ_WRITE or MDL_EXCLUSIVE.',
lock_duration varchar(30) comment 'One of MDL_STATEMENT, MDL_TRANSACTION or MDL_EXPLICIT',
lock_type     varchar(30) comment ' One of Global read lock, Schema metadata lock, Table metadata lock, Stored function metadata lock, Stored procedure metadata lock, Trigger metadata lock, Event metadata lock, Commit lock or User lock.',
table_schema  varchar(64) comment '',
table_name    varchar(64) comment '',
primary key (snap_id, thread_id, lock_type, table_schema, table_name)
)
engine = 'MyISAM'
charset = 'utf8'
collate = 'utf8_general_ci'
comment = 'DB workload - snapshot of metadata lock info'
;
