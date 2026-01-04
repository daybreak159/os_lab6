
obj/__user_schedbench.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	142000ef          	jal	ra,800162 <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <__panic>:
#include <stdio.h>
#include <ulib.h>
#include <error.h>

void
__panic(const char *file, int line, const char *fmt, ...) {
  800026:	715d                	addi	sp,sp,-80
  800028:	8e2e                	mv	t3,a1
  80002a:	e822                	sd	s0,16(sp)
    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("user panic at %s:%d:\n    ", file, line);
  80002c:	85aa                	mv	a1,a0
__panic(const char *file, int line, const char *fmt, ...) {
  80002e:	8432                	mv	s0,a2
  800030:	fc3e                	sd	a5,56(sp)
    cprintf("user panic at %s:%d:\n    ", file, line);
  800032:	8672                	mv	a2,t3
    va_start(ap, fmt);
  800034:	103c                	addi	a5,sp,40
    cprintf("user panic at %s:%d:\n    ", file, line);
  800036:	00000517          	auipc	a0,0x0
  80003a:	6ba50513          	addi	a0,a0,1722 # 8006f0 <main+0x166>
__panic(const char *file, int line, const char *fmt, ...) {
  80003e:	ec06                	sd	ra,24(sp)
  800040:	f436                	sd	a3,40(sp)
  800042:	f83a                	sd	a4,48(sp)
  800044:	e0c2                	sd	a6,64(sp)
  800046:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800048:	e43e                	sd	a5,8(sp)
    cprintf("user panic at %s:%d:\n    ", file, line);
  80004a:	058000ef          	jal	ra,8000a2 <cprintf>
    vcprintf(fmt, ap);
  80004e:	65a2                	ld	a1,8(sp)
  800050:	8522                	mv	a0,s0
  800052:	030000ef          	jal	ra,800082 <vcprintf>
    cprintf("\n");
  800056:	00000517          	auipc	a0,0x0
  80005a:	6ba50513          	addi	a0,a0,1722 # 800710 <main+0x186>
  80005e:	044000ef          	jal	ra,8000a2 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0d8000ef          	jal	ra,80013c <exit>

0000000000800068 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800068:	1141                	addi	sp,sp,-16
  80006a:	e022                	sd	s0,0(sp)
  80006c:	e406                	sd	ra,8(sp)
  80006e:	842e                	mv	s0,a1
    sys_putc(c);
  800070:	0ba000ef          	jal	ra,80012a <sys_putc>
    (*cnt) ++;
  800074:	401c                	lw	a5,0(s0)
}
  800076:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
  800078:	2785                	addiw	a5,a5,1
  80007a:	c01c                	sw	a5,0(s0)
}
  80007c:	6402                	ld	s0,0(sp)
  80007e:	0141                	addi	sp,sp,16
  800080:	8082                	ret

0000000000800082 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
  800082:	1101                	addi	sp,sp,-32
  800084:	862a                	mv	a2,a0
  800086:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800088:	00000517          	auipc	a0,0x0
  80008c:	fe050513          	addi	a0,a0,-32 # 800068 <cputch>
  800090:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
  800092:	ec06                	sd	ra,24(sp)
    int cnt = 0;
  800094:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800096:	144000ef          	jal	ra,8001da <vprintfmt>
    return cnt;
}
  80009a:	60e2                	ld	ra,24(sp)
  80009c:	4532                	lw	a0,12(sp)
  80009e:	6105                	addi	sp,sp,32
  8000a0:	8082                	ret

00000000008000a2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  8000a2:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  8000a4:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  8000a8:	8e2a                	mv	t3,a0
  8000aa:	f42e                	sd	a1,40(sp)
  8000ac:	f832                	sd	a2,48(sp)
  8000ae:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000b0:	00000517          	auipc	a0,0x0
  8000b4:	fb850513          	addi	a0,a0,-72 # 800068 <cputch>
  8000b8:	004c                	addi	a1,sp,4
  8000ba:	869a                	mv	a3,t1
  8000bc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
  8000be:	ec06                	sd	ra,24(sp)
  8000c0:	e0ba                	sd	a4,64(sp)
  8000c2:	e4be                	sd	a5,72(sp)
  8000c4:	e8c2                	sd	a6,80(sp)
  8000c6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  8000c8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
  8000ca:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000cc:	10e000ef          	jal	ra,8001da <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  8000d0:	60e2                	ld	ra,24(sp)
  8000d2:	4512                	lw	a0,4(sp)
  8000d4:	6125                	addi	sp,sp,96
  8000d6:	8082                	ret

00000000008000d8 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  8000d8:	7175                	addi	sp,sp,-144
  8000da:	f8ba                	sd	a4,112(sp)
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  8000dc:	e0ba                	sd	a4,64(sp)
  8000de:	0118                	addi	a4,sp,128
