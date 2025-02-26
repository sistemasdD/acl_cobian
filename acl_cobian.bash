#!/usr/bin/env bash

[ -t 1 ] && {

    _RED=$( tput setaf 1 ) 
    _RESET=$( tput sgr0 )
    _BLUE=$( tput setaf 159 )
    _PINK=$( tput setaf 219 )
}

checkBash ()
{
    [ -z "$BASH_VERSINFO" ] && {

        printf \
            "\n\t%s[!] %s must be run using bash %s or ./%s %s\n\n" \
            "$_RED" "${0##*/}" "${0##*/}" "${0##*/}" "$_RESET" \
            1>&2

        return 1
    }

    return 0
}

banner ()
{
    cat << BANNER
    $_BLUE 
    ██   ▄█▄    █      ▄▄▄▄▄   
    █ █  █▀ ▀▄  █     █     ▀▄ 
    █▄▄█ █   ▀  █   ▄  ▀▀▀▀▄   
    █  █ █▄  ▄▀ ███▄ ▀▄▄▄▄▀    
       █ ▀███▀      ▀          
      █                        
     ▀
    $_RESET
BANNER
}

checkDeps ()
{
    command -V "$1" &> /dev/null && return 0 || return 1
}

aclInstall ()
{
    (( $( id -u ) == 0 )) || {

        printf \
            "\n\t%s[!] It seems that this script is not running as Root %s\n\n" \
            "$_RED" "$_RESET"

        return 1
    }

    checkDeps "acl" || apt install --assume-yes -- acl &> /dev/null || return 1

    return 0
}

checkUser ()
{
    local -- _user=$1 _passwd= _hostname=$( hostname --long )
 
    id -u "$_user" &> /dev/null && return 0

    _passwd=$( cat /dev/urandom | tr -dc 'A-Za-z0-9@#%^&*()_' | head -c 30 )

    [[ -z $_passwd ]] && {

        printf \
            "\n\t%s[!] Could not generate the password for the user %s %s\n\n" \
            "$_RED" "$_user" "$_RESET" \
            1>&2

        return 1
    }

    useradd "$_user" &> /dev/null || {

        printf \
            "\n\t%s[!] The user %s could not be created :( %s \n\n" \
            "$_RED" "$_user" "$_RESET" \
            1>&2

        return 1 
    }

    chpasswd <<< "${_user}:$_passwd" && {

        printf \
            "\n%s[+] %s's Password ➔  %s %s\n" \
            "$_PINK" "$_user" "$_passwd" "$_RESET"

    } || return 1

    return 0
}

checkPlesk ()
{
    local -- _hostname=$( hostname --long )

    checkDeps "plesk" || {

        printf \
            "\n\t%s[!] It seems that Plesk is not installed in the %s %s\n\n" \
            "$_RED" "$_hostname" "$_RESET" \
            1>&2

        return 1
    }

    systemctl --quiet is-active psa.service &> /dev/null || {

        printf \
            "\n\t%s[!] Psa.service related to Plesk is not running in %s... :( %s\n\n" \
            "$_RED" "$_hostname" "$_RESET" \
            1>&2

        return 1
    }

    return 0
}

execACLs1 ()
{
    local -- _user=${1:-backupdd} _backupPath=${1:-/var/lib/psa/dumps} \
             _hostname=$( hostname --long )

    [[ $_user == 'backupdd' ]] || checkUser "$1" || return 1

    [[ -e $_backupPath ]] || {

        printf \
            "\n\t%s[!] %s path does not exist in %s %s \n\n" \
            "$_RED" "$_backupPath" "$_hostname" "$_RESET" \
            1>&2

        return 1
    }

    setfacl -m u:"${_user}":x "${_backupPath}"/ 2> /dev/null
    setfacl -m mask::x "${_backupPath}"/ 2> /dev/null
    setfacl -m u:"${_user}":rwx "${_backupPath}"/domains/ 2> /dev/null
    setfacl -m default:u:"${_user}":rwx "${_backupPath}"/domains/ 2> /dev/null
    setfacl -m mask::rwx "${_backupPath}"/domains/ 2> /dev/null
    setfacl -m default:mask::rwx "${_backupPath}"/domains/ 2> /dev/null

    return 0
}

execACLs2 ()
{
    local -- _user=${1:-backupdd} _backupPath=${1:-/var/lib/psa/dumps} \
             _hostname=$( hostname --long )

    [[ $_user == 'backupdd' ]] || checkUser "$1" || return 1

    [[ -e $_backupPath ]] || {

        printf \
            "\n\t%s[!] %s path does not exist in %s %s \n\n" \
            "$_RED" "$_backupPath" "$_hostname" "$_RESET" \
            1>&2

        return 1
    }

    shopt -q globstar ; _globstarStatus=$?
    shopt -q dotglob ; _dotglobStatus=$?

    (( _globstarStatus )) && shopt -s globstar
    (( _dotglobStatus )) && shopt -s dotglob

    setfacl -m u:"${_user}":rwx "${_backupPath}"/domains/** 2> /dev/null
    setfacl -m default:u:"${_user}":rwx "${_backupPath}"/domains/**/ 2> /dev/null
    setfacl -m mask::rwx "${_backupPath}"/domains/** 2> /dev/null
    setfacl -m default:mask::rwx "${_backupPath}"/domains/**/ 2> /dev/null

    (( _globstarStatus )) && shopt -u globstar
    (( _dotglobStatus )) && shopt -u dotglob

    return 0
}

main ()
{
    aclInstall || exit 99
    checkUser "backupdd" || exit 99
    checkPlesk || exit 99
    execACLs1 && { execACLs2 || exit 99 ; } || exit 99

    printf \
        "\n%s[+] ACLs applied recursively under /var/lib/psa/ for the user backupdd :) %s\n\n" \
        "$_PINK" "$_RESET"
}

banner

main
