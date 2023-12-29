#!/usr/bin/env bash
#
# Created By: Jake@Linux
# Created On: Tue 31 Oct 2023 12:01:15 PM CDT
# Project: Void Linux Install Script


#     _            __       _    __      _     __
#    (_)___  _____/ /_____ | |  / /___  (_)___/ /
#   / / __ \/ ___/ __/ __ `/ | / / __ \/ / __  / 
#  / / / / (__  ) /_/ /_/ /| |/ / /_/ / / /_/ /  
# /_/_/ /_/____/\__/\__,_/ |___/\____/_/\__,_/   


### PRESET VARIABLES
#------------------#

# ...for outline menu
check_complete=false
greeting_complete=false
create_list_complete=false
part_func_complete=false
fs_complete=false
fs_mount_complete=false
fs_choice_complete=false
structure_sel_complete=false
arch_sel_complete=false


# ...for error checking
script_name="$(basename "$0")"
line_number="${BASH_LINENO[0]}"

# ...for filesystem and structure
useBtrFS=false
subvolumes=false

# ...Mirror (set to default for glibc, can be changed to select desired mirror)
#repoGlibc=https://repo-default.voidlinux.org/current


### FUNCTIONS
#-----------#

# ...handle errors
handle_error() {
    local exit_code=$?
    echo "Error in $script_name at line $line_number: Command failed with exit code ${exit_code}"
    exit ${exit_code}
}

# ...set up error handling
trap 'handle_error' ERR



# ...display incomplete/complete steps
steps() {
    echo -e "\e[32m$(figlet -f slant Outline)\e[0m"

    if [ "${check_complete}" = true ]; then
        echo -e "(1) Check Dependencies                 \e[32m[ Complete ]\e[0m"
    else
        echo -e "(1) Check Dependencies                 \e[31m[ Incomplete ]\e[0m"
    fi

    if [ "${greeting_complete}" = true ]; then
        echo -e "(2) Greeting                           \e[32m[ Complete ]\e[0m"
    else
        echo -e "(2) Greeting                           \e[31m[ Incomplete ]\e[0m"
    fi

    if [ "${create_list_complete}" = true ]; then
        echo -e "(3) Choose Device                      \e[32m[ Complete ]\e[0m Using Device: \e[31m${device}\e[0m"
    else
        echo -e "(3) Choose Device                      \e[31m[ Incomplete ]\e[0m"
    fi

    if [ "${fs_choice_complete}" = true ]; then
        echo -e "(4) Choose file system                 \e[32m[ Complete ]\e[0m Using: \e[31m${chosenFS}\e[0m"
    else
        echo -e "(4) Choose file system                 \e[31m[ Incomplete ]\e[0m"
    fi

    if [ "${structure_sel_complete}" = true ] || [[ "${chosenFS}" == Ext4 ]]; then
        echo -e "(5) File system structure select       \e[32m[ Complete ]\e[0m Structure: \e[31m${selection_choice}\e[0m"
    else
        echo -e "(5) File system structure select       \e[31m[ Incomplete ]\e[0m"
    fi

    if [ "${part_func_complete}" = true ]; then
        echo -e "(6) Partition                          \e[32m[ Complete ]\e[0m Current Partitions: \e[31m${efipart} ${rootpart} ${homepart}\e[0m"
    else
        echo -e "(6) Partition                          \e[31m[ Incomplete ]\e[0m"
    fi

    if [ "${fs_complete}" = true ]; then
        echo -e "(7) File System                        \e[32m[ Complete ]\e[0m"
    else
        echo -e "(7) File System                        \e[31m[ Incomplete ]\e[0m"
    fi

    if [ "${fs_mount_complete}" = true ]; then
        echo -e "(8) FS mounted                         \e[32m[ Complete ]\e[0m"
    else
        echo -e "(8) FS mounted                         \e[31m[ Incomplete ]\e[0m"
    fi

    if [ "${repo_choice_complete}" = true ]; then
        echo -e "(4) Choose repo                        \e[32m[ Complete ]\e[0m Using: \e[31m${chosenRepo}\e[0m"
    else
        echo -e "(4) Choose repo                        \e[31m[ Incomplete ]\e[0m"
    fi

    printf "\n"
}



