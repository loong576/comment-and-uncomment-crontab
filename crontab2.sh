#!/bin/bash
host=`hostname`
echo $host


if [ $host = ansible ]
then
sed -i '/^#.*$HOME\/bin\/date/s/^#//g'  /var/spool/cron/user_test
sed -i '/^#.*$HOME\/bin\/pwd_test/s/^#//g'  /var/spool/cron/user_test
fi

if [ $host =  ansible-awx ]
then
sed -i '/^#.*$HOME\/bin\/df/s/^#//g'  /var/spool/cron/user_test
fi
