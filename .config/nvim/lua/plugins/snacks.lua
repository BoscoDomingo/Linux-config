return {
  "folke/snacks.nvim",
  init = function()
    -- Open the same Snacks explorer used by <leader>e when Neovim starts.
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        -- Only open automatically for empty editor sessions, not files like COMMIT_EDITMSG.
        if vim.fn.argc() > 0 then
          return
        end

        Snacks.explorer({ cwd = LazyVim.root() })
      end,
    })
  end,
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true, -- Show files hidden by Snacks' Shift+H toggle by default.
          jump = { close = true }, -- Close the explorer after choosing a file to edit.
          layout = { preset = "sidebar", preview = { main = true, enabled = false } },
          actions = {
            explorer_preview_or_open = function(picker, item, action)
              if not item then
                return
              end

              local explorer_actions = require("snacks.explorer.actions").actions
              if picker.input.filter.meta.searching or item.dir then
                picker._dotfiles_explorer_l_preview = nil
                return explorer_actions.confirm(picker, item, action)
              end

              local path = Snacks.picker.util.path(item) or item.file
              if picker._dotfiles_explorer_l_preview == path then
                picker._dotfiles_explorer_l_preview = nil
                return explorer_actions.confirm(picker, item, action)
              end

              -- Make l preview first, then open only if l is pressed again before moving.
              picker._dotfiles_explorer_l_preview = path
              if not picker._dotfiles_explorer_l_reset then
                picker._dotfiles_explorer_l_reset = true
                vim.api.nvim_create_autocmd("CursorMoved", {
                  buffer = picker.list.win.buf,
                  callback = function()
                    picker._dotfiles_explorer_l_preview = nil
                  end,
                })
              end

              picker:toggle("preview", { enable = true, focus = "list" })
              vim.schedule(function()
                if not picker.closed then
                  picker:show_preview()
                end
              end)
            end,
          },
          win = {
            list = {
              keys = {
                l = "explorer_preview_or_open",
              },
            },
          },
        },
      },
    },
  },
}
