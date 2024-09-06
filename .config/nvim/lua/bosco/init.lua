require("bosco.remap")

-- Line number settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.statuscolumn = '%s%=%{v:relnum?v:relnum:v:lnum} '

-- Color settings
vim.opt.termguicolors = true
vim.opt.cursorline = true

-- Use system clipboard. Source: https://www.reddit.com/r/neovim/comments/vxdjyb/neovim_in_wsl2_cant_copypaste_tofrom_system/itiyb3p/
vim.opt.clipboard = "unnamedplus"
if vim.fn.has("wsl") == 1 then
    vim.api.nvim_create_autocmd(
        "TextYankPost",
        {
            group = vim.api.nvim_create_augroup("Yank", {clear = true}),
            callback = function()
                vim.fn.system("clip.exe", vim.fn.getreg('"'))
            end
        }
    )
end

-- WSL yank support (slower than above, doesn't work with clipboard correctly. Source: https://superuser.com/a/1557751)
--[[
if vim.fn.executable("clip.exe") == 1 then
    vim.api.nvim_create_augroup("WSLYank", { clear = true })
    vim.api.nvim_create_autocmd("TextYankPost", {
        group = "WSLYank",
        callback = function()
            if vim.v.event.operator == 'y' then
                vim.fn.system("clip.exe", vim.fn.getreg('0'))
            end
        end
    })
end
--]]

-- Indentation settings
vim.opt.smartindent = true
