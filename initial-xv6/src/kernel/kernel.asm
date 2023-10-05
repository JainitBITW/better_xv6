
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
    80000066:	f1e78793          	addi	a5,a5,-226 # 80005f80 <timervec>
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
    80000ec4:	100080e7          	jalr	256(ra) # 80005fc0 <plicinithart>
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
    80000f44:	06a080e7          	jalr	106(ra) # 80005faa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	078080e7          	jalr	120(ra) # 80005fc0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	264080e7          	jalr	612(ra) # 800031b4 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	902080e7          	jalr	-1790(ra) # 8000385a <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	878080e7          	jalr	-1928(ra) # 800047d8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	160080e7          	jalr	352(ra) # 800060c8 <virtio_disk_init>
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
    80001a1e:	dc0080e7          	jalr	-576(ra) # 800037da <fsinit>
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
    80001da2:	45a080e7          	jalr	1114(ra) # 800041f8 <namei>
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
    80001ed2:	99c080e7          	jalr	-1636(ra) # 8000486a <filedup>
    80001ed6:	00a93023          	sd	a0,0(s2)
    80001eda:	b7e5                	j	80001ec2 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001edc:	150ab503          	ld	a0,336(s5)
    80001ee0:	00002097          	auipc	ra,0x2
    80001ee4:	b34080e7          	jalr	-1228(ra) # 80003a14 <idup>
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
    80002288:	638080e7          	jalr	1592(ra) # 800048bc <fileclose>
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
    800022a0:	15c080e7          	jalr	348(ra) # 800043f8 <begin_op>
  iput(p->cwd);
    800022a4:	1509b503          	ld	a0,336(s3)
    800022a8:	00002097          	auipc	ra,0x2
    800022ac:	964080e7          	jalr	-1692(ra) # 80003c0c <iput>
  end_op();
    800022b0:	00002097          	auipc	ra,0x2
    800022b4:	1c2080e7          	jalr	450(ra) # 80004472 <end_op>
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
    800028c6:	62e78793          	addi	a5,a5,1582 # 80005ef0 <kernelvec>
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
    800029f6:	606080e7          	jalr	1542(ra) # 80005ff8 <plic_claim>
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
    80002a24:	5fc080e7          	jalr	1532(ra) # 8000601c <plic_complete>
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
    80002a3a:	aac080e7          	jalr	-1364(ra) # 800064e2 <virtio_disk_intr>
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
    80002a7e:	47678793          	addi	a5,a5,1142 # 80005ef0 <kernelvec>
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
  return myproc()->trapframe->a0;
    800031a0:	fffff097          	auipc	ra,0xfffff
    800031a4:	806080e7          	jalr	-2042(ra) # 800019a6 <myproc>
    800031a8:	6d3c                	ld	a5,88(a0)
    800031aa:	7ba8                	ld	a0,112(a5)
    800031ac:	60a2                	ld	ra,8(sp)
    800031ae:	6402                	ld	s0,0(sp)
    800031b0:	0141                	addi	sp,sp,16
    800031b2:	8082                	ret

00000000800031b4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031b4:	7179                	addi	sp,sp,-48
    800031b6:	f406                	sd	ra,40(sp)
    800031b8:	f022                	sd	s0,32(sp)
    800031ba:	ec26                	sd	s1,24(sp)
    800031bc:	e84a                	sd	s2,16(sp)
    800031be:	e44e                	sd	s3,8(sp)
    800031c0:	e052                	sd	s4,0(sp)
    800031c2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031c4:	00005597          	auipc	a1,0x5
    800031c8:	35c58593          	addi	a1,a1,860 # 80008520 <syscalls+0xd0>
    800031cc:	00014517          	auipc	a0,0x14
    800031d0:	1ec50513          	addi	a0,a0,492 # 800173b8 <bcache>
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	96e080e7          	jalr	-1682(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031dc:	0001c797          	auipc	a5,0x1c
    800031e0:	1dc78793          	addi	a5,a5,476 # 8001f3b8 <bcache+0x8000>
    800031e4:	0001c717          	auipc	a4,0x1c
    800031e8:	43c70713          	addi	a4,a4,1084 # 8001f620 <bcache+0x8268>
    800031ec:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031f0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031f4:	00014497          	auipc	s1,0x14
    800031f8:	1dc48493          	addi	s1,s1,476 # 800173d0 <bcache+0x18>
    b->next = bcache.head.next;
    800031fc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031fe:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003200:	00005a17          	auipc	s4,0x5
    80003204:	328a0a13          	addi	s4,s4,808 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003208:	2b893783          	ld	a5,696(s2)
    8000320c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000320e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003212:	85d2                	mv	a1,s4
    80003214:	01048513          	addi	a0,s1,16
    80003218:	00001097          	auipc	ra,0x1
    8000321c:	496080e7          	jalr	1174(ra) # 800046ae <initsleeplock>
    bcache.head.next->prev = b;
    80003220:	2b893783          	ld	a5,696(s2)
    80003224:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003226:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000322a:	45848493          	addi	s1,s1,1112
    8000322e:	fd349de3          	bne	s1,s3,80003208 <binit+0x54>
  }
}
    80003232:	70a2                	ld	ra,40(sp)
    80003234:	7402                	ld	s0,32(sp)
    80003236:	64e2                	ld	s1,24(sp)
    80003238:	6942                	ld	s2,16(sp)
    8000323a:	69a2                	ld	s3,8(sp)
    8000323c:	6a02                	ld	s4,0(sp)
    8000323e:	6145                	addi	sp,sp,48
    80003240:	8082                	ret

