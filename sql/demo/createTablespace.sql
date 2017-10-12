--DROP TABLESPACE TBS_BANCO_DATA    INCLUDING CONTENTS AND DATAFILES;
select * from dba_tablespaces;
select * from V$TABLESPACE;
select * from ALL_DIRECTORIES;
select * from DBA_DATA_FILES;
select * from dba_users;

create tablespace 
   TBS_BANK_DATA
datafile   
  '/u01/app/oracle/oradata/oracle11g-data/TBS_BANK_DATA.dbf' 
size 50m
autoextend on;
create tablespace 
   TBS_BANK_IDX
datafile   
  '/u01/app/oracle/oradata/oracle11g-data/TBS_BANK_IDX.dbf' 
size 50m
autoextend on;