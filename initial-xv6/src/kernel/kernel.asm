
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	f0e78793          	addi	a5,a5,-242 # 80005f70 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc07f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	438080e7          	jalr	1080(ra) # 80002562 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	addi	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	addi	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000180:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	8cc50513          	addi	a0,a0,-1844 # 80010a50 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8bc48493          	addi	s1,s1,-1860 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	94c90913          	addi	s2,s2,-1716 # 80010ae8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00001097          	auipc	ra,0x1
    800001b8:	7f2080e7          	jalr	2034(ra) # 800019a6 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	1f0080e7          	jalr	496(ra) # 800023ac <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	f2e080e7          	jalr	-210(ra) # 800020f8 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	87270713          	addi	a4,a4,-1934 # 80010a50 <cons>
    800001e6:	0017869b          	addiw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	andi	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	addi	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	2fc080e7          	jalr	764(ra) # 8000250c <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	82850513          	addi	a0,a0,-2008 # 80010a50 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	81250513          	addi	a0,a0,-2030 # 80010a50 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a40080e7          	jalr	-1472(ra) # 80000c86 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	addi	sp,sp,96
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	86f72d23          	sw	a5,-1926(a4) # 80010ae8 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	addi	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	addi	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00010517          	auipc	a0,0x10
    800002cc:	78850513          	addi	a0,a0,1928 # 80010a50 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	2ca080e7          	jalr	714(ra) # 800025b8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	75a50513          	addi	a0,a0,1882 # 80010a50 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	addi	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	73670713          	addi	a4,a4,1846 # 80010a50 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00010797          	auipc	a5,0x10
    80000348:	70c78793          	addi	a5,a5,1804 # 80010a50 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addiw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	andi	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00010797          	auipc	a5,0x10
    80000376:	7767a783          	lw	a5,1910(a5) # 80010ae8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6ca70713          	addi	a4,a4,1738 # 80010a50 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6ba48493          	addi	s1,s1,1722 # 80010a50 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addiw	a5,a5,-1
    800003a6:	07f7f713          	andi	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	67e70713          	addi	a4,a4,1662 # 80010a50 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	70f72423          	sw	a5,1800(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	64278793          	addi	a5,a5,1602 # 80010a50 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	6ac7ad23          	sw	a2,1722(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	6ae50513          	addi	a0,a0,1710 # 80010ae8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	d1a080e7          	jalr	-742(ra) # 8000215c <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	addi	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	addi	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	5f450513          	addi	a0,a0,1524 # 80010a50 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00021797          	auipc	a5,0x21
    80000478:	17478793          	addi	a5,a5,372 # 800215e8 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	addi	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	addi	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	addi	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	addi	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	addi	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	addi	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	addi	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addiw	a4,a4,-1
    8000050e:	1702                	slli	a4,a4,0x20
    80000510:	9301                	srli	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	addi	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	addi	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	addi	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	5c07a423          	sw	zero,1480(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	addi	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b5e50513          	addi	a0,a0,-1186 # 800080c8 <digits+0x88>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	34f72a23          	sw	a5,852(a4) # 800088d0 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	addi	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	addi	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	558dad83          	lw	s11,1368(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	addi	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	addi	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	50250513          	addi	a0,a0,1282 # 80010af8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	5d4080e7          	jalr	1492(ra) # 80000bd2 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	addi	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	addi	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	addi	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srli	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	slli	s2,s2,0x4
    800006d4:	34fd                	addiw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	addi	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	addi	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	addi	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	addi	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	3a450513          	addi	a0,a0,932 # 80010af8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	52a080e7          	jalr	1322(ra) # 80000c86 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	addi	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	38848493          	addi	s1,s1,904 # 80010af8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	addi	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	3c0080e7          	jalr	960(ra) # 80000b42 <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	addi	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	addi	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	addi	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	34850513          	addi	a0,a0,840 # 80010b18 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	addi	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	392080e7          	jalr	914(ra) # 80000b86 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	0d47a783          	lw	a5,212(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	andi	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	404080e7          	jalr	1028(ra) # 80000c26 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	addi	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	0a47b783          	ld	a5,164(a5) # 800088d8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0a473703          	ld	a4,164(a4) # 800088e0 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	addi	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	2baa0a13          	addi	s4,s4,698 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	07248493          	addi	s1,s1,114 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	07298993          	addi	s3,s3,114 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	andi	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	andi	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	addi	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	8cc080e7          	jalr	-1844(ra) # 8000215c <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	addi	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	addi	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	addi	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	24c50513          	addi	a0,a0,588 # 80010b18 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	ff47a783          	lw	a5,-12(a5) # 800088d0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	ffa73703          	ld	a4,-6(a4) # 800088e0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	fea7b783          	ld	a5,-22(a5) # 800088d8 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	21e98993          	addi	s3,s3,542 # 80010b18 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fd648493          	addi	s1,s1,-42 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fd690913          	addi	s2,s2,-42 # 800088e0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	7de080e7          	jalr	2014(ra) # 800020f8 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1e848493          	addi	s1,s1,488 # 80010b18 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f8e7be23          	sd	a4,-100(a5) # 800088e0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	330080e7          	jalr	816(ra) # 80000c86 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	addi	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	andi	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	addi	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	addi	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	16248493          	addi	s1,s1,354 # 80010b18 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b4080e7          	jalr	692(ra) # 80000c86 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00022797          	auipc	a5,0x22
    800009fc:	d8878793          	addi	a5,a5,-632 # 80022780 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	13890913          	addi	s2,s2,312 # 80010b50 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1b0080e7          	jalr	432(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	addi	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	addi	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	addi	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	addi	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	addi	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	09a50513          	addi	a0,a0,154 # 80010b50 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00022517          	auipc	a0,0x22
    80000ace:	cb650513          	addi	a0,a0,-842 # 80022780 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	addi	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	addi	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	06448493          	addi	s1,s1,100 # 80010b50 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	04c50513          	addi	a0,a0,76 # 80010b50 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	addi	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	02050513          	addi	a0,a0,32 # 80010b50 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	addi	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	addi	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	e1e080e7          	jalr	-482(ra) # 8000198a <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	addi	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	addi	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	dec080e7          	jalr	-532(ra) # 8000198a <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	de0080e7          	jalr	-544(ra) # 8000198a <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	dc8080e7          	jalr	-568(ra) # 8000198a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srli	s1,s1,0x1
    80000bcc:	8885                	andi	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	addi	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	addi	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	d88080e7          	jalr	-632(ra) # 8000198a <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	addi	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	45a50513          	addi	a0,a0,1114 # 80008070 <digits+0x30>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	addi	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	d5c080e7          	jalr	-676(ra) # 8000198a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addiw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	addi	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	41250513          	addi	a0,a0,1042 # 80008078 <digits+0x38>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	41a50513          	addi	a0,a0,1050 # 80008090 <digits+0x50>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	addi	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	addi	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	addi	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3da50513          	addi	a0,a0,986 # 80008098 <digits+0x58>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	876080e7          	jalr	-1930(ra) # 8000053c <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	addi	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	slli	a2,a2,0x20
    80000cda:	9201                	srli	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	addi	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	addi	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	addi	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfc:	1682                	slli	a3,a3,0x20
    80000cfe:	9281                	srli	a3,a3,0x20
    80000d00:	0685                	addi	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	addi	a0,a0,1
    80000d12:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	addi	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d30:	c205                	beqz	a2,80000d50 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e263          	bltu	a1,a0,80000d56 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	1602                	slli	a2,a2,0x20
    80000d38:	9201                	srli	a2,a2,0x20
    80000d3a:	00c587b3          	add	a5,a1,a2
{
    80000d3e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d40:	0585                	addi	a1,a1,1
    80000d42:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc881>
    80000d44:	fff5c683          	lbu	a3,-1(a1)
    80000d48:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4c:	fef59ae3          	bne	a1,a5,80000d40 <memmove+0x16>

  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret
  if(s < d && s + n > d){
    80000d56:	02061693          	slli	a3,a2,0x20
    80000d5a:	9281                	srli	a3,a3,0x20
    80000d5c:	00d58733          	add	a4,a1,a3
    80000d60:	fce57be3          	bgeu	a0,a4,80000d36 <memmove+0xc>
    d += n;
    80000d64:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d66:	fff6079b          	addiw	a5,a2,-1
    80000d6a:	1782                	slli	a5,a5,0x20
    80000d6c:	9381                	srli	a5,a5,0x20
    80000d6e:	fff7c793          	not	a5,a5
    80000d72:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d74:	177d                	addi	a4,a4,-1
    80000d76:	16fd                	addi	a3,a3,-1
    80000d78:	00074603          	lbu	a2,0(a4)
    80000d7c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d80:	fee79ae3          	bne	a5,a4,80000d74 <memmove+0x4a>
    80000d84:	b7f1                	j	80000d50 <memmove+0x26>

0000000080000d86 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d86:	1141                	addi	sp,sp,-16
    80000d88:	e406                	sd	ra,8(sp)
    80000d8a:	e022                	sd	s0,0(sp)
    80000d8c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	f9c080e7          	jalr	-100(ra) # 80000d2a <memmove>
}
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	6402                	ld	s0,0(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9e:	1141                	addi	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da4:	ce11                	beqz	a2,80000dc0 <strncmp+0x22>
    80000da6:	00054783          	lbu	a5,0(a0)
    80000daa:	cf89                	beqz	a5,80000dc4 <strncmp+0x26>
    80000dac:	0005c703          	lbu	a4,0(a1)
    80000db0:	00f71a63          	bne	a4,a5,80000dc4 <strncmp+0x26>
    n--, p++, q++;
    80000db4:	367d                	addiw	a2,a2,-1
    80000db6:	0505                	addi	a0,a0,1
    80000db8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dba:	f675                	bnez	a2,80000da6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbc:	4501                	li	a0,0
    80000dbe:	a809                	j	80000dd0 <strncmp+0x32>
    80000dc0:	4501                	li	a0,0
    80000dc2:	a039                	j	80000dd0 <strncmp+0x32>
  if(n == 0)
    80000dc4:	ca09                	beqz	a2,80000dd6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	addi	sp,sp,16
    80000dd4:	8082                	ret
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	bfe5                	j	80000dd0 <strncmp+0x32>

0000000080000dda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dda:	1141                	addi	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de0:	87aa                	mv	a5,a0
    80000de2:	86b2                	mv	a3,a2
    80000de4:	367d                	addiw	a2,a2,-1
    80000de6:	00d05963          	blez	a3,80000df8 <strncpy+0x1e>
    80000dea:	0785                	addi	a5,a5,1
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	fee78fa3          	sb	a4,-1(a5)
    80000df4:	0585                	addi	a1,a1,1
    80000df6:	f775                	bnez	a4,80000de2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df8:	873e                	mv	a4,a5
    80000dfa:	9fb5                	addw	a5,a5,a3
    80000dfc:	37fd                	addiw	a5,a5,-1
    80000dfe:	00c05963          	blez	a2,80000e10 <strncpy+0x36>
    *s++ = 0;
    80000e02:	0705                	addi	a4,a4,1
    80000e04:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e08:	40e786bb          	subw	a3,a5,a4
    80000e0c:	fed04be3          	bgtz	a3,80000e02 <strncpy+0x28>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86be                	mv	a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	ff65                	bnez	a4,80000e58 <strlen+0x10>
    80000e62:	40a6853b          	subw	a0,a3,a0
    80000e66:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	b00080e7          	jalr	-1280(ra) # 8000197a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	a6670713          	addi	a4,a4,-1434 # 800088e8 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ae4080e7          	jalr	-1308(ra) # 8000197a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6de080e7          	jalr	1758(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	9ec080e7          	jalr	-1556(ra) # 800028a4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	0f0080e7          	jalr	240(ra) # 80005fb0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	07e080e7          	jalr	126(ra) # 80001f46 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67e080e7          	jalr	1662(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b96080e7          	jalr	-1130(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	326080e7          	jalr	806(ra) # 8000123e <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	99e080e7          	jalr	-1634(ra) # 800018c6 <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	94c080e7          	jalr	-1716(ra) # 8000287c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	96c080e7          	jalr	-1684(ra) # 800028a4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	05a080e7          	jalr	90(ra) # 80005f9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	068080e7          	jalr	104(ra) # 80005fb0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	24c080e7          	jalr	588(ra) # 8000319c <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	8ea080e7          	jalr	-1814(ra) # 80003842 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	860080e7          	jalr	-1952(ra) # 800047c0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	150080e7          	jalr	336(ra) # 800060b8 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	db8080e7          	jalr	-584(ra) # 80001d28 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	96f72523          	sw	a5,-1686(a4) # 800088e8 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f8e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f92:	00008797          	auipc	a5,0x8
    80000f96:	95e7b783          	ld	a5,-1698(a5) # 800088f0 <kernel_pagetable>
    80000f9a:	83b1                	srli	a5,a5,0xc
    80000f9c:	577d                	li	a4,-1
    80000f9e:	177e                	slli	a4,a4,0x3f
    80000fa0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fa6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000faa:	6422                	ld	s0,8(sp)
    80000fac:	0141                	addi	sp,sp,16
    80000fae:	8082                	ret

0000000080000fb0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb0:	7139                	addi	sp,sp,-64
    80000fb2:	fc06                	sd	ra,56(sp)
    80000fb4:	f822                	sd	s0,48(sp)
    80000fb6:	f426                	sd	s1,40(sp)
    80000fb8:	f04a                	sd	s2,32(sp)
    80000fba:	ec4e                	sd	s3,24(sp)
    80000fbc:	e852                	sd	s4,16(sp)
    80000fbe:	e456                	sd	s5,8(sp)
    80000fc0:	e05a                	sd	s6,0(sp)
    80000fc2:	0080                	addi	s0,sp,64
    80000fc4:	84aa                	mv	s1,a0
    80000fc6:	89ae                	mv	s3,a1
    80000fc8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fca:	57fd                	li	a5,-1
    80000fcc:	83e9                	srli	a5,a5,0x1a
    80000fce:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd2:	04b7f263          	bgeu	a5,a1,80001016 <walk+0x66>
    panic("walk");
    80000fd6:	00007517          	auipc	a0,0x7
    80000fda:	0fa50513          	addi	a0,a0,250 # 800080d0 <digits+0x90>
    80000fde:	fffff097          	auipc	ra,0xfffff
    80000fe2:	55e080e7          	jalr	1374(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe6:	060a8663          	beqz	s5,80001052 <walk+0xa2>
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	af8080e7          	jalr	-1288(ra) # 80000ae2 <kalloc>
    80000ff2:	84aa                	mv	s1,a0
    80000ff4:	c529                	beqz	a0,8000103e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff6:	6605                	lui	a2,0x1
    80000ff8:	4581                	li	a1,0
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	cd4080e7          	jalr	-812(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001002:	00c4d793          	srli	a5,s1,0xc
    80001006:	07aa                	slli	a5,a5,0xa
    80001008:	0017e793          	ori	a5,a5,1
    8000100c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001010:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc877>
    80001012:	036a0063          	beq	s4,s6,80001032 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001016:	0149d933          	srl	s2,s3,s4
    8000101a:	1ff97913          	andi	s2,s2,511
    8000101e:	090e                	slli	s2,s2,0x3
    80001020:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001022:	00093483          	ld	s1,0(s2)
    80001026:	0014f793          	andi	a5,s1,1
    8000102a:	dfd5                	beqz	a5,80000fe6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000102c:	80a9                	srli	s1,s1,0xa
    8000102e:	04b2                	slli	s1,s1,0xc
    80001030:	b7c5                	j	80001010 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001032:	00c9d513          	srli	a0,s3,0xc
    80001036:	1ff57513          	andi	a0,a0,511
    8000103a:	050e                	slli	a0,a0,0x3
    8000103c:	9526                	add	a0,a0,s1
}
    8000103e:	70e2                	ld	ra,56(sp)
    80001040:	7442                	ld	s0,48(sp)
    80001042:	74a2                	ld	s1,40(sp)
    80001044:	7902                	ld	s2,32(sp)
    80001046:	69e2                	ld	s3,24(sp)
    80001048:	6a42                	ld	s4,16(sp)
    8000104a:	6aa2                	ld	s5,8(sp)
    8000104c:	6b02                	ld	s6,0(sp)
    8000104e:	6121                	addi	sp,sp,64
    80001050:	8082                	ret
        return 0;
    80001052:	4501                	li	a0,0
    80001054:	b7ed                	j	8000103e <walk+0x8e>

0000000080001056 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001056:	57fd                	li	a5,-1
    80001058:	83e9                	srli	a5,a5,0x1a
    8000105a:	00b7f463          	bgeu	a5,a1,80001062 <walkaddr+0xc>
    return 0;
    8000105e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001060:	8082                	ret
{
    80001062:	1141                	addi	sp,sp,-16
    80001064:	e406                	sd	ra,8(sp)
    80001066:	e022                	sd	s0,0(sp)
    80001068:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000106a:	4601                	li	a2,0
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	f44080e7          	jalr	-188(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001074:	c105                	beqz	a0,80001094 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001076:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001078:	0117f693          	andi	a3,a5,17
    8000107c:	4745                	li	a4,17
    return 0;
    8000107e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001080:	00e68663          	beq	a3,a4,8000108c <walkaddr+0x36>
}
    80001084:	60a2                	ld	ra,8(sp)
    80001086:	6402                	ld	s0,0(sp)
    80001088:	0141                	addi	sp,sp,16
    8000108a:	8082                	ret
  pa = PTE2PA(*pte);
    8000108c:	83a9                	srli	a5,a5,0xa
    8000108e:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001092:	bfcd                	j	80001084 <walkaddr+0x2e>
    return 0;
    80001094:	4501                	li	a0,0
    80001096:	b7fd                	j	80001084 <walkaddr+0x2e>

0000000080001098 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001098:	715d                	addi	sp,sp,-80
    8000109a:	e486                	sd	ra,72(sp)
    8000109c:	e0a2                	sd	s0,64(sp)
    8000109e:	fc26                	sd	s1,56(sp)
    800010a0:	f84a                	sd	s2,48(sp)
    800010a2:	f44e                	sd	s3,40(sp)
    800010a4:	f052                	sd	s4,32(sp)
    800010a6:	ec56                	sd	s5,24(sp)
    800010a8:	e85a                	sd	s6,16(sp)
    800010aa:	e45e                	sd	s7,8(sp)
    800010ac:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ae:	c639                	beqz	a2,800010fc <mappages+0x64>
    800010b0:	8aaa                	mv	s5,a0
    800010b2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b4:	777d                	lui	a4,0xfffff
    800010b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ba:	fff58993          	addi	s3,a1,-1
    800010be:	99b2                	add	s3,s3,a2
    800010c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c4:	893e                	mv	s2,a5
    800010c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ca:	6b85                	lui	s7,0x1
    800010cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d0:	4605                	li	a2,1
    800010d2:	85ca                	mv	a1,s2
    800010d4:	8556                	mv	a0,s5
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	eda080e7          	jalr	-294(ra) # 80000fb0 <walk>
    800010de:	cd1d                	beqz	a0,8000111c <mappages+0x84>
    if(*pte & PTE_V)
    800010e0:	611c                	ld	a5,0(a0)
    800010e2:	8b85                	andi	a5,a5,1
    800010e4:	e785                	bnez	a5,8000110c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e6:	80b1                	srli	s1,s1,0xc
    800010e8:	04aa                	slli	s1,s1,0xa
    800010ea:	0164e4b3          	or	s1,s1,s6
    800010ee:	0014e493          	ori	s1,s1,1
    800010f2:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f4:	05390063          	beq	s2,s3,80001134 <mappages+0x9c>
    a += PGSIZE;
    800010f8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010fa:	bfc9                	j	800010cc <mappages+0x34>
    panic("mappages: size");
    800010fc:	00007517          	auipc	a0,0x7
    80001100:	fdc50513          	addi	a0,a0,-36 # 800080d8 <digits+0x98>
    80001104:	fffff097          	auipc	ra,0xfffff
    80001108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000110c:	00007517          	auipc	a0,0x7
    80001110:	fdc50513          	addi	a0,a0,-36 # 800080e8 <digits+0xa8>
    80001114:	fffff097          	auipc	ra,0xfffff
    80001118:	428080e7          	jalr	1064(ra) # 8000053c <panic>
      return -1;
    8000111c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111e:	60a6                	ld	ra,72(sp)
    80001120:	6406                	ld	s0,64(sp)
    80001122:	74e2                	ld	s1,56(sp)
    80001124:	7942                	ld	s2,48(sp)
    80001126:	79a2                	ld	s3,40(sp)
    80001128:	7a02                	ld	s4,32(sp)
    8000112a:	6ae2                	ld	s5,24(sp)
    8000112c:	6b42                	ld	s6,16(sp)
    8000112e:	6ba2                	ld	s7,8(sp)
    80001130:	6161                	addi	sp,sp,80
    80001132:	8082                	ret
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	b7e5                	j	8000111e <mappages+0x86>

0000000080001138 <kvmmap>:
{
    80001138:	1141                	addi	sp,sp,-16
    8000113a:	e406                	sd	ra,8(sp)
    8000113c:	e022                	sd	s0,0(sp)
    8000113e:	0800                	addi	s0,sp,16
    80001140:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001142:	86b2                	mv	a3,a2
    80001144:	863e                	mv	a2,a5
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	f52080e7          	jalr	-174(ra) # 80001098 <mappages>
    8000114e:	e509                	bnez	a0,80001158 <kvmmap+0x20>
}
    80001150:	60a2                	ld	ra,8(sp)
    80001152:	6402                	ld	s0,0(sp)
    80001154:	0141                	addi	sp,sp,16
    80001156:	8082                	ret
    panic("kvmmap");
    80001158:	00007517          	auipc	a0,0x7
    8000115c:	fa050513          	addi	a0,a0,-96 # 800080f8 <digits+0xb8>
    80001160:	fffff097          	auipc	ra,0xfffff
    80001164:	3dc080e7          	jalr	988(ra) # 8000053c <panic>

0000000080001168 <kvmmake>:
{
    80001168:	1101                	addi	sp,sp,-32
    8000116a:	ec06                	sd	ra,24(sp)
    8000116c:	e822                	sd	s0,16(sp)
    8000116e:	e426                	sd	s1,8(sp)
    80001170:	e04a                	sd	s2,0(sp)
    80001172:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001174:	00000097          	auipc	ra,0x0
    80001178:	96e080e7          	jalr	-1682(ra) # 80000ae2 <kalloc>
    8000117c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117e:	6605                	lui	a2,0x1
    80001180:	4581                	li	a1,0
    80001182:	00000097          	auipc	ra,0x0
    80001186:	b4c080e7          	jalr	-1204(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000118a:	4719                	li	a4,6
    8000118c:	6685                	lui	a3,0x1
    8000118e:	10000637          	lui	a2,0x10000
    80001192:	100005b7          	lui	a1,0x10000
    80001196:	8526                	mv	a0,s1
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	fa0080e7          	jalr	-96(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	6685                	lui	a3,0x1
    800011a4:	10001637          	lui	a2,0x10001
    800011a8:	100015b7          	lui	a1,0x10001
    800011ac:	8526                	mv	a0,s1
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	f8a080e7          	jalr	-118(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b6:	4719                	li	a4,6
    800011b8:	004006b7          	lui	a3,0x400
    800011bc:	0c000637          	lui	a2,0xc000
    800011c0:	0c0005b7          	lui	a1,0xc000
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f72080e7          	jalr	-142(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ce:	00007917          	auipc	s2,0x7
    800011d2:	e3290913          	addi	s2,s2,-462 # 80008000 <etext>
    800011d6:	4729                	li	a4,10
    800011d8:	80007697          	auipc	a3,0x80007
    800011dc:	e2868693          	addi	a3,a3,-472 # 8000 <_entry-0x7fff8000>
    800011e0:	4605                	li	a2,1
    800011e2:	067e                	slli	a2,a2,0x1f
    800011e4:	85b2                	mv	a1,a2
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f50080e7          	jalr	-176(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f0:	4719                	li	a4,6
    800011f2:	46c5                	li	a3,17
    800011f4:	06ee                	slli	a3,a3,0x1b
    800011f6:	412686b3          	sub	a3,a3,s2
    800011fa:	864a                	mv	a2,s2
    800011fc:	85ca                	mv	a1,s2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f38080e7          	jalr	-200(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001208:	4729                	li	a4,10
    8000120a:	6685                	lui	a3,0x1
    8000120c:	00006617          	auipc	a2,0x6
    80001210:	df460613          	addi	a2,a2,-524 # 80007000 <_trampoline>
    80001214:	040005b7          	lui	a1,0x4000
    80001218:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000121a:	05b2                	slli	a1,a1,0xc
    8000121c:	8526                	mv	a0,s1
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f1a080e7          	jalr	-230(ra) # 80001138 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001226:	8526                	mv	a0,s1
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	608080e7          	jalr	1544(ra) # 80001830 <proc_mapstacks>
}
    80001230:	8526                	mv	a0,s1
    80001232:	60e2                	ld	ra,24(sp)
    80001234:	6442                	ld	s0,16(sp)
    80001236:	64a2                	ld	s1,8(sp)
    80001238:	6902                	ld	s2,0(sp)
    8000123a:	6105                	addi	sp,sp,32
    8000123c:	8082                	ret

000000008000123e <kvminit>:
{
    8000123e:	1141                	addi	sp,sp,-16
    80001240:	e406                	sd	ra,8(sp)
    80001242:	e022                	sd	s0,0(sp)
    80001244:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f22080e7          	jalr	-222(ra) # 80001168 <kvmmake>
    8000124e:	00007797          	auipc	a5,0x7
    80001252:	6aa7b123          	sd	a0,1698(a5) # 800088f0 <kernel_pagetable>
}
    80001256:	60a2                	ld	ra,8(sp)
    80001258:	6402                	ld	s0,0(sp)
    8000125a:	0141                	addi	sp,sp,16
    8000125c:	8082                	ret

000000008000125e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125e:	715d                	addi	sp,sp,-80
    80001260:	e486                	sd	ra,72(sp)
    80001262:	e0a2                	sd	s0,64(sp)
    80001264:	fc26                	sd	s1,56(sp)
    80001266:	f84a                	sd	s2,48(sp)
    80001268:	f44e                	sd	s3,40(sp)
    8000126a:	f052                	sd	s4,32(sp)
    8000126c:	ec56                	sd	s5,24(sp)
    8000126e:	e85a                	sd	s6,16(sp)
    80001270:	e45e                	sd	s7,8(sp)
    80001272:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001274:	03459793          	slli	a5,a1,0x34
    80001278:	e795                	bnez	a5,800012a4 <uvmunmap+0x46>
    8000127a:	8a2a                	mv	s4,a0
    8000127c:	892e                	mv	s2,a1
    8000127e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001280:	0632                	slli	a2,a2,0xc
    80001282:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001286:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001288:	6b05                	lui	s6,0x1
    8000128a:	0735e263          	bltu	a1,s3,800012ee <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128e:	60a6                	ld	ra,72(sp)
    80001290:	6406                	ld	s0,64(sp)
    80001292:	74e2                	ld	s1,56(sp)
    80001294:	7942                	ld	s2,48(sp)
    80001296:	79a2                	ld	s3,40(sp)
    80001298:	7a02                	ld	s4,32(sp)
    8000129a:	6ae2                	ld	s5,24(sp)
    8000129c:	6b42                	ld	s6,16(sp)
    8000129e:	6ba2                	ld	s7,8(sp)
    800012a0:	6161                	addi	sp,sp,80
    800012a2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a4:	00007517          	auipc	a0,0x7
    800012a8:	e5c50513          	addi	a0,a0,-420 # 80008100 <digits+0xc0>
    800012ac:	fffff097          	auipc	ra,0xfffff
    800012b0:	290080e7          	jalr	656(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800012b4:	00007517          	auipc	a0,0x7
    800012b8:	e6450513          	addi	a0,a0,-412 # 80008118 <digits+0xd8>
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	280080e7          	jalr	640(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e6450513          	addi	a0,a0,-412 # 80008128 <digits+0xe8>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	270080e7          	jalr	624(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e6c50513          	addi	a0,a0,-404 # 80008140 <digits+0x100>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	260080e7          	jalr	608(ra) # 8000053c <panic>
    *pte = 0;
    800012e4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e8:	995a                	add	s2,s2,s6
    800012ea:	fb3972e3          	bgeu	s2,s3,8000128e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ee:	4601                	li	a2,0
    800012f0:	85ca                	mv	a1,s2
    800012f2:	8552                	mv	a0,s4
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	cbc080e7          	jalr	-836(ra) # 80000fb0 <walk>
    800012fc:	84aa                	mv	s1,a0
    800012fe:	d95d                	beqz	a0,800012b4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001300:	6108                	ld	a0,0(a0)
    80001302:	00157793          	andi	a5,a0,1
    80001306:	dfdd                	beqz	a5,800012c4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001308:	3ff57793          	andi	a5,a0,1023
    8000130c:	fd7784e3          	beq	a5,s7,800012d4 <uvmunmap+0x76>
    if(do_free){
    80001310:	fc0a8ae3          	beqz	s5,800012e4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001314:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001316:	0532                	slli	a0,a0,0xc
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	6cc080e7          	jalr	1740(ra) # 800009e4 <kfree>
    80001320:	b7d1                	j	800012e4 <uvmunmap+0x86>

0000000080001322 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001322:	1101                	addi	sp,sp,-32
    80001324:	ec06                	sd	ra,24(sp)
    80001326:	e822                	sd	s0,16(sp)
    80001328:	e426                	sd	s1,8(sp)
    8000132a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	7b6080e7          	jalr	1974(ra) # 80000ae2 <kalloc>
    80001334:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001336:	c519                	beqz	a0,80001344 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001338:	6605                	lui	a2,0x1
    8000133a:	4581                	li	a1,0
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	992080e7          	jalr	-1646(ra) # 80000cce <memset>
  return pagetable;
}
    80001344:	8526                	mv	a0,s1
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6105                	addi	sp,sp,32
    8000134e:	8082                	ret

0000000080001350 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001350:	7179                	addi	sp,sp,-48
    80001352:	f406                	sd	ra,40(sp)
    80001354:	f022                	sd	s0,32(sp)
    80001356:	ec26                	sd	s1,24(sp)
    80001358:	e84a                	sd	s2,16(sp)
    8000135a:	e44e                	sd	s3,8(sp)
    8000135c:	e052                	sd	s4,0(sp)
    8000135e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001360:	6785                	lui	a5,0x1
    80001362:	04f67863          	bgeu	a2,a5,800013b2 <uvmfirst+0x62>
    80001366:	8a2a                	mv	s4,a0
    80001368:	89ae                	mv	s3,a1
    8000136a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000136c:	fffff097          	auipc	ra,0xfffff
    80001370:	776080e7          	jalr	1910(ra) # 80000ae2 <kalloc>
    80001374:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001376:	6605                	lui	a2,0x1
    80001378:	4581                	li	a1,0
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	954080e7          	jalr	-1708(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001382:	4779                	li	a4,30
    80001384:	86ca                	mv	a3,s2
    80001386:	6605                	lui	a2,0x1
    80001388:	4581                	li	a1,0
    8000138a:	8552                	mv	a0,s4
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	d0c080e7          	jalr	-756(ra) # 80001098 <mappages>
  memmove(mem, src, sz);
    80001394:	8626                	mv	a2,s1
    80001396:	85ce                	mv	a1,s3
    80001398:	854a                	mv	a0,s2
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	990080e7          	jalr	-1648(ra) # 80000d2a <memmove>
}
    800013a2:	70a2                	ld	ra,40(sp)
    800013a4:	7402                	ld	s0,32(sp)
    800013a6:	64e2                	ld	s1,24(sp)
    800013a8:	6942                	ld	s2,16(sp)
    800013aa:	69a2                	ld	s3,8(sp)
    800013ac:	6a02                	ld	s4,0(sp)
    800013ae:	6145                	addi	sp,sp,48
    800013b0:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	da650513          	addi	a0,a0,-602 # 80008158 <digits+0x118>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	182080e7          	jalr	386(ra) # 8000053c <panic>

00000000800013c2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c2:	1101                	addi	sp,sp,-32
    800013c4:	ec06                	sd	ra,24(sp)
    800013c6:	e822                	sd	s0,16(sp)
    800013c8:	e426                	sd	s1,8(sp)
    800013ca:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013cc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ce:	00b67d63          	bgeu	a2,a1,800013e8 <uvmdealloc+0x26>
    800013d2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d4:	6785                	lui	a5,0x1
    800013d6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d8:	00f60733          	add	a4,a2,a5
    800013dc:	76fd                	lui	a3,0xfffff
    800013de:	8f75                	and	a4,a4,a3
    800013e0:	97ae                	add	a5,a5,a1
    800013e2:	8ff5                	and	a5,a5,a3
    800013e4:	00f76863          	bltu	a4,a5,800013f4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e8:	8526                	mv	a0,s1
    800013ea:	60e2                	ld	ra,24(sp)
    800013ec:	6442                	ld	s0,16(sp)
    800013ee:	64a2                	ld	s1,8(sp)
    800013f0:	6105                	addi	sp,sp,32
    800013f2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f4:	8f99                	sub	a5,a5,a4
    800013f6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f8:	4685                	li	a3,1
    800013fa:	0007861b          	sext.w	a2,a5
    800013fe:	85ba                	mv	a1,a4
    80001400:	00000097          	auipc	ra,0x0
    80001404:	e5e080e7          	jalr	-418(ra) # 8000125e <uvmunmap>
    80001408:	b7c5                	j	800013e8 <uvmdealloc+0x26>

000000008000140a <uvmalloc>:
  if(newsz < oldsz)
    8000140a:	0ab66563          	bltu	a2,a1,800014b4 <uvmalloc+0xaa>
{
    8000140e:	7139                	addi	sp,sp,-64
    80001410:	fc06                	sd	ra,56(sp)
    80001412:	f822                	sd	s0,48(sp)
    80001414:	f426                	sd	s1,40(sp)
    80001416:	f04a                	sd	s2,32(sp)
    80001418:	ec4e                	sd	s3,24(sp)
    8000141a:	e852                	sd	s4,16(sp)
    8000141c:	e456                	sd	s5,8(sp)
    8000141e:	e05a                	sd	s6,0(sp)
    80001420:	0080                	addi	s0,sp,64
    80001422:	8aaa                	mv	s5,a0
    80001424:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001426:	6785                	lui	a5,0x1
    80001428:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000142a:	95be                	add	a1,a1,a5
    8000142c:	77fd                	lui	a5,0xfffff
    8000142e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001432:	08c9f363          	bgeu	s3,a2,800014b8 <uvmalloc+0xae>
    80001436:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001438:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000143c:	fffff097          	auipc	ra,0xfffff
    80001440:	6a6080e7          	jalr	1702(ra) # 80000ae2 <kalloc>
    80001444:	84aa                	mv	s1,a0
    if(mem == 0){
    80001446:	c51d                	beqz	a0,80001474 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	882080e7          	jalr	-1918(ra) # 80000cce <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001454:	875a                	mv	a4,s6
    80001456:	86a6                	mv	a3,s1
    80001458:	6605                	lui	a2,0x1
    8000145a:	85ca                	mv	a1,s2
    8000145c:	8556                	mv	a0,s5
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	c3a080e7          	jalr	-966(ra) # 80001098 <mappages>
    80001466:	e90d                	bnez	a0,80001498 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001468:	6785                	lui	a5,0x1
    8000146a:	993e                	add	s2,s2,a5
    8000146c:	fd4968e3          	bltu	s2,s4,8000143c <uvmalloc+0x32>
  return newsz;
    80001470:	8552                	mv	a0,s4
    80001472:	a809                	j	80001484 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001474:	864e                	mv	a2,s3
    80001476:	85ca                	mv	a1,s2
    80001478:	8556                	mv	a0,s5
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	f48080e7          	jalr	-184(ra) # 800013c2 <uvmdealloc>
      return 0;
    80001482:	4501                	li	a0,0
}
    80001484:	70e2                	ld	ra,56(sp)
    80001486:	7442                	ld	s0,48(sp)
    80001488:	74a2                	ld	s1,40(sp)
    8000148a:	7902                	ld	s2,32(sp)
    8000148c:	69e2                	ld	s3,24(sp)
    8000148e:	6a42                	ld	s4,16(sp)
    80001490:	6aa2                	ld	s5,8(sp)
    80001492:	6b02                	ld	s6,0(sp)
    80001494:	6121                	addi	sp,sp,64
    80001496:	8082                	ret
      kfree(mem);
    80001498:	8526                	mv	a0,s1
    8000149a:	fffff097          	auipc	ra,0xfffff
    8000149e:	54a080e7          	jalr	1354(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a2:	864e                	mv	a2,s3
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	f1a080e7          	jalr	-230(ra) # 800013c2 <uvmdealloc>
      return 0;
    800014b0:	4501                	li	a0,0
    800014b2:	bfc9                	j	80001484 <uvmalloc+0x7a>
    return oldsz;
    800014b4:	852e                	mv	a0,a1
}
    800014b6:	8082                	ret
  return newsz;
    800014b8:	8532                	mv	a0,a2
    800014ba:	b7e9                	j	80001484 <uvmalloc+0x7a>

00000000800014bc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014bc:	7179                	addi	sp,sp,-48
    800014be:	f406                	sd	ra,40(sp)
    800014c0:	f022                	sd	s0,32(sp)
    800014c2:	ec26                	sd	s1,24(sp)
    800014c4:	e84a                	sd	s2,16(sp)
    800014c6:	e44e                	sd	s3,8(sp)
    800014c8:	e052                	sd	s4,0(sp)
    800014ca:	1800                	addi	s0,sp,48
    800014cc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ce:	84aa                	mv	s1,a0
    800014d0:	6905                	lui	s2,0x1
    800014d2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d4:	4985                	li	s3,1
    800014d6:	a829                	j	800014f0 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014d8:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014da:	00c79513          	slli	a0,a5,0xc
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	fde080e7          	jalr	-34(ra) # 800014bc <freewalk>
      pagetable[i] = 0;
    800014e6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ea:	04a1                	addi	s1,s1,8
    800014ec:	03248163          	beq	s1,s2,8000150e <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	00f7f713          	andi	a4,a5,15
    800014f6:	ff3701e3          	beq	a4,s3,800014d8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fa:	8b85                	andi	a5,a5,1
    800014fc:	d7fd                	beqz	a5,800014ea <freewalk+0x2e>
      panic("freewalk: leaf");
    800014fe:	00007517          	auipc	a0,0x7
    80001502:	c7a50513          	addi	a0,a0,-902 # 80008178 <digits+0x138>
    80001506:	fffff097          	auipc	ra,0xfffff
    8000150a:	036080e7          	jalr	54(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    8000150e:	8552                	mv	a0,s4
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	4d4080e7          	jalr	1236(ra) # 800009e4 <kfree>
}
    80001518:	70a2                	ld	ra,40(sp)
    8000151a:	7402                	ld	s0,32(sp)
    8000151c:	64e2                	ld	s1,24(sp)
    8000151e:	6942                	ld	s2,16(sp)
    80001520:	69a2                	ld	s3,8(sp)
    80001522:	6a02                	ld	s4,0(sp)
    80001524:	6145                	addi	sp,sp,48
    80001526:	8082                	ret

0000000080001528 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001528:	1101                	addi	sp,sp,-32
    8000152a:	ec06                	sd	ra,24(sp)
    8000152c:	e822                	sd	s0,16(sp)
    8000152e:	e426                	sd	s1,8(sp)
    80001530:	1000                	addi	s0,sp,32
    80001532:	84aa                	mv	s1,a0
  if(sz > 0)
    80001534:	e999                	bnez	a1,8000154a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001536:	8526                	mv	a0,s1
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	f84080e7          	jalr	-124(ra) # 800014bc <freewalk>
}
    80001540:	60e2                	ld	ra,24(sp)
    80001542:	6442                	ld	s0,16(sp)
    80001544:	64a2                	ld	s1,8(sp)
    80001546:	6105                	addi	sp,sp,32
    80001548:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154a:	6785                	lui	a5,0x1
    8000154c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000154e:	95be                	add	a1,a1,a5
    80001550:	4685                	li	a3,1
    80001552:	00c5d613          	srli	a2,a1,0xc
    80001556:	4581                	li	a1,0
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	d06080e7          	jalr	-762(ra) # 8000125e <uvmunmap>
    80001560:	bfd9                	j	80001536 <uvmfree+0xe>

0000000080001562 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001562:	c679                	beqz	a2,80001630 <uvmcopy+0xce>
{
    80001564:	715d                	addi	sp,sp,-80
    80001566:	e486                	sd	ra,72(sp)
    80001568:	e0a2                	sd	s0,64(sp)
    8000156a:	fc26                	sd	s1,56(sp)
    8000156c:	f84a                	sd	s2,48(sp)
    8000156e:	f44e                	sd	s3,40(sp)
    80001570:	f052                	sd	s4,32(sp)
    80001572:	ec56                	sd	s5,24(sp)
    80001574:	e85a                	sd	s6,16(sp)
    80001576:	e45e                	sd	s7,8(sp)
    80001578:	0880                	addi	s0,sp,80
    8000157a:	8b2a                	mv	s6,a0
    8000157c:	8aae                	mv	s5,a1
    8000157e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001580:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001582:	4601                	li	a2,0
    80001584:	85ce                	mv	a1,s3
    80001586:	855a                	mv	a0,s6
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	a28080e7          	jalr	-1496(ra) # 80000fb0 <walk>
    80001590:	c531                	beqz	a0,800015dc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001592:	6118                	ld	a4,0(a0)
    80001594:	00177793          	andi	a5,a4,1
    80001598:	cbb1                	beqz	a5,800015ec <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159a:	00a75593          	srli	a1,a4,0xa
    8000159e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	53c080e7          	jalr	1340(ra) # 80000ae2 <kalloc>
    800015ae:	892a                	mv	s2,a0
    800015b0:	c939                	beqz	a0,80001606 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85de                	mv	a1,s7
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	774080e7          	jalr	1908(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015be:	8726                	mv	a4,s1
    800015c0:	86ca                	mv	a3,s2
    800015c2:	6605                	lui	a2,0x1
    800015c4:	85ce                	mv	a1,s3
    800015c6:	8556                	mv	a0,s5
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	ad0080e7          	jalr	-1328(ra) # 80001098 <mappages>
    800015d0:	e515                	bnez	a0,800015fc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d2:	6785                	lui	a5,0x1
    800015d4:	99be                	add	s3,s3,a5
    800015d6:	fb49e6e3          	bltu	s3,s4,80001582 <uvmcopy+0x20>
    800015da:	a081                	j	8000161a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bac50513          	addi	a0,a0,-1108 # 80008188 <digits+0x148>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f58080e7          	jalr	-168(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800015ec:	00007517          	auipc	a0,0x7
    800015f0:	bbc50513          	addi	a0,a0,-1092 # 800081a8 <digits+0x168>
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	f48080e7          	jalr	-184(ra) # 8000053c <panic>
      kfree(mem);
    800015fc:	854a                	mv	a0,s2
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	3e6080e7          	jalr	998(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001606:	4685                	li	a3,1
    80001608:	00c9d613          	srli	a2,s3,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	8556                	mv	a0,s5
    80001610:	00000097          	auipc	ra,0x0
    80001614:	c4e080e7          	jalr	-946(ra) # 8000125e <uvmunmap>
  return -1;
    80001618:	557d                	li	a0,-1
}
    8000161a:	60a6                	ld	ra,72(sp)
    8000161c:	6406                	ld	s0,64(sp)
    8000161e:	74e2                	ld	s1,56(sp)
    80001620:	7942                	ld	s2,48(sp)
    80001622:	79a2                	ld	s3,40(sp)
    80001624:	7a02                	ld	s4,32(sp)
    80001626:	6ae2                	ld	s5,24(sp)
    80001628:	6b42                	ld	s6,16(sp)
    8000162a:	6ba2                	ld	s7,8(sp)
    8000162c:	6161                	addi	sp,sp,80
    8000162e:	8082                	ret
  return 0;
    80001630:	4501                	li	a0,0
}
    80001632:	8082                	ret

0000000080001634 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001634:	1141                	addi	sp,sp,-16
    80001636:	e406                	sd	ra,8(sp)
    80001638:	e022                	sd	s0,0(sp)
    8000163a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163c:	4601                	li	a2,0
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	972080e7          	jalr	-1678(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001646:	c901                	beqz	a0,80001656 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001648:	611c                	ld	a5,0(a0)
    8000164a:	9bbd                	andi	a5,a5,-17
    8000164c:	e11c                	sd	a5,0(a0)
}
    8000164e:	60a2                	ld	ra,8(sp)
    80001650:	6402                	ld	s0,0(sp)
    80001652:	0141                	addi	sp,sp,16
    80001654:	8082                	ret
    panic("uvmclear");
    80001656:	00007517          	auipc	a0,0x7
    8000165a:	b7250513          	addi	a0,a0,-1166 # 800081c8 <digits+0x188>
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	ede080e7          	jalr	-290(ra) # 8000053c <panic>

0000000080001666 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001666:	c6bd                	beqz	a3,800016d4 <copyout+0x6e>
{
    80001668:	715d                	addi	sp,sp,-80
    8000166a:	e486                	sd	ra,72(sp)
    8000166c:	e0a2                	sd	s0,64(sp)
    8000166e:	fc26                	sd	s1,56(sp)
    80001670:	f84a                	sd	s2,48(sp)
    80001672:	f44e                	sd	s3,40(sp)
    80001674:	f052                	sd	s4,32(sp)
    80001676:	ec56                	sd	s5,24(sp)
    80001678:	e85a                	sd	s6,16(sp)
    8000167a:	e45e                	sd	s7,8(sp)
    8000167c:	e062                	sd	s8,0(sp)
    8000167e:	0880                	addi	s0,sp,80
    80001680:	8b2a                	mv	s6,a0
    80001682:	8c2e                	mv	s8,a1
    80001684:	8a32                	mv	s4,a2
    80001686:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001688:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168a:	6a85                	lui	s5,0x1
    8000168c:	a015                	j	800016b0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000168e:	9562                	add	a0,a0,s8
    80001690:	0004861b          	sext.w	a2,s1
    80001694:	85d2                	mv	a1,s4
    80001696:	41250533          	sub	a0,a0,s2
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	690080e7          	jalr	1680(ra) # 80000d2a <memmove>

    len -= n;
    800016a2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016a8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ac:	02098263          	beqz	s3,800016d0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b4:	85ca                	mv	a1,s2
    800016b6:	855a                	mv	a0,s6
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	99e080e7          	jalr	-1634(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800016c0:	cd01                	beqz	a0,800016d8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c2:	418904b3          	sub	s1,s2,s8
    800016c6:	94d6                	add	s1,s1,s5
    800016c8:	fc99f3e3          	bgeu	s3,s1,8000168e <copyout+0x28>
    800016cc:	84ce                	mv	s1,s3
    800016ce:	b7c1                	j	8000168e <copyout+0x28>
  }
  return 0;
    800016d0:	4501                	li	a0,0
    800016d2:	a021                	j	800016da <copyout+0x74>
    800016d4:	4501                	li	a0,0
}
    800016d6:	8082                	ret
      return -1;
    800016d8:	557d                	li	a0,-1
}
    800016da:	60a6                	ld	ra,72(sp)
    800016dc:	6406                	ld	s0,64(sp)
    800016de:	74e2                	ld	s1,56(sp)
    800016e0:	7942                	ld	s2,48(sp)
    800016e2:	79a2                	ld	s3,40(sp)
    800016e4:	7a02                	ld	s4,32(sp)
    800016e6:	6ae2                	ld	s5,24(sp)
    800016e8:	6b42                	ld	s6,16(sp)
    800016ea:	6ba2                	ld	s7,8(sp)
    800016ec:	6c02                	ld	s8,0(sp)
    800016ee:	6161                	addi	sp,sp,80
    800016f0:	8082                	ret

00000000800016f2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f2:	caa5                	beqz	a3,80001762 <copyin+0x70>
{
    800016f4:	715d                	addi	sp,sp,-80
    800016f6:	e486                	sd	ra,72(sp)
    800016f8:	e0a2                	sd	s0,64(sp)
    800016fa:	fc26                	sd	s1,56(sp)
    800016fc:	f84a                	sd	s2,48(sp)
    800016fe:	f44e                	sd	s3,40(sp)
    80001700:	f052                	sd	s4,32(sp)
    80001702:	ec56                	sd	s5,24(sp)
    80001704:	e85a                	sd	s6,16(sp)
    80001706:	e45e                	sd	s7,8(sp)
    80001708:	e062                	sd	s8,0(sp)
    8000170a:	0880                	addi	s0,sp,80
    8000170c:	8b2a                	mv	s6,a0
    8000170e:	8a2e                	mv	s4,a1
    80001710:	8c32                	mv	s8,a2
    80001712:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001714:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001716:	6a85                	lui	s5,0x1
    80001718:	a01d                	j	8000173e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171a:	018505b3          	add	a1,a0,s8
    8000171e:	0004861b          	sext.w	a2,s1
    80001722:	412585b3          	sub	a1,a1,s2
    80001726:	8552                	mv	a0,s4
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	602080e7          	jalr	1538(ra) # 80000d2a <memmove>

    len -= n;
    80001730:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001734:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001736:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173a:	02098263          	beqz	s3,8000175e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000173e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001742:	85ca                	mv	a1,s2
    80001744:	855a                	mv	a0,s6
    80001746:	00000097          	auipc	ra,0x0
    8000174a:	910080e7          	jalr	-1776(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    8000174e:	cd01                	beqz	a0,80001766 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001750:	418904b3          	sub	s1,s2,s8
    80001754:	94d6                	add	s1,s1,s5
    80001756:	fc99f2e3          	bgeu	s3,s1,8000171a <copyin+0x28>
    8000175a:	84ce                	mv	s1,s3
    8000175c:	bf7d                	j	8000171a <copyin+0x28>
  }
  return 0;
    8000175e:	4501                	li	a0,0
    80001760:	a021                	j	80001768 <copyin+0x76>
    80001762:	4501                	li	a0,0
}
    80001764:	8082                	ret
      return -1;
    80001766:	557d                	li	a0,-1
}
    80001768:	60a6                	ld	ra,72(sp)
    8000176a:	6406                	ld	s0,64(sp)
    8000176c:	74e2                	ld	s1,56(sp)
    8000176e:	7942                	ld	s2,48(sp)
    80001770:	79a2                	ld	s3,40(sp)
    80001772:	7a02                	ld	s4,32(sp)
    80001774:	6ae2                	ld	s5,24(sp)
    80001776:	6b42                	ld	s6,16(sp)
    80001778:	6ba2                	ld	s7,8(sp)
    8000177a:	6c02                	ld	s8,0(sp)
    8000177c:	6161                	addi	sp,sp,80
    8000177e:	8082                	ret

0000000080001780 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001780:	c2dd                	beqz	a3,80001826 <copyinstr+0xa6>
{
    80001782:	715d                	addi	sp,sp,-80
    80001784:	e486                	sd	ra,72(sp)
    80001786:	e0a2                	sd	s0,64(sp)
    80001788:	fc26                	sd	s1,56(sp)
    8000178a:	f84a                	sd	s2,48(sp)
    8000178c:	f44e                	sd	s3,40(sp)
    8000178e:	f052                	sd	s4,32(sp)
    80001790:	ec56                	sd	s5,24(sp)
    80001792:	e85a                	sd	s6,16(sp)
    80001794:	e45e                	sd	s7,8(sp)
    80001796:	0880                	addi	s0,sp,80
    80001798:	8a2a                	mv	s4,a0
    8000179a:	8b2e                	mv	s6,a1
    8000179c:	8bb2                	mv	s7,a2
    8000179e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a2:	6985                	lui	s3,0x1
    800017a4:	a02d                	j	800017ce <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017aa:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ac:	37fd                	addiw	a5,a5,-1
    800017ae:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b2:	60a6                	ld	ra,72(sp)
    800017b4:	6406                	ld	s0,64(sp)
    800017b6:	74e2                	ld	s1,56(sp)
    800017b8:	7942                	ld	s2,48(sp)
    800017ba:	79a2                	ld	s3,40(sp)
    800017bc:	7a02                	ld	s4,32(sp)
    800017be:	6ae2                	ld	s5,24(sp)
    800017c0:	6b42                	ld	s6,16(sp)
    800017c2:	6ba2                	ld	s7,8(sp)
    800017c4:	6161                	addi	sp,sp,80
    800017c6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017cc:	c8a9                	beqz	s1,8000181e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ce:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d2:	85ca                	mv	a1,s2
    800017d4:	8552                	mv	a0,s4
    800017d6:	00000097          	auipc	ra,0x0
    800017da:	880080e7          	jalr	-1920(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800017de:	c131                	beqz	a0,80001822 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e0:	417906b3          	sub	a3,s2,s7
    800017e4:	96ce                	add	a3,a3,s3
    800017e6:	00d4f363          	bgeu	s1,a3,800017ec <copyinstr+0x6c>
    800017ea:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ec:	955e                	add	a0,a0,s7
    800017ee:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f2:	daf9                	beqz	a3,800017c8 <copyinstr+0x48>
    800017f4:	87da                	mv	a5,s6
    800017f6:	885a                	mv	a6,s6
      if(*p == '\0'){
    800017f8:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800017fc:	96da                	add	a3,a3,s6
    800017fe:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001800:	00f60733          	add	a4,a2,a5
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc880>
    80001808:	df59                	beqz	a4,800017a6 <copyinstr+0x26>
        *dst = *p;
    8000180a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000180e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001810:	fed797e3          	bne	a5,a3,800017fe <copyinstr+0x7e>
    80001814:	14fd                	addi	s1,s1,-1
    80001816:	94c2                	add	s1,s1,a6
      --max;
    80001818:	8c8d                	sub	s1,s1,a1
      dst++;
    8000181a:	8b3e                	mv	s6,a5
    8000181c:	b775                	j	800017c8 <copyinstr+0x48>
    8000181e:	4781                	li	a5,0
    80001820:	b771                	j	800017ac <copyinstr+0x2c>
      return -1;
    80001822:	557d                	li	a0,-1
    80001824:	b779                	j	800017b2 <copyinstr+0x32>
  int got_null = 0;
    80001826:	4781                	li	a5,0
  if(got_null){
    80001828:	37fd                	addiw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
}
    8000182e:	8082                	ret

0000000080001830 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001830:	7139                	addi	sp,sp,-64
    80001832:	fc06                	sd	ra,56(sp)
    80001834:	f822                	sd	s0,48(sp)
    80001836:	f426                	sd	s1,40(sp)
    80001838:	f04a                	sd	s2,32(sp)
    8000183a:	ec4e                	sd	s3,24(sp)
    8000183c:	e852                	sd	s4,16(sp)
    8000183e:	e456                	sd	s5,8(sp)
    80001840:	e05a                	sd	s6,0(sp)
    80001842:	0080                	addi	s0,sp,64
    80001844:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001846:	0000f497          	auipc	s1,0xf
    8000184a:	75a48493          	addi	s1,s1,1882 # 80010fa0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000184e:	8b26                	mv	s6,s1
    80001850:	00006a97          	auipc	s5,0x6
    80001854:	7b0a8a93          	addi	s5,s5,1968 # 80008000 <etext>
    80001858:	04000937          	lui	s2,0x4000
    8000185c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000185e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001860:	00016a17          	auipc	s4,0x16
    80001864:	b40a0a13          	addi	s4,s4,-1216 # 800173a0 <tickslock>
    char *pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	27a080e7          	jalr	634(ra) # 80000ae2 <kalloc>
    80001870:	862a                	mv	a2,a0
    if (pa == 0)
    80001872:	c131                	beqz	a0,800018b6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001874:	416485b3          	sub	a1,s1,s6
    80001878:	8591                	srai	a1,a1,0x4
    8000187a:	000ab783          	ld	a5,0(s5)
    8000187e:	02f585b3          	mul	a1,a1,a5
    80001882:	2585                	addiw	a1,a1,1
    80001884:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001888:	4719                	li	a4,6
    8000188a:	6685                	lui	a3,0x1
    8000188c:	40b905b3          	sub	a1,s2,a1
    80001890:	854e                	mv	a0,s3
    80001892:	00000097          	auipc	ra,0x0
    80001896:	8a6080e7          	jalr	-1882(ra) # 80001138 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000189a:	19048493          	addi	s1,s1,400
    8000189e:	fd4495e3          	bne	s1,s4,80001868 <proc_mapstacks+0x38>
  }
}
    800018a2:	70e2                	ld	ra,56(sp)
    800018a4:	7442                	ld	s0,48(sp)
    800018a6:	74a2                	ld	s1,40(sp)
    800018a8:	7902                	ld	s2,32(sp)
    800018aa:	69e2                	ld	s3,24(sp)
    800018ac:	6a42                	ld	s4,16(sp)
    800018ae:	6aa2                	ld	s5,8(sp)
    800018b0:	6b02                	ld	s6,0(sp)
    800018b2:	6121                	addi	sp,sp,64
    800018b4:	8082                	ret
      panic("kalloc");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	92250513          	addi	a0,a0,-1758 # 800081d8 <digits+0x198>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c7e080e7          	jalr	-898(ra) # 8000053c <panic>

00000000800018c6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018c6:	7139                	addi	sp,sp,-64
    800018c8:	fc06                	sd	ra,56(sp)
    800018ca:	f822                	sd	s0,48(sp)
    800018cc:	f426                	sd	s1,40(sp)
    800018ce:	f04a                	sd	s2,32(sp)
    800018d0:	ec4e                	sd	s3,24(sp)
    800018d2:	e852                	sd	s4,16(sp)
    800018d4:	e456                	sd	s5,8(sp)
    800018d6:	e05a                	sd	s6,0(sp)
    800018d8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018da:	00007597          	auipc	a1,0x7
    800018de:	90658593          	addi	a1,a1,-1786 # 800081e0 <digits+0x1a0>
    800018e2:	0000f517          	auipc	a0,0xf
    800018e6:	28e50513          	addi	a0,a0,654 # 80010b70 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	addi	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	28e50513          	addi	a0,a0,654 # 80010b88 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000190a:	0000f497          	auipc	s1,0xf
    8000190e:	69648493          	addi	s1,s1,1686 # 80010fa0 <proc>
  {
    initlock(&p->lock, "proc");
    80001912:	00007b17          	auipc	s6,0x7
    80001916:	8e6b0b13          	addi	s6,s6,-1818 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000191a:	8aa6                	mv	s5,s1
    8000191c:	00006a17          	auipc	s4,0x6
    80001920:	6e4a0a13          	addi	s4,s4,1764 # 80008000 <etext>
    80001924:	04000937          	lui	s2,0x4000
    80001928:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000192a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000192c:	00016997          	auipc	s3,0x16
    80001930:	a7498993          	addi	s3,s3,-1420 # 800173a0 <tickslock>
    initlock(&p->lock, "proc");
    80001934:	85da                	mv	a1,s6
    80001936:	8526                	mv	a0,s1
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20a080e7          	jalr	522(ra) # 80000b42 <initlock>
    p->state = UNUSED;
    80001940:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	8791                	srai	a5,a5,0x4
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addiw	a5,a5,1
    80001954:	00d7979b          	slliw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000195e:	19048493          	addi	s1,s1,400
    80001962:	fd3499e3          	bne	s1,s3,80001934 <procinit+0x6e>
  }
}
    80001966:	70e2                	ld	ra,56(sp)
    80001968:	7442                	ld	s0,48(sp)
    8000196a:	74a2                	ld	s1,40(sp)
    8000196c:	7902                	ld	s2,32(sp)
    8000196e:	69e2                	ld	s3,24(sp)
    80001970:	6a42                	ld	s4,16(sp)
    80001972:	6aa2                	ld	s5,8(sp)
    80001974:	6b02                	ld	s6,0(sp)
    80001976:	6121                	addi	sp,sp,64
    80001978:	8082                	ret

000000008000197a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001980:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001982:	2501                	sext.w	a0,a0
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	addi	sp,sp,16
    80001988:	8082                	ret

000000008000198a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	addi	s0,sp,16
    80001990:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
  return c;
}
    80001996:	0000f517          	auipc	a0,0xf
    8000199a:	20a50513          	addi	a0,a0,522 # 80010ba0 <cpus>
    8000199e:	953e                	add	a0,a0,a5
    800019a0:	6422                	ld	s0,8(sp)
    800019a2:	0141                	addi	sp,sp,16
    800019a4:	8082                	ret

00000000800019a6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019a6:	1101                	addi	sp,sp,-32
    800019a8:	ec06                	sd	ra,24(sp)
    800019aa:	e822                	sd	s0,16(sp)
    800019ac:	e426                	sd	s1,8(sp)
    800019ae:	1000                	addi	s0,sp,32
  push_off();
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	1d6080e7          	jalr	470(ra) # 80000b86 <push_off>
    800019b8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
    800019be:	0000f717          	auipc	a4,0xf
    800019c2:	1b270713          	addi	a4,a4,434 # 80010b70 <pid_lock>
    800019c6:	97ba                	add	a5,a5,a4
    800019c8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	25c080e7          	jalr	604(ra) # 80000c26 <pop_off>
  return p;
}
    800019d2:	8526                	mv	a0,s1
    800019d4:	60e2                	ld	ra,24(sp)
    800019d6:	6442                	ld	s0,16(sp)
    800019d8:	64a2                	ld	s1,8(sp)
    800019da:	6105                	addi	sp,sp,32
    800019dc:	8082                	ret

00000000800019de <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019de:	1141                	addi	sp,sp,-16
    800019e0:	e406                	sd	ra,8(sp)
    800019e2:	e022                	sd	s0,0(sp)
    800019e4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	fc0080e7          	jalr	-64(ra) # 800019a6 <myproc>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	298080e7          	jalr	664(ra) # 80000c86 <release>

  if (first)
    800019f6:	00007797          	auipc	a5,0x7
    800019fa:	e6a7a783          	lw	a5,-406(a5) # 80008860 <first.1>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	ebc080e7          	jalr	-324(ra) # 800028bc <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	addi	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	e407a823          	sw	zero,-432(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	da8080e7          	jalr	-600(ra) # 800037c2 <fsinit>
    80001a22:	bff9                	j	80001a00 <forkret+0x22>

0000000080001a24 <allocpid>:
{
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	e04a                	sd	s2,0(sp)
    80001a2e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a30:	0000f917          	auipc	s2,0xf
    80001a34:	14090913          	addi	s2,s2,320 # 80010b70 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	e2278793          	addi	a5,a5,-478 # 80008864 <nextpid>
    80001a4a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4c:	0014871b          	addiw	a4,s1,1
    80001a50:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	232080e7          	jalr	562(ra) # 80000c86 <release>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6902                	ld	s2,0(sp)
    80001a66:	6105                	addi	sp,sp,32
    80001a68:	8082                	ret

0000000080001a6a <sys_sigalarm>:
uint64 sys_sigalarm(void){
    80001a6a:	1101                	addi	sp,sp,-32
    80001a6c:	ec06                	sd	ra,24(sp)
    80001a6e:	e822                	sd	s0,16(sp)
    80001a70:	1000                	addi	s0,sp,32
  argint(0, &ticks);
    80001a72:	fec40593          	addi	a1,s0,-20
    80001a76:	4501                	li	a0,0
    80001a78:	00001097          	auipc	ra,0x1
    80001a7c:	328080e7          	jalr	808(ra) # 80002da0 <argint>
  argaddr(1, &handler) ;
    80001a80:	fe040593          	addi	a1,s0,-32
    80001a84:	4505                	li	a0,1
    80001a86:	00001097          	auipc	ra,0x1
    80001a8a:	33a080e7          	jalr	826(ra) # 80002dc0 <argaddr>
  myproc()->is_sigalarm =0;
    80001a8e:	00000097          	auipc	ra,0x0
    80001a92:	f18080e7          	jalr	-232(ra) # 800019a6 <myproc>
    80001a96:	16052a23          	sw	zero,372(a0)
  myproc()->ticks = ticks;
    80001a9a:	00000097          	auipc	ra,0x0
    80001a9e:	f0c080e7          	jalr	-244(ra) # 800019a6 <myproc>
    80001aa2:	fec42783          	lw	a5,-20(s0)
    80001aa6:	16f52c23          	sw	a5,376(a0)
  myproc()->now_ticks = 0;
    80001aaa:	00000097          	auipc	ra,0x0
    80001aae:	efc080e7          	jalr	-260(ra) # 800019a6 <myproc>
    80001ab2:	16052e23          	sw	zero,380(a0)
  myproc()->handler = handler;
    80001ab6:	00000097          	auipc	ra,0x0
    80001aba:	ef0080e7          	jalr	-272(ra) # 800019a6 <myproc>
    80001abe:	fe043783          	ld	a5,-32(s0)
    80001ac2:	18f53023          	sd	a5,384(a0)
}
    80001ac6:	4501                	li	a0,0
    80001ac8:	60e2                	ld	ra,24(sp)
    80001aca:	6442                	ld	s0,16(sp)
    80001acc:	6105                	addi	sp,sp,32
    80001ace:	8082                	ret

0000000080001ad0 <proc_pagetable>:
{
    80001ad0:	1101                	addi	sp,sp,-32
    80001ad2:	ec06                	sd	ra,24(sp)
    80001ad4:	e822                	sd	s0,16(sp)
    80001ad6:	e426                	sd	s1,8(sp)
    80001ad8:	e04a                	sd	s2,0(sp)
    80001ada:	1000                	addi	s0,sp,32
    80001adc:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	844080e7          	jalr	-1980(ra) # 80001322 <uvmcreate>
    80001ae6:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001ae8:	c121                	beqz	a0,80001b28 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aea:	4729                	li	a4,10
    80001aec:	00005697          	auipc	a3,0x5
    80001af0:	51468693          	addi	a3,a3,1300 # 80007000 <_trampoline>
    80001af4:	6605                	lui	a2,0x1
    80001af6:	040005b7          	lui	a1,0x4000
    80001afa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001afc:	05b2                	slli	a1,a1,0xc
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	59a080e7          	jalr	1434(ra) # 80001098 <mappages>
    80001b06:	02054863          	bltz	a0,80001b36 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b0a:	4719                	li	a4,6
    80001b0c:	05893683          	ld	a3,88(s2)
    80001b10:	6605                	lui	a2,0x1
    80001b12:	020005b7          	lui	a1,0x2000
    80001b16:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b18:	05b6                	slli	a1,a1,0xd
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	57c080e7          	jalr	1404(ra) # 80001098 <mappages>
    80001b24:	02054163          	bltz	a0,80001b46 <proc_pagetable+0x76>
}
    80001b28:	8526                	mv	a0,s1
    80001b2a:	60e2                	ld	ra,24(sp)
    80001b2c:	6442                	ld	s0,16(sp)
    80001b2e:	64a2                	ld	s1,8(sp)
    80001b30:	6902                	ld	s2,0(sp)
    80001b32:	6105                	addi	sp,sp,32
    80001b34:	8082                	ret
    uvmfree(pagetable, 0);
    80001b36:	4581                	li	a1,0
    80001b38:	8526                	mv	a0,s1
    80001b3a:	00000097          	auipc	ra,0x0
    80001b3e:	9ee080e7          	jalr	-1554(ra) # 80001528 <uvmfree>
    return 0;
    80001b42:	4481                	li	s1,0
    80001b44:	b7d5                	j	80001b28 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b46:	4681                	li	a3,0
    80001b48:	4605                	li	a2,1
    80001b4a:	040005b7          	lui	a1,0x4000
    80001b4e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b50:	05b2                	slli	a1,a1,0xc
    80001b52:	8526                	mv	a0,s1
    80001b54:	fffff097          	auipc	ra,0xfffff
    80001b58:	70a080e7          	jalr	1802(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b5c:	4581                	li	a1,0
    80001b5e:	8526                	mv	a0,s1
    80001b60:	00000097          	auipc	ra,0x0
    80001b64:	9c8080e7          	jalr	-1592(ra) # 80001528 <uvmfree>
    return 0;
    80001b68:	4481                	li	s1,0
    80001b6a:	bf7d                	j	80001b28 <proc_pagetable+0x58>

0000000080001b6c <proc_freepagetable>:
{
    80001b6c:	1101                	addi	sp,sp,-32
    80001b6e:	ec06                	sd	ra,24(sp)
    80001b70:	e822                	sd	s0,16(sp)
    80001b72:	e426                	sd	s1,8(sp)
    80001b74:	e04a                	sd	s2,0(sp)
    80001b76:	1000                	addi	s0,sp,32
    80001b78:	84aa                	mv	s1,a0
    80001b7a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7c:	4681                	li	a3,0
    80001b7e:	4605                	li	a2,1
    80001b80:	040005b7          	lui	a1,0x4000
    80001b84:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b86:	05b2                	slli	a1,a1,0xc
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	6d6080e7          	jalr	1750(ra) # 8000125e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b90:	4681                	li	a3,0
    80001b92:	4605                	li	a2,1
    80001b94:	020005b7          	lui	a1,0x2000
    80001b98:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b9a:	05b6                	slli	a1,a1,0xd
    80001b9c:	8526                	mv	a0,s1
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	6c0080e7          	jalr	1728(ra) # 8000125e <uvmunmap>
  uvmfree(pagetable, sz);
    80001ba6:	85ca                	mv	a1,s2
    80001ba8:	8526                	mv	a0,s1
    80001baa:	00000097          	auipc	ra,0x0
    80001bae:	97e080e7          	jalr	-1666(ra) # 80001528 <uvmfree>
}
    80001bb2:	60e2                	ld	ra,24(sp)
    80001bb4:	6442                	ld	s0,16(sp)
    80001bb6:	64a2                	ld	s1,8(sp)
    80001bb8:	6902                	ld	s2,0(sp)
    80001bba:	6105                	addi	sp,sp,32
    80001bbc:	8082                	ret

0000000080001bbe <freeproc>:
{
    80001bbe:	1101                	addi	sp,sp,-32
    80001bc0:	ec06                	sd	ra,24(sp)
    80001bc2:	e822                	sd	s0,16(sp)
    80001bc4:	e426                	sd	s1,8(sp)
    80001bc6:	1000                	addi	s0,sp,32
    80001bc8:	84aa                	mv	s1,a0
  if (p->backup_trapframe)
    80001bca:	18853503          	ld	a0,392(a0)
    80001bce:	c509                	beqz	a0,80001bd8 <freeproc+0x1a>
    kfree((void *)p->backup_trapframe);
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	e14080e7          	jalr	-492(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001bd8:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001bdc:	68a8                	ld	a0,80(s1)
    80001bde:	c511                	beqz	a0,80001bea <freeproc+0x2c>
    proc_freepagetable(p->pagetable, p->sz);
    80001be0:	64ac                	ld	a1,72(s1)
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	f8a080e7          	jalr	-118(ra) # 80001b6c <proc_freepagetable>
  p->pagetable = 0;
    80001bea:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bee:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bf2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bf6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bfa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bfe:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c02:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c06:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c0a:	0004ac23          	sw	zero,24(s1)
}
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6105                	addi	sp,sp,32
    80001c16:	8082                	ret

0000000080001c18 <allocproc>:
{
    80001c18:	1101                	addi	sp,sp,-32
    80001c1a:	ec06                	sd	ra,24(sp)
    80001c1c:	e822                	sd	s0,16(sp)
    80001c1e:	e426                	sd	s1,8(sp)
    80001c20:	e04a                	sd	s2,0(sp)
    80001c22:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c24:	0000f497          	auipc	s1,0xf
    80001c28:	37c48493          	addi	s1,s1,892 # 80010fa0 <proc>
    80001c2c:	00015917          	auipc	s2,0x15
    80001c30:	77490913          	addi	s2,s2,1908 # 800173a0 <tickslock>
    acquire(&p->lock);
    80001c34:	8526                	mv	a0,s1
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	f9c080e7          	jalr	-100(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001c3e:	4c9c                	lw	a5,24(s1)
    80001c40:	cf81                	beqz	a5,80001c58 <allocproc+0x40>
      release(&p->lock);
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	042080e7          	jalr	66(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c4c:	19048493          	addi	s1,s1,400
    80001c50:	ff2492e3          	bne	s1,s2,80001c34 <allocproc+0x1c>
  return 0;
    80001c54:	4481                	li	s1,0
    80001c56:	a059                	j	80001cdc <allocproc+0xc4>
  p->pid = allocpid();
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	dcc080e7          	jalr	-564(ra) # 80001a24 <allocpid>
    80001c60:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c62:	4785                	li	a5,1
    80001c64:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	e7c080e7          	jalr	-388(ra) # 80000ae2 <kalloc>
    80001c6e:	892a                	mv	s2,a0
    80001c70:	eca8                	sd	a0,88(s1)
    80001c72:	cd25                	beqz	a0,80001cea <allocproc+0xd2>
  if((p->backup_trapframe = (struct trapframe *)kalloc()) == 0){
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	e6e080e7          	jalr	-402(ra) # 80000ae2 <kalloc>
    80001c7c:	892a                	mv	s2,a0
    80001c7e:	18a4b423          	sd	a0,392(s1)
    80001c82:	c141                	beqz	a0,80001d02 <allocproc+0xea>
  p->pagetable = proc_pagetable(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	e4a080e7          	jalr	-438(ra) # 80001ad0 <proc_pagetable>
    80001c8e:	892a                	mv	s2,a0
    80001c90:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c92:	cd3d                	beqz	a0,80001d10 <allocproc+0xf8>
  memset(&p->context, 0, sizeof(p->context));
    80001c94:	07000613          	li	a2,112
    80001c98:	4581                	li	a1,0
    80001c9a:	06048513          	addi	a0,s1,96
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	030080e7          	jalr	48(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001ca6:	00000797          	auipc	a5,0x0
    80001caa:	d3878793          	addi	a5,a5,-712 # 800019de <forkret>
    80001cae:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cb0:	60bc                	ld	a5,64(s1)
    80001cb2:	6705                	lui	a4,0x1
    80001cb4:	97ba                	add	a5,a5,a4
    80001cb6:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001cb8:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001cbc:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001cc0:	00007797          	auipc	a5,0x7
    80001cc4:	c407a783          	lw	a5,-960(a5) # 80008900 <ticks>
    80001cc8:	16f4a623          	sw	a5,364(s1)
  p->is_sigalarm = 0;
    80001ccc:	1604aa23          	sw	zero,372(s1)
  p->ticks = 0;
    80001cd0:	1604ac23          	sw	zero,376(s1)
  p->now_ticks = 0;
    80001cd4:	1604ae23          	sw	zero,380(s1)
  p->handler = 0;
    80001cd8:	1804b023          	sd	zero,384(s1)
}
    80001cdc:	8526                	mv	a0,s1
    80001cde:	60e2                	ld	ra,24(sp)
    80001ce0:	6442                	ld	s0,16(sp)
    80001ce2:	64a2                	ld	s1,8(sp)
    80001ce4:	6902                	ld	s2,0(sp)
    80001ce6:	6105                	addi	sp,sp,32
    80001ce8:	8082                	ret
    freeproc(p);
    80001cea:	8526                	mv	a0,s1
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	ed2080e7          	jalr	-302(ra) # 80001bbe <freeproc>
    release(&p->lock);
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	f90080e7          	jalr	-112(ra) # 80000c86 <release>
    return 0;
    80001cfe:	84ca                	mv	s1,s2
    80001d00:	bff1                	j	80001cdc <allocproc+0xc4>
    release(&p->lock);
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	f82080e7          	jalr	-126(ra) # 80000c86 <release>
    return 0;
    80001d0c:	84ca                	mv	s1,s2
    80001d0e:	b7f9                	j	80001cdc <allocproc+0xc4>
    freeproc(p);
    80001d10:	8526                	mv	a0,s1
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	eac080e7          	jalr	-340(ra) # 80001bbe <freeproc>
    release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f6a080e7          	jalr	-150(ra) # 80000c86 <release>
    return 0;
    80001d24:	84ca                	mv	s1,s2
    80001d26:	bf5d                	j	80001cdc <allocproc+0xc4>

0000000080001d28 <userinit>:
{
    80001d28:	1101                	addi	sp,sp,-32
    80001d2a:	ec06                	sd	ra,24(sp)
    80001d2c:	e822                	sd	s0,16(sp)
    80001d2e:	e426                	sd	s1,8(sp)
    80001d30:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	ee6080e7          	jalr	-282(ra) # 80001c18 <allocproc>
    80001d3a:	84aa                	mv	s1,a0
  initproc = p;
    80001d3c:	00007797          	auipc	a5,0x7
    80001d40:	baa7be23          	sd	a0,-1092(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d44:	03400613          	li	a2,52
    80001d48:	00007597          	auipc	a1,0x7
    80001d4c:	b2858593          	addi	a1,a1,-1240 # 80008870 <initcode>
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	5fe080e7          	jalr	1534(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001d5a:	6785                	lui	a5,0x1
    80001d5c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d5e:	6cb8                	ld	a4,88(s1)
    80001d60:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d64:	6cb8                	ld	a4,88(s1)
    80001d66:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d68:	4641                	li	a2,16
    80001d6a:	00006597          	auipc	a1,0x6
    80001d6e:	49658593          	addi	a1,a1,1174 # 80008200 <digits+0x1c0>
    80001d72:	15848513          	addi	a0,s1,344
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	0a0080e7          	jalr	160(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d7e:	00006517          	auipc	a0,0x6
    80001d82:	49250513          	addi	a0,a0,1170 # 80008210 <digits+0x1d0>
    80001d86:	00002097          	auipc	ra,0x2
    80001d8a:	45a080e7          	jalr	1114(ra) # 800041e0 <namei>
    80001d8e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d92:	478d                	li	a5,3
    80001d94:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d96:	8526                	mv	a0,s1
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	eee080e7          	jalr	-274(ra) # 80000c86 <release>
}
    80001da0:	60e2                	ld	ra,24(sp)
    80001da2:	6442                	ld	s0,16(sp)
    80001da4:	64a2                	ld	s1,8(sp)
    80001da6:	6105                	addi	sp,sp,32
    80001da8:	8082                	ret

0000000080001daa <growproc>:
{
    80001daa:	1101                	addi	sp,sp,-32
    80001dac:	ec06                	sd	ra,24(sp)
    80001dae:	e822                	sd	s0,16(sp)
    80001db0:	e426                	sd	s1,8(sp)
    80001db2:	e04a                	sd	s2,0(sp)
    80001db4:	1000                	addi	s0,sp,32
    80001db6:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	bee080e7          	jalr	-1042(ra) # 800019a6 <myproc>
    80001dc0:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dc2:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001dc4:	01204c63          	bgtz	s2,80001ddc <growproc+0x32>
  else if (n < 0)
    80001dc8:	02094663          	bltz	s2,80001df4 <growproc+0x4a>
  p->sz = sz;
    80001dcc:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dce:	4501                	li	a0,0
}
    80001dd0:	60e2                	ld	ra,24(sp)
    80001dd2:	6442                	ld	s0,16(sp)
    80001dd4:	64a2                	ld	s1,8(sp)
    80001dd6:	6902                	ld	s2,0(sp)
    80001dd8:	6105                	addi	sp,sp,32
    80001dda:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001ddc:	4691                	li	a3,4
    80001dde:	00b90633          	add	a2,s2,a1
    80001de2:	6928                	ld	a0,80(a0)
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	626080e7          	jalr	1574(ra) # 8000140a <uvmalloc>
    80001dec:	85aa                	mv	a1,a0
    80001dee:	fd79                	bnez	a0,80001dcc <growproc+0x22>
      return -1;
    80001df0:	557d                	li	a0,-1
    80001df2:	bff9                	j	80001dd0 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df4:	00b90633          	add	a2,s2,a1
    80001df8:	6928                	ld	a0,80(a0)
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	5c8080e7          	jalr	1480(ra) # 800013c2 <uvmdealloc>
    80001e02:	85aa                	mv	a1,a0
    80001e04:	b7e1                	j	80001dcc <growproc+0x22>

0000000080001e06 <fork>:
{
    80001e06:	7139                	addi	sp,sp,-64
    80001e08:	fc06                	sd	ra,56(sp)
    80001e0a:	f822                	sd	s0,48(sp)
    80001e0c:	f426                	sd	s1,40(sp)
    80001e0e:	f04a                	sd	s2,32(sp)
    80001e10:	ec4e                	sd	s3,24(sp)
    80001e12:	e852                	sd	s4,16(sp)
    80001e14:	e456                	sd	s5,8(sp)
    80001e16:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	b8e080e7          	jalr	-1138(ra) # 800019a6 <myproc>
    80001e20:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	df6080e7          	jalr	-522(ra) # 80001c18 <allocproc>
    80001e2a:	10050c63          	beqz	a0,80001f42 <fork+0x13c>
    80001e2e:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e30:	048ab603          	ld	a2,72(s5)
    80001e34:	692c                	ld	a1,80(a0)
    80001e36:	050ab503          	ld	a0,80(s5)
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	728080e7          	jalr	1832(ra) # 80001562 <uvmcopy>
    80001e42:	04054863          	bltz	a0,80001e92 <fork+0x8c>
  np->sz = p->sz;
    80001e46:	048ab783          	ld	a5,72(s5)
    80001e4a:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e4e:	058ab683          	ld	a3,88(s5)
    80001e52:	87b6                	mv	a5,a3
    80001e54:	058a3703          	ld	a4,88(s4)
    80001e58:	12068693          	addi	a3,a3,288
    80001e5c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e60:	6788                	ld	a0,8(a5)
    80001e62:	6b8c                	ld	a1,16(a5)
    80001e64:	6f90                	ld	a2,24(a5)
    80001e66:	01073023          	sd	a6,0(a4)
    80001e6a:	e708                	sd	a0,8(a4)
    80001e6c:	eb0c                	sd	a1,16(a4)
    80001e6e:	ef10                	sd	a2,24(a4)
    80001e70:	02078793          	addi	a5,a5,32
    80001e74:	02070713          	addi	a4,a4,32
    80001e78:	fed792e3          	bne	a5,a3,80001e5c <fork+0x56>
  np->trapframe->a0 = 0;
    80001e7c:	058a3783          	ld	a5,88(s4)
    80001e80:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e84:	0d0a8493          	addi	s1,s5,208
    80001e88:	0d0a0913          	addi	s2,s4,208
    80001e8c:	150a8993          	addi	s3,s5,336
    80001e90:	a00d                	j	80001eb2 <fork+0xac>
    freeproc(np);
    80001e92:	8552                	mv	a0,s4
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	d2a080e7          	jalr	-726(ra) # 80001bbe <freeproc>
    release(&np->lock);
    80001e9c:	8552                	mv	a0,s4
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	de8080e7          	jalr	-536(ra) # 80000c86 <release>
    return -1;
    80001ea6:	597d                	li	s2,-1
    80001ea8:	a059                	j	80001f2e <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001eaa:	04a1                	addi	s1,s1,8
    80001eac:	0921                	addi	s2,s2,8
    80001eae:	01348b63          	beq	s1,s3,80001ec4 <fork+0xbe>
    if (p->ofile[i])
    80001eb2:	6088                	ld	a0,0(s1)
    80001eb4:	d97d                	beqz	a0,80001eaa <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb6:	00003097          	auipc	ra,0x3
    80001eba:	99c080e7          	jalr	-1636(ra) # 80004852 <filedup>
    80001ebe:	00a93023          	sd	a0,0(s2)
    80001ec2:	b7e5                	j	80001eaa <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ec4:	150ab503          	ld	a0,336(s5)
    80001ec8:	00002097          	auipc	ra,0x2
    80001ecc:	b34080e7          	jalr	-1228(ra) # 800039fc <idup>
    80001ed0:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed4:	4641                	li	a2,16
    80001ed6:	158a8593          	addi	a1,s5,344
    80001eda:	158a0513          	addi	a0,s4,344
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	f38080e7          	jalr	-200(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001ee6:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eea:	8552                	mv	a0,s4
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	d9a080e7          	jalr	-614(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001ef4:	0000f497          	auipc	s1,0xf
    80001ef8:	c9448493          	addi	s1,s1,-876 # 80010b88 <wait_lock>
    80001efc:	8526                	mv	a0,s1
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	cd4080e7          	jalr	-812(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001f06:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	d7a080e7          	jalr	-646(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001f14:	8552                	mv	a0,s4
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	cbc080e7          	jalr	-836(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001f1e:	478d                	li	a5,3
    80001f20:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f24:	8552                	mv	a0,s4
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	d60080e7          	jalr	-672(ra) # 80000c86 <release>
}
    80001f2e:	854a                	mv	a0,s2
    80001f30:	70e2                	ld	ra,56(sp)
    80001f32:	7442                	ld	s0,48(sp)
    80001f34:	74a2                	ld	s1,40(sp)
    80001f36:	7902                	ld	s2,32(sp)
    80001f38:	69e2                	ld	s3,24(sp)
    80001f3a:	6a42                	ld	s4,16(sp)
    80001f3c:	6aa2                	ld	s5,8(sp)
    80001f3e:	6121                	addi	sp,sp,64
    80001f40:	8082                	ret
    return -1;
    80001f42:	597d                	li	s2,-1
    80001f44:	b7ed                	j	80001f2e <fork+0x128>

0000000080001f46 <scheduler>:
{
    80001f46:	7139                	addi	sp,sp,-64
    80001f48:	fc06                	sd	ra,56(sp)
    80001f4a:	f822                	sd	s0,48(sp)
    80001f4c:	f426                	sd	s1,40(sp)
    80001f4e:	f04a                	sd	s2,32(sp)
    80001f50:	ec4e                	sd	s3,24(sp)
    80001f52:	e852                	sd	s4,16(sp)
    80001f54:	e456                	sd	s5,8(sp)
    80001f56:	e05a                	sd	s6,0(sp)
    80001f58:	0080                	addi	s0,sp,64
    80001f5a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f5e:	00779a93          	slli	s5,a5,0x7
    80001f62:	0000f717          	auipc	a4,0xf
    80001f66:	c0e70713          	addi	a4,a4,-1010 # 80010b70 <pid_lock>
    80001f6a:	9756                	add	a4,a4,s5
    80001f6c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f70:	0000f717          	auipc	a4,0xf
    80001f74:	c3870713          	addi	a4,a4,-968 # 80010ba8 <cpus+0x8>
    80001f78:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f7a:	498d                	li	s3,3
        p->state = RUNNING;
    80001f7c:	4b11                	li	s6,4
        c->proc = p;
    80001f7e:	079e                	slli	a5,a5,0x7
    80001f80:	0000fa17          	auipc	s4,0xf
    80001f84:	bf0a0a13          	addi	s4,s4,-1040 # 80010b70 <pid_lock>
    80001f88:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f8a:	00015917          	auipc	s2,0x15
    80001f8e:	41690913          	addi	s2,s2,1046 # 800173a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f96:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9a:	10079073          	csrw	sstatus,a5
    80001f9e:	0000f497          	auipc	s1,0xf
    80001fa2:	00248493          	addi	s1,s1,2 # 80010fa0 <proc>
    80001fa6:	a811                	j	80001fba <scheduler+0x74>
      release(&p->lock);
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	cdc080e7          	jalr	-804(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fb2:	19048493          	addi	s1,s1,400
    80001fb6:	fd248ee3          	beq	s1,s2,80001f92 <scheduler+0x4c>
      acquire(&p->lock);
    80001fba:	8526                	mv	a0,s1
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	c16080e7          	jalr	-1002(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    80001fc4:	4c9c                	lw	a5,24(s1)
    80001fc6:	ff3791e3          	bne	a5,s3,80001fa8 <scheduler+0x62>
        p->state = RUNNING;
    80001fca:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fce:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fd2:	06048593          	addi	a1,s1,96
    80001fd6:	8556                	mv	a0,s5
    80001fd8:	00001097          	auipc	ra,0x1
    80001fdc:	83a080e7          	jalr	-1990(ra) # 80002812 <swtch>
        c->proc = 0;
    80001fe0:	020a3823          	sd	zero,48(s4)
    80001fe4:	b7d1                	j	80001fa8 <scheduler+0x62>

0000000080001fe6 <sched>:
{
    80001fe6:	7179                	addi	sp,sp,-48
    80001fe8:	f406                	sd	ra,40(sp)
    80001fea:	f022                	sd	s0,32(sp)
    80001fec:	ec26                	sd	s1,24(sp)
    80001fee:	e84a                	sd	s2,16(sp)
    80001ff0:	e44e                	sd	s3,8(sp)
    80001ff2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	9b2080e7          	jalr	-1614(ra) # 800019a6 <myproc>
    80001ffc:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	b5a080e7          	jalr	-1190(ra) # 80000b58 <holding>
    80002006:	c93d                	beqz	a0,8000207c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002008:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000200a:	2781                	sext.w	a5,a5
    8000200c:	079e                	slli	a5,a5,0x7
    8000200e:	0000f717          	auipc	a4,0xf
    80002012:	b6270713          	addi	a4,a4,-1182 # 80010b70 <pid_lock>
    80002016:	97ba                	add	a5,a5,a4
    80002018:	0a87a703          	lw	a4,168(a5)
    8000201c:	4785                	li	a5,1
    8000201e:	06f71763          	bne	a4,a5,8000208c <sched+0xa6>
  if (p->state == RUNNING)
    80002022:	4c98                	lw	a4,24(s1)
    80002024:	4791                	li	a5,4
    80002026:	06f70b63          	beq	a4,a5,8000209c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000202e:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002030:	efb5                	bnez	a5,800020ac <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002032:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002034:	0000f917          	auipc	s2,0xf
    80002038:	b3c90913          	addi	s2,s2,-1220 # 80010b70 <pid_lock>
    8000203c:	2781                	sext.w	a5,a5
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	97ca                	add	a5,a5,s2
    80002042:	0ac7a983          	lw	s3,172(a5)
    80002046:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002048:	2781                	sext.w	a5,a5
    8000204a:	079e                	slli	a5,a5,0x7
    8000204c:	0000f597          	auipc	a1,0xf
    80002050:	b5c58593          	addi	a1,a1,-1188 # 80010ba8 <cpus+0x8>
    80002054:	95be                	add	a1,a1,a5
    80002056:	06048513          	addi	a0,s1,96
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	7b8080e7          	jalr	1976(ra) # 80002812 <swtch>
    80002062:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002064:	2781                	sext.w	a5,a5
    80002066:	079e                	slli	a5,a5,0x7
    80002068:	993e                	add	s2,s2,a5
    8000206a:	0b392623          	sw	s3,172(s2)
}
    8000206e:	70a2                	ld	ra,40(sp)
    80002070:	7402                	ld	s0,32(sp)
    80002072:	64e2                	ld	s1,24(sp)
    80002074:	6942                	ld	s2,16(sp)
    80002076:	69a2                	ld	s3,8(sp)
    80002078:	6145                	addi	sp,sp,48
    8000207a:	8082                	ret
    panic("sched p->lock");
    8000207c:	00006517          	auipc	a0,0x6
    80002080:	19c50513          	addi	a0,a0,412 # 80008218 <digits+0x1d8>
    80002084:	ffffe097          	auipc	ra,0xffffe
    80002088:	4b8080e7          	jalr	1208(ra) # 8000053c <panic>
    panic("sched locks");
    8000208c:	00006517          	auipc	a0,0x6
    80002090:	19c50513          	addi	a0,a0,412 # 80008228 <digits+0x1e8>
    80002094:	ffffe097          	auipc	ra,0xffffe
    80002098:	4a8080e7          	jalr	1192(ra) # 8000053c <panic>
    panic("sched running");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	19c50513          	addi	a0,a0,412 # 80008238 <digits+0x1f8>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	498080e7          	jalr	1176(ra) # 8000053c <panic>
    panic("sched interruptible");
    800020ac:	00006517          	auipc	a0,0x6
    800020b0:	19c50513          	addi	a0,a0,412 # 80008248 <digits+0x208>
    800020b4:	ffffe097          	auipc	ra,0xffffe
    800020b8:	488080e7          	jalr	1160(ra) # 8000053c <panic>

00000000800020bc <yield>:
{
    800020bc:	1101                	addi	sp,sp,-32
    800020be:	ec06                	sd	ra,24(sp)
    800020c0:	e822                	sd	s0,16(sp)
    800020c2:	e426                	sd	s1,8(sp)
    800020c4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c6:	00000097          	auipc	ra,0x0
    800020ca:	8e0080e7          	jalr	-1824(ra) # 800019a6 <myproc>
    800020ce:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	b02080e7          	jalr	-1278(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    800020d8:	478d                	li	a5,3
    800020da:	cc9c                	sw	a5,24(s1)
  sched();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	f0a080e7          	jalr	-246(ra) # 80001fe6 <sched>
  release(&p->lock);
    800020e4:	8526                	mv	a0,s1
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	ba0080e7          	jalr	-1120(ra) # 80000c86 <release>
}
    800020ee:	60e2                	ld	ra,24(sp)
    800020f0:	6442                	ld	s0,16(sp)
    800020f2:	64a2                	ld	s1,8(sp)
    800020f4:	6105                	addi	sp,sp,32
    800020f6:	8082                	ret

00000000800020f8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020f8:	7179                	addi	sp,sp,-48
    800020fa:	f406                	sd	ra,40(sp)
    800020fc:	f022                	sd	s0,32(sp)
    800020fe:	ec26                	sd	s1,24(sp)
    80002100:	e84a                	sd	s2,16(sp)
    80002102:	e44e                	sd	s3,8(sp)
    80002104:	1800                	addi	s0,sp,48
    80002106:	89aa                	mv	s3,a0
    80002108:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000210a:	00000097          	auipc	ra,0x0
    8000210e:	89c080e7          	jalr	-1892(ra) # 800019a6 <myproc>
    80002112:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	abe080e7          	jalr	-1346(ra) # 80000bd2 <acquire>
  release(lk);
    8000211c:	854a                	mv	a0,s2
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	b68080e7          	jalr	-1176(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    80002126:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212a:	4789                	li	a5,2
    8000212c:	cc9c                	sw	a5,24(s1)

  sched();
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	eb8080e7          	jalr	-328(ra) # 80001fe6 <sched>

  // Tidy up.
  p->chan = 0;
    80002136:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b4a080e7          	jalr	-1206(ra) # 80000c86 <release>
  acquire(lk);
    80002144:	854a                	mv	a0,s2
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	a8c080e7          	jalr	-1396(ra) # 80000bd2 <acquire>
}
    8000214e:	70a2                	ld	ra,40(sp)
    80002150:	7402                	ld	s0,32(sp)
    80002152:	64e2                	ld	s1,24(sp)
    80002154:	6942                	ld	s2,16(sp)
    80002156:	69a2                	ld	s3,8(sp)
    80002158:	6145                	addi	sp,sp,48
    8000215a:	8082                	ret

000000008000215c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000215c:	7139                	addi	sp,sp,-64
    8000215e:	fc06                	sd	ra,56(sp)
    80002160:	f822                	sd	s0,48(sp)
    80002162:	f426                	sd	s1,40(sp)
    80002164:	f04a                	sd	s2,32(sp)
    80002166:	ec4e                	sd	s3,24(sp)
    80002168:	e852                	sd	s4,16(sp)
    8000216a:	e456                	sd	s5,8(sp)
    8000216c:	0080                	addi	s0,sp,64
    8000216e:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002170:	0000f497          	auipc	s1,0xf
    80002174:	e3048493          	addi	s1,s1,-464 # 80010fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002178:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000217a:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000217c:	00015917          	auipc	s2,0x15
    80002180:	22490913          	addi	s2,s2,548 # 800173a0 <tickslock>
    80002184:	a811                	j	80002198 <wakeup+0x3c>
      }
      release(&p->lock);
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	afe080e7          	jalr	-1282(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002190:	19048493          	addi	s1,s1,400
    80002194:	03248663          	beq	s1,s2,800021c0 <wakeup+0x64>
    if (p != myproc())
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	80e080e7          	jalr	-2034(ra) # 800019a6 <myproc>
    800021a0:	fea488e3          	beq	s1,a0,80002190 <wakeup+0x34>
      acquire(&p->lock);
    800021a4:	8526                	mv	a0,s1
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	a2c080e7          	jalr	-1492(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800021ae:	4c9c                	lw	a5,24(s1)
    800021b0:	fd379be3          	bne	a5,s3,80002186 <wakeup+0x2a>
    800021b4:	709c                	ld	a5,32(s1)
    800021b6:	fd4798e3          	bne	a5,s4,80002186 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021ba:	0154ac23          	sw	s5,24(s1)
    800021be:	b7e1                	j	80002186 <wakeup+0x2a>
    }
  }
}
    800021c0:	70e2                	ld	ra,56(sp)
    800021c2:	7442                	ld	s0,48(sp)
    800021c4:	74a2                	ld	s1,40(sp)
    800021c6:	7902                	ld	s2,32(sp)
    800021c8:	69e2                	ld	s3,24(sp)
    800021ca:	6a42                	ld	s4,16(sp)
    800021cc:	6aa2                	ld	s5,8(sp)
    800021ce:	6121                	addi	sp,sp,64
    800021d0:	8082                	ret

00000000800021d2 <reparent>:
{
    800021d2:	7179                	addi	sp,sp,-48
    800021d4:	f406                	sd	ra,40(sp)
    800021d6:	f022                	sd	s0,32(sp)
    800021d8:	ec26                	sd	s1,24(sp)
    800021da:	e84a                	sd	s2,16(sp)
    800021dc:	e44e                	sd	s3,8(sp)
    800021de:	e052                	sd	s4,0(sp)
    800021e0:	1800                	addi	s0,sp,48
    800021e2:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021e4:	0000f497          	auipc	s1,0xf
    800021e8:	dbc48493          	addi	s1,s1,-580 # 80010fa0 <proc>
      pp->parent = initproc;
    800021ec:	00006a17          	auipc	s4,0x6
    800021f0:	70ca0a13          	addi	s4,s4,1804 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021f4:	00015997          	auipc	s3,0x15
    800021f8:	1ac98993          	addi	s3,s3,428 # 800173a0 <tickslock>
    800021fc:	a029                	j	80002206 <reparent+0x34>
    800021fe:	19048493          	addi	s1,s1,400
    80002202:	01348d63          	beq	s1,s3,8000221c <reparent+0x4a>
    if (pp->parent == p)
    80002206:	7c9c                	ld	a5,56(s1)
    80002208:	ff279be3          	bne	a5,s2,800021fe <reparent+0x2c>
      pp->parent = initproc;
    8000220c:	000a3503          	ld	a0,0(s4)
    80002210:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002212:	00000097          	auipc	ra,0x0
    80002216:	f4a080e7          	jalr	-182(ra) # 8000215c <wakeup>
    8000221a:	b7d5                	j	800021fe <reparent+0x2c>
}
    8000221c:	70a2                	ld	ra,40(sp)
    8000221e:	7402                	ld	s0,32(sp)
    80002220:	64e2                	ld	s1,24(sp)
    80002222:	6942                	ld	s2,16(sp)
    80002224:	69a2                	ld	s3,8(sp)
    80002226:	6a02                	ld	s4,0(sp)
    80002228:	6145                	addi	sp,sp,48
    8000222a:	8082                	ret

000000008000222c <exit>:
{
    8000222c:	7179                	addi	sp,sp,-48
    8000222e:	f406                	sd	ra,40(sp)
    80002230:	f022                	sd	s0,32(sp)
    80002232:	ec26                	sd	s1,24(sp)
    80002234:	e84a                	sd	s2,16(sp)
    80002236:	e44e                	sd	s3,8(sp)
    80002238:	e052                	sd	s4,0(sp)
    8000223a:	1800                	addi	s0,sp,48
    8000223c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	768080e7          	jalr	1896(ra) # 800019a6 <myproc>
    80002246:	89aa                	mv	s3,a0
  if (p == initproc)
    80002248:	00006797          	auipc	a5,0x6
    8000224c:	6b07b783          	ld	a5,1712(a5) # 800088f8 <initproc>
    80002250:	0d050493          	addi	s1,a0,208
    80002254:	15050913          	addi	s2,a0,336
    80002258:	02a79363          	bne	a5,a0,8000227e <exit+0x52>
    panic("init exiting");
    8000225c:	00006517          	auipc	a0,0x6
    80002260:	00450513          	addi	a0,a0,4 # 80008260 <digits+0x220>
    80002264:	ffffe097          	auipc	ra,0xffffe
    80002268:	2d8080e7          	jalr	728(ra) # 8000053c <panic>
      fileclose(f);
    8000226c:	00002097          	auipc	ra,0x2
    80002270:	638080e7          	jalr	1592(ra) # 800048a4 <fileclose>
      p->ofile[fd] = 0;
    80002274:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002278:	04a1                	addi	s1,s1,8
    8000227a:	01248563          	beq	s1,s2,80002284 <exit+0x58>
    if (p->ofile[fd])
    8000227e:	6088                	ld	a0,0(s1)
    80002280:	f575                	bnez	a0,8000226c <exit+0x40>
    80002282:	bfdd                	j	80002278 <exit+0x4c>
  begin_op();
    80002284:	00002097          	auipc	ra,0x2
    80002288:	15c080e7          	jalr	348(ra) # 800043e0 <begin_op>
  iput(p->cwd);
    8000228c:	1509b503          	ld	a0,336(s3)
    80002290:	00002097          	auipc	ra,0x2
    80002294:	964080e7          	jalr	-1692(ra) # 80003bf4 <iput>
  end_op();
    80002298:	00002097          	auipc	ra,0x2
    8000229c:	1c2080e7          	jalr	450(ra) # 8000445a <end_op>
  p->cwd = 0;
    800022a0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022a4:	0000f497          	auipc	s1,0xf
    800022a8:	8e448493          	addi	s1,s1,-1820 # 80010b88 <wait_lock>
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	924080e7          	jalr	-1756(ra) # 80000bd2 <acquire>
  reparent(p);
    800022b6:	854e                	mv	a0,s3
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	f1a080e7          	jalr	-230(ra) # 800021d2 <reparent>
  wakeup(p->parent);
    800022c0:	0389b503          	ld	a0,56(s3)
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	e98080e7          	jalr	-360(ra) # 8000215c <wakeup>
  acquire(&p->lock);
    800022cc:	854e                	mv	a0,s3
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	904080e7          	jalr	-1788(ra) # 80000bd2 <acquire>
  p->xstate = status;
    800022d6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022da:	4795                	li	a5,5
    800022dc:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800022e0:	00006797          	auipc	a5,0x6
    800022e4:	6207a783          	lw	a5,1568(a5) # 80008900 <ticks>
    800022e8:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	998080e7          	jalr	-1640(ra) # 80000c86 <release>
  sched();
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	cf0080e7          	jalr	-784(ra) # 80001fe6 <sched>
  panic("zombie exit");
    800022fe:	00006517          	auipc	a0,0x6
    80002302:	f7250513          	addi	a0,a0,-142 # 80008270 <digits+0x230>
    80002306:	ffffe097          	auipc	ra,0xffffe
    8000230a:	236080e7          	jalr	566(ra) # 8000053c <panic>

000000008000230e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000230e:	7179                	addi	sp,sp,-48
    80002310:	f406                	sd	ra,40(sp)
    80002312:	f022                	sd	s0,32(sp)
    80002314:	ec26                	sd	s1,24(sp)
    80002316:	e84a                	sd	s2,16(sp)
    80002318:	e44e                	sd	s3,8(sp)
    8000231a:	1800                	addi	s0,sp,48
    8000231c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000231e:	0000f497          	auipc	s1,0xf
    80002322:	c8248493          	addi	s1,s1,-894 # 80010fa0 <proc>
    80002326:	00015997          	auipc	s3,0x15
    8000232a:	07a98993          	addi	s3,s3,122 # 800173a0 <tickslock>
  {
    acquire(&p->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	8a2080e7          	jalr	-1886(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    80002338:	589c                	lw	a5,48(s1)
    8000233a:	01278d63          	beq	a5,s2,80002354 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	946080e7          	jalr	-1722(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002348:	19048493          	addi	s1,s1,400
    8000234c:	ff3491e3          	bne	s1,s3,8000232e <kill+0x20>
  }
  return -1;
    80002350:	557d                	li	a0,-1
    80002352:	a829                	j	8000236c <kill+0x5e>
      p->killed = 1;
    80002354:	4785                	li	a5,1
    80002356:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002358:	4c98                	lw	a4,24(s1)
    8000235a:	4789                	li	a5,2
    8000235c:	00f70f63          	beq	a4,a5,8000237a <kill+0x6c>
      release(&p->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	924080e7          	jalr	-1756(ra) # 80000c86 <release>
      return 0;
    8000236a:	4501                	li	a0,0
}
    8000236c:	70a2                	ld	ra,40(sp)
    8000236e:	7402                	ld	s0,32(sp)
    80002370:	64e2                	ld	s1,24(sp)
    80002372:	6942                	ld	s2,16(sp)
    80002374:	69a2                	ld	s3,8(sp)
    80002376:	6145                	addi	sp,sp,48
    80002378:	8082                	ret
        p->state = RUNNABLE;
    8000237a:	478d                	li	a5,3
    8000237c:	cc9c                	sw	a5,24(s1)
    8000237e:	b7cd                	j	80002360 <kill+0x52>

0000000080002380 <setkilled>:

void setkilled(struct proc *p)
{
    80002380:	1101                	addi	sp,sp,-32
    80002382:	ec06                	sd	ra,24(sp)
    80002384:	e822                	sd	s0,16(sp)
    80002386:	e426                	sd	s1,8(sp)
    80002388:	1000                	addi	s0,sp,32
    8000238a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	846080e7          	jalr	-1978(ra) # 80000bd2 <acquire>
  p->killed = 1;
    80002394:	4785                	li	a5,1
    80002396:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	8ec080e7          	jalr	-1812(ra) # 80000c86 <release>
}
    800023a2:	60e2                	ld	ra,24(sp)
    800023a4:	6442                	ld	s0,16(sp)
    800023a6:	64a2                	ld	s1,8(sp)
    800023a8:	6105                	addi	sp,sp,32
    800023aa:	8082                	ret

00000000800023ac <killed>:

int killed(struct proc *p)
{
    800023ac:	1101                	addi	sp,sp,-32
    800023ae:	ec06                	sd	ra,24(sp)
    800023b0:	e822                	sd	s0,16(sp)
    800023b2:	e426                	sd	s1,8(sp)
    800023b4:	e04a                	sd	s2,0(sp)
    800023b6:	1000                	addi	s0,sp,32
    800023b8:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	818080e7          	jalr	-2024(ra) # 80000bd2 <acquire>
  k = p->killed;
    800023c2:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8be080e7          	jalr	-1858(ra) # 80000c86 <release>
  return k;
}
    800023d0:	854a                	mv	a0,s2
    800023d2:	60e2                	ld	ra,24(sp)
    800023d4:	6442                	ld	s0,16(sp)
    800023d6:	64a2                	ld	s1,8(sp)
    800023d8:	6902                	ld	s2,0(sp)
    800023da:	6105                	addi	sp,sp,32
    800023dc:	8082                	ret

00000000800023de <wait>:
{
    800023de:	715d                	addi	sp,sp,-80
    800023e0:	e486                	sd	ra,72(sp)
    800023e2:	e0a2                	sd	s0,64(sp)
    800023e4:	fc26                	sd	s1,56(sp)
    800023e6:	f84a                	sd	s2,48(sp)
    800023e8:	f44e                	sd	s3,40(sp)
    800023ea:	f052                	sd	s4,32(sp)
    800023ec:	ec56                	sd	s5,24(sp)
    800023ee:	e85a                	sd	s6,16(sp)
    800023f0:	e45e                	sd	s7,8(sp)
    800023f2:	e062                	sd	s8,0(sp)
    800023f4:	0880                	addi	s0,sp,80
    800023f6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	5ae080e7          	jalr	1454(ra) # 800019a6 <myproc>
    80002400:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002402:	0000e517          	auipc	a0,0xe
    80002406:	78650513          	addi	a0,a0,1926 # 80010b88 <wait_lock>
    8000240a:	ffffe097          	auipc	ra,0xffffe
    8000240e:	7c8080e7          	jalr	1992(ra) # 80000bd2 <acquire>
    havekids = 0;
    80002412:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002414:	4a15                	li	s4,5
        havekids = 1;
    80002416:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002418:	00015997          	auipc	s3,0x15
    8000241c:	f8898993          	addi	s3,s3,-120 # 800173a0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002420:	0000ec17          	auipc	s8,0xe
    80002424:	768c0c13          	addi	s8,s8,1896 # 80010b88 <wait_lock>
    80002428:	a0d1                	j	800024ec <wait+0x10e>
          pid = pp->pid;
    8000242a:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000242e:	000b0e63          	beqz	s6,8000244a <wait+0x6c>
    80002432:	4691                	li	a3,4
    80002434:	02c48613          	addi	a2,s1,44
    80002438:	85da                	mv	a1,s6
    8000243a:	05093503          	ld	a0,80(s2)
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	228080e7          	jalr	552(ra) # 80001666 <copyout>
    80002446:	04054163          	bltz	a0,80002488 <wait+0xaa>
          freeproc(pp);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	772080e7          	jalr	1906(ra) # 80001bbe <freeproc>
          release(&pp->lock);
    80002454:	8526                	mv	a0,s1
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	830080e7          	jalr	-2000(ra) # 80000c86 <release>
          release(&wait_lock);
    8000245e:	0000e517          	auipc	a0,0xe
    80002462:	72a50513          	addi	a0,a0,1834 # 80010b88 <wait_lock>
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	820080e7          	jalr	-2016(ra) # 80000c86 <release>
}
    8000246e:	854e                	mv	a0,s3
    80002470:	60a6                	ld	ra,72(sp)
    80002472:	6406                	ld	s0,64(sp)
    80002474:	74e2                	ld	s1,56(sp)
    80002476:	7942                	ld	s2,48(sp)
    80002478:	79a2                	ld	s3,40(sp)
    8000247a:	7a02                	ld	s4,32(sp)
    8000247c:	6ae2                	ld	s5,24(sp)
    8000247e:	6b42                	ld	s6,16(sp)
    80002480:	6ba2                	ld	s7,8(sp)
    80002482:	6c02                	ld	s8,0(sp)
    80002484:	6161                	addi	sp,sp,80
    80002486:	8082                	ret
            release(&pp->lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	7fc080e7          	jalr	2044(ra) # 80000c86 <release>
            release(&wait_lock);
    80002492:	0000e517          	auipc	a0,0xe
    80002496:	6f650513          	addi	a0,a0,1782 # 80010b88 <wait_lock>
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	7ec080e7          	jalr	2028(ra) # 80000c86 <release>
            return -1;
    800024a2:	59fd                	li	s3,-1
    800024a4:	b7e9                	j	8000246e <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024a6:	19048493          	addi	s1,s1,400
    800024aa:	03348463          	beq	s1,s3,800024d2 <wait+0xf4>
      if (pp->parent == p)
    800024ae:	7c9c                	ld	a5,56(s1)
    800024b0:	ff279be3          	bne	a5,s2,800024a6 <wait+0xc8>
        acquire(&pp->lock);
    800024b4:	8526                	mv	a0,s1
    800024b6:	ffffe097          	auipc	ra,0xffffe
    800024ba:	71c080e7          	jalr	1820(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    800024be:	4c9c                	lw	a5,24(s1)
    800024c0:	f74785e3          	beq	a5,s4,8000242a <wait+0x4c>
        release(&pp->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	7c0080e7          	jalr	1984(ra) # 80000c86 <release>
        havekids = 1;
    800024ce:	8756                	mv	a4,s5
    800024d0:	bfd9                	j	800024a6 <wait+0xc8>
    if (!havekids || killed(p))
    800024d2:	c31d                	beqz	a4,800024f8 <wait+0x11a>
    800024d4:	854a                	mv	a0,s2
    800024d6:	00000097          	auipc	ra,0x0
    800024da:	ed6080e7          	jalr	-298(ra) # 800023ac <killed>
    800024de:	ed09                	bnez	a0,800024f8 <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024e0:	85e2                	mv	a1,s8
    800024e2:	854a                	mv	a0,s2
    800024e4:	00000097          	auipc	ra,0x0
    800024e8:	c14080e7          	jalr	-1004(ra) # 800020f8 <sleep>
    havekids = 0;
    800024ec:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024ee:	0000f497          	auipc	s1,0xf
    800024f2:	ab248493          	addi	s1,s1,-1358 # 80010fa0 <proc>
    800024f6:	bf65                	j	800024ae <wait+0xd0>
      release(&wait_lock);
    800024f8:	0000e517          	auipc	a0,0xe
    800024fc:	69050513          	addi	a0,a0,1680 # 80010b88 <wait_lock>
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	786080e7          	jalr	1926(ra) # 80000c86 <release>
      return -1;
    80002508:	59fd                	li	s3,-1
    8000250a:	b795                	j	8000246e <wait+0x90>

000000008000250c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000250c:	7179                	addi	sp,sp,-48
    8000250e:	f406                	sd	ra,40(sp)
    80002510:	f022                	sd	s0,32(sp)
    80002512:	ec26                	sd	s1,24(sp)
    80002514:	e84a                	sd	s2,16(sp)
    80002516:	e44e                	sd	s3,8(sp)
    80002518:	e052                	sd	s4,0(sp)
    8000251a:	1800                	addi	s0,sp,48
    8000251c:	84aa                	mv	s1,a0
    8000251e:	892e                	mv	s2,a1
    80002520:	89b2                	mv	s3,a2
    80002522:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002524:	fffff097          	auipc	ra,0xfffff
    80002528:	482080e7          	jalr	1154(ra) # 800019a6 <myproc>
  if (user_dst)
    8000252c:	c08d                	beqz	s1,8000254e <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000252e:	86d2                	mv	a3,s4
    80002530:	864e                	mv	a2,s3
    80002532:	85ca                	mv	a1,s2
    80002534:	6928                	ld	a0,80(a0)
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	130080e7          	jalr	304(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000253e:	70a2                	ld	ra,40(sp)
    80002540:	7402                	ld	s0,32(sp)
    80002542:	64e2                	ld	s1,24(sp)
    80002544:	6942                	ld	s2,16(sp)
    80002546:	69a2                	ld	s3,8(sp)
    80002548:	6a02                	ld	s4,0(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
    memmove((char *)dst, src, len);
    8000254e:	000a061b          	sext.w	a2,s4
    80002552:	85ce                	mv	a1,s3
    80002554:	854a                	mv	a0,s2
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	7d4080e7          	jalr	2004(ra) # 80000d2a <memmove>
    return 0;
    8000255e:	8526                	mv	a0,s1
    80002560:	bff9                	j	8000253e <either_copyout+0x32>

0000000080002562 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002562:	7179                	addi	sp,sp,-48
    80002564:	f406                	sd	ra,40(sp)
    80002566:	f022                	sd	s0,32(sp)
    80002568:	ec26                	sd	s1,24(sp)
    8000256a:	e84a                	sd	s2,16(sp)
    8000256c:	e44e                	sd	s3,8(sp)
    8000256e:	e052                	sd	s4,0(sp)
    80002570:	1800                	addi	s0,sp,48
    80002572:	892a                	mv	s2,a0
    80002574:	84ae                	mv	s1,a1
    80002576:	89b2                	mv	s3,a2
    80002578:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	42c080e7          	jalr	1068(ra) # 800019a6 <myproc>
  if (user_src)
    80002582:	c08d                	beqz	s1,800025a4 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002584:	86d2                	mv	a3,s4
    80002586:	864e                	mv	a2,s3
    80002588:	85ca                	mv	a1,s2
    8000258a:	6928                	ld	a0,80(a0)
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	166080e7          	jalr	358(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002594:	70a2                	ld	ra,40(sp)
    80002596:	7402                	ld	s0,32(sp)
    80002598:	64e2                	ld	s1,24(sp)
    8000259a:	6942                	ld	s2,16(sp)
    8000259c:	69a2                	ld	s3,8(sp)
    8000259e:	6a02                	ld	s4,0(sp)
    800025a0:	6145                	addi	sp,sp,48
    800025a2:	8082                	ret
    memmove(dst, (char *)src, len);
    800025a4:	000a061b          	sext.w	a2,s4
    800025a8:	85ce                	mv	a1,s3
    800025aa:	854a                	mv	a0,s2
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	77e080e7          	jalr	1918(ra) # 80000d2a <memmove>
    return 0;
    800025b4:	8526                	mv	a0,s1
    800025b6:	bff9                	j	80002594 <either_copyin+0x32>

00000000800025b8 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800025b8:	715d                	addi	sp,sp,-80
    800025ba:	e486                	sd	ra,72(sp)
    800025bc:	e0a2                	sd	s0,64(sp)
    800025be:	fc26                	sd	s1,56(sp)
    800025c0:	f84a                	sd	s2,48(sp)
    800025c2:	f44e                	sd	s3,40(sp)
    800025c4:	f052                	sd	s4,32(sp)
    800025c6:	ec56                	sd	s5,24(sp)
    800025c8:	e85a                	sd	s6,16(sp)
    800025ca:	e45e                	sd	s7,8(sp)
    800025cc:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800025ce:	00006517          	auipc	a0,0x6
    800025d2:	afa50513          	addi	a0,a0,-1286 # 800080c8 <digits+0x88>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	fb0080e7          	jalr	-80(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025de:	0000f497          	auipc	s1,0xf
    800025e2:	b1a48493          	addi	s1,s1,-1254 # 800110f8 <proc+0x158>
    800025e6:	00015917          	auipc	s2,0x15
    800025ea:	f1290913          	addi	s2,s2,-238 # 800174f8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025f0:	00006997          	auipc	s3,0x6
    800025f4:	c9098993          	addi	s3,s3,-880 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025f8:	00006a97          	auipc	s5,0x6
    800025fc:	c90a8a93          	addi	s5,s5,-880 # 80008288 <digits+0x248>
    printf("\n");
    80002600:	00006a17          	auipc	s4,0x6
    80002604:	ac8a0a13          	addi	s4,s4,-1336 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002608:	00006b97          	auipc	s7,0x6
    8000260c:	cc0b8b93          	addi	s7,s7,-832 # 800082c8 <states.0>
    80002610:	a00d                	j	80002632 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002612:	ed86a583          	lw	a1,-296(a3)
    80002616:	8556                	mv	a0,s5
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f6e080e7          	jalr	-146(ra) # 80000586 <printf>
    printf("\n");
    80002620:	8552                	mv	a0,s4
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	f64080e7          	jalr	-156(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000262a:	19048493          	addi	s1,s1,400
    8000262e:	03248263          	beq	s1,s2,80002652 <procdump+0x9a>
    if (p->state == UNUSED)
    80002632:	86a6                	mv	a3,s1
    80002634:	ec04a783          	lw	a5,-320(s1)
    80002638:	dbed                	beqz	a5,8000262a <procdump+0x72>
      state = "???";
    8000263a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000263c:	fcfb6be3          	bltu	s6,a5,80002612 <procdump+0x5a>
    80002640:	02079713          	slli	a4,a5,0x20
    80002644:	01d75793          	srli	a5,a4,0x1d
    80002648:	97de                	add	a5,a5,s7
    8000264a:	6390                	ld	a2,0(a5)
    8000264c:	f279                	bnez	a2,80002612 <procdump+0x5a>
      state = "???";
    8000264e:	864e                	mv	a2,s3
    80002650:	b7c9                	j	80002612 <procdump+0x5a>
  }
}
    80002652:	60a6                	ld	ra,72(sp)
    80002654:	6406                	ld	s0,64(sp)
    80002656:	74e2                	ld	s1,56(sp)
    80002658:	7942                	ld	s2,48(sp)
    8000265a:	79a2                	ld	s3,40(sp)
    8000265c:	7a02                	ld	s4,32(sp)
    8000265e:	6ae2                	ld	s5,24(sp)
    80002660:	6b42                	ld	s6,16(sp)
    80002662:	6ba2                	ld	s7,8(sp)
    80002664:	6161                	addi	sp,sp,80
    80002666:	8082                	ret

0000000080002668 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002668:	711d                	addi	sp,sp,-96
    8000266a:	ec86                	sd	ra,88(sp)
    8000266c:	e8a2                	sd	s0,80(sp)
    8000266e:	e4a6                	sd	s1,72(sp)
    80002670:	e0ca                	sd	s2,64(sp)
    80002672:	fc4e                	sd	s3,56(sp)
    80002674:	f852                	sd	s4,48(sp)
    80002676:	f456                	sd	s5,40(sp)
    80002678:	f05a                	sd	s6,32(sp)
    8000267a:	ec5e                	sd	s7,24(sp)
    8000267c:	e862                	sd	s8,16(sp)
    8000267e:	e466                	sd	s9,8(sp)
    80002680:	e06a                	sd	s10,0(sp)
    80002682:	1080                	addi	s0,sp,96
    80002684:	8b2a                	mv	s6,a0
    80002686:	8bae                	mv	s7,a1
    80002688:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	31c080e7          	jalr	796(ra) # 800019a6 <myproc>
    80002692:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002694:	0000e517          	auipc	a0,0xe
    80002698:	4f450513          	addi	a0,a0,1268 # 80010b88 <wait_lock>
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	536080e7          	jalr	1334(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800026a4:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800026a6:	4a15                	li	s4,5
        havekids = 1;
    800026a8:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800026aa:	00015997          	auipc	s3,0x15
    800026ae:	cf698993          	addi	s3,s3,-778 # 800173a0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026b2:	0000ed17          	auipc	s10,0xe
    800026b6:	4d6d0d13          	addi	s10,s10,1238 # 80010b88 <wait_lock>
    800026ba:	a8e9                	j	80002794 <waitx+0x12c>
          pid = np->pid;
    800026bc:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800026c0:	1684a783          	lw	a5,360(s1)
    800026c4:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800026c8:	16c4a703          	lw	a4,364(s1)
    800026cc:	9f3d                	addw	a4,a4,a5
    800026ce:	1704a783          	lw	a5,368(s1)
    800026d2:	9f99                	subw	a5,a5,a4
    800026d4:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026d8:	000b0e63          	beqz	s6,800026f4 <waitx+0x8c>
    800026dc:	4691                	li	a3,4
    800026de:	02c48613          	addi	a2,s1,44
    800026e2:	85da                	mv	a1,s6
    800026e4:	05093503          	ld	a0,80(s2)
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	f7e080e7          	jalr	-130(ra) # 80001666 <copyout>
    800026f0:	04054363          	bltz	a0,80002736 <waitx+0xce>
          freeproc(np);
    800026f4:	8526                	mv	a0,s1
    800026f6:	fffff097          	auipc	ra,0xfffff
    800026fa:	4c8080e7          	jalr	1224(ra) # 80001bbe <freeproc>
          release(&np->lock);
    800026fe:	8526                	mv	a0,s1
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	586080e7          	jalr	1414(ra) # 80000c86 <release>
          release(&wait_lock);
    80002708:	0000e517          	auipc	a0,0xe
    8000270c:	48050513          	addi	a0,a0,1152 # 80010b88 <wait_lock>
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	576080e7          	jalr	1398(ra) # 80000c86 <release>
  }
}
    80002718:	854e                	mv	a0,s3
    8000271a:	60e6                	ld	ra,88(sp)
    8000271c:	6446                	ld	s0,80(sp)
    8000271e:	64a6                	ld	s1,72(sp)
    80002720:	6906                	ld	s2,64(sp)
    80002722:	79e2                	ld	s3,56(sp)
    80002724:	7a42                	ld	s4,48(sp)
    80002726:	7aa2                	ld	s5,40(sp)
    80002728:	7b02                	ld	s6,32(sp)
    8000272a:	6be2                	ld	s7,24(sp)
    8000272c:	6c42                	ld	s8,16(sp)
    8000272e:	6ca2                	ld	s9,8(sp)
    80002730:	6d02                	ld	s10,0(sp)
    80002732:	6125                	addi	sp,sp,96
    80002734:	8082                	ret
            release(&np->lock);
    80002736:	8526                	mv	a0,s1
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	54e080e7          	jalr	1358(ra) # 80000c86 <release>
            release(&wait_lock);
    80002740:	0000e517          	auipc	a0,0xe
    80002744:	44850513          	addi	a0,a0,1096 # 80010b88 <wait_lock>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	53e080e7          	jalr	1342(ra) # 80000c86 <release>
            return -1;
    80002750:	59fd                	li	s3,-1
    80002752:	b7d9                	j	80002718 <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002754:	19048493          	addi	s1,s1,400
    80002758:	03348463          	beq	s1,s3,80002780 <waitx+0x118>
      if (np->parent == p)
    8000275c:	7c9c                	ld	a5,56(s1)
    8000275e:	ff279be3          	bne	a5,s2,80002754 <waitx+0xec>
        acquire(&np->lock);
    80002762:	8526                	mv	a0,s1
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	46e080e7          	jalr	1134(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    8000276c:	4c9c                	lw	a5,24(s1)
    8000276e:	f54787e3          	beq	a5,s4,800026bc <waitx+0x54>
        release(&np->lock);
    80002772:	8526                	mv	a0,s1
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	512080e7          	jalr	1298(ra) # 80000c86 <release>
        havekids = 1;
    8000277c:	8756                	mv	a4,s5
    8000277e:	bfd9                	j	80002754 <waitx+0xec>
    if (!havekids || p->killed)
    80002780:	c305                	beqz	a4,800027a0 <waitx+0x138>
    80002782:	02892783          	lw	a5,40(s2)
    80002786:	ef89                	bnez	a5,800027a0 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002788:	85ea                	mv	a1,s10
    8000278a:	854a                	mv	a0,s2
    8000278c:	00000097          	auipc	ra,0x0
    80002790:	96c080e7          	jalr	-1684(ra) # 800020f8 <sleep>
    havekids = 0;
    80002794:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002796:	0000f497          	auipc	s1,0xf
    8000279a:	80a48493          	addi	s1,s1,-2038 # 80010fa0 <proc>
    8000279e:	bf7d                	j	8000275c <waitx+0xf4>
      release(&wait_lock);
    800027a0:	0000e517          	auipc	a0,0xe
    800027a4:	3e850513          	addi	a0,a0,1000 # 80010b88 <wait_lock>
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	4de080e7          	jalr	1246(ra) # 80000c86 <release>
      return -1;
    800027b0:	59fd                	li	s3,-1
    800027b2:	b79d                	j	80002718 <waitx+0xb0>

00000000800027b4 <update_time>:

void update_time()
{
    800027b4:	7179                	addi	sp,sp,-48
    800027b6:	f406                	sd	ra,40(sp)
    800027b8:	f022                	sd	s0,32(sp)
    800027ba:	ec26                	sd	s1,24(sp)
    800027bc:	e84a                	sd	s2,16(sp)
    800027be:	e44e                	sd	s3,8(sp)
    800027c0:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800027c2:	0000e497          	auipc	s1,0xe
    800027c6:	7de48493          	addi	s1,s1,2014 # 80010fa0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800027ca:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800027cc:	00015917          	auipc	s2,0x15
    800027d0:	bd490913          	addi	s2,s2,-1068 # 800173a0 <tickslock>
    800027d4:	a811                	j	800027e8 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    800027d6:	8526                	mv	a0,s1
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	4ae080e7          	jalr	1198(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027e0:	19048493          	addi	s1,s1,400
    800027e4:	03248063          	beq	s1,s2,80002804 <update_time+0x50>
    acquire(&p->lock);
    800027e8:	8526                	mv	a0,s1
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	3e8080e7          	jalr	1000(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    800027f2:	4c9c                	lw	a5,24(s1)
    800027f4:	ff3791e3          	bne	a5,s3,800027d6 <update_time+0x22>
      p->rtime++;
    800027f8:	1684a783          	lw	a5,360(s1)
    800027fc:	2785                	addiw	a5,a5,1
    800027fe:	16f4a423          	sw	a5,360(s1)
    80002802:	bfd1                	j	800027d6 <update_time+0x22>
  }
    80002804:	70a2                	ld	ra,40(sp)
    80002806:	7402                	ld	s0,32(sp)
    80002808:	64e2                	ld	s1,24(sp)
    8000280a:	6942                	ld	s2,16(sp)
    8000280c:	69a2                	ld	s3,8(sp)
    8000280e:	6145                	addi	sp,sp,48
    80002810:	8082                	ret

0000000080002812 <swtch>:
    80002812:	00153023          	sd	ra,0(a0)
    80002816:	00253423          	sd	sp,8(a0)
    8000281a:	e900                	sd	s0,16(a0)
    8000281c:	ed04                	sd	s1,24(a0)
    8000281e:	03253023          	sd	s2,32(a0)
    80002822:	03353423          	sd	s3,40(a0)
    80002826:	03453823          	sd	s4,48(a0)
    8000282a:	03553c23          	sd	s5,56(a0)
    8000282e:	05653023          	sd	s6,64(a0)
    80002832:	05753423          	sd	s7,72(a0)
    80002836:	05853823          	sd	s8,80(a0)
    8000283a:	05953c23          	sd	s9,88(a0)
    8000283e:	07a53023          	sd	s10,96(a0)
    80002842:	07b53423          	sd	s11,104(a0)
    80002846:	0005b083          	ld	ra,0(a1)
    8000284a:	0085b103          	ld	sp,8(a1)
    8000284e:	6980                	ld	s0,16(a1)
    80002850:	6d84                	ld	s1,24(a1)
    80002852:	0205b903          	ld	s2,32(a1)
    80002856:	0285b983          	ld	s3,40(a1)
    8000285a:	0305ba03          	ld	s4,48(a1)
    8000285e:	0385ba83          	ld	s5,56(a1)
    80002862:	0405bb03          	ld	s6,64(a1)
    80002866:	0485bb83          	ld	s7,72(a1)
    8000286a:	0505bc03          	ld	s8,80(a1)
    8000286e:	0585bc83          	ld	s9,88(a1)
    80002872:	0605bd03          	ld	s10,96(a1)
    80002876:	0685bd83          	ld	s11,104(a1)
    8000287a:	8082                	ret

000000008000287c <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    8000287c:	1141                	addi	sp,sp,-16
    8000287e:	e406                	sd	ra,8(sp)
    80002880:	e022                	sd	s0,0(sp)
    80002882:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002884:	00006597          	auipc	a1,0x6
    80002888:	a7458593          	addi	a1,a1,-1420 # 800082f8 <states.0+0x30>
    8000288c:	00015517          	auipc	a0,0x15
    80002890:	b1450513          	addi	a0,a0,-1260 # 800173a0 <tickslock>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	2ae080e7          	jalr	686(ra) # 80000b42 <initlock>
}
    8000289c:	60a2                	ld	ra,8(sp)
    8000289e:	6402                	ld	s0,0(sp)
    800028a0:	0141                	addi	sp,sp,16
    800028a2:	8082                	ret

00000000800028a4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800028a4:	1141                	addi	sp,sp,-16
    800028a6:	e422                	sd	s0,8(sp)
    800028a8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028aa:	00003797          	auipc	a5,0x3
    800028ae:	63678793          	addi	a5,a5,1590 # 80005ee0 <kernelvec>
    800028b2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028b6:	6422                	ld	s0,8(sp)
    800028b8:	0141                	addi	sp,sp,16
    800028ba:	8082                	ret

00000000800028bc <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800028bc:	1141                	addi	sp,sp,-16
    800028be:	e406                	sd	ra,8(sp)
    800028c0:	e022                	sd	s0,0(sp)
    800028c2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	0e2080e7          	jalr	226(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028d0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800028d6:	00004697          	auipc	a3,0x4
    800028da:	72a68693          	addi	a3,a3,1834 # 80007000 <_trampoline>
    800028de:	00004717          	auipc	a4,0x4
    800028e2:	72270713          	addi	a4,a4,1826 # 80007000 <_trampoline>
    800028e6:	8f15                	sub	a4,a4,a3
    800028e8:	040007b7          	lui	a5,0x4000
    800028ec:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800028ee:	07b2                	slli	a5,a5,0xc
    800028f0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028f6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028f8:	18002673          	csrr	a2,satp
    800028fc:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028fe:	6d30                	ld	a2,88(a0)
    80002900:	6138                	ld	a4,64(a0)
    80002902:	6585                	lui	a1,0x1
    80002904:	972e                	add	a4,a4,a1
    80002906:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002908:	6d38                	ld	a4,88(a0)
    8000290a:	00000617          	auipc	a2,0x0
    8000290e:	14260613          	addi	a2,a2,322 # 80002a4c <usertrap>
    80002912:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002914:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002916:	8612                	mv	a2,tp
    80002918:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000291e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002922:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002926:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000292a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000292c:	6f18                	ld	a4,24(a4)
    8000292e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002932:	6928                	ld	a0,80(a0)
    80002934:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002936:	00004717          	auipc	a4,0x4
    8000293a:	76670713          	addi	a4,a4,1894 # 8000709c <userret>
    8000293e:	8f15                	sub	a4,a4,a3
    80002940:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002942:	577d                	li	a4,-1
    80002944:	177e                	slli	a4,a4,0x3f
    80002946:	8d59                	or	a0,a0,a4
    80002948:	9782                	jalr	a5
}
    8000294a:	60a2                	ld	ra,8(sp)
    8000294c:	6402                	ld	s0,0(sp)
    8000294e:	0141                	addi	sp,sp,16
    80002950:	8082                	ret

0000000080002952 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002952:	1101                	addi	sp,sp,-32
    80002954:	ec06                	sd	ra,24(sp)
    80002956:	e822                	sd	s0,16(sp)
    80002958:	e426                	sd	s1,8(sp)
    8000295a:	e04a                	sd	s2,0(sp)
    8000295c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000295e:	00015917          	auipc	s2,0x15
    80002962:	a4290913          	addi	s2,s2,-1470 # 800173a0 <tickslock>
    80002966:	854a                	mv	a0,s2
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	26a080e7          	jalr	618(ra) # 80000bd2 <acquire>
  ticks++;
    80002970:	00006497          	auipc	s1,0x6
    80002974:	f9048493          	addi	s1,s1,-112 # 80008900 <ticks>
    80002978:	409c                	lw	a5,0(s1)
    8000297a:	2785                	addiw	a5,a5,1
    8000297c:	c09c                	sw	a5,0(s1)
  update_time();
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	e36080e7          	jalr	-458(ra) # 800027b4 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002986:	8526                	mv	a0,s1
    80002988:	fffff097          	auipc	ra,0xfffff
    8000298c:	7d4080e7          	jalr	2004(ra) # 8000215c <wakeup>
  release(&tickslock);
    80002990:	854a                	mv	a0,s2
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	2f4080e7          	jalr	756(ra) # 80000c86 <release>
}
    8000299a:	60e2                	ld	ra,24(sp)
    8000299c:	6442                	ld	s0,16(sp)
    8000299e:	64a2                	ld	s1,8(sp)
    800029a0:	6902                	ld	s2,0(sp)
    800029a2:	6105                	addi	sp,sp,32
    800029a4:	8082                	ret

00000000800029a6 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a6:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    800029aa:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    800029ac:	0807df63          	bgez	a5,80002a4a <devintr+0xa4>
{
    800029b0:	1101                	addi	sp,sp,-32
    800029b2:	ec06                	sd	ra,24(sp)
    800029b4:	e822                	sd	s0,16(sp)
    800029b6:	e426                	sd	s1,8(sp)
    800029b8:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    800029ba:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    800029be:	46a5                	li	a3,9
    800029c0:	00d70d63          	beq	a4,a3,800029da <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    800029c4:	577d                	li	a4,-1
    800029c6:	177e                	slli	a4,a4,0x3f
    800029c8:	0705                	addi	a4,a4,1
    return 0;
    800029ca:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    800029cc:	04e78e63          	beq	a5,a4,80002a28 <devintr+0x82>
  }
}
    800029d0:	60e2                	ld	ra,24(sp)
    800029d2:	6442                	ld	s0,16(sp)
    800029d4:	64a2                	ld	s1,8(sp)
    800029d6:	6105                	addi	sp,sp,32
    800029d8:	8082                	ret
    int irq = plic_claim();
    800029da:	00003097          	auipc	ra,0x3
    800029de:	60e080e7          	jalr	1550(ra) # 80005fe8 <plic_claim>
    800029e2:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    800029e4:	47a9                	li	a5,10
    800029e6:	02f50763          	beq	a0,a5,80002a14 <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    800029ea:	4785                	li	a5,1
    800029ec:	02f50963          	beq	a0,a5,80002a1e <devintr+0x78>
    return 1;
    800029f0:	4505                	li	a0,1
    else if (irq)
    800029f2:	dcf9                	beqz	s1,800029d0 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    800029f4:	85a6                	mv	a1,s1
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	90a50513          	addi	a0,a0,-1782 # 80008300 <states.0+0x38>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b88080e7          	jalr	-1144(ra) # 80000586 <printf>
      plic_complete(irq);
    80002a06:	8526                	mv	a0,s1
    80002a08:	00003097          	auipc	ra,0x3
    80002a0c:	604080e7          	jalr	1540(ra) # 8000600c <plic_complete>
    return 1;
    80002a10:	4505                	li	a0,1
    80002a12:	bf7d                	j	800029d0 <devintr+0x2a>
      uartintr();
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	f80080e7          	jalr	-128(ra) # 80000994 <uartintr>
    if (irq)
    80002a1c:	b7ed                	j	80002a06 <devintr+0x60>
      virtio_disk_intr();
    80002a1e:	00004097          	auipc	ra,0x4
    80002a22:	ab4080e7          	jalr	-1356(ra) # 800064d2 <virtio_disk_intr>
    if (irq)
    80002a26:	b7c5                	j	80002a06 <devintr+0x60>
    if (cpuid() == 0)
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	f52080e7          	jalr	-174(ra) # 8000197a <cpuid>
    80002a30:	c901                	beqz	a0,80002a40 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a32:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a36:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a38:	14479073          	csrw	sip,a5
    return 2;
    80002a3c:	4509                	li	a0,2
    80002a3e:	bf49                	j	800029d0 <devintr+0x2a>
      clockintr();
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	f12080e7          	jalr	-238(ra) # 80002952 <clockintr>
    80002a48:	b7ed                	j	80002a32 <devintr+0x8c>
}
    80002a4a:	8082                	ret

0000000080002a4c <usertrap>:
{
    80002a4c:	1101                	addi	sp,sp,-32
    80002a4e:	ec06                	sd	ra,24(sp)
    80002a50:	e822                	sd	s0,16(sp)
    80002a52:	e426                	sd	s1,8(sp)
    80002a54:	e04a                	sd	s2,0(sp)
    80002a56:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a58:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002a5c:	1007f793          	andi	a5,a5,256
    80002a60:	e3b1                	bnez	a5,80002aa4 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a62:	00003797          	auipc	a5,0x3
    80002a66:	47e78793          	addi	a5,a5,1150 # 80005ee0 <kernelvec>
    80002a6a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a6e:	fffff097          	auipc	ra,0xfffff
    80002a72:	f38080e7          	jalr	-200(ra) # 800019a6 <myproc>
    80002a76:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a78:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a7a:	14102773          	csrr	a4,sepc
    80002a7e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a80:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a84:	47a1                	li	a5,8
    80002a86:	02f70763          	beq	a4,a5,80002ab4 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002a8a:	00000097          	auipc	ra,0x0
    80002a8e:	f1c080e7          	jalr	-228(ra) # 800029a6 <devintr>
    80002a92:	892a                	mv	s2,a0
    80002a94:	c92d                	beqz	a0,80002b06 <usertrap+0xba>
  if (killed(p))
    80002a96:	8526                	mv	a0,s1
    80002a98:	00000097          	auipc	ra,0x0
    80002a9c:	914080e7          	jalr	-1772(ra) # 800023ac <killed>
    80002aa0:	c555                	beqz	a0,80002b4c <usertrap+0x100>
    80002aa2:	a045                	j	80002b42 <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	87c50513          	addi	a0,a0,-1924 # 80008320 <states.0+0x58>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	a90080e7          	jalr	-1392(ra) # 8000053c <panic>
    if (killed(p))
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	8f8080e7          	jalr	-1800(ra) # 800023ac <killed>
    80002abc:	ed1d                	bnez	a0,80002afa <usertrap+0xae>
    p->trapframe->epc += 4;
    80002abe:	6cb8                	ld	a4,88(s1)
    80002ac0:	6f1c                	ld	a5,24(a4)
    80002ac2:	0791                	addi	a5,a5,4
    80002ac4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002aca:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ace:	10079073          	csrw	sstatus,a5
    syscall();
    80002ad2:	00000097          	auipc	ra,0x0
    80002ad6:	346080e7          	jalr	838(ra) # 80002e18 <syscall>
  if (killed(p))
    80002ada:	8526                	mv	a0,s1
    80002adc:	00000097          	auipc	ra,0x0
    80002ae0:	8d0080e7          	jalr	-1840(ra) # 800023ac <killed>
    80002ae4:	ed31                	bnez	a0,80002b40 <usertrap+0xf4>
  usertrapret();
    80002ae6:	00000097          	auipc	ra,0x0
    80002aea:	dd6080e7          	jalr	-554(ra) # 800028bc <usertrapret>
}
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6902                	ld	s2,0(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret
      exit(-1);
    80002afa:	557d                	li	a0,-1
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	730080e7          	jalr	1840(ra) # 8000222c <exit>
    80002b04:	bf6d                	j	80002abe <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b06:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b0a:	5890                	lw	a2,48(s1)
    80002b0c:	00006517          	auipc	a0,0x6
    80002b10:	83450513          	addi	a0,a0,-1996 # 80008340 <states.0+0x78>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	a72080e7          	jalr	-1422(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b20:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b24:	00006517          	auipc	a0,0x6
    80002b28:	84c50513          	addi	a0,a0,-1972 # 80008370 <states.0+0xa8>
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	a5a080e7          	jalr	-1446(ra) # 80000586 <printf>
    setkilled(p);
    80002b34:	8526                	mv	a0,s1
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	84a080e7          	jalr	-1974(ra) # 80002380 <setkilled>
    80002b3e:	bf71                	j	80002ada <usertrap+0x8e>
  if (killed(p))
    80002b40:	4901                	li	s2,0
    exit(-1);
    80002b42:	557d                	li	a0,-1
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	6e8080e7          	jalr	1768(ra) # 8000222c <exit>
  if (which_dev == 2)
    80002b4c:	4789                	li	a5,2
    80002b4e:	f8f91ce3          	bne	s2,a5,80002ae6 <usertrap+0x9a>
      p->now_ticks+=1 ; 
    80002b52:	17c4a783          	lw	a5,380(s1)
    80002b56:	2785                	addiw	a5,a5,1
    80002b58:	0007871b          	sext.w	a4,a5
    80002b5c:	16f4ae23          	sw	a5,380(s1)
      if( p-> ticks > 0 && p->now_ticks >= p->ticks && !p->is_sigalarm)
    80002b60:	1784a783          	lw	a5,376(s1)
    80002b64:	04f05663          	blez	a5,80002bb0 <usertrap+0x164>
    80002b68:	04f74463          	blt	a4,a5,80002bb0 <usertrap+0x164>
    80002b6c:	1744a783          	lw	a5,372(s1)
    80002b70:	e3a1                	bnez	a5,80002bb0 <usertrap+0x164>
        p->now_ticks = 0;
    80002b72:	1604ae23          	sw	zero,380(s1)
        p->is_sigalarm = 1;
    80002b76:	4785                	li	a5,1
    80002b78:	16f4aa23          	sw	a5,372(s1)
        *(p->backup_trapframe) =*( p->trapframe);
    80002b7c:	6cb4                	ld	a3,88(s1)
    80002b7e:	87b6                	mv	a5,a3
    80002b80:	1884b703          	ld	a4,392(s1)
    80002b84:	12068693          	addi	a3,a3,288
    80002b88:	0007b803          	ld	a6,0(a5)
    80002b8c:	6788                	ld	a0,8(a5)
    80002b8e:	6b8c                	ld	a1,16(a5)
    80002b90:	6f90                	ld	a2,24(a5)
    80002b92:	01073023          	sd	a6,0(a4)
    80002b96:	e708                	sd	a0,8(a4)
    80002b98:	eb0c                	sd	a1,16(a4)
    80002b9a:	ef10                	sd	a2,24(a4)
    80002b9c:	02078793          	addi	a5,a5,32
    80002ba0:	02070713          	addi	a4,a4,32
    80002ba4:	fed792e3          	bne	a5,a3,80002b88 <usertrap+0x13c>
        p->trapframe->epc = p->handler;
    80002ba8:	6cbc                	ld	a5,88(s1)
    80002baa:	1804b703          	ld	a4,384(s1)
    80002bae:	ef98                	sd	a4,24(a5)
      yield();
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	50c080e7          	jalr	1292(ra) # 800020bc <yield>
    80002bb8:	b73d                	j	80002ae6 <usertrap+0x9a>

0000000080002bba <kerneltrap>:
{
    80002bba:	7179                	addi	sp,sp,-48
    80002bbc:	f406                	sd	ra,40(sp)
    80002bbe:	f022                	sd	s0,32(sp)
    80002bc0:	ec26                	sd	s1,24(sp)
    80002bc2:	e84a                	sd	s2,16(sp)
    80002bc4:	e44e                	sd	s3,8(sp)
    80002bc6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bcc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002bd4:	1004f793          	andi	a5,s1,256
    80002bd8:	cb85                	beqz	a5,80002c08 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bda:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bde:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002be0:	ef85                	bnez	a5,80002c18 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	dc4080e7          	jalr	-572(ra) # 800029a6 <devintr>
    80002bea:	cd1d                	beqz	a0,80002c28 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bec:	4789                	li	a5,2
    80002bee:	06f50a63          	beq	a0,a5,80002c62 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bf2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bf6:	10049073          	csrw	sstatus,s1
}
    80002bfa:	70a2                	ld	ra,40(sp)
    80002bfc:	7402                	ld	s0,32(sp)
    80002bfe:	64e2                	ld	s1,24(sp)
    80002c00:	6942                	ld	s2,16(sp)
    80002c02:	69a2                	ld	s3,8(sp)
    80002c04:	6145                	addi	sp,sp,48
    80002c06:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c08:	00005517          	auipc	a0,0x5
    80002c0c:	78850513          	addi	a0,a0,1928 # 80008390 <states.0+0xc8>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	92c080e7          	jalr	-1748(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002c18:	00005517          	auipc	a0,0x5
    80002c1c:	7a050513          	addi	a0,a0,1952 # 800083b8 <states.0+0xf0>
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	91c080e7          	jalr	-1764(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002c28:	85ce                	mv	a1,s3
    80002c2a:	00005517          	auipc	a0,0x5
    80002c2e:	7ae50513          	addi	a0,a0,1966 # 800083d8 <states.0+0x110>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	954080e7          	jalr	-1708(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c3e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c42:	00005517          	auipc	a0,0x5
    80002c46:	7a650513          	addi	a0,a0,1958 # 800083e8 <states.0+0x120>
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	93c080e7          	jalr	-1732(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002c52:	00005517          	auipc	a0,0x5
    80002c56:	7ae50513          	addi	a0,a0,1966 # 80008400 <states.0+0x138>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	8e2080e7          	jalr	-1822(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	d44080e7          	jalr	-700(ra) # 800019a6 <myproc>
    80002c6a:	d541                	beqz	a0,80002bf2 <kerneltrap+0x38>
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	d3a080e7          	jalr	-710(ra) # 800019a6 <myproc>
    80002c74:	4d18                	lw	a4,24(a0)
    80002c76:	4791                	li	a5,4
    80002c78:	f6f71de3          	bne	a4,a5,80002bf2 <kerneltrap+0x38>
    yield();
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	440080e7          	jalr	1088(ra) # 800020bc <yield>
    80002c84:	b7bd                	j	80002bf2 <kerneltrap+0x38>

0000000080002c86 <sys_getreadcount>:
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}
uint64 sys_getreadcount(void)
{
    80002c86:	1141                	addi	sp,sp,-16
    80002c88:	e422                	sd	s0,8(sp)
    80002c8a:	0800                	addi	s0,sp,16
  return READCOUNT; 
}
    80002c8c:	00006517          	auipc	a0,0x6
    80002c90:	c7c53503          	ld	a0,-900(a0) # 80008908 <READCOUNT>
    80002c94:	6422                	ld	s0,8(sp)
    80002c96:	0141                	addi	sp,sp,16
    80002c98:	8082                	ret

0000000080002c9a <argraw>:
{
    80002c9a:	1101                	addi	sp,sp,-32
    80002c9c:	ec06                	sd	ra,24(sp)
    80002c9e:	e822                	sd	s0,16(sp)
    80002ca0:	e426                	sd	s1,8(sp)
    80002ca2:	1000                	addi	s0,sp,32
    80002ca4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	d00080e7          	jalr	-768(ra) # 800019a6 <myproc>
  switch (n) {
    80002cae:	4795                	li	a5,5
    80002cb0:	0497e163          	bltu	a5,s1,80002cf2 <argraw+0x58>
    80002cb4:	048a                	slli	s1,s1,0x2
    80002cb6:	00005717          	auipc	a4,0x5
    80002cba:	78270713          	addi	a4,a4,1922 # 80008438 <states.0+0x170>
    80002cbe:	94ba                	add	s1,s1,a4
    80002cc0:	409c                	lw	a5,0(s1)
    80002cc2:	97ba                	add	a5,a5,a4
    80002cc4:	8782                	jr	a5
    return p->trapframe->a0;
    80002cc6:	6d3c                	ld	a5,88(a0)
    80002cc8:	7ba8                	ld	a0,112(a5)
}
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	64a2                	ld	s1,8(sp)
    80002cd0:	6105                	addi	sp,sp,32
    80002cd2:	8082                	ret
    return p->trapframe->a1;
    80002cd4:	6d3c                	ld	a5,88(a0)
    80002cd6:	7fa8                	ld	a0,120(a5)
    80002cd8:	bfcd                	j	80002cca <argraw+0x30>
    return p->trapframe->a2;
    80002cda:	6d3c                	ld	a5,88(a0)
    80002cdc:	63c8                	ld	a0,128(a5)
    80002cde:	b7f5                	j	80002cca <argraw+0x30>
    return p->trapframe->a3;
    80002ce0:	6d3c                	ld	a5,88(a0)
    80002ce2:	67c8                	ld	a0,136(a5)
    80002ce4:	b7dd                	j	80002cca <argraw+0x30>
    return p->trapframe->a4;
    80002ce6:	6d3c                	ld	a5,88(a0)
    80002ce8:	6bc8                	ld	a0,144(a5)
    80002cea:	b7c5                	j	80002cca <argraw+0x30>
    return p->trapframe->a5;
    80002cec:	6d3c                	ld	a5,88(a0)
    80002cee:	6fc8                	ld	a0,152(a5)
    80002cf0:	bfe9                	j	80002cca <argraw+0x30>
  panic("argraw");
    80002cf2:	00005517          	auipc	a0,0x5
    80002cf6:	71e50513          	addi	a0,a0,1822 # 80008410 <states.0+0x148>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	842080e7          	jalr	-1982(ra) # 8000053c <panic>

0000000080002d02 <fetchaddr>:
{
    80002d02:	1101                	addi	sp,sp,-32
    80002d04:	ec06                	sd	ra,24(sp)
    80002d06:	e822                	sd	s0,16(sp)
    80002d08:	e426                	sd	s1,8(sp)
    80002d0a:	e04a                	sd	s2,0(sp)
    80002d0c:	1000                	addi	s0,sp,32
    80002d0e:	84aa                	mv	s1,a0
    80002d10:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	c94080e7          	jalr	-876(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d1a:	653c                	ld	a5,72(a0)
    80002d1c:	02f4f863          	bgeu	s1,a5,80002d4c <fetchaddr+0x4a>
    80002d20:	00848713          	addi	a4,s1,8
    80002d24:	02e7e663          	bltu	a5,a4,80002d50 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d28:	46a1                	li	a3,8
    80002d2a:	8626                	mv	a2,s1
    80002d2c:	85ca                	mv	a1,s2
    80002d2e:	6928                	ld	a0,80(a0)
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	9c2080e7          	jalr	-1598(ra) # 800016f2 <copyin>
    80002d38:	00a03533          	snez	a0,a0
    80002d3c:	40a00533          	neg	a0,a0
}
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	64a2                	ld	s1,8(sp)
    80002d46:	6902                	ld	s2,0(sp)
    80002d48:	6105                	addi	sp,sp,32
    80002d4a:	8082                	ret
    return -1;
    80002d4c:	557d                	li	a0,-1
    80002d4e:	bfcd                	j	80002d40 <fetchaddr+0x3e>
    80002d50:	557d                	li	a0,-1
    80002d52:	b7fd                	j	80002d40 <fetchaddr+0x3e>

0000000080002d54 <fetchstr>:
{
    80002d54:	7179                	addi	sp,sp,-48
    80002d56:	f406                	sd	ra,40(sp)
    80002d58:	f022                	sd	s0,32(sp)
    80002d5a:	ec26                	sd	s1,24(sp)
    80002d5c:	e84a                	sd	s2,16(sp)
    80002d5e:	e44e                	sd	s3,8(sp)
    80002d60:	1800                	addi	s0,sp,48
    80002d62:	892a                	mv	s2,a0
    80002d64:	84ae                	mv	s1,a1
    80002d66:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	c3e080e7          	jalr	-962(ra) # 800019a6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d70:	86ce                	mv	a3,s3
    80002d72:	864a                	mv	a2,s2
    80002d74:	85a6                	mv	a1,s1
    80002d76:	6928                	ld	a0,80(a0)
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	a08080e7          	jalr	-1528(ra) # 80001780 <copyinstr>
    80002d80:	00054e63          	bltz	a0,80002d9c <fetchstr+0x48>
  return strlen(buf);
    80002d84:	8526                	mv	a0,s1
    80002d86:	ffffe097          	auipc	ra,0xffffe
    80002d8a:	0c2080e7          	jalr	194(ra) # 80000e48 <strlen>
}
    80002d8e:	70a2                	ld	ra,40(sp)
    80002d90:	7402                	ld	s0,32(sp)
    80002d92:	64e2                	ld	s1,24(sp)
    80002d94:	6942                	ld	s2,16(sp)
    80002d96:	69a2                	ld	s3,8(sp)
    80002d98:	6145                	addi	sp,sp,48
    80002d9a:	8082                	ret
    return -1;
    80002d9c:	557d                	li	a0,-1
    80002d9e:	bfc5                	j	80002d8e <fetchstr+0x3a>

0000000080002da0 <argint>:
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	e426                	sd	s1,8(sp)
    80002da8:	1000                	addi	s0,sp,32
    80002daa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	eee080e7          	jalr	-274(ra) # 80002c9a <argraw>
    80002db4:	c088                	sw	a0,0(s1)
}
    80002db6:	60e2                	ld	ra,24(sp)
    80002db8:	6442                	ld	s0,16(sp)
    80002dba:	64a2                	ld	s1,8(sp)
    80002dbc:	6105                	addi	sp,sp,32
    80002dbe:	8082                	ret

0000000080002dc0 <argaddr>:
{
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	e426                	sd	s1,8(sp)
    80002dc8:	1000                	addi	s0,sp,32
    80002dca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dcc:	00000097          	auipc	ra,0x0
    80002dd0:	ece080e7          	jalr	-306(ra) # 80002c9a <argraw>
    80002dd4:	e088                	sd	a0,0(s1)
}
    80002dd6:	60e2                	ld	ra,24(sp)
    80002dd8:	6442                	ld	s0,16(sp)
    80002dda:	64a2                	ld	s1,8(sp)
    80002ddc:	6105                	addi	sp,sp,32
    80002dde:	8082                	ret

0000000080002de0 <argstr>:
{
    80002de0:	7179                	addi	sp,sp,-48
    80002de2:	f406                	sd	ra,40(sp)
    80002de4:	f022                	sd	s0,32(sp)
    80002de6:	ec26                	sd	s1,24(sp)
    80002de8:	e84a                	sd	s2,16(sp)
    80002dea:	1800                	addi	s0,sp,48
    80002dec:	84ae                	mv	s1,a1
    80002dee:	8932                	mv	s2,a2
  argaddr(n, &addr);
    80002df0:	fd840593          	addi	a1,s0,-40
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	fcc080e7          	jalr	-52(ra) # 80002dc0 <argaddr>
  return fetchstr(addr, buf, max);
    80002dfc:	864a                	mv	a2,s2
    80002dfe:	85a6                	mv	a1,s1
    80002e00:	fd843503          	ld	a0,-40(s0)
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	f50080e7          	jalr	-176(ra) # 80002d54 <fetchstr>
}
    80002e0c:	70a2                	ld	ra,40(sp)
    80002e0e:	7402                	ld	s0,32(sp)
    80002e10:	64e2                	ld	s1,24(sp)
    80002e12:	6942                	ld	s2,16(sp)
    80002e14:	6145                	addi	sp,sp,48
    80002e16:	8082                	ret

0000000080002e18 <syscall>:

};

void
syscall(void)
{
    80002e18:	1101                	addi	sp,sp,-32
    80002e1a:	ec06                	sd	ra,24(sp)
    80002e1c:	e822                	sd	s0,16(sp)
    80002e1e:	e426                	sd	s1,8(sp)
    80002e20:	e04a                	sd	s2,0(sp)
    80002e22:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e24:	fffff097          	auipc	ra,0xfffff
    80002e28:	b82080e7          	jalr	-1150(ra) # 800019a6 <myproc>
    80002e2c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e2e:	05853903          	ld	s2,88(a0)
    80002e32:	0a893783          	ld	a5,168(s2)
    80002e36:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e3a:	37fd                	addiw	a5,a5,-1
    80002e3c:	4761                	li	a4,24
    80002e3e:	00f76f63          	bltu	a4,a5,80002e5c <syscall+0x44>
    80002e42:	00369713          	slli	a4,a3,0x3
    80002e46:	00005797          	auipc	a5,0x5
    80002e4a:	60a78793          	addi	a5,a5,1546 # 80008450 <syscalls>
    80002e4e:	97ba                	add	a5,a5,a4
    80002e50:	639c                	ld	a5,0(a5)
    80002e52:	c789                	beqz	a5,80002e5c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e54:	9782                	jalr	a5
    80002e56:	06a93823          	sd	a0,112(s2)
    80002e5a:	a839                	j	80002e78 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e5c:	15848613          	addi	a2,s1,344
    80002e60:	588c                	lw	a1,48(s1)
    80002e62:	00005517          	auipc	a0,0x5
    80002e66:	5b650513          	addi	a0,a0,1462 # 80008418 <states.0+0x150>
    80002e6a:	ffffd097          	auipc	ra,0xffffd
    80002e6e:	71c080e7          	jalr	1820(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e72:	6cbc                	ld	a5,88(s1)
    80002e74:	577d                	li	a4,-1
    80002e76:	fbb8                	sd	a4,112(a5)
  }
}
    80002e78:	60e2                	ld	ra,24(sp)
    80002e7a:	6442                	ld	s0,16(sp)
    80002e7c:	64a2                	ld	s1,8(sp)
    80002e7e:	6902                	ld	s2,0(sp)
    80002e80:	6105                	addi	sp,sp,32
    80002e82:	8082                	ret

0000000080002e84 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e84:	1101                	addi	sp,sp,-32
    80002e86:	ec06                	sd	ra,24(sp)
    80002e88:	e822                	sd	s0,16(sp)
    80002e8a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e8c:	fec40593          	addi	a1,s0,-20
    80002e90:	4501                	li	a0,0
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	f0e080e7          	jalr	-242(ra) # 80002da0 <argint>
  exit(n);
    80002e9a:	fec42503          	lw	a0,-20(s0)
    80002e9e:	fffff097          	auipc	ra,0xfffff
    80002ea2:	38e080e7          	jalr	910(ra) # 8000222c <exit>
  return 0; // not reached
}
    80002ea6:	4501                	li	a0,0
    80002ea8:	60e2                	ld	ra,24(sp)
    80002eaa:	6442                	ld	s0,16(sp)
    80002eac:	6105                	addi	sp,sp,32
    80002eae:	8082                	ret

0000000080002eb0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002eb0:	1141                	addi	sp,sp,-16
    80002eb2:	e406                	sd	ra,8(sp)
    80002eb4:	e022                	sd	s0,0(sp)
    80002eb6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	aee080e7          	jalr	-1298(ra) # 800019a6 <myproc>
}
    80002ec0:	5908                	lw	a0,48(a0)
    80002ec2:	60a2                	ld	ra,8(sp)
    80002ec4:	6402                	ld	s0,0(sp)
    80002ec6:	0141                	addi	sp,sp,16
    80002ec8:	8082                	ret

0000000080002eca <sys_fork>:

uint64
sys_fork(void)
{
    80002eca:	1141                	addi	sp,sp,-16
    80002ecc:	e406                	sd	ra,8(sp)
    80002ece:	e022                	sd	s0,0(sp)
    80002ed0:	0800                	addi	s0,sp,16
  return fork();
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	f34080e7          	jalr	-204(ra) # 80001e06 <fork>
}
    80002eda:	60a2                	ld	ra,8(sp)
    80002edc:	6402                	ld	s0,0(sp)
    80002ede:	0141                	addi	sp,sp,16
    80002ee0:	8082                	ret

0000000080002ee2 <sys_wait>:

uint64
sys_wait(void)
{
    80002ee2:	1101                	addi	sp,sp,-32
    80002ee4:	ec06                	sd	ra,24(sp)
    80002ee6:	e822                	sd	s0,16(sp)
    80002ee8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002eea:	fe840593          	addi	a1,s0,-24
    80002eee:	4501                	li	a0,0
    80002ef0:	00000097          	auipc	ra,0x0
    80002ef4:	ed0080e7          	jalr	-304(ra) # 80002dc0 <argaddr>
  return wait(p);
    80002ef8:	fe843503          	ld	a0,-24(s0)
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	4e2080e7          	jalr	1250(ra) # 800023de <wait>
}
    80002f04:	60e2                	ld	ra,24(sp)
    80002f06:	6442                	ld	s0,16(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret

0000000080002f0c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f0c:	7179                	addi	sp,sp,-48
    80002f0e:	f406                	sd	ra,40(sp)
    80002f10:	f022                	sd	s0,32(sp)
    80002f12:	ec26                	sd	s1,24(sp)
    80002f14:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f16:	fdc40593          	addi	a1,s0,-36
    80002f1a:	4501                	li	a0,0
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	e84080e7          	jalr	-380(ra) # 80002da0 <argint>
  addr = myproc()->sz;
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	a82080e7          	jalr	-1406(ra) # 800019a6 <myproc>
    80002f2c:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002f2e:	fdc42503          	lw	a0,-36(s0)
    80002f32:	fffff097          	auipc	ra,0xfffff
    80002f36:	e78080e7          	jalr	-392(ra) # 80001daa <growproc>
    80002f3a:	00054863          	bltz	a0,80002f4a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f3e:	8526                	mv	a0,s1
    80002f40:	70a2                	ld	ra,40(sp)
    80002f42:	7402                	ld	s0,32(sp)
    80002f44:	64e2                	ld	s1,24(sp)
    80002f46:	6145                	addi	sp,sp,48
    80002f48:	8082                	ret
    return -1;
    80002f4a:	54fd                	li	s1,-1
    80002f4c:	bfcd                	j	80002f3e <sys_sbrk+0x32>

0000000080002f4e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f4e:	7139                	addi	sp,sp,-64
    80002f50:	fc06                	sd	ra,56(sp)
    80002f52:	f822                	sd	s0,48(sp)
    80002f54:	f426                	sd	s1,40(sp)
    80002f56:	f04a                	sd	s2,32(sp)
    80002f58:	ec4e                	sd	s3,24(sp)
    80002f5a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f5c:	fcc40593          	addi	a1,s0,-52
    80002f60:	4501                	li	a0,0
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	e3e080e7          	jalr	-450(ra) # 80002da0 <argint>
  acquire(&tickslock);
    80002f6a:	00014517          	auipc	a0,0x14
    80002f6e:	43650513          	addi	a0,a0,1078 # 800173a0 <tickslock>
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	c60080e7          	jalr	-928(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002f7a:	00006917          	auipc	s2,0x6
    80002f7e:	98692903          	lw	s2,-1658(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    80002f82:	fcc42783          	lw	a5,-52(s0)
    80002f86:	cf9d                	beqz	a5,80002fc4 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f88:	00014997          	auipc	s3,0x14
    80002f8c:	41898993          	addi	s3,s3,1048 # 800173a0 <tickslock>
    80002f90:	00006497          	auipc	s1,0x6
    80002f94:	97048493          	addi	s1,s1,-1680 # 80008900 <ticks>
    if (killed(myproc()))
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	a0e080e7          	jalr	-1522(ra) # 800019a6 <myproc>
    80002fa0:	fffff097          	auipc	ra,0xfffff
    80002fa4:	40c080e7          	jalr	1036(ra) # 800023ac <killed>
    80002fa8:	ed15                	bnez	a0,80002fe4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002faa:	85ce                	mv	a1,s3
    80002fac:	8526                	mv	a0,s1
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	14a080e7          	jalr	330(ra) # 800020f8 <sleep>
  while (ticks - ticks0 < n)
    80002fb6:	409c                	lw	a5,0(s1)
    80002fb8:	412787bb          	subw	a5,a5,s2
    80002fbc:	fcc42703          	lw	a4,-52(s0)
    80002fc0:	fce7ece3          	bltu	a5,a4,80002f98 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002fc4:	00014517          	auipc	a0,0x14
    80002fc8:	3dc50513          	addi	a0,a0,988 # 800173a0 <tickslock>
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	cba080e7          	jalr	-838(ra) # 80000c86 <release>
  return 0;
    80002fd4:	4501                	li	a0,0
}
    80002fd6:	70e2                	ld	ra,56(sp)
    80002fd8:	7442                	ld	s0,48(sp)
    80002fda:	74a2                	ld	s1,40(sp)
    80002fdc:	7902                	ld	s2,32(sp)
    80002fde:	69e2                	ld	s3,24(sp)
    80002fe0:	6121                	addi	sp,sp,64
    80002fe2:	8082                	ret
      release(&tickslock);
    80002fe4:	00014517          	auipc	a0,0x14
    80002fe8:	3bc50513          	addi	a0,a0,956 # 800173a0 <tickslock>
    80002fec:	ffffe097          	auipc	ra,0xffffe
    80002ff0:	c9a080e7          	jalr	-870(ra) # 80000c86 <release>
      return -1;
    80002ff4:	557d                	li	a0,-1
    80002ff6:	b7c5                	j	80002fd6 <sys_sleep+0x88>

0000000080002ff8 <sys_kill>:

uint64
sys_kill(void)
{
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003000:	fec40593          	addi	a1,s0,-20
    80003004:	4501                	li	a0,0
    80003006:	00000097          	auipc	ra,0x0
    8000300a:	d9a080e7          	jalr	-614(ra) # 80002da0 <argint>
  return kill(pid);
    8000300e:	fec42503          	lw	a0,-20(s0)
    80003012:	fffff097          	auipc	ra,0xfffff
    80003016:	2fc080e7          	jalr	764(ra) # 8000230e <kill>
}
    8000301a:	60e2                	ld	ra,24(sp)
    8000301c:	6442                	ld	s0,16(sp)
    8000301e:	6105                	addi	sp,sp,32
    80003020:	8082                	ret

0000000080003022 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003022:	1101                	addi	sp,sp,-32
    80003024:	ec06                	sd	ra,24(sp)
    80003026:	e822                	sd	s0,16(sp)
    80003028:	e426                	sd	s1,8(sp)
    8000302a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000302c:	00014517          	auipc	a0,0x14
    80003030:	37450513          	addi	a0,a0,884 # 800173a0 <tickslock>
    80003034:	ffffe097          	auipc	ra,0xffffe
    80003038:	b9e080e7          	jalr	-1122(ra) # 80000bd2 <acquire>
  xticks = ticks;
    8000303c:	00006497          	auipc	s1,0x6
    80003040:	8c44a483          	lw	s1,-1852(s1) # 80008900 <ticks>
  release(&tickslock);
    80003044:	00014517          	auipc	a0,0x14
    80003048:	35c50513          	addi	a0,a0,860 # 800173a0 <tickslock>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	c3a080e7          	jalr	-966(ra) # 80000c86 <release>
  return xticks;
}
    80003054:	02049513          	slli	a0,s1,0x20
    80003058:	9101                	srli	a0,a0,0x20
    8000305a:	60e2                	ld	ra,24(sp)
    8000305c:	6442                	ld	s0,16(sp)
    8000305e:	64a2                	ld	s1,8(sp)
    80003060:	6105                	addi	sp,sp,32
    80003062:	8082                	ret

0000000080003064 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003064:	7139                	addi	sp,sp,-64
    80003066:	fc06                	sd	ra,56(sp)
    80003068:	f822                	sd	s0,48(sp)
    8000306a:	f426                	sd	s1,40(sp)
    8000306c:	f04a                	sd	s2,32(sp)
    8000306e:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003070:	fd840593          	addi	a1,s0,-40
    80003074:	4501                	li	a0,0
    80003076:	00000097          	auipc	ra,0x0
    8000307a:	d4a080e7          	jalr	-694(ra) # 80002dc0 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000307e:	fd040593          	addi	a1,s0,-48
    80003082:	4505                	li	a0,1
    80003084:	00000097          	auipc	ra,0x0
    80003088:	d3c080e7          	jalr	-708(ra) # 80002dc0 <argaddr>
  argaddr(2, &addr2);
    8000308c:	fc840593          	addi	a1,s0,-56
    80003090:	4509                	li	a0,2
    80003092:	00000097          	auipc	ra,0x0
    80003096:	d2e080e7          	jalr	-722(ra) # 80002dc0 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000309a:	fc040613          	addi	a2,s0,-64
    8000309e:	fc440593          	addi	a1,s0,-60
    800030a2:	fd843503          	ld	a0,-40(s0)
    800030a6:	fffff097          	auipc	ra,0xfffff
    800030aa:	5c2080e7          	jalr	1474(ra) # 80002668 <waitx>
    800030ae:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800030b0:	fffff097          	auipc	ra,0xfffff
    800030b4:	8f6080e7          	jalr	-1802(ra) # 800019a6 <myproc>
    800030b8:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800030ba:	4691                	li	a3,4
    800030bc:	fc440613          	addi	a2,s0,-60
    800030c0:	fd043583          	ld	a1,-48(s0)
    800030c4:	6928                	ld	a0,80(a0)
    800030c6:	ffffe097          	auipc	ra,0xffffe
    800030ca:	5a0080e7          	jalr	1440(ra) # 80001666 <copyout>
    return -1;
    800030ce:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800030d0:	00054f63          	bltz	a0,800030ee <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800030d4:	4691                	li	a3,4
    800030d6:	fc040613          	addi	a2,s0,-64
    800030da:	fc843583          	ld	a1,-56(s0)
    800030de:	68a8                	ld	a0,80(s1)
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	586080e7          	jalr	1414(ra) # 80001666 <copyout>
    800030e8:	00054a63          	bltz	a0,800030fc <sys_waitx+0x98>
    return -1;
  return ret;
    800030ec:	87ca                	mv	a5,s2
}
    800030ee:	853e                	mv	a0,a5
    800030f0:	70e2                	ld	ra,56(sp)
    800030f2:	7442                	ld	s0,48(sp)
    800030f4:	74a2                	ld	s1,40(sp)
    800030f6:	7902                	ld	s2,32(sp)
    800030f8:	6121                	addi	sp,sp,64
    800030fa:	8082                	ret
    return -1;
    800030fc:	57fd                	li	a5,-1
    800030fe:	bfc5                	j	800030ee <sys_waitx+0x8a>

0000000080003100 <restore>:
void restore(){
    80003100:	1141                	addi	sp,sp,-16
    80003102:	e406                	sd	ra,8(sp)
    80003104:	e022                	sd	s0,0(sp)
    80003106:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	89e080e7          	jalr	-1890(ra) # 800019a6 <myproc>
  p->backup_trapframe->kernel_hartid = p->trapframe->kernel_hartid;
    80003110:	18853783          	ld	a5,392(a0)
    80003114:	6d38                	ld	a4,88(a0)
    80003116:	7318                	ld	a4,32(a4)
    80003118:	f398                	sd	a4,32(a5)
  p->backup_trapframe->kernel_satp = p->trapframe->kernel_satp;
    8000311a:	18853783          	ld	a5,392(a0)
    8000311e:	6d38                	ld	a4,88(a0)
    80003120:	6318                	ld	a4,0(a4)
    80003122:	e398                	sd	a4,0(a5)
  p->backup_trapframe->kernel_sp = p->trapframe->kernel_sp;
    80003124:	18853783          	ld	a5,392(a0)
    80003128:	6d38                	ld	a4,88(a0)
    8000312a:	6718                	ld	a4,8(a4)
    8000312c:	e798                	sd	a4,8(a5)
  p->backup_trapframe->kernel_trap = p->trapframe->kernel_trap;
    8000312e:	18853783          	ld	a5,392(a0)
    80003132:	6d38                	ld	a4,88(a0)
    80003134:	6b18                	ld	a4,16(a4)
    80003136:	eb98                	sd	a4,16(a5)
  *(p->trapframe) = *(p->backup_trapframe);
    80003138:	18853683          	ld	a3,392(a0)
    8000313c:	87b6                	mv	a5,a3
    8000313e:	6d38                	ld	a4,88(a0)
    80003140:	12068693          	addi	a3,a3,288
    80003144:	0007b803          	ld	a6,0(a5)
    80003148:	6788                	ld	a0,8(a5)
    8000314a:	6b8c                	ld	a1,16(a5)
    8000314c:	6f90                	ld	a2,24(a5)
    8000314e:	01073023          	sd	a6,0(a4)
    80003152:	e708                	sd	a0,8(a4)
    80003154:	eb0c                	sd	a1,16(a4)
    80003156:	ef10                	sd	a2,24(a4)
    80003158:	02078793          	addi	a5,a5,32
    8000315c:	02070713          	addi	a4,a4,32
    80003160:	fed792e3          	bne	a5,a3,80003144 <restore+0x44>
} 
    80003164:	60a2                	ld	ra,8(sp)
    80003166:	6402                	ld	s0,0(sp)
    80003168:	0141                	addi	sp,sp,16
    8000316a:	8082                	ret

000000008000316c <sys_sigreturn>:
uint64 sys_sigreturn(void){
    8000316c:	1141                	addi	sp,sp,-16
    8000316e:	e406                	sd	ra,8(sp)
    80003170:	e022                	sd	s0,0(sp)
    80003172:	0800                	addi	s0,sp,16
  restore();
    80003174:	00000097          	auipc	ra,0x0
    80003178:	f8c080e7          	jalr	-116(ra) # 80003100 <restore>
  myproc()->is_sigalarm = 0;
    8000317c:	fffff097          	auipc	ra,0xfffff
    80003180:	82a080e7          	jalr	-2006(ra) # 800019a6 <myproc>
    80003184:	16052a23          	sw	zero,372(a0)
  return myproc()->trapframe->a0;
    80003188:	fffff097          	auipc	ra,0xfffff
    8000318c:	81e080e7          	jalr	-2018(ra) # 800019a6 <myproc>
    80003190:	6d3c                	ld	a5,88(a0)
    80003192:	7ba8                	ld	a0,112(a5)
    80003194:	60a2                	ld	ra,8(sp)
    80003196:	6402                	ld	s0,0(sp)
    80003198:	0141                	addi	sp,sp,16
    8000319a:	8082                	ret

000000008000319c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000319c:	7179                	addi	sp,sp,-48
    8000319e:	f406                	sd	ra,40(sp)
    800031a0:	f022                	sd	s0,32(sp)
    800031a2:	ec26                	sd	s1,24(sp)
    800031a4:	e84a                	sd	s2,16(sp)
    800031a6:	e44e                	sd	s3,8(sp)
    800031a8:	e052                	sd	s4,0(sp)
    800031aa:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031ac:	00005597          	auipc	a1,0x5
    800031b0:	37458593          	addi	a1,a1,884 # 80008520 <syscalls+0xd0>
    800031b4:	00014517          	auipc	a0,0x14
    800031b8:	20450513          	addi	a0,a0,516 # 800173b8 <bcache>
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	986080e7          	jalr	-1658(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031c4:	0001c797          	auipc	a5,0x1c
    800031c8:	1f478793          	addi	a5,a5,500 # 8001f3b8 <bcache+0x8000>
    800031cc:	0001c717          	auipc	a4,0x1c
    800031d0:	45470713          	addi	a4,a4,1108 # 8001f620 <bcache+0x8268>
    800031d4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031d8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031dc:	00014497          	auipc	s1,0x14
    800031e0:	1f448493          	addi	s1,s1,500 # 800173d0 <bcache+0x18>
    b->next = bcache.head.next;
    800031e4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031e6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031e8:	00005a17          	auipc	s4,0x5
    800031ec:	340a0a13          	addi	s4,s4,832 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    800031f0:	2b893783          	ld	a5,696(s2)
    800031f4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031f6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031fa:	85d2                	mv	a1,s4
    800031fc:	01048513          	addi	a0,s1,16
    80003200:	00001097          	auipc	ra,0x1
    80003204:	496080e7          	jalr	1174(ra) # 80004696 <initsleeplock>
    bcache.head.next->prev = b;
    80003208:	2b893783          	ld	a5,696(s2)
    8000320c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000320e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003212:	45848493          	addi	s1,s1,1112
    80003216:	fd349de3          	bne	s1,s3,800031f0 <binit+0x54>
  }
}
    8000321a:	70a2                	ld	ra,40(sp)
    8000321c:	7402                	ld	s0,32(sp)
    8000321e:	64e2                	ld	s1,24(sp)
    80003220:	6942                	ld	s2,16(sp)
    80003222:	69a2                	ld	s3,8(sp)
    80003224:	6a02                	ld	s4,0(sp)
    80003226:	6145                	addi	sp,sp,48
    80003228:	8082                	ret

000000008000322a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000322a:	7179                	addi	sp,sp,-48
    8000322c:	f406                	sd	ra,40(sp)
    8000322e:	f022                	sd	s0,32(sp)
    80003230:	ec26                	sd	s1,24(sp)
    80003232:	e84a                	sd	s2,16(sp)
    80003234:	e44e                	sd	s3,8(sp)
    80003236:	1800                	addi	s0,sp,48
    80003238:	892a                	mv	s2,a0
    8000323a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000323c:	00014517          	auipc	a0,0x14
    80003240:	17c50513          	addi	a0,a0,380 # 800173b8 <bcache>
    80003244:	ffffe097          	auipc	ra,0xffffe
    80003248:	98e080e7          	jalr	-1650(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000324c:	0001c497          	auipc	s1,0x1c
    80003250:	4244b483          	ld	s1,1060(s1) # 8001f670 <bcache+0x82b8>
    80003254:	0001c797          	auipc	a5,0x1c
    80003258:	3cc78793          	addi	a5,a5,972 # 8001f620 <bcache+0x8268>
    8000325c:	02f48f63          	beq	s1,a5,8000329a <bread+0x70>
    80003260:	873e                	mv	a4,a5
    80003262:	a021                	j	8000326a <bread+0x40>
    80003264:	68a4                	ld	s1,80(s1)
    80003266:	02e48a63          	beq	s1,a4,8000329a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000326a:	449c                	lw	a5,8(s1)
    8000326c:	ff279ce3          	bne	a5,s2,80003264 <bread+0x3a>
    80003270:	44dc                	lw	a5,12(s1)
    80003272:	ff3799e3          	bne	a5,s3,80003264 <bread+0x3a>
      b->refcnt++;
    80003276:	40bc                	lw	a5,64(s1)
    80003278:	2785                	addiw	a5,a5,1
    8000327a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000327c:	00014517          	auipc	a0,0x14
    80003280:	13c50513          	addi	a0,a0,316 # 800173b8 <bcache>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	a02080e7          	jalr	-1534(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    8000328c:	01048513          	addi	a0,s1,16
    80003290:	00001097          	auipc	ra,0x1
    80003294:	440080e7          	jalr	1088(ra) # 800046d0 <acquiresleep>
      return b;
    80003298:	a8b9                	j	800032f6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000329a:	0001c497          	auipc	s1,0x1c
    8000329e:	3ce4b483          	ld	s1,974(s1) # 8001f668 <bcache+0x82b0>
    800032a2:	0001c797          	auipc	a5,0x1c
    800032a6:	37e78793          	addi	a5,a5,894 # 8001f620 <bcache+0x8268>
    800032aa:	00f48863          	beq	s1,a5,800032ba <bread+0x90>
    800032ae:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032b0:	40bc                	lw	a5,64(s1)
    800032b2:	cf81                	beqz	a5,800032ca <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032b4:	64a4                	ld	s1,72(s1)
    800032b6:	fee49de3          	bne	s1,a4,800032b0 <bread+0x86>
  panic("bget: no buffers");
    800032ba:	00005517          	auipc	a0,0x5
    800032be:	27650513          	addi	a0,a0,630 # 80008530 <syscalls+0xe0>
    800032c2:	ffffd097          	auipc	ra,0xffffd
    800032c6:	27a080e7          	jalr	634(ra) # 8000053c <panic>
      b->dev = dev;
    800032ca:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032ce:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032d2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032d6:	4785                	li	a5,1
    800032d8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032da:	00014517          	auipc	a0,0x14
    800032de:	0de50513          	addi	a0,a0,222 # 800173b8 <bcache>
    800032e2:	ffffe097          	auipc	ra,0xffffe
    800032e6:	9a4080e7          	jalr	-1628(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800032ea:	01048513          	addi	a0,s1,16
    800032ee:	00001097          	auipc	ra,0x1
    800032f2:	3e2080e7          	jalr	994(ra) # 800046d0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032f6:	409c                	lw	a5,0(s1)
    800032f8:	cb89                	beqz	a5,8000330a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032fa:	8526                	mv	a0,s1
    800032fc:	70a2                	ld	ra,40(sp)
    800032fe:	7402                	ld	s0,32(sp)
    80003300:	64e2                	ld	s1,24(sp)
    80003302:	6942                	ld	s2,16(sp)
    80003304:	69a2                	ld	s3,8(sp)
    80003306:	6145                	addi	sp,sp,48
    80003308:	8082                	ret
    virtio_disk_rw(b, 0);
    8000330a:	4581                	li	a1,0
    8000330c:	8526                	mv	a0,s1
    8000330e:	00003097          	auipc	ra,0x3
    80003312:	f94080e7          	jalr	-108(ra) # 800062a2 <virtio_disk_rw>
    b->valid = 1;
    80003316:	4785                	li	a5,1
    80003318:	c09c                	sw	a5,0(s1)
  return b;
    8000331a:	b7c5                	j	800032fa <bread+0xd0>

000000008000331c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000331c:	1101                	addi	sp,sp,-32
    8000331e:	ec06                	sd	ra,24(sp)
    80003320:	e822                	sd	s0,16(sp)
    80003322:	e426                	sd	s1,8(sp)
    80003324:	1000                	addi	s0,sp,32
    80003326:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003328:	0541                	addi	a0,a0,16
    8000332a:	00001097          	auipc	ra,0x1
    8000332e:	440080e7          	jalr	1088(ra) # 8000476a <holdingsleep>
    80003332:	cd01                	beqz	a0,8000334a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003334:	4585                	li	a1,1
    80003336:	8526                	mv	a0,s1
    80003338:	00003097          	auipc	ra,0x3
    8000333c:	f6a080e7          	jalr	-150(ra) # 800062a2 <virtio_disk_rw>
}
    80003340:	60e2                	ld	ra,24(sp)
    80003342:	6442                	ld	s0,16(sp)
    80003344:	64a2                	ld	s1,8(sp)
    80003346:	6105                	addi	sp,sp,32
    80003348:	8082                	ret
    panic("bwrite");
    8000334a:	00005517          	auipc	a0,0x5
    8000334e:	1fe50513          	addi	a0,a0,510 # 80008548 <syscalls+0xf8>
    80003352:	ffffd097          	auipc	ra,0xffffd
    80003356:	1ea080e7          	jalr	490(ra) # 8000053c <panic>

000000008000335a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000335a:	1101                	addi	sp,sp,-32
    8000335c:	ec06                	sd	ra,24(sp)
    8000335e:	e822                	sd	s0,16(sp)
    80003360:	e426                	sd	s1,8(sp)
    80003362:	e04a                	sd	s2,0(sp)
    80003364:	1000                	addi	s0,sp,32
    80003366:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003368:	01050913          	addi	s2,a0,16
    8000336c:	854a                	mv	a0,s2
    8000336e:	00001097          	auipc	ra,0x1
    80003372:	3fc080e7          	jalr	1020(ra) # 8000476a <holdingsleep>
    80003376:	c925                	beqz	a0,800033e6 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003378:	854a                	mv	a0,s2
    8000337a:	00001097          	auipc	ra,0x1
    8000337e:	3ac080e7          	jalr	940(ra) # 80004726 <releasesleep>

  acquire(&bcache.lock);
    80003382:	00014517          	auipc	a0,0x14
    80003386:	03650513          	addi	a0,a0,54 # 800173b8 <bcache>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	848080e7          	jalr	-1976(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003392:	40bc                	lw	a5,64(s1)
    80003394:	37fd                	addiw	a5,a5,-1
    80003396:	0007871b          	sext.w	a4,a5
    8000339a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000339c:	e71d                	bnez	a4,800033ca <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000339e:	68b8                	ld	a4,80(s1)
    800033a0:	64bc                	ld	a5,72(s1)
    800033a2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800033a4:	68b8                	ld	a4,80(s1)
    800033a6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033a8:	0001c797          	auipc	a5,0x1c
    800033ac:	01078793          	addi	a5,a5,16 # 8001f3b8 <bcache+0x8000>
    800033b0:	2b87b703          	ld	a4,696(a5)
    800033b4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033b6:	0001c717          	auipc	a4,0x1c
    800033ba:	26a70713          	addi	a4,a4,618 # 8001f620 <bcache+0x8268>
    800033be:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033c0:	2b87b703          	ld	a4,696(a5)
    800033c4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033c6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033ca:	00014517          	auipc	a0,0x14
    800033ce:	fee50513          	addi	a0,a0,-18 # 800173b8 <bcache>
    800033d2:	ffffe097          	auipc	ra,0xffffe
    800033d6:	8b4080e7          	jalr	-1868(ra) # 80000c86 <release>
}
    800033da:	60e2                	ld	ra,24(sp)
    800033dc:	6442                	ld	s0,16(sp)
    800033de:	64a2                	ld	s1,8(sp)
    800033e0:	6902                	ld	s2,0(sp)
    800033e2:	6105                	addi	sp,sp,32
    800033e4:	8082                	ret
    panic("brelse");
    800033e6:	00005517          	auipc	a0,0x5
    800033ea:	16a50513          	addi	a0,a0,362 # 80008550 <syscalls+0x100>
    800033ee:	ffffd097          	auipc	ra,0xffffd
    800033f2:	14e080e7          	jalr	334(ra) # 8000053c <panic>

00000000800033f6 <bpin>:

void
bpin(struct buf *b) {
    800033f6:	1101                	addi	sp,sp,-32
    800033f8:	ec06                	sd	ra,24(sp)
    800033fa:	e822                	sd	s0,16(sp)
    800033fc:	e426                	sd	s1,8(sp)
    800033fe:	1000                	addi	s0,sp,32
    80003400:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003402:	00014517          	auipc	a0,0x14
    80003406:	fb650513          	addi	a0,a0,-74 # 800173b8 <bcache>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	7c8080e7          	jalr	1992(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003412:	40bc                	lw	a5,64(s1)
    80003414:	2785                	addiw	a5,a5,1
    80003416:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003418:	00014517          	auipc	a0,0x14
    8000341c:	fa050513          	addi	a0,a0,-96 # 800173b8 <bcache>
    80003420:	ffffe097          	auipc	ra,0xffffe
    80003424:	866080e7          	jalr	-1946(ra) # 80000c86 <release>
}
    80003428:	60e2                	ld	ra,24(sp)
    8000342a:	6442                	ld	s0,16(sp)
    8000342c:	64a2                	ld	s1,8(sp)
    8000342e:	6105                	addi	sp,sp,32
    80003430:	8082                	ret

0000000080003432 <bunpin>:

void
bunpin(struct buf *b) {
    80003432:	1101                	addi	sp,sp,-32
    80003434:	ec06                	sd	ra,24(sp)
    80003436:	e822                	sd	s0,16(sp)
    80003438:	e426                	sd	s1,8(sp)
    8000343a:	1000                	addi	s0,sp,32
    8000343c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000343e:	00014517          	auipc	a0,0x14
    80003442:	f7a50513          	addi	a0,a0,-134 # 800173b8 <bcache>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	78c080e7          	jalr	1932(ra) # 80000bd2 <acquire>
  b->refcnt--;
    8000344e:	40bc                	lw	a5,64(s1)
    80003450:	37fd                	addiw	a5,a5,-1
    80003452:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003454:	00014517          	auipc	a0,0x14
    80003458:	f6450513          	addi	a0,a0,-156 # 800173b8 <bcache>
    8000345c:	ffffe097          	auipc	ra,0xffffe
    80003460:	82a080e7          	jalr	-2006(ra) # 80000c86 <release>
}
    80003464:	60e2                	ld	ra,24(sp)
    80003466:	6442                	ld	s0,16(sp)
    80003468:	64a2                	ld	s1,8(sp)
    8000346a:	6105                	addi	sp,sp,32
    8000346c:	8082                	ret

000000008000346e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000346e:	1101                	addi	sp,sp,-32
    80003470:	ec06                	sd	ra,24(sp)
    80003472:	e822                	sd	s0,16(sp)
    80003474:	e426                	sd	s1,8(sp)
    80003476:	e04a                	sd	s2,0(sp)
    80003478:	1000                	addi	s0,sp,32
    8000347a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000347c:	00d5d59b          	srliw	a1,a1,0xd
    80003480:	0001c797          	auipc	a5,0x1c
    80003484:	6147a783          	lw	a5,1556(a5) # 8001fa94 <sb+0x1c>
    80003488:	9dbd                	addw	a1,a1,a5
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	da0080e7          	jalr	-608(ra) # 8000322a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003492:	0074f713          	andi	a4,s1,7
    80003496:	4785                	li	a5,1
    80003498:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000349c:	14ce                	slli	s1,s1,0x33
    8000349e:	90d9                	srli	s1,s1,0x36
    800034a0:	00950733          	add	a4,a0,s1
    800034a4:	05874703          	lbu	a4,88(a4)
    800034a8:	00e7f6b3          	and	a3,a5,a4
    800034ac:	c69d                	beqz	a3,800034da <bfree+0x6c>
    800034ae:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034b0:	94aa                	add	s1,s1,a0
    800034b2:	fff7c793          	not	a5,a5
    800034b6:	8f7d                	and	a4,a4,a5
    800034b8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800034bc:	00001097          	auipc	ra,0x1
    800034c0:	0f6080e7          	jalr	246(ra) # 800045b2 <log_write>
  brelse(bp);
    800034c4:	854a                	mv	a0,s2
    800034c6:	00000097          	auipc	ra,0x0
    800034ca:	e94080e7          	jalr	-364(ra) # 8000335a <brelse>
}
    800034ce:	60e2                	ld	ra,24(sp)
    800034d0:	6442                	ld	s0,16(sp)
    800034d2:	64a2                	ld	s1,8(sp)
    800034d4:	6902                	ld	s2,0(sp)
    800034d6:	6105                	addi	sp,sp,32
    800034d8:	8082                	ret
    panic("freeing free block");
    800034da:	00005517          	auipc	a0,0x5
    800034de:	07e50513          	addi	a0,a0,126 # 80008558 <syscalls+0x108>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	05a080e7          	jalr	90(ra) # 8000053c <panic>

00000000800034ea <balloc>:
{
    800034ea:	711d                	addi	sp,sp,-96
    800034ec:	ec86                	sd	ra,88(sp)
    800034ee:	e8a2                	sd	s0,80(sp)
    800034f0:	e4a6                	sd	s1,72(sp)
    800034f2:	e0ca                	sd	s2,64(sp)
    800034f4:	fc4e                	sd	s3,56(sp)
    800034f6:	f852                	sd	s4,48(sp)
    800034f8:	f456                	sd	s5,40(sp)
    800034fa:	f05a                	sd	s6,32(sp)
    800034fc:	ec5e                	sd	s7,24(sp)
    800034fe:	e862                	sd	s8,16(sp)
    80003500:	e466                	sd	s9,8(sp)
    80003502:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003504:	0001c797          	auipc	a5,0x1c
    80003508:	5787a783          	lw	a5,1400(a5) # 8001fa7c <sb+0x4>
    8000350c:	cff5                	beqz	a5,80003608 <balloc+0x11e>
    8000350e:	8baa                	mv	s7,a0
    80003510:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003512:	0001cb17          	auipc	s6,0x1c
    80003516:	566b0b13          	addi	s6,s6,1382 # 8001fa78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000351a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000351c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000351e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003520:	6c89                	lui	s9,0x2
    80003522:	a061                	j	800035aa <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003524:	97ca                	add	a5,a5,s2
    80003526:	8e55                	or	a2,a2,a3
    80003528:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000352c:	854a                	mv	a0,s2
    8000352e:	00001097          	auipc	ra,0x1
    80003532:	084080e7          	jalr	132(ra) # 800045b2 <log_write>
        brelse(bp);
    80003536:	854a                	mv	a0,s2
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	e22080e7          	jalr	-478(ra) # 8000335a <brelse>
  bp = bread(dev, bno);
    80003540:	85a6                	mv	a1,s1
    80003542:	855e                	mv	a0,s7
    80003544:	00000097          	auipc	ra,0x0
    80003548:	ce6080e7          	jalr	-794(ra) # 8000322a <bread>
    8000354c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000354e:	40000613          	li	a2,1024
    80003552:	4581                	li	a1,0
    80003554:	05850513          	addi	a0,a0,88
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	776080e7          	jalr	1910(ra) # 80000cce <memset>
  log_write(bp);
    80003560:	854a                	mv	a0,s2
    80003562:	00001097          	auipc	ra,0x1
    80003566:	050080e7          	jalr	80(ra) # 800045b2 <log_write>
  brelse(bp);
    8000356a:	854a                	mv	a0,s2
    8000356c:	00000097          	auipc	ra,0x0
    80003570:	dee080e7          	jalr	-530(ra) # 8000335a <brelse>
}
    80003574:	8526                	mv	a0,s1
    80003576:	60e6                	ld	ra,88(sp)
    80003578:	6446                	ld	s0,80(sp)
    8000357a:	64a6                	ld	s1,72(sp)
    8000357c:	6906                	ld	s2,64(sp)
    8000357e:	79e2                	ld	s3,56(sp)
    80003580:	7a42                	ld	s4,48(sp)
    80003582:	7aa2                	ld	s5,40(sp)
    80003584:	7b02                	ld	s6,32(sp)
    80003586:	6be2                	ld	s7,24(sp)
    80003588:	6c42                	ld	s8,16(sp)
    8000358a:	6ca2                	ld	s9,8(sp)
    8000358c:	6125                	addi	sp,sp,96
    8000358e:	8082                	ret
    brelse(bp);
    80003590:	854a                	mv	a0,s2
    80003592:	00000097          	auipc	ra,0x0
    80003596:	dc8080e7          	jalr	-568(ra) # 8000335a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000359a:	015c87bb          	addw	a5,s9,s5
    8000359e:	00078a9b          	sext.w	s5,a5
    800035a2:	004b2703          	lw	a4,4(s6)
    800035a6:	06eaf163          	bgeu	s5,a4,80003608 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800035aa:	41fad79b          	sraiw	a5,s5,0x1f
    800035ae:	0137d79b          	srliw	a5,a5,0x13
    800035b2:	015787bb          	addw	a5,a5,s5
    800035b6:	40d7d79b          	sraiw	a5,a5,0xd
    800035ba:	01cb2583          	lw	a1,28(s6)
    800035be:	9dbd                	addw	a1,a1,a5
    800035c0:	855e                	mv	a0,s7
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	c68080e7          	jalr	-920(ra) # 8000322a <bread>
    800035ca:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035cc:	004b2503          	lw	a0,4(s6)
    800035d0:	000a849b          	sext.w	s1,s5
    800035d4:	8762                	mv	a4,s8
    800035d6:	faa4fde3          	bgeu	s1,a0,80003590 <balloc+0xa6>
      m = 1 << (bi % 8);
    800035da:	00777693          	andi	a3,a4,7
    800035de:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035e2:	41f7579b          	sraiw	a5,a4,0x1f
    800035e6:	01d7d79b          	srliw	a5,a5,0x1d
    800035ea:	9fb9                	addw	a5,a5,a4
    800035ec:	4037d79b          	sraiw	a5,a5,0x3
    800035f0:	00f90633          	add	a2,s2,a5
    800035f4:	05864603          	lbu	a2,88(a2)
    800035f8:	00c6f5b3          	and	a1,a3,a2
    800035fc:	d585                	beqz	a1,80003524 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035fe:	2705                	addiw	a4,a4,1
    80003600:	2485                	addiw	s1,s1,1
    80003602:	fd471ae3          	bne	a4,s4,800035d6 <balloc+0xec>
    80003606:	b769                	j	80003590 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003608:	00005517          	auipc	a0,0x5
    8000360c:	f6850513          	addi	a0,a0,-152 # 80008570 <syscalls+0x120>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	f76080e7          	jalr	-138(ra) # 80000586 <printf>
  return 0;
    80003618:	4481                	li	s1,0
    8000361a:	bfa9                	j	80003574 <balloc+0x8a>

000000008000361c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000361c:	7179                	addi	sp,sp,-48
    8000361e:	f406                	sd	ra,40(sp)
    80003620:	f022                	sd	s0,32(sp)
    80003622:	ec26                	sd	s1,24(sp)
    80003624:	e84a                	sd	s2,16(sp)
    80003626:	e44e                	sd	s3,8(sp)
    80003628:	e052                	sd	s4,0(sp)
    8000362a:	1800                	addi	s0,sp,48
    8000362c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000362e:	47ad                	li	a5,11
    80003630:	02b7e863          	bltu	a5,a1,80003660 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003634:	02059793          	slli	a5,a1,0x20
    80003638:	01e7d593          	srli	a1,a5,0x1e
    8000363c:	00b504b3          	add	s1,a0,a1
    80003640:	0504a903          	lw	s2,80(s1)
    80003644:	06091e63          	bnez	s2,800036c0 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003648:	4108                	lw	a0,0(a0)
    8000364a:	00000097          	auipc	ra,0x0
    8000364e:	ea0080e7          	jalr	-352(ra) # 800034ea <balloc>
    80003652:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003656:	06090563          	beqz	s2,800036c0 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000365a:	0524a823          	sw	s2,80(s1)
    8000365e:	a08d                	j	800036c0 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003660:	ff45849b          	addiw	s1,a1,-12
    80003664:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003668:	0ff00793          	li	a5,255
    8000366c:	08e7e563          	bltu	a5,a4,800036f6 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003670:	08052903          	lw	s2,128(a0)
    80003674:	00091d63          	bnez	s2,8000368e <bmap+0x72>
      addr = balloc(ip->dev);
    80003678:	4108                	lw	a0,0(a0)
    8000367a:	00000097          	auipc	ra,0x0
    8000367e:	e70080e7          	jalr	-400(ra) # 800034ea <balloc>
    80003682:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003686:	02090d63          	beqz	s2,800036c0 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000368a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000368e:	85ca                	mv	a1,s2
    80003690:	0009a503          	lw	a0,0(s3)
    80003694:	00000097          	auipc	ra,0x0
    80003698:	b96080e7          	jalr	-1130(ra) # 8000322a <bread>
    8000369c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000369e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036a2:	02049713          	slli	a4,s1,0x20
    800036a6:	01e75593          	srli	a1,a4,0x1e
    800036aa:	00b784b3          	add	s1,a5,a1
    800036ae:	0004a903          	lw	s2,0(s1)
    800036b2:	02090063          	beqz	s2,800036d2 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036b6:	8552                	mv	a0,s4
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	ca2080e7          	jalr	-862(ra) # 8000335a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036c0:	854a                	mv	a0,s2
    800036c2:	70a2                	ld	ra,40(sp)
    800036c4:	7402                	ld	s0,32(sp)
    800036c6:	64e2                	ld	s1,24(sp)
    800036c8:	6942                	ld	s2,16(sp)
    800036ca:	69a2                	ld	s3,8(sp)
    800036cc:	6a02                	ld	s4,0(sp)
    800036ce:	6145                	addi	sp,sp,48
    800036d0:	8082                	ret
      addr = balloc(ip->dev);
    800036d2:	0009a503          	lw	a0,0(s3)
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	e14080e7          	jalr	-492(ra) # 800034ea <balloc>
    800036de:	0005091b          	sext.w	s2,a0
      if(addr){
    800036e2:	fc090ae3          	beqz	s2,800036b6 <bmap+0x9a>
        a[bn] = addr;
    800036e6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800036ea:	8552                	mv	a0,s4
    800036ec:	00001097          	auipc	ra,0x1
    800036f0:	ec6080e7          	jalr	-314(ra) # 800045b2 <log_write>
    800036f4:	b7c9                	j	800036b6 <bmap+0x9a>
  panic("bmap: out of range");
    800036f6:	00005517          	auipc	a0,0x5
    800036fa:	e9250513          	addi	a0,a0,-366 # 80008588 <syscalls+0x138>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	e3e080e7          	jalr	-450(ra) # 8000053c <panic>

0000000080003706 <iget>:
{
    80003706:	7179                	addi	sp,sp,-48
    80003708:	f406                	sd	ra,40(sp)
    8000370a:	f022                	sd	s0,32(sp)
    8000370c:	ec26                	sd	s1,24(sp)
    8000370e:	e84a                	sd	s2,16(sp)
    80003710:	e44e                	sd	s3,8(sp)
    80003712:	e052                	sd	s4,0(sp)
    80003714:	1800                	addi	s0,sp,48
    80003716:	89aa                	mv	s3,a0
    80003718:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000371a:	0001c517          	auipc	a0,0x1c
    8000371e:	37e50513          	addi	a0,a0,894 # 8001fa98 <itable>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	4b0080e7          	jalr	1200(ra) # 80000bd2 <acquire>
  empty = 0;
    8000372a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000372c:	0001c497          	auipc	s1,0x1c
    80003730:	38448493          	addi	s1,s1,900 # 8001fab0 <itable+0x18>
    80003734:	0001e697          	auipc	a3,0x1e
    80003738:	e0c68693          	addi	a3,a3,-500 # 80021540 <log>
    8000373c:	a039                	j	8000374a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000373e:	02090b63          	beqz	s2,80003774 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003742:	08848493          	addi	s1,s1,136
    80003746:	02d48a63          	beq	s1,a3,8000377a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000374a:	449c                	lw	a5,8(s1)
    8000374c:	fef059e3          	blez	a5,8000373e <iget+0x38>
    80003750:	4098                	lw	a4,0(s1)
    80003752:	ff3716e3          	bne	a4,s3,8000373e <iget+0x38>
    80003756:	40d8                	lw	a4,4(s1)
    80003758:	ff4713e3          	bne	a4,s4,8000373e <iget+0x38>
      ip->ref++;
    8000375c:	2785                	addiw	a5,a5,1
    8000375e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003760:	0001c517          	auipc	a0,0x1c
    80003764:	33850513          	addi	a0,a0,824 # 8001fa98 <itable>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	51e080e7          	jalr	1310(ra) # 80000c86 <release>
      return ip;
    80003770:	8926                	mv	s2,s1
    80003772:	a03d                	j	800037a0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003774:	f7f9                	bnez	a5,80003742 <iget+0x3c>
    80003776:	8926                	mv	s2,s1
    80003778:	b7e9                	j	80003742 <iget+0x3c>
  if(empty == 0)
    8000377a:	02090c63          	beqz	s2,800037b2 <iget+0xac>
  ip->dev = dev;
    8000377e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003782:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003786:	4785                	li	a5,1
    80003788:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000378c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003790:	0001c517          	auipc	a0,0x1c
    80003794:	30850513          	addi	a0,a0,776 # 8001fa98 <itable>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	4ee080e7          	jalr	1262(ra) # 80000c86 <release>
}
    800037a0:	854a                	mv	a0,s2
    800037a2:	70a2                	ld	ra,40(sp)
    800037a4:	7402                	ld	s0,32(sp)
    800037a6:	64e2                	ld	s1,24(sp)
    800037a8:	6942                	ld	s2,16(sp)
    800037aa:	69a2                	ld	s3,8(sp)
    800037ac:	6a02                	ld	s4,0(sp)
    800037ae:	6145                	addi	sp,sp,48
    800037b0:	8082                	ret
    panic("iget: no inodes");
    800037b2:	00005517          	auipc	a0,0x5
    800037b6:	dee50513          	addi	a0,a0,-530 # 800085a0 <syscalls+0x150>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	d82080e7          	jalr	-638(ra) # 8000053c <panic>

00000000800037c2 <fsinit>:
fsinit(int dev) {
    800037c2:	7179                	addi	sp,sp,-48
    800037c4:	f406                	sd	ra,40(sp)
    800037c6:	f022                	sd	s0,32(sp)
    800037c8:	ec26                	sd	s1,24(sp)
    800037ca:	e84a                	sd	s2,16(sp)
    800037cc:	e44e                	sd	s3,8(sp)
    800037ce:	1800                	addi	s0,sp,48
    800037d0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037d2:	4585                	li	a1,1
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	a56080e7          	jalr	-1450(ra) # 8000322a <bread>
    800037dc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037de:	0001c997          	auipc	s3,0x1c
    800037e2:	29a98993          	addi	s3,s3,666 # 8001fa78 <sb>
    800037e6:	02000613          	li	a2,32
    800037ea:	05850593          	addi	a1,a0,88
    800037ee:	854e                	mv	a0,s3
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	53a080e7          	jalr	1338(ra) # 80000d2a <memmove>
  brelse(bp);
    800037f8:	8526                	mv	a0,s1
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	b60080e7          	jalr	-1184(ra) # 8000335a <brelse>
  if(sb.magic != FSMAGIC)
    80003802:	0009a703          	lw	a4,0(s3)
    80003806:	102037b7          	lui	a5,0x10203
    8000380a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000380e:	02f71263          	bne	a4,a5,80003832 <fsinit+0x70>
  initlog(dev, &sb);
    80003812:	0001c597          	auipc	a1,0x1c
    80003816:	26658593          	addi	a1,a1,614 # 8001fa78 <sb>
    8000381a:	854a                	mv	a0,s2
    8000381c:	00001097          	auipc	ra,0x1
    80003820:	b2c080e7          	jalr	-1236(ra) # 80004348 <initlog>
}
    80003824:	70a2                	ld	ra,40(sp)
    80003826:	7402                	ld	s0,32(sp)
    80003828:	64e2                	ld	s1,24(sp)
    8000382a:	6942                	ld	s2,16(sp)
    8000382c:	69a2                	ld	s3,8(sp)
    8000382e:	6145                	addi	sp,sp,48
    80003830:	8082                	ret
    panic("invalid file system");
    80003832:	00005517          	auipc	a0,0x5
    80003836:	d7e50513          	addi	a0,a0,-642 # 800085b0 <syscalls+0x160>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	d02080e7          	jalr	-766(ra) # 8000053c <panic>

0000000080003842 <iinit>:
{
    80003842:	7179                	addi	sp,sp,-48
    80003844:	f406                	sd	ra,40(sp)
    80003846:	f022                	sd	s0,32(sp)
    80003848:	ec26                	sd	s1,24(sp)
    8000384a:	e84a                	sd	s2,16(sp)
    8000384c:	e44e                	sd	s3,8(sp)
    8000384e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003850:	00005597          	auipc	a1,0x5
    80003854:	d7858593          	addi	a1,a1,-648 # 800085c8 <syscalls+0x178>
    80003858:	0001c517          	auipc	a0,0x1c
    8000385c:	24050513          	addi	a0,a0,576 # 8001fa98 <itable>
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	2e2080e7          	jalr	738(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003868:	0001c497          	auipc	s1,0x1c
    8000386c:	25848493          	addi	s1,s1,600 # 8001fac0 <itable+0x28>
    80003870:	0001e997          	auipc	s3,0x1e
    80003874:	ce098993          	addi	s3,s3,-800 # 80021550 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003878:	00005917          	auipc	s2,0x5
    8000387c:	d5890913          	addi	s2,s2,-680 # 800085d0 <syscalls+0x180>
    80003880:	85ca                	mv	a1,s2
    80003882:	8526                	mv	a0,s1
    80003884:	00001097          	auipc	ra,0x1
    80003888:	e12080e7          	jalr	-494(ra) # 80004696 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000388c:	08848493          	addi	s1,s1,136
    80003890:	ff3498e3          	bne	s1,s3,80003880 <iinit+0x3e>
}
    80003894:	70a2                	ld	ra,40(sp)
    80003896:	7402                	ld	s0,32(sp)
    80003898:	64e2                	ld	s1,24(sp)
    8000389a:	6942                	ld	s2,16(sp)
    8000389c:	69a2                	ld	s3,8(sp)
    8000389e:	6145                	addi	sp,sp,48
    800038a0:	8082                	ret

00000000800038a2 <ialloc>:
{
    800038a2:	7139                	addi	sp,sp,-64
    800038a4:	fc06                	sd	ra,56(sp)
    800038a6:	f822                	sd	s0,48(sp)
    800038a8:	f426                	sd	s1,40(sp)
    800038aa:	f04a                	sd	s2,32(sp)
    800038ac:	ec4e                	sd	s3,24(sp)
    800038ae:	e852                	sd	s4,16(sp)
    800038b0:	e456                	sd	s5,8(sp)
    800038b2:	e05a                	sd	s6,0(sp)
    800038b4:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800038b6:	0001c717          	auipc	a4,0x1c
    800038ba:	1ce72703          	lw	a4,462(a4) # 8001fa84 <sb+0xc>
    800038be:	4785                	li	a5,1
    800038c0:	04e7f863          	bgeu	a5,a4,80003910 <ialloc+0x6e>
    800038c4:	8aaa                	mv	s5,a0
    800038c6:	8b2e                	mv	s6,a1
    800038c8:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038ca:	0001ca17          	auipc	s4,0x1c
    800038ce:	1aea0a13          	addi	s4,s4,430 # 8001fa78 <sb>
    800038d2:	00495593          	srli	a1,s2,0x4
    800038d6:	018a2783          	lw	a5,24(s4)
    800038da:	9dbd                	addw	a1,a1,a5
    800038dc:	8556                	mv	a0,s5
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	94c080e7          	jalr	-1716(ra) # 8000322a <bread>
    800038e6:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038e8:	05850993          	addi	s3,a0,88
    800038ec:	00f97793          	andi	a5,s2,15
    800038f0:	079a                	slli	a5,a5,0x6
    800038f2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038f4:	00099783          	lh	a5,0(s3)
    800038f8:	cf9d                	beqz	a5,80003936 <ialloc+0x94>
    brelse(bp);
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	a60080e7          	jalr	-1440(ra) # 8000335a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003902:	0905                	addi	s2,s2,1
    80003904:	00ca2703          	lw	a4,12(s4)
    80003908:	0009079b          	sext.w	a5,s2
    8000390c:	fce7e3e3          	bltu	a5,a4,800038d2 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003910:	00005517          	auipc	a0,0x5
    80003914:	cc850513          	addi	a0,a0,-824 # 800085d8 <syscalls+0x188>
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	c6e080e7          	jalr	-914(ra) # 80000586 <printf>
  return 0;
    80003920:	4501                	li	a0,0
}
    80003922:	70e2                	ld	ra,56(sp)
    80003924:	7442                	ld	s0,48(sp)
    80003926:	74a2                	ld	s1,40(sp)
    80003928:	7902                	ld	s2,32(sp)
    8000392a:	69e2                	ld	s3,24(sp)
    8000392c:	6a42                	ld	s4,16(sp)
    8000392e:	6aa2                	ld	s5,8(sp)
    80003930:	6b02                	ld	s6,0(sp)
    80003932:	6121                	addi	sp,sp,64
    80003934:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003936:	04000613          	li	a2,64
    8000393a:	4581                	li	a1,0
    8000393c:	854e                	mv	a0,s3
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	390080e7          	jalr	912(ra) # 80000cce <memset>
      dip->type = type;
    80003946:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000394a:	8526                	mv	a0,s1
    8000394c:	00001097          	auipc	ra,0x1
    80003950:	c66080e7          	jalr	-922(ra) # 800045b2 <log_write>
      brelse(bp);
    80003954:	8526                	mv	a0,s1
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	a04080e7          	jalr	-1532(ra) # 8000335a <brelse>
      return iget(dev, inum);
    8000395e:	0009059b          	sext.w	a1,s2
    80003962:	8556                	mv	a0,s5
    80003964:	00000097          	auipc	ra,0x0
    80003968:	da2080e7          	jalr	-606(ra) # 80003706 <iget>
    8000396c:	bf5d                	j	80003922 <ialloc+0x80>

000000008000396e <iupdate>:
{
    8000396e:	1101                	addi	sp,sp,-32
    80003970:	ec06                	sd	ra,24(sp)
    80003972:	e822                	sd	s0,16(sp)
    80003974:	e426                	sd	s1,8(sp)
    80003976:	e04a                	sd	s2,0(sp)
    80003978:	1000                	addi	s0,sp,32
    8000397a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000397c:	415c                	lw	a5,4(a0)
    8000397e:	0047d79b          	srliw	a5,a5,0x4
    80003982:	0001c597          	auipc	a1,0x1c
    80003986:	10e5a583          	lw	a1,270(a1) # 8001fa90 <sb+0x18>
    8000398a:	9dbd                	addw	a1,a1,a5
    8000398c:	4108                	lw	a0,0(a0)
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	89c080e7          	jalr	-1892(ra) # 8000322a <bread>
    80003996:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003998:	05850793          	addi	a5,a0,88
    8000399c:	40d8                	lw	a4,4(s1)
    8000399e:	8b3d                	andi	a4,a4,15
    800039a0:	071a                	slli	a4,a4,0x6
    800039a2:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800039a4:	04449703          	lh	a4,68(s1)
    800039a8:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800039ac:	04649703          	lh	a4,70(s1)
    800039b0:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800039b4:	04849703          	lh	a4,72(s1)
    800039b8:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800039bc:	04a49703          	lh	a4,74(s1)
    800039c0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800039c4:	44f8                	lw	a4,76(s1)
    800039c6:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039c8:	03400613          	li	a2,52
    800039cc:	05048593          	addi	a1,s1,80
    800039d0:	00c78513          	addi	a0,a5,12
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	356080e7          	jalr	854(ra) # 80000d2a <memmove>
  log_write(bp);
    800039dc:	854a                	mv	a0,s2
    800039de:	00001097          	auipc	ra,0x1
    800039e2:	bd4080e7          	jalr	-1068(ra) # 800045b2 <log_write>
  brelse(bp);
    800039e6:	854a                	mv	a0,s2
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	972080e7          	jalr	-1678(ra) # 8000335a <brelse>
}
    800039f0:	60e2                	ld	ra,24(sp)
    800039f2:	6442                	ld	s0,16(sp)
    800039f4:	64a2                	ld	s1,8(sp)
    800039f6:	6902                	ld	s2,0(sp)
    800039f8:	6105                	addi	sp,sp,32
    800039fa:	8082                	ret

00000000800039fc <idup>:
{
    800039fc:	1101                	addi	sp,sp,-32
    800039fe:	ec06                	sd	ra,24(sp)
    80003a00:	e822                	sd	s0,16(sp)
    80003a02:	e426                	sd	s1,8(sp)
    80003a04:	1000                	addi	s0,sp,32
    80003a06:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a08:	0001c517          	auipc	a0,0x1c
    80003a0c:	09050513          	addi	a0,a0,144 # 8001fa98 <itable>
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	1c2080e7          	jalr	450(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003a18:	449c                	lw	a5,8(s1)
    80003a1a:	2785                	addiw	a5,a5,1
    80003a1c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a1e:	0001c517          	auipc	a0,0x1c
    80003a22:	07a50513          	addi	a0,a0,122 # 8001fa98 <itable>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	260080e7          	jalr	608(ra) # 80000c86 <release>
}
    80003a2e:	8526                	mv	a0,s1
    80003a30:	60e2                	ld	ra,24(sp)
    80003a32:	6442                	ld	s0,16(sp)
    80003a34:	64a2                	ld	s1,8(sp)
    80003a36:	6105                	addi	sp,sp,32
    80003a38:	8082                	ret

0000000080003a3a <ilock>:
{
    80003a3a:	1101                	addi	sp,sp,-32
    80003a3c:	ec06                	sd	ra,24(sp)
    80003a3e:	e822                	sd	s0,16(sp)
    80003a40:	e426                	sd	s1,8(sp)
    80003a42:	e04a                	sd	s2,0(sp)
    80003a44:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a46:	c115                	beqz	a0,80003a6a <ilock+0x30>
    80003a48:	84aa                	mv	s1,a0
    80003a4a:	451c                	lw	a5,8(a0)
    80003a4c:	00f05f63          	blez	a5,80003a6a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a50:	0541                	addi	a0,a0,16
    80003a52:	00001097          	auipc	ra,0x1
    80003a56:	c7e080e7          	jalr	-898(ra) # 800046d0 <acquiresleep>
  if(ip->valid == 0){
    80003a5a:	40bc                	lw	a5,64(s1)
    80003a5c:	cf99                	beqz	a5,80003a7a <ilock+0x40>
}
    80003a5e:	60e2                	ld	ra,24(sp)
    80003a60:	6442                	ld	s0,16(sp)
    80003a62:	64a2                	ld	s1,8(sp)
    80003a64:	6902                	ld	s2,0(sp)
    80003a66:	6105                	addi	sp,sp,32
    80003a68:	8082                	ret
    panic("ilock");
    80003a6a:	00005517          	auipc	a0,0x5
    80003a6e:	b8650513          	addi	a0,a0,-1146 # 800085f0 <syscalls+0x1a0>
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	aca080e7          	jalr	-1334(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a7a:	40dc                	lw	a5,4(s1)
    80003a7c:	0047d79b          	srliw	a5,a5,0x4
    80003a80:	0001c597          	auipc	a1,0x1c
    80003a84:	0105a583          	lw	a1,16(a1) # 8001fa90 <sb+0x18>
    80003a88:	9dbd                	addw	a1,a1,a5
    80003a8a:	4088                	lw	a0,0(s1)
    80003a8c:	fffff097          	auipc	ra,0xfffff
    80003a90:	79e080e7          	jalr	1950(ra) # 8000322a <bread>
    80003a94:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a96:	05850593          	addi	a1,a0,88
    80003a9a:	40dc                	lw	a5,4(s1)
    80003a9c:	8bbd                	andi	a5,a5,15
    80003a9e:	079a                	slli	a5,a5,0x6
    80003aa0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003aa2:	00059783          	lh	a5,0(a1)
    80003aa6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003aaa:	00259783          	lh	a5,2(a1)
    80003aae:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ab2:	00459783          	lh	a5,4(a1)
    80003ab6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003aba:	00659783          	lh	a5,6(a1)
    80003abe:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ac2:	459c                	lw	a5,8(a1)
    80003ac4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ac6:	03400613          	li	a2,52
    80003aca:	05b1                	addi	a1,a1,12
    80003acc:	05048513          	addi	a0,s1,80
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	25a080e7          	jalr	602(ra) # 80000d2a <memmove>
    brelse(bp);
    80003ad8:	854a                	mv	a0,s2
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	880080e7          	jalr	-1920(ra) # 8000335a <brelse>
    ip->valid = 1;
    80003ae2:	4785                	li	a5,1
    80003ae4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ae6:	04449783          	lh	a5,68(s1)
    80003aea:	fbb5                	bnez	a5,80003a5e <ilock+0x24>
      panic("ilock: no type");
    80003aec:	00005517          	auipc	a0,0x5
    80003af0:	b0c50513          	addi	a0,a0,-1268 # 800085f8 <syscalls+0x1a8>
    80003af4:	ffffd097          	auipc	ra,0xffffd
    80003af8:	a48080e7          	jalr	-1464(ra) # 8000053c <panic>

0000000080003afc <iunlock>:
{
    80003afc:	1101                	addi	sp,sp,-32
    80003afe:	ec06                	sd	ra,24(sp)
    80003b00:	e822                	sd	s0,16(sp)
    80003b02:	e426                	sd	s1,8(sp)
    80003b04:	e04a                	sd	s2,0(sp)
    80003b06:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b08:	c905                	beqz	a0,80003b38 <iunlock+0x3c>
    80003b0a:	84aa                	mv	s1,a0
    80003b0c:	01050913          	addi	s2,a0,16
    80003b10:	854a                	mv	a0,s2
    80003b12:	00001097          	auipc	ra,0x1
    80003b16:	c58080e7          	jalr	-936(ra) # 8000476a <holdingsleep>
    80003b1a:	cd19                	beqz	a0,80003b38 <iunlock+0x3c>
    80003b1c:	449c                	lw	a5,8(s1)
    80003b1e:	00f05d63          	blez	a5,80003b38 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b22:	854a                	mv	a0,s2
    80003b24:	00001097          	auipc	ra,0x1
    80003b28:	c02080e7          	jalr	-1022(ra) # 80004726 <releasesleep>
}
    80003b2c:	60e2                	ld	ra,24(sp)
    80003b2e:	6442                	ld	s0,16(sp)
    80003b30:	64a2                	ld	s1,8(sp)
    80003b32:	6902                	ld	s2,0(sp)
    80003b34:	6105                	addi	sp,sp,32
    80003b36:	8082                	ret
    panic("iunlock");
    80003b38:	00005517          	auipc	a0,0x5
    80003b3c:	ad050513          	addi	a0,a0,-1328 # 80008608 <syscalls+0x1b8>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	9fc080e7          	jalr	-1540(ra) # 8000053c <panic>

0000000080003b48 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b48:	7179                	addi	sp,sp,-48
    80003b4a:	f406                	sd	ra,40(sp)
    80003b4c:	f022                	sd	s0,32(sp)
    80003b4e:	ec26                	sd	s1,24(sp)
    80003b50:	e84a                	sd	s2,16(sp)
    80003b52:	e44e                	sd	s3,8(sp)
    80003b54:	e052                	sd	s4,0(sp)
    80003b56:	1800                	addi	s0,sp,48
    80003b58:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b5a:	05050493          	addi	s1,a0,80
    80003b5e:	08050913          	addi	s2,a0,128
    80003b62:	a021                	j	80003b6a <itrunc+0x22>
    80003b64:	0491                	addi	s1,s1,4
    80003b66:	01248d63          	beq	s1,s2,80003b80 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b6a:	408c                	lw	a1,0(s1)
    80003b6c:	dde5                	beqz	a1,80003b64 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b6e:	0009a503          	lw	a0,0(s3)
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	8fc080e7          	jalr	-1796(ra) # 8000346e <bfree>
      ip->addrs[i] = 0;
    80003b7a:	0004a023          	sw	zero,0(s1)
    80003b7e:	b7dd                	j	80003b64 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b80:	0809a583          	lw	a1,128(s3)
    80003b84:	e185                	bnez	a1,80003ba4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b86:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b8a:	854e                	mv	a0,s3
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	de2080e7          	jalr	-542(ra) # 8000396e <iupdate>
}
    80003b94:	70a2                	ld	ra,40(sp)
    80003b96:	7402                	ld	s0,32(sp)
    80003b98:	64e2                	ld	s1,24(sp)
    80003b9a:	6942                	ld	s2,16(sp)
    80003b9c:	69a2                	ld	s3,8(sp)
    80003b9e:	6a02                	ld	s4,0(sp)
    80003ba0:	6145                	addi	sp,sp,48
    80003ba2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ba4:	0009a503          	lw	a0,0(s3)
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	682080e7          	jalr	1666(ra) # 8000322a <bread>
    80003bb0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bb2:	05850493          	addi	s1,a0,88
    80003bb6:	45850913          	addi	s2,a0,1112
    80003bba:	a021                	j	80003bc2 <itrunc+0x7a>
    80003bbc:	0491                	addi	s1,s1,4
    80003bbe:	01248b63          	beq	s1,s2,80003bd4 <itrunc+0x8c>
      if(a[j])
    80003bc2:	408c                	lw	a1,0(s1)
    80003bc4:	dde5                	beqz	a1,80003bbc <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bc6:	0009a503          	lw	a0,0(s3)
    80003bca:	00000097          	auipc	ra,0x0
    80003bce:	8a4080e7          	jalr	-1884(ra) # 8000346e <bfree>
    80003bd2:	b7ed                	j	80003bbc <itrunc+0x74>
    brelse(bp);
    80003bd4:	8552                	mv	a0,s4
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	784080e7          	jalr	1924(ra) # 8000335a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bde:	0809a583          	lw	a1,128(s3)
    80003be2:	0009a503          	lw	a0,0(s3)
    80003be6:	00000097          	auipc	ra,0x0
    80003bea:	888080e7          	jalr	-1912(ra) # 8000346e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bee:	0809a023          	sw	zero,128(s3)
    80003bf2:	bf51                	j	80003b86 <itrunc+0x3e>

0000000080003bf4 <iput>:
{
    80003bf4:	1101                	addi	sp,sp,-32
    80003bf6:	ec06                	sd	ra,24(sp)
    80003bf8:	e822                	sd	s0,16(sp)
    80003bfa:	e426                	sd	s1,8(sp)
    80003bfc:	e04a                	sd	s2,0(sp)
    80003bfe:	1000                	addi	s0,sp,32
    80003c00:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c02:	0001c517          	auipc	a0,0x1c
    80003c06:	e9650513          	addi	a0,a0,-362 # 8001fa98 <itable>
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	fc8080e7          	jalr	-56(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c12:	4498                	lw	a4,8(s1)
    80003c14:	4785                	li	a5,1
    80003c16:	02f70363          	beq	a4,a5,80003c3c <iput+0x48>
  ip->ref--;
    80003c1a:	449c                	lw	a5,8(s1)
    80003c1c:	37fd                	addiw	a5,a5,-1
    80003c1e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c20:	0001c517          	auipc	a0,0x1c
    80003c24:	e7850513          	addi	a0,a0,-392 # 8001fa98 <itable>
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	05e080e7          	jalr	94(ra) # 80000c86 <release>
}
    80003c30:	60e2                	ld	ra,24(sp)
    80003c32:	6442                	ld	s0,16(sp)
    80003c34:	64a2                	ld	s1,8(sp)
    80003c36:	6902                	ld	s2,0(sp)
    80003c38:	6105                	addi	sp,sp,32
    80003c3a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c3c:	40bc                	lw	a5,64(s1)
    80003c3e:	dff1                	beqz	a5,80003c1a <iput+0x26>
    80003c40:	04a49783          	lh	a5,74(s1)
    80003c44:	fbf9                	bnez	a5,80003c1a <iput+0x26>
    acquiresleep(&ip->lock);
    80003c46:	01048913          	addi	s2,s1,16
    80003c4a:	854a                	mv	a0,s2
    80003c4c:	00001097          	auipc	ra,0x1
    80003c50:	a84080e7          	jalr	-1404(ra) # 800046d0 <acquiresleep>
    release(&itable.lock);
    80003c54:	0001c517          	auipc	a0,0x1c
    80003c58:	e4450513          	addi	a0,a0,-444 # 8001fa98 <itable>
    80003c5c:	ffffd097          	auipc	ra,0xffffd
    80003c60:	02a080e7          	jalr	42(ra) # 80000c86 <release>
    itrunc(ip);
    80003c64:	8526                	mv	a0,s1
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	ee2080e7          	jalr	-286(ra) # 80003b48 <itrunc>
    ip->type = 0;
    80003c6e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c72:	8526                	mv	a0,s1
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	cfa080e7          	jalr	-774(ra) # 8000396e <iupdate>
    ip->valid = 0;
    80003c7c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c80:	854a                	mv	a0,s2
    80003c82:	00001097          	auipc	ra,0x1
    80003c86:	aa4080e7          	jalr	-1372(ra) # 80004726 <releasesleep>
    acquire(&itable.lock);
    80003c8a:	0001c517          	auipc	a0,0x1c
    80003c8e:	e0e50513          	addi	a0,a0,-498 # 8001fa98 <itable>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	f40080e7          	jalr	-192(ra) # 80000bd2 <acquire>
    80003c9a:	b741                	j	80003c1a <iput+0x26>

0000000080003c9c <iunlockput>:
{
    80003c9c:	1101                	addi	sp,sp,-32
    80003c9e:	ec06                	sd	ra,24(sp)
    80003ca0:	e822                	sd	s0,16(sp)
    80003ca2:	e426                	sd	s1,8(sp)
    80003ca4:	1000                	addi	s0,sp,32
    80003ca6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ca8:	00000097          	auipc	ra,0x0
    80003cac:	e54080e7          	jalr	-428(ra) # 80003afc <iunlock>
  iput(ip);
    80003cb0:	8526                	mv	a0,s1
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	f42080e7          	jalr	-190(ra) # 80003bf4 <iput>
}
    80003cba:	60e2                	ld	ra,24(sp)
    80003cbc:	6442                	ld	s0,16(sp)
    80003cbe:	64a2                	ld	s1,8(sp)
    80003cc0:	6105                	addi	sp,sp,32
    80003cc2:	8082                	ret

0000000080003cc4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cc4:	1141                	addi	sp,sp,-16
    80003cc6:	e422                	sd	s0,8(sp)
    80003cc8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003cca:	411c                	lw	a5,0(a0)
    80003ccc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003cce:	415c                	lw	a5,4(a0)
    80003cd0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003cd2:	04451783          	lh	a5,68(a0)
    80003cd6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cda:	04a51783          	lh	a5,74(a0)
    80003cde:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ce2:	04c56783          	lwu	a5,76(a0)
    80003ce6:	e99c                	sd	a5,16(a1)
}
    80003ce8:	6422                	ld	s0,8(sp)
    80003cea:	0141                	addi	sp,sp,16
    80003cec:	8082                	ret

0000000080003cee <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cee:	457c                	lw	a5,76(a0)
    80003cf0:	0ed7e963          	bltu	a5,a3,80003de2 <readi+0xf4>
{
    80003cf4:	7159                	addi	sp,sp,-112
    80003cf6:	f486                	sd	ra,104(sp)
    80003cf8:	f0a2                	sd	s0,96(sp)
    80003cfa:	eca6                	sd	s1,88(sp)
    80003cfc:	e8ca                	sd	s2,80(sp)
    80003cfe:	e4ce                	sd	s3,72(sp)
    80003d00:	e0d2                	sd	s4,64(sp)
    80003d02:	fc56                	sd	s5,56(sp)
    80003d04:	f85a                	sd	s6,48(sp)
    80003d06:	f45e                	sd	s7,40(sp)
    80003d08:	f062                	sd	s8,32(sp)
    80003d0a:	ec66                	sd	s9,24(sp)
    80003d0c:	e86a                	sd	s10,16(sp)
    80003d0e:	e46e                	sd	s11,8(sp)
    80003d10:	1880                	addi	s0,sp,112
    80003d12:	8b2a                	mv	s6,a0
    80003d14:	8bae                	mv	s7,a1
    80003d16:	8a32                	mv	s4,a2
    80003d18:	84b6                	mv	s1,a3
    80003d1a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d1c:	9f35                	addw	a4,a4,a3
    return 0;
    80003d1e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d20:	0ad76063          	bltu	a4,a3,80003dc0 <readi+0xd2>
  if(off + n > ip->size)
    80003d24:	00e7f463          	bgeu	a5,a4,80003d2c <readi+0x3e>
    n = ip->size - off;
    80003d28:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d2c:	0a0a8963          	beqz	s5,80003dde <readi+0xf0>
    80003d30:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d32:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d36:	5c7d                	li	s8,-1
    80003d38:	a82d                	j	80003d72 <readi+0x84>
    80003d3a:	020d1d93          	slli	s11,s10,0x20
    80003d3e:	020ddd93          	srli	s11,s11,0x20
    80003d42:	05890613          	addi	a2,s2,88
    80003d46:	86ee                	mv	a3,s11
    80003d48:	963a                	add	a2,a2,a4
    80003d4a:	85d2                	mv	a1,s4
    80003d4c:	855e                	mv	a0,s7
    80003d4e:	ffffe097          	auipc	ra,0xffffe
    80003d52:	7be080e7          	jalr	1982(ra) # 8000250c <either_copyout>
    80003d56:	05850d63          	beq	a0,s8,80003db0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d5a:	854a                	mv	a0,s2
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	5fe080e7          	jalr	1534(ra) # 8000335a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d64:	013d09bb          	addw	s3,s10,s3
    80003d68:	009d04bb          	addw	s1,s10,s1
    80003d6c:	9a6e                	add	s4,s4,s11
    80003d6e:	0559f763          	bgeu	s3,s5,80003dbc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d72:	00a4d59b          	srliw	a1,s1,0xa
    80003d76:	855a                	mv	a0,s6
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	8a4080e7          	jalr	-1884(ra) # 8000361c <bmap>
    80003d80:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d84:	cd85                	beqz	a1,80003dbc <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d86:	000b2503          	lw	a0,0(s6)
    80003d8a:	fffff097          	auipc	ra,0xfffff
    80003d8e:	4a0080e7          	jalr	1184(ra) # 8000322a <bread>
    80003d92:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d94:	3ff4f713          	andi	a4,s1,1023
    80003d98:	40ec87bb          	subw	a5,s9,a4
    80003d9c:	413a86bb          	subw	a3,s5,s3
    80003da0:	8d3e                	mv	s10,a5
    80003da2:	2781                	sext.w	a5,a5
    80003da4:	0006861b          	sext.w	a2,a3
    80003da8:	f8f679e3          	bgeu	a2,a5,80003d3a <readi+0x4c>
    80003dac:	8d36                	mv	s10,a3
    80003dae:	b771                	j	80003d3a <readi+0x4c>
      brelse(bp);
    80003db0:	854a                	mv	a0,s2
    80003db2:	fffff097          	auipc	ra,0xfffff
    80003db6:	5a8080e7          	jalr	1448(ra) # 8000335a <brelse>
      tot = -1;
    80003dba:	59fd                	li	s3,-1
  }
  return tot;
    80003dbc:	0009851b          	sext.w	a0,s3
}
    80003dc0:	70a6                	ld	ra,104(sp)
    80003dc2:	7406                	ld	s0,96(sp)
    80003dc4:	64e6                	ld	s1,88(sp)
    80003dc6:	6946                	ld	s2,80(sp)
    80003dc8:	69a6                	ld	s3,72(sp)
    80003dca:	6a06                	ld	s4,64(sp)
    80003dcc:	7ae2                	ld	s5,56(sp)
    80003dce:	7b42                	ld	s6,48(sp)
    80003dd0:	7ba2                	ld	s7,40(sp)
    80003dd2:	7c02                	ld	s8,32(sp)
    80003dd4:	6ce2                	ld	s9,24(sp)
    80003dd6:	6d42                	ld	s10,16(sp)
    80003dd8:	6da2                	ld	s11,8(sp)
    80003dda:	6165                	addi	sp,sp,112
    80003ddc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dde:	89d6                	mv	s3,s5
    80003de0:	bff1                	j	80003dbc <readi+0xce>
    return 0;
    80003de2:	4501                	li	a0,0
}
    80003de4:	8082                	ret

0000000080003de6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003de6:	457c                	lw	a5,76(a0)
    80003de8:	10d7e863          	bltu	a5,a3,80003ef8 <writei+0x112>
{
    80003dec:	7159                	addi	sp,sp,-112
    80003dee:	f486                	sd	ra,104(sp)
    80003df0:	f0a2                	sd	s0,96(sp)
    80003df2:	eca6                	sd	s1,88(sp)
    80003df4:	e8ca                	sd	s2,80(sp)
    80003df6:	e4ce                	sd	s3,72(sp)
    80003df8:	e0d2                	sd	s4,64(sp)
    80003dfa:	fc56                	sd	s5,56(sp)
    80003dfc:	f85a                	sd	s6,48(sp)
    80003dfe:	f45e                	sd	s7,40(sp)
    80003e00:	f062                	sd	s8,32(sp)
    80003e02:	ec66                	sd	s9,24(sp)
    80003e04:	e86a                	sd	s10,16(sp)
    80003e06:	e46e                	sd	s11,8(sp)
    80003e08:	1880                	addi	s0,sp,112
    80003e0a:	8aaa                	mv	s5,a0
    80003e0c:	8bae                	mv	s7,a1
    80003e0e:	8a32                	mv	s4,a2
    80003e10:	8936                	mv	s2,a3
    80003e12:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e14:	00e687bb          	addw	a5,a3,a4
    80003e18:	0ed7e263          	bltu	a5,a3,80003efc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e1c:	00043737          	lui	a4,0x43
    80003e20:	0ef76063          	bltu	a4,a5,80003f00 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e24:	0c0b0863          	beqz	s6,80003ef4 <writei+0x10e>
    80003e28:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e2a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e2e:	5c7d                	li	s8,-1
    80003e30:	a091                	j	80003e74 <writei+0x8e>
    80003e32:	020d1d93          	slli	s11,s10,0x20
    80003e36:	020ddd93          	srli	s11,s11,0x20
    80003e3a:	05848513          	addi	a0,s1,88
    80003e3e:	86ee                	mv	a3,s11
    80003e40:	8652                	mv	a2,s4
    80003e42:	85de                	mv	a1,s7
    80003e44:	953a                	add	a0,a0,a4
    80003e46:	ffffe097          	auipc	ra,0xffffe
    80003e4a:	71c080e7          	jalr	1820(ra) # 80002562 <either_copyin>
    80003e4e:	07850263          	beq	a0,s8,80003eb2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e52:	8526                	mv	a0,s1
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	75e080e7          	jalr	1886(ra) # 800045b2 <log_write>
    brelse(bp);
    80003e5c:	8526                	mv	a0,s1
    80003e5e:	fffff097          	auipc	ra,0xfffff
    80003e62:	4fc080e7          	jalr	1276(ra) # 8000335a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e66:	013d09bb          	addw	s3,s10,s3
    80003e6a:	012d093b          	addw	s2,s10,s2
    80003e6e:	9a6e                	add	s4,s4,s11
    80003e70:	0569f663          	bgeu	s3,s6,80003ebc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e74:	00a9559b          	srliw	a1,s2,0xa
    80003e78:	8556                	mv	a0,s5
    80003e7a:	fffff097          	auipc	ra,0xfffff
    80003e7e:	7a2080e7          	jalr	1954(ra) # 8000361c <bmap>
    80003e82:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e86:	c99d                	beqz	a1,80003ebc <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e88:	000aa503          	lw	a0,0(s5)
    80003e8c:	fffff097          	auipc	ra,0xfffff
    80003e90:	39e080e7          	jalr	926(ra) # 8000322a <bread>
    80003e94:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e96:	3ff97713          	andi	a4,s2,1023
    80003e9a:	40ec87bb          	subw	a5,s9,a4
    80003e9e:	413b06bb          	subw	a3,s6,s3
    80003ea2:	8d3e                	mv	s10,a5
    80003ea4:	2781                	sext.w	a5,a5
    80003ea6:	0006861b          	sext.w	a2,a3
    80003eaa:	f8f674e3          	bgeu	a2,a5,80003e32 <writei+0x4c>
    80003eae:	8d36                	mv	s10,a3
    80003eb0:	b749                	j	80003e32 <writei+0x4c>
      brelse(bp);
    80003eb2:	8526                	mv	a0,s1
    80003eb4:	fffff097          	auipc	ra,0xfffff
    80003eb8:	4a6080e7          	jalr	1190(ra) # 8000335a <brelse>
  }

  if(off > ip->size)
    80003ebc:	04caa783          	lw	a5,76(s5)
    80003ec0:	0127f463          	bgeu	a5,s2,80003ec8 <writei+0xe2>
    ip->size = off;
    80003ec4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ec8:	8556                	mv	a0,s5
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	aa4080e7          	jalr	-1372(ra) # 8000396e <iupdate>

  return tot;
    80003ed2:	0009851b          	sext.w	a0,s3
}
    80003ed6:	70a6                	ld	ra,104(sp)
    80003ed8:	7406                	ld	s0,96(sp)
    80003eda:	64e6                	ld	s1,88(sp)
    80003edc:	6946                	ld	s2,80(sp)
    80003ede:	69a6                	ld	s3,72(sp)
    80003ee0:	6a06                	ld	s4,64(sp)
    80003ee2:	7ae2                	ld	s5,56(sp)
    80003ee4:	7b42                	ld	s6,48(sp)
    80003ee6:	7ba2                	ld	s7,40(sp)
    80003ee8:	7c02                	ld	s8,32(sp)
    80003eea:	6ce2                	ld	s9,24(sp)
    80003eec:	6d42                	ld	s10,16(sp)
    80003eee:	6da2                	ld	s11,8(sp)
    80003ef0:	6165                	addi	sp,sp,112
    80003ef2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ef4:	89da                	mv	s3,s6
    80003ef6:	bfc9                	j	80003ec8 <writei+0xe2>
    return -1;
    80003ef8:	557d                	li	a0,-1
}
    80003efa:	8082                	ret
    return -1;
    80003efc:	557d                	li	a0,-1
    80003efe:	bfe1                	j	80003ed6 <writei+0xf0>
    return -1;
    80003f00:	557d                	li	a0,-1
    80003f02:	bfd1                	j	80003ed6 <writei+0xf0>

0000000080003f04 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f04:	1141                	addi	sp,sp,-16
    80003f06:	e406                	sd	ra,8(sp)
    80003f08:	e022                	sd	s0,0(sp)
    80003f0a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f0c:	4639                	li	a2,14
    80003f0e:	ffffd097          	auipc	ra,0xffffd
    80003f12:	e90080e7          	jalr	-368(ra) # 80000d9e <strncmp>
}
    80003f16:	60a2                	ld	ra,8(sp)
    80003f18:	6402                	ld	s0,0(sp)
    80003f1a:	0141                	addi	sp,sp,16
    80003f1c:	8082                	ret

0000000080003f1e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f1e:	7139                	addi	sp,sp,-64
    80003f20:	fc06                	sd	ra,56(sp)
    80003f22:	f822                	sd	s0,48(sp)
    80003f24:	f426                	sd	s1,40(sp)
    80003f26:	f04a                	sd	s2,32(sp)
    80003f28:	ec4e                	sd	s3,24(sp)
    80003f2a:	e852                	sd	s4,16(sp)
    80003f2c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f2e:	04451703          	lh	a4,68(a0)
    80003f32:	4785                	li	a5,1
    80003f34:	00f71a63          	bne	a4,a5,80003f48 <dirlookup+0x2a>
    80003f38:	892a                	mv	s2,a0
    80003f3a:	89ae                	mv	s3,a1
    80003f3c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f3e:	457c                	lw	a5,76(a0)
    80003f40:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f42:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f44:	e79d                	bnez	a5,80003f72 <dirlookup+0x54>
    80003f46:	a8a5                	j	80003fbe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f48:	00004517          	auipc	a0,0x4
    80003f4c:	6c850513          	addi	a0,a0,1736 # 80008610 <syscalls+0x1c0>
    80003f50:	ffffc097          	auipc	ra,0xffffc
    80003f54:	5ec080e7          	jalr	1516(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003f58:	00004517          	auipc	a0,0x4
    80003f5c:	6d050513          	addi	a0,a0,1744 # 80008628 <syscalls+0x1d8>
    80003f60:	ffffc097          	auipc	ra,0xffffc
    80003f64:	5dc080e7          	jalr	1500(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f68:	24c1                	addiw	s1,s1,16
    80003f6a:	04c92783          	lw	a5,76(s2)
    80003f6e:	04f4f763          	bgeu	s1,a5,80003fbc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f72:	4741                	li	a4,16
    80003f74:	86a6                	mv	a3,s1
    80003f76:	fc040613          	addi	a2,s0,-64
    80003f7a:	4581                	li	a1,0
    80003f7c:	854a                	mv	a0,s2
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	d70080e7          	jalr	-656(ra) # 80003cee <readi>
    80003f86:	47c1                	li	a5,16
    80003f88:	fcf518e3          	bne	a0,a5,80003f58 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f8c:	fc045783          	lhu	a5,-64(s0)
    80003f90:	dfe1                	beqz	a5,80003f68 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f92:	fc240593          	addi	a1,s0,-62
    80003f96:	854e                	mv	a0,s3
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	f6c080e7          	jalr	-148(ra) # 80003f04 <namecmp>
    80003fa0:	f561                	bnez	a0,80003f68 <dirlookup+0x4a>
      if(poff)
    80003fa2:	000a0463          	beqz	s4,80003faa <dirlookup+0x8c>
        *poff = off;
    80003fa6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003faa:	fc045583          	lhu	a1,-64(s0)
    80003fae:	00092503          	lw	a0,0(s2)
    80003fb2:	fffff097          	auipc	ra,0xfffff
    80003fb6:	754080e7          	jalr	1876(ra) # 80003706 <iget>
    80003fba:	a011                	j	80003fbe <dirlookup+0xa0>
  return 0;
    80003fbc:	4501                	li	a0,0
}
    80003fbe:	70e2                	ld	ra,56(sp)
    80003fc0:	7442                	ld	s0,48(sp)
    80003fc2:	74a2                	ld	s1,40(sp)
    80003fc4:	7902                	ld	s2,32(sp)
    80003fc6:	69e2                	ld	s3,24(sp)
    80003fc8:	6a42                	ld	s4,16(sp)
    80003fca:	6121                	addi	sp,sp,64
    80003fcc:	8082                	ret

0000000080003fce <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fce:	711d                	addi	sp,sp,-96
    80003fd0:	ec86                	sd	ra,88(sp)
    80003fd2:	e8a2                	sd	s0,80(sp)
    80003fd4:	e4a6                	sd	s1,72(sp)
    80003fd6:	e0ca                	sd	s2,64(sp)
    80003fd8:	fc4e                	sd	s3,56(sp)
    80003fda:	f852                	sd	s4,48(sp)
    80003fdc:	f456                	sd	s5,40(sp)
    80003fde:	f05a                	sd	s6,32(sp)
    80003fe0:	ec5e                	sd	s7,24(sp)
    80003fe2:	e862                	sd	s8,16(sp)
    80003fe4:	e466                	sd	s9,8(sp)
    80003fe6:	1080                	addi	s0,sp,96
    80003fe8:	84aa                	mv	s1,a0
    80003fea:	8b2e                	mv	s6,a1
    80003fec:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fee:	00054703          	lbu	a4,0(a0)
    80003ff2:	02f00793          	li	a5,47
    80003ff6:	02f70263          	beq	a4,a5,8000401a <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ffa:	ffffe097          	auipc	ra,0xffffe
    80003ffe:	9ac080e7          	jalr	-1620(ra) # 800019a6 <myproc>
    80004002:	15053503          	ld	a0,336(a0)
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	9f6080e7          	jalr	-1546(ra) # 800039fc <idup>
    8000400e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004010:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004014:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004016:	4b85                	li	s7,1
    80004018:	a875                	j	800040d4 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000401a:	4585                	li	a1,1
    8000401c:	4505                	li	a0,1
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	6e8080e7          	jalr	1768(ra) # 80003706 <iget>
    80004026:	8a2a                	mv	s4,a0
    80004028:	b7e5                	j	80004010 <namex+0x42>
      iunlockput(ip);
    8000402a:	8552                	mv	a0,s4
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	c70080e7          	jalr	-912(ra) # 80003c9c <iunlockput>
      return 0;
    80004034:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004036:	8552                	mv	a0,s4
    80004038:	60e6                	ld	ra,88(sp)
    8000403a:	6446                	ld	s0,80(sp)
    8000403c:	64a6                	ld	s1,72(sp)
    8000403e:	6906                	ld	s2,64(sp)
    80004040:	79e2                	ld	s3,56(sp)
    80004042:	7a42                	ld	s4,48(sp)
    80004044:	7aa2                	ld	s5,40(sp)
    80004046:	7b02                	ld	s6,32(sp)
    80004048:	6be2                	ld	s7,24(sp)
    8000404a:	6c42                	ld	s8,16(sp)
    8000404c:	6ca2                	ld	s9,8(sp)
    8000404e:	6125                	addi	sp,sp,96
    80004050:	8082                	ret
      iunlock(ip);
    80004052:	8552                	mv	a0,s4
    80004054:	00000097          	auipc	ra,0x0
    80004058:	aa8080e7          	jalr	-1368(ra) # 80003afc <iunlock>
      return ip;
    8000405c:	bfe9                	j	80004036 <namex+0x68>
      iunlockput(ip);
    8000405e:	8552                	mv	a0,s4
    80004060:	00000097          	auipc	ra,0x0
    80004064:	c3c080e7          	jalr	-964(ra) # 80003c9c <iunlockput>
      return 0;
    80004068:	8a4e                	mv	s4,s3
    8000406a:	b7f1                	j	80004036 <namex+0x68>
  len = path - s;
    8000406c:	40998633          	sub	a2,s3,s1
    80004070:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004074:	099c5863          	bge	s8,s9,80004104 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004078:	4639                	li	a2,14
    8000407a:	85a6                	mv	a1,s1
    8000407c:	8556                	mv	a0,s5
    8000407e:	ffffd097          	auipc	ra,0xffffd
    80004082:	cac080e7          	jalr	-852(ra) # 80000d2a <memmove>
    80004086:	84ce                	mv	s1,s3
  while(*path == '/')
    80004088:	0004c783          	lbu	a5,0(s1)
    8000408c:	01279763          	bne	a5,s2,8000409a <namex+0xcc>
    path++;
    80004090:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004092:	0004c783          	lbu	a5,0(s1)
    80004096:	ff278de3          	beq	a5,s2,80004090 <namex+0xc2>
    ilock(ip);
    8000409a:	8552                	mv	a0,s4
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	99e080e7          	jalr	-1634(ra) # 80003a3a <ilock>
    if(ip->type != T_DIR){
    800040a4:	044a1783          	lh	a5,68(s4)
    800040a8:	f97791e3          	bne	a5,s7,8000402a <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800040ac:	000b0563          	beqz	s6,800040b6 <namex+0xe8>
    800040b0:	0004c783          	lbu	a5,0(s1)
    800040b4:	dfd9                	beqz	a5,80004052 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040b6:	4601                	li	a2,0
    800040b8:	85d6                	mv	a1,s5
    800040ba:	8552                	mv	a0,s4
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	e62080e7          	jalr	-414(ra) # 80003f1e <dirlookup>
    800040c4:	89aa                	mv	s3,a0
    800040c6:	dd41                	beqz	a0,8000405e <namex+0x90>
    iunlockput(ip);
    800040c8:	8552                	mv	a0,s4
    800040ca:	00000097          	auipc	ra,0x0
    800040ce:	bd2080e7          	jalr	-1070(ra) # 80003c9c <iunlockput>
    ip = next;
    800040d2:	8a4e                	mv	s4,s3
  while(*path == '/')
    800040d4:	0004c783          	lbu	a5,0(s1)
    800040d8:	01279763          	bne	a5,s2,800040e6 <namex+0x118>
    path++;
    800040dc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040de:	0004c783          	lbu	a5,0(s1)
    800040e2:	ff278de3          	beq	a5,s2,800040dc <namex+0x10e>
  if(*path == 0)
    800040e6:	cb9d                	beqz	a5,8000411c <namex+0x14e>
  while(*path != '/' && *path != 0)
    800040e8:	0004c783          	lbu	a5,0(s1)
    800040ec:	89a6                	mv	s3,s1
  len = path - s;
    800040ee:	4c81                	li	s9,0
    800040f0:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800040f2:	01278963          	beq	a5,s2,80004104 <namex+0x136>
    800040f6:	dbbd                	beqz	a5,8000406c <namex+0x9e>
    path++;
    800040f8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800040fa:	0009c783          	lbu	a5,0(s3)
    800040fe:	ff279ce3          	bne	a5,s2,800040f6 <namex+0x128>
    80004102:	b7ad                	j	8000406c <namex+0x9e>
    memmove(name, s, len);
    80004104:	2601                	sext.w	a2,a2
    80004106:	85a6                	mv	a1,s1
    80004108:	8556                	mv	a0,s5
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	c20080e7          	jalr	-992(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004112:	9cd6                	add	s9,s9,s5
    80004114:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004118:	84ce                	mv	s1,s3
    8000411a:	b7bd                	j	80004088 <namex+0xba>
  if(nameiparent){
    8000411c:	f00b0de3          	beqz	s6,80004036 <namex+0x68>
    iput(ip);
    80004120:	8552                	mv	a0,s4
    80004122:	00000097          	auipc	ra,0x0
    80004126:	ad2080e7          	jalr	-1326(ra) # 80003bf4 <iput>
    return 0;
    8000412a:	4a01                	li	s4,0
    8000412c:	b729                	j	80004036 <namex+0x68>

000000008000412e <dirlink>:
{
    8000412e:	7139                	addi	sp,sp,-64
    80004130:	fc06                	sd	ra,56(sp)
    80004132:	f822                	sd	s0,48(sp)
    80004134:	f426                	sd	s1,40(sp)
    80004136:	f04a                	sd	s2,32(sp)
    80004138:	ec4e                	sd	s3,24(sp)
    8000413a:	e852                	sd	s4,16(sp)
    8000413c:	0080                	addi	s0,sp,64
    8000413e:	892a                	mv	s2,a0
    80004140:	8a2e                	mv	s4,a1
    80004142:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004144:	4601                	li	a2,0
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	dd8080e7          	jalr	-552(ra) # 80003f1e <dirlookup>
    8000414e:	e93d                	bnez	a0,800041c4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004150:	04c92483          	lw	s1,76(s2)
    80004154:	c49d                	beqz	s1,80004182 <dirlink+0x54>
    80004156:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004158:	4741                	li	a4,16
    8000415a:	86a6                	mv	a3,s1
    8000415c:	fc040613          	addi	a2,s0,-64
    80004160:	4581                	li	a1,0
    80004162:	854a                	mv	a0,s2
    80004164:	00000097          	auipc	ra,0x0
    80004168:	b8a080e7          	jalr	-1142(ra) # 80003cee <readi>
    8000416c:	47c1                	li	a5,16
    8000416e:	06f51163          	bne	a0,a5,800041d0 <dirlink+0xa2>
    if(de.inum == 0)
    80004172:	fc045783          	lhu	a5,-64(s0)
    80004176:	c791                	beqz	a5,80004182 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004178:	24c1                	addiw	s1,s1,16
    8000417a:	04c92783          	lw	a5,76(s2)
    8000417e:	fcf4ede3          	bltu	s1,a5,80004158 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004182:	4639                	li	a2,14
    80004184:	85d2                	mv	a1,s4
    80004186:	fc240513          	addi	a0,s0,-62
    8000418a:	ffffd097          	auipc	ra,0xffffd
    8000418e:	c50080e7          	jalr	-944(ra) # 80000dda <strncpy>
  de.inum = inum;
    80004192:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004196:	4741                	li	a4,16
    80004198:	86a6                	mv	a3,s1
    8000419a:	fc040613          	addi	a2,s0,-64
    8000419e:	4581                	li	a1,0
    800041a0:	854a                	mv	a0,s2
    800041a2:	00000097          	auipc	ra,0x0
    800041a6:	c44080e7          	jalr	-956(ra) # 80003de6 <writei>
    800041aa:	1541                	addi	a0,a0,-16
    800041ac:	00a03533          	snez	a0,a0
    800041b0:	40a00533          	neg	a0,a0
}
    800041b4:	70e2                	ld	ra,56(sp)
    800041b6:	7442                	ld	s0,48(sp)
    800041b8:	74a2                	ld	s1,40(sp)
    800041ba:	7902                	ld	s2,32(sp)
    800041bc:	69e2                	ld	s3,24(sp)
    800041be:	6a42                	ld	s4,16(sp)
    800041c0:	6121                	addi	sp,sp,64
    800041c2:	8082                	ret
    iput(ip);
    800041c4:	00000097          	auipc	ra,0x0
    800041c8:	a30080e7          	jalr	-1488(ra) # 80003bf4 <iput>
    return -1;
    800041cc:	557d                	li	a0,-1
    800041ce:	b7dd                	j	800041b4 <dirlink+0x86>
      panic("dirlink read");
    800041d0:	00004517          	auipc	a0,0x4
    800041d4:	46850513          	addi	a0,a0,1128 # 80008638 <syscalls+0x1e8>
    800041d8:	ffffc097          	auipc	ra,0xffffc
    800041dc:	364080e7          	jalr	868(ra) # 8000053c <panic>

00000000800041e0 <namei>:

struct inode*
namei(char *path)
{
    800041e0:	1101                	addi	sp,sp,-32
    800041e2:	ec06                	sd	ra,24(sp)
    800041e4:	e822                	sd	s0,16(sp)
    800041e6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041e8:	fe040613          	addi	a2,s0,-32
    800041ec:	4581                	li	a1,0
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	de0080e7          	jalr	-544(ra) # 80003fce <namex>
}
    800041f6:	60e2                	ld	ra,24(sp)
    800041f8:	6442                	ld	s0,16(sp)
    800041fa:	6105                	addi	sp,sp,32
    800041fc:	8082                	ret

00000000800041fe <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041fe:	1141                	addi	sp,sp,-16
    80004200:	e406                	sd	ra,8(sp)
    80004202:	e022                	sd	s0,0(sp)
    80004204:	0800                	addi	s0,sp,16
    80004206:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004208:	4585                	li	a1,1
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	dc4080e7          	jalr	-572(ra) # 80003fce <namex>
}
    80004212:	60a2                	ld	ra,8(sp)
    80004214:	6402                	ld	s0,0(sp)
    80004216:	0141                	addi	sp,sp,16
    80004218:	8082                	ret

000000008000421a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000421a:	1101                	addi	sp,sp,-32
    8000421c:	ec06                	sd	ra,24(sp)
    8000421e:	e822                	sd	s0,16(sp)
    80004220:	e426                	sd	s1,8(sp)
    80004222:	e04a                	sd	s2,0(sp)
    80004224:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004226:	0001d917          	auipc	s2,0x1d
    8000422a:	31a90913          	addi	s2,s2,794 # 80021540 <log>
    8000422e:	01892583          	lw	a1,24(s2)
    80004232:	02892503          	lw	a0,40(s2)
    80004236:	fffff097          	auipc	ra,0xfffff
    8000423a:	ff4080e7          	jalr	-12(ra) # 8000322a <bread>
    8000423e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004240:	02c92603          	lw	a2,44(s2)
    80004244:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004246:	00c05f63          	blez	a2,80004264 <write_head+0x4a>
    8000424a:	0001d717          	auipc	a4,0x1d
    8000424e:	32670713          	addi	a4,a4,806 # 80021570 <log+0x30>
    80004252:	87aa                	mv	a5,a0
    80004254:	060a                	slli	a2,a2,0x2
    80004256:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004258:	4314                	lw	a3,0(a4)
    8000425a:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000425c:	0711                	addi	a4,a4,4
    8000425e:	0791                	addi	a5,a5,4
    80004260:	fec79ce3          	bne	a5,a2,80004258 <write_head+0x3e>
  }
  bwrite(buf);
    80004264:	8526                	mv	a0,s1
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	0b6080e7          	jalr	182(ra) # 8000331c <bwrite>
  brelse(buf);
    8000426e:	8526                	mv	a0,s1
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	0ea080e7          	jalr	234(ra) # 8000335a <brelse>
}
    80004278:	60e2                	ld	ra,24(sp)
    8000427a:	6442                	ld	s0,16(sp)
    8000427c:	64a2                	ld	s1,8(sp)
    8000427e:	6902                	ld	s2,0(sp)
    80004280:	6105                	addi	sp,sp,32
    80004282:	8082                	ret

0000000080004284 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004284:	0001d797          	auipc	a5,0x1d
    80004288:	2e87a783          	lw	a5,744(a5) # 8002156c <log+0x2c>
    8000428c:	0af05d63          	blez	a5,80004346 <install_trans+0xc2>
{
    80004290:	7139                	addi	sp,sp,-64
    80004292:	fc06                	sd	ra,56(sp)
    80004294:	f822                	sd	s0,48(sp)
    80004296:	f426                	sd	s1,40(sp)
    80004298:	f04a                	sd	s2,32(sp)
    8000429a:	ec4e                	sd	s3,24(sp)
    8000429c:	e852                	sd	s4,16(sp)
    8000429e:	e456                	sd	s5,8(sp)
    800042a0:	e05a                	sd	s6,0(sp)
    800042a2:	0080                	addi	s0,sp,64
    800042a4:	8b2a                	mv	s6,a0
    800042a6:	0001da97          	auipc	s5,0x1d
    800042aa:	2caa8a93          	addi	s5,s5,714 # 80021570 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ae:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042b0:	0001d997          	auipc	s3,0x1d
    800042b4:	29098993          	addi	s3,s3,656 # 80021540 <log>
    800042b8:	a00d                	j	800042da <install_trans+0x56>
    brelse(lbuf);
    800042ba:	854a                	mv	a0,s2
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	09e080e7          	jalr	158(ra) # 8000335a <brelse>
    brelse(dbuf);
    800042c4:	8526                	mv	a0,s1
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	094080e7          	jalr	148(ra) # 8000335a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ce:	2a05                	addiw	s4,s4,1
    800042d0:	0a91                	addi	s5,s5,4
    800042d2:	02c9a783          	lw	a5,44(s3)
    800042d6:	04fa5e63          	bge	s4,a5,80004332 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042da:	0189a583          	lw	a1,24(s3)
    800042de:	014585bb          	addw	a1,a1,s4
    800042e2:	2585                	addiw	a1,a1,1
    800042e4:	0289a503          	lw	a0,40(s3)
    800042e8:	fffff097          	auipc	ra,0xfffff
    800042ec:	f42080e7          	jalr	-190(ra) # 8000322a <bread>
    800042f0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042f2:	000aa583          	lw	a1,0(s5)
    800042f6:	0289a503          	lw	a0,40(s3)
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	f30080e7          	jalr	-208(ra) # 8000322a <bread>
    80004302:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004304:	40000613          	li	a2,1024
    80004308:	05890593          	addi	a1,s2,88
    8000430c:	05850513          	addi	a0,a0,88
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	a1a080e7          	jalr	-1510(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004318:	8526                	mv	a0,s1
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	002080e7          	jalr	2(ra) # 8000331c <bwrite>
    if(recovering == 0)
    80004322:	f80b1ce3          	bnez	s6,800042ba <install_trans+0x36>
      bunpin(dbuf);
    80004326:	8526                	mv	a0,s1
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	10a080e7          	jalr	266(ra) # 80003432 <bunpin>
    80004330:	b769                	j	800042ba <install_trans+0x36>
}
    80004332:	70e2                	ld	ra,56(sp)
    80004334:	7442                	ld	s0,48(sp)
    80004336:	74a2                	ld	s1,40(sp)
    80004338:	7902                	ld	s2,32(sp)
    8000433a:	69e2                	ld	s3,24(sp)
    8000433c:	6a42                	ld	s4,16(sp)
    8000433e:	6aa2                	ld	s5,8(sp)
    80004340:	6b02                	ld	s6,0(sp)
    80004342:	6121                	addi	sp,sp,64
    80004344:	8082                	ret
    80004346:	8082                	ret

0000000080004348 <initlog>:
{
    80004348:	7179                	addi	sp,sp,-48
    8000434a:	f406                	sd	ra,40(sp)
    8000434c:	f022                	sd	s0,32(sp)
    8000434e:	ec26                	sd	s1,24(sp)
    80004350:	e84a                	sd	s2,16(sp)
    80004352:	e44e                	sd	s3,8(sp)
    80004354:	1800                	addi	s0,sp,48
    80004356:	892a                	mv	s2,a0
    80004358:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000435a:	0001d497          	auipc	s1,0x1d
    8000435e:	1e648493          	addi	s1,s1,486 # 80021540 <log>
    80004362:	00004597          	auipc	a1,0x4
    80004366:	2e658593          	addi	a1,a1,742 # 80008648 <syscalls+0x1f8>
    8000436a:	8526                	mv	a0,s1
    8000436c:	ffffc097          	auipc	ra,0xffffc
    80004370:	7d6080e7          	jalr	2006(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004374:	0149a583          	lw	a1,20(s3)
    80004378:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000437a:	0109a783          	lw	a5,16(s3)
    8000437e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004380:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004384:	854a                	mv	a0,s2
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	ea4080e7          	jalr	-348(ra) # 8000322a <bread>
  log.lh.n = lh->n;
    8000438e:	4d30                	lw	a2,88(a0)
    80004390:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004392:	00c05f63          	blez	a2,800043b0 <initlog+0x68>
    80004396:	87aa                	mv	a5,a0
    80004398:	0001d717          	auipc	a4,0x1d
    8000439c:	1d870713          	addi	a4,a4,472 # 80021570 <log+0x30>
    800043a0:	060a                	slli	a2,a2,0x2
    800043a2:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800043a4:	4ff4                	lw	a3,92(a5)
    800043a6:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043a8:	0791                	addi	a5,a5,4
    800043aa:	0711                	addi	a4,a4,4
    800043ac:	fec79ce3          	bne	a5,a2,800043a4 <initlog+0x5c>
  brelse(buf);
    800043b0:	fffff097          	auipc	ra,0xfffff
    800043b4:	faa080e7          	jalr	-86(ra) # 8000335a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043b8:	4505                	li	a0,1
    800043ba:	00000097          	auipc	ra,0x0
    800043be:	eca080e7          	jalr	-310(ra) # 80004284 <install_trans>
  log.lh.n = 0;
    800043c2:	0001d797          	auipc	a5,0x1d
    800043c6:	1a07a523          	sw	zero,426(a5) # 8002156c <log+0x2c>
  write_head(); // clear the log
    800043ca:	00000097          	auipc	ra,0x0
    800043ce:	e50080e7          	jalr	-432(ra) # 8000421a <write_head>
}
    800043d2:	70a2                	ld	ra,40(sp)
    800043d4:	7402                	ld	s0,32(sp)
    800043d6:	64e2                	ld	s1,24(sp)
    800043d8:	6942                	ld	s2,16(sp)
    800043da:	69a2                	ld	s3,8(sp)
    800043dc:	6145                	addi	sp,sp,48
    800043de:	8082                	ret

00000000800043e0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043e0:	1101                	addi	sp,sp,-32
    800043e2:	ec06                	sd	ra,24(sp)
    800043e4:	e822                	sd	s0,16(sp)
    800043e6:	e426                	sd	s1,8(sp)
    800043e8:	e04a                	sd	s2,0(sp)
    800043ea:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043ec:	0001d517          	auipc	a0,0x1d
    800043f0:	15450513          	addi	a0,a0,340 # 80021540 <log>
    800043f4:	ffffc097          	auipc	ra,0xffffc
    800043f8:	7de080e7          	jalr	2014(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    800043fc:	0001d497          	auipc	s1,0x1d
    80004400:	14448493          	addi	s1,s1,324 # 80021540 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004404:	4979                	li	s2,30
    80004406:	a039                	j	80004414 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004408:	85a6                	mv	a1,s1
    8000440a:	8526                	mv	a0,s1
    8000440c:	ffffe097          	auipc	ra,0xffffe
    80004410:	cec080e7          	jalr	-788(ra) # 800020f8 <sleep>
    if(log.committing){
    80004414:	50dc                	lw	a5,36(s1)
    80004416:	fbed                	bnez	a5,80004408 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004418:	5098                	lw	a4,32(s1)
    8000441a:	2705                	addiw	a4,a4,1
    8000441c:	0027179b          	slliw	a5,a4,0x2
    80004420:	9fb9                	addw	a5,a5,a4
    80004422:	0017979b          	slliw	a5,a5,0x1
    80004426:	54d4                	lw	a3,44(s1)
    80004428:	9fb5                	addw	a5,a5,a3
    8000442a:	00f95963          	bge	s2,a5,8000443c <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000442e:	85a6                	mv	a1,s1
    80004430:	8526                	mv	a0,s1
    80004432:	ffffe097          	auipc	ra,0xffffe
    80004436:	cc6080e7          	jalr	-826(ra) # 800020f8 <sleep>
    8000443a:	bfe9                	j	80004414 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000443c:	0001d517          	auipc	a0,0x1d
    80004440:	10450513          	addi	a0,a0,260 # 80021540 <log>
    80004444:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	840080e7          	jalr	-1984(ra) # 80000c86 <release>
      break;
    }
  }
}
    8000444e:	60e2                	ld	ra,24(sp)
    80004450:	6442                	ld	s0,16(sp)
    80004452:	64a2                	ld	s1,8(sp)
    80004454:	6902                	ld	s2,0(sp)
    80004456:	6105                	addi	sp,sp,32
    80004458:	8082                	ret

000000008000445a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000445a:	7139                	addi	sp,sp,-64
    8000445c:	fc06                	sd	ra,56(sp)
    8000445e:	f822                	sd	s0,48(sp)
    80004460:	f426                	sd	s1,40(sp)
    80004462:	f04a                	sd	s2,32(sp)
    80004464:	ec4e                	sd	s3,24(sp)
    80004466:	e852                	sd	s4,16(sp)
    80004468:	e456                	sd	s5,8(sp)
    8000446a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000446c:	0001d497          	auipc	s1,0x1d
    80004470:	0d448493          	addi	s1,s1,212 # 80021540 <log>
    80004474:	8526                	mv	a0,s1
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	75c080e7          	jalr	1884(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    8000447e:	509c                	lw	a5,32(s1)
    80004480:	37fd                	addiw	a5,a5,-1
    80004482:	0007891b          	sext.w	s2,a5
    80004486:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004488:	50dc                	lw	a5,36(s1)
    8000448a:	e7b9                	bnez	a5,800044d8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000448c:	04091e63          	bnez	s2,800044e8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004490:	0001d497          	auipc	s1,0x1d
    80004494:	0b048493          	addi	s1,s1,176 # 80021540 <log>
    80004498:	4785                	li	a5,1
    8000449a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000449c:	8526                	mv	a0,s1
    8000449e:	ffffc097          	auipc	ra,0xffffc
    800044a2:	7e8080e7          	jalr	2024(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044a6:	54dc                	lw	a5,44(s1)
    800044a8:	06f04763          	bgtz	a5,80004516 <end_op+0xbc>
    acquire(&log.lock);
    800044ac:	0001d497          	auipc	s1,0x1d
    800044b0:	09448493          	addi	s1,s1,148 # 80021540 <log>
    800044b4:	8526                	mv	a0,s1
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	71c080e7          	jalr	1820(ra) # 80000bd2 <acquire>
    log.committing = 0;
    800044be:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044c2:	8526                	mv	a0,s1
    800044c4:	ffffe097          	auipc	ra,0xffffe
    800044c8:	c98080e7          	jalr	-872(ra) # 8000215c <wakeup>
    release(&log.lock);
    800044cc:	8526                	mv	a0,s1
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	7b8080e7          	jalr	1976(ra) # 80000c86 <release>
}
    800044d6:	a03d                	j	80004504 <end_op+0xaa>
    panic("log.committing");
    800044d8:	00004517          	auipc	a0,0x4
    800044dc:	17850513          	addi	a0,a0,376 # 80008650 <syscalls+0x200>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	05c080e7          	jalr	92(ra) # 8000053c <panic>
    wakeup(&log);
    800044e8:	0001d497          	auipc	s1,0x1d
    800044ec:	05848493          	addi	s1,s1,88 # 80021540 <log>
    800044f0:	8526                	mv	a0,s1
    800044f2:	ffffe097          	auipc	ra,0xffffe
    800044f6:	c6a080e7          	jalr	-918(ra) # 8000215c <wakeup>
  release(&log.lock);
    800044fa:	8526                	mv	a0,s1
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	78a080e7          	jalr	1930(ra) # 80000c86 <release>
}
    80004504:	70e2                	ld	ra,56(sp)
    80004506:	7442                	ld	s0,48(sp)
    80004508:	74a2                	ld	s1,40(sp)
    8000450a:	7902                	ld	s2,32(sp)
    8000450c:	69e2                	ld	s3,24(sp)
    8000450e:	6a42                	ld	s4,16(sp)
    80004510:	6aa2                	ld	s5,8(sp)
    80004512:	6121                	addi	sp,sp,64
    80004514:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004516:	0001da97          	auipc	s5,0x1d
    8000451a:	05aa8a93          	addi	s5,s5,90 # 80021570 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000451e:	0001da17          	auipc	s4,0x1d
    80004522:	022a0a13          	addi	s4,s4,34 # 80021540 <log>
    80004526:	018a2583          	lw	a1,24(s4)
    8000452a:	012585bb          	addw	a1,a1,s2
    8000452e:	2585                	addiw	a1,a1,1
    80004530:	028a2503          	lw	a0,40(s4)
    80004534:	fffff097          	auipc	ra,0xfffff
    80004538:	cf6080e7          	jalr	-778(ra) # 8000322a <bread>
    8000453c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000453e:	000aa583          	lw	a1,0(s5)
    80004542:	028a2503          	lw	a0,40(s4)
    80004546:	fffff097          	auipc	ra,0xfffff
    8000454a:	ce4080e7          	jalr	-796(ra) # 8000322a <bread>
    8000454e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004550:	40000613          	li	a2,1024
    80004554:	05850593          	addi	a1,a0,88
    80004558:	05848513          	addi	a0,s1,88
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	7ce080e7          	jalr	1998(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004564:	8526                	mv	a0,s1
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	db6080e7          	jalr	-586(ra) # 8000331c <bwrite>
    brelse(from);
    8000456e:	854e                	mv	a0,s3
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	dea080e7          	jalr	-534(ra) # 8000335a <brelse>
    brelse(to);
    80004578:	8526                	mv	a0,s1
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	de0080e7          	jalr	-544(ra) # 8000335a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004582:	2905                	addiw	s2,s2,1
    80004584:	0a91                	addi	s5,s5,4
    80004586:	02ca2783          	lw	a5,44(s4)
    8000458a:	f8f94ee3          	blt	s2,a5,80004526 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000458e:	00000097          	auipc	ra,0x0
    80004592:	c8c080e7          	jalr	-884(ra) # 8000421a <write_head>
    install_trans(0); // Now install writes to home locations
    80004596:	4501                	li	a0,0
    80004598:	00000097          	auipc	ra,0x0
    8000459c:	cec080e7          	jalr	-788(ra) # 80004284 <install_trans>
    log.lh.n = 0;
    800045a0:	0001d797          	auipc	a5,0x1d
    800045a4:	fc07a623          	sw	zero,-52(a5) # 8002156c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045a8:	00000097          	auipc	ra,0x0
    800045ac:	c72080e7          	jalr	-910(ra) # 8000421a <write_head>
    800045b0:	bdf5                	j	800044ac <end_op+0x52>

00000000800045b2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045b2:	1101                	addi	sp,sp,-32
    800045b4:	ec06                	sd	ra,24(sp)
    800045b6:	e822                	sd	s0,16(sp)
    800045b8:	e426                	sd	s1,8(sp)
    800045ba:	e04a                	sd	s2,0(sp)
    800045bc:	1000                	addi	s0,sp,32
    800045be:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045c0:	0001d917          	auipc	s2,0x1d
    800045c4:	f8090913          	addi	s2,s2,-128 # 80021540 <log>
    800045c8:	854a                	mv	a0,s2
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	608080e7          	jalr	1544(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045d2:	02c92603          	lw	a2,44(s2)
    800045d6:	47f5                	li	a5,29
    800045d8:	06c7c563          	blt	a5,a2,80004642 <log_write+0x90>
    800045dc:	0001d797          	auipc	a5,0x1d
    800045e0:	f807a783          	lw	a5,-128(a5) # 8002155c <log+0x1c>
    800045e4:	37fd                	addiw	a5,a5,-1
    800045e6:	04f65e63          	bge	a2,a5,80004642 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045ea:	0001d797          	auipc	a5,0x1d
    800045ee:	f767a783          	lw	a5,-138(a5) # 80021560 <log+0x20>
    800045f2:	06f05063          	blez	a5,80004652 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045f6:	4781                	li	a5,0
    800045f8:	06c05563          	blez	a2,80004662 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045fc:	44cc                	lw	a1,12(s1)
    800045fe:	0001d717          	auipc	a4,0x1d
    80004602:	f7270713          	addi	a4,a4,-142 # 80021570 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004606:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004608:	4314                	lw	a3,0(a4)
    8000460a:	04b68c63          	beq	a3,a1,80004662 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000460e:	2785                	addiw	a5,a5,1
    80004610:	0711                	addi	a4,a4,4
    80004612:	fef61be3          	bne	a2,a5,80004608 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004616:	0621                	addi	a2,a2,8
    80004618:	060a                	slli	a2,a2,0x2
    8000461a:	0001d797          	auipc	a5,0x1d
    8000461e:	f2678793          	addi	a5,a5,-218 # 80021540 <log>
    80004622:	97b2                	add	a5,a5,a2
    80004624:	44d8                	lw	a4,12(s1)
    80004626:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004628:	8526                	mv	a0,s1
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	dcc080e7          	jalr	-564(ra) # 800033f6 <bpin>
    log.lh.n++;
    80004632:	0001d717          	auipc	a4,0x1d
    80004636:	f0e70713          	addi	a4,a4,-242 # 80021540 <log>
    8000463a:	575c                	lw	a5,44(a4)
    8000463c:	2785                	addiw	a5,a5,1
    8000463e:	d75c                	sw	a5,44(a4)
    80004640:	a82d                	j	8000467a <log_write+0xc8>
    panic("too big a transaction");
    80004642:	00004517          	auipc	a0,0x4
    80004646:	01e50513          	addi	a0,a0,30 # 80008660 <syscalls+0x210>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	ef2080e7          	jalr	-270(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004652:	00004517          	auipc	a0,0x4
    80004656:	02650513          	addi	a0,a0,38 # 80008678 <syscalls+0x228>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	ee2080e7          	jalr	-286(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004662:	00878693          	addi	a3,a5,8
    80004666:	068a                	slli	a3,a3,0x2
    80004668:	0001d717          	auipc	a4,0x1d
    8000466c:	ed870713          	addi	a4,a4,-296 # 80021540 <log>
    80004670:	9736                	add	a4,a4,a3
    80004672:	44d4                	lw	a3,12(s1)
    80004674:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004676:	faf609e3          	beq	a2,a5,80004628 <log_write+0x76>
  }
  release(&log.lock);
    8000467a:	0001d517          	auipc	a0,0x1d
    8000467e:	ec650513          	addi	a0,a0,-314 # 80021540 <log>
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	604080e7          	jalr	1540(ra) # 80000c86 <release>
}
    8000468a:	60e2                	ld	ra,24(sp)
    8000468c:	6442                	ld	s0,16(sp)
    8000468e:	64a2                	ld	s1,8(sp)
    80004690:	6902                	ld	s2,0(sp)
    80004692:	6105                	addi	sp,sp,32
    80004694:	8082                	ret

0000000080004696 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004696:	1101                	addi	sp,sp,-32
    80004698:	ec06                	sd	ra,24(sp)
    8000469a:	e822                	sd	s0,16(sp)
    8000469c:	e426                	sd	s1,8(sp)
    8000469e:	e04a                	sd	s2,0(sp)
    800046a0:	1000                	addi	s0,sp,32
    800046a2:	84aa                	mv	s1,a0
    800046a4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046a6:	00004597          	auipc	a1,0x4
    800046aa:	ff258593          	addi	a1,a1,-14 # 80008698 <syscalls+0x248>
    800046ae:	0521                	addi	a0,a0,8
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	492080e7          	jalr	1170(ra) # 80000b42 <initlock>
  lk->name = name;
    800046b8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046bc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046c0:	0204a423          	sw	zero,40(s1)
}
    800046c4:	60e2                	ld	ra,24(sp)
    800046c6:	6442                	ld	s0,16(sp)
    800046c8:	64a2                	ld	s1,8(sp)
    800046ca:	6902                	ld	s2,0(sp)
    800046cc:	6105                	addi	sp,sp,32
    800046ce:	8082                	ret

00000000800046d0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046d0:	1101                	addi	sp,sp,-32
    800046d2:	ec06                	sd	ra,24(sp)
    800046d4:	e822                	sd	s0,16(sp)
    800046d6:	e426                	sd	s1,8(sp)
    800046d8:	e04a                	sd	s2,0(sp)
    800046da:	1000                	addi	s0,sp,32
    800046dc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046de:	00850913          	addi	s2,a0,8
    800046e2:	854a                	mv	a0,s2
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	4ee080e7          	jalr	1262(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    800046ec:	409c                	lw	a5,0(s1)
    800046ee:	cb89                	beqz	a5,80004700 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046f0:	85ca                	mv	a1,s2
    800046f2:	8526                	mv	a0,s1
    800046f4:	ffffe097          	auipc	ra,0xffffe
    800046f8:	a04080e7          	jalr	-1532(ra) # 800020f8 <sleep>
  while (lk->locked) {
    800046fc:	409c                	lw	a5,0(s1)
    800046fe:	fbed                	bnez	a5,800046f0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004700:	4785                	li	a5,1
    80004702:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004704:	ffffd097          	auipc	ra,0xffffd
    80004708:	2a2080e7          	jalr	674(ra) # 800019a6 <myproc>
    8000470c:	591c                	lw	a5,48(a0)
    8000470e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004710:	854a                	mv	a0,s2
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	574080e7          	jalr	1396(ra) # 80000c86 <release>
}
    8000471a:	60e2                	ld	ra,24(sp)
    8000471c:	6442                	ld	s0,16(sp)
    8000471e:	64a2                	ld	s1,8(sp)
    80004720:	6902                	ld	s2,0(sp)
    80004722:	6105                	addi	sp,sp,32
    80004724:	8082                	ret

0000000080004726 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004726:	1101                	addi	sp,sp,-32
    80004728:	ec06                	sd	ra,24(sp)
    8000472a:	e822                	sd	s0,16(sp)
    8000472c:	e426                	sd	s1,8(sp)
    8000472e:	e04a                	sd	s2,0(sp)
    80004730:	1000                	addi	s0,sp,32
    80004732:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004734:	00850913          	addi	s2,a0,8
    80004738:	854a                	mv	a0,s2
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	498080e7          	jalr	1176(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004742:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004746:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000474a:	8526                	mv	a0,s1
    8000474c:	ffffe097          	auipc	ra,0xffffe
    80004750:	a10080e7          	jalr	-1520(ra) # 8000215c <wakeup>
  release(&lk->lk);
    80004754:	854a                	mv	a0,s2
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	530080e7          	jalr	1328(ra) # 80000c86 <release>
}
    8000475e:	60e2                	ld	ra,24(sp)
    80004760:	6442                	ld	s0,16(sp)
    80004762:	64a2                	ld	s1,8(sp)
    80004764:	6902                	ld	s2,0(sp)
    80004766:	6105                	addi	sp,sp,32
    80004768:	8082                	ret

000000008000476a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000476a:	7179                	addi	sp,sp,-48
    8000476c:	f406                	sd	ra,40(sp)
    8000476e:	f022                	sd	s0,32(sp)
    80004770:	ec26                	sd	s1,24(sp)
    80004772:	e84a                	sd	s2,16(sp)
    80004774:	e44e                	sd	s3,8(sp)
    80004776:	1800                	addi	s0,sp,48
    80004778:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000477a:	00850913          	addi	s2,a0,8
    8000477e:	854a                	mv	a0,s2
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	452080e7          	jalr	1106(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004788:	409c                	lw	a5,0(s1)
    8000478a:	ef99                	bnez	a5,800047a8 <holdingsleep+0x3e>
    8000478c:	4481                	li	s1,0
  release(&lk->lk);
    8000478e:	854a                	mv	a0,s2
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	4f6080e7          	jalr	1270(ra) # 80000c86 <release>
  return r;
}
    80004798:	8526                	mv	a0,s1
    8000479a:	70a2                	ld	ra,40(sp)
    8000479c:	7402                	ld	s0,32(sp)
    8000479e:	64e2                	ld	s1,24(sp)
    800047a0:	6942                	ld	s2,16(sp)
    800047a2:	69a2                	ld	s3,8(sp)
    800047a4:	6145                	addi	sp,sp,48
    800047a6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047a8:	0284a983          	lw	s3,40(s1)
    800047ac:	ffffd097          	auipc	ra,0xffffd
    800047b0:	1fa080e7          	jalr	506(ra) # 800019a6 <myproc>
    800047b4:	5904                	lw	s1,48(a0)
    800047b6:	413484b3          	sub	s1,s1,s3
    800047ba:	0014b493          	seqz	s1,s1
    800047be:	bfc1                	j	8000478e <holdingsleep+0x24>

00000000800047c0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047c0:	1141                	addi	sp,sp,-16
    800047c2:	e406                	sd	ra,8(sp)
    800047c4:	e022                	sd	s0,0(sp)
    800047c6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047c8:	00004597          	auipc	a1,0x4
    800047cc:	ee058593          	addi	a1,a1,-288 # 800086a8 <syscalls+0x258>
    800047d0:	0001d517          	auipc	a0,0x1d
    800047d4:	eb850513          	addi	a0,a0,-328 # 80021688 <ftable>
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
}
    800047e0:	60a2                	ld	ra,8(sp)
    800047e2:	6402                	ld	s0,0(sp)
    800047e4:	0141                	addi	sp,sp,16
    800047e6:	8082                	ret

00000000800047e8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047e8:	1101                	addi	sp,sp,-32
    800047ea:	ec06                	sd	ra,24(sp)
    800047ec:	e822                	sd	s0,16(sp)
    800047ee:	e426                	sd	s1,8(sp)
    800047f0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047f2:	0001d517          	auipc	a0,0x1d
    800047f6:	e9650513          	addi	a0,a0,-362 # 80021688 <ftable>
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	3d8080e7          	jalr	984(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004802:	0001d497          	auipc	s1,0x1d
    80004806:	e9e48493          	addi	s1,s1,-354 # 800216a0 <ftable+0x18>
    8000480a:	0001e717          	auipc	a4,0x1e
    8000480e:	e3670713          	addi	a4,a4,-458 # 80022640 <disk>
    if(f->ref == 0){
    80004812:	40dc                	lw	a5,4(s1)
    80004814:	cf99                	beqz	a5,80004832 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004816:	02848493          	addi	s1,s1,40
    8000481a:	fee49ce3          	bne	s1,a4,80004812 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000481e:	0001d517          	auipc	a0,0x1d
    80004822:	e6a50513          	addi	a0,a0,-406 # 80021688 <ftable>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	460080e7          	jalr	1120(ra) # 80000c86 <release>
  return 0;
    8000482e:	4481                	li	s1,0
    80004830:	a819                	j	80004846 <filealloc+0x5e>
      f->ref = 1;
    80004832:	4785                	li	a5,1
    80004834:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004836:	0001d517          	auipc	a0,0x1d
    8000483a:	e5250513          	addi	a0,a0,-430 # 80021688 <ftable>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	448080e7          	jalr	1096(ra) # 80000c86 <release>
}
    80004846:	8526                	mv	a0,s1
    80004848:	60e2                	ld	ra,24(sp)
    8000484a:	6442                	ld	s0,16(sp)
    8000484c:	64a2                	ld	s1,8(sp)
    8000484e:	6105                	addi	sp,sp,32
    80004850:	8082                	ret

0000000080004852 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004852:	1101                	addi	sp,sp,-32
    80004854:	ec06                	sd	ra,24(sp)
    80004856:	e822                	sd	s0,16(sp)
    80004858:	e426                	sd	s1,8(sp)
    8000485a:	1000                	addi	s0,sp,32
    8000485c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000485e:	0001d517          	auipc	a0,0x1d
    80004862:	e2a50513          	addi	a0,a0,-470 # 80021688 <ftable>
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	36c080e7          	jalr	876(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000486e:	40dc                	lw	a5,4(s1)
    80004870:	02f05263          	blez	a5,80004894 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004874:	2785                	addiw	a5,a5,1
    80004876:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004878:	0001d517          	auipc	a0,0x1d
    8000487c:	e1050513          	addi	a0,a0,-496 # 80021688 <ftable>
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	406080e7          	jalr	1030(ra) # 80000c86 <release>
  return f;
}
    80004888:	8526                	mv	a0,s1
    8000488a:	60e2                	ld	ra,24(sp)
    8000488c:	6442                	ld	s0,16(sp)
    8000488e:	64a2                	ld	s1,8(sp)
    80004890:	6105                	addi	sp,sp,32
    80004892:	8082                	ret
    panic("filedup");
    80004894:	00004517          	auipc	a0,0x4
    80004898:	e1c50513          	addi	a0,a0,-484 # 800086b0 <syscalls+0x260>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	ca0080e7          	jalr	-864(ra) # 8000053c <panic>

00000000800048a4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048a4:	7139                	addi	sp,sp,-64
    800048a6:	fc06                	sd	ra,56(sp)
    800048a8:	f822                	sd	s0,48(sp)
    800048aa:	f426                	sd	s1,40(sp)
    800048ac:	f04a                	sd	s2,32(sp)
    800048ae:	ec4e                	sd	s3,24(sp)
    800048b0:	e852                	sd	s4,16(sp)
    800048b2:	e456                	sd	s5,8(sp)
    800048b4:	0080                	addi	s0,sp,64
    800048b6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048b8:	0001d517          	auipc	a0,0x1d
    800048bc:	dd050513          	addi	a0,a0,-560 # 80021688 <ftable>
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	312080e7          	jalr	786(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800048c8:	40dc                	lw	a5,4(s1)
    800048ca:	06f05163          	blez	a5,8000492c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048ce:	37fd                	addiw	a5,a5,-1
    800048d0:	0007871b          	sext.w	a4,a5
    800048d4:	c0dc                	sw	a5,4(s1)
    800048d6:	06e04363          	bgtz	a4,8000493c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048da:	0004a903          	lw	s2,0(s1)
    800048de:	0094ca83          	lbu	s5,9(s1)
    800048e2:	0104ba03          	ld	s4,16(s1)
    800048e6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048ea:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048ee:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048f2:	0001d517          	auipc	a0,0x1d
    800048f6:	d9650513          	addi	a0,a0,-618 # 80021688 <ftable>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	38c080e7          	jalr	908(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004902:	4785                	li	a5,1
    80004904:	04f90d63          	beq	s2,a5,8000495e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004908:	3979                	addiw	s2,s2,-2
    8000490a:	4785                	li	a5,1
    8000490c:	0527e063          	bltu	a5,s2,8000494c <fileclose+0xa8>
    begin_op();
    80004910:	00000097          	auipc	ra,0x0
    80004914:	ad0080e7          	jalr	-1328(ra) # 800043e0 <begin_op>
    iput(ff.ip);
    80004918:	854e                	mv	a0,s3
    8000491a:	fffff097          	auipc	ra,0xfffff
    8000491e:	2da080e7          	jalr	730(ra) # 80003bf4 <iput>
    end_op();
    80004922:	00000097          	auipc	ra,0x0
    80004926:	b38080e7          	jalr	-1224(ra) # 8000445a <end_op>
    8000492a:	a00d                	j	8000494c <fileclose+0xa8>
    panic("fileclose");
    8000492c:	00004517          	auipc	a0,0x4
    80004930:	d8c50513          	addi	a0,a0,-628 # 800086b8 <syscalls+0x268>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	c08080e7          	jalr	-1016(ra) # 8000053c <panic>
    release(&ftable.lock);
    8000493c:	0001d517          	auipc	a0,0x1d
    80004940:	d4c50513          	addi	a0,a0,-692 # 80021688 <ftable>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	342080e7          	jalr	834(ra) # 80000c86 <release>
  }
}
    8000494c:	70e2                	ld	ra,56(sp)
    8000494e:	7442                	ld	s0,48(sp)
    80004950:	74a2                	ld	s1,40(sp)
    80004952:	7902                	ld	s2,32(sp)
    80004954:	69e2                	ld	s3,24(sp)
    80004956:	6a42                	ld	s4,16(sp)
    80004958:	6aa2                	ld	s5,8(sp)
    8000495a:	6121                	addi	sp,sp,64
    8000495c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000495e:	85d6                	mv	a1,s5
    80004960:	8552                	mv	a0,s4
    80004962:	00000097          	auipc	ra,0x0
    80004966:	348080e7          	jalr	840(ra) # 80004caa <pipeclose>
    8000496a:	b7cd                	j	8000494c <fileclose+0xa8>

000000008000496c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000496c:	715d                	addi	sp,sp,-80
    8000496e:	e486                	sd	ra,72(sp)
    80004970:	e0a2                	sd	s0,64(sp)
    80004972:	fc26                	sd	s1,56(sp)
    80004974:	f84a                	sd	s2,48(sp)
    80004976:	f44e                	sd	s3,40(sp)
    80004978:	0880                	addi	s0,sp,80
    8000497a:	84aa                	mv	s1,a0
    8000497c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000497e:	ffffd097          	auipc	ra,0xffffd
    80004982:	028080e7          	jalr	40(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004986:	409c                	lw	a5,0(s1)
    80004988:	37f9                	addiw	a5,a5,-2
    8000498a:	4705                	li	a4,1
    8000498c:	04f76763          	bltu	a4,a5,800049da <filestat+0x6e>
    80004990:	892a                	mv	s2,a0
    ilock(f->ip);
    80004992:	6c88                	ld	a0,24(s1)
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	0a6080e7          	jalr	166(ra) # 80003a3a <ilock>
    stati(f->ip, &st);
    8000499c:	fb840593          	addi	a1,s0,-72
    800049a0:	6c88                	ld	a0,24(s1)
    800049a2:	fffff097          	auipc	ra,0xfffff
    800049a6:	322080e7          	jalr	802(ra) # 80003cc4 <stati>
    iunlock(f->ip);
    800049aa:	6c88                	ld	a0,24(s1)
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	150080e7          	jalr	336(ra) # 80003afc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049b4:	46e1                	li	a3,24
    800049b6:	fb840613          	addi	a2,s0,-72
    800049ba:	85ce                	mv	a1,s3
    800049bc:	05093503          	ld	a0,80(s2)
    800049c0:	ffffd097          	auipc	ra,0xffffd
    800049c4:	ca6080e7          	jalr	-858(ra) # 80001666 <copyout>
    800049c8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049cc:	60a6                	ld	ra,72(sp)
    800049ce:	6406                	ld	s0,64(sp)
    800049d0:	74e2                	ld	s1,56(sp)
    800049d2:	7942                	ld	s2,48(sp)
    800049d4:	79a2                	ld	s3,40(sp)
    800049d6:	6161                	addi	sp,sp,80
    800049d8:	8082                	ret
  return -1;
    800049da:	557d                	li	a0,-1
    800049dc:	bfc5                	j	800049cc <filestat+0x60>

00000000800049de <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049de:	7179                	addi	sp,sp,-48
    800049e0:	f406                	sd	ra,40(sp)
    800049e2:	f022                	sd	s0,32(sp)
    800049e4:	ec26                	sd	s1,24(sp)
    800049e6:	e84a                	sd	s2,16(sp)
    800049e8:	e44e                	sd	s3,8(sp)
    800049ea:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049ec:	00854783          	lbu	a5,8(a0)
    800049f0:	c3d5                	beqz	a5,80004a94 <fileread+0xb6>
    800049f2:	84aa                	mv	s1,a0
    800049f4:	89ae                	mv	s3,a1
    800049f6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049f8:	411c                	lw	a5,0(a0)
    800049fa:	4705                	li	a4,1
    800049fc:	04e78963          	beq	a5,a4,80004a4e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a00:	470d                	li	a4,3
    80004a02:	04e78d63          	beq	a5,a4,80004a5c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a06:	4709                	li	a4,2
    80004a08:	06e79e63          	bne	a5,a4,80004a84 <fileread+0xa6>
    ilock(f->ip);
    80004a0c:	6d08                	ld	a0,24(a0)
    80004a0e:	fffff097          	auipc	ra,0xfffff
    80004a12:	02c080e7          	jalr	44(ra) # 80003a3a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a16:	874a                	mv	a4,s2
    80004a18:	5094                	lw	a3,32(s1)
    80004a1a:	864e                	mv	a2,s3
    80004a1c:	4585                	li	a1,1
    80004a1e:	6c88                	ld	a0,24(s1)
    80004a20:	fffff097          	auipc	ra,0xfffff
    80004a24:	2ce080e7          	jalr	718(ra) # 80003cee <readi>
    80004a28:	892a                	mv	s2,a0
    80004a2a:	00a05563          	blez	a0,80004a34 <fileread+0x56>
      f->off += r;
    80004a2e:	509c                	lw	a5,32(s1)
    80004a30:	9fa9                	addw	a5,a5,a0
    80004a32:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a34:	6c88                	ld	a0,24(s1)
    80004a36:	fffff097          	auipc	ra,0xfffff
    80004a3a:	0c6080e7          	jalr	198(ra) # 80003afc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a3e:	854a                	mv	a0,s2
    80004a40:	70a2                	ld	ra,40(sp)
    80004a42:	7402                	ld	s0,32(sp)
    80004a44:	64e2                	ld	s1,24(sp)
    80004a46:	6942                	ld	s2,16(sp)
    80004a48:	69a2                	ld	s3,8(sp)
    80004a4a:	6145                	addi	sp,sp,48
    80004a4c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a4e:	6908                	ld	a0,16(a0)
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	3c2080e7          	jalr	962(ra) # 80004e12 <piperead>
    80004a58:	892a                	mv	s2,a0
    80004a5a:	b7d5                	j	80004a3e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a5c:	02451783          	lh	a5,36(a0)
    80004a60:	03079693          	slli	a3,a5,0x30
    80004a64:	92c1                	srli	a3,a3,0x30
    80004a66:	4725                	li	a4,9
    80004a68:	02d76863          	bltu	a4,a3,80004a98 <fileread+0xba>
    80004a6c:	0792                	slli	a5,a5,0x4
    80004a6e:	0001d717          	auipc	a4,0x1d
    80004a72:	b7a70713          	addi	a4,a4,-1158 # 800215e8 <devsw>
    80004a76:	97ba                	add	a5,a5,a4
    80004a78:	639c                	ld	a5,0(a5)
    80004a7a:	c38d                	beqz	a5,80004a9c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a7c:	4505                	li	a0,1
    80004a7e:	9782                	jalr	a5
    80004a80:	892a                	mv	s2,a0
    80004a82:	bf75                	j	80004a3e <fileread+0x60>
    panic("fileread");
    80004a84:	00004517          	auipc	a0,0x4
    80004a88:	c4450513          	addi	a0,a0,-956 # 800086c8 <syscalls+0x278>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	ab0080e7          	jalr	-1360(ra) # 8000053c <panic>
    return -1;
    80004a94:	597d                	li	s2,-1
    80004a96:	b765                	j	80004a3e <fileread+0x60>
      return -1;
    80004a98:	597d                	li	s2,-1
    80004a9a:	b755                	j	80004a3e <fileread+0x60>
    80004a9c:	597d                	li	s2,-1
    80004a9e:	b745                	j	80004a3e <fileread+0x60>

0000000080004aa0 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004aa0:	00954783          	lbu	a5,9(a0)
    80004aa4:	10078e63          	beqz	a5,80004bc0 <filewrite+0x120>
{
    80004aa8:	715d                	addi	sp,sp,-80
    80004aaa:	e486                	sd	ra,72(sp)
    80004aac:	e0a2                	sd	s0,64(sp)
    80004aae:	fc26                	sd	s1,56(sp)
    80004ab0:	f84a                	sd	s2,48(sp)
    80004ab2:	f44e                	sd	s3,40(sp)
    80004ab4:	f052                	sd	s4,32(sp)
    80004ab6:	ec56                	sd	s5,24(sp)
    80004ab8:	e85a                	sd	s6,16(sp)
    80004aba:	e45e                	sd	s7,8(sp)
    80004abc:	e062                	sd	s8,0(sp)
    80004abe:	0880                	addi	s0,sp,80
    80004ac0:	892a                	mv	s2,a0
    80004ac2:	8b2e                	mv	s6,a1
    80004ac4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ac6:	411c                	lw	a5,0(a0)
    80004ac8:	4705                	li	a4,1
    80004aca:	02e78263          	beq	a5,a4,80004aee <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ace:	470d                	li	a4,3
    80004ad0:	02e78563          	beq	a5,a4,80004afa <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ad4:	4709                	li	a4,2
    80004ad6:	0ce79d63          	bne	a5,a4,80004bb0 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ada:	0ac05b63          	blez	a2,80004b90 <filewrite+0xf0>
    int i = 0;
    80004ade:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004ae0:	6b85                	lui	s7,0x1
    80004ae2:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ae6:	6c05                	lui	s8,0x1
    80004ae8:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004aec:	a851                	j	80004b80 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004aee:	6908                	ld	a0,16(a0)
    80004af0:	00000097          	auipc	ra,0x0
    80004af4:	22a080e7          	jalr	554(ra) # 80004d1a <pipewrite>
    80004af8:	a045                	j	80004b98 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004afa:	02451783          	lh	a5,36(a0)
    80004afe:	03079693          	slli	a3,a5,0x30
    80004b02:	92c1                	srli	a3,a3,0x30
    80004b04:	4725                	li	a4,9
    80004b06:	0ad76f63          	bltu	a4,a3,80004bc4 <filewrite+0x124>
    80004b0a:	0792                	slli	a5,a5,0x4
    80004b0c:	0001d717          	auipc	a4,0x1d
    80004b10:	adc70713          	addi	a4,a4,-1316 # 800215e8 <devsw>
    80004b14:	97ba                	add	a5,a5,a4
    80004b16:	679c                	ld	a5,8(a5)
    80004b18:	cbc5                	beqz	a5,80004bc8 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004b1a:	4505                	li	a0,1
    80004b1c:	9782                	jalr	a5
    80004b1e:	a8ad                	j	80004b98 <filewrite+0xf8>
      if(n1 > max)
    80004b20:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004b24:	00000097          	auipc	ra,0x0
    80004b28:	8bc080e7          	jalr	-1860(ra) # 800043e0 <begin_op>
      ilock(f->ip);
    80004b2c:	01893503          	ld	a0,24(s2)
    80004b30:	fffff097          	auipc	ra,0xfffff
    80004b34:	f0a080e7          	jalr	-246(ra) # 80003a3a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b38:	8756                	mv	a4,s5
    80004b3a:	02092683          	lw	a3,32(s2)
    80004b3e:	01698633          	add	a2,s3,s6
    80004b42:	4585                	li	a1,1
    80004b44:	01893503          	ld	a0,24(s2)
    80004b48:	fffff097          	auipc	ra,0xfffff
    80004b4c:	29e080e7          	jalr	670(ra) # 80003de6 <writei>
    80004b50:	84aa                	mv	s1,a0
    80004b52:	00a05763          	blez	a0,80004b60 <filewrite+0xc0>
        f->off += r;
    80004b56:	02092783          	lw	a5,32(s2)
    80004b5a:	9fa9                	addw	a5,a5,a0
    80004b5c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b60:	01893503          	ld	a0,24(s2)
    80004b64:	fffff097          	auipc	ra,0xfffff
    80004b68:	f98080e7          	jalr	-104(ra) # 80003afc <iunlock>
      end_op();
    80004b6c:	00000097          	auipc	ra,0x0
    80004b70:	8ee080e7          	jalr	-1810(ra) # 8000445a <end_op>

      if(r != n1){
    80004b74:	009a9f63          	bne	s5,s1,80004b92 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004b78:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b7c:	0149db63          	bge	s3,s4,80004b92 <filewrite+0xf2>
      int n1 = n - i;
    80004b80:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004b84:	0004879b          	sext.w	a5,s1
    80004b88:	f8fbdce3          	bge	s7,a5,80004b20 <filewrite+0x80>
    80004b8c:	84e2                	mv	s1,s8
    80004b8e:	bf49                	j	80004b20 <filewrite+0x80>
    int i = 0;
    80004b90:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b92:	033a1d63          	bne	s4,s3,80004bcc <filewrite+0x12c>
    80004b96:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b98:	60a6                	ld	ra,72(sp)
    80004b9a:	6406                	ld	s0,64(sp)
    80004b9c:	74e2                	ld	s1,56(sp)
    80004b9e:	7942                	ld	s2,48(sp)
    80004ba0:	79a2                	ld	s3,40(sp)
    80004ba2:	7a02                	ld	s4,32(sp)
    80004ba4:	6ae2                	ld	s5,24(sp)
    80004ba6:	6b42                	ld	s6,16(sp)
    80004ba8:	6ba2                	ld	s7,8(sp)
    80004baa:	6c02                	ld	s8,0(sp)
    80004bac:	6161                	addi	sp,sp,80
    80004bae:	8082                	ret
    panic("filewrite");
    80004bb0:	00004517          	auipc	a0,0x4
    80004bb4:	b2850513          	addi	a0,a0,-1240 # 800086d8 <syscalls+0x288>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	984080e7          	jalr	-1660(ra) # 8000053c <panic>
    return -1;
    80004bc0:	557d                	li	a0,-1
}
    80004bc2:	8082                	ret
      return -1;
    80004bc4:	557d                	li	a0,-1
    80004bc6:	bfc9                	j	80004b98 <filewrite+0xf8>
    80004bc8:	557d                	li	a0,-1
    80004bca:	b7f9                	j	80004b98 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004bcc:	557d                	li	a0,-1
    80004bce:	b7e9                	j	80004b98 <filewrite+0xf8>

0000000080004bd0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bd0:	7179                	addi	sp,sp,-48
    80004bd2:	f406                	sd	ra,40(sp)
    80004bd4:	f022                	sd	s0,32(sp)
    80004bd6:	ec26                	sd	s1,24(sp)
    80004bd8:	e84a                	sd	s2,16(sp)
    80004bda:	e44e                	sd	s3,8(sp)
    80004bdc:	e052                	sd	s4,0(sp)
    80004bde:	1800                	addi	s0,sp,48
    80004be0:	84aa                	mv	s1,a0
    80004be2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004be4:	0005b023          	sd	zero,0(a1)
    80004be8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bec:	00000097          	auipc	ra,0x0
    80004bf0:	bfc080e7          	jalr	-1028(ra) # 800047e8 <filealloc>
    80004bf4:	e088                	sd	a0,0(s1)
    80004bf6:	c551                	beqz	a0,80004c82 <pipealloc+0xb2>
    80004bf8:	00000097          	auipc	ra,0x0
    80004bfc:	bf0080e7          	jalr	-1040(ra) # 800047e8 <filealloc>
    80004c00:	00aa3023          	sd	a0,0(s4)
    80004c04:	c92d                	beqz	a0,80004c76 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	edc080e7          	jalr	-292(ra) # 80000ae2 <kalloc>
    80004c0e:	892a                	mv	s2,a0
    80004c10:	c125                	beqz	a0,80004c70 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c12:	4985                	li	s3,1
    80004c14:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c18:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c1c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c20:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c24:	00004597          	auipc	a1,0x4
    80004c28:	ac458593          	addi	a1,a1,-1340 # 800086e8 <syscalls+0x298>
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	f16080e7          	jalr	-234(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004c34:	609c                	ld	a5,0(s1)
    80004c36:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c3a:	609c                	ld	a5,0(s1)
    80004c3c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c40:	609c                	ld	a5,0(s1)
    80004c42:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c46:	609c                	ld	a5,0(s1)
    80004c48:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c4c:	000a3783          	ld	a5,0(s4)
    80004c50:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c54:	000a3783          	ld	a5,0(s4)
    80004c58:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c5c:	000a3783          	ld	a5,0(s4)
    80004c60:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c64:	000a3783          	ld	a5,0(s4)
    80004c68:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c6c:	4501                	li	a0,0
    80004c6e:	a025                	j	80004c96 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c70:	6088                	ld	a0,0(s1)
    80004c72:	e501                	bnez	a0,80004c7a <pipealloc+0xaa>
    80004c74:	a039                	j	80004c82 <pipealloc+0xb2>
    80004c76:	6088                	ld	a0,0(s1)
    80004c78:	c51d                	beqz	a0,80004ca6 <pipealloc+0xd6>
    fileclose(*f0);
    80004c7a:	00000097          	auipc	ra,0x0
    80004c7e:	c2a080e7          	jalr	-982(ra) # 800048a4 <fileclose>
  if(*f1)
    80004c82:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c86:	557d                	li	a0,-1
  if(*f1)
    80004c88:	c799                	beqz	a5,80004c96 <pipealloc+0xc6>
    fileclose(*f1);
    80004c8a:	853e                	mv	a0,a5
    80004c8c:	00000097          	auipc	ra,0x0
    80004c90:	c18080e7          	jalr	-1000(ra) # 800048a4 <fileclose>
  return -1;
    80004c94:	557d                	li	a0,-1
}
    80004c96:	70a2                	ld	ra,40(sp)
    80004c98:	7402                	ld	s0,32(sp)
    80004c9a:	64e2                	ld	s1,24(sp)
    80004c9c:	6942                	ld	s2,16(sp)
    80004c9e:	69a2                	ld	s3,8(sp)
    80004ca0:	6a02                	ld	s4,0(sp)
    80004ca2:	6145                	addi	sp,sp,48
    80004ca4:	8082                	ret
  return -1;
    80004ca6:	557d                	li	a0,-1
    80004ca8:	b7fd                	j	80004c96 <pipealloc+0xc6>

0000000080004caa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004caa:	1101                	addi	sp,sp,-32
    80004cac:	ec06                	sd	ra,24(sp)
    80004cae:	e822                	sd	s0,16(sp)
    80004cb0:	e426                	sd	s1,8(sp)
    80004cb2:	e04a                	sd	s2,0(sp)
    80004cb4:	1000                	addi	s0,sp,32
    80004cb6:	84aa                	mv	s1,a0
    80004cb8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	f18080e7          	jalr	-232(ra) # 80000bd2 <acquire>
  if(writable){
    80004cc2:	02090d63          	beqz	s2,80004cfc <pipeclose+0x52>
    pi->writeopen = 0;
    80004cc6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cca:	21848513          	addi	a0,s1,536
    80004cce:	ffffd097          	auipc	ra,0xffffd
    80004cd2:	48e080e7          	jalr	1166(ra) # 8000215c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cd6:	2204b783          	ld	a5,544(s1)
    80004cda:	eb95                	bnez	a5,80004d0e <pipeclose+0x64>
    release(&pi->lock);
    80004cdc:	8526                	mv	a0,s1
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	fa8080e7          	jalr	-88(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004ce6:	8526                	mv	a0,s1
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	cfc080e7          	jalr	-772(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004cf0:	60e2                	ld	ra,24(sp)
    80004cf2:	6442                	ld	s0,16(sp)
    80004cf4:	64a2                	ld	s1,8(sp)
    80004cf6:	6902                	ld	s2,0(sp)
    80004cf8:	6105                	addi	sp,sp,32
    80004cfa:	8082                	ret
    pi->readopen = 0;
    80004cfc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d00:	21c48513          	addi	a0,s1,540
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	458080e7          	jalr	1112(ra) # 8000215c <wakeup>
    80004d0c:	b7e9                	j	80004cd6 <pipeclose+0x2c>
    release(&pi->lock);
    80004d0e:	8526                	mv	a0,s1
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	f76080e7          	jalr	-138(ra) # 80000c86 <release>
}
    80004d18:	bfe1                	j	80004cf0 <pipeclose+0x46>

0000000080004d1a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d1a:	711d                	addi	sp,sp,-96
    80004d1c:	ec86                	sd	ra,88(sp)
    80004d1e:	e8a2                	sd	s0,80(sp)
    80004d20:	e4a6                	sd	s1,72(sp)
    80004d22:	e0ca                	sd	s2,64(sp)
    80004d24:	fc4e                	sd	s3,56(sp)
    80004d26:	f852                	sd	s4,48(sp)
    80004d28:	f456                	sd	s5,40(sp)
    80004d2a:	f05a                	sd	s6,32(sp)
    80004d2c:	ec5e                	sd	s7,24(sp)
    80004d2e:	e862                	sd	s8,16(sp)
    80004d30:	1080                	addi	s0,sp,96
    80004d32:	84aa                	mv	s1,a0
    80004d34:	8aae                	mv	s5,a1
    80004d36:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d38:	ffffd097          	auipc	ra,0xffffd
    80004d3c:	c6e080e7          	jalr	-914(ra) # 800019a6 <myproc>
    80004d40:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d42:	8526                	mv	a0,s1
    80004d44:	ffffc097          	auipc	ra,0xffffc
    80004d48:	e8e080e7          	jalr	-370(ra) # 80000bd2 <acquire>
  while(i < n){
    80004d4c:	0b405663          	blez	s4,80004df8 <pipewrite+0xde>
  int i = 0;
    80004d50:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d52:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d54:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d58:	21c48b93          	addi	s7,s1,540
    80004d5c:	a089                	j	80004d9e <pipewrite+0x84>
      release(&pi->lock);
    80004d5e:	8526                	mv	a0,s1
    80004d60:	ffffc097          	auipc	ra,0xffffc
    80004d64:	f26080e7          	jalr	-218(ra) # 80000c86 <release>
      return -1;
    80004d68:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d6a:	854a                	mv	a0,s2
    80004d6c:	60e6                	ld	ra,88(sp)
    80004d6e:	6446                	ld	s0,80(sp)
    80004d70:	64a6                	ld	s1,72(sp)
    80004d72:	6906                	ld	s2,64(sp)
    80004d74:	79e2                	ld	s3,56(sp)
    80004d76:	7a42                	ld	s4,48(sp)
    80004d78:	7aa2                	ld	s5,40(sp)
    80004d7a:	7b02                	ld	s6,32(sp)
    80004d7c:	6be2                	ld	s7,24(sp)
    80004d7e:	6c42                	ld	s8,16(sp)
    80004d80:	6125                	addi	sp,sp,96
    80004d82:	8082                	ret
      wakeup(&pi->nread);
    80004d84:	8562                	mv	a0,s8
    80004d86:	ffffd097          	auipc	ra,0xffffd
    80004d8a:	3d6080e7          	jalr	982(ra) # 8000215c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d8e:	85a6                	mv	a1,s1
    80004d90:	855e                	mv	a0,s7
    80004d92:	ffffd097          	auipc	ra,0xffffd
    80004d96:	366080e7          	jalr	870(ra) # 800020f8 <sleep>
  while(i < n){
    80004d9a:	07495063          	bge	s2,s4,80004dfa <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d9e:	2204a783          	lw	a5,544(s1)
    80004da2:	dfd5                	beqz	a5,80004d5e <pipewrite+0x44>
    80004da4:	854e                	mv	a0,s3
    80004da6:	ffffd097          	auipc	ra,0xffffd
    80004daa:	606080e7          	jalr	1542(ra) # 800023ac <killed>
    80004dae:	f945                	bnez	a0,80004d5e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004db0:	2184a783          	lw	a5,536(s1)
    80004db4:	21c4a703          	lw	a4,540(s1)
    80004db8:	2007879b          	addiw	a5,a5,512
    80004dbc:	fcf704e3          	beq	a4,a5,80004d84 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dc0:	4685                	li	a3,1
    80004dc2:	01590633          	add	a2,s2,s5
    80004dc6:	faf40593          	addi	a1,s0,-81
    80004dca:	0509b503          	ld	a0,80(s3)
    80004dce:	ffffd097          	auipc	ra,0xffffd
    80004dd2:	924080e7          	jalr	-1756(ra) # 800016f2 <copyin>
    80004dd6:	03650263          	beq	a0,s6,80004dfa <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dda:	21c4a783          	lw	a5,540(s1)
    80004dde:	0017871b          	addiw	a4,a5,1
    80004de2:	20e4ae23          	sw	a4,540(s1)
    80004de6:	1ff7f793          	andi	a5,a5,511
    80004dea:	97a6                	add	a5,a5,s1
    80004dec:	faf44703          	lbu	a4,-81(s0)
    80004df0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004df4:	2905                	addiw	s2,s2,1
    80004df6:	b755                	j	80004d9a <pipewrite+0x80>
  int i = 0;
    80004df8:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004dfa:	21848513          	addi	a0,s1,536
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	35e080e7          	jalr	862(ra) # 8000215c <wakeup>
  release(&pi->lock);
    80004e06:	8526                	mv	a0,s1
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	e7e080e7          	jalr	-386(ra) # 80000c86 <release>
  return i;
    80004e10:	bfa9                	j	80004d6a <pipewrite+0x50>

0000000080004e12 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e12:	715d                	addi	sp,sp,-80
    80004e14:	e486                	sd	ra,72(sp)
    80004e16:	e0a2                	sd	s0,64(sp)
    80004e18:	fc26                	sd	s1,56(sp)
    80004e1a:	f84a                	sd	s2,48(sp)
    80004e1c:	f44e                	sd	s3,40(sp)
    80004e1e:	f052                	sd	s4,32(sp)
    80004e20:	ec56                	sd	s5,24(sp)
    80004e22:	e85a                	sd	s6,16(sp)
    80004e24:	0880                	addi	s0,sp,80
    80004e26:	84aa                	mv	s1,a0
    80004e28:	892e                	mv	s2,a1
    80004e2a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e2c:	ffffd097          	auipc	ra,0xffffd
    80004e30:	b7a080e7          	jalr	-1158(ra) # 800019a6 <myproc>
    80004e34:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e36:	8526                	mv	a0,s1
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	d9a080e7          	jalr	-614(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e40:	2184a703          	lw	a4,536(s1)
    80004e44:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e48:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e4c:	02f71763          	bne	a4,a5,80004e7a <piperead+0x68>
    80004e50:	2244a783          	lw	a5,548(s1)
    80004e54:	c39d                	beqz	a5,80004e7a <piperead+0x68>
    if(killed(pr)){
    80004e56:	8552                	mv	a0,s4
    80004e58:	ffffd097          	auipc	ra,0xffffd
    80004e5c:	554080e7          	jalr	1364(ra) # 800023ac <killed>
    80004e60:	e949                	bnez	a0,80004ef2 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e62:	85a6                	mv	a1,s1
    80004e64:	854e                	mv	a0,s3
    80004e66:	ffffd097          	auipc	ra,0xffffd
    80004e6a:	292080e7          	jalr	658(ra) # 800020f8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e6e:	2184a703          	lw	a4,536(s1)
    80004e72:	21c4a783          	lw	a5,540(s1)
    80004e76:	fcf70de3          	beq	a4,a5,80004e50 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e7a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e7c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e7e:	05505463          	blez	s5,80004ec6 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004e82:	2184a783          	lw	a5,536(s1)
    80004e86:	21c4a703          	lw	a4,540(s1)
    80004e8a:	02f70e63          	beq	a4,a5,80004ec6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e8e:	0017871b          	addiw	a4,a5,1
    80004e92:	20e4ac23          	sw	a4,536(s1)
    80004e96:	1ff7f793          	andi	a5,a5,511
    80004e9a:	97a6                	add	a5,a5,s1
    80004e9c:	0187c783          	lbu	a5,24(a5)
    80004ea0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ea4:	4685                	li	a3,1
    80004ea6:	fbf40613          	addi	a2,s0,-65
    80004eaa:	85ca                	mv	a1,s2
    80004eac:	050a3503          	ld	a0,80(s4)
    80004eb0:	ffffc097          	auipc	ra,0xffffc
    80004eb4:	7b6080e7          	jalr	1974(ra) # 80001666 <copyout>
    80004eb8:	01650763          	beq	a0,s6,80004ec6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ebc:	2985                	addiw	s3,s3,1
    80004ebe:	0905                	addi	s2,s2,1
    80004ec0:	fd3a91e3          	bne	s5,s3,80004e82 <piperead+0x70>
    80004ec4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ec6:	21c48513          	addi	a0,s1,540
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	292080e7          	jalr	658(ra) # 8000215c <wakeup>
  release(&pi->lock);
    80004ed2:	8526                	mv	a0,s1
    80004ed4:	ffffc097          	auipc	ra,0xffffc
    80004ed8:	db2080e7          	jalr	-590(ra) # 80000c86 <release>
  return i;
}
    80004edc:	854e                	mv	a0,s3
    80004ede:	60a6                	ld	ra,72(sp)
    80004ee0:	6406                	ld	s0,64(sp)
    80004ee2:	74e2                	ld	s1,56(sp)
    80004ee4:	7942                	ld	s2,48(sp)
    80004ee6:	79a2                	ld	s3,40(sp)
    80004ee8:	7a02                	ld	s4,32(sp)
    80004eea:	6ae2                	ld	s5,24(sp)
    80004eec:	6b42                	ld	s6,16(sp)
    80004eee:	6161                	addi	sp,sp,80
    80004ef0:	8082                	ret
      release(&pi->lock);
    80004ef2:	8526                	mv	a0,s1
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	d92080e7          	jalr	-622(ra) # 80000c86 <release>
      return -1;
    80004efc:	59fd                	li	s3,-1
    80004efe:	bff9                	j	80004edc <piperead+0xca>

0000000080004f00 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f00:	1141                	addi	sp,sp,-16
    80004f02:	e422                	sd	s0,8(sp)
    80004f04:	0800                	addi	s0,sp,16
    80004f06:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f08:	8905                	andi	a0,a0,1
    80004f0a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004f0c:	8b89                	andi	a5,a5,2
    80004f0e:	c399                	beqz	a5,80004f14 <flags2perm+0x14>
      perm |= PTE_W;
    80004f10:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f14:	6422                	ld	s0,8(sp)
    80004f16:	0141                	addi	sp,sp,16
    80004f18:	8082                	ret

0000000080004f1a <exec>:

int
exec(char *path, char **argv)
{
    80004f1a:	df010113          	addi	sp,sp,-528
    80004f1e:	20113423          	sd	ra,520(sp)
    80004f22:	20813023          	sd	s0,512(sp)
    80004f26:	ffa6                	sd	s1,504(sp)
    80004f28:	fbca                	sd	s2,496(sp)
    80004f2a:	f7ce                	sd	s3,488(sp)
    80004f2c:	f3d2                	sd	s4,480(sp)
    80004f2e:	efd6                	sd	s5,472(sp)
    80004f30:	ebda                	sd	s6,464(sp)
    80004f32:	e7de                	sd	s7,456(sp)
    80004f34:	e3e2                	sd	s8,448(sp)
    80004f36:	ff66                	sd	s9,440(sp)
    80004f38:	fb6a                	sd	s10,432(sp)
    80004f3a:	f76e                	sd	s11,424(sp)
    80004f3c:	0c00                	addi	s0,sp,528
    80004f3e:	892a                	mv	s2,a0
    80004f40:	dea43c23          	sd	a0,-520(s0)
    80004f44:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f48:	ffffd097          	auipc	ra,0xffffd
    80004f4c:	a5e080e7          	jalr	-1442(ra) # 800019a6 <myproc>
    80004f50:	84aa                	mv	s1,a0

  begin_op();
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	48e080e7          	jalr	1166(ra) # 800043e0 <begin_op>

  if((ip = namei(path)) == 0){
    80004f5a:	854a                	mv	a0,s2
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	284080e7          	jalr	644(ra) # 800041e0 <namei>
    80004f64:	c92d                	beqz	a0,80004fd6 <exec+0xbc>
    80004f66:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	ad2080e7          	jalr	-1326(ra) # 80003a3a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f70:	04000713          	li	a4,64
    80004f74:	4681                	li	a3,0
    80004f76:	e5040613          	addi	a2,s0,-432
    80004f7a:	4581                	li	a1,0
    80004f7c:	8552                	mv	a0,s4
    80004f7e:	fffff097          	auipc	ra,0xfffff
    80004f82:	d70080e7          	jalr	-656(ra) # 80003cee <readi>
    80004f86:	04000793          	li	a5,64
    80004f8a:	00f51a63          	bne	a0,a5,80004f9e <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f8e:	e5042703          	lw	a4,-432(s0)
    80004f92:	464c47b7          	lui	a5,0x464c4
    80004f96:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f9a:	04f70463          	beq	a4,a5,80004fe2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f9e:	8552                	mv	a0,s4
    80004fa0:	fffff097          	auipc	ra,0xfffff
    80004fa4:	cfc080e7          	jalr	-772(ra) # 80003c9c <iunlockput>
    end_op();
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	4b2080e7          	jalr	1202(ra) # 8000445a <end_op>
  }
  return -1;
    80004fb0:	557d                	li	a0,-1
}
    80004fb2:	20813083          	ld	ra,520(sp)
    80004fb6:	20013403          	ld	s0,512(sp)
    80004fba:	74fe                	ld	s1,504(sp)
    80004fbc:	795e                	ld	s2,496(sp)
    80004fbe:	79be                	ld	s3,488(sp)
    80004fc0:	7a1e                	ld	s4,480(sp)
    80004fc2:	6afe                	ld	s5,472(sp)
    80004fc4:	6b5e                	ld	s6,464(sp)
    80004fc6:	6bbe                	ld	s7,456(sp)
    80004fc8:	6c1e                	ld	s8,448(sp)
    80004fca:	7cfa                	ld	s9,440(sp)
    80004fcc:	7d5a                	ld	s10,432(sp)
    80004fce:	7dba                	ld	s11,424(sp)
    80004fd0:	21010113          	addi	sp,sp,528
    80004fd4:	8082                	ret
    end_op();
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	484080e7          	jalr	1156(ra) # 8000445a <end_op>
    return -1;
    80004fde:	557d                	li	a0,-1
    80004fe0:	bfc9                	j	80004fb2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fe2:	8526                	mv	a0,s1
    80004fe4:	ffffd097          	auipc	ra,0xffffd
    80004fe8:	aec080e7          	jalr	-1300(ra) # 80001ad0 <proc_pagetable>
    80004fec:	8b2a                	mv	s6,a0
    80004fee:	d945                	beqz	a0,80004f9e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ff0:	e7042d03          	lw	s10,-400(s0)
    80004ff4:	e8845783          	lhu	a5,-376(s0)
    80004ff8:	10078463          	beqz	a5,80005100 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ffc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ffe:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005000:	6c85                	lui	s9,0x1
    80005002:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005006:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000500a:	6a85                	lui	s5,0x1
    8000500c:	a0b5                	j	80005078 <exec+0x15e>
      panic("loadseg: address should exist");
    8000500e:	00003517          	auipc	a0,0x3
    80005012:	6e250513          	addi	a0,a0,1762 # 800086f0 <syscalls+0x2a0>
    80005016:	ffffb097          	auipc	ra,0xffffb
    8000501a:	526080e7          	jalr	1318(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    8000501e:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005020:	8726                	mv	a4,s1
    80005022:	012c06bb          	addw	a3,s8,s2
    80005026:	4581                	li	a1,0
    80005028:	8552                	mv	a0,s4
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	cc4080e7          	jalr	-828(ra) # 80003cee <readi>
    80005032:	2501                	sext.w	a0,a0
    80005034:	24a49863          	bne	s1,a0,80005284 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80005038:	012a893b          	addw	s2,s5,s2
    8000503c:	03397563          	bgeu	s2,s3,80005066 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005040:	02091593          	slli	a1,s2,0x20
    80005044:	9181                	srli	a1,a1,0x20
    80005046:	95de                	add	a1,a1,s7
    80005048:	855a                	mv	a0,s6
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	00c080e7          	jalr	12(ra) # 80001056 <walkaddr>
    80005052:	862a                	mv	a2,a0
    if(pa == 0)
    80005054:	dd4d                	beqz	a0,8000500e <exec+0xf4>
    if(sz - i < PGSIZE)
    80005056:	412984bb          	subw	s1,s3,s2
    8000505a:	0004879b          	sext.w	a5,s1
    8000505e:	fcfcf0e3          	bgeu	s9,a5,8000501e <exec+0x104>
    80005062:	84d6                	mv	s1,s5
    80005064:	bf6d                	j	8000501e <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005066:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000506a:	2d85                	addiw	s11,s11,1
    8000506c:	038d0d1b          	addiw	s10,s10,56
    80005070:	e8845783          	lhu	a5,-376(s0)
    80005074:	08fdd763          	bge	s11,a5,80005102 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005078:	2d01                	sext.w	s10,s10
    8000507a:	03800713          	li	a4,56
    8000507e:	86ea                	mv	a3,s10
    80005080:	e1840613          	addi	a2,s0,-488
    80005084:	4581                	li	a1,0
    80005086:	8552                	mv	a0,s4
    80005088:	fffff097          	auipc	ra,0xfffff
    8000508c:	c66080e7          	jalr	-922(ra) # 80003cee <readi>
    80005090:	03800793          	li	a5,56
    80005094:	1ef51663          	bne	a0,a5,80005280 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005098:	e1842783          	lw	a5,-488(s0)
    8000509c:	4705                	li	a4,1
    8000509e:	fce796e3          	bne	a5,a4,8000506a <exec+0x150>
    if(ph.memsz < ph.filesz)
    800050a2:	e4043483          	ld	s1,-448(s0)
    800050a6:	e3843783          	ld	a5,-456(s0)
    800050aa:	1ef4e863          	bltu	s1,a5,8000529a <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050ae:	e2843783          	ld	a5,-472(s0)
    800050b2:	94be                	add	s1,s1,a5
    800050b4:	1ef4e663          	bltu	s1,a5,800052a0 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800050b8:	df043703          	ld	a4,-528(s0)
    800050bc:	8ff9                	and	a5,a5,a4
    800050be:	1e079463          	bnez	a5,800052a6 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050c2:	e1c42503          	lw	a0,-484(s0)
    800050c6:	00000097          	auipc	ra,0x0
    800050ca:	e3a080e7          	jalr	-454(ra) # 80004f00 <flags2perm>
    800050ce:	86aa                	mv	a3,a0
    800050d0:	8626                	mv	a2,s1
    800050d2:	85ca                	mv	a1,s2
    800050d4:	855a                	mv	a0,s6
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	334080e7          	jalr	820(ra) # 8000140a <uvmalloc>
    800050de:	e0a43423          	sd	a0,-504(s0)
    800050e2:	1c050563          	beqz	a0,800052ac <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050e6:	e2843b83          	ld	s7,-472(s0)
    800050ea:	e2042c03          	lw	s8,-480(s0)
    800050ee:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050f2:	00098463          	beqz	s3,800050fa <exec+0x1e0>
    800050f6:	4901                	li	s2,0
    800050f8:	b7a1                	j	80005040 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050fa:	e0843903          	ld	s2,-504(s0)
    800050fe:	b7b5                	j	8000506a <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005100:	4901                	li	s2,0
  iunlockput(ip);
    80005102:	8552                	mv	a0,s4
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	b98080e7          	jalr	-1128(ra) # 80003c9c <iunlockput>
  end_op();
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	34e080e7          	jalr	846(ra) # 8000445a <end_op>
  p = myproc();
    80005114:	ffffd097          	auipc	ra,0xffffd
    80005118:	892080e7          	jalr	-1902(ra) # 800019a6 <myproc>
    8000511c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000511e:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005122:	6985                	lui	s3,0x1
    80005124:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005126:	99ca                	add	s3,s3,s2
    80005128:	77fd                	lui	a5,0xfffff
    8000512a:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000512e:	4691                	li	a3,4
    80005130:	6609                	lui	a2,0x2
    80005132:	964e                	add	a2,a2,s3
    80005134:	85ce                	mv	a1,s3
    80005136:	855a                	mv	a0,s6
    80005138:	ffffc097          	auipc	ra,0xffffc
    8000513c:	2d2080e7          	jalr	722(ra) # 8000140a <uvmalloc>
    80005140:	892a                	mv	s2,a0
    80005142:	e0a43423          	sd	a0,-504(s0)
    80005146:	e509                	bnez	a0,80005150 <exec+0x236>
  if(pagetable)
    80005148:	e1343423          	sd	s3,-504(s0)
    8000514c:	4a01                	li	s4,0
    8000514e:	aa1d                	j	80005284 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005150:	75f9                	lui	a1,0xffffe
    80005152:	95aa                	add	a1,a1,a0
    80005154:	855a                	mv	a0,s6
    80005156:	ffffc097          	auipc	ra,0xffffc
    8000515a:	4de080e7          	jalr	1246(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    8000515e:	7bfd                	lui	s7,0xfffff
    80005160:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005162:	e0043783          	ld	a5,-512(s0)
    80005166:	6388                	ld	a0,0(a5)
    80005168:	c52d                	beqz	a0,800051d2 <exec+0x2b8>
    8000516a:	e9040993          	addi	s3,s0,-368
    8000516e:	f9040c13          	addi	s8,s0,-112
    80005172:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005174:	ffffc097          	auipc	ra,0xffffc
    80005178:	cd4080e7          	jalr	-812(ra) # 80000e48 <strlen>
    8000517c:	0015079b          	addiw	a5,a0,1
    80005180:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005184:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005188:	13796563          	bltu	s2,s7,800052b2 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000518c:	e0043d03          	ld	s10,-512(s0)
    80005190:	000d3a03          	ld	s4,0(s10)
    80005194:	8552                	mv	a0,s4
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	cb2080e7          	jalr	-846(ra) # 80000e48 <strlen>
    8000519e:	0015069b          	addiw	a3,a0,1
    800051a2:	8652                	mv	a2,s4
    800051a4:	85ca                	mv	a1,s2
    800051a6:	855a                	mv	a0,s6
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	4be080e7          	jalr	1214(ra) # 80001666 <copyout>
    800051b0:	10054363          	bltz	a0,800052b6 <exec+0x39c>
    ustack[argc] = sp;
    800051b4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051b8:	0485                	addi	s1,s1,1
    800051ba:	008d0793          	addi	a5,s10,8
    800051be:	e0f43023          	sd	a5,-512(s0)
    800051c2:	008d3503          	ld	a0,8(s10)
    800051c6:	c909                	beqz	a0,800051d8 <exec+0x2be>
    if(argc >= MAXARG)
    800051c8:	09a1                	addi	s3,s3,8
    800051ca:	fb8995e3          	bne	s3,s8,80005174 <exec+0x25a>
  ip = 0;
    800051ce:	4a01                	li	s4,0
    800051d0:	a855                	j	80005284 <exec+0x36a>
  sp = sz;
    800051d2:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800051d6:	4481                	li	s1,0
  ustack[argc] = 0;
    800051d8:	00349793          	slli	a5,s1,0x3
    800051dc:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdc810>
    800051e0:	97a2                	add	a5,a5,s0
    800051e2:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800051e6:	00148693          	addi	a3,s1,1
    800051ea:	068e                	slli	a3,a3,0x3
    800051ec:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051f0:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800051f4:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800051f8:	f57968e3          	bltu	s2,s7,80005148 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051fc:	e9040613          	addi	a2,s0,-368
    80005200:	85ca                	mv	a1,s2
    80005202:	855a                	mv	a0,s6
    80005204:	ffffc097          	auipc	ra,0xffffc
    80005208:	462080e7          	jalr	1122(ra) # 80001666 <copyout>
    8000520c:	0a054763          	bltz	a0,800052ba <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005210:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005214:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005218:	df843783          	ld	a5,-520(s0)
    8000521c:	0007c703          	lbu	a4,0(a5)
    80005220:	cf11                	beqz	a4,8000523c <exec+0x322>
    80005222:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005224:	02f00693          	li	a3,47
    80005228:	a039                	j	80005236 <exec+0x31c>
      last = s+1;
    8000522a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000522e:	0785                	addi	a5,a5,1
    80005230:	fff7c703          	lbu	a4,-1(a5)
    80005234:	c701                	beqz	a4,8000523c <exec+0x322>
    if(*s == '/')
    80005236:	fed71ce3          	bne	a4,a3,8000522e <exec+0x314>
    8000523a:	bfc5                	j	8000522a <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    8000523c:	4641                	li	a2,16
    8000523e:	df843583          	ld	a1,-520(s0)
    80005242:	158a8513          	addi	a0,s5,344
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	bd0080e7          	jalr	-1072(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    8000524e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005252:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005256:	e0843783          	ld	a5,-504(s0)
    8000525a:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000525e:	058ab783          	ld	a5,88(s5)
    80005262:	e6843703          	ld	a4,-408(s0)
    80005266:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005268:	058ab783          	ld	a5,88(s5)
    8000526c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005270:	85e6                	mv	a1,s9
    80005272:	ffffd097          	auipc	ra,0xffffd
    80005276:	8fa080e7          	jalr	-1798(ra) # 80001b6c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000527a:	0004851b          	sext.w	a0,s1
    8000527e:	bb15                	j	80004fb2 <exec+0x98>
    80005280:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005284:	e0843583          	ld	a1,-504(s0)
    80005288:	855a                	mv	a0,s6
    8000528a:	ffffd097          	auipc	ra,0xffffd
    8000528e:	8e2080e7          	jalr	-1822(ra) # 80001b6c <proc_freepagetable>
  return -1;
    80005292:	557d                	li	a0,-1
  if(ip){
    80005294:	d00a0fe3          	beqz	s4,80004fb2 <exec+0x98>
    80005298:	b319                	j	80004f9e <exec+0x84>
    8000529a:	e1243423          	sd	s2,-504(s0)
    8000529e:	b7dd                	j	80005284 <exec+0x36a>
    800052a0:	e1243423          	sd	s2,-504(s0)
    800052a4:	b7c5                	j	80005284 <exec+0x36a>
    800052a6:	e1243423          	sd	s2,-504(s0)
    800052aa:	bfe9                	j	80005284 <exec+0x36a>
    800052ac:	e1243423          	sd	s2,-504(s0)
    800052b0:	bfd1                	j	80005284 <exec+0x36a>
  ip = 0;
    800052b2:	4a01                	li	s4,0
    800052b4:	bfc1                	j	80005284 <exec+0x36a>
    800052b6:	4a01                	li	s4,0
  if(pagetable)
    800052b8:	b7f1                	j	80005284 <exec+0x36a>
  sz = sz1;
    800052ba:	e0843983          	ld	s3,-504(s0)
    800052be:	b569                	j	80005148 <exec+0x22e>

00000000800052c0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052c0:	7179                	addi	sp,sp,-48
    800052c2:	f406                	sd	ra,40(sp)
    800052c4:	f022                	sd	s0,32(sp)
    800052c6:	ec26                	sd	s1,24(sp)
    800052c8:	e84a                	sd	s2,16(sp)
    800052ca:	1800                	addi	s0,sp,48
    800052cc:	892e                	mv	s2,a1
    800052ce:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052d0:	fdc40593          	addi	a1,s0,-36
    800052d4:	ffffe097          	auipc	ra,0xffffe
    800052d8:	acc080e7          	jalr	-1332(ra) # 80002da0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052dc:	fdc42703          	lw	a4,-36(s0)
    800052e0:	47bd                	li	a5,15
    800052e2:	02e7eb63          	bltu	a5,a4,80005318 <argfd+0x58>
    800052e6:	ffffc097          	auipc	ra,0xffffc
    800052ea:	6c0080e7          	jalr	1728(ra) # 800019a6 <myproc>
    800052ee:	fdc42703          	lw	a4,-36(s0)
    800052f2:	01a70793          	addi	a5,a4,26
    800052f6:	078e                	slli	a5,a5,0x3
    800052f8:	953e                	add	a0,a0,a5
    800052fa:	611c                	ld	a5,0(a0)
    800052fc:	c385                	beqz	a5,8000531c <argfd+0x5c>
    return -1;
  if(pfd)
    800052fe:	00090463          	beqz	s2,80005306 <argfd+0x46>
    *pfd = fd;
    80005302:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005306:	4501                	li	a0,0
  if(pf)
    80005308:	c091                	beqz	s1,8000530c <argfd+0x4c>
    *pf = f;
    8000530a:	e09c                	sd	a5,0(s1)
}
    8000530c:	70a2                	ld	ra,40(sp)
    8000530e:	7402                	ld	s0,32(sp)
    80005310:	64e2                	ld	s1,24(sp)
    80005312:	6942                	ld	s2,16(sp)
    80005314:	6145                	addi	sp,sp,48
    80005316:	8082                	ret
    return -1;
    80005318:	557d                	li	a0,-1
    8000531a:	bfcd                	j	8000530c <argfd+0x4c>
    8000531c:	557d                	li	a0,-1
    8000531e:	b7fd                	j	8000530c <argfd+0x4c>

0000000080005320 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005320:	1101                	addi	sp,sp,-32
    80005322:	ec06                	sd	ra,24(sp)
    80005324:	e822                	sd	s0,16(sp)
    80005326:	e426                	sd	s1,8(sp)
    80005328:	1000                	addi	s0,sp,32
    8000532a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000532c:	ffffc097          	auipc	ra,0xffffc
    80005330:	67a080e7          	jalr	1658(ra) # 800019a6 <myproc>
    80005334:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005336:	0d050793          	addi	a5,a0,208
    8000533a:	4501                	li	a0,0
    8000533c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000533e:	6398                	ld	a4,0(a5)
    80005340:	cb19                	beqz	a4,80005356 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005342:	2505                	addiw	a0,a0,1
    80005344:	07a1                	addi	a5,a5,8
    80005346:	fed51ce3          	bne	a0,a3,8000533e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000534a:	557d                	li	a0,-1
}
    8000534c:	60e2                	ld	ra,24(sp)
    8000534e:	6442                	ld	s0,16(sp)
    80005350:	64a2                	ld	s1,8(sp)
    80005352:	6105                	addi	sp,sp,32
    80005354:	8082                	ret
      p->ofile[fd] = f;
    80005356:	01a50793          	addi	a5,a0,26
    8000535a:	078e                	slli	a5,a5,0x3
    8000535c:	963e                	add	a2,a2,a5
    8000535e:	e204                	sd	s1,0(a2)
      return fd;
    80005360:	b7f5                	j	8000534c <fdalloc+0x2c>

0000000080005362 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005362:	715d                	addi	sp,sp,-80
    80005364:	e486                	sd	ra,72(sp)
    80005366:	e0a2                	sd	s0,64(sp)
    80005368:	fc26                	sd	s1,56(sp)
    8000536a:	f84a                	sd	s2,48(sp)
    8000536c:	f44e                	sd	s3,40(sp)
    8000536e:	f052                	sd	s4,32(sp)
    80005370:	ec56                	sd	s5,24(sp)
    80005372:	e85a                	sd	s6,16(sp)
    80005374:	0880                	addi	s0,sp,80
    80005376:	8b2e                	mv	s6,a1
    80005378:	89b2                	mv	s3,a2
    8000537a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000537c:	fb040593          	addi	a1,s0,-80
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	e7e080e7          	jalr	-386(ra) # 800041fe <nameiparent>
    80005388:	84aa                	mv	s1,a0
    8000538a:	14050b63          	beqz	a0,800054e0 <create+0x17e>
    return 0;

  ilock(dp);
    8000538e:	ffffe097          	auipc	ra,0xffffe
    80005392:	6ac080e7          	jalr	1708(ra) # 80003a3a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005396:	4601                	li	a2,0
    80005398:	fb040593          	addi	a1,s0,-80
    8000539c:	8526                	mv	a0,s1
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	b80080e7          	jalr	-1152(ra) # 80003f1e <dirlookup>
    800053a6:	8aaa                	mv	s5,a0
    800053a8:	c921                	beqz	a0,800053f8 <create+0x96>
    iunlockput(dp);
    800053aa:	8526                	mv	a0,s1
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	8f0080e7          	jalr	-1808(ra) # 80003c9c <iunlockput>
    ilock(ip);
    800053b4:	8556                	mv	a0,s5
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	684080e7          	jalr	1668(ra) # 80003a3a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053be:	4789                	li	a5,2
    800053c0:	02fb1563          	bne	s6,a5,800053ea <create+0x88>
    800053c4:	044ad783          	lhu	a5,68(s5)
    800053c8:	37f9                	addiw	a5,a5,-2
    800053ca:	17c2                	slli	a5,a5,0x30
    800053cc:	93c1                	srli	a5,a5,0x30
    800053ce:	4705                	li	a4,1
    800053d0:	00f76d63          	bltu	a4,a5,800053ea <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053d4:	8556                	mv	a0,s5
    800053d6:	60a6                	ld	ra,72(sp)
    800053d8:	6406                	ld	s0,64(sp)
    800053da:	74e2                	ld	s1,56(sp)
    800053dc:	7942                	ld	s2,48(sp)
    800053de:	79a2                	ld	s3,40(sp)
    800053e0:	7a02                	ld	s4,32(sp)
    800053e2:	6ae2                	ld	s5,24(sp)
    800053e4:	6b42                	ld	s6,16(sp)
    800053e6:	6161                	addi	sp,sp,80
    800053e8:	8082                	ret
    iunlockput(ip);
    800053ea:	8556                	mv	a0,s5
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	8b0080e7          	jalr	-1872(ra) # 80003c9c <iunlockput>
    return 0;
    800053f4:	4a81                	li	s5,0
    800053f6:	bff9                	j	800053d4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800053f8:	85da                	mv	a1,s6
    800053fa:	4088                	lw	a0,0(s1)
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	4a6080e7          	jalr	1190(ra) # 800038a2 <ialloc>
    80005404:	8a2a                	mv	s4,a0
    80005406:	c529                	beqz	a0,80005450 <create+0xee>
  ilock(ip);
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	632080e7          	jalr	1586(ra) # 80003a3a <ilock>
  ip->major = major;
    80005410:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005414:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005418:	4905                	li	s2,1
    8000541a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000541e:	8552                	mv	a0,s4
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	54e080e7          	jalr	1358(ra) # 8000396e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005428:	032b0b63          	beq	s6,s2,8000545e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000542c:	004a2603          	lw	a2,4(s4)
    80005430:	fb040593          	addi	a1,s0,-80
    80005434:	8526                	mv	a0,s1
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	cf8080e7          	jalr	-776(ra) # 8000412e <dirlink>
    8000543e:	06054f63          	bltz	a0,800054bc <create+0x15a>
  iunlockput(dp);
    80005442:	8526                	mv	a0,s1
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	858080e7          	jalr	-1960(ra) # 80003c9c <iunlockput>
  return ip;
    8000544c:	8ad2                	mv	s5,s4
    8000544e:	b759                	j	800053d4 <create+0x72>
    iunlockput(dp);
    80005450:	8526                	mv	a0,s1
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	84a080e7          	jalr	-1974(ra) # 80003c9c <iunlockput>
    return 0;
    8000545a:	8ad2                	mv	s5,s4
    8000545c:	bfa5                	j	800053d4 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000545e:	004a2603          	lw	a2,4(s4)
    80005462:	00003597          	auipc	a1,0x3
    80005466:	2ae58593          	addi	a1,a1,686 # 80008710 <syscalls+0x2c0>
    8000546a:	8552                	mv	a0,s4
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	cc2080e7          	jalr	-830(ra) # 8000412e <dirlink>
    80005474:	04054463          	bltz	a0,800054bc <create+0x15a>
    80005478:	40d0                	lw	a2,4(s1)
    8000547a:	00003597          	auipc	a1,0x3
    8000547e:	29e58593          	addi	a1,a1,670 # 80008718 <syscalls+0x2c8>
    80005482:	8552                	mv	a0,s4
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	caa080e7          	jalr	-854(ra) # 8000412e <dirlink>
    8000548c:	02054863          	bltz	a0,800054bc <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005490:	004a2603          	lw	a2,4(s4)
    80005494:	fb040593          	addi	a1,s0,-80
    80005498:	8526                	mv	a0,s1
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	c94080e7          	jalr	-876(ra) # 8000412e <dirlink>
    800054a2:	00054d63          	bltz	a0,800054bc <create+0x15a>
    dp->nlink++;  // for ".."
    800054a6:	04a4d783          	lhu	a5,74(s1)
    800054aa:	2785                	addiw	a5,a5,1
    800054ac:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054b0:	8526                	mv	a0,s1
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	4bc080e7          	jalr	1212(ra) # 8000396e <iupdate>
    800054ba:	b761                	j	80005442 <create+0xe0>
  ip->nlink = 0;
    800054bc:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054c0:	8552                	mv	a0,s4
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	4ac080e7          	jalr	1196(ra) # 8000396e <iupdate>
  iunlockput(ip);
    800054ca:	8552                	mv	a0,s4
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	7d0080e7          	jalr	2000(ra) # 80003c9c <iunlockput>
  iunlockput(dp);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	7c6080e7          	jalr	1990(ra) # 80003c9c <iunlockput>
  return 0;
    800054de:	bddd                	j	800053d4 <create+0x72>
    return 0;
    800054e0:	8aaa                	mv	s5,a0
    800054e2:	bdcd                	j	800053d4 <create+0x72>

00000000800054e4 <sys_dup>:
{
    800054e4:	7179                	addi	sp,sp,-48
    800054e6:	f406                	sd	ra,40(sp)
    800054e8:	f022                	sd	s0,32(sp)
    800054ea:	ec26                	sd	s1,24(sp)
    800054ec:	e84a                	sd	s2,16(sp)
    800054ee:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054f0:	fd840613          	addi	a2,s0,-40
    800054f4:	4581                	li	a1,0
    800054f6:	4501                	li	a0,0
    800054f8:	00000097          	auipc	ra,0x0
    800054fc:	dc8080e7          	jalr	-568(ra) # 800052c0 <argfd>
    return -1;
    80005500:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005502:	02054363          	bltz	a0,80005528 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005506:	fd843903          	ld	s2,-40(s0)
    8000550a:	854a                	mv	a0,s2
    8000550c:	00000097          	auipc	ra,0x0
    80005510:	e14080e7          	jalr	-492(ra) # 80005320 <fdalloc>
    80005514:	84aa                	mv	s1,a0
    return -1;
    80005516:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005518:	00054863          	bltz	a0,80005528 <sys_dup+0x44>
  filedup(f);
    8000551c:	854a                	mv	a0,s2
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	334080e7          	jalr	820(ra) # 80004852 <filedup>
  return fd;
    80005526:	87a6                	mv	a5,s1
}
    80005528:	853e                	mv	a0,a5
    8000552a:	70a2                	ld	ra,40(sp)
    8000552c:	7402                	ld	s0,32(sp)
    8000552e:	64e2                	ld	s1,24(sp)
    80005530:	6942                	ld	s2,16(sp)
    80005532:	6145                	addi	sp,sp,48
    80005534:	8082                	ret

0000000080005536 <sys_read>:
{
    80005536:	7179                	addi	sp,sp,-48
    80005538:	f406                	sd	ra,40(sp)
    8000553a:	f022                	sd	s0,32(sp)
    8000553c:	1800                	addi	s0,sp,48
  READCOUNT++;
    8000553e:	00003717          	auipc	a4,0x3
    80005542:	3ca70713          	addi	a4,a4,970 # 80008908 <READCOUNT>
    80005546:	631c                	ld	a5,0(a4)
    80005548:	0785                	addi	a5,a5,1
    8000554a:	e31c                	sd	a5,0(a4)
  argaddr(1, &p);
    8000554c:	fd840593          	addi	a1,s0,-40
    80005550:	4505                	li	a0,1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	86e080e7          	jalr	-1938(ra) # 80002dc0 <argaddr>
  argint(2, &n);
    8000555a:	fe440593          	addi	a1,s0,-28
    8000555e:	4509                	li	a0,2
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	840080e7          	jalr	-1984(ra) # 80002da0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005568:	fe840613          	addi	a2,s0,-24
    8000556c:	4581                	li	a1,0
    8000556e:	4501                	li	a0,0
    80005570:	00000097          	auipc	ra,0x0
    80005574:	d50080e7          	jalr	-688(ra) # 800052c0 <argfd>
    80005578:	87aa                	mv	a5,a0
    return -1;
    8000557a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000557c:	0007cc63          	bltz	a5,80005594 <sys_read+0x5e>
  return fileread(f, p, n);
    80005580:	fe442603          	lw	a2,-28(s0)
    80005584:	fd843583          	ld	a1,-40(s0)
    80005588:	fe843503          	ld	a0,-24(s0)
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	452080e7          	jalr	1106(ra) # 800049de <fileread>
}
    80005594:	70a2                	ld	ra,40(sp)
    80005596:	7402                	ld	s0,32(sp)
    80005598:	6145                	addi	sp,sp,48
    8000559a:	8082                	ret

000000008000559c <sys_write>:
{
    8000559c:	7179                	addi	sp,sp,-48
    8000559e:	f406                	sd	ra,40(sp)
    800055a0:	f022                	sd	s0,32(sp)
    800055a2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055a4:	fd840593          	addi	a1,s0,-40
    800055a8:	4505                	li	a0,1
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	816080e7          	jalr	-2026(ra) # 80002dc0 <argaddr>
  argint(2, &n);
    800055b2:	fe440593          	addi	a1,s0,-28
    800055b6:	4509                	li	a0,2
    800055b8:	ffffd097          	auipc	ra,0xffffd
    800055bc:	7e8080e7          	jalr	2024(ra) # 80002da0 <argint>
  if(argfd(0, 0, &f) < 0)
    800055c0:	fe840613          	addi	a2,s0,-24
    800055c4:	4581                	li	a1,0
    800055c6:	4501                	li	a0,0
    800055c8:	00000097          	auipc	ra,0x0
    800055cc:	cf8080e7          	jalr	-776(ra) # 800052c0 <argfd>
    800055d0:	87aa                	mv	a5,a0
    return -1;
    800055d2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055d4:	0007cc63          	bltz	a5,800055ec <sys_write+0x50>
  return filewrite(f, p, n);
    800055d8:	fe442603          	lw	a2,-28(s0)
    800055dc:	fd843583          	ld	a1,-40(s0)
    800055e0:	fe843503          	ld	a0,-24(s0)
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	4bc080e7          	jalr	1212(ra) # 80004aa0 <filewrite>
}
    800055ec:	70a2                	ld	ra,40(sp)
    800055ee:	7402                	ld	s0,32(sp)
    800055f0:	6145                	addi	sp,sp,48
    800055f2:	8082                	ret

00000000800055f4 <sys_close>:
{
    800055f4:	1101                	addi	sp,sp,-32
    800055f6:	ec06                	sd	ra,24(sp)
    800055f8:	e822                	sd	s0,16(sp)
    800055fa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055fc:	fe040613          	addi	a2,s0,-32
    80005600:	fec40593          	addi	a1,s0,-20
    80005604:	4501                	li	a0,0
    80005606:	00000097          	auipc	ra,0x0
    8000560a:	cba080e7          	jalr	-838(ra) # 800052c0 <argfd>
    return -1;
    8000560e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005610:	02054463          	bltz	a0,80005638 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005614:	ffffc097          	auipc	ra,0xffffc
    80005618:	392080e7          	jalr	914(ra) # 800019a6 <myproc>
    8000561c:	fec42783          	lw	a5,-20(s0)
    80005620:	07e9                	addi	a5,a5,26
    80005622:	078e                	slli	a5,a5,0x3
    80005624:	953e                	add	a0,a0,a5
    80005626:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000562a:	fe043503          	ld	a0,-32(s0)
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	276080e7          	jalr	630(ra) # 800048a4 <fileclose>
  return 0;
    80005636:	4781                	li	a5,0
}
    80005638:	853e                	mv	a0,a5
    8000563a:	60e2                	ld	ra,24(sp)
    8000563c:	6442                	ld	s0,16(sp)
    8000563e:	6105                	addi	sp,sp,32
    80005640:	8082                	ret

0000000080005642 <sys_fstat>:
{
    80005642:	1101                	addi	sp,sp,-32
    80005644:	ec06                	sd	ra,24(sp)
    80005646:	e822                	sd	s0,16(sp)
    80005648:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000564a:	fe040593          	addi	a1,s0,-32
    8000564e:	4505                	li	a0,1
    80005650:	ffffd097          	auipc	ra,0xffffd
    80005654:	770080e7          	jalr	1904(ra) # 80002dc0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005658:	fe840613          	addi	a2,s0,-24
    8000565c:	4581                	li	a1,0
    8000565e:	4501                	li	a0,0
    80005660:	00000097          	auipc	ra,0x0
    80005664:	c60080e7          	jalr	-928(ra) # 800052c0 <argfd>
    80005668:	87aa                	mv	a5,a0
    return -1;
    8000566a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000566c:	0007ca63          	bltz	a5,80005680 <sys_fstat+0x3e>
  return filestat(f, st);
    80005670:	fe043583          	ld	a1,-32(s0)
    80005674:	fe843503          	ld	a0,-24(s0)
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	2f4080e7          	jalr	756(ra) # 8000496c <filestat>
}
    80005680:	60e2                	ld	ra,24(sp)
    80005682:	6442                	ld	s0,16(sp)
    80005684:	6105                	addi	sp,sp,32
    80005686:	8082                	ret

0000000080005688 <sys_link>:
{
    80005688:	7169                	addi	sp,sp,-304
    8000568a:	f606                	sd	ra,296(sp)
    8000568c:	f222                	sd	s0,288(sp)
    8000568e:	ee26                	sd	s1,280(sp)
    80005690:	ea4a                	sd	s2,272(sp)
    80005692:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005694:	08000613          	li	a2,128
    80005698:	ed040593          	addi	a1,s0,-304
    8000569c:	4501                	li	a0,0
    8000569e:	ffffd097          	auipc	ra,0xffffd
    800056a2:	742080e7          	jalr	1858(ra) # 80002de0 <argstr>
    return -1;
    800056a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056a8:	10054e63          	bltz	a0,800057c4 <sys_link+0x13c>
    800056ac:	08000613          	li	a2,128
    800056b0:	f5040593          	addi	a1,s0,-176
    800056b4:	4505                	li	a0,1
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	72a080e7          	jalr	1834(ra) # 80002de0 <argstr>
    return -1;
    800056be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056c0:	10054263          	bltz	a0,800057c4 <sys_link+0x13c>
  begin_op();
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	d1c080e7          	jalr	-740(ra) # 800043e0 <begin_op>
  if((ip = namei(old)) == 0){
    800056cc:	ed040513          	addi	a0,s0,-304
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	b10080e7          	jalr	-1264(ra) # 800041e0 <namei>
    800056d8:	84aa                	mv	s1,a0
    800056da:	c551                	beqz	a0,80005766 <sys_link+0xde>
  ilock(ip);
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	35e080e7          	jalr	862(ra) # 80003a3a <ilock>
  if(ip->type == T_DIR){
    800056e4:	04449703          	lh	a4,68(s1)
    800056e8:	4785                	li	a5,1
    800056ea:	08f70463          	beq	a4,a5,80005772 <sys_link+0xea>
  ip->nlink++;
    800056ee:	04a4d783          	lhu	a5,74(s1)
    800056f2:	2785                	addiw	a5,a5,1
    800056f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	274080e7          	jalr	628(ra) # 8000396e <iupdate>
  iunlock(ip);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	3f8080e7          	jalr	1016(ra) # 80003afc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000570c:	fd040593          	addi	a1,s0,-48
    80005710:	f5040513          	addi	a0,s0,-176
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	aea080e7          	jalr	-1302(ra) # 800041fe <nameiparent>
    8000571c:	892a                	mv	s2,a0
    8000571e:	c935                	beqz	a0,80005792 <sys_link+0x10a>
  ilock(dp);
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	31a080e7          	jalr	794(ra) # 80003a3a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005728:	00092703          	lw	a4,0(s2)
    8000572c:	409c                	lw	a5,0(s1)
    8000572e:	04f71d63          	bne	a4,a5,80005788 <sys_link+0x100>
    80005732:	40d0                	lw	a2,4(s1)
    80005734:	fd040593          	addi	a1,s0,-48
    80005738:	854a                	mv	a0,s2
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	9f4080e7          	jalr	-1548(ra) # 8000412e <dirlink>
    80005742:	04054363          	bltz	a0,80005788 <sys_link+0x100>
  iunlockput(dp);
    80005746:	854a                	mv	a0,s2
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	554080e7          	jalr	1364(ra) # 80003c9c <iunlockput>
  iput(ip);
    80005750:	8526                	mv	a0,s1
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	4a2080e7          	jalr	1186(ra) # 80003bf4 <iput>
  end_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	d00080e7          	jalr	-768(ra) # 8000445a <end_op>
  return 0;
    80005762:	4781                	li	a5,0
    80005764:	a085                	j	800057c4 <sys_link+0x13c>
    end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	cf4080e7          	jalr	-780(ra) # 8000445a <end_op>
    return -1;
    8000576e:	57fd                	li	a5,-1
    80005770:	a891                	j	800057c4 <sys_link+0x13c>
    iunlockput(ip);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	528080e7          	jalr	1320(ra) # 80003c9c <iunlockput>
    end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	cde080e7          	jalr	-802(ra) # 8000445a <end_op>
    return -1;
    80005784:	57fd                	li	a5,-1
    80005786:	a83d                	j	800057c4 <sys_link+0x13c>
    iunlockput(dp);
    80005788:	854a                	mv	a0,s2
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	512080e7          	jalr	1298(ra) # 80003c9c <iunlockput>
  ilock(ip);
    80005792:	8526                	mv	a0,s1
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	2a6080e7          	jalr	678(ra) # 80003a3a <ilock>
  ip->nlink--;
    8000579c:	04a4d783          	lhu	a5,74(s1)
    800057a0:	37fd                	addiw	a5,a5,-1
    800057a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057a6:	8526                	mv	a0,s1
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	1c6080e7          	jalr	454(ra) # 8000396e <iupdate>
  iunlockput(ip);
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	4ea080e7          	jalr	1258(ra) # 80003c9c <iunlockput>
  end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	ca0080e7          	jalr	-864(ra) # 8000445a <end_op>
  return -1;
    800057c2:	57fd                	li	a5,-1
}
    800057c4:	853e                	mv	a0,a5
    800057c6:	70b2                	ld	ra,296(sp)
    800057c8:	7412                	ld	s0,288(sp)
    800057ca:	64f2                	ld	s1,280(sp)
    800057cc:	6952                	ld	s2,272(sp)
    800057ce:	6155                	addi	sp,sp,304
    800057d0:	8082                	ret

00000000800057d2 <sys_unlink>:
{
    800057d2:	7151                	addi	sp,sp,-240
    800057d4:	f586                	sd	ra,232(sp)
    800057d6:	f1a2                	sd	s0,224(sp)
    800057d8:	eda6                	sd	s1,216(sp)
    800057da:	e9ca                	sd	s2,208(sp)
    800057dc:	e5ce                	sd	s3,200(sp)
    800057de:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057e0:	08000613          	li	a2,128
    800057e4:	f3040593          	addi	a1,s0,-208
    800057e8:	4501                	li	a0,0
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	5f6080e7          	jalr	1526(ra) # 80002de0 <argstr>
    800057f2:	18054163          	bltz	a0,80005974 <sys_unlink+0x1a2>
  begin_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	bea080e7          	jalr	-1046(ra) # 800043e0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057fe:	fb040593          	addi	a1,s0,-80
    80005802:	f3040513          	addi	a0,s0,-208
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	9f8080e7          	jalr	-1544(ra) # 800041fe <nameiparent>
    8000580e:	84aa                	mv	s1,a0
    80005810:	c979                	beqz	a0,800058e6 <sys_unlink+0x114>
  ilock(dp);
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	228080e7          	jalr	552(ra) # 80003a3a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000581a:	00003597          	auipc	a1,0x3
    8000581e:	ef658593          	addi	a1,a1,-266 # 80008710 <syscalls+0x2c0>
    80005822:	fb040513          	addi	a0,s0,-80
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	6de080e7          	jalr	1758(ra) # 80003f04 <namecmp>
    8000582e:	14050a63          	beqz	a0,80005982 <sys_unlink+0x1b0>
    80005832:	00003597          	auipc	a1,0x3
    80005836:	ee658593          	addi	a1,a1,-282 # 80008718 <syscalls+0x2c8>
    8000583a:	fb040513          	addi	a0,s0,-80
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	6c6080e7          	jalr	1734(ra) # 80003f04 <namecmp>
    80005846:	12050e63          	beqz	a0,80005982 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000584a:	f2c40613          	addi	a2,s0,-212
    8000584e:	fb040593          	addi	a1,s0,-80
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	6ca080e7          	jalr	1738(ra) # 80003f1e <dirlookup>
    8000585c:	892a                	mv	s2,a0
    8000585e:	12050263          	beqz	a0,80005982 <sys_unlink+0x1b0>
  ilock(ip);
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	1d8080e7          	jalr	472(ra) # 80003a3a <ilock>
  if(ip->nlink < 1)
    8000586a:	04a91783          	lh	a5,74(s2)
    8000586e:	08f05263          	blez	a5,800058f2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005872:	04491703          	lh	a4,68(s2)
    80005876:	4785                	li	a5,1
    80005878:	08f70563          	beq	a4,a5,80005902 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000587c:	4641                	li	a2,16
    8000587e:	4581                	li	a1,0
    80005880:	fc040513          	addi	a0,s0,-64
    80005884:	ffffb097          	auipc	ra,0xffffb
    80005888:	44a080e7          	jalr	1098(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000588c:	4741                	li	a4,16
    8000588e:	f2c42683          	lw	a3,-212(s0)
    80005892:	fc040613          	addi	a2,s0,-64
    80005896:	4581                	li	a1,0
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	54c080e7          	jalr	1356(ra) # 80003de6 <writei>
    800058a2:	47c1                	li	a5,16
    800058a4:	0af51563          	bne	a0,a5,8000594e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058a8:	04491703          	lh	a4,68(s2)
    800058ac:	4785                	li	a5,1
    800058ae:	0af70863          	beq	a4,a5,8000595e <sys_unlink+0x18c>
  iunlockput(dp);
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	3e8080e7          	jalr	1000(ra) # 80003c9c <iunlockput>
  ip->nlink--;
    800058bc:	04a95783          	lhu	a5,74(s2)
    800058c0:	37fd                	addiw	a5,a5,-1
    800058c2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058c6:	854a                	mv	a0,s2
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	0a6080e7          	jalr	166(ra) # 8000396e <iupdate>
  iunlockput(ip);
    800058d0:	854a                	mv	a0,s2
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	3ca080e7          	jalr	970(ra) # 80003c9c <iunlockput>
  end_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	b80080e7          	jalr	-1152(ra) # 8000445a <end_op>
  return 0;
    800058e2:	4501                	li	a0,0
    800058e4:	a84d                	j	80005996 <sys_unlink+0x1c4>
    end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	b74080e7          	jalr	-1164(ra) # 8000445a <end_op>
    return -1;
    800058ee:	557d                	li	a0,-1
    800058f0:	a05d                	j	80005996 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058f2:	00003517          	auipc	a0,0x3
    800058f6:	e2e50513          	addi	a0,a0,-466 # 80008720 <syscalls+0x2d0>
    800058fa:	ffffb097          	auipc	ra,0xffffb
    800058fe:	c42080e7          	jalr	-958(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005902:	04c92703          	lw	a4,76(s2)
    80005906:	02000793          	li	a5,32
    8000590a:	f6e7f9e3          	bgeu	a5,a4,8000587c <sys_unlink+0xaa>
    8000590e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005912:	4741                	li	a4,16
    80005914:	86ce                	mv	a3,s3
    80005916:	f1840613          	addi	a2,s0,-232
    8000591a:	4581                	li	a1,0
    8000591c:	854a                	mv	a0,s2
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	3d0080e7          	jalr	976(ra) # 80003cee <readi>
    80005926:	47c1                	li	a5,16
    80005928:	00f51b63          	bne	a0,a5,8000593e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000592c:	f1845783          	lhu	a5,-232(s0)
    80005930:	e7a1                	bnez	a5,80005978 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005932:	29c1                	addiw	s3,s3,16
    80005934:	04c92783          	lw	a5,76(s2)
    80005938:	fcf9ede3          	bltu	s3,a5,80005912 <sys_unlink+0x140>
    8000593c:	b781                	j	8000587c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000593e:	00003517          	auipc	a0,0x3
    80005942:	dfa50513          	addi	a0,a0,-518 # 80008738 <syscalls+0x2e8>
    80005946:	ffffb097          	auipc	ra,0xffffb
    8000594a:	bf6080e7          	jalr	-1034(ra) # 8000053c <panic>
    panic("unlink: writei");
    8000594e:	00003517          	auipc	a0,0x3
    80005952:	e0250513          	addi	a0,a0,-510 # 80008750 <syscalls+0x300>
    80005956:	ffffb097          	auipc	ra,0xffffb
    8000595a:	be6080e7          	jalr	-1050(ra) # 8000053c <panic>
    dp->nlink--;
    8000595e:	04a4d783          	lhu	a5,74(s1)
    80005962:	37fd                	addiw	a5,a5,-1
    80005964:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005968:	8526                	mv	a0,s1
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	004080e7          	jalr	4(ra) # 8000396e <iupdate>
    80005972:	b781                	j	800058b2 <sys_unlink+0xe0>
    return -1;
    80005974:	557d                	li	a0,-1
    80005976:	a005                	j	80005996 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005978:	854a                	mv	a0,s2
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	322080e7          	jalr	802(ra) # 80003c9c <iunlockput>
  iunlockput(dp);
    80005982:	8526                	mv	a0,s1
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	318080e7          	jalr	792(ra) # 80003c9c <iunlockput>
  end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	ace080e7          	jalr	-1330(ra) # 8000445a <end_op>
  return -1;
    80005994:	557d                	li	a0,-1
}
    80005996:	70ae                	ld	ra,232(sp)
    80005998:	740e                	ld	s0,224(sp)
    8000599a:	64ee                	ld	s1,216(sp)
    8000599c:	694e                	ld	s2,208(sp)
    8000599e:	69ae                	ld	s3,200(sp)
    800059a0:	616d                	addi	sp,sp,240
    800059a2:	8082                	ret

00000000800059a4 <sys_open>:

uint64
sys_open(void)
{
    800059a4:	7131                	addi	sp,sp,-192
    800059a6:	fd06                	sd	ra,184(sp)
    800059a8:	f922                	sd	s0,176(sp)
    800059aa:	f526                	sd	s1,168(sp)
    800059ac:	f14a                	sd	s2,160(sp)
    800059ae:	ed4e                	sd	s3,152(sp)
    800059b0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059b2:	f4c40593          	addi	a1,s0,-180
    800059b6:	4505                	li	a0,1
    800059b8:	ffffd097          	auipc	ra,0xffffd
    800059bc:	3e8080e7          	jalr	1000(ra) # 80002da0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059c0:	08000613          	li	a2,128
    800059c4:	f5040593          	addi	a1,s0,-176
    800059c8:	4501                	li	a0,0
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	416080e7          	jalr	1046(ra) # 80002de0 <argstr>
    800059d2:	87aa                	mv	a5,a0
    return -1;
    800059d4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059d6:	0a07c863          	bltz	a5,80005a86 <sys_open+0xe2>

  begin_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	a06080e7          	jalr	-1530(ra) # 800043e0 <begin_op>

  if(omode & O_CREATE){
    800059e2:	f4c42783          	lw	a5,-180(s0)
    800059e6:	2007f793          	andi	a5,a5,512
    800059ea:	cbdd                	beqz	a5,80005aa0 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800059ec:	4681                	li	a3,0
    800059ee:	4601                	li	a2,0
    800059f0:	4589                	li	a1,2
    800059f2:	f5040513          	addi	a0,s0,-176
    800059f6:	00000097          	auipc	ra,0x0
    800059fa:	96c080e7          	jalr	-1684(ra) # 80005362 <create>
    800059fe:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a00:	c951                	beqz	a0,80005a94 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a02:	04449703          	lh	a4,68(s1)
    80005a06:	478d                	li	a5,3
    80005a08:	00f71763          	bne	a4,a5,80005a16 <sys_open+0x72>
    80005a0c:	0464d703          	lhu	a4,70(s1)
    80005a10:	47a5                	li	a5,9
    80005a12:	0ce7ec63          	bltu	a5,a4,80005aea <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	dd2080e7          	jalr	-558(ra) # 800047e8 <filealloc>
    80005a1e:	892a                	mv	s2,a0
    80005a20:	c56d                	beqz	a0,80005b0a <sys_open+0x166>
    80005a22:	00000097          	auipc	ra,0x0
    80005a26:	8fe080e7          	jalr	-1794(ra) # 80005320 <fdalloc>
    80005a2a:	89aa                	mv	s3,a0
    80005a2c:	0c054a63          	bltz	a0,80005b00 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a30:	04449703          	lh	a4,68(s1)
    80005a34:	478d                	li	a5,3
    80005a36:	0ef70563          	beq	a4,a5,80005b20 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a3a:	4789                	li	a5,2
    80005a3c:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005a40:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005a44:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005a48:	f4c42783          	lw	a5,-180(s0)
    80005a4c:	0017c713          	xori	a4,a5,1
    80005a50:	8b05                	andi	a4,a4,1
    80005a52:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a56:	0037f713          	andi	a4,a5,3
    80005a5a:	00e03733          	snez	a4,a4
    80005a5e:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a62:	4007f793          	andi	a5,a5,1024
    80005a66:	c791                	beqz	a5,80005a72 <sys_open+0xce>
    80005a68:	04449703          	lh	a4,68(s1)
    80005a6c:	4789                	li	a5,2
    80005a6e:	0cf70063          	beq	a4,a5,80005b2e <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005a72:	8526                	mv	a0,s1
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	088080e7          	jalr	136(ra) # 80003afc <iunlock>
  end_op();
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	9de080e7          	jalr	-1570(ra) # 8000445a <end_op>

  return fd;
    80005a84:	854e                	mv	a0,s3
}
    80005a86:	70ea                	ld	ra,184(sp)
    80005a88:	744a                	ld	s0,176(sp)
    80005a8a:	74aa                	ld	s1,168(sp)
    80005a8c:	790a                	ld	s2,160(sp)
    80005a8e:	69ea                	ld	s3,152(sp)
    80005a90:	6129                	addi	sp,sp,192
    80005a92:	8082                	ret
      end_op();
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	9c6080e7          	jalr	-1594(ra) # 8000445a <end_op>
      return -1;
    80005a9c:	557d                	li	a0,-1
    80005a9e:	b7e5                	j	80005a86 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005aa0:	f5040513          	addi	a0,s0,-176
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	73c080e7          	jalr	1852(ra) # 800041e0 <namei>
    80005aac:	84aa                	mv	s1,a0
    80005aae:	c905                	beqz	a0,80005ade <sys_open+0x13a>
    ilock(ip);
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	f8a080e7          	jalr	-118(ra) # 80003a3a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ab8:	04449703          	lh	a4,68(s1)
    80005abc:	4785                	li	a5,1
    80005abe:	f4f712e3          	bne	a4,a5,80005a02 <sys_open+0x5e>
    80005ac2:	f4c42783          	lw	a5,-180(s0)
    80005ac6:	dba1                	beqz	a5,80005a16 <sys_open+0x72>
      iunlockput(ip);
    80005ac8:	8526                	mv	a0,s1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	1d2080e7          	jalr	466(ra) # 80003c9c <iunlockput>
      end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	988080e7          	jalr	-1656(ra) # 8000445a <end_op>
      return -1;
    80005ada:	557d                	li	a0,-1
    80005adc:	b76d                	j	80005a86 <sys_open+0xe2>
      end_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	97c080e7          	jalr	-1668(ra) # 8000445a <end_op>
      return -1;
    80005ae6:	557d                	li	a0,-1
    80005ae8:	bf79                	j	80005a86 <sys_open+0xe2>
    iunlockput(ip);
    80005aea:	8526                	mv	a0,s1
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	1b0080e7          	jalr	432(ra) # 80003c9c <iunlockput>
    end_op();
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	966080e7          	jalr	-1690(ra) # 8000445a <end_op>
    return -1;
    80005afc:	557d                	li	a0,-1
    80005afe:	b761                	j	80005a86 <sys_open+0xe2>
      fileclose(f);
    80005b00:	854a                	mv	a0,s2
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	da2080e7          	jalr	-606(ra) # 800048a4 <fileclose>
    iunlockput(ip);
    80005b0a:	8526                	mv	a0,s1
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	190080e7          	jalr	400(ra) # 80003c9c <iunlockput>
    end_op();
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	946080e7          	jalr	-1722(ra) # 8000445a <end_op>
    return -1;
    80005b1c:	557d                	li	a0,-1
    80005b1e:	b7a5                	j	80005a86 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005b20:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005b24:	04649783          	lh	a5,70(s1)
    80005b28:	02f91223          	sh	a5,36(s2)
    80005b2c:	bf21                	j	80005a44 <sys_open+0xa0>
    itrunc(ip);
    80005b2e:	8526                	mv	a0,s1
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	018080e7          	jalr	24(ra) # 80003b48 <itrunc>
    80005b38:	bf2d                	j	80005a72 <sys_open+0xce>

0000000080005b3a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b3a:	7175                	addi	sp,sp,-144
    80005b3c:	e506                	sd	ra,136(sp)
    80005b3e:	e122                	sd	s0,128(sp)
    80005b40:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	89e080e7          	jalr	-1890(ra) # 800043e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b4a:	08000613          	li	a2,128
    80005b4e:	f7040593          	addi	a1,s0,-144
    80005b52:	4501                	li	a0,0
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	28c080e7          	jalr	652(ra) # 80002de0 <argstr>
    80005b5c:	02054963          	bltz	a0,80005b8e <sys_mkdir+0x54>
    80005b60:	4681                	li	a3,0
    80005b62:	4601                	li	a2,0
    80005b64:	4585                	li	a1,1
    80005b66:	f7040513          	addi	a0,s0,-144
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	7f8080e7          	jalr	2040(ra) # 80005362 <create>
    80005b72:	cd11                	beqz	a0,80005b8e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	128080e7          	jalr	296(ra) # 80003c9c <iunlockput>
  end_op();
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	8de080e7          	jalr	-1826(ra) # 8000445a <end_op>
  return 0;
    80005b84:	4501                	li	a0,0
}
    80005b86:	60aa                	ld	ra,136(sp)
    80005b88:	640a                	ld	s0,128(sp)
    80005b8a:	6149                	addi	sp,sp,144
    80005b8c:	8082                	ret
    end_op();
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	8cc080e7          	jalr	-1844(ra) # 8000445a <end_op>
    return -1;
    80005b96:	557d                	li	a0,-1
    80005b98:	b7fd                	j	80005b86 <sys_mkdir+0x4c>

0000000080005b9a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b9a:	7135                	addi	sp,sp,-160
    80005b9c:	ed06                	sd	ra,152(sp)
    80005b9e:	e922                	sd	s0,144(sp)
    80005ba0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	83e080e7          	jalr	-1986(ra) # 800043e0 <begin_op>
  argint(1, &major);
    80005baa:	f6c40593          	addi	a1,s0,-148
    80005bae:	4505                	li	a0,1
    80005bb0:	ffffd097          	auipc	ra,0xffffd
    80005bb4:	1f0080e7          	jalr	496(ra) # 80002da0 <argint>
  argint(2, &minor);
    80005bb8:	f6840593          	addi	a1,s0,-152
    80005bbc:	4509                	li	a0,2
    80005bbe:	ffffd097          	auipc	ra,0xffffd
    80005bc2:	1e2080e7          	jalr	482(ra) # 80002da0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bc6:	08000613          	li	a2,128
    80005bca:	f7040593          	addi	a1,s0,-144
    80005bce:	4501                	li	a0,0
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	210080e7          	jalr	528(ra) # 80002de0 <argstr>
    80005bd8:	02054b63          	bltz	a0,80005c0e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bdc:	f6841683          	lh	a3,-152(s0)
    80005be0:	f6c41603          	lh	a2,-148(s0)
    80005be4:	458d                	li	a1,3
    80005be6:	f7040513          	addi	a0,s0,-144
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	778080e7          	jalr	1912(ra) # 80005362 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bf2:	cd11                	beqz	a0,80005c0e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	0a8080e7          	jalr	168(ra) # 80003c9c <iunlockput>
  end_op();
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	85e080e7          	jalr	-1954(ra) # 8000445a <end_op>
  return 0;
    80005c04:	4501                	li	a0,0
}
    80005c06:	60ea                	ld	ra,152(sp)
    80005c08:	644a                	ld	s0,144(sp)
    80005c0a:	610d                	addi	sp,sp,160
    80005c0c:	8082                	ret
    end_op();
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	84c080e7          	jalr	-1972(ra) # 8000445a <end_op>
    return -1;
    80005c16:	557d                	li	a0,-1
    80005c18:	b7fd                	j	80005c06 <sys_mknod+0x6c>

0000000080005c1a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c1a:	7135                	addi	sp,sp,-160
    80005c1c:	ed06                	sd	ra,152(sp)
    80005c1e:	e922                	sd	s0,144(sp)
    80005c20:	e526                	sd	s1,136(sp)
    80005c22:	e14a                	sd	s2,128(sp)
    80005c24:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c26:	ffffc097          	auipc	ra,0xffffc
    80005c2a:	d80080e7          	jalr	-640(ra) # 800019a6 <myproc>
    80005c2e:	892a                	mv	s2,a0
  
  begin_op();
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	7b0080e7          	jalr	1968(ra) # 800043e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c38:	08000613          	li	a2,128
    80005c3c:	f6040593          	addi	a1,s0,-160
    80005c40:	4501                	li	a0,0
    80005c42:	ffffd097          	auipc	ra,0xffffd
    80005c46:	19e080e7          	jalr	414(ra) # 80002de0 <argstr>
    80005c4a:	04054b63          	bltz	a0,80005ca0 <sys_chdir+0x86>
    80005c4e:	f6040513          	addi	a0,s0,-160
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	58e080e7          	jalr	1422(ra) # 800041e0 <namei>
    80005c5a:	84aa                	mv	s1,a0
    80005c5c:	c131                	beqz	a0,80005ca0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	ddc080e7          	jalr	-548(ra) # 80003a3a <ilock>
  if(ip->type != T_DIR){
    80005c66:	04449703          	lh	a4,68(s1)
    80005c6a:	4785                	li	a5,1
    80005c6c:	04f71063          	bne	a4,a5,80005cac <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c70:	8526                	mv	a0,s1
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	e8a080e7          	jalr	-374(ra) # 80003afc <iunlock>
  iput(p->cwd);
    80005c7a:	15093503          	ld	a0,336(s2)
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	f76080e7          	jalr	-138(ra) # 80003bf4 <iput>
  end_op();
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	7d4080e7          	jalr	2004(ra) # 8000445a <end_op>
  p->cwd = ip;
    80005c8e:	14993823          	sd	s1,336(s2)
  return 0;
    80005c92:	4501                	li	a0,0
}
    80005c94:	60ea                	ld	ra,152(sp)
    80005c96:	644a                	ld	s0,144(sp)
    80005c98:	64aa                	ld	s1,136(sp)
    80005c9a:	690a                	ld	s2,128(sp)
    80005c9c:	610d                	addi	sp,sp,160
    80005c9e:	8082                	ret
    end_op();
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	7ba080e7          	jalr	1978(ra) # 8000445a <end_op>
    return -1;
    80005ca8:	557d                	li	a0,-1
    80005caa:	b7ed                	j	80005c94 <sys_chdir+0x7a>
    iunlockput(ip);
    80005cac:	8526                	mv	a0,s1
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	fee080e7          	jalr	-18(ra) # 80003c9c <iunlockput>
    end_op();
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	7a4080e7          	jalr	1956(ra) # 8000445a <end_op>
    return -1;
    80005cbe:	557d                	li	a0,-1
    80005cc0:	bfd1                	j	80005c94 <sys_chdir+0x7a>

0000000080005cc2 <sys_exec>:

uint64
sys_exec(void)
{
    80005cc2:	7121                	addi	sp,sp,-448
    80005cc4:	ff06                	sd	ra,440(sp)
    80005cc6:	fb22                	sd	s0,432(sp)
    80005cc8:	f726                	sd	s1,424(sp)
    80005cca:	f34a                	sd	s2,416(sp)
    80005ccc:	ef4e                	sd	s3,408(sp)
    80005cce:	eb52                	sd	s4,400(sp)
    80005cd0:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cd2:	e4840593          	addi	a1,s0,-440
    80005cd6:	4505                	li	a0,1
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	0e8080e7          	jalr	232(ra) # 80002dc0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ce0:	08000613          	li	a2,128
    80005ce4:	f5040593          	addi	a1,s0,-176
    80005ce8:	4501                	li	a0,0
    80005cea:	ffffd097          	auipc	ra,0xffffd
    80005cee:	0f6080e7          	jalr	246(ra) # 80002de0 <argstr>
    80005cf2:	87aa                	mv	a5,a0
    return -1;
    80005cf4:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005cf6:	0c07c263          	bltz	a5,80005dba <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005cfa:	10000613          	li	a2,256
    80005cfe:	4581                	li	a1,0
    80005d00:	e5040513          	addi	a0,s0,-432
    80005d04:	ffffb097          	auipc	ra,0xffffb
    80005d08:	fca080e7          	jalr	-54(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d0c:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005d10:	89a6                	mv	s3,s1
    80005d12:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d14:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d18:	00391513          	slli	a0,s2,0x3
    80005d1c:	e4040593          	addi	a1,s0,-448
    80005d20:	e4843783          	ld	a5,-440(s0)
    80005d24:	953e                	add	a0,a0,a5
    80005d26:	ffffd097          	auipc	ra,0xffffd
    80005d2a:	fdc080e7          	jalr	-36(ra) # 80002d02 <fetchaddr>
    80005d2e:	02054a63          	bltz	a0,80005d62 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005d32:	e4043783          	ld	a5,-448(s0)
    80005d36:	c3b9                	beqz	a5,80005d7c <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d38:	ffffb097          	auipc	ra,0xffffb
    80005d3c:	daa080e7          	jalr	-598(ra) # 80000ae2 <kalloc>
    80005d40:	85aa                	mv	a1,a0
    80005d42:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d46:	cd11                	beqz	a0,80005d62 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d48:	6605                	lui	a2,0x1
    80005d4a:	e4043503          	ld	a0,-448(s0)
    80005d4e:	ffffd097          	auipc	ra,0xffffd
    80005d52:	006080e7          	jalr	6(ra) # 80002d54 <fetchstr>
    80005d56:	00054663          	bltz	a0,80005d62 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005d5a:	0905                	addi	s2,s2,1
    80005d5c:	09a1                	addi	s3,s3,8
    80005d5e:	fb491de3          	bne	s2,s4,80005d18 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d62:	f5040913          	addi	s2,s0,-176
    80005d66:	6088                	ld	a0,0(s1)
    80005d68:	c921                	beqz	a0,80005db8 <sys_exec+0xf6>
    kfree(argv[i]);
    80005d6a:	ffffb097          	auipc	ra,0xffffb
    80005d6e:	c7a080e7          	jalr	-902(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d72:	04a1                	addi	s1,s1,8
    80005d74:	ff2499e3          	bne	s1,s2,80005d66 <sys_exec+0xa4>
  return -1;
    80005d78:	557d                	li	a0,-1
    80005d7a:	a081                	j	80005dba <sys_exec+0xf8>
      argv[i] = 0;
    80005d7c:	0009079b          	sext.w	a5,s2
    80005d80:	078e                	slli	a5,a5,0x3
    80005d82:	fd078793          	addi	a5,a5,-48
    80005d86:	97a2                	add	a5,a5,s0
    80005d88:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005d8c:	e5040593          	addi	a1,s0,-432
    80005d90:	f5040513          	addi	a0,s0,-176
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	186080e7          	jalr	390(ra) # 80004f1a <exec>
    80005d9c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d9e:	f5040993          	addi	s3,s0,-176
    80005da2:	6088                	ld	a0,0(s1)
    80005da4:	c901                	beqz	a0,80005db4 <sys_exec+0xf2>
    kfree(argv[i]);
    80005da6:	ffffb097          	auipc	ra,0xffffb
    80005daa:	c3e080e7          	jalr	-962(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dae:	04a1                	addi	s1,s1,8
    80005db0:	ff3499e3          	bne	s1,s3,80005da2 <sys_exec+0xe0>
  return ret;
    80005db4:	854a                	mv	a0,s2
    80005db6:	a011                	j	80005dba <sys_exec+0xf8>
  return -1;
    80005db8:	557d                	li	a0,-1
}
    80005dba:	70fa                	ld	ra,440(sp)
    80005dbc:	745a                	ld	s0,432(sp)
    80005dbe:	74ba                	ld	s1,424(sp)
    80005dc0:	791a                	ld	s2,416(sp)
    80005dc2:	69fa                	ld	s3,408(sp)
    80005dc4:	6a5a                	ld	s4,400(sp)
    80005dc6:	6139                	addi	sp,sp,448
    80005dc8:	8082                	ret

0000000080005dca <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dca:	7139                	addi	sp,sp,-64
    80005dcc:	fc06                	sd	ra,56(sp)
    80005dce:	f822                	sd	s0,48(sp)
    80005dd0:	f426                	sd	s1,40(sp)
    80005dd2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dd4:	ffffc097          	auipc	ra,0xffffc
    80005dd8:	bd2080e7          	jalr	-1070(ra) # 800019a6 <myproc>
    80005ddc:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005dde:	fd840593          	addi	a1,s0,-40
    80005de2:	4501                	li	a0,0
    80005de4:	ffffd097          	auipc	ra,0xffffd
    80005de8:	fdc080e7          	jalr	-36(ra) # 80002dc0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005dec:	fc840593          	addi	a1,s0,-56
    80005df0:	fd040513          	addi	a0,s0,-48
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	ddc080e7          	jalr	-548(ra) # 80004bd0 <pipealloc>
    return -1;
    80005dfc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dfe:	0c054463          	bltz	a0,80005ec6 <sys_pipe+0xfc>
  fd0 = -1;
    80005e02:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e06:	fd043503          	ld	a0,-48(s0)
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	516080e7          	jalr	1302(ra) # 80005320 <fdalloc>
    80005e12:	fca42223          	sw	a0,-60(s0)
    80005e16:	08054b63          	bltz	a0,80005eac <sys_pipe+0xe2>
    80005e1a:	fc843503          	ld	a0,-56(s0)
    80005e1e:	fffff097          	auipc	ra,0xfffff
    80005e22:	502080e7          	jalr	1282(ra) # 80005320 <fdalloc>
    80005e26:	fca42023          	sw	a0,-64(s0)
    80005e2a:	06054863          	bltz	a0,80005e9a <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e2e:	4691                	li	a3,4
    80005e30:	fc440613          	addi	a2,s0,-60
    80005e34:	fd843583          	ld	a1,-40(s0)
    80005e38:	68a8                	ld	a0,80(s1)
    80005e3a:	ffffc097          	auipc	ra,0xffffc
    80005e3e:	82c080e7          	jalr	-2004(ra) # 80001666 <copyout>
    80005e42:	02054063          	bltz	a0,80005e62 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e46:	4691                	li	a3,4
    80005e48:	fc040613          	addi	a2,s0,-64
    80005e4c:	fd843583          	ld	a1,-40(s0)
    80005e50:	0591                	addi	a1,a1,4
    80005e52:	68a8                	ld	a0,80(s1)
    80005e54:	ffffc097          	auipc	ra,0xffffc
    80005e58:	812080e7          	jalr	-2030(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e5c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e5e:	06055463          	bgez	a0,80005ec6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e62:	fc442783          	lw	a5,-60(s0)
    80005e66:	07e9                	addi	a5,a5,26
    80005e68:	078e                	slli	a5,a5,0x3
    80005e6a:	97a6                	add	a5,a5,s1
    80005e6c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e70:	fc042783          	lw	a5,-64(s0)
    80005e74:	07e9                	addi	a5,a5,26
    80005e76:	078e                	slli	a5,a5,0x3
    80005e78:	94be                	add	s1,s1,a5
    80005e7a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e7e:	fd043503          	ld	a0,-48(s0)
    80005e82:	fffff097          	auipc	ra,0xfffff
    80005e86:	a22080e7          	jalr	-1502(ra) # 800048a4 <fileclose>
    fileclose(wf);
    80005e8a:	fc843503          	ld	a0,-56(s0)
    80005e8e:	fffff097          	auipc	ra,0xfffff
    80005e92:	a16080e7          	jalr	-1514(ra) # 800048a4 <fileclose>
    return -1;
    80005e96:	57fd                	li	a5,-1
    80005e98:	a03d                	j	80005ec6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e9a:	fc442783          	lw	a5,-60(s0)
    80005e9e:	0007c763          	bltz	a5,80005eac <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ea2:	07e9                	addi	a5,a5,26
    80005ea4:	078e                	slli	a5,a5,0x3
    80005ea6:	97a6                	add	a5,a5,s1
    80005ea8:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005eac:	fd043503          	ld	a0,-48(s0)
    80005eb0:	fffff097          	auipc	ra,0xfffff
    80005eb4:	9f4080e7          	jalr	-1548(ra) # 800048a4 <fileclose>
    fileclose(wf);
    80005eb8:	fc843503          	ld	a0,-56(s0)
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	9e8080e7          	jalr	-1560(ra) # 800048a4 <fileclose>
    return -1;
    80005ec4:	57fd                	li	a5,-1
}
    80005ec6:	853e                	mv	a0,a5
    80005ec8:	70e2                	ld	ra,56(sp)
    80005eca:	7442                	ld	s0,48(sp)
    80005ecc:	74a2                	ld	s1,40(sp)
    80005ece:	6121                	addi	sp,sp,64
    80005ed0:	8082                	ret
	...

0000000080005ee0 <kernelvec>:
    80005ee0:	7111                	addi	sp,sp,-256
    80005ee2:	e006                	sd	ra,0(sp)
    80005ee4:	e40a                	sd	sp,8(sp)
    80005ee6:	e80e                	sd	gp,16(sp)
    80005ee8:	ec12                	sd	tp,24(sp)
    80005eea:	f016                	sd	t0,32(sp)
    80005eec:	f41a                	sd	t1,40(sp)
    80005eee:	f81e                	sd	t2,48(sp)
    80005ef0:	fc22                	sd	s0,56(sp)
    80005ef2:	e0a6                	sd	s1,64(sp)
    80005ef4:	e4aa                	sd	a0,72(sp)
    80005ef6:	e8ae                	sd	a1,80(sp)
    80005ef8:	ecb2                	sd	a2,88(sp)
    80005efa:	f0b6                	sd	a3,96(sp)
    80005efc:	f4ba                	sd	a4,104(sp)
    80005efe:	f8be                	sd	a5,112(sp)
    80005f00:	fcc2                	sd	a6,120(sp)
    80005f02:	e146                	sd	a7,128(sp)
    80005f04:	e54a                	sd	s2,136(sp)
    80005f06:	e94e                	sd	s3,144(sp)
    80005f08:	ed52                	sd	s4,152(sp)
    80005f0a:	f156                	sd	s5,160(sp)
    80005f0c:	f55a                	sd	s6,168(sp)
    80005f0e:	f95e                	sd	s7,176(sp)
    80005f10:	fd62                	sd	s8,184(sp)
    80005f12:	e1e6                	sd	s9,192(sp)
    80005f14:	e5ea                	sd	s10,200(sp)
    80005f16:	e9ee                	sd	s11,208(sp)
    80005f18:	edf2                	sd	t3,216(sp)
    80005f1a:	f1f6                	sd	t4,224(sp)
    80005f1c:	f5fa                	sd	t5,232(sp)
    80005f1e:	f9fe                	sd	t6,240(sp)
    80005f20:	c9bfc0ef          	jal	ra,80002bba <kerneltrap>
    80005f24:	6082                	ld	ra,0(sp)
    80005f26:	6122                	ld	sp,8(sp)
    80005f28:	61c2                	ld	gp,16(sp)
    80005f2a:	7282                	ld	t0,32(sp)
    80005f2c:	7322                	ld	t1,40(sp)
    80005f2e:	73c2                	ld	t2,48(sp)
    80005f30:	7462                	ld	s0,56(sp)
    80005f32:	6486                	ld	s1,64(sp)
    80005f34:	6526                	ld	a0,72(sp)
    80005f36:	65c6                	ld	a1,80(sp)
    80005f38:	6666                	ld	a2,88(sp)
    80005f3a:	7686                	ld	a3,96(sp)
    80005f3c:	7726                	ld	a4,104(sp)
    80005f3e:	77c6                	ld	a5,112(sp)
    80005f40:	7866                	ld	a6,120(sp)
    80005f42:	688a                	ld	a7,128(sp)
    80005f44:	692a                	ld	s2,136(sp)
    80005f46:	69ca                	ld	s3,144(sp)
    80005f48:	6a6a                	ld	s4,152(sp)
    80005f4a:	7a8a                	ld	s5,160(sp)
    80005f4c:	7b2a                	ld	s6,168(sp)
    80005f4e:	7bca                	ld	s7,176(sp)
    80005f50:	7c6a                	ld	s8,184(sp)
    80005f52:	6c8e                	ld	s9,192(sp)
    80005f54:	6d2e                	ld	s10,200(sp)
    80005f56:	6dce                	ld	s11,208(sp)
    80005f58:	6e6e                	ld	t3,216(sp)
    80005f5a:	7e8e                	ld	t4,224(sp)
    80005f5c:	7f2e                	ld	t5,232(sp)
    80005f5e:	7fce                	ld	t6,240(sp)
    80005f60:	6111                	addi	sp,sp,256
    80005f62:	10200073          	sret
    80005f66:	00000013          	nop
    80005f6a:	00000013          	nop
    80005f6e:	0001                	nop

0000000080005f70 <timervec>:
    80005f70:	34051573          	csrrw	a0,mscratch,a0
    80005f74:	e10c                	sd	a1,0(a0)
    80005f76:	e510                	sd	a2,8(a0)
    80005f78:	e914                	sd	a3,16(a0)
    80005f7a:	6d0c                	ld	a1,24(a0)
    80005f7c:	7110                	ld	a2,32(a0)
    80005f7e:	6194                	ld	a3,0(a1)
    80005f80:	96b2                	add	a3,a3,a2
    80005f82:	e194                	sd	a3,0(a1)
    80005f84:	4589                	li	a1,2
    80005f86:	14459073          	csrw	sip,a1
    80005f8a:	6914                	ld	a3,16(a0)
    80005f8c:	6510                	ld	a2,8(a0)
    80005f8e:	610c                	ld	a1,0(a0)
    80005f90:	34051573          	csrrw	a0,mscratch,a0
    80005f94:	30200073          	mret
	...

0000000080005f9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f9a:	1141                	addi	sp,sp,-16
    80005f9c:	e422                	sd	s0,8(sp)
    80005f9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fa0:	0c0007b7          	lui	a5,0xc000
    80005fa4:	4705                	li	a4,1
    80005fa6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fa8:	c3d8                	sw	a4,4(a5)
}
    80005faa:	6422                	ld	s0,8(sp)
    80005fac:	0141                	addi	sp,sp,16
    80005fae:	8082                	ret

0000000080005fb0 <plicinithart>:

void
plicinithart(void)
{
    80005fb0:	1141                	addi	sp,sp,-16
    80005fb2:	e406                	sd	ra,8(sp)
    80005fb4:	e022                	sd	s0,0(sp)
    80005fb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	9c2080e7          	jalr	-1598(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fc0:	0085171b          	slliw	a4,a0,0x8
    80005fc4:	0c0027b7          	lui	a5,0xc002
    80005fc8:	97ba                	add	a5,a5,a4
    80005fca:	40200713          	li	a4,1026
    80005fce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fd2:	00d5151b          	slliw	a0,a0,0xd
    80005fd6:	0c2017b7          	lui	a5,0xc201
    80005fda:	97aa                	add	a5,a5,a0
    80005fdc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005fe0:	60a2                	ld	ra,8(sp)
    80005fe2:	6402                	ld	s0,0(sp)
    80005fe4:	0141                	addi	sp,sp,16
    80005fe6:	8082                	ret

0000000080005fe8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fe8:	1141                	addi	sp,sp,-16
    80005fea:	e406                	sd	ra,8(sp)
    80005fec:	e022                	sd	s0,0(sp)
    80005fee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ff0:	ffffc097          	auipc	ra,0xffffc
    80005ff4:	98a080e7          	jalr	-1654(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ff8:	00d5151b          	slliw	a0,a0,0xd
    80005ffc:	0c2017b7          	lui	a5,0xc201
    80006000:	97aa                	add	a5,a5,a0
  return irq;
}
    80006002:	43c8                	lw	a0,4(a5)
    80006004:	60a2                	ld	ra,8(sp)
    80006006:	6402                	ld	s0,0(sp)
    80006008:	0141                	addi	sp,sp,16
    8000600a:	8082                	ret

000000008000600c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000600c:	1101                	addi	sp,sp,-32
    8000600e:	ec06                	sd	ra,24(sp)
    80006010:	e822                	sd	s0,16(sp)
    80006012:	e426                	sd	s1,8(sp)
    80006014:	1000                	addi	s0,sp,32
    80006016:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	962080e7          	jalr	-1694(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006020:	00d5151b          	slliw	a0,a0,0xd
    80006024:	0c2017b7          	lui	a5,0xc201
    80006028:	97aa                	add	a5,a5,a0
    8000602a:	c3c4                	sw	s1,4(a5)
}
    8000602c:	60e2                	ld	ra,24(sp)
    8000602e:	6442                	ld	s0,16(sp)
    80006030:	64a2                	ld	s1,8(sp)
    80006032:	6105                	addi	sp,sp,32
    80006034:	8082                	ret

0000000080006036 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006036:	1141                	addi	sp,sp,-16
    80006038:	e406                	sd	ra,8(sp)
    8000603a:	e022                	sd	s0,0(sp)
    8000603c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000603e:	479d                	li	a5,7
    80006040:	04a7cc63          	blt	a5,a0,80006098 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006044:	0001c797          	auipc	a5,0x1c
    80006048:	5fc78793          	addi	a5,a5,1532 # 80022640 <disk>
    8000604c:	97aa                	add	a5,a5,a0
    8000604e:	0187c783          	lbu	a5,24(a5)
    80006052:	ebb9                	bnez	a5,800060a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006054:	00451693          	slli	a3,a0,0x4
    80006058:	0001c797          	auipc	a5,0x1c
    8000605c:	5e878793          	addi	a5,a5,1512 # 80022640 <disk>
    80006060:	6398                	ld	a4,0(a5)
    80006062:	9736                	add	a4,a4,a3
    80006064:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006068:	6398                	ld	a4,0(a5)
    8000606a:	9736                	add	a4,a4,a3
    8000606c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006070:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006074:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006078:	97aa                	add	a5,a5,a0
    8000607a:	4705                	li	a4,1
    8000607c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006080:	0001c517          	auipc	a0,0x1c
    80006084:	5d850513          	addi	a0,a0,1496 # 80022658 <disk+0x18>
    80006088:	ffffc097          	auipc	ra,0xffffc
    8000608c:	0d4080e7          	jalr	212(ra) # 8000215c <wakeup>
}
    80006090:	60a2                	ld	ra,8(sp)
    80006092:	6402                	ld	s0,0(sp)
    80006094:	0141                	addi	sp,sp,16
    80006096:	8082                	ret
    panic("free_desc 1");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	6c850513          	addi	a0,a0,1736 # 80008760 <syscalls+0x310>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	49c080e7          	jalr	1180(ra) # 8000053c <panic>
    panic("free_desc 2");
    800060a8:	00002517          	auipc	a0,0x2
    800060ac:	6c850513          	addi	a0,a0,1736 # 80008770 <syscalls+0x320>
    800060b0:	ffffa097          	auipc	ra,0xffffa
    800060b4:	48c080e7          	jalr	1164(ra) # 8000053c <panic>

00000000800060b8 <virtio_disk_init>:
{
    800060b8:	1101                	addi	sp,sp,-32
    800060ba:	ec06                	sd	ra,24(sp)
    800060bc:	e822                	sd	s0,16(sp)
    800060be:	e426                	sd	s1,8(sp)
    800060c0:	e04a                	sd	s2,0(sp)
    800060c2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060c4:	00002597          	auipc	a1,0x2
    800060c8:	6bc58593          	addi	a1,a1,1724 # 80008780 <syscalls+0x330>
    800060cc:	0001c517          	auipc	a0,0x1c
    800060d0:	69c50513          	addi	a0,a0,1692 # 80022768 <disk+0x128>
    800060d4:	ffffb097          	auipc	ra,0xffffb
    800060d8:	a6e080e7          	jalr	-1426(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060dc:	100017b7          	lui	a5,0x10001
    800060e0:	4398                	lw	a4,0(a5)
    800060e2:	2701                	sext.w	a4,a4
    800060e4:	747277b7          	lui	a5,0x74727
    800060e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060ec:	14f71b63          	bne	a4,a5,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060f0:	100017b7          	lui	a5,0x10001
    800060f4:	43dc                	lw	a5,4(a5)
    800060f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060f8:	4709                	li	a4,2
    800060fa:	14e79463          	bne	a5,a4,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060fe:	100017b7          	lui	a5,0x10001
    80006102:	479c                	lw	a5,8(a5)
    80006104:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006106:	12e79e63          	bne	a5,a4,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000610a:	100017b7          	lui	a5,0x10001
    8000610e:	47d8                	lw	a4,12(a5)
    80006110:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006112:	554d47b7          	lui	a5,0x554d4
    80006116:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000611a:	12f71463          	bne	a4,a5,80006242 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000611e:	100017b7          	lui	a5,0x10001
    80006122:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006126:	4705                	li	a4,1
    80006128:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000612a:	470d                	li	a4,3
    8000612c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000612e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006130:	c7ffe6b7          	lui	a3,0xc7ffe
    80006134:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbfdf>
    80006138:	8f75                	and	a4,a4,a3
    8000613a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000613c:	472d                	li	a4,11
    8000613e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006140:	5bbc                	lw	a5,112(a5)
    80006142:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006146:	8ba1                	andi	a5,a5,8
    80006148:	10078563          	beqz	a5,80006252 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000614c:	100017b7          	lui	a5,0x10001
    80006150:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006154:	43fc                	lw	a5,68(a5)
    80006156:	2781                	sext.w	a5,a5
    80006158:	10079563          	bnez	a5,80006262 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000615c:	100017b7          	lui	a5,0x10001
    80006160:	5bdc                	lw	a5,52(a5)
    80006162:	2781                	sext.w	a5,a5
  if(max == 0)
    80006164:	10078763          	beqz	a5,80006272 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006168:	471d                	li	a4,7
    8000616a:	10f77c63          	bgeu	a4,a5,80006282 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	974080e7          	jalr	-1676(ra) # 80000ae2 <kalloc>
    80006176:	0001c497          	auipc	s1,0x1c
    8000617a:	4ca48493          	addi	s1,s1,1226 # 80022640 <disk>
    8000617e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	962080e7          	jalr	-1694(ra) # 80000ae2 <kalloc>
    80006188:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	958080e7          	jalr	-1704(ra) # 80000ae2 <kalloc>
    80006192:	87aa                	mv	a5,a0
    80006194:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006196:	6088                	ld	a0,0(s1)
    80006198:	cd6d                	beqz	a0,80006292 <virtio_disk_init+0x1da>
    8000619a:	0001c717          	auipc	a4,0x1c
    8000619e:	4ae73703          	ld	a4,1198(a4) # 80022648 <disk+0x8>
    800061a2:	cb65                	beqz	a4,80006292 <virtio_disk_init+0x1da>
    800061a4:	c7fd                	beqz	a5,80006292 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800061a6:	6605                	lui	a2,0x1
    800061a8:	4581                	li	a1,0
    800061aa:	ffffb097          	auipc	ra,0xffffb
    800061ae:	b24080e7          	jalr	-1244(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    800061b2:	0001c497          	auipc	s1,0x1c
    800061b6:	48e48493          	addi	s1,s1,1166 # 80022640 <disk>
    800061ba:	6605                	lui	a2,0x1
    800061bc:	4581                	li	a1,0
    800061be:	6488                	ld	a0,8(s1)
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	b0e080e7          	jalr	-1266(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    800061c8:	6605                	lui	a2,0x1
    800061ca:	4581                	li	a1,0
    800061cc:	6888                	ld	a0,16(s1)
    800061ce:	ffffb097          	auipc	ra,0xffffb
    800061d2:	b00080e7          	jalr	-1280(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061d6:	100017b7          	lui	a5,0x10001
    800061da:	4721                	li	a4,8
    800061dc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061de:	4098                	lw	a4,0(s1)
    800061e0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061e4:	40d8                	lw	a4,4(s1)
    800061e6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061ea:	6498                	ld	a4,8(s1)
    800061ec:	0007069b          	sext.w	a3,a4
    800061f0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061f4:	9701                	srai	a4,a4,0x20
    800061f6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061fa:	6898                	ld	a4,16(s1)
    800061fc:	0007069b          	sext.w	a3,a4
    80006200:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006204:	9701                	srai	a4,a4,0x20
    80006206:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000620a:	4705                	li	a4,1
    8000620c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000620e:	00e48c23          	sb	a4,24(s1)
    80006212:	00e48ca3          	sb	a4,25(s1)
    80006216:	00e48d23          	sb	a4,26(s1)
    8000621a:	00e48da3          	sb	a4,27(s1)
    8000621e:	00e48e23          	sb	a4,28(s1)
    80006222:	00e48ea3          	sb	a4,29(s1)
    80006226:	00e48f23          	sb	a4,30(s1)
    8000622a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000622e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006232:	0727a823          	sw	s2,112(a5)
}
    80006236:	60e2                	ld	ra,24(sp)
    80006238:	6442                	ld	s0,16(sp)
    8000623a:	64a2                	ld	s1,8(sp)
    8000623c:	6902                	ld	s2,0(sp)
    8000623e:	6105                	addi	sp,sp,32
    80006240:	8082                	ret
    panic("could not find virtio disk");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	54e50513          	addi	a0,a0,1358 # 80008790 <syscalls+0x340>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2f2080e7          	jalr	754(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	55e50513          	addi	a0,a0,1374 # 800087b0 <syscalls+0x360>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2e2080e7          	jalr	738(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	56e50513          	addi	a0,a0,1390 # 800087d0 <syscalls+0x380>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d2080e7          	jalr	722(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	57e50513          	addi	a0,a0,1406 # 800087f0 <syscalls+0x3a0>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c2080e7          	jalr	706(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	58e50513          	addi	a0,a0,1422 # 80008810 <syscalls+0x3c0>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b2080e7          	jalr	690(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	59e50513          	addi	a0,a0,1438 # 80008830 <syscalls+0x3e0>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a2080e7          	jalr	674(ra) # 8000053c <panic>

00000000800062a2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062a2:	7159                	addi	sp,sp,-112
    800062a4:	f486                	sd	ra,104(sp)
    800062a6:	f0a2                	sd	s0,96(sp)
    800062a8:	eca6                	sd	s1,88(sp)
    800062aa:	e8ca                	sd	s2,80(sp)
    800062ac:	e4ce                	sd	s3,72(sp)
    800062ae:	e0d2                	sd	s4,64(sp)
    800062b0:	fc56                	sd	s5,56(sp)
    800062b2:	f85a                	sd	s6,48(sp)
    800062b4:	f45e                	sd	s7,40(sp)
    800062b6:	f062                	sd	s8,32(sp)
    800062b8:	ec66                	sd	s9,24(sp)
    800062ba:	e86a                	sd	s10,16(sp)
    800062bc:	1880                	addi	s0,sp,112
    800062be:	8a2a                	mv	s4,a0
    800062c0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062c2:	00c52c83          	lw	s9,12(a0)
    800062c6:	001c9c9b          	slliw	s9,s9,0x1
    800062ca:	1c82                	slli	s9,s9,0x20
    800062cc:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062d0:	0001c517          	auipc	a0,0x1c
    800062d4:	49850513          	addi	a0,a0,1176 # 80022768 <disk+0x128>
    800062d8:	ffffb097          	auipc	ra,0xffffb
    800062dc:	8fa080e7          	jalr	-1798(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    800062e0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800062e2:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062e4:	0001cb17          	auipc	s6,0x1c
    800062e8:	35cb0b13          	addi	s6,s6,860 # 80022640 <disk>
  for(int i = 0; i < 3; i++){
    800062ec:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062ee:	0001cc17          	auipc	s8,0x1c
    800062f2:	47ac0c13          	addi	s8,s8,1146 # 80022768 <disk+0x128>
    800062f6:	a095                	j	8000635a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062f8:	00fb0733          	add	a4,s6,a5
    800062fc:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006300:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006302:	0207c563          	bltz	a5,8000632c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006306:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006308:	0591                	addi	a1,a1,4
    8000630a:	05560d63          	beq	a2,s5,80006364 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000630e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006310:	0001c717          	auipc	a4,0x1c
    80006314:	33070713          	addi	a4,a4,816 # 80022640 <disk>
    80006318:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000631a:	01874683          	lbu	a3,24(a4)
    8000631e:	fee9                	bnez	a3,800062f8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006320:	2785                	addiw	a5,a5,1
    80006322:	0705                	addi	a4,a4,1
    80006324:	fe979be3          	bne	a5,s1,8000631a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006328:	57fd                	li	a5,-1
    8000632a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000632c:	00c05e63          	blez	a2,80006348 <virtio_disk_rw+0xa6>
    80006330:	060a                	slli	a2,a2,0x2
    80006332:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006336:	0009a503          	lw	a0,0(s3)
    8000633a:	00000097          	auipc	ra,0x0
    8000633e:	cfc080e7          	jalr	-772(ra) # 80006036 <free_desc>
      for(int j = 0; j < i; j++)
    80006342:	0991                	addi	s3,s3,4
    80006344:	ffa999e3          	bne	s3,s10,80006336 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006348:	85e2                	mv	a1,s8
    8000634a:	0001c517          	auipc	a0,0x1c
    8000634e:	30e50513          	addi	a0,a0,782 # 80022658 <disk+0x18>
    80006352:	ffffc097          	auipc	ra,0xffffc
    80006356:	da6080e7          	jalr	-602(ra) # 800020f8 <sleep>
  for(int i = 0; i < 3; i++){
    8000635a:	f9040993          	addi	s3,s0,-112
{
    8000635e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006360:	864a                	mv	a2,s2
    80006362:	b775                	j	8000630e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006364:	f9042503          	lw	a0,-112(s0)
    80006368:	00a50713          	addi	a4,a0,10
    8000636c:	0712                	slli	a4,a4,0x4

  if(write)
    8000636e:	0001c797          	auipc	a5,0x1c
    80006372:	2d278793          	addi	a5,a5,722 # 80022640 <disk>
    80006376:	00e786b3          	add	a3,a5,a4
    8000637a:	01703633          	snez	a2,s7
    8000637e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006380:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006384:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006388:	f6070613          	addi	a2,a4,-160
    8000638c:	6394                	ld	a3,0(a5)
    8000638e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006390:	00870593          	addi	a1,a4,8
    80006394:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006396:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006398:	0007b803          	ld	a6,0(a5)
    8000639c:	9642                	add	a2,a2,a6
    8000639e:	46c1                	li	a3,16
    800063a0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063a2:	4585                	li	a1,1
    800063a4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800063a8:	f9442683          	lw	a3,-108(s0)
    800063ac:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063b0:	0692                	slli	a3,a3,0x4
    800063b2:	9836                	add	a6,a6,a3
    800063b4:	058a0613          	addi	a2,s4,88
    800063b8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800063bc:	0007b803          	ld	a6,0(a5)
    800063c0:	96c2                	add	a3,a3,a6
    800063c2:	40000613          	li	a2,1024
    800063c6:	c690                	sw	a2,8(a3)
  if(write)
    800063c8:	001bb613          	seqz	a2,s7
    800063cc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063d0:	00166613          	ori	a2,a2,1
    800063d4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063d8:	f9842603          	lw	a2,-104(s0)
    800063dc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063e0:	00250693          	addi	a3,a0,2
    800063e4:	0692                	slli	a3,a3,0x4
    800063e6:	96be                	add	a3,a3,a5
    800063e8:	58fd                	li	a7,-1
    800063ea:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063ee:	0612                	slli	a2,a2,0x4
    800063f0:	9832                	add	a6,a6,a2
    800063f2:	f9070713          	addi	a4,a4,-112
    800063f6:	973e                	add	a4,a4,a5
    800063f8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800063fc:	6398                	ld	a4,0(a5)
    800063fe:	9732                	add	a4,a4,a2
    80006400:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006402:	4609                	li	a2,2
    80006404:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006408:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000640c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006410:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006414:	6794                	ld	a3,8(a5)
    80006416:	0026d703          	lhu	a4,2(a3)
    8000641a:	8b1d                	andi	a4,a4,7
    8000641c:	0706                	slli	a4,a4,0x1
    8000641e:	96ba                	add	a3,a3,a4
    80006420:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006424:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006428:	6798                	ld	a4,8(a5)
    8000642a:	00275783          	lhu	a5,2(a4)
    8000642e:	2785                	addiw	a5,a5,1
    80006430:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006434:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006438:	100017b7          	lui	a5,0x10001
    8000643c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006440:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006444:	0001c917          	auipc	s2,0x1c
    80006448:	32490913          	addi	s2,s2,804 # 80022768 <disk+0x128>
  while(b->disk == 1) {
    8000644c:	4485                	li	s1,1
    8000644e:	00b79c63          	bne	a5,a1,80006466 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006452:	85ca                	mv	a1,s2
    80006454:	8552                	mv	a0,s4
    80006456:	ffffc097          	auipc	ra,0xffffc
    8000645a:	ca2080e7          	jalr	-862(ra) # 800020f8 <sleep>
  while(b->disk == 1) {
    8000645e:	004a2783          	lw	a5,4(s4)
    80006462:	fe9788e3          	beq	a5,s1,80006452 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006466:	f9042903          	lw	s2,-112(s0)
    8000646a:	00290713          	addi	a4,s2,2
    8000646e:	0712                	slli	a4,a4,0x4
    80006470:	0001c797          	auipc	a5,0x1c
    80006474:	1d078793          	addi	a5,a5,464 # 80022640 <disk>
    80006478:	97ba                	add	a5,a5,a4
    8000647a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000647e:	0001c997          	auipc	s3,0x1c
    80006482:	1c298993          	addi	s3,s3,450 # 80022640 <disk>
    80006486:	00491713          	slli	a4,s2,0x4
    8000648a:	0009b783          	ld	a5,0(s3)
    8000648e:	97ba                	add	a5,a5,a4
    80006490:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006494:	854a                	mv	a0,s2
    80006496:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000649a:	00000097          	auipc	ra,0x0
    8000649e:	b9c080e7          	jalr	-1124(ra) # 80006036 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064a2:	8885                	andi	s1,s1,1
    800064a4:	f0ed                	bnez	s1,80006486 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064a6:	0001c517          	auipc	a0,0x1c
    800064aa:	2c250513          	addi	a0,a0,706 # 80022768 <disk+0x128>
    800064ae:	ffffa097          	auipc	ra,0xffffa
    800064b2:	7d8080e7          	jalr	2008(ra) # 80000c86 <release>
}
    800064b6:	70a6                	ld	ra,104(sp)
    800064b8:	7406                	ld	s0,96(sp)
    800064ba:	64e6                	ld	s1,88(sp)
    800064bc:	6946                	ld	s2,80(sp)
    800064be:	69a6                	ld	s3,72(sp)
    800064c0:	6a06                	ld	s4,64(sp)
    800064c2:	7ae2                	ld	s5,56(sp)
    800064c4:	7b42                	ld	s6,48(sp)
    800064c6:	7ba2                	ld	s7,40(sp)
    800064c8:	7c02                	ld	s8,32(sp)
    800064ca:	6ce2                	ld	s9,24(sp)
    800064cc:	6d42                	ld	s10,16(sp)
    800064ce:	6165                	addi	sp,sp,112
    800064d0:	8082                	ret

00000000800064d2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064d2:	1101                	addi	sp,sp,-32
    800064d4:	ec06                	sd	ra,24(sp)
    800064d6:	e822                	sd	s0,16(sp)
    800064d8:	e426                	sd	s1,8(sp)
    800064da:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064dc:	0001c497          	auipc	s1,0x1c
    800064e0:	16448493          	addi	s1,s1,356 # 80022640 <disk>
    800064e4:	0001c517          	auipc	a0,0x1c
    800064e8:	28450513          	addi	a0,a0,644 # 80022768 <disk+0x128>
    800064ec:	ffffa097          	auipc	ra,0xffffa
    800064f0:	6e6080e7          	jalr	1766(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064f4:	10001737          	lui	a4,0x10001
    800064f8:	533c                	lw	a5,96(a4)
    800064fa:	8b8d                	andi	a5,a5,3
    800064fc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064fe:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006502:	689c                	ld	a5,16(s1)
    80006504:	0204d703          	lhu	a4,32(s1)
    80006508:	0027d783          	lhu	a5,2(a5)
    8000650c:	04f70863          	beq	a4,a5,8000655c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006510:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006514:	6898                	ld	a4,16(s1)
    80006516:	0204d783          	lhu	a5,32(s1)
    8000651a:	8b9d                	andi	a5,a5,7
    8000651c:	078e                	slli	a5,a5,0x3
    8000651e:	97ba                	add	a5,a5,a4
    80006520:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006522:	00278713          	addi	a4,a5,2
    80006526:	0712                	slli	a4,a4,0x4
    80006528:	9726                	add	a4,a4,s1
    8000652a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000652e:	e721                	bnez	a4,80006576 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006530:	0789                	addi	a5,a5,2
    80006532:	0792                	slli	a5,a5,0x4
    80006534:	97a6                	add	a5,a5,s1
    80006536:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006538:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000653c:	ffffc097          	auipc	ra,0xffffc
    80006540:	c20080e7          	jalr	-992(ra) # 8000215c <wakeup>

    disk.used_idx += 1;
    80006544:	0204d783          	lhu	a5,32(s1)
    80006548:	2785                	addiw	a5,a5,1
    8000654a:	17c2                	slli	a5,a5,0x30
    8000654c:	93c1                	srli	a5,a5,0x30
    8000654e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006552:	6898                	ld	a4,16(s1)
    80006554:	00275703          	lhu	a4,2(a4)
    80006558:	faf71ce3          	bne	a4,a5,80006510 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000655c:	0001c517          	auipc	a0,0x1c
    80006560:	20c50513          	addi	a0,a0,524 # 80022768 <disk+0x128>
    80006564:	ffffa097          	auipc	ra,0xffffa
    80006568:	722080e7          	jalr	1826(ra) # 80000c86 <release>
}
    8000656c:	60e2                	ld	ra,24(sp)
    8000656e:	6442                	ld	s0,16(sp)
    80006570:	64a2                	ld	s1,8(sp)
    80006572:	6105                	addi	sp,sp,32
    80006574:	8082                	ret
      panic("virtio_disk_intr status");
    80006576:	00002517          	auipc	a0,0x2
    8000657a:	2d250513          	addi	a0,a0,722 # 80008848 <syscalls+0x3f8>
    8000657e:	ffffa097          	auipc	ra,0xffffa
    80006582:	fbe080e7          	jalr	-66(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
