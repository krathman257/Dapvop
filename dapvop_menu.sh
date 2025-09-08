#! /bin/bash -xv 

# Capturing Dialog Output
#
# Dialog outputs its menu selections into stderr, which makes it harder to capture in a variable
# To fix this, the flags '3>&1 1>&2 2>&3 3>&-' can be used after the dialog command
# - 3>&1 opens a new stream (3) and feeds it into stdout (1)
# - 1>&2 feeds stdout (1) into stderr (2)
# - 2>&3 feeds stderr (2) into the new stream (3), which is directed into stdout
# - 3>&- closes the new stream (3)
# Think of it as switching two variable values
# temp = x
# x = y
# y = temp

mainMenu(){
	CHOICE=$(dialog --title "Dapvop Main Menu" --no-cancel --menu "Please select an option" 0 0 0 1 "Play a DVD" 2 "Play a file" 3 "Youtube" 4 "Settings" 5 "Power" 3>&1 1>&2 2>&3 3>&-)

	case "$CHOICE" in
		1)
			playDVD
			;;
		2)
			fileMenu
			;;
		3)
			openYoutube
			;;
		4)
			settingsMenu
			;;
		5)
			powerMenu
			;;
	esac
	clear
}

playDVD(){
	# Play DVD in VLC
	ratpoison -c "verbexec cvlc --dts-dynrng dvd://"
	clear
}

fileMenu(){
	CHOICE="/mnt/external"
	declare CHOICE_EXIT_STATUS
	while [ -d "$CHOICE/" ]
	do	
		CHOICE=$(dialog --title "File Menu" --cancel-label "Back" --fselect "$CHOICE/" 10 100 3>&1 1>&2 2>&3 3>&-) || return
	done

	ratpoison -c "verbexec cvlc --dts-dynrng --no-sub-autodetect-file '$CHOICE'"
	
	clear
}

openYoutube(){
	ratpoison -c "verbexec firefox https://youtube.com/tv"
	clear 
}

settingsMenu(){
	CHOICE=$(dialog --title "Dapvop Settings" --cancel-label "Back" --menu "Please select an option" 0 0 0 1 "Detect Monitor" 2 "Network Manager" 3 "Open Terminal" 3>&1 1>&2 2>&3 3>&-) || return

	case "$CHOICE" in
		1)
			xrandr --output eDP1 --auto --output HDMI1 --auto
			;;
		2)
			ratpoison -c "exec xterm -e 'nmcli device wifi rescan; nmtui connect'"
			;;
		3)
			ratpoison -c "exec xterm"
			;;
	esac
	clear
}

powerMenu(){
	CHOICE=$(dialog --title "Power Options" --cancel-label "Back" --menu "Please select an option" 0 0 0 1 "Sleep" 2 "Shut Down" 3>&1 1>&2 2>&3 3>&-) || return

	case "$CHOICE" in
		1)
			systemctl suspend
			;;
		2)
			poweroff
			;;
	esac
	clear
}

# Main Loop

while true
do
	mainMenu
done
