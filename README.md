# install_base_service
此脚本是为了完成在ubuntu离线环境下，安装nginx、redis、mysql、supervisor
# 未解决的问题
- 编译后的nginx，无法解决当时更换目录的问题，也就是只能在固定目录安装。故只能固定安装目录。
- redis不知道有没有这个问题，毕竟没有更换过目录
# 在ubuntu联网环境下载依赖包的指令
`apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances 需要下载的软件名 | grep "^\w" | sort -u)`
# 测试过的版本
Ubuntu 22.04.1
# 参考链接
- [遇到卸载不了的情况](https://blog.csdn.net/weixin_43820665/article/details/110292462)
- [彻底卸载mysql](https://blog.csdn.net/fanrongwoaini/article/details/107518693)
- [乌班图安装mysql](https://blog.csdn.net/emergencysun/article/details/124229238)
- [离线安装nginx](https://www.cnblogs.com/hellojesson/p/10635047.html)
- [离线安装redis](https://blog.csdn.net/dwdda/article/details/128674751)
- [下载离线包](https://he-yin.cn/archives/ubuntuapt)
