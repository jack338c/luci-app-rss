local e=require"luci.sys"
m=Map("shadowsocksr")
s = m:section(TypedSection, "lan_hosts", translate("LAN Hosts"))
s.template = "cbi/tblsection"
s.addremove = true
s.anonymous = true

o = s:option(Value, "host", translate("Host"))
luci.sys.net.arptable(function(x)
	o:value(x["IP address"], "%s (%s)" %{x["IP address"], x["HW address"]})
end)
o.datatype = "ip4addr"
o.rmempty = false

o = s:option(ListValue, "type", translate("Proxy Type"))

o:value("router", translate("大陆IP模式"))
o:value("gfw", translate("GFWList模式"))
o:value("global", translate("全局模式"))
o:value("gm", translate("游戏模式"))
o:value("disable", translate("停用"))

o.rmempty = false
o=s:option(Value,"ports",translate("Dest Ports"))
o.width="30%"
o.placeholder="80,443"



return m
