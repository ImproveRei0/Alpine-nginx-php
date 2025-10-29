# Alpine-nginx-php


# Nginx + PHP 快速部署脚本 (Alpine Linux)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个交互式的 Shell 脚本，用于在 Alpine Linux 系统上快速安装、配置和清理一个完整的 Nginx + PHP-FPM 环境。

## ✨ 功能特性

-   **交互式菜单**：通过简单的菜单选项即可完成安装或清理操作。
-   **自定义配置**：在安装过程中，可以自定义 Nginx 的监听端口和网站根目录。
-   **智能默认值**：为常用配置（如端口 `52110`）提供了合理的默认值，简化了部署流程。
-   **一键安装**：自动处理软件包安装、Nginx 与 PHP-FPM 配置、目录权限设置以及服务启动。
-   **安全清理**：提供一键清理功能，可以彻底移除所有相关的软件包、配置文件和网站目录，并有二次确认防止误操作。
-   **专为 Alpine 设计**：使用 `apk` 包管理器和 `rc-service` 服务管理，完美适配 Alpine Linux 环境。

## 🚀 使用方法

### 1. 下载脚本

### 使用 curl 
```bash
bash -c "$(curl -sSL https://raw.githubusercontent.com/ImproveRei0/Alpine-nginx-php/main/np.sh)"
```
### 使用 wget
```bash
bash -c "$(wget -qO - https://raw.githubusercontent.com/ImproveRei0/Alpine-nginx-php/main/np.sh)"
```

### 2. 遵循交互式菜单提示

运行后，你将看到一个清晰的菜单：

```
========================================
     Nginx + PHP 环境管理脚本
========================================
  1. 安装新环境
  2. 清理环境
  3. 退出
----------------------------------------
请输入你的选择 [1-3]:
```

-   **选择 `1` (安装)**：
    -   脚本会提示你输入 Nginx 的监听端口和网站根目录。
    -   你可以直接按回车键使用默认值（端口：`52110`，目录：`/var/www/html`）。
    -   配置确认后，脚本将自动完成所有安装和配置工作。

-   **选择 `2` (清理)**：
    -   脚本会停止相关服务，卸载软件包，并删除所有配置文件和网站目录。
    -   为了安全起见，在执行删除操作前会要求你进行确认。

-   **选择 `3` (退出)**：
    -   安全退出脚本。

## 🛠️ 技术细节

### 安装流程

1.  **更新与安装**：更新 `apk` 软件包列表，并安装 `nginx` 和 `php82-fpm`。
2.  **配置 Nginx**：
    -   创建一个新的 Nginx 服务器配置 (`/etc/nginx/http.d/default.conf`)。
    -   监听用户指定的端口。
    -   将 PHP 请求通过 Unix Socket (`/run/php/php82-fpm.sock`) 转发给 PHP-FPM 处理。
3.  **配置 PHP-FPM**：
    -   修改 `www.conf`，将监听方式从 TCP 端口改为更高效的 Unix Socket。
    -   设置 Socket 的所有者和用户组为 `nginx`，以确保 Nginx 有权限访问。
    -   将 PHP-FPM 进程的运行用户和组也设置为 `nginx`。
4.  **创建目录与权限**：
    -   创建网站根目录 (`/var/www/html` 或自定义路径)。
    -   创建一个 `phpinfo()` 测试页面 (`index.php`)。
    -   将网站根目录的所有权递归地设置为 `nginx:nginx`。
5.  **服务管理**：
    -   启动 `nginx` 和 `php-fpm` 服务。
    -   将这两个服务添加到系统启动项中。

### 清理流程

1.  **停止服务**：停止 `nginx` 和 `php-fpm` 服务，并从系统启动项中移除。
2.  **卸载软件**：使用 `apk del` 彻底移除 `nginx` 和 `php82-fpm`。
3.  **删除文件**：删除 Nginx 配置文件、网站根目录、日志文件以及 PHP-FPM 的运行时目录。

## 📜 许可证

本项目采用 [MIT License](LICENSE) 授权。
