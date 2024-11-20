requirement:
- open firewall to allow IAP tcp-forwarding 35.235.240.0/20 port:3389
- open firewall to smtp smtp-allow port:587
- to passthrought vm to gmail open App password on your gmail account
    - open your google account -> security -> 2 step verification -> insert your password -> App passwords > insert name and save the password to using later for msmtp
- install msmtp
    - sudo apt update
    - sudo apt install -y msmtp
- nano ~/.msmtprc
    defaults
  
    auth           on
  
    tls            on
  
    tls_trust_file /etc/ssl/certs/ca-certificates.crt
  
    logfile        ~/.msmtp.log


    account default
  
    host smtp.gmail.com
  
    port 587
  
    from your_email@gmail.com
  
    user your_email@gmail.com
  
    password your_app_password
  
- chmod 600 ~/.msmtprc
- chmod +x send-email-notif.sh
- ./send-email-notif.sh

================================

for scheduler using this

crontab -e

#for auto update csv


0 0 * * * gcloud compute instances list --filters="status=RUNNING" --format="csv(name, zone)" > /path/datalabs-hs/config/instances_list.csv


#for auto RUNNING script(it's up to you)
* * * * * ./send-email-notif.sh 

