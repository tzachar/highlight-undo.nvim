-- This module highlights reference usages and the corresponding
-- definition on cursor hold.

local api = vim.api

---makes undo action respect `foldopen=undo` (#18)
local function openFoldsOnUndo()
  if vim.tbl_contains(vim.opt.foldopen:get(), 'undo') then
    vim.cmd.normal({ 'zv', bang = true })
  end
end

local M = {
  config = {
    duration = 300,
    keymaps = {
      {
        fg = '#dcd7ba', -- default
        bg = '#2d4f67', -- default
        hlgroup = 'HighlightUndo', -- Set by "Highlight" .. opts.lhs
        mode = 'n', -- default
        lhs = 'u', -- Only thing that's mandatory here
        rhs = 'u', -- if not set rhs = lhs, can also be a function
        callback = function() -- do something after rhs
          openFoldsOnUndo()
        end,
        opts = { desc = 'HighlightUndo' }, -- opts to vim.keymap.set
      },
      {
        hlgroup = 'HighlightRedo',
        lhs = '<C-r>',
        callback = function()
          openFoldsOnUndo()
        end,
        opts = { desc = 'redo' },
      },
      { opts = { desc = 'paste' }, hlgroup = 'HighlightUndo', lhs = 'p' },
      { opts = { desc = 'Paste' }, hlgroup = 'HighlightUndo', lhs = 'P' },
      -- you also can add an action as simply as this:
      -- { lhs = 'p' }
    },
  },
  timer = (vim.uv or vim.loop).new_timer(),
  should_detach = true,
  current_hlgroup = nil,
}

local usage_namespace = api.nvim_create_namespace('highlight_undo')

---@diagnostic disable-next-line: unused-local
function M.on_bytes(ignored, bufnr, changedtick, start_row, start_column, byte_offset, old_end_row, old_end_col, old_end_byte, new_end_row, new_end_col, new_end_byte)
  -- dump(
  --   {
  --     ignored = ignored,
  --     bufnr = bufnr,
  --     changedtick = changedtick,
  --     start_row = start_row,
  --     start_column = start_column,
  --     byte_off = byte_offset,
  --     old_end_row = old_end_row,
  --     old_end_col = old_end_col,
  --     old_end_byte = old_end_byte,
  --     new_end_row = new_end_row,
  --     new_end_col = new_end_col,
  --     new_end_byte = new_end_byte,
  --   }
  -- )
  -- defer highligh till after changes take place..
  local num_lines = api.nvim_buf_line_count(0)
  local end_row = start_row + new_end_row
  local end_col = start_column + new_end_col
  if end_row >= num_lines then
    -- we are past the last line. highlight till the last column
    end_col = #api.nvim_buf_get_lines(0, -2, -1, false)[1]
  end
  vim.schedule(function()
    vim.highlight.range(bufnr, usage_namespace, M.current_hlgroup, { start_row, start_column }, { end_row, end_col })
    M.clear_highlights(bufnr)
  end)
  --detach
  -- return true
end

function M.highlight_actions(bufnr, hlgroup, command)
  M.current_hlgroup = hlgroup
  api.nvim_buf_attach(bufnr, false, {
    on_bytes = M.on_bytes,
  })
  M.should_detach = false
  for _ = 1, vim.v.count1 do
    command()
  end
end

function M.clear_highlights(bufnr)
  M.timer:stop()
  M.timer:start(
    M.config.duration,
    0,
    vim.schedule_wrap(function()
      api.nvim_buf_clear_namespace(bufnr, usage_namespace, 0, -1)
      M.should_detach = true
    end)
  )
end

function M.setup(config)
  M.config = vim.tbl_deep_extend('keep', config or {}, M.config)

  for _, opts in ipairs(M.config.keymaps) do
    if not opts.fg then
      opts.fg = '#dcd7ba'
    end

    if not opts.bg then
      opts.bg = '#2d4f67'
    end

    if not opts.hlgroup then
      opts.hlgroup = 'Highlight' .. opts.lhs
    end

    if not opts.mode then
      opts.mode = 'n'
    end

    if not opts.rhs then
      opts.rhs = opts.lhs
    end

    api.nvim_set_hl(0, opts.hlgroup, {
      fg = opts.fg,
      bg = opts.bg,
      default = true,
    })
    vim.keymap.set(opts.mode, opts.lhs, function()
      M.highlight_actions(0, opts.hlgroup, function()
        api.nvim_feedkeys(opts.rhs, opts.mode, false)
        if opts.callback then
          opts.callback()
        end
      end)
    end, opts.opts)
  end
end

return M
