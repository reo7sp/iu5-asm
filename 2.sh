#!/bin/bash
set -e


options() {
    echo '1) использовать команду type'
    echo '2) очистить экран'
    echo '3) справка'
    echo '4) автор'
    echo '5) выход'
}

opt_type() {
    if [[ -z $1 ]]; then
        echo 'необходим аргумент: название файла'
        return
    fi

    cat "$1"
}

opt_clear() {
    clear
}

opt_help() {
    echo './2.sh [НАЗВАНИЕ_ФАЙЛА_ДЛЯ_КОМАНДЫ_TYPE]'
}

opt_about() {
    echo 'Морозенков Олег ИУ5-42'
}

opt_exit() {
    exit 0
}


clear

while true; do
    options

    read cmd
    case $cmd in
        '1')
            opt_type "$1"
            ;;
        '2')
            opt_clear
            ;;
        '3')
            opt_help
            ;;
        '4')
            opt_about
            ;;
        '5')
            opt_exit
            ;;
        *)
            echo 'неизвестный пункт меню'
            ;;
    esac

    echo
done

