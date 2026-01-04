#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>
#include <stdio.h>

#define USE_SKEW_HEAP 1

/*
 * default_sched_stride.c：Stride Scheduling（lab6 Challenge1，调度算法可切换）
 *
 * 目标：让“被调度次数/CPU 份额”与进程 priority 成正比。
 *
 * 做法：
 * - 每个进程维护 stride（也叫 pass）：数值越小越优先运行
 * - 每次选中一个进程运行后，更新：
 *     stride += BIG_STRIDE / priority
 *   priority 越大，步进越小，stride 增长越慢，因此更容易保持“最小”，从而获得更多 CPU 时间。
 *
 * 数据结构：
 * - 用 skew heap（斜堆）作为优先队列，实现快速取出 stride 最小的进程。
 * - compare 函数 proc_stride_comp_f 采用“差值的有符号比较”以缓解无符号溢出问题。
 */

/* You should define the BigStride constant here*/
/* 你需要在这里定义 BIG_STRIDE（大步长常量） */
/* LAB6 CHALLENGE 1: 2310675 */
// lab6:2310675 选择一个足够大的常数以降低溢出影响（与 RV32/无符号比较配合）
#define BIG_STRIDE (1 << 30) /* you should give a value, and is ??? */

/* The compare function for two skew_heap_node_t's and the
 * corresponding procs*/
/* 用于比较两个斜堆节点（对应两个进程）的 stride 大小的比较函数 */
static int
proc_stride_comp_f(void *a, void *b)
{
     struct proc_struct *p = le2proc(a, lab6_run_pool);
     struct proc_struct *q = le2proc(b, lab6_run_pool);
     // 通过“差值转 int32_t”的方式比较无符号 stride，降低溢出时直接比较带来的错误风险
     int32_t c = p->lab6_stride - q->lab6_stride;
     if (c > 0)
          return 1;
     else if (c == 0)
          return 0;
     else
          return -1;
}

/*
 * stride_init initializes the run-queue rq with correct assignment for
 * member variables, including:
 * stride_init 会初始化运行队列 rq 的关键成员，包括：
 *
 *   - run_list: should be a empty list after initialization.
 *   - run_list：初始化后应为空链表（仅有表头结点）。
 *   - lab6_run_pool: NULL
 *   - lab6_run_pool：优先队列（斜堆）堆顶指针，初始化为 NULL 表示队列为空。
 *   - proc_num: 0
 *   - proc_num：运行队列中的进程数量清零。
 *   - max_time_slice: no need here, the variable would be assigned by the caller.
 *   - max_time_slice：这里无需设置，由调用者（sched_init）赋值。
 *
 * hint: see libs/list.h for routines of the list structures.
 * 提示：链表相关操作可参考 libs/list.h。
 */
static void
stride_init(struct run_queue *rq)
{
     /* LAB6 CHALLENGE 1: 2310675
      * (1) init the ready process list: rq->run_list
      * (2) init the run pool: rq->lab6_run_pool
      * (3) set number of process: rq->proc_num to 0
      */
     // lab6:2310675 使用链表初始化（即便选择 skew_heap 也保持 run_list 可用）
     list_init(&(rq->run_list));
     rq->lab6_run_pool = NULL;
     rq->proc_num = 0;
}

/*
 * stride_enqueue inserts the process ``proc'' into the run-queue
 * ``rq''. The procedure should verify/initialize the relevant members
 * of ``proc'', and then put the ``lab6_run_pool'' node into the
 * queue(since we use priority queue here). The procedure should also
 * update the meta date in ``rq'' structure.
 * stride_enqueue 把进程 proc 插入到运行队列 rq：
 * - 初始化/校正 proc 的相关字段（如 time_slice）
 * - 将 proc 对应的斜堆节点 proc->lab6_run_pool 插入到 rq->lab6_run_pool（优先队列）中
 * - 更新 rq->proc_num 等统计信息
 *
 * proc->time_slice denotes the time slices allocation for the
 * process, which should set to rq->max_time_slice.
 * proc->time_slice 表示该进程本轮可使用的剩余时间片；入队时通常应设置为 rq->max_time_slice。
 *
 * hint: see libs/skew_heap.h for routines of the priority
 * queue structures.
 * 提示：优先队列（斜堆）接口见 libs/skew_heap.h。
 */
static void
stride_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: 2310675
      * (1) insert the proc into rq correctly
      * NOTICE: you can use skew_heap or list. Important functions
      *         skew_heap_insert: insert a entry into skew_heap
      *         list_add_before: insert  a entry into the last of list
      * (2) recalculate proc->time_slice
      * (3) set proc->rq pointer to rq
      * (4) increase rq->proc_num
      */
     // lab6:2310675 插入优先队列（skew heap）按 stride 最小优先
#if USE_SKEW_HEAP
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
#else
     list_add_before(&(rq->run_list), &(proc->run_link));
