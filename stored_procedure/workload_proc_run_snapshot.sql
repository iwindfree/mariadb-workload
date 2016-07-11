#
# Author: YJ
# Date  : 2016.07.11
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
COMMENT 'gather db workloads'
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

      # log the "digest sql text"
      INSERT INTO workload_sql_text
      (
         schema_name
        ,digest
        ,digest_text
      )
      SELECT IFNULL(d.schema_name, '') AS schema_name
            ,d.digest
            ,d.digest_text
        FROM performance_schema.events_statements_summary_by_digest d
       WHERE d.digest IS NOT NULL
         AND NOT EXISTS (SELECT 'N'
                           FROM workload_sql_text t
                          WHERE IFNULL(d.schema_name, '') = t.schema_name
                            AND d.digest = t.digest)
      ;

      # log the "digest sql text" statistics summary
      INSERT INTO workload_sql_summary
      (
         snap_id
        ,schema_name
        ,digest
        ,count_star
        ,delta_count_star
        ,sum_timer_wait
        ,delta_timer_wait
        ,sum_lock_time
        ,delta_lock_time
        ,sum_errors
        ,delta_errors
        ,sum_warnings
        ,delta_warnings
        ,sum_rows_affected
        ,delta_rows_affected
        ,sum_rows_sent
        ,delta_rows_sent
        ,sum_rows_examined
        ,delta_rows_examined
        ,sum_created_tmp_disk_tables
        ,delta_created_tmp_disk_tables
        ,sum_created_tmp_tables
        ,delta_created_tmp_tables
        ,sum_select_full_join
        ,delta_select_full_join
        ,sum_select_full_range_join
        ,delta_select_full_range_join
        ,sum_select_range
        ,delta_select_range
        ,sum_select_range_check
        ,delta_select_range_check
        ,sum_select_scan
        ,delta_select_scan
        ,sum_sort_merge_passes
        ,delta_sort_merge_passes
        ,sum_sort_range
        ,delta_sort_range
        ,sum_sort_rows
        ,delta_sort_rows
        ,sum_sort_scan
        ,delta_sort_scan
        ,sum_no_index_used
        ,delta_no_index_used
        ,sum_no_good_index_used
        ,delta_no_good_index_used
        ,first_seen
        ,last_seen
      )
      SELECT
             _snap_id AS snap_id
            ,IFNULL(d.schema_name, '') AS schema_name
            ,d.digest
            ,d.count_star
            ,CASE WHEN d.count_star >= s.count_star
                  THEN d.count_star - s.count_star
                  ELSE d.count_star
             END AS delta_count_star
            ,d.sum_timer_wait/1e+12 AS sum_timer_wait
            ,CASE WHEN d.sum_timer_wait/1e+12 >= s.sum_timer_wait
                  THEN d.sum_timer_wait/1e+12 - s.sum_timer_wait
                  ELSE d.sum_timer_wait/1e+12
             END AS delta_timer_wait
            ,d.sum_lock_time/1e+12 AS sum_lock_time
            ,CASE WHEN d.sum_lock_time/1e+12 >= s.sum_lock_time
                  THEN d.sum_lock_time/1e+12 - s.sum_lock_time
                  ELSE d.sum_lock_time/1e+12
             END AS delta_lock_time
            ,d.sum_errors
            ,CASE WHEN d.sum_errors >= s.sum_errors
                  THEN d.sum_errors - s.sum_errors
                  ELSE d.sum_errors
             END AS delta_errors
            ,d.sum_warnings
            ,CASE WHEN d.sum_warnings >= s.sum_warnings
                  THEN d.sum_warnings - s.sum_warnings
                  ELSE d.sum_warnings
             END AS delta_warnings
            ,d.sum_rows_affected
            ,CASE WHEN d.sum_rows_affected >= s.sum_rows_affected
                  THEN d.sum_rows_affected - s.sum_rows_affected
                  ELSE d.sum_rows_affected
             END AS delta_rows_affected
            ,d.sum_rows_sent
            ,CASE WHEN d.sum_rows_sent >= s.sum_rows_sent
                  THEN d.sum_rows_sent - s.sum_rows_sent
                  ELSE d.sum_rows_sent
             END AS delta_rows_sent
            ,d.sum_rows_examined
            ,CASE WHEN d.sum_rows_examined >= s.sum_rows_examined
                  THEN d.sum_rows_examined - s.sum_rows_examined
                  ELSE d.sum_rows_examined
             END AS delta_rows_examined
            ,d.sum_created_tmp_disk_tables
            ,CASE WHEN d.sum_created_tmp_disk_tables >= s.sum_created_tmp_disk_tables
                  THEN d.sum_created_tmp_disk_tables - s.sum_created_tmp_disk_tables
                  ELSE d.sum_created_tmp_disk_tables
             END AS delta_created_tmp_disk_tables
            ,d.sum_created_tmp_tables
            ,CASE WHEN d.sum_created_tmp_tables >= s.sum_created_tmp_tables
                  THEN d.sum_created_tmp_tables - s.sum_created_tmp_tables
                  ELSE d.sum_created_tmp_tables
             END AS delta_created_tmp_tables
            ,d.sum_select_full_join
            ,CASE WHEN d.sum_select_full_join >= s.sum_select_full_join
                  THEN d.sum_select_full_join - s.sum_select_full_join
                  ELSE d.sum_select_full_join
             END AS delta_select_full_join
            ,d.sum_select_full_range_join
            ,CASE WHEN d.sum_select_full_range_join >= s.sum_select_full_range_join
                  THEN d.sum_select_full_range_join - s.sum_select_full_range_join
                  ELSE d.sum_select_full_range_join
             END AS delta_select_full_range_join
            ,d.sum_select_range
            ,CASE WHEN d.sum_select_range >= s.sum_select_range
                  THEN d.sum_select_range - s.sum_select_range
                  ELSE d.sum_select_range
             END AS delta_select_range
            ,d.sum_select_range_check
            ,CASE WHEN d.sum_select_range_check >= s.sum_select_range_check
                  THEN d.sum_select_range_check - s.sum_select_range_check
                  ELSE d.sum_select_range_check
             END AS delta_select_range_check
            ,d.sum_select_scan
            ,CASE WHEN d.sum_select_scan >= s.sum_select_scan
                  THEN d.sum_select_scan - s.sum_select_scan
                  ELSE d.sum_select_scan
             END AS delta_select_scan
            ,d.sum_sort_merge_passes
            ,CASE WHEN d.sum_sort_merge_passes >= s.sum_sort_merge_passes
                  THEN d.sum_sort_merge_passes - s.sum_sort_merge_passes
                  ELSE d.sum_sort_merge_passes
             END AS delta_sort_merge_passes
            ,d.sum_sort_range
            ,CASE WHEN d.sum_sort_range >= s.sum_sort_range
                  THEN d.sum_sort_range - s.sum_sort_range
                  ELSE d.sum_sort_range
             END AS delta_sort_range
            ,d.sum_sort_rows
            ,CASE WHEN d.sum_sort_rows >= s.sum_sort_rows
                  THEN d.sum_sort_rows - s.sum_sort_rows
                  ELSE d.sum_sort_rows
             END AS delta_sort_rows
            ,d.sum_sort_scan
            ,CASE WHEN d.sum_sort_scan >= s.sum_sort_scan
                  THEN d.sum_sort_scan - s.sum_sort_scan
                  ELSE d.sum_sort_scan
             END AS delta_sort_scan
            ,d.sum_no_index_used
            ,CASE WHEN d.sum_no_index_used >= s.sum_no_index_used
                  THEN d.sum_no_index_used - s.sum_no_index_used
                  ELSE d.sum_no_index_used
             END AS delta_no_index_used
            ,d.sum_no_good_index_used
            ,CASE WHEN d.sum_no_good_index_used >= s.sum_no_good_index_used
                  THEN d.sum_no_good_index_used - s.sum_no_good_index_used
                  ELSE d.sum_no_good_index_used
             END AS delta_no_good_index_used
            ,d.first_seen
            ,d.last_seen
        FROM performance_schema.events_statements_summary_by_digest d
             LEFT OUTER JOIN workload_sql_summary s
             ON IFNULL(d.schema_name, '') = s.schema_name
                AND d.digest = s.digest
                AND d.last_seen >= s.last_seen
                AND s.snap_id = CASE _snap_id WHEN 1 THEN NULL ELSE _snap_id - 1 END
       WHERE d.digest IS NOT NULL;

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
