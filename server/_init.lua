-- all pins --
local LIGHTS = {
  R = 0,
  G = 1,
  r = 3,
  y = 4,
  g = 5,
}
local SOUND_PIN = 2
local SOUND_POWER = 8

local server = require('server')
local player = require('player')

local SOUNDS = {
  person = player:new('melody-long.u8.wav', SOUND_PIN, SOUND_POWER),
  road = player:new('melody.u8.wav', SOUND_PIN, SOUND_POWER),
}

local SOUNDS_LIST = {
  'person', 
  'road',
}

local PERSON_SOUND = player:new('melody-long.u8.wav', SOUND_PIN)
local ROAD_SOUND = player:new('melody.u8.wav', SOUND_PIN)

local current_tmr = tmr.create()
local current_state = nil

local function data_received(sck, data)
  print('received: '..data)
  if current_state then
    if current_state['interruptable'] then
      print('interrupt current state')
      if current_tmr:state() then
        current_tmr:interval(1)
      end
      server.send('w')
    elseif current_state['rc'] == 'x' then
      server.send('w')
    end
  end
end

local function client_connected(sck, data)
  if current_state then
    local rc = current_state['rc'] or 'w'
    print('send signal to control on connected: '..rc)
    sck:send(rc)
  end
end

local function init_pins()
  for _, pin in pairs(LIGHTS) do
    gpio.mode(pin, gpio.OUTPUT)
    gpio.write(pin, gpio.LOW)
  end
end

local function init_network()
  server.start_wifi('traffic-light', 'traffic-light', '192.168.20.1')
  server.start_server(8080, data_received, client_connected)
end

local function set_lights(lights, value)
  for c in lights:gmatch('.') do
    gpio.write(LIGHTS[c], value)
  end
end

local function set_sounds(sound)
  for key, sound_player in pairs(SOUNDS) do
    if key == sound then
      if not sound_player.isPlaying then
        sound_player:play()
      end
    elseif sound_player.isPlaying then
        sound_player:stop()
    end
  end
end

local function process_states(states, index)
  index = index or 1
  local state = states[index]
  current_state = state

  print('=====================')
  print('start '..state['name'])
  print('send signal to control: '..(state['rc'] or 'nil'))
  if state['rc'] then
    server.send(state['rc'])
  end
  local sound = state['sound']
  if sound == 'random' then
    sound = SOUNDS_LIST[tmr.now() % 2 + 1]
  end
  print('play/stop sound: '..(sound or 'nil'))
  set_sounds(sound)
  print('turn off lights: '..state['off_lights'])
  set_lights(state['off_lights'], gpio.LOW)
  local on_time = state['on_time']
  local on_lights = state['on_lights']
  local next_index = index % #states + 1
  local callback = function()
    process_states(states, next_index)
  end
  if type(on_time) == 'number' then
    print('turn on lights: '..on_lights)
    set_lights(on_lights, gpio.HIGH)
    local next = index % #states + 1
    current_tmr:alarm(on_time, tmr.ALARM_SINGLE, callback)
  else
    print('blink on lights: '..on_lights)
    for i = 1, #on_lights do
      local c = on_lights:sub(i, i)
      gpio.serout(LIGHTS[c], gpio.LOW, on_time, state['cycle'], i == #on_lights and callback or function() end)
    end
  end
end

local function main()
  init_network()
  init_pins()
  
  local states = {
    {name='g_int', on_lights='gR', off_lights='ryG', on_time=20000, rc='p', interruptable=true, sound=nil},
    {name='g', on_lights='gR', off_lights='', on_time=5000, rc='x', interruptable=false, sound=nil},
--    {name='g_blink', on_lights='g', off_lights='', on_time={500000, 500000}, cycle=6, rc='w', interruptable=false, sound=nil},
    {name='y', on_lights='y', off_lights='g', on_time=3000, rc='w', interruptable=false, sound=nil},
    {name='G', on_lights='rG', off_lights='yR', on_time=25000, rc='-', interruptable=false, sound='random'},
    {name='G_blink', on_lights='G', off_lights='', on_time={500000, 500000}, cycle=6, rc='-', interruptable=false, sound=nil},
  }

  process_states(states)
end

main()
