# highlight-undo.nvim

Highlight changed text after an action. Purely lua / nvim api implementation,
no external dependencies needed.

## In Action

![recording](https://github.com/tzachar/highlight-undo.nvim/assets/4946827/81b85a3b-b563-4e97-b4e1-7a48d0d2f912)

## Installation

Using Lazy:

```lua
  {
    'tzachar/highlight-undo.nvim',
    opts = {
      ...
    },
  },
```

## Setup

You can manually setup `highlight-undo` as follows:

```lua
require('highlight-undo').setup({
  highlight_for_count = true, -- Should '3p' or '5u' be highlighted
  duration = 300, -- Time in ms for the highlight
  after_keymaps = function() end, -- Any keymaps you might wanna add after the keymaps set by this plugin
  actions = {
    Undo = {
      disabled = false, -- Useful when debugging
        fg = "#dcd7ba", -- colors
        bg = "#2d4f67",
        mode = "n", -- The mode(s)
				keymap = "u", -- mapping
				cmd = "undo", -- Vim command
				opts = {}, -- silent = true, desc = "", ...
			},
    Redo = { keymap = "<C-r>", cmd = "redo" }, -- Actions can be made as easely as this
    Pasted = {
      keymap = "p",
      cmd = "put",
      cmd_args = function() -- This function needs to return a string as a parameter to cmd (or it can do stuff just after the command)
        return vim.v.register -- Return the register
      end,
    },
     -- Add any action you want
  },
})
```

## Keymaps

Specify which keymaps should trigger the beginning and end of tracking changes
([see here](#how-the-plugin-works)). By default, the plugin starts tracking
changes before an `undo` or a `redo` or anything you want.

Keymaps are specified in the same format as `vim.keymap.set` accepts: mode, keympa, cmd, opts. Maps are passed verbatim to `vim.keymap.set`.

## Highlighting

The hlgroup is created like this: "Highlight|action|" 
For example with the Pasted action: "HighlightPasted"

## `duration`

The duration (in milliseconds) to highlight changes. Default is 300.

## highlight_for_count

Enable support for highlighting when a `<count>` is provided before the key.
If set to `false` it will only highlight when the mapping is not prefixed with a
`<count>`.

Default: `true`

## How the Plugin Works

`highlight-undo` will remap the `u` and `<C-r>` keys (for undo and redo, by default) and
hijack the calls. By utilizing `nvim_buf_attach` to get indications for changes in the
buffer, the plugin can achieve very low overhead.
