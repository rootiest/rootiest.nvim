# rootiest.nvim

A Neovim plugin for various utilities and settings.

**This plugin is in early development.**

It is intended to provide additional refinements on top of the LazyVim distribution.

## Installation

Using `lazy.nvim`:

```lua
require("lazy").setup({
  {
    "rootiest/rootiest.nvim",
    config = true,
  }
})
```

## Usage

- **`:RestoreColorscheme`**: Restore the colorscheme. (executed at startup)
- **`:Q`**: Close all buffers.
- **`:YankLine`**: Yank the current line without leading/trailing whitespace.
- **`:LoadRemote`**: Start the nvim-remote plugin.

## Optional Dependencies

- **`SmoothCursor.nvim`**: Provides custom cursor icons.  
  This plugin is optional but recommended for a better experience.  
  If you have `SmoothCursor.nvim` installed,
  the `set_cursor_icons` function in `rootiest` will configure custom cursor icons.

## License

MIT
