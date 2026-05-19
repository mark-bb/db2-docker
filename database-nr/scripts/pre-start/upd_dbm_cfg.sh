#!/bin/bash

set -x
db2 update dbm cfg using SYSCTRL_GROUP db2ictrl SYSMAINT_GROUP db2imnt

# Doesn't help with missing libaws* libs
# db2set DB2_ENABLE_COS_SDK=NO
# db2set DB2_OBJECT_STORAGE_SETTINGS=OFF
