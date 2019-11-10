#!/bin/bash

UPDATE_CACHE(){
if [[ -f ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist ]]; then KextLEconf=$( cat ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist ); cache=1
else
    unset KextLEconf; cache=0
fi
}

SLEEP_READ(){ osascript -e 'tell application "Terminal" to activate'; for ((i=0;i<$1;i++)) do read -r -s -n 1 -t 1; done }

ANY_KEY(){ while true; do if $(read -r -s -n 1 -t 1); then break; fi; done }

ASK_KEXTS_TO_DELETE(){
if [[ $loc = "ru" ]]; then
osascript <<EOD
tell application "System Events"    activate
set ThemeList to {$file_list}
set FavoriteThemeAnswer to choose from list ThemeList with title "Удалить установленные файлы"  with prompt "Выберите один или несколько файлов"  default items "Basic" with multiple selections allowed #set FavoriteThemeAnswer to FavoriteThemeAnswer's item 1 (* extract choice from list *)
end tell
EOD
else
osascript <<EOD
tell application "System Events"    activate
set ThemeList to {$file_list}
set FavoriteThemeAnswer to choose from list ThemeList with title "Delete installed files" with prompt "Select one or more files" default items "Basic" with multiple selections allowed#set FavoriteThemeAnswer to FavoriteThemeAnswer's item 1 (* extract choice from list *)
end tell
EOD
fi
}

