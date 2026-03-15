{
  description = "Linux Retroism - A 1980-1990's retro UI theme for Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          gtk-theme = pkgs.stdenv.mkDerivation {
            pname = "linux-retroism-gtk-theme";
            version = "0.1.0";

            src = ./gtk_theme;

            dontBuild = true;
            dontConfigure = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/themes
              cp -r ClassicPlatinumStreamlined $out/share/themes/

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Mac OS 9 Classic-inspired GTK theme";
              homepage = "https://github.com/diinkii/linux-retroism";
              license = licenses.mit;
              platforms = platforms.linux;
            };
          };

          icon-theme = pkgs.stdenv.mkDerivation {
            pname = "linux-retroism-icon-theme";
            version = "0.1.0";

            src = ./icon_theme;

            dontBuild = true;
            dontConfigure = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/icons

              cp -Lrp RetroismIcons $out/share/icons/ 2>/dev/null || {
                cp -rp RetroismIcons $out/share/icons/
                find $out/share/icons/RetroismIcons -type l ! -exec test -e {} \; -delete
              }

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Mac OS 9 Classic-inspired icon theme";
              homepage = "https://github.com/diinkii/linux-retroism";
              license = licenses.mit;
              platforms = platforms.linux;
            };
          };

          default = pkgs.buildEnv {
            name = "linux-retroism";
            paths = [
              self.packages.${system}.gtk-theme
              self.packages.${system}.icon-theme
            ];
          };
        }
      );

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        with lib;
        let
          cfg = config.programs.linux-retroism;
        in
        {
          options.programs.linux-retroism = {
            enable = mkEnableOption "Linux Retroism GTK theme";

            package = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.gtk-theme;
              defaultText = literalExpression "self.packages.\${pkgs.system}.gtk-theme";
              description = "The Linux Retroism GTK theme package to use";
            };

            iconPackage = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.icon-theme;
              defaultText = literalExpression "self.packages.\${pkgs.system}.icon-theme";
              description = "The Linux Retroism icon theme package to use";
            };

            enableIcons = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to enable the Retroism icon theme";
            };
          };

          config = mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ] ++ (optionals cfg.enableIcons [ cfg.iconPackage ]);

            environment.sessionVariables = {
              GTK_THEME = "ClassicPlatinumStreamlined";
            };

            programs.dconf.enable = true;

            programs.dconf.profiles.user.databases = [
              {
                settings = {
                  "org/gnome/desktop/interface" = {
                    gtk-theme = "ClassicPlatinumStreamlined";
                  }
                  // (optionalAttrs cfg.enableIcons {
                    icon-theme = "RetroismIcons";
                  });
                };
              }
            ];
          };
        };
    };
}