syscall(int64_t num, ...) {
  8000e0:	e42a                	sd	a0,8(sp)
  8000e2:	ecae                	sd	a1,88(sp)
  8000e4:	f0b2                	sd	a2,96(sp)
  8000e6:	f4b6                	sd	a3,104(sp)
  8000e8:	fcbe                	sd	a5,120(sp)
  8000ea:	e142                	sd	a6,128(sp)
  8000ec:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  8000ee:	f42e                	sd	a1,40(sp)
  8000f0:	f832                	sd	a2,48(sp)
  8000f2:	fc36                	sd	a3,56(sp)
  8000f4:	f03a                	sd	a4,32(sp)
  8000f6:	e4be                	sd	a5,72(sp)
    }
    va_end(ap);
    asm volatile (
  8000f8:	4522                	lw	a0,8(sp)
  8000fa:	55a2                	lw	a1,40(sp)
  8000fc:	5642                	lw	a2,48(sp)
  8000fe:	56e2                	lw	a3,56(sp)
  800100:	4706                	lw	a4,64(sp)
  800102:	47a6                	lw	a5,72(sp)
  800104:	00000073          	ecall
  800108:	ce2a                	sw	a0,28(sp)
          "m" (a[3]),
          "m" (a[4])
        : "memory"
      );
    return ret;
}
  80010a:	4572                	lw	a0,28(sp)
  80010c:	6149                	addi	sp,sp,144
  80010e:	8082                	ret

0000000000800110 <sys_exit>:

int
sys_exit(int64_t error_code) {
  800110:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  800112:	4505                	li	a0,1
  800114:	b7d1                	j	8000d8 <syscall>

0000000000800116 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  800116:	4509                	li	a0,2
  800118:	b7c1                	j	8000d8 <syscall>

000000000080011a <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  80011a:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  80011c:	85aa                	mv	a1,a0
  80011e:	450d                	li	a0,3
  800120:	bf65                	j	8000d8 <syscall>

0000000000800122 <sys_yield>:
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  800122:	4529                	li	a0,10
  800124:	bf55                	j	8000d8 <syscall>

0000000000800126 <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  800126:	4549                	li	a0,18
  800128:	bf45                	j	8000d8 <syscall>

000000000080012a <sys_putc>:
}

int
sys_putc(int64_t c) {
  80012a:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  80012c:	4579                	li	a0,30
  80012e:	b76d                	j	8000d8 <syscall>

0000000000800130 <sys_gettime>:
    return syscall(SYS_pgdir);
}

int
sys_gettime(void) {
    return syscall(SYS_gettime);
  800130:	4545                	li	a0,17
  800132:	b75d                	j	8000d8 <syscall>

0000000000800134 <sys_lab6_set_priority>:
}

void
sys_lab6_set_priority(uint64_t priority)
{
  800134:	85aa                	mv	a1,a0
    syscall(SYS_lab6_set_priority, priority);
  800136:	0ff00513          	li	a0,255
  80013a:	bf79                	j	8000d8 <syscall>

000000000080013c <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  80013c:	1141                	addi	sp,sp,-16
  80013e:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  800140:	fd1ff0ef          	jal	ra,800110 <sys_exit>
    cprintf("BUG: exit failed.\n");
  800144:	00000517          	auipc	a0,0x0
  800148:	5d450513          	addi	a0,a0,1492 # 800718 <main+0x18e>
  80014c:	f57ff0ef          	jal	ra,8000a2 <cprintf>
    while (1);
  800150:	a001                	j	800150 <exit+0x14>

0000000000800152 <fork>:
}

int
fork(void) {
    return sys_fork();
  800152:	b7d1                	j	800116 <sys_fork>

0000000000800154 <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  800154:	b7d9                	j	80011a <sys_wait>

0000000000800156 <yield>:
}

void
yield(void) {
    sys_yield();
  800156:	b7f1                	j	800122 <sys_yield>

0000000000800158 <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  800158:	b7f9                	j	800126 <sys_getpid>

000000000080015a <gettime_msec>:
    sys_pgdir();
}

unsigned int
gettime_msec(void) {
    return (unsigned int)sys_gettime();
  80015a:	bfd9                	j	800130 <sys_gettime>

000000000080015c <lab6_setpriority>:
}

