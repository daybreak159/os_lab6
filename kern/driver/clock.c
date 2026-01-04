#include <clock.h>
#include <defs.h>
#include <sbi.h>
#include <stdio.h>
#include <riscv.h>

volatile size_t ticks;

// 读取平台计时器（QEMU virt 上由 OpenSBI 提供），用于设置下一次时钟中断触发时间
static inline uint64_t get_cycles(void)
{
#if __riscv_xlen == 64
    uint64_t n;
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    return n;
#else
    uint32_t lo, hi, tmp;
    __asm__ __volatile__(
        "1:\n"
        "rdtimeh %0\n"
        "rdtime %1\n"
        "rdtimeh %2\n"
        "bne %0, %2, 1b"
        : "=&r"(hi), "=&r"(lo), "=&r"(tmp));
    return ((uint64_t)hi << 32) | lo;
#endif
}

static uint64_t timebase = 100000;

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    // 允许 S-mode 的 timer interrupt（STIP），后续在 trap 中处理并驱动调度器 tick
    set_csr(sie, MIP_STIP);

    clock_set_next_event();
    // initialize time counter 'ticks' to zero
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

/*
 * 触发“下一次”时钟中断：
 * - sbi_set_timer() 设置 timer compare 寄存器（抽象为 SBI 调用）
 * - trap 的 timer handler 中会递增 ticks、再次调用 clock_set_next_event()，形成周期性中断
 */
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
