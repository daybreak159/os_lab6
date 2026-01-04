#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>
#include <skew_heap.h>
/*
 * default_sched_hpf.c：HPF（Highest Priority First）调度（lab6 Challenge2）
 *
 * 语义（优先级优先 + 抢占式时间片）：
 * - 每个进程有一个优先级 lab6_priority（越大越优先）
 * - 就绪队列用优先队列维护，始终选择 priority 最大的进程
 * - 使用 time_slice 触发抢占：time_slice 耗尽则 need_resched=1
 *
 * 说明：
 * - 这是最基本的“静态优先级”策略，低优先级可能饥饿；
 * - Challenge2 的对比分析可以围绕“吞吐/响应/饥饿”展开。
 */

static int
proc_prio_comp_f(void *a, void *b) {
    struct proc_struct *p = le2proc(a, lab6_run_pool);
    struct proc_struct *q = le2proc(b, lab6_run_pool);
    if (p->lab6_priority > q->lab6_priority) {
        return -1; // p 更“优先”（在最小堆语义下，用 -1 表示更小/更靠前）
    }
    if (p->lab6_priority < q->lab6_priority) {
        return 1;
    }
    // 同优先级下用 pid 做稳定性 tie-break（越小越靠前）
    if (p->pid < q->pid) {
        return -1;
    }
    if (p->pid > q->pid) {
        return 1;
    }
    return 0;
}

static void
HPF_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->lab6_run_pool = NULL;
    rq->proc_num = 0;
}

static void
HPF_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_prio_comp_f);
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    rq->proc_num++;
}

static void
HPF_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(proc->rq == rq && rq->proc_num > 0);
    rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_prio_comp_f);
    rq->proc_num--;
}

static struct proc_struct *
HPF_pick_next(struct run_queue *rq) {
    if (rq->lab6_run_pool == NULL) {
        return NULL;
    }
    return le2proc(rq->lab6_run_pool, lab6_run_pool);
}

static void
HPF_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    // 抢占式：时间片耗尽触发重调度（与 RR 一致）
    (void)rq;
    if (proc->time_slice > 0) {
        proc->time_slice--;
    }
    if (proc->time_slice == 0) {
        proc->need_resched = 1;
    }
}

struct sched_class hpf_sched_class = {
    .name = "HPF_scheduler",
    .init = HPF_init,
    .enqueue = HPF_enqueue,
    .dequeue = HPF_dequeue,
    .pick_next = HPF_pick_next,
    .proc_tick = HPF_proc_tick,
};

