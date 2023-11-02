#!/usr/bin/env bash
#
# Created By: Jake@Linux
# Created On: Tue 31 Oct 2023 12:01:15 PM CDT
# Project: Void Linux Install Script

greeting_complete=false
create_list_complete=false
part_func_complete=false

check_deps(){
    missing_packages=()
    check_complete=false
    # Check for missing commands and add them to the list
    for cmd in figlet git sfdisk; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Command $cmd is missing."
            missing_packages+=("$cmd")
        fi
    done

    # Install missing packages if any
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "Installing missing packages: ${missing_packages[*]}"
        pacman -S "${missing_packages[@]}" 
    fi
    check_complete=true
}

greeting(){
    echo -e "\e[32m$(figlet -f slant instaVoid)\e[0m"
    echo -e "\e[36mVersion\e[0m: 1.0"
    echo -e "\e[36mDescription\e[0m: This script takes input from the user to completely install Void Linux.\n\n"
    greeting_complete=true
    printf "\n"
    read -rp "Press enter to continue"
    clear
}

steps(){
    echo -e "\e[32m$(figlet -f slant Outline)\e[0m"
    if [ "$greeting_complete" = true ]; then
        echo -e "1: Greeting..............\e[32m[ Complete ]\e[0m"
    else
        echo -e "1: Greeting............\e[31m[ Incomplete ]\e[0m"
    fi
    if [ "$check_complete" = true ]; then
        echo -e "2: Check Dependencies....\e[32m[ Complete ]\e[0m"
    else
        echo -e "2: Check Dependencies....\e[31m[ Incomplete ]\e[0m"
    fi
    if [ "$create_list_complete" = true ]; then
        echo -e "3: Choose Device.........\e[32m[ Complete ]\e[0m Using Device: \e[31m$device\e[0m"
    else
        echo -e "3: Choose Device.........\e[31m[ Incomplete ]\e[0m"
    fi
    if [ "$part_func_complete" = true ]; then
        echo -e "4: Partition.............\e[32m[ Complete ]\e[0m Current Partitions: \e[31m$efipart $rootpart $homepart\e[0m"
    else
        echo -e "4: Partition.............\e[31m[ Incomplete ]\e[0m"
    fi
    if [ "$fs_complete" = true ]; then
        echo -e "5: File System...........\e[32m[ Complete ]\e[0m Current Partitions: \e[31m$efipart $rootpart $homepart\e[0m"
    else
        echo -e "5: File System...........\e[31m[ Incomplete ]\e[0m"
    fi
    printf "\n"
    read -rp "Press enter to continue"
    clear
}

create_dev_list(){
    echo -e "\e[32m$(figlet -f slant Partition)\e[0m"
    lsblk_output=$(lsblk)
    mapfile -t device_array < <(echo "$lsblk_output" | awk '$0 ~ /^[a-z]/ {print $1}')
# Display a menu with device options
    echo "Select a device:"
    select device in "${device_array[@]}"; do
        case $device in
            "${device_array[@]}")
                read -rp "You chose $device, is this correct? [Y/y,N/n]: " answer
                if [[ $answer = [Y/y] ]];
                then
                    read -r "Press enter to continue" read
                elif [[ $answer = [N/n] ]];
                then
                    clear
                    create_dev_list
                fi
                break
                ;;
            *)
                echo "Invalid selection"
                ;;
        esac
    done
    create_list_complete=true
    clear
}

# partition selected device
part_func(){
    echo -e "\e[32m$(figlet -f slant Partition Drive)\e[0m"
    read -rp "Enter partition sizes in this order, efi root home, separated by spaces with no commas: " parts
    IFS=" " read -r efipart rootpart homepart <<< "$parts"

    sfdisk /dev/"$device" << EOF
label: GPT
,
EOF

sudo sfdisk /dev/"$device" <<EOF
, "$efipart"
, "$rootpart"
, "$homepart"
EOF

part_func_complete=true
}

# install file system
fs_install () {
    fs_complete=false
    # Format the partitions
    mkfs.vfat /dev/"$device"1  # Format the first partition as FAT32
    mkfs.ext4 /dev/"$device"2  # Format the second partition as ext4
    mkfs.ext4 /dev/"$device"3  # Format the third partition as ext4

    # Display the filesystems of the created partitions
    lsblk -f
    fs_complete=true
}

check_deps
greeting
steps
create_dev_list
steps
part_func
steps