0000000080003242 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003242:	7179                	addi	sp,sp,-48
    80003244:	f406                	sd	ra,40(sp)
    80003246:	f022                	sd	s0,32(sp)
    80003248:	ec26                	sd	s1,24(sp)
    8000324a:	e84a                	sd	s2,16(sp)
    8000324c:	e44e                	sd	s3,8(sp)
    8000324e:	1800                	addi	s0,sp,48
    80003250:	892a                	mv	s2,a0
    80003252:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003254:	00014517          	auipc	a0,0x14
    80003258:	16450513          	addi	a0,a0,356 # 800173b8 <bcache>
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	976080e7          	jalr	-1674(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003264:	0001c497          	auipc	s1,0x1c
    80003268:	40c4b483          	ld	s1,1036(s1) # 8001f670 <bcache+0x82b8>
    8000326c:	0001c797          	auipc	a5,0x1c
    80003270:	3b478793          	addi	a5,a5,948 # 8001f620 <bcache+0x8268>
    80003274:	02f48f63          	beq	s1,a5,800032b2 <bread+0x70>
    80003278:	873e                	mv	a4,a5
    8000327a:	a021                	j	80003282 <bread+0x40>
    8000327c:	68a4                	ld	s1,80(s1)
    8000327e:	02e48a63          	beq	s1,a4,800032b2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003282:	449c                	lw	a5,8(s1)
    80003284:	ff279ce3          	bne	a5,s2,8000327c <bread+0x3a>
    80003288:	44dc                	lw	a5,12(s1)
    8000328a:	ff3799e3          	bne	a5,s3,8000327c <bread+0x3a>
      b->refcnt++;
    8000328e:	40bc                	lw	a5,64(s1)
    80003290:	2785                	addiw	a5,a5,1
    80003292:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003294:	00014517          	auipc	a0,0x14
    80003298:	12450513          	addi	a0,a0,292 # 800173b8 <bcache>
    8000329c:	ffffe097          	auipc	ra,0xffffe
    800032a0:	9ea080e7          	jalr	-1558(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800032a4:	01048513          	addi	a0,s1,16
    800032a8:	00001097          	auipc	ra,0x1
    800032ac:	440080e7          	jalr	1088(ra) # 800046e8 <acquiresleep>
      return b;
    800032b0:	a8b9                	j	8000330e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032b2:	0001c497          	auipc	s1,0x1c
    800032b6:	3b64b483          	ld	s1,950(s1) # 8001f668 <bcache+0x82b0>
    800032ba:	0001c797          	auipc	a5,0x1c
    800032be:	36678793          	addi	a5,a5,870 # 8001f620 <bcache+0x8268>
    800032c2:	00f48863          	beq	s1,a5,800032d2 <bread+0x90>
    800032c6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032c8:	40bc                	lw	a5,64(s1)
    800032ca:	cf81                	beqz	a5,800032e2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032cc:	64a4                	ld	s1,72(s1)
    800032ce:	fee49de3          	bne	s1,a4,800032c8 <bread+0x86>
  panic("bget: no buffers");
    800032d2:	00005517          	auipc	a0,0x5
    800032d6:	25e50513          	addi	a0,a0,606 # 80008530 <syscalls+0xe0>
    800032da:	ffffd097          	auipc	ra,0xffffd
    800032de:	262080e7          	jalr	610(ra) # 8000053c <panic>
      b->dev = dev;
    800032e2:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032e6:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032ea:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032ee:	4785                	li	a5,1
    800032f0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032f2:	00014517          	auipc	a0,0x14
    800032f6:	0c650513          	addi	a0,a0,198 # 800173b8 <bcache>
    800032fa:	ffffe097          	auipc	ra,0xffffe
    800032fe:	98c080e7          	jalr	-1652(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003302:	01048513          	addi	a0,s1,16
    80003306:	00001097          	auipc	ra,0x1
    8000330a:	3e2080e7          	jalr	994(ra) # 800046e8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000330e:	409c                	lw	a5,0(s1)
    80003310:	cb89                	beqz	a5,80003322 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003312:	8526                	mv	a0,s1
    80003314:	70a2                	ld	ra,40(sp)
    80003316:	7402                	ld	s0,32(sp)
    80003318:	64e2                	ld	s1,24(sp)
    8000331a:	6942                	ld	s2,16(sp)
    8000331c:	69a2                	ld	s3,8(sp)
    8000331e:	6145                	addi	sp,sp,48
    80003320:	8082                	ret
    virtio_disk_rw(b, 0);
    80003322:	4581                	li	a1,0
    80003324:	8526                	mv	a0,s1
    80003326:	00003097          	auipc	ra,0x3
    8000332a:	f8c080e7          	jalr	-116(ra) # 800062b2 <virtio_disk_rw>
    b->valid = 1;
    8000332e:	4785                	li	a5,1
    80003330:	c09c                	sw	a5,0(s1)
  return b;
    80003332:	b7c5                	j	80003312 <bread+0xd0>

0000000080003334 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003334:	1101                	addi	sp,sp,-32
    80003336:	ec06                	sd	ra,24(sp)
    80003338:	e822                	sd	s0,16(sp)
    8000333a:	e426                	sd	s1,8(sp)
    8000333c:	1000                	addi	s0,sp,32
    8000333e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003340:	0541                	addi	a0,a0,16
    80003342:	00001097          	auipc	ra,0x1
    80003346:	440080e7          	jalr	1088(ra) # 80004782 <holdingsleep>
    8000334a:	cd01                	beqz	a0,80003362 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000334c:	4585                	li	a1,1
    8000334e:	8526                	mv	a0,s1
    80003350:	00003097          	auipc	ra,0x3
    80003354:	f62080e7          	jalr	-158(ra) # 800062b2 <virtio_disk_rw>
}
    80003358:	60e2                	ld	ra,24(sp)
    8000335a:	6442                	ld	s0,16(sp)
    8000335c:	64a2                	ld	s1,8(sp)
    8000335e:	6105                	addi	sp,sp,32
    80003360:	8082                	ret
    panic("bwrite");
    80003362:	00005517          	auipc	a0,0x5
    80003366:	1e650513          	addi	a0,a0,486 # 80008548 <syscalls+0xf8>
    8000336a:	ffffd097          	auipc	ra,0xffffd
    8000336e:	1d2080e7          	jalr	466(ra) # 8000053c <panic>

0000000080003372 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003372:	1101                	addi	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	e426                	sd	s1,8(sp)
    8000337a:	e04a                	sd	s2,0(sp)
    8000337c:	1000                	addi	s0,sp,32
    8000337e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003380:	01050913          	addi	s2,a0,16
    80003384:	854a                	mv	a0,s2
    80003386:	00001097          	auipc	ra,0x1
    8000338a:	3fc080e7          	jalr	1020(ra) # 80004782 <holdingsleep>
    8000338e:	c925                	beqz	a0,800033fe <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003390:	854a                	mv	a0,s2
    80003392:	00001097          	auipc	ra,0x1
    80003396:	3ac080e7          	jalr	940(ra) # 8000473e <releasesleep>

  acquire(&bcache.lock);
    8000339a:	00014517          	auipc	a0,0x14
    8000339e:	01e50513          	addi	a0,a0,30 # 800173b8 <bcache>
    800033a2:	ffffe097          	auipc	ra,0xffffe
    800033a6:	830080e7          	jalr	-2000(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800033aa:	40bc                	lw	a5,64(s1)
    800033ac:	37fd                	addiw	a5,a5,-1
    800033ae:	0007871b          	sext.w	a4,a5
    800033b2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033b4:	e71d                	bnez	a4,800033e2 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033b6:	68b8                	ld	a4,80(s1)
    800033b8:	64bc                	ld	a5,72(s1)
    800033ba:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800033bc:	68b8                	ld	a4,80(s1)
    800033be:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033c0:	0001c797          	auipc	a5,0x1c
    800033c4:	ff878793          	addi	a5,a5,-8 # 8001f3b8 <bcache+0x8000>
    800033c8:	2b87b703          	ld	a4,696(a5)
    800033cc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033ce:	0001c717          	auipc	a4,0x1c
    800033d2:	25270713          	addi	a4,a4,594 # 8001f620 <bcache+0x8268>
    800033d6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033d8:	2b87b703          	ld	a4,696(a5)
    800033dc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033de:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033e2:	00014517          	auipc	a0,0x14
    800033e6:	fd650513          	addi	a0,a0,-42 # 800173b8 <bcache>
    800033ea:	ffffe097          	auipc	ra,0xffffe
    800033ee:	89c080e7          	jalr	-1892(ra) # 80000c86 <release>
}
    800033f2:	60e2                	ld	ra,24(sp)
    800033f4:	6442                	ld	s0,16(sp)
    800033f6:	64a2                	ld	s1,8(sp)
    800033f8:	6902                	ld	s2,0(sp)
    800033fa:	6105                	addi	sp,sp,32
    800033fc:	8082                	ret
    panic("brelse");
    800033fe:	00005517          	auipc	a0,0x5
    80003402:	15250513          	addi	a0,a0,338 # 80008550 <syscalls+0x100>
    80003406:	ffffd097          	auipc	ra,0xffffd
    8000340a:	136080e7          	jalr	310(ra) # 8000053c <panic>

000000008000340e <bpin>:

void
bpin(struct buf *b) {
    8000340e:	1101                	addi	sp,sp,-32
    80003410:	ec06                	sd	ra,24(sp)
    80003412:	e822                	sd	s0,16(sp)
    80003414:	e426                	sd	s1,8(sp)
    80003416:	1000                	addi	s0,sp,32
    80003418:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000341a:	00014517          	auipc	a0,0x14
    8000341e:	f9e50513          	addi	a0,a0,-98 # 800173b8 <bcache>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	7b0080e7          	jalr	1968(ra) # 80000bd2 <acquire>
  b->refcnt++;
    8000342a:	40bc                	lw	a5,64(s1)
    8000342c:	2785                	addiw	a5,a5,1
    8000342e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003430:	00014517          	auipc	a0,0x14
    80003434:	f8850513          	addi	a0,a0,-120 # 800173b8 <bcache>
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	84e080e7          	jalr	-1970(ra) # 80000c86 <release>
}
    80003440:	60e2                	ld	ra,24(sp)
    80003442:	6442                	ld	s0,16(sp)
    80003444:	64a2                	ld	s1,8(sp)
    80003446:	6105                	addi	sp,sp,32
    80003448:	8082                	ret

000000008000344a <bunpin>:

void
bunpin(struct buf *b) {
    8000344a:	1101                	addi	sp,sp,-32
    8000344c:	ec06                	sd	ra,24(sp)
    8000344e:	e822                	sd	s0,16(sp)
    80003450:	e426                	sd	s1,8(sp)
    80003452:	1000                	addi	s0,sp,32
    80003454:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003456:	00014517          	auipc	a0,0x14
    8000345a:	f6250513          	addi	a0,a0,-158 # 800173b8 <bcache>
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	774080e7          	jalr	1908(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003466:	40bc                	lw	a5,64(s1)
    80003468:	37fd                	addiw	a5,a5,-1
    8000346a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000346c:	00014517          	auipc	a0,0x14
    80003470:	f4c50513          	addi	a0,a0,-180 # 800173b8 <bcache>
    80003474:	ffffe097          	auipc	ra,0xffffe
    80003478:	812080e7          	jalr	-2030(ra) # 80000c86 <release>
}
    8000347c:	60e2                	ld	ra,24(sp)
    8000347e:	6442                	ld	s0,16(sp)
    80003480:	64a2                	ld	s1,8(sp)
    80003482:	6105                	addi	sp,sp,32
    80003484:	8082                	ret

0000000080003486 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003486:	1101                	addi	sp,sp,-32
    80003488:	ec06                	sd	ra,24(sp)
    8000348a:	e822                	sd	s0,16(sp)
    8000348c:	e426                	sd	s1,8(sp)
    8000348e:	e04a                	sd	s2,0(sp)
    80003490:	1000                	addi	s0,sp,32
    80003492:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003494:	00d5d59b          	srliw	a1,a1,0xd
    80003498:	0001c797          	auipc	a5,0x1c
    8000349c:	5fc7a783          	lw	a5,1532(a5) # 8001fa94 <sb+0x1c>
    800034a0:	9dbd                	addw	a1,a1,a5
    800034a2:	00000097          	auipc	ra,0x0
    800034a6:	da0080e7          	jalr	-608(ra) # 80003242 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034aa:	0074f713          	andi	a4,s1,7
    800034ae:	4785                	li	a5,1
    800034b0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034b4:	14ce                	slli	s1,s1,0x33
    800034b6:	90d9                	srli	s1,s1,0x36
    800034b8:	00950733          	add	a4,a0,s1
    800034bc:	05874703          	lbu	a4,88(a4)
    800034c0:	00e7f6b3          	and	a3,a5,a4
    800034c4:	c69d                	beqz	a3,800034f2 <bfree+0x6c>
    800034c6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034c8:	94aa                	add	s1,s1,a0
    800034ca:	fff7c793          	not	a5,a5
    800034ce:	8f7d                	and	a4,a4,a5
    800034d0:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800034d4:	00001097          	auipc	ra,0x1
    800034d8:	0f6080e7          	jalr	246(ra) # 800045ca <log_write>
  brelse(bp);
    800034dc:	854a                	mv	a0,s2
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	e94080e7          	jalr	-364(ra) # 80003372 <brelse>
}
    800034e6:	60e2                	ld	ra,24(sp)
    800034e8:	6442                	ld	s0,16(sp)
    800034ea:	64a2                	ld	s1,8(sp)
    800034ec:	6902                	ld	s2,0(sp)
    800034ee:	6105                	addi	sp,sp,32
    800034f0:	8082                	ret
    panic("freeing free block");
    800034f2:	00005517          	auipc	a0,0x5
    800034f6:	06650513          	addi	a0,a0,102 # 80008558 <syscalls+0x108>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	042080e7          	jalr	66(ra) # 8000053c <panic>

0000000080003502 <balloc>:
{
    80003502:	711d                	addi	sp,sp,-96
    80003504:	ec86                	sd	ra,88(sp)
    80003506:	e8a2                	sd	s0,80(sp)
    80003508:	e4a6                	sd	s1,72(sp)
    8000350a:	e0ca                	sd	s2,64(sp)
    8000350c:	fc4e                	sd	s3,56(sp)
    8000350e:	f852                	sd	s4,48(sp)
    80003510:	f456                	sd	s5,40(sp)
    80003512:	f05a                	sd	s6,32(sp)
    80003514:	ec5e                	sd	s7,24(sp)
    80003516:	e862                	sd	s8,16(sp)
    80003518:	e466                	sd	s9,8(sp)
    8000351a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000351c:	0001c797          	auipc	a5,0x1c
    80003520:	5607a783          	lw	a5,1376(a5) # 8001fa7c <sb+0x4>
    80003524:	cff5                	beqz	a5,80003620 <balloc+0x11e>
    80003526:	8baa                	mv	s7,a0
    80003528:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000352a:	0001cb17          	auipc	s6,0x1c
    8000352e:	54eb0b13          	addi	s6,s6,1358 # 8001fa78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003532:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003534:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003536:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003538:	6c89                	lui	s9,0x2
    8000353a:	a061                	j	800035c2 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000353c:	97ca                	add	a5,a5,s2
    8000353e:	8e55                	or	a2,a2,a3
    80003540:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003544:	854a                	mv	a0,s2
    80003546:	00001097          	auipc	ra,0x1
    8000354a:	084080e7          	jalr	132(ra) # 800045ca <log_write>
        brelse(bp);
    8000354e:	854a                	mv	a0,s2
    80003550:	00000097          	auipc	ra,0x0
    80003554:	e22080e7          	jalr	-478(ra) # 80003372 <brelse>
  bp = bread(dev, bno);
    80003558:	85a6                	mv	a1,s1
    8000355a:	855e                	mv	a0,s7
    8000355c:	00000097          	auipc	ra,0x0
    80003560:	ce6080e7          	jalr	-794(ra) # 80003242 <bread>
    80003564:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003566:	40000613          	li	a2,1024
    8000356a:	4581                	li	a1,0
    8000356c:	05850513          	addi	a0,a0,88
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	75e080e7          	jalr	1886(ra) # 80000cce <memset>
  log_write(bp);
    80003578:	854a                	mv	a0,s2
    8000357a:	00001097          	auipc	ra,0x1
    8000357e:	050080e7          	jalr	80(ra) # 800045ca <log_write>
  brelse(bp);
    80003582:	854a                	mv	a0,s2
    80003584:	00000097          	auipc	ra,0x0
    80003588:	dee080e7          	jalr	-530(ra) # 80003372 <brelse>
}
    8000358c:	8526                	mv	a0,s1
    8000358e:	60e6                	ld	ra,88(sp)
    80003590:	6446                	ld	s0,80(sp)
    80003592:	64a6                	ld	s1,72(sp)
    80003594:	6906                	ld	s2,64(sp)
    80003596:	79e2                	ld	s3,56(sp)
    80003598:	7a42                	ld	s4,48(sp)
    8000359a:	7aa2                	ld	s5,40(sp)
    8000359c:	7b02                	ld	s6,32(sp)
    8000359e:	6be2                	ld	s7,24(sp)
    800035a0:	6c42                	ld	s8,16(sp)
    800035a2:	6ca2                	ld	s9,8(sp)
    800035a4:	6125                	addi	sp,sp,96
    800035a6:	8082                	ret
    brelse(bp);
    800035a8:	854a                	mv	a0,s2
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	dc8080e7          	jalr	-568(ra) # 80003372 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035b2:	015c87bb          	addw	a5,s9,s5
    800035b6:	00078a9b          	sext.w	s5,a5
    800035ba:	004b2703          	lw	a4,4(s6)
    800035be:	06eaf163          	bgeu	s5,a4,80003620 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800035c2:	41fad79b          	sraiw	a5,s5,0x1f
    800035c6:	0137d79b          	srliw	a5,a5,0x13
    800035ca:	015787bb          	addw	a5,a5,s5
    800035ce:	40d7d79b          	sraiw	a5,a5,0xd
    800035d2:	01cb2583          	lw	a1,28(s6)
    800035d6:	9dbd                	addw	a1,a1,a5
    800035d8:	855e                	mv	a0,s7
    800035da:	00000097          	auipc	ra,0x0
    800035de:	c68080e7          	jalr	-920(ra) # 80003242 <bread>
    800035e2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035e4:	004b2503          	lw	a0,4(s6)
    800035e8:	000a849b          	sext.w	s1,s5
    800035ec:	8762                	mv	a4,s8
    800035ee:	faa4fde3          	bgeu	s1,a0,800035a8 <balloc+0xa6>
      m = 1 << (bi % 8);
    800035f2:	00777693          	andi	a3,a4,7
    800035f6:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035fa:	41f7579b          	sraiw	a5,a4,0x1f
    800035fe:	01d7d79b          	srliw	a5,a5,0x1d
    80003602:	9fb9                	addw	a5,a5,a4
    80003604:	4037d79b          	sraiw	a5,a5,0x3
    80003608:	00f90633          	add	a2,s2,a5
    8000360c:	05864603          	lbu	a2,88(a2)
    80003610:	00c6f5b3          	and	a1,a3,a2
    80003614:	d585                	beqz	a1,8000353c <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003616:	2705                	addiw	a4,a4,1
    80003618:	2485                	addiw	s1,s1,1
    8000361a:	fd471ae3          	bne	a4,s4,800035ee <balloc+0xec>
    8000361e:	b769                	j	800035a8 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003620:	00005517          	auipc	a0,0x5
    80003624:	f5050513          	addi	a0,a0,-176 # 80008570 <syscalls+0x120>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	f5e080e7          	jalr	-162(ra) # 80000586 <printf>
  return 0;
    80003630:	4481                	li	s1,0
    80003632:	bfa9                	j	8000358c <balloc+0x8a>

0000000080003634 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003634:	7179                	addi	sp,sp,-48
    80003636:	f406                	sd	ra,40(sp)
    80003638:	f022                	sd	s0,32(sp)
    8000363a:	ec26                	sd	s1,24(sp)
    8000363c:	e84a                	sd	s2,16(sp)
    8000363e:	e44e                	sd	s3,8(sp)
    80003640:	e052                	sd	s4,0(sp)
    80003642:	1800                	addi	s0,sp,48
    80003644:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003646:	47ad                	li	a5,11
    80003648:	02b7e863          	bltu	a5,a1,80003678 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000364c:	02059793          	slli	a5,a1,0x20
    80003650:	01e7d593          	srli	a1,a5,0x1e
    80003654:	00b504b3          	add	s1,a0,a1
    80003658:	0504a903          	lw	s2,80(s1)
    8000365c:	06091e63          	bnez	s2,800036d8 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003660:	4108                	lw	a0,0(a0)
    80003662:	00000097          	auipc	ra,0x0
    80003666:	ea0080e7          	jalr	-352(ra) # 80003502 <balloc>
    8000366a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000366e:	06090563          	beqz	s2,800036d8 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003672:	0524a823          	sw	s2,80(s1)
    80003676:	a08d                	j	800036d8 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003678:	ff45849b          	addiw	s1,a1,-12
    8000367c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003680:	0ff00793          	li	a5,255
    80003684:	08e7e563          	bltu	a5,a4,8000370e <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003688:	08052903          	lw	s2,128(a0)
    8000368c:	00091d63          	bnez	s2,800036a6 <bmap+0x72>
      addr = balloc(ip->dev);
    80003690:	4108                	lw	a0,0(a0)
    80003692:	00000097          	auipc	ra,0x0
    80003696:	e70080e7          	jalr	-400(ra) # 80003502 <balloc>
    8000369a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000369e:	02090d63          	beqz	s2,800036d8 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800036a2:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800036a6:	85ca                	mv	a1,s2
    800036a8:	0009a503          	lw	a0,0(s3)
    800036ac:	00000097          	auipc	ra,0x0
    800036b0:	b96080e7          	jalr	-1130(ra) # 80003242 <bread>
    800036b4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036b6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036ba:	02049713          	slli	a4,s1,0x20
    800036be:	01e75593          	srli	a1,a4,0x1e
    800036c2:	00b784b3          	add	s1,a5,a1
    800036c6:	0004a903          	lw	s2,0(s1)
    800036ca:	02090063          	beqz	s2,800036ea <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036ce:	8552                	mv	a0,s4
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	ca2080e7          	jalr	-862(ra) # 80003372 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036d8:	854a                	mv	a0,s2
    800036da:	70a2                	ld	ra,40(sp)
    800036dc:	7402                	ld	s0,32(sp)
    800036de:	64e2                	ld	s1,24(sp)
    800036e0:	6942                	ld	s2,16(sp)
    800036e2:	69a2                	ld	s3,8(sp)
    800036e4:	6a02                	ld	s4,0(sp)
    800036e6:	6145                	addi	sp,sp,48
    800036e8:	8082                	ret
      addr = balloc(ip->dev);
    800036ea:	0009a503          	lw	a0,0(s3)
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	e14080e7          	jalr	-492(ra) # 80003502 <balloc>
    800036f6:	0005091b          	sext.w	s2,a0
      if(addr){
    800036fa:	fc090ae3          	beqz	s2,800036ce <bmap+0x9a>
        a[bn] = addr;
    800036fe:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003702:	8552                	mv	a0,s4
    80003704:	00001097          	auipc	ra,0x1
    80003708:	ec6080e7          	jalr	-314(ra) # 800045ca <log_write>
    8000370c:	b7c9                	j	800036ce <bmap+0x9a>
  panic("bmap: out of range");
    8000370e:	00005517          	auipc	a0,0x5
    80003712:	e7a50513          	addi	a0,a0,-390 # 80008588 <syscalls+0x138>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	e26080e7          	jalr	-474(ra) # 8000053c <panic>

000000008000371e <iget>:
{
    8000371e:	7179                	addi	sp,sp,-48
    80003720:	f406                	sd	ra,40(sp)
    80003722:	f022                	sd	s0,32(sp)
    80003724:	ec26                	sd	s1,24(sp)
    80003726:	e84a                	sd	s2,16(sp)
    80003728:	e44e                	sd	s3,8(sp)
    8000372a:	e052                	sd	s4,0(sp)
    8000372c:	1800                	addi	s0,sp,48
    8000372e:	89aa                	mv	s3,a0
    80003730:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003732:	0001c517          	auipc	a0,0x1c
    80003736:	36650513          	addi	a0,a0,870 # 8001fa98 <itable>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	498080e7          	jalr	1176(ra) # 80000bd2 <acquire>
  empty = 0;
    80003742:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003744:	0001c497          	auipc	s1,0x1c
    80003748:	36c48493          	addi	s1,s1,876 # 8001fab0 <itable+0x18>
    8000374c:	0001e697          	auipc	a3,0x1e
    80003750:	df468693          	addi	a3,a3,-524 # 80021540 <log>
    80003754:	a039                	j	80003762 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003756:	02090b63          	beqz	s2,8000378c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000375a:	08848493          	addi	s1,s1,136
    8000375e:	02d48a63          	beq	s1,a3,80003792 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003762:	449c                	lw	a5,8(s1)
    80003764:	fef059e3          	blez	a5,80003756 <iget+0x38>
    80003768:	4098                	lw	a4,0(s1)
    8000376a:	ff3716e3          	bne	a4,s3,80003756 <iget+0x38>
    8000376e:	40d8                	lw	a4,4(s1)
    80003770:	ff4713e3          	bne	a4,s4,80003756 <iget+0x38>
      ip->ref++;
    80003774:	2785                	addiw	a5,a5,1
    80003776:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003778:	0001c517          	auipc	a0,0x1c
    8000377c:	32050513          	addi	a0,a0,800 # 8001fa98 <itable>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	506080e7          	jalr	1286(ra) # 80000c86 <release>
      return ip;
    80003788:	8926                	mv	s2,s1
    8000378a:	a03d                	j	800037b8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000378c:	f7f9                	bnez	a5,8000375a <iget+0x3c>
    8000378e:	8926                	mv	s2,s1
    80003790:	b7e9                	j	8000375a <iget+0x3c>
  if(empty == 0)
    80003792:	02090c63          	beqz	s2,800037ca <iget+0xac>
  ip->dev = dev;
    80003796:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000379a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000379e:	4785                	li	a5,1
    800037a0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037a4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037a8:	0001c517          	auipc	a0,0x1c
    800037ac:	2f050513          	addi	a0,a0,752 # 8001fa98 <itable>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	4d6080e7          	jalr	1238(ra) # 80000c86 <release>
}
    800037b8:	854a                	mv	a0,s2
    800037ba:	70a2                	ld	ra,40(sp)
    800037bc:	7402                	ld	s0,32(sp)
    800037be:	64e2                	ld	s1,24(sp)
    800037c0:	6942                	ld	s2,16(sp)
    800037c2:	69a2                	ld	s3,8(sp)
    800037c4:	6a02                	ld	s4,0(sp)
    800037c6:	6145                	addi	sp,sp,48
    800037c8:	8082                	ret
    panic("iget: no inodes");
    800037ca:	00005517          	auipc	a0,0x5
    800037ce:	dd650513          	addi	a0,a0,-554 # 800085a0 <syscalls+0x150>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	d6a080e7          	jalr	-662(ra) # 8000053c <panic>

00000000800037da <fsinit>:
fsinit(int dev) {
    800037da:	7179                	addi	sp,sp,-48
    800037dc:	f406                	sd	ra,40(sp)
    800037de:	f022                	sd	s0,32(sp)
    800037e0:	ec26                	sd	s1,24(sp)
    800037e2:	e84a                	sd	s2,16(sp)
    800037e4:	e44e                	sd	s3,8(sp)
    800037e6:	1800                	addi	s0,sp,48
    800037e8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037ea:	4585                	li	a1,1
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	a56080e7          	jalr	-1450(ra) # 80003242 <bread>
    800037f4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037f6:	0001c997          	auipc	s3,0x1c
    800037fa:	28298993          	addi	s3,s3,642 # 8001fa78 <sb>
    800037fe:	02000613          	li	a2,32
    80003802:	05850593          	addi	a1,a0,88
    80003806:	854e                	mv	a0,s3
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	522080e7          	jalr	1314(ra) # 80000d2a <memmove>
  brelse(bp);
    80003810:	8526                	mv	a0,s1
    80003812:	00000097          	auipc	ra,0x0
    80003816:	b60080e7          	jalr	-1184(ra) # 80003372 <brelse>
  if(sb.magic != FSMAGIC)
    8000381a:	0009a703          	lw	a4,0(s3)
    8000381e:	102037b7          	lui	a5,0x10203
    80003822:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003826:	02f71263          	bne	a4,a5,8000384a <fsinit+0x70>
  initlog(dev, &sb);
    8000382a:	0001c597          	auipc	a1,0x1c
    8000382e:	24e58593          	addi	a1,a1,590 # 8001fa78 <sb>
    80003832:	854a                	mv	a0,s2
    80003834:	00001097          	auipc	ra,0x1
    80003838:	b2c080e7          	jalr	-1236(ra) # 80004360 <initlog>
}
    8000383c:	70a2                	ld	ra,40(sp)
    8000383e:	7402                	ld	s0,32(sp)
    80003840:	64e2                	ld	s1,24(sp)
    80003842:	6942                	ld	s2,16(sp)
    80003844:	69a2                	ld	s3,8(sp)
    80003846:	6145                	addi	sp,sp,48
    80003848:	8082                	ret
    panic("invalid file system");
    8000384a:	00005517          	auipc	a0,0x5
    8000384e:	d6650513          	addi	a0,a0,-666 # 800085b0 <syscalls+0x160>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	cea080e7          	jalr	-790(ra) # 8000053c <panic>

000000008000385a <iinit>:
{
    8000385a:	7179                	addi	sp,sp,-48
    8000385c:	f406                	sd	ra,40(sp)
    8000385e:	f022                	sd	s0,32(sp)
    80003860:	ec26                	sd	s1,24(sp)
    80003862:	e84a                	sd	s2,16(sp)
    80003864:	e44e                	sd	s3,8(sp)
    80003866:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003868:	00005597          	auipc	a1,0x5
    8000386c:	d6058593          	addi	a1,a1,-672 # 800085c8 <syscalls+0x178>
    80003870:	0001c517          	auipc	a0,0x1c
    80003874:	22850513          	addi	a0,a0,552 # 8001fa98 <itable>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	2ca080e7          	jalr	714(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003880:	0001c497          	auipc	s1,0x1c
    80003884:	24048493          	addi	s1,s1,576 # 8001fac0 <itable+0x28>
    80003888:	0001e997          	auipc	s3,0x1e
    8000388c:	cc898993          	addi	s3,s3,-824 # 80021550 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003890:	00005917          	auipc	s2,0x5
    80003894:	d4090913          	addi	s2,s2,-704 # 800085d0 <syscalls+0x180>
    80003898:	85ca                	mv	a1,s2
    8000389a:	8526                	mv	a0,s1
    8000389c:	00001097          	auipc	ra,0x1
    800038a0:	e12080e7          	jalr	-494(ra) # 800046ae <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038a4:	08848493          	addi	s1,s1,136
    800038a8:	ff3498e3          	bne	s1,s3,80003898 <iinit+0x3e>
}
    800038ac:	70a2                	ld	ra,40(sp)
    800038ae:	7402                	ld	s0,32(sp)
    800038b0:	64e2                	ld	s1,24(sp)
    800038b2:	6942                	ld	s2,16(sp)
    800038b4:	69a2                	ld	s3,8(sp)
    800038b6:	6145                	addi	sp,sp,48
    800038b8:	8082                	ret

00000000800038ba <ialloc>:
{
    800038ba:	7139                	addi	sp,sp,-64
    800038bc:	fc06                	sd	ra,56(sp)
    800038be:	f822                	sd	s0,48(sp)
    800038c0:	f426                	sd	s1,40(sp)
    800038c2:	f04a                	sd	s2,32(sp)
    800038c4:	ec4e                	sd	s3,24(sp)
    800038c6:	e852                	sd	s4,16(sp)
    800038c8:	e456                	sd	s5,8(sp)
    800038ca:	e05a                	sd	s6,0(sp)
    800038cc:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800038ce:	0001c717          	auipc	a4,0x1c
    800038d2:	1b672703          	lw	a4,438(a4) # 8001fa84 <sb+0xc>
    800038d6:	4785                	li	a5,1
    800038d8:	04e7f863          	bgeu	a5,a4,80003928 <ialloc+0x6e>
    800038dc:	8aaa                	mv	s5,a0
    800038de:	8b2e                	mv	s6,a1
    800038e0:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038e2:	0001ca17          	auipc	s4,0x1c
    800038e6:	196a0a13          	addi	s4,s4,406 # 8001fa78 <sb>
    800038ea:	00495593          	srli	a1,s2,0x4
    800038ee:	018a2783          	lw	a5,24(s4)
    800038f2:	9dbd                	addw	a1,a1,a5
    800038f4:	8556                	mv	a0,s5
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	94c080e7          	jalr	-1716(ra) # 80003242 <bread>
    800038fe:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003900:	05850993          	addi	s3,a0,88
    80003904:	00f97793          	andi	a5,s2,15
    80003908:	079a                	slli	a5,a5,0x6
    8000390a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000390c:	00099783          	lh	a5,0(s3)
    80003910:	cf9d                	beqz	a5,8000394e <ialloc+0x94>
    brelse(bp);
    80003912:	00000097          	auipc	ra,0x0
    80003916:	a60080e7          	jalr	-1440(ra) # 80003372 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000391a:	0905                	addi	s2,s2,1
    8000391c:	00ca2703          	lw	a4,12(s4)
    80003920:	0009079b          	sext.w	a5,s2
    80003924:	fce7e3e3          	bltu	a5,a4,800038ea <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003928:	00005517          	auipc	a0,0x5
    8000392c:	cb050513          	addi	a0,a0,-848 # 800085d8 <syscalls+0x188>
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	c56080e7          	jalr	-938(ra) # 80000586 <printf>
  return 0;
    80003938:	4501                	li	a0,0
}
    8000393a:	70e2                	ld	ra,56(sp)
    8000393c:	7442                	ld	s0,48(sp)
    8000393e:	74a2                	ld	s1,40(sp)
    80003940:	7902                	ld	s2,32(sp)
    80003942:	69e2                	ld	s3,24(sp)
    80003944:	6a42                	ld	s4,16(sp)
    80003946:	6aa2                	ld	s5,8(sp)
    80003948:	6b02                	ld	s6,0(sp)
    8000394a:	6121                	addi	sp,sp,64
    8000394c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000394e:	04000613          	li	a2,64
    80003952:	4581                	li	a1,0
    80003954:	854e                	mv	a0,s3
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	378080e7          	jalr	888(ra) # 80000cce <memset>
      dip->type = type;
    8000395e:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003962:	8526                	mv	a0,s1
    80003964:	00001097          	auipc	ra,0x1
    80003968:	c66080e7          	jalr	-922(ra) # 800045ca <log_write>
      brelse(bp);
    8000396c:	8526                	mv	a0,s1
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	a04080e7          	jalr	-1532(ra) # 80003372 <brelse>
      return iget(dev, inum);
    80003976:	0009059b          	sext.w	a1,s2
    8000397a:	8556                	mv	a0,s5
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	da2080e7          	jalr	-606(ra) # 8000371e <iget>
    80003984:	bf5d                	j	8000393a <ialloc+0x80>

0000000080003986 <iupdate>:
{
    80003986:	1101                	addi	sp,sp,-32
    80003988:	ec06                	sd	ra,24(sp)
    8000398a:	e822                	sd	s0,16(sp)
    8000398c:	e426                	sd	s1,8(sp)
    8000398e:	e04a                	sd	s2,0(sp)
    80003990:	1000                	addi	s0,sp,32
    80003992:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003994:	415c                	lw	a5,4(a0)
    80003996:	0047d79b          	srliw	a5,a5,0x4
    8000399a:	0001c597          	auipc	a1,0x1c
    8000399e:	0f65a583          	lw	a1,246(a1) # 8001fa90 <sb+0x18>
    800039a2:	9dbd                	addw	a1,a1,a5
    800039a4:	4108                	lw	a0,0(a0)
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	89c080e7          	jalr	-1892(ra) # 80003242 <bread>
    800039ae:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039b0:	05850793          	addi	a5,a0,88
    800039b4:	40d8                	lw	a4,4(s1)
    800039b6:	8b3d                	andi	a4,a4,15
    800039b8:	071a                	slli	a4,a4,0x6
    800039ba:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800039bc:	04449703          	lh	a4,68(s1)
    800039c0:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800039c4:	04649703          	lh	a4,70(s1)
    800039c8:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800039cc:	04849703          	lh	a4,72(s1)
    800039d0:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800039d4:	04a49703          	lh	a4,74(s1)
    800039d8:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800039dc:	44f8                	lw	a4,76(s1)
    800039de:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039e0:	03400613          	li	a2,52
    800039e4:	05048593          	addi	a1,s1,80
    800039e8:	00c78513          	addi	a0,a5,12
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	33e080e7          	jalr	830(ra) # 80000d2a <memmove>
  log_write(bp);
    800039f4:	854a                	mv	a0,s2
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	bd4080e7          	jalr	-1068(ra) # 800045ca <log_write>
  brelse(bp);
    800039fe:	854a                	mv	a0,s2
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	972080e7          	jalr	-1678(ra) # 80003372 <brelse>
}
    80003a08:	60e2                	ld	ra,24(sp)
    80003a0a:	6442                	ld	s0,16(sp)
    80003a0c:	64a2                	ld	s1,8(sp)
    80003a0e:	6902                	ld	s2,0(sp)
    80003a10:	6105                	addi	sp,sp,32
    80003a12:	8082                	ret

0000000080003a14 <idup>:
{
    80003a14:	1101                	addi	sp,sp,-32
    80003a16:	ec06                	sd	ra,24(sp)
    80003a18:	e822                	sd	s0,16(sp)
    80003a1a:	e426                	sd	s1,8(sp)
    80003a1c:	1000                	addi	s0,sp,32
    80003a1e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a20:	0001c517          	auipc	a0,0x1c
    80003a24:	07850513          	addi	a0,a0,120 # 8001fa98 <itable>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	1aa080e7          	jalr	426(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003a30:	449c                	lw	a5,8(s1)
    80003a32:	2785                	addiw	a5,a5,1
    80003a34:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a36:	0001c517          	auipc	a0,0x1c
    80003a3a:	06250513          	addi	a0,a0,98 # 8001fa98 <itable>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	248080e7          	jalr	584(ra) # 80000c86 <release>
}
    80003a46:	8526                	mv	a0,s1
    80003a48:	60e2                	ld	ra,24(sp)
    80003a4a:	6442                	ld	s0,16(sp)
    80003a4c:	64a2                	ld	s1,8(sp)
    80003a4e:	6105                	addi	sp,sp,32
    80003a50:	8082                	ret

0000000080003a52 <ilock>:
{
    80003a52:	1101                	addi	sp,sp,-32
    80003a54:	ec06                	sd	ra,24(sp)
    80003a56:	e822                	sd	s0,16(sp)
    80003a58:	e426                	sd	s1,8(sp)
    80003a5a:	e04a                	sd	s2,0(sp)
    80003a5c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a5e:	c115                	beqz	a0,80003a82 <ilock+0x30>
    80003a60:	84aa                	mv	s1,a0
    80003a62:	451c                	lw	a5,8(a0)
    80003a64:	00f05f63          	blez	a5,80003a82 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a68:	0541                	addi	a0,a0,16
    80003a6a:	00001097          	auipc	ra,0x1
    80003a6e:	c7e080e7          	jalr	-898(ra) # 800046e8 <acquiresleep>
  if(ip->valid == 0){
    80003a72:	40bc                	lw	a5,64(s1)
    80003a74:	cf99                	beqz	a5,80003a92 <ilock+0x40>
}
    80003a76:	60e2                	ld	ra,24(sp)
    80003a78:	6442                	ld	s0,16(sp)
    80003a7a:	64a2                	ld	s1,8(sp)
    80003a7c:	6902                	ld	s2,0(sp)
    80003a7e:	6105                	addi	sp,sp,32
    80003a80:	8082                	ret
    panic("ilock");
    80003a82:	00005517          	auipc	a0,0x5
    80003a86:	b6e50513          	addi	a0,a0,-1170 # 800085f0 <syscalls+0x1a0>
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	ab2080e7          	jalr	-1358(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a92:	40dc                	lw	a5,4(s1)
    80003a94:	0047d79b          	srliw	a5,a5,0x4
    80003a98:	0001c597          	auipc	a1,0x1c
    80003a9c:	ff85a583          	lw	a1,-8(a1) # 8001fa90 <sb+0x18>
    80003aa0:	9dbd                	addw	a1,a1,a5
    80003aa2:	4088                	lw	a0,0(s1)
    80003aa4:	fffff097          	auipc	ra,0xfffff
    80003aa8:	79e080e7          	jalr	1950(ra) # 80003242 <bread>
    80003aac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aae:	05850593          	addi	a1,a0,88
    80003ab2:	40dc                	lw	a5,4(s1)
    80003ab4:	8bbd                	andi	a5,a5,15
    80003ab6:	079a                	slli	a5,a5,0x6
    80003ab8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003aba:	00059783          	lh	a5,0(a1)
    80003abe:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ac2:	00259783          	lh	a5,2(a1)
    80003ac6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003aca:	00459783          	lh	a5,4(a1)
    80003ace:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ad2:	00659783          	lh	a5,6(a1)
    80003ad6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ada:	459c                	lw	a5,8(a1)
    80003adc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ade:	03400613          	li	a2,52
    80003ae2:	05b1                	addi	a1,a1,12
    80003ae4:	05048513          	addi	a0,s1,80
    80003ae8:	ffffd097          	auipc	ra,0xffffd
    80003aec:	242080e7          	jalr	578(ra) # 80000d2a <memmove>
    brelse(bp);
    80003af0:	854a                	mv	a0,s2
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	880080e7          	jalr	-1920(ra) # 80003372 <brelse>
    ip->valid = 1;
    80003afa:	4785                	li	a5,1
    80003afc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003afe:	04449783          	lh	a5,68(s1)
    80003b02:	fbb5                	bnez	a5,80003a76 <ilock+0x24>
      panic("ilock: no type");
    80003b04:	00005517          	auipc	a0,0x5
    80003b08:	af450513          	addi	a0,a0,-1292 # 800085f8 <syscalls+0x1a8>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	a30080e7          	jalr	-1488(ra) # 8000053c <panic>

0000000080003b14 <iunlock>:
{
    80003b14:	1101                	addi	sp,sp,-32
    80003b16:	ec06                	sd	ra,24(sp)
    80003b18:	e822                	sd	s0,16(sp)
    80003b1a:	e426                	sd	s1,8(sp)
    80003b1c:	e04a                	sd	s2,0(sp)
    80003b1e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b20:	c905                	beqz	a0,80003b50 <iunlock+0x3c>
    80003b22:	84aa                	mv	s1,a0
    80003b24:	01050913          	addi	s2,a0,16
    80003b28:	854a                	mv	a0,s2
    80003b2a:	00001097          	auipc	ra,0x1
    80003b2e:	c58080e7          	jalr	-936(ra) # 80004782 <holdingsleep>
    80003b32:	cd19                	beqz	a0,80003b50 <iunlock+0x3c>
    80003b34:	449c                	lw	a5,8(s1)
    80003b36:	00f05d63          	blez	a5,80003b50 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b3a:	854a                	mv	a0,s2
    80003b3c:	00001097          	auipc	ra,0x1
    80003b40:	c02080e7          	jalr	-1022(ra) # 8000473e <releasesleep>
}
    80003b44:	60e2                	ld	ra,24(sp)
    80003b46:	6442                	ld	s0,16(sp)
    80003b48:	64a2                	ld	s1,8(sp)
    80003b4a:	6902                	ld	s2,0(sp)
    80003b4c:	6105                	addi	sp,sp,32
    80003b4e:	8082                	ret
    panic("iunlock");
    80003b50:	00005517          	auipc	a0,0x5
    80003b54:	ab850513          	addi	a0,a0,-1352 # 80008608 <syscalls+0x1b8>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	9e4080e7          	jalr	-1564(ra) # 8000053c <panic>

0000000080003b60 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b60:	7179                	addi	sp,sp,-48
    80003b62:	f406                	sd	ra,40(sp)
    80003b64:	f022                	sd	s0,32(sp)
    80003b66:	ec26                	sd	s1,24(sp)
    80003b68:	e84a                	sd	s2,16(sp)
    80003b6a:	e44e                	sd	s3,8(sp)
    80003b6c:	e052                	sd	s4,0(sp)
    80003b6e:	1800                	addi	s0,sp,48
    80003b70:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b72:	05050493          	addi	s1,a0,80
    80003b76:	08050913          	addi	s2,a0,128
    80003b7a:	a021                	j	80003b82 <itrunc+0x22>
    80003b7c:	0491                	addi	s1,s1,4
    80003b7e:	01248d63          	beq	s1,s2,80003b98 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b82:	408c                	lw	a1,0(s1)
    80003b84:	dde5                	beqz	a1,80003b7c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b86:	0009a503          	lw	a0,0(s3)
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	8fc080e7          	jalr	-1796(ra) # 80003486 <bfree>
      ip->addrs[i] = 0;
    80003b92:	0004a023          	sw	zero,0(s1)
    80003b96:	b7dd                	j	80003b7c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b98:	0809a583          	lw	a1,128(s3)
    80003b9c:	e185                	bnez	a1,80003bbc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b9e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ba2:	854e                	mv	a0,s3
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	de2080e7          	jalr	-542(ra) # 80003986 <iupdate>
}
    80003bac:	70a2                	ld	ra,40(sp)
    80003bae:	7402                	ld	s0,32(sp)
    80003bb0:	64e2                	ld	s1,24(sp)
    80003bb2:	6942                	ld	s2,16(sp)
    80003bb4:	69a2                	ld	s3,8(sp)
    80003bb6:	6a02                	ld	s4,0(sp)
    80003bb8:	6145                	addi	sp,sp,48
    80003bba:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bbc:	0009a503          	lw	a0,0(s3)
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	682080e7          	jalr	1666(ra) # 80003242 <bread>
    80003bc8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bca:	05850493          	addi	s1,a0,88
    80003bce:	45850913          	addi	s2,a0,1112
    80003bd2:	a021                	j	80003bda <itrunc+0x7a>
    80003bd4:	0491                	addi	s1,s1,4
    80003bd6:	01248b63          	beq	s1,s2,80003bec <itrunc+0x8c>
      if(a[j])
    80003bda:	408c                	lw	a1,0(s1)
    80003bdc:	dde5                	beqz	a1,80003bd4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bde:	0009a503          	lw	a0,0(s3)
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	8a4080e7          	jalr	-1884(ra) # 80003486 <bfree>
    80003bea:	b7ed                	j	80003bd4 <itrunc+0x74>
    brelse(bp);
    80003bec:	8552                	mv	a0,s4
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	784080e7          	jalr	1924(ra) # 80003372 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bf6:	0809a583          	lw	a1,128(s3)
    80003bfa:	0009a503          	lw	a0,0(s3)
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	888080e7          	jalr	-1912(ra) # 80003486 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c06:	0809a023          	sw	zero,128(s3)
    80003c0a:	bf51                	j	80003b9e <itrunc+0x3e>

0000000080003c0c <iput>:
{
    80003c0c:	1101                	addi	sp,sp,-32
    80003c0e:	ec06                	sd	ra,24(sp)
    80003c10:	e822                	sd	s0,16(sp)
    80003c12:	e426                	sd	s1,8(sp)
    80003c14:	e04a                	sd	s2,0(sp)
    80003c16:	1000                	addi	s0,sp,32
    80003c18:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c1a:	0001c517          	auipc	a0,0x1c
    80003c1e:	e7e50513          	addi	a0,a0,-386 # 8001fa98 <itable>
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	fb0080e7          	jalr	-80(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c2a:	4498                	lw	a4,8(s1)
    80003c2c:	4785                	li	a5,1
    80003c2e:	02f70363          	beq	a4,a5,80003c54 <iput+0x48>
  ip->ref--;
    80003c32:	449c                	lw	a5,8(s1)
    80003c34:	37fd                	addiw	a5,a5,-1
    80003c36:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c38:	0001c517          	auipc	a0,0x1c
    80003c3c:	e6050513          	addi	a0,a0,-416 # 8001fa98 <itable>
    80003c40:	ffffd097          	auipc	ra,0xffffd
    80003c44:	046080e7          	jalr	70(ra) # 80000c86 <release>
}
    80003c48:	60e2                	ld	ra,24(sp)
    80003c4a:	6442                	ld	s0,16(sp)
    80003c4c:	64a2                	ld	s1,8(sp)
    80003c4e:	6902                	ld	s2,0(sp)
    80003c50:	6105                	addi	sp,sp,32
    80003c52:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c54:	40bc                	lw	a5,64(s1)
    80003c56:	dff1                	beqz	a5,80003c32 <iput+0x26>
    80003c58:	04a49783          	lh	a5,74(s1)
    80003c5c:	fbf9                	bnez	a5,80003c32 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c5e:	01048913          	addi	s2,s1,16
    80003c62:	854a                	mv	a0,s2
    80003c64:	00001097          	auipc	ra,0x1
    80003c68:	a84080e7          	jalr	-1404(ra) # 800046e8 <acquiresleep>
    release(&itable.lock);
    80003c6c:	0001c517          	auipc	a0,0x1c
    80003c70:	e2c50513          	addi	a0,a0,-468 # 8001fa98 <itable>
    80003c74:	ffffd097          	auipc	ra,0xffffd
    80003c78:	012080e7          	jalr	18(ra) # 80000c86 <release>
    itrunc(ip);
    80003c7c:	8526                	mv	a0,s1
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	ee2080e7          	jalr	-286(ra) # 80003b60 <itrunc>
    ip->type = 0;
    80003c86:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c8a:	8526                	mv	a0,s1
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	cfa080e7          	jalr	-774(ra) # 80003986 <iupdate>
    ip->valid = 0;
    80003c94:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c98:	854a                	mv	a0,s2
    80003c9a:	00001097          	auipc	ra,0x1
    80003c9e:	aa4080e7          	jalr	-1372(ra) # 8000473e <releasesleep>
    acquire(&itable.lock);
    80003ca2:	0001c517          	auipc	a0,0x1c
    80003ca6:	df650513          	addi	a0,a0,-522 # 8001fa98 <itable>
    80003caa:	ffffd097          	auipc	ra,0xffffd
    80003cae:	f28080e7          	jalr	-216(ra) # 80000bd2 <acquire>
    80003cb2:	b741                	j	80003c32 <iput+0x26>

0000000080003cb4 <iunlockput>:
{
    80003cb4:	1101                	addi	sp,sp,-32
    80003cb6:	ec06                	sd	ra,24(sp)
    80003cb8:	e822                	sd	s0,16(sp)
    80003cba:	e426                	sd	s1,8(sp)
    80003cbc:	1000                	addi	s0,sp,32
    80003cbe:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	e54080e7          	jalr	-428(ra) # 80003b14 <iunlock>
  iput(ip);
    80003cc8:	8526                	mv	a0,s1
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	f42080e7          	jalr	-190(ra) # 80003c0c <iput>
}
    80003cd2:	60e2                	ld	ra,24(sp)
    80003cd4:	6442                	ld	s0,16(sp)
    80003cd6:	64a2                	ld	s1,8(sp)
    80003cd8:	6105                	addi	sp,sp,32
    80003cda:	8082                	ret

0000000080003cdc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cdc:	1141                	addi	sp,sp,-16
    80003cde:	e422                	sd	s0,8(sp)
    80003ce0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ce2:	411c                	lw	a5,0(a0)
    80003ce4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ce6:	415c                	lw	a5,4(a0)
    80003ce8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003cea:	04451783          	lh	a5,68(a0)
    80003cee:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cf2:	04a51783          	lh	a5,74(a0)
    80003cf6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cfa:	04c56783          	lwu	a5,76(a0)
    80003cfe:	e99c                	sd	a5,16(a1)
}
    80003d00:	6422                	ld	s0,8(sp)
    80003d02:	0141                	addi	sp,sp,16
    80003d04:	8082                	ret

0000000080003d06 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d06:	457c                	lw	a5,76(a0)
    80003d08:	0ed7e963          	bltu	a5,a3,80003dfa <readi+0xf4>
{
    80003d0c:	7159                	addi	sp,sp,-112
    80003d0e:	f486                	sd	ra,104(sp)
    80003d10:	f0a2                	sd	s0,96(sp)
    80003d12:	eca6                	sd	s1,88(sp)
    80003d14:	e8ca                	sd	s2,80(sp)
    80003d16:	e4ce                	sd	s3,72(sp)
    80003d18:	e0d2                	sd	s4,64(sp)
    80003d1a:	fc56                	sd	s5,56(sp)
    80003d1c:	f85a                	sd	s6,48(sp)
    80003d1e:	f45e                	sd	s7,40(sp)
    80003d20:	f062                	sd	s8,32(sp)
    80003d22:	ec66                	sd	s9,24(sp)
    80003d24:	e86a                	sd	s10,16(sp)
    80003d26:	e46e                	sd	s11,8(sp)
    80003d28:	1880                	addi	s0,sp,112
    80003d2a:	8b2a                	mv	s6,a0
    80003d2c:	8bae                	mv	s7,a1
    80003d2e:	8a32                	mv	s4,a2
    80003d30:	84b6                	mv	s1,a3
    80003d32:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d34:	9f35                	addw	a4,a4,a3
    return 0;
    80003d36:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d38:	0ad76063          	bltu	a4,a3,80003dd8 <readi+0xd2>
  if(off + n > ip->size)
    80003d3c:	00e7f463          	bgeu	a5,a4,80003d44 <readi+0x3e>
    n = ip->size - off;
    80003d40:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d44:	0a0a8963          	beqz	s5,80003df6 <readi+0xf0>
    80003d48:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d4a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d4e:	5c7d                	li	s8,-1
    80003d50:	a82d                	j	80003d8a <readi+0x84>
    80003d52:	020d1d93          	slli	s11,s10,0x20
    80003d56:	020ddd93          	srli	s11,s11,0x20
    80003d5a:	05890613          	addi	a2,s2,88
    80003d5e:	86ee                	mv	a3,s11
    80003d60:	963a                	add	a2,a2,a4
    80003d62:	85d2                	mv	a1,s4
    80003d64:	855e                	mv	a0,s7
    80003d66:	ffffe097          	auipc	ra,0xffffe
    80003d6a:	7be080e7          	jalr	1982(ra) # 80002524 <either_copyout>
    80003d6e:	05850d63          	beq	a0,s8,80003dc8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d72:	854a                	mv	a0,s2
    80003d74:	fffff097          	auipc	ra,0xfffff
    80003d78:	5fe080e7          	jalr	1534(ra) # 80003372 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d7c:	013d09bb          	addw	s3,s10,s3
    80003d80:	009d04bb          	addw	s1,s10,s1
    80003d84:	9a6e                	add	s4,s4,s11
    80003d86:	0559f763          	bgeu	s3,s5,80003dd4 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d8a:	00a4d59b          	srliw	a1,s1,0xa
    80003d8e:	855a                	mv	a0,s6
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	8a4080e7          	jalr	-1884(ra) # 80003634 <bmap>
    80003d98:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d9c:	cd85                	beqz	a1,80003dd4 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d9e:	000b2503          	lw	a0,0(s6)
    80003da2:	fffff097          	auipc	ra,0xfffff
    80003da6:	4a0080e7          	jalr	1184(ra) # 80003242 <bread>
    80003daa:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dac:	3ff4f713          	andi	a4,s1,1023
    80003db0:	40ec87bb          	subw	a5,s9,a4
    80003db4:	413a86bb          	subw	a3,s5,s3
    80003db8:	8d3e                	mv	s10,a5
    80003dba:	2781                	sext.w	a5,a5
    80003dbc:	0006861b          	sext.w	a2,a3
    80003dc0:	f8f679e3          	bgeu	a2,a5,80003d52 <readi+0x4c>
    80003dc4:	8d36                	mv	s10,a3
    80003dc6:	b771                	j	80003d52 <readi+0x4c>
      brelse(bp);
    80003dc8:	854a                	mv	a0,s2
    80003dca:	fffff097          	auipc	ra,0xfffff
    80003dce:	5a8080e7          	jalr	1448(ra) # 80003372 <brelse>
      tot = -1;
    80003dd2:	59fd                	li	s3,-1
  }
  return tot;
    80003dd4:	0009851b          	sext.w	a0,s3
}
    80003dd8:	70a6                	ld	ra,104(sp)
    80003dda:	7406                	ld	s0,96(sp)
    80003ddc:	64e6                	ld	s1,88(sp)
    80003dde:	6946                	ld	s2,80(sp)
    80003de0:	69a6                	ld	s3,72(sp)
    80003de2:	6a06                	ld	s4,64(sp)
    80003de4:	7ae2                	ld	s5,56(sp)
    80003de6:	7b42                	ld	s6,48(sp)
    80003de8:	7ba2                	ld	s7,40(sp)
    80003dea:	7c02                	ld	s8,32(sp)
    80003dec:	6ce2                	ld	s9,24(sp)
    80003dee:	6d42                	ld	s10,16(sp)
    80003df0:	6da2                	ld	s11,8(sp)
    80003df2:	6165                	addi	sp,sp,112
    80003df4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003df6:	89d6                	mv	s3,s5
    80003df8:	bff1                	j	80003dd4 <readi+0xce>
    return 0;
    80003dfa:	4501                	li	a0,0
}
    80003dfc:	8082                	ret

0000000080003dfe <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dfe:	457c                	lw	a5,76(a0)
    80003e00:	10d7e863          	bltu	a5,a3,80003f10 <writei+0x112>
{
    80003e04:	7159                	addi	sp,sp,-112
    80003e06:	f486                	sd	ra,104(sp)
    80003e08:	f0a2                	sd	s0,96(sp)
    80003e0a:	eca6                	sd	s1,88(sp)
    80003e0c:	e8ca                	sd	s2,80(sp)
    80003e0e:	e4ce                	sd	s3,72(sp)
    80003e10:	e0d2                	sd	s4,64(sp)
    80003e12:	fc56                	sd	s5,56(sp)
    80003e14:	f85a                	sd	s6,48(sp)
    80003e16:	f45e                	sd	s7,40(sp)
    80003e18:	f062                	sd	s8,32(sp)
    80003e1a:	ec66                	sd	s9,24(sp)
    80003e1c:	e86a                	sd	s10,16(sp)
    80003e1e:	e46e                	sd	s11,8(sp)
    80003e20:	1880                	addi	s0,sp,112
    80003e22:	8aaa                	mv	s5,a0
    80003e24:	8bae                	mv	s7,a1
    80003e26:	8a32                	mv	s4,a2
    80003e28:	8936                	mv	s2,a3
    80003e2a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e2c:	00e687bb          	addw	a5,a3,a4
    80003e30:	0ed7e263          	bltu	a5,a3,80003f14 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e34:	00043737          	lui	a4,0x43
    80003e38:	0ef76063          	bltu	a4,a5,80003f18 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e3c:	0c0b0863          	beqz	s6,80003f0c <writei+0x10e>
    80003e40:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e42:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e46:	5c7d                	li	s8,-1
    80003e48:	a091                	j	80003e8c <writei+0x8e>
    80003e4a:	020d1d93          	slli	s11,s10,0x20
    80003e4e:	020ddd93          	srli	s11,s11,0x20
    80003e52:	05848513          	addi	a0,s1,88
    80003e56:	86ee                	mv	a3,s11
    80003e58:	8652                	mv	a2,s4
    80003e5a:	85de                	mv	a1,s7
    80003e5c:	953a                	add	a0,a0,a4
    80003e5e:	ffffe097          	auipc	ra,0xffffe
    80003e62:	71c080e7          	jalr	1820(ra) # 8000257a <either_copyin>
    80003e66:	07850263          	beq	a0,s8,80003eca <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e6a:	8526                	mv	a0,s1
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	75e080e7          	jalr	1886(ra) # 800045ca <log_write>
    brelse(bp);
    80003e74:	8526                	mv	a0,s1
    80003e76:	fffff097          	auipc	ra,0xfffff
    80003e7a:	4fc080e7          	jalr	1276(ra) # 80003372 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e7e:	013d09bb          	addw	s3,s10,s3
    80003e82:	012d093b          	addw	s2,s10,s2
    80003e86:	9a6e                	add	s4,s4,s11
    80003e88:	0569f663          	bgeu	s3,s6,80003ed4 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e8c:	00a9559b          	srliw	a1,s2,0xa
    80003e90:	8556                	mv	a0,s5
    80003e92:	fffff097          	auipc	ra,0xfffff
    80003e96:	7a2080e7          	jalr	1954(ra) # 80003634 <bmap>
    80003e9a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e9e:	c99d                	beqz	a1,80003ed4 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003ea0:	000aa503          	lw	a0,0(s5)
    80003ea4:	fffff097          	auipc	ra,0xfffff
    80003ea8:	39e080e7          	jalr	926(ra) # 80003242 <bread>
    80003eac:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eae:	3ff97713          	andi	a4,s2,1023
    80003eb2:	40ec87bb          	subw	a5,s9,a4
    80003eb6:	413b06bb          	subw	a3,s6,s3
    80003eba:	8d3e                	mv	s10,a5
    80003ebc:	2781                	sext.w	a5,a5
    80003ebe:	0006861b          	sext.w	a2,a3
    80003ec2:	f8f674e3          	bgeu	a2,a5,80003e4a <writei+0x4c>
    80003ec6:	8d36                	mv	s10,a3
    80003ec8:	b749                	j	80003e4a <writei+0x4c>
      brelse(bp);
    80003eca:	8526                	mv	a0,s1
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	4a6080e7          	jalr	1190(ra) # 80003372 <brelse>
  }

  if(off > ip->size)
    80003ed4:	04caa783          	lw	a5,76(s5)
    80003ed8:	0127f463          	bgeu	a5,s2,80003ee0 <writei+0xe2>
    ip->size = off;
    80003edc:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ee0:	8556                	mv	a0,s5
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	aa4080e7          	jalr	-1372(ra) # 80003986 <iupdate>

  return tot;
    80003eea:	0009851b          	sext.w	a0,s3
}
    80003eee:	70a6                	ld	ra,104(sp)
    80003ef0:	7406                	ld	s0,96(sp)
    80003ef2:	64e6                	ld	s1,88(sp)
    80003ef4:	6946                	ld	s2,80(sp)
    80003ef6:	69a6                	ld	s3,72(sp)
    80003ef8:	6a06                	ld	s4,64(sp)
    80003efa:	7ae2                	ld	s5,56(sp)
    80003efc:	7b42                	ld	s6,48(sp)
    80003efe:	7ba2                	ld	s7,40(sp)
    80003f00:	7c02                	ld	s8,32(sp)
    80003f02:	6ce2                	ld	s9,24(sp)
    80003f04:	6d42                	ld	s10,16(sp)
    80003f06:	6da2                	ld	s11,8(sp)
    80003f08:	6165                	addi	sp,sp,112
    80003f0a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f0c:	89da                	mv	s3,s6
    80003f0e:	bfc9                	j	80003ee0 <writei+0xe2>
    return -1;
    80003f10:	557d                	li	a0,-1
}
    80003f12:	8082                	ret
    return -1;
    80003f14:	557d                	li	a0,-1
    80003f16:	bfe1                	j	80003eee <writei+0xf0>
    return -1;
    80003f18:	557d                	li	a0,-1
    80003f1a:	bfd1                	j	80003eee <writei+0xf0>

