-- Copyright (C) 2017 yushi studio By Alx
-- Licensed to the public under the GNU General Public License v3.

module("luci.controller.shadowsocksr", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/shadowsocksr") then
		return
	end


               	entry({"admin", "services", "shadowsocksr"},alias("admin", "services", "shadowsocksr", "status"),_("ShadowSocksR"), 10).dependent = true
               	entry({"admin", "services", "shadowsocksr", "client"},arcombine(cbi("shadowsocksr/client"), cbi("shadowsocksr/client-config")),_("Basic settings"), 20).leaf = true
               	entry({"admin", "services", "shadowsocksr", "clientlist"},arcombine(cbi("shadowsocksr/clientlist"), cbi("shadowsocksr/client-config")),_("Client List"), 30).leaf = true
               	entry({"admin", "services", "shadowsocksr", "AccessControl"},arcombine(cbi("shadowsocksr/AccessControl"), cbi("shadowsocksr/client-config")),_("Access Control"), 80).leaf = true
               	entry({"admin", "services", "shadowsocksr", "gfwlist"},arcombine(cbi("shadowsocksr/gfwlist"), cbi("shadowsocksr/client-config")),_("规则列表"), 40).leaf = true
		entry({"admin","services","shadowsocksr","blacklist"},cbi("shadowsocksr/blacklist"),_("设置黑名单"),60).leaf=true
		entry({"admin","services","shadowsocksr","whitelist"},cbi("shadowsocksr/whitelist"),_("设置白名单"),70).leaf=true
		entry({"admin", "services", "shadowsocksr", "status"},cbi("shadowsocksr/status"),_("Status"), 10).leaf = true
		entry({"admin", "services", "shadowsocksr", "refresh"}, call("refresh_data"))
		entry({"admin", "services", "shadowsocksr", "checkport"}, call("check_port"))
		entry({"admin","services","shadowsocksr","china"},call("china_status")).leaf=true
		entry({"admin","services","shadowsocksr","foreign"},call("foreign_status")).leaf=true
	
end


function china_status()
local e={}
e.china=luci.sys.call("/usr/share/shadowsocksr/ssr-check www.baidu.com  80 3 1")==0
luci.http.prepare_content("application/json")
luci.http.write_json(e)
end
function foreign_status()
local e={}
e.foreign=luci.sys.call("/usr/share/shadowsocksr/ssr-check www.youtube.com  80 3 1")==0
luci.http.prepare_content("application/json")
luci.http.write_json(e)
end










function refresh_data()
local set =luci.http.formvalue("set")
local icount =0

if set == "gfw_data" then
      if nixio.fs.access("/usr/bin/wget-ssl") then
             refresh_cmd="wget-ssl --no-check-certificate https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt -O /tmp/gfw.b64"
      else
             refresh_cmd="wget -O /tmp/gfw.b64 http://iytc.net/tools/list.b64"
      end
      sret=luci.sys.call(refresh_cmd .. " 2>/dev/null")
      if sret== 0 then
             luci.sys.call("/usr/share/shadowsocksr/ssr-gfw")
             icount = luci.sys.exec("cat /tmp/gfwnew.txt | wc -l")
             if tonumber(icount)>1000 then
                     oldcount=luci.sys.exec("cat /etc/dnsmasq.d/gfwlist.conf | wc -l")
                     if tonumber(icount) ~= tonumber(oldcount) then
                            luci.sys.exec("cp -f /tmp/gfwnew.txt /etc/dnsmasq.d/gfwlist.conf")
                            retstring=tostring(math.ceil(tonumber(icount)/2))
                     else
                         retstring ="0"
                     end
             else
                   retstring ="-1"  
             end
             luci.sys.exec("rm -f /tmp/gfwnew.txt ")
       else
             retstring ="-1"
       end
elseif set == "ip_data" then
        
        sret=luci.sys.call("/usr/share/shadowsocksr/update_chinaroute.sh")
        icount = luci.sys.exec("cat /etc/ipset/china | wc -l")
	if   tonumber(icount)>1000 then
		oldcount=luci.sys.exec("cat /etc/ipset/china | wc -l")
		if tonumber(icount) ~= tonumber(oldcount) then
			retstring=tostring(tonumber(icount))
		else
			retstring ="0"
		end
        else
              retstring ="-1"
        end

       
end


luci.http.prepare_content("application/json")
luci.http.write_json({ ret=retstring ,retcount=icount})
end




function check_port()
local set=""
local retstring="<br /><br />"
local s
local server_name = ""
local shadowsocksr = "shadowsocksr"
local uci = luci.model.uci.cursor()
local iret=1

uci:foreach(shadowsocksr, "servers", function(s)

	if s.alias then
		server_name=s.alias
	elseif s.server and s.server_port then
		server_name= "%s:%s" %{s.server, s.server_port}
	end
	iret=luci.sys.call(" ipset add ss_spec_wan_ac " .. s.server .. " 2>/dev/null")
	socket = nixio.socket("inet", "stream")
	socket:setopt("socket", "rcvtimeo", 3)
	socket:setopt("socket", "sndtimeo", 3)
	ret=socket:connect(s.server,s.server_port)
	if  tostring(ret) == "true" then
	socket:close()
	retstring =retstring .. "<font color='green'>[" .. server_name .. "] OK.</font><br />"
	else
	retstring =retstring .. "<font color='red'>[" .. server_name .. "] Error.</font><br />"
	end	
	if  iret== 0 then
	luci.sys.call(" ipset del ss_spec_wan_ac " .. s.server)
	end
end)

luci.http.prepare_content("application/json")
luci.http.write_json({ ret=retstring })
end
