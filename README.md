**前言：**
在日常变更过程中，变更前会注释某些定时任务(比如巡检告警等)，变更完成后需恢复，又是变更操作的服务器很多，对应需要注释的crontab也很多且不相同，本文通过分发平台执行对应脚本批量实现crontab的注释和解注释功能。



**环境说明：**

|   主机名    |  操作系统版本   |      ip      | 用户名 |        备注         |
| :---------: | :-------------: | :----------: | ------ | :-----------------: |
|   ansible   | Centos 7.6.1810 | 172.27.34.51 |        | crontab测试服务器01 |
| ansible-awx | Centos 7.6.1810 | 172.27.34.50 |        | crontab测试服务器02 |

## 一、crontab测试环境准备

### 1.主机ansible环境准备

```bash
[user_test@ansible ~]$ echo $HOME
/home/user_test
[user_test@ansible ~]$ crontab -l
0 0 * * * /home/user_test/bin/date > /dev/null
0 0 * * * $HOME/bin/date > /dev/null
0 0 * * * date > /dev/null
* * * * * df -h > /tmp/df.txt
0 0 * * * $HOME/bin/pwd_test > /dev/null
[user_test@ansible ~]$ pwd
/home/user_test
[user_test@ansible ~]$ ll
总用量 8
drwxrwxr-x 2 user_test user_test   6 9月   8 11:22 bin
-rwxrw-r-- 1 user_test user_test 309 9月   8 11:01 crontab2.sh
-rwxrw-r-- 1 user_test user_test 303 9月   8 10:59 crontab.sh
[user_test@ansible ~]$ cd bin
[user_test@ansible bin]$ ll
总用量 0
[user_test@ansible bin]$ ln -s /usr/bin/date date
[user_test@ansible bin]$ ln -s /usr/bin/pwd pwd_test
[user_test@ansible bin]$ ll
总用量 0
lrwxrwxrwx 1 user_test user_test 13 9月   8 11:23 date -> /usr/bin/date
lrwxrwxrwx 1 user_test user_test 12 9月   8 11:23 pwd_test -> /usr/bin/pwd
[user_test@ansible bin]$ /home/user_test/bin/date 
2020年 09月 08日 星期二 11:23:25 CST
[user_test@ansible bin]$ /home/user_test/bin/pwd_test 
/home/user_test/bin
```