# ...check for/install missing dependencies
check_deps() {
    clear
    missing_packages=()
    check_complete=false
    for cmd in figlet git sfdisk; do
        if ! command -v "${cmd}" >/dev/null 2>&1; then
            echo "Command ${cmd} is missing."
            missing_packages+=("${cmd}")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "Installing missing packages: ${missing_packages[*]}"
        pacman -S "${missing_packages[@]}" 
    fi
    check_complete=true
}


# ...greeting
greeting() {
    echo -e "\e[32m$(figlet -f slant instaVoid)\e[0m"
    echo -e "\e[36mVersion\e[0m: 1.0"
    echo -e "\e[36mDescription\e[0m: This script takes input from the user to completely install Void Linux.\n\n"
    greeting_complete=true
    printf "\n"
    read -rp "Press enter to continue"
    clear
}


# ...create device list to choose installation drive
create_dev_list() {
    steps
    echo -e "\e[32m$(figlet -f slant Available Devices)\e[0m"
    lsblk_output=$(lsblk)
    mapfile -t device_array < <(echo "${lsblk_output}" | awk '$0 ~ /^[a-z]/ {print $1}')
    echo "Select a device:"
    select device in "${device_array[@]}"; do
        case ${device} in
            "${device_array[@]}")
                read -rp "You chose ${device}, is this correct? [Y/y,N/n]: " answer
                if [[ ${answer} = [Y/y] ]];
                then
                    read -r "Press enter to continue"
                elif [[ ${answer} = [N/n] ]];
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


# ...display filesystem choices
fs_menu() {
    steps
    echo -e "\e[32m$(figlet -f slant Filesystem)\e[0m"
    echo "Choose a filesystem:"
    echo "1. Btrfs"
    echo "2. Ext4"
    echo "3. Quit"
}


# ...set filesystem true or false
set_filesystem() {
    read -rp "Enter your choice (1/2/3): " choice

    case ${choice} in
        1)
            useBtrFS=true
            ;;
        2)
            useBtrFS=false
            ;;
        3)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, or 3."
            set_filesystem
            ;;
    esac
    fs_choice_complete=true
    if [[ "${choice}" == 1 ]];
    then
        chosenFS=Btrfs
    elif [[ "${choice}" == 2 ]];
    then
        chosenFS=Ext4
        selection_choice=Partitions  
    fi
}


# ...partition structure menu
structure_menu() {
    clear
    steps
    echo "Choose file system structure:"
    echo "1. Subvolumes"
    echo "2. Partitions"
    echo "3. Quit"
}


# ...set structure true or false
set_structure() {
    read -rp "Enter your choice (1/2/3): " selection
    case ${selection} in
        1)
            subvolumes=true
            ;;
        2)
            subvolumes=false
            ;;
        3)
            echo "Exiting"
            exit 0
            ;;
    esac
    structure_sel_complete=true
    if [[ "${selection}" == 1 ]];
    then
        selection_choice=Subvolumes
    elif [[ "${selection}" == 2 ]];
    then
        selection_choice=Partitions
    fi
}


# ...partition selected device using multiple partitions
part_func_noSubVol() {
    clear
    steps
    echo -e "\e[32m$(figlet -f slant Partition Drive)\e[0m"
    read -rp "Enter partition sizes in this order, efi root home, separated by spaces with no commas: " parts
    IFS=" " read -r efipart rootpart homepart <<< "${parts}"

    sfdisk /dev/"${device}" << EOF
label: GPT
,
EOF

sudo sfdisk /dev/"${device}" << EOF
, "${efipart}"
, "${rootpart}"
, "${homepart}"
EOF

part_func_complete=true
}

part_func_withSubVol() {
    clear
    steps
    echo -e "\e[32m$(figlet -f slant Partition Drive)\e[0m"
    read -rp "Now partitioning for Btrfs with subvolumes, there will be 2 partitions, boot partition of 1G and second partition for the system with the rest of the disk.\n
do you want to continue? [Y/y, N/n]: " response
    if [[ "${response}" == [Y/y] ]]; then
        sfdisk /dev/"${device}" << EOF
label: GPT
,
EOF


sfdisk /dev/"${device}" << EOF
, 1G
,
EOF

else
    fs_menu
    fi

    part_func_complete=true
}

