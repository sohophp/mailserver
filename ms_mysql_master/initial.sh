#!/bin/bash
#################
# 初始化MySQL数据库
################

# 预设参数
MYSQL_MASTER_ROOT_PASSWORD=123456
MYSQL_MASTER_HOST=localhost
MYSQL_MASTER_PORT=3306
MYSQL_MASTER_DATABASE=postfix
MYSQL_MASTER_USER=postfix
MYSQL_MASTER_PASSWORD=123456 

base=$(cd "$(dirname $0)/..";pwd)
# 导入设定参数
source $base'/.env';

# 日志时间
TIMESTAMP=`date +%Y%m%d%H%M%S`

# 日志文件名
log=$base'/log/mysql_master_initial.log'
tmp_log=$base'/log/tmp.log'
if [ ! -f "$tmp_log" ];
then 
touch $tmp_log
fi

mycnf=$base'/ms_mysql_master/my.cnf'

echo "
[client]
host=$MYSQL_MASTER_HOST
user=root
port=$MYSQL_MASTER_PORT
password=$MYSQL_MASTER_ROOT_PASSWORD
">$mycnf

# 写入日志
# echo "Start execute sql statement at `date`." >> $log 
echo "Start execute sql statement at `date`."
# 执行初始 SQL
mysql --defaults-extra-file=$mycnf --tee="$tmp_log" -e" 

DROP DATABASE IF EXISTS $MYSQL_MASTER_DATABASE ;
CREATE DATABASE $MYSQL_MASTER_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE $MYSQL_MASTER_DATABASE;
-- #lt 5.7
-- #DROP USER IF EXISTS '$MYSQL_MASTER_USER'@'%';
GRANT USAGE ON *.* TO '$MYSQL_MASTER_USER'@'%' IDENTIFIED BY '123456' ;
DROP USER '$MYSQL_MASTER_USER'@'%';
FLUSH PRIVILEGES;
CREATE USER '$MYSQL_MASTER_USER'@'%' IDENTIFIED  BY '$MYSQL_MASTER_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_MASTER_DATABASE.* TO '$MYSQL_MASTER_USER'@'%';
FLUSH PRIVILEGES;
";

if test 1 ; then

mysql --defaults-extra-file=$mycnf --tee="$tmp_log" -e "

USE $MYSQL_MASTER_DATABASE;

CREATE TABLE virtual_domains (
  id int(11) NOT NULL auto_increment,
  name varchar(50) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE virtual_users (
  id int(11) NOT NULL auto_increment,
  domain_id int(11) NOT NULL,
  password varchar(106) NOT NULL,
  email varchar(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY email (email),
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE virtual_aliases (
  id int(11) NOT NULL auto_increment,
  domain_id int(11) NOT NULL,
  source varchar(100) NOT NULL,
  destination varchar(100) NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

";
fi;

rm $mycnf; 
# echo "below is output result.">>${log};
echo "below is output result." ;   
# cat $tmp_log>>${log};
cat $tmp_log;
# echo "script executed successful.">>${log};
echo "script executed successful." ;
# echo -e "\n">>${log};
if [ -f "$tmp_log" ];then rm $tmp_log;fi;
if [ -f "$log" ];then rm $log; fi;
