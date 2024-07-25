# rootiest.nvim

`rootiest.nvim` is a Neovim plugin designed to enhance your editing experience
with several useful utilities and configurations.

## Features

- Manage and restore colorschemes
- Various utility functions like yanking lines without whitespace,
checking terminal type, etc.
- Support for Neovide and additional plugins like precognition and hardtime

## Installation

Using `lazy.nvim`, add the plugin to your configuration:

```lua
require("lazy").setup({
    {
        "rootiest/rootiest.nvim",
    },
})
```

## Configuration

You can configure the `rootiest` plugin by passing a table of options to `require("rootiest").setup()`.

### Default Values

The default values for `rootiest` configuration are:

```lua
local config = {
    colorscheme = "default", -- Default colorscheme
}
```

### Example Configuration

To manually set all default values (though they are already set by default),
use the following `lazy.nvim` configuration:

```lua
require("lazy").setup({
    {
        "rootiest/rootiest.nvim",
        config = function()
            require("rootiest").setup({
                colorscheme = "default", -- Specify your preferred colorscheme here
            })
        end,
    },
})
```

## Commands

- **`:SetColorscheme <name>`**: Set the colorscheme and save it to the settings file.
- **`:RestoreColorscheme`**: Restore the colorscheme from the settings file.

## Autocommands

- **ColorScheme**: Automatically updates the colorscheme in the settings file
when the colorscheme changes.

## License

`rootiest.nvim` is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please open an issue or
submit a pull request to the [GitHub repository](https://github.com/rootiest/rootiest.nvim).
