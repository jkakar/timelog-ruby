A command-line driven time-tracking tool inspired by GTimeLog.

## Usage

This simple command line tool is inspired by GTimeLog:

  http://mg.pov.lt/gtimelog/

It behaves almost the same way, but has a command-line interface,
instead of a graphical UI.

### Starting the day

Start the day by typing *Arrived* to start the clock.

```bash
timelog "Arrived"
```

### Switching activities

When you switch to an activity, tell the timelog what you were doing
before you start the new activity:

```bash
timelog "Reading mail"
```

### Slacking

If you don't want the activity you were doing to count as time spent
working use two asterisks to mark it as slacking:

```bash
timelog "Lunch **"
```

### Status update

Running the `timelog` command by itself will print a simple report
showing you what you've done, how many hours you've worked and how
many hours you have left before the day is over.  Slacking activities
aren't included in the totals.


## License

Copyright (c) 2012, Jamshed Kakar <jkakar@kakar.ca>
All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
