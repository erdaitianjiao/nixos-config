# NixOS 配置

NixOS 25.11 的 flake 配置,用 home-manager 管理用户级配置。一条命令同时更新系统和个人环境。

## 文件

| 文件 | 作用 |
|------|------|
| `flake.nix` | flake 入口,声明依赖、组装系统 |
| `configuration.nix` | 系统级配置(桌面/服务/网络/软件) |
| `hardware-configuration.nix` | 硬件配置,自动生成,**别手改** |
| `home.nix` | 用户级配置(个人软件/dotfiles) |

## 常用命令

在仓库目录下执行:

```bash
sudo nixos-rebuild switch --flake .#nixos   # 应用配置(系统+用户)
sudo nixos-rebuild test --flake .#nixos     # 只测试,不切换
nix flake update                            # 更新依赖
sudo nixos-rebuild switch --rollback        # 回滚到上一代
```

## 加速:临时用国内镜像

下载慢时,用 `--option` 一次性指定国内镜像(**不改配置文件,仅本次构建生效**):

```bash
sudo nixos-rebuild switch --flake .#nixos \
  --option substituters "https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org/" \
  --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
```

镜像任选(替换上面 URL 即可):
- **USTC(中科大)**:`https://mirrors.ustc.edu.cn/nix-channels/store`
- **TUNA(清华)**:`https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store`

## 修改配置

- 系统级(桌面/服务/网络)→ `configuration.nix`
- 个人环境(软件/dotfiles)→ `home.nix`
- 改完跑 `switch` 生效

## 注意

- `flake.lock`、`hardware-configuration.nix` 别手改。
- `stateVersion` 设了永远不改。
- 换机器要重新生成 `hardware-configuration.nix`。
