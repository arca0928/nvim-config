(local catppuccin (require :catppuccin))

(catppuccin.setup {:flavor :frappe
                   :transparent-background false
                   :integrations {:native-lsp {:enabled true}}})

(vim.cmd.colorscheme :catppuccin)

{}
