#!/bin/bash

## custom_check_reboot_needed_via_ssh.sh
## version 0.1
## Check if a reboot is needed after installing updates.
## Currently only supports Ubuntu
## probably works perfectly on all Ubuntu dirivitives or really anything with the "update-notifier-common" package installed
## added some guess work for all other *Nix machines that probably won't break anything.



sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cat /etc/*release")
distro=$(echo "$sshOutput" | grep NAME= | cut -d'=' -f2)
distroLike=$(echo "$sshOutput" | grep ID_LIKE= | cut -d'=' -f2)



## Thanks to Adam Crume for the following line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable
sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "compgen -G /etc/*release" > /dev/null) 2>&1 )




if [ -z "$sshError" ] ; then
        if echo "$distro" | grep -i ubuntu > /dev/null ; then
                if ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cat /run/reboot-required*" 2>/dev/null; then
                        exit 1
                else
                        echo no reboot required
                        exit 0
                fi
        fi

        if echo "$distroLike" | grep -i ubuntu > /dev/null ; then
                if ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cat /run/reboot-required*" > /dev/null 2>/dev/null; then
                        echo "This OS is not officially supported, but I'm reasonably sure it requires a reboot."
                        exit 1
                else
                        echo "This OS is not officially supported, but I'm reasonably sure no reboot is required."
                        exit 0
                fi
        fi

        ## Thanks to GrangerX for the following line, using changed files as a hint of pending changes.
        ## https://serverfault.com/questions/122178/how-can-i-check-from-the-command-line-if-a-reboot-is-required-on-rhel-or-centos
        if ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "lsof" | grep "(path inode=.*)" ; then
                echo "This OS is definitely not supported, so I'm making a wild guess. I think you should reboot."
                exit 1
        else
                echo "This OS is definitely not supported, so I'm making a wild guess. I think no reboot is required."
                exit 0
        fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id before adding or editing a server to monitor - $sshError"
        exit 2
fi
