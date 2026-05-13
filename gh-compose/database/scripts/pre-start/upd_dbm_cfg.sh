set -x
. /setup/utils.sh
grp="$(id -gn ${REPOSITORYDB_USER?})"
su - ${DB2INSTANCE?} -c "db2 update dbm cfg using SYSCTRL_GROUP ${grp?}"
