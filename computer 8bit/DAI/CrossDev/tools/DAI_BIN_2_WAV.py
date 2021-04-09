#!/usr/bin/env python3
# This program convert DAI file format to WAV file which can
# be loaded by a real DAI computer as well by the eamulator (under Mame)
# It's based on the work (analysis of the tape format of the DAI, program to convert DAI file to WAV for Windows)
# done by Bruno Vivien and available on his website: http://bruno.vivien.pagesperso-orange.fr/DAI/index.htm
#
# Program V1.0 by Pierre Durant - 2019
# V1.2  - Performance improvement + possibility to use it with the command line - by Emil Mikulic - 2019

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
filesize = 0

# Write a BIT
# Pre-Leader: 1 x 00-80
# Leader: 7 x FF-7F / 7 x 00-80 / 7 x FF-7F / 7 x 00-80
# 1: 22 x FF-7F / 22 x 00-80 / 14 x FF-7F / 14 x 00-80
# 0: 14 x FF-7F / 14 x 00-80 / 22 x FF-7F / 22 x 00-80
# Trailer: 10 x FF-7F / 10 x 00-80 / 14 x FF-7F / 14 x 00-80
def Write_Bit (type_bit,f2):
    global filesize
    nbre_a = 0
    nbre_b = 0

    if type_bit == "1": # for a "1"
        nbre_a = 11
        nbre_b = 7
    else: 
        if type_bit == "0": # for a "0"
            nbre_a = 7
            nbre_b = 11
        else: 
            if type_bit == "L": # For the Leader
                nbre_a = 7
                nbre_b = 7
            else:
                nbre_a = 5 # For the Trailer
                nbre_b = 7

    if type_bit != "PL": # all except the PreLeader
        f2.write(bytes([255, 127]) * nbre_a)
        filesize += 2 * nbre_a
        f2.write(bytes([0, 128]) * nbre_a)
        filesize += 2 * nbre_a
        f2.write(bytes([255, 127]) * nbre_b)
        filesize += 2 * nbre_b
        f2.write(bytes([0, 128]) * nbre_b)
        filesize += 2 * nbre_b
    else:   # For the PreLeader
        f2.write(bytes([0, 128]))
        filesize += 2

# Decompose a Byte in Bits String 
# and write them
def Write_Byte (value,file_output):
    for i in range(8):
        if value[0] & (1 << (7-i)):
            Write_Bit("1",file_output)
        else:
            Write_Bit("0",file_output)


# Main Convert function
def Convert(oldname):   
    global filepathname
    global filesize
    filesize = 0
    f2 = open(directory + '/' + oldname + '.WAV', "wb")

    # Write the styandard WAV header
    # RIFF marker
    f2.write(b'RIFF')
    # file-size (equals file-size - 8) (4 bytes)
    temp = 0000
    f2.write(temp.to_bytes(4, byteorder='little', signed=True))
    # Mark it as type "WAVE"
    f2.write(b'WAVE')
    # Mark the format section
    f2.write(b'fmt ')
    # Length of format data. Allways 16 (4 bytes)
    temp = 16
    f2.write(temp.to_bytes(4, byteorder='little', signed=True))
    # Wave type PCM (2 bytes)
    temp = 1
    f2.write(temp.to_bytes(2, byteorder='little', signed=True))
    # 1 Channel (2 bytes)
    temp = 1
    f2.write(temp.to_bytes(2, byteorder='little', signed=True))
    # kHz Sample Rate (4 bytes)
    temp = 8790
    f2.write(temp.to_bytes(2, byteorder='big', signed=True))
    temp = 0
    f2.write(temp.to_bytes(2, byteorder='big', signed=True))
    # (Sample Rate * Bit Size * Channels) / 8 (4 bytes)
    temp = 17580
    f2.write(temp.to_bytes(2, byteorder='big', signed=True))
    temp = 0
    f2.write(temp.to_bytes(2, byteorder='big', signed=True))
     # (Bit Size * Channels) / 8 (2 bytes)
    temp = 2
    f2.write(temp.to_bytes(2, byteorder='little', signed=True))
    # Bits per sample (=Bit Size * Samples) (2 bytes)
    temp = 16
    f2.write(temp.to_bytes(2, byteorder='little', signed=True))
    # "data" marker
    f2.write(b'data')
     # ata-size (equals file-size - 44)
    temp = 0000
    f2.write(temp.to_bytes(4, byteorder='little', signed=True))

    # DAI tape pre-leader & leader
    i = 0
    while i < 45:
        Write_Bit("PL",f2)
        i += 1
    i = 0
    while i < 1834:
        Write_Bit("L",f2)
        i += 1
    Write_Bit("1",f2)
    Write_Byte(bytes([85]),f2)

    # Read BIN File
    # and write the corresponding bytes
    with open(filepathname, "rb") as f1:
        byte = f1.read(1)
        while byte:
            Write_Byte(byte,f2)
            byte = f1.read(1)
    f1.close()

    # Write the DAI tape trailer
    i = 0
    while i < 74:
        Write_Bit("T",f2)
        i += 1
    Write_Bit("1",f2)

    # Write the filesize int the WAV header
    f2.seek(4)    
    temp = filesize - 8
    f2.write(temp.to_bytes(4, byteorder='little', signed=True))
    f2.seek(40)    
    temp = filesize - 44
    f2.write(temp.to_bytes(4, byteorder='little', signed=True))

    f2.close()


def Open():   
    global filepathname
    global filename
    global directory

    filepathname = askopenfilename(title="Open a DAI File",filetypes=[('BIN files','.BIN'),('bin files','.bin'),('all files','.*')])
    directory = os.path.dirname(filepathname)
    filename = os.path.basename(filepathname)
    if filename != "":
        newWindow()


def newWindow():
    Nfen = Toplevel()
    Nfen.geometry('300x80')
    Nfen.resizable(width=False, height=False)
    Nfen.title("DAI File Format to WAV file Converter")

    LNom = Label(Nfen,text='Name: ')
    LNom.grid(row =1, column =1, sticky='W', padx=5, pady=5)
    Nom = Label(Nfen,text=os.path.splitext(filename)[0])
    Nom.grid(row =1, column =2, sticky='W', padx=5, pady=5)

    Conv = Button(Nfen, text ="Convert", command =lambda: Convert(os.path.splitext(filename)[0]))
    Conv.grid(row =5, column =2, padx=5, pady=5)


########################################################################################
# Main Program
if len(sys.argv) == 2:
    directory = '.'
    filepathname = sys.argv[1]
    Convert(filepathname)
    sys.exit(0)

fen = Tk()
fen.geometry('400x100') 
fen.title("DAI BIN FIle to WAV") 

menubar = Menu(fen)
filemenu = Menu(menubar, tearoff=0)
filemenu.add_command(label="Open", command=Open)
filemenu.add_command(label="Exit", command=fen.destroy)
menubar.add_cascade(label="File", menu=filemenu)
fen.config(menu=menubar)

fen.mainloop()
