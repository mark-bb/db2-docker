set -x

. /setup/utils.sh
su - ${DB2INSTANCE?} -c "db2 list db directory" | grep -E "Database name + = ${REPOSITORYDB_DATABASENAME?}\$" &>/dev/null
rc=$?
if [ "X${REPOSITORYDB_DATABASENAME?}" != "X" -a ${rc?} -ne 0 ]; then 
  echo "Creating ${REPOSITORYDB_DATABASENAME?} ..."
  time su - ${DB2INSTANCE?} -c "db2 CREATE DATABASE ${REPOSITORYDB_DATABASENAME?} PAGESIZE 32 K"
  su - ${DB2INSTANCE?} -c "db2 UPDATE DATABASE CONFIGURATION FOR ${REPOSITORYDB_DATABASENAME?} USING \
     LOGPRIMARY 5 \
     LOGSECOND 200 \
     LOGFILSIZ 8192 \
     EXTENDED_ROW_SZ enable"
fi
su - ${DB2INSTANCE?} -c "db2 activate db ${REPOSITORYDB_DATABASENAME?} && \
db2 connect to ${REPOSITORYDB_DATABASENAME?} && \
db2 grant DBADM WITH DATAACCESS on database to user ${REPOSITORYDB_USER?} && \
db2 connect reset && db2 terminate"
