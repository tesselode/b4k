import os
import shutil
import urllib.request

# create the dist folder
if os.path.exists('dist'):
	shutil.rmtree('dist')
os.mkdir('dist')

# make the .love file
shutil.make_archive('dist/b4k', 'zip', 'source')
os.rename('dist/b4k.zip', 'dist/b4k.love')

# make the win32 build
urllib.request.urlretrieve('https://bitbucket.org/rude/love/downloads/love-11.2-win32.zip', 'dist/love-win32.zip')
shutil.unpack_archive('dist/love-win32.zip', 'dist')
os.remove('dist/love-win32.zip')
os.rename('dist/love-11.2.0-win32', 'dist/win32')
shutil.copy2('dist/b4k.love', 'dist/win32/b4k.love')
os.chdir('dist/win32')
os.system('copy /b love.exe+b4k.love b4k.exe')
if os.name == 'nt':
	os.system('ResourceHacker -open b4k.exe -save b4k.exe -action modify -resource "../../assets/graphics/icon.ico" -mask ICONGROUP,1')
os.chdir('../..')
os.remove('dist/win32/changes.txt')
os.remove('dist/win32/b4k.love')
os.remove('dist/win32/game.ico')
os.remove('dist/win32/love.exe')
os.remove('dist/win32/love.ico')
os.remove('dist/win32/lovec.exe')
os.remove('dist/win32/readme.txt')
shutil.make_archive('dist/b4k-win32', 'zip', 'dist/win32')

# make the win64 build
urllib.request.urlretrieve('https://bitbucket.org/rude/love/downloads/love-11.2-win64.zip', 'dist/love-win64.zip')
shutil.unpack_archive('dist/love-win64.zip', 'dist')
os.remove('dist/love-win64.zip')
os.rename('dist/love-11.2.0-win64', 'dist/win64')
shutil.copy2('dist/b4k.love', 'dist/win64/b4k.love')
os.chdir('dist/win64')
os.system('copy /b love.exe+b4k.love b4k.exe')
if os.name == 'nt':
	os.system('ResourceHacker -open b4k.exe -save b4k.exe -action modify -resource "../../assets/graphics/icon.ico" -mask ICONGROUP,1')
os.chdir('../..')
os.remove('dist/win64/changes.txt')
os.remove('dist/win64/b4k.love')
os.remove('dist/win64/game.ico')
os.remove('dist/win64/love.exe')
os.remove('dist/win64/love.ico')
os.remove('dist/win64/lovec.exe')
os.remove('dist/win64/readme.txt')
shutil.make_archive('dist/b4k-win64', 'zip', 'dist/win64')

# upload to itch
if input('Upload to Itch? [y/N] ')[0].lower() == 'y':
	os.system('butler push dist/win32 tesselode/b4k:win32')
	os.system('butler push dist/win64 tesselode/b4k:win64')
	os.system('butler push dist/b4k.love tesselode/b4k:love')
