vim.g.MYVIMRC = "$XDG_CONFIG_HOME/nvim/init.lua" -- required to reload the config with :luafile $MYVIMRC
require("bosco") -- Imports my personal config

if vim.g.vscode then
    -- VSCode extension
    print("Inside the VS Code extension")
else
    -- ordinary Neovim
end
