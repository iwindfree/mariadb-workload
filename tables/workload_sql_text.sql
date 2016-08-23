#
# Name: workload_sql_text
# Author: YJ
# Created : 2016.07.11
# Last Updated: 2016.08.22
# Desc: "digest sql text"
#       (digest: a normalized form of a statement)
#
drop table if exists workload_sql_text;

create table workload_sql_text
(
schema_name varchar(64) not null comment 'Database name. Records are summarised together with DIGEST.',
digest      varchar(32) not null comment 'Performance Schema digest. (digest: a normalized form of a statement) Records are summarised together with SCHEMA NAME.',
digest_text longtext             comment 'The unhashed form of the digest.',
primary key (digest, schema_name)
)
engine = 'MyISAM'
charset = 'utf8'
collate = 'utf8_general_ci'
comment = 'DB workload - sql digest(a normalized form of a statement)'
;

