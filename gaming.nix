# ─────────────────────────────────────────────────────────────
# 游戏开发软件 —— 独立 home-manager 模块
#
# 抽成单独文件，方便把游戏开发环境带到其它分支：
# 在目标分支的 home.nix 里改一行即可，不必 cherry-pick 整段 home.packages。
#
#   imports = [ ./niri.nix ./gaming.nix ];
#
# 不需要游戏开发环境的分支，删掉那行 import 就行。
# ─────────────────────────────────────────────────────────────
{ pkgs, ... }: {
  home.packages = with pkgs; [
    godot                # Godot 4 引擎（GDScript）
    godot-mono           # Godot 4 + C#/.NET 8（自带 dotnet sdk，命令名 godot-mono）
    blender              # 3D 建模 / 动画 / 导出 glTF
    krita                # 2D 绘制
    tiled                # 瓦片地图编辑器
    libresprite          # 像素画
    # aseprite           # 像素画（unfree，想要再开）
  ];
}
