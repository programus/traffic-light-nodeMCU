-- a wifi client
local _M = {}

_M.socket = nil

local function on_connection(sck, c)
  _M.socket = sck
  print('server connected.')
end

local function on_disconnection()
  _M.socket = nil
  print('disconnected.')
end

local function on_sent(sck, c)
  print('sent!')
end

local function connect_server(ip, port, cb_receive)
  print('connecting to server '..ip..':'..port..'...')
  local socket = net.createConnection(net.TCP, 0)
  socket:on('receive', cb_receive)
  socket:on('connection', on_connection)
  socket:on('reconnection', on_connection)
  socket:on('disconnection', on_disconnection)
  socket:on('sent', on_sent)
  socket:on('receive', cb_receive)
  socket:connect(port, ip)
end

function _M.connect_wifi_server(config)
  print('start config wifi...')
  wifi.setmode(wifi.STATION)
  wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(t)
    print('wifi '..t.SSID..' connected')
    if config.cb_connected then
      config.cb_connected(t)
    end
  end)
  wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(t)
    print('wifi '..(t.SSID or 'nil')..' disconnected: '..(t.reason or 'nil'))
    if config.cb_disconnected then
      config.cb_disconnected(t)
    end
  end)
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(t)
    print('got ip:'..t.IP..'/'..t.netmask..'/'..t.gateway)
    connect_server(config.server_ip, config.server_port, config.cb_receive)
  end)
  wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, function()
    print('dhcp timeout!')
  end)
  while (not wifi.sta.config({
    ssid = config.ssid,
    pwd = config.pwd,
    auto = true,
  })) do
    print('config wifi failed, retry...')
  end
  print('finished config wifi')
end

function _M.send(data)
  if _M.socket then
    print('send '..data)
    _M.socket:send(data)
  end
end

return _M

