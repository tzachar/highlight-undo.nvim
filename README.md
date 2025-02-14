# highlight-undo.nvim

Highlight changed text after any action not in insert mode which modifies the current buffer. This
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
        hlgroup = "HighlightUndo",
        duration = 300,
        pattern = {"*"},
        ignored_filetypes = { "neo-tree", "fugitive", "TelescopePrompt", "mason", "lazy" },
        -- ignore_cb is in comma as there is a default implementation. Setting
        -- to nil will mean no default os called.
        -- ignore_cb = nil,
    },
  },
```

## Setup

The easiest way to set up `highlight-undo` as follows:
```lua
require('highlight-undo').setup({})
```

## `hlgroup`

```lua
require('highlight-undo').setup({
    hlgroup = "HighlightUndo"
})
```

Specify the highlighting group to use. By default, `highlight-undo` will use `HighlightUndo`.

## `duration`

```lua
require('highlight-undo').setup({
    duration = 300
})
```

The duration (in milliseconds) to highlight changes. Default is 300.

## `pattern`

```lua
require('highlight-undo').setup({
    pattern = {"*"},
})
```

Which file patterns to atttach to. Default is everything (`*`).

## `ignored_filetypes`

```lua
require('highlight-undo').setup({
        ignored_filetypes = { "neo-tree", "fugitive", "TelescopePrompt", "mason", "lazy" },
})
```

Which file types to ignore, regardless of `patter`.

## `ignore_cb`

```lua
require('highlight-undo').setup({
        ignore_cb = function(buf) return false end,
})
```

You can also provide a callback function which is called when attaching to a new
buffer, which should return `true` if you want to disable `highlight-undo` on
this buffer.
The default callback rejects nomodifiable buffers and bufers whose file type is
`""`.
