#!/usr/bin/python

# -*- coding: utf-8 -*-
import os
import sys
import struct
import time
import binascii

from event import *


binlog='./mysql-bin.000001'

fileData = open(binlog, 'rb')

mcg_id, = struct.unpack('I', fileData.read(4))
print mcg_id
i = 0
while(i<10):
	buf = fileData.read(19)
	head = EventHeader(buf)
	print head.log_pos,":", head.__str__()
	print head.event_type
	if (head.event_type == 4):
		break
	fileData.seek(head.log_pos)
	i=i+1
