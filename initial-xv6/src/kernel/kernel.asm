
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
    80000066:	f4e78793          	addi	a5,a5,-178 # 80005fb0 <timervec>
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
    8000012e:	47e080e7          	jalr	1150(ra) # 800025a8 <either_copyin>
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
    800001c0:	236080e7          	jalr	566(ra) # 800023f2 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	f74080e7          	jalr	-140(ra) # 8000213e <sleep>
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
    80000214:	342080e7          	jalr	834(ra) # 80002552 <either_copyout>
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
    800002f2:	310080e7          	jalr	784(ra) # 800025fe <procdump>
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
    80000446:	d60080e7          	jalr	-672(ra) # 800021a2 <wakeup>
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
    80000894:	912080e7          	jalr	-1774(ra) # 800021a2 <wakeup>
    
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
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	824080e7          	jalr	-2012(ra) # 8000213e <sleep>
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
    80000ebc:	a32080e7          	jalr	-1486(ra) # 800028ea <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	130080e7          	jalr	304(ra) # 80005ff0 <plicinithart>
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
    80000f34:	992080e7          	jalr	-1646(ra) # 800028c2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	9b2080e7          	jalr	-1614(ra) # 800028ea <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	09a080e7          	jalr	154(ra) # 80005fda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	0a8080e7          	jalr	168(ra) # 80005ff0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	292080e7          	jalr	658(ra) # 800031e2 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	930080e7          	jalr	-1744(ra) # 80003888 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	8a6080e7          	jalr	-1882(ra) # 80004806 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	190080e7          	jalr	400(ra) # 800060f8 <virtio_disk_init>
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
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    80001846:	0000f497          	auipc	s1,0xf
    8000184a:	75a48493          	addi	s1,s1,1882 # 80010fa0 <proc>
	{
		char* pa = kalloc();
		if(pa == 0)
			panic("kalloc");
		uint64 va = KSTACK((int)(p - proc));
    8000184e:	8b26                	mv	s6,s1
    80001850:	00006a97          	auipc	s5,0x6
    80001854:	7b0a8a93          	addi	s5,s5,1968 # 80008000 <etext>
    80001858:	04000937          	lui	s2,0x4000
    8000185c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000185e:	0932                	slli	s2,s2,0xc
	for(p = proc; p < &proc[NPROC]; p++)
    80001860:	00016a17          	auipc	s4,0x16
    80001864:	b40a0a13          	addi	s4,s4,-1216 # 800173a0 <tickslock>
		char* pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	27a080e7          	jalr	634(ra) # 80000ae2 <kalloc>
    80001870:	862a                	mv	a2,a0
		if(pa == 0)
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
	for(p = proc; p < &proc[NPROC]; p++)
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
	struct proc* p;

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
	for(p = proc; p < &proc[NPROC]; p++)
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
	for(p = proc; p < &proc[NPROC]; p++)
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
	for(p = proc; p < &proc[NPROC]; p++)
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
struct cpu* mycpu(void)
{
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	addi	s0,sp,16
    80001990:	8792                	mv	a5,tp
	int id = cpuid();
	struct cpu* c = &cpus[id];
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
struct proc* myproc(void)
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
	struct cpu* c = mycpu();
	struct proc* p = c->proc;
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

	if(first)
    800019f6:	00007797          	auipc	a5,0x7
    800019fa:	e6a7a783          	lw	a5,-406(a5) # 80008860 <first.1>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
		// be run from main().
		first = 0;
		fsinit(ROOTDEV);
	}

	usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	f02080e7          	jalr	-254(ra) # 80002902 <usertrapret>
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
    80001a1e:	dee080e7          	jalr	-530(ra) # 80003808 <fsinit>
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
{
    80001a6a:	1101                	addi	sp,sp,-32
    80001a6c:	ec06                	sd	ra,24(sp)
    80001a6e:	e822                	sd	s0,16(sp)
    80001a70:	1000                	addi	s0,sp,32
	argint(0, &ticks);
    80001a72:	fec40593          	addi	a1,s0,-20
    80001a76:	4501                	li	a0,0
    80001a78:	00001097          	auipc	ra,0x1
    80001a7c:	36e080e7          	jalr	878(ra) # 80002de6 <argint>
	argaddr(1, &handler);
    80001a80:	fe040593          	addi	a1,s0,-32
    80001a84:	4505                	li	a0,1
    80001a86:	00001097          	auipc	ra,0x1
    80001a8a:	380080e7          	jalr	896(ra) # 80002e06 <argaddr>
	myproc()->is_sigalarm = 0;
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
	if(pagetable == 0)
    80001ae8:	c121                	beqz	a0,80001b28 <proc_pagetable+0x58>
	if(mappages(pagetable, TRAMPOLINE, PGSIZE, (uint64)trampoline, PTE_R | PTE_X) < 0)
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
	if(mappages(pagetable, TRAPFRAME, PGSIZE, (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
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
	if(p->backup_trapframe)
    80001bca:	18853503          	ld	a0,392(a0)
    80001bce:	c509                	beqz	a0,80001bd8 <freeproc+0x1a>
		kfree((void*)p->backup_trapframe);
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	e14080e7          	jalr	-492(ra) # 800009e4 <kfree>
	p->trapframe = 0;
    80001bd8:	0404bc23          	sd	zero,88(s1)
	if(p->pagetable)
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
	for(p = proc; p < &proc[NPROC]; p++)
    80001c24:	0000f497          	auipc	s1,0xf
    80001c28:	37c48493          	addi	s1,s1,892 # 80010fa0 <proc>
    80001c2c:	00015917          	auipc	s2,0x15
    80001c30:	77490913          	addi	s2,s2,1908 # 800173a0 <tickslock>
		acquire(&p->lock);
    80001c34:	8526                	mv	a0,s1
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	f9c080e7          	jalr	-100(ra) # 80000bd2 <acquire>
		if(p->state == UNUSED)
    80001c3e:	4c9c                	lw	a5,24(s1)
    80001c40:	cf81                	beqz	a5,80001c58 <allocproc+0x40>
			release(&p->lock);
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	042080e7          	jalr	66(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
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
	if((p->trapframe = (struct trapframe*)kalloc()) == 0)
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	e7c080e7          	jalr	-388(ra) # 80000ae2 <kalloc>
    80001c6e:	892a                	mv	s2,a0
    80001c70:	eca8                	sd	a0,88(s1)
    80001c72:	cd25                	beqz	a0,80001cea <allocproc+0xd2>
	if((p->backup_trapframe = (struct trapframe*)kalloc()) == 0)
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
	if(p->pagetable == 0)
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
	p->trapframe->epc = 0; // user program counter
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
    80001d8a:	4a0080e7          	jalr	1184(ra) # 80004226 <namei>
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
	struct proc* p = myproc();
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	bee080e7          	jalr	-1042(ra) # 800019a6 <myproc>
    80001dc0:	84aa                	mv	s1,a0
	sz = p->sz;
    80001dc2:	652c                	ld	a1,72(a0)
	if(n > 0)
    80001dc4:	01204c63          	bgtz	s2,80001ddc <growproc+0x32>
	else if(n < 0)
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
		if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
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
	struct proc* p = myproc();
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	b8e080e7          	jalr	-1138(ra) # 800019a6 <myproc>
    80001e20:	8aaa                	mv	s5,a0
	if((np = allocproc()) == 0)
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	df6080e7          	jalr	-522(ra) # 80001c18 <allocproc>
    80001e2a:	10050c63          	beqz	a0,80001f42 <fork+0x13c>
    80001e2e:	8a2a                	mv	s4,a0
	if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
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
	for(i = 0; i < NOFILE; i++)
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
	for(i = 0; i < NOFILE; i++)
    80001eaa:	04a1                	addi	s1,s1,8
    80001eac:	0921                	addi	s2,s2,8
    80001eae:	01348b63          	beq	s1,s3,80001ec4 <fork+0xbe>
		if(p->ofile[i])
    80001eb2:	6088                	ld	a0,0(s1)
    80001eb4:	d97d                	beqz	a0,80001eaa <fork+0xa4>
			np->ofile[i] = filedup(p->ofile[i]);
    80001eb6:	00003097          	auipc	ra,0x3
    80001eba:	9e2080e7          	jalr	-1566(ra) # 80004898 <filedup>
    80001ebe:	00a93023          	sd	a0,0(s2)
    80001ec2:	b7e5                	j	80001eaa <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001ec4:	150ab503          	ld	a0,336(s5)
    80001ec8:	00002097          	auipc	ra,0x2
    80001ecc:	b7a080e7          	jalr	-1158(ra) # 80003a42 <idup>
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
    80001f46:	715d                	addi	sp,sp,-80
    80001f48:	e486                	sd	ra,72(sp)
    80001f4a:	e0a2                	sd	s0,64(sp)
    80001f4c:	fc26                	sd	s1,56(sp)
    80001f4e:	f84a                	sd	s2,48(sp)
    80001f50:	f44e                	sd	s3,40(sp)
    80001f52:	f052                	sd	s4,32(sp)
    80001f54:	ec56                	sd	s5,24(sp)
    80001f56:	e85a                	sd	s6,16(sp)
    80001f58:	e45e                	sd	s7,8(sp)
    80001f5a:	0880                	addi	s0,sp,80
    80001f5c:	8792                	mv	a5,tp
	int id = r_tp();
    80001f5e:	2781                	sext.w	a5,a5
	c->proc = 0;
    80001f60:	00779a93          	slli	s5,a5,0x7
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	c0c70713          	addi	a4,a4,-1012 # 80010b70 <pid_lock>
    80001f6c:	9756                	add	a4,a4,s5
    80001f6e:	02073823          	sd	zero,48(a4)
					swtch(&c->context, &p->context);
    80001f72:	0000f717          	auipc	a4,0xf
    80001f76:	c3670713          	addi	a4,a4,-970 # 80010ba8 <cpus+0x8>
    80001f7a:	9aba                	add	s5,s5,a4
			acquire(&p->lock);
    80001f7c:	0000fb97          	auipc	s7,0xf
    80001f80:	024b8b93          	addi	s7,s7,36 # 80010fa0 <proc>
			if(p->state == RUNNABLE)
    80001f84:	490d                	li	s2,3
				p->state = RUNNING;
    80001f86:	4b11                	li	s6,4
				c->proc = p;
    80001f88:	079e                	slli	a5,a5,0x7
    80001f8a:	0000fa17          	auipc	s4,0xf
    80001f8e:	be6a0a13          	addi	s4,s4,-1050 # 80010b70 <pid_lock>
    80001f92:	9a3e                	add	s4,s4,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9c:	10079073          	csrw	sstatus,a5
			acquire(&p->lock);
    80001fa0:	855e                	mv	a0,s7
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	c30080e7          	jalr	-976(ra) # 80000bd2 <acquire>
			if(p->state == RUNNABLE)
    80001faa:	018ba783          	lw	a5,24(s7)
    80001fae:	03278063          	beq	a5,s2,80001fce <scheduler+0x88>
			release(&p->lock);
    80001fb2:	855e                	mv	a0,s7
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	cd2080e7          	jalr	-814(ra) # 80000c86 <release>
			for(p = proc; p < &proc[NPROC]; p++)
    80001fbc:	0000f497          	auipc	s1,0xf
    80001fc0:	fe448493          	addi	s1,s1,-28 # 80010fa0 <proc>
    80001fc4:	00015997          	auipc	s3,0x15
    80001fc8:	3dc98993          	addi	s3,s3,988 # 800173a0 <tickslock>
    80001fcc:	a815                	j	80002000 <scheduler+0xba>
				p->state = RUNNING;
    80001fce:	016bac23          	sw	s6,24(s7)
				c->proc = p;
    80001fd2:	037a3823          	sd	s7,48(s4)
				swtch(&c->context, &p->context);
    80001fd6:	0000f597          	auipc	a1,0xf
    80001fda:	02a58593          	addi	a1,a1,42 # 80011000 <proc+0x60>
    80001fde:	8556                	mv	a0,s5
    80001fe0:	00001097          	auipc	ra,0x1
    80001fe4:	878080e7          	jalr	-1928(ra) # 80002858 <swtch>
				c->proc = 0;
    80001fe8:	020a3823          	sd	zero,48(s4)
    80001fec:	b7d9                	j	80001fb2 <scheduler+0x6c>
				release(&p->lock);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	c96080e7          	jalr	-874(ra) # 80000c86 <release>
			for(p = proc; p < &proc[NPROC]; p++)
    80001ff8:	19048493          	addi	s1,s1,400
    80001ffc:	f9348ce3          	beq	s1,s3,80001f94 <scheduler+0x4e>
				acquire(&p->lock);
    80002000:	8526                	mv	a0,s1
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	bd0080e7          	jalr	-1072(ra) # 80000bd2 <acquire>
				if(p->state == RUNNABLE)
    8000200a:	4c9c                	lw	a5,24(s1)
    8000200c:	ff2791e3          	bne	a5,s2,80001fee <scheduler+0xa8>
					p->state = RUNNING;
    80002010:	0164ac23          	sw	s6,24(s1)
					c->proc = p;
    80002014:	029a3823          	sd	s1,48(s4)
					swtch(&c->context, &p->context);
    80002018:	06048593          	addi	a1,s1,96
    8000201c:	8556                	mv	a0,s5
    8000201e:	00001097          	auipc	ra,0x1
    80002022:	83a080e7          	jalr	-1990(ra) # 80002858 <swtch>
					c->proc = 0;
    80002026:	020a3823          	sd	zero,48(s4)
    8000202a:	b7d1                	j	80001fee <scheduler+0xa8>

000000008000202c <sched>:
{
    8000202c:	7179                	addi	sp,sp,-48
    8000202e:	f406                	sd	ra,40(sp)
    80002030:	f022                	sd	s0,32(sp)
    80002032:	ec26                	sd	s1,24(sp)
    80002034:	e84a                	sd	s2,16(sp)
    80002036:	e44e                	sd	s3,8(sp)
    80002038:	1800                	addi	s0,sp,48
	struct proc* p = myproc();
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	96c080e7          	jalr	-1684(ra) # 800019a6 <myproc>
    80002042:	84aa                	mv	s1,a0
	if(!holding(&p->lock))
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	b14080e7          	jalr	-1260(ra) # 80000b58 <holding>
    8000204c:	c93d                	beqz	a0,800020c2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000204e:	8792                	mv	a5,tp
	if(mycpu()->noff != 1)
    80002050:	2781                	sext.w	a5,a5
    80002052:	079e                	slli	a5,a5,0x7
    80002054:	0000f717          	auipc	a4,0xf
    80002058:	b1c70713          	addi	a4,a4,-1252 # 80010b70 <pid_lock>
    8000205c:	97ba                	add	a5,a5,a4
    8000205e:	0a87a703          	lw	a4,168(a5)
    80002062:	4785                	li	a5,1
    80002064:	06f71763          	bne	a4,a5,800020d2 <sched+0xa6>
	if(p->state == RUNNING)
    80002068:	4c98                	lw	a4,24(s1)
    8000206a:	4791                	li	a5,4
    8000206c:	06f70b63          	beq	a4,a5,800020e2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002070:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002074:	8b89                	andi	a5,a5,2
	if(intr_get())
    80002076:	efb5                	bnez	a5,800020f2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002078:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    8000207a:	0000f917          	auipc	s2,0xf
    8000207e:	af690913          	addi	s2,s2,-1290 # 80010b70 <pid_lock>
    80002082:	2781                	sext.w	a5,a5
    80002084:	079e                	slli	a5,a5,0x7
    80002086:	97ca                	add	a5,a5,s2
    80002088:	0ac7a983          	lw	s3,172(a5)
    8000208c:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    8000208e:	2781                	sext.w	a5,a5
    80002090:	079e                	slli	a5,a5,0x7
    80002092:	0000f597          	auipc	a1,0xf
    80002096:	b1658593          	addi	a1,a1,-1258 # 80010ba8 <cpus+0x8>
    8000209a:	95be                	add	a1,a1,a5
    8000209c:	06048513          	addi	a0,s1,96
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	7b8080e7          	jalr	1976(ra) # 80002858 <swtch>
    800020a8:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    800020aa:	2781                	sext.w	a5,a5
    800020ac:	079e                	slli	a5,a5,0x7
    800020ae:	993e                	add	s2,s2,a5
    800020b0:	0b392623          	sw	s3,172(s2)
}
    800020b4:	70a2                	ld	ra,40(sp)
    800020b6:	7402                	ld	s0,32(sp)
    800020b8:	64e2                	ld	s1,24(sp)
    800020ba:	6942                	ld	s2,16(sp)
    800020bc:	69a2                	ld	s3,8(sp)
    800020be:	6145                	addi	sp,sp,48
    800020c0:	8082                	ret
		panic("sched p->lock");
    800020c2:	00006517          	auipc	a0,0x6
    800020c6:	15650513          	addi	a0,a0,342 # 80008218 <digits+0x1d8>
    800020ca:	ffffe097          	auipc	ra,0xffffe
    800020ce:	472080e7          	jalr	1138(ra) # 8000053c <panic>
		panic("sched locks");
    800020d2:	00006517          	auipc	a0,0x6
    800020d6:	15650513          	addi	a0,a0,342 # 80008228 <digits+0x1e8>
    800020da:	ffffe097          	auipc	ra,0xffffe
    800020de:	462080e7          	jalr	1122(ra) # 8000053c <panic>
		panic("sched running");
    800020e2:	00006517          	auipc	a0,0x6
    800020e6:	15650513          	addi	a0,a0,342 # 80008238 <digits+0x1f8>
    800020ea:	ffffe097          	auipc	ra,0xffffe
    800020ee:	452080e7          	jalr	1106(ra) # 8000053c <panic>
		panic("sched interruptible");
    800020f2:	00006517          	auipc	a0,0x6
    800020f6:	15650513          	addi	a0,a0,342 # 80008248 <digits+0x208>
    800020fa:	ffffe097          	auipc	ra,0xffffe
    800020fe:	442080e7          	jalr	1090(ra) # 8000053c <panic>

0000000080002102 <yield>:
{
    80002102:	1101                	addi	sp,sp,-32
    80002104:	ec06                	sd	ra,24(sp)
    80002106:	e822                	sd	s0,16(sp)
    80002108:	e426                	sd	s1,8(sp)
    8000210a:	1000                	addi	s0,sp,32
	struct proc* p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	89a080e7          	jalr	-1894(ra) # 800019a6 <myproc>
    80002114:	84aa                	mv	s1,a0
	acquire(&p->lock);
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	abc080e7          	jalr	-1348(ra) # 80000bd2 <acquire>
	p->state = RUNNABLE;
    8000211e:	478d                	li	a5,3
    80002120:	cc9c                	sw	a5,24(s1)
	sched();
    80002122:	00000097          	auipc	ra,0x0
    80002126:	f0a080e7          	jalr	-246(ra) # 8000202c <sched>
	release(&p->lock);
    8000212a:	8526                	mv	a0,s1
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	b5a080e7          	jalr	-1190(ra) # 80000c86 <release>
}
    80002134:	60e2                	ld	ra,24(sp)
    80002136:	6442                	ld	s0,16(sp)
    80002138:	64a2                	ld	s1,8(sp)
    8000213a:	6105                	addi	sp,sp,32
    8000213c:	8082                	ret

000000008000213e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void* chan, struct spinlock* lk)
{
    8000213e:	7179                	addi	sp,sp,-48
    80002140:	f406                	sd	ra,40(sp)
    80002142:	f022                	sd	s0,32(sp)
    80002144:	ec26                	sd	s1,24(sp)
    80002146:	e84a                	sd	s2,16(sp)
    80002148:	e44e                	sd	s3,8(sp)
    8000214a:	1800                	addi	s0,sp,48
    8000214c:	89aa                	mv	s3,a0
    8000214e:	892e                	mv	s2,a1
	struct proc* p = myproc();
    80002150:	00000097          	auipc	ra,0x0
    80002154:	856080e7          	jalr	-1962(ra) # 800019a6 <myproc>
    80002158:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); // DOC: sleeplock1
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	a78080e7          	jalr	-1416(ra) # 80000bd2 <acquire>
	release(lk);
    80002162:	854a                	mv	a0,s2
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	b22080e7          	jalr	-1246(ra) # 80000c86 <release>

	// Go to sleep.
	p->chan = chan;
    8000216c:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    80002170:	4789                	li	a5,2
    80002172:	cc9c                	sw	a5,24(s1)

	sched();
    80002174:	00000097          	auipc	ra,0x0
    80002178:	eb8080e7          	jalr	-328(ra) # 8000202c <sched>

	// Tidy up.
	p->chan = 0;
    8000217c:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    80002180:	8526                	mv	a0,s1
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	b04080e7          	jalr	-1276(ra) # 80000c86 <release>
	acquire(lk);
    8000218a:	854a                	mv	a0,s2
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
}
    80002194:	70a2                	ld	ra,40(sp)
    80002196:	7402                	ld	s0,32(sp)
    80002198:	64e2                	ld	s1,24(sp)
    8000219a:	6942                	ld	s2,16(sp)
    8000219c:	69a2                	ld	s3,8(sp)
    8000219e:	6145                	addi	sp,sp,48
    800021a0:	8082                	ret

00000000800021a2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void* chan)
{
    800021a2:	7139                	addi	sp,sp,-64
    800021a4:	fc06                	sd	ra,56(sp)
    800021a6:	f822                	sd	s0,48(sp)
    800021a8:	f426                	sd	s1,40(sp)
    800021aa:	f04a                	sd	s2,32(sp)
    800021ac:	ec4e                	sd	s3,24(sp)
    800021ae:	e852                	sd	s4,16(sp)
    800021b0:	e456                	sd	s5,8(sp)
    800021b2:	0080                	addi	s0,sp,64
    800021b4:	8a2a                	mv	s4,a0
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    800021b6:	0000f497          	auipc	s1,0xf
    800021ba:	dea48493          	addi	s1,s1,-534 # 80010fa0 <proc>
	{
		if(p != myproc())
		{
			acquire(&p->lock);
			if(p->state == SLEEPING && p->chan == chan)
    800021be:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    800021c0:	4a8d                	li	s5,3
	for(p = proc; p < &proc[NPROC]; p++)
    800021c2:	00015917          	auipc	s2,0x15
    800021c6:	1de90913          	addi	s2,s2,478 # 800173a0 <tickslock>
    800021ca:	a811                	j	800021de <wakeup+0x3c>
			}
			release(&p->lock);
    800021cc:	8526                	mv	a0,s1
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	ab8080e7          	jalr	-1352(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    800021d6:	19048493          	addi	s1,s1,400
    800021da:	03248663          	beq	s1,s2,80002206 <wakeup+0x64>
		if(p != myproc())
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	7c8080e7          	jalr	1992(ra) # 800019a6 <myproc>
    800021e6:	fea488e3          	beq	s1,a0,800021d6 <wakeup+0x34>
			acquire(&p->lock);
    800021ea:	8526                	mv	a0,s1
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	9e6080e7          	jalr	-1562(ra) # 80000bd2 <acquire>
			if(p->state == SLEEPING && p->chan == chan)
    800021f4:	4c9c                	lw	a5,24(s1)
    800021f6:	fd379be3          	bne	a5,s3,800021cc <wakeup+0x2a>
    800021fa:	709c                	ld	a5,32(s1)
    800021fc:	fd4798e3          	bne	a5,s4,800021cc <wakeup+0x2a>
				p->state = RUNNABLE;
    80002200:	0154ac23          	sw	s5,24(s1)
    80002204:	b7e1                	j	800021cc <wakeup+0x2a>
		}
	}
}
    80002206:	70e2                	ld	ra,56(sp)
    80002208:	7442                	ld	s0,48(sp)
    8000220a:	74a2                	ld	s1,40(sp)
    8000220c:	7902                	ld	s2,32(sp)
    8000220e:	69e2                	ld	s3,24(sp)
    80002210:	6a42                	ld	s4,16(sp)
    80002212:	6aa2                	ld	s5,8(sp)
    80002214:	6121                	addi	sp,sp,64
    80002216:	8082                	ret

0000000080002218 <reparent>:
{
    80002218:	7179                	addi	sp,sp,-48
    8000221a:	f406                	sd	ra,40(sp)
    8000221c:	f022                	sd	s0,32(sp)
    8000221e:	ec26                	sd	s1,24(sp)
    80002220:	e84a                	sd	s2,16(sp)
    80002222:	e44e                	sd	s3,8(sp)
    80002224:	e052                	sd	s4,0(sp)
    80002226:	1800                	addi	s0,sp,48
    80002228:	892a                	mv	s2,a0
	for(pp = proc; pp < &proc[NPROC]; pp++)
    8000222a:	0000f497          	auipc	s1,0xf
    8000222e:	d7648493          	addi	s1,s1,-650 # 80010fa0 <proc>
			pp->parent = initproc;
    80002232:	00006a17          	auipc	s4,0x6
    80002236:	6c6a0a13          	addi	s4,s4,1734 # 800088f8 <initproc>
	for(pp = proc; pp < &proc[NPROC]; pp++)
    8000223a:	00015997          	auipc	s3,0x15
    8000223e:	16698993          	addi	s3,s3,358 # 800173a0 <tickslock>
    80002242:	a029                	j	8000224c <reparent+0x34>
    80002244:	19048493          	addi	s1,s1,400
    80002248:	01348d63          	beq	s1,s3,80002262 <reparent+0x4a>
		if(pp->parent == p)
    8000224c:	7c9c                	ld	a5,56(s1)
    8000224e:	ff279be3          	bne	a5,s2,80002244 <reparent+0x2c>
			pp->parent = initproc;
    80002252:	000a3503          	ld	a0,0(s4)
    80002256:	fc88                	sd	a0,56(s1)
			wakeup(initproc);
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	f4a080e7          	jalr	-182(ra) # 800021a2 <wakeup>
    80002260:	b7d5                	j	80002244 <reparent+0x2c>
}
    80002262:	70a2                	ld	ra,40(sp)
    80002264:	7402                	ld	s0,32(sp)
    80002266:	64e2                	ld	s1,24(sp)
    80002268:	6942                	ld	s2,16(sp)
    8000226a:	69a2                	ld	s3,8(sp)
    8000226c:	6a02                	ld	s4,0(sp)
    8000226e:	6145                	addi	sp,sp,48
    80002270:	8082                	ret

0000000080002272 <exit>:
{
    80002272:	7179                	addi	sp,sp,-48
    80002274:	f406                	sd	ra,40(sp)
    80002276:	f022                	sd	s0,32(sp)
    80002278:	ec26                	sd	s1,24(sp)
    8000227a:	e84a                	sd	s2,16(sp)
    8000227c:	e44e                	sd	s3,8(sp)
    8000227e:	e052                	sd	s4,0(sp)
    80002280:	1800                	addi	s0,sp,48
    80002282:	8a2a                	mv	s4,a0
	struct proc* p = myproc();
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	722080e7          	jalr	1826(ra) # 800019a6 <myproc>
    8000228c:	89aa                	mv	s3,a0
	if(p == initproc)
    8000228e:	00006797          	auipc	a5,0x6
    80002292:	66a7b783          	ld	a5,1642(a5) # 800088f8 <initproc>
    80002296:	0d050493          	addi	s1,a0,208
    8000229a:	15050913          	addi	s2,a0,336
    8000229e:	02a79363          	bne	a5,a0,800022c4 <exit+0x52>
		panic("init exiting");
    800022a2:	00006517          	auipc	a0,0x6
    800022a6:	fbe50513          	addi	a0,a0,-66 # 80008260 <digits+0x220>
    800022aa:	ffffe097          	auipc	ra,0xffffe
    800022ae:	292080e7          	jalr	658(ra) # 8000053c <panic>
			fileclose(f);
    800022b2:	00002097          	auipc	ra,0x2
    800022b6:	638080e7          	jalr	1592(ra) # 800048ea <fileclose>
			p->ofile[fd] = 0;
    800022ba:	0004b023          	sd	zero,0(s1)
	for(int fd = 0; fd < NOFILE; fd++)
    800022be:	04a1                	addi	s1,s1,8
    800022c0:	01248563          	beq	s1,s2,800022ca <exit+0x58>
		if(p->ofile[fd])
    800022c4:	6088                	ld	a0,0(s1)
    800022c6:	f575                	bnez	a0,800022b2 <exit+0x40>
    800022c8:	bfdd                	j	800022be <exit+0x4c>
	begin_op();
    800022ca:	00002097          	auipc	ra,0x2
    800022ce:	15c080e7          	jalr	348(ra) # 80004426 <begin_op>
	iput(p->cwd);
    800022d2:	1509b503          	ld	a0,336(s3)
    800022d6:	00002097          	auipc	ra,0x2
    800022da:	964080e7          	jalr	-1692(ra) # 80003c3a <iput>
	end_op();
    800022de:	00002097          	auipc	ra,0x2
    800022e2:	1c2080e7          	jalr	450(ra) # 800044a0 <end_op>
	p->cwd = 0;
    800022e6:	1409b823          	sd	zero,336(s3)
	acquire(&wait_lock);
    800022ea:	0000f497          	auipc	s1,0xf
    800022ee:	89e48493          	addi	s1,s1,-1890 # 80010b88 <wait_lock>
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	8de080e7          	jalr	-1826(ra) # 80000bd2 <acquire>
	reparent(p);
    800022fc:	854e                	mv	a0,s3
    800022fe:	00000097          	auipc	ra,0x0
    80002302:	f1a080e7          	jalr	-230(ra) # 80002218 <reparent>
	wakeup(p->parent);
    80002306:	0389b503          	ld	a0,56(s3)
    8000230a:	00000097          	auipc	ra,0x0
    8000230e:	e98080e7          	jalr	-360(ra) # 800021a2 <wakeup>
	acquire(&p->lock);
    80002312:	854e                	mv	a0,s3
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	8be080e7          	jalr	-1858(ra) # 80000bd2 <acquire>
	p->xstate = status;
    8000231c:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    80002320:	4795                	li	a5,5
    80002322:	00f9ac23          	sw	a5,24(s3)
	p->etime = ticks;
    80002326:	00006797          	auipc	a5,0x6
    8000232a:	5da7a783          	lw	a5,1498(a5) # 80008900 <ticks>
    8000232e:	16f9a823          	sw	a5,368(s3)
	release(&wait_lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	952080e7          	jalr	-1710(ra) # 80000c86 <release>
	sched();
    8000233c:	00000097          	auipc	ra,0x0
    80002340:	cf0080e7          	jalr	-784(ra) # 8000202c <sched>
	panic("zombie exit");
    80002344:	00006517          	auipc	a0,0x6
    80002348:	f2c50513          	addi	a0,a0,-212 # 80008270 <digits+0x230>
    8000234c:	ffffe097          	auipc	ra,0xffffe
    80002350:	1f0080e7          	jalr	496(ra) # 8000053c <panic>

0000000080002354 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002354:	7179                	addi	sp,sp,-48
    80002356:	f406                	sd	ra,40(sp)
    80002358:	f022                	sd	s0,32(sp)
    8000235a:	ec26                	sd	s1,24(sp)
    8000235c:	e84a                	sd	s2,16(sp)
    8000235e:	e44e                	sd	s3,8(sp)
    80002360:	1800                	addi	s0,sp,48
    80002362:	892a                	mv	s2,a0
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    80002364:	0000f497          	auipc	s1,0xf
    80002368:	c3c48493          	addi	s1,s1,-964 # 80010fa0 <proc>
    8000236c:	00015997          	auipc	s3,0x15
    80002370:	03498993          	addi	s3,s3,52 # 800173a0 <tickslock>
	{
		acquire(&p->lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	85c080e7          	jalr	-1956(ra) # 80000bd2 <acquire>
		if(p->pid == pid)
    8000237e:	589c                	lw	a5,48(s1)
    80002380:	01278d63          	beq	a5,s2,8000239a <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	900080e7          	jalr	-1792(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    8000238e:	19048493          	addi	s1,s1,400
    80002392:	ff3491e3          	bne	s1,s3,80002374 <kill+0x20>
	}
	return -1;
    80002396:	557d                	li	a0,-1
    80002398:	a829                	j	800023b2 <kill+0x5e>
			p->killed = 1;
    8000239a:	4785                	li	a5,1
    8000239c:	d49c                	sw	a5,40(s1)
			if(p->state == SLEEPING)
    8000239e:	4c98                	lw	a4,24(s1)
    800023a0:	4789                	li	a5,2
    800023a2:	00f70f63          	beq	a4,a5,800023c0 <kill+0x6c>
			release(&p->lock);
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	8de080e7          	jalr	-1826(ra) # 80000c86 <release>
			return 0;
    800023b0:	4501                	li	a0,0
}
    800023b2:	70a2                	ld	ra,40(sp)
    800023b4:	7402                	ld	s0,32(sp)
    800023b6:	64e2                	ld	s1,24(sp)
    800023b8:	6942                	ld	s2,16(sp)
    800023ba:	69a2                	ld	s3,8(sp)
    800023bc:	6145                	addi	sp,sp,48
    800023be:	8082                	ret
				p->state = RUNNABLE;
    800023c0:	478d                	li	a5,3
    800023c2:	cc9c                	sw	a5,24(s1)
    800023c4:	b7cd                	j	800023a6 <kill+0x52>

00000000800023c6 <setkilled>:

void setkilled(struct proc* p)
{
    800023c6:	1101                	addi	sp,sp,-32
    800023c8:	ec06                	sd	ra,24(sp)
    800023ca:	e822                	sd	s0,16(sp)
    800023cc:	e426                	sd	s1,8(sp)
    800023ce:	1000                	addi	s0,sp,32
    800023d0:	84aa                	mv	s1,a0
	acquire(&p->lock);
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	800080e7          	jalr	-2048(ra) # 80000bd2 <acquire>
	p->killed = 1;
    800023da:	4785                	li	a5,1
    800023dc:	d49c                	sw	a5,40(s1)
	release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8a6080e7          	jalr	-1882(ra) # 80000c86 <release>
}
    800023e8:	60e2                	ld	ra,24(sp)
    800023ea:	6442                	ld	s0,16(sp)
    800023ec:	64a2                	ld	s1,8(sp)
    800023ee:	6105                	addi	sp,sp,32
    800023f0:	8082                	ret

00000000800023f2 <killed>:

int killed(struct proc* p)
{
    800023f2:	1101                	addi	sp,sp,-32
    800023f4:	ec06                	sd	ra,24(sp)
    800023f6:	e822                	sd	s0,16(sp)
    800023f8:	e426                	sd	s1,8(sp)
    800023fa:	e04a                	sd	s2,0(sp)
    800023fc:	1000                	addi	s0,sp,32
    800023fe:	84aa                	mv	s1,a0
	int k;

	acquire(&p->lock);
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7d2080e7          	jalr	2002(ra) # 80000bd2 <acquire>
	k = p->killed;
    80002408:	0284a903          	lw	s2,40(s1)
	release(&p->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	878080e7          	jalr	-1928(ra) # 80000c86 <release>
	return k;
}
    80002416:	854a                	mv	a0,s2
    80002418:	60e2                	ld	ra,24(sp)
    8000241a:	6442                	ld	s0,16(sp)
    8000241c:	64a2                	ld	s1,8(sp)
    8000241e:	6902                	ld	s2,0(sp)
    80002420:	6105                	addi	sp,sp,32
    80002422:	8082                	ret

0000000080002424 <wait>:
{
    80002424:	715d                	addi	sp,sp,-80
    80002426:	e486                	sd	ra,72(sp)
    80002428:	e0a2                	sd	s0,64(sp)
    8000242a:	fc26                	sd	s1,56(sp)
    8000242c:	f84a                	sd	s2,48(sp)
    8000242e:	f44e                	sd	s3,40(sp)
    80002430:	f052                	sd	s4,32(sp)
    80002432:	ec56                	sd	s5,24(sp)
    80002434:	e85a                	sd	s6,16(sp)
    80002436:	e45e                	sd	s7,8(sp)
    80002438:	e062                	sd	s8,0(sp)
    8000243a:	0880                	addi	s0,sp,80
    8000243c:	8b2a                	mv	s6,a0
	struct proc* p = myproc();
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	568080e7          	jalr	1384(ra) # 800019a6 <myproc>
    80002446:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002448:	0000e517          	auipc	a0,0xe
    8000244c:	74050513          	addi	a0,a0,1856 # 80010b88 <wait_lock>
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	782080e7          	jalr	1922(ra) # 80000bd2 <acquire>
		havekids = 0;
    80002458:	4b81                	li	s7,0
				if(pp->state == ZOMBIE)
    8000245a:	4a15                	li	s4,5
				havekids = 1;
    8000245c:	4a85                	li	s5,1
		for(pp = proc; pp < &proc[NPROC]; pp++)
    8000245e:	00015997          	auipc	s3,0x15
    80002462:	f4298993          	addi	s3,s3,-190 # 800173a0 <tickslock>
		sleep(p, &wait_lock); // DOC: wait-sleep
    80002466:	0000ec17          	auipc	s8,0xe
    8000246a:	722c0c13          	addi	s8,s8,1826 # 80010b88 <wait_lock>
    8000246e:	a0d1                	j	80002532 <wait+0x10e>
					pid = pp->pid;
    80002470:	0304a983          	lw	s3,48(s1)
					if(addr != 0 &&
    80002474:	000b0e63          	beqz	s6,80002490 <wait+0x6c>
					   copyout(p->pagetable, addr, (char*)&pp->xstate, sizeof(pp->xstate)) < 0)
    80002478:	4691                	li	a3,4
    8000247a:	02c48613          	addi	a2,s1,44
    8000247e:	85da                	mv	a1,s6
    80002480:	05093503          	ld	a0,80(s2)
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	1e2080e7          	jalr	482(ra) # 80001666 <copyout>
					if(addr != 0 &&
    8000248c:	04054163          	bltz	a0,800024ce <wait+0xaa>
					freeproc(pp);
    80002490:	8526                	mv	a0,s1
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	72c080e7          	jalr	1836(ra) # 80001bbe <freeproc>
					release(&pp->lock);
    8000249a:	8526                	mv	a0,s1
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	7ea080e7          	jalr	2026(ra) # 80000c86 <release>
					release(&wait_lock);
    800024a4:	0000e517          	auipc	a0,0xe
    800024a8:	6e450513          	addi	a0,a0,1764 # 80010b88 <wait_lock>
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	7da080e7          	jalr	2010(ra) # 80000c86 <release>
}
    800024b4:	854e                	mv	a0,s3
    800024b6:	60a6                	ld	ra,72(sp)
    800024b8:	6406                	ld	s0,64(sp)
    800024ba:	74e2                	ld	s1,56(sp)
    800024bc:	7942                	ld	s2,48(sp)
    800024be:	79a2                	ld	s3,40(sp)
    800024c0:	7a02                	ld	s4,32(sp)
    800024c2:	6ae2                	ld	s5,24(sp)
    800024c4:	6b42                	ld	s6,16(sp)
    800024c6:	6ba2                	ld	s7,8(sp)
    800024c8:	6c02                	ld	s8,0(sp)
    800024ca:	6161                	addi	sp,sp,80
    800024cc:	8082                	ret
						release(&pp->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	7b6080e7          	jalr	1974(ra) # 80000c86 <release>
						release(&wait_lock);
    800024d8:	0000e517          	auipc	a0,0xe
    800024dc:	6b050513          	addi	a0,a0,1712 # 80010b88 <wait_lock>
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7a6080e7          	jalr	1958(ra) # 80000c86 <release>
						return -1;
    800024e8:	59fd                	li	s3,-1
    800024ea:	b7e9                	j	800024b4 <wait+0x90>
		for(pp = proc; pp < &proc[NPROC]; pp++)
    800024ec:	19048493          	addi	s1,s1,400
    800024f0:	03348463          	beq	s1,s3,80002518 <wait+0xf4>
			if(pp->parent == p)
    800024f4:	7c9c                	ld	a5,56(s1)
    800024f6:	ff279be3          	bne	a5,s2,800024ec <wait+0xc8>
				acquire(&pp->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	6d6080e7          	jalr	1750(ra) # 80000bd2 <acquire>
				if(pp->state == ZOMBIE)
    80002504:	4c9c                	lw	a5,24(s1)
    80002506:	f74785e3          	beq	a5,s4,80002470 <wait+0x4c>
				release(&pp->lock);
    8000250a:	8526                	mv	a0,s1
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	77a080e7          	jalr	1914(ra) # 80000c86 <release>
				havekids = 1;
    80002514:	8756                	mv	a4,s5
    80002516:	bfd9                	j	800024ec <wait+0xc8>
		if(!havekids || killed(p))
    80002518:	c31d                	beqz	a4,8000253e <wait+0x11a>
    8000251a:	854a                	mv	a0,s2
    8000251c:	00000097          	auipc	ra,0x0
    80002520:	ed6080e7          	jalr	-298(ra) # 800023f2 <killed>
    80002524:	ed09                	bnez	a0,8000253e <wait+0x11a>
		sleep(p, &wait_lock); // DOC: wait-sleep
    80002526:	85e2                	mv	a1,s8
    80002528:	854a                	mv	a0,s2
    8000252a:	00000097          	auipc	ra,0x0
    8000252e:	c14080e7          	jalr	-1004(ra) # 8000213e <sleep>
		havekids = 0;
    80002532:	875e                	mv	a4,s7
		for(pp = proc; pp < &proc[NPROC]; pp++)
    80002534:	0000f497          	auipc	s1,0xf
    80002538:	a6c48493          	addi	s1,s1,-1428 # 80010fa0 <proc>
    8000253c:	bf65                	j	800024f4 <wait+0xd0>
			release(&wait_lock);
    8000253e:	0000e517          	auipc	a0,0xe
    80002542:	64a50513          	addi	a0,a0,1610 # 80010b88 <wait_lock>
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	740080e7          	jalr	1856(ra) # 80000c86 <release>
			return -1;
    8000254e:	59fd                	li	s3,-1
    80002550:	b795                	j	800024b4 <wait+0x90>

0000000080002552 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void* src, uint64 len)
{
    80002552:	7179                	addi	sp,sp,-48
    80002554:	f406                	sd	ra,40(sp)
    80002556:	f022                	sd	s0,32(sp)
    80002558:	ec26                	sd	s1,24(sp)
    8000255a:	e84a                	sd	s2,16(sp)
    8000255c:	e44e                	sd	s3,8(sp)
    8000255e:	e052                	sd	s4,0(sp)
    80002560:	1800                	addi	s0,sp,48
    80002562:	84aa                	mv	s1,a0
    80002564:	892e                	mv	s2,a1
    80002566:	89b2                	mv	s3,a2
    80002568:	8a36                	mv	s4,a3
	struct proc* p = myproc();
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	43c080e7          	jalr	1084(ra) # 800019a6 <myproc>
	if(user_dst)
    80002572:	c08d                	beqz	s1,80002594 <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    80002574:	86d2                	mv	a3,s4
    80002576:	864e                	mv	a2,s3
    80002578:	85ca                	mv	a1,s2
    8000257a:	6928                	ld	a0,80(a0)
    8000257c:	fffff097          	auipc	ra,0xfffff
    80002580:	0ea080e7          	jalr	234(ra) # 80001666 <copyout>
	else
	{
		memmove((char*)dst, src, len);
		return 0;
	}
}
    80002584:	70a2                	ld	ra,40(sp)
    80002586:	7402                	ld	s0,32(sp)
    80002588:	64e2                	ld	s1,24(sp)
    8000258a:	6942                	ld	s2,16(sp)
    8000258c:	69a2                	ld	s3,8(sp)
    8000258e:	6a02                	ld	s4,0(sp)
    80002590:	6145                	addi	sp,sp,48
    80002592:	8082                	ret
		memmove((char*)dst, src, len);
    80002594:	000a061b          	sext.w	a2,s4
    80002598:	85ce                	mv	a1,s3
    8000259a:	854a                	mv	a0,s2
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	78e080e7          	jalr	1934(ra) # 80000d2a <memmove>
		return 0;
    800025a4:	8526                	mv	a0,s1
    800025a6:	bff9                	j	80002584 <either_copyout+0x32>

00000000800025a8 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void* dst, int user_src, uint64 src, uint64 len)
{
    800025a8:	7179                	addi	sp,sp,-48
    800025aa:	f406                	sd	ra,40(sp)
    800025ac:	f022                	sd	s0,32(sp)
    800025ae:	ec26                	sd	s1,24(sp)
    800025b0:	e84a                	sd	s2,16(sp)
    800025b2:	e44e                	sd	s3,8(sp)
    800025b4:	e052                	sd	s4,0(sp)
    800025b6:	1800                	addi	s0,sp,48
    800025b8:	892a                	mv	s2,a0
    800025ba:	84ae                	mv	s1,a1
    800025bc:	89b2                	mv	s3,a2
    800025be:	8a36                	mv	s4,a3
	struct proc* p = myproc();
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	3e6080e7          	jalr	998(ra) # 800019a6 <myproc>
	if(user_src)
    800025c8:	c08d                	beqz	s1,800025ea <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    800025ca:	86d2                	mv	a3,s4
    800025cc:	864e                	mv	a2,s3
    800025ce:	85ca                	mv	a1,s2
    800025d0:	6928                	ld	a0,80(a0)
    800025d2:	fffff097          	auipc	ra,0xfffff
    800025d6:	120080e7          	jalr	288(ra) # 800016f2 <copyin>
	else
	{
		memmove(dst, (char*)src, len);
		return 0;
	}
}
    800025da:	70a2                	ld	ra,40(sp)
    800025dc:	7402                	ld	s0,32(sp)
    800025de:	64e2                	ld	s1,24(sp)
    800025e0:	6942                	ld	s2,16(sp)
    800025e2:	69a2                	ld	s3,8(sp)
    800025e4:	6a02                	ld	s4,0(sp)
    800025e6:	6145                	addi	sp,sp,48
    800025e8:	8082                	ret
		memmove(dst, (char*)src, len);
    800025ea:	000a061b          	sext.w	a2,s4
    800025ee:	85ce                	mv	a1,s3
    800025f0:	854a                	mv	a0,s2
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	738080e7          	jalr	1848(ra) # 80000d2a <memmove>
		return 0;
    800025fa:	8526                	mv	a0,s1
    800025fc:	bff9                	j	800025da <either_copyin+0x32>

00000000800025fe <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800025fe:	715d                	addi	sp,sp,-80
    80002600:	e486                	sd	ra,72(sp)
    80002602:	e0a2                	sd	s0,64(sp)
    80002604:	fc26                	sd	s1,56(sp)
    80002606:	f84a                	sd	s2,48(sp)
    80002608:	f44e                	sd	s3,40(sp)
    8000260a:	f052                	sd	s4,32(sp)
    8000260c:	ec56                	sd	s5,24(sp)
    8000260e:	e85a                	sd	s6,16(sp)
    80002610:	e45e                	sd	s7,8(sp)
    80002612:	0880                	addi	s0,sp,80
							 [RUNNING] "run   ",
							 [ZOMBIE] "zombie"};
	struct proc* p;
	char* state;

	printf("\n");
    80002614:	00006517          	auipc	a0,0x6
    80002618:	ab450513          	addi	a0,a0,-1356 # 800080c8 <digits+0x88>
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	f6a080e7          	jalr	-150(ra) # 80000586 <printf>
	for(p = proc; p < &proc[NPROC]; p++)
    80002624:	0000f497          	auipc	s1,0xf
    80002628:	ad448493          	addi	s1,s1,-1324 # 800110f8 <proc+0x158>
    8000262c:	00015917          	auipc	s2,0x15
    80002630:	ecc90913          	addi	s2,s2,-308 # 800174f8 <bcache+0x140>
	{
		if(p->state == UNUSED)
			continue;
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002634:	4b15                	li	s6,5
			state = states[p->state];
		else
			state = "???";
    80002636:	00006997          	auipc	s3,0x6
    8000263a:	c4a98993          	addi	s3,s3,-950 # 80008280 <digits+0x240>
		printf("%d %s %s", p->pid, state, p->name);
    8000263e:	00006a97          	auipc	s5,0x6
    80002642:	c4aa8a93          	addi	s5,s5,-950 # 80008288 <digits+0x248>
		printf("\n");
    80002646:	00006a17          	auipc	s4,0x6
    8000264a:	a82a0a13          	addi	s4,s4,-1406 # 800080c8 <digits+0x88>
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000264e:	00006b97          	auipc	s7,0x6
    80002652:	c7ab8b93          	addi	s7,s7,-902 # 800082c8 <states.0>
    80002656:	a00d                	j	80002678 <procdump+0x7a>
		printf("%d %s %s", p->pid, state, p->name);
    80002658:	ed86a583          	lw	a1,-296(a3)
    8000265c:	8556                	mv	a0,s5
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	f28080e7          	jalr	-216(ra) # 80000586 <printf>
		printf("\n");
    80002666:	8552                	mv	a0,s4
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	f1e080e7          	jalr	-226(ra) # 80000586 <printf>
	for(p = proc; p < &proc[NPROC]; p++)
    80002670:	19048493          	addi	s1,s1,400
    80002674:	03248263          	beq	s1,s2,80002698 <procdump+0x9a>
		if(p->state == UNUSED)
    80002678:	86a6                	mv	a3,s1
    8000267a:	ec04a783          	lw	a5,-320(s1)
    8000267e:	dbed                	beqz	a5,80002670 <procdump+0x72>
			state = "???";
    80002680:	864e                	mv	a2,s3
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002682:	fcfb6be3          	bltu	s6,a5,80002658 <procdump+0x5a>
    80002686:	02079713          	slli	a4,a5,0x20
    8000268a:	01d75793          	srli	a5,a4,0x1d
    8000268e:	97de                	add	a5,a5,s7
    80002690:	6390                	ld	a2,0(a5)
    80002692:	f279                	bnez	a2,80002658 <procdump+0x5a>
			state = "???";
    80002694:	864e                	mv	a2,s3
    80002696:	b7c9                	j	80002658 <procdump+0x5a>
	}
}
    80002698:	60a6                	ld	ra,72(sp)
    8000269a:	6406                	ld	s0,64(sp)
    8000269c:	74e2                	ld	s1,56(sp)
    8000269e:	7942                	ld	s2,48(sp)
    800026a0:	79a2                	ld	s3,40(sp)
    800026a2:	7a02                	ld	s4,32(sp)
    800026a4:	6ae2                	ld	s5,24(sp)
    800026a6:	6b42                	ld	s6,16(sp)
    800026a8:	6ba2                	ld	s7,8(sp)
    800026aa:	6161                	addi	sp,sp,80
    800026ac:	8082                	ret

00000000800026ae <waitx>:

// waitx
int waitx(uint64 addr, uint* wtime, uint* rtime)
{
    800026ae:	711d                	addi	sp,sp,-96
    800026b0:	ec86                	sd	ra,88(sp)
    800026b2:	e8a2                	sd	s0,80(sp)
    800026b4:	e4a6                	sd	s1,72(sp)
    800026b6:	e0ca                	sd	s2,64(sp)
    800026b8:	fc4e                	sd	s3,56(sp)
    800026ba:	f852                	sd	s4,48(sp)
    800026bc:	f456                	sd	s5,40(sp)
    800026be:	f05a                	sd	s6,32(sp)
    800026c0:	ec5e                	sd	s7,24(sp)
    800026c2:	e862                	sd	s8,16(sp)
    800026c4:	e466                	sd	s9,8(sp)
    800026c6:	e06a                	sd	s10,0(sp)
    800026c8:	1080                	addi	s0,sp,96
    800026ca:	8b2a                	mv	s6,a0
    800026cc:	8bae                	mv	s7,a1
    800026ce:	8c32                	mv	s8,a2
	struct proc* np;
	int havekids, pid;
	struct proc* p = myproc();
    800026d0:	fffff097          	auipc	ra,0xfffff
    800026d4:	2d6080e7          	jalr	726(ra) # 800019a6 <myproc>
    800026d8:	892a                	mv	s2,a0

	acquire(&wait_lock);
    800026da:	0000e517          	auipc	a0,0xe
    800026de:	4ae50513          	addi	a0,a0,1198 # 80010b88 <wait_lock>
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	4f0080e7          	jalr	1264(ra) # 80000bd2 <acquire>

	for(;;)
	{
		// Scan through table looking for exited children.
		havekids = 0;
    800026ea:	4c81                	li	s9,0
			{
				// make sure the child isn't still in exit() or swtch().
				acquire(&np->lock);

				havekids = 1;
				if(np->state == ZOMBIE)
    800026ec:	4a15                	li	s4,5
				havekids = 1;
    800026ee:	4a85                	li	s5,1
		for(np = proc; np < &proc[NPROC]; np++)
    800026f0:	00015997          	auipc	s3,0x15
    800026f4:	cb098993          	addi	s3,s3,-848 # 800173a0 <tickslock>
			release(&wait_lock);
			return -1;
		}

		// Wait for a child to exit.
		sleep(p, &wait_lock); // DOC: wait-sleep
    800026f8:	0000ed17          	auipc	s10,0xe
    800026fc:	490d0d13          	addi	s10,s10,1168 # 80010b88 <wait_lock>
    80002700:	a8e9                	j	800027da <waitx+0x12c>
					pid = np->pid;
    80002702:	0304a983          	lw	s3,48(s1)
					*rtime = np->rtime;
    80002706:	1684a783          	lw	a5,360(s1)
    8000270a:	00fc2023          	sw	a5,0(s8)
					*wtime = np->etime - np->ctime - np->rtime;
    8000270e:	16c4a703          	lw	a4,364(s1)
    80002712:	9f3d                	addw	a4,a4,a5
    80002714:	1704a783          	lw	a5,368(s1)
    80002718:	9f99                	subw	a5,a5,a4
    8000271a:	00fba023          	sw	a5,0(s7)
					if(addr != 0 &&
    8000271e:	000b0e63          	beqz	s6,8000273a <waitx+0x8c>
					   copyout(p->pagetable, addr, (char*)&np->xstate, sizeof(np->xstate)) < 0)
    80002722:	4691                	li	a3,4
    80002724:	02c48613          	addi	a2,s1,44
    80002728:	85da                	mv	a1,s6
    8000272a:	05093503          	ld	a0,80(s2)
    8000272e:	fffff097          	auipc	ra,0xfffff
    80002732:	f38080e7          	jalr	-200(ra) # 80001666 <copyout>
					if(addr != 0 &&
    80002736:	04054363          	bltz	a0,8000277c <waitx+0xce>
					freeproc(np);
    8000273a:	8526                	mv	a0,s1
    8000273c:	fffff097          	auipc	ra,0xfffff
    80002740:	482080e7          	jalr	1154(ra) # 80001bbe <freeproc>
					release(&np->lock);
    80002744:	8526                	mv	a0,s1
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	540080e7          	jalr	1344(ra) # 80000c86 <release>
					release(&wait_lock);
    8000274e:	0000e517          	auipc	a0,0xe
    80002752:	43a50513          	addi	a0,a0,1082 # 80010b88 <wait_lock>
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	530080e7          	jalr	1328(ra) # 80000c86 <release>
	}
}
    8000275e:	854e                	mv	a0,s3
    80002760:	60e6                	ld	ra,88(sp)
    80002762:	6446                	ld	s0,80(sp)
    80002764:	64a6                	ld	s1,72(sp)
    80002766:	6906                	ld	s2,64(sp)
    80002768:	79e2                	ld	s3,56(sp)
    8000276a:	7a42                	ld	s4,48(sp)
    8000276c:	7aa2                	ld	s5,40(sp)
    8000276e:	7b02                	ld	s6,32(sp)
    80002770:	6be2                	ld	s7,24(sp)
    80002772:	6c42                	ld	s8,16(sp)
    80002774:	6ca2                	ld	s9,8(sp)
    80002776:	6d02                	ld	s10,0(sp)
    80002778:	6125                	addi	sp,sp,96
    8000277a:	8082                	ret
						release(&np->lock);
    8000277c:	8526                	mv	a0,s1
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	508080e7          	jalr	1288(ra) # 80000c86 <release>
						release(&wait_lock);
    80002786:	0000e517          	auipc	a0,0xe
    8000278a:	40250513          	addi	a0,a0,1026 # 80010b88 <wait_lock>
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	4f8080e7          	jalr	1272(ra) # 80000c86 <release>
						return -1;
    80002796:	59fd                	li	s3,-1
    80002798:	b7d9                	j	8000275e <waitx+0xb0>
		for(np = proc; np < &proc[NPROC]; np++)
    8000279a:	19048493          	addi	s1,s1,400
    8000279e:	03348463          	beq	s1,s3,800027c6 <waitx+0x118>
			if(np->parent == p)
    800027a2:	7c9c                	ld	a5,56(s1)
    800027a4:	ff279be3          	bne	a5,s2,8000279a <waitx+0xec>
				acquire(&np->lock);
    800027a8:	8526                	mv	a0,s1
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	428080e7          	jalr	1064(ra) # 80000bd2 <acquire>
				if(np->state == ZOMBIE)
    800027b2:	4c9c                	lw	a5,24(s1)
    800027b4:	f54787e3          	beq	a5,s4,80002702 <waitx+0x54>
				release(&np->lock);
    800027b8:	8526                	mv	a0,s1
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	4cc080e7          	jalr	1228(ra) # 80000c86 <release>
				havekids = 1;
    800027c2:	8756                	mv	a4,s5
    800027c4:	bfd9                	j	8000279a <waitx+0xec>
		if(!havekids || p->killed)
    800027c6:	c305                	beqz	a4,800027e6 <waitx+0x138>
    800027c8:	02892783          	lw	a5,40(s2)
    800027cc:	ef89                	bnez	a5,800027e6 <waitx+0x138>
		sleep(p, &wait_lock); // DOC: wait-sleep
    800027ce:	85ea                	mv	a1,s10
    800027d0:	854a                	mv	a0,s2
    800027d2:	00000097          	auipc	ra,0x0
    800027d6:	96c080e7          	jalr	-1684(ra) # 8000213e <sleep>
		havekids = 0;
    800027da:	8766                	mv	a4,s9
		for(np = proc; np < &proc[NPROC]; np++)
    800027dc:	0000e497          	auipc	s1,0xe
    800027e0:	7c448493          	addi	s1,s1,1988 # 80010fa0 <proc>
    800027e4:	bf7d                	j	800027a2 <waitx+0xf4>
			release(&wait_lock);
    800027e6:	0000e517          	auipc	a0,0xe
    800027ea:	3a250513          	addi	a0,a0,930 # 80010b88 <wait_lock>
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	498080e7          	jalr	1176(ra) # 80000c86 <release>
			return -1;
    800027f6:	59fd                	li	s3,-1
    800027f8:	b79d                	j	8000275e <waitx+0xb0>

00000000800027fa <update_time>:

void update_time()
{
    800027fa:	7179                	addi	sp,sp,-48
    800027fc:	f406                	sd	ra,40(sp)
    800027fe:	f022                	sd	s0,32(sp)
    80002800:	ec26                	sd	s1,24(sp)
    80002802:	e84a                	sd	s2,16(sp)
    80002804:	e44e                	sd	s3,8(sp)
    80002806:	1800                	addi	s0,sp,48
	struct proc* p;
	for(p = proc; p < &proc[NPROC]; p++)
    80002808:	0000e497          	auipc	s1,0xe
    8000280c:	79848493          	addi	s1,s1,1944 # 80010fa0 <proc>
	{
		acquire(&p->lock);
		if(p->state == RUNNING)
    80002810:	4991                	li	s3,4
	for(p = proc; p < &proc[NPROC]; p++)
    80002812:	00015917          	auipc	s2,0x15
    80002816:	b8e90913          	addi	s2,s2,-1138 # 800173a0 <tickslock>
    8000281a:	a811                	j	8000282e <update_time+0x34>
		{
			p->rtime++;
		}
		release(&p->lock);
    8000281c:	8526                	mv	a0,s1
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	468080e7          	jalr	1128(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    80002826:	19048493          	addi	s1,s1,400
    8000282a:	03248063          	beq	s1,s2,8000284a <update_time+0x50>
		acquire(&p->lock);
    8000282e:	8526                	mv	a0,s1
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	3a2080e7          	jalr	930(ra) # 80000bd2 <acquire>
		if(p->state == RUNNING)
    80002838:	4c9c                	lw	a5,24(s1)
    8000283a:	ff3791e3          	bne	a5,s3,8000281c <update_time+0x22>
			p->rtime++;
    8000283e:	1684a783          	lw	a5,360(s1)
    80002842:	2785                	addiw	a5,a5,1
    80002844:	16f4a423          	sw	a5,360(s1)
    80002848:	bfd1                	j	8000281c <update_time+0x22>
	}
    8000284a:	70a2                	ld	ra,40(sp)
    8000284c:	7402                	ld	s0,32(sp)
    8000284e:	64e2                	ld	s1,24(sp)
    80002850:	6942                	ld	s2,16(sp)
    80002852:	69a2                	ld	s3,8(sp)
    80002854:	6145                	addi	sp,sp,48
    80002856:	8082                	ret

0000000080002858 <swtch>:
    80002858:	00153023          	sd	ra,0(a0)
    8000285c:	00253423          	sd	sp,8(a0)
    80002860:	e900                	sd	s0,16(a0)
    80002862:	ed04                	sd	s1,24(a0)
    80002864:	03253023          	sd	s2,32(a0)
    80002868:	03353423          	sd	s3,40(a0)
    8000286c:	03453823          	sd	s4,48(a0)
    80002870:	03553c23          	sd	s5,56(a0)
    80002874:	05653023          	sd	s6,64(a0)
    80002878:	05753423          	sd	s7,72(a0)
    8000287c:	05853823          	sd	s8,80(a0)
    80002880:	05953c23          	sd	s9,88(a0)
    80002884:	07a53023          	sd	s10,96(a0)
    80002888:	07b53423          	sd	s11,104(a0)
    8000288c:	0005b083          	ld	ra,0(a1)
    80002890:	0085b103          	ld	sp,8(a1)
    80002894:	6980                	ld	s0,16(a1)
    80002896:	6d84                	ld	s1,24(a1)
    80002898:	0205b903          	ld	s2,32(a1)
    8000289c:	0285b983          	ld	s3,40(a1)
    800028a0:	0305ba03          	ld	s4,48(a1)
    800028a4:	0385ba83          	ld	s5,56(a1)
    800028a8:	0405bb03          	ld	s6,64(a1)
    800028ac:	0485bb83          	ld	s7,72(a1)
    800028b0:	0505bc03          	ld	s8,80(a1)
    800028b4:	0585bc83          	ld	s9,88(a1)
    800028b8:	0605bd03          	ld	s10,96(a1)
    800028bc:	0685bd83          	ld	s11,104(a1)
    800028c0:	8082                	ret

00000000800028c2 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800028c2:	1141                	addi	sp,sp,-16
    800028c4:	e406                	sd	ra,8(sp)
    800028c6:	e022                	sd	s0,0(sp)
    800028c8:	0800                	addi	s0,sp,16
	initlock(&tickslock, "time");
    800028ca:	00006597          	auipc	a1,0x6
    800028ce:	a2e58593          	addi	a1,a1,-1490 # 800082f8 <states.0+0x30>
    800028d2:	00015517          	auipc	a0,0x15
    800028d6:	ace50513          	addi	a0,a0,-1330 # 800173a0 <tickslock>
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	268080e7          	jalr	616(ra) # 80000b42 <initlock>
}
    800028e2:	60a2                	ld	ra,8(sp)
    800028e4:	6402                	ld	s0,0(sp)
    800028e6:	0141                	addi	sp,sp,16
    800028e8:	8082                	ret

00000000800028ea <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800028ea:	1141                	addi	sp,sp,-16
    800028ec:	e422                	sd	s0,8(sp)
    800028ee:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f0:	00003797          	auipc	a5,0x3
    800028f4:	63078793          	addi	a5,a5,1584 # 80005f20 <kernelvec>
    800028f8:	10579073          	csrw	stvec,a5
	w_stvec((uint64)kernelvec);
}
    800028fc:	6422                	ld	s0,8(sp)
    800028fe:	0141                	addi	sp,sp,16
    80002900:	8082                	ret

0000000080002902 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002902:	1141                	addi	sp,sp,-16
    80002904:	e406                	sd	ra,8(sp)
    80002906:	e022                	sd	s0,0(sp)
    80002908:	0800                	addi	s0,sp,16
	struct proc *p = myproc();
    8000290a:	fffff097          	auipc	ra,0xfffff
    8000290e:	09c080e7          	jalr	156(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002912:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002916:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002918:	10079073          	csrw	sstatus,a5
	// kerneltrap() to usertrap(), so turn off interrupts until
	// we're back in user space, where usertrap() is correct.
	intr_off();

	// send syscalls, interrupts, and exceptions to uservec in trampoline.S
	uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000291c:	00004697          	auipc	a3,0x4
    80002920:	6e468693          	addi	a3,a3,1764 # 80007000 <_trampoline>
    80002924:	00004717          	auipc	a4,0x4
    80002928:	6dc70713          	addi	a4,a4,1756 # 80007000 <_trampoline>
    8000292c:	8f15                	sub	a4,a4,a3
    8000292e:	040007b7          	lui	a5,0x4000
    80002932:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002934:	07b2                	slli	a5,a5,0xc
    80002936:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002938:	10571073          	csrw	stvec,a4
	w_stvec(trampoline_uservec);

	// set up trapframe values that uservec will need when
	// the process next traps into the kernel.
	p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000293c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000293e:	18002673          	csrr	a2,satp
    80002942:	e310                	sd	a2,0(a4)
	p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002944:	6d30                	ld	a2,88(a0)
    80002946:	6138                	ld	a4,64(a0)
    80002948:	6585                	lui	a1,0x1
    8000294a:	972e                	add	a4,a4,a1
    8000294c:	e618                	sd	a4,8(a2)
	p->trapframe->kernel_trap = (uint64)usertrap;
    8000294e:	6d38                	ld	a4,88(a0)
    80002950:	00000617          	auipc	a2,0x0
    80002954:	14260613          	addi	a2,a2,322 # 80002a92 <usertrap>
    80002958:	eb10                	sd	a2,16(a4)
	p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    8000295a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000295c:	8612                	mv	a2,tp
    8000295e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002960:	10002773          	csrr	a4,sstatus
	// set up the registers that trampoline.S's sret will use
	// to get to user space.

	// set S Previous Privilege mode to User.
	unsigned long x = r_sstatus();
	x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002964:	eff77713          	andi	a4,a4,-257
	x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002968:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000296c:	10071073          	csrw	sstatus,a4
	w_sstatus(x);

	// set S Exception Program Counter to the saved user pc.
	w_sepc(p->trapframe->epc);
    80002970:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002972:	6f18                	ld	a4,24(a4)
    80002974:	14171073          	csrw	sepc,a4

	// tell trampoline.S the user page table to switch to.
	uint64 satp = MAKE_SATP(p->pagetable);
    80002978:	6928                	ld	a0,80(a0)
    8000297a:	8131                	srli	a0,a0,0xc

	// jump to userret in trampoline.S at the top of memory, which
	// switches to the user page table, restores user registers,
	// and switches to user mode with sret.
	uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000297c:	00004717          	auipc	a4,0x4
    80002980:	72070713          	addi	a4,a4,1824 # 8000709c <userret>
    80002984:	8f15                	sub	a4,a4,a3
    80002986:	97ba                	add	a5,a5,a4
	((void (*)(uint64))trampoline_userret)(satp);
    80002988:	577d                	li	a4,-1
    8000298a:	177e                	slli	a4,a4,0x3f
    8000298c:	8d59                	or	a0,a0,a4
    8000298e:	9782                	jalr	a5
}
    80002990:	60a2                	ld	ra,8(sp)
    80002992:	6402                	ld	s0,0(sp)
    80002994:	0141                	addi	sp,sp,16
    80002996:	8082                	ret

0000000080002998 <clockintr>:
	w_sepc(sepc);
	w_sstatus(sstatus);
}

void clockintr()
{
    80002998:	1101                	addi	sp,sp,-32
    8000299a:	ec06                	sd	ra,24(sp)
    8000299c:	e822                	sd	s0,16(sp)
    8000299e:	e426                	sd	s1,8(sp)
    800029a0:	e04a                	sd	s2,0(sp)
    800029a2:	1000                	addi	s0,sp,32
	acquire(&tickslock);
    800029a4:	00015917          	auipc	s2,0x15
    800029a8:	9fc90913          	addi	s2,s2,-1540 # 800173a0 <tickslock>
    800029ac:	854a                	mv	a0,s2
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	224080e7          	jalr	548(ra) # 80000bd2 <acquire>
	ticks++;
    800029b6:	00006497          	auipc	s1,0x6
    800029ba:	f4a48493          	addi	s1,s1,-182 # 80008900 <ticks>
    800029be:	409c                	lw	a5,0(s1)
    800029c0:	2785                	addiw	a5,a5,1
    800029c2:	c09c                	sw	a5,0(s1)
	update_time();
    800029c4:	00000097          	auipc	ra,0x0
    800029c8:	e36080e7          	jalr	-458(ra) # 800027fa <update_time>
	//   // {
	//   //   p->wtime++;
	//   // }
	//   release(&p->lock);
	// }
	wakeup(&ticks);
    800029cc:	8526                	mv	a0,s1
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	7d4080e7          	jalr	2004(ra) # 800021a2 <wakeup>
	release(&tickslock);
    800029d6:	854a                	mv	a0,s2
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	2ae080e7          	jalr	686(ra) # 80000c86 <release>
}
    800029e0:	60e2                	ld	ra,24(sp)
    800029e2:	6442                	ld	s0,16(sp)
    800029e4:	64a2                	ld	s1,8(sp)
    800029e6:	6902                	ld	s2,0(sp)
    800029e8:	6105                	addi	sp,sp,32
    800029ea:	8082                	ret

00000000800029ec <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ec:	142027f3          	csrr	a5,scause

		return 2;
	}
	else
	{
		return 0;
    800029f0:	4501                	li	a0,0
	if ((scause & 0x8000000000000000L) &&
    800029f2:	0807df63          	bgez	a5,80002a90 <devintr+0xa4>
{
    800029f6:	1101                	addi	sp,sp,-32
    800029f8:	ec06                	sd	ra,24(sp)
    800029fa:	e822                	sd	s0,16(sp)
    800029fc:	e426                	sd	s1,8(sp)
    800029fe:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    80002a00:	0ff7f713          	zext.b	a4,a5
	if ((scause & 0x8000000000000000L) &&
    80002a04:	46a5                	li	a3,9
    80002a06:	00d70d63          	beq	a4,a3,80002a20 <devintr+0x34>
	else if (scause == 0x8000000000000001L)
    80002a0a:	577d                	li	a4,-1
    80002a0c:	177e                	slli	a4,a4,0x3f
    80002a0e:	0705                	addi	a4,a4,1
		return 0;
    80002a10:	4501                	li	a0,0
	else if (scause == 0x8000000000000001L)
    80002a12:	04e78e63          	beq	a5,a4,80002a6e <devintr+0x82>
	}
}
    80002a16:	60e2                	ld	ra,24(sp)
    80002a18:	6442                	ld	s0,16(sp)
    80002a1a:	64a2                	ld	s1,8(sp)
    80002a1c:	6105                	addi	sp,sp,32
    80002a1e:	8082                	ret
		int irq = plic_claim();
    80002a20:	00003097          	auipc	ra,0x3
    80002a24:	608080e7          	jalr	1544(ra) # 80006028 <plic_claim>
    80002a28:	84aa                	mv	s1,a0
		if (irq == UART0_IRQ)
    80002a2a:	47a9                	li	a5,10
    80002a2c:	02f50763          	beq	a0,a5,80002a5a <devintr+0x6e>
		else if (irq == VIRTIO0_IRQ)
    80002a30:	4785                	li	a5,1
    80002a32:	02f50963          	beq	a0,a5,80002a64 <devintr+0x78>
		return 1;
    80002a36:	4505                	li	a0,1
		else if (irq)
    80002a38:	dcf9                	beqz	s1,80002a16 <devintr+0x2a>
			printf("unexpected interrupt irq=%d\n", irq);
    80002a3a:	85a6                	mv	a1,s1
    80002a3c:	00006517          	auipc	a0,0x6
    80002a40:	8c450513          	addi	a0,a0,-1852 # 80008300 <states.0+0x38>
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	b42080e7          	jalr	-1214(ra) # 80000586 <printf>
			plic_complete(irq);
    80002a4c:	8526                	mv	a0,s1
    80002a4e:	00003097          	auipc	ra,0x3
    80002a52:	5fe080e7          	jalr	1534(ra) # 8000604c <plic_complete>
		return 1;
    80002a56:	4505                	li	a0,1
    80002a58:	bf7d                	j	80002a16 <devintr+0x2a>
			uartintr();
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	f3a080e7          	jalr	-198(ra) # 80000994 <uartintr>
		if (irq)
    80002a62:	b7ed                	j	80002a4c <devintr+0x60>
			virtio_disk_intr();
    80002a64:	00004097          	auipc	ra,0x4
    80002a68:	aae080e7          	jalr	-1362(ra) # 80006512 <virtio_disk_intr>
		if (irq)
    80002a6c:	b7c5                	j	80002a4c <devintr+0x60>
		if (cpuid() == 0)
    80002a6e:	fffff097          	auipc	ra,0xfffff
    80002a72:	f0c080e7          	jalr	-244(ra) # 8000197a <cpuid>
    80002a76:	c901                	beqz	a0,80002a86 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a78:	144027f3          	csrr	a5,sip
		w_sip(r_sip() & ~2);
    80002a7c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a7e:	14479073          	csrw	sip,a5
		return 2;
    80002a82:	4509                	li	a0,2
    80002a84:	bf49                	j	80002a16 <devintr+0x2a>
			clockintr();
    80002a86:	00000097          	auipc	ra,0x0
    80002a8a:	f12080e7          	jalr	-238(ra) # 80002998 <clockintr>
    80002a8e:	b7ed                	j	80002a78 <devintr+0x8c>
}
    80002a90:	8082                	ret

0000000080002a92 <usertrap>:
{
    80002a92:	1101                	addi	sp,sp,-32
    80002a94:	ec06                	sd	ra,24(sp)
    80002a96:	e822                	sd	s0,16(sp)
    80002a98:	e426                	sd	s1,8(sp)
    80002a9a:	e04a                	sd	s2,0(sp)
    80002a9c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a9e:	100027f3          	csrr	a5,sstatus
	if((r_sstatus() & SSTATUS_SPP) != 0)
    80002aa2:	1007f793          	andi	a5,a5,256
    80002aa6:	e3b1                	bnez	a5,80002aea <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aa8:	00003797          	auipc	a5,0x3
    80002aac:	47878793          	addi	a5,a5,1144 # 80005f20 <kernelvec>
    80002ab0:	10579073          	csrw	stvec,a5
	struct proc *p = myproc();
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	ef2080e7          	jalr	-270(ra) # 800019a6 <myproc>
    80002abc:	84aa                	mv	s1,a0
	p->trapframe->epc = r_sepc();
    80002abe:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac0:	14102773          	csrr	a4,sepc
    80002ac4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac6:	14202773          	csrr	a4,scause
	if (r_scause() == 8)
    80002aca:	47a1                	li	a5,8
    80002acc:	02f70763          	beq	a4,a5,80002afa <usertrap+0x68>
	else if ((which_dev = devintr()) != 0)
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	f1c080e7          	jalr	-228(ra) # 800029ec <devintr>
    80002ad8:	892a                	mv	s2,a0
    80002ada:	c92d                	beqz	a0,80002b4c <usertrap+0xba>
	if (killed(p))
    80002adc:	8526                	mv	a0,s1
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	914080e7          	jalr	-1772(ra) # 800023f2 <killed>
    80002ae6:	c555                	beqz	a0,80002b92 <usertrap+0x100>
    80002ae8:	a045                	j	80002b88 <usertrap+0xf6>
		panic("usertrap: not from user mode");
    80002aea:	00006517          	auipc	a0,0x6
    80002aee:	83650513          	addi	a0,a0,-1994 # 80008320 <states.0+0x58>
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	a4a080e7          	jalr	-1462(ra) # 8000053c <panic>
		if (killed(p))
    80002afa:	00000097          	auipc	ra,0x0
    80002afe:	8f8080e7          	jalr	-1800(ra) # 800023f2 <killed>
    80002b02:	ed1d                	bnez	a0,80002b40 <usertrap+0xae>
		p->trapframe->epc += 4;
    80002b04:	6cb8                	ld	a4,88(s1)
    80002b06:	6f1c                	ld	a5,24(a4)
    80002b08:	0791                	addi	a5,a5,4
    80002b0a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b0c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b10:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b14:	10079073          	csrw	sstatus,a5
		syscall();
    80002b18:	00000097          	auipc	ra,0x0
    80002b1c:	346080e7          	jalr	838(ra) # 80002e5e <syscall>
	if (killed(p))
    80002b20:	8526                	mv	a0,s1
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	8d0080e7          	jalr	-1840(ra) # 800023f2 <killed>
    80002b2a:	ed31                	bnez	a0,80002b86 <usertrap+0xf4>
	usertrapret();
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	dd6080e7          	jalr	-554(ra) # 80002902 <usertrapret>
}
    80002b34:	60e2                	ld	ra,24(sp)
    80002b36:	6442                	ld	s0,16(sp)
    80002b38:	64a2                	ld	s1,8(sp)
    80002b3a:	6902                	ld	s2,0(sp)
    80002b3c:	6105                	addi	sp,sp,32
    80002b3e:	8082                	ret
			exit(-1);
    80002b40:	557d                	li	a0,-1
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	730080e7          	jalr	1840(ra) # 80002272 <exit>
    80002b4a:	bf6d                	j	80002b04 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b4c:	142025f3          	csrr	a1,scause
		printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b50:	5890                	lw	a2,48(s1)
    80002b52:	00005517          	auipc	a0,0x5
    80002b56:	7ee50513          	addi	a0,a0,2030 # 80008340 <states.0+0x78>
    80002b5a:	ffffe097          	auipc	ra,0xffffe
    80002b5e:	a2c080e7          	jalr	-1492(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b62:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b66:	14302673          	csrr	a2,stval
		printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b6a:	00006517          	auipc	a0,0x6
    80002b6e:	80650513          	addi	a0,a0,-2042 # 80008370 <states.0+0xa8>
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	a14080e7          	jalr	-1516(ra) # 80000586 <printf>
		setkilled(p);
    80002b7a:	8526                	mv	a0,s1
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	84a080e7          	jalr	-1974(ra) # 800023c6 <setkilled>
    80002b84:	bf71                	j	80002b20 <usertrap+0x8e>
	if (killed(p))
    80002b86:	4901                	li	s2,0
		exit(-1);
    80002b88:	557d                	li	a0,-1
    80002b8a:	fffff097          	auipc	ra,0xfffff
    80002b8e:	6e8080e7          	jalr	1768(ra) # 80002272 <exit>
	if (which_dev == 2)
    80002b92:	4789                	li	a5,2
    80002b94:	f8f91ce3          	bne	s2,a5,80002b2c <usertrap+0x9a>
		p->now_ticks+=1 ;
    80002b98:	17c4a783          	lw	a5,380(s1)
    80002b9c:	2785                	addiw	a5,a5,1
    80002b9e:	0007871b          	sext.w	a4,a5
    80002ba2:	16f4ae23          	sw	a5,380(s1)
		if( p-> ticks > 0 && p->now_ticks >= p->ticks && !p->is_sigalarm)
    80002ba6:	1784a783          	lw	a5,376(s1)
    80002baa:	04f05663          	blez	a5,80002bf6 <usertrap+0x164>
    80002bae:	04f74463          	blt	a4,a5,80002bf6 <usertrap+0x164>
    80002bb2:	1744a783          	lw	a5,372(s1)
    80002bb6:	e3a1                	bnez	a5,80002bf6 <usertrap+0x164>
			p->now_ticks = 0;
    80002bb8:	1604ae23          	sw	zero,380(s1)
			p->is_sigalarm = 1;
    80002bbc:	4785                	li	a5,1
    80002bbe:	16f4aa23          	sw	a5,372(s1)
			*(p->backup_trapframe) =*( p->trapframe);
    80002bc2:	6cb4                	ld	a3,88(s1)
    80002bc4:	87b6                	mv	a5,a3
    80002bc6:	1884b703          	ld	a4,392(s1)
    80002bca:	12068693          	addi	a3,a3,288
    80002bce:	0007b803          	ld	a6,0(a5)
    80002bd2:	6788                	ld	a0,8(a5)
    80002bd4:	6b8c                	ld	a1,16(a5)
    80002bd6:	6f90                	ld	a2,24(a5)
    80002bd8:	01073023          	sd	a6,0(a4)
    80002bdc:	e708                	sd	a0,8(a4)
    80002bde:	eb0c                	sd	a1,16(a4)
    80002be0:	ef10                	sd	a2,24(a4)
    80002be2:	02078793          	addi	a5,a5,32
    80002be6:	02070713          	addi	a4,a4,32
    80002bea:	fed792e3          	bne	a5,a3,80002bce <usertrap+0x13c>
			p->trapframe->epc = p->handler;
    80002bee:	6cbc                	ld	a5,88(s1)
    80002bf0:	1804b703          	ld	a4,384(s1)
    80002bf4:	ef98                	sd	a4,24(a5)
		yield();
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	50c080e7          	jalr	1292(ra) # 80002102 <yield>
    80002bfe:	b73d                	j	80002b2c <usertrap+0x9a>

0000000080002c00 <kerneltrap>:
{
    80002c00:	7179                	addi	sp,sp,-48
    80002c02:	f406                	sd	ra,40(sp)
    80002c04:	f022                	sd	s0,32(sp)
    80002c06:	ec26                	sd	s1,24(sp)
    80002c08:	e84a                	sd	s2,16(sp)
    80002c0a:	e44e                	sd	s3,8(sp)
    80002c0c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c0e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c12:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c16:	142029f3          	csrr	s3,scause
	if ((sstatus & SSTATUS_SPP) == 0)
    80002c1a:	1004f793          	andi	a5,s1,256
    80002c1e:	cb85                	beqz	a5,80002c4e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c20:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c24:	8b89                	andi	a5,a5,2
	if (intr_get() != 0)
    80002c26:	ef85                	bnez	a5,80002c5e <kerneltrap+0x5e>
	if ((which_dev = devintr()) == 0)
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	dc4080e7          	jalr	-572(ra) # 800029ec <devintr>
    80002c30:	cd1d                	beqz	a0,80002c6e <kerneltrap+0x6e>
	if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c32:	4789                	li	a5,2
    80002c34:	06f50a63          	beq	a0,a5,80002ca8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c38:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c3c:	10049073          	csrw	sstatus,s1
}
    80002c40:	70a2                	ld	ra,40(sp)
    80002c42:	7402                	ld	s0,32(sp)
    80002c44:	64e2                	ld	s1,24(sp)
    80002c46:	6942                	ld	s2,16(sp)
    80002c48:	69a2                	ld	s3,8(sp)
    80002c4a:	6145                	addi	sp,sp,48
    80002c4c:	8082                	ret
		panic("kerneltrap: not from supervisor mode");
    80002c4e:	00005517          	auipc	a0,0x5
    80002c52:	74250513          	addi	a0,a0,1858 # 80008390 <states.0+0xc8>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	8e6080e7          	jalr	-1818(ra) # 8000053c <panic>
		panic("kerneltrap: interrupts enabled");
    80002c5e:	00005517          	auipc	a0,0x5
    80002c62:	75a50513          	addi	a0,a0,1882 # 800083b8 <states.0+0xf0>
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	8d6080e7          	jalr	-1834(ra) # 8000053c <panic>
		printf("scause %p\n", scause);
    80002c6e:	85ce                	mv	a1,s3
    80002c70:	00005517          	auipc	a0,0x5
    80002c74:	76850513          	addi	a0,a0,1896 # 800083d8 <states.0+0x110>
    80002c78:	ffffe097          	auipc	ra,0xffffe
    80002c7c:	90e080e7          	jalr	-1778(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c80:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c84:	14302673          	csrr	a2,stval
		printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c88:	00005517          	auipc	a0,0x5
    80002c8c:	76050513          	addi	a0,a0,1888 # 800083e8 <states.0+0x120>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	8f6080e7          	jalr	-1802(ra) # 80000586 <printf>
		panic("kerneltrap");
    80002c98:	00005517          	auipc	a0,0x5
    80002c9c:	76850513          	addi	a0,a0,1896 # 80008400 <states.0+0x138>
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	89c080e7          	jalr	-1892(ra) # 8000053c <panic>
	if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	cfe080e7          	jalr	-770(ra) # 800019a6 <myproc>
    80002cb0:	d541                	beqz	a0,80002c38 <kerneltrap+0x38>
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	cf4080e7          	jalr	-780(ra) # 800019a6 <myproc>
    80002cba:	4d18                	lw	a4,24(a0)
    80002cbc:	4791                	li	a5,4
    80002cbe:	f6f71de3          	bne	a4,a5,80002c38 <kerneltrap+0x38>
		yield();
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	440080e7          	jalr	1088(ra) # 80002102 <yield>
    80002cca:	b7bd                	j	80002c38 <kerneltrap+0x38>

0000000080002ccc <sys_getreadcount>:
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}
uint64 sys_getreadcount(void)
{
    80002ccc:	1141                	addi	sp,sp,-16
    80002cce:	e422                	sd	s0,8(sp)
    80002cd0:	0800                	addi	s0,sp,16
  return READCOUNT; 
}
    80002cd2:	00006517          	auipc	a0,0x6
    80002cd6:	c3653503          	ld	a0,-970(a0) # 80008908 <READCOUNT>
    80002cda:	6422                	ld	s0,8(sp)
    80002cdc:	0141                	addi	sp,sp,16
    80002cde:	8082                	ret

0000000080002ce0 <argraw>:
{
    80002ce0:	1101                	addi	sp,sp,-32
    80002ce2:	ec06                	sd	ra,24(sp)
    80002ce4:	e822                	sd	s0,16(sp)
    80002ce6:	e426                	sd	s1,8(sp)
    80002ce8:	1000                	addi	s0,sp,32
    80002cea:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	cba080e7          	jalr	-838(ra) # 800019a6 <myproc>
  switch (n) {
    80002cf4:	4795                	li	a5,5
    80002cf6:	0497e163          	bltu	a5,s1,80002d38 <argraw+0x58>
    80002cfa:	048a                	slli	s1,s1,0x2
    80002cfc:	00005717          	auipc	a4,0x5
    80002d00:	73c70713          	addi	a4,a4,1852 # 80008438 <states.0+0x170>
    80002d04:	94ba                	add	s1,s1,a4
    80002d06:	409c                	lw	a5,0(s1)
    80002d08:	97ba                	add	a5,a5,a4
    80002d0a:	8782                	jr	a5
    return p->trapframe->a0;
    80002d0c:	6d3c                	ld	a5,88(a0)
    80002d0e:	7ba8                	ld	a0,112(a5)
}
    80002d10:	60e2                	ld	ra,24(sp)
    80002d12:	6442                	ld	s0,16(sp)
    80002d14:	64a2                	ld	s1,8(sp)
    80002d16:	6105                	addi	sp,sp,32
    80002d18:	8082                	ret
    return p->trapframe->a1;
    80002d1a:	6d3c                	ld	a5,88(a0)
    80002d1c:	7fa8                	ld	a0,120(a5)
    80002d1e:	bfcd                	j	80002d10 <argraw+0x30>
    return p->trapframe->a2;
    80002d20:	6d3c                	ld	a5,88(a0)
    80002d22:	63c8                	ld	a0,128(a5)
    80002d24:	b7f5                	j	80002d10 <argraw+0x30>
    return p->trapframe->a3;
    80002d26:	6d3c                	ld	a5,88(a0)
    80002d28:	67c8                	ld	a0,136(a5)
    80002d2a:	b7dd                	j	80002d10 <argraw+0x30>
    return p->trapframe->a4;
    80002d2c:	6d3c                	ld	a5,88(a0)
    80002d2e:	6bc8                	ld	a0,144(a5)
    80002d30:	b7c5                	j	80002d10 <argraw+0x30>
    return p->trapframe->a5;
    80002d32:	6d3c                	ld	a5,88(a0)
    80002d34:	6fc8                	ld	a0,152(a5)
    80002d36:	bfe9                	j	80002d10 <argraw+0x30>
  panic("argraw");
    80002d38:	00005517          	auipc	a0,0x5
    80002d3c:	6d850513          	addi	a0,a0,1752 # 80008410 <states.0+0x148>
    80002d40:	ffffd097          	auipc	ra,0xffffd
    80002d44:	7fc080e7          	jalr	2044(ra) # 8000053c <panic>

0000000080002d48 <fetchaddr>:
{
    80002d48:	1101                	addi	sp,sp,-32
    80002d4a:	ec06                	sd	ra,24(sp)
    80002d4c:	e822                	sd	s0,16(sp)
    80002d4e:	e426                	sd	s1,8(sp)
    80002d50:	e04a                	sd	s2,0(sp)
    80002d52:	1000                	addi	s0,sp,32
    80002d54:	84aa                	mv	s1,a0
    80002d56:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	c4e080e7          	jalr	-946(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d60:	653c                	ld	a5,72(a0)
    80002d62:	02f4f863          	bgeu	s1,a5,80002d92 <fetchaddr+0x4a>
    80002d66:	00848713          	addi	a4,s1,8
    80002d6a:	02e7e663          	bltu	a5,a4,80002d96 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d6e:	46a1                	li	a3,8
    80002d70:	8626                	mv	a2,s1
    80002d72:	85ca                	mv	a1,s2
    80002d74:	6928                	ld	a0,80(a0)
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	97c080e7          	jalr	-1668(ra) # 800016f2 <copyin>
    80002d7e:	00a03533          	snez	a0,a0
    80002d82:	40a00533          	neg	a0,a0
}
    80002d86:	60e2                	ld	ra,24(sp)
    80002d88:	6442                	ld	s0,16(sp)
    80002d8a:	64a2                	ld	s1,8(sp)
    80002d8c:	6902                	ld	s2,0(sp)
    80002d8e:	6105                	addi	sp,sp,32
    80002d90:	8082                	ret
    return -1;
    80002d92:	557d                	li	a0,-1
    80002d94:	bfcd                	j	80002d86 <fetchaddr+0x3e>
    80002d96:	557d                	li	a0,-1
    80002d98:	b7fd                	j	80002d86 <fetchaddr+0x3e>

0000000080002d9a <fetchstr>:
{
    80002d9a:	7179                	addi	sp,sp,-48
    80002d9c:	f406                	sd	ra,40(sp)
    80002d9e:	f022                	sd	s0,32(sp)
    80002da0:	ec26                	sd	s1,24(sp)
    80002da2:	e84a                	sd	s2,16(sp)
    80002da4:	e44e                	sd	s3,8(sp)
    80002da6:	1800                	addi	s0,sp,48
    80002da8:	892a                	mv	s2,a0
    80002daa:	84ae                	mv	s1,a1
    80002dac:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	bf8080e7          	jalr	-1032(ra) # 800019a6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002db6:	86ce                	mv	a3,s3
    80002db8:	864a                	mv	a2,s2
    80002dba:	85a6                	mv	a1,s1
    80002dbc:	6928                	ld	a0,80(a0)
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	9c2080e7          	jalr	-1598(ra) # 80001780 <copyinstr>
    80002dc6:	00054e63          	bltz	a0,80002de2 <fetchstr+0x48>
  return strlen(buf);
    80002dca:	8526                	mv	a0,s1
    80002dcc:	ffffe097          	auipc	ra,0xffffe
    80002dd0:	07c080e7          	jalr	124(ra) # 80000e48 <strlen>
}
    80002dd4:	70a2                	ld	ra,40(sp)
    80002dd6:	7402                	ld	s0,32(sp)
    80002dd8:	64e2                	ld	s1,24(sp)
    80002dda:	6942                	ld	s2,16(sp)
    80002ddc:	69a2                	ld	s3,8(sp)
    80002dde:	6145                	addi	sp,sp,48
    80002de0:	8082                	ret
    return -1;
    80002de2:	557d                	li	a0,-1
    80002de4:	bfc5                	j	80002dd4 <fetchstr+0x3a>

0000000080002de6 <argint>:
{
    80002de6:	1101                	addi	sp,sp,-32
    80002de8:	ec06                	sd	ra,24(sp)
    80002dea:	e822                	sd	s0,16(sp)
    80002dec:	e426                	sd	s1,8(sp)
    80002dee:	1000                	addi	s0,sp,32
    80002df0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	eee080e7          	jalr	-274(ra) # 80002ce0 <argraw>
    80002dfa:	c088                	sw	a0,0(s1)
}
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	64a2                	ld	s1,8(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret

0000000080002e06 <argaddr>:
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	1000                	addi	s0,sp,32
    80002e10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e12:	00000097          	auipc	ra,0x0
    80002e16:	ece080e7          	jalr	-306(ra) # 80002ce0 <argraw>
    80002e1a:	e088                	sd	a0,0(s1)
}
    80002e1c:	60e2                	ld	ra,24(sp)
    80002e1e:	6442                	ld	s0,16(sp)
    80002e20:	64a2                	ld	s1,8(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <argstr>:
{
    80002e26:	7179                	addi	sp,sp,-48
    80002e28:	f406                	sd	ra,40(sp)
    80002e2a:	f022                	sd	s0,32(sp)
    80002e2c:	ec26                	sd	s1,24(sp)
    80002e2e:	e84a                	sd	s2,16(sp)
    80002e30:	1800                	addi	s0,sp,48
    80002e32:	84ae                	mv	s1,a1
    80002e34:	8932                	mv	s2,a2
  argaddr(n, &addr);
    80002e36:	fd840593          	addi	a1,s0,-40
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	fcc080e7          	jalr	-52(ra) # 80002e06 <argaddr>
  return fetchstr(addr, buf, max);
    80002e42:	864a                	mv	a2,s2
    80002e44:	85a6                	mv	a1,s1
    80002e46:	fd843503          	ld	a0,-40(s0)
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	f50080e7          	jalr	-176(ra) # 80002d9a <fetchstr>
}
    80002e52:	70a2                	ld	ra,40(sp)
    80002e54:	7402                	ld	s0,32(sp)
    80002e56:	64e2                	ld	s1,24(sp)
    80002e58:	6942                	ld	s2,16(sp)
    80002e5a:	6145                	addi	sp,sp,48
    80002e5c:	8082                	ret

0000000080002e5e <syscall>:

};

void
syscall(void)
{
    80002e5e:	1101                	addi	sp,sp,-32
    80002e60:	ec06                	sd	ra,24(sp)
    80002e62:	e822                	sd	s0,16(sp)
    80002e64:	e426                	sd	s1,8(sp)
    80002e66:	e04a                	sd	s2,0(sp)
    80002e68:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	b3c080e7          	jalr	-1220(ra) # 800019a6 <myproc>
    80002e72:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e74:	05853903          	ld	s2,88(a0)
    80002e78:	0a893783          	ld	a5,168(s2)
    80002e7c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e80:	37fd                	addiw	a5,a5,-1
    80002e82:	4761                	li	a4,24
    80002e84:	00f76f63          	bltu	a4,a5,80002ea2 <syscall+0x44>
    80002e88:	00369713          	slli	a4,a3,0x3
    80002e8c:	00005797          	auipc	a5,0x5
    80002e90:	5c478793          	addi	a5,a5,1476 # 80008450 <syscalls>
    80002e94:	97ba                	add	a5,a5,a4
    80002e96:	639c                	ld	a5,0(a5)
    80002e98:	c789                	beqz	a5,80002ea2 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e9a:	9782                	jalr	a5
    80002e9c:	06a93823          	sd	a0,112(s2)
    80002ea0:	a839                	j	80002ebe <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ea2:	15848613          	addi	a2,s1,344
    80002ea6:	588c                	lw	a1,48(s1)
    80002ea8:	00005517          	auipc	a0,0x5
    80002eac:	57050513          	addi	a0,a0,1392 # 80008418 <states.0+0x150>
    80002eb0:	ffffd097          	auipc	ra,0xffffd
    80002eb4:	6d6080e7          	jalr	1750(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002eb8:	6cbc                	ld	a5,88(s1)
    80002eba:	577d                	li	a4,-1
    80002ebc:	fbb8                	sd	a4,112(a5)
  }
}
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	64a2                	ld	s1,8(sp)
    80002ec4:	6902                	ld	s2,0(sp)
    80002ec6:	6105                	addi	sp,sp,32
    80002ec8:	8082                	ret

0000000080002eca <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eca:	1101                	addi	sp,sp,-32
    80002ecc:	ec06                	sd	ra,24(sp)
    80002ece:	e822                	sd	s0,16(sp)
    80002ed0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ed2:	fec40593          	addi	a1,s0,-20
    80002ed6:	4501                	li	a0,0
    80002ed8:	00000097          	auipc	ra,0x0
    80002edc:	f0e080e7          	jalr	-242(ra) # 80002de6 <argint>
  exit(n);
    80002ee0:	fec42503          	lw	a0,-20(s0)
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	38e080e7          	jalr	910(ra) # 80002272 <exit>
  return 0; // not reached
}
    80002eec:	4501                	li	a0,0
    80002eee:	60e2                	ld	ra,24(sp)
    80002ef0:	6442                	ld	s0,16(sp)
    80002ef2:	6105                	addi	sp,sp,32
    80002ef4:	8082                	ret

0000000080002ef6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ef6:	1141                	addi	sp,sp,-16
    80002ef8:	e406                	sd	ra,8(sp)
    80002efa:	e022                	sd	s0,0(sp)
    80002efc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	aa8080e7          	jalr	-1368(ra) # 800019a6 <myproc>
}
    80002f06:	5908                	lw	a0,48(a0)
    80002f08:	60a2                	ld	ra,8(sp)
    80002f0a:	6402                	ld	s0,0(sp)
    80002f0c:	0141                	addi	sp,sp,16
    80002f0e:	8082                	ret

0000000080002f10 <sys_fork>:

uint64
sys_fork(void)
{
    80002f10:	1141                	addi	sp,sp,-16
    80002f12:	e406                	sd	ra,8(sp)
    80002f14:	e022                	sd	s0,0(sp)
    80002f16:	0800                	addi	s0,sp,16
  return fork();
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	eee080e7          	jalr	-274(ra) # 80001e06 <fork>
}
    80002f20:	60a2                	ld	ra,8(sp)
    80002f22:	6402                	ld	s0,0(sp)
    80002f24:	0141                	addi	sp,sp,16
    80002f26:	8082                	ret

0000000080002f28 <sys_wait>:

uint64
sys_wait(void)
{
    80002f28:	1101                	addi	sp,sp,-32
    80002f2a:	ec06                	sd	ra,24(sp)
    80002f2c:	e822                	sd	s0,16(sp)
    80002f2e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f30:	fe840593          	addi	a1,s0,-24
    80002f34:	4501                	li	a0,0
    80002f36:	00000097          	auipc	ra,0x0
    80002f3a:	ed0080e7          	jalr	-304(ra) # 80002e06 <argaddr>
  return wait(p);
    80002f3e:	fe843503          	ld	a0,-24(s0)
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	4e2080e7          	jalr	1250(ra) # 80002424 <wait>
}
    80002f4a:	60e2                	ld	ra,24(sp)
    80002f4c:	6442                	ld	s0,16(sp)
    80002f4e:	6105                	addi	sp,sp,32
    80002f50:	8082                	ret

0000000080002f52 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f52:	7179                	addi	sp,sp,-48
    80002f54:	f406                	sd	ra,40(sp)
    80002f56:	f022                	sd	s0,32(sp)
    80002f58:	ec26                	sd	s1,24(sp)
    80002f5a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f5c:	fdc40593          	addi	a1,s0,-36
    80002f60:	4501                	li	a0,0
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	e84080e7          	jalr	-380(ra) # 80002de6 <argint>
  addr = myproc()->sz;
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	a3c080e7          	jalr	-1476(ra) # 800019a6 <myproc>
    80002f72:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002f74:	fdc42503          	lw	a0,-36(s0)
    80002f78:	fffff097          	auipc	ra,0xfffff
    80002f7c:	e32080e7          	jalr	-462(ra) # 80001daa <growproc>
    80002f80:	00054863          	bltz	a0,80002f90 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f84:	8526                	mv	a0,s1
    80002f86:	70a2                	ld	ra,40(sp)
    80002f88:	7402                	ld	s0,32(sp)
    80002f8a:	64e2                	ld	s1,24(sp)
    80002f8c:	6145                	addi	sp,sp,48
    80002f8e:	8082                	ret
    return -1;
    80002f90:	54fd                	li	s1,-1
    80002f92:	bfcd                	j	80002f84 <sys_sbrk+0x32>

0000000080002f94 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f94:	7139                	addi	sp,sp,-64
    80002f96:	fc06                	sd	ra,56(sp)
    80002f98:	f822                	sd	s0,48(sp)
    80002f9a:	f426                	sd	s1,40(sp)
    80002f9c:	f04a                	sd	s2,32(sp)
    80002f9e:	ec4e                	sd	s3,24(sp)
    80002fa0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002fa2:	fcc40593          	addi	a1,s0,-52
    80002fa6:	4501                	li	a0,0
    80002fa8:	00000097          	auipc	ra,0x0
    80002fac:	e3e080e7          	jalr	-450(ra) # 80002de6 <argint>
  acquire(&tickslock);
    80002fb0:	00014517          	auipc	a0,0x14
    80002fb4:	3f050513          	addi	a0,a0,1008 # 800173a0 <tickslock>
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	c1a080e7          	jalr	-998(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002fc0:	00006917          	auipc	s2,0x6
    80002fc4:	94092903          	lw	s2,-1728(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    80002fc8:	fcc42783          	lw	a5,-52(s0)
    80002fcc:	cf9d                	beqz	a5,8000300a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fce:	00014997          	auipc	s3,0x14
    80002fd2:	3d298993          	addi	s3,s3,978 # 800173a0 <tickslock>
    80002fd6:	00006497          	auipc	s1,0x6
    80002fda:	92a48493          	addi	s1,s1,-1750 # 80008900 <ticks>
    if (killed(myproc()))
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	9c8080e7          	jalr	-1592(ra) # 800019a6 <myproc>
    80002fe6:	fffff097          	auipc	ra,0xfffff
    80002fea:	40c080e7          	jalr	1036(ra) # 800023f2 <killed>
    80002fee:	ed15                	bnez	a0,8000302a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ff0:	85ce                	mv	a1,s3
    80002ff2:	8526                	mv	a0,s1
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	14a080e7          	jalr	330(ra) # 8000213e <sleep>
  while (ticks - ticks0 < n)
    80002ffc:	409c                	lw	a5,0(s1)
    80002ffe:	412787bb          	subw	a5,a5,s2
    80003002:	fcc42703          	lw	a4,-52(s0)
    80003006:	fce7ece3          	bltu	a5,a4,80002fde <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000300a:	00014517          	auipc	a0,0x14
    8000300e:	39650513          	addi	a0,a0,918 # 800173a0 <tickslock>
    80003012:	ffffe097          	auipc	ra,0xffffe
    80003016:	c74080e7          	jalr	-908(ra) # 80000c86 <release>
  return 0;
    8000301a:	4501                	li	a0,0
}
    8000301c:	70e2                	ld	ra,56(sp)
    8000301e:	7442                	ld	s0,48(sp)
    80003020:	74a2                	ld	s1,40(sp)
    80003022:	7902                	ld	s2,32(sp)
    80003024:	69e2                	ld	s3,24(sp)
    80003026:	6121                	addi	sp,sp,64
    80003028:	8082                	ret
      release(&tickslock);
    8000302a:	00014517          	auipc	a0,0x14
    8000302e:	37650513          	addi	a0,a0,886 # 800173a0 <tickslock>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	c54080e7          	jalr	-940(ra) # 80000c86 <release>
      return -1;
    8000303a:	557d                	li	a0,-1
    8000303c:	b7c5                	j	8000301c <sys_sleep+0x88>

000000008000303e <sys_kill>:

uint64
sys_kill(void)
{
    8000303e:	1101                	addi	sp,sp,-32
    80003040:	ec06                	sd	ra,24(sp)
    80003042:	e822                	sd	s0,16(sp)
    80003044:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003046:	fec40593          	addi	a1,s0,-20
    8000304a:	4501                	li	a0,0
    8000304c:	00000097          	auipc	ra,0x0
    80003050:	d9a080e7          	jalr	-614(ra) # 80002de6 <argint>
  return kill(pid);
    80003054:	fec42503          	lw	a0,-20(s0)
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	2fc080e7          	jalr	764(ra) # 80002354 <kill>
}
    80003060:	60e2                	ld	ra,24(sp)
    80003062:	6442                	ld	s0,16(sp)
    80003064:	6105                	addi	sp,sp,32
    80003066:	8082                	ret

0000000080003068 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003068:	1101                	addi	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	e426                	sd	s1,8(sp)
    80003070:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003072:	00014517          	auipc	a0,0x14
    80003076:	32e50513          	addi	a0,a0,814 # 800173a0 <tickslock>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	b58080e7          	jalr	-1192(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80003082:	00006497          	auipc	s1,0x6
    80003086:	87e4a483          	lw	s1,-1922(s1) # 80008900 <ticks>
  release(&tickslock);
    8000308a:	00014517          	auipc	a0,0x14
    8000308e:	31650513          	addi	a0,a0,790 # 800173a0 <tickslock>
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	bf4080e7          	jalr	-1036(ra) # 80000c86 <release>
  return xticks;
}
    8000309a:	02049513          	slli	a0,s1,0x20
    8000309e:	9101                	srli	a0,a0,0x20
    800030a0:	60e2                	ld	ra,24(sp)
    800030a2:	6442                	ld	s0,16(sp)
    800030a4:	64a2                	ld	s1,8(sp)
    800030a6:	6105                	addi	sp,sp,32
    800030a8:	8082                	ret

00000000800030aa <sys_waitx>:

uint64
sys_waitx(void)
{
    800030aa:	7139                	addi	sp,sp,-64
    800030ac:	fc06                	sd	ra,56(sp)
    800030ae:	f822                	sd	s0,48(sp)
    800030b0:	f426                	sd	s1,40(sp)
    800030b2:	f04a                	sd	s2,32(sp)
    800030b4:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800030b6:	fd840593          	addi	a1,s0,-40
    800030ba:	4501                	li	a0,0
    800030bc:	00000097          	auipc	ra,0x0
    800030c0:	d4a080e7          	jalr	-694(ra) # 80002e06 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800030c4:	fd040593          	addi	a1,s0,-48
    800030c8:	4505                	li	a0,1
    800030ca:	00000097          	auipc	ra,0x0
    800030ce:	d3c080e7          	jalr	-708(ra) # 80002e06 <argaddr>
  argaddr(2, &addr2);
    800030d2:	fc840593          	addi	a1,s0,-56
    800030d6:	4509                	li	a0,2
    800030d8:	00000097          	auipc	ra,0x0
    800030dc:	d2e080e7          	jalr	-722(ra) # 80002e06 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800030e0:	fc040613          	addi	a2,s0,-64
    800030e4:	fc440593          	addi	a1,s0,-60
    800030e8:	fd843503          	ld	a0,-40(s0)
    800030ec:	fffff097          	auipc	ra,0xfffff
    800030f0:	5c2080e7          	jalr	1474(ra) # 800026ae <waitx>
    800030f4:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	8b0080e7          	jalr	-1872(ra) # 800019a6 <myproc>
    800030fe:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003100:	4691                	li	a3,4
    80003102:	fc440613          	addi	a2,s0,-60
    80003106:	fd043583          	ld	a1,-48(s0)
    8000310a:	6928                	ld	a0,80(a0)
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	55a080e7          	jalr	1370(ra) # 80001666 <copyout>
    return -1;
    80003114:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003116:	00054f63          	bltz	a0,80003134 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000311a:	4691                	li	a3,4
    8000311c:	fc040613          	addi	a2,s0,-64
    80003120:	fc843583          	ld	a1,-56(s0)
    80003124:	68a8                	ld	a0,80(s1)
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	540080e7          	jalr	1344(ra) # 80001666 <copyout>
    8000312e:	00054a63          	bltz	a0,80003142 <sys_waitx+0x98>
    return -1;
  return ret;
    80003132:	87ca                	mv	a5,s2
}
    80003134:	853e                	mv	a0,a5
    80003136:	70e2                	ld	ra,56(sp)
    80003138:	7442                	ld	s0,48(sp)
    8000313a:	74a2                	ld	s1,40(sp)
    8000313c:	7902                	ld	s2,32(sp)
    8000313e:	6121                	addi	sp,sp,64
    80003140:	8082                	ret
    return -1;
    80003142:	57fd                	li	a5,-1
    80003144:	bfc5                	j	80003134 <sys_waitx+0x8a>

0000000080003146 <restore>:
void restore(){
    80003146:	1141                	addi	sp,sp,-16
    80003148:	e406                	sd	ra,8(sp)
    8000314a:	e022                	sd	s0,0(sp)
    8000314c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000314e:	fffff097          	auipc	ra,0xfffff
    80003152:	858080e7          	jalr	-1960(ra) # 800019a6 <myproc>
  p->backup_trapframe->kernel_hartid = p->trapframe->kernel_hartid;
    80003156:	18853783          	ld	a5,392(a0)
    8000315a:	6d38                	ld	a4,88(a0)
    8000315c:	7318                	ld	a4,32(a4)
    8000315e:	f398                	sd	a4,32(a5)
  p->backup_trapframe->kernel_satp = p->trapframe->kernel_satp;
    80003160:	18853783          	ld	a5,392(a0)
    80003164:	6d38                	ld	a4,88(a0)
    80003166:	6318                	ld	a4,0(a4)
    80003168:	e398                	sd	a4,0(a5)
  p->backup_trapframe->kernel_sp = p->trapframe->kernel_sp;
    8000316a:	18853783          	ld	a5,392(a0)
    8000316e:	6d38                	ld	a4,88(a0)
    80003170:	6718                	ld	a4,8(a4)
    80003172:	e798                	sd	a4,8(a5)
  p->backup_trapframe->kernel_trap = p->trapframe->kernel_trap;
    80003174:	18853783          	ld	a5,392(a0)
    80003178:	6d38                	ld	a4,88(a0)
    8000317a:	6b18                	ld	a4,16(a4)
    8000317c:	eb98                	sd	a4,16(a5)
  *(p->trapframe) = *(p->backup_trapframe);
    8000317e:	18853683          	ld	a3,392(a0)
    80003182:	87b6                	mv	a5,a3
    80003184:	6d38                	ld	a4,88(a0)
    80003186:	12068693          	addi	a3,a3,288
    8000318a:	0007b803          	ld	a6,0(a5)
    8000318e:	6788                	ld	a0,8(a5)
    80003190:	6b8c                	ld	a1,16(a5)
    80003192:	6f90                	ld	a2,24(a5)
    80003194:	01073023          	sd	a6,0(a4)
    80003198:	e708                	sd	a0,8(a4)
    8000319a:	eb0c                	sd	a1,16(a4)
    8000319c:	ef10                	sd	a2,24(a4)
    8000319e:	02078793          	addi	a5,a5,32
    800031a2:	02070713          	addi	a4,a4,32
    800031a6:	fed792e3          	bne	a5,a3,8000318a <restore+0x44>
} 
    800031aa:	60a2                	ld	ra,8(sp)
    800031ac:	6402                	ld	s0,0(sp)
    800031ae:	0141                	addi	sp,sp,16
    800031b0:	8082                	ret

00000000800031b2 <sys_sigreturn>:
uint64 sys_sigreturn(void){
    800031b2:	1141                	addi	sp,sp,-16
    800031b4:	e406                	sd	ra,8(sp)
    800031b6:	e022                	sd	s0,0(sp)
    800031b8:	0800                	addi	s0,sp,16
  restore();
    800031ba:	00000097          	auipc	ra,0x0
    800031be:	f8c080e7          	jalr	-116(ra) # 80003146 <restore>
  myproc()->is_sigalarm = 0;
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	7e4080e7          	jalr	2020(ra) # 800019a6 <myproc>
    800031ca:	16052a23          	sw	zero,372(a0)
  return myproc()->trapframe->a0;
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	7d8080e7          	jalr	2008(ra) # 800019a6 <myproc>
    800031d6:	6d3c                	ld	a5,88(a0)
    800031d8:	7ba8                	ld	a0,112(a5)
    800031da:	60a2                	ld	ra,8(sp)
    800031dc:	6402                	ld	s0,0(sp)
    800031de:	0141                	addi	sp,sp,16
    800031e0:	8082                	ret

00000000800031e2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031e2:	7179                	addi	sp,sp,-48
    800031e4:	f406                	sd	ra,40(sp)
    800031e6:	f022                	sd	s0,32(sp)
    800031e8:	ec26                	sd	s1,24(sp)
    800031ea:	e84a                	sd	s2,16(sp)
    800031ec:	e44e                	sd	s3,8(sp)
    800031ee:	e052                	sd	s4,0(sp)
    800031f0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031f2:	00005597          	auipc	a1,0x5
    800031f6:	32e58593          	addi	a1,a1,814 # 80008520 <syscalls+0xd0>
    800031fa:	00014517          	auipc	a0,0x14
    800031fe:	1be50513          	addi	a0,a0,446 # 800173b8 <bcache>
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	940080e7          	jalr	-1728(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000320a:	0001c797          	auipc	a5,0x1c
    8000320e:	1ae78793          	addi	a5,a5,430 # 8001f3b8 <bcache+0x8000>
    80003212:	0001c717          	auipc	a4,0x1c
    80003216:	40e70713          	addi	a4,a4,1038 # 8001f620 <bcache+0x8268>
    8000321a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000321e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003222:	00014497          	auipc	s1,0x14
    80003226:	1ae48493          	addi	s1,s1,430 # 800173d0 <bcache+0x18>
    b->next = bcache.head.next;
    8000322a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000322c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000322e:	00005a17          	auipc	s4,0x5
    80003232:	2faa0a13          	addi	s4,s4,762 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003236:	2b893783          	ld	a5,696(s2)
    8000323a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000323c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003240:	85d2                	mv	a1,s4
    80003242:	01048513          	addi	a0,s1,16
    80003246:	00001097          	auipc	ra,0x1
    8000324a:	496080e7          	jalr	1174(ra) # 800046dc <initsleeplock>
    bcache.head.next->prev = b;
    8000324e:	2b893783          	ld	a5,696(s2)
    80003252:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003254:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003258:	45848493          	addi	s1,s1,1112
    8000325c:	fd349de3          	bne	s1,s3,80003236 <binit+0x54>
  }
}
    80003260:	70a2                	ld	ra,40(sp)
    80003262:	7402                	ld	s0,32(sp)
    80003264:	64e2                	ld	s1,24(sp)
    80003266:	6942                	ld	s2,16(sp)
    80003268:	69a2                	ld	s3,8(sp)
    8000326a:	6a02                	ld	s4,0(sp)
    8000326c:	6145                	addi	sp,sp,48
    8000326e:	8082                	ret

0000000080003270 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003270:	7179                	addi	sp,sp,-48
    80003272:	f406                	sd	ra,40(sp)
    80003274:	f022                	sd	s0,32(sp)
    80003276:	ec26                	sd	s1,24(sp)
    80003278:	e84a                	sd	s2,16(sp)
    8000327a:	e44e                	sd	s3,8(sp)
    8000327c:	1800                	addi	s0,sp,48
    8000327e:	892a                	mv	s2,a0
    80003280:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003282:	00014517          	auipc	a0,0x14
    80003286:	13650513          	addi	a0,a0,310 # 800173b8 <bcache>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	948080e7          	jalr	-1720(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003292:	0001c497          	auipc	s1,0x1c
    80003296:	3de4b483          	ld	s1,990(s1) # 8001f670 <bcache+0x82b8>
    8000329a:	0001c797          	auipc	a5,0x1c
    8000329e:	38678793          	addi	a5,a5,902 # 8001f620 <bcache+0x8268>
    800032a2:	02f48f63          	beq	s1,a5,800032e0 <bread+0x70>
    800032a6:	873e                	mv	a4,a5
    800032a8:	a021                	j	800032b0 <bread+0x40>
    800032aa:	68a4                	ld	s1,80(s1)
    800032ac:	02e48a63          	beq	s1,a4,800032e0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032b0:	449c                	lw	a5,8(s1)
    800032b2:	ff279ce3          	bne	a5,s2,800032aa <bread+0x3a>
    800032b6:	44dc                	lw	a5,12(s1)
    800032b8:	ff3799e3          	bne	a5,s3,800032aa <bread+0x3a>
      b->refcnt++;
    800032bc:	40bc                	lw	a5,64(s1)
    800032be:	2785                	addiw	a5,a5,1
    800032c0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032c2:	00014517          	auipc	a0,0x14
    800032c6:	0f650513          	addi	a0,a0,246 # 800173b8 <bcache>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	9bc080e7          	jalr	-1604(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800032d2:	01048513          	addi	a0,s1,16
    800032d6:	00001097          	auipc	ra,0x1
    800032da:	440080e7          	jalr	1088(ra) # 80004716 <acquiresleep>
      return b;
    800032de:	a8b9                	j	8000333c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032e0:	0001c497          	auipc	s1,0x1c
    800032e4:	3884b483          	ld	s1,904(s1) # 8001f668 <bcache+0x82b0>
    800032e8:	0001c797          	auipc	a5,0x1c
    800032ec:	33878793          	addi	a5,a5,824 # 8001f620 <bcache+0x8268>
    800032f0:	00f48863          	beq	s1,a5,80003300 <bread+0x90>
    800032f4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032f6:	40bc                	lw	a5,64(s1)
    800032f8:	cf81                	beqz	a5,80003310 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032fa:	64a4                	ld	s1,72(s1)
    800032fc:	fee49de3          	bne	s1,a4,800032f6 <bread+0x86>
  panic("bget: no buffers");
    80003300:	00005517          	auipc	a0,0x5
    80003304:	23050513          	addi	a0,a0,560 # 80008530 <syscalls+0xe0>
    80003308:	ffffd097          	auipc	ra,0xffffd
    8000330c:	234080e7          	jalr	564(ra) # 8000053c <panic>
      b->dev = dev;
    80003310:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003314:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003318:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000331c:	4785                	li	a5,1
    8000331e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003320:	00014517          	auipc	a0,0x14
    80003324:	09850513          	addi	a0,a0,152 # 800173b8 <bcache>
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	95e080e7          	jalr	-1698(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003330:	01048513          	addi	a0,s1,16
    80003334:	00001097          	auipc	ra,0x1
    80003338:	3e2080e7          	jalr	994(ra) # 80004716 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000333c:	409c                	lw	a5,0(s1)
    8000333e:	cb89                	beqz	a5,80003350 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003340:	8526                	mv	a0,s1
    80003342:	70a2                	ld	ra,40(sp)
    80003344:	7402                	ld	s0,32(sp)
    80003346:	64e2                	ld	s1,24(sp)
    80003348:	6942                	ld	s2,16(sp)
    8000334a:	69a2                	ld	s3,8(sp)
    8000334c:	6145                	addi	sp,sp,48
    8000334e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003350:	4581                	li	a1,0
    80003352:	8526                	mv	a0,s1
    80003354:	00003097          	auipc	ra,0x3
    80003358:	f8e080e7          	jalr	-114(ra) # 800062e2 <virtio_disk_rw>
    b->valid = 1;
    8000335c:	4785                	li	a5,1
    8000335e:	c09c                	sw	a5,0(s1)
  return b;
    80003360:	b7c5                	j	80003340 <bread+0xd0>

0000000080003362 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003362:	1101                	addi	sp,sp,-32
    80003364:	ec06                	sd	ra,24(sp)
    80003366:	e822                	sd	s0,16(sp)
    80003368:	e426                	sd	s1,8(sp)
    8000336a:	1000                	addi	s0,sp,32
    8000336c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000336e:	0541                	addi	a0,a0,16
    80003370:	00001097          	auipc	ra,0x1
    80003374:	440080e7          	jalr	1088(ra) # 800047b0 <holdingsleep>
    80003378:	cd01                	beqz	a0,80003390 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000337a:	4585                	li	a1,1
    8000337c:	8526                	mv	a0,s1
    8000337e:	00003097          	auipc	ra,0x3
    80003382:	f64080e7          	jalr	-156(ra) # 800062e2 <virtio_disk_rw>
}
    80003386:	60e2                	ld	ra,24(sp)
    80003388:	6442                	ld	s0,16(sp)
    8000338a:	64a2                	ld	s1,8(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret
    panic("bwrite");
    80003390:	00005517          	auipc	a0,0x5
    80003394:	1b850513          	addi	a0,a0,440 # 80008548 <syscalls+0xf8>
    80003398:	ffffd097          	auipc	ra,0xffffd
    8000339c:	1a4080e7          	jalr	420(ra) # 8000053c <panic>

00000000800033a0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	e04a                	sd	s2,0(sp)
    800033aa:	1000                	addi	s0,sp,32
    800033ac:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033ae:	01050913          	addi	s2,a0,16
    800033b2:	854a                	mv	a0,s2
    800033b4:	00001097          	auipc	ra,0x1
    800033b8:	3fc080e7          	jalr	1020(ra) # 800047b0 <holdingsleep>
    800033bc:	c925                	beqz	a0,8000342c <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800033be:	854a                	mv	a0,s2
    800033c0:	00001097          	auipc	ra,0x1
    800033c4:	3ac080e7          	jalr	940(ra) # 8000476c <releasesleep>

  acquire(&bcache.lock);
    800033c8:	00014517          	auipc	a0,0x14
    800033cc:	ff050513          	addi	a0,a0,-16 # 800173b8 <bcache>
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	802080e7          	jalr	-2046(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800033d8:	40bc                	lw	a5,64(s1)
    800033da:	37fd                	addiw	a5,a5,-1
    800033dc:	0007871b          	sext.w	a4,a5
    800033e0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033e2:	e71d                	bnez	a4,80003410 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033e4:	68b8                	ld	a4,80(s1)
    800033e6:	64bc                	ld	a5,72(s1)
    800033e8:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800033ea:	68b8                	ld	a4,80(s1)
    800033ec:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033ee:	0001c797          	auipc	a5,0x1c
    800033f2:	fca78793          	addi	a5,a5,-54 # 8001f3b8 <bcache+0x8000>
    800033f6:	2b87b703          	ld	a4,696(a5)
    800033fa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033fc:	0001c717          	auipc	a4,0x1c
    80003400:	22470713          	addi	a4,a4,548 # 8001f620 <bcache+0x8268>
    80003404:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003406:	2b87b703          	ld	a4,696(a5)
    8000340a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000340c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003410:	00014517          	auipc	a0,0x14
    80003414:	fa850513          	addi	a0,a0,-88 # 800173b8 <bcache>
    80003418:	ffffe097          	auipc	ra,0xffffe
    8000341c:	86e080e7          	jalr	-1938(ra) # 80000c86 <release>
}
    80003420:	60e2                	ld	ra,24(sp)
    80003422:	6442                	ld	s0,16(sp)
    80003424:	64a2                	ld	s1,8(sp)
    80003426:	6902                	ld	s2,0(sp)
    80003428:	6105                	addi	sp,sp,32
    8000342a:	8082                	ret
    panic("brelse");
    8000342c:	00005517          	auipc	a0,0x5
    80003430:	12450513          	addi	a0,a0,292 # 80008550 <syscalls+0x100>
    80003434:	ffffd097          	auipc	ra,0xffffd
    80003438:	108080e7          	jalr	264(ra) # 8000053c <panic>

000000008000343c <bpin>:

void
bpin(struct buf *b) {
    8000343c:	1101                	addi	sp,sp,-32
    8000343e:	ec06                	sd	ra,24(sp)
    80003440:	e822                	sd	s0,16(sp)
    80003442:	e426                	sd	s1,8(sp)
    80003444:	1000                	addi	s0,sp,32
    80003446:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003448:	00014517          	auipc	a0,0x14
    8000344c:	f7050513          	addi	a0,a0,-144 # 800173b8 <bcache>
    80003450:	ffffd097          	auipc	ra,0xffffd
    80003454:	782080e7          	jalr	1922(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003458:	40bc                	lw	a5,64(s1)
    8000345a:	2785                	addiw	a5,a5,1
    8000345c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000345e:	00014517          	auipc	a0,0x14
    80003462:	f5a50513          	addi	a0,a0,-166 # 800173b8 <bcache>
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	820080e7          	jalr	-2016(ra) # 80000c86 <release>
}
    8000346e:	60e2                	ld	ra,24(sp)
    80003470:	6442                	ld	s0,16(sp)
    80003472:	64a2                	ld	s1,8(sp)
    80003474:	6105                	addi	sp,sp,32
    80003476:	8082                	ret

0000000080003478 <bunpin>:

void
bunpin(struct buf *b) {
    80003478:	1101                	addi	sp,sp,-32
    8000347a:	ec06                	sd	ra,24(sp)
    8000347c:	e822                	sd	s0,16(sp)
    8000347e:	e426                	sd	s1,8(sp)
    80003480:	1000                	addi	s0,sp,32
    80003482:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003484:	00014517          	auipc	a0,0x14
    80003488:	f3450513          	addi	a0,a0,-204 # 800173b8 <bcache>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	746080e7          	jalr	1862(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003494:	40bc                	lw	a5,64(s1)
    80003496:	37fd                	addiw	a5,a5,-1
    80003498:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000349a:	00014517          	auipc	a0,0x14
    8000349e:	f1e50513          	addi	a0,a0,-226 # 800173b8 <bcache>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	7e4080e7          	jalr	2020(ra) # 80000c86 <release>
}
    800034aa:	60e2                	ld	ra,24(sp)
    800034ac:	6442                	ld	s0,16(sp)
    800034ae:	64a2                	ld	s1,8(sp)
    800034b0:	6105                	addi	sp,sp,32
    800034b2:	8082                	ret

00000000800034b4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034b4:	1101                	addi	sp,sp,-32
    800034b6:	ec06                	sd	ra,24(sp)
    800034b8:	e822                	sd	s0,16(sp)
    800034ba:	e426                	sd	s1,8(sp)
    800034bc:	e04a                	sd	s2,0(sp)
    800034be:	1000                	addi	s0,sp,32
    800034c0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034c2:	00d5d59b          	srliw	a1,a1,0xd
    800034c6:	0001c797          	auipc	a5,0x1c
    800034ca:	5ce7a783          	lw	a5,1486(a5) # 8001fa94 <sb+0x1c>
    800034ce:	9dbd                	addw	a1,a1,a5
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	da0080e7          	jalr	-608(ra) # 80003270 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034d8:	0074f713          	andi	a4,s1,7
    800034dc:	4785                	li	a5,1
    800034de:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034e2:	14ce                	slli	s1,s1,0x33
    800034e4:	90d9                	srli	s1,s1,0x36
    800034e6:	00950733          	add	a4,a0,s1
    800034ea:	05874703          	lbu	a4,88(a4)
    800034ee:	00e7f6b3          	and	a3,a5,a4
    800034f2:	c69d                	beqz	a3,80003520 <bfree+0x6c>
    800034f4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034f6:	94aa                	add	s1,s1,a0
    800034f8:	fff7c793          	not	a5,a5
    800034fc:	8f7d                	and	a4,a4,a5
    800034fe:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003502:	00001097          	auipc	ra,0x1
    80003506:	0f6080e7          	jalr	246(ra) # 800045f8 <log_write>
  brelse(bp);
    8000350a:	854a                	mv	a0,s2
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	e94080e7          	jalr	-364(ra) # 800033a0 <brelse>
}
    80003514:	60e2                	ld	ra,24(sp)
    80003516:	6442                	ld	s0,16(sp)
    80003518:	64a2                	ld	s1,8(sp)
    8000351a:	6902                	ld	s2,0(sp)
    8000351c:	6105                	addi	sp,sp,32
    8000351e:	8082                	ret
    panic("freeing free block");
    80003520:	00005517          	auipc	a0,0x5
    80003524:	03850513          	addi	a0,a0,56 # 80008558 <syscalls+0x108>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	014080e7          	jalr	20(ra) # 8000053c <panic>

0000000080003530 <balloc>:
{
    80003530:	711d                	addi	sp,sp,-96
    80003532:	ec86                	sd	ra,88(sp)
    80003534:	e8a2                	sd	s0,80(sp)
    80003536:	e4a6                	sd	s1,72(sp)
    80003538:	e0ca                	sd	s2,64(sp)
    8000353a:	fc4e                	sd	s3,56(sp)
    8000353c:	f852                	sd	s4,48(sp)
    8000353e:	f456                	sd	s5,40(sp)
    80003540:	f05a                	sd	s6,32(sp)
    80003542:	ec5e                	sd	s7,24(sp)
    80003544:	e862                	sd	s8,16(sp)
    80003546:	e466                	sd	s9,8(sp)
    80003548:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000354a:	0001c797          	auipc	a5,0x1c
    8000354e:	5327a783          	lw	a5,1330(a5) # 8001fa7c <sb+0x4>
    80003552:	cff5                	beqz	a5,8000364e <balloc+0x11e>
    80003554:	8baa                	mv	s7,a0
    80003556:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003558:	0001cb17          	auipc	s6,0x1c
    8000355c:	520b0b13          	addi	s6,s6,1312 # 8001fa78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003560:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003562:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003564:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003566:	6c89                	lui	s9,0x2
    80003568:	a061                	j	800035f0 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000356a:	97ca                	add	a5,a5,s2
    8000356c:	8e55                	or	a2,a2,a3
    8000356e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003572:	854a                	mv	a0,s2
    80003574:	00001097          	auipc	ra,0x1
    80003578:	084080e7          	jalr	132(ra) # 800045f8 <log_write>
        brelse(bp);
    8000357c:	854a                	mv	a0,s2
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	e22080e7          	jalr	-478(ra) # 800033a0 <brelse>
  bp = bread(dev, bno);
    80003586:	85a6                	mv	a1,s1
    80003588:	855e                	mv	a0,s7
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	ce6080e7          	jalr	-794(ra) # 80003270 <bread>
    80003592:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003594:	40000613          	li	a2,1024
    80003598:	4581                	li	a1,0
    8000359a:	05850513          	addi	a0,a0,88
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	730080e7          	jalr	1840(ra) # 80000cce <memset>
  log_write(bp);
    800035a6:	854a                	mv	a0,s2
    800035a8:	00001097          	auipc	ra,0x1
    800035ac:	050080e7          	jalr	80(ra) # 800045f8 <log_write>
  brelse(bp);
    800035b0:	854a                	mv	a0,s2
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	dee080e7          	jalr	-530(ra) # 800033a0 <brelse>
}
    800035ba:	8526                	mv	a0,s1
    800035bc:	60e6                	ld	ra,88(sp)
    800035be:	6446                	ld	s0,80(sp)
    800035c0:	64a6                	ld	s1,72(sp)
    800035c2:	6906                	ld	s2,64(sp)
    800035c4:	79e2                	ld	s3,56(sp)
    800035c6:	7a42                	ld	s4,48(sp)
    800035c8:	7aa2                	ld	s5,40(sp)
    800035ca:	7b02                	ld	s6,32(sp)
    800035cc:	6be2                	ld	s7,24(sp)
    800035ce:	6c42                	ld	s8,16(sp)
    800035d0:	6ca2                	ld	s9,8(sp)
    800035d2:	6125                	addi	sp,sp,96
    800035d4:	8082                	ret
    brelse(bp);
    800035d6:	854a                	mv	a0,s2
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	dc8080e7          	jalr	-568(ra) # 800033a0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035e0:	015c87bb          	addw	a5,s9,s5
    800035e4:	00078a9b          	sext.w	s5,a5
    800035e8:	004b2703          	lw	a4,4(s6)
    800035ec:	06eaf163          	bgeu	s5,a4,8000364e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800035f0:	41fad79b          	sraiw	a5,s5,0x1f
    800035f4:	0137d79b          	srliw	a5,a5,0x13
    800035f8:	015787bb          	addw	a5,a5,s5
    800035fc:	40d7d79b          	sraiw	a5,a5,0xd
    80003600:	01cb2583          	lw	a1,28(s6)
    80003604:	9dbd                	addw	a1,a1,a5
    80003606:	855e                	mv	a0,s7
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	c68080e7          	jalr	-920(ra) # 80003270 <bread>
    80003610:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003612:	004b2503          	lw	a0,4(s6)
    80003616:	000a849b          	sext.w	s1,s5
    8000361a:	8762                	mv	a4,s8
    8000361c:	faa4fde3          	bgeu	s1,a0,800035d6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003620:	00777693          	andi	a3,a4,7
    80003624:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003628:	41f7579b          	sraiw	a5,a4,0x1f
    8000362c:	01d7d79b          	srliw	a5,a5,0x1d
    80003630:	9fb9                	addw	a5,a5,a4
    80003632:	4037d79b          	sraiw	a5,a5,0x3
    80003636:	00f90633          	add	a2,s2,a5
    8000363a:	05864603          	lbu	a2,88(a2)
    8000363e:	00c6f5b3          	and	a1,a3,a2
    80003642:	d585                	beqz	a1,8000356a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003644:	2705                	addiw	a4,a4,1
    80003646:	2485                	addiw	s1,s1,1
    80003648:	fd471ae3          	bne	a4,s4,8000361c <balloc+0xec>
    8000364c:	b769                	j	800035d6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000364e:	00005517          	auipc	a0,0x5
    80003652:	f2250513          	addi	a0,a0,-222 # 80008570 <syscalls+0x120>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	f30080e7          	jalr	-208(ra) # 80000586 <printf>
  return 0;
    8000365e:	4481                	li	s1,0
    80003660:	bfa9                	j	800035ba <balloc+0x8a>

0000000080003662 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003662:	7179                	addi	sp,sp,-48
    80003664:	f406                	sd	ra,40(sp)
    80003666:	f022                	sd	s0,32(sp)
    80003668:	ec26                	sd	s1,24(sp)
    8000366a:	e84a                	sd	s2,16(sp)
    8000366c:	e44e                	sd	s3,8(sp)
    8000366e:	e052                	sd	s4,0(sp)
    80003670:	1800                	addi	s0,sp,48
    80003672:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003674:	47ad                	li	a5,11
    80003676:	02b7e863          	bltu	a5,a1,800036a6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000367a:	02059793          	slli	a5,a1,0x20
    8000367e:	01e7d593          	srli	a1,a5,0x1e
    80003682:	00b504b3          	add	s1,a0,a1
    80003686:	0504a903          	lw	s2,80(s1)
    8000368a:	06091e63          	bnez	s2,80003706 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000368e:	4108                	lw	a0,0(a0)
    80003690:	00000097          	auipc	ra,0x0
    80003694:	ea0080e7          	jalr	-352(ra) # 80003530 <balloc>
    80003698:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000369c:	06090563          	beqz	s2,80003706 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800036a0:	0524a823          	sw	s2,80(s1)
    800036a4:	a08d                	j	80003706 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800036a6:	ff45849b          	addiw	s1,a1,-12
    800036aa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036ae:	0ff00793          	li	a5,255
    800036b2:	08e7e563          	bltu	a5,a4,8000373c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800036b6:	08052903          	lw	s2,128(a0)
    800036ba:	00091d63          	bnez	s2,800036d4 <bmap+0x72>
      addr = balloc(ip->dev);
    800036be:	4108                	lw	a0,0(a0)
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	e70080e7          	jalr	-400(ra) # 80003530 <balloc>
    800036c8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800036cc:	02090d63          	beqz	s2,80003706 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800036d0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800036d4:	85ca                	mv	a1,s2
    800036d6:	0009a503          	lw	a0,0(s3)
    800036da:	00000097          	auipc	ra,0x0
    800036de:	b96080e7          	jalr	-1130(ra) # 80003270 <bread>
    800036e2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036e4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036e8:	02049713          	slli	a4,s1,0x20
    800036ec:	01e75593          	srli	a1,a4,0x1e
    800036f0:	00b784b3          	add	s1,a5,a1
    800036f4:	0004a903          	lw	s2,0(s1)
    800036f8:	02090063          	beqz	s2,80003718 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036fc:	8552                	mv	a0,s4
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	ca2080e7          	jalr	-862(ra) # 800033a0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003706:	854a                	mv	a0,s2
    80003708:	70a2                	ld	ra,40(sp)
    8000370a:	7402                	ld	s0,32(sp)
    8000370c:	64e2                	ld	s1,24(sp)
    8000370e:	6942                	ld	s2,16(sp)
    80003710:	69a2                	ld	s3,8(sp)
    80003712:	6a02                	ld	s4,0(sp)
    80003714:	6145                	addi	sp,sp,48
    80003716:	8082                	ret
      addr = balloc(ip->dev);
    80003718:	0009a503          	lw	a0,0(s3)
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	e14080e7          	jalr	-492(ra) # 80003530 <balloc>
    80003724:	0005091b          	sext.w	s2,a0
      if(addr){
    80003728:	fc090ae3          	beqz	s2,800036fc <bmap+0x9a>
        a[bn] = addr;
    8000372c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003730:	8552                	mv	a0,s4
    80003732:	00001097          	auipc	ra,0x1
    80003736:	ec6080e7          	jalr	-314(ra) # 800045f8 <log_write>
    8000373a:	b7c9                	j	800036fc <bmap+0x9a>
  panic("bmap: out of range");
    8000373c:	00005517          	auipc	a0,0x5
    80003740:	e4c50513          	addi	a0,a0,-436 # 80008588 <syscalls+0x138>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	df8080e7          	jalr	-520(ra) # 8000053c <panic>

000000008000374c <iget>:
{
    8000374c:	7179                	addi	sp,sp,-48
    8000374e:	f406                	sd	ra,40(sp)
    80003750:	f022                	sd	s0,32(sp)
    80003752:	ec26                	sd	s1,24(sp)
    80003754:	e84a                	sd	s2,16(sp)
    80003756:	e44e                	sd	s3,8(sp)
    80003758:	e052                	sd	s4,0(sp)
    8000375a:	1800                	addi	s0,sp,48
    8000375c:	89aa                	mv	s3,a0
    8000375e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003760:	0001c517          	auipc	a0,0x1c
    80003764:	33850513          	addi	a0,a0,824 # 8001fa98 <itable>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	46a080e7          	jalr	1130(ra) # 80000bd2 <acquire>
  empty = 0;
    80003770:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003772:	0001c497          	auipc	s1,0x1c
    80003776:	33e48493          	addi	s1,s1,830 # 8001fab0 <itable+0x18>
    8000377a:	0001e697          	auipc	a3,0x1e
    8000377e:	dc668693          	addi	a3,a3,-570 # 80021540 <log>
    80003782:	a039                	j	80003790 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003784:	02090b63          	beqz	s2,800037ba <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003788:	08848493          	addi	s1,s1,136
    8000378c:	02d48a63          	beq	s1,a3,800037c0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003790:	449c                	lw	a5,8(s1)
    80003792:	fef059e3          	blez	a5,80003784 <iget+0x38>
    80003796:	4098                	lw	a4,0(s1)
    80003798:	ff3716e3          	bne	a4,s3,80003784 <iget+0x38>
    8000379c:	40d8                	lw	a4,4(s1)
    8000379e:	ff4713e3          	bne	a4,s4,80003784 <iget+0x38>
      ip->ref++;
    800037a2:	2785                	addiw	a5,a5,1
    800037a4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037a6:	0001c517          	auipc	a0,0x1c
    800037aa:	2f250513          	addi	a0,a0,754 # 8001fa98 <itable>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	4d8080e7          	jalr	1240(ra) # 80000c86 <release>
      return ip;
    800037b6:	8926                	mv	s2,s1
    800037b8:	a03d                	j	800037e6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037ba:	f7f9                	bnez	a5,80003788 <iget+0x3c>
    800037bc:	8926                	mv	s2,s1
    800037be:	b7e9                	j	80003788 <iget+0x3c>
  if(empty == 0)
    800037c0:	02090c63          	beqz	s2,800037f8 <iget+0xac>
  ip->dev = dev;
    800037c4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800037c8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800037cc:	4785                	li	a5,1
    800037ce:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037d2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037d6:	0001c517          	auipc	a0,0x1c
    800037da:	2c250513          	addi	a0,a0,706 # 8001fa98 <itable>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	4a8080e7          	jalr	1192(ra) # 80000c86 <release>
}
    800037e6:	854a                	mv	a0,s2
    800037e8:	70a2                	ld	ra,40(sp)
    800037ea:	7402                	ld	s0,32(sp)
    800037ec:	64e2                	ld	s1,24(sp)
    800037ee:	6942                	ld	s2,16(sp)
    800037f0:	69a2                	ld	s3,8(sp)
    800037f2:	6a02                	ld	s4,0(sp)
    800037f4:	6145                	addi	sp,sp,48
    800037f6:	8082                	ret
    panic("iget: no inodes");
    800037f8:	00005517          	auipc	a0,0x5
    800037fc:	da850513          	addi	a0,a0,-600 # 800085a0 <syscalls+0x150>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	d3c080e7          	jalr	-708(ra) # 8000053c <panic>

0000000080003808 <fsinit>:
fsinit(int dev) {
    80003808:	7179                	addi	sp,sp,-48
    8000380a:	f406                	sd	ra,40(sp)
    8000380c:	f022                	sd	s0,32(sp)
    8000380e:	ec26                	sd	s1,24(sp)
    80003810:	e84a                	sd	s2,16(sp)
    80003812:	e44e                	sd	s3,8(sp)
    80003814:	1800                	addi	s0,sp,48
    80003816:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003818:	4585                	li	a1,1
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	a56080e7          	jalr	-1450(ra) # 80003270 <bread>
    80003822:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003824:	0001c997          	auipc	s3,0x1c
    80003828:	25498993          	addi	s3,s3,596 # 8001fa78 <sb>
    8000382c:	02000613          	li	a2,32
    80003830:	05850593          	addi	a1,a0,88
    80003834:	854e                	mv	a0,s3
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	4f4080e7          	jalr	1268(ra) # 80000d2a <memmove>
  brelse(bp);
    8000383e:	8526                	mv	a0,s1
    80003840:	00000097          	auipc	ra,0x0
    80003844:	b60080e7          	jalr	-1184(ra) # 800033a0 <brelse>
  if(sb.magic != FSMAGIC)
    80003848:	0009a703          	lw	a4,0(s3)
    8000384c:	102037b7          	lui	a5,0x10203
    80003850:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003854:	02f71263          	bne	a4,a5,80003878 <fsinit+0x70>
  initlog(dev, &sb);
    80003858:	0001c597          	auipc	a1,0x1c
    8000385c:	22058593          	addi	a1,a1,544 # 8001fa78 <sb>
    80003860:	854a                	mv	a0,s2
    80003862:	00001097          	auipc	ra,0x1
    80003866:	b2c080e7          	jalr	-1236(ra) # 8000438e <initlog>
}
    8000386a:	70a2                	ld	ra,40(sp)
    8000386c:	7402                	ld	s0,32(sp)
    8000386e:	64e2                	ld	s1,24(sp)
    80003870:	6942                	ld	s2,16(sp)
    80003872:	69a2                	ld	s3,8(sp)
    80003874:	6145                	addi	sp,sp,48
    80003876:	8082                	ret
    panic("invalid file system");
    80003878:	00005517          	auipc	a0,0x5
    8000387c:	d3850513          	addi	a0,a0,-712 # 800085b0 <syscalls+0x160>
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	cbc080e7          	jalr	-836(ra) # 8000053c <panic>

0000000080003888 <iinit>:
{
    80003888:	7179                	addi	sp,sp,-48
    8000388a:	f406                	sd	ra,40(sp)
    8000388c:	f022                	sd	s0,32(sp)
    8000388e:	ec26                	sd	s1,24(sp)
    80003890:	e84a                	sd	s2,16(sp)
    80003892:	e44e                	sd	s3,8(sp)
    80003894:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003896:	00005597          	auipc	a1,0x5
    8000389a:	d3258593          	addi	a1,a1,-718 # 800085c8 <syscalls+0x178>
    8000389e:	0001c517          	auipc	a0,0x1c
    800038a2:	1fa50513          	addi	a0,a0,506 # 8001fa98 <itable>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	29c080e7          	jalr	668(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038ae:	0001c497          	auipc	s1,0x1c
    800038b2:	21248493          	addi	s1,s1,530 # 8001fac0 <itable+0x28>
    800038b6:	0001e997          	auipc	s3,0x1e
    800038ba:	c9a98993          	addi	s3,s3,-870 # 80021550 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038be:	00005917          	auipc	s2,0x5
    800038c2:	d1290913          	addi	s2,s2,-750 # 800085d0 <syscalls+0x180>
    800038c6:	85ca                	mv	a1,s2
    800038c8:	8526                	mv	a0,s1
    800038ca:	00001097          	auipc	ra,0x1
    800038ce:	e12080e7          	jalr	-494(ra) # 800046dc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038d2:	08848493          	addi	s1,s1,136
    800038d6:	ff3498e3          	bne	s1,s3,800038c6 <iinit+0x3e>
}
    800038da:	70a2                	ld	ra,40(sp)
    800038dc:	7402                	ld	s0,32(sp)
    800038de:	64e2                	ld	s1,24(sp)
    800038e0:	6942                	ld	s2,16(sp)
    800038e2:	69a2                	ld	s3,8(sp)
    800038e4:	6145                	addi	sp,sp,48
    800038e6:	8082                	ret

00000000800038e8 <ialloc>:
{
    800038e8:	7139                	addi	sp,sp,-64
    800038ea:	fc06                	sd	ra,56(sp)
    800038ec:	f822                	sd	s0,48(sp)
    800038ee:	f426                	sd	s1,40(sp)
    800038f0:	f04a                	sd	s2,32(sp)
    800038f2:	ec4e                	sd	s3,24(sp)
    800038f4:	e852                	sd	s4,16(sp)
    800038f6:	e456                	sd	s5,8(sp)
    800038f8:	e05a                	sd	s6,0(sp)
    800038fa:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800038fc:	0001c717          	auipc	a4,0x1c
    80003900:	18872703          	lw	a4,392(a4) # 8001fa84 <sb+0xc>
    80003904:	4785                	li	a5,1
    80003906:	04e7f863          	bgeu	a5,a4,80003956 <ialloc+0x6e>
    8000390a:	8aaa                	mv	s5,a0
    8000390c:	8b2e                	mv	s6,a1
    8000390e:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003910:	0001ca17          	auipc	s4,0x1c
    80003914:	168a0a13          	addi	s4,s4,360 # 8001fa78 <sb>
    80003918:	00495593          	srli	a1,s2,0x4
    8000391c:	018a2783          	lw	a5,24(s4)
    80003920:	9dbd                	addw	a1,a1,a5
    80003922:	8556                	mv	a0,s5
    80003924:	00000097          	auipc	ra,0x0
    80003928:	94c080e7          	jalr	-1716(ra) # 80003270 <bread>
    8000392c:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000392e:	05850993          	addi	s3,a0,88
    80003932:	00f97793          	andi	a5,s2,15
    80003936:	079a                	slli	a5,a5,0x6
    80003938:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000393a:	00099783          	lh	a5,0(s3)
    8000393e:	cf9d                	beqz	a5,8000397c <ialloc+0x94>
    brelse(bp);
    80003940:	00000097          	auipc	ra,0x0
    80003944:	a60080e7          	jalr	-1440(ra) # 800033a0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003948:	0905                	addi	s2,s2,1
    8000394a:	00ca2703          	lw	a4,12(s4)
    8000394e:	0009079b          	sext.w	a5,s2
    80003952:	fce7e3e3          	bltu	a5,a4,80003918 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003956:	00005517          	auipc	a0,0x5
    8000395a:	c8250513          	addi	a0,a0,-894 # 800085d8 <syscalls+0x188>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	c28080e7          	jalr	-984(ra) # 80000586 <printf>
  return 0;
    80003966:	4501                	li	a0,0
}
    80003968:	70e2                	ld	ra,56(sp)
    8000396a:	7442                	ld	s0,48(sp)
    8000396c:	74a2                	ld	s1,40(sp)
    8000396e:	7902                	ld	s2,32(sp)
    80003970:	69e2                	ld	s3,24(sp)
    80003972:	6a42                	ld	s4,16(sp)
    80003974:	6aa2                	ld	s5,8(sp)
    80003976:	6b02                	ld	s6,0(sp)
    80003978:	6121                	addi	sp,sp,64
    8000397a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000397c:	04000613          	li	a2,64
    80003980:	4581                	li	a1,0
    80003982:	854e                	mv	a0,s3
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	34a080e7          	jalr	842(ra) # 80000cce <memset>
      dip->type = type;
    8000398c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003990:	8526                	mv	a0,s1
    80003992:	00001097          	auipc	ra,0x1
    80003996:	c66080e7          	jalr	-922(ra) # 800045f8 <log_write>
      brelse(bp);
    8000399a:	8526                	mv	a0,s1
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	a04080e7          	jalr	-1532(ra) # 800033a0 <brelse>
      return iget(dev, inum);
    800039a4:	0009059b          	sext.w	a1,s2
    800039a8:	8556                	mv	a0,s5
    800039aa:	00000097          	auipc	ra,0x0
    800039ae:	da2080e7          	jalr	-606(ra) # 8000374c <iget>
    800039b2:	bf5d                	j	80003968 <ialloc+0x80>

00000000800039b4 <iupdate>:
{
    800039b4:	1101                	addi	sp,sp,-32
    800039b6:	ec06                	sd	ra,24(sp)
    800039b8:	e822                	sd	s0,16(sp)
    800039ba:	e426                	sd	s1,8(sp)
    800039bc:	e04a                	sd	s2,0(sp)
    800039be:	1000                	addi	s0,sp,32
    800039c0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039c2:	415c                	lw	a5,4(a0)
    800039c4:	0047d79b          	srliw	a5,a5,0x4
    800039c8:	0001c597          	auipc	a1,0x1c
    800039cc:	0c85a583          	lw	a1,200(a1) # 8001fa90 <sb+0x18>
    800039d0:	9dbd                	addw	a1,a1,a5
    800039d2:	4108                	lw	a0,0(a0)
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	89c080e7          	jalr	-1892(ra) # 80003270 <bread>
    800039dc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039de:	05850793          	addi	a5,a0,88
    800039e2:	40d8                	lw	a4,4(s1)
    800039e4:	8b3d                	andi	a4,a4,15
    800039e6:	071a                	slli	a4,a4,0x6
    800039e8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800039ea:	04449703          	lh	a4,68(s1)
    800039ee:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800039f2:	04649703          	lh	a4,70(s1)
    800039f6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800039fa:	04849703          	lh	a4,72(s1)
    800039fe:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a02:	04a49703          	lh	a4,74(s1)
    80003a06:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a0a:	44f8                	lw	a4,76(s1)
    80003a0c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a0e:	03400613          	li	a2,52
    80003a12:	05048593          	addi	a1,s1,80
    80003a16:	00c78513          	addi	a0,a5,12
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	310080e7          	jalr	784(ra) # 80000d2a <memmove>
  log_write(bp);
    80003a22:	854a                	mv	a0,s2
    80003a24:	00001097          	auipc	ra,0x1
    80003a28:	bd4080e7          	jalr	-1068(ra) # 800045f8 <log_write>
  brelse(bp);
    80003a2c:	854a                	mv	a0,s2
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	972080e7          	jalr	-1678(ra) # 800033a0 <brelse>
}
    80003a36:	60e2                	ld	ra,24(sp)
    80003a38:	6442                	ld	s0,16(sp)
    80003a3a:	64a2                	ld	s1,8(sp)
    80003a3c:	6902                	ld	s2,0(sp)
    80003a3e:	6105                	addi	sp,sp,32
    80003a40:	8082                	ret

0000000080003a42 <idup>:
{
    80003a42:	1101                	addi	sp,sp,-32
    80003a44:	ec06                	sd	ra,24(sp)
    80003a46:	e822                	sd	s0,16(sp)
    80003a48:	e426                	sd	s1,8(sp)
    80003a4a:	1000                	addi	s0,sp,32
    80003a4c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a4e:	0001c517          	auipc	a0,0x1c
    80003a52:	04a50513          	addi	a0,a0,74 # 8001fa98 <itable>
    80003a56:	ffffd097          	auipc	ra,0xffffd
    80003a5a:	17c080e7          	jalr	380(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003a5e:	449c                	lw	a5,8(s1)
    80003a60:	2785                	addiw	a5,a5,1
    80003a62:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a64:	0001c517          	auipc	a0,0x1c
    80003a68:	03450513          	addi	a0,a0,52 # 8001fa98 <itable>
    80003a6c:	ffffd097          	auipc	ra,0xffffd
    80003a70:	21a080e7          	jalr	538(ra) # 80000c86 <release>
}
    80003a74:	8526                	mv	a0,s1
    80003a76:	60e2                	ld	ra,24(sp)
    80003a78:	6442                	ld	s0,16(sp)
    80003a7a:	64a2                	ld	s1,8(sp)
    80003a7c:	6105                	addi	sp,sp,32
    80003a7e:	8082                	ret

0000000080003a80 <ilock>:
{
    80003a80:	1101                	addi	sp,sp,-32
    80003a82:	ec06                	sd	ra,24(sp)
    80003a84:	e822                	sd	s0,16(sp)
    80003a86:	e426                	sd	s1,8(sp)
    80003a88:	e04a                	sd	s2,0(sp)
    80003a8a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a8c:	c115                	beqz	a0,80003ab0 <ilock+0x30>
    80003a8e:	84aa                	mv	s1,a0
    80003a90:	451c                	lw	a5,8(a0)
    80003a92:	00f05f63          	blez	a5,80003ab0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a96:	0541                	addi	a0,a0,16
    80003a98:	00001097          	auipc	ra,0x1
    80003a9c:	c7e080e7          	jalr	-898(ra) # 80004716 <acquiresleep>
  if(ip->valid == 0){
    80003aa0:	40bc                	lw	a5,64(s1)
    80003aa2:	cf99                	beqz	a5,80003ac0 <ilock+0x40>
}
    80003aa4:	60e2                	ld	ra,24(sp)
    80003aa6:	6442                	ld	s0,16(sp)
    80003aa8:	64a2                	ld	s1,8(sp)
    80003aaa:	6902                	ld	s2,0(sp)
    80003aac:	6105                	addi	sp,sp,32
    80003aae:	8082                	ret
    panic("ilock");
    80003ab0:	00005517          	auipc	a0,0x5
    80003ab4:	b4050513          	addi	a0,a0,-1216 # 800085f0 <syscalls+0x1a0>
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	a84080e7          	jalr	-1404(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ac0:	40dc                	lw	a5,4(s1)
    80003ac2:	0047d79b          	srliw	a5,a5,0x4
    80003ac6:	0001c597          	auipc	a1,0x1c
    80003aca:	fca5a583          	lw	a1,-54(a1) # 8001fa90 <sb+0x18>
    80003ace:	9dbd                	addw	a1,a1,a5
    80003ad0:	4088                	lw	a0,0(s1)
    80003ad2:	fffff097          	auipc	ra,0xfffff
    80003ad6:	79e080e7          	jalr	1950(ra) # 80003270 <bread>
    80003ada:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003adc:	05850593          	addi	a1,a0,88
    80003ae0:	40dc                	lw	a5,4(s1)
    80003ae2:	8bbd                	andi	a5,a5,15
    80003ae4:	079a                	slli	a5,a5,0x6
    80003ae6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ae8:	00059783          	lh	a5,0(a1)
    80003aec:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003af0:	00259783          	lh	a5,2(a1)
    80003af4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003af8:	00459783          	lh	a5,4(a1)
    80003afc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b00:	00659783          	lh	a5,6(a1)
    80003b04:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b08:	459c                	lw	a5,8(a1)
    80003b0a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b0c:	03400613          	li	a2,52
    80003b10:	05b1                	addi	a1,a1,12
    80003b12:	05048513          	addi	a0,s1,80
    80003b16:	ffffd097          	auipc	ra,0xffffd
    80003b1a:	214080e7          	jalr	532(ra) # 80000d2a <memmove>
    brelse(bp);
    80003b1e:	854a                	mv	a0,s2
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	880080e7          	jalr	-1920(ra) # 800033a0 <brelse>
    ip->valid = 1;
    80003b28:	4785                	li	a5,1
    80003b2a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b2c:	04449783          	lh	a5,68(s1)
    80003b30:	fbb5                	bnez	a5,80003aa4 <ilock+0x24>
      panic("ilock: no type");
    80003b32:	00005517          	auipc	a0,0x5
    80003b36:	ac650513          	addi	a0,a0,-1338 # 800085f8 <syscalls+0x1a8>
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	a02080e7          	jalr	-1534(ra) # 8000053c <panic>

0000000080003b42 <iunlock>:
{
    80003b42:	1101                	addi	sp,sp,-32
    80003b44:	ec06                	sd	ra,24(sp)
    80003b46:	e822                	sd	s0,16(sp)
    80003b48:	e426                	sd	s1,8(sp)
    80003b4a:	e04a                	sd	s2,0(sp)
    80003b4c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b4e:	c905                	beqz	a0,80003b7e <iunlock+0x3c>
    80003b50:	84aa                	mv	s1,a0
    80003b52:	01050913          	addi	s2,a0,16
    80003b56:	854a                	mv	a0,s2
    80003b58:	00001097          	auipc	ra,0x1
    80003b5c:	c58080e7          	jalr	-936(ra) # 800047b0 <holdingsleep>
    80003b60:	cd19                	beqz	a0,80003b7e <iunlock+0x3c>
    80003b62:	449c                	lw	a5,8(s1)
    80003b64:	00f05d63          	blez	a5,80003b7e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b68:	854a                	mv	a0,s2
    80003b6a:	00001097          	auipc	ra,0x1
    80003b6e:	c02080e7          	jalr	-1022(ra) # 8000476c <releasesleep>
}
    80003b72:	60e2                	ld	ra,24(sp)
    80003b74:	6442                	ld	s0,16(sp)
    80003b76:	64a2                	ld	s1,8(sp)
    80003b78:	6902                	ld	s2,0(sp)
    80003b7a:	6105                	addi	sp,sp,32
    80003b7c:	8082                	ret
    panic("iunlock");
    80003b7e:	00005517          	auipc	a0,0x5
    80003b82:	a8a50513          	addi	a0,a0,-1398 # 80008608 <syscalls+0x1b8>
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	9b6080e7          	jalr	-1610(ra) # 8000053c <panic>

0000000080003b8e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b8e:	7179                	addi	sp,sp,-48
    80003b90:	f406                	sd	ra,40(sp)
    80003b92:	f022                	sd	s0,32(sp)
    80003b94:	ec26                	sd	s1,24(sp)
    80003b96:	e84a                	sd	s2,16(sp)
    80003b98:	e44e                	sd	s3,8(sp)
    80003b9a:	e052                	sd	s4,0(sp)
    80003b9c:	1800                	addi	s0,sp,48
    80003b9e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ba0:	05050493          	addi	s1,a0,80
    80003ba4:	08050913          	addi	s2,a0,128
    80003ba8:	a021                	j	80003bb0 <itrunc+0x22>
    80003baa:	0491                	addi	s1,s1,4
    80003bac:	01248d63          	beq	s1,s2,80003bc6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003bb0:	408c                	lw	a1,0(s1)
    80003bb2:	dde5                	beqz	a1,80003baa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003bb4:	0009a503          	lw	a0,0(s3)
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	8fc080e7          	jalr	-1796(ra) # 800034b4 <bfree>
      ip->addrs[i] = 0;
    80003bc0:	0004a023          	sw	zero,0(s1)
    80003bc4:	b7dd                	j	80003baa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003bc6:	0809a583          	lw	a1,128(s3)
    80003bca:	e185                	bnez	a1,80003bea <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003bcc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003bd0:	854e                	mv	a0,s3
    80003bd2:	00000097          	auipc	ra,0x0
    80003bd6:	de2080e7          	jalr	-542(ra) # 800039b4 <iupdate>
}
    80003bda:	70a2                	ld	ra,40(sp)
    80003bdc:	7402                	ld	s0,32(sp)
    80003bde:	64e2                	ld	s1,24(sp)
    80003be0:	6942                	ld	s2,16(sp)
    80003be2:	69a2                	ld	s3,8(sp)
    80003be4:	6a02                	ld	s4,0(sp)
    80003be6:	6145                	addi	sp,sp,48
    80003be8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bea:	0009a503          	lw	a0,0(s3)
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	682080e7          	jalr	1666(ra) # 80003270 <bread>
    80003bf6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bf8:	05850493          	addi	s1,a0,88
    80003bfc:	45850913          	addi	s2,a0,1112
    80003c00:	a021                	j	80003c08 <itrunc+0x7a>
    80003c02:	0491                	addi	s1,s1,4
    80003c04:	01248b63          	beq	s1,s2,80003c1a <itrunc+0x8c>
      if(a[j])
    80003c08:	408c                	lw	a1,0(s1)
    80003c0a:	dde5                	beqz	a1,80003c02 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c0c:	0009a503          	lw	a0,0(s3)
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	8a4080e7          	jalr	-1884(ra) # 800034b4 <bfree>
    80003c18:	b7ed                	j	80003c02 <itrunc+0x74>
    brelse(bp);
    80003c1a:	8552                	mv	a0,s4
    80003c1c:	fffff097          	auipc	ra,0xfffff
    80003c20:	784080e7          	jalr	1924(ra) # 800033a0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c24:	0809a583          	lw	a1,128(s3)
    80003c28:	0009a503          	lw	a0,0(s3)
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	888080e7          	jalr	-1912(ra) # 800034b4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c34:	0809a023          	sw	zero,128(s3)
    80003c38:	bf51                	j	80003bcc <itrunc+0x3e>

0000000080003c3a <iput>:
{
    80003c3a:	1101                	addi	sp,sp,-32
    80003c3c:	ec06                	sd	ra,24(sp)
    80003c3e:	e822                	sd	s0,16(sp)
    80003c40:	e426                	sd	s1,8(sp)
    80003c42:	e04a                	sd	s2,0(sp)
    80003c44:	1000                	addi	s0,sp,32
    80003c46:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c48:	0001c517          	auipc	a0,0x1c
    80003c4c:	e5050513          	addi	a0,a0,-432 # 8001fa98 <itable>
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	f82080e7          	jalr	-126(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c58:	4498                	lw	a4,8(s1)
    80003c5a:	4785                	li	a5,1
    80003c5c:	02f70363          	beq	a4,a5,80003c82 <iput+0x48>
  ip->ref--;
    80003c60:	449c                	lw	a5,8(s1)
    80003c62:	37fd                	addiw	a5,a5,-1
    80003c64:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c66:	0001c517          	auipc	a0,0x1c
    80003c6a:	e3250513          	addi	a0,a0,-462 # 8001fa98 <itable>
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	018080e7          	jalr	24(ra) # 80000c86 <release>
}
    80003c76:	60e2                	ld	ra,24(sp)
    80003c78:	6442                	ld	s0,16(sp)
    80003c7a:	64a2                	ld	s1,8(sp)
    80003c7c:	6902                	ld	s2,0(sp)
    80003c7e:	6105                	addi	sp,sp,32
    80003c80:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c82:	40bc                	lw	a5,64(s1)
    80003c84:	dff1                	beqz	a5,80003c60 <iput+0x26>
    80003c86:	04a49783          	lh	a5,74(s1)
    80003c8a:	fbf9                	bnez	a5,80003c60 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c8c:	01048913          	addi	s2,s1,16
    80003c90:	854a                	mv	a0,s2
    80003c92:	00001097          	auipc	ra,0x1
    80003c96:	a84080e7          	jalr	-1404(ra) # 80004716 <acquiresleep>
    release(&itable.lock);
    80003c9a:	0001c517          	auipc	a0,0x1c
    80003c9e:	dfe50513          	addi	a0,a0,-514 # 8001fa98 <itable>
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	fe4080e7          	jalr	-28(ra) # 80000c86 <release>
    itrunc(ip);
    80003caa:	8526                	mv	a0,s1
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	ee2080e7          	jalr	-286(ra) # 80003b8e <itrunc>
    ip->type = 0;
    80003cb4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003cb8:	8526                	mv	a0,s1
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	cfa080e7          	jalr	-774(ra) # 800039b4 <iupdate>
    ip->valid = 0;
    80003cc2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	00001097          	auipc	ra,0x1
    80003ccc:	aa4080e7          	jalr	-1372(ra) # 8000476c <releasesleep>
    acquire(&itable.lock);
    80003cd0:	0001c517          	auipc	a0,0x1c
    80003cd4:	dc850513          	addi	a0,a0,-568 # 8001fa98 <itable>
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	efa080e7          	jalr	-262(ra) # 80000bd2 <acquire>
    80003ce0:	b741                	j	80003c60 <iput+0x26>

0000000080003ce2 <iunlockput>:
{
    80003ce2:	1101                	addi	sp,sp,-32
    80003ce4:	ec06                	sd	ra,24(sp)
    80003ce6:	e822                	sd	s0,16(sp)
    80003ce8:	e426                	sd	s1,8(sp)
    80003cea:	1000                	addi	s0,sp,32
    80003cec:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	e54080e7          	jalr	-428(ra) # 80003b42 <iunlock>
  iput(ip);
    80003cf6:	8526                	mv	a0,s1
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	f42080e7          	jalr	-190(ra) # 80003c3a <iput>
}
    80003d00:	60e2                	ld	ra,24(sp)
    80003d02:	6442                	ld	s0,16(sp)
    80003d04:	64a2                	ld	s1,8(sp)
    80003d06:	6105                	addi	sp,sp,32
    80003d08:	8082                	ret

0000000080003d0a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d0a:	1141                	addi	sp,sp,-16
    80003d0c:	e422                	sd	s0,8(sp)
    80003d0e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d10:	411c                	lw	a5,0(a0)
    80003d12:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d14:	415c                	lw	a5,4(a0)
    80003d16:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d18:	04451783          	lh	a5,68(a0)
    80003d1c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d20:	04a51783          	lh	a5,74(a0)
    80003d24:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d28:	04c56783          	lwu	a5,76(a0)
    80003d2c:	e99c                	sd	a5,16(a1)
}
    80003d2e:	6422                	ld	s0,8(sp)
    80003d30:	0141                	addi	sp,sp,16
    80003d32:	8082                	ret

0000000080003d34 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d34:	457c                	lw	a5,76(a0)
    80003d36:	0ed7e963          	bltu	a5,a3,80003e28 <readi+0xf4>
{
    80003d3a:	7159                	addi	sp,sp,-112
    80003d3c:	f486                	sd	ra,104(sp)
    80003d3e:	f0a2                	sd	s0,96(sp)
    80003d40:	eca6                	sd	s1,88(sp)
    80003d42:	e8ca                	sd	s2,80(sp)
    80003d44:	e4ce                	sd	s3,72(sp)
    80003d46:	e0d2                	sd	s4,64(sp)
    80003d48:	fc56                	sd	s5,56(sp)
    80003d4a:	f85a                	sd	s6,48(sp)
    80003d4c:	f45e                	sd	s7,40(sp)
    80003d4e:	f062                	sd	s8,32(sp)
    80003d50:	ec66                	sd	s9,24(sp)
    80003d52:	e86a                	sd	s10,16(sp)
    80003d54:	e46e                	sd	s11,8(sp)
    80003d56:	1880                	addi	s0,sp,112
    80003d58:	8b2a                	mv	s6,a0
    80003d5a:	8bae                	mv	s7,a1
    80003d5c:	8a32                	mv	s4,a2
    80003d5e:	84b6                	mv	s1,a3
    80003d60:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d62:	9f35                	addw	a4,a4,a3
    return 0;
    80003d64:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d66:	0ad76063          	bltu	a4,a3,80003e06 <readi+0xd2>
  if(off + n > ip->size)
    80003d6a:	00e7f463          	bgeu	a5,a4,80003d72 <readi+0x3e>
    n = ip->size - off;
    80003d6e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d72:	0a0a8963          	beqz	s5,80003e24 <readi+0xf0>
    80003d76:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d78:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d7c:	5c7d                	li	s8,-1
    80003d7e:	a82d                	j	80003db8 <readi+0x84>
    80003d80:	020d1d93          	slli	s11,s10,0x20
    80003d84:	020ddd93          	srli	s11,s11,0x20
    80003d88:	05890613          	addi	a2,s2,88
    80003d8c:	86ee                	mv	a3,s11
    80003d8e:	963a                	add	a2,a2,a4
    80003d90:	85d2                	mv	a1,s4
    80003d92:	855e                	mv	a0,s7
    80003d94:	ffffe097          	auipc	ra,0xffffe
    80003d98:	7be080e7          	jalr	1982(ra) # 80002552 <either_copyout>
    80003d9c:	05850d63          	beq	a0,s8,80003df6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003da0:	854a                	mv	a0,s2
    80003da2:	fffff097          	auipc	ra,0xfffff
    80003da6:	5fe080e7          	jalr	1534(ra) # 800033a0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003daa:	013d09bb          	addw	s3,s10,s3
    80003dae:	009d04bb          	addw	s1,s10,s1
    80003db2:	9a6e                	add	s4,s4,s11
    80003db4:	0559f763          	bgeu	s3,s5,80003e02 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003db8:	00a4d59b          	srliw	a1,s1,0xa
    80003dbc:	855a                	mv	a0,s6
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	8a4080e7          	jalr	-1884(ra) # 80003662 <bmap>
    80003dc6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003dca:	cd85                	beqz	a1,80003e02 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003dcc:	000b2503          	lw	a0,0(s6)
    80003dd0:	fffff097          	auipc	ra,0xfffff
    80003dd4:	4a0080e7          	jalr	1184(ra) # 80003270 <bread>
    80003dd8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dda:	3ff4f713          	andi	a4,s1,1023
    80003dde:	40ec87bb          	subw	a5,s9,a4
    80003de2:	413a86bb          	subw	a3,s5,s3
    80003de6:	8d3e                	mv	s10,a5
    80003de8:	2781                	sext.w	a5,a5
    80003dea:	0006861b          	sext.w	a2,a3
    80003dee:	f8f679e3          	bgeu	a2,a5,80003d80 <readi+0x4c>
    80003df2:	8d36                	mv	s10,a3
    80003df4:	b771                	j	80003d80 <readi+0x4c>
      brelse(bp);
    80003df6:	854a                	mv	a0,s2
    80003df8:	fffff097          	auipc	ra,0xfffff
    80003dfc:	5a8080e7          	jalr	1448(ra) # 800033a0 <brelse>
      tot = -1;
    80003e00:	59fd                	li	s3,-1
  }
  return tot;
    80003e02:	0009851b          	sext.w	a0,s3
}
    80003e06:	70a6                	ld	ra,104(sp)
    80003e08:	7406                	ld	s0,96(sp)
    80003e0a:	64e6                	ld	s1,88(sp)
    80003e0c:	6946                	ld	s2,80(sp)
    80003e0e:	69a6                	ld	s3,72(sp)
    80003e10:	6a06                	ld	s4,64(sp)
    80003e12:	7ae2                	ld	s5,56(sp)
    80003e14:	7b42                	ld	s6,48(sp)
    80003e16:	7ba2                	ld	s7,40(sp)
    80003e18:	7c02                	ld	s8,32(sp)
    80003e1a:	6ce2                	ld	s9,24(sp)
    80003e1c:	6d42                	ld	s10,16(sp)
    80003e1e:	6da2                	ld	s11,8(sp)
    80003e20:	6165                	addi	sp,sp,112
    80003e22:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e24:	89d6                	mv	s3,s5
    80003e26:	bff1                	j	80003e02 <readi+0xce>
    return 0;
    80003e28:	4501                	li	a0,0
}
    80003e2a:	8082                	ret

0000000080003e2c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e2c:	457c                	lw	a5,76(a0)
    80003e2e:	10d7e863          	bltu	a5,a3,80003f3e <writei+0x112>
{
    80003e32:	7159                	addi	sp,sp,-112
    80003e34:	f486                	sd	ra,104(sp)
    80003e36:	f0a2                	sd	s0,96(sp)
    80003e38:	eca6                	sd	s1,88(sp)
    80003e3a:	e8ca                	sd	s2,80(sp)
    80003e3c:	e4ce                	sd	s3,72(sp)
    80003e3e:	e0d2                	sd	s4,64(sp)
    80003e40:	fc56                	sd	s5,56(sp)
    80003e42:	f85a                	sd	s6,48(sp)
    80003e44:	f45e                	sd	s7,40(sp)
    80003e46:	f062                	sd	s8,32(sp)
    80003e48:	ec66                	sd	s9,24(sp)
    80003e4a:	e86a                	sd	s10,16(sp)
    80003e4c:	e46e                	sd	s11,8(sp)
    80003e4e:	1880                	addi	s0,sp,112
    80003e50:	8aaa                	mv	s5,a0
    80003e52:	8bae                	mv	s7,a1
    80003e54:	8a32                	mv	s4,a2
    80003e56:	8936                	mv	s2,a3
    80003e58:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e5a:	00e687bb          	addw	a5,a3,a4
    80003e5e:	0ed7e263          	bltu	a5,a3,80003f42 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e62:	00043737          	lui	a4,0x43
    80003e66:	0ef76063          	bltu	a4,a5,80003f46 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e6a:	0c0b0863          	beqz	s6,80003f3a <writei+0x10e>
    80003e6e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e70:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e74:	5c7d                	li	s8,-1
    80003e76:	a091                	j	80003eba <writei+0x8e>
    80003e78:	020d1d93          	slli	s11,s10,0x20
    80003e7c:	020ddd93          	srli	s11,s11,0x20
    80003e80:	05848513          	addi	a0,s1,88
    80003e84:	86ee                	mv	a3,s11
    80003e86:	8652                	mv	a2,s4
    80003e88:	85de                	mv	a1,s7
    80003e8a:	953a                	add	a0,a0,a4
    80003e8c:	ffffe097          	auipc	ra,0xffffe
    80003e90:	71c080e7          	jalr	1820(ra) # 800025a8 <either_copyin>
    80003e94:	07850263          	beq	a0,s8,80003ef8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e98:	8526                	mv	a0,s1
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	75e080e7          	jalr	1886(ra) # 800045f8 <log_write>
    brelse(bp);
    80003ea2:	8526                	mv	a0,s1
    80003ea4:	fffff097          	auipc	ra,0xfffff
    80003ea8:	4fc080e7          	jalr	1276(ra) # 800033a0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eac:	013d09bb          	addw	s3,s10,s3
    80003eb0:	012d093b          	addw	s2,s10,s2
    80003eb4:	9a6e                	add	s4,s4,s11
    80003eb6:	0569f663          	bgeu	s3,s6,80003f02 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003eba:	00a9559b          	srliw	a1,s2,0xa
    80003ebe:	8556                	mv	a0,s5
    80003ec0:	fffff097          	auipc	ra,0xfffff
    80003ec4:	7a2080e7          	jalr	1954(ra) # 80003662 <bmap>
    80003ec8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ecc:	c99d                	beqz	a1,80003f02 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003ece:	000aa503          	lw	a0,0(s5)
    80003ed2:	fffff097          	auipc	ra,0xfffff
    80003ed6:	39e080e7          	jalr	926(ra) # 80003270 <bread>
    80003eda:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003edc:	3ff97713          	andi	a4,s2,1023
    80003ee0:	40ec87bb          	subw	a5,s9,a4
    80003ee4:	413b06bb          	subw	a3,s6,s3
    80003ee8:	8d3e                	mv	s10,a5
    80003eea:	2781                	sext.w	a5,a5
    80003eec:	0006861b          	sext.w	a2,a3
    80003ef0:	f8f674e3          	bgeu	a2,a5,80003e78 <writei+0x4c>
    80003ef4:	8d36                	mv	s10,a3
    80003ef6:	b749                	j	80003e78 <writei+0x4c>
      brelse(bp);
    80003ef8:	8526                	mv	a0,s1
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	4a6080e7          	jalr	1190(ra) # 800033a0 <brelse>
  }

  if(off > ip->size)
    80003f02:	04caa783          	lw	a5,76(s5)
    80003f06:	0127f463          	bgeu	a5,s2,80003f0e <writei+0xe2>
    ip->size = off;
    80003f0a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f0e:	8556                	mv	a0,s5
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	aa4080e7          	jalr	-1372(ra) # 800039b4 <iupdate>

  return tot;
    80003f18:	0009851b          	sext.w	a0,s3
}
    80003f1c:	70a6                	ld	ra,104(sp)
    80003f1e:	7406                	ld	s0,96(sp)
    80003f20:	64e6                	ld	s1,88(sp)
    80003f22:	6946                	ld	s2,80(sp)
    80003f24:	69a6                	ld	s3,72(sp)
    80003f26:	6a06                	ld	s4,64(sp)
    80003f28:	7ae2                	ld	s5,56(sp)
    80003f2a:	7b42                	ld	s6,48(sp)
    80003f2c:	7ba2                	ld	s7,40(sp)
    80003f2e:	7c02                	ld	s8,32(sp)
    80003f30:	6ce2                	ld	s9,24(sp)
    80003f32:	6d42                	ld	s10,16(sp)
    80003f34:	6da2                	ld	s11,8(sp)
    80003f36:	6165                	addi	sp,sp,112
    80003f38:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f3a:	89da                	mv	s3,s6
    80003f3c:	bfc9                	j	80003f0e <writei+0xe2>
    return -1;
    80003f3e:	557d                	li	a0,-1
}
    80003f40:	8082                	ret
    return -1;
    80003f42:	557d                	li	a0,-1
    80003f44:	bfe1                	j	80003f1c <writei+0xf0>
    return -1;
    80003f46:	557d                	li	a0,-1
    80003f48:	bfd1                	j	80003f1c <writei+0xf0>

0000000080003f4a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f4a:	1141                	addi	sp,sp,-16
    80003f4c:	e406                	sd	ra,8(sp)
    80003f4e:	e022                	sd	s0,0(sp)
    80003f50:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f52:	4639                	li	a2,14
    80003f54:	ffffd097          	auipc	ra,0xffffd
    80003f58:	e4a080e7          	jalr	-438(ra) # 80000d9e <strncmp>
}
    80003f5c:	60a2                	ld	ra,8(sp)
    80003f5e:	6402                	ld	s0,0(sp)
    80003f60:	0141                	addi	sp,sp,16
    80003f62:	8082                	ret

0000000080003f64 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f64:	7139                	addi	sp,sp,-64
    80003f66:	fc06                	sd	ra,56(sp)
    80003f68:	f822                	sd	s0,48(sp)
    80003f6a:	f426                	sd	s1,40(sp)
    80003f6c:	f04a                	sd	s2,32(sp)
    80003f6e:	ec4e                	sd	s3,24(sp)
    80003f70:	e852                	sd	s4,16(sp)
    80003f72:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f74:	04451703          	lh	a4,68(a0)
    80003f78:	4785                	li	a5,1
    80003f7a:	00f71a63          	bne	a4,a5,80003f8e <dirlookup+0x2a>
    80003f7e:	892a                	mv	s2,a0
    80003f80:	89ae                	mv	s3,a1
    80003f82:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f84:	457c                	lw	a5,76(a0)
    80003f86:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f88:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f8a:	e79d                	bnez	a5,80003fb8 <dirlookup+0x54>
    80003f8c:	a8a5                	j	80004004 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f8e:	00004517          	auipc	a0,0x4
    80003f92:	68250513          	addi	a0,a0,1666 # 80008610 <syscalls+0x1c0>
    80003f96:	ffffc097          	auipc	ra,0xffffc
    80003f9a:	5a6080e7          	jalr	1446(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003f9e:	00004517          	auipc	a0,0x4
    80003fa2:	68a50513          	addi	a0,a0,1674 # 80008628 <syscalls+0x1d8>
    80003fa6:	ffffc097          	auipc	ra,0xffffc
    80003faa:	596080e7          	jalr	1430(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fae:	24c1                	addiw	s1,s1,16
    80003fb0:	04c92783          	lw	a5,76(s2)
    80003fb4:	04f4f763          	bgeu	s1,a5,80004002 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb8:	4741                	li	a4,16
    80003fba:	86a6                	mv	a3,s1
    80003fbc:	fc040613          	addi	a2,s0,-64
    80003fc0:	4581                	li	a1,0
    80003fc2:	854a                	mv	a0,s2
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	d70080e7          	jalr	-656(ra) # 80003d34 <readi>
    80003fcc:	47c1                	li	a5,16
    80003fce:	fcf518e3          	bne	a0,a5,80003f9e <dirlookup+0x3a>
    if(de.inum == 0)
    80003fd2:	fc045783          	lhu	a5,-64(s0)
    80003fd6:	dfe1                	beqz	a5,80003fae <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003fd8:	fc240593          	addi	a1,s0,-62
    80003fdc:	854e                	mv	a0,s3
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	f6c080e7          	jalr	-148(ra) # 80003f4a <namecmp>
    80003fe6:	f561                	bnez	a0,80003fae <dirlookup+0x4a>
      if(poff)
    80003fe8:	000a0463          	beqz	s4,80003ff0 <dirlookup+0x8c>
        *poff = off;
    80003fec:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ff0:	fc045583          	lhu	a1,-64(s0)
    80003ff4:	00092503          	lw	a0,0(s2)
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	754080e7          	jalr	1876(ra) # 8000374c <iget>
    80004000:	a011                	j	80004004 <dirlookup+0xa0>
  return 0;
    80004002:	4501                	li	a0,0
}
    80004004:	70e2                	ld	ra,56(sp)
    80004006:	7442                	ld	s0,48(sp)
    80004008:	74a2                	ld	s1,40(sp)
    8000400a:	7902                	ld	s2,32(sp)
    8000400c:	69e2                	ld	s3,24(sp)
    8000400e:	6a42                	ld	s4,16(sp)
    80004010:	6121                	addi	sp,sp,64
    80004012:	8082                	ret

0000000080004014 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004014:	711d                	addi	sp,sp,-96
    80004016:	ec86                	sd	ra,88(sp)
    80004018:	e8a2                	sd	s0,80(sp)
    8000401a:	e4a6                	sd	s1,72(sp)
    8000401c:	e0ca                	sd	s2,64(sp)
    8000401e:	fc4e                	sd	s3,56(sp)
    80004020:	f852                	sd	s4,48(sp)
    80004022:	f456                	sd	s5,40(sp)
    80004024:	f05a                	sd	s6,32(sp)
    80004026:	ec5e                	sd	s7,24(sp)
    80004028:	e862                	sd	s8,16(sp)
    8000402a:	e466                	sd	s9,8(sp)
    8000402c:	1080                	addi	s0,sp,96
    8000402e:	84aa                	mv	s1,a0
    80004030:	8b2e                	mv	s6,a1
    80004032:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004034:	00054703          	lbu	a4,0(a0)
    80004038:	02f00793          	li	a5,47
    8000403c:	02f70263          	beq	a4,a5,80004060 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004040:	ffffe097          	auipc	ra,0xffffe
    80004044:	966080e7          	jalr	-1690(ra) # 800019a6 <myproc>
    80004048:	15053503          	ld	a0,336(a0)
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	9f6080e7          	jalr	-1546(ra) # 80003a42 <idup>
    80004054:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004056:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000405a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000405c:	4b85                	li	s7,1
    8000405e:	a875                	j	8000411a <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004060:	4585                	li	a1,1
    80004062:	4505                	li	a0,1
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	6e8080e7          	jalr	1768(ra) # 8000374c <iget>
    8000406c:	8a2a                	mv	s4,a0
    8000406e:	b7e5                	j	80004056 <namex+0x42>
      iunlockput(ip);
    80004070:	8552                	mv	a0,s4
    80004072:	00000097          	auipc	ra,0x0
    80004076:	c70080e7          	jalr	-912(ra) # 80003ce2 <iunlockput>
      return 0;
    8000407a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000407c:	8552                	mv	a0,s4
    8000407e:	60e6                	ld	ra,88(sp)
    80004080:	6446                	ld	s0,80(sp)
    80004082:	64a6                	ld	s1,72(sp)
    80004084:	6906                	ld	s2,64(sp)
    80004086:	79e2                	ld	s3,56(sp)
    80004088:	7a42                	ld	s4,48(sp)
    8000408a:	7aa2                	ld	s5,40(sp)
    8000408c:	7b02                	ld	s6,32(sp)
    8000408e:	6be2                	ld	s7,24(sp)
    80004090:	6c42                	ld	s8,16(sp)
    80004092:	6ca2                	ld	s9,8(sp)
    80004094:	6125                	addi	sp,sp,96
    80004096:	8082                	ret
      iunlock(ip);
    80004098:	8552                	mv	a0,s4
    8000409a:	00000097          	auipc	ra,0x0
    8000409e:	aa8080e7          	jalr	-1368(ra) # 80003b42 <iunlock>
      return ip;
    800040a2:	bfe9                	j	8000407c <namex+0x68>
      iunlockput(ip);
    800040a4:	8552                	mv	a0,s4
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	c3c080e7          	jalr	-964(ra) # 80003ce2 <iunlockput>
      return 0;
    800040ae:	8a4e                	mv	s4,s3
    800040b0:	b7f1                	j	8000407c <namex+0x68>
  len = path - s;
    800040b2:	40998633          	sub	a2,s3,s1
    800040b6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800040ba:	099c5863          	bge	s8,s9,8000414a <namex+0x136>
    memmove(name, s, DIRSIZ);
    800040be:	4639                	li	a2,14
    800040c0:	85a6                	mv	a1,s1
    800040c2:	8556                	mv	a0,s5
    800040c4:	ffffd097          	auipc	ra,0xffffd
    800040c8:	c66080e7          	jalr	-922(ra) # 80000d2a <memmove>
    800040cc:	84ce                	mv	s1,s3
  while(*path == '/')
    800040ce:	0004c783          	lbu	a5,0(s1)
    800040d2:	01279763          	bne	a5,s2,800040e0 <namex+0xcc>
    path++;
    800040d6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040d8:	0004c783          	lbu	a5,0(s1)
    800040dc:	ff278de3          	beq	a5,s2,800040d6 <namex+0xc2>
    ilock(ip);
    800040e0:	8552                	mv	a0,s4
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	99e080e7          	jalr	-1634(ra) # 80003a80 <ilock>
    if(ip->type != T_DIR){
    800040ea:	044a1783          	lh	a5,68(s4)
    800040ee:	f97791e3          	bne	a5,s7,80004070 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800040f2:	000b0563          	beqz	s6,800040fc <namex+0xe8>
    800040f6:	0004c783          	lbu	a5,0(s1)
    800040fa:	dfd9                	beqz	a5,80004098 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040fc:	4601                	li	a2,0
    800040fe:	85d6                	mv	a1,s5
    80004100:	8552                	mv	a0,s4
    80004102:	00000097          	auipc	ra,0x0
    80004106:	e62080e7          	jalr	-414(ra) # 80003f64 <dirlookup>
    8000410a:	89aa                	mv	s3,a0
    8000410c:	dd41                	beqz	a0,800040a4 <namex+0x90>
    iunlockput(ip);
    8000410e:	8552                	mv	a0,s4
    80004110:	00000097          	auipc	ra,0x0
    80004114:	bd2080e7          	jalr	-1070(ra) # 80003ce2 <iunlockput>
    ip = next;
    80004118:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000411a:	0004c783          	lbu	a5,0(s1)
    8000411e:	01279763          	bne	a5,s2,8000412c <namex+0x118>
    path++;
    80004122:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004124:	0004c783          	lbu	a5,0(s1)
    80004128:	ff278de3          	beq	a5,s2,80004122 <namex+0x10e>
  if(*path == 0)
    8000412c:	cb9d                	beqz	a5,80004162 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000412e:	0004c783          	lbu	a5,0(s1)
    80004132:	89a6                	mv	s3,s1
  len = path - s;
    80004134:	4c81                	li	s9,0
    80004136:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004138:	01278963          	beq	a5,s2,8000414a <namex+0x136>
    8000413c:	dbbd                	beqz	a5,800040b2 <namex+0x9e>
    path++;
    8000413e:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004140:	0009c783          	lbu	a5,0(s3)
    80004144:	ff279ce3          	bne	a5,s2,8000413c <namex+0x128>
    80004148:	b7ad                	j	800040b2 <namex+0x9e>
    memmove(name, s, len);
    8000414a:	2601                	sext.w	a2,a2
    8000414c:	85a6                	mv	a1,s1
    8000414e:	8556                	mv	a0,s5
    80004150:	ffffd097          	auipc	ra,0xffffd
    80004154:	bda080e7          	jalr	-1062(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004158:	9cd6                	add	s9,s9,s5
    8000415a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000415e:	84ce                	mv	s1,s3
    80004160:	b7bd                	j	800040ce <namex+0xba>
  if(nameiparent){
    80004162:	f00b0de3          	beqz	s6,8000407c <namex+0x68>
    iput(ip);
    80004166:	8552                	mv	a0,s4
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	ad2080e7          	jalr	-1326(ra) # 80003c3a <iput>
    return 0;
    80004170:	4a01                	li	s4,0
    80004172:	b729                	j	8000407c <namex+0x68>

0000000080004174 <dirlink>:
{
    80004174:	7139                	addi	sp,sp,-64
    80004176:	fc06                	sd	ra,56(sp)
    80004178:	f822                	sd	s0,48(sp)
    8000417a:	f426                	sd	s1,40(sp)
    8000417c:	f04a                	sd	s2,32(sp)
    8000417e:	ec4e                	sd	s3,24(sp)
    80004180:	e852                	sd	s4,16(sp)
    80004182:	0080                	addi	s0,sp,64
    80004184:	892a                	mv	s2,a0
    80004186:	8a2e                	mv	s4,a1
    80004188:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000418a:	4601                	li	a2,0
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	dd8080e7          	jalr	-552(ra) # 80003f64 <dirlookup>
    80004194:	e93d                	bnez	a0,8000420a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004196:	04c92483          	lw	s1,76(s2)
    8000419a:	c49d                	beqz	s1,800041c8 <dirlink+0x54>
    8000419c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000419e:	4741                	li	a4,16
    800041a0:	86a6                	mv	a3,s1
    800041a2:	fc040613          	addi	a2,s0,-64
    800041a6:	4581                	li	a1,0
    800041a8:	854a                	mv	a0,s2
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	b8a080e7          	jalr	-1142(ra) # 80003d34 <readi>
    800041b2:	47c1                	li	a5,16
    800041b4:	06f51163          	bne	a0,a5,80004216 <dirlink+0xa2>
    if(de.inum == 0)
    800041b8:	fc045783          	lhu	a5,-64(s0)
    800041bc:	c791                	beqz	a5,800041c8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041be:	24c1                	addiw	s1,s1,16
    800041c0:	04c92783          	lw	a5,76(s2)
    800041c4:	fcf4ede3          	bltu	s1,a5,8000419e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800041c8:	4639                	li	a2,14
    800041ca:	85d2                	mv	a1,s4
    800041cc:	fc240513          	addi	a0,s0,-62
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	c0a080e7          	jalr	-1014(ra) # 80000dda <strncpy>
  de.inum = inum;
    800041d8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041dc:	4741                	li	a4,16
    800041de:	86a6                	mv	a3,s1
    800041e0:	fc040613          	addi	a2,s0,-64
    800041e4:	4581                	li	a1,0
    800041e6:	854a                	mv	a0,s2
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	c44080e7          	jalr	-956(ra) # 80003e2c <writei>
    800041f0:	1541                	addi	a0,a0,-16
    800041f2:	00a03533          	snez	a0,a0
    800041f6:	40a00533          	neg	a0,a0
}
    800041fa:	70e2                	ld	ra,56(sp)
    800041fc:	7442                	ld	s0,48(sp)
    800041fe:	74a2                	ld	s1,40(sp)
    80004200:	7902                	ld	s2,32(sp)
    80004202:	69e2                	ld	s3,24(sp)
    80004204:	6a42                	ld	s4,16(sp)
    80004206:	6121                	addi	sp,sp,64
    80004208:	8082                	ret
    iput(ip);
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	a30080e7          	jalr	-1488(ra) # 80003c3a <iput>
    return -1;
    80004212:	557d                	li	a0,-1
    80004214:	b7dd                	j	800041fa <dirlink+0x86>
      panic("dirlink read");
    80004216:	00004517          	auipc	a0,0x4
    8000421a:	42250513          	addi	a0,a0,1058 # 80008638 <syscalls+0x1e8>
    8000421e:	ffffc097          	auipc	ra,0xffffc
    80004222:	31e080e7          	jalr	798(ra) # 8000053c <panic>

0000000080004226 <namei>:

struct inode*
namei(char *path)
{
    80004226:	1101                	addi	sp,sp,-32
    80004228:	ec06                	sd	ra,24(sp)
    8000422a:	e822                	sd	s0,16(sp)
    8000422c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000422e:	fe040613          	addi	a2,s0,-32
    80004232:	4581                	li	a1,0
    80004234:	00000097          	auipc	ra,0x0
    80004238:	de0080e7          	jalr	-544(ra) # 80004014 <namex>
}
    8000423c:	60e2                	ld	ra,24(sp)
    8000423e:	6442                	ld	s0,16(sp)
    80004240:	6105                	addi	sp,sp,32
    80004242:	8082                	ret

0000000080004244 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004244:	1141                	addi	sp,sp,-16
    80004246:	e406                	sd	ra,8(sp)
    80004248:	e022                	sd	s0,0(sp)
    8000424a:	0800                	addi	s0,sp,16
    8000424c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000424e:	4585                	li	a1,1
    80004250:	00000097          	auipc	ra,0x0
    80004254:	dc4080e7          	jalr	-572(ra) # 80004014 <namex>
}
    80004258:	60a2                	ld	ra,8(sp)
    8000425a:	6402                	ld	s0,0(sp)
    8000425c:	0141                	addi	sp,sp,16
    8000425e:	8082                	ret

0000000080004260 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004260:	1101                	addi	sp,sp,-32
    80004262:	ec06                	sd	ra,24(sp)
    80004264:	e822                	sd	s0,16(sp)
    80004266:	e426                	sd	s1,8(sp)
    80004268:	e04a                	sd	s2,0(sp)
    8000426a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000426c:	0001d917          	auipc	s2,0x1d
    80004270:	2d490913          	addi	s2,s2,724 # 80021540 <log>
    80004274:	01892583          	lw	a1,24(s2)
    80004278:	02892503          	lw	a0,40(s2)
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	ff4080e7          	jalr	-12(ra) # 80003270 <bread>
    80004284:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004286:	02c92603          	lw	a2,44(s2)
    8000428a:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000428c:	00c05f63          	blez	a2,800042aa <write_head+0x4a>
    80004290:	0001d717          	auipc	a4,0x1d
    80004294:	2e070713          	addi	a4,a4,736 # 80021570 <log+0x30>
    80004298:	87aa                	mv	a5,a0
    8000429a:	060a                	slli	a2,a2,0x2
    8000429c:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000429e:	4314                	lw	a3,0(a4)
    800042a0:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800042a2:	0711                	addi	a4,a4,4
    800042a4:	0791                	addi	a5,a5,4
    800042a6:	fec79ce3          	bne	a5,a2,8000429e <write_head+0x3e>
  }
  bwrite(buf);
    800042aa:	8526                	mv	a0,s1
    800042ac:	fffff097          	auipc	ra,0xfffff
    800042b0:	0b6080e7          	jalr	182(ra) # 80003362 <bwrite>
  brelse(buf);
    800042b4:	8526                	mv	a0,s1
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	0ea080e7          	jalr	234(ra) # 800033a0 <brelse>
}
    800042be:	60e2                	ld	ra,24(sp)
    800042c0:	6442                	ld	s0,16(sp)
    800042c2:	64a2                	ld	s1,8(sp)
    800042c4:	6902                	ld	s2,0(sp)
    800042c6:	6105                	addi	sp,sp,32
    800042c8:	8082                	ret

00000000800042ca <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ca:	0001d797          	auipc	a5,0x1d
    800042ce:	2a27a783          	lw	a5,674(a5) # 8002156c <log+0x2c>
    800042d2:	0af05d63          	blez	a5,8000438c <install_trans+0xc2>
{
    800042d6:	7139                	addi	sp,sp,-64
    800042d8:	fc06                	sd	ra,56(sp)
    800042da:	f822                	sd	s0,48(sp)
    800042dc:	f426                	sd	s1,40(sp)
    800042de:	f04a                	sd	s2,32(sp)
    800042e0:	ec4e                	sd	s3,24(sp)
    800042e2:	e852                	sd	s4,16(sp)
    800042e4:	e456                	sd	s5,8(sp)
    800042e6:	e05a                	sd	s6,0(sp)
    800042e8:	0080                	addi	s0,sp,64
    800042ea:	8b2a                	mv	s6,a0
    800042ec:	0001da97          	auipc	s5,0x1d
    800042f0:	284a8a93          	addi	s5,s5,644 # 80021570 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042f6:	0001d997          	auipc	s3,0x1d
    800042fa:	24a98993          	addi	s3,s3,586 # 80021540 <log>
    800042fe:	a00d                	j	80004320 <install_trans+0x56>
    brelse(lbuf);
    80004300:	854a                	mv	a0,s2
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	09e080e7          	jalr	158(ra) # 800033a0 <brelse>
    brelse(dbuf);
    8000430a:	8526                	mv	a0,s1
    8000430c:	fffff097          	auipc	ra,0xfffff
    80004310:	094080e7          	jalr	148(ra) # 800033a0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004314:	2a05                	addiw	s4,s4,1
    80004316:	0a91                	addi	s5,s5,4
    80004318:	02c9a783          	lw	a5,44(s3)
    8000431c:	04fa5e63          	bge	s4,a5,80004378 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004320:	0189a583          	lw	a1,24(s3)
    80004324:	014585bb          	addw	a1,a1,s4
    80004328:	2585                	addiw	a1,a1,1
    8000432a:	0289a503          	lw	a0,40(s3)
    8000432e:	fffff097          	auipc	ra,0xfffff
    80004332:	f42080e7          	jalr	-190(ra) # 80003270 <bread>
    80004336:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004338:	000aa583          	lw	a1,0(s5)
    8000433c:	0289a503          	lw	a0,40(s3)
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	f30080e7          	jalr	-208(ra) # 80003270 <bread>
    80004348:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000434a:	40000613          	li	a2,1024
    8000434e:	05890593          	addi	a1,s2,88
    80004352:	05850513          	addi	a0,a0,88
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	9d4080e7          	jalr	-1580(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000435e:	8526                	mv	a0,s1
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	002080e7          	jalr	2(ra) # 80003362 <bwrite>
    if(recovering == 0)
    80004368:	f80b1ce3          	bnez	s6,80004300 <install_trans+0x36>
      bunpin(dbuf);
    8000436c:	8526                	mv	a0,s1
    8000436e:	fffff097          	auipc	ra,0xfffff
    80004372:	10a080e7          	jalr	266(ra) # 80003478 <bunpin>
    80004376:	b769                	j	80004300 <install_trans+0x36>
}
    80004378:	70e2                	ld	ra,56(sp)
    8000437a:	7442                	ld	s0,48(sp)
    8000437c:	74a2                	ld	s1,40(sp)
    8000437e:	7902                	ld	s2,32(sp)
    80004380:	69e2                	ld	s3,24(sp)
    80004382:	6a42                	ld	s4,16(sp)
    80004384:	6aa2                	ld	s5,8(sp)
    80004386:	6b02                	ld	s6,0(sp)
    80004388:	6121                	addi	sp,sp,64
    8000438a:	8082                	ret
    8000438c:	8082                	ret

000000008000438e <initlog>:
{
    8000438e:	7179                	addi	sp,sp,-48
    80004390:	f406                	sd	ra,40(sp)
    80004392:	f022                	sd	s0,32(sp)
    80004394:	ec26                	sd	s1,24(sp)
    80004396:	e84a                	sd	s2,16(sp)
    80004398:	e44e                	sd	s3,8(sp)
    8000439a:	1800                	addi	s0,sp,48
    8000439c:	892a                	mv	s2,a0
    8000439e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800043a0:	0001d497          	auipc	s1,0x1d
    800043a4:	1a048493          	addi	s1,s1,416 # 80021540 <log>
    800043a8:	00004597          	auipc	a1,0x4
    800043ac:	2a058593          	addi	a1,a1,672 # 80008648 <syscalls+0x1f8>
    800043b0:	8526                	mv	a0,s1
    800043b2:	ffffc097          	auipc	ra,0xffffc
    800043b6:	790080e7          	jalr	1936(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    800043ba:	0149a583          	lw	a1,20(s3)
    800043be:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800043c0:	0109a783          	lw	a5,16(s3)
    800043c4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800043c6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043ca:	854a                	mv	a0,s2
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	ea4080e7          	jalr	-348(ra) # 80003270 <bread>
  log.lh.n = lh->n;
    800043d4:	4d30                	lw	a2,88(a0)
    800043d6:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043d8:	00c05f63          	blez	a2,800043f6 <initlog+0x68>
    800043dc:	87aa                	mv	a5,a0
    800043de:	0001d717          	auipc	a4,0x1d
    800043e2:	19270713          	addi	a4,a4,402 # 80021570 <log+0x30>
    800043e6:	060a                	slli	a2,a2,0x2
    800043e8:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800043ea:	4ff4                	lw	a3,92(a5)
    800043ec:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043ee:	0791                	addi	a5,a5,4
    800043f0:	0711                	addi	a4,a4,4
    800043f2:	fec79ce3          	bne	a5,a2,800043ea <initlog+0x5c>
  brelse(buf);
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	faa080e7          	jalr	-86(ra) # 800033a0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043fe:	4505                	li	a0,1
    80004400:	00000097          	auipc	ra,0x0
    80004404:	eca080e7          	jalr	-310(ra) # 800042ca <install_trans>
  log.lh.n = 0;
    80004408:	0001d797          	auipc	a5,0x1d
    8000440c:	1607a223          	sw	zero,356(a5) # 8002156c <log+0x2c>
  write_head(); // clear the log
    80004410:	00000097          	auipc	ra,0x0
    80004414:	e50080e7          	jalr	-432(ra) # 80004260 <write_head>
}
    80004418:	70a2                	ld	ra,40(sp)
    8000441a:	7402                	ld	s0,32(sp)
    8000441c:	64e2                	ld	s1,24(sp)
    8000441e:	6942                	ld	s2,16(sp)
    80004420:	69a2                	ld	s3,8(sp)
    80004422:	6145                	addi	sp,sp,48
    80004424:	8082                	ret

0000000080004426 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004426:	1101                	addi	sp,sp,-32
    80004428:	ec06                	sd	ra,24(sp)
    8000442a:	e822                	sd	s0,16(sp)
    8000442c:	e426                	sd	s1,8(sp)
    8000442e:	e04a                	sd	s2,0(sp)
    80004430:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004432:	0001d517          	auipc	a0,0x1d
    80004436:	10e50513          	addi	a0,a0,270 # 80021540 <log>
    8000443a:	ffffc097          	auipc	ra,0xffffc
    8000443e:	798080e7          	jalr	1944(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004442:	0001d497          	auipc	s1,0x1d
    80004446:	0fe48493          	addi	s1,s1,254 # 80021540 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000444a:	4979                	li	s2,30
    8000444c:	a039                	j	8000445a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000444e:	85a6                	mv	a1,s1
    80004450:	8526                	mv	a0,s1
    80004452:	ffffe097          	auipc	ra,0xffffe
    80004456:	cec080e7          	jalr	-788(ra) # 8000213e <sleep>
    if(log.committing){
    8000445a:	50dc                	lw	a5,36(s1)
    8000445c:	fbed                	bnez	a5,8000444e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000445e:	5098                	lw	a4,32(s1)
    80004460:	2705                	addiw	a4,a4,1
    80004462:	0027179b          	slliw	a5,a4,0x2
    80004466:	9fb9                	addw	a5,a5,a4
    80004468:	0017979b          	slliw	a5,a5,0x1
    8000446c:	54d4                	lw	a3,44(s1)
    8000446e:	9fb5                	addw	a5,a5,a3
    80004470:	00f95963          	bge	s2,a5,80004482 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004474:	85a6                	mv	a1,s1
    80004476:	8526                	mv	a0,s1
    80004478:	ffffe097          	auipc	ra,0xffffe
    8000447c:	cc6080e7          	jalr	-826(ra) # 8000213e <sleep>
    80004480:	bfe9                	j	8000445a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004482:	0001d517          	auipc	a0,0x1d
    80004486:	0be50513          	addi	a0,a0,190 # 80021540 <log>
    8000448a:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	7fa080e7          	jalr	2042(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004494:	60e2                	ld	ra,24(sp)
    80004496:	6442                	ld	s0,16(sp)
    80004498:	64a2                	ld	s1,8(sp)
    8000449a:	6902                	ld	s2,0(sp)
    8000449c:	6105                	addi	sp,sp,32
    8000449e:	8082                	ret

00000000800044a0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800044a0:	7139                	addi	sp,sp,-64
    800044a2:	fc06                	sd	ra,56(sp)
    800044a4:	f822                	sd	s0,48(sp)
    800044a6:	f426                	sd	s1,40(sp)
    800044a8:	f04a                	sd	s2,32(sp)
    800044aa:	ec4e                	sd	s3,24(sp)
    800044ac:	e852                	sd	s4,16(sp)
    800044ae:	e456                	sd	s5,8(sp)
    800044b0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044b2:	0001d497          	auipc	s1,0x1d
    800044b6:	08e48493          	addi	s1,s1,142 # 80021540 <log>
    800044ba:	8526                	mv	a0,s1
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	716080e7          	jalr	1814(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    800044c4:	509c                	lw	a5,32(s1)
    800044c6:	37fd                	addiw	a5,a5,-1
    800044c8:	0007891b          	sext.w	s2,a5
    800044cc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044ce:	50dc                	lw	a5,36(s1)
    800044d0:	e7b9                	bnez	a5,8000451e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044d2:	04091e63          	bnez	s2,8000452e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044d6:	0001d497          	auipc	s1,0x1d
    800044da:	06a48493          	addi	s1,s1,106 # 80021540 <log>
    800044de:	4785                	li	a5,1
    800044e0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044e2:	8526                	mv	a0,s1
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	7a2080e7          	jalr	1954(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044ec:	54dc                	lw	a5,44(s1)
    800044ee:	06f04763          	bgtz	a5,8000455c <end_op+0xbc>
    acquire(&log.lock);
    800044f2:	0001d497          	auipc	s1,0x1d
    800044f6:	04e48493          	addi	s1,s1,78 # 80021540 <log>
    800044fa:	8526                	mv	a0,s1
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	6d6080e7          	jalr	1750(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004504:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004508:	8526                	mv	a0,s1
    8000450a:	ffffe097          	auipc	ra,0xffffe
    8000450e:	c98080e7          	jalr	-872(ra) # 800021a2 <wakeup>
    release(&log.lock);
    80004512:	8526                	mv	a0,s1
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	772080e7          	jalr	1906(ra) # 80000c86 <release>
}
    8000451c:	a03d                	j	8000454a <end_op+0xaa>
    panic("log.committing");
    8000451e:	00004517          	auipc	a0,0x4
    80004522:	13250513          	addi	a0,a0,306 # 80008650 <syscalls+0x200>
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	016080e7          	jalr	22(ra) # 8000053c <panic>
    wakeup(&log);
    8000452e:	0001d497          	auipc	s1,0x1d
    80004532:	01248493          	addi	s1,s1,18 # 80021540 <log>
    80004536:	8526                	mv	a0,s1
    80004538:	ffffe097          	auipc	ra,0xffffe
    8000453c:	c6a080e7          	jalr	-918(ra) # 800021a2 <wakeup>
  release(&log.lock);
    80004540:	8526                	mv	a0,s1
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	744080e7          	jalr	1860(ra) # 80000c86 <release>
}
    8000454a:	70e2                	ld	ra,56(sp)
    8000454c:	7442                	ld	s0,48(sp)
    8000454e:	74a2                	ld	s1,40(sp)
    80004550:	7902                	ld	s2,32(sp)
    80004552:	69e2                	ld	s3,24(sp)
    80004554:	6a42                	ld	s4,16(sp)
    80004556:	6aa2                	ld	s5,8(sp)
    80004558:	6121                	addi	sp,sp,64
    8000455a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000455c:	0001da97          	auipc	s5,0x1d
    80004560:	014a8a93          	addi	s5,s5,20 # 80021570 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004564:	0001da17          	auipc	s4,0x1d
    80004568:	fdca0a13          	addi	s4,s4,-36 # 80021540 <log>
    8000456c:	018a2583          	lw	a1,24(s4)
    80004570:	012585bb          	addw	a1,a1,s2
    80004574:	2585                	addiw	a1,a1,1
    80004576:	028a2503          	lw	a0,40(s4)
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	cf6080e7          	jalr	-778(ra) # 80003270 <bread>
    80004582:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004584:	000aa583          	lw	a1,0(s5)
    80004588:	028a2503          	lw	a0,40(s4)
    8000458c:	fffff097          	auipc	ra,0xfffff
    80004590:	ce4080e7          	jalr	-796(ra) # 80003270 <bread>
    80004594:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004596:	40000613          	li	a2,1024
    8000459a:	05850593          	addi	a1,a0,88
    8000459e:	05848513          	addi	a0,s1,88
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	788080e7          	jalr	1928(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800045aa:	8526                	mv	a0,s1
    800045ac:	fffff097          	auipc	ra,0xfffff
    800045b0:	db6080e7          	jalr	-586(ra) # 80003362 <bwrite>
    brelse(from);
    800045b4:	854e                	mv	a0,s3
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	dea080e7          	jalr	-534(ra) # 800033a0 <brelse>
    brelse(to);
    800045be:	8526                	mv	a0,s1
    800045c0:	fffff097          	auipc	ra,0xfffff
    800045c4:	de0080e7          	jalr	-544(ra) # 800033a0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c8:	2905                	addiw	s2,s2,1
    800045ca:	0a91                	addi	s5,s5,4
    800045cc:	02ca2783          	lw	a5,44(s4)
    800045d0:	f8f94ee3          	blt	s2,a5,8000456c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045d4:	00000097          	auipc	ra,0x0
    800045d8:	c8c080e7          	jalr	-884(ra) # 80004260 <write_head>
    install_trans(0); // Now install writes to home locations
    800045dc:	4501                	li	a0,0
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	cec080e7          	jalr	-788(ra) # 800042ca <install_trans>
    log.lh.n = 0;
    800045e6:	0001d797          	auipc	a5,0x1d
    800045ea:	f807a323          	sw	zero,-122(a5) # 8002156c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045ee:	00000097          	auipc	ra,0x0
    800045f2:	c72080e7          	jalr	-910(ra) # 80004260 <write_head>
    800045f6:	bdf5                	j	800044f2 <end_op+0x52>

00000000800045f8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045f8:	1101                	addi	sp,sp,-32
    800045fa:	ec06                	sd	ra,24(sp)
    800045fc:	e822                	sd	s0,16(sp)
    800045fe:	e426                	sd	s1,8(sp)
    80004600:	e04a                	sd	s2,0(sp)
    80004602:	1000                	addi	s0,sp,32
    80004604:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004606:	0001d917          	auipc	s2,0x1d
    8000460a:	f3a90913          	addi	s2,s2,-198 # 80021540 <log>
    8000460e:	854a                	mv	a0,s2
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	5c2080e7          	jalr	1474(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004618:	02c92603          	lw	a2,44(s2)
    8000461c:	47f5                	li	a5,29
    8000461e:	06c7c563          	blt	a5,a2,80004688 <log_write+0x90>
    80004622:	0001d797          	auipc	a5,0x1d
    80004626:	f3a7a783          	lw	a5,-198(a5) # 8002155c <log+0x1c>
    8000462a:	37fd                	addiw	a5,a5,-1
    8000462c:	04f65e63          	bge	a2,a5,80004688 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004630:	0001d797          	auipc	a5,0x1d
    80004634:	f307a783          	lw	a5,-208(a5) # 80021560 <log+0x20>
    80004638:	06f05063          	blez	a5,80004698 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000463c:	4781                	li	a5,0
    8000463e:	06c05563          	blez	a2,800046a8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004642:	44cc                	lw	a1,12(s1)
    80004644:	0001d717          	auipc	a4,0x1d
    80004648:	f2c70713          	addi	a4,a4,-212 # 80021570 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000464c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000464e:	4314                	lw	a3,0(a4)
    80004650:	04b68c63          	beq	a3,a1,800046a8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004654:	2785                	addiw	a5,a5,1
    80004656:	0711                	addi	a4,a4,4
    80004658:	fef61be3          	bne	a2,a5,8000464e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000465c:	0621                	addi	a2,a2,8
    8000465e:	060a                	slli	a2,a2,0x2
    80004660:	0001d797          	auipc	a5,0x1d
    80004664:	ee078793          	addi	a5,a5,-288 # 80021540 <log>
    80004668:	97b2                	add	a5,a5,a2
    8000466a:	44d8                	lw	a4,12(s1)
    8000466c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000466e:	8526                	mv	a0,s1
    80004670:	fffff097          	auipc	ra,0xfffff
    80004674:	dcc080e7          	jalr	-564(ra) # 8000343c <bpin>
    log.lh.n++;
    80004678:	0001d717          	auipc	a4,0x1d
    8000467c:	ec870713          	addi	a4,a4,-312 # 80021540 <log>
    80004680:	575c                	lw	a5,44(a4)
    80004682:	2785                	addiw	a5,a5,1
    80004684:	d75c                	sw	a5,44(a4)
    80004686:	a82d                	j	800046c0 <log_write+0xc8>
    panic("too big a transaction");
    80004688:	00004517          	auipc	a0,0x4
    8000468c:	fd850513          	addi	a0,a0,-40 # 80008660 <syscalls+0x210>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	eac080e7          	jalr	-340(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004698:	00004517          	auipc	a0,0x4
    8000469c:	fe050513          	addi	a0,a0,-32 # 80008678 <syscalls+0x228>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	e9c080e7          	jalr	-356(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800046a8:	00878693          	addi	a3,a5,8
    800046ac:	068a                	slli	a3,a3,0x2
    800046ae:	0001d717          	auipc	a4,0x1d
    800046b2:	e9270713          	addi	a4,a4,-366 # 80021540 <log>
    800046b6:	9736                	add	a4,a4,a3
    800046b8:	44d4                	lw	a3,12(s1)
    800046ba:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046bc:	faf609e3          	beq	a2,a5,8000466e <log_write+0x76>
  }
  release(&log.lock);
    800046c0:	0001d517          	auipc	a0,0x1d
    800046c4:	e8050513          	addi	a0,a0,-384 # 80021540 <log>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	5be080e7          	jalr	1470(ra) # 80000c86 <release>
}
    800046d0:	60e2                	ld	ra,24(sp)
    800046d2:	6442                	ld	s0,16(sp)
    800046d4:	64a2                	ld	s1,8(sp)
    800046d6:	6902                	ld	s2,0(sp)
    800046d8:	6105                	addi	sp,sp,32
    800046da:	8082                	ret

00000000800046dc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046dc:	1101                	addi	sp,sp,-32
    800046de:	ec06                	sd	ra,24(sp)
    800046e0:	e822                	sd	s0,16(sp)
    800046e2:	e426                	sd	s1,8(sp)
    800046e4:	e04a                	sd	s2,0(sp)
    800046e6:	1000                	addi	s0,sp,32
    800046e8:	84aa                	mv	s1,a0
    800046ea:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046ec:	00004597          	auipc	a1,0x4
    800046f0:	fac58593          	addi	a1,a1,-84 # 80008698 <syscalls+0x248>
    800046f4:	0521                	addi	a0,a0,8
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	44c080e7          	jalr	1100(ra) # 80000b42 <initlock>
  lk->name = name;
    800046fe:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004702:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004706:	0204a423          	sw	zero,40(s1)
}
    8000470a:	60e2                	ld	ra,24(sp)
    8000470c:	6442                	ld	s0,16(sp)
    8000470e:	64a2                	ld	s1,8(sp)
    80004710:	6902                	ld	s2,0(sp)
    80004712:	6105                	addi	sp,sp,32
    80004714:	8082                	ret

0000000080004716 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004716:	1101                	addi	sp,sp,-32
    80004718:	ec06                	sd	ra,24(sp)
    8000471a:	e822                	sd	s0,16(sp)
    8000471c:	e426                	sd	s1,8(sp)
    8000471e:	e04a                	sd	s2,0(sp)
    80004720:	1000                	addi	s0,sp,32
    80004722:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004724:	00850913          	addi	s2,a0,8
    80004728:	854a                	mv	a0,s2
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	4a8080e7          	jalr	1192(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004732:	409c                	lw	a5,0(s1)
    80004734:	cb89                	beqz	a5,80004746 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004736:	85ca                	mv	a1,s2
    80004738:	8526                	mv	a0,s1
    8000473a:	ffffe097          	auipc	ra,0xffffe
    8000473e:	a04080e7          	jalr	-1532(ra) # 8000213e <sleep>
  while (lk->locked) {
    80004742:	409c                	lw	a5,0(s1)
    80004744:	fbed                	bnez	a5,80004736 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004746:	4785                	li	a5,1
    80004748:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000474a:	ffffd097          	auipc	ra,0xffffd
    8000474e:	25c080e7          	jalr	604(ra) # 800019a6 <myproc>
    80004752:	591c                	lw	a5,48(a0)
    80004754:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004756:	854a                	mv	a0,s2
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	52e080e7          	jalr	1326(ra) # 80000c86 <release>
}
    80004760:	60e2                	ld	ra,24(sp)
    80004762:	6442                	ld	s0,16(sp)
    80004764:	64a2                	ld	s1,8(sp)
    80004766:	6902                	ld	s2,0(sp)
    80004768:	6105                	addi	sp,sp,32
    8000476a:	8082                	ret

000000008000476c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000476c:	1101                	addi	sp,sp,-32
    8000476e:	ec06                	sd	ra,24(sp)
    80004770:	e822                	sd	s0,16(sp)
    80004772:	e426                	sd	s1,8(sp)
    80004774:	e04a                	sd	s2,0(sp)
    80004776:	1000                	addi	s0,sp,32
    80004778:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000477a:	00850913          	addi	s2,a0,8
    8000477e:	854a                	mv	a0,s2
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	452080e7          	jalr	1106(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004788:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000478c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004790:	8526                	mv	a0,s1
    80004792:	ffffe097          	auipc	ra,0xffffe
    80004796:	a10080e7          	jalr	-1520(ra) # 800021a2 <wakeup>
  release(&lk->lk);
    8000479a:	854a                	mv	a0,s2
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	4ea080e7          	jalr	1258(ra) # 80000c86 <release>
}
    800047a4:	60e2                	ld	ra,24(sp)
    800047a6:	6442                	ld	s0,16(sp)
    800047a8:	64a2                	ld	s1,8(sp)
    800047aa:	6902                	ld	s2,0(sp)
    800047ac:	6105                	addi	sp,sp,32
    800047ae:	8082                	ret

00000000800047b0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047b0:	7179                	addi	sp,sp,-48
    800047b2:	f406                	sd	ra,40(sp)
    800047b4:	f022                	sd	s0,32(sp)
    800047b6:	ec26                	sd	s1,24(sp)
    800047b8:	e84a                	sd	s2,16(sp)
    800047ba:	e44e                	sd	s3,8(sp)
    800047bc:	1800                	addi	s0,sp,48
    800047be:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047c0:	00850913          	addi	s2,a0,8
    800047c4:	854a                	mv	a0,s2
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	40c080e7          	jalr	1036(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047ce:	409c                	lw	a5,0(s1)
    800047d0:	ef99                	bnez	a5,800047ee <holdingsleep+0x3e>
    800047d2:	4481                	li	s1,0
  release(&lk->lk);
    800047d4:	854a                	mv	a0,s2
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	4b0080e7          	jalr	1200(ra) # 80000c86 <release>
  return r;
}
    800047de:	8526                	mv	a0,s1
    800047e0:	70a2                	ld	ra,40(sp)
    800047e2:	7402                	ld	s0,32(sp)
    800047e4:	64e2                	ld	s1,24(sp)
    800047e6:	6942                	ld	s2,16(sp)
    800047e8:	69a2                	ld	s3,8(sp)
    800047ea:	6145                	addi	sp,sp,48
    800047ec:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047ee:	0284a983          	lw	s3,40(s1)
    800047f2:	ffffd097          	auipc	ra,0xffffd
    800047f6:	1b4080e7          	jalr	436(ra) # 800019a6 <myproc>
    800047fa:	5904                	lw	s1,48(a0)
    800047fc:	413484b3          	sub	s1,s1,s3
    80004800:	0014b493          	seqz	s1,s1
    80004804:	bfc1                	j	800047d4 <holdingsleep+0x24>

0000000080004806 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004806:	1141                	addi	sp,sp,-16
    80004808:	e406                	sd	ra,8(sp)
    8000480a:	e022                	sd	s0,0(sp)
    8000480c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000480e:	00004597          	auipc	a1,0x4
    80004812:	e9a58593          	addi	a1,a1,-358 # 800086a8 <syscalls+0x258>
    80004816:	0001d517          	auipc	a0,0x1d
    8000481a:	e7250513          	addi	a0,a0,-398 # 80021688 <ftable>
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	324080e7          	jalr	804(ra) # 80000b42 <initlock>
}
    80004826:	60a2                	ld	ra,8(sp)
    80004828:	6402                	ld	s0,0(sp)
    8000482a:	0141                	addi	sp,sp,16
    8000482c:	8082                	ret

000000008000482e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000482e:	1101                	addi	sp,sp,-32
    80004830:	ec06                	sd	ra,24(sp)
    80004832:	e822                	sd	s0,16(sp)
    80004834:	e426                	sd	s1,8(sp)
    80004836:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004838:	0001d517          	auipc	a0,0x1d
    8000483c:	e5050513          	addi	a0,a0,-432 # 80021688 <ftable>
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	392080e7          	jalr	914(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004848:	0001d497          	auipc	s1,0x1d
    8000484c:	e5848493          	addi	s1,s1,-424 # 800216a0 <ftable+0x18>
    80004850:	0001e717          	auipc	a4,0x1e
    80004854:	df070713          	addi	a4,a4,-528 # 80022640 <disk>
    if(f->ref == 0){
    80004858:	40dc                	lw	a5,4(s1)
    8000485a:	cf99                	beqz	a5,80004878 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000485c:	02848493          	addi	s1,s1,40
    80004860:	fee49ce3          	bne	s1,a4,80004858 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004864:	0001d517          	auipc	a0,0x1d
    80004868:	e2450513          	addi	a0,a0,-476 # 80021688 <ftable>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	41a080e7          	jalr	1050(ra) # 80000c86 <release>
  return 0;
    80004874:	4481                	li	s1,0
    80004876:	a819                	j	8000488c <filealloc+0x5e>
      f->ref = 1;
    80004878:	4785                	li	a5,1
    8000487a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000487c:	0001d517          	auipc	a0,0x1d
    80004880:	e0c50513          	addi	a0,a0,-500 # 80021688 <ftable>
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	402080e7          	jalr	1026(ra) # 80000c86 <release>
}
    8000488c:	8526                	mv	a0,s1
    8000488e:	60e2                	ld	ra,24(sp)
    80004890:	6442                	ld	s0,16(sp)
    80004892:	64a2                	ld	s1,8(sp)
    80004894:	6105                	addi	sp,sp,32
    80004896:	8082                	ret

0000000080004898 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004898:	1101                	addi	sp,sp,-32
    8000489a:	ec06                	sd	ra,24(sp)
    8000489c:	e822                	sd	s0,16(sp)
    8000489e:	e426                	sd	s1,8(sp)
    800048a0:	1000                	addi	s0,sp,32
    800048a2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800048a4:	0001d517          	auipc	a0,0x1d
    800048a8:	de450513          	addi	a0,a0,-540 # 80021688 <ftable>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	326080e7          	jalr	806(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800048b4:	40dc                	lw	a5,4(s1)
    800048b6:	02f05263          	blez	a5,800048da <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048ba:	2785                	addiw	a5,a5,1
    800048bc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048be:	0001d517          	auipc	a0,0x1d
    800048c2:	dca50513          	addi	a0,a0,-566 # 80021688 <ftable>
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	3c0080e7          	jalr	960(ra) # 80000c86 <release>
  return f;
}
    800048ce:	8526                	mv	a0,s1
    800048d0:	60e2                	ld	ra,24(sp)
    800048d2:	6442                	ld	s0,16(sp)
    800048d4:	64a2                	ld	s1,8(sp)
    800048d6:	6105                	addi	sp,sp,32
    800048d8:	8082                	ret
    panic("filedup");
    800048da:	00004517          	auipc	a0,0x4
    800048de:	dd650513          	addi	a0,a0,-554 # 800086b0 <syscalls+0x260>
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	c5a080e7          	jalr	-934(ra) # 8000053c <panic>

00000000800048ea <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048ea:	7139                	addi	sp,sp,-64
    800048ec:	fc06                	sd	ra,56(sp)
    800048ee:	f822                	sd	s0,48(sp)
    800048f0:	f426                	sd	s1,40(sp)
    800048f2:	f04a                	sd	s2,32(sp)
    800048f4:	ec4e                	sd	s3,24(sp)
    800048f6:	e852                	sd	s4,16(sp)
    800048f8:	e456                	sd	s5,8(sp)
    800048fa:	0080                	addi	s0,sp,64
    800048fc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048fe:	0001d517          	auipc	a0,0x1d
    80004902:	d8a50513          	addi	a0,a0,-630 # 80021688 <ftable>
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	2cc080e7          	jalr	716(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000490e:	40dc                	lw	a5,4(s1)
    80004910:	06f05163          	blez	a5,80004972 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004914:	37fd                	addiw	a5,a5,-1
    80004916:	0007871b          	sext.w	a4,a5
    8000491a:	c0dc                	sw	a5,4(s1)
    8000491c:	06e04363          	bgtz	a4,80004982 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004920:	0004a903          	lw	s2,0(s1)
    80004924:	0094ca83          	lbu	s5,9(s1)
    80004928:	0104ba03          	ld	s4,16(s1)
    8000492c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004930:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004934:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004938:	0001d517          	auipc	a0,0x1d
    8000493c:	d5050513          	addi	a0,a0,-688 # 80021688 <ftable>
    80004940:	ffffc097          	auipc	ra,0xffffc
    80004944:	346080e7          	jalr	838(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004948:	4785                	li	a5,1
    8000494a:	04f90d63          	beq	s2,a5,800049a4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000494e:	3979                	addiw	s2,s2,-2
    80004950:	4785                	li	a5,1
    80004952:	0527e063          	bltu	a5,s2,80004992 <fileclose+0xa8>
    begin_op();
    80004956:	00000097          	auipc	ra,0x0
    8000495a:	ad0080e7          	jalr	-1328(ra) # 80004426 <begin_op>
    iput(ff.ip);
    8000495e:	854e                	mv	a0,s3
    80004960:	fffff097          	auipc	ra,0xfffff
    80004964:	2da080e7          	jalr	730(ra) # 80003c3a <iput>
    end_op();
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	b38080e7          	jalr	-1224(ra) # 800044a0 <end_op>
    80004970:	a00d                	j	80004992 <fileclose+0xa8>
    panic("fileclose");
    80004972:	00004517          	auipc	a0,0x4
    80004976:	d4650513          	addi	a0,a0,-698 # 800086b8 <syscalls+0x268>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	bc2080e7          	jalr	-1086(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004982:	0001d517          	auipc	a0,0x1d
    80004986:	d0650513          	addi	a0,a0,-762 # 80021688 <ftable>
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	2fc080e7          	jalr	764(ra) # 80000c86 <release>
  }
}
    80004992:	70e2                	ld	ra,56(sp)
    80004994:	7442                	ld	s0,48(sp)
    80004996:	74a2                	ld	s1,40(sp)
    80004998:	7902                	ld	s2,32(sp)
    8000499a:	69e2                	ld	s3,24(sp)
    8000499c:	6a42                	ld	s4,16(sp)
    8000499e:	6aa2                	ld	s5,8(sp)
    800049a0:	6121                	addi	sp,sp,64
    800049a2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800049a4:	85d6                	mv	a1,s5
    800049a6:	8552                	mv	a0,s4
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	348080e7          	jalr	840(ra) # 80004cf0 <pipeclose>
    800049b0:	b7cd                	j	80004992 <fileclose+0xa8>

00000000800049b2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049b2:	715d                	addi	sp,sp,-80
    800049b4:	e486                	sd	ra,72(sp)
    800049b6:	e0a2                	sd	s0,64(sp)
    800049b8:	fc26                	sd	s1,56(sp)
    800049ba:	f84a                	sd	s2,48(sp)
    800049bc:	f44e                	sd	s3,40(sp)
    800049be:	0880                	addi	s0,sp,80
    800049c0:	84aa                	mv	s1,a0
    800049c2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049c4:	ffffd097          	auipc	ra,0xffffd
    800049c8:	fe2080e7          	jalr	-30(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049cc:	409c                	lw	a5,0(s1)
    800049ce:	37f9                	addiw	a5,a5,-2
    800049d0:	4705                	li	a4,1
    800049d2:	04f76763          	bltu	a4,a5,80004a20 <filestat+0x6e>
    800049d6:	892a                	mv	s2,a0
    ilock(f->ip);
    800049d8:	6c88                	ld	a0,24(s1)
    800049da:	fffff097          	auipc	ra,0xfffff
    800049de:	0a6080e7          	jalr	166(ra) # 80003a80 <ilock>
    stati(f->ip, &st);
    800049e2:	fb840593          	addi	a1,s0,-72
    800049e6:	6c88                	ld	a0,24(s1)
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	322080e7          	jalr	802(ra) # 80003d0a <stati>
    iunlock(f->ip);
    800049f0:	6c88                	ld	a0,24(s1)
    800049f2:	fffff097          	auipc	ra,0xfffff
    800049f6:	150080e7          	jalr	336(ra) # 80003b42 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049fa:	46e1                	li	a3,24
    800049fc:	fb840613          	addi	a2,s0,-72
    80004a00:	85ce                	mv	a1,s3
    80004a02:	05093503          	ld	a0,80(s2)
    80004a06:	ffffd097          	auipc	ra,0xffffd
    80004a0a:	c60080e7          	jalr	-928(ra) # 80001666 <copyout>
    80004a0e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a12:	60a6                	ld	ra,72(sp)
    80004a14:	6406                	ld	s0,64(sp)
    80004a16:	74e2                	ld	s1,56(sp)
    80004a18:	7942                	ld	s2,48(sp)
    80004a1a:	79a2                	ld	s3,40(sp)
    80004a1c:	6161                	addi	sp,sp,80
    80004a1e:	8082                	ret
  return -1;
    80004a20:	557d                	li	a0,-1
    80004a22:	bfc5                	j	80004a12 <filestat+0x60>

0000000080004a24 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a24:	7179                	addi	sp,sp,-48
    80004a26:	f406                	sd	ra,40(sp)
    80004a28:	f022                	sd	s0,32(sp)
    80004a2a:	ec26                	sd	s1,24(sp)
    80004a2c:	e84a                	sd	s2,16(sp)
    80004a2e:	e44e                	sd	s3,8(sp)
    80004a30:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a32:	00854783          	lbu	a5,8(a0)
    80004a36:	c3d5                	beqz	a5,80004ada <fileread+0xb6>
    80004a38:	84aa                	mv	s1,a0
    80004a3a:	89ae                	mv	s3,a1
    80004a3c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a3e:	411c                	lw	a5,0(a0)
    80004a40:	4705                	li	a4,1
    80004a42:	04e78963          	beq	a5,a4,80004a94 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a46:	470d                	li	a4,3
    80004a48:	04e78d63          	beq	a5,a4,80004aa2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a4c:	4709                	li	a4,2
    80004a4e:	06e79e63          	bne	a5,a4,80004aca <fileread+0xa6>
    ilock(f->ip);
    80004a52:	6d08                	ld	a0,24(a0)
    80004a54:	fffff097          	auipc	ra,0xfffff
    80004a58:	02c080e7          	jalr	44(ra) # 80003a80 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a5c:	874a                	mv	a4,s2
    80004a5e:	5094                	lw	a3,32(s1)
    80004a60:	864e                	mv	a2,s3
    80004a62:	4585                	li	a1,1
    80004a64:	6c88                	ld	a0,24(s1)
    80004a66:	fffff097          	auipc	ra,0xfffff
    80004a6a:	2ce080e7          	jalr	718(ra) # 80003d34 <readi>
    80004a6e:	892a                	mv	s2,a0
    80004a70:	00a05563          	blez	a0,80004a7a <fileread+0x56>
      f->off += r;
    80004a74:	509c                	lw	a5,32(s1)
    80004a76:	9fa9                	addw	a5,a5,a0
    80004a78:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a7a:	6c88                	ld	a0,24(s1)
    80004a7c:	fffff097          	auipc	ra,0xfffff
    80004a80:	0c6080e7          	jalr	198(ra) # 80003b42 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a84:	854a                	mv	a0,s2
    80004a86:	70a2                	ld	ra,40(sp)
    80004a88:	7402                	ld	s0,32(sp)
    80004a8a:	64e2                	ld	s1,24(sp)
    80004a8c:	6942                	ld	s2,16(sp)
    80004a8e:	69a2                	ld	s3,8(sp)
    80004a90:	6145                	addi	sp,sp,48
    80004a92:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a94:	6908                	ld	a0,16(a0)
    80004a96:	00000097          	auipc	ra,0x0
    80004a9a:	3c2080e7          	jalr	962(ra) # 80004e58 <piperead>
    80004a9e:	892a                	mv	s2,a0
    80004aa0:	b7d5                	j	80004a84 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004aa2:	02451783          	lh	a5,36(a0)
    80004aa6:	03079693          	slli	a3,a5,0x30
    80004aaa:	92c1                	srli	a3,a3,0x30
    80004aac:	4725                	li	a4,9
    80004aae:	02d76863          	bltu	a4,a3,80004ade <fileread+0xba>
    80004ab2:	0792                	slli	a5,a5,0x4
    80004ab4:	0001d717          	auipc	a4,0x1d
    80004ab8:	b3470713          	addi	a4,a4,-1228 # 800215e8 <devsw>
    80004abc:	97ba                	add	a5,a5,a4
    80004abe:	639c                	ld	a5,0(a5)
    80004ac0:	c38d                	beqz	a5,80004ae2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ac2:	4505                	li	a0,1
    80004ac4:	9782                	jalr	a5
    80004ac6:	892a                	mv	s2,a0
    80004ac8:	bf75                	j	80004a84 <fileread+0x60>
    panic("fileread");
    80004aca:	00004517          	auipc	a0,0x4
    80004ace:	bfe50513          	addi	a0,a0,-1026 # 800086c8 <syscalls+0x278>
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	a6a080e7          	jalr	-1430(ra) # 8000053c <panic>
    return -1;
    80004ada:	597d                	li	s2,-1
    80004adc:	b765                	j	80004a84 <fileread+0x60>
      return -1;
    80004ade:	597d                	li	s2,-1
    80004ae0:	b755                	j	80004a84 <fileread+0x60>
    80004ae2:	597d                	li	s2,-1
    80004ae4:	b745                	j	80004a84 <fileread+0x60>

0000000080004ae6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004ae6:	00954783          	lbu	a5,9(a0)
    80004aea:	10078e63          	beqz	a5,80004c06 <filewrite+0x120>
{
    80004aee:	715d                	addi	sp,sp,-80
    80004af0:	e486                	sd	ra,72(sp)
    80004af2:	e0a2                	sd	s0,64(sp)
    80004af4:	fc26                	sd	s1,56(sp)
    80004af6:	f84a                	sd	s2,48(sp)
    80004af8:	f44e                	sd	s3,40(sp)
    80004afa:	f052                	sd	s4,32(sp)
    80004afc:	ec56                	sd	s5,24(sp)
    80004afe:	e85a                	sd	s6,16(sp)
    80004b00:	e45e                	sd	s7,8(sp)
    80004b02:	e062                	sd	s8,0(sp)
    80004b04:	0880                	addi	s0,sp,80
    80004b06:	892a                	mv	s2,a0
    80004b08:	8b2e                	mv	s6,a1
    80004b0a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b0c:	411c                	lw	a5,0(a0)
    80004b0e:	4705                	li	a4,1
    80004b10:	02e78263          	beq	a5,a4,80004b34 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b14:	470d                	li	a4,3
    80004b16:	02e78563          	beq	a5,a4,80004b40 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b1a:	4709                	li	a4,2
    80004b1c:	0ce79d63          	bne	a5,a4,80004bf6 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b20:	0ac05b63          	blez	a2,80004bd6 <filewrite+0xf0>
    int i = 0;
    80004b24:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004b26:	6b85                	lui	s7,0x1
    80004b28:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004b2c:	6c05                	lui	s8,0x1
    80004b2e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004b32:	a851                	j	80004bc6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004b34:	6908                	ld	a0,16(a0)
    80004b36:	00000097          	auipc	ra,0x0
    80004b3a:	22a080e7          	jalr	554(ra) # 80004d60 <pipewrite>
    80004b3e:	a045                	j	80004bde <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b40:	02451783          	lh	a5,36(a0)
    80004b44:	03079693          	slli	a3,a5,0x30
    80004b48:	92c1                	srli	a3,a3,0x30
    80004b4a:	4725                	li	a4,9
    80004b4c:	0ad76f63          	bltu	a4,a3,80004c0a <filewrite+0x124>
    80004b50:	0792                	slli	a5,a5,0x4
    80004b52:	0001d717          	auipc	a4,0x1d
    80004b56:	a9670713          	addi	a4,a4,-1386 # 800215e8 <devsw>
    80004b5a:	97ba                	add	a5,a5,a4
    80004b5c:	679c                	ld	a5,8(a5)
    80004b5e:	cbc5                	beqz	a5,80004c0e <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004b60:	4505                	li	a0,1
    80004b62:	9782                	jalr	a5
    80004b64:	a8ad                	j	80004bde <filewrite+0xf8>
      if(n1 > max)
    80004b66:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004b6a:	00000097          	auipc	ra,0x0
    80004b6e:	8bc080e7          	jalr	-1860(ra) # 80004426 <begin_op>
      ilock(f->ip);
    80004b72:	01893503          	ld	a0,24(s2)
    80004b76:	fffff097          	auipc	ra,0xfffff
    80004b7a:	f0a080e7          	jalr	-246(ra) # 80003a80 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b7e:	8756                	mv	a4,s5
    80004b80:	02092683          	lw	a3,32(s2)
    80004b84:	01698633          	add	a2,s3,s6
    80004b88:	4585                	li	a1,1
    80004b8a:	01893503          	ld	a0,24(s2)
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	29e080e7          	jalr	670(ra) # 80003e2c <writei>
    80004b96:	84aa                	mv	s1,a0
    80004b98:	00a05763          	blez	a0,80004ba6 <filewrite+0xc0>
        f->off += r;
    80004b9c:	02092783          	lw	a5,32(s2)
    80004ba0:	9fa9                	addw	a5,a5,a0
    80004ba2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ba6:	01893503          	ld	a0,24(s2)
    80004baa:	fffff097          	auipc	ra,0xfffff
    80004bae:	f98080e7          	jalr	-104(ra) # 80003b42 <iunlock>
      end_op();
    80004bb2:	00000097          	auipc	ra,0x0
    80004bb6:	8ee080e7          	jalr	-1810(ra) # 800044a0 <end_op>

      if(r != n1){
    80004bba:	009a9f63          	bne	s5,s1,80004bd8 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004bbe:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bc2:	0149db63          	bge	s3,s4,80004bd8 <filewrite+0xf2>
      int n1 = n - i;
    80004bc6:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004bca:	0004879b          	sext.w	a5,s1
    80004bce:	f8fbdce3          	bge	s7,a5,80004b66 <filewrite+0x80>
    80004bd2:	84e2                	mv	s1,s8
    80004bd4:	bf49                	j	80004b66 <filewrite+0x80>
    int i = 0;
    80004bd6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004bd8:	033a1d63          	bne	s4,s3,80004c12 <filewrite+0x12c>
    80004bdc:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bde:	60a6                	ld	ra,72(sp)
    80004be0:	6406                	ld	s0,64(sp)
    80004be2:	74e2                	ld	s1,56(sp)
    80004be4:	7942                	ld	s2,48(sp)
    80004be6:	79a2                	ld	s3,40(sp)
    80004be8:	7a02                	ld	s4,32(sp)
    80004bea:	6ae2                	ld	s5,24(sp)
    80004bec:	6b42                	ld	s6,16(sp)
    80004bee:	6ba2                	ld	s7,8(sp)
    80004bf0:	6c02                	ld	s8,0(sp)
    80004bf2:	6161                	addi	sp,sp,80
    80004bf4:	8082                	ret
    panic("filewrite");
    80004bf6:	00004517          	auipc	a0,0x4
    80004bfa:	ae250513          	addi	a0,a0,-1310 # 800086d8 <syscalls+0x288>
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	93e080e7          	jalr	-1730(ra) # 8000053c <panic>
    return -1;
    80004c06:	557d                	li	a0,-1
}
    80004c08:	8082                	ret
      return -1;
    80004c0a:	557d                	li	a0,-1
    80004c0c:	bfc9                	j	80004bde <filewrite+0xf8>
    80004c0e:	557d                	li	a0,-1
    80004c10:	b7f9                	j	80004bde <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004c12:	557d                	li	a0,-1
    80004c14:	b7e9                	j	80004bde <filewrite+0xf8>

0000000080004c16 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c16:	7179                	addi	sp,sp,-48
    80004c18:	f406                	sd	ra,40(sp)
    80004c1a:	f022                	sd	s0,32(sp)
    80004c1c:	ec26                	sd	s1,24(sp)
    80004c1e:	e84a                	sd	s2,16(sp)
    80004c20:	e44e                	sd	s3,8(sp)
    80004c22:	e052                	sd	s4,0(sp)
    80004c24:	1800                	addi	s0,sp,48
    80004c26:	84aa                	mv	s1,a0
    80004c28:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c2a:	0005b023          	sd	zero,0(a1)
    80004c2e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c32:	00000097          	auipc	ra,0x0
    80004c36:	bfc080e7          	jalr	-1028(ra) # 8000482e <filealloc>
    80004c3a:	e088                	sd	a0,0(s1)
    80004c3c:	c551                	beqz	a0,80004cc8 <pipealloc+0xb2>
    80004c3e:	00000097          	auipc	ra,0x0
    80004c42:	bf0080e7          	jalr	-1040(ra) # 8000482e <filealloc>
    80004c46:	00aa3023          	sd	a0,0(s4)
    80004c4a:	c92d                	beqz	a0,80004cbc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	e96080e7          	jalr	-362(ra) # 80000ae2 <kalloc>
    80004c54:	892a                	mv	s2,a0
    80004c56:	c125                	beqz	a0,80004cb6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c58:	4985                	li	s3,1
    80004c5a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c5e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c62:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c66:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c6a:	00004597          	auipc	a1,0x4
    80004c6e:	a7e58593          	addi	a1,a1,-1410 # 800086e8 <syscalls+0x298>
    80004c72:	ffffc097          	auipc	ra,0xffffc
    80004c76:	ed0080e7          	jalr	-304(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004c7a:	609c                	ld	a5,0(s1)
    80004c7c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c80:	609c                	ld	a5,0(s1)
    80004c82:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c86:	609c                	ld	a5,0(s1)
    80004c88:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c8c:	609c                	ld	a5,0(s1)
    80004c8e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c92:	000a3783          	ld	a5,0(s4)
    80004c96:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c9a:	000a3783          	ld	a5,0(s4)
    80004c9e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ca2:	000a3783          	ld	a5,0(s4)
    80004ca6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004caa:	000a3783          	ld	a5,0(s4)
    80004cae:	0127b823          	sd	s2,16(a5)
  return 0;
    80004cb2:	4501                	li	a0,0
    80004cb4:	a025                	j	80004cdc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004cb6:	6088                	ld	a0,0(s1)
    80004cb8:	e501                	bnez	a0,80004cc0 <pipealloc+0xaa>
    80004cba:	a039                	j	80004cc8 <pipealloc+0xb2>
    80004cbc:	6088                	ld	a0,0(s1)
    80004cbe:	c51d                	beqz	a0,80004cec <pipealloc+0xd6>
    fileclose(*f0);
    80004cc0:	00000097          	auipc	ra,0x0
    80004cc4:	c2a080e7          	jalr	-982(ra) # 800048ea <fileclose>
  if(*f1)
    80004cc8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ccc:	557d                	li	a0,-1
  if(*f1)
    80004cce:	c799                	beqz	a5,80004cdc <pipealloc+0xc6>
    fileclose(*f1);
    80004cd0:	853e                	mv	a0,a5
    80004cd2:	00000097          	auipc	ra,0x0
    80004cd6:	c18080e7          	jalr	-1000(ra) # 800048ea <fileclose>
  return -1;
    80004cda:	557d                	li	a0,-1
}
    80004cdc:	70a2                	ld	ra,40(sp)
    80004cde:	7402                	ld	s0,32(sp)
    80004ce0:	64e2                	ld	s1,24(sp)
    80004ce2:	6942                	ld	s2,16(sp)
    80004ce4:	69a2                	ld	s3,8(sp)
    80004ce6:	6a02                	ld	s4,0(sp)
    80004ce8:	6145                	addi	sp,sp,48
    80004cea:	8082                	ret
  return -1;
    80004cec:	557d                	li	a0,-1
    80004cee:	b7fd                	j	80004cdc <pipealloc+0xc6>

0000000080004cf0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cf0:	1101                	addi	sp,sp,-32
    80004cf2:	ec06                	sd	ra,24(sp)
    80004cf4:	e822                	sd	s0,16(sp)
    80004cf6:	e426                	sd	s1,8(sp)
    80004cf8:	e04a                	sd	s2,0(sp)
    80004cfa:	1000                	addi	s0,sp,32
    80004cfc:	84aa                	mv	s1,a0
    80004cfe:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	ed2080e7          	jalr	-302(ra) # 80000bd2 <acquire>
  if(writable){
    80004d08:	02090d63          	beqz	s2,80004d42 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d0c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d10:	21848513          	addi	a0,s1,536
    80004d14:	ffffd097          	auipc	ra,0xffffd
    80004d18:	48e080e7          	jalr	1166(ra) # 800021a2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d1c:	2204b783          	ld	a5,544(s1)
    80004d20:	eb95                	bnez	a5,80004d54 <pipeclose+0x64>
    release(&pi->lock);
    80004d22:	8526                	mv	a0,s1
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	f62080e7          	jalr	-158(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004d2c:	8526                	mv	a0,s1
    80004d2e:	ffffc097          	auipc	ra,0xffffc
    80004d32:	cb6080e7          	jalr	-842(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004d36:	60e2                	ld	ra,24(sp)
    80004d38:	6442                	ld	s0,16(sp)
    80004d3a:	64a2                	ld	s1,8(sp)
    80004d3c:	6902                	ld	s2,0(sp)
    80004d3e:	6105                	addi	sp,sp,32
    80004d40:	8082                	ret
    pi->readopen = 0;
    80004d42:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d46:	21c48513          	addi	a0,s1,540
    80004d4a:	ffffd097          	auipc	ra,0xffffd
    80004d4e:	458080e7          	jalr	1112(ra) # 800021a2 <wakeup>
    80004d52:	b7e9                	j	80004d1c <pipeclose+0x2c>
    release(&pi->lock);
    80004d54:	8526                	mv	a0,s1
    80004d56:	ffffc097          	auipc	ra,0xffffc
    80004d5a:	f30080e7          	jalr	-208(ra) # 80000c86 <release>
}
    80004d5e:	bfe1                	j	80004d36 <pipeclose+0x46>

0000000080004d60 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d60:	711d                	addi	sp,sp,-96
    80004d62:	ec86                	sd	ra,88(sp)
    80004d64:	e8a2                	sd	s0,80(sp)
    80004d66:	e4a6                	sd	s1,72(sp)
    80004d68:	e0ca                	sd	s2,64(sp)
    80004d6a:	fc4e                	sd	s3,56(sp)
    80004d6c:	f852                	sd	s4,48(sp)
    80004d6e:	f456                	sd	s5,40(sp)
    80004d70:	f05a                	sd	s6,32(sp)
    80004d72:	ec5e                	sd	s7,24(sp)
    80004d74:	e862                	sd	s8,16(sp)
    80004d76:	1080                	addi	s0,sp,96
    80004d78:	84aa                	mv	s1,a0
    80004d7a:	8aae                	mv	s5,a1
    80004d7c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	c28080e7          	jalr	-984(ra) # 800019a6 <myproc>
    80004d86:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d88:	8526                	mv	a0,s1
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	e48080e7          	jalr	-440(ra) # 80000bd2 <acquire>
  while(i < n){
    80004d92:	0b405663          	blez	s4,80004e3e <pipewrite+0xde>
  int i = 0;
    80004d96:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d98:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d9a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d9e:	21c48b93          	addi	s7,s1,540
    80004da2:	a089                	j	80004de4 <pipewrite+0x84>
      release(&pi->lock);
    80004da4:	8526                	mv	a0,s1
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	ee0080e7          	jalr	-288(ra) # 80000c86 <release>
      return -1;
    80004dae:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004db0:	854a                	mv	a0,s2
    80004db2:	60e6                	ld	ra,88(sp)
    80004db4:	6446                	ld	s0,80(sp)
    80004db6:	64a6                	ld	s1,72(sp)
    80004db8:	6906                	ld	s2,64(sp)
    80004dba:	79e2                	ld	s3,56(sp)
    80004dbc:	7a42                	ld	s4,48(sp)
    80004dbe:	7aa2                	ld	s5,40(sp)
    80004dc0:	7b02                	ld	s6,32(sp)
    80004dc2:	6be2                	ld	s7,24(sp)
    80004dc4:	6c42                	ld	s8,16(sp)
    80004dc6:	6125                	addi	sp,sp,96
    80004dc8:	8082                	ret
      wakeup(&pi->nread);
    80004dca:	8562                	mv	a0,s8
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	3d6080e7          	jalr	982(ra) # 800021a2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004dd4:	85a6                	mv	a1,s1
    80004dd6:	855e                	mv	a0,s7
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	366080e7          	jalr	870(ra) # 8000213e <sleep>
  while(i < n){
    80004de0:	07495063          	bge	s2,s4,80004e40 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004de4:	2204a783          	lw	a5,544(s1)
    80004de8:	dfd5                	beqz	a5,80004da4 <pipewrite+0x44>
    80004dea:	854e                	mv	a0,s3
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	606080e7          	jalr	1542(ra) # 800023f2 <killed>
    80004df4:	f945                	bnez	a0,80004da4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004df6:	2184a783          	lw	a5,536(s1)
    80004dfa:	21c4a703          	lw	a4,540(s1)
    80004dfe:	2007879b          	addiw	a5,a5,512
    80004e02:	fcf704e3          	beq	a4,a5,80004dca <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e06:	4685                	li	a3,1
    80004e08:	01590633          	add	a2,s2,s5
    80004e0c:	faf40593          	addi	a1,s0,-81
    80004e10:	0509b503          	ld	a0,80(s3)
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	8de080e7          	jalr	-1826(ra) # 800016f2 <copyin>
    80004e1c:	03650263          	beq	a0,s6,80004e40 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e20:	21c4a783          	lw	a5,540(s1)
    80004e24:	0017871b          	addiw	a4,a5,1
    80004e28:	20e4ae23          	sw	a4,540(s1)
    80004e2c:	1ff7f793          	andi	a5,a5,511
    80004e30:	97a6                	add	a5,a5,s1
    80004e32:	faf44703          	lbu	a4,-81(s0)
    80004e36:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e3a:	2905                	addiw	s2,s2,1
    80004e3c:	b755                	j	80004de0 <pipewrite+0x80>
  int i = 0;
    80004e3e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e40:	21848513          	addi	a0,s1,536
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	35e080e7          	jalr	862(ra) # 800021a2 <wakeup>
  release(&pi->lock);
    80004e4c:	8526                	mv	a0,s1
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	e38080e7          	jalr	-456(ra) # 80000c86 <release>
  return i;
    80004e56:	bfa9                	j	80004db0 <pipewrite+0x50>

0000000080004e58 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e58:	715d                	addi	sp,sp,-80
    80004e5a:	e486                	sd	ra,72(sp)
    80004e5c:	e0a2                	sd	s0,64(sp)
    80004e5e:	fc26                	sd	s1,56(sp)
    80004e60:	f84a                	sd	s2,48(sp)
    80004e62:	f44e                	sd	s3,40(sp)
    80004e64:	f052                	sd	s4,32(sp)
    80004e66:	ec56                	sd	s5,24(sp)
    80004e68:	e85a                	sd	s6,16(sp)
    80004e6a:	0880                	addi	s0,sp,80
    80004e6c:	84aa                	mv	s1,a0
    80004e6e:	892e                	mv	s2,a1
    80004e70:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e72:	ffffd097          	auipc	ra,0xffffd
    80004e76:	b34080e7          	jalr	-1228(ra) # 800019a6 <myproc>
    80004e7a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e7c:	8526                	mv	a0,s1
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	d54080e7          	jalr	-684(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e86:	2184a703          	lw	a4,536(s1)
    80004e8a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e8e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e92:	02f71763          	bne	a4,a5,80004ec0 <piperead+0x68>
    80004e96:	2244a783          	lw	a5,548(s1)
    80004e9a:	c39d                	beqz	a5,80004ec0 <piperead+0x68>
    if(killed(pr)){
    80004e9c:	8552                	mv	a0,s4
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	554080e7          	jalr	1364(ra) # 800023f2 <killed>
    80004ea6:	e949                	bnez	a0,80004f38 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ea8:	85a6                	mv	a1,s1
    80004eaa:	854e                	mv	a0,s3
    80004eac:	ffffd097          	auipc	ra,0xffffd
    80004eb0:	292080e7          	jalr	658(ra) # 8000213e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004eb4:	2184a703          	lw	a4,536(s1)
    80004eb8:	21c4a783          	lw	a5,540(s1)
    80004ebc:	fcf70de3          	beq	a4,a5,80004e96 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ec0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ec2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ec4:	05505463          	blez	s5,80004f0c <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004ec8:	2184a783          	lw	a5,536(s1)
    80004ecc:	21c4a703          	lw	a4,540(s1)
    80004ed0:	02f70e63          	beq	a4,a5,80004f0c <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ed4:	0017871b          	addiw	a4,a5,1
    80004ed8:	20e4ac23          	sw	a4,536(s1)
    80004edc:	1ff7f793          	andi	a5,a5,511
    80004ee0:	97a6                	add	a5,a5,s1
    80004ee2:	0187c783          	lbu	a5,24(a5)
    80004ee6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eea:	4685                	li	a3,1
    80004eec:	fbf40613          	addi	a2,s0,-65
    80004ef0:	85ca                	mv	a1,s2
    80004ef2:	050a3503          	ld	a0,80(s4)
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	770080e7          	jalr	1904(ra) # 80001666 <copyout>
    80004efe:	01650763          	beq	a0,s6,80004f0c <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f02:	2985                	addiw	s3,s3,1
    80004f04:	0905                	addi	s2,s2,1
    80004f06:	fd3a91e3          	bne	s5,s3,80004ec8 <piperead+0x70>
    80004f0a:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f0c:	21c48513          	addi	a0,s1,540
    80004f10:	ffffd097          	auipc	ra,0xffffd
    80004f14:	292080e7          	jalr	658(ra) # 800021a2 <wakeup>
  release(&pi->lock);
    80004f18:	8526                	mv	a0,s1
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	d6c080e7          	jalr	-660(ra) # 80000c86 <release>
  return i;
}
    80004f22:	854e                	mv	a0,s3
    80004f24:	60a6                	ld	ra,72(sp)
    80004f26:	6406                	ld	s0,64(sp)
    80004f28:	74e2                	ld	s1,56(sp)
    80004f2a:	7942                	ld	s2,48(sp)
    80004f2c:	79a2                	ld	s3,40(sp)
    80004f2e:	7a02                	ld	s4,32(sp)
    80004f30:	6ae2                	ld	s5,24(sp)
    80004f32:	6b42                	ld	s6,16(sp)
    80004f34:	6161                	addi	sp,sp,80
    80004f36:	8082                	ret
      release(&pi->lock);
    80004f38:	8526                	mv	a0,s1
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	d4c080e7          	jalr	-692(ra) # 80000c86 <release>
      return -1;
    80004f42:	59fd                	li	s3,-1
    80004f44:	bff9                	j	80004f22 <piperead+0xca>

0000000080004f46 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f46:	1141                	addi	sp,sp,-16
    80004f48:	e422                	sd	s0,8(sp)
    80004f4a:	0800                	addi	s0,sp,16
    80004f4c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f4e:	8905                	andi	a0,a0,1
    80004f50:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004f52:	8b89                	andi	a5,a5,2
    80004f54:	c399                	beqz	a5,80004f5a <flags2perm+0x14>
      perm |= PTE_W;
    80004f56:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f5a:	6422                	ld	s0,8(sp)
    80004f5c:	0141                	addi	sp,sp,16
    80004f5e:	8082                	ret

0000000080004f60 <exec>:

int
exec(char *path, char **argv)
{
    80004f60:	df010113          	addi	sp,sp,-528
    80004f64:	20113423          	sd	ra,520(sp)
    80004f68:	20813023          	sd	s0,512(sp)
    80004f6c:	ffa6                	sd	s1,504(sp)
    80004f6e:	fbca                	sd	s2,496(sp)
    80004f70:	f7ce                	sd	s3,488(sp)
    80004f72:	f3d2                	sd	s4,480(sp)
    80004f74:	efd6                	sd	s5,472(sp)
    80004f76:	ebda                	sd	s6,464(sp)
    80004f78:	e7de                	sd	s7,456(sp)
    80004f7a:	e3e2                	sd	s8,448(sp)
    80004f7c:	ff66                	sd	s9,440(sp)
    80004f7e:	fb6a                	sd	s10,432(sp)
    80004f80:	f76e                	sd	s11,424(sp)
    80004f82:	0c00                	addi	s0,sp,528
    80004f84:	892a                	mv	s2,a0
    80004f86:	dea43c23          	sd	a0,-520(s0)
    80004f8a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f8e:	ffffd097          	auipc	ra,0xffffd
    80004f92:	a18080e7          	jalr	-1512(ra) # 800019a6 <myproc>
    80004f96:	84aa                	mv	s1,a0

  begin_op();
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	48e080e7          	jalr	1166(ra) # 80004426 <begin_op>

  if((ip = namei(path)) == 0){
    80004fa0:	854a                	mv	a0,s2
    80004fa2:	fffff097          	auipc	ra,0xfffff
    80004fa6:	284080e7          	jalr	644(ra) # 80004226 <namei>
    80004faa:	c92d                	beqz	a0,8000501c <exec+0xbc>
    80004fac:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004fae:	fffff097          	auipc	ra,0xfffff
    80004fb2:	ad2080e7          	jalr	-1326(ra) # 80003a80 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fb6:	04000713          	li	a4,64
    80004fba:	4681                	li	a3,0
    80004fbc:	e5040613          	addi	a2,s0,-432
    80004fc0:	4581                	li	a1,0
    80004fc2:	8552                	mv	a0,s4
    80004fc4:	fffff097          	auipc	ra,0xfffff
    80004fc8:	d70080e7          	jalr	-656(ra) # 80003d34 <readi>
    80004fcc:	04000793          	li	a5,64
    80004fd0:	00f51a63          	bne	a0,a5,80004fe4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004fd4:	e5042703          	lw	a4,-432(s0)
    80004fd8:	464c47b7          	lui	a5,0x464c4
    80004fdc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fe0:	04f70463          	beq	a4,a5,80005028 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fe4:	8552                	mv	a0,s4
    80004fe6:	fffff097          	auipc	ra,0xfffff
    80004fea:	cfc080e7          	jalr	-772(ra) # 80003ce2 <iunlockput>
    end_op();
    80004fee:	fffff097          	auipc	ra,0xfffff
    80004ff2:	4b2080e7          	jalr	1202(ra) # 800044a0 <end_op>
  }
  return -1;
    80004ff6:	557d                	li	a0,-1
}
    80004ff8:	20813083          	ld	ra,520(sp)
    80004ffc:	20013403          	ld	s0,512(sp)
    80005000:	74fe                	ld	s1,504(sp)
    80005002:	795e                	ld	s2,496(sp)
    80005004:	79be                	ld	s3,488(sp)
    80005006:	7a1e                	ld	s4,480(sp)
    80005008:	6afe                	ld	s5,472(sp)
    8000500a:	6b5e                	ld	s6,464(sp)
    8000500c:	6bbe                	ld	s7,456(sp)
    8000500e:	6c1e                	ld	s8,448(sp)
    80005010:	7cfa                	ld	s9,440(sp)
    80005012:	7d5a                	ld	s10,432(sp)
    80005014:	7dba                	ld	s11,424(sp)
    80005016:	21010113          	addi	sp,sp,528
    8000501a:	8082                	ret
    end_op();
    8000501c:	fffff097          	auipc	ra,0xfffff
    80005020:	484080e7          	jalr	1156(ra) # 800044a0 <end_op>
    return -1;
    80005024:	557d                	li	a0,-1
    80005026:	bfc9                	j	80004ff8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffd097          	auipc	ra,0xffffd
    8000502e:	aa6080e7          	jalr	-1370(ra) # 80001ad0 <proc_pagetable>
    80005032:	8b2a                	mv	s6,a0
    80005034:	d945                	beqz	a0,80004fe4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005036:	e7042d03          	lw	s10,-400(s0)
    8000503a:	e8845783          	lhu	a5,-376(s0)
    8000503e:	10078463          	beqz	a5,80005146 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005042:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005044:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005046:	6c85                	lui	s9,0x1
    80005048:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000504c:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005050:	6a85                	lui	s5,0x1
    80005052:	a0b5                	j	800050be <exec+0x15e>
      panic("loadseg: address should exist");
    80005054:	00003517          	auipc	a0,0x3
    80005058:	69c50513          	addi	a0,a0,1692 # 800086f0 <syscalls+0x2a0>
    8000505c:	ffffb097          	auipc	ra,0xffffb
    80005060:	4e0080e7          	jalr	1248(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005064:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005066:	8726                	mv	a4,s1
    80005068:	012c06bb          	addw	a3,s8,s2
    8000506c:	4581                	li	a1,0
    8000506e:	8552                	mv	a0,s4
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	cc4080e7          	jalr	-828(ra) # 80003d34 <readi>
    80005078:	2501                	sext.w	a0,a0
    8000507a:	24a49863          	bne	s1,a0,800052ca <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    8000507e:	012a893b          	addw	s2,s5,s2
    80005082:	03397563          	bgeu	s2,s3,800050ac <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005086:	02091593          	slli	a1,s2,0x20
    8000508a:	9181                	srli	a1,a1,0x20
    8000508c:	95de                	add	a1,a1,s7
    8000508e:	855a                	mv	a0,s6
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	fc6080e7          	jalr	-58(ra) # 80001056 <walkaddr>
    80005098:	862a                	mv	a2,a0
    if(pa == 0)
    8000509a:	dd4d                	beqz	a0,80005054 <exec+0xf4>
    if(sz - i < PGSIZE)
    8000509c:	412984bb          	subw	s1,s3,s2
    800050a0:	0004879b          	sext.w	a5,s1
    800050a4:	fcfcf0e3          	bgeu	s9,a5,80005064 <exec+0x104>
    800050a8:	84d6                	mv	s1,s5
    800050aa:	bf6d                	j	80005064 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050ac:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050b0:	2d85                	addiw	s11,s11,1
    800050b2:	038d0d1b          	addiw	s10,s10,56
    800050b6:	e8845783          	lhu	a5,-376(s0)
    800050ba:	08fdd763          	bge	s11,a5,80005148 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050be:	2d01                	sext.w	s10,s10
    800050c0:	03800713          	li	a4,56
    800050c4:	86ea                	mv	a3,s10
    800050c6:	e1840613          	addi	a2,s0,-488
    800050ca:	4581                	li	a1,0
    800050cc:	8552                	mv	a0,s4
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	c66080e7          	jalr	-922(ra) # 80003d34 <readi>
    800050d6:	03800793          	li	a5,56
    800050da:	1ef51663          	bne	a0,a5,800052c6 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800050de:	e1842783          	lw	a5,-488(s0)
    800050e2:	4705                	li	a4,1
    800050e4:	fce796e3          	bne	a5,a4,800050b0 <exec+0x150>
    if(ph.memsz < ph.filesz)
    800050e8:	e4043483          	ld	s1,-448(s0)
    800050ec:	e3843783          	ld	a5,-456(s0)
    800050f0:	1ef4e863          	bltu	s1,a5,800052e0 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050f4:	e2843783          	ld	a5,-472(s0)
    800050f8:	94be                	add	s1,s1,a5
    800050fa:	1ef4e663          	bltu	s1,a5,800052e6 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800050fe:	df043703          	ld	a4,-528(s0)
    80005102:	8ff9                	and	a5,a5,a4
    80005104:	1e079463          	bnez	a5,800052ec <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005108:	e1c42503          	lw	a0,-484(s0)
    8000510c:	00000097          	auipc	ra,0x0
    80005110:	e3a080e7          	jalr	-454(ra) # 80004f46 <flags2perm>
    80005114:	86aa                	mv	a3,a0
    80005116:	8626                	mv	a2,s1
    80005118:	85ca                	mv	a1,s2
    8000511a:	855a                	mv	a0,s6
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	2ee080e7          	jalr	750(ra) # 8000140a <uvmalloc>
    80005124:	e0a43423          	sd	a0,-504(s0)
    80005128:	1c050563          	beqz	a0,800052f2 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000512c:	e2843b83          	ld	s7,-472(s0)
    80005130:	e2042c03          	lw	s8,-480(s0)
    80005134:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005138:	00098463          	beqz	s3,80005140 <exec+0x1e0>
    8000513c:	4901                	li	s2,0
    8000513e:	b7a1                	j	80005086 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005140:	e0843903          	ld	s2,-504(s0)
    80005144:	b7b5                	j	800050b0 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005146:	4901                	li	s2,0
  iunlockput(ip);
    80005148:	8552                	mv	a0,s4
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	b98080e7          	jalr	-1128(ra) # 80003ce2 <iunlockput>
  end_op();
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	34e080e7          	jalr	846(ra) # 800044a0 <end_op>
  p = myproc();
    8000515a:	ffffd097          	auipc	ra,0xffffd
    8000515e:	84c080e7          	jalr	-1972(ra) # 800019a6 <myproc>
    80005162:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005164:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005168:	6985                	lui	s3,0x1
    8000516a:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000516c:	99ca                	add	s3,s3,s2
    8000516e:	77fd                	lui	a5,0xfffff
    80005170:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005174:	4691                	li	a3,4
    80005176:	6609                	lui	a2,0x2
    80005178:	964e                	add	a2,a2,s3
    8000517a:	85ce                	mv	a1,s3
    8000517c:	855a                	mv	a0,s6
    8000517e:	ffffc097          	auipc	ra,0xffffc
    80005182:	28c080e7          	jalr	652(ra) # 8000140a <uvmalloc>
    80005186:	892a                	mv	s2,a0
    80005188:	e0a43423          	sd	a0,-504(s0)
    8000518c:	e509                	bnez	a0,80005196 <exec+0x236>
  if(pagetable)
    8000518e:	e1343423          	sd	s3,-504(s0)
    80005192:	4a01                	li	s4,0
    80005194:	aa1d                	j	800052ca <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005196:	75f9                	lui	a1,0xffffe
    80005198:	95aa                	add	a1,a1,a0
    8000519a:	855a                	mv	a0,s6
    8000519c:	ffffc097          	auipc	ra,0xffffc
    800051a0:	498080e7          	jalr	1176(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    800051a4:	7bfd                	lui	s7,0xfffff
    800051a6:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800051a8:	e0043783          	ld	a5,-512(s0)
    800051ac:	6388                	ld	a0,0(a5)
    800051ae:	c52d                	beqz	a0,80005218 <exec+0x2b8>
    800051b0:	e9040993          	addi	s3,s0,-368
    800051b4:	f9040c13          	addi	s8,s0,-112
    800051b8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	c8e080e7          	jalr	-882(ra) # 80000e48 <strlen>
    800051c2:	0015079b          	addiw	a5,a0,1
    800051c6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051ca:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051ce:	13796563          	bltu	s2,s7,800052f8 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051d2:	e0043d03          	ld	s10,-512(s0)
    800051d6:	000d3a03          	ld	s4,0(s10)
    800051da:	8552                	mv	a0,s4
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	c6c080e7          	jalr	-916(ra) # 80000e48 <strlen>
    800051e4:	0015069b          	addiw	a3,a0,1
    800051e8:	8652                	mv	a2,s4
    800051ea:	85ca                	mv	a1,s2
    800051ec:	855a                	mv	a0,s6
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	478080e7          	jalr	1144(ra) # 80001666 <copyout>
    800051f6:	10054363          	bltz	a0,800052fc <exec+0x39c>
    ustack[argc] = sp;
    800051fa:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051fe:	0485                	addi	s1,s1,1
    80005200:	008d0793          	addi	a5,s10,8
    80005204:	e0f43023          	sd	a5,-512(s0)
    80005208:	008d3503          	ld	a0,8(s10)
    8000520c:	c909                	beqz	a0,8000521e <exec+0x2be>
    if(argc >= MAXARG)
    8000520e:	09a1                	addi	s3,s3,8
    80005210:	fb8995e3          	bne	s3,s8,800051ba <exec+0x25a>
  ip = 0;
    80005214:	4a01                	li	s4,0
    80005216:	a855                	j	800052ca <exec+0x36a>
  sp = sz;
    80005218:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000521c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000521e:	00349793          	slli	a5,s1,0x3
    80005222:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdc810>
    80005226:	97a2                	add	a5,a5,s0
    80005228:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000522c:	00148693          	addi	a3,s1,1
    80005230:	068e                	slli	a3,a3,0x3
    80005232:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005236:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000523a:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000523e:	f57968e3          	bltu	s2,s7,8000518e <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005242:	e9040613          	addi	a2,s0,-368
    80005246:	85ca                	mv	a1,s2
    80005248:	855a                	mv	a0,s6
    8000524a:	ffffc097          	auipc	ra,0xffffc
    8000524e:	41c080e7          	jalr	1052(ra) # 80001666 <copyout>
    80005252:	0a054763          	bltz	a0,80005300 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005256:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000525a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000525e:	df843783          	ld	a5,-520(s0)
    80005262:	0007c703          	lbu	a4,0(a5)
    80005266:	cf11                	beqz	a4,80005282 <exec+0x322>
    80005268:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000526a:	02f00693          	li	a3,47
    8000526e:	a039                	j	8000527c <exec+0x31c>
      last = s+1;
    80005270:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005274:	0785                	addi	a5,a5,1
    80005276:	fff7c703          	lbu	a4,-1(a5)
    8000527a:	c701                	beqz	a4,80005282 <exec+0x322>
    if(*s == '/')
    8000527c:	fed71ce3          	bne	a4,a3,80005274 <exec+0x314>
    80005280:	bfc5                	j	80005270 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005282:	4641                	li	a2,16
    80005284:	df843583          	ld	a1,-520(s0)
    80005288:	158a8513          	addi	a0,s5,344
    8000528c:	ffffc097          	auipc	ra,0xffffc
    80005290:	b8a080e7          	jalr	-1142(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005294:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005298:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000529c:	e0843783          	ld	a5,-504(s0)
    800052a0:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052a4:	058ab783          	ld	a5,88(s5)
    800052a8:	e6843703          	ld	a4,-408(s0)
    800052ac:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052ae:	058ab783          	ld	a5,88(s5)
    800052b2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052b6:	85e6                	mv	a1,s9
    800052b8:	ffffd097          	auipc	ra,0xffffd
    800052bc:	8b4080e7          	jalr	-1868(ra) # 80001b6c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052c0:	0004851b          	sext.w	a0,s1
    800052c4:	bb15                	j	80004ff8 <exec+0x98>
    800052c6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800052ca:	e0843583          	ld	a1,-504(s0)
    800052ce:	855a                	mv	a0,s6
    800052d0:	ffffd097          	auipc	ra,0xffffd
    800052d4:	89c080e7          	jalr	-1892(ra) # 80001b6c <proc_freepagetable>
  return -1;
    800052d8:	557d                	li	a0,-1
  if(ip){
    800052da:	d00a0fe3          	beqz	s4,80004ff8 <exec+0x98>
    800052de:	b319                	j	80004fe4 <exec+0x84>
    800052e0:	e1243423          	sd	s2,-504(s0)
    800052e4:	b7dd                	j	800052ca <exec+0x36a>
    800052e6:	e1243423          	sd	s2,-504(s0)
    800052ea:	b7c5                	j	800052ca <exec+0x36a>
    800052ec:	e1243423          	sd	s2,-504(s0)
    800052f0:	bfe9                	j	800052ca <exec+0x36a>
    800052f2:	e1243423          	sd	s2,-504(s0)
    800052f6:	bfd1                	j	800052ca <exec+0x36a>
  ip = 0;
    800052f8:	4a01                	li	s4,0
    800052fa:	bfc1                	j	800052ca <exec+0x36a>
    800052fc:	4a01                	li	s4,0
  if(pagetable)
    800052fe:	b7f1                	j	800052ca <exec+0x36a>
  sz = sz1;
    80005300:	e0843983          	ld	s3,-504(s0)
    80005304:	b569                	j	8000518e <exec+0x22e>

0000000080005306 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005306:	7179                	addi	sp,sp,-48
    80005308:	f406                	sd	ra,40(sp)
    8000530a:	f022                	sd	s0,32(sp)
    8000530c:	ec26                	sd	s1,24(sp)
    8000530e:	e84a                	sd	s2,16(sp)
    80005310:	1800                	addi	s0,sp,48
    80005312:	892e                	mv	s2,a1
    80005314:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005316:	fdc40593          	addi	a1,s0,-36
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	acc080e7          	jalr	-1332(ra) # 80002de6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005322:	fdc42703          	lw	a4,-36(s0)
    80005326:	47bd                	li	a5,15
    80005328:	02e7eb63          	bltu	a5,a4,8000535e <argfd+0x58>
    8000532c:	ffffc097          	auipc	ra,0xffffc
    80005330:	67a080e7          	jalr	1658(ra) # 800019a6 <myproc>
    80005334:	fdc42703          	lw	a4,-36(s0)
    80005338:	01a70793          	addi	a5,a4,26
    8000533c:	078e                	slli	a5,a5,0x3
    8000533e:	953e                	add	a0,a0,a5
    80005340:	611c                	ld	a5,0(a0)
    80005342:	c385                	beqz	a5,80005362 <argfd+0x5c>
    return -1;
  if(pfd)
    80005344:	00090463          	beqz	s2,8000534c <argfd+0x46>
    *pfd = fd;
    80005348:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000534c:	4501                	li	a0,0
  if(pf)
    8000534e:	c091                	beqz	s1,80005352 <argfd+0x4c>
    *pf = f;
    80005350:	e09c                	sd	a5,0(s1)
}
    80005352:	70a2                	ld	ra,40(sp)
    80005354:	7402                	ld	s0,32(sp)
    80005356:	64e2                	ld	s1,24(sp)
    80005358:	6942                	ld	s2,16(sp)
    8000535a:	6145                	addi	sp,sp,48
    8000535c:	8082                	ret
    return -1;
    8000535e:	557d                	li	a0,-1
    80005360:	bfcd                	j	80005352 <argfd+0x4c>
    80005362:	557d                	li	a0,-1
    80005364:	b7fd                	j	80005352 <argfd+0x4c>

0000000080005366 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005366:	1101                	addi	sp,sp,-32
    80005368:	ec06                	sd	ra,24(sp)
    8000536a:	e822                	sd	s0,16(sp)
    8000536c:	e426                	sd	s1,8(sp)
    8000536e:	1000                	addi	s0,sp,32
    80005370:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005372:	ffffc097          	auipc	ra,0xffffc
    80005376:	634080e7          	jalr	1588(ra) # 800019a6 <myproc>
    8000537a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000537c:	0d050793          	addi	a5,a0,208
    80005380:	4501                	li	a0,0
    80005382:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005384:	6398                	ld	a4,0(a5)
    80005386:	cb19                	beqz	a4,8000539c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005388:	2505                	addiw	a0,a0,1
    8000538a:	07a1                	addi	a5,a5,8
    8000538c:	fed51ce3          	bne	a0,a3,80005384 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005390:	557d                	li	a0,-1
}
    80005392:	60e2                	ld	ra,24(sp)
    80005394:	6442                	ld	s0,16(sp)
    80005396:	64a2                	ld	s1,8(sp)
    80005398:	6105                	addi	sp,sp,32
    8000539a:	8082                	ret
      p->ofile[fd] = f;
    8000539c:	01a50793          	addi	a5,a0,26
    800053a0:	078e                	slli	a5,a5,0x3
    800053a2:	963e                	add	a2,a2,a5
    800053a4:	e204                	sd	s1,0(a2)
      return fd;
    800053a6:	b7f5                	j	80005392 <fdalloc+0x2c>

00000000800053a8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053a8:	715d                	addi	sp,sp,-80
    800053aa:	e486                	sd	ra,72(sp)
    800053ac:	e0a2                	sd	s0,64(sp)
    800053ae:	fc26                	sd	s1,56(sp)
    800053b0:	f84a                	sd	s2,48(sp)
    800053b2:	f44e                	sd	s3,40(sp)
    800053b4:	f052                	sd	s4,32(sp)
    800053b6:	ec56                	sd	s5,24(sp)
    800053b8:	e85a                	sd	s6,16(sp)
    800053ba:	0880                	addi	s0,sp,80
    800053bc:	8b2e                	mv	s6,a1
    800053be:	89b2                	mv	s3,a2
    800053c0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053c2:	fb040593          	addi	a1,s0,-80
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	e7e080e7          	jalr	-386(ra) # 80004244 <nameiparent>
    800053ce:	84aa                	mv	s1,a0
    800053d0:	14050b63          	beqz	a0,80005526 <create+0x17e>
    return 0;

  ilock(dp);
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	6ac080e7          	jalr	1708(ra) # 80003a80 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053dc:	4601                	li	a2,0
    800053de:	fb040593          	addi	a1,s0,-80
    800053e2:	8526                	mv	a0,s1
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	b80080e7          	jalr	-1152(ra) # 80003f64 <dirlookup>
    800053ec:	8aaa                	mv	s5,a0
    800053ee:	c921                	beqz	a0,8000543e <create+0x96>
    iunlockput(dp);
    800053f0:	8526                	mv	a0,s1
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	8f0080e7          	jalr	-1808(ra) # 80003ce2 <iunlockput>
    ilock(ip);
    800053fa:	8556                	mv	a0,s5
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	684080e7          	jalr	1668(ra) # 80003a80 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005404:	4789                	li	a5,2
    80005406:	02fb1563          	bne	s6,a5,80005430 <create+0x88>
    8000540a:	044ad783          	lhu	a5,68(s5)
    8000540e:	37f9                	addiw	a5,a5,-2
    80005410:	17c2                	slli	a5,a5,0x30
    80005412:	93c1                	srli	a5,a5,0x30
    80005414:	4705                	li	a4,1
    80005416:	00f76d63          	bltu	a4,a5,80005430 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000541a:	8556                	mv	a0,s5
    8000541c:	60a6                	ld	ra,72(sp)
    8000541e:	6406                	ld	s0,64(sp)
    80005420:	74e2                	ld	s1,56(sp)
    80005422:	7942                	ld	s2,48(sp)
    80005424:	79a2                	ld	s3,40(sp)
    80005426:	7a02                	ld	s4,32(sp)
    80005428:	6ae2                	ld	s5,24(sp)
    8000542a:	6b42                	ld	s6,16(sp)
    8000542c:	6161                	addi	sp,sp,80
    8000542e:	8082                	ret
    iunlockput(ip);
    80005430:	8556                	mv	a0,s5
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	8b0080e7          	jalr	-1872(ra) # 80003ce2 <iunlockput>
    return 0;
    8000543a:	4a81                	li	s5,0
    8000543c:	bff9                	j	8000541a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000543e:	85da                	mv	a1,s6
    80005440:	4088                	lw	a0,0(s1)
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	4a6080e7          	jalr	1190(ra) # 800038e8 <ialloc>
    8000544a:	8a2a                	mv	s4,a0
    8000544c:	c529                	beqz	a0,80005496 <create+0xee>
  ilock(ip);
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	632080e7          	jalr	1586(ra) # 80003a80 <ilock>
  ip->major = major;
    80005456:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000545a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000545e:	4905                	li	s2,1
    80005460:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005464:	8552                	mv	a0,s4
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	54e080e7          	jalr	1358(ra) # 800039b4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000546e:	032b0b63          	beq	s6,s2,800054a4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005472:	004a2603          	lw	a2,4(s4)
    80005476:	fb040593          	addi	a1,s0,-80
    8000547a:	8526                	mv	a0,s1
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	cf8080e7          	jalr	-776(ra) # 80004174 <dirlink>
    80005484:	06054f63          	bltz	a0,80005502 <create+0x15a>
  iunlockput(dp);
    80005488:	8526                	mv	a0,s1
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	858080e7          	jalr	-1960(ra) # 80003ce2 <iunlockput>
  return ip;
    80005492:	8ad2                	mv	s5,s4
    80005494:	b759                	j	8000541a <create+0x72>
    iunlockput(dp);
    80005496:	8526                	mv	a0,s1
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	84a080e7          	jalr	-1974(ra) # 80003ce2 <iunlockput>
    return 0;
    800054a0:	8ad2                	mv	s5,s4
    800054a2:	bfa5                	j	8000541a <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054a4:	004a2603          	lw	a2,4(s4)
    800054a8:	00003597          	auipc	a1,0x3
    800054ac:	26858593          	addi	a1,a1,616 # 80008710 <syscalls+0x2c0>
    800054b0:	8552                	mv	a0,s4
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	cc2080e7          	jalr	-830(ra) # 80004174 <dirlink>
    800054ba:	04054463          	bltz	a0,80005502 <create+0x15a>
    800054be:	40d0                	lw	a2,4(s1)
    800054c0:	00003597          	auipc	a1,0x3
    800054c4:	25858593          	addi	a1,a1,600 # 80008718 <syscalls+0x2c8>
    800054c8:	8552                	mv	a0,s4
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	caa080e7          	jalr	-854(ra) # 80004174 <dirlink>
    800054d2:	02054863          	bltz	a0,80005502 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800054d6:	004a2603          	lw	a2,4(s4)
    800054da:	fb040593          	addi	a1,s0,-80
    800054de:	8526                	mv	a0,s1
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	c94080e7          	jalr	-876(ra) # 80004174 <dirlink>
    800054e8:	00054d63          	bltz	a0,80005502 <create+0x15a>
    dp->nlink++;  // for ".."
    800054ec:	04a4d783          	lhu	a5,74(s1)
    800054f0:	2785                	addiw	a5,a5,1
    800054f2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	4bc080e7          	jalr	1212(ra) # 800039b4 <iupdate>
    80005500:	b761                	j	80005488 <create+0xe0>
  ip->nlink = 0;
    80005502:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005506:	8552                	mv	a0,s4
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	4ac080e7          	jalr	1196(ra) # 800039b4 <iupdate>
  iunlockput(ip);
    80005510:	8552                	mv	a0,s4
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	7d0080e7          	jalr	2000(ra) # 80003ce2 <iunlockput>
  iunlockput(dp);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	7c6080e7          	jalr	1990(ra) # 80003ce2 <iunlockput>
  return 0;
    80005524:	bddd                	j	8000541a <create+0x72>
    return 0;
    80005526:	8aaa                	mv	s5,a0
    80005528:	bdcd                	j	8000541a <create+0x72>

000000008000552a <sys_dup>:
{
    8000552a:	7179                	addi	sp,sp,-48
    8000552c:	f406                	sd	ra,40(sp)
    8000552e:	f022                	sd	s0,32(sp)
    80005530:	ec26                	sd	s1,24(sp)
    80005532:	e84a                	sd	s2,16(sp)
    80005534:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005536:	fd840613          	addi	a2,s0,-40
    8000553a:	4581                	li	a1,0
    8000553c:	4501                	li	a0,0
    8000553e:	00000097          	auipc	ra,0x0
    80005542:	dc8080e7          	jalr	-568(ra) # 80005306 <argfd>
    return -1;
    80005546:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005548:	02054363          	bltz	a0,8000556e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000554c:	fd843903          	ld	s2,-40(s0)
    80005550:	854a                	mv	a0,s2
    80005552:	00000097          	auipc	ra,0x0
    80005556:	e14080e7          	jalr	-492(ra) # 80005366 <fdalloc>
    8000555a:	84aa                	mv	s1,a0
    return -1;
    8000555c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000555e:	00054863          	bltz	a0,8000556e <sys_dup+0x44>
  filedup(f);
    80005562:	854a                	mv	a0,s2
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	334080e7          	jalr	820(ra) # 80004898 <filedup>
  return fd;
    8000556c:	87a6                	mv	a5,s1
}
    8000556e:	853e                	mv	a0,a5
    80005570:	70a2                	ld	ra,40(sp)
    80005572:	7402                	ld	s0,32(sp)
    80005574:	64e2                	ld	s1,24(sp)
    80005576:	6942                	ld	s2,16(sp)
    80005578:	6145                	addi	sp,sp,48
    8000557a:	8082                	ret

000000008000557c <sys_read>:
{
    8000557c:	7179                	addi	sp,sp,-48
    8000557e:	f406                	sd	ra,40(sp)
    80005580:	f022                	sd	s0,32(sp)
    80005582:	1800                	addi	s0,sp,48
  READCOUNT++;
    80005584:	00003717          	auipc	a4,0x3
    80005588:	38470713          	addi	a4,a4,900 # 80008908 <READCOUNT>
    8000558c:	631c                	ld	a5,0(a4)
    8000558e:	0785                	addi	a5,a5,1
    80005590:	e31c                	sd	a5,0(a4)
  argaddr(1, &p);
    80005592:	fd840593          	addi	a1,s0,-40
    80005596:	4505                	li	a0,1
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	86e080e7          	jalr	-1938(ra) # 80002e06 <argaddr>
  argint(2, &n);
    800055a0:	fe440593          	addi	a1,s0,-28
    800055a4:	4509                	li	a0,2
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	840080e7          	jalr	-1984(ra) # 80002de6 <argint>
  if(argfd(0, 0, &f) < 0)
    800055ae:	fe840613          	addi	a2,s0,-24
    800055b2:	4581                	li	a1,0
    800055b4:	4501                	li	a0,0
    800055b6:	00000097          	auipc	ra,0x0
    800055ba:	d50080e7          	jalr	-688(ra) # 80005306 <argfd>
    800055be:	87aa                	mv	a5,a0
    return -1;
    800055c0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055c2:	0007cc63          	bltz	a5,800055da <sys_read+0x5e>
  return fileread(f, p, n);
    800055c6:	fe442603          	lw	a2,-28(s0)
    800055ca:	fd843583          	ld	a1,-40(s0)
    800055ce:	fe843503          	ld	a0,-24(s0)
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	452080e7          	jalr	1106(ra) # 80004a24 <fileread>
}
    800055da:	70a2                	ld	ra,40(sp)
    800055dc:	7402                	ld	s0,32(sp)
    800055de:	6145                	addi	sp,sp,48
    800055e0:	8082                	ret

00000000800055e2 <sys_write>:
{
    800055e2:	7179                	addi	sp,sp,-48
    800055e4:	f406                	sd	ra,40(sp)
    800055e6:	f022                	sd	s0,32(sp)
    800055e8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055ea:	fd840593          	addi	a1,s0,-40
    800055ee:	4505                	li	a0,1
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	816080e7          	jalr	-2026(ra) # 80002e06 <argaddr>
  argint(2, &n);
    800055f8:	fe440593          	addi	a1,s0,-28
    800055fc:	4509                	li	a0,2
    800055fe:	ffffd097          	auipc	ra,0xffffd
    80005602:	7e8080e7          	jalr	2024(ra) # 80002de6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005606:	fe840613          	addi	a2,s0,-24
    8000560a:	4581                	li	a1,0
    8000560c:	4501                	li	a0,0
    8000560e:	00000097          	auipc	ra,0x0
    80005612:	cf8080e7          	jalr	-776(ra) # 80005306 <argfd>
    80005616:	87aa                	mv	a5,a0
    return -1;
    80005618:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000561a:	0007cc63          	bltz	a5,80005632 <sys_write+0x50>
  return filewrite(f, p, n);
    8000561e:	fe442603          	lw	a2,-28(s0)
    80005622:	fd843583          	ld	a1,-40(s0)
    80005626:	fe843503          	ld	a0,-24(s0)
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	4bc080e7          	jalr	1212(ra) # 80004ae6 <filewrite>
}
    80005632:	70a2                	ld	ra,40(sp)
    80005634:	7402                	ld	s0,32(sp)
    80005636:	6145                	addi	sp,sp,48
    80005638:	8082                	ret

000000008000563a <sys_close>:
{
    8000563a:	1101                	addi	sp,sp,-32
    8000563c:	ec06                	sd	ra,24(sp)
    8000563e:	e822                	sd	s0,16(sp)
    80005640:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005642:	fe040613          	addi	a2,s0,-32
    80005646:	fec40593          	addi	a1,s0,-20
    8000564a:	4501                	li	a0,0
    8000564c:	00000097          	auipc	ra,0x0
    80005650:	cba080e7          	jalr	-838(ra) # 80005306 <argfd>
    return -1;
    80005654:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005656:	02054463          	bltz	a0,8000567e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000565a:	ffffc097          	auipc	ra,0xffffc
    8000565e:	34c080e7          	jalr	844(ra) # 800019a6 <myproc>
    80005662:	fec42783          	lw	a5,-20(s0)
    80005666:	07e9                	addi	a5,a5,26
    80005668:	078e                	slli	a5,a5,0x3
    8000566a:	953e                	add	a0,a0,a5
    8000566c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005670:	fe043503          	ld	a0,-32(s0)
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	276080e7          	jalr	630(ra) # 800048ea <fileclose>
  return 0;
    8000567c:	4781                	li	a5,0
}
    8000567e:	853e                	mv	a0,a5
    80005680:	60e2                	ld	ra,24(sp)
    80005682:	6442                	ld	s0,16(sp)
    80005684:	6105                	addi	sp,sp,32
    80005686:	8082                	ret

0000000080005688 <sys_fstat>:
{
    80005688:	1101                	addi	sp,sp,-32
    8000568a:	ec06                	sd	ra,24(sp)
    8000568c:	e822                	sd	s0,16(sp)
    8000568e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005690:	fe040593          	addi	a1,s0,-32
    80005694:	4505                	li	a0,1
    80005696:	ffffd097          	auipc	ra,0xffffd
    8000569a:	770080e7          	jalr	1904(ra) # 80002e06 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000569e:	fe840613          	addi	a2,s0,-24
    800056a2:	4581                	li	a1,0
    800056a4:	4501                	li	a0,0
    800056a6:	00000097          	auipc	ra,0x0
    800056aa:	c60080e7          	jalr	-928(ra) # 80005306 <argfd>
    800056ae:	87aa                	mv	a5,a0
    return -1;
    800056b0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056b2:	0007ca63          	bltz	a5,800056c6 <sys_fstat+0x3e>
  return filestat(f, st);
    800056b6:	fe043583          	ld	a1,-32(s0)
    800056ba:	fe843503          	ld	a0,-24(s0)
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	2f4080e7          	jalr	756(ra) # 800049b2 <filestat>
}
    800056c6:	60e2                	ld	ra,24(sp)
    800056c8:	6442                	ld	s0,16(sp)
    800056ca:	6105                	addi	sp,sp,32
    800056cc:	8082                	ret

00000000800056ce <sys_link>:
{
    800056ce:	7169                	addi	sp,sp,-304
    800056d0:	f606                	sd	ra,296(sp)
    800056d2:	f222                	sd	s0,288(sp)
    800056d4:	ee26                	sd	s1,280(sp)
    800056d6:	ea4a                	sd	s2,272(sp)
    800056d8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056da:	08000613          	li	a2,128
    800056de:	ed040593          	addi	a1,s0,-304
    800056e2:	4501                	li	a0,0
    800056e4:	ffffd097          	auipc	ra,0xffffd
    800056e8:	742080e7          	jalr	1858(ra) # 80002e26 <argstr>
    return -1;
    800056ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056ee:	10054e63          	bltz	a0,8000580a <sys_link+0x13c>
    800056f2:	08000613          	li	a2,128
    800056f6:	f5040593          	addi	a1,s0,-176
    800056fa:	4505                	li	a0,1
    800056fc:	ffffd097          	auipc	ra,0xffffd
    80005700:	72a080e7          	jalr	1834(ra) # 80002e26 <argstr>
    return -1;
    80005704:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005706:	10054263          	bltz	a0,8000580a <sys_link+0x13c>
  begin_op();
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	d1c080e7          	jalr	-740(ra) # 80004426 <begin_op>
  if((ip = namei(old)) == 0){
    80005712:	ed040513          	addi	a0,s0,-304
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	b10080e7          	jalr	-1264(ra) # 80004226 <namei>
    8000571e:	84aa                	mv	s1,a0
    80005720:	c551                	beqz	a0,800057ac <sys_link+0xde>
  ilock(ip);
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	35e080e7          	jalr	862(ra) # 80003a80 <ilock>
  if(ip->type == T_DIR){
    8000572a:	04449703          	lh	a4,68(s1)
    8000572e:	4785                	li	a5,1
    80005730:	08f70463          	beq	a4,a5,800057b8 <sys_link+0xea>
  ip->nlink++;
    80005734:	04a4d783          	lhu	a5,74(s1)
    80005738:	2785                	addiw	a5,a5,1
    8000573a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000573e:	8526                	mv	a0,s1
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	274080e7          	jalr	628(ra) # 800039b4 <iupdate>
  iunlock(ip);
    80005748:	8526                	mv	a0,s1
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	3f8080e7          	jalr	1016(ra) # 80003b42 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005752:	fd040593          	addi	a1,s0,-48
    80005756:	f5040513          	addi	a0,s0,-176
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	aea080e7          	jalr	-1302(ra) # 80004244 <nameiparent>
    80005762:	892a                	mv	s2,a0
    80005764:	c935                	beqz	a0,800057d8 <sys_link+0x10a>
  ilock(dp);
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	31a080e7          	jalr	794(ra) # 80003a80 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000576e:	00092703          	lw	a4,0(s2)
    80005772:	409c                	lw	a5,0(s1)
    80005774:	04f71d63          	bne	a4,a5,800057ce <sys_link+0x100>
    80005778:	40d0                	lw	a2,4(s1)
    8000577a:	fd040593          	addi	a1,s0,-48
    8000577e:	854a                	mv	a0,s2
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	9f4080e7          	jalr	-1548(ra) # 80004174 <dirlink>
    80005788:	04054363          	bltz	a0,800057ce <sys_link+0x100>
  iunlockput(dp);
    8000578c:	854a                	mv	a0,s2
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	554080e7          	jalr	1364(ra) # 80003ce2 <iunlockput>
  iput(ip);
    80005796:	8526                	mv	a0,s1
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	4a2080e7          	jalr	1186(ra) # 80003c3a <iput>
  end_op();
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	d00080e7          	jalr	-768(ra) # 800044a0 <end_op>
  return 0;
    800057a8:	4781                	li	a5,0
    800057aa:	a085                	j	8000580a <sys_link+0x13c>
    end_op();
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	cf4080e7          	jalr	-780(ra) # 800044a0 <end_op>
    return -1;
    800057b4:	57fd                	li	a5,-1
    800057b6:	a891                	j	8000580a <sys_link+0x13c>
    iunlockput(ip);
    800057b8:	8526                	mv	a0,s1
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	528080e7          	jalr	1320(ra) # 80003ce2 <iunlockput>
    end_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	cde080e7          	jalr	-802(ra) # 800044a0 <end_op>
    return -1;
    800057ca:	57fd                	li	a5,-1
    800057cc:	a83d                	j	8000580a <sys_link+0x13c>
    iunlockput(dp);
    800057ce:	854a                	mv	a0,s2
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	512080e7          	jalr	1298(ra) # 80003ce2 <iunlockput>
  ilock(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	2a6080e7          	jalr	678(ra) # 80003a80 <ilock>
  ip->nlink--;
    800057e2:	04a4d783          	lhu	a5,74(s1)
    800057e6:	37fd                	addiw	a5,a5,-1
    800057e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057ec:	8526                	mv	a0,s1
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	1c6080e7          	jalr	454(ra) # 800039b4 <iupdate>
  iunlockput(ip);
    800057f6:	8526                	mv	a0,s1
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	4ea080e7          	jalr	1258(ra) # 80003ce2 <iunlockput>
  end_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	ca0080e7          	jalr	-864(ra) # 800044a0 <end_op>
  return -1;
    80005808:	57fd                	li	a5,-1
}
    8000580a:	853e                	mv	a0,a5
    8000580c:	70b2                	ld	ra,296(sp)
    8000580e:	7412                	ld	s0,288(sp)
    80005810:	64f2                	ld	s1,280(sp)
    80005812:	6952                	ld	s2,272(sp)
    80005814:	6155                	addi	sp,sp,304
    80005816:	8082                	ret

0000000080005818 <sys_unlink>:
{
    80005818:	7151                	addi	sp,sp,-240
    8000581a:	f586                	sd	ra,232(sp)
    8000581c:	f1a2                	sd	s0,224(sp)
    8000581e:	eda6                	sd	s1,216(sp)
    80005820:	e9ca                	sd	s2,208(sp)
    80005822:	e5ce                	sd	s3,200(sp)
    80005824:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005826:	08000613          	li	a2,128
    8000582a:	f3040593          	addi	a1,s0,-208
    8000582e:	4501                	li	a0,0
    80005830:	ffffd097          	auipc	ra,0xffffd
    80005834:	5f6080e7          	jalr	1526(ra) # 80002e26 <argstr>
    80005838:	18054163          	bltz	a0,800059ba <sys_unlink+0x1a2>
  begin_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	bea080e7          	jalr	-1046(ra) # 80004426 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005844:	fb040593          	addi	a1,s0,-80
    80005848:	f3040513          	addi	a0,s0,-208
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	9f8080e7          	jalr	-1544(ra) # 80004244 <nameiparent>
    80005854:	84aa                	mv	s1,a0
    80005856:	c979                	beqz	a0,8000592c <sys_unlink+0x114>
  ilock(dp);
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	228080e7          	jalr	552(ra) # 80003a80 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005860:	00003597          	auipc	a1,0x3
    80005864:	eb058593          	addi	a1,a1,-336 # 80008710 <syscalls+0x2c0>
    80005868:	fb040513          	addi	a0,s0,-80
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	6de080e7          	jalr	1758(ra) # 80003f4a <namecmp>
    80005874:	14050a63          	beqz	a0,800059c8 <sys_unlink+0x1b0>
    80005878:	00003597          	auipc	a1,0x3
    8000587c:	ea058593          	addi	a1,a1,-352 # 80008718 <syscalls+0x2c8>
    80005880:	fb040513          	addi	a0,s0,-80
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	6c6080e7          	jalr	1734(ra) # 80003f4a <namecmp>
    8000588c:	12050e63          	beqz	a0,800059c8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005890:	f2c40613          	addi	a2,s0,-212
    80005894:	fb040593          	addi	a1,s0,-80
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	6ca080e7          	jalr	1738(ra) # 80003f64 <dirlookup>
    800058a2:	892a                	mv	s2,a0
    800058a4:	12050263          	beqz	a0,800059c8 <sys_unlink+0x1b0>
  ilock(ip);
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	1d8080e7          	jalr	472(ra) # 80003a80 <ilock>
  if(ip->nlink < 1)
    800058b0:	04a91783          	lh	a5,74(s2)
    800058b4:	08f05263          	blez	a5,80005938 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058b8:	04491703          	lh	a4,68(s2)
    800058bc:	4785                	li	a5,1
    800058be:	08f70563          	beq	a4,a5,80005948 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058c2:	4641                	li	a2,16
    800058c4:	4581                	li	a1,0
    800058c6:	fc040513          	addi	a0,s0,-64
    800058ca:	ffffb097          	auipc	ra,0xffffb
    800058ce:	404080e7          	jalr	1028(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058d2:	4741                	li	a4,16
    800058d4:	f2c42683          	lw	a3,-212(s0)
    800058d8:	fc040613          	addi	a2,s0,-64
    800058dc:	4581                	li	a1,0
    800058de:	8526                	mv	a0,s1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	54c080e7          	jalr	1356(ra) # 80003e2c <writei>
    800058e8:	47c1                	li	a5,16
    800058ea:	0af51563          	bne	a0,a5,80005994 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058ee:	04491703          	lh	a4,68(s2)
    800058f2:	4785                	li	a5,1
    800058f4:	0af70863          	beq	a4,a5,800059a4 <sys_unlink+0x18c>
  iunlockput(dp);
    800058f8:	8526                	mv	a0,s1
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	3e8080e7          	jalr	1000(ra) # 80003ce2 <iunlockput>
  ip->nlink--;
    80005902:	04a95783          	lhu	a5,74(s2)
    80005906:	37fd                	addiw	a5,a5,-1
    80005908:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000590c:	854a                	mv	a0,s2
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	0a6080e7          	jalr	166(ra) # 800039b4 <iupdate>
  iunlockput(ip);
    80005916:	854a                	mv	a0,s2
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	3ca080e7          	jalr	970(ra) # 80003ce2 <iunlockput>
  end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	b80080e7          	jalr	-1152(ra) # 800044a0 <end_op>
  return 0;
    80005928:	4501                	li	a0,0
    8000592a:	a84d                	j	800059dc <sys_unlink+0x1c4>
    end_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	b74080e7          	jalr	-1164(ra) # 800044a0 <end_op>
    return -1;
    80005934:	557d                	li	a0,-1
    80005936:	a05d                	j	800059dc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005938:	00003517          	auipc	a0,0x3
    8000593c:	de850513          	addi	a0,a0,-536 # 80008720 <syscalls+0x2d0>
    80005940:	ffffb097          	auipc	ra,0xffffb
    80005944:	bfc080e7          	jalr	-1028(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005948:	04c92703          	lw	a4,76(s2)
    8000594c:	02000793          	li	a5,32
    80005950:	f6e7f9e3          	bgeu	a5,a4,800058c2 <sys_unlink+0xaa>
    80005954:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005958:	4741                	li	a4,16
    8000595a:	86ce                	mv	a3,s3
    8000595c:	f1840613          	addi	a2,s0,-232
    80005960:	4581                	li	a1,0
    80005962:	854a                	mv	a0,s2
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	3d0080e7          	jalr	976(ra) # 80003d34 <readi>
    8000596c:	47c1                	li	a5,16
    8000596e:	00f51b63          	bne	a0,a5,80005984 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005972:	f1845783          	lhu	a5,-232(s0)
    80005976:	e7a1                	bnez	a5,800059be <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005978:	29c1                	addiw	s3,s3,16
    8000597a:	04c92783          	lw	a5,76(s2)
    8000597e:	fcf9ede3          	bltu	s3,a5,80005958 <sys_unlink+0x140>
    80005982:	b781                	j	800058c2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005984:	00003517          	auipc	a0,0x3
    80005988:	db450513          	addi	a0,a0,-588 # 80008738 <syscalls+0x2e8>
    8000598c:	ffffb097          	auipc	ra,0xffffb
    80005990:	bb0080e7          	jalr	-1104(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005994:	00003517          	auipc	a0,0x3
    80005998:	dbc50513          	addi	a0,a0,-580 # 80008750 <syscalls+0x300>
    8000599c:	ffffb097          	auipc	ra,0xffffb
    800059a0:	ba0080e7          	jalr	-1120(ra) # 8000053c <panic>
    dp->nlink--;
    800059a4:	04a4d783          	lhu	a5,74(s1)
    800059a8:	37fd                	addiw	a5,a5,-1
    800059aa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059ae:	8526                	mv	a0,s1
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	004080e7          	jalr	4(ra) # 800039b4 <iupdate>
    800059b8:	b781                	j	800058f8 <sys_unlink+0xe0>
    return -1;
    800059ba:	557d                	li	a0,-1
    800059bc:	a005                	j	800059dc <sys_unlink+0x1c4>
    iunlockput(ip);
    800059be:	854a                	mv	a0,s2
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	322080e7          	jalr	802(ra) # 80003ce2 <iunlockput>
  iunlockput(dp);
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	318080e7          	jalr	792(ra) # 80003ce2 <iunlockput>
  end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	ace080e7          	jalr	-1330(ra) # 800044a0 <end_op>
  return -1;
    800059da:	557d                	li	a0,-1
}
    800059dc:	70ae                	ld	ra,232(sp)
    800059de:	740e                	ld	s0,224(sp)
    800059e0:	64ee                	ld	s1,216(sp)
    800059e2:	694e                	ld	s2,208(sp)
    800059e4:	69ae                	ld	s3,200(sp)
    800059e6:	616d                	addi	sp,sp,240
    800059e8:	8082                	ret

00000000800059ea <sys_open>:

uint64
sys_open(void)
{
    800059ea:	7131                	addi	sp,sp,-192
    800059ec:	fd06                	sd	ra,184(sp)
    800059ee:	f922                	sd	s0,176(sp)
    800059f0:	f526                	sd	s1,168(sp)
    800059f2:	f14a                	sd	s2,160(sp)
    800059f4:	ed4e                	sd	s3,152(sp)
    800059f6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059f8:	f4c40593          	addi	a1,s0,-180
    800059fc:	4505                	li	a0,1
    800059fe:	ffffd097          	auipc	ra,0xffffd
    80005a02:	3e8080e7          	jalr	1000(ra) # 80002de6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a06:	08000613          	li	a2,128
    80005a0a:	f5040593          	addi	a1,s0,-176
    80005a0e:	4501                	li	a0,0
    80005a10:	ffffd097          	auipc	ra,0xffffd
    80005a14:	416080e7          	jalr	1046(ra) # 80002e26 <argstr>
    80005a18:	87aa                	mv	a5,a0
    return -1;
    80005a1a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a1c:	0a07c863          	bltz	a5,80005acc <sys_open+0xe2>

  begin_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	a06080e7          	jalr	-1530(ra) # 80004426 <begin_op>

  if(omode & O_CREATE){
    80005a28:	f4c42783          	lw	a5,-180(s0)
    80005a2c:	2007f793          	andi	a5,a5,512
    80005a30:	cbdd                	beqz	a5,80005ae6 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005a32:	4681                	li	a3,0
    80005a34:	4601                	li	a2,0
    80005a36:	4589                	li	a1,2
    80005a38:	f5040513          	addi	a0,s0,-176
    80005a3c:	00000097          	auipc	ra,0x0
    80005a40:	96c080e7          	jalr	-1684(ra) # 800053a8 <create>
    80005a44:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a46:	c951                	beqz	a0,80005ada <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a48:	04449703          	lh	a4,68(s1)
    80005a4c:	478d                	li	a5,3
    80005a4e:	00f71763          	bne	a4,a5,80005a5c <sys_open+0x72>
    80005a52:	0464d703          	lhu	a4,70(s1)
    80005a56:	47a5                	li	a5,9
    80005a58:	0ce7ec63          	bltu	a5,a4,80005b30 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	dd2080e7          	jalr	-558(ra) # 8000482e <filealloc>
    80005a64:	892a                	mv	s2,a0
    80005a66:	c56d                	beqz	a0,80005b50 <sys_open+0x166>
    80005a68:	00000097          	auipc	ra,0x0
    80005a6c:	8fe080e7          	jalr	-1794(ra) # 80005366 <fdalloc>
    80005a70:	89aa                	mv	s3,a0
    80005a72:	0c054a63          	bltz	a0,80005b46 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a76:	04449703          	lh	a4,68(s1)
    80005a7a:	478d                	li	a5,3
    80005a7c:	0ef70563          	beq	a4,a5,80005b66 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a80:	4789                	li	a5,2
    80005a82:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005a86:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005a8a:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005a8e:	f4c42783          	lw	a5,-180(s0)
    80005a92:	0017c713          	xori	a4,a5,1
    80005a96:	8b05                	andi	a4,a4,1
    80005a98:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a9c:	0037f713          	andi	a4,a5,3
    80005aa0:	00e03733          	snez	a4,a4
    80005aa4:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005aa8:	4007f793          	andi	a5,a5,1024
    80005aac:	c791                	beqz	a5,80005ab8 <sys_open+0xce>
    80005aae:	04449703          	lh	a4,68(s1)
    80005ab2:	4789                	li	a5,2
    80005ab4:	0cf70063          	beq	a4,a5,80005b74 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005ab8:	8526                	mv	a0,s1
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	088080e7          	jalr	136(ra) # 80003b42 <iunlock>
  end_op();
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	9de080e7          	jalr	-1570(ra) # 800044a0 <end_op>

  return fd;
    80005aca:	854e                	mv	a0,s3
}
    80005acc:	70ea                	ld	ra,184(sp)
    80005ace:	744a                	ld	s0,176(sp)
    80005ad0:	74aa                	ld	s1,168(sp)
    80005ad2:	790a                	ld	s2,160(sp)
    80005ad4:	69ea                	ld	s3,152(sp)
    80005ad6:	6129                	addi	sp,sp,192
    80005ad8:	8082                	ret
      end_op();
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	9c6080e7          	jalr	-1594(ra) # 800044a0 <end_op>
      return -1;
    80005ae2:	557d                	li	a0,-1
    80005ae4:	b7e5                	j	80005acc <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005ae6:	f5040513          	addi	a0,s0,-176
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	73c080e7          	jalr	1852(ra) # 80004226 <namei>
    80005af2:	84aa                	mv	s1,a0
    80005af4:	c905                	beqz	a0,80005b24 <sys_open+0x13a>
    ilock(ip);
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	f8a080e7          	jalr	-118(ra) # 80003a80 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005afe:	04449703          	lh	a4,68(s1)
    80005b02:	4785                	li	a5,1
    80005b04:	f4f712e3          	bne	a4,a5,80005a48 <sys_open+0x5e>
    80005b08:	f4c42783          	lw	a5,-180(s0)
    80005b0c:	dba1                	beqz	a5,80005a5c <sys_open+0x72>
      iunlockput(ip);
    80005b0e:	8526                	mv	a0,s1
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	1d2080e7          	jalr	466(ra) # 80003ce2 <iunlockput>
      end_op();
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	988080e7          	jalr	-1656(ra) # 800044a0 <end_op>
      return -1;
    80005b20:	557d                	li	a0,-1
    80005b22:	b76d                	j	80005acc <sys_open+0xe2>
      end_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	97c080e7          	jalr	-1668(ra) # 800044a0 <end_op>
      return -1;
    80005b2c:	557d                	li	a0,-1
    80005b2e:	bf79                	j	80005acc <sys_open+0xe2>
    iunlockput(ip);
    80005b30:	8526                	mv	a0,s1
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	1b0080e7          	jalr	432(ra) # 80003ce2 <iunlockput>
    end_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	966080e7          	jalr	-1690(ra) # 800044a0 <end_op>
    return -1;
    80005b42:	557d                	li	a0,-1
    80005b44:	b761                	j	80005acc <sys_open+0xe2>
      fileclose(f);
    80005b46:	854a                	mv	a0,s2
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	da2080e7          	jalr	-606(ra) # 800048ea <fileclose>
    iunlockput(ip);
    80005b50:	8526                	mv	a0,s1
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	190080e7          	jalr	400(ra) # 80003ce2 <iunlockput>
    end_op();
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	946080e7          	jalr	-1722(ra) # 800044a0 <end_op>
    return -1;
    80005b62:	557d                	li	a0,-1
    80005b64:	b7a5                	j	80005acc <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005b66:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005b6a:	04649783          	lh	a5,70(s1)
    80005b6e:	02f91223          	sh	a5,36(s2)
    80005b72:	bf21                	j	80005a8a <sys_open+0xa0>
    itrunc(ip);
    80005b74:	8526                	mv	a0,s1
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	018080e7          	jalr	24(ra) # 80003b8e <itrunc>
    80005b7e:	bf2d                	j	80005ab8 <sys_open+0xce>

0000000080005b80 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b80:	7175                	addi	sp,sp,-144
    80005b82:	e506                	sd	ra,136(sp)
    80005b84:	e122                	sd	s0,128(sp)
    80005b86:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	89e080e7          	jalr	-1890(ra) # 80004426 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b90:	08000613          	li	a2,128
    80005b94:	f7040593          	addi	a1,s0,-144
    80005b98:	4501                	li	a0,0
    80005b9a:	ffffd097          	auipc	ra,0xffffd
    80005b9e:	28c080e7          	jalr	652(ra) # 80002e26 <argstr>
    80005ba2:	02054963          	bltz	a0,80005bd4 <sys_mkdir+0x54>
    80005ba6:	4681                	li	a3,0
    80005ba8:	4601                	li	a2,0
    80005baa:	4585                	li	a1,1
    80005bac:	f7040513          	addi	a0,s0,-144
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	7f8080e7          	jalr	2040(ra) # 800053a8 <create>
    80005bb8:	cd11                	beqz	a0,80005bd4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	128080e7          	jalr	296(ra) # 80003ce2 <iunlockput>
  end_op();
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	8de080e7          	jalr	-1826(ra) # 800044a0 <end_op>
  return 0;
    80005bca:	4501                	li	a0,0
}
    80005bcc:	60aa                	ld	ra,136(sp)
    80005bce:	640a                	ld	s0,128(sp)
    80005bd0:	6149                	addi	sp,sp,144
    80005bd2:	8082                	ret
    end_op();
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	8cc080e7          	jalr	-1844(ra) # 800044a0 <end_op>
    return -1;
    80005bdc:	557d                	li	a0,-1
    80005bde:	b7fd                	j	80005bcc <sys_mkdir+0x4c>

0000000080005be0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005be0:	7135                	addi	sp,sp,-160
    80005be2:	ed06                	sd	ra,152(sp)
    80005be4:	e922                	sd	s0,144(sp)
    80005be6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	83e080e7          	jalr	-1986(ra) # 80004426 <begin_op>
  argint(1, &major);
    80005bf0:	f6c40593          	addi	a1,s0,-148
    80005bf4:	4505                	li	a0,1
    80005bf6:	ffffd097          	auipc	ra,0xffffd
    80005bfa:	1f0080e7          	jalr	496(ra) # 80002de6 <argint>
  argint(2, &minor);
    80005bfe:	f6840593          	addi	a1,s0,-152
    80005c02:	4509                	li	a0,2
    80005c04:	ffffd097          	auipc	ra,0xffffd
    80005c08:	1e2080e7          	jalr	482(ra) # 80002de6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c0c:	08000613          	li	a2,128
    80005c10:	f7040593          	addi	a1,s0,-144
    80005c14:	4501                	li	a0,0
    80005c16:	ffffd097          	auipc	ra,0xffffd
    80005c1a:	210080e7          	jalr	528(ra) # 80002e26 <argstr>
    80005c1e:	02054b63          	bltz	a0,80005c54 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c22:	f6841683          	lh	a3,-152(s0)
    80005c26:	f6c41603          	lh	a2,-148(s0)
    80005c2a:	458d                	li	a1,3
    80005c2c:	f7040513          	addi	a0,s0,-144
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	778080e7          	jalr	1912(ra) # 800053a8 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c38:	cd11                	beqz	a0,80005c54 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	0a8080e7          	jalr	168(ra) # 80003ce2 <iunlockput>
  end_op();
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	85e080e7          	jalr	-1954(ra) # 800044a0 <end_op>
  return 0;
    80005c4a:	4501                	li	a0,0
}
    80005c4c:	60ea                	ld	ra,152(sp)
    80005c4e:	644a                	ld	s0,144(sp)
    80005c50:	610d                	addi	sp,sp,160
    80005c52:	8082                	ret
    end_op();
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	84c080e7          	jalr	-1972(ra) # 800044a0 <end_op>
    return -1;
    80005c5c:	557d                	li	a0,-1
    80005c5e:	b7fd                	j	80005c4c <sys_mknod+0x6c>

0000000080005c60 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c60:	7135                	addi	sp,sp,-160
    80005c62:	ed06                	sd	ra,152(sp)
    80005c64:	e922                	sd	s0,144(sp)
    80005c66:	e526                	sd	s1,136(sp)
    80005c68:	e14a                	sd	s2,128(sp)
    80005c6a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c6c:	ffffc097          	auipc	ra,0xffffc
    80005c70:	d3a080e7          	jalr	-710(ra) # 800019a6 <myproc>
    80005c74:	892a                	mv	s2,a0
  
  begin_op();
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	7b0080e7          	jalr	1968(ra) # 80004426 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c7e:	08000613          	li	a2,128
    80005c82:	f6040593          	addi	a1,s0,-160
    80005c86:	4501                	li	a0,0
    80005c88:	ffffd097          	auipc	ra,0xffffd
    80005c8c:	19e080e7          	jalr	414(ra) # 80002e26 <argstr>
    80005c90:	04054b63          	bltz	a0,80005ce6 <sys_chdir+0x86>
    80005c94:	f6040513          	addi	a0,s0,-160
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	58e080e7          	jalr	1422(ra) # 80004226 <namei>
    80005ca0:	84aa                	mv	s1,a0
    80005ca2:	c131                	beqz	a0,80005ce6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	ddc080e7          	jalr	-548(ra) # 80003a80 <ilock>
  if(ip->type != T_DIR){
    80005cac:	04449703          	lh	a4,68(s1)
    80005cb0:	4785                	li	a5,1
    80005cb2:	04f71063          	bne	a4,a5,80005cf2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005cb6:	8526                	mv	a0,s1
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	e8a080e7          	jalr	-374(ra) # 80003b42 <iunlock>
  iput(p->cwd);
    80005cc0:	15093503          	ld	a0,336(s2)
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	f76080e7          	jalr	-138(ra) # 80003c3a <iput>
  end_op();
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	7d4080e7          	jalr	2004(ra) # 800044a0 <end_op>
  p->cwd = ip;
    80005cd4:	14993823          	sd	s1,336(s2)
  return 0;
    80005cd8:	4501                	li	a0,0
}
    80005cda:	60ea                	ld	ra,152(sp)
    80005cdc:	644a                	ld	s0,144(sp)
    80005cde:	64aa                	ld	s1,136(sp)
    80005ce0:	690a                	ld	s2,128(sp)
    80005ce2:	610d                	addi	sp,sp,160
    80005ce4:	8082                	ret
    end_op();
    80005ce6:	ffffe097          	auipc	ra,0xffffe
    80005cea:	7ba080e7          	jalr	1978(ra) # 800044a0 <end_op>
    return -1;
    80005cee:	557d                	li	a0,-1
    80005cf0:	b7ed                	j	80005cda <sys_chdir+0x7a>
    iunlockput(ip);
    80005cf2:	8526                	mv	a0,s1
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	fee080e7          	jalr	-18(ra) # 80003ce2 <iunlockput>
    end_op();
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	7a4080e7          	jalr	1956(ra) # 800044a0 <end_op>
    return -1;
    80005d04:	557d                	li	a0,-1
    80005d06:	bfd1                	j	80005cda <sys_chdir+0x7a>

0000000080005d08 <sys_exec>:

uint64
sys_exec(void)
{
    80005d08:	7121                	addi	sp,sp,-448
    80005d0a:	ff06                	sd	ra,440(sp)
    80005d0c:	fb22                	sd	s0,432(sp)
    80005d0e:	f726                	sd	s1,424(sp)
    80005d10:	f34a                	sd	s2,416(sp)
    80005d12:	ef4e                	sd	s3,408(sp)
    80005d14:	eb52                	sd	s4,400(sp)
    80005d16:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005d18:	e4840593          	addi	a1,s0,-440
    80005d1c:	4505                	li	a0,1
    80005d1e:	ffffd097          	auipc	ra,0xffffd
    80005d22:	0e8080e7          	jalr	232(ra) # 80002e06 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005d26:	08000613          	li	a2,128
    80005d2a:	f5040593          	addi	a1,s0,-176
    80005d2e:	4501                	li	a0,0
    80005d30:	ffffd097          	auipc	ra,0xffffd
    80005d34:	0f6080e7          	jalr	246(ra) # 80002e26 <argstr>
    80005d38:	87aa                	mv	a5,a0
    return -1;
    80005d3a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d3c:	0c07c263          	bltz	a5,80005e00 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005d40:	10000613          	li	a2,256
    80005d44:	4581                	li	a1,0
    80005d46:	e5040513          	addi	a0,s0,-432
    80005d4a:	ffffb097          	auipc	ra,0xffffb
    80005d4e:	f84080e7          	jalr	-124(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d52:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005d56:	89a6                	mv	s3,s1
    80005d58:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d5a:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d5e:	00391513          	slli	a0,s2,0x3
    80005d62:	e4040593          	addi	a1,s0,-448
    80005d66:	e4843783          	ld	a5,-440(s0)
    80005d6a:	953e                	add	a0,a0,a5
    80005d6c:	ffffd097          	auipc	ra,0xffffd
    80005d70:	fdc080e7          	jalr	-36(ra) # 80002d48 <fetchaddr>
    80005d74:	02054a63          	bltz	a0,80005da8 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005d78:	e4043783          	ld	a5,-448(s0)
    80005d7c:	c3b9                	beqz	a5,80005dc2 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d7e:	ffffb097          	auipc	ra,0xffffb
    80005d82:	d64080e7          	jalr	-668(ra) # 80000ae2 <kalloc>
    80005d86:	85aa                	mv	a1,a0
    80005d88:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d8c:	cd11                	beqz	a0,80005da8 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d8e:	6605                	lui	a2,0x1
    80005d90:	e4043503          	ld	a0,-448(s0)
    80005d94:	ffffd097          	auipc	ra,0xffffd
    80005d98:	006080e7          	jalr	6(ra) # 80002d9a <fetchstr>
    80005d9c:	00054663          	bltz	a0,80005da8 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005da0:	0905                	addi	s2,s2,1
    80005da2:	09a1                	addi	s3,s3,8
    80005da4:	fb491de3          	bne	s2,s4,80005d5e <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005da8:	f5040913          	addi	s2,s0,-176
    80005dac:	6088                	ld	a0,0(s1)
    80005dae:	c921                	beqz	a0,80005dfe <sys_exec+0xf6>
    kfree(argv[i]);
    80005db0:	ffffb097          	auipc	ra,0xffffb
    80005db4:	c34080e7          	jalr	-972(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005db8:	04a1                	addi	s1,s1,8
    80005dba:	ff2499e3          	bne	s1,s2,80005dac <sys_exec+0xa4>
  return -1;
    80005dbe:	557d                	li	a0,-1
    80005dc0:	a081                	j	80005e00 <sys_exec+0xf8>
      argv[i] = 0;
    80005dc2:	0009079b          	sext.w	a5,s2
    80005dc6:	078e                	slli	a5,a5,0x3
    80005dc8:	fd078793          	addi	a5,a5,-48
    80005dcc:	97a2                	add	a5,a5,s0
    80005dce:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005dd2:	e5040593          	addi	a1,s0,-432
    80005dd6:	f5040513          	addi	a0,s0,-176
    80005dda:	fffff097          	auipc	ra,0xfffff
    80005dde:	186080e7          	jalr	390(ra) # 80004f60 <exec>
    80005de2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005de4:	f5040993          	addi	s3,s0,-176
    80005de8:	6088                	ld	a0,0(s1)
    80005dea:	c901                	beqz	a0,80005dfa <sys_exec+0xf2>
    kfree(argv[i]);
    80005dec:	ffffb097          	auipc	ra,0xffffb
    80005df0:	bf8080e7          	jalr	-1032(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005df4:	04a1                	addi	s1,s1,8
    80005df6:	ff3499e3          	bne	s1,s3,80005de8 <sys_exec+0xe0>
  return ret;
    80005dfa:	854a                	mv	a0,s2
    80005dfc:	a011                	j	80005e00 <sys_exec+0xf8>
  return -1;
    80005dfe:	557d                	li	a0,-1
}
    80005e00:	70fa                	ld	ra,440(sp)
    80005e02:	745a                	ld	s0,432(sp)
    80005e04:	74ba                	ld	s1,424(sp)
    80005e06:	791a                	ld	s2,416(sp)
    80005e08:	69fa                	ld	s3,408(sp)
    80005e0a:	6a5a                	ld	s4,400(sp)
    80005e0c:	6139                	addi	sp,sp,448
    80005e0e:	8082                	ret

0000000080005e10 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e10:	7139                	addi	sp,sp,-64
    80005e12:	fc06                	sd	ra,56(sp)
    80005e14:	f822                	sd	s0,48(sp)
    80005e16:	f426                	sd	s1,40(sp)
    80005e18:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e1a:	ffffc097          	auipc	ra,0xffffc
    80005e1e:	b8c080e7          	jalr	-1140(ra) # 800019a6 <myproc>
    80005e22:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005e24:	fd840593          	addi	a1,s0,-40
    80005e28:	4501                	li	a0,0
    80005e2a:	ffffd097          	auipc	ra,0xffffd
    80005e2e:	fdc080e7          	jalr	-36(ra) # 80002e06 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005e32:	fc840593          	addi	a1,s0,-56
    80005e36:	fd040513          	addi	a0,s0,-48
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	ddc080e7          	jalr	-548(ra) # 80004c16 <pipealloc>
    return -1;
    80005e42:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e44:	0c054463          	bltz	a0,80005f0c <sys_pipe+0xfc>
  fd0 = -1;
    80005e48:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e4c:	fd043503          	ld	a0,-48(s0)
    80005e50:	fffff097          	auipc	ra,0xfffff
    80005e54:	516080e7          	jalr	1302(ra) # 80005366 <fdalloc>
    80005e58:	fca42223          	sw	a0,-60(s0)
    80005e5c:	08054b63          	bltz	a0,80005ef2 <sys_pipe+0xe2>
    80005e60:	fc843503          	ld	a0,-56(s0)
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	502080e7          	jalr	1282(ra) # 80005366 <fdalloc>
    80005e6c:	fca42023          	sw	a0,-64(s0)
    80005e70:	06054863          	bltz	a0,80005ee0 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e74:	4691                	li	a3,4
    80005e76:	fc440613          	addi	a2,s0,-60
    80005e7a:	fd843583          	ld	a1,-40(s0)
    80005e7e:	68a8                	ld	a0,80(s1)
    80005e80:	ffffb097          	auipc	ra,0xffffb
    80005e84:	7e6080e7          	jalr	2022(ra) # 80001666 <copyout>
    80005e88:	02054063          	bltz	a0,80005ea8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e8c:	4691                	li	a3,4
    80005e8e:	fc040613          	addi	a2,s0,-64
    80005e92:	fd843583          	ld	a1,-40(s0)
    80005e96:	0591                	addi	a1,a1,4
    80005e98:	68a8                	ld	a0,80(s1)
    80005e9a:	ffffb097          	auipc	ra,0xffffb
    80005e9e:	7cc080e7          	jalr	1996(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ea2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ea4:	06055463          	bgez	a0,80005f0c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ea8:	fc442783          	lw	a5,-60(s0)
    80005eac:	07e9                	addi	a5,a5,26
    80005eae:	078e                	slli	a5,a5,0x3
    80005eb0:	97a6                	add	a5,a5,s1
    80005eb2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005eb6:	fc042783          	lw	a5,-64(s0)
    80005eba:	07e9                	addi	a5,a5,26
    80005ebc:	078e                	slli	a5,a5,0x3
    80005ebe:	94be                	add	s1,s1,a5
    80005ec0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ec4:	fd043503          	ld	a0,-48(s0)
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	a22080e7          	jalr	-1502(ra) # 800048ea <fileclose>
    fileclose(wf);
    80005ed0:	fc843503          	ld	a0,-56(s0)
    80005ed4:	fffff097          	auipc	ra,0xfffff
    80005ed8:	a16080e7          	jalr	-1514(ra) # 800048ea <fileclose>
    return -1;
    80005edc:	57fd                	li	a5,-1
    80005ede:	a03d                	j	80005f0c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ee0:	fc442783          	lw	a5,-60(s0)
    80005ee4:	0007c763          	bltz	a5,80005ef2 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ee8:	07e9                	addi	a5,a5,26
    80005eea:	078e                	slli	a5,a5,0x3
    80005eec:	97a6                	add	a5,a5,s1
    80005eee:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005ef2:	fd043503          	ld	a0,-48(s0)
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	9f4080e7          	jalr	-1548(ra) # 800048ea <fileclose>
    fileclose(wf);
    80005efe:	fc843503          	ld	a0,-56(s0)
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	9e8080e7          	jalr	-1560(ra) # 800048ea <fileclose>
    return -1;
    80005f0a:	57fd                	li	a5,-1
}
    80005f0c:	853e                	mv	a0,a5
    80005f0e:	70e2                	ld	ra,56(sp)
    80005f10:	7442                	ld	s0,48(sp)
    80005f12:	74a2                	ld	s1,40(sp)
    80005f14:	6121                	addi	sp,sp,64
    80005f16:	8082                	ret
	...

0000000080005f20 <kernelvec>:
    80005f20:	7111                	addi	sp,sp,-256
    80005f22:	e006                	sd	ra,0(sp)
    80005f24:	e40a                	sd	sp,8(sp)
    80005f26:	e80e                	sd	gp,16(sp)
    80005f28:	ec12                	sd	tp,24(sp)
    80005f2a:	f016                	sd	t0,32(sp)
    80005f2c:	f41a                	sd	t1,40(sp)
    80005f2e:	f81e                	sd	t2,48(sp)
    80005f30:	fc22                	sd	s0,56(sp)
    80005f32:	e0a6                	sd	s1,64(sp)
    80005f34:	e4aa                	sd	a0,72(sp)
    80005f36:	e8ae                	sd	a1,80(sp)
    80005f38:	ecb2                	sd	a2,88(sp)
    80005f3a:	f0b6                	sd	a3,96(sp)
    80005f3c:	f4ba                	sd	a4,104(sp)
    80005f3e:	f8be                	sd	a5,112(sp)
    80005f40:	fcc2                	sd	a6,120(sp)
    80005f42:	e146                	sd	a7,128(sp)
    80005f44:	e54a                	sd	s2,136(sp)
    80005f46:	e94e                	sd	s3,144(sp)
    80005f48:	ed52                	sd	s4,152(sp)
    80005f4a:	f156                	sd	s5,160(sp)
    80005f4c:	f55a                	sd	s6,168(sp)
    80005f4e:	f95e                	sd	s7,176(sp)
    80005f50:	fd62                	sd	s8,184(sp)
    80005f52:	e1e6                	sd	s9,192(sp)
    80005f54:	e5ea                	sd	s10,200(sp)
    80005f56:	e9ee                	sd	s11,208(sp)
    80005f58:	edf2                	sd	t3,216(sp)
    80005f5a:	f1f6                	sd	t4,224(sp)
    80005f5c:	f5fa                	sd	t5,232(sp)
    80005f5e:	f9fe                	sd	t6,240(sp)
    80005f60:	ca1fc0ef          	jal	ra,80002c00 <kerneltrap>
    80005f64:	6082                	ld	ra,0(sp)
    80005f66:	6122                	ld	sp,8(sp)
    80005f68:	61c2                	ld	gp,16(sp)
    80005f6a:	7282                	ld	t0,32(sp)
    80005f6c:	7322                	ld	t1,40(sp)
    80005f6e:	73c2                	ld	t2,48(sp)
    80005f70:	7462                	ld	s0,56(sp)
    80005f72:	6486                	ld	s1,64(sp)
    80005f74:	6526                	ld	a0,72(sp)
    80005f76:	65c6                	ld	a1,80(sp)
    80005f78:	6666                	ld	a2,88(sp)
    80005f7a:	7686                	ld	a3,96(sp)
    80005f7c:	7726                	ld	a4,104(sp)
    80005f7e:	77c6                	ld	a5,112(sp)
    80005f80:	7866                	ld	a6,120(sp)
    80005f82:	688a                	ld	a7,128(sp)
    80005f84:	692a                	ld	s2,136(sp)
    80005f86:	69ca                	ld	s3,144(sp)
    80005f88:	6a6a                	ld	s4,152(sp)
    80005f8a:	7a8a                	ld	s5,160(sp)
    80005f8c:	7b2a                	ld	s6,168(sp)
    80005f8e:	7bca                	ld	s7,176(sp)
    80005f90:	7c6a                	ld	s8,184(sp)
    80005f92:	6c8e                	ld	s9,192(sp)
    80005f94:	6d2e                	ld	s10,200(sp)
    80005f96:	6dce                	ld	s11,208(sp)
    80005f98:	6e6e                	ld	t3,216(sp)
    80005f9a:	7e8e                	ld	t4,224(sp)
    80005f9c:	7f2e                	ld	t5,232(sp)
    80005f9e:	7fce                	ld	t6,240(sp)
    80005fa0:	6111                	addi	sp,sp,256
    80005fa2:	10200073          	sret
    80005fa6:	00000013          	nop
    80005faa:	00000013          	nop
    80005fae:	0001                	nop

0000000080005fb0 <timervec>:
    80005fb0:	34051573          	csrrw	a0,mscratch,a0
    80005fb4:	e10c                	sd	a1,0(a0)
    80005fb6:	e510                	sd	a2,8(a0)
    80005fb8:	e914                	sd	a3,16(a0)
    80005fba:	6d0c                	ld	a1,24(a0)
    80005fbc:	7110                	ld	a2,32(a0)
    80005fbe:	6194                	ld	a3,0(a1)
    80005fc0:	96b2                	add	a3,a3,a2
    80005fc2:	e194                	sd	a3,0(a1)
    80005fc4:	4589                	li	a1,2
    80005fc6:	14459073          	csrw	sip,a1
    80005fca:	6914                	ld	a3,16(a0)
    80005fcc:	6510                	ld	a2,8(a0)
    80005fce:	610c                	ld	a1,0(a0)
    80005fd0:	34051573          	csrrw	a0,mscratch,a0
    80005fd4:	30200073          	mret
	...

0000000080005fda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fda:	1141                	addi	sp,sp,-16
    80005fdc:	e422                	sd	s0,8(sp)
    80005fde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fe0:	0c0007b7          	lui	a5,0xc000
    80005fe4:	4705                	li	a4,1
    80005fe6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fe8:	c3d8                	sw	a4,4(a5)
}
    80005fea:	6422                	ld	s0,8(sp)
    80005fec:	0141                	addi	sp,sp,16
    80005fee:	8082                	ret

0000000080005ff0 <plicinithart>:

void
plicinithart(void)
{
    80005ff0:	1141                	addi	sp,sp,-16
    80005ff2:	e406                	sd	ra,8(sp)
    80005ff4:	e022                	sd	s0,0(sp)
    80005ff6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ff8:	ffffc097          	auipc	ra,0xffffc
    80005ffc:	982080e7          	jalr	-1662(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006000:	0085171b          	slliw	a4,a0,0x8
    80006004:	0c0027b7          	lui	a5,0xc002
    80006008:	97ba                	add	a5,a5,a4
    8000600a:	40200713          	li	a4,1026
    8000600e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006012:	00d5151b          	slliw	a0,a0,0xd
    80006016:	0c2017b7          	lui	a5,0xc201
    8000601a:	97aa                	add	a5,a5,a0
    8000601c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006020:	60a2                	ld	ra,8(sp)
    80006022:	6402                	ld	s0,0(sp)
    80006024:	0141                	addi	sp,sp,16
    80006026:	8082                	ret

0000000080006028 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006028:	1141                	addi	sp,sp,-16
    8000602a:	e406                	sd	ra,8(sp)
    8000602c:	e022                	sd	s0,0(sp)
    8000602e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006030:	ffffc097          	auipc	ra,0xffffc
    80006034:	94a080e7          	jalr	-1718(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006038:	00d5151b          	slliw	a0,a0,0xd
    8000603c:	0c2017b7          	lui	a5,0xc201
    80006040:	97aa                	add	a5,a5,a0
  return irq;
}
    80006042:	43c8                	lw	a0,4(a5)
    80006044:	60a2                	ld	ra,8(sp)
    80006046:	6402                	ld	s0,0(sp)
    80006048:	0141                	addi	sp,sp,16
    8000604a:	8082                	ret

000000008000604c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000604c:	1101                	addi	sp,sp,-32
    8000604e:	ec06                	sd	ra,24(sp)
    80006050:	e822                	sd	s0,16(sp)
    80006052:	e426                	sd	s1,8(sp)
    80006054:	1000                	addi	s0,sp,32
    80006056:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006058:	ffffc097          	auipc	ra,0xffffc
    8000605c:	922080e7          	jalr	-1758(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006060:	00d5151b          	slliw	a0,a0,0xd
    80006064:	0c2017b7          	lui	a5,0xc201
    80006068:	97aa                	add	a5,a5,a0
    8000606a:	c3c4                	sw	s1,4(a5)
}
    8000606c:	60e2                	ld	ra,24(sp)
    8000606e:	6442                	ld	s0,16(sp)
    80006070:	64a2                	ld	s1,8(sp)
    80006072:	6105                	addi	sp,sp,32
    80006074:	8082                	ret

0000000080006076 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006076:	1141                	addi	sp,sp,-16
    80006078:	e406                	sd	ra,8(sp)
    8000607a:	e022                	sd	s0,0(sp)
    8000607c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000607e:	479d                	li	a5,7
    80006080:	04a7cc63          	blt	a5,a0,800060d8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006084:	0001c797          	auipc	a5,0x1c
    80006088:	5bc78793          	addi	a5,a5,1468 # 80022640 <disk>
    8000608c:	97aa                	add	a5,a5,a0
    8000608e:	0187c783          	lbu	a5,24(a5)
    80006092:	ebb9                	bnez	a5,800060e8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006094:	00451693          	slli	a3,a0,0x4
    80006098:	0001c797          	auipc	a5,0x1c
    8000609c:	5a878793          	addi	a5,a5,1448 # 80022640 <disk>
    800060a0:	6398                	ld	a4,0(a5)
    800060a2:	9736                	add	a4,a4,a3
    800060a4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800060a8:	6398                	ld	a4,0(a5)
    800060aa:	9736                	add	a4,a4,a3
    800060ac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800060b0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800060b4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800060b8:	97aa                	add	a5,a5,a0
    800060ba:	4705                	li	a4,1
    800060bc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800060c0:	0001c517          	auipc	a0,0x1c
    800060c4:	59850513          	addi	a0,a0,1432 # 80022658 <disk+0x18>
    800060c8:	ffffc097          	auipc	ra,0xffffc
    800060cc:	0da080e7          	jalr	218(ra) # 800021a2 <wakeup>
}
    800060d0:	60a2                	ld	ra,8(sp)
    800060d2:	6402                	ld	s0,0(sp)
    800060d4:	0141                	addi	sp,sp,16
    800060d6:	8082                	ret
    panic("free_desc 1");
    800060d8:	00002517          	auipc	a0,0x2
    800060dc:	68850513          	addi	a0,a0,1672 # 80008760 <syscalls+0x310>
    800060e0:	ffffa097          	auipc	ra,0xffffa
    800060e4:	45c080e7          	jalr	1116(ra) # 8000053c <panic>
    panic("free_desc 2");
    800060e8:	00002517          	auipc	a0,0x2
    800060ec:	68850513          	addi	a0,a0,1672 # 80008770 <syscalls+0x320>
    800060f0:	ffffa097          	auipc	ra,0xffffa
    800060f4:	44c080e7          	jalr	1100(ra) # 8000053c <panic>

00000000800060f8 <virtio_disk_init>:
{
    800060f8:	1101                	addi	sp,sp,-32
    800060fa:	ec06                	sd	ra,24(sp)
    800060fc:	e822                	sd	s0,16(sp)
    800060fe:	e426                	sd	s1,8(sp)
    80006100:	e04a                	sd	s2,0(sp)
    80006102:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006104:	00002597          	auipc	a1,0x2
    80006108:	67c58593          	addi	a1,a1,1660 # 80008780 <syscalls+0x330>
    8000610c:	0001c517          	auipc	a0,0x1c
    80006110:	65c50513          	addi	a0,a0,1628 # 80022768 <disk+0x128>
    80006114:	ffffb097          	auipc	ra,0xffffb
    80006118:	a2e080e7          	jalr	-1490(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000611c:	100017b7          	lui	a5,0x10001
    80006120:	4398                	lw	a4,0(a5)
    80006122:	2701                	sext.w	a4,a4
    80006124:	747277b7          	lui	a5,0x74727
    80006128:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000612c:	14f71b63          	bne	a4,a5,80006282 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006130:	100017b7          	lui	a5,0x10001
    80006134:	43dc                	lw	a5,4(a5)
    80006136:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006138:	4709                	li	a4,2
    8000613a:	14e79463          	bne	a5,a4,80006282 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000613e:	100017b7          	lui	a5,0x10001
    80006142:	479c                	lw	a5,8(a5)
    80006144:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006146:	12e79e63          	bne	a5,a4,80006282 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000614a:	100017b7          	lui	a5,0x10001
    8000614e:	47d8                	lw	a4,12(a5)
    80006150:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006152:	554d47b7          	lui	a5,0x554d4
    80006156:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000615a:	12f71463          	bne	a4,a5,80006282 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000615e:	100017b7          	lui	a5,0x10001
    80006162:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006166:	4705                	li	a4,1
    80006168:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000616a:	470d                	li	a4,3
    8000616c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000616e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006170:	c7ffe6b7          	lui	a3,0xc7ffe
    80006174:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbfdf>
    80006178:	8f75                	and	a4,a4,a3
    8000617a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000617c:	472d                	li	a4,11
    8000617e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006180:	5bbc                	lw	a5,112(a5)
    80006182:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006186:	8ba1                	andi	a5,a5,8
    80006188:	10078563          	beqz	a5,80006292 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000618c:	100017b7          	lui	a5,0x10001
    80006190:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006194:	43fc                	lw	a5,68(a5)
    80006196:	2781                	sext.w	a5,a5
    80006198:	10079563          	bnez	a5,800062a2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000619c:	100017b7          	lui	a5,0x10001
    800061a0:	5bdc                	lw	a5,52(a5)
    800061a2:	2781                	sext.w	a5,a5
  if(max == 0)
    800061a4:	10078763          	beqz	a5,800062b2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800061a8:	471d                	li	a4,7
    800061aa:	10f77c63          	bgeu	a4,a5,800062c2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800061ae:	ffffb097          	auipc	ra,0xffffb
    800061b2:	934080e7          	jalr	-1740(ra) # 80000ae2 <kalloc>
    800061b6:	0001c497          	auipc	s1,0x1c
    800061ba:	48a48493          	addi	s1,s1,1162 # 80022640 <disk>
    800061be:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	922080e7          	jalr	-1758(ra) # 80000ae2 <kalloc>
    800061c8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	918080e7          	jalr	-1768(ra) # 80000ae2 <kalloc>
    800061d2:	87aa                	mv	a5,a0
    800061d4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800061d6:	6088                	ld	a0,0(s1)
    800061d8:	cd6d                	beqz	a0,800062d2 <virtio_disk_init+0x1da>
    800061da:	0001c717          	auipc	a4,0x1c
    800061de:	46e73703          	ld	a4,1134(a4) # 80022648 <disk+0x8>
    800061e2:	cb65                	beqz	a4,800062d2 <virtio_disk_init+0x1da>
    800061e4:	c7fd                	beqz	a5,800062d2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800061e6:	6605                	lui	a2,0x1
    800061e8:	4581                	li	a1,0
    800061ea:	ffffb097          	auipc	ra,0xffffb
    800061ee:	ae4080e7          	jalr	-1308(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    800061f2:	0001c497          	auipc	s1,0x1c
    800061f6:	44e48493          	addi	s1,s1,1102 # 80022640 <disk>
    800061fa:	6605                	lui	a2,0x1
    800061fc:	4581                	li	a1,0
    800061fe:	6488                	ld	a0,8(s1)
    80006200:	ffffb097          	auipc	ra,0xffffb
    80006204:	ace080e7          	jalr	-1330(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006208:	6605                	lui	a2,0x1
    8000620a:	4581                	li	a1,0
    8000620c:	6888                	ld	a0,16(s1)
    8000620e:	ffffb097          	auipc	ra,0xffffb
    80006212:	ac0080e7          	jalr	-1344(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006216:	100017b7          	lui	a5,0x10001
    8000621a:	4721                	li	a4,8
    8000621c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000621e:	4098                	lw	a4,0(s1)
    80006220:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006224:	40d8                	lw	a4,4(s1)
    80006226:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000622a:	6498                	ld	a4,8(s1)
    8000622c:	0007069b          	sext.w	a3,a4
    80006230:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006234:	9701                	srai	a4,a4,0x20
    80006236:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000623a:	6898                	ld	a4,16(s1)
    8000623c:	0007069b          	sext.w	a3,a4
    80006240:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006244:	9701                	srai	a4,a4,0x20
    80006246:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000624a:	4705                	li	a4,1
    8000624c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000624e:	00e48c23          	sb	a4,24(s1)
    80006252:	00e48ca3          	sb	a4,25(s1)
    80006256:	00e48d23          	sb	a4,26(s1)
    8000625a:	00e48da3          	sb	a4,27(s1)
    8000625e:	00e48e23          	sb	a4,28(s1)
    80006262:	00e48ea3          	sb	a4,29(s1)
    80006266:	00e48f23          	sb	a4,30(s1)
    8000626a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000626e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006272:	0727a823          	sw	s2,112(a5)
}
    80006276:	60e2                	ld	ra,24(sp)
    80006278:	6442                	ld	s0,16(sp)
    8000627a:	64a2                	ld	s1,8(sp)
    8000627c:	6902                	ld	s2,0(sp)
    8000627e:	6105                	addi	sp,sp,32
    80006280:	8082                	ret
    panic("could not find virtio disk");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	50e50513          	addi	a0,a0,1294 # 80008790 <syscalls+0x340>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b2080e7          	jalr	690(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	51e50513          	addi	a0,a0,1310 # 800087b0 <syscalls+0x360>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a2080e7          	jalr	674(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800062a2:	00002517          	auipc	a0,0x2
    800062a6:	52e50513          	addi	a0,a0,1326 # 800087d0 <syscalls+0x380>
    800062aa:	ffffa097          	auipc	ra,0xffffa
    800062ae:	292080e7          	jalr	658(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800062b2:	00002517          	auipc	a0,0x2
    800062b6:	53e50513          	addi	a0,a0,1342 # 800087f0 <syscalls+0x3a0>
    800062ba:	ffffa097          	auipc	ra,0xffffa
    800062be:	282080e7          	jalr	642(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	54e50513          	addi	a0,a0,1358 # 80008810 <syscalls+0x3c0>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	272080e7          	jalr	626(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800062d2:	00002517          	auipc	a0,0x2
    800062d6:	55e50513          	addi	a0,a0,1374 # 80008830 <syscalls+0x3e0>
    800062da:	ffffa097          	auipc	ra,0xffffa
    800062de:	262080e7          	jalr	610(ra) # 8000053c <panic>

00000000800062e2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062e2:	7159                	addi	sp,sp,-112
    800062e4:	f486                	sd	ra,104(sp)
    800062e6:	f0a2                	sd	s0,96(sp)
    800062e8:	eca6                	sd	s1,88(sp)
    800062ea:	e8ca                	sd	s2,80(sp)
    800062ec:	e4ce                	sd	s3,72(sp)
    800062ee:	e0d2                	sd	s4,64(sp)
    800062f0:	fc56                	sd	s5,56(sp)
    800062f2:	f85a                	sd	s6,48(sp)
    800062f4:	f45e                	sd	s7,40(sp)
    800062f6:	f062                	sd	s8,32(sp)
    800062f8:	ec66                	sd	s9,24(sp)
    800062fa:	e86a                	sd	s10,16(sp)
    800062fc:	1880                	addi	s0,sp,112
    800062fe:	8a2a                	mv	s4,a0
    80006300:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006302:	00c52c83          	lw	s9,12(a0)
    80006306:	001c9c9b          	slliw	s9,s9,0x1
    8000630a:	1c82                	slli	s9,s9,0x20
    8000630c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006310:	0001c517          	auipc	a0,0x1c
    80006314:	45850513          	addi	a0,a0,1112 # 80022768 <disk+0x128>
    80006318:	ffffb097          	auipc	ra,0xffffb
    8000631c:	8ba080e7          	jalr	-1862(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006320:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006322:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006324:	0001cb17          	auipc	s6,0x1c
    80006328:	31cb0b13          	addi	s6,s6,796 # 80022640 <disk>
  for(int i = 0; i < 3; i++){
    8000632c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000632e:	0001cc17          	auipc	s8,0x1c
    80006332:	43ac0c13          	addi	s8,s8,1082 # 80022768 <disk+0x128>
    80006336:	a095                	j	8000639a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006338:	00fb0733          	add	a4,s6,a5
    8000633c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006340:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006342:	0207c563          	bltz	a5,8000636c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006346:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006348:	0591                	addi	a1,a1,4
    8000634a:	05560d63          	beq	a2,s5,800063a4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000634e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006350:	0001c717          	auipc	a4,0x1c
    80006354:	2f070713          	addi	a4,a4,752 # 80022640 <disk>
    80006358:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000635a:	01874683          	lbu	a3,24(a4)
    8000635e:	fee9                	bnez	a3,80006338 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006360:	2785                	addiw	a5,a5,1
    80006362:	0705                	addi	a4,a4,1
    80006364:	fe979be3          	bne	a5,s1,8000635a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006368:	57fd                	li	a5,-1
    8000636a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000636c:	00c05e63          	blez	a2,80006388 <virtio_disk_rw+0xa6>
    80006370:	060a                	slli	a2,a2,0x2
    80006372:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006376:	0009a503          	lw	a0,0(s3)
    8000637a:	00000097          	auipc	ra,0x0
    8000637e:	cfc080e7          	jalr	-772(ra) # 80006076 <free_desc>
      for(int j = 0; j < i; j++)
    80006382:	0991                	addi	s3,s3,4
    80006384:	ffa999e3          	bne	s3,s10,80006376 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006388:	85e2                	mv	a1,s8
    8000638a:	0001c517          	auipc	a0,0x1c
    8000638e:	2ce50513          	addi	a0,a0,718 # 80022658 <disk+0x18>
    80006392:	ffffc097          	auipc	ra,0xffffc
    80006396:	dac080e7          	jalr	-596(ra) # 8000213e <sleep>
  for(int i = 0; i < 3; i++){
    8000639a:	f9040993          	addi	s3,s0,-112
{
    8000639e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800063a0:	864a                	mv	a2,s2
    800063a2:	b775                	j	8000634e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063a4:	f9042503          	lw	a0,-112(s0)
    800063a8:	00a50713          	addi	a4,a0,10
    800063ac:	0712                	slli	a4,a4,0x4

  if(write)
    800063ae:	0001c797          	auipc	a5,0x1c
    800063b2:	29278793          	addi	a5,a5,658 # 80022640 <disk>
    800063b6:	00e786b3          	add	a3,a5,a4
    800063ba:	01703633          	snez	a2,s7
    800063be:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063c0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800063c4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063c8:	f6070613          	addi	a2,a4,-160
    800063cc:	6394                	ld	a3,0(a5)
    800063ce:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063d0:	00870593          	addi	a1,a4,8
    800063d4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063d6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063d8:	0007b803          	ld	a6,0(a5)
    800063dc:	9642                	add	a2,a2,a6
    800063de:	46c1                	li	a3,16
    800063e0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063e2:	4585                	li	a1,1
    800063e4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800063e8:	f9442683          	lw	a3,-108(s0)
    800063ec:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063f0:	0692                	slli	a3,a3,0x4
    800063f2:	9836                	add	a6,a6,a3
    800063f4:	058a0613          	addi	a2,s4,88
    800063f8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800063fc:	0007b803          	ld	a6,0(a5)
    80006400:	96c2                	add	a3,a3,a6
    80006402:	40000613          	li	a2,1024
    80006406:	c690                	sw	a2,8(a3)
  if(write)
    80006408:	001bb613          	seqz	a2,s7
    8000640c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006410:	00166613          	ori	a2,a2,1
    80006414:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006418:	f9842603          	lw	a2,-104(s0)
    8000641c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006420:	00250693          	addi	a3,a0,2
    80006424:	0692                	slli	a3,a3,0x4
    80006426:	96be                	add	a3,a3,a5
    80006428:	58fd                	li	a7,-1
    8000642a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000642e:	0612                	slli	a2,a2,0x4
    80006430:	9832                	add	a6,a6,a2
    80006432:	f9070713          	addi	a4,a4,-112
    80006436:	973e                	add	a4,a4,a5
    80006438:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000643c:	6398                	ld	a4,0(a5)
    8000643e:	9732                	add	a4,a4,a2
    80006440:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006442:	4609                	li	a2,2
    80006444:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006448:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000644c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006450:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006454:	6794                	ld	a3,8(a5)
    80006456:	0026d703          	lhu	a4,2(a3)
    8000645a:	8b1d                	andi	a4,a4,7
    8000645c:	0706                	slli	a4,a4,0x1
    8000645e:	96ba                	add	a3,a3,a4
    80006460:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006464:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006468:	6798                	ld	a4,8(a5)
    8000646a:	00275783          	lhu	a5,2(a4)
    8000646e:	2785                	addiw	a5,a5,1
    80006470:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006474:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006478:	100017b7          	lui	a5,0x10001
    8000647c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006480:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006484:	0001c917          	auipc	s2,0x1c
    80006488:	2e490913          	addi	s2,s2,740 # 80022768 <disk+0x128>
  while(b->disk == 1) {
    8000648c:	4485                	li	s1,1
    8000648e:	00b79c63          	bne	a5,a1,800064a6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006492:	85ca                	mv	a1,s2
    80006494:	8552                	mv	a0,s4
    80006496:	ffffc097          	auipc	ra,0xffffc
    8000649a:	ca8080e7          	jalr	-856(ra) # 8000213e <sleep>
  while(b->disk == 1) {
    8000649e:	004a2783          	lw	a5,4(s4)
    800064a2:	fe9788e3          	beq	a5,s1,80006492 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800064a6:	f9042903          	lw	s2,-112(s0)
    800064aa:	00290713          	addi	a4,s2,2
    800064ae:	0712                	slli	a4,a4,0x4
    800064b0:	0001c797          	auipc	a5,0x1c
    800064b4:	19078793          	addi	a5,a5,400 # 80022640 <disk>
    800064b8:	97ba                	add	a5,a5,a4
    800064ba:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800064be:	0001c997          	auipc	s3,0x1c
    800064c2:	18298993          	addi	s3,s3,386 # 80022640 <disk>
    800064c6:	00491713          	slli	a4,s2,0x4
    800064ca:	0009b783          	ld	a5,0(s3)
    800064ce:	97ba                	add	a5,a5,a4
    800064d0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064d4:	854a                	mv	a0,s2
    800064d6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064da:	00000097          	auipc	ra,0x0
    800064de:	b9c080e7          	jalr	-1124(ra) # 80006076 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064e2:	8885                	andi	s1,s1,1
    800064e4:	f0ed                	bnez	s1,800064c6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064e6:	0001c517          	auipc	a0,0x1c
    800064ea:	28250513          	addi	a0,a0,642 # 80022768 <disk+0x128>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	798080e7          	jalr	1944(ra) # 80000c86 <release>
}
    800064f6:	70a6                	ld	ra,104(sp)
    800064f8:	7406                	ld	s0,96(sp)
    800064fa:	64e6                	ld	s1,88(sp)
    800064fc:	6946                	ld	s2,80(sp)
    800064fe:	69a6                	ld	s3,72(sp)
    80006500:	6a06                	ld	s4,64(sp)
    80006502:	7ae2                	ld	s5,56(sp)
    80006504:	7b42                	ld	s6,48(sp)
    80006506:	7ba2                	ld	s7,40(sp)
    80006508:	7c02                	ld	s8,32(sp)
    8000650a:	6ce2                	ld	s9,24(sp)
    8000650c:	6d42                	ld	s10,16(sp)
    8000650e:	6165                	addi	sp,sp,112
    80006510:	8082                	ret

0000000080006512 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006512:	1101                	addi	sp,sp,-32
    80006514:	ec06                	sd	ra,24(sp)
    80006516:	e822                	sd	s0,16(sp)
    80006518:	e426                	sd	s1,8(sp)
    8000651a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000651c:	0001c497          	auipc	s1,0x1c
    80006520:	12448493          	addi	s1,s1,292 # 80022640 <disk>
    80006524:	0001c517          	auipc	a0,0x1c
    80006528:	24450513          	addi	a0,a0,580 # 80022768 <disk+0x128>
    8000652c:	ffffa097          	auipc	ra,0xffffa
    80006530:	6a6080e7          	jalr	1702(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006534:	10001737          	lui	a4,0x10001
    80006538:	533c                	lw	a5,96(a4)
    8000653a:	8b8d                	andi	a5,a5,3
    8000653c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000653e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006542:	689c                	ld	a5,16(s1)
    80006544:	0204d703          	lhu	a4,32(s1)
    80006548:	0027d783          	lhu	a5,2(a5)
    8000654c:	04f70863          	beq	a4,a5,8000659c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006550:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006554:	6898                	ld	a4,16(s1)
    80006556:	0204d783          	lhu	a5,32(s1)
    8000655a:	8b9d                	andi	a5,a5,7
    8000655c:	078e                	slli	a5,a5,0x3
    8000655e:	97ba                	add	a5,a5,a4
    80006560:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006562:	00278713          	addi	a4,a5,2
    80006566:	0712                	slli	a4,a4,0x4
    80006568:	9726                	add	a4,a4,s1
    8000656a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000656e:	e721                	bnez	a4,800065b6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006570:	0789                	addi	a5,a5,2
    80006572:	0792                	slli	a5,a5,0x4
    80006574:	97a6                	add	a5,a5,s1
    80006576:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006578:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000657c:	ffffc097          	auipc	ra,0xffffc
    80006580:	c26080e7          	jalr	-986(ra) # 800021a2 <wakeup>

    disk.used_idx += 1;
    80006584:	0204d783          	lhu	a5,32(s1)
    80006588:	2785                	addiw	a5,a5,1
    8000658a:	17c2                	slli	a5,a5,0x30
    8000658c:	93c1                	srli	a5,a5,0x30
    8000658e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006592:	6898                	ld	a4,16(s1)
    80006594:	00275703          	lhu	a4,2(a4)
    80006598:	faf71ce3          	bne	a4,a5,80006550 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000659c:	0001c517          	auipc	a0,0x1c
    800065a0:	1cc50513          	addi	a0,a0,460 # 80022768 <disk+0x128>
    800065a4:	ffffa097          	auipc	ra,0xffffa
    800065a8:	6e2080e7          	jalr	1762(ra) # 80000c86 <release>
}
    800065ac:	60e2                	ld	ra,24(sp)
    800065ae:	6442                	ld	s0,16(sp)
    800065b0:	64a2                	ld	s1,8(sp)
    800065b2:	6105                	addi	sp,sp,32
    800065b4:	8082                	ret
      panic("virtio_disk_intr status");
    800065b6:	00002517          	auipc	a0,0x2
    800065ba:	29250513          	addi	a0,a0,658 # 80008848 <syscalls+0x3f8>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	f7e080e7          	jalr	-130(ra) # 8000053c <panic>
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
