(macro sets [& expr]
  `(set ,expr))

(set vim.o.fileencodings [:ucs-bom :utf-8 :iso-2022-jp :euc-jp :cp932])
(set vim.o.fileformats [:unix :dos])
(set vim.o.ambiwidth :single)

(vim.o.formatoptions:append {:m true :M true})

(set vim.o.number true)
(set vim.o.relativenumber true)
(set vim.o.cursorline true)
(set vim.o.signcolumn :yes)

(set vim.o.wrap false)

(set vim.o.termguicolors true)

{}
