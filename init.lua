-- Bootstrap Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 8
vim.opt.clipboard = "unnamedplus"

-- Detect if running on Windows
local transparent = vim.loop.os_uname().version:match("Windows")



-- Transparency (only if NOT Windows)
local function apply_transparency()
  if transparent then
    vim.cmd [[
      hi Normal guibg=NONE ctermbg=NONE
      hi NormalNC guibg=NONE ctermbg=NONE
      hi SignColumn guibg=NONE
      hi VertSplit guibg=NONE
      hi StatusLine guibg=NONE
      hi EndOfBuffer guibg=NONE

      hi NvimTreeNormal guibg=NONE ctermbg=NONE
      hi NvimTreeNormalNC guibg=NONE ctermbg=NONE
      hi NvimTreeVertSplit guibg=NONE ctermbg=NONE
      hi NvimTreeEndOfBuffer guibg=NONE ctermbg=NONE

      hi NormalFloat guibg=NONE ctermbg=NONE
      hi FloatBorder guibg=NONE ctermbg=NONE
    ]]
  else
    vim.cmd [[
      hi clear Normal
      hi clear NormalNC
      hi clear SignColumn
      hi clear VertSplit
      hi clear StatusLine
      hi clear EndOfBuffer
      hi clear NvimTreeNormal
      hi clear NvimTreeNormalNC
      hi clear NvimTreeVertSplit
      hi clear NvimTreeEndOfBuffer
      hi clear NormalFloat
      hi clear FloatBorder
      colorscheme tokyonight-storm
    ]]
  end
end


vim.api.nvim_create_user_command("Trans", function()
  transparent = not transparent
  apply_transparency()
  print("Transparency " .. (transparent and "enabled" or "disabled"))
end, {})


apply_transparency()



-- Plugins
require("lazy").setup({
  -- LSP + Autocomplete
  { "williamboman/mason.nvim", config = true },
  { "williamboman/mason-lspconfig.nvim" },
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "windwp/nvim-autopairs", config = true },
  { "olrtg/emmet-language-server" },
  { "windwp/nvim-ts-autotag", config = true },
  -- Telescope and Terminal keymaps
  { "nvim-telescope/telescope.nvim", tag = "0.1.6", dependencies = { "nvim-lua/plenary.nvim" } },
  { "akinsho/toggleterm.nvim", config = true },
  -- Syntax highlighting
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  -- File explorer
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 35 },
        renderer = { highlight_git = true, icons = { show = { file = true, folder = true } } },
        hijack_netrw = true,
        respect_buf_cwd = true,
        sync_root_with_cwd = true,
      })
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function(data)
          local directory = vim.fn.isdirectory(data.file) == 1
          if directory then
            require("nvim-tree.api").tree.open()
          else
            require("nvim-tree.api").tree.open({ focus = false })
          end
        end,
      })
    end
  },
  -- Color theme
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, config = function()
      vim.cmd("colorscheme tokyonight-storm")
    end },
})


local builtin = require("telescope.builtin")

vim.keymap.set("n", "<Space>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<Space>fg", builtin.buffers, { desc = "Recently opened files" })

-- NvimTree toggle shortcut
vim.keymap.set("n", "<Space>fe", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })

-- Terminal shortcut
vim.keymap.set("n", "<Space>tt", ":terminal<CR>", { desc = "Open terminal" })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Floating terminal setup
require("toggleterm").setup({
  open_mapping = [[<Space>tt]],
  direction = "float",
  float_opts = {
    border = "curved",
  },
  shade_terminals = true,
  start_in_insert = true,
  insert_mappings = true,
})


-- Autopairs integration
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local cmp = require("cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

-- Mason + LSP setup
require("mason-lspconfig").setup({
  ensure_installed = { "ts_ls", "html", "cssls", "jsonls", "tailwindcss", "emmet_language_server" },
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config["emmet_language_server"] = {
  filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
  capabilities = capabilities,
}
vim.lsp.enable("emmet_language_server")

-- Autocomplete setup
cmp.setup({
  snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
  mapping = {
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require("luasnip").expand_or_jumpable() then
        require("luasnip").expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif require("luasnip").jumpable(-1) then
        require("luasnip").jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  },
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }),
})

-- LSP config
vim.lsp.config["tsserver"] = {
  capabilities = capabilities,
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
}
vim.lsp.config["html"] = { capabilities = capabilities }
vim.lsp.config["cssls"] = { capabilities = capabilities }
vim.lsp.config["jsonls"] = { capabilities = capabilities }
vim.lsp.config["tailwindcss"] = { capabilities = capabilities }

vim.lsp.enable("tsserver")
vim.lsp.enable("html")
vim.lsp.enable("cssls")
vim.lsp.enable("jsonls")
vim.lsp.enable("tailwindcss")

require("nvim-treesitter.configs").setup({
  highlight = { enable = true },
  autotag = { enable = true },
})

-- Re-apply transparency on colorscheme change
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = apply_transparency,
})

-- set colorscheme and apply transparency if possible
vim.cmd("colorscheme tokyonight-storm")
apply_transparency()
