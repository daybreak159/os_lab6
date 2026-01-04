#include <ulib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/*
 * matrix：调度测试程序之一
 *
 * 思路：创建一批子进程，每个子进程做一定量的 CPU 计算（矩阵乘法）并打印开始/结束。
 * - 能否全部跑完并输出 "matrix pass."：验证 fork/wait/exit 基本正确
 * - 多进程长时间计算场景下系统是否仍能响应：间接验证时钟中断驱动的抢占式调度是否工作
 */

#define MATSIZE     10

static int mata[MATSIZE][MATSIZE];
static int matb[MATSIZE][MATSIZE];
static int matc[MATSIZE][MATSIZE];

void
work(unsigned int times) {
    int i, j, k, size = MATSIZE;
    for (i = 0; i < size; i ++) {
        for (j = 0; j < size; j ++) {
            mata[i][j] = matb[i][j] = 1;
        }
    }

    yield();
    // 主动让出一次 CPU，确保调度路径（sys_yield -> need_resched -> schedule）可触发

    cprintf("pid %d is running (%d times)!.\n", getpid(), times);

    while (times -- > 0) {
        for (i = 0; i < size; i ++) {
            for (j = 0; j < size; j ++) {
                matc[i][j] = 0;
                for (k = 0; k < size; k ++) {
                    matc[i][j] += mata[i][k] * matb[k][j];
                }
            }
        }
        for (i = 0; i < size; i ++) {
            for (j = 0; j < size; j ++) {
                mata[i][j] = matb[i][j] = matc[i][j];
            }
        }
    }
    cprintf("pid %d done!.\n", getpid());
    exit(0);
}

const int total = 21;

int
main(void) {
    int pids[total];
    memset(pids, 0, sizeof(pids));

    int i;
    for (i = 0; i < total; i ++) {
        if ((pids[i] = fork()) == 0) {
            srand(i * i);
            int times = (((unsigned int)rand()) % total);
            times = (times * times + 10) * 100;
            work(times);
        }
        if (pids[i] < 0) {
            goto failed;
        }
    }

    cprintf("fork ok.\n");

    for (i = 0; i < total; i ++) {
        if (wait() != 0) {
            cprintf("wait failed.\n");
            goto failed;
        }
    }

    cprintf("matrix pass.\n");
    return 0;

failed:
    for (i = 0; i < total; i ++) {
        if (pids[i] > 0) {
            kill(pids[i]);
        }
    }
    panic("FAIL: T.T\n");
}
