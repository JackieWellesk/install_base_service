#!/bin/bash
OLD_LANG=${LANG}
export LANG=en_US.UTF-8

OLD_IFS="${IFS}"
export IFS=" "

# set -e #报错之后立即退出
chmod -R 755 ./*
function install_mysql {
	arg1=$1
	if [[ $arg1 == YES ]]
	then
		read -p "please input Mysql Host ip :" mysql_host_ip < /dev/tty
		read -p "please input Mysql PORT :" mysql_port < /dev/tty
		read -p "please input Mysql Username :" mysql_username < /dev/tty
		read -p "please input Mysql Password :" mysql_password < /dev/tty
		
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/MYSQL_HOST=127.0.0.1/MYSQL_HOST=$mysql_host_ip/g"
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/MYSQL_PORT=3306/MYSQL_PORT=$mysql_port/g"
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/MYSQL_USERNAME=root/MYSQL_USERNAME=$mysql_username/g"
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/MYSQL_USERNAME_LOG=root/MYSQL_USERNAME_LOG=$mysql_username/g"
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/MYSQL_PASSWORD=xxx/MYSQL_PASSWORD=$mysql_password/g"
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/MYSQL_PASSWORD_LOG=xxx/MYSQL_PASSWORD_LOG=$mysql_password/g"
		
		dpkg -i ./middleware/mysql/mysql-community-client_5.7.34-1ubuntu18.04_amd64.deb
		
		mysql -h$mysql_host_ip -P$mysql_port -u$mysql_username -p$mysql_password mysql -e "source ./middleware/zg_auth.sql;"
		
		cd classes
		java -classpath .:./lib/*:./* com.unicloud.flyway.FlywayApplication --MYSQL_HOST=$mysql_host_ip --MYSQL_PORT=$mysql_port --MYSQL_USERNAME=$mysql_username --MYSQL_PASSWORD=$mysql_password 
		cd ..
		exit_code=$?
		
		return 0
	fi
	
	local PID=`ps -ef | grep "mysql" | grep -v grep | awk '{print $2}'`
	
	if [ ! -n "$PID" ]; then 
		# 安装时会提示输入密码，默认密码为:xxx
		bash ./install_mysql.sh
	fi 
	
	exit_code=$?
	mysql -uroot -pxxx mysql -e "source ./middleware/zg_auth.sql;"
	mysql -uroot -pxxx mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'$SERVER_IP' IDENTIFIED BY 'xxx' WITH GRANT OPTION;"
	mysql -uroot -pxxx mysql -e "FLUSH PRIVILEGES;"
	
	cd classes
	#flyway设置数据库
	java -classpath .:./lib/*:./* com.unicloud.flyway.FlywayApplication
	cd ..
	exit_code=$?
	return $exit_code
}

function install_redis {
	arg1=$1
	if [[ $arg1 == "YES" ]]
	then
		read -p "please input Redis Host ip :" redis_host_ip < /dev/tty
		read -p "please input Redis Port :" redis_port < /dev/tty
		read -p "please input Redis Password :" redis_password < /dev/tty
		
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/REDIS_HOST=127.0.0.1/REDIS_HOST=$redis_host_ip/g"
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/REDIS_HOST=6379/REDIS_PORT=$redis_port/g"
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/REDIS_PASSWORD=xxx/REDIS_PASSWORD=$redis_password/g"
		
		return 0
	fi
	
	local PID=`ps -ef | grep "redis" | grep -v grep | awk '{print $2}'`
	
	if [ ! -n "$PID" ]; then 
		bash ./start_redis.sh
	fi 
	return $exit_code
}

function init_servicediscovery {
	if [[ $arg1 == "YES" ]]
	then
		read -p "please input EUREKA Host ip :" EUREKA_IP < /dev/tty
		read -p "please input EUREKA Port :" EUREKA_PORT < /dev/tty
		
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/EUREKA_HOST=127.0.0.1/EUREKA_HOST=$EUREKA_IP/g"
		find ./middleware/supervisor/ -name '*.conf' | xargs sed -i "s/EUREKA_PORT=11000/EUREKA_PORT=$EUREKA_PORT/g"
				
		return 0
	fi
	return 0
	
}

function update_supervisor_conf {

	if [ ! -d "/etc/supervisord.d" ]; then
 		mkdir /etc/supervisord.d
	fi
	
	/usr/bin/cp -rf ./middleware/supervisor/*.conf /etc/supervisord.d
	
	local PID=`ps -ef | grep "supervisor" | grep -v grep | awk '{print $2}'`
	
	if [ ! -n "$PID" ]; then 
		bash ./install_supervisor.sh
		
		mkdir -p /etc/supervisor/
		echo_supervisord_conf > /etc/supervisor/supervisord.conf

		#启动服务
		supervisorctl -c /etc/supervisord.conf
	fi
	sed -i "/^\;\[include\]/c\[include\]" /etc/supervisor/supervisord.conf
	sed -i '/^\;files/cfiles = /etc/supervisord.d/*.conf' /etc/supervisor/supervisord.conf
	supervisorctl update
	return $exit_code
}

function init_nginx {
	arg1=$1
	if [[ $arg1 == "YES" ]]
	then
		
		sed -i "s/authip/$SERVER_IP:12000/g" ./out_ng/sys/env/env.js
		sed -i "s/authip/$SERVER_IP:12000/g" ./out_ng/user/env/env.js
		
		return 0
	fi
	
	local PID=`ps -ef | grep "nginx" | grep -v grep | awk '{print $2}'`
	
	if [ ! -n "$PID" ]; then 
		bash ./install_nginx.sh
	fi
	return $exit_code
}


function main {
	
	chmod 755 -R ./*
	
	while read LINE
	do
		array=(${LINE//:/ })
		echo ${array[0]} ${array[1]}
		action ${array[0]} ${array[1]}
		
	done  < ./init.conf
	
	update_supervisor_conf
	
	echo '------------nacos pid------------'
	ps -ef | grep nacos | grep -v grep
	echo '------------mysql pid------------'
	ps -ef | grep mysql | grep -v grep
	echo '------------redis pid------------'
	ps -ef | grep redis | grep -v grep
	echo '------------nginx pid------------'
	ps -ef | grep nginx | grep -v grep
	echo '------------supervisor pid------------'
	ps -ef | grep supervisor | grep -v grep
	echo '------------supervisor status------------'
	supervisorctl status
	exit_code=$?
	
	return $exit_code

}

function action {
	step=$1
	para=$2
	exit_code=0
	case $step in
	USE_OTHER_MYSQL)
		echo "start init mysql"
		install_mysql $para
		exit_code=$?
	;;
	USE_OTHER_REDIS)
		echo "start init redis"
		install_redis $para
		exit_code=$?
	;;
	USE_OTHER_NGINX)
		echo "start init nginx"
		init_nginx $para
		exit_code=$?
	;;
	USE_OTHER_EUREKA)
		echo "start init ServiceDiscovery"
		init_servicediscovery $para
		exit_code=$?
	;;
	esac
	return $exit_code
}

exit_code=0

main $1

export LANG=${OLD_LANG}
export IFS="${OLD_IFS}"
exit $exit_code
