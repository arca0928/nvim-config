import type { Plugin } from "@shougo/dpp-vim/types";

import {
  BaseConfig,
  type ConfigArguments,
  type ConfigReturn,
} from "@shougo/dpp-vim/config";

import type { LazyMakeStateResult } from "@shougo/dpp-ext-lazy";

type Manifest = {
  plugins: Record<string, {
    path: string;
    version: string;
  }>;
};

type TomlResult = {
  plugins?: Plugin[];
  ftplugins?: Record<string, string>;
};

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<ConfigReturn> {
    const manifestPath = String(args.extraArgs.manifestPath);
    const tomlPath = String(args.extraArgs.tomlPath);

    const manifest = JSON.parse(
      await Deno.readTextFile(manifestPath),
    ) as Manifest;

    const [context, options] = await args.contextBuilder.get(args.denops);

    const toml = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "toml",
      "load",
      { path: tomlPath },
    ) as TomlResult | undefined;

    const overrides = new Map(
      (toml?.plugins ?? []).map((plugin) => [plugin.name, plugin]),
    );

    const plugins: Plugin[] = Object.entries(manifest.plugins).map((
      [name, src],
    ) => ({
      ...overrides.get(name),
      name,
      path: src.path,
      local: true,
    }));

    for (const name of overrides.keys()) {
      if (!(name in manifest.plugins)) {
        throw new Error(
          `dpp.toml references a plugin not provided by Nix: ${name}`,
        );
      }
    }

    const lazyResult = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "lazy",
      "makeState",
      { plugins },
    ) as LazyMakeStateResult | undefined;

    return {
      checkFiles: [manifestPath, tomlPath],
      plugins: lazyResult?.plugins ?? plugins,
      stateLines: lazyResult?.stateLines ?? [],
      ftplugins: toml?.ftplugins,
    };
  }
}
