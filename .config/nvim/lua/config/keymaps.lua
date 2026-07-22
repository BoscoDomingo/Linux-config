-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- the following mappings will produce:
--	d => "delete"
-- 	leader d => "cut"
-- Source: https://stackoverflow.com/questions/11993851/how-to-delete-not-cut-in-vim
vim.keymap.set({ "n", "v" }, "d", '"_d', { desc = "Delete without copying to register", noremap = true })
vim.keymap.set("n", "x", '"_x', { desc = "Cut without copying to register", noremap = true })
vim.keymap.set("n", "D", '"_D', { desc = "Delete without copying to register", noremap = true })

vim.keymap.set({ "n", "v" }, "<leader>d", '""d', { desc = "Cut and copy to register", noremap = true })
vim.keymap.set("n", "<leader>D", '""D', { desc = "Cut and copy to register", noremap = true })
vim.keymap.set("n", "<leader>dd", '""dd', { desc = "Cut and copy to register", noremap = true })
