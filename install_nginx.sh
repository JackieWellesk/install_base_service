echo '----------start install nginx-dependency ----------'
dpkg -i ./middleware/nginx-dependency/libpcre/*.deb
dpkg -i ./middleware/nginx-dependency/openssl/*.deb
dpkg -i ./middleware/nginx-dependency/zlib1g/*.deb
echo '----------end install nginx-dependency ----------'

echo '----------start nginx ----------'
mkdir -p /opt/soft/
/usr/bin/cp -rf ./middleware/nginx-1.24.0-dist/ /opt/soft/
chmod 755 -R /opt/soft/
/opt/soft/nginx-1.24.0-dist/sbin/nginx
echo '----------end nginx ----------'