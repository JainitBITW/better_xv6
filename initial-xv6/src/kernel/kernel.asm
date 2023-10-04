
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
    8000012e:	450080e7          	jalr	1104(ra) # 8000257a <either_copyin>
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
    800001c0:	208080e7          	jalr	520(ra) # 800023c4 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	f46080e7          	jalr	-186(ra) # 80002110 <sleep>
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
    80000214:	314080e7          	jalr	788(ra) # 80002524 <either_copyout>
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
    800002f2:	2e2080e7          	jalr	738(ra) # 800025d0 <procdump>
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
    80000446:	d32080e7          	jalr	-718(ra) # 80002174 <wakeup>
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
    80000894:	8e4080e7          	jalr	-1820(ra) # 80002174 <wakeup>
    
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
    8000091e:	7f6080e7          	jalr	2038(ra) # 80002110 <sleep>
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
    80000ebc:	a04080e7          	jalr	-1532(ra) # 800028bc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	0f0080e7          	jalr	240(ra) # 80005fb0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	096080e7          	jalr	150(ra) # 80001f5e <scheduler>
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
    80000f34:	964080e7          	jalr	-1692(ra) # 80002894 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	984080e7          	jalr	-1660(ra) # 800028bc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	05a080e7          	jalr	90(ra) # 80005f9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	068080e7          	jalr	104(ra) # 80005fb0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	25a080e7          	jalr	602(ra) # 800031aa <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	8f8080e7          	jalr	-1800(ra) # 80003850 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	86e080e7          	jalr	-1938(ra) # 800047ce <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	150080e7          	jalr	336(ra) # 800060b8 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	dd0080e7          	jalr	-560(ra) # 80001d40 <userinit>
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
    80001a04:	ed4080e7          	jalr	-300(ra) # 800028d4 <usertrapret>
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
    80001a1e:	db6080e7          	jalr	-586(ra) # 800037d0 <fsinit>
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
    80001a7c:	340080e7          	jalr	832(ra) # 80002db8 <argint>
  argaddr(1, &handler) ;
    80001a80:	fe040593          	addi	a1,s0,-32
    80001a84:	4505                	li	a0,1
    80001a86:	00001097          	auipc	ra,0x1
    80001a8a:	352080e7          	jalr	850(ra) # 80002dd8 <argaddr>
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
  if (p->backup_trapframe)
    80001bea:	1884b503          	ld	a0,392(s1)
    80001bee:	c509                	beqz	a0,80001bf8 <freeproc+0x3a>
    kfree((void *)p->backup_trapframe);
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	df4080e7          	jalr	-524(ra) # 800009e4 <kfree>
  p->pagetable = 0;
    80001bf8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bfc:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c00:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c04:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c08:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c0c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c10:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c14:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c18:	0004ac23          	sw	zero,24(s1)
}
    80001c1c:	60e2                	ld	ra,24(sp)
    80001c1e:	6442                	ld	s0,16(sp)
    80001c20:	64a2                	ld	s1,8(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret

0000000080001c26 <allocproc>:
{
    80001c26:	1101                	addi	sp,sp,-32
    80001c28:	ec06                	sd	ra,24(sp)
    80001c2a:	e822                	sd	s0,16(sp)
    80001c2c:	e426                	sd	s1,8(sp)
    80001c2e:	e04a                	sd	s2,0(sp)
    80001c30:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c32:	0000f497          	auipc	s1,0xf
    80001c36:	36e48493          	addi	s1,s1,878 # 80010fa0 <proc>
    80001c3a:	00015917          	auipc	s2,0x15
    80001c3e:	76690913          	addi	s2,s2,1894 # 800173a0 <tickslock>
    acquire(&p->lock);
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	f8e080e7          	jalr	-114(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001c4c:	4c9c                	lw	a5,24(s1)
    80001c4e:	cf81                	beqz	a5,80001c66 <allocproc+0x40>
      release(&p->lock);
    80001c50:	8526                	mv	a0,s1
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	034080e7          	jalr	52(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c5a:	19048493          	addi	s1,s1,400
    80001c5e:	ff2492e3          	bne	s1,s2,80001c42 <allocproc+0x1c>
  return 0;
    80001c62:	4481                	li	s1,0
    80001c64:	a059                	j	80001cea <allocproc+0xc4>
  p->pid = allocpid();
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	dbe080e7          	jalr	-578(ra) # 80001a24 <allocpid>
    80001c6e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c70:	4785                	li	a5,1
    80001c72:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	e6e080e7          	jalr	-402(ra) # 80000ae2 <kalloc>
    80001c7c:	892a                	mv	s2,a0
    80001c7e:	eca8                	sd	a0,88(s1)
    80001c80:	cd25                	beqz	a0,80001cf8 <allocproc+0xd2>
  if((p->backup_trapframe = (struct trapframe *)kalloc()) == 0){
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	e60080e7          	jalr	-416(ra) # 80000ae2 <kalloc>
    80001c8a:	892a                	mv	s2,a0
    80001c8c:	18a4b423          	sd	a0,392(s1)
    80001c90:	c141                	beqz	a0,80001d10 <allocproc+0xea>
  p->pagetable = proc_pagetable(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	e3c080e7          	jalr	-452(ra) # 80001ad0 <proc_pagetable>
    80001c9c:	892a                	mv	s2,a0
    80001c9e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001ca0:	c541                	beqz	a0,80001d28 <allocproc+0x102>
  memset(&p->context, 0, sizeof(p->context));
    80001ca2:	07000613          	li	a2,112
    80001ca6:	4581                	li	a1,0
    80001ca8:	06048513          	addi	a0,s1,96
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	022080e7          	jalr	34(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001cb4:	00000797          	auipc	a5,0x0
    80001cb8:	d2a78793          	addi	a5,a5,-726 # 800019de <forkret>
    80001cbc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cbe:	60bc                	ld	a5,64(s1)
    80001cc0:	6705                	lui	a4,0x1
    80001cc2:	97ba                	add	a5,a5,a4
    80001cc4:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001cc6:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001cca:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001cce:	00007797          	auipc	a5,0x7
    80001cd2:	c327a783          	lw	a5,-974(a5) # 80008900 <ticks>
    80001cd6:	16f4a623          	sw	a5,364(s1)
  p->is_sigalarm = 0;
    80001cda:	1604aa23          	sw	zero,372(s1)
  p->ticks = 0;
    80001cde:	1604ac23          	sw	zero,376(s1)
  p->now_ticks = 0;
    80001ce2:	1604ae23          	sw	zero,380(s1)
  p->handler = 0;
    80001ce6:	1804b023          	sd	zero,384(s1)
}
    80001cea:	8526                	mv	a0,s1
    80001cec:	60e2                	ld	ra,24(sp)
    80001cee:	6442                	ld	s0,16(sp)
    80001cf0:	64a2                	ld	s1,8(sp)
    80001cf2:	6902                	ld	s2,0(sp)
    80001cf4:	6105                	addi	sp,sp,32
    80001cf6:	8082                	ret
    freeproc(p);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	ec4080e7          	jalr	-316(ra) # 80001bbe <freeproc>
    release(&p->lock);
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	f82080e7          	jalr	-126(ra) # 80000c86 <release>
    return 0;
    80001d0c:	84ca                	mv	s1,s2
    80001d0e:	bff1                	j	80001cea <allocproc+0xc4>
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
    80001d26:	b7d1                	j	80001cea <allocproc+0xc4>
    freeproc(p);
    80001d28:	8526                	mv	a0,s1
    80001d2a:	00000097          	auipc	ra,0x0
    80001d2e:	e94080e7          	jalr	-364(ra) # 80001bbe <freeproc>
    release(&p->lock);
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	f52080e7          	jalr	-174(ra) # 80000c86 <release>
    return 0;
    80001d3c:	84ca                	mv	s1,s2
    80001d3e:	b775                	j	80001cea <allocproc+0xc4>

0000000080001d40 <userinit>:
{
    80001d40:	1101                	addi	sp,sp,-32
    80001d42:	ec06                	sd	ra,24(sp)
    80001d44:	e822                	sd	s0,16(sp)
    80001d46:	e426                	sd	s1,8(sp)
    80001d48:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	edc080e7          	jalr	-292(ra) # 80001c26 <allocproc>
    80001d52:	84aa                	mv	s1,a0
  initproc = p;
    80001d54:	00007797          	auipc	a5,0x7
    80001d58:	baa7b223          	sd	a0,-1116(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d5c:	03400613          	li	a2,52
    80001d60:	00007597          	auipc	a1,0x7
    80001d64:	b1058593          	addi	a1,a1,-1264 # 80008870 <initcode>
    80001d68:	6928                	ld	a0,80(a0)
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	5e6080e7          	jalr	1510(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001d72:	6785                	lui	a5,0x1
    80001d74:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d76:	6cb8                	ld	a4,88(s1)
    80001d78:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d7c:	6cb8                	ld	a4,88(s1)
    80001d7e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d80:	4641                	li	a2,16
    80001d82:	00006597          	auipc	a1,0x6
    80001d86:	47e58593          	addi	a1,a1,1150 # 80008200 <digits+0x1c0>
    80001d8a:	15848513          	addi	a0,s1,344
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	088080e7          	jalr	136(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d96:	00006517          	auipc	a0,0x6
    80001d9a:	47a50513          	addi	a0,a0,1146 # 80008210 <digits+0x1d0>
    80001d9e:	00002097          	auipc	ra,0x2
    80001da2:	450080e7          	jalr	1104(ra) # 800041ee <namei>
    80001da6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001daa:	478d                	li	a5,3
    80001dac:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001dae:	8526                	mv	a0,s1
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	ed6080e7          	jalr	-298(ra) # 80000c86 <release>
}
    80001db8:	60e2                	ld	ra,24(sp)
    80001dba:	6442                	ld	s0,16(sp)
    80001dbc:	64a2                	ld	s1,8(sp)
    80001dbe:	6105                	addi	sp,sp,32
    80001dc0:	8082                	ret

0000000080001dc2 <growproc>:
{
    80001dc2:	1101                	addi	sp,sp,-32
    80001dc4:	ec06                	sd	ra,24(sp)
    80001dc6:	e822                	sd	s0,16(sp)
    80001dc8:	e426                	sd	s1,8(sp)
    80001dca:	e04a                	sd	s2,0(sp)
    80001dcc:	1000                	addi	s0,sp,32
    80001dce:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	bd6080e7          	jalr	-1066(ra) # 800019a6 <myproc>
    80001dd8:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dda:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001ddc:	01204c63          	bgtz	s2,80001df4 <growproc+0x32>
  else if (n < 0)
    80001de0:	02094663          	bltz	s2,80001e0c <growproc+0x4a>
  p->sz = sz;
    80001de4:	e4ac                	sd	a1,72(s1)
  return 0;
    80001de6:	4501                	li	a0,0
}
    80001de8:	60e2                	ld	ra,24(sp)
    80001dea:	6442                	ld	s0,16(sp)
    80001dec:	64a2                	ld	s1,8(sp)
    80001dee:	6902                	ld	s2,0(sp)
    80001df0:	6105                	addi	sp,sp,32
    80001df2:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001df4:	4691                	li	a3,4
    80001df6:	00b90633          	add	a2,s2,a1
    80001dfa:	6928                	ld	a0,80(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	60e080e7          	jalr	1550(ra) # 8000140a <uvmalloc>
    80001e04:	85aa                	mv	a1,a0
    80001e06:	fd79                	bnez	a0,80001de4 <growproc+0x22>
      return -1;
    80001e08:	557d                	li	a0,-1
    80001e0a:	bff9                	j	80001de8 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e0c:	00b90633          	add	a2,s2,a1
    80001e10:	6928                	ld	a0,80(a0)
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	5b0080e7          	jalr	1456(ra) # 800013c2 <uvmdealloc>
    80001e1a:	85aa                	mv	a1,a0
    80001e1c:	b7e1                	j	80001de4 <growproc+0x22>

0000000080001e1e <fork>:
{
    80001e1e:	7139                	addi	sp,sp,-64
    80001e20:	fc06                	sd	ra,56(sp)
    80001e22:	f822                	sd	s0,48(sp)
    80001e24:	f426                	sd	s1,40(sp)
    80001e26:	f04a                	sd	s2,32(sp)
    80001e28:	ec4e                	sd	s3,24(sp)
    80001e2a:	e852                	sd	s4,16(sp)
    80001e2c:	e456                	sd	s5,8(sp)
    80001e2e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	b76080e7          	jalr	-1162(ra) # 800019a6 <myproc>
    80001e38:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001e3a:	00000097          	auipc	ra,0x0
    80001e3e:	dec080e7          	jalr	-532(ra) # 80001c26 <allocproc>
    80001e42:	10050c63          	beqz	a0,80001f5a <fork+0x13c>
    80001e46:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e48:	048ab603          	ld	a2,72(s5)
    80001e4c:	692c                	ld	a1,80(a0)
    80001e4e:	050ab503          	ld	a0,80(s5)
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	710080e7          	jalr	1808(ra) # 80001562 <uvmcopy>
    80001e5a:	04054863          	bltz	a0,80001eaa <fork+0x8c>
  np->sz = p->sz;
    80001e5e:	048ab783          	ld	a5,72(s5)
    80001e62:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e66:	058ab683          	ld	a3,88(s5)
    80001e6a:	87b6                	mv	a5,a3
    80001e6c:	058a3703          	ld	a4,88(s4)
    80001e70:	12068693          	addi	a3,a3,288
    80001e74:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e78:	6788                	ld	a0,8(a5)
    80001e7a:	6b8c                	ld	a1,16(a5)
    80001e7c:	6f90                	ld	a2,24(a5)
    80001e7e:	01073023          	sd	a6,0(a4)
    80001e82:	e708                	sd	a0,8(a4)
    80001e84:	eb0c                	sd	a1,16(a4)
    80001e86:	ef10                	sd	a2,24(a4)
    80001e88:	02078793          	addi	a5,a5,32
    80001e8c:	02070713          	addi	a4,a4,32
    80001e90:	fed792e3          	bne	a5,a3,80001e74 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e94:	058a3783          	ld	a5,88(s4)
    80001e98:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e9c:	0d0a8493          	addi	s1,s5,208
    80001ea0:	0d0a0913          	addi	s2,s4,208
    80001ea4:	150a8993          	addi	s3,s5,336
    80001ea8:	a00d                	j	80001eca <fork+0xac>
    freeproc(np);
    80001eaa:	8552                	mv	a0,s4
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	d12080e7          	jalr	-750(ra) # 80001bbe <freeproc>
    release(&np->lock);
    80001eb4:	8552                	mv	a0,s4
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	dd0080e7          	jalr	-560(ra) # 80000c86 <release>
    return -1;
    80001ebe:	597d                	li	s2,-1
    80001ec0:	a059                	j	80001f46 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001ec2:	04a1                	addi	s1,s1,8
    80001ec4:	0921                	addi	s2,s2,8
    80001ec6:	01348b63          	beq	s1,s3,80001edc <fork+0xbe>
    if (p->ofile[i])
    80001eca:	6088                	ld	a0,0(s1)
    80001ecc:	d97d                	beqz	a0,80001ec2 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ece:	00003097          	auipc	ra,0x3
    80001ed2:	992080e7          	jalr	-1646(ra) # 80004860 <filedup>
    80001ed6:	00a93023          	sd	a0,0(s2)
    80001eda:	b7e5                	j	80001ec2 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001edc:	150ab503          	ld	a0,336(s5)
    80001ee0:	00002097          	auipc	ra,0x2
    80001ee4:	b2a080e7          	jalr	-1238(ra) # 80003a0a <idup>
    80001ee8:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eec:	4641                	li	a2,16
    80001eee:	158a8593          	addi	a1,s5,344
    80001ef2:	158a0513          	addi	a0,s4,344
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	f20080e7          	jalr	-224(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001efe:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f02:	8552                	mv	a0,s4
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	d82080e7          	jalr	-638(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001f0c:	0000f497          	auipc	s1,0xf
    80001f10:	c7c48493          	addi	s1,s1,-900 # 80010b88 <wait_lock>
    80001f14:	8526                	mv	a0,s1
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	cbc080e7          	jalr	-836(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001f1e:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f22:	8526                	mv	a0,s1
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	d62080e7          	jalr	-670(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001f2c:	8552                	mv	a0,s4
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	ca4080e7          	jalr	-860(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001f36:	478d                	li	a5,3
    80001f38:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f3c:	8552                	mv	a0,s4
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	d48080e7          	jalr	-696(ra) # 80000c86 <release>
}
    80001f46:	854a                	mv	a0,s2
    80001f48:	70e2                	ld	ra,56(sp)
    80001f4a:	7442                	ld	s0,48(sp)
    80001f4c:	74a2                	ld	s1,40(sp)
    80001f4e:	7902                	ld	s2,32(sp)
    80001f50:	69e2                	ld	s3,24(sp)
    80001f52:	6a42                	ld	s4,16(sp)
    80001f54:	6aa2                	ld	s5,8(sp)
    80001f56:	6121                	addi	sp,sp,64
    80001f58:	8082                	ret
    return -1;
    80001f5a:	597d                	li	s2,-1
    80001f5c:	b7ed                	j	80001f46 <fork+0x128>

0000000080001f5e <scheduler>:
{
    80001f5e:	7139                	addi	sp,sp,-64
    80001f60:	fc06                	sd	ra,56(sp)
    80001f62:	f822                	sd	s0,48(sp)
    80001f64:	f426                	sd	s1,40(sp)
    80001f66:	f04a                	sd	s2,32(sp)
    80001f68:	ec4e                	sd	s3,24(sp)
    80001f6a:	e852                	sd	s4,16(sp)
    80001f6c:	e456                	sd	s5,8(sp)
    80001f6e:	e05a                	sd	s6,0(sp)
    80001f70:	0080                	addi	s0,sp,64
    80001f72:	8792                	mv	a5,tp
  int id = r_tp();
    80001f74:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f76:	00779a93          	slli	s5,a5,0x7
    80001f7a:	0000f717          	auipc	a4,0xf
    80001f7e:	bf670713          	addi	a4,a4,-1034 # 80010b70 <pid_lock>
    80001f82:	9756                	add	a4,a4,s5
    80001f84:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f88:	0000f717          	auipc	a4,0xf
    80001f8c:	c2070713          	addi	a4,a4,-992 # 80010ba8 <cpus+0x8>
    80001f90:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f92:	498d                	li	s3,3
        p->state = RUNNING;
    80001f94:	4b11                	li	s6,4
        c->proc = p;
    80001f96:	079e                	slli	a5,a5,0x7
    80001f98:	0000fa17          	auipc	s4,0xf
    80001f9c:	bd8a0a13          	addi	s4,s4,-1064 # 80010b70 <pid_lock>
    80001fa0:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001fa2:	00015917          	auipc	s2,0x15
    80001fa6:	3fe90913          	addi	s2,s2,1022 # 800173a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001faa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fb2:	10079073          	csrw	sstatus,a5
    80001fb6:	0000f497          	auipc	s1,0xf
    80001fba:	fea48493          	addi	s1,s1,-22 # 80010fa0 <proc>
    80001fbe:	a811                	j	80001fd2 <scheduler+0x74>
      release(&p->lock);
    80001fc0:	8526                	mv	a0,s1
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	cc4080e7          	jalr	-828(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fca:	19048493          	addi	s1,s1,400
    80001fce:	fd248ee3          	beq	s1,s2,80001faa <scheduler+0x4c>
      acquire(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	bfe080e7          	jalr	-1026(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    80001fdc:	4c9c                	lw	a5,24(s1)
    80001fde:	ff3791e3          	bne	a5,s3,80001fc0 <scheduler+0x62>
        p->state = RUNNING;
    80001fe2:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fe6:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fea:	06048593          	addi	a1,s1,96
    80001fee:	8556                	mv	a0,s5
    80001ff0:	00001097          	auipc	ra,0x1
    80001ff4:	83a080e7          	jalr	-1990(ra) # 8000282a <swtch>
        c->proc = 0;
    80001ff8:	020a3823          	sd	zero,48(s4)
    80001ffc:	b7d1                	j	80001fc0 <scheduler+0x62>

0000000080001ffe <sched>:
{
    80001ffe:	7179                	addi	sp,sp,-48
    80002000:	f406                	sd	ra,40(sp)
    80002002:	f022                	sd	s0,32(sp)
    80002004:	ec26                	sd	s1,24(sp)
    80002006:	e84a                	sd	s2,16(sp)
    80002008:	e44e                	sd	s3,8(sp)
    8000200a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	99a080e7          	jalr	-1638(ra) # 800019a6 <myproc>
    80002014:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	b42080e7          	jalr	-1214(ra) # 80000b58 <holding>
    8000201e:	c93d                	beqz	a0,80002094 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002020:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002022:	2781                	sext.w	a5,a5
    80002024:	079e                	slli	a5,a5,0x7
    80002026:	0000f717          	auipc	a4,0xf
    8000202a:	b4a70713          	addi	a4,a4,-1206 # 80010b70 <pid_lock>
    8000202e:	97ba                	add	a5,a5,a4
    80002030:	0a87a703          	lw	a4,168(a5)
    80002034:	4785                	li	a5,1
    80002036:	06f71763          	bne	a4,a5,800020a4 <sched+0xa6>
  if (p->state == RUNNING)
    8000203a:	4c98                	lw	a4,24(s1)
    8000203c:	4791                	li	a5,4
    8000203e:	06f70b63          	beq	a4,a5,800020b4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002042:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002046:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002048:	efb5                	bnez	a5,800020c4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000204a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000204c:	0000f917          	auipc	s2,0xf
    80002050:	b2490913          	addi	s2,s2,-1244 # 80010b70 <pid_lock>
    80002054:	2781                	sext.w	a5,a5
    80002056:	079e                	slli	a5,a5,0x7
    80002058:	97ca                	add	a5,a5,s2
    8000205a:	0ac7a983          	lw	s3,172(a5)
    8000205e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002060:	2781                	sext.w	a5,a5
    80002062:	079e                	slli	a5,a5,0x7
    80002064:	0000f597          	auipc	a1,0xf
    80002068:	b4458593          	addi	a1,a1,-1212 # 80010ba8 <cpus+0x8>
    8000206c:	95be                	add	a1,a1,a5
    8000206e:	06048513          	addi	a0,s1,96
    80002072:	00000097          	auipc	ra,0x0
    80002076:	7b8080e7          	jalr	1976(ra) # 8000282a <swtch>
    8000207a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000207c:	2781                	sext.w	a5,a5
    8000207e:	079e                	slli	a5,a5,0x7
    80002080:	993e                	add	s2,s2,a5
    80002082:	0b392623          	sw	s3,172(s2)
}
    80002086:	70a2                	ld	ra,40(sp)
    80002088:	7402                	ld	s0,32(sp)
    8000208a:	64e2                	ld	s1,24(sp)
    8000208c:	6942                	ld	s2,16(sp)
    8000208e:	69a2                	ld	s3,8(sp)
    80002090:	6145                	addi	sp,sp,48
    80002092:	8082                	ret
    panic("sched p->lock");
    80002094:	00006517          	auipc	a0,0x6
    80002098:	18450513          	addi	a0,a0,388 # 80008218 <digits+0x1d8>
    8000209c:	ffffe097          	auipc	ra,0xffffe
    800020a0:	4a0080e7          	jalr	1184(ra) # 8000053c <panic>
    panic("sched locks");
    800020a4:	00006517          	auipc	a0,0x6
    800020a8:	18450513          	addi	a0,a0,388 # 80008228 <digits+0x1e8>
    800020ac:	ffffe097          	auipc	ra,0xffffe
    800020b0:	490080e7          	jalr	1168(ra) # 8000053c <panic>
    panic("sched running");
    800020b4:	00006517          	auipc	a0,0x6
    800020b8:	18450513          	addi	a0,a0,388 # 80008238 <digits+0x1f8>
    800020bc:	ffffe097          	auipc	ra,0xffffe
    800020c0:	480080e7          	jalr	1152(ra) # 8000053c <panic>
    panic("sched interruptible");
    800020c4:	00006517          	auipc	a0,0x6
    800020c8:	18450513          	addi	a0,a0,388 # 80008248 <digits+0x208>
    800020cc:	ffffe097          	auipc	ra,0xffffe
    800020d0:	470080e7          	jalr	1136(ra) # 8000053c <panic>

00000000800020d4 <yield>:
{
    800020d4:	1101                	addi	sp,sp,-32
    800020d6:	ec06                	sd	ra,24(sp)
    800020d8:	e822                	sd	s0,16(sp)
    800020da:	e426                	sd	s1,8(sp)
    800020dc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	8c8080e7          	jalr	-1848(ra) # 800019a6 <myproc>
    800020e6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	aea080e7          	jalr	-1302(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    800020f0:	478d                	li	a5,3
    800020f2:	cc9c                	sw	a5,24(s1)
  sched();
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	f0a080e7          	jalr	-246(ra) # 80001ffe <sched>
  release(&p->lock);
    800020fc:	8526                	mv	a0,s1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	b88080e7          	jalr	-1144(ra) # 80000c86 <release>
}
    80002106:	60e2                	ld	ra,24(sp)
    80002108:	6442                	ld	s0,16(sp)
    8000210a:	64a2                	ld	s1,8(sp)
    8000210c:	6105                	addi	sp,sp,32
    8000210e:	8082                	ret

0000000080002110 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002110:	7179                	addi	sp,sp,-48
    80002112:	f406                	sd	ra,40(sp)
    80002114:	f022                	sd	s0,32(sp)
    80002116:	ec26                	sd	s1,24(sp)
    80002118:	e84a                	sd	s2,16(sp)
    8000211a:	e44e                	sd	s3,8(sp)
    8000211c:	1800                	addi	s0,sp,48
    8000211e:	89aa                	mv	s3,a0
    80002120:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002122:	00000097          	auipc	ra,0x0
    80002126:	884080e7          	jalr	-1916(ra) # 800019a6 <myproc>
    8000212a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	aa6080e7          	jalr	-1370(ra) # 80000bd2 <acquire>
  release(lk);
    80002134:	854a                	mv	a0,s2
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	b50080e7          	jalr	-1200(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    8000213e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002142:	4789                	li	a5,2
    80002144:	cc9c                	sw	a5,24(s1)

  sched();
    80002146:	00000097          	auipc	ra,0x0
    8000214a:	eb8080e7          	jalr	-328(ra) # 80001ffe <sched>

  // Tidy up.
  p->chan = 0;
    8000214e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002152:	8526                	mv	a0,s1
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	b32080e7          	jalr	-1230(ra) # 80000c86 <release>
  acquire(lk);
    8000215c:	854a                	mv	a0,s2
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	a74080e7          	jalr	-1420(ra) # 80000bd2 <acquire>
}
    80002166:	70a2                	ld	ra,40(sp)
    80002168:	7402                	ld	s0,32(sp)
    8000216a:	64e2                	ld	s1,24(sp)
    8000216c:	6942                	ld	s2,16(sp)
    8000216e:	69a2                	ld	s3,8(sp)
    80002170:	6145                	addi	sp,sp,48
    80002172:	8082                	ret

0000000080002174 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002174:	7139                	addi	sp,sp,-64
    80002176:	fc06                	sd	ra,56(sp)
    80002178:	f822                	sd	s0,48(sp)
    8000217a:	f426                	sd	s1,40(sp)
    8000217c:	f04a                	sd	s2,32(sp)
    8000217e:	ec4e                	sd	s3,24(sp)
    80002180:	e852                	sd	s4,16(sp)
    80002182:	e456                	sd	s5,8(sp)
    80002184:	0080                	addi	s0,sp,64
    80002186:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002188:	0000f497          	auipc	s1,0xf
    8000218c:	e1848493          	addi	s1,s1,-488 # 80010fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002190:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002192:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002194:	00015917          	auipc	s2,0x15
    80002198:	20c90913          	addi	s2,s2,524 # 800173a0 <tickslock>
    8000219c:	a811                	j	800021b0 <wakeup+0x3c>
      }
      release(&p->lock);
    8000219e:	8526                	mv	a0,s1
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	ae6080e7          	jalr	-1306(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800021a8:	19048493          	addi	s1,s1,400
    800021ac:	03248663          	beq	s1,s2,800021d8 <wakeup+0x64>
    if (p != myproc())
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	7f6080e7          	jalr	2038(ra) # 800019a6 <myproc>
    800021b8:	fea488e3          	beq	s1,a0,800021a8 <wakeup+0x34>
      acquire(&p->lock);
    800021bc:	8526                	mv	a0,s1
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	a14080e7          	jalr	-1516(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800021c6:	4c9c                	lw	a5,24(s1)
    800021c8:	fd379be3          	bne	a5,s3,8000219e <wakeup+0x2a>
    800021cc:	709c                	ld	a5,32(s1)
    800021ce:	fd4798e3          	bne	a5,s4,8000219e <wakeup+0x2a>
        p->state = RUNNABLE;
    800021d2:	0154ac23          	sw	s5,24(s1)
    800021d6:	b7e1                	j	8000219e <wakeup+0x2a>
    }
  }
}
    800021d8:	70e2                	ld	ra,56(sp)
    800021da:	7442                	ld	s0,48(sp)
    800021dc:	74a2                	ld	s1,40(sp)
    800021de:	7902                	ld	s2,32(sp)
    800021e0:	69e2                	ld	s3,24(sp)
    800021e2:	6a42                	ld	s4,16(sp)
    800021e4:	6aa2                	ld	s5,8(sp)
    800021e6:	6121                	addi	sp,sp,64
    800021e8:	8082                	ret

00000000800021ea <reparent>:
{
    800021ea:	7179                	addi	sp,sp,-48
    800021ec:	f406                	sd	ra,40(sp)
    800021ee:	f022                	sd	s0,32(sp)
    800021f0:	ec26                	sd	s1,24(sp)
    800021f2:	e84a                	sd	s2,16(sp)
    800021f4:	e44e                	sd	s3,8(sp)
    800021f6:	e052                	sd	s4,0(sp)
    800021f8:	1800                	addi	s0,sp,48
    800021fa:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021fc:	0000f497          	auipc	s1,0xf
    80002200:	da448493          	addi	s1,s1,-604 # 80010fa0 <proc>
      pp->parent = initproc;
    80002204:	00006a17          	auipc	s4,0x6
    80002208:	6f4a0a13          	addi	s4,s4,1780 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000220c:	00015997          	auipc	s3,0x15
    80002210:	19498993          	addi	s3,s3,404 # 800173a0 <tickslock>
    80002214:	a029                	j	8000221e <reparent+0x34>
    80002216:	19048493          	addi	s1,s1,400
    8000221a:	01348d63          	beq	s1,s3,80002234 <reparent+0x4a>
    if (pp->parent == p)
    8000221e:	7c9c                	ld	a5,56(s1)
    80002220:	ff279be3          	bne	a5,s2,80002216 <reparent+0x2c>
      pp->parent = initproc;
    80002224:	000a3503          	ld	a0,0(s4)
    80002228:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	f4a080e7          	jalr	-182(ra) # 80002174 <wakeup>
    80002232:	b7d5                	j	80002216 <reparent+0x2c>
}
    80002234:	70a2                	ld	ra,40(sp)
    80002236:	7402                	ld	s0,32(sp)
    80002238:	64e2                	ld	s1,24(sp)
    8000223a:	6942                	ld	s2,16(sp)
    8000223c:	69a2                	ld	s3,8(sp)
    8000223e:	6a02                	ld	s4,0(sp)
    80002240:	6145                	addi	sp,sp,48
    80002242:	8082                	ret

0000000080002244 <exit>:
{
    80002244:	7179                	addi	sp,sp,-48
    80002246:	f406                	sd	ra,40(sp)
    80002248:	f022                	sd	s0,32(sp)
    8000224a:	ec26                	sd	s1,24(sp)
    8000224c:	e84a                	sd	s2,16(sp)
    8000224e:	e44e                	sd	s3,8(sp)
    80002250:	e052                	sd	s4,0(sp)
    80002252:	1800                	addi	s0,sp,48
    80002254:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	750080e7          	jalr	1872(ra) # 800019a6 <myproc>
    8000225e:	89aa                	mv	s3,a0
  if (p == initproc)
    80002260:	00006797          	auipc	a5,0x6
    80002264:	6987b783          	ld	a5,1688(a5) # 800088f8 <initproc>
    80002268:	0d050493          	addi	s1,a0,208
    8000226c:	15050913          	addi	s2,a0,336
    80002270:	02a79363          	bne	a5,a0,80002296 <exit+0x52>
    panic("init exiting");
    80002274:	00006517          	auipc	a0,0x6
    80002278:	fec50513          	addi	a0,a0,-20 # 80008260 <digits+0x220>
    8000227c:	ffffe097          	auipc	ra,0xffffe
    80002280:	2c0080e7          	jalr	704(ra) # 8000053c <panic>
      fileclose(f);
    80002284:	00002097          	auipc	ra,0x2
    80002288:	62e080e7          	jalr	1582(ra) # 800048b2 <fileclose>
      p->ofile[fd] = 0;
    8000228c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002290:	04a1                	addi	s1,s1,8
    80002292:	01248563          	beq	s1,s2,8000229c <exit+0x58>
    if (p->ofile[fd])
    80002296:	6088                	ld	a0,0(s1)
    80002298:	f575                	bnez	a0,80002284 <exit+0x40>
    8000229a:	bfdd                	j	80002290 <exit+0x4c>
  begin_op();
    8000229c:	00002097          	auipc	ra,0x2
    800022a0:	152080e7          	jalr	338(ra) # 800043ee <begin_op>
  iput(p->cwd);
    800022a4:	1509b503          	ld	a0,336(s3)
    800022a8:	00002097          	auipc	ra,0x2
    800022ac:	95a080e7          	jalr	-1702(ra) # 80003c02 <iput>
  end_op();
    800022b0:	00002097          	auipc	ra,0x2
    800022b4:	1b8080e7          	jalr	440(ra) # 80004468 <end_op>
  p->cwd = 0;
    800022b8:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022bc:	0000f497          	auipc	s1,0xf
    800022c0:	8cc48493          	addi	s1,s1,-1844 # 80010b88 <wait_lock>
    800022c4:	8526                	mv	a0,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	90c080e7          	jalr	-1780(ra) # 80000bd2 <acquire>
  reparent(p);
    800022ce:	854e                	mv	a0,s3
    800022d0:	00000097          	auipc	ra,0x0
    800022d4:	f1a080e7          	jalr	-230(ra) # 800021ea <reparent>
  wakeup(p->parent);
    800022d8:	0389b503          	ld	a0,56(s3)
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	e98080e7          	jalr	-360(ra) # 80002174 <wakeup>
  acquire(&p->lock);
    800022e4:	854e                	mv	a0,s3
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	8ec080e7          	jalr	-1812(ra) # 80000bd2 <acquire>
  p->xstate = status;
    800022ee:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022f2:	4795                	li	a5,5
    800022f4:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800022f8:	00006797          	auipc	a5,0x6
    800022fc:	6087a783          	lw	a5,1544(a5) # 80008900 <ticks>
    80002300:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002304:	8526                	mv	a0,s1
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	980080e7          	jalr	-1664(ra) # 80000c86 <release>
  sched();
    8000230e:	00000097          	auipc	ra,0x0
    80002312:	cf0080e7          	jalr	-784(ra) # 80001ffe <sched>
  panic("zombie exit");
    80002316:	00006517          	auipc	a0,0x6
    8000231a:	f5a50513          	addi	a0,a0,-166 # 80008270 <digits+0x230>
    8000231e:	ffffe097          	auipc	ra,0xffffe
    80002322:	21e080e7          	jalr	542(ra) # 8000053c <panic>

0000000080002326 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002326:	7179                	addi	sp,sp,-48
    80002328:	f406                	sd	ra,40(sp)
    8000232a:	f022                	sd	s0,32(sp)
    8000232c:	ec26                	sd	s1,24(sp)
    8000232e:	e84a                	sd	s2,16(sp)
    80002330:	e44e                	sd	s3,8(sp)
    80002332:	1800                	addi	s0,sp,48
    80002334:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002336:	0000f497          	auipc	s1,0xf
    8000233a:	c6a48493          	addi	s1,s1,-918 # 80010fa0 <proc>
    8000233e:	00015997          	auipc	s3,0x15
    80002342:	06298993          	addi	s3,s3,98 # 800173a0 <tickslock>
  {
    acquire(&p->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	88a080e7          	jalr	-1910(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    80002350:	589c                	lw	a5,48(s1)
    80002352:	01278d63          	beq	a5,s2,8000236c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	92e080e7          	jalr	-1746(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002360:	19048493          	addi	s1,s1,400
    80002364:	ff3491e3          	bne	s1,s3,80002346 <kill+0x20>
  }
  return -1;
    80002368:	557d                	li	a0,-1
    8000236a:	a829                	j	80002384 <kill+0x5e>
      p->killed = 1;
    8000236c:	4785                	li	a5,1
    8000236e:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002370:	4c98                	lw	a4,24(s1)
    80002372:	4789                	li	a5,2
    80002374:	00f70f63          	beq	a4,a5,80002392 <kill+0x6c>
      release(&p->lock);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	90c080e7          	jalr	-1780(ra) # 80000c86 <release>
      return 0;
    80002382:	4501                	li	a0,0
}
    80002384:	70a2                	ld	ra,40(sp)
    80002386:	7402                	ld	s0,32(sp)
    80002388:	64e2                	ld	s1,24(sp)
    8000238a:	6942                	ld	s2,16(sp)
    8000238c:	69a2                	ld	s3,8(sp)
    8000238e:	6145                	addi	sp,sp,48
    80002390:	8082                	ret
        p->state = RUNNABLE;
    80002392:	478d                	li	a5,3
    80002394:	cc9c                	sw	a5,24(s1)
    80002396:	b7cd                	j	80002378 <kill+0x52>

0000000080002398 <setkilled>:

void setkilled(struct proc *p)
{
    80002398:	1101                	addi	sp,sp,-32
    8000239a:	ec06                	sd	ra,24(sp)
    8000239c:	e822                	sd	s0,16(sp)
    8000239e:	e426                	sd	s1,8(sp)
    800023a0:	1000                	addi	s0,sp,32
    800023a2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	82e080e7          	jalr	-2002(ra) # 80000bd2 <acquire>
  p->killed = 1;
    800023ac:	4785                	li	a5,1
    800023ae:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	8d4080e7          	jalr	-1836(ra) # 80000c86 <release>
}
    800023ba:	60e2                	ld	ra,24(sp)
    800023bc:	6442                	ld	s0,16(sp)
    800023be:	64a2                	ld	s1,8(sp)
    800023c0:	6105                	addi	sp,sp,32
    800023c2:	8082                	ret

00000000800023c4 <killed>:

int killed(struct proc *p)
{
    800023c4:	1101                	addi	sp,sp,-32
    800023c6:	ec06                	sd	ra,24(sp)
    800023c8:	e822                	sd	s0,16(sp)
    800023ca:	e426                	sd	s1,8(sp)
    800023cc:	e04a                	sd	s2,0(sp)
    800023ce:	1000                	addi	s0,sp,32
    800023d0:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	800080e7          	jalr	-2048(ra) # 80000bd2 <acquire>
  k = p->killed;
    800023da:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8a6080e7          	jalr	-1882(ra) # 80000c86 <release>
  return k;
}
    800023e8:	854a                	mv	a0,s2
    800023ea:	60e2                	ld	ra,24(sp)
    800023ec:	6442                	ld	s0,16(sp)
    800023ee:	64a2                	ld	s1,8(sp)
    800023f0:	6902                	ld	s2,0(sp)
    800023f2:	6105                	addi	sp,sp,32
    800023f4:	8082                	ret

00000000800023f6 <wait>:
{
    800023f6:	715d                	addi	sp,sp,-80
    800023f8:	e486                	sd	ra,72(sp)
    800023fa:	e0a2                	sd	s0,64(sp)
    800023fc:	fc26                	sd	s1,56(sp)
    800023fe:	f84a                	sd	s2,48(sp)
    80002400:	f44e                	sd	s3,40(sp)
    80002402:	f052                	sd	s4,32(sp)
    80002404:	ec56                	sd	s5,24(sp)
    80002406:	e85a                	sd	s6,16(sp)
    80002408:	e45e                	sd	s7,8(sp)
    8000240a:	e062                	sd	s8,0(sp)
    8000240c:	0880                	addi	s0,sp,80
    8000240e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	596080e7          	jalr	1430(ra) # 800019a6 <myproc>
    80002418:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000241a:	0000e517          	auipc	a0,0xe
    8000241e:	76e50513          	addi	a0,a0,1902 # 80010b88 <wait_lock>
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	7b0080e7          	jalr	1968(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000242a:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000242c:	4a15                	li	s4,5
        havekids = 1;
    8000242e:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002430:	00015997          	auipc	s3,0x15
    80002434:	f7098993          	addi	s3,s3,-144 # 800173a0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002438:	0000ec17          	auipc	s8,0xe
    8000243c:	750c0c13          	addi	s8,s8,1872 # 80010b88 <wait_lock>
    80002440:	a0d1                	j	80002504 <wait+0x10e>
          pid = pp->pid;
    80002442:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002446:	000b0e63          	beqz	s6,80002462 <wait+0x6c>
    8000244a:	4691                	li	a3,4
    8000244c:	02c48613          	addi	a2,s1,44
    80002450:	85da                	mv	a1,s6
    80002452:	05093503          	ld	a0,80(s2)
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	210080e7          	jalr	528(ra) # 80001666 <copyout>
    8000245e:	04054163          	bltz	a0,800024a0 <wait+0xaa>
          freeproc(pp);
    80002462:	8526                	mv	a0,s1
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	75a080e7          	jalr	1882(ra) # 80001bbe <freeproc>
          release(&pp->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	818080e7          	jalr	-2024(ra) # 80000c86 <release>
          release(&wait_lock);
    80002476:	0000e517          	auipc	a0,0xe
    8000247a:	71250513          	addi	a0,a0,1810 # 80010b88 <wait_lock>
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	808080e7          	jalr	-2040(ra) # 80000c86 <release>
}
    80002486:	854e                	mv	a0,s3
    80002488:	60a6                	ld	ra,72(sp)
    8000248a:	6406                	ld	s0,64(sp)
    8000248c:	74e2                	ld	s1,56(sp)
    8000248e:	7942                	ld	s2,48(sp)
    80002490:	79a2                	ld	s3,40(sp)
    80002492:	7a02                	ld	s4,32(sp)
    80002494:	6ae2                	ld	s5,24(sp)
    80002496:	6b42                	ld	s6,16(sp)
    80002498:	6ba2                	ld	s7,8(sp)
    8000249a:	6c02                	ld	s8,0(sp)
    8000249c:	6161                	addi	sp,sp,80
    8000249e:	8082                	ret
            release(&pp->lock);
    800024a0:	8526                	mv	a0,s1
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	7e4080e7          	jalr	2020(ra) # 80000c86 <release>
            release(&wait_lock);
    800024aa:	0000e517          	auipc	a0,0xe
    800024ae:	6de50513          	addi	a0,a0,1758 # 80010b88 <wait_lock>
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	7d4080e7          	jalr	2004(ra) # 80000c86 <release>
            return -1;
    800024ba:	59fd                	li	s3,-1
    800024bc:	b7e9                	j	80002486 <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024be:	19048493          	addi	s1,s1,400
    800024c2:	03348463          	beq	s1,s3,800024ea <wait+0xf4>
      if (pp->parent == p)
    800024c6:	7c9c                	ld	a5,56(s1)
    800024c8:	ff279be3          	bne	a5,s2,800024be <wait+0xc8>
        acquire(&pp->lock);
    800024cc:	8526                	mv	a0,s1
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	704080e7          	jalr	1796(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    800024d6:	4c9c                	lw	a5,24(s1)
    800024d8:	f74785e3          	beq	a5,s4,80002442 <wait+0x4c>
        release(&pp->lock);
    800024dc:	8526                	mv	a0,s1
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	7a8080e7          	jalr	1960(ra) # 80000c86 <release>
        havekids = 1;
    800024e6:	8756                	mv	a4,s5
    800024e8:	bfd9                	j	800024be <wait+0xc8>
    if (!havekids || killed(p))
    800024ea:	c31d                	beqz	a4,80002510 <wait+0x11a>
    800024ec:	854a                	mv	a0,s2
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	ed6080e7          	jalr	-298(ra) # 800023c4 <killed>
    800024f6:	ed09                	bnez	a0,80002510 <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024f8:	85e2                	mv	a1,s8
    800024fa:	854a                	mv	a0,s2
    800024fc:	00000097          	auipc	ra,0x0
    80002500:	c14080e7          	jalr	-1004(ra) # 80002110 <sleep>
    havekids = 0;
    80002504:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002506:	0000f497          	auipc	s1,0xf
    8000250a:	a9a48493          	addi	s1,s1,-1382 # 80010fa0 <proc>
    8000250e:	bf65                	j	800024c6 <wait+0xd0>
      release(&wait_lock);
    80002510:	0000e517          	auipc	a0,0xe
    80002514:	67850513          	addi	a0,a0,1656 # 80010b88 <wait_lock>
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	76e080e7          	jalr	1902(ra) # 80000c86 <release>
      return -1;
    80002520:	59fd                	li	s3,-1
    80002522:	b795                	j	80002486 <wait+0x90>

0000000080002524 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002524:	7179                	addi	sp,sp,-48
    80002526:	f406                	sd	ra,40(sp)
    80002528:	f022                	sd	s0,32(sp)
    8000252a:	ec26                	sd	s1,24(sp)
    8000252c:	e84a                	sd	s2,16(sp)
    8000252e:	e44e                	sd	s3,8(sp)
    80002530:	e052                	sd	s4,0(sp)
    80002532:	1800                	addi	s0,sp,48
    80002534:	84aa                	mv	s1,a0
    80002536:	892e                	mv	s2,a1
    80002538:	89b2                	mv	s3,a2
    8000253a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	46a080e7          	jalr	1130(ra) # 800019a6 <myproc>
  if (user_dst)
    80002544:	c08d                	beqz	s1,80002566 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002546:	86d2                	mv	a3,s4
    80002548:	864e                	mv	a2,s3
    8000254a:	85ca                	mv	a1,s2
    8000254c:	6928                	ld	a0,80(a0)
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	118080e7          	jalr	280(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002556:	70a2                	ld	ra,40(sp)
    80002558:	7402                	ld	s0,32(sp)
    8000255a:	64e2                	ld	s1,24(sp)
    8000255c:	6942                	ld	s2,16(sp)
    8000255e:	69a2                	ld	s3,8(sp)
    80002560:	6a02                	ld	s4,0(sp)
    80002562:	6145                	addi	sp,sp,48
    80002564:	8082                	ret
    memmove((char *)dst, src, len);
    80002566:	000a061b          	sext.w	a2,s4
    8000256a:	85ce                	mv	a1,s3
    8000256c:	854a                	mv	a0,s2
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	7bc080e7          	jalr	1980(ra) # 80000d2a <memmove>
    return 0;
    80002576:	8526                	mv	a0,s1
    80002578:	bff9                	j	80002556 <either_copyout+0x32>

000000008000257a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000257a:	7179                	addi	sp,sp,-48
    8000257c:	f406                	sd	ra,40(sp)
    8000257e:	f022                	sd	s0,32(sp)
    80002580:	ec26                	sd	s1,24(sp)
    80002582:	e84a                	sd	s2,16(sp)
    80002584:	e44e                	sd	s3,8(sp)
    80002586:	e052                	sd	s4,0(sp)
    80002588:	1800                	addi	s0,sp,48
    8000258a:	892a                	mv	s2,a0
    8000258c:	84ae                	mv	s1,a1
    8000258e:	89b2                	mv	s3,a2
    80002590:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	414080e7          	jalr	1044(ra) # 800019a6 <myproc>
  if (user_src)
    8000259a:	c08d                	beqz	s1,800025bc <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000259c:	86d2                	mv	a3,s4
    8000259e:	864e                	mv	a2,s3
    800025a0:	85ca                	mv	a1,s2
    800025a2:	6928                	ld	a0,80(a0)
    800025a4:	fffff097          	auipc	ra,0xfffff
    800025a8:	14e080e7          	jalr	334(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800025ac:	70a2                	ld	ra,40(sp)
    800025ae:	7402                	ld	s0,32(sp)
    800025b0:	64e2                	ld	s1,24(sp)
    800025b2:	6942                	ld	s2,16(sp)
    800025b4:	69a2                	ld	s3,8(sp)
    800025b6:	6a02                	ld	s4,0(sp)
    800025b8:	6145                	addi	sp,sp,48
    800025ba:	8082                	ret
    memmove(dst, (char *)src, len);
    800025bc:	000a061b          	sext.w	a2,s4
    800025c0:	85ce                	mv	a1,s3
    800025c2:	854a                	mv	a0,s2
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	766080e7          	jalr	1894(ra) # 80000d2a <memmove>
    return 0;
    800025cc:	8526                	mv	a0,s1
    800025ce:	bff9                	j	800025ac <either_copyin+0x32>

00000000800025d0 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800025d0:	715d                	addi	sp,sp,-80
    800025d2:	e486                	sd	ra,72(sp)
    800025d4:	e0a2                	sd	s0,64(sp)
    800025d6:	fc26                	sd	s1,56(sp)
    800025d8:	f84a                	sd	s2,48(sp)
    800025da:	f44e                	sd	s3,40(sp)
    800025dc:	f052                	sd	s4,32(sp)
    800025de:	ec56                	sd	s5,24(sp)
    800025e0:	e85a                	sd	s6,16(sp)
    800025e2:	e45e                	sd	s7,8(sp)
    800025e4:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800025e6:	00006517          	auipc	a0,0x6
    800025ea:	ae250513          	addi	a0,a0,-1310 # 800080c8 <digits+0x88>
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	f98080e7          	jalr	-104(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025f6:	0000f497          	auipc	s1,0xf
    800025fa:	b0248493          	addi	s1,s1,-1278 # 800110f8 <proc+0x158>
    800025fe:	00015917          	auipc	s2,0x15
    80002602:	efa90913          	addi	s2,s2,-262 # 800174f8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002606:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002608:	00006997          	auipc	s3,0x6
    8000260c:	c7898993          	addi	s3,s3,-904 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002610:	00006a97          	auipc	s5,0x6
    80002614:	c78a8a93          	addi	s5,s5,-904 # 80008288 <digits+0x248>
    printf("\n");
    80002618:	00006a17          	auipc	s4,0x6
    8000261c:	ab0a0a13          	addi	s4,s4,-1360 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002620:	00006b97          	auipc	s7,0x6
    80002624:	ca8b8b93          	addi	s7,s7,-856 # 800082c8 <states.0>
    80002628:	a00d                	j	8000264a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000262a:	ed86a583          	lw	a1,-296(a3)
    8000262e:	8556                	mv	a0,s5
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	f56080e7          	jalr	-170(ra) # 80000586 <printf>
    printf("\n");
    80002638:	8552                	mv	a0,s4
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	f4c080e7          	jalr	-180(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002642:	19048493          	addi	s1,s1,400
    80002646:	03248263          	beq	s1,s2,8000266a <procdump+0x9a>
    if (p->state == UNUSED)
    8000264a:	86a6                	mv	a3,s1
    8000264c:	ec04a783          	lw	a5,-320(s1)
    80002650:	dbed                	beqz	a5,80002642 <procdump+0x72>
      state = "???";
    80002652:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002654:	fcfb6be3          	bltu	s6,a5,8000262a <procdump+0x5a>
    80002658:	02079713          	slli	a4,a5,0x20
    8000265c:	01d75793          	srli	a5,a4,0x1d
    80002660:	97de                	add	a5,a5,s7
    80002662:	6390                	ld	a2,0(a5)
    80002664:	f279                	bnez	a2,8000262a <procdump+0x5a>
      state = "???";
    80002666:	864e                	mv	a2,s3
    80002668:	b7c9                	j	8000262a <procdump+0x5a>
  }
}
    8000266a:	60a6                	ld	ra,72(sp)
    8000266c:	6406                	ld	s0,64(sp)
    8000266e:	74e2                	ld	s1,56(sp)
    80002670:	7942                	ld	s2,48(sp)
    80002672:	79a2                	ld	s3,40(sp)
    80002674:	7a02                	ld	s4,32(sp)
    80002676:	6ae2                	ld	s5,24(sp)
    80002678:	6b42                	ld	s6,16(sp)
    8000267a:	6ba2                	ld	s7,8(sp)
    8000267c:	6161                	addi	sp,sp,80
    8000267e:	8082                	ret

0000000080002680 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002680:	711d                	addi	sp,sp,-96
    80002682:	ec86                	sd	ra,88(sp)
    80002684:	e8a2                	sd	s0,80(sp)
    80002686:	e4a6                	sd	s1,72(sp)
    80002688:	e0ca                	sd	s2,64(sp)
    8000268a:	fc4e                	sd	s3,56(sp)
    8000268c:	f852                	sd	s4,48(sp)
    8000268e:	f456                	sd	s5,40(sp)
    80002690:	f05a                	sd	s6,32(sp)
    80002692:	ec5e                	sd	s7,24(sp)
    80002694:	e862                	sd	s8,16(sp)
    80002696:	e466                	sd	s9,8(sp)
    80002698:	e06a                	sd	s10,0(sp)
    8000269a:	1080                	addi	s0,sp,96
    8000269c:	8b2a                	mv	s6,a0
    8000269e:	8bae                	mv	s7,a1
    800026a0:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800026a2:	fffff097          	auipc	ra,0xfffff
    800026a6:	304080e7          	jalr	772(ra) # 800019a6 <myproc>
    800026aa:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800026ac:	0000e517          	auipc	a0,0xe
    800026b0:	4dc50513          	addi	a0,a0,1244 # 80010b88 <wait_lock>
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	51e080e7          	jalr	1310(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800026bc:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800026be:	4a15                	li	s4,5
        havekids = 1;
    800026c0:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800026c2:	00015997          	auipc	s3,0x15
    800026c6:	cde98993          	addi	s3,s3,-802 # 800173a0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026ca:	0000ed17          	auipc	s10,0xe
    800026ce:	4bed0d13          	addi	s10,s10,1214 # 80010b88 <wait_lock>
    800026d2:	a8e9                	j	800027ac <waitx+0x12c>
          pid = np->pid;
    800026d4:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800026d8:	1684a783          	lw	a5,360(s1)
    800026dc:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800026e0:	16c4a703          	lw	a4,364(s1)
    800026e4:	9f3d                	addw	a4,a4,a5
    800026e6:	1704a783          	lw	a5,368(s1)
    800026ea:	9f99                	subw	a5,a5,a4
    800026ec:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026f0:	000b0e63          	beqz	s6,8000270c <waitx+0x8c>
    800026f4:	4691                	li	a3,4
    800026f6:	02c48613          	addi	a2,s1,44
    800026fa:	85da                	mv	a1,s6
    800026fc:	05093503          	ld	a0,80(s2)
    80002700:	fffff097          	auipc	ra,0xfffff
    80002704:	f66080e7          	jalr	-154(ra) # 80001666 <copyout>
    80002708:	04054363          	bltz	a0,8000274e <waitx+0xce>
          freeproc(np);
    8000270c:	8526                	mv	a0,s1
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	4b0080e7          	jalr	1200(ra) # 80001bbe <freeproc>
          release(&np->lock);
    80002716:	8526                	mv	a0,s1
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	56e080e7          	jalr	1390(ra) # 80000c86 <release>
          release(&wait_lock);
    80002720:	0000e517          	auipc	a0,0xe
    80002724:	46850513          	addi	a0,a0,1128 # 80010b88 <wait_lock>
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	55e080e7          	jalr	1374(ra) # 80000c86 <release>
  }
}
    80002730:	854e                	mv	a0,s3
    80002732:	60e6                	ld	ra,88(sp)
    80002734:	6446                	ld	s0,80(sp)
    80002736:	64a6                	ld	s1,72(sp)
    80002738:	6906                	ld	s2,64(sp)
    8000273a:	79e2                	ld	s3,56(sp)
    8000273c:	7a42                	ld	s4,48(sp)
    8000273e:	7aa2                	ld	s5,40(sp)
    80002740:	7b02                	ld	s6,32(sp)
    80002742:	6be2                	ld	s7,24(sp)
    80002744:	6c42                	ld	s8,16(sp)
    80002746:	6ca2                	ld	s9,8(sp)
    80002748:	6d02                	ld	s10,0(sp)
    8000274a:	6125                	addi	sp,sp,96
    8000274c:	8082                	ret
            release(&np->lock);
    8000274e:	8526                	mv	a0,s1
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	536080e7          	jalr	1334(ra) # 80000c86 <release>
            release(&wait_lock);
    80002758:	0000e517          	auipc	a0,0xe
    8000275c:	43050513          	addi	a0,a0,1072 # 80010b88 <wait_lock>
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	526080e7          	jalr	1318(ra) # 80000c86 <release>
            return -1;
    80002768:	59fd                	li	s3,-1
    8000276a:	b7d9                	j	80002730 <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    8000276c:	19048493          	addi	s1,s1,400
    80002770:	03348463          	beq	s1,s3,80002798 <waitx+0x118>
      if (np->parent == p)
    80002774:	7c9c                	ld	a5,56(s1)
    80002776:	ff279be3          	bne	a5,s2,8000276c <waitx+0xec>
        acquire(&np->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	456080e7          	jalr	1110(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    80002784:	4c9c                	lw	a5,24(s1)
    80002786:	f54787e3          	beq	a5,s4,800026d4 <waitx+0x54>
        release(&np->lock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	4fa080e7          	jalr	1274(ra) # 80000c86 <release>
        havekids = 1;
    80002794:	8756                	mv	a4,s5
    80002796:	bfd9                	j	8000276c <waitx+0xec>
    if (!havekids || p->killed)
    80002798:	c305                	beqz	a4,800027b8 <waitx+0x138>
    8000279a:	02892783          	lw	a5,40(s2)
    8000279e:	ef89                	bnez	a5,800027b8 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027a0:	85ea                	mv	a1,s10
    800027a2:	854a                	mv	a0,s2
    800027a4:	00000097          	auipc	ra,0x0
    800027a8:	96c080e7          	jalr	-1684(ra) # 80002110 <sleep>
    havekids = 0;
    800027ac:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800027ae:	0000e497          	auipc	s1,0xe
    800027b2:	7f248493          	addi	s1,s1,2034 # 80010fa0 <proc>
    800027b6:	bf7d                	j	80002774 <waitx+0xf4>
      release(&wait_lock);
    800027b8:	0000e517          	auipc	a0,0xe
    800027bc:	3d050513          	addi	a0,a0,976 # 80010b88 <wait_lock>
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	4c6080e7          	jalr	1222(ra) # 80000c86 <release>
      return -1;
    800027c8:	59fd                	li	s3,-1
    800027ca:	b79d                	j	80002730 <waitx+0xb0>

00000000800027cc <update_time>:

void update_time()
{
    800027cc:	7179                	addi	sp,sp,-48
    800027ce:	f406                	sd	ra,40(sp)
    800027d0:	f022                	sd	s0,32(sp)
    800027d2:	ec26                	sd	s1,24(sp)
    800027d4:	e84a                	sd	s2,16(sp)
    800027d6:	e44e                	sd	s3,8(sp)
    800027d8:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800027da:	0000e497          	auipc	s1,0xe
    800027de:	7c648493          	addi	s1,s1,1990 # 80010fa0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800027e2:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800027e4:	00015917          	auipc	s2,0x15
    800027e8:	bbc90913          	addi	s2,s2,-1092 # 800173a0 <tickslock>
    800027ec:	a811                	j	80002800 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    800027ee:	8526                	mv	a0,s1
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	496080e7          	jalr	1174(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027f8:	19048493          	addi	s1,s1,400
    800027fc:	03248063          	beq	s1,s2,8000281c <update_time+0x50>
    acquire(&p->lock);
    80002800:	8526                	mv	a0,s1
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	3d0080e7          	jalr	976(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    8000280a:	4c9c                	lw	a5,24(s1)
    8000280c:	ff3791e3          	bne	a5,s3,800027ee <update_time+0x22>
      p->rtime++;
    80002810:	1684a783          	lw	a5,360(s1)
    80002814:	2785                	addiw	a5,a5,1
    80002816:	16f4a423          	sw	a5,360(s1)
    8000281a:	bfd1                	j	800027ee <update_time+0x22>
  }
    8000281c:	70a2                	ld	ra,40(sp)
    8000281e:	7402                	ld	s0,32(sp)
    80002820:	64e2                	ld	s1,24(sp)
    80002822:	6942                	ld	s2,16(sp)
    80002824:	69a2                	ld	s3,8(sp)
    80002826:	6145                	addi	sp,sp,48
    80002828:	8082                	ret

000000008000282a <swtch>:
    8000282a:	00153023          	sd	ra,0(a0)
    8000282e:	00253423          	sd	sp,8(a0)
    80002832:	e900                	sd	s0,16(a0)
    80002834:	ed04                	sd	s1,24(a0)
    80002836:	03253023          	sd	s2,32(a0)
    8000283a:	03353423          	sd	s3,40(a0)
    8000283e:	03453823          	sd	s4,48(a0)
    80002842:	03553c23          	sd	s5,56(a0)
    80002846:	05653023          	sd	s6,64(a0)
    8000284a:	05753423          	sd	s7,72(a0)
    8000284e:	05853823          	sd	s8,80(a0)
    80002852:	05953c23          	sd	s9,88(a0)
    80002856:	07a53023          	sd	s10,96(a0)
    8000285a:	07b53423          	sd	s11,104(a0)
    8000285e:	0005b083          	ld	ra,0(a1)
    80002862:	0085b103          	ld	sp,8(a1)
    80002866:	6980                	ld	s0,16(a1)
    80002868:	6d84                	ld	s1,24(a1)
    8000286a:	0205b903          	ld	s2,32(a1)
    8000286e:	0285b983          	ld	s3,40(a1)
    80002872:	0305ba03          	ld	s4,48(a1)
    80002876:	0385ba83          	ld	s5,56(a1)
    8000287a:	0405bb03          	ld	s6,64(a1)
    8000287e:	0485bb83          	ld	s7,72(a1)
    80002882:	0505bc03          	ld	s8,80(a1)
    80002886:	0585bc83          	ld	s9,88(a1)
    8000288a:	0605bd03          	ld	s10,96(a1)
    8000288e:	0685bd83          	ld	s11,104(a1)
    80002892:	8082                	ret

0000000080002894 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002894:	1141                	addi	sp,sp,-16
    80002896:	e406                	sd	ra,8(sp)
    80002898:	e022                	sd	s0,0(sp)
    8000289a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000289c:	00006597          	auipc	a1,0x6
    800028a0:	a5c58593          	addi	a1,a1,-1444 # 800082f8 <states.0+0x30>
    800028a4:	00015517          	auipc	a0,0x15
    800028a8:	afc50513          	addi	a0,a0,-1284 # 800173a0 <tickslock>
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	296080e7          	jalr	662(ra) # 80000b42 <initlock>
}
    800028b4:	60a2                	ld	ra,8(sp)
    800028b6:	6402                	ld	s0,0(sp)
    800028b8:	0141                	addi	sp,sp,16
    800028ba:	8082                	ret

00000000800028bc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800028bc:	1141                	addi	sp,sp,-16
    800028be:	e422                	sd	s0,8(sp)
    800028c0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028c2:	00003797          	auipc	a5,0x3
    800028c6:	61e78793          	addi	a5,a5,1566 # 80005ee0 <kernelvec>
    800028ca:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028ce:	6422                	ld	s0,8(sp)
    800028d0:	0141                	addi	sp,sp,16
    800028d2:	8082                	ret

00000000800028d4 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800028d4:	1141                	addi	sp,sp,-16
    800028d6:	e406                	sd	ra,8(sp)
    800028d8:	e022                	sd	s0,0(sp)
    800028da:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028dc:	fffff097          	auipc	ra,0xfffff
    800028e0:	0ca080e7          	jalr	202(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028e8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ea:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800028ee:	00004697          	auipc	a3,0x4
    800028f2:	71268693          	addi	a3,a3,1810 # 80007000 <_trampoline>
    800028f6:	00004717          	auipc	a4,0x4
    800028fa:	70a70713          	addi	a4,a4,1802 # 80007000 <_trampoline>
    800028fe:	8f15                	sub	a4,a4,a3
    80002900:	040007b7          	lui	a5,0x4000
    80002904:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002906:	07b2                	slli	a5,a5,0xc
    80002908:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000290a:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000290e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002910:	18002673          	csrr	a2,satp
    80002914:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002916:	6d30                	ld	a2,88(a0)
    80002918:	6138                	ld	a4,64(a0)
    8000291a:	6585                	lui	a1,0x1
    8000291c:	972e                	add	a4,a4,a1
    8000291e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002920:	6d38                	ld	a4,88(a0)
    80002922:	00000617          	auipc	a2,0x0
    80002926:	14260613          	addi	a2,a2,322 # 80002a64 <usertrap>
    8000292a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    8000292c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000292e:	8612                	mv	a2,tp
    80002930:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002932:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002936:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000293a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000293e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002942:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002944:	6f18                	ld	a4,24(a4)
    80002946:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000294a:	6928                	ld	a0,80(a0)
    8000294c:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000294e:	00004717          	auipc	a4,0x4
    80002952:	74e70713          	addi	a4,a4,1870 # 8000709c <userret>
    80002956:	8f15                	sub	a4,a4,a3
    80002958:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000295a:	577d                	li	a4,-1
    8000295c:	177e                	slli	a4,a4,0x3f
    8000295e:	8d59                	or	a0,a0,a4
    80002960:	9782                	jalr	a5
}
    80002962:	60a2                	ld	ra,8(sp)
    80002964:	6402                	ld	s0,0(sp)
    80002966:	0141                	addi	sp,sp,16
    80002968:	8082                	ret

000000008000296a <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    8000296a:	1101                	addi	sp,sp,-32
    8000296c:	ec06                	sd	ra,24(sp)
    8000296e:	e822                	sd	s0,16(sp)
    80002970:	e426                	sd	s1,8(sp)
    80002972:	e04a                	sd	s2,0(sp)
    80002974:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002976:	00015917          	auipc	s2,0x15
    8000297a:	a2a90913          	addi	s2,s2,-1494 # 800173a0 <tickslock>
    8000297e:	854a                	mv	a0,s2
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	252080e7          	jalr	594(ra) # 80000bd2 <acquire>
  ticks++;
    80002988:	00006497          	auipc	s1,0x6
    8000298c:	f7848493          	addi	s1,s1,-136 # 80008900 <ticks>
    80002990:	409c                	lw	a5,0(s1)
    80002992:	2785                	addiw	a5,a5,1
    80002994:	c09c                	sw	a5,0(s1)
  update_time();
    80002996:	00000097          	auipc	ra,0x0
    8000299a:	e36080e7          	jalr	-458(ra) # 800027cc <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    8000299e:	8526                	mv	a0,s1
    800029a0:	fffff097          	auipc	ra,0xfffff
    800029a4:	7d4080e7          	jalr	2004(ra) # 80002174 <wakeup>
  release(&tickslock);
    800029a8:	854a                	mv	a0,s2
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	2dc080e7          	jalr	732(ra) # 80000c86 <release>
}
    800029b2:	60e2                	ld	ra,24(sp)
    800029b4:	6442                	ld	s0,16(sp)
    800029b6:	64a2                	ld	s1,8(sp)
    800029b8:	6902                	ld	s2,0(sp)
    800029ba:	6105                	addi	sp,sp,32
    800029bc:	8082                	ret

00000000800029be <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029be:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    800029c2:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    800029c4:	0807df63          	bgez	a5,80002a62 <devintr+0xa4>
{
    800029c8:	1101                	addi	sp,sp,-32
    800029ca:	ec06                	sd	ra,24(sp)
    800029cc:	e822                	sd	s0,16(sp)
    800029ce:	e426                	sd	s1,8(sp)
    800029d0:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    800029d2:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    800029d6:	46a5                	li	a3,9
    800029d8:	00d70d63          	beq	a4,a3,800029f2 <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    800029dc:	577d                	li	a4,-1
    800029de:	177e                	slli	a4,a4,0x3f
    800029e0:	0705                	addi	a4,a4,1
    return 0;
    800029e2:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    800029e4:	04e78e63          	beq	a5,a4,80002a40 <devintr+0x82>
  }
}
    800029e8:	60e2                	ld	ra,24(sp)
    800029ea:	6442                	ld	s0,16(sp)
    800029ec:	64a2                	ld	s1,8(sp)
    800029ee:	6105                	addi	sp,sp,32
    800029f0:	8082                	ret
    int irq = plic_claim();
    800029f2:	00003097          	auipc	ra,0x3
    800029f6:	5f6080e7          	jalr	1526(ra) # 80005fe8 <plic_claim>
    800029fa:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    800029fc:	47a9                	li	a5,10
    800029fe:	02f50763          	beq	a0,a5,80002a2c <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    80002a02:	4785                	li	a5,1
    80002a04:	02f50963          	beq	a0,a5,80002a36 <devintr+0x78>
    return 1;
    80002a08:	4505                	li	a0,1
    else if (irq)
    80002a0a:	dcf9                	beqz	s1,800029e8 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a0c:	85a6                	mv	a1,s1
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	8f250513          	addi	a0,a0,-1806 # 80008300 <states.0+0x38>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b70080e7          	jalr	-1168(ra) # 80000586 <printf>
      plic_complete(irq);
    80002a1e:	8526                	mv	a0,s1
    80002a20:	00003097          	auipc	ra,0x3
    80002a24:	5ec080e7          	jalr	1516(ra) # 8000600c <plic_complete>
    return 1;
    80002a28:	4505                	li	a0,1
    80002a2a:	bf7d                	j	800029e8 <devintr+0x2a>
      uartintr();
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	f68080e7          	jalr	-152(ra) # 80000994 <uartintr>
    if (irq)
    80002a34:	b7ed                	j	80002a1e <devintr+0x60>
      virtio_disk_intr();
    80002a36:	00004097          	auipc	ra,0x4
    80002a3a:	a9c080e7          	jalr	-1380(ra) # 800064d2 <virtio_disk_intr>
    if (irq)
    80002a3e:	b7c5                	j	80002a1e <devintr+0x60>
    if (cpuid() == 0)
    80002a40:	fffff097          	auipc	ra,0xfffff
    80002a44:	f3a080e7          	jalr	-198(ra) # 8000197a <cpuid>
    80002a48:	c901                	beqz	a0,80002a58 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a4a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a4e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a50:	14479073          	csrw	sip,a5
    return 2;
    80002a54:	4509                	li	a0,2
    80002a56:	bf49                	j	800029e8 <devintr+0x2a>
      clockintr();
    80002a58:	00000097          	auipc	ra,0x0
    80002a5c:	f12080e7          	jalr	-238(ra) # 8000296a <clockintr>
    80002a60:	b7ed                	j	80002a4a <devintr+0x8c>
}
    80002a62:	8082                	ret

0000000080002a64 <usertrap>:
{
    80002a64:	1101                	addi	sp,sp,-32
    80002a66:	ec06                	sd	ra,24(sp)
    80002a68:	e822                	sd	s0,16(sp)
    80002a6a:	e426                	sd	s1,8(sp)
    80002a6c:	e04a                	sd	s2,0(sp)
    80002a6e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a70:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002a74:	1007f793          	andi	a5,a5,256
    80002a78:	e3b1                	bnez	a5,80002abc <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a7a:	00003797          	auipc	a5,0x3
    80002a7e:	46678793          	addi	a5,a5,1126 # 80005ee0 <kernelvec>
    80002a82:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	f20080e7          	jalr	-224(ra) # 800019a6 <myproc>
    80002a8e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a90:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a92:	14102773          	csrr	a4,sepc
    80002a96:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a98:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a9c:	47a1                	li	a5,8
    80002a9e:	02f70763          	beq	a4,a5,80002acc <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002aa2:	00000097          	auipc	ra,0x0
    80002aa6:	f1c080e7          	jalr	-228(ra) # 800029be <devintr>
    80002aaa:	892a                	mv	s2,a0
    80002aac:	c92d                	beqz	a0,80002b1e <usertrap+0xba>
  if (killed(p))
    80002aae:	8526                	mv	a0,s1
    80002ab0:	00000097          	auipc	ra,0x0
    80002ab4:	914080e7          	jalr	-1772(ra) # 800023c4 <killed>
    80002ab8:	c555                	beqz	a0,80002b64 <usertrap+0x100>
    80002aba:	a045                	j	80002b5a <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002abc:	00006517          	auipc	a0,0x6
    80002ac0:	86450513          	addi	a0,a0,-1948 # 80008320 <states.0+0x58>
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	a78080e7          	jalr	-1416(ra) # 8000053c <panic>
    if (killed(p))
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	8f8080e7          	jalr	-1800(ra) # 800023c4 <killed>
    80002ad4:	ed1d                	bnez	a0,80002b12 <usertrap+0xae>
    p->trapframe->epc += 4;
    80002ad6:	6cb8                	ld	a4,88(s1)
    80002ad8:	6f1c                	ld	a5,24(a4)
    80002ada:	0791                	addi	a5,a5,4
    80002adc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ade:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ae2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae6:	10079073          	csrw	sstatus,a5
    syscall();
    80002aea:	00000097          	auipc	ra,0x0
    80002aee:	346080e7          	jalr	838(ra) # 80002e30 <syscall>
  if (killed(p))
    80002af2:	8526                	mv	a0,s1
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	8d0080e7          	jalr	-1840(ra) # 800023c4 <killed>
    80002afc:	ed31                	bnez	a0,80002b58 <usertrap+0xf4>
  usertrapret();
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	dd6080e7          	jalr	-554(ra) # 800028d4 <usertrapret>
}
    80002b06:	60e2                	ld	ra,24(sp)
    80002b08:	6442                	ld	s0,16(sp)
    80002b0a:	64a2                	ld	s1,8(sp)
    80002b0c:	6902                	ld	s2,0(sp)
    80002b0e:	6105                	addi	sp,sp,32
    80002b10:	8082                	ret
      exit(-1);
    80002b12:	557d                	li	a0,-1
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	730080e7          	jalr	1840(ra) # 80002244 <exit>
    80002b1c:	bf6d                	j	80002ad6 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b1e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b22:	5890                	lw	a2,48(s1)
    80002b24:	00006517          	auipc	a0,0x6
    80002b28:	81c50513          	addi	a0,a0,-2020 # 80008340 <states.0+0x78>
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	a5a080e7          	jalr	-1446(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b34:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b38:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b3c:	00006517          	auipc	a0,0x6
    80002b40:	83450513          	addi	a0,a0,-1996 # 80008370 <states.0+0xa8>
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	a42080e7          	jalr	-1470(ra) # 80000586 <printf>
    setkilled(p);
    80002b4c:	8526                	mv	a0,s1
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	84a080e7          	jalr	-1974(ra) # 80002398 <setkilled>
    80002b56:	bf71                	j	80002af2 <usertrap+0x8e>
  if (killed(p))
    80002b58:	4901                	li	s2,0
    exit(-1);
    80002b5a:	557d                	li	a0,-1
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	6e8080e7          	jalr	1768(ra) # 80002244 <exit>
  if (which_dev == 2)
    80002b64:	4789                	li	a5,2
    80002b66:	f8f91ce3          	bne	s2,a5,80002afe <usertrap+0x9a>
      p->now_ticks+=1 ; 
    80002b6a:	17c4a783          	lw	a5,380(s1)
    80002b6e:	2785                	addiw	a5,a5,1
    80002b70:	0007871b          	sext.w	a4,a5
    80002b74:	16f4ae23          	sw	a5,380(s1)
      if( p-> ticks > 0 && p->now_ticks >= p->ticks && !p->is_sigalarm)
    80002b78:	1784a783          	lw	a5,376(s1)
    80002b7c:	04f05663          	blez	a5,80002bc8 <usertrap+0x164>
    80002b80:	04f74463          	blt	a4,a5,80002bc8 <usertrap+0x164>
    80002b84:	1744a783          	lw	a5,372(s1)
    80002b88:	e3a1                	bnez	a5,80002bc8 <usertrap+0x164>
        p->now_ticks = 0;
    80002b8a:	1604ae23          	sw	zero,380(s1)
        p->is_sigalarm = 1;
    80002b8e:	4785                	li	a5,1
    80002b90:	16f4aa23          	sw	a5,372(s1)
        *(p->backup_trapframe) =*( p->trapframe);
    80002b94:	6cb4                	ld	a3,88(s1)
    80002b96:	87b6                	mv	a5,a3
    80002b98:	1884b703          	ld	a4,392(s1)
    80002b9c:	12068693          	addi	a3,a3,288
    80002ba0:	0007b803          	ld	a6,0(a5)
    80002ba4:	6788                	ld	a0,8(a5)
    80002ba6:	6b8c                	ld	a1,16(a5)
    80002ba8:	6f90                	ld	a2,24(a5)
    80002baa:	01073023          	sd	a6,0(a4)
    80002bae:	e708                	sd	a0,8(a4)
    80002bb0:	eb0c                	sd	a1,16(a4)
    80002bb2:	ef10                	sd	a2,24(a4)
    80002bb4:	02078793          	addi	a5,a5,32
    80002bb8:	02070713          	addi	a4,a4,32
    80002bbc:	fed792e3          	bne	a5,a3,80002ba0 <usertrap+0x13c>
        p->trapframe->epc = p->handler;
    80002bc0:	6cbc                	ld	a5,88(s1)
    80002bc2:	1804b703          	ld	a4,384(s1)
    80002bc6:	ef98                	sd	a4,24(a5)
      yield();
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	50c080e7          	jalr	1292(ra) # 800020d4 <yield>
    80002bd0:	b73d                	j	80002afe <usertrap+0x9a>

0000000080002bd2 <kerneltrap>:
{
    80002bd2:	7179                	addi	sp,sp,-48
    80002bd4:	f406                	sd	ra,40(sp)
    80002bd6:	f022                	sd	s0,32(sp)
    80002bd8:	ec26                	sd	s1,24(sp)
    80002bda:	e84a                	sd	s2,16(sp)
    80002bdc:	e44e                	sd	s3,8(sp)
    80002bde:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be8:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002bec:	1004f793          	andi	a5,s1,256
    80002bf0:	cb85                	beqz	a5,80002c20 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bf2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bf6:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002bf8:	ef85                	bnez	a5,80002c30 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	dc4080e7          	jalr	-572(ra) # 800029be <devintr>
    80002c02:	cd1d                	beqz	a0,80002c40 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c04:	4789                	li	a5,2
    80002c06:	06f50a63          	beq	a0,a5,80002c7a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c0a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c0e:	10049073          	csrw	sstatus,s1
}
    80002c12:	70a2                	ld	ra,40(sp)
    80002c14:	7402                	ld	s0,32(sp)
    80002c16:	64e2                	ld	s1,24(sp)
    80002c18:	6942                	ld	s2,16(sp)
    80002c1a:	69a2                	ld	s3,8(sp)
    80002c1c:	6145                	addi	sp,sp,48
    80002c1e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c20:	00005517          	auipc	a0,0x5
    80002c24:	77050513          	addi	a0,a0,1904 # 80008390 <states.0+0xc8>
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	914080e7          	jalr	-1772(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002c30:	00005517          	auipc	a0,0x5
    80002c34:	78850513          	addi	a0,a0,1928 # 800083b8 <states.0+0xf0>
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	904080e7          	jalr	-1788(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002c40:	85ce                	mv	a1,s3
    80002c42:	00005517          	auipc	a0,0x5
    80002c46:	79650513          	addi	a0,a0,1942 # 800083d8 <states.0+0x110>
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	93c080e7          	jalr	-1732(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c52:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c56:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c5a:	00005517          	auipc	a0,0x5
    80002c5e:	78e50513          	addi	a0,a0,1934 # 800083e8 <states.0+0x120>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	924080e7          	jalr	-1756(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002c6a:	00005517          	auipc	a0,0x5
    80002c6e:	79650513          	addi	a0,a0,1942 # 80008400 <states.0+0x138>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	8ca080e7          	jalr	-1846(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	d2c080e7          	jalr	-724(ra) # 800019a6 <myproc>
    80002c82:	d541                	beqz	a0,80002c0a <kerneltrap+0x38>
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	d22080e7          	jalr	-734(ra) # 800019a6 <myproc>
    80002c8c:	4d18                	lw	a4,24(a0)
    80002c8e:	4791                	li	a5,4
    80002c90:	f6f71de3          	bne	a4,a5,80002c0a <kerneltrap+0x38>
    yield();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	440080e7          	jalr	1088(ra) # 800020d4 <yield>
    80002c9c:	b7bd                	j	80002c0a <kerneltrap+0x38>

0000000080002c9e <sys_getreadcount>:
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}
uint64 sys_getreadcount(void)
{
    80002c9e:	1141                	addi	sp,sp,-16
    80002ca0:	e422                	sd	s0,8(sp)
    80002ca2:	0800                	addi	s0,sp,16
  return READCOUNT; 
}
    80002ca4:	00006517          	auipc	a0,0x6
    80002ca8:	c6453503          	ld	a0,-924(a0) # 80008908 <READCOUNT>
    80002cac:	6422                	ld	s0,8(sp)
    80002cae:	0141                	addi	sp,sp,16
    80002cb0:	8082                	ret

0000000080002cb2 <argraw>:
{
    80002cb2:	1101                	addi	sp,sp,-32
    80002cb4:	ec06                	sd	ra,24(sp)
    80002cb6:	e822                	sd	s0,16(sp)
    80002cb8:	e426                	sd	s1,8(sp)
    80002cba:	1000                	addi	s0,sp,32
    80002cbc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	ce8080e7          	jalr	-792(ra) # 800019a6 <myproc>
  switch (n) {
    80002cc6:	4795                	li	a5,5
    80002cc8:	0497e163          	bltu	a5,s1,80002d0a <argraw+0x58>
    80002ccc:	048a                	slli	s1,s1,0x2
    80002cce:	00005717          	auipc	a4,0x5
    80002cd2:	76a70713          	addi	a4,a4,1898 # 80008438 <states.0+0x170>
    80002cd6:	94ba                	add	s1,s1,a4
    80002cd8:	409c                	lw	a5,0(s1)
    80002cda:	97ba                	add	a5,a5,a4
    80002cdc:	8782                	jr	a5
    return p->trapframe->a0;
    80002cde:	6d3c                	ld	a5,88(a0)
    80002ce0:	7ba8                	ld	a0,112(a5)
}
    80002ce2:	60e2                	ld	ra,24(sp)
    80002ce4:	6442                	ld	s0,16(sp)
    80002ce6:	64a2                	ld	s1,8(sp)
    80002ce8:	6105                	addi	sp,sp,32
    80002cea:	8082                	ret
    return p->trapframe->a1;
    80002cec:	6d3c                	ld	a5,88(a0)
    80002cee:	7fa8                	ld	a0,120(a5)
    80002cf0:	bfcd                	j	80002ce2 <argraw+0x30>
    return p->trapframe->a2;
    80002cf2:	6d3c                	ld	a5,88(a0)
    80002cf4:	63c8                	ld	a0,128(a5)
    80002cf6:	b7f5                	j	80002ce2 <argraw+0x30>
    return p->trapframe->a3;
    80002cf8:	6d3c                	ld	a5,88(a0)
    80002cfa:	67c8                	ld	a0,136(a5)
    80002cfc:	b7dd                	j	80002ce2 <argraw+0x30>
    return p->trapframe->a4;
    80002cfe:	6d3c                	ld	a5,88(a0)
    80002d00:	6bc8                	ld	a0,144(a5)
    80002d02:	b7c5                	j	80002ce2 <argraw+0x30>
    return p->trapframe->a5;
    80002d04:	6d3c                	ld	a5,88(a0)
    80002d06:	6fc8                	ld	a0,152(a5)
    80002d08:	bfe9                	j	80002ce2 <argraw+0x30>
  panic("argraw");
    80002d0a:	00005517          	auipc	a0,0x5
    80002d0e:	70650513          	addi	a0,a0,1798 # 80008410 <states.0+0x148>
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	82a080e7          	jalr	-2006(ra) # 8000053c <panic>

0000000080002d1a <fetchaddr>:
{
    80002d1a:	1101                	addi	sp,sp,-32
    80002d1c:	ec06                	sd	ra,24(sp)
    80002d1e:	e822                	sd	s0,16(sp)
    80002d20:	e426                	sd	s1,8(sp)
    80002d22:	e04a                	sd	s2,0(sp)
    80002d24:	1000                	addi	s0,sp,32
    80002d26:	84aa                	mv	s1,a0
    80002d28:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	c7c080e7          	jalr	-900(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d32:	653c                	ld	a5,72(a0)
    80002d34:	02f4f863          	bgeu	s1,a5,80002d64 <fetchaddr+0x4a>
    80002d38:	00848713          	addi	a4,s1,8
    80002d3c:	02e7e663          	bltu	a5,a4,80002d68 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d40:	46a1                	li	a3,8
    80002d42:	8626                	mv	a2,s1
    80002d44:	85ca                	mv	a1,s2
    80002d46:	6928                	ld	a0,80(a0)
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	9aa080e7          	jalr	-1622(ra) # 800016f2 <copyin>
    80002d50:	00a03533          	snez	a0,a0
    80002d54:	40a00533          	neg	a0,a0
}
    80002d58:	60e2                	ld	ra,24(sp)
    80002d5a:	6442                	ld	s0,16(sp)
    80002d5c:	64a2                	ld	s1,8(sp)
    80002d5e:	6902                	ld	s2,0(sp)
    80002d60:	6105                	addi	sp,sp,32
    80002d62:	8082                	ret
    return -1;
    80002d64:	557d                	li	a0,-1
    80002d66:	bfcd                	j	80002d58 <fetchaddr+0x3e>
    80002d68:	557d                	li	a0,-1
    80002d6a:	b7fd                	j	80002d58 <fetchaddr+0x3e>

0000000080002d6c <fetchstr>:
{
    80002d6c:	7179                	addi	sp,sp,-48
    80002d6e:	f406                	sd	ra,40(sp)
    80002d70:	f022                	sd	s0,32(sp)
    80002d72:	ec26                	sd	s1,24(sp)
    80002d74:	e84a                	sd	s2,16(sp)
    80002d76:	e44e                	sd	s3,8(sp)
    80002d78:	1800                	addi	s0,sp,48
    80002d7a:	892a                	mv	s2,a0
    80002d7c:	84ae                	mv	s1,a1
    80002d7e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d80:	fffff097          	auipc	ra,0xfffff
    80002d84:	c26080e7          	jalr	-986(ra) # 800019a6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d88:	86ce                	mv	a3,s3
    80002d8a:	864a                	mv	a2,s2
    80002d8c:	85a6                	mv	a1,s1
    80002d8e:	6928                	ld	a0,80(a0)
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	9f0080e7          	jalr	-1552(ra) # 80001780 <copyinstr>
    80002d98:	00054e63          	bltz	a0,80002db4 <fetchstr+0x48>
  return strlen(buf);
    80002d9c:	8526                	mv	a0,s1
    80002d9e:	ffffe097          	auipc	ra,0xffffe
    80002da2:	0aa080e7          	jalr	170(ra) # 80000e48 <strlen>
}
    80002da6:	70a2                	ld	ra,40(sp)
    80002da8:	7402                	ld	s0,32(sp)
    80002daa:	64e2                	ld	s1,24(sp)
    80002dac:	6942                	ld	s2,16(sp)
    80002dae:	69a2                	ld	s3,8(sp)
    80002db0:	6145                	addi	sp,sp,48
    80002db2:	8082                	ret
    return -1;
    80002db4:	557d                	li	a0,-1
    80002db6:	bfc5                	j	80002da6 <fetchstr+0x3a>

0000000080002db8 <argint>:
{
    80002db8:	1101                	addi	sp,sp,-32
    80002dba:	ec06                	sd	ra,24(sp)
    80002dbc:	e822                	sd	s0,16(sp)
    80002dbe:	e426                	sd	s1,8(sp)
    80002dc0:	1000                	addi	s0,sp,32
    80002dc2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dc4:	00000097          	auipc	ra,0x0
    80002dc8:	eee080e7          	jalr	-274(ra) # 80002cb2 <argraw>
    80002dcc:	c088                	sw	a0,0(s1)
}
    80002dce:	60e2                	ld	ra,24(sp)
    80002dd0:	6442                	ld	s0,16(sp)
    80002dd2:	64a2                	ld	s1,8(sp)
    80002dd4:	6105                	addi	sp,sp,32
    80002dd6:	8082                	ret

0000000080002dd8 <argaddr>:
{
    80002dd8:	1101                	addi	sp,sp,-32
    80002dda:	ec06                	sd	ra,24(sp)
    80002ddc:	e822                	sd	s0,16(sp)
    80002dde:	e426                	sd	s1,8(sp)
    80002de0:	1000                	addi	s0,sp,32
    80002de2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	ece080e7          	jalr	-306(ra) # 80002cb2 <argraw>
    80002dec:	e088                	sd	a0,0(s1)
}
    80002dee:	60e2                	ld	ra,24(sp)
    80002df0:	6442                	ld	s0,16(sp)
    80002df2:	64a2                	ld	s1,8(sp)
    80002df4:	6105                	addi	sp,sp,32
    80002df6:	8082                	ret

0000000080002df8 <argstr>:
{
    80002df8:	7179                	addi	sp,sp,-48
    80002dfa:	f406                	sd	ra,40(sp)
    80002dfc:	f022                	sd	s0,32(sp)
    80002dfe:	ec26                	sd	s1,24(sp)
    80002e00:	e84a                	sd	s2,16(sp)
    80002e02:	1800                	addi	s0,sp,48
    80002e04:	84ae                	mv	s1,a1
    80002e06:	8932                	mv	s2,a2
  argaddr(n, &addr);
    80002e08:	fd840593          	addi	a1,s0,-40
    80002e0c:	00000097          	auipc	ra,0x0
    80002e10:	fcc080e7          	jalr	-52(ra) # 80002dd8 <argaddr>
  return fetchstr(addr, buf, max);
    80002e14:	864a                	mv	a2,s2
    80002e16:	85a6                	mv	a1,s1
    80002e18:	fd843503          	ld	a0,-40(s0)
    80002e1c:	00000097          	auipc	ra,0x0
    80002e20:	f50080e7          	jalr	-176(ra) # 80002d6c <fetchstr>
}
    80002e24:	70a2                	ld	ra,40(sp)
    80002e26:	7402                	ld	s0,32(sp)
    80002e28:	64e2                	ld	s1,24(sp)
    80002e2a:	6942                	ld	s2,16(sp)
    80002e2c:	6145                	addi	sp,sp,48
    80002e2e:	8082                	ret

0000000080002e30 <syscall>:

};

void
syscall(void)
{
    80002e30:	1101                	addi	sp,sp,-32
    80002e32:	ec06                	sd	ra,24(sp)
    80002e34:	e822                	sd	s0,16(sp)
    80002e36:	e426                	sd	s1,8(sp)
    80002e38:	e04a                	sd	s2,0(sp)
    80002e3a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	b6a080e7          	jalr	-1174(ra) # 800019a6 <myproc>
    80002e44:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e46:	05853903          	ld	s2,88(a0)
    80002e4a:	0a893783          	ld	a5,168(s2)
    80002e4e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e52:	37fd                	addiw	a5,a5,-1
    80002e54:	4761                	li	a4,24
    80002e56:	00f76f63          	bltu	a4,a5,80002e74 <syscall+0x44>
    80002e5a:	00369713          	slli	a4,a3,0x3
    80002e5e:	00005797          	auipc	a5,0x5
    80002e62:	5f278793          	addi	a5,a5,1522 # 80008450 <syscalls>
    80002e66:	97ba                	add	a5,a5,a4
    80002e68:	639c                	ld	a5,0(a5)
    80002e6a:	c789                	beqz	a5,80002e74 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e6c:	9782                	jalr	a5
    80002e6e:	06a93823          	sd	a0,112(s2)
    80002e72:	a839                	j	80002e90 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e74:	15848613          	addi	a2,s1,344
    80002e78:	588c                	lw	a1,48(s1)
    80002e7a:	00005517          	auipc	a0,0x5
    80002e7e:	59e50513          	addi	a0,a0,1438 # 80008418 <states.0+0x150>
    80002e82:	ffffd097          	auipc	ra,0xffffd
    80002e86:	704080e7          	jalr	1796(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e8a:	6cbc                	ld	a5,88(s1)
    80002e8c:	577d                	li	a4,-1
    80002e8e:	fbb8                	sd	a4,112(a5)
  }
}
    80002e90:	60e2                	ld	ra,24(sp)
    80002e92:	6442                	ld	s0,16(sp)
    80002e94:	64a2                	ld	s1,8(sp)
    80002e96:	6902                	ld	s2,0(sp)
    80002e98:	6105                	addi	sp,sp,32
    80002e9a:	8082                	ret

0000000080002e9c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e9c:	1101                	addi	sp,sp,-32
    80002e9e:	ec06                	sd	ra,24(sp)
    80002ea0:	e822                	sd	s0,16(sp)
    80002ea2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ea4:	fec40593          	addi	a1,s0,-20
    80002ea8:	4501                	li	a0,0
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	f0e080e7          	jalr	-242(ra) # 80002db8 <argint>
  exit(n);
    80002eb2:	fec42503          	lw	a0,-20(s0)
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	38e080e7          	jalr	910(ra) # 80002244 <exit>
  return 0; // not reached
}
    80002ebe:	4501                	li	a0,0
    80002ec0:	60e2                	ld	ra,24(sp)
    80002ec2:	6442                	ld	s0,16(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret

0000000080002ec8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ec8:	1141                	addi	sp,sp,-16
    80002eca:	e406                	sd	ra,8(sp)
    80002ecc:	e022                	sd	s0,0(sp)
    80002ece:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	ad6080e7          	jalr	-1322(ra) # 800019a6 <myproc>
}
    80002ed8:	5908                	lw	a0,48(a0)
    80002eda:	60a2                	ld	ra,8(sp)
    80002edc:	6402                	ld	s0,0(sp)
    80002ede:	0141                	addi	sp,sp,16
    80002ee0:	8082                	ret

0000000080002ee2 <sys_fork>:

uint64
sys_fork(void)
{
    80002ee2:	1141                	addi	sp,sp,-16
    80002ee4:	e406                	sd	ra,8(sp)
    80002ee6:	e022                	sd	s0,0(sp)
    80002ee8:	0800                	addi	s0,sp,16
  return fork();
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	f34080e7          	jalr	-204(ra) # 80001e1e <fork>
}
    80002ef2:	60a2                	ld	ra,8(sp)
    80002ef4:	6402                	ld	s0,0(sp)
    80002ef6:	0141                	addi	sp,sp,16
    80002ef8:	8082                	ret

0000000080002efa <sys_wait>:

uint64
sys_wait(void)
{
    80002efa:	1101                	addi	sp,sp,-32
    80002efc:	ec06                	sd	ra,24(sp)
    80002efe:	e822                	sd	s0,16(sp)
    80002f00:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f02:	fe840593          	addi	a1,s0,-24
    80002f06:	4501                	li	a0,0
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	ed0080e7          	jalr	-304(ra) # 80002dd8 <argaddr>
  return wait(p);
    80002f10:	fe843503          	ld	a0,-24(s0)
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	4e2080e7          	jalr	1250(ra) # 800023f6 <wait>
}
    80002f1c:	60e2                	ld	ra,24(sp)
    80002f1e:	6442                	ld	s0,16(sp)
    80002f20:	6105                	addi	sp,sp,32
    80002f22:	8082                	ret

0000000080002f24 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f24:	7179                	addi	sp,sp,-48
    80002f26:	f406                	sd	ra,40(sp)
    80002f28:	f022                	sd	s0,32(sp)
    80002f2a:	ec26                	sd	s1,24(sp)
    80002f2c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f2e:	fdc40593          	addi	a1,s0,-36
    80002f32:	4501                	li	a0,0
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	e84080e7          	jalr	-380(ra) # 80002db8 <argint>
  addr = myproc()->sz;
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	a6a080e7          	jalr	-1430(ra) # 800019a6 <myproc>
    80002f44:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002f46:	fdc42503          	lw	a0,-36(s0)
    80002f4a:	fffff097          	auipc	ra,0xfffff
    80002f4e:	e78080e7          	jalr	-392(ra) # 80001dc2 <growproc>
    80002f52:	00054863          	bltz	a0,80002f62 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f56:	8526                	mv	a0,s1
    80002f58:	70a2                	ld	ra,40(sp)
    80002f5a:	7402                	ld	s0,32(sp)
    80002f5c:	64e2                	ld	s1,24(sp)
    80002f5e:	6145                	addi	sp,sp,48
    80002f60:	8082                	ret
    return -1;
    80002f62:	54fd                	li	s1,-1
    80002f64:	bfcd                	j	80002f56 <sys_sbrk+0x32>

0000000080002f66 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f66:	7139                	addi	sp,sp,-64
    80002f68:	fc06                	sd	ra,56(sp)
    80002f6a:	f822                	sd	s0,48(sp)
    80002f6c:	f426                	sd	s1,40(sp)
    80002f6e:	f04a                	sd	s2,32(sp)
    80002f70:	ec4e                	sd	s3,24(sp)
    80002f72:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f74:	fcc40593          	addi	a1,s0,-52
    80002f78:	4501                	li	a0,0
    80002f7a:	00000097          	auipc	ra,0x0
    80002f7e:	e3e080e7          	jalr	-450(ra) # 80002db8 <argint>
  acquire(&tickslock);
    80002f82:	00014517          	auipc	a0,0x14
    80002f86:	41e50513          	addi	a0,a0,1054 # 800173a0 <tickslock>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	c48080e7          	jalr	-952(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002f92:	00006917          	auipc	s2,0x6
    80002f96:	96e92903          	lw	s2,-1682(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    80002f9a:	fcc42783          	lw	a5,-52(s0)
    80002f9e:	cf9d                	beqz	a5,80002fdc <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fa0:	00014997          	auipc	s3,0x14
    80002fa4:	40098993          	addi	s3,s3,1024 # 800173a0 <tickslock>
    80002fa8:	00006497          	auipc	s1,0x6
    80002fac:	95848493          	addi	s1,s1,-1704 # 80008900 <ticks>
    if (killed(myproc()))
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	9f6080e7          	jalr	-1546(ra) # 800019a6 <myproc>
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	40c080e7          	jalr	1036(ra) # 800023c4 <killed>
    80002fc0:	ed15                	bnez	a0,80002ffc <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002fc2:	85ce                	mv	a1,s3
    80002fc4:	8526                	mv	a0,s1
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	14a080e7          	jalr	330(ra) # 80002110 <sleep>
  while (ticks - ticks0 < n)
    80002fce:	409c                	lw	a5,0(s1)
    80002fd0:	412787bb          	subw	a5,a5,s2
    80002fd4:	fcc42703          	lw	a4,-52(s0)
    80002fd8:	fce7ece3          	bltu	a5,a4,80002fb0 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002fdc:	00014517          	auipc	a0,0x14
    80002fe0:	3c450513          	addi	a0,a0,964 # 800173a0 <tickslock>
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	ca2080e7          	jalr	-862(ra) # 80000c86 <release>
  return 0;
    80002fec:	4501                	li	a0,0
}
    80002fee:	70e2                	ld	ra,56(sp)
    80002ff0:	7442                	ld	s0,48(sp)
    80002ff2:	74a2                	ld	s1,40(sp)
    80002ff4:	7902                	ld	s2,32(sp)
    80002ff6:	69e2                	ld	s3,24(sp)
    80002ff8:	6121                	addi	sp,sp,64
    80002ffa:	8082                	ret
      release(&tickslock);
    80002ffc:	00014517          	auipc	a0,0x14
    80003000:	3a450513          	addi	a0,a0,932 # 800173a0 <tickslock>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	c82080e7          	jalr	-894(ra) # 80000c86 <release>
      return -1;
    8000300c:	557d                	li	a0,-1
    8000300e:	b7c5                	j	80002fee <sys_sleep+0x88>

0000000080003010 <sys_kill>:

uint64
sys_kill(void)
{
    80003010:	1101                	addi	sp,sp,-32
    80003012:	ec06                	sd	ra,24(sp)
    80003014:	e822                	sd	s0,16(sp)
    80003016:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003018:	fec40593          	addi	a1,s0,-20
    8000301c:	4501                	li	a0,0
    8000301e:	00000097          	auipc	ra,0x0
    80003022:	d9a080e7          	jalr	-614(ra) # 80002db8 <argint>
  return kill(pid);
    80003026:	fec42503          	lw	a0,-20(s0)
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	2fc080e7          	jalr	764(ra) # 80002326 <kill>
}
    80003032:	60e2                	ld	ra,24(sp)
    80003034:	6442                	ld	s0,16(sp)
    80003036:	6105                	addi	sp,sp,32
    80003038:	8082                	ret

000000008000303a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000303a:	1101                	addi	sp,sp,-32
    8000303c:	ec06                	sd	ra,24(sp)
    8000303e:	e822                	sd	s0,16(sp)
    80003040:	e426                	sd	s1,8(sp)
    80003042:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003044:	00014517          	auipc	a0,0x14
    80003048:	35c50513          	addi	a0,a0,860 # 800173a0 <tickslock>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	b86080e7          	jalr	-1146(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80003054:	00006497          	auipc	s1,0x6
    80003058:	8ac4a483          	lw	s1,-1876(s1) # 80008900 <ticks>
  release(&tickslock);
    8000305c:	00014517          	auipc	a0,0x14
    80003060:	34450513          	addi	a0,a0,836 # 800173a0 <tickslock>
    80003064:	ffffe097          	auipc	ra,0xffffe
    80003068:	c22080e7          	jalr	-990(ra) # 80000c86 <release>
  return xticks;
}
    8000306c:	02049513          	slli	a0,s1,0x20
    80003070:	9101                	srli	a0,a0,0x20
    80003072:	60e2                	ld	ra,24(sp)
    80003074:	6442                	ld	s0,16(sp)
    80003076:	64a2                	ld	s1,8(sp)
    80003078:	6105                	addi	sp,sp,32
    8000307a:	8082                	ret

000000008000307c <sys_waitx>:

uint64
sys_waitx(void)
{
    8000307c:	7139                	addi	sp,sp,-64
    8000307e:	fc06                	sd	ra,56(sp)
    80003080:	f822                	sd	s0,48(sp)
    80003082:	f426                	sd	s1,40(sp)
    80003084:	f04a                	sd	s2,32(sp)
    80003086:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003088:	fd840593          	addi	a1,s0,-40
    8000308c:	4501                	li	a0,0
    8000308e:	00000097          	auipc	ra,0x0
    80003092:	d4a080e7          	jalr	-694(ra) # 80002dd8 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003096:	fd040593          	addi	a1,s0,-48
    8000309a:	4505                	li	a0,1
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	d3c080e7          	jalr	-708(ra) # 80002dd8 <argaddr>
  argaddr(2, &addr2);
    800030a4:	fc840593          	addi	a1,s0,-56
    800030a8:	4509                	li	a0,2
    800030aa:	00000097          	auipc	ra,0x0
    800030ae:	d2e080e7          	jalr	-722(ra) # 80002dd8 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800030b2:	fc040613          	addi	a2,s0,-64
    800030b6:	fc440593          	addi	a1,s0,-60
    800030ba:	fd843503          	ld	a0,-40(s0)
    800030be:	fffff097          	auipc	ra,0xfffff
    800030c2:	5c2080e7          	jalr	1474(ra) # 80002680 <waitx>
    800030c6:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800030c8:	fffff097          	auipc	ra,0xfffff
    800030cc:	8de080e7          	jalr	-1826(ra) # 800019a6 <myproc>
    800030d0:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800030d2:	4691                	li	a3,4
    800030d4:	fc440613          	addi	a2,s0,-60
    800030d8:	fd043583          	ld	a1,-48(s0)
    800030dc:	6928                	ld	a0,80(a0)
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	588080e7          	jalr	1416(ra) # 80001666 <copyout>
    return -1;
    800030e6:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800030e8:	00054f63          	bltz	a0,80003106 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800030ec:	4691                	li	a3,4
    800030ee:	fc040613          	addi	a2,s0,-64
    800030f2:	fc843583          	ld	a1,-56(s0)
    800030f6:	68a8                	ld	a0,80(s1)
    800030f8:	ffffe097          	auipc	ra,0xffffe
    800030fc:	56e080e7          	jalr	1390(ra) # 80001666 <copyout>
    80003100:	00054a63          	bltz	a0,80003114 <sys_waitx+0x98>
    return -1;
  return ret;
    80003104:	87ca                	mv	a5,s2
}
    80003106:	853e                	mv	a0,a5
    80003108:	70e2                	ld	ra,56(sp)
    8000310a:	7442                	ld	s0,48(sp)
    8000310c:	74a2                	ld	s1,40(sp)
    8000310e:	7902                	ld	s2,32(sp)
    80003110:	6121                	addi	sp,sp,64
    80003112:	8082                	ret
    return -1;
    80003114:	57fd                	li	a5,-1
    80003116:	bfc5                	j	80003106 <sys_waitx+0x8a>

0000000080003118 <restore>:
void restore(){
    80003118:	1141                	addi	sp,sp,-16
    8000311a:	e406                	sd	ra,8(sp)
    8000311c:	e022                	sd	s0,0(sp)
    8000311e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003120:	fffff097          	auipc	ra,0xfffff
    80003124:	886080e7          	jalr	-1914(ra) # 800019a6 <myproc>
  p->backup_trapframe->kernel_hartid = p->trapframe->kernel_hartid;
    80003128:	18853783          	ld	a5,392(a0)
    8000312c:	6d38                	ld	a4,88(a0)
    8000312e:	7318                	ld	a4,32(a4)
    80003130:	f398                	sd	a4,32(a5)
  p->backup_trapframe->kernel_satp = p->trapframe->kernel_satp;
    80003132:	18853783          	ld	a5,392(a0)
    80003136:	6d38                	ld	a4,88(a0)
    80003138:	6318                	ld	a4,0(a4)
    8000313a:	e398                	sd	a4,0(a5)
  p->backup_trapframe->kernel_sp = p->trapframe->kernel_sp;
    8000313c:	18853783          	ld	a5,392(a0)
    80003140:	6d38                	ld	a4,88(a0)
    80003142:	6718                	ld	a4,8(a4)
    80003144:	e798                	sd	a4,8(a5)
  p->backup_trapframe->kernel_trap = p->trapframe->kernel_trap;
    80003146:	18853783          	ld	a5,392(a0)
    8000314a:	6d38                	ld	a4,88(a0)
    8000314c:	6b18                	ld	a4,16(a4)
    8000314e:	eb98                	sd	a4,16(a5)
  *(p->trapframe) = *(p->backup_trapframe);
    80003150:	18853683          	ld	a3,392(a0)
    80003154:	87b6                	mv	a5,a3
    80003156:	6d38                	ld	a4,88(a0)
    80003158:	12068693          	addi	a3,a3,288
    8000315c:	0007b803          	ld	a6,0(a5)
    80003160:	6788                	ld	a0,8(a5)
    80003162:	6b8c                	ld	a1,16(a5)
    80003164:	6f90                	ld	a2,24(a5)
    80003166:	01073023          	sd	a6,0(a4)
    8000316a:	e708                	sd	a0,8(a4)
    8000316c:	eb0c                	sd	a1,16(a4)
    8000316e:	ef10                	sd	a2,24(a4)
    80003170:	02078793          	addi	a5,a5,32
    80003174:	02070713          	addi	a4,a4,32
    80003178:	fed792e3          	bne	a5,a3,8000315c <restore+0x44>
} 
    8000317c:	60a2                	ld	ra,8(sp)
    8000317e:	6402                	ld	s0,0(sp)
    80003180:	0141                	addi	sp,sp,16
    80003182:	8082                	ret

0000000080003184 <sys_sigreturn>:
uint64 sys_sigreturn(void){
    80003184:	1141                	addi	sp,sp,-16
    80003186:	e406                	sd	ra,8(sp)
    80003188:	e022                	sd	s0,0(sp)
    8000318a:	0800                	addi	s0,sp,16
  restore();
    8000318c:	00000097          	auipc	ra,0x0
    80003190:	f8c080e7          	jalr	-116(ra) # 80003118 <restore>
  myproc()->is_sigalarm = 0;
    80003194:	fffff097          	auipc	ra,0xfffff
    80003198:	812080e7          	jalr	-2030(ra) # 800019a6 <myproc>
    8000319c:	16052a23          	sw	zero,372(a0)
  return 0;
    800031a0:	4501                	li	a0,0
    800031a2:	60a2                	ld	ra,8(sp)
    800031a4:	6402                	ld	s0,0(sp)
    800031a6:	0141                	addi	sp,sp,16
    800031a8:	8082                	ret

00000000800031aa <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031aa:	7179                	addi	sp,sp,-48
    800031ac:	f406                	sd	ra,40(sp)
    800031ae:	f022                	sd	s0,32(sp)
    800031b0:	ec26                	sd	s1,24(sp)
    800031b2:	e84a                	sd	s2,16(sp)
    800031b4:	e44e                	sd	s3,8(sp)
    800031b6:	e052                	sd	s4,0(sp)
    800031b8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031ba:	00005597          	auipc	a1,0x5
    800031be:	36658593          	addi	a1,a1,870 # 80008520 <syscalls+0xd0>
    800031c2:	00014517          	auipc	a0,0x14
    800031c6:	1f650513          	addi	a0,a0,502 # 800173b8 <bcache>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	978080e7          	jalr	-1672(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031d2:	0001c797          	auipc	a5,0x1c
    800031d6:	1e678793          	addi	a5,a5,486 # 8001f3b8 <bcache+0x8000>
    800031da:	0001c717          	auipc	a4,0x1c
    800031de:	44670713          	addi	a4,a4,1094 # 8001f620 <bcache+0x8268>
    800031e2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031e6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ea:	00014497          	auipc	s1,0x14
    800031ee:	1e648493          	addi	s1,s1,486 # 800173d0 <bcache+0x18>
    b->next = bcache.head.next;
    800031f2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031f4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031f6:	00005a17          	auipc	s4,0x5
    800031fa:	332a0a13          	addi	s4,s4,818 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    800031fe:	2b893783          	ld	a5,696(s2)
    80003202:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003204:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003208:	85d2                	mv	a1,s4
    8000320a:	01048513          	addi	a0,s1,16
    8000320e:	00001097          	auipc	ra,0x1
    80003212:	496080e7          	jalr	1174(ra) # 800046a4 <initsleeplock>
    bcache.head.next->prev = b;
    80003216:	2b893783          	ld	a5,696(s2)
    8000321a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000321c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003220:	45848493          	addi	s1,s1,1112
    80003224:	fd349de3          	bne	s1,s3,800031fe <binit+0x54>
  }
}
    80003228:	70a2                	ld	ra,40(sp)
    8000322a:	7402                	ld	s0,32(sp)
    8000322c:	64e2                	ld	s1,24(sp)
    8000322e:	6942                	ld	s2,16(sp)
    80003230:	69a2                	ld	s3,8(sp)
    80003232:	6a02                	ld	s4,0(sp)
    80003234:	6145                	addi	sp,sp,48
    80003236:	8082                	ret

0000000080003238 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003238:	7179                	addi	sp,sp,-48
    8000323a:	f406                	sd	ra,40(sp)
    8000323c:	f022                	sd	s0,32(sp)
    8000323e:	ec26                	sd	s1,24(sp)
    80003240:	e84a                	sd	s2,16(sp)
    80003242:	e44e                	sd	s3,8(sp)
    80003244:	1800                	addi	s0,sp,48
    80003246:	892a                	mv	s2,a0
    80003248:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000324a:	00014517          	auipc	a0,0x14
    8000324e:	16e50513          	addi	a0,a0,366 # 800173b8 <bcache>
    80003252:	ffffe097          	auipc	ra,0xffffe
    80003256:	980080e7          	jalr	-1664(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000325a:	0001c497          	auipc	s1,0x1c
    8000325e:	4164b483          	ld	s1,1046(s1) # 8001f670 <bcache+0x82b8>
    80003262:	0001c797          	auipc	a5,0x1c
    80003266:	3be78793          	addi	a5,a5,958 # 8001f620 <bcache+0x8268>
    8000326a:	02f48f63          	beq	s1,a5,800032a8 <bread+0x70>
    8000326e:	873e                	mv	a4,a5
    80003270:	a021                	j	80003278 <bread+0x40>
    80003272:	68a4                	ld	s1,80(s1)
    80003274:	02e48a63          	beq	s1,a4,800032a8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003278:	449c                	lw	a5,8(s1)
    8000327a:	ff279ce3          	bne	a5,s2,80003272 <bread+0x3a>
    8000327e:	44dc                	lw	a5,12(s1)
    80003280:	ff3799e3          	bne	a5,s3,80003272 <bread+0x3a>
      b->refcnt++;
    80003284:	40bc                	lw	a5,64(s1)
    80003286:	2785                	addiw	a5,a5,1
    80003288:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000328a:	00014517          	auipc	a0,0x14
    8000328e:	12e50513          	addi	a0,a0,302 # 800173b8 <bcache>
    80003292:	ffffe097          	auipc	ra,0xffffe
    80003296:	9f4080e7          	jalr	-1548(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    8000329a:	01048513          	addi	a0,s1,16
    8000329e:	00001097          	auipc	ra,0x1
    800032a2:	440080e7          	jalr	1088(ra) # 800046de <acquiresleep>
      return b;
    800032a6:	a8b9                	j	80003304 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032a8:	0001c497          	auipc	s1,0x1c
    800032ac:	3c04b483          	ld	s1,960(s1) # 8001f668 <bcache+0x82b0>
    800032b0:	0001c797          	auipc	a5,0x1c
    800032b4:	37078793          	addi	a5,a5,880 # 8001f620 <bcache+0x8268>
    800032b8:	00f48863          	beq	s1,a5,800032c8 <bread+0x90>
    800032bc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032be:	40bc                	lw	a5,64(s1)
    800032c0:	cf81                	beqz	a5,800032d8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032c2:	64a4                	ld	s1,72(s1)
    800032c4:	fee49de3          	bne	s1,a4,800032be <bread+0x86>
  panic("bget: no buffers");
    800032c8:	00005517          	auipc	a0,0x5
    800032cc:	26850513          	addi	a0,a0,616 # 80008530 <syscalls+0xe0>
    800032d0:	ffffd097          	auipc	ra,0xffffd
    800032d4:	26c080e7          	jalr	620(ra) # 8000053c <panic>
      b->dev = dev;
    800032d8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032dc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032e0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032e4:	4785                	li	a5,1
    800032e6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032e8:	00014517          	auipc	a0,0x14
    800032ec:	0d050513          	addi	a0,a0,208 # 800173b8 <bcache>
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	996080e7          	jalr	-1642(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800032f8:	01048513          	addi	a0,s1,16
    800032fc:	00001097          	auipc	ra,0x1
    80003300:	3e2080e7          	jalr	994(ra) # 800046de <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003304:	409c                	lw	a5,0(s1)
    80003306:	cb89                	beqz	a5,80003318 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003308:	8526                	mv	a0,s1
    8000330a:	70a2                	ld	ra,40(sp)
    8000330c:	7402                	ld	s0,32(sp)
    8000330e:	64e2                	ld	s1,24(sp)
    80003310:	6942                	ld	s2,16(sp)
    80003312:	69a2                	ld	s3,8(sp)
    80003314:	6145                	addi	sp,sp,48
    80003316:	8082                	ret
    virtio_disk_rw(b, 0);
    80003318:	4581                	li	a1,0
    8000331a:	8526                	mv	a0,s1
    8000331c:	00003097          	auipc	ra,0x3
    80003320:	f86080e7          	jalr	-122(ra) # 800062a2 <virtio_disk_rw>
    b->valid = 1;
    80003324:	4785                	li	a5,1
    80003326:	c09c                	sw	a5,0(s1)
  return b;
    80003328:	b7c5                	j	80003308 <bread+0xd0>

000000008000332a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000332a:	1101                	addi	sp,sp,-32
    8000332c:	ec06                	sd	ra,24(sp)
    8000332e:	e822                	sd	s0,16(sp)
    80003330:	e426                	sd	s1,8(sp)
    80003332:	1000                	addi	s0,sp,32
    80003334:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003336:	0541                	addi	a0,a0,16
    80003338:	00001097          	auipc	ra,0x1
    8000333c:	440080e7          	jalr	1088(ra) # 80004778 <holdingsleep>
    80003340:	cd01                	beqz	a0,80003358 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003342:	4585                	li	a1,1
    80003344:	8526                	mv	a0,s1
    80003346:	00003097          	auipc	ra,0x3
    8000334a:	f5c080e7          	jalr	-164(ra) # 800062a2 <virtio_disk_rw>
}
    8000334e:	60e2                	ld	ra,24(sp)
    80003350:	6442                	ld	s0,16(sp)
    80003352:	64a2                	ld	s1,8(sp)
    80003354:	6105                	addi	sp,sp,32
    80003356:	8082                	ret
    panic("bwrite");
    80003358:	00005517          	auipc	a0,0x5
    8000335c:	1f050513          	addi	a0,a0,496 # 80008548 <syscalls+0xf8>
    80003360:	ffffd097          	auipc	ra,0xffffd
    80003364:	1dc080e7          	jalr	476(ra) # 8000053c <panic>

0000000080003368 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003368:	1101                	addi	sp,sp,-32
    8000336a:	ec06                	sd	ra,24(sp)
    8000336c:	e822                	sd	s0,16(sp)
    8000336e:	e426                	sd	s1,8(sp)
    80003370:	e04a                	sd	s2,0(sp)
    80003372:	1000                	addi	s0,sp,32
    80003374:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003376:	01050913          	addi	s2,a0,16
    8000337a:	854a                	mv	a0,s2
    8000337c:	00001097          	auipc	ra,0x1
    80003380:	3fc080e7          	jalr	1020(ra) # 80004778 <holdingsleep>
    80003384:	c925                	beqz	a0,800033f4 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003386:	854a                	mv	a0,s2
    80003388:	00001097          	auipc	ra,0x1
    8000338c:	3ac080e7          	jalr	940(ra) # 80004734 <releasesleep>

  acquire(&bcache.lock);
    80003390:	00014517          	auipc	a0,0x14
    80003394:	02850513          	addi	a0,a0,40 # 800173b8 <bcache>
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	83a080e7          	jalr	-1990(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800033a0:	40bc                	lw	a5,64(s1)
    800033a2:	37fd                	addiw	a5,a5,-1
    800033a4:	0007871b          	sext.w	a4,a5
    800033a8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033aa:	e71d                	bnez	a4,800033d8 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033ac:	68b8                	ld	a4,80(s1)
    800033ae:	64bc                	ld	a5,72(s1)
    800033b0:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800033b2:	68b8                	ld	a4,80(s1)
    800033b4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033b6:	0001c797          	auipc	a5,0x1c
    800033ba:	00278793          	addi	a5,a5,2 # 8001f3b8 <bcache+0x8000>
    800033be:	2b87b703          	ld	a4,696(a5)
    800033c2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033c4:	0001c717          	auipc	a4,0x1c
    800033c8:	25c70713          	addi	a4,a4,604 # 8001f620 <bcache+0x8268>
    800033cc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033ce:	2b87b703          	ld	a4,696(a5)
    800033d2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033d4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033d8:	00014517          	auipc	a0,0x14
    800033dc:	fe050513          	addi	a0,a0,-32 # 800173b8 <bcache>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8a6080e7          	jalr	-1882(ra) # 80000c86 <release>
}
    800033e8:	60e2                	ld	ra,24(sp)
    800033ea:	6442                	ld	s0,16(sp)
    800033ec:	64a2                	ld	s1,8(sp)
    800033ee:	6902                	ld	s2,0(sp)
    800033f0:	6105                	addi	sp,sp,32
    800033f2:	8082                	ret
    panic("brelse");
    800033f4:	00005517          	auipc	a0,0x5
    800033f8:	15c50513          	addi	a0,a0,348 # 80008550 <syscalls+0x100>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	140080e7          	jalr	320(ra) # 8000053c <panic>

0000000080003404 <bpin>:

void
bpin(struct buf *b) {
    80003404:	1101                	addi	sp,sp,-32
    80003406:	ec06                	sd	ra,24(sp)
    80003408:	e822                	sd	s0,16(sp)
    8000340a:	e426                	sd	s1,8(sp)
    8000340c:	1000                	addi	s0,sp,32
    8000340e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003410:	00014517          	auipc	a0,0x14
    80003414:	fa850513          	addi	a0,a0,-88 # 800173b8 <bcache>
    80003418:	ffffd097          	auipc	ra,0xffffd
    8000341c:	7ba080e7          	jalr	1978(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003420:	40bc                	lw	a5,64(s1)
    80003422:	2785                	addiw	a5,a5,1
    80003424:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003426:	00014517          	auipc	a0,0x14
    8000342a:	f9250513          	addi	a0,a0,-110 # 800173b8 <bcache>
    8000342e:	ffffe097          	auipc	ra,0xffffe
    80003432:	858080e7          	jalr	-1960(ra) # 80000c86 <release>
}
    80003436:	60e2                	ld	ra,24(sp)
    80003438:	6442                	ld	s0,16(sp)
    8000343a:	64a2                	ld	s1,8(sp)
    8000343c:	6105                	addi	sp,sp,32
    8000343e:	8082                	ret

0000000080003440 <bunpin>:

void
bunpin(struct buf *b) {
    80003440:	1101                	addi	sp,sp,-32
    80003442:	ec06                	sd	ra,24(sp)
    80003444:	e822                	sd	s0,16(sp)
    80003446:	e426                	sd	s1,8(sp)
    80003448:	1000                	addi	s0,sp,32
    8000344a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000344c:	00014517          	auipc	a0,0x14
    80003450:	f6c50513          	addi	a0,a0,-148 # 800173b8 <bcache>
    80003454:	ffffd097          	auipc	ra,0xffffd
    80003458:	77e080e7          	jalr	1918(ra) # 80000bd2 <acquire>
  b->refcnt--;
    8000345c:	40bc                	lw	a5,64(s1)
    8000345e:	37fd                	addiw	a5,a5,-1
    80003460:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003462:	00014517          	auipc	a0,0x14
    80003466:	f5650513          	addi	a0,a0,-170 # 800173b8 <bcache>
    8000346a:	ffffe097          	auipc	ra,0xffffe
    8000346e:	81c080e7          	jalr	-2020(ra) # 80000c86 <release>
}
    80003472:	60e2                	ld	ra,24(sp)
    80003474:	6442                	ld	s0,16(sp)
    80003476:	64a2                	ld	s1,8(sp)
    80003478:	6105                	addi	sp,sp,32
    8000347a:	8082                	ret

000000008000347c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000347c:	1101                	addi	sp,sp,-32
    8000347e:	ec06                	sd	ra,24(sp)
    80003480:	e822                	sd	s0,16(sp)
    80003482:	e426                	sd	s1,8(sp)
    80003484:	e04a                	sd	s2,0(sp)
    80003486:	1000                	addi	s0,sp,32
    80003488:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000348a:	00d5d59b          	srliw	a1,a1,0xd
    8000348e:	0001c797          	auipc	a5,0x1c
    80003492:	6067a783          	lw	a5,1542(a5) # 8001fa94 <sb+0x1c>
    80003496:	9dbd                	addw	a1,a1,a5
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	da0080e7          	jalr	-608(ra) # 80003238 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034a0:	0074f713          	andi	a4,s1,7
    800034a4:	4785                	li	a5,1
    800034a6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034aa:	14ce                	slli	s1,s1,0x33
    800034ac:	90d9                	srli	s1,s1,0x36
    800034ae:	00950733          	add	a4,a0,s1
    800034b2:	05874703          	lbu	a4,88(a4)
    800034b6:	00e7f6b3          	and	a3,a5,a4
    800034ba:	c69d                	beqz	a3,800034e8 <bfree+0x6c>
    800034bc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034be:	94aa                	add	s1,s1,a0
    800034c0:	fff7c793          	not	a5,a5
    800034c4:	8f7d                	and	a4,a4,a5
    800034c6:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800034ca:	00001097          	auipc	ra,0x1
    800034ce:	0f6080e7          	jalr	246(ra) # 800045c0 <log_write>
  brelse(bp);
    800034d2:	854a                	mv	a0,s2
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	e94080e7          	jalr	-364(ra) # 80003368 <brelse>
}
    800034dc:	60e2                	ld	ra,24(sp)
    800034de:	6442                	ld	s0,16(sp)
    800034e0:	64a2                	ld	s1,8(sp)
    800034e2:	6902                	ld	s2,0(sp)
    800034e4:	6105                	addi	sp,sp,32
    800034e6:	8082                	ret
    panic("freeing free block");
    800034e8:	00005517          	auipc	a0,0x5
    800034ec:	07050513          	addi	a0,a0,112 # 80008558 <syscalls+0x108>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	04c080e7          	jalr	76(ra) # 8000053c <panic>

00000000800034f8 <balloc>:
{
    800034f8:	711d                	addi	sp,sp,-96
    800034fa:	ec86                	sd	ra,88(sp)
    800034fc:	e8a2                	sd	s0,80(sp)
    800034fe:	e4a6                	sd	s1,72(sp)
    80003500:	e0ca                	sd	s2,64(sp)
    80003502:	fc4e                	sd	s3,56(sp)
    80003504:	f852                	sd	s4,48(sp)
    80003506:	f456                	sd	s5,40(sp)
    80003508:	f05a                	sd	s6,32(sp)
    8000350a:	ec5e                	sd	s7,24(sp)
    8000350c:	e862                	sd	s8,16(sp)
    8000350e:	e466                	sd	s9,8(sp)
    80003510:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003512:	0001c797          	auipc	a5,0x1c
    80003516:	56a7a783          	lw	a5,1386(a5) # 8001fa7c <sb+0x4>
    8000351a:	cff5                	beqz	a5,80003616 <balloc+0x11e>
    8000351c:	8baa                	mv	s7,a0
    8000351e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003520:	0001cb17          	auipc	s6,0x1c
    80003524:	558b0b13          	addi	s6,s6,1368 # 8001fa78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003528:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000352a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000352c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000352e:	6c89                	lui	s9,0x2
    80003530:	a061                	j	800035b8 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003532:	97ca                	add	a5,a5,s2
    80003534:	8e55                	or	a2,a2,a3
    80003536:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000353a:	854a                	mv	a0,s2
    8000353c:	00001097          	auipc	ra,0x1
    80003540:	084080e7          	jalr	132(ra) # 800045c0 <log_write>
        brelse(bp);
    80003544:	854a                	mv	a0,s2
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	e22080e7          	jalr	-478(ra) # 80003368 <brelse>
  bp = bread(dev, bno);
    8000354e:	85a6                	mv	a1,s1
    80003550:	855e                	mv	a0,s7
    80003552:	00000097          	auipc	ra,0x0
    80003556:	ce6080e7          	jalr	-794(ra) # 80003238 <bread>
    8000355a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000355c:	40000613          	li	a2,1024
    80003560:	4581                	li	a1,0
    80003562:	05850513          	addi	a0,a0,88
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	768080e7          	jalr	1896(ra) # 80000cce <memset>
  log_write(bp);
    8000356e:	854a                	mv	a0,s2
    80003570:	00001097          	auipc	ra,0x1
    80003574:	050080e7          	jalr	80(ra) # 800045c0 <log_write>
  brelse(bp);
    80003578:	854a                	mv	a0,s2
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	dee080e7          	jalr	-530(ra) # 80003368 <brelse>
}
    80003582:	8526                	mv	a0,s1
    80003584:	60e6                	ld	ra,88(sp)
    80003586:	6446                	ld	s0,80(sp)
    80003588:	64a6                	ld	s1,72(sp)
    8000358a:	6906                	ld	s2,64(sp)
    8000358c:	79e2                	ld	s3,56(sp)
    8000358e:	7a42                	ld	s4,48(sp)
    80003590:	7aa2                	ld	s5,40(sp)
    80003592:	7b02                	ld	s6,32(sp)
    80003594:	6be2                	ld	s7,24(sp)
    80003596:	6c42                	ld	s8,16(sp)
    80003598:	6ca2                	ld	s9,8(sp)
    8000359a:	6125                	addi	sp,sp,96
    8000359c:	8082                	ret
    brelse(bp);
    8000359e:	854a                	mv	a0,s2
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	dc8080e7          	jalr	-568(ra) # 80003368 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035a8:	015c87bb          	addw	a5,s9,s5
    800035ac:	00078a9b          	sext.w	s5,a5
    800035b0:	004b2703          	lw	a4,4(s6)
    800035b4:	06eaf163          	bgeu	s5,a4,80003616 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800035b8:	41fad79b          	sraiw	a5,s5,0x1f
    800035bc:	0137d79b          	srliw	a5,a5,0x13
    800035c0:	015787bb          	addw	a5,a5,s5
    800035c4:	40d7d79b          	sraiw	a5,a5,0xd
    800035c8:	01cb2583          	lw	a1,28(s6)
    800035cc:	9dbd                	addw	a1,a1,a5
    800035ce:	855e                	mv	a0,s7
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	c68080e7          	jalr	-920(ra) # 80003238 <bread>
    800035d8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035da:	004b2503          	lw	a0,4(s6)
    800035de:	000a849b          	sext.w	s1,s5
    800035e2:	8762                	mv	a4,s8
    800035e4:	faa4fde3          	bgeu	s1,a0,8000359e <balloc+0xa6>
      m = 1 << (bi % 8);
    800035e8:	00777693          	andi	a3,a4,7
    800035ec:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035f0:	41f7579b          	sraiw	a5,a4,0x1f
    800035f4:	01d7d79b          	srliw	a5,a5,0x1d
    800035f8:	9fb9                	addw	a5,a5,a4
    800035fa:	4037d79b          	sraiw	a5,a5,0x3
    800035fe:	00f90633          	add	a2,s2,a5
    80003602:	05864603          	lbu	a2,88(a2)
    80003606:	00c6f5b3          	and	a1,a3,a2
    8000360a:	d585                	beqz	a1,80003532 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000360c:	2705                	addiw	a4,a4,1
    8000360e:	2485                	addiw	s1,s1,1
    80003610:	fd471ae3          	bne	a4,s4,800035e4 <balloc+0xec>
    80003614:	b769                	j	8000359e <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003616:	00005517          	auipc	a0,0x5
    8000361a:	f5a50513          	addi	a0,a0,-166 # 80008570 <syscalls+0x120>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	f68080e7          	jalr	-152(ra) # 80000586 <printf>
  return 0;
    80003626:	4481                	li	s1,0
    80003628:	bfa9                	j	80003582 <balloc+0x8a>

000000008000362a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000362a:	7179                	addi	sp,sp,-48
    8000362c:	f406                	sd	ra,40(sp)
    8000362e:	f022                	sd	s0,32(sp)
    80003630:	ec26                	sd	s1,24(sp)
    80003632:	e84a                	sd	s2,16(sp)
    80003634:	e44e                	sd	s3,8(sp)
    80003636:	e052                	sd	s4,0(sp)
    80003638:	1800                	addi	s0,sp,48
    8000363a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000363c:	47ad                	li	a5,11
    8000363e:	02b7e863          	bltu	a5,a1,8000366e <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003642:	02059793          	slli	a5,a1,0x20
    80003646:	01e7d593          	srli	a1,a5,0x1e
    8000364a:	00b504b3          	add	s1,a0,a1
    8000364e:	0504a903          	lw	s2,80(s1)
    80003652:	06091e63          	bnez	s2,800036ce <bmap+0xa4>
      addr = balloc(ip->dev);
    80003656:	4108                	lw	a0,0(a0)
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	ea0080e7          	jalr	-352(ra) # 800034f8 <balloc>
    80003660:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003664:	06090563          	beqz	s2,800036ce <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003668:	0524a823          	sw	s2,80(s1)
    8000366c:	a08d                	j	800036ce <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000366e:	ff45849b          	addiw	s1,a1,-12
    80003672:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003676:	0ff00793          	li	a5,255
    8000367a:	08e7e563          	bltu	a5,a4,80003704 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000367e:	08052903          	lw	s2,128(a0)
    80003682:	00091d63          	bnez	s2,8000369c <bmap+0x72>
      addr = balloc(ip->dev);
    80003686:	4108                	lw	a0,0(a0)
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	e70080e7          	jalr	-400(ra) # 800034f8 <balloc>
    80003690:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003694:	02090d63          	beqz	s2,800036ce <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003698:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000369c:	85ca                	mv	a1,s2
    8000369e:	0009a503          	lw	a0,0(s3)
    800036a2:	00000097          	auipc	ra,0x0
    800036a6:	b96080e7          	jalr	-1130(ra) # 80003238 <bread>
    800036aa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036ac:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036b0:	02049713          	slli	a4,s1,0x20
    800036b4:	01e75593          	srli	a1,a4,0x1e
    800036b8:	00b784b3          	add	s1,a5,a1
    800036bc:	0004a903          	lw	s2,0(s1)
    800036c0:	02090063          	beqz	s2,800036e0 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036c4:	8552                	mv	a0,s4
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	ca2080e7          	jalr	-862(ra) # 80003368 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036ce:	854a                	mv	a0,s2
    800036d0:	70a2                	ld	ra,40(sp)
    800036d2:	7402                	ld	s0,32(sp)
    800036d4:	64e2                	ld	s1,24(sp)
    800036d6:	6942                	ld	s2,16(sp)
    800036d8:	69a2                	ld	s3,8(sp)
    800036da:	6a02                	ld	s4,0(sp)
    800036dc:	6145                	addi	sp,sp,48
    800036de:	8082                	ret
      addr = balloc(ip->dev);
    800036e0:	0009a503          	lw	a0,0(s3)
    800036e4:	00000097          	auipc	ra,0x0
    800036e8:	e14080e7          	jalr	-492(ra) # 800034f8 <balloc>
    800036ec:	0005091b          	sext.w	s2,a0
      if(addr){
    800036f0:	fc090ae3          	beqz	s2,800036c4 <bmap+0x9a>
        a[bn] = addr;
    800036f4:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800036f8:	8552                	mv	a0,s4
    800036fa:	00001097          	auipc	ra,0x1
    800036fe:	ec6080e7          	jalr	-314(ra) # 800045c0 <log_write>
    80003702:	b7c9                	j	800036c4 <bmap+0x9a>
  panic("bmap: out of range");
    80003704:	00005517          	auipc	a0,0x5
    80003708:	e8450513          	addi	a0,a0,-380 # 80008588 <syscalls+0x138>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	e30080e7          	jalr	-464(ra) # 8000053c <panic>

0000000080003714 <iget>:
{
    80003714:	7179                	addi	sp,sp,-48
    80003716:	f406                	sd	ra,40(sp)
    80003718:	f022                	sd	s0,32(sp)
    8000371a:	ec26                	sd	s1,24(sp)
    8000371c:	e84a                	sd	s2,16(sp)
    8000371e:	e44e                	sd	s3,8(sp)
    80003720:	e052                	sd	s4,0(sp)
    80003722:	1800                	addi	s0,sp,48
    80003724:	89aa                	mv	s3,a0
    80003726:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003728:	0001c517          	auipc	a0,0x1c
    8000372c:	37050513          	addi	a0,a0,880 # 8001fa98 <itable>
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	4a2080e7          	jalr	1186(ra) # 80000bd2 <acquire>
  empty = 0;
    80003738:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000373a:	0001c497          	auipc	s1,0x1c
    8000373e:	37648493          	addi	s1,s1,886 # 8001fab0 <itable+0x18>
    80003742:	0001e697          	auipc	a3,0x1e
    80003746:	dfe68693          	addi	a3,a3,-514 # 80021540 <log>
    8000374a:	a039                	j	80003758 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000374c:	02090b63          	beqz	s2,80003782 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003750:	08848493          	addi	s1,s1,136
    80003754:	02d48a63          	beq	s1,a3,80003788 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003758:	449c                	lw	a5,8(s1)
    8000375a:	fef059e3          	blez	a5,8000374c <iget+0x38>
    8000375e:	4098                	lw	a4,0(s1)
    80003760:	ff3716e3          	bne	a4,s3,8000374c <iget+0x38>
    80003764:	40d8                	lw	a4,4(s1)
    80003766:	ff4713e3          	bne	a4,s4,8000374c <iget+0x38>
      ip->ref++;
    8000376a:	2785                	addiw	a5,a5,1
    8000376c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000376e:	0001c517          	auipc	a0,0x1c
    80003772:	32a50513          	addi	a0,a0,810 # 8001fa98 <itable>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	510080e7          	jalr	1296(ra) # 80000c86 <release>
      return ip;
    8000377e:	8926                	mv	s2,s1
    80003780:	a03d                	j	800037ae <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003782:	f7f9                	bnez	a5,80003750 <iget+0x3c>
    80003784:	8926                	mv	s2,s1
    80003786:	b7e9                	j	80003750 <iget+0x3c>
  if(empty == 0)
    80003788:	02090c63          	beqz	s2,800037c0 <iget+0xac>
  ip->dev = dev;
    8000378c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003790:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003794:	4785                	li	a5,1
    80003796:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000379a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000379e:	0001c517          	auipc	a0,0x1c
    800037a2:	2fa50513          	addi	a0,a0,762 # 8001fa98 <itable>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	4e0080e7          	jalr	1248(ra) # 80000c86 <release>
}
    800037ae:	854a                	mv	a0,s2
    800037b0:	70a2                	ld	ra,40(sp)
    800037b2:	7402                	ld	s0,32(sp)
    800037b4:	64e2                	ld	s1,24(sp)
    800037b6:	6942                	ld	s2,16(sp)
    800037b8:	69a2                	ld	s3,8(sp)
    800037ba:	6a02                	ld	s4,0(sp)
    800037bc:	6145                	addi	sp,sp,48
    800037be:	8082                	ret
    panic("iget: no inodes");
    800037c0:	00005517          	auipc	a0,0x5
    800037c4:	de050513          	addi	a0,a0,-544 # 800085a0 <syscalls+0x150>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	d74080e7          	jalr	-652(ra) # 8000053c <panic>

00000000800037d0 <fsinit>:
fsinit(int dev) {
    800037d0:	7179                	addi	sp,sp,-48
    800037d2:	f406                	sd	ra,40(sp)
    800037d4:	f022                	sd	s0,32(sp)
    800037d6:	ec26                	sd	s1,24(sp)
    800037d8:	e84a                	sd	s2,16(sp)
    800037da:	e44e                	sd	s3,8(sp)
    800037dc:	1800                	addi	s0,sp,48
    800037de:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037e0:	4585                	li	a1,1
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	a56080e7          	jalr	-1450(ra) # 80003238 <bread>
    800037ea:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037ec:	0001c997          	auipc	s3,0x1c
    800037f0:	28c98993          	addi	s3,s3,652 # 8001fa78 <sb>
    800037f4:	02000613          	li	a2,32
    800037f8:	05850593          	addi	a1,a0,88
    800037fc:	854e                	mv	a0,s3
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	52c080e7          	jalr	1324(ra) # 80000d2a <memmove>
  brelse(bp);
    80003806:	8526                	mv	a0,s1
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	b60080e7          	jalr	-1184(ra) # 80003368 <brelse>
  if(sb.magic != FSMAGIC)
    80003810:	0009a703          	lw	a4,0(s3)
    80003814:	102037b7          	lui	a5,0x10203
    80003818:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000381c:	02f71263          	bne	a4,a5,80003840 <fsinit+0x70>
  initlog(dev, &sb);
    80003820:	0001c597          	auipc	a1,0x1c
    80003824:	25858593          	addi	a1,a1,600 # 8001fa78 <sb>
    80003828:	854a                	mv	a0,s2
    8000382a:	00001097          	auipc	ra,0x1
    8000382e:	b2c080e7          	jalr	-1236(ra) # 80004356 <initlog>
}
    80003832:	70a2                	ld	ra,40(sp)
    80003834:	7402                	ld	s0,32(sp)
    80003836:	64e2                	ld	s1,24(sp)
    80003838:	6942                	ld	s2,16(sp)
    8000383a:	69a2                	ld	s3,8(sp)
    8000383c:	6145                	addi	sp,sp,48
    8000383e:	8082                	ret
    panic("invalid file system");
    80003840:	00005517          	auipc	a0,0x5
    80003844:	d7050513          	addi	a0,a0,-656 # 800085b0 <syscalls+0x160>
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	cf4080e7          	jalr	-780(ra) # 8000053c <panic>

0000000080003850 <iinit>:
{
    80003850:	7179                	addi	sp,sp,-48
    80003852:	f406                	sd	ra,40(sp)
    80003854:	f022                	sd	s0,32(sp)
    80003856:	ec26                	sd	s1,24(sp)
    80003858:	e84a                	sd	s2,16(sp)
    8000385a:	e44e                	sd	s3,8(sp)
    8000385c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000385e:	00005597          	auipc	a1,0x5
    80003862:	d6a58593          	addi	a1,a1,-662 # 800085c8 <syscalls+0x178>
    80003866:	0001c517          	auipc	a0,0x1c
    8000386a:	23250513          	addi	a0,a0,562 # 8001fa98 <itable>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	2d4080e7          	jalr	724(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003876:	0001c497          	auipc	s1,0x1c
    8000387a:	24a48493          	addi	s1,s1,586 # 8001fac0 <itable+0x28>
    8000387e:	0001e997          	auipc	s3,0x1e
    80003882:	cd298993          	addi	s3,s3,-814 # 80021550 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003886:	00005917          	auipc	s2,0x5
    8000388a:	d4a90913          	addi	s2,s2,-694 # 800085d0 <syscalls+0x180>
    8000388e:	85ca                	mv	a1,s2
    80003890:	8526                	mv	a0,s1
    80003892:	00001097          	auipc	ra,0x1
    80003896:	e12080e7          	jalr	-494(ra) # 800046a4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000389a:	08848493          	addi	s1,s1,136
    8000389e:	ff3498e3          	bne	s1,s3,8000388e <iinit+0x3e>
}
    800038a2:	70a2                	ld	ra,40(sp)
    800038a4:	7402                	ld	s0,32(sp)
    800038a6:	64e2                	ld	s1,24(sp)
    800038a8:	6942                	ld	s2,16(sp)
    800038aa:	69a2                	ld	s3,8(sp)
    800038ac:	6145                	addi	sp,sp,48
    800038ae:	8082                	ret

00000000800038b0 <ialloc>:
{
    800038b0:	7139                	addi	sp,sp,-64
    800038b2:	fc06                	sd	ra,56(sp)
    800038b4:	f822                	sd	s0,48(sp)
    800038b6:	f426                	sd	s1,40(sp)
    800038b8:	f04a                	sd	s2,32(sp)
    800038ba:	ec4e                	sd	s3,24(sp)
    800038bc:	e852                	sd	s4,16(sp)
    800038be:	e456                	sd	s5,8(sp)
    800038c0:	e05a                	sd	s6,0(sp)
    800038c2:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800038c4:	0001c717          	auipc	a4,0x1c
    800038c8:	1c072703          	lw	a4,448(a4) # 8001fa84 <sb+0xc>
    800038cc:	4785                	li	a5,1
    800038ce:	04e7f863          	bgeu	a5,a4,8000391e <ialloc+0x6e>
    800038d2:	8aaa                	mv	s5,a0
    800038d4:	8b2e                	mv	s6,a1
    800038d6:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038d8:	0001ca17          	auipc	s4,0x1c
    800038dc:	1a0a0a13          	addi	s4,s4,416 # 8001fa78 <sb>
    800038e0:	00495593          	srli	a1,s2,0x4
    800038e4:	018a2783          	lw	a5,24(s4)
    800038e8:	9dbd                	addw	a1,a1,a5
    800038ea:	8556                	mv	a0,s5
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	94c080e7          	jalr	-1716(ra) # 80003238 <bread>
    800038f4:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038f6:	05850993          	addi	s3,a0,88
    800038fa:	00f97793          	andi	a5,s2,15
    800038fe:	079a                	slli	a5,a5,0x6
    80003900:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003902:	00099783          	lh	a5,0(s3)
    80003906:	cf9d                	beqz	a5,80003944 <ialloc+0x94>
    brelse(bp);
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	a60080e7          	jalr	-1440(ra) # 80003368 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003910:	0905                	addi	s2,s2,1
    80003912:	00ca2703          	lw	a4,12(s4)
    80003916:	0009079b          	sext.w	a5,s2
    8000391a:	fce7e3e3          	bltu	a5,a4,800038e0 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    8000391e:	00005517          	auipc	a0,0x5
    80003922:	cba50513          	addi	a0,a0,-838 # 800085d8 <syscalls+0x188>
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	c60080e7          	jalr	-928(ra) # 80000586 <printf>
  return 0;
    8000392e:	4501                	li	a0,0
}
    80003930:	70e2                	ld	ra,56(sp)
    80003932:	7442                	ld	s0,48(sp)
    80003934:	74a2                	ld	s1,40(sp)
    80003936:	7902                	ld	s2,32(sp)
    80003938:	69e2                	ld	s3,24(sp)
    8000393a:	6a42                	ld	s4,16(sp)
    8000393c:	6aa2                	ld	s5,8(sp)
    8000393e:	6b02                	ld	s6,0(sp)
    80003940:	6121                	addi	sp,sp,64
    80003942:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003944:	04000613          	li	a2,64
    80003948:	4581                	li	a1,0
    8000394a:	854e                	mv	a0,s3
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	382080e7          	jalr	898(ra) # 80000cce <memset>
      dip->type = type;
    80003954:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003958:	8526                	mv	a0,s1
    8000395a:	00001097          	auipc	ra,0x1
    8000395e:	c66080e7          	jalr	-922(ra) # 800045c0 <log_write>
      brelse(bp);
    80003962:	8526                	mv	a0,s1
    80003964:	00000097          	auipc	ra,0x0
    80003968:	a04080e7          	jalr	-1532(ra) # 80003368 <brelse>
      return iget(dev, inum);
    8000396c:	0009059b          	sext.w	a1,s2
    80003970:	8556                	mv	a0,s5
    80003972:	00000097          	auipc	ra,0x0
    80003976:	da2080e7          	jalr	-606(ra) # 80003714 <iget>
    8000397a:	bf5d                	j	80003930 <ialloc+0x80>

000000008000397c <iupdate>:
{
    8000397c:	1101                	addi	sp,sp,-32
    8000397e:	ec06                	sd	ra,24(sp)
    80003980:	e822                	sd	s0,16(sp)
    80003982:	e426                	sd	s1,8(sp)
    80003984:	e04a                	sd	s2,0(sp)
    80003986:	1000                	addi	s0,sp,32
    80003988:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000398a:	415c                	lw	a5,4(a0)
    8000398c:	0047d79b          	srliw	a5,a5,0x4
    80003990:	0001c597          	auipc	a1,0x1c
    80003994:	1005a583          	lw	a1,256(a1) # 8001fa90 <sb+0x18>
    80003998:	9dbd                	addw	a1,a1,a5
    8000399a:	4108                	lw	a0,0(a0)
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	89c080e7          	jalr	-1892(ra) # 80003238 <bread>
    800039a4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039a6:	05850793          	addi	a5,a0,88
    800039aa:	40d8                	lw	a4,4(s1)
    800039ac:	8b3d                	andi	a4,a4,15
    800039ae:	071a                	slli	a4,a4,0x6
    800039b0:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800039b2:	04449703          	lh	a4,68(s1)
    800039b6:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800039ba:	04649703          	lh	a4,70(s1)
    800039be:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800039c2:	04849703          	lh	a4,72(s1)
    800039c6:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800039ca:	04a49703          	lh	a4,74(s1)
    800039ce:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800039d2:	44f8                	lw	a4,76(s1)
    800039d4:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039d6:	03400613          	li	a2,52
    800039da:	05048593          	addi	a1,s1,80
    800039de:	00c78513          	addi	a0,a5,12
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	348080e7          	jalr	840(ra) # 80000d2a <memmove>
  log_write(bp);
    800039ea:	854a                	mv	a0,s2
    800039ec:	00001097          	auipc	ra,0x1
    800039f0:	bd4080e7          	jalr	-1068(ra) # 800045c0 <log_write>
  brelse(bp);
    800039f4:	854a                	mv	a0,s2
    800039f6:	00000097          	auipc	ra,0x0
    800039fa:	972080e7          	jalr	-1678(ra) # 80003368 <brelse>
}
    800039fe:	60e2                	ld	ra,24(sp)
    80003a00:	6442                	ld	s0,16(sp)
    80003a02:	64a2                	ld	s1,8(sp)
    80003a04:	6902                	ld	s2,0(sp)
    80003a06:	6105                	addi	sp,sp,32
    80003a08:	8082                	ret

0000000080003a0a <idup>:
{
    80003a0a:	1101                	addi	sp,sp,-32
    80003a0c:	ec06                	sd	ra,24(sp)
    80003a0e:	e822                	sd	s0,16(sp)
    80003a10:	e426                	sd	s1,8(sp)
    80003a12:	1000                	addi	s0,sp,32
    80003a14:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a16:	0001c517          	auipc	a0,0x1c
    80003a1a:	08250513          	addi	a0,a0,130 # 8001fa98 <itable>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	1b4080e7          	jalr	436(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003a26:	449c                	lw	a5,8(s1)
    80003a28:	2785                	addiw	a5,a5,1
    80003a2a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a2c:	0001c517          	auipc	a0,0x1c
    80003a30:	06c50513          	addi	a0,a0,108 # 8001fa98 <itable>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	252080e7          	jalr	594(ra) # 80000c86 <release>
}
    80003a3c:	8526                	mv	a0,s1
    80003a3e:	60e2                	ld	ra,24(sp)
    80003a40:	6442                	ld	s0,16(sp)
    80003a42:	64a2                	ld	s1,8(sp)
    80003a44:	6105                	addi	sp,sp,32
    80003a46:	8082                	ret

0000000080003a48 <ilock>:
{
    80003a48:	1101                	addi	sp,sp,-32
    80003a4a:	ec06                	sd	ra,24(sp)
    80003a4c:	e822                	sd	s0,16(sp)
    80003a4e:	e426                	sd	s1,8(sp)
    80003a50:	e04a                	sd	s2,0(sp)
    80003a52:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a54:	c115                	beqz	a0,80003a78 <ilock+0x30>
    80003a56:	84aa                	mv	s1,a0
    80003a58:	451c                	lw	a5,8(a0)
    80003a5a:	00f05f63          	blez	a5,80003a78 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a5e:	0541                	addi	a0,a0,16
    80003a60:	00001097          	auipc	ra,0x1
    80003a64:	c7e080e7          	jalr	-898(ra) # 800046de <acquiresleep>
  if(ip->valid == 0){
    80003a68:	40bc                	lw	a5,64(s1)
    80003a6a:	cf99                	beqz	a5,80003a88 <ilock+0x40>
}
    80003a6c:	60e2                	ld	ra,24(sp)
    80003a6e:	6442                	ld	s0,16(sp)
    80003a70:	64a2                	ld	s1,8(sp)
    80003a72:	6902                	ld	s2,0(sp)
    80003a74:	6105                	addi	sp,sp,32
    80003a76:	8082                	ret
    panic("ilock");
    80003a78:	00005517          	auipc	a0,0x5
    80003a7c:	b7850513          	addi	a0,a0,-1160 # 800085f0 <syscalls+0x1a0>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	abc080e7          	jalr	-1348(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a88:	40dc                	lw	a5,4(s1)
    80003a8a:	0047d79b          	srliw	a5,a5,0x4
    80003a8e:	0001c597          	auipc	a1,0x1c
    80003a92:	0025a583          	lw	a1,2(a1) # 8001fa90 <sb+0x18>
    80003a96:	9dbd                	addw	a1,a1,a5
    80003a98:	4088                	lw	a0,0(s1)
    80003a9a:	fffff097          	auipc	ra,0xfffff
    80003a9e:	79e080e7          	jalr	1950(ra) # 80003238 <bread>
    80003aa2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aa4:	05850593          	addi	a1,a0,88
    80003aa8:	40dc                	lw	a5,4(s1)
    80003aaa:	8bbd                	andi	a5,a5,15
    80003aac:	079a                	slli	a5,a5,0x6
    80003aae:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ab0:	00059783          	lh	a5,0(a1)
    80003ab4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ab8:	00259783          	lh	a5,2(a1)
    80003abc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ac0:	00459783          	lh	a5,4(a1)
    80003ac4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ac8:	00659783          	lh	a5,6(a1)
    80003acc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ad0:	459c                	lw	a5,8(a1)
    80003ad2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ad4:	03400613          	li	a2,52
    80003ad8:	05b1                	addi	a1,a1,12
    80003ada:	05048513          	addi	a0,s1,80
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	24c080e7          	jalr	588(ra) # 80000d2a <memmove>
    brelse(bp);
    80003ae6:	854a                	mv	a0,s2
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	880080e7          	jalr	-1920(ra) # 80003368 <brelse>
    ip->valid = 1;
    80003af0:	4785                	li	a5,1
    80003af2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003af4:	04449783          	lh	a5,68(s1)
    80003af8:	fbb5                	bnez	a5,80003a6c <ilock+0x24>
      panic("ilock: no type");
    80003afa:	00005517          	auipc	a0,0x5
    80003afe:	afe50513          	addi	a0,a0,-1282 # 800085f8 <syscalls+0x1a8>
    80003b02:	ffffd097          	auipc	ra,0xffffd
    80003b06:	a3a080e7          	jalr	-1478(ra) # 8000053c <panic>

0000000080003b0a <iunlock>:
{
    80003b0a:	1101                	addi	sp,sp,-32
    80003b0c:	ec06                	sd	ra,24(sp)
    80003b0e:	e822                	sd	s0,16(sp)
    80003b10:	e426                	sd	s1,8(sp)
    80003b12:	e04a                	sd	s2,0(sp)
    80003b14:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b16:	c905                	beqz	a0,80003b46 <iunlock+0x3c>
    80003b18:	84aa                	mv	s1,a0
    80003b1a:	01050913          	addi	s2,a0,16
    80003b1e:	854a                	mv	a0,s2
    80003b20:	00001097          	auipc	ra,0x1
    80003b24:	c58080e7          	jalr	-936(ra) # 80004778 <holdingsleep>
    80003b28:	cd19                	beqz	a0,80003b46 <iunlock+0x3c>
    80003b2a:	449c                	lw	a5,8(s1)
    80003b2c:	00f05d63          	blez	a5,80003b46 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b30:	854a                	mv	a0,s2
    80003b32:	00001097          	auipc	ra,0x1
    80003b36:	c02080e7          	jalr	-1022(ra) # 80004734 <releasesleep>
}
    80003b3a:	60e2                	ld	ra,24(sp)
    80003b3c:	6442                	ld	s0,16(sp)
    80003b3e:	64a2                	ld	s1,8(sp)
    80003b40:	6902                	ld	s2,0(sp)
    80003b42:	6105                	addi	sp,sp,32
    80003b44:	8082                	ret
    panic("iunlock");
    80003b46:	00005517          	auipc	a0,0x5
    80003b4a:	ac250513          	addi	a0,a0,-1342 # 80008608 <syscalls+0x1b8>
    80003b4e:	ffffd097          	auipc	ra,0xffffd
    80003b52:	9ee080e7          	jalr	-1554(ra) # 8000053c <panic>

0000000080003b56 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b56:	7179                	addi	sp,sp,-48
    80003b58:	f406                	sd	ra,40(sp)
    80003b5a:	f022                	sd	s0,32(sp)
    80003b5c:	ec26                	sd	s1,24(sp)
    80003b5e:	e84a                	sd	s2,16(sp)
    80003b60:	e44e                	sd	s3,8(sp)
    80003b62:	e052                	sd	s4,0(sp)
    80003b64:	1800                	addi	s0,sp,48
    80003b66:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b68:	05050493          	addi	s1,a0,80
    80003b6c:	08050913          	addi	s2,a0,128
    80003b70:	a021                	j	80003b78 <itrunc+0x22>
    80003b72:	0491                	addi	s1,s1,4
    80003b74:	01248d63          	beq	s1,s2,80003b8e <itrunc+0x38>
    if(ip->addrs[i]){
    80003b78:	408c                	lw	a1,0(s1)
    80003b7a:	dde5                	beqz	a1,80003b72 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b7c:	0009a503          	lw	a0,0(s3)
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	8fc080e7          	jalr	-1796(ra) # 8000347c <bfree>
      ip->addrs[i] = 0;
    80003b88:	0004a023          	sw	zero,0(s1)
    80003b8c:	b7dd                	j	80003b72 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b8e:	0809a583          	lw	a1,128(s3)
    80003b92:	e185                	bnez	a1,80003bb2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b94:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b98:	854e                	mv	a0,s3
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	de2080e7          	jalr	-542(ra) # 8000397c <iupdate>
}
    80003ba2:	70a2                	ld	ra,40(sp)
    80003ba4:	7402                	ld	s0,32(sp)
    80003ba6:	64e2                	ld	s1,24(sp)
    80003ba8:	6942                	ld	s2,16(sp)
    80003baa:	69a2                	ld	s3,8(sp)
    80003bac:	6a02                	ld	s4,0(sp)
    80003bae:	6145                	addi	sp,sp,48
    80003bb0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bb2:	0009a503          	lw	a0,0(s3)
    80003bb6:	fffff097          	auipc	ra,0xfffff
    80003bba:	682080e7          	jalr	1666(ra) # 80003238 <bread>
    80003bbe:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bc0:	05850493          	addi	s1,a0,88
    80003bc4:	45850913          	addi	s2,a0,1112
    80003bc8:	a021                	j	80003bd0 <itrunc+0x7a>
    80003bca:	0491                	addi	s1,s1,4
    80003bcc:	01248b63          	beq	s1,s2,80003be2 <itrunc+0x8c>
      if(a[j])
    80003bd0:	408c                	lw	a1,0(s1)
    80003bd2:	dde5                	beqz	a1,80003bca <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bd4:	0009a503          	lw	a0,0(s3)
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	8a4080e7          	jalr	-1884(ra) # 8000347c <bfree>
    80003be0:	b7ed                	j	80003bca <itrunc+0x74>
    brelse(bp);
    80003be2:	8552                	mv	a0,s4
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	784080e7          	jalr	1924(ra) # 80003368 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bec:	0809a583          	lw	a1,128(s3)
    80003bf0:	0009a503          	lw	a0,0(s3)
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	888080e7          	jalr	-1912(ra) # 8000347c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bfc:	0809a023          	sw	zero,128(s3)
    80003c00:	bf51                	j	80003b94 <itrunc+0x3e>

0000000080003c02 <iput>:
{
    80003c02:	1101                	addi	sp,sp,-32
    80003c04:	ec06                	sd	ra,24(sp)
    80003c06:	e822                	sd	s0,16(sp)
    80003c08:	e426                	sd	s1,8(sp)
    80003c0a:	e04a                	sd	s2,0(sp)
    80003c0c:	1000                	addi	s0,sp,32
    80003c0e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c10:	0001c517          	auipc	a0,0x1c
    80003c14:	e8850513          	addi	a0,a0,-376 # 8001fa98 <itable>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	fba080e7          	jalr	-70(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c20:	4498                	lw	a4,8(s1)
    80003c22:	4785                	li	a5,1
    80003c24:	02f70363          	beq	a4,a5,80003c4a <iput+0x48>
  ip->ref--;
    80003c28:	449c                	lw	a5,8(s1)
    80003c2a:	37fd                	addiw	a5,a5,-1
    80003c2c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c2e:	0001c517          	auipc	a0,0x1c
    80003c32:	e6a50513          	addi	a0,a0,-406 # 8001fa98 <itable>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	050080e7          	jalr	80(ra) # 80000c86 <release>
}
    80003c3e:	60e2                	ld	ra,24(sp)
    80003c40:	6442                	ld	s0,16(sp)
    80003c42:	64a2                	ld	s1,8(sp)
    80003c44:	6902                	ld	s2,0(sp)
    80003c46:	6105                	addi	sp,sp,32
    80003c48:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c4a:	40bc                	lw	a5,64(s1)
    80003c4c:	dff1                	beqz	a5,80003c28 <iput+0x26>
    80003c4e:	04a49783          	lh	a5,74(s1)
    80003c52:	fbf9                	bnez	a5,80003c28 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c54:	01048913          	addi	s2,s1,16
    80003c58:	854a                	mv	a0,s2
    80003c5a:	00001097          	auipc	ra,0x1
    80003c5e:	a84080e7          	jalr	-1404(ra) # 800046de <acquiresleep>
    release(&itable.lock);
    80003c62:	0001c517          	auipc	a0,0x1c
    80003c66:	e3650513          	addi	a0,a0,-458 # 8001fa98 <itable>
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	01c080e7          	jalr	28(ra) # 80000c86 <release>
    itrunc(ip);
    80003c72:	8526                	mv	a0,s1
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	ee2080e7          	jalr	-286(ra) # 80003b56 <itrunc>
    ip->type = 0;
    80003c7c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c80:	8526                	mv	a0,s1
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	cfa080e7          	jalr	-774(ra) # 8000397c <iupdate>
    ip->valid = 0;
    80003c8a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c8e:	854a                	mv	a0,s2
    80003c90:	00001097          	auipc	ra,0x1
    80003c94:	aa4080e7          	jalr	-1372(ra) # 80004734 <releasesleep>
    acquire(&itable.lock);
    80003c98:	0001c517          	auipc	a0,0x1c
    80003c9c:	e0050513          	addi	a0,a0,-512 # 8001fa98 <itable>
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	f32080e7          	jalr	-206(ra) # 80000bd2 <acquire>
    80003ca8:	b741                	j	80003c28 <iput+0x26>

0000000080003caa <iunlockput>:
{
    80003caa:	1101                	addi	sp,sp,-32
    80003cac:	ec06                	sd	ra,24(sp)
    80003cae:	e822                	sd	s0,16(sp)
    80003cb0:	e426                	sd	s1,8(sp)
    80003cb2:	1000                	addi	s0,sp,32
    80003cb4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	e54080e7          	jalr	-428(ra) # 80003b0a <iunlock>
  iput(ip);
    80003cbe:	8526                	mv	a0,s1
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	f42080e7          	jalr	-190(ra) # 80003c02 <iput>
}
    80003cc8:	60e2                	ld	ra,24(sp)
    80003cca:	6442                	ld	s0,16(sp)
    80003ccc:	64a2                	ld	s1,8(sp)
    80003cce:	6105                	addi	sp,sp,32
    80003cd0:	8082                	ret

0000000080003cd2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cd2:	1141                	addi	sp,sp,-16
    80003cd4:	e422                	sd	s0,8(sp)
    80003cd6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003cd8:	411c                	lw	a5,0(a0)
    80003cda:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003cdc:	415c                	lw	a5,4(a0)
    80003cde:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ce0:	04451783          	lh	a5,68(a0)
    80003ce4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ce8:	04a51783          	lh	a5,74(a0)
    80003cec:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cf0:	04c56783          	lwu	a5,76(a0)
    80003cf4:	e99c                	sd	a5,16(a1)
}
    80003cf6:	6422                	ld	s0,8(sp)
    80003cf8:	0141                	addi	sp,sp,16
    80003cfa:	8082                	ret

0000000080003cfc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cfc:	457c                	lw	a5,76(a0)
    80003cfe:	0ed7e963          	bltu	a5,a3,80003df0 <readi+0xf4>
{
    80003d02:	7159                	addi	sp,sp,-112
    80003d04:	f486                	sd	ra,104(sp)
    80003d06:	f0a2                	sd	s0,96(sp)
    80003d08:	eca6                	sd	s1,88(sp)
    80003d0a:	e8ca                	sd	s2,80(sp)
    80003d0c:	e4ce                	sd	s3,72(sp)
    80003d0e:	e0d2                	sd	s4,64(sp)
    80003d10:	fc56                	sd	s5,56(sp)
    80003d12:	f85a                	sd	s6,48(sp)
    80003d14:	f45e                	sd	s7,40(sp)
    80003d16:	f062                	sd	s8,32(sp)
    80003d18:	ec66                	sd	s9,24(sp)
    80003d1a:	e86a                	sd	s10,16(sp)
    80003d1c:	e46e                	sd	s11,8(sp)
    80003d1e:	1880                	addi	s0,sp,112
    80003d20:	8b2a                	mv	s6,a0
    80003d22:	8bae                	mv	s7,a1
    80003d24:	8a32                	mv	s4,a2
    80003d26:	84b6                	mv	s1,a3
    80003d28:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d2a:	9f35                	addw	a4,a4,a3
    return 0;
    80003d2c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d2e:	0ad76063          	bltu	a4,a3,80003dce <readi+0xd2>
  if(off + n > ip->size)
    80003d32:	00e7f463          	bgeu	a5,a4,80003d3a <readi+0x3e>
    n = ip->size - off;
    80003d36:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d3a:	0a0a8963          	beqz	s5,80003dec <readi+0xf0>
    80003d3e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d40:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d44:	5c7d                	li	s8,-1
    80003d46:	a82d                	j	80003d80 <readi+0x84>
    80003d48:	020d1d93          	slli	s11,s10,0x20
    80003d4c:	020ddd93          	srli	s11,s11,0x20
    80003d50:	05890613          	addi	a2,s2,88
    80003d54:	86ee                	mv	a3,s11
    80003d56:	963a                	add	a2,a2,a4
    80003d58:	85d2                	mv	a1,s4
    80003d5a:	855e                	mv	a0,s7
    80003d5c:	ffffe097          	auipc	ra,0xffffe
    80003d60:	7c8080e7          	jalr	1992(ra) # 80002524 <either_copyout>
    80003d64:	05850d63          	beq	a0,s8,80003dbe <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d68:	854a                	mv	a0,s2
    80003d6a:	fffff097          	auipc	ra,0xfffff
    80003d6e:	5fe080e7          	jalr	1534(ra) # 80003368 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d72:	013d09bb          	addw	s3,s10,s3
    80003d76:	009d04bb          	addw	s1,s10,s1
    80003d7a:	9a6e                	add	s4,s4,s11
    80003d7c:	0559f763          	bgeu	s3,s5,80003dca <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d80:	00a4d59b          	srliw	a1,s1,0xa
    80003d84:	855a                	mv	a0,s6
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	8a4080e7          	jalr	-1884(ra) # 8000362a <bmap>
    80003d8e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d92:	cd85                	beqz	a1,80003dca <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d94:	000b2503          	lw	a0,0(s6)
    80003d98:	fffff097          	auipc	ra,0xfffff
    80003d9c:	4a0080e7          	jalr	1184(ra) # 80003238 <bread>
    80003da0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003da2:	3ff4f713          	andi	a4,s1,1023
    80003da6:	40ec87bb          	subw	a5,s9,a4
    80003daa:	413a86bb          	subw	a3,s5,s3
    80003dae:	8d3e                	mv	s10,a5
    80003db0:	2781                	sext.w	a5,a5
    80003db2:	0006861b          	sext.w	a2,a3
    80003db6:	f8f679e3          	bgeu	a2,a5,80003d48 <readi+0x4c>
    80003dba:	8d36                	mv	s10,a3
    80003dbc:	b771                	j	80003d48 <readi+0x4c>
      brelse(bp);
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	fffff097          	auipc	ra,0xfffff
    80003dc4:	5a8080e7          	jalr	1448(ra) # 80003368 <brelse>
      tot = -1;
    80003dc8:	59fd                	li	s3,-1
  }
  return tot;
    80003dca:	0009851b          	sext.w	a0,s3
}
    80003dce:	70a6                	ld	ra,104(sp)
    80003dd0:	7406                	ld	s0,96(sp)
    80003dd2:	64e6                	ld	s1,88(sp)
    80003dd4:	6946                	ld	s2,80(sp)
    80003dd6:	69a6                	ld	s3,72(sp)
    80003dd8:	6a06                	ld	s4,64(sp)
    80003dda:	7ae2                	ld	s5,56(sp)
    80003ddc:	7b42                	ld	s6,48(sp)
    80003dde:	7ba2                	ld	s7,40(sp)
    80003de0:	7c02                	ld	s8,32(sp)
    80003de2:	6ce2                	ld	s9,24(sp)
    80003de4:	6d42                	ld	s10,16(sp)
    80003de6:	6da2                	ld	s11,8(sp)
    80003de8:	6165                	addi	sp,sp,112
    80003dea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dec:	89d6                	mv	s3,s5
    80003dee:	bff1                	j	80003dca <readi+0xce>
    return 0;
    80003df0:	4501                	li	a0,0
}
    80003df2:	8082                	ret

0000000080003df4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003df4:	457c                	lw	a5,76(a0)
    80003df6:	10d7e863          	bltu	a5,a3,80003f06 <writei+0x112>
{
    80003dfa:	7159                	addi	sp,sp,-112
    80003dfc:	f486                	sd	ra,104(sp)
    80003dfe:	f0a2                	sd	s0,96(sp)
    80003e00:	eca6                	sd	s1,88(sp)
    80003e02:	e8ca                	sd	s2,80(sp)
    80003e04:	e4ce                	sd	s3,72(sp)
    80003e06:	e0d2                	sd	s4,64(sp)
    80003e08:	fc56                	sd	s5,56(sp)
    80003e0a:	f85a                	sd	s6,48(sp)
    80003e0c:	f45e                	sd	s7,40(sp)
    80003e0e:	f062                	sd	s8,32(sp)
    80003e10:	ec66                	sd	s9,24(sp)
    80003e12:	e86a                	sd	s10,16(sp)
    80003e14:	e46e                	sd	s11,8(sp)
    80003e16:	1880                	addi	s0,sp,112
    80003e18:	8aaa                	mv	s5,a0
    80003e1a:	8bae                	mv	s7,a1
    80003e1c:	8a32                	mv	s4,a2
    80003e1e:	8936                	mv	s2,a3
    80003e20:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e22:	00e687bb          	addw	a5,a3,a4
    80003e26:	0ed7e263          	bltu	a5,a3,80003f0a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e2a:	00043737          	lui	a4,0x43
    80003e2e:	0ef76063          	bltu	a4,a5,80003f0e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e32:	0c0b0863          	beqz	s6,80003f02 <writei+0x10e>
    80003e36:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e38:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e3c:	5c7d                	li	s8,-1
    80003e3e:	a091                	j	80003e82 <writei+0x8e>
    80003e40:	020d1d93          	slli	s11,s10,0x20
    80003e44:	020ddd93          	srli	s11,s11,0x20
    80003e48:	05848513          	addi	a0,s1,88
    80003e4c:	86ee                	mv	a3,s11
    80003e4e:	8652                	mv	a2,s4
    80003e50:	85de                	mv	a1,s7
    80003e52:	953a                	add	a0,a0,a4
    80003e54:	ffffe097          	auipc	ra,0xffffe
    80003e58:	726080e7          	jalr	1830(ra) # 8000257a <either_copyin>
    80003e5c:	07850263          	beq	a0,s8,80003ec0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e60:	8526                	mv	a0,s1
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	75e080e7          	jalr	1886(ra) # 800045c0 <log_write>
    brelse(bp);
    80003e6a:	8526                	mv	a0,s1
    80003e6c:	fffff097          	auipc	ra,0xfffff
    80003e70:	4fc080e7          	jalr	1276(ra) # 80003368 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e74:	013d09bb          	addw	s3,s10,s3
    80003e78:	012d093b          	addw	s2,s10,s2
    80003e7c:	9a6e                	add	s4,s4,s11
    80003e7e:	0569f663          	bgeu	s3,s6,80003eca <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e82:	00a9559b          	srliw	a1,s2,0xa
    80003e86:	8556                	mv	a0,s5
    80003e88:	fffff097          	auipc	ra,0xfffff
    80003e8c:	7a2080e7          	jalr	1954(ra) # 8000362a <bmap>
    80003e90:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e94:	c99d                	beqz	a1,80003eca <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e96:	000aa503          	lw	a0,0(s5)
    80003e9a:	fffff097          	auipc	ra,0xfffff
    80003e9e:	39e080e7          	jalr	926(ra) # 80003238 <bread>
    80003ea2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ea4:	3ff97713          	andi	a4,s2,1023
    80003ea8:	40ec87bb          	subw	a5,s9,a4
    80003eac:	413b06bb          	subw	a3,s6,s3
    80003eb0:	8d3e                	mv	s10,a5
    80003eb2:	2781                	sext.w	a5,a5
    80003eb4:	0006861b          	sext.w	a2,a3
    80003eb8:	f8f674e3          	bgeu	a2,a5,80003e40 <writei+0x4c>
    80003ebc:	8d36                	mv	s10,a3
    80003ebe:	b749                	j	80003e40 <writei+0x4c>
      brelse(bp);
    80003ec0:	8526                	mv	a0,s1
    80003ec2:	fffff097          	auipc	ra,0xfffff
    80003ec6:	4a6080e7          	jalr	1190(ra) # 80003368 <brelse>
  }

  if(off > ip->size)
    80003eca:	04caa783          	lw	a5,76(s5)
    80003ece:	0127f463          	bgeu	a5,s2,80003ed6 <writei+0xe2>
    ip->size = off;
    80003ed2:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ed6:	8556                	mv	a0,s5
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	aa4080e7          	jalr	-1372(ra) # 8000397c <iupdate>

  return tot;
    80003ee0:	0009851b          	sext.w	a0,s3
}
    80003ee4:	70a6                	ld	ra,104(sp)
    80003ee6:	7406                	ld	s0,96(sp)
    80003ee8:	64e6                	ld	s1,88(sp)
    80003eea:	6946                	ld	s2,80(sp)
    80003eec:	69a6                	ld	s3,72(sp)
    80003eee:	6a06                	ld	s4,64(sp)
    80003ef0:	7ae2                	ld	s5,56(sp)
    80003ef2:	7b42                	ld	s6,48(sp)
    80003ef4:	7ba2                	ld	s7,40(sp)
    80003ef6:	7c02                	ld	s8,32(sp)
    80003ef8:	6ce2                	ld	s9,24(sp)
    80003efa:	6d42                	ld	s10,16(sp)
    80003efc:	6da2                	ld	s11,8(sp)
    80003efe:	6165                	addi	sp,sp,112
    80003f00:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f02:	89da                	mv	s3,s6
    80003f04:	bfc9                	j	80003ed6 <writei+0xe2>
    return -1;
    80003f06:	557d                	li	a0,-1
}
    80003f08:	8082                	ret
    return -1;
    80003f0a:	557d                	li	a0,-1
    80003f0c:	bfe1                	j	80003ee4 <writei+0xf0>
    return -1;
    80003f0e:	557d                	li	a0,-1
    80003f10:	bfd1                	j	80003ee4 <writei+0xf0>

0000000080003f12 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f12:	1141                	addi	sp,sp,-16
    80003f14:	e406                	sd	ra,8(sp)
    80003f16:	e022                	sd	s0,0(sp)
    80003f18:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f1a:	4639                	li	a2,14
    80003f1c:	ffffd097          	auipc	ra,0xffffd
    80003f20:	e82080e7          	jalr	-382(ra) # 80000d9e <strncmp>
}
    80003f24:	60a2                	ld	ra,8(sp)
    80003f26:	6402                	ld	s0,0(sp)
    80003f28:	0141                	addi	sp,sp,16
    80003f2a:	8082                	ret

0000000080003f2c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f2c:	7139                	addi	sp,sp,-64
    80003f2e:	fc06                	sd	ra,56(sp)
    80003f30:	f822                	sd	s0,48(sp)
    80003f32:	f426                	sd	s1,40(sp)
    80003f34:	f04a                	sd	s2,32(sp)
    80003f36:	ec4e                	sd	s3,24(sp)
    80003f38:	e852                	sd	s4,16(sp)
    80003f3a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f3c:	04451703          	lh	a4,68(a0)
    80003f40:	4785                	li	a5,1
    80003f42:	00f71a63          	bne	a4,a5,80003f56 <dirlookup+0x2a>
    80003f46:	892a                	mv	s2,a0
    80003f48:	89ae                	mv	s3,a1
    80003f4a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f4c:	457c                	lw	a5,76(a0)
    80003f4e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f50:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f52:	e79d                	bnez	a5,80003f80 <dirlookup+0x54>
    80003f54:	a8a5                	j	80003fcc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f56:	00004517          	auipc	a0,0x4
    80003f5a:	6ba50513          	addi	a0,a0,1722 # 80008610 <syscalls+0x1c0>
    80003f5e:	ffffc097          	auipc	ra,0xffffc
    80003f62:	5de080e7          	jalr	1502(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003f66:	00004517          	auipc	a0,0x4
    80003f6a:	6c250513          	addi	a0,a0,1730 # 80008628 <syscalls+0x1d8>
    80003f6e:	ffffc097          	auipc	ra,0xffffc
    80003f72:	5ce080e7          	jalr	1486(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f76:	24c1                	addiw	s1,s1,16
    80003f78:	04c92783          	lw	a5,76(s2)
    80003f7c:	04f4f763          	bgeu	s1,a5,80003fca <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f80:	4741                	li	a4,16
    80003f82:	86a6                	mv	a3,s1
    80003f84:	fc040613          	addi	a2,s0,-64
    80003f88:	4581                	li	a1,0
    80003f8a:	854a                	mv	a0,s2
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	d70080e7          	jalr	-656(ra) # 80003cfc <readi>
    80003f94:	47c1                	li	a5,16
    80003f96:	fcf518e3          	bne	a0,a5,80003f66 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f9a:	fc045783          	lhu	a5,-64(s0)
    80003f9e:	dfe1                	beqz	a5,80003f76 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003fa0:	fc240593          	addi	a1,s0,-62
    80003fa4:	854e                	mv	a0,s3
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	f6c080e7          	jalr	-148(ra) # 80003f12 <namecmp>
    80003fae:	f561                	bnez	a0,80003f76 <dirlookup+0x4a>
      if(poff)
    80003fb0:	000a0463          	beqz	s4,80003fb8 <dirlookup+0x8c>
        *poff = off;
    80003fb4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fb8:	fc045583          	lhu	a1,-64(s0)
    80003fbc:	00092503          	lw	a0,0(s2)
    80003fc0:	fffff097          	auipc	ra,0xfffff
    80003fc4:	754080e7          	jalr	1876(ra) # 80003714 <iget>
    80003fc8:	a011                	j	80003fcc <dirlookup+0xa0>
  return 0;
    80003fca:	4501                	li	a0,0
}
    80003fcc:	70e2                	ld	ra,56(sp)
    80003fce:	7442                	ld	s0,48(sp)
    80003fd0:	74a2                	ld	s1,40(sp)
    80003fd2:	7902                	ld	s2,32(sp)
    80003fd4:	69e2                	ld	s3,24(sp)
    80003fd6:	6a42                	ld	s4,16(sp)
    80003fd8:	6121                	addi	sp,sp,64
    80003fda:	8082                	ret

0000000080003fdc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fdc:	711d                	addi	sp,sp,-96
    80003fde:	ec86                	sd	ra,88(sp)
    80003fe0:	e8a2                	sd	s0,80(sp)
    80003fe2:	e4a6                	sd	s1,72(sp)
    80003fe4:	e0ca                	sd	s2,64(sp)
    80003fe6:	fc4e                	sd	s3,56(sp)
    80003fe8:	f852                	sd	s4,48(sp)
    80003fea:	f456                	sd	s5,40(sp)
    80003fec:	f05a                	sd	s6,32(sp)
    80003fee:	ec5e                	sd	s7,24(sp)
    80003ff0:	e862                	sd	s8,16(sp)
    80003ff2:	e466                	sd	s9,8(sp)
    80003ff4:	1080                	addi	s0,sp,96
    80003ff6:	84aa                	mv	s1,a0
    80003ff8:	8b2e                	mv	s6,a1
    80003ffa:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ffc:	00054703          	lbu	a4,0(a0)
    80004000:	02f00793          	li	a5,47
    80004004:	02f70263          	beq	a4,a5,80004028 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004008:	ffffe097          	auipc	ra,0xffffe
    8000400c:	99e080e7          	jalr	-1634(ra) # 800019a6 <myproc>
    80004010:	15053503          	ld	a0,336(a0)
    80004014:	00000097          	auipc	ra,0x0
    80004018:	9f6080e7          	jalr	-1546(ra) # 80003a0a <idup>
    8000401c:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000401e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004022:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004024:	4b85                	li	s7,1
    80004026:	a875                	j	800040e2 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004028:	4585                	li	a1,1
    8000402a:	4505                	li	a0,1
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	6e8080e7          	jalr	1768(ra) # 80003714 <iget>
    80004034:	8a2a                	mv	s4,a0
    80004036:	b7e5                	j	8000401e <namex+0x42>
      iunlockput(ip);
    80004038:	8552                	mv	a0,s4
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	c70080e7          	jalr	-912(ra) # 80003caa <iunlockput>
      return 0;
    80004042:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004044:	8552                	mv	a0,s4
    80004046:	60e6                	ld	ra,88(sp)
    80004048:	6446                	ld	s0,80(sp)
    8000404a:	64a6                	ld	s1,72(sp)
    8000404c:	6906                	ld	s2,64(sp)
    8000404e:	79e2                	ld	s3,56(sp)
    80004050:	7a42                	ld	s4,48(sp)
    80004052:	7aa2                	ld	s5,40(sp)
    80004054:	7b02                	ld	s6,32(sp)
    80004056:	6be2                	ld	s7,24(sp)
    80004058:	6c42                	ld	s8,16(sp)
    8000405a:	6ca2                	ld	s9,8(sp)
    8000405c:	6125                	addi	sp,sp,96
    8000405e:	8082                	ret
      iunlock(ip);
    80004060:	8552                	mv	a0,s4
    80004062:	00000097          	auipc	ra,0x0
    80004066:	aa8080e7          	jalr	-1368(ra) # 80003b0a <iunlock>
      return ip;
    8000406a:	bfe9                	j	80004044 <namex+0x68>
      iunlockput(ip);
    8000406c:	8552                	mv	a0,s4
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	c3c080e7          	jalr	-964(ra) # 80003caa <iunlockput>
      return 0;
    80004076:	8a4e                	mv	s4,s3
    80004078:	b7f1                	j	80004044 <namex+0x68>
  len = path - s;
    8000407a:	40998633          	sub	a2,s3,s1
    8000407e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004082:	099c5863          	bge	s8,s9,80004112 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004086:	4639                	li	a2,14
    80004088:	85a6                	mv	a1,s1
    8000408a:	8556                	mv	a0,s5
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	c9e080e7          	jalr	-866(ra) # 80000d2a <memmove>
    80004094:	84ce                	mv	s1,s3
  while(*path == '/')
    80004096:	0004c783          	lbu	a5,0(s1)
    8000409a:	01279763          	bne	a5,s2,800040a8 <namex+0xcc>
    path++;
    8000409e:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040a0:	0004c783          	lbu	a5,0(s1)
    800040a4:	ff278de3          	beq	a5,s2,8000409e <namex+0xc2>
    ilock(ip);
    800040a8:	8552                	mv	a0,s4
    800040aa:	00000097          	auipc	ra,0x0
    800040ae:	99e080e7          	jalr	-1634(ra) # 80003a48 <ilock>
    if(ip->type != T_DIR){
    800040b2:	044a1783          	lh	a5,68(s4)
    800040b6:	f97791e3          	bne	a5,s7,80004038 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800040ba:	000b0563          	beqz	s6,800040c4 <namex+0xe8>
    800040be:	0004c783          	lbu	a5,0(s1)
    800040c2:	dfd9                	beqz	a5,80004060 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040c4:	4601                	li	a2,0
    800040c6:	85d6                	mv	a1,s5
    800040c8:	8552                	mv	a0,s4
    800040ca:	00000097          	auipc	ra,0x0
    800040ce:	e62080e7          	jalr	-414(ra) # 80003f2c <dirlookup>
    800040d2:	89aa                	mv	s3,a0
    800040d4:	dd41                	beqz	a0,8000406c <namex+0x90>
    iunlockput(ip);
    800040d6:	8552                	mv	a0,s4
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	bd2080e7          	jalr	-1070(ra) # 80003caa <iunlockput>
    ip = next;
    800040e0:	8a4e                	mv	s4,s3
  while(*path == '/')
    800040e2:	0004c783          	lbu	a5,0(s1)
    800040e6:	01279763          	bne	a5,s2,800040f4 <namex+0x118>
    path++;
    800040ea:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040ec:	0004c783          	lbu	a5,0(s1)
    800040f0:	ff278de3          	beq	a5,s2,800040ea <namex+0x10e>
  if(*path == 0)
    800040f4:	cb9d                	beqz	a5,8000412a <namex+0x14e>
  while(*path != '/' && *path != 0)
    800040f6:	0004c783          	lbu	a5,0(s1)
    800040fa:	89a6                	mv	s3,s1
  len = path - s;
    800040fc:	4c81                	li	s9,0
    800040fe:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004100:	01278963          	beq	a5,s2,80004112 <namex+0x136>
    80004104:	dbbd                	beqz	a5,8000407a <namex+0x9e>
    path++;
    80004106:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004108:	0009c783          	lbu	a5,0(s3)
    8000410c:	ff279ce3          	bne	a5,s2,80004104 <namex+0x128>
    80004110:	b7ad                	j	8000407a <namex+0x9e>
    memmove(name, s, len);
    80004112:	2601                	sext.w	a2,a2
    80004114:	85a6                	mv	a1,s1
    80004116:	8556                	mv	a0,s5
    80004118:	ffffd097          	auipc	ra,0xffffd
    8000411c:	c12080e7          	jalr	-1006(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004120:	9cd6                	add	s9,s9,s5
    80004122:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004126:	84ce                	mv	s1,s3
    80004128:	b7bd                	j	80004096 <namex+0xba>
  if(nameiparent){
    8000412a:	f00b0de3          	beqz	s6,80004044 <namex+0x68>
    iput(ip);
    8000412e:	8552                	mv	a0,s4
    80004130:	00000097          	auipc	ra,0x0
    80004134:	ad2080e7          	jalr	-1326(ra) # 80003c02 <iput>
    return 0;
    80004138:	4a01                	li	s4,0
    8000413a:	b729                	j	80004044 <namex+0x68>

000000008000413c <dirlink>:
{
    8000413c:	7139                	addi	sp,sp,-64
    8000413e:	fc06                	sd	ra,56(sp)
    80004140:	f822                	sd	s0,48(sp)
    80004142:	f426                	sd	s1,40(sp)
    80004144:	f04a                	sd	s2,32(sp)
    80004146:	ec4e                	sd	s3,24(sp)
    80004148:	e852                	sd	s4,16(sp)
    8000414a:	0080                	addi	s0,sp,64
    8000414c:	892a                	mv	s2,a0
    8000414e:	8a2e                	mv	s4,a1
    80004150:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004152:	4601                	li	a2,0
    80004154:	00000097          	auipc	ra,0x0
    80004158:	dd8080e7          	jalr	-552(ra) # 80003f2c <dirlookup>
    8000415c:	e93d                	bnez	a0,800041d2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000415e:	04c92483          	lw	s1,76(s2)
    80004162:	c49d                	beqz	s1,80004190 <dirlink+0x54>
    80004164:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004166:	4741                	li	a4,16
    80004168:	86a6                	mv	a3,s1
    8000416a:	fc040613          	addi	a2,s0,-64
    8000416e:	4581                	li	a1,0
    80004170:	854a                	mv	a0,s2
    80004172:	00000097          	auipc	ra,0x0
    80004176:	b8a080e7          	jalr	-1142(ra) # 80003cfc <readi>
    8000417a:	47c1                	li	a5,16
    8000417c:	06f51163          	bne	a0,a5,800041de <dirlink+0xa2>
    if(de.inum == 0)
    80004180:	fc045783          	lhu	a5,-64(s0)
    80004184:	c791                	beqz	a5,80004190 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004186:	24c1                	addiw	s1,s1,16
    80004188:	04c92783          	lw	a5,76(s2)
    8000418c:	fcf4ede3          	bltu	s1,a5,80004166 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004190:	4639                	li	a2,14
    80004192:	85d2                	mv	a1,s4
    80004194:	fc240513          	addi	a0,s0,-62
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	c42080e7          	jalr	-958(ra) # 80000dda <strncpy>
  de.inum = inum;
    800041a0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041a4:	4741                	li	a4,16
    800041a6:	86a6                	mv	a3,s1
    800041a8:	fc040613          	addi	a2,s0,-64
    800041ac:	4581                	li	a1,0
    800041ae:	854a                	mv	a0,s2
    800041b0:	00000097          	auipc	ra,0x0
    800041b4:	c44080e7          	jalr	-956(ra) # 80003df4 <writei>
    800041b8:	1541                	addi	a0,a0,-16
    800041ba:	00a03533          	snez	a0,a0
    800041be:	40a00533          	neg	a0,a0
}
    800041c2:	70e2                	ld	ra,56(sp)
    800041c4:	7442                	ld	s0,48(sp)
    800041c6:	74a2                	ld	s1,40(sp)
    800041c8:	7902                	ld	s2,32(sp)
    800041ca:	69e2                	ld	s3,24(sp)
    800041cc:	6a42                	ld	s4,16(sp)
    800041ce:	6121                	addi	sp,sp,64
    800041d0:	8082                	ret
    iput(ip);
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	a30080e7          	jalr	-1488(ra) # 80003c02 <iput>
    return -1;
    800041da:	557d                	li	a0,-1
    800041dc:	b7dd                	j	800041c2 <dirlink+0x86>
      panic("dirlink read");
    800041de:	00004517          	auipc	a0,0x4
    800041e2:	45a50513          	addi	a0,a0,1114 # 80008638 <syscalls+0x1e8>
    800041e6:	ffffc097          	auipc	ra,0xffffc
    800041ea:	356080e7          	jalr	854(ra) # 8000053c <panic>

00000000800041ee <namei>:

struct inode*
namei(char *path)
{
    800041ee:	1101                	addi	sp,sp,-32
    800041f0:	ec06                	sd	ra,24(sp)
    800041f2:	e822                	sd	s0,16(sp)
    800041f4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041f6:	fe040613          	addi	a2,s0,-32
    800041fa:	4581                	li	a1,0
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	de0080e7          	jalr	-544(ra) # 80003fdc <namex>
}
    80004204:	60e2                	ld	ra,24(sp)
    80004206:	6442                	ld	s0,16(sp)
    80004208:	6105                	addi	sp,sp,32
    8000420a:	8082                	ret

000000008000420c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000420c:	1141                	addi	sp,sp,-16
    8000420e:	e406                	sd	ra,8(sp)
    80004210:	e022                	sd	s0,0(sp)
    80004212:	0800                	addi	s0,sp,16
    80004214:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004216:	4585                	li	a1,1
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	dc4080e7          	jalr	-572(ra) # 80003fdc <namex>
}
    80004220:	60a2                	ld	ra,8(sp)
    80004222:	6402                	ld	s0,0(sp)
    80004224:	0141                	addi	sp,sp,16
    80004226:	8082                	ret

0000000080004228 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004228:	1101                	addi	sp,sp,-32
    8000422a:	ec06                	sd	ra,24(sp)
    8000422c:	e822                	sd	s0,16(sp)
    8000422e:	e426                	sd	s1,8(sp)
    80004230:	e04a                	sd	s2,0(sp)
    80004232:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004234:	0001d917          	auipc	s2,0x1d
    80004238:	30c90913          	addi	s2,s2,780 # 80021540 <log>
    8000423c:	01892583          	lw	a1,24(s2)
    80004240:	02892503          	lw	a0,40(s2)
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	ff4080e7          	jalr	-12(ra) # 80003238 <bread>
    8000424c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000424e:	02c92603          	lw	a2,44(s2)
    80004252:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004254:	00c05f63          	blez	a2,80004272 <write_head+0x4a>
    80004258:	0001d717          	auipc	a4,0x1d
    8000425c:	31870713          	addi	a4,a4,792 # 80021570 <log+0x30>
    80004260:	87aa                	mv	a5,a0
    80004262:	060a                	slli	a2,a2,0x2
    80004264:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004266:	4314                	lw	a3,0(a4)
    80004268:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000426a:	0711                	addi	a4,a4,4
    8000426c:	0791                	addi	a5,a5,4
    8000426e:	fec79ce3          	bne	a5,a2,80004266 <write_head+0x3e>
  }
  bwrite(buf);
    80004272:	8526                	mv	a0,s1
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	0b6080e7          	jalr	182(ra) # 8000332a <bwrite>
  brelse(buf);
    8000427c:	8526                	mv	a0,s1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	0ea080e7          	jalr	234(ra) # 80003368 <brelse>
}
    80004286:	60e2                	ld	ra,24(sp)
    80004288:	6442                	ld	s0,16(sp)
    8000428a:	64a2                	ld	s1,8(sp)
    8000428c:	6902                	ld	s2,0(sp)
    8000428e:	6105                	addi	sp,sp,32
    80004290:	8082                	ret

0000000080004292 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004292:	0001d797          	auipc	a5,0x1d
    80004296:	2da7a783          	lw	a5,730(a5) # 8002156c <log+0x2c>
    8000429a:	0af05d63          	blez	a5,80004354 <install_trans+0xc2>
{
    8000429e:	7139                	addi	sp,sp,-64
    800042a0:	fc06                	sd	ra,56(sp)
    800042a2:	f822                	sd	s0,48(sp)
    800042a4:	f426                	sd	s1,40(sp)
    800042a6:	f04a                	sd	s2,32(sp)
    800042a8:	ec4e                	sd	s3,24(sp)
    800042aa:	e852                	sd	s4,16(sp)
    800042ac:	e456                	sd	s5,8(sp)
    800042ae:	e05a                	sd	s6,0(sp)
    800042b0:	0080                	addi	s0,sp,64
    800042b2:	8b2a                	mv	s6,a0
    800042b4:	0001da97          	auipc	s5,0x1d
    800042b8:	2bca8a93          	addi	s5,s5,700 # 80021570 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042bc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042be:	0001d997          	auipc	s3,0x1d
    800042c2:	28298993          	addi	s3,s3,642 # 80021540 <log>
    800042c6:	a00d                	j	800042e8 <install_trans+0x56>
    brelse(lbuf);
    800042c8:	854a                	mv	a0,s2
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	09e080e7          	jalr	158(ra) # 80003368 <brelse>
    brelse(dbuf);
    800042d2:	8526                	mv	a0,s1
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	094080e7          	jalr	148(ra) # 80003368 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042dc:	2a05                	addiw	s4,s4,1
    800042de:	0a91                	addi	s5,s5,4
    800042e0:	02c9a783          	lw	a5,44(s3)
    800042e4:	04fa5e63          	bge	s4,a5,80004340 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042e8:	0189a583          	lw	a1,24(s3)
    800042ec:	014585bb          	addw	a1,a1,s4
    800042f0:	2585                	addiw	a1,a1,1
    800042f2:	0289a503          	lw	a0,40(s3)
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	f42080e7          	jalr	-190(ra) # 80003238 <bread>
    800042fe:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004300:	000aa583          	lw	a1,0(s5)
    80004304:	0289a503          	lw	a0,40(s3)
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	f30080e7          	jalr	-208(ra) # 80003238 <bread>
    80004310:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004312:	40000613          	li	a2,1024
    80004316:	05890593          	addi	a1,s2,88
    8000431a:	05850513          	addi	a0,a0,88
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	a0c080e7          	jalr	-1524(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004326:	8526                	mv	a0,s1
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	002080e7          	jalr	2(ra) # 8000332a <bwrite>
    if(recovering == 0)
    80004330:	f80b1ce3          	bnez	s6,800042c8 <install_trans+0x36>
      bunpin(dbuf);
    80004334:	8526                	mv	a0,s1
    80004336:	fffff097          	auipc	ra,0xfffff
    8000433a:	10a080e7          	jalr	266(ra) # 80003440 <bunpin>
    8000433e:	b769                	j	800042c8 <install_trans+0x36>
}
    80004340:	70e2                	ld	ra,56(sp)
    80004342:	7442                	ld	s0,48(sp)
    80004344:	74a2                	ld	s1,40(sp)
    80004346:	7902                	ld	s2,32(sp)
    80004348:	69e2                	ld	s3,24(sp)
    8000434a:	6a42                	ld	s4,16(sp)
    8000434c:	6aa2                	ld	s5,8(sp)
    8000434e:	6b02                	ld	s6,0(sp)
    80004350:	6121                	addi	sp,sp,64
    80004352:	8082                	ret
    80004354:	8082                	ret

0000000080004356 <initlog>:
{
    80004356:	7179                	addi	sp,sp,-48
    80004358:	f406                	sd	ra,40(sp)
    8000435a:	f022                	sd	s0,32(sp)
    8000435c:	ec26                	sd	s1,24(sp)
    8000435e:	e84a                	sd	s2,16(sp)
    80004360:	e44e                	sd	s3,8(sp)
    80004362:	1800                	addi	s0,sp,48
    80004364:	892a                	mv	s2,a0
    80004366:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004368:	0001d497          	auipc	s1,0x1d
    8000436c:	1d848493          	addi	s1,s1,472 # 80021540 <log>
    80004370:	00004597          	auipc	a1,0x4
    80004374:	2d858593          	addi	a1,a1,728 # 80008648 <syscalls+0x1f8>
    80004378:	8526                	mv	a0,s1
    8000437a:	ffffc097          	auipc	ra,0xffffc
    8000437e:	7c8080e7          	jalr	1992(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004382:	0149a583          	lw	a1,20(s3)
    80004386:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004388:	0109a783          	lw	a5,16(s3)
    8000438c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000438e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004392:	854a                	mv	a0,s2
    80004394:	fffff097          	auipc	ra,0xfffff
    80004398:	ea4080e7          	jalr	-348(ra) # 80003238 <bread>
  log.lh.n = lh->n;
    8000439c:	4d30                	lw	a2,88(a0)
    8000439e:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043a0:	00c05f63          	blez	a2,800043be <initlog+0x68>
    800043a4:	87aa                	mv	a5,a0
    800043a6:	0001d717          	auipc	a4,0x1d
    800043aa:	1ca70713          	addi	a4,a4,458 # 80021570 <log+0x30>
    800043ae:	060a                	slli	a2,a2,0x2
    800043b0:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800043b2:	4ff4                	lw	a3,92(a5)
    800043b4:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043b6:	0791                	addi	a5,a5,4
    800043b8:	0711                	addi	a4,a4,4
    800043ba:	fec79ce3          	bne	a5,a2,800043b2 <initlog+0x5c>
  brelse(buf);
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	faa080e7          	jalr	-86(ra) # 80003368 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043c6:	4505                	li	a0,1
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	eca080e7          	jalr	-310(ra) # 80004292 <install_trans>
  log.lh.n = 0;
    800043d0:	0001d797          	auipc	a5,0x1d
    800043d4:	1807ae23          	sw	zero,412(a5) # 8002156c <log+0x2c>
  write_head(); // clear the log
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	e50080e7          	jalr	-432(ra) # 80004228 <write_head>
}
    800043e0:	70a2                	ld	ra,40(sp)
    800043e2:	7402                	ld	s0,32(sp)
    800043e4:	64e2                	ld	s1,24(sp)
    800043e6:	6942                	ld	s2,16(sp)
    800043e8:	69a2                	ld	s3,8(sp)
    800043ea:	6145                	addi	sp,sp,48
    800043ec:	8082                	ret

00000000800043ee <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043ee:	1101                	addi	sp,sp,-32
    800043f0:	ec06                	sd	ra,24(sp)
    800043f2:	e822                	sd	s0,16(sp)
    800043f4:	e426                	sd	s1,8(sp)
    800043f6:	e04a                	sd	s2,0(sp)
    800043f8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043fa:	0001d517          	auipc	a0,0x1d
    800043fe:	14650513          	addi	a0,a0,326 # 80021540 <log>
    80004402:	ffffc097          	auipc	ra,0xffffc
    80004406:	7d0080e7          	jalr	2000(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    8000440a:	0001d497          	auipc	s1,0x1d
    8000440e:	13648493          	addi	s1,s1,310 # 80021540 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004412:	4979                	li	s2,30
    80004414:	a039                	j	80004422 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004416:	85a6                	mv	a1,s1
    80004418:	8526                	mv	a0,s1
    8000441a:	ffffe097          	auipc	ra,0xffffe
    8000441e:	cf6080e7          	jalr	-778(ra) # 80002110 <sleep>
    if(log.committing){
    80004422:	50dc                	lw	a5,36(s1)
    80004424:	fbed                	bnez	a5,80004416 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004426:	5098                	lw	a4,32(s1)
    80004428:	2705                	addiw	a4,a4,1
    8000442a:	0027179b          	slliw	a5,a4,0x2
    8000442e:	9fb9                	addw	a5,a5,a4
    80004430:	0017979b          	slliw	a5,a5,0x1
    80004434:	54d4                	lw	a3,44(s1)
    80004436:	9fb5                	addw	a5,a5,a3
    80004438:	00f95963          	bge	s2,a5,8000444a <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000443c:	85a6                	mv	a1,s1
    8000443e:	8526                	mv	a0,s1
    80004440:	ffffe097          	auipc	ra,0xffffe
    80004444:	cd0080e7          	jalr	-816(ra) # 80002110 <sleep>
    80004448:	bfe9                	j	80004422 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000444a:	0001d517          	auipc	a0,0x1d
    8000444e:	0f650513          	addi	a0,a0,246 # 80021540 <log>
    80004452:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	832080e7          	jalr	-1998(ra) # 80000c86 <release>
      break;
    }
  }
}
    8000445c:	60e2                	ld	ra,24(sp)
    8000445e:	6442                	ld	s0,16(sp)
    80004460:	64a2                	ld	s1,8(sp)
    80004462:	6902                	ld	s2,0(sp)
    80004464:	6105                	addi	sp,sp,32
    80004466:	8082                	ret

0000000080004468 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004468:	7139                	addi	sp,sp,-64
    8000446a:	fc06                	sd	ra,56(sp)
    8000446c:	f822                	sd	s0,48(sp)
    8000446e:	f426                	sd	s1,40(sp)
    80004470:	f04a                	sd	s2,32(sp)
    80004472:	ec4e                	sd	s3,24(sp)
    80004474:	e852                	sd	s4,16(sp)
    80004476:	e456                	sd	s5,8(sp)
    80004478:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000447a:	0001d497          	auipc	s1,0x1d
    8000447e:	0c648493          	addi	s1,s1,198 # 80021540 <log>
    80004482:	8526                	mv	a0,s1
    80004484:	ffffc097          	auipc	ra,0xffffc
    80004488:	74e080e7          	jalr	1870(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    8000448c:	509c                	lw	a5,32(s1)
    8000448e:	37fd                	addiw	a5,a5,-1
    80004490:	0007891b          	sext.w	s2,a5
    80004494:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004496:	50dc                	lw	a5,36(s1)
    80004498:	e7b9                	bnez	a5,800044e6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000449a:	04091e63          	bnez	s2,800044f6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000449e:	0001d497          	auipc	s1,0x1d
    800044a2:	0a248493          	addi	s1,s1,162 # 80021540 <log>
    800044a6:	4785                	li	a5,1
    800044a8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044aa:	8526                	mv	a0,s1
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	7da080e7          	jalr	2010(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044b4:	54dc                	lw	a5,44(s1)
    800044b6:	06f04763          	bgtz	a5,80004524 <end_op+0xbc>
    acquire(&log.lock);
    800044ba:	0001d497          	auipc	s1,0x1d
    800044be:	08648493          	addi	s1,s1,134 # 80021540 <log>
    800044c2:	8526                	mv	a0,s1
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	70e080e7          	jalr	1806(ra) # 80000bd2 <acquire>
    log.committing = 0;
    800044cc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044d0:	8526                	mv	a0,s1
    800044d2:	ffffe097          	auipc	ra,0xffffe
    800044d6:	ca2080e7          	jalr	-862(ra) # 80002174 <wakeup>
    release(&log.lock);
    800044da:	8526                	mv	a0,s1
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	7aa080e7          	jalr	1962(ra) # 80000c86 <release>
}
    800044e4:	a03d                	j	80004512 <end_op+0xaa>
    panic("log.committing");
    800044e6:	00004517          	auipc	a0,0x4
    800044ea:	16a50513          	addi	a0,a0,362 # 80008650 <syscalls+0x200>
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	04e080e7          	jalr	78(ra) # 8000053c <panic>
    wakeup(&log);
    800044f6:	0001d497          	auipc	s1,0x1d
    800044fa:	04a48493          	addi	s1,s1,74 # 80021540 <log>
    800044fe:	8526                	mv	a0,s1
    80004500:	ffffe097          	auipc	ra,0xffffe
    80004504:	c74080e7          	jalr	-908(ra) # 80002174 <wakeup>
  release(&log.lock);
    80004508:	8526                	mv	a0,s1
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	77c080e7          	jalr	1916(ra) # 80000c86 <release>
}
    80004512:	70e2                	ld	ra,56(sp)
    80004514:	7442                	ld	s0,48(sp)
    80004516:	74a2                	ld	s1,40(sp)
    80004518:	7902                	ld	s2,32(sp)
    8000451a:	69e2                	ld	s3,24(sp)
    8000451c:	6a42                	ld	s4,16(sp)
    8000451e:	6aa2                	ld	s5,8(sp)
    80004520:	6121                	addi	sp,sp,64
    80004522:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004524:	0001da97          	auipc	s5,0x1d
    80004528:	04ca8a93          	addi	s5,s5,76 # 80021570 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000452c:	0001da17          	auipc	s4,0x1d
    80004530:	014a0a13          	addi	s4,s4,20 # 80021540 <log>
    80004534:	018a2583          	lw	a1,24(s4)
    80004538:	012585bb          	addw	a1,a1,s2
    8000453c:	2585                	addiw	a1,a1,1
    8000453e:	028a2503          	lw	a0,40(s4)
    80004542:	fffff097          	auipc	ra,0xfffff
    80004546:	cf6080e7          	jalr	-778(ra) # 80003238 <bread>
    8000454a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000454c:	000aa583          	lw	a1,0(s5)
    80004550:	028a2503          	lw	a0,40(s4)
    80004554:	fffff097          	auipc	ra,0xfffff
    80004558:	ce4080e7          	jalr	-796(ra) # 80003238 <bread>
    8000455c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000455e:	40000613          	li	a2,1024
    80004562:	05850593          	addi	a1,a0,88
    80004566:	05848513          	addi	a0,s1,88
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	7c0080e7          	jalr	1984(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004572:	8526                	mv	a0,s1
    80004574:	fffff097          	auipc	ra,0xfffff
    80004578:	db6080e7          	jalr	-586(ra) # 8000332a <bwrite>
    brelse(from);
    8000457c:	854e                	mv	a0,s3
    8000457e:	fffff097          	auipc	ra,0xfffff
    80004582:	dea080e7          	jalr	-534(ra) # 80003368 <brelse>
    brelse(to);
    80004586:	8526                	mv	a0,s1
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	de0080e7          	jalr	-544(ra) # 80003368 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004590:	2905                	addiw	s2,s2,1
    80004592:	0a91                	addi	s5,s5,4
    80004594:	02ca2783          	lw	a5,44(s4)
    80004598:	f8f94ee3          	blt	s2,a5,80004534 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000459c:	00000097          	auipc	ra,0x0
    800045a0:	c8c080e7          	jalr	-884(ra) # 80004228 <write_head>
    install_trans(0); // Now install writes to home locations
    800045a4:	4501                	li	a0,0
    800045a6:	00000097          	auipc	ra,0x0
    800045aa:	cec080e7          	jalr	-788(ra) # 80004292 <install_trans>
    log.lh.n = 0;
    800045ae:	0001d797          	auipc	a5,0x1d
    800045b2:	fa07af23          	sw	zero,-66(a5) # 8002156c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045b6:	00000097          	auipc	ra,0x0
    800045ba:	c72080e7          	jalr	-910(ra) # 80004228 <write_head>
    800045be:	bdf5                	j	800044ba <end_op+0x52>

00000000800045c0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045c0:	1101                	addi	sp,sp,-32
    800045c2:	ec06                	sd	ra,24(sp)
    800045c4:	e822                	sd	s0,16(sp)
    800045c6:	e426                	sd	s1,8(sp)
    800045c8:	e04a                	sd	s2,0(sp)
    800045ca:	1000                	addi	s0,sp,32
    800045cc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045ce:	0001d917          	auipc	s2,0x1d
    800045d2:	f7290913          	addi	s2,s2,-142 # 80021540 <log>
    800045d6:	854a                	mv	a0,s2
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	5fa080e7          	jalr	1530(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045e0:	02c92603          	lw	a2,44(s2)
    800045e4:	47f5                	li	a5,29
    800045e6:	06c7c563          	blt	a5,a2,80004650 <log_write+0x90>
    800045ea:	0001d797          	auipc	a5,0x1d
    800045ee:	f727a783          	lw	a5,-142(a5) # 8002155c <log+0x1c>
    800045f2:	37fd                	addiw	a5,a5,-1
    800045f4:	04f65e63          	bge	a2,a5,80004650 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045f8:	0001d797          	auipc	a5,0x1d
    800045fc:	f687a783          	lw	a5,-152(a5) # 80021560 <log+0x20>
    80004600:	06f05063          	blez	a5,80004660 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004604:	4781                	li	a5,0
    80004606:	06c05563          	blez	a2,80004670 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000460a:	44cc                	lw	a1,12(s1)
    8000460c:	0001d717          	auipc	a4,0x1d
    80004610:	f6470713          	addi	a4,a4,-156 # 80021570 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004614:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004616:	4314                	lw	a3,0(a4)
    80004618:	04b68c63          	beq	a3,a1,80004670 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000461c:	2785                	addiw	a5,a5,1
    8000461e:	0711                	addi	a4,a4,4
    80004620:	fef61be3          	bne	a2,a5,80004616 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004624:	0621                	addi	a2,a2,8
    80004626:	060a                	slli	a2,a2,0x2
    80004628:	0001d797          	auipc	a5,0x1d
    8000462c:	f1878793          	addi	a5,a5,-232 # 80021540 <log>
    80004630:	97b2                	add	a5,a5,a2
    80004632:	44d8                	lw	a4,12(s1)
    80004634:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004636:	8526                	mv	a0,s1
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	dcc080e7          	jalr	-564(ra) # 80003404 <bpin>
    log.lh.n++;
    80004640:	0001d717          	auipc	a4,0x1d
    80004644:	f0070713          	addi	a4,a4,-256 # 80021540 <log>
    80004648:	575c                	lw	a5,44(a4)
    8000464a:	2785                	addiw	a5,a5,1
    8000464c:	d75c                	sw	a5,44(a4)
    8000464e:	a82d                	j	80004688 <log_write+0xc8>
    panic("too big a transaction");
    80004650:	00004517          	auipc	a0,0x4
    80004654:	01050513          	addi	a0,a0,16 # 80008660 <syscalls+0x210>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	ee4080e7          	jalr	-284(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004660:	00004517          	auipc	a0,0x4
    80004664:	01850513          	addi	a0,a0,24 # 80008678 <syscalls+0x228>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	ed4080e7          	jalr	-300(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004670:	00878693          	addi	a3,a5,8
    80004674:	068a                	slli	a3,a3,0x2
    80004676:	0001d717          	auipc	a4,0x1d
    8000467a:	eca70713          	addi	a4,a4,-310 # 80021540 <log>
    8000467e:	9736                	add	a4,a4,a3
    80004680:	44d4                	lw	a3,12(s1)
    80004682:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004684:	faf609e3          	beq	a2,a5,80004636 <log_write+0x76>
  }
  release(&log.lock);
    80004688:	0001d517          	auipc	a0,0x1d
    8000468c:	eb850513          	addi	a0,a0,-328 # 80021540 <log>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	5f6080e7          	jalr	1526(ra) # 80000c86 <release>
}
    80004698:	60e2                	ld	ra,24(sp)
    8000469a:	6442                	ld	s0,16(sp)
    8000469c:	64a2                	ld	s1,8(sp)
    8000469e:	6902                	ld	s2,0(sp)
    800046a0:	6105                	addi	sp,sp,32
    800046a2:	8082                	ret

00000000800046a4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046a4:	1101                	addi	sp,sp,-32
    800046a6:	ec06                	sd	ra,24(sp)
    800046a8:	e822                	sd	s0,16(sp)
    800046aa:	e426                	sd	s1,8(sp)
    800046ac:	e04a                	sd	s2,0(sp)
    800046ae:	1000                	addi	s0,sp,32
    800046b0:	84aa                	mv	s1,a0
    800046b2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046b4:	00004597          	auipc	a1,0x4
    800046b8:	fe458593          	addi	a1,a1,-28 # 80008698 <syscalls+0x248>
    800046bc:	0521                	addi	a0,a0,8
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	484080e7          	jalr	1156(ra) # 80000b42 <initlock>
  lk->name = name;
    800046c6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046ca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ce:	0204a423          	sw	zero,40(s1)
}
    800046d2:	60e2                	ld	ra,24(sp)
    800046d4:	6442                	ld	s0,16(sp)
    800046d6:	64a2                	ld	s1,8(sp)
    800046d8:	6902                	ld	s2,0(sp)
    800046da:	6105                	addi	sp,sp,32
    800046dc:	8082                	ret

00000000800046de <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046de:	1101                	addi	sp,sp,-32
    800046e0:	ec06                	sd	ra,24(sp)
    800046e2:	e822                	sd	s0,16(sp)
    800046e4:	e426                	sd	s1,8(sp)
    800046e6:	e04a                	sd	s2,0(sp)
    800046e8:	1000                	addi	s0,sp,32
    800046ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046ec:	00850913          	addi	s2,a0,8
    800046f0:	854a                	mv	a0,s2
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	4e0080e7          	jalr	1248(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    800046fa:	409c                	lw	a5,0(s1)
    800046fc:	cb89                	beqz	a5,8000470e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046fe:	85ca                	mv	a1,s2
    80004700:	8526                	mv	a0,s1
    80004702:	ffffe097          	auipc	ra,0xffffe
    80004706:	a0e080e7          	jalr	-1522(ra) # 80002110 <sleep>
  while (lk->locked) {
    8000470a:	409c                	lw	a5,0(s1)
    8000470c:	fbed                	bnez	a5,800046fe <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000470e:	4785                	li	a5,1
    80004710:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004712:	ffffd097          	auipc	ra,0xffffd
    80004716:	294080e7          	jalr	660(ra) # 800019a6 <myproc>
    8000471a:	591c                	lw	a5,48(a0)
    8000471c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000471e:	854a                	mv	a0,s2
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	566080e7          	jalr	1382(ra) # 80000c86 <release>
}
    80004728:	60e2                	ld	ra,24(sp)
    8000472a:	6442                	ld	s0,16(sp)
    8000472c:	64a2                	ld	s1,8(sp)
    8000472e:	6902                	ld	s2,0(sp)
    80004730:	6105                	addi	sp,sp,32
    80004732:	8082                	ret

0000000080004734 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004734:	1101                	addi	sp,sp,-32
    80004736:	ec06                	sd	ra,24(sp)
    80004738:	e822                	sd	s0,16(sp)
    8000473a:	e426                	sd	s1,8(sp)
    8000473c:	e04a                	sd	s2,0(sp)
    8000473e:	1000                	addi	s0,sp,32
    80004740:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004742:	00850913          	addi	s2,a0,8
    80004746:	854a                	mv	a0,s2
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	48a080e7          	jalr	1162(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004750:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004754:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004758:	8526                	mv	a0,s1
    8000475a:	ffffe097          	auipc	ra,0xffffe
    8000475e:	a1a080e7          	jalr	-1510(ra) # 80002174 <wakeup>
  release(&lk->lk);
    80004762:	854a                	mv	a0,s2
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	522080e7          	jalr	1314(ra) # 80000c86 <release>
}
    8000476c:	60e2                	ld	ra,24(sp)
    8000476e:	6442                	ld	s0,16(sp)
    80004770:	64a2                	ld	s1,8(sp)
    80004772:	6902                	ld	s2,0(sp)
    80004774:	6105                	addi	sp,sp,32
    80004776:	8082                	ret

0000000080004778 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004778:	7179                	addi	sp,sp,-48
    8000477a:	f406                	sd	ra,40(sp)
    8000477c:	f022                	sd	s0,32(sp)
    8000477e:	ec26                	sd	s1,24(sp)
    80004780:	e84a                	sd	s2,16(sp)
    80004782:	e44e                	sd	s3,8(sp)
    80004784:	1800                	addi	s0,sp,48
    80004786:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004788:	00850913          	addi	s2,a0,8
    8000478c:	854a                	mv	a0,s2
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	444080e7          	jalr	1092(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004796:	409c                	lw	a5,0(s1)
    80004798:	ef99                	bnez	a5,800047b6 <holdingsleep+0x3e>
    8000479a:	4481                	li	s1,0
  release(&lk->lk);
    8000479c:	854a                	mv	a0,s2
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	4e8080e7          	jalr	1256(ra) # 80000c86 <release>
  return r;
}
    800047a6:	8526                	mv	a0,s1
    800047a8:	70a2                	ld	ra,40(sp)
    800047aa:	7402                	ld	s0,32(sp)
    800047ac:	64e2                	ld	s1,24(sp)
    800047ae:	6942                	ld	s2,16(sp)
    800047b0:	69a2                	ld	s3,8(sp)
    800047b2:	6145                	addi	sp,sp,48
    800047b4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047b6:	0284a983          	lw	s3,40(s1)
    800047ba:	ffffd097          	auipc	ra,0xffffd
    800047be:	1ec080e7          	jalr	492(ra) # 800019a6 <myproc>
    800047c2:	5904                	lw	s1,48(a0)
    800047c4:	413484b3          	sub	s1,s1,s3
    800047c8:	0014b493          	seqz	s1,s1
    800047cc:	bfc1                	j	8000479c <holdingsleep+0x24>

00000000800047ce <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047ce:	1141                	addi	sp,sp,-16
    800047d0:	e406                	sd	ra,8(sp)
    800047d2:	e022                	sd	s0,0(sp)
    800047d4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047d6:	00004597          	auipc	a1,0x4
    800047da:	ed258593          	addi	a1,a1,-302 # 800086a8 <syscalls+0x258>
    800047de:	0001d517          	auipc	a0,0x1d
    800047e2:	eaa50513          	addi	a0,a0,-342 # 80021688 <ftable>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	35c080e7          	jalr	860(ra) # 80000b42 <initlock>
}
    800047ee:	60a2                	ld	ra,8(sp)
    800047f0:	6402                	ld	s0,0(sp)
    800047f2:	0141                	addi	sp,sp,16
    800047f4:	8082                	ret

00000000800047f6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047f6:	1101                	addi	sp,sp,-32
    800047f8:	ec06                	sd	ra,24(sp)
    800047fa:	e822                	sd	s0,16(sp)
    800047fc:	e426                	sd	s1,8(sp)
    800047fe:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004800:	0001d517          	auipc	a0,0x1d
    80004804:	e8850513          	addi	a0,a0,-376 # 80021688 <ftable>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	3ca080e7          	jalr	970(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004810:	0001d497          	auipc	s1,0x1d
    80004814:	e9048493          	addi	s1,s1,-368 # 800216a0 <ftable+0x18>
    80004818:	0001e717          	auipc	a4,0x1e
    8000481c:	e2870713          	addi	a4,a4,-472 # 80022640 <disk>
    if(f->ref == 0){
    80004820:	40dc                	lw	a5,4(s1)
    80004822:	cf99                	beqz	a5,80004840 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004824:	02848493          	addi	s1,s1,40
    80004828:	fee49ce3          	bne	s1,a4,80004820 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000482c:	0001d517          	auipc	a0,0x1d
    80004830:	e5c50513          	addi	a0,a0,-420 # 80021688 <ftable>
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	452080e7          	jalr	1106(ra) # 80000c86 <release>
  return 0;
    8000483c:	4481                	li	s1,0
    8000483e:	a819                	j	80004854 <filealloc+0x5e>
      f->ref = 1;
    80004840:	4785                	li	a5,1
    80004842:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004844:	0001d517          	auipc	a0,0x1d
    80004848:	e4450513          	addi	a0,a0,-444 # 80021688 <ftable>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	43a080e7          	jalr	1082(ra) # 80000c86 <release>
}
    80004854:	8526                	mv	a0,s1
    80004856:	60e2                	ld	ra,24(sp)
    80004858:	6442                	ld	s0,16(sp)
    8000485a:	64a2                	ld	s1,8(sp)
    8000485c:	6105                	addi	sp,sp,32
    8000485e:	8082                	ret

0000000080004860 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004860:	1101                	addi	sp,sp,-32
    80004862:	ec06                	sd	ra,24(sp)
    80004864:	e822                	sd	s0,16(sp)
    80004866:	e426                	sd	s1,8(sp)
    80004868:	1000                	addi	s0,sp,32
    8000486a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000486c:	0001d517          	auipc	a0,0x1d
    80004870:	e1c50513          	addi	a0,a0,-484 # 80021688 <ftable>
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	35e080e7          	jalr	862(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000487c:	40dc                	lw	a5,4(s1)
    8000487e:	02f05263          	blez	a5,800048a2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004882:	2785                	addiw	a5,a5,1
    80004884:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004886:	0001d517          	auipc	a0,0x1d
    8000488a:	e0250513          	addi	a0,a0,-510 # 80021688 <ftable>
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	3f8080e7          	jalr	1016(ra) # 80000c86 <release>
  return f;
}
    80004896:	8526                	mv	a0,s1
    80004898:	60e2                	ld	ra,24(sp)
    8000489a:	6442                	ld	s0,16(sp)
    8000489c:	64a2                	ld	s1,8(sp)
    8000489e:	6105                	addi	sp,sp,32
    800048a0:	8082                	ret
    panic("filedup");
    800048a2:	00004517          	auipc	a0,0x4
    800048a6:	e0e50513          	addi	a0,a0,-498 # 800086b0 <syscalls+0x260>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	c92080e7          	jalr	-878(ra) # 8000053c <panic>

00000000800048b2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048b2:	7139                	addi	sp,sp,-64
    800048b4:	fc06                	sd	ra,56(sp)
    800048b6:	f822                	sd	s0,48(sp)
    800048b8:	f426                	sd	s1,40(sp)
    800048ba:	f04a                	sd	s2,32(sp)
    800048bc:	ec4e                	sd	s3,24(sp)
    800048be:	e852                	sd	s4,16(sp)
    800048c0:	e456                	sd	s5,8(sp)
    800048c2:	0080                	addi	s0,sp,64
    800048c4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048c6:	0001d517          	auipc	a0,0x1d
    800048ca:	dc250513          	addi	a0,a0,-574 # 80021688 <ftable>
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	304080e7          	jalr	772(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800048d6:	40dc                	lw	a5,4(s1)
    800048d8:	06f05163          	blez	a5,8000493a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048dc:	37fd                	addiw	a5,a5,-1
    800048de:	0007871b          	sext.w	a4,a5
    800048e2:	c0dc                	sw	a5,4(s1)
    800048e4:	06e04363          	bgtz	a4,8000494a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048e8:	0004a903          	lw	s2,0(s1)
    800048ec:	0094ca83          	lbu	s5,9(s1)
    800048f0:	0104ba03          	ld	s4,16(s1)
    800048f4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048f8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048fc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004900:	0001d517          	auipc	a0,0x1d
    80004904:	d8850513          	addi	a0,a0,-632 # 80021688 <ftable>
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	37e080e7          	jalr	894(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004910:	4785                	li	a5,1
    80004912:	04f90d63          	beq	s2,a5,8000496c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004916:	3979                	addiw	s2,s2,-2
    80004918:	4785                	li	a5,1
    8000491a:	0527e063          	bltu	a5,s2,8000495a <fileclose+0xa8>
    begin_op();
    8000491e:	00000097          	auipc	ra,0x0
    80004922:	ad0080e7          	jalr	-1328(ra) # 800043ee <begin_op>
    iput(ff.ip);
    80004926:	854e                	mv	a0,s3
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	2da080e7          	jalr	730(ra) # 80003c02 <iput>
    end_op();
    80004930:	00000097          	auipc	ra,0x0
    80004934:	b38080e7          	jalr	-1224(ra) # 80004468 <end_op>
    80004938:	a00d                	j	8000495a <fileclose+0xa8>
    panic("fileclose");
    8000493a:	00004517          	auipc	a0,0x4
    8000493e:	d7e50513          	addi	a0,a0,-642 # 800086b8 <syscalls+0x268>
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	bfa080e7          	jalr	-1030(ra) # 8000053c <panic>
    release(&ftable.lock);
    8000494a:	0001d517          	auipc	a0,0x1d
    8000494e:	d3e50513          	addi	a0,a0,-706 # 80021688 <ftable>
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	334080e7          	jalr	820(ra) # 80000c86 <release>
  }
}
    8000495a:	70e2                	ld	ra,56(sp)
    8000495c:	7442                	ld	s0,48(sp)
    8000495e:	74a2                	ld	s1,40(sp)
    80004960:	7902                	ld	s2,32(sp)
    80004962:	69e2                	ld	s3,24(sp)
    80004964:	6a42                	ld	s4,16(sp)
    80004966:	6aa2                	ld	s5,8(sp)
    80004968:	6121                	addi	sp,sp,64
    8000496a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000496c:	85d6                	mv	a1,s5
    8000496e:	8552                	mv	a0,s4
    80004970:	00000097          	auipc	ra,0x0
    80004974:	348080e7          	jalr	840(ra) # 80004cb8 <pipeclose>
    80004978:	b7cd                	j	8000495a <fileclose+0xa8>

000000008000497a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000497a:	715d                	addi	sp,sp,-80
    8000497c:	e486                	sd	ra,72(sp)
    8000497e:	e0a2                	sd	s0,64(sp)
    80004980:	fc26                	sd	s1,56(sp)
    80004982:	f84a                	sd	s2,48(sp)
    80004984:	f44e                	sd	s3,40(sp)
    80004986:	0880                	addi	s0,sp,80
    80004988:	84aa                	mv	s1,a0
    8000498a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000498c:	ffffd097          	auipc	ra,0xffffd
    80004990:	01a080e7          	jalr	26(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004994:	409c                	lw	a5,0(s1)
    80004996:	37f9                	addiw	a5,a5,-2
    80004998:	4705                	li	a4,1
    8000499a:	04f76763          	bltu	a4,a5,800049e8 <filestat+0x6e>
    8000499e:	892a                	mv	s2,a0
    ilock(f->ip);
    800049a0:	6c88                	ld	a0,24(s1)
    800049a2:	fffff097          	auipc	ra,0xfffff
    800049a6:	0a6080e7          	jalr	166(ra) # 80003a48 <ilock>
    stati(f->ip, &st);
    800049aa:	fb840593          	addi	a1,s0,-72
    800049ae:	6c88                	ld	a0,24(s1)
    800049b0:	fffff097          	auipc	ra,0xfffff
    800049b4:	322080e7          	jalr	802(ra) # 80003cd2 <stati>
    iunlock(f->ip);
    800049b8:	6c88                	ld	a0,24(s1)
    800049ba:	fffff097          	auipc	ra,0xfffff
    800049be:	150080e7          	jalr	336(ra) # 80003b0a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049c2:	46e1                	li	a3,24
    800049c4:	fb840613          	addi	a2,s0,-72
    800049c8:	85ce                	mv	a1,s3
    800049ca:	05093503          	ld	a0,80(s2)
    800049ce:	ffffd097          	auipc	ra,0xffffd
    800049d2:	c98080e7          	jalr	-872(ra) # 80001666 <copyout>
    800049d6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049da:	60a6                	ld	ra,72(sp)
    800049dc:	6406                	ld	s0,64(sp)
    800049de:	74e2                	ld	s1,56(sp)
    800049e0:	7942                	ld	s2,48(sp)
    800049e2:	79a2                	ld	s3,40(sp)
    800049e4:	6161                	addi	sp,sp,80
    800049e6:	8082                	ret
  return -1;
    800049e8:	557d                	li	a0,-1
    800049ea:	bfc5                	j	800049da <filestat+0x60>

00000000800049ec <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049ec:	7179                	addi	sp,sp,-48
    800049ee:	f406                	sd	ra,40(sp)
    800049f0:	f022                	sd	s0,32(sp)
    800049f2:	ec26                	sd	s1,24(sp)
    800049f4:	e84a                	sd	s2,16(sp)
    800049f6:	e44e                	sd	s3,8(sp)
    800049f8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049fa:	00854783          	lbu	a5,8(a0)
    800049fe:	c3d5                	beqz	a5,80004aa2 <fileread+0xb6>
    80004a00:	84aa                	mv	s1,a0
    80004a02:	89ae                	mv	s3,a1
    80004a04:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a06:	411c                	lw	a5,0(a0)
    80004a08:	4705                	li	a4,1
    80004a0a:	04e78963          	beq	a5,a4,80004a5c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a0e:	470d                	li	a4,3
    80004a10:	04e78d63          	beq	a5,a4,80004a6a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a14:	4709                	li	a4,2
    80004a16:	06e79e63          	bne	a5,a4,80004a92 <fileread+0xa6>
    ilock(f->ip);
    80004a1a:	6d08                	ld	a0,24(a0)
    80004a1c:	fffff097          	auipc	ra,0xfffff
    80004a20:	02c080e7          	jalr	44(ra) # 80003a48 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a24:	874a                	mv	a4,s2
    80004a26:	5094                	lw	a3,32(s1)
    80004a28:	864e                	mv	a2,s3
    80004a2a:	4585                	li	a1,1
    80004a2c:	6c88                	ld	a0,24(s1)
    80004a2e:	fffff097          	auipc	ra,0xfffff
    80004a32:	2ce080e7          	jalr	718(ra) # 80003cfc <readi>
    80004a36:	892a                	mv	s2,a0
    80004a38:	00a05563          	blez	a0,80004a42 <fileread+0x56>
      f->off += r;
    80004a3c:	509c                	lw	a5,32(s1)
    80004a3e:	9fa9                	addw	a5,a5,a0
    80004a40:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a42:	6c88                	ld	a0,24(s1)
    80004a44:	fffff097          	auipc	ra,0xfffff
    80004a48:	0c6080e7          	jalr	198(ra) # 80003b0a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a4c:	854a                	mv	a0,s2
    80004a4e:	70a2                	ld	ra,40(sp)
    80004a50:	7402                	ld	s0,32(sp)
    80004a52:	64e2                	ld	s1,24(sp)
    80004a54:	6942                	ld	s2,16(sp)
    80004a56:	69a2                	ld	s3,8(sp)
    80004a58:	6145                	addi	sp,sp,48
    80004a5a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a5c:	6908                	ld	a0,16(a0)
    80004a5e:	00000097          	auipc	ra,0x0
    80004a62:	3c2080e7          	jalr	962(ra) # 80004e20 <piperead>
    80004a66:	892a                	mv	s2,a0
    80004a68:	b7d5                	j	80004a4c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a6a:	02451783          	lh	a5,36(a0)
    80004a6e:	03079693          	slli	a3,a5,0x30
    80004a72:	92c1                	srli	a3,a3,0x30
    80004a74:	4725                	li	a4,9
    80004a76:	02d76863          	bltu	a4,a3,80004aa6 <fileread+0xba>
    80004a7a:	0792                	slli	a5,a5,0x4
    80004a7c:	0001d717          	auipc	a4,0x1d
    80004a80:	b6c70713          	addi	a4,a4,-1172 # 800215e8 <devsw>
    80004a84:	97ba                	add	a5,a5,a4
    80004a86:	639c                	ld	a5,0(a5)
    80004a88:	c38d                	beqz	a5,80004aaa <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a8a:	4505                	li	a0,1
    80004a8c:	9782                	jalr	a5
    80004a8e:	892a                	mv	s2,a0
    80004a90:	bf75                	j	80004a4c <fileread+0x60>
    panic("fileread");
    80004a92:	00004517          	auipc	a0,0x4
    80004a96:	c3650513          	addi	a0,a0,-970 # 800086c8 <syscalls+0x278>
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	aa2080e7          	jalr	-1374(ra) # 8000053c <panic>
    return -1;
    80004aa2:	597d                	li	s2,-1
    80004aa4:	b765                	j	80004a4c <fileread+0x60>
      return -1;
    80004aa6:	597d                	li	s2,-1
    80004aa8:	b755                	j	80004a4c <fileread+0x60>
    80004aaa:	597d                	li	s2,-1
    80004aac:	b745                	j	80004a4c <fileread+0x60>

0000000080004aae <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004aae:	00954783          	lbu	a5,9(a0)
    80004ab2:	10078e63          	beqz	a5,80004bce <filewrite+0x120>
{
    80004ab6:	715d                	addi	sp,sp,-80
    80004ab8:	e486                	sd	ra,72(sp)
    80004aba:	e0a2                	sd	s0,64(sp)
    80004abc:	fc26                	sd	s1,56(sp)
    80004abe:	f84a                	sd	s2,48(sp)
    80004ac0:	f44e                	sd	s3,40(sp)
    80004ac2:	f052                	sd	s4,32(sp)
    80004ac4:	ec56                	sd	s5,24(sp)
    80004ac6:	e85a                	sd	s6,16(sp)
    80004ac8:	e45e                	sd	s7,8(sp)
    80004aca:	e062                	sd	s8,0(sp)
    80004acc:	0880                	addi	s0,sp,80
    80004ace:	892a                	mv	s2,a0
    80004ad0:	8b2e                	mv	s6,a1
    80004ad2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ad4:	411c                	lw	a5,0(a0)
    80004ad6:	4705                	li	a4,1
    80004ad8:	02e78263          	beq	a5,a4,80004afc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004adc:	470d                	li	a4,3
    80004ade:	02e78563          	beq	a5,a4,80004b08 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ae2:	4709                	li	a4,2
    80004ae4:	0ce79d63          	bne	a5,a4,80004bbe <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ae8:	0ac05b63          	blez	a2,80004b9e <filewrite+0xf0>
    int i = 0;
    80004aec:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004aee:	6b85                	lui	s7,0x1
    80004af0:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004af4:	6c05                	lui	s8,0x1
    80004af6:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004afa:	a851                	j	80004b8e <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004afc:	6908                	ld	a0,16(a0)
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	22a080e7          	jalr	554(ra) # 80004d28 <pipewrite>
    80004b06:	a045                	j	80004ba6 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b08:	02451783          	lh	a5,36(a0)
    80004b0c:	03079693          	slli	a3,a5,0x30
    80004b10:	92c1                	srli	a3,a3,0x30
    80004b12:	4725                	li	a4,9
    80004b14:	0ad76f63          	bltu	a4,a3,80004bd2 <filewrite+0x124>
    80004b18:	0792                	slli	a5,a5,0x4
    80004b1a:	0001d717          	auipc	a4,0x1d
    80004b1e:	ace70713          	addi	a4,a4,-1330 # 800215e8 <devsw>
    80004b22:	97ba                	add	a5,a5,a4
    80004b24:	679c                	ld	a5,8(a5)
    80004b26:	cbc5                	beqz	a5,80004bd6 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004b28:	4505                	li	a0,1
    80004b2a:	9782                	jalr	a5
    80004b2c:	a8ad                	j	80004ba6 <filewrite+0xf8>
      if(n1 > max)
    80004b2e:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004b32:	00000097          	auipc	ra,0x0
    80004b36:	8bc080e7          	jalr	-1860(ra) # 800043ee <begin_op>
      ilock(f->ip);
    80004b3a:	01893503          	ld	a0,24(s2)
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	f0a080e7          	jalr	-246(ra) # 80003a48 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b46:	8756                	mv	a4,s5
    80004b48:	02092683          	lw	a3,32(s2)
    80004b4c:	01698633          	add	a2,s3,s6
    80004b50:	4585                	li	a1,1
    80004b52:	01893503          	ld	a0,24(s2)
    80004b56:	fffff097          	auipc	ra,0xfffff
    80004b5a:	29e080e7          	jalr	670(ra) # 80003df4 <writei>
    80004b5e:	84aa                	mv	s1,a0
    80004b60:	00a05763          	blez	a0,80004b6e <filewrite+0xc0>
        f->off += r;
    80004b64:	02092783          	lw	a5,32(s2)
    80004b68:	9fa9                	addw	a5,a5,a0
    80004b6a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b6e:	01893503          	ld	a0,24(s2)
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	f98080e7          	jalr	-104(ra) # 80003b0a <iunlock>
      end_op();
    80004b7a:	00000097          	auipc	ra,0x0
    80004b7e:	8ee080e7          	jalr	-1810(ra) # 80004468 <end_op>

      if(r != n1){
    80004b82:	009a9f63          	bne	s5,s1,80004ba0 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004b86:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b8a:	0149db63          	bge	s3,s4,80004ba0 <filewrite+0xf2>
      int n1 = n - i;
    80004b8e:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004b92:	0004879b          	sext.w	a5,s1
    80004b96:	f8fbdce3          	bge	s7,a5,80004b2e <filewrite+0x80>
    80004b9a:	84e2                	mv	s1,s8
    80004b9c:	bf49                	j	80004b2e <filewrite+0x80>
    int i = 0;
    80004b9e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ba0:	033a1d63          	bne	s4,s3,80004bda <filewrite+0x12c>
    80004ba4:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ba6:	60a6                	ld	ra,72(sp)
    80004ba8:	6406                	ld	s0,64(sp)
    80004baa:	74e2                	ld	s1,56(sp)
    80004bac:	7942                	ld	s2,48(sp)
    80004bae:	79a2                	ld	s3,40(sp)
    80004bb0:	7a02                	ld	s4,32(sp)
    80004bb2:	6ae2                	ld	s5,24(sp)
    80004bb4:	6b42                	ld	s6,16(sp)
    80004bb6:	6ba2                	ld	s7,8(sp)
    80004bb8:	6c02                	ld	s8,0(sp)
    80004bba:	6161                	addi	sp,sp,80
    80004bbc:	8082                	ret
    panic("filewrite");
    80004bbe:	00004517          	auipc	a0,0x4
    80004bc2:	b1a50513          	addi	a0,a0,-1254 # 800086d8 <syscalls+0x288>
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	976080e7          	jalr	-1674(ra) # 8000053c <panic>
    return -1;
    80004bce:	557d                	li	a0,-1
}
    80004bd0:	8082                	ret
      return -1;
    80004bd2:	557d                	li	a0,-1
    80004bd4:	bfc9                	j	80004ba6 <filewrite+0xf8>
    80004bd6:	557d                	li	a0,-1
    80004bd8:	b7f9                	j	80004ba6 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004bda:	557d                	li	a0,-1
    80004bdc:	b7e9                	j	80004ba6 <filewrite+0xf8>

0000000080004bde <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bde:	7179                	addi	sp,sp,-48
    80004be0:	f406                	sd	ra,40(sp)
    80004be2:	f022                	sd	s0,32(sp)
    80004be4:	ec26                	sd	s1,24(sp)
    80004be6:	e84a                	sd	s2,16(sp)
    80004be8:	e44e                	sd	s3,8(sp)
    80004bea:	e052                	sd	s4,0(sp)
    80004bec:	1800                	addi	s0,sp,48
    80004bee:	84aa                	mv	s1,a0
    80004bf0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bf2:	0005b023          	sd	zero,0(a1)
    80004bf6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bfa:	00000097          	auipc	ra,0x0
    80004bfe:	bfc080e7          	jalr	-1028(ra) # 800047f6 <filealloc>
    80004c02:	e088                	sd	a0,0(s1)
    80004c04:	c551                	beqz	a0,80004c90 <pipealloc+0xb2>
    80004c06:	00000097          	auipc	ra,0x0
    80004c0a:	bf0080e7          	jalr	-1040(ra) # 800047f6 <filealloc>
    80004c0e:	00aa3023          	sd	a0,0(s4)
    80004c12:	c92d                	beqz	a0,80004c84 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	ece080e7          	jalr	-306(ra) # 80000ae2 <kalloc>
    80004c1c:	892a                	mv	s2,a0
    80004c1e:	c125                	beqz	a0,80004c7e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c20:	4985                	li	s3,1
    80004c22:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c26:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c2a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c2e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c32:	00004597          	auipc	a1,0x4
    80004c36:	ab658593          	addi	a1,a1,-1354 # 800086e8 <syscalls+0x298>
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	f08080e7          	jalr	-248(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004c42:	609c                	ld	a5,0(s1)
    80004c44:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c48:	609c                	ld	a5,0(s1)
    80004c4a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c4e:	609c                	ld	a5,0(s1)
    80004c50:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c54:	609c                	ld	a5,0(s1)
    80004c56:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c5a:	000a3783          	ld	a5,0(s4)
    80004c5e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c62:	000a3783          	ld	a5,0(s4)
    80004c66:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c6a:	000a3783          	ld	a5,0(s4)
    80004c6e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c72:	000a3783          	ld	a5,0(s4)
    80004c76:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c7a:	4501                	li	a0,0
    80004c7c:	a025                	j	80004ca4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c7e:	6088                	ld	a0,0(s1)
    80004c80:	e501                	bnez	a0,80004c88 <pipealloc+0xaa>
    80004c82:	a039                	j	80004c90 <pipealloc+0xb2>
    80004c84:	6088                	ld	a0,0(s1)
    80004c86:	c51d                	beqz	a0,80004cb4 <pipealloc+0xd6>
    fileclose(*f0);
    80004c88:	00000097          	auipc	ra,0x0
    80004c8c:	c2a080e7          	jalr	-982(ra) # 800048b2 <fileclose>
  if(*f1)
    80004c90:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c94:	557d                	li	a0,-1
  if(*f1)
    80004c96:	c799                	beqz	a5,80004ca4 <pipealloc+0xc6>
    fileclose(*f1);
    80004c98:	853e                	mv	a0,a5
    80004c9a:	00000097          	auipc	ra,0x0
    80004c9e:	c18080e7          	jalr	-1000(ra) # 800048b2 <fileclose>
  return -1;
    80004ca2:	557d                	li	a0,-1
}
    80004ca4:	70a2                	ld	ra,40(sp)
    80004ca6:	7402                	ld	s0,32(sp)
    80004ca8:	64e2                	ld	s1,24(sp)
    80004caa:	6942                	ld	s2,16(sp)
    80004cac:	69a2                	ld	s3,8(sp)
    80004cae:	6a02                	ld	s4,0(sp)
    80004cb0:	6145                	addi	sp,sp,48
    80004cb2:	8082                	ret
  return -1;
    80004cb4:	557d                	li	a0,-1
    80004cb6:	b7fd                	j	80004ca4 <pipealloc+0xc6>

0000000080004cb8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cb8:	1101                	addi	sp,sp,-32
    80004cba:	ec06                	sd	ra,24(sp)
    80004cbc:	e822                	sd	s0,16(sp)
    80004cbe:	e426                	sd	s1,8(sp)
    80004cc0:	e04a                	sd	s2,0(sp)
    80004cc2:	1000                	addi	s0,sp,32
    80004cc4:	84aa                	mv	s1,a0
    80004cc6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	f0a080e7          	jalr	-246(ra) # 80000bd2 <acquire>
  if(writable){
    80004cd0:	02090d63          	beqz	s2,80004d0a <pipeclose+0x52>
    pi->writeopen = 0;
    80004cd4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cd8:	21848513          	addi	a0,s1,536
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	498080e7          	jalr	1176(ra) # 80002174 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ce4:	2204b783          	ld	a5,544(s1)
    80004ce8:	eb95                	bnez	a5,80004d1c <pipeclose+0x64>
    release(&pi->lock);
    80004cea:	8526                	mv	a0,s1
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	f9a080e7          	jalr	-102(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	cee080e7          	jalr	-786(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004cfe:	60e2                	ld	ra,24(sp)
    80004d00:	6442                	ld	s0,16(sp)
    80004d02:	64a2                	ld	s1,8(sp)
    80004d04:	6902                	ld	s2,0(sp)
    80004d06:	6105                	addi	sp,sp,32
    80004d08:	8082                	ret
    pi->readopen = 0;
    80004d0a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d0e:	21c48513          	addi	a0,s1,540
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	462080e7          	jalr	1122(ra) # 80002174 <wakeup>
    80004d1a:	b7e9                	j	80004ce4 <pipeclose+0x2c>
    release(&pi->lock);
    80004d1c:	8526                	mv	a0,s1
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	f68080e7          	jalr	-152(ra) # 80000c86 <release>
}
    80004d26:	bfe1                	j	80004cfe <pipeclose+0x46>

0000000080004d28 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d28:	711d                	addi	sp,sp,-96
    80004d2a:	ec86                	sd	ra,88(sp)
    80004d2c:	e8a2                	sd	s0,80(sp)
    80004d2e:	e4a6                	sd	s1,72(sp)
    80004d30:	e0ca                	sd	s2,64(sp)
    80004d32:	fc4e                	sd	s3,56(sp)
    80004d34:	f852                	sd	s4,48(sp)
    80004d36:	f456                	sd	s5,40(sp)
    80004d38:	f05a                	sd	s6,32(sp)
    80004d3a:	ec5e                	sd	s7,24(sp)
    80004d3c:	e862                	sd	s8,16(sp)
    80004d3e:	1080                	addi	s0,sp,96
    80004d40:	84aa                	mv	s1,a0
    80004d42:	8aae                	mv	s5,a1
    80004d44:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d46:	ffffd097          	auipc	ra,0xffffd
    80004d4a:	c60080e7          	jalr	-928(ra) # 800019a6 <myproc>
    80004d4e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d50:	8526                	mv	a0,s1
    80004d52:	ffffc097          	auipc	ra,0xffffc
    80004d56:	e80080e7          	jalr	-384(ra) # 80000bd2 <acquire>
  while(i < n){
    80004d5a:	0b405663          	blez	s4,80004e06 <pipewrite+0xde>
  int i = 0;
    80004d5e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d60:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d62:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d66:	21c48b93          	addi	s7,s1,540
    80004d6a:	a089                	j	80004dac <pipewrite+0x84>
      release(&pi->lock);
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	ffffc097          	auipc	ra,0xffffc
    80004d72:	f18080e7          	jalr	-232(ra) # 80000c86 <release>
      return -1;
    80004d76:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d78:	854a                	mv	a0,s2
    80004d7a:	60e6                	ld	ra,88(sp)
    80004d7c:	6446                	ld	s0,80(sp)
    80004d7e:	64a6                	ld	s1,72(sp)
    80004d80:	6906                	ld	s2,64(sp)
    80004d82:	79e2                	ld	s3,56(sp)
    80004d84:	7a42                	ld	s4,48(sp)
    80004d86:	7aa2                	ld	s5,40(sp)
    80004d88:	7b02                	ld	s6,32(sp)
    80004d8a:	6be2                	ld	s7,24(sp)
    80004d8c:	6c42                	ld	s8,16(sp)
    80004d8e:	6125                	addi	sp,sp,96
    80004d90:	8082                	ret
      wakeup(&pi->nread);
    80004d92:	8562                	mv	a0,s8
    80004d94:	ffffd097          	auipc	ra,0xffffd
    80004d98:	3e0080e7          	jalr	992(ra) # 80002174 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d9c:	85a6                	mv	a1,s1
    80004d9e:	855e                	mv	a0,s7
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	370080e7          	jalr	880(ra) # 80002110 <sleep>
  while(i < n){
    80004da8:	07495063          	bge	s2,s4,80004e08 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004dac:	2204a783          	lw	a5,544(s1)
    80004db0:	dfd5                	beqz	a5,80004d6c <pipewrite+0x44>
    80004db2:	854e                	mv	a0,s3
    80004db4:	ffffd097          	auipc	ra,0xffffd
    80004db8:	610080e7          	jalr	1552(ra) # 800023c4 <killed>
    80004dbc:	f945                	bnez	a0,80004d6c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004dbe:	2184a783          	lw	a5,536(s1)
    80004dc2:	21c4a703          	lw	a4,540(s1)
    80004dc6:	2007879b          	addiw	a5,a5,512
    80004dca:	fcf704e3          	beq	a4,a5,80004d92 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dce:	4685                	li	a3,1
    80004dd0:	01590633          	add	a2,s2,s5
    80004dd4:	faf40593          	addi	a1,s0,-81
    80004dd8:	0509b503          	ld	a0,80(s3)
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	916080e7          	jalr	-1770(ra) # 800016f2 <copyin>
    80004de4:	03650263          	beq	a0,s6,80004e08 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004de8:	21c4a783          	lw	a5,540(s1)
    80004dec:	0017871b          	addiw	a4,a5,1
    80004df0:	20e4ae23          	sw	a4,540(s1)
    80004df4:	1ff7f793          	andi	a5,a5,511
    80004df8:	97a6                	add	a5,a5,s1
    80004dfa:	faf44703          	lbu	a4,-81(s0)
    80004dfe:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e02:	2905                	addiw	s2,s2,1
    80004e04:	b755                	j	80004da8 <pipewrite+0x80>
  int i = 0;
    80004e06:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e08:	21848513          	addi	a0,s1,536
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	368080e7          	jalr	872(ra) # 80002174 <wakeup>
  release(&pi->lock);
    80004e14:	8526                	mv	a0,s1
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	e70080e7          	jalr	-400(ra) # 80000c86 <release>
  return i;
    80004e1e:	bfa9                	j	80004d78 <pipewrite+0x50>

0000000080004e20 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e20:	715d                	addi	sp,sp,-80
    80004e22:	e486                	sd	ra,72(sp)
    80004e24:	e0a2                	sd	s0,64(sp)
    80004e26:	fc26                	sd	s1,56(sp)
    80004e28:	f84a                	sd	s2,48(sp)
    80004e2a:	f44e                	sd	s3,40(sp)
    80004e2c:	f052                	sd	s4,32(sp)
    80004e2e:	ec56                	sd	s5,24(sp)
    80004e30:	e85a                	sd	s6,16(sp)
    80004e32:	0880                	addi	s0,sp,80
    80004e34:	84aa                	mv	s1,a0
    80004e36:	892e                	mv	s2,a1
    80004e38:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e3a:	ffffd097          	auipc	ra,0xffffd
    80004e3e:	b6c080e7          	jalr	-1172(ra) # 800019a6 <myproc>
    80004e42:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e44:	8526                	mv	a0,s1
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	d8c080e7          	jalr	-628(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e4e:	2184a703          	lw	a4,536(s1)
    80004e52:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e56:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e5a:	02f71763          	bne	a4,a5,80004e88 <piperead+0x68>
    80004e5e:	2244a783          	lw	a5,548(s1)
    80004e62:	c39d                	beqz	a5,80004e88 <piperead+0x68>
    if(killed(pr)){
    80004e64:	8552                	mv	a0,s4
    80004e66:	ffffd097          	auipc	ra,0xffffd
    80004e6a:	55e080e7          	jalr	1374(ra) # 800023c4 <killed>
    80004e6e:	e949                	bnez	a0,80004f00 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e70:	85a6                	mv	a1,s1
    80004e72:	854e                	mv	a0,s3
    80004e74:	ffffd097          	auipc	ra,0xffffd
    80004e78:	29c080e7          	jalr	668(ra) # 80002110 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e7c:	2184a703          	lw	a4,536(s1)
    80004e80:	21c4a783          	lw	a5,540(s1)
    80004e84:	fcf70de3          	beq	a4,a5,80004e5e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e88:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e8a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e8c:	05505463          	blez	s5,80004ed4 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004e90:	2184a783          	lw	a5,536(s1)
    80004e94:	21c4a703          	lw	a4,540(s1)
    80004e98:	02f70e63          	beq	a4,a5,80004ed4 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e9c:	0017871b          	addiw	a4,a5,1
    80004ea0:	20e4ac23          	sw	a4,536(s1)
    80004ea4:	1ff7f793          	andi	a5,a5,511
    80004ea8:	97a6                	add	a5,a5,s1
    80004eaa:	0187c783          	lbu	a5,24(a5)
    80004eae:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eb2:	4685                	li	a3,1
    80004eb4:	fbf40613          	addi	a2,s0,-65
    80004eb8:	85ca                	mv	a1,s2
    80004eba:	050a3503          	ld	a0,80(s4)
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	7a8080e7          	jalr	1960(ra) # 80001666 <copyout>
    80004ec6:	01650763          	beq	a0,s6,80004ed4 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eca:	2985                	addiw	s3,s3,1
    80004ecc:	0905                	addi	s2,s2,1
    80004ece:	fd3a91e3          	bne	s5,s3,80004e90 <piperead+0x70>
    80004ed2:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ed4:	21c48513          	addi	a0,s1,540
    80004ed8:	ffffd097          	auipc	ra,0xffffd
    80004edc:	29c080e7          	jalr	668(ra) # 80002174 <wakeup>
  release(&pi->lock);
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	da4080e7          	jalr	-604(ra) # 80000c86 <release>
  return i;
}
    80004eea:	854e                	mv	a0,s3
    80004eec:	60a6                	ld	ra,72(sp)
    80004eee:	6406                	ld	s0,64(sp)
    80004ef0:	74e2                	ld	s1,56(sp)
    80004ef2:	7942                	ld	s2,48(sp)
    80004ef4:	79a2                	ld	s3,40(sp)
    80004ef6:	7a02                	ld	s4,32(sp)
    80004ef8:	6ae2                	ld	s5,24(sp)
    80004efa:	6b42                	ld	s6,16(sp)
    80004efc:	6161                	addi	sp,sp,80
    80004efe:	8082                	ret
      release(&pi->lock);
    80004f00:	8526                	mv	a0,s1
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	d84080e7          	jalr	-636(ra) # 80000c86 <release>
      return -1;
    80004f0a:	59fd                	li	s3,-1
    80004f0c:	bff9                	j	80004eea <piperead+0xca>

0000000080004f0e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f0e:	1141                	addi	sp,sp,-16
    80004f10:	e422                	sd	s0,8(sp)
    80004f12:	0800                	addi	s0,sp,16
    80004f14:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f16:	8905                	andi	a0,a0,1
    80004f18:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004f1a:	8b89                	andi	a5,a5,2
    80004f1c:	c399                	beqz	a5,80004f22 <flags2perm+0x14>
      perm |= PTE_W;
    80004f1e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f22:	6422                	ld	s0,8(sp)
    80004f24:	0141                	addi	sp,sp,16
    80004f26:	8082                	ret

0000000080004f28 <exec>:

int
exec(char *path, char **argv)
{
    80004f28:	df010113          	addi	sp,sp,-528
    80004f2c:	20113423          	sd	ra,520(sp)
    80004f30:	20813023          	sd	s0,512(sp)
    80004f34:	ffa6                	sd	s1,504(sp)
    80004f36:	fbca                	sd	s2,496(sp)
    80004f38:	f7ce                	sd	s3,488(sp)
    80004f3a:	f3d2                	sd	s4,480(sp)
    80004f3c:	efd6                	sd	s5,472(sp)
    80004f3e:	ebda                	sd	s6,464(sp)
    80004f40:	e7de                	sd	s7,456(sp)
    80004f42:	e3e2                	sd	s8,448(sp)
    80004f44:	ff66                	sd	s9,440(sp)
    80004f46:	fb6a                	sd	s10,432(sp)
    80004f48:	f76e                	sd	s11,424(sp)
    80004f4a:	0c00                	addi	s0,sp,528
    80004f4c:	892a                	mv	s2,a0
    80004f4e:	dea43c23          	sd	a0,-520(s0)
    80004f52:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	a50080e7          	jalr	-1456(ra) # 800019a6 <myproc>
    80004f5e:	84aa                	mv	s1,a0

  begin_op();
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	48e080e7          	jalr	1166(ra) # 800043ee <begin_op>

  if((ip = namei(path)) == 0){
    80004f68:	854a                	mv	a0,s2
    80004f6a:	fffff097          	auipc	ra,0xfffff
    80004f6e:	284080e7          	jalr	644(ra) # 800041ee <namei>
    80004f72:	c92d                	beqz	a0,80004fe4 <exec+0xbc>
    80004f74:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f76:	fffff097          	auipc	ra,0xfffff
    80004f7a:	ad2080e7          	jalr	-1326(ra) # 80003a48 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f7e:	04000713          	li	a4,64
    80004f82:	4681                	li	a3,0
    80004f84:	e5040613          	addi	a2,s0,-432
    80004f88:	4581                	li	a1,0
    80004f8a:	8552                	mv	a0,s4
    80004f8c:	fffff097          	auipc	ra,0xfffff
    80004f90:	d70080e7          	jalr	-656(ra) # 80003cfc <readi>
    80004f94:	04000793          	li	a5,64
    80004f98:	00f51a63          	bne	a0,a5,80004fac <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f9c:	e5042703          	lw	a4,-432(s0)
    80004fa0:	464c47b7          	lui	a5,0x464c4
    80004fa4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fa8:	04f70463          	beq	a4,a5,80004ff0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fac:	8552                	mv	a0,s4
    80004fae:	fffff097          	auipc	ra,0xfffff
    80004fb2:	cfc080e7          	jalr	-772(ra) # 80003caa <iunlockput>
    end_op();
    80004fb6:	fffff097          	auipc	ra,0xfffff
    80004fba:	4b2080e7          	jalr	1202(ra) # 80004468 <end_op>
  }
  return -1;
    80004fbe:	557d                	li	a0,-1
}
    80004fc0:	20813083          	ld	ra,520(sp)
    80004fc4:	20013403          	ld	s0,512(sp)
    80004fc8:	74fe                	ld	s1,504(sp)
    80004fca:	795e                	ld	s2,496(sp)
    80004fcc:	79be                	ld	s3,488(sp)
    80004fce:	7a1e                	ld	s4,480(sp)
    80004fd0:	6afe                	ld	s5,472(sp)
    80004fd2:	6b5e                	ld	s6,464(sp)
    80004fd4:	6bbe                	ld	s7,456(sp)
    80004fd6:	6c1e                	ld	s8,448(sp)
    80004fd8:	7cfa                	ld	s9,440(sp)
    80004fda:	7d5a                	ld	s10,432(sp)
    80004fdc:	7dba                	ld	s11,424(sp)
    80004fde:	21010113          	addi	sp,sp,528
    80004fe2:	8082                	ret
    end_op();
    80004fe4:	fffff097          	auipc	ra,0xfffff
    80004fe8:	484080e7          	jalr	1156(ra) # 80004468 <end_op>
    return -1;
    80004fec:	557d                	li	a0,-1
    80004fee:	bfc9                	j	80004fc0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ff0:	8526                	mv	a0,s1
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	ade080e7          	jalr	-1314(ra) # 80001ad0 <proc_pagetable>
    80004ffa:	8b2a                	mv	s6,a0
    80004ffc:	d945                	beqz	a0,80004fac <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ffe:	e7042d03          	lw	s10,-400(s0)
    80005002:	e8845783          	lhu	a5,-376(s0)
    80005006:	10078463          	beqz	a5,8000510e <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000500a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000500c:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    8000500e:	6c85                	lui	s9,0x1
    80005010:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005014:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005018:	6a85                	lui	s5,0x1
    8000501a:	a0b5                	j	80005086 <exec+0x15e>
      panic("loadseg: address should exist");
    8000501c:	00003517          	auipc	a0,0x3
    80005020:	6d450513          	addi	a0,a0,1748 # 800086f0 <syscalls+0x2a0>
    80005024:	ffffb097          	auipc	ra,0xffffb
    80005028:	518080e7          	jalr	1304(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    8000502c:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000502e:	8726                	mv	a4,s1
    80005030:	012c06bb          	addw	a3,s8,s2
    80005034:	4581                	li	a1,0
    80005036:	8552                	mv	a0,s4
    80005038:	fffff097          	auipc	ra,0xfffff
    8000503c:	cc4080e7          	jalr	-828(ra) # 80003cfc <readi>
    80005040:	2501                	sext.w	a0,a0
    80005042:	24a49863          	bne	s1,a0,80005292 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80005046:	012a893b          	addw	s2,s5,s2
    8000504a:	03397563          	bgeu	s2,s3,80005074 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    8000504e:	02091593          	slli	a1,s2,0x20
    80005052:	9181                	srli	a1,a1,0x20
    80005054:	95de                	add	a1,a1,s7
    80005056:	855a                	mv	a0,s6
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	ffe080e7          	jalr	-2(ra) # 80001056 <walkaddr>
    80005060:	862a                	mv	a2,a0
    if(pa == 0)
    80005062:	dd4d                	beqz	a0,8000501c <exec+0xf4>
    if(sz - i < PGSIZE)
    80005064:	412984bb          	subw	s1,s3,s2
    80005068:	0004879b          	sext.w	a5,s1
    8000506c:	fcfcf0e3          	bgeu	s9,a5,8000502c <exec+0x104>
    80005070:	84d6                	mv	s1,s5
    80005072:	bf6d                	j	8000502c <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005074:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005078:	2d85                	addiw	s11,s11,1
    8000507a:	038d0d1b          	addiw	s10,s10,56
    8000507e:	e8845783          	lhu	a5,-376(s0)
    80005082:	08fdd763          	bge	s11,a5,80005110 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005086:	2d01                	sext.w	s10,s10
    80005088:	03800713          	li	a4,56
    8000508c:	86ea                	mv	a3,s10
    8000508e:	e1840613          	addi	a2,s0,-488
    80005092:	4581                	li	a1,0
    80005094:	8552                	mv	a0,s4
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	c66080e7          	jalr	-922(ra) # 80003cfc <readi>
    8000509e:	03800793          	li	a5,56
    800050a2:	1ef51663          	bne	a0,a5,8000528e <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800050a6:	e1842783          	lw	a5,-488(s0)
    800050aa:	4705                	li	a4,1
    800050ac:	fce796e3          	bne	a5,a4,80005078 <exec+0x150>
    if(ph.memsz < ph.filesz)
    800050b0:	e4043483          	ld	s1,-448(s0)
    800050b4:	e3843783          	ld	a5,-456(s0)
    800050b8:	1ef4e863          	bltu	s1,a5,800052a8 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050bc:	e2843783          	ld	a5,-472(s0)
    800050c0:	94be                	add	s1,s1,a5
    800050c2:	1ef4e663          	bltu	s1,a5,800052ae <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800050c6:	df043703          	ld	a4,-528(s0)
    800050ca:	8ff9                	and	a5,a5,a4
    800050cc:	1e079463          	bnez	a5,800052b4 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050d0:	e1c42503          	lw	a0,-484(s0)
    800050d4:	00000097          	auipc	ra,0x0
    800050d8:	e3a080e7          	jalr	-454(ra) # 80004f0e <flags2perm>
    800050dc:	86aa                	mv	a3,a0
    800050de:	8626                	mv	a2,s1
    800050e0:	85ca                	mv	a1,s2
    800050e2:	855a                	mv	a0,s6
    800050e4:	ffffc097          	auipc	ra,0xffffc
    800050e8:	326080e7          	jalr	806(ra) # 8000140a <uvmalloc>
    800050ec:	e0a43423          	sd	a0,-504(s0)
    800050f0:	1c050563          	beqz	a0,800052ba <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050f4:	e2843b83          	ld	s7,-472(s0)
    800050f8:	e2042c03          	lw	s8,-480(s0)
    800050fc:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005100:	00098463          	beqz	s3,80005108 <exec+0x1e0>
    80005104:	4901                	li	s2,0
    80005106:	b7a1                	j	8000504e <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005108:	e0843903          	ld	s2,-504(s0)
    8000510c:	b7b5                	j	80005078 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000510e:	4901                	li	s2,0
  iunlockput(ip);
    80005110:	8552                	mv	a0,s4
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	b98080e7          	jalr	-1128(ra) # 80003caa <iunlockput>
  end_op();
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	34e080e7          	jalr	846(ra) # 80004468 <end_op>
  p = myproc();
    80005122:	ffffd097          	auipc	ra,0xffffd
    80005126:	884080e7          	jalr	-1916(ra) # 800019a6 <myproc>
    8000512a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000512c:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005130:	6985                	lui	s3,0x1
    80005132:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005134:	99ca                	add	s3,s3,s2
    80005136:	77fd                	lui	a5,0xfffff
    80005138:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000513c:	4691                	li	a3,4
    8000513e:	6609                	lui	a2,0x2
    80005140:	964e                	add	a2,a2,s3
    80005142:	85ce                	mv	a1,s3
    80005144:	855a                	mv	a0,s6
    80005146:	ffffc097          	auipc	ra,0xffffc
    8000514a:	2c4080e7          	jalr	708(ra) # 8000140a <uvmalloc>
    8000514e:	892a                	mv	s2,a0
    80005150:	e0a43423          	sd	a0,-504(s0)
    80005154:	e509                	bnez	a0,8000515e <exec+0x236>
  if(pagetable)
    80005156:	e1343423          	sd	s3,-504(s0)
    8000515a:	4a01                	li	s4,0
    8000515c:	aa1d                	j	80005292 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000515e:	75f9                	lui	a1,0xffffe
    80005160:	95aa                	add	a1,a1,a0
    80005162:	855a                	mv	a0,s6
    80005164:	ffffc097          	auipc	ra,0xffffc
    80005168:	4d0080e7          	jalr	1232(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    8000516c:	7bfd                	lui	s7,0xfffff
    8000516e:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005170:	e0043783          	ld	a5,-512(s0)
    80005174:	6388                	ld	a0,0(a5)
    80005176:	c52d                	beqz	a0,800051e0 <exec+0x2b8>
    80005178:	e9040993          	addi	s3,s0,-368
    8000517c:	f9040c13          	addi	s8,s0,-112
    80005180:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	cc6080e7          	jalr	-826(ra) # 80000e48 <strlen>
    8000518a:	0015079b          	addiw	a5,a0,1
    8000518e:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005192:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005196:	13796563          	bltu	s2,s7,800052c0 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000519a:	e0043d03          	ld	s10,-512(s0)
    8000519e:	000d3a03          	ld	s4,0(s10)
    800051a2:	8552                	mv	a0,s4
    800051a4:	ffffc097          	auipc	ra,0xffffc
    800051a8:	ca4080e7          	jalr	-860(ra) # 80000e48 <strlen>
    800051ac:	0015069b          	addiw	a3,a0,1
    800051b0:	8652                	mv	a2,s4
    800051b2:	85ca                	mv	a1,s2
    800051b4:	855a                	mv	a0,s6
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	4b0080e7          	jalr	1200(ra) # 80001666 <copyout>
    800051be:	10054363          	bltz	a0,800052c4 <exec+0x39c>
    ustack[argc] = sp;
    800051c2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051c6:	0485                	addi	s1,s1,1
    800051c8:	008d0793          	addi	a5,s10,8
    800051cc:	e0f43023          	sd	a5,-512(s0)
    800051d0:	008d3503          	ld	a0,8(s10)
    800051d4:	c909                	beqz	a0,800051e6 <exec+0x2be>
    if(argc >= MAXARG)
    800051d6:	09a1                	addi	s3,s3,8
    800051d8:	fb8995e3          	bne	s3,s8,80005182 <exec+0x25a>
  ip = 0;
    800051dc:	4a01                	li	s4,0
    800051de:	a855                	j	80005292 <exec+0x36a>
  sp = sz;
    800051e0:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800051e4:	4481                	li	s1,0
  ustack[argc] = 0;
    800051e6:	00349793          	slli	a5,s1,0x3
    800051ea:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdc810>
    800051ee:	97a2                	add	a5,a5,s0
    800051f0:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800051f4:	00148693          	addi	a3,s1,1
    800051f8:	068e                	slli	a3,a3,0x3
    800051fa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051fe:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80005202:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005206:	f57968e3          	bltu	s2,s7,80005156 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000520a:	e9040613          	addi	a2,s0,-368
    8000520e:	85ca                	mv	a1,s2
    80005210:	855a                	mv	a0,s6
    80005212:	ffffc097          	auipc	ra,0xffffc
    80005216:	454080e7          	jalr	1108(ra) # 80001666 <copyout>
    8000521a:	0a054763          	bltz	a0,800052c8 <exec+0x3a0>
  p->trapframe->a1 = sp;
    8000521e:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005222:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005226:	df843783          	ld	a5,-520(s0)
    8000522a:	0007c703          	lbu	a4,0(a5)
    8000522e:	cf11                	beqz	a4,8000524a <exec+0x322>
    80005230:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005232:	02f00693          	li	a3,47
    80005236:	a039                	j	80005244 <exec+0x31c>
      last = s+1;
    80005238:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000523c:	0785                	addi	a5,a5,1
    8000523e:	fff7c703          	lbu	a4,-1(a5)
    80005242:	c701                	beqz	a4,8000524a <exec+0x322>
    if(*s == '/')
    80005244:	fed71ce3          	bne	a4,a3,8000523c <exec+0x314>
    80005248:	bfc5                	j	80005238 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    8000524a:	4641                	li	a2,16
    8000524c:	df843583          	ld	a1,-520(s0)
    80005250:	158a8513          	addi	a0,s5,344
    80005254:	ffffc097          	auipc	ra,0xffffc
    80005258:	bc2080e7          	jalr	-1086(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    8000525c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005260:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005264:	e0843783          	ld	a5,-504(s0)
    80005268:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000526c:	058ab783          	ld	a5,88(s5)
    80005270:	e6843703          	ld	a4,-408(s0)
    80005274:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005276:	058ab783          	ld	a5,88(s5)
    8000527a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000527e:	85e6                	mv	a1,s9
    80005280:	ffffd097          	auipc	ra,0xffffd
    80005284:	8ec080e7          	jalr	-1812(ra) # 80001b6c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005288:	0004851b          	sext.w	a0,s1
    8000528c:	bb15                	j	80004fc0 <exec+0x98>
    8000528e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005292:	e0843583          	ld	a1,-504(s0)
    80005296:	855a                	mv	a0,s6
    80005298:	ffffd097          	auipc	ra,0xffffd
    8000529c:	8d4080e7          	jalr	-1836(ra) # 80001b6c <proc_freepagetable>
  return -1;
    800052a0:	557d                	li	a0,-1
  if(ip){
    800052a2:	d00a0fe3          	beqz	s4,80004fc0 <exec+0x98>
    800052a6:	b319                	j	80004fac <exec+0x84>
    800052a8:	e1243423          	sd	s2,-504(s0)
    800052ac:	b7dd                	j	80005292 <exec+0x36a>
    800052ae:	e1243423          	sd	s2,-504(s0)
    800052b2:	b7c5                	j	80005292 <exec+0x36a>
    800052b4:	e1243423          	sd	s2,-504(s0)
    800052b8:	bfe9                	j	80005292 <exec+0x36a>
    800052ba:	e1243423          	sd	s2,-504(s0)
    800052be:	bfd1                	j	80005292 <exec+0x36a>
  ip = 0;
    800052c0:	4a01                	li	s4,0
    800052c2:	bfc1                	j	80005292 <exec+0x36a>
    800052c4:	4a01                	li	s4,0
  if(pagetable)
    800052c6:	b7f1                	j	80005292 <exec+0x36a>
  sz = sz1;
    800052c8:	e0843983          	ld	s3,-504(s0)
    800052cc:	b569                	j	80005156 <exec+0x22e>

00000000800052ce <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052ce:	7179                	addi	sp,sp,-48
    800052d0:	f406                	sd	ra,40(sp)
    800052d2:	f022                	sd	s0,32(sp)
    800052d4:	ec26                	sd	s1,24(sp)
    800052d6:	e84a                	sd	s2,16(sp)
    800052d8:	1800                	addi	s0,sp,48
    800052da:	892e                	mv	s2,a1
    800052dc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052de:	fdc40593          	addi	a1,s0,-36
    800052e2:	ffffe097          	auipc	ra,0xffffe
    800052e6:	ad6080e7          	jalr	-1322(ra) # 80002db8 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052ea:	fdc42703          	lw	a4,-36(s0)
    800052ee:	47bd                	li	a5,15
    800052f0:	02e7eb63          	bltu	a5,a4,80005326 <argfd+0x58>
    800052f4:	ffffc097          	auipc	ra,0xffffc
    800052f8:	6b2080e7          	jalr	1714(ra) # 800019a6 <myproc>
    800052fc:	fdc42703          	lw	a4,-36(s0)
    80005300:	01a70793          	addi	a5,a4,26
    80005304:	078e                	slli	a5,a5,0x3
    80005306:	953e                	add	a0,a0,a5
    80005308:	611c                	ld	a5,0(a0)
    8000530a:	c385                	beqz	a5,8000532a <argfd+0x5c>
    return -1;
  if(pfd)
    8000530c:	00090463          	beqz	s2,80005314 <argfd+0x46>
    *pfd = fd;
    80005310:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005314:	4501                	li	a0,0
  if(pf)
    80005316:	c091                	beqz	s1,8000531a <argfd+0x4c>
    *pf = f;
    80005318:	e09c                	sd	a5,0(s1)
}
    8000531a:	70a2                	ld	ra,40(sp)
    8000531c:	7402                	ld	s0,32(sp)
    8000531e:	64e2                	ld	s1,24(sp)
    80005320:	6942                	ld	s2,16(sp)
    80005322:	6145                	addi	sp,sp,48
    80005324:	8082                	ret
    return -1;
    80005326:	557d                	li	a0,-1
    80005328:	bfcd                	j	8000531a <argfd+0x4c>
    8000532a:	557d                	li	a0,-1
    8000532c:	b7fd                	j	8000531a <argfd+0x4c>

000000008000532e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000532e:	1101                	addi	sp,sp,-32
    80005330:	ec06                	sd	ra,24(sp)
    80005332:	e822                	sd	s0,16(sp)
    80005334:	e426                	sd	s1,8(sp)
    80005336:	1000                	addi	s0,sp,32
    80005338:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000533a:	ffffc097          	auipc	ra,0xffffc
    8000533e:	66c080e7          	jalr	1644(ra) # 800019a6 <myproc>
    80005342:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005344:	0d050793          	addi	a5,a0,208
    80005348:	4501                	li	a0,0
    8000534a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000534c:	6398                	ld	a4,0(a5)
    8000534e:	cb19                	beqz	a4,80005364 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005350:	2505                	addiw	a0,a0,1
    80005352:	07a1                	addi	a5,a5,8
    80005354:	fed51ce3          	bne	a0,a3,8000534c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005358:	557d                	li	a0,-1
}
    8000535a:	60e2                	ld	ra,24(sp)
    8000535c:	6442                	ld	s0,16(sp)
    8000535e:	64a2                	ld	s1,8(sp)
    80005360:	6105                	addi	sp,sp,32
    80005362:	8082                	ret
      p->ofile[fd] = f;
    80005364:	01a50793          	addi	a5,a0,26
    80005368:	078e                	slli	a5,a5,0x3
    8000536a:	963e                	add	a2,a2,a5
    8000536c:	e204                	sd	s1,0(a2)
      return fd;
    8000536e:	b7f5                	j	8000535a <fdalloc+0x2c>

0000000080005370 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005370:	715d                	addi	sp,sp,-80
    80005372:	e486                	sd	ra,72(sp)
    80005374:	e0a2                	sd	s0,64(sp)
    80005376:	fc26                	sd	s1,56(sp)
    80005378:	f84a                	sd	s2,48(sp)
    8000537a:	f44e                	sd	s3,40(sp)
    8000537c:	f052                	sd	s4,32(sp)
    8000537e:	ec56                	sd	s5,24(sp)
    80005380:	e85a                	sd	s6,16(sp)
    80005382:	0880                	addi	s0,sp,80
    80005384:	8b2e                	mv	s6,a1
    80005386:	89b2                	mv	s3,a2
    80005388:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000538a:	fb040593          	addi	a1,s0,-80
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	e7e080e7          	jalr	-386(ra) # 8000420c <nameiparent>
    80005396:	84aa                	mv	s1,a0
    80005398:	14050b63          	beqz	a0,800054ee <create+0x17e>
    return 0;

  ilock(dp);
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	6ac080e7          	jalr	1708(ra) # 80003a48 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053a4:	4601                	li	a2,0
    800053a6:	fb040593          	addi	a1,s0,-80
    800053aa:	8526                	mv	a0,s1
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	b80080e7          	jalr	-1152(ra) # 80003f2c <dirlookup>
    800053b4:	8aaa                	mv	s5,a0
    800053b6:	c921                	beqz	a0,80005406 <create+0x96>
    iunlockput(dp);
    800053b8:	8526                	mv	a0,s1
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	8f0080e7          	jalr	-1808(ra) # 80003caa <iunlockput>
    ilock(ip);
    800053c2:	8556                	mv	a0,s5
    800053c4:	ffffe097          	auipc	ra,0xffffe
    800053c8:	684080e7          	jalr	1668(ra) # 80003a48 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053cc:	4789                	li	a5,2
    800053ce:	02fb1563          	bne	s6,a5,800053f8 <create+0x88>
    800053d2:	044ad783          	lhu	a5,68(s5)
    800053d6:	37f9                	addiw	a5,a5,-2
    800053d8:	17c2                	slli	a5,a5,0x30
    800053da:	93c1                	srli	a5,a5,0x30
    800053dc:	4705                	li	a4,1
    800053de:	00f76d63          	bltu	a4,a5,800053f8 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053e2:	8556                	mv	a0,s5
    800053e4:	60a6                	ld	ra,72(sp)
    800053e6:	6406                	ld	s0,64(sp)
    800053e8:	74e2                	ld	s1,56(sp)
    800053ea:	7942                	ld	s2,48(sp)
    800053ec:	79a2                	ld	s3,40(sp)
    800053ee:	7a02                	ld	s4,32(sp)
    800053f0:	6ae2                	ld	s5,24(sp)
    800053f2:	6b42                	ld	s6,16(sp)
    800053f4:	6161                	addi	sp,sp,80
    800053f6:	8082                	ret
    iunlockput(ip);
    800053f8:	8556                	mv	a0,s5
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	8b0080e7          	jalr	-1872(ra) # 80003caa <iunlockput>
    return 0;
    80005402:	4a81                	li	s5,0
    80005404:	bff9                	j	800053e2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005406:	85da                	mv	a1,s6
    80005408:	4088                	lw	a0,0(s1)
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	4a6080e7          	jalr	1190(ra) # 800038b0 <ialloc>
    80005412:	8a2a                	mv	s4,a0
    80005414:	c529                	beqz	a0,8000545e <create+0xee>
  ilock(ip);
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	632080e7          	jalr	1586(ra) # 80003a48 <ilock>
  ip->major = major;
    8000541e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005422:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005426:	4905                	li	s2,1
    80005428:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000542c:	8552                	mv	a0,s4
    8000542e:	ffffe097          	auipc	ra,0xffffe
    80005432:	54e080e7          	jalr	1358(ra) # 8000397c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005436:	032b0b63          	beq	s6,s2,8000546c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000543a:	004a2603          	lw	a2,4(s4)
    8000543e:	fb040593          	addi	a1,s0,-80
    80005442:	8526                	mv	a0,s1
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	cf8080e7          	jalr	-776(ra) # 8000413c <dirlink>
    8000544c:	06054f63          	bltz	a0,800054ca <create+0x15a>
  iunlockput(dp);
    80005450:	8526                	mv	a0,s1
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	858080e7          	jalr	-1960(ra) # 80003caa <iunlockput>
  return ip;
    8000545a:	8ad2                	mv	s5,s4
    8000545c:	b759                	j	800053e2 <create+0x72>
    iunlockput(dp);
    8000545e:	8526                	mv	a0,s1
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	84a080e7          	jalr	-1974(ra) # 80003caa <iunlockput>
    return 0;
    80005468:	8ad2                	mv	s5,s4
    8000546a:	bfa5                	j	800053e2 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000546c:	004a2603          	lw	a2,4(s4)
    80005470:	00003597          	auipc	a1,0x3
    80005474:	2a058593          	addi	a1,a1,672 # 80008710 <syscalls+0x2c0>
    80005478:	8552                	mv	a0,s4
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	cc2080e7          	jalr	-830(ra) # 8000413c <dirlink>
    80005482:	04054463          	bltz	a0,800054ca <create+0x15a>
    80005486:	40d0                	lw	a2,4(s1)
    80005488:	00003597          	auipc	a1,0x3
    8000548c:	29058593          	addi	a1,a1,656 # 80008718 <syscalls+0x2c8>
    80005490:	8552                	mv	a0,s4
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	caa080e7          	jalr	-854(ra) # 8000413c <dirlink>
    8000549a:	02054863          	bltz	a0,800054ca <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    8000549e:	004a2603          	lw	a2,4(s4)
    800054a2:	fb040593          	addi	a1,s0,-80
    800054a6:	8526                	mv	a0,s1
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	c94080e7          	jalr	-876(ra) # 8000413c <dirlink>
    800054b0:	00054d63          	bltz	a0,800054ca <create+0x15a>
    dp->nlink++;  // for ".."
    800054b4:	04a4d783          	lhu	a5,74(s1)
    800054b8:	2785                	addiw	a5,a5,1
    800054ba:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054be:	8526                	mv	a0,s1
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	4bc080e7          	jalr	1212(ra) # 8000397c <iupdate>
    800054c8:	b761                	j	80005450 <create+0xe0>
  ip->nlink = 0;
    800054ca:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054ce:	8552                	mv	a0,s4
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	4ac080e7          	jalr	1196(ra) # 8000397c <iupdate>
  iunlockput(ip);
    800054d8:	8552                	mv	a0,s4
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	7d0080e7          	jalr	2000(ra) # 80003caa <iunlockput>
  iunlockput(dp);
    800054e2:	8526                	mv	a0,s1
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	7c6080e7          	jalr	1990(ra) # 80003caa <iunlockput>
  return 0;
    800054ec:	bddd                	j	800053e2 <create+0x72>
    return 0;
    800054ee:	8aaa                	mv	s5,a0
    800054f0:	bdcd                	j	800053e2 <create+0x72>

00000000800054f2 <sys_dup>:
{
    800054f2:	7179                	addi	sp,sp,-48
    800054f4:	f406                	sd	ra,40(sp)
    800054f6:	f022                	sd	s0,32(sp)
    800054f8:	ec26                	sd	s1,24(sp)
    800054fa:	e84a                	sd	s2,16(sp)
    800054fc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054fe:	fd840613          	addi	a2,s0,-40
    80005502:	4581                	li	a1,0
    80005504:	4501                	li	a0,0
    80005506:	00000097          	auipc	ra,0x0
    8000550a:	dc8080e7          	jalr	-568(ra) # 800052ce <argfd>
    return -1;
    8000550e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005510:	02054363          	bltz	a0,80005536 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005514:	fd843903          	ld	s2,-40(s0)
    80005518:	854a                	mv	a0,s2
    8000551a:	00000097          	auipc	ra,0x0
    8000551e:	e14080e7          	jalr	-492(ra) # 8000532e <fdalloc>
    80005522:	84aa                	mv	s1,a0
    return -1;
    80005524:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005526:	00054863          	bltz	a0,80005536 <sys_dup+0x44>
  filedup(f);
    8000552a:	854a                	mv	a0,s2
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	334080e7          	jalr	820(ra) # 80004860 <filedup>
  return fd;
    80005534:	87a6                	mv	a5,s1
}
    80005536:	853e                	mv	a0,a5
    80005538:	70a2                	ld	ra,40(sp)
    8000553a:	7402                	ld	s0,32(sp)
    8000553c:	64e2                	ld	s1,24(sp)
    8000553e:	6942                	ld	s2,16(sp)
    80005540:	6145                	addi	sp,sp,48
    80005542:	8082                	ret

0000000080005544 <sys_read>:
{
    80005544:	7179                	addi	sp,sp,-48
    80005546:	f406                	sd	ra,40(sp)
    80005548:	f022                	sd	s0,32(sp)
    8000554a:	1800                	addi	s0,sp,48
  READCOUNT++;
    8000554c:	00003717          	auipc	a4,0x3
    80005550:	3bc70713          	addi	a4,a4,956 # 80008908 <READCOUNT>
    80005554:	631c                	ld	a5,0(a4)
    80005556:	0785                	addi	a5,a5,1
    80005558:	e31c                	sd	a5,0(a4)
  argaddr(1, &p);
    8000555a:	fd840593          	addi	a1,s0,-40
    8000555e:	4505                	li	a0,1
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	878080e7          	jalr	-1928(ra) # 80002dd8 <argaddr>
  argint(2, &n);
    80005568:	fe440593          	addi	a1,s0,-28
    8000556c:	4509                	li	a0,2
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	84a080e7          	jalr	-1974(ra) # 80002db8 <argint>
  if(argfd(0, 0, &f) < 0)
    80005576:	fe840613          	addi	a2,s0,-24
    8000557a:	4581                	li	a1,0
    8000557c:	4501                	li	a0,0
    8000557e:	00000097          	auipc	ra,0x0
    80005582:	d50080e7          	jalr	-688(ra) # 800052ce <argfd>
    80005586:	87aa                	mv	a5,a0
    return -1;
    80005588:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000558a:	0007cc63          	bltz	a5,800055a2 <sys_read+0x5e>
  return fileread(f, p, n);
    8000558e:	fe442603          	lw	a2,-28(s0)
    80005592:	fd843583          	ld	a1,-40(s0)
    80005596:	fe843503          	ld	a0,-24(s0)
    8000559a:	fffff097          	auipc	ra,0xfffff
    8000559e:	452080e7          	jalr	1106(ra) # 800049ec <fileread>
}
    800055a2:	70a2                	ld	ra,40(sp)
    800055a4:	7402                	ld	s0,32(sp)
    800055a6:	6145                	addi	sp,sp,48
    800055a8:	8082                	ret

00000000800055aa <sys_write>:
{
    800055aa:	7179                	addi	sp,sp,-48
    800055ac:	f406                	sd	ra,40(sp)
    800055ae:	f022                	sd	s0,32(sp)
    800055b0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055b2:	fd840593          	addi	a1,s0,-40
    800055b6:	4505                	li	a0,1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	820080e7          	jalr	-2016(ra) # 80002dd8 <argaddr>
  argint(2, &n);
    800055c0:	fe440593          	addi	a1,s0,-28
    800055c4:	4509                	li	a0,2
    800055c6:	ffffd097          	auipc	ra,0xffffd
    800055ca:	7f2080e7          	jalr	2034(ra) # 80002db8 <argint>
  if(argfd(0, 0, &f) < 0)
    800055ce:	fe840613          	addi	a2,s0,-24
    800055d2:	4581                	li	a1,0
    800055d4:	4501                	li	a0,0
    800055d6:	00000097          	auipc	ra,0x0
    800055da:	cf8080e7          	jalr	-776(ra) # 800052ce <argfd>
    800055de:	87aa                	mv	a5,a0
    return -1;
    800055e0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055e2:	0007cc63          	bltz	a5,800055fa <sys_write+0x50>
  return filewrite(f, p, n);
    800055e6:	fe442603          	lw	a2,-28(s0)
    800055ea:	fd843583          	ld	a1,-40(s0)
    800055ee:	fe843503          	ld	a0,-24(s0)
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	4bc080e7          	jalr	1212(ra) # 80004aae <filewrite>
}
    800055fa:	70a2                	ld	ra,40(sp)
    800055fc:	7402                	ld	s0,32(sp)
    800055fe:	6145                	addi	sp,sp,48
    80005600:	8082                	ret

0000000080005602 <sys_close>:
{
    80005602:	1101                	addi	sp,sp,-32
    80005604:	ec06                	sd	ra,24(sp)
    80005606:	e822                	sd	s0,16(sp)
    80005608:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000560a:	fe040613          	addi	a2,s0,-32
    8000560e:	fec40593          	addi	a1,s0,-20
    80005612:	4501                	li	a0,0
    80005614:	00000097          	auipc	ra,0x0
    80005618:	cba080e7          	jalr	-838(ra) # 800052ce <argfd>
    return -1;
    8000561c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000561e:	02054463          	bltz	a0,80005646 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005622:	ffffc097          	auipc	ra,0xffffc
    80005626:	384080e7          	jalr	900(ra) # 800019a6 <myproc>
    8000562a:	fec42783          	lw	a5,-20(s0)
    8000562e:	07e9                	addi	a5,a5,26
    80005630:	078e                	slli	a5,a5,0x3
    80005632:	953e                	add	a0,a0,a5
    80005634:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005638:	fe043503          	ld	a0,-32(s0)
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	276080e7          	jalr	630(ra) # 800048b2 <fileclose>
  return 0;
    80005644:	4781                	li	a5,0
}
    80005646:	853e                	mv	a0,a5
    80005648:	60e2                	ld	ra,24(sp)
    8000564a:	6442                	ld	s0,16(sp)
    8000564c:	6105                	addi	sp,sp,32
    8000564e:	8082                	ret

0000000080005650 <sys_fstat>:
{
    80005650:	1101                	addi	sp,sp,-32
    80005652:	ec06                	sd	ra,24(sp)
    80005654:	e822                	sd	s0,16(sp)
    80005656:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005658:	fe040593          	addi	a1,s0,-32
    8000565c:	4505                	li	a0,1
    8000565e:	ffffd097          	auipc	ra,0xffffd
    80005662:	77a080e7          	jalr	1914(ra) # 80002dd8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005666:	fe840613          	addi	a2,s0,-24
    8000566a:	4581                	li	a1,0
    8000566c:	4501                	li	a0,0
    8000566e:	00000097          	auipc	ra,0x0
    80005672:	c60080e7          	jalr	-928(ra) # 800052ce <argfd>
    80005676:	87aa                	mv	a5,a0
    return -1;
    80005678:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000567a:	0007ca63          	bltz	a5,8000568e <sys_fstat+0x3e>
  return filestat(f, st);
    8000567e:	fe043583          	ld	a1,-32(s0)
    80005682:	fe843503          	ld	a0,-24(s0)
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	2f4080e7          	jalr	756(ra) # 8000497a <filestat>
}
    8000568e:	60e2                	ld	ra,24(sp)
    80005690:	6442                	ld	s0,16(sp)
    80005692:	6105                	addi	sp,sp,32
    80005694:	8082                	ret

0000000080005696 <sys_link>:
{
    80005696:	7169                	addi	sp,sp,-304
    80005698:	f606                	sd	ra,296(sp)
    8000569a:	f222                	sd	s0,288(sp)
    8000569c:	ee26                	sd	s1,280(sp)
    8000569e:	ea4a                	sd	s2,272(sp)
    800056a0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056a2:	08000613          	li	a2,128
    800056a6:	ed040593          	addi	a1,s0,-304
    800056aa:	4501                	li	a0,0
    800056ac:	ffffd097          	auipc	ra,0xffffd
    800056b0:	74c080e7          	jalr	1868(ra) # 80002df8 <argstr>
    return -1;
    800056b4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056b6:	10054e63          	bltz	a0,800057d2 <sys_link+0x13c>
    800056ba:	08000613          	li	a2,128
    800056be:	f5040593          	addi	a1,s0,-176
    800056c2:	4505                	li	a0,1
    800056c4:	ffffd097          	auipc	ra,0xffffd
    800056c8:	734080e7          	jalr	1844(ra) # 80002df8 <argstr>
    return -1;
    800056cc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056ce:	10054263          	bltz	a0,800057d2 <sys_link+0x13c>
  begin_op();
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	d1c080e7          	jalr	-740(ra) # 800043ee <begin_op>
  if((ip = namei(old)) == 0){
    800056da:	ed040513          	addi	a0,s0,-304
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	b10080e7          	jalr	-1264(ra) # 800041ee <namei>
    800056e6:	84aa                	mv	s1,a0
    800056e8:	c551                	beqz	a0,80005774 <sys_link+0xde>
  ilock(ip);
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	35e080e7          	jalr	862(ra) # 80003a48 <ilock>
  if(ip->type == T_DIR){
    800056f2:	04449703          	lh	a4,68(s1)
    800056f6:	4785                	li	a5,1
    800056f8:	08f70463          	beq	a4,a5,80005780 <sys_link+0xea>
  ip->nlink++;
    800056fc:	04a4d783          	lhu	a5,74(s1)
    80005700:	2785                	addiw	a5,a5,1
    80005702:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	274080e7          	jalr	628(ra) # 8000397c <iupdate>
  iunlock(ip);
    80005710:	8526                	mv	a0,s1
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	3f8080e7          	jalr	1016(ra) # 80003b0a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000571a:	fd040593          	addi	a1,s0,-48
    8000571e:	f5040513          	addi	a0,s0,-176
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	aea080e7          	jalr	-1302(ra) # 8000420c <nameiparent>
    8000572a:	892a                	mv	s2,a0
    8000572c:	c935                	beqz	a0,800057a0 <sys_link+0x10a>
  ilock(dp);
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	31a080e7          	jalr	794(ra) # 80003a48 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005736:	00092703          	lw	a4,0(s2)
    8000573a:	409c                	lw	a5,0(s1)
    8000573c:	04f71d63          	bne	a4,a5,80005796 <sys_link+0x100>
    80005740:	40d0                	lw	a2,4(s1)
    80005742:	fd040593          	addi	a1,s0,-48
    80005746:	854a                	mv	a0,s2
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	9f4080e7          	jalr	-1548(ra) # 8000413c <dirlink>
    80005750:	04054363          	bltz	a0,80005796 <sys_link+0x100>
  iunlockput(dp);
    80005754:	854a                	mv	a0,s2
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	554080e7          	jalr	1364(ra) # 80003caa <iunlockput>
  iput(ip);
    8000575e:	8526                	mv	a0,s1
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	4a2080e7          	jalr	1186(ra) # 80003c02 <iput>
  end_op();
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	d00080e7          	jalr	-768(ra) # 80004468 <end_op>
  return 0;
    80005770:	4781                	li	a5,0
    80005772:	a085                	j	800057d2 <sys_link+0x13c>
    end_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	cf4080e7          	jalr	-780(ra) # 80004468 <end_op>
    return -1;
    8000577c:	57fd                	li	a5,-1
    8000577e:	a891                	j	800057d2 <sys_link+0x13c>
    iunlockput(ip);
    80005780:	8526                	mv	a0,s1
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	528080e7          	jalr	1320(ra) # 80003caa <iunlockput>
    end_op();
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	cde080e7          	jalr	-802(ra) # 80004468 <end_op>
    return -1;
    80005792:	57fd                	li	a5,-1
    80005794:	a83d                	j	800057d2 <sys_link+0x13c>
    iunlockput(dp);
    80005796:	854a                	mv	a0,s2
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	512080e7          	jalr	1298(ra) # 80003caa <iunlockput>
  ilock(ip);
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	2a6080e7          	jalr	678(ra) # 80003a48 <ilock>
  ip->nlink--;
    800057aa:	04a4d783          	lhu	a5,74(s1)
    800057ae:	37fd                	addiw	a5,a5,-1
    800057b0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057b4:	8526                	mv	a0,s1
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	1c6080e7          	jalr	454(ra) # 8000397c <iupdate>
  iunlockput(ip);
    800057be:	8526                	mv	a0,s1
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	4ea080e7          	jalr	1258(ra) # 80003caa <iunlockput>
  end_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	ca0080e7          	jalr	-864(ra) # 80004468 <end_op>
  return -1;
    800057d0:	57fd                	li	a5,-1
}
    800057d2:	853e                	mv	a0,a5
    800057d4:	70b2                	ld	ra,296(sp)
    800057d6:	7412                	ld	s0,288(sp)
    800057d8:	64f2                	ld	s1,280(sp)
    800057da:	6952                	ld	s2,272(sp)
    800057dc:	6155                	addi	sp,sp,304
    800057de:	8082                	ret

00000000800057e0 <sys_unlink>:
{
    800057e0:	7151                	addi	sp,sp,-240
    800057e2:	f586                	sd	ra,232(sp)
    800057e4:	f1a2                	sd	s0,224(sp)
    800057e6:	eda6                	sd	s1,216(sp)
    800057e8:	e9ca                	sd	s2,208(sp)
    800057ea:	e5ce                	sd	s3,200(sp)
    800057ec:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057ee:	08000613          	li	a2,128
    800057f2:	f3040593          	addi	a1,s0,-208
    800057f6:	4501                	li	a0,0
    800057f8:	ffffd097          	auipc	ra,0xffffd
    800057fc:	600080e7          	jalr	1536(ra) # 80002df8 <argstr>
    80005800:	18054163          	bltz	a0,80005982 <sys_unlink+0x1a2>
  begin_op();
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	bea080e7          	jalr	-1046(ra) # 800043ee <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000580c:	fb040593          	addi	a1,s0,-80
    80005810:	f3040513          	addi	a0,s0,-208
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	9f8080e7          	jalr	-1544(ra) # 8000420c <nameiparent>
    8000581c:	84aa                	mv	s1,a0
    8000581e:	c979                	beqz	a0,800058f4 <sys_unlink+0x114>
  ilock(dp);
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	228080e7          	jalr	552(ra) # 80003a48 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005828:	00003597          	auipc	a1,0x3
    8000582c:	ee858593          	addi	a1,a1,-280 # 80008710 <syscalls+0x2c0>
    80005830:	fb040513          	addi	a0,s0,-80
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	6de080e7          	jalr	1758(ra) # 80003f12 <namecmp>
    8000583c:	14050a63          	beqz	a0,80005990 <sys_unlink+0x1b0>
    80005840:	00003597          	auipc	a1,0x3
    80005844:	ed858593          	addi	a1,a1,-296 # 80008718 <syscalls+0x2c8>
    80005848:	fb040513          	addi	a0,s0,-80
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	6c6080e7          	jalr	1734(ra) # 80003f12 <namecmp>
    80005854:	12050e63          	beqz	a0,80005990 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005858:	f2c40613          	addi	a2,s0,-212
    8000585c:	fb040593          	addi	a1,s0,-80
    80005860:	8526                	mv	a0,s1
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	6ca080e7          	jalr	1738(ra) # 80003f2c <dirlookup>
    8000586a:	892a                	mv	s2,a0
    8000586c:	12050263          	beqz	a0,80005990 <sys_unlink+0x1b0>
  ilock(ip);
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	1d8080e7          	jalr	472(ra) # 80003a48 <ilock>
  if(ip->nlink < 1)
    80005878:	04a91783          	lh	a5,74(s2)
    8000587c:	08f05263          	blez	a5,80005900 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005880:	04491703          	lh	a4,68(s2)
    80005884:	4785                	li	a5,1
    80005886:	08f70563          	beq	a4,a5,80005910 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000588a:	4641                	li	a2,16
    8000588c:	4581                	li	a1,0
    8000588e:	fc040513          	addi	a0,s0,-64
    80005892:	ffffb097          	auipc	ra,0xffffb
    80005896:	43c080e7          	jalr	1084(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000589a:	4741                	li	a4,16
    8000589c:	f2c42683          	lw	a3,-212(s0)
    800058a0:	fc040613          	addi	a2,s0,-64
    800058a4:	4581                	li	a1,0
    800058a6:	8526                	mv	a0,s1
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	54c080e7          	jalr	1356(ra) # 80003df4 <writei>
    800058b0:	47c1                	li	a5,16
    800058b2:	0af51563          	bne	a0,a5,8000595c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058b6:	04491703          	lh	a4,68(s2)
    800058ba:	4785                	li	a5,1
    800058bc:	0af70863          	beq	a4,a5,8000596c <sys_unlink+0x18c>
  iunlockput(dp);
    800058c0:	8526                	mv	a0,s1
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	3e8080e7          	jalr	1000(ra) # 80003caa <iunlockput>
  ip->nlink--;
    800058ca:	04a95783          	lhu	a5,74(s2)
    800058ce:	37fd                	addiw	a5,a5,-1
    800058d0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058d4:	854a                	mv	a0,s2
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	0a6080e7          	jalr	166(ra) # 8000397c <iupdate>
  iunlockput(ip);
    800058de:	854a                	mv	a0,s2
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	3ca080e7          	jalr	970(ra) # 80003caa <iunlockput>
  end_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	b80080e7          	jalr	-1152(ra) # 80004468 <end_op>
  return 0;
    800058f0:	4501                	li	a0,0
    800058f2:	a84d                	j	800059a4 <sys_unlink+0x1c4>
    end_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	b74080e7          	jalr	-1164(ra) # 80004468 <end_op>
    return -1;
    800058fc:	557d                	li	a0,-1
    800058fe:	a05d                	j	800059a4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005900:	00003517          	auipc	a0,0x3
    80005904:	e2050513          	addi	a0,a0,-480 # 80008720 <syscalls+0x2d0>
    80005908:	ffffb097          	auipc	ra,0xffffb
    8000590c:	c34080e7          	jalr	-972(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005910:	04c92703          	lw	a4,76(s2)
    80005914:	02000793          	li	a5,32
    80005918:	f6e7f9e3          	bgeu	a5,a4,8000588a <sys_unlink+0xaa>
    8000591c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005920:	4741                	li	a4,16
    80005922:	86ce                	mv	a3,s3
    80005924:	f1840613          	addi	a2,s0,-232
    80005928:	4581                	li	a1,0
    8000592a:	854a                	mv	a0,s2
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	3d0080e7          	jalr	976(ra) # 80003cfc <readi>
    80005934:	47c1                	li	a5,16
    80005936:	00f51b63          	bne	a0,a5,8000594c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000593a:	f1845783          	lhu	a5,-232(s0)
    8000593e:	e7a1                	bnez	a5,80005986 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005940:	29c1                	addiw	s3,s3,16
    80005942:	04c92783          	lw	a5,76(s2)
    80005946:	fcf9ede3          	bltu	s3,a5,80005920 <sys_unlink+0x140>
    8000594a:	b781                	j	8000588a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000594c:	00003517          	auipc	a0,0x3
    80005950:	dec50513          	addi	a0,a0,-532 # 80008738 <syscalls+0x2e8>
    80005954:	ffffb097          	auipc	ra,0xffffb
    80005958:	be8080e7          	jalr	-1048(ra) # 8000053c <panic>
    panic("unlink: writei");
    8000595c:	00003517          	auipc	a0,0x3
    80005960:	df450513          	addi	a0,a0,-524 # 80008750 <syscalls+0x300>
    80005964:	ffffb097          	auipc	ra,0xffffb
    80005968:	bd8080e7          	jalr	-1064(ra) # 8000053c <panic>
    dp->nlink--;
    8000596c:	04a4d783          	lhu	a5,74(s1)
    80005970:	37fd                	addiw	a5,a5,-1
    80005972:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005976:	8526                	mv	a0,s1
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	004080e7          	jalr	4(ra) # 8000397c <iupdate>
    80005980:	b781                	j	800058c0 <sys_unlink+0xe0>
    return -1;
    80005982:	557d                	li	a0,-1
    80005984:	a005                	j	800059a4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005986:	854a                	mv	a0,s2
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	322080e7          	jalr	802(ra) # 80003caa <iunlockput>
  iunlockput(dp);
    80005990:	8526                	mv	a0,s1
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	318080e7          	jalr	792(ra) # 80003caa <iunlockput>
  end_op();
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	ace080e7          	jalr	-1330(ra) # 80004468 <end_op>
  return -1;
    800059a2:	557d                	li	a0,-1
}
    800059a4:	70ae                	ld	ra,232(sp)
    800059a6:	740e                	ld	s0,224(sp)
    800059a8:	64ee                	ld	s1,216(sp)
    800059aa:	694e                	ld	s2,208(sp)
    800059ac:	69ae                	ld	s3,200(sp)
    800059ae:	616d                	addi	sp,sp,240
    800059b0:	8082                	ret

00000000800059b2 <sys_open>:

uint64
sys_open(void)
{
    800059b2:	7131                	addi	sp,sp,-192
    800059b4:	fd06                	sd	ra,184(sp)
    800059b6:	f922                	sd	s0,176(sp)
    800059b8:	f526                	sd	s1,168(sp)
    800059ba:	f14a                	sd	s2,160(sp)
    800059bc:	ed4e                	sd	s3,152(sp)
    800059be:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059c0:	f4c40593          	addi	a1,s0,-180
    800059c4:	4505                	li	a0,1
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	3f2080e7          	jalr	1010(ra) # 80002db8 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059ce:	08000613          	li	a2,128
    800059d2:	f5040593          	addi	a1,s0,-176
    800059d6:	4501                	li	a0,0
    800059d8:	ffffd097          	auipc	ra,0xffffd
    800059dc:	420080e7          	jalr	1056(ra) # 80002df8 <argstr>
    800059e0:	87aa                	mv	a5,a0
    return -1;
    800059e2:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059e4:	0a07c863          	bltz	a5,80005a94 <sys_open+0xe2>

  begin_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	a06080e7          	jalr	-1530(ra) # 800043ee <begin_op>

  if(omode & O_CREATE){
    800059f0:	f4c42783          	lw	a5,-180(s0)
    800059f4:	2007f793          	andi	a5,a5,512
    800059f8:	cbdd                	beqz	a5,80005aae <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800059fa:	4681                	li	a3,0
    800059fc:	4601                	li	a2,0
    800059fe:	4589                	li	a1,2
    80005a00:	f5040513          	addi	a0,s0,-176
    80005a04:	00000097          	auipc	ra,0x0
    80005a08:	96c080e7          	jalr	-1684(ra) # 80005370 <create>
    80005a0c:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a0e:	c951                	beqz	a0,80005aa2 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a10:	04449703          	lh	a4,68(s1)
    80005a14:	478d                	li	a5,3
    80005a16:	00f71763          	bne	a4,a5,80005a24 <sys_open+0x72>
    80005a1a:	0464d703          	lhu	a4,70(s1)
    80005a1e:	47a5                	li	a5,9
    80005a20:	0ce7ec63          	bltu	a5,a4,80005af8 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	dd2080e7          	jalr	-558(ra) # 800047f6 <filealloc>
    80005a2c:	892a                	mv	s2,a0
    80005a2e:	c56d                	beqz	a0,80005b18 <sys_open+0x166>
    80005a30:	00000097          	auipc	ra,0x0
    80005a34:	8fe080e7          	jalr	-1794(ra) # 8000532e <fdalloc>
    80005a38:	89aa                	mv	s3,a0
    80005a3a:	0c054a63          	bltz	a0,80005b0e <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a3e:	04449703          	lh	a4,68(s1)
    80005a42:	478d                	li	a5,3
    80005a44:	0ef70563          	beq	a4,a5,80005b2e <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a48:	4789                	li	a5,2
    80005a4a:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005a4e:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005a52:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005a56:	f4c42783          	lw	a5,-180(s0)
    80005a5a:	0017c713          	xori	a4,a5,1
    80005a5e:	8b05                	andi	a4,a4,1
    80005a60:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a64:	0037f713          	andi	a4,a5,3
    80005a68:	00e03733          	snez	a4,a4
    80005a6c:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a70:	4007f793          	andi	a5,a5,1024
    80005a74:	c791                	beqz	a5,80005a80 <sys_open+0xce>
    80005a76:	04449703          	lh	a4,68(s1)
    80005a7a:	4789                	li	a5,2
    80005a7c:	0cf70063          	beq	a4,a5,80005b3c <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005a80:	8526                	mv	a0,s1
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	088080e7          	jalr	136(ra) # 80003b0a <iunlock>
  end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	9de080e7          	jalr	-1570(ra) # 80004468 <end_op>

  return fd;
    80005a92:	854e                	mv	a0,s3
}
    80005a94:	70ea                	ld	ra,184(sp)
    80005a96:	744a                	ld	s0,176(sp)
    80005a98:	74aa                	ld	s1,168(sp)
    80005a9a:	790a                	ld	s2,160(sp)
    80005a9c:	69ea                	ld	s3,152(sp)
    80005a9e:	6129                	addi	sp,sp,192
    80005aa0:	8082                	ret
      end_op();
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	9c6080e7          	jalr	-1594(ra) # 80004468 <end_op>
      return -1;
    80005aaa:	557d                	li	a0,-1
    80005aac:	b7e5                	j	80005a94 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005aae:	f5040513          	addi	a0,s0,-176
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	73c080e7          	jalr	1852(ra) # 800041ee <namei>
    80005aba:	84aa                	mv	s1,a0
    80005abc:	c905                	beqz	a0,80005aec <sys_open+0x13a>
    ilock(ip);
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	f8a080e7          	jalr	-118(ra) # 80003a48 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ac6:	04449703          	lh	a4,68(s1)
    80005aca:	4785                	li	a5,1
    80005acc:	f4f712e3          	bne	a4,a5,80005a10 <sys_open+0x5e>
    80005ad0:	f4c42783          	lw	a5,-180(s0)
    80005ad4:	dba1                	beqz	a5,80005a24 <sys_open+0x72>
      iunlockput(ip);
    80005ad6:	8526                	mv	a0,s1
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	1d2080e7          	jalr	466(ra) # 80003caa <iunlockput>
      end_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	988080e7          	jalr	-1656(ra) # 80004468 <end_op>
      return -1;
    80005ae8:	557d                	li	a0,-1
    80005aea:	b76d                	j	80005a94 <sys_open+0xe2>
      end_op();
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	97c080e7          	jalr	-1668(ra) # 80004468 <end_op>
      return -1;
    80005af4:	557d                	li	a0,-1
    80005af6:	bf79                	j	80005a94 <sys_open+0xe2>
    iunlockput(ip);
    80005af8:	8526                	mv	a0,s1
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	1b0080e7          	jalr	432(ra) # 80003caa <iunlockput>
    end_op();
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	966080e7          	jalr	-1690(ra) # 80004468 <end_op>
    return -1;
    80005b0a:	557d                	li	a0,-1
    80005b0c:	b761                	j	80005a94 <sys_open+0xe2>
      fileclose(f);
    80005b0e:	854a                	mv	a0,s2
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	da2080e7          	jalr	-606(ra) # 800048b2 <fileclose>
    iunlockput(ip);
    80005b18:	8526                	mv	a0,s1
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	190080e7          	jalr	400(ra) # 80003caa <iunlockput>
    end_op();
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	946080e7          	jalr	-1722(ra) # 80004468 <end_op>
    return -1;
    80005b2a:	557d                	li	a0,-1
    80005b2c:	b7a5                	j	80005a94 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005b2e:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005b32:	04649783          	lh	a5,70(s1)
    80005b36:	02f91223          	sh	a5,36(s2)
    80005b3a:	bf21                	j	80005a52 <sys_open+0xa0>
    itrunc(ip);
    80005b3c:	8526                	mv	a0,s1
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	018080e7          	jalr	24(ra) # 80003b56 <itrunc>
    80005b46:	bf2d                	j	80005a80 <sys_open+0xce>

0000000080005b48 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b48:	7175                	addi	sp,sp,-144
    80005b4a:	e506                	sd	ra,136(sp)
    80005b4c:	e122                	sd	s0,128(sp)
    80005b4e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	89e080e7          	jalr	-1890(ra) # 800043ee <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b58:	08000613          	li	a2,128
    80005b5c:	f7040593          	addi	a1,s0,-144
    80005b60:	4501                	li	a0,0
    80005b62:	ffffd097          	auipc	ra,0xffffd
    80005b66:	296080e7          	jalr	662(ra) # 80002df8 <argstr>
    80005b6a:	02054963          	bltz	a0,80005b9c <sys_mkdir+0x54>
    80005b6e:	4681                	li	a3,0
    80005b70:	4601                	li	a2,0
    80005b72:	4585                	li	a1,1
    80005b74:	f7040513          	addi	a0,s0,-144
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	7f8080e7          	jalr	2040(ra) # 80005370 <create>
    80005b80:	cd11                	beqz	a0,80005b9c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	128080e7          	jalr	296(ra) # 80003caa <iunlockput>
  end_op();
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	8de080e7          	jalr	-1826(ra) # 80004468 <end_op>
  return 0;
    80005b92:	4501                	li	a0,0
}
    80005b94:	60aa                	ld	ra,136(sp)
    80005b96:	640a                	ld	s0,128(sp)
    80005b98:	6149                	addi	sp,sp,144
    80005b9a:	8082                	ret
    end_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	8cc080e7          	jalr	-1844(ra) # 80004468 <end_op>
    return -1;
    80005ba4:	557d                	li	a0,-1
    80005ba6:	b7fd                	j	80005b94 <sys_mkdir+0x4c>

0000000080005ba8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ba8:	7135                	addi	sp,sp,-160
    80005baa:	ed06                	sd	ra,152(sp)
    80005bac:	e922                	sd	s0,144(sp)
    80005bae:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	83e080e7          	jalr	-1986(ra) # 800043ee <begin_op>
  argint(1, &major);
    80005bb8:	f6c40593          	addi	a1,s0,-148
    80005bbc:	4505                	li	a0,1
    80005bbe:	ffffd097          	auipc	ra,0xffffd
    80005bc2:	1fa080e7          	jalr	506(ra) # 80002db8 <argint>
  argint(2, &minor);
    80005bc6:	f6840593          	addi	a1,s0,-152
    80005bca:	4509                	li	a0,2
    80005bcc:	ffffd097          	auipc	ra,0xffffd
    80005bd0:	1ec080e7          	jalr	492(ra) # 80002db8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bd4:	08000613          	li	a2,128
    80005bd8:	f7040593          	addi	a1,s0,-144
    80005bdc:	4501                	li	a0,0
    80005bde:	ffffd097          	auipc	ra,0xffffd
    80005be2:	21a080e7          	jalr	538(ra) # 80002df8 <argstr>
    80005be6:	02054b63          	bltz	a0,80005c1c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bea:	f6841683          	lh	a3,-152(s0)
    80005bee:	f6c41603          	lh	a2,-148(s0)
    80005bf2:	458d                	li	a1,3
    80005bf4:	f7040513          	addi	a0,s0,-144
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	778080e7          	jalr	1912(ra) # 80005370 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c00:	cd11                	beqz	a0,80005c1c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	0a8080e7          	jalr	168(ra) # 80003caa <iunlockput>
  end_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	85e080e7          	jalr	-1954(ra) # 80004468 <end_op>
  return 0;
    80005c12:	4501                	li	a0,0
}
    80005c14:	60ea                	ld	ra,152(sp)
    80005c16:	644a                	ld	s0,144(sp)
    80005c18:	610d                	addi	sp,sp,160
    80005c1a:	8082                	ret
    end_op();
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	84c080e7          	jalr	-1972(ra) # 80004468 <end_op>
    return -1;
    80005c24:	557d                	li	a0,-1
    80005c26:	b7fd                	j	80005c14 <sys_mknod+0x6c>

0000000080005c28 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c28:	7135                	addi	sp,sp,-160
    80005c2a:	ed06                	sd	ra,152(sp)
    80005c2c:	e922                	sd	s0,144(sp)
    80005c2e:	e526                	sd	s1,136(sp)
    80005c30:	e14a                	sd	s2,128(sp)
    80005c32:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c34:	ffffc097          	auipc	ra,0xffffc
    80005c38:	d72080e7          	jalr	-654(ra) # 800019a6 <myproc>
    80005c3c:	892a                	mv	s2,a0
  
  begin_op();
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	7b0080e7          	jalr	1968(ra) # 800043ee <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c46:	08000613          	li	a2,128
    80005c4a:	f6040593          	addi	a1,s0,-160
    80005c4e:	4501                	li	a0,0
    80005c50:	ffffd097          	auipc	ra,0xffffd
    80005c54:	1a8080e7          	jalr	424(ra) # 80002df8 <argstr>
    80005c58:	04054b63          	bltz	a0,80005cae <sys_chdir+0x86>
    80005c5c:	f6040513          	addi	a0,s0,-160
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	58e080e7          	jalr	1422(ra) # 800041ee <namei>
    80005c68:	84aa                	mv	s1,a0
    80005c6a:	c131                	beqz	a0,80005cae <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	ddc080e7          	jalr	-548(ra) # 80003a48 <ilock>
  if(ip->type != T_DIR){
    80005c74:	04449703          	lh	a4,68(s1)
    80005c78:	4785                	li	a5,1
    80005c7a:	04f71063          	bne	a4,a5,80005cba <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c7e:	8526                	mv	a0,s1
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	e8a080e7          	jalr	-374(ra) # 80003b0a <iunlock>
  iput(p->cwd);
    80005c88:	15093503          	ld	a0,336(s2)
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	f76080e7          	jalr	-138(ra) # 80003c02 <iput>
  end_op();
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	7d4080e7          	jalr	2004(ra) # 80004468 <end_op>
  p->cwd = ip;
    80005c9c:	14993823          	sd	s1,336(s2)
  return 0;
    80005ca0:	4501                	li	a0,0
}
    80005ca2:	60ea                	ld	ra,152(sp)
    80005ca4:	644a                	ld	s0,144(sp)
    80005ca6:	64aa                	ld	s1,136(sp)
    80005ca8:	690a                	ld	s2,128(sp)
    80005caa:	610d                	addi	sp,sp,160
    80005cac:	8082                	ret
    end_op();
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	7ba080e7          	jalr	1978(ra) # 80004468 <end_op>
    return -1;
    80005cb6:	557d                	li	a0,-1
    80005cb8:	b7ed                	j	80005ca2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005cba:	8526                	mv	a0,s1
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	fee080e7          	jalr	-18(ra) # 80003caa <iunlockput>
    end_op();
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	7a4080e7          	jalr	1956(ra) # 80004468 <end_op>
    return -1;
    80005ccc:	557d                	li	a0,-1
    80005cce:	bfd1                	j	80005ca2 <sys_chdir+0x7a>

0000000080005cd0 <sys_exec>:

uint64
sys_exec(void)
{
    80005cd0:	7121                	addi	sp,sp,-448
    80005cd2:	ff06                	sd	ra,440(sp)
    80005cd4:	fb22                	sd	s0,432(sp)
    80005cd6:	f726                	sd	s1,424(sp)
    80005cd8:	f34a                	sd	s2,416(sp)
    80005cda:	ef4e                	sd	s3,408(sp)
    80005cdc:	eb52                	sd	s4,400(sp)
    80005cde:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ce0:	e4840593          	addi	a1,s0,-440
    80005ce4:	4505                	li	a0,1
    80005ce6:	ffffd097          	auipc	ra,0xffffd
    80005cea:	0f2080e7          	jalr	242(ra) # 80002dd8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005cee:	08000613          	li	a2,128
    80005cf2:	f5040593          	addi	a1,s0,-176
    80005cf6:	4501                	li	a0,0
    80005cf8:	ffffd097          	auipc	ra,0xffffd
    80005cfc:	100080e7          	jalr	256(ra) # 80002df8 <argstr>
    80005d00:	87aa                	mv	a5,a0
    return -1;
    80005d02:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d04:	0c07c263          	bltz	a5,80005dc8 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005d08:	10000613          	li	a2,256
    80005d0c:	4581                	li	a1,0
    80005d0e:	e5040513          	addi	a0,s0,-432
    80005d12:	ffffb097          	auipc	ra,0xffffb
    80005d16:	fbc080e7          	jalr	-68(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d1a:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005d1e:	89a6                	mv	s3,s1
    80005d20:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d22:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d26:	00391513          	slli	a0,s2,0x3
    80005d2a:	e4040593          	addi	a1,s0,-448
    80005d2e:	e4843783          	ld	a5,-440(s0)
    80005d32:	953e                	add	a0,a0,a5
    80005d34:	ffffd097          	auipc	ra,0xffffd
    80005d38:	fe6080e7          	jalr	-26(ra) # 80002d1a <fetchaddr>
    80005d3c:	02054a63          	bltz	a0,80005d70 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005d40:	e4043783          	ld	a5,-448(s0)
    80005d44:	c3b9                	beqz	a5,80005d8a <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d46:	ffffb097          	auipc	ra,0xffffb
    80005d4a:	d9c080e7          	jalr	-612(ra) # 80000ae2 <kalloc>
    80005d4e:	85aa                	mv	a1,a0
    80005d50:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d54:	cd11                	beqz	a0,80005d70 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d56:	6605                	lui	a2,0x1
    80005d58:	e4043503          	ld	a0,-448(s0)
    80005d5c:	ffffd097          	auipc	ra,0xffffd
    80005d60:	010080e7          	jalr	16(ra) # 80002d6c <fetchstr>
    80005d64:	00054663          	bltz	a0,80005d70 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005d68:	0905                	addi	s2,s2,1
    80005d6a:	09a1                	addi	s3,s3,8
    80005d6c:	fb491de3          	bne	s2,s4,80005d26 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d70:	f5040913          	addi	s2,s0,-176
    80005d74:	6088                	ld	a0,0(s1)
    80005d76:	c921                	beqz	a0,80005dc6 <sys_exec+0xf6>
    kfree(argv[i]);
    80005d78:	ffffb097          	auipc	ra,0xffffb
    80005d7c:	c6c080e7          	jalr	-916(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d80:	04a1                	addi	s1,s1,8
    80005d82:	ff2499e3          	bne	s1,s2,80005d74 <sys_exec+0xa4>
  return -1;
    80005d86:	557d                	li	a0,-1
    80005d88:	a081                	j	80005dc8 <sys_exec+0xf8>
      argv[i] = 0;
    80005d8a:	0009079b          	sext.w	a5,s2
    80005d8e:	078e                	slli	a5,a5,0x3
    80005d90:	fd078793          	addi	a5,a5,-48
    80005d94:	97a2                	add	a5,a5,s0
    80005d96:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005d9a:	e5040593          	addi	a1,s0,-432
    80005d9e:	f5040513          	addi	a0,s0,-176
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	186080e7          	jalr	390(ra) # 80004f28 <exec>
    80005daa:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dac:	f5040993          	addi	s3,s0,-176
    80005db0:	6088                	ld	a0,0(s1)
    80005db2:	c901                	beqz	a0,80005dc2 <sys_exec+0xf2>
    kfree(argv[i]);
    80005db4:	ffffb097          	auipc	ra,0xffffb
    80005db8:	c30080e7          	jalr	-976(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dbc:	04a1                	addi	s1,s1,8
    80005dbe:	ff3499e3          	bne	s1,s3,80005db0 <sys_exec+0xe0>
  return ret;
    80005dc2:	854a                	mv	a0,s2
    80005dc4:	a011                	j	80005dc8 <sys_exec+0xf8>
  return -1;
    80005dc6:	557d                	li	a0,-1
}
    80005dc8:	70fa                	ld	ra,440(sp)
    80005dca:	745a                	ld	s0,432(sp)
    80005dcc:	74ba                	ld	s1,424(sp)
    80005dce:	791a                	ld	s2,416(sp)
    80005dd0:	69fa                	ld	s3,408(sp)
    80005dd2:	6a5a                	ld	s4,400(sp)
    80005dd4:	6139                	addi	sp,sp,448
    80005dd6:	8082                	ret

0000000080005dd8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dd8:	7139                	addi	sp,sp,-64
    80005dda:	fc06                	sd	ra,56(sp)
    80005ddc:	f822                	sd	s0,48(sp)
    80005dde:	f426                	sd	s1,40(sp)
    80005de0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005de2:	ffffc097          	auipc	ra,0xffffc
    80005de6:	bc4080e7          	jalr	-1084(ra) # 800019a6 <myproc>
    80005dea:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005dec:	fd840593          	addi	a1,s0,-40
    80005df0:	4501                	li	a0,0
    80005df2:	ffffd097          	auipc	ra,0xffffd
    80005df6:	fe6080e7          	jalr	-26(ra) # 80002dd8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005dfa:	fc840593          	addi	a1,s0,-56
    80005dfe:	fd040513          	addi	a0,s0,-48
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	ddc080e7          	jalr	-548(ra) # 80004bde <pipealloc>
    return -1;
    80005e0a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e0c:	0c054463          	bltz	a0,80005ed4 <sys_pipe+0xfc>
  fd0 = -1;
    80005e10:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e14:	fd043503          	ld	a0,-48(s0)
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	516080e7          	jalr	1302(ra) # 8000532e <fdalloc>
    80005e20:	fca42223          	sw	a0,-60(s0)
    80005e24:	08054b63          	bltz	a0,80005eba <sys_pipe+0xe2>
    80005e28:	fc843503          	ld	a0,-56(s0)
    80005e2c:	fffff097          	auipc	ra,0xfffff
    80005e30:	502080e7          	jalr	1282(ra) # 8000532e <fdalloc>
    80005e34:	fca42023          	sw	a0,-64(s0)
    80005e38:	06054863          	bltz	a0,80005ea8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e3c:	4691                	li	a3,4
    80005e3e:	fc440613          	addi	a2,s0,-60
    80005e42:	fd843583          	ld	a1,-40(s0)
    80005e46:	68a8                	ld	a0,80(s1)
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	81e080e7          	jalr	-2018(ra) # 80001666 <copyout>
    80005e50:	02054063          	bltz	a0,80005e70 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e54:	4691                	li	a3,4
    80005e56:	fc040613          	addi	a2,s0,-64
    80005e5a:	fd843583          	ld	a1,-40(s0)
    80005e5e:	0591                	addi	a1,a1,4
    80005e60:	68a8                	ld	a0,80(s1)
    80005e62:	ffffc097          	auipc	ra,0xffffc
    80005e66:	804080e7          	jalr	-2044(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e6a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e6c:	06055463          	bgez	a0,80005ed4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e70:	fc442783          	lw	a5,-60(s0)
    80005e74:	07e9                	addi	a5,a5,26
    80005e76:	078e                	slli	a5,a5,0x3
    80005e78:	97a6                	add	a5,a5,s1
    80005e7a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e7e:	fc042783          	lw	a5,-64(s0)
    80005e82:	07e9                	addi	a5,a5,26
    80005e84:	078e                	slli	a5,a5,0x3
    80005e86:	94be                	add	s1,s1,a5
    80005e88:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e8c:	fd043503          	ld	a0,-48(s0)
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	a22080e7          	jalr	-1502(ra) # 800048b2 <fileclose>
    fileclose(wf);
    80005e98:	fc843503          	ld	a0,-56(s0)
    80005e9c:	fffff097          	auipc	ra,0xfffff
    80005ea0:	a16080e7          	jalr	-1514(ra) # 800048b2 <fileclose>
    return -1;
    80005ea4:	57fd                	li	a5,-1
    80005ea6:	a03d                	j	80005ed4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ea8:	fc442783          	lw	a5,-60(s0)
    80005eac:	0007c763          	bltz	a5,80005eba <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005eb0:	07e9                	addi	a5,a5,26
    80005eb2:	078e                	slli	a5,a5,0x3
    80005eb4:	97a6                	add	a5,a5,s1
    80005eb6:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005eba:	fd043503          	ld	a0,-48(s0)
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	9f4080e7          	jalr	-1548(ra) # 800048b2 <fileclose>
    fileclose(wf);
    80005ec6:	fc843503          	ld	a0,-56(s0)
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	9e8080e7          	jalr	-1560(ra) # 800048b2 <fileclose>
    return -1;
    80005ed2:	57fd                	li	a5,-1
}
    80005ed4:	853e                	mv	a0,a5
    80005ed6:	70e2                	ld	ra,56(sp)
    80005ed8:	7442                	ld	s0,48(sp)
    80005eda:	74a2                	ld	s1,40(sp)
    80005edc:	6121                	addi	sp,sp,64
    80005ede:	8082                	ret

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
    80005f20:	cb3fc0ef          	jal	ra,80002bd2 <kerneltrap>
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
    8000608c:	0ec080e7          	jalr	236(ra) # 80002174 <wakeup>
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
    80006356:	dbe080e7          	jalr	-578(ra) # 80002110 <sleep>
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
    8000645a:	cba080e7          	jalr	-838(ra) # 80002110 <sleep>
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
    80006540:	c38080e7          	jalr	-968(ra) # 80002174 <wakeup>

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
