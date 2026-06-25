# 构建阶段
FROM alpine:latest AS builder

# 安装编译依赖
RUN apk add --no-cache \
    build-base \
    git \
    cargo \
    openssl-dev \
    musl-dev

WORKDIR /app

# 克隆仓库（浅克隆加速）
RUN git clone --depth 1 https://github.com/bee-san/RustScan.git

WORKDIR /app/RustScan

# 编译 release 版本
RUN cargo build --release

# 运行时阶段
FROM alpine:latest AS release

# 创建用户和安装运行时依赖
RUN addgroup -S rustscan && \
    adduser -S -G rustscan rustscan && \
    apk add --no-cache \
        nmap \
        nmap-scripts \
        wget \
        ca-certificates \
        bind-tools

# 从构建阶段复制二进制文件
COPY --from=builder /app/RustScan/target/release/rustscan /usr/local/bin/rustscan

# 设置权限
RUN chmod +x /usr/local/bin/rustscan

# 切换到非 root 用户
USER rustscan

# 设置入口点
ENTRYPOINT ["/usr/local/bin/rustscan"]
