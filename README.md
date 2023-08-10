# highlight-undo.nvim

Highlight changed text after Undo / Redo operations. Purely lua / nvim api implementation,
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
  duration = 300,
  undo = {
    hlgroup = 'HighlightUndo',
    mode = 'n',
    lhs = 'u',
    map = 'undo',
    opts = {}
  },
  redo = {
    hlgroup = 'HighlightUndo',
    mode = 'n',
    lhs = '<C-r>',
    map = 'redo',
    opts = {}
  },
})
```

## Keymaps

Specify which keymaps should trigger the beginning and end of tracking changes
([see here](#how-the-plugin-works)). By default, the plugin starts tracking
changes before an `undo` or a `redo`.

Keymaps are specified in the same format as `vim.keymap.set` accepts: mode, lhs,
rhs, opts. Maps are passed verbatim to `vim.keymap.set`.

## `hlgroup`

Specify the highlighting group to use.

By default, `highlight-undo` will use the `HighlightUndo` highlight
group, which it defines upon startup. If the group is already defined
elsewhere in your config then it will not be overwritten. You can also
use any other group you desire.

## `duration`

The duration (in milliseconds) to highlight changes. Default is 300.

## How the Plugin Works

`highlight-undo` will remap the `u` and `<C-r>` keys (for undo and redo, by default) and
hijack the calls. By utilizing `nvim_buf_attach` to get indications for changes in the
buffer, the plugin can achieve very low overhead.
