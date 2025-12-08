return {
  "loctvl842/monokai-pro.nvim",
  config = function()
    require("monokai-pro").setup({
      filter = "machine", -- << this sets the Machine variant
    })

    vim.cmd("colorscheme monokai-pro")
  end
}
