#ifndef __KERN_SCHEDULE_SCHED_RR_H__
#define __KERN_SCHEDULE_SCHED_RR_H__

#include <sched.h>

/*
 * 具体调度算法对外导出的 sched_class：
 * - default_sched_class：Round-Robin（lab6 基本练习）
 * - stride_sched_class：Stride Scheduling（lab6 Challenge1）
 * - fifo_sched_class：FIFO/FCFS（lab6 Challenge2，非抢占）
 * - sjf_sched_class：SJF（lab6 Challenge2，可配置为抢占/非抢占）
 * - hpf_sched_class：HPF（lab6 Challenge2，优先级优先）
 *
 * 调度框架层（kern/schedule/sched.c）只持有一个 sched_class 指针，
 * 在 sched_init() 中选择绑定哪一种算法即可完成“切换调度策略”。
 */
extern struct sched_class default_sched_class;
extern struct sched_class stride_sched_class;
extern struct sched_class fifo_sched_class;
extern struct sched_class sjf_sched_class;
extern struct sched_class hpf_sched_class;

#endif /* !__KERN_SCHEDULE_SCHED_RR_H__ */
