#
# Author: YJ
# Date  : 2016.07.08
# Desc  : Innodb Lock Snapshot
#
drop table if exists sys.workload_innodb_locks;

create table sys.workload_innodb_locks
(
snap_id int unsigned not null comment 'snapshot id',
lock_id     varchar(81)         not null comment 'Unique lock ID number, internal to InnoDB. Treat it as an opaque string. Although LOCK_ID currently contains TRX_ID, the format of the data in LOCK_ID is not guaranteed to remain the same in future releases. Do not write programs that parse the LOCK_ID value.',
lock_trx_id varchar(18)         not null comment 'ID of the transaction holding this lock. Details about the transaction can be found by joining with INNODB_TRX on TRX_ID',
lock_mode   varchar(32)         not null comment 'Mode of the lock. One of S[,GAP], X[,GAP], IS[,GAP], IX[,GAP], AUTO_INC, or UNKNOWN. Lock modes other than AUTO_INC and UNKNOWN will indicate GAP locks, if present. ',
lock_type   varchar(32)         not null comment 'Type of the lock. One of RECORD or TABLE for record (row) level or table level locks, respectively.',
lock_table  varchar(1024)       not null comment 'Name of the table that has been locked or contains locked records.',
lock_index  varchar(1024)       comment 'Name of the index if LOCK_TYPE=''RECORD'', otherwise NULL.',
lock_space  bigint  unsigned comment 'Tablespace ID of the locked record if LOCK_TYPE=''RECORD'', otherwise NULL.',
lock_page   bigint unsigned comment 'Page number of the locked record if LOCK_TYPE=''RECORD'', otherwise NULL.',
lock_rec    bigint  unsigned comment 'Heap number of the locked record within the page if LOCK_TYPE=''RECORD'', otherwise NULL.',
lock_data   varchar(8192)       comment 'Primary key value(s) of the locked record if LOCK_TYPE=''RECORD'', otherwise NULL. ',
primary key (snap_id, lock_id)
)
engine = 'MyISAM'
charset = 'utf8'
collate = 'utf8_general_ci'
comment = 'DB workload - snapshot of innodb locks'
;