fs_install() {
    steps
    if [[ "${useBtrFS}" == true ]];
    then
        if [[ "${subvolumes}" == false ]];
        then
            if [[ ${device} = sd?* ]];
            then
                mkfs.fat -F 32 -n BOOT /dev/"${device}"1
                mkfs.btrfs -L ROOT /dev/"${device}2"
                mkfs.btrfs -L HOME /dev/"$device}3"
            elif [[ $device = nvme??? ]];
            then
                mkfs.fat -F 32 -L BOOT /dev/"${device}p1"
                mkfs.btrfs -L ROOT /dev/"${device}p2"
                mkfs.btrfs -L HOME /dev/"${device}p3"
            fi
        else
            if [[ ${device} = sd?* ]];
            then
                mkfs.fat -F 32 -n BOOT /dev/"${device}1"
                mkfs.btrfs /dev/"${device}2"
            elif [[ $device = nvme??? ]];
            then
                mkfs.fat -F 32 -n BOOT /dev/"${device}p1"
                mkfs.btrfs /dev/"${device}p2"
            fi
        fi
    else
        if [[ ${device} = sd?* ]];
        then
            mkfs.fat -F 32 -n BOOT /dev/"${device}1"
            mkfs.ext4 -L ROOT /dev/"${device}2"
            mkfs.ext4 -L HOME /dev/"${device}3"
        elif [[ ${device} = nvme??? ]];
        then
            mkfs.fat -F 32 -L BOOT /dev/"${device}p1"
            mkfs.ext4 -L ROOT /dev/"${device}p2"
            mkfs.ext4 -L HOME /dev/"${device}p3"
        fi
    fi
    lsblk -f
    fs_complete=true
}


# ...mount file system
fs_mount() {
    steps
    if [[ ${device} = sd?* ]];
    then
        mount -L ROOT /mnt/
        mkdir -p /mnt/boot/efi
        mkdir -p /mnt/home
        mount -L BOOT /mnt/boot/efi/
        mount -L HOME /mnt/home/
    elif [[ ${device} = nvme??? ]];
    then 
        mount /dev/"${device}p2" /mnt/
        mkdir -p /mnt/boot/efi
        mkdir /mnt/home
        mount /dev/"${device}p1" /mnt/boot/efi/
        mount /dev/"${device}p3" /mnt/home/
    fi
    fs_mount_complete=true
}


repo() {
    steps
    echo -e "\e[32m$(figlet -f slant Repo)\e[0m"
    echo "Choose a repo:"
    echo "1. Glibc"
    echo "2. Musl"
    echo "3. Quit"
    read -rp "Enter your choice (1/2/3): " choice

    case ${choice} in
        1)
            REPO=https://repo-default.voidlinux.org/current
            ;;
        2)
            REPO=https://repo-default.voidlinux.org/current/musl
            ;;
        3)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, or 3."
            repo
            ;;
    esac
    repo_choice_complete=true
    if [[ "${choice}" == 1 ]];
    then
        chosenRepo=Glibc
    elif [[ "${choice}" == 2 ]];
    then
        chosenRepo=Musl  
    fi
}


###########  FIX THIS FUNCTION FIRST   ###########




Arch() {
    steps
    echo -e "\e[32m$(figlet -f slant Architecture)\e[0m"
    echo "Choose an architecture:"
    echo "1. x86_64"
    echo "2. x86_64-musl"
    echo 
    echo "3. Quit"
    read -rp "Enter your choice (1/2/3): " choice

    case ${choice} in
        1)
            REPO=https://repo-default.voidlinux.org/current
            ;;
        2)
            REPO=https://repo-default.voidlinux.org/current/musl
            ;;
        3)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, or 3."
            repo
            ;;
    esac
    arch_choice_complete=true
    if [[ "${choice}" == 1 ]];
    then
        chosenArch=Glibc
    elif [[ "${choice}" == 2 ]];
    then
        chosenRepo=Musl  
    fi
}


# ...main function calling all other functions
main() {
    check_deps
    greeting
    create_dev_list
    fs_menu
    set_filesystem
    if [[ "${useBtrFS}" == false ]];
    then
        part_func_noSubVol
    else
        structure_menu
        set_structure
        if [[ "${subvolumes}" == false ]];
        then
            part_func_noSubVol
        else
            part_func_withSubVol
        fi
    fi
    fs_install
    fs_mount


}


### CALLING MAIN TO RUN SCRIPT
#----------------------------#

# ...main function/run script
main

