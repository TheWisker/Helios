#!/bin/bash
# <==============================================>

#   ██╗  ██╗███████╗██╗     ██╗ ██████╗ ███████╗
#   ██║  ██║██╔════╝██║     ██║██╔═══██╗██╔════╝
#   ███████║█████╗  ██║     ██║██║   ██║███████╗
#   ██╔══██║██╔══╝  ██║     ██║██║   ██║╚════██║
#   ██║  ██║███████╗███████╗██║╚██████╔╝███████║
#   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚══════╝

# <==============================================>
#                @Author: TheWisker
# <==============================================>
#    Arch-linux based personal distro installer
# <==============================================>
#  Change directory to that of the script
# <==============================================>
cd "$(dirname "$0")"
# <==============================================>
#  [Procedures] Log:
# <==============================================>
# Specify name of the log files
# <==============================================>
export logfile_in="./helios.in.log"
export logfile_out="./helios.out.log"
# <==============================================>
# Clear $logfile creating it if it does not exist
# <==============================================>
> $logfile_out
# <==============================================>
#  [Functions] Log:
# <==============================================>
# Enable log
# <==============================================>
log () {
	# Redirect /dev/fd/3 to the console and stdout and stderr in append mode to $logfile_out
	exec 3>&1 1>>${logfile_out} 2>&1
}
# <==============================================>
# Disable log
# <==============================================>
unlog () {
	# Redirect stdout and stderr to the console and /dev/fd/3 in append mode to $logfile_out
	exec 1>&3 3>>${logfile_out} 2>&1
}
# <==============================================>
#  [Variables] Title & Separator & Colors:
# <==============================================>
title="
  ██╗  ██╗███████╗██╗     ██╗ ██████╗ ███████╗
  ██║  ██║██╔════╝██║     ██║██╔═══██╗██╔════╝
  ███████║█████╗  ██║     ██║██║   ██║███████╗
  ██╔══██║██╔══╝  ██║     ██║██║   ██║╚════██║
  ██║  ██║███████╗███████╗██║╚██████╔╝███████║
  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚══════╝
