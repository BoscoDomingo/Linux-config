vim.g.MYVIMRC = "$XDG_CONFIG_HOME/nvim/init.lua"
require("bosco")

if vim.g.vscode then
    -- VSCode extension
    print("Inside the VS Code extension")
else
    -- ordinary Neovim
end
