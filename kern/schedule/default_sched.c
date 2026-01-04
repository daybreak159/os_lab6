#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * default_sched.c：Round-Robin（RR）时间片轮转调度（lab6）
 *
 * 核心策略：
 * - 所有 runnable 进程排成一个 FIFO 队列
 * - 每个进程拥有一个 time_slice（时间片计数）
 * - 每次时钟 tick：time_slice--，耗尽则 need_resched=1，触发 schedule() 重新选择进程
 *
 * RR 的优点：实现简单、公平性较强（进程获得 CPU 时间趋于均等）
 * RR 的局限：无法表达“不同优先级/不同权重”的份额需求（这就是 Stride 的动机）
 */

/*
 * RR_init - 初始化 RR 调度器的运行队列（sched_class 接口之一）
 * @rq: 运行队列指针
 *
 * 功能说明：
 * 1. 初始化就绪队列链表 run_list（双向循环链表）
 * 2. 将进程计数器 proc_num 清零
 * 3. max_time_slice 由调用者（sched_init）设置，这里无需处理
 *
 * 调用路径：sched_init() → sched_class->init(rq) → RR_init(rq)
 *
 * RR_init initializes the run-queue rq with correct assignment for
 * member variables, including:
 * RR_init 会正确初始化运行队列 rq 的关键成员，包括：
 *
 *   - run_list: should be an empty list after initialization.
 *   - run_list：初始化后应为空链表（仅有表头结点）。
 *   - proc_num: set to 0
 *   - proc_num：运行队列中的进程数量清零。
 *   - max_time_slice: no need here, the variable would be assigned by the caller.
 *   - max_time_slice：这里无需设置，由调用者（sched_init）赋值。
 *
 * hint: see libs/list.h for routines of the list structures.
 * 提示：链表相关操作可参考 libs/list.h。
 */
static void
RR_init(struct run_queue *rq)
{
    // LAB6: 2310675
    // lab6:2310675 初始化就绪队列链表，并清零进程数
    list_init(&(rq->run_list));
    rq->proc_num = 0;
}

/*
 * RR_enqueue - 将进程加入 RR 调度器的就绪队列（sched_class 接口之一）
 * @rq:   运行队列指针
 * @proc: 要加入的进程
 *
 * 功能说明：
 * 1. 将进程插入队尾（list_add_before: 插入到 rq->run_list 之前，即队尾）
 * 2. 初始化/校正进程的时间片：
 *    - 如果 time_slice == 0（新进程）或 > max_time_slice（异常情况）
 *    - 则将其设置为 rq->max_time_slice（默认时间片大小）
 * 3. 更新进程的 rq 指针（指向所属运行队列）
 * 4. 增加运行队列的进程计数 proc_num
 *
 * RR 的入队策略：FIFO（先进先出），所有进程公平排队
 *
 * 调用路径：wakeup_proc() → sched_class->enqueue() → RR_enqueue()
 *          schedule() → sched_class->enqueue() → RR_enqueue()（当前进程仍 runnable 时）
 *
 * RR_enqueue inserts the process ``proc'' into the tail of run-queue
 * ``rq''. The procedure should verify/initialize the relevant members
 * of ``proc'', and then put the ``run_link'' node into the queue.
 * The procedure should also update the meta data in ``rq'' structure.
 * RR_enqueue 把进程 proc 插入到运行队列 rq 的队尾：需要检查/初始化 proc 的相关字段，
 * 并把 proc->run_link 挂到队列上，同时更新 rq 中的统计信息。
 *
 * proc->time_slice denotes the time slices allocation for the
 * process, which should set to rq->max_time_slice.
 * proc->time_slice 表示该进程本轮可使用的剩余时间片；入队时通常应设置为 rq->max_time_slice。
 *
 * hint: see libs/list.h for routines of the list structures.
 * 提示：链表相关操作可参考 libs/list.h。
 */
static void
RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2310675
    // lab6:2310675 把进程插入队尾，并初始化/校正时间片
    assert(list_empty(&(proc->run_link))); // lab6: 确保进程未在其他队列中
    list_add_before(&(rq->run_list), &(proc->run_link)); // lab6: 插入队尾（循环链表）
    // lab6: 校正时间片（新进程或时间片用尽的进程需要重置）
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice)
    {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq; // lab6: 绑定到运行队列
    rq->proc_num++; // lab6: 更新队列进程数
}

/*
 * RR_dequeue - 将进程从 RR 调度器的就绪队列移除（sched_class 接口之一）
 * @rq:   运行队列指针
 * @proc: 要移除的进程
 *
 * 功能说明：
 * 1. 将进程从就绪队列链表中删除（list_del_init: 删除并重新初始化节点）
 * 2. 减少运行队列的进程计数 proc_num
 * 3. 断言检查：进程必须在队列中（run_link 非空）且属于该队列（proc->rq == rq）
 *
 * 调用时机：
 * - schedule() 选中下一个进程后，将其从队列中移除
 * - 进程进入阻塞状态（如 sleep/wait）时，从就绪队列移除
 *
 * 调用路径：schedule() → sched_class->dequeue() → RR_dequeue()
 *
 * RR_dequeue removes the process ``proc'' from the front of run-queue
 * ``rq'', the operation would be finished by the list_del_init operation.
 * Remember to update the ``rq'' structure.
 * RR_dequeue 把进程 proc 从运行队列 rq 中移除（通过 list_del_init 完成），并更新 rq 的计数等信息。
 *
 * hint: see libs/list.h for routines of the list structures.
 * 提示：链表相关操作可参考 libs/list.h。
 */
