#!/bin/bash

# set this to "y" to avoid deletion of downloaded data (arma3 and steamcmd)
debug="n"

# get install path
a3instdir=$(dirname "$(readlink -f "$0")")
a3instdir=${a3instdir%/installer}
#echo $a3instdir

. $a3instdir/installer/install.cfg

goinst="n"
echo -n "

---------------------------------------------
This will install Arma3 Server with Antistasi Altis
including required mods, 3 headless clients, steamcmd
and startup / update scripts

into: $a3instdir
for admin-user: $useradm
a3server will be executed by: $userlnch
both being in group: $grpserver

Modify ./install.cfg to change the above.

The script will OVERWRITE existing folders in the installation directory,
and you may be asked for the 'sudo' password by the script.

Do you want to continue? (y/n)"

read goinst
if [ $goinst != "y" ]; then
	exit 0
fi

if [ $debug == "y"  ]; then
	echo "---Debug mode is ON----"
	sleep 1
fi

# scripted user management
echo -n "
Do you want the users named above to be created?
! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !
WARNING, if they already exist, they will be DELETED, including their home folders!
! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !

Create Users? (y/n)"
read mkuser
if [ $mkuser == "y" ]; then
	. $a3instdir/installer/adddelusr.sh
fi

echo -n "
Basic modlist:
Antistasi Altis, CBA_A3, RHSAFRF, RHSUSAF, RHSGREF, RHSSAF, ace, ACE Compat - RHSAFRF,
ACE Compat - RHSUSAF, ACE Compat - RHSGREF

Extended modlist (inludes basic modlist):
XLA_FixedArsenal, Enhanced Movement, JSRS SOUNDMOD, JSRS - Additional Weap Sounds,
JSRS - RHS - Vehicles Sound Patch, JSRS - RHS - Weapons Sound Patch, Blastcore

Install extended modlist? (y/n)"
read extmodlist

echo -n "
Input password for joining a3 server, if you want to leave the server public
leave this empty and press enter

Arma Server Password: "

read srvpass

echo -n "
Building filestructure...
"

# build basic folder structure
sudo chown ${useradm}:${grpserver} $a3instdir
sudo -u $useradm chmod 775 $a3instdir

if [ $debug == "y"  ]; then
 list=("scripts")
else
 list=("scripts" "a3master" "steamcmd")
fi

for folder in "${list[@]}"; do
if [ -d "${a3instdir}/${folder}" ]; then
	sudo rm -rf $a3instdir/$folder
fi
	sudo -u $useradm mkdir $a3instdir/$folder --mode=775
done

#debug lines to clear a3master, but not downloaded content
if [ $debug == "y"  ]; then
	sudo rm -rf ${a3instdir}/a3master/_mods
	sudo rm -rf ${a3instdir}/a3master/cfg
	sudo rm -rf ${a3instdir}/a3master/log
	sudo rm -rf ${a3instdir}/a3master/userconfig/
fi

sudo -u $useradm mkdir ${a3instdir}/scripts/service --mode=754
sudo -u $useradm mkdir ${a3instdir}/a3master/_mods --mode=775
sudo -u $useradm mkdir ${a3instdir}/a3master/cfg --mode=775
sudo -u $useradm mkdir ${a3instdir}/a3master/log --mode=775
sudo -u $useradm mkdir ${a3instdir}/scripts/logs --mode=775
sudo -u $useradm mkdir ${a3instdir}/a3master/userconfig --mode=775

# copy files
sudo -u $useradm cp ${a3instdir}/installer/rsc/servervars.cfg ${a3instdir}/scripts/service/
sudo -u $useradm chmod 644 ${a3instdir}/scripts/service/servervars.cfg
if [ $extmodlist == "y" ]; then
	sudo -u $useradm cp ${a3instdir}/installer/rsc/modlistextd.inp ${a3instdir}/scripts/modlist.inp
	sudo -u $useradm chmod 664 ${a3instdir}/scripts/modlist.inp
else
	sudo -u $useradm cp ${a3instdir}/installer/rsc/modlist.inp ${a3instdir}/scripts/
	sudo -u $useradm chmod 664 ${a3instdir}/scripts/modlist.inp
