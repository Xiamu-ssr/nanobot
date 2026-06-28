# Nanobot Multi-Instance Deployment

多实例部署方案，每个业务员一个独立 Nanobot 容器，数据完全隔离。

## 快速部署

```bash
# 1. Build image (from repo root)
docker compose build nanobot-gateway

# 2. Deploy instance for user A
./deploy/launch-instance.sh alice 8088 8765 18790

# 3. Deploy instance for user B
./deploy/launch-instance.sh bob 8089 8766 18791

# 4. List all instances
./deploy/list-instances.sh

# 5. Stop/remove an instance
./deploy/stop-instance.sh alice
```

## 架构

```
用户A → http://host:8088 → nginx → nanobot-alice (workspace: ~/.nanobot-alice/)
用户B → http://host:8089 → nginx → nanobot-bob   (workspace: ~/.nanobot-bob/)
用户C → http://host:8090 → nginx → nanobot-charlie (workspace: ~/.nanobot-charlie/)
```

每个实例：
- 独立 workspace（会话、记忆、文件、cron 全隔离）
- 独立 tokenIssueSecret（不同密码）
- 独立端口
- ~70MB 内存

## Nginx 配置

见 `deploy/nginx/` 目录。每个实例一个 server block，可选 `auth_basic` 防陌生人。

## 自定义改动（vs 上游）

1. **ThreadComposer.tsx**: `ACCEPT_ATTR = ""`（接受任意文件类型）
2. **useAttachedImages.ts**: 跳过 MIME 白名单
3. **imageEncode.worker.ts**: 非图片文件用 `bufferToBase64` 生成 data URL
4. **websocket.py**: `_MAX_IMAGE_BYTES` 8MB→20MB，MIME 白名单放宽
5. **config**: `extract_document_text: false`（文档只给路径，不自动提取文本）

## 文件上传行为

| 文件类型 | 上传时 | AI 用 read_file 读时 |
|---------|--------|---------------------|
| 图片 | 原始像素 → base64 → 多模态 vision block | 同上 |
| PDF/DOCX/XLSX | 只给 `[Attachment: 路径]` | AI 主动读，提取文本 |
| 其他文件 | 只给 `[Attachment: 路径]` | AI 用 read_file 读原始字节 |
