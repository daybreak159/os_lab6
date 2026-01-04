#ifndef __KERN_SYSCALL_SYSCALL_H__
#define __KERN_SYSCALL_SYSCALL_H__

// 系统调用入口：由 trap/exception 处理路径调用，在 kern/syscall/syscall.c 中完成分发
void syscall(void);

#endif /* !__KERN_SYSCALL_SYSCALL_H__ */
