#!/bin/bash

set -x
db2 update dbm cfg using SYSCTRL_GROUP db2ictrl SYSMAINT_GROUP db2imnt
db2set DB2_ENABLE_COS_SDK=NO
