# 上游（vendored）

这是 **原样搬进来**的 [Clavis shell](https://github.com/StatIndet/quickshell) 源码，
只去掉了 `.git`，**不要在这里做本地修改**：

- 我们自己的 shell 在 `assets/quickshell/clavis-style/`
- 要改 Clavis 就写 patch，并在下面的「本地改动」里记录

## 来源

| 项 | 值 |
| --- | --- |
| 仓库 | https://github.com/StatIndet/quickshell |
| `VERSION` | `2026.9.12` |
| 检出的提交 | `c3ee54f` — 2026-10-07 `fix: 日历缺少跨天刷新机制，而 Qt 月份模型中的“今天”状态会被缓存。` |
| 许可 | 见 `LICENSE` 与 `licenses/` |

## 怎么更新

```bash
git clone https://github.com/StatIndet/quickshell /tmp/quickshell-inspect
git -C /tmp/quickshell-inspect pull --ff-only
rsync -a --exclude=.git --delete /tmp/quickshell-inspect/ assets/quickshell/clavis/
```

（`--delete` 会删掉上游已经没有的文件；`UPSTREAM.md` 是本地加的，
更新完记得 `git checkout -- assets/quickshell/clavis/UPSTREAM.md`。）

## Nix 打包

见 `packages/clavis-shell.nix`。它做三件事：

1. 用 CMake 构建 native QML 插件（`core/`）→ `$out/lib/qt6/qml/Clavis`
2. 把 QML 配置本体装到 `$out/etc/xdg/quickshell/clavis`
   （Quickshell 会去 XDG 配置目录里找名为 `clavis` 的配置，所以
   `XDG_CONFIG_DIRS` 带上 `$out/etc/xdg` 后直接 `quickshell -c clavis` 就行）
3. systemd user unit → `$out/lib/systemd/user`

## 本地改动

- `Modules/Bar/HorizontalBarWindow.qml` / `VerticalBarWindow.qml`：bar 的
  `overlay` 模式原来用 `exclusiveZone: 0`，niri 仍按 surface 高度预留（窗口被
  推下 52px）；改成 `-1` 才真正不占 work area。
