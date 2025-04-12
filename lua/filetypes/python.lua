return {
  setup = function()
    -- Create filetype-specific autocmd
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "python",
      callback = function()
        -- Tab settings specific to Lua files
        vim.bo.tabstop = 2
        vim.bo.shiftwidth = 2
        vim.bo.expandtab = true
        vim.bo.softtabstop = 2
        
        -- Important indentation settings
        vim.bo.smartindent = true
        vim.bo.autoindent = true
      end,
    })
  end
}