fi
sudo -u $useradm cp ${a3instdir}/installer/rsc/a3srvi.sh ${a3instdir}/scripts/service/
sudo -u $useradm chmod 754 ${a3instdir}/scripts/service/a3srvi.sh
sudo -u $useradm cp ${a3instdir}/installer/rsc/a3srviHC.sh ${a3instdir}/scripts/service/
sudo -u $useradm chmod 754 ${a3instdir}/scripts/service/a3srviHC.sh
sudo -u $useradm cp ${a3instdir}/installer/rsc/prepserv.sh ${a3instdir}/scripts/service/
sudo -u $useradm chmod 754 ${a3instdir}/scripts/service/prepserv.sh

sudo -u $useradm touch ${a3instdir}/a3master/cfg/a3common.cfg
sudo -u $useradm chmod 664 ${a3instdir}/a3master/cfg/a3common.cfg

sudo -u $useradm bash -c "echo \"//
// More information at: http://community.bistudio.com/wiki/server.cfg
//
// GLOBAL SETTINGS
password = \"${srvpass}\";						//Password for joining, eg connecting to the server\" >> ${a3instdir}/a3master/cfg/a3common.cfg"
sudo -u $useradm bash -c "cat ${a3instdir}/installer/rsc/a3common.cfg >> ${a3instdir}/a3master/cfg/a3common.cfg"
sudo -u $useradm cp ${a3instdir}/installer/rsc/basic.cfg ${a3instdir}/a3master/cfg/
sudo -u $useradm chmod 664 ${a3instdir}/a3master/cfg/basic.cfg

