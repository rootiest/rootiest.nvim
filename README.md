# rootiest.nvim

A Neovim plugin for various utilities and settings.

## Installation

Using `lazy.nvim`:

```lua
require("lazy").setup({
  {
    "rootiest/rootiest.nvim",
    config = function()
      require("rootiest").setup()
    end,
    dependencies = {
      "username/precognition.nvim",
      "username/hardtime.nvim",
      "username/toggleterm.nvim",
      "username/remote-nvim",
      "gen740/SmoothCursor.nvim" -- Optional: for cursor icons
    }
  }
})
```

## Usage

- **`:RestoreColorscheme`**: Restore the colorscheme.
- **`:Q`**: Close all buffers.
- **`:YankLine`**: Yank the current line without leading/trailing whitespace.
- **`:LoadRemote`**: Start the Remote plugin.

## Optional Dependencies

- **`SmoothCursor.nvim`**: Provides custom cursor icons.  
This plugin is optional but recommended for a better experience.  
If you have `SmoothCursor.nvim` installed,
the `set_cursor_icons` function in `rootiest` will configure custom cursor icons.

## License

MIT
