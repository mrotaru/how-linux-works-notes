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
- `udevadm` can be used to obtain more information about a device:

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
- the path at `DEVPATH` is a folder meant to be read primarily by tools but can reveal some useful information about the device:
- `P:` - device `sysfs` path
- `N:` - device node
- `S:` - a symlink created by `udevd`
- `E:` - additional information extracted in `udevd` rules

```
$ ls /sys/devices/pci0000:00/0000:00:14.1/ata1/host0/target0:0:1/0:0:1:0/block/sda
alignment_offset  capability  device             events        events_poll_msecs  hidden   inflight   power  range      ro    sda2  slaves  subsystem  uevent
bdi               dev         discard_alignment  events_async  ext_range          holders  integrity  queue  removable  sda1  size  stat    trace
  ```

#### `dd`
- http://man7.org/linux/man-pages/man1/dd.1.html
- powerful tool; use with care
```
$ dd if=/dev/zero of=new_file bs=1024 count=1
1+0 records in
1+0 records out
1024 bytes (1.0 kB, 1.0 KiB) copied, 0.00057832 s, 1.8 MB/s
```
##### arguments
- `bs` → block size (if different for i/o, use `ibs` and `obs`)
- `count` → how many blocks to copy

#### Disks
- "sd" originates from **S**CSI **d**isk; "sda" → SCSI disk "a"
- SCSI - Small Computer System Interface - a set of standards
- `/dev/sd*`: disk drives
- use `lsscsi` to list SCSI devices
```
$ sudo lsscsi
[0:0:1:0]    disk    ATA      Samsung SSD 860  1B6Q  /dev/sda
[6:0:0:0]    disk    Lexar    USB Flash Drive  1100  /dev/sdb
[7:0:0:0]    disk    Lexar    USB Flash Drive  1100  /dev/sdc
```
- first column - `[H:C:T:L]` format; [source](http://www.fibrevillage.com/storage/51-linux-lsscsi-list-scsi-devices-or-hosts-and-their-attributes)
```
H == hostadapter id (first one being 0)
C == SCSI channel on hostadapter (first one being 0)
T == ID
L == LUN (first one being 0)
```
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
- virtual consoles - can switch between them with <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + `{` <kbd>F1</kbd>, ... <kbd>F8</kbd> `}`
- the display server normally runs as the 7th virtual console
- a virtual console acts like a terminal emulator, but is implemented in the kernel
- `/dev/pts/` - pseudo-terminal slaves
- `/dev/tty` - "controlling" terminal file (depends on what process opens it)
- `/dev/ttyX` - "virtual console" terminal files

#### [Unix terminals and shells - 2 of 5](https://www.youtube.com/watch?v=hgFBRZmwpSM)
- terminal is dumb - just displays characters, and sends keyboard input
- shell - reads from a terminal, and interprets the input as commands
- shells have a configurable prompt, where the user enters commands
- when the shell is expecting the user to type a command, it puts the terminal into echoing mode
- the shell interprets <kbd>Enter</kbd> as the end of a command, which it interprets and executes
- process command - `program-name arguments`
- where does the shell look for `program-name` ?
    - `foo` - dirs in the current process' `$PATH` env var
    - `/bin/foo` - root dir
    - `bin/foo` - in `$PWD` (current directory)
    - `./foo` - `foo` in `$PWD`
- to invoke a program:
    - shell `fork`s itself
    - parent invokes [`WAIT`](http://man7.org/linux/man-pages/man2/waitpid.2.html) syscall to wait for child process to complete
    - child process calls `exec` to run the command (it is just a continuation of the shell process until then), passing in the program arguments
        - `exec` copies the args somewhere in the heap of the process `NULL`-terminated, and puts the address in the first stack frame
        - http://man7.org/linux/man-pages/man3/exec.3.html
- in `bash`, some characters have special meaning
- ``# ' " \ $ ` * ~ ? < > ( ) ! | & ; space newline``
- `\` - quote the following char _or_ start an escape sequence
- `''` - quote _every_ enclosed metacharacter
- `""` - quote enclosed metacharacters, except ``$ ` \ * @``
- `ls -la\ bin` - invoke `ls` with a single argument, `-la bin`
- a backslash before a newline allows splitting a command on multiple lines

#### File Descriptors

> In the traditional implementation of Unix, file descriptors index into a per-process file descriptor table maintained by the kernel, that in turn indexes into a system-wide table of files opened by all processes, called the file table. This table records the mode with which the file (or other resource) has been opened: for reading, writing, appending, and possibly other modes. It also indexes into a third table called the inode table that describes the actual underlying files.[3] To perform input or output, the process passes the file descriptor to the kernel through a system call, and the kernel will access the file on behalf of the process. The process does not have direct access to the file or inode tables. 
>
> On Linux, the set of file descriptors open in a process can be accessed under the path /proc/PID/fd/, where PID is the process identifier.
>
> In Unix-like systems, file descriptors can refer to any Unix file type named in a file system. As well as regular files, this includes directories, block and character devices (also called "special files"), Unix domain sockets, and named pipes. File descriptors can also refer to other objects that do not normally exist in the file system, such as anonymous pipes and network sockets. 
>
> (https://en.wikipedia.org/wiki/File_descriptor#Overview)

- common file descriptors:
  - `0` → `stdin`
  - `1` → `stdout`
  - `2` → `stderr`

#### [Unix terminals and shells - 3 of 5](https://www.youtube.com/watch?v=GA2mIUQq48s)
##### Redirection
- redirection - when a process gets something other than the parents terminal for `stdin`/`stdout`
- a shell starts by having its `stdin`/`stdout` connected to a terminal
- because child processes inherit `stdin`/`stdout`, by default it uses the same terminal for IO
- redirects are transparent to the invoked commands; they are set up by the shell before the commands are even invoked
- when opening a file in linux, it's file descriptor will be the lowest available number; so if we close fd 0, the next opened file will have fd = 0 (for the respective process)
- `<` _file_ → close fd 0 and open _file_ for reading (which will become the new fd 0)
- `>` _file_ → close fd 1 and open _file_ for writing (which will become the new fd 1)
- technically, redirects can be specified even before the actual command (`> files.txt ls` ⇔ `ls > files.txt`)
- `foo --arg1 --arg2 < input.txt > /dev/null`
    - shell forks itself (clones itself into a newly created child process)
    - parent process starts waiting for child process to complete
    - child closes `stdin`, opens `input.txt` for reading
    - child closes `stdout`, opens `/dev/null` for writing
    - child `exec`s the command (`foo`), passing the args
    - the `foo` command is none the wiser about the redirects

##### Pipelines
- the pipe operator can be used to connect one command's `stdout` to another's `stdin`
- `ls | grep foo`
    - the parent process (the shell) will create a pipe (https://linux.die.net/man/2/pipe)
    - then it will iterate over the commands (`ls` and `grep`) and create a subshell (`fork`) each of them, interposing the pipe between them
    - for the first child process (for `ls`), the value of fd 1 (`stdout`) will be the ID of the anonymous pipe - which will result in any output produced by the process being redirected to the pipe
    - the child process will then `exec` the `ls` command
    - for the second child process, fd 0 (`stdin`) will be set to the pipe
    - the parent will wait for both to complete
- piped commands are ran **in parallel** - the parent process will `fork` each of them
- more on pipe parallelism: https://stackoverflow.com/a/51452413/447661

##### Commands
- a command can be a process command or a built-in command; `bash` has 70+ built-ins
- shell makes built-ins behave the same as external cmds with regards to redirection and piping
- the `help` built-in gives more details about built-ins (`help if` - more on `if`)
- `cd` - built-in - a process' CWD cannot be changed externally, so must be a built-in
- pipeline: a single command, or multiple commands connected with `|`
- command list: one or more pipelines, separated and terminated by `;`, `&` or `newline`
- pipelined commands are executed in parallel (`foo | bar | fizz | baz`)
- `pipelineA && pipelineB`
- `pipelineA || pipelineB`

##### Variables
- shell variables are different from _environment_ variables
- the same syntax is used to expand both kinds of vars: `$foo`
- `foo=42` - sets the value of the `foo` shell variable to the string "42"
- `echo ${foo}d` - expands the `foo` variable
- single quotes remove special meaning from most chars, therefore preventing expansion
- shell variables are not automatically passed to sub-shells (child processes)
- use `export` to "tag" a shell variable as an _environment_ variable (which _will_ be inherited by child processes - like any other environment variable)

##### Conditionals
- conditionals (`if`, `while`) take a list of commands; the exit status of the last one is used to determine the outcome of the conditional (`0` → `true`, anything else → `false`)
- the [`exit()`](http://man7.org/linux/man-pages/man3/exit.3.html) syscall is used to set the exit status, passed on to any waiting process

#### [Unix terminals and shells - 4 of 5](https://www.youtube.com/watch?v=M82FUtqXdE8)
```bash
function foo { ls -la; cd /; }
# same as:
function foo {
    ls -la
    cd /
}
# to invoke a function, no parens required:
foo 42 # invoke the foo function with one argument, "42"
```
- one could have a function with the same name as a built-in or a process command
- "shadowing" order:
  1. function call
  2. built-in command
  3. process command
- functions and variables live in separate namespaces - can have fn and var with same name
- function arguments available inside the fn body as `$1`, `$2`, etc
- `$?` - the exist code of the previously executed command
- the return value of a function is the exit code of the last command (built-in, or process)
- can override exit code with `return` (must be a number)
- brace expansion: `pre-{foo,bar}-post` expands into "pre-foo-post" and "pre-bar-post"
- note: `pre-${foo,bar}-post` is a _variable_ expansion - only the first one will be expanded though
- `~` - tilde expansion
```bash
# command substitution
$(echo foo-$(echo bar)) # will be substituted with the result of running the command (the string "foo-bar")
`echo foo-`echo bar`` # can't nest (substitution will end at second backtick, and start again)
```
- arithmetic substitution: `$((42 + 100))`, `$(((1 + 2) * 3))`
    - automatically does variable substitution: `$((foo + 100))`
- `*`, `?` - filename expansion - all matching files/folders included in expansion
- order of expansions:
  1. brace expansion (`foo{fizz,buzz}bar)`) 
  2. tilde expansion
  3. variable, arithmetic expansion, command substitution (same priority, outermost performed last)
  4. filename expansion
- there is more nuance to expansions and substitutions (https://linux.die.net/man/1/bash, "Expansion")

#### [Unix terminals and shells - 5 of 5](https://www.youtube.com/watch?v=N8kT2XRNEAg)
- program commands can be executed in subshells - the parent creates another process (the subshell process), which will then fork and exec the command
- program commands will always run in a separate process, but built-ins (like `cd`) normally run in the same process
- parens can be used to start a sub-shell: `(cd /; ls -la;)` (`cd` will not affect the parent process)
- curly braces execute a command in the _current_ shell: `{ cd /; ls -la; }`
- the `{` is actually a built-in command, and what follows are arguments given to it - so space is necessary
- useful bc. redirection would be applied to all enclosed commands
- not related to function blocks `{}`
- exist status will be the exit status of the last executed command
- with `&`, a pipeline can be run "in background":
    1. shell doesn't wait for it to complete
    2. pipeline is started in a subshell
    3. pipeline can't read from terminal
    4. pipeline could, potentially, be allowed to _write_ to the terminal
- with `&`, even a curly braced pipeline can be set to run in the background `{ cd /; ls -la; } &`
- kernel keeps tack of each process' job and session
- terminal emulators start with one session, containing one job, consisting of the shell process
- processes started by the shell run as part of the same job; but sub-shells run as new, separate jobs
- each session has an "controlling terminal" associated with it
- only one job in a session is running in the foreground
- fg processes can read/write to terminal, bg proc. get the `SIGTTIN` when they attempt to read the terminal
- <kbd>Ctrl</kbd> + <kbd>Z</kbd>:
  1. send `SIGTSTP` to processes of the current fg job (terminal stop)
  2. send `SIGCONT` to processes of bg job and moves it to fg
  - normally used to suspend (:?) a long-running process and send it to bg, to get back the job with the shell in it
- `jobs` - list jobs
- `bg JOB_NUMBER` - resumes suspended bg job (sends `SIGCONT` to it's procs) so it resumes running in bg
- `fg JOB_NUMBER` - moves job from bg to fg, and send `SIGCONT` to them
- `source file` - read and execute commands in the current shell; same as actually typing them
- `/bin/bash file` - read and execute commands _in a subshell_
- `#!/bin/bash` - the "#!" is a "shebang" - allows invoking of text files as if they were binary executable

#### More Terminal Resources
- very good and very technical, plus historic bg: http://www.linusakesson.net/programming/tty
- https://unix.stackexchange.com/questions/4126/what-is-the-exact-difference-between-a-terminal-a-shell-a-tty-and-a-con
- end of [this document](https://mirrors.edge.kernel.org/pub/linux/docs/lanana/device-list/devices-2.6.txt) has some info 

#### Serial Ports
- used as special terminal devices; ex: RS-232 (https://en.wikipedia.org/wiki/RS-232)
- in `/dev/ttyS*`, but not really usable from the CLI because serial communication requires low-level operations
- https://en.wikipedia.org/wiki/Serial_communication
- `/dev/ttyS0` would be `COM1` on Windows, `/dev/ttyS1` → `COM2`, etc

#### Parallel Ports
- largely superseded by USB
- unidirectional: `/dev/lp0` and `/dev/lp1` - `LPT1` and `LPT2` on Windows
- can send files directly to a parallel port (w. `cat`)
- bidirectional: `/dev/parport0` and `/dev/parport1`

### udev
- during boot, kernel creates device files and notifies `udevd`
- when notified, `udevd` does device initialization, process notification, and mk symlinks in `/dev`
- devtmpfs
    - https://unix.stackexchange.com/a/77936/39603
    - https://lwn.net/Articles/331818/
- kernel uses an internal network link to send `udevd` notifications about devices
- `udevd` parses kernel notification, and sets attributes based on it
- based on the extracted attributes, `udevd` loads rules in `/lib/udev/rules.d` or `/etc/udev/rules.d`
- a rule has two parts: the "match" part (based on attrs) and the "action" part
- more on `udev` rules: https://linuxconfig.org/tutorial-on-how-to-write-basic-udev-rules-in-linux
- https://linux.die.net/man/8/udev
- this process dictates the layout in `/dev/disk/by-id` & co
- `udevadm` - tool for interacting with `udevd` - reload rules, trigger events, monitor uevents
- `udevadm info --querly=all --name=/dev/sda` - see above
- to monitor for devices being added/removed: `udevadm monitor`

## 4. Disks and Filesystems

### Partitions

- disks are sub-divided into partitions
- `parted` - CLI; MBR + GPT
- `gparted` - GUI; MBR + GPT
- `fdisk` - CLI; MBR
- `gdisk` - CLI; GPT

```
$ sudo parted -l
Model: ATA Samsung SSD 860 (scsi)
Disk /dev/sda: 256GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name  Flags
 1      1049kB  2097kB  1049kB                     bios_grub
 2      2097kB  256GB   256GB   ext4
```
- `parted` calls MBR partition tables "msdos"
- under MBR, individual paritions cannot be given names
- under MBR, number of primary partitions is limited to 4
    - one of them can be made "extended", which means it can be further sub-divided into "logical" partitions
- `dmesg` when attaching a disk:
```
[  480.054612] ata3: exception Emask 0x10 SAct 0x0 SErr 0x40d0000 action 0xe frozen
[  480.054762] ata3: irq_stat 0x00400040, connection status changed
[  480.054874] ata3: SError: { PHYRdyChg CommWake 10B8B DevExch }
[  480.054989] ata3: hard resetting link
[  485.846088] ata3: SATA link up 3.0 Gbps (SStatus 123 SControl 300)
[  485.857399] ata3.00: failed to enable AA (error_mask=0x1)
[  485.857519] ata3.00: ATA-8: VB0250EAVER, HPG9, max UDMA/100
[  485.857524] ata3.00: 488397168 sectors, multi 0: LBA48 NCQ (depth 31/32)
[  485.858592] ata3.00: failed to enable AA (error_mask=0x1)
[  485.858719] ata3.00: configured for UDMA/100
[  485.858751] ata3: EH complete
[  485.859053] scsi 2:0:0:0: Direct-Access     ATA      VB0250EAVER      HPG9 PQ: 0 ANSI: 5
[  485.859546] sd 2:0:0:0: [sdb] 488397168 512-byte logical blocks: (250 GB/233 GiB)
[  485.859575] sd 2:0:0:0: [sdb] Write Protect is off
[  485.859580] sd 2:0:0:0: [sdb] Mode Sense: 00 3a 00 00
[  485.859628] sd 2:0:0:0: [sdb] Write cache: disabled, read cache: enabled, doesn't support DPO or FUA
[  485.860429] sd 2:0:0:0: Attached scsi generic sg1 type 0
[  485.881724]  sdb: sdb1
[  485.882993] sd 2:0:0:0: [sdb] Attached SCSI disk
```
- `fdisk` applies changes upon exiting; `parted` applies them _immediatelly_
- the _cylinder-head-sector_ scheme - numbers reported even by modern hardware, but do not reflect the physical reality
- modern hardware uses the <abbr title="Logical Block Addressing">LBA</abbr> scheme - allows addressing locations on disk by block number
- on SSDs, data is normally read in chunks of 4096 bytes (4kB) - so when data not aligned, can need 2 reads even for small files
- for optimal performance, partition start should be a multiple of 4096
```
$ cat /sys/block/sde/sde2/start
4096
```

### File Systems
- initially were implemented in kernel; [Plan 9](https://en.wikipedia.org/wiki/Plan_9_from_Bell_Labs) pioneered user-space fs
    - now generally implemented via FUSE (File System in User Space)
- futher abstratction is provided by Virtual File System (VFS)
- `mkfs` can be used to create filesystems once partitions are in place: `mkfs -t ext4 /dev/sdf2`
- `mkfs` is actually a wrapper for various fs-specific utilities (`ls -l /sbin/mkfs.*`)
- to be usable, a filesystems needs to be mounted
- the `mount` command, without arguments, shows currently mounted filesystems
- output format: `<device> on <mount_point> type <fs_type> (<mount_options>)`
```
mrotaru@micro-server:~$ mount
sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime)
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
udev on /dev type devtmpfs (rw,nosuid,relatime,size=988860k,nr_inodes=247215,mode=755)
devpts on /dev/pts type devpts (rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=000)
tmpfs on /run type tmpfs (rw,nosuid,noexec,relatime,size=204060k,mode=755)
/dev/sde2 on / type ext4 (rw,relatime,data=ordered)
securityfs on /sys/kernel/security type securityfs (rw,nosuid,nodev,noexec,relatime)
tmpfs on /dev/shm type tmpfs (rw,nosuid,nodev)
tmpfs on /run/lock type tmpfs (rw,nosuid,nodev,noexec,relatime,size=5120k)
tmpfs on /sys/fs/cgroup type tmpfs (ro,nosuid,nodev,noexec,mode=755)
cgroup on /sys/fs/cgroup/unified type cgroup2 (rw,nosuid,nodev,noexec,relatime)
cgroup on /sys/fs/cgroup/systemd type cgroup (rw,nosuid,nodev,noexec,relatime,xattr,name=systemd)
pstore on /sys/fs/pstore type pstore (rw,nosuid,nodev,noexec,relatime)
cgroup on /sys/fs/cgroup/freezer type cgroup (rw,nosuid,nodev,noexec,relatime,freezer)
cgroup on /sys/fs/cgroup/blkio type cgroup (rw,nosuid,nodev,noexec,relatime,blkio)
(... more cgroup stuff)
systemd-1 on /proc/sys/fs/binfmt_misc type autofs (rw,relatime,fd=26,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=14545)
mqueue on /dev/mqueue type mqueue (rw,relatime)
hugetlbfs on /dev/hugepages type hugetlbfs (rw,relatime,pagesize=2M)
debugfs on /sys/kernel/debug type debugfs (rw,relatime)
fusectl on /sys/fs/fuse/connections type fusectl (rw,relatime)
configfs on /sys/kernel/config type configfs (rw,relatime)
/var/lib/snapd/snaps/core_8935.snap on /snap/core/8935 type squashfs (ro,nodev,relatime,x-gdu.hide)
/var/lib/snapd/snaps/core_8689.snap on /snap/core/8689 type squashfs (ro,nodev,relatime,x-gdu.hide)
/var/lib/snapd/snaps/core18_1705.snap on /snap/core18/1705 type squashfs (ro,nodev,relatime,x-gdu.hide)
tank on /tank type zfs (rw,xattr,noacl)
lxcfs on /var/lib/lxcfs type fuse.lxcfs (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other)
/var/lib/snapd/snaps/httpee_211.snap on /snap/httpee/211 type squashfs (ro,nodev,relatime,x-gdu.hide)
tmpfs on /run/user/1000 type tmpfs (rw,nosuid,nodev,relatime,size=204056k,mode=700,uid=1000,gid=1000)
tmpfs on /run/snapd/ns type tmpfs (rw,nosuid,noexec,relatime,size=204060k,mode=755)
nsfs on /run/snapd/ns/httpee.mnt type nsfs (rw)
/var/lib/snapd/snaps/httpee_218.snap on /snap/httpee/218 type squashfs (ro,nodev,relatime,x-gdu.hide)
```
- `mount` has many params; some general, others fs-specific
    - `-r` - read-only; implicit when mounting with CDs and such
    - `-n`- don't update runtime mount db, `/etc/mtab`
    - `-t` - fs type
    - `-o ro, conv=auto` - two long options, `ro` (≡`-r`) and `conv=auto` (auto-convert line endings for text files)
    - other long options: `exec`, `noexec`, `suid`, `nosuid`, `rw`, `conv=binary|text|auto`
- `unmount <mountpoint>` can be used to unmount
- device names (like `sda`, etc) are not deterministic; `blkid` provides consistent IDs:
```
$ blkid
/dev/sda1: UUID="6be792bb-3fac-4e2f-a42d-f8ccc78327f4" TYPE="ext4" PARTUUID="000c8617-01"
/dev/sdb1: LABEL="tank" UUID="11931612062141205475" UUID_SUB="4158743156209613126" TYPE="zfs_member" PARTLABEL="zfs-9a184d671ac054dd" PARTUUID="d0891a37-9115-f14a-959a-b81ad8d15f16"
/dev/sdd1: LABEL="tank" UUID="11931612062141205475" UUID_SUB="4984306899594034767" TYPE="zfs_member" PARTLABEL="zfs-4c3e4016932caa0b" PARTUUID="49587987-f528-d149-a579-6b2cbfedbb20"
/dev/sde2: UUID="b04a3bf0-4981-4bdf-9812-60d9b8a43701" TYPE="ext4" PARTUUID="2c8a8d74-5cff-4b32-a5ba-bc6f33fc2511"
/dev/sdc1: LABEL="tank" UUID="11931612062141205475" UUID_SUB="17071196160985234051" TYPE="zfs_member" PARTLABEL="zfs-5f24ed180d77ad47" PARTUUID="60fd1972-9bbd-4148-b126-39c717dd04f4"
```
- these UUIDs are generated upon fs creation
- UUIDs for the `ext` family of fs can be changed with `tune2fs`
- to mount using UUID: `mount UUID=6be792bb-3fac-4e2f-a42d-f8ccc78327f4 /home/foo`
- the `/etc/fstab` file is used to mount fs at startup:
```
$ cat /etc/fstab
UUID=b04a3bf0-4981-4bdf-9812-60d9b8a43701 / ext4 defaults 0 0
/swap.img       none    swap    sw      0       0
```
- format: `<device/uuid> <mount_point> <fs_type> <options> <backup_for_dump> <fs_integrity_test_order>`
- entries can have `noauto` so they're not automtically mounted, but can be either explicitly or with `mount -a`
- as alternatives to the `/etc/fstab` file, the `/etc/fstab.d` folder or `systemd` can be used
- `df` can be ued to see capacity; `-h` option can be used for human-readable sizes:
```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            966M     0  966M   0% /dev
tmpfs           200M  1.2M  199M   1% /run
/dev/sde2       234G   53G  169G  24% /
tmpfs           997M     0  997M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           997M     0  997M   0% /sys/fs/cgroup
/dev/loop0       94M   94M     0 100% /snap/core/8935
/dev/loop2       55M   55M     0 100% /snap/core18/1705
tank             15T  128K   15T   1% /tank
/dev/loop4       17M   17M     0 100% /snap/httpee/211
tmpfs           200M     0  200M   0% /run/user/1000
/dev/loop5       17M   17M     0 100% /snap/httpee/218
/dev/loop3       94M   94M     0 100% /snap/core/9066
```
- to see how much space current folder is occupying, use `du -hs`
- `fsck` can be used to verify file systems - but not currently mounted ones
- normally fs integrity is checked at boot time, and journaling makes it a rare occasion to have to use it manually
- care must be exercised and any manually fixable problems should be addresssed before running `fsck`
- files with only an `inode` (no name) are placed in `lost+found` with a number as the name
- `/proc` → info abt processes
- `/sys` → device and system info
- `/run` → can use memory and swap as storage; `tmpfs` (https://en.wikipedia.org/wiki/Tmpfs)
- virtual memory, aka swap space - augument _real_ memory (RAM); use `free` for swap overview
- `mkswap` and `swapon` can be used to register and use a partition or a file as swap space
- I/O is expensive, the OS should not be using the swap space too frequently
- a fs has two major components: the actual storage blocks, and a database with meta-information
- an _inode_ can describe a file - type, permissions, blocks where it is stored
- an _inode_ can also describe a folder, in which case it contains a list of file names and corresponding links to inodes
- directory inodes also contain entries for `.` and `..`
- `ls -i` and `stat` can be used to see inode info
```
$ ls -li
total 24
5243304 drwxrwxr-x 2 mrotaru mrotaru 4096 Apr 22 19:50 code
5111828 -rw-rw-r-- 1 mrotaru mrotaru 1024 Mar 18 10:17 new_file
5243302 drwxr-xr-x 3 mrotaru mrotaru 4096 Apr 18 15:54 snap
5111821 drwxrwxr-x 2 mrotaru mrotaru 4096 Feb 26 20:28 test
5111819 -rw-rw---- 1 mrotaru mrotaru    0 Feb 26 20:02 test.txt
```
- a hard link is just a manually created entry in a dir inode to an existing file inode
- `rm` is unlinkig - if a file has hard links pointing to it, each hard link is counted and the file is actually removed only when count is 0
- for directories, each child dirs `..` counts towards the inode count of the parent
- root inode's link count has one extra link, from the superblock
- https://unix.stackexchange.com/questions/4402/what-is-a-superblock-inode-dentry-and-a-file
- VFS ensures syscalls always return inode numbers and link counts, but their meaning depends on underlying fs