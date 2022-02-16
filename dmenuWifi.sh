#!/bin/bash
# Add the following line to your sudoers file, change USER to your name:
# USER ALL=NOPASSWD:/usr/bin/iwctl
# USER ALL=NOPASSWD:/usr/sbin/iwlist
# USER ALL=NOPASSWD:/usr/bin/systemctl restart iwd.service

quit() {
   exit 0
}

notify() {
   notify-send -t 5000 "$1"
}


getKnowen() {
   sudo iwctl known-networks list | tail -n+5 | sed "s/^  //g;s/   .*$//g" | awk -F '\n' '{print "|||| " $1 " ^ 0 ^\t removeWifi " $1}' | sed "s/^||||  \^ 0 \^.*$//g"
}

getList() {
   sudo iwlist wlan0 scanning | grep ESSID | sed 's/^.*ESSID:\"//g;s/\"$//g' | awk -F '\n' '{print "|||| " $1 "\t^ 1 ^\tmainloop Wifi Password " $1}'
}

connectWifi() {
   sudo iwctl --passphrase="$2" station wlan0 connect "$1"
   dmenuWifi.sh
}

removeWifi() {
   sudo iwctl known-networks "$1" forget 
   dmenuWifi.sh
}

restartWifi() {
   sudo systemctl restart iwd.service && notify-sed -t 5000 "Restarted Wifi" || notify-sed -t 5000 "|||| ERROR: Restarting Wifi failed,- check iwd.service"
   dmenuWifi.sh

}


checkConnection() {
   sleep 2
   TESTCHECK=$1
   ping -c3 archlinux.org &&
      (notify "Network Connected :)" && pkill qutebrowser && quit) ||
      (notify "Failed to connect..$TESTCHECK"
       HEADER="Failed to connect.."
       checkConnection $((TESTCHECK+1))
       )
   [[ "$TESTCHECK" == "6" ]] && removeWifi $WIFINAME

}

connectWifi() {
   [[ "$CMD" = " mainloop" ]] && HEADER="" &&
      mainloop New Wifi
   [[ "$CMD" = " quit" ]] && quit
   echo "$PASSWD"
   sudoWifi "connectWifi" "$WIFINAME" "$PASSWD" &&
      checkConnection 0
}

removeWifi() {
   WIFINAME="$1"
   sudoWifi "removeWifi" "$WIFINAME"
   HEADER="Removed $WIFINAME"
   mainloop Remove Wifi
}

progPassword() {
   CHOICES="|||| Cancel             ^ 0 ^ quit"
   WINAME="Wifi Password"
   DMENUPARAMETER="-P -d"
}

progRemoveWifi() {
   CHOICES="$(getKnowen)"
   WINAME="Remove Wifi"
   DMENUPARAMETER="-l 20"
}


progWifi() {
   CHOICES="$(getList)"

   C=0
   while [[ "$CHOICES" == "" ]]; do
      C=$((C+1))
      CHOICES="$(getList)"

      [[ $C = 8 ]] && CHOICES="|||| Error rorrE ^ 1 ^ mainloop"

      sleep 1
   done

   WINAME="New Wifi"
   DMENUPARAMETER="-l 20"
}

progNetwork() {
   CHOICES="
   01 Close          ^ 0 ^ quit
   02 New Wifi       ^ 0 ^ mainloop New Wifi
   03 Restart Wifi   ^ 0 ^ restartWifi
   04 Remove Wifi    ^ 0 ^ mainloop Remove Wifi
   "
   WINAME="Network"
   DMENUPARAMETER="-l 20"
}

getprogchoices() {
   PROG="$@"
   echo $PROG | grep "^Wifi Password " &&
      WIFINAME="$(echo $PROG | sed 's/^Wifi Password //g')" &&
      PROG="Wifi Password"


   if [[ -z "$@" ]]; then PROG="Network"; fi
   if [ "$PROG" = "Wifi Password" ]; then
      progPassword
   elif [ "$PROG" = "New Wifi" ]; then
      progWifi
   elif [ "$PROG" = "Remove Wifi" ]; then
      progRemoveWifi

   elif [ "$PROG" = "Network" ]; then
      progNetwork
   fi
   [[ "$PROG" = "Network" ]] || 
      CHOICES="01 <- $HEADER ^ 1 ^ HEADER=\"\" mainloop
      $CHOICES"
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

   #printf "%s\n" "sxmo_appmenu: Eval: <$CMD> from picked <$PICKED> with loop <$LOOP>">&2

   echo "Loop: $WINAME"
   echo "CMD: $PICKED"
   if [[ "$WINAME" == "Wifi Password" ]]; then
      PASSWD="$PICKED"
      connectWifi
   elif printf %s "$LOOP" | grep -q 1; then
      eval "$CMD"
      mainloop "$@"
   else
      eval "$CMD"
      quit
   fi
}

mainloop "$@"
