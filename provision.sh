#!/bin/bash
MASTERHOST=workbench.local
MASTERUSER=root
MASTERHOME=/home/chip/
HOSTUSER=chip
HOSTNAME="$1"

BOLD="`tput bold` `tput setaf 4`"
UNBOLD="`tput rmso` `tput setaf 0`"

logger() {
  echo "$BOLD$@ $UNBOLD"
}

if [ "$UID" -ne "0" ]
then
  echo "Hey this is a root thing"
  echo ""
  echo "just root stuff ok"
fi

cd /home/$HOSTUSER

if [ "$HOSTNAME" == "" ]
then
  logger we require more vespene gas. or a hostname, as \$1.
  exit
fi

if [ ! -e /home/$HOSTUSER/.ssh/id_rsa ] || [ ! -e ~/.ssh/id_rsa ]
then
  logger getting key... please enter password:
  scp -r $MASTERUSER@$MASTERHOST:$MASTERHOME.ssh /root/
  scp -r $MASTERUSER@$MASTERHOST:$MASTERHOME.ssh /home/$HOSTUSER/
  logger perms for ssh keys...
  chown -R $HOSTUSER /home/$HOSTUSER/.ssh
  chmod 700 /home/$HOSTUSER/.ssh
  chmod 700 /home/$HOSTUSER/.ssh/id_rsa

  chmod 700 ~/.ssh
  chmod 700 ~/.ssh/id_rsa

fi

if [ `ls /etc/NetworkManager/system-connections/| wc -l` -lt 2 ]
then
logger fetching network connections...
scp -r $MASTERUSER@$MASTERHOST:/etc/NetworkManager/system-connections/ /etc/NetworkManager/
fi


logger updating packages...
apt-get update

logger timezone...
# dpkg-reconfigure tzdata
scp -r $MASTERUSER@$MASTERHOST:/etc/localtime /etc/

logger locales...
apt-get -y install locales
scp -r $MASTERUSER@$MASTERHOST:/etc/locale.gen /etc/
/usr/sbin/locale-gen
logger hostname...

grep Debian /etc/motd > /dev/null
if [ "$?" == "0" ]
then
logger setting motd ...
echo "$HOSTNAME" | figlet -f `ls /usr/share/figlet/*.flf | sort -R | head -1` > /etc/motd
fi

grep EDITOR ~/.profile > /dev/null || ( logger adding EDITOR to ~/.profile... ; echo -e '\nexport EDITOR=nano\n' >> ~/.profile )
grep EDITOR /home/$HOSTUSER/.profile > /dev/null || ( logger adding EDITOR to /home/HOSTUSER/.profile... ;echo -e '\nexport EDITOR=nano\n' >> /home/$HOSTUSER/.profile )


logger git repos...
cd ~HOSTUSER
mkdir git 2>/dev/null
cd git
logger chip-tools
if [ ! -d chip-tools ]
then
yes | git clone git@github.com:combs/chip-tools.git
fi
logger chip-trello
if [ ! -d chip-trello ]
then
yes | git clone git@github.com:combs/chip-trello.git
fi
cd /home/$HOSTUSER
logger perms for git repos...

chown -R $HOSTUSER git

# logger locking password...
# passwd -l $HOSTUSER
# passwd -l root

logger adding nopasswd to sudoers...
echo '%sudo ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/nopasswd
chmod 0440 /etc/sudoers.d/nopasswd

logger disabling password authentication...
cat /etc/ssh/sshd_config | sed 's/^PasswordAuthentication yes/# PasswordAuthentication yes/' >> /tmp/sshd_config && cat /tmp/sshd_config > /etc/ssh/sshd_config && rm /tmp/sshd_config

logger setting hostname...
echo $HOSTNAME > /etc/hostname
cat /etc/hosts | sed -e "s/127.0.0.1.*chip.*/127.0.0.1 $HOSTNAME/" > /tmp/hostname && cat /tmp/hostname > /etc/hosts && rm /tmp/hostname

if [ ! -d /root/.axp209 ]
then
  logger setting up axp209 daemon...
  scp -r $MASTERUSER@$MASTERHOST:/etc/init.d/axp209 /etc/init.d/
  scp -r $MASTERUSER@$MASTERHOST:/root/.axp209 /root/
  /etc/init.d/axp209 start
  sudo update-rc.d ax209 defaults
fi

crontab -u root -l > /tmp/crontab.root
grep backup /tmp/crontab.root || ( logger adding backup to crontab... ; echo -e "\n# m h  dom mon dow   command\n0 5 * * 1 /home/chip/git/chip-tools/backup.sh" >> /tmp/crontab.root; crontab /tmp/crontab.root; rm /tmp/crontab.root )

crontab -u $HOSTUSER -l > /tmp/crontab.$HOSTUSER
grep git-puller /tmp/crontab.$HOSTUSER || ( logger adding git-puller.sh to $HOSTUSER crontab... ; echo -e "\n# m h  dom mon dow   command\n25 5,9,13,17,21,1 * * 1 /home/chip/git/chip-tools/git-puller.sh" >> /tmp/crontab.$HOSTUSER; crontab -u $HOSTUSER /tmp/crontab.$HOSTUSER; rm /tmp/crontab.$HOSTUSER )


logger install packages...
apt-get -y install python3 psutils aptitude build-essential git autoconf libtool libdaemon-dev libasound2-dev libpopt-dev libconfig-dev libavahi-client-dev libssl-dev libsoxr-dev zlib1g-dev zlib1g python3.4 python3-pip figlet htop ffmpeg mplayer unzip gettext
logger update packages...
apt-get -y dist-upgrade

logger Hmm that\'s all I got
