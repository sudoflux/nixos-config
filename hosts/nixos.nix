{ config, pkgs, inputs, lib, ... }: {

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;

  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  # Home Manager
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.josh = import ../home/josh.nix;

  # Bootloader
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.timeout = 0;

# systemd service for monitor script

systemd.services.early-display = {
  description = "Configure monitors before SDDM starts";
  wantedBy = [ "multi-user.target" ];
  before = [ "display-manager.service" ];
  after = [ "systemd-udevd.service" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "/etc/nixos/scripts/monitors.sh";
  };
};

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

  # Host & Locale
  networking.hostName = "nixos";
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # User
  users.users.josh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # NVIDIA default (dock mode)
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.initrd.kernelModules = [ "nvidia" ];
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
  hardware.enableRedistributableFirmware = true;

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
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

# Display manager + Hyprland
services.displayManager.sddm.enable = true;
services.displayManager.sddm.wayland.enable = true;
services.displayManager.defaultSession = "hyprland";
services.displayManager.sddm.theme = "Breeze";

programs.hyprland = {
  enable = true;
  package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
};

  # Static networking
  networking.networkmanager.enable = false;
  networking.useDHCP = false;
  networking.interfaces.enp4s0 = {
    useDHCP = false;
    ipv4.addresses = [{
      address = "192.168.10.109";
      prefixLength = 24;
    }];
  };
  networking.defaultGateway = "192.168.10.1";
  networking.nameservers = [ "192.168.1.1" "8.8.8.8" ];

  # System packages
  environment.systemPackages = with pkgs; [
    egl-wayland
    nvidia-vaapi-driver
    libva
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    wayland
    dbus
    pciutils
    usbutils
    gnome.adwaita-icon-theme
#    config.boot.kernelPackages.nvidiaPackages.stable.bin
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

  # Nix features
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  system.stateVersion = "23.11";

  environment.etc."nixos/scripts/monitors.sh".source = inputs.self + "/scripts/monitors.sh";

}
