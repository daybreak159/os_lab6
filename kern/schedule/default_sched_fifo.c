#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>
/*
 * default_sched_fifo.c：FIFO/FCFS 调度（lab6 Challenge2）
 *
 * 语义（非抢占式 FIFO）：
 * - 就绪队列按“到达顺序”排队
 * - 选择队首进程运行
 * - 时钟 tick 不会强制触发重调度（proc_tick 不置 need_resched）
 * - 只有当进程主动让出/阻塞/退出时才发生调度
 *
 * 注意：
 * - 这是经典的 FCFS 思路，会出现“CPU-bound 进程长期占用导致其它进程饥饿”的现象，
 *   这正是 Challenge2 用于对比分析的重点之一。
 */

static void
FIFO_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->lab6_run_pool = NULL;
    rq->proc_num = 0;
}

static void
FIFO_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    assert(list_empty(&(proc->run_link)));
    list_add_before(&(rq->run_list), &(proc->run_link)); // 队尾入队
    proc->rq = rq;
    rq->proc_num++;
}

static void
FIFO_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(proc->rq == rq && rq->proc_num > 0);
    assert(!list_empty(&(proc->run_link)));
    list_del_init(&(proc->run_link));
    rq->proc_num--;
}

static struct proc_struct *
FIFO_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
        return le2proc(le, run_link);
    }
    return NULL;
}

static void
FIFO_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    // 非抢占 FIFO：tick 不触发调度
    (void)rq;
    (void)proc;
}

struct sched_class fifo_sched_class = {
    .name = "FIFO_scheduler",
    .init = FIFO_init,
    .enqueue = FIFO_enqueue,
    .dequeue = FIFO_dequeue,
    .pick_next = FIFO_pick_next,
    .proc_tick = FIFO_proc_tick,
};
