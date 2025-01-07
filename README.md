# highlight-undo.nvim

Highlight changed text after any action which modifies the current buffer. This
plugin was originaly written to support Undo / Redo highlighting, but is now
expanded to support any other action.

Purely lua / nvim api implementation, no external dependencies needed.

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

The easiest way to set up `highlight-undo` as follows:
```lua
require('highlight-undo').setup({})
```
The code above will set up `highlight-undo` to hijack `u`, `<C-r>`, `p` and `P`. To disable any of the defaults see [here](#keymaps)

You can also manually setup `highlight-undo` with specific / additional keymaps as follows:

```lua
require('highlight-undo').setup({
  duration = 300,
  keymaps = {
    Keymap_name = {
      -- most fields here are the same as in vim.keymap.set
      desc = "a description",
      hlgroup = 'HighlightUndo',
      mode = 'n',
      lhs = 'lhs',
      rhs = 'optional, can be nil',
      opts = {
        -- same as opts to vim.keymap.set. if rhs is nil, there should be a
        -- callback key which points to a function
      },
    },
  },
})
```

### Plugin Load Order

As this plugin hijacks kemaps, there might be issues with other plugin with
similar behavior. Make sure this plugin is loaded last. For example, using
`lazy.nvim`, you can just specify the following:


```lua
  {
    'tzachar/highlight-undo.nvim',
    keys = { { "u" }, { "<C-r>" } },
  }
```

## Keymaps

Specify which keymaps should trigger the beginning and end of tracking changes
([see here](#how-the-plugin-works)). By default, the plugin starts tracking
changes before and after the following keymaps:
* `u` -- for Undo
* `<C-r>` -- for Redo
* `p` -- for paste
* `P` -- for Paste

To disable any of the defaults, add a `disabled = true` entry to the appropriate
keymap. For example, to disable the default highlight for Paste:

```lua
require('highlight-undo').setup({
  keymaps = {
    Paste = {
        disabled = true,
    },
  },
})
```

Keymaps are specified in the same format as `vim.keymap.set` accepts: mode, lhs,
rhs, opts. Maps are passed verbatim to `vim.keymap.set`. A different possibility
is when you just want to hijack an existing keymap, you can then just specify
the `lhs` and `highligh-undo` will remap `lhs` and trigger the original action
afterwards.

For example, adding `p` (which exists by default), is as easy as:
```lua
require('highlight-undo').setup({
  keymaps = {
    paste = {
      desc = "paste",
      hlgroup = 'HighlightUndo',
      mode = 'n',
      lhs = 'p',
      rhs = 'p',
      opts = {},
    },
  },
})
```
Note that `lhs` and `rhs` are identical.

## `hlgroup`

Specify the highlighting group to use.

By default, `highlight-undo` will use `HighlightUndo` for the undo action and
`HighlightRedo` for the redo action. Both of these groups, are defined when the
plugin is loaded. If the groups are already defined elsewhere in your config
then they will not be overwritten. You can also use others groups, if desired.

## `duration`

The duration (in milliseconds) to highlight changes. Default is 300.

## How the Plugin Works

`highlight-undo` will remap the `u` and `<C-r>` keys (for undo and redo, by default) and
hijack the calls. By utilizing `nvim_buf_attach` to get indications for changes in the
buffer, the plugin can achieve very low overhead.
