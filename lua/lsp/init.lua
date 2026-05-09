local M = {}

local defaults = {
  enabled = true,
  servers = {},
}

local internal_keys = {
  buffer_options = true,
  enabled = true,
  merge_capabilities = true,
  notify_missing = true,
}

local function executable_from_cmd(cmd)
  if type(cmd) == "table" then
    return cmd[1]
  end

  if type(cmd) == "string" then
    return cmd
  end
end

local function command_is_available(cmd)
  local executable = executable_from_cmd(cmd)
  return not executable or vim.fn.executable(executable) == 1
end

local function lsp_config_from(server)
  local config = {}

  for key, value in pairs(server) do
    if not internal_keys[key] then
      config[key] = value
    end
  end

  return config
end

local function capabilities_for(server)
  local capabilities = server.capabilities or vim.lsp.protocol.make_client_capabilities()
  local ok, blink = pcall(require, "blink.cmp")

  if ok then
    return blink.get_lsp_capabilities(capabilities)
  end

  return capabilities
end

local function setup_server(name, server)
  if server.enabled == false then
    return
  end

  if not command_is_available(server.cmd) then
    if server.notify_missing ~= false then
      local executable = executable_from_cmd(server.cmd)
      vim.notify(string.format("LSP server '%s' is disabled because '%s' is not on PATH", name, executable), vim.log.levels.WARN)
    end
    return
  end

  local config = lsp_config_from(server)
  local on_attach = config.on_attach

  config.on_attach = function(client, bufnr)
    for option, value in pairs(server.buffer_options or {}) do
      vim.bo[bufnr][option] = value
    end

    if type(on_attach) == "function" then
      on_attach(client, bufnr)
    end
  end

  if server.merge_capabilities ~= false then
    config.capabilities = capabilities_for(server)
  end

  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end

function M.setup(opts)
  local options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  if options.enabled == false then
    return
  end

  for name, server in pairs(options.servers or {}) do
    setup_server(name, server)
  end
end

return M
