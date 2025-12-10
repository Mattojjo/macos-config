return {
  "lewis6991/gitsigns.nvim",
  config = function()
    require("gitsigns").setup({
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signcolumn = true,
      numhl = false,
      linehl = false,
      word_diff = false,
      watch_gitdir = {
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true,
      current_line_blame = false, -- Toggle with :Gitsigns toggle_current_line_blame
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 1000,
      },
      preview_config = {
        border = "rounded",
        style = "minimal",
      },
    })

    -- Keymaps
    vim.keymap.set("n", "]c", ":Gitsigns next_hunk<CR>", { silent = true })
    vim.keymap.set("n", "[c", ":Gitsigns prev_hunk<CR>", { silent = true })
    vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", { silent = true })
    vim.keymap.set("n", "<leader>gb", ":Gitsigns toggle_current_line_blame<CR>", { silent = true })
  end,
}
