Installation Guide
==================

1. Read the Documentation
    * Re-read everything on paludis.pioto.org and exherbo.org .
    * Check recent mailing list posts for any possible issues that might occur.

2. Boot a live system
    * Download SystemRescueCD (it has both 32 and 64 bit support)  
        ``# links http://www.sysresccd.org/Download``
    * Burn it to a cd or use unetbootin to put it on a usb stick
    * Reboot, choose the right kernel, and get your network up  
        ``# net-setup wlan0``

3. Prepare the hard disk
    * Create a boot partition (~16mb), a root partition (>=4gb), and a home partition  
        ``# cfdisk /dev/sda``
    * Format the filesystems for each partition  
          # mkfs.ext2 /dev/sda1  
          # mkfs.ext4 /dev/sda2  
	  # mkfs.ext4 /dev/sda3  
	/dev/sda1 is for /boot, where grub will go.
	/dev/sda2 is for /, where the system will reside.
	/dev/sda3 is for /home, where user files will go.
	ext2 is chosen for /boot to speed up booting, and ext4 for the rest of the filesystem.

4. Chroot into the system
    * Mount root and cd into it  
        ``# mkdir /mnt/exherbo && mount /dev/sda2 /mnt/exherbo && cd /mnt/exherbo``
    * Get the latest archive of exherbo and extract it  
        ``# wget http://dev.exherbo.org/stages/exherbo-amd64-current.tar.lzma && unlzma -c exherbo*lzma | tar xf -``
    * Mount everything for the chroot  
          # mount -o bind /dev /mnt/exherbo/dev/  
          # mount -o bind /sys /mnt/exherbo/sys/  
          # mount -t proc none /mnt/exherbo/proc/  
          # mount /dev/sda1 boot/  
          # mount /dev/sda3 home/  
    * Make sure the network can resolve dns, and mtab is correct  
          # cp /etc/resolv.conf etc/resolv.conf  
	  # cat /proc/mounts > etc/mtab  
    * Change your root!  
          # chroot /mnt/exherbo /bin/bash  
          # eclectic env update  
          # source /etc/profile  
          # export PS1="(chroot) $PS1"  

5. Update the install
    * Make sure paludis is configured correctly - changing C/CXXFLAGS to -march=native might be a good idea  
        ``# cd /etc/paludis && vim bashrc && vim *conf``  
    * _IMPORTANT_ Update paludis _before_ syncing - since Paludis is very actively developed, its a good idea to update the client to take advantage of new features that might show up with a sync  
        ``# paludis -i paludis``  
    * Sync all the trees - now it is safe to sync  
        ``# paludis  --sync``  
    * Update the System   
        ``# paludis -i everything --dl-reinstall if-use-changed --dl-upgrade always``
    
6. Make bootable
    * Install Grub  
          # grub-install /dev/sda1  
          # grub  
	  grub> root (hd0,0)  
	  grub> setup (hd0)  
	  grub> quit  
    * Install a kernel  
          # paludis -i vanilla-sources  
	  # cd /usr/src/linux && make menuconfig && make && make modules_install && cp arch/x86_64/boot/bzImage /boot/  
    * Update grub  
        # vim /boot/grub/grub.conf  
	The configuration of grub is wildly different between grub-static (0.97) and grub2 (1.9x). Consult /usr/share/doc/grub*/ and the website for those changes if you want to use grub2. NOTE: grub2 will not compile on ~amd64 until Exherbo gets a working multilib.  
    * Install any hardware stuff you might need, check the FAQ for 'Masked by unavailable' errors  
        # paludis -i iwlwifi-4965-ucode  
    * Reboot  
        reboot && sacrifice a goat && pray  
