#
# Name: workload_event_schedule
# Author: YJ
# Created : 2016.07.11
# Last Updated: 2016.08.23
# Desc: event for workload snapshot
#
DROP EVENT IF EXISTS workload_event_schedule;

delimiter ;;
CREATE DEFINER=`root`@`localhost` EVENT `workload_event_schedule`
  ON SCHEDULE
    EVERY 10 MINUTE STARTS '2016-07-01 12:00:00'
  ON COMPLETION PRESERVE
  ENABLE
  COMMENT 'gather db workload snapshot'
  DO
BEGIN
  CALL workload_proc_run_snapshot();
  CALL workload_proc_purge_snapshot();
END;;
delimiter ;
