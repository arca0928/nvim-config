local manifest = vim.json.decode(
    table.concat(vim.fn.readfile(manifest_path), "\n")
)

local function plugin_path(name)
    local plugin = manifest.plugins[name]
    assert(plugin, "Plugin: " .. name .. " is missing")
    return plugin.path
end

vim.opt.runtimepath:prepend(fennel_config_path)
require("config")

vim.opt.runtimepath:prepend(plugin_path("dpp.vim"))

local dpp = require("dpp")
local dpp_base = vim.fn.stdpath("cache") .. "/dpp"

if dpp.load_state(dpp_base, manifest_hash) then
    for _, name in ipairs({
        "denops.vim",
        "dpp-ext-lazy",
        "dpp-ext-toml",
    }) do
        vim.opt.runtimepath:prepend(plugin_path(name))
    end

    vim.api.nvim_create_autocmd("User", {
        pattern = "DenopsReady",
        once = true,
        callback = function()
            dpp.make_state(
                dpp_base,
                dpp_config_path,
                manifest_hash,
                {
                    manifestPath = manifest_path,
                    tomlPath = dpp_toml_path,
                }
            )
        end,
    })
end