"
# <==============================================>
export separator="<==============================================>"
# <==============================================>
export color_off='\033[0m'
export color_black='\033[1;30m'
export color_red='\033[1;31m'
export color_green='\033[1;32m'
export color_yellow='\033[1;33m'
export color_blue='\033[1;34m'
export color_purple='\033[1;35m'
export color_cyan='\033[1;36m'
export color_white='\033[1;37m'
# <==============================================>
#  [Functions] Input & Output:
# <==============================================>
# Get some input in a formatted way
# <==============================================>
input () {
	local color="color_$3"
	echo -ne "${!color}${2}" | tee /dev/fd/3
	read "$1" && echo ${!1} # Makes read input appear in logfile
	[[ "${4}" != "!" ]] && output $separator cyan !
	return 0
}
# <==============================================>
# Display some formatted output
# <==============================================>
output () {
	local color="color_$2"
	echo -e "${!color}${1}${color_off}" | tee /dev/fd/3
	[[ "${3}" != "!" ]] && output $separator cyan !
	return 0
}
# <==============================================>
#  [Function] UEFI:
# <==============================================>
# Check if currently in UEFI as it is required
# <==============================================>
c_efi () {
	output "\n[Unified Extensible Firmware Interface]" purple

	output "~ Checking if the host is booted in UEFI mode..." yellow

	# <==============================================>
	#  Check if we booted in UEFI mode:
	# <==============================================>
	if [ ! -e /sys/firmware/efi/fw_platform_size ]; then
		output "\n> Host has not booted in UEFI mode, thus, it is assumed to not be UEFI capable!" red !
		#exit 1
	fi

	output "# Booted in UEFI x$(cat /sys/firmware/efi/fw_platform_size) mode!" green

	output "[Unified Extensible Firmware Interface]" purple !
	return 0
}
# <==============================================>
#  [Function] Network & Time:
# <==============================================>
# Check if currently connected to internet
# <==============================================>
c_net () {
	output "\n[Network & Time]" purple

	output "~ Checking if host archlinux.org is reachable\n~ As to assert network connectivity..." yellow

	# <==============================================>
	#  Ping to check network and dns avaiability:
	# <==============================================>
	if ! ping archlinux.org -c 2 -q -W 4; then
		output "\n> Host archlinux.org is not reachable, thus, host may not have a proper network connection!" red !
		exit 1
	fi

	output "# Network is proper!" green

	output "~ Checking if host is synchronized with an NTP server\n~ As to assert time accuracy..." yellow

	# <==============================================>
	#  Check if time is synchronized with NTP server:
	# <==============================================>
	if [[ "$(timedatectl show --property=NTPSynchronized | grep -c 'yes')" != "1" ]]; then
		output "\n> Host is not synchronized with an NTP server, thus, the system time ($(date)) may not be accurate!" red !
		exit 1
	fi

	output "# Time is proper!" green

	output "[Network & Time]" purple !
	return 0
}
# <==============================================>
#  [Function] Partitions & Filesystems:
# <==============================================>
# Partition and format the target device
# <==============================================>
c_part () {
	output "\n[Partitions & Filesystems]" purple

	# Print current devices table
	output "$(lsblk -o NAME,PARTLABEL,LABEL,FSTYPE,SIZE)" blue

	# <==============================================>
	#  Prompt for installation target device:
	# <==============================================>
	input device ">> Target device: /dev/" cyan
	export device="/dev/$device"
	# Check if $device is not a block device, i.e., not a device
	if [ ! -b "$device" ]; then
		output "\nDevice ${device} has no matching block device file, thus, it is not a valid device!" red !
		exit 2
	fi

	# <==============================================>
	#  Prompt for backup partition:
	# <==============================================>
	input device_bk ">> Backup partition: /dev/" cyan
	export device_bk="/dev/$device_bk"
	# Check if $device_bk is not a block device, i.e., not a device
	if [ ! -b "$device_bk" ]; then
		output "\nDevice ${device_bk} has no matching block device file, thus, it is not a valid device!" red !
		exit 2
	fi

	# <==============================================>
	#  Prompt for external partitions:
	# <==============================================>
	input device_ex1 ">> External partition one: /dev/" cyan
	export device_ex1="/dev/$device_ex1"
	# Check if $device_ex1 is not a block device, i.e., not a device
	if [ ! -b "$device_ex1" ]; then
		output "\nDevice ${device_ex1} has no matching block device file, thus, it is not a valid device!" red !
		exit 2
	fi
	input device_ex2 ">> External partition two: /dev/" cyan
	export device_ex2="/dev/$device_ex2"
	# Check if $device_ex2 is not a block device, i.e., not a device
	if [ ! -b "$device_ex2" ]; then
		output "\nDevice ${device_ex2} has no matching block device file, thus, it is not a valid device!" red !
		exit 2
	fi

	output "$ This action will erase all data on device ${device}!" red

	# <==============================================>
	#  Prompt for confirmation as its final:
	# <==============================================>
	input confirm ">> Do you still wish to proceed? [y/N]: " cyan
	if [ ! "${confirm,,}" = "y" ]; then
		output "\nInstallation aborted!" red !
		exit 0
	fi

	output "~ Discarding all sectors for device ${device}..." yellow

	# <==============================================>
	#  Command to discard all device blocks:
	# <==============================================>
	# Only use with Flash Disks (SSDs and NVMes)!
	# <==============================================>
	blkdiscard -f $device || return 2

	output "# Sectors discarded successfully!" green

	output "~ Partitioning the device..." yellow

	# <==============================================>
	#  Scripted disk partititon:
	# <==============================================>
	# Table-length refers to the maximum number of gpt partitions for the disk
	# <==============================================>
	# Sector-size should be equal to the output with the best relative performance:
	# (nvme-cli) $ nvme id-ns -H /dev/nvmeXnY | grep "Relative Performance"
	# <==============================================>
	# The names refer to the gpt partition label and can and will be used to identify
	# the partitions whichever filesystem they may be formatted with
	# <==============================================>
	sfdisk --wipe always --color $device <<- EOF
		label:gpt
		unit:sectors
		table-length:8
		sector-size:4096
		name="ESP", size=1G, type=uefi
		name="Archy", size=+, type=linux
	EOF

	output "# Device partitioned successfully!" green

	output "~ Making filesystems for the partitions..." yellow

	# <==============================================>
	#  Make filesystems for the partitions:
	# <==============================================>
	# Check (-c) the device for bad blocks before creating the filesystem
	# <==============================================>
	# Sector-size (-S | --sectorsize) should be equal to the output with the best relative performance:
	# (nvme-cli) $ nvme id-ns -H /dev/nvmeXnY | grep "Relative Performance"
	# <==============================================>
	# The names (-n) refer to the filesystem label and can and will be used to identify
	# the partitions while not reformatted or relabeled
	# <==============================================>
	# Do not perform whole device TRIM operation (-K) on devices that are capable of that
	# We disable this option as we have already performed a whole device TRIM operation with blkdiscard
	# <==============================================>
	mkfs.fat -c -F 32 -S 4096 -n "ESP" ${device}p1 || return 2
	mkfs.btrfs -K --sectorsize 4096 -L "Archy" ${device}p2 || return 2

	output "# Filesystems made successfully!" green

	output "~ Mounting BTRFS partition at for subvolume creation..." yellow

	# <==============================================>
	#  Mount btrfs partition for creating subvolumes:
	# <==============================================>
	# Make (-m) any missing parent directories
	# <==============================================>
	mount -m ${device}p2 /mnt || return 2

	output "# Partition mounted successfully!" green

	output "~ Creating subvolumes for BTRFS partition..." yellow

	# <==============================================>
	#  Creation of btrfs subvolumes:
	# <==============================================>
	# Create any missing parent (-p) directories
	# <==============================================>
	btrfs subvolume create /mnt/@arch || return 2 # Mount: /
	btrfs subvolume create /mnt/@home || return 2 # Mount: /home
	btrfs subvolume create /mnt/@root || return 2 # Mount: /root
	btrfs subvolume create /mnt/@cache || return 2 # Mount: /var/cache
	btrfs subvolume create /mnt/@tmp || return 2 # Mount: /var/tmp
	btrfs subvolume create /mnt/@log || return 2 # Mount: /var/log
	btrfs subvolume create /mnt/@snap || return 2 # Mount: /var/snap
	btrfs subvolume create /mnt/@swap || return 2 # Mount: /var/swap
	btrfs subvolume create /mnt/@srv || return 2 # Mount: /srv
	btrfs subvolume create /mnt/@shr || return 2 # Mount: /media/shr
	btrfs subvolume set-default /mnt/@shr || return 2 # When mounting the btrfs partition default to mounting the @shr subvolume

	output "# Subvolumes created successfully!" green

	output "~ Unmounting BTRFS partition with new subvolumes..." yellow

	# <==============================================>
	#  Unmount btrfs partition:
	# <==============================================>
	umount /mnt || return 2

	output "# Partition unmounted successfully!" green

	# Print new devices table
	output "$(lsblk -o NAME,PARTLABEL,LABEL,FSTYPE,SIZE)" blue

	# Pause until key is pressed
	input pause ">> Press *Enter* to continue..." cyan

	output "[Partitions & Filesystems]" purple !
	return 0
}
# <==============================================>
#  [Function] Mounts & Swapfile:
# <==============================================>
# Mount device structure and make swapfile
# <==============================================>
c_mnt() {
	output "\n[Mounts & Swapfile]" purple

	# <==============================================>
	#  Mount options for the partitions:
	# <==============================================>
	# rw: Mount the partition in read-write mode
	# exec: Allow executing binaries in the partition
	# dev: Allow device and special files in the partition
	# suid: Allow executable files to run with the permissions of the file's owner or group
	# async: Allow to perform write operations asynchronously
	# noatime: Do not update node access time
	# nodiratime: Do not update directory node access time
	# nouser: Only the root is allowed to mount the filesystem
	# <==============================================>
	mnt_opts='rw,exec,dev,suid,async,noatime,nodiratime,nouser'
	# <==============================================>
	# noautodefrag: do not defrag as its a Flash Disk (SSDs or NVMes) and it breaks COW (Linux kernel versions < 3.9 or ≥ 3.14-rc2 as well as with Linux stable kernel versions ≥ 3.10.31, ≥ 3.12.12 or ≥ 3.13.4)
	# commit=120: Flush data to disk every 120 seconds as to improve troughput by sacrificing write security in case of unexpected shutdown
	# datacow: Enable data copy-on-write for newly created files
	# datasum: Enable data checksumming for newly created files
	# compress-force=zstd:1: Compress files with zstd at level 1 (lowest) always
	# space_cache=v2: Greatly improves performance when reading block group free space into memory. However, managing the space cache consumes some resources, including a small amount of disk space
	# discard=async: Enable asynchronous TRIM for the partition
	# thread_pool=8: The number of worker threads to start
	# ssd: Specify that the device in use is an SSD in order to treat it accordingly
	# <==============================================>
	mnt_opts_btrfs="$mnt_opts,noautodefrag,commit=120,datacow,datasum,compress-force=zstd:1,space_cache=v2,discard=async,thread_pool=8"

	output "~ Mounting ESP and BTRFS subvolumes..." yellow

	# <==============================================>
	#  Mount btrfs subvolumes to respective paths:
	# <==============================================>
	# Make (-m) any missing parent directories
	# <==============================================>
	# Use the specified mount options (-o)
	# <==============================================>
	mount -m ${device}p2 /mnt -o subvol='@arch',$mnt_opts_btrfs,ssd || return 2
	mount -m ${device}p2 /mnt/home -o subvol='@home',$mnt_opts_btrfs,ssd || return 2
	mount -m ${device}p2 /mnt/root -o subvol='@root',$mnt_opts_btrfs,ssd || return 2
	mount -m ${device}p2 /mnt/var/cache -o subvol='@cache',$mnt_opts_btrfs,ssd || return 2
	mount -m ${device}p2 /mnt/var/tmp -o subvol='@tmp',$mnt_opts_btrfs,ssd || return 2
	mount -m ${device}p2 /mnt/var/log -o subvol='@log',$mnt_opts_btrfs,ssd || return 2
	mount -m ${device}p2 /mnt/var/snap -o subvol='@snap',$mnt_opts_btrfs,ssd || return 2
	mount -m ${device}p2 /mnt/var/swap -o subvol='@swap',$mnt_opts_btrfs,ssd || return 2
	mount -m ${device}p2 /mnt/srv -o subvol='@srv',$mnt_opts_btrfs,ssd || return 2
	mount -m ${device}p2 /mnt/media/shr -o subvol='@shr',$mnt_opts_btrfs,ssd || return 2
	# <==============================================>
	#  Mount esp partition:
	# <==============================================>
	mount -m ${device}p1 /mnt/boot -o $mnt_opts,nosuid,nodev || return 2
	# <==============================================>
	#  Mount internal backup disk:
	# <==============================================>
	mount -m ${device_bk} /mnt/var/bak -o $mnt_opts_btrfs,nodiscard,nosuid,nodev,noexec || return 2
	# <==============================================>
	#  Mount external disks:
	# <==============================================>
	mount -m ${device_ex1} "/mnt/media/$(e2label $device_ex1 | grep -oP -m 1 "labelled '\K[^']+")" -o $mnt_opts_btrfs,nosuid,nodev,nofail,noauto,nodiscard,user || return 2
	mount -m ${device_ex2} "/mnt/media/$(e2label $device_ex2 | grep -oP -m 1 "labelled '\K[^']+")" -o $mnt_opts_btrfs,nosuid,nodev,nofail,noauto,nodiscard,user || return 2

	output "# Mounted ESP and BTRFS subvolumes successfully!" green

	output "~ Creating swapfile and setting swapspace..." yellow

	# <==============================================>
	#  Create & enable swapfile in btrfs:
	# <==============================================>
	btrfs filesystem mkswapfile --size 10g --uuid clear /mnt/var/swap/swapfile || return 2
	swapon /mnt/var/swap/swapfile || return 2

	output "# Swapfile created successfully!" green

	output "~ Generating fstab for new system..." yellow

	# <==============================================>
	#  Generate the fstab for current mounts:
	# <==============================================>
	mkdir -p /mnt/etc || return 2
	genfstab -t PARTLABEL /mnt >> /mnt/etc/fstab || return 2
	# Update advanced mount options that mount does not relay to genfstab
	devices=("$device_ex1" "$device_ex2")
	for device in "${devices[@]}"; do
		content=$(awk -v plabel="$(blkid -s PARTLABEL -o value "$device")" -v opts="x-systemd.automount,x-systemd.device-timeout=8" '
			{
				if ($0 ~ /^PARTLABEL=/ && $1 ~ plabel"$") {
					$4 = $4 "," opts;
				} print $0;
			}
		' /mnt/etc/fstab)
		echo "$content" > /mnt/etc/fstab
	done

	output "# Fstab generated successfully!" green

	output "[Mounts & Swapfile]" purple !
	return 0
}
# <==============================================>
#  [Function] Packages & Configs:
# <==============================================>
# Install base system, packages and configs
# <==============================================>
c_pkg () {
	output "\n[Packages & Configs]" purple

	# <==============================================>
	#  System Packages:
	# <==============================================>
	# base: Arch base meta package
	# linux-zen: Linux-zen kernel
	# linux-zen-headers: Linux-zen kernel headers for dkms
	# linux-firmware: General firmware files
	# base-devel: Utilities for building packages
	# sudo: Controlled superuser access system
	# man-db: Utilities for managin man pages
	# man-pages: Utilities for accessing man pages
	# textinfo: Utilities for accessing textinfo docs
	# git: Git version control
	# posix: Metapackage providing the POSIX shell and utilities (XCU)
	# <==============================================>
	sys_pkgs='base linux-zen linux-zen-headers linux-firmware base-devel sudo man-db man-pages texinfo git posix'
	# <==============================================>
	#  Boot Packages:
	# <==============================================>
	# efibootmgr: Utility for managing efi boot entries
	# intel-ucode: Microcode for intel CPUs
	# mkinitcpio: Utility for creating initramfs images and UKIs
	# <==============================================>
	boot_pkgs='efibootmgr intel-ucode mkinitcpio'
	# <==============================================>
	#  Packages Packages:
	# <==============================================>
	# pacman-contrib: Provides utilities for managing the pacman environment
	# reflector: Updates the repository mirrors dynamically sorting and filtering them
	# namcap: Pacman package analyzer
	# arch-audit: Utility to report package security breaches posted at https://security.archlinux.org/
	# mold: Fastest linker used to build packages
	# <==============================================>
	pkgs_pkgs='pacman-contrib reflector namcap arch-audit mold'
	# <==============================================>
	#  Disk Packages:
	# <==============================================>
	# nvme-cli: Userspace utilities for NVMes
	# hdparm: Userspace utilities for IDE disks
	# sdparm: Userspace utilities for SCSI disks
	# smartmontools. S.M.A.R.T disk control
	# gocryptfs: FUSE encrypted filesystem
	# profile-sync-daemon: Tiny pseudo-daemon designed to manage browser profile(s) in tmpfs and to periodically sync back to the physical disc (HDD/SSD)
	# <==============================================>
	disk_pkgs='nvme-cli hdparm sdparm smartmontools gocryptfs profile-sync-daemon'
	# <==============================================>
	#  BTRFS Packages:
	# <==============================================>
	# btrfs-progs: Userspace utilities for managing btrfs filesystems
	# btrbk: Btrfs backup utility that leverages btrfs capabilities
	# duperemove: Tool for deduping file systems
	# compsize: Calculate compression ratio of a set of files on Btrfs
	# <==============================================>
	btrfs_pkgs='btrfs-progs btrbk duperemove compsize'
	# <==============================================>
	#  NVidia Packages:
	# <==============================================>
	# nvidia-open-dkms: Drivers for use with linux-zen kernel (-dkms) and GTX 1650 (nvidia-open)
	# nvidia-utils: Utilites for the nvidia driver
	# nvidia-settings: CLI and GUI utility for configuring the graphics card and driver
	# <==============================================>
	nvidia_pkgs='nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings'
	# <==============================================>
	#  Audio Packages:
	# <==============================================>
	# pipewire: Provides a low-level multimedia framework
	# wireplumber: Session manager for pipewire
	# pipewire-audio: Provides an audio server
	# pipewire-alsa: Routes all applications using the ALSA API through pipewire
	# pipewire-pulse: Routes all applications using the pulseaudio API through pipewire
	# pipewire-jack: Routes all applications using the JACK API through pipewire
	# pavucontrol: Application to manage sound with pulseaudio
	# easyeffects: Pipewire effect plugins manager
	# calf: limiter, exciter, bass enhancer and others (dependency of easyeffects)
	# lsp-plugins-lv2: equalizer, compressor, delay, loudness (dependency of easyeffects)
	# libcanberra: simple abstract interface for playing event sounds
	# <==============================================>
	audio_pkgs='pipewire lib32-pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse lib32-libpulse pipewire-jack pavucontrol easyeffects calf lsp-plugins-lv2 libcanberra'
	# <==============================================>
	#  Shell Packages:
	# <==============================================>
	# fish: Friendly Interactive SHell
	# fisher: Fish package manager
	# starship: Modern shell prompt
	# eza: Better ls
	# micro: Console text editor
	# moreutils: Utilities for the shell
	# fastfetch: Fetch general system information
	# cmatrix: Matrix animation in the terminal
	# lolcat: Give any text rainbow color
	# posix: Posix utilities
	# procps-ng: Utilities for monitoring your system and its processes
	# bat: Cat clone with syntax highlighting and Git integration
	# bat-extras: Extra utilities for bat, like batman
	# zoxide: Smarter cd
	# dateutils: Date and time utilities
	# ripgrep-all: Search tool that allows you to look for a regex in a multitude of file types
	# fzf: General-purpose command-line fuzzy finder
	# gdu: Fast disk usage analyzer
	# rsync: Fast incremental file transfer
	# gpm: General purpose mouse for ttys # enable gpm.service
	# p7zip: 7z compression utility
	# fd: Faster, colorized alternative to find
	# expac: Pacman database extraction utility
	# prettyping: Ping wrapper with better format and colors
	# httrack: Download a World Wide Web site from the Internet to a local directory, building recursively all directories, getting HTML, images, and other files from the server to your computer
	# btop: System monitoring utility
	# cloc: Count lines of code
	# jq: Command-line JSON processor
	# yazi: Blazing fast terminal file manager written in Rust
	# github-cli: The GitHub CLI
	# unrar: The RAR uncompression program
	# zip, unzip: Compressor/Decompressor for creating and modifying zipfiles and for extracting and viewing files in .zip archives
	# imagemagick: An image viewing/manipulation program
	# <=========================>
	#  git-delta
	# <=========================>
	sh_pkgs='fish fisher starship eza micro moreutils fastfetch cmatrix lolcat posix procps-ng bat bat-extras zoxide dateutils ripgrep-all fzf gdu rsync gpm p7zip fd expac prettyping httrack btop cloc jq yazi github-cli unrar zip unzip imagemagick'
	# <==============================================>
	#  Desktop Packages:
	# <==============================================>
	# xorg-sever: Provides the X11 graphical server
	# xorg-xrdb: X server resource database utility
	# xorg-server-xephyr: Nest X11 sessions for testing
	# xdotool: Command-line X11 automation tool
	# lightdm: Provides a display manager
	# light-locker: Uses lightdm to lock the user session on request and on events
	# awesome: Provides Awesome Window Manager to manage clients
	# picom: Provides a compositor to add visual effects to clients
	# xdg-user-dirs: Implements the XDG User Dirs directory specification
	# accountsservice: D-Bus interface for user account query and manipulation
	# playerctl: Media player control utility
	# hicolor-icon-theme: Freedesktop.org Hicolor, thus default, icon theme
	# kvantum: SVG-based theme engine for Qt
	# xclip: Command line interface to the X11 clipboard (dependency of micro, yazi and etc)
	# python-pywal: Generate and change colorschemes on the fly
	# polkit: Application-level toolkit for defining and handling the policy that allows unprivileged processes to speak to privileged processes
	# polkit-kde-agent: Polkit graphical agent for requesting credentials
	# xdg-desktop-portal: Portals to provide uniform access to features independent of desktops and toolkits
	# xdg-desktop-portal-kde: Kde xdg-desktop-portal backend
	# xsettingsd: Lightweight xsettings daemon which provides settings to Xorg applications
	# python-gpgme: Required for launching dropbox for the first time (orphan dependency) -> https://wiki.archlinux.org/title/Dropbox#Required_packages
	# <==============================================>
	desktop_pkgs='xorg-server xorg-xrdb xorg-server-xephyr xdotool lightdm light-locker awesome picom xdg-user-dirs accountsservice playerctl hicolor-icon-theme kvantum xclip python-pywal polkit polkit-kde-agent xdg-desktop-portal xdg-desktop-portal-kde xsettingsd python-gpgme'
	# <==============================================>
	#  Font Packages:
	# <==============================================>
	# noto-fonts & ttf-iosevka-nerd: Personal fonts
	# ttf-font-awesome: Icons fonts
	# ttf-liberation: Free alternative to Microsoft Fonts
	# <==============================================>
	font_pkgs='noto-fonts ttf-iosevka-nerd ttf-font-awesome ttf-liberation'
	# <==============================================>
	#  Application Packages:
	# <==============================================>
	# rofi: Application launcher
	# dolphin: File manager
	# dolphin-plugins: Plugins for dolphin. eg. Dropbox
	# ffmpegthumbs: Video thumbnails (dependency of dolphin)
	# kdegraphics-thumbnailers: Image and PDF thumbnails (dependency of dolphin)
	# okular: Document viewer
	# redshift: Adjust the color temperature of your screen according to solar cycle
	# vlc: Multi-platform MPEG, VCD/DVD, and DivX player
	# smplayer: Media player with built-in codecs that can play virtually all video and audio formats
	# smplayer-skins: Skins for SMPlayer (dependency of smplayer)
	# smplayer-themes: Themes for SMPlayer (dependency of smplayer)
	# kitty: Terminal emulator
	# libcanberra: Playing bell sound on terminal bell (dependency of kitty)
	# python-pygments: Syntax highlighting in kitty kitten diff (dependency of kitty)
	# qalculate-gtk: Graphical calculator suite
	# electron: Meta package providing the latest available stable Electron build
	# firefox: Web browser
	# torbrowser-launcher: Evasive web browser
	# chromium: Google chrome for testing html projects
	# discord: Chat application
	# flameshot: Screenshot taking utility
	# gimp: Image editing
	# inkscape: Vector graphics editor
	# audacity: Audio editor
	# obsidian: Note app
	# code: OSS Code editor
	# qbittorrent: Graphical bittorrent client
	# ark: Archiving tool included in the KDE desktop
	# libreoffice-fresh: Modern libreoffice suite
	# elisa: Music player
	# <==============================================>
	app_pkgs='rofi dolphin dolphin-plugins ffmpegthumbs kdegraphics-thumbnailers okular redshift vlc smplayer smplayer-skins smplayer-themes kitty libcanberra python-pygments qalculate-gtk electron firefox torbrowser-launcher chromium discord flameshot gimp inkscape audacity obsidian code qbittorrent ark libreoffice-fresh elisa'
	# <==============================================>
	#  Game Packages:
	# <==============================================>
	# lutris: Open Gaming Platform
	# wine: Compatibility layer capable of running Microsoft Windows applications on Unix-like operating systems
	# wine-mono: Wine's built-in replacement for Microsoft's .NET Framework
	# gamemode: Feral gamemode for optimizing Linux system performance on demand
	# steam: Game distribution platform
	# lib32-systemd: For steam to be able to connect to its servers if using systemd-networkd
	# mangohud: A Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more
	# <==============================================>
	game_pkgs='lutris wine wine-mono gamemode lib32-gamemode steam lib32-systemd mangohud lib32-mangohud'
	# <==============================================>
	#  Bluetooth Packages:
	# <==============================================>
	# bluez: Provides the bluetooth protocol stack
	# bluez-utils: Usertime utilities for controlling bluetooth
	# blueman: Full featured bluetooth manager
	# <==============================================>
	bth_pkgs='bluez bluez-utils blueman'
	# Send notifications via notif daemon
	#gsettings set org.blueman.general notification-daemon true
	# <==============================================>
	#  Packages:
	# <==============================================>
	# pkgstats: Sends anonymous stats to arch devs on a weekly basis (systemd timer)
	# <==============================================>
	pkgs="$sys_pkgs $boot_pkgs $pkgs_pkgs $disk_pkgs $btrfs_pkgs $nvidia_pkgs $audio_pkgs $sh_pkgs $desktop_pkgs $font_pkgs $app_pkgs $game_pkgs $bth_pkgs pkgstats"

	# <==============================================>
	#  Update mirrorlist:
	# <==============================================>
	reflector --connection-timeout 10 --download-timeout 30 --cache-timeout 300 --url https://archlinux.org/mirrors/status/json/ --save /etc/pacman.d/mirrorlist --sort rate --threads 2 --age 24 --delay 2 --country Spain,Portugal,France, --latest 8 --protocol https

	output "~ Installing packages to new root..." yellow

	# <==============================================>
	#  Install packages to new root:
	# <==============================================>
	# Initialize (-K) an empty pacman keyring
	# <==============================================>
	# Avoid (-M) copying the host’s mirrorlist
	# <==============================================>
	unlog
	pacstrap -KM /mnt $pkgs || (log && return 2)
	#pacstrap -K /mnt $pkgs || (log && return 2)
	log

	output "# Packages installed successfully!" green

	output "~ Merging configuration files with new system..." yellow

	# <==============================================>
	#  Merges preconfigurated files to the new system:
	# <==============================================>
	# Archive (-a) is equal to (-rlptgoD)
	# <==============================================>
	# Copy recursively (-r), copy symbolic links (-l),
	# copy permissions (-p), copy times (-t),
	# copy owner and group ownership (-og),
	# copy devices and special files (-D)
	# <==============================================>
	# Change ownership and group (--chown) to root:root
	# <==============================================>
	# Change directory and file permissions (--chmod)
	# <==============================================>
	rsync -a --chown=root:root --chmod=D755,F644 ./sysroot/ /mnt || return 2

	# <==============================================>
	#  Set permissions for pacman hooks:
	# <==============================================>
	# Pacman hooks need execute permission
	# <==============================================>
	chmod +x /mnt/etc/pacman.d/hooks/*

	# <==============================================>
	#  Copy packages for building in archroot:
	# <==============================================>
	# Copy recursively (-r) all files and directories
	# <==============================================>
	cp -r ./packages /mnt/pkgs || return 2

	# <==============================================>
	#  Set permissions for sudoers file:
	# <==============================================>
	# Sudoers file needs specific permissions or sudo
	# might refuse to work, thus breking the system
	# <==============================================>
	chmod -c 0440 /mnt/etc/sudoers || return 2

	output "# Configuration files merged successfully!" green

	output "[Packages & Configs]" purple !
	return 0
}

# <==============================================>
#  [Function] Archroot:
# <==============================================>
# Function executed chrooted into new system
# <==============================================>
archroot () {
	# <==============================================>
	#  [Procedures] Log:
	# <==============================================>
	# Clear $logfile creating it if it does not exist
	# <==============================================>
	> $logfile_in
	# <==============================================>
	#  [Functions] Log:
	# <==============================================>
	# Enable log
	# <==============================================>
	log_in () {
		# Redirect /dev/fd/3 to the console and stdout and stderr in append mode to $logfile_in
		exec 3>&1 1>>${logfile_in} 2>&1
	}
	# <==============================================>
	# Disable log
	# <==============================================>
	unlog_in () {
		# Redirect stdout and stderr to the console and /dev/fd/3 in append mode to $logfile_in
		exec 1>&3 3>>${logfile_in} 2>&1
	}
	# <==============================================>
	#  [Function] Time & Locales:
	# <==============================================>
	# Set up the time, timezone, and locales
	# <==============================================>
	o_local () {
		output "\n[Time & Locales]" purple

		output "~ Configuring timezone for new system..." yellow

		# <==============================================>
		#  Set the timezone to use in localtime:
		# <==============================================>
		# If Windows Dualboot:
		#  - Make windows use UTC instead of localtime
		#  - Make windows disable ntp (time sync) client
		# <==============================================>
		ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime || return 2

		output "# Timezone configured successfully!" green

		output "~ Syncying hardware clock with system clock..." yellow

		# <==============================================>
		#  Sync hardware clock with system clock:
		# <==============================================>
		hwclock --systohc || return 2

		output "# Clocks synced successfully!" green

		output "~ Generating locales for new system..." yellow

		# <==============================================>
		#  Generate locales according to /etc/locale.gen:
		# <==============================================>
		locale-gen || return 2

		output "# Locales generated successfully!" green

		output "[Time & Locales]" purple !
		return 0
	}

	# <==============================================>
	#  [Function] Local Packages:
	# <==============================================>
	# Build & install local packages
	# <==============================================>
	o_pkgs () {
		output "\n[Local Packages]" purple

		pkgs=(sea-greeter shikai-theme orchis-gtk-theme orchis-kvantum-theme amy-icon-theme xcursor-hacked enchanted-sound-theme zhou-theme yt-playlist suwayomi linuxshss dotfiles)
		pkgs_deps=(calf lsp-plugins-lv2 ffmpegthumbs kdegraphics-thumbnailers libcanberra python-pygments python-gpgme smplayer-skins smplayer-themes xclip)
		pkgs_aur=(dropbox jdownloader2)
		pkgs_tmp=()
		pkgs_ins=()
		pkgs_uns=()

		# <==============================================>
		#  Update mirrorlist:
		# <==============================================>
		reflector --connection-timeout 10 --download-timeout 30 --cache-timeout 300 --url https://archlinux.org/mirrors/status/json/ --save /etc/pacman.d/mirrorlist --sort rate --threads 2 --age 24 --delay 2 --country Spain,Portugal,France, --latest 8 --protocol https

		# <==============================================>
		#  Add temporary user to build packages:
		# <==============================================>
		useradd -l -m -U -c "TheBuilder" builder || return 2
		# <==============================================>
		#  Change /pkgs ownership to said user:
		# <==============================================>
		chown -R builder:builder /pkgs || return 2
		# <==============================================>
		#  Make building dirs and give permissions:
		# <==============================================>
		#mkdir -p /tmp/makepkg/{out, src} || return 2
		#chown -R builder:builder /tmp/makepkg/{out, src} || return 2

		output "~ Initializing and populating archlinux keyring..." yellow

		# <==============================================>
		#  Initialize and populate archlinux keyring:
		# <==============================================>
		pacman-key --init || return 2
		pacman-key --populate archlinux || return 2

		output "# Initialized and populated archlinux keyring successfully!" green

		output "~ Building local packages..." yellow

		unlog_in

		# <==============================================>
		#  Loop trough copied PKGBUILDs and install:
		# <==============================================>
		for pkg in /pkgs/*/; do
			# Check if package is in pkgs array for installing
			if [[ "$(echo ${pkgs[@]} | grep -cwF -m 1 "$(basename "$pkg")")" == "1" ]]; then
				# Extract specific variable from PKGBUILD
				depends=("$(source "$pkg/PKGBUILD" && echo "${depends[@]}")")

				# Extract specific variable from PKGBUILD
				makedepends=("$(source "$pkg/PKGBUILD" && echo "${makedepends[@]}")")

				# Only add packages not already installed
				for mkdp in "${makedepends[@]}"; do
					if ! pacman -Qq "$mkdp" > /dev/null 2>&1; then
						pkgs_tmp+=("$mkdp")
					fi
				done

				# Install depends and makedepends
				pacman -Sy --needed --noconfirm ${makedepends[@]} ${depends[@]}

				# Build pkg, which will be stored in ~/.pkgs as per makepkg.conf
				(su - builder -c "makepkg -D "$pkg" -fcr --noconfirm") && pkgs_ins+=("$(basename "$pkg")") || pkgs_uns+=("$(basename "$pkg")")

				# Remove files that are not needed
				rm -fr "$pkg"
				rm -fr /tmp/makepkg/*
			fi
		done

		#LOOKOUT
		#install -dm 500 /etc/skel/.dropbox-dist || return 2 # instead of -dm0 use -dm 444

		log_in

		output "# Local packages built successfully!" green

		# <==============================================>
		#  Remove package source path contents:
		# <==============================================>
		rm -fr /pkgs/* || return 2

		output "~ Building AUR packages..." yellow

		unlog_in

		# <==============================================>
		#  Loop trough AUR PKGBUILDs and install:
		# <==============================================>
		for pkg in "${pkgs_aur[@]}"; do
			pkg="/pkgs/$pkg"

			# Clone AUR repository
			su - builder -c "git -C /pkgs clone "https://aur.archlinux.org/$(basename "$pkg").git

			# Extract specific variable from PKGBUILD
			depends=("$(source "$pkg/PKGBUILD" && echo "${depends[@]}")")

			# Extract specific variable from PKGBUILD
			makedepends=("$(source "$pkg/PKGBUILD" && echo "${makedepends[@]}")")

			# Only add packages not already installed
			for mkdp in "${makedepends[@]}"; do
				if ! pacman -Qq "$mkdp" > /dev/null 2>&1; then
					pkgs_tmp+=("$mkdp")
				fi
			done

			# Install depends and makedepends
			pacman -Sy --needed --noconfirm ${makedepends[@]} ${depends[@]}

			# Build pkg, which will be stored in ~/.pkgs as per makepkg.conf
			(su - builder -c "makepkg -D "$pkg" -fcr --noconfirm") && pkgs_ins+=("$(basename "$pkg")") || pkgs_uns+=("$(basename "$pkg")")

			# Remove files that are not needed
			rm -fr "$pkg"
			rm -fr /tmp/makepkg/*
		done

		log_in

		output "# AUR packages built successfully!" green

		output "~ Installing built packages..." yellow

		# Install built packages
		pacman -U --noconfirm /home/builder/.pkgs/*.pkg.tar.zst
		# Remove makedepends packages
		pacman -Rnsu --noconfirm ${pkgs_tmp[@]}

		output "# Built packages installed successfully!" green

		# <==============================================>
		#  Remove package source path:
		# <==============================================>
		rm -fr /pkgs || return 2
		rm -fr /tmp/makepkg || return 2
		# <==============================================>
		#  Remove temporary builder user:
		# <==============================================>
		userdel -fr builder || return 2

		# <==============================================>
		#  Loop trough dependency packages and
		#  change their install reason to dependency:
		# <==============================================>
		for pkg in "${pkgs_deps[@]}"; do
			pacman -D --asdeps $pkg || return 2
		done

		# Print installation summary
		output "Makepkg Summary:" blue

		# Loop trough succesfull installations
		for pkg in "${pkgs_ins[@]}"; do
			output "# Built: ${pkg}" green !
		done
		# Loop trough unsuccesfull installations
		for pkg in "${pkgs_uns[@]}"; do
			output "$ Failed: ${pkg}" red !
		done

		# Pause until key is pressed
		input pause ">> Press *Enter* to continue..." cyan

		output "[Local Packages]" purple !
		return 0
	}

	# <==============================================>
	#  [Function] Boot & UKIs:
	# <==============================================>
	# Unified Kernel Images and EFI boot entries
	# <==============================================>
	o_boot () {
		output "\n[Boot & UKIs]" purple

		output "~ Generating UKIs for the system..." yellow

		# <==============================================>
		#  Create EFI directory to house efi binaries:
		# <==============================================>
		# Directory must exists to create boot images
		# <==============================================>
		mkdir -p /boot/EFI/Linux

		# <==============================================>
		#  Make the UKIs for booting up:
		# <==============================================>
		unlog_in

		mkinitcpio -p linux-zen-uki || (log_in && return 2)

		log_in

		output "# UKIs generated successfully!" green

		output "~ Creating boot entries for the UKIs..." yellow

		# <==============================================>
		#  Make the UKIs for booting up:
		# <==============================================>
		efibootmgr --create --disk $device --part 1 --label "Arch Linux" --loader '/EFI/Linux/arch-linux.efi' --unicode || return 2
		efibootmgr --create --disk $device --part 1 --label "Arch Linux: Normal" --loader '/EFI/Linux/arch-linux-normal.efi' --unicode || return 2
		efibootmgr --create --disk $device --part 1 --label "Arch Linux: Fallback" --loader '/EFI/Linux/arch-linux-fallback.efi' --unicode || return 2
		# Mount uefi vars read only for security ??? /sys/firmware/efi/efivars

		output "# Boot entries created successfully!" green

		output "[Boot & UKIs]" purple !
		return 0
	}

	# <==============================================>
	#  Set up the users and groups:
	# <==============================================>

	# <==============================================>
	o_usr () {
		output "\n[Users & Groups]" purple

		# <==============================================>
		#  Control groups:
		# <==============================================>
		groupadd -f -g 1500 users || return 2
		groupadd -f -g 1600 power || return 2
		groupadd -f -g 1700 network || return 2
		groupadd -f -g 1750 bluetooth || return 2
		groupadd -f -g 1800 storage || return 2
		groupadd -f -g 1900 ssh || return 2
		groupadd -f -g 2000 autologin || return 2

		# Administrator accounts
		#useradd --system -u 666 -U -c "He who manages the Packages" pkgop || return 2
		#useradd --system -u 999 -U -c "He who manages the System" sysop || return 2

		# Gamemode group for using gamemode
		useradd -m -u 2500 -U -G users -c "TheGuest" guest || return 2
		useradd -m -u 2000 -U -G users,power,network,bluetooth,ssh,gamemode -c "TheWisker" wisker || return 2

		# Lock the root account for security
		#passwd --lock root
		output "[Users & Groups]" purple !
		return 0
	}

	# <==============================================>
	#  Systemd Services:
	# <==============================================>
	# Enable required services for new system
	# <==============================================>
	o_srv () {
		output "\n[Setup & Services]" purple

		output "~ Enabling systemd services for the system..." yellow

		# Enable btrfs scrub timers for monthly checksum validation
		systemctl enable btrfs-scrub@-.timer
		systemctl enable btrfs-scrub@home.timer

		# Enable btrbk backup timer for making backups every hour
		systemctl enable btrbk@1h.timer || return 2

		# Enable duperemove timer for finding duplicate regions in root disk and submiting them for deduplication monthly
		systemctl enable duperemove@monthly.timer || return 2

		# Enable lightdm for having a display manager
		systemctl enable lightdm.service || return 2

		# Enable bluetooth for having bluetooth capabilites
		systemctl enable bluetooth.service || return 2

		# Enable psd user unit for all users for syncing profiles (ej. firefox)
		systemctl --global enable psd.service || return 2

		# Enable systemd-{networkd, resolved} for network connection and resolution
		systemctl enable systemd-networkd.service || return 2
		systemctl enable systemd-resolved.service || return 2

		# Enable timesync daemon for time synchronization
		systemctl enable systemd-timesyncd.service || return 2

		# Enable canberra-system-bootup for having bootup, shutdown and reboot sounds using canberra
		systemctl enable canberra-system-bootup.service || return 2

		# Enable reflector on boot after network-online.target is reached to update mirrorlist
		systemctl enable systemd-networkd-wait-online.service || return 2
		systemctl enable reflector.service || return 2 # Needs systemd-networkd-wait-online.service enabled

		# Enable xdg-user-dirs-update for all users updating XDG-User directories on boot
		systemctl --global enable xdg-user-dirs-update.service || return 2

		output "# Systemd services enabled successfully!" green

		output "[Setup & Services]" purple !
		return 0
	}

	log_in

	output "\n[Archroot Setup]" purple

	o_local && o_pkgs && o_boot && o_usr && o_srv

	output "[Archroot Setup]" purple !

	unlog_in && sync

	return 0
}
# <==============================================>
#  [Function] Clean:
# <==============================================>
# Clean environment after installation
# <==============================================>
c_clean () {
	output "\n[Clean]" purple

	output "~ Cleaning after installation..." yellow

	# <==============================================>
	#  Symlink for using systemd-resolved:
	# <==============================================>
	# Must be done after install as we lose the
	# ability to resolve dns in chroot otherwise
	# <==============================================>
	ln -sf /mnt/run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf || return 2

	# <==============================================>
	#  Move $logfile_in outside of new root:
	# <==============================================>
	mv /mnt/$logfile_in .

	# <==============================================>
	#  Swapoff swapfile:
	# <==============================================>
	swapoff /mnt/var/swap/swapfile

	# <==============================================>
	#  Unmount all mounts for new root:
	# <==============================================>
	# Unmount recursively (-R) all mounts
	# <==============================================>
	umount -R /mnt

	output "# Cleaned after installation successfully!" green

	output "[Clean]" purple !
	return 0
}
# <==============================================>
#  [Code] Main:
# <==============================================>
# Export functions and run all installer functions
# <==============================================>
# Makes these functions visible in the arch-chroot
# <==============================================>
export -f input
export -f output
export -f archroot
# <==============================================>
# Save start time to calculate difference
# <==============================================>
stime=$(date +%s)
# <==============================================>
#  Run all functions, in order, chained as to
#  only run if the previous function has not failed
# <==============================================>
log && output "" off && output "$title" purple
# <==============================================>
if c_efi && c_net && c_part && c_mnt && c_pkg && (unlog && sync && arch-chroot /mnt /bin/bash -c "archroot" && log); then
	output "\n> Restart to log into the new system!" yellow !
	output "\n> Installation completed successfully!" green !
else
	log; output "\n> Installation failed!" red !
fi
# <==============================================>
etime=$(($(date +%s) - stime))
output "\n>> Elapsed time: $((etime / 60)) minutes $((etime % 60)) seconds"
# <==============================================>
c_clean
# <==============================================>
