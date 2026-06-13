# NixOS 配置

本仓库用 [Nix Flakes](https://nixos.wiki/wiki/Flakes) 管理 NixOS 系统配置,并用 [home-manager](https://nix-community.github.io/home-manager/) 以 module 模式管理用户级配置。一条命令同时更新系统和个人环境。

- **主机**: `nixos`
- **用户**: `tianjiao`
- **NixOS**: 25.11
- **桌面**: KDE Plasma 6 + SDDM
- **Shell**: Zsh + Oh My Zsh + powerlevel10k
- **输入法**: Fcitx5

## 目录结构

| 文件 | 作用 | 谁维护 |
|------|------|--------|
| `flake.nix` | flake 入口,声明依赖 + 组装系统 | 手写 |
| `flake.lock` | 依赖版本锁,保证可复现 | 自动生成,**别手改** |
| `configuration.nix` | 系统级配置(桌面/服务/网络/字体/系统软件) | 手写 |
| `hardware-configuration.nix` | 硬件描述(磁盘挂载/内核模块/CPU 微码) | `nixos-generate-config` 生成,**别手改** |
| `home.nix` | 用户级配置(个人软件/dotfiles,只对 `tianjiao`) | 手写 |

## 依赖关系

```
nixos-rebuild --flake .#nixos
        │
        ▼
   flake.nix  ──inputs──▶  nixpkgs / home-manager / cc-switch-cli
        │                   (版本由 flake.lock 锁定)
        │ modules
        ├──▶ hardware-configuration.nix   (硬件)
        ├──▶ configuration.nix            (系统)  ──▶ home-manager ──▶ home.nix (用户)
        └──▶ home-manager nixos module
```

## 使用

> 所有命令都在本仓库目录下执行。`.#nixos` 对应 `flake.nix` 里的 `nixosConfigurations.nixos`。

### 应用配置(系统 + 用户一起生效)

```bash
sudo nixos-rebuild switch --flake .#nixos
```

### 只构建测试,不切换(验证改动是否编译通过)

```bash
sudo nixos-rebuild test --flake .#nixos
```

### 更新依赖(升级 nixpkgs / home-manager)

```bash
nix flake update          # 更新 flake.lock
sudo nixos-rebuild switch --flake .#nixos
```

### 回滚

每次 `switch` 会产生一个新 generation。

```bash
# 回退到上一个 generation
sudo nixos-rebuild switch --rollback
```

开机时在 systemd-boot 引导菜单里也能直接选之前的 generation 进入。

## 修改配置

| 想改什么 | 改哪个文件 |
|---------|-----------|
| 桌面环境、系统服务(docker/网络/声音) | `configuration.nix` |
| 系统级软件、字体、输入法 | `configuration.nix` |
| 个人软件(ripgrep/fzf/编辑器…) | `home.nix` 的 `home.packages` |
| 个人 dotfiles(git/ssh/starship…) | `home.nix` 的 `programs.*` |
| 硬件(换磁盘/换机器) | 重新跑 `nixos-generate-config`,别手改 |

改完任意文件后,跑 `sudo nixos-rebuild switch --flake .#nixos` 生效。

## 推荐的 shell alias

```zsh
alias nrs='sudo nixos-rebuild switch --flake ~/nixos-config#nixos'
alias nrt='sudo nixos-rebuild test --flake ~/nixos-config#nixos'
alias nfu='nix flake update --flake ~/nixos-config'
```

## 注意事项

- `system.stateVersion`(在 `configuration.nix`)和 `home.stateVersion`(在 `home.nix`)首次设定后**永远不要修改**。
- `hardware-configuration.nix` 含本机磁盘 UUID,**换机器时必须重新生成**,直接拷贝到别的机器会无法启动。
- 首次引入新 input(如加新的 flake 依赖)后,`flake.lock` 会自动更新,记得一起 commit。
- 提交前建议先 `nixos-rebuild test` 验证能编译,再 `switch` + commit。
