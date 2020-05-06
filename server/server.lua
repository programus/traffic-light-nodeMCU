-- a wifi server
local _M = {}

_M.socket = nil

function _M.start_wifi(ssid, pwd, ip)
  wifi.setmode(wifi.SOFTAP)
  while (not wifi.ap.config({
    ssid = ssid,
    pwd = pwd,
  })) do end
  while (not wifi.ap.setip({
    ip = ip,
    netmask = '255.255.255.0',
    gateway = ip,
  })) do end
  while (not wifi.ap.dhcp.start()) do end
  wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
    print("\n\tAP - STATION CONNECTED".."\n\tMAC: "..T.MAC.."\n\tAID: "..T.AID)
  end)
  print('wifi started.')
end

local function on_connection(sck, c)
  _M.socket = sck
  print('connected.')
end

local function on_disconnection()
  _M.socket = nil
  print('disconnected.')
end

local function on_sent(sck, c)
  print('sent!')
end

function _M.start_server(port, cb_receive, cb_connection)
  local socket = net.createServer(net.TCP)
  socket:listen(port, function(conn)
    conn:on('receive', cb_receive)
    conn:on('connection', function(sck, c)
      on_connection(sck, c)
      print(cb_connection)
      if cb_connection then
        print('call external callback')
        cb_connection(sck, c)
      end
    end)
    conn:on('reconnection', on_connection)
    conn:on('disconnection', on_disconnection)
    conn:on('sent', on_sent)
  end)
  print('server started at '..port)
end

function _M.send(data)
  if _M.socket then
    print('send '..data)
    _M.socket:send(data)
  end
end

return _M