DEL_KEXT_IN_PLIST(){ # kext_name ->
strng=`echo "$KextLEconf" | grep -A 1 "<key>Installed</key>" | grep string | sed -e 's/.*>\(.*\)<.*/\1/' | tr -d '\n'`
if [[ ! "${strng}" = "" ]]; then 

    IFS=';'; klist=( ${strng} ); unset IFS; kcount=${#klist[@]}

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
        
        plutil -replace Installed -string "${strng}" ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist; UPDATE_CACHE
    fi
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
        plutil -replace Installed -string "$strng" ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist; UPDATE_CACHE
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
if [[ $window_visible = 0 ]]; then osascript -e 'tell application "Terminal" to set visible  of last  window to true'; window_visible=1; fi 
#####################################################################################################################

CHECK_TTY_COUNT	
if [[ ${TTYcount} = 0  ]]; then   osascript -e 'tell application "Terminal" to close first window' && osascript -e 'quit app "terminal.app"' & exit
	else
     osascript -e 'tell application "Terminal" to close first window' & exit
fi

}

DELETE_KEXT(){

    let "n++"; let "n++"
if [[ ! -d /Library/Extensions/"${kext_name}" ]]; then 
    if [[ $loc = "ru" ]]; then
    vbuf+=$( printf '\033['${n}';20f''\e[1;31m     Не найден:    \e[1;33m'"${kext_name}"'\e[0m ' )
    else
    vbuf+=$( printf '\033['${n}';20f''\e[1;31m     Not found:    \e[1;33m'"${kext_name}"'\e[0m ' )
    fi
    not_found=1

else
    not_found=0
    if [[ ! /Library/Extensions/"${kext_name}" = "/Library/Extensions/" ]]; then new_kext="${kext_name}"; BACKUP_EXTENSION; sudo rm -Rf /Library/Extensions/"${kext_name}"; update_cache=1; fi
    if [[ $loc = "ru" ]]; then
    vbuf+=$( printf '\033['${n}';20f''\e[1;31m     Удалён:    \e[1;33m'"${kext_name}"'\e[0m ' )
    else
    vbuf+=$( printf '\033['${n}';20f''\e[1;31m     Deleted:    \e[1;33m'"${kext_name}"'\e[0m ' )
    fi

     DEL_KEXT_IN_PLIST

fi

}

CHECK_INSTALL_KEXTS(){

extension="${new_kext##*.}"

let "n++"; let "n++"

if [[ ${extension} = "kext" ]] || [[ ${extension} = "bundle" ]] || [[ ${extension} = "plugin" ]]; then 
    update_cache=1
    if [[ $loc = "ru" ]]; then
    vbuf+=$( printf '\033['${n}';7f''     Установлен:    \e[1;33m''\033['${n}';'$corr'f'"${new_kext}"'\033['${n}';54f''\e[0m    ver. \e[1;32m'${sver}'\033['${n}';70f''\e[0m' )
    else
    vbuf+=$( printf '\033['${n}';7f''      Installed:    \e[1;33m''\033['${n}';'$corr'f'"${new_kext}"'\033['${n}';54f''\e[0m    ver. \e[1;32m'${sver}'\033['${n}';70f''\e[0m' )
    fi
    if [[ ! $old_ver = "" ]]; then large_window=1;  vbuf+=$( printf ' -      was ver. \e[1;31m'$old_ver'\e[0m \n' else printf '\n' ) ; fi 
    
    echo $mypassword | sudo -S printf '' >/dev/null 2>/dev/null

    BACKUP_EXTENSION

    if [[ -d /Library/Extensions/"${new_kext}" ]] && [[ ! /Library/Extensions/"${new_kext}" = "/Library/Extensions/" ]]; then sudo rm -Rf /Library/Extensions/"${new_kext}"; fi
    sudo cp -a "${new_path}" /Library/Extensions
    sudo chown -R root:wheel /Library/Extensions/"${new_kext}"
    sudo chmod  -R 755 /Library/Extensions/"${new_kext}"
    ADD_KEXT_IN_PLIST

    else
    wait_on_exit=1
    if [[ $loc = "ru" ]]; then
    vbuf+=$( printf '\033['${n}';7f''\e[1;31m  НЕ установлен:    \e[1;33m''\033['${n}';'$corr'f'${new_kext}'\033['${n}';54f''\e[0m' )
    else
    vbuf+=$( printf '\033['${n}';7f''\e[1;31m  NOT Installed:    \e[1;33m''\033['${n}';'$corr'f'${new_kext}'\033['${n}';54f''\e[0m' )
    fi
fi
}

CREATE_TIMESTAMP(){
    TIME_STAMP=$( date +"%d-%m-%y"" (%H.%M)" )
if [[ -d ~/Desktop/"Replaced Extensions"/"Library Extensions"/"${TIME_STAMP}" ]]; then
  for ((b=1;b<10;b++)) do if [[ -d ~/Desktop/"Replaced Extensions"/"Library Extensions"/"${TIME_STAMP}" ]]; then TIME_STAMP=${TIME_STAMP:0:16}; TIME_STAMP+="-""${b}"; else break; fi; done
fi
}

BACKUP_EXTENSION(){
if [[ -d /Library/Extensions/"${new_kext}" ]]; then
if [[ ! -d ~/Desktop/"Replaced Extensions"/"Library Extensions"/"${TIME_STAMP}" ]]; then mkdir -p ~/Desktop/"Replaced Extensions"/"Library Extensions"/"${TIME_STAMP}"; fi
if [[ ! -d ~/Desktop/"Replaced Extensions"/"Library Extensions"/"${TIME_STAMP}"/"${new_kext}" ]]; then cp -a /Library/Extensions/"${new_kext}" ~/Desktop/"Replaced Extensions"/"Library Extensions"/"${TIME_STAMP}"; fi
fi
}

function ProgressBar {
let _progress=(${1}*100/${2}*100)/100
printf "\r    \033[20C\e[1;32m[ ${_progress}%% ] \e[0m"
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
old_ver="$(plutil -p /Library/Extensions/"${new_kext}"/Contents/Info.plist | grep CFBundleShortVersionString  | awk -F"=> " '{print $2}' | cut -c 2- | rev | cut -c 2- | rev )"
}

UPDATE_KERNEL_CACHE(){
osascript -e 'tell application "Terminal" to activate'
SET_INPUT
if [[ $large_window = 1 ]]; then sz=100; else sz=74; fi
let lines="path_count*2+12"; clear && printf '\e[8;'$lines';'$sz't' && printf '\e[3J' && printf "\033[H"
echo ${vbuf}
echo
echo
if [[ $loc = "ru" ]]; then
echo "       Обновить кэш (y/N) ?"
else
echo "       Update cache (y/N) ?"
fi
while true; do unset input; read  -s -r  -n 1 -t 1 input ; if [[ ! $input = "" ]]; then break; fi; done
printf '\r\033[1A'
if [[ ${input} = [yY] ]]; then 
wait_on_exit=1
if [[ $loc = "ru" ]]; then
printf '\e[1;36m     обновление кэша ядра  .... \e[0m'
else
printf '\e[1;36m     updating kernel cache .... \e[0m'
fi
rm -f ~/Desktop/KernelCacheUpdate.log.txt

printf "\r\033[33C"
spin="/|\\-/|\\-"; i=0
while :; do for i in `seq 0 7`;  do printf '\r\033[34C\e[1;32m'"${spin:$i:1}"; echo -en "\010\033[0m";  sleep 0.05; done; done &
trap "kill $!" EXIT 
sudo kextcache -i / &> ~/Desktop/KernelCacheUpdate.log.txt >/dev/null
kill $!
wait $! 2>/dev/null
trap " " EXIT
if [[ $loc = "ru" ]]; then
printf '\r\e[1;36m           кэш ядра обновлён                    \e[0m'
else
printf '\r\e[1;36m           kernel cache was updated             \e[0m'
fi
echo
echo
text_edit_flag=0
if [[ -f ~/Desktop/KernelCacheUpdate.log.txt ]]; then log=$(cat /Users/andrej/Desktop/KernelCacheUpdate.log.txt); if [[ ! $log = "" ]]; then
textedit_flag=1; open -a "TextEdit" -n  ~/Desktop/KernelCacheUpdate.log.txt; osascript -e 'tell application "Terminal" to activate'; fi
fi
if [[ $loc = "ru" ]]; then
printf '\r\n\e[1;36m           таймаут: \e[1;32m'
else
printf '\r\n\e[1;36m           timeout: \e[1;32m'
fi
printf "\r\033[18C"
spin="/|\\-/|\\-"; i=0
while :; do for i in `seq 0 7`;  do printf '\r\033[34C\e[1;32m'"${spin:$i:1}"; echo -en "\010\033[0m";  sleep 0.05; done; done &
trap "kill $!" EXIT
TIMEOUT
kill $!
wait $! 2>/dev/null
trap " " EXIT
printf '\e[0m\r''                                                                       \n\n'
fi
printf '\r                                \n'
printf '\r\033[6A'
printf "%"74"s"'\n'"%"74"s"'\n'"%"74"s"'\n'"%"74"s"'\n'
if [[ $wait_on_exit = 1 ]]; then  
osascript -e 'tell application "Terminal" to activate'
if [[ $loc = "ru" ]]; then
                printf '\n                                 Нажмите любую клавишу  '
                    else
                printf '\n                                     Press any key  '
                    fi
ANY_KEY

fi
if [[ $textedit_flag = 1 ]]; then
  textedit_now=$(ps -xao tty,pid,command | grep -v grep | grep "TextEdit" | wc -l | tr -d ' ')
  if [[ $textedit_now -gt 0 ]]; then let "textedit_count=textedit_now-1"
    if [[ $textedit_count = 0 ]]; then osascript -e 'tell app "TextEdit" to close first  window' && osascript -e 'quit app "TextEdit.app"' >/dev/null 2>/dev/null
        else
            osascript -e 'tell app "TextEdit" to close first  window' >/dev/null 2>/dev/null
    fi
  fi
fi
}

GET_ARGS(){
get_args="$(cat  ~/.patches.txt | tr '\n' ';' | xargs )"
all_path=(); var=0; m=1; while [[ $var = 0 ]]; do str="$(echo $get_args | cut -f"${m}" -d ';')"; if [[ ! $str = "" ]]; then all_path+=( "${str}" ); let "m++"; else break; fi; done
path_count=${#all_path[@]}
rm -f ~/.patches.txt

}

TRAIL_FOLDER(){
all_path_trailed=()
for ((l=0;l<$path_count;l++)) do 
new_path="$(echo "${all_path[l]}" | xargs)"; new_kext=$(echo "${new_path}" | sed 's|.*/||')
   if [[ ! -f "${new_path}" ]]; then 
     if [[ ! "${new_path}" = "/Library/Extensions" ]] &&  [[ ! "$( echo "${new_path}" | sed 's/[^/]*$//' )" = "/Library/Extensions/" ]];  then
      if [[ -d "${new_path}" ]]; then 
        if [[ -f "${new_path}"/Contents/Info.plist ]]; then all_path_trailed+=( "$(echo "${all_path[l]}" | xargs)" )
            else
                get_args="$( find "${new_path}" -maxdepth 1 -type d -not -path "${new_path}" | tr '\n' ';' | xargs )"
                folder_trailed=(); var=0; m=1; while [[ $var = 0 ]]; do str="$(echo $get_args | cut -f"${m}" -d ';')"; if [[ ! $str = "" ]]; then folder_trailed+=( "${str}" ); let "m++"; else break; fi; done
                folder_trailed_count=${#folder_trailed[@]}
                if [[ ! $folder_trailed_count = 0 ]]; then 
                    for ((i=0;i<$folder_trailed_count;i++)) do 
                    if [[ ! -f "$(echo "${folder_trailed[i]}" | xargs)" ]]; then
                        if [[ -f "$(echo "${folder_trailed[i]}" | xargs)"/Contents/Info.plist ]]; then  all_path_trailed+=( "$(echo "${folder_trailed[i]}" | xargs)" ); fi
                    fi
                    done
                fi
        fi
      fi
     fi
   fi
done
all_path=( "${all_path_trailed[@]}" ); path_count=${#all_path[@]}
}

INSTALL_KEXTS(){
osascript -e 'tell application "Terminal" to activate'
CREATE_TIMESTAMP
n=0; corr=0; vbuf=""; large_window=0
if [[ $loc = "ru" ]]; then
printf '\r\n\e[1;36m              Установка расширений: \e[1;32m'
else
printf '\r\n\e[1;36m         Installing the extensions: \e[1;32m'
fi
printf "\r\033[18C"
spin="/|\\-/|\\-"; i=0
while :; do for i in `seq 0 7`;  do printf '\r\033[38C\e[1;32m'"${spin:$i:1}"; echo -en "\010\033[0m";  sleep 0.05; done; done &
trap "kill $!" EXIT
for ((i=0;i<$path_count;i++)) do 
new_path="$(echo "${all_path[i]}" | xargs)"
new_kext=$(echo "${new_path}" | sed 's|.*/||'); p=${#new_kext}; let "corr=(36-p)/2+21"
GET_KEXT_INFO
CHECK_INSTALL_KEXTS
done
kill $!
wait $! 2>/dev/null
trap " " EXIT
printf '\e[0m\r''                                                                       \n\n'
}

GET_INSTALLED_STRING(){
UPDATE_CACHE
    if [[ ${cache} = 1 ]]; then strng=`echo "$KextLEconf" | grep -A 1 "<key>Installed</key>" | grep string | sed -e 's/.*>\(.*\)<.*/\1/' | tr -d '\n'`; fi
    if [[ ! $strng = "" ]]; then  IFS=';'; kmlist=( ${strng} ); unset IFS; kmcount=${#kmlist[@]}; file_list=""
                    for ((i=0;i<$kmcount;i++)) do old_kext="${kmlist[i]}"; file_list+='"'${old_kext}'"' ; if [[ ! $i = $(( $kmcount-1 )) ]]; then file_list+=","; fi ; done
            else kmlist=(); kmcount=0
    fi
}

ASK_FOLDER_TO_DELETE(){
from_list=0
 if [[ $loc = "ru" ]]; then prompt='"ВЫБЕРИТЕ ФАЙЛЫ ДЛЯ УДАЛЕНИЯ ИЗ /Library/Extensions:"'; else prompt='"SELECT FILES TO DELETE FROM /Library/Extensions:"'; fi

alias_string='"'"$(echo "$(diskutil info $(df / | tail -1 | cut -d' ' -f 1 ) |  grep "Volume Name:" | cut -d':'  -f 2 | xargs)")"':Library:Extensions"'
if answer=$(osascript -e 'tell application "Terminal" to (choose file default location alias '"${alias_string}"' with prompt '"${prompt}"' with multiple selections allowed)'); then cancel=0; else cancel=1; fi 2>/dev/null 
if [[ $answer = "" ]]; then cancel=1; else cancel=0
IFS=","; array=( $answer ); unset IFS; size=${#array[@]}; unset result; for ((i=0;i<$size;i++)) do result+="$(echo ${array[i]} | rev | cut -f2 -d ':' | rev)"; if [[ ! $i = $(( $size-1 )) ]]; then result+="," ; fi ;  done
fi
}

ASK_TO_DELETE_FROM(){
            
                if [[ $loc = "ru" ]]; then
             if answer=$(osascript -e 'display dialog "Выбрать файлы из /Library/Extensions или из списка ранее установленных?" '"${icon_string}"' buttons {"Удаление из системной папки", "Удаление через список", "Отмена" } default button "Удаление через список" '); then cancel=0; else cancel=1; fi 2>/dev/null
                                else
             if answer=$(osascript -e 'display dialog "Select files from / Library / Extensions or from a list of previously installed ones?" '"${icon_string}"' buttons {"Choose from the system folder", "Choose from the list", "Cancel" } default button "Choose from the list" '); then cancel=0; else cancel=1; fi 2>/dev/null
                                fi
        
             answer=$(echo "${answer}"  | cut -f2 -d':' )

            if [[ "${answer}" = "Удаление из системной папки" ]] || [[ "${answer}" = "Choose from the system folder" ]]; then ASK_FOLDER_TO_DELETE
                        elif [[ "${answer}" = "Удаление через список" ]] || [[ "${answer}" = "Choose from the list" ]]; then
                    from_list=1
                    if result=$(ASK_KEXTS_TO_DELETE); then cancel=0; else cancel=1; fi
                    if [[ $result = "false" ]]; then cancel=1; else cancel=0; fi
                        elif [[ "${answer}" = "Отмена" ]] || [[ "${answer}" = "Сancel" ]]; then cancel=2
             else
                    cancel=1
             fi
}


DELETE_KEXTS(){
           if ! GET_PASSWORD; then EXIT_PROGRAM; fi
           echo $mypassword | sudo -S printf '' >/dev/null 2>/dev/null
           IFS=","; tmlist=( ${result} ); unset IFS; tmcount=${#tmlist[@]}
           osascript -e 'tell application "Terminal" to activate'
           CREATE_TIMESTAMP
           n=0; corr=0 ; vbuf=""
        if [[ $from_list = 1 ]]; then 
           for ((i=0;i<$kmcount;i++)) do
           old_kext="${kmlist[i]}"
           for ((l=0;l<$tmcount;l++)) do if [[ "${old_kext}" = $(echo "${tmlist[l]}" | xargs) ]]; then  kext_name="${old_kext}"; DELETE_KEXT; break; fi ; done
           done
        else
           for ((l=0;l<$tmcount;l++)) do kext_name=$(echo "${tmlist[l]}" | xargs); DELETE_KEXT;  done
        fi
           if [[ $not_found = 0 ]]; then UPDATE_KERNEL_CACHE ; else SLEEP_READ 3 ; fi

}

SET_INPUT(){

layout_name=`defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | egrep -w 'KeyboardLayout Name' | sed -E 's/.+ = "?([^"]+)"?;/\1/' | tr -d "\n"`
xkbs=1

case ${layout_name} in
 "Russian"          ) xkbs=2 ;;
 "RussianWin"       ) xkbs=2 ;;
 "Russian-Phonetic" ) xkbs=2 ;;
 "Ukrainian"        ) xkbs=2 ;;
 "Ukrainian-PC"     ) xkbs=2 ;;
 "Byelorussian"     ) xkbs=2 ;;
 esac

if [[ $xkbs = 2 ]]; then 
cd "$(dirname "$0")"
    if [[ -f "./xkbswitch" ]]; then 
declare -a layouts_names
layouts=`defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleInputSourceHistory | egrep -w 'KeyboardLayout Name' | sed -E 's/.+ = "?([^"]+)"?;/\1/' | tr  '\n' ';'`
IFS=";"; layouts_names=($layouts); unset IFS; num=${#layouts_names[@]}
keyboard="0"

while [ $num != 0 ]; do 
case ${layouts_names[$num]} in
 "ABC"                ) keyboard=${layouts_names[$num]} ;;
 "US Extended"        ) keyboard="USExtended" ;;
 "USInternational-PC" ) keyboard=${layouts_names[$num]} ;;
 "U.S."               ) keyboard="US" ;;
 "British"            ) keyboard=${layouts_names[$num]} ;;
 "British-PC"         ) keyboard=${layouts_names[$num]} ;;
