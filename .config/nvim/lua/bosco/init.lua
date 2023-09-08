require("bosco.remap")

vim.opt.compatible = false
--
-- Line number settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.statuscolumn = '%s%=%{v:relnum?v:relnum:v:lnum} '

-- Color settings
vim.opt.termguicolors = true

-- Indentation settings
vim.opt.smartindent = true
--

--
-- Use system clipboard. Source: https://www.reddit.com/r/neovim/comments/vxdjyb/neovim_in_wsl2_cant_copypaste_tofrom_system/itiyb3p/
vim.opt.clipboard = "unnamedplus"
if vim.fn.has("wsl") == 1 then
    vim.api.nvim_create_autocmd("TextYankPost", {
        group = vim.api.nvim_create_augroup("Yank", {
            clear = true
        }),
        callback = function()
            vim.fn.system("clip.exe", vim.fn.getreg('"'))
        end
    })
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
--

--
-- Cursor settings
vim.opt.guicursor = "a:ver30-Cursor-blinkwait700-blinkon400-blinkoff250"
vim.opt.cursorline = true -- Highlight current line

-- :au VimLeave * set guicursor= | call chansend(v:stderr, "\x1b[ q") -- reset cursor to normal on exit (vimscript)
vim.api.nvim_create_autocmd("VimLeave", { -- reset cursor to normal on exit (Lua)
    pattern = "*",
    callback = function()
        vim.opt.guicursor = "a:ver30-blinkon1"

        -- Reset the GUI cursor to default by clearing the 'guicursor' option
        -- vim.opt.guicursor = ""

        -- Send the escape sequence to stderr to reset the cursor appearance
        -- vim.fn.chansend(vim.v.stderr, "\x1b[ q") -- reset cursor to normal on exit
    end
})

-- Allow cursor to move one character beyond the end of the line in visual mode
vim.opt.virtualedit:append("onemore")
--
