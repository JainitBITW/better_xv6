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
* For this scheduler, I initialized 4 arrays(queues) numbered 0 to 3, with 0 having the highest priority.
* During the initialization of XV-6, I set all the queues to empty.
* After that, every time during fork and userinit, I insert the process into the **0th queue**. For convenience, I created functions to insert a process into the queue and to delete the ith process from the queue.
* Further, at the time of inserting into the 0th queue through fork, I check if the current process being executed(through `myproc()`) is in a lower priority queue(1-3), then i yield() and the currently running process gets preempted
* Now, at the start of the scheduler, I check for ageing in the queues.
    * **For ageing here, as well as for the wtime printed in MLFQ's procdump, I consider the queue wait time as the number of ticks for which the process in that queue was in the RUNNABLE state. This value is what is used for implementing ageing.**
    * The maximum age that is allowed is defined in the AGE_MAX parameter.
    * If the wait time of the process has gone beyond the AGE_MAX value, then it gets inserted into the higher priority queue(except if it is in 0th queue).
* After this, I find the first process in a non-empty highest prioirity queue, and if it is runnable, select it for running. Now, we set its state to running and give it CPU to run.
* In order to implement time slicing, I made modifications in `kernel/trap.c` and modified such that if the current queue run time exceeds the ticks limit, then the process gets yielded.
    * Also, in this case, I set a flag `q_leap` to 1.
* Now, after the process has finished running, I check for the `q_leap` flag, in which case I increase its queue number. Now, if the process is still runnable, then I insert it back into the queue according to its current queue_number.
* Further, for processes that themselves relinquish control(for I/O, etc.), they go into the sleep state, and they are not **pushed back into the queue**. However, when the I/O stops, they reach the `wakeup` function, where they are added back into the queue they were previously in before going to sleep.
* Further, after killing a process, I check if the process was in the RUNNABLE state, and if so, I remove it from the queue it was in.