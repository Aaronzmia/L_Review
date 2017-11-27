# -*- coding: utf-8 -*-

import struct
from datetime import datetime
import json
import time
import utils

class EventHeader(object):
	def __init__(self, buf):
		self.timestamp = utils.read_int(buf, 4)[1]
		self.event_type = utils.read_int(buf[4:], 1)[1]
		self.server_id = utils.read_int(buf[5:], 4)[1]
		self.event_size = utils.read_int(buf[9:], 4)[1]
		self.log_pos = utils.read_int(buf[13:], 4)[1]
		self.flags = utils.read_int(buf[17:], 2)[1]

	def __str__(self):
		res = {}
		res["timestamp"] = time.strftime("%Y-%m-%d %H:%M:%S", \
		time.localtime(self.timestamp))
		res["event_type"] = "%d"%int(self.event_type)
		res["server_id"] = self.server_id
		res["event_size"] = self.event_size
		res["log_pos"] = self.log_pos
		res["flags"] = "0x%.4x"%self.flags
		return json.dumps(res)
