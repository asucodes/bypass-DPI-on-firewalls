# Users first need to rent a VPS to their nearby location (for minimum latency), Digital Ocean preferred as AWS has high bandwith charges. A 2vCPU/2G ram with
# 2TB of bandwith is enough for our setup [can handle upto 20 users streaming and gaming smoothly]
# This guide is for Ubunity 22.02 distro, you can choose your preferred distro 

# first step on any new server is to make sure its software is fully up to date
sudo apt update && sudo apt upgrade -y

# get yourself a free domain from duckdns, this is crucial as many firewall block HTTPS data from unknown IPs, duckdns domain with a valid SSL is the fix!
#To get a valid ssl certificate for your website, we use certbot
sudo apt install nginx python3-certbot-nginx uuid-runtime -y

#Next install X-ray core, the engine that powers our VMess,Vless tunnel
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

#configure firewall on your server
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable

#get a ssl certificate using certbot
sudo certbot --nginx -d [your duck DNS domain here] 
#dont forget to connect your duckdns domain to your VPS's ipv4 address 

#generate credential
uuidgen

#open X ray config and edit it with your system details
sudo nano /usr/local/etc/xray/config.json

#a standard file layout is given below, incase you can't make your own:
{
  "inbounds": [
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "YOUR_UUID"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/my-secret-path"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
#pls ensure your change "/my-secret-path", replace UUID with the one generated with uuidgen above

#Configure Nginx as a Reverse Proxy
sudo nano /etc/nginx/sites-available/[your ducks dns url goes here]
# Add this new location block
    location /my-secret-path {
      if ($http_upgrade != "websocket") {
          return 404;
      }
      proxy_pass http://127.0.0.1:10001;
      proxy_redirect off;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    
    location / {
        # ... (certbot settings are probably in here)
    }
#change my-secret-path to your secret path and http://127.0.0.1:10001 with your VPS's IPv4
#test and restart
sudo nginx -t
#enable all services
sudo systemctl enable xray
sudo systemctl start xray
sudo systemctl restart nginx

------------------------------------------------------------------------------------------------------------




