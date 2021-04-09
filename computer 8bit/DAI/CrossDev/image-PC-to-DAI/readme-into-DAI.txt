
IMPORTANT!
Bookmark this link, this is where Emil keeps the latest versions of programs:

https://github.com/emikulic/dai-gfx

====================================================================================

How to get a photo or an image from a modern computer to DAI?

	1. You need a photo or an image in JPG, PNG or GIF format; and
	2. You need the Python installed on today's computer in order to run enclosed programs; and
	3. You need to download generated data to DAI (via audio cable.)


In the Command line window on Windows run: pho2bin.py -h   (for help) or 
	this sequence of three commands:
 
	C:\DAI>pho2bin.py myimage.png myimage.png.bin
 	C:\DAI>bin2dai.py myimage.png.bin 63B8
	C:\DAI>dai2wav.py myimage.png.bin.BIN

Result of processing myimage.png:
	myimage.png.bin
	myimage.png.bin.BIN
	myimage.png.bin.BIN.WAV 
  

Done. 
Send the WAV file via CAS port to DAI to see your recent image on your DAI.
Thank you Emil and Pierre for marvelous code!

====================================================================================
Some people are interested in more details so I wrote here the "boring stuff". :)



How to get a selfy or any image displayed on DAI screen? 
The process takes three steps.



Step 1. 
Prepare the image you will send to DAI.
Select any photo or image you want. I tested and program works with GIF, JPG, PNG, TIF and TGA. 
It probably works with many other common formats, feel free to explore. 
The target image on DAI will be in 16 DAI colors (mode 5) or 4 DAI colors (mode 6).
Size of the target image on DAI is 352 x 256 pixels. 
You can process a photo of any size, height to width ratio or number of colors. 

It is a good idea to zoom and crop your photo in a photo editor (eg. Photoshop) and bring it to the closest values of the target image to eliminate unexpected surprises. 

I suggest to crop your photo to 352 x 256 pixels. 
Or at least keep the proportion x = 1.375*y; or y = 0.727272*y. 
Remember, you don't have to! 
(Among the X and Y, the larger side will be scaled down to the target size with proportionally scaled the smaller one too.) 

I also suggest to convert your photo to an index color palette mode.
If you do this you can use some very nice extra features eg. "ditherring". Besides, you will see very close result what will your photo look on DAI.
Open your photo in Photoshop and see if you want to crop it to 352 x 256. 
Also, try to reduce that size first and then scale it up by using "Neighboring pixels" method instead of "Bicubic" to get very coarse pixelated image. 
Select in File menu "Save for Web and Devices". 
Play with palette types, number of colors and dither. You don't need Transparency. 
Save it as something like "myimage.gif". 



Step 2. 
Process your photo in order to create a file which will be sent to DAI in it's native format.  
You need to install Python at least ver 3.7.4 on your computer (Windows, Mac or Linux). 
On the command line run provided programs in following order:

	pho2bin.py myimage.png myimage.png.raw.bin
 	bin2dai.py myimage.png.raw.bin 63b8
	dai2wav.py myimage.png.raw.bin.BIN 

I renamed original programs (which you can find in the enclosed folder) to help me to remember what they do. So, from the names above it is obvious that program

pho2bin.py    "Photo to binary" creates a raw binary file from practically any image.

If you use -h option you will get the help instructions which are:

infile, outfile   These file names HAVE TO be entered to proceed with processing.
-h (help)  
-mode (16gray / 4color)  This option forces the output image format. By default it will be 16 color.
-text (4lines.txt)  This option allows you to put any text eg. credits or name or message in the 4 lines of text in split mode. It will be displayed only during loading your image to DAI in graphic split mode. 
The text file may have maximum 22 characters in 4 lines.

"encoded 23624 bytes"  ... If you see this message displayed after processing means the image was successfully processed and binary file created. 

