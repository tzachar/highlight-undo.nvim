# highlight-undo.nvim

Highlight changed text after Undo / Redo operations. Purely lua / nvim api implementation,
no external dependencies needed.

# In Action

![recording](https://github.com/tzachar/highlight-undo.nvim/assets/4946827/81b85a3b-b563-4e97-b4e1-7a48d0d2f912)

# install

Using Lazy:

```lua
  {
      'tzachar/highlight-undo.nvim',
      config = function()
        require('highlight-undo').setup({
            ...
          })
      end
  },
```

# Setup

You can setup `highlight-undo` as follows:

```lua
require('highlight-undo').setup({
    hlgroup = 'HighlightUndo',
    duration = 300,
})
```

## `hlgroup`

Specify the highlighting group to use.

By default, `highlight-undo` will use the `HighlightUndo` highlight
group, which it defines upon startup. If the group is already defined
elsewhere in your config then it will not be overwritten. You can also
use any other group you desire.

## `duration`

The duration (in milliseconds) highligh changes. Default is 300.

# How the Plugin Works

`highlight-undo` will remap the `u` and `<C-r>` keys (for undo and redo) and
hijack the calls. By utilizing nvim_buf_attach to get indications for changes in the
buffer, we can achieve very low overhead.
