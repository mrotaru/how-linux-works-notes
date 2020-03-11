# Learning Linux

Notes based primarily on "How Linux Works" (2nd Ed), extended with information from many other sources. The book was released in 2015, and the Linux kernel has advanced a major version - from 4 to 5. However, it looks like the major version bump does not actually indicate major changes: https://itsfoss.com/linux-kernel-5/ so most things in the book should still be relevant.

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
- "live" book about Linux internals: https://0xax.gitbooks.io/linux-insides/content/

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

#### Redirection
- `ls > file.txt`  - file.txt will be "clobbered" if already existing
- `ls >> file.txt`  - output of `ls` will be _appended_ to file.txt
- `ls 2> errors.txt` - redirect STDERR to errors.txt
- `ls 2>&1` - redirect STDERR to STDOUT
- `head < ls` ≡ `ls | head`
- https://en.wikipedia.org/wiki/Standard_streams
- gregs: https://mywiki.wooledge.org/BashGuide/InputAndOutput#Redirection
- man: https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Redirections

#### Managing Processes
- `ps x` - show all _yours_
- `ps ax` - show all - not just yours
- `ps u` - more details
- `ps w` - full command names (wide output)
- `ps auwx` - the full monty
- more examples in man: http://man7.org/linux/man-pages/man1/ps.1.html#EXAMPLES
- `kill 42` - send `SIGTERM` signal to process with PID `42` (signals: http://man7.org/linux/man-pages/man7/signal.7.html)
- `kill -TERM 42` ≡ `kill 42` - short version of signal name (without SIG) can be used
- `SIGSTOP` and `SIGCONT` can be used to suspend/resume processes (`kill -STOP 42` and `kill -CONT 42`)
- <kbd>CTRL</kbd> - <kbd>C</kbd> - same as `kill -INT` for current process (`SIGINT`)

##### Job Control
- https://en.wikipedia.org/wiki/Job_control_(Unix)#Implementation
- `jobs` shows current background jobs
- `bg` - resume suspended jobs in background
- `fg` - resume suspended jobs in foreground
- <kbd>CTRL</kbd> - <kbd>Z</kbd> - sends `SIGTSTP` to current process; similar to `SIGSTOP` (https://stackoverflow.com/a/11888074/447661)

##### Background Processes
- not the same as jobs
- https://unix.stackexchange.com/questions/4214/what-is-the-difference-between-a-job-and-a-process
- `gunzip file.gz &` - detach process from shell, put it in the background; `PID` printed as response
- background processes can still write to stdout and stderr - redirect to ensure this doesn't happen

#### File Modes and Permissions

- file "mode" represented with 10 characters: `TUUUGGGOOO`
  - T: type; "-" → regular file; "d" → directory
  - UUU: user permissions
  - GGG: group permissions
  - OOO: other/world permissions
  - each permission: 0 - read, 1 - write, 2 - execute (for dirs, execute = list files inside)
- `chmod g+r file` - set the groups (`g`) "read" (`r`) bit to `1` (add read permission)
- `chmod g-r file` - set the groups (`g`) "read" (`r`) bit to `0` (remove read permission)
- `chmod go+r file` - set `g` _and_ `o` to 1
- the `-R` flag can be used to apply modes recursively
- capital mode means only apply to dirs: `chmod -R a+rX *` - set `x` just for dirs (https://stackoverflow.com/a/14634721/447661)
- `sudo chmod -R u+rwX,g+rwX,o+rX .` - recursive; files to 664, dirs to 775

Modes:
- 4: `r` → `100`
- 2: `w` → `010`
- 1: `x` → `001`
- `rwx` → `111` → 4 + 2 + 1 = 7
- `rw-` → `110` → 4 + 2 + 0 = 6
- `r--` → `100` → 4 + 0 + 0 = 4
- `r-x` → `101` → 4 + 0 + 1 = 5
- `644` → `rw-r--r--` (files)
- `600` → `rw-------` (files)
- `755` → `rwxr-xr-x` (exe/dirs)
- `700` → `rwxr-----` (exe/dirs)
- `711` → `rwxr-1--1` (dirs)

#### Links

- `ln -s existing_target new_link`
- if inverted, creates cyclical (broken) link
- to find broken links (dest. missing): `find . -xtype l` (https://unix.stackexchange.com/a/38691/39603)
- to find broken links (dest. missing, _or_ cyclical): `find /path/to/search -type l -exec test ! -e {} \; -print` (https://serverfault.com/a/433273)

#### Archiving
- can't use `gzip` to zip a folder - only works for files
- use `tar` to "concatenate" files together: `tar cvf file1 file2 ...` 
- `tar xvf archive.tar` - unpack in current dir (`x` - e**x**tract)
- `tar t archive.tar` - list contents, basic integrity check
- `p` flag will **p**reserve permission bits, overriding local `umask`
- `p` is used implicitly when operating as the superuser
- permissions are set **after** extraction is complete - so let `tar` finish
- with `.tar.gz` files, first resolve `.gz` (with `gunzip`) the `.tar` (with `tar x`)
- or: `zcat file.tar.gz | tar xvf -`
- `tar` also has `z` flag:
    - to verify compressed archive: `tar ztvf file.tar.gz`
    - to extract compressed archive: `tar xzvf file.tar.gz`
    - to create compressed archive: `tar czvf file.tar.gz`
- the `j` flag should be used instead of `z` for `bzip`-compressed files
- `zip`/`unzip` also come with most distributions

### Directory Hierarchy

- https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
- https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard
- `/` - root
    - `/bin` - `ls`, `cp`, ... - binary (and script) utils for all users
    - `/dev` - device files
    - `/etc` - core system config
    - `/home` - personal dirs for regular users
    - `/lib` - shared libraries
        - `/lib/modules` - loadable kernel modules
    - `/proc` - system statistics
    - `/sys` - similar to `/proc` - device and system interface
    - `/sbin` - system executables - often not in user's `$PATH`, many require root
    - `/tmp` - temporary - accessible to all users
    - `/usr` - lots of stuff; most of the OS; similar layout to `/`; exists for historic reasons
        - `/usr/include` - `C` header files
        - `/usr/info` - GNU info manuals
        - `/usr/local` - where sysadmins should install software
        - `/usr/man` - manual pages
        - `/usr/share` - exists mostly for historic reasons
    - `/var` - logs, caches, etc
    - `/boot` - kernel boot loader files
        - `/boot/vmlinuz` - kernel; boot loader loads it into memory
    - `/media` - where removable devices would be attached
    - `/opt` - additional third-party software; many distros don't use it

## 3. Devices

- `/dev/null` is a device - it simply discards any input
- device files are in `/dev` 
- `b` - block, `c` - character, `p` - pipe, `s` - socket
- doesn't look like there is a single pipe or socket in Ubuntu 18.04 LTS

```
$ cd /dev && ls -l # output truncated
crw-rw-rw- 1 root root      1,   3 Mar  2 12:40 null
brw-rw---- 1 root disk      8,   0 Mar  2 12:40 sda
brw-rw---- 1 root disk      8,   1 Mar  2 12:40 sda1
brw-rw---- 1 root disk      8,   2 Mar  2 12:40 sda2
drwxr-xr-x 2 root root          60 Mar  2 12:40 usb
crw-rw-rw- 1 root tty       5,   0 Mar  2 12:40 tty
crw--w---- 1 root tty       4,   0 Mar  2 12:40 tty0
crw--w---- 1 root tty       4,   1 Mar  2 12:40 tty1
crw--w---- 1 root tty       4,  10 Mar  2 12:40 tty10
```
- in `/dev`, name doesn't say much; also, devices are added as they are found
- so `/sys/devices` offers more information
- https://mirrors.edge.kernel.org/pub/linux/docs/lanana/device-list/devices-2.6.txt

```
$ ls /sys
block  bus  class  dev  devices  firmware  fs  hypervisor  kernel  module  power

$ ls /sys/dev
block  char

$ ls /sys/devices/
breakpoint  cpu  ibs_fetch  ibs_op  isa  LNXSYSTM:00  msr  pci0000:00  platform  pnp0  software  system  tracepoint  virtual
```
- `udevadm` can be used to obtain more information about a device   :

```
$ udevadm info --query=all --name=/dev/sda
P: /devices/pci0000:00/0000:00:14.1/ata1/host0/target0:0:1/0:0:1:0/block/sda
N: sda
S: disk/by-id/ata-Samsung_SSD_860_PRO_256GB_S42VNF0M805065Y
S: disk/by-id/wwn-0x5002538e99843e08
S: disk/by-path/pci-0000:00:14.1-ata-1
E: DEVLINKS=/dev/disk/by-id/wwn-0x5002538e99843e08 /dev/disk/by-path/pci-0000:00:14.1-ata-1 /dev/disk/by-id/ata-Samsung_SSD_860_PRO_256GB_S42VNF0M805065Y
E: DEVNAME=/dev/sda
E: DEVPATH=/devices/pci0000:00/0000:00:14.1/ata1/host0/target0:0:1/0:0:1:0/block/sda
E: DEVTYPE=disk
E: ID_ATA=1
E: ID_ATA_ROTATION_RATE_RPM=0
E: ID_ATA_SATA=1
E: ID_ATA_SATA_SIGNAL_RATE_GEN1=1
E: ID_ATA_SATA_SIGNAL_RATE_GEN2=1
E: ID_ATA_WRITE_CACHE=1
E: ID_ATA_WRITE_CACHE_ENABLED=0
E: ID_BUS=ata
E: ID_MODEL=Samsung_SSD_860_PRO_256GB
E: ID_MODEL_ENC=Samsung\x20SSD\x20860\x20PRO\x20256GB\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20
E: ID_PART_TABLE_TYPE=gpt
E: ID_PART_TABLE_UUID=14a768bb-d94b-4be1-84a1-03d1299563ab
E: ID_PATH=pci-0000:00:14.1-ata-1
E: ID_PATH_TAG=pci-0000_00_14_1-ata-1
E: ID_REVISION=RVM01B6Q
E: ID_SERIAL=Samsung_SSD_860_PRO_256GB_S42VNF0M805065Y
E: ID_SERIAL_SHORT=S42VNF0M805065Y
E: ID_TYPE=disk
E: ID_WWN=0x5002538e99843e08
E: ID_WWN_WITH_EXTENSION=0x5002538e99843e08
E: MAJOR=8
E: MINOR=0
E: SUBSYSTEM=block
E: TAGS=:systemd:
E: USEC_INITIALIZED=4315137
```

- `dd` can be used to interact with block device files
- https://en.wikipedia.org/wiki/Dd_(Unix)

```
$ dd if=/dev/zero of=new_file bs=1024 count=1
1+0 records in
1+0 records out
1024 bytes (1.0 kB, 1.0 KiB) copied, 0.000426194 s, 2.4 MB/s
```
- `/dev/sd*`: disk drives; "sd" stands for <abbr title="Small Computer System Interface">SCSI</abbr> disk
- drives added and named in the order they are detected
- if you have `sda`, `sdb` and `sdc` and remove `sdb`, the old `sdc` becomes `sdb`
- `/dev/sr*`: read-only CD/DVD drives

### Terminals, Consoles

- not much info in HLW 
- `/dev/tty` - controlling terminal of current process
- `/dev/tty1` - the first virtual console
- `/dev/pts/0` - the first pseudo-terminal device ()
- `tty` - print the file name of the terminal connected to standard input
- when `ssh`ing, `tty` outputs `/dev/pts/0`
- when local, `tty` outputs `/dev/tty1`

#### [Unix terminals and shells - 1 of 5](https://www.youtube.com/watch?v=07Q9oqNLXB4)
- hardware (real) terminal device: keyboard + character-based display (normally, fixed grid)
- in UNIX, a process communicates w. a terminal using a file representing that terminal; a character device file
- terminal is dumb - just displays chars sent from the device file
- the terminal device file can have "echo" mode turned on - will just "echo" input chars back to the terminal
- later terminals added support for escape sequences, allowing func. like changing colour
- escape sequences: http://ascii-table.com/ansi-escape-sequences-vt-100.php
- when a process is started, it expects to inherit `stdin` (file descriptor 0) and `stdout` (file descriptor 1)
- when `fork`, the parent `stdin` and `stdout` are copied to the child (so, same)
- so UNIX programs generally don't look for a terminal themselves
- in UNIX, the graphical environment runs as a separate process (not part of the kernel)
- GUI programs send the content of their windows to the display server (`X`, `Wayland`) which is responsible for actually displaying them
- terminal emulator - sends drawing commands to the display server, and receives keyboard input (and perhaps mouse clicks) from it
- process talk to pseudo-terminal device files
- when a terminal emulator starts, it asks the OS to allocate a pseudo-terminal
- terminal emulator gets input from the display server, and writes it to the "master" pseudo-terminal character device file
- the OS (kernel) will automatically write the same input to the corresponding "slave" pseudo-terminal character device file
- the process has it's `stdin` and `stdout` connected to the "slave" ptdf
- virtual consoles - can switch between them with <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + `{` <kbd>F1<kbd>, ... <kbd>F8</kbd> `}`
- the display server normally runs as the 7th virtual console
- a virtual console acts like a terminal emulator, but is implemented in the kernel
- `/dev/pts/` - pseudo-terminal slaves
- `/dev/tty` - "controlling" terminal file (depends on what process opens it)
- `/dev/ttyX` - "virtual console" terminal files

#### Other Resources
- very good and very technical, plus historic bg: http://www.linusakesson.net/programming/tty
- end of [this document](https://mirrors.edge.kernel.org/pub/linux/docs/lanana/device-list/devices-2.6.txt) has some info 
- https://unix.stackexchange.com/questions/4126/what-is-the-exact-difference-between-a-terminal-a-shell-a-tty-and-a-con