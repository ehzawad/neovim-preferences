return {
  completion = {
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
  },
  lsp = {
    enabled = true,
    servers = {
      basedpyright = {
        enabled = true,
        cmd = { "basedpyright-langserver", "--stdio" },
        filetypes = { "python" },
        -- Neovim's LSP client sets omnifunc on attach; keep Python on blink.cmp's LSP source instead.
        buffer_options = {
          omnifunc = "",
        },
        root_markers = {
          "pyrightconfig.json",
          "pyproject.toml",
          "setup.py",
          "setup.cfg",
          "requirements.txt",
          "Pipfile",
          ".git",
        },
        settings = {
          python = {
            pythonPath = vim.fn.exepath("python3"),
          },
          basedpyright = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "openFilesOnly",
            },
          },
        },
      },
    },
  },
  filetypes = {
    defaults = {
      expandtab = true,
      smartindent = true,
      autoindent = true,
    },
    languages = {
      lua = {
        enabled = true,
        options = {
          tabstop = 2,
          shiftwidth = 2,
          softtabstop = 2,
          commentstring = "-- %s",
        },
      },
      python = {
        enabled = true,
        options = {
          tabstop = 4,
          shiftwidth = 4,
          softtabstop = 4,
          omnifunc = "",
        },
      },
    },
  },
}
