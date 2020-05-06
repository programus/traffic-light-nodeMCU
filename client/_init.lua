-- all pins --
local LIGHTS = {
  p = 8,
  w = 2,
}

local BUTTON_PIN = 6

local WIFI_INDICATOR_PIN = 0

local client = require('client')

local function data_received(sck, data)
  print('received: '..data)
  for c in data:gmatch('.') do
    print('process: '..c)
    if c ~= 'x' then
      for light, pin in pairs(LIGHTS) do
        gpio.write(pin, light == c and gpio.HIGH or gpio.LOW)
      end
    end
  end
end

local function wifi_disconnected()
  gpio.write(WIFI_INDICATOR_PIN, gpio.LOW)
  data_received(nil, '-')
end

local function wifi_connected()
  gpio.write(WIFI_INDICATOR_PIN, gpio.HIGH)
end

local function button_pressed()
  print('button pressed.')
  client.send('x')
end

local function init_pins()
  for _, pin in pairs(LIGHTS) do
    gpio.mode(pin, gpio.OUTPUT)
    gpio.write(pin, gpio.LOW)
  end
  gpio.mode(WIFI_INDICATOR_PIN, gpio.OUTPUT)
  gpio.write(WIFI_INDICATOR_PIN, gpio.LOW)
  gpio.mode(BUTTON_PIN, gpio.INT, gpio.PULLUP)
  gpio.trig(BUTTON_PIN, 'down', button_pressed)
end

local function init_network()
  client.connect_wifi_server({
    ssid = 'traffic-light',
    pwd = 'traffic-light',
    server_ip = '192.168.20.1',
    server_port = 8080,
    cb_receive = data_received,
    cb_connected = wifi_connected,
    cb_disconnected = wifi_disconnected,
  })
end

local function main()
  init_pins()
  init_network()
end

main()
