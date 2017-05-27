#!/bin/sh
wget-ssl --no-check-certificate https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt -O /tmp/gfw.b64
 if [ "$?" == "0" ]; then
         /usr/share/shadowsocksr/ssr-gfw
         icunt=$(cat /tmp/gfwnew.txt | wc -l)
         icunt1=$(cat /etc/dnsmasq.d/gfwlist.conf | wc -l)
              if [ "$icunt" != "$icunt1" ];then
                           cp -f /tmp/gfwnew.txt /etc/dnsmasq.d/gfwlist.conf
              fi
fi
rm -rf  /tmp/gfwnew.txt
rm -rf  /tmp/gfw.b64
