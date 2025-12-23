# Dapvop
Laptop-to-DVD-Player Arch Linux configuration

## Introduction

In short, this repo provides the Bash code and configuration steps to add some simple DVD player-type functionality to a laptop. Or any computer, really, I suppose.

This project came from a combination of two problems: I had a "smart" TV that would load up far more apps than I ever wanted before I could get to the 2 or 3 features I actually needed, and I had a laptop that was far too weak to run the Windows 10 I had loaded up on it. I decided to kill two bugs with one push and configured a clean Arch Linux install to run as a simple DVD player.

> [!IMPORTANT]
> I should mention that this project was just as much a learning experience for me as it was an actual solution to my problem.
>
> If you're looking for a *good* solution to turn your laptop into a DVD player, you might find some answers here, but there are more professionally written programs that'll probably help you more (that I only learned about halfway through this project).
>
> In my Googlings, I found information on [Home Theater PCs](https://en.wikipedia.org/wiki/Home_theater_PC), as well as recommendations for hardware beyond laptops and software beyond Bash frontends. If you're looking for a more solidly-built solution, the [wiki from Reddit's r/htpc](https://r-htpc.github.io/wiki/) might be a good place to start. One piece of software that caught my eye was Kodi, but I never looked too deeply into it; I was more interested in getting more comfortable with Linux.
>
> On the other hand, if you came to this repo wanting to look at a goofy Arch Linux configuration, gander at someone's dabblings into Bash, or have a solution that's janky but does, in fact, work, by all means, read on.

## Functionality

The configuration described here is meant to be installed onto a USB drive, and booted onto a laptop from that drive. On startup, the `dapvop_menu.sh` script brings up a menu showing five options:
- **Play a DVD:** This will play whatever DVD is in the laptop's CD drive.
- **Play a file:** This will bring up a list of files in the Dapvop's storage partition. Video files can be copied here over the network, or copied over if the USB is plugged into another computer. Files are kept in a partition separate from the root directory.
- **Youtube:** This will open Youtube's TV app interface.
- **Settings:** Gives options to:
  - **Detect Monitor:** Reset which monitors Linux sees, in case the HDMI output isn't being output to.
  - **Network Manager:** Opens Network Manager to let the user connect to a network.
  - **Open Terminal:** Opens a terminal for Linux shenanigans.
- **Power:** Lets the user put the computer to sleep, or power off.

## Setup

### Install Arch Linux

As with most things regarding Arch Linux, [READ THE WIKI](https://wiki.archlinux.org/title/Main_page). This was my first project with it, and 90% of the issues I had were my own fault by not reading the wiki closely enough.

The wiki has a [page on installing the operating system](https://wiki.archlinux.org/title/Installation_guide), and this should be followed more or less to the letter. Set up Arch Linux to be installed on a USB drive (so for this project, I had two USBs: a blank one to install onto, and one to hold the installation software).

> [!WARNING]
> Needless to be said, installing a new OS on a USB will format and destroy any data on that drive.

#### Partitioning

There are lots of different partition setups that would work, I'm sure, but what's described here is a BIOS with GPT setup. My laptop was set up to boot with BIOS anyway, and I ended up needing the GPT attributes to hide certain partitions from Windows (otherwise Windows would try to mount the Linux partitions when plugging in the USB as a storage device). Here are the partitions I ended up setting up:
| Partition # | Partition Type       | Partition Size | Filesystem        | Notes                                         |
| ----------- | -------------------- | -------------- | ----------------- | --------------------------------------------- |
| 1           | BIOS boot            | 1MB            | N/A               | Boot partition to be used by the bootloader   |
| 2           | Microsoft Basic Data | 4GB            | N/A, use `swapon` | Swap space for Linux                          |
| 3           | Microsoft Basic Data | 7GB            | `mkfs.ext4`       | Linux root device                             |
| 4           | Microsoft Basic Data | All remaining  | `mkfs.ntfs -f`    | Windows-viewable device for video file storage|

All partitions are labeled as Microsoft Basic Data partitions so `gdisk` can be used (enter `x` to enter the Expert menu, and `a` to set partition attributes) to set attributes that Windows can act on. It's important to set the first three partitions with attibutes **62 (hidden)** and **63 (no auto-mount)** to make Windows ignore those partions; when the Dapvop is plugged in as a storage device, Windows should only see the file storage partition.

> [!NOTE]
> The boot partition must be labeled as a 'BIOS boot' partition type when GRUB is configured, otherwise the configuration won't see the partition and GRUB will fail to install properly. Once it's configured, though, it's safe to relabel the partition as 'Microsoft Basic Data' and make sure the right attributes are set to hide the partition from Windows.

#### Packages

When installing the base packages, you can append any other `pacman` packages that you want to the initial `pacstrap` command. Here's the complete `pacstrap` command I used, including all the packages I needed, save two [Arch User Repository packages](https://wiki.archlinux.org/title/Arch_User_Repository) that can be installed once the OS is bootable (`ratpoison` and `flirc-bin`).

`pacstrap -K /mnt base linux linux-firmware base-devel git e2fsprogs ntfs-3g sof-firmware grub vim man-db man-pages texinfo pulseaudio pavucontrol networkmanager ufw samba wsdd xorg-server xorg-init xterm sudo dialog scrot firefox vlc vlc-plugin-dvd vlc-plugin-dca libdvdcss libva-intel-driver xf86-video-intel`

- `base linux linux-firmware` are the base packages required to install Arch Linux
- [`base-devel`](https://wiki.archlinux.org/title/Arch_User_Repository) [`git`](https://wiki.archlinux.org/title/Git) are used to install AUR packages
- [`e2fsprogs`](https://wiki.archlinux.org/title/Ext4) adds Ext4 filesystem utilities
- [`ntfs-3g`](https://wiki.archlinux.org/title/NTFS-3G) adds NTFS filesystem utilities
- [`sof-firmware`](https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture#Firmware) was recommended for laptop onboard audio support
- [`grub`](https://wiki.archlinux.org/title/GRUB) is the bootloader
- [`vim`](https://wiki.archlinux.org/title/Vim) adds a text editor (your preferences may vary)
- [`man-db man-pages`](https://wiki.archlinux.org/title/Man_page) [`texinfo`](https://wiki.archlinux.org/title/GNU#Texinfo) adds the very helpful Man Pages and Info pages
- [`pulseaudio pavucontrol`](https://wiki.archlinux.org/title/PulseAudio) adds audio control software
- [`networkmanager`](https://wiki.archlinux.org/title/NetworkManager) [`ufw`](https://wiki.archlinux.org/title/Uncomplicated_Firewall) are used, in addition to the pre-installed [`iptables`](https://wiki.archlinux.org/title/Iptables), for basic networking
- [`samba wsdd`](https://wiki.archlinux.org/title/Samba) are used to open the storage partition as a network drive, accessible to anyone (with the right credentials) on the network
- [`xorg-server`](https://wiki.archlinux.org/title/Xorg) [`xorg-xinit`](https://wiki.archlinux.org/title/Xinit) [`xterm`](https://wiki.archlinux.org/title/Xterm) are used to configure the display manager
- [`sudo`](https://wiki.archlinux.org/title/Sudo) allows easier root permission access
- [`dialog`](https://linux.die.net/man/1/dialog) is what the main menu is written with
- [`scrot`](https://wiki.archlinux.org/title/Screen_capture#scrot) is a screenshot utility (not necessary, but I found it handy for documentation)
- [`firefox`](https://wiki.archlinux.org/title/Firefox) adds a web browser, used for browsing Youtube
- [`vlc`](https://wiki.archlinux.org/title/VLC_media_player) [`vlc-plugin-dvd libdvdcss vlc-plugin-dca`](https://wiki.archlinux.org/title/VLC_media_player#Cannot_open_DVD) `libva-intel-driver xf86-video-intel` adds the VLC media player and various packages useful for playing videos. The two Intel packages can be ignored if your device doesn't have an Intel CPU.

Once the packages are installed, make sure to configure GRUB as described in the wiki, and the USB should be bootable.

### Initial Setup

I'll try not to repeat too much of what's on the wiki, since it really is helpful to go through the configuration steps listed there, but I'll try to give a brief overview of what needs to be configured at all, and the specific steps necessary to get the system set up for Dapvop. If anything doesn't look like it's working properly, read the wiki pages, but definitely make sure to use `systemctl` to start and enable the services for:
- `iptables`
- `NetworkManager`
- `ufw` (also use the command `ufw enable`; read the wiki)
- `wsdd`
- `smb`

#### Files To Copy

Create a basic user (so you aren't using `root` all the time) and copy the following files into the home directory:
- `.Xresources`
- `.bash_profile`
- `.ratpoisonrc`
- `.xinitrc`
- `dapvop_menu.sh`

This should start up Xorg, and then Ratpoison, as well as open the Dapvop menu, on boot up. To disable opening the Dapvop menu every boot, comment out `xterm -e bash -c '$HOME/dapvop_menu.sh' &` towards the bottom of `.xinitrc`.

Additionally, add a folder called Screenshots in the home directory. As shown in `.ratpoisonrc`, pressing the control key (in this configuration, the Windows key) and F12 will save a screenshot to that folder.

#### Navigating the Dapvop Menu

This is straightforward 90% of the time, but the controls for the file selector used by `dialog` are convoluted enough that I'm adding a brief entry here.

Up, Down, Left, Right and Return select options for most of the menus, as is tradition. When selecting 'Play a file', the file selector opens which has four sections: Directories, Files, Working Directory, and OK/Back. It can be hard to see where the cursor is at any given time, and that can change whether Up moves the cursor from one directory to another, or to a different section altogether. Here's what to keep in mind when navigating:
- The Tab key will switch the cursor between sections
- When the cursor is over a Directory or File, pressing the Spacebar will add it to the Working Directory section
- If a Directory was added to the Working Directory, on pressing Return, that directory will be navigated to. If a File was added, it will open that file in VLC.

The some of the logic can be see in `dapvop_menu.sh`, but I'll admit it's more convoluted than I'd like.

#### AUR Packages

Once the Internet connection is set up (read the pages for [Network Manager](https://wiki.archlinux.org/title/NetworkManager) and [UFW](https://wiki.archlinux.org/title/Uncomplicated_Firewall)), copy the `installAUR.sh` scripts into its own folder in the home directory. When ran, it'll attempt to download and install [AUR packages](https://wiki.archlinux.org/title/Arch_User_Repository) given as the first argument. For example, to install `ratpoison`, run:
```
> ./installAUR.sh ratpoison
```
The two packages I used were [`ratpoison`](https://wiki.archlinux.org/title/Ratpoison), a window manager, and `flirc-bin`, the software used to control a [Flirc USB dongle](https://flirc.tv/products/flirc-usb-receiver?variant=43513067569384) used to control the laptop with a universal remote.

#### Storage Partition

Set up your storage partition to be mounted automatically on boot in a folder called `/mnt/external` by adding an entry to `/etc/fstab`. It should look similar to the other entries in the file:
```
# /dev/sda4
UUID=[UUID]        /mnt/external     ntfs        rw,relatime     0 0
```
You can find the UUID of the block device using the `blkid` command.

#### Samba

[Samba](https://wiki.archlinux.org/title/Samba) is used to open the storage partition to the network. Following the instructions on the wiki should be sufficient to getting it up and running. Make sure to create a separate user with a Samba password, and to give that user permission to access the storage partition.

Additionally, make sure to use UFW to [open the right ports to allow Samba traffic](https://wiki.archlinux.org/title/Samba#UFW_Rule).

#### Firefox

Open Firefox and install the following two extensions:
- [Youtube TV](https://addons.mozilla.org/en-US/firefox/addon/youtube-for-tv/) allows Youtube's TV app to be opened in a browser
- [Ublock Origin](https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/) blocks ads. But you knew that already.

To hide the toolbar along the top, giving Firefox a cleaner look, create a folder called `chrome` in Firefox's profile folder and copy `userChrome.css` into it. You can find your profile folder by going to the `about:support` URL.

Finally, go to the `about:config` URL, and search for the setting called `toolkit.legacyUserProfileCustomizations.stylesheets` and switch it to `true`.

#### Flirc and Configuring Keypresses

There are lots of ways to control a laptop remotely, and the solution used here is a [Flirc dongle](https://flirc.tv/products/flirc-usb-receiver?variant=43513067569384), which can emulate keypresses based on set signals received from any universial remote, or any IR emitting device. Once the `flirc-bin` AUR package is installed and the dongle is plugged in, run the `flirc_util help` command to see available options. A list of handy keypresses to configure is:
- Up, Down, Left, Right: For navigation
- Return: To select options
- Left, Right (Separately from above): To seek through videos
- Space: To pause videos
- Ctrl Q: To exit from programs and return to the Dapvop menu
- Shift M: To return to the DVD's disc menu in VLC
- Backspace: To go back in Youtube TV
- Tab, Shift Tab: To toggle through `dialog`'s file selection options

### Bric-a-Brac I Wish I Knew Beforehand

#### Skip GRUB's Initial OS Selection Screen

Copy the file `grub` into `/etc/default/grub` and run `grub-mkconfig -o /boot/grub/grub.cfg` to regenerate `grub.cfg` with the new settings. The new file sets `GRUB_TIMEOUT` and `GRUB_HIDDEN_TIMEOUT` to 0, as well as `GRUB_TIMEOUT_STYLE` to hidden, skipping the initial screen.

#### Autologin as the basic user

Following the instructions [here](https://wiki.archlinux.org/title/Getty#Automatic_login_to_virtual_console), create a folder called `getty@tty1.service.d` in `/etc/systemd/system` and add the content shown in a file called `autologin.conf`.

#### Fix Audio Only Being Output Through Laptop Speakers

In the Configuration tab of PulseAudio Volume Control (`pavucontrol`), you can select the HDMI output as the output device.

## Notes

The full notes I wrote as I put all this together can be found on my dubiously-fonted [Git Blog Whiteboard Thing](https://krathman257.github.io/projects/dvdplayer.html), along with notes for some of my other projects. If you need any incentive to check it out, there's a Jurassic Park tangent in there :3
