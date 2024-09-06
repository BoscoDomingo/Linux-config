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
