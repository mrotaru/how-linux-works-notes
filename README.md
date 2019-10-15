# How Linux Works - 2nd Ed

The book was released in 2015, and the Linux kernel has advanced a major version - from 4 to 5. However, it looks like the major version bump does not actually indicate major changes: https://itsfoss.com/linux-kernel-5/ so most things in the book should still be relevant.

## 1. The Big Picture

- layers of abstraction, high to low:
    1. user processes (GUI, web servers, shell)
    2. linux kernel (system calls, process and memory management, device drivers)
    3. hardware (CPU, RAM, disks, etc)
- user processes run in _user mode_, kernel processes in _kernel mode_
- user mode is more restrictive; mem. access is restricted and only a subset of CPU and mem operations are available
- all mem accessible by user mode processes: _user space_ or _user land_
- in _kernel mode_, a process has unlimited access to mem
- mem that can only be accessed in _kernel mode_: _kernel space_

### The Kernel
- determines which **processes** are allowed to use the CPU
- keeps track of **memory** - who can access what, what is free, what is shared, etc
- interface betw **hardware** and processes 
- provides **system calls** - used by processes to communicate with the kernel

### Process Management
- context switching - when kernel stops currently running process and starts executing another one
- each process gets a fraction of a second (_time slice_) to do it's thing before another context switch occurs

When CPU determines that the current process's _time slice_ is up:

1. CPU _interrupts_ current process, switches to kernel mode
2. kernel takes a snapshot of current CPU state and memory
3. cleanup - finish any tasks such as I/O
4. pick another process
5. prepare memory, then prepare CPU for the picked process
6. tell CPU how long the time slice will be
7. switch CPU into user mode, hand control of the CPU to the picked process

