#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Ocean.sh"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 获取公共 IP 地址
function get_public_ip() {
    # 使用外部服务获取公共 IP
    PUBLIC_IP=$(curl -s ifconfig.me)
    echo "$PUBLIC_IP"
}

# 安装 Docker 和 Docker Compose
function install_docker_and_compose() {
    # 更新系统包列表
    apt-get update

    # 安装必要的工具
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    # 添加 Docker 官方 GPG 密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    # 添加 Docker APT 仓库
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # 更新包列表
    apt-get update

    # 安装 Docker Engine 和相关组件
    apt-get install -y docker-ce docker-ce-cli containerd.io

    # 启动 Docker 服务并设置为开机自启
    systemctl start docker
    systemctl enable docker

    # 验证 Docker 状态
    echo "Docker 状态:"
    systemctl status docker --no-pager

    # 检查 Docker Compose 是否已安装
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose 未安装，正在安装 Docker Compose..."
        # 安装 Docker Compose
        DOCKER_COMPOSE_VERSION="2.20.2"
        curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        echo "Docker Compose 已安装。"
    fi

    # 输出 Docker Compose 版本
    echo "Docker Compose 版本:"
    docker-compose --version
}

# 设置并启动节点
function setup_and_start_node() {
    # 创建目录并进入
    mkdir -p ocean
    cd ocean || exit

    # 下载节点脚本并赋予执行权限
    curl -O https://raw.githubusercontent.com/oceanprotocol/ocean-node/main/scripts/ocean-node-quickstart.sh
    chmod +x ocean-node-quickstart.sh

    # 提示用户
    echo "即将运行节点脚本。请按照以下步骤操作："
    echo "1. 在安装过程中，选择 'Y' 并按 Enter。"
    echo "2. 输入你的 EVM 钱包的私钥，注意在私钥前添加 '0x' 前缀。"
    echo "3. 输入与私钥对应的 EVM 钱包地址。"
    echo "4. 连续按 5 次 Enter。"
    echo "5. 输入服务器的 IP 地址。"

    # 执行节点脚本
    ./ocean-node-quickstart.sh

    # 启动节点
    echo "启动节点..."
    docker-compose up -d

    echo "节点启动完成！"
}

# 查看 Docker 日志
function view_logs() {
    echo "查看 Docker 日志..."
    if [ -d "ocean" ]; then
        cd ocean || exit
        docker-compose logs -f
    else
        echo "请先启动节点，目录 'ocean' 不存在。"
    fi
}

# 检查节点状态
function check_node_status() {
    # 获取 IP 地址
    PUBLIC_IP=$(get_public_ip)

    echo "请访问以下 URL 来检查节点状态："
    echo "http://$PUBLIC_IP:8000/dashboard/"
    echo "请注意，确保你的服务器允许外部访问 8000 端口。"
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 启动节点"
        echo "2. 查看日志"
        echo "3. 检查节点状态"
        echo "4. 退出"
        echo -n "请输入选项 (1/2/3/4): "
        read -r choice

        case $choice in
            1)
                echo "正在启动节点..."
                install_docker_and_compose
                setup_and_start_node
                ;;
            2)
                view_logs
                ;;
            3)
                check_node_status
                ;;
            4)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选项，请选择 1、2、3 或 4。"
                ;;
        esac
    done
}

# 执行主菜单
main_menu
