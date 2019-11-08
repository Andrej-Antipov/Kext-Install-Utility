#!/bin/bash

# функция отладки ##################################################################################################

deb=0

DEBUG(){
if [[ ! $deb = 0 ]]; then
printf '\n\n Останов '"$stop"'  :\n\n' >> ~/temp.txt 
printf '............................................................\n' >> ~/temp.txt
#echo "patches.txt = " >> ~/temp.txt
#cat ~/.spatches.txt >> ~/temp.txt
#echo " " >> ~/temp.txt
echo "kmcount = ""${kmcount}" >> ~/temp.txt
echo "kmlist = ""${kmlist[@]}" >> ~/temp.txt
echo "kmlist/i = ""${kmlist[i]}" >> ~/temp.txt
echo "i = ""${i}" >> ~/temp.txt
echo " " >> ~/temp.txt
echo "new_path = ""${new_path}" >> ~/temp.txt
echo " " >> ~/temp.txt
echo "kext_path = ""${kext_path}" >> ~/temp.txt
echo "result = ""${result}" >> ~/temp.txt
echo " " >> ~/temp.txt
echo "old_kext = ""${old_kext}" >> ~/temp.txt
echo "tmlist/l/ = ""${tmlist[l]}" >> ~/temp.txt
echo " " >> ~/temp.txt
echo "m = ""${m}" >> ~/temp.txt
#echo "l = ""${l}" >> ~/temp.txt
echo "tmlist = ""${tmlist[@]}" >> ~/temp.txt
echo "tmcount= ""${tmcount}" >> ~/temp.txt
echo "strng = ""$strng" >> ~/temp.txt
#echo "folder_trailed_count = "${#folder_trailed[@]} >> ~/temp.txt

printf '............................................................\n\n' >> ~/temp.txt
sleep 0.2
read -n 1 -s
fi
}
#########################################################################################################################################

UPDATE_CACHE(){
if [[ -f ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist ]]; then KextLEconf=$( cat ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist ); cache=1
else
    unset KextLEconf; cache=0
fi
}

ASK_KEXTS_TO_DELETE(){
if [[ $loc = "ru" ]]; then
osascript <<EOD
tell application "System Events"
set ThemeList to {$file_list}
set FavoriteThemeAnswer to choose from list ThemeList with title "Удалить установленные файлы" with prompt "Выберите один или несколько файлов" default items "Basic" with multiple selections allowed
end tell
EOD
else
osascript <<EOD
tell application "System Events"
set ThemeList to {$file_list}
set FavoriteThemeAnswer to choose from list ThemeList with title "Delete installed files" with prompt "Select one or more files" default items "Basic" with multiple selections allowed
end tell
EOD
fi
}

