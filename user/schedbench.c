#include <ulib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/*
 * schedbench.c：Lab6 Challenge2 用于对比调度算法的简单基准程序
 *
 * 思路：
 * - fork 出多个子进程（固定 5 个）
 * - 每个子进程设置一个“参数”（复用 lab6_setpriority）：
 *     - 在 Stride/HPF：代表优先级（越大越优先/份额越大）
 *     - 在 SJF：代表“作业长度估计”（越小越短）
 * - 子进程先 yield 一次，让所有进程都有机会完成参数设置，再开始做 CPU-bound 工作
 * - 子进程运行到各自的目标时长后退出，并打印 start/end/elapsed
 *
 * 运行方式示例：
 * - RR：        make -C lab6 run-nox-schedbench DEFS+='-DSCHED_RR'
 * - Stride：    make -C lab6 run-nox-schedbench DEFS+='-DSCHED_STRIDE'
 * - FIFO：      make -C lab6 run-nox-schedbench DEFS+='-DSCHED_FIFO'
 * - SJF：       make -C lab6 run-nox-schedbench DEFS+='-DSCHED_SJF'
 * - HPF：       make -C lab6 run-nox-schedbench DEFS+='-DSCHED_HPF'
 */

#define NCHILD 5

static void
spin_delay(void) {
    int i;
    volatile int j = 0;
    for (i = 0; i != 200; i++) {
        j = !j;
    }
}

int
main(void) {
    int pids[NCHILD];
    int i;
    memset(pids, 0, sizeof(pids));

    // 设定一组“长度/优先级参数”
    // - 对 SJF：越小越短（更容易先跑完）
    // - 对 HPF/Stride：越大越优先
    int param[NCHILD] = {5, 1, 3, 2, 4};
    // 每个子进程目标运行时长（ms），用于对比完成顺序/周转时间
    int dur_ms[NCHILD] = {2500, 500, 1500, 1000, 2000};

    cprintf("schedbench: start, time=%dms\n", gettime_msec());
    for (i = 0; i < NCHILD; i++) {
        int pid = fork();
        if (pid < 0) {
            panic("fork failed\n");
        }
        if (pid == 0) {
            int start = gettime_msec();
            // 复用 lab6_setpriority 作为“调度参数”
            lab6_setpriority(param[i]);
            // 让出一次 CPU，确保其它子进程也完成参数设置（便于 SJF/HPF 对比）
            yield();

            // CPU-bound：运行到目标时间后退出
            while (gettime_msec() - start < dur_ms[i]) {
                spin_delay();
            }
            int end = gettime_msec();
            cprintf("child idx=%d pid=%d param=%d start=%d end=%d elapsed=%d\n",
                    i, getpid(), param[i], start, end, end - start);
            // 退出码携带 idx，父进程可用 waitpid(0,&status) 得知完成顺序
            exit(i);
        }
        pids[i] = pid;
    }

    // 父进程等待并按完成顺序输出（用于观察 FIFO/SJF/HPF/RR/Stride 差异）
    cprintf("parent: fork ok, waiting...\n");
    for (i = 0; i < NCHILD; i++) {
        int status = -1;
        // Lab6 的 wait 语义：pid=0 表示等待任意子进程，返回值固定为 0，退出码写入 status
        waitpid(0, &status);
        cprintf("parent: child idx=%d done, time=%dms\n", status, gettime_msec());
    }
    cprintf("schedbench: done, time=%dms\n", gettime_msec());
    return 0;
}