esac

        if [[ ! $keyboard = "0" ]]; then num=1; fi
let "num--"
done

if [[ ! $keyboard = "0" ]]; then ./xkbswitch -se $keyboard; fi
   else
        if [[ $loc = "ru" ]]; then
printf '\n\n                         ! Смените раскладку на латиницу !'
            else
printf '\n\n                          ! Change layout to UTF-8 ABC, US or EN !'
        fi
read -t 2 -n 2 -s
printf '\r                                                                               \r'
 printf "\r\n\033[3A\033[46C" ; if [[ $order = 3 ]]; then printf "\033[3C"; fi   fi

fi
}

WINDOW_ON(){ if [[ $window_visible = 0 ]]; then osascript -e 'tell application "Terminal" to set visible  of last  window to true'; window_visible=1; fi }

WINDOW_OFF(){ if [[ $window_visible = 1 ]]; then  osascript -e 'tell application "Terminal" to set miniaturized of front window to true'; window_visible=0; fi }


###################### main ##############################################################################################

clear

cd "$(dirname "$0")"; ROOT="$(dirname "$0")"

osascript -e "tell application \"Terminal\" to set the font size of window 1 to 12"
osascript -e "tell application \"Terminal\" to set background color of window 1 to {300, 9500, 16250}"
osascript -e "tell application \"Terminal\" to set normal text color of window 1 to {65535, 65535, 65535}"


