vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.background = "light"
vim.opt.breakindent = true
vim.opt.confirm = true
vim.opt.cursorline = true
vim.opt.ignorecase = true
vim.opt.mouse = "a"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 6
vim.opt.showmode = false
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.timeoutlen = 400
vim.opt.undofile = true
vim.opt.updatetime = 200

if not pcall(vim.cmd.colorscheme, "quiet") then
  vim.cmd.colorscheme("habamax")
end

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true })
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "H", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "L", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<M-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<M-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })

local function toggle_markdown_checkbox()
  local line = vim.api.nvim_get_current_line()
  local changed
  line, changed = line:gsub("^(%s*[-*+] )%[[xX]%]", "%1[ ]", 1)
  if changed == 0 then
    line, changed = line:gsub("^(%s*[-*+] )%[ %]", "%1[x]", 1)
  end
  if changed == 0 then
    line = line:gsub("^(%s*[-*+] )", "%1[ ] ", 1)
  end
  vim.api.nvim_set_current_line(line)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" },
  callback = function(args)
    vim.opt_local.breakindent = true
    vim.opt_local.colorcolumn = ""
    vim.opt_local.conceallevel = 0
    vim.opt_local.expandtab = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.textwidth = 100
    vim.opt_local.wrap = true
    vim.opt_local.formatoptions:append("jnq")

    if vim.bo[args.buf].filetype == "markdown" then
      vim.keymap.set("n", "[h", function()
        vim.fn.search("^#\\+\\s", "bW")
      end, { buffer = args.buf, desc = "Previous Markdown heading" })
      vim.keymap.set("n", "]h", function()
        vim.fn.search("^#\\+\\s", "W")
      end, { buffer = args.buf, desc = "Next Markdown heading" })
      vim.keymap.set("n", "<leader>x", toggle_markdown_checkbox, {
        buffer = args.buf,
        desc = "Toggle Markdown checkbox",
      })
    end
  end,
})
