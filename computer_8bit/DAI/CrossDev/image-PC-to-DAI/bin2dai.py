#!/usr/bin/env python3
# Program to convert a BINary file to a Binary DAI File Format (machine language to be loaded under UT)
# Mainly, the job consist to add a correct Leader and Trailer
# The user has to specify the DAI name (use in the header & as name of the new file) and the adress 
# where the file is supposed to be loaded on the DAI
# It's based on the work (analysis of the different DAI Files Formats) 
# done by Bruno Vivien and available on his website: http://bruno.vivien.pagesperso-orange.fr/DAI/index.htm
#
# Program V1.0 by Pierre Durant - 2019

from tkinter import *
from tkinter.scrolledtext import ScrolledText
from tkinter.messagebox import *
from tkinter.filedialog import *

import tkinter.font as tkFont
import tkinter.ttk as ttk
import os
import sys


filepathname = ''
filename =''
directory = ''

# Calculate the checksum
# fpollowing the DAI protocol
def Checksum(cs,nombre):
    ret = 0
    cs = cs ^ nombre
    if cs >= 128:
        ret = 1
    cs = cs << 1
    cs = cs & 255
    if ret == 1:
        cs = cs + 1
    return cs

# Main Convert function
def Convert(newname,startadr):   
    global filepathname
    tempInt = 0

    fn = f'{directory}/{newname}.BIN'
    print(f'writing to {fn}')
    f2 = open(fn, "wb")

    # File Type = 49 (31H for Binary file to load in UT with "R" command)
    f2.write(bytes([49]))

    # Name Length
    FNLength = len(newname)
    cs = 86
    f2.write(bytes([0]))
    cs = Checksum(cs,0)
    f2.write(bytes([FNLength]))
    cs = Checksum(cs,FNLength)
    f2.write(bytes([cs]))

    # Name
    cs = 86
    for car in newname:
        c = ord(car)
        f2.write(bytes([c]))
        cs = Checksum(cs,c)
    f2.write(bytes([cs]))

    # Length of Address
    f2.write(bytes([0]))
    f2.write(bytes([2]))
    f2.write(bytes([93]))

    # Start Address
    cs = 86
    Istartadr =int(startadr, 16)
    stadrL= Istartadr & 255
    Istartadr = Istartadr >> 8
    stadrH = Istartadr & 255
    f2.write(bytes([stadrL]))
    cs = Checksum(cs,stadrL)
    f2.write(bytes([stadrH]))
    cs = Checksum(cs,stadrH)
    f2.write(bytes([cs]))

    # Length of Content
    tempint = os.stat(filepathname).st_size
    longL = tempint & 255
    tempint = tempint >> 8
    longH = tempint & 255
    cs = 86
    f2.write(bytes([longH]))
    cs = Checksum(cs,longH)
    f2.write(bytes([longL]))
    cs = Checksum(cs,longL)
    f2.write(bytes([cs]))

    # Content
    # Original file read and added to the DAI file
    cs = 86
    with open(filepathname, "rb") as f1:
        byte = f1.read(1)
        while byte:
            f2.write(byte)
            cs = Checksum(cs,int.from_bytes(byte,"big"))
            byte = f1.read(1)
    f2.write(bytes([cs]))
    f2.close()


def Open():   
    global filepathname
    global filename
    global directory

    filepathname = askopenfilename(title="Open a file .BIN",filetypes=[('BIN files','.BIN'),('bin files','.bin'),('all files','.*')])
    directory = os.path.dirname(filepathname)
    filename = os.path.basename(filepathname)
    if filename != "":		  
        newWindow()


def newWindow():
    Nfen = Toplevel()
    Nfen.resizable(width=False, height=False)
    Nfen.title("BIN Converter to DAI File Format")

    LNom = Label(Nfen,text='Name: ')
    LNom.grid(row =1, column =1, sticky='W', padx=5, pady=5)
    Nom = Label(Nfen,text=os.path.splitext(filename)[0])
    Nom.grid(row =1, column =2, sticky='W', padx=5, pady=5)
    LDNom = Label(Nfen,text='DAI Name: ')
    LDNom.grid(row =2, column =1, sticky='W', padx=5, pady=5)
    DNom = Entry(Nfen)
    DNom.grid(row =2, column =2, sticky='W', padx=5, pady=5)
    DNom.focus_set()
    LAdr = Label(Nfen,text= 'Start Address: ')
    LAdr.grid(row =3, column =1, sticky='W', padx=5, pady=5)
    Adr = Entry(Nfen)
    Adr.grid(row =3, column =2, sticky='W', padx=5, pady=5)

    Conv = Button(Nfen, text ="Convert", command =lambda: Convert(DNom.get().upper(),Adr.get()))
    Conv.grid(row =5, column =2, padx=5, pady=5)


########################################################################################
# Main Program
if len(sys.argv) not in [1, 3]:
    print(f'usage: {sys.argv[0]} infile load_addr_hex')
    sys.exit(1)
if len(sys.argv) == 3:
    directory = '.'
    filepathname = sys.argv[1]
    addr = sys.argv[2]
    Convert(filepathname, addr)
    sys.exit(0)

fen = Tk()

menubar = Menu(fen)

fen.geometry('400x100') 
fen.title("Converter BIN 2 DAI File") 
filemenu = Menu(menubar, tearoff=0)
filemenu.add_command(label="Open", command=Open)
filemenu.add_command(label="Exit", command=fen.destroy)
menubar.add_cascade(label="File", menu=filemenu)
fen.config(menu=menubar)

fen.mainloop()