clear && printf '\e[8;22;74t' && printf '\e[3J' && printf "\033[H"
loc=`defaults read -g AppleLocale | cut -d "_" -f1`
MyTTY=`tty | tr -d " dev/\n"`
term=`ps`;  MyTTYcount=`echo $term | grep -Eo $MyTTY | wc -l | tr - " \t\n"`
wait_on_exit=0
window_visible=1
printf "\033[?25l"
macos=$(sw_vers -productVersion | cut -f1-2 -d"." | tr -d '.')
if [[ "${macos}" = "1015" ]]; then 
  if ! GET_PASSWORD; then EXIT_PROGRAM; else sudo mount -uw / ; fi
fi
printf '\e[3J' && printf "\033[H"
printf '           \n'

if [[ ! -d  ~/Library/Application\ Support/KextLEinstaller ]]; then mkdir ~/Library/Application\ Support/KextLEinstaller; fi
if [[ ! -f ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist ]]; then
    echo '<?xml version="1.0" encoding="UTF-8"?>' >> ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist
    echo '<plist version="1.0">' >> ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist
    echo '<dict>' >> ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist
    echo '  <key>Installed</key>' >> ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist
    echo '  <string></string>' >> ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist
    echo '</dict>' >> ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist
    echo '</plist>' >> ~/Library/Application\ Support/KextLEinstaller/InstalledKext.plist
