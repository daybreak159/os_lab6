#include <defs.h>
#include <stdio.h>
#include <string.h>
#include <console.h>
#include <kdebug.h>
#include <picirq.h>
#include <trap.h>
#include <clock.h>
#include <intr.h>
#include <pmm.h>
#include <dtb.h>
#include <vmm.h>
#include <proc.h>
#include <kmonitor.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    cons_init(); // init the console

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);

    print_kerninfo();

    // grade_backtrace();

    dtb_init(); // init dtb

    pmm_init(); // init physical memory management

    pic_init(); // init interrupt controller
    idt_init(); // init interrupt descriptor table

    vmm_init(); // init virtual memory management
    /*
     * 调度器初始化（lab6）
     *
     * sched_init() 会把“调度器框架”与“具体调度算法”绑定起来：
     * - 选择一个 sched_class（例如 RR 或 Stride）
     * - 初始化全局运行队列 run_queue，并设置 max_time_slice
     *
     * 之后时钟中断会通过 proc_tick 驱动时间片消耗，need_resched 会触发 schedule() 做进程切换。
     */
    sched_init();
    proc_init(); // init process table

    clock_init();  // init clock interrupt
    intr_enable(); // enable irq interrupt

    cpu_idle(); // run idle process
}
