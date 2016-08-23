#
# Name: workload_proc_purge_snapshot
# Author: YJ
# Created : 2016.07.11
# Last Updated: 2016.08.22
# Desc: Purge workloads and mysql.slow_log table
#
# MariaDB [sys]> call workload_proc_purge_snapshot();
#
DROP PROCEDURE IF EXISTS workload_proc_purge_snapshot;

delimiter ;;
CREATE
DEFINER = `root`@`localhost`
PROCEDURE workload_proc_purge_snapshot ()
LANGUAGE SQL
NOT DETERMINISTIC
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'purge db workloads'
Main: BEGIN

  # define variables for error handler
  DECLARE _errno    SMALLINT UNSIGNED;
  DECLARE _errm     VARCHAR(250);

  # define variables for this procedure
  DECLARE _user_lock_name varchar(30) DEFAULT 'workload_snapshot_purge';
  DECLARE _snap_id int unsigned;
  DECLARE _setup_cnt tinyint unsigned;
  DECLARE _expire_snapshot_days tinyint unsigned DEFAULT 7;

  # define handler: release user lock & exit procedure
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    # get error info
    GET DIAGNOSTICS CONDITION 1  _errno = MYSQL_ERRNO
                               , _errm  = MESSAGE_TEXT;
    # release user defined lock
    DO RELEASE_LOCK(_user_lock_name);
    SHOW ERRORS;
  END;

  # do not binary logging in this thread
  SET SESSION sql_log_bin=OFF;

  # if there is no user defined lock, keep going. if else do nothing.
  IF IS_FREE_LOCK(_user_lock_name) THEN

    # set user defined lock and execute processes
    # this prevents duplicate runs
    IF GET_LOCK(_user_lock_name, 0) THEN

      # getting the count of workload setup data
      SELECT COUNT(1)
        INTO _setup_cnt
        FROM workload_setup
      ;

      # if workload table has one data, use the data
      IF _setup_cnt = 1 THEN
        SELECT expire_snapshot_days
          INTO _expire_snapshot_days
          FROM workload_setup
        ;
      END IF;

      # get snap_id to purge workload data
      SELECT MAX(snap_id)
        INTO _snap_id
        FROM workload_snapshot
       WHERE begin_snap_time <= DATE_SUB(current_timestamp(), INTERVAL _expire_snapshot_days DAY);

      # delete mysql.slow_log
      SET GLOBAL slow_query_log=OFF;
      RENAME TABLE mysql.slow_log TO mysql.workload_temp_slow_log;
      DELETE FROM mysql.workload_temp_slow_log
       WHERE start_time < DATE_SUB(current_timestamp(), INTERVAL _expire_snapshot_days+1 DAY);
      RENAME TABLE mysql.workload_temp_slow_log TO mysql.slow_log;
      SET GLOBAL slow_query_log=ON;

      # delete the snapshot history
      DELETE FROM workload_snapshot
       WHERE snap_id <= _snap_id
      ;

      # delete the global viariables workload
      DELETE FROM workload_global_variables
       WHERE snap_id <= _snap_id
      ;

      # delete the global status workload
      DELETE FROM workload_global_status
       WHERE snap_id <= _snap_id
      ;

      # delete the metadata lock workload
      DELETE FROM workload_meta_locks
       WHERE snap_id <= _snap_id
      ;

      # delete the InnoDB transactions workload
      DELETE FROM workload_innodb_trx
       WHERE snap_id <= _snap_id
      ;

      # delete the InnoDB locks workload
      DELETE FROM workload_innodb_locks
       WHERE snap_id <= _snap_id
      ;

      # delete the "digest sql text" statistics summary
      DELETE FROM workload_sql_summary
       WHERE snap_id <= _snap_id
      ;

    END IF;

  END IF;

  # release user defined lock
  DO RELEASE_LOCK(_user_lock_name);

  # do binary logging in this thread
  SET SESSION sql_log_bin=ON;

END Main;;
delimiter ;