bin2dai.py   "Raw-binary to DAI-file-format binary" reads a raw-binary file created by pho2bin.py and creates a file ready to be imported to DAI. 
If you use -h option for help you will get the instruction: 

usage: bin2dai.py infile load_addr_hex   

This means you have to specify only the input file name and start-address for loading to DAI. For images in mode 5 and 6 always use 63B8 which will start loading the image from #63B8 in DAI RAM. 
The output from bin2dai.py is the file named same as input file with added ".BIN" eg:

bin2dai.py myimage.png.raw.bin 63b8
myimage.png.raw.bin.BIN	

Just feed it as the input file to dai2wav.py to get final WAV file:

dai2wav.py myimage.png.raw.bin.BIN 
This will create the WAV file identical to the file recorded on audio cassette through DAI CAS port. 
myimage.png.raw.bin.BIN.WAV

 

Step 3.
Load your image to DAI.
As Pierre Durant from Facebook DAInamic group suggested, the simplest way of sending the image data to DAI from any external computer is via audio cassette port. 
It was so strange to me, I never used audio cassette or CAS port on DAI ever. And now I am using it about 40 years later as the easiest method! 
Next, you will need a cable but unfortunately, I don't think you can buy one to the specification. It wil not be a problem if a soldering gun is your friend. Otherwise ask one of your DAI friends for help to make a simple audio cable. 

I use the connector on my PC (the one where people usually plug their headphones in audio card output) and connected it to the CAS 1 connector on DAI. I connected the signal from PC to go to pin 5 on DAI CAS port but please consult the DAI manual page 32 to make sure which one is the pin 5. 

- There are two CAS ports on DAi marked "CAS 1" and "CAS 2". Connect a PC-2-DAI audio cable to "CAS 1". It should have a standard male 3.5 mm mono plug (klinkenstecker) on the PC side and a 6 pin (270 degrees) DIN male connector on DAI side. NB.: It is a good idea to have both IN and OUT signals from DAI CAS through the same cable - just make two male mono plugs on the PC side - one for recording from DAI (DIN pin 1) and one for playing audio to DAI (DIN pin 5).
 
- "Power on" the DAI and start with the default Basic screen. 
By default the COLORG registers contain 0 5 10 15 (black, green, orange and white) colors. 
You don't have to change them but be aware that your photo will be displayed in these default colors during downloading in mode 6. You can type any combination if you want to watch loading in your colors eg. 
8 0 3 10 (gray, black, red and orange.) Image in 16 colors ignore the 4 colors settings.

- Type "MODE6" or "MODE5"
It is irrelevant which mode you choose for downloading. But it is very important that you remember which one it was because you wil need it later! Therefore, I always use "MODE6". Screen will initiate mode 6 with default background color 0 (black) unless you changed it. 
Four alphanumeric lines with black characters on gray background will open at the bottom of the screen. 

- Type CAS while in Basic. (If your cable is connected to port CAS 2 you need to type CAS2.) 

- Type UT to switch to Utility while still in mode 6A (or 5A if that was your preference.)

- In UT type R <Return> for reading the CAS port. Cursor on DAI is blinking.
- Press "Play" on your audio player on PC to play appropriate DAI WAV file you created. By several tests I found that the output level at 60% of loudness (using the VLC player) is reliable. 

- Check the cursor on DAI. If it stopped blinking your image is loading SUCCESSFULLY!
If cursor continue blinking you better stop the loading, tweak the audio output volume and try again. 

- Watch the progress, see the text message if you have set one and once your image is loaded you can stop the audio player. 
- You can save the loaded image on your MDCR, Floppy disc or SD-DOS: W63B8 BFFF MYIMAGE. (W for write in Utility)

- To enjoy watching your image in full size you need to switch to Basic and write two lines program: 
	10 MODE 6
	20 GOTO 20
	RUN 
	If you call a mode different to the one in which you loaded the image it will erase the screen! 



Good luck! This works perfectly well for me.
Tom Mikulic
2019-10-25