void
lab6_setpriority(uint32_t priority)
{
    sys_lab6_set_priority(priority);
  80015c:	1502                	slli	a0,a0,0x20
  80015e:	9101                	srli	a0,a0,0x20
  800160:	bfd1                	j	800134 <sys_lab6_set_priority>

0000000000800162 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  800162:	1141                	addi	sp,sp,-16
  800164:	e406                	sd	ra,8(sp)
    int ret = main();
  800166:	424000ef          	jal	ra,80058a <main>
    exit(ret);
  80016a:	fd3ff0ef          	jal	ra,80013c <exit>

000000000080016e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  80016e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800172:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  800174:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800178:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  80017a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  80017e:	f022                	sd	s0,32(sp)
  800180:	ec26                	sd	s1,24(sp)
  800182:	e84a                	sd	s2,16(sp)
  800184:	f406                	sd	ra,40(sp)
  800186:	e44e                	sd	s3,8(sp)
  800188:	84aa                	mv	s1,a0
  80018a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  80018c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  800190:	2a01                	sext.w	s4,s4
    if (num >= base) {
  800192:	03067e63          	bgeu	a2,a6,8001ce <printnum+0x60>
  800196:	89be                	mv	s3,a5
        while (-- width > 0)
  800198:	00805763          	blez	s0,8001a6 <printnum+0x38>
  80019c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  80019e:	85ca                	mv	a1,s2
  8001a0:	854e                	mv	a0,s3
  8001a2:	9482                	jalr	s1
        while (-- width > 0)
  8001a4:	fc65                	bnez	s0,80019c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  8001a6:	1a02                	slli	s4,s4,0x20
  8001a8:	00000797          	auipc	a5,0x0
  8001ac:	58878793          	addi	a5,a5,1416 # 800730 <main+0x1a6>
  8001b0:	020a5a13          	srli	s4,s4,0x20
  8001b4:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  8001b6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001b8:	000a4503          	lbu	a0,0(s4)
}
  8001bc:	70a2                	ld	ra,40(sp)
  8001be:	69a2                	ld	s3,8(sp)
  8001c0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001c2:	85ca                	mv	a1,s2
  8001c4:	87a6                	mv	a5,s1
}
  8001c6:	6942                	ld	s2,16(sp)
  8001c8:	64e2                	ld	s1,24(sp)
  8001ca:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001cc:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001ce:	03065633          	divu	a2,a2,a6
  8001d2:	8722                	mv	a4,s0
  8001d4:	f9bff0ef          	jal	ra,80016e <printnum>
  8001d8:	b7f9                	j	8001a6 <printnum+0x38>

