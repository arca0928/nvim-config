{
  description = "my neovim configurations with nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      pluginSources = import ./npins { };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt.flakeModule
        inputs.git-hooks.flakeModule
      ];
      systems = [ "x86_64-linux" ];

      perSystem =
        {
          self',
          pkgs,
          system,
          config,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                vimPlugins =
                  let
                    pluginBuildOverrides = {
                      "catppuccin.nvim" = {
                        nvimSkipModules = [
                          "catppuccin.groups.integrations.noice"
                          "catppuccin.lib.detect_integrations"
                        ];
                      };
                    };
                    buildPlugin =
                      name: src:
                      prev.vimUtils.buildVimPlugin (
                        {
                          inherit src;
                          pname = builtins.replaceStrings [ "." ] [ "-" ] name;
                          version = src.version;
                        }
                        // (pluginBuildOverrides.${name} or { })
                      );
                    buildPlugins = sources: builtins.mapAttrs buildPlugin sources;
                  in
                  prev.vimPlugins // buildPlugins pluginSources;
              })
            ];
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              deno
              npins
              nixd
              fennel-ls
            ];

            shellHook = ''
              ${config.pre-commit.shellHook}
            '';
          };

          treefmt = {
            programs = {
              nixfmt.enable = true;
              deno.enable = true;
              fnlfmt.enable = true;
            };
          };

          pre-commit = {
            check.enable = true;
            settings.hooks.treefmt.enable = true;
          };

          packages = rec {
            default = pkgs.callPackage ./nix/package.nix { };
            neovim = default;
          };
          apps.default = {
            program = self'.packages.default;
          };
        };
    };
}
