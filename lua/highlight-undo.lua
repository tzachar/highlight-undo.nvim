local api = vim.api
Object = require("classic")

Tracker = Object:extend()

function Tracker:new(config, buf)
  self.timer = (vim.uv or vim.loop).new_timer()
  self.should_detach = true
  self.buf = buf
  self.config = config
end

local config = {
  duration = 300,
  hlgroup = "HighlightUndo",
  pattern = { "*" },
  ignored_filetypes = { "neo-tree", "fugitive", " TelescopePrompt" },
  ignore_cb = nil,
}

local buffers = {}

local function attach(buf)
  local cache = buffers[buf]
  if cache ~= nil then
    return cache
  end
  buffers[buf] = Tracker(config, buf)
  return buffers[buf]
end

local usage_namespace = api.nvim_create_namespace('highlight_undo')

function Tracker:on_bytes(
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
  if self.should_detach then
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
    (vim.hl or vim.highlight).range(
      bufnr,
      usage_namespace,
      self.config.hlgroup,
      { start_row, start_column },
      { end_row, end_col }
    )
    self:clear_highlights()
  end)
end

function Tracker:highlight_undo()
  self.timer:stop()
  self.should_detach = false
  api.nvim_buf_attach(self.buf, false, {
    on_bytes = function (...) self:on_bytes(...) end,
  })
  vim.schedule(function()
    self:clear_highlights()
  end)
end

function Tracker:clear_highlights()
  self.timer:stop()
  self.timer:start(
    self.config.duration,
    0,
    vim.schedule_wrap(function()
      if vim.api.nvim_buf_is_valid(self.buf) then
        api.nvim_buf_clear_namespace(self.buf, usage_namespace, 0, -1)
      end
    end)
  )
end

local M = {}
function M.setup(cfg)
  api.nvim_set_hl(0, 'HighlightUndo', {
    fg = '#dcd7ba',
    bg = '#2d4f67',
    default = true,
  })

  config = vim.tbl_deep_extend('keep', cfg or {}, config)
  vim.api.nvim_create_autocmd({ "InsertLeave", "BufEnter" }, {
    pattern = config.pattern or { "*" },
    callback = function(ev)
      local buf = ev.buf
      local ft = api.nvim_get_option_value("filetype", {buf = buf})
      if ((not vim.tbl_contains(config.ignored_filetypes, ft))
        and not (config.ignore_cb and config.ignore_cb(buf))
      ) then
        local tracker = attach(buf)
        tracker:highlight_undo()
      end
    end
  })
  vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave" }, {
    pattern = { "*" },
    callback = function(ev)
      local buf = ev.buf
      local ft = api.nvim_get_option_value("filetype", {buf = buf})
      if ((not vim.tbl_contains(config.ignored_filetypes, ft))
        and not (config.ignore_cb and config.ignore_cb(buf))
      ) then
        local tracker = attach(buf)
        tracker.should_detach = true
      end
    end
  })

  -- see if we need to cancel after filetype has been set!
  -- this is a race condition with the previous autocommands
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "*" },
    callback = function(ev)
      local buf = ev.buf
      local ft = api.nvim_get_option_value("filetype", {buf = buf})
      if vim.tbl_contains(config.ignored_filetypes, ft)
        or (config.ignore_cb and config.ignore_cb(buf)
      ) then
        local tracker = attach(buf)
        tracker.should_detach = true
      end
    end
  })
end

return M
