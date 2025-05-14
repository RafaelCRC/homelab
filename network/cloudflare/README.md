install both crontab and logrotate

/cloudflare/ ___ script.sh
             |_ logs/

/etc/logrotate.d/flare_log


crontab -e

0 2 * * * /cloudflare/flareipupdate.sh >> /cloudflare/logs/flarelog.log 2>&1

sudo systemctl status cron

sudo systemctl start cron
 
sudo systemctl enable cron


create flare_log

```
/cloudflare/logs/flarelog.log {
    daily                 
    rotate 7       
    compress            
    missingok            
    notifempty          
    create 0644 root root 
    dateext              
}
```

sudo systemctl status logrotate.timer

sudo systemctl enable --now logrotate.timer
