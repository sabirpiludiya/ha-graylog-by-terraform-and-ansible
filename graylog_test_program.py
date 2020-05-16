from pygelf import GelfTcpHandler, GelfUdpHandler, GelfTlsHandler, GelfHttpHandler
import logging
import time, threading
import socket
import sys
from datetime import datetime
from pytz import timezone
from tzlocal import get_localzone
format = "%Y-%m-%d %H:%M:%S"

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()


logger.addHandler(GelfUdpHandler(host=sys.argv[1], port=12201))


WAIT_TIME_SECONDS = 1


ticker = threading.Event()
while not ticker.wait(WAIT_TIME_SECONDS):
	now_utc = datetime.now(timezone('UTC'))
	now_local = now_utc.astimezone(get_localzone())
	time = (now_local.strftime(format))
	logger.info('Hey DevOps..! '+time)






