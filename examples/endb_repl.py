#!/usr/bin/env python3

import cmd
import endb
import pprint
import urllib.error

class EndbShell(cmd.Cmd):
    file = None

    def __init__(self, url, accept='application/ld+json', username=None, password=None, prompt='-> '):
        super().__init__()
        self.url = url
        self.accept = accept
        self.username = username
        self.password = password
        self.prompt = prompt

    def emptyline(self):
        pass

    def complete_accept(self, text, line, begidx, endidx):
        return [x for x in ['application/json', 'application/ld+json', 'text/csv'] if x.startswith(text)]

    def do_accept(self, arg):
        'Accepted mime type.'
        if arg:
            self.accept = arg
        print(self.accept)

    def do_url(self, arg):
        'Database URL.'
        if arg:
            self.url = arg
        print(self.url)

    def do_username(self, arg):
        'Database user.'
        if arg:
            self.username = arg
        print(self.username)

    def do_password(self, arg):
        'Database password.'
        if arg:
            self.password = arg
        if self.password:
            print('*******')
        else:
            print(None)

    def do_quit(self, arg):
        'Quits the console.'
        return 'stop'

    def default(self, line):
        if line == 'EOF':
            return 'stop'
        try:
            auth = None
            if self.username and self.password:
                auth = (self.username, self.password)
            result = endb.sql(line, accept=self.accept, url=self.url, auth=auth)
            if self.accept == 'text/csv':
                print(result.strip())
            else:
                pprint.pprint(result)
        except urllib.error.HTTPError as e:
            print('%s %s' % (e.code, e.reason))
            body = e.read().decode()
            if body:
                print(body)
        except urllib.error.URLError as e:
            print(self.url)
            print(e.reason)

if __name__ == "__main__":
    import sys
    url = 'http://localhost:3803/sql'
    if len(sys.argv) > 1:
        url = sys.argv[1]
    prompt = '-> '
    if not sys.stdin.isatty():
        prompt = ''
    try:
        EndbShell(url, prompt=prompt).cmdloop()
        if sys.stdin.isatty():
            print()
    except KeyboardInterrupt:
        print()
        pass
