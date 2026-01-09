{
  pkgs,
  ...
}:
let
  hostName = "vps";
  rootDisk = "/dev/disk/by-uuid/a03c79b4-0622-43d7-ac01-d24cdd70e685";
in
{
  nixpkgs = {
    overlays = [
      (
        final: prev:
        let
          optimizedStdenv = prev.lib.pipe prev.stdenv [
            # 1. Use the Mold linker
            prev.useMoldLinker

            # 2. Apply impure native optimizations (march=native)
            prev.impureUseNativeOptimizations

            # 3. Add compiler flags
            # We wrap this in parenthesis to pass the argument
            (prev.withCFlags [
              "-O3"
              "-flto"
              "-funroll-loops"
            ])
          ];
        in
        {
          # TODO
        }
      )
    ];
    hostPlatform = {
      system = "x86_64-linux";
      gcc = {
        # arch = "znver1";
        # tune = "znver1";
      };
    };
  };

  fileSystems."/" = {
    device = rootDisk;
    options = [
      "noatime"
      "nodiratime"
      "discard=async" # Trim NVMe asynchronously
      "commit=60" # Write to disk every 60s
    ];
    fsType = "ext4";
  };

  hardware = {
    # VPS uses EPYC
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = false;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    initrd = {
      availableKernelModules = [
        "virtio_pci"
        "virtio_mmio"
        "virtio_blk"
        "virtio_scsi"

        "virtio_net"
      ];
      kernelModules = [
        "virtio_balloon"
        "virtio_console"
        "virtio_rng"
      ];
      verbose = false;
      compressor = "zstd";
    };
    loader = {
      grub = {
        splashImage = null;
        forceInstall = true;
        device = rootDisk;
      };
      timeout = 1;
    };
    kernelParams = [
      # CPU & SCHEDULING
      "preempt=full" # Maximize responsiveness
      "scsi_mod.use_blk_mq=1" # NVMe multi-queue
      "elevator=none" # Let the NVMe controller handle scheduling, OS scheduler adds latency

      # MEMORY
      "transparent_hugepage=madvise" # 'always' causes latency spikes during compaction. 'madvise' is smoother.

      # WATCHDOGS (Kill them to save cycles)
      "nowatchdog"
      "nmi_watchdog=0"

      # CONSOLE
      "console=ttyS0" # Contabo uses serial console for VNC/Emergency
      "panic=10" # Reboot after 10s on panic

      # FROM
      "panic=1"
      "boot.panic_on_fail"
      "vga=0x317"
      "nomodeset"
    ];
    kernelModules = [ "tcp_bbr" ];
    kernel.sysctl = {
      # BBR Congestion Control
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";

      # TCP Fast Open (Lowers RTT for re-visits)
      "net.ipv4.tcp_fastopen" = 3;

      # Connection Handling
      "net.ipv4.tcp_max_syn_backlog" = 4096;
      "net.ipv4.tcp_max_tw_buckets" = 200000;
      "net.ipv4.tcp_tw_reuse" = 1; # Allow reusing sockets in TIME_WAIT
      "net.ipv4.tcp_fin_timeout" = 10;
      "net.ipv4.tcp_slow_start_after_idle" = 0; # Keep connections fast even after idle
      "net.ipv4.tcp_mtu_probing" = 1; # Help with blackhole routers

      # Security/Stability
      "vm.swappiness" = 10; # Prefer RAM over swap
      "vm.vfs_cache_pressure" = 50; # Cache filesystem metadata aggressively
      "kernel.hung_task_timeout_secs" = 30;
    };
  };

  networking = {
    inherit hostName;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
      allowPing = true;
      logRefusedConnections = false;
    };
    useDHCP = true;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  services = {
    fstrim = {
      enable = true;
      interval = "weekly";
    };
    logrotate = {
      enable = true;
      settings.header = {
        dateext = true;
        compress = true;
      };
    };
    journald.extraConfig = "SystemMaxUse=100M"; # Prevent logs eating 75GB disk

    irqbalance = {
      enable = true;
    };
    openssh = {
      enable = true;
      package = pkgs.openssh_hpn;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
        KbdInteractiveAuthentication = false;
      };
    };
    qemuGuest = {
      enable = true;
    };
    udisks2.enable = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF4x4a59eOntSGiZqdnZtUr1PJvW/r8ehc/ZK21FCmsc" # Macbook
  ];

  systemd = {
    services = {
      "serial-getty@ttyS0".enable = false;
      "serial-getty@hvc0".enable = false;
      "getty@tty1".enable = false;
      "autovt@".enable = false;
      "NetworkManager-wait-online".enable = false;
      "systemd-networkd-wait-online".enable = false;
      "auditd".enable = false;

    };
    network.wait-online.enable = false;

    enableEmergencyMode = false;
  };

  security = {
    sudo.wheelNeedsPassword = false;
    pam.loginLimits = [
      # High file limit for Nginx/Git
      {
        domain = "*";
        item = "nofile";
        type = "-";
        value = "65536";
      }
      {
        domain = "*";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
    ];
  };

  environment = {
    defaultPackages = [ ];
    stub-ld.enable = false;
  };

  programs = {
    mosh = {
      enable = true;
      withUtempter = true;
      openFirewall = true;
    };
    command-not-found.enable = false;
    fish.generateCompletions = false;
  };

  xdg = {
    autostart.enable = false;
    icons.enable = false;
    mime.enable = false;
    sounds.enable = false;
  };

  documentation = {
    enable = false;
    nixos.enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
  };

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  nix = {
    enable = true;
    settings = {
      max-jobs = "auto";
      cores = 0;

      auto-optimise-store = true;
      keep-outputs = false;
      keep-derivations = false;

      allowed-users = [ "@wheel" ];

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      system-features = [
        "big-parallel"
        "kvm"
        "gccarch-znver1"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";

    };
  };

  system.stateVersion = "26.05";
}
