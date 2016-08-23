SET NAMES utf8;
SET @sql_log_bin = @@sql_log_bin;
SET sql_log_bin = 0;

CREATE DATABASE IF NOT EXISTS sys DEFAULT CHARACTER SET utf8;

INSTALL PLUGIN metadata_lock_info SONAME 'metadata_lock_info';

USE sys;

SOURCE ./tables/workload_global_status.sql
SOURCE ./tables/workload_global_variables.sql
SOURCE ./tables/workload_innodb_locks.sql
SOURCE ./tables/workload_innodb_trx.sql
SOURCE ./tables/workload_meta_locks.sql
SOURCE ./tables/workload_setup.sql
SOURCE ./tables/workload_snapshot.sql
SOURCE ./tables/workload_sql_summary.sql
SOURCE ./tables/workload_sql_text.sql

SOURCE ./stored_procedure/workload_proc_purge_snapshot.sql
SOURCE ./stored_procedure/workload_proc_run_snapshot.sql

SOURCE ./event/workload_event_schedule.sql

UPDATE performance_schema.setup_consumers
   SET statements_digest = 'YES'
 WHERE name = 'statements_digest';
COMMIT;

SET @@sql_log_bin = @sql_log_bin;
