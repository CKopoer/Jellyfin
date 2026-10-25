# Jellyfin（Intel NAS 定制镜像）

基于官方 `jellyfin/jellyfin:latest`，仅面向 `linux/amd64`，增加：

- `intel-media-va-driver-non-free`
- `vainfo`
- `fonts-noto-cjk-extra`

官方镜像已经包含 Intel 用户态驱动（包括 Jellyfin FFmpeg 目录内的 iHD/i965）。额外安装的 Debian 系统驱动不保证会被 Jellyfin 使用；本项目不覆盖驱动路径、不设置 `LIBVA_DRIVERS_PATH`，也不代表已解决硬解故障。[官方 Intel 硬件加速说明](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/intel/)。

## 基底与验证

2026-10-18 实际拉取的官方 latest 为 Debian 13 / trixie，版本标签 `12.2`，manifest digest：

```text
sha256:357724bf0ae27a672c7cbaa899db2d9abeb13dbd8657ccce750258a4c059d037
```

Dockerfile 保留官方 apt 源，仅补充同一 trixie 发行版的 non-free 组件。Debian 官方索引已确认提供 `intel-media-va-driver-non-free`。若上游切换发行版，构建会明确失败，需要审查后更新，不会混用 bookworm/trixie。构建执行 `fc-cache`，并强制检查 `fc-list :lang=zh` 能识别 Noto CJK。

## 自动构建

`.github/workflows/image.yml` 每周一 UTC 00:23（北京时间 08:23）检查一次；GitHub 调度可能延迟。main 上构建文件变化及手动运行也触发检查。

1. 解析官方 latest 的 manifest digest。
2. 将 digest、平台、Dockerfile、.dockerignore、scripts 和 workflow 内容计算为 build key。
3. GHCR 中已经存在 `build-<完整 key>` 时跳过，否则构建。网络或权限异常会失败，避免误报“无变化”。首次通过 GitHub Packages API 确认包不存在后构建。
4. 始终使用已解析的 `jellyfin/jellyfin@sha256:...` 构建，避免检查与构建之间 latest 漂移。

README 变化不触发构建。仅 Debian 包更新不会改变 key；如需刷新包，在 Actions → Build Jellyfin image → Run workflow 勾选 `force`。这是明确的强制重建例外。删除已有 key 标签也会使下次重新构建。

发布到 `ghcr.io/ckopoer/jellyfin`，包含：

- `latest`：最近一次成功构建。
- `build-<key>`：对应基底与构建定义；强制重建可能更新此标签。
- `run-<run_id>-<attempt>`：每次构建独立标签，用于回滚。
- OCI labels：仓库来源、代码 commit、上游版本、上游 digest 与 build key。

以 Actions summary 给出的镜像 digest 固定部署最可靠。工作流只使用内置短期 `GITHUB_TOKEN`（`contents: read`、`packages: write`），没有 PAT 或 NAS 自动部署。所有第三方 Actions 已固定完整 commit SHA。

公开仓库不保证新建的 GHCR 包自动公开。首次发布后需在**本包**的 Package settings 中检查可见性，并按需设为 Public；不应更改其他包权限。GitHub 可能暂停长期无活动公开仓库的定时任务，需定期检查 Actions 状态。

## 构建与使用

```sh
docker build --platform linux/amd64 \
  --build-arg BASE_IMAGE=jellyfin/jellyfin@sha256:357724bf0ae27a672c7cbaa899db2d9abeb13dbd8657ccce750258a4c059d037 \
  -t jellyfin-custom:local .
docker run --rm --entrypoint sh jellyfin-custom:local -c \
  'dpkg-query -W intel-media-va-driver-non-free vainfo fonts-noto-cjk-extra; fc-list :lang=zh family'
```

发布成功后，可在现有 NAS Jellyfin 配置中替换镜像为 `ghcr.io/ckopoer/jellyfin:latest` 或指定 `run-...` 标签/digest；保留已有持久化目录。先备份配置，服务升级引起的数据库变更可能使旧版本镜像无法直接回滚。

硬解仍需宿主机内核驱动、`/dev/dri` 设备映射、正确的 render/video 组权限以及 Jellyfin 转码设置。应在 NAS 上实际转码并检查日志；云端镜像构建或字体检查通过不等于硬件加速通过。
