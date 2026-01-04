
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000ce517          	auipc	a0,0xce
ffffffffc020004e:	b2e50513          	addi	a0,a0,-1234 # ffffffffc02cdb78 <buf>
ffffffffc0200052:	000d2617          	auipc	a2,0xd2
ffffffffc0200056:	00660613          	addi	a2,a2,6 # ffffffffc02d2058 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	7ee050ef          	jal	ra,ffffffffc0205850 <memset>
    cons_init(); // init the console
ffffffffc0200066:	520000ef          	jal	ra,ffffffffc0200586 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00006597          	auipc	a1,0x6
ffffffffc020006e:	81658593          	addi	a1,a1,-2026 # ffffffffc0205880 <etext+0x6>
ffffffffc0200072:	00006517          	auipc	a0,0x6
ffffffffc0200076:	82e50513          	addi	a0,a0,-2002 # ffffffffc02058a0 <etext+0x26>
ffffffffc020007a:	11e000ef          	jal	ra,ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1a2000ef          	jal	ra,ffffffffc0200220 <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	576000ef          	jal	ra,ffffffffc02005f8 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	5c0020ef          	jal	ra,ffffffffc0202646 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	12b000ef          	jal	ra,ffffffffc02009b4 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	129000ef          	jal	ra,ffffffffc02009b6 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	099030ef          	jal	ra,ffffffffc020392a <vmm_init>
     * - 选择一个 sched_class（例如 RR 或 Stride）
     * - 初始化全局运行队列 run_queue，并设置 max_time_slice
     *
     * 之后时钟中断会通过 proc_tick 驱动时间片消耗，need_resched 会触发 schedule() 做进程切换。
     */
    sched_init();
ffffffffc0200096:	050050ef          	jal	ra,ffffffffc02050e6 <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	4ef040ef          	jal	ra,ffffffffc0204d88 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	4a0000ef          	jal	ra,ffffffffc020053e <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	107000ef          	jal	ra,ffffffffc02009a8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	67b040ef          	jal	ra,ffffffffc0204f20 <cpu_idle>

ffffffffc02000aa <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000aa:	715d                	addi	sp,sp,-80
ffffffffc02000ac:	e486                	sd	ra,72(sp)
ffffffffc02000ae:	e0a6                	sd	s1,64(sp)
ffffffffc02000b0:	fc4a                	sd	s2,56(sp)
ffffffffc02000b2:	f84e                	sd	s3,48(sp)
ffffffffc02000b4:	f452                	sd	s4,40(sp)
ffffffffc02000b6:	f056                	sd	s5,32(sp)
ffffffffc02000b8:	ec5a                	sd	s6,24(sp)
ffffffffc02000ba:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000bc:	c901                	beqz	a0,ffffffffc02000cc <readline+0x22>
ffffffffc02000be:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000c0:	00005517          	auipc	a0,0x5
ffffffffc02000c4:	7e850513          	addi	a0,a0,2024 # ffffffffc02058a8 <etext+0x2e>
ffffffffc02000c8:	0d0000ef          	jal	ra,ffffffffc0200198 <cprintf>
readline(const char *prompt) {
ffffffffc02000cc:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ce:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d0:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000d2:	4aa9                	li	s5,10
ffffffffc02000d4:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d6:	000ceb97          	auipc	s7,0xce
ffffffffc02000da:	aa2b8b93          	addi	s7,s7,-1374 # ffffffffc02cdb78 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000de:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000e2:	12e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000e6:	00054a63          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ea:	00a95a63          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc02000ee:	029a5263          	bge	s4,s1,ffffffffc0200112 <readline+0x68>
        c = getchar();
ffffffffc02000f2:	11e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000f6:	fe055ae3          	bgez	a0,ffffffffc02000ea <readline+0x40>
            return NULL;
ffffffffc02000fa:	4501                	li	a0,0
ffffffffc02000fc:	a091                	j	ffffffffc0200140 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fe:	03351463          	bne	a0,s3,ffffffffc0200126 <readline+0x7c>
ffffffffc0200102:	e8a9                	bnez	s1,ffffffffc0200154 <readline+0xaa>
        c = getchar();
ffffffffc0200104:	10c000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc0200108:	fe0549e3          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010c:	fea959e3          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc0200110:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200112:	e42a                	sd	a0,8(sp)
ffffffffc0200114:	0ba000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i ++] = c;
ffffffffc0200118:	6522                	ld	a0,8(sp)
ffffffffc020011a:	009b87b3          	add	a5,s7,s1
ffffffffc020011e:	2485                	addiw	s1,s1,1
ffffffffc0200120:	00a78023          	sb	a0,0(a5)
ffffffffc0200124:	bf7d                	j	ffffffffc02000e2 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200126:	01550463          	beq	a0,s5,ffffffffc020012e <readline+0x84>
ffffffffc020012a:	fb651ce3          	bne	a0,s6,ffffffffc02000e2 <readline+0x38>
            cputchar(c);
ffffffffc020012e:	0a0000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i] = '\0';
ffffffffc0200132:	000ce517          	auipc	a0,0xce
ffffffffc0200136:	a4650513          	addi	a0,a0,-1466 # ffffffffc02cdb78 <buf>
ffffffffc020013a:	94aa                	add	s1,s1,a0
ffffffffc020013c:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200140:	60a6                	ld	ra,72(sp)
ffffffffc0200142:	6486                	ld	s1,64(sp)
ffffffffc0200144:	7962                	ld	s2,56(sp)
ffffffffc0200146:	79c2                	ld	s3,48(sp)
ffffffffc0200148:	7a22                	ld	s4,40(sp)
ffffffffc020014a:	7a82                	ld	s5,32(sp)
ffffffffc020014c:	6b62                	ld	s6,24(sp)
ffffffffc020014e:	6bc2                	ld	s7,16(sp)
ffffffffc0200150:	6161                	addi	sp,sp,80
ffffffffc0200152:	8082                	ret
            cputchar(c);
ffffffffc0200154:	4521                	li	a0,8
ffffffffc0200156:	078000ef          	jal	ra,ffffffffc02001ce <cputchar>
            i --;
ffffffffc020015a:	34fd                	addiw	s1,s1,-1
ffffffffc020015c:	b759                	j	ffffffffc02000e2 <readline+0x38>

ffffffffc020015e <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015e:	1141                	addi	sp,sp,-16
ffffffffc0200160:	e022                	sd	s0,0(sp)
ffffffffc0200162:	e406                	sd	ra,8(sp)
ffffffffc0200164:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200166:	422000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    (*cnt)++;
ffffffffc020016a:	401c                	lw	a5,0(s0)
}
ffffffffc020016c:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016e:	2785                	addiw	a5,a5,1
ffffffffc0200170:	c01c                	sw	a5,0(s0)
}
ffffffffc0200172:	6402                	ld	s0,0(sp)
ffffffffc0200174:	0141                	addi	sp,sp,16
ffffffffc0200176:	8082                	ret

ffffffffc0200178 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200178:	1101                	addi	sp,sp,-32
ffffffffc020017a:	862a                	mv	a2,a0
ffffffffc020017c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017e:	00000517          	auipc	a0,0x0
ffffffffc0200182:	fe050513          	addi	a0,a0,-32 # ffffffffc020015e <cputch>
ffffffffc0200186:	006c                	addi	a1,sp,12
{
ffffffffc0200188:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020018a:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020018c:	2a0050ef          	jal	ra,ffffffffc020542c <vprintfmt>
    return cnt;
}
ffffffffc0200190:	60e2                	ld	ra,24(sp)
ffffffffc0200192:	4532                	lw	a0,12(sp)
ffffffffc0200194:	6105                	addi	sp,sp,32
ffffffffc0200196:	8082                	ret

ffffffffc0200198 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200198:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020019a:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
{
ffffffffc020019e:	8e2a                	mv	t3,a0
ffffffffc02001a0:	f42e                	sd	a1,40(sp)
ffffffffc02001a2:	f832                	sd	a2,48(sp)
ffffffffc02001a4:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a6:	00000517          	auipc	a0,0x0
ffffffffc02001aa:	fb850513          	addi	a0,a0,-72 # ffffffffc020015e <cputch>
ffffffffc02001ae:	004c                	addi	a1,sp,4
ffffffffc02001b0:	869a                	mv	a3,t1
ffffffffc02001b2:	8672                	mv	a2,t3
{
ffffffffc02001b4:	ec06                	sd	ra,24(sp)
ffffffffc02001b6:	e0ba                	sd	a4,64(sp)
ffffffffc02001b8:	e4be                	sd	a5,72(sp)
ffffffffc02001ba:	e8c2                	sd	a6,80(sp)
ffffffffc02001bc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001be:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001c0:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001c2:	26a050ef          	jal	ra,ffffffffc020542c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c6:	60e2                	ld	ra,24(sp)
ffffffffc02001c8:	4512                	lw	a0,4(sp)
ffffffffc02001ca:	6125                	addi	sp,sp,96
ffffffffc02001cc:	8082                	ret

ffffffffc02001ce <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ce:	ae6d                	j	ffffffffc0200588 <cons_putc>

ffffffffc02001d0 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001d0:	1101                	addi	sp,sp,-32
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	ec06                	sd	ra,24(sp)
ffffffffc02001d6:	e426                	sd	s1,8(sp)
ffffffffc02001d8:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001da:	00054503          	lbu	a0,0(a0)
ffffffffc02001de:	c51d                	beqz	a0,ffffffffc020020c <cputs+0x3c>
ffffffffc02001e0:	0405                	addi	s0,s0,1
ffffffffc02001e2:	4485                	li	s1,1
ffffffffc02001e4:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e6:	3a2000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001ea:	00044503          	lbu	a0,0(s0)
ffffffffc02001ee:	008487bb          	addw	a5,s1,s0
ffffffffc02001f2:	0405                	addi	s0,s0,1
ffffffffc02001f4:	f96d                	bnez	a0,ffffffffc02001e6 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f6:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001fa:	4529                	li	a0,10
ffffffffc02001fc:	38c000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200200:	60e2                	ld	ra,24(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	6442                	ld	s0,16(sp)
ffffffffc0200206:	64a2                	ld	s1,8(sp)
ffffffffc0200208:	6105                	addi	sp,sp,32
ffffffffc020020a:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc020020c:	4405                	li	s0,1
ffffffffc020020e:	b7f5                	j	ffffffffc02001fa <cputs+0x2a>

ffffffffc0200210 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200210:	1141                	addi	sp,sp,-16
ffffffffc0200212:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200214:	3a8000ef          	jal	ra,ffffffffc02005bc <cons_getc>
ffffffffc0200218:	dd75                	beqz	a0,ffffffffc0200214 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020021a:	60a2                	ld	ra,8(sp)
ffffffffc020021c:	0141                	addi	sp,sp,16
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200220:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200222:	00005517          	auipc	a0,0x5
ffffffffc0200226:	68e50513          	addi	a0,a0,1678 # ffffffffc02058b0 <etext+0x36>
void print_kerninfo(void) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	f6dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200230:	00000597          	auipc	a1,0x0
ffffffffc0200234:	e1a58593          	addi	a1,a1,-486 # ffffffffc020004a <kern_init>
ffffffffc0200238:	00005517          	auipc	a0,0x5
ffffffffc020023c:	69850513          	addi	a0,a0,1688 # ffffffffc02058d0 <etext+0x56>
ffffffffc0200240:	f59ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200244:	00005597          	auipc	a1,0x5
ffffffffc0200248:	63658593          	addi	a1,a1,1590 # ffffffffc020587a <etext>
ffffffffc020024c:	00005517          	auipc	a0,0x5
ffffffffc0200250:	6a450513          	addi	a0,a0,1700 # ffffffffc02058f0 <etext+0x76>
ffffffffc0200254:	f45ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200258:	000ce597          	auipc	a1,0xce
ffffffffc020025c:	92058593          	addi	a1,a1,-1760 # ffffffffc02cdb78 <buf>
ffffffffc0200260:	00005517          	auipc	a0,0x5
ffffffffc0200264:	6b050513          	addi	a0,a0,1712 # ffffffffc0205910 <etext+0x96>
ffffffffc0200268:	f31ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020026c:	000d2597          	auipc	a1,0xd2
ffffffffc0200270:	dec58593          	addi	a1,a1,-532 # ffffffffc02d2058 <end>
ffffffffc0200274:	00005517          	auipc	a0,0x5
ffffffffc0200278:	6bc50513          	addi	a0,a0,1724 # ffffffffc0205930 <etext+0xb6>
ffffffffc020027c:	f1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200280:	000d2597          	auipc	a1,0xd2
ffffffffc0200284:	1d758593          	addi	a1,a1,471 # ffffffffc02d2457 <end+0x3ff>
ffffffffc0200288:	00000797          	auipc	a5,0x0
ffffffffc020028c:	dc278793          	addi	a5,a5,-574 # ffffffffc020004a <kern_init>
ffffffffc0200290:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200294:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200298:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029a:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029e:	95be                	add	a1,a1,a5
ffffffffc02002a0:	85a9                	srai	a1,a1,0xa
ffffffffc02002a2:	00005517          	auipc	a0,0x5
ffffffffc02002a6:	6ae50513          	addi	a0,a0,1710 # ffffffffc0205950 <etext+0xd6>
}
ffffffffc02002aa:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ac:	b5f5                	j	ffffffffc0200198 <cprintf>

ffffffffc02002ae <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002ae:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b0:	00005617          	auipc	a2,0x5
ffffffffc02002b4:	6d060613          	addi	a2,a2,1744 # ffffffffc0205980 <etext+0x106>
ffffffffc02002b8:	04d00593          	li	a1,77
ffffffffc02002bc:	00005517          	auipc	a0,0x5
ffffffffc02002c0:	6dc50513          	addi	a0,a0,1756 # ffffffffc0205998 <etext+0x11e>
void print_stackframe(void) {
ffffffffc02002c4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c6:	1cc000ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02002ca <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ca:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002cc:	00005617          	auipc	a2,0x5
ffffffffc02002d0:	6e460613          	addi	a2,a2,1764 # ffffffffc02059b0 <etext+0x136>
ffffffffc02002d4:	00005597          	auipc	a1,0x5
ffffffffc02002d8:	6fc58593          	addi	a1,a1,1788 # ffffffffc02059d0 <etext+0x156>
ffffffffc02002dc:	00005517          	auipc	a0,0x5
ffffffffc02002e0:	6fc50513          	addi	a0,a0,1788 # ffffffffc02059d8 <etext+0x15e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	eb3ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc02002ea:	00005617          	auipc	a2,0x5
ffffffffc02002ee:	6fe60613          	addi	a2,a2,1790 # ffffffffc02059e8 <etext+0x16e>
ffffffffc02002f2:	00005597          	auipc	a1,0x5
ffffffffc02002f6:	71e58593          	addi	a1,a1,1822 # ffffffffc0205a10 <etext+0x196>
ffffffffc02002fa:	00005517          	auipc	a0,0x5
ffffffffc02002fe:	6de50513          	addi	a0,a0,1758 # ffffffffc02059d8 <etext+0x15e>
ffffffffc0200302:	e97ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200306:	00005617          	auipc	a2,0x5
ffffffffc020030a:	71a60613          	addi	a2,a2,1818 # ffffffffc0205a20 <etext+0x1a6>
ffffffffc020030e:	00005597          	auipc	a1,0x5
ffffffffc0200312:	73258593          	addi	a1,a1,1842 # ffffffffc0205a40 <etext+0x1c6>
ffffffffc0200316:	00005517          	auipc	a0,0x5
ffffffffc020031a:	6c250513          	addi	a0,a0,1730 # ffffffffc02059d8 <etext+0x15e>
ffffffffc020031e:	e7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    return 0;
}
ffffffffc0200322:	60a2                	ld	ra,8(sp)
ffffffffc0200324:	4501                	li	a0,0
ffffffffc0200326:	0141                	addi	sp,sp,16
ffffffffc0200328:	8082                	ret

ffffffffc020032a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020032a:	1141                	addi	sp,sp,-16
ffffffffc020032c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032e:	ef3ff0ef          	jal	ra,ffffffffc0200220 <print_kerninfo>
    return 0;
}
ffffffffc0200332:	60a2                	ld	ra,8(sp)
ffffffffc0200334:	4501                	li	a0,0
ffffffffc0200336:	0141                	addi	sp,sp,16
ffffffffc0200338:	8082                	ret

ffffffffc020033a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020033a:	1141                	addi	sp,sp,-16
ffffffffc020033c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033e:	f71ff0ef          	jal	ra,ffffffffc02002ae <print_stackframe>
    return 0;
}
ffffffffc0200342:	60a2                	ld	ra,8(sp)
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	0141                	addi	sp,sp,16
ffffffffc0200348:	8082                	ret

ffffffffc020034a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020034a:	7115                	addi	sp,sp,-224
ffffffffc020034c:	ed5e                	sd	s7,152(sp)
ffffffffc020034e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200350:	00005517          	auipc	a0,0x5
ffffffffc0200354:	70050513          	addi	a0,a0,1792 # ffffffffc0205a50 <etext+0x1d6>
kmonitor(struct trapframe *tf) {
ffffffffc0200358:	ed86                	sd	ra,216(sp)
ffffffffc020035a:	e9a2                	sd	s0,208(sp)
ffffffffc020035c:	e5a6                	sd	s1,200(sp)
ffffffffc020035e:	e1ca                	sd	s2,192(sp)
ffffffffc0200360:	fd4e                	sd	s3,184(sp)
ffffffffc0200362:	f952                	sd	s4,176(sp)
ffffffffc0200364:	f556                	sd	s5,168(sp)
ffffffffc0200366:	f15a                	sd	s6,160(sp)
ffffffffc0200368:	e962                	sd	s8,144(sp)
ffffffffc020036a:	e566                	sd	s9,136(sp)
ffffffffc020036c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036e:	e2bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200372:	00005517          	auipc	a0,0x5
ffffffffc0200376:	70650513          	addi	a0,a0,1798 # ffffffffc0205a78 <etext+0x1fe>
ffffffffc020037a:	e1fff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc020037e:	000b8563          	beqz	s7,ffffffffc0200388 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200382:	855e                	mv	a0,s7
ffffffffc0200384:	01b000ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
ffffffffc0200388:	00005c17          	auipc	s8,0x5
ffffffffc020038c:	760c0c13          	addi	s8,s8,1888 # ffffffffc0205ae8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200390:	00005917          	auipc	s2,0x5
ffffffffc0200394:	71090913          	addi	s2,s2,1808 # ffffffffc0205aa0 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200398:	00005497          	auipc	s1,0x5
ffffffffc020039c:	71048493          	addi	s1,s1,1808 # ffffffffc0205aa8 <etext+0x22e>
        if (argc == MAXARGS - 1) {
ffffffffc02003a0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003a2:	00005b17          	auipc	s6,0x5
ffffffffc02003a6:	70eb0b13          	addi	s6,s6,1806 # ffffffffc0205ab0 <etext+0x236>
        argv[argc ++] = buf;
ffffffffc02003aa:	00005a17          	auipc	s4,0x5
ffffffffc02003ae:	626a0a13          	addi	s4,s4,1574 # ffffffffc02059d0 <etext+0x156>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b4:	854a                	mv	a0,s2
ffffffffc02003b6:	cf5ff0ef          	jal	ra,ffffffffc02000aa <readline>
ffffffffc02003ba:	842a                	mv	s0,a0
ffffffffc02003bc:	dd65                	beqz	a0,ffffffffc02003b4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003c2:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c4:	e1bd                	bnez	a1,ffffffffc020042a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02003c6:	fe0c87e3          	beqz	s9,ffffffffc02003b4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ca:	6582                	ld	a1,0(sp)
ffffffffc02003cc:	00005d17          	auipc	s10,0x5
ffffffffc02003d0:	71cd0d13          	addi	s10,s10,1820 # ffffffffc0205ae8 <commands>
        argv[argc ++] = buf;
ffffffffc02003d4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d6:	4401                	li	s0,0
ffffffffc02003d8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	41c050ef          	jal	ra,ffffffffc02057f6 <strcmp>
ffffffffc02003de:	c919                	beqz	a0,ffffffffc02003f4 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e0:	2405                	addiw	s0,s0,1
ffffffffc02003e2:	0b540063          	beq	s0,s5,ffffffffc0200482 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e6:	000d3503          	ld	a0,0(s10)
ffffffffc02003ea:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ec:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ee:	408050ef          	jal	ra,ffffffffc02057f6 <strcmp>
ffffffffc02003f2:	f57d                	bnez	a0,ffffffffc02003e0 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f4:	00141793          	slli	a5,s0,0x1
ffffffffc02003f8:	97a2                	add	a5,a5,s0
ffffffffc02003fa:	078e                	slli	a5,a5,0x3
ffffffffc02003fc:	97e2                	add	a5,a5,s8
ffffffffc02003fe:	6b9c                	ld	a5,16(a5)
ffffffffc0200400:	865e                	mv	a2,s7
ffffffffc0200402:	002c                	addi	a1,sp,8
ffffffffc0200404:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200408:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020040a:	fa0555e3          	bgez	a0,ffffffffc02003b4 <kmonitor+0x6a>
}
ffffffffc020040e:	60ee                	ld	ra,216(sp)
ffffffffc0200410:	644e                	ld	s0,208(sp)
ffffffffc0200412:	64ae                	ld	s1,200(sp)
ffffffffc0200414:	690e                	ld	s2,192(sp)
ffffffffc0200416:	79ea                	ld	s3,184(sp)
ffffffffc0200418:	7a4a                	ld	s4,176(sp)
ffffffffc020041a:	7aaa                	ld	s5,168(sp)
ffffffffc020041c:	7b0a                	ld	s6,160(sp)
ffffffffc020041e:	6bea                	ld	s7,152(sp)
ffffffffc0200420:	6c4a                	ld	s8,144(sp)
ffffffffc0200422:	6caa                	ld	s9,136(sp)
ffffffffc0200424:	6d0a                	ld	s10,128(sp)
ffffffffc0200426:	612d                	addi	sp,sp,224
ffffffffc0200428:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042a:	8526                	mv	a0,s1
ffffffffc020042c:	40e050ef          	jal	ra,ffffffffc020583a <strchr>
ffffffffc0200430:	c901                	beqz	a0,ffffffffc0200440 <kmonitor+0xf6>
ffffffffc0200432:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200436:	00040023          	sb	zero,0(s0)
ffffffffc020043a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043c:	d5c9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc020043e:	b7f5                	j	ffffffffc020042a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200440:	00044783          	lbu	a5,0(s0)
ffffffffc0200444:	d3c9                	beqz	a5,ffffffffc02003c6 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200446:	033c8963          	beq	s9,s3,ffffffffc0200478 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020044a:	003c9793          	slli	a5,s9,0x3
ffffffffc020044e:	0118                	addi	a4,sp,128
ffffffffc0200450:	97ba                	add	a5,a5,a4
ffffffffc0200452:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200456:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020045a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020045c:	e591                	bnez	a1,ffffffffc0200468 <kmonitor+0x11e>
ffffffffc020045e:	b7b5                	j	ffffffffc02003ca <kmonitor+0x80>
ffffffffc0200460:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200464:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200466:	d1a5                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200468:	8526                	mv	a0,s1
ffffffffc020046a:	3d0050ef          	jal	ra,ffffffffc020583a <strchr>
ffffffffc020046e:	d96d                	beqz	a0,ffffffffc0200460 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200470:	00044583          	lbu	a1,0(s0)
ffffffffc0200474:	d9a9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200476:	bf55                	j	ffffffffc020042a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200478:	45c1                	li	a1,16
ffffffffc020047a:	855a                	mv	a0,s6
ffffffffc020047c:	d1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200480:	b7e9                	j	ffffffffc020044a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200482:	6582                	ld	a1,0(sp)
ffffffffc0200484:	00005517          	auipc	a0,0x5
ffffffffc0200488:	64c50513          	addi	a0,a0,1612 # ffffffffc0205ad0 <etext+0x256>
ffffffffc020048c:	d0dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
ffffffffc0200490:	b715                	j	ffffffffc02003b4 <kmonitor+0x6a>

ffffffffc0200492 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200492:	000d2317          	auipc	t1,0xd2
ffffffffc0200496:	b3e30313          	addi	t1,t1,-1218 # ffffffffc02d1fd0 <is_panic>
ffffffffc020049a:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020049e:	715d                	addi	sp,sp,-80
ffffffffc02004a0:	ec06                	sd	ra,24(sp)
ffffffffc02004a2:	e822                	sd	s0,16(sp)
ffffffffc02004a4:	f436                	sd	a3,40(sp)
ffffffffc02004a6:	f83a                	sd	a4,48(sp)
ffffffffc02004a8:	fc3e                	sd	a5,56(sp)
ffffffffc02004aa:	e0c2                	sd	a6,64(sp)
ffffffffc02004ac:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004ae:	020e1a63          	bnez	t3,ffffffffc02004e2 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004b2:	4785                	li	a5,1
ffffffffc02004b4:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b8:	8432                	mv	s0,a2
ffffffffc02004ba:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004bc:	862e                	mv	a2,a1
ffffffffc02004be:	85aa                	mv	a1,a0
ffffffffc02004c0:	00005517          	auipc	a0,0x5
ffffffffc02004c4:	67050513          	addi	a0,a0,1648 # ffffffffc0205b30 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c8:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004ca:	ccfff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ce:	65a2                	ld	a1,8(sp)
ffffffffc02004d0:	8522                	mv	a0,s0
ffffffffc02004d2:	ca7ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc02004d6:	00006517          	auipc	a0,0x6
ffffffffc02004da:	76250513          	addi	a0,a0,1890 # ffffffffc0206c38 <default_pmm_manager+0x578>
ffffffffc02004de:	cbbff0ef          	jal	ra,ffffffffc0200198 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004e2:	4501                	li	a0,0
ffffffffc02004e4:	4581                	li	a1,0
ffffffffc02004e6:	4601                	li	a2,0
ffffffffc02004e8:	48a1                	li	a7,8
ffffffffc02004ea:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ee:	4c0000ef          	jal	ra,ffffffffc02009ae <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004f2:	4501                	li	a0,0
ffffffffc02004f4:	e57ff0ef          	jal	ra,ffffffffc020034a <kmonitor>
    while (1) {
ffffffffc02004f8:	bfed                	j	ffffffffc02004f2 <__panic+0x60>

ffffffffc02004fa <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004fa:	715d                	addi	sp,sp,-80
ffffffffc02004fc:	832e                	mv	t1,a1
ffffffffc02004fe:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200500:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200502:	8432                	mv	s0,a2
ffffffffc0200504:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200508:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020050a:	00005517          	auipc	a0,0x5
ffffffffc020050e:	64650513          	addi	a0,a0,1606 # ffffffffc0205b50 <commands+0x68>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200512:	ec06                	sd	ra,24(sp)
ffffffffc0200514:	f436                	sd	a3,40(sp)
ffffffffc0200516:	f83a                	sd	a4,48(sp)
ffffffffc0200518:	e0c2                	sd	a6,64(sp)
ffffffffc020051a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020051c:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051e:	c7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200522:	65a2                	ld	a1,8(sp)
ffffffffc0200524:	8522                	mv	a0,s0
ffffffffc0200526:	c53ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc020052a:	00006517          	auipc	a0,0x6
ffffffffc020052e:	70e50513          	addi	a0,a0,1806 # ffffffffc0206c38 <default_pmm_manager+0x578>
ffffffffc0200532:	c67ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    va_end(ap);
}
ffffffffc0200536:	60e2                	ld	ra,24(sp)
ffffffffc0200538:	6442                	ld	s0,16(sp)
ffffffffc020053a:	6161                	addi	sp,sp,80
ffffffffc020053c:	8082                	ret

ffffffffc020053e <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    // 允许 S-mode 的 timer interrupt（STIP），后续在 trap 中处理并驱动调度器 tick
    set_csr(sie, MIP_STIP);
ffffffffc020053e:	02000793          	li	a5,32
ffffffffc0200542:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200546:	c0102573          	rdtime	a0
/*
 * 触发“下一次”时钟中断：
 * - sbi_set_timer() 设置 timer compare 寄存器（抽象为 SBI 调用）
 * - trap 的 timer handler 中会递增 ticks、再次调用 clock_set_next_event()，形成周期性中断
 */
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054a:	67e1                	lui	a5,0x18
ffffffffc020054c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf98>
ffffffffc0200550:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200552:	4581                	li	a1,0
ffffffffc0200554:	4601                	li	a2,0
ffffffffc0200556:	4881                	li	a7,0
ffffffffc0200558:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc020055c:	00005517          	auipc	a0,0x5
ffffffffc0200560:	61450513          	addi	a0,a0,1556 # ffffffffc0205b70 <commands+0x88>
    ticks = 0;
ffffffffc0200564:	000d2797          	auipc	a5,0xd2
ffffffffc0200568:	a607ba23          	sd	zero,-1420(a5) # ffffffffc02d1fd8 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020056c:	b135                	j	ffffffffc0200198 <cprintf>

ffffffffc020056e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200572:	67e1                	lui	a5,0x18
ffffffffc0200574:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf98>
ffffffffc0200578:	953e                	add	a0,a0,a5
ffffffffc020057a:	4581                	li	a1,0
ffffffffc020057c:	4601                	li	a2,0
ffffffffc020057e:	4881                	li	a7,0
ffffffffc0200580:	00000073          	ecall
ffffffffc0200584:	8082                	ret

ffffffffc0200586 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <cons_putc>:
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200588:	100027f3          	csrr	a5,sstatus
ffffffffc020058c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020058e:	0ff57513          	zext.b	a0,a0
ffffffffc0200592:	e799                	bnez	a5,ffffffffc02005a0 <cons_putc+0x18>
ffffffffc0200594:	4581                	li	a1,0
ffffffffc0200596:	4601                	li	a2,0
ffffffffc0200598:	4885                	li	a7,1
ffffffffc020059a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020059e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a0:	1101                	addi	sp,sp,-32
ffffffffc02005a2:	ec06                	sd	ra,24(sp)
ffffffffc02005a4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005a6:	408000ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02005aa:	6522                	ld	a0,8(sp)
ffffffffc02005ac:	4581                	li	a1,0
ffffffffc02005ae:	4601                	li	a2,0
ffffffffc02005b0:	4885                	li	a7,1
ffffffffc02005b2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005b6:	60e2                	ld	ra,24(sp)
ffffffffc02005b8:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005ba:	a6fd                	j	ffffffffc02009a8 <intr_enable>

ffffffffc02005bc <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005bc:	100027f3          	csrr	a5,sstatus
ffffffffc02005c0:	8b89                	andi	a5,a5,2
ffffffffc02005c2:	eb89                	bnez	a5,ffffffffc02005d4 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005c4:	4501                	li	a0,0
ffffffffc02005c6:	4581                	li	a1,0
ffffffffc02005c8:	4601                	li	a2,0
ffffffffc02005ca:	4889                	li	a7,2
ffffffffc02005cc:	00000073          	ecall
ffffffffc02005d0:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d2:	8082                	ret
int cons_getc(void) {
ffffffffc02005d4:	1101                	addi	sp,sp,-32
ffffffffc02005d6:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005d8:	3d6000ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02005dc:	4501                	li	a0,0
ffffffffc02005de:	4581                	li	a1,0
ffffffffc02005e0:	4601                	li	a2,0
ffffffffc02005e2:	4889                	li	a7,2
ffffffffc02005e4:	00000073          	ecall
ffffffffc02005e8:	2501                	sext.w	a0,a0
ffffffffc02005ea:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ec:	3bc000ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc02005f0:	60e2                	ld	ra,24(sp)
ffffffffc02005f2:	6522                	ld	a0,8(sp)
ffffffffc02005f4:	6105                	addi	sp,sp,32
ffffffffc02005f6:	8082                	ret

ffffffffc02005f8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005f8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02005fa:	00005517          	auipc	a0,0x5
ffffffffc02005fe:	59650513          	addi	a0,a0,1430 # ffffffffc0205b90 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200602:	fc86                	sd	ra,120(sp)
ffffffffc0200604:	f8a2                	sd	s0,112(sp)
ffffffffc0200606:	e8d2                	sd	s4,80(sp)
ffffffffc0200608:	f4a6                	sd	s1,104(sp)
ffffffffc020060a:	f0ca                	sd	s2,96(sp)
ffffffffc020060c:	ecce                	sd	s3,88(sp)
ffffffffc020060e:	e4d6                	sd	s5,72(sp)
ffffffffc0200610:	e0da                	sd	s6,64(sp)
ffffffffc0200612:	fc5e                	sd	s7,56(sp)
ffffffffc0200614:	f862                	sd	s8,48(sp)
ffffffffc0200616:	f466                	sd	s9,40(sp)
ffffffffc0200618:	f06a                	sd	s10,32(sp)
ffffffffc020061a:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020061c:	b7dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200620:	0000c597          	auipc	a1,0xc
ffffffffc0200624:	9e05b583          	ld	a1,-1568(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc0200628:	00005517          	auipc	a0,0x5
ffffffffc020062c:	57850513          	addi	a0,a0,1400 # ffffffffc0205ba0 <commands+0xb8>
ffffffffc0200630:	b69ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200634:	0000c417          	auipc	s0,0xc
ffffffffc0200638:	9d440413          	addi	s0,s0,-1580 # ffffffffc020c008 <boot_dtb>
ffffffffc020063c:	600c                	ld	a1,0(s0)
ffffffffc020063e:	00005517          	auipc	a0,0x5
ffffffffc0200642:	57250513          	addi	a0,a0,1394 # ffffffffc0205bb0 <commands+0xc8>
ffffffffc0200646:	b53ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020064a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020064e:	00005517          	auipc	a0,0x5
ffffffffc0200652:	57a50513          	addi	a0,a0,1402 # ffffffffc0205bc8 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc0200656:	120a0463          	beqz	s4,ffffffffc020077e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020065a:	57f5                	li	a5,-3
ffffffffc020065c:	07fa                	slli	a5,a5,0x1e
ffffffffc020065e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200662:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200664:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200668:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020066e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200672:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200676:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	8ec9                	or	a3,a3,a0
ffffffffc0200682:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200686:	1b7d                	addi	s6,s6,-1
ffffffffc0200688:	0167f7b3          	and	a5,a5,s6
ffffffffc020068c:	8dd5                	or	a1,a1,a3
ffffffffc020068e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200690:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200694:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe0de95>
ffffffffc020069a:	10f59163          	bne	a1,a5,ffffffffc020079c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020069e:	471c                	lw	a5,8(a4)
ffffffffc02006a0:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a2:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006a8:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006ac:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006bc:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c0:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c8:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006cc:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	01146433          	or	s0,s0,a7
ffffffffc02006d2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006d6:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006da:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e0:	8c49                	or	s0,s0,a0
ffffffffc02006e2:	0166f6b3          	and	a3,a3,s6
ffffffffc02006e6:	00ca6a33          	or	s4,s4,a2
ffffffffc02006ea:	0167f7b3          	and	a5,a5,s6
ffffffffc02006ee:	8c55                	or	s0,s0,a3
ffffffffc02006f0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006f4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006f6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006f8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fa:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200706:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200708:	00005917          	auipc	s2,0x5
ffffffffc020070c:	51090913          	addi	s2,s2,1296 # ffffffffc0205c18 <commands+0x130>
ffffffffc0200710:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200712:	4d91                	li	s11,4
ffffffffc0200714:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200716:	00005497          	auipc	s1,0x5
ffffffffc020071a:	4fa48493          	addi	s1,s1,1274 # ffffffffc0205c10 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020071e:	000a2703          	lw	a4,0(s4)
ffffffffc0200722:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0087569b          	srliw	a3,a4,0x8
ffffffffc020072a:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0107571b          	srliw	a4,a4,0x10
ffffffffc020073a:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073c:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200740:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200744:	8fd5                	or	a5,a5,a3
ffffffffc0200746:	00eb7733          	and	a4,s6,a4
ffffffffc020074a:	8fd9                	or	a5,a5,a4
ffffffffc020074c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020074e:	09778c63          	beq	a5,s7,ffffffffc02007e6 <dtb_init+0x1ee>
ffffffffc0200752:	00fbea63          	bltu	s7,a5,ffffffffc0200766 <dtb_init+0x16e>
ffffffffc0200756:	07a78663          	beq	a5,s10,ffffffffc02007c2 <dtb_init+0x1ca>
ffffffffc020075a:	4709                	li	a4,2
ffffffffc020075c:	00e79763          	bne	a5,a4,ffffffffc020076a <dtb_init+0x172>
ffffffffc0200760:	4c81                	li	s9,0
ffffffffc0200762:	8a56                	mv	s4,s5
ffffffffc0200764:	bf6d                	j	ffffffffc020071e <dtb_init+0x126>
ffffffffc0200766:	ffb78ee3          	beq	a5,s11,ffffffffc0200762 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020076a:	00005517          	auipc	a0,0x5
ffffffffc020076e:	52650513          	addi	a0,a0,1318 # ffffffffc0205c90 <commands+0x1a8>
ffffffffc0200772:	a27ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200776:	00005517          	auipc	a0,0x5
ffffffffc020077a:	55250513          	addi	a0,a0,1362 # ffffffffc0205cc8 <commands+0x1e0>
}
ffffffffc020077e:	7446                	ld	s0,112(sp)
ffffffffc0200780:	70e6                	ld	ra,120(sp)
ffffffffc0200782:	74a6                	ld	s1,104(sp)
ffffffffc0200784:	7906                	ld	s2,96(sp)
ffffffffc0200786:	69e6                	ld	s3,88(sp)
ffffffffc0200788:	6a46                	ld	s4,80(sp)
ffffffffc020078a:	6aa6                	ld	s5,72(sp)
ffffffffc020078c:	6b06                	ld	s6,64(sp)
ffffffffc020078e:	7be2                	ld	s7,56(sp)
ffffffffc0200790:	7c42                	ld	s8,48(sp)
ffffffffc0200792:	7ca2                	ld	s9,40(sp)
ffffffffc0200794:	7d02                	ld	s10,32(sp)
ffffffffc0200796:	6de2                	ld	s11,24(sp)
ffffffffc0200798:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020079a:	bafd                	j	ffffffffc0200198 <cprintf>
}
ffffffffc020079c:	7446                	ld	s0,112(sp)
ffffffffc020079e:	70e6                	ld	ra,120(sp)
ffffffffc02007a0:	74a6                	ld	s1,104(sp)
ffffffffc02007a2:	7906                	ld	s2,96(sp)
ffffffffc02007a4:	69e6                	ld	s3,88(sp)
ffffffffc02007a6:	6a46                	ld	s4,80(sp)
ffffffffc02007a8:	6aa6                	ld	s5,72(sp)
ffffffffc02007aa:	6b06                	ld	s6,64(sp)
ffffffffc02007ac:	7be2                	ld	s7,56(sp)
ffffffffc02007ae:	7c42                	ld	s8,48(sp)
ffffffffc02007b0:	7ca2                	ld	s9,40(sp)
ffffffffc02007b2:	7d02                	ld	s10,32(sp)
ffffffffc02007b4:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007b6:	00005517          	auipc	a0,0x5
ffffffffc02007ba:	43250513          	addi	a0,a0,1074 # ffffffffc0205be8 <commands+0x100>
}
ffffffffc02007be:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c0:	bae1                	j	ffffffffc0200198 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c2:	8556                	mv	a0,s5
ffffffffc02007c4:	7eb040ef          	jal	ra,ffffffffc02057ae <strlen>
ffffffffc02007c8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007ca:	4619                	li	a2,6
ffffffffc02007cc:	85a6                	mv	a1,s1
ffffffffc02007ce:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d0:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d2:	042050ef          	jal	ra,ffffffffc0205814 <strncmp>
ffffffffc02007d6:	e111                	bnez	a0,ffffffffc02007da <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007d8:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007da:	0a91                	addi	s5,s5,4
ffffffffc02007dc:	9ad2                	add	s5,s5,s4
ffffffffc02007de:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e2:	8a56                	mv	s4,s5
ffffffffc02007e4:	bf2d                	j	ffffffffc020071e <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007e6:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ea:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ee:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fe:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200802:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020080e:	00eaeab3          	or	s5,s5,a4
ffffffffc0200812:	00fb77b3          	and	a5,s6,a5
ffffffffc0200816:	00faeab3          	or	s5,s5,a5
ffffffffc020081a:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020081c:	000c9c63          	bnez	s9,ffffffffc0200834 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200820:	1a82                	slli	s5,s5,0x20
ffffffffc0200822:	00368793          	addi	a5,a3,3
ffffffffc0200826:	020ada93          	srli	s5,s5,0x20
ffffffffc020082a:	9abe                	add	s5,s5,a5
ffffffffc020082c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200830:	8a56                	mv	s4,s5
ffffffffc0200832:	b5f5                	j	ffffffffc020071e <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200834:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200838:	85ca                	mv	a1,s2
ffffffffc020083a:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020083c:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200840:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200844:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200848:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200850:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0087979b          	slliw	a5,a5,0x8
ffffffffc020085a:	8d59                	or	a0,a0,a4
ffffffffc020085c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200860:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200862:	1502                	slli	a0,a0,0x20
ffffffffc0200864:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200866:	9522                	add	a0,a0,s0
ffffffffc0200868:	78f040ef          	jal	ra,ffffffffc02057f6 <strcmp>
ffffffffc020086c:	66a2                	ld	a3,8(sp)
ffffffffc020086e:	f94d                	bnez	a0,ffffffffc0200820 <dtb_init+0x228>
ffffffffc0200870:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200820 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200874:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200878:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020087c:	00005517          	auipc	a0,0x5
ffffffffc0200880:	3a450513          	addi	a0,a0,932 # ffffffffc0205c20 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc0200884:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200888:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020088c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200890:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200894:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200898:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020089c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a0:	0187d693          	srli	a3,a5,0x18
ffffffffc02008a4:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008a8:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008ac:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b0:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008b4:	010f6f33          	or	t5,t5,a6
ffffffffc02008b8:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008bc:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c0:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008c4:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c8:	0186f6b3          	and	a3,a3,s8
ffffffffc02008cc:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d0:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008d4:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008d8:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008dc:	8361                	srli	a4,a4,0x18
ffffffffc02008de:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e2:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008e6:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008ea:	00cb7633          	and	a2,s6,a2
ffffffffc02008ee:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008f6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008fa:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008fe:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200902:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200906:	0088989b          	slliw	a7,a7,0x8
ffffffffc020090a:	011b78b3          	and	a7,s6,a7
ffffffffc020090e:	005eeeb3          	or	t4,t4,t0
ffffffffc0200912:	00c6e733          	or	a4,a3,a2
ffffffffc0200916:	006c6c33          	or	s8,s8,t1
ffffffffc020091a:	010b76b3          	and	a3,s6,a6
ffffffffc020091e:	00bb7b33          	and	s6,s6,a1
ffffffffc0200922:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200926:	016c6b33          	or	s6,s8,s6
ffffffffc020092a:	01146433          	or	s0,s0,a7
ffffffffc020092e:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200930:	1702                	slli	a4,a4,0x20
ffffffffc0200932:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200934:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200938:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093a:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	0167eb33          	or	s6,a5,s6
ffffffffc0200942:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200944:	855ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200948:	85a2                	mv	a1,s0
ffffffffc020094a:	00005517          	auipc	a0,0x5
ffffffffc020094e:	2f650513          	addi	a0,a0,758 # ffffffffc0205c40 <commands+0x158>
ffffffffc0200952:	847ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200956:	014b5613          	srli	a2,s6,0x14
ffffffffc020095a:	85da                	mv	a1,s6
ffffffffc020095c:	00005517          	auipc	a0,0x5
ffffffffc0200960:	2fc50513          	addi	a0,a0,764 # ffffffffc0205c58 <commands+0x170>
ffffffffc0200964:	835ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200968:	008b05b3          	add	a1,s6,s0
ffffffffc020096c:	15fd                	addi	a1,a1,-1
ffffffffc020096e:	00005517          	auipc	a0,0x5
ffffffffc0200972:	30a50513          	addi	a0,a0,778 # ffffffffc0205c78 <commands+0x190>
ffffffffc0200976:	823ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020097a:	00005517          	auipc	a0,0x5
ffffffffc020097e:	34e50513          	addi	a0,a0,846 # ffffffffc0205cc8 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200982:	000d1797          	auipc	a5,0xd1
ffffffffc0200986:	6487bf23          	sd	s0,1630(a5) # ffffffffc02d1fe0 <memory_base>
        memory_size = mem_size;
ffffffffc020098a:	000d1797          	auipc	a5,0xd1
ffffffffc020098e:	6567bf23          	sd	s6,1630(a5) # ffffffffc02d1fe8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200992:	b3f5                	j	ffffffffc020077e <dtb_init+0x186>

ffffffffc0200994 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200994:	000d1517          	auipc	a0,0xd1
ffffffffc0200998:	64c53503          	ld	a0,1612(a0) # ffffffffc02d1fe0 <memory_base>
ffffffffc020099c:	8082                	ret

ffffffffc020099e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020099e:	000d1517          	auipc	a0,0xd1
ffffffffc02009a2:	64a53503          	ld	a0,1610(a0) # ffffffffc02d1fe8 <memory_size>
ffffffffc02009a6:	8082                	ret

ffffffffc02009a8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009a8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009b4:	8082                	ret

ffffffffc02009b6 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009b6:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009ba:	00000797          	auipc	a5,0x0
ffffffffc02009be:	46278793          	addi	a5,a5,1122 # ffffffffc0200e1c <__alltraps>
ffffffffc02009c2:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009c6:	000407b7          	lui	a5,0x40
ffffffffc02009ca:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009ce:	8082                	ret

ffffffffc02009d0 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d0:	610c                	ld	a1,0(a0)
{
ffffffffc02009d2:	1141                	addi	sp,sp,-16
ffffffffc02009d4:	e022                	sd	s0,0(sp)
ffffffffc02009d6:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	30850513          	addi	a0,a0,776 # ffffffffc0205ce0 <commands+0x1f8>
{
ffffffffc02009e0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e2:	fb6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009e6:	640c                	ld	a1,8(s0)
ffffffffc02009e8:	00005517          	auipc	a0,0x5
ffffffffc02009ec:	31050513          	addi	a0,a0,784 # ffffffffc0205cf8 <commands+0x210>
ffffffffc02009f0:	fa8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009f4:	680c                	ld	a1,16(s0)
ffffffffc02009f6:	00005517          	auipc	a0,0x5
ffffffffc02009fa:	31a50513          	addi	a0,a0,794 # ffffffffc0205d10 <commands+0x228>
ffffffffc02009fe:	f9aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a02:	6c0c                	ld	a1,24(s0)
ffffffffc0200a04:	00005517          	auipc	a0,0x5
ffffffffc0200a08:	32450513          	addi	a0,a0,804 # ffffffffc0205d28 <commands+0x240>
ffffffffc0200a0c:	f8cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a10:	700c                	ld	a1,32(s0)
ffffffffc0200a12:	00005517          	auipc	a0,0x5
ffffffffc0200a16:	32e50513          	addi	a0,a0,814 # ffffffffc0205d40 <commands+0x258>
ffffffffc0200a1a:	f7eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a1e:	740c                	ld	a1,40(s0)
ffffffffc0200a20:	00005517          	auipc	a0,0x5
ffffffffc0200a24:	33850513          	addi	a0,a0,824 # ffffffffc0205d58 <commands+0x270>
ffffffffc0200a28:	f70ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a2c:	780c                	ld	a1,48(s0)
ffffffffc0200a2e:	00005517          	auipc	a0,0x5
ffffffffc0200a32:	34250513          	addi	a0,a0,834 # ffffffffc0205d70 <commands+0x288>
ffffffffc0200a36:	f62ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a3a:	7c0c                	ld	a1,56(s0)
ffffffffc0200a3c:	00005517          	auipc	a0,0x5
ffffffffc0200a40:	34c50513          	addi	a0,a0,844 # ffffffffc0205d88 <commands+0x2a0>
ffffffffc0200a44:	f54ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a48:	602c                	ld	a1,64(s0)
ffffffffc0200a4a:	00005517          	auipc	a0,0x5
ffffffffc0200a4e:	35650513          	addi	a0,a0,854 # ffffffffc0205da0 <commands+0x2b8>
ffffffffc0200a52:	f46ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a56:	642c                	ld	a1,72(s0)
ffffffffc0200a58:	00005517          	auipc	a0,0x5
ffffffffc0200a5c:	36050513          	addi	a0,a0,864 # ffffffffc0205db8 <commands+0x2d0>
ffffffffc0200a60:	f38ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a64:	682c                	ld	a1,80(s0)
ffffffffc0200a66:	00005517          	auipc	a0,0x5
ffffffffc0200a6a:	36a50513          	addi	a0,a0,874 # ffffffffc0205dd0 <commands+0x2e8>
ffffffffc0200a6e:	f2aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a72:	6c2c                	ld	a1,88(s0)
ffffffffc0200a74:	00005517          	auipc	a0,0x5
ffffffffc0200a78:	37450513          	addi	a0,a0,884 # ffffffffc0205de8 <commands+0x300>
ffffffffc0200a7c:	f1cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a80:	702c                	ld	a1,96(s0)
ffffffffc0200a82:	00005517          	auipc	a0,0x5
ffffffffc0200a86:	37e50513          	addi	a0,a0,894 # ffffffffc0205e00 <commands+0x318>
ffffffffc0200a8a:	f0eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a8e:	742c                	ld	a1,104(s0)
ffffffffc0200a90:	00005517          	auipc	a0,0x5
ffffffffc0200a94:	38850513          	addi	a0,a0,904 # ffffffffc0205e18 <commands+0x330>
ffffffffc0200a98:	f00ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a9c:	782c                	ld	a1,112(s0)
ffffffffc0200a9e:	00005517          	auipc	a0,0x5
ffffffffc0200aa2:	39250513          	addi	a0,a0,914 # ffffffffc0205e30 <commands+0x348>
ffffffffc0200aa6:	ef2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200aaa:	7c2c                	ld	a1,120(s0)
ffffffffc0200aac:	00005517          	auipc	a0,0x5
ffffffffc0200ab0:	39c50513          	addi	a0,a0,924 # ffffffffc0205e48 <commands+0x360>
ffffffffc0200ab4:	ee4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200ab8:	604c                	ld	a1,128(s0)
ffffffffc0200aba:	00005517          	auipc	a0,0x5
ffffffffc0200abe:	3a650513          	addi	a0,a0,934 # ffffffffc0205e60 <commands+0x378>
ffffffffc0200ac2:	ed6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200ac6:	644c                	ld	a1,136(s0)
ffffffffc0200ac8:	00005517          	auipc	a0,0x5
ffffffffc0200acc:	3b050513          	addi	a0,a0,944 # ffffffffc0205e78 <commands+0x390>
ffffffffc0200ad0:	ec8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ad4:	684c                	ld	a1,144(s0)
ffffffffc0200ad6:	00005517          	auipc	a0,0x5
ffffffffc0200ada:	3ba50513          	addi	a0,a0,954 # ffffffffc0205e90 <commands+0x3a8>
ffffffffc0200ade:	ebaff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae2:	6c4c                	ld	a1,152(s0)
ffffffffc0200ae4:	00005517          	auipc	a0,0x5
ffffffffc0200ae8:	3c450513          	addi	a0,a0,964 # ffffffffc0205ea8 <commands+0x3c0>
ffffffffc0200aec:	eacff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af0:	704c                	ld	a1,160(s0)
ffffffffc0200af2:	00005517          	auipc	a0,0x5
ffffffffc0200af6:	3ce50513          	addi	a0,a0,974 # ffffffffc0205ec0 <commands+0x3d8>
ffffffffc0200afa:	e9eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200afe:	744c                	ld	a1,168(s0)
ffffffffc0200b00:	00005517          	auipc	a0,0x5
ffffffffc0200b04:	3d850513          	addi	a0,a0,984 # ffffffffc0205ed8 <commands+0x3f0>
ffffffffc0200b08:	e90ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b0c:	784c                	ld	a1,176(s0)
ffffffffc0200b0e:	00005517          	auipc	a0,0x5
ffffffffc0200b12:	3e250513          	addi	a0,a0,994 # ffffffffc0205ef0 <commands+0x408>
ffffffffc0200b16:	e82ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b1a:	7c4c                	ld	a1,184(s0)
ffffffffc0200b1c:	00005517          	auipc	a0,0x5
ffffffffc0200b20:	3ec50513          	addi	a0,a0,1004 # ffffffffc0205f08 <commands+0x420>
ffffffffc0200b24:	e74ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b28:	606c                	ld	a1,192(s0)
ffffffffc0200b2a:	00005517          	auipc	a0,0x5
ffffffffc0200b2e:	3f650513          	addi	a0,a0,1014 # ffffffffc0205f20 <commands+0x438>
ffffffffc0200b32:	e66ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b36:	646c                	ld	a1,200(s0)
ffffffffc0200b38:	00005517          	auipc	a0,0x5
ffffffffc0200b3c:	40050513          	addi	a0,a0,1024 # ffffffffc0205f38 <commands+0x450>
ffffffffc0200b40:	e58ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b44:	686c                	ld	a1,208(s0)
ffffffffc0200b46:	00005517          	auipc	a0,0x5
ffffffffc0200b4a:	40a50513          	addi	a0,a0,1034 # ffffffffc0205f50 <commands+0x468>
ffffffffc0200b4e:	e4aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b52:	6c6c                	ld	a1,216(s0)
ffffffffc0200b54:	00005517          	auipc	a0,0x5
ffffffffc0200b58:	41450513          	addi	a0,a0,1044 # ffffffffc0205f68 <commands+0x480>
ffffffffc0200b5c:	e3cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b60:	706c                	ld	a1,224(s0)
ffffffffc0200b62:	00005517          	auipc	a0,0x5
ffffffffc0200b66:	41e50513          	addi	a0,a0,1054 # ffffffffc0205f80 <commands+0x498>
ffffffffc0200b6a:	e2eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b6e:	746c                	ld	a1,232(s0)
ffffffffc0200b70:	00005517          	auipc	a0,0x5
ffffffffc0200b74:	42850513          	addi	a0,a0,1064 # ffffffffc0205f98 <commands+0x4b0>
ffffffffc0200b78:	e20ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b7c:	786c                	ld	a1,240(s0)
ffffffffc0200b7e:	00005517          	auipc	a0,0x5
ffffffffc0200b82:	43250513          	addi	a0,a0,1074 # ffffffffc0205fb0 <commands+0x4c8>
ffffffffc0200b86:	e12ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b8a:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b8c:	6402                	ld	s0,0(sp)
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	00005517          	auipc	a0,0x5
ffffffffc0200b94:	43850513          	addi	a0,a0,1080 # ffffffffc0205fc8 <commands+0x4e0>
}
ffffffffc0200b98:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b9a:	dfeff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200b9e <print_trapframe>:
{
ffffffffc0200b9e:	1141                	addi	sp,sp,-16
ffffffffc0200ba0:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba2:	85aa                	mv	a1,a0
{
ffffffffc0200ba4:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba6:	00005517          	auipc	a0,0x5
ffffffffc0200baa:	43a50513          	addi	a0,a0,1082 # ffffffffc0205fe0 <commands+0x4f8>
{
ffffffffc0200bae:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb0:	de8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bb4:	8522                	mv	a0,s0
ffffffffc0200bb6:	e1bff0ef          	jal	ra,ffffffffc02009d0 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bba:	10043583          	ld	a1,256(s0)
ffffffffc0200bbe:	00005517          	auipc	a0,0x5
ffffffffc0200bc2:	43a50513          	addi	a0,a0,1082 # ffffffffc0205ff8 <commands+0x510>
ffffffffc0200bc6:	dd2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bca:	10843583          	ld	a1,264(s0)
ffffffffc0200bce:	00005517          	auipc	a0,0x5
ffffffffc0200bd2:	44250513          	addi	a0,a0,1090 # ffffffffc0206010 <commands+0x528>
ffffffffc0200bd6:	dc2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200bda:	11043583          	ld	a1,272(s0)
ffffffffc0200bde:	00005517          	auipc	a0,0x5
ffffffffc0200be2:	44a50513          	addi	a0,a0,1098 # ffffffffc0206028 <commands+0x540>
ffffffffc0200be6:	db2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bea:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bee:	6402                	ld	s0,0(sp)
ffffffffc0200bf0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf2:	00005517          	auipc	a0,0x5
ffffffffc0200bf6:	44650513          	addi	a0,a0,1094 # ffffffffc0206038 <commands+0x550>
}
ffffffffc0200bfa:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bfc:	d9cff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200c00 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c00:	11853783          	ld	a5,280(a0)
ffffffffc0200c04:	472d                	li	a4,11
ffffffffc0200c06:	0786                	slli	a5,a5,0x1
ffffffffc0200c08:	8385                	srli	a5,a5,0x1
ffffffffc0200c0a:	08f76363          	bltu	a4,a5,ffffffffc0200c90 <interrupt_handler+0x90>
ffffffffc0200c0e:	00005717          	auipc	a4,0x5
ffffffffc0200c12:	4f270713          	addi	a4,a4,1266 # ffffffffc0206100 <commands+0x618>
ffffffffc0200c16:	078a                	slli	a5,a5,0x2
ffffffffc0200c18:	97ba                	add	a5,a5,a4
ffffffffc0200c1a:	439c                	lw	a5,0(a5)
ffffffffc0200c1c:	97ba                	add	a5,a5,a4
ffffffffc0200c1e:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c20:	00005517          	auipc	a0,0x5
ffffffffc0200c24:	49050513          	addi	a0,a0,1168 # ffffffffc02060b0 <commands+0x5c8>
ffffffffc0200c28:	d70ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c2c:	00005517          	auipc	a0,0x5
ffffffffc0200c30:	46450513          	addi	a0,a0,1124 # ffffffffc0206090 <commands+0x5a8>
ffffffffc0200c34:	d64ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c38:	00005517          	auipc	a0,0x5
ffffffffc0200c3c:	41850513          	addi	a0,a0,1048 # ffffffffc0206050 <commands+0x568>
ffffffffc0200c40:	d58ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c44:	00005517          	auipc	a0,0x5
ffffffffc0200c48:	42c50513          	addi	a0,a0,1068 # ffffffffc0206070 <commands+0x588>
ffffffffc0200c4c:	d4cff06f          	j	ffffffffc0200198 <cprintf>
{
ffffffffc0200c50:	1141                	addi	sp,sp,-16
ffffffffc0200c52:	e406                	sd	ra,8(sp)
         *
         * 注意：ucore 的调度发生在“回到用户态之前”，当 need_resched 被置位后，trap 返回路径会调用 schedule()。
         */
        // lab6:2310675 (update LAB3 steps)
        // lab6:2310675 重新预约下一次时钟中断，保证周期性触发
        clock_set_next_event();
ffffffffc0200c54:	91bff0ef          	jal	ra,ffffffffc020056e <clock_set_next_event>
        // lab6:2310675 全局节拍数自增
        ticks++;
ffffffffc0200c58:	000d1797          	auipc	a5,0xd1
ffffffffc0200c5c:	38078793          	addi	a5,a5,896 # ffffffffc02d1fd8 <ticks>
ffffffffc0200c60:	6398                	ld	a4,0(a5)
ffffffffc0200c62:	0705                	addi	a4,a4,1
ffffffffc0200c64:	e398                	sd	a4,0(a5)
        // lab6:2310675 每累计 TICK_NUM 次输出一次 ticks
        if (ticks % TICK_NUM == 0)
ffffffffc0200c66:	639c                	ld	a5,0(a5)
ffffffffc0200c68:	06400713          	li	a4,100
ffffffffc0200c6c:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c70:	c785                	beqz	a5,ffffffffc0200c98 <interrupt_handler+0x98>
        {
            print_ticks();
        }
        // lab6:2310675 在时钟中断中驱动调度器时间片逻辑
        if (current != NULL)
ffffffffc0200c72:	000d1517          	auipc	a0,0xd1
ffffffffc0200c76:	3b653503          	ld	a0,950(a0) # ffffffffc02d2028 <current>
ffffffffc0200c7a:	cd01                	beqz	a0,ffffffffc0200c92 <interrupt_handler+0x92>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c7c:	60a2                	ld	ra,8(sp)
ffffffffc0200c7e:	0141                	addi	sp,sp,16
            sched_class_proc_tick(current);
ffffffffc0200c80:	43e0406f          	j	ffffffffc02050be <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c84:	00005517          	auipc	a0,0x5
ffffffffc0200c88:	45c50513          	addi	a0,a0,1116 # ffffffffc02060e0 <commands+0x5f8>
ffffffffc0200c8c:	d0cff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200c90:	b739                	j	ffffffffc0200b9e <print_trapframe>
}
ffffffffc0200c92:	60a2                	ld	ra,8(sp)
ffffffffc0200c94:	0141                	addi	sp,sp,16
ffffffffc0200c96:	8082                	ret
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c98:	06400593          	li	a1,100
ffffffffc0200c9c:	00005517          	auipc	a0,0x5
ffffffffc0200ca0:	43450513          	addi	a0,a0,1076 # ffffffffc02060d0 <commands+0x5e8>
ffffffffc0200ca4:	cf4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0200ca8:	b7e9                	j	ffffffffc0200c72 <interrupt_handler+0x72>

ffffffffc0200caa <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200caa:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cae:	1141                	addi	sp,sp,-16
ffffffffc0200cb0:	e022                	sd	s0,0(sp)
ffffffffc0200cb2:	e406                	sd	ra,8(sp)
ffffffffc0200cb4:	473d                	li	a4,15
ffffffffc0200cb6:	842a                	mv	s0,a0
ffffffffc0200cb8:	0af76b63          	bltu	a4,a5,ffffffffc0200d6e <exception_handler+0xc4>
ffffffffc0200cbc:	00005717          	auipc	a4,0x5
ffffffffc0200cc0:	60470713          	addi	a4,a4,1540 # ffffffffc02062c0 <commands+0x7d8>
ffffffffc0200cc4:	078a                	slli	a5,a5,0x2
ffffffffc0200cc6:	97ba                	add	a5,a5,a4
ffffffffc0200cc8:	439c                	lw	a5,0(a5)
ffffffffc0200cca:	97ba                	add	a5,a5,a4
ffffffffc0200ccc:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cce:	00005517          	auipc	a0,0x5
ffffffffc0200cd2:	54a50513          	addi	a0,a0,1354 # ffffffffc0206218 <commands+0x730>
ffffffffc0200cd6:	cc2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200cda:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cde:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200ce0:	0791                	addi	a5,a5,4
ffffffffc0200ce2:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200ce6:	6402                	ld	s0,0(sp)
ffffffffc0200ce8:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200cea:	63e0406f          	j	ffffffffc0205328 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cee:	00005517          	auipc	a0,0x5
ffffffffc0200cf2:	54a50513          	addi	a0,a0,1354 # ffffffffc0206238 <commands+0x750>
}
ffffffffc0200cf6:	6402                	ld	s0,0(sp)
ffffffffc0200cf8:	60a2                	ld	ra,8(sp)
ffffffffc0200cfa:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200cfc:	c9cff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d00:	00005517          	auipc	a0,0x5
ffffffffc0200d04:	55850513          	addi	a0,a0,1368 # ffffffffc0206258 <commands+0x770>
ffffffffc0200d08:	b7fd                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d0a:	00005517          	auipc	a0,0x5
ffffffffc0200d0e:	56e50513          	addi	a0,a0,1390 # ffffffffc0206278 <commands+0x790>
ffffffffc0200d12:	b7d5                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200d14:	00005517          	auipc	a0,0x5
ffffffffc0200d18:	57c50513          	addi	a0,a0,1404 # ffffffffc0206290 <commands+0x7a8>
ffffffffc0200d1c:	bfe9                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d1e:	00005517          	auipc	a0,0x5
ffffffffc0200d22:	58a50513          	addi	a0,a0,1418 # ffffffffc02062a8 <commands+0x7c0>
ffffffffc0200d26:	bfc1                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d28:	00005517          	auipc	a0,0x5
ffffffffc0200d2c:	40850513          	addi	a0,a0,1032 # ffffffffc0206130 <commands+0x648>
ffffffffc0200d30:	b7d9                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d32:	00005517          	auipc	a0,0x5
ffffffffc0200d36:	41e50513          	addi	a0,a0,1054 # ffffffffc0206150 <commands+0x668>
ffffffffc0200d3a:	bf75                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d3c:	00005517          	auipc	a0,0x5
ffffffffc0200d40:	43450513          	addi	a0,a0,1076 # ffffffffc0206170 <commands+0x688>
ffffffffc0200d44:	bf4d                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d46:	00005517          	auipc	a0,0x5
ffffffffc0200d4a:	44250513          	addi	a0,a0,1090 # ffffffffc0206188 <commands+0x6a0>
ffffffffc0200d4e:	b765                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        cprintf("Load address misaligned\n");
ffffffffc0200d50:	00005517          	auipc	a0,0x5
ffffffffc0200d54:	44850513          	addi	a0,a0,1096 # ffffffffc0206198 <commands+0x6b0>
ffffffffc0200d58:	bf79                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d5a:	00005517          	auipc	a0,0x5
ffffffffc0200d5e:	45e50513          	addi	a0,a0,1118 # ffffffffc02061b8 <commands+0x6d0>
ffffffffc0200d62:	bf51                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d64:	00005517          	auipc	a0,0x5
ffffffffc0200d68:	49c50513          	addi	a0,a0,1180 # ffffffffc0206200 <commands+0x718>
ffffffffc0200d6c:	b769                	j	ffffffffc0200cf6 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d6e:	8522                	mv	a0,s0
}
ffffffffc0200d70:	6402                	ld	s0,0(sp)
ffffffffc0200d72:	60a2                	ld	ra,8(sp)
ffffffffc0200d74:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d76:	b525                	j	ffffffffc0200b9e <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d78:	00005617          	auipc	a2,0x5
ffffffffc0200d7c:	45860613          	addi	a2,a2,1112 # ffffffffc02061d0 <commands+0x6e8>
ffffffffc0200d80:	0ca00593          	li	a1,202
ffffffffc0200d84:	00005517          	auipc	a0,0x5
ffffffffc0200d88:	46450513          	addi	a0,a0,1124 # ffffffffc02061e8 <commands+0x700>
ffffffffc0200d8c:	f06ff0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0200d90 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200d90:	1101                	addi	sp,sp,-32
ffffffffc0200d92:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d94:	000d1417          	auipc	s0,0xd1
ffffffffc0200d98:	29440413          	addi	s0,s0,660 # ffffffffc02d2028 <current>
ffffffffc0200d9c:	6018                	ld	a4,0(s0)
{
ffffffffc0200d9e:	ec06                	sd	ra,24(sp)
ffffffffc0200da0:	e426                	sd	s1,8(sp)
ffffffffc0200da2:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200da4:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200da8:	cf1d                	beqz	a4,ffffffffc0200de6 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200daa:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200dae:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200db2:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200db4:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200db8:	0206c463          	bltz	a3,ffffffffc0200de0 <trap+0x50>
        exception_handler(tf);
ffffffffc0200dbc:	eefff0ef          	jal	ra,ffffffffc0200caa <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200dc0:	601c                	ld	a5,0(s0)
ffffffffc0200dc2:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200dc6:	e499                	bnez	s1,ffffffffc0200dd4 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200dc8:	0b07a703          	lw	a4,176(a5)
ffffffffc0200dcc:	8b05                	andi	a4,a4,1
ffffffffc0200dce:	e329                	bnez	a4,ffffffffc0200e10 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200dd0:	6f9c                	ld	a5,24(a5)
ffffffffc0200dd2:	eb85                	bnez	a5,ffffffffc0200e02 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200dd4:	60e2                	ld	ra,24(sp)
ffffffffc0200dd6:	6442                	ld	s0,16(sp)
ffffffffc0200dd8:	64a2                	ld	s1,8(sp)
ffffffffc0200dda:	6902                	ld	s2,0(sp)
ffffffffc0200ddc:	6105                	addi	sp,sp,32
ffffffffc0200dde:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200de0:	e21ff0ef          	jal	ra,ffffffffc0200c00 <interrupt_handler>
ffffffffc0200de4:	bff1                	j	ffffffffc0200dc0 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200de6:	0006c863          	bltz	a3,ffffffffc0200df6 <trap+0x66>
}
ffffffffc0200dea:	6442                	ld	s0,16(sp)
ffffffffc0200dec:	60e2                	ld	ra,24(sp)
ffffffffc0200dee:	64a2                	ld	s1,8(sp)
ffffffffc0200df0:	6902                	ld	s2,0(sp)
ffffffffc0200df2:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200df4:	bd5d                	j	ffffffffc0200caa <exception_handler>
}
ffffffffc0200df6:	6442                	ld	s0,16(sp)
ffffffffc0200df8:	60e2                	ld	ra,24(sp)
ffffffffc0200dfa:	64a2                	ld	s1,8(sp)
ffffffffc0200dfc:	6902                	ld	s2,0(sp)
ffffffffc0200dfe:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e00:	b501                	j	ffffffffc0200c00 <interrupt_handler>
}
ffffffffc0200e02:	6442                	ld	s0,16(sp)
ffffffffc0200e04:	60e2                	ld	ra,24(sp)
ffffffffc0200e06:	64a2                	ld	s1,8(sp)
ffffffffc0200e08:	6902                	ld	s2,0(sp)
ffffffffc0200e0a:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e0c:	3de0406f          	j	ffffffffc02051ea <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e10:	555d                	li	a0,-9
ffffffffc0200e12:	4ba030ef          	jal	ra,ffffffffc02042cc <do_exit>
            if (current->need_resched)
ffffffffc0200e16:	601c                	ld	a5,0(s0)
ffffffffc0200e18:	bf65                	j	ffffffffc0200dd0 <trap+0x40>
	...

ffffffffc0200e1c <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e1c:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e20:	00011463          	bnez	sp,ffffffffc0200e28 <__alltraps+0xc>
ffffffffc0200e24:	14002173          	csrr	sp,sscratch
ffffffffc0200e28:	712d                	addi	sp,sp,-288
ffffffffc0200e2a:	e002                	sd	zero,0(sp)
ffffffffc0200e2c:	e406                	sd	ra,8(sp)
ffffffffc0200e2e:	ec0e                	sd	gp,24(sp)
ffffffffc0200e30:	f012                	sd	tp,32(sp)
ffffffffc0200e32:	f416                	sd	t0,40(sp)
ffffffffc0200e34:	f81a                	sd	t1,48(sp)
ffffffffc0200e36:	fc1e                	sd	t2,56(sp)
ffffffffc0200e38:	e0a2                	sd	s0,64(sp)
ffffffffc0200e3a:	e4a6                	sd	s1,72(sp)
ffffffffc0200e3c:	e8aa                	sd	a0,80(sp)
ffffffffc0200e3e:	ecae                	sd	a1,88(sp)
ffffffffc0200e40:	f0b2                	sd	a2,96(sp)
ffffffffc0200e42:	f4b6                	sd	a3,104(sp)
ffffffffc0200e44:	f8ba                	sd	a4,112(sp)
ffffffffc0200e46:	fcbe                	sd	a5,120(sp)
ffffffffc0200e48:	e142                	sd	a6,128(sp)
ffffffffc0200e4a:	e546                	sd	a7,136(sp)
ffffffffc0200e4c:	e94a                	sd	s2,144(sp)
ffffffffc0200e4e:	ed4e                	sd	s3,152(sp)
ffffffffc0200e50:	f152                	sd	s4,160(sp)
ffffffffc0200e52:	f556                	sd	s5,168(sp)
ffffffffc0200e54:	f95a                	sd	s6,176(sp)
ffffffffc0200e56:	fd5e                	sd	s7,184(sp)
ffffffffc0200e58:	e1e2                	sd	s8,192(sp)
ffffffffc0200e5a:	e5e6                	sd	s9,200(sp)
ffffffffc0200e5c:	e9ea                	sd	s10,208(sp)
ffffffffc0200e5e:	edee                	sd	s11,216(sp)
ffffffffc0200e60:	f1f2                	sd	t3,224(sp)
ffffffffc0200e62:	f5f6                	sd	t4,232(sp)
ffffffffc0200e64:	f9fa                	sd	t5,240(sp)
ffffffffc0200e66:	fdfe                	sd	t6,248(sp)
ffffffffc0200e68:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e6c:	100024f3          	csrr	s1,sstatus
ffffffffc0200e70:	14102973          	csrr	s2,sepc
ffffffffc0200e74:	143029f3          	csrr	s3,stval
ffffffffc0200e78:	14202a73          	csrr	s4,scause
ffffffffc0200e7c:	e822                	sd	s0,16(sp)
ffffffffc0200e7e:	e226                	sd	s1,256(sp)
ffffffffc0200e80:	e64a                	sd	s2,264(sp)
ffffffffc0200e82:	ea4e                	sd	s3,272(sp)
ffffffffc0200e84:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e86:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e88:	f09ff0ef          	jal	ra,ffffffffc0200d90 <trap>

ffffffffc0200e8c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e8c:	6492                	ld	s1,256(sp)
ffffffffc0200e8e:	6932                	ld	s2,264(sp)
ffffffffc0200e90:	1004f413          	andi	s0,s1,256
ffffffffc0200e94:	e401                	bnez	s0,ffffffffc0200e9c <__trapret+0x10>
ffffffffc0200e96:	1200                	addi	s0,sp,288
ffffffffc0200e98:	14041073          	csrw	sscratch,s0
ffffffffc0200e9c:	10049073          	csrw	sstatus,s1
ffffffffc0200ea0:	14191073          	csrw	sepc,s2
ffffffffc0200ea4:	60a2                	ld	ra,8(sp)
ffffffffc0200ea6:	61e2                	ld	gp,24(sp)
ffffffffc0200ea8:	7202                	ld	tp,32(sp)
ffffffffc0200eaa:	72a2                	ld	t0,40(sp)
ffffffffc0200eac:	7342                	ld	t1,48(sp)
ffffffffc0200eae:	73e2                	ld	t2,56(sp)
ffffffffc0200eb0:	6406                	ld	s0,64(sp)
ffffffffc0200eb2:	64a6                	ld	s1,72(sp)
ffffffffc0200eb4:	6546                	ld	a0,80(sp)
ffffffffc0200eb6:	65e6                	ld	a1,88(sp)
ffffffffc0200eb8:	7606                	ld	a2,96(sp)
ffffffffc0200eba:	76a6                	ld	a3,104(sp)
ffffffffc0200ebc:	7746                	ld	a4,112(sp)
ffffffffc0200ebe:	77e6                	ld	a5,120(sp)
ffffffffc0200ec0:	680a                	ld	a6,128(sp)
ffffffffc0200ec2:	68aa                	ld	a7,136(sp)
ffffffffc0200ec4:	694a                	ld	s2,144(sp)
ffffffffc0200ec6:	69ea                	ld	s3,152(sp)
ffffffffc0200ec8:	7a0a                	ld	s4,160(sp)
ffffffffc0200eca:	7aaa                	ld	s5,168(sp)
ffffffffc0200ecc:	7b4a                	ld	s6,176(sp)
ffffffffc0200ece:	7bea                	ld	s7,184(sp)
ffffffffc0200ed0:	6c0e                	ld	s8,192(sp)
ffffffffc0200ed2:	6cae                	ld	s9,200(sp)
ffffffffc0200ed4:	6d4e                	ld	s10,208(sp)
ffffffffc0200ed6:	6dee                	ld	s11,216(sp)
ffffffffc0200ed8:	7e0e                	ld	t3,224(sp)
ffffffffc0200eda:	7eae                	ld	t4,232(sp)
ffffffffc0200edc:	7f4e                	ld	t5,240(sp)
ffffffffc0200ede:	7fee                	ld	t6,248(sp)
ffffffffc0200ee0:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200ee2:	10200073          	sret

ffffffffc0200ee6 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200ee6:	812a                	mv	sp,a0
ffffffffc0200ee8:	b755                	j	ffffffffc0200e8c <__trapret>

ffffffffc0200eea <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200eea:	000cd797          	auipc	a5,0xcd
ffffffffc0200eee:	08e78793          	addi	a5,a5,142 # ffffffffc02cdf78 <free_area>
ffffffffc0200ef2:	e79c                	sd	a5,8(a5)
ffffffffc0200ef4:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200ef6:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200efa:	8082                	ret

ffffffffc0200efc <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200efc:	000cd517          	auipc	a0,0xcd
ffffffffc0200f00:	08c56503          	lwu	a0,140(a0) # ffffffffc02cdf88 <free_area+0x10>
ffffffffc0200f04:	8082                	ret

ffffffffc0200f06 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200f06:	715d                	addi	sp,sp,-80
ffffffffc0200f08:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f0a:	000cd417          	auipc	s0,0xcd
ffffffffc0200f0e:	06e40413          	addi	s0,s0,110 # ffffffffc02cdf78 <free_area>
ffffffffc0200f12:	641c                	ld	a5,8(s0)
ffffffffc0200f14:	e486                	sd	ra,72(sp)
ffffffffc0200f16:	fc26                	sd	s1,56(sp)
ffffffffc0200f18:	f84a                	sd	s2,48(sp)
ffffffffc0200f1a:	f44e                	sd	s3,40(sp)
ffffffffc0200f1c:	f052                	sd	s4,32(sp)
ffffffffc0200f1e:	ec56                	sd	s5,24(sp)
ffffffffc0200f20:	e85a                	sd	s6,16(sp)
ffffffffc0200f22:	e45e                	sd	s7,8(sp)
ffffffffc0200f24:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f26:	2a878d63          	beq	a5,s0,ffffffffc02011e0 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200f2a:	4481                	li	s1,0
ffffffffc0200f2c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200f2e:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200f32:	8b09                	andi	a4,a4,2
ffffffffc0200f34:	2a070a63          	beqz	a4,ffffffffc02011e8 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0200f38:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f3c:	679c                	ld	a5,8(a5)
ffffffffc0200f3e:	2905                	addiw	s2,s2,1
ffffffffc0200f40:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f42:	fe8796e3          	bne	a5,s0,ffffffffc0200f2e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200f46:	89a6                	mv	s3,s1
ffffffffc0200f48:	6df000ef          	jal	ra,ffffffffc0201e26 <nr_free_pages>
ffffffffc0200f4c:	6f351e63          	bne	a0,s3,ffffffffc0201648 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f50:	4505                	li	a0,1
ffffffffc0200f52:	657000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc0200f56:	8aaa                	mv	s5,a0
ffffffffc0200f58:	42050863          	beqz	a0,ffffffffc0201388 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f5c:	4505                	li	a0,1
ffffffffc0200f5e:	64b000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc0200f62:	89aa                	mv	s3,a0
ffffffffc0200f64:	70050263          	beqz	a0,ffffffffc0201668 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f68:	4505                	li	a0,1
ffffffffc0200f6a:	63f000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc0200f6e:	8a2a                	mv	s4,a0
ffffffffc0200f70:	48050c63          	beqz	a0,ffffffffc0201408 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f74:	293a8a63          	beq	s5,s3,ffffffffc0201208 <default_check+0x302>
ffffffffc0200f78:	28aa8863          	beq	s5,a0,ffffffffc0201208 <default_check+0x302>
ffffffffc0200f7c:	28a98663          	beq	s3,a0,ffffffffc0201208 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f80:	000aa783          	lw	a5,0(s5)
ffffffffc0200f84:	2a079263          	bnez	a5,ffffffffc0201228 <default_check+0x322>
ffffffffc0200f88:	0009a783          	lw	a5,0(s3)
ffffffffc0200f8c:	28079e63          	bnez	a5,ffffffffc0201228 <default_check+0x322>
ffffffffc0200f90:	411c                	lw	a5,0(a0)
ffffffffc0200f92:	28079b63          	bnez	a5,ffffffffc0201228 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200f96:	000d1797          	auipc	a5,0xd1
ffffffffc0200f9a:	07a7b783          	ld	a5,122(a5) # ffffffffc02d2010 <pages>
ffffffffc0200f9e:	40fa8733          	sub	a4,s5,a5
ffffffffc0200fa2:	00007617          	auipc	a2,0x7
ffffffffc0200fa6:	1f663603          	ld	a2,502(a2) # ffffffffc0208198 <nbase>
ffffffffc0200faa:	8719                	srai	a4,a4,0x6
ffffffffc0200fac:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200fae:	000d1697          	auipc	a3,0xd1
ffffffffc0200fb2:	05a6b683          	ld	a3,90(a3) # ffffffffc02d2008 <npage>
ffffffffc0200fb6:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fb8:	0732                	slli	a4,a4,0xc
ffffffffc0200fba:	28d77763          	bgeu	a4,a3,ffffffffc0201248 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200fbe:	40f98733          	sub	a4,s3,a5
ffffffffc0200fc2:	8719                	srai	a4,a4,0x6
ffffffffc0200fc4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fc6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200fc8:	4cd77063          	bgeu	a4,a3,ffffffffc0201488 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200fcc:	40f507b3          	sub	a5,a0,a5
ffffffffc0200fd0:	8799                	srai	a5,a5,0x6
ffffffffc0200fd2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fd4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200fd6:	30d7f963          	bgeu	a5,a3,ffffffffc02012e8 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200fda:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fdc:	00043c03          	ld	s8,0(s0)
ffffffffc0200fe0:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200fe4:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200fe8:	e400                	sd	s0,8(s0)
ffffffffc0200fea:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200fec:	000cd797          	auipc	a5,0xcd
ffffffffc0200ff0:	f807ae23          	sw	zero,-100(a5) # ffffffffc02cdf88 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200ff4:	5b5000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc0200ff8:	2c051863          	bnez	a0,ffffffffc02012c8 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200ffc:	4585                	li	a1,1
ffffffffc0200ffe:	8556                	mv	a0,s5
ffffffffc0201000:	5e7000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    free_page(p1);
ffffffffc0201004:	4585                	li	a1,1
ffffffffc0201006:	854e                	mv	a0,s3
ffffffffc0201008:	5df000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    free_page(p2);
ffffffffc020100c:	4585                	li	a1,1
ffffffffc020100e:	8552                	mv	a0,s4
ffffffffc0201010:	5d7000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    assert(nr_free == 3);
ffffffffc0201014:	4818                	lw	a4,16(s0)
ffffffffc0201016:	478d                	li	a5,3
ffffffffc0201018:	28f71863          	bne	a4,a5,ffffffffc02012a8 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020101c:	4505                	li	a0,1
ffffffffc020101e:	58b000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc0201022:	89aa                	mv	s3,a0
ffffffffc0201024:	26050263          	beqz	a0,ffffffffc0201288 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201028:	4505                	li	a0,1
ffffffffc020102a:	57f000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc020102e:	8aaa                	mv	s5,a0
ffffffffc0201030:	3a050c63          	beqz	a0,ffffffffc02013e8 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201034:	4505                	li	a0,1
ffffffffc0201036:	573000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc020103a:	8a2a                	mv	s4,a0
ffffffffc020103c:	38050663          	beqz	a0,ffffffffc02013c8 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201040:	4505                	li	a0,1
ffffffffc0201042:	567000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc0201046:	36051163          	bnez	a0,ffffffffc02013a8 <default_check+0x4a2>
    free_page(p0);
ffffffffc020104a:	4585                	li	a1,1
ffffffffc020104c:	854e                	mv	a0,s3
ffffffffc020104e:	599000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201052:	641c                	ld	a5,8(s0)
ffffffffc0201054:	20878a63          	beq	a5,s0,ffffffffc0201268 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201058:	4505                	li	a0,1
ffffffffc020105a:	54f000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc020105e:	30a99563          	bne	s3,a0,ffffffffc0201368 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201062:	4505                	li	a0,1
ffffffffc0201064:	545000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc0201068:	2e051063          	bnez	a0,ffffffffc0201348 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc020106c:	481c                	lw	a5,16(s0)
ffffffffc020106e:	2a079d63          	bnez	a5,ffffffffc0201328 <default_check+0x422>
    free_page(p);
ffffffffc0201072:	854e                	mv	a0,s3
ffffffffc0201074:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201076:	01843023          	sd	s8,0(s0)
ffffffffc020107a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020107e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201082:	565000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    free_page(p1);
ffffffffc0201086:	4585                	li	a1,1
ffffffffc0201088:	8556                	mv	a0,s5
ffffffffc020108a:	55d000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    free_page(p2);
ffffffffc020108e:	4585                	li	a1,1
ffffffffc0201090:	8552                	mv	a0,s4
ffffffffc0201092:	555000ef          	jal	ra,ffffffffc0201de6 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201096:	4515                	li	a0,5
ffffffffc0201098:	511000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc020109c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020109e:	26050563          	beqz	a0,ffffffffc0201308 <default_check+0x402>
ffffffffc02010a2:	651c                	ld	a5,8(a0)
ffffffffc02010a4:	8385                	srli	a5,a5,0x1
ffffffffc02010a6:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc02010a8:	54079063          	bnez	a5,ffffffffc02015e8 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02010ac:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010ae:	00043b03          	ld	s6,0(s0)
ffffffffc02010b2:	00843a83          	ld	s5,8(s0)
ffffffffc02010b6:	e000                	sd	s0,0(s0)
ffffffffc02010b8:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02010ba:	4ef000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc02010be:	50051563          	bnez	a0,ffffffffc02015c8 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02010c2:	08098a13          	addi	s4,s3,128
ffffffffc02010c6:	8552                	mv	a0,s4
ffffffffc02010c8:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02010ca:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02010ce:	000cd797          	auipc	a5,0xcd
ffffffffc02010d2:	ea07ad23          	sw	zero,-326(a5) # ffffffffc02cdf88 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02010d6:	511000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02010da:	4511                	li	a0,4
ffffffffc02010dc:	4cd000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc02010e0:	4c051463          	bnez	a0,ffffffffc02015a8 <default_check+0x6a2>
ffffffffc02010e4:	0889b783          	ld	a5,136(s3)
ffffffffc02010e8:	8385                	srli	a5,a5,0x1
ffffffffc02010ea:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02010ec:	48078e63          	beqz	a5,ffffffffc0201588 <default_check+0x682>
ffffffffc02010f0:	0909a703          	lw	a4,144(s3)
ffffffffc02010f4:	478d                	li	a5,3
ffffffffc02010f6:	48f71963          	bne	a4,a5,ffffffffc0201588 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010fa:	450d                	li	a0,3
ffffffffc02010fc:	4ad000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc0201100:	8c2a                	mv	s8,a0
ffffffffc0201102:	46050363          	beqz	a0,ffffffffc0201568 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0201106:	4505                	li	a0,1
ffffffffc0201108:	4a1000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc020110c:	42051e63          	bnez	a0,ffffffffc0201548 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201110:	418a1c63          	bne	s4,s8,ffffffffc0201528 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201114:	4585                	li	a1,1
ffffffffc0201116:	854e                	mv	a0,s3
ffffffffc0201118:	4cf000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    free_pages(p1, 3);
ffffffffc020111c:	458d                	li	a1,3
ffffffffc020111e:	8552                	mv	a0,s4
ffffffffc0201120:	4c7000ef          	jal	ra,ffffffffc0201de6 <free_pages>
ffffffffc0201124:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201128:	04098c13          	addi	s8,s3,64
ffffffffc020112c:	8385                	srli	a5,a5,0x1
ffffffffc020112e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201130:	3c078c63          	beqz	a5,ffffffffc0201508 <default_check+0x602>
ffffffffc0201134:	0109a703          	lw	a4,16(s3)
ffffffffc0201138:	4785                	li	a5,1
ffffffffc020113a:	3cf71763          	bne	a4,a5,ffffffffc0201508 <default_check+0x602>
ffffffffc020113e:	008a3783          	ld	a5,8(s4)
ffffffffc0201142:	8385                	srli	a5,a5,0x1
ffffffffc0201144:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201146:	3a078163          	beqz	a5,ffffffffc02014e8 <default_check+0x5e2>
ffffffffc020114a:	010a2703          	lw	a4,16(s4)
ffffffffc020114e:	478d                	li	a5,3
ffffffffc0201150:	38f71c63          	bne	a4,a5,ffffffffc02014e8 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201154:	4505                	li	a0,1
ffffffffc0201156:	453000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc020115a:	36a99763          	bne	s3,a0,ffffffffc02014c8 <default_check+0x5c2>
    free_page(p0);
ffffffffc020115e:	4585                	li	a1,1
ffffffffc0201160:	487000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201164:	4509                	li	a0,2
ffffffffc0201166:	443000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc020116a:	32aa1f63          	bne	s4,a0,ffffffffc02014a8 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020116e:	4589                	li	a1,2
ffffffffc0201170:	477000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    free_page(p2);
ffffffffc0201174:	4585                	li	a1,1
ffffffffc0201176:	8562                	mv	a0,s8
ffffffffc0201178:	46f000ef          	jal	ra,ffffffffc0201de6 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020117c:	4515                	li	a0,5
ffffffffc020117e:	42b000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc0201182:	89aa                	mv	s3,a0
ffffffffc0201184:	48050263          	beqz	a0,ffffffffc0201608 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201188:	4505                	li	a0,1
ffffffffc020118a:	41f000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc020118e:	2c051d63          	bnez	a0,ffffffffc0201468 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201192:	481c                	lw	a5,16(s0)
ffffffffc0201194:	2a079a63          	bnez	a5,ffffffffc0201448 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201198:	4595                	li	a1,5
ffffffffc020119a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020119c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02011a0:	01643023          	sd	s6,0(s0)
ffffffffc02011a4:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02011a8:	43f000ef          	jal	ra,ffffffffc0201de6 <free_pages>
    return listelm->next;
ffffffffc02011ac:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02011ae:	00878963          	beq	a5,s0,ffffffffc02011c0 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02011b2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02011b6:	679c                	ld	a5,8(a5)
ffffffffc02011b8:	397d                	addiw	s2,s2,-1
ffffffffc02011ba:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02011bc:	fe879be3          	bne	a5,s0,ffffffffc02011b2 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02011c0:	26091463          	bnez	s2,ffffffffc0201428 <default_check+0x522>
    assert(total == 0);
ffffffffc02011c4:	46049263          	bnez	s1,ffffffffc0201628 <default_check+0x722>
}
ffffffffc02011c8:	60a6                	ld	ra,72(sp)
ffffffffc02011ca:	6406                	ld	s0,64(sp)
ffffffffc02011cc:	74e2                	ld	s1,56(sp)
ffffffffc02011ce:	7942                	ld	s2,48(sp)
ffffffffc02011d0:	79a2                	ld	s3,40(sp)
ffffffffc02011d2:	7a02                	ld	s4,32(sp)
ffffffffc02011d4:	6ae2                	ld	s5,24(sp)
ffffffffc02011d6:	6b42                	ld	s6,16(sp)
ffffffffc02011d8:	6ba2                	ld	s7,8(sp)
ffffffffc02011da:	6c02                	ld	s8,0(sp)
ffffffffc02011dc:	6161                	addi	sp,sp,80
ffffffffc02011de:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02011e0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02011e2:	4481                	li	s1,0
ffffffffc02011e4:	4901                	li	s2,0
ffffffffc02011e6:	b38d                	j	ffffffffc0200f48 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02011e8:	00005697          	auipc	a3,0x5
ffffffffc02011ec:	11868693          	addi	a3,a3,280 # ffffffffc0206300 <commands+0x818>
ffffffffc02011f0:	00005617          	auipc	a2,0x5
ffffffffc02011f4:	12060613          	addi	a2,a2,288 # ffffffffc0206310 <commands+0x828>
ffffffffc02011f8:	11000593          	li	a1,272
ffffffffc02011fc:	00005517          	auipc	a0,0x5
ffffffffc0201200:	12c50513          	addi	a0,a0,300 # ffffffffc0206328 <commands+0x840>
ffffffffc0201204:	a8eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201208:	00005697          	auipc	a3,0x5
ffffffffc020120c:	1b868693          	addi	a3,a3,440 # ffffffffc02063c0 <commands+0x8d8>
ffffffffc0201210:	00005617          	auipc	a2,0x5
ffffffffc0201214:	10060613          	addi	a2,a2,256 # ffffffffc0206310 <commands+0x828>
ffffffffc0201218:	0db00593          	li	a1,219
ffffffffc020121c:	00005517          	auipc	a0,0x5
ffffffffc0201220:	10c50513          	addi	a0,a0,268 # ffffffffc0206328 <commands+0x840>
ffffffffc0201224:	a6eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201228:	00005697          	auipc	a3,0x5
ffffffffc020122c:	1c068693          	addi	a3,a3,448 # ffffffffc02063e8 <commands+0x900>
ffffffffc0201230:	00005617          	auipc	a2,0x5
ffffffffc0201234:	0e060613          	addi	a2,a2,224 # ffffffffc0206310 <commands+0x828>
ffffffffc0201238:	0dc00593          	li	a1,220
ffffffffc020123c:	00005517          	auipc	a0,0x5
ffffffffc0201240:	0ec50513          	addi	a0,a0,236 # ffffffffc0206328 <commands+0x840>
ffffffffc0201244:	a4eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201248:	00005697          	auipc	a3,0x5
ffffffffc020124c:	1e068693          	addi	a3,a3,480 # ffffffffc0206428 <commands+0x940>
ffffffffc0201250:	00005617          	auipc	a2,0x5
ffffffffc0201254:	0c060613          	addi	a2,a2,192 # ffffffffc0206310 <commands+0x828>
ffffffffc0201258:	0de00593          	li	a1,222
ffffffffc020125c:	00005517          	auipc	a0,0x5
ffffffffc0201260:	0cc50513          	addi	a0,a0,204 # ffffffffc0206328 <commands+0x840>
ffffffffc0201264:	a2eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201268:	00005697          	auipc	a3,0x5
ffffffffc020126c:	24868693          	addi	a3,a3,584 # ffffffffc02064b0 <commands+0x9c8>
ffffffffc0201270:	00005617          	auipc	a2,0x5
ffffffffc0201274:	0a060613          	addi	a2,a2,160 # ffffffffc0206310 <commands+0x828>
ffffffffc0201278:	0f700593          	li	a1,247
ffffffffc020127c:	00005517          	auipc	a0,0x5
ffffffffc0201280:	0ac50513          	addi	a0,a0,172 # ffffffffc0206328 <commands+0x840>
ffffffffc0201284:	a0eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201288:	00005697          	auipc	a3,0x5
ffffffffc020128c:	0d868693          	addi	a3,a3,216 # ffffffffc0206360 <commands+0x878>
ffffffffc0201290:	00005617          	auipc	a2,0x5
ffffffffc0201294:	08060613          	addi	a2,a2,128 # ffffffffc0206310 <commands+0x828>
ffffffffc0201298:	0f000593          	li	a1,240
ffffffffc020129c:	00005517          	auipc	a0,0x5
ffffffffc02012a0:	08c50513          	addi	a0,a0,140 # ffffffffc0206328 <commands+0x840>
ffffffffc02012a4:	9eeff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 3);
ffffffffc02012a8:	00005697          	auipc	a3,0x5
ffffffffc02012ac:	1f868693          	addi	a3,a3,504 # ffffffffc02064a0 <commands+0x9b8>
ffffffffc02012b0:	00005617          	auipc	a2,0x5
ffffffffc02012b4:	06060613          	addi	a2,a2,96 # ffffffffc0206310 <commands+0x828>
ffffffffc02012b8:	0ee00593          	li	a1,238
ffffffffc02012bc:	00005517          	auipc	a0,0x5
ffffffffc02012c0:	06c50513          	addi	a0,a0,108 # ffffffffc0206328 <commands+0x840>
ffffffffc02012c4:	9ceff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012c8:	00005697          	auipc	a3,0x5
ffffffffc02012cc:	1c068693          	addi	a3,a3,448 # ffffffffc0206488 <commands+0x9a0>
ffffffffc02012d0:	00005617          	auipc	a2,0x5
ffffffffc02012d4:	04060613          	addi	a2,a2,64 # ffffffffc0206310 <commands+0x828>
ffffffffc02012d8:	0e900593          	li	a1,233
ffffffffc02012dc:	00005517          	auipc	a0,0x5
ffffffffc02012e0:	04c50513          	addi	a0,a0,76 # ffffffffc0206328 <commands+0x840>
ffffffffc02012e4:	9aeff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012e8:	00005697          	auipc	a3,0x5
ffffffffc02012ec:	18068693          	addi	a3,a3,384 # ffffffffc0206468 <commands+0x980>
ffffffffc02012f0:	00005617          	auipc	a2,0x5
ffffffffc02012f4:	02060613          	addi	a2,a2,32 # ffffffffc0206310 <commands+0x828>
ffffffffc02012f8:	0e000593          	li	a1,224
ffffffffc02012fc:	00005517          	auipc	a0,0x5
ffffffffc0201300:	02c50513          	addi	a0,a0,44 # ffffffffc0206328 <commands+0x840>
ffffffffc0201304:	98eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != NULL);
ffffffffc0201308:	00005697          	auipc	a3,0x5
ffffffffc020130c:	1f068693          	addi	a3,a3,496 # ffffffffc02064f8 <commands+0xa10>
ffffffffc0201310:	00005617          	auipc	a2,0x5
ffffffffc0201314:	00060613          	mv	a2,a2
ffffffffc0201318:	11800593          	li	a1,280
ffffffffc020131c:	00005517          	auipc	a0,0x5
ffffffffc0201320:	00c50513          	addi	a0,a0,12 # ffffffffc0206328 <commands+0x840>
ffffffffc0201324:	96eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc0201328:	00005697          	auipc	a3,0x5
ffffffffc020132c:	1c068693          	addi	a3,a3,448 # ffffffffc02064e8 <commands+0xa00>
ffffffffc0201330:	00005617          	auipc	a2,0x5
ffffffffc0201334:	fe060613          	addi	a2,a2,-32 # ffffffffc0206310 <commands+0x828>
ffffffffc0201338:	0fd00593          	li	a1,253
ffffffffc020133c:	00005517          	auipc	a0,0x5
ffffffffc0201340:	fec50513          	addi	a0,a0,-20 # ffffffffc0206328 <commands+0x840>
ffffffffc0201344:	94eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201348:	00005697          	auipc	a3,0x5
ffffffffc020134c:	14068693          	addi	a3,a3,320 # ffffffffc0206488 <commands+0x9a0>
ffffffffc0201350:	00005617          	auipc	a2,0x5
ffffffffc0201354:	fc060613          	addi	a2,a2,-64 # ffffffffc0206310 <commands+0x828>
ffffffffc0201358:	0fb00593          	li	a1,251
ffffffffc020135c:	00005517          	auipc	a0,0x5
ffffffffc0201360:	fcc50513          	addi	a0,a0,-52 # ffffffffc0206328 <commands+0x840>
ffffffffc0201364:	92eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201368:	00005697          	auipc	a3,0x5
ffffffffc020136c:	16068693          	addi	a3,a3,352 # ffffffffc02064c8 <commands+0x9e0>
ffffffffc0201370:	00005617          	auipc	a2,0x5
ffffffffc0201374:	fa060613          	addi	a2,a2,-96 # ffffffffc0206310 <commands+0x828>
ffffffffc0201378:	0fa00593          	li	a1,250
ffffffffc020137c:	00005517          	auipc	a0,0x5
ffffffffc0201380:	fac50513          	addi	a0,a0,-84 # ffffffffc0206328 <commands+0x840>
ffffffffc0201384:	90eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201388:	00005697          	auipc	a3,0x5
ffffffffc020138c:	fd868693          	addi	a3,a3,-40 # ffffffffc0206360 <commands+0x878>
ffffffffc0201390:	00005617          	auipc	a2,0x5
ffffffffc0201394:	f8060613          	addi	a2,a2,-128 # ffffffffc0206310 <commands+0x828>
ffffffffc0201398:	0d700593          	li	a1,215
ffffffffc020139c:	00005517          	auipc	a0,0x5
ffffffffc02013a0:	f8c50513          	addi	a0,a0,-116 # ffffffffc0206328 <commands+0x840>
ffffffffc02013a4:	8eeff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013a8:	00005697          	auipc	a3,0x5
ffffffffc02013ac:	0e068693          	addi	a3,a3,224 # ffffffffc0206488 <commands+0x9a0>
ffffffffc02013b0:	00005617          	auipc	a2,0x5
ffffffffc02013b4:	f6060613          	addi	a2,a2,-160 # ffffffffc0206310 <commands+0x828>
ffffffffc02013b8:	0f400593          	li	a1,244
ffffffffc02013bc:	00005517          	auipc	a0,0x5
ffffffffc02013c0:	f6c50513          	addi	a0,a0,-148 # ffffffffc0206328 <commands+0x840>
ffffffffc02013c4:	8ceff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013c8:	00005697          	auipc	a3,0x5
ffffffffc02013cc:	fd868693          	addi	a3,a3,-40 # ffffffffc02063a0 <commands+0x8b8>
ffffffffc02013d0:	00005617          	auipc	a2,0x5
ffffffffc02013d4:	f4060613          	addi	a2,a2,-192 # ffffffffc0206310 <commands+0x828>
ffffffffc02013d8:	0f200593          	li	a1,242
ffffffffc02013dc:	00005517          	auipc	a0,0x5
ffffffffc02013e0:	f4c50513          	addi	a0,a0,-180 # ffffffffc0206328 <commands+0x840>
ffffffffc02013e4:	8aeff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013e8:	00005697          	auipc	a3,0x5
ffffffffc02013ec:	f9868693          	addi	a3,a3,-104 # ffffffffc0206380 <commands+0x898>
ffffffffc02013f0:	00005617          	auipc	a2,0x5
ffffffffc02013f4:	f2060613          	addi	a2,a2,-224 # ffffffffc0206310 <commands+0x828>
ffffffffc02013f8:	0f100593          	li	a1,241
ffffffffc02013fc:	00005517          	auipc	a0,0x5
ffffffffc0201400:	f2c50513          	addi	a0,a0,-212 # ffffffffc0206328 <commands+0x840>
ffffffffc0201404:	88eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201408:	00005697          	auipc	a3,0x5
ffffffffc020140c:	f9868693          	addi	a3,a3,-104 # ffffffffc02063a0 <commands+0x8b8>
ffffffffc0201410:	00005617          	auipc	a2,0x5
ffffffffc0201414:	f0060613          	addi	a2,a2,-256 # ffffffffc0206310 <commands+0x828>
ffffffffc0201418:	0d900593          	li	a1,217
ffffffffc020141c:	00005517          	auipc	a0,0x5
ffffffffc0201420:	f0c50513          	addi	a0,a0,-244 # ffffffffc0206328 <commands+0x840>
ffffffffc0201424:	86eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(count == 0);
ffffffffc0201428:	00005697          	auipc	a3,0x5
ffffffffc020142c:	22068693          	addi	a3,a3,544 # ffffffffc0206648 <commands+0xb60>
ffffffffc0201430:	00005617          	auipc	a2,0x5
ffffffffc0201434:	ee060613          	addi	a2,a2,-288 # ffffffffc0206310 <commands+0x828>
ffffffffc0201438:	14600593          	li	a1,326
ffffffffc020143c:	00005517          	auipc	a0,0x5
ffffffffc0201440:	eec50513          	addi	a0,a0,-276 # ffffffffc0206328 <commands+0x840>
ffffffffc0201444:	84eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc0201448:	00005697          	auipc	a3,0x5
ffffffffc020144c:	0a068693          	addi	a3,a3,160 # ffffffffc02064e8 <commands+0xa00>
ffffffffc0201450:	00005617          	auipc	a2,0x5
ffffffffc0201454:	ec060613          	addi	a2,a2,-320 # ffffffffc0206310 <commands+0x828>
ffffffffc0201458:	13a00593          	li	a1,314
ffffffffc020145c:	00005517          	auipc	a0,0x5
ffffffffc0201460:	ecc50513          	addi	a0,a0,-308 # ffffffffc0206328 <commands+0x840>
ffffffffc0201464:	82eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201468:	00005697          	auipc	a3,0x5
ffffffffc020146c:	02068693          	addi	a3,a3,32 # ffffffffc0206488 <commands+0x9a0>
ffffffffc0201470:	00005617          	auipc	a2,0x5
ffffffffc0201474:	ea060613          	addi	a2,a2,-352 # ffffffffc0206310 <commands+0x828>
ffffffffc0201478:	13800593          	li	a1,312
ffffffffc020147c:	00005517          	auipc	a0,0x5
ffffffffc0201480:	eac50513          	addi	a0,a0,-340 # ffffffffc0206328 <commands+0x840>
ffffffffc0201484:	80eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201488:	00005697          	auipc	a3,0x5
ffffffffc020148c:	fc068693          	addi	a3,a3,-64 # ffffffffc0206448 <commands+0x960>
ffffffffc0201490:	00005617          	auipc	a2,0x5
ffffffffc0201494:	e8060613          	addi	a2,a2,-384 # ffffffffc0206310 <commands+0x828>
ffffffffc0201498:	0df00593          	li	a1,223
ffffffffc020149c:	00005517          	auipc	a0,0x5
ffffffffc02014a0:	e8c50513          	addi	a0,a0,-372 # ffffffffc0206328 <commands+0x840>
ffffffffc02014a4:	feffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02014a8:	00005697          	auipc	a3,0x5
ffffffffc02014ac:	16068693          	addi	a3,a3,352 # ffffffffc0206608 <commands+0xb20>
ffffffffc02014b0:	00005617          	auipc	a2,0x5
ffffffffc02014b4:	e6060613          	addi	a2,a2,-416 # ffffffffc0206310 <commands+0x828>
ffffffffc02014b8:	13200593          	li	a1,306
ffffffffc02014bc:	00005517          	auipc	a0,0x5
ffffffffc02014c0:	e6c50513          	addi	a0,a0,-404 # ffffffffc0206328 <commands+0x840>
ffffffffc02014c4:	fcffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02014c8:	00005697          	auipc	a3,0x5
ffffffffc02014cc:	12068693          	addi	a3,a3,288 # ffffffffc02065e8 <commands+0xb00>
ffffffffc02014d0:	00005617          	auipc	a2,0x5
ffffffffc02014d4:	e4060613          	addi	a2,a2,-448 # ffffffffc0206310 <commands+0x828>
ffffffffc02014d8:	13000593          	li	a1,304
ffffffffc02014dc:	00005517          	auipc	a0,0x5
ffffffffc02014e0:	e4c50513          	addi	a0,a0,-436 # ffffffffc0206328 <commands+0x840>
ffffffffc02014e4:	faffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014e8:	00005697          	auipc	a3,0x5
ffffffffc02014ec:	0d868693          	addi	a3,a3,216 # ffffffffc02065c0 <commands+0xad8>
ffffffffc02014f0:	00005617          	auipc	a2,0x5
ffffffffc02014f4:	e2060613          	addi	a2,a2,-480 # ffffffffc0206310 <commands+0x828>
ffffffffc02014f8:	12e00593          	li	a1,302
ffffffffc02014fc:	00005517          	auipc	a0,0x5
ffffffffc0201500:	e2c50513          	addi	a0,a0,-468 # ffffffffc0206328 <commands+0x840>
ffffffffc0201504:	f8ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201508:	00005697          	auipc	a3,0x5
ffffffffc020150c:	09068693          	addi	a3,a3,144 # ffffffffc0206598 <commands+0xab0>
ffffffffc0201510:	00005617          	auipc	a2,0x5
ffffffffc0201514:	e0060613          	addi	a2,a2,-512 # ffffffffc0206310 <commands+0x828>
ffffffffc0201518:	12d00593          	li	a1,301
ffffffffc020151c:	00005517          	auipc	a0,0x5
ffffffffc0201520:	e0c50513          	addi	a0,a0,-500 # ffffffffc0206328 <commands+0x840>
ffffffffc0201524:	f6ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201528:	00005697          	auipc	a3,0x5
ffffffffc020152c:	06068693          	addi	a3,a3,96 # ffffffffc0206588 <commands+0xaa0>
ffffffffc0201530:	00005617          	auipc	a2,0x5
ffffffffc0201534:	de060613          	addi	a2,a2,-544 # ffffffffc0206310 <commands+0x828>
ffffffffc0201538:	12800593          	li	a1,296
ffffffffc020153c:	00005517          	auipc	a0,0x5
ffffffffc0201540:	dec50513          	addi	a0,a0,-532 # ffffffffc0206328 <commands+0x840>
ffffffffc0201544:	f4ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201548:	00005697          	auipc	a3,0x5
ffffffffc020154c:	f4068693          	addi	a3,a3,-192 # ffffffffc0206488 <commands+0x9a0>
ffffffffc0201550:	00005617          	auipc	a2,0x5
ffffffffc0201554:	dc060613          	addi	a2,a2,-576 # ffffffffc0206310 <commands+0x828>
ffffffffc0201558:	12700593          	li	a1,295
ffffffffc020155c:	00005517          	auipc	a0,0x5
ffffffffc0201560:	dcc50513          	addi	a0,a0,-564 # ffffffffc0206328 <commands+0x840>
ffffffffc0201564:	f2ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201568:	00005697          	auipc	a3,0x5
ffffffffc020156c:	00068693          	mv	a3,a3
ffffffffc0201570:	00005617          	auipc	a2,0x5
ffffffffc0201574:	da060613          	addi	a2,a2,-608 # ffffffffc0206310 <commands+0x828>
ffffffffc0201578:	12600593          	li	a1,294
ffffffffc020157c:	00005517          	auipc	a0,0x5
ffffffffc0201580:	dac50513          	addi	a0,a0,-596 # ffffffffc0206328 <commands+0x840>
ffffffffc0201584:	f0ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201588:	00005697          	auipc	a3,0x5
ffffffffc020158c:	fb068693          	addi	a3,a3,-80 # ffffffffc0206538 <commands+0xa50>
ffffffffc0201590:	00005617          	auipc	a2,0x5
ffffffffc0201594:	d8060613          	addi	a2,a2,-640 # ffffffffc0206310 <commands+0x828>
ffffffffc0201598:	12500593          	li	a1,293
ffffffffc020159c:	00005517          	auipc	a0,0x5
ffffffffc02015a0:	d8c50513          	addi	a0,a0,-628 # ffffffffc0206328 <commands+0x840>
ffffffffc02015a4:	eeffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02015a8:	00005697          	auipc	a3,0x5
ffffffffc02015ac:	f7868693          	addi	a3,a3,-136 # ffffffffc0206520 <commands+0xa38>
ffffffffc02015b0:	00005617          	auipc	a2,0x5
ffffffffc02015b4:	d6060613          	addi	a2,a2,-672 # ffffffffc0206310 <commands+0x828>
ffffffffc02015b8:	12400593          	li	a1,292
ffffffffc02015bc:	00005517          	auipc	a0,0x5
ffffffffc02015c0:	d6c50513          	addi	a0,a0,-660 # ffffffffc0206328 <commands+0x840>
ffffffffc02015c4:	ecffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015c8:	00005697          	auipc	a3,0x5
ffffffffc02015cc:	ec068693          	addi	a3,a3,-320 # ffffffffc0206488 <commands+0x9a0>
ffffffffc02015d0:	00005617          	auipc	a2,0x5
ffffffffc02015d4:	d4060613          	addi	a2,a2,-704 # ffffffffc0206310 <commands+0x828>
ffffffffc02015d8:	11e00593          	li	a1,286
ffffffffc02015dc:	00005517          	auipc	a0,0x5
ffffffffc02015e0:	d4c50513          	addi	a0,a0,-692 # ffffffffc0206328 <commands+0x840>
ffffffffc02015e4:	eaffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!PageProperty(p0));
ffffffffc02015e8:	00005697          	auipc	a3,0x5
ffffffffc02015ec:	f2068693          	addi	a3,a3,-224 # ffffffffc0206508 <commands+0xa20>
ffffffffc02015f0:	00005617          	auipc	a2,0x5
ffffffffc02015f4:	d2060613          	addi	a2,a2,-736 # ffffffffc0206310 <commands+0x828>
ffffffffc02015f8:	11900593          	li	a1,281
ffffffffc02015fc:	00005517          	auipc	a0,0x5
ffffffffc0201600:	d2c50513          	addi	a0,a0,-724 # ffffffffc0206328 <commands+0x840>
ffffffffc0201604:	e8ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201608:	00005697          	auipc	a3,0x5
ffffffffc020160c:	02068693          	addi	a3,a3,32 # ffffffffc0206628 <commands+0xb40>
ffffffffc0201610:	00005617          	auipc	a2,0x5
ffffffffc0201614:	d0060613          	addi	a2,a2,-768 # ffffffffc0206310 <commands+0x828>
ffffffffc0201618:	13700593          	li	a1,311
ffffffffc020161c:	00005517          	auipc	a0,0x5
ffffffffc0201620:	d0c50513          	addi	a0,a0,-756 # ffffffffc0206328 <commands+0x840>
ffffffffc0201624:	e6ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == 0);
ffffffffc0201628:	00005697          	auipc	a3,0x5
ffffffffc020162c:	03068693          	addi	a3,a3,48 # ffffffffc0206658 <commands+0xb70>
ffffffffc0201630:	00005617          	auipc	a2,0x5
ffffffffc0201634:	ce060613          	addi	a2,a2,-800 # ffffffffc0206310 <commands+0x828>
ffffffffc0201638:	14700593          	li	a1,327
ffffffffc020163c:	00005517          	auipc	a0,0x5
ffffffffc0201640:	cec50513          	addi	a0,a0,-788 # ffffffffc0206328 <commands+0x840>
ffffffffc0201644:	e4ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201648:	00005697          	auipc	a3,0x5
ffffffffc020164c:	cf868693          	addi	a3,a3,-776 # ffffffffc0206340 <commands+0x858>
ffffffffc0201650:	00005617          	auipc	a2,0x5
ffffffffc0201654:	cc060613          	addi	a2,a2,-832 # ffffffffc0206310 <commands+0x828>
ffffffffc0201658:	11300593          	li	a1,275
ffffffffc020165c:	00005517          	auipc	a0,0x5
ffffffffc0201660:	ccc50513          	addi	a0,a0,-820 # ffffffffc0206328 <commands+0x840>
ffffffffc0201664:	e2ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201668:	00005697          	auipc	a3,0x5
ffffffffc020166c:	d1868693          	addi	a3,a3,-744 # ffffffffc0206380 <commands+0x898>
ffffffffc0201670:	00005617          	auipc	a2,0x5
ffffffffc0201674:	ca060613          	addi	a2,a2,-864 # ffffffffc0206310 <commands+0x828>
ffffffffc0201678:	0d800593          	li	a1,216
ffffffffc020167c:	00005517          	auipc	a0,0x5
ffffffffc0201680:	cac50513          	addi	a0,a0,-852 # ffffffffc0206328 <commands+0x840>
ffffffffc0201684:	e0ffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201688 <default_free_pages>:
{
ffffffffc0201688:	1141                	addi	sp,sp,-16
ffffffffc020168a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020168c:	14058463          	beqz	a1,ffffffffc02017d4 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201690:	00659693          	slli	a3,a1,0x6
ffffffffc0201694:	96aa                	add	a3,a3,a0
ffffffffc0201696:	87aa                	mv	a5,a0
ffffffffc0201698:	02d50263          	beq	a0,a3,ffffffffc02016bc <default_free_pages+0x34>
ffffffffc020169c:	6798                	ld	a4,8(a5)
ffffffffc020169e:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016a0:	10071a63          	bnez	a4,ffffffffc02017b4 <default_free_pages+0x12c>
ffffffffc02016a4:	6798                	ld	a4,8(a5)
ffffffffc02016a6:	8b09                	andi	a4,a4,2
ffffffffc02016a8:	10071663          	bnez	a4,ffffffffc02017b4 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02016ac:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02016b0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02016b4:	04078793          	addi	a5,a5,64
ffffffffc02016b8:	fed792e3          	bne	a5,a3,ffffffffc020169c <default_free_pages+0x14>
    base->property = n;
ffffffffc02016bc:	2581                	sext.w	a1,a1
ffffffffc02016be:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02016c0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016c4:	4789                	li	a5,2
ffffffffc02016c6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02016ca:	000cd697          	auipc	a3,0xcd
ffffffffc02016ce:	8ae68693          	addi	a3,a3,-1874 # ffffffffc02cdf78 <free_area>
ffffffffc02016d2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016d4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02016d6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02016da:	9db9                	addw	a1,a1,a4
ffffffffc02016dc:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02016de:	0ad78463          	beq	a5,a3,ffffffffc0201786 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02016e2:	fe878713          	addi	a4,a5,-24
ffffffffc02016e6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02016ea:	4581                	li	a1,0
            if (base < page)
ffffffffc02016ec:	00e56a63          	bltu	a0,a4,ffffffffc0201700 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02016f0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02016f2:	04d70c63          	beq	a4,a3,ffffffffc020174a <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02016f6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02016f8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02016fc:	fee57ae3          	bgeu	a0,a4,ffffffffc02016f0 <default_free_pages+0x68>
ffffffffc0201700:	c199                	beqz	a1,ffffffffc0201706 <default_free_pages+0x7e>
ffffffffc0201702:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201706:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201708:	e390                	sd	a2,0(a5)
ffffffffc020170a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020170c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020170e:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201710:	00d70d63          	beq	a4,a3,ffffffffc020172a <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201714:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201718:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc020171c:	02059813          	slli	a6,a1,0x20
ffffffffc0201720:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201724:	97b2                	add	a5,a5,a2
ffffffffc0201726:	02f50c63          	beq	a0,a5,ffffffffc020175e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020172a:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc020172c:	00d78c63          	beq	a5,a3,ffffffffc0201744 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201730:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201732:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201736:	02061593          	slli	a1,a2,0x20
ffffffffc020173a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020173e:	972a                	add	a4,a4,a0
ffffffffc0201740:	04e68a63          	beq	a3,a4,ffffffffc0201794 <default_free_pages+0x10c>
}
ffffffffc0201744:	60a2                	ld	ra,8(sp)
ffffffffc0201746:	0141                	addi	sp,sp,16
ffffffffc0201748:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020174a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020174c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020174e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201750:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201752:	02d70763          	beq	a4,a3,ffffffffc0201780 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201756:	8832                	mv	a6,a2
ffffffffc0201758:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020175a:	87ba                	mv	a5,a4
ffffffffc020175c:	bf71                	j	ffffffffc02016f8 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020175e:	491c                	lw	a5,16(a0)
ffffffffc0201760:	9dbd                	addw	a1,a1,a5
ffffffffc0201762:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201766:	57f5                	li	a5,-3
ffffffffc0201768:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020176c:	01853803          	ld	a6,24(a0)
ffffffffc0201770:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201772:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201774:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201778:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020177a:	0105b023          	sd	a6,0(a1)
ffffffffc020177e:	b77d                	j	ffffffffc020172c <default_free_pages+0xa4>
ffffffffc0201780:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201782:	873e                	mv	a4,a5
ffffffffc0201784:	bf41                	j	ffffffffc0201714 <default_free_pages+0x8c>
}
ffffffffc0201786:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201788:	e390                	sd	a2,0(a5)
ffffffffc020178a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020178c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020178e:	ed1c                	sd	a5,24(a0)
ffffffffc0201790:	0141                	addi	sp,sp,16
ffffffffc0201792:	8082                	ret
            base->property += p->property;
ffffffffc0201794:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201798:	ff078693          	addi	a3,a5,-16
ffffffffc020179c:	9e39                	addw	a2,a2,a4
ffffffffc020179e:	c910                	sw	a2,16(a0)
ffffffffc02017a0:	5775                	li	a4,-3
ffffffffc02017a2:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017a6:	6398                	ld	a4,0(a5)
ffffffffc02017a8:	679c                	ld	a5,8(a5)
}
ffffffffc02017aa:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02017ac:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02017ae:	e398                	sd	a4,0(a5)
ffffffffc02017b0:	0141                	addi	sp,sp,16
ffffffffc02017b2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017b4:	00005697          	auipc	a3,0x5
ffffffffc02017b8:	ebc68693          	addi	a3,a3,-324 # ffffffffc0206670 <commands+0xb88>
ffffffffc02017bc:	00005617          	auipc	a2,0x5
ffffffffc02017c0:	b5460613          	addi	a2,a2,-1196 # ffffffffc0206310 <commands+0x828>
ffffffffc02017c4:	09400593          	li	a1,148
ffffffffc02017c8:	00005517          	auipc	a0,0x5
ffffffffc02017cc:	b6050513          	addi	a0,a0,-1184 # ffffffffc0206328 <commands+0x840>
ffffffffc02017d0:	cc3fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc02017d4:	00005697          	auipc	a3,0x5
ffffffffc02017d8:	e9468693          	addi	a3,a3,-364 # ffffffffc0206668 <commands+0xb80>
ffffffffc02017dc:	00005617          	auipc	a2,0x5
ffffffffc02017e0:	b3460613          	addi	a2,a2,-1228 # ffffffffc0206310 <commands+0x828>
ffffffffc02017e4:	09000593          	li	a1,144
ffffffffc02017e8:	00005517          	auipc	a0,0x5
ffffffffc02017ec:	b4050513          	addi	a0,a0,-1216 # ffffffffc0206328 <commands+0x840>
ffffffffc02017f0:	ca3fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02017f4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017f4:	c941                	beqz	a0,ffffffffc0201884 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc02017f6:	000cc597          	auipc	a1,0xcc
ffffffffc02017fa:	78258593          	addi	a1,a1,1922 # ffffffffc02cdf78 <free_area>
ffffffffc02017fe:	0105a803          	lw	a6,16(a1)
ffffffffc0201802:	872a                	mv	a4,a0
ffffffffc0201804:	02081793          	slli	a5,a6,0x20
ffffffffc0201808:	9381                	srli	a5,a5,0x20
ffffffffc020180a:	00a7ee63          	bltu	a5,a0,ffffffffc0201826 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020180e:	87ae                	mv	a5,a1
ffffffffc0201810:	a801                	j	ffffffffc0201820 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201812:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201816:	02069613          	slli	a2,a3,0x20
ffffffffc020181a:	9201                	srli	a2,a2,0x20
ffffffffc020181c:	00e67763          	bgeu	a2,a4,ffffffffc020182a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201820:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201822:	feb798e3          	bne	a5,a1,ffffffffc0201812 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201826:	4501                	li	a0,0
}
ffffffffc0201828:	8082                	ret
    return listelm->prev;
ffffffffc020182a:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020182e:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201832:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201836:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020183a:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020183e:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201842:	02c77863          	bgeu	a4,a2,ffffffffc0201872 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201846:	071a                	slli	a4,a4,0x6
ffffffffc0201848:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020184a:	41c686bb          	subw	a3,a3,t3
ffffffffc020184e:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201850:	00870613          	addi	a2,a4,8
ffffffffc0201854:	4689                	li	a3,2
ffffffffc0201856:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020185a:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020185e:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201862:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201866:	e290                	sd	a2,0(a3)
ffffffffc0201868:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020186c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020186e:	01173c23          	sd	a7,24(a4)
ffffffffc0201872:	41c8083b          	subw	a6,a6,t3
ffffffffc0201876:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020187a:	5775                	li	a4,-3
ffffffffc020187c:	17c1                	addi	a5,a5,-16
ffffffffc020187e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201882:	8082                	ret
{
ffffffffc0201884:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201886:	00005697          	auipc	a3,0x5
ffffffffc020188a:	de268693          	addi	a3,a3,-542 # ffffffffc0206668 <commands+0xb80>
ffffffffc020188e:	00005617          	auipc	a2,0x5
ffffffffc0201892:	a8260613          	addi	a2,a2,-1406 # ffffffffc0206310 <commands+0x828>
ffffffffc0201896:	06c00593          	li	a1,108
ffffffffc020189a:	00005517          	auipc	a0,0x5
ffffffffc020189e:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0206328 <commands+0x840>
{
ffffffffc02018a2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018a4:	beffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02018a8 <default_init_memmap>:
{
ffffffffc02018a8:	1141                	addi	sp,sp,-16
ffffffffc02018aa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018ac:	c5f1                	beqz	a1,ffffffffc0201978 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc02018ae:	00659693          	slli	a3,a1,0x6
ffffffffc02018b2:	96aa                	add	a3,a3,a0
ffffffffc02018b4:	87aa                	mv	a5,a0
ffffffffc02018b6:	00d50f63          	beq	a0,a3,ffffffffc02018d4 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02018ba:	6798                	ld	a4,8(a5)
ffffffffc02018bc:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02018be:	cf49                	beqz	a4,ffffffffc0201958 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02018c0:	0007a823          	sw	zero,16(a5)
ffffffffc02018c4:	0007b423          	sd	zero,8(a5)
ffffffffc02018c8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018cc:	04078793          	addi	a5,a5,64
ffffffffc02018d0:	fed795e3          	bne	a5,a3,ffffffffc02018ba <default_init_memmap+0x12>
    base->property = n;
ffffffffc02018d4:	2581                	sext.w	a1,a1
ffffffffc02018d6:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018d8:	4789                	li	a5,2
ffffffffc02018da:	00850713          	addi	a4,a0,8
ffffffffc02018de:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018e2:	000cc697          	auipc	a3,0xcc
ffffffffc02018e6:	69668693          	addi	a3,a3,1686 # ffffffffc02cdf78 <free_area>
ffffffffc02018ea:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018ec:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02018ee:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02018f2:	9db9                	addw	a1,a1,a4
ffffffffc02018f4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02018f6:	04d78a63          	beq	a5,a3,ffffffffc020194a <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc02018fa:	fe878713          	addi	a4,a5,-24
ffffffffc02018fe:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201902:	4581                	li	a1,0
            if (base < page)
ffffffffc0201904:	00e56a63          	bltu	a0,a4,ffffffffc0201918 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201908:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020190a:	02d70263          	beq	a4,a3,ffffffffc020192e <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc020190e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201910:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201914:	fee57ae3          	bgeu	a0,a4,ffffffffc0201908 <default_init_memmap+0x60>
ffffffffc0201918:	c199                	beqz	a1,ffffffffc020191e <default_init_memmap+0x76>
ffffffffc020191a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020191e:	6398                	ld	a4,0(a5)
}
ffffffffc0201920:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201922:	e390                	sd	a2,0(a5)
ffffffffc0201924:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201926:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201928:	ed18                	sd	a4,24(a0)
ffffffffc020192a:	0141                	addi	sp,sp,16
ffffffffc020192c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020192e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201930:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201932:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201934:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201936:	00d70663          	beq	a4,a3,ffffffffc0201942 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc020193a:	8832                	mv	a6,a2
ffffffffc020193c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020193e:	87ba                	mv	a5,a4
ffffffffc0201940:	bfc1                	j	ffffffffc0201910 <default_init_memmap+0x68>
}
ffffffffc0201942:	60a2                	ld	ra,8(sp)
ffffffffc0201944:	e290                	sd	a2,0(a3)
ffffffffc0201946:	0141                	addi	sp,sp,16
ffffffffc0201948:	8082                	ret
ffffffffc020194a:	60a2                	ld	ra,8(sp)
ffffffffc020194c:	e390                	sd	a2,0(a5)
ffffffffc020194e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201950:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201952:	ed1c                	sd	a5,24(a0)
ffffffffc0201954:	0141                	addi	sp,sp,16
ffffffffc0201956:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201958:	00005697          	auipc	a3,0x5
ffffffffc020195c:	d4068693          	addi	a3,a3,-704 # ffffffffc0206698 <commands+0xbb0>
ffffffffc0201960:	00005617          	auipc	a2,0x5
ffffffffc0201964:	9b060613          	addi	a2,a2,-1616 # ffffffffc0206310 <commands+0x828>
ffffffffc0201968:	04b00593          	li	a1,75
ffffffffc020196c:	00005517          	auipc	a0,0x5
ffffffffc0201970:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0206328 <commands+0x840>
ffffffffc0201974:	b1ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc0201978:	00005697          	auipc	a3,0x5
ffffffffc020197c:	cf068693          	addi	a3,a3,-784 # ffffffffc0206668 <commands+0xb80>
ffffffffc0201980:	00005617          	auipc	a2,0x5
ffffffffc0201984:	99060613          	addi	a2,a2,-1648 # ffffffffc0206310 <commands+0x828>
ffffffffc0201988:	04700593          	li	a1,71
ffffffffc020198c:	00005517          	auipc	a0,0x5
ffffffffc0201990:	99c50513          	addi	a0,a0,-1636 # ffffffffc0206328 <commands+0x840>
ffffffffc0201994:	afffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201998 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201998:	c94d                	beqz	a0,ffffffffc0201a4a <slob_free+0xb2>
{
ffffffffc020199a:	1141                	addi	sp,sp,-16
ffffffffc020199c:	e022                	sd	s0,0(sp)
ffffffffc020199e:	e406                	sd	ra,8(sp)
ffffffffc02019a0:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc02019a2:	e9c1                	bnez	a1,ffffffffc0201a32 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019a4:	100027f3          	csrr	a5,sstatus
ffffffffc02019a8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019aa:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019ac:	ebd9                	bnez	a5,ffffffffc0201a42 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019ae:	000cc617          	auipc	a2,0xcc
ffffffffc02019b2:	1ba60613          	addi	a2,a2,442 # ffffffffc02cdb68 <slobfree>
ffffffffc02019b6:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019b8:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019ba:	679c                	ld	a5,8(a5)
ffffffffc02019bc:	02877a63          	bgeu	a4,s0,ffffffffc02019f0 <slob_free+0x58>
ffffffffc02019c0:	00f46463          	bltu	s0,a5,ffffffffc02019c8 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019c4:	fef76ae3          	bltu	a4,a5,ffffffffc02019b8 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02019c8:	400c                	lw	a1,0(s0)
ffffffffc02019ca:	00459693          	slli	a3,a1,0x4
ffffffffc02019ce:	96a2                	add	a3,a3,s0
ffffffffc02019d0:	02d78a63          	beq	a5,a3,ffffffffc0201a04 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02019d4:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02019d6:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02019d8:	00469793          	slli	a5,a3,0x4
ffffffffc02019dc:	97ba                	add	a5,a5,a4
ffffffffc02019de:	02f40e63          	beq	s0,a5,ffffffffc0201a1a <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02019e2:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02019e4:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc02019e6:	e129                	bnez	a0,ffffffffc0201a28 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02019e8:	60a2                	ld	ra,8(sp)
ffffffffc02019ea:	6402                	ld	s0,0(sp)
ffffffffc02019ec:	0141                	addi	sp,sp,16
ffffffffc02019ee:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019f0:	fcf764e3          	bltu	a4,a5,ffffffffc02019b8 <slob_free+0x20>
ffffffffc02019f4:	fcf472e3          	bgeu	s0,a5,ffffffffc02019b8 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02019f8:	400c                	lw	a1,0(s0)
ffffffffc02019fa:	00459693          	slli	a3,a1,0x4
ffffffffc02019fe:	96a2                	add	a3,a3,s0
ffffffffc0201a00:	fcd79ae3          	bne	a5,a3,ffffffffc02019d4 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201a04:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a06:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201a08:	9db5                	addw	a1,a1,a3
ffffffffc0201a0a:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201a0c:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201a0e:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201a10:	00469793          	slli	a5,a3,0x4
ffffffffc0201a14:	97ba                	add	a5,a5,a4
ffffffffc0201a16:	fcf416e3          	bne	s0,a5,ffffffffc02019e2 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201a1a:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201a1c:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201a1e:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201a20:	9ebd                	addw	a3,a3,a5
ffffffffc0201a22:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201a24:	e70c                	sd	a1,8(a4)
ffffffffc0201a26:	d169                	beqz	a0,ffffffffc02019e8 <slob_free+0x50>
}
ffffffffc0201a28:	6402                	ld	s0,0(sp)
ffffffffc0201a2a:	60a2                	ld	ra,8(sp)
ffffffffc0201a2c:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201a2e:	f7bfe06f          	j	ffffffffc02009a8 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201a32:	25bd                	addiw	a1,a1,15
ffffffffc0201a34:	8191                	srli	a1,a1,0x4
ffffffffc0201a36:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a38:	100027f3          	csrr	a5,sstatus
ffffffffc0201a3c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a3e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a40:	d7bd                	beqz	a5,ffffffffc02019ae <slob_free+0x16>
        intr_disable();
ffffffffc0201a42:	f6dfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201a46:	4505                	li	a0,1
ffffffffc0201a48:	b79d                	j	ffffffffc02019ae <slob_free+0x16>
ffffffffc0201a4a:	8082                	ret

ffffffffc0201a4c <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a4c:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a4e:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a50:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a54:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a56:	352000ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
	if (!page)
ffffffffc0201a5a:	c91d                	beqz	a0,ffffffffc0201a90 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201a5c:	000d0697          	auipc	a3,0xd0
ffffffffc0201a60:	5b46b683          	ld	a3,1460(a3) # ffffffffc02d2010 <pages>
ffffffffc0201a64:	8d15                	sub	a0,a0,a3
ffffffffc0201a66:	8519                	srai	a0,a0,0x6
ffffffffc0201a68:	00006697          	auipc	a3,0x6
ffffffffc0201a6c:	7306b683          	ld	a3,1840(a3) # ffffffffc0208198 <nbase>
ffffffffc0201a70:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201a72:	00c51793          	slli	a5,a0,0xc
ffffffffc0201a76:	83b1                	srli	a5,a5,0xc
ffffffffc0201a78:	000d0717          	auipc	a4,0xd0
ffffffffc0201a7c:	59073703          	ld	a4,1424(a4) # ffffffffc02d2008 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201a80:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201a82:	00e7fa63          	bgeu	a5,a4,ffffffffc0201a96 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201a86:	000d0697          	auipc	a3,0xd0
ffffffffc0201a8a:	59a6b683          	ld	a3,1434(a3) # ffffffffc02d2020 <va_pa_offset>
ffffffffc0201a8e:	9536                	add	a0,a0,a3
}
ffffffffc0201a90:	60a2                	ld	ra,8(sp)
ffffffffc0201a92:	0141                	addi	sp,sp,16
ffffffffc0201a94:	8082                	ret
ffffffffc0201a96:	86aa                	mv	a3,a0
ffffffffc0201a98:	00005617          	auipc	a2,0x5
ffffffffc0201a9c:	c6060613          	addi	a2,a2,-928 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc0201aa0:	07100593          	li	a1,113
ffffffffc0201aa4:	00005517          	auipc	a0,0x5
ffffffffc0201aa8:	c7c50513          	addi	a0,a0,-900 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc0201aac:	9e7fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201ab0 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201ab0:	1101                	addi	sp,sp,-32
ffffffffc0201ab2:	ec06                	sd	ra,24(sp)
ffffffffc0201ab4:	e822                	sd	s0,16(sp)
ffffffffc0201ab6:	e426                	sd	s1,8(sp)
ffffffffc0201ab8:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201aba:	01050713          	addi	a4,a0,16
ffffffffc0201abe:	6785                	lui	a5,0x1
ffffffffc0201ac0:	0cf77363          	bgeu	a4,a5,ffffffffc0201b86 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201ac4:	00f50493          	addi	s1,a0,15
ffffffffc0201ac8:	8091                	srli	s1,s1,0x4
ffffffffc0201aca:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201acc:	10002673          	csrr	a2,sstatus
ffffffffc0201ad0:	8a09                	andi	a2,a2,2
ffffffffc0201ad2:	e25d                	bnez	a2,ffffffffc0201b78 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201ad4:	000cc917          	auipc	s2,0xcc
ffffffffc0201ad8:	09490913          	addi	s2,s2,148 # ffffffffc02cdb68 <slobfree>
ffffffffc0201adc:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ae0:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201ae2:	4398                	lw	a4,0(a5)
ffffffffc0201ae4:	08975e63          	bge	a4,s1,ffffffffc0201b80 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201ae8:	00f68b63          	beq	a3,a5,ffffffffc0201afe <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201aec:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201aee:	4018                	lw	a4,0(s0)
ffffffffc0201af0:	02975a63          	bge	a4,s1,ffffffffc0201b24 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201af4:	00093683          	ld	a3,0(s2)
ffffffffc0201af8:	87a2                	mv	a5,s0
ffffffffc0201afa:	fef699e3          	bne	a3,a5,ffffffffc0201aec <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201afe:	ee31                	bnez	a2,ffffffffc0201b5a <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b00:	4501                	li	a0,0
ffffffffc0201b02:	f4bff0ef          	jal	ra,ffffffffc0201a4c <__slob_get_free_pages.constprop.0>
ffffffffc0201b06:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201b08:	cd05                	beqz	a0,ffffffffc0201b40 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b0a:	6585                	lui	a1,0x1
ffffffffc0201b0c:	e8dff0ef          	jal	ra,ffffffffc0201998 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b10:	10002673          	csrr	a2,sstatus
ffffffffc0201b14:	8a09                	andi	a2,a2,2
ffffffffc0201b16:	ee05                	bnez	a2,ffffffffc0201b4e <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201b18:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b1c:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201b1e:	4018                	lw	a4,0(s0)
ffffffffc0201b20:	fc974ae3          	blt	a4,s1,ffffffffc0201af4 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201b24:	04e48763          	beq	s1,a4,ffffffffc0201b72 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201b28:	00449693          	slli	a3,s1,0x4
ffffffffc0201b2c:	96a2                	add	a3,a3,s0
ffffffffc0201b2e:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201b30:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201b32:	9f05                	subw	a4,a4,s1
ffffffffc0201b34:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201b36:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201b38:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201b3a:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201b3e:	e20d                	bnez	a2,ffffffffc0201b60 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201b40:	60e2                	ld	ra,24(sp)
ffffffffc0201b42:	8522                	mv	a0,s0
ffffffffc0201b44:	6442                	ld	s0,16(sp)
ffffffffc0201b46:	64a2                	ld	s1,8(sp)
ffffffffc0201b48:	6902                	ld	s2,0(sp)
ffffffffc0201b4a:	6105                	addi	sp,sp,32
ffffffffc0201b4c:	8082                	ret
        intr_disable();
ffffffffc0201b4e:	e61fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
			cur = slobfree;
ffffffffc0201b52:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201b56:	4605                	li	a2,1
ffffffffc0201b58:	b7d1                	j	ffffffffc0201b1c <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201b5a:	e4ffe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201b5e:	b74d                	j	ffffffffc0201b00 <slob_alloc.constprop.0+0x50>
ffffffffc0201b60:	e49fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc0201b64:	60e2                	ld	ra,24(sp)
ffffffffc0201b66:	8522                	mv	a0,s0
ffffffffc0201b68:	6442                	ld	s0,16(sp)
ffffffffc0201b6a:	64a2                	ld	s1,8(sp)
ffffffffc0201b6c:	6902                	ld	s2,0(sp)
ffffffffc0201b6e:	6105                	addi	sp,sp,32
ffffffffc0201b70:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201b72:	6418                	ld	a4,8(s0)
ffffffffc0201b74:	e798                	sd	a4,8(a5)
ffffffffc0201b76:	b7d1                	j	ffffffffc0201b3a <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201b78:	e37fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201b7c:	4605                	li	a2,1
ffffffffc0201b7e:	bf99                	j	ffffffffc0201ad4 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201b80:	843e                	mv	s0,a5
ffffffffc0201b82:	87b6                	mv	a5,a3
ffffffffc0201b84:	b745                	j	ffffffffc0201b24 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b86:	00005697          	auipc	a3,0x5
ffffffffc0201b8a:	baa68693          	addi	a3,a3,-1110 # ffffffffc0206730 <default_pmm_manager+0x70>
ffffffffc0201b8e:	00004617          	auipc	a2,0x4
ffffffffc0201b92:	78260613          	addi	a2,a2,1922 # ffffffffc0206310 <commands+0x828>
ffffffffc0201b96:	06300593          	li	a1,99
ffffffffc0201b9a:	00005517          	auipc	a0,0x5
ffffffffc0201b9e:	bb650513          	addi	a0,a0,-1098 # ffffffffc0206750 <default_pmm_manager+0x90>
ffffffffc0201ba2:	8f1fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201ba6 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201ba6:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201ba8:	00005517          	auipc	a0,0x5
ffffffffc0201bac:	bc050513          	addi	a0,a0,-1088 # ffffffffc0206768 <default_pmm_manager+0xa8>
{
ffffffffc0201bb0:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201bb2:	de6fe0ef          	jal	ra,ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201bb6:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201bb8:	00005517          	auipc	a0,0x5
ffffffffc0201bbc:	bc850513          	addi	a0,a0,-1080 # ffffffffc0206780 <default_pmm_manager+0xc0>
}
ffffffffc0201bc0:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201bc2:	dd6fe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201bc6 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201bc6:	4501                	li	a0,0
ffffffffc0201bc8:	8082                	ret

ffffffffc0201bca <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201bca:	1101                	addi	sp,sp,-32
ffffffffc0201bcc:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bce:	6905                	lui	s2,0x1
{
ffffffffc0201bd0:	e822                	sd	s0,16(sp)
ffffffffc0201bd2:	ec06                	sd	ra,24(sp)
ffffffffc0201bd4:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bd6:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8f41>
{
ffffffffc0201bda:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bdc:	04a7f963          	bgeu	a5,a0,ffffffffc0201c2e <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201be0:	4561                	li	a0,24
ffffffffc0201be2:	ecfff0ef          	jal	ra,ffffffffc0201ab0 <slob_alloc.constprop.0>
ffffffffc0201be6:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201be8:	c929                	beqz	a0,ffffffffc0201c3a <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201bea:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201bee:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201bf0:	00f95763          	bge	s2,a5,ffffffffc0201bfe <kmalloc+0x34>
ffffffffc0201bf4:	6705                	lui	a4,0x1
ffffffffc0201bf6:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201bf8:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201bfa:	fef74ee3          	blt	a4,a5,ffffffffc0201bf6 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201bfe:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c00:	e4dff0ef          	jal	ra,ffffffffc0201a4c <__slob_get_free_pages.constprop.0>
ffffffffc0201c04:	e488                	sd	a0,8(s1)
ffffffffc0201c06:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201c08:	c525                	beqz	a0,ffffffffc0201c70 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c0a:	100027f3          	csrr	a5,sstatus
ffffffffc0201c0e:	8b89                	andi	a5,a5,2
ffffffffc0201c10:	ef8d                	bnez	a5,ffffffffc0201c4a <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201c12:	000d0797          	auipc	a5,0xd0
ffffffffc0201c16:	3de78793          	addi	a5,a5,990 # ffffffffc02d1ff0 <bigblocks>
ffffffffc0201c1a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201c1c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201c1e:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201c20:	60e2                	ld	ra,24(sp)
ffffffffc0201c22:	8522                	mv	a0,s0
ffffffffc0201c24:	6442                	ld	s0,16(sp)
ffffffffc0201c26:	64a2                	ld	s1,8(sp)
ffffffffc0201c28:	6902                	ld	s2,0(sp)
ffffffffc0201c2a:	6105                	addi	sp,sp,32
ffffffffc0201c2c:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201c2e:	0541                	addi	a0,a0,16
ffffffffc0201c30:	e81ff0ef          	jal	ra,ffffffffc0201ab0 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201c34:	01050413          	addi	s0,a0,16
ffffffffc0201c38:	f565                	bnez	a0,ffffffffc0201c20 <kmalloc+0x56>
ffffffffc0201c3a:	4401                	li	s0,0
}
ffffffffc0201c3c:	60e2                	ld	ra,24(sp)
ffffffffc0201c3e:	8522                	mv	a0,s0
ffffffffc0201c40:	6442                	ld	s0,16(sp)
ffffffffc0201c42:	64a2                	ld	s1,8(sp)
ffffffffc0201c44:	6902                	ld	s2,0(sp)
ffffffffc0201c46:	6105                	addi	sp,sp,32
ffffffffc0201c48:	8082                	ret
        intr_disable();
ffffffffc0201c4a:	d65fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		bb->next = bigblocks;
ffffffffc0201c4e:	000d0797          	auipc	a5,0xd0
ffffffffc0201c52:	3a278793          	addi	a5,a5,930 # ffffffffc02d1ff0 <bigblocks>
ffffffffc0201c56:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201c58:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201c5a:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201c5c:	d4dfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
		return bb->pages;
ffffffffc0201c60:	6480                	ld	s0,8(s1)
}
ffffffffc0201c62:	60e2                	ld	ra,24(sp)
ffffffffc0201c64:	64a2                	ld	s1,8(sp)
ffffffffc0201c66:	8522                	mv	a0,s0
ffffffffc0201c68:	6442                	ld	s0,16(sp)
ffffffffc0201c6a:	6902                	ld	s2,0(sp)
ffffffffc0201c6c:	6105                	addi	sp,sp,32
ffffffffc0201c6e:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c70:	45e1                	li	a1,24
ffffffffc0201c72:	8526                	mv	a0,s1
ffffffffc0201c74:	d25ff0ef          	jal	ra,ffffffffc0201998 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201c78:	b765                	j	ffffffffc0201c20 <kmalloc+0x56>

ffffffffc0201c7a <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201c7a:	c169                	beqz	a0,ffffffffc0201d3c <kfree+0xc2>
{
ffffffffc0201c7c:	1101                	addi	sp,sp,-32
ffffffffc0201c7e:	e822                	sd	s0,16(sp)
ffffffffc0201c80:	ec06                	sd	ra,24(sp)
ffffffffc0201c82:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201c84:	03451793          	slli	a5,a0,0x34
ffffffffc0201c88:	842a                	mv	s0,a0
ffffffffc0201c8a:	e3d9                	bnez	a5,ffffffffc0201d10 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c8c:	100027f3          	csrr	a5,sstatus
ffffffffc0201c90:	8b89                	andi	a5,a5,2
ffffffffc0201c92:	e7d9                	bnez	a5,ffffffffc0201d20 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c94:	000d0797          	auipc	a5,0xd0
ffffffffc0201c98:	35c7b783          	ld	a5,860(a5) # ffffffffc02d1ff0 <bigblocks>
    return 0;
ffffffffc0201c9c:	4601                	li	a2,0
ffffffffc0201c9e:	cbad                	beqz	a5,ffffffffc0201d10 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201ca0:	000d0697          	auipc	a3,0xd0
ffffffffc0201ca4:	35068693          	addi	a3,a3,848 # ffffffffc02d1ff0 <bigblocks>
ffffffffc0201ca8:	a021                	j	ffffffffc0201cb0 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201caa:	01048693          	addi	a3,s1,16
ffffffffc0201cae:	c3a5                	beqz	a5,ffffffffc0201d0e <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201cb0:	6798                	ld	a4,8(a5)
ffffffffc0201cb2:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201cb4:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201cb6:	fe871ae3          	bne	a4,s0,ffffffffc0201caa <kfree+0x30>
				*last = bb->next;
ffffffffc0201cba:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201cbc:	ee2d                	bnez	a2,ffffffffc0201d36 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201cbe:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201cc2:	4098                	lw	a4,0(s1)
ffffffffc0201cc4:	08f46963          	bltu	s0,a5,ffffffffc0201d56 <kfree+0xdc>
ffffffffc0201cc8:	000d0697          	auipc	a3,0xd0
ffffffffc0201ccc:	3586b683          	ld	a3,856(a3) # ffffffffc02d2020 <va_pa_offset>
ffffffffc0201cd0:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201cd2:	8031                	srli	s0,s0,0xc
ffffffffc0201cd4:	000d0797          	auipc	a5,0xd0
ffffffffc0201cd8:	3347b783          	ld	a5,820(a5) # ffffffffc02d2008 <npage>
ffffffffc0201cdc:	06f47163          	bgeu	s0,a5,ffffffffc0201d3e <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ce0:	00006517          	auipc	a0,0x6
ffffffffc0201ce4:	4b853503          	ld	a0,1208(a0) # ffffffffc0208198 <nbase>
ffffffffc0201ce8:	8c09                	sub	s0,s0,a0
ffffffffc0201cea:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201cec:	000d0517          	auipc	a0,0xd0
ffffffffc0201cf0:	32453503          	ld	a0,804(a0) # ffffffffc02d2010 <pages>
ffffffffc0201cf4:	4585                	li	a1,1
ffffffffc0201cf6:	9522                	add	a0,a0,s0
ffffffffc0201cf8:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201cfc:	0ea000ef          	jal	ra,ffffffffc0201de6 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d00:	6442                	ld	s0,16(sp)
ffffffffc0201d02:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d04:	8526                	mv	a0,s1
}
ffffffffc0201d06:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d08:	45e1                	li	a1,24
}
ffffffffc0201d0a:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d0c:	b171                	j	ffffffffc0201998 <slob_free>
ffffffffc0201d0e:	e20d                	bnez	a2,ffffffffc0201d30 <kfree+0xb6>
ffffffffc0201d10:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201d14:	6442                	ld	s0,16(sp)
ffffffffc0201d16:	60e2                	ld	ra,24(sp)
ffffffffc0201d18:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d1a:	4581                	li	a1,0
}
ffffffffc0201d1c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d1e:	b9ad                	j	ffffffffc0201998 <slob_free>
        intr_disable();
ffffffffc0201d20:	c8ffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d24:	000d0797          	auipc	a5,0xd0
ffffffffc0201d28:	2cc7b783          	ld	a5,716(a5) # ffffffffc02d1ff0 <bigblocks>
        return 1;
ffffffffc0201d2c:	4605                	li	a2,1
ffffffffc0201d2e:	fbad                	bnez	a5,ffffffffc0201ca0 <kfree+0x26>
        intr_enable();
ffffffffc0201d30:	c79fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d34:	bff1                	j	ffffffffc0201d10 <kfree+0x96>
ffffffffc0201d36:	c73fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d3a:	b751                	j	ffffffffc0201cbe <kfree+0x44>
ffffffffc0201d3c:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201d3e:	00005617          	auipc	a2,0x5
ffffffffc0201d42:	a8a60613          	addi	a2,a2,-1398 # ffffffffc02067c8 <default_pmm_manager+0x108>
ffffffffc0201d46:	06900593          	li	a1,105
ffffffffc0201d4a:	00005517          	auipc	a0,0x5
ffffffffc0201d4e:	9d650513          	addi	a0,a0,-1578 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc0201d52:	f40fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201d56:	86a2                	mv	a3,s0
ffffffffc0201d58:	00005617          	auipc	a2,0x5
ffffffffc0201d5c:	a4860613          	addi	a2,a2,-1464 # ffffffffc02067a0 <default_pmm_manager+0xe0>
ffffffffc0201d60:	07700593          	li	a1,119
ffffffffc0201d64:	00005517          	auipc	a0,0x5
ffffffffc0201d68:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc0201d6c:	f26fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d70 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201d70:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201d72:	00005617          	auipc	a2,0x5
ffffffffc0201d76:	a5660613          	addi	a2,a2,-1450 # ffffffffc02067c8 <default_pmm_manager+0x108>
ffffffffc0201d7a:	06900593          	li	a1,105
ffffffffc0201d7e:	00005517          	auipc	a0,0x5
ffffffffc0201d82:	9a250513          	addi	a0,a0,-1630 # ffffffffc0206720 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201d86:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201d88:	f0afe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d8c <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201d8c:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201d8e:	00005617          	auipc	a2,0x5
ffffffffc0201d92:	a5a60613          	addi	a2,a2,-1446 # ffffffffc02067e8 <default_pmm_manager+0x128>
ffffffffc0201d96:	07f00593          	li	a1,127
ffffffffc0201d9a:	00005517          	auipc	a0,0x5
ffffffffc0201d9e:	98650513          	addi	a0,a0,-1658 # ffffffffc0206720 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201da2:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201da4:	eeefe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201da8 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201da8:	100027f3          	csrr	a5,sstatus
ffffffffc0201dac:	8b89                	andi	a5,a5,2
ffffffffc0201dae:	e799                	bnez	a5,ffffffffc0201dbc <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201db0:	000d0797          	auipc	a5,0xd0
ffffffffc0201db4:	2687b783          	ld	a5,616(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0201db8:	6f9c                	ld	a5,24(a5)
ffffffffc0201dba:	8782                	jr	a5
{
ffffffffc0201dbc:	1141                	addi	sp,sp,-16
ffffffffc0201dbe:	e406                	sd	ra,8(sp)
ffffffffc0201dc0:	e022                	sd	s0,0(sp)
ffffffffc0201dc2:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201dc4:	bebfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dc8:	000d0797          	auipc	a5,0xd0
ffffffffc0201dcc:	2507b783          	ld	a5,592(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0201dd0:	6f9c                	ld	a5,24(a5)
ffffffffc0201dd2:	8522                	mv	a0,s0
ffffffffc0201dd4:	9782                	jalr	a5
ffffffffc0201dd6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201dd8:	bd1fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ddc:	60a2                	ld	ra,8(sp)
ffffffffc0201dde:	8522                	mv	a0,s0
ffffffffc0201de0:	6402                	ld	s0,0(sp)
ffffffffc0201de2:	0141                	addi	sp,sp,16
ffffffffc0201de4:	8082                	ret

ffffffffc0201de6 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201de6:	100027f3          	csrr	a5,sstatus
ffffffffc0201dea:	8b89                	andi	a5,a5,2
ffffffffc0201dec:	e799                	bnez	a5,ffffffffc0201dfa <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201dee:	000d0797          	auipc	a5,0xd0
ffffffffc0201df2:	22a7b783          	ld	a5,554(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0201df6:	739c                	ld	a5,32(a5)
ffffffffc0201df8:	8782                	jr	a5
{
ffffffffc0201dfa:	1101                	addi	sp,sp,-32
ffffffffc0201dfc:	ec06                	sd	ra,24(sp)
ffffffffc0201dfe:	e822                	sd	s0,16(sp)
ffffffffc0201e00:	e426                	sd	s1,8(sp)
ffffffffc0201e02:	842a                	mv	s0,a0
ffffffffc0201e04:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201e06:	ba9fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201e0a:	000d0797          	auipc	a5,0xd0
ffffffffc0201e0e:	20e7b783          	ld	a5,526(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0201e12:	739c                	ld	a5,32(a5)
ffffffffc0201e14:	85a6                	mv	a1,s1
ffffffffc0201e16:	8522                	mv	a0,s0
ffffffffc0201e18:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201e1a:	6442                	ld	s0,16(sp)
ffffffffc0201e1c:	60e2                	ld	ra,24(sp)
ffffffffc0201e1e:	64a2                	ld	s1,8(sp)
ffffffffc0201e20:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201e22:	b87fe06f          	j	ffffffffc02009a8 <intr_enable>

ffffffffc0201e26 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e26:	100027f3          	csrr	a5,sstatus
ffffffffc0201e2a:	8b89                	andi	a5,a5,2
ffffffffc0201e2c:	e799                	bnez	a5,ffffffffc0201e3a <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e2e:	000d0797          	auipc	a5,0xd0
ffffffffc0201e32:	1ea7b783          	ld	a5,490(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0201e36:	779c                	ld	a5,40(a5)
ffffffffc0201e38:	8782                	jr	a5
{
ffffffffc0201e3a:	1141                	addi	sp,sp,-16
ffffffffc0201e3c:	e406                	sd	ra,8(sp)
ffffffffc0201e3e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201e40:	b6ffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e44:	000d0797          	auipc	a5,0xd0
ffffffffc0201e48:	1d47b783          	ld	a5,468(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0201e4c:	779c                	ld	a5,40(a5)
ffffffffc0201e4e:	9782                	jalr	a5
ffffffffc0201e50:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e52:	b57fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201e56:	60a2                	ld	ra,8(sp)
ffffffffc0201e58:	8522                	mv	a0,s0
ffffffffc0201e5a:	6402                	ld	s0,0(sp)
ffffffffc0201e5c:	0141                	addi	sp,sp,16
ffffffffc0201e5e:	8082                	ret

ffffffffc0201e60 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e60:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201e64:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201e68:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e6a:	078e                	slli	a5,a5,0x3
{
ffffffffc0201e6c:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e6e:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201e72:	6094                	ld	a3,0(s1)
{
ffffffffc0201e74:	f04a                	sd	s2,32(sp)
ffffffffc0201e76:	ec4e                	sd	s3,24(sp)
ffffffffc0201e78:	e852                	sd	s4,16(sp)
ffffffffc0201e7a:	fc06                	sd	ra,56(sp)
ffffffffc0201e7c:	f822                	sd	s0,48(sp)
ffffffffc0201e7e:	e456                	sd	s5,8(sp)
ffffffffc0201e80:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201e82:	0016f793          	andi	a5,a3,1
{
ffffffffc0201e86:	892e                	mv	s2,a1
ffffffffc0201e88:	8a32                	mv	s4,a2
ffffffffc0201e8a:	000d0997          	auipc	s3,0xd0
ffffffffc0201e8e:	17e98993          	addi	s3,s3,382 # ffffffffc02d2008 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201e92:	efbd                	bnez	a5,ffffffffc0201f10 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e94:	14060c63          	beqz	a2,ffffffffc0201fec <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e98:	100027f3          	csrr	a5,sstatus
ffffffffc0201e9c:	8b89                	andi	a5,a5,2
ffffffffc0201e9e:	14079963          	bnez	a5,ffffffffc0201ff0 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ea2:	000d0797          	auipc	a5,0xd0
ffffffffc0201ea6:	1767b783          	ld	a5,374(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0201eaa:	6f9c                	ld	a5,24(a5)
ffffffffc0201eac:	4505                	li	a0,1
ffffffffc0201eae:	9782                	jalr	a5
ffffffffc0201eb0:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201eb2:	12040d63          	beqz	s0,ffffffffc0201fec <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201eb6:	000d0b17          	auipc	s6,0xd0
ffffffffc0201eba:	15ab0b13          	addi	s6,s6,346 # ffffffffc02d2010 <pages>
ffffffffc0201ebe:	000b3503          	ld	a0,0(s6)
ffffffffc0201ec2:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ec6:	000d0997          	auipc	s3,0xd0
ffffffffc0201eca:	14298993          	addi	s3,s3,322 # ffffffffc02d2008 <npage>
ffffffffc0201ece:	40a40533          	sub	a0,s0,a0
ffffffffc0201ed2:	8519                	srai	a0,a0,0x6
ffffffffc0201ed4:	9556                	add	a0,a0,s5
ffffffffc0201ed6:	0009b703          	ld	a4,0(s3)
ffffffffc0201eda:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201ede:	4685                	li	a3,1
ffffffffc0201ee0:	c014                	sw	a3,0(s0)
ffffffffc0201ee2:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ee4:	0532                	slli	a0,a0,0xc
ffffffffc0201ee6:	16e7f763          	bgeu	a5,a4,ffffffffc0202054 <get_pte+0x1f4>
ffffffffc0201eea:	000d0797          	auipc	a5,0xd0
ffffffffc0201eee:	1367b783          	ld	a5,310(a5) # ffffffffc02d2020 <va_pa_offset>
ffffffffc0201ef2:	6605                	lui	a2,0x1
ffffffffc0201ef4:	4581                	li	a1,0
ffffffffc0201ef6:	953e                	add	a0,a0,a5
ffffffffc0201ef8:	159030ef          	jal	ra,ffffffffc0205850 <memset>
    return page - pages + nbase;
ffffffffc0201efc:	000b3683          	ld	a3,0(s6)
ffffffffc0201f00:	40d406b3          	sub	a3,s0,a3
ffffffffc0201f04:	8699                	srai	a3,a3,0x6
ffffffffc0201f06:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f08:	06aa                	slli	a3,a3,0xa
ffffffffc0201f0a:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f0e:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f10:	77fd                	lui	a5,0xfffff
ffffffffc0201f12:	068a                	slli	a3,a3,0x2
ffffffffc0201f14:	0009b703          	ld	a4,0(s3)
ffffffffc0201f18:	8efd                	and	a3,a3,a5
ffffffffc0201f1a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f1e:	10e7ff63          	bgeu	a5,a4,ffffffffc020203c <get_pte+0x1dc>
ffffffffc0201f22:	000d0a97          	auipc	s5,0xd0
ffffffffc0201f26:	0fea8a93          	addi	s5,s5,254 # ffffffffc02d2020 <va_pa_offset>
ffffffffc0201f2a:	000ab403          	ld	s0,0(s5)
ffffffffc0201f2e:	01595793          	srli	a5,s2,0x15
ffffffffc0201f32:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f36:	96a2                	add	a3,a3,s0
ffffffffc0201f38:	00379413          	slli	s0,a5,0x3
ffffffffc0201f3c:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201f3e:	6014                	ld	a3,0(s0)
ffffffffc0201f40:	0016f793          	andi	a5,a3,1
ffffffffc0201f44:	ebad                	bnez	a5,ffffffffc0201fb6 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f46:	0a0a0363          	beqz	s4,ffffffffc0201fec <get_pte+0x18c>
ffffffffc0201f4a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f4e:	8b89                	andi	a5,a5,2
ffffffffc0201f50:	efcd                	bnez	a5,ffffffffc020200a <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f52:	000d0797          	auipc	a5,0xd0
ffffffffc0201f56:	0c67b783          	ld	a5,198(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0201f5a:	6f9c                	ld	a5,24(a5)
ffffffffc0201f5c:	4505                	li	a0,1
ffffffffc0201f5e:	9782                	jalr	a5
ffffffffc0201f60:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f62:	c4c9                	beqz	s1,ffffffffc0201fec <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f64:	000d0b17          	auipc	s6,0xd0
ffffffffc0201f68:	0acb0b13          	addi	s6,s6,172 # ffffffffc02d2010 <pages>
ffffffffc0201f6c:	000b3503          	ld	a0,0(s6)
ffffffffc0201f70:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f74:	0009b703          	ld	a4,0(s3)
ffffffffc0201f78:	40a48533          	sub	a0,s1,a0
ffffffffc0201f7c:	8519                	srai	a0,a0,0x6
ffffffffc0201f7e:	9552                	add	a0,a0,s4
ffffffffc0201f80:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201f84:	4685                	li	a3,1
ffffffffc0201f86:	c094                	sw	a3,0(s1)
ffffffffc0201f88:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f8a:	0532                	slli	a0,a0,0xc
ffffffffc0201f8c:	0ee7f163          	bgeu	a5,a4,ffffffffc020206e <get_pte+0x20e>
ffffffffc0201f90:	000ab783          	ld	a5,0(s5)
ffffffffc0201f94:	6605                	lui	a2,0x1
ffffffffc0201f96:	4581                	li	a1,0
ffffffffc0201f98:	953e                	add	a0,a0,a5
ffffffffc0201f9a:	0b7030ef          	jal	ra,ffffffffc0205850 <memset>
    return page - pages + nbase;
ffffffffc0201f9e:	000b3683          	ld	a3,0(s6)
ffffffffc0201fa2:	40d486b3          	sub	a3,s1,a3
ffffffffc0201fa6:	8699                	srai	a3,a3,0x6
ffffffffc0201fa8:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201faa:	06aa                	slli	a3,a3,0xa
ffffffffc0201fac:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fb0:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201fb2:	0009b703          	ld	a4,0(s3)
ffffffffc0201fb6:	068a                	slli	a3,a3,0x2
ffffffffc0201fb8:	757d                	lui	a0,0xfffff
ffffffffc0201fba:	8ee9                	and	a3,a3,a0
ffffffffc0201fbc:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201fc0:	06e7f263          	bgeu	a5,a4,ffffffffc0202024 <get_pte+0x1c4>
ffffffffc0201fc4:	000ab503          	ld	a0,0(s5)
ffffffffc0201fc8:	00c95913          	srli	s2,s2,0xc
ffffffffc0201fcc:	1ff97913          	andi	s2,s2,511
ffffffffc0201fd0:	96aa                	add	a3,a3,a0
ffffffffc0201fd2:	00391513          	slli	a0,s2,0x3
ffffffffc0201fd6:	9536                	add	a0,a0,a3
}
ffffffffc0201fd8:	70e2                	ld	ra,56(sp)
ffffffffc0201fda:	7442                	ld	s0,48(sp)
ffffffffc0201fdc:	74a2                	ld	s1,40(sp)
ffffffffc0201fde:	7902                	ld	s2,32(sp)
ffffffffc0201fe0:	69e2                	ld	s3,24(sp)
ffffffffc0201fe2:	6a42                	ld	s4,16(sp)
ffffffffc0201fe4:	6aa2                	ld	s5,8(sp)
ffffffffc0201fe6:	6b02                	ld	s6,0(sp)
ffffffffc0201fe8:	6121                	addi	sp,sp,64
ffffffffc0201fea:	8082                	ret
            return NULL;
ffffffffc0201fec:	4501                	li	a0,0
ffffffffc0201fee:	b7ed                	j	ffffffffc0201fd8 <get_pte+0x178>
        intr_disable();
ffffffffc0201ff0:	9bffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ff4:	000d0797          	auipc	a5,0xd0
ffffffffc0201ff8:	0247b783          	ld	a5,36(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0201ffc:	6f9c                	ld	a5,24(a5)
ffffffffc0201ffe:	4505                	li	a0,1
ffffffffc0202000:	9782                	jalr	a5
ffffffffc0202002:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202004:	9a5fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202008:	b56d                	j	ffffffffc0201eb2 <get_pte+0x52>
        intr_disable();
ffffffffc020200a:	9a5fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc020200e:	000d0797          	auipc	a5,0xd0
ffffffffc0202012:	00a7b783          	ld	a5,10(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0202016:	6f9c                	ld	a5,24(a5)
ffffffffc0202018:	4505                	li	a0,1
ffffffffc020201a:	9782                	jalr	a5
ffffffffc020201c:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc020201e:	98bfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202022:	b781                	j	ffffffffc0201f62 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202024:	00004617          	auipc	a2,0x4
ffffffffc0202028:	6d460613          	addi	a2,a2,1748 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc020202c:	0fa00593          	li	a1,250
ffffffffc0202030:	00004517          	auipc	a0,0x4
ffffffffc0202034:	7e050513          	addi	a0,a0,2016 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202038:	c5afe0ef          	jal	ra,ffffffffc0200492 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020203c:	00004617          	auipc	a2,0x4
ffffffffc0202040:	6bc60613          	addi	a2,a2,1724 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc0202044:	0ed00593          	li	a1,237
ffffffffc0202048:	00004517          	auipc	a0,0x4
ffffffffc020204c:	7c850513          	addi	a0,a0,1992 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202050:	c42fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202054:	86aa                	mv	a3,a0
ffffffffc0202056:	00004617          	auipc	a2,0x4
ffffffffc020205a:	6a260613          	addi	a2,a2,1698 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc020205e:	0e900593          	li	a1,233
ffffffffc0202062:	00004517          	auipc	a0,0x4
ffffffffc0202066:	7ae50513          	addi	a0,a0,1966 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc020206a:	c28fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020206e:	86aa                	mv	a3,a0
ffffffffc0202070:	00004617          	auipc	a2,0x4
ffffffffc0202074:	68860613          	addi	a2,a2,1672 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc0202078:	0f700593          	li	a1,247
ffffffffc020207c:	00004517          	auipc	a0,0x4
ffffffffc0202080:	79450513          	addi	a0,a0,1940 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202084:	c0efe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0202088 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202088:	1141                	addi	sp,sp,-16
ffffffffc020208a:	e022                	sd	s0,0(sp)
ffffffffc020208c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020208e:	4601                	li	a2,0
{
ffffffffc0202090:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202092:	dcfff0ef          	jal	ra,ffffffffc0201e60 <get_pte>
    if (ptep_store != NULL)
ffffffffc0202096:	c011                	beqz	s0,ffffffffc020209a <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202098:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020209a:	c511                	beqz	a0,ffffffffc02020a6 <get_page+0x1e>
ffffffffc020209c:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020209e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02020a0:	0017f713          	andi	a4,a5,1
ffffffffc02020a4:	e709                	bnez	a4,ffffffffc02020ae <get_page+0x26>
}
ffffffffc02020a6:	60a2                	ld	ra,8(sp)
ffffffffc02020a8:	6402                	ld	s0,0(sp)
ffffffffc02020aa:	0141                	addi	sp,sp,16
ffffffffc02020ac:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02020ae:	078a                	slli	a5,a5,0x2
ffffffffc02020b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020b2:	000d0717          	auipc	a4,0xd0
ffffffffc02020b6:	f5673703          	ld	a4,-170(a4) # ffffffffc02d2008 <npage>
ffffffffc02020ba:	00e7ff63          	bgeu	a5,a4,ffffffffc02020d8 <get_page+0x50>
ffffffffc02020be:	60a2                	ld	ra,8(sp)
ffffffffc02020c0:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02020c2:	fff80537          	lui	a0,0xfff80
ffffffffc02020c6:	97aa                	add	a5,a5,a0
ffffffffc02020c8:	079a                	slli	a5,a5,0x6
ffffffffc02020ca:	000d0517          	auipc	a0,0xd0
ffffffffc02020ce:	f4653503          	ld	a0,-186(a0) # ffffffffc02d2010 <pages>
ffffffffc02020d2:	953e                	add	a0,a0,a5
ffffffffc02020d4:	0141                	addi	sp,sp,16
ffffffffc02020d6:	8082                	ret
ffffffffc02020d8:	c99ff0ef          	jal	ra,ffffffffc0201d70 <pa2page.part.0>

ffffffffc02020dc <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02020dc:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020de:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02020e2:	f486                	sd	ra,104(sp)
ffffffffc02020e4:	f0a2                	sd	s0,96(sp)
ffffffffc02020e6:	eca6                	sd	s1,88(sp)
ffffffffc02020e8:	e8ca                	sd	s2,80(sp)
ffffffffc02020ea:	e4ce                	sd	s3,72(sp)
ffffffffc02020ec:	e0d2                	sd	s4,64(sp)
ffffffffc02020ee:	fc56                	sd	s5,56(sp)
ffffffffc02020f0:	f85a                	sd	s6,48(sp)
ffffffffc02020f2:	f45e                	sd	s7,40(sp)
ffffffffc02020f4:	f062                	sd	s8,32(sp)
ffffffffc02020f6:	ec66                	sd	s9,24(sp)
ffffffffc02020f8:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020fa:	17d2                	slli	a5,a5,0x34
ffffffffc02020fc:	e3ed                	bnez	a5,ffffffffc02021de <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02020fe:	002007b7          	lui	a5,0x200
ffffffffc0202102:	842e                	mv	s0,a1
ffffffffc0202104:	0ef5ed63          	bltu	a1,a5,ffffffffc02021fe <unmap_range+0x122>
ffffffffc0202108:	8932                	mv	s2,a2
ffffffffc020210a:	0ec5fa63          	bgeu	a1,a2,ffffffffc02021fe <unmap_range+0x122>
ffffffffc020210e:	4785                	li	a5,1
ffffffffc0202110:	07fe                	slli	a5,a5,0x1f
ffffffffc0202112:	0ec7e663          	bltu	a5,a2,ffffffffc02021fe <unmap_range+0x122>
ffffffffc0202116:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202118:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020211a:	000d0c97          	auipc	s9,0xd0
ffffffffc020211e:	eeec8c93          	addi	s9,s9,-274 # ffffffffc02d2008 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202122:	000d0c17          	auipc	s8,0xd0
ffffffffc0202126:	eeec0c13          	addi	s8,s8,-274 # ffffffffc02d2010 <pages>
ffffffffc020212a:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc020212e:	000d0d17          	auipc	s10,0xd0
ffffffffc0202132:	eead0d13          	addi	s10,s10,-278 # ffffffffc02d2018 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202136:	00200b37          	lui	s6,0x200
ffffffffc020213a:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020213e:	4601                	li	a2,0
ffffffffc0202140:	85a2                	mv	a1,s0
ffffffffc0202142:	854e                	mv	a0,s3
ffffffffc0202144:	d1dff0ef          	jal	ra,ffffffffc0201e60 <get_pte>
ffffffffc0202148:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020214a:	cd29                	beqz	a0,ffffffffc02021a4 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc020214c:	611c                	ld	a5,0(a0)
ffffffffc020214e:	e395                	bnez	a5,ffffffffc0202172 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202150:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202152:	ff2466e3          	bltu	s0,s2,ffffffffc020213e <unmap_range+0x62>
}
ffffffffc0202156:	70a6                	ld	ra,104(sp)
ffffffffc0202158:	7406                	ld	s0,96(sp)
ffffffffc020215a:	64e6                	ld	s1,88(sp)
ffffffffc020215c:	6946                	ld	s2,80(sp)
ffffffffc020215e:	69a6                	ld	s3,72(sp)
ffffffffc0202160:	6a06                	ld	s4,64(sp)
ffffffffc0202162:	7ae2                	ld	s5,56(sp)
ffffffffc0202164:	7b42                	ld	s6,48(sp)
ffffffffc0202166:	7ba2                	ld	s7,40(sp)
ffffffffc0202168:	7c02                	ld	s8,32(sp)
ffffffffc020216a:	6ce2                	ld	s9,24(sp)
ffffffffc020216c:	6d42                	ld	s10,16(sp)
ffffffffc020216e:	6165                	addi	sp,sp,112
ffffffffc0202170:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202172:	0017f713          	andi	a4,a5,1
ffffffffc0202176:	df69                	beqz	a4,ffffffffc0202150 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202178:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020217c:	078a                	slli	a5,a5,0x2
ffffffffc020217e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202180:	08e7ff63          	bgeu	a5,a4,ffffffffc020221e <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202184:	000c3503          	ld	a0,0(s8)
ffffffffc0202188:	97de                	add	a5,a5,s7
ffffffffc020218a:	079a                	slli	a5,a5,0x6
ffffffffc020218c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020218e:	411c                	lw	a5,0(a0)
ffffffffc0202190:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202194:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202196:	cf11                	beqz	a4,ffffffffc02021b2 <unmap_range+0xd6>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202198:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020219c:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02021a0:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02021a2:	bf45                	j	ffffffffc0202152 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021a4:	945a                	add	s0,s0,s6
ffffffffc02021a6:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02021aa:	d455                	beqz	s0,ffffffffc0202156 <unmap_range+0x7a>
ffffffffc02021ac:	f92469e3          	bltu	s0,s2,ffffffffc020213e <unmap_range+0x62>
ffffffffc02021b0:	b75d                	j	ffffffffc0202156 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02021b2:	100027f3          	csrr	a5,sstatus
ffffffffc02021b6:	8b89                	andi	a5,a5,2
ffffffffc02021b8:	e799                	bnez	a5,ffffffffc02021c6 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc02021ba:	000d3783          	ld	a5,0(s10)
ffffffffc02021be:	4585                	li	a1,1
ffffffffc02021c0:	739c                	ld	a5,32(a5)
ffffffffc02021c2:	9782                	jalr	a5
    if (flag)
ffffffffc02021c4:	bfd1                	j	ffffffffc0202198 <unmap_range+0xbc>
ffffffffc02021c6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02021c8:	fe6fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02021cc:	000d3783          	ld	a5,0(s10)
ffffffffc02021d0:	6522                	ld	a0,8(sp)
ffffffffc02021d2:	4585                	li	a1,1
ffffffffc02021d4:	739c                	ld	a5,32(a5)
ffffffffc02021d6:	9782                	jalr	a5
        intr_enable();
ffffffffc02021d8:	fd0fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02021dc:	bf75                	j	ffffffffc0202198 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021de:	00004697          	auipc	a3,0x4
ffffffffc02021e2:	64268693          	addi	a3,a3,1602 # ffffffffc0206820 <default_pmm_manager+0x160>
ffffffffc02021e6:	00004617          	auipc	a2,0x4
ffffffffc02021ea:	12a60613          	addi	a2,a2,298 # ffffffffc0206310 <commands+0x828>
ffffffffc02021ee:	12200593          	li	a1,290
ffffffffc02021f2:	00004517          	auipc	a0,0x4
ffffffffc02021f6:	61e50513          	addi	a0,a0,1566 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc02021fa:	a98fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02021fe:	00004697          	auipc	a3,0x4
ffffffffc0202202:	65268693          	addi	a3,a3,1618 # ffffffffc0206850 <default_pmm_manager+0x190>
ffffffffc0202206:	00004617          	auipc	a2,0x4
ffffffffc020220a:	10a60613          	addi	a2,a2,266 # ffffffffc0206310 <commands+0x828>
ffffffffc020220e:	12300593          	li	a1,291
ffffffffc0202212:	00004517          	auipc	a0,0x4
ffffffffc0202216:	5fe50513          	addi	a0,a0,1534 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc020221a:	a78fe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc020221e:	b53ff0ef          	jal	ra,ffffffffc0201d70 <pa2page.part.0>

ffffffffc0202222 <exit_range>:
{
ffffffffc0202222:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202224:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202228:	fc86                	sd	ra,120(sp)
ffffffffc020222a:	f8a2                	sd	s0,112(sp)
ffffffffc020222c:	f4a6                	sd	s1,104(sp)
ffffffffc020222e:	f0ca                	sd	s2,96(sp)
ffffffffc0202230:	ecce                	sd	s3,88(sp)
ffffffffc0202232:	e8d2                	sd	s4,80(sp)
ffffffffc0202234:	e4d6                	sd	s5,72(sp)
ffffffffc0202236:	e0da                	sd	s6,64(sp)
ffffffffc0202238:	fc5e                	sd	s7,56(sp)
ffffffffc020223a:	f862                	sd	s8,48(sp)
ffffffffc020223c:	f466                	sd	s9,40(sp)
ffffffffc020223e:	f06a                	sd	s10,32(sp)
ffffffffc0202240:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202242:	17d2                	slli	a5,a5,0x34
ffffffffc0202244:	20079a63          	bnez	a5,ffffffffc0202458 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0202248:	002007b7          	lui	a5,0x200
ffffffffc020224c:	24f5e463          	bltu	a1,a5,ffffffffc0202494 <exit_range+0x272>
ffffffffc0202250:	8ab2                	mv	s5,a2
ffffffffc0202252:	24c5f163          	bgeu	a1,a2,ffffffffc0202494 <exit_range+0x272>
ffffffffc0202256:	4785                	li	a5,1
ffffffffc0202258:	07fe                	slli	a5,a5,0x1f
ffffffffc020225a:	22c7ed63          	bltu	a5,a2,ffffffffc0202494 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020225e:	c00009b7          	lui	s3,0xc0000
ffffffffc0202262:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202266:	ffe00937          	lui	s2,0xffe00
ffffffffc020226a:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020226e:	5cfd                	li	s9,-1
ffffffffc0202270:	8c2a                	mv	s8,a0
ffffffffc0202272:	0125f933          	and	s2,a1,s2
ffffffffc0202276:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202278:	000d0d17          	auipc	s10,0xd0
ffffffffc020227c:	d90d0d13          	addi	s10,s10,-624 # ffffffffc02d2008 <npage>
    return KADDR(page2pa(page));
ffffffffc0202280:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202284:	000d0717          	auipc	a4,0xd0
ffffffffc0202288:	d8c70713          	addi	a4,a4,-628 # ffffffffc02d2010 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc020228c:	000d0d97          	auipc	s11,0xd0
ffffffffc0202290:	d8cd8d93          	addi	s11,s11,-628 # ffffffffc02d2018 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202294:	c0000437          	lui	s0,0xc0000
ffffffffc0202298:	944e                	add	s0,s0,s3
ffffffffc020229a:	8079                	srli	s0,s0,0x1e
ffffffffc020229c:	1ff47413          	andi	s0,s0,511
ffffffffc02022a0:	040e                	slli	s0,s0,0x3
ffffffffc02022a2:	9462                	add	s0,s0,s8
ffffffffc02022a4:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38f8>
        if (pde1 & PTE_V)
ffffffffc02022a8:	001a7793          	andi	a5,s4,1
ffffffffc02022ac:	eb99                	bnez	a5,ffffffffc02022c2 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc02022ae:	12098463          	beqz	s3,ffffffffc02023d6 <exit_range+0x1b4>
ffffffffc02022b2:	400007b7          	lui	a5,0x40000
ffffffffc02022b6:	97ce                	add	a5,a5,s3
ffffffffc02022b8:	894e                	mv	s2,s3
ffffffffc02022ba:	1159fe63          	bgeu	s3,s5,ffffffffc02023d6 <exit_range+0x1b4>
ffffffffc02022be:	89be                	mv	s3,a5
ffffffffc02022c0:	bfd1                	j	ffffffffc0202294 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02022c2:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02022c6:	0a0a                	slli	s4,s4,0x2
ffffffffc02022c8:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02022cc:	1cfa7263          	bgeu	s4,a5,ffffffffc0202490 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02022d0:	fff80637          	lui	a2,0xfff80
ffffffffc02022d4:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02022d6:	000806b7          	lui	a3,0x80
ffffffffc02022da:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02022dc:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02022e0:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02022e2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02022e4:	18f5fa63          	bgeu	a1,a5,ffffffffc0202478 <exit_range+0x256>
ffffffffc02022e8:	000d0817          	auipc	a6,0xd0
ffffffffc02022ec:	d3880813          	addi	a6,a6,-712 # ffffffffc02d2020 <va_pa_offset>
ffffffffc02022f0:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02022f4:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02022f6:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02022fa:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02022fc:	00080337          	lui	t1,0x80
ffffffffc0202300:	6885                	lui	a7,0x1
ffffffffc0202302:	a819                	j	ffffffffc0202318 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202304:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc0202306:	002007b7          	lui	a5,0x200
ffffffffc020230a:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020230c:	08090c63          	beqz	s2,ffffffffc02023a4 <exit_range+0x182>
ffffffffc0202310:	09397a63          	bgeu	s2,s3,ffffffffc02023a4 <exit_range+0x182>
ffffffffc0202314:	0f597063          	bgeu	s2,s5,ffffffffc02023f4 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202318:	01595493          	srli	s1,s2,0x15
ffffffffc020231c:	1ff4f493          	andi	s1,s1,511
ffffffffc0202320:	048e                	slli	s1,s1,0x3
ffffffffc0202322:	94da                	add	s1,s1,s6
ffffffffc0202324:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc0202326:	0017f693          	andi	a3,a5,1
ffffffffc020232a:	dee9                	beqz	a3,ffffffffc0202304 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc020232c:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202330:	078a                	slli	a5,a5,0x2
ffffffffc0202332:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202334:	14b7fe63          	bgeu	a5,a1,ffffffffc0202490 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202338:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020233a:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc020233e:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202342:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202346:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202348:	12bef863          	bgeu	t4,a1,ffffffffc0202478 <exit_range+0x256>
ffffffffc020234c:	00083783          	ld	a5,0(a6)
ffffffffc0202350:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202352:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc0202356:	629c                	ld	a5,0(a3)
ffffffffc0202358:	8b85                	andi	a5,a5,1
ffffffffc020235a:	f7d5                	bnez	a5,ffffffffc0202306 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020235c:	06a1                	addi	a3,a3,8
ffffffffc020235e:	fed59ce3          	bne	a1,a3,ffffffffc0202356 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202362:	631c                	ld	a5,0(a4)
ffffffffc0202364:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202366:	100027f3          	csrr	a5,sstatus
ffffffffc020236a:	8b89                	andi	a5,a5,2
ffffffffc020236c:	e7d9                	bnez	a5,ffffffffc02023fa <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc020236e:	000db783          	ld	a5,0(s11)
ffffffffc0202372:	4585                	li	a1,1
ffffffffc0202374:	e032                	sd	a2,0(sp)
ffffffffc0202376:	739c                	ld	a5,32(a5)
ffffffffc0202378:	9782                	jalr	a5
    if (flag)
ffffffffc020237a:	6602                	ld	a2,0(sp)
ffffffffc020237c:	000d0817          	auipc	a6,0xd0
ffffffffc0202380:	ca480813          	addi	a6,a6,-860 # ffffffffc02d2020 <va_pa_offset>
ffffffffc0202384:	fff80e37          	lui	t3,0xfff80
ffffffffc0202388:	00080337          	lui	t1,0x80
ffffffffc020238c:	6885                	lui	a7,0x1
ffffffffc020238e:	000d0717          	auipc	a4,0xd0
ffffffffc0202392:	c8270713          	addi	a4,a4,-894 # ffffffffc02d2010 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202396:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020239a:	002007b7          	lui	a5,0x200
ffffffffc020239e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023a0:	f60918e3          	bnez	s2,ffffffffc0202310 <exit_range+0xee>
            if (free_pd0)
ffffffffc02023a4:	f00b85e3          	beqz	s7,ffffffffc02022ae <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc02023a8:	000d3783          	ld	a5,0(s10)
ffffffffc02023ac:	0efa7263          	bgeu	s4,a5,ffffffffc0202490 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023b0:	6308                	ld	a0,0(a4)
ffffffffc02023b2:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02023b4:	100027f3          	csrr	a5,sstatus
ffffffffc02023b8:	8b89                	andi	a5,a5,2
ffffffffc02023ba:	efad                	bnez	a5,ffffffffc0202434 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02023bc:	000db783          	ld	a5,0(s11)
ffffffffc02023c0:	4585                	li	a1,1
ffffffffc02023c2:	739c                	ld	a5,32(a5)
ffffffffc02023c4:	9782                	jalr	a5
ffffffffc02023c6:	000d0717          	auipc	a4,0xd0
ffffffffc02023ca:	c4a70713          	addi	a4,a4,-950 # ffffffffc02d2010 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02023ce:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02023d2:	ee0990e3          	bnez	s3,ffffffffc02022b2 <exit_range+0x90>
}
ffffffffc02023d6:	70e6                	ld	ra,120(sp)
ffffffffc02023d8:	7446                	ld	s0,112(sp)
ffffffffc02023da:	74a6                	ld	s1,104(sp)
ffffffffc02023dc:	7906                	ld	s2,96(sp)
ffffffffc02023de:	69e6                	ld	s3,88(sp)
ffffffffc02023e0:	6a46                	ld	s4,80(sp)
ffffffffc02023e2:	6aa6                	ld	s5,72(sp)
ffffffffc02023e4:	6b06                	ld	s6,64(sp)
ffffffffc02023e6:	7be2                	ld	s7,56(sp)
ffffffffc02023e8:	7c42                	ld	s8,48(sp)
ffffffffc02023ea:	7ca2                	ld	s9,40(sp)
ffffffffc02023ec:	7d02                	ld	s10,32(sp)
ffffffffc02023ee:	6de2                	ld	s11,24(sp)
ffffffffc02023f0:	6109                	addi	sp,sp,128
ffffffffc02023f2:	8082                	ret
            if (free_pd0)
ffffffffc02023f4:	ea0b8fe3          	beqz	s7,ffffffffc02022b2 <exit_range+0x90>
ffffffffc02023f8:	bf45                	j	ffffffffc02023a8 <exit_range+0x186>
ffffffffc02023fa:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02023fc:	e42a                	sd	a0,8(sp)
ffffffffc02023fe:	db0fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202402:	000db783          	ld	a5,0(s11)
ffffffffc0202406:	6522                	ld	a0,8(sp)
ffffffffc0202408:	4585                	li	a1,1
ffffffffc020240a:	739c                	ld	a5,32(a5)
ffffffffc020240c:	9782                	jalr	a5
        intr_enable();
ffffffffc020240e:	d9afe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202412:	6602                	ld	a2,0(sp)
ffffffffc0202414:	000d0717          	auipc	a4,0xd0
ffffffffc0202418:	bfc70713          	addi	a4,a4,-1028 # ffffffffc02d2010 <pages>
ffffffffc020241c:	6885                	lui	a7,0x1
ffffffffc020241e:	00080337          	lui	t1,0x80
ffffffffc0202422:	fff80e37          	lui	t3,0xfff80
ffffffffc0202426:	000d0817          	auipc	a6,0xd0
ffffffffc020242a:	bfa80813          	addi	a6,a6,-1030 # ffffffffc02d2020 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020242e:	0004b023          	sd	zero,0(s1)
ffffffffc0202432:	b7a5                	j	ffffffffc020239a <exit_range+0x178>
ffffffffc0202434:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0202436:	d78fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020243a:	000db783          	ld	a5,0(s11)
ffffffffc020243e:	6502                	ld	a0,0(sp)
ffffffffc0202440:	4585                	li	a1,1
ffffffffc0202442:	739c                	ld	a5,32(a5)
ffffffffc0202444:	9782                	jalr	a5
        intr_enable();
ffffffffc0202446:	d62fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020244a:	000d0717          	auipc	a4,0xd0
ffffffffc020244e:	bc670713          	addi	a4,a4,-1082 # ffffffffc02d2010 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202452:	00043023          	sd	zero,0(s0)
ffffffffc0202456:	bfb5                	j	ffffffffc02023d2 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202458:	00004697          	auipc	a3,0x4
ffffffffc020245c:	3c868693          	addi	a3,a3,968 # ffffffffc0206820 <default_pmm_manager+0x160>
ffffffffc0202460:	00004617          	auipc	a2,0x4
ffffffffc0202464:	eb060613          	addi	a2,a2,-336 # ffffffffc0206310 <commands+0x828>
ffffffffc0202468:	13700593          	li	a1,311
ffffffffc020246c:	00004517          	auipc	a0,0x4
ffffffffc0202470:	3a450513          	addi	a0,a0,932 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202474:	81efe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202478:	00004617          	auipc	a2,0x4
ffffffffc020247c:	28060613          	addi	a2,a2,640 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc0202480:	07100593          	li	a1,113
ffffffffc0202484:	00004517          	auipc	a0,0x4
ffffffffc0202488:	29c50513          	addi	a0,a0,668 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc020248c:	806fe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202490:	8e1ff0ef          	jal	ra,ffffffffc0201d70 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202494:	00004697          	auipc	a3,0x4
ffffffffc0202498:	3bc68693          	addi	a3,a3,956 # ffffffffc0206850 <default_pmm_manager+0x190>
ffffffffc020249c:	00004617          	auipc	a2,0x4
ffffffffc02024a0:	e7460613          	addi	a2,a2,-396 # ffffffffc0206310 <commands+0x828>
ffffffffc02024a4:	13800593          	li	a1,312
ffffffffc02024a8:	00004517          	auipc	a0,0x4
ffffffffc02024ac:	36850513          	addi	a0,a0,872 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc02024b0:	fe3fd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02024b4 <page_remove>:
{
ffffffffc02024b4:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02024b6:	4601                	li	a2,0
{
ffffffffc02024b8:	ec26                	sd	s1,24(sp)
ffffffffc02024ba:	f406                	sd	ra,40(sp)
ffffffffc02024bc:	f022                	sd	s0,32(sp)
ffffffffc02024be:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02024c0:	9a1ff0ef          	jal	ra,ffffffffc0201e60 <get_pte>
    if (ptep != NULL)
ffffffffc02024c4:	c511                	beqz	a0,ffffffffc02024d0 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02024c6:	611c                	ld	a5,0(a0)
ffffffffc02024c8:	842a                	mv	s0,a0
ffffffffc02024ca:	0017f713          	andi	a4,a5,1
ffffffffc02024ce:	e711                	bnez	a4,ffffffffc02024da <page_remove+0x26>
}
ffffffffc02024d0:	70a2                	ld	ra,40(sp)
ffffffffc02024d2:	7402                	ld	s0,32(sp)
ffffffffc02024d4:	64e2                	ld	s1,24(sp)
ffffffffc02024d6:	6145                	addi	sp,sp,48
ffffffffc02024d8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02024da:	078a                	slli	a5,a5,0x2
ffffffffc02024dc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024de:	000d0717          	auipc	a4,0xd0
ffffffffc02024e2:	b2a73703          	ld	a4,-1238(a4) # ffffffffc02d2008 <npage>
ffffffffc02024e6:	06e7f363          	bgeu	a5,a4,ffffffffc020254c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02024ea:	fff80537          	lui	a0,0xfff80
ffffffffc02024ee:	97aa                	add	a5,a5,a0
ffffffffc02024f0:	079a                	slli	a5,a5,0x6
ffffffffc02024f2:	000d0517          	auipc	a0,0xd0
ffffffffc02024f6:	b1e53503          	ld	a0,-1250(a0) # ffffffffc02d2010 <pages>
ffffffffc02024fa:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02024fc:	411c                	lw	a5,0(a0)
ffffffffc02024fe:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202502:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202504:	cb11                	beqz	a4,ffffffffc0202518 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202506:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020250a:	12048073          	sfence.vma	s1
}
ffffffffc020250e:	70a2                	ld	ra,40(sp)
ffffffffc0202510:	7402                	ld	s0,32(sp)
ffffffffc0202512:	64e2                	ld	s1,24(sp)
ffffffffc0202514:	6145                	addi	sp,sp,48
ffffffffc0202516:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202518:	100027f3          	csrr	a5,sstatus
ffffffffc020251c:	8b89                	andi	a5,a5,2
ffffffffc020251e:	eb89                	bnez	a5,ffffffffc0202530 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202520:	000d0797          	auipc	a5,0xd0
ffffffffc0202524:	af87b783          	ld	a5,-1288(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0202528:	739c                	ld	a5,32(a5)
ffffffffc020252a:	4585                	li	a1,1
ffffffffc020252c:	9782                	jalr	a5
    if (flag)
ffffffffc020252e:	bfe1                	j	ffffffffc0202506 <page_remove+0x52>
        intr_disable();
ffffffffc0202530:	e42a                	sd	a0,8(sp)
ffffffffc0202532:	c7cfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202536:	000d0797          	auipc	a5,0xd0
ffffffffc020253a:	ae27b783          	ld	a5,-1310(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc020253e:	739c                	ld	a5,32(a5)
ffffffffc0202540:	6522                	ld	a0,8(sp)
ffffffffc0202542:	4585                	li	a1,1
ffffffffc0202544:	9782                	jalr	a5
        intr_enable();
ffffffffc0202546:	c62fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020254a:	bf75                	j	ffffffffc0202506 <page_remove+0x52>
ffffffffc020254c:	825ff0ef          	jal	ra,ffffffffc0201d70 <pa2page.part.0>

ffffffffc0202550 <page_insert>:
{
ffffffffc0202550:	7139                	addi	sp,sp,-64
ffffffffc0202552:	e852                	sd	s4,16(sp)
ffffffffc0202554:	8a32                	mv	s4,a2
ffffffffc0202556:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202558:	4605                	li	a2,1
{
ffffffffc020255a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020255c:	85d2                	mv	a1,s4
{
ffffffffc020255e:	f426                	sd	s1,40(sp)
ffffffffc0202560:	fc06                	sd	ra,56(sp)
ffffffffc0202562:	f04a                	sd	s2,32(sp)
ffffffffc0202564:	ec4e                	sd	s3,24(sp)
ffffffffc0202566:	e456                	sd	s5,8(sp)
ffffffffc0202568:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020256a:	8f7ff0ef          	jal	ra,ffffffffc0201e60 <get_pte>
    if (ptep == NULL)
ffffffffc020256e:	c961                	beqz	a0,ffffffffc020263e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202570:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202572:	611c                	ld	a5,0(a0)
ffffffffc0202574:	89aa                	mv	s3,a0
ffffffffc0202576:	0016871b          	addiw	a4,a3,1
ffffffffc020257a:	c018                	sw	a4,0(s0)
ffffffffc020257c:	0017f713          	andi	a4,a5,1
ffffffffc0202580:	ef05                	bnez	a4,ffffffffc02025b8 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202582:	000d0717          	auipc	a4,0xd0
ffffffffc0202586:	a8e73703          	ld	a4,-1394(a4) # ffffffffc02d2010 <pages>
ffffffffc020258a:	8c19                	sub	s0,s0,a4
ffffffffc020258c:	000807b7          	lui	a5,0x80
ffffffffc0202590:	8419                	srai	s0,s0,0x6
ffffffffc0202592:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202594:	042a                	slli	s0,s0,0xa
ffffffffc0202596:	8cc1                	or	s1,s1,s0
ffffffffc0202598:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020259c:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38f8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025a0:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02025a4:	4501                	li	a0,0
}
ffffffffc02025a6:	70e2                	ld	ra,56(sp)
ffffffffc02025a8:	7442                	ld	s0,48(sp)
ffffffffc02025aa:	74a2                	ld	s1,40(sp)
ffffffffc02025ac:	7902                	ld	s2,32(sp)
ffffffffc02025ae:	69e2                	ld	s3,24(sp)
ffffffffc02025b0:	6a42                	ld	s4,16(sp)
ffffffffc02025b2:	6aa2                	ld	s5,8(sp)
ffffffffc02025b4:	6121                	addi	sp,sp,64
ffffffffc02025b6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02025b8:	078a                	slli	a5,a5,0x2
ffffffffc02025ba:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025bc:	000d0717          	auipc	a4,0xd0
ffffffffc02025c0:	a4c73703          	ld	a4,-1460(a4) # ffffffffc02d2008 <npage>
ffffffffc02025c4:	06e7ff63          	bgeu	a5,a4,ffffffffc0202642 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02025c8:	000d0a97          	auipc	s5,0xd0
ffffffffc02025cc:	a48a8a93          	addi	s5,s5,-1464 # ffffffffc02d2010 <pages>
ffffffffc02025d0:	000ab703          	ld	a4,0(s5)
ffffffffc02025d4:	fff80937          	lui	s2,0xfff80
ffffffffc02025d8:	993e                	add	s2,s2,a5
ffffffffc02025da:	091a                	slli	s2,s2,0x6
ffffffffc02025dc:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02025de:	01240c63          	beq	s0,s2,ffffffffc02025f6 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02025e2:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcadfa8>
ffffffffc02025e6:	fff7869b          	addiw	a3,a5,-1
ffffffffc02025ea:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02025ee:	c691                	beqz	a3,ffffffffc02025fa <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025f0:	120a0073          	sfence.vma	s4
}
ffffffffc02025f4:	bf59                	j	ffffffffc020258a <page_insert+0x3a>
ffffffffc02025f6:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02025f8:	bf49                	j	ffffffffc020258a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025fa:	100027f3          	csrr	a5,sstatus
ffffffffc02025fe:	8b89                	andi	a5,a5,2
ffffffffc0202600:	ef91                	bnez	a5,ffffffffc020261c <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202602:	000d0797          	auipc	a5,0xd0
ffffffffc0202606:	a167b783          	ld	a5,-1514(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc020260a:	739c                	ld	a5,32(a5)
ffffffffc020260c:	4585                	li	a1,1
ffffffffc020260e:	854a                	mv	a0,s2
ffffffffc0202610:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202612:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202616:	120a0073          	sfence.vma	s4
ffffffffc020261a:	bf85                	j	ffffffffc020258a <page_insert+0x3a>
        intr_disable();
ffffffffc020261c:	b92fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202620:	000d0797          	auipc	a5,0xd0
ffffffffc0202624:	9f87b783          	ld	a5,-1544(a5) # ffffffffc02d2018 <pmm_manager>
ffffffffc0202628:	739c                	ld	a5,32(a5)
ffffffffc020262a:	4585                	li	a1,1
ffffffffc020262c:	854a                	mv	a0,s2
ffffffffc020262e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202630:	b78fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202634:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202638:	120a0073          	sfence.vma	s4
ffffffffc020263c:	b7b9                	j	ffffffffc020258a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020263e:	5571                	li	a0,-4
ffffffffc0202640:	b79d                	j	ffffffffc02025a6 <page_insert+0x56>
ffffffffc0202642:	f2eff0ef          	jal	ra,ffffffffc0201d70 <pa2page.part.0>

ffffffffc0202646 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202646:	00004797          	auipc	a5,0x4
ffffffffc020264a:	07a78793          	addi	a5,a5,122 # ffffffffc02066c0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020264e:	638c                	ld	a1,0(a5)
{
ffffffffc0202650:	7159                	addi	sp,sp,-112
ffffffffc0202652:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202654:	00004517          	auipc	a0,0x4
ffffffffc0202658:	21450513          	addi	a0,a0,532 # ffffffffc0206868 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc020265c:	000d0b17          	auipc	s6,0xd0
ffffffffc0202660:	9bcb0b13          	addi	s6,s6,-1604 # ffffffffc02d2018 <pmm_manager>
{
ffffffffc0202664:	f486                	sd	ra,104(sp)
ffffffffc0202666:	e8ca                	sd	s2,80(sp)
ffffffffc0202668:	e4ce                	sd	s3,72(sp)
ffffffffc020266a:	f0a2                	sd	s0,96(sp)
ffffffffc020266c:	eca6                	sd	s1,88(sp)
ffffffffc020266e:	e0d2                	sd	s4,64(sp)
ffffffffc0202670:	fc56                	sd	s5,56(sp)
ffffffffc0202672:	f45e                	sd	s7,40(sp)
ffffffffc0202674:	f062                	sd	s8,32(sp)
ffffffffc0202676:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202678:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020267c:	b1dfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc0202680:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202684:	000d0997          	auipc	s3,0xd0
ffffffffc0202688:	99c98993          	addi	s3,s3,-1636 # ffffffffc02d2020 <va_pa_offset>
    pmm_manager->init();
ffffffffc020268c:	679c                	ld	a5,8(a5)
ffffffffc020268e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202690:	57f5                	li	a5,-3
ffffffffc0202692:	07fa                	slli	a5,a5,0x1e
ffffffffc0202694:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202698:	afcfe0ef          	jal	ra,ffffffffc0200994 <get_memory_base>
ffffffffc020269c:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020269e:	b00fe0ef          	jal	ra,ffffffffc020099e <get_memory_size>
    if (mem_size == 0)
ffffffffc02026a2:	200505e3          	beqz	a0,ffffffffc02030ac <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02026a6:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02026a8:	00004517          	auipc	a0,0x4
ffffffffc02026ac:	1f850513          	addi	a0,a0,504 # ffffffffc02068a0 <default_pmm_manager+0x1e0>
ffffffffc02026b0:	ae9fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02026b4:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02026b8:	fff40693          	addi	a3,s0,-1
ffffffffc02026bc:	864a                	mv	a2,s2
ffffffffc02026be:	85a6                	mv	a1,s1
ffffffffc02026c0:	00004517          	auipc	a0,0x4
ffffffffc02026c4:	1f850513          	addi	a0,a0,504 # ffffffffc02068b8 <default_pmm_manager+0x1f8>
ffffffffc02026c8:	ad1fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02026cc:	c8000737          	lui	a4,0xc8000
ffffffffc02026d0:	87a2                	mv	a5,s0
ffffffffc02026d2:	54876163          	bltu	a4,s0,ffffffffc0202c14 <pmm_init+0x5ce>
ffffffffc02026d6:	757d                	lui	a0,0xfffff
ffffffffc02026d8:	000d1617          	auipc	a2,0xd1
ffffffffc02026dc:	97f60613          	addi	a2,a2,-1665 # ffffffffc02d3057 <end+0xfff>
ffffffffc02026e0:	8e69                	and	a2,a2,a0
ffffffffc02026e2:	000d0497          	auipc	s1,0xd0
ffffffffc02026e6:	92648493          	addi	s1,s1,-1754 # ffffffffc02d2008 <npage>
ffffffffc02026ea:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026ee:	000d0b97          	auipc	s7,0xd0
ffffffffc02026f2:	922b8b93          	addi	s7,s7,-1758 # ffffffffc02d2010 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02026f6:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026f8:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026fc:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202700:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202702:	02f50863          	beq	a0,a5,ffffffffc0202732 <pmm_init+0xec>
ffffffffc0202706:	4781                	li	a5,0
ffffffffc0202708:	4585                	li	a1,1
ffffffffc020270a:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020270e:	00679513          	slli	a0,a5,0x6
ffffffffc0202712:	9532                	add	a0,a0,a2
ffffffffc0202714:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd2cfb0>
ffffffffc0202718:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020271c:	6088                	ld	a0,0(s1)
ffffffffc020271e:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202720:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202724:	00d50733          	add	a4,a0,a3
ffffffffc0202728:	fee7e3e3          	bltu	a5,a4,ffffffffc020270e <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020272c:	071a                	slli	a4,a4,0x6
ffffffffc020272e:	00e606b3          	add	a3,a2,a4
ffffffffc0202732:	c02007b7          	lui	a5,0xc0200
ffffffffc0202736:	2ef6ece3          	bltu	a3,a5,ffffffffc020322e <pmm_init+0xbe8>
ffffffffc020273a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020273e:	77fd                	lui	a5,0xfffff
ffffffffc0202740:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202742:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202744:	5086eb63          	bltu	a3,s0,ffffffffc0202c5a <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202748:	00004517          	auipc	a0,0x4
ffffffffc020274c:	19850513          	addi	a0,a0,408 # ffffffffc02068e0 <default_pmm_manager+0x220>
ffffffffc0202750:	a49fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202754:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202758:	000d0917          	auipc	s2,0xd0
ffffffffc020275c:	8a890913          	addi	s2,s2,-1880 # ffffffffc02d2000 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202760:	7b9c                	ld	a5,48(a5)
ffffffffc0202762:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202764:	00004517          	auipc	a0,0x4
ffffffffc0202768:	19450513          	addi	a0,a0,404 # ffffffffc02068f8 <default_pmm_manager+0x238>
ffffffffc020276c:	a2dfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202770:	00009697          	auipc	a3,0x9
ffffffffc0202774:	89068693          	addi	a3,a3,-1904 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202778:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020277c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202780:	28f6ebe3          	bltu	a3,a5,ffffffffc0203216 <pmm_init+0xbd0>
ffffffffc0202784:	0009b783          	ld	a5,0(s3)
ffffffffc0202788:	8e9d                	sub	a3,a3,a5
ffffffffc020278a:	000d0797          	auipc	a5,0xd0
ffffffffc020278e:	86d7b723          	sd	a3,-1938(a5) # ffffffffc02d1ff8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202792:	100027f3          	csrr	a5,sstatus
ffffffffc0202796:	8b89                	andi	a5,a5,2
ffffffffc0202798:	4a079763          	bnez	a5,ffffffffc0202c46 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc020279c:	000b3783          	ld	a5,0(s6)
ffffffffc02027a0:	779c                	ld	a5,40(a5)
ffffffffc02027a2:	9782                	jalr	a5
ffffffffc02027a4:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027a6:	6098                	ld	a4,0(s1)
ffffffffc02027a8:	c80007b7          	lui	a5,0xc8000
ffffffffc02027ac:	83b1                	srli	a5,a5,0xc
ffffffffc02027ae:	66e7e363          	bltu	a5,a4,ffffffffc0202e14 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02027b2:	00093503          	ld	a0,0(s2)
ffffffffc02027b6:	62050f63          	beqz	a0,ffffffffc0202df4 <pmm_init+0x7ae>
ffffffffc02027ba:	03451793          	slli	a5,a0,0x34
ffffffffc02027be:	62079b63          	bnez	a5,ffffffffc0202df4 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02027c2:	4601                	li	a2,0
ffffffffc02027c4:	4581                	li	a1,0
ffffffffc02027c6:	8c3ff0ef          	jal	ra,ffffffffc0202088 <get_page>
ffffffffc02027ca:	60051563          	bnez	a0,ffffffffc0202dd4 <pmm_init+0x78e>
ffffffffc02027ce:	100027f3          	csrr	a5,sstatus
ffffffffc02027d2:	8b89                	andi	a5,a5,2
ffffffffc02027d4:	44079e63          	bnez	a5,ffffffffc0202c30 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027d8:	000b3783          	ld	a5,0(s6)
ffffffffc02027dc:	4505                	li	a0,1
ffffffffc02027de:	6f9c                	ld	a5,24(a5)
ffffffffc02027e0:	9782                	jalr	a5
ffffffffc02027e2:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02027e4:	00093503          	ld	a0,0(s2)
ffffffffc02027e8:	4681                	li	a3,0
ffffffffc02027ea:	4601                	li	a2,0
ffffffffc02027ec:	85d2                	mv	a1,s4
ffffffffc02027ee:	d63ff0ef          	jal	ra,ffffffffc0202550 <page_insert>
ffffffffc02027f2:	26051ae3          	bnez	a0,ffffffffc0203266 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02027f6:	00093503          	ld	a0,0(s2)
ffffffffc02027fa:	4601                	li	a2,0
ffffffffc02027fc:	4581                	li	a1,0
ffffffffc02027fe:	e62ff0ef          	jal	ra,ffffffffc0201e60 <get_pte>
ffffffffc0202802:	240502e3          	beqz	a0,ffffffffc0203246 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202806:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202808:	0017f713          	andi	a4,a5,1
ffffffffc020280c:	5a070263          	beqz	a4,ffffffffc0202db0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202810:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202812:	078a                	slli	a5,a5,0x2
ffffffffc0202814:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202816:	58e7fb63          	bgeu	a5,a4,ffffffffc0202dac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020281a:	000bb683          	ld	a3,0(s7)
ffffffffc020281e:	fff80637          	lui	a2,0xfff80
ffffffffc0202822:	97b2                	add	a5,a5,a2
ffffffffc0202824:	079a                	slli	a5,a5,0x6
ffffffffc0202826:	97b6                	add	a5,a5,a3
ffffffffc0202828:	14fa17e3          	bne	s4,a5,ffffffffc0203176 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc020282c:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f30>
ffffffffc0202830:	4785                	li	a5,1
ffffffffc0202832:	12f692e3          	bne	a3,a5,ffffffffc0203156 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202836:	00093503          	ld	a0,0(s2)
ffffffffc020283a:	77fd                	lui	a5,0xfffff
ffffffffc020283c:	6114                	ld	a3,0(a0)
ffffffffc020283e:	068a                	slli	a3,a3,0x2
ffffffffc0202840:	8efd                	and	a3,a3,a5
ffffffffc0202842:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202846:	0ee67ce3          	bgeu	a2,a4,ffffffffc020313e <pmm_init+0xaf8>
ffffffffc020284a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020284e:	96e2                	add	a3,a3,s8
ffffffffc0202850:	0006ba83          	ld	s5,0(a3)
ffffffffc0202854:	0a8a                	slli	s5,s5,0x2
ffffffffc0202856:	00fafab3          	and	s5,s5,a5
ffffffffc020285a:	00cad793          	srli	a5,s5,0xc
ffffffffc020285e:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203124 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202862:	4601                	li	a2,0
ffffffffc0202864:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202866:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202868:	df8ff0ef          	jal	ra,ffffffffc0201e60 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020286c:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020286e:	55551363          	bne	a0,s5,ffffffffc0202db4 <pmm_init+0x76e>
ffffffffc0202872:	100027f3          	csrr	a5,sstatus
ffffffffc0202876:	8b89                	andi	a5,a5,2
ffffffffc0202878:	3a079163          	bnez	a5,ffffffffc0202c1a <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020287c:	000b3783          	ld	a5,0(s6)
ffffffffc0202880:	4505                	li	a0,1
ffffffffc0202882:	6f9c                	ld	a5,24(a5)
ffffffffc0202884:	9782                	jalr	a5
ffffffffc0202886:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202888:	00093503          	ld	a0,0(s2)
ffffffffc020288c:	46d1                	li	a3,20
ffffffffc020288e:	6605                	lui	a2,0x1
ffffffffc0202890:	85e2                	mv	a1,s8
ffffffffc0202892:	cbfff0ef          	jal	ra,ffffffffc0202550 <page_insert>
ffffffffc0202896:	060517e3          	bnez	a0,ffffffffc0203104 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020289a:	00093503          	ld	a0,0(s2)
ffffffffc020289e:	4601                	li	a2,0
ffffffffc02028a0:	6585                	lui	a1,0x1
ffffffffc02028a2:	dbeff0ef          	jal	ra,ffffffffc0201e60 <get_pte>
ffffffffc02028a6:	02050fe3          	beqz	a0,ffffffffc02030e4 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02028aa:	611c                	ld	a5,0(a0)
ffffffffc02028ac:	0107f713          	andi	a4,a5,16
ffffffffc02028b0:	7c070e63          	beqz	a4,ffffffffc020308c <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02028b4:	8b91                	andi	a5,a5,4
ffffffffc02028b6:	7a078b63          	beqz	a5,ffffffffc020306c <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02028ba:	00093503          	ld	a0,0(s2)
ffffffffc02028be:	611c                	ld	a5,0(a0)
ffffffffc02028c0:	8bc1                	andi	a5,a5,16
ffffffffc02028c2:	78078563          	beqz	a5,ffffffffc020304c <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02028c6:	000c2703          	lw	a4,0(s8)
ffffffffc02028ca:	4785                	li	a5,1
ffffffffc02028cc:	76f71063          	bne	a4,a5,ffffffffc020302c <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02028d0:	4681                	li	a3,0
ffffffffc02028d2:	6605                	lui	a2,0x1
ffffffffc02028d4:	85d2                	mv	a1,s4
ffffffffc02028d6:	c7bff0ef          	jal	ra,ffffffffc0202550 <page_insert>
ffffffffc02028da:	72051963          	bnez	a0,ffffffffc020300c <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02028de:	000a2703          	lw	a4,0(s4)
ffffffffc02028e2:	4789                	li	a5,2
ffffffffc02028e4:	70f71463          	bne	a4,a5,ffffffffc0202fec <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02028e8:	000c2783          	lw	a5,0(s8)
ffffffffc02028ec:	6e079063          	bnez	a5,ffffffffc0202fcc <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02028f0:	00093503          	ld	a0,0(s2)
ffffffffc02028f4:	4601                	li	a2,0
ffffffffc02028f6:	6585                	lui	a1,0x1
ffffffffc02028f8:	d68ff0ef          	jal	ra,ffffffffc0201e60 <get_pte>
ffffffffc02028fc:	6a050863          	beqz	a0,ffffffffc0202fac <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202900:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202902:	00177793          	andi	a5,a4,1
ffffffffc0202906:	4a078563          	beqz	a5,ffffffffc0202db0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020290a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020290c:	00271793          	slli	a5,a4,0x2
ffffffffc0202910:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202912:	48d7fd63          	bgeu	a5,a3,ffffffffc0202dac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202916:	000bb683          	ld	a3,0(s7)
ffffffffc020291a:	fff80ab7          	lui	s5,0xfff80
ffffffffc020291e:	97d6                	add	a5,a5,s5
ffffffffc0202920:	079a                	slli	a5,a5,0x6
ffffffffc0202922:	97b6                	add	a5,a5,a3
ffffffffc0202924:	66fa1463          	bne	s4,a5,ffffffffc0202f8c <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202928:	8b41                	andi	a4,a4,16
ffffffffc020292a:	64071163          	bnez	a4,ffffffffc0202f6c <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020292e:	00093503          	ld	a0,0(s2)
ffffffffc0202932:	4581                	li	a1,0
ffffffffc0202934:	b81ff0ef          	jal	ra,ffffffffc02024b4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202938:	000a2c83          	lw	s9,0(s4)
ffffffffc020293c:	4785                	li	a5,1
ffffffffc020293e:	60fc9763          	bne	s9,a5,ffffffffc0202f4c <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202942:	000c2783          	lw	a5,0(s8)
ffffffffc0202946:	5e079363          	bnez	a5,ffffffffc0202f2c <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020294a:	00093503          	ld	a0,0(s2)
ffffffffc020294e:	6585                	lui	a1,0x1
ffffffffc0202950:	b65ff0ef          	jal	ra,ffffffffc02024b4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202954:	000a2783          	lw	a5,0(s4)
ffffffffc0202958:	52079a63          	bnez	a5,ffffffffc0202e8c <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc020295c:	000c2783          	lw	a5,0(s8)
ffffffffc0202960:	50079663          	bnez	a5,ffffffffc0202e6c <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202964:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202968:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020296a:	000a3683          	ld	a3,0(s4)
ffffffffc020296e:	068a                	slli	a3,a3,0x2
ffffffffc0202970:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202972:	42b6fd63          	bgeu	a3,a1,ffffffffc0202dac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202976:	000bb503          	ld	a0,0(s7)
ffffffffc020297a:	96d6                	add	a3,a3,s5
ffffffffc020297c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020297e:	00d507b3          	add	a5,a0,a3
ffffffffc0202982:	439c                	lw	a5,0(a5)
ffffffffc0202984:	4d979463          	bne	a5,s9,ffffffffc0202e4c <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202988:	8699                	srai	a3,a3,0x6
ffffffffc020298a:	00080637          	lui	a2,0x80
ffffffffc020298e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202990:	00c69713          	slli	a4,a3,0xc
ffffffffc0202994:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202996:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202998:	48b77e63          	bgeu	a4,a1,ffffffffc0202e34 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020299c:	0009b703          	ld	a4,0(s3)
ffffffffc02029a0:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc02029a2:	629c                	ld	a5,0(a3)
ffffffffc02029a4:	078a                	slli	a5,a5,0x2
ffffffffc02029a6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029a8:	40b7f263          	bgeu	a5,a1,ffffffffc0202dac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029ac:	8f91                	sub	a5,a5,a2
ffffffffc02029ae:	079a                	slli	a5,a5,0x6
ffffffffc02029b0:	953e                	add	a0,a0,a5
ffffffffc02029b2:	100027f3          	csrr	a5,sstatus
ffffffffc02029b6:	8b89                	andi	a5,a5,2
ffffffffc02029b8:	30079963          	bnez	a5,ffffffffc0202cca <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc02029bc:	000b3783          	ld	a5,0(s6)
ffffffffc02029c0:	4585                	li	a1,1
ffffffffc02029c2:	739c                	ld	a5,32(a5)
ffffffffc02029c4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02029c6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02029ca:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02029cc:	078a                	slli	a5,a5,0x2
ffffffffc02029ce:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029d0:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202dac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029d4:	000bb503          	ld	a0,0(s7)
ffffffffc02029d8:	fff80737          	lui	a4,0xfff80
ffffffffc02029dc:	97ba                	add	a5,a5,a4
ffffffffc02029de:	079a                	slli	a5,a5,0x6
ffffffffc02029e0:	953e                	add	a0,a0,a5
ffffffffc02029e2:	100027f3          	csrr	a5,sstatus
ffffffffc02029e6:	8b89                	andi	a5,a5,2
ffffffffc02029e8:	2c079563          	bnez	a5,ffffffffc0202cb2 <pmm_init+0x66c>
ffffffffc02029ec:	000b3783          	ld	a5,0(s6)
ffffffffc02029f0:	4585                	li	a1,1
ffffffffc02029f2:	739c                	ld	a5,32(a5)
ffffffffc02029f4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02029f6:	00093783          	ld	a5,0(s2)
ffffffffc02029fa:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd2cfa8>
    asm volatile("sfence.vma");
ffffffffc02029fe:	12000073          	sfence.vma
ffffffffc0202a02:	100027f3          	csrr	a5,sstatus
ffffffffc0202a06:	8b89                	andi	a5,a5,2
ffffffffc0202a08:	28079b63          	bnez	a5,ffffffffc0202c9e <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a0c:	000b3783          	ld	a5,0(s6)
ffffffffc0202a10:	779c                	ld	a5,40(a5)
ffffffffc0202a12:	9782                	jalr	a5
ffffffffc0202a14:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202a16:	4b441b63          	bne	s0,s4,ffffffffc0202ecc <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202a1a:	00004517          	auipc	a0,0x4
ffffffffc0202a1e:	20650513          	addi	a0,a0,518 # ffffffffc0206c20 <default_pmm_manager+0x560>
ffffffffc0202a22:	f76fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0202a26:	100027f3          	csrr	a5,sstatus
ffffffffc0202a2a:	8b89                	andi	a5,a5,2
ffffffffc0202a2c:	24079f63          	bnez	a5,ffffffffc0202c8a <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a30:	000b3783          	ld	a5,0(s6)
ffffffffc0202a34:	779c                	ld	a5,40(a5)
ffffffffc0202a36:	9782                	jalr	a5
ffffffffc0202a38:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a3a:	6098                	ld	a4,0(s1)
ffffffffc0202a3c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a40:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a42:	00c71793          	slli	a5,a4,0xc
ffffffffc0202a46:	6a05                	lui	s4,0x1
ffffffffc0202a48:	02f47c63          	bgeu	s0,a5,ffffffffc0202a80 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202a4c:	00c45793          	srli	a5,s0,0xc
ffffffffc0202a50:	00093503          	ld	a0,0(s2)
ffffffffc0202a54:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202d52 <pmm_init+0x70c>
ffffffffc0202a58:	0009b583          	ld	a1,0(s3)
ffffffffc0202a5c:	4601                	li	a2,0
ffffffffc0202a5e:	95a2                	add	a1,a1,s0
ffffffffc0202a60:	c00ff0ef          	jal	ra,ffffffffc0201e60 <get_pte>
ffffffffc0202a64:	32050463          	beqz	a0,ffffffffc0202d8c <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a68:	611c                	ld	a5,0(a0)
ffffffffc0202a6a:	078a                	slli	a5,a5,0x2
ffffffffc0202a6c:	0157f7b3          	and	a5,a5,s5
ffffffffc0202a70:	2e879e63          	bne	a5,s0,ffffffffc0202d6c <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a74:	6098                	ld	a4,0(s1)
ffffffffc0202a76:	9452                	add	s0,s0,s4
ffffffffc0202a78:	00c71793          	slli	a5,a4,0xc
ffffffffc0202a7c:	fcf468e3          	bltu	s0,a5,ffffffffc0202a4c <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202a80:	00093783          	ld	a5,0(s2)
ffffffffc0202a84:	639c                	ld	a5,0(a5)
ffffffffc0202a86:	42079363          	bnez	a5,ffffffffc0202eac <pmm_init+0x866>
ffffffffc0202a8a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a8e:	8b89                	andi	a5,a5,2
ffffffffc0202a90:	24079963          	bnez	a5,ffffffffc0202ce2 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a94:	000b3783          	ld	a5,0(s6)
ffffffffc0202a98:	4505                	li	a0,1
ffffffffc0202a9a:	6f9c                	ld	a5,24(a5)
ffffffffc0202a9c:	9782                	jalr	a5
ffffffffc0202a9e:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202aa0:	00093503          	ld	a0,0(s2)
ffffffffc0202aa4:	4699                	li	a3,6
ffffffffc0202aa6:	10000613          	li	a2,256
ffffffffc0202aaa:	85d2                	mv	a1,s4
ffffffffc0202aac:	aa5ff0ef          	jal	ra,ffffffffc0202550 <page_insert>
ffffffffc0202ab0:	44051e63          	bnez	a0,ffffffffc0202f0c <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202ab4:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f30>
ffffffffc0202ab8:	4785                	li	a5,1
ffffffffc0202aba:	42f71963          	bne	a4,a5,ffffffffc0202eec <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202abe:	00093503          	ld	a0,0(s2)
ffffffffc0202ac2:	6405                	lui	s0,0x1
ffffffffc0202ac4:	4699                	li	a3,6
ffffffffc0202ac6:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8e30>
ffffffffc0202aca:	85d2                	mv	a1,s4
ffffffffc0202acc:	a85ff0ef          	jal	ra,ffffffffc0202550 <page_insert>
ffffffffc0202ad0:	72051363          	bnez	a0,ffffffffc02031f6 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202ad4:	000a2703          	lw	a4,0(s4)
ffffffffc0202ad8:	4789                	li	a5,2
ffffffffc0202ada:	6ef71e63          	bne	a4,a5,ffffffffc02031d6 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202ade:	00004597          	auipc	a1,0x4
ffffffffc0202ae2:	28a58593          	addi	a1,a1,650 # ffffffffc0206d68 <default_pmm_manager+0x6a8>
ffffffffc0202ae6:	10000513          	li	a0,256
ffffffffc0202aea:	4fb020ef          	jal	ra,ffffffffc02057e4 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202aee:	10040593          	addi	a1,s0,256
ffffffffc0202af2:	10000513          	li	a0,256
ffffffffc0202af6:	501020ef          	jal	ra,ffffffffc02057f6 <strcmp>
ffffffffc0202afa:	6a051e63          	bnez	a0,ffffffffc02031b6 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202afe:	000bb683          	ld	a3,0(s7)
ffffffffc0202b02:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202b06:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202b08:	40da06b3          	sub	a3,s4,a3
ffffffffc0202b0c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202b0e:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202b10:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202b12:	8031                	srli	s0,s0,0xc
ffffffffc0202b14:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b18:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b1a:	30f77d63          	bgeu	a4,a5,ffffffffc0202e34 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b1e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b22:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b26:	96be                	add	a3,a3,a5
ffffffffc0202b28:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b2c:	483020ef          	jal	ra,ffffffffc02057ae <strlen>
ffffffffc0202b30:	66051363          	bnez	a0,ffffffffc0203196 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202b34:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b38:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b3a:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd2cfa8>
ffffffffc0202b3e:	068a                	slli	a3,a3,0x2
ffffffffc0202b40:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b42:	26f6f563          	bgeu	a3,a5,ffffffffc0202dac <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202b46:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b48:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b4a:	2ef47563          	bgeu	s0,a5,ffffffffc0202e34 <pmm_init+0x7ee>
ffffffffc0202b4e:	0009b403          	ld	s0,0(s3)
ffffffffc0202b52:	9436                	add	s0,s0,a3
ffffffffc0202b54:	100027f3          	csrr	a5,sstatus
ffffffffc0202b58:	8b89                	andi	a5,a5,2
ffffffffc0202b5a:	1e079163          	bnez	a5,ffffffffc0202d3c <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202b5e:	000b3783          	ld	a5,0(s6)
ffffffffc0202b62:	4585                	li	a1,1
ffffffffc0202b64:	8552                	mv	a0,s4
ffffffffc0202b66:	739c                	ld	a5,32(a5)
ffffffffc0202b68:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b6a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202b6c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b6e:	078a                	slli	a5,a5,0x2
ffffffffc0202b70:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b72:	22e7fd63          	bgeu	a5,a4,ffffffffc0202dac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b76:	000bb503          	ld	a0,0(s7)
ffffffffc0202b7a:	fff80737          	lui	a4,0xfff80
ffffffffc0202b7e:	97ba                	add	a5,a5,a4
ffffffffc0202b80:	079a                	slli	a5,a5,0x6
ffffffffc0202b82:	953e                	add	a0,a0,a5
ffffffffc0202b84:	100027f3          	csrr	a5,sstatus
ffffffffc0202b88:	8b89                	andi	a5,a5,2
ffffffffc0202b8a:	18079d63          	bnez	a5,ffffffffc0202d24 <pmm_init+0x6de>
ffffffffc0202b8e:	000b3783          	ld	a5,0(s6)
ffffffffc0202b92:	4585                	li	a1,1
ffffffffc0202b94:	739c                	ld	a5,32(a5)
ffffffffc0202b96:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b98:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202b9c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b9e:	078a                	slli	a5,a5,0x2
ffffffffc0202ba0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ba2:	20e7f563          	bgeu	a5,a4,ffffffffc0202dac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ba6:	000bb503          	ld	a0,0(s7)
ffffffffc0202baa:	fff80737          	lui	a4,0xfff80
ffffffffc0202bae:	97ba                	add	a5,a5,a4
ffffffffc0202bb0:	079a                	slli	a5,a5,0x6
ffffffffc0202bb2:	953e                	add	a0,a0,a5
ffffffffc0202bb4:	100027f3          	csrr	a5,sstatus
ffffffffc0202bb8:	8b89                	andi	a5,a5,2
ffffffffc0202bba:	14079963          	bnez	a5,ffffffffc0202d0c <pmm_init+0x6c6>
ffffffffc0202bbe:	000b3783          	ld	a5,0(s6)
ffffffffc0202bc2:	4585                	li	a1,1
ffffffffc0202bc4:	739c                	ld	a5,32(a5)
ffffffffc0202bc6:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202bc8:	00093783          	ld	a5,0(s2)
ffffffffc0202bcc:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202bd0:	12000073          	sfence.vma
ffffffffc0202bd4:	100027f3          	csrr	a5,sstatus
ffffffffc0202bd8:	8b89                	andi	a5,a5,2
ffffffffc0202bda:	10079f63          	bnez	a5,ffffffffc0202cf8 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bde:	000b3783          	ld	a5,0(s6)
ffffffffc0202be2:	779c                	ld	a5,40(a5)
ffffffffc0202be4:	9782                	jalr	a5
ffffffffc0202be6:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202be8:	4c8c1e63          	bne	s8,s0,ffffffffc02030c4 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202bec:	00004517          	auipc	a0,0x4
ffffffffc0202bf0:	1f450513          	addi	a0,a0,500 # ffffffffc0206de0 <default_pmm_manager+0x720>
ffffffffc0202bf4:	da4fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0202bf8:	7406                	ld	s0,96(sp)
ffffffffc0202bfa:	70a6                	ld	ra,104(sp)
ffffffffc0202bfc:	64e6                	ld	s1,88(sp)
ffffffffc0202bfe:	6946                	ld	s2,80(sp)
ffffffffc0202c00:	69a6                	ld	s3,72(sp)
ffffffffc0202c02:	6a06                	ld	s4,64(sp)
ffffffffc0202c04:	7ae2                	ld	s5,56(sp)
ffffffffc0202c06:	7b42                	ld	s6,48(sp)
ffffffffc0202c08:	7ba2                	ld	s7,40(sp)
ffffffffc0202c0a:	7c02                	ld	s8,32(sp)
ffffffffc0202c0c:	6ce2                	ld	s9,24(sp)
ffffffffc0202c0e:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202c10:	f97fe06f          	j	ffffffffc0201ba6 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202c14:	c80007b7          	lui	a5,0xc8000
ffffffffc0202c18:	bc7d                	j	ffffffffc02026d6 <pmm_init+0x90>
        intr_disable();
ffffffffc0202c1a:	d95fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c1e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c22:	4505                	li	a0,1
ffffffffc0202c24:	6f9c                	ld	a5,24(a5)
ffffffffc0202c26:	9782                	jalr	a5
ffffffffc0202c28:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202c2a:	d7ffd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c2e:	b9a9                	j	ffffffffc0202888 <pmm_init+0x242>
        intr_disable();
ffffffffc0202c30:	d7ffd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202c34:	000b3783          	ld	a5,0(s6)
ffffffffc0202c38:	4505                	li	a0,1
ffffffffc0202c3a:	6f9c                	ld	a5,24(a5)
ffffffffc0202c3c:	9782                	jalr	a5
ffffffffc0202c3e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202c40:	d69fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c44:	b645                	j	ffffffffc02027e4 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202c46:	d69fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c4a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c4e:	779c                	ld	a5,40(a5)
ffffffffc0202c50:	9782                	jalr	a5
ffffffffc0202c52:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202c54:	d55fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c58:	b6b9                	j	ffffffffc02027a6 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202c5a:	6705                	lui	a4,0x1
ffffffffc0202c5c:	177d                	addi	a4,a4,-1
ffffffffc0202c5e:	96ba                	add	a3,a3,a4
ffffffffc0202c60:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202c62:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202c66:	14a77363          	bgeu	a4,a0,ffffffffc0202dac <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202c6a:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202c6e:	fff80537          	lui	a0,0xfff80
ffffffffc0202c72:	972a                	add	a4,a4,a0
ffffffffc0202c74:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202c76:	8c1d                	sub	s0,s0,a5
ffffffffc0202c78:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202c7c:	00c45593          	srli	a1,s0,0xc
ffffffffc0202c80:	9532                	add	a0,a0,a2
ffffffffc0202c82:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202c84:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202c88:	b4c1                	j	ffffffffc0202748 <pmm_init+0x102>
        intr_disable();
ffffffffc0202c8a:	d25fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c8e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c92:	779c                	ld	a5,40(a5)
ffffffffc0202c94:	9782                	jalr	a5
ffffffffc0202c96:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202c98:	d11fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c9c:	bb79                	j	ffffffffc0202a3a <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202c9e:	d11fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202ca2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ca6:	779c                	ld	a5,40(a5)
ffffffffc0202ca8:	9782                	jalr	a5
ffffffffc0202caa:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202cac:	cfdfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cb0:	b39d                	j	ffffffffc0202a16 <pmm_init+0x3d0>
ffffffffc0202cb2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202cb4:	cfbfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202cb8:	000b3783          	ld	a5,0(s6)
ffffffffc0202cbc:	6522                	ld	a0,8(sp)
ffffffffc0202cbe:	4585                	li	a1,1
ffffffffc0202cc0:	739c                	ld	a5,32(a5)
ffffffffc0202cc2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202cc4:	ce5fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cc8:	b33d                	j	ffffffffc02029f6 <pmm_init+0x3b0>
ffffffffc0202cca:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ccc:	ce3fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202cd0:	000b3783          	ld	a5,0(s6)
ffffffffc0202cd4:	6522                	ld	a0,8(sp)
ffffffffc0202cd6:	4585                	li	a1,1
ffffffffc0202cd8:	739c                	ld	a5,32(a5)
ffffffffc0202cda:	9782                	jalr	a5
        intr_enable();
ffffffffc0202cdc:	ccdfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202ce0:	b1dd                	j	ffffffffc02029c6 <pmm_init+0x380>
        intr_disable();
ffffffffc0202ce2:	ccdfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202ce6:	000b3783          	ld	a5,0(s6)
ffffffffc0202cea:	4505                	li	a0,1
ffffffffc0202cec:	6f9c                	ld	a5,24(a5)
ffffffffc0202cee:	9782                	jalr	a5
ffffffffc0202cf0:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202cf2:	cb7fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cf6:	b36d                	j	ffffffffc0202aa0 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202cf8:	cb7fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cfc:	000b3783          	ld	a5,0(s6)
ffffffffc0202d00:	779c                	ld	a5,40(a5)
ffffffffc0202d02:	9782                	jalr	a5
ffffffffc0202d04:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d06:	ca3fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d0a:	bdf9                	j	ffffffffc0202be8 <pmm_init+0x5a2>
ffffffffc0202d0c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d0e:	ca1fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d12:	000b3783          	ld	a5,0(s6)
ffffffffc0202d16:	6522                	ld	a0,8(sp)
ffffffffc0202d18:	4585                	li	a1,1
ffffffffc0202d1a:	739c                	ld	a5,32(a5)
ffffffffc0202d1c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d1e:	c8bfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d22:	b55d                	j	ffffffffc0202bc8 <pmm_init+0x582>
ffffffffc0202d24:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d26:	c89fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d2a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d2e:	6522                	ld	a0,8(sp)
ffffffffc0202d30:	4585                	li	a1,1
ffffffffc0202d32:	739c                	ld	a5,32(a5)
ffffffffc0202d34:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d36:	c73fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d3a:	bdb9                	j	ffffffffc0202b98 <pmm_init+0x552>
        intr_disable();
ffffffffc0202d3c:	c73fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d40:	000b3783          	ld	a5,0(s6)
ffffffffc0202d44:	4585                	li	a1,1
ffffffffc0202d46:	8552                	mv	a0,s4
ffffffffc0202d48:	739c                	ld	a5,32(a5)
ffffffffc0202d4a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d4c:	c5dfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d50:	bd29                	j	ffffffffc0202b6a <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d52:	86a2                	mv	a3,s0
ffffffffc0202d54:	00004617          	auipc	a2,0x4
ffffffffc0202d58:	9a460613          	addi	a2,a2,-1628 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc0202d5c:	25a00593          	li	a1,602
ffffffffc0202d60:	00004517          	auipc	a0,0x4
ffffffffc0202d64:	ab050513          	addi	a0,a0,-1360 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202d68:	f2afd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202d6c:	00004697          	auipc	a3,0x4
ffffffffc0202d70:	f1468693          	addi	a3,a3,-236 # ffffffffc0206c80 <default_pmm_manager+0x5c0>
ffffffffc0202d74:	00003617          	auipc	a2,0x3
ffffffffc0202d78:	59c60613          	addi	a2,a2,1436 # ffffffffc0206310 <commands+0x828>
ffffffffc0202d7c:	25b00593          	li	a1,603
ffffffffc0202d80:	00004517          	auipc	a0,0x4
ffffffffc0202d84:	a9050513          	addi	a0,a0,-1392 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202d88:	f0afd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d8c:	00004697          	auipc	a3,0x4
ffffffffc0202d90:	eb468693          	addi	a3,a3,-332 # ffffffffc0206c40 <default_pmm_manager+0x580>
ffffffffc0202d94:	00003617          	auipc	a2,0x3
ffffffffc0202d98:	57c60613          	addi	a2,a2,1404 # ffffffffc0206310 <commands+0x828>
ffffffffc0202d9c:	25a00593          	li	a1,602
ffffffffc0202da0:	00004517          	auipc	a0,0x4
ffffffffc0202da4:	a7050513          	addi	a0,a0,-1424 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202da8:	eeafd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202dac:	fc5fe0ef          	jal	ra,ffffffffc0201d70 <pa2page.part.0>
ffffffffc0202db0:	fddfe0ef          	jal	ra,ffffffffc0201d8c <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202db4:	00004697          	auipc	a3,0x4
ffffffffc0202db8:	c8468693          	addi	a3,a3,-892 # ffffffffc0206a38 <default_pmm_manager+0x378>
ffffffffc0202dbc:	00003617          	auipc	a2,0x3
ffffffffc0202dc0:	55460613          	addi	a2,a2,1364 # ffffffffc0206310 <commands+0x828>
ffffffffc0202dc4:	22a00593          	li	a1,554
ffffffffc0202dc8:	00004517          	auipc	a0,0x4
ffffffffc0202dcc:	a4850513          	addi	a0,a0,-1464 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202dd0:	ec2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202dd4:	00004697          	auipc	a3,0x4
ffffffffc0202dd8:	ba468693          	addi	a3,a3,-1116 # ffffffffc0206978 <default_pmm_manager+0x2b8>
ffffffffc0202ddc:	00003617          	auipc	a2,0x3
ffffffffc0202de0:	53460613          	addi	a2,a2,1332 # ffffffffc0206310 <commands+0x828>
ffffffffc0202de4:	21d00593          	li	a1,541
ffffffffc0202de8:	00004517          	auipc	a0,0x4
ffffffffc0202dec:	a2850513          	addi	a0,a0,-1496 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202df0:	ea2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202df4:	00004697          	auipc	a3,0x4
ffffffffc0202df8:	b4468693          	addi	a3,a3,-1212 # ffffffffc0206938 <default_pmm_manager+0x278>
ffffffffc0202dfc:	00003617          	auipc	a2,0x3
ffffffffc0202e00:	51460613          	addi	a2,a2,1300 # ffffffffc0206310 <commands+0x828>
ffffffffc0202e04:	21c00593          	li	a1,540
ffffffffc0202e08:	00004517          	auipc	a0,0x4
ffffffffc0202e0c:	a0850513          	addi	a0,a0,-1528 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202e10:	e82fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202e14:	00004697          	auipc	a3,0x4
ffffffffc0202e18:	b0468693          	addi	a3,a3,-1276 # ffffffffc0206918 <default_pmm_manager+0x258>
ffffffffc0202e1c:	00003617          	auipc	a2,0x3
ffffffffc0202e20:	4f460613          	addi	a2,a2,1268 # ffffffffc0206310 <commands+0x828>
ffffffffc0202e24:	21b00593          	li	a1,539
ffffffffc0202e28:	00004517          	auipc	a0,0x4
ffffffffc0202e2c:	9e850513          	addi	a0,a0,-1560 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202e30:	e62fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202e34:	00004617          	auipc	a2,0x4
ffffffffc0202e38:	8c460613          	addi	a2,a2,-1852 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc0202e3c:	07100593          	li	a1,113
ffffffffc0202e40:	00004517          	auipc	a0,0x4
ffffffffc0202e44:	8e050513          	addi	a0,a0,-1824 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc0202e48:	e4afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202e4c:	00004697          	auipc	a3,0x4
ffffffffc0202e50:	d7c68693          	addi	a3,a3,-644 # ffffffffc0206bc8 <default_pmm_manager+0x508>
ffffffffc0202e54:	00003617          	auipc	a2,0x3
ffffffffc0202e58:	4bc60613          	addi	a2,a2,1212 # ffffffffc0206310 <commands+0x828>
ffffffffc0202e5c:	24300593          	li	a1,579
ffffffffc0202e60:	00004517          	auipc	a0,0x4
ffffffffc0202e64:	9b050513          	addi	a0,a0,-1616 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202e68:	e2afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202e6c:	00004697          	auipc	a3,0x4
ffffffffc0202e70:	d1468693          	addi	a3,a3,-748 # ffffffffc0206b80 <default_pmm_manager+0x4c0>
ffffffffc0202e74:	00003617          	auipc	a2,0x3
ffffffffc0202e78:	49c60613          	addi	a2,a2,1180 # ffffffffc0206310 <commands+0x828>
ffffffffc0202e7c:	24100593          	li	a1,577
ffffffffc0202e80:	00004517          	auipc	a0,0x4
ffffffffc0202e84:	99050513          	addi	a0,a0,-1648 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202e88:	e0afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202e8c:	00004697          	auipc	a3,0x4
ffffffffc0202e90:	d2468693          	addi	a3,a3,-732 # ffffffffc0206bb0 <default_pmm_manager+0x4f0>
ffffffffc0202e94:	00003617          	auipc	a2,0x3
ffffffffc0202e98:	47c60613          	addi	a2,a2,1148 # ffffffffc0206310 <commands+0x828>
ffffffffc0202e9c:	24000593          	li	a1,576
ffffffffc0202ea0:	00004517          	auipc	a0,0x4
ffffffffc0202ea4:	97050513          	addi	a0,a0,-1680 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202ea8:	deafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202eac:	00004697          	auipc	a3,0x4
ffffffffc0202eb0:	dec68693          	addi	a3,a3,-532 # ffffffffc0206c98 <default_pmm_manager+0x5d8>
ffffffffc0202eb4:	00003617          	auipc	a2,0x3
ffffffffc0202eb8:	45c60613          	addi	a2,a2,1116 # ffffffffc0206310 <commands+0x828>
ffffffffc0202ebc:	25e00593          	li	a1,606
ffffffffc0202ec0:	00004517          	auipc	a0,0x4
ffffffffc0202ec4:	95050513          	addi	a0,a0,-1712 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202ec8:	dcafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202ecc:	00004697          	auipc	a3,0x4
ffffffffc0202ed0:	d2c68693          	addi	a3,a3,-724 # ffffffffc0206bf8 <default_pmm_manager+0x538>
ffffffffc0202ed4:	00003617          	auipc	a2,0x3
ffffffffc0202ed8:	43c60613          	addi	a2,a2,1084 # ffffffffc0206310 <commands+0x828>
ffffffffc0202edc:	24b00593          	li	a1,587
ffffffffc0202ee0:	00004517          	auipc	a0,0x4
ffffffffc0202ee4:	93050513          	addi	a0,a0,-1744 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202ee8:	daafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202eec:	00004697          	auipc	a3,0x4
ffffffffc0202ef0:	e0468693          	addi	a3,a3,-508 # ffffffffc0206cf0 <default_pmm_manager+0x630>
ffffffffc0202ef4:	00003617          	auipc	a2,0x3
ffffffffc0202ef8:	41c60613          	addi	a2,a2,1052 # ffffffffc0206310 <commands+0x828>
ffffffffc0202efc:	26300593          	li	a1,611
ffffffffc0202f00:	00004517          	auipc	a0,0x4
ffffffffc0202f04:	91050513          	addi	a0,a0,-1776 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202f08:	d8afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202f0c:	00004697          	auipc	a3,0x4
ffffffffc0202f10:	da468693          	addi	a3,a3,-604 # ffffffffc0206cb0 <default_pmm_manager+0x5f0>
ffffffffc0202f14:	00003617          	auipc	a2,0x3
ffffffffc0202f18:	3fc60613          	addi	a2,a2,1020 # ffffffffc0206310 <commands+0x828>
ffffffffc0202f1c:	26200593          	li	a1,610
ffffffffc0202f20:	00004517          	auipc	a0,0x4
ffffffffc0202f24:	8f050513          	addi	a0,a0,-1808 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202f28:	d6afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f2c:	00004697          	auipc	a3,0x4
ffffffffc0202f30:	c5468693          	addi	a3,a3,-940 # ffffffffc0206b80 <default_pmm_manager+0x4c0>
ffffffffc0202f34:	00003617          	auipc	a2,0x3
ffffffffc0202f38:	3dc60613          	addi	a2,a2,988 # ffffffffc0206310 <commands+0x828>
ffffffffc0202f3c:	23d00593          	li	a1,573
ffffffffc0202f40:	00004517          	auipc	a0,0x4
ffffffffc0202f44:	8d050513          	addi	a0,a0,-1840 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202f48:	d4afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202f4c:	00004697          	auipc	a3,0x4
ffffffffc0202f50:	ad468693          	addi	a3,a3,-1324 # ffffffffc0206a20 <default_pmm_manager+0x360>
ffffffffc0202f54:	00003617          	auipc	a2,0x3
ffffffffc0202f58:	3bc60613          	addi	a2,a2,956 # ffffffffc0206310 <commands+0x828>
ffffffffc0202f5c:	23c00593          	li	a1,572
ffffffffc0202f60:	00004517          	auipc	a0,0x4
ffffffffc0202f64:	8b050513          	addi	a0,a0,-1872 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202f68:	d2afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202f6c:	00004697          	auipc	a3,0x4
ffffffffc0202f70:	c2c68693          	addi	a3,a3,-980 # ffffffffc0206b98 <default_pmm_manager+0x4d8>
ffffffffc0202f74:	00003617          	auipc	a2,0x3
ffffffffc0202f78:	39c60613          	addi	a2,a2,924 # ffffffffc0206310 <commands+0x828>
ffffffffc0202f7c:	23900593          	li	a1,569
ffffffffc0202f80:	00004517          	auipc	a0,0x4
ffffffffc0202f84:	89050513          	addi	a0,a0,-1904 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202f88:	d0afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f8c:	00004697          	auipc	a3,0x4
ffffffffc0202f90:	a7c68693          	addi	a3,a3,-1412 # ffffffffc0206a08 <default_pmm_manager+0x348>
ffffffffc0202f94:	00003617          	auipc	a2,0x3
ffffffffc0202f98:	37c60613          	addi	a2,a2,892 # ffffffffc0206310 <commands+0x828>
ffffffffc0202f9c:	23800593          	li	a1,568
ffffffffc0202fa0:	00004517          	auipc	a0,0x4
ffffffffc0202fa4:	87050513          	addi	a0,a0,-1936 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202fa8:	ceafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202fac:	00004697          	auipc	a3,0x4
ffffffffc0202fb0:	afc68693          	addi	a3,a3,-1284 # ffffffffc0206aa8 <default_pmm_manager+0x3e8>
ffffffffc0202fb4:	00003617          	auipc	a2,0x3
ffffffffc0202fb8:	35c60613          	addi	a2,a2,860 # ffffffffc0206310 <commands+0x828>
ffffffffc0202fbc:	23700593          	li	a1,567
ffffffffc0202fc0:	00004517          	auipc	a0,0x4
ffffffffc0202fc4:	85050513          	addi	a0,a0,-1968 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202fc8:	ccafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fcc:	00004697          	auipc	a3,0x4
ffffffffc0202fd0:	bb468693          	addi	a3,a3,-1100 # ffffffffc0206b80 <default_pmm_manager+0x4c0>
ffffffffc0202fd4:	00003617          	auipc	a2,0x3
ffffffffc0202fd8:	33c60613          	addi	a2,a2,828 # ffffffffc0206310 <commands+0x828>
ffffffffc0202fdc:	23600593          	li	a1,566
ffffffffc0202fe0:	00004517          	auipc	a0,0x4
ffffffffc0202fe4:	83050513          	addi	a0,a0,-2000 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0202fe8:	caafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202fec:	00004697          	auipc	a3,0x4
ffffffffc0202ff0:	b7c68693          	addi	a3,a3,-1156 # ffffffffc0206b68 <default_pmm_manager+0x4a8>
ffffffffc0202ff4:	00003617          	auipc	a2,0x3
ffffffffc0202ff8:	31c60613          	addi	a2,a2,796 # ffffffffc0206310 <commands+0x828>
ffffffffc0202ffc:	23500593          	li	a1,565
ffffffffc0203000:	00004517          	auipc	a0,0x4
ffffffffc0203004:	81050513          	addi	a0,a0,-2032 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203008:	c8afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc020300c:	00004697          	auipc	a3,0x4
ffffffffc0203010:	b2c68693          	addi	a3,a3,-1236 # ffffffffc0206b38 <default_pmm_manager+0x478>
ffffffffc0203014:	00003617          	auipc	a2,0x3
ffffffffc0203018:	2fc60613          	addi	a2,a2,764 # ffffffffc0206310 <commands+0x828>
ffffffffc020301c:	23400593          	li	a1,564
ffffffffc0203020:	00003517          	auipc	a0,0x3
ffffffffc0203024:	7f050513          	addi	a0,a0,2032 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203028:	c6afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020302c:	00004697          	auipc	a3,0x4
ffffffffc0203030:	af468693          	addi	a3,a3,-1292 # ffffffffc0206b20 <default_pmm_manager+0x460>
ffffffffc0203034:	00003617          	auipc	a2,0x3
ffffffffc0203038:	2dc60613          	addi	a2,a2,732 # ffffffffc0206310 <commands+0x828>
ffffffffc020303c:	23200593          	li	a1,562
ffffffffc0203040:	00003517          	auipc	a0,0x3
ffffffffc0203044:	7d050513          	addi	a0,a0,2000 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203048:	c4afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020304c:	00004697          	auipc	a3,0x4
ffffffffc0203050:	ab468693          	addi	a3,a3,-1356 # ffffffffc0206b00 <default_pmm_manager+0x440>
ffffffffc0203054:	00003617          	auipc	a2,0x3
ffffffffc0203058:	2bc60613          	addi	a2,a2,700 # ffffffffc0206310 <commands+0x828>
ffffffffc020305c:	23100593          	li	a1,561
ffffffffc0203060:	00003517          	auipc	a0,0x3
ffffffffc0203064:	7b050513          	addi	a0,a0,1968 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203068:	c2afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020306c:	00004697          	auipc	a3,0x4
ffffffffc0203070:	a8468693          	addi	a3,a3,-1404 # ffffffffc0206af0 <default_pmm_manager+0x430>
ffffffffc0203074:	00003617          	auipc	a2,0x3
ffffffffc0203078:	29c60613          	addi	a2,a2,668 # ffffffffc0206310 <commands+0x828>
ffffffffc020307c:	23000593          	li	a1,560
ffffffffc0203080:	00003517          	auipc	a0,0x3
ffffffffc0203084:	79050513          	addi	a0,a0,1936 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203088:	c0afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_U);
ffffffffc020308c:	00004697          	auipc	a3,0x4
ffffffffc0203090:	a5468693          	addi	a3,a3,-1452 # ffffffffc0206ae0 <default_pmm_manager+0x420>
ffffffffc0203094:	00003617          	auipc	a2,0x3
ffffffffc0203098:	27c60613          	addi	a2,a2,636 # ffffffffc0206310 <commands+0x828>
ffffffffc020309c:	22f00593          	li	a1,559
ffffffffc02030a0:	00003517          	auipc	a0,0x3
ffffffffc02030a4:	77050513          	addi	a0,a0,1904 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc02030a8:	beafd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("DTB memory info not available");
ffffffffc02030ac:	00003617          	auipc	a2,0x3
ffffffffc02030b0:	7d460613          	addi	a2,a2,2004 # ffffffffc0206880 <default_pmm_manager+0x1c0>
ffffffffc02030b4:	06500593          	li	a1,101
ffffffffc02030b8:	00003517          	auipc	a0,0x3
ffffffffc02030bc:	75850513          	addi	a0,a0,1880 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc02030c0:	bd2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02030c4:	00004697          	auipc	a3,0x4
ffffffffc02030c8:	b3468693          	addi	a3,a3,-1228 # ffffffffc0206bf8 <default_pmm_manager+0x538>
ffffffffc02030cc:	00003617          	auipc	a2,0x3
ffffffffc02030d0:	24460613          	addi	a2,a2,580 # ffffffffc0206310 <commands+0x828>
ffffffffc02030d4:	27500593          	li	a1,629
ffffffffc02030d8:	00003517          	auipc	a0,0x3
ffffffffc02030dc:	73850513          	addi	a0,a0,1848 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc02030e0:	bb2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030e4:	00004697          	auipc	a3,0x4
ffffffffc02030e8:	9c468693          	addi	a3,a3,-1596 # ffffffffc0206aa8 <default_pmm_manager+0x3e8>
ffffffffc02030ec:	00003617          	auipc	a2,0x3
ffffffffc02030f0:	22460613          	addi	a2,a2,548 # ffffffffc0206310 <commands+0x828>
ffffffffc02030f4:	22e00593          	li	a1,558
ffffffffc02030f8:	00003517          	auipc	a0,0x3
ffffffffc02030fc:	71850513          	addi	a0,a0,1816 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203100:	b92fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203104:	00004697          	auipc	a3,0x4
ffffffffc0203108:	96468693          	addi	a3,a3,-1692 # ffffffffc0206a68 <default_pmm_manager+0x3a8>
ffffffffc020310c:	00003617          	auipc	a2,0x3
ffffffffc0203110:	20460613          	addi	a2,a2,516 # ffffffffc0206310 <commands+0x828>
ffffffffc0203114:	22d00593          	li	a1,557
ffffffffc0203118:	00003517          	auipc	a0,0x3
ffffffffc020311c:	6f850513          	addi	a0,a0,1784 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203120:	b72fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203124:	86d6                	mv	a3,s5
ffffffffc0203126:	00003617          	auipc	a2,0x3
ffffffffc020312a:	5d260613          	addi	a2,a2,1490 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc020312e:	22900593          	li	a1,553
ffffffffc0203132:	00003517          	auipc	a0,0x3
ffffffffc0203136:	6de50513          	addi	a0,a0,1758 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc020313a:	b58fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020313e:	00003617          	auipc	a2,0x3
ffffffffc0203142:	5ba60613          	addi	a2,a2,1466 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc0203146:	22800593          	li	a1,552
ffffffffc020314a:	00003517          	auipc	a0,0x3
ffffffffc020314e:	6c650513          	addi	a0,a0,1734 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203152:	b40fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203156:	00004697          	auipc	a3,0x4
ffffffffc020315a:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0206a20 <default_pmm_manager+0x360>
ffffffffc020315e:	00003617          	auipc	a2,0x3
ffffffffc0203162:	1b260613          	addi	a2,a2,434 # ffffffffc0206310 <commands+0x828>
ffffffffc0203166:	22600593          	li	a1,550
ffffffffc020316a:	00003517          	auipc	a0,0x3
ffffffffc020316e:	6a650513          	addi	a0,a0,1702 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203172:	b20fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203176:	00004697          	auipc	a3,0x4
ffffffffc020317a:	89268693          	addi	a3,a3,-1902 # ffffffffc0206a08 <default_pmm_manager+0x348>
ffffffffc020317e:	00003617          	auipc	a2,0x3
ffffffffc0203182:	19260613          	addi	a2,a2,402 # ffffffffc0206310 <commands+0x828>
ffffffffc0203186:	22500593          	li	a1,549
ffffffffc020318a:	00003517          	auipc	a0,0x3
ffffffffc020318e:	68650513          	addi	a0,a0,1670 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203192:	b00fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203196:	00004697          	auipc	a3,0x4
ffffffffc020319a:	c2268693          	addi	a3,a3,-990 # ffffffffc0206db8 <default_pmm_manager+0x6f8>
ffffffffc020319e:	00003617          	auipc	a2,0x3
ffffffffc02031a2:	17260613          	addi	a2,a2,370 # ffffffffc0206310 <commands+0x828>
ffffffffc02031a6:	26c00593          	li	a1,620
ffffffffc02031aa:	00003517          	auipc	a0,0x3
ffffffffc02031ae:	66650513          	addi	a0,a0,1638 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc02031b2:	ae0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02031b6:	00004697          	auipc	a3,0x4
ffffffffc02031ba:	bca68693          	addi	a3,a3,-1078 # ffffffffc0206d80 <default_pmm_manager+0x6c0>
ffffffffc02031be:	00003617          	auipc	a2,0x3
ffffffffc02031c2:	15260613          	addi	a2,a2,338 # ffffffffc0206310 <commands+0x828>
ffffffffc02031c6:	26900593          	li	a1,617
ffffffffc02031ca:	00003517          	auipc	a0,0x3
ffffffffc02031ce:	64650513          	addi	a0,a0,1606 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc02031d2:	ac0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02031d6:	00004697          	auipc	a3,0x4
ffffffffc02031da:	b7a68693          	addi	a3,a3,-1158 # ffffffffc0206d50 <default_pmm_manager+0x690>
ffffffffc02031de:	00003617          	auipc	a2,0x3
ffffffffc02031e2:	13260613          	addi	a2,a2,306 # ffffffffc0206310 <commands+0x828>
ffffffffc02031e6:	26500593          	li	a1,613
ffffffffc02031ea:	00003517          	auipc	a0,0x3
ffffffffc02031ee:	62650513          	addi	a0,a0,1574 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc02031f2:	aa0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02031f6:	00004697          	auipc	a3,0x4
ffffffffc02031fa:	b1268693          	addi	a3,a3,-1262 # ffffffffc0206d08 <default_pmm_manager+0x648>
ffffffffc02031fe:	00003617          	auipc	a2,0x3
ffffffffc0203202:	11260613          	addi	a2,a2,274 # ffffffffc0206310 <commands+0x828>
ffffffffc0203206:	26400593          	li	a1,612
ffffffffc020320a:	00003517          	auipc	a0,0x3
ffffffffc020320e:	60650513          	addi	a0,a0,1542 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203212:	a80fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203216:	00003617          	auipc	a2,0x3
ffffffffc020321a:	58a60613          	addi	a2,a2,1418 # ffffffffc02067a0 <default_pmm_manager+0xe0>
ffffffffc020321e:	0c900593          	li	a1,201
ffffffffc0203222:	00003517          	auipc	a0,0x3
ffffffffc0203226:	5ee50513          	addi	a0,a0,1518 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc020322a:	a68fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020322e:	00003617          	auipc	a2,0x3
ffffffffc0203232:	57260613          	addi	a2,a2,1394 # ffffffffc02067a0 <default_pmm_manager+0xe0>
ffffffffc0203236:	08100593          	li	a1,129
ffffffffc020323a:	00003517          	auipc	a0,0x3
ffffffffc020323e:	5d650513          	addi	a0,a0,1494 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203242:	a50fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203246:	00003697          	auipc	a3,0x3
ffffffffc020324a:	79268693          	addi	a3,a3,1938 # ffffffffc02069d8 <default_pmm_manager+0x318>
ffffffffc020324e:	00003617          	auipc	a2,0x3
ffffffffc0203252:	0c260613          	addi	a2,a2,194 # ffffffffc0206310 <commands+0x828>
ffffffffc0203256:	22400593          	li	a1,548
ffffffffc020325a:	00003517          	auipc	a0,0x3
ffffffffc020325e:	5b650513          	addi	a0,a0,1462 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203262:	a30fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203266:	00003697          	auipc	a3,0x3
ffffffffc020326a:	74268693          	addi	a3,a3,1858 # ffffffffc02069a8 <default_pmm_manager+0x2e8>
ffffffffc020326e:	00003617          	auipc	a2,0x3
ffffffffc0203272:	0a260613          	addi	a2,a2,162 # ffffffffc0206310 <commands+0x828>
ffffffffc0203276:	22100593          	li	a1,545
ffffffffc020327a:	00003517          	auipc	a0,0x3
ffffffffc020327e:	59650513          	addi	a0,a0,1430 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc0203282:	a10fd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203286 <copy_range>:
{
ffffffffc0203286:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203288:	00d667b3          	or	a5,a2,a3
{
ffffffffc020328c:	f486                	sd	ra,104(sp)
ffffffffc020328e:	f0a2                	sd	s0,96(sp)
ffffffffc0203290:	eca6                	sd	s1,88(sp)
ffffffffc0203292:	e8ca                	sd	s2,80(sp)
ffffffffc0203294:	e4ce                	sd	s3,72(sp)
ffffffffc0203296:	e0d2                	sd	s4,64(sp)
ffffffffc0203298:	fc56                	sd	s5,56(sp)
ffffffffc020329a:	f85a                	sd	s6,48(sp)
ffffffffc020329c:	f45e                	sd	s7,40(sp)
ffffffffc020329e:	f062                	sd	s8,32(sp)
ffffffffc02032a0:	ec66                	sd	s9,24(sp)
ffffffffc02032a2:	e86a                	sd	s10,16(sp)
ffffffffc02032a4:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02032a6:	17d2                	slli	a5,a5,0x34
ffffffffc02032a8:	22079563          	bnez	a5,ffffffffc02034d2 <copy_range+0x24c>
    assert(USER_ACCESS(start, end));
ffffffffc02032ac:	002007b7          	lui	a5,0x200
ffffffffc02032b0:	8432                	mv	s0,a2
ffffffffc02032b2:	1af66863          	bltu	a2,a5,ffffffffc0203462 <copy_range+0x1dc>
ffffffffc02032b6:	8936                	mv	s2,a3
ffffffffc02032b8:	1ad67563          	bgeu	a2,a3,ffffffffc0203462 <copy_range+0x1dc>
ffffffffc02032bc:	4785                	li	a5,1
ffffffffc02032be:	07fe                	slli	a5,a5,0x1f
ffffffffc02032c0:	1ad7e163          	bltu	a5,a3,ffffffffc0203462 <copy_range+0x1dc>
ffffffffc02032c4:	5b7d                	li	s6,-1
ffffffffc02032c6:	8aaa                	mv	s5,a0
ffffffffc02032c8:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc02032ca:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02032cc:	000cfc17          	auipc	s8,0xcf
ffffffffc02032d0:	d3cc0c13          	addi	s8,s8,-708 # ffffffffc02d2008 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02032d4:	000cfb97          	auipc	s7,0xcf
ffffffffc02032d8:	d3cb8b93          	addi	s7,s7,-708 # ffffffffc02d2010 <pages>
    return KADDR(page2pa(page));
ffffffffc02032dc:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc02032e0:	000cfc97          	auipc	s9,0xcf
ffffffffc02032e4:	d38c8c93          	addi	s9,s9,-712 # ffffffffc02d2018 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02032e8:	4601                	li	a2,0
ffffffffc02032ea:	85a2                	mv	a1,s0
ffffffffc02032ec:	854e                	mv	a0,s3
ffffffffc02032ee:	b73fe0ef          	jal	ra,ffffffffc0201e60 <get_pte>
ffffffffc02032f2:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02032f4:	c965                	beqz	a0,ffffffffc02033e4 <copy_range+0x15e>
        if (*ptep & PTE_V)
ffffffffc02032f6:	611c                	ld	a5,0(a0)
ffffffffc02032f8:	8b85                	andi	a5,a5,1
ffffffffc02032fa:	e78d                	bnez	a5,ffffffffc0203324 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc02032fc:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02032fe:	ff2465e3          	bltu	s0,s2,ffffffffc02032e8 <copy_range+0x62>
    return 0;
ffffffffc0203302:	4481                	li	s1,0
}
ffffffffc0203304:	70a6                	ld	ra,104(sp)
ffffffffc0203306:	7406                	ld	s0,96(sp)
ffffffffc0203308:	6946                	ld	s2,80(sp)
ffffffffc020330a:	69a6                	ld	s3,72(sp)
ffffffffc020330c:	6a06                	ld	s4,64(sp)
ffffffffc020330e:	7ae2                	ld	s5,56(sp)
ffffffffc0203310:	7b42                	ld	s6,48(sp)
ffffffffc0203312:	7ba2                	ld	s7,40(sp)
ffffffffc0203314:	7c02                	ld	s8,32(sp)
ffffffffc0203316:	6ce2                	ld	s9,24(sp)
ffffffffc0203318:	6d42                	ld	s10,16(sp)
ffffffffc020331a:	6da2                	ld	s11,8(sp)
ffffffffc020331c:	8526                	mv	a0,s1
ffffffffc020331e:	64e6                	ld	s1,88(sp)
ffffffffc0203320:	6165                	addi	sp,sp,112
ffffffffc0203322:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203324:	4605                	li	a2,1
ffffffffc0203326:	85a2                	mv	a1,s0
ffffffffc0203328:	8556                	mv	a0,s5
ffffffffc020332a:	b37fe0ef          	jal	ra,ffffffffc0201e60 <get_pte>
ffffffffc020332e:	c165                	beqz	a0,ffffffffc020340e <copy_range+0x188>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203330:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203332:	0017f713          	andi	a4,a5,1
ffffffffc0203336:	01f7f493          	andi	s1,a5,31
ffffffffc020333a:	18070063          	beqz	a4,ffffffffc02034ba <copy_range+0x234>
    if (PPN(pa) >= npage)
ffffffffc020333e:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203342:	078a                	slli	a5,a5,0x2
ffffffffc0203344:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203348:	14d77d63          	bgeu	a4,a3,ffffffffc02034a2 <copy_range+0x21c>
    return &pages[PPN(pa) - nbase];
ffffffffc020334c:	000bb783          	ld	a5,0(s7)
ffffffffc0203350:	fff806b7          	lui	a3,0xfff80
ffffffffc0203354:	9736                	add	a4,a4,a3
ffffffffc0203356:	071a                	slli	a4,a4,0x6
ffffffffc0203358:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020335c:	10002773          	csrr	a4,sstatus
ffffffffc0203360:	8b09                	andi	a4,a4,2
ffffffffc0203362:	eb59                	bnez	a4,ffffffffc02033f8 <copy_range+0x172>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203364:	000cb703          	ld	a4,0(s9)
ffffffffc0203368:	4505                	li	a0,1
ffffffffc020336a:	6f18                	ld	a4,24(a4)
ffffffffc020336c:	9702                	jalr	a4
ffffffffc020336e:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203370:	0c0d8963          	beqz	s11,ffffffffc0203442 <copy_range+0x1bc>
            assert(npage != NULL);
ffffffffc0203374:	100d0763          	beqz	s10,ffffffffc0203482 <copy_range+0x1fc>
    return page - pages + nbase;
ffffffffc0203378:	000bb703          	ld	a4,0(s7)
ffffffffc020337c:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc0203380:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0203384:	40ed86b3          	sub	a3,s11,a4
ffffffffc0203388:	8699                	srai	a3,a3,0x6
ffffffffc020338a:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020338c:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203390:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203392:	08c7fc63          	bgeu	a5,a2,ffffffffc020342a <copy_range+0x1a4>
    return page - pages + nbase;
ffffffffc0203396:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc020339a:	000cf717          	auipc	a4,0xcf
ffffffffc020339e:	c8670713          	addi	a4,a4,-890 # ffffffffc02d2020 <va_pa_offset>
ffffffffc02033a2:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc02033a4:	8799                	srai	a5,a5,0x6
ffffffffc02033a6:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc02033a8:	0167f733          	and	a4,a5,s6
ffffffffc02033ac:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02033b0:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02033b2:	06c77b63          	bgeu	a4,a2,ffffffffc0203428 <copy_range+0x1a2>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02033b6:	6605                	lui	a2,0x1
ffffffffc02033b8:	953e                	add	a0,a0,a5
ffffffffc02033ba:	4a8020ef          	jal	ra,ffffffffc0205862 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02033be:	86a6                	mv	a3,s1
ffffffffc02033c0:	8622                	mv	a2,s0
ffffffffc02033c2:	85ea                	mv	a1,s10
ffffffffc02033c4:	8556                	mv	a0,s5
ffffffffc02033c6:	98aff0ef          	jal	ra,ffffffffc0202550 <page_insert>
ffffffffc02033ca:	84aa                	mv	s1,a0
            if (ret != 0)
ffffffffc02033cc:	d905                	beqz	a0,ffffffffc02032fc <copy_range+0x76>
ffffffffc02033ce:	100027f3          	csrr	a5,sstatus
ffffffffc02033d2:	8b89                	andi	a5,a5,2
ffffffffc02033d4:	ef9d                	bnez	a5,ffffffffc0203412 <copy_range+0x18c>
        pmm_manager->free_pages(base, n);
ffffffffc02033d6:	000cb783          	ld	a5,0(s9)
ffffffffc02033da:	4585                	li	a1,1
ffffffffc02033dc:	856a                	mv	a0,s10
ffffffffc02033de:	739c                	ld	a5,32(a5)
ffffffffc02033e0:	9782                	jalr	a5
    if (flag)
ffffffffc02033e2:	b70d                	j	ffffffffc0203304 <copy_range+0x7e>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02033e4:	00200637          	lui	a2,0x200
ffffffffc02033e8:	9432                	add	s0,s0,a2
ffffffffc02033ea:	ffe00637          	lui	a2,0xffe00
ffffffffc02033ee:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc02033f0:	d809                	beqz	s0,ffffffffc0203302 <copy_range+0x7c>
ffffffffc02033f2:	ef246be3          	bltu	s0,s2,ffffffffc02032e8 <copy_range+0x62>
ffffffffc02033f6:	b731                	j	ffffffffc0203302 <copy_range+0x7c>
        intr_disable();
ffffffffc02033f8:	db6fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02033fc:	000cb703          	ld	a4,0(s9)
ffffffffc0203400:	4505                	li	a0,1
ffffffffc0203402:	6f18                	ld	a4,24(a4)
ffffffffc0203404:	9702                	jalr	a4
ffffffffc0203406:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc0203408:	da0fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020340c:	b795                	j	ffffffffc0203370 <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc020340e:	54f1                	li	s1,-4
ffffffffc0203410:	bdd5                	j	ffffffffc0203304 <copy_range+0x7e>
        intr_disable();
ffffffffc0203412:	d9cfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203416:	000cb783          	ld	a5,0(s9)
ffffffffc020341a:	4585                	li	a1,1
ffffffffc020341c:	856a                	mv	a0,s10
ffffffffc020341e:	739c                	ld	a5,32(a5)
ffffffffc0203420:	9782                	jalr	a5
        intr_enable();
ffffffffc0203422:	d86fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203426:	bdf9                	j	ffffffffc0203304 <copy_range+0x7e>
ffffffffc0203428:	86be                	mv	a3,a5
ffffffffc020342a:	00003617          	auipc	a2,0x3
ffffffffc020342e:	2ce60613          	addi	a2,a2,718 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc0203432:	07100593          	li	a1,113
ffffffffc0203436:	00003517          	auipc	a0,0x3
ffffffffc020343a:	2ea50513          	addi	a0,a0,746 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc020343e:	854fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(page != NULL);
ffffffffc0203442:	00004697          	auipc	a3,0x4
ffffffffc0203446:	9be68693          	addi	a3,a3,-1602 # ffffffffc0206e00 <default_pmm_manager+0x740>
ffffffffc020344a:	00003617          	auipc	a2,0x3
ffffffffc020344e:	ec660613          	addi	a2,a2,-314 # ffffffffc0206310 <commands+0x828>
ffffffffc0203452:	19600593          	li	a1,406
ffffffffc0203456:	00003517          	auipc	a0,0x3
ffffffffc020345a:	3ba50513          	addi	a0,a0,954 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc020345e:	834fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203462:	00003697          	auipc	a3,0x3
ffffffffc0203466:	3ee68693          	addi	a3,a3,1006 # ffffffffc0206850 <default_pmm_manager+0x190>
ffffffffc020346a:	00003617          	auipc	a2,0x3
ffffffffc020346e:	ea660613          	addi	a2,a2,-346 # ffffffffc0206310 <commands+0x828>
ffffffffc0203472:	17e00593          	li	a1,382
ffffffffc0203476:	00003517          	auipc	a0,0x3
ffffffffc020347a:	39a50513          	addi	a0,a0,922 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc020347e:	814fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(npage != NULL);
ffffffffc0203482:	00004697          	auipc	a3,0x4
ffffffffc0203486:	98e68693          	addi	a3,a3,-1650 # ffffffffc0206e10 <default_pmm_manager+0x750>
ffffffffc020348a:	00003617          	auipc	a2,0x3
ffffffffc020348e:	e8660613          	addi	a2,a2,-378 # ffffffffc0206310 <commands+0x828>
ffffffffc0203492:	19700593          	li	a1,407
ffffffffc0203496:	00003517          	auipc	a0,0x3
ffffffffc020349a:	37a50513          	addi	a0,a0,890 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc020349e:	ff5fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02034a2:	00003617          	auipc	a2,0x3
ffffffffc02034a6:	32660613          	addi	a2,a2,806 # ffffffffc02067c8 <default_pmm_manager+0x108>
ffffffffc02034aa:	06900593          	li	a1,105
ffffffffc02034ae:	00003517          	auipc	a0,0x3
ffffffffc02034b2:	27250513          	addi	a0,a0,626 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc02034b6:	fddfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02034ba:	00003617          	auipc	a2,0x3
ffffffffc02034be:	32e60613          	addi	a2,a2,814 # ffffffffc02067e8 <default_pmm_manager+0x128>
ffffffffc02034c2:	07f00593          	li	a1,127
ffffffffc02034c6:	00003517          	auipc	a0,0x3
ffffffffc02034ca:	25a50513          	addi	a0,a0,602 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc02034ce:	fc5fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02034d2:	00003697          	auipc	a3,0x3
ffffffffc02034d6:	34e68693          	addi	a3,a3,846 # ffffffffc0206820 <default_pmm_manager+0x160>
ffffffffc02034da:	00003617          	auipc	a2,0x3
ffffffffc02034de:	e3660613          	addi	a2,a2,-458 # ffffffffc0206310 <commands+0x828>
ffffffffc02034e2:	17d00593          	li	a1,381
ffffffffc02034e6:	00003517          	auipc	a0,0x3
ffffffffc02034ea:	32a50513          	addi	a0,a0,810 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc02034ee:	fa5fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02034f2 <pgdir_alloc_page>:
{
ffffffffc02034f2:	7179                	addi	sp,sp,-48
ffffffffc02034f4:	ec26                	sd	s1,24(sp)
ffffffffc02034f6:	e84a                	sd	s2,16(sp)
ffffffffc02034f8:	e052                	sd	s4,0(sp)
ffffffffc02034fa:	f406                	sd	ra,40(sp)
ffffffffc02034fc:	f022                	sd	s0,32(sp)
ffffffffc02034fe:	e44e                	sd	s3,8(sp)
ffffffffc0203500:	8a2a                	mv	s4,a0
ffffffffc0203502:	84ae                	mv	s1,a1
ffffffffc0203504:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203506:	100027f3          	csrr	a5,sstatus
ffffffffc020350a:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc020350c:	000cf997          	auipc	s3,0xcf
ffffffffc0203510:	b0c98993          	addi	s3,s3,-1268 # ffffffffc02d2018 <pmm_manager>
ffffffffc0203514:	ef8d                	bnez	a5,ffffffffc020354e <pgdir_alloc_page+0x5c>
ffffffffc0203516:	0009b783          	ld	a5,0(s3)
ffffffffc020351a:	4505                	li	a0,1
ffffffffc020351c:	6f9c                	ld	a5,24(a5)
ffffffffc020351e:	9782                	jalr	a5
ffffffffc0203520:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203522:	cc09                	beqz	s0,ffffffffc020353c <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203524:	86ca                	mv	a3,s2
ffffffffc0203526:	8626                	mv	a2,s1
ffffffffc0203528:	85a2                	mv	a1,s0
ffffffffc020352a:	8552                	mv	a0,s4
ffffffffc020352c:	824ff0ef          	jal	ra,ffffffffc0202550 <page_insert>
ffffffffc0203530:	e915                	bnez	a0,ffffffffc0203564 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203532:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203534:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc0203536:	4785                	li	a5,1
ffffffffc0203538:	04f71e63          	bne	a4,a5,ffffffffc0203594 <pgdir_alloc_page+0xa2>
}
ffffffffc020353c:	70a2                	ld	ra,40(sp)
ffffffffc020353e:	8522                	mv	a0,s0
ffffffffc0203540:	7402                	ld	s0,32(sp)
ffffffffc0203542:	64e2                	ld	s1,24(sp)
ffffffffc0203544:	6942                	ld	s2,16(sp)
ffffffffc0203546:	69a2                	ld	s3,8(sp)
ffffffffc0203548:	6a02                	ld	s4,0(sp)
ffffffffc020354a:	6145                	addi	sp,sp,48
ffffffffc020354c:	8082                	ret
        intr_disable();
ffffffffc020354e:	c60fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203552:	0009b783          	ld	a5,0(s3)
ffffffffc0203556:	4505                	li	a0,1
ffffffffc0203558:	6f9c                	ld	a5,24(a5)
ffffffffc020355a:	9782                	jalr	a5
ffffffffc020355c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020355e:	c4afd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203562:	b7c1                	j	ffffffffc0203522 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203564:	100027f3          	csrr	a5,sstatus
ffffffffc0203568:	8b89                	andi	a5,a5,2
ffffffffc020356a:	eb89                	bnez	a5,ffffffffc020357c <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc020356c:	0009b783          	ld	a5,0(s3)
ffffffffc0203570:	8522                	mv	a0,s0
ffffffffc0203572:	4585                	li	a1,1
ffffffffc0203574:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203576:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203578:	9782                	jalr	a5
    if (flag)
ffffffffc020357a:	b7c9                	j	ffffffffc020353c <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc020357c:	c32fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0203580:	0009b783          	ld	a5,0(s3)
ffffffffc0203584:	8522                	mv	a0,s0
ffffffffc0203586:	4585                	li	a1,1
ffffffffc0203588:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020358a:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020358c:	9782                	jalr	a5
        intr_enable();
ffffffffc020358e:	c1afd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203592:	b76d                	j	ffffffffc020353c <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203594:	00004697          	auipc	a3,0x4
ffffffffc0203598:	88c68693          	addi	a3,a3,-1908 # ffffffffc0206e20 <default_pmm_manager+0x760>
ffffffffc020359c:	00003617          	auipc	a2,0x3
ffffffffc02035a0:	d7460613          	addi	a2,a2,-652 # ffffffffc0206310 <commands+0x828>
ffffffffc02035a4:	20200593          	li	a1,514
ffffffffc02035a8:	00003517          	auipc	a0,0x3
ffffffffc02035ac:	26850513          	addi	a0,a0,616 # ffffffffc0206810 <default_pmm_manager+0x150>
ffffffffc02035b0:	ee3fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02035b4 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02035b4:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02035b6:	00004697          	auipc	a3,0x4
ffffffffc02035ba:	88268693          	addi	a3,a3,-1918 # ffffffffc0206e38 <default_pmm_manager+0x778>
ffffffffc02035be:	00003617          	auipc	a2,0x3
ffffffffc02035c2:	d5260613          	addi	a2,a2,-686 # ffffffffc0206310 <commands+0x828>
ffffffffc02035c6:	07400593          	li	a1,116
ffffffffc02035ca:	00004517          	auipc	a0,0x4
ffffffffc02035ce:	88e50513          	addi	a0,a0,-1906 # ffffffffc0206e58 <default_pmm_manager+0x798>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02035d2:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02035d4:	ebffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02035d8 <mm_create>:
{
ffffffffc02035d8:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035da:	04000513          	li	a0,64
{
ffffffffc02035de:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035e0:	deafe0ef          	jal	ra,ffffffffc0201bca <kmalloc>
    if (mm != NULL)
ffffffffc02035e4:	cd19                	beqz	a0,ffffffffc0203602 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02035e6:	e508                	sd	a0,8(a0)
ffffffffc02035e8:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02035ea:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02035ee:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02035f2:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02035f6:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02035fa:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02035fe:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203602:	60a2                	ld	ra,8(sp)
ffffffffc0203604:	0141                	addi	sp,sp,16
ffffffffc0203606:	8082                	ret

ffffffffc0203608 <find_vma>:
{
ffffffffc0203608:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc020360a:	c505                	beqz	a0,ffffffffc0203632 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc020360c:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020360e:	c501                	beqz	a0,ffffffffc0203616 <find_vma+0xe>
ffffffffc0203610:	651c                	ld	a5,8(a0)
ffffffffc0203612:	02f5f263          	bgeu	a1,a5,ffffffffc0203636 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203616:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0203618:	00f68d63          	beq	a3,a5,ffffffffc0203632 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020361c:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f38e0>
ffffffffc0203620:	00e5e663          	bltu	a1,a4,ffffffffc020362c <find_vma+0x24>
ffffffffc0203624:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203628:	00e5ec63          	bltu	a1,a4,ffffffffc0203640 <find_vma+0x38>
ffffffffc020362c:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc020362e:	fef697e3          	bne	a3,a5,ffffffffc020361c <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203632:	4501                	li	a0,0
}
ffffffffc0203634:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203636:	691c                	ld	a5,16(a0)
ffffffffc0203638:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0203616 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc020363c:	ea88                	sd	a0,16(a3)
ffffffffc020363e:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203640:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203644:	ea88                	sd	a0,16(a3)
ffffffffc0203646:	8082                	ret

ffffffffc0203648 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203648:	6590                	ld	a2,8(a1)
ffffffffc020364a:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_matrix_out_size+0x73908>
{
ffffffffc020364e:	1141                	addi	sp,sp,-16
ffffffffc0203650:	e406                	sd	ra,8(sp)
ffffffffc0203652:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203654:	01066763          	bltu	a2,a6,ffffffffc0203662 <insert_vma_struct+0x1a>
ffffffffc0203658:	a085                	j	ffffffffc02036b8 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020365a:	fe87b703          	ld	a4,-24(a5)
ffffffffc020365e:	04e66863          	bltu	a2,a4,ffffffffc02036ae <insert_vma_struct+0x66>
ffffffffc0203662:	86be                	mv	a3,a5
ffffffffc0203664:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203666:	fef51ae3          	bne	a0,a5,ffffffffc020365a <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020366a:	02a68463          	beq	a3,a0,ffffffffc0203692 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020366e:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203672:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203676:	08e8f163          	bgeu	a7,a4,ffffffffc02036f8 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020367a:	04e66f63          	bltu	a2,a4,ffffffffc02036d8 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc020367e:	00f50a63          	beq	a0,a5,ffffffffc0203692 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203682:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203686:	05076963          	bltu	a4,a6,ffffffffc02036d8 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020368a:	ff07b603          	ld	a2,-16(a5)
ffffffffc020368e:	02c77363          	bgeu	a4,a2,ffffffffc02036b4 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203692:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203694:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203696:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020369a:	e390                	sd	a2,0(a5)
ffffffffc020369c:	e690                	sd	a2,8(a3)
}
ffffffffc020369e:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02036a0:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02036a2:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc02036a4:	0017079b          	addiw	a5,a4,1
ffffffffc02036a8:	d11c                	sw	a5,32(a0)
}
ffffffffc02036aa:	0141                	addi	sp,sp,16
ffffffffc02036ac:	8082                	ret
    if (le_prev != list)
ffffffffc02036ae:	fca690e3          	bne	a3,a0,ffffffffc020366e <insert_vma_struct+0x26>
ffffffffc02036b2:	bfd1                	j	ffffffffc0203686 <insert_vma_struct+0x3e>
ffffffffc02036b4:	f01ff0ef          	jal	ra,ffffffffc02035b4 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02036b8:	00003697          	auipc	a3,0x3
ffffffffc02036bc:	7b068693          	addi	a3,a3,1968 # ffffffffc0206e68 <default_pmm_manager+0x7a8>
ffffffffc02036c0:	00003617          	auipc	a2,0x3
ffffffffc02036c4:	c5060613          	addi	a2,a2,-944 # ffffffffc0206310 <commands+0x828>
ffffffffc02036c8:	07a00593          	li	a1,122
ffffffffc02036cc:	00003517          	auipc	a0,0x3
ffffffffc02036d0:	78c50513          	addi	a0,a0,1932 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc02036d4:	dbffc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036d8:	00003697          	auipc	a3,0x3
ffffffffc02036dc:	7d068693          	addi	a3,a3,2000 # ffffffffc0206ea8 <default_pmm_manager+0x7e8>
ffffffffc02036e0:	00003617          	auipc	a2,0x3
ffffffffc02036e4:	c3060613          	addi	a2,a2,-976 # ffffffffc0206310 <commands+0x828>
ffffffffc02036e8:	07300593          	li	a1,115
ffffffffc02036ec:	00003517          	auipc	a0,0x3
ffffffffc02036f0:	76c50513          	addi	a0,a0,1900 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc02036f4:	d9ffc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036f8:	00003697          	auipc	a3,0x3
ffffffffc02036fc:	79068693          	addi	a3,a3,1936 # ffffffffc0206e88 <default_pmm_manager+0x7c8>
ffffffffc0203700:	00003617          	auipc	a2,0x3
ffffffffc0203704:	c1060613          	addi	a2,a2,-1008 # ffffffffc0206310 <commands+0x828>
ffffffffc0203708:	07200593          	li	a1,114
ffffffffc020370c:	00003517          	auipc	a0,0x3
ffffffffc0203710:	74c50513          	addi	a0,a0,1868 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203714:	d7ffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203718 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203718:	591c                	lw	a5,48(a0)
{
ffffffffc020371a:	1141                	addi	sp,sp,-16
ffffffffc020371c:	e406                	sd	ra,8(sp)
ffffffffc020371e:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203720:	e78d                	bnez	a5,ffffffffc020374a <mm_destroy+0x32>
ffffffffc0203722:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203724:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203726:	00a40c63          	beq	s0,a0,ffffffffc020373e <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020372a:	6118                	ld	a4,0(a0)
ffffffffc020372c:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020372e:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203730:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203732:	e398                	sd	a4,0(a5)
ffffffffc0203734:	d46fe0ef          	jal	ra,ffffffffc0201c7a <kfree>
    return listelm->next;
ffffffffc0203738:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc020373a:	fea418e3          	bne	s0,a0,ffffffffc020372a <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020373e:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203740:	6402                	ld	s0,0(sp)
ffffffffc0203742:	60a2                	ld	ra,8(sp)
ffffffffc0203744:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203746:	d34fe06f          	j	ffffffffc0201c7a <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020374a:	00003697          	auipc	a3,0x3
ffffffffc020374e:	77e68693          	addi	a3,a3,1918 # ffffffffc0206ec8 <default_pmm_manager+0x808>
ffffffffc0203752:	00003617          	auipc	a2,0x3
ffffffffc0203756:	bbe60613          	addi	a2,a2,-1090 # ffffffffc0206310 <commands+0x828>
ffffffffc020375a:	09e00593          	li	a1,158
ffffffffc020375e:	00003517          	auipc	a0,0x3
ffffffffc0203762:	6fa50513          	addi	a0,a0,1786 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203766:	d2dfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020376a <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc020376a:	7139                	addi	sp,sp,-64
ffffffffc020376c:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020376e:	6405                	lui	s0,0x1
ffffffffc0203770:	147d                	addi	s0,s0,-1
ffffffffc0203772:	77fd                	lui	a5,0xfffff
ffffffffc0203774:	9622                	add	a2,a2,s0
ffffffffc0203776:	962e                	add	a2,a2,a1
{
ffffffffc0203778:	f426                	sd	s1,40(sp)
ffffffffc020377a:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020377c:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203780:	f04a                	sd	s2,32(sp)
ffffffffc0203782:	ec4e                	sd	s3,24(sp)
ffffffffc0203784:	e852                	sd	s4,16(sp)
ffffffffc0203786:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203788:	002005b7          	lui	a1,0x200
ffffffffc020378c:	00f67433          	and	s0,a2,a5
ffffffffc0203790:	06b4e363          	bltu	s1,a1,ffffffffc02037f6 <mm_map+0x8c>
ffffffffc0203794:	0684f163          	bgeu	s1,s0,ffffffffc02037f6 <mm_map+0x8c>
ffffffffc0203798:	4785                	li	a5,1
ffffffffc020379a:	07fe                	slli	a5,a5,0x1f
ffffffffc020379c:	0487ed63          	bltu	a5,s0,ffffffffc02037f6 <mm_map+0x8c>
ffffffffc02037a0:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02037a2:	cd21                	beqz	a0,ffffffffc02037fa <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc02037a4:	85a6                	mv	a1,s1
ffffffffc02037a6:	8ab6                	mv	s5,a3
ffffffffc02037a8:	8a3a                	mv	s4,a4
ffffffffc02037aa:	e5fff0ef          	jal	ra,ffffffffc0203608 <find_vma>
ffffffffc02037ae:	c501                	beqz	a0,ffffffffc02037b6 <mm_map+0x4c>
ffffffffc02037b0:	651c                	ld	a5,8(a0)
ffffffffc02037b2:	0487e263          	bltu	a5,s0,ffffffffc02037f6 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02037b6:	03000513          	li	a0,48
ffffffffc02037ba:	c10fe0ef          	jal	ra,ffffffffc0201bca <kmalloc>
ffffffffc02037be:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02037c0:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02037c2:	02090163          	beqz	s2,ffffffffc02037e4 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02037c6:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02037c8:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02037cc:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02037d0:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02037d4:	85ca                	mv	a1,s2
ffffffffc02037d6:	e73ff0ef          	jal	ra,ffffffffc0203648 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02037da:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02037dc:	000a0463          	beqz	s4,ffffffffc02037e4 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02037e0:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f30>

out:
    return ret;
}
ffffffffc02037e4:	70e2                	ld	ra,56(sp)
ffffffffc02037e6:	7442                	ld	s0,48(sp)
ffffffffc02037e8:	74a2                	ld	s1,40(sp)
ffffffffc02037ea:	7902                	ld	s2,32(sp)
ffffffffc02037ec:	69e2                	ld	s3,24(sp)
ffffffffc02037ee:	6a42                	ld	s4,16(sp)
ffffffffc02037f0:	6aa2                	ld	s5,8(sp)
ffffffffc02037f2:	6121                	addi	sp,sp,64
ffffffffc02037f4:	8082                	ret
        return -E_INVAL;
ffffffffc02037f6:	5575                	li	a0,-3
ffffffffc02037f8:	b7f5                	j	ffffffffc02037e4 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02037fa:	00003697          	auipc	a3,0x3
ffffffffc02037fe:	6e668693          	addi	a3,a3,1766 # ffffffffc0206ee0 <default_pmm_manager+0x820>
ffffffffc0203802:	00003617          	auipc	a2,0x3
ffffffffc0203806:	b0e60613          	addi	a2,a2,-1266 # ffffffffc0206310 <commands+0x828>
ffffffffc020380a:	0b300593          	li	a1,179
ffffffffc020380e:	00003517          	auipc	a0,0x3
ffffffffc0203812:	64a50513          	addi	a0,a0,1610 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203816:	c7dfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020381a <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc020381a:	7139                	addi	sp,sp,-64
ffffffffc020381c:	fc06                	sd	ra,56(sp)
ffffffffc020381e:	f822                	sd	s0,48(sp)
ffffffffc0203820:	f426                	sd	s1,40(sp)
ffffffffc0203822:	f04a                	sd	s2,32(sp)
ffffffffc0203824:	ec4e                	sd	s3,24(sp)
ffffffffc0203826:	e852                	sd	s4,16(sp)
ffffffffc0203828:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc020382a:	c52d                	beqz	a0,ffffffffc0203894 <dup_mmap+0x7a>
ffffffffc020382c:	892a                	mv	s2,a0
ffffffffc020382e:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203830:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203832:	e595                	bnez	a1,ffffffffc020385e <dup_mmap+0x44>
ffffffffc0203834:	a085                	j	ffffffffc0203894 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203836:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203838:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_matrix_out_size+0x1f3900>
        vma->vm_end = vm_end;
ffffffffc020383c:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203840:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203844:	e05ff0ef          	jal	ra,ffffffffc0203648 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203848:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8f40>
ffffffffc020384c:	fe843603          	ld	a2,-24(s0)
ffffffffc0203850:	6c8c                	ld	a1,24(s1)
ffffffffc0203852:	01893503          	ld	a0,24(s2)
ffffffffc0203856:	4701                	li	a4,0
ffffffffc0203858:	a2fff0ef          	jal	ra,ffffffffc0203286 <copy_range>
ffffffffc020385c:	e105                	bnez	a0,ffffffffc020387c <dup_mmap+0x62>
    return listelm->prev;
ffffffffc020385e:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203860:	02848863          	beq	s1,s0,ffffffffc0203890 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203864:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203868:	fe843a83          	ld	s5,-24(s0)
ffffffffc020386c:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203870:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203874:	b56fe0ef          	jal	ra,ffffffffc0201bca <kmalloc>
ffffffffc0203878:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc020387a:	fd55                	bnez	a0,ffffffffc0203836 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc020387c:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020387e:	70e2                	ld	ra,56(sp)
ffffffffc0203880:	7442                	ld	s0,48(sp)
ffffffffc0203882:	74a2                	ld	s1,40(sp)
ffffffffc0203884:	7902                	ld	s2,32(sp)
ffffffffc0203886:	69e2                	ld	s3,24(sp)
ffffffffc0203888:	6a42                	ld	s4,16(sp)
ffffffffc020388a:	6aa2                	ld	s5,8(sp)
ffffffffc020388c:	6121                	addi	sp,sp,64
ffffffffc020388e:	8082                	ret
    return 0;
ffffffffc0203890:	4501                	li	a0,0
ffffffffc0203892:	b7f5                	j	ffffffffc020387e <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203894:	00003697          	auipc	a3,0x3
ffffffffc0203898:	65c68693          	addi	a3,a3,1628 # ffffffffc0206ef0 <default_pmm_manager+0x830>
ffffffffc020389c:	00003617          	auipc	a2,0x3
ffffffffc02038a0:	a7460613          	addi	a2,a2,-1420 # ffffffffc0206310 <commands+0x828>
ffffffffc02038a4:	0cf00593          	li	a1,207
ffffffffc02038a8:	00003517          	auipc	a0,0x3
ffffffffc02038ac:	5b050513          	addi	a0,a0,1456 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc02038b0:	be3fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02038b4 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc02038b4:	1101                	addi	sp,sp,-32
ffffffffc02038b6:	ec06                	sd	ra,24(sp)
ffffffffc02038b8:	e822                	sd	s0,16(sp)
ffffffffc02038ba:	e426                	sd	s1,8(sp)
ffffffffc02038bc:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02038be:	c531                	beqz	a0,ffffffffc020390a <exit_mmap+0x56>
ffffffffc02038c0:	591c                	lw	a5,48(a0)
ffffffffc02038c2:	84aa                	mv	s1,a0
ffffffffc02038c4:	e3b9                	bnez	a5,ffffffffc020390a <exit_mmap+0x56>
    return listelm->next;
ffffffffc02038c6:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02038c8:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02038cc:	02850663          	beq	a0,s0,ffffffffc02038f8 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038d0:	ff043603          	ld	a2,-16(s0)
ffffffffc02038d4:	fe843583          	ld	a1,-24(s0)
ffffffffc02038d8:	854a                	mv	a0,s2
ffffffffc02038da:	803fe0ef          	jal	ra,ffffffffc02020dc <unmap_range>
ffffffffc02038de:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038e0:	fe8498e3          	bne	s1,s0,ffffffffc02038d0 <exit_mmap+0x1c>
ffffffffc02038e4:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02038e6:	00848c63          	beq	s1,s0,ffffffffc02038fe <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038ea:	ff043603          	ld	a2,-16(s0)
ffffffffc02038ee:	fe843583          	ld	a1,-24(s0)
ffffffffc02038f2:	854a                	mv	a0,s2
ffffffffc02038f4:	92ffe0ef          	jal	ra,ffffffffc0202222 <exit_range>
ffffffffc02038f8:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038fa:	fe8498e3          	bne	s1,s0,ffffffffc02038ea <exit_mmap+0x36>
    }
}
ffffffffc02038fe:	60e2                	ld	ra,24(sp)
ffffffffc0203900:	6442                	ld	s0,16(sp)
ffffffffc0203902:	64a2                	ld	s1,8(sp)
ffffffffc0203904:	6902                	ld	s2,0(sp)
ffffffffc0203906:	6105                	addi	sp,sp,32
ffffffffc0203908:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020390a:	00003697          	auipc	a3,0x3
ffffffffc020390e:	60668693          	addi	a3,a3,1542 # ffffffffc0206f10 <default_pmm_manager+0x850>
ffffffffc0203912:	00003617          	auipc	a2,0x3
ffffffffc0203916:	9fe60613          	addi	a2,a2,-1538 # ffffffffc0206310 <commands+0x828>
ffffffffc020391a:	0e800593          	li	a1,232
ffffffffc020391e:	00003517          	auipc	a0,0x3
ffffffffc0203922:	53a50513          	addi	a0,a0,1338 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203926:	b6dfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020392a <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc020392a:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020392c:	04000513          	li	a0,64
{
ffffffffc0203930:	fc06                	sd	ra,56(sp)
ffffffffc0203932:	f822                	sd	s0,48(sp)
ffffffffc0203934:	f426                	sd	s1,40(sp)
ffffffffc0203936:	f04a                	sd	s2,32(sp)
ffffffffc0203938:	ec4e                	sd	s3,24(sp)
ffffffffc020393a:	e852                	sd	s4,16(sp)
ffffffffc020393c:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020393e:	a8cfe0ef          	jal	ra,ffffffffc0201bca <kmalloc>
    if (mm != NULL)
ffffffffc0203942:	2e050663          	beqz	a0,ffffffffc0203c2e <vmm_init+0x304>
ffffffffc0203946:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203948:	e508                	sd	a0,8(a0)
ffffffffc020394a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020394c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203950:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203954:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203958:	02053423          	sd	zero,40(a0)
ffffffffc020395c:	02052823          	sw	zero,48(a0)
ffffffffc0203960:	02053c23          	sd	zero,56(a0)
ffffffffc0203964:	03200413          	li	s0,50
ffffffffc0203968:	a811                	j	ffffffffc020397c <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc020396a:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc020396c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020396e:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203972:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203974:	8526                	mv	a0,s1
ffffffffc0203976:	cd3ff0ef          	jal	ra,ffffffffc0203648 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc020397a:	c80d                	beqz	s0,ffffffffc02039ac <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020397c:	03000513          	li	a0,48
ffffffffc0203980:	a4afe0ef          	jal	ra,ffffffffc0201bca <kmalloc>
ffffffffc0203984:	85aa                	mv	a1,a0
ffffffffc0203986:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc020398a:	f165                	bnez	a0,ffffffffc020396a <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc020398c:	00003697          	auipc	a3,0x3
ffffffffc0203990:	71c68693          	addi	a3,a3,1820 # ffffffffc02070a8 <default_pmm_manager+0x9e8>
ffffffffc0203994:	00003617          	auipc	a2,0x3
ffffffffc0203998:	97c60613          	addi	a2,a2,-1668 # ffffffffc0206310 <commands+0x828>
ffffffffc020399c:	12c00593          	li	a1,300
ffffffffc02039a0:	00003517          	auipc	a0,0x3
ffffffffc02039a4:	4b850513          	addi	a0,a0,1208 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc02039a8:	aebfc0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc02039ac:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039b0:	1f900913          	li	s2,505
ffffffffc02039b4:	a819                	j	ffffffffc02039ca <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc02039b6:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02039b8:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039ba:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039be:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02039c0:	8526                	mv	a0,s1
ffffffffc02039c2:	c87ff0ef          	jal	ra,ffffffffc0203648 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039c6:	03240a63          	beq	s0,s2,ffffffffc02039fa <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039ca:	03000513          	li	a0,48
ffffffffc02039ce:	9fcfe0ef          	jal	ra,ffffffffc0201bca <kmalloc>
ffffffffc02039d2:	85aa                	mv	a1,a0
ffffffffc02039d4:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02039d8:	fd79                	bnez	a0,ffffffffc02039b6 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc02039da:	00003697          	auipc	a3,0x3
ffffffffc02039de:	6ce68693          	addi	a3,a3,1742 # ffffffffc02070a8 <default_pmm_manager+0x9e8>
ffffffffc02039e2:	00003617          	auipc	a2,0x3
ffffffffc02039e6:	92e60613          	addi	a2,a2,-1746 # ffffffffc0206310 <commands+0x828>
ffffffffc02039ea:	13300593          	li	a1,307
ffffffffc02039ee:	00003517          	auipc	a0,0x3
ffffffffc02039f2:	46a50513          	addi	a0,a0,1130 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc02039f6:	a9dfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return listelm->next;
ffffffffc02039fa:	649c                	ld	a5,8(s1)
ffffffffc02039fc:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02039fe:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203a02:	16f48663          	beq	s1,a5,ffffffffc0203b6e <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203a06:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd2cf90>
ffffffffc0203a0a:	ffe70693          	addi	a3,a4,-2
ffffffffc0203a0e:	10d61063          	bne	a2,a3,ffffffffc0203b0e <vmm_init+0x1e4>
ffffffffc0203a12:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203a16:	0ed71c63          	bne	a4,a3,ffffffffc0203b0e <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203a1a:	0715                	addi	a4,a4,5
ffffffffc0203a1c:	679c                	ld	a5,8(a5)
ffffffffc0203a1e:	feb712e3          	bne	a4,a1,ffffffffc0203a02 <vmm_init+0xd8>
ffffffffc0203a22:	4a1d                	li	s4,7
ffffffffc0203a24:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a26:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203a2a:	85a2                	mv	a1,s0
ffffffffc0203a2c:	8526                	mv	a0,s1
ffffffffc0203a2e:	bdbff0ef          	jal	ra,ffffffffc0203608 <find_vma>
ffffffffc0203a32:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203a34:	16050d63          	beqz	a0,ffffffffc0203bae <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203a38:	00140593          	addi	a1,s0,1
ffffffffc0203a3c:	8526                	mv	a0,s1
ffffffffc0203a3e:	bcbff0ef          	jal	ra,ffffffffc0203608 <find_vma>
ffffffffc0203a42:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203a44:	14050563          	beqz	a0,ffffffffc0203b8e <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203a48:	85d2                	mv	a1,s4
ffffffffc0203a4a:	8526                	mv	a0,s1
ffffffffc0203a4c:	bbdff0ef          	jal	ra,ffffffffc0203608 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203a50:	16051f63          	bnez	a0,ffffffffc0203bce <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203a54:	00340593          	addi	a1,s0,3
ffffffffc0203a58:	8526                	mv	a0,s1
ffffffffc0203a5a:	bafff0ef          	jal	ra,ffffffffc0203608 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203a5e:	1a051863          	bnez	a0,ffffffffc0203c0e <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203a62:	00440593          	addi	a1,s0,4
ffffffffc0203a66:	8526                	mv	a0,s1
ffffffffc0203a68:	ba1ff0ef          	jal	ra,ffffffffc0203608 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203a6c:	18051163          	bnez	a0,ffffffffc0203bee <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203a70:	00893783          	ld	a5,8(s2)
ffffffffc0203a74:	0a879d63          	bne	a5,s0,ffffffffc0203b2e <vmm_init+0x204>
ffffffffc0203a78:	01093783          	ld	a5,16(s2)
ffffffffc0203a7c:	0b479963          	bne	a5,s4,ffffffffc0203b2e <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203a80:	0089b783          	ld	a5,8(s3)
ffffffffc0203a84:	0c879563          	bne	a5,s0,ffffffffc0203b4e <vmm_init+0x224>
ffffffffc0203a88:	0109b783          	ld	a5,16(s3)
ffffffffc0203a8c:	0d479163          	bne	a5,s4,ffffffffc0203b4e <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a90:	0415                	addi	s0,s0,5
ffffffffc0203a92:	0a15                	addi	s4,s4,5
ffffffffc0203a94:	f9541be3          	bne	s0,s5,ffffffffc0203a2a <vmm_init+0x100>
ffffffffc0203a98:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203a9a:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203a9c:	85a2                	mv	a1,s0
ffffffffc0203a9e:	8526                	mv	a0,s1
ffffffffc0203aa0:	b69ff0ef          	jal	ra,ffffffffc0203608 <find_vma>
ffffffffc0203aa4:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203aa8:	c90d                	beqz	a0,ffffffffc0203ada <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203aaa:	6914                	ld	a3,16(a0)
ffffffffc0203aac:	6510                	ld	a2,8(a0)
ffffffffc0203aae:	00003517          	auipc	a0,0x3
ffffffffc0203ab2:	58250513          	addi	a0,a0,1410 # ffffffffc0207030 <default_pmm_manager+0x970>
ffffffffc0203ab6:	ee2fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203aba:	00003697          	auipc	a3,0x3
ffffffffc0203abe:	59e68693          	addi	a3,a3,1438 # ffffffffc0207058 <default_pmm_manager+0x998>
ffffffffc0203ac2:	00003617          	auipc	a2,0x3
ffffffffc0203ac6:	84e60613          	addi	a2,a2,-1970 # ffffffffc0206310 <commands+0x828>
ffffffffc0203aca:	15900593          	li	a1,345
ffffffffc0203ace:	00003517          	auipc	a0,0x3
ffffffffc0203ad2:	38a50513          	addi	a0,a0,906 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203ad6:	9bdfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203ada:	147d                	addi	s0,s0,-1
ffffffffc0203adc:	fd2410e3          	bne	s0,s2,ffffffffc0203a9c <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203ae0:	8526                	mv	a0,s1
ffffffffc0203ae2:	c37ff0ef          	jal	ra,ffffffffc0203718 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203ae6:	00003517          	auipc	a0,0x3
ffffffffc0203aea:	58a50513          	addi	a0,a0,1418 # ffffffffc0207070 <default_pmm_manager+0x9b0>
ffffffffc0203aee:	eaafc0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0203af2:	7442                	ld	s0,48(sp)
ffffffffc0203af4:	70e2                	ld	ra,56(sp)
ffffffffc0203af6:	74a2                	ld	s1,40(sp)
ffffffffc0203af8:	7902                	ld	s2,32(sp)
ffffffffc0203afa:	69e2                	ld	s3,24(sp)
ffffffffc0203afc:	6a42                	ld	s4,16(sp)
ffffffffc0203afe:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203b00:	00003517          	auipc	a0,0x3
ffffffffc0203b04:	59050513          	addi	a0,a0,1424 # ffffffffc0207090 <default_pmm_manager+0x9d0>
}
ffffffffc0203b08:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203b0a:	e8efc06f          	j	ffffffffc0200198 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b0e:	00003697          	auipc	a3,0x3
ffffffffc0203b12:	43a68693          	addi	a3,a3,1082 # ffffffffc0206f48 <default_pmm_manager+0x888>
ffffffffc0203b16:	00002617          	auipc	a2,0x2
ffffffffc0203b1a:	7fa60613          	addi	a2,a2,2042 # ffffffffc0206310 <commands+0x828>
ffffffffc0203b1e:	13d00593          	li	a1,317
ffffffffc0203b22:	00003517          	auipc	a0,0x3
ffffffffc0203b26:	33650513          	addi	a0,a0,822 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203b2a:	969fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b2e:	00003697          	auipc	a3,0x3
ffffffffc0203b32:	4a268693          	addi	a3,a3,1186 # ffffffffc0206fd0 <default_pmm_manager+0x910>
ffffffffc0203b36:	00002617          	auipc	a2,0x2
ffffffffc0203b3a:	7da60613          	addi	a2,a2,2010 # ffffffffc0206310 <commands+0x828>
ffffffffc0203b3e:	14e00593          	li	a1,334
ffffffffc0203b42:	00003517          	auipc	a0,0x3
ffffffffc0203b46:	31650513          	addi	a0,a0,790 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203b4a:	949fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b4e:	00003697          	auipc	a3,0x3
ffffffffc0203b52:	4b268693          	addi	a3,a3,1202 # ffffffffc0207000 <default_pmm_manager+0x940>
ffffffffc0203b56:	00002617          	auipc	a2,0x2
ffffffffc0203b5a:	7ba60613          	addi	a2,a2,1978 # ffffffffc0206310 <commands+0x828>
ffffffffc0203b5e:	14f00593          	li	a1,335
ffffffffc0203b62:	00003517          	auipc	a0,0x3
ffffffffc0203b66:	2f650513          	addi	a0,a0,758 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203b6a:	929fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203b6e:	00003697          	auipc	a3,0x3
ffffffffc0203b72:	3c268693          	addi	a3,a3,962 # ffffffffc0206f30 <default_pmm_manager+0x870>
ffffffffc0203b76:	00002617          	auipc	a2,0x2
ffffffffc0203b7a:	79a60613          	addi	a2,a2,1946 # ffffffffc0206310 <commands+0x828>
ffffffffc0203b7e:	13b00593          	li	a1,315
ffffffffc0203b82:	00003517          	auipc	a0,0x3
ffffffffc0203b86:	2d650513          	addi	a0,a0,726 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203b8a:	909fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2 != NULL);
ffffffffc0203b8e:	00003697          	auipc	a3,0x3
ffffffffc0203b92:	40268693          	addi	a3,a3,1026 # ffffffffc0206f90 <default_pmm_manager+0x8d0>
ffffffffc0203b96:	00002617          	auipc	a2,0x2
ffffffffc0203b9a:	77a60613          	addi	a2,a2,1914 # ffffffffc0206310 <commands+0x828>
ffffffffc0203b9e:	14600593          	li	a1,326
ffffffffc0203ba2:	00003517          	auipc	a0,0x3
ffffffffc0203ba6:	2b650513          	addi	a0,a0,694 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203baa:	8e9fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1 != NULL);
ffffffffc0203bae:	00003697          	auipc	a3,0x3
ffffffffc0203bb2:	3d268693          	addi	a3,a3,978 # ffffffffc0206f80 <default_pmm_manager+0x8c0>
ffffffffc0203bb6:	00002617          	auipc	a2,0x2
ffffffffc0203bba:	75a60613          	addi	a2,a2,1882 # ffffffffc0206310 <commands+0x828>
ffffffffc0203bbe:	14400593          	li	a1,324
ffffffffc0203bc2:	00003517          	auipc	a0,0x3
ffffffffc0203bc6:	29650513          	addi	a0,a0,662 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203bca:	8c9fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma3 == NULL);
ffffffffc0203bce:	00003697          	auipc	a3,0x3
ffffffffc0203bd2:	3d268693          	addi	a3,a3,978 # ffffffffc0206fa0 <default_pmm_manager+0x8e0>
ffffffffc0203bd6:	00002617          	auipc	a2,0x2
ffffffffc0203bda:	73a60613          	addi	a2,a2,1850 # ffffffffc0206310 <commands+0x828>
ffffffffc0203bde:	14800593          	li	a1,328
ffffffffc0203be2:	00003517          	auipc	a0,0x3
ffffffffc0203be6:	27650513          	addi	a0,a0,630 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203bea:	8a9fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma5 == NULL);
ffffffffc0203bee:	00003697          	auipc	a3,0x3
ffffffffc0203bf2:	3d268693          	addi	a3,a3,978 # ffffffffc0206fc0 <default_pmm_manager+0x900>
ffffffffc0203bf6:	00002617          	auipc	a2,0x2
ffffffffc0203bfa:	71a60613          	addi	a2,a2,1818 # ffffffffc0206310 <commands+0x828>
ffffffffc0203bfe:	14c00593          	li	a1,332
ffffffffc0203c02:	00003517          	auipc	a0,0x3
ffffffffc0203c06:	25650513          	addi	a0,a0,598 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203c0a:	889fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma4 == NULL);
ffffffffc0203c0e:	00003697          	auipc	a3,0x3
ffffffffc0203c12:	3a268693          	addi	a3,a3,930 # ffffffffc0206fb0 <default_pmm_manager+0x8f0>
ffffffffc0203c16:	00002617          	auipc	a2,0x2
ffffffffc0203c1a:	6fa60613          	addi	a2,a2,1786 # ffffffffc0206310 <commands+0x828>
ffffffffc0203c1e:	14a00593          	li	a1,330
ffffffffc0203c22:	00003517          	auipc	a0,0x3
ffffffffc0203c26:	23650513          	addi	a0,a0,566 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203c2a:	869fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(mm != NULL);
ffffffffc0203c2e:	00003697          	auipc	a3,0x3
ffffffffc0203c32:	2b268693          	addi	a3,a3,690 # ffffffffc0206ee0 <default_pmm_manager+0x820>
ffffffffc0203c36:	00002617          	auipc	a2,0x2
ffffffffc0203c3a:	6da60613          	addi	a2,a2,1754 # ffffffffc0206310 <commands+0x828>
ffffffffc0203c3e:	12400593          	li	a1,292
ffffffffc0203c42:	00003517          	auipc	a0,0x3
ffffffffc0203c46:	21650513          	addi	a0,a0,534 # ffffffffc0206e58 <default_pmm_manager+0x798>
ffffffffc0203c4a:	849fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203c4e <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203c4e:	7179                	addi	sp,sp,-48
ffffffffc0203c50:	f022                	sd	s0,32(sp)
ffffffffc0203c52:	f406                	sd	ra,40(sp)
ffffffffc0203c54:	ec26                	sd	s1,24(sp)
ffffffffc0203c56:	e84a                	sd	s2,16(sp)
ffffffffc0203c58:	e44e                	sd	s3,8(sp)
ffffffffc0203c5a:	e052                	sd	s4,0(sp)
ffffffffc0203c5c:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203c5e:	c135                	beqz	a0,ffffffffc0203cc2 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203c60:	002007b7          	lui	a5,0x200
ffffffffc0203c64:	04f5e663          	bltu	a1,a5,ffffffffc0203cb0 <user_mem_check+0x62>
ffffffffc0203c68:	00c584b3          	add	s1,a1,a2
ffffffffc0203c6c:	0495f263          	bgeu	a1,s1,ffffffffc0203cb0 <user_mem_check+0x62>
ffffffffc0203c70:	4785                	li	a5,1
ffffffffc0203c72:	07fe                	slli	a5,a5,0x1f
ffffffffc0203c74:	0297ee63          	bltu	a5,s1,ffffffffc0203cb0 <user_mem_check+0x62>
ffffffffc0203c78:	892a                	mv	s2,a0
ffffffffc0203c7a:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c7c:	6a05                	lui	s4,0x1
ffffffffc0203c7e:	a821                	j	ffffffffc0203c96 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c80:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c84:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c86:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c88:	c685                	beqz	a3,ffffffffc0203cb0 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c8a:	c399                	beqz	a5,ffffffffc0203c90 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c8c:	02e46263          	bltu	s0,a4,ffffffffc0203cb0 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203c90:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203c92:	04947663          	bgeu	s0,s1,ffffffffc0203cde <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203c96:	85a2                	mv	a1,s0
ffffffffc0203c98:	854a                	mv	a0,s2
ffffffffc0203c9a:	96fff0ef          	jal	ra,ffffffffc0203608 <find_vma>
ffffffffc0203c9e:	c909                	beqz	a0,ffffffffc0203cb0 <user_mem_check+0x62>
ffffffffc0203ca0:	6518                	ld	a4,8(a0)
ffffffffc0203ca2:	00e46763          	bltu	s0,a4,ffffffffc0203cb0 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203ca6:	4d1c                	lw	a5,24(a0)
ffffffffc0203ca8:	fc099ce3          	bnez	s3,ffffffffc0203c80 <user_mem_check+0x32>
ffffffffc0203cac:	8b85                	andi	a5,a5,1
ffffffffc0203cae:	f3ed                	bnez	a5,ffffffffc0203c90 <user_mem_check+0x42>
            return 0;
ffffffffc0203cb0:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203cb2:	70a2                	ld	ra,40(sp)
ffffffffc0203cb4:	7402                	ld	s0,32(sp)
ffffffffc0203cb6:	64e2                	ld	s1,24(sp)
ffffffffc0203cb8:	6942                	ld	s2,16(sp)
ffffffffc0203cba:	69a2                	ld	s3,8(sp)
ffffffffc0203cbc:	6a02                	ld	s4,0(sp)
ffffffffc0203cbe:	6145                	addi	sp,sp,48
ffffffffc0203cc0:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203cc2:	c02007b7          	lui	a5,0xc0200
ffffffffc0203cc6:	4501                	li	a0,0
ffffffffc0203cc8:	fef5e5e3          	bltu	a1,a5,ffffffffc0203cb2 <user_mem_check+0x64>
ffffffffc0203ccc:	962e                	add	a2,a2,a1
ffffffffc0203cce:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203cb2 <user_mem_check+0x64>
ffffffffc0203cd2:	c8000537          	lui	a0,0xc8000
ffffffffc0203cd6:	0505                	addi	a0,a0,1
ffffffffc0203cd8:	00a63533          	sltu	a0,a2,a0
ffffffffc0203cdc:	bfd9                	j	ffffffffc0203cb2 <user_mem_check+0x64>
        return 1;
ffffffffc0203cde:	4505                	li	a0,1
ffffffffc0203ce0:	bfc9                	j	ffffffffc0203cb2 <user_mem_check+0x64>

ffffffffc0203ce2 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203ce2:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203ce4:	9402                	jalr	s0

	jal do_exit
ffffffffc0203ce6:	5e6000ef          	jal	ra,ffffffffc02042cc <do_exit>

ffffffffc0203cea <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203cea:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203cec:	14800513          	li	a0,328
{
ffffffffc0203cf0:	e022                	sd	s0,0(sp)
ffffffffc0203cf2:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203cf4:	ed7fd0ef          	jal	ra,ffffffffc0201bca <kmalloc>
ffffffffc0203cf8:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203cfa:	c141                	beqz	a0,ffffffffc0203d7a <alloc_proc+0x90>
         *       uint32_t lab6_stride;                       // stride value (lab6 stride)
         *       uint32_t lab6_priority;                     // priority value (lab6 stride)
         */

        // lab6:2310675 初始化 proc_struct 基本字段（LAB4/LAB5 已完成部分在此合入）
        proc->state = PROC_UNINIT;
ffffffffc0203cfc:	57fd                	li	a5,-1
ffffffffc0203cfe:	1782                	slli	a5,a5,0x20
ffffffffc0203d00:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203d02:	07000613          	li	a2,112
ffffffffc0203d06:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc0203d08:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d2dfb0>
        proc->kstack = 0;
ffffffffc0203d0c:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203d10:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203d14:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203d18:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203d1c:	03050513          	addi	a0,a0,48
ffffffffc0203d20:	331010ef          	jal	ra,ffffffffc0205850 <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203d24:	000ce797          	auipc	a5,0xce
ffffffffc0203d28:	2d47b783          	ld	a5,724(a5) # ffffffffc02d1ff8 <boot_pgdir_pa>
ffffffffc0203d2c:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0203d2e:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203d32:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203d36:	4641                	li	a2,16
ffffffffc0203d38:	4581                	li	a1,0
ffffffffc0203d3a:	0b440513          	addi	a0,s0,180
ffffffffc0203d3e:	313010ef          	jal	ra,ffffffffc0205850 <memset>
        // lab6:2310675 LAB6 调度相关字段
        // 这些字段用于“调度框架 + 具体调度算法”协作：
        // - rq/run_link/time_slice：RR 使用（就绪队列链表 + 时间片）
        // - lab6_run_pool/lab6_stride/lab6_priority：Stride 使用（优先队列节点 + 步进/权重）
        proc->rq = NULL;
        list_init(&(proc->run_link));
ffffffffc0203d42:	11040793          	addi	a5,s0,272
    elm->prev = elm->next = elm;
ffffffffc0203d46:	10f43c23          	sd	a5,280(s0)
ffffffffc0203d4a:	10f43823          	sd	a5,272(s0)
        proc->time_slice = 0;
        skew_heap_init(&(proc->lab6_run_pool));
        proc->lab6_stride = 0;
ffffffffc0203d4e:	4785                	li	a5,1
ffffffffc0203d50:	1782                	slli	a5,a5,0x20
        proc->wait_state = 0;
ffffffffc0203d52:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->optr = proc->yptr = NULL;
ffffffffc0203d56:	0e043c23          	sd	zero,248(s0)
ffffffffc0203d5a:	10043023          	sd	zero,256(s0)
ffffffffc0203d5e:	0e043823          	sd	zero,240(s0)
        proc->rq = NULL;
ffffffffc0203d62:	10043423          	sd	zero,264(s0)
        proc->time_slice = 0;
ffffffffc0203d66:	12042023          	sw	zero,288(s0)
     compare_f comp) __attribute__((always_inline));

static inline void
skew_heap_init(skew_heap_entry_t *a)
{
     a->left = a->right = a->parent = NULL;
ffffffffc0203d6a:	12043423          	sd	zero,296(s0)
ffffffffc0203d6e:	12043823          	sd	zero,304(s0)
ffffffffc0203d72:	12043c23          	sd	zero,312(s0)
        proc->lab6_stride = 0;
ffffffffc0203d76:	14f43023          	sd	a5,320(s0)
        proc->lab6_priority = 1;
    }
    return proc;
}
ffffffffc0203d7a:	60a2                	ld	ra,8(sp)
ffffffffc0203d7c:	8522                	mv	a0,s0
ffffffffc0203d7e:	6402                	ld	s0,0(sp)
ffffffffc0203d80:	0141                	addi	sp,sp,16
ffffffffc0203d82:	8082                	ret

ffffffffc0203d84 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203d84:	000ce797          	auipc	a5,0xce
ffffffffc0203d88:	2a47b783          	ld	a5,676(a5) # ffffffffc02d2028 <current>
ffffffffc0203d8c:	73c8                	ld	a0,160(a5)
ffffffffc0203d8e:	958fd06f          	j	ffffffffc0200ee6 <forkrets>

ffffffffc0203d92 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203d92:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203d94:	1141                	addi	sp,sp,-16
ffffffffc0203d96:	e406                	sd	ra,8(sp)
ffffffffc0203d98:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d9c:	02f6ee63          	bltu	a3,a5,ffffffffc0203dd8 <put_pgdir+0x46>
ffffffffc0203da0:	000ce517          	auipc	a0,0xce
ffffffffc0203da4:	28053503          	ld	a0,640(a0) # ffffffffc02d2020 <va_pa_offset>
ffffffffc0203da8:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203daa:	82b1                	srli	a3,a3,0xc
ffffffffc0203dac:	000ce797          	auipc	a5,0xce
ffffffffc0203db0:	25c7b783          	ld	a5,604(a5) # ffffffffc02d2008 <npage>
ffffffffc0203db4:	02f6fe63          	bgeu	a3,a5,ffffffffc0203df0 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203db8:	00004517          	auipc	a0,0x4
ffffffffc0203dbc:	3e053503          	ld	a0,992(a0) # ffffffffc0208198 <nbase>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203dc0:	60a2                	ld	ra,8(sp)
ffffffffc0203dc2:	8e89                	sub	a3,a3,a0
ffffffffc0203dc4:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203dc6:	000ce517          	auipc	a0,0xce
ffffffffc0203dca:	24a53503          	ld	a0,586(a0) # ffffffffc02d2010 <pages>
ffffffffc0203dce:	4585                	li	a1,1
ffffffffc0203dd0:	9536                	add	a0,a0,a3
}
ffffffffc0203dd2:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203dd4:	812fe06f          	j	ffffffffc0201de6 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203dd8:	00003617          	auipc	a2,0x3
ffffffffc0203ddc:	9c860613          	addi	a2,a2,-1592 # ffffffffc02067a0 <default_pmm_manager+0xe0>
ffffffffc0203de0:	07700593          	li	a1,119
ffffffffc0203de4:	00003517          	auipc	a0,0x3
ffffffffc0203de8:	93c50513          	addi	a0,a0,-1732 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc0203dec:	ea6fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203df0:	00003617          	auipc	a2,0x3
ffffffffc0203df4:	9d860613          	addi	a2,a2,-1576 # ffffffffc02067c8 <default_pmm_manager+0x108>
ffffffffc0203df8:	06900593          	li	a1,105
ffffffffc0203dfc:	00003517          	auipc	a0,0x3
ffffffffc0203e00:	92450513          	addi	a0,a0,-1756 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc0203e04:	e8efc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203e08 <proc_run>:
{
ffffffffc0203e08:	7179                	addi	sp,sp,-48
ffffffffc0203e0a:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203e0c:	000ce917          	auipc	s2,0xce
ffffffffc0203e10:	21c90913          	addi	s2,s2,540 # ffffffffc02d2028 <current>
{
ffffffffc0203e14:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203e16:	00093483          	ld	s1,0(s2)
{
ffffffffc0203e1a:	f406                	sd	ra,40(sp)
ffffffffc0203e1c:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0203e1e:	02a48a63          	beq	s1,a0,ffffffffc0203e52 <proc_run+0x4a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203e22:	100027f3          	csrr	a5,sstatus
ffffffffc0203e26:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203e28:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203e2a:	e3a9                	bnez	a5,ffffffffc0203e6c <proc_run+0x64>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203e2c:	755c                	ld	a5,168(a0)
ffffffffc0203e2e:	577d                	li	a4,-1
ffffffffc0203e30:	177e                	slli	a4,a4,0x3f
ffffffffc0203e32:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0203e34:	00a93023          	sd	a0,0(s2)
ffffffffc0203e38:	8fd9                	or	a5,a5,a4
ffffffffc0203e3a:	18079073          	csrw	satp,a5
    asm volatile("sfence.vma");
ffffffffc0203e3e:	12000073          	sfence.vma
            switch_to(&(prev->context), &(proc->context));
ffffffffc0203e42:	03050593          	addi	a1,a0,48
ffffffffc0203e46:	03048513          	addi	a0,s1,48
ffffffffc0203e4a:	12a010ef          	jal	ra,ffffffffc0204f74 <switch_to>
    if (flag)
ffffffffc0203e4e:	00099863          	bnez	s3,ffffffffc0203e5e <proc_run+0x56>
}
ffffffffc0203e52:	70a2                	ld	ra,40(sp)
ffffffffc0203e54:	7482                	ld	s1,32(sp)
ffffffffc0203e56:	6962                	ld	s2,24(sp)
ffffffffc0203e58:	69c2                	ld	s3,16(sp)
ffffffffc0203e5a:	6145                	addi	sp,sp,48
ffffffffc0203e5c:	8082                	ret
ffffffffc0203e5e:	70a2                	ld	ra,40(sp)
ffffffffc0203e60:	7482                	ld	s1,32(sp)
ffffffffc0203e62:	6962                	ld	s2,24(sp)
ffffffffc0203e64:	69c2                	ld	s3,16(sp)
ffffffffc0203e66:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203e68:	b41fc06f          	j	ffffffffc02009a8 <intr_enable>
ffffffffc0203e6c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203e6e:	b41fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0203e72:	6522                	ld	a0,8(sp)
ffffffffc0203e74:	4985                	li	s3,1
ffffffffc0203e76:	bf5d                	j	ffffffffc0203e2c <proc_run+0x24>

ffffffffc0203e78 <do_fork>:
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
ffffffffc0203e78:	7119                	addi	sp,sp,-128
ffffffffc0203e7a:	f4a6                	sd	s1,104(sp)
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203e7c:	000ce497          	auipc	s1,0xce
ffffffffc0203e80:	1c448493          	addi	s1,s1,452 # ffffffffc02d2040 <nr_process>
ffffffffc0203e84:	4098                	lw	a4,0(s1)
{
ffffffffc0203e86:	fc86                	sd	ra,120(sp)
ffffffffc0203e88:	f8a2                	sd	s0,112(sp)
ffffffffc0203e8a:	f0ca                	sd	s2,96(sp)
ffffffffc0203e8c:	ecce                	sd	s3,88(sp)
ffffffffc0203e8e:	e8d2                	sd	s4,80(sp)
ffffffffc0203e90:	e4d6                	sd	s5,72(sp)
ffffffffc0203e92:	e0da                	sd	s6,64(sp)
ffffffffc0203e94:	fc5e                	sd	s7,56(sp)
ffffffffc0203e96:	f862                	sd	s8,48(sp)
ffffffffc0203e98:	f466                	sd	s9,40(sp)
ffffffffc0203e9a:	f06a                	sd	s10,32(sp)
ffffffffc0203e9c:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203e9e:	6785                	lui	a5,0x1
ffffffffc0203ea0:	32f75363          	bge	a4,a5,ffffffffc02041c6 <do_fork+0x34e>
ffffffffc0203ea4:	8a2a                	mv	s4,a0
ffffffffc0203ea6:	892e                	mv	s2,a1
ffffffffc0203ea8:	89b2                	mv	s3,a2
     *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
     *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
     */

    // lab6:2310675 step1: alloc and initialize proc_struct
    if ((proc = alloc_proc()) == NULL)
ffffffffc0203eaa:	e41ff0ef          	jal	ra,ffffffffc0203cea <alloc_proc>
ffffffffc0203eae:	842a                	mv	s0,a0
ffffffffc0203eb0:	32050263          	beqz	a0,ffffffffc02041d4 <do_fork+0x35c>
    {
        goto fork_out;
    }

    // lab6:2310675 LAB5 update: setup parent/child relationship
    proc->parent = current;
ffffffffc0203eb4:	000ceb97          	auipc	s7,0xce
ffffffffc0203eb8:	174b8b93          	addi	s7,s7,372 # ffffffffc02d2028 <current>
ffffffffc0203ebc:	000bb783          	ld	a5,0(s7)
    assert(current->wait_state == 0);
ffffffffc0203ec0:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8e44>
    proc->parent = current;
ffffffffc0203ec4:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0203ec6:	30071e63          	bnez	a4,ffffffffc02041e2 <do_fork+0x36a>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203eca:	4509                	li	a0,2
ffffffffc0203ecc:	eddfd0ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
    if (page != NULL)
ffffffffc0203ed0:	2e050963          	beqz	a0,ffffffffc02041c2 <do_fork+0x34a>
    return page - pages + nbase;
ffffffffc0203ed4:	000cec97          	auipc	s9,0xce
ffffffffc0203ed8:	13cc8c93          	addi	s9,s9,316 # ffffffffc02d2010 <pages>
ffffffffc0203edc:	000cb683          	ld	a3,0(s9)
ffffffffc0203ee0:	00004a97          	auipc	s5,0x4
ffffffffc0203ee4:	2b8a8a93          	addi	s5,s5,696 # ffffffffc0208198 <nbase>
ffffffffc0203ee8:	000ab703          	ld	a4,0(s5)
ffffffffc0203eec:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0203ef0:	000ced17          	auipc	s10,0xce
ffffffffc0203ef4:	118d0d13          	addi	s10,s10,280 # ffffffffc02d2008 <npage>
    return page - pages + nbase;
ffffffffc0203ef8:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203efa:	5b7d                	li	s6,-1
ffffffffc0203efc:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc0203f00:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0203f02:	00cb5b13          	srli	s6,s6,0xc
ffffffffc0203f06:	0166f633          	and	a2,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203f0a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203f0c:	2ef67b63          	bgeu	a2,a5,ffffffffc0204202 <do_fork+0x38a>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203f10:	000bb603          	ld	a2,0(s7)
ffffffffc0203f14:	000ced97          	auipc	s11,0xce
ffffffffc0203f18:	10cd8d93          	addi	s11,s11,268 # ffffffffc02d2020 <va_pa_offset>
ffffffffc0203f1c:	000db783          	ld	a5,0(s11)
ffffffffc0203f20:	02863b83          	ld	s7,40(a2)
ffffffffc0203f24:	e43a                	sd	a4,8(sp)
ffffffffc0203f26:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203f28:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0203f2a:	020b8863          	beqz	s7,ffffffffc0203f5a <do_fork+0xe2>
    if (clone_flags & CLONE_VM)
ffffffffc0203f2e:	100a7a13          	andi	s4,s4,256
ffffffffc0203f32:	1a0a0163          	beqz	s4,ffffffffc02040d4 <do_fork+0x25c>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0203f36:	030ba703          	lw	a4,48(s7)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f3a:	018bb783          	ld	a5,24(s7)
ffffffffc0203f3e:	c02006b7          	lui	a3,0xc0200
ffffffffc0203f42:	2705                	addiw	a4,a4,1
ffffffffc0203f44:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc0203f48:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f4c:	30d7eb63          	bltu	a5,a3,ffffffffc0204262 <do_fork+0x3ea>
ffffffffc0203f50:	000db703          	ld	a4,0(s11)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f54:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f56:	8f99                	sub	a5,a5,a4
ffffffffc0203f58:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f5a:	6789                	lui	a5,0x2
ffffffffc0203f5c:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8050>
ffffffffc0203f60:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0203f62:	864e                	mv	a2,s3
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f64:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0203f66:	87b6                	mv	a5,a3
ffffffffc0203f68:	12098893          	addi	a7,s3,288
ffffffffc0203f6c:	00063803          	ld	a6,0(a2)
ffffffffc0203f70:	6608                	ld	a0,8(a2)
ffffffffc0203f72:	6a0c                	ld	a1,16(a2)
ffffffffc0203f74:	6e18                	ld	a4,24(a2)
ffffffffc0203f76:	0107b023          	sd	a6,0(a5)
ffffffffc0203f7a:	e788                	sd	a0,8(a5)
ffffffffc0203f7c:	eb8c                	sd	a1,16(a5)
ffffffffc0203f7e:	ef98                	sd	a4,24(a5)
ffffffffc0203f80:	02060613          	addi	a2,a2,32
ffffffffc0203f84:	02078793          	addi	a5,a5,32
ffffffffc0203f88:	ff1612e3          	bne	a2,a7,ffffffffc0203f6c <do_fork+0xf4>
    proc->tf->gpr.a0 = 0;
ffffffffc0203f8c:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203f90:	1c090c63          	beqz	s2,ffffffffc0204168 <do_fork+0x2f0>
ffffffffc0203f94:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203f98:	00000797          	auipc	a5,0x0
ffffffffc0203f9c:	dec78793          	addi	a5,a5,-532 # ffffffffc0203d84 <forkret>
ffffffffc0203fa0:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203fa2:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fa4:	100027f3          	csrr	a5,sstatus
ffffffffc0203fa8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203faa:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fac:	20079763          	bnez	a5,ffffffffc02041ba <do_fork+0x342>
    if (++last_pid >= MAX_PID)
ffffffffc0203fb0:	000ca817          	auipc	a6,0xca
ffffffffc0203fb4:	bc080813          	addi	a6,a6,-1088 # ffffffffc02cdb70 <last_pid.1>
ffffffffc0203fb8:	00082783          	lw	a5,0(a6)
ffffffffc0203fbc:	6709                	lui	a4,0x2
ffffffffc0203fbe:	0017851b          	addiw	a0,a5,1
ffffffffc0203fc2:	00a82023          	sw	a0,0(a6)
ffffffffc0203fc6:	0ae55063          	bge	a0,a4,ffffffffc0204066 <do_fork+0x1ee>
    if (last_pid >= next_safe)
ffffffffc0203fca:	000ca317          	auipc	t1,0xca
ffffffffc0203fce:	baa30313          	addi	t1,t1,-1110 # ffffffffc02cdb74 <next_safe.0>
ffffffffc0203fd2:	00032783          	lw	a5,0(t1)
ffffffffc0203fd6:	000ce917          	auipc	s2,0xce
ffffffffc0203fda:	fba90913          	addi	s2,s2,-70 # ffffffffc02d1f90 <proc_list>
ffffffffc0203fde:	08f55c63          	bge	a0,a5,ffffffffc0204076 <do_fork+0x1fe>

    // lab6:2310675 step5: allocate pid and insert into global lists atomically
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
ffffffffc0203fe2:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203fe4:	45a9                	li	a1,10
ffffffffc0203fe6:	2501                	sext.w	a0,a0
ffffffffc0203fe8:	3c2010ef          	jal	ra,ffffffffc02053aa <hash32>
ffffffffc0203fec:	02051793          	slli	a5,a0,0x20
ffffffffc0203ff0:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203ff4:	000ca797          	auipc	a5,0xca
ffffffffc0203ff8:	f9c78793          	addi	a5,a5,-100 # ffffffffc02cdf90 <hash_list>
ffffffffc0203ffc:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0203ffe:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204000:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204002:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc0204006:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204008:	00893603          	ld	a2,8(s2)
    prev->next = next->prev = elm;
ffffffffc020400c:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020400e:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204010:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc0204014:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc0204016:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc0204018:	e21c                	sd	a5,0(a2)
ffffffffc020401a:	00f93423          	sd	a5,8(s2)
    elm->next = next;
ffffffffc020401e:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc0204020:	0d243423          	sd	s2,200(s0)
    proc->yptr = NULL;
ffffffffc0204024:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204028:	10e43023          	sd	a4,256(s0)
ffffffffc020402c:	c311                	beqz	a4,ffffffffc0204030 <do_fork+0x1b8>
        proc->optr->yptr = proc;
ffffffffc020402e:	ff60                	sd	s0,248(a4)
    nr_process++;
ffffffffc0204030:	409c                	lw	a5,0(s1)
    proc->parent->cptr = proc;
ffffffffc0204032:	fae0                	sd	s0,240(a3)
    nr_process++;
ffffffffc0204034:	2785                	addiw	a5,a5,1
ffffffffc0204036:	c09c                	sw	a5,0(s1)
    if (flag)
ffffffffc0204038:	12099a63          	bnez	s3,ffffffffc020416c <do_fork+0x2f4>
        set_links(proc);
    }
    local_intr_restore(intr_flag);

    // lab6:2310675 step6: make the child runnable
    wakeup_proc(proc);
ffffffffc020403c:	8522                	mv	a0,s0
ffffffffc020403e:	0fa010ef          	jal	ra,ffffffffc0205138 <wakeup_proc>

    // lab6:2310675 step7: return child's pid in parent
    ret = proc->pid;
ffffffffc0204042:	00442a03          	lw	s4,4(s0)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc0204046:	70e6                	ld	ra,120(sp)
ffffffffc0204048:	7446                	ld	s0,112(sp)
ffffffffc020404a:	74a6                	ld	s1,104(sp)
ffffffffc020404c:	7906                	ld	s2,96(sp)
ffffffffc020404e:	69e6                	ld	s3,88(sp)
ffffffffc0204050:	6aa6                	ld	s5,72(sp)
ffffffffc0204052:	6b06                	ld	s6,64(sp)
ffffffffc0204054:	7be2                	ld	s7,56(sp)
ffffffffc0204056:	7c42                	ld	s8,48(sp)
ffffffffc0204058:	7ca2                	ld	s9,40(sp)
ffffffffc020405a:	7d02                	ld	s10,32(sp)
ffffffffc020405c:	6de2                	ld	s11,24(sp)
ffffffffc020405e:	8552                	mv	a0,s4
ffffffffc0204060:	6a46                	ld	s4,80(sp)
ffffffffc0204062:	6109                	addi	sp,sp,128
ffffffffc0204064:	8082                	ret
        last_pid = 1;
ffffffffc0204066:	4785                	li	a5,1
ffffffffc0204068:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020406c:	4505                	li	a0,1
ffffffffc020406e:	000ca317          	auipc	t1,0xca
ffffffffc0204072:	b0630313          	addi	t1,t1,-1274 # ffffffffc02cdb74 <next_safe.0>
    return listelm->next;
ffffffffc0204076:	000ce917          	auipc	s2,0xce
ffffffffc020407a:	f1a90913          	addi	s2,s2,-230 # ffffffffc02d1f90 <proc_list>
ffffffffc020407e:	00893e03          	ld	t3,8(s2)
        next_safe = MAX_PID;
ffffffffc0204082:	6789                	lui	a5,0x2
ffffffffc0204084:	00f32023          	sw	a5,0(t1)
ffffffffc0204088:	86aa                	mv	a3,a0
ffffffffc020408a:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020408c:	6e89                	lui	t4,0x2
ffffffffc020408e:	132e0e63          	beq	t3,s2,ffffffffc02041ca <do_fork+0x352>
ffffffffc0204092:	88ae                	mv	a7,a1
ffffffffc0204094:	87f2                	mv	a5,t3
ffffffffc0204096:	6609                	lui	a2,0x2
ffffffffc0204098:	a811                	j	ffffffffc02040ac <do_fork+0x234>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020409a:	00e6d663          	bge	a3,a4,ffffffffc02040a6 <do_fork+0x22e>
ffffffffc020409e:	00c75463          	bge	a4,a2,ffffffffc02040a6 <do_fork+0x22e>
ffffffffc02040a2:	863a                	mv	a2,a4
ffffffffc02040a4:	4885                	li	a7,1
ffffffffc02040a6:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02040a8:	01278d63          	beq	a5,s2,ffffffffc02040c2 <do_fork+0x24a>
            if (proc->pid == last_pid)
ffffffffc02040ac:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7ff4>
ffffffffc02040b0:	fed715e3          	bne	a4,a3,ffffffffc020409a <do_fork+0x222>
                if (++last_pid >= next_safe)
ffffffffc02040b4:	2685                	addiw	a3,a3,1
ffffffffc02040b6:	0ec6dd63          	bge	a3,a2,ffffffffc02041b0 <do_fork+0x338>
ffffffffc02040ba:	679c                	ld	a5,8(a5)
ffffffffc02040bc:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02040be:	ff2797e3          	bne	a5,s2,ffffffffc02040ac <do_fork+0x234>
ffffffffc02040c2:	c581                	beqz	a1,ffffffffc02040ca <do_fork+0x252>
ffffffffc02040c4:	00d82023          	sw	a3,0(a6)
ffffffffc02040c8:	8536                	mv	a0,a3
ffffffffc02040ca:	f0088ce3          	beqz	a7,ffffffffc0203fe2 <do_fork+0x16a>
ffffffffc02040ce:	00c32023          	sw	a2,0(t1)
ffffffffc02040d2:	bf01                	j	ffffffffc0203fe2 <do_fork+0x16a>
    if ((mm = mm_create()) == NULL)
ffffffffc02040d4:	d04ff0ef          	jal	ra,ffffffffc02035d8 <mm_create>
ffffffffc02040d8:	8c2a                	mv	s8,a0
ffffffffc02040da:	10050263          	beqz	a0,ffffffffc02041de <do_fork+0x366>
    if ((page = alloc_page()) == NULL)
ffffffffc02040de:	4505                	li	a0,1
ffffffffc02040e0:	cc9fd0ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc02040e4:	c559                	beqz	a0,ffffffffc0204172 <do_fork+0x2fa>
    return page - pages + nbase;
ffffffffc02040e6:	000cb683          	ld	a3,0(s9)
ffffffffc02040ea:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc02040ec:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc02040f0:	40d506b3          	sub	a3,a0,a3
ffffffffc02040f4:	8699                	srai	a3,a3,0x6
ffffffffc02040f6:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02040f8:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02040fc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02040fe:	10fb7263          	bgeu	s6,a5,ffffffffc0204202 <do_fork+0x38a>
ffffffffc0204102:	000dba03          	ld	s4,0(s11)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204106:	6605                	lui	a2,0x1
ffffffffc0204108:	000ce597          	auipc	a1,0xce
ffffffffc020410c:	ef85b583          	ld	a1,-264(a1) # ffffffffc02d2000 <boot_pgdir_va>
ffffffffc0204110:	9a36                	add	s4,s4,a3
ffffffffc0204112:	8552                	mv	a0,s4
ffffffffc0204114:	74e010ef          	jal	ra,ffffffffc0205862 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204118:	038b8b13          	addi	s6,s7,56
    mm->pgdir = pgdir;
ffffffffc020411c:	014c3c23          	sd	s4,24(s8)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204120:	4785                	li	a5,1
ffffffffc0204122:	40fb37af          	amoor.d	a5,a5,(s6)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204126:	8b85                	andi	a5,a5,1
ffffffffc0204128:	4a05                	li	s4,1
ffffffffc020412a:	c799                	beqz	a5,ffffffffc0204138 <do_fork+0x2c0>
    {
        schedule();
ffffffffc020412c:	0be010ef          	jal	ra,ffffffffc02051ea <schedule>
ffffffffc0204130:	414b37af          	amoor.d	a5,s4,(s6)
    while (!try_lock(lock))
ffffffffc0204134:	8b85                	andi	a5,a5,1
ffffffffc0204136:	fbfd                	bnez	a5,ffffffffc020412c <do_fork+0x2b4>
        ret = dup_mmap(mm, oldmm);
ffffffffc0204138:	85de                	mv	a1,s7
ffffffffc020413a:	8562                	mv	a0,s8
ffffffffc020413c:	edeff0ef          	jal	ra,ffffffffc020381a <dup_mmap>
ffffffffc0204140:	8a2a                	mv	s4,a0
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204142:	57f9                	li	a5,-2
ffffffffc0204144:	60fb37af          	amoand.d	a5,a5,(s6)
ffffffffc0204148:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020414a:	10078063          	beqz	a5,ffffffffc020424a <do_fork+0x3d2>
good_mm:
ffffffffc020414e:	8be2                	mv	s7,s8
    if (ret != 0)
ffffffffc0204150:	de0503e3          	beqz	a0,ffffffffc0203f36 <do_fork+0xbe>
    exit_mmap(mm);
ffffffffc0204154:	8562                	mv	a0,s8
ffffffffc0204156:	f5eff0ef          	jal	ra,ffffffffc02038b4 <exit_mmap>
    put_pgdir(mm);
ffffffffc020415a:	8562                	mv	a0,s8
ffffffffc020415c:	c37ff0ef          	jal	ra,ffffffffc0203d92 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204160:	8562                	mv	a0,s8
ffffffffc0204162:	db6ff0ef          	jal	ra,ffffffffc0203718 <mm_destroy>
ffffffffc0204166:	a811                	j	ffffffffc020417a <do_fork+0x302>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204168:	8936                	mv	s2,a3
ffffffffc020416a:	b52d                	j	ffffffffc0203f94 <do_fork+0x11c>
        intr_enable();
ffffffffc020416c:	83dfc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204170:	b5f1                	j	ffffffffc020403c <do_fork+0x1c4>
    mm_destroy(mm);
ffffffffc0204172:	8562                	mv	a0,s8
ffffffffc0204174:	da4ff0ef          	jal	ra,ffffffffc0203718 <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc0204178:	5a71                	li	s4,-4
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020417a:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020417c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204180:	0af6e963          	bltu	a3,a5,ffffffffc0204232 <do_fork+0x3ba>
ffffffffc0204184:	000db703          	ld	a4,0(s11)
    if (PPN(pa) >= npage)
ffffffffc0204188:	000d3783          	ld	a5,0(s10)
    return pa2page(PADDR(kva));
ffffffffc020418c:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc020418e:	82b1                	srli	a3,a3,0xc
ffffffffc0204190:	08f6f563          	bgeu	a3,a5,ffffffffc020421a <do_fork+0x3a2>
    return &pages[PPN(pa) - nbase];
ffffffffc0204194:	000ab783          	ld	a5,0(s5)
ffffffffc0204198:	000cb503          	ld	a0,0(s9)
ffffffffc020419c:	4589                	li	a1,2
ffffffffc020419e:	8e9d                	sub	a3,a3,a5
ffffffffc02041a0:	069a                	slli	a3,a3,0x6
ffffffffc02041a2:	9536                	add	a0,a0,a3
ffffffffc02041a4:	c43fd0ef          	jal	ra,ffffffffc0201de6 <free_pages>
    kfree(proc);
ffffffffc02041a8:	8522                	mv	a0,s0
ffffffffc02041aa:	ad1fd0ef          	jal	ra,ffffffffc0201c7a <kfree>
    return ret;
ffffffffc02041ae:	bd61                	j	ffffffffc0204046 <do_fork+0x1ce>
                    if (last_pid >= MAX_PID)
ffffffffc02041b0:	01d6c363          	blt	a3,t4,ffffffffc02041b6 <do_fork+0x33e>
                        last_pid = 1;
ffffffffc02041b4:	4685                	li	a3,1
                    goto repeat;
ffffffffc02041b6:	4585                	li	a1,1
ffffffffc02041b8:	bdd9                	j	ffffffffc020408e <do_fork+0x216>
        intr_disable();
ffffffffc02041ba:	ff4fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02041be:	4985                	li	s3,1
ffffffffc02041c0:	bbc5                	j	ffffffffc0203fb0 <do_fork+0x138>
    return -E_NO_MEM;
ffffffffc02041c2:	5a71                	li	s4,-4
ffffffffc02041c4:	b7d5                	j	ffffffffc02041a8 <do_fork+0x330>
    int ret = -E_NO_FREE_PROC;
ffffffffc02041c6:	5a6d                	li	s4,-5
ffffffffc02041c8:	bdbd                	j	ffffffffc0204046 <do_fork+0x1ce>
ffffffffc02041ca:	c599                	beqz	a1,ffffffffc02041d8 <do_fork+0x360>
ffffffffc02041cc:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02041d0:	8536                	mv	a0,a3
ffffffffc02041d2:	bd01                	j	ffffffffc0203fe2 <do_fork+0x16a>
    ret = -E_NO_MEM;
ffffffffc02041d4:	5a71                	li	s4,-4
ffffffffc02041d6:	bd85                	j	ffffffffc0204046 <do_fork+0x1ce>
    return last_pid;
ffffffffc02041d8:	00082503          	lw	a0,0(a6)
ffffffffc02041dc:	b519                	j	ffffffffc0203fe2 <do_fork+0x16a>
    int ret = -E_NO_MEM;
ffffffffc02041de:	5a71                	li	s4,-4
ffffffffc02041e0:	bf69                	j	ffffffffc020417a <do_fork+0x302>
    assert(current->wait_state == 0);
ffffffffc02041e2:	00003697          	auipc	a3,0x3
ffffffffc02041e6:	ed668693          	addi	a3,a3,-298 # ffffffffc02070b8 <default_pmm_manager+0x9f8>
ffffffffc02041ea:	00002617          	auipc	a2,0x2
ffffffffc02041ee:	12660613          	addi	a2,a2,294 # ffffffffc0206310 <commands+0x828>
ffffffffc02041f2:	1f800593          	li	a1,504
ffffffffc02041f6:	00003517          	auipc	a0,0x3
ffffffffc02041fa:	ee250513          	addi	a0,a0,-286 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc02041fe:	a94fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204202:	00002617          	auipc	a2,0x2
ffffffffc0204206:	4f660613          	addi	a2,a2,1270 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc020420a:	07100593          	li	a1,113
ffffffffc020420e:	00002517          	auipc	a0,0x2
ffffffffc0204212:	51250513          	addi	a0,a0,1298 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc0204216:	a7cfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020421a:	00002617          	auipc	a2,0x2
ffffffffc020421e:	5ae60613          	addi	a2,a2,1454 # ffffffffc02067c8 <default_pmm_manager+0x108>
ffffffffc0204222:	06900593          	li	a1,105
ffffffffc0204226:	00002517          	auipc	a0,0x2
ffffffffc020422a:	4fa50513          	addi	a0,a0,1274 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc020422e:	a64fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204232:	00002617          	auipc	a2,0x2
ffffffffc0204236:	56e60613          	addi	a2,a2,1390 # ffffffffc02067a0 <default_pmm_manager+0xe0>
ffffffffc020423a:	07700593          	li	a1,119
ffffffffc020423e:	00002517          	auipc	a0,0x2
ffffffffc0204242:	4e250513          	addi	a0,a0,1250 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc0204246:	a4cfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc020424a:	00003617          	auipc	a2,0x3
ffffffffc020424e:	ea660613          	addi	a2,a2,-346 # ffffffffc02070f0 <default_pmm_manager+0xa30>
ffffffffc0204252:	04000593          	li	a1,64
ffffffffc0204256:	00003517          	auipc	a0,0x3
ffffffffc020425a:	eaa50513          	addi	a0,a0,-342 # ffffffffc0207100 <default_pmm_manager+0xa40>
ffffffffc020425e:	a34fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204262:	86be                	mv	a3,a5
ffffffffc0204264:	00002617          	auipc	a2,0x2
ffffffffc0204268:	53c60613          	addi	a2,a2,1340 # ffffffffc02067a0 <default_pmm_manager+0xe0>
ffffffffc020426c:	1a500593          	li	a1,421
ffffffffc0204270:	00003517          	auipc	a0,0x3
ffffffffc0204274:	e6850513          	addi	a0,a0,-408 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204278:	a1afc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020427c <kernel_thread>:
{
ffffffffc020427c:	7129                	addi	sp,sp,-320
ffffffffc020427e:	fa22                	sd	s0,304(sp)
ffffffffc0204280:	f626                	sd	s1,296(sp)
ffffffffc0204282:	f24a                	sd	s2,288(sp)
ffffffffc0204284:	84ae                	mv	s1,a1
ffffffffc0204286:	892a                	mv	s2,a0
ffffffffc0204288:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020428a:	4581                	li	a1,0
ffffffffc020428c:	12000613          	li	a2,288
ffffffffc0204290:	850a                	mv	a0,sp
{
ffffffffc0204292:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204294:	5bc010ef          	jal	ra,ffffffffc0205850 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204298:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020429a:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020429c:	100027f3          	csrr	a5,sstatus
ffffffffc02042a0:	edd7f793          	andi	a5,a5,-291
ffffffffc02042a4:	1207e793          	ori	a5,a5,288
ffffffffc02042a8:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02042aa:	860a                	mv	a2,sp
ffffffffc02042ac:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02042b0:	00000797          	auipc	a5,0x0
ffffffffc02042b4:	a3278793          	addi	a5,a5,-1486 # ffffffffc0203ce2 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02042b8:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02042ba:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02042bc:	bbdff0ef          	jal	ra,ffffffffc0203e78 <do_fork>
}
ffffffffc02042c0:	70f2                	ld	ra,312(sp)
ffffffffc02042c2:	7452                	ld	s0,304(sp)
ffffffffc02042c4:	74b2                	ld	s1,296(sp)
ffffffffc02042c6:	7912                	ld	s2,288(sp)
ffffffffc02042c8:	6131                	addi	sp,sp,320
ffffffffc02042ca:	8082                	ret

ffffffffc02042cc <do_exit>:
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
//
// 这是实验指导书中提到的“主动调度”触发点之一：进程退出后会主动调用 schedule() 让出 CPU。
int do_exit(int error_code)
{
ffffffffc02042cc:	7179                	addi	sp,sp,-48
ffffffffc02042ce:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02042d0:	000ce417          	auipc	s0,0xce
ffffffffc02042d4:	d5840413          	addi	s0,s0,-680 # ffffffffc02d2028 <current>
ffffffffc02042d8:	601c                	ld	a5,0(s0)
{
ffffffffc02042da:	f406                	sd	ra,40(sp)
ffffffffc02042dc:	ec26                	sd	s1,24(sp)
ffffffffc02042de:	e84a                	sd	s2,16(sp)
ffffffffc02042e0:	e44e                	sd	s3,8(sp)
ffffffffc02042e2:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02042e4:	000ce717          	auipc	a4,0xce
ffffffffc02042e8:	d4c73703          	ld	a4,-692(a4) # ffffffffc02d2030 <idleproc>
ffffffffc02042ec:	0ce78c63          	beq	a5,a4,ffffffffc02043c4 <do_exit+0xf8>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc02042f0:	000ce497          	auipc	s1,0xce
ffffffffc02042f4:	d4848493          	addi	s1,s1,-696 # ffffffffc02d2038 <initproc>
ffffffffc02042f8:	6098                	ld	a4,0(s1)
ffffffffc02042fa:	0ee78b63          	beq	a5,a4,ffffffffc02043f0 <do_exit+0x124>
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc02042fe:	0287b983          	ld	s3,40(a5)
ffffffffc0204302:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204304:	02098663          	beqz	s3,ffffffffc0204330 <do_exit+0x64>
ffffffffc0204308:	000ce797          	auipc	a5,0xce
ffffffffc020430c:	cf07b783          	ld	a5,-784(a5) # ffffffffc02d1ff8 <boot_pgdir_pa>
ffffffffc0204310:	577d                	li	a4,-1
ffffffffc0204312:	177e                	slli	a4,a4,0x3f
ffffffffc0204314:	83b1                	srli	a5,a5,0xc
ffffffffc0204316:	8fd9                	or	a5,a5,a4
ffffffffc0204318:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020431c:	0309a783          	lw	a5,48(s3)
ffffffffc0204320:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204324:	02e9a823          	sw	a4,48(s3)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc0204328:	cb55                	beqz	a4,ffffffffc02043dc <do_exit+0x110>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc020432a:	601c                	ld	a5,0(s0)
ffffffffc020432c:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc0204330:	601c                	ld	a5,0(s0)
ffffffffc0204332:	470d                	li	a4,3
ffffffffc0204334:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204336:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020433a:	100027f3          	csrr	a5,sstatus
ffffffffc020433e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204340:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204342:	e3f9                	bnez	a5,ffffffffc0204408 <do_exit+0x13c>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc0204344:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204346:	800007b7          	lui	a5,0x80000
ffffffffc020434a:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc020434c:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020434e:	0ec52703          	lw	a4,236(a0)
ffffffffc0204352:	0af70f63          	beq	a4,a5,ffffffffc0204410 <do_exit+0x144>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc0204356:	6018                	ld	a4,0(s0)
ffffffffc0204358:	7b7c                	ld	a5,240(a4)
ffffffffc020435a:	c3a1                	beqz	a5,ffffffffc020439a <do_exit+0xce>
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc020435c:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204360:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204362:	0985                	addi	s3,s3,1
ffffffffc0204364:	a021                	j	ffffffffc020436c <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204366:	6018                	ld	a4,0(s0)
ffffffffc0204368:	7b7c                	ld	a5,240(a4)
ffffffffc020436a:	cb85                	beqz	a5,ffffffffc020439a <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc020436c:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_matrix_out_size+0xffffffff7fff39f8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204370:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204372:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204374:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204376:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020437a:	10e7b023          	sd	a4,256(a5)
ffffffffc020437e:	c311                	beqz	a4,ffffffffc0204382 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204380:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204382:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204384:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204386:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204388:	fd271fe3          	bne	a4,s2,ffffffffc0204366 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020438c:	0ec52783          	lw	a5,236(a0)
ffffffffc0204390:	fd379be3          	bne	a5,s3,ffffffffc0204366 <do_exit+0x9a>
                {
                    wakeup_proc(initproc);
ffffffffc0204394:	5a5000ef          	jal	ra,ffffffffc0205138 <wakeup_proc>
ffffffffc0204398:	b7f9                	j	ffffffffc0204366 <do_exit+0x9a>
    if (flag)
ffffffffc020439a:	020a1263          	bnez	s4,ffffffffc02043be <do_exit+0xf2>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc020439e:	64d000ef          	jal	ra,ffffffffc02051ea <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02043a2:	601c                	ld	a5,0(s0)
ffffffffc02043a4:	00003617          	auipc	a2,0x3
ffffffffc02043a8:	d9460613          	addi	a2,a2,-620 # ffffffffc0207138 <default_pmm_manager+0xa78>
ffffffffc02043ac:	26100593          	li	a1,609
ffffffffc02043b0:	43d4                	lw	a3,4(a5)
ffffffffc02043b2:	00003517          	auipc	a0,0x3
ffffffffc02043b6:	d2650513          	addi	a0,a0,-730 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc02043ba:	8d8fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_enable();
ffffffffc02043be:	deafc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02043c2:	bff1                	j	ffffffffc020439e <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02043c4:	00003617          	auipc	a2,0x3
ffffffffc02043c8:	d5460613          	addi	a2,a2,-684 # ffffffffc0207118 <default_pmm_manager+0xa58>
ffffffffc02043cc:	22d00593          	li	a1,557
ffffffffc02043d0:	00003517          	auipc	a0,0x3
ffffffffc02043d4:	d0850513          	addi	a0,a0,-760 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc02043d8:	8bafc0ef          	jal	ra,ffffffffc0200492 <__panic>
            exit_mmap(mm);
ffffffffc02043dc:	854e                	mv	a0,s3
ffffffffc02043de:	cd6ff0ef          	jal	ra,ffffffffc02038b4 <exit_mmap>
            put_pgdir(mm);
ffffffffc02043e2:	854e                	mv	a0,s3
ffffffffc02043e4:	9afff0ef          	jal	ra,ffffffffc0203d92 <put_pgdir>
            mm_destroy(mm);
ffffffffc02043e8:	854e                	mv	a0,s3
ffffffffc02043ea:	b2eff0ef          	jal	ra,ffffffffc0203718 <mm_destroy>
ffffffffc02043ee:	bf35                	j	ffffffffc020432a <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02043f0:	00003617          	auipc	a2,0x3
ffffffffc02043f4:	d3860613          	addi	a2,a2,-712 # ffffffffc0207128 <default_pmm_manager+0xa68>
ffffffffc02043f8:	23100593          	li	a1,561
ffffffffc02043fc:	00003517          	auipc	a0,0x3
ffffffffc0204400:	cdc50513          	addi	a0,a0,-804 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204404:	88efc0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_disable();
ffffffffc0204408:	da6fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc020440c:	4a05                	li	s4,1
ffffffffc020440e:	bf1d                	j	ffffffffc0204344 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204410:	529000ef          	jal	ra,ffffffffc0205138 <wakeup_proc>
ffffffffc0204414:	b789                	j	ffffffffc0204356 <do_exit+0x8a>

ffffffffc0204416 <do_wait.part.0>:
// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
//
// do_wait 也是“主动调度”触发点：如果子进程未退出，父进程进入 PROC_SLEEPING 并 schedule() 等待被唤醒。
int do_wait(int pid, int *code_store)
ffffffffc0204416:	715d                	addi	sp,sp,-80
ffffffffc0204418:	f84a                	sd	s2,48(sp)
ffffffffc020441a:	f44e                	sd	s3,40(sp)
        }
    }
    if (haskid)
    {
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
ffffffffc020441c:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204420:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204422:	fc26                	sd	s1,56(sp)
ffffffffc0204424:	f052                	sd	s4,32(sp)
ffffffffc0204426:	ec56                	sd	s5,24(sp)
ffffffffc0204428:	e85a                	sd	s6,16(sp)
ffffffffc020442a:	e45e                	sd	s7,8(sp)
ffffffffc020442c:	e486                	sd	ra,72(sp)
ffffffffc020442e:	e0a2                	sd	s0,64(sp)
ffffffffc0204430:	84aa                	mv	s1,a0
ffffffffc0204432:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204434:	000ceb97          	auipc	s7,0xce
ffffffffc0204438:	bf4b8b93          	addi	s7,s7,-1036 # ffffffffc02d2028 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc020443c:	00050b1b          	sext.w	s6,a0
ffffffffc0204440:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204444:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204446:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204448:	ccbd                	beqz	s1,ffffffffc02044c6 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc020444a:	0359e863          	bltu	s3,s5,ffffffffc020447a <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020444e:	45a9                	li	a1,10
ffffffffc0204450:	855a                	mv	a0,s6
ffffffffc0204452:	759000ef          	jal	ra,ffffffffc02053aa <hash32>
ffffffffc0204456:	02051793          	slli	a5,a0,0x20
ffffffffc020445a:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020445e:	000ca797          	auipc	a5,0xca
ffffffffc0204462:	b3278793          	addi	a5,a5,-1230 # ffffffffc02cdf90 <hash_list>
ffffffffc0204466:	953e                	add	a0,a0,a5
ffffffffc0204468:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc020446a:	a029                	j	ffffffffc0204474 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc020446c:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204470:	02978163          	beq	a5,s1,ffffffffc0204492 <do_wait.part.0+0x7c>
ffffffffc0204474:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204476:	fe851be3          	bne	a0,s0,ffffffffc020446c <do_wait.part.0+0x56>
        {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;
ffffffffc020447a:	5579                	li	a0,-2
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc020447c:	60a6                	ld	ra,72(sp)
ffffffffc020447e:	6406                	ld	s0,64(sp)
ffffffffc0204480:	74e2                	ld	s1,56(sp)
ffffffffc0204482:	7942                	ld	s2,48(sp)
ffffffffc0204484:	79a2                	ld	s3,40(sp)
ffffffffc0204486:	7a02                	ld	s4,32(sp)
ffffffffc0204488:	6ae2                	ld	s5,24(sp)
ffffffffc020448a:	6b42                	ld	s6,16(sp)
ffffffffc020448c:	6ba2                	ld	s7,8(sp)
ffffffffc020448e:	6161                	addi	sp,sp,80
ffffffffc0204490:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204492:	000bb683          	ld	a3,0(s7)
ffffffffc0204496:	f4843783          	ld	a5,-184(s0)
ffffffffc020449a:	fed790e3          	bne	a5,a3,ffffffffc020447a <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020449e:	f2842703          	lw	a4,-216(s0)
ffffffffc02044a2:	478d                	li	a5,3
ffffffffc02044a4:	0ef70b63          	beq	a4,a5,ffffffffc020459a <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc02044a8:	4785                	li	a5,1
ffffffffc02044aa:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc02044ac:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc02044b0:	53b000ef          	jal	ra,ffffffffc02051ea <schedule>
        if (current->flags & PF_EXITING)
ffffffffc02044b4:	000bb783          	ld	a5,0(s7)
ffffffffc02044b8:	0b07a783          	lw	a5,176(a5)
ffffffffc02044bc:	8b85                	andi	a5,a5,1
ffffffffc02044be:	d7c9                	beqz	a5,ffffffffc0204448 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02044c0:	555d                	li	a0,-9
ffffffffc02044c2:	e0bff0ef          	jal	ra,ffffffffc02042cc <do_exit>
        proc = current->cptr;
ffffffffc02044c6:	000bb683          	ld	a3,0(s7)
ffffffffc02044ca:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02044cc:	d45d                	beqz	s0,ffffffffc020447a <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044ce:	470d                	li	a4,3
ffffffffc02044d0:	a021                	j	ffffffffc02044d8 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02044d2:	10043403          	ld	s0,256(s0)
ffffffffc02044d6:	d869                	beqz	s0,ffffffffc02044a8 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044d8:	401c                	lw	a5,0(s0)
ffffffffc02044da:	fee79ce3          	bne	a5,a4,ffffffffc02044d2 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02044de:	000ce797          	auipc	a5,0xce
ffffffffc02044e2:	b527b783          	ld	a5,-1198(a5) # ffffffffc02d2030 <idleproc>
ffffffffc02044e6:	0c878963          	beq	a5,s0,ffffffffc02045b8 <do_wait.part.0+0x1a2>
ffffffffc02044ea:	000ce797          	auipc	a5,0xce
ffffffffc02044ee:	b4e7b783          	ld	a5,-1202(a5) # ffffffffc02d2038 <initproc>
ffffffffc02044f2:	0cf40363          	beq	s0,a5,ffffffffc02045b8 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02044f6:	000a0663          	beqz	s4,ffffffffc0204502 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02044fa:	0e842783          	lw	a5,232(s0)
ffffffffc02044fe:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204502:	100027f3          	csrr	a5,sstatus
ffffffffc0204506:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204508:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020450a:	e7c1                	bnez	a5,ffffffffc0204592 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020450c:	6c70                	ld	a2,216(s0)
ffffffffc020450e:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204510:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204514:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204516:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204518:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020451a:	6470                	ld	a2,200(s0)
ffffffffc020451c:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc020451e:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204520:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204522:	c319                	beqz	a4,ffffffffc0204528 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204524:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204526:	7c7c                	ld	a5,248(s0)
ffffffffc0204528:	c3b5                	beqz	a5,ffffffffc020458c <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc020452a:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc020452e:	000ce717          	auipc	a4,0xce
ffffffffc0204532:	b1270713          	addi	a4,a4,-1262 # ffffffffc02d2040 <nr_process>
ffffffffc0204536:	431c                	lw	a5,0(a4)
ffffffffc0204538:	37fd                	addiw	a5,a5,-1
ffffffffc020453a:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc020453c:	e5a9                	bnez	a1,ffffffffc0204586 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020453e:	6814                	ld	a3,16(s0)
ffffffffc0204540:	c02007b7          	lui	a5,0xc0200
ffffffffc0204544:	04f6ee63          	bltu	a3,a5,ffffffffc02045a0 <do_wait.part.0+0x18a>
ffffffffc0204548:	000ce797          	auipc	a5,0xce
ffffffffc020454c:	ad87b783          	ld	a5,-1320(a5) # ffffffffc02d2020 <va_pa_offset>
ffffffffc0204550:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204552:	82b1                	srli	a3,a3,0xc
ffffffffc0204554:	000ce797          	auipc	a5,0xce
ffffffffc0204558:	ab47b783          	ld	a5,-1356(a5) # ffffffffc02d2008 <npage>
ffffffffc020455c:	06f6fa63          	bgeu	a3,a5,ffffffffc02045d0 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204560:	00004517          	auipc	a0,0x4
ffffffffc0204564:	c3853503          	ld	a0,-968(a0) # ffffffffc0208198 <nbase>
ffffffffc0204568:	8e89                	sub	a3,a3,a0
ffffffffc020456a:	069a                	slli	a3,a3,0x6
ffffffffc020456c:	000ce517          	auipc	a0,0xce
ffffffffc0204570:	aa453503          	ld	a0,-1372(a0) # ffffffffc02d2010 <pages>
ffffffffc0204574:	9536                	add	a0,a0,a3
ffffffffc0204576:	4589                	li	a1,2
ffffffffc0204578:	86ffd0ef          	jal	ra,ffffffffc0201de6 <free_pages>
    kfree(proc);
ffffffffc020457c:	8522                	mv	a0,s0
ffffffffc020457e:	efcfd0ef          	jal	ra,ffffffffc0201c7a <kfree>
    return 0;
ffffffffc0204582:	4501                	li	a0,0
ffffffffc0204584:	bde5                	j	ffffffffc020447c <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204586:	c22fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020458a:	bf55                	j	ffffffffc020453e <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc020458c:	701c                	ld	a5,32(s0)
ffffffffc020458e:	fbf8                	sd	a4,240(a5)
ffffffffc0204590:	bf79                	j	ffffffffc020452e <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204592:	c1cfc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0204596:	4585                	li	a1,1
ffffffffc0204598:	bf95                	j	ffffffffc020450c <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020459a:	f2840413          	addi	s0,s0,-216
ffffffffc020459e:	b781                	j	ffffffffc02044de <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02045a0:	00002617          	auipc	a2,0x2
ffffffffc02045a4:	20060613          	addi	a2,a2,512 # ffffffffc02067a0 <default_pmm_manager+0xe0>
ffffffffc02045a8:	07700593          	li	a1,119
ffffffffc02045ac:	00002517          	auipc	a0,0x2
ffffffffc02045b0:	17450513          	addi	a0,a0,372 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc02045b4:	edffb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02045b8:	00003617          	auipc	a2,0x3
ffffffffc02045bc:	ba060613          	addi	a2,a2,-1120 # ffffffffc0207158 <default_pmm_manager+0xa98>
ffffffffc02045c0:	38800593          	li	a1,904
ffffffffc02045c4:	00003517          	auipc	a0,0x3
ffffffffc02045c8:	b1450513          	addi	a0,a0,-1260 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc02045cc:	ec7fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02045d0:	00002617          	auipc	a2,0x2
ffffffffc02045d4:	1f860613          	addi	a2,a2,504 # ffffffffc02067c8 <default_pmm_manager+0x108>
ffffffffc02045d8:	06900593          	li	a1,105
ffffffffc02045dc:	00002517          	auipc	a0,0x2
ffffffffc02045e0:	14450513          	addi	a0,a0,324 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc02045e4:	eaffb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02045e8 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02045e8:	1141                	addi	sp,sp,-16
ffffffffc02045ea:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02045ec:	83bfd0ef          	jal	ra,ffffffffc0201e26 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02045f0:	dd6fd0ef          	jal	ra,ffffffffc0201bc6 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02045f4:	4601                	li	a2,0
ffffffffc02045f6:	4581                	li	a1,0
ffffffffc02045f8:	00000517          	auipc	a0,0x0
ffffffffc02045fc:	63050513          	addi	a0,a0,1584 # ffffffffc0204c28 <user_main>
ffffffffc0204600:	c7dff0ef          	jal	ra,ffffffffc020427c <kernel_thread>
    if (pid <= 0)
ffffffffc0204604:	00a04563          	bgtz	a0,ffffffffc020460e <init_main+0x26>
ffffffffc0204608:	a071                	j	ffffffffc0204694 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc020460a:	3e1000ef          	jal	ra,ffffffffc02051ea <schedule>
    if (code_store != NULL)
ffffffffc020460e:	4581                	li	a1,0
ffffffffc0204610:	4501                	li	a0,0
ffffffffc0204612:	e05ff0ef          	jal	ra,ffffffffc0204416 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204616:	d975                	beqz	a0,ffffffffc020460a <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204618:	00003517          	auipc	a0,0x3
ffffffffc020461c:	b8050513          	addi	a0,a0,-1152 # ffffffffc0207198 <default_pmm_manager+0xad8>
ffffffffc0204620:	b79fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204624:	000ce797          	auipc	a5,0xce
ffffffffc0204628:	a147b783          	ld	a5,-1516(a5) # ffffffffc02d2038 <initproc>
ffffffffc020462c:	7bf8                	ld	a4,240(a5)
ffffffffc020462e:	e339                	bnez	a4,ffffffffc0204674 <init_main+0x8c>
ffffffffc0204630:	7ff8                	ld	a4,248(a5)
ffffffffc0204632:	e329                	bnez	a4,ffffffffc0204674 <init_main+0x8c>
ffffffffc0204634:	1007b703          	ld	a4,256(a5)
ffffffffc0204638:	ef15                	bnez	a4,ffffffffc0204674 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020463a:	000ce697          	auipc	a3,0xce
ffffffffc020463e:	a066a683          	lw	a3,-1530(a3) # ffffffffc02d2040 <nr_process>
ffffffffc0204642:	4709                	li	a4,2
ffffffffc0204644:	0ae69463          	bne	a3,a4,ffffffffc02046ec <init_main+0x104>
    return listelm->next;
ffffffffc0204648:	000ce697          	auipc	a3,0xce
ffffffffc020464c:	94868693          	addi	a3,a3,-1720 # ffffffffc02d1f90 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204650:	6698                	ld	a4,8(a3)
ffffffffc0204652:	0c878793          	addi	a5,a5,200
ffffffffc0204656:	06f71b63          	bne	a4,a5,ffffffffc02046cc <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020465a:	629c                	ld	a5,0(a3)
ffffffffc020465c:	04f71863          	bne	a4,a5,ffffffffc02046ac <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204660:	00003517          	auipc	a0,0x3
ffffffffc0204664:	c2050513          	addi	a0,a0,-992 # ffffffffc0207280 <default_pmm_manager+0xbc0>
ffffffffc0204668:	b31fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc020466c:	60a2                	ld	ra,8(sp)
ffffffffc020466e:	4501                	li	a0,0
ffffffffc0204670:	0141                	addi	sp,sp,16
ffffffffc0204672:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204674:	00003697          	auipc	a3,0x3
ffffffffc0204678:	b4c68693          	addi	a3,a3,-1204 # ffffffffc02071c0 <default_pmm_manager+0xb00>
ffffffffc020467c:	00002617          	auipc	a2,0x2
ffffffffc0204680:	c9460613          	addi	a2,a2,-876 # ffffffffc0206310 <commands+0x828>
ffffffffc0204684:	3f400593          	li	a1,1012
ffffffffc0204688:	00003517          	auipc	a0,0x3
ffffffffc020468c:	a5050513          	addi	a0,a0,-1456 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204690:	e03fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("create user_main failed.\n");
ffffffffc0204694:	00003617          	auipc	a2,0x3
ffffffffc0204698:	ae460613          	addi	a2,a2,-1308 # ffffffffc0207178 <default_pmm_manager+0xab8>
ffffffffc020469c:	3eb00593          	li	a1,1003
ffffffffc02046a0:	00003517          	auipc	a0,0x3
ffffffffc02046a4:	a3850513          	addi	a0,a0,-1480 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc02046a8:	debfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02046ac:	00003697          	auipc	a3,0x3
ffffffffc02046b0:	ba468693          	addi	a3,a3,-1116 # ffffffffc0207250 <default_pmm_manager+0xb90>
ffffffffc02046b4:	00002617          	auipc	a2,0x2
ffffffffc02046b8:	c5c60613          	addi	a2,a2,-932 # ffffffffc0206310 <commands+0x828>
ffffffffc02046bc:	3f700593          	li	a1,1015
ffffffffc02046c0:	00003517          	auipc	a0,0x3
ffffffffc02046c4:	a1850513          	addi	a0,a0,-1512 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc02046c8:	dcbfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02046cc:	00003697          	auipc	a3,0x3
ffffffffc02046d0:	b5468693          	addi	a3,a3,-1196 # ffffffffc0207220 <default_pmm_manager+0xb60>
ffffffffc02046d4:	00002617          	auipc	a2,0x2
ffffffffc02046d8:	c3c60613          	addi	a2,a2,-964 # ffffffffc0206310 <commands+0x828>
ffffffffc02046dc:	3f600593          	li	a1,1014
ffffffffc02046e0:	00003517          	auipc	a0,0x3
ffffffffc02046e4:	9f850513          	addi	a0,a0,-1544 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc02046e8:	dabfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_process == 2);
ffffffffc02046ec:	00003697          	auipc	a3,0x3
ffffffffc02046f0:	b2468693          	addi	a3,a3,-1244 # ffffffffc0207210 <default_pmm_manager+0xb50>
ffffffffc02046f4:	00002617          	auipc	a2,0x2
ffffffffc02046f8:	c1c60613          	addi	a2,a2,-996 # ffffffffc0206310 <commands+0x828>
ffffffffc02046fc:	3f500593          	li	a1,1013
ffffffffc0204700:	00003517          	auipc	a0,0x3
ffffffffc0204704:	9d850513          	addi	a0,a0,-1576 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204708:	d8bfb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020470c <do_execve>:
{
ffffffffc020470c:	7171                	addi	sp,sp,-176
ffffffffc020470e:	f0e2                	sd	s8,96(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204710:	000cec17          	auipc	s8,0xce
ffffffffc0204714:	918c0c13          	addi	s8,s8,-1768 # ffffffffc02d2028 <current>
ffffffffc0204718:	000c3783          	ld	a5,0(s8)
{
ffffffffc020471c:	e54e                	sd	s3,136(sp)
ffffffffc020471e:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204720:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204724:	e94a                	sd	s2,144(sp)
ffffffffc0204726:	f4de                	sd	s7,104(sp)
ffffffffc0204728:	892a                	mv	s2,a0
ffffffffc020472a:	8bb2                	mv	s7,a2
ffffffffc020472c:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020472e:	862e                	mv	a2,a1
ffffffffc0204730:	4681                	li	a3,0
ffffffffc0204732:	85aa                	mv	a1,a0
ffffffffc0204734:	854e                	mv	a0,s3
{
ffffffffc0204736:	f506                	sd	ra,168(sp)
ffffffffc0204738:	f122                	sd	s0,160(sp)
ffffffffc020473a:	e152                	sd	s4,128(sp)
ffffffffc020473c:	fcd6                	sd	s5,120(sp)
ffffffffc020473e:	f8da                	sd	s6,112(sp)
ffffffffc0204740:	ece6                	sd	s9,88(sp)
ffffffffc0204742:	e8ea                	sd	s10,80(sp)
ffffffffc0204744:	e4ee                	sd	s11,72(sp)
ffffffffc0204746:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204748:	d06ff0ef          	jal	ra,ffffffffc0203c4e <user_mem_check>
ffffffffc020474c:	40050e63          	beqz	a0,ffffffffc0204b68 <do_execve+0x45c>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204750:	4641                	li	a2,16
ffffffffc0204752:	4581                	li	a1,0
ffffffffc0204754:	1808                	addi	a0,sp,48
ffffffffc0204756:	0fa010ef          	jal	ra,ffffffffc0205850 <memset>
    memcpy(local_name, name, len);
ffffffffc020475a:	47bd                	li	a5,15
ffffffffc020475c:	8626                	mv	a2,s1
ffffffffc020475e:	1e97e663          	bltu	a5,s1,ffffffffc020494a <do_execve+0x23e>
ffffffffc0204762:	85ca                	mv	a1,s2
ffffffffc0204764:	1808                	addi	a0,sp,48
ffffffffc0204766:	0fc010ef          	jal	ra,ffffffffc0205862 <memcpy>
    if (mm != NULL)
ffffffffc020476a:	1e098763          	beqz	s3,ffffffffc0204958 <do_execve+0x24c>
        cputs("mm != NULL");
ffffffffc020476e:	00002517          	auipc	a0,0x2
ffffffffc0204772:	77250513          	addi	a0,a0,1906 # ffffffffc0206ee0 <default_pmm_manager+0x820>
ffffffffc0204776:	a5bfb0ef          	jal	ra,ffffffffc02001d0 <cputs>
ffffffffc020477a:	000ce797          	auipc	a5,0xce
ffffffffc020477e:	87e7b783          	ld	a5,-1922(a5) # ffffffffc02d1ff8 <boot_pgdir_pa>
ffffffffc0204782:	577d                	li	a4,-1
ffffffffc0204784:	177e                	slli	a4,a4,0x3f
ffffffffc0204786:	83b1                	srli	a5,a5,0xc
ffffffffc0204788:	8fd9                	or	a5,a5,a4
ffffffffc020478a:	18079073          	csrw	satp,a5
ffffffffc020478e:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7f00>
ffffffffc0204792:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204796:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020479a:	2c070863          	beqz	a4,ffffffffc0204a6a <do_execve+0x35e>
        current->mm = NULL;
ffffffffc020479e:	000c3783          	ld	a5,0(s8)
ffffffffc02047a2:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02047a6:	e33fe0ef          	jal	ra,ffffffffc02035d8 <mm_create>
ffffffffc02047aa:	84aa                	mv	s1,a0
ffffffffc02047ac:	1e050163          	beqz	a0,ffffffffc020498e <do_execve+0x282>
    if ((page = alloc_page()) == NULL)
ffffffffc02047b0:	4505                	li	a0,1
ffffffffc02047b2:	df6fd0ef          	jal	ra,ffffffffc0201da8 <alloc_pages>
ffffffffc02047b6:	3a050d63          	beqz	a0,ffffffffc0204b70 <do_execve+0x464>
    return page - pages + nbase;
ffffffffc02047ba:	000ced17          	auipc	s10,0xce
ffffffffc02047be:	856d0d13          	addi	s10,s10,-1962 # ffffffffc02d2010 <pages>
ffffffffc02047c2:	000d3683          	ld	a3,0(s10)
    return KADDR(page2pa(page));
ffffffffc02047c6:	000cec97          	auipc	s9,0xce
ffffffffc02047ca:	842c8c93          	addi	s9,s9,-1982 # ffffffffc02d2008 <npage>
    return page - pages + nbase;
ffffffffc02047ce:	00004717          	auipc	a4,0x4
ffffffffc02047d2:	9ca73703          	ld	a4,-1590(a4) # ffffffffc0208198 <nbase>
ffffffffc02047d6:	40d506b3          	sub	a3,a0,a3
ffffffffc02047da:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02047dc:	5afd                	li	s5,-1
ffffffffc02047de:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc02047e2:	96ba                	add	a3,a3,a4
ffffffffc02047e4:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02047e6:	00cad713          	srli	a4,s5,0xc
ffffffffc02047ea:	ec3a                	sd	a4,24(sp)
ffffffffc02047ec:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02047ee:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02047f0:	38f77463          	bgeu	a4,a5,ffffffffc0204b78 <do_execve+0x46c>
ffffffffc02047f4:	000ceb17          	auipc	s6,0xce
ffffffffc02047f8:	82cb0b13          	addi	s6,s6,-2004 # ffffffffc02d2020 <va_pa_offset>
ffffffffc02047fc:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204800:	6605                	lui	a2,0x1
ffffffffc0204802:	000cd597          	auipc	a1,0xcd
ffffffffc0204806:	7fe5b583          	ld	a1,2046(a1) # ffffffffc02d2000 <boot_pgdir_va>
ffffffffc020480a:	9936                	add	s2,s2,a3
ffffffffc020480c:	854a                	mv	a0,s2
ffffffffc020480e:	054010ef          	jal	ra,ffffffffc0205862 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204812:	7782                	ld	a5,32(sp)
ffffffffc0204814:	4398                	lw	a4,0(a5)
ffffffffc0204816:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc020481a:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc020481e:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b7e77>
ffffffffc0204822:	14f71c63          	bne	a4,a5,ffffffffc020497a <do_execve+0x26e>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204826:	7682                	ld	a3,32(sp)
ffffffffc0204828:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020482c:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204830:	00371793          	slli	a5,a4,0x3
ffffffffc0204834:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204836:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204838:	078e                	slli	a5,a5,0x3
ffffffffc020483a:	97ce                	add	a5,a5,s3
ffffffffc020483c:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc020483e:	00f9fc63          	bgeu	s3,a5,ffffffffc0204856 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204842:	0009a783          	lw	a5,0(s3)
ffffffffc0204846:	4705                	li	a4,1
ffffffffc0204848:	14e78563          	beq	a5,a4,ffffffffc0204992 <do_execve+0x286>
    for (; ph < ph_end; ph++)
ffffffffc020484c:	77a2                	ld	a5,40(sp)
ffffffffc020484e:	03898993          	addi	s3,s3,56
ffffffffc0204852:	fef9e8e3          	bltu	s3,a5,ffffffffc0204842 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204856:	4701                	li	a4,0
ffffffffc0204858:	46ad                	li	a3,11
ffffffffc020485a:	00100637          	lui	a2,0x100
ffffffffc020485e:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204862:	8526                	mv	a0,s1
ffffffffc0204864:	f07fe0ef          	jal	ra,ffffffffc020376a <mm_map>
ffffffffc0204868:	8a2a                	mv	s4,a0
ffffffffc020486a:	1e051663          	bnez	a0,ffffffffc0204a56 <do_execve+0x34a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc020486e:	6c88                	ld	a0,24(s1)
ffffffffc0204870:	467d                	li	a2,31
ffffffffc0204872:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204876:	c7dfe0ef          	jal	ra,ffffffffc02034f2 <pgdir_alloc_page>
ffffffffc020487a:	38050763          	beqz	a0,ffffffffc0204c08 <do_execve+0x4fc>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc020487e:	6c88                	ld	a0,24(s1)
ffffffffc0204880:	467d                	li	a2,31
ffffffffc0204882:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204886:	c6dfe0ef          	jal	ra,ffffffffc02034f2 <pgdir_alloc_page>
ffffffffc020488a:	34050f63          	beqz	a0,ffffffffc0204be8 <do_execve+0x4dc>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc020488e:	6c88                	ld	a0,24(s1)
ffffffffc0204890:	467d                	li	a2,31
ffffffffc0204892:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204896:	c5dfe0ef          	jal	ra,ffffffffc02034f2 <pgdir_alloc_page>
ffffffffc020489a:	32050763          	beqz	a0,ffffffffc0204bc8 <do_execve+0x4bc>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc020489e:	6c88                	ld	a0,24(s1)
ffffffffc02048a0:	467d                	li	a2,31
ffffffffc02048a2:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc02048a6:	c4dfe0ef          	jal	ra,ffffffffc02034f2 <pgdir_alloc_page>
ffffffffc02048aa:	2e050f63          	beqz	a0,ffffffffc0204ba8 <do_execve+0x49c>
    mm->mm_count += 1;
ffffffffc02048ae:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc02048b0:	000c3703          	ld	a4,0(s8)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02048b4:	6c94                	ld	a3,24(s1)
ffffffffc02048b6:	2785                	addiw	a5,a5,1
ffffffffc02048b8:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc02048ba:	f704                	sd	s1,40(a4)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02048bc:	c02007b7          	lui	a5,0xc0200
ffffffffc02048c0:	2cf6e863          	bltu	a3,a5,ffffffffc0204b90 <do_execve+0x484>
ffffffffc02048c4:	000b3783          	ld	a5,0(s6)
ffffffffc02048c8:	8e9d                	sub	a3,a3,a5
ffffffffc02048ca:	f754                	sd	a3,168(a4)
ffffffffc02048cc:	577d                	li	a4,-1
ffffffffc02048ce:	00c6d793          	srli	a5,a3,0xc
ffffffffc02048d2:	177e                	slli	a4,a4,0x3f
ffffffffc02048d4:	8fd9                	or	a5,a5,a4
ffffffffc02048d6:	18079073          	csrw	satp,a5
    asm volatile("sfence.vma");
ffffffffc02048da:	12000073          	sfence.vma
    struct trapframe *tf = current->tf;
ffffffffc02048de:	000c3783          	ld	a5,0(s8)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02048e2:	12000613          	li	a2,288
ffffffffc02048e6:	4581                	li	a1,0
    struct trapframe *tf = current->tf;
ffffffffc02048e8:	73c0                	ld	s0,160(a5)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02048ea:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc02048ec:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02048f0:	761000ef          	jal	ra,ffffffffc0205850 <memset>
    tf->epc = elf->e_entry;
ffffffffc02048f4:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02048f6:	000c3903          	ld	s2,0(s8)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02048fa:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc02048fe:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204900:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204902:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_matrix_out_size+0xffffffff7fff39ac>
    tf->gpr.sp = USTACKTOP;
ffffffffc0204906:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204908:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020490c:	4641                	li	a2,16
ffffffffc020490e:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204910:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204912:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204916:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020491a:	854a                	mv	a0,s2
ffffffffc020491c:	735000ef          	jal	ra,ffffffffc0205850 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204920:	463d                	li	a2,15
ffffffffc0204922:	180c                	addi	a1,sp,48
ffffffffc0204924:	854a                	mv	a0,s2
ffffffffc0204926:	73d000ef          	jal	ra,ffffffffc0205862 <memcpy>
}
ffffffffc020492a:	70aa                	ld	ra,168(sp)
ffffffffc020492c:	740a                	ld	s0,160(sp)
ffffffffc020492e:	64ea                	ld	s1,152(sp)
ffffffffc0204930:	694a                	ld	s2,144(sp)
ffffffffc0204932:	69aa                	ld	s3,136(sp)
ffffffffc0204934:	7ae6                	ld	s5,120(sp)
ffffffffc0204936:	7b46                	ld	s6,112(sp)
ffffffffc0204938:	7ba6                	ld	s7,104(sp)
ffffffffc020493a:	7c06                	ld	s8,96(sp)
ffffffffc020493c:	6ce6                	ld	s9,88(sp)
ffffffffc020493e:	6d46                	ld	s10,80(sp)
ffffffffc0204940:	6da6                	ld	s11,72(sp)
ffffffffc0204942:	8552                	mv	a0,s4
ffffffffc0204944:	6a0a                	ld	s4,128(sp)
ffffffffc0204946:	614d                	addi	sp,sp,176
ffffffffc0204948:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc020494a:	463d                	li	a2,15
ffffffffc020494c:	85ca                	mv	a1,s2
ffffffffc020494e:	1808                	addi	a0,sp,48
ffffffffc0204950:	713000ef          	jal	ra,ffffffffc0205862 <memcpy>
    if (mm != NULL)
ffffffffc0204954:	e0099de3          	bnez	s3,ffffffffc020476e <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204958:	000c3783          	ld	a5,0(s8)
ffffffffc020495c:	779c                	ld	a5,40(a5)
ffffffffc020495e:	e40784e3          	beqz	a5,ffffffffc02047a6 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204962:	00003617          	auipc	a2,0x3
ffffffffc0204966:	93e60613          	addi	a2,a2,-1730 # ffffffffc02072a0 <default_pmm_manager+0xbe0>
ffffffffc020496a:	26d00593          	li	a1,621
ffffffffc020496e:	00002517          	auipc	a0,0x2
ffffffffc0204972:	76a50513          	addi	a0,a0,1898 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204976:	b1dfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    put_pgdir(mm);
ffffffffc020497a:	8526                	mv	a0,s1
ffffffffc020497c:	c16ff0ef          	jal	ra,ffffffffc0203d92 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204980:	8526                	mv	a0,s1
ffffffffc0204982:	d97fe0ef          	jal	ra,ffffffffc0203718 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204986:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204988:	8552                	mv	a0,s4
ffffffffc020498a:	943ff0ef          	jal	ra,ffffffffc02042cc <do_exit>
    int ret = -E_NO_MEM;
ffffffffc020498e:	5a71                	li	s4,-4
ffffffffc0204990:	bfe5                	j	ffffffffc0204988 <do_execve+0x27c>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204992:	0289b603          	ld	a2,40(s3)
ffffffffc0204996:	0209b783          	ld	a5,32(s3)
ffffffffc020499a:	1cf66d63          	bltu	a2,a5,ffffffffc0204b74 <do_execve+0x468>
        if (ph->p_flags & ELF_PF_X)
ffffffffc020499e:	0049a783          	lw	a5,4(s3)
ffffffffc02049a2:	0017f693          	andi	a3,a5,1
ffffffffc02049a6:	c291                	beqz	a3,ffffffffc02049aa <do_execve+0x29e>
            vm_flags |= VM_EXEC;
ffffffffc02049a8:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02049aa:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc02049ae:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02049b0:	e779                	bnez	a4,ffffffffc0204a7e <do_execve+0x372>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc02049b2:	4dc5                	li	s11,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc02049b4:	c781                	beqz	a5,ffffffffc02049bc <do_execve+0x2b0>
            vm_flags |= VM_READ;
ffffffffc02049b6:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc02049ba:	4dcd                	li	s11,19
        if (vm_flags & VM_WRITE)
ffffffffc02049bc:	0026f793          	andi	a5,a3,2
ffffffffc02049c0:	e3f1                	bnez	a5,ffffffffc0204a84 <do_execve+0x378>
        if (vm_flags & VM_EXEC)
ffffffffc02049c2:	0046f793          	andi	a5,a3,4
ffffffffc02049c6:	c399                	beqz	a5,ffffffffc02049cc <do_execve+0x2c0>
            perm |= PTE_X;
ffffffffc02049c8:	008ded93          	ori	s11,s11,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc02049cc:	0109b583          	ld	a1,16(s3)
ffffffffc02049d0:	4701                	li	a4,0
ffffffffc02049d2:	8526                	mv	a0,s1
ffffffffc02049d4:	d97fe0ef          	jal	ra,ffffffffc020376a <mm_map>
ffffffffc02049d8:	8a2a                	mv	s4,a0
ffffffffc02049da:	ed35                	bnez	a0,ffffffffc0204a56 <do_execve+0x34a>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049dc:	0109bb83          	ld	s7,16(s3)
ffffffffc02049e0:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc02049e2:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049e6:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049ea:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049ee:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc02049f0:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049f2:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc02049f4:	054be963          	bltu	s7,s4,ffffffffc0204a46 <do_execve+0x33a>
ffffffffc02049f8:	aa95                	j	ffffffffc0204b6c <do_execve+0x460>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc02049fa:	6785                	lui	a5,0x1
ffffffffc02049fc:	415b8533          	sub	a0,s7,s5
ffffffffc0204a00:	9abe                	add	s5,s5,a5
ffffffffc0204a02:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204a06:	015a7463          	bgeu	s4,s5,ffffffffc0204a0e <do_execve+0x302>
                size -= la - end;
ffffffffc0204a0a:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204a0e:	000d3683          	ld	a3,0(s10)
ffffffffc0204a12:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204a14:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204a18:	40d406b3          	sub	a3,s0,a3
ffffffffc0204a1c:	8699                	srai	a3,a3,0x6
ffffffffc0204a1e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204a20:	67e2                	ld	a5,24(sp)
ffffffffc0204a22:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a26:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a28:	14b87863          	bgeu	a6,a1,ffffffffc0204b78 <do_execve+0x46c>
ffffffffc0204a2c:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a30:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204a32:	9bb2                	add	s7,s7,a2
ffffffffc0204a34:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a36:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204a38:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a3a:	629000ef          	jal	ra,ffffffffc0205862 <memcpy>
            start += size, from += size;
ffffffffc0204a3e:	6622                	ld	a2,8(sp)
ffffffffc0204a40:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204a42:	054bf363          	bgeu	s7,s4,ffffffffc0204a88 <do_execve+0x37c>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204a46:	6c88                	ld	a0,24(s1)
ffffffffc0204a48:	866e                	mv	a2,s11
ffffffffc0204a4a:	85d6                	mv	a1,s5
ffffffffc0204a4c:	aa7fe0ef          	jal	ra,ffffffffc02034f2 <pgdir_alloc_page>
ffffffffc0204a50:	842a                	mv	s0,a0
ffffffffc0204a52:	f545                	bnez	a0,ffffffffc02049fa <do_execve+0x2ee>
        ret = -E_NO_MEM;
ffffffffc0204a54:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204a56:	8526                	mv	a0,s1
ffffffffc0204a58:	e5dfe0ef          	jal	ra,ffffffffc02038b4 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204a5c:	8526                	mv	a0,s1
ffffffffc0204a5e:	b34ff0ef          	jal	ra,ffffffffc0203d92 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204a62:	8526                	mv	a0,s1
ffffffffc0204a64:	cb5fe0ef          	jal	ra,ffffffffc0203718 <mm_destroy>
    return ret;
ffffffffc0204a68:	b705                	j	ffffffffc0204988 <do_execve+0x27c>
            exit_mmap(mm);
ffffffffc0204a6a:	854e                	mv	a0,s3
ffffffffc0204a6c:	e49fe0ef          	jal	ra,ffffffffc02038b4 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204a70:	854e                	mv	a0,s3
ffffffffc0204a72:	b20ff0ef          	jal	ra,ffffffffc0203d92 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204a76:	854e                	mv	a0,s3
ffffffffc0204a78:	ca1fe0ef          	jal	ra,ffffffffc0203718 <mm_destroy>
ffffffffc0204a7c:	b30d                	j	ffffffffc020479e <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204a7e:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a82:	fb95                	bnez	a5,ffffffffc02049b6 <do_execve+0x2aa>
            perm |= (PTE_W | PTE_R);
ffffffffc0204a84:	4ddd                	li	s11,23
ffffffffc0204a86:	bf35                	j	ffffffffc02049c2 <do_execve+0x2b6>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204a88:	0109b683          	ld	a3,16(s3)
ffffffffc0204a8c:	0289b903          	ld	s2,40(s3)
ffffffffc0204a90:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204a92:	075bfd63          	bgeu	s7,s5,ffffffffc0204b0c <do_execve+0x400>
            if (start == end)
ffffffffc0204a96:	db790be3          	beq	s2,s7,ffffffffc020484c <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204a9a:	6785                	lui	a5,0x1
ffffffffc0204a9c:	00fb8533          	add	a0,s7,a5
ffffffffc0204aa0:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204aa4:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204aa8:	0b597d63          	bgeu	s2,s5,ffffffffc0204b62 <do_execve+0x456>
    return page - pages + nbase;
ffffffffc0204aac:	000d3683          	ld	a3,0(s10)
ffffffffc0204ab0:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204ab2:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204ab6:	40d406b3          	sub	a3,s0,a3
ffffffffc0204aba:	8699                	srai	a3,a3,0x6
ffffffffc0204abc:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204abe:	67e2                	ld	a5,24(sp)
ffffffffc0204ac0:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ac4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ac6:	0ac5f963          	bgeu	a1,a2,ffffffffc0204b78 <do_execve+0x46c>
ffffffffc0204aca:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ace:	8652                	mv	a2,s4
ffffffffc0204ad0:	4581                	li	a1,0
ffffffffc0204ad2:	96c2                	add	a3,a3,a6
ffffffffc0204ad4:	9536                	add	a0,a0,a3
ffffffffc0204ad6:	57b000ef          	jal	ra,ffffffffc0205850 <memset>
            start += size;
ffffffffc0204ada:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204ade:	03597463          	bgeu	s2,s5,ffffffffc0204b06 <do_execve+0x3fa>
ffffffffc0204ae2:	d6e905e3          	beq	s2,a4,ffffffffc020484c <do_execve+0x140>
ffffffffc0204ae6:	00002697          	auipc	a3,0x2
ffffffffc0204aea:	7e268693          	addi	a3,a3,2018 # ffffffffc02072c8 <default_pmm_manager+0xc08>
ffffffffc0204aee:	00002617          	auipc	a2,0x2
ffffffffc0204af2:	82260613          	addi	a2,a2,-2014 # ffffffffc0206310 <commands+0x828>
ffffffffc0204af6:	2d600593          	li	a1,726
ffffffffc0204afa:	00002517          	auipc	a0,0x2
ffffffffc0204afe:	5de50513          	addi	a0,a0,1502 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204b02:	991fb0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0204b06:	ff5710e3          	bne	a4,s5,ffffffffc0204ae6 <do_execve+0x3da>
ffffffffc0204b0a:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204b0c:	d52bf0e3          	bgeu	s7,s2,ffffffffc020484c <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b10:	6c88                	ld	a0,24(s1)
ffffffffc0204b12:	866e                	mv	a2,s11
ffffffffc0204b14:	85d6                	mv	a1,s5
ffffffffc0204b16:	9ddfe0ef          	jal	ra,ffffffffc02034f2 <pgdir_alloc_page>
ffffffffc0204b1a:	842a                	mv	s0,a0
ffffffffc0204b1c:	dd05                	beqz	a0,ffffffffc0204a54 <do_execve+0x348>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b1e:	6785                	lui	a5,0x1
ffffffffc0204b20:	415b8533          	sub	a0,s7,s5
ffffffffc0204b24:	9abe                	add	s5,s5,a5
ffffffffc0204b26:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204b2a:	01597463          	bgeu	s2,s5,ffffffffc0204b32 <do_execve+0x426>
                size -= la - end;
ffffffffc0204b2e:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204b32:	000d3683          	ld	a3,0(s10)
ffffffffc0204b36:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b38:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204b3c:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b40:	8699                	srai	a3,a3,0x6
ffffffffc0204b42:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b44:	67e2                	ld	a5,24(sp)
ffffffffc0204b46:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b4a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b4c:	02b87663          	bgeu	a6,a1,ffffffffc0204b78 <do_execve+0x46c>
ffffffffc0204b50:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b54:	4581                	li	a1,0
            start += size;
ffffffffc0204b56:	9bb2                	add	s7,s7,a2
ffffffffc0204b58:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b5a:	9536                	add	a0,a0,a3
ffffffffc0204b5c:	4f5000ef          	jal	ra,ffffffffc0205850 <memset>
ffffffffc0204b60:	b775                	j	ffffffffc0204b0c <do_execve+0x400>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204b62:	417a8a33          	sub	s4,s5,s7
ffffffffc0204b66:	b799                	j	ffffffffc0204aac <do_execve+0x3a0>
        return -E_INVAL;
ffffffffc0204b68:	5a75                	li	s4,-3
ffffffffc0204b6a:	b3c1                	j	ffffffffc020492a <do_execve+0x21e>
        while (start < end)
ffffffffc0204b6c:	86de                	mv	a3,s7
ffffffffc0204b6e:	bf39                	j	ffffffffc0204a8c <do_execve+0x380>
    int ret = -E_NO_MEM;
ffffffffc0204b70:	5a71                	li	s4,-4
ffffffffc0204b72:	bdc5                	j	ffffffffc0204a62 <do_execve+0x356>
            ret = -E_INVAL_ELF;
ffffffffc0204b74:	5a61                	li	s4,-8
ffffffffc0204b76:	b5c5                	j	ffffffffc0204a56 <do_execve+0x34a>
ffffffffc0204b78:	00002617          	auipc	a2,0x2
ffffffffc0204b7c:	b8060613          	addi	a2,a2,-1152 # ffffffffc02066f8 <default_pmm_manager+0x38>
ffffffffc0204b80:	07100593          	li	a1,113
ffffffffc0204b84:	00002517          	auipc	a0,0x2
ffffffffc0204b88:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0206720 <default_pmm_manager+0x60>
ffffffffc0204b8c:	907fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b90:	00002617          	auipc	a2,0x2
ffffffffc0204b94:	c1060613          	addi	a2,a2,-1008 # ffffffffc02067a0 <default_pmm_manager+0xe0>
ffffffffc0204b98:	2f500593          	li	a1,757
ffffffffc0204b9c:	00002517          	auipc	a0,0x2
ffffffffc0204ba0:	53c50513          	addi	a0,a0,1340 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204ba4:	8effb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ba8:	00003697          	auipc	a3,0x3
ffffffffc0204bac:	83868693          	addi	a3,a3,-1992 # ffffffffc02073e0 <default_pmm_manager+0xd20>
ffffffffc0204bb0:	00001617          	auipc	a2,0x1
ffffffffc0204bb4:	76060613          	addi	a2,a2,1888 # ffffffffc0206310 <commands+0x828>
ffffffffc0204bb8:	2f000593          	li	a1,752
ffffffffc0204bbc:	00002517          	auipc	a0,0x2
ffffffffc0204bc0:	51c50513          	addi	a0,a0,1308 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204bc4:	8cffb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204bc8:	00002697          	auipc	a3,0x2
ffffffffc0204bcc:	7d068693          	addi	a3,a3,2000 # ffffffffc0207398 <default_pmm_manager+0xcd8>
ffffffffc0204bd0:	00001617          	auipc	a2,0x1
ffffffffc0204bd4:	74060613          	addi	a2,a2,1856 # ffffffffc0206310 <commands+0x828>
ffffffffc0204bd8:	2ef00593          	li	a1,751
ffffffffc0204bdc:	00002517          	auipc	a0,0x2
ffffffffc0204be0:	4fc50513          	addi	a0,a0,1276 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204be4:	8affb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204be8:	00002697          	auipc	a3,0x2
ffffffffc0204bec:	76868693          	addi	a3,a3,1896 # ffffffffc0207350 <default_pmm_manager+0xc90>
ffffffffc0204bf0:	00001617          	auipc	a2,0x1
ffffffffc0204bf4:	72060613          	addi	a2,a2,1824 # ffffffffc0206310 <commands+0x828>
ffffffffc0204bf8:	2ee00593          	li	a1,750
ffffffffc0204bfc:	00002517          	auipc	a0,0x2
ffffffffc0204c00:	4dc50513          	addi	a0,a0,1244 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204c04:	88ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204c08:	00002697          	auipc	a3,0x2
ffffffffc0204c0c:	70068693          	addi	a3,a3,1792 # ffffffffc0207308 <default_pmm_manager+0xc48>
ffffffffc0204c10:	00001617          	auipc	a2,0x1
ffffffffc0204c14:	70060613          	addi	a2,a2,1792 # ffffffffc0206310 <commands+0x828>
ffffffffc0204c18:	2ed00593          	li	a1,749
ffffffffc0204c1c:	00002517          	auipc	a0,0x2
ffffffffc0204c20:	4bc50513          	addi	a0,a0,1212 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204c24:	86ffb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204c28 <user_main>:
{
ffffffffc0204c28:	1101                	addi	sp,sp,-32
ffffffffc0204c2a:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE(priority);
ffffffffc0204c2c:	000cd917          	auipc	s2,0xcd
ffffffffc0204c30:	3fc90913          	addi	s2,s2,1020 # ffffffffc02d2028 <current>
ffffffffc0204c34:	00093783          	ld	a5,0(s2)
ffffffffc0204c38:	00002617          	auipc	a2,0x2
ffffffffc0204c3c:	7f060613          	addi	a2,a2,2032 # ffffffffc0207428 <default_pmm_manager+0xd68>
ffffffffc0204c40:	00002517          	auipc	a0,0x2
ffffffffc0204c44:	7f850513          	addi	a0,a0,2040 # ffffffffc0207438 <default_pmm_manager+0xd78>
ffffffffc0204c48:	43cc                	lw	a1,4(a5)
{
ffffffffc0204c4a:	ec06                	sd	ra,24(sp)
ffffffffc0204c4c:	e822                	sd	s0,16(sp)
ffffffffc0204c4e:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE(priority);
ffffffffc0204c50:	d48fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204c54:	00002517          	auipc	a0,0x2
ffffffffc0204c58:	7d450513          	addi	a0,a0,2004 # ffffffffc0207428 <default_pmm_manager+0xd68>
ffffffffc0204c5c:	353000ef          	jal	ra,ffffffffc02057ae <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204c60:	00093783          	ld	a5,0(s2)
    size_t len = strlen(name);
ffffffffc0204c64:	84aa                	mv	s1,a0
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c66:	12000613          	li	a2,288
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204c6a:	6b80                	ld	s0,16(a5)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c6c:	73cc                	ld	a1,160(a5)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204c6e:	6789                	lui	a5,0x2
ffffffffc0204c70:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8050>
ffffffffc0204c74:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c76:	8522                	mv	a0,s0
ffffffffc0204c78:	3eb000ef          	jal	ra,ffffffffc0205862 <memcpy>
    current->tf = new_tf;
ffffffffc0204c7c:	00093783          	ld	a5,0(s2)
    ret = do_execve(name, len, binary, size);
ffffffffc0204c80:	3fe07697          	auipc	a3,0x3fe07
ffffffffc0204c84:	ab868693          	addi	a3,a3,-1352 # b738 <_binary_obj___user_priority_out_size>
ffffffffc0204c88:	0007d617          	auipc	a2,0x7d
ffffffffc0204c8c:	02860613          	addi	a2,a2,40 # ffffffffc0281cb0 <_binary_obj___user_priority_out_start>
    current->tf = new_tf;
ffffffffc0204c90:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204c92:	85a6                	mv	a1,s1
ffffffffc0204c94:	00002517          	auipc	a0,0x2
ffffffffc0204c98:	79450513          	addi	a0,a0,1940 # ffffffffc0207428 <default_pmm_manager+0xd68>
ffffffffc0204c9c:	a71ff0ef          	jal	ra,ffffffffc020470c <do_execve>
    asm volatile(
ffffffffc0204ca0:	8122                	mv	sp,s0
ffffffffc0204ca2:	9eafc06f          	j	ffffffffc0200e8c <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204ca6:	00002617          	auipc	a2,0x2
ffffffffc0204caa:	7ba60613          	addi	a2,a2,1978 # ffffffffc0207460 <default_pmm_manager+0xda0>
ffffffffc0204cae:	3de00593          	li	a1,990
ffffffffc0204cb2:	00002517          	auipc	a0,0x2
ffffffffc0204cb6:	42650513          	addi	a0,a0,1062 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204cba:	fd8fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204cbe <do_yield>:
    current->need_resched = 1;
ffffffffc0204cbe:	000cd797          	auipc	a5,0xcd
ffffffffc0204cc2:	36a7b783          	ld	a5,874(a5) # ffffffffc02d2028 <current>
ffffffffc0204cc6:	4705                	li	a4,1
ffffffffc0204cc8:	ef98                	sd	a4,24(a5)
}
ffffffffc0204cca:	4501                	li	a0,0
ffffffffc0204ccc:	8082                	ret

ffffffffc0204cce <do_wait>:
{
ffffffffc0204cce:	1101                	addi	sp,sp,-32
ffffffffc0204cd0:	e822                	sd	s0,16(sp)
ffffffffc0204cd2:	e426                	sd	s1,8(sp)
ffffffffc0204cd4:	ec06                	sd	ra,24(sp)
ffffffffc0204cd6:	842e                	mv	s0,a1
ffffffffc0204cd8:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204cda:	c999                	beqz	a1,ffffffffc0204cf0 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204cdc:	000cd797          	auipc	a5,0xcd
ffffffffc0204ce0:	34c7b783          	ld	a5,844(a5) # ffffffffc02d2028 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204ce4:	7788                	ld	a0,40(a5)
ffffffffc0204ce6:	4685                	li	a3,1
ffffffffc0204ce8:	4611                	li	a2,4
ffffffffc0204cea:	f65fe0ef          	jal	ra,ffffffffc0203c4e <user_mem_check>
ffffffffc0204cee:	c909                	beqz	a0,ffffffffc0204d00 <do_wait+0x32>
ffffffffc0204cf0:	85a2                	mv	a1,s0
}
ffffffffc0204cf2:	6442                	ld	s0,16(sp)
ffffffffc0204cf4:	60e2                	ld	ra,24(sp)
ffffffffc0204cf6:	8526                	mv	a0,s1
ffffffffc0204cf8:	64a2                	ld	s1,8(sp)
ffffffffc0204cfa:	6105                	addi	sp,sp,32
ffffffffc0204cfc:	f1aff06f          	j	ffffffffc0204416 <do_wait.part.0>
ffffffffc0204d00:	60e2                	ld	ra,24(sp)
ffffffffc0204d02:	6442                	ld	s0,16(sp)
ffffffffc0204d04:	64a2                	ld	s1,8(sp)
ffffffffc0204d06:	5575                	li	a0,-3
ffffffffc0204d08:	6105                	addi	sp,sp,32
ffffffffc0204d0a:	8082                	ret

ffffffffc0204d0c <do_kill>:
{
ffffffffc0204d0c:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d0e:	6789                	lui	a5,0x2
{
ffffffffc0204d10:	e406                	sd	ra,8(sp)
ffffffffc0204d12:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d14:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204d18:	17f9                	addi	a5,a5,-2
ffffffffc0204d1a:	02e7e963          	bltu	a5,a4,ffffffffc0204d4c <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d1e:	842a                	mv	s0,a0
ffffffffc0204d20:	45a9                	li	a1,10
ffffffffc0204d22:	2501                	sext.w	a0,a0
ffffffffc0204d24:	686000ef          	jal	ra,ffffffffc02053aa <hash32>
ffffffffc0204d28:	02051793          	slli	a5,a0,0x20
ffffffffc0204d2c:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204d30:	000c9797          	auipc	a5,0xc9
ffffffffc0204d34:	26078793          	addi	a5,a5,608 # ffffffffc02cdf90 <hash_list>
ffffffffc0204d38:	953e                	add	a0,a0,a5
ffffffffc0204d3a:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204d3c:	a029                	j	ffffffffc0204d46 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204d3e:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204d42:	00870b63          	beq	a4,s0,ffffffffc0204d58 <do_kill+0x4c>
ffffffffc0204d46:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204d48:	fef51be3          	bne	a0,a5,ffffffffc0204d3e <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204d4c:	5475                	li	s0,-3
}
ffffffffc0204d4e:	60a2                	ld	ra,8(sp)
ffffffffc0204d50:	8522                	mv	a0,s0
ffffffffc0204d52:	6402                	ld	s0,0(sp)
ffffffffc0204d54:	0141                	addi	sp,sp,16
ffffffffc0204d56:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204d58:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204d5c:	00177693          	andi	a3,a4,1
ffffffffc0204d60:	e295                	bnez	a3,ffffffffc0204d84 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204d62:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204d64:	00176713          	ori	a4,a4,1
ffffffffc0204d68:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204d6c:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204d6e:	fe06d0e3          	bgez	a3,ffffffffc0204d4e <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204d72:	f2878513          	addi	a0,a5,-216
ffffffffc0204d76:	3c2000ef          	jal	ra,ffffffffc0205138 <wakeup_proc>
}
ffffffffc0204d7a:	60a2                	ld	ra,8(sp)
ffffffffc0204d7c:	8522                	mv	a0,s0
ffffffffc0204d7e:	6402                	ld	s0,0(sp)
ffffffffc0204d80:	0141                	addi	sp,sp,16
ffffffffc0204d82:	8082                	ret
        return -E_KILLED;
ffffffffc0204d84:	545d                	li	s0,-9
ffffffffc0204d86:	b7e1                	j	ffffffffc0204d4e <do_kill+0x42>

ffffffffc0204d88 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204d88:	1101                	addi	sp,sp,-32
ffffffffc0204d8a:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204d8c:	000cd797          	auipc	a5,0xcd
ffffffffc0204d90:	20478793          	addi	a5,a5,516 # ffffffffc02d1f90 <proc_list>
ffffffffc0204d94:	ec06                	sd	ra,24(sp)
ffffffffc0204d96:	e822                	sd	s0,16(sp)
ffffffffc0204d98:	e04a                	sd	s2,0(sp)
ffffffffc0204d9a:	000c9497          	auipc	s1,0xc9
ffffffffc0204d9e:	1f648493          	addi	s1,s1,502 # ffffffffc02cdf90 <hash_list>
ffffffffc0204da2:	e79c                	sd	a5,8(a5)
ffffffffc0204da4:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204da6:	000cd717          	auipc	a4,0xcd
ffffffffc0204daa:	1ea70713          	addi	a4,a4,490 # ffffffffc02d1f90 <proc_list>
ffffffffc0204dae:	87a6                	mv	a5,s1
ffffffffc0204db0:	e79c                	sd	a5,8(a5)
ffffffffc0204db2:	e39c                	sd	a5,0(a5)
ffffffffc0204db4:	07c1                	addi	a5,a5,16
ffffffffc0204db6:	fef71de3          	bne	a4,a5,ffffffffc0204db0 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204dba:	f31fe0ef          	jal	ra,ffffffffc0203cea <alloc_proc>
ffffffffc0204dbe:	000cd917          	auipc	s2,0xcd
ffffffffc0204dc2:	27290913          	addi	s2,s2,626 # ffffffffc02d2030 <idleproc>
ffffffffc0204dc6:	00a93023          	sd	a0,0(s2)
ffffffffc0204dca:	0e050f63          	beqz	a0,ffffffffc0204ec8 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204dce:	4789                	li	a5,2
ffffffffc0204dd0:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204dd2:	00004797          	auipc	a5,0x4
ffffffffc0204dd6:	22e78793          	addi	a5,a5,558 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204dda:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204dde:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204de0:	4785                	li	a5,1
ffffffffc0204de2:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204de4:	4641                	li	a2,16
ffffffffc0204de6:	4581                	li	a1,0
ffffffffc0204de8:	8522                	mv	a0,s0
ffffffffc0204dea:	267000ef          	jal	ra,ffffffffc0205850 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204dee:	463d                	li	a2,15
ffffffffc0204df0:	00002597          	auipc	a1,0x2
ffffffffc0204df4:	6a858593          	addi	a1,a1,1704 # ffffffffc0207498 <default_pmm_manager+0xdd8>
ffffffffc0204df8:	8522                	mv	a0,s0
ffffffffc0204dfa:	269000ef          	jal	ra,ffffffffc0205862 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204dfe:	000cd717          	auipc	a4,0xcd
ffffffffc0204e02:	24270713          	addi	a4,a4,578 # ffffffffc02d2040 <nr_process>
ffffffffc0204e06:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204e08:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e0c:	4601                	li	a2,0
    nr_process++;
ffffffffc0204e0e:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e10:	4581                	li	a1,0
ffffffffc0204e12:	fffff517          	auipc	a0,0xfffff
ffffffffc0204e16:	7d650513          	addi	a0,a0,2006 # ffffffffc02045e8 <init_main>
    nr_process++;
ffffffffc0204e1a:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204e1c:	000cd797          	auipc	a5,0xcd
ffffffffc0204e20:	20d7b623          	sd	a3,524(a5) # ffffffffc02d2028 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e24:	c58ff0ef          	jal	ra,ffffffffc020427c <kernel_thread>
ffffffffc0204e28:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204e2a:	08a05363          	blez	a0,ffffffffc0204eb0 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e2e:	6789                	lui	a5,0x2
ffffffffc0204e30:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e34:	17f9                	addi	a5,a5,-2
ffffffffc0204e36:	2501                	sext.w	a0,a0
ffffffffc0204e38:	02e7e363          	bltu	a5,a4,ffffffffc0204e5e <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e3c:	45a9                	li	a1,10
ffffffffc0204e3e:	56c000ef          	jal	ra,ffffffffc02053aa <hash32>
ffffffffc0204e42:	02051793          	slli	a5,a0,0x20
ffffffffc0204e46:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204e4a:	96a6                	add	a3,a3,s1
ffffffffc0204e4c:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204e4e:	a029                	j	ffffffffc0204e58 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204e50:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x8004>
ffffffffc0204e54:	04870b63          	beq	a4,s0,ffffffffc0204eaa <proc_init+0x122>
    return listelm->next;
ffffffffc0204e58:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204e5a:	fef69be3          	bne	a3,a5,ffffffffc0204e50 <proc_init+0xc8>
    return NULL;
ffffffffc0204e5e:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e60:	0b478493          	addi	s1,a5,180
ffffffffc0204e64:	4641                	li	a2,16
ffffffffc0204e66:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204e68:	000cd417          	auipc	s0,0xcd
ffffffffc0204e6c:	1d040413          	addi	s0,s0,464 # ffffffffc02d2038 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e70:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204e72:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e74:	1dd000ef          	jal	ra,ffffffffc0205850 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e78:	463d                	li	a2,15
ffffffffc0204e7a:	00002597          	auipc	a1,0x2
ffffffffc0204e7e:	64658593          	addi	a1,a1,1606 # ffffffffc02074c0 <default_pmm_manager+0xe00>
ffffffffc0204e82:	8526                	mv	a0,s1
ffffffffc0204e84:	1df000ef          	jal	ra,ffffffffc0205862 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204e88:	00093783          	ld	a5,0(s2)
ffffffffc0204e8c:	cbb5                	beqz	a5,ffffffffc0204f00 <proc_init+0x178>
ffffffffc0204e8e:	43dc                	lw	a5,4(a5)
ffffffffc0204e90:	eba5                	bnez	a5,ffffffffc0204f00 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204e92:	601c                	ld	a5,0(s0)
ffffffffc0204e94:	c7b1                	beqz	a5,ffffffffc0204ee0 <proc_init+0x158>
ffffffffc0204e96:	43d8                	lw	a4,4(a5)
ffffffffc0204e98:	4785                	li	a5,1
ffffffffc0204e9a:	04f71363          	bne	a4,a5,ffffffffc0204ee0 <proc_init+0x158>
}
ffffffffc0204e9e:	60e2                	ld	ra,24(sp)
ffffffffc0204ea0:	6442                	ld	s0,16(sp)
ffffffffc0204ea2:	64a2                	ld	s1,8(sp)
ffffffffc0204ea4:	6902                	ld	s2,0(sp)
ffffffffc0204ea6:	6105                	addi	sp,sp,32
ffffffffc0204ea8:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204eaa:	f2878793          	addi	a5,a5,-216
ffffffffc0204eae:	bf4d                	j	ffffffffc0204e60 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204eb0:	00002617          	auipc	a2,0x2
ffffffffc0204eb4:	5f060613          	addi	a2,a2,1520 # ffffffffc02074a0 <default_pmm_manager+0xde0>
ffffffffc0204eb8:	41a00593          	li	a1,1050
ffffffffc0204ebc:	00002517          	auipc	a0,0x2
ffffffffc0204ec0:	21c50513          	addi	a0,a0,540 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204ec4:	dcefb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204ec8:	00002617          	auipc	a2,0x2
ffffffffc0204ecc:	5b860613          	addi	a2,a2,1464 # ffffffffc0207480 <default_pmm_manager+0xdc0>
ffffffffc0204ed0:	40b00593          	li	a1,1035
ffffffffc0204ed4:	00002517          	auipc	a0,0x2
ffffffffc0204ed8:	20450513          	addi	a0,a0,516 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204edc:	db6fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204ee0:	00002697          	auipc	a3,0x2
ffffffffc0204ee4:	61068693          	addi	a3,a3,1552 # ffffffffc02074f0 <default_pmm_manager+0xe30>
ffffffffc0204ee8:	00001617          	auipc	a2,0x1
ffffffffc0204eec:	42860613          	addi	a2,a2,1064 # ffffffffc0206310 <commands+0x828>
ffffffffc0204ef0:	42100593          	li	a1,1057
ffffffffc0204ef4:	00002517          	auipc	a0,0x2
ffffffffc0204ef8:	1e450513          	addi	a0,a0,484 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204efc:	d96fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f00:	00002697          	auipc	a3,0x2
ffffffffc0204f04:	5c868693          	addi	a3,a3,1480 # ffffffffc02074c8 <default_pmm_manager+0xe08>
ffffffffc0204f08:	00001617          	auipc	a2,0x1
ffffffffc0204f0c:	40860613          	addi	a2,a2,1032 # ffffffffc0206310 <commands+0x828>
ffffffffc0204f10:	42000593          	li	a1,1056
ffffffffc0204f14:	00002517          	auipc	a0,0x2
ffffffffc0204f18:	1c450513          	addi	a0,a0,452 # ffffffffc02070d8 <default_pmm_manager+0xa18>
ffffffffc0204f1c:	d76fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204f20 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204f20:	1141                	addi	sp,sp,-16
ffffffffc0204f22:	e022                	sd	s0,0(sp)
ffffffffc0204f24:	e406                	sd	ra,8(sp)
ffffffffc0204f26:	000cd417          	auipc	s0,0xcd
ffffffffc0204f2a:	10240413          	addi	s0,s0,258 # ffffffffc02d2028 <current>
    // idle 线程：系统没有可运行进程时占用 CPU；当 need_resched 被置位时进入 schedule()
    while (1)
    {
        if (current->need_resched)
ffffffffc0204f2e:	6018                	ld	a4,0(s0)
ffffffffc0204f30:	6f1c                	ld	a5,24(a4)
ffffffffc0204f32:	dffd                	beqz	a5,ffffffffc0204f30 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204f34:	2b6000ef          	jal	ra,ffffffffc02051ea <schedule>
ffffffffc0204f38:	bfdd                	j	ffffffffc0204f2e <cpu_idle+0xe>

ffffffffc0204f3a <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc0204f3a:	1141                	addi	sp,sp,-16
ffffffffc0204f3c:	e022                	sd	s0,0(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204f3e:	85aa                	mv	a1,a0
{
ffffffffc0204f40:	842a                	mv	s0,a0
    cprintf("set priority to %d\n", priority);
ffffffffc0204f42:	00002517          	auipc	a0,0x2
ffffffffc0204f46:	5d650513          	addi	a0,a0,1494 # ffffffffc0207518 <default_pmm_manager+0xe58>
{
ffffffffc0204f4a:	e406                	sd	ra,8(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204f4c:	a4cfb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    // priority 由用户态 priority.c 通过系统调用设置，用于 Stride 调度的权重；
    // 在 RR 调度下该值不会影响调度结果（RR 只保证时间片轮转的公平性）。
    if (priority == 0)
        current->lab6_priority = 1;
ffffffffc0204f50:	000cd797          	auipc	a5,0xcd
ffffffffc0204f54:	0d87b783          	ld	a5,216(a5) # ffffffffc02d2028 <current>
    if (priority == 0)
ffffffffc0204f58:	e801                	bnez	s0,ffffffffc0204f68 <lab6_set_priority+0x2e>
    else
        current->lab6_priority = priority;
}
ffffffffc0204f5a:	60a2                	ld	ra,8(sp)
ffffffffc0204f5c:	6402                	ld	s0,0(sp)
        current->lab6_priority = 1;
ffffffffc0204f5e:	4705                	li	a4,1
ffffffffc0204f60:	14e7a223          	sw	a4,324(a5)
}
ffffffffc0204f64:	0141                	addi	sp,sp,16
ffffffffc0204f66:	8082                	ret
ffffffffc0204f68:	60a2                	ld	ra,8(sp)
        current->lab6_priority = priority;
ffffffffc0204f6a:	1487a223          	sw	s0,324(a5)
}
ffffffffc0204f6e:	6402                	ld	s0,0(sp)
ffffffffc0204f70:	0141                	addi	sp,sp,16
ffffffffc0204f72:	8082                	ret

ffffffffc0204f74 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204f74:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204f78:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204f7c:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204f7e:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204f80:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204f84:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204f88:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204f8c:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204f90:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204f94:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204f98:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204f9c:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204fa0:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204fa4:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204fa8:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204fac:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204fb0:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204fb2:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204fb4:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204fb8:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204fbc:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204fc0:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204fc4:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204fc8:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204fcc:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204fd0:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204fd4:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204fd8:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204fdc:	8082                	ret

ffffffffc0204fde <FIFO_init>:
    elm->prev = elm->next = elm;
ffffffffc0204fde:	e508                	sd	a0,8(a0)
ffffffffc0204fe0:	e108                	sd	a0,0(a0)
 */

static void
FIFO_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->lab6_run_pool = NULL;
ffffffffc0204fe2:	00053c23          	sd	zero,24(a0)
    rq->proc_num = 0;
ffffffffc0204fe6:	00052823          	sw	zero,16(a0)
}
ffffffffc0204fea:	8082                	ret

ffffffffc0204fec <FIFO_pick_next>:
    return listelm->next;
ffffffffc0204fec:	651c                	ld	a5,8(a0)
}

static struct proc_struct *
FIFO_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
ffffffffc0204fee:	00f50563          	beq	a0,a5,ffffffffc0204ff8 <FIFO_pick_next+0xc>
        return le2proc(le, run_link);
ffffffffc0204ff2:	ef078513          	addi	a0,a5,-272
ffffffffc0204ff6:	8082                	ret
    }
    return NULL;
ffffffffc0204ff8:	4501                	li	a0,0
}
ffffffffc0204ffa:	8082                	ret

ffffffffc0204ffc <FIFO_proc_tick>:
static void
FIFO_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    // 非抢占 FIFO：tick 不触发调度
    (void)rq;
    (void)proc;
}
ffffffffc0204ffc:	8082                	ret

ffffffffc0204ffe <FIFO_dequeue>:
    assert(proc->rq == rq && rq->proc_num > 0);
ffffffffc0204ffe:	1085b703          	ld	a4,264(a1)
FIFO_dequeue(struct run_queue *rq, struct proc_struct *proc) {
ffffffffc0205002:	1141                	addi	sp,sp,-16
ffffffffc0205004:	e406                	sd	ra,8(sp)
    assert(proc->rq == rq && rq->proc_num > 0);
ffffffffc0205006:	02a71763          	bne	a4,a0,ffffffffc0205034 <FIFO_dequeue+0x36>
ffffffffc020500a:	4b1c                	lw	a5,16(a4)
ffffffffc020500c:	c785                	beqz	a5,ffffffffc0205034 <FIFO_dequeue+0x36>
    return list->next == list;
ffffffffc020500e:	1185b603          	ld	a2,280(a1)
    assert(!list_empty(&(proc->run_link)));
ffffffffc0205012:	11058693          	addi	a3,a1,272
ffffffffc0205016:	02c68f63          	beq	a3,a2,ffffffffc0205054 <FIFO_dequeue+0x56>
    __list_del(listelm->prev, listelm->next);
ffffffffc020501a:	1105b503          	ld	a0,272(a1)
}
ffffffffc020501e:	60a2                	ld	ra,8(sp)
    rq->proc_num--;
ffffffffc0205020:	37fd                	addiw	a5,a5,-1
    prev->next = next;
ffffffffc0205022:	e510                	sd	a2,8(a0)
    next->prev = prev;
ffffffffc0205024:	e208                	sd	a0,0(a2)
    elm->prev = elm->next = elm;
ffffffffc0205026:	10d5bc23          	sd	a3,280(a1)
ffffffffc020502a:	10d5b823          	sd	a3,272(a1)
ffffffffc020502e:	cb1c                	sw	a5,16(a4)
}
ffffffffc0205030:	0141                	addi	sp,sp,16
ffffffffc0205032:	8082                	ret
    assert(proc->rq == rq && rq->proc_num > 0);
ffffffffc0205034:	00002697          	auipc	a3,0x2
ffffffffc0205038:	4fc68693          	addi	a3,a3,1276 # ffffffffc0207530 <default_pmm_manager+0xe70>
ffffffffc020503c:	00001617          	auipc	a2,0x1
ffffffffc0205040:	2d460613          	addi	a2,a2,724 # ffffffffc0206310 <commands+0x828>
ffffffffc0205044:	02500593          	li	a1,37
ffffffffc0205048:	00002517          	auipc	a0,0x2
ffffffffc020504c:	51050513          	addi	a0,a0,1296 # ffffffffc0207558 <default_pmm_manager+0xe98>
ffffffffc0205050:	c42fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!list_empty(&(proc->run_link)));
ffffffffc0205054:	00002697          	auipc	a3,0x2
ffffffffc0205058:	52c68693          	addi	a3,a3,1324 # ffffffffc0207580 <default_pmm_manager+0xec0>
ffffffffc020505c:	00001617          	auipc	a2,0x1
ffffffffc0205060:	2b460613          	addi	a2,a2,692 # ffffffffc0206310 <commands+0x828>
ffffffffc0205064:	02600593          	li	a1,38
ffffffffc0205068:	00002517          	auipc	a0,0x2
ffffffffc020506c:	4f050513          	addi	a0,a0,1264 # ffffffffc0207558 <default_pmm_manager+0xe98>
ffffffffc0205070:	c22fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205074 <FIFO_enqueue>:
    assert(list_empty(&(proc->run_link)));
ffffffffc0205074:	1185b703          	ld	a4,280(a1)
ffffffffc0205078:	11058793          	addi	a5,a1,272
ffffffffc020507c:	02e79063          	bne	a5,a4,ffffffffc020509c <FIFO_enqueue+0x28>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0205080:	6114                	ld	a3,0(a0)
    rq->proc_num++;
ffffffffc0205082:	4918                	lw	a4,16(a0)
    prev->next = next->prev = elm;
ffffffffc0205084:	e11c                	sd	a5,0(a0)
ffffffffc0205086:	e69c                	sd	a5,8(a3)
    elm->next = next;
ffffffffc0205088:	10a5bc23          	sd	a0,280(a1)
    elm->prev = prev;
ffffffffc020508c:	10d5b823          	sd	a3,272(a1)
    proc->rq = rq;
ffffffffc0205090:	10a5b423          	sd	a0,264(a1)
    rq->proc_num++;
ffffffffc0205094:	0017079b          	addiw	a5,a4,1
ffffffffc0205098:	c91c                	sw	a5,16(a0)
ffffffffc020509a:	8082                	ret
FIFO_enqueue(struct run_queue *rq, struct proc_struct *proc) {
ffffffffc020509c:	1141                	addi	sp,sp,-16
    assert(list_empty(&(proc->run_link)));
ffffffffc020509e:	00002697          	auipc	a3,0x2
ffffffffc02050a2:	50268693          	addi	a3,a3,1282 # ffffffffc02075a0 <default_pmm_manager+0xee0>
ffffffffc02050a6:	00001617          	auipc	a2,0x1
ffffffffc02050aa:	26a60613          	addi	a2,a2,618 # ffffffffc0206310 <commands+0x828>
ffffffffc02050ae:	45f5                	li	a1,29
ffffffffc02050b0:	00002517          	auipc	a0,0x2
ffffffffc02050b4:	4a850513          	addi	a0,a0,1192 # ffffffffc0207558 <default_pmm_manager+0xe98>
FIFO_enqueue(struct run_queue *rq, struct proc_struct *proc) {
ffffffffc02050b8:	e406                	sd	ra,8(sp)
    assert(list_empty(&(proc->run_link)));
ffffffffc02050ba:	bd8fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02050be <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc02050be:	000cd797          	auipc	a5,0xcd
ffffffffc02050c2:	f727b783          	ld	a5,-142(a5) # ffffffffc02d2030 <idleproc>
{
ffffffffc02050c6:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc02050c8:	00a78c63          	beq	a5,a0,ffffffffc02050e0 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc02050cc:	000cd797          	auipc	a5,0xcd
ffffffffc02050d0:	f847b783          	ld	a5,-124(a5) # ffffffffc02d2050 <sched_class>
ffffffffc02050d4:	779c                	ld	a5,40(a5)
ffffffffc02050d6:	000cd517          	auipc	a0,0xcd
ffffffffc02050da:	f7253503          	ld	a0,-142(a0) # ffffffffc02d2048 <rq>
ffffffffc02050de:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc02050e0:	4705                	li	a4,1
ffffffffc02050e2:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc02050e4:	8082                	ret

ffffffffc02050e6 <sched_init>:

static struct run_queue __rq;

void sched_init(void)
{
ffffffffc02050e6:	1141                	addi	sp,sp,-16
    // - make grade（DEBUG_GRADE）保持 RR，满足评分脚本输出
    // - make qemu 默认切换为 FIFO，便于观察 FCFS 的行为
#ifdef DEBUG_GRADE
    sched_class = &default_sched_class;
#else
    sched_class = &fifo_sched_class;
ffffffffc02050e8:	000c9717          	auipc	a4,0xc9
ffffffffc02050ec:	a5070713          	addi	a4,a4,-1456 # ffffffffc02cdb38 <fifo_sched_class>
{
ffffffffc02050f0:	e022                	sd	s0,0(sp)
ffffffffc02050f2:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc02050f4:	000cd797          	auipc	a5,0xcd
ffffffffc02050f8:	ecc78793          	addi	a5,a5,-308 # ffffffffc02d1fc0 <timer_list>
#endif

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc02050fc:	6714                	ld	a3,8(a4)
    rq = &__rq;
ffffffffc02050fe:	000cd517          	auipc	a0,0xcd
ffffffffc0205102:	ea250513          	addi	a0,a0,-350 # ffffffffc02d1fa0 <__rq>
ffffffffc0205106:	e79c                	sd	a5,8(a5)
ffffffffc0205108:	e39c                	sd	a5,0(a5)
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc020510a:	4795                	li	a5,5
ffffffffc020510c:	c95c                	sw	a5,20(a0)
    sched_class = &fifo_sched_class;
ffffffffc020510e:	000cd417          	auipc	s0,0xcd
ffffffffc0205112:	f4240413          	addi	s0,s0,-190 # ffffffffc02d2050 <sched_class>
    rq = &__rq;
ffffffffc0205116:	000cd797          	auipc	a5,0xcd
ffffffffc020511a:	f2a7b923          	sd	a0,-206(a5) # ffffffffc02d2048 <rq>
    sched_class = &fifo_sched_class;
ffffffffc020511e:	e018                	sd	a4,0(s0)
    sched_class->init(rq);
ffffffffc0205120:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205122:	601c                	ld	a5,0(s0)
}
ffffffffc0205124:	6402                	ld	s0,0(sp)
ffffffffc0205126:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205128:	638c                	ld	a1,0(a5)
ffffffffc020512a:	00002517          	auipc	a0,0x2
ffffffffc020512e:	4a650513          	addi	a0,a0,1190 # ffffffffc02075d0 <default_pmm_manager+0xf10>
}
ffffffffc0205132:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205134:	864fb06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0205138 <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205138:	4118                	lw	a4,0(a0)
{
ffffffffc020513a:	1101                	addi	sp,sp,-32
ffffffffc020513c:	ec06                	sd	ra,24(sp)
ffffffffc020513e:	e822                	sd	s0,16(sp)
ffffffffc0205140:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205142:	478d                	li	a5,3
ffffffffc0205144:	08f70363          	beq	a4,a5,ffffffffc02051ca <wakeup_proc+0x92>
ffffffffc0205148:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020514a:	100027f3          	csrr	a5,sstatus
ffffffffc020514e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205150:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205152:	e7bd                	bnez	a5,ffffffffc02051c0 <wakeup_proc+0x88>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205154:	4789                	li	a5,2
ffffffffc0205156:	04f70863          	beq	a4,a5,ffffffffc02051a6 <wakeup_proc+0x6e>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc020515a:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc020515c:	0e042623          	sw	zero,236(s0)
            if (proc != current)
ffffffffc0205160:	000cd797          	auipc	a5,0xcd
ffffffffc0205164:	ec87b783          	ld	a5,-312(a5) # ffffffffc02d2028 <current>
ffffffffc0205168:	02878363          	beq	a5,s0,ffffffffc020518e <wakeup_proc+0x56>
    if (proc != idleproc)
ffffffffc020516c:	000cd797          	auipc	a5,0xcd
ffffffffc0205170:	ec47b783          	ld	a5,-316(a5) # ffffffffc02d2030 <idleproc>
ffffffffc0205174:	00f40d63          	beq	s0,a5,ffffffffc020518e <wakeup_proc+0x56>
        sched_class->enqueue(rq, proc);
ffffffffc0205178:	000cd797          	auipc	a5,0xcd
ffffffffc020517c:	ed87b783          	ld	a5,-296(a5) # ffffffffc02d2050 <sched_class>
ffffffffc0205180:	6b9c                	ld	a5,16(a5)
ffffffffc0205182:	85a2                	mv	a1,s0
ffffffffc0205184:	000cd517          	auipc	a0,0xcd
ffffffffc0205188:	ec453503          	ld	a0,-316(a0) # ffffffffc02d2048 <rq>
ffffffffc020518c:	9782                	jalr	a5
    if (flag)
ffffffffc020518e:	e491                	bnez	s1,ffffffffc020519a <wakeup_proc+0x62>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205190:	60e2                	ld	ra,24(sp)
ffffffffc0205192:	6442                	ld	s0,16(sp)
ffffffffc0205194:	64a2                	ld	s1,8(sp)
ffffffffc0205196:	6105                	addi	sp,sp,32
ffffffffc0205198:	8082                	ret
ffffffffc020519a:	6442                	ld	s0,16(sp)
ffffffffc020519c:	60e2                	ld	ra,24(sp)
ffffffffc020519e:	64a2                	ld	s1,8(sp)
ffffffffc02051a0:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051a2:	807fb06f          	j	ffffffffc02009a8 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02051a6:	00002617          	auipc	a2,0x2
ffffffffc02051aa:	47a60613          	addi	a2,a2,1146 # ffffffffc0207620 <default_pmm_manager+0xf60>
ffffffffc02051ae:	06200593          	li	a1,98
ffffffffc02051b2:	00002517          	auipc	a0,0x2
ffffffffc02051b6:	45650513          	addi	a0,a0,1110 # ffffffffc0207608 <default_pmm_manager+0xf48>
ffffffffc02051ba:	b40fb0ef          	jal	ra,ffffffffc02004fa <__warn>
ffffffffc02051be:	bfc1                	j	ffffffffc020518e <wakeup_proc+0x56>
        intr_disable();
ffffffffc02051c0:	feefb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051c4:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc02051c6:	4485                	li	s1,1
ffffffffc02051c8:	b771                	j	ffffffffc0205154 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051ca:	00002697          	auipc	a3,0x2
ffffffffc02051ce:	41e68693          	addi	a3,a3,1054 # ffffffffc02075e8 <default_pmm_manager+0xf28>
ffffffffc02051d2:	00001617          	auipc	a2,0x1
ffffffffc02051d6:	13e60613          	addi	a2,a2,318 # ffffffffc0206310 <commands+0x828>
ffffffffc02051da:	05300593          	li	a1,83
ffffffffc02051de:	00002517          	auipc	a0,0x2
ffffffffc02051e2:	42a50513          	addi	a0,a0,1066 # ffffffffc0207608 <default_pmm_manager+0xf48>
ffffffffc02051e6:	aacfb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02051ea <schedule>:

void schedule(void)
{
ffffffffc02051ea:	7179                	addi	sp,sp,-48
ffffffffc02051ec:	f406                	sd	ra,40(sp)
ffffffffc02051ee:	f022                	sd	s0,32(sp)
ffffffffc02051f0:	ec26                	sd	s1,24(sp)
ffffffffc02051f2:	e84a                	sd	s2,16(sp)
ffffffffc02051f4:	e44e                	sd	s3,8(sp)
ffffffffc02051f6:	e052                	sd	s4,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051f8:	100027f3          	csrr	a5,sstatus
ffffffffc02051fc:	8b89                	andi	a5,a5,2
ffffffffc02051fe:	4a01                	li	s4,0
ffffffffc0205200:	e3cd                	bnez	a5,ffffffffc02052a2 <schedule+0xb8>
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        // need_resched 由时钟中断（proc_tick）或系统调用（yield/sleep/wait 等）设置，
        // schedule() 会清除此标志并选择新的进程运行。
        current->need_resched = 0;
ffffffffc0205202:	000cd497          	auipc	s1,0xcd
ffffffffc0205206:	e2648493          	addi	s1,s1,-474 # ffffffffc02d2028 <current>
ffffffffc020520a:	608c                	ld	a1,0(s1)
        sched_class->enqueue(rq, proc);
ffffffffc020520c:	000cd997          	auipc	s3,0xcd
ffffffffc0205210:	e4498993          	addi	s3,s3,-444 # ffffffffc02d2050 <sched_class>
ffffffffc0205214:	000cd917          	auipc	s2,0xcd
ffffffffc0205218:	e3490913          	addi	s2,s2,-460 # ffffffffc02d2048 <rq>
        if (current->state == PROC_RUNNABLE)
ffffffffc020521c:	4194                	lw	a3,0(a1)
        current->need_resched = 0;
ffffffffc020521e:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205222:	4709                	li	a4,2
        sched_class->enqueue(rq, proc);
ffffffffc0205224:	0009b783          	ld	a5,0(s3)
ffffffffc0205228:	00093503          	ld	a0,0(s2)
        if (current->state == PROC_RUNNABLE)
ffffffffc020522c:	04e68e63          	beq	a3,a4,ffffffffc0205288 <schedule+0x9e>
    return sched_class->pick_next(rq);
ffffffffc0205230:	739c                	ld	a5,32(a5)
ffffffffc0205232:	9782                	jalr	a5
ffffffffc0205234:	842a                	mv	s0,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc0205236:	c521                	beqz	a0,ffffffffc020527e <schedule+0x94>
    sched_class->dequeue(rq, proc);
ffffffffc0205238:	0009b783          	ld	a5,0(s3)
ffffffffc020523c:	00093503          	ld	a0,0(s2)
ffffffffc0205240:	85a2                	mv	a1,s0
ffffffffc0205242:	6f9c                	ld	a5,24(a5)
ffffffffc0205244:	9782                	jalr	a5
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc0205246:	441c                	lw	a5,8(s0)
        if (next != current)
ffffffffc0205248:	6098                	ld	a4,0(s1)
        next->runs++;
ffffffffc020524a:	2785                	addiw	a5,a5,1
ffffffffc020524c:	c41c                	sw	a5,8(s0)
        if (next != current)
ffffffffc020524e:	00870563          	beq	a4,s0,ffffffffc0205258 <schedule+0x6e>
        {
            proc_run(next);
ffffffffc0205252:	8522                	mv	a0,s0
ffffffffc0205254:	bb5fe0ef          	jal	ra,ffffffffc0203e08 <proc_run>
    if (flag)
ffffffffc0205258:	000a1a63          	bnez	s4,ffffffffc020526c <schedule+0x82>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020525c:	70a2                	ld	ra,40(sp)
ffffffffc020525e:	7402                	ld	s0,32(sp)
ffffffffc0205260:	64e2                	ld	s1,24(sp)
ffffffffc0205262:	6942                	ld	s2,16(sp)
ffffffffc0205264:	69a2                	ld	s3,8(sp)
ffffffffc0205266:	6a02                	ld	s4,0(sp)
ffffffffc0205268:	6145                	addi	sp,sp,48
ffffffffc020526a:	8082                	ret
ffffffffc020526c:	7402                	ld	s0,32(sp)
ffffffffc020526e:	70a2                	ld	ra,40(sp)
ffffffffc0205270:	64e2                	ld	s1,24(sp)
ffffffffc0205272:	6942                	ld	s2,16(sp)
ffffffffc0205274:	69a2                	ld	s3,8(sp)
ffffffffc0205276:	6a02                	ld	s4,0(sp)
ffffffffc0205278:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc020527a:	f2efb06f          	j	ffffffffc02009a8 <intr_enable>
            next = idleproc;
ffffffffc020527e:	000cd417          	auipc	s0,0xcd
ffffffffc0205282:	db243403          	ld	s0,-590(s0) # ffffffffc02d2030 <idleproc>
ffffffffc0205286:	b7c1                	j	ffffffffc0205246 <schedule+0x5c>
    if (proc != idleproc)
ffffffffc0205288:	000cd717          	auipc	a4,0xcd
ffffffffc020528c:	da873703          	ld	a4,-600(a4) # ffffffffc02d2030 <idleproc>
ffffffffc0205290:	fae580e3          	beq	a1,a4,ffffffffc0205230 <schedule+0x46>
        sched_class->enqueue(rq, proc);
ffffffffc0205294:	6b9c                	ld	a5,16(a5)
ffffffffc0205296:	9782                	jalr	a5
    return sched_class->pick_next(rq);
ffffffffc0205298:	0009b783          	ld	a5,0(s3)
ffffffffc020529c:	00093503          	ld	a0,0(s2)
ffffffffc02052a0:	bf41                	j	ffffffffc0205230 <schedule+0x46>
        intr_disable();
ffffffffc02052a2:	f0cfb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02052a6:	4a05                	li	s4,1
ffffffffc02052a8:	bfa9                	j	ffffffffc0205202 <schedule+0x18>

ffffffffc02052aa <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02052aa:	000cd797          	auipc	a5,0xcd
ffffffffc02052ae:	d7e7b783          	ld	a5,-642(a5) # ffffffffc02d2028 <current>
}
ffffffffc02052b2:	43c8                	lw	a0,4(a5)
ffffffffc02052b4:	8082                	ret

ffffffffc02052b6 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02052b6:	4501                	li	a0,0
ffffffffc02052b8:	8082                	ret

ffffffffc02052ba <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    // 用户态以毫秒为单位的粗略时间（ticks * 10ms）
    return (int)ticks*10;
ffffffffc02052ba:	000cd797          	auipc	a5,0xcd
ffffffffc02052be:	d1e7b783          	ld	a5,-738(a5) # ffffffffc02d1fd8 <ticks>
ffffffffc02052c2:	0027951b          	slliw	a0,a5,0x2
ffffffffc02052c6:	9d3d                	addw	a0,a0,a5
}
ffffffffc02052c8:	0015151b          	slliw	a0,a0,0x1
ffffffffc02052cc:	8082                	ret

ffffffffc02052ce <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    // 设置当前进程优先级（Stride 中权重越大，得到 CPU 越多）
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc02052ce:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc02052d0:	1141                	addi	sp,sp,-16
ffffffffc02052d2:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc02052d4:	c67ff0ef          	jal	ra,ffffffffc0204f3a <lab6_set_priority>
    return 0;
}
ffffffffc02052d8:	60a2                	ld	ra,8(sp)
ffffffffc02052da:	4501                	li	a0,0
ffffffffc02052dc:	0141                	addi	sp,sp,16
ffffffffc02052de:	8082                	ret

ffffffffc02052e0 <sys_putc>:
    cputchar(c);
ffffffffc02052e0:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02052e2:	1141                	addi	sp,sp,-16
ffffffffc02052e4:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02052e6:	ee9fa0ef          	jal	ra,ffffffffc02001ce <cputchar>
}
ffffffffc02052ea:	60a2                	ld	ra,8(sp)
ffffffffc02052ec:	4501                	li	a0,0
ffffffffc02052ee:	0141                	addi	sp,sp,16
ffffffffc02052f0:	8082                	ret

ffffffffc02052f2 <sys_kill>:
    return do_kill(pid);
ffffffffc02052f2:	4108                	lw	a0,0(a0)
ffffffffc02052f4:	a19ff06f          	j	ffffffffc0204d0c <do_kill>

ffffffffc02052f8 <sys_yield>:
    return do_yield();
ffffffffc02052f8:	9c7ff06f          	j	ffffffffc0204cbe <do_yield>

ffffffffc02052fc <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02052fc:	6d14                	ld	a3,24(a0)
ffffffffc02052fe:	6910                	ld	a2,16(a0)
ffffffffc0205300:	650c                	ld	a1,8(a0)
ffffffffc0205302:	6108                	ld	a0,0(a0)
ffffffffc0205304:	c08ff06f          	j	ffffffffc020470c <do_execve>

ffffffffc0205308 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205308:	650c                	ld	a1,8(a0)
ffffffffc020530a:	4108                	lw	a0,0(a0)
ffffffffc020530c:	9c3ff06f          	j	ffffffffc0204cce <do_wait>

ffffffffc0205310 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205310:	000cd797          	auipc	a5,0xcd
ffffffffc0205314:	d187b783          	ld	a5,-744(a5) # ffffffffc02d2028 <current>
ffffffffc0205318:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020531a:	4501                	li	a0,0
ffffffffc020531c:	6a0c                	ld	a1,16(a2)
ffffffffc020531e:	b5bfe06f          	j	ffffffffc0203e78 <do_fork>

ffffffffc0205322 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205322:	4108                	lw	a0,0(a0)
ffffffffc0205324:	fa9fe06f          	j	ffffffffc02042cc <do_exit>

ffffffffc0205328 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205328:	715d                	addi	sp,sp,-80
ffffffffc020532a:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc020532c:	000cd497          	auipc	s1,0xcd
ffffffffc0205330:	cfc48493          	addi	s1,s1,-772 # ffffffffc02d2028 <current>
ffffffffc0205334:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205336:	e0a2                	sd	s0,64(sp)
ffffffffc0205338:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc020533a:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc020533c:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020533e:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc0205342:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205346:	0327ee63          	bltu	a5,s2,ffffffffc0205382 <syscall+0x5a>
        if (syscalls[num] != NULL) {
ffffffffc020534a:	00391713          	slli	a4,s2,0x3
ffffffffc020534e:	00002797          	auipc	a5,0x2
ffffffffc0205352:	33a78793          	addi	a5,a5,826 # ffffffffc0207688 <syscalls>
ffffffffc0205356:	97ba                	add	a5,a5,a4
ffffffffc0205358:	639c                	ld	a5,0(a5)
ffffffffc020535a:	c785                	beqz	a5,ffffffffc0205382 <syscall+0x5a>
            arg[0] = tf->gpr.a1;
ffffffffc020535c:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc020535e:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205360:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205362:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205364:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205366:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205368:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020536a:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020536c:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020536e:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205370:	0028                	addi	a0,sp,8
ffffffffc0205372:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205374:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205376:	e828                	sd	a0,80(s0)
}
ffffffffc0205378:	6406                	ld	s0,64(sp)
ffffffffc020537a:	74e2                	ld	s1,56(sp)
ffffffffc020537c:	7942                	ld	s2,48(sp)
ffffffffc020537e:	6161                	addi	sp,sp,80
ffffffffc0205380:	8082                	ret
    print_trapframe(tf);
ffffffffc0205382:	8522                	mv	a0,s0
ffffffffc0205384:	81bfb0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205388:	609c                	ld	a5,0(s1)
ffffffffc020538a:	86ca                	mv	a3,s2
ffffffffc020538c:	00002617          	auipc	a2,0x2
ffffffffc0205390:	2b460613          	addi	a2,a2,692 # ffffffffc0207640 <default_pmm_manager+0xf80>
ffffffffc0205394:	43d8                	lw	a4,4(a5)
ffffffffc0205396:	07a00593          	li	a1,122
ffffffffc020539a:	0b478793          	addi	a5,a5,180
ffffffffc020539e:	00002517          	auipc	a0,0x2
ffffffffc02053a2:	2d250513          	addi	a0,a0,722 # ffffffffc0207670 <default_pmm_manager+0xfb0>
ffffffffc02053a6:	8ecfb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02053aa <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02053aa:	9e3707b7          	lui	a5,0x9e370
ffffffffc02053ae:	2785                	addiw	a5,a5,1
ffffffffc02053b0:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02053b4:	02000793          	li	a5,32
ffffffffc02053b8:	9f8d                	subw	a5,a5,a1
}
ffffffffc02053ba:	00f5553b          	srlw	a0,a0,a5
ffffffffc02053be:	8082                	ret

ffffffffc02053c0 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02053c0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053c4:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02053c6:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053ca:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02053cc:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053d0:	f022                	sd	s0,32(sp)
ffffffffc02053d2:	ec26                	sd	s1,24(sp)
ffffffffc02053d4:	e84a                	sd	s2,16(sp)
ffffffffc02053d6:	f406                	sd	ra,40(sp)
ffffffffc02053d8:	e44e                	sd	s3,8(sp)
ffffffffc02053da:	84aa                	mv	s1,a0
ffffffffc02053dc:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02053de:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02053e2:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02053e4:	03067e63          	bgeu	a2,a6,ffffffffc0205420 <printnum+0x60>
ffffffffc02053e8:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02053ea:	00805763          	blez	s0,ffffffffc02053f8 <printnum+0x38>
ffffffffc02053ee:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02053f0:	85ca                	mv	a1,s2
ffffffffc02053f2:	854e                	mv	a0,s3
ffffffffc02053f4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02053f6:	fc65                	bnez	s0,ffffffffc02053ee <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053f8:	1a02                	slli	s4,s4,0x20
ffffffffc02053fa:	00003797          	auipc	a5,0x3
ffffffffc02053fe:	a8e78793          	addi	a5,a5,-1394 # ffffffffc0207e88 <syscalls+0x800>
ffffffffc0205402:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205406:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205408:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020540a:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020540e:	70a2                	ld	ra,40(sp)
ffffffffc0205410:	69a2                	ld	s3,8(sp)
ffffffffc0205412:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205414:	85ca                	mv	a1,s2
ffffffffc0205416:	87a6                	mv	a5,s1
}
ffffffffc0205418:	6942                	ld	s2,16(sp)
ffffffffc020541a:	64e2                	ld	s1,24(sp)
ffffffffc020541c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020541e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205420:	03065633          	divu	a2,a2,a6
ffffffffc0205424:	8722                	mv	a4,s0
ffffffffc0205426:	f9bff0ef          	jal	ra,ffffffffc02053c0 <printnum>
ffffffffc020542a:	b7f9                	j	ffffffffc02053f8 <printnum+0x38>

ffffffffc020542c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020542c:	7119                	addi	sp,sp,-128
ffffffffc020542e:	f4a6                	sd	s1,104(sp)
ffffffffc0205430:	f0ca                	sd	s2,96(sp)
ffffffffc0205432:	ecce                	sd	s3,88(sp)
ffffffffc0205434:	e8d2                	sd	s4,80(sp)
ffffffffc0205436:	e4d6                	sd	s5,72(sp)
ffffffffc0205438:	e0da                	sd	s6,64(sp)
ffffffffc020543a:	fc5e                	sd	s7,56(sp)
ffffffffc020543c:	f06a                	sd	s10,32(sp)
ffffffffc020543e:	fc86                	sd	ra,120(sp)
ffffffffc0205440:	f8a2                	sd	s0,112(sp)
ffffffffc0205442:	f862                	sd	s8,48(sp)
ffffffffc0205444:	f466                	sd	s9,40(sp)
ffffffffc0205446:	ec6e                	sd	s11,24(sp)
ffffffffc0205448:	892a                	mv	s2,a0
ffffffffc020544a:	84ae                	mv	s1,a1
ffffffffc020544c:	8d32                	mv	s10,a2
ffffffffc020544e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205450:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205454:	5b7d                	li	s6,-1
ffffffffc0205456:	00003a97          	auipc	s5,0x3
ffffffffc020545a:	a5ea8a93          	addi	s5,s5,-1442 # ffffffffc0207eb4 <syscalls+0x82c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020545e:	00003b97          	auipc	s7,0x3
ffffffffc0205462:	c72b8b93          	addi	s7,s7,-910 # ffffffffc02080d0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205466:	000d4503          	lbu	a0,0(s10)
ffffffffc020546a:	001d0413          	addi	s0,s10,1
ffffffffc020546e:	01350a63          	beq	a0,s3,ffffffffc0205482 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205472:	c121                	beqz	a0,ffffffffc02054b2 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205474:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205476:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205478:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020547a:	fff44503          	lbu	a0,-1(s0)
ffffffffc020547e:	ff351ae3          	bne	a0,s3,ffffffffc0205472 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205482:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205486:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020548a:	4c81                	li	s9,0
ffffffffc020548c:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020548e:	5c7d                	li	s8,-1
ffffffffc0205490:	5dfd                	li	s11,-1
ffffffffc0205492:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205496:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205498:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020549c:	0ff5f593          	zext.b	a1,a1
ffffffffc02054a0:	00140d13          	addi	s10,s0,1
ffffffffc02054a4:	04b56263          	bltu	a0,a1,ffffffffc02054e8 <vprintfmt+0xbc>
ffffffffc02054a8:	058a                	slli	a1,a1,0x2
ffffffffc02054aa:	95d6                	add	a1,a1,s5
ffffffffc02054ac:	4194                	lw	a3,0(a1)
ffffffffc02054ae:	96d6                	add	a3,a3,s5
ffffffffc02054b0:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02054b2:	70e6                	ld	ra,120(sp)
ffffffffc02054b4:	7446                	ld	s0,112(sp)
ffffffffc02054b6:	74a6                	ld	s1,104(sp)
ffffffffc02054b8:	7906                	ld	s2,96(sp)
ffffffffc02054ba:	69e6                	ld	s3,88(sp)
ffffffffc02054bc:	6a46                	ld	s4,80(sp)
ffffffffc02054be:	6aa6                	ld	s5,72(sp)
ffffffffc02054c0:	6b06                	ld	s6,64(sp)
ffffffffc02054c2:	7be2                	ld	s7,56(sp)
ffffffffc02054c4:	7c42                	ld	s8,48(sp)
ffffffffc02054c6:	7ca2                	ld	s9,40(sp)
ffffffffc02054c8:	7d02                	ld	s10,32(sp)
ffffffffc02054ca:	6de2                	ld	s11,24(sp)
ffffffffc02054cc:	6109                	addi	sp,sp,128
ffffffffc02054ce:	8082                	ret
            padc = '0';
ffffffffc02054d0:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02054d2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054d6:	846a                	mv	s0,s10
ffffffffc02054d8:	00140d13          	addi	s10,s0,1
ffffffffc02054dc:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054e0:	0ff5f593          	zext.b	a1,a1
ffffffffc02054e4:	fcb572e3          	bgeu	a0,a1,ffffffffc02054a8 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02054e8:	85a6                	mv	a1,s1
ffffffffc02054ea:	02500513          	li	a0,37
ffffffffc02054ee:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02054f0:	fff44783          	lbu	a5,-1(s0)
ffffffffc02054f4:	8d22                	mv	s10,s0
ffffffffc02054f6:	f73788e3          	beq	a5,s3,ffffffffc0205466 <vprintfmt+0x3a>
ffffffffc02054fa:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02054fe:	1d7d                	addi	s10,s10,-1
ffffffffc0205500:	ff379de3          	bne	a5,s3,ffffffffc02054fa <vprintfmt+0xce>
ffffffffc0205504:	b78d                	j	ffffffffc0205466 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205506:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020550a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020550e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205510:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205514:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205518:	02d86463          	bltu	a6,a3,ffffffffc0205540 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020551c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205520:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205524:	0186873b          	addw	a4,a3,s8
ffffffffc0205528:	0017171b          	slliw	a4,a4,0x1
ffffffffc020552c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020552e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205532:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205534:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205538:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020553c:	fed870e3          	bgeu	a6,a3,ffffffffc020551c <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205540:	f40ddce3          	bgez	s11,ffffffffc0205498 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205544:	8de2                	mv	s11,s8
ffffffffc0205546:	5c7d                	li	s8,-1
ffffffffc0205548:	bf81                	j	ffffffffc0205498 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020554a:	fffdc693          	not	a3,s11
ffffffffc020554e:	96fd                	srai	a3,a3,0x3f
ffffffffc0205550:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205554:	00144603          	lbu	a2,1(s0)
ffffffffc0205558:	2d81                	sext.w	s11,s11
ffffffffc020555a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020555c:	bf35                	j	ffffffffc0205498 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020555e:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205562:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205566:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205568:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020556a:	bfd9                	j	ffffffffc0205540 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020556c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020556e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205572:	01174463          	blt	a4,a7,ffffffffc020557a <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205576:	1a088e63          	beqz	a7,ffffffffc0205732 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020557a:	000a3603          	ld	a2,0(s4)
ffffffffc020557e:	46c1                	li	a3,16
ffffffffc0205580:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205582:	2781                	sext.w	a5,a5
ffffffffc0205584:	876e                	mv	a4,s11
ffffffffc0205586:	85a6                	mv	a1,s1
ffffffffc0205588:	854a                	mv	a0,s2
ffffffffc020558a:	e37ff0ef          	jal	ra,ffffffffc02053c0 <printnum>
            break;
ffffffffc020558e:	bde1                	j	ffffffffc0205466 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205590:	000a2503          	lw	a0,0(s4)
ffffffffc0205594:	85a6                	mv	a1,s1
ffffffffc0205596:	0a21                	addi	s4,s4,8
ffffffffc0205598:	9902                	jalr	s2
            break;
ffffffffc020559a:	b5f1                	j	ffffffffc0205466 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020559c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020559e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055a2:	01174463          	blt	a4,a7,ffffffffc02055aa <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02055a6:	18088163          	beqz	a7,ffffffffc0205728 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02055aa:	000a3603          	ld	a2,0(s4)
ffffffffc02055ae:	46a9                	li	a3,10
ffffffffc02055b0:	8a2e                	mv	s4,a1
ffffffffc02055b2:	bfc1                	j	ffffffffc0205582 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055b4:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02055b8:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055ba:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055bc:	bdf1                	j	ffffffffc0205498 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02055be:	85a6                	mv	a1,s1
ffffffffc02055c0:	02500513          	li	a0,37
ffffffffc02055c4:	9902                	jalr	s2
            break;
ffffffffc02055c6:	b545                	j	ffffffffc0205466 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055c8:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02055cc:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055ce:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055d0:	b5e1                	j	ffffffffc0205498 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02055d2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055d4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055d8:	01174463          	blt	a4,a7,ffffffffc02055e0 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02055dc:	14088163          	beqz	a7,ffffffffc020571e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02055e0:	000a3603          	ld	a2,0(s4)
ffffffffc02055e4:	46a1                	li	a3,8
ffffffffc02055e6:	8a2e                	mv	s4,a1
ffffffffc02055e8:	bf69                	j	ffffffffc0205582 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02055ea:	03000513          	li	a0,48
ffffffffc02055ee:	85a6                	mv	a1,s1
ffffffffc02055f0:	e03e                	sd	a5,0(sp)
ffffffffc02055f2:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02055f4:	85a6                	mv	a1,s1
ffffffffc02055f6:	07800513          	li	a0,120
ffffffffc02055fa:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055fc:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02055fe:	6782                	ld	a5,0(sp)
ffffffffc0205600:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205602:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205606:	bfb5                	j	ffffffffc0205582 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205608:	000a3403          	ld	s0,0(s4)
ffffffffc020560c:	008a0713          	addi	a4,s4,8
ffffffffc0205610:	e03a                	sd	a4,0(sp)
ffffffffc0205612:	14040263          	beqz	s0,ffffffffc0205756 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205616:	0fb05763          	blez	s11,ffffffffc0205704 <vprintfmt+0x2d8>
ffffffffc020561a:	02d00693          	li	a3,45
ffffffffc020561e:	0cd79163          	bne	a5,a3,ffffffffc02056e0 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205622:	00044783          	lbu	a5,0(s0)
ffffffffc0205626:	0007851b          	sext.w	a0,a5
ffffffffc020562a:	cf85                	beqz	a5,ffffffffc0205662 <vprintfmt+0x236>
ffffffffc020562c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205630:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205634:	000c4563          	bltz	s8,ffffffffc020563e <vprintfmt+0x212>
ffffffffc0205638:	3c7d                	addiw	s8,s8,-1
ffffffffc020563a:	036c0263          	beq	s8,s6,ffffffffc020565e <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020563e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205640:	0e0c8e63          	beqz	s9,ffffffffc020573c <vprintfmt+0x310>
ffffffffc0205644:	3781                	addiw	a5,a5,-32
ffffffffc0205646:	0ef47b63          	bgeu	s0,a5,ffffffffc020573c <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020564a:	03f00513          	li	a0,63
ffffffffc020564e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205650:	000a4783          	lbu	a5,0(s4)
ffffffffc0205654:	3dfd                	addiw	s11,s11,-1
ffffffffc0205656:	0a05                	addi	s4,s4,1
ffffffffc0205658:	0007851b          	sext.w	a0,a5
ffffffffc020565c:	ffe1                	bnez	a5,ffffffffc0205634 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020565e:	01b05963          	blez	s11,ffffffffc0205670 <vprintfmt+0x244>
ffffffffc0205662:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205664:	85a6                	mv	a1,s1
ffffffffc0205666:	02000513          	li	a0,32
ffffffffc020566a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020566c:	fe0d9be3          	bnez	s11,ffffffffc0205662 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205670:	6a02                	ld	s4,0(sp)
ffffffffc0205672:	bbd5                	j	ffffffffc0205466 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205674:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205676:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020567a:	01174463          	blt	a4,a7,ffffffffc0205682 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020567e:	08088d63          	beqz	a7,ffffffffc0205718 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205682:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205686:	0a044d63          	bltz	s0,ffffffffc0205740 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020568a:	8622                	mv	a2,s0
ffffffffc020568c:	8a66                	mv	s4,s9
ffffffffc020568e:	46a9                	li	a3,10
ffffffffc0205690:	bdcd                	j	ffffffffc0205582 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205692:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205696:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205698:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020569a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020569e:	8fb5                	xor	a5,a5,a3
ffffffffc02056a0:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056a4:	02d74163          	blt	a4,a3,ffffffffc02056c6 <vprintfmt+0x29a>
ffffffffc02056a8:	00369793          	slli	a5,a3,0x3
ffffffffc02056ac:	97de                	add	a5,a5,s7
ffffffffc02056ae:	639c                	ld	a5,0(a5)
ffffffffc02056b0:	cb99                	beqz	a5,ffffffffc02056c6 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02056b2:	86be                	mv	a3,a5
ffffffffc02056b4:	00000617          	auipc	a2,0x0
ffffffffc02056b8:	1f460613          	addi	a2,a2,500 # ffffffffc02058a8 <etext+0x2e>
ffffffffc02056bc:	85a6                	mv	a1,s1
ffffffffc02056be:	854a                	mv	a0,s2
ffffffffc02056c0:	0ce000ef          	jal	ra,ffffffffc020578e <printfmt>
ffffffffc02056c4:	b34d                	j	ffffffffc0205466 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02056c6:	00002617          	auipc	a2,0x2
ffffffffc02056ca:	7e260613          	addi	a2,a2,2018 # ffffffffc0207ea8 <syscalls+0x820>
ffffffffc02056ce:	85a6                	mv	a1,s1
ffffffffc02056d0:	854a                	mv	a0,s2
ffffffffc02056d2:	0bc000ef          	jal	ra,ffffffffc020578e <printfmt>
ffffffffc02056d6:	bb41                	j	ffffffffc0205466 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02056d8:	00002417          	auipc	s0,0x2
ffffffffc02056dc:	7c840413          	addi	s0,s0,1992 # ffffffffc0207ea0 <syscalls+0x818>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056e0:	85e2                	mv	a1,s8
ffffffffc02056e2:	8522                	mv	a0,s0
ffffffffc02056e4:	e43e                	sd	a5,8(sp)
ffffffffc02056e6:	0e2000ef          	jal	ra,ffffffffc02057c8 <strnlen>
ffffffffc02056ea:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02056ee:	01b05b63          	blez	s11,ffffffffc0205704 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02056f2:	67a2                	ld	a5,8(sp)
ffffffffc02056f4:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056f8:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02056fa:	85a6                	mv	a1,s1
ffffffffc02056fc:	8552                	mv	a0,s4
ffffffffc02056fe:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205700:	fe0d9ce3          	bnez	s11,ffffffffc02056f8 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205704:	00044783          	lbu	a5,0(s0)
ffffffffc0205708:	00140a13          	addi	s4,s0,1
ffffffffc020570c:	0007851b          	sext.w	a0,a5
ffffffffc0205710:	d3a5                	beqz	a5,ffffffffc0205670 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205712:	05e00413          	li	s0,94
ffffffffc0205716:	bf39                	j	ffffffffc0205634 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205718:	000a2403          	lw	s0,0(s4)
ffffffffc020571c:	b7ad                	j	ffffffffc0205686 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020571e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205722:	46a1                	li	a3,8
ffffffffc0205724:	8a2e                	mv	s4,a1
ffffffffc0205726:	bdb1                	j	ffffffffc0205582 <vprintfmt+0x156>
ffffffffc0205728:	000a6603          	lwu	a2,0(s4)
ffffffffc020572c:	46a9                	li	a3,10
ffffffffc020572e:	8a2e                	mv	s4,a1
ffffffffc0205730:	bd89                	j	ffffffffc0205582 <vprintfmt+0x156>
ffffffffc0205732:	000a6603          	lwu	a2,0(s4)
ffffffffc0205736:	46c1                	li	a3,16
ffffffffc0205738:	8a2e                	mv	s4,a1
ffffffffc020573a:	b5a1                	j	ffffffffc0205582 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020573c:	9902                	jalr	s2
ffffffffc020573e:	bf09                	j	ffffffffc0205650 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205740:	85a6                	mv	a1,s1
ffffffffc0205742:	02d00513          	li	a0,45
ffffffffc0205746:	e03e                	sd	a5,0(sp)
ffffffffc0205748:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020574a:	6782                	ld	a5,0(sp)
ffffffffc020574c:	8a66                	mv	s4,s9
ffffffffc020574e:	40800633          	neg	a2,s0
ffffffffc0205752:	46a9                	li	a3,10
ffffffffc0205754:	b53d                	j	ffffffffc0205582 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205756:	03b05163          	blez	s11,ffffffffc0205778 <vprintfmt+0x34c>
ffffffffc020575a:	02d00693          	li	a3,45
ffffffffc020575e:	f6d79de3          	bne	a5,a3,ffffffffc02056d8 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205762:	00002417          	auipc	s0,0x2
ffffffffc0205766:	73e40413          	addi	s0,s0,1854 # ffffffffc0207ea0 <syscalls+0x818>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020576a:	02800793          	li	a5,40
ffffffffc020576e:	02800513          	li	a0,40
ffffffffc0205772:	00140a13          	addi	s4,s0,1
ffffffffc0205776:	bd6d                	j	ffffffffc0205630 <vprintfmt+0x204>
ffffffffc0205778:	00002a17          	auipc	s4,0x2
ffffffffc020577c:	729a0a13          	addi	s4,s4,1833 # ffffffffc0207ea1 <syscalls+0x819>
ffffffffc0205780:	02800513          	li	a0,40
ffffffffc0205784:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205788:	05e00413          	li	s0,94
ffffffffc020578c:	b565                	j	ffffffffc0205634 <vprintfmt+0x208>

ffffffffc020578e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020578e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205790:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205794:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205796:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205798:	ec06                	sd	ra,24(sp)
ffffffffc020579a:	f83a                	sd	a4,48(sp)
ffffffffc020579c:	fc3e                	sd	a5,56(sp)
ffffffffc020579e:	e0c2                	sd	a6,64(sp)
ffffffffc02057a0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02057a2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057a4:	c89ff0ef          	jal	ra,ffffffffc020542c <vprintfmt>
}
ffffffffc02057a8:	60e2                	ld	ra,24(sp)
ffffffffc02057aa:	6161                	addi	sp,sp,80
ffffffffc02057ac:	8082                	ret

ffffffffc02057ae <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02057ae:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02057b2:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02057b4:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02057b6:	cb81                	beqz	a5,ffffffffc02057c6 <strlen+0x18>
        cnt ++;
ffffffffc02057b8:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02057ba:	00a707b3          	add	a5,a4,a0
ffffffffc02057be:	0007c783          	lbu	a5,0(a5)
ffffffffc02057c2:	fbfd                	bnez	a5,ffffffffc02057b8 <strlen+0xa>
ffffffffc02057c4:	8082                	ret
    }
    return cnt;
}
ffffffffc02057c6:	8082                	ret

ffffffffc02057c8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02057c8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057ca:	e589                	bnez	a1,ffffffffc02057d4 <strnlen+0xc>
ffffffffc02057cc:	a811                	j	ffffffffc02057e0 <strnlen+0x18>
        cnt ++;
ffffffffc02057ce:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057d0:	00f58863          	beq	a1,a5,ffffffffc02057e0 <strnlen+0x18>
ffffffffc02057d4:	00f50733          	add	a4,a0,a5
ffffffffc02057d8:	00074703          	lbu	a4,0(a4)
ffffffffc02057dc:	fb6d                	bnez	a4,ffffffffc02057ce <strnlen+0x6>
ffffffffc02057de:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02057e0:	852e                	mv	a0,a1
ffffffffc02057e2:	8082                	ret

ffffffffc02057e4 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02057e4:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02057e6:	0005c703          	lbu	a4,0(a1)
ffffffffc02057ea:	0785                	addi	a5,a5,1
ffffffffc02057ec:	0585                	addi	a1,a1,1
ffffffffc02057ee:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02057f2:	fb75                	bnez	a4,ffffffffc02057e6 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02057f4:	8082                	ret

ffffffffc02057f6 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057f6:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057fa:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057fe:	cb89                	beqz	a5,ffffffffc0205810 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205800:	0505                	addi	a0,a0,1
ffffffffc0205802:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205804:	fee789e3          	beq	a5,a4,ffffffffc02057f6 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205808:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020580c:	9d19                	subw	a0,a0,a4
ffffffffc020580e:	8082                	ret
ffffffffc0205810:	4501                	li	a0,0
ffffffffc0205812:	bfed                	j	ffffffffc020580c <strcmp+0x16>

ffffffffc0205814 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205814:	c20d                	beqz	a2,ffffffffc0205836 <strncmp+0x22>
ffffffffc0205816:	962e                	add	a2,a2,a1
ffffffffc0205818:	a031                	j	ffffffffc0205824 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020581a:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020581c:	00e79a63          	bne	a5,a4,ffffffffc0205830 <strncmp+0x1c>
ffffffffc0205820:	00b60b63          	beq	a2,a1,ffffffffc0205836 <strncmp+0x22>
ffffffffc0205824:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205828:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020582a:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020582e:	f7f5                	bnez	a5,ffffffffc020581a <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205830:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205834:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205836:	4501                	li	a0,0
ffffffffc0205838:	8082                	ret

ffffffffc020583a <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020583a:	00054783          	lbu	a5,0(a0)
ffffffffc020583e:	c799                	beqz	a5,ffffffffc020584c <strchr+0x12>
        if (*s == c) {
ffffffffc0205840:	00f58763          	beq	a1,a5,ffffffffc020584e <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205844:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205848:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020584a:	fbfd                	bnez	a5,ffffffffc0205840 <strchr+0x6>
    }
    return NULL;
ffffffffc020584c:	4501                	li	a0,0
}
ffffffffc020584e:	8082                	ret

ffffffffc0205850 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205850:	ca01                	beqz	a2,ffffffffc0205860 <memset+0x10>
ffffffffc0205852:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205854:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205856:	0785                	addi	a5,a5,1
ffffffffc0205858:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020585c:	fec79de3          	bne	a5,a2,ffffffffc0205856 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205860:	8082                	ret

ffffffffc0205862 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205862:	ca19                	beqz	a2,ffffffffc0205878 <memcpy+0x16>
ffffffffc0205864:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205866:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205868:	0005c703          	lbu	a4,0(a1)
ffffffffc020586c:	0585                	addi	a1,a1,1
ffffffffc020586e:	0785                	addi	a5,a5,1
ffffffffc0205870:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205874:	fec59ae3          	bne	a1,a2,ffffffffc0205868 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205878:	8082                	ret
