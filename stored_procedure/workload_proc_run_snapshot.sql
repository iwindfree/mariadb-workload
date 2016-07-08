#
# Author: YJ
# Date  : 2016.07.08
# Desc  : procedure that write workload snapshot
#
DROP PROCEDURE IF EXISTS workload_proc_run_snapshot;

delimiter ;;
CREATE
DEFINER = `root`@`localhost`
PROCEDURE workload_proc_run_snapshot ()
LANGUAGE SQL
NOT DETERMINISTIC
MODIFIES SQL DATA
SQL SECURITY DEFINER
COMMENT 'procedure to db status snapshot'
Main: BEGIN

  # define variables for error handler
  DECLARE _errno    SMALLINT UNSIGNED;
  DECLARE _errm     VARCHAR(250);

  # define variables for this procedure
  DECLARE _user_lock_name varchar(30) DEFAULT 'workload_snapshot_running';
  DECLARE _snap_id int unsigned;

  # define handler: release user lock & exit procedure
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    # get error info
    GET DIAGNOSTICS CONDITION 1  _errno = MYSQL_ERRNO
                                 , _errm  = MESSAGE_TEXT;
    # release user defined lock
    DO RELEASE_LOCK(_user_lock_name);
    SHOW ERRORS;
    # set snapshot end time and state
    UPDATE workload_snapshot
       SET end_snap_time = NOW()
          ,state = 'ABORTED'
          ,err_msg = CONCAT_WS('', '(', _errno, ')', _errm)
     WHERE snap_id = _snap_id;
  END;

  # if there is no user defined lock, keep going. if else do nothing.
  IF IS_FREE_LOCK(_user_lock_name) THEN

    # set user defined lock and execute processes
    # this prevents duplicate runs
    IF GET_LOCK(_user_lock_name, 0) THEN

      # log the snapshot starting
      INSERT INTO workload_snapshot
      ( begin_snap_time, state  )
      VALUES
      ( NOW(), 'RUNNING' );

      # get snap_id
      SELECT LAST_INSERT_ID() INTO _snap_id;

      # log the global viariables
      INSERT INTO workload_global_variables
      (
        snap_id, variable_name, variable_value
      )
      SELECT _snap_id, variable_name, variable_value
        FROM information_schema.global_variables
      ;

      # log the global status
      INSERT INTO workload_global_status
      (
        snap_id, variable_name, variable_value
      )
      SELECT _snap_id, variable_name, variable_value
        FROM information_schema.global_status
      ;

      # log the Metadata locks
      INSERT INTO workload_meta_locks
      (
         snap_id
        ,thread_id
        ,user_host
        ,lock_mode
        ,lock_duration
        ,lock_type
        ,table_schema
        ,table_name
      )
      SELECT
             _snap_id AS snap_id
          ,m.thread_id
            ,concat('`', p.user, '`@`', substring_index(p.host, ':', 1), '`') AS user_host
            ,m.lock_mode
            ,m.lock_duration
            ,m.lock_type
            ,m.table_schema
            ,m.table_name
        FROM information_schema.metadata_lock_info m
             LEFT OUTER JOIN information_schema.processlist p
                ON m.thread_id = p.id;

      # log the InnoDB transactions
      INSERT INTO workload_innodb_trx
      (
         snap_id
        ,thread_id
        ,user_host
        ,trx_id
        ,trx_state
        ,trx_started
        ,trx_requested_lock_id
        ,trx_wait_started
        ,trx_weight
        ,trx_query
        ,trx_operation_state
        ,trx_tables_in_use
        ,trx_tables_locked
        ,trx_lock_structs
        ,trx_lock_memory_bytes
        ,trx_rows_locked
        ,trx_rows_modified
        ,trx_concurrency_tickets
        ,trx_isolation_level
        ,trx_unique_checks
        ,trx_foreign_key_checks
        ,trx_last_foreign_key_error
        ,trx_adaptive_hash_latched
        ,trx_adaptive_hash_timeout
        ,trx_is_read_only
        ,trx_autocommit_non_locking
      )
      SELECT
           _snap_id AS snap_id
          ,t.trx_mysql_thread_id AS thread_id
          ,concat('`', p.user, '`@`', substring_index(p.host, ':', 1), '`') AS user_host
          ,t.trx_id
          ,t.trx_state
          ,t.trx_started
          ,t.trx_requested_lock_id
          ,t.trx_wait_started
          ,t.trx_weight
          ,t.trx_query
          ,t.trx_operation_state
          ,t.trx_tables_in_use
          ,t.trx_tables_locked
          ,t.trx_lock_structs
          ,t.trx_lock_memory_bytes
          ,t.trx_rows_locked
          ,t.trx_rows_modified
          ,t.trx_concurrency_tickets
          ,t.trx_isolation_level
          ,t.trx_unique_checks
          ,t.trx_foreign_key_checks
          ,t.trx_last_foreign_key_error
          ,t.trx_adaptive_hash_latched
          ,t.trx_adaptive_hash_timeout
          ,t.trx_is_read_only
          ,t.trx_autocommit_non_locking
        FROM information_schema.innodb_trx t
             JOIN information_schema.processlist p
              ON t.trx_mysql_thread_id = p.id
      ;

      # log the InnoDB locks
      INSERT INTO workload_innodb_locks
      (
         snap_id
        ,lock_id
        ,lock_trx_id
        ,lock_mode
        ,lock_type
        ,lock_table
        ,lock_index
        ,lock_space
        ,lock_page
        ,lock_rec
        ,lock_data
      )
      SELECT
           _snap_id AS snap_id
          ,lock_id
          ,lock_trx_id
          ,lock_mode
          ,lock_type
          ,lock_table
          ,lock_index
          ,lock_space
          ,lock_page
          ,lock_rec
          ,lock_data
        FROM information_schema.innodb_locks
      ;

    END IF;

  END IF;

  # release user defined lock
  DO RELEASE_LOCK(_user_lock_name);

  # set snapshot end time and state
  UPDATE workload_snapshot
     SET end_snap_time = NOW()
        ,state = 'COMPLETED'
   WHERE snap_id = _snap_id;

END Main;;
delimiter ;
