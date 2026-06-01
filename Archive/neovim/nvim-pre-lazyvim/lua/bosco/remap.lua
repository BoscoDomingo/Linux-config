-- Remap space as leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Go to explorer with space + e
vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

-- Save with ctrl + s
vim.keymap.set("n", "<C-s>", vim.cmd.w)

-- Use system keyboard
vim.api.nvim_set_keymap('v', '<C-c>', '"+yi', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-x>', '"+c', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-v>', 'c<ESC>"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-v>', '<ESC>"+pa', { noremap = true, silent = true })

-- Source: https://vim.fandom.com/wiki/Moving_lines_up_or_down
-- nnoremap <A-j> :m .+1<CR>==
-- nnoremap <A-k> :m .-2<CR>==
-- inoremap <A-j> <Esc>:m .+1<CR>==gi
-- inoremap <A-k> <Esc>:m .-2<CR>==gi
-- vnoremap <A-j> :m '>+1<CR>gv=gv
-- vnoremap <A-k> :m '<-2<CR>gv=gv
vim.keymap.set("n", "<A-j>", ":m+<CR>==")
vim.keymap.set("n", "<A-k>", ":m-2<CR>==")
vim.keymap.set("i", "<A-j>", "<Esc>:m+<CR>==gi")
vim.keymap.set("i", "<A-k>", "<Esc>:m-2<CR>==gi")
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "<A-down>", ":m+<CR>==")
vim.keymap.set("n", "<A-up>", ":m-2<CR>==")
vim.keymap.set("i", "<A-down>", "<Esc>:m+<CR>==gi")
vim.keymap.set("i", "<A-up>", "<Esc>:m-2<CR>==gi")
vim.keymap.set("v", "<A-down>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-up>", ":m '<-2<CR>gv=gv")
