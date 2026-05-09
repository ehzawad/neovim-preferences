local M = {}

local defaults = {
  defaults = {},
  languages = {},
}

local function apply_buffer_options(bufnr, options)
  for name, value in pairs(options or {}) do
    vim.bo[bufnr][name] = value
  end
end

local function register_filetype(name, opts)
  if opts.enabled == false then
    return
  end

  local pattern = opts.pattern or name
  local group = vim.api.nvim_create_augroup("UserFiletypeSettings" .. name:gsub("[^%w]", "_"), {
    clear = true,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = pattern,
    callback = function(event)
      apply_buffer_options(event.buf, opts.options)

      if type(opts.on_filetype) == "function" then
        opts.on_filetype(event, opts)
      end
    end,
  })
end

function M.setup(opts)
  local options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  for name, language_options in pairs(options.languages or {}) do
    local merged = vim.tbl_deep_extend("force", {
      options = vim.deepcopy(options.defaults or {}),
    }, language_options)

    if merged.enabled ~= false then
      if merged.module then
        local ok, module = pcall(require, merged.module)

        if not ok then
          vim.notify(string.format("Failed to load filetype module '%s': %s", merged.module, module), vim.log.levels.WARN)
        elseif type(module.setup) ~= "function" then
          vim.notify(string.format("Filetype module '%s' does not expose setup()", merged.module), vim.log.levels.WARN)
        else
          module.setup(merged)
        end
      else
        register_filetype(name, merged)
      end
    end
  end

  return options
end

return M