#endif

     // lab6:2310675 初始化/校正时间片
     if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice)
     {
          proc->time_slice = rq->max_time_slice;
     }
     proc->rq = rq;
     rq->proc_num++;
}

/*
 * stride_dequeue removes the process ``proc'' from the run-queue
 * ``rq'', the operation would be finished by the skew_heap_remove
 * operations. Remember to update the ``rq'' structure.
 * stride_dequeue 将进程 proc 从运行队列 rq 中移除：
 * - 使用 skew_heap_remove 把 proc->lab6_run_pool 从 rq->lab6_run_pool 中删除
 * - 更新 rq->proc_num 等统计信息
 *
 * hint: see libs/skew_heap.h for routines of the priority
 * queue structures.
 * 提示：优先队列（斜堆）接口见 libs/skew_heap.h。
 */
static void
stride_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: 2310675
      * (1) remove the proc from rq correctly
      * NOTICE: you can use skew_heap or list. Important functions
      *         skew_heap_remove: remove a entry from skew_heap
      *         list_del_init: remove a entry from the  list
      */
     assert(proc->rq == rq && rq->proc_num > 0);
#if USE_SKEW_HEAP
     rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
#else
     list_del_init(&(proc->run_link));
#endif
     rq->proc_num--;
}
/*
 * stride_pick_next pick the element from the ``run-queue'', with the
 * minimum value of stride, and returns the corresponding process
 * pointer. The process pointer would be calculated by macro le2proc,
 * see kern/process/proc.h for definition. Return NULL if
 * there is no process in the queue.
 * stride_pick_next 从运行队列中选择 stride 最小的进程并返回：
 * - 使用斜堆时，堆顶就是 stride 最小的节点，可用 le2proc 取回对应的 proc_struct
 * - 使用链表时，需要遍历查找最小 stride（复杂度更高）
 * 队列为空则返回 NULL。
 *
 * When one proc structure is selected, remember to update the stride
 * property of the proc. (stride += BIG_STRIDE / priority)
 * 选中进程后需要更新其 stride：
 *   stride += BIG_STRIDE / priority
 * priority 越大，增量越小，stride 增长越慢，因此更容易保持“最小”，获得更多 CPU。
 *
 * hint: see libs/skew_heap.h for routines of the priority
 * queue structures.
 * 提示：优先队列（斜堆）接口见 libs/skew_heap.h。
 */
static struct proc_struct *
stride_pick_next(struct run_queue *rq)
{
     /* LAB6 CHALLENGE 1: 2310675
      * (1) get a  proc_struct pointer p  with the minimum value of stride
             (1.1) If using skew_heap, we can use le2proc get the p from rq->lab6_run_pol
             (1.2) If using list, we have to search list to find the p with minimum stride value
      * (2) update p;s stride value: p->lab6_stride
      * (3) return p
      */
     if (rq->proc_num == 0)
     {
          return NULL;
     }
#if USE_SKEW_HEAP
     if (rq->lab6_run_pool == NULL)
     {
          return NULL;
     }
     struct proc_struct *proc = le2proc(rq->lab6_run_pool, lab6_run_pool);
#else
     struct proc_struct *proc = NULL, *p;
     list_entry_t *le = list_next(&(rq->run_list));
     while (le != &(rq->run_list))
     {
          p = le2proc(le, run_link);
          if (proc == NULL || proc_stride_comp_f(&(p->lab6_run_pool), &(proc->lab6_run_pool)) < 0)
          {
               proc = p;
          }
          le = list_next(le);
     }
     if (proc == NULL)
     {
          return NULL;
     }
#endif
     // lab6:2310675 更新 stride：stride += BIG_STRIDE / priority
     proc->lab6_stride += BIG_STRIDE / proc->lab6_priority;
     return proc;
}

/*
 * stride_proc_tick works with the tick event of current process. You
 * should check whether the time slices for current process is
 * exhausted and update the proc struct ``proc''. proc->time_slice
 * denotes the time slices left for current
 * process. proc->need_resched is the flag variable for process
 * switching.
 * stride_proc_tick 处理当前进程的一个“时钟滴答”：
 * - 递减 proc->time_slice（剩余时间片）
 * - 若时间片耗尽，则设置 proc->need_resched 触发调度
 * 与 RR 类似：tick 只设置标志位，真正的 schedule 在 trap 返回用户态前的安全点执行。
 */
static void
stride_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: 2310675 */
     // lab6:2310675 与 RR 类似：时间片耗尽则触发重调度
     if (proc->time_slice > 0)
     {
          proc->time_slice--;
     }
     if (proc->time_slice == 0)
     {
          proc->need_resched = 1;
     }
}

struct sched_class stride_sched_class = {
    .name = "stride_scheduler",
    .init = stride_init,
    .enqueue = stride_enqueue,
    .dequeue = stride_dequeue,
    .pick_next = stride_pick_next,
    .proc_tick = stride_proc_tick,
};
