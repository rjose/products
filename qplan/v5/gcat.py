#!/usr/bin/env python

import ConfigParser
import os
import sys
import gspread

# Read config info
config = ConfigParser.ConfigParser()
config.readfp(open(os.path.expanduser('~/.gcat.conf')))

# Log in
user = config.get('User info', 'user')
password = config.get('User info', 'password')
gc = gspread.login(user, password)

# Read in spreadsheet source info
source_info = ConfigParser.ConfigParser()
source_info.readfp(sys.stdin)

def cat_tables(section):
        print "=====%s" % section
        for p in source_info.items(section):
                [spreadsheet_key, worksheet_index] = p[1].split(":")
                spreadsheet = gc.open_by_key(spreadsheet_key)
                worksheet = spreadsheet.get_worksheet(int(worksheet_index))
                list_of_lists = worksheet.get_all_values()
                for row in list_of_lists:
                        print '\t'.join(row)
        return

sections = ['Work', 'Staff']
for s in sections:
        cat_tables(s)
