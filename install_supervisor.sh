echo '---------start install supervisor---------'
dpkg -i middleware/supervisor/*.deb
mkdir -p /etc/supervisor/
echo_supervisord_conf > /etc/supervisor/supervisord.conf

#启动服务
supervisorctl -c /etc/supervisor/supervisord.conf
systemctl stop supervisor
systemctl start supervisor
supervisorctl status
echo '---------end install supervisor---------'