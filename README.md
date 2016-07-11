# mariadb-workload
Gathering workload in MariaDB

< 사전에 준비되어야 할 사항 >
* 플러그인 설치: metadata_lock_info.so
* sys 스키마 생성
* performance_schema 사용 (ON)

< 구성시 주의 사항 >

USE sys; => 명령을 통해서 sys 스키마에 구성할 것을 권장함

테이블 생성 -> 프로시저 생성 -> 이벤트 등록 순서로 구성해야함
