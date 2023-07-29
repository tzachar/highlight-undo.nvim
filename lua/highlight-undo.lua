-- This module highlights reference usages and the corresponding
-- definition on cursor hold.

local api = vim.api

local M = {
  config = {
    hlgroup = 'HighlightUndo',
    undo_hlgroup = nil,
    redo_hlgroup = nil,
    duration = 300,
    keymaps = {
      { 'n', 'u', 'undo', {} },
      { 'n', '<C-r>', 'redo', {} },
    },
  },
  timer = (vim.uv or vim.loop).new_timer(),
  should_detach = true,
  current_hlgroup = nil,
}

local usage_namespace = api.nvim_create_namespace('highlight_undo')

function M.call_original_kemap(map)
  if type(map) == 'string' then
    vim.cmd(map)
  elseif type(map) == 'function' then
    map()
  end
end

function M.on_bytes(
  ignored, ---@diagnostic disable-line
  bufnr, ---@diagnostic disable-line
  changedtick, ---@diagnostic disable-line
  start_row, ---@diagnostic disable-line
  start_column, ---@diagnostic disable-line
  byte_offset, ---@diagnostic disable-line
  old_end_row, ---@diagnostic disable-line
  old_end_col, ---@diagnostic disable-line
  old_end_byte, ---@diagnostic disable-line
  new_end_row, ---@diagnostic disable-line
  new_end_col, ---@diagnostic disable-line
  new_end_byte ---@diagnostic disable-line
)
  if M.should_detach then
    return true
  end
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
  vim.schedule(function()
    vim.highlight.range(bufnr, usage_namespace, M.current_hlgroup, { start_row, start_column }, {
      start_row + new_end_row,
      start_column + new_end_col,
    })
    M.clear_highlights(bufnr)
  end)
  --detach
  -- return true
end

function M.highlight_undo(bufnr, hlgroup, command)
  M.current_hlgroup = hlgroup
  api.nvim_buf_attach(bufnr, false, {
    on_bytes = M.on_bytes,
  })
  M.should_detach = false
  command()
  M.should_detach = true
end

function M.clear_highlights(bufnr)
  M.timer:stop()
  M.timer:start(
    M.config.duration,
    0,
    vim.schedule_wrap(function()
      api.nvim_buf_clear_namespace(bufnr, usage_namespace, 0, -1)
    end)
  )
end

function M.setup(config)
  api.nvim_set_hl(0, 'HighlightUndo', {
    fg = '#dcd7ba',
    bg = '#2d4f67',
    default = true,
  })

  M.config = vim.tbl_deep_extend('keep', config or {}, M.config)

  local undo_mapping = M.config.keymaps[1]
  vim.keymap.set(undo_mapping[1], undo_mapping[2], function()
    M.highlight_undo(0, M.config.undo_hlgroup or M.config.hlgroup, function()
      M.call_original_kemap(undo_mapping[3])
    end)
  end, undo_mapping[4])

  local redo_mapping = M.config.keymaps[2]
  vim.keymap.set(redo_mapping[1], redo_mapping[2], function()
    M.highlight_undo(0, M.config.redo_hlgroup or M.config.hlgroup, function()
      M.call_original_kemap(redo_mapping[3])
    end)
  end, redo_mapping[4])
end

return M