![image-20200908112545814](https://i.loli.net/2020/09/08/r5G7hoktQml8MFf.png)

### 2.主机ansible-awx环境准备

```bash
[user_test@ansible-awx ~]$ echo $HOME
/home/user_test
[user_test@ansible-awx ~]$ crontab -l
0 0 * * * /home/user_test/bin/date > /dev/null
0 0 * * * $HOME/bin/date > /dev/null
0 0 * * * date > /dev/null
0 0 * * * $HOME/bin/df -h > /tmp/df.txt
[user_test@ansible-awx ~]$ pwd   
/home/user_test
[user_test@ansible-awx ~]$ ll
总用量 0
drwxrwxr-x 2 user_test user_test 6 9月   8 11:25 bin
[user_test@ansible-awx ~]$ cd bin
[user_test@ansible-awx bin]$ ll
总用量 0
[user_test@ansible-awx bin]$ ln -s /usr/bin/date date
[user_test@ansible-awx bin]$ ln -s /usr/bin/df df
[user_test@ansible-awx bin]$ ll
总用量 0
lrwxrwxrwx 1 user_test user_test 13 9月   8 11:25 date -> /usr/bin/date
lrwxrwxrwx 1 user_test user_test 11 9月   8 11:25 df -> /usr/bin/df
[user_test@ansible-awx bin]$ /home/user_test/bin/date 
2020年 09月 08日 星期二 11:25:58 CST
[user_test@ansible-awx bin]$ /home/user_test/bin/df -h
文件系统                   容量  已用  可用 已用% 挂载点
/dev/mapper/root--vg-root   10G  229M  9.8G    3% /
devtmpfs                   1.9G     0  1.9G    0% /dev
tmpfs                      1.9G     0  1.9G    0% /dev/shm
tmpfs                      1.9G  201M  1.7G   11% /run
tmpfs                      1.9G     0  1.9G    0% /sys/fs/cgroup
/dev/mapper/root--vg-usr    10G  1.7G  8.4G   17% /usr
/dev/mapper/root--vg-home   10G   50M   10G    1% /home
/dev/mapper/root--vg-var    10G  3.0G  7.1G   30% /var
/dev/mapper/root--vg-tmp    10G   33M   10G    1% /tmp
/dev/mapper/root--vg-opt    10G  233M  9.8G    3% /opt
/dev/sda1                  497M  138M  359M   28% /boot
tmpfs                      379M     0  379M    0% /run/user/0
```

![image-20200908112802951](https://i.loli.net/2020/09/08/BVkptD1dfOwba4e.png)

分别在两台主机上构造定时任务，其中$HOME/bin下的命令都为/usr/bin/下系统命令的软链接，/home/user_test/bin/pwd_test等命令测试正常。

本文目标：

注释ansible的`“0 0 * * * $HOME/bin/date > /dev/null”、“0 0 * * * $HOME/bin/pwd_test > /dev/null”`

注释ansible-awx的`“0 0 * * * $HOME/bin/df -h > /tmp/df.txt”`


## 二、执行脚本

### 1.注释脚本crontab.sh

```bash
[user_test@ansible ~]$ more crontab.sh 
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
```

![image-20200908113213592](https://i.loli.net/2020/09/08/xtAeJdU59zEfMWB.png)

### 2.解注释脚本crontab2.sh

```bash
[user_test@ansible ~]$ more crontab2.sh 
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
```

![image-20200908113505890](https://i.loli.net/2020/09/08/yfjxiQF9gnTEvLY.png)

两个脚本判断逻辑：首先获取主机名，然后匹配主机名，根据主机名来注释或解注释指定的定时任务，指定的定时任务通过sed工具匹配获取。

## 三、测试执行

### 1.spug平台模板配置

使用自动化运维平台spug(后面文章会介绍)进行测试。

![image-20200908144548685](https://i.loli.net/2020/09/08/qczOZAP4ydBYJ5C.png)

模板管理中新建两个模板'注释crontab'和'解注释crontab'，这两个模板其实分别对应脚本crontab.sh和crontab2.sh。

如果没有spug平台，也可以使用ansible平台进行分发执行。

### 2.注释crontab

选择主机ansible和ansible-awx

![image-20200908145029479](https://i.loli.net/2020/09/08/CdyxDiS7aAqnlu6.png)

选择模板'注释crontab'

![image-20200908145137372](https://i.loli.net/2020/09/08/7vZawVNxsyclbLt.png)

![image-20200908145156385](https://i.loli.net/2020/09/08/HzqpLdYIlJS4ePQ.png)

选择模板即是选择对应执行的脚本，'开始执行'

![image-20200908145257040](E:\jianguo\typora-pic\image-20200908145257040.png)

**验证：**

![image-20200908145358556](https://i.loli.net/2020/09/08/Bhpa2Iq9uORMAUy.png)

![image-20200908145416355](https://i.loli.net/2020/09/08/rPQbyLncVAMWq7N.png)

发现主机ansible和ansible-awx都完成对应crontab的注释。

### 3.解注释crontab

选择模板'解注释crontab'

![image-20200908145550233](https://i.loli.net/2020/09/08/wc1I4QAb5f9jqJG.png)

执行：

![image-20200908145604617](https://i.loli.net/2020/09/08/QqgEbFNirtIARwH.png)

![image-20200908145633256.png](https://i.loli.net/2020/09/08/BZits3W2rzvhQIS.png)



**验证：**

![image-20200908145658096.png](https://i.loli.net/2020/09/08/ISdV8Gopj6BqQbn.png)

![image-20200908145708701](https://i.loli.net/2020/09/08/yOapxAv9PWn2RYo.png)

两台主机的crontab都已经解注释，注释和解注释测试都符合预期。
