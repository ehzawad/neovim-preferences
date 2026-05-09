local preferences = require("preferences")

local defaults = {
  enabled = true,
  keymap_preset = "default",
  nerd_font_variant = "mono",
  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 250,
    },
    ghost_text = {
      enabled = true,
    },
  },
  signature = {
    enabled = true,
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },
}

local completion = vim.tbl_deep_extend("force", defaults, preferences.completion or {})

if completion.enabled == false then
  return {}
end

return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    opts = {
      keymap = {
        preset = completion.keymap_preset,
      },
      appearance = {
        nerd_font_variant = completion.nerd_font_variant,
      },
      completion = completion.completion,
      signature = completion.signature,
      sources = completion.sources,
      fuzzy = completion.fuzzy,
    },
    opts_extend = { "sources.default" },
  },
}
