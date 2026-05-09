#!/usr/bin/env bash
set -euo pipefail

run_nvim() {
  local output status

  set +e
  output=$(nvim --headless "$@" 2>&1)
  status=$?
  set -e

  printf '%s' "$output"

  if [ "$status" -ne 0 ] || printf '%s' "$output" | grep -Eq '(^|[[:space:]])E[0-9]+:|assertion failed|^Error|Error detected|Error executing|stack traceback|attempt to (call|index)'; then
    return 1
  fi
}

run_nvim +'set noswapfile' +qa

run_nvim +'set noswapfile' \
  +'lua assert(package.loaded["preferences"]); assert(package.loaded["filetypes"]); print("startup modules ok")' \
  +qall!

run_nvim +'set noswapfile' \
  +'lua local plugins = require("lazy.core.config").plugins; assert(plugins["blink.cmp"]); assert(plugins["nvim-lspconfig"]); print("plugin specs ok")' \
  +qall!

run_nvim +'set noswapfile' \
  +'lua require("lazy").load({ plugins = { "blink.cmp" } }); assert(pcall(require, "blink.cmp")); print("blink loads ok")' \
  +qall!

run_nvim +'set noswapfile' \
  +'lua require("lazy").load({ plugins = { "blink.cmp" } }); local icons = require("blink.cmp.config").appearance.kind_icons; assert(type(icons.Class) == "string"); assert(type(icons.Function) == "string"); print("blink icons ok")' \
  +qall!

run_nvim +'set noswapfile' \
  +'enew' \
  +'file sample.py' \
  +'setfiletype python' \
  +'lua assert(vim.bo.filetype == "python"); assert(vim.bo.tabstop == 4); assert(vim.bo.shiftwidth == 4); assert(vim.bo.softtabstop == 4); assert(vim.bo.expandtab == true); assert(vim.bo.omnifunc == ""); print("python filetype ok")' \
  +qall!

run_nvim +'set noswapfile' \
  +'enew' \
  +'file sample.lua' \
  +'setfiletype lua' \
  +'lua assert(vim.bo.filetype == "lua"); assert(vim.bo.tabstop == 2); assert(vim.bo.shiftwidth == 2); assert(vim.bo.softtabstop == 2); assert(vim.bo.expandtab == true); assert(vim.bo.commentstring == "-- %s"); print("lua filetype ok")' \
  +qall!

run_nvim +'set noswapfile' \
  +'enew' \
  +'file sample.php' \
  +'setfiletype php' \
  +'lua assert(vim.bo.filetype == "php"); assert(vim.bo.omnifunc ~= ""); print("non-python omnifunc scope ok")' \
  +qall!

run_nvim +'set noswapfile' \
  +'lua local filetypes = require("filetypes"); filetypes.setup({ languages = { samplelang = { pattern = "samplelang", options = { tabstop = 7 } } } }); vim.cmd("enew"); vim.cmd("setfiletype samplelang"); assert(vim.bo.tabstop == 7); print("generic filetype registry ok")' \
  +qall!

run_nvim +'set noswapfile' \
  +'lua package.preload["test_filetype_module"] = function() return { setup = function(opts) vim.g.test_filetype_module_tabstop = opts.options.tabstop end } end; local filetypes = require("filetypes"); filetypes.setup({ defaults = { tabstop = 3 }, languages = { modulelang = { module = "test_filetype_module" }, disabledmodule = { enabled = false, module = "test_filetype_module", options = { tabstop = 9 } } } }); assert(vim.g.test_filetype_module_tabstop == 3); print("filetype module registry ok")' \
  +qall!

run_nvim +'set noswapfile' \
  +'lua local filetypes = require("filetypes"); filetypes.setup({ languages = { disabledlang = { enabled = false, options = { tabstop = 9 } } } }); vim.cmd("enew"); vim.cmd("setfiletype disabledlang"); assert(vim.bo.tabstop ~= 9); print("disabled filetype ok")' \
  +qall!

command -v basedpyright-langserver >/dev/null || {
  printf '%s\n' "FAIL: basedpyright-langserver is not on PATH"
  exit 1
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/pyproject.toml" <<'TOML'
[tool.basedpyright]
pythonVersion = "3.11"
TOML

cat > "$tmpdir/probe.py" <<'PY'
import asyncio
asyncio.T
PY

cat > "$tmpdir/assert_python_completion.lua" <<'LUA'
local file = assert(vim.env.PROBE_FILE, "PROBE_FILE unset")

vim.cmd.edit(vim.fn.fnameescape(file))
vim.cmd("setfiletype python")

local bufnr = vim.api.nvim_get_current_buf()
assert(vim.bo[bufnr].filetype == "python", "buffer is not python")

local function basedpyright_client()
  return vim.lsp.get_clients({ bufnr = bufnr, name = "basedpyright" })[1]
end

assert(vim.wait(15000, function()
  local client = basedpyright_client()
  return client and client.initialized
end, 50), "basedpyright did not attach and initialize")

local client = assert(basedpyright_client(), "basedpyright client disappeared")
assert(client:supports_method("textDocument/completion"), "basedpyright completion support missing")

assert(vim.bo[bufnr].omnifunc == "", "python omnifunc should stay disabled when LSP attaches")

local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
local target_line = #lines
local target_character = #lines[target_line]
vim.api.nvim_win_set_cursor(0, { target_line, target_character })

local params = {
  textDocument = { uri = vim.uri_from_bufnr(bufnr) },
  position = { line = target_line - 1, character = target_character },
  context = { triggerKind = 1 },
}

local response, err = client:request_sync("textDocument/completion", params, 10000, bufnr)
assert(response, "completion request failed: " .. tostring(err))
assert(not response.err, "completion LSP error: " .. vim.inspect(response.err))

local result = assert(response.result, "completion result was nil")
local items = result.items or result
assert(type(items) == "table" and #items > 0, "completion returned no items")

local labels = {}
local seen = {}
for _, item in ipairs(items) do
  if type(item.label) == "string" then
    table.insert(labels, item.label)
    seen[item.label] = true
  end
end

table.sort(labels)

assert(seen.Task, "missing asyncio completion label Task; labels=" .. table.concat(labels, ", "))
assert(seen.TaskGroup, "missing asyncio completion label TaskGroup; labels=" .. table.concat(labels, ", "))

print("python lsp completion ok")
LUA

PROBE_FILE="$tmpdir/probe.py" ASSERT_FILE="$tmpdir/assert_python_completion.lua" \
  run_nvim +'set noswapfile' +'lua dofile(vim.env.ASSERT_FILE)' +qall!
