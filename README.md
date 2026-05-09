#### Ehza's neovim preferences

```bash
git clone git@github.com:ehzawad/neovim-preferences.git ~/.config/nvim
```

### Configuration

Language-specific behavior is configured from `lua/preferences/init.lua`.
Filetype options are loaded through `lua/filetypes/init.lua`, completion through
`lua/plugins/completion.lua`, and language servers through `lua/plugins/lsp.lua`
and `lua/lsp/init.lua`.

Generic filetype settings only need an entry in `filetypes.languages`. Use a
dedicated module only when a language needs custom Lua behavior beyond setting
buffer-local options.

Completion is handled by `blink.cmp`; Python semantic completion goes through
`blink.cmp`'s `lsp` source backed by `basedpyright` and Neovim's native LSP
APIs. Python keeps Vim's old Python `omnifunc` disabled, so `<C-x><C-o>` is not
the Python completion path.

Completion kind icons use Nerd Font glyphs from `blink.cmp`, so configure your
terminal profile to use a Nerd Font such as `JetBrainsMono Nerd Font Mono`.

Defaults under `filetypes.defaults` are shared by every configured language and
can be overridden per language from `filetypes.languages`.

Run the config checks with:

```bash
./scripts/test_nvim_config.sh
```
