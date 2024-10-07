-- This module highlights reference usages and the corresponding
-- definition on cursor hold.

local api = vim.api

---makes highlight-undo respect `foldopen=undo` (#18)
local function openFoldsOnUndo()
  if vim.tbl_contains(vim.opt.foldopen:get(), "undo") then
    vim.cmd.normal({"zv", bang = true})
  end
end

local M = {
  config = {
    duration = 300,
    keymaps = {
      undo = {
        desc = "undo",
        hlgroup = 'HighlightUndo',
        mode = 'n',
        lhs = 'u',
        rhs = nil,
        opts = {
          callback = function ()
            vim.cmd('undo')
            openFoldsOnUndo()
          end,
        },
      },
      redo = {
        desc = "redo",
        hlgroup = 'HighlightRedo',
        mode = 'n',
        lhs = '<C-r>',
        rhs = nil,
        opts = {
          callback = function ()
            vim.cmd('redo')
            openFoldsOnUndo()
          end,
        },
      },
      paste = {
        desc = "paste",
        hlgroup = 'HighlightUndo',
        mode = 'n',
        lhs = 'p',
        rhs = 'p',
        opts = {},
      },
      Paste = {
        desc = "Paste",
        hlgroup = 'HighlightUndo',
        mode = 'n',
        lhs = 'P',
        rhs = 'P',
        opts = {},
      },
    },
  },
  timer = (vim.uv or vim.loop).new_timer(),
  should_detach = true,
  current_hlgroup = nil,
}

local usage_namespace = api.nvim_create_namespace('highlight_undo')

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
  -- defer highligh till after changes take place..
  local num_lines = api.nvim_buf_line_count(0)
  local end_row = start_row + new_end_row
  local end_col = start_column + new_end_col
  if end_row >= num_lines then
    -- we are past the last line. highligh till the last column
    end_col = #api.nvim_buf_get_lines(0, -2, -1, false)[1]
  end
  vim.schedule(function()
    vim.highlight.range(
      bufnr,
      usage_namespace,
      M.current_hlgroup,
      { start_row, start_column },
      { end_row, end_col}
    )
  end)
end

function M.highlight_undo(bufnr, hlgroup, command)
  M.timer:stop()
  M.current_hlgroup = hlgroup
  M.should_detach = false
  api.nvim_buf_attach(bufnr, false, {
    on_bytes = M.on_bytes,
  })
  for _ = 1, vim.v.count1 do
    command()
  end
  vim.schedule(function()
    M.clear_highlights(bufnr)
  end)
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

local function hijack(opts, org_mapping)
  opts.opts["noremap"] = true
  local callback = function()
    M.highlight_undo(0, opts.hlgroup, function()
      if org_mapping and not vim.tbl_isempty(org_mapping) then
        if org_mapping.callback then
          org_mapping.callback()
          -- if the original mapping was also hijacking calls (for example,
          -- which-key.nvim) make sure to recapture the mapping
          -- we assume that the actual mapping will be present after the
          -- first invcation
          local new_mapping = vim.fn.maparg(opts.lhs, opts.mode, false, true)
          if not vim.deep_equal(new_mapping, org_mapping.callback) then
            hijack(opts, new_mapping)
          end
        elseif org_mapping.rhs then
          local keys = vim.api.nvim_replace_termcodes(org_mapping.rhs, true, false, true)
          vim.api.nvim_feedkeys(keys, org_mapping.mode, false)
        end
      elseif opts.rhs and type(opts.rhs) == "string" then
        local keys = vim.api.nvim_replace_termcodes(opts.rhs, true, false, true)
        vim.api.nvim_feedkeys(keys, opts.mode, false)
      elseif opts.command and type(opts.command) == "string" then
        vim.cmd(opts.command)
      elseif opts.opts.callback then
        opts.opts.callback()
      end
    end)
  end
  vim.keymap.set(opts.mode, opts.lhs, callback, opts.opts)
end

function M.setup(config)
  api.nvim_set_hl(0, 'HighlightUndo', {
    fg = '#dcd7ba',
    bg = '#2d4f67',
    default = true,
  })
  api.nvim_set_hl(0, 'HighlightRedo', {
    fg = '#dcd7ba',
    bg = '#2d4f67',
    default = true,
  })

  M.config = vim.tbl_deep_extend('keep', config or {}, M.config)
  for _, opts in pairs(M.config.keymaps) do
    if not opts.disabled then
      local org_mapping = vim.fn.maparg(opts.lhs, opts.mode, false, true)
      hijack(opts, org_mapping)
    end
  end
end

return M
