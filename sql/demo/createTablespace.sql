select * from dba_users;

create tablespace 
   TBS_BANCO_DATA
datafile   
  '/u01/app/oracle/oradata/oracle11g-data/TBS_BANK_DATA.dbf' 
size 50m
autoextend on;
create tablespace 
   TBS_BANCO_IDX
datafile   
  '/u01/app/oracle/oradata/oracle11g-data/TBS_BANK_IDX.dbf' 
size 50m
autoextend on;