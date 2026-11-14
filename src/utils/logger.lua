---@alias Severity "debug" | "info" | "warn" | "error"

---@type table<Severity, integer>
local severity_color = {
  debug = 0xffaaaaaa,
  info = 0xff77ff77,
  warn = 0xff77ffff,
  error = 0xff7777ff,
}

---@class Log
---@field severity Severity
---@field message string
---@field source? string
---@field count integer

---@class Logger
---@field private name? string
---@field private logs Log[]
---@field private head integer
---@field ui_filter table<Severity, boolean>
local Logger = {
  logs = {},
  head = 1,
  ui_filter = {
    debug = true,
    info = true,
    warn = true,
    error = true,
  }
} --[[@as Logger]]
Logger.__index = Logger

---@param name string
---@return nil
function Logger:set_name(name)
  self.name = name
end

---@param severity Severity
---@param message string
---@param source? string
---@return nil
function Logger:log(severity, message, source)
  local prev = self.logs[#self.logs]
  if prev
      and prev.severity == severity
      and prev.message == message
      and prev.source == source
  then
    prev.count = prev.count + 1
  else
    self.logs[#self.logs + 1] = {
      severity = severity,
      message = message,
      source = source,
      count = 1,
    }
  end
end

---@param id integer
---@return string?
function Logger:format_log(id)

end

---@return nil
function Logger:flush()
  if not log then return end
  if self.head > #self.logs then return end

  local name = self.name and string.format("[%s] ", self.name) or ""

  for i = self.head, #self.logs do
    local entry = self.logs[i]
    if entry.count > 1 then
      log[entry.severity](string.format("%s%dx %s", name, entry.count, entry.message))
    else
      log[entry.severity](string.format("%s%s", name, entry.message))
    end
  end
  self.head = #self.logs + 1
end

local log_box_size = imgui.calc_text_size(("a\n"):rep(10)).y

---@return nil
function Logger:on_draw_ui()
  if not imgui.collapsing_header("Logs") or #self.logs == 0 then return end

  if imgui.button("Copy to clipboard") then
    local res = ""
    for i = #self.logs, 1, -1 do
      local log = self.logs[i]
      if self.ui_filter[log.severity] then
        if log.count > 1 then
          res = res .. string.format("[%s] %dx %s\n", log.severity, log.count, log.message)
        else
          res = res .. string.format("[%s] %s\n", log.severity, log.message)
        end
      end
    end
    imgui.set_clipboard(res);
  end

  imgui.same_line()

  if imgui.button("Clear") then
    self.logs = {}
    self.head = 1
  end

  local filter = Logger.ui_filter
  for i, sev in ipairs({ "debug", "info", "warn", "error" }) do
    if i > 1 then
      imgui.same_line()
    end
    _, filter[sev] = imgui.checkbox(sev, filter[sev])
  end

  imgui.begin_rect()
  for i = #self.logs, math.max(1, #self.logs - 10), -1 do
    local log = self.logs[i]
    if self.ui_filter[log.severity] then
      imgui.text("[")
      imgui.same_line()
      imgui.text_colored(log.severity, severity_color[log.severity])
      imgui.same_line()
      imgui.text("] ")
      imgui.same_line()
      if log.count > 1 then
        imgui.text(string.format("%dx %s", log.count, log.message))
      else
        imgui.text(log.message)
      end
    end
  end
  imgui.end_rect(0, 0)
end

return Logger
