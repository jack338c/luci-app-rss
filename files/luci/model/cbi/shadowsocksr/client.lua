-- Copyright (C) 2017 yushi By Alx
-- Licensed to the public under the GNU General Public License v3.

local m, s,sec, o,kcp_enable
local shadowsocksr = "shadowsocksr"
local uci = luci.model.uci.cursor()
local ipkg = require("luci.model.ipkg")

local sys = require "luci.sys"

local gfwmode=0

local pdnsd_flag=0

local Pcap_Dns = 0

local dns2socks = 1




if nixio.fs.access("/usr/bin/dns2socks") then
	dns2sockss=1
end


if nixio.fs.access("/etc/config/pcap-dnsproxy") then
	Pcap_Dns=1
end

if nixio.fs.access("/etc/dnsmasq.d/gfwlist.conf") then
	gfwmode=1
end

if nixio.fs.access("/etc/pdnsd.conf") then
	pdnsd_flag=1
end

m = Map(shadowsocksr)
m.redirect = luci.dispatcher.build_url("admin/services/shadowsocksr/status")
local server_table = {}
local arp_table = luci.sys.net.arptable() or {}
local encrypt_methods = {
"none",
"rc4-md5",
"rc4-md5-6",
"aes-128-cfb",
"aes-192-cfb",
"aes-256-cfb",
"aes-128-ctr",
"aes-192-ctr",
"aes-256-ctr",
"bf-cfb",
"camellia-128-cfb",
"camellia-192-cfb",
"camellia-256-cfb",
"cast5-cfb",
"des-cfb",
"idea-cfb",
"rc2-cfb",
"seed-cfb",
"salsa20",
"chacha20",
"chacha20-ietf",

}

local protocol = {
"origin",
"verify_simple",
"auth_sha1_v4",
"auth_aes128_sha1",
"auth_aes128_md5",
"auth_chain_a",
}

obfs = {
"plain",
"http_simple",
"http_post",
"tls1.2_ticket_auth",
}


uci:foreach(shadowsocksr, "servers", function (s)
	if s.alias then
		server_table[s[".name"]] = s.alias
	elseif s.server and s.server_port then
		server_table[s[".name"]] = "%s:%s" %{s.server, s.server_port}
	end
end)




-- [[ Global Setting ]]--




s = m:section(TypedSection, "global", translate("Global Setting"))
s.anonymous = true

o = s:option(Flag, "enable_switch", translate("Auto Switch"))
o.rmempty = false


o = s:option(ListValue, "dalay_time", translate("延迟启动"))
o:value(0, translate("未启动"))
for _, v in ipairs({5, 10, 15, 25, 40}) do
	o:value(v, translate("%u 秒") %{v})
end
o.datatype = "uinteger"
o.default = 0
o.rmempty = false

o = s:option(ListValue, "global_server", translate("当前服务器"))
o:value("nil", translate("Disable"))
for k, v in pairs(server_table) do o:value(k, v) end
o.default = "nil"
o.rmempty = false

o = s:option(ListValue, "udp_relay_server", translate("UDP游戏服务器"))
o:value("", translate("Disable"))
o:value("same", translate("Same as Global Server"))
for k, v in pairs(server_table) do o:value(k, v) end








if gfwmode==0 then
	o = s:option(Flag, "tunnel_enable", translate("Enable Tunnel(DNS)"))
	o.default = 0
	o.rmempty = false
	o = s:option(Value, "tunnel_port", translate("Tunnel Port"))
	o.datatype = "port"
	o.default = 5300
	o.rmempty = false
else
	o = s:option(ListValue, "gfw_enable", translate("Operating mode"))
	o:value("router", translate("大陆IP模式"))
	o:value("gfw", translate("GFWList模式"))
	o:value("global", translate("全局模式"))
o:value("gm", translate("游戏模式"))
	o.rmempty = false
	o = s:option(ListValue, "dns_enable", translate("Resolve Dns Mode"))
	o:value("0", translate("ssr_tunnel"))
	
	
	
	
	
	if pdnsd_flag==1  then
		o:value("1", translate("pdnsd"))
	end
	
	if  Pcap_Dns == 1 then
		o:value("2", translate("pcap_Dnsproxy"))
	end
	if  dns2sockss == 1 then
		o:value("3", translate("dns2socks"))
	end
	
	o.rmempty = false
end

o = s:option(Value, "tunnel_forward", translate("DNS Server IP and Port"))
o.default = "8.8.4.4:53"
o.rmempty = false




return m


