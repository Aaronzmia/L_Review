#!/usr/bin/python

# -*- coding: utf-8 -*-
import os
import sys
import struct
import time
import binascii

binlog='./mysql-bin.000001'

fileData = open(binlog, 'rb')

mcg_id, = struct.unpack('I', fileData.read(4))
print mcg_id
t = struct.unpack('I', fileData.read(4))[0]
ti = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(t))
print ti
event_type = struct.unpack('c', fileData.read(1))[0]
print "evdnt_type: %s" % hex(ord(event_type))
server_id = struct.unpack('I', fileData.read(4))[0]
print "server_id", server_id
event_size = struct.unpack('I', fileData.read(4))[0]
print "event_size ",event_size
log_pos = struct.unpack('I', fileData.read(4))[0]
print "next_log_pos " ,log_pos
flags = struct.unpack('h', fileData.read(2))[0]
print "event flags: ", flags
bfv = struct.unpack('h', fileData.read(2))[0]
print "binlog format: ", bfv
server_version = struct.unpack('50s', fileData.read(50))[0]
print "server_version: ",server_version
t = struct.unpack('I', fileData.read(4))[0]
create_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(t))
print create_time
chl = struct.unpack('c', fileData.read(1))[0]
print "header length: ",ord(chl)
fileData.seek(log_pos)

