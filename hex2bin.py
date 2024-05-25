#!/bin/env python

import sys

if len(sys.argv) < 3:
    print("usage: hex2bin.py <inFile> <outFile>")
    exit()


inFile = open(sys.argv[1], "r")

outFile = open(sys.argv[2], "wb")

inBytes: str = inFile.read()

inBytes = inBytes.replace(" ", "")
inBytes = inBytes.replace("\n", "")
inBytes = inBytes.replace("\t", "")
inBytes = inBytes.replace("\r", "")

outBytes = []

print("totalBytes", len(inBytes) / 2)
print(inBytes)
for i in range(0,len(inBytes), 2):
    by = int(inBytes[i:(i+2)], 16).to_bytes(1)
    print(hex(by[0]))
    outFile.write(by)

outFile.close()