00000000008001da <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001da:	7119                	addi	sp,sp,-128
  8001dc:	f4a6                	sd	s1,104(sp)
  8001de:	f0ca                	sd	s2,96(sp)
  8001e0:	ecce                	sd	s3,88(sp)
  8001e2:	e8d2                	sd	s4,80(sp)
  8001e4:	e4d6                	sd	s5,72(sp)
  8001e6:	e0da                	sd	s6,64(sp)
  8001e8:	fc5e                	sd	s7,56(sp)
  8001ea:	f06a                	sd	s10,32(sp)
  8001ec:	fc86                	sd	ra,120(sp)
  8001ee:	f8a2                	sd	s0,112(sp)
  8001f0:	f862                	sd	s8,48(sp)
  8001f2:	f466                	sd	s9,40(sp)
  8001f4:	ec6e                	sd	s11,24(sp)
  8001f6:	892a                	mv	s2,a0
  8001f8:	84ae                	mv	s1,a1
  8001fa:	8d32                	mv	s10,a2
  8001fc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001fe:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  800202:	5b7d                	li	s6,-1
  800204:	00000a97          	auipc	s5,0x0
  800208:	560a8a93          	addi	s5,s5,1376 # 800764 <main+0x1da>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80020c:	00000b97          	auipc	s7,0x0
  800210:	774b8b93          	addi	s7,s7,1908 # 800980 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800214:	000d4503          	lbu	a0,0(s10)
  800218:	001d0413          	addi	s0,s10,1
  80021c:	01350a63          	beq	a0,s3,800230 <vprintfmt+0x56>
            if (ch == '\0') {
  800220:	c121                	beqz	a0,800260 <vprintfmt+0x86>
            putch(ch, putdat);
  800222:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800224:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  800226:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800228:	fff44503          	lbu	a0,-1(s0)
  80022c:	ff351ae3          	bne	a0,s3,800220 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  800230:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  800234:	02000793          	li	a5,32
        lflag = altflag = 0;
  800238:	4c81                	li	s9,0
  80023a:	4881                	li	a7,0
        width = precision = -1;
  80023c:	5c7d                	li	s8,-1
  80023e:	5dfd                	li	s11,-1
  800240:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  800244:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  800246:	fdd6059b          	addiw	a1,a2,-35
  80024a:	0ff5f593          	zext.b	a1,a1
  80024e:	00140d13          	addi	s10,s0,1
  800252:	04b56263          	bltu	a0,a1,800296 <vprintfmt+0xbc>
  800256:	058a                	slli	a1,a1,0x2
  800258:	95d6                	add	a1,a1,s5
  80025a:	4194                	lw	a3,0(a1)
  80025c:	96d6                	add	a3,a3,s5
  80025e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  800260:	70e6                	ld	ra,120(sp)
  800262:	7446                	ld	s0,112(sp)
  800264:	74a6                	ld	s1,104(sp)
  800266:	7906                	ld	s2,96(sp)
  800268:	69e6                	ld	s3,88(sp)
  80026a:	6a46                	ld	s4,80(sp)
  80026c:	6aa6                	ld	s5,72(sp)
  80026e:	6b06                	ld	s6,64(sp)
  800270:	7be2                	ld	s7,56(sp)
  800272:	7c42                	ld	s8,48(sp)
  800274:	7ca2                	ld	s9,40(sp)
  800276:	7d02                	ld	s10,32(sp)
  800278:	6de2                	ld	s11,24(sp)
  80027a:	6109                	addi	sp,sp,128
  80027c:	8082                	ret
            padc = '0';
  80027e:	87b2                	mv	a5,a2
            goto reswitch;
  800280:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800284:	846a                	mv	s0,s10
  800286:	00140d13          	addi	s10,s0,1
  80028a:	fdd6059b          	addiw	a1,a2,-35
  80028e:	0ff5f593          	zext.b	a1,a1
  800292:	fcb572e3          	bgeu	a0,a1,800256 <vprintfmt+0x7c>
            putch('%', putdat);
  800296:	85a6                	mv	a1,s1
  800298:	02500513          	li	a0,37
  80029c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  80029e:	fff44783          	lbu	a5,-1(s0)
  8002a2:	8d22                	mv	s10,s0
  8002a4:	f73788e3          	beq	a5,s3,800214 <vprintfmt+0x3a>
  8002a8:	ffed4783          	lbu	a5,-2(s10)
  8002ac:	1d7d                	addi	s10,s10,-1
  8002ae:	ff379de3          	bne	a5,s3,8002a8 <vprintfmt+0xce>
  8002b2:	b78d                	j	800214 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  8002b4:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  8002b8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  8002bc:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  8002be:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  8002c2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002c6:	02d86463          	bltu	a6,a3,8002ee <vprintfmt+0x114>
                ch = *fmt;
  8002ca:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  8002ce:	002c169b          	slliw	a3,s8,0x2
  8002d2:	0186873b          	addw	a4,a3,s8
  8002d6:	0017171b          	slliw	a4,a4,0x1
  8002da:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  8002dc:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  8002e0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  8002e2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  8002e6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002ea:	fed870e3          	bgeu	a6,a3,8002ca <vprintfmt+0xf0>
            if (width < 0)
  8002ee:	f40ddce3          	bgez	s11,800246 <vprintfmt+0x6c>
                width = precision, precision = -1;
  8002f2:	8de2                	mv	s11,s8
  8002f4:	5c7d                	li	s8,-1
  8002f6:	bf81                	j	800246 <vprintfmt+0x6c>
            if (width < 0)
  8002f8:	fffdc693          	not	a3,s11
  8002fc:	96fd                	srai	a3,a3,0x3f
  8002fe:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  800302:	00144603          	lbu	a2,1(s0)
  800306:	2d81                	sext.w	s11,s11
  800308:	846a                	mv	s0,s10
            goto reswitch;
  80030a:	bf35                	j	800246 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  80030c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  800310:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  800314:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  800316:	846a                	mv	s0,s10
            goto process_precision;
  800318:	bfd9                	j	8002ee <vprintfmt+0x114>
    if (lflag >= 2) {
  80031a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80031c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800320:	01174463          	blt	a4,a7,800328 <vprintfmt+0x14e>
    else if (lflag) {
  800324:	1a088e63          	beqz	a7,8004e0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  800328:	000a3603          	ld	a2,0(s4)
  80032c:	46c1                	li	a3,16
  80032e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  800330:	2781                	sext.w	a5,a5
  800332:	876e                	mv	a4,s11
  800334:	85a6                	mv	a1,s1
  800336:	854a                	mv	a0,s2
  800338:	e37ff0ef          	jal	ra,80016e <printnum>
            break;
  80033c:	bde1                	j	800214 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  80033e:	000a2503          	lw	a0,0(s4)
  800342:	85a6                	mv	a1,s1
  800344:	0a21                	addi	s4,s4,8
  800346:	9902                	jalr	s2
            break;
  800348:	b5f1                	j	800214 <vprintfmt+0x3a>
    if (lflag >= 2) {
  80034a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80034c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800350:	01174463          	blt	a4,a7,800358 <vprintfmt+0x17e>
    else if (lflag) {
  800354:	18088163          	beqz	a7,8004d6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  800358:	000a3603          	ld	a2,0(s4)
  80035c:	46a9                	li	a3,10
  80035e:	8a2e                	mv	s4,a1
  800360:	bfc1                	j	800330 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  800362:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  800366:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  800368:	846a                	mv	s0,s10
            goto reswitch;
  80036a:	bdf1                	j	800246 <vprintfmt+0x6c>
            putch(ch, putdat);
  80036c:	85a6                	mv	a1,s1
  80036e:	02500513          	li	a0,37
  800372:	9902                	jalr	s2
            break;
  800374:	b545                	j	800214 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  800376:	00144603          	lbu	a2,1(s0)
            lflag ++;
  80037a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  80037c:	846a                	mv	s0,s10
            goto reswitch;
  80037e:	b5e1                	j	800246 <vprintfmt+0x6c>
    if (lflag >= 2) {
  800380:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800382:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800386:	01174463          	blt	a4,a7,80038e <vprintfmt+0x1b4>
    else if (lflag) {
  80038a:	14088163          	beqz	a7,8004cc <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  80038e:	000a3603          	ld	a2,0(s4)
  800392:	46a1                	li	a3,8
  800394:	8a2e                	mv	s4,a1
  800396:	bf69                	j	800330 <vprintfmt+0x156>
            putch('0', putdat);
  800398:	03000513          	li	a0,48
  80039c:	85a6                	mv	a1,s1
  80039e:	e03e                	sd	a5,0(sp)
  8003a0:	9902                	jalr	s2
            putch('x', putdat);
  8003a2:	85a6                	mv	a1,s1
  8003a4:	07800513          	li	a0,120
  8003a8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8003aa:	0a21                	addi	s4,s4,8
            goto number;
  8003ac:	6782                	ld	a5,0(sp)
  8003ae:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8003b0:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  8003b4:	bfb5                	j	800330 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003b6:	000a3403          	ld	s0,0(s4)
  8003ba:	008a0713          	addi	a4,s4,8
  8003be:	e03a                	sd	a4,0(sp)
  8003c0:	14040263          	beqz	s0,800504 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  8003c4:	0fb05763          	blez	s11,8004b2 <vprintfmt+0x2d8>
  8003c8:	02d00693          	li	a3,45
  8003cc:	0cd79163          	bne	a5,a3,80048e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003d0:	00044783          	lbu	a5,0(s0)
  8003d4:	0007851b          	sext.w	a0,a5
  8003d8:	cf85                	beqz	a5,800410 <vprintfmt+0x236>
  8003da:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003de:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003e2:	000c4563          	bltz	s8,8003ec <vprintfmt+0x212>
  8003e6:	3c7d                	addiw	s8,s8,-1
  8003e8:	036c0263          	beq	s8,s6,80040c <vprintfmt+0x232>
                    putch('?', putdat);
  8003ec:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003ee:	0e0c8e63          	beqz	s9,8004ea <vprintfmt+0x310>
  8003f2:	3781                	addiw	a5,a5,-32
  8003f4:	0ef47b63          	bgeu	s0,a5,8004ea <vprintfmt+0x310>
                    putch('?', putdat);
  8003f8:	03f00513          	li	a0,63
  8003fc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003fe:	000a4783          	lbu	a5,0(s4)
  800402:	3dfd                	addiw	s11,s11,-1
  800404:	0a05                	addi	s4,s4,1
  800406:	0007851b          	sext.w	a0,a5
  80040a:	ffe1                	bnez	a5,8003e2 <vprintfmt+0x208>
            for (; width > 0; width --) {
  80040c:	01b05963          	blez	s11,80041e <vprintfmt+0x244>
  800410:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  800412:	85a6                	mv	a1,s1
  800414:	02000513          	li	a0,32
  800418:	9902                	jalr	s2
            for (; width > 0; width --) {
  80041a:	fe0d9be3          	bnez	s11,800410 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  80041e:	6a02                	ld	s4,0(sp)
  800420:	bbd5                	j	800214 <vprintfmt+0x3a>
    if (lflag >= 2) {
  800422:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800424:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  800428:	01174463          	blt	a4,a7,800430 <vprintfmt+0x256>
    else if (lflag) {
  80042c:	08088d63          	beqz	a7,8004c6 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  800430:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  800434:	0a044d63          	bltz	s0,8004ee <vprintfmt+0x314>
            num = getint(&ap, lflag);
  800438:	8622                	mv	a2,s0
  80043a:	8a66                	mv	s4,s9
  80043c:	46a9                	li	a3,10
  80043e:	bdcd                	j	800330 <vprintfmt+0x156>
            err = va_arg(ap, int);
  800440:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800444:	4761                	li	a4,24
            err = va_arg(ap, int);
  800446:	0a21                	addi	s4,s4,8
            if (err < 0) {
  800448:	41f7d69b          	sraiw	a3,a5,0x1f
  80044c:	8fb5                	xor	a5,a5,a3
  80044e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800452:	02d74163          	blt	a4,a3,800474 <vprintfmt+0x29a>
  800456:	00369793          	slli	a5,a3,0x3
  80045a:	97de                	add	a5,a5,s7
  80045c:	639c                	ld	a5,0(a5)
  80045e:	cb99                	beqz	a5,800474 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  800460:	86be                	mv	a3,a5
  800462:	00000617          	auipc	a2,0x0
  800466:	2fe60613          	addi	a2,a2,766 # 800760 <main+0x1d6>
  80046a:	85a6                	mv	a1,s1
  80046c:	854a                	mv	a0,s2
  80046e:	0ce000ef          	jal	ra,80053c <printfmt>
  800472:	b34d                	j	800214 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  800474:	00000617          	auipc	a2,0x0
  800478:	2dc60613          	addi	a2,a2,732 # 800750 <main+0x1c6>
  80047c:	85a6                	mv	a1,s1
  80047e:	854a                	mv	a0,s2
  800480:	0bc000ef          	jal	ra,80053c <printfmt>
  800484:	bb41                	j	800214 <vprintfmt+0x3a>
                p = "(null)";
  800486:	00000417          	auipc	s0,0x0
  80048a:	2c240413          	addi	s0,s0,706 # 800748 <main+0x1be>
                for (width -= strnlen(p, precision); width > 0; width --) {
  80048e:	85e2                	mv	a1,s8
  800490:	8522                	mv	a0,s0
  800492:	e43e                	sd	a5,8(sp)
  800494:	0c8000ef          	jal	ra,80055c <strnlen>
  800498:	40ad8dbb          	subw	s11,s11,a0
  80049c:	01b05b63          	blez	s11,8004b2 <vprintfmt+0x2d8>
                    putch(padc, putdat);
  8004a0:	67a2                	ld	a5,8(sp)
  8004a2:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004a6:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  8004a8:	85a6                	mv	a1,s1
  8004aa:	8552                	mv	a0,s4
  8004ac:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004ae:	fe0d9ce3          	bnez	s11,8004a6 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004b2:	00044783          	lbu	a5,0(s0)
  8004b6:	00140a13          	addi	s4,s0,1
  8004ba:	0007851b          	sext.w	a0,a5
  8004be:	d3a5                	beqz	a5,80041e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  8004c0:	05e00413          	li	s0,94
  8004c4:	bf39                	j	8003e2 <vprintfmt+0x208>
        return va_arg(*ap, int);
  8004c6:	000a2403          	lw	s0,0(s4)
  8004ca:	b7ad                	j	800434 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  8004cc:	000a6603          	lwu	a2,0(s4)
  8004d0:	46a1                	li	a3,8
  8004d2:	8a2e                	mv	s4,a1
  8004d4:	bdb1                	j	800330 <vprintfmt+0x156>
  8004d6:	000a6603          	lwu	a2,0(s4)
  8004da:	46a9                	li	a3,10
  8004dc:	8a2e                	mv	s4,a1
  8004de:	bd89                	j	800330 <vprintfmt+0x156>
  8004e0:	000a6603          	lwu	a2,0(s4)
  8004e4:	46c1                	li	a3,16
  8004e6:	8a2e                	mv	s4,a1
  8004e8:	b5a1                	j	800330 <vprintfmt+0x156>
                    putch(ch, putdat);
  8004ea:	9902                	jalr	s2
  8004ec:	bf09                	j	8003fe <vprintfmt+0x224>
                putch('-', putdat);
  8004ee:	85a6                	mv	a1,s1
  8004f0:	02d00513          	li	a0,45
  8004f4:	e03e                	sd	a5,0(sp)
  8004f6:	9902                	jalr	s2
                num = -(long long)num;
  8004f8:	6782                	ld	a5,0(sp)
  8004fa:	8a66                	mv	s4,s9
  8004fc:	40800633          	neg	a2,s0
  800500:	46a9                	li	a3,10
  800502:	b53d                	j	800330 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  800504:	03b05163          	blez	s11,800526 <vprintfmt+0x34c>
  800508:	02d00693          	li	a3,45
  80050c:	f6d79de3          	bne	a5,a3,800486 <vprintfmt+0x2ac>
                p = "(null)";
  800510:	00000417          	auipc	s0,0x0
  800514:	23840413          	addi	s0,s0,568 # 800748 <main+0x1be>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800518:	02800793          	li	a5,40
  80051c:	02800513          	li	a0,40
  800520:	00140a13          	addi	s4,s0,1
  800524:	bd6d                	j	8003de <vprintfmt+0x204>
  800526:	00000a17          	auipc	s4,0x0
  80052a:	223a0a13          	addi	s4,s4,547 # 800749 <main+0x1bf>
  80052e:	02800513          	li	a0,40
  800532:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  800536:	05e00413          	li	s0,94
  80053a:	b565                	j	8003e2 <vprintfmt+0x208>

000000000080053c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80053c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  80053e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800542:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800544:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800546:	ec06                	sd	ra,24(sp)
  800548:	f83a                	sd	a4,48(sp)
  80054a:	fc3e                	sd	a5,56(sp)
  80054c:	e0c2                	sd	a6,64(sp)
  80054e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800550:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800552:	c89ff0ef          	jal	ra,8001da <vprintfmt>
}
  800556:	60e2                	ld	ra,24(sp)
  800558:	6161                	addi	sp,sp,80
  80055a:	8082                	ret

000000000080055c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  80055c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  80055e:	e589                	bnez	a1,800568 <strnlen+0xc>
  800560:	a811                	j	800574 <strnlen+0x18>
        cnt ++;
  800562:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800564:	00f58863          	beq	a1,a5,800574 <strnlen+0x18>
  800568:	00f50733          	add	a4,a0,a5
  80056c:	00074703          	lbu	a4,0(a4)
  800570:	fb6d                	bnez	a4,800562 <strnlen+0x6>
  800572:	85be                	mv	a1,a5
    }
    return cnt;
}
  800574:	852e                	mv	a0,a1
  800576:	8082                	ret

0000000000800578 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
  800578:	ca01                	beqz	a2,800588 <memset+0x10>
  80057a:	962a                	add	a2,a2,a0
    char *p = s;
  80057c:	87aa                	mv	a5,a0
        *p ++ = c;
  80057e:	0785                	addi	a5,a5,1
  800580:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
  800584:	fec79de3          	bne	a5,a2,80057e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
  800588:	8082                	ret

000000000080058a <main>:
        j = !j;
    }
}

int
main(void) {
  80058a:	7119                	addi	sp,sp,-128
    int pids[NCHILD];
    int i;
    memset(pids, 0, sizeof(pids));
  80058c:	4651                	li	a2,20
  80058e:	4581                	li	a1,0
  800590:	0028                	addi	a0,sp,8
main(void) {
  800592:	fc86                	sd	ra,120(sp)
  800594:	f8a2                	sd	s0,112(sp)
  800596:	f4a6                	sd	s1,104(sp)
  800598:	f0ca                	sd	s2,96(sp)
  80059a:	ecce                	sd	s3,88(sp)
  80059c:	e8d2                	sd	s4,80(sp)
    memset(pids, 0, sizeof(pids));
  80059e:	fdbff0ef          	jal	ra,800578 <memset>

    // 设定一组“长度/优先级参数”
    // - 对 SJF：越小越短（更容易先跑完）
    // - 对 HPF/Stride：越大越优先
    int param[NCHILD] = {5, 1, 3, 2, 4};
  8005a2:	4785                	li	a5,1
  8005a4:	02079693          	slli	a3,a5,0x20
  8005a8:	1786                	slli	a5,a5,0x21
  8005aa:	078d                	addi	a5,a5,3
  8005ac:	f43e                	sd	a5,40(sp)
  8005ae:	4791                	li	a5,4
    // 每个子进程目标运行时长（ms），用于对比完成顺序/周转时间
    int dur_ms[NCHILD] = {2500, 500, 1500, 1000, 2000};
  8005b0:	07d00713          	li	a4,125
    int param[NCHILD] = {5, 1, 3, 2, 4};
  8005b4:	d83e                	sw	a5,48(sp)
    int dur_ms[NCHILD] = {2500, 500, 1500, 1000, 2000};
  8005b6:	00000797          	auipc	a5,0x0
  8005ba:	5827b783          	ld	a5,1410(a5) # 800b38 <error_string+0x1b8>
  8005be:	fc3e                	sd	a5,56(sp)
  8005c0:	02371793          	slli	a5,a4,0x23
  8005c4:	5dc78793          	addi	a5,a5,1500
    int param[NCHILD] = {5, 1, 3, 2, 4};
  8005c8:	0695                	addi	a3,a3,5
    int dur_ms[NCHILD] = {2500, 500, 1500, 1000, 2000};
  8005ca:	e0be                	sd	a5,64(sp)
  8005cc:	7d000793          	li	a5,2000
    int param[NCHILD] = {5, 1, 3, 2, 4};
  8005d0:	f036                	sd	a3,32(sp)
    int dur_ms[NCHILD] = {2500, 500, 1500, 1000, 2000};
  8005d2:	c4be                	sw	a5,72(sp)

    cprintf("schedbench: start, time=%dms\n", gettime_msec());
  8005d4:	b87ff0ef          	jal	ra,80015a <gettime_msec>
  8005d8:	0005059b          	sext.w	a1,a0
  8005dc:	00000517          	auipc	a0,0x0
  8005e0:	46c50513          	addi	a0,a0,1132 # 800a48 <error_string+0xc8>
  8005e4:	abfff0ef          	jal	ra,8000a2 <cprintf>
    for (i = 0; i < NCHILD; i++) {
  8005e8:	0020                	addi	s0,sp,8
  8005ea:	4481                	li	s1,0
  8005ec:	4915                	li	s2,5
        int pid = fork();
  8005ee:	b65ff0ef          	jal	ra,800152 <fork>
        if (pid < 0) {
  8005f2:	06054763          	bltz	a0,800660 <main+0xd6>
            panic("fork failed\n");
        }
        if (pid == 0) {
  8005f6:	c149                	beqz	a0,800678 <main+0xee>
            cprintf("child idx=%d pid=%d param=%d start=%d end=%d elapsed=%d\n",
                    i, getpid(), param[i], start, end, end - start);
            // 退出码携带 idx，父进程可用 waitpid(0,&status) 得知完成顺序
            exit(i);
        }
        pids[i] = pid;
  8005f8:	c008                	sw	a0,0(s0)
    for (i = 0; i < NCHILD; i++) {
  8005fa:	2485                	addiw	s1,s1,1
  8005fc:	0411                	addi	s0,s0,4
  8005fe:	ff2498e3          	bne	s1,s2,8005ee <main+0x64>
    }

    // 父进程等待并按完成顺序输出（用于观察 FIFO/SJF/HPF/RR/Stride 差异）
    cprintf("parent: fork ok, waiting...\n");
  800602:	00000517          	auipc	a0,0x0
  800606:	4ce50513          	addi	a0,a0,1230 # 800ad0 <error_string+0x150>
  80060a:	a99ff0ef          	jal	ra,8000a2 <cprintf>
  80060e:	4415                	li	s0,5
    for (i = 0; i < NCHILD; i++) {
        int status = -1;
  800610:	59fd                	li	s3,-1
        // Lab6 的 wait 语义：pid=0 表示等待任意子进程，返回值固定为 0，退出码写入 status
        waitpid(0, &status);
        cprintf("parent: child idx=%d done, time=%dms\n", status, gettime_msec());
  800612:	00000917          	auipc	s2,0x0
  800616:	4de90913          	addi	s2,s2,1246 # 800af0 <error_string+0x170>
        waitpid(0, &status);
  80061a:	004c                	addi	a1,sp,4
  80061c:	4501                	li	a0,0
        int status = -1;
  80061e:	c24e                	sw	s3,4(sp)
        waitpid(0, &status);
  800620:	b35ff0ef          	jal	ra,800154 <waitpid>
        cprintf("parent: child idx=%d done, time=%dms\n", status, gettime_msec());
  800624:	4492                	lw	s1,4(sp)
  800626:	b35ff0ef          	jal	ra,80015a <gettime_msec>
  80062a:	0005061b          	sext.w	a2,a0
    for (i = 0; i < NCHILD; i++) {
  80062e:	347d                	addiw	s0,s0,-1
        cprintf("parent: child idx=%d done, time=%dms\n", status, gettime_msec());
  800630:	85a6                	mv	a1,s1
  800632:	854a                	mv	a0,s2
  800634:	a6fff0ef          	jal	ra,8000a2 <cprintf>
    for (i = 0; i < NCHILD; i++) {
  800638:	f06d                	bnez	s0,80061a <main+0x90>
    }
    cprintf("schedbench: done, time=%dms\n", gettime_msec());
  80063a:	b21ff0ef          	jal	ra,80015a <gettime_msec>
  80063e:	0005059b          	sext.w	a1,a0
  800642:	00000517          	auipc	a0,0x0
  800646:	4d650513          	addi	a0,a0,1238 # 800b18 <error_string+0x198>
  80064a:	a59ff0ef          	jal	ra,8000a2 <cprintf>
    return 0;
}
  80064e:	70e6                	ld	ra,120(sp)
  800650:	7446                	ld	s0,112(sp)
  800652:	74a6                	ld	s1,104(sp)
  800654:	7906                	ld	s2,96(sp)
  800656:	69e6                	ld	s3,88(sp)
  800658:	6a46                	ld	s4,80(sp)
  80065a:	4501                	li	a0,0
  80065c:	6109                	addi	sp,sp,128
  80065e:	8082                	ret
            panic("fork failed\n");
  800660:	00000617          	auipc	a2,0x0
  800664:	40860613          	addi	a2,a2,1032 # 800a68 <error_string+0xe8>
  800668:	03500593          	li	a1,53
  80066c:	00000517          	auipc	a0,0x0
  800670:	40c50513          	addi	a0,a0,1036 # 800a78 <error_string+0xf8>
  800674:	9b3ff0ef          	jal	ra,800026 <__panic>
            int start = gettime_msec();
  800678:	ae3ff0ef          	jal	ra,80015a <gettime_msec>
            lab6_setpriority(param[i]);
  80067c:	089c                	addi	a5,sp,80
  80067e:	00249413          	slli	s0,s1,0x2
  800682:	943e                	add	s0,s0,a5
  800684:	fd042983          	lw	s3,-48(s0)
            int start = gettime_msec();
  800688:	00050a1b          	sext.w	s4,a0
  80068c:	8952                	mv	s2,s4
            lab6_setpriority(param[i]);
  80068e:	854e                	mv	a0,s3
  800690:	acdff0ef          	jal	ra,80015c <lab6_setpriority>
            yield();
  800694:	ac3ff0ef          	jal	ra,800156 <yield>
            while (gettime_msec() - start < dur_ms[i]) {
  800698:	ac3ff0ef          	jal	ra,80015a <gettime_msec>
  80069c:	fe842703          	lw	a4,-24(s0)
  8006a0:	414507bb          	subw	a5,a0,s4
  8006a4:	00e7fd63          	bgeu	a5,a4,8006be <main+0x134>
    volatile int j = 0;
  8006a8:	c202                	sw	zero,4(sp)
  8006aa:	0c800713          	li	a4,200
        j = !j;
  8006ae:	4792                	lw	a5,4(sp)
    for (i = 0; i != 200; i++) {
  8006b0:	377d                	addiw	a4,a4,-1
        j = !j;
  8006b2:	2781                	sext.w	a5,a5
  8006b4:	0017b793          	seqz	a5,a5
  8006b8:	c23e                	sw	a5,4(sp)
    for (i = 0; i != 200; i++) {
  8006ba:	fb75                	bnez	a4,8006ae <main+0x124>
  8006bc:	bff1                	j	800698 <main+0x10e>
            int end = gettime_msec();
  8006be:	a9dff0ef          	jal	ra,80015a <gettime_msec>
  8006c2:	0005041b          	sext.w	s0,a0
            cprintf("child idx=%d pid=%d param=%d start=%d end=%d elapsed=%d\n",
  8006c6:	a93ff0ef          	jal	ra,800158 <getpid>
  8006ca:	862a                	mv	a2,a0
  8006cc:	4124083b          	subw	a6,s0,s2
  8006d0:	87a2                	mv	a5,s0
  8006d2:	874a                	mv	a4,s2
  8006d4:	86ce                	mv	a3,s3
  8006d6:	85a6                	mv	a1,s1
  8006d8:	00000517          	auipc	a0,0x0
  8006dc:	3b850513          	addi	a0,a0,952 # 800a90 <error_string+0x110>
  8006e0:	9c3ff0ef          	jal	ra,8000a2 <cprintf>
            exit(i);
  8006e4:	8526                	mv	a0,s1
  8006e6:	a57ff0ef          	jal	ra,80013c <exit>
