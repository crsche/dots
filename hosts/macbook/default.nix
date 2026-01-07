{
  pkgs,
  inputs,
  ...
}:

let
  user = rec {
    name = "conor";
    home = "/Users/${name}";
    uid = 501;
  };
in
{
  # ---------------------------------------------------------------------------
  # Imports
  # ---------------------------------------------------------------------------
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.determinate.darwinModules.default
  ];

  # ---------------------------------------------------------------------------
  # Nix / Determinate
  # ---------------------------------------------------------------------------
  # NOTE: Using Determinate Systems' Nix installer
  nix.enable = false;

  determinate-nix.customSettings = {
    experimental-features = [ "parallel-eval" ];

    keep-env-derivations = true;
    keep-outputs = true;

    # Performance
    max-jobs = "auto";
    cores = 0;
    eval-cores = 0;
    http2 = true;
    http-connections = 128;
    max-substitution-jobs = 64;
    eval-cache = true;

    # Resiliency & Storage
    download-attempts = 5;
    # FIXME: https://releases.nixos.org/nix/nix-2.33.0/manual/release-notes/rl-2.33.html
    # Should be streaming so this is kind of(?) deprecated?
    download-buffer-size = 268435456; # 256 MiB
    nar-buffer-size = 33554432; # 32 MiB
    auto-optimise-store = true;
    use-sqlite-wal = true;
    fsync-metadata = false;

    # GC / Store hygiene
    keep-derivations = true;
    keep-build-log = false;

    # Caches
    substituters = [
      "https://cache.flakehub.com?priority=5"
      "https://nix-community.cachix.org?priority=10"
      "https://cache.nixos.org?priority=30"
      "https://install.determinate.systems?priority=40"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    ];
    trusted-users = [
      "root"
      user.name
    ];
  };

  # ---------------------------------------------------------------------------
  # nixpkgs + deployment target env
  # ---------------------------------------------------------------------------
  nixpkgs = {
    config = {
      # allowUnfree = true;
      # allowBroken = true;
    };
    overlays = [
      inputs.neovim-nightly-overlay.overlays.default
      inputs.fenix.overlays.default
    ];
  };

  # ---------------------------------------------------------------------------
  # Networking
  # ---------------------------------------------------------------------------
  networking = {
    knownNetworkServices = [
      "Wi-Fi"
      "Thunderbolt Bridge"
    ];

    dns = [
      "1.1.1.1"
      "1.0.0.1"
    ];

    hostName = "nix";

    applicationFirewall = {
      enable = true;

      enableStealthMode = true;

      blockAllIncoming = true;
      allowSigned = true;
      allowSignedApp = true;
    };
  };

  # ---------------------------------------------------------------------------
  # Security
  # ---------------------------------------------------------------------------
  security = {
    pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
      reattach = true;
    };
  };

  # ---------------------------------------------------------------------------
  # System (defaults, services, etc.)
  # ---------------------------------------------------------------------------
  system = {
    stateVersion = 6;
    primaryUser = user.name;

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };

    defaults = {
      # Global UI/UX
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleIconAppearanceTheme = "ClearAutomatic";
        _HIHideMenuBar = true;
        NSWindowShouldDragOnGesture = true;

        # Input & Keyboard
        AppleKeyboardUIMode = 2;
        ApplePressAndHoldEnabled = false;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;

        # Animations & Transitions
        NSWindowResizeTime = 0.0;
        NSAutomaticWindowAnimationsEnabled = false;
        NSScrollAnimationEnabled = false;

        # Behavior
        AppleShowScrollBars = "Always";
        AppleScrollerPagingBehavior = true;
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        AppleWindowTabbingMode = "manual";
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        AppleEnableSwipeNavigateWithScrolls = false;
        AppleEnableMouseSwipeNavigateWithScrolls = false;
        AppleSpacesSwitchOnActivate = false;

        # Text Input
        NSAutomaticInlinePredictionEnabled = true;
        NSAutomaticSpellingCorrectionEnabled = true;
        NSAutomaticDashSubstitutionEnabled = true;
        NSAutomaticQuoteSubstitutionEnabled = true;
        NSAutomaticPeriodSubstitutionEnabled = true;
        NSAutomaticCapitalizationEnabled = true;
      };

      # Dock & Mission Control
      dock = {
        autohide = true;
        autohide-delay = 0.001;
        autohide-time-modifier = 0.0;
        orientation = "left";
        tilesize = 32;
        static-only = true;
        show-recents = false;
        showhidden = true;
        mru-spaces = false;
        mineffect = "scale";
        launchanim = false;
        minimize-to-application = true;
        expose-animation-duration = 0.0;
        # Hot corners (1: Disabled)
        wvous-tr-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-bl-corner = 1;
      };

      # Finder
      finder = {
        QuitMenuItem = true;
        ShowStatusBar = true;
        ShowPathbar = true;
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        CreateDesktop = true;
        NewWindowTarget = "Recents";
        _FXSortFoldersFirst = true;
        FXDefaultSearchScope = "SCcf";
        _FXEnableColumnAutoSizing = true;
        FXPreferredViewStyle = "Nlsv";
        ShowRemovableMediaOnDesktop = false;
        ShowExternalHardDrivesOnDesktop = false;
      };

      # Input Devices
      trackpad = {
        TrackpadPinch = true;
        TrackpadRightClick = true;
        ActuateDetents = true;
        FirstClickThreshold = 0;
        TrackpadThreeFingerHorizSwipeGesture = 2;
      };

      # Built-in Tiling & Desktop Behavior (Disabled for external TWMs)
      WindowManager = {
        GloballyEnabled = false;
        EnableTilingByEdgeDrag = false;
        EnableTopTilingByEdgeDrag = false;
        EnableTilingOptionAccelerator = false;
        EnableTiledWindowMargins = false;
        HideDesktop = true;
        StandardHideDesktopIcons = true;
        StandardHideWidgets = true;
        StageManagerHideWidgets = true;
        EnableStandardClickToShowDesktop = false;
      };

      # Miscellaneous
      menuExtraClock = {
        ShowDate = 0;
        ShowDayOfWeek = true;
        ShowDayOfMonth = true;
        ShowSeconds = true;
      };

      screencapture = {
        target = "clipboard";
        type = "png";
        include-date = true;
        disable-shadow = true;
        show-thumbnail = true;
      };

      controlcenter = {
        AirDrop = true;
        Bluetooth = true;
        BatteryShowPercentage = true;
        Sound = true;
        FocusModes = true;
        NowPlaying = true;
      };

      universalaccess = {
        reduceMotion = true;
        reduceTransparency = false;
      };

      ActivityMonitor = {
        IconType = 6;
        SortColumn = "% CPU";
        ShowCategory = 101;
      };

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      iCal = {
        "TimeZone support enabled" = true;
        CalendarSidebarShown = true;
      };

      hitoolbox = {
        AppleFnUsageType = "Show Emoji & Symbols";
      };

      loginwindow = {
        GuestEnabled = false;
      };

      SoftwareUpdate = {
        AutomaticallyInstallMacOSUpdates = true;
      };

      spaces = {
        spans-displays = false;
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Single-user Setup
  # ---------------------------------------------------------------------------
  programs.fish.enable = true;

  users.users.${user.name} = {
    inherit (user) name home uid;
    shell = pkgs.fish;
  };

  users.knownUsers = [ user.name ];

  # ---------------------------------------------------------------------------
  # Single-user home-manager
  # ---------------------------------------------------------------------------
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user.name} = ./home.nix;
  };

}
