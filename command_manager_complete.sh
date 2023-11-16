#!/bin/bash

_command_manager_autocomplete() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="add list get edit rename execute"

    if [[ ${cur} == * ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

    if [[ ${prev} == execute || ${prev} == get || ${prev} == edit || ${prev} == rename ]]; then
        local commands=$(sqlite3 commands.db "SELECT name FROM saved_commands;")
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        return 0
    fi
}

_comp_command_manager() {
    local -a commands
    local cur

    cur=$2

    if (( CURRENT == 2 )); then
        commands=('add' 'list' 'get' 'edit' 'rename' 'execute')
        _describe 'command' commands
        return
    fi

    if (( CURRENT == 3 )) && [[ ${words[2]} == execute || ${words[2]} == get || ${words[2]} == edit || ${words[2]} == rename ]]; then
        local saved_commands
        saved_commands=($(sqlite3 commands.db "SELECT name FROM saved_commands;"))
        _describe 'saved_command' saved_commands
        return
    fi
}

complete -F _command_manager_autocomplete ./command_manager.sh
compdef _comp_command_manager command_manager.sh
