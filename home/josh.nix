{ config, pkgs, ... }:

{
  home.username = "josh";
  home.homeDirectory = "/home/josh";
  home.stateVersion = "23.11";

  # ---------------------------
  # 🖥️ Hyprland Window Manager
  # ---------------------------
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      env = [
#        "WLR_DRM_DEVICES,/dev/dri/card1"   
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "LIBVA_DRIVER_NAME,nvidia"
        "WLR_RENDERER_ALLOW_SOFTWARE,0"
        "WLR_NO_HARDWARE_CURSORS,1"
      ];
      monitor = [ ",preferred,auto,1" ];  # safe fallback
      exec-once = [
        "~/.config/hypr/monitors.sh"
        "waybar"
        "kitty"
      ];
      bind = [
        "SUPER,Return,exec,kitty"
        "SUPER,B,exec,firefox"
        "SUPER,Q,killactive"
        "SUPER,F,fullscreen,1"
        "SUPER,Space,togglefloating"
        "SUPER,D,exec,rofi -show drun"
        "SUPER,L,exec,hyprlock"
        "SUPER_SHIFT,R,exec,hyprctl reload"
      ];
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
      };
      animations.enabled = false; # disable for performance
      input.kb_layout = "us";
    };
  };

  # ----------------------
  # 🔧 Terminal & Programs
  # ----------------------
  programs.kitty.enable = true;
  programs.waybar.enable = true;
  programs.firefox.enable = true;
  programs.rofi.enable = true;

  # ---------------
  # 🧠 Neovim setup
  # ---------------
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };

  # --------------------
  # 🐚 Zsh & Starship
  # --------------------
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      nixclean = "~/scripts/nix-cleanup.sh";
      rebootamd = ''sudo systemctl reboot --boot-loader-entry=$(bootctl list | awk "/specialisation-amd/{getline; print \$2}")'';
    };

    initExtra = ''
      export EDITOR=nvim
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory $git_branch $character";
    };
  };

  # ---------------------
  # 📦 Extra packages
  # ---------------------
  home.packages = with pkgs; [
    hyprland
    foot
    wofi
    swww
    git
    curl
    wget
    htop
    unzip
    starship
    jq
  ];

  # -------------------
  # 📡 D-Bus services
  # -------------------
  services.mpris-proxy.enable = true;
}