DEL_KEXT_IN_PLIST(){ # kext_name ->
strng=`echo "$KextLEconf" | grep -A 1 "<key>Installed</key>" | grep string | sed -e 's/.*>\(.*\)<.*/\1/' | tr -d '\n'`
if [[ "${strng}" = "" ]]; then kcount=0; klist=()
else
IFS=';'; klist=( ${strng} ); unset IFS
kcount=${#klist[@]}
fi
if [[ ! $kcount = 0 ]]; then
         var=$kcount; posk=0; tlist=()
            while [[ ! $var = 0 ]]
         do
            installed_kext_path=`echo "${klist[$posk]}" | xargs`
            if [[ ! "${installed_kext_path}" = "${kext_name}" ]]; then tlist+=("${klist[$posk]}"); fi
            let "var--"
            let "posk++"
         done
       kcount=${#tlist[@]} 
       var=$kcount; posk=0; unset strng
            while [[ ! $var = 0 ]]
         do
        strng+="${tlist[$posk]}"";"
        let "var--"
        let "posk++"
        done
        
        plutil -replace Installed -string "${strng}" ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist; UPDATE_CACHE
fi  
}

ADD_KEXT_IN_PLIST(){ # new_kext -> 
strng=`echo "$KextLEconf" | grep -A 1 "<key>Installed</key>" | grep string | sed -e 's/.*>\(.*\)<.*/\1/' | tr -d '\n'`
if [[ ! "${strng}" = "" ]]; then 
IFS=';'; klist=( ${strng} ); unset IFS
kcount=${#klist[@]}

    if [[ ! $kcount = 0 ]]; then
        var=$kcount; posk=0; tlist=()
            while [[ ! $var = 0 ]]
         do
            installed_kext_path=`echo "${klist[$posk]}" | xargs`
            if [[ ! "${installed_kext_path}" = "${new_kext}" ]]; then tlist+=("${klist[$posk]}"); fi
            let "var--"
            let "posk++"
         done

    fi
fi
        tlist+=( "${new_kext}" )
       kcount=${#tlist[@]} 
       var=$kcount; posk=0; unset strng
            while [[ ! $var = 0 ]]
         do
        strng+="${tlist[$posk]}"";"
        let "var--"
        let "posk++"
        done
        plutil -replace Installed -string "$strng" ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist; UPDATE_CACHE
}


DISPLAY_NOTIFICATION(){
if [[ -d "${ROOT}"/terminal-notifier.app ]]; then
"${ROOT}"/terminal-notifier.app/Contents/MacOS/terminal-notifier -title "Kext Installler" -sound Submarine -subtitle "${SUBTITLE}" -message "${MESSAGE}"
fi
}

GET_APP_ICON(){
icon_string=""
if [[ -f AppIcon.icns ]]; then 
   icon_string=' with icon file "'"$(echo "$(diskutil info $(df / | tail -1 | cut -d' ' -f 1 ) |  grep "Volume Name:" | cut -d':'  -f 2 | xargs)")"''"$(echo "${ROOT}" | tr "/" ":" | xargs)"':AppIcon.icns"'
fi 
}

GET_PASSWORD(){
PASSWORD=""
if (security find-generic-password -a ${USER} -s addkextinle -w) >/dev/null 2>&1; then
             PASSWORD=$(security find-generic-password -a ${USER} -s addkextinle -w)
             if ! echo $PASSWORD | sudo -Sk printf '' 2>/dev/null; then 
                    security delete-generic-password -a ${USER} -s addkextinle >/dev/null 2>&1
                    PASSWORD=""
                        
                        if [[ $loc = "ru" ]]; then
                        SUBTITLE=SUBTITLE="НЕВЕРНЫЙ ПАРОЛЬ УДАЛЁН ИЗ КЛЮЧЕЙ !"; MESSAGE=" "
                        else
                        SUBTITLE="WRONG PASSWORD REMOVED FROM KEYCHAIN !"; MESSAGE=" "
                        fi
                        DISPLAY_NOTIFICATION 
             fi
fi
if [[ $PASSWORD = "" ]]; then ENTER_PASSWORD; fi 
if [[ $PASSWORD = "" ]]; then 

                        if [[ $loc = "ru" ]]; then
                        SUBTITLE="БЕЗ ПАРОЛЯ ПРОГРАММА НЕ ФУНКЦИОНАЛЬНА !"; MESSAGE="Выполнение программы прекращено .... "
                        else
                        SUBTITLE="NO WAY TO CONTINUE WITHOUT THE PASSWORD !"; MESSAGE="The program's execution aborted ..."
                        fi
                        DISPLAY_NOTIFICATION 
                        EXIT_PROGRAM
 fi

echo $PASSWORD | sudo -S printf '' 2>/dev/null

}

ENTER_PASSWORD(){

        TRY=3; GET_APP_ICON
        while [[ ! $TRY = 0 ]]; do
        if [[ $loc = "ru" ]]; then
        if PASSWORD=$(osascript -e 'Tell application "System Events" to display dialog "       Введите пароль: " '"${icon_string}"' with hidden answer  default answer ""'  -e 'text returned of result'); then cansel=0; else cansel=1; fi 2>/dev/null
        else
        if PASSWORD=$(osascript -e 'Tell application "System Events" to display dialog "       Enter password: " '"${icon_string}"' with hidden answer  default answer ""' -e 'text returned of result'); then cansel=0; else cansel=1; fi 2>/dev/null
        fi      
                if [[ $cansel = 1 ]]; then break; fi  
                if [[ $PASSWORD = "" ]]; then PASSWORD="?"; fi

                if echo $PASSWORD | sudo -Sk printf '' 2>/dev/null; then
                    security add-generic-password -a ${USER} -s addkextinle -w ${PASSWORD} >/dev/null 2>&1
                        
                        if [[ $loc = "ru" ]]; then
                        SUBTITLE="ПАРОЛЬ СОХРАНЁН В СВЯЗКЕ КЛЮЧЕЙ !"; MESSAGE=""
                        else
                        SUBTITLE="PASSWORD KEEPED IN KEYCHAIN !"; MESSAGE=""
                        fi
                        DISPLAY_NOTIFICATION
                        break
                else
                        let "TRY--"
                        if [[ ! $TRY = 0 ]]; then 
                        
                            if [[ $loc = "ru" ]]; then
                        if [[ $TRY = 2 ]]; then ATTEMPT="ПОПЫТКИ"; LAST="ОСТАЛОСЬ"; fi
                        if [[ $TRY = 1 ]]; then ATTEMPT="ПОПЫТКА"; LAST="ОСТАЛАСЬ"; fi
                        SUBTITLE="НЕВЕРНЫЙ ПАРОЛЬ. $LAST $TRY $ATTEMPT !"; MESSAGE=""
                            else
                        if [[ $TRY = 2 ]]; then ATTEMPT="ATTEMPTS"; fi
                        if [[ $TRY = 1 ]]; then ATTEMPT="ATTEMPT"; fi
                        SUBTITLE="INCORRECT PASSWORD. LEFT $TRY $ATTEMPT !"; MESSAGE=""
                            fi
                DISPLAY_NOTIFICATION
                fi
                fi
            done
            PASSWORD="0"
if (security find-generic-password -a ${USER} -s addkextinle -w) >/dev/null 2>&1; then
                PASSWORD=$(security find-generic-password -a ${USER} -s addkextinle -w); 
fi
            if [[ "$PASSWORD" = "0" ]]; then
                
                    if [[ $loc = "ru" ]]; then
                SUBTITLE="ПАРОЛЬ НЕ ПОЛУЧЕН !"; MESSAGE=""
                    else
                SUBTITLE="PASSWORD NOT KEEPED IN KEYCHAIN !"; MESSAGE=""
                    fi
                DISPLAY_NOTIFICATION
            fi

}



CHECK_TTY_COUNT(){
term=`ps`
AllTTYcount=`echo $term | grep -Eo ttys[0-9][0-9][0-9] | wc -l | tr - " \t\n"`
let "TTYcount=AllTTYcount-MyTTYcount"
}

CLEAR_HISTORY(){
if [[ -f ~/.bash_history ]]; then cat  ~/.bash_history | sed -n '/addkext_in_LE/!p' >> ~/new_hist.txt; rm -f ~/.bash_history; mv ~/new_hist.txt ~/.bash_history ; fi >/dev/null 2>/dev/null
if [[ -f ~/.zsh_history ]]; then cat  ~/.zsh_history | sed -n '/addkext_in_LE/!p' >> ~/new_z_hist.txt; rm -f ~/.zsh_history; mv ~/new_z_hist.txt ~/.zsh_history ; fi >/dev/null 2>/dev/null
}

################## Выход из программы с проверкой - выгружать терминал из трея или нет #####################################################
EXIT_PROGRAM(){
################################## очистка на выходе #############################################################
CLEAR_HISTORY 
if [[ $wait_on_exit = 1 ]]; then  
osascript -e 'tell application "Terminal" to activate'
if [[ $loc = "ru" ]]; then
                printf '\n\n                               Нажмите любую клавишу для завершения '
                    else
                printf '\n\n                                     Press any key to exit '
                    fi
read -n1 -s 
fi
#####################################################################################################################
if [[ $textedit_flag = 1 ]]; then
  textedit_now=$(ps -xao tty,pid,command | grep -v grep | grep "TextEdit" | wc -l | tr -d ' ')
  if [[ $textedit_now -gt 0 ]]; then let "textedit_count=textedit_now-1"
    if [[ $textedit_count = 0 ]]; then osascript -e 'tell app "TextEdit" to close first  window' && osascript -e 'quit app "TextEdit.app"' >/dev/null 2>/dev/null
        else
            osascript -e 'tell app "TextEdit" to close first  window' >/dev/null 2>/dev/null
    fi
  fi
fi

CHECK_TTY_COUNT	
if [[ ${TTYcount} = 0  ]]; then   osascript -e 'tell application "Terminal" to close first window' && osascript -e 'quit app "terminal.app"' & exit
	else
     osascript -e 'tell application "Terminal" to close first window' & exit
fi

}



DELETE_KEXT(){

    let "n++"; let "n++"
    if [[ -d /System/Library/Extensions/"${kext_name}" ]] && [[ ! /System/Library/Extensions/"${kext_name}" = "/System/Library/Extensions/" ]]; then sudo rm -Rf /System/Library/Extensions/"${kext_name}"; update_cache=1; fi
    if [[ $loc = "ru" ]]; then
    printf '\033['${n}';20f''\e[1;31m     Удалён:    \e[1;33m'"${kext_name}"'\e[0m '
    else
    printf '\033['${n}';20f''\e[1;31m     Deleted:    \e[1;33m'"${kext_name}"'\e[0m '
    fi

    DEL_KEXT_IN_PLIST

}

CHECK_INSTALL_KEXTS(){

extension="${new_kext##*.}"

let "n++"; let "n++"

if [[ ${extension} = "kext" ]] || [[ ${extension} = "bundle" ]] || [[ ${extension} = "plugin" ]]; then 
    update_cache=1
    if [[ $loc = "ru" ]]; then
    printf '\033['${n}';0f''     Установлен:    \e[1;33m''\033['${n}';'$corr'f'"${new_kext}"'\033['${n}';54f''\e[0m    ver. \e[1;32m'${sver}'\033['${n}';70f''\e[0m'
    else
    printf '\033['${n}';0f''      Installed:    \e[1;33m''\033['${n}';'$corr'f'"${new_kext}"'\033['${n}';54f''\e[0m    ver. \e[1;32m'${sver}'\033['${n}';70f''\e[0m'
    fi
    if [[ ! $old_ver = "" ]]; then  printf ' -   was ver. \e[1;31m'$old_ver'\e[0m \n' else printf '\n'; fi
    
    echo $mypassword | sudo -S printf '' >/dev/null 2>/dev/null

    if [[ -d /System/Library/Extensions/"${new_kext}" ]]; then sudo rm -Rf /System/Library/Extensions/"${new_kext}"; fi
    sudo cp -a "${new_path}" /System/Library/Extensions
    sudo chown -R root:wheel /System/Library/Extensions/"${new_kext}"
    sudo chmod  -R 755 /System/Library/Extensions/"${new_kext}"
    ADD_KEXT_IN_PLIST

    else
    wait_on_exit=1
    if [[ $loc = "ru" ]]; then
    printf '\033['${n}';0f''\e[1;31m  НЕ установлен:    \e[1;33m''\033['${n}';'$corr'f'${new_kext}'\033['${n}';54f''\e[0m'
    else
    printf '\033['${n}';0f''\e[1;31m  NOT Installed:    \e[1;33m''\033['${n}';'$corr'f'${new_kext}'\033['${n}';54f''\e[0m'
    fi


fi


}

function ProgressBar {
let _progress=(${1}*100/${2}*100)/100
let _done=(${_progress}*4)/10
let _left=40-$_done
_fill=$(printf "%${_done}s")
_empty=$(printf "%${_left}s")
printf "\r    \033[18C[${_fill// /.}${_empty// / } ]  ${_progress}%%"
}

TIMEOUT(){
_start=1
_end=100
for number in $(seq ${_start} ${_end})
do
sleep 0.4
ProgressBar ${number} ${_end}
done
}

GET_KEXT_INFO(){
sver="${new_path}"
sver="$(plutil -p "${sver}"/Contents/Info.plist | grep CFBundleShortVersionString | awk -F"=> " '{print $2}' | cut -c 2- | rev | cut -c 2- | rev )"
old_ver=""
old_ver="$(plutil -p /System/Library/Extensions/"${new_kext}"/Contents/Info.plist | grep CFBundleShortVersionString  | awk -F"=> " '{print $2}' | cut -c 2- | rev | cut -c 2- | rev )"
}

UPDATE_KERNEL_CACHE(){
osascript -e 'tell application "Terminal" to activate'
echo
echo
echo "       Update cache (y/N) ?"
read  -s -r  -n 1  input
printf '\r\033[1A'
if [[ ${input} = [yY] ]]; then 
wait_on_exit=1
printf '\e[1;36m     updating kernel cache ....\e[0m'
rm -f ~/Desktop/KernelCacheUpdate.log.txt
while :;do printf '\e[1;36m.\e[0m' ;sleep 2;done &
trap "kill $!" EXIT 
sudo kextcache -i / &> ~/Desktop/KernelCacheUpdate.log.txt >/dev/null
kill $!
wait $! 2>/dev/null
trap " " EXIT
echo
echo
text_edit_flag=0
if [[ -f ~/Desktop/KernelCacheUpdate.log.txt ]]; then textedit_flag=1; open -a "TextEdit" -n  ~/Desktop/KernelCacheUpdate.log.txt; osascript -e 'tell application "Terminal" to activate'; fi
printf '\r\n\e[1;36m     timeout after: \e[1;32m'  
TIMEOUT
printf '\e[0m\r''                                                                       \n\n'
fi
printf '\r                                \n'
printf '\r\033[6A'
printf "%"100"s"'\n'"%"100"s"'\n'"%"100"s"'\n'"%"100"s"'\n'"%"100"s"'\n'"%"100"s"'\n'"%"100"s"
}

GET_ARGS(){
get_args="$(cat  ~/.spatches.txt | tr '\n' ';' | xargs )"
all_path=(); var=0; m=1; while [[ $var = 0 ]]; do str="$(echo $get_args | cut -f"${m}" -d ';')"; if [[ ! $str = "" ]]; then all_path+=( "${str}" ); let "m++"; else break; fi; done
path_count=${#all_path[@]}
}

PARSE_FOLDER(){
if [[ -d "${new_path}" ]]; then
get_args="$( find "${new_path}" -maxdepth 1 -type d -not -path "${new_path}" | tr '\n' ';' | xargs )"
folder_trailed=(); var=0; m=1; while [[ $var = 0 ]]; do str="$(echo $get_args | cut -f"${m}" -d ';')"; if [[ ! $str = "" ]]; then folder_trailed+=( "${str}" ); let "m++"; else break; fi; done
folder_trailed_count=${#folder_trailed[@]}
    if [[ ! $folder_trailed_count = 0 ]]; then 
        for ((i=0;i<$folder_trailed_count;i++)) do 
        all_path_trailed+=( "$(echo "${folder_trailed[i]}" | xargs)" )
        done
    fi
fi
}

TRAIL_FOLDER(){
all_path_trailed=()
for ((l=0;l<$path_count;l++)) do 
new_path="$(echo "${all_path[l]}" | xargs)"; new_kext=$(echo "${new_path}" | sed 's|.*/||')
    if [[ -f "${new_path}" ]]; then all_path_trailed+=( "$(echo "${all_path[l]}" | xargs)" )
    else
dota=$(echo "${new_kext}" | grep -o "\." | wc -w | tr -d ' ')
if [[ ! "${dota}" = "0" ]] && [[ "${new_kext:0:1}" = "." ]]; then let "dota--"; fi
if [[ ! "${dota}" = "0" ]]; then  extension="${new_kext##*.}"
    if [[ ! ${extension} = "" ]]; then all_path_trailed+=( "$(echo "${all_path[l]}" | xargs)" ); else PARSE_FOLDER; fi
    else
    if [[ -f "${new_path}" ]]; then all_path_trailed+=( "$(echo "${all_path[l]}" | xargs)" ); else PARSE_FOLDER; fi
fi
    fi
done

all_path=( "${all_path_trailed[@]}" ); path_count=${#all_path[@]}
}

INSTALL_KEXTS(){
n=0; corr=0
for ((i=0;i<$path_count;i++)) do 
new_path="$(echo "${all_path[i]}" | xargs)"
new_kext=$(echo "${new_path}" | sed 's|.*/||'); p=${#new_kext}; let "corr=(36-p)/2+21"
GET_KEXT_INFO
CHECK_INSTALL_KEXTS
done
}

GET_INSTALLED_STRING(){
UPDATE_CACHE
    if [[ ${cache} = 1 ]]; then strng=`echo "$KextLEconf" | grep -A 1 "<key>Installed</key>" | grep string | sed -e 's/.*>\(.*\)<.*/\1/' | tr -d '\n'`; fi
}

###################### main #########################################################

clear

cd "$(dirname "$0")"; ROOT="$(dirname "$0")"

osascript -e "tell application \"Terminal\" to set the font size of window 1 to 12"
osascript -e "tell application \"Terminal\" to set background color of window 1 to {300, 9500, 16250}"
osascript -e "tell application \"Terminal\" to set normal text color of window 1 to {65535, 65535, 65535}"


clear && printf '\e[8;22;100t' && printf '\e[3J' && printf "\033[H"
loc=`defaults read -g AppleLocale | cut -d "_" -f1`
MyTTY=`tty | tr -d " dev/\n"`
term=`ps`;  MyTTYcount=`echo $term | grep -Eo $MyTTY | wc -l | tr - " \t\n"`
wait_on_exit=0
printf "\033[?25l"
macos=$(sw_vers -productVersion | cut -f1-2 -d"." | tr -d '.')
if [[ "${macos}" = "1015" ]]; then 
  if ! GET_PASSWORD; then EXIT_PROGRAM; else sudo mount -uw / ; fi
fi
printf '\e[3J' && printf "\033[H"
printf '           \n'

if [[ ! -d  ~/Library/Application\ Support/KextSLEinstaller ]]; then mkdir ~/Library/Application\ Support/KextSLEinstaller; fi
if [[ ! -f ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist ]]; then
    echo '<?xml version="1.0" encoding="UTF-8"?>' >> ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist
    echo '<plist version="1.0">' >> ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist
    echo '<dict>' >> ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist
    echo '  <key>Installed</key>' >> ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist
    echo '  <string></string>' >> ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist
    echo '</dict>' >> ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist
    echo '</plist>' >> ~/Library/Application\ Support/KextSLEinstaller/InstalledKext.plist
fi


if [[ ! -d  /Library/Extensions ]]; then 
    if ! GET_PASSWORD; then EXIT_PROGRAM; fi
    echo $mypassword | sudo -S printf '' >/dev/null 2>/dev/null
    sudo mkdir /Library/Extensions
    sudo chown -R root:wheel /Library/Extensions
    sudo chmod -R 755 /Library/Extensions
fi

UPDATE_CACHE


################ get args string ##########################################################
if [[ ! -f ~/.spatches.txt ]]; then 

    var1=0; while [[ $var1 = 0 ]]; do


    GET_INSTALLED_STRING
    if [[ ! $strng = "" ]]; then 

             GET_APP_ICON


                                if [[ $loc = "ru" ]]; then
             if answer=$(osascript -e 'display dialog "Что собираемся предпринять?" '"${icon_string}"' buttons {"Удаление", "Установка", "Выход" } default button "Установка" '); then cancel=0; else cancel=1; fi 2>/dev/null
             if [[ "$(echo $answer | cut -f2 -d':')" = "Выход" ]]; then EXIT_PROGRAM; fi
                                else
             if answer=$(osascript -e 'display dialog "What are you going to do?" '"${icon_string}"' buttons {"Delete", "Install", "Exit" } default button "Install" '); then cancel=0; else cancel=1; fi 2>/dev/null
             if [[ "$(echo $answer | cut -f2 -d':')" = "Exit" ]]; then EXIT_PROGRAM; fi
                                fi
             if [[ $cancel = 1 ]]; then EXIT_PROGRAM; fi
             
    else
            if [[ $loc = "ru" ]]; then answer="Установка"; else answer="Install"; fi
    fi
    if [[ $loc = "ru" ]]; then check_answer="Установка"; else check_answer="Install"; fi
 if [[ "$(echo $answer | cut -f2 -d':')" = "${check_answer}" ]]; then
    n=4
            if [[ $loc = "ru" ]]; then
        printf '\033['${n}';0f''\e[1;33m     Выберите кексты для установки !    \e[0m '
            else
        printf '\033['${n}';0f''\e[1;33m     Select the kexts to install  !    \e[0m '
            fi
    open -W AskKexts.app
    clear && printf '\e[3J' && printf "\033[H"
    if [[ ! -f ~/.spatches.txt ]]; then  UPDATE_CACHE; strng=`echo "$KextLEconf" | grep -A 1 "<key>Installed</key>" | grep string | sed -e 's/.*>\(.*\)<.*/\1/' | tr -d '\n'`; if [[ $strng = "" ]]; then wait_on_exit=0; break; fi
        else
        no_kexts=0
        GET_ARGS
        rm -f ~/.spatches.txt
        if [[ ${path_count} = 0 ]]; then no_kexts=1; else TRAIL_FOLDER; fi
                if [[ ${path_count} = 0 ]]; then 
                    no_kexts=1
                 else 
                    if ! GET_PASSWORD; then EXIT_PROGRAM; fi
                    if [[ $path_count -gt 5 ]]; then let lines="path_count*2+12"; clear && printf '\e[8;'$lines';100t' && printf '\e[3J' && printf "\033[H"; fi 
                    update_cache=0
                    INSTALL_KEXTS
                    if [[ $update_cache = 0 ]]; then no_kexts=1; else UPDATE_KERNEL_CACHE; fi
                 fi                                  
        if [[ ${no_kexts} = 1 ]]; then 
                    if [[ $loc = "ru" ]]; then
            printf '\033['${n}';0f''\e[1;33m     Не получены подходящие файлы для установки !    \e[0m '
                    else
            printf '\033['${n}';0f''\e[1;33m     No valid files to install found  !              \e[0m '
                    fi
            read -n 1 -s -t 3
        fi             
    fi
    
 else

    if [[ ! $strng = "" ]]; then  IFS=';'; kmlist=( ${strng} ); unset IFS; kmcount=${#kmlist[@]}; file_list=""

       for ((i=0;i<$kmcount;i++)) do old_kext="${kmlist[i]}"; file_list+='"'${old_kext}'"' ; if [[ ! $i = $(( $kmcount-1 )) ]]; then file_list+=","; fi ; done
    
       if result=$(ASK_KEXTS_TO_DELETE); then 
           if [[ ! $result = "false" ]]; then 
           if ! GET_PASSWORD; then EXIT_PROGRAM; fi
           echo $mypassword | sudo -S printf '' >/dev/null 2>/dev/null
           IFS=","; tmlist=( ${result} ); unset IFS; tmcount=${#tmlist[@]}
           if [[ $tmcount -gt 5 ]]; then let lines="tmcount*2+12"; clear && printf '\e[8;'$lines';100t' && printf '\e[3J' && printf "\033[H"; fi
           n=0; corr=0 
           for ((i=0;i<$kmcount;i++)) do
           old_kext="${kmlist[i]}"
           for ((l=0;l<$tmcount;l++)) do if [[ "${old_kext}" = $(echo "${tmlist[l]}" | xargs) ]]; then  kext_name=$(echo "${kmlist[i]}" | xargs);  DELETE_KEXT; break; fi ; done
           done
           UPDATE_KERNEL_CACHE
           fi
        fi
    fi
 fi
    clear && printf '\e[8;22;100t' && printf '\e[3J' && printf "\033[H"
    done
fi

############################# get args from file ###########################################

if [[ ! -f ~/.spatches.txt ]]; then EXIT_PROGRAM; fi

GET_ARGS

rm -f ~/.spatches.txt

if [[ ${path_count} = 0 ]]; then EXIT_PROGRAM; fi

#################### get kexts from folders ################################################

TRAIL_FOLDER

############################################################################################

if ! GET_PASSWORD; then EXIT_PROGRAM; fi

if [[ $path_count -gt 5 ]]; then let lines="path_count*2+12"; clear && printf '\e[8;'$lines';100t' && printf '\e[3J' && printf "\033[H"; fi

update_cache=0

INSTALL_KEXTS

if [[ $update_cache = 0 ]]; then EXIT_PROGRAM; fi

UPDATE_KERNEL_CACHE

EXIT_PROGRAM