### Memory Management
- kernel must have private mem area, inaccessible to user processes
- user processes need own sections of mem, inaccessible to other user processes
- user processes can share mem
- some user process mem can be read-only
- user processes cannot access hw mem directly - kernel gives them virtual memory to play with
- [virtual memory](https://en.wikipedia.org/wiki/Virtual_memory) - allows disk mem to be "seen" as main (<abbr title="Random Access Memory">RAM</abbbr>) memory - page table
- CPUs have <abbr title="Memory Management Unit">MMU</abbr> - hardware support for memory address map

### Device Drivers and Management
- devices normally accessible only in kernel mode
- device drivers can be embedded into the kernel, or loadable modules (https://unix.stackexchange.com/questions/47208/what-is-the-difference-between-kernel-drivers-and-kernel-modules)
- "Linux Device Drivers, 3rd Ed" (2005) available for free: https://lwn.net/Kernel/LDD3/

### System Calls
- opening, reading, writing files - all done through system calls
- [`fork()`](http://man7.org/linux/man-pages/man2/fork.2.html) → kernel creates a nearly identical **copy** of the current process
- `exec(program)` →  kernel starts `program` as a child process, **replacing** the current process ([`execve()`](http://man7.org/linux/man-pages/man2/execve.2.html), [`execveat()`](http://man7.org/linux/man-pages/man2/execveat.2.html))
- `ls` in shell → `fork()` to "clone" current shell; in new shell: `exec(ls)` (why not `exec(ls)` in current ?)
- kernel also provides [_pseudodevices_](https://en.wikipedia.org/wiki/Device_file#Pseudo-devices) - `/dev/null`, `/dev/zero`, `/dev/random`
- ref: http://man7.org/linux/man-pages/man2/syscalls.2.html
- in-depth blog post, 2016: https://blog.packagecloud.io/eng/2016/04/05/the-definitive-guide-to-linux-system-calls/

### Users
- kernel identifies users by numeric _userid_
- every user-space process has a user _owner_, which process runs _as_
- users cannot interfere with other user's processes
- `root` user, aka `superuser` - can do anything to any process and any file

## 2. Basic Commands and Directory Hierarchy

### Shell
- Unix had Bourne shell - `/bin/sh`; Linux comes with `bash` - Bourne Again Shell
- default shell for each user - in `/etc/passwd`
- `/etc/shells` provides a list with all installed shells
- Ubuntu: default shell is `/bin/bash`, but `/bin/sh` is also installed by default
- Ubuntu: `/bin/sh` is **not** the Bourne shell; it's a symbolic link to `/bin/dash`
- `dash` is a modern POSIX-compliant implementation of Bourne shell (https://linux.die.net/man/1/dash)

#### Standard Input and Standard Output
- Unix processes use I/O _streams_ to read and write data
- kernel provides a standard input stream, used by some programs when input is not specified (ex: `cat`)
- <kbd>CTRL</kbd> + <kbd>D</kbd>: stops current standard input entry from terminal - which can also terminate the program
- <kbd>CTRL</kbd> + <kbd>C</kbd>: terminates current program
- kernel gives each program a standard output - normally connected to the terminal
- many commands are like `cat` - read from _stdin_ if no input stream specified
- output behavior varies more - some programs send output only to _stdout_, others can also write to files

#### Basic Commands
- `cp`, `mv` - when 2+ args, last one is dest dir, others are files to be copied/moved
- `touch` - creates file; if existing, updates the modification timestamp
- `*` glob pattern matches any number of characters - including  - while `?` matches 1 character

#### Intermediate Commands
- `grep root /etc/*` - check every file in `/etc`, including subdirs, for "root"
- common `grep` flags: `-i` - case insensitive, `-v` - invert
- `less`: view file one screenful at a time; <kbd>Space</kbd> for next screenful, <kbd>b</kbd> for previous, <kbd>q</kbd> to quit
- `less`: to search for "foo": <kbd>/foo</kbd>; <kbd>n</kbd> - next match; <kbd>?foo</kbd> - search backward
- can pipe command output to it: `grep ie /usr/share/dict/words | less`
- `less` is an enhanced vers of `more`
- `diff f1 f2` shows human-readable output by default; use `-u` for machine-readable patch
- `file` command shows details about the file - such as encoding, what type of binary it is, etc
- `find /etc/ -name passwd -print` - print all files named `passwd` in `/etc`
- `head`, `tail` - print first and last lines of a file; how many lines ? 10 by default, configrable with `-n`
- `sort` - sort lines in a file, alphanumerically by default; `-n` to compare by string numerical value
- files with name starting with `.` not shown by `ls` by default; use `ls -a` to see them
- shell globs don't match dot files, unless explicitly included: `.*`
- use `.[^.]` or `.??*` to exclude current (`.`) and parent (`..`) directories

#### Variables
```bash
FOO=bar # shell variable; is temporary, and "dies" with the current shell
BAR="contains spaces" # use quotes if value contains whitespace chars
export FOO # make the shell variable into an environment variable
```
- `export` makes a shell variable available to current process's _child_ processes
- parent process will not "see" variables `export`ed by child processes (https://askubuntu.com/q/53177/20187)
- to "load" variables not present in the environment, use `source`: `source file-with-vars`

#### Moving Around on the Command Line
- <kbd>CTRL</kbd> - <kbd>B</kbd> - mv cursor left
- <kbd>CTRL</kbd> - <kbd>F</kbd> - mv cursor right
- <kbd>CTRL</kbd> - <kbd>P</kbd> - view prev command, or mv cursor up
- <kbd>CTRL</kbd> - <kbd>N</kbd> - view next command, or mv cursor down
- <kbd>CTRL</kbd> - <kbd>A</kbd> - mv cursor to start of line
- <kbd>CTRL</kbd> - <kbd>E</kbd> - mv cursor to end of line
- <kbd>CTRL</kbd> - <kbd>W</kbd> - erase preceding word
- <kbd>CTRL</kbd> - <kbd>U</kbd> - erase from cursor to start of line
- <kbd>CTRL</kbd> - <kbd>K</kbd> - erase from cursor to end of line
- <kbd>CTRL</kbd> - <kbd>Y</kbd> - paste erased text

#### Command Documentation
- `man` pages contain dry reference information - they're not tutorials
- `man -k sort` - shows a list of all manual pages which include the "sort" keyword
- `man 5 passwd` - show section `5` (see below) of `passwd` manual - info about `/etc/passwd` file

##### Manual Sections
- `1` - user commands
- `2` - system calls
- `3` - higher-level Unix programming library docs
- `4` - device interface and driver information
- `5` - file descriptions - system configuration files
- `6` - games
- `7` - file formats, conventions and encodings
- `8` - system commands and servers

## Other Resources
- "live" book about Linux internals: https://0xax.gitbooks.io/linux-insides/content/