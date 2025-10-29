#!/bin/sh

set -e

PHP_VERSION="php82"
PHP_FPM_SERVICE_NAME="php-fpm$(echo $PHP_VERSION | sed 's/php//')"

install_env() {
    DEFAULT_WEB_PORT=52110
    DEFAULT_WEB_ROOT="/var/www/html"

    echo "--- [开始安装 Nginx + PHP 环境] ---"
    echo ""
    
    read -p "请输入 Nginx 监听端口 [默认: ${DEFAULT_WEB_PORT}]: " WEB_PORT
    WEB_PORT=${WEB_PORT:-$DEFAULT_WEB_PORT}

    read -p "请输入网站根目录地址 [默认: ${DEFAULT_WEB_ROOT}]: " WEB_ROOT
    WEB_ROOT=${WEB_ROOT:-$DEFAULT_WEB_ROOT}

    echo ""
    echo "--- 配置确认 ---"
    echo "监听端口: ${WEB_PORT}"
    echo "网站根目录: ${WEB_ROOT}"
    echo "-----------------"
    read -p "确认开始安装吗? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "安装已取消。"
        exit 0
    fi
    echo ""

    echo "步骤 1/7: 更新软件包并安装 Nginx 和 PHP..."
    apk update
    apk add --no-cache nginx ${PHP_VERSION}-fpm

    echo "步骤 2/7: 创建 PHP-FPM 运行目录并设置权限..."
    mkdir -p /run/php
    chown nginx:nginx /run/php

    echo "步骤 3/7: 配置 Nginx..."
    cat > /etc/nginx/http.d/default.conf <<EOF
server {
    listen ${WEB_PORT};
    listen [::]:${WEB_PORT};
    server_name _;
    root ${WEB_ROOT};
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
}
EOF

    echo "步骤 4/7: 配置 PHP-FPM..."
    sed -i "s|listen = 127.0.0.1:9000|listen = /run/php/${PHP_VERSION}-fpm.sock|g" /etc/${PHP_VERSION}/php-fpm.d/www.conf
    sed -i "s|;listen.owner = nobody|listen.owner = nginx|g" /etc/${PHP_VERSION}/php-fpm.d/www.conf
    sed -i "s|;listen.group = nobody|listen.group = nginx|g" /etc/${PHP_VERSION}/php-fpm.d/www.conf
    sed -i "s|user = nobody|user = nginx|g" /etc/${PHP_VERSION}/php-fpm.d/www.conf
    sed -i "s|group = nobody|group = nginx|g" /etc/${PHP_VERSION}/php-fpm.d/www.conf

    echo "步骤 5/7: 创建 Web 根目录和测试页面..."
    mkdir -p ${WEB_ROOT}
    echo "<?php phpinfo(); ?>" > ${WEB_ROOT}/index.php
    chown -R nginx:nginx ${WEB_ROOT}

    echo "步骤 6/7: 启动并启用服务..."
    rc-service nginx start
    rc-service ${PHP_FPM_SERVICE_NAME} start
    rc-update add nginx default
    rc-update add ${PHP_FPM_SERVICE_NAME} default

    echo "步骤 7/7: 检查服务状态..."
    rc-service nginx status
    rc-service ${PHP_FPM_SERVICE_NAME} status

    echo ""
    echo "--- [安装完成！] ---"
    echo "环境已成功搭建！请访问: http://<你的服务器IP>:${WEB_PORT}"
    echo "如果无法访问，请检查防火墙是否放行 TCP 端口 ${WEB_PORT}。"
}

clean_env() {
    DEFAULT_WEB_ROOT="/var/www/html"

    echo "--- [开始清理环境] ---"
    echo ""
    
    read -p "请输入需要清理的网站根目录 [默认: ${DEFAULT_WEB_ROOT}]: " WEB_ROOT
    WEB_ROOT=${WEB_ROOT:-$DEFAULT_WEB_ROOT}

    echo ""
    echo "警告：此操作将删除软件包、配置文件以及目录 '${WEB_ROOT}'！"
    read -p "确认要清理吗? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "清理已取消。"
        exit 0
    fi
    echo ""

    echo "步骤 1/4: 停止并禁用服务..."
    rc-service nginx stop || true
    rc-service ${PHP_FPM_SERVICE_NAME} stop || true
    rc-update del nginx default || true
    rc-update del ${PHP_FPM_SERVICE_NAME} default || true

    echo "步骤 2/4: 移除 Nginx 和 PHP 软件包..."
    apk del nginx ${PHP_VERSION}-fpm

    echo "步骤 3/4: 移除配置文件、Web 目录和日志..."
    rm -f /etc/nginx/http.d/default.conf
    rm -rf ${WEB_ROOT}
    rm -f /var/log/nginx/access.log /var/log/nginx/error.log
    rm -f /var/log/${PHP_VERSION}-fpm.log

    echo "步骤 4/4: 移除运行时目录..."
    rm -rf /run/php

    echo ""
    echo "--- [清理完成！] ---"
    echo "所有相关的软件包、配置和文件均已移除。"
}

show_menu() {
    echo "========================================"
    echo "     Nginx + PHP 环境管理脚本"
    echo "========================================"
    echo "  1. 安装新环境"
    echo "  2. 清理环境"
    echo "  3. 退出"
    echo "----------------------------------------"
}

main() {
    if [ "$(id -u)" -ne 0 ]; then
       echo "错误：此脚本必须以 root 用户身份运行。" >&2
       exit 1
    fi

    while true; do
        show_menu
        read -p "请输入你的选择 [1-3]: " choice
        echo ""
        case "$choice" in
            1)
                install_env
                break
                ;;
            2)
                clean_env
                break
                ;;
            3)
                echo "脚本退出。"
                exit 0
                ;;
            *)
                echo "无效输入，请重新选择。"
                echo ""
                ;;
        esac
    done
}

main
