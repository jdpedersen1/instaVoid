#!/usr/bin/env bash
#
## Created By: Jake@Linux
# Created On: Tue 24 Oct 2023 05:36:46 PM CDT
# # Project: install script project

# MENU #
# 1: Functions
# 2: Program check
# 3: Greeting
# 4: Variables


###----------------------------------------------------------------------------- 1
##
#

  ###---- 1 ----###
 ### Functions ###
####-----------###

# prints colored text
color_text () {

    if [ "$2" == "info" ] ; then
        COLOR="96m";
    elif [ "$2" == "success" ] ; then
        COLOR="92m";
    elif [ "$2" == "warning" ] ; then
        COLOR="93m";
    elif [ "$2" == "danger" ] ; then
        COLOR="91m";
    else #default color
        COLOR="0m";
    fi

    STARTCOLOR="\e[$COLOR";
    ENDCOLOR="\e[0m";

    printf "$STARTCOLOR%b$ENDCOLOR" "$1";
}

# partitions selected device
partfunc () {
    sfdisk /dev/"$device" << EOF
label: GPT
,
EOF

sudo sfdisk /dev/"$device" <<EOF
, "$efipart"
, "$rootpart"
, "$homepart"
EOF
}

# install file system
fs_install () {
    # Format the partitions
    mkfs.vfat /dev/"$device"1  # Format the first partition as FAT32
    mkfs.ext4 /dev/"$device"2  # Format the second partition as ext4
    mkfs.ext4 /dev/"$device"3  # Format the third partition as ext4

    # Display the filesystems of the created partitions
    lsblk -f
}

# mount file system
fs_mount () {
    mount /dev/"$device"2 /mnt/
    mkdir -p /mnt/boot/efi
    mkdir -p /mnt/home
    mount /dev/"$device"1 /mnt/boot/efi/
    mount /dev/"$device"3 /mnt/home/
}

keys () {
    mkdir -p /mnt/var/db/xbps/keys
    cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
} 

base_install () {
    XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system
}

# Pre-defined variables
create_vars () {
    REPO=https://repo-default.voidlinux.org/current
    ARCH=x86_64

    # Prompting user for input to create variables
    read -rp "Which device would you like to partition?: /dev/" device
    read -rp "Enter partition sizes in this order, efi root home, separated by spaces with no commas: " parts
    read -rp "Specify your desired username: " userName
    read -rp "Give your new system a hostname: " hostName


    # Input Field Separator to separate user input from partition size prompt into 3 separate variables
    IFS=" " read -r efipart rootpart homepart <<< "$parts"
}


# Title of script
echo -e "\e[32m$(figlet -f slant instaVoid)\e[0m"
# Version and Description
echo -e "Version: 1.0"
echo -e "Description: Interactive Void Linux Install Script"
echo -e "\nPress Enter to continue..."
read -r




###---------------------------------------------------------------------------- 2
##
#

  ###------------ 2 --------------###     
 ### Check for required programs ###
###-----------------------------###

  if ! command -v sfdisk &> /dev/null
  then
      echo "please install sfdisk"
      exit 1
  fi


###----------------------------------------------------------------------------- 3
##
#

  ###----------- 3 -----------###
 ### Greeting and directions ###
###-------------------------###

# Print welcome message
color_text "WELCOME TO THE VOID LINUX INSTALL SCRIPT!\nThis script will partition your drive for you, it will make 3 partitions, efi, root, and home\n\n" "warning"

# List devices available to partition
lsblk
printf "\n\n"

# Directions on how to enter partition sizes
color_text "When selecting partition sizes in GB\nex: 5G 1.5G 10G\n\n"

###---------------------------------------------------------------------------- 5
##
#

# Partition function
create_vars
partfunc
printf "\n"

# List devices again to verify partition correctly set up
lsblk
fs_install
fs_mount
keys
base_install
