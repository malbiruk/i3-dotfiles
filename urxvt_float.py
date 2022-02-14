#!/usr/bin/python3

import sys
import subprocess
import i3ipc

i3 = i3ipc.Connection()

def on(i3, e):
    if e.container.window_class == 'URxvt':
        i3.command('floating enable')
        sys.exit(0)

i3.on('window::new', on)
try:
    subprocess.Popen(['urxvt'], close_fds=True)
    i3.main()
finally:
    i3.main_quit()
