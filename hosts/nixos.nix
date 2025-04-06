{ config, pkgs, inputs, lib, ... }: {

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;

  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
 
  # Home Manager user config
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.josh = import ../home/josh.nix;

  # Bootloader with nvidia default
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
    configurationLimit = 5;
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;
  
  # Filesystems
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-root";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-label/SWAP"; }
  ];

  # Hostname & Locale
  networking.hostName = "nixos";
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # User setup
  users.users.josh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # ----------------------
  # 🧠 Session Variables
  # ----------------------
#  environment.sessionVariables = {
#    WLR_DRM_DEVICES = "/dev/dri/card0"; # ← Confirm this is still the NVIDIA card
#    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
#    LIBVA_DRIVER_NAME = "nvidia";
#    WLR_RENDERER_ALLOW_SOFTWARE = "0";
#    WLR_NO_HARDWARE_CURSORS = "1"; # Optional, fixes flicker sometimes
#  };

# --------------------------------------
# 🖥️ NVIDIA as default (dock mode)
# --------------------------------------

services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];
boot.initrd.kernelModules = lib.mkForce [ "nvidia" ];
hardware.enableRedistributableFirmware = true;

# NVIDIA PRIME
boot.kernelParams = lib.mkForce [ "nvidia-drm.modeset=1" ];

services.logind = {
  lidSwitch = "ignore";
  lidSwitchDocked = "ignore";
  lidSwitchExternalPower = "ignore";
};

hardware.opengl = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;
};

hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
#  open = true;

#  prime = {
#    sync.enable = true;
#    nvidiaBusId = "PCI:1:0:0";
#    amdgpuBusId = "PCI:6:0:0";
#  };

};


# --------------------------------------
# 🪟 Display Manager + Hyprland
# --------------------------------------

services.xserver.enable = true;
services.xserver.displayManager.sddm = {
  enable = true;
  theme = "breeze";
};
services.xserver.windowManager.hypr.enable = true;

programs.hyprland = {
  enable = true;
  package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
};

# --------------------------------------
# 🔋 AMD spec (battery/mobile mode)
# --------------------------------------

specialisation.amd.configuration = {
  system.nixos.label = "nixos-amd";

  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware.nvidia = lib.mkForce { };

  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
  };
};


  environment.systemPackages = with pkgs; [
    # System Tools
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    wayland
    dbus
    pciutils
    usbutils
    config.boot.kernelPackages.nvidiaPackages.stable.bin
    gnome.adwaita-icon-theme
  ];

  environment.variables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  # Audio
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };

# Disable NetworkManager
networking.networkmanager.enable = false;
networking.useDHCP = false;

# Static IP setup for enp4s0
networking.interfaces.enp4s0 = {
  useDHCP = false;
  ipv4.addresses = [{
    address = "192.168.10.109";
    prefixLength = 24;
  }];
};

# Default gateway
networking.defaultGateway = "192.168.10.1";

# DNS servers
networking.nameservers = [ "192.168.1.1" "8.8.8.8" ];


  # Nix config
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  system.stateVersion = "23.11";
}
