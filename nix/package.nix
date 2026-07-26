{ pkgs, lib, ... }:
let
  pluginNames = builtins.attrNames (import ../npins { });

  plugins = lib.genAttrs pluginNames (name: pkgs.vimPlugins.${name});

  manifestJSON = builtins.toJSON {
    plugins = builtins.mapAttrs (_name: plugin: {
      path = "${plugin}";
      version = "${plugin.version}";
    }) plugins;
  };
  manifest = pkgs.writeText "manifest.json" manifestJSON;
  manifestHash = builtins.hashString "sha256" manifestJSON;

  dppConfigSource = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../dpp.ts
      ../dpp.toml
      ../deno.json
      ../deno.lock
    ];
  };

  fennelConfig =
    pkgs.runCommand "nvim-fennel-config"
      {
        nativeBuildInputs = [ pkgs.luaPackages.fennel ];
      }
      ''
        mkdir -p $out/lua

        cd ${../.}
        find fnl -type f -name '*.fnl' | while read -r source; do
          relative="''${source#fnl/}"
          target="$out/lua/''${relative%.fnl}.lua"

          mkdir -p "$(dirname "$target")"
          fennel --compile "$source" > "$target"
        done
      '';

  config = {
    vimAlias = true;

    wrapperArgs = [
      "--suffix"
      "PATH"
      ":"
      (lib.makeBinPath [
        pkgs.deno
        pkgs.ripgrep
      ])
    ];

    luaRcContent = ''
      local fennel_config_path = "${fennelConfig}"
      local manifest_path = "${manifest}"
      local manifest_hash = "${manifestHash}"
      local dpp_toml_path = "${dppConfigSource}/dpp.toml"
      local dpp_config_path = "${dppConfigSource}/dpp.ts"
    ''
    + builtins.readFile ../init.lua;
  };
  package = pkgs.neovim-unwrapped;
in
pkgs.wrapNeovimUnstable package config
