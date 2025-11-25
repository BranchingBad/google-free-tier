#!/bin/bash
sudo /tmp/2-host-setup/1-create-swap.sh
sudo /tmp/2-host-setup/2-install-nginx.sh
sudo /tmp/2-host-setup/3-setup-duckdns.sh ${domain_name} ${duckdns_token}
sudo /tmp/2-host-setup/4-setup-ssl.sh ${domain_name} ${email_address}
sudo /tmp/2-host-setup/5-adjust-firewall.sh
sudo /tmp/2-host-setup/6-setup-backups.sh ${gcs_bucket_name} ${backup_dir}