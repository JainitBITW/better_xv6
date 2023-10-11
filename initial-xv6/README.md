# Testing system calls

## Running Tests for getreadcount

Running tests for this syscall is easy. Just do the following from
inside the `initial-xv6` directory:

```sh
prompt> ./test-getreadcounts.sh
```

If you implemented things correctly, you should get some notification
that the tests passed. If not ...

The tests assume that xv6 source code is found in the `src/` subdirectory.
If it's not there, the script will complain.

The test script does a one-time clean build of your xv6 source code
using a newly generated makefile called `Makefile.test`. You can use
this when debugging (assuming you ever make mistakes, that is), e.g.:

```sh
prompt> cd src/
prompt> make -f Makefile.test qemu-nox
```

You can suppress the repeated building of xv6 in the tests with the
`-s` flag. This should make repeated testing faster:

```sh
prompt> ./test-getreadcounts.sh -s
```

---

## Running Tests for sigalarm and sigreturn

**After implementing both sigalarm and sigreturn**, do the following:
- Make the entry for `alarmtest` in `src/Makefile` inside `UPROGS`
- Run the command inside xv6:
    ```sh
    prompt> alarmtest
    ```

---

## Getting runtimes and waittimes for your schedulers
- Run the following command in xv6:
    ```sh
    prompt> schedulertest
    ```  
---

## Running tests for entire xv6 OS
- Run the following command in xv6:
    ```sh
    prompt> usertests
    ```

---


### Implementing Sigalarm and Sigreturn 



1. In `syscall.c`, we have declared the implementations of these system calls and added corresponding identifiers in `syscall.h` and `user.h`.

2. In `usys.pl`, we have specified these new system calls for user-space access.

3. We've updated the `proc` structure in the operating system with the following new fields:

   - `is_sigalarm`: A flag to mark whether an alarm is set.
   - `ticks`: Stores the number of ticks for the alarm.
   - `now_ticks`: Keeps track of the current tick count.
   - `handler`: Stores the address of the handler function.
   - `trapframe_copy`: A new `trapframe` structure to store register values when the handler function first expires.

4. We initialize and release these variables in `proc.c` during process creation and destruction.

5. In `trap.c`, we handle the case where an interrupt occurs, increment `now_ticks` if an alarm is active, and execute the handler function when the specified number of ticks has passed.

6. We've defined a function named `restore` in `sysproc.c` to restore specific `trapframe` values when returning from the handler function.

7. We've implemented the `sys_sigreturn` system call, which uses the `restore` function to return to the previous state, marking that the alarm is no longer active.

It's important to note that some variables and stack elements cannot be directly restored to the `trapframe`, as certain kernel stack and other elements are shared and used for various purposes.

### MLFQ Implementation 


Implement a simplified preemptive MLFQ scheduler that allows processes to move between different priority queues based on their behavior and CPU bursts.

*   If a process uses too much CPU time, it is pushed to a lower priority queue, leaving I/O bound and interactive processes in the higher priority queues.
*   To prevent starvation, implement aging.

**Details:**

1.  Create four priority queues, giving the highest priority to queue number 0 and lowest priority to queue number 3
2.  The time-slice are as follows:
    
    1.  For priority 0: 1 timer tick
    2.  For priority 1: 3 timer ticks
    3.  For priority 2: 9 timer ticks
    4.  For priority 3: 15 timer ticks
    
    **NOTE:** Here tick refers to the clock interrupt timer. (see kernel/trap.c)


### How ? 
I made 4 queues containing each containing the addresses to processes. 
