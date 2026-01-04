#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>
#include <skew_heap.h>
/*
 * default_sched_sjf.c：SJF（Shortest Job First）调度（lab6 Challenge2）
 *
 * 语义（简化版 SJF：按“作业长度估计值”选最小者）：
 * - 这里复用 proc_struct::lab6_priority 作为“作业长度估计”（越小越短）
 * - 每次调度选择该估计值最小的进程运行
 *
 * 实现选择：
 * - 就绪队列使用斜堆（优先队列）避免线性扫描（pick_next O(1)，插入/删除均摊 O(log n)）
 * - proc_tick 采用 RR 式时间片触发调度（保证系统能周期性重新选择最短作业；也便于对比）
 *
 * 讨论点（Challenge2 分析可用）：
 * - SJF 可以显著降低平均等待时间，但可能导致长作业饥饿；
 * - 若要更贴近理论的 SRTF（Shortest Remaining Time First），可以把“估计值”改为“剩余估计”，在 tick 中递减。
 */

static int
proc_sjf_comp_f(void *a, void *b) {
    struct proc_struct *p = le2proc(a, lab6_run_pool);
    struct proc_struct *q = le2proc(b, lab6_run_pool);
    if (p->lab6_priority < q->lab6_priority) {
        return -1;
    }
    if (p->lab6_priority > q->lab6_priority) {
        return 1;
    }
    // 相同估计值下用 pid 稳定排序
    if (p->pid < q->pid) {
        return -1;
    }
    if (p->pid > q->pid) {
        return 1;
    }
    return 0;
}

static void
SJF_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->lab6_run_pool = NULL;
    rq->proc_num = 0;
}

static void
SJF_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_sjf_comp_f);
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    rq->proc_num++;
}

static void
SJF_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(proc->rq == rq && rq->proc_num > 0);
    rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_sjf_comp_f);
    rq->proc_num--;
}

static struct proc_struct *
SJF_pick_next(struct run_queue *rq) {
    if (rq->lab6_run_pool == NULL) {
        return NULL;
    }
    return le2proc(rq->lab6_run_pool, lab6_run_pool);
}

static void
SJF_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    // 与 RR 一致：时间片耗尽触发重调度，便于周期性重新选择“最短作业”
    (void)rq;
    if (proc->time_slice > 0) {
        proc->time_slice--;
    }
    if (proc->time_slice == 0) {
        proc->need_resched = 1;
    }
}

struct sched_class sjf_sched_class = {
    .name = "SJF_scheduler",
    .init = SJF_init,
    .enqueue = SJF_enqueue,
    .dequeue = SJF_dequeue,
    .pick_next = SJF_pick_next,
    .proc_tick = SJF_proc_tick,
};

