device=/dev/nvme0n1
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

# <==============================================>
#  Mount btrfs subvolumes to respective paths:
# <==============================================>
# Make (-m) any missing parent directories
# <==============================================>
# Use the specified mount options (-o)
# <==============================================>
mount -m ${device}p2 /mnt -o subvol='@archy',$mnt_opts_btrfs,ssd
mount -m ${device}p2 /mnt/home -o subvol='@home',$mnt_opts_btrfs,ssd
mount -m ${device}p2 /mnt/root -o subvol='@root',$mnt_opts_btrfs,ssd
mount -m ${device}p2 /mnt/var/cache -o subvol='@cache',$mnt_opts_btrfs,ssd
mount -m ${device}p2 /mnt/var/tmp -o subvol='@tmp',$mnt_opts_btrfs,ssd
mount -m ${device}p2 /mnt/var/log -o subvol='@log',$mnt_opts_btrfs,ssd
mount -m ${device}p2 /mnt/var/snap -o subvol='@snap',$mnt_opts_btrfs,ssd
mount -m ${device}p2 /mnt/var/swap -o subvol='@swap',$mnt_opts_btrfs,ssd
mount -m ${device}p2 /mnt/srv -o subvol='@srv',$mnt_opts_btrfs,ssd
mount -m ${device}p2 /mnt/media/shr -o subvol='@shr',$mnt_opts_btrfs,ssd
# <==============================================>
#  Mount esp partition:
# <==============================================>
mount -m ${device}p1 /mnt/boot -o $mnt_opts,nosuid,nodev