fi


if [[ ! -d  /Library/Extensions ]]; then 
    if ! GET_PASSWORD; then EXIT_PROGRAM; fi
    echo $mypassword | sudo -S printf '' >/dev/null 2>/dev/null
    sudo mkdir /Library/Extensions
    sudo chown -R root:wheel /Library/Extensions
    sudo chmod -R 755 /Library/Extensions
fi

UPDATE_CACHE

SET_INPUT

################ get args string ##########################################################

if [[ ! -f ~/.patches.txt ]]; then 
 

    var1=0; while [[ $var1 = 0 ]]; do

    WINDOW_OFF

             GET_APP_ICON

                                if [[ $loc = "ru" ]]; then
             if answer=$(osascript -e 'display dialog "Что собираемся предпринять?" '"${icon_string}"' buttons {"Удаление", "Установка", "Выход" } default button "Установка" '); then cancel=0; else cancel=1; fi 2>/dev/null
             if [[ "$(echo $answer | cut -f2 -d':')" = "Выход" ]]; then EXIT_PROGRAM; fi
                                else
             if answer=$(osascript -e 'display dialog "What are you going to do?" '"${icon_string}"' buttons {"Delete", "Install", "Exit" } default button "Install" '); then cancel=0; else cancel=1; fi 2>/dev/null
             if [[ "$(echo $answer | cut -f2 -d':')" = "Exit" ]]; then EXIT_PROGRAM; fi
                                fi
             if [[ $cancel = 1 ]]; then EXIT_PROGRAM; fi
        
             answer=$(echo "${answer}"  | cut -f2 -d':' )
            
