@echo off
setlocal EnableDelayedExpansion

:: export tiled maps
echo;
echo exporting tiled maps
echo --------------------
for %%f in (source/puzzle/*.tmx) do (
	set tmxPath=source/puzzle/%%f
	set luaPath=!tmxPath:~0,-4!.lua
	echo exporting !tmxPath! to !luaPath!
	tiled --export-map !tmxPath! !luaPath!
)

:: run love
echo;
echo running love
echo ------------
lovec source %*

:: remove ignored files
echo;
echo cleaning up files
echo -----------------
git clean -Xdf
