#!/bin/bash

GLOBALES=~/.local/bin/globals.sh

# dont run twice
[[ $(pgrep -c wofi) > 0 ]] && pkill -o wofi


quit() {
	exit 0
}

moveTo() {
   echo "swaymsg workspace $1"
}

changeResolution() {
   OUTPUT="$(swaymsg -t get_outputs | jq '.[] | {name} ' | xargs | sed 's/.*: //g;s/ }//g')"
   RESOLUTION="$1"
   LINE="output $OUTPUT resolution $RESOLUTION position 0,0"
   sed -i "s/^.*position 0,0/$LINE/" ~/.config/sway/config
   swaymsg reload
   dmenuSystem.sh changeReso
}


WMCLASS="$@"
if echo "$WMCLASS" | grep -w "changeReso"; then
   ACTIVE="$(grep "position 0,0" .config/sway/config | awk '{print $4}')"
   CHOICES="01 <- $ACTIVE        ^ 1 ^ dmenuSystem.sh system
   $(swaymsg -t get_outputs | jq '.. | ..' | grep -E "width|height" | xargs | sed 's/width: //g;s/, height: /x/g;s/,/\n/g' | sort | uniq | sed '/0x0/d;/^$/d' | awk '{print "|||| "$1"\t^ 1 ^\tchangeResolution "$1}')"
   WINAME="Change Resolution"
elif echo "$WMCLASS" | grep -w "system"; then
   CHOICES="
      01 <-                      ^ 1 ^ dmenuSystem.sh 
      10 Terminal                ^ 0 ^ alacritty && $(moveTo "Terminal")
      20 Change Resolution       ^ 1 ^ dmenuSystem.sh changeReso
      30 Reboot                  ^ 0 ^ reboot
      31 Poweroff                ^ 0 ^ poweroff
      40 Close                   ^ 0 ^ $(quit)
   "
   WINAME="System"
else
   CHOICES="
      01 Close                   ^ 0 ^ $(quit)
      10 System                  ^ 1 ^ dmenuSystem.sh system
      20 Printer                 ^ 1 ^ dmenuPrinter.sh && dmenuSystem.sh
      30 Wifi                    ^ 0 ^ dmenuWifi.sh && dmenuSystem.sh
      40 Browser Restart         ^ 0 ^ swaymsg [title=\"Browser\"] kill && $(moveTo "Browser")
      50 Change Homepage         ^ 0 ^ changeHomepage.sh

   "
   WINAME="Start"
fi

PROGCHOICES="$(echo "$CHOICES" | xargs -0 echo | sed '/^[[:space:]]*$/d' | awk '{$1=$1};1')"

echo "$PROGCHOICES" |
   cut -d'^' -f1 |
   wofi -O alphabetical -d -l 16 -p "$WINAME" | (
      PICKED="$(cat)"
      echo "$PICKED" | grep . || quit
		LOOP="$(echo "$PROGCHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f2)"
		CMD="$(echo "$PROGCHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f3)"
		if echo "$LOOP" | grep 1; then
			eval "$CMD"
		else
			eval "$CMD" &
			quit
		fi
      echo "$PICKED"
   ) & wait
