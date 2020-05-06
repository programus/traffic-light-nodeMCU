-- a sound player
local _M = {}

local function cb_drained(d, fd)
  print("drained "..node.heap())
  fd:seek('set', 0)
  d:play(pcm.RATE_8K)
end

local function cb_stopped(d, fd)
  print("playback stopped")
  fd:seek('set', 0)
end

local function cb_paused(d, fd)
  print("playback paused")
end

local function cb_data(d, fd)
  return fd:read()
end

function _M:new(file_name, pin, power_pin, rate)
  local fd = file.open(file_name, 'r')
  local drv = pcm.new(pcm.SD, pin)
  if power_pin then
    gpio.mode(power_pin, gpio.OUTPUT)
    gpio.write(power_pin, gpio.LOW)
  end

  -- fetch data in chunks of LUA_BUFFERSIZE (1024) from file
  drv:on("data", function (d) return cb_data(d, fd) end)

  -- get called back when all samples were read from the file
  drv:on("drained", function (d) cb_drained(d, fd) end)

  drv:on("stopped", function (d) cb_stopped(d, fd) end)
  drv:on("paused", function (d) cb_paused(d, fd) end)

  newObj = {
    file_name = file_name,
    __drv = drv,
    __rate = rate or pcm.RATE_8K,
    power_pin = power_pin, 
    isPlaying = false,
  }

  self.__index = self

  return setmetatable(newObj, self)
end

function _M:play()
  print('start playing '..self.file_name)
  if self.power_pin then
    gpio.write(self.power_pin, gpio.HIGH)
  end
  self.__drv:play(self.__rate)
  self.isPlaying = true
end

function _M:stop()
  print('stop playing '..self.file_name)
  if self.power_pin then
    gpio.write(self.power_pin, gpio.LOW)
  end
  self.__drv:stop()
  self.isPlaying = false
end

function _M:pause()
  print('pause playing '..self.file_name)
  if self.power_pin then
    gpio.write(self.power_pin, gpio.LOW)
  end
  self.__drv:pause()
  self.isPlaying = false
end

return _M