static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2310675
    // lab6:2310675 将进程从就绪队列移除，并更新计数
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq); // lab6: 确保进程在该队列中
    list_del_init(&(proc->run_link)); // lab6: 从链表删除并初始化节点
    rq->proc_num--; // lab6: 更新队列进程数
}

/*
 * RR_pick_next - 从 RR 调度器的就绪队列中选择下一个要运行的进程（sched_class 接口之一）
 * @rq: 运行队列指针
 *
 * 功能说明：
 * 1. 取队首进程（list_next: 获取链表的下一个节点，即队首）
 * 2. 如果队列非空，返回队首进程指针（通过 le2proc 宏转换）
 * 3. 如果队列为空，返回 NULL
 *
 * RR 的调度策略：FIFO（先进先出），总是选择队首进程
 * - 简单公平，每个进程按加入顺序获得 CPU 时间
 * - 不考虑优先级或权重
 *
 * 调用路径：schedule() → sched_class->pick_next() → RR_pick_next()
 *
 * le2proc 宏说明：
 * - 将链表节点指针转换为进程结构体指针
 * - le2proc(le, run_link) = container_of(le, proc_struct, run_link)
 * - 即：根据 run_link 字段的地址反推出 proc_struct 的地址
 *
 * RR_pick_next picks the element from the front of ``run-queue'',
 * and returns the corresponding process pointer. The process pointer
 * would be calculated by macro le2proc, see kern/process/proc.h
 * for definition. Return NULL if there is no process in the queue.
 * RR_pick_next 从运行队列 rq 的队首选择下一个要运行的进程，并返回其 proc_struct 指针。
 * 通过 le2proc 宏可从链表节点反推宿主进程结构体（定义见 kern/process/proc.h）。
 * 若队列为空则返回 NULL。
 *
 * hint: see libs/list.h for routines of the list structures.
 * 提示：链表相关操作可参考 libs/list.h。
 */
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: 2310675
    // lab6:2310675 取队首进程作为下一运行者
    list_entry_t *le = list_next(&(rq->run_list)); // lab6: 获取队首节点
    if (le != &(rq->run_list)) // lab6: 检查队列非空（循环链表头节点不是进程）
    {
        return le2proc(le, run_link); // lab6: 将链表节点转换为进程指针
    }
    return NULL; // lab6: 队列为空，无可调度进程
}

/*
 * RR_proc_tick - 处理时钟滴答事件，更新当前进程的时间片（sched_class 接口之一）
 * @rq:   运行队列指针
 * @proc: 当前正在运行的进程
 *
 * 功能说明：
 * 1. 将当前进程的时间片减 1（proc->time_slice--）
 * 2. 如果时间片耗尽（time_slice == 0），则置位 need_resched 标志
 * 3. need_resched = 1 会触发 schedule() 重新选择进程
 *
 * 调用路径：
 * - timer interrupt → trap() → interrupt_handler() → clock_set_next_event() → ticks++
 * - trap() → sched_class_proc_tick(current) → sched_class->proc_tick() → RR_proc_tick()
 * - trap() 返回前检查 need_resched，若为 1 则调用 schedule()
 *
 * RR 的时间片管理：
 * - 每个进程分配 max_time_slice 个 tick（默认为 5）
 * - 每个 tick 递减 1，耗尽后触发重调度
 * - 重新入队后时间片会被重置为 max_time_slice（在 RR_enqueue 中）
 *
 * RR_proc_tick works with the tick event of current process. You
 * should check whether the time slices for current process is
 * exhausted and update the proc struct ``proc''. proc->time_slice
 * denotes the time slices left for current process. proc->need_resched
 * is the flag variable for process switching.
 * RR_proc_tick 处理当前进程的一个“时钟滴答”：
 * - 递减 proc->time_slice（剩余时间片）
 * - 若时间片耗尽，则设置 proc->need_resched 触发调度
 * 其中 need_resched 是“需要重新调度”的标志位，实际调度发生在 trap 返回用户态前的安全点。
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2310675
    // lab6:2310675 时间片递减，为 0 时触发重调度
    if (proc->time_slice > 0) // lab6: 检查时间片剩余
    {
        proc->time_slice--; // lab6: 递减时间片
    }
    if (proc->time_slice == 0) // lab6: 时间片耗尽
    {
        proc->need_resched = 1; // lab6: 置位重调度标志
    }
}

struct sched_class default_sched_class = {
    .name = "RR_scheduler",
    .init = RR_init,
    .enqueue = RR_enqueue,
    .dequeue = RR_dequeue,
    .pick_next = RR_pick_next,
    .proc_tick = RR_proc_tick,
};