0000000080003f1c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f1c:	1141                	addi	sp,sp,-16
    80003f1e:	e406                	sd	ra,8(sp)
    80003f20:	e022                	sd	s0,0(sp)
    80003f22:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f24:	4639                	li	a2,14
    80003f26:	ffffd097          	auipc	ra,0xffffd
    80003f2a:	e78080e7          	jalr	-392(ra) # 80000d9e <strncmp>
}
    80003f2e:	60a2                	ld	ra,8(sp)
    80003f30:	6402                	ld	s0,0(sp)
    80003f32:	0141                	addi	sp,sp,16
    80003f34:	8082                	ret

0000000080003f36 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f36:	7139                	addi	sp,sp,-64
    80003f38:	fc06                	sd	ra,56(sp)
    80003f3a:	f822                	sd	s0,48(sp)
    80003f3c:	f426                	sd	s1,40(sp)
    80003f3e:	f04a                	sd	s2,32(sp)
    80003f40:	ec4e                	sd	s3,24(sp)
    80003f42:	e852                	sd	s4,16(sp)
    80003f44:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f46:	04451703          	lh	a4,68(a0)
    80003f4a:	4785                	li	a5,1
    80003f4c:	00f71a63          	bne	a4,a5,80003f60 <dirlookup+0x2a>
    80003f50:	892a                	mv	s2,a0
    80003f52:	89ae                	mv	s3,a1
    80003f54:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f56:	457c                	lw	a5,76(a0)
    80003f58:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f5a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f5c:	e79d                	bnez	a5,80003f8a <dirlookup+0x54>
    80003f5e:	a8a5                	j	80003fd6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f60:	00004517          	auipc	a0,0x4
    80003f64:	6b050513          	addi	a0,a0,1712 # 80008610 <syscalls+0x1c0>
    80003f68:	ffffc097          	auipc	ra,0xffffc
    80003f6c:	5d4080e7          	jalr	1492(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003f70:	00004517          	auipc	a0,0x4
    80003f74:	6b850513          	addi	a0,a0,1720 # 80008628 <syscalls+0x1d8>
    80003f78:	ffffc097          	auipc	ra,0xffffc
    80003f7c:	5c4080e7          	jalr	1476(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f80:	24c1                	addiw	s1,s1,16
    80003f82:	04c92783          	lw	a5,76(s2)
    80003f86:	04f4f763          	bgeu	s1,a5,80003fd4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f8a:	4741                	li	a4,16
    80003f8c:	86a6                	mv	a3,s1
    80003f8e:	fc040613          	addi	a2,s0,-64
    80003f92:	4581                	li	a1,0
    80003f94:	854a                	mv	a0,s2
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	d70080e7          	jalr	-656(ra) # 80003d06 <readi>
    80003f9e:	47c1                	li	a5,16
    80003fa0:	fcf518e3          	bne	a0,a5,80003f70 <dirlookup+0x3a>
    if(de.inum == 0)
    80003fa4:	fc045783          	lhu	a5,-64(s0)
    80003fa8:	dfe1                	beqz	a5,80003f80 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003faa:	fc240593          	addi	a1,s0,-62
    80003fae:	854e                	mv	a0,s3
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	f6c080e7          	jalr	-148(ra) # 80003f1c <namecmp>
    80003fb8:	f561                	bnez	a0,80003f80 <dirlookup+0x4a>
      if(poff)
    80003fba:	000a0463          	beqz	s4,80003fc2 <dirlookup+0x8c>
        *poff = off;
    80003fbe:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fc2:	fc045583          	lhu	a1,-64(s0)
    80003fc6:	00092503          	lw	a0,0(s2)
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	754080e7          	jalr	1876(ra) # 8000371e <iget>
    80003fd2:	a011                	j	80003fd6 <dirlookup+0xa0>
  return 0;
    80003fd4:	4501                	li	a0,0
}
    80003fd6:	70e2                	ld	ra,56(sp)
    80003fd8:	7442                	ld	s0,48(sp)
    80003fda:	74a2                	ld	s1,40(sp)
    80003fdc:	7902                	ld	s2,32(sp)
    80003fde:	69e2                	ld	s3,24(sp)
    80003fe0:	6a42                	ld	s4,16(sp)
    80003fe2:	6121                	addi	sp,sp,64
    80003fe4:	8082                	ret

0000000080003fe6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fe6:	711d                	addi	sp,sp,-96
    80003fe8:	ec86                	sd	ra,88(sp)
    80003fea:	e8a2                	sd	s0,80(sp)
    80003fec:	e4a6                	sd	s1,72(sp)
    80003fee:	e0ca                	sd	s2,64(sp)
    80003ff0:	fc4e                	sd	s3,56(sp)
    80003ff2:	f852                	sd	s4,48(sp)
    80003ff4:	f456                	sd	s5,40(sp)
    80003ff6:	f05a                	sd	s6,32(sp)
    80003ff8:	ec5e                	sd	s7,24(sp)
    80003ffa:	e862                	sd	s8,16(sp)
    80003ffc:	e466                	sd	s9,8(sp)
    80003ffe:	1080                	addi	s0,sp,96
    80004000:	84aa                	mv	s1,a0
    80004002:	8b2e                	mv	s6,a1
    80004004:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004006:	00054703          	lbu	a4,0(a0)
    8000400a:	02f00793          	li	a5,47
    8000400e:	02f70263          	beq	a4,a5,80004032 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004012:	ffffe097          	auipc	ra,0xffffe
    80004016:	994080e7          	jalr	-1644(ra) # 800019a6 <myproc>
    8000401a:	15053503          	ld	a0,336(a0)
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	9f6080e7          	jalr	-1546(ra) # 80003a14 <idup>
    80004026:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004028:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000402c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000402e:	4b85                	li	s7,1
    80004030:	a875                	j	800040ec <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004032:	4585                	li	a1,1
    80004034:	4505                	li	a0,1
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	6e8080e7          	jalr	1768(ra) # 8000371e <iget>
    8000403e:	8a2a                	mv	s4,a0
    80004040:	b7e5                	j	80004028 <namex+0x42>
      iunlockput(ip);
    80004042:	8552                	mv	a0,s4
    80004044:	00000097          	auipc	ra,0x0
    80004048:	c70080e7          	jalr	-912(ra) # 80003cb4 <iunlockput>
      return 0;
    8000404c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000404e:	8552                	mv	a0,s4
    80004050:	60e6                	ld	ra,88(sp)
    80004052:	6446                	ld	s0,80(sp)
    80004054:	64a6                	ld	s1,72(sp)
    80004056:	6906                	ld	s2,64(sp)
    80004058:	79e2                	ld	s3,56(sp)
    8000405a:	7a42                	ld	s4,48(sp)
    8000405c:	7aa2                	ld	s5,40(sp)
    8000405e:	7b02                	ld	s6,32(sp)
    80004060:	6be2                	ld	s7,24(sp)
    80004062:	6c42                	ld	s8,16(sp)
    80004064:	6ca2                	ld	s9,8(sp)
    80004066:	6125                	addi	sp,sp,96
    80004068:	8082                	ret
      iunlock(ip);
    8000406a:	8552                	mv	a0,s4
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	aa8080e7          	jalr	-1368(ra) # 80003b14 <iunlock>
      return ip;
    80004074:	bfe9                	j	8000404e <namex+0x68>
      iunlockput(ip);
    80004076:	8552                	mv	a0,s4
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	c3c080e7          	jalr	-964(ra) # 80003cb4 <iunlockput>
      return 0;
    80004080:	8a4e                	mv	s4,s3
    80004082:	b7f1                	j	8000404e <namex+0x68>
  len = path - s;
    80004084:	40998633          	sub	a2,s3,s1
    80004088:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000408c:	099c5863          	bge	s8,s9,8000411c <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004090:	4639                	li	a2,14
    80004092:	85a6                	mv	a1,s1
    80004094:	8556                	mv	a0,s5
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	c94080e7          	jalr	-876(ra) # 80000d2a <memmove>
    8000409e:	84ce                	mv	s1,s3
  while(*path == '/')
    800040a0:	0004c783          	lbu	a5,0(s1)
    800040a4:	01279763          	bne	a5,s2,800040b2 <namex+0xcc>
    path++;
    800040a8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040aa:	0004c783          	lbu	a5,0(s1)
    800040ae:	ff278de3          	beq	a5,s2,800040a8 <namex+0xc2>
    ilock(ip);
    800040b2:	8552                	mv	a0,s4
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	99e080e7          	jalr	-1634(ra) # 80003a52 <ilock>
    if(ip->type != T_DIR){
    800040bc:	044a1783          	lh	a5,68(s4)
    800040c0:	f97791e3          	bne	a5,s7,80004042 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800040c4:	000b0563          	beqz	s6,800040ce <namex+0xe8>
    800040c8:	0004c783          	lbu	a5,0(s1)
    800040cc:	dfd9                	beqz	a5,8000406a <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040ce:	4601                	li	a2,0
    800040d0:	85d6                	mv	a1,s5
    800040d2:	8552                	mv	a0,s4
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	e62080e7          	jalr	-414(ra) # 80003f36 <dirlookup>
    800040dc:	89aa                	mv	s3,a0
    800040de:	dd41                	beqz	a0,80004076 <namex+0x90>
    iunlockput(ip);
    800040e0:	8552                	mv	a0,s4
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	bd2080e7          	jalr	-1070(ra) # 80003cb4 <iunlockput>
    ip = next;
    800040ea:	8a4e                	mv	s4,s3
  while(*path == '/')
    800040ec:	0004c783          	lbu	a5,0(s1)
    800040f0:	01279763          	bne	a5,s2,800040fe <namex+0x118>
    path++;
    800040f4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040f6:	0004c783          	lbu	a5,0(s1)
    800040fa:	ff278de3          	beq	a5,s2,800040f4 <namex+0x10e>
  if(*path == 0)
    800040fe:	cb9d                	beqz	a5,80004134 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004100:	0004c783          	lbu	a5,0(s1)
    80004104:	89a6                	mv	s3,s1
  len = path - s;
    80004106:	4c81                	li	s9,0
    80004108:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    8000410a:	01278963          	beq	a5,s2,8000411c <namex+0x136>
    8000410e:	dbbd                	beqz	a5,80004084 <namex+0x9e>
    path++;
    80004110:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004112:	0009c783          	lbu	a5,0(s3)
    80004116:	ff279ce3          	bne	a5,s2,8000410e <namex+0x128>
    8000411a:	b7ad                	j	80004084 <namex+0x9e>
    memmove(name, s, len);
    8000411c:	2601                	sext.w	a2,a2
    8000411e:	85a6                	mv	a1,s1
    80004120:	8556                	mv	a0,s5
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	c08080e7          	jalr	-1016(ra) # 80000d2a <memmove>
    name[len] = 0;
    8000412a:	9cd6                	add	s9,s9,s5
    8000412c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004130:	84ce                	mv	s1,s3
    80004132:	b7bd                	j	800040a0 <namex+0xba>
  if(nameiparent){
    80004134:	f00b0de3          	beqz	s6,8000404e <namex+0x68>
    iput(ip);
    80004138:	8552                	mv	a0,s4
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	ad2080e7          	jalr	-1326(ra) # 80003c0c <iput>
    return 0;
    80004142:	4a01                	li	s4,0
    80004144:	b729                	j	8000404e <namex+0x68>

0000000080004146 <dirlink>:
{
    80004146:	7139                	addi	sp,sp,-64
    80004148:	fc06                	sd	ra,56(sp)
    8000414a:	f822                	sd	s0,48(sp)
    8000414c:	f426                	sd	s1,40(sp)
    8000414e:	f04a                	sd	s2,32(sp)
    80004150:	ec4e                	sd	s3,24(sp)
    80004152:	e852                	sd	s4,16(sp)
    80004154:	0080                	addi	s0,sp,64
    80004156:	892a                	mv	s2,a0
    80004158:	8a2e                	mv	s4,a1
    8000415a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000415c:	4601                	li	a2,0
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	dd8080e7          	jalr	-552(ra) # 80003f36 <dirlookup>
    80004166:	e93d                	bnez	a0,800041dc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004168:	04c92483          	lw	s1,76(s2)
    8000416c:	c49d                	beqz	s1,8000419a <dirlink+0x54>
    8000416e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004170:	4741                	li	a4,16
    80004172:	86a6                	mv	a3,s1
    80004174:	fc040613          	addi	a2,s0,-64
    80004178:	4581                	li	a1,0
    8000417a:	854a                	mv	a0,s2
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	b8a080e7          	jalr	-1142(ra) # 80003d06 <readi>
    80004184:	47c1                	li	a5,16
    80004186:	06f51163          	bne	a0,a5,800041e8 <dirlink+0xa2>
    if(de.inum == 0)
    8000418a:	fc045783          	lhu	a5,-64(s0)
    8000418e:	c791                	beqz	a5,8000419a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004190:	24c1                	addiw	s1,s1,16
    80004192:	04c92783          	lw	a5,76(s2)
    80004196:	fcf4ede3          	bltu	s1,a5,80004170 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000419a:	4639                	li	a2,14
    8000419c:	85d2                	mv	a1,s4
    8000419e:	fc240513          	addi	a0,s0,-62
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	c38080e7          	jalr	-968(ra) # 80000dda <strncpy>
  de.inum = inum;
    800041aa:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041ae:	4741                	li	a4,16
    800041b0:	86a6                	mv	a3,s1
    800041b2:	fc040613          	addi	a2,s0,-64
    800041b6:	4581                	li	a1,0
    800041b8:	854a                	mv	a0,s2
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	c44080e7          	jalr	-956(ra) # 80003dfe <writei>
    800041c2:	1541                	addi	a0,a0,-16
    800041c4:	00a03533          	snez	a0,a0
    800041c8:	40a00533          	neg	a0,a0
}
    800041cc:	70e2                	ld	ra,56(sp)
    800041ce:	7442                	ld	s0,48(sp)
    800041d0:	74a2                	ld	s1,40(sp)
    800041d2:	7902                	ld	s2,32(sp)
    800041d4:	69e2                	ld	s3,24(sp)
    800041d6:	6a42                	ld	s4,16(sp)
    800041d8:	6121                	addi	sp,sp,64
    800041da:	8082                	ret
    iput(ip);
    800041dc:	00000097          	auipc	ra,0x0
    800041e0:	a30080e7          	jalr	-1488(ra) # 80003c0c <iput>
    return -1;
    800041e4:	557d                	li	a0,-1
    800041e6:	b7dd                	j	800041cc <dirlink+0x86>
      panic("dirlink read");
    800041e8:	00004517          	auipc	a0,0x4
    800041ec:	45050513          	addi	a0,a0,1104 # 80008638 <syscalls+0x1e8>
    800041f0:	ffffc097          	auipc	ra,0xffffc
    800041f4:	34c080e7          	jalr	844(ra) # 8000053c <panic>

00000000800041f8 <namei>:

struct inode*
namei(char *path)
{
    800041f8:	1101                	addi	sp,sp,-32
    800041fa:	ec06                	sd	ra,24(sp)
    800041fc:	e822                	sd	s0,16(sp)
    800041fe:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004200:	fe040613          	addi	a2,s0,-32
    80004204:	4581                	li	a1,0
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	de0080e7          	jalr	-544(ra) # 80003fe6 <namex>
}
    8000420e:	60e2                	ld	ra,24(sp)
    80004210:	6442                	ld	s0,16(sp)
    80004212:	6105                	addi	sp,sp,32
    80004214:	8082                	ret

0000000080004216 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004216:	1141                	addi	sp,sp,-16
    80004218:	e406                	sd	ra,8(sp)
    8000421a:	e022                	sd	s0,0(sp)
    8000421c:	0800                	addi	s0,sp,16
    8000421e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004220:	4585                	li	a1,1
    80004222:	00000097          	auipc	ra,0x0
    80004226:	dc4080e7          	jalr	-572(ra) # 80003fe6 <namex>
}
    8000422a:	60a2                	ld	ra,8(sp)
    8000422c:	6402                	ld	s0,0(sp)
    8000422e:	0141                	addi	sp,sp,16
    80004230:	8082                	ret

0000000080004232 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004232:	1101                	addi	sp,sp,-32
    80004234:	ec06                	sd	ra,24(sp)
    80004236:	e822                	sd	s0,16(sp)
    80004238:	e426                	sd	s1,8(sp)
    8000423a:	e04a                	sd	s2,0(sp)
    8000423c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000423e:	0001d917          	auipc	s2,0x1d
    80004242:	30290913          	addi	s2,s2,770 # 80021540 <log>
    80004246:	01892583          	lw	a1,24(s2)
    8000424a:	02892503          	lw	a0,40(s2)
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	ff4080e7          	jalr	-12(ra) # 80003242 <bread>
    80004256:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004258:	02c92603          	lw	a2,44(s2)
    8000425c:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000425e:	00c05f63          	blez	a2,8000427c <write_head+0x4a>
    80004262:	0001d717          	auipc	a4,0x1d
    80004266:	30e70713          	addi	a4,a4,782 # 80021570 <log+0x30>
    8000426a:	87aa                	mv	a5,a0
    8000426c:	060a                	slli	a2,a2,0x2
    8000426e:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004270:	4314                	lw	a3,0(a4)
    80004272:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004274:	0711                	addi	a4,a4,4
    80004276:	0791                	addi	a5,a5,4
    80004278:	fec79ce3          	bne	a5,a2,80004270 <write_head+0x3e>
  }
  bwrite(buf);
    8000427c:	8526                	mv	a0,s1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	0b6080e7          	jalr	182(ra) # 80003334 <bwrite>
  brelse(buf);
    80004286:	8526                	mv	a0,s1
    80004288:	fffff097          	auipc	ra,0xfffff
    8000428c:	0ea080e7          	jalr	234(ra) # 80003372 <brelse>
}
    80004290:	60e2                	ld	ra,24(sp)
    80004292:	6442                	ld	s0,16(sp)
    80004294:	64a2                	ld	s1,8(sp)
    80004296:	6902                	ld	s2,0(sp)
    80004298:	6105                	addi	sp,sp,32
    8000429a:	8082                	ret

