#!/usr/bin/python3

import argparse
import os

def read_file(filename):
    with open(filename) as f:
        f = f.read().split('\n')
    return f


def find_current_theme(gtkpath):
    f = read_file(gtkpath)
    return f[2].split('=')[1]


def change_theme_to(theme, gtkpath, notify=False):
    f = read_file(gtkpath)
    gtk_theme_name = f[2].split('=')[0]
    changed_gtk_line = ['='.join([gtk_theme_name, theme])]
    f_updated = f[:2] + changed_gtk_line + f[3:]
    with open(gtkpath, 'w') as f:
        f.write('\n'.join(f_updated))
    if notify:
        os.popen(
            f'notify-send "GTK theme was switched to {theme}\n'
            'Applications need to be restarted for changes to take place"')


def swap_themes(theme_current, theme_1, theme_2, gtkpath, notify=False):
    if theme_current == theme_1:
        change_theme_to(theme_2, gtkpath, notify)
    elif theme_current == theme_2:
        change_theme_to(theme_1, gtkpath, notify)
    else:
        raise ValueError('current theme is not specified, cannot toggle')


def main():
    parser = argparse.ArgumentParser(
        description='toggle GTK themes between theme_1 and theme_2 '
        'or just apply one of the themes if --apply is specified',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-tl', dest='theme_1',
                        default='Orchis-light-compact',
                        help='specify light theme')
    parser.add_argument('-td', dest='theme_2',
                        default='Nordic-darker-standard-buttons-v40',
                        help='specify dark theme')
    parser.add_argument('--apply', choices=['tl', 'td'],
                        help='don\'t toggle between themes, just apply one of them')
    parser.add_argument('--notify', action='store_true',
                        help='turn on notifications')
    parser.add_argument('-p', '--path', help='path to config file',
                        default='/home/klim/.config/gtk-3.0/settings.ini')

    args = parser.parse_args()

    if args.apply is None:
        theme_current = find_current_theme(args.path)
        swap_themes(theme_current, args.theme_1,
                    args.theme_2, args.path, args.notify)
    else:
        apply_theme = args.theme_1 if args.apply == 'tl' else args.theme_2
        change_theme_to(apply_theme, args.path, args.notify)


if __name__ == '__main__':
    main()
