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

## The Kernel
- determines which **processes** are allowed to use the CPU
- keeps track of **memory** - who can access what, what is free, what is shared, etc
- interface betw **hardware** and processes 
- provides **system calls** - used by processes to communicate with the kernel

### Process Management
- context switching - when kernel stops currently running process and replaces it with another one
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