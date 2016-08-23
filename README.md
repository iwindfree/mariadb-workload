# The MariaDB Workload

## Comment

"The MariaDB workload" is gathering workload in MariaDB.

I wanted to find a tool like Oracle AWR, but it could not.

So I made a simple tool that gather workload in MariaDB.

The main objective was to find a high frequency of running the query.

## Explanation

This tool contains the below:
- Tables to store the collected information
- Procedures to collect DB status
- Event to run procedures periodically

Basically the event runs every 10 minutes and keeps the gathered data in 7 days.

After 7 days, the event deletes workload and slow_log.

If you want to change the term to keep workload, you can change the value in expire_snapshot_days of workload_setup table.

If you want to change the event execution interval, you can change the modify the event directly.

## Requirements

The value of "performance_schema" should be "ON".

The value of "enabled" of "statements_digest" in the performance_schema.setup_consumers shoud be "YES".

the plugin metadata_lock_info should installed.

## Installation

The objects should all be created as the root user (run with the privileges of the definer).


For instance if you download to /tmp/mariadb-workload/, and want to install the tool you should:

```
cd /tmp/mariadb-workload/
mysql -u root -p < ./mariadb_workload_install.sql
```

Or if you would like to log in to the client, and install the schema:

```
cd /tmp/mariadb-workload/
mysql -u root -p
SOURCE ./mariadb_workload_install.sql
```

## Object Description

to be continue...

-------

# The MariaDB Workload

## 비고

Oracle AWR과 유사한 도구를 찾아봤는데 찾을 수가 없어서, 간단히 만든 기능입니다.

## 설명

이 기능은 다음과 같은 요소로 구성 돼 있습니다.


- DB 정보가 저장되는 테이블들
- DB 상태를 수집하는 프로시저
- 주기적으로 프로시저를 실행하는 이벤트

기본적으로 이벤트는 10분 간격으로 실행되며, 수집된 정보는 7일간 보관합니다.

보관기간을 변경하고 싶다면 workload_setup 테이블의 expire_snapshot_days 값을 변경하면 됩니다.

이벤트 실행주기를 변경하고 싶다면 직접 이벤트를 수저하면 됩니다.

## 요건

"performance_schema"가 "ON" 이어야 합니다.

performance_schema.setup_consumers 테이블의 "statements_digest"의 "enabled"가 "YES"여야 합니다.

metadata_lock_info 플러그인이 설치 돼 있어야 합니다.

## 설치

위에 Installaion 부분을 참고하시면 됩니다.

## 오브젝트 설명
