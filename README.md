# WinPE
Microsoft: "Windows PE (WinPE) for Windows 10 is a small operating system used to install, deploy, and repair Windows 10"

This is a custom script that runs when Windows PE boots. It gives a convenient menu to easily capture and deploy Windows images.

## Features

* Simple menu for capturing and deploying Windows images.
* Deploy with one click, script automatically partitions drive and writes image to disk.
* Works with UEFI or BIOS.
* Create a full disk backup with 7z. (needs some work)

## Setup

### Perequisites

* Windows PE files. Download the [Windows Assessment and Deployment Kit (ADK)](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/download-winpe--windows-pe)
  * Make sure you have selected **Deployment tools**
  * if you have Windows 1809 make sure to download the Windows PE add-on
* The files from this repository

### Create working Files

1. Start **Deployment and Imaging tools Environment** as admin.
2. Run copype to create a directory to work from. This will only boot on 64-bit machines.
    * `copype amd64 C:\WinPE`
3. Mount WinPE to allow making changes.
    * `Dism /Mount-Image /ImageFile:"C:\WinPE\media\sources\boot.wim" /index:1 /MountDir:"C:\WinPE\mount"`
4. Copy and replace files from repo to "C:\WinPE\mount\Windows\System32".

### Unmount and commit changes

1. Use Dism to unmount and commit changes
    * `Dism /Unmount-Image /MountDir:"C:\WinPE\mount" /commit`

### Create Bootable Media

#### Bootable USB Drive

Windows PE uses Fat32, so the maximum file size is only 4 GB. Typically Windows images are much larger after updates, installing software, etc. So you have the following options from least to most convenient:

* Split your .wim file into several chunks to get the whole image to fit with WinPE on one parition. I can't see any benefit to doing this now since Windows 10 1703 supports creating multiple partitions on USB drives.
  * Note: My script doesn't allow for creating split images yet. So if for some reason you needed to deploy the image from a FAT32 drive, you would need to capture it yourself, or two a second NTFS drive and [split it later](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe--use-a-single-usb-key-for-winpe-and-a-wim-file---wim#option-4-split-the-image).
* Use two USB drives. One FAT to boot Windows PE, and other as NTFS to hold the images. This works but if you have a Microsoft Surface or similar device, these only have a single USB port so to use both would need a USB hub.
* Continue reading my instructions on formatting a USB drive with two paritions. One small FAT partition for Windows PE, and the other as NTFS for images. I find this to be the easiest method, as USB 3 drives are getting pretty cheap, are are very fast, and more convenient as you only need one device.

**This should go without saying, but all data on the drive will be erased! - Also, make sure to select the right drive!**

1. In the **Deployment and Imaging Tools Environment** type **diskpart** and press Enter.
2. Use these commands to partition the disk into two paritions using Diskpart.
    1. `List disk`
    2. `select disk x` - (Where x is USB drive.)
    3. `clean`
    4. `create partition primary size=512` (This makes WinPE 512MB. Increase as needed if you have added more to your WinPE setup.)
    5. `active`
    6. `format fs=FAT32 quick label="WinPE"`
    7. `assign letter=P`
    8. `create partition primary`
    9. `format fs=NTFS quick label="Images"`
    10. `assign letter=I`
    11. `Exit`
3. Copy Windows PE files to drive
    1. `MakeWinPEMedia /UFD C:\WinPE P:`
4. Create an "Images" folder on the I drive. This is where the script will store and read images from.
    1. `mkdir I:\Images`

#### ISO disk image

1. Use MakeWinPEMedia with /ISO option.
    * `MakeWinPEMedia /ISO C:\WinPE C:\WinPE\WinPE.iso`

## Resources

* [Create bootable WinPE media](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-create-usb-bootable-drive)
* [WinPE: Mount and Customize](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-mount-and-customize)
* [WinPE: Store or split images to deploy Windows using a single USB drive](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe--use-a-single-usb-key-for-winpe-and-a-wim-file---wim)