#!/bin/bash
host=`hostname`
echo $host


if [ $host = ansible ]
then
sed -i.bak '/$HOME\/bin\/date/s/^/#/' /var/spool/cron/user_test
sed -i.bak '/$HOME\/bin\/pwd_test/s/^/#/' /var/spool/cron/user_test
fi

if [ $host =  ansible-awx ]
then
sed -i.bak '/$HOME\/bin\/df/s/^/#/' /var/spool/cron/user_test
fi
