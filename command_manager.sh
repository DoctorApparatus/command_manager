#!/bin/bash

DB_FILE="commands.db"

# Function to initialize the database
initialize_db() {
    sqlite3 $DB_FILE "CREATE TABLE IF NOT EXISTS saved_commands (name TEXT PRIMARY KEY, command TEXT);"
}

# Function to add a command to the database
add_command() {
    local name="$1"
    local cmd="$2"
    cmd=$(echo "$cmd" | sed "s/'/''/g")
    sqlite3 $DB_FILE "INSERT OR REPLACE INTO saved_commands (name, command) VALUES ('$name', '$cmd');"
    echo "Command saved successfully!"
}

# Function to list all saved commands
list_commands() {
    sqlite3 $DB_FILE "SELECT name FROM saved_commands;" | while read line; do
        echo "$line"
    done
}

# Function to retrieve a command by its name
get_command() {
    local name="$1"
    local cmd=$(sqlite3 $DB_FILE "SELECT command FROM saved_commands WHERE name='$name';")
    if [ -z "$cmd" ]; then
        echo "Command not found!"
    else
        echo "$cmd"
    fi
}

copy_command() {
    local name="$1"
    local cmd=$(sqlite3 $DB_FILE "SELECT command FROM saved_commands WHERE name='$name';")
    if [ -z "$cmd" ]; then
        echo "Command not found!"
    else
        echo -n "$cmd" | xclip -selection clipboard
    fi
}

edit_command() {
    local name="$1"
    local tmp_file=$(mktemp)

    # Retrieve the command from the database
    local cmd=$(sqlite3 $DB_FILE "SELECT command FROM saved_commands WHERE name='$name';")
    if [ -z "$cmd" ]; then
        echo "Command not found!"
        return
    fi

    # Write the command to a temporary file
    echo "$cmd" > "$tmp_file"

    # Open the command in the default editor
    ${EDITOR:-vi} "$tmp_file"

    # Read the edited command
    local edited_cmd=$(<"$tmp_file")
    edited_cmd=$(echo "$edited_cmd" | sed "s/'/''/g")


    # Save the edited command back to the database
    sqlite3 $DB_FILE "UPDATE saved_commands SET command='$edited_cmd' WHERE name='$name';"
    echo "Command updated successfully!"

    # Clean up
    rm "$tmp_file"
}

rename_command() {
    local old_name="$1"
    local new_name="$2"

    # Check if the command with the old name exists
    local cmd=$(sqlite3 $DB_FILE "SELECT command FROM saved_commands WHERE name='$old_name';")
    if [ -z "$cmd" ]; then
        echo "Command not found!"
        return
    fi

    # Rename the command in the database
    sqlite3 $DB_FILE "UPDATE saved_commands SET name='$new_name' WHERE name='$old_name';"
    echo "Command renamed successfully!"
}

select_command_rofi() {
	commands="$(list_commands)"
	command_name="$( echo "$commands" | rofi -dmenu -p "Select a command:" )"
	echo "$( get_command $command_name )" | xclip -selection clipboard
}

# Main program logic
initialize_db

case $1 in
    add)
        add_command "$2" "$3"
        ;;
    list)
        list_commands
        ;;
    get)
        get_command "$2"
        ;;
    copy)
        copy_command "$2"
        ;;
    edit)
        edit_command "$2"
        ;;
    rename)
        rename_command "$2" "$3"
        ;;
    rofi)
        select_command_rofi "$2"
        ;;
    *)
        echo "Usage: $0 {add|list|get} [args...]"
        ;;
esac
