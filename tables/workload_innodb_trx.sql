#
# Name: workload_innodb_trx
# Author: YJ
# Created : 2016.07.08
# Last Updated: 2016.08.22
# Desc: InnoDB Transaction Snapshot
#
drop table if exists workload_innodb_trx;

create table workload_innodb_trx
(
snap_id int unsigned not null comment 'snapshot id',
thread_id                  bigint unsigned not null comment 'MySQL thread ID. Can be used for joining with PROCESSLIST on ID',
user_host                  varchar(200)             comment 'user@host',
trx_id                     varchar(18)     not null comment 'Unique transaction ID number, internal to InnoDB. (Starting in MySQL 5.6, these IDs are not created for transactions that are read-only and non-locking. See Optimizing InnoDB Read-Only Transactions for details.)',
trx_state                  varchar(13)     not null comment 'Transaction execution state. One of RUNNING, LOCK WAIT, ROLLING BACK or COMMITTING.',
trx_started                datetime        not null comment 'Transaction start time.',
trx_requested_lock_id      varchar(81)              comment 'ID of the lock the transaction is currently waiting for (if TRX_STATE is LOCK WAIT, otherwise NULL). Details about the lock can be found by joining with INNODB_LOCKS on LOCK_ID',
trx_wait_started           datetime                 comment 'Time when the transaction started waiting on the lock (if TRX_STATE is LOCK WAIT, otherwise NULL).',
trx_weight                 bigint unsigned not null comment 'The weight of a transaction, reflecting (but not necessarily the exact count of) the number of rows altered and the number of rows locked by the transaction. To resolve a deadlock, InnoDB selects the transaction with the smallest weight as the “victim” to rollback. Transactions that have changed non-transactional tables are considered heavier than others, regardless of the number of altered and locked rows.',
trx_query                  varchar(1024)            comment 'The SQL query that is being executed by the transaction.',
trx_operation_state        varchar(64)              comment 'The transaction''s current operation, or NULL.',
trx_tables_in_use          bigint unsigned not null comment 'The number of InnoDB tables used while processing the current SQL statement of this transaction.',
trx_tables_locked          bigint unsigned not null comment 'Number of InnoDB tables that the current SQL statement has row locks on. (Because these are row locks, not table locks, the tables can usually still be read from and written to by multiple transactions, despite some rows being locked.)',
trx_lock_structs           bigint unsigned not null comment 'The number of locks reserved by the transaction.',
trx_lock_memory_bytes      bigint unsigned not null comment 'Total size taken up by the lock structures of this transaction in memory.',
trx_rows_locked            bigint unsigned not null comment 'Approximate number or rows locked by this transaction. The value might include delete-marked rows that are physically present but not visible to the transaction.',
trx_rows_modified          bigint unsigned not null comment 'The number of modified and inserted rows in this transaction.',
trx_concurrency_tickets    bigint unsigned not null comment 'A value indicating how much work the current transaction can do before being swapped out, as specified by the innodb_concurrency_tickets option.',
trx_isolation_level        varchar(16)     not null comment 'The isolation level of the current transaction.',
trx_unique_checks          int             not null comment 'Whether unique checks are turned on or off for the current transaction. (They might be turned off during a bulk data load, for example.)',
trx_foreign_key_checks     int             not null comment 'Whether foreign key checks are turned on or off for the current transaction. (They might be turned off during a bulk data load, for example.)',
trx_last_foreign_key_error varchar(256)             comment 'Detailed error message for last FK error, or NULL.',
trx_adaptive_hash_latched  int             not null comment 'Whether or not the adaptive hash index is locked by the current transaction. (Only a single transaction at a time can modify the adaptive hash index.)',
trx_adaptive_hash_timeout  bigint unsigned not null comment 'Whether to relinquish the search latch immediately for the adaptive hash index, or reserve it across calls from MySQL. When there is no AHI contention, this value remains zero and statements reserve the latch until they finish. During times of contention, it counts down to zero, and statements release the latch immediately after each row lookup.',
trx_is_read_only           int             not null comment 'A value of 1 indicates the transaction is read-only. (5.6.4 and up.)',
trx_autocommit_non_locking int             not null comment 'A value of 1 indicates the transaction is a SELECT statement that does not use the FOR UPDATE or LOCK IN SHARED MODE clauses, and is executing with the autocommit setting turned on so that the transaction will only contain this one statement. (5.6.4 and up.) When this column and TRX_IS_READ_ONLY are both 1, InnoDB optimizes the transaction to reduce the overhead associated with transactions that change table data.',
primary key (snap_id, thread_id, trx_id)
)
engine = 'MyISAM'
charset = 'utf8'
collate = 'utf8_general_ci'
comment = 'DB workload - snapshot of innodb transactions'
;