if [[ "${answer}" = "Install" ]] || [[ "${answer}" = "Установка" ]]; then
       

    sleep 0.3
    open -W AskKexts.app

    clear && printf '\e[3J' && printf "\033[H"
    if [[ -f ~/.patches.txt ]]; then  

    WINDOW_ON

        no_kexts=0

        GET_ARGS

        if [[ ${path_count} = 0 ]]; then no_kexts=1; else TRAIL_FOLDER; fi
                if [[ ${path_count} = 0 ]]; then 
                    no_kexts=1
                 else 
                    if ! GET_PASSWORD; then EXIT_PROGRAM; fi
                    update_cache=0
                    INSTALL_KEXTS
                    if [[ $update_cache = 0 ]]; then no_kexts=1; else UPDATE_KERNEL_CACHE; fi
                 fi                                  
        if [[ ${no_kexts} = 1 ]]; then 
            clear && printf '\e[8;22;74t' && printf '\e[3J' && printf "\033[H"
                    if [[ $loc = "ru" ]]; then
            n=4
            printf '\033['${n}';0f''\e[1;33m     Не получены подходящие файлы для установки !    \e[0m '
                    else
            printf '\033['${n}';0f''\e[1;33m     No valid files to install found  !              \e[0m '
                    fi
            SLEEP_READ 3
        fi             
    fi
    
 else
    
    var3=0 
    while [[ $var3 = 0 ]]; do 

    GET_INSTALLED_STRING

    if [[ ! $strng = "" ]]; then  ASK_TO_DELETE_FROM

        if [[ $cancel = 2 ]]; then break; fi
        if [[ $cancel = 0 ]]; then  WINDOW_ON; DELETE_KEXTS ; break; fi

    else

         ASK_FOLDER_TO_DELETE
         if [[ $strng = "" ]] && [[ $cancel = 1 ]]; then break; fi
         if [[ $cancel = 0 ]]; then WINDOW_ON; DELETE_KEXTS; break; fi
    fi
    done
 fi
    clear && printf '\e[8;22;74t' && printf '\e[3J' && printf "\033[H"
    done
fi

############################# get args from file ###########################################

if [[ ! -f ~/.patches.txt ]]; then EXIT_PROGRAM; fi

GET_ARGS

if [[ ${path_count} = 0 ]]; then EXIT_PROGRAM; fi

#################### get kexts from folders ################################################

TRAIL_FOLDER

############################################################################################

if ! GET_PASSWORD; then EXIT_PROGRAM; fi

update_cache=0

INSTALL_KEXTS

if [[ $update_cache = 0 ]]; then EXIT_PROGRAM; fi

UPDATE_KERNEL_CACHE

EXIT_PROGRAM