000000008000429c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429c:	0001d797          	auipc	a5,0x1d
    800042a0:	2d07a783          	lw	a5,720(a5) # 8002156c <log+0x2c>
    800042a4:	0af05d63          	blez	a5,8000435e <install_trans+0xc2>
{
    800042a8:	7139                	addi	sp,sp,-64
    800042aa:	fc06                	sd	ra,56(sp)
    800042ac:	f822                	sd	s0,48(sp)
    800042ae:	f426                	sd	s1,40(sp)
    800042b0:	f04a                	sd	s2,32(sp)
    800042b2:	ec4e                	sd	s3,24(sp)
    800042b4:	e852                	sd	s4,16(sp)
    800042b6:	e456                	sd	s5,8(sp)
    800042b8:	e05a                	sd	s6,0(sp)
    800042ba:	0080                	addi	s0,sp,64
    800042bc:	8b2a                	mv	s6,a0
    800042be:	0001da97          	auipc	s5,0x1d
    800042c2:	2b2a8a93          	addi	s5,s5,690 # 80021570 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042c8:	0001d997          	auipc	s3,0x1d
    800042cc:	27898993          	addi	s3,s3,632 # 80021540 <log>
    800042d0:	a00d                	j	800042f2 <install_trans+0x56>
    brelse(lbuf);
    800042d2:	854a                	mv	a0,s2
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	09e080e7          	jalr	158(ra) # 80003372 <brelse>
    brelse(dbuf);
    800042dc:	8526                	mv	a0,s1
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	094080e7          	jalr	148(ra) # 80003372 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e6:	2a05                	addiw	s4,s4,1
    800042e8:	0a91                	addi	s5,s5,4
    800042ea:	02c9a783          	lw	a5,44(s3)
    800042ee:	04fa5e63          	bge	s4,a5,8000434a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042f2:	0189a583          	lw	a1,24(s3)
    800042f6:	014585bb          	addw	a1,a1,s4
    800042fa:	2585                	addiw	a1,a1,1
    800042fc:	0289a503          	lw	a0,40(s3)
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	f42080e7          	jalr	-190(ra) # 80003242 <bread>
    80004308:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000430a:	000aa583          	lw	a1,0(s5)
    8000430e:	0289a503          	lw	a0,40(s3)
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	f30080e7          	jalr	-208(ra) # 80003242 <bread>
    8000431a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000431c:	40000613          	li	a2,1024
    80004320:	05890593          	addi	a1,s2,88
    80004324:	05850513          	addi	a0,a0,88
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	a02080e7          	jalr	-1534(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004330:	8526                	mv	a0,s1
    80004332:	fffff097          	auipc	ra,0xfffff
    80004336:	002080e7          	jalr	2(ra) # 80003334 <bwrite>
    if(recovering == 0)
    8000433a:	f80b1ce3          	bnez	s6,800042d2 <install_trans+0x36>
      bunpin(dbuf);
    8000433e:	8526                	mv	a0,s1
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	10a080e7          	jalr	266(ra) # 8000344a <bunpin>
    80004348:	b769                	j	800042d2 <install_trans+0x36>
}
    8000434a:	70e2                	ld	ra,56(sp)
    8000434c:	7442                	ld	s0,48(sp)
    8000434e:	74a2                	ld	s1,40(sp)
    80004350:	7902                	ld	s2,32(sp)
    80004352:	69e2                	ld	s3,24(sp)
    80004354:	6a42                	ld	s4,16(sp)
    80004356:	6aa2                	ld	s5,8(sp)
    80004358:	6b02                	ld	s6,0(sp)
    8000435a:	6121                	addi	sp,sp,64
    8000435c:	8082                	ret
    8000435e:	8082                	ret

0000000080004360 <initlog>:
{
    80004360:	7179                	addi	sp,sp,-48
    80004362:	f406                	sd	ra,40(sp)
    80004364:	f022                	sd	s0,32(sp)
    80004366:	ec26                	sd	s1,24(sp)
    80004368:	e84a                	sd	s2,16(sp)
    8000436a:	e44e                	sd	s3,8(sp)
    8000436c:	1800                	addi	s0,sp,48
    8000436e:	892a                	mv	s2,a0
    80004370:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004372:	0001d497          	auipc	s1,0x1d
    80004376:	1ce48493          	addi	s1,s1,462 # 80021540 <log>
    8000437a:	00004597          	auipc	a1,0x4
    8000437e:	2ce58593          	addi	a1,a1,718 # 80008648 <syscalls+0x1f8>
    80004382:	8526                	mv	a0,s1
    80004384:	ffffc097          	auipc	ra,0xffffc
    80004388:	7be080e7          	jalr	1982(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    8000438c:	0149a583          	lw	a1,20(s3)
    80004390:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004392:	0109a783          	lw	a5,16(s3)
    80004396:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004398:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000439c:	854a                	mv	a0,s2
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	ea4080e7          	jalr	-348(ra) # 80003242 <bread>
  log.lh.n = lh->n;
    800043a6:	4d30                	lw	a2,88(a0)
    800043a8:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043aa:	00c05f63          	blez	a2,800043c8 <initlog+0x68>
    800043ae:	87aa                	mv	a5,a0
    800043b0:	0001d717          	auipc	a4,0x1d
    800043b4:	1c070713          	addi	a4,a4,448 # 80021570 <log+0x30>
    800043b8:	060a                	slli	a2,a2,0x2
    800043ba:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800043bc:	4ff4                	lw	a3,92(a5)
    800043be:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043c0:	0791                	addi	a5,a5,4
    800043c2:	0711                	addi	a4,a4,4
    800043c4:	fec79ce3          	bne	a5,a2,800043bc <initlog+0x5c>
  brelse(buf);
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	faa080e7          	jalr	-86(ra) # 80003372 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043d0:	4505                	li	a0,1
    800043d2:	00000097          	auipc	ra,0x0
    800043d6:	eca080e7          	jalr	-310(ra) # 8000429c <install_trans>
  log.lh.n = 0;
    800043da:	0001d797          	auipc	a5,0x1d
    800043de:	1807a923          	sw	zero,402(a5) # 8002156c <log+0x2c>
  write_head(); // clear the log
    800043e2:	00000097          	auipc	ra,0x0
    800043e6:	e50080e7          	jalr	-432(ra) # 80004232 <write_head>
}
    800043ea:	70a2                	ld	ra,40(sp)
    800043ec:	7402                	ld	s0,32(sp)
    800043ee:	64e2                	ld	s1,24(sp)
    800043f0:	6942                	ld	s2,16(sp)
    800043f2:	69a2                	ld	s3,8(sp)
    800043f4:	6145                	addi	sp,sp,48
    800043f6:	8082                	ret

00000000800043f8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043f8:	1101                	addi	sp,sp,-32
    800043fa:	ec06                	sd	ra,24(sp)
    800043fc:	e822                	sd	s0,16(sp)
    800043fe:	e426                	sd	s1,8(sp)
    80004400:	e04a                	sd	s2,0(sp)
    80004402:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004404:	0001d517          	auipc	a0,0x1d
    80004408:	13c50513          	addi	a0,a0,316 # 80021540 <log>
    8000440c:	ffffc097          	auipc	ra,0xffffc
    80004410:	7c6080e7          	jalr	1990(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004414:	0001d497          	auipc	s1,0x1d
    80004418:	12c48493          	addi	s1,s1,300 # 80021540 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000441c:	4979                	li	s2,30
    8000441e:	a039                	j	8000442c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004420:	85a6                	mv	a1,s1
    80004422:	8526                	mv	a0,s1
    80004424:	ffffe097          	auipc	ra,0xffffe
    80004428:	cec080e7          	jalr	-788(ra) # 80002110 <sleep>
    if(log.committing){
    8000442c:	50dc                	lw	a5,36(s1)
    8000442e:	fbed                	bnez	a5,80004420 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004430:	5098                	lw	a4,32(s1)
    80004432:	2705                	addiw	a4,a4,1
    80004434:	0027179b          	slliw	a5,a4,0x2
    80004438:	9fb9                	addw	a5,a5,a4
    8000443a:	0017979b          	slliw	a5,a5,0x1
    8000443e:	54d4                	lw	a3,44(s1)
    80004440:	9fb5                	addw	a5,a5,a3
    80004442:	00f95963          	bge	s2,a5,80004454 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004446:	85a6                	mv	a1,s1
    80004448:	8526                	mv	a0,s1
    8000444a:	ffffe097          	auipc	ra,0xffffe
    8000444e:	cc6080e7          	jalr	-826(ra) # 80002110 <sleep>
    80004452:	bfe9                	j	8000442c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004454:	0001d517          	auipc	a0,0x1d
    80004458:	0ec50513          	addi	a0,a0,236 # 80021540 <log>
    8000445c:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000445e:	ffffd097          	auipc	ra,0xffffd
    80004462:	828080e7          	jalr	-2008(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004466:	60e2                	ld	ra,24(sp)
    80004468:	6442                	ld	s0,16(sp)
    8000446a:	64a2                	ld	s1,8(sp)
    8000446c:	6902                	ld	s2,0(sp)
    8000446e:	6105                	addi	sp,sp,32
    80004470:	8082                	ret

0000000080004472 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004472:	7139                	addi	sp,sp,-64
    80004474:	fc06                	sd	ra,56(sp)
    80004476:	f822                	sd	s0,48(sp)
    80004478:	f426                	sd	s1,40(sp)
    8000447a:	f04a                	sd	s2,32(sp)
    8000447c:	ec4e                	sd	s3,24(sp)
    8000447e:	e852                	sd	s4,16(sp)
    80004480:	e456                	sd	s5,8(sp)
    80004482:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004484:	0001d497          	auipc	s1,0x1d
    80004488:	0bc48493          	addi	s1,s1,188 # 80021540 <log>
    8000448c:	8526                	mv	a0,s1
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	744080e7          	jalr	1860(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004496:	509c                	lw	a5,32(s1)
    80004498:	37fd                	addiw	a5,a5,-1
    8000449a:	0007891b          	sext.w	s2,a5
    8000449e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044a0:	50dc                	lw	a5,36(s1)
    800044a2:	e7b9                	bnez	a5,800044f0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044a4:	04091e63          	bnez	s2,80004500 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044a8:	0001d497          	auipc	s1,0x1d
    800044ac:	09848493          	addi	s1,s1,152 # 80021540 <log>
    800044b0:	4785                	li	a5,1
    800044b2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044b4:	8526                	mv	a0,s1
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	7d0080e7          	jalr	2000(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044be:	54dc                	lw	a5,44(s1)
    800044c0:	06f04763          	bgtz	a5,8000452e <end_op+0xbc>
    acquire(&log.lock);
    800044c4:	0001d497          	auipc	s1,0x1d
    800044c8:	07c48493          	addi	s1,s1,124 # 80021540 <log>
    800044cc:	8526                	mv	a0,s1
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	704080e7          	jalr	1796(ra) # 80000bd2 <acquire>
    log.committing = 0;
    800044d6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044da:	8526                	mv	a0,s1
    800044dc:	ffffe097          	auipc	ra,0xffffe
    800044e0:	c98080e7          	jalr	-872(ra) # 80002174 <wakeup>
    release(&log.lock);
    800044e4:	8526                	mv	a0,s1
    800044e6:	ffffc097          	auipc	ra,0xffffc
    800044ea:	7a0080e7          	jalr	1952(ra) # 80000c86 <release>
}
    800044ee:	a03d                	j	8000451c <end_op+0xaa>
    panic("log.committing");
    800044f0:	00004517          	auipc	a0,0x4
    800044f4:	16050513          	addi	a0,a0,352 # 80008650 <syscalls+0x200>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	044080e7          	jalr	68(ra) # 8000053c <panic>
    wakeup(&log);
    80004500:	0001d497          	auipc	s1,0x1d
    80004504:	04048493          	addi	s1,s1,64 # 80021540 <log>
    80004508:	8526                	mv	a0,s1
    8000450a:	ffffe097          	auipc	ra,0xffffe
    8000450e:	c6a080e7          	jalr	-918(ra) # 80002174 <wakeup>
  release(&log.lock);
    80004512:	8526                	mv	a0,s1
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	772080e7          	jalr	1906(ra) # 80000c86 <release>
}
    8000451c:	70e2                	ld	ra,56(sp)
    8000451e:	7442                	ld	s0,48(sp)
    80004520:	74a2                	ld	s1,40(sp)
    80004522:	7902                	ld	s2,32(sp)
    80004524:	69e2                	ld	s3,24(sp)
    80004526:	6a42                	ld	s4,16(sp)
    80004528:	6aa2                	ld	s5,8(sp)
    8000452a:	6121                	addi	sp,sp,64
    8000452c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000452e:	0001da97          	auipc	s5,0x1d
    80004532:	042a8a93          	addi	s5,s5,66 # 80021570 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004536:	0001da17          	auipc	s4,0x1d
    8000453a:	00aa0a13          	addi	s4,s4,10 # 80021540 <log>
    8000453e:	018a2583          	lw	a1,24(s4)
    80004542:	012585bb          	addw	a1,a1,s2
    80004546:	2585                	addiw	a1,a1,1
    80004548:	028a2503          	lw	a0,40(s4)
    8000454c:	fffff097          	auipc	ra,0xfffff
    80004550:	cf6080e7          	jalr	-778(ra) # 80003242 <bread>
    80004554:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004556:	000aa583          	lw	a1,0(s5)
    8000455a:	028a2503          	lw	a0,40(s4)
    8000455e:	fffff097          	auipc	ra,0xfffff
    80004562:	ce4080e7          	jalr	-796(ra) # 80003242 <bread>
    80004566:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004568:	40000613          	li	a2,1024
    8000456c:	05850593          	addi	a1,a0,88
    80004570:	05848513          	addi	a0,s1,88
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	7b6080e7          	jalr	1974(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    8000457c:	8526                	mv	a0,s1
    8000457e:	fffff097          	auipc	ra,0xfffff
    80004582:	db6080e7          	jalr	-586(ra) # 80003334 <bwrite>
    brelse(from);
    80004586:	854e                	mv	a0,s3
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	dea080e7          	jalr	-534(ra) # 80003372 <brelse>
    brelse(to);
    80004590:	8526                	mv	a0,s1
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	de0080e7          	jalr	-544(ra) # 80003372 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000459a:	2905                	addiw	s2,s2,1
    8000459c:	0a91                	addi	s5,s5,4
    8000459e:	02ca2783          	lw	a5,44(s4)
    800045a2:	f8f94ee3          	blt	s2,a5,8000453e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045a6:	00000097          	auipc	ra,0x0
    800045aa:	c8c080e7          	jalr	-884(ra) # 80004232 <write_head>
    install_trans(0); // Now install writes to home locations
    800045ae:	4501                	li	a0,0
    800045b0:	00000097          	auipc	ra,0x0
    800045b4:	cec080e7          	jalr	-788(ra) # 8000429c <install_trans>
    log.lh.n = 0;
    800045b8:	0001d797          	auipc	a5,0x1d
    800045bc:	fa07aa23          	sw	zero,-76(a5) # 8002156c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045c0:	00000097          	auipc	ra,0x0
    800045c4:	c72080e7          	jalr	-910(ra) # 80004232 <write_head>
    800045c8:	bdf5                	j	800044c4 <end_op+0x52>

00000000800045ca <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045ca:	1101                	addi	sp,sp,-32
    800045cc:	ec06                	sd	ra,24(sp)
    800045ce:	e822                	sd	s0,16(sp)
    800045d0:	e426                	sd	s1,8(sp)
    800045d2:	e04a                	sd	s2,0(sp)
    800045d4:	1000                	addi	s0,sp,32
    800045d6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045d8:	0001d917          	auipc	s2,0x1d
    800045dc:	f6890913          	addi	s2,s2,-152 # 80021540 <log>
    800045e0:	854a                	mv	a0,s2
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	5f0080e7          	jalr	1520(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045ea:	02c92603          	lw	a2,44(s2)
    800045ee:	47f5                	li	a5,29
    800045f0:	06c7c563          	blt	a5,a2,8000465a <log_write+0x90>
    800045f4:	0001d797          	auipc	a5,0x1d
    800045f8:	f687a783          	lw	a5,-152(a5) # 8002155c <log+0x1c>
    800045fc:	37fd                	addiw	a5,a5,-1
    800045fe:	04f65e63          	bge	a2,a5,8000465a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004602:	0001d797          	auipc	a5,0x1d
    80004606:	f5e7a783          	lw	a5,-162(a5) # 80021560 <log+0x20>
    8000460a:	06f05063          	blez	a5,8000466a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000460e:	4781                	li	a5,0
    80004610:	06c05563          	blez	a2,8000467a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004614:	44cc                	lw	a1,12(s1)
    80004616:	0001d717          	auipc	a4,0x1d
    8000461a:	f5a70713          	addi	a4,a4,-166 # 80021570 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000461e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004620:	4314                	lw	a3,0(a4)
    80004622:	04b68c63          	beq	a3,a1,8000467a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004626:	2785                	addiw	a5,a5,1
    80004628:	0711                	addi	a4,a4,4
    8000462a:	fef61be3          	bne	a2,a5,80004620 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000462e:	0621                	addi	a2,a2,8
    80004630:	060a                	slli	a2,a2,0x2
    80004632:	0001d797          	auipc	a5,0x1d
    80004636:	f0e78793          	addi	a5,a5,-242 # 80021540 <log>
    8000463a:	97b2                	add	a5,a5,a2
    8000463c:	44d8                	lw	a4,12(s1)
    8000463e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004640:	8526                	mv	a0,s1
    80004642:	fffff097          	auipc	ra,0xfffff
    80004646:	dcc080e7          	jalr	-564(ra) # 8000340e <bpin>
    log.lh.n++;
    8000464a:	0001d717          	auipc	a4,0x1d
    8000464e:	ef670713          	addi	a4,a4,-266 # 80021540 <log>
    80004652:	575c                	lw	a5,44(a4)
    80004654:	2785                	addiw	a5,a5,1
    80004656:	d75c                	sw	a5,44(a4)
    80004658:	a82d                	j	80004692 <log_write+0xc8>
    panic("too big a transaction");
    8000465a:	00004517          	auipc	a0,0x4
    8000465e:	00650513          	addi	a0,a0,6 # 80008660 <syscalls+0x210>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	eda080e7          	jalr	-294(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    8000466a:	00004517          	auipc	a0,0x4
    8000466e:	00e50513          	addi	a0,a0,14 # 80008678 <syscalls+0x228>
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	eca080e7          	jalr	-310(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    8000467a:	00878693          	addi	a3,a5,8
    8000467e:	068a                	slli	a3,a3,0x2
    80004680:	0001d717          	auipc	a4,0x1d
    80004684:	ec070713          	addi	a4,a4,-320 # 80021540 <log>
    80004688:	9736                	add	a4,a4,a3
    8000468a:	44d4                	lw	a3,12(s1)
    8000468c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000468e:	faf609e3          	beq	a2,a5,80004640 <log_write+0x76>
  }
  release(&log.lock);
    80004692:	0001d517          	auipc	a0,0x1d
    80004696:	eae50513          	addi	a0,a0,-338 # 80021540 <log>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	5ec080e7          	jalr	1516(ra) # 80000c86 <release>
}
    800046a2:	60e2                	ld	ra,24(sp)
    800046a4:	6442                	ld	s0,16(sp)
    800046a6:	64a2                	ld	s1,8(sp)
    800046a8:	6902                	ld	s2,0(sp)
    800046aa:	6105                	addi	sp,sp,32
    800046ac:	8082                	ret

00000000800046ae <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046ae:	1101                	addi	sp,sp,-32
    800046b0:	ec06                	sd	ra,24(sp)
    800046b2:	e822                	sd	s0,16(sp)
    800046b4:	e426                	sd	s1,8(sp)
    800046b6:	e04a                	sd	s2,0(sp)
    800046b8:	1000                	addi	s0,sp,32
    800046ba:	84aa                	mv	s1,a0
    800046bc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046be:	00004597          	auipc	a1,0x4
    800046c2:	fda58593          	addi	a1,a1,-38 # 80008698 <syscalls+0x248>
    800046c6:	0521                	addi	a0,a0,8
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	47a080e7          	jalr	1146(ra) # 80000b42 <initlock>
  lk->name = name;
    800046d0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046d8:	0204a423          	sw	zero,40(s1)
}
    800046dc:	60e2                	ld	ra,24(sp)
    800046de:	6442                	ld	s0,16(sp)
    800046e0:	64a2                	ld	s1,8(sp)
    800046e2:	6902                	ld	s2,0(sp)
    800046e4:	6105                	addi	sp,sp,32
    800046e6:	8082                	ret

00000000800046e8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046e8:	1101                	addi	sp,sp,-32
    800046ea:	ec06                	sd	ra,24(sp)
    800046ec:	e822                	sd	s0,16(sp)
    800046ee:	e426                	sd	s1,8(sp)
    800046f0:	e04a                	sd	s2,0(sp)
    800046f2:	1000                	addi	s0,sp,32
    800046f4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046f6:	00850913          	addi	s2,a0,8
    800046fa:	854a                	mv	a0,s2
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	4d6080e7          	jalr	1238(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004704:	409c                	lw	a5,0(s1)
    80004706:	cb89                	beqz	a5,80004718 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004708:	85ca                	mv	a1,s2
    8000470a:	8526                	mv	a0,s1
    8000470c:	ffffe097          	auipc	ra,0xffffe
    80004710:	a04080e7          	jalr	-1532(ra) # 80002110 <sleep>
  while (lk->locked) {
    80004714:	409c                	lw	a5,0(s1)
    80004716:	fbed                	bnez	a5,80004708 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004718:	4785                	li	a5,1
    8000471a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000471c:	ffffd097          	auipc	ra,0xffffd
    80004720:	28a080e7          	jalr	650(ra) # 800019a6 <myproc>
    80004724:	591c                	lw	a5,48(a0)
    80004726:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004728:	854a                	mv	a0,s2
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	55c080e7          	jalr	1372(ra) # 80000c86 <release>
}
    80004732:	60e2                	ld	ra,24(sp)
    80004734:	6442                	ld	s0,16(sp)
    80004736:	64a2                	ld	s1,8(sp)
    80004738:	6902                	ld	s2,0(sp)
    8000473a:	6105                	addi	sp,sp,32
    8000473c:	8082                	ret

000000008000473e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000473e:	1101                	addi	sp,sp,-32
    80004740:	ec06                	sd	ra,24(sp)
    80004742:	e822                	sd	s0,16(sp)
    80004744:	e426                	sd	s1,8(sp)
    80004746:	e04a                	sd	s2,0(sp)
    80004748:	1000                	addi	s0,sp,32
    8000474a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000474c:	00850913          	addi	s2,a0,8
    80004750:	854a                	mv	a0,s2
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	480080e7          	jalr	1152(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    8000475a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000475e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004762:	8526                	mv	a0,s1
    80004764:	ffffe097          	auipc	ra,0xffffe
    80004768:	a10080e7          	jalr	-1520(ra) # 80002174 <wakeup>
  release(&lk->lk);
    8000476c:	854a                	mv	a0,s2
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	518080e7          	jalr	1304(ra) # 80000c86 <release>
}
    80004776:	60e2                	ld	ra,24(sp)
    80004778:	6442                	ld	s0,16(sp)
    8000477a:	64a2                	ld	s1,8(sp)
    8000477c:	6902                	ld	s2,0(sp)
    8000477e:	6105                	addi	sp,sp,32
    80004780:	8082                	ret

0000000080004782 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004782:	7179                	addi	sp,sp,-48
    80004784:	f406                	sd	ra,40(sp)
    80004786:	f022                	sd	s0,32(sp)
    80004788:	ec26                	sd	s1,24(sp)
    8000478a:	e84a                	sd	s2,16(sp)
    8000478c:	e44e                	sd	s3,8(sp)
    8000478e:	1800                	addi	s0,sp,48
    80004790:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004792:	00850913          	addi	s2,a0,8
    80004796:	854a                	mv	a0,s2
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	43a080e7          	jalr	1082(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047a0:	409c                	lw	a5,0(s1)
    800047a2:	ef99                	bnez	a5,800047c0 <holdingsleep+0x3e>
    800047a4:	4481                	li	s1,0
  release(&lk->lk);
    800047a6:	854a                	mv	a0,s2
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	4de080e7          	jalr	1246(ra) # 80000c86 <release>
  return r;
}
    800047b0:	8526                	mv	a0,s1
    800047b2:	70a2                	ld	ra,40(sp)
    800047b4:	7402                	ld	s0,32(sp)
    800047b6:	64e2                	ld	s1,24(sp)
    800047b8:	6942                	ld	s2,16(sp)
    800047ba:	69a2                	ld	s3,8(sp)
    800047bc:	6145                	addi	sp,sp,48
    800047be:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047c0:	0284a983          	lw	s3,40(s1)
    800047c4:	ffffd097          	auipc	ra,0xffffd
    800047c8:	1e2080e7          	jalr	482(ra) # 800019a6 <myproc>
    800047cc:	5904                	lw	s1,48(a0)
    800047ce:	413484b3          	sub	s1,s1,s3
    800047d2:	0014b493          	seqz	s1,s1
    800047d6:	bfc1                	j	800047a6 <holdingsleep+0x24>

00000000800047d8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047d8:	1141                	addi	sp,sp,-16
    800047da:	e406                	sd	ra,8(sp)
    800047dc:	e022                	sd	s0,0(sp)
    800047de:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047e0:	00004597          	auipc	a1,0x4
    800047e4:	ec858593          	addi	a1,a1,-312 # 800086a8 <syscalls+0x258>
    800047e8:	0001d517          	auipc	a0,0x1d
    800047ec:	ea050513          	addi	a0,a0,-352 # 80021688 <ftable>
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	352080e7          	jalr	850(ra) # 80000b42 <initlock>
}
    800047f8:	60a2                	ld	ra,8(sp)
    800047fa:	6402                	ld	s0,0(sp)
    800047fc:	0141                	addi	sp,sp,16
    800047fe:	8082                	ret

0000000080004800 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004800:	1101                	addi	sp,sp,-32
    80004802:	ec06                	sd	ra,24(sp)
    80004804:	e822                	sd	s0,16(sp)
    80004806:	e426                	sd	s1,8(sp)
    80004808:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000480a:	0001d517          	auipc	a0,0x1d
    8000480e:	e7e50513          	addi	a0,a0,-386 # 80021688 <ftable>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	3c0080e7          	jalr	960(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000481a:	0001d497          	auipc	s1,0x1d
    8000481e:	e8648493          	addi	s1,s1,-378 # 800216a0 <ftable+0x18>
    80004822:	0001e717          	auipc	a4,0x1e
    80004826:	e1e70713          	addi	a4,a4,-482 # 80022640 <disk>
    if(f->ref == 0){
    8000482a:	40dc                	lw	a5,4(s1)
    8000482c:	cf99                	beqz	a5,8000484a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000482e:	02848493          	addi	s1,s1,40
    80004832:	fee49ce3          	bne	s1,a4,8000482a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004836:	0001d517          	auipc	a0,0x1d
    8000483a:	e5250513          	addi	a0,a0,-430 # 80021688 <ftable>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	448080e7          	jalr	1096(ra) # 80000c86 <release>
  return 0;
    80004846:	4481                	li	s1,0
    80004848:	a819                	j	8000485e <filealloc+0x5e>
      f->ref = 1;
    8000484a:	4785                	li	a5,1
    8000484c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000484e:	0001d517          	auipc	a0,0x1d
    80004852:	e3a50513          	addi	a0,a0,-454 # 80021688 <ftable>
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	430080e7          	jalr	1072(ra) # 80000c86 <release>
}
    8000485e:	8526                	mv	a0,s1
    80004860:	60e2                	ld	ra,24(sp)
    80004862:	6442                	ld	s0,16(sp)
    80004864:	64a2                	ld	s1,8(sp)
    80004866:	6105                	addi	sp,sp,32
    80004868:	8082                	ret

000000008000486a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000486a:	1101                	addi	sp,sp,-32
    8000486c:	ec06                	sd	ra,24(sp)
    8000486e:	e822                	sd	s0,16(sp)
    80004870:	e426                	sd	s1,8(sp)
    80004872:	1000                	addi	s0,sp,32
    80004874:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004876:	0001d517          	auipc	a0,0x1d
    8000487a:	e1250513          	addi	a0,a0,-494 # 80021688 <ftable>
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	354080e7          	jalr	852(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004886:	40dc                	lw	a5,4(s1)
    80004888:	02f05263          	blez	a5,800048ac <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000488c:	2785                	addiw	a5,a5,1
    8000488e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004890:	0001d517          	auipc	a0,0x1d
    80004894:	df850513          	addi	a0,a0,-520 # 80021688 <ftable>
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	3ee080e7          	jalr	1006(ra) # 80000c86 <release>
  return f;
}
    800048a0:	8526                	mv	a0,s1
    800048a2:	60e2                	ld	ra,24(sp)
    800048a4:	6442                	ld	s0,16(sp)
    800048a6:	64a2                	ld	s1,8(sp)
    800048a8:	6105                	addi	sp,sp,32
    800048aa:	8082                	ret
    panic("filedup");
    800048ac:	00004517          	auipc	a0,0x4
    800048b0:	e0450513          	addi	a0,a0,-508 # 800086b0 <syscalls+0x260>
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	c88080e7          	jalr	-888(ra) # 8000053c <panic>

00000000800048bc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048bc:	7139                	addi	sp,sp,-64
    800048be:	fc06                	sd	ra,56(sp)
    800048c0:	f822                	sd	s0,48(sp)
    800048c2:	f426                	sd	s1,40(sp)
    800048c4:	f04a                	sd	s2,32(sp)
    800048c6:	ec4e                	sd	s3,24(sp)
    800048c8:	e852                	sd	s4,16(sp)
    800048ca:	e456                	sd	s5,8(sp)
    800048cc:	0080                	addi	s0,sp,64
    800048ce:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048d0:	0001d517          	auipc	a0,0x1d
    800048d4:	db850513          	addi	a0,a0,-584 # 80021688 <ftable>
    800048d8:	ffffc097          	auipc	ra,0xffffc
    800048dc:	2fa080e7          	jalr	762(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800048e0:	40dc                	lw	a5,4(s1)
    800048e2:	06f05163          	blez	a5,80004944 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048e6:	37fd                	addiw	a5,a5,-1
    800048e8:	0007871b          	sext.w	a4,a5
    800048ec:	c0dc                	sw	a5,4(s1)
    800048ee:	06e04363          	bgtz	a4,80004954 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048f2:	0004a903          	lw	s2,0(s1)
    800048f6:	0094ca83          	lbu	s5,9(s1)
    800048fa:	0104ba03          	ld	s4,16(s1)
    800048fe:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004902:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004906:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000490a:	0001d517          	auipc	a0,0x1d
    8000490e:	d7e50513          	addi	a0,a0,-642 # 80021688 <ftable>
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	374080e7          	jalr	884(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    8000491a:	4785                	li	a5,1
    8000491c:	04f90d63          	beq	s2,a5,80004976 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004920:	3979                	addiw	s2,s2,-2
    80004922:	4785                	li	a5,1
    80004924:	0527e063          	bltu	a5,s2,80004964 <fileclose+0xa8>
    begin_op();
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	ad0080e7          	jalr	-1328(ra) # 800043f8 <begin_op>
    iput(ff.ip);
    80004930:	854e                	mv	a0,s3
    80004932:	fffff097          	auipc	ra,0xfffff
    80004936:	2da080e7          	jalr	730(ra) # 80003c0c <iput>
    end_op();
    8000493a:	00000097          	auipc	ra,0x0
    8000493e:	b38080e7          	jalr	-1224(ra) # 80004472 <end_op>
    80004942:	a00d                	j	80004964 <fileclose+0xa8>
    panic("fileclose");
    80004944:	00004517          	auipc	a0,0x4
    80004948:	d7450513          	addi	a0,a0,-652 # 800086b8 <syscalls+0x268>
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	bf0080e7          	jalr	-1040(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004954:	0001d517          	auipc	a0,0x1d
    80004958:	d3450513          	addi	a0,a0,-716 # 80021688 <ftable>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	32a080e7          	jalr	810(ra) # 80000c86 <release>
  }
}
    80004964:	70e2                	ld	ra,56(sp)
    80004966:	7442                	ld	s0,48(sp)
    80004968:	74a2                	ld	s1,40(sp)
    8000496a:	7902                	ld	s2,32(sp)
    8000496c:	69e2                	ld	s3,24(sp)
    8000496e:	6a42                	ld	s4,16(sp)
    80004970:	6aa2                	ld	s5,8(sp)
    80004972:	6121                	addi	sp,sp,64
    80004974:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004976:	85d6                	mv	a1,s5
    80004978:	8552                	mv	a0,s4
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	348080e7          	jalr	840(ra) # 80004cc2 <pipeclose>
    80004982:	b7cd                	j	80004964 <fileclose+0xa8>

0000000080004984 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004984:	715d                	addi	sp,sp,-80
    80004986:	e486                	sd	ra,72(sp)
    80004988:	e0a2                	sd	s0,64(sp)
    8000498a:	fc26                	sd	s1,56(sp)
    8000498c:	f84a                	sd	s2,48(sp)
    8000498e:	f44e                	sd	s3,40(sp)
    80004990:	0880                	addi	s0,sp,80
    80004992:	84aa                	mv	s1,a0
    80004994:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004996:	ffffd097          	auipc	ra,0xffffd
    8000499a:	010080e7          	jalr	16(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000499e:	409c                	lw	a5,0(s1)
    800049a0:	37f9                	addiw	a5,a5,-2
    800049a2:	4705                	li	a4,1
    800049a4:	04f76763          	bltu	a4,a5,800049f2 <filestat+0x6e>
    800049a8:	892a                	mv	s2,a0
    ilock(f->ip);
    800049aa:	6c88                	ld	a0,24(s1)
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	0a6080e7          	jalr	166(ra) # 80003a52 <ilock>
    stati(f->ip, &st);
    800049b4:	fb840593          	addi	a1,s0,-72
    800049b8:	6c88                	ld	a0,24(s1)
    800049ba:	fffff097          	auipc	ra,0xfffff
    800049be:	322080e7          	jalr	802(ra) # 80003cdc <stati>
    iunlock(f->ip);
    800049c2:	6c88                	ld	a0,24(s1)
    800049c4:	fffff097          	auipc	ra,0xfffff
    800049c8:	150080e7          	jalr	336(ra) # 80003b14 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049cc:	46e1                	li	a3,24
    800049ce:	fb840613          	addi	a2,s0,-72
    800049d2:	85ce                	mv	a1,s3
    800049d4:	05093503          	ld	a0,80(s2)
    800049d8:	ffffd097          	auipc	ra,0xffffd
    800049dc:	c8e080e7          	jalr	-882(ra) # 80001666 <copyout>
    800049e0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049e4:	60a6                	ld	ra,72(sp)
    800049e6:	6406                	ld	s0,64(sp)
    800049e8:	74e2                	ld	s1,56(sp)
    800049ea:	7942                	ld	s2,48(sp)
    800049ec:	79a2                	ld	s3,40(sp)
    800049ee:	6161                	addi	sp,sp,80
    800049f0:	8082                	ret
  return -1;
    800049f2:	557d                	li	a0,-1
    800049f4:	bfc5                	j	800049e4 <filestat+0x60>

00000000800049f6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049f6:	7179                	addi	sp,sp,-48
    800049f8:	f406                	sd	ra,40(sp)
    800049fa:	f022                	sd	s0,32(sp)
    800049fc:	ec26                	sd	s1,24(sp)
    800049fe:	e84a                	sd	s2,16(sp)
    80004a00:	e44e                	sd	s3,8(sp)
    80004a02:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a04:	00854783          	lbu	a5,8(a0)
    80004a08:	c3d5                	beqz	a5,80004aac <fileread+0xb6>
    80004a0a:	84aa                	mv	s1,a0
    80004a0c:	89ae                	mv	s3,a1
    80004a0e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a10:	411c                	lw	a5,0(a0)
    80004a12:	4705                	li	a4,1
    80004a14:	04e78963          	beq	a5,a4,80004a66 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a18:	470d                	li	a4,3
    80004a1a:	04e78d63          	beq	a5,a4,80004a74 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a1e:	4709                	li	a4,2
    80004a20:	06e79e63          	bne	a5,a4,80004a9c <fileread+0xa6>
    ilock(f->ip);
    80004a24:	6d08                	ld	a0,24(a0)
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	02c080e7          	jalr	44(ra) # 80003a52 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a2e:	874a                	mv	a4,s2
    80004a30:	5094                	lw	a3,32(s1)
    80004a32:	864e                	mv	a2,s3
    80004a34:	4585                	li	a1,1
    80004a36:	6c88                	ld	a0,24(s1)
    80004a38:	fffff097          	auipc	ra,0xfffff
    80004a3c:	2ce080e7          	jalr	718(ra) # 80003d06 <readi>
    80004a40:	892a                	mv	s2,a0
    80004a42:	00a05563          	blez	a0,80004a4c <fileread+0x56>
      f->off += r;
    80004a46:	509c                	lw	a5,32(s1)
    80004a48:	9fa9                	addw	a5,a5,a0
    80004a4a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a4c:	6c88                	ld	a0,24(s1)
    80004a4e:	fffff097          	auipc	ra,0xfffff
    80004a52:	0c6080e7          	jalr	198(ra) # 80003b14 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a56:	854a                	mv	a0,s2
    80004a58:	70a2                	ld	ra,40(sp)
    80004a5a:	7402                	ld	s0,32(sp)
    80004a5c:	64e2                	ld	s1,24(sp)
    80004a5e:	6942                	ld	s2,16(sp)
    80004a60:	69a2                	ld	s3,8(sp)
    80004a62:	6145                	addi	sp,sp,48
    80004a64:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a66:	6908                	ld	a0,16(a0)
    80004a68:	00000097          	auipc	ra,0x0
    80004a6c:	3c2080e7          	jalr	962(ra) # 80004e2a <piperead>
    80004a70:	892a                	mv	s2,a0
    80004a72:	b7d5                	j	80004a56 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a74:	02451783          	lh	a5,36(a0)
    80004a78:	03079693          	slli	a3,a5,0x30
    80004a7c:	92c1                	srli	a3,a3,0x30
    80004a7e:	4725                	li	a4,9
    80004a80:	02d76863          	bltu	a4,a3,80004ab0 <fileread+0xba>
    80004a84:	0792                	slli	a5,a5,0x4
    80004a86:	0001d717          	auipc	a4,0x1d
    80004a8a:	b6270713          	addi	a4,a4,-1182 # 800215e8 <devsw>
    80004a8e:	97ba                	add	a5,a5,a4
    80004a90:	639c                	ld	a5,0(a5)
    80004a92:	c38d                	beqz	a5,80004ab4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a94:	4505                	li	a0,1
    80004a96:	9782                	jalr	a5
    80004a98:	892a                	mv	s2,a0
    80004a9a:	bf75                	j	80004a56 <fileread+0x60>
    panic("fileread");
    80004a9c:	00004517          	auipc	a0,0x4
    80004aa0:	c2c50513          	addi	a0,a0,-980 # 800086c8 <syscalls+0x278>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	a98080e7          	jalr	-1384(ra) # 8000053c <panic>
    return -1;
    80004aac:	597d                	li	s2,-1
    80004aae:	b765                	j	80004a56 <fileread+0x60>
      return -1;
    80004ab0:	597d                	li	s2,-1
    80004ab2:	b755                	j	80004a56 <fileread+0x60>
    80004ab4:	597d                	li	s2,-1
    80004ab6:	b745                	j	80004a56 <fileread+0x60>

0000000080004ab8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004ab8:	00954783          	lbu	a5,9(a0)
    80004abc:	10078e63          	beqz	a5,80004bd8 <filewrite+0x120>
{
    80004ac0:	715d                	addi	sp,sp,-80
    80004ac2:	e486                	sd	ra,72(sp)
    80004ac4:	e0a2                	sd	s0,64(sp)
    80004ac6:	fc26                	sd	s1,56(sp)
    80004ac8:	f84a                	sd	s2,48(sp)
    80004aca:	f44e                	sd	s3,40(sp)
    80004acc:	f052                	sd	s4,32(sp)
    80004ace:	ec56                	sd	s5,24(sp)
    80004ad0:	e85a                	sd	s6,16(sp)
    80004ad2:	e45e                	sd	s7,8(sp)
    80004ad4:	e062                	sd	s8,0(sp)
    80004ad6:	0880                	addi	s0,sp,80
    80004ad8:	892a                	mv	s2,a0
    80004ada:	8b2e                	mv	s6,a1
    80004adc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ade:	411c                	lw	a5,0(a0)
    80004ae0:	4705                	li	a4,1
    80004ae2:	02e78263          	beq	a5,a4,80004b06 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ae6:	470d                	li	a4,3
    80004ae8:	02e78563          	beq	a5,a4,80004b12 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004aec:	4709                	li	a4,2
    80004aee:	0ce79d63          	bne	a5,a4,80004bc8 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004af2:	0ac05b63          	blez	a2,80004ba8 <filewrite+0xf0>
    int i = 0;
    80004af6:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004af8:	6b85                	lui	s7,0x1
    80004afa:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004afe:	6c05                	lui	s8,0x1
    80004b00:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004b04:	a851                	j	80004b98 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004b06:	6908                	ld	a0,16(a0)
    80004b08:	00000097          	auipc	ra,0x0
    80004b0c:	22a080e7          	jalr	554(ra) # 80004d32 <pipewrite>
    80004b10:	a045                	j	80004bb0 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b12:	02451783          	lh	a5,36(a0)
    80004b16:	03079693          	slli	a3,a5,0x30
    80004b1a:	92c1                	srli	a3,a3,0x30
    80004b1c:	4725                	li	a4,9
    80004b1e:	0ad76f63          	bltu	a4,a3,80004bdc <filewrite+0x124>
    80004b22:	0792                	slli	a5,a5,0x4
    80004b24:	0001d717          	auipc	a4,0x1d
    80004b28:	ac470713          	addi	a4,a4,-1340 # 800215e8 <devsw>
    80004b2c:	97ba                	add	a5,a5,a4
    80004b2e:	679c                	ld	a5,8(a5)
    80004b30:	cbc5                	beqz	a5,80004be0 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004b32:	4505                	li	a0,1
    80004b34:	9782                	jalr	a5
    80004b36:	a8ad                	j	80004bb0 <filewrite+0xf8>
      if(n1 > max)
    80004b38:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004b3c:	00000097          	auipc	ra,0x0
    80004b40:	8bc080e7          	jalr	-1860(ra) # 800043f8 <begin_op>
      ilock(f->ip);
    80004b44:	01893503          	ld	a0,24(s2)
    80004b48:	fffff097          	auipc	ra,0xfffff
    80004b4c:	f0a080e7          	jalr	-246(ra) # 80003a52 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b50:	8756                	mv	a4,s5
    80004b52:	02092683          	lw	a3,32(s2)
    80004b56:	01698633          	add	a2,s3,s6
    80004b5a:	4585                	li	a1,1
    80004b5c:	01893503          	ld	a0,24(s2)
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	29e080e7          	jalr	670(ra) # 80003dfe <writei>
    80004b68:	84aa                	mv	s1,a0
    80004b6a:	00a05763          	blez	a0,80004b78 <filewrite+0xc0>
        f->off += r;
    80004b6e:	02092783          	lw	a5,32(s2)
    80004b72:	9fa9                	addw	a5,a5,a0
    80004b74:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b78:	01893503          	ld	a0,24(s2)
    80004b7c:	fffff097          	auipc	ra,0xfffff
    80004b80:	f98080e7          	jalr	-104(ra) # 80003b14 <iunlock>
      end_op();
    80004b84:	00000097          	auipc	ra,0x0
    80004b88:	8ee080e7          	jalr	-1810(ra) # 80004472 <end_op>

      if(r != n1){
    80004b8c:	009a9f63          	bne	s5,s1,80004baa <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004b90:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b94:	0149db63          	bge	s3,s4,80004baa <filewrite+0xf2>
      int n1 = n - i;
    80004b98:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004b9c:	0004879b          	sext.w	a5,s1
    80004ba0:	f8fbdce3          	bge	s7,a5,80004b38 <filewrite+0x80>
    80004ba4:	84e2                	mv	s1,s8
    80004ba6:	bf49                	j	80004b38 <filewrite+0x80>
    int i = 0;
    80004ba8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004baa:	033a1d63          	bne	s4,s3,80004be4 <filewrite+0x12c>
    80004bae:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bb0:	60a6                	ld	ra,72(sp)
    80004bb2:	6406                	ld	s0,64(sp)
    80004bb4:	74e2                	ld	s1,56(sp)
    80004bb6:	7942                	ld	s2,48(sp)
    80004bb8:	79a2                	ld	s3,40(sp)
    80004bba:	7a02                	ld	s4,32(sp)
    80004bbc:	6ae2                	ld	s5,24(sp)
    80004bbe:	6b42                	ld	s6,16(sp)
    80004bc0:	6ba2                	ld	s7,8(sp)
    80004bc2:	6c02                	ld	s8,0(sp)
    80004bc4:	6161                	addi	sp,sp,80
    80004bc6:	8082                	ret
    panic("filewrite");
    80004bc8:	00004517          	auipc	a0,0x4
    80004bcc:	b1050513          	addi	a0,a0,-1264 # 800086d8 <syscalls+0x288>
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	96c080e7          	jalr	-1684(ra) # 8000053c <panic>
    return -1;
    80004bd8:	557d                	li	a0,-1
}
    80004bda:	8082                	ret
      return -1;
    80004bdc:	557d                	li	a0,-1
    80004bde:	bfc9                	j	80004bb0 <filewrite+0xf8>
    80004be0:	557d                	li	a0,-1
    80004be2:	b7f9                	j	80004bb0 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004be4:	557d                	li	a0,-1
    80004be6:	b7e9                	j	80004bb0 <filewrite+0xf8>

0000000080004be8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004be8:	7179                	addi	sp,sp,-48
    80004bea:	f406                	sd	ra,40(sp)
    80004bec:	f022                	sd	s0,32(sp)
    80004bee:	ec26                	sd	s1,24(sp)
    80004bf0:	e84a                	sd	s2,16(sp)
    80004bf2:	e44e                	sd	s3,8(sp)
    80004bf4:	e052                	sd	s4,0(sp)
    80004bf6:	1800                	addi	s0,sp,48
    80004bf8:	84aa                	mv	s1,a0
    80004bfa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bfc:	0005b023          	sd	zero,0(a1)
    80004c00:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c04:	00000097          	auipc	ra,0x0
    80004c08:	bfc080e7          	jalr	-1028(ra) # 80004800 <filealloc>
    80004c0c:	e088                	sd	a0,0(s1)
    80004c0e:	c551                	beqz	a0,80004c9a <pipealloc+0xb2>
    80004c10:	00000097          	auipc	ra,0x0
    80004c14:	bf0080e7          	jalr	-1040(ra) # 80004800 <filealloc>
    80004c18:	00aa3023          	sd	a0,0(s4)
    80004c1c:	c92d                	beqz	a0,80004c8e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	ec4080e7          	jalr	-316(ra) # 80000ae2 <kalloc>
    80004c26:	892a                	mv	s2,a0
    80004c28:	c125                	beqz	a0,80004c88 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c2a:	4985                	li	s3,1
    80004c2c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c30:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c34:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c38:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c3c:	00004597          	auipc	a1,0x4
    80004c40:	aac58593          	addi	a1,a1,-1364 # 800086e8 <syscalls+0x298>
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	efe080e7          	jalr	-258(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004c4c:	609c                	ld	a5,0(s1)
    80004c4e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c52:	609c                	ld	a5,0(s1)
    80004c54:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c58:	609c                	ld	a5,0(s1)
    80004c5a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c5e:	609c                	ld	a5,0(s1)
    80004c60:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c64:	000a3783          	ld	a5,0(s4)
    80004c68:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c6c:	000a3783          	ld	a5,0(s4)
    80004c70:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c74:	000a3783          	ld	a5,0(s4)
    80004c78:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c7c:	000a3783          	ld	a5,0(s4)
    80004c80:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c84:	4501                	li	a0,0
    80004c86:	a025                	j	80004cae <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c88:	6088                	ld	a0,0(s1)
    80004c8a:	e501                	bnez	a0,80004c92 <pipealloc+0xaa>
    80004c8c:	a039                	j	80004c9a <pipealloc+0xb2>
    80004c8e:	6088                	ld	a0,0(s1)
    80004c90:	c51d                	beqz	a0,80004cbe <pipealloc+0xd6>
    fileclose(*f0);
    80004c92:	00000097          	auipc	ra,0x0
    80004c96:	c2a080e7          	jalr	-982(ra) # 800048bc <fileclose>
  if(*f1)
    80004c9a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c9e:	557d                	li	a0,-1
  if(*f1)
    80004ca0:	c799                	beqz	a5,80004cae <pipealloc+0xc6>
    fileclose(*f1);
    80004ca2:	853e                	mv	a0,a5
    80004ca4:	00000097          	auipc	ra,0x0
    80004ca8:	c18080e7          	jalr	-1000(ra) # 800048bc <fileclose>
  return -1;
    80004cac:	557d                	li	a0,-1
}
    80004cae:	70a2                	ld	ra,40(sp)
    80004cb0:	7402                	ld	s0,32(sp)
    80004cb2:	64e2                	ld	s1,24(sp)
    80004cb4:	6942                	ld	s2,16(sp)
    80004cb6:	69a2                	ld	s3,8(sp)
    80004cb8:	6a02                	ld	s4,0(sp)
    80004cba:	6145                	addi	sp,sp,48
    80004cbc:	8082                	ret
  return -1;
    80004cbe:	557d                	li	a0,-1
    80004cc0:	b7fd                	j	80004cae <pipealloc+0xc6>

0000000080004cc2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cc2:	1101                	addi	sp,sp,-32
    80004cc4:	ec06                	sd	ra,24(sp)
    80004cc6:	e822                	sd	s0,16(sp)
    80004cc8:	e426                	sd	s1,8(sp)
    80004cca:	e04a                	sd	s2,0(sp)
    80004ccc:	1000                	addi	s0,sp,32
    80004cce:	84aa                	mv	s1,a0
    80004cd0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	f00080e7          	jalr	-256(ra) # 80000bd2 <acquire>
  if(writable){
    80004cda:	02090d63          	beqz	s2,80004d14 <pipeclose+0x52>
    pi->writeopen = 0;
    80004cde:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ce2:	21848513          	addi	a0,s1,536
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	48e080e7          	jalr	1166(ra) # 80002174 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cee:	2204b783          	ld	a5,544(s1)
    80004cf2:	eb95                	bnez	a5,80004d26 <pipeclose+0x64>
    release(&pi->lock);
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	f90080e7          	jalr	-112(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004cfe:	8526                	mv	a0,s1
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	ce4080e7          	jalr	-796(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004d08:	60e2                	ld	ra,24(sp)
    80004d0a:	6442                	ld	s0,16(sp)
    80004d0c:	64a2                	ld	s1,8(sp)
    80004d0e:	6902                	ld	s2,0(sp)
    80004d10:	6105                	addi	sp,sp,32
    80004d12:	8082                	ret
    pi->readopen = 0;
    80004d14:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d18:	21c48513          	addi	a0,s1,540
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	458080e7          	jalr	1112(ra) # 80002174 <wakeup>
    80004d24:	b7e9                	j	80004cee <pipeclose+0x2c>
    release(&pi->lock);
    80004d26:	8526                	mv	a0,s1
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	f5e080e7          	jalr	-162(ra) # 80000c86 <release>
}
    80004d30:	bfe1                	j	80004d08 <pipeclose+0x46>

0000000080004d32 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d32:	711d                	addi	sp,sp,-96
    80004d34:	ec86                	sd	ra,88(sp)
    80004d36:	e8a2                	sd	s0,80(sp)
    80004d38:	e4a6                	sd	s1,72(sp)
    80004d3a:	e0ca                	sd	s2,64(sp)
    80004d3c:	fc4e                	sd	s3,56(sp)
    80004d3e:	f852                	sd	s4,48(sp)
    80004d40:	f456                	sd	s5,40(sp)
    80004d42:	f05a                	sd	s6,32(sp)
    80004d44:	ec5e                	sd	s7,24(sp)
    80004d46:	e862                	sd	s8,16(sp)
    80004d48:	1080                	addi	s0,sp,96
    80004d4a:	84aa                	mv	s1,a0
    80004d4c:	8aae                	mv	s5,a1
    80004d4e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d50:	ffffd097          	auipc	ra,0xffffd
    80004d54:	c56080e7          	jalr	-938(ra) # 800019a6 <myproc>
    80004d58:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d5a:	8526                	mv	a0,s1
    80004d5c:	ffffc097          	auipc	ra,0xffffc
    80004d60:	e76080e7          	jalr	-394(ra) # 80000bd2 <acquire>
  while(i < n){
    80004d64:	0b405663          	blez	s4,80004e10 <pipewrite+0xde>
  int i = 0;
    80004d68:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d6a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d6c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d70:	21c48b93          	addi	s7,s1,540
    80004d74:	a089                	j	80004db6 <pipewrite+0x84>
      release(&pi->lock);
    80004d76:	8526                	mv	a0,s1
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	f0e080e7          	jalr	-242(ra) # 80000c86 <release>
      return -1;
    80004d80:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d82:	854a                	mv	a0,s2
    80004d84:	60e6                	ld	ra,88(sp)
    80004d86:	6446                	ld	s0,80(sp)
    80004d88:	64a6                	ld	s1,72(sp)
    80004d8a:	6906                	ld	s2,64(sp)
    80004d8c:	79e2                	ld	s3,56(sp)
    80004d8e:	7a42                	ld	s4,48(sp)
    80004d90:	7aa2                	ld	s5,40(sp)
    80004d92:	7b02                	ld	s6,32(sp)
    80004d94:	6be2                	ld	s7,24(sp)
    80004d96:	6c42                	ld	s8,16(sp)
    80004d98:	6125                	addi	sp,sp,96
    80004d9a:	8082                	ret
      wakeup(&pi->nread);
    80004d9c:	8562                	mv	a0,s8
    80004d9e:	ffffd097          	auipc	ra,0xffffd
    80004da2:	3d6080e7          	jalr	982(ra) # 80002174 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004da6:	85a6                	mv	a1,s1
    80004da8:	855e                	mv	a0,s7
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	366080e7          	jalr	870(ra) # 80002110 <sleep>
  while(i < n){
    80004db2:	07495063          	bge	s2,s4,80004e12 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004db6:	2204a783          	lw	a5,544(s1)
    80004dba:	dfd5                	beqz	a5,80004d76 <pipewrite+0x44>
    80004dbc:	854e                	mv	a0,s3
    80004dbe:	ffffd097          	auipc	ra,0xffffd
    80004dc2:	606080e7          	jalr	1542(ra) # 800023c4 <killed>
    80004dc6:	f945                	bnez	a0,80004d76 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004dc8:	2184a783          	lw	a5,536(s1)
    80004dcc:	21c4a703          	lw	a4,540(s1)
    80004dd0:	2007879b          	addiw	a5,a5,512
    80004dd4:	fcf704e3          	beq	a4,a5,80004d9c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dd8:	4685                	li	a3,1
    80004dda:	01590633          	add	a2,s2,s5
    80004dde:	faf40593          	addi	a1,s0,-81
    80004de2:	0509b503          	ld	a0,80(s3)
    80004de6:	ffffd097          	auipc	ra,0xffffd
    80004dea:	90c080e7          	jalr	-1780(ra) # 800016f2 <copyin>
    80004dee:	03650263          	beq	a0,s6,80004e12 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004df2:	21c4a783          	lw	a5,540(s1)
    80004df6:	0017871b          	addiw	a4,a5,1
    80004dfa:	20e4ae23          	sw	a4,540(s1)
    80004dfe:	1ff7f793          	andi	a5,a5,511
    80004e02:	97a6                	add	a5,a5,s1
    80004e04:	faf44703          	lbu	a4,-81(s0)
    80004e08:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e0c:	2905                	addiw	s2,s2,1
    80004e0e:	b755                	j	80004db2 <pipewrite+0x80>
  int i = 0;
    80004e10:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e12:	21848513          	addi	a0,s1,536
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	35e080e7          	jalr	862(ra) # 80002174 <wakeup>
  release(&pi->lock);
    80004e1e:	8526                	mv	a0,s1
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	e66080e7          	jalr	-410(ra) # 80000c86 <release>
  return i;
    80004e28:	bfa9                	j	80004d82 <pipewrite+0x50>

0000000080004e2a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e2a:	715d                	addi	sp,sp,-80
    80004e2c:	e486                	sd	ra,72(sp)
    80004e2e:	e0a2                	sd	s0,64(sp)
    80004e30:	fc26                	sd	s1,56(sp)
    80004e32:	f84a                	sd	s2,48(sp)
    80004e34:	f44e                	sd	s3,40(sp)
    80004e36:	f052                	sd	s4,32(sp)
    80004e38:	ec56                	sd	s5,24(sp)
    80004e3a:	e85a                	sd	s6,16(sp)
    80004e3c:	0880                	addi	s0,sp,80
    80004e3e:	84aa                	mv	s1,a0
    80004e40:	892e                	mv	s2,a1
    80004e42:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	b62080e7          	jalr	-1182(ra) # 800019a6 <myproc>
    80004e4c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e4e:	8526                	mv	a0,s1
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	d82080e7          	jalr	-638(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e58:	2184a703          	lw	a4,536(s1)
    80004e5c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e60:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e64:	02f71763          	bne	a4,a5,80004e92 <piperead+0x68>
    80004e68:	2244a783          	lw	a5,548(s1)
    80004e6c:	c39d                	beqz	a5,80004e92 <piperead+0x68>
    if(killed(pr)){
    80004e6e:	8552                	mv	a0,s4
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	554080e7          	jalr	1364(ra) # 800023c4 <killed>
    80004e78:	e949                	bnez	a0,80004f0a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e7a:	85a6                	mv	a1,s1
    80004e7c:	854e                	mv	a0,s3
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	292080e7          	jalr	658(ra) # 80002110 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e86:	2184a703          	lw	a4,536(s1)
    80004e8a:	21c4a783          	lw	a5,540(s1)
    80004e8e:	fcf70de3          	beq	a4,a5,80004e68 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e92:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e94:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e96:	05505463          	blez	s5,80004ede <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004e9a:	2184a783          	lw	a5,536(s1)
    80004e9e:	21c4a703          	lw	a4,540(s1)
    80004ea2:	02f70e63          	beq	a4,a5,80004ede <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ea6:	0017871b          	addiw	a4,a5,1
    80004eaa:	20e4ac23          	sw	a4,536(s1)
    80004eae:	1ff7f793          	andi	a5,a5,511
    80004eb2:	97a6                	add	a5,a5,s1
    80004eb4:	0187c783          	lbu	a5,24(a5)
    80004eb8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ebc:	4685                	li	a3,1
    80004ebe:	fbf40613          	addi	a2,s0,-65
    80004ec2:	85ca                	mv	a1,s2
    80004ec4:	050a3503          	ld	a0,80(s4)
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	79e080e7          	jalr	1950(ra) # 80001666 <copyout>
    80004ed0:	01650763          	beq	a0,s6,80004ede <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ed4:	2985                	addiw	s3,s3,1
    80004ed6:	0905                	addi	s2,s2,1
    80004ed8:	fd3a91e3          	bne	s5,s3,80004e9a <piperead+0x70>
    80004edc:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ede:	21c48513          	addi	a0,s1,540
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	292080e7          	jalr	658(ra) # 80002174 <wakeup>
  release(&pi->lock);
    80004eea:	8526                	mv	a0,s1
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	d9a080e7          	jalr	-614(ra) # 80000c86 <release>
  return i;
}
    80004ef4:	854e                	mv	a0,s3
    80004ef6:	60a6                	ld	ra,72(sp)
    80004ef8:	6406                	ld	s0,64(sp)
    80004efa:	74e2                	ld	s1,56(sp)
    80004efc:	7942                	ld	s2,48(sp)
    80004efe:	79a2                	ld	s3,40(sp)
    80004f00:	7a02                	ld	s4,32(sp)
    80004f02:	6ae2                	ld	s5,24(sp)
    80004f04:	6b42                	ld	s6,16(sp)
    80004f06:	6161                	addi	sp,sp,80
    80004f08:	8082                	ret
      release(&pi->lock);
    80004f0a:	8526                	mv	a0,s1
    80004f0c:	ffffc097          	auipc	ra,0xffffc
    80004f10:	d7a080e7          	jalr	-646(ra) # 80000c86 <release>
      return -1;
    80004f14:	59fd                	li	s3,-1
    80004f16:	bff9                	j	80004ef4 <piperead+0xca>

0000000080004f18 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f18:	1141                	addi	sp,sp,-16
    80004f1a:	e422                	sd	s0,8(sp)
    80004f1c:	0800                	addi	s0,sp,16
    80004f1e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f20:	8905                	andi	a0,a0,1
    80004f22:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004f24:	8b89                	andi	a5,a5,2
    80004f26:	c399                	beqz	a5,80004f2c <flags2perm+0x14>
      perm |= PTE_W;
    80004f28:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f2c:	6422                	ld	s0,8(sp)
    80004f2e:	0141                	addi	sp,sp,16
    80004f30:	8082                	ret

0000000080004f32 <exec>:

int
exec(char *path, char **argv)
{
    80004f32:	df010113          	addi	sp,sp,-528
    80004f36:	20113423          	sd	ra,520(sp)
    80004f3a:	20813023          	sd	s0,512(sp)
    80004f3e:	ffa6                	sd	s1,504(sp)
    80004f40:	fbca                	sd	s2,496(sp)
    80004f42:	f7ce                	sd	s3,488(sp)
    80004f44:	f3d2                	sd	s4,480(sp)
    80004f46:	efd6                	sd	s5,472(sp)
    80004f48:	ebda                	sd	s6,464(sp)
    80004f4a:	e7de                	sd	s7,456(sp)
    80004f4c:	e3e2                	sd	s8,448(sp)
    80004f4e:	ff66                	sd	s9,440(sp)
    80004f50:	fb6a                	sd	s10,432(sp)
    80004f52:	f76e                	sd	s11,424(sp)
    80004f54:	0c00                	addi	s0,sp,528
    80004f56:	892a                	mv	s2,a0
    80004f58:	dea43c23          	sd	a0,-520(s0)
    80004f5c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f60:	ffffd097          	auipc	ra,0xffffd
    80004f64:	a46080e7          	jalr	-1466(ra) # 800019a6 <myproc>
    80004f68:	84aa                	mv	s1,a0

  begin_op();
    80004f6a:	fffff097          	auipc	ra,0xfffff
    80004f6e:	48e080e7          	jalr	1166(ra) # 800043f8 <begin_op>

  if((ip = namei(path)) == 0){
    80004f72:	854a                	mv	a0,s2
    80004f74:	fffff097          	auipc	ra,0xfffff
    80004f78:	284080e7          	jalr	644(ra) # 800041f8 <namei>
    80004f7c:	c92d                	beqz	a0,80004fee <exec+0xbc>
    80004f7e:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f80:	fffff097          	auipc	ra,0xfffff
    80004f84:	ad2080e7          	jalr	-1326(ra) # 80003a52 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f88:	04000713          	li	a4,64
    80004f8c:	4681                	li	a3,0
    80004f8e:	e5040613          	addi	a2,s0,-432
    80004f92:	4581                	li	a1,0
    80004f94:	8552                	mv	a0,s4
    80004f96:	fffff097          	auipc	ra,0xfffff
    80004f9a:	d70080e7          	jalr	-656(ra) # 80003d06 <readi>
    80004f9e:	04000793          	li	a5,64
    80004fa2:	00f51a63          	bne	a0,a5,80004fb6 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004fa6:	e5042703          	lw	a4,-432(s0)
    80004faa:	464c47b7          	lui	a5,0x464c4
    80004fae:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fb2:	04f70463          	beq	a4,a5,80004ffa <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fb6:	8552                	mv	a0,s4
    80004fb8:	fffff097          	auipc	ra,0xfffff
    80004fbc:	cfc080e7          	jalr	-772(ra) # 80003cb4 <iunlockput>
    end_op();
    80004fc0:	fffff097          	auipc	ra,0xfffff
    80004fc4:	4b2080e7          	jalr	1202(ra) # 80004472 <end_op>
  }
  return -1;
    80004fc8:	557d                	li	a0,-1
}
    80004fca:	20813083          	ld	ra,520(sp)
    80004fce:	20013403          	ld	s0,512(sp)
    80004fd2:	74fe                	ld	s1,504(sp)
    80004fd4:	795e                	ld	s2,496(sp)
    80004fd6:	79be                	ld	s3,488(sp)
    80004fd8:	7a1e                	ld	s4,480(sp)
    80004fda:	6afe                	ld	s5,472(sp)
    80004fdc:	6b5e                	ld	s6,464(sp)
    80004fde:	6bbe                	ld	s7,456(sp)
    80004fe0:	6c1e                	ld	s8,448(sp)
    80004fe2:	7cfa                	ld	s9,440(sp)
    80004fe4:	7d5a                	ld	s10,432(sp)
    80004fe6:	7dba                	ld	s11,424(sp)
    80004fe8:	21010113          	addi	sp,sp,528
    80004fec:	8082                	ret
    end_op();
    80004fee:	fffff097          	auipc	ra,0xfffff
    80004ff2:	484080e7          	jalr	1156(ra) # 80004472 <end_op>
    return -1;
    80004ff6:	557d                	li	a0,-1
    80004ff8:	bfc9                	j	80004fca <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ffa:	8526                	mv	a0,s1
    80004ffc:	ffffd097          	auipc	ra,0xffffd
    80005000:	ad4080e7          	jalr	-1324(ra) # 80001ad0 <proc_pagetable>
    80005004:	8b2a                	mv	s6,a0
    80005006:	d945                	beqz	a0,80004fb6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005008:	e7042d03          	lw	s10,-400(s0)
    8000500c:	e8845783          	lhu	a5,-376(s0)
    80005010:	10078463          	beqz	a5,80005118 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005014:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005016:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005018:	6c85                	lui	s9,0x1
    8000501a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000501e:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005022:	6a85                	lui	s5,0x1
    80005024:	a0b5                	j	80005090 <exec+0x15e>
      panic("loadseg: address should exist");
    80005026:	00003517          	auipc	a0,0x3
    8000502a:	6ca50513          	addi	a0,a0,1738 # 800086f0 <syscalls+0x2a0>
    8000502e:	ffffb097          	auipc	ra,0xffffb
    80005032:	50e080e7          	jalr	1294(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005036:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005038:	8726                	mv	a4,s1
    8000503a:	012c06bb          	addw	a3,s8,s2
    8000503e:	4581                	li	a1,0
    80005040:	8552                	mv	a0,s4
    80005042:	fffff097          	auipc	ra,0xfffff
    80005046:	cc4080e7          	jalr	-828(ra) # 80003d06 <readi>
    8000504a:	2501                	sext.w	a0,a0
    8000504c:	24a49863          	bne	s1,a0,8000529c <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80005050:	012a893b          	addw	s2,s5,s2
    80005054:	03397563          	bgeu	s2,s3,8000507e <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005058:	02091593          	slli	a1,s2,0x20
    8000505c:	9181                	srli	a1,a1,0x20
    8000505e:	95de                	add	a1,a1,s7
    80005060:	855a                	mv	a0,s6
    80005062:	ffffc097          	auipc	ra,0xffffc
    80005066:	ff4080e7          	jalr	-12(ra) # 80001056 <walkaddr>
    8000506a:	862a                	mv	a2,a0
    if(pa == 0)
    8000506c:	dd4d                	beqz	a0,80005026 <exec+0xf4>
    if(sz - i < PGSIZE)
    8000506e:	412984bb          	subw	s1,s3,s2
    80005072:	0004879b          	sext.w	a5,s1
    80005076:	fcfcf0e3          	bgeu	s9,a5,80005036 <exec+0x104>
    8000507a:	84d6                	mv	s1,s5
    8000507c:	bf6d                	j	80005036 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000507e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005082:	2d85                	addiw	s11,s11,1
    80005084:	038d0d1b          	addiw	s10,s10,56
    80005088:	e8845783          	lhu	a5,-376(s0)
    8000508c:	08fdd763          	bge	s11,a5,8000511a <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005090:	2d01                	sext.w	s10,s10
    80005092:	03800713          	li	a4,56
    80005096:	86ea                	mv	a3,s10
    80005098:	e1840613          	addi	a2,s0,-488
    8000509c:	4581                	li	a1,0
    8000509e:	8552                	mv	a0,s4
    800050a0:	fffff097          	auipc	ra,0xfffff
    800050a4:	c66080e7          	jalr	-922(ra) # 80003d06 <readi>
    800050a8:	03800793          	li	a5,56
    800050ac:	1ef51663          	bne	a0,a5,80005298 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800050b0:	e1842783          	lw	a5,-488(s0)
    800050b4:	4705                	li	a4,1
    800050b6:	fce796e3          	bne	a5,a4,80005082 <exec+0x150>
    if(ph.memsz < ph.filesz)
    800050ba:	e4043483          	ld	s1,-448(s0)
    800050be:	e3843783          	ld	a5,-456(s0)
    800050c2:	1ef4e863          	bltu	s1,a5,800052b2 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050c6:	e2843783          	ld	a5,-472(s0)
    800050ca:	94be                	add	s1,s1,a5
    800050cc:	1ef4e663          	bltu	s1,a5,800052b8 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800050d0:	df043703          	ld	a4,-528(s0)
    800050d4:	8ff9                	and	a5,a5,a4
    800050d6:	1e079463          	bnez	a5,800052be <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050da:	e1c42503          	lw	a0,-484(s0)
    800050de:	00000097          	auipc	ra,0x0
    800050e2:	e3a080e7          	jalr	-454(ra) # 80004f18 <flags2perm>
    800050e6:	86aa                	mv	a3,a0
    800050e8:	8626                	mv	a2,s1
    800050ea:	85ca                	mv	a1,s2
    800050ec:	855a                	mv	a0,s6
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	31c080e7          	jalr	796(ra) # 8000140a <uvmalloc>
    800050f6:	e0a43423          	sd	a0,-504(s0)
    800050fa:	1c050563          	beqz	a0,800052c4 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050fe:	e2843b83          	ld	s7,-472(s0)
    80005102:	e2042c03          	lw	s8,-480(s0)
    80005106:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000510a:	00098463          	beqz	s3,80005112 <exec+0x1e0>
    8000510e:	4901                	li	s2,0
    80005110:	b7a1                	j	80005058 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005112:	e0843903          	ld	s2,-504(s0)
    80005116:	b7b5                	j	80005082 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005118:	4901                	li	s2,0
  iunlockput(ip);
    8000511a:	8552                	mv	a0,s4
    8000511c:	fffff097          	auipc	ra,0xfffff
    80005120:	b98080e7          	jalr	-1128(ra) # 80003cb4 <iunlockput>
  end_op();
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	34e080e7          	jalr	846(ra) # 80004472 <end_op>
  p = myproc();
    8000512c:	ffffd097          	auipc	ra,0xffffd
    80005130:	87a080e7          	jalr	-1926(ra) # 800019a6 <myproc>
    80005134:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005136:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    8000513a:	6985                	lui	s3,0x1
    8000513c:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000513e:	99ca                	add	s3,s3,s2
    80005140:	77fd                	lui	a5,0xfffff
    80005142:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005146:	4691                	li	a3,4
    80005148:	6609                	lui	a2,0x2
    8000514a:	964e                	add	a2,a2,s3
    8000514c:	85ce                	mv	a1,s3
    8000514e:	855a                	mv	a0,s6
    80005150:	ffffc097          	auipc	ra,0xffffc
    80005154:	2ba080e7          	jalr	698(ra) # 8000140a <uvmalloc>
    80005158:	892a                	mv	s2,a0
    8000515a:	e0a43423          	sd	a0,-504(s0)
    8000515e:	e509                	bnez	a0,80005168 <exec+0x236>
  if(pagetable)
    80005160:	e1343423          	sd	s3,-504(s0)
    80005164:	4a01                	li	s4,0
    80005166:	aa1d                	j	8000529c <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005168:	75f9                	lui	a1,0xffffe
    8000516a:	95aa                	add	a1,a1,a0
    8000516c:	855a                	mv	a0,s6
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	4c6080e7          	jalr	1222(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80005176:	7bfd                	lui	s7,0xfffff
    80005178:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    8000517a:	e0043783          	ld	a5,-512(s0)
    8000517e:	6388                	ld	a0,0(a5)
    80005180:	c52d                	beqz	a0,800051ea <exec+0x2b8>
    80005182:	e9040993          	addi	s3,s0,-368
    80005186:	f9040c13          	addi	s8,s0,-112
    8000518a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000518c:	ffffc097          	auipc	ra,0xffffc
    80005190:	cbc080e7          	jalr	-836(ra) # 80000e48 <strlen>
    80005194:	0015079b          	addiw	a5,a0,1
    80005198:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000519c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051a0:	13796563          	bltu	s2,s7,800052ca <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051a4:	e0043d03          	ld	s10,-512(s0)
    800051a8:	000d3a03          	ld	s4,0(s10)
    800051ac:	8552                	mv	a0,s4
    800051ae:	ffffc097          	auipc	ra,0xffffc
    800051b2:	c9a080e7          	jalr	-870(ra) # 80000e48 <strlen>
    800051b6:	0015069b          	addiw	a3,a0,1
    800051ba:	8652                	mv	a2,s4
    800051bc:	85ca                	mv	a1,s2
    800051be:	855a                	mv	a0,s6
    800051c0:	ffffc097          	auipc	ra,0xffffc
    800051c4:	4a6080e7          	jalr	1190(ra) # 80001666 <copyout>
    800051c8:	10054363          	bltz	a0,800052ce <exec+0x39c>
    ustack[argc] = sp;
    800051cc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051d0:	0485                	addi	s1,s1,1
    800051d2:	008d0793          	addi	a5,s10,8
    800051d6:	e0f43023          	sd	a5,-512(s0)
    800051da:	008d3503          	ld	a0,8(s10)
    800051de:	c909                	beqz	a0,800051f0 <exec+0x2be>
    if(argc >= MAXARG)
    800051e0:	09a1                	addi	s3,s3,8
    800051e2:	fb8995e3          	bne	s3,s8,8000518c <exec+0x25a>
  ip = 0;
    800051e6:	4a01                	li	s4,0
    800051e8:	a855                	j	8000529c <exec+0x36a>
  sp = sz;
    800051ea:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800051ee:	4481                	li	s1,0
  ustack[argc] = 0;
    800051f0:	00349793          	slli	a5,s1,0x3
    800051f4:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdc810>
    800051f8:	97a2                	add	a5,a5,s0
    800051fa:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800051fe:	00148693          	addi	a3,s1,1
    80005202:	068e                	slli	a3,a3,0x3
    80005204:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005208:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000520c:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005210:	f57968e3          	bltu	s2,s7,80005160 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005214:	e9040613          	addi	a2,s0,-368
    80005218:	85ca                	mv	a1,s2
    8000521a:	855a                	mv	a0,s6
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	44a080e7          	jalr	1098(ra) # 80001666 <copyout>
    80005224:	0a054763          	bltz	a0,800052d2 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005228:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000522c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005230:	df843783          	ld	a5,-520(s0)
    80005234:	0007c703          	lbu	a4,0(a5)
    80005238:	cf11                	beqz	a4,80005254 <exec+0x322>
    8000523a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000523c:	02f00693          	li	a3,47
    80005240:	a039                	j	8000524e <exec+0x31c>
      last = s+1;
    80005242:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005246:	0785                	addi	a5,a5,1
    80005248:	fff7c703          	lbu	a4,-1(a5)
    8000524c:	c701                	beqz	a4,80005254 <exec+0x322>
    if(*s == '/')
    8000524e:	fed71ce3          	bne	a4,a3,80005246 <exec+0x314>
    80005252:	bfc5                	j	80005242 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005254:	4641                	li	a2,16
    80005256:	df843583          	ld	a1,-520(s0)
    8000525a:	158a8513          	addi	a0,s5,344
    8000525e:	ffffc097          	auipc	ra,0xffffc
    80005262:	bb8080e7          	jalr	-1096(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005266:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000526a:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000526e:	e0843783          	ld	a5,-504(s0)
    80005272:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005276:	058ab783          	ld	a5,88(s5)
    8000527a:	e6843703          	ld	a4,-408(s0)
    8000527e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005280:	058ab783          	ld	a5,88(s5)
    80005284:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005288:	85e6                	mv	a1,s9
    8000528a:	ffffd097          	auipc	ra,0xffffd
    8000528e:	8e2080e7          	jalr	-1822(ra) # 80001b6c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005292:	0004851b          	sext.w	a0,s1
    80005296:	bb15                	j	80004fca <exec+0x98>
    80005298:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000529c:	e0843583          	ld	a1,-504(s0)
    800052a0:	855a                	mv	a0,s6
    800052a2:	ffffd097          	auipc	ra,0xffffd
    800052a6:	8ca080e7          	jalr	-1846(ra) # 80001b6c <proc_freepagetable>
  return -1;
    800052aa:	557d                	li	a0,-1
  if(ip){
    800052ac:	d00a0fe3          	beqz	s4,80004fca <exec+0x98>
    800052b0:	b319                	j	80004fb6 <exec+0x84>
    800052b2:	e1243423          	sd	s2,-504(s0)
    800052b6:	b7dd                	j	8000529c <exec+0x36a>
    800052b8:	e1243423          	sd	s2,-504(s0)
    800052bc:	b7c5                	j	8000529c <exec+0x36a>
    800052be:	e1243423          	sd	s2,-504(s0)
    800052c2:	bfe9                	j	8000529c <exec+0x36a>
    800052c4:	e1243423          	sd	s2,-504(s0)
    800052c8:	bfd1                	j	8000529c <exec+0x36a>
  ip = 0;
    800052ca:	4a01                	li	s4,0
    800052cc:	bfc1                	j	8000529c <exec+0x36a>
    800052ce:	4a01                	li	s4,0
  if(pagetable)
    800052d0:	b7f1                	j	8000529c <exec+0x36a>
  sz = sz1;
    800052d2:	e0843983          	ld	s3,-504(s0)
    800052d6:	b569                	j	80005160 <exec+0x22e>

00000000800052d8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052d8:	7179                	addi	sp,sp,-48
    800052da:	f406                	sd	ra,40(sp)
    800052dc:	f022                	sd	s0,32(sp)
    800052de:	ec26                	sd	s1,24(sp)
    800052e0:	e84a                	sd	s2,16(sp)
    800052e2:	1800                	addi	s0,sp,48
    800052e4:	892e                	mv	s2,a1
    800052e6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052e8:	fdc40593          	addi	a1,s0,-36
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	acc080e7          	jalr	-1332(ra) # 80002db8 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052f4:	fdc42703          	lw	a4,-36(s0)
    800052f8:	47bd                	li	a5,15
    800052fa:	02e7eb63          	bltu	a5,a4,80005330 <argfd+0x58>
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	6a8080e7          	jalr	1704(ra) # 800019a6 <myproc>
    80005306:	fdc42703          	lw	a4,-36(s0)
    8000530a:	01a70793          	addi	a5,a4,26
    8000530e:	078e                	slli	a5,a5,0x3
    80005310:	953e                	add	a0,a0,a5
    80005312:	611c                	ld	a5,0(a0)
    80005314:	c385                	beqz	a5,80005334 <argfd+0x5c>
    return -1;
  if(pfd)
    80005316:	00090463          	beqz	s2,8000531e <argfd+0x46>
    *pfd = fd;
    8000531a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000531e:	4501                	li	a0,0
  if(pf)
    80005320:	c091                	beqz	s1,80005324 <argfd+0x4c>
    *pf = f;
    80005322:	e09c                	sd	a5,0(s1)
}
    80005324:	70a2                	ld	ra,40(sp)
    80005326:	7402                	ld	s0,32(sp)
    80005328:	64e2                	ld	s1,24(sp)
    8000532a:	6942                	ld	s2,16(sp)
    8000532c:	6145                	addi	sp,sp,48
    8000532e:	8082                	ret
    return -1;
    80005330:	557d                	li	a0,-1
    80005332:	bfcd                	j	80005324 <argfd+0x4c>
    80005334:	557d                	li	a0,-1
    80005336:	b7fd                	j	80005324 <argfd+0x4c>

0000000080005338 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005338:	1101                	addi	sp,sp,-32
    8000533a:	ec06                	sd	ra,24(sp)
    8000533c:	e822                	sd	s0,16(sp)
    8000533e:	e426                	sd	s1,8(sp)
    80005340:	1000                	addi	s0,sp,32
    80005342:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005344:	ffffc097          	auipc	ra,0xffffc
    80005348:	662080e7          	jalr	1634(ra) # 800019a6 <myproc>
    8000534c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000534e:	0d050793          	addi	a5,a0,208
    80005352:	4501                	li	a0,0
    80005354:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005356:	6398                	ld	a4,0(a5)
    80005358:	cb19                	beqz	a4,8000536e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000535a:	2505                	addiw	a0,a0,1
    8000535c:	07a1                	addi	a5,a5,8
    8000535e:	fed51ce3          	bne	a0,a3,80005356 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005362:	557d                	li	a0,-1
}
    80005364:	60e2                	ld	ra,24(sp)
    80005366:	6442                	ld	s0,16(sp)
    80005368:	64a2                	ld	s1,8(sp)
    8000536a:	6105                	addi	sp,sp,32
    8000536c:	8082                	ret
      p->ofile[fd] = f;
    8000536e:	01a50793          	addi	a5,a0,26
    80005372:	078e                	slli	a5,a5,0x3
    80005374:	963e                	add	a2,a2,a5
    80005376:	e204                	sd	s1,0(a2)
      return fd;
    80005378:	b7f5                	j	80005364 <fdalloc+0x2c>

000000008000537a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000537a:	715d                	addi	sp,sp,-80
    8000537c:	e486                	sd	ra,72(sp)
    8000537e:	e0a2                	sd	s0,64(sp)
    80005380:	fc26                	sd	s1,56(sp)
    80005382:	f84a                	sd	s2,48(sp)
    80005384:	f44e                	sd	s3,40(sp)
    80005386:	f052                	sd	s4,32(sp)
    80005388:	ec56                	sd	s5,24(sp)
    8000538a:	e85a                	sd	s6,16(sp)
    8000538c:	0880                	addi	s0,sp,80
    8000538e:	8b2e                	mv	s6,a1
    80005390:	89b2                	mv	s3,a2
    80005392:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005394:	fb040593          	addi	a1,s0,-80
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	e7e080e7          	jalr	-386(ra) # 80004216 <nameiparent>
    800053a0:	84aa                	mv	s1,a0
    800053a2:	14050b63          	beqz	a0,800054f8 <create+0x17e>
    return 0;

  ilock(dp);
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	6ac080e7          	jalr	1708(ra) # 80003a52 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053ae:	4601                	li	a2,0
    800053b0:	fb040593          	addi	a1,s0,-80
    800053b4:	8526                	mv	a0,s1
    800053b6:	fffff097          	auipc	ra,0xfffff
    800053ba:	b80080e7          	jalr	-1152(ra) # 80003f36 <dirlookup>
    800053be:	8aaa                	mv	s5,a0
    800053c0:	c921                	beqz	a0,80005410 <create+0x96>
    iunlockput(dp);
    800053c2:	8526                	mv	a0,s1
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	8f0080e7          	jalr	-1808(ra) # 80003cb4 <iunlockput>
    ilock(ip);
    800053cc:	8556                	mv	a0,s5
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	684080e7          	jalr	1668(ra) # 80003a52 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053d6:	4789                	li	a5,2
    800053d8:	02fb1563          	bne	s6,a5,80005402 <create+0x88>
    800053dc:	044ad783          	lhu	a5,68(s5)
    800053e0:	37f9                	addiw	a5,a5,-2
    800053e2:	17c2                	slli	a5,a5,0x30
    800053e4:	93c1                	srli	a5,a5,0x30
    800053e6:	4705                	li	a4,1
    800053e8:	00f76d63          	bltu	a4,a5,80005402 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053ec:	8556                	mv	a0,s5
    800053ee:	60a6                	ld	ra,72(sp)
    800053f0:	6406                	ld	s0,64(sp)
    800053f2:	74e2                	ld	s1,56(sp)
    800053f4:	7942                	ld	s2,48(sp)
    800053f6:	79a2                	ld	s3,40(sp)
    800053f8:	7a02                	ld	s4,32(sp)
    800053fa:	6ae2                	ld	s5,24(sp)
    800053fc:	6b42                	ld	s6,16(sp)
    800053fe:	6161                	addi	sp,sp,80
    80005400:	8082                	ret
    iunlockput(ip);
    80005402:	8556                	mv	a0,s5
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	8b0080e7          	jalr	-1872(ra) # 80003cb4 <iunlockput>
    return 0;
    8000540c:	4a81                	li	s5,0
    8000540e:	bff9                	j	800053ec <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005410:	85da                	mv	a1,s6
    80005412:	4088                	lw	a0,0(s1)
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	4a6080e7          	jalr	1190(ra) # 800038ba <ialloc>
    8000541c:	8a2a                	mv	s4,a0
    8000541e:	c529                	beqz	a0,80005468 <create+0xee>
  ilock(ip);
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	632080e7          	jalr	1586(ra) # 80003a52 <ilock>
  ip->major = major;
    80005428:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000542c:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005430:	4905                	li	s2,1
    80005432:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005436:	8552                	mv	a0,s4
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	54e080e7          	jalr	1358(ra) # 80003986 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005440:	032b0b63          	beq	s6,s2,80005476 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005444:	004a2603          	lw	a2,4(s4)
    80005448:	fb040593          	addi	a1,s0,-80
    8000544c:	8526                	mv	a0,s1
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	cf8080e7          	jalr	-776(ra) # 80004146 <dirlink>
    80005456:	06054f63          	bltz	a0,800054d4 <create+0x15a>
  iunlockput(dp);
    8000545a:	8526                	mv	a0,s1
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	858080e7          	jalr	-1960(ra) # 80003cb4 <iunlockput>
  return ip;
    80005464:	8ad2                	mv	s5,s4
    80005466:	b759                	j	800053ec <create+0x72>
    iunlockput(dp);
    80005468:	8526                	mv	a0,s1
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	84a080e7          	jalr	-1974(ra) # 80003cb4 <iunlockput>
    return 0;
    80005472:	8ad2                	mv	s5,s4
    80005474:	bfa5                	j	800053ec <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005476:	004a2603          	lw	a2,4(s4)
    8000547a:	00003597          	auipc	a1,0x3
    8000547e:	29658593          	addi	a1,a1,662 # 80008710 <syscalls+0x2c0>
    80005482:	8552                	mv	a0,s4
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	cc2080e7          	jalr	-830(ra) # 80004146 <dirlink>
    8000548c:	04054463          	bltz	a0,800054d4 <create+0x15a>
    80005490:	40d0                	lw	a2,4(s1)
    80005492:	00003597          	auipc	a1,0x3
    80005496:	28658593          	addi	a1,a1,646 # 80008718 <syscalls+0x2c8>
    8000549a:	8552                	mv	a0,s4
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	caa080e7          	jalr	-854(ra) # 80004146 <dirlink>
    800054a4:	02054863          	bltz	a0,800054d4 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800054a8:	004a2603          	lw	a2,4(s4)
    800054ac:	fb040593          	addi	a1,s0,-80
    800054b0:	8526                	mv	a0,s1
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	c94080e7          	jalr	-876(ra) # 80004146 <dirlink>
    800054ba:	00054d63          	bltz	a0,800054d4 <create+0x15a>
    dp->nlink++;  // for ".."
    800054be:	04a4d783          	lhu	a5,74(s1)
    800054c2:	2785                	addiw	a5,a5,1
    800054c4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054c8:	8526                	mv	a0,s1
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	4bc080e7          	jalr	1212(ra) # 80003986 <iupdate>
    800054d2:	b761                	j	8000545a <create+0xe0>
  ip->nlink = 0;
    800054d4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054d8:	8552                	mv	a0,s4
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	4ac080e7          	jalr	1196(ra) # 80003986 <iupdate>
  iunlockput(ip);
    800054e2:	8552                	mv	a0,s4
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	7d0080e7          	jalr	2000(ra) # 80003cb4 <iunlockput>
  iunlockput(dp);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	7c6080e7          	jalr	1990(ra) # 80003cb4 <iunlockput>
  return 0;
    800054f6:	bddd                	j	800053ec <create+0x72>
    return 0;
    800054f8:	8aaa                	mv	s5,a0
    800054fa:	bdcd                	j	800053ec <create+0x72>

00000000800054fc <sys_dup>:
{
    800054fc:	7179                	addi	sp,sp,-48
    800054fe:	f406                	sd	ra,40(sp)
    80005500:	f022                	sd	s0,32(sp)
    80005502:	ec26                	sd	s1,24(sp)
    80005504:	e84a                	sd	s2,16(sp)
    80005506:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005508:	fd840613          	addi	a2,s0,-40
    8000550c:	4581                	li	a1,0
    8000550e:	4501                	li	a0,0
    80005510:	00000097          	auipc	ra,0x0
    80005514:	dc8080e7          	jalr	-568(ra) # 800052d8 <argfd>
    return -1;
    80005518:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000551a:	02054363          	bltz	a0,80005540 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000551e:	fd843903          	ld	s2,-40(s0)
    80005522:	854a                	mv	a0,s2
    80005524:	00000097          	auipc	ra,0x0
    80005528:	e14080e7          	jalr	-492(ra) # 80005338 <fdalloc>
    8000552c:	84aa                	mv	s1,a0
    return -1;
    8000552e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005530:	00054863          	bltz	a0,80005540 <sys_dup+0x44>
  filedup(f);
    80005534:	854a                	mv	a0,s2
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	334080e7          	jalr	820(ra) # 8000486a <filedup>
  return fd;
    8000553e:	87a6                	mv	a5,s1
}
    80005540:	853e                	mv	a0,a5
    80005542:	70a2                	ld	ra,40(sp)
    80005544:	7402                	ld	s0,32(sp)
    80005546:	64e2                	ld	s1,24(sp)
    80005548:	6942                	ld	s2,16(sp)
    8000554a:	6145                	addi	sp,sp,48
    8000554c:	8082                	ret

000000008000554e <sys_read>:
{
    8000554e:	7179                	addi	sp,sp,-48
    80005550:	f406                	sd	ra,40(sp)
    80005552:	f022                	sd	s0,32(sp)
    80005554:	1800                	addi	s0,sp,48
  READCOUNT++;
    80005556:	00003717          	auipc	a4,0x3
    8000555a:	3b270713          	addi	a4,a4,946 # 80008908 <READCOUNT>
    8000555e:	631c                	ld	a5,0(a4)
    80005560:	0785                	addi	a5,a5,1
    80005562:	e31c                	sd	a5,0(a4)
  argaddr(1, &p);
    80005564:	fd840593          	addi	a1,s0,-40
    80005568:	4505                	li	a0,1
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	86e080e7          	jalr	-1938(ra) # 80002dd8 <argaddr>
  argint(2, &n);
    80005572:	fe440593          	addi	a1,s0,-28
    80005576:	4509                	li	a0,2
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	840080e7          	jalr	-1984(ra) # 80002db8 <argint>
  if(argfd(0, 0, &f) < 0)
    80005580:	fe840613          	addi	a2,s0,-24
    80005584:	4581                	li	a1,0
    80005586:	4501                	li	a0,0
    80005588:	00000097          	auipc	ra,0x0
    8000558c:	d50080e7          	jalr	-688(ra) # 800052d8 <argfd>
    80005590:	87aa                	mv	a5,a0
    return -1;
    80005592:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005594:	0007cc63          	bltz	a5,800055ac <sys_read+0x5e>
  return fileread(f, p, n);
    80005598:	fe442603          	lw	a2,-28(s0)
    8000559c:	fd843583          	ld	a1,-40(s0)
    800055a0:	fe843503          	ld	a0,-24(s0)
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	452080e7          	jalr	1106(ra) # 800049f6 <fileread>
}
    800055ac:	70a2                	ld	ra,40(sp)
    800055ae:	7402                	ld	s0,32(sp)
    800055b0:	6145                	addi	sp,sp,48
    800055b2:	8082                	ret

00000000800055b4 <sys_write>:
{
    800055b4:	7179                	addi	sp,sp,-48
    800055b6:	f406                	sd	ra,40(sp)
    800055b8:	f022                	sd	s0,32(sp)
    800055ba:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055bc:	fd840593          	addi	a1,s0,-40
    800055c0:	4505                	li	a0,1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	816080e7          	jalr	-2026(ra) # 80002dd8 <argaddr>
  argint(2, &n);
    800055ca:	fe440593          	addi	a1,s0,-28
    800055ce:	4509                	li	a0,2
    800055d0:	ffffd097          	auipc	ra,0xffffd
    800055d4:	7e8080e7          	jalr	2024(ra) # 80002db8 <argint>
  if(argfd(0, 0, &f) < 0)
    800055d8:	fe840613          	addi	a2,s0,-24
    800055dc:	4581                	li	a1,0
    800055de:	4501                	li	a0,0
    800055e0:	00000097          	auipc	ra,0x0
    800055e4:	cf8080e7          	jalr	-776(ra) # 800052d8 <argfd>
    800055e8:	87aa                	mv	a5,a0
    return -1;
    800055ea:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055ec:	0007cc63          	bltz	a5,80005604 <sys_write+0x50>
  return filewrite(f, p, n);
    800055f0:	fe442603          	lw	a2,-28(s0)
    800055f4:	fd843583          	ld	a1,-40(s0)
    800055f8:	fe843503          	ld	a0,-24(s0)
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	4bc080e7          	jalr	1212(ra) # 80004ab8 <filewrite>
}
    80005604:	70a2                	ld	ra,40(sp)
    80005606:	7402                	ld	s0,32(sp)
    80005608:	6145                	addi	sp,sp,48
    8000560a:	8082                	ret

000000008000560c <sys_close>:
{
    8000560c:	1101                	addi	sp,sp,-32
    8000560e:	ec06                	sd	ra,24(sp)
    80005610:	e822                	sd	s0,16(sp)
    80005612:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005614:	fe040613          	addi	a2,s0,-32
    80005618:	fec40593          	addi	a1,s0,-20
    8000561c:	4501                	li	a0,0
    8000561e:	00000097          	auipc	ra,0x0
    80005622:	cba080e7          	jalr	-838(ra) # 800052d8 <argfd>
    return -1;
    80005626:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005628:	02054463          	bltz	a0,80005650 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000562c:	ffffc097          	auipc	ra,0xffffc
    80005630:	37a080e7          	jalr	890(ra) # 800019a6 <myproc>
    80005634:	fec42783          	lw	a5,-20(s0)
    80005638:	07e9                	addi	a5,a5,26
    8000563a:	078e                	slli	a5,a5,0x3
    8000563c:	953e                	add	a0,a0,a5
    8000563e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005642:	fe043503          	ld	a0,-32(s0)
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	276080e7          	jalr	630(ra) # 800048bc <fileclose>
  return 0;
    8000564e:	4781                	li	a5,0
}
    80005650:	853e                	mv	a0,a5
    80005652:	60e2                	ld	ra,24(sp)
    80005654:	6442                	ld	s0,16(sp)
    80005656:	6105                	addi	sp,sp,32
    80005658:	8082                	ret

000000008000565a <sys_fstat>:
{
    8000565a:	1101                	addi	sp,sp,-32
    8000565c:	ec06                	sd	ra,24(sp)
    8000565e:	e822                	sd	s0,16(sp)
    80005660:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005662:	fe040593          	addi	a1,s0,-32
    80005666:	4505                	li	a0,1
    80005668:	ffffd097          	auipc	ra,0xffffd
    8000566c:	770080e7          	jalr	1904(ra) # 80002dd8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005670:	fe840613          	addi	a2,s0,-24
    80005674:	4581                	li	a1,0
    80005676:	4501                	li	a0,0
    80005678:	00000097          	auipc	ra,0x0
    8000567c:	c60080e7          	jalr	-928(ra) # 800052d8 <argfd>
    80005680:	87aa                	mv	a5,a0
    return -1;
    80005682:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005684:	0007ca63          	bltz	a5,80005698 <sys_fstat+0x3e>
  return filestat(f, st);
    80005688:	fe043583          	ld	a1,-32(s0)
    8000568c:	fe843503          	ld	a0,-24(s0)
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	2f4080e7          	jalr	756(ra) # 80004984 <filestat>
}
    80005698:	60e2                	ld	ra,24(sp)
    8000569a:	6442                	ld	s0,16(sp)
    8000569c:	6105                	addi	sp,sp,32
    8000569e:	8082                	ret

00000000800056a0 <sys_link>:
{
    800056a0:	7169                	addi	sp,sp,-304
    800056a2:	f606                	sd	ra,296(sp)
    800056a4:	f222                	sd	s0,288(sp)
    800056a6:	ee26                	sd	s1,280(sp)
    800056a8:	ea4a                	sd	s2,272(sp)
    800056aa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056ac:	08000613          	li	a2,128
    800056b0:	ed040593          	addi	a1,s0,-304
    800056b4:	4501                	li	a0,0
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	742080e7          	jalr	1858(ra) # 80002df8 <argstr>
    return -1;
    800056be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056c0:	10054e63          	bltz	a0,800057dc <sys_link+0x13c>
    800056c4:	08000613          	li	a2,128
    800056c8:	f5040593          	addi	a1,s0,-176
    800056cc:	4505                	li	a0,1
    800056ce:	ffffd097          	auipc	ra,0xffffd
    800056d2:	72a080e7          	jalr	1834(ra) # 80002df8 <argstr>
    return -1;
    800056d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056d8:	10054263          	bltz	a0,800057dc <sys_link+0x13c>
  begin_op();
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	d1c080e7          	jalr	-740(ra) # 800043f8 <begin_op>
  if((ip = namei(old)) == 0){
    800056e4:	ed040513          	addi	a0,s0,-304
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	b10080e7          	jalr	-1264(ra) # 800041f8 <namei>
    800056f0:	84aa                	mv	s1,a0
    800056f2:	c551                	beqz	a0,8000577e <sys_link+0xde>
  ilock(ip);
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	35e080e7          	jalr	862(ra) # 80003a52 <ilock>
  if(ip->type == T_DIR){
    800056fc:	04449703          	lh	a4,68(s1)
    80005700:	4785                	li	a5,1
    80005702:	08f70463          	beq	a4,a5,8000578a <sys_link+0xea>
  ip->nlink++;
    80005706:	04a4d783          	lhu	a5,74(s1)
    8000570a:	2785                	addiw	a5,a5,1
    8000570c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005710:	8526                	mv	a0,s1
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	274080e7          	jalr	628(ra) # 80003986 <iupdate>
  iunlock(ip);
    8000571a:	8526                	mv	a0,s1
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	3f8080e7          	jalr	1016(ra) # 80003b14 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005724:	fd040593          	addi	a1,s0,-48
    80005728:	f5040513          	addi	a0,s0,-176
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	aea080e7          	jalr	-1302(ra) # 80004216 <nameiparent>
    80005734:	892a                	mv	s2,a0
    80005736:	c935                	beqz	a0,800057aa <sys_link+0x10a>
  ilock(dp);
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	31a080e7          	jalr	794(ra) # 80003a52 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005740:	00092703          	lw	a4,0(s2)
    80005744:	409c                	lw	a5,0(s1)
    80005746:	04f71d63          	bne	a4,a5,800057a0 <sys_link+0x100>
    8000574a:	40d0                	lw	a2,4(s1)
    8000574c:	fd040593          	addi	a1,s0,-48
    80005750:	854a                	mv	a0,s2
    80005752:	fffff097          	auipc	ra,0xfffff
    80005756:	9f4080e7          	jalr	-1548(ra) # 80004146 <dirlink>
    8000575a:	04054363          	bltz	a0,800057a0 <sys_link+0x100>
  iunlockput(dp);
    8000575e:	854a                	mv	a0,s2
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	554080e7          	jalr	1364(ra) # 80003cb4 <iunlockput>
  iput(ip);
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	4a2080e7          	jalr	1186(ra) # 80003c0c <iput>
  end_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	d00080e7          	jalr	-768(ra) # 80004472 <end_op>
  return 0;
    8000577a:	4781                	li	a5,0
    8000577c:	a085                	j	800057dc <sys_link+0x13c>
    end_op();
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	cf4080e7          	jalr	-780(ra) # 80004472 <end_op>
    return -1;
    80005786:	57fd                	li	a5,-1
    80005788:	a891                	j	800057dc <sys_link+0x13c>
    iunlockput(ip);
    8000578a:	8526                	mv	a0,s1
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	528080e7          	jalr	1320(ra) # 80003cb4 <iunlockput>
    end_op();
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	cde080e7          	jalr	-802(ra) # 80004472 <end_op>
    return -1;
    8000579c:	57fd                	li	a5,-1
    8000579e:	a83d                	j	800057dc <sys_link+0x13c>
    iunlockput(dp);
    800057a0:	854a                	mv	a0,s2
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	512080e7          	jalr	1298(ra) # 80003cb4 <iunlockput>
  ilock(ip);
    800057aa:	8526                	mv	a0,s1
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	2a6080e7          	jalr	678(ra) # 80003a52 <ilock>
  ip->nlink--;
    800057b4:	04a4d783          	lhu	a5,74(s1)
    800057b8:	37fd                	addiw	a5,a5,-1
    800057ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057be:	8526                	mv	a0,s1
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	1c6080e7          	jalr	454(ra) # 80003986 <iupdate>
  iunlockput(ip);
    800057c8:	8526                	mv	a0,s1
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	4ea080e7          	jalr	1258(ra) # 80003cb4 <iunlockput>
  end_op();
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	ca0080e7          	jalr	-864(ra) # 80004472 <end_op>
  return -1;
    800057da:	57fd                	li	a5,-1
}
    800057dc:	853e                	mv	a0,a5
    800057de:	70b2                	ld	ra,296(sp)
    800057e0:	7412                	ld	s0,288(sp)
    800057e2:	64f2                	ld	s1,280(sp)
    800057e4:	6952                	ld	s2,272(sp)
    800057e6:	6155                	addi	sp,sp,304
    800057e8:	8082                	ret

00000000800057ea <sys_unlink>:
{
    800057ea:	7151                	addi	sp,sp,-240
    800057ec:	f586                	sd	ra,232(sp)
    800057ee:	f1a2                	sd	s0,224(sp)
    800057f0:	eda6                	sd	s1,216(sp)
    800057f2:	e9ca                	sd	s2,208(sp)
    800057f4:	e5ce                	sd	s3,200(sp)
    800057f6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057f8:	08000613          	li	a2,128
    800057fc:	f3040593          	addi	a1,s0,-208
    80005800:	4501                	li	a0,0
    80005802:	ffffd097          	auipc	ra,0xffffd
    80005806:	5f6080e7          	jalr	1526(ra) # 80002df8 <argstr>
    8000580a:	18054163          	bltz	a0,8000598c <sys_unlink+0x1a2>
  begin_op();
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	bea080e7          	jalr	-1046(ra) # 800043f8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005816:	fb040593          	addi	a1,s0,-80
    8000581a:	f3040513          	addi	a0,s0,-208
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	9f8080e7          	jalr	-1544(ra) # 80004216 <nameiparent>
    80005826:	84aa                	mv	s1,a0
    80005828:	c979                	beqz	a0,800058fe <sys_unlink+0x114>
  ilock(dp);
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	228080e7          	jalr	552(ra) # 80003a52 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005832:	00003597          	auipc	a1,0x3
    80005836:	ede58593          	addi	a1,a1,-290 # 80008710 <syscalls+0x2c0>
    8000583a:	fb040513          	addi	a0,s0,-80
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	6de080e7          	jalr	1758(ra) # 80003f1c <namecmp>
    80005846:	14050a63          	beqz	a0,8000599a <sys_unlink+0x1b0>
    8000584a:	00003597          	auipc	a1,0x3
    8000584e:	ece58593          	addi	a1,a1,-306 # 80008718 <syscalls+0x2c8>
    80005852:	fb040513          	addi	a0,s0,-80
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	6c6080e7          	jalr	1734(ra) # 80003f1c <namecmp>
    8000585e:	12050e63          	beqz	a0,8000599a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005862:	f2c40613          	addi	a2,s0,-212
    80005866:	fb040593          	addi	a1,s0,-80
    8000586a:	8526                	mv	a0,s1
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	6ca080e7          	jalr	1738(ra) # 80003f36 <dirlookup>
    80005874:	892a                	mv	s2,a0
    80005876:	12050263          	beqz	a0,8000599a <sys_unlink+0x1b0>
  ilock(ip);
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	1d8080e7          	jalr	472(ra) # 80003a52 <ilock>
  if(ip->nlink < 1)
    80005882:	04a91783          	lh	a5,74(s2)
    80005886:	08f05263          	blez	a5,8000590a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000588a:	04491703          	lh	a4,68(s2)
    8000588e:	4785                	li	a5,1
    80005890:	08f70563          	beq	a4,a5,8000591a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005894:	4641                	li	a2,16
    80005896:	4581                	li	a1,0
    80005898:	fc040513          	addi	a0,s0,-64
    8000589c:	ffffb097          	auipc	ra,0xffffb
    800058a0:	432080e7          	jalr	1074(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058a4:	4741                	li	a4,16
    800058a6:	f2c42683          	lw	a3,-212(s0)
    800058aa:	fc040613          	addi	a2,s0,-64
    800058ae:	4581                	li	a1,0
    800058b0:	8526                	mv	a0,s1
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	54c080e7          	jalr	1356(ra) # 80003dfe <writei>
    800058ba:	47c1                	li	a5,16
    800058bc:	0af51563          	bne	a0,a5,80005966 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058c0:	04491703          	lh	a4,68(s2)
    800058c4:	4785                	li	a5,1
    800058c6:	0af70863          	beq	a4,a5,80005976 <sys_unlink+0x18c>
  iunlockput(dp);
    800058ca:	8526                	mv	a0,s1
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	3e8080e7          	jalr	1000(ra) # 80003cb4 <iunlockput>
  ip->nlink--;
    800058d4:	04a95783          	lhu	a5,74(s2)
    800058d8:	37fd                	addiw	a5,a5,-1
    800058da:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058de:	854a                	mv	a0,s2
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	0a6080e7          	jalr	166(ra) # 80003986 <iupdate>
  iunlockput(ip);
    800058e8:	854a                	mv	a0,s2
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	3ca080e7          	jalr	970(ra) # 80003cb4 <iunlockput>
  end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	b80080e7          	jalr	-1152(ra) # 80004472 <end_op>
  return 0;
    800058fa:	4501                	li	a0,0
    800058fc:	a84d                	j	800059ae <sys_unlink+0x1c4>
    end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	b74080e7          	jalr	-1164(ra) # 80004472 <end_op>
    return -1;
    80005906:	557d                	li	a0,-1
    80005908:	a05d                	j	800059ae <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000590a:	00003517          	auipc	a0,0x3
    8000590e:	e1650513          	addi	a0,a0,-490 # 80008720 <syscalls+0x2d0>
    80005912:	ffffb097          	auipc	ra,0xffffb
    80005916:	c2a080e7          	jalr	-982(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000591a:	04c92703          	lw	a4,76(s2)
    8000591e:	02000793          	li	a5,32
    80005922:	f6e7f9e3          	bgeu	a5,a4,80005894 <sys_unlink+0xaa>
    80005926:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000592a:	4741                	li	a4,16
    8000592c:	86ce                	mv	a3,s3
    8000592e:	f1840613          	addi	a2,s0,-232
    80005932:	4581                	li	a1,0
    80005934:	854a                	mv	a0,s2
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	3d0080e7          	jalr	976(ra) # 80003d06 <readi>
    8000593e:	47c1                	li	a5,16
    80005940:	00f51b63          	bne	a0,a5,80005956 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005944:	f1845783          	lhu	a5,-232(s0)
    80005948:	e7a1                	bnez	a5,80005990 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000594a:	29c1                	addiw	s3,s3,16
    8000594c:	04c92783          	lw	a5,76(s2)
    80005950:	fcf9ede3          	bltu	s3,a5,8000592a <sys_unlink+0x140>
    80005954:	b781                	j	80005894 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005956:	00003517          	auipc	a0,0x3
    8000595a:	de250513          	addi	a0,a0,-542 # 80008738 <syscalls+0x2e8>
    8000595e:	ffffb097          	auipc	ra,0xffffb
    80005962:	bde080e7          	jalr	-1058(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005966:	00003517          	auipc	a0,0x3
    8000596a:	dea50513          	addi	a0,a0,-534 # 80008750 <syscalls+0x300>
    8000596e:	ffffb097          	auipc	ra,0xffffb
    80005972:	bce080e7          	jalr	-1074(ra) # 8000053c <panic>
    dp->nlink--;
    80005976:	04a4d783          	lhu	a5,74(s1)
    8000597a:	37fd                	addiw	a5,a5,-1
    8000597c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005980:	8526                	mv	a0,s1
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	004080e7          	jalr	4(ra) # 80003986 <iupdate>
    8000598a:	b781                	j	800058ca <sys_unlink+0xe0>
    return -1;
    8000598c:	557d                	li	a0,-1
    8000598e:	a005                	j	800059ae <sys_unlink+0x1c4>
    iunlockput(ip);
    80005990:	854a                	mv	a0,s2
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	322080e7          	jalr	802(ra) # 80003cb4 <iunlockput>
  iunlockput(dp);
    8000599a:	8526                	mv	a0,s1
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	318080e7          	jalr	792(ra) # 80003cb4 <iunlockput>
  end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	ace080e7          	jalr	-1330(ra) # 80004472 <end_op>
  return -1;
    800059ac:	557d                	li	a0,-1
}
    800059ae:	70ae                	ld	ra,232(sp)
    800059b0:	740e                	ld	s0,224(sp)
    800059b2:	64ee                	ld	s1,216(sp)
    800059b4:	694e                	ld	s2,208(sp)
    800059b6:	69ae                	ld	s3,200(sp)
    800059b8:	616d                	addi	sp,sp,240
    800059ba:	8082                	ret

00000000800059bc <sys_open>:

uint64
sys_open(void)
{
    800059bc:	7131                	addi	sp,sp,-192
    800059be:	fd06                	sd	ra,184(sp)
    800059c0:	f922                	sd	s0,176(sp)
    800059c2:	f526                	sd	s1,168(sp)
    800059c4:	f14a                	sd	s2,160(sp)
    800059c6:	ed4e                	sd	s3,152(sp)
    800059c8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059ca:	f4c40593          	addi	a1,s0,-180
    800059ce:	4505                	li	a0,1
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	3e8080e7          	jalr	1000(ra) # 80002db8 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059d8:	08000613          	li	a2,128
    800059dc:	f5040593          	addi	a1,s0,-176
    800059e0:	4501                	li	a0,0
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	416080e7          	jalr	1046(ra) # 80002df8 <argstr>
    800059ea:	87aa                	mv	a5,a0
    return -1;
    800059ec:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059ee:	0a07c863          	bltz	a5,80005a9e <sys_open+0xe2>

  begin_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	a06080e7          	jalr	-1530(ra) # 800043f8 <begin_op>

  if(omode & O_CREATE){
    800059fa:	f4c42783          	lw	a5,-180(s0)
    800059fe:	2007f793          	andi	a5,a5,512
    80005a02:	cbdd                	beqz	a5,80005ab8 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005a04:	4681                	li	a3,0
    80005a06:	4601                	li	a2,0
    80005a08:	4589                	li	a1,2
    80005a0a:	f5040513          	addi	a0,s0,-176
    80005a0e:	00000097          	auipc	ra,0x0
    80005a12:	96c080e7          	jalr	-1684(ra) # 8000537a <create>
    80005a16:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a18:	c951                	beqz	a0,80005aac <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a1a:	04449703          	lh	a4,68(s1)
    80005a1e:	478d                	li	a5,3
    80005a20:	00f71763          	bne	a4,a5,80005a2e <sys_open+0x72>
    80005a24:	0464d703          	lhu	a4,70(s1)
    80005a28:	47a5                	li	a5,9
    80005a2a:	0ce7ec63          	bltu	a5,a4,80005b02 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	dd2080e7          	jalr	-558(ra) # 80004800 <filealloc>
    80005a36:	892a                	mv	s2,a0
    80005a38:	c56d                	beqz	a0,80005b22 <sys_open+0x166>
    80005a3a:	00000097          	auipc	ra,0x0
    80005a3e:	8fe080e7          	jalr	-1794(ra) # 80005338 <fdalloc>
    80005a42:	89aa                	mv	s3,a0
    80005a44:	0c054a63          	bltz	a0,80005b18 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a48:	04449703          	lh	a4,68(s1)
    80005a4c:	478d                	li	a5,3
    80005a4e:	0ef70563          	beq	a4,a5,80005b38 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a52:	4789                	li	a5,2
    80005a54:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005a58:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005a5c:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005a60:	f4c42783          	lw	a5,-180(s0)
    80005a64:	0017c713          	xori	a4,a5,1
    80005a68:	8b05                	andi	a4,a4,1
    80005a6a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a6e:	0037f713          	andi	a4,a5,3
    80005a72:	00e03733          	snez	a4,a4
    80005a76:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a7a:	4007f793          	andi	a5,a5,1024
    80005a7e:	c791                	beqz	a5,80005a8a <sys_open+0xce>
    80005a80:	04449703          	lh	a4,68(s1)
    80005a84:	4789                	li	a5,2
    80005a86:	0cf70063          	beq	a4,a5,80005b46 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	088080e7          	jalr	136(ra) # 80003b14 <iunlock>
  end_op();
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	9de080e7          	jalr	-1570(ra) # 80004472 <end_op>

  return fd;
    80005a9c:	854e                	mv	a0,s3
}
    80005a9e:	70ea                	ld	ra,184(sp)
    80005aa0:	744a                	ld	s0,176(sp)
    80005aa2:	74aa                	ld	s1,168(sp)
    80005aa4:	790a                	ld	s2,160(sp)
    80005aa6:	69ea                	ld	s3,152(sp)
    80005aa8:	6129                	addi	sp,sp,192
    80005aaa:	8082                	ret
      end_op();
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	9c6080e7          	jalr	-1594(ra) # 80004472 <end_op>
      return -1;
    80005ab4:	557d                	li	a0,-1
    80005ab6:	b7e5                	j	80005a9e <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005ab8:	f5040513          	addi	a0,s0,-176
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	73c080e7          	jalr	1852(ra) # 800041f8 <namei>
    80005ac4:	84aa                	mv	s1,a0
    80005ac6:	c905                	beqz	a0,80005af6 <sys_open+0x13a>
    ilock(ip);
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	f8a080e7          	jalr	-118(ra) # 80003a52 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ad0:	04449703          	lh	a4,68(s1)
    80005ad4:	4785                	li	a5,1
    80005ad6:	f4f712e3          	bne	a4,a5,80005a1a <sys_open+0x5e>
    80005ada:	f4c42783          	lw	a5,-180(s0)
    80005ade:	dba1                	beqz	a5,80005a2e <sys_open+0x72>
      iunlockput(ip);
    80005ae0:	8526                	mv	a0,s1
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	1d2080e7          	jalr	466(ra) # 80003cb4 <iunlockput>
      end_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	988080e7          	jalr	-1656(ra) # 80004472 <end_op>
      return -1;
    80005af2:	557d                	li	a0,-1
    80005af4:	b76d                	j	80005a9e <sys_open+0xe2>
      end_op();
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	97c080e7          	jalr	-1668(ra) # 80004472 <end_op>
      return -1;
    80005afe:	557d                	li	a0,-1
    80005b00:	bf79                	j	80005a9e <sys_open+0xe2>
    iunlockput(ip);
    80005b02:	8526                	mv	a0,s1
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	1b0080e7          	jalr	432(ra) # 80003cb4 <iunlockput>
    end_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	966080e7          	jalr	-1690(ra) # 80004472 <end_op>
    return -1;
    80005b14:	557d                	li	a0,-1
    80005b16:	b761                	j	80005a9e <sys_open+0xe2>
      fileclose(f);
    80005b18:	854a                	mv	a0,s2
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	da2080e7          	jalr	-606(ra) # 800048bc <fileclose>
    iunlockput(ip);
    80005b22:	8526                	mv	a0,s1
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	190080e7          	jalr	400(ra) # 80003cb4 <iunlockput>
    end_op();
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	946080e7          	jalr	-1722(ra) # 80004472 <end_op>
    return -1;
    80005b34:	557d                	li	a0,-1
    80005b36:	b7a5                	j	80005a9e <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005b38:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005b3c:	04649783          	lh	a5,70(s1)
    80005b40:	02f91223          	sh	a5,36(s2)
    80005b44:	bf21                	j	80005a5c <sys_open+0xa0>
    itrunc(ip);
    80005b46:	8526                	mv	a0,s1
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	018080e7          	jalr	24(ra) # 80003b60 <itrunc>
    80005b50:	bf2d                	j	80005a8a <sys_open+0xce>

0000000080005b52 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b52:	7175                	addi	sp,sp,-144
    80005b54:	e506                	sd	ra,136(sp)
    80005b56:	e122                	sd	s0,128(sp)
    80005b58:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	89e080e7          	jalr	-1890(ra) # 800043f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b62:	08000613          	li	a2,128
    80005b66:	f7040593          	addi	a1,s0,-144
    80005b6a:	4501                	li	a0,0
    80005b6c:	ffffd097          	auipc	ra,0xffffd
    80005b70:	28c080e7          	jalr	652(ra) # 80002df8 <argstr>
    80005b74:	02054963          	bltz	a0,80005ba6 <sys_mkdir+0x54>
    80005b78:	4681                	li	a3,0
    80005b7a:	4601                	li	a2,0
    80005b7c:	4585                	li	a1,1
    80005b7e:	f7040513          	addi	a0,s0,-144
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	7f8080e7          	jalr	2040(ra) # 8000537a <create>
    80005b8a:	cd11                	beqz	a0,80005ba6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	128080e7          	jalr	296(ra) # 80003cb4 <iunlockput>
  end_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	8de080e7          	jalr	-1826(ra) # 80004472 <end_op>
  return 0;
    80005b9c:	4501                	li	a0,0
}
    80005b9e:	60aa                	ld	ra,136(sp)
    80005ba0:	640a                	ld	s0,128(sp)
    80005ba2:	6149                	addi	sp,sp,144
    80005ba4:	8082                	ret
    end_op();
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	8cc080e7          	jalr	-1844(ra) # 80004472 <end_op>
    return -1;
    80005bae:	557d                	li	a0,-1
    80005bb0:	b7fd                	j	80005b9e <sys_mkdir+0x4c>

0000000080005bb2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bb2:	7135                	addi	sp,sp,-160
    80005bb4:	ed06                	sd	ra,152(sp)
    80005bb6:	e922                	sd	s0,144(sp)
    80005bb8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	83e080e7          	jalr	-1986(ra) # 800043f8 <begin_op>
  argint(1, &major);
    80005bc2:	f6c40593          	addi	a1,s0,-148
    80005bc6:	4505                	li	a0,1
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	1f0080e7          	jalr	496(ra) # 80002db8 <argint>
  argint(2, &minor);
    80005bd0:	f6840593          	addi	a1,s0,-152
    80005bd4:	4509                	li	a0,2
    80005bd6:	ffffd097          	auipc	ra,0xffffd
    80005bda:	1e2080e7          	jalr	482(ra) # 80002db8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bde:	08000613          	li	a2,128
    80005be2:	f7040593          	addi	a1,s0,-144
    80005be6:	4501                	li	a0,0
    80005be8:	ffffd097          	auipc	ra,0xffffd
    80005bec:	210080e7          	jalr	528(ra) # 80002df8 <argstr>
    80005bf0:	02054b63          	bltz	a0,80005c26 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bf4:	f6841683          	lh	a3,-152(s0)
    80005bf8:	f6c41603          	lh	a2,-148(s0)
    80005bfc:	458d                	li	a1,3
    80005bfe:	f7040513          	addi	a0,s0,-144
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	778080e7          	jalr	1912(ra) # 8000537a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c0a:	cd11                	beqz	a0,80005c26 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	0a8080e7          	jalr	168(ra) # 80003cb4 <iunlockput>
  end_op();
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	85e080e7          	jalr	-1954(ra) # 80004472 <end_op>
  return 0;
    80005c1c:	4501                	li	a0,0
}
    80005c1e:	60ea                	ld	ra,152(sp)
    80005c20:	644a                	ld	s0,144(sp)
    80005c22:	610d                	addi	sp,sp,160
    80005c24:	8082                	ret
    end_op();
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	84c080e7          	jalr	-1972(ra) # 80004472 <end_op>
    return -1;
    80005c2e:	557d                	li	a0,-1
    80005c30:	b7fd                	j	80005c1e <sys_mknod+0x6c>

0000000080005c32 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c32:	7135                	addi	sp,sp,-160
    80005c34:	ed06                	sd	ra,152(sp)
    80005c36:	e922                	sd	s0,144(sp)
    80005c38:	e526                	sd	s1,136(sp)
    80005c3a:	e14a                	sd	s2,128(sp)
    80005c3c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c3e:	ffffc097          	auipc	ra,0xffffc
    80005c42:	d68080e7          	jalr	-664(ra) # 800019a6 <myproc>
    80005c46:	892a                	mv	s2,a0
  
  begin_op();
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	7b0080e7          	jalr	1968(ra) # 800043f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c50:	08000613          	li	a2,128
    80005c54:	f6040593          	addi	a1,s0,-160
    80005c58:	4501                	li	a0,0
    80005c5a:	ffffd097          	auipc	ra,0xffffd
    80005c5e:	19e080e7          	jalr	414(ra) # 80002df8 <argstr>
    80005c62:	04054b63          	bltz	a0,80005cb8 <sys_chdir+0x86>
    80005c66:	f6040513          	addi	a0,s0,-160
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	58e080e7          	jalr	1422(ra) # 800041f8 <namei>
    80005c72:	84aa                	mv	s1,a0
    80005c74:	c131                	beqz	a0,80005cb8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	ddc080e7          	jalr	-548(ra) # 80003a52 <ilock>
  if(ip->type != T_DIR){
    80005c7e:	04449703          	lh	a4,68(s1)
    80005c82:	4785                	li	a5,1
    80005c84:	04f71063          	bne	a4,a5,80005cc4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c88:	8526                	mv	a0,s1
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	e8a080e7          	jalr	-374(ra) # 80003b14 <iunlock>
  iput(p->cwd);
    80005c92:	15093503          	ld	a0,336(s2)
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	f76080e7          	jalr	-138(ra) # 80003c0c <iput>
  end_op();
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	7d4080e7          	jalr	2004(ra) # 80004472 <end_op>
  p->cwd = ip;
    80005ca6:	14993823          	sd	s1,336(s2)
  return 0;
    80005caa:	4501                	li	a0,0
}
    80005cac:	60ea                	ld	ra,152(sp)
    80005cae:	644a                	ld	s0,144(sp)
    80005cb0:	64aa                	ld	s1,136(sp)
    80005cb2:	690a                	ld	s2,128(sp)
    80005cb4:	610d                	addi	sp,sp,160
    80005cb6:	8082                	ret
    end_op();
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	7ba080e7          	jalr	1978(ra) # 80004472 <end_op>
    return -1;
    80005cc0:	557d                	li	a0,-1
    80005cc2:	b7ed                	j	80005cac <sys_chdir+0x7a>
    iunlockput(ip);
    80005cc4:	8526                	mv	a0,s1
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	fee080e7          	jalr	-18(ra) # 80003cb4 <iunlockput>
    end_op();
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	7a4080e7          	jalr	1956(ra) # 80004472 <end_op>
    return -1;
    80005cd6:	557d                	li	a0,-1
    80005cd8:	bfd1                	j	80005cac <sys_chdir+0x7a>

0000000080005cda <sys_exec>:

uint64
sys_exec(void)
{
    80005cda:	7121                	addi	sp,sp,-448
    80005cdc:	ff06                	sd	ra,440(sp)
    80005cde:	fb22                	sd	s0,432(sp)
    80005ce0:	f726                	sd	s1,424(sp)
    80005ce2:	f34a                	sd	s2,416(sp)
    80005ce4:	ef4e                	sd	s3,408(sp)
    80005ce6:	eb52                	sd	s4,400(sp)
    80005ce8:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cea:	e4840593          	addi	a1,s0,-440
    80005cee:	4505                	li	a0,1
    80005cf0:	ffffd097          	auipc	ra,0xffffd
    80005cf4:	0e8080e7          	jalr	232(ra) # 80002dd8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005cf8:	08000613          	li	a2,128
    80005cfc:	f5040593          	addi	a1,s0,-176
    80005d00:	4501                	li	a0,0
    80005d02:	ffffd097          	auipc	ra,0xffffd
    80005d06:	0f6080e7          	jalr	246(ra) # 80002df8 <argstr>
    80005d0a:	87aa                	mv	a5,a0
    return -1;
    80005d0c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d0e:	0c07c263          	bltz	a5,80005dd2 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005d12:	10000613          	li	a2,256
    80005d16:	4581                	li	a1,0
    80005d18:	e5040513          	addi	a0,s0,-432
    80005d1c:	ffffb097          	auipc	ra,0xffffb
    80005d20:	fb2080e7          	jalr	-78(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d24:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005d28:	89a6                	mv	s3,s1
    80005d2a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d2c:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d30:	00391513          	slli	a0,s2,0x3
    80005d34:	e4040593          	addi	a1,s0,-448
    80005d38:	e4843783          	ld	a5,-440(s0)
    80005d3c:	953e                	add	a0,a0,a5
    80005d3e:	ffffd097          	auipc	ra,0xffffd
    80005d42:	fdc080e7          	jalr	-36(ra) # 80002d1a <fetchaddr>
    80005d46:	02054a63          	bltz	a0,80005d7a <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005d4a:	e4043783          	ld	a5,-448(s0)
    80005d4e:	c3b9                	beqz	a5,80005d94 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d50:	ffffb097          	auipc	ra,0xffffb
    80005d54:	d92080e7          	jalr	-622(ra) # 80000ae2 <kalloc>
    80005d58:	85aa                	mv	a1,a0
    80005d5a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d5e:	cd11                	beqz	a0,80005d7a <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d60:	6605                	lui	a2,0x1
    80005d62:	e4043503          	ld	a0,-448(s0)
    80005d66:	ffffd097          	auipc	ra,0xffffd
    80005d6a:	006080e7          	jalr	6(ra) # 80002d6c <fetchstr>
    80005d6e:	00054663          	bltz	a0,80005d7a <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005d72:	0905                	addi	s2,s2,1
    80005d74:	09a1                	addi	s3,s3,8
    80005d76:	fb491de3          	bne	s2,s4,80005d30 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d7a:	f5040913          	addi	s2,s0,-176
    80005d7e:	6088                	ld	a0,0(s1)
    80005d80:	c921                	beqz	a0,80005dd0 <sys_exec+0xf6>
    kfree(argv[i]);
    80005d82:	ffffb097          	auipc	ra,0xffffb
    80005d86:	c62080e7          	jalr	-926(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d8a:	04a1                	addi	s1,s1,8
    80005d8c:	ff2499e3          	bne	s1,s2,80005d7e <sys_exec+0xa4>
  return -1;
    80005d90:	557d                	li	a0,-1
    80005d92:	a081                	j	80005dd2 <sys_exec+0xf8>
      argv[i] = 0;
    80005d94:	0009079b          	sext.w	a5,s2
    80005d98:	078e                	slli	a5,a5,0x3
    80005d9a:	fd078793          	addi	a5,a5,-48
    80005d9e:	97a2                	add	a5,a5,s0
    80005da0:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005da4:	e5040593          	addi	a1,s0,-432
    80005da8:	f5040513          	addi	a0,s0,-176
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	186080e7          	jalr	390(ra) # 80004f32 <exec>
    80005db4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005db6:	f5040993          	addi	s3,s0,-176
    80005dba:	6088                	ld	a0,0(s1)
    80005dbc:	c901                	beqz	a0,80005dcc <sys_exec+0xf2>
    kfree(argv[i]);
    80005dbe:	ffffb097          	auipc	ra,0xffffb
    80005dc2:	c26080e7          	jalr	-986(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dc6:	04a1                	addi	s1,s1,8
    80005dc8:	ff3499e3          	bne	s1,s3,80005dba <sys_exec+0xe0>
  return ret;
    80005dcc:	854a                	mv	a0,s2
    80005dce:	a011                	j	80005dd2 <sys_exec+0xf8>
  return -1;
    80005dd0:	557d                	li	a0,-1
}
    80005dd2:	70fa                	ld	ra,440(sp)
    80005dd4:	745a                	ld	s0,432(sp)
    80005dd6:	74ba                	ld	s1,424(sp)
    80005dd8:	791a                	ld	s2,416(sp)
    80005dda:	69fa                	ld	s3,408(sp)
    80005ddc:	6a5a                	ld	s4,400(sp)
    80005dde:	6139                	addi	sp,sp,448
    80005de0:	8082                	ret

0000000080005de2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005de2:	7139                	addi	sp,sp,-64
    80005de4:	fc06                	sd	ra,56(sp)
    80005de6:	f822                	sd	s0,48(sp)
    80005de8:	f426                	sd	s1,40(sp)
    80005dea:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dec:	ffffc097          	auipc	ra,0xffffc
    80005df0:	bba080e7          	jalr	-1094(ra) # 800019a6 <myproc>
    80005df4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005df6:	fd840593          	addi	a1,s0,-40
    80005dfa:	4501                	li	a0,0
    80005dfc:	ffffd097          	auipc	ra,0xffffd
    80005e00:	fdc080e7          	jalr	-36(ra) # 80002dd8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005e04:	fc840593          	addi	a1,s0,-56
    80005e08:	fd040513          	addi	a0,s0,-48
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	ddc080e7          	jalr	-548(ra) # 80004be8 <pipealloc>
    return -1;
    80005e14:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e16:	0c054463          	bltz	a0,80005ede <sys_pipe+0xfc>
  fd0 = -1;
    80005e1a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e1e:	fd043503          	ld	a0,-48(s0)
    80005e22:	fffff097          	auipc	ra,0xfffff
    80005e26:	516080e7          	jalr	1302(ra) # 80005338 <fdalloc>
    80005e2a:	fca42223          	sw	a0,-60(s0)
    80005e2e:	08054b63          	bltz	a0,80005ec4 <sys_pipe+0xe2>
    80005e32:	fc843503          	ld	a0,-56(s0)
    80005e36:	fffff097          	auipc	ra,0xfffff
    80005e3a:	502080e7          	jalr	1282(ra) # 80005338 <fdalloc>
    80005e3e:	fca42023          	sw	a0,-64(s0)
    80005e42:	06054863          	bltz	a0,80005eb2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e46:	4691                	li	a3,4
    80005e48:	fc440613          	addi	a2,s0,-60
    80005e4c:	fd843583          	ld	a1,-40(s0)
    80005e50:	68a8                	ld	a0,80(s1)
    80005e52:	ffffc097          	auipc	ra,0xffffc
    80005e56:	814080e7          	jalr	-2028(ra) # 80001666 <copyout>
    80005e5a:	02054063          	bltz	a0,80005e7a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e5e:	4691                	li	a3,4
    80005e60:	fc040613          	addi	a2,s0,-64
    80005e64:	fd843583          	ld	a1,-40(s0)
    80005e68:	0591                	addi	a1,a1,4
    80005e6a:	68a8                	ld	a0,80(s1)
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	7fa080e7          	jalr	2042(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e74:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e76:	06055463          	bgez	a0,80005ede <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e7a:	fc442783          	lw	a5,-60(s0)
    80005e7e:	07e9                	addi	a5,a5,26
    80005e80:	078e                	slli	a5,a5,0x3
    80005e82:	97a6                	add	a5,a5,s1
    80005e84:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e88:	fc042783          	lw	a5,-64(s0)
    80005e8c:	07e9                	addi	a5,a5,26
    80005e8e:	078e                	slli	a5,a5,0x3
    80005e90:	94be                	add	s1,s1,a5
    80005e92:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e96:	fd043503          	ld	a0,-48(s0)
    80005e9a:	fffff097          	auipc	ra,0xfffff
    80005e9e:	a22080e7          	jalr	-1502(ra) # 800048bc <fileclose>
    fileclose(wf);
    80005ea2:	fc843503          	ld	a0,-56(s0)
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	a16080e7          	jalr	-1514(ra) # 800048bc <fileclose>
    return -1;
    80005eae:	57fd                	li	a5,-1
    80005eb0:	a03d                	j	80005ede <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005eb2:	fc442783          	lw	a5,-60(s0)
    80005eb6:	0007c763          	bltz	a5,80005ec4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005eba:	07e9                	addi	a5,a5,26
    80005ebc:	078e                	slli	a5,a5,0x3
    80005ebe:	97a6                	add	a5,a5,s1
    80005ec0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005ec4:	fd043503          	ld	a0,-48(s0)
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	9f4080e7          	jalr	-1548(ra) # 800048bc <fileclose>
    fileclose(wf);
    80005ed0:	fc843503          	ld	a0,-56(s0)
    80005ed4:	fffff097          	auipc	ra,0xfffff
    80005ed8:	9e8080e7          	jalr	-1560(ra) # 800048bc <fileclose>
    return -1;
    80005edc:	57fd                	li	a5,-1
}
    80005ede:	853e                	mv	a0,a5
    80005ee0:	70e2                	ld	ra,56(sp)
    80005ee2:	7442                	ld	s0,48(sp)
    80005ee4:	74a2                	ld	s1,40(sp)
    80005ee6:	6121                	addi	sp,sp,64
    80005ee8:	8082                	ret
    80005eea:	0000                	unimp
    80005eec:	0000                	unimp
	...

0000000080005ef0 <kernelvec>:
    80005ef0:	7111                	addi	sp,sp,-256
    80005ef2:	e006                	sd	ra,0(sp)
    80005ef4:	e40a                	sd	sp,8(sp)
    80005ef6:	e80e                	sd	gp,16(sp)
    80005ef8:	ec12                	sd	tp,24(sp)
    80005efa:	f016                	sd	t0,32(sp)
    80005efc:	f41a                	sd	t1,40(sp)
    80005efe:	f81e                	sd	t2,48(sp)
    80005f00:	fc22                	sd	s0,56(sp)
    80005f02:	e0a6                	sd	s1,64(sp)
    80005f04:	e4aa                	sd	a0,72(sp)
    80005f06:	e8ae                	sd	a1,80(sp)
    80005f08:	ecb2                	sd	a2,88(sp)
    80005f0a:	f0b6                	sd	a3,96(sp)
    80005f0c:	f4ba                	sd	a4,104(sp)
    80005f0e:	f8be                	sd	a5,112(sp)
    80005f10:	fcc2                	sd	a6,120(sp)
    80005f12:	e146                	sd	a7,128(sp)
    80005f14:	e54a                	sd	s2,136(sp)
    80005f16:	e94e                	sd	s3,144(sp)
    80005f18:	ed52                	sd	s4,152(sp)
    80005f1a:	f156                	sd	s5,160(sp)
    80005f1c:	f55a                	sd	s6,168(sp)
    80005f1e:	f95e                	sd	s7,176(sp)
    80005f20:	fd62                	sd	s8,184(sp)
    80005f22:	e1e6                	sd	s9,192(sp)
    80005f24:	e5ea                	sd	s10,200(sp)
    80005f26:	e9ee                	sd	s11,208(sp)
    80005f28:	edf2                	sd	t3,216(sp)
    80005f2a:	f1f6                	sd	t4,224(sp)
    80005f2c:	f5fa                	sd	t5,232(sp)
    80005f2e:	f9fe                	sd	t6,240(sp)
    80005f30:	ca3fc0ef          	jal	ra,80002bd2 <kerneltrap>
    80005f34:	6082                	ld	ra,0(sp)
    80005f36:	6122                	ld	sp,8(sp)
    80005f38:	61c2                	ld	gp,16(sp)
    80005f3a:	7282                	ld	t0,32(sp)
    80005f3c:	7322                	ld	t1,40(sp)
    80005f3e:	73c2                	ld	t2,48(sp)
    80005f40:	7462                	ld	s0,56(sp)
    80005f42:	6486                	ld	s1,64(sp)
    80005f44:	6526                	ld	a0,72(sp)
    80005f46:	65c6                	ld	a1,80(sp)
    80005f48:	6666                	ld	a2,88(sp)
    80005f4a:	7686                	ld	a3,96(sp)
    80005f4c:	7726                	ld	a4,104(sp)
    80005f4e:	77c6                	ld	a5,112(sp)
    80005f50:	7866                	ld	a6,120(sp)
    80005f52:	688a                	ld	a7,128(sp)
    80005f54:	692a                	ld	s2,136(sp)
    80005f56:	69ca                	ld	s3,144(sp)
    80005f58:	6a6a                	ld	s4,152(sp)
    80005f5a:	7a8a                	ld	s5,160(sp)
    80005f5c:	7b2a                	ld	s6,168(sp)
    80005f5e:	7bca                	ld	s7,176(sp)
    80005f60:	7c6a                	ld	s8,184(sp)
    80005f62:	6c8e                	ld	s9,192(sp)
    80005f64:	6d2e                	ld	s10,200(sp)
    80005f66:	6dce                	ld	s11,208(sp)
    80005f68:	6e6e                	ld	t3,216(sp)
    80005f6a:	7e8e                	ld	t4,224(sp)
    80005f6c:	7f2e                	ld	t5,232(sp)
    80005f6e:	7fce                	ld	t6,240(sp)
    80005f70:	6111                	addi	sp,sp,256
    80005f72:	10200073          	sret
    80005f76:	00000013          	nop
    80005f7a:	00000013          	nop
    80005f7e:	0001                	nop

0000000080005f80 <timervec>:
    80005f80:	34051573          	csrrw	a0,mscratch,a0
    80005f84:	e10c                	sd	a1,0(a0)
    80005f86:	e510                	sd	a2,8(a0)
    80005f88:	e914                	sd	a3,16(a0)
    80005f8a:	6d0c                	ld	a1,24(a0)
    80005f8c:	7110                	ld	a2,32(a0)
    80005f8e:	6194                	ld	a3,0(a1)
    80005f90:	96b2                	add	a3,a3,a2
    80005f92:	e194                	sd	a3,0(a1)
    80005f94:	4589                	li	a1,2
    80005f96:	14459073          	csrw	sip,a1
    80005f9a:	6914                	ld	a3,16(a0)
    80005f9c:	6510                	ld	a2,8(a0)
    80005f9e:	610c                	ld	a1,0(a0)
    80005fa0:	34051573          	csrrw	a0,mscratch,a0
    80005fa4:	30200073          	mret
	...

0000000080005faa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005faa:	1141                	addi	sp,sp,-16
    80005fac:	e422                	sd	s0,8(sp)
    80005fae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fb0:	0c0007b7          	lui	a5,0xc000
    80005fb4:	4705                	li	a4,1
    80005fb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fb8:	c3d8                	sw	a4,4(a5)
}
    80005fba:	6422                	ld	s0,8(sp)
    80005fbc:	0141                	addi	sp,sp,16
    80005fbe:	8082                	ret

0000000080005fc0 <plicinithart>:

void
plicinithart(void)
{
    80005fc0:	1141                	addi	sp,sp,-16
    80005fc2:	e406                	sd	ra,8(sp)
    80005fc4:	e022                	sd	s0,0(sp)
    80005fc6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	9b2080e7          	jalr	-1614(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fd0:	0085171b          	slliw	a4,a0,0x8
    80005fd4:	0c0027b7          	lui	a5,0xc002
    80005fd8:	97ba                	add	a5,a5,a4
    80005fda:	40200713          	li	a4,1026
    80005fde:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fe2:	00d5151b          	slliw	a0,a0,0xd
    80005fe6:	0c2017b7          	lui	a5,0xc201
    80005fea:	97aa                	add	a5,a5,a0
    80005fec:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ff0:	60a2                	ld	ra,8(sp)
    80005ff2:	6402                	ld	s0,0(sp)
    80005ff4:	0141                	addi	sp,sp,16
    80005ff6:	8082                	ret

0000000080005ff8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ff8:	1141                	addi	sp,sp,-16
    80005ffa:	e406                	sd	ra,8(sp)
    80005ffc:	e022                	sd	s0,0(sp)
    80005ffe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006000:	ffffc097          	auipc	ra,0xffffc
    80006004:	97a080e7          	jalr	-1670(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006008:	00d5151b          	slliw	a0,a0,0xd
    8000600c:	0c2017b7          	lui	a5,0xc201
    80006010:	97aa                	add	a5,a5,a0
  return irq;
}
    80006012:	43c8                	lw	a0,4(a5)
    80006014:	60a2                	ld	ra,8(sp)
    80006016:	6402                	ld	s0,0(sp)
    80006018:	0141                	addi	sp,sp,16
    8000601a:	8082                	ret

000000008000601c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000601c:	1101                	addi	sp,sp,-32
    8000601e:	ec06                	sd	ra,24(sp)
    80006020:	e822                	sd	s0,16(sp)
    80006022:	e426                	sd	s1,8(sp)
    80006024:	1000                	addi	s0,sp,32
    80006026:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006028:	ffffc097          	auipc	ra,0xffffc
    8000602c:	952080e7          	jalr	-1710(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006030:	00d5151b          	slliw	a0,a0,0xd
    80006034:	0c2017b7          	lui	a5,0xc201
    80006038:	97aa                	add	a5,a5,a0
    8000603a:	c3c4                	sw	s1,4(a5)
}
    8000603c:	60e2                	ld	ra,24(sp)
    8000603e:	6442                	ld	s0,16(sp)
    80006040:	64a2                	ld	s1,8(sp)
    80006042:	6105                	addi	sp,sp,32
    80006044:	8082                	ret

0000000080006046 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006046:	1141                	addi	sp,sp,-16
    80006048:	e406                	sd	ra,8(sp)
    8000604a:	e022                	sd	s0,0(sp)
    8000604c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000604e:	479d                	li	a5,7
    80006050:	04a7cc63          	blt	a5,a0,800060a8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006054:	0001c797          	auipc	a5,0x1c
    80006058:	5ec78793          	addi	a5,a5,1516 # 80022640 <disk>
    8000605c:	97aa                	add	a5,a5,a0
    8000605e:	0187c783          	lbu	a5,24(a5)
    80006062:	ebb9                	bnez	a5,800060b8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006064:	00451693          	slli	a3,a0,0x4
    80006068:	0001c797          	auipc	a5,0x1c
    8000606c:	5d878793          	addi	a5,a5,1496 # 80022640 <disk>
    80006070:	6398                	ld	a4,0(a5)
    80006072:	9736                	add	a4,a4,a3
    80006074:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006078:	6398                	ld	a4,0(a5)
    8000607a:	9736                	add	a4,a4,a3
    8000607c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006080:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006084:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006088:	97aa                	add	a5,a5,a0
    8000608a:	4705                	li	a4,1
    8000608c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006090:	0001c517          	auipc	a0,0x1c
    80006094:	5c850513          	addi	a0,a0,1480 # 80022658 <disk+0x18>
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	0dc080e7          	jalr	220(ra) # 80002174 <wakeup>
}
    800060a0:	60a2                	ld	ra,8(sp)
    800060a2:	6402                	ld	s0,0(sp)
    800060a4:	0141                	addi	sp,sp,16
    800060a6:	8082                	ret
    panic("free_desc 1");
    800060a8:	00002517          	auipc	a0,0x2
    800060ac:	6b850513          	addi	a0,a0,1720 # 80008760 <syscalls+0x310>
    800060b0:	ffffa097          	auipc	ra,0xffffa
    800060b4:	48c080e7          	jalr	1164(ra) # 8000053c <panic>
    panic("free_desc 2");
    800060b8:	00002517          	auipc	a0,0x2
    800060bc:	6b850513          	addi	a0,a0,1720 # 80008770 <syscalls+0x320>
    800060c0:	ffffa097          	auipc	ra,0xffffa
    800060c4:	47c080e7          	jalr	1148(ra) # 8000053c <panic>

00000000800060c8 <virtio_disk_init>:
{
    800060c8:	1101                	addi	sp,sp,-32
    800060ca:	ec06                	sd	ra,24(sp)
    800060cc:	e822                	sd	s0,16(sp)
    800060ce:	e426                	sd	s1,8(sp)
    800060d0:	e04a                	sd	s2,0(sp)
    800060d2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060d4:	00002597          	auipc	a1,0x2
    800060d8:	6ac58593          	addi	a1,a1,1708 # 80008780 <syscalls+0x330>
    800060dc:	0001c517          	auipc	a0,0x1c
    800060e0:	68c50513          	addi	a0,a0,1676 # 80022768 <disk+0x128>
    800060e4:	ffffb097          	auipc	ra,0xffffb
    800060e8:	a5e080e7          	jalr	-1442(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060ec:	100017b7          	lui	a5,0x10001
    800060f0:	4398                	lw	a4,0(a5)
    800060f2:	2701                	sext.w	a4,a4
    800060f4:	747277b7          	lui	a5,0x74727
    800060f8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060fc:	14f71b63          	bne	a4,a5,80006252 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006100:	100017b7          	lui	a5,0x10001
    80006104:	43dc                	lw	a5,4(a5)
    80006106:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006108:	4709                	li	a4,2
    8000610a:	14e79463          	bne	a5,a4,80006252 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000610e:	100017b7          	lui	a5,0x10001
    80006112:	479c                	lw	a5,8(a5)
    80006114:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006116:	12e79e63          	bne	a5,a4,80006252 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000611a:	100017b7          	lui	a5,0x10001
    8000611e:	47d8                	lw	a4,12(a5)
    80006120:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006122:	554d47b7          	lui	a5,0x554d4
    80006126:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000612a:	12f71463          	bne	a4,a5,80006252 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000612e:	100017b7          	lui	a5,0x10001
    80006132:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006136:	4705                	li	a4,1
    80006138:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000613a:	470d                	li	a4,3
    8000613c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000613e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006140:	c7ffe6b7          	lui	a3,0xc7ffe
    80006144:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbfdf>
    80006148:	8f75                	and	a4,a4,a3
    8000614a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000614c:	472d                	li	a4,11
    8000614e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006150:	5bbc                	lw	a5,112(a5)
    80006152:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006156:	8ba1                	andi	a5,a5,8
    80006158:	10078563          	beqz	a5,80006262 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000615c:	100017b7          	lui	a5,0x10001
    80006160:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006164:	43fc                	lw	a5,68(a5)
    80006166:	2781                	sext.w	a5,a5
    80006168:	10079563          	bnez	a5,80006272 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000616c:	100017b7          	lui	a5,0x10001
    80006170:	5bdc                	lw	a5,52(a5)
    80006172:	2781                	sext.w	a5,a5
  if(max == 0)
    80006174:	10078763          	beqz	a5,80006282 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006178:	471d                	li	a4,7
    8000617a:	10f77c63          	bgeu	a4,a5,80006292 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000617e:	ffffb097          	auipc	ra,0xffffb
    80006182:	964080e7          	jalr	-1692(ra) # 80000ae2 <kalloc>
    80006186:	0001c497          	auipc	s1,0x1c
    8000618a:	4ba48493          	addi	s1,s1,1210 # 80022640 <disk>
    8000618e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006190:	ffffb097          	auipc	ra,0xffffb
    80006194:	952080e7          	jalr	-1710(ra) # 80000ae2 <kalloc>
    80006198:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000619a:	ffffb097          	auipc	ra,0xffffb
    8000619e:	948080e7          	jalr	-1720(ra) # 80000ae2 <kalloc>
    800061a2:	87aa                	mv	a5,a0
    800061a4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800061a6:	6088                	ld	a0,0(s1)
    800061a8:	cd6d                	beqz	a0,800062a2 <virtio_disk_init+0x1da>
    800061aa:	0001c717          	auipc	a4,0x1c
    800061ae:	49e73703          	ld	a4,1182(a4) # 80022648 <disk+0x8>
    800061b2:	cb65                	beqz	a4,800062a2 <virtio_disk_init+0x1da>
    800061b4:	c7fd                	beqz	a5,800062a2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800061b6:	6605                	lui	a2,0x1
    800061b8:	4581                	li	a1,0
    800061ba:	ffffb097          	auipc	ra,0xffffb
    800061be:	b14080e7          	jalr	-1260(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    800061c2:	0001c497          	auipc	s1,0x1c
    800061c6:	47e48493          	addi	s1,s1,1150 # 80022640 <disk>
    800061ca:	6605                	lui	a2,0x1
    800061cc:	4581                	li	a1,0
    800061ce:	6488                	ld	a0,8(s1)
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	afe080e7          	jalr	-1282(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    800061d8:	6605                	lui	a2,0x1
    800061da:	4581                	li	a1,0
    800061dc:	6888                	ld	a0,16(s1)
    800061de:	ffffb097          	auipc	ra,0xffffb
    800061e2:	af0080e7          	jalr	-1296(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061e6:	100017b7          	lui	a5,0x10001
    800061ea:	4721                	li	a4,8
    800061ec:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061ee:	4098                	lw	a4,0(s1)
    800061f0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061f4:	40d8                	lw	a4,4(s1)
    800061f6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061fa:	6498                	ld	a4,8(s1)
    800061fc:	0007069b          	sext.w	a3,a4
    80006200:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006204:	9701                	srai	a4,a4,0x20
    80006206:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000620a:	6898                	ld	a4,16(s1)
    8000620c:	0007069b          	sext.w	a3,a4
    80006210:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006214:	9701                	srai	a4,a4,0x20
    80006216:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000621a:	4705                	li	a4,1
    8000621c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000621e:	00e48c23          	sb	a4,24(s1)
    80006222:	00e48ca3          	sb	a4,25(s1)
    80006226:	00e48d23          	sb	a4,26(s1)
    8000622a:	00e48da3          	sb	a4,27(s1)
    8000622e:	00e48e23          	sb	a4,28(s1)
    80006232:	00e48ea3          	sb	a4,29(s1)
    80006236:	00e48f23          	sb	a4,30(s1)
    8000623a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000623e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006242:	0727a823          	sw	s2,112(a5)
}
    80006246:	60e2                	ld	ra,24(sp)
    80006248:	6442                	ld	s0,16(sp)
    8000624a:	64a2                	ld	s1,8(sp)
    8000624c:	6902                	ld	s2,0(sp)
    8000624e:	6105                	addi	sp,sp,32
    80006250:	8082                	ret
    panic("could not find virtio disk");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	53e50513          	addi	a0,a0,1342 # 80008790 <syscalls+0x340>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2e2080e7          	jalr	738(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	54e50513          	addi	a0,a0,1358 # 800087b0 <syscalls+0x360>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d2080e7          	jalr	722(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	55e50513          	addi	a0,a0,1374 # 800087d0 <syscalls+0x380>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c2080e7          	jalr	706(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	56e50513          	addi	a0,a0,1390 # 800087f0 <syscalls+0x3a0>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b2080e7          	jalr	690(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	57e50513          	addi	a0,a0,1406 # 80008810 <syscalls+0x3c0>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a2080e7          	jalr	674(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800062a2:	00002517          	auipc	a0,0x2
    800062a6:	58e50513          	addi	a0,a0,1422 # 80008830 <syscalls+0x3e0>
    800062aa:	ffffa097          	auipc	ra,0xffffa
    800062ae:	292080e7          	jalr	658(ra) # 8000053c <panic>

00000000800062b2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062b2:	7159                	addi	sp,sp,-112
    800062b4:	f486                	sd	ra,104(sp)
    800062b6:	f0a2                	sd	s0,96(sp)
    800062b8:	eca6                	sd	s1,88(sp)
    800062ba:	e8ca                	sd	s2,80(sp)
    800062bc:	e4ce                	sd	s3,72(sp)
    800062be:	e0d2                	sd	s4,64(sp)
    800062c0:	fc56                	sd	s5,56(sp)
    800062c2:	f85a                	sd	s6,48(sp)
    800062c4:	f45e                	sd	s7,40(sp)
    800062c6:	f062                	sd	s8,32(sp)
    800062c8:	ec66                	sd	s9,24(sp)
    800062ca:	e86a                	sd	s10,16(sp)
    800062cc:	1880                	addi	s0,sp,112
    800062ce:	8a2a                	mv	s4,a0
    800062d0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062d2:	00c52c83          	lw	s9,12(a0)
    800062d6:	001c9c9b          	slliw	s9,s9,0x1
    800062da:	1c82                	slli	s9,s9,0x20
    800062dc:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062e0:	0001c517          	auipc	a0,0x1c
    800062e4:	48850513          	addi	a0,a0,1160 # 80022768 <disk+0x128>
    800062e8:	ffffb097          	auipc	ra,0xffffb
    800062ec:	8ea080e7          	jalr	-1814(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    800062f0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800062f2:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062f4:	0001cb17          	auipc	s6,0x1c
    800062f8:	34cb0b13          	addi	s6,s6,844 # 80022640 <disk>
  for(int i = 0; i < 3; i++){
    800062fc:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062fe:	0001cc17          	auipc	s8,0x1c
    80006302:	46ac0c13          	addi	s8,s8,1130 # 80022768 <disk+0x128>
    80006306:	a095                	j	8000636a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006308:	00fb0733          	add	a4,s6,a5
    8000630c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006310:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006312:	0207c563          	bltz	a5,8000633c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006316:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006318:	0591                	addi	a1,a1,4
    8000631a:	05560d63          	beq	a2,s5,80006374 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000631e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006320:	0001c717          	auipc	a4,0x1c
    80006324:	32070713          	addi	a4,a4,800 # 80022640 <disk>
    80006328:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000632a:	01874683          	lbu	a3,24(a4)
    8000632e:	fee9                	bnez	a3,80006308 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006330:	2785                	addiw	a5,a5,1
    80006332:	0705                	addi	a4,a4,1
    80006334:	fe979be3          	bne	a5,s1,8000632a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006338:	57fd                	li	a5,-1
    8000633a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000633c:	00c05e63          	blez	a2,80006358 <virtio_disk_rw+0xa6>
    80006340:	060a                	slli	a2,a2,0x2
    80006342:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006346:	0009a503          	lw	a0,0(s3)
    8000634a:	00000097          	auipc	ra,0x0
    8000634e:	cfc080e7          	jalr	-772(ra) # 80006046 <free_desc>
      for(int j = 0; j < i; j++)
    80006352:	0991                	addi	s3,s3,4
    80006354:	ffa999e3          	bne	s3,s10,80006346 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006358:	85e2                	mv	a1,s8
    8000635a:	0001c517          	auipc	a0,0x1c
    8000635e:	2fe50513          	addi	a0,a0,766 # 80022658 <disk+0x18>
    80006362:	ffffc097          	auipc	ra,0xffffc
    80006366:	dae080e7          	jalr	-594(ra) # 80002110 <sleep>
  for(int i = 0; i < 3; i++){
    8000636a:	f9040993          	addi	s3,s0,-112
{
    8000636e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006370:	864a                	mv	a2,s2
    80006372:	b775                	j	8000631e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006374:	f9042503          	lw	a0,-112(s0)
    80006378:	00a50713          	addi	a4,a0,10
    8000637c:	0712                	slli	a4,a4,0x4

  if(write)
    8000637e:	0001c797          	auipc	a5,0x1c
    80006382:	2c278793          	addi	a5,a5,706 # 80022640 <disk>
    80006386:	00e786b3          	add	a3,a5,a4
    8000638a:	01703633          	snez	a2,s7
    8000638e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006390:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006394:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006398:	f6070613          	addi	a2,a4,-160
    8000639c:	6394                	ld	a3,0(a5)
    8000639e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063a0:	00870593          	addi	a1,a4,8
    800063a4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063a6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063a8:	0007b803          	ld	a6,0(a5)
    800063ac:	9642                	add	a2,a2,a6
    800063ae:	46c1                	li	a3,16
    800063b0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063b2:	4585                	li	a1,1
    800063b4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800063b8:	f9442683          	lw	a3,-108(s0)
    800063bc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063c0:	0692                	slli	a3,a3,0x4
    800063c2:	9836                	add	a6,a6,a3
    800063c4:	058a0613          	addi	a2,s4,88
    800063c8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800063cc:	0007b803          	ld	a6,0(a5)
    800063d0:	96c2                	add	a3,a3,a6
    800063d2:	40000613          	li	a2,1024
    800063d6:	c690                	sw	a2,8(a3)
  if(write)
    800063d8:	001bb613          	seqz	a2,s7
    800063dc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063e0:	00166613          	ori	a2,a2,1
    800063e4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063e8:	f9842603          	lw	a2,-104(s0)
    800063ec:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063f0:	00250693          	addi	a3,a0,2
    800063f4:	0692                	slli	a3,a3,0x4
    800063f6:	96be                	add	a3,a3,a5
    800063f8:	58fd                	li	a7,-1
    800063fa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063fe:	0612                	slli	a2,a2,0x4
    80006400:	9832                	add	a6,a6,a2
    80006402:	f9070713          	addi	a4,a4,-112
    80006406:	973e                	add	a4,a4,a5
    80006408:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000640c:	6398                	ld	a4,0(a5)
    8000640e:	9732                	add	a4,a4,a2
    80006410:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006412:	4609                	li	a2,2
    80006414:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006418:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000641c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006420:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006424:	6794                	ld	a3,8(a5)
    80006426:	0026d703          	lhu	a4,2(a3)
    8000642a:	8b1d                	andi	a4,a4,7
    8000642c:	0706                	slli	a4,a4,0x1
    8000642e:	96ba                	add	a3,a3,a4
    80006430:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006434:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006438:	6798                	ld	a4,8(a5)
    8000643a:	00275783          	lhu	a5,2(a4)
    8000643e:	2785                	addiw	a5,a5,1
    80006440:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006444:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006448:	100017b7          	lui	a5,0x10001
    8000644c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006450:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006454:	0001c917          	auipc	s2,0x1c
    80006458:	31490913          	addi	s2,s2,788 # 80022768 <disk+0x128>
  while(b->disk == 1) {
    8000645c:	4485                	li	s1,1
    8000645e:	00b79c63          	bne	a5,a1,80006476 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006462:	85ca                	mv	a1,s2
    80006464:	8552                	mv	a0,s4
    80006466:	ffffc097          	auipc	ra,0xffffc
    8000646a:	caa080e7          	jalr	-854(ra) # 80002110 <sleep>
  while(b->disk == 1) {
    8000646e:	004a2783          	lw	a5,4(s4)
    80006472:	fe9788e3          	beq	a5,s1,80006462 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006476:	f9042903          	lw	s2,-112(s0)
    8000647a:	00290713          	addi	a4,s2,2
    8000647e:	0712                	slli	a4,a4,0x4
    80006480:	0001c797          	auipc	a5,0x1c
    80006484:	1c078793          	addi	a5,a5,448 # 80022640 <disk>
    80006488:	97ba                	add	a5,a5,a4
    8000648a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000648e:	0001c997          	auipc	s3,0x1c
    80006492:	1b298993          	addi	s3,s3,434 # 80022640 <disk>
    80006496:	00491713          	slli	a4,s2,0x4
    8000649a:	0009b783          	ld	a5,0(s3)
    8000649e:	97ba                	add	a5,a5,a4
    800064a0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064a4:	854a                	mv	a0,s2
    800064a6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064aa:	00000097          	auipc	ra,0x0
    800064ae:	b9c080e7          	jalr	-1124(ra) # 80006046 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064b2:	8885                	andi	s1,s1,1
    800064b4:	f0ed                	bnez	s1,80006496 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064b6:	0001c517          	auipc	a0,0x1c
    800064ba:	2b250513          	addi	a0,a0,690 # 80022768 <disk+0x128>
    800064be:	ffffa097          	auipc	ra,0xffffa
    800064c2:	7c8080e7          	jalr	1992(ra) # 80000c86 <release>
}
    800064c6:	70a6                	ld	ra,104(sp)
    800064c8:	7406                	ld	s0,96(sp)
    800064ca:	64e6                	ld	s1,88(sp)
    800064cc:	6946                	ld	s2,80(sp)
    800064ce:	69a6                	ld	s3,72(sp)
    800064d0:	6a06                	ld	s4,64(sp)
    800064d2:	7ae2                	ld	s5,56(sp)
    800064d4:	7b42                	ld	s6,48(sp)
    800064d6:	7ba2                	ld	s7,40(sp)
    800064d8:	7c02                	ld	s8,32(sp)
    800064da:	6ce2                	ld	s9,24(sp)
    800064dc:	6d42                	ld	s10,16(sp)
    800064de:	6165                	addi	sp,sp,112
    800064e0:	8082                	ret

00000000800064e2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064e2:	1101                	addi	sp,sp,-32
    800064e4:	ec06                	sd	ra,24(sp)
    800064e6:	e822                	sd	s0,16(sp)
    800064e8:	e426                	sd	s1,8(sp)
    800064ea:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064ec:	0001c497          	auipc	s1,0x1c
    800064f0:	15448493          	addi	s1,s1,340 # 80022640 <disk>
    800064f4:	0001c517          	auipc	a0,0x1c
    800064f8:	27450513          	addi	a0,a0,628 # 80022768 <disk+0x128>
    800064fc:	ffffa097          	auipc	ra,0xffffa
    80006500:	6d6080e7          	jalr	1750(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006504:	10001737          	lui	a4,0x10001
    80006508:	533c                	lw	a5,96(a4)
    8000650a:	8b8d                	andi	a5,a5,3
    8000650c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000650e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006512:	689c                	ld	a5,16(s1)
    80006514:	0204d703          	lhu	a4,32(s1)
    80006518:	0027d783          	lhu	a5,2(a5)
    8000651c:	04f70863          	beq	a4,a5,8000656c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006520:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006524:	6898                	ld	a4,16(s1)
    80006526:	0204d783          	lhu	a5,32(s1)
    8000652a:	8b9d                	andi	a5,a5,7
    8000652c:	078e                	slli	a5,a5,0x3
    8000652e:	97ba                	add	a5,a5,a4
    80006530:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006532:	00278713          	addi	a4,a5,2
    80006536:	0712                	slli	a4,a4,0x4
    80006538:	9726                	add	a4,a4,s1
    8000653a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000653e:	e721                	bnez	a4,80006586 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006540:	0789                	addi	a5,a5,2
    80006542:	0792                	slli	a5,a5,0x4
    80006544:	97a6                	add	a5,a5,s1
    80006546:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006548:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000654c:	ffffc097          	auipc	ra,0xffffc
    80006550:	c28080e7          	jalr	-984(ra) # 80002174 <wakeup>

    disk.used_idx += 1;
    80006554:	0204d783          	lhu	a5,32(s1)
    80006558:	2785                	addiw	a5,a5,1
    8000655a:	17c2                	slli	a5,a5,0x30
    8000655c:	93c1                	srli	a5,a5,0x30
    8000655e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006562:	6898                	ld	a4,16(s1)
    80006564:	00275703          	lhu	a4,2(a4)
    80006568:	faf71ce3          	bne	a4,a5,80006520 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000656c:	0001c517          	auipc	a0,0x1c
    80006570:	1fc50513          	addi	a0,a0,508 # 80022768 <disk+0x128>
    80006574:	ffffa097          	auipc	ra,0xffffa
    80006578:	712080e7          	jalr	1810(ra) # 80000c86 <release>
}
    8000657c:	60e2                	ld	ra,24(sp)
    8000657e:	6442                	ld	s0,16(sp)
    80006580:	64a2                	ld	s1,8(sp)
    80006582:	6105                	addi	sp,sp,32
    80006584:	8082                	ret
      panic("virtio_disk_intr status");
    80006586:	00002517          	auipc	a0,0x2
    8000658a:	2c250513          	addi	a0,a0,706 # 80008848 <syscalls+0x3f8>
    8000658e:	ffffa097          	auipc	ra,0xffffa
    80006592:	fae080e7          	jalr	-82(ra) # 8000053c <panic>
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
