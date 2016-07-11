#
# Author: YJ
# Date  : 2016.07.11
# Desc  : "digest sql text" statistics summary
# performance_schema.setup_consumers 테이블의 "statements_digest" 항목의 enabled 설정이 "YES"로 돼 있어야 함
# performance_schema.events_statements_summary_by_digest 테이블의 timer 관련 항목은 picoseconds 단위임
# 이 테이블에는 seconds 단위로 저장함
#
drop table if exists workload_sql_summary;

create table workload_sql_summary
(
snap_id                       int unsigned           not null comment 'snapshot id',
schema_name                   varchar(64)            not null comment 'Database name. Records are summarised together with DIGEST.',
digest                        varchar(32)            not null comment 'Performance Schema digest. (digest: a normalized form of a statement) Records are summarised together with SCHEMA NAME.',
count_star                    bigint unsigned        not null comment '(Cumulative)Number of summarized events',
delta_count_star              bigint unsigned        not null comment '(Delta)Number of summarized events',
sum_timer_wait                decimal(17,9) unsigned not null comment '(Cumulative)Total wait time of the summarized events that are timed.',
delta_timer_wait              decimal(17,9) unsigned not null comment '(Delta)Total wait time of the summarized events that are timed.',
sum_lock_time                 decimal(17,9) unsigned not null comment '(Cumulative)Sum of the LOCK_TIME column in the events_statements_current table.',
delta_lock_time               decimal(17,9) unsigned not null comment '(Delta)Sum of the LOCK_TIME column in the events_statements_current table.',
sum_errors                    bigint unsigned        not null comment '(Cumulative)Sum of the ERRORS column in the events_statements_current table.',
delta_errors                  bigint unsigned        not null comment '(Delta)Sum of the ERRORS column in the events_statements_current table.',
sum_warnings                  bigint unsigned        not null comment '(Cumulative)Sum of the WARNINGS column in the events_statements_current table.',
delta_warnings                bigint unsigned        not null comment '(Delta)Sum of the WARNINGS column in the events_statements_current table.',
sum_rows_affected             bigint unsigned        not null comment '(Cumulative)Sum of the ROWS_AFFECTED column in the events_statements_current table.',
delta_rows_affected           bigint unsigned        not null comment '(Delta)Sum of the ROWS_AFFECTED column in the events_statements_current table.',
sum_rows_sent                 bigint unsigned        not null comment '(Cumulative)Sum of the ROWS_SENT column in the events_statements_current table.',
delta_rows_sent               bigint unsigned        not null comment '(Delta)Sum of the ROWS_SENT column in the events_statements_current table.',
sum_rows_examined             bigint unsigned        not null comment '(Cumulative)Sum of the ROWS_EXAMINED column in the events_statements_current table.',
delta_rows_examined           bigint unsigned        not null comment '(Delta)Sum of the ROWS_EXAMINED column in the events_statements_current table.',
sum_created_tmp_disk_tables   bigint unsigned        not null comment '(Cumulative)Sum of the CREATED_TMP_DISK_TABLES column in the events_statements_current table.',
delta_created_tmp_disk_tables bigint unsigned        not null comment '(Delta)Sum of the CREATED_TMP_DISK_TABLES column in the events_statements_current table.',
sum_created_tmp_tables        bigint unsigned        not null comment '(Cumulative)Sum of the CREATED_TMP_TABLES column in the events_statements_current table.',
delta_created_tmp_tables      bigint unsigned        not null comment '(Delta)Sum of the CREATED_TMP_TABLES column in the events_statements_current table.',
sum_select_full_join          bigint unsigned        not null comment '(Cumulative)Sum of the SELECT_FULL_JOIN column in the events_statements_current table.',
delta_select_full_join        bigint unsigned        not null comment '(Delta)Sum of the SELECT_FULL_JOIN column in the events_statements_current table.',
sum_select_full_range_join    bigint unsigned        not null comment '(Cumulative)Sum of the SELECT_FULL_RANGE_JOIN column in the events_statements_current table.',
delta_select_full_range_join  bigint unsigned        not null comment '(Delta)Sum of the SELECT_FULL_RANGE_JOIN column in the events_statements_current table.',
sum_select_range              bigint unsigned        not null comment '(Cumulative)Sum of the SELECT_RANGE column in the events_statements_current table.',
delta_select_range            bigint unsigned        not null comment '(Delta)Sum of the SELECT_RANGE column in the events_statements_current table.',
sum_select_range_check        bigint unsigned        not null comment '(Cumulative)Sum of the SELECT_RANGE_CHECK column in the events_statements_current table.',
delta_select_range_check      bigint unsigned        not null comment '(Delta)Sum of the SELECT_RANGE_CHECK column in the events_statements_current table.',
sum_select_scan               bigint unsigned        not null comment '(Cumulative)Sum of the SELECT_SCAN column in the events_statements_current table.',
delta_select_scan             bigint unsigned        not null comment '(Delta)Sum of the SELECT_SCAN column in the events_statements_current table.',
sum_sort_merge_passes         bigint unsigned        not null comment '(Cumulative)Sum of the SORT_MERGE_PASSES column in the events_statements_current table.',
delta_sort_merge_passes       bigint unsigned        not null comment '(Delta)Sum of the SORT_MERGE_PASSES column in the events_statements_current table.',
sum_sort_range                bigint unsigned        not null comment '(Cumulative)Sum of the SORT_RANGE column in the events_statements_current table.',
delta_sort_range              bigint unsigned        not null comment '(Delta)Sum of the SORT_RANGE column in the events_statements_current table.',
sum_sort_rows                 bigint unsigned        not null comment '(Cumulative)Sum of the SORT_ROWS column in the events_statements_current table.',
delta_sort_rows               bigint unsigned        not null comment '(Delta)Sum of the SORT_ROWS column in the events_statements_current table.',
sum_sort_scan                 bigint unsigned        not null comment '(Cumulative)Sum of the SORT_SCAN column in the events_statements_current table.',
delta_sort_scan               bigint unsigned        not null comment '(Delta)Sum of the SORT_SCAN column in the events_statements_current table.',
sum_no_index_used             bigint unsigned        not null comment '(Cumulative)Sum of the NO_INDEX_USED column in the events_statements_current table.',
delta_no_index_used           bigint unsigned        not null comment '(Delta)Sum of the NO_INDEX_USED column in the events_statements_current table.',
sum_no_good_index_used        bigint unsigned        not null comment '(Cumulative)Sum of the NO_GOOD_INDEX_USED column in the events_statements_current table.',
delta_no_good_index_used      bigint unsigned        not null comment '(Delta)Sum of the NO_GOOD_INDEX_USED column in the events_statements_current table.',
first_seen                    timestamp default '2000-01-01 00:00:00' not null comment 'Time at which the digest was first seen.',
last_seen                     timestamp default '2000-01-01 00:00:00' not null comment 'Time at which the digest was most recently seen.',
primary key (snap_id, schema_name, digest),
index ix_digest (digest)
)
engine = 'MyISAM'
charset = 'utf8'
collate = 'utf8_general_ci'
comment = 'DB workload - snapshot of sql digest(a normalized form of a statement) summary'
;
