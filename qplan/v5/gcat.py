import ConfigParser
import os
import gspread

# Read config info
config = ConfigParser.ConfigParser()
config.readfp(open(os.path.expanduser('~/.gcat.conf')))

# Log in
user = config.get('User info', 'user')
password = config.get('User info', 'password')
gc = gspread.login(user, password)

# Get data
# TODO: Read this from stdin (another ini format)
spreadsheet = gc.open_by_key('0AvCMfDyA42UTdFJldVh0dkREWjBzSHdwbVZMR0luekE')
worksheet = spreadsheet.get_worksheet(0)
list_of_lists = worksheet.get_all_values()

# Print to stdout
for row in list_of_lists:
        print '\t'.join(row)
