#! /bin/bash

if [ -n $1 ]
then
	git clone https://aur.archlinux.org/${1}.git
	cd ./${1}
	makepkg -sirc --skippgpcheck
	if [ $? -eq "0" ]
	then
		echo "Installation successful"
	else
		cd ..
		read -p "An error occured. Remove cloned files? (y/n) " RM_Y_N
		if [ $RM_Y_N == "y" ]
		then
			sudo rm -r $1
			echo "Cloned files removed"
		else
			echo "Cloned files not removed and can be found at $(pwd)/$1"
		fi
		echo "Error: Package not installed"
	fi
fi
