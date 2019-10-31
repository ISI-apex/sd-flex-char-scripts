#!/usr/bin/python
#
# Expects two arguments, start and end date, in ISO 8601 format, i.e.,
# YYYY-MM-DD'T'hh:mm:ss.SSS'Z' (without quotes), e.g., 2019-10-30T21:31:23.877Z
#
import dateutil.parser
import sys

du_s = dateutil.parser.parse(sys.argv[1])
du_e = dateutil.parser.parse(sys.argv[2])
elapsed = du_e - du_s

print(elapsed.total_seconds())
