return {
  "folke/snacks.nvim",
  init = function()
    -- Open the same Snacks explorer used by <leader>e when Neovim starts.
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        Snacks.explorer({ cwd = LazyVim.root() })
      end,
    })
  end,
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true, -- Show files hidden by Snacks' Shift+H toggle by default.
        },
      },
    },
  },
}