antistasirar=${antistasi_download_url##*/}
antistasimission=${antistasirar%.rar}
sudo -u $useradm touch ${a3instdir}/a3master/cfg/a3indi1.cfg
sudo -u $useradm chmod 664 ${a3instdir}/a3master/cfg/a3indi1.cfg
sudo -u $useradm bash -c "echo \"headlessClients[]={\"127.0.0.1\"};
localClient[]={\"127.0.0.1\"};

// MISSIONS CYCLE
class Missions {
    class mission1
		{
		template = \"${antistasimission}\";
		};
};\" >> ${a3instdir}/a3master/cfg/a3indi1.cfg"

for index in $(seq 4); do
	if [ $index == "1" ]; then
  	wait 1
	else
		sudo -u $useradm cp ${a3instdir}/installer/rsc/a3indiHC.cfg ${a3instdir}/a3master/cfg/a3indi${index}.cfg
	fi
	sudo -u $useradm chmod 664 ${a3instdir}/a3master/cfg/a3indi${index}.cfg
done

# build Arma3Profile
if [ -d "/home/"${userlnch}'/.local/share/Arma 3 - Other Profiles/'"${grpserver}" ]; then
        sudo -u $userlnch rm -rf /home/${userlnch}"/.local/share/Arma 3 - Other Profiles/"${grpserver}
fi
sudo chmod 755 /home/${userlnch}
sudo -u $userlnch mkdir -p /home/${userlnch}"/.local/share/Arma 3 - Other Profiles/"${grpserver} --mode=775
sudo -u $userlnch cp ${a3instdir}/installer/rsc/profile.Arma3Profile /home/${userlnch}"/.local/share/Arma 3 - Other Profiles/"${grpserver}/${grpserver}.Arma3Profile
sudo -u $userlnch chmod 464 /home/${userlnch}'/.local/share/Arma 3 - Other Profiles/'${grpserver}/*.Arma3Profile

# store User settings
sudo -u $useradm chmod 664 ${a3instdir}/scripts/service/servervars.cfg

sudo bash -c "echo \"
useradm=${useradm}
username=${userlnch}
profile=${grpserver}\" >> ${a3instdir}/scripts/service/servervars.cfg"

# build SysVinit scripts
for index in $(seq 4); do
	if [ -f "/etc/init.d/a3srv${index}" ]; then
		sudo rm -f /etc/init.d/a3srv${index}
	fi
# build for host server
	if [ $index == "1" ]; then
		sudo touch /etc/init.d/a3srv${index}
		sudo chmod 750 /etc/init.d/a3srv${index}
		sudo bash -c "echo \"#!/bin/sh
### BEGIN INIT INFO
# Provides:          a3srv${index}\" >> /etc/init.d/a3srv${index}"
sudo bash -c "cat ${a3instdir}/installer/rsc/a3srvi.init >> /etc/init.d/a3srv${index}"
sudo bash -c "echo \"serverid=${index}
basepath=${a3instdir}
a3srvpass=${srvpass}
. ${a3instdir}/scripts/service/a3srvi.sh\" >> /etc/init.d/a3srv${index}"
sudo update-rc.d a3srv${index} defaults
	else
# build for headless clients
sudo touch /etc/init.d/a3srv${index}
sudo chmod 750 /etc/init.d/a3srv${index}
sudo bash -c "echo \"#!/bin/sh
### BEGIN INIT INFO
# Provides:          a3srv${index}\" >> /etc/init.d/a3srv${index}"
sudo bash -c "cat ${a3instdir}/installer/rsc/a3srvi.init >> /etc/init.d/a3srv${index}"
sudo bash -c "echo \"serverid=${index}
basepath=${a3instdir}
a3srvpass=${srvpass}
. ${a3instdir}/scripts/service/a3srviHC.sh\" >> /etc/init.d/a3srv${index}"
sudo update-rc.d a3srv${index} defaults
	fi
done

echo -n "
Installing steam and requirements...
"
# install steamcmd
sudo apt-get install unrar

if [ $debug != "y"  ]; then
	sudo apt-get install lib32gcc1
	sudo apt-get install lib32stdc++6
	cd $a3instdir/steamcmd
	sudo -u $useradm wget -nv http://media.steampowered.com/installer/steamcmd_linux.tar.gz
	sudo -u $useradm tar -xvzf steamcmd_linux.tar.gz
	sudo -iu $useradm ${a3instdir}/steamcmd/steamcmd.sh +runscript ${a3instdir}/installer/rsc/update.steam
	sudo -u $useradm rm -f ${a3instdir}/steamcmd/steamcmd_linux.tar.gz
	echo "--- SteamCMD was installed and is up to date!"
fi

# set file permissions of ~/Steam folder
sudo -u $useradm find -L /home/${useradm}/Steam -type d -exec chmod 775 {} \;
sudo -u $useradm find -L /home/${useradm}/Steam -type f -exec chmod 664 {} \;

# build update scripts
sudo -u $useradm touch ${a3instdir}/scripts/a3update.sh
sudo -u $useradm chmod 744 ${a3instdir}/scripts/a3update.sh
sudo -u $useradm bash -c "echo \"#!/bin/bash

useradm=$useradm
steamdir=${a3instdir}/steamcmd
a3instdir=$a3instdir\" >> ${a3instdir}/scripts/a3update.sh"
sudo -u $useradm bash -c "cat ${a3instdir}/installer/rsc/a3update.sh >> ${a3instdir}/scripts/a3update.sh"

sudo -u $useradm touch ${a3instdir}/scripts/runupdate.sh
sudo -u $useradm chmod 754 ${a3instdir}/scripts/runupdate.sh
sudo -u $useradm bash -c "cat ${a3instdir}/installer/rsc/runupdate.sh > ${a3instdir}/scripts/runupdate.sh"
sudo -u $useradm bash -c "echo \"

chown -R ${useradm}:${grpserver} ${a3instdir}/a3master
sudo -iu ${useradm} ${a3instdir}/scripts/a3update.sh

fi
exit 0\" >> ${a3instdir}/scripts/runupdate.sh"

sudo bash -c "echo \"
%${grpserver}      ALL=NOPASSWD: /usr/sbin/service a3srv[1-4] *, ${a3instdir}/scripts/runupdate.sh
\" >> /etc/sudoers"
ln -s /home/${useradm}/Steam /root/Steam

# request download
echo -n "Installation is now prepared.

You need to execute the command
ln -s /home/${useradm}/Steam /home/UPDATEUSER/Steam
once for every user you want to enable to run the update script.

If you choose to abort now, you can still continue later by running the A3-update script.
Begin download of A3? (y/n)?"

#You may want to add the line
#%${grpserver}      ALL=NOPASSWD: /usr/sbin/service a3srv[1-4] *, ${a3instdir}/scripts/runupdate.sh
#to sudoers with the visudo command after the download. Consider reading the wiki/manpage on visudo beforehand.

read goinst
if [ $goinst != "y" ]; then
        exit 0
fi

# install A3
sudo -iu $useradm ${a3instdir}/scripts/a3update.sh $antistasi_download_url

echo -n "
 - ALL DONE
"

exit 0
