rem == ApplyImage.bat ==

rem == These commands deploy a specified Windows
rem    image file to the Windows partition, and configure
rem    the system partition.

rem    Usage:   ApplyImage WimFileName 
rem    Example: ApplyImage E:\Images\ThinImage.wim ==

rem == Apply the image to the Windows partition ==
dism /Apply-Image /ImageFile:%1 /Index:1 /ApplyDir:W:\

rem == Copy boot files to the System partition ==
W:\Windows\System32\bcdboot W:\Windows /s S:

:rem == Verify the configuration status of the images. ==
W:\Windows\System32\Reagentc /Info /Target W:\Windows