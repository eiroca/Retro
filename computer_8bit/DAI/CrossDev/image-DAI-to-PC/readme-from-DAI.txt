

IMPORTANT!
Bookmark this link, this is where Emil keeps the latest versions of programs:

https://github.com/emikulic/dai-gfx

====================================================================================


How to get an image from DAI to any modern computer?

	1. You need to send the image data to let's say a PC and save it in a text file; and
	2. You need the Python installed on today's computer in order to run enclosed "decode.py" program.


In the Command line window on Windows run: decode.py -h   (for help) or
 
	C:\DAI>decode.py myimage.txt   

Done. It's so simple, this is all you need. Thank you Emil for marvelous code!

====================================================================================
Some people are interested in more details so I wrote here the "boring stuff". :)




How to get the image data from DAI?

The simplest way in my configuration (DAI with MDCR) was to use the serial port RS232. 
Check in your garage if you have a PC box with a serial port.
I connected my old PC running Windows XP with DAI via RS232 cable. 
Start "putty.exe" in Windows. (Free and portable program.)

	Settings in putty:
		Connection type: Serial 
		Serial line: COM1  
		Speed (baud): 9600 
		Data bits: 8  
		Stop bits: 1 
		Parity: None 
		Flow control: None 

putty.exe opens a black console window with a green hollow rectangle prompt. It waits until it detects anything comming to the RS232 port on PC.

On DAI you are by default in Basic mode with "*" prompt.
Define the graphic mode, draw your image or get it from your tapes. Once you see on the DAI screen the image you want to convert you are ready. 
make sure you are in "alpha split" mode, e.g. you are supposed to see 4 alphanumeric lines at the bottom of the screen. The top of your image seems missing, don't worry Basic handles it promptly. 
Type "UT" to switch to DAI Utility, it will prompt with ">".

You need to know the start and end address of your image if you want to save it on the tape or disc and same if you want to send it to PC via RS232. Don't worry if you are not sure in addresses, use the range of the largest area taken by mode 5 and mode 6 and any smaller image will be included in this range and recognized by "convert.py". I always use these addresses:  

>D63B8 BFFF

This is the "magic" command, the only one you need ("Display") in DAI Utility. It lists the content of RAM between these two addresses in plain ASCII text format. The displayed values are addresses and bytes in hexadecimal values. e.g.:

63B8 00 00 FF FF FF FF FF FF
63C0 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
63D0 07 FF F0 FF FF FF FF FF FF FF FF FF FF FF FF FF
63E0 FF FF FF FF FF FF FF FF FF FF FF FF BF FF AF FF
63F0 1B FF 5D FF A0 5F 5C A3 F7 08 3F 00 EE D0 FF FF
6400 FF FF EF FF FF FF FF FF FF FF FF FF FF FF 00 00
6411 40 20 

DAI displays the data on its screen and sends it to the RS232 port. You can also see the data displayed on PC with the program "putty.exe" which also records it in it's log file. 

Capture data from #63B8 - #BFFF and save it in the text file eg. "myimage.txt".
This is all you need to extract image from it. (See the sample file Monalisa.txt.)

--------------------------------------------------------------------------------------------

Once you saved the image data in "myimage.txt" file open the Command line window in Windows and run:
	decode.py myimage.txt  

If processing was successful program generates a binary file and 2 pictures in PNG format:
	If your DAI image is in 16 color mode you will get 3 files:

		myimage.txt.png  	(Image in 16 colors specified by DAI palette.)
		myimage.txt.gray.png	(Image in 16 linearly graded black and white shades)  
		myimage.txt.bin  	(ASCII text file converted to actual binary content without descriptive addresses.)

	If your DAI image is in 4 color mode you will get 3 files:

		myimage.txt.png  	(Image in 4 colors specified in #BFF0-#BFFF, or in the "BLUES 1,9,12,15" if #BFFF is missing.)
		myimage.txt.gray.png	(Image in 4 linearly graded black and white shades)
		myimage.txt.bin  	(ASCII text file converted to actual binary content without descriptive addresses.)


NOTE: These raw binary files contain image data plus 568 bytes of alphanumeric insert at appropriate address!
This is because you can convert such raw-binary file into DAI-file format and further into WAV file for exchange between users.


-----------------------------------------------------------------------------------------

"decode.py" program is written by Emil Mikulic in October 2019. 
	Bookmark his GitHub repository for more DAI utilities: 
	https://github.com/emikulic/dai-gfx  

The Python program "decode.py" reads a text file, finds the DAI-specific graphic data in it and converts it into a PNG file.

It was tested in OCT 2019 and works fine in Python 3.7.4 on Windows 10.
It can convert any image generated in DAI Basic and saved in text file from DAI-UT.
In any standard graphic mode Basic splits the image in two parts and inserts 568 bytes of alphanumeric data between them.  

Full alphanumeric modes are not supported by "decode.py"

	Beware, Basic handles promptly the splitting of all standard graphic modes into their "alpha" versions e.g.:

	MODE 1 - MODE 1A, ...  MODE 6 - MODE 6A

	If an image was generated in non-standard graphic mode (by using POKE command) Basic will probably destroy part of the image by splitting it into 	"alpha" split mode. The image "Testbeeld" from DAInamic magazine is an example of such case. 

I archived a large number of images so the batch processing was very handy!

-----------------------------------------------------------------------------------------

