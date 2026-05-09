local preferences = require("preferences")

local function configured_filetypes(lsp_preferences)
  local filetypes = {}

  for _, server in pairs(lsp_preferences.servers or {}) do
    if server.enabled ~= false then
      for _, filetype in ipairs(server.filetypes or {}) do
        filetypes[filetype] = true
      end
    end
  end

  local result = {}
  for filetype in pairs(filetypes) do
    table.insert(result, filetype)
  end

  table.sort(result)
  return result
end

local lsp_preferences = preferences.lsp or {}

if lsp_preferences.enabled == false then
  return {}
end

return {
  {
    "neovim/nvim-lspconfig",
    ft = configured_filetypes(lsp_preferences),
    dependencies = {
      "saghen/blink.cmp",
    },
    config = function()
      require("lsp").setup(lsp_preferences)
    end,
  },
}
