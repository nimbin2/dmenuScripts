#!/bin/bash

# Add the following line to your sudoers file, change USER to your name:
# USER ALL=NOPASSWD:/usr/bin/systemctl restart cups.service

# dont run twice
[[ $(pgrep -c wofi) > 0 ]] && pkill -o wofi


quit() {
   exit 0
}

notify() {
   notify-send -t 5000 "$1"
}

checkQutePrinter() {
	if which toggleQutePrinter.sh | grep -q ".sh"; then
      GLOBALES=~/.local/bin/globals.sh
      STATUS=$(grep "^TITLES=" $GLOBALES | grep -q "Printer" &&
         echo "Close" ||
         echo "Open")
      echo "02 $STATUS Settings ^ 0 ^ toggleQutePrinter.sh && waymsg workspace Printer"
   fi
}

progRemovePrinter() {
   lpstat -e | sed '/.*_SP40/d' | awk -F '\n' '{print "|||| " $1 "\t^ 1 ^\tlpadmin -x "$1}'
}

getprogchoices() {
   WMCLASS="$1"
	case "$WMCLASS" in
		*removePrinter)
			CHOICES="
				01 <-                   ^ 0 ^ dmenuPrinter.sh
				$(progRemovePrinter)"
			WINAME="Remove Printer"
			;;
		*)
		CHOICES="
			01 Close                   ^ 0 ^ $(quit)
			$(checkQutePrinter)
			03 Remove all Jobs ($(lpstat -W not-completed | wc -l))   ^ 1 ^ cancel -a && dnemuSystem.sh printer
			04 Remove Printer          ^ 0 ^ dmenuPrinter.sh removePrinter
			05 Restart Service  			^ 0 ^ sudo systemctl restart cups.service
		"
		;;
	esac
   CHOICES="$(printf "%s\n" "$CHOICES" |
            xargs -0 echo | sed '/^[[:space:]]*$/d' | awk '{$1=$1};1')"
}

mainloop() {
	getprogchoices "$@"
   PICKED="$(
   printf "%s\n" "$CHOICES" |
      cut -d'^' -f1 |
      wofi -O alphabetical -d -p "$WINAME" $DMENUPARAMETER
      )"
   LOOP="$(printf "%s\n" "$CHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f2)"
   CMD="$(printf "%s\n" "$CHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f3)"
	
	if printf %s "$LOOP" | grep -q 1; then
      eval "$CMD"
		mainloop "$@"
	else
		eval "$CMD"
		quit
	fi
} 

mainloop "$@"

