
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8d013103          	ld	sp,-1840(sp) # 800088d0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	8e070713          	addi	a4,a4,-1824 # 80008930 <timer_scratch>
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
    80000066:	f6e78793          	addi	a5,a5,-146 # 80005fd0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc05f>
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
    8000012e:	496080e7          	jalr	1174(ra) # 800025c0 <either_copyin>
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
    80000188:	8ec50513          	addi	a0,a0,-1812 # 80010a70 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8dc48493          	addi	s1,s1,-1828 # 80010a70 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	96c90913          	addi	s2,s2,-1684 # 80010b08 <cons+0x98>
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
    800001c0:	24e080e7          	jalr	590(ra) # 8000240a <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	f8c080e7          	jalr	-116(ra) # 80002156 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	89270713          	addi	a4,a4,-1902 # 80010a70 <cons>
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
    80000214:	35a080e7          	jalr	858(ra) # 8000256a <either_copyout>
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
    8000022c:	84850513          	addi	a0,a0,-1976 # 80010a70 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	83250513          	addi	a0,a0,-1998 # 80010a70 <cons>
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
    80000272:	88f72d23          	sw	a5,-1894(a4) # 80010b08 <cons+0x98>
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
    800002cc:	7a850513          	addi	a0,a0,1960 # 80010a70 <cons>
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
    800002f2:	328080e7          	jalr	808(ra) # 80002616 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	77a50513          	addi	a0,a0,1914 # 80010a70 <cons>
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
    8000031e:	75670713          	addi	a4,a4,1878 # 80010a70 <cons>
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
    80000348:	72c78793          	addi	a5,a5,1836 # 80010a70 <cons>
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
    80000376:	7967a783          	lw	a5,1942(a5) # 80010b08 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6ea70713          	addi	a4,a4,1770 # 80010a70 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6da48493          	addi	s1,s1,1754 # 80010a70 <cons>
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
    800003d6:	69e70713          	addi	a4,a4,1694 # 80010a70 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	72f72423          	sw	a5,1832(a4) # 80010b10 <cons+0xa0>
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
    80000412:	66278793          	addi	a5,a5,1634 # 80010a70 <cons>
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
    80000436:	6cc7ad23          	sw	a2,1754(a5) # 80010b0c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	6ce50513          	addi	a0,a0,1742 # 80010b08 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	d78080e7          	jalr	-648(ra) # 800021ba <wakeup>
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
    80000460:	61450513          	addi	a0,a0,1556 # 80010a70 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00021797          	auipc	a5,0x21
    80000478:	19478793          	addi	a5,a5,404 # 80021608 <devsw>
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
    8000054c:	5e07a423          	sw	zero,1512(a5) # 80010b30 <pr+0x18>
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
    80000580:	36f72a23          	sw	a5,884(a4) # 800088f0 <panicked>
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
    800005bc:	578dad83          	lw	s11,1400(s11) # 80010b30 <pr+0x18>
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
    800005fa:	52250513          	addi	a0,a0,1314 # 80010b18 <pr>
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
    80000758:	3c450513          	addi	a0,a0,964 # 80010b18 <pr>
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
    80000774:	3a848493          	addi	s1,s1,936 # 80010b18 <pr>
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
    800007d4:	36850513          	addi	a0,a0,872 # 80010b38 <uart_tx_lock>
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
    80000800:	0f47a783          	lw	a5,244(a5) # 800088f0 <panicked>
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
    80000838:	0c47b783          	ld	a5,196(a5) # 800088f8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0c473703          	ld	a4,196(a4) # 80008900 <uart_tx_w>
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
    80000862:	2daa0a13          	addi	s4,s4,730 # 80010b38 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	09248493          	addi	s1,s1,146 # 800088f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	09298993          	addi	s3,s3,146 # 80008900 <uart_tx_w>
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
    80000894:	92a080e7          	jalr	-1750(ra) # 800021ba <wakeup>
    
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
    800008d0:	26c50513          	addi	a0,a0,620 # 80010b38 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0147a783          	lw	a5,20(a5) # 800088f0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	01a73703          	ld	a4,26(a4) # 80008900 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	00a7b783          	ld	a5,10(a5) # 800088f8 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	23e98993          	addi	s3,s3,574 # 80010b38 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	ff648493          	addi	s1,s1,-10 # 800088f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	ff690913          	addi	s2,s2,-10 # 80008900 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	83c080e7          	jalr	-1988(ra) # 80002156 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	20848493          	addi	s1,s1,520 # 80010b38 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	fae7be23          	sd	a4,-68(a5) # 80008900 <uart_tx_w>
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
    800009ba:	18248493          	addi	s1,s1,386 # 80010b38 <uart_tx_lock>
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
    800009fc:	da878793          	addi	a5,a5,-600 # 800227a0 <end>
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
    80000a1c:	15890913          	addi	s2,s2,344 # 80010b70 <kmem>
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
    80000aba:	0ba50513          	addi	a0,a0,186 # 80010b70 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00022517          	auipc	a0,0x22
    80000ace:	cd650513          	addi	a0,a0,-810 # 800227a0 <end>
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
    80000af0:	08448493          	addi	s1,s1,132 # 80010b70 <kmem>
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
    80000b08:	06c50513          	addi	a0,a0,108 # 80010b70 <kmem>
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
    80000b34:	04050513          	addi	a0,a0,64 # 80010b70 <kmem>
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
    80000d42:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc861>
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
    80000e86:	a8670713          	addi	a4,a4,-1402 # 80008908 <started>
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
    80000ebc:	a4a080e7          	jalr	-1462(ra) # 80002902 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	150080e7          	jalr	336(ra) # 80006010 <plicinithart>
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
    80000f34:	9aa080e7          	jalr	-1622(ra) # 800028da <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	9ca080e7          	jalr	-1590(ra) # 80002902 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	0ba080e7          	jalr	186(ra) # 80005ffa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	0c8080e7          	jalr	200(ra) # 80006010 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	2b2080e7          	jalr	690(ra) # 80003202 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	950080e7          	jalr	-1712(ra) # 800038a8 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	8c6080e7          	jalr	-1850(ra) # 80004826 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	1b0080e7          	jalr	432(ra) # 80006118 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	db8080e7          	jalr	-584(ra) # 80001d28 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	98f72523          	sw	a5,-1654(a4) # 80008908 <started>
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
    80000f96:	97e7b783          	ld	a5,-1666(a5) # 80008910 <kernel_pagetable>
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
    80001010:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc857>
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
    80001252:	6ca7b123          	sd	a0,1730(a5) # 80008910 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc860>
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
    8000184a:	77a48493          	addi	s1,s1,1914 # 80010fc0 <proc>
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
    80001864:	b60a0a13          	addi	s4,s4,-1184 # 800173c0 <tickslock>
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
    800018e6:	2ae50513          	addi	a0,a0,686 # 80010b90 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
	initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	addi	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	2ae50513          	addi	a0,a0,686 # 80010ba8 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
	for(p = proc; p < &proc[NPROC]; p++)
    8000190a:	0000f497          	auipc	s1,0xf
    8000190e:	6b648493          	addi	s1,s1,1718 # 80010fc0 <proc>
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
    80001930:	a9498993          	addi	s3,s3,-1388 # 800173c0 <tickslock>
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
    8000199a:	22a50513          	addi	a0,a0,554 # 80010bc0 <cpus>
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
    800019c2:	1d270713          	addi	a4,a4,466 # 80010b90 <pid_lock>
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
    800019fa:	e8a7a783          	lw	a5,-374(a5) # 80008880 <first.1>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
		// be run from main().
		first = 0;
		fsinit(ROOTDEV);
	}

	usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	f1a080e7          	jalr	-230(ra) # 8000291a <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	addi	sp,sp,16
    80001a0e:	8082                	ret
		first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	e607a823          	sw	zero,-400(a5) # 80008880 <first.1>
		fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	e0e080e7          	jalr	-498(ra) # 80003828 <fsinit>
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
    80001a34:	16090913          	addi	s2,s2,352 # 80010b90 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
	pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	e4278793          	addi	a5,a5,-446 # 80008884 <nextpid>
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
    80001a7c:	38e080e7          	jalr	910(ra) # 80002e06 <argint>
	argaddr(1, &handler);
    80001a80:	fe040593          	addi	a1,s0,-32
    80001a84:	4505                	li	a0,1
    80001a86:	00001097          	auipc	ra,0x1
    80001a8a:	3a0080e7          	jalr	928(ra) # 80002e26 <argaddr>
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
    80001c28:	39c48493          	addi	s1,s1,924 # 80010fc0 <proc>
    80001c2c:	00015917          	auipc	s2,0x15
    80001c30:	79490913          	addi	s2,s2,1940 # 800173c0 <tickslock>
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
    80001cc4:	c607a783          	lw	a5,-928(a5) # 80008920 <ticks>
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
    80001d40:	bca7be23          	sd	a0,-1060(a5) # 80008918 <initproc>
	uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d44:	03400613          	li	a2,52
    80001d48:	00007597          	auipc	a1,0x7
    80001d4c:	b4858593          	addi	a1,a1,-1208 # 80008890 <initcode>
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
    80001d8a:	4c0080e7          	jalr	1216(ra) # 80004246 <namei>
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
    80001eba:	a02080e7          	jalr	-1534(ra) # 800048b8 <filedup>
    80001ebe:	00a93023          	sd	a0,0(s2)
    80001ec2:	b7e5                	j	80001eaa <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001ec4:	150ab503          	ld	a0,336(s5)
    80001ec8:	00002097          	auipc	ra,0x2
    80001ecc:	b9a080e7          	jalr	-1126(ra) # 80003a62 <idup>
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
    80001ef8:	cb448493          	addi	s1,s1,-844 # 80010ba8 <wait_lock>
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
    80001f46:	711d                	addi	sp,sp,-96
    80001f48:	ec86                	sd	ra,88(sp)
    80001f4a:	e8a2                	sd	s0,80(sp)
    80001f4c:	e4a6                	sd	s1,72(sp)
    80001f4e:	e0ca                	sd	s2,64(sp)
    80001f50:	fc4e                	sd	s3,56(sp)
    80001f52:	f852                	sd	s4,48(sp)
    80001f54:	f456                	sd	s5,40(sp)
    80001f56:	f05a                	sd	s6,32(sp)
    80001f58:	ec5e                	sd	s7,24(sp)
    80001f5a:	e862                	sd	s8,16(sp)
    80001f5c:	e466                	sd	s9,8(sp)
    80001f5e:	1080                	addi	s0,sp,96
    80001f60:	8792                	mv	a5,tp
	int id = r_tp();
    80001f62:	2781                	sext.w	a5,a5
	c->proc = 0;
    80001f64:	00779693          	slli	a3,a5,0x7
    80001f68:	0000f717          	auipc	a4,0xf
    80001f6c:	c2870713          	addi	a4,a4,-984 # 80010b90 <pid_lock>
    80001f70:	9736                	add	a4,a4,a3
    80001f72:	02073823          	sd	zero,48(a4)
				swtch(&c->context, &min_p->context);
    80001f76:	0000f717          	auipc	a4,0xf
    80001f7a:	c5270713          	addi	a4,a4,-942 # 80010bc8 <cpus+0x8>
    80001f7e:	00e68cb3          	add	s9,a3,a4
		int min_ctime = 0x7fffffff;
    80001f82:	80000b37          	lui	s6,0x80000
    80001f86:	fffb4b13          	not	s6,s6
			if(p->state == RUNNABLE && p->ctime < min_ctime)
    80001f8a:	490d                	li	s2,3
		for(p = proc; p < &proc[NPROC]; p++)
    80001f8c:	00015997          	auipc	s3,0x15
    80001f90:	43498993          	addi	s3,s3,1076 # 800173c0 <tickslock>
				c->proc = min_p;
    80001f94:	0000fc17          	auipc	s8,0xf
    80001f98:	bfcc0c13          	addi	s8,s8,-1028 # 80010b90 <pid_lock>
    80001f9c:	9c36                	add	s8,s8,a3
    80001f9e:	a04d                	j	80002040 <scheduler+0xfa>
			release(&p->lock);
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	ce4080e7          	jalr	-796(ra) # 80000c86 <release>
		for(p = proc; p < &proc[NPROC]; p++)
    80001faa:	19048493          	addi	s1,s1,400
    80001fae:	03348e63          	beq	s1,s3,80001fea <scheduler+0xa4>
			acquire(&p->lock);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	c1e080e7          	jalr	-994(ra) # 80000bd2 <acquire>
			if(p->state == RUNNABLE && p->ctime < min_ctime)
    80001fbc:	4c9c                	lw	a5,24(s1)
    80001fbe:	ff2791e3          	bne	a5,s2,80001fa0 <scheduler+0x5a>
    80001fc2:	16c4a783          	lw	a5,364(s1)
    80001fc6:	000a071b          	sext.w	a4,s4
    80001fca:	fce7fbe3          	bgeu	a5,a4,80001fa0 <scheduler+0x5a>
				min_ctime = p->ctime;
    80001fce:	00078a1b          	sext.w	s4,a5
			release(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	cb2080e7          	jalr	-846(ra) # 80000c86 <release>
		for(p = proc; p < &proc[NPROC]; p++)
    80001fdc:	19048793          	addi	a5,s1,400
    80001fe0:	03378563          	beq	a5,s3,8000200a <scheduler+0xc4>
    80001fe4:	8aa6                	mv	s5,s1
    80001fe6:	84be                	mv	s1,a5
    80001fe8:	b7e9                	j	80001fb2 <scheduler+0x6c>
		if(min_p != 0)
    80001fea:	000a9f63          	bnez	s5,80002008 <scheduler+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ff2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff6:	10079073          	csrw	sstatus,a5
		int min_ctime = 0x7fffffff;
    80001ffa:	8a5a                	mv	s4,s6
		struct proc* min_p = 0;
    80001ffc:	8ade                	mv	s5,s7
		for(p = proc; p < &proc[NPROC]; p++)
    80001ffe:	0000f497          	auipc	s1,0xf
    80002002:	fc248493          	addi	s1,s1,-62 # 80010fc0 <proc>
    80002006:	b775                	j	80001fb2 <scheduler+0x6c>
    80002008:	84d6                	mv	s1,s5
			acquire(&min_p->lock);
    8000200a:	8a26                	mv	s4,s1
    8000200c:	8526                	mv	a0,s1
    8000200e:	fffff097          	auipc	ra,0xfffff
    80002012:	bc4080e7          	jalr	-1084(ra) # 80000bd2 <acquire>
			if(min_p->state == RUNNABLE)
    80002016:	4c9c                	lw	a5,24(s1)
    80002018:	01279f63          	bne	a5,s2,80002036 <scheduler+0xf0>
				min_p->state = RUNNING;
    8000201c:	4791                	li	a5,4
    8000201e:	cc9c                	sw	a5,24(s1)
				c->proc = min_p;
    80002020:	029c3823          	sd	s1,48(s8)
				swtch(&c->context, &min_p->context);
    80002024:	06048593          	addi	a1,s1,96
    80002028:	8566                	mv	a0,s9
    8000202a:	00001097          	auipc	ra,0x1
    8000202e:	846080e7          	jalr	-1978(ra) # 80002870 <swtch>
				c->proc = 0;
    80002032:	020c3823          	sd	zero,48(s8)
			release(&min_p->lock);
    80002036:	8552                	mv	a0,s4
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	c4e080e7          	jalr	-946(ra) # 80000c86 <release>
		struct proc* min_p = 0;
    80002040:	4b81                	li	s7,0
    80002042:	b775                	j	80001fee <scheduler+0xa8>

0000000080002044 <sched>:
{
    80002044:	7179                	addi	sp,sp,-48
    80002046:	f406                	sd	ra,40(sp)
    80002048:	f022                	sd	s0,32(sp)
    8000204a:	ec26                	sd	s1,24(sp)
    8000204c:	e84a                	sd	s2,16(sp)
    8000204e:	e44e                	sd	s3,8(sp)
    80002050:	1800                	addi	s0,sp,48
	struct proc* p = myproc();
    80002052:	00000097          	auipc	ra,0x0
    80002056:	954080e7          	jalr	-1708(ra) # 800019a6 <myproc>
    8000205a:	84aa                	mv	s1,a0
	if(!holding(&p->lock))
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	afc080e7          	jalr	-1284(ra) # 80000b58 <holding>
    80002064:	c93d                	beqz	a0,800020da <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002066:	8792                	mv	a5,tp
	if(mycpu()->noff != 1)
    80002068:	2781                	sext.w	a5,a5
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	0000f717          	auipc	a4,0xf
    80002070:	b2470713          	addi	a4,a4,-1244 # 80010b90 <pid_lock>
    80002074:	97ba                	add	a5,a5,a4
    80002076:	0a87a703          	lw	a4,168(a5)
    8000207a:	4785                	li	a5,1
    8000207c:	06f71763          	bne	a4,a5,800020ea <sched+0xa6>
	if(p->state == RUNNING)
    80002080:	4c98                	lw	a4,24(s1)
    80002082:	4791                	li	a5,4
    80002084:	06f70b63          	beq	a4,a5,800020fa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002088:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000208c:	8b89                	andi	a5,a5,2
	if(intr_get())
    8000208e:	efb5                	bnez	a5,8000210a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002090:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    80002092:	0000f917          	auipc	s2,0xf
    80002096:	afe90913          	addi	s2,s2,-1282 # 80010b90 <pid_lock>
    8000209a:	2781                	sext.w	a5,a5
    8000209c:	079e                	slli	a5,a5,0x7
    8000209e:	97ca                	add	a5,a5,s2
    800020a0:	0ac7a983          	lw	s3,172(a5)
    800020a4:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    800020a6:	2781                	sext.w	a5,a5
    800020a8:	079e                	slli	a5,a5,0x7
    800020aa:	0000f597          	auipc	a1,0xf
    800020ae:	b1e58593          	addi	a1,a1,-1250 # 80010bc8 <cpus+0x8>
    800020b2:	95be                	add	a1,a1,a5
    800020b4:	06048513          	addi	a0,s1,96
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	7b8080e7          	jalr	1976(ra) # 80002870 <swtch>
    800020c0:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    800020c2:	2781                	sext.w	a5,a5
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	993e                	add	s2,s2,a5
    800020c8:	0b392623          	sw	s3,172(s2)
}
    800020cc:	70a2                	ld	ra,40(sp)
    800020ce:	7402                	ld	s0,32(sp)
    800020d0:	64e2                	ld	s1,24(sp)
    800020d2:	6942                	ld	s2,16(sp)
    800020d4:	69a2                	ld	s3,8(sp)
    800020d6:	6145                	addi	sp,sp,48
    800020d8:	8082                	ret
		panic("sched p->lock");
    800020da:	00006517          	auipc	a0,0x6
    800020de:	13e50513          	addi	a0,a0,318 # 80008218 <digits+0x1d8>
    800020e2:	ffffe097          	auipc	ra,0xffffe
    800020e6:	45a080e7          	jalr	1114(ra) # 8000053c <panic>
		panic("sched locks");
    800020ea:	00006517          	auipc	a0,0x6
    800020ee:	13e50513          	addi	a0,a0,318 # 80008228 <digits+0x1e8>
    800020f2:	ffffe097          	auipc	ra,0xffffe
    800020f6:	44a080e7          	jalr	1098(ra) # 8000053c <panic>
		panic("sched running");
    800020fa:	00006517          	auipc	a0,0x6
    800020fe:	13e50513          	addi	a0,a0,318 # 80008238 <digits+0x1f8>
    80002102:	ffffe097          	auipc	ra,0xffffe
    80002106:	43a080e7          	jalr	1082(ra) # 8000053c <panic>
		panic("sched interruptible");
    8000210a:	00006517          	auipc	a0,0x6
    8000210e:	13e50513          	addi	a0,a0,318 # 80008248 <digits+0x208>
    80002112:	ffffe097          	auipc	ra,0xffffe
    80002116:	42a080e7          	jalr	1066(ra) # 8000053c <panic>

000000008000211a <yield>:
{
    8000211a:	1101                	addi	sp,sp,-32
    8000211c:	ec06                	sd	ra,24(sp)
    8000211e:	e822                	sd	s0,16(sp)
    80002120:	e426                	sd	s1,8(sp)
    80002122:	1000                	addi	s0,sp,32
	struct proc* p = myproc();
    80002124:	00000097          	auipc	ra,0x0
    80002128:	882080e7          	jalr	-1918(ra) # 800019a6 <myproc>
    8000212c:	84aa                	mv	s1,a0
	acquire(&p->lock);
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	aa4080e7          	jalr	-1372(ra) # 80000bd2 <acquire>
	p->state = RUNNABLE;
    80002136:	478d                	li	a5,3
    80002138:	cc9c                	sw	a5,24(s1)
	sched();
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	f0a080e7          	jalr	-246(ra) # 80002044 <sched>
	release(&p->lock);
    80002142:	8526                	mv	a0,s1
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	b42080e7          	jalr	-1214(ra) # 80000c86 <release>
}
    8000214c:	60e2                	ld	ra,24(sp)
    8000214e:	6442                	ld	s0,16(sp)
    80002150:	64a2                	ld	s1,8(sp)
    80002152:	6105                	addi	sp,sp,32
    80002154:	8082                	ret

0000000080002156 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void* chan, struct spinlock* lk)
{
    80002156:	7179                	addi	sp,sp,-48
    80002158:	f406                	sd	ra,40(sp)
    8000215a:	f022                	sd	s0,32(sp)
    8000215c:	ec26                	sd	s1,24(sp)
    8000215e:	e84a                	sd	s2,16(sp)
    80002160:	e44e                	sd	s3,8(sp)
    80002162:	1800                	addi	s0,sp,48
    80002164:	89aa                	mv	s3,a0
    80002166:	892e                	mv	s2,a1
	struct proc* p = myproc();
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	83e080e7          	jalr	-1986(ra) # 800019a6 <myproc>
    80002170:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); // DOC: sleeplock1
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	a60080e7          	jalr	-1440(ra) # 80000bd2 <acquire>
	release(lk);
    8000217a:	854a                	mv	a0,s2
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	b0a080e7          	jalr	-1270(ra) # 80000c86 <release>

	// Go to sleep.
	p->chan = chan;
    80002184:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    80002188:	4789                	li	a5,2
    8000218a:	cc9c                	sw	a5,24(s1)

	sched();
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	eb8080e7          	jalr	-328(ra) # 80002044 <sched>

	// Tidy up.
	p->chan = 0;
    80002194:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	aec080e7          	jalr	-1300(ra) # 80000c86 <release>
	acquire(lk);
    800021a2:	854a                	mv	a0,s2
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	a2e080e7          	jalr	-1490(ra) # 80000bd2 <acquire>
}
    800021ac:	70a2                	ld	ra,40(sp)
    800021ae:	7402                	ld	s0,32(sp)
    800021b0:	64e2                	ld	s1,24(sp)
    800021b2:	6942                	ld	s2,16(sp)
    800021b4:	69a2                	ld	s3,8(sp)
    800021b6:	6145                	addi	sp,sp,48
    800021b8:	8082                	ret

00000000800021ba <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void* chan)
{
    800021ba:	7139                	addi	sp,sp,-64
    800021bc:	fc06                	sd	ra,56(sp)
    800021be:	f822                	sd	s0,48(sp)
    800021c0:	f426                	sd	s1,40(sp)
    800021c2:	f04a                	sd	s2,32(sp)
    800021c4:	ec4e                	sd	s3,24(sp)
    800021c6:	e852                	sd	s4,16(sp)
    800021c8:	e456                	sd	s5,8(sp)
    800021ca:	0080                	addi	s0,sp,64
    800021cc:	8a2a                	mv	s4,a0
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    800021ce:	0000f497          	auipc	s1,0xf
    800021d2:	df248493          	addi	s1,s1,-526 # 80010fc0 <proc>
	{
		if(p != myproc())
		{
			acquire(&p->lock);
			if(p->state == SLEEPING && p->chan == chan)
    800021d6:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    800021d8:	4a8d                	li	s5,3
	for(p = proc; p < &proc[NPROC]; p++)
    800021da:	00015917          	auipc	s2,0x15
    800021de:	1e690913          	addi	s2,s2,486 # 800173c0 <tickslock>
    800021e2:	a811                	j	800021f6 <wakeup+0x3c>
			}
			release(&p->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	aa0080e7          	jalr	-1376(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    800021ee:	19048493          	addi	s1,s1,400
    800021f2:	03248663          	beq	s1,s2,8000221e <wakeup+0x64>
		if(p != myproc())
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	7b0080e7          	jalr	1968(ra) # 800019a6 <myproc>
    800021fe:	fea488e3          	beq	s1,a0,800021ee <wakeup+0x34>
			acquire(&p->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	9ce080e7          	jalr	-1586(ra) # 80000bd2 <acquire>
			if(p->state == SLEEPING && p->chan == chan)
    8000220c:	4c9c                	lw	a5,24(s1)
    8000220e:	fd379be3          	bne	a5,s3,800021e4 <wakeup+0x2a>
    80002212:	709c                	ld	a5,32(s1)
    80002214:	fd4798e3          	bne	a5,s4,800021e4 <wakeup+0x2a>
				p->state = RUNNABLE;
    80002218:	0154ac23          	sw	s5,24(s1)
    8000221c:	b7e1                	j	800021e4 <wakeup+0x2a>
		}
	}
}
    8000221e:	70e2                	ld	ra,56(sp)
    80002220:	7442                	ld	s0,48(sp)
    80002222:	74a2                	ld	s1,40(sp)
    80002224:	7902                	ld	s2,32(sp)
    80002226:	69e2                	ld	s3,24(sp)
    80002228:	6a42                	ld	s4,16(sp)
    8000222a:	6aa2                	ld	s5,8(sp)
    8000222c:	6121                	addi	sp,sp,64
    8000222e:	8082                	ret

0000000080002230 <reparent>:
{
    80002230:	7179                	addi	sp,sp,-48
    80002232:	f406                	sd	ra,40(sp)
    80002234:	f022                	sd	s0,32(sp)
    80002236:	ec26                	sd	s1,24(sp)
    80002238:	e84a                	sd	s2,16(sp)
    8000223a:	e44e                	sd	s3,8(sp)
    8000223c:	e052                	sd	s4,0(sp)
    8000223e:	1800                	addi	s0,sp,48
    80002240:	892a                	mv	s2,a0
	for(pp = proc; pp < &proc[NPROC]; pp++)
    80002242:	0000f497          	auipc	s1,0xf
    80002246:	d7e48493          	addi	s1,s1,-642 # 80010fc0 <proc>
			pp->parent = initproc;
    8000224a:	00006a17          	auipc	s4,0x6
    8000224e:	6cea0a13          	addi	s4,s4,1742 # 80008918 <initproc>
	for(pp = proc; pp < &proc[NPROC]; pp++)
    80002252:	00015997          	auipc	s3,0x15
    80002256:	16e98993          	addi	s3,s3,366 # 800173c0 <tickslock>
    8000225a:	a029                	j	80002264 <reparent+0x34>
    8000225c:	19048493          	addi	s1,s1,400
    80002260:	01348d63          	beq	s1,s3,8000227a <reparent+0x4a>
		if(pp->parent == p)
    80002264:	7c9c                	ld	a5,56(s1)
    80002266:	ff279be3          	bne	a5,s2,8000225c <reparent+0x2c>
			pp->parent = initproc;
    8000226a:	000a3503          	ld	a0,0(s4)
    8000226e:	fc88                	sd	a0,56(s1)
			wakeup(initproc);
    80002270:	00000097          	auipc	ra,0x0
    80002274:	f4a080e7          	jalr	-182(ra) # 800021ba <wakeup>
    80002278:	b7d5                	j	8000225c <reparent+0x2c>
}
    8000227a:	70a2                	ld	ra,40(sp)
    8000227c:	7402                	ld	s0,32(sp)
    8000227e:	64e2                	ld	s1,24(sp)
    80002280:	6942                	ld	s2,16(sp)
    80002282:	69a2                	ld	s3,8(sp)
    80002284:	6a02                	ld	s4,0(sp)
    80002286:	6145                	addi	sp,sp,48
    80002288:	8082                	ret

000000008000228a <exit>:
{
    8000228a:	7179                	addi	sp,sp,-48
    8000228c:	f406                	sd	ra,40(sp)
    8000228e:	f022                	sd	s0,32(sp)
    80002290:	ec26                	sd	s1,24(sp)
    80002292:	e84a                	sd	s2,16(sp)
    80002294:	e44e                	sd	s3,8(sp)
    80002296:	e052                	sd	s4,0(sp)
    80002298:	1800                	addi	s0,sp,48
    8000229a:	8a2a                	mv	s4,a0
	struct proc* p = myproc();
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	70a080e7          	jalr	1802(ra) # 800019a6 <myproc>
    800022a4:	89aa                	mv	s3,a0
	if(p == initproc)
    800022a6:	00006797          	auipc	a5,0x6
    800022aa:	6727b783          	ld	a5,1650(a5) # 80008918 <initproc>
    800022ae:	0d050493          	addi	s1,a0,208
    800022b2:	15050913          	addi	s2,a0,336
    800022b6:	02a79363          	bne	a5,a0,800022dc <exit+0x52>
		panic("init exiting");
    800022ba:	00006517          	auipc	a0,0x6
    800022be:	fa650513          	addi	a0,a0,-90 # 80008260 <digits+0x220>
    800022c2:	ffffe097          	auipc	ra,0xffffe
    800022c6:	27a080e7          	jalr	634(ra) # 8000053c <panic>
			fileclose(f);
    800022ca:	00002097          	auipc	ra,0x2
    800022ce:	640080e7          	jalr	1600(ra) # 8000490a <fileclose>
			p->ofile[fd] = 0;
    800022d2:	0004b023          	sd	zero,0(s1)
	for(int fd = 0; fd < NOFILE; fd++)
    800022d6:	04a1                	addi	s1,s1,8
    800022d8:	01248563          	beq	s1,s2,800022e2 <exit+0x58>
		if(p->ofile[fd])
    800022dc:	6088                	ld	a0,0(s1)
    800022de:	f575                	bnez	a0,800022ca <exit+0x40>
    800022e0:	bfdd                	j	800022d6 <exit+0x4c>
	begin_op();
    800022e2:	00002097          	auipc	ra,0x2
    800022e6:	164080e7          	jalr	356(ra) # 80004446 <begin_op>
	iput(p->cwd);
    800022ea:	1509b503          	ld	a0,336(s3)
    800022ee:	00002097          	auipc	ra,0x2
    800022f2:	96c080e7          	jalr	-1684(ra) # 80003c5a <iput>
	end_op();
    800022f6:	00002097          	auipc	ra,0x2
    800022fa:	1ca080e7          	jalr	458(ra) # 800044c0 <end_op>
	p->cwd = 0;
    800022fe:	1409b823          	sd	zero,336(s3)
	acquire(&wait_lock);
    80002302:	0000f497          	auipc	s1,0xf
    80002306:	8a648493          	addi	s1,s1,-1882 # 80010ba8 <wait_lock>
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	8c6080e7          	jalr	-1850(ra) # 80000bd2 <acquire>
	reparent(p);
    80002314:	854e                	mv	a0,s3
    80002316:	00000097          	auipc	ra,0x0
    8000231a:	f1a080e7          	jalr	-230(ra) # 80002230 <reparent>
	wakeup(p->parent);
    8000231e:	0389b503          	ld	a0,56(s3)
    80002322:	00000097          	auipc	ra,0x0
    80002326:	e98080e7          	jalr	-360(ra) # 800021ba <wakeup>
	acquire(&p->lock);
    8000232a:	854e                	mv	a0,s3
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	8a6080e7          	jalr	-1882(ra) # 80000bd2 <acquire>
	p->xstate = status;
    80002334:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    80002338:	4795                	li	a5,5
    8000233a:	00f9ac23          	sw	a5,24(s3)
	p->etime = ticks;
    8000233e:	00006797          	auipc	a5,0x6
    80002342:	5e27a783          	lw	a5,1506(a5) # 80008920 <ticks>
    80002346:	16f9a823          	sw	a5,368(s3)
	release(&wait_lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	93a080e7          	jalr	-1734(ra) # 80000c86 <release>
	sched();
    80002354:	00000097          	auipc	ra,0x0
    80002358:	cf0080e7          	jalr	-784(ra) # 80002044 <sched>
	panic("zombie exit");
    8000235c:	00006517          	auipc	a0,0x6
    80002360:	f1450513          	addi	a0,a0,-236 # 80008270 <digits+0x230>
    80002364:	ffffe097          	auipc	ra,0xffffe
    80002368:	1d8080e7          	jalr	472(ra) # 8000053c <panic>

000000008000236c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000236c:	7179                	addi	sp,sp,-48
    8000236e:	f406                	sd	ra,40(sp)
    80002370:	f022                	sd	s0,32(sp)
    80002372:	ec26                	sd	s1,24(sp)
    80002374:	e84a                	sd	s2,16(sp)
    80002376:	e44e                	sd	s3,8(sp)
    80002378:	1800                	addi	s0,sp,48
    8000237a:	892a                	mv	s2,a0
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    8000237c:	0000f497          	auipc	s1,0xf
    80002380:	c4448493          	addi	s1,s1,-956 # 80010fc0 <proc>
    80002384:	00015997          	auipc	s3,0x15
    80002388:	03c98993          	addi	s3,s3,60 # 800173c0 <tickslock>
	{
		acquire(&p->lock);
    8000238c:	8526                	mv	a0,s1
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	844080e7          	jalr	-1980(ra) # 80000bd2 <acquire>
		if(p->pid == pid)
    80002396:	589c                	lw	a5,48(s1)
    80002398:	01278d63          	beq	a5,s2,800023b2 <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	8e8080e7          	jalr	-1816(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    800023a6:	19048493          	addi	s1,s1,400
    800023aa:	ff3491e3          	bne	s1,s3,8000238c <kill+0x20>
	}
	return -1;
    800023ae:	557d                	li	a0,-1
    800023b0:	a829                	j	800023ca <kill+0x5e>
			p->killed = 1;
    800023b2:	4785                	li	a5,1
    800023b4:	d49c                	sw	a5,40(s1)
			if(p->state == SLEEPING)
    800023b6:	4c98                	lw	a4,24(s1)
    800023b8:	4789                	li	a5,2
    800023ba:	00f70f63          	beq	a4,a5,800023d8 <kill+0x6c>
			release(&p->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8c6080e7          	jalr	-1850(ra) # 80000c86 <release>
			return 0;
    800023c8:	4501                	li	a0,0
}
    800023ca:	70a2                	ld	ra,40(sp)
    800023cc:	7402                	ld	s0,32(sp)
    800023ce:	64e2                	ld	s1,24(sp)
    800023d0:	6942                	ld	s2,16(sp)
    800023d2:	69a2                	ld	s3,8(sp)
    800023d4:	6145                	addi	sp,sp,48
    800023d6:	8082                	ret
				p->state = RUNNABLE;
    800023d8:	478d                	li	a5,3
    800023da:	cc9c                	sw	a5,24(s1)
    800023dc:	b7cd                	j	800023be <kill+0x52>

00000000800023de <setkilled>:

void setkilled(struct proc* p)
{
    800023de:	1101                	addi	sp,sp,-32
    800023e0:	ec06                	sd	ra,24(sp)
    800023e2:	e822                	sd	s0,16(sp)
    800023e4:	e426                	sd	s1,8(sp)
    800023e6:	1000                	addi	s0,sp,32
    800023e8:	84aa                	mv	s1,a0
	acquire(&p->lock);
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	7e8080e7          	jalr	2024(ra) # 80000bd2 <acquire>
	p->killed = 1;
    800023f2:	4785                	li	a5,1
    800023f4:	d49c                	sw	a5,40(s1)
	release(&p->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	88e080e7          	jalr	-1906(ra) # 80000c86 <release>
}
    80002400:	60e2                	ld	ra,24(sp)
    80002402:	6442                	ld	s0,16(sp)
    80002404:	64a2                	ld	s1,8(sp)
    80002406:	6105                	addi	sp,sp,32
    80002408:	8082                	ret

000000008000240a <killed>:

int killed(struct proc* p)
{
    8000240a:	1101                	addi	sp,sp,-32
    8000240c:	ec06                	sd	ra,24(sp)
    8000240e:	e822                	sd	s0,16(sp)
    80002410:	e426                	sd	s1,8(sp)
    80002412:	e04a                	sd	s2,0(sp)
    80002414:	1000                	addi	s0,sp,32
    80002416:	84aa                	mv	s1,a0
	int k;

	acquire(&p->lock);
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	7ba080e7          	jalr	1978(ra) # 80000bd2 <acquire>
	k = p->killed;
    80002420:	0284a903          	lw	s2,40(s1)
	release(&p->lock);
    80002424:	8526                	mv	a0,s1
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	860080e7          	jalr	-1952(ra) # 80000c86 <release>
	return k;
}
    8000242e:	854a                	mv	a0,s2
    80002430:	60e2                	ld	ra,24(sp)
    80002432:	6442                	ld	s0,16(sp)
    80002434:	64a2                	ld	s1,8(sp)
    80002436:	6902                	ld	s2,0(sp)
    80002438:	6105                	addi	sp,sp,32
    8000243a:	8082                	ret

000000008000243c <wait>:
{
    8000243c:	715d                	addi	sp,sp,-80
    8000243e:	e486                	sd	ra,72(sp)
    80002440:	e0a2                	sd	s0,64(sp)
    80002442:	fc26                	sd	s1,56(sp)
    80002444:	f84a                	sd	s2,48(sp)
    80002446:	f44e                	sd	s3,40(sp)
    80002448:	f052                	sd	s4,32(sp)
    8000244a:	ec56                	sd	s5,24(sp)
    8000244c:	e85a                	sd	s6,16(sp)
    8000244e:	e45e                	sd	s7,8(sp)
    80002450:	e062                	sd	s8,0(sp)
    80002452:	0880                	addi	s0,sp,80
    80002454:	8b2a                	mv	s6,a0
	struct proc* p = myproc();
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	550080e7          	jalr	1360(ra) # 800019a6 <myproc>
    8000245e:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002460:	0000e517          	auipc	a0,0xe
    80002464:	74850513          	addi	a0,a0,1864 # 80010ba8 <wait_lock>
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	76a080e7          	jalr	1898(ra) # 80000bd2 <acquire>
		havekids = 0;
    80002470:	4b81                	li	s7,0
				if(pp->state == ZOMBIE)
    80002472:	4a15                	li	s4,5
				havekids = 1;
    80002474:	4a85                	li	s5,1
		for(pp = proc; pp < &proc[NPROC]; pp++)
    80002476:	00015997          	auipc	s3,0x15
    8000247a:	f4a98993          	addi	s3,s3,-182 # 800173c0 <tickslock>
		sleep(p, &wait_lock); // DOC: wait-sleep
    8000247e:	0000ec17          	auipc	s8,0xe
    80002482:	72ac0c13          	addi	s8,s8,1834 # 80010ba8 <wait_lock>
    80002486:	a0d1                	j	8000254a <wait+0x10e>
					pid = pp->pid;
    80002488:	0304a983          	lw	s3,48(s1)
					if(addr != 0 &&
    8000248c:	000b0e63          	beqz	s6,800024a8 <wait+0x6c>
					   copyout(p->pagetable, addr, (char*)&pp->xstate, sizeof(pp->xstate)) < 0)
    80002490:	4691                	li	a3,4
    80002492:	02c48613          	addi	a2,s1,44
    80002496:	85da                	mv	a1,s6
    80002498:	05093503          	ld	a0,80(s2)
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	1ca080e7          	jalr	458(ra) # 80001666 <copyout>
					if(addr != 0 &&
    800024a4:	04054163          	bltz	a0,800024e6 <wait+0xaa>
					freeproc(pp);
    800024a8:	8526                	mv	a0,s1
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	714080e7          	jalr	1812(ra) # 80001bbe <freeproc>
					release(&pp->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	7d2080e7          	jalr	2002(ra) # 80000c86 <release>
					release(&wait_lock);
    800024bc:	0000e517          	auipc	a0,0xe
    800024c0:	6ec50513          	addi	a0,a0,1772 # 80010ba8 <wait_lock>
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	7c2080e7          	jalr	1986(ra) # 80000c86 <release>
}
    800024cc:	854e                	mv	a0,s3
    800024ce:	60a6                	ld	ra,72(sp)
    800024d0:	6406                	ld	s0,64(sp)
    800024d2:	74e2                	ld	s1,56(sp)
    800024d4:	7942                	ld	s2,48(sp)
    800024d6:	79a2                	ld	s3,40(sp)
    800024d8:	7a02                	ld	s4,32(sp)
    800024da:	6ae2                	ld	s5,24(sp)
    800024dc:	6b42                	ld	s6,16(sp)
    800024de:	6ba2                	ld	s7,8(sp)
    800024e0:	6c02                	ld	s8,0(sp)
    800024e2:	6161                	addi	sp,sp,80
    800024e4:	8082                	ret
						release(&pp->lock);
    800024e6:	8526                	mv	a0,s1
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	79e080e7          	jalr	1950(ra) # 80000c86 <release>
						release(&wait_lock);
    800024f0:	0000e517          	auipc	a0,0xe
    800024f4:	6b850513          	addi	a0,a0,1720 # 80010ba8 <wait_lock>
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	78e080e7          	jalr	1934(ra) # 80000c86 <release>
						return -1;
    80002500:	59fd                	li	s3,-1
    80002502:	b7e9                	j	800024cc <wait+0x90>
		for(pp = proc; pp < &proc[NPROC]; pp++)
    80002504:	19048493          	addi	s1,s1,400
    80002508:	03348463          	beq	s1,s3,80002530 <wait+0xf4>
			if(pp->parent == p)
    8000250c:	7c9c                	ld	a5,56(s1)
    8000250e:	ff279be3          	bne	a5,s2,80002504 <wait+0xc8>
				acquire(&pp->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	6be080e7          	jalr	1726(ra) # 80000bd2 <acquire>
				if(pp->state == ZOMBIE)
    8000251c:	4c9c                	lw	a5,24(s1)
    8000251e:	f74785e3          	beq	a5,s4,80002488 <wait+0x4c>
				release(&pp->lock);
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	762080e7          	jalr	1890(ra) # 80000c86 <release>
				havekids = 1;
    8000252c:	8756                	mv	a4,s5
    8000252e:	bfd9                	j	80002504 <wait+0xc8>
		if(!havekids || killed(p))
    80002530:	c31d                	beqz	a4,80002556 <wait+0x11a>
    80002532:	854a                	mv	a0,s2
    80002534:	00000097          	auipc	ra,0x0
    80002538:	ed6080e7          	jalr	-298(ra) # 8000240a <killed>
    8000253c:	ed09                	bnez	a0,80002556 <wait+0x11a>
		sleep(p, &wait_lock); // DOC: wait-sleep
    8000253e:	85e2                	mv	a1,s8
    80002540:	854a                	mv	a0,s2
    80002542:	00000097          	auipc	ra,0x0
    80002546:	c14080e7          	jalr	-1004(ra) # 80002156 <sleep>
		havekids = 0;
    8000254a:	875e                	mv	a4,s7
		for(pp = proc; pp < &proc[NPROC]; pp++)
    8000254c:	0000f497          	auipc	s1,0xf
    80002550:	a7448493          	addi	s1,s1,-1420 # 80010fc0 <proc>
    80002554:	bf65                	j	8000250c <wait+0xd0>
			release(&wait_lock);
    80002556:	0000e517          	auipc	a0,0xe
    8000255a:	65250513          	addi	a0,a0,1618 # 80010ba8 <wait_lock>
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	728080e7          	jalr	1832(ra) # 80000c86 <release>
			return -1;
    80002566:	59fd                	li	s3,-1
    80002568:	b795                	j	800024cc <wait+0x90>

000000008000256a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void* src, uint64 len)
{
    8000256a:	7179                	addi	sp,sp,-48
    8000256c:	f406                	sd	ra,40(sp)
    8000256e:	f022                	sd	s0,32(sp)
    80002570:	ec26                	sd	s1,24(sp)
    80002572:	e84a                	sd	s2,16(sp)
    80002574:	e44e                	sd	s3,8(sp)
    80002576:	e052                	sd	s4,0(sp)
    80002578:	1800                	addi	s0,sp,48
    8000257a:	84aa                	mv	s1,a0
    8000257c:	892e                	mv	s2,a1
    8000257e:	89b2                	mv	s3,a2
    80002580:	8a36                	mv	s4,a3
	struct proc* p = myproc();
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	424080e7          	jalr	1060(ra) # 800019a6 <myproc>
	if(user_dst)
    8000258a:	c08d                	beqz	s1,800025ac <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    8000258c:	86d2                	mv	a3,s4
    8000258e:	864e                	mv	a2,s3
    80002590:	85ca                	mv	a1,s2
    80002592:	6928                	ld	a0,80(a0)
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	0d2080e7          	jalr	210(ra) # 80001666 <copyout>
	else
	{
		memmove((char*)dst, src, len);
		return 0;
	}
}
    8000259c:	70a2                	ld	ra,40(sp)
    8000259e:	7402                	ld	s0,32(sp)
    800025a0:	64e2                	ld	s1,24(sp)
    800025a2:	6942                	ld	s2,16(sp)
    800025a4:	69a2                	ld	s3,8(sp)
    800025a6:	6a02                	ld	s4,0(sp)
    800025a8:	6145                	addi	sp,sp,48
    800025aa:	8082                	ret
		memmove((char*)dst, src, len);
    800025ac:	000a061b          	sext.w	a2,s4
    800025b0:	85ce                	mv	a1,s3
    800025b2:	854a                	mv	a0,s2
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	776080e7          	jalr	1910(ra) # 80000d2a <memmove>
		return 0;
    800025bc:	8526                	mv	a0,s1
    800025be:	bff9                	j	8000259c <either_copyout+0x32>

00000000800025c0 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void* dst, int user_src, uint64 src, uint64 len)
{
    800025c0:	7179                	addi	sp,sp,-48
    800025c2:	f406                	sd	ra,40(sp)
    800025c4:	f022                	sd	s0,32(sp)
    800025c6:	ec26                	sd	s1,24(sp)
    800025c8:	e84a                	sd	s2,16(sp)
    800025ca:	e44e                	sd	s3,8(sp)
    800025cc:	e052                	sd	s4,0(sp)
    800025ce:	1800                	addi	s0,sp,48
    800025d0:	892a                	mv	s2,a0
    800025d2:	84ae                	mv	s1,a1
    800025d4:	89b2                	mv	s3,a2
    800025d6:	8a36                	mv	s4,a3
	struct proc* p = myproc();
    800025d8:	fffff097          	auipc	ra,0xfffff
    800025dc:	3ce080e7          	jalr	974(ra) # 800019a6 <myproc>
	if(user_src)
    800025e0:	c08d                	beqz	s1,80002602 <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    800025e2:	86d2                	mv	a3,s4
    800025e4:	864e                	mv	a2,s3
    800025e6:	85ca                	mv	a1,s2
    800025e8:	6928                	ld	a0,80(a0)
    800025ea:	fffff097          	auipc	ra,0xfffff
    800025ee:	108080e7          	jalr	264(ra) # 800016f2 <copyin>
	else
	{
		memmove(dst, (char*)src, len);
		return 0;
	}
}
    800025f2:	70a2                	ld	ra,40(sp)
    800025f4:	7402                	ld	s0,32(sp)
    800025f6:	64e2                	ld	s1,24(sp)
    800025f8:	6942                	ld	s2,16(sp)
    800025fa:	69a2                	ld	s3,8(sp)
    800025fc:	6a02                	ld	s4,0(sp)
    800025fe:	6145                	addi	sp,sp,48
    80002600:	8082                	ret
		memmove(dst, (char*)src, len);
    80002602:	000a061b          	sext.w	a2,s4
    80002606:	85ce                	mv	a1,s3
    80002608:	854a                	mv	a0,s2
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	720080e7          	jalr	1824(ra) # 80000d2a <memmove>
		return 0;
    80002612:	8526                	mv	a0,s1
    80002614:	bff9                	j	800025f2 <either_copyin+0x32>

0000000080002616 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002616:	715d                	addi	sp,sp,-80
    80002618:	e486                	sd	ra,72(sp)
    8000261a:	e0a2                	sd	s0,64(sp)
    8000261c:	fc26                	sd	s1,56(sp)
    8000261e:	f84a                	sd	s2,48(sp)
    80002620:	f44e                	sd	s3,40(sp)
    80002622:	f052                	sd	s4,32(sp)
    80002624:	ec56                	sd	s5,24(sp)
    80002626:	e85a                	sd	s6,16(sp)
    80002628:	e45e                	sd	s7,8(sp)
    8000262a:	0880                	addi	s0,sp,80
							 [RUNNING] "run   ",
							 [ZOMBIE] "zombie"};
	struct proc* p;
	char* state;

	printf("\n");
    8000262c:	00006517          	auipc	a0,0x6
    80002630:	a9c50513          	addi	a0,a0,-1380 # 800080c8 <digits+0x88>
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	f52080e7          	jalr	-174(ra) # 80000586 <printf>
	for(p = proc; p < &proc[NPROC]; p++)
    8000263c:	0000f497          	auipc	s1,0xf
    80002640:	adc48493          	addi	s1,s1,-1316 # 80011118 <proc+0x158>
    80002644:	00015917          	auipc	s2,0x15
    80002648:	ed490913          	addi	s2,s2,-300 # 80017518 <bcache+0x140>
	{
		if(p->state == UNUSED)
			continue;
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000264c:	4b15                	li	s6,5
			state = states[p->state];
		else
			state = "???";
    8000264e:	00006997          	auipc	s3,0x6
    80002652:	c3298993          	addi	s3,s3,-974 # 80008280 <digits+0x240>
		printf("%d %s %s", p->pid, state, p->name);
    80002656:	00006a97          	auipc	s5,0x6
    8000265a:	c32a8a93          	addi	s5,s5,-974 # 80008288 <digits+0x248>
		printf("\n");
    8000265e:	00006a17          	auipc	s4,0x6
    80002662:	a6aa0a13          	addi	s4,s4,-1430 # 800080c8 <digits+0x88>
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002666:	00006b97          	auipc	s7,0x6
    8000266a:	c62b8b93          	addi	s7,s7,-926 # 800082c8 <states.0>
    8000266e:	a00d                	j	80002690 <procdump+0x7a>
		printf("%d %s %s", p->pid, state, p->name);
    80002670:	ed86a583          	lw	a1,-296(a3)
    80002674:	8556                	mv	a0,s5
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	f10080e7          	jalr	-240(ra) # 80000586 <printf>
		printf("\n");
    8000267e:	8552                	mv	a0,s4
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	f06080e7          	jalr	-250(ra) # 80000586 <printf>
	for(p = proc; p < &proc[NPROC]; p++)
    80002688:	19048493          	addi	s1,s1,400
    8000268c:	03248263          	beq	s1,s2,800026b0 <procdump+0x9a>
		if(p->state == UNUSED)
    80002690:	86a6                	mv	a3,s1
    80002692:	ec04a783          	lw	a5,-320(s1)
    80002696:	dbed                	beqz	a5,80002688 <procdump+0x72>
			state = "???";
    80002698:	864e                	mv	a2,s3
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000269a:	fcfb6be3          	bltu	s6,a5,80002670 <procdump+0x5a>
    8000269e:	02079713          	slli	a4,a5,0x20
    800026a2:	01d75793          	srli	a5,a4,0x1d
    800026a6:	97de                	add	a5,a5,s7
    800026a8:	6390                	ld	a2,0(a5)
    800026aa:	f279                	bnez	a2,80002670 <procdump+0x5a>
			state = "???";
    800026ac:	864e                	mv	a2,s3
    800026ae:	b7c9                	j	80002670 <procdump+0x5a>
	}	
}
    800026b0:	60a6                	ld	ra,72(sp)
    800026b2:	6406                	ld	s0,64(sp)
    800026b4:	74e2                	ld	s1,56(sp)
    800026b6:	7942                	ld	s2,48(sp)
    800026b8:	79a2                	ld	s3,40(sp)
    800026ba:	7a02                	ld	s4,32(sp)
    800026bc:	6ae2                	ld	s5,24(sp)
    800026be:	6b42                	ld	s6,16(sp)
    800026c0:	6ba2                	ld	s7,8(sp)
    800026c2:	6161                	addi	sp,sp,80
    800026c4:	8082                	ret

00000000800026c6 <waitx>:

// waitx
int waitx(uint64 addr, uint* wtime, uint* rtime)
{
    800026c6:	711d                	addi	sp,sp,-96
    800026c8:	ec86                	sd	ra,88(sp)
    800026ca:	e8a2                	sd	s0,80(sp)
    800026cc:	e4a6                	sd	s1,72(sp)
    800026ce:	e0ca                	sd	s2,64(sp)
    800026d0:	fc4e                	sd	s3,56(sp)
    800026d2:	f852                	sd	s4,48(sp)
    800026d4:	f456                	sd	s5,40(sp)
    800026d6:	f05a                	sd	s6,32(sp)
    800026d8:	ec5e                	sd	s7,24(sp)
    800026da:	e862                	sd	s8,16(sp)
    800026dc:	e466                	sd	s9,8(sp)
    800026de:	e06a                	sd	s10,0(sp)
    800026e0:	1080                	addi	s0,sp,96
    800026e2:	8b2a                	mv	s6,a0
    800026e4:	8bae                	mv	s7,a1
    800026e6:	8c32                	mv	s8,a2
	struct proc* np;
	int havekids, pid;
	struct proc* p = myproc();
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	2be080e7          	jalr	702(ra) # 800019a6 <myproc>
    800026f0:	892a                	mv	s2,a0

	acquire(&wait_lock);
    800026f2:	0000e517          	auipc	a0,0xe
    800026f6:	4b650513          	addi	a0,a0,1206 # 80010ba8 <wait_lock>
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	4d8080e7          	jalr	1240(ra) # 80000bd2 <acquire>

	for(;;)
	{
		// Scan through table looking for exited children.
		havekids = 0;
    80002702:	4c81                	li	s9,0
			{
				// make sure the child isn't still in exit() or swtch().
				acquire(&np->lock);

				havekids = 1;
				if(np->state == ZOMBIE)
    80002704:	4a15                	li	s4,5
				havekids = 1;
    80002706:	4a85                	li	s5,1
		for(np = proc; np < &proc[NPROC]; np++)
    80002708:	00015997          	auipc	s3,0x15
    8000270c:	cb898993          	addi	s3,s3,-840 # 800173c0 <tickslock>
			release(&wait_lock);
			return -1;
		}

		// Wait for a child to exit.
		sleep(p, &wait_lock); // DOC: wait-sleep
    80002710:	0000ed17          	auipc	s10,0xe
    80002714:	498d0d13          	addi	s10,s10,1176 # 80010ba8 <wait_lock>
    80002718:	a8e9                	j	800027f2 <waitx+0x12c>
					pid = np->pid;
    8000271a:	0304a983          	lw	s3,48(s1)
					*rtime = np->rtime;
    8000271e:	1684a783          	lw	a5,360(s1)
    80002722:	00fc2023          	sw	a5,0(s8)
					*wtime = np->etime - np->ctime - np->rtime;
    80002726:	16c4a703          	lw	a4,364(s1)
    8000272a:	9f3d                	addw	a4,a4,a5
    8000272c:	1704a783          	lw	a5,368(s1)
    80002730:	9f99                	subw	a5,a5,a4
    80002732:	00fba023          	sw	a5,0(s7)
					if(addr != 0 &&
    80002736:	000b0e63          	beqz	s6,80002752 <waitx+0x8c>
					   copyout(p->pagetable, addr, (char*)&np->xstate, sizeof(np->xstate)) < 0)
    8000273a:	4691                	li	a3,4
    8000273c:	02c48613          	addi	a2,s1,44
    80002740:	85da                	mv	a1,s6
    80002742:	05093503          	ld	a0,80(s2)
    80002746:	fffff097          	auipc	ra,0xfffff
    8000274a:	f20080e7          	jalr	-224(ra) # 80001666 <copyout>
					if(addr != 0 &&
    8000274e:	04054363          	bltz	a0,80002794 <waitx+0xce>
					freeproc(np);
    80002752:	8526                	mv	a0,s1
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	46a080e7          	jalr	1130(ra) # 80001bbe <freeproc>
					release(&np->lock);
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	528080e7          	jalr	1320(ra) # 80000c86 <release>
					release(&wait_lock);
    80002766:	0000e517          	auipc	a0,0xe
    8000276a:	44250513          	addi	a0,a0,1090 # 80010ba8 <wait_lock>
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	518080e7          	jalr	1304(ra) # 80000c86 <release>
	}
}
    80002776:	854e                	mv	a0,s3
    80002778:	60e6                	ld	ra,88(sp)
    8000277a:	6446                	ld	s0,80(sp)
    8000277c:	64a6                	ld	s1,72(sp)
    8000277e:	6906                	ld	s2,64(sp)
    80002780:	79e2                	ld	s3,56(sp)
    80002782:	7a42                	ld	s4,48(sp)
    80002784:	7aa2                	ld	s5,40(sp)
    80002786:	7b02                	ld	s6,32(sp)
    80002788:	6be2                	ld	s7,24(sp)
    8000278a:	6c42                	ld	s8,16(sp)
    8000278c:	6ca2                	ld	s9,8(sp)
    8000278e:	6d02                	ld	s10,0(sp)
    80002790:	6125                	addi	sp,sp,96
    80002792:	8082                	ret
						release(&np->lock);
    80002794:	8526                	mv	a0,s1
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	4f0080e7          	jalr	1264(ra) # 80000c86 <release>
						release(&wait_lock);
    8000279e:	0000e517          	auipc	a0,0xe
    800027a2:	40a50513          	addi	a0,a0,1034 # 80010ba8 <wait_lock>
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	4e0080e7          	jalr	1248(ra) # 80000c86 <release>
						return -1;
    800027ae:	59fd                	li	s3,-1
    800027b0:	b7d9                	j	80002776 <waitx+0xb0>
		for(np = proc; np < &proc[NPROC]; np++)
    800027b2:	19048493          	addi	s1,s1,400
    800027b6:	03348463          	beq	s1,s3,800027de <waitx+0x118>
			if(np->parent == p)
    800027ba:	7c9c                	ld	a5,56(s1)
    800027bc:	ff279be3          	bne	a5,s2,800027b2 <waitx+0xec>
				acquire(&np->lock);
    800027c0:	8526                	mv	a0,s1
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	410080e7          	jalr	1040(ra) # 80000bd2 <acquire>
				if(np->state == ZOMBIE)
    800027ca:	4c9c                	lw	a5,24(s1)
    800027cc:	f54787e3          	beq	a5,s4,8000271a <waitx+0x54>
				release(&np->lock);
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	4b4080e7          	jalr	1204(ra) # 80000c86 <release>
				havekids = 1;
    800027da:	8756                	mv	a4,s5
    800027dc:	bfd9                	j	800027b2 <waitx+0xec>
		if(!havekids || p->killed)
    800027de:	c305                	beqz	a4,800027fe <waitx+0x138>
    800027e0:	02892783          	lw	a5,40(s2)
    800027e4:	ef89                	bnez	a5,800027fe <waitx+0x138>
		sleep(p, &wait_lock); // DOC: wait-sleep
    800027e6:	85ea                	mv	a1,s10
    800027e8:	854a                	mv	a0,s2
    800027ea:	00000097          	auipc	ra,0x0
    800027ee:	96c080e7          	jalr	-1684(ra) # 80002156 <sleep>
		havekids = 0;
    800027f2:	8766                	mv	a4,s9
		for(np = proc; np < &proc[NPROC]; np++)
    800027f4:	0000e497          	auipc	s1,0xe
    800027f8:	7cc48493          	addi	s1,s1,1996 # 80010fc0 <proc>
    800027fc:	bf7d                	j	800027ba <waitx+0xf4>
			release(&wait_lock);
    800027fe:	0000e517          	auipc	a0,0xe
    80002802:	3aa50513          	addi	a0,a0,938 # 80010ba8 <wait_lock>
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	480080e7          	jalr	1152(ra) # 80000c86 <release>
			return -1;
    8000280e:	59fd                	li	s3,-1
    80002810:	b79d                	j	80002776 <waitx+0xb0>

0000000080002812 <update_time>:

void update_time()
{
    80002812:	7179                	addi	sp,sp,-48
    80002814:	f406                	sd	ra,40(sp)
    80002816:	f022                	sd	s0,32(sp)
    80002818:	ec26                	sd	s1,24(sp)
    8000281a:	e84a                	sd	s2,16(sp)
    8000281c:	e44e                	sd	s3,8(sp)
    8000281e:	1800                	addi	s0,sp,48
	struct proc* p;
	for(p = proc; p < &proc[NPROC]; p++)
    80002820:	0000e497          	auipc	s1,0xe
    80002824:	7a048493          	addi	s1,s1,1952 # 80010fc0 <proc>
	{
		acquire(&p->lock);
		if(p->state == RUNNING)
    80002828:	4991                	li	s3,4
	for(p = proc; p < &proc[NPROC]; p++)
    8000282a:	00015917          	auipc	s2,0x15
    8000282e:	b9690913          	addi	s2,s2,-1130 # 800173c0 <tickslock>
    80002832:	a811                	j	80002846 <update_time+0x34>
		{
			p->rtime++;
		}
		release(&p->lock);
    80002834:	8526                	mv	a0,s1
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	450080e7          	jalr	1104(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    8000283e:	19048493          	addi	s1,s1,400
    80002842:	03248063          	beq	s1,s2,80002862 <update_time+0x50>
		acquire(&p->lock);
    80002846:	8526                	mv	a0,s1
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	38a080e7          	jalr	906(ra) # 80000bd2 <acquire>
		if(p->state == RUNNING)
    80002850:	4c9c                	lw	a5,24(s1)
    80002852:	ff3791e3          	bne	a5,s3,80002834 <update_time+0x22>
			p->rtime++;
    80002856:	1684a783          	lw	a5,360(s1)
    8000285a:	2785                	addiw	a5,a5,1
    8000285c:	16f4a423          	sw	a5,360(s1)
    80002860:	bfd1                	j	80002834 <update_time+0x22>
	}
    80002862:	70a2                	ld	ra,40(sp)
    80002864:	7402                	ld	s0,32(sp)
    80002866:	64e2                	ld	s1,24(sp)
    80002868:	6942                	ld	s2,16(sp)
    8000286a:	69a2                	ld	s3,8(sp)
    8000286c:	6145                	addi	sp,sp,48
    8000286e:	8082                	ret

0000000080002870 <swtch>:
    80002870:	00153023          	sd	ra,0(a0)
    80002874:	00253423          	sd	sp,8(a0)
    80002878:	e900                	sd	s0,16(a0)
    8000287a:	ed04                	sd	s1,24(a0)
    8000287c:	03253023          	sd	s2,32(a0)
    80002880:	03353423          	sd	s3,40(a0)
    80002884:	03453823          	sd	s4,48(a0)
    80002888:	03553c23          	sd	s5,56(a0)
    8000288c:	05653023          	sd	s6,64(a0)
    80002890:	05753423          	sd	s7,72(a0)
    80002894:	05853823          	sd	s8,80(a0)
    80002898:	05953c23          	sd	s9,88(a0)
    8000289c:	07a53023          	sd	s10,96(a0)
    800028a0:	07b53423          	sd	s11,104(a0)
    800028a4:	0005b083          	ld	ra,0(a1)
    800028a8:	0085b103          	ld	sp,8(a1)
    800028ac:	6980                	ld	s0,16(a1)
    800028ae:	6d84                	ld	s1,24(a1)
    800028b0:	0205b903          	ld	s2,32(a1)
    800028b4:	0285b983          	ld	s3,40(a1)
    800028b8:	0305ba03          	ld	s4,48(a1)
    800028bc:	0385ba83          	ld	s5,56(a1)
    800028c0:	0405bb03          	ld	s6,64(a1)
    800028c4:	0485bb83          	ld	s7,72(a1)
    800028c8:	0505bc03          	ld	s8,80(a1)
    800028cc:	0585bc83          	ld	s9,88(a1)
    800028d0:	0605bd03          	ld	s10,96(a1)
    800028d4:	0685bd83          	ld	s11,104(a1)
    800028d8:	8082                	ret

00000000800028da <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800028da:	1141                	addi	sp,sp,-16
    800028dc:	e406                	sd	ra,8(sp)
    800028de:	e022                	sd	s0,0(sp)
    800028e0:	0800                	addi	s0,sp,16
	initlock(&tickslock, "time");
    800028e2:	00006597          	auipc	a1,0x6
    800028e6:	a1658593          	addi	a1,a1,-1514 # 800082f8 <states.0+0x30>
    800028ea:	00015517          	auipc	a0,0x15
    800028ee:	ad650513          	addi	a0,a0,-1322 # 800173c0 <tickslock>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	250080e7          	jalr	592(ra) # 80000b42 <initlock>
}
    800028fa:	60a2                	ld	ra,8(sp)
    800028fc:	6402                	ld	s0,0(sp)
    800028fe:	0141                	addi	sp,sp,16
    80002900:	8082                	ret

0000000080002902 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002902:	1141                	addi	sp,sp,-16
    80002904:	e422                	sd	s0,8(sp)
    80002906:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002908:	00003797          	auipc	a5,0x3
    8000290c:	63878793          	addi	a5,a5,1592 # 80005f40 <kernelvec>
    80002910:	10579073          	csrw	stvec,a5
	w_stvec((uint64)kernelvec);
}
    80002914:	6422                	ld	s0,8(sp)
    80002916:	0141                	addi	sp,sp,16
    80002918:	8082                	ret

000000008000291a <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000291a:	1141                	addi	sp,sp,-16
    8000291c:	e406                	sd	ra,8(sp)
    8000291e:	e022                	sd	s0,0(sp)
    80002920:	0800                	addi	s0,sp,16
	struct proc *p = myproc();
    80002922:	fffff097          	auipc	ra,0xfffff
    80002926:	084080e7          	jalr	132(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000292e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002930:	10079073          	csrw	sstatus,a5
	// kerneltrap() to usertrap(), so turn off interrupts until
	// we're back in user space, where usertrap() is correct.
	intr_off();

	// send syscalls, interrupts, and exceptions to uservec in trampoline.S
	uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002934:	00004697          	auipc	a3,0x4
    80002938:	6cc68693          	addi	a3,a3,1740 # 80007000 <_trampoline>
    8000293c:	00004717          	auipc	a4,0x4
    80002940:	6c470713          	addi	a4,a4,1732 # 80007000 <_trampoline>
    80002944:	8f15                	sub	a4,a4,a3
    80002946:	040007b7          	lui	a5,0x4000
    8000294a:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000294c:	07b2                	slli	a5,a5,0xc
    8000294e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002950:	10571073          	csrw	stvec,a4
	w_stvec(trampoline_uservec);

	// set up trapframe values that uservec will need when
	// the process next traps into the kernel.
	p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002954:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002956:	18002673          	csrr	a2,satp
    8000295a:	e310                	sd	a2,0(a4)
	p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000295c:	6d30                	ld	a2,88(a0)
    8000295e:	6138                	ld	a4,64(a0)
    80002960:	6585                	lui	a1,0x1
    80002962:	972e                	add	a4,a4,a1
    80002964:	e618                	sd	a4,8(a2)
	p->trapframe->kernel_trap = (uint64)usertrap;
    80002966:	6d38                	ld	a4,88(a0)
    80002968:	00000617          	auipc	a2,0x0
    8000296c:	14260613          	addi	a2,a2,322 # 80002aaa <usertrap>
    80002970:	eb10                	sd	a2,16(a4)
	p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002972:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002974:	8612                	mv	a2,tp
    80002976:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002978:	10002773          	csrr	a4,sstatus
	// set up the registers that trampoline.S's sret will use
	// to get to user space.

	// set S Previous Privilege mode to User.
	unsigned long x = r_sstatus();
	x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000297c:	eff77713          	andi	a4,a4,-257
	x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002980:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002984:	10071073          	csrw	sstatus,a4
	w_sstatus(x);

	// set S Exception Program Counter to the saved user pc.
	w_sepc(p->trapframe->epc);
    80002988:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000298a:	6f18                	ld	a4,24(a4)
    8000298c:	14171073          	csrw	sepc,a4

	// tell trampoline.S the user page table to switch to.
	uint64 satp = MAKE_SATP(p->pagetable);
    80002990:	6928                	ld	a0,80(a0)
    80002992:	8131                	srli	a0,a0,0xc

	// jump to userret in trampoline.S at the top of memory, which
	// switches to the user page table, restores user registers,
	// and switches to user mode with sret.
	uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002994:	00004717          	auipc	a4,0x4
    80002998:	70870713          	addi	a4,a4,1800 # 8000709c <userret>
    8000299c:	8f15                	sub	a4,a4,a3
    8000299e:	97ba                	add	a5,a5,a4
	((void (*)(uint64))trampoline_userret)(satp);
    800029a0:	577d                	li	a4,-1
    800029a2:	177e                	slli	a4,a4,0x3f
    800029a4:	8d59                	or	a0,a0,a4
    800029a6:	9782                	jalr	a5
}
    800029a8:	60a2                	ld	ra,8(sp)
    800029aa:	6402                	ld	s0,0(sp)
    800029ac:	0141                	addi	sp,sp,16
    800029ae:	8082                	ret

00000000800029b0 <clockintr>:
	w_sepc(sepc);
	w_sstatus(sstatus);
}

void clockintr()
{
    800029b0:	1101                	addi	sp,sp,-32
    800029b2:	ec06                	sd	ra,24(sp)
    800029b4:	e822                	sd	s0,16(sp)
    800029b6:	e426                	sd	s1,8(sp)
    800029b8:	e04a                	sd	s2,0(sp)
    800029ba:	1000                	addi	s0,sp,32
	acquire(&tickslock);
    800029bc:	00015917          	auipc	s2,0x15
    800029c0:	a0490913          	addi	s2,s2,-1532 # 800173c0 <tickslock>
    800029c4:	854a                	mv	a0,s2
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	20c080e7          	jalr	524(ra) # 80000bd2 <acquire>
	ticks++;
    800029ce:	00006497          	auipc	s1,0x6
    800029d2:	f5248493          	addi	s1,s1,-174 # 80008920 <ticks>
    800029d6:	409c                	lw	a5,0(s1)
    800029d8:	2785                	addiw	a5,a5,1
    800029da:	c09c                	sw	a5,0(s1)
	update_time();
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	e36080e7          	jalr	-458(ra) # 80002812 <update_time>
	//   // {
	//   //   p->wtime++;
	//   // }
	//   release(&p->lock);
	// }
	wakeup(&ticks);
    800029e4:	8526                	mv	a0,s1
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	7d4080e7          	jalr	2004(ra) # 800021ba <wakeup>
	release(&tickslock);
    800029ee:	854a                	mv	a0,s2
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	296080e7          	jalr	662(ra) # 80000c86 <release>
}
    800029f8:	60e2                	ld	ra,24(sp)
    800029fa:	6442                	ld	s0,16(sp)
    800029fc:	64a2                	ld	s1,8(sp)
    800029fe:	6902                	ld	s2,0(sp)
    80002a00:	6105                	addi	sp,sp,32
    80002a02:	8082                	ret

0000000080002a04 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a04:	142027f3          	csrr	a5,scause

		return 2;
	}
	else
	{
		return 0;
    80002a08:	4501                	li	a0,0
	if ((scause & 0x8000000000000000L) &&
    80002a0a:	0807df63          	bgez	a5,80002aa8 <devintr+0xa4>
{
    80002a0e:	1101                	addi	sp,sp,-32
    80002a10:	ec06                	sd	ra,24(sp)
    80002a12:	e822                	sd	s0,16(sp)
    80002a14:	e426                	sd	s1,8(sp)
    80002a16:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    80002a18:	0ff7f713          	zext.b	a4,a5
	if ((scause & 0x8000000000000000L) &&
    80002a1c:	46a5                	li	a3,9
    80002a1e:	00d70d63          	beq	a4,a3,80002a38 <devintr+0x34>
	else if (scause == 0x8000000000000001L)
    80002a22:	577d                	li	a4,-1
    80002a24:	177e                	slli	a4,a4,0x3f
    80002a26:	0705                	addi	a4,a4,1
		return 0;
    80002a28:	4501                	li	a0,0
	else if (scause == 0x8000000000000001L)
    80002a2a:	04e78e63          	beq	a5,a4,80002a86 <devintr+0x82>
	}
}
    80002a2e:	60e2                	ld	ra,24(sp)
    80002a30:	6442                	ld	s0,16(sp)
    80002a32:	64a2                	ld	s1,8(sp)
    80002a34:	6105                	addi	sp,sp,32
    80002a36:	8082                	ret
		int irq = plic_claim();
    80002a38:	00003097          	auipc	ra,0x3
    80002a3c:	610080e7          	jalr	1552(ra) # 80006048 <plic_claim>
    80002a40:	84aa                	mv	s1,a0
		if (irq == UART0_IRQ)
    80002a42:	47a9                	li	a5,10
    80002a44:	02f50763          	beq	a0,a5,80002a72 <devintr+0x6e>
		else if (irq == VIRTIO0_IRQ)
    80002a48:	4785                	li	a5,1
    80002a4a:	02f50963          	beq	a0,a5,80002a7c <devintr+0x78>
		return 1;
    80002a4e:	4505                	li	a0,1
		else if (irq)
    80002a50:	dcf9                	beqz	s1,80002a2e <devintr+0x2a>
			printf("unexpected interrupt irq=%d\n", irq);
    80002a52:	85a6                	mv	a1,s1
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	8ac50513          	addi	a0,a0,-1876 # 80008300 <states.0+0x38>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	b2a080e7          	jalr	-1238(ra) # 80000586 <printf>
			plic_complete(irq);
    80002a64:	8526                	mv	a0,s1
    80002a66:	00003097          	auipc	ra,0x3
    80002a6a:	606080e7          	jalr	1542(ra) # 8000606c <plic_complete>
		return 1;
    80002a6e:	4505                	li	a0,1
    80002a70:	bf7d                	j	80002a2e <devintr+0x2a>
			uartintr();
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	f22080e7          	jalr	-222(ra) # 80000994 <uartintr>
		if (irq)
    80002a7a:	b7ed                	j	80002a64 <devintr+0x60>
			virtio_disk_intr();
    80002a7c:	00004097          	auipc	ra,0x4
    80002a80:	ab6080e7          	jalr	-1354(ra) # 80006532 <virtio_disk_intr>
		if (irq)
    80002a84:	b7c5                	j	80002a64 <devintr+0x60>
		if (cpuid() == 0)
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	ef4080e7          	jalr	-268(ra) # 8000197a <cpuid>
    80002a8e:	c901                	beqz	a0,80002a9e <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a90:	144027f3          	csrr	a5,sip
		w_sip(r_sip() & ~2);
    80002a94:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a96:	14479073          	csrw	sip,a5
		return 2;
    80002a9a:	4509                	li	a0,2
    80002a9c:	bf49                	j	80002a2e <devintr+0x2a>
			clockintr();
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	f12080e7          	jalr	-238(ra) # 800029b0 <clockintr>
    80002aa6:	b7ed                	j	80002a90 <devintr+0x8c>
}
    80002aa8:	8082                	ret

0000000080002aaa <usertrap>:
{
    80002aaa:	7179                	addi	sp,sp,-48
    80002aac:	f406                	sd	ra,40(sp)
    80002aae:	f022                	sd	s0,32(sp)
    80002ab0:	ec26                	sd	s1,24(sp)
    80002ab2:	e84a                	sd	s2,16(sp)
    80002ab4:	e44e                	sd	s3,8(sp)
    80002ab6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab8:	100027f3          	csrr	a5,sstatus
	if((r_sstatus() & SSTATUS_SPP) != 0)
    80002abc:	1007f793          	andi	a5,a5,256
    80002ac0:	e3b1                	bnez	a5,80002b04 <usertrap+0x5a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ac2:	00003797          	auipc	a5,0x3
    80002ac6:	47e78793          	addi	a5,a5,1150 # 80005f40 <kernelvec>
    80002aca:	10579073          	csrw	stvec,a5
	struct proc *p = myproc();
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	ed8080e7          	jalr	-296(ra) # 800019a6 <myproc>
    80002ad6:	84aa                	mv	s1,a0
	p->trapframe->epc = r_sepc();
    80002ad8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ada:	14102773          	csrr	a4,sepc
    80002ade:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae0:	14202773          	csrr	a4,scause
	if (r_scause() == 8)
    80002ae4:	47a1                	li	a5,8
    80002ae6:	02f70763          	beq	a4,a5,80002b14 <usertrap+0x6a>
	else if ((which_dev = devintr()) != 0)
    80002aea:	00000097          	auipc	ra,0x0
    80002aee:	f1a080e7          	jalr	-230(ra) # 80002a04 <devintr>
    80002af2:	892a                	mv	s2,a0
    80002af4:	c159                	beqz	a0,80002b7a <usertrap+0xd0>
	if (killed(p))
    80002af6:	8526                	mv	a0,s1
    80002af8:	00000097          	auipc	ra,0x0
    80002afc:	912080e7          	jalr	-1774(ra) # 8000240a <killed>
    80002b00:	c929                	beqz	a0,80002b52 <usertrap+0xa8>
    80002b02:	a099                	j	80002b48 <usertrap+0x9e>
		panic("usertrap: not from user mode");
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	81c50513          	addi	a0,a0,-2020 # 80008320 <states.0+0x58>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a30080e7          	jalr	-1488(ra) # 8000053c <panic>
		if (killed(p))
    80002b14:	00000097          	auipc	ra,0x0
    80002b18:	8f6080e7          	jalr	-1802(ra) # 8000240a <killed>
    80002b1c:	e929                	bnez	a0,80002b6e <usertrap+0xc4>
		p->trapframe->epc += 4;
    80002b1e:	6cb8                	ld	a4,88(s1)
    80002b20:	6f1c                	ld	a5,24(a4)
    80002b22:	0791                	addi	a5,a5,4
    80002b24:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b26:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b2a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b2e:	10079073          	csrw	sstatus,a5
		syscall();
    80002b32:	00000097          	auipc	ra,0x0
    80002b36:	34c080e7          	jalr	844(ra) # 80002e7e <syscall>
	if (killed(p))
    80002b3a:	8526                	mv	a0,s1
    80002b3c:	00000097          	auipc	ra,0x0
    80002b40:	8ce080e7          	jalr	-1842(ra) # 8000240a <killed>
    80002b44:	c911                	beqz	a0,80002b58 <usertrap+0xae>
    80002b46:	4901                	li	s2,0
		exit(-1);
    80002b48:	557d                	li	a0,-1
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	740080e7          	jalr	1856(ra) # 8000228a <exit>
	if (which_dev == 2)
    80002b52:	4789                	li	a5,2
    80002b54:	06f90063          	beq	s2,a5,80002bb4 <usertrap+0x10a>
	usertrapret();
    80002b58:	00000097          	auipc	ra,0x0
    80002b5c:	dc2080e7          	jalr	-574(ra) # 8000291a <usertrapret>
}
    80002b60:	70a2                	ld	ra,40(sp)
    80002b62:	7402                	ld	s0,32(sp)
    80002b64:	64e2                	ld	s1,24(sp)
    80002b66:	6942                	ld	s2,16(sp)
    80002b68:	69a2                	ld	s3,8(sp)
    80002b6a:	6145                	addi	sp,sp,48
    80002b6c:	8082                	ret
			exit(-1);
    80002b6e:	557d                	li	a0,-1
    80002b70:	fffff097          	auipc	ra,0xfffff
    80002b74:	71a080e7          	jalr	1818(ra) # 8000228a <exit>
    80002b78:	b75d                	j	80002b1e <usertrap+0x74>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b7a:	142025f3          	csrr	a1,scause
		printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b7e:	5890                	lw	a2,48(s1)
    80002b80:	00005517          	auipc	a0,0x5
    80002b84:	7c050513          	addi	a0,a0,1984 # 80008340 <states.0+0x78>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	9fe080e7          	jalr	-1538(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b90:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b94:	14302673          	csrr	a2,stval
		printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b98:	00005517          	auipc	a0,0x5
    80002b9c:	7d850513          	addi	a0,a0,2008 # 80008370 <states.0+0xa8>
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	9e6080e7          	jalr	-1562(ra) # 80000586 <printf>
		setkilled(p);
    80002ba8:	8526                	mv	a0,s1
    80002baa:	00000097          	auipc	ra,0x0
    80002bae:	834080e7          	jalr	-1996(ra) # 800023de <setkilled>
    80002bb2:	b761                	j	80002b3a <usertrap+0x90>
		p->now_ticks+=1 ;
    80002bb4:	17c4a783          	lw	a5,380(s1)
    80002bb8:	2785                	addiw	a5,a5,1
    80002bba:	16f4ae23          	sw	a5,380(s1)
printf("proc %d , cpu %d , ctime %d\n",myproc()->pid,cpuid(),myproc()->ctime); 
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	de8080e7          	jalr	-536(ra) # 800019a6 <myproc>
    80002bc6:	03052983          	lw	s3,48(a0)
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	db0080e7          	jalr	-592(ra) # 8000197a <cpuid>
    80002bd2:	892a                	mv	s2,a0
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	dd2080e7          	jalr	-558(ra) # 800019a6 <myproc>
    80002bdc:	16c52683          	lw	a3,364(a0)
    80002be0:	864a                	mv	a2,s2
    80002be2:	85ce                	mv	a1,s3
    80002be4:	00005517          	auipc	a0,0x5
    80002be8:	7ac50513          	addi	a0,a0,1964 # 80008390 <states.0+0xc8>
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	99a080e7          	jalr	-1638(ra) # 80000586 <printf>
		if( p-> ticks > 0 && p->now_ticks >= p->ticks && !p->is_sigalarm)
    80002bf4:	1784a783          	lw	a5,376(s1)
    80002bf8:	f6f050e3          	blez	a5,80002b58 <usertrap+0xae>
    80002bfc:	17c4a703          	lw	a4,380(s1)
    80002c00:	f4f74ce3          	blt	a4,a5,80002b58 <usertrap+0xae>
    80002c04:	1744a783          	lw	a5,372(s1)
    80002c08:	fba1                	bnez	a5,80002b58 <usertrap+0xae>
			p->now_ticks = 0;
    80002c0a:	1604ae23          	sw	zero,380(s1)
			p->is_sigalarm = 1;
    80002c0e:	4785                	li	a5,1
    80002c10:	16f4aa23          	sw	a5,372(s1)
			*(p->backup_trapframe) =*( p->trapframe);
    80002c14:	6cb4                	ld	a3,88(s1)
    80002c16:	87b6                	mv	a5,a3
    80002c18:	1884b703          	ld	a4,392(s1)
    80002c1c:	12068693          	addi	a3,a3,288
    80002c20:	0007b803          	ld	a6,0(a5)
    80002c24:	6788                	ld	a0,8(a5)
    80002c26:	6b8c                	ld	a1,16(a5)
    80002c28:	6f90                	ld	a2,24(a5)
    80002c2a:	01073023          	sd	a6,0(a4)
    80002c2e:	e708                	sd	a0,8(a4)
    80002c30:	eb0c                	sd	a1,16(a4)
    80002c32:	ef10                	sd	a2,24(a4)
    80002c34:	02078793          	addi	a5,a5,32
    80002c38:	02070713          	addi	a4,a4,32
    80002c3c:	fed792e3          	bne	a5,a3,80002c20 <usertrap+0x176>
			p->trapframe->epc = p->handler;
    80002c40:	6cbc                	ld	a5,88(s1)
    80002c42:	1804b703          	ld	a4,384(s1)
    80002c46:	ef98                	sd	a4,24(a5)
    80002c48:	bf01                	j	80002b58 <usertrap+0xae>

0000000080002c4a <kerneltrap>:
{
    80002c4a:	7179                	addi	sp,sp,-48
    80002c4c:	f406                	sd	ra,40(sp)
    80002c4e:	f022                	sd	s0,32(sp)
    80002c50:	ec26                	sd	s1,24(sp)
    80002c52:	e84a                	sd	s2,16(sp)
    80002c54:	e44e                	sd	s3,8(sp)
    80002c56:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c58:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c60:	142029f3          	csrr	s3,scause
	if ((sstatus & SSTATUS_SPP) == 0)
    80002c64:	1004f793          	andi	a5,s1,256
    80002c68:	c78d                	beqz	a5,80002c92 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c6a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c6e:	8b89                	andi	a5,a5,2
	if (intr_get() != 0)
    80002c70:	eb8d                	bnez	a5,80002ca2 <kerneltrap+0x58>
	if ((which_dev = devintr()) == 0)
    80002c72:	00000097          	auipc	ra,0x0
    80002c76:	d92080e7          	jalr	-622(ra) # 80002a04 <devintr>
    80002c7a:	cd05                	beqz	a0,80002cb2 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c7c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c80:	10049073          	csrw	sstatus,s1
}
    80002c84:	70a2                	ld	ra,40(sp)
    80002c86:	7402                	ld	s0,32(sp)
    80002c88:	64e2                	ld	s1,24(sp)
    80002c8a:	6942                	ld	s2,16(sp)
    80002c8c:	69a2                	ld	s3,8(sp)
    80002c8e:	6145                	addi	sp,sp,48
    80002c90:	8082                	ret
		panic("kerneltrap: not from supervisor mode");
    80002c92:	00005517          	auipc	a0,0x5
    80002c96:	71e50513          	addi	a0,a0,1822 # 800083b0 <states.0+0xe8>
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	8a2080e7          	jalr	-1886(ra) # 8000053c <panic>
		panic("kerneltrap: interrupts enabled");
    80002ca2:	00005517          	auipc	a0,0x5
    80002ca6:	73650513          	addi	a0,a0,1846 # 800083d8 <states.0+0x110>
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	892080e7          	jalr	-1902(ra) # 8000053c <panic>
		printf("scause %p\n", scause);
    80002cb2:	85ce                	mv	a1,s3
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	74450513          	addi	a0,a0,1860 # 800083f8 <states.0+0x130>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	8ca080e7          	jalr	-1846(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cc4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cc8:	14302673          	csrr	a2,stval
		printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ccc:	00005517          	auipc	a0,0x5
    80002cd0:	73c50513          	addi	a0,a0,1852 # 80008408 <states.0+0x140>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	8b2080e7          	jalr	-1870(ra) # 80000586 <printf>
		panic("kerneltrap");
    80002cdc:	00005517          	auipc	a0,0x5
    80002ce0:	74450513          	addi	a0,a0,1860 # 80008420 <states.0+0x158>
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	858080e7          	jalr	-1960(ra) # 8000053c <panic>

0000000080002cec <sys_getreadcount>:
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}
uint64 sys_getreadcount(void)
{
    80002cec:	1141                	addi	sp,sp,-16
    80002cee:	e422                	sd	s0,8(sp)
    80002cf0:	0800                	addi	s0,sp,16
  return READCOUNT; 
}
    80002cf2:	00006517          	auipc	a0,0x6
    80002cf6:	c3653503          	ld	a0,-970(a0) # 80008928 <READCOUNT>
    80002cfa:	6422                	ld	s0,8(sp)
    80002cfc:	0141                	addi	sp,sp,16
    80002cfe:	8082                	ret

0000000080002d00 <argraw>:
{
    80002d00:	1101                	addi	sp,sp,-32
    80002d02:	ec06                	sd	ra,24(sp)
    80002d04:	e822                	sd	s0,16(sp)
    80002d06:	e426                	sd	s1,8(sp)
    80002d08:	1000                	addi	s0,sp,32
    80002d0a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	c9a080e7          	jalr	-870(ra) # 800019a6 <myproc>
  switch (n) {
    80002d14:	4795                	li	a5,5
    80002d16:	0497e163          	bltu	a5,s1,80002d58 <argraw+0x58>
    80002d1a:	048a                	slli	s1,s1,0x2
    80002d1c:	00005717          	auipc	a4,0x5
    80002d20:	73c70713          	addi	a4,a4,1852 # 80008458 <states.0+0x190>
    80002d24:	94ba                	add	s1,s1,a4
    80002d26:	409c                	lw	a5,0(s1)
    80002d28:	97ba                	add	a5,a5,a4
    80002d2a:	8782                	jr	a5
    return p->trapframe->a0;
    80002d2c:	6d3c                	ld	a5,88(a0)
    80002d2e:	7ba8                	ld	a0,112(a5)
}
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	64a2                	ld	s1,8(sp)
    80002d36:	6105                	addi	sp,sp,32
    80002d38:	8082                	ret
    return p->trapframe->a1;
    80002d3a:	6d3c                	ld	a5,88(a0)
    80002d3c:	7fa8                	ld	a0,120(a5)
    80002d3e:	bfcd                	j	80002d30 <argraw+0x30>
    return p->trapframe->a2;
    80002d40:	6d3c                	ld	a5,88(a0)
    80002d42:	63c8                	ld	a0,128(a5)
    80002d44:	b7f5                	j	80002d30 <argraw+0x30>
    return p->trapframe->a3;
    80002d46:	6d3c                	ld	a5,88(a0)
    80002d48:	67c8                	ld	a0,136(a5)
    80002d4a:	b7dd                	j	80002d30 <argraw+0x30>
    return p->trapframe->a4;
    80002d4c:	6d3c                	ld	a5,88(a0)
    80002d4e:	6bc8                	ld	a0,144(a5)
    80002d50:	b7c5                	j	80002d30 <argraw+0x30>
    return p->trapframe->a5;
    80002d52:	6d3c                	ld	a5,88(a0)
    80002d54:	6fc8                	ld	a0,152(a5)
    80002d56:	bfe9                	j	80002d30 <argraw+0x30>
  panic("argraw");
    80002d58:	00005517          	auipc	a0,0x5
    80002d5c:	6d850513          	addi	a0,a0,1752 # 80008430 <states.0+0x168>
    80002d60:	ffffd097          	auipc	ra,0xffffd
    80002d64:	7dc080e7          	jalr	2012(ra) # 8000053c <panic>

0000000080002d68 <fetchaddr>:
{
    80002d68:	1101                	addi	sp,sp,-32
    80002d6a:	ec06                	sd	ra,24(sp)
    80002d6c:	e822                	sd	s0,16(sp)
    80002d6e:	e426                	sd	s1,8(sp)
    80002d70:	e04a                	sd	s2,0(sp)
    80002d72:	1000                	addi	s0,sp,32
    80002d74:	84aa                	mv	s1,a0
    80002d76:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	c2e080e7          	jalr	-978(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d80:	653c                	ld	a5,72(a0)
    80002d82:	02f4f863          	bgeu	s1,a5,80002db2 <fetchaddr+0x4a>
    80002d86:	00848713          	addi	a4,s1,8
    80002d8a:	02e7e663          	bltu	a5,a4,80002db6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d8e:	46a1                	li	a3,8
    80002d90:	8626                	mv	a2,s1
    80002d92:	85ca                	mv	a1,s2
    80002d94:	6928                	ld	a0,80(a0)
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	95c080e7          	jalr	-1700(ra) # 800016f2 <copyin>
    80002d9e:	00a03533          	snez	a0,a0
    80002da2:	40a00533          	neg	a0,a0
}
    80002da6:	60e2                	ld	ra,24(sp)
    80002da8:	6442                	ld	s0,16(sp)
    80002daa:	64a2                	ld	s1,8(sp)
    80002dac:	6902                	ld	s2,0(sp)
    80002dae:	6105                	addi	sp,sp,32
    80002db0:	8082                	ret
    return -1;
    80002db2:	557d                	li	a0,-1
    80002db4:	bfcd                	j	80002da6 <fetchaddr+0x3e>
    80002db6:	557d                	li	a0,-1
    80002db8:	b7fd                	j	80002da6 <fetchaddr+0x3e>

0000000080002dba <fetchstr>:
{
    80002dba:	7179                	addi	sp,sp,-48
    80002dbc:	f406                	sd	ra,40(sp)
    80002dbe:	f022                	sd	s0,32(sp)
    80002dc0:	ec26                	sd	s1,24(sp)
    80002dc2:	e84a                	sd	s2,16(sp)
    80002dc4:	e44e                	sd	s3,8(sp)
    80002dc6:	1800                	addi	s0,sp,48
    80002dc8:	892a                	mv	s2,a0
    80002dca:	84ae                	mv	s1,a1
    80002dcc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	bd8080e7          	jalr	-1064(ra) # 800019a6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002dd6:	86ce                	mv	a3,s3
    80002dd8:	864a                	mv	a2,s2
    80002dda:	85a6                	mv	a1,s1
    80002ddc:	6928                	ld	a0,80(a0)
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	9a2080e7          	jalr	-1630(ra) # 80001780 <copyinstr>
    80002de6:	00054e63          	bltz	a0,80002e02 <fetchstr+0x48>
  return strlen(buf);
    80002dea:	8526                	mv	a0,s1
    80002dec:	ffffe097          	auipc	ra,0xffffe
    80002df0:	05c080e7          	jalr	92(ra) # 80000e48 <strlen>
}
    80002df4:	70a2                	ld	ra,40(sp)
    80002df6:	7402                	ld	s0,32(sp)
    80002df8:	64e2                	ld	s1,24(sp)
    80002dfa:	6942                	ld	s2,16(sp)
    80002dfc:	69a2                	ld	s3,8(sp)
    80002dfe:	6145                	addi	sp,sp,48
    80002e00:	8082                	ret
    return -1;
    80002e02:	557d                	li	a0,-1
    80002e04:	bfc5                	j	80002df4 <fetchstr+0x3a>

0000000080002e06 <argint>:
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	1000                	addi	s0,sp,32
    80002e10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e12:	00000097          	auipc	ra,0x0
    80002e16:	eee080e7          	jalr	-274(ra) # 80002d00 <argraw>
    80002e1a:	c088                	sw	a0,0(s1)
}
    80002e1c:	60e2                	ld	ra,24(sp)
    80002e1e:	6442                	ld	s0,16(sp)
    80002e20:	64a2                	ld	s1,8(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <argaddr>:
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	e426                	sd	s1,8(sp)
    80002e2e:	1000                	addi	s0,sp,32
    80002e30:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	ece080e7          	jalr	-306(ra) # 80002d00 <argraw>
    80002e3a:	e088                	sd	a0,0(s1)
}
    80002e3c:	60e2                	ld	ra,24(sp)
    80002e3e:	6442                	ld	s0,16(sp)
    80002e40:	64a2                	ld	s1,8(sp)
    80002e42:	6105                	addi	sp,sp,32
    80002e44:	8082                	ret

0000000080002e46 <argstr>:
{
    80002e46:	7179                	addi	sp,sp,-48
    80002e48:	f406                	sd	ra,40(sp)
    80002e4a:	f022                	sd	s0,32(sp)
    80002e4c:	ec26                	sd	s1,24(sp)
    80002e4e:	e84a                	sd	s2,16(sp)
    80002e50:	1800                	addi	s0,sp,48
    80002e52:	84ae                	mv	s1,a1
    80002e54:	8932                	mv	s2,a2
  argaddr(n, &addr);
    80002e56:	fd840593          	addi	a1,s0,-40
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	fcc080e7          	jalr	-52(ra) # 80002e26 <argaddr>
  return fetchstr(addr, buf, max);
    80002e62:	864a                	mv	a2,s2
    80002e64:	85a6                	mv	a1,s1
    80002e66:	fd843503          	ld	a0,-40(s0)
    80002e6a:	00000097          	auipc	ra,0x0
    80002e6e:	f50080e7          	jalr	-176(ra) # 80002dba <fetchstr>
}
    80002e72:	70a2                	ld	ra,40(sp)
    80002e74:	7402                	ld	s0,32(sp)
    80002e76:	64e2                	ld	s1,24(sp)
    80002e78:	6942                	ld	s2,16(sp)
    80002e7a:	6145                	addi	sp,sp,48
    80002e7c:	8082                	ret

0000000080002e7e <syscall>:

};

void
syscall(void)
{
    80002e7e:	1101                	addi	sp,sp,-32
    80002e80:	ec06                	sd	ra,24(sp)
    80002e82:	e822                	sd	s0,16(sp)
    80002e84:	e426                	sd	s1,8(sp)
    80002e86:	e04a                	sd	s2,0(sp)
    80002e88:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	b1c080e7          	jalr	-1252(ra) # 800019a6 <myproc>
    80002e92:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e94:	05853903          	ld	s2,88(a0)
    80002e98:	0a893783          	ld	a5,168(s2)
    80002e9c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ea0:	37fd                	addiw	a5,a5,-1
    80002ea2:	4761                	li	a4,24
    80002ea4:	00f76f63          	bltu	a4,a5,80002ec2 <syscall+0x44>
    80002ea8:	00369713          	slli	a4,a3,0x3
    80002eac:	00005797          	auipc	a5,0x5
    80002eb0:	5c478793          	addi	a5,a5,1476 # 80008470 <syscalls>
    80002eb4:	97ba                	add	a5,a5,a4
    80002eb6:	639c                	ld	a5,0(a5)
    80002eb8:	c789                	beqz	a5,80002ec2 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002eba:	9782                	jalr	a5
    80002ebc:	06a93823          	sd	a0,112(s2)
    80002ec0:	a839                	j	80002ede <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ec2:	15848613          	addi	a2,s1,344
    80002ec6:	588c                	lw	a1,48(s1)
    80002ec8:	00005517          	auipc	a0,0x5
    80002ecc:	57050513          	addi	a0,a0,1392 # 80008438 <states.0+0x170>
    80002ed0:	ffffd097          	auipc	ra,0xffffd
    80002ed4:	6b6080e7          	jalr	1718(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ed8:	6cbc                	ld	a5,88(s1)
    80002eda:	577d                	li	a4,-1
    80002edc:	fbb8                	sd	a4,112(a5)
  }
}
    80002ede:	60e2                	ld	ra,24(sp)
    80002ee0:	6442                	ld	s0,16(sp)
    80002ee2:	64a2                	ld	s1,8(sp)
    80002ee4:	6902                	ld	s2,0(sp)
    80002ee6:	6105                	addi	sp,sp,32
    80002ee8:	8082                	ret

0000000080002eea <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eea:	1101                	addi	sp,sp,-32
    80002eec:	ec06                	sd	ra,24(sp)
    80002eee:	e822                	sd	s0,16(sp)
    80002ef0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ef2:	fec40593          	addi	a1,s0,-20
    80002ef6:	4501                	li	a0,0
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	f0e080e7          	jalr	-242(ra) # 80002e06 <argint>
  exit(n);
    80002f00:	fec42503          	lw	a0,-20(s0)
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	386080e7          	jalr	902(ra) # 8000228a <exit>
  return 0; // not reached
}
    80002f0c:	4501                	li	a0,0
    80002f0e:	60e2                	ld	ra,24(sp)
    80002f10:	6442                	ld	s0,16(sp)
    80002f12:	6105                	addi	sp,sp,32
    80002f14:	8082                	ret

0000000080002f16 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f16:	1141                	addi	sp,sp,-16
    80002f18:	e406                	sd	ra,8(sp)
    80002f1a:	e022                	sd	s0,0(sp)
    80002f1c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	a88080e7          	jalr	-1400(ra) # 800019a6 <myproc>
}
    80002f26:	5908                	lw	a0,48(a0)
    80002f28:	60a2                	ld	ra,8(sp)
    80002f2a:	6402                	ld	s0,0(sp)
    80002f2c:	0141                	addi	sp,sp,16
    80002f2e:	8082                	ret

0000000080002f30 <sys_fork>:

uint64
sys_fork(void)
{
    80002f30:	1141                	addi	sp,sp,-16
    80002f32:	e406                	sd	ra,8(sp)
    80002f34:	e022                	sd	s0,0(sp)
    80002f36:	0800                	addi	s0,sp,16
  return fork();
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	ece080e7          	jalr	-306(ra) # 80001e06 <fork>
}
    80002f40:	60a2                	ld	ra,8(sp)
    80002f42:	6402                	ld	s0,0(sp)
    80002f44:	0141                	addi	sp,sp,16
    80002f46:	8082                	ret

0000000080002f48 <sys_wait>:

uint64
sys_wait(void)
{
    80002f48:	1101                	addi	sp,sp,-32
    80002f4a:	ec06                	sd	ra,24(sp)
    80002f4c:	e822                	sd	s0,16(sp)
    80002f4e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f50:	fe840593          	addi	a1,s0,-24
    80002f54:	4501                	li	a0,0
    80002f56:	00000097          	auipc	ra,0x0
    80002f5a:	ed0080e7          	jalr	-304(ra) # 80002e26 <argaddr>
  return wait(p);
    80002f5e:	fe843503          	ld	a0,-24(s0)
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	4da080e7          	jalr	1242(ra) # 8000243c <wait>
}
    80002f6a:	60e2                	ld	ra,24(sp)
    80002f6c:	6442                	ld	s0,16(sp)
    80002f6e:	6105                	addi	sp,sp,32
    80002f70:	8082                	ret

0000000080002f72 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f72:	7179                	addi	sp,sp,-48
    80002f74:	f406                	sd	ra,40(sp)
    80002f76:	f022                	sd	s0,32(sp)
    80002f78:	ec26                	sd	s1,24(sp)
    80002f7a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f7c:	fdc40593          	addi	a1,s0,-36
    80002f80:	4501                	li	a0,0
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	e84080e7          	jalr	-380(ra) # 80002e06 <argint>
  addr = myproc()->sz;
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	a1c080e7          	jalr	-1508(ra) # 800019a6 <myproc>
    80002f92:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002f94:	fdc42503          	lw	a0,-36(s0)
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	e12080e7          	jalr	-494(ra) # 80001daa <growproc>
    80002fa0:	00054863          	bltz	a0,80002fb0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002fa4:	8526                	mv	a0,s1
    80002fa6:	70a2                	ld	ra,40(sp)
    80002fa8:	7402                	ld	s0,32(sp)
    80002faa:	64e2                	ld	s1,24(sp)
    80002fac:	6145                	addi	sp,sp,48
    80002fae:	8082                	ret
    return -1;
    80002fb0:	54fd                	li	s1,-1
    80002fb2:	bfcd                	j	80002fa4 <sys_sbrk+0x32>

0000000080002fb4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fb4:	7139                	addi	sp,sp,-64
    80002fb6:	fc06                	sd	ra,56(sp)
    80002fb8:	f822                	sd	s0,48(sp)
    80002fba:	f426                	sd	s1,40(sp)
    80002fbc:	f04a                	sd	s2,32(sp)
    80002fbe:	ec4e                	sd	s3,24(sp)
    80002fc0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002fc2:	fcc40593          	addi	a1,s0,-52
    80002fc6:	4501                	li	a0,0
    80002fc8:	00000097          	auipc	ra,0x0
    80002fcc:	e3e080e7          	jalr	-450(ra) # 80002e06 <argint>
  acquire(&tickslock);
    80002fd0:	00014517          	auipc	a0,0x14
    80002fd4:	3f050513          	addi	a0,a0,1008 # 800173c0 <tickslock>
    80002fd8:	ffffe097          	auipc	ra,0xffffe
    80002fdc:	bfa080e7          	jalr	-1030(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002fe0:	00006917          	auipc	s2,0x6
    80002fe4:	94092903          	lw	s2,-1728(s2) # 80008920 <ticks>
  while (ticks - ticks0 < n)
    80002fe8:	fcc42783          	lw	a5,-52(s0)
    80002fec:	cf9d                	beqz	a5,8000302a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fee:	00014997          	auipc	s3,0x14
    80002ff2:	3d298993          	addi	s3,s3,978 # 800173c0 <tickslock>
    80002ff6:	00006497          	auipc	s1,0x6
    80002ffa:	92a48493          	addi	s1,s1,-1750 # 80008920 <ticks>
    if (killed(myproc()))
    80002ffe:	fffff097          	auipc	ra,0xfffff
    80003002:	9a8080e7          	jalr	-1624(ra) # 800019a6 <myproc>
    80003006:	fffff097          	auipc	ra,0xfffff
    8000300a:	404080e7          	jalr	1028(ra) # 8000240a <killed>
    8000300e:	ed15                	bnez	a0,8000304a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003010:	85ce                	mv	a1,s3
    80003012:	8526                	mv	a0,s1
    80003014:	fffff097          	auipc	ra,0xfffff
    80003018:	142080e7          	jalr	322(ra) # 80002156 <sleep>
  while (ticks - ticks0 < n)
    8000301c:	409c                	lw	a5,0(s1)
    8000301e:	412787bb          	subw	a5,a5,s2
    80003022:	fcc42703          	lw	a4,-52(s0)
    80003026:	fce7ece3          	bltu	a5,a4,80002ffe <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000302a:	00014517          	auipc	a0,0x14
    8000302e:	39650513          	addi	a0,a0,918 # 800173c0 <tickslock>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	c54080e7          	jalr	-940(ra) # 80000c86 <release>
  return 0;
    8000303a:	4501                	li	a0,0
}
    8000303c:	70e2                	ld	ra,56(sp)
    8000303e:	7442                	ld	s0,48(sp)
    80003040:	74a2                	ld	s1,40(sp)
    80003042:	7902                	ld	s2,32(sp)
    80003044:	69e2                	ld	s3,24(sp)
    80003046:	6121                	addi	sp,sp,64
    80003048:	8082                	ret
      release(&tickslock);
    8000304a:	00014517          	auipc	a0,0x14
    8000304e:	37650513          	addi	a0,a0,886 # 800173c0 <tickslock>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	c34080e7          	jalr	-972(ra) # 80000c86 <release>
      return -1;
    8000305a:	557d                	li	a0,-1
    8000305c:	b7c5                	j	8000303c <sys_sleep+0x88>

000000008000305e <sys_kill>:

uint64
sys_kill(void)
{
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003066:	fec40593          	addi	a1,s0,-20
    8000306a:	4501                	li	a0,0
    8000306c:	00000097          	auipc	ra,0x0
    80003070:	d9a080e7          	jalr	-614(ra) # 80002e06 <argint>
  return kill(pid);
    80003074:	fec42503          	lw	a0,-20(s0)
    80003078:	fffff097          	auipc	ra,0xfffff
    8000307c:	2f4080e7          	jalr	756(ra) # 8000236c <kill>
}
    80003080:	60e2                	ld	ra,24(sp)
    80003082:	6442                	ld	s0,16(sp)
    80003084:	6105                	addi	sp,sp,32
    80003086:	8082                	ret

0000000080003088 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003092:	00014517          	auipc	a0,0x14
    80003096:	32e50513          	addi	a0,a0,814 # 800173c0 <tickslock>
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	b38080e7          	jalr	-1224(ra) # 80000bd2 <acquire>
  xticks = ticks;
    800030a2:	00006497          	auipc	s1,0x6
    800030a6:	87e4a483          	lw	s1,-1922(s1) # 80008920 <ticks>
  release(&tickslock);
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	31650513          	addi	a0,a0,790 # 800173c0 <tickslock>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	bd4080e7          	jalr	-1068(ra) # 80000c86 <release>
  return xticks;
}
    800030ba:	02049513          	slli	a0,s1,0x20
    800030be:	9101                	srli	a0,a0,0x20
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret

00000000800030ca <sys_waitx>:

uint64
sys_waitx(void)
{
    800030ca:	7139                	addi	sp,sp,-64
    800030cc:	fc06                	sd	ra,56(sp)
    800030ce:	f822                	sd	s0,48(sp)
    800030d0:	f426                	sd	s1,40(sp)
    800030d2:	f04a                	sd	s2,32(sp)
    800030d4:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800030d6:	fd840593          	addi	a1,s0,-40
    800030da:	4501                	li	a0,0
    800030dc:	00000097          	auipc	ra,0x0
    800030e0:	d4a080e7          	jalr	-694(ra) # 80002e26 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800030e4:	fd040593          	addi	a1,s0,-48
    800030e8:	4505                	li	a0,1
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	d3c080e7          	jalr	-708(ra) # 80002e26 <argaddr>
  argaddr(2, &addr2);
    800030f2:	fc840593          	addi	a1,s0,-56
    800030f6:	4509                	li	a0,2
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	d2e080e7          	jalr	-722(ra) # 80002e26 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003100:	fc040613          	addi	a2,s0,-64
    80003104:	fc440593          	addi	a1,s0,-60
    80003108:	fd843503          	ld	a0,-40(s0)
    8000310c:	fffff097          	auipc	ra,0xfffff
    80003110:	5ba080e7          	jalr	1466(ra) # 800026c6 <waitx>
    80003114:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003116:	fffff097          	auipc	ra,0xfffff
    8000311a:	890080e7          	jalr	-1904(ra) # 800019a6 <myproc>
    8000311e:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003120:	4691                	li	a3,4
    80003122:	fc440613          	addi	a2,s0,-60
    80003126:	fd043583          	ld	a1,-48(s0)
    8000312a:	6928                	ld	a0,80(a0)
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	53a080e7          	jalr	1338(ra) # 80001666 <copyout>
    return -1;
    80003134:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003136:	00054f63          	bltz	a0,80003154 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000313a:	4691                	li	a3,4
    8000313c:	fc040613          	addi	a2,s0,-64
    80003140:	fc843583          	ld	a1,-56(s0)
    80003144:	68a8                	ld	a0,80(s1)
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	520080e7          	jalr	1312(ra) # 80001666 <copyout>
    8000314e:	00054a63          	bltz	a0,80003162 <sys_waitx+0x98>
    return -1;
  return ret;
    80003152:	87ca                	mv	a5,s2
}
    80003154:	853e                	mv	a0,a5
    80003156:	70e2                	ld	ra,56(sp)
    80003158:	7442                	ld	s0,48(sp)
    8000315a:	74a2                	ld	s1,40(sp)
    8000315c:	7902                	ld	s2,32(sp)
    8000315e:	6121                	addi	sp,sp,64
    80003160:	8082                	ret
    return -1;
    80003162:	57fd                	li	a5,-1
    80003164:	bfc5                	j	80003154 <sys_waitx+0x8a>

0000000080003166 <restore>:
void restore(){
    80003166:	1141                	addi	sp,sp,-16
    80003168:	e406                	sd	ra,8(sp)
    8000316a:	e022                	sd	s0,0(sp)
    8000316c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	838080e7          	jalr	-1992(ra) # 800019a6 <myproc>
  p->backup_trapframe->kernel_hartid = p->trapframe->kernel_hartid;
    80003176:	18853783          	ld	a5,392(a0)
    8000317a:	6d38                	ld	a4,88(a0)
    8000317c:	7318                	ld	a4,32(a4)
    8000317e:	f398                	sd	a4,32(a5)
  p->backup_trapframe->kernel_satp = p->trapframe->kernel_satp;
    80003180:	18853783          	ld	a5,392(a0)
    80003184:	6d38                	ld	a4,88(a0)
    80003186:	6318                	ld	a4,0(a4)
    80003188:	e398                	sd	a4,0(a5)
  p->backup_trapframe->kernel_sp = p->trapframe->kernel_sp;
    8000318a:	18853783          	ld	a5,392(a0)
    8000318e:	6d38                	ld	a4,88(a0)
    80003190:	6718                	ld	a4,8(a4)
    80003192:	e798                	sd	a4,8(a5)
  p->backup_trapframe->kernel_trap = p->trapframe->kernel_trap;
    80003194:	18853783          	ld	a5,392(a0)
    80003198:	6d38                	ld	a4,88(a0)
    8000319a:	6b18                	ld	a4,16(a4)
    8000319c:	eb98                	sd	a4,16(a5)
  *(p->trapframe) = *(p->backup_trapframe);
    8000319e:	18853683          	ld	a3,392(a0)
    800031a2:	87b6                	mv	a5,a3
    800031a4:	6d38                	ld	a4,88(a0)
    800031a6:	12068693          	addi	a3,a3,288
    800031aa:	0007b803          	ld	a6,0(a5)
    800031ae:	6788                	ld	a0,8(a5)
    800031b0:	6b8c                	ld	a1,16(a5)
    800031b2:	6f90                	ld	a2,24(a5)
    800031b4:	01073023          	sd	a6,0(a4)
    800031b8:	e708                	sd	a0,8(a4)
    800031ba:	eb0c                	sd	a1,16(a4)
    800031bc:	ef10                	sd	a2,24(a4)
    800031be:	02078793          	addi	a5,a5,32
    800031c2:	02070713          	addi	a4,a4,32
    800031c6:	fed792e3          	bne	a5,a3,800031aa <restore+0x44>
} 
    800031ca:	60a2                	ld	ra,8(sp)
    800031cc:	6402                	ld	s0,0(sp)
    800031ce:	0141                	addi	sp,sp,16
    800031d0:	8082                	ret

00000000800031d2 <sys_sigreturn>:
uint64 sys_sigreturn(void){
    800031d2:	1141                	addi	sp,sp,-16
    800031d4:	e406                	sd	ra,8(sp)
    800031d6:	e022                	sd	s0,0(sp)
    800031d8:	0800                	addi	s0,sp,16
  restore();
    800031da:	00000097          	auipc	ra,0x0
    800031de:	f8c080e7          	jalr	-116(ra) # 80003166 <restore>
  myproc()->is_sigalarm = 0;
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	7c4080e7          	jalr	1988(ra) # 800019a6 <myproc>
    800031ea:	16052a23          	sw	zero,372(a0)
  return myproc()->trapframe->a0;
    800031ee:	ffffe097          	auipc	ra,0xffffe
    800031f2:	7b8080e7          	jalr	1976(ra) # 800019a6 <myproc>
    800031f6:	6d3c                	ld	a5,88(a0)
    800031f8:	7ba8                	ld	a0,112(a5)
    800031fa:	60a2                	ld	ra,8(sp)
    800031fc:	6402                	ld	s0,0(sp)
    800031fe:	0141                	addi	sp,sp,16
    80003200:	8082                	ret

0000000080003202 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003202:	7179                	addi	sp,sp,-48
    80003204:	f406                	sd	ra,40(sp)
    80003206:	f022                	sd	s0,32(sp)
    80003208:	ec26                	sd	s1,24(sp)
    8000320a:	e84a                	sd	s2,16(sp)
    8000320c:	e44e                	sd	s3,8(sp)
    8000320e:	e052                	sd	s4,0(sp)
    80003210:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003212:	00005597          	auipc	a1,0x5
    80003216:	32e58593          	addi	a1,a1,814 # 80008540 <syscalls+0xd0>
    8000321a:	00014517          	auipc	a0,0x14
    8000321e:	1be50513          	addi	a0,a0,446 # 800173d8 <bcache>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	920080e7          	jalr	-1760(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000322a:	0001c797          	auipc	a5,0x1c
    8000322e:	1ae78793          	addi	a5,a5,430 # 8001f3d8 <bcache+0x8000>
    80003232:	0001c717          	auipc	a4,0x1c
    80003236:	40e70713          	addi	a4,a4,1038 # 8001f640 <bcache+0x8268>
    8000323a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000323e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003242:	00014497          	auipc	s1,0x14
    80003246:	1ae48493          	addi	s1,s1,430 # 800173f0 <bcache+0x18>
    b->next = bcache.head.next;
    8000324a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000324c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000324e:	00005a17          	auipc	s4,0x5
    80003252:	2faa0a13          	addi	s4,s4,762 # 80008548 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003256:	2b893783          	ld	a5,696(s2)
    8000325a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000325c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003260:	85d2                	mv	a1,s4
    80003262:	01048513          	addi	a0,s1,16
    80003266:	00001097          	auipc	ra,0x1
    8000326a:	496080e7          	jalr	1174(ra) # 800046fc <initsleeplock>
    bcache.head.next->prev = b;
    8000326e:	2b893783          	ld	a5,696(s2)
    80003272:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003274:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003278:	45848493          	addi	s1,s1,1112
    8000327c:	fd349de3          	bne	s1,s3,80003256 <binit+0x54>
  }
}
    80003280:	70a2                	ld	ra,40(sp)
    80003282:	7402                	ld	s0,32(sp)
    80003284:	64e2                	ld	s1,24(sp)
    80003286:	6942                	ld	s2,16(sp)
    80003288:	69a2                	ld	s3,8(sp)
    8000328a:	6a02                	ld	s4,0(sp)
    8000328c:	6145                	addi	sp,sp,48
    8000328e:	8082                	ret

0000000080003290 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003290:	7179                	addi	sp,sp,-48
    80003292:	f406                	sd	ra,40(sp)
    80003294:	f022                	sd	s0,32(sp)
    80003296:	ec26                	sd	s1,24(sp)
    80003298:	e84a                	sd	s2,16(sp)
    8000329a:	e44e                	sd	s3,8(sp)
    8000329c:	1800                	addi	s0,sp,48
    8000329e:	892a                	mv	s2,a0
    800032a0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032a2:	00014517          	auipc	a0,0x14
    800032a6:	13650513          	addi	a0,a0,310 # 800173d8 <bcache>
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	928080e7          	jalr	-1752(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032b2:	0001c497          	auipc	s1,0x1c
    800032b6:	3de4b483          	ld	s1,990(s1) # 8001f690 <bcache+0x82b8>
    800032ba:	0001c797          	auipc	a5,0x1c
    800032be:	38678793          	addi	a5,a5,902 # 8001f640 <bcache+0x8268>
    800032c2:	02f48f63          	beq	s1,a5,80003300 <bread+0x70>
    800032c6:	873e                	mv	a4,a5
    800032c8:	a021                	j	800032d0 <bread+0x40>
    800032ca:	68a4                	ld	s1,80(s1)
    800032cc:	02e48a63          	beq	s1,a4,80003300 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032d0:	449c                	lw	a5,8(s1)
    800032d2:	ff279ce3          	bne	a5,s2,800032ca <bread+0x3a>
    800032d6:	44dc                	lw	a5,12(s1)
    800032d8:	ff3799e3          	bne	a5,s3,800032ca <bread+0x3a>
      b->refcnt++;
    800032dc:	40bc                	lw	a5,64(s1)
    800032de:	2785                	addiw	a5,a5,1
    800032e0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032e2:	00014517          	auipc	a0,0x14
    800032e6:	0f650513          	addi	a0,a0,246 # 800173d8 <bcache>
    800032ea:	ffffe097          	auipc	ra,0xffffe
    800032ee:	99c080e7          	jalr	-1636(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800032f2:	01048513          	addi	a0,s1,16
    800032f6:	00001097          	auipc	ra,0x1
    800032fa:	440080e7          	jalr	1088(ra) # 80004736 <acquiresleep>
      return b;
    800032fe:	a8b9                	j	8000335c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003300:	0001c497          	auipc	s1,0x1c
    80003304:	3884b483          	ld	s1,904(s1) # 8001f688 <bcache+0x82b0>
    80003308:	0001c797          	auipc	a5,0x1c
    8000330c:	33878793          	addi	a5,a5,824 # 8001f640 <bcache+0x8268>
    80003310:	00f48863          	beq	s1,a5,80003320 <bread+0x90>
    80003314:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003316:	40bc                	lw	a5,64(s1)
    80003318:	cf81                	beqz	a5,80003330 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000331a:	64a4                	ld	s1,72(s1)
    8000331c:	fee49de3          	bne	s1,a4,80003316 <bread+0x86>
  panic("bget: no buffers");
    80003320:	00005517          	auipc	a0,0x5
    80003324:	23050513          	addi	a0,a0,560 # 80008550 <syscalls+0xe0>
    80003328:	ffffd097          	auipc	ra,0xffffd
    8000332c:	214080e7          	jalr	532(ra) # 8000053c <panic>
      b->dev = dev;
    80003330:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003334:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003338:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000333c:	4785                	li	a5,1
    8000333e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003340:	00014517          	auipc	a0,0x14
    80003344:	09850513          	addi	a0,a0,152 # 800173d8 <bcache>
    80003348:	ffffe097          	auipc	ra,0xffffe
    8000334c:	93e080e7          	jalr	-1730(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003350:	01048513          	addi	a0,s1,16
    80003354:	00001097          	auipc	ra,0x1
    80003358:	3e2080e7          	jalr	994(ra) # 80004736 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000335c:	409c                	lw	a5,0(s1)
    8000335e:	cb89                	beqz	a5,80003370 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003360:	8526                	mv	a0,s1
    80003362:	70a2                	ld	ra,40(sp)
    80003364:	7402                	ld	s0,32(sp)
    80003366:	64e2                	ld	s1,24(sp)
    80003368:	6942                	ld	s2,16(sp)
    8000336a:	69a2                	ld	s3,8(sp)
    8000336c:	6145                	addi	sp,sp,48
    8000336e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003370:	4581                	li	a1,0
    80003372:	8526                	mv	a0,s1
    80003374:	00003097          	auipc	ra,0x3
    80003378:	f8e080e7          	jalr	-114(ra) # 80006302 <virtio_disk_rw>
    b->valid = 1;
    8000337c:	4785                	li	a5,1
    8000337e:	c09c                	sw	a5,0(s1)
  return b;
    80003380:	b7c5                	j	80003360 <bread+0xd0>

0000000080003382 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003382:	1101                	addi	sp,sp,-32
    80003384:	ec06                	sd	ra,24(sp)
    80003386:	e822                	sd	s0,16(sp)
    80003388:	e426                	sd	s1,8(sp)
    8000338a:	1000                	addi	s0,sp,32
    8000338c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000338e:	0541                	addi	a0,a0,16
    80003390:	00001097          	auipc	ra,0x1
    80003394:	440080e7          	jalr	1088(ra) # 800047d0 <holdingsleep>
    80003398:	cd01                	beqz	a0,800033b0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000339a:	4585                	li	a1,1
    8000339c:	8526                	mv	a0,s1
    8000339e:	00003097          	auipc	ra,0x3
    800033a2:	f64080e7          	jalr	-156(ra) # 80006302 <virtio_disk_rw>
}
    800033a6:	60e2                	ld	ra,24(sp)
    800033a8:	6442                	ld	s0,16(sp)
    800033aa:	64a2                	ld	s1,8(sp)
    800033ac:	6105                	addi	sp,sp,32
    800033ae:	8082                	ret
    panic("bwrite");
    800033b0:	00005517          	auipc	a0,0x5
    800033b4:	1b850513          	addi	a0,a0,440 # 80008568 <syscalls+0xf8>
    800033b8:	ffffd097          	auipc	ra,0xffffd
    800033bc:	184080e7          	jalr	388(ra) # 8000053c <panic>

00000000800033c0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033c0:	1101                	addi	sp,sp,-32
    800033c2:	ec06                	sd	ra,24(sp)
    800033c4:	e822                	sd	s0,16(sp)
    800033c6:	e426                	sd	s1,8(sp)
    800033c8:	e04a                	sd	s2,0(sp)
    800033ca:	1000                	addi	s0,sp,32
    800033cc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033ce:	01050913          	addi	s2,a0,16
    800033d2:	854a                	mv	a0,s2
    800033d4:	00001097          	auipc	ra,0x1
    800033d8:	3fc080e7          	jalr	1020(ra) # 800047d0 <holdingsleep>
    800033dc:	c925                	beqz	a0,8000344c <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800033de:	854a                	mv	a0,s2
    800033e0:	00001097          	auipc	ra,0x1
    800033e4:	3ac080e7          	jalr	940(ra) # 8000478c <releasesleep>

  acquire(&bcache.lock);
    800033e8:	00014517          	auipc	a0,0x14
    800033ec:	ff050513          	addi	a0,a0,-16 # 800173d8 <bcache>
    800033f0:	ffffd097          	auipc	ra,0xffffd
    800033f4:	7e2080e7          	jalr	2018(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800033f8:	40bc                	lw	a5,64(s1)
    800033fa:	37fd                	addiw	a5,a5,-1
    800033fc:	0007871b          	sext.w	a4,a5
    80003400:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003402:	e71d                	bnez	a4,80003430 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003404:	68b8                	ld	a4,80(s1)
    80003406:	64bc                	ld	a5,72(s1)
    80003408:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000340a:	68b8                	ld	a4,80(s1)
    8000340c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000340e:	0001c797          	auipc	a5,0x1c
    80003412:	fca78793          	addi	a5,a5,-54 # 8001f3d8 <bcache+0x8000>
    80003416:	2b87b703          	ld	a4,696(a5)
    8000341a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000341c:	0001c717          	auipc	a4,0x1c
    80003420:	22470713          	addi	a4,a4,548 # 8001f640 <bcache+0x8268>
    80003424:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003426:	2b87b703          	ld	a4,696(a5)
    8000342a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000342c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003430:	00014517          	auipc	a0,0x14
    80003434:	fa850513          	addi	a0,a0,-88 # 800173d8 <bcache>
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	84e080e7          	jalr	-1970(ra) # 80000c86 <release>
}
    80003440:	60e2                	ld	ra,24(sp)
    80003442:	6442                	ld	s0,16(sp)
    80003444:	64a2                	ld	s1,8(sp)
    80003446:	6902                	ld	s2,0(sp)
    80003448:	6105                	addi	sp,sp,32
    8000344a:	8082                	ret
    panic("brelse");
    8000344c:	00005517          	auipc	a0,0x5
    80003450:	12450513          	addi	a0,a0,292 # 80008570 <syscalls+0x100>
    80003454:	ffffd097          	auipc	ra,0xffffd
    80003458:	0e8080e7          	jalr	232(ra) # 8000053c <panic>

000000008000345c <bpin>:

void
bpin(struct buf *b) {
    8000345c:	1101                	addi	sp,sp,-32
    8000345e:	ec06                	sd	ra,24(sp)
    80003460:	e822                	sd	s0,16(sp)
    80003462:	e426                	sd	s1,8(sp)
    80003464:	1000                	addi	s0,sp,32
    80003466:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003468:	00014517          	auipc	a0,0x14
    8000346c:	f7050513          	addi	a0,a0,-144 # 800173d8 <bcache>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	762080e7          	jalr	1890(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003478:	40bc                	lw	a5,64(s1)
    8000347a:	2785                	addiw	a5,a5,1
    8000347c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000347e:	00014517          	auipc	a0,0x14
    80003482:	f5a50513          	addi	a0,a0,-166 # 800173d8 <bcache>
    80003486:	ffffe097          	auipc	ra,0xffffe
    8000348a:	800080e7          	jalr	-2048(ra) # 80000c86 <release>
}
    8000348e:	60e2                	ld	ra,24(sp)
    80003490:	6442                	ld	s0,16(sp)
    80003492:	64a2                	ld	s1,8(sp)
    80003494:	6105                	addi	sp,sp,32
    80003496:	8082                	ret

0000000080003498 <bunpin>:

void
bunpin(struct buf *b) {
    80003498:	1101                	addi	sp,sp,-32
    8000349a:	ec06                	sd	ra,24(sp)
    8000349c:	e822                	sd	s0,16(sp)
    8000349e:	e426                	sd	s1,8(sp)
    800034a0:	1000                	addi	s0,sp,32
    800034a2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034a4:	00014517          	auipc	a0,0x14
    800034a8:	f3450513          	addi	a0,a0,-204 # 800173d8 <bcache>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	726080e7          	jalr	1830(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800034b4:	40bc                	lw	a5,64(s1)
    800034b6:	37fd                	addiw	a5,a5,-1
    800034b8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034ba:	00014517          	auipc	a0,0x14
    800034be:	f1e50513          	addi	a0,a0,-226 # 800173d8 <bcache>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	7c4080e7          	jalr	1988(ra) # 80000c86 <release>
}
    800034ca:	60e2                	ld	ra,24(sp)
    800034cc:	6442                	ld	s0,16(sp)
    800034ce:	64a2                	ld	s1,8(sp)
    800034d0:	6105                	addi	sp,sp,32
    800034d2:	8082                	ret

00000000800034d4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034d4:	1101                	addi	sp,sp,-32
    800034d6:	ec06                	sd	ra,24(sp)
    800034d8:	e822                	sd	s0,16(sp)
    800034da:	e426                	sd	s1,8(sp)
    800034dc:	e04a                	sd	s2,0(sp)
    800034de:	1000                	addi	s0,sp,32
    800034e0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034e2:	00d5d59b          	srliw	a1,a1,0xd
    800034e6:	0001c797          	auipc	a5,0x1c
    800034ea:	5ce7a783          	lw	a5,1486(a5) # 8001fab4 <sb+0x1c>
    800034ee:	9dbd                	addw	a1,a1,a5
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	da0080e7          	jalr	-608(ra) # 80003290 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034f8:	0074f713          	andi	a4,s1,7
    800034fc:	4785                	li	a5,1
    800034fe:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003502:	14ce                	slli	s1,s1,0x33
    80003504:	90d9                	srli	s1,s1,0x36
    80003506:	00950733          	add	a4,a0,s1
    8000350a:	05874703          	lbu	a4,88(a4)
    8000350e:	00e7f6b3          	and	a3,a5,a4
    80003512:	c69d                	beqz	a3,80003540 <bfree+0x6c>
    80003514:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003516:	94aa                	add	s1,s1,a0
    80003518:	fff7c793          	not	a5,a5
    8000351c:	8f7d                	and	a4,a4,a5
    8000351e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003522:	00001097          	auipc	ra,0x1
    80003526:	0f6080e7          	jalr	246(ra) # 80004618 <log_write>
  brelse(bp);
    8000352a:	854a                	mv	a0,s2
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	e94080e7          	jalr	-364(ra) # 800033c0 <brelse>
}
    80003534:	60e2                	ld	ra,24(sp)
    80003536:	6442                	ld	s0,16(sp)
    80003538:	64a2                	ld	s1,8(sp)
    8000353a:	6902                	ld	s2,0(sp)
    8000353c:	6105                	addi	sp,sp,32
    8000353e:	8082                	ret
    panic("freeing free block");
    80003540:	00005517          	auipc	a0,0x5
    80003544:	03850513          	addi	a0,a0,56 # 80008578 <syscalls+0x108>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	ff4080e7          	jalr	-12(ra) # 8000053c <panic>

0000000080003550 <balloc>:
{
    80003550:	711d                	addi	sp,sp,-96
    80003552:	ec86                	sd	ra,88(sp)
    80003554:	e8a2                	sd	s0,80(sp)
    80003556:	e4a6                	sd	s1,72(sp)
    80003558:	e0ca                	sd	s2,64(sp)
    8000355a:	fc4e                	sd	s3,56(sp)
    8000355c:	f852                	sd	s4,48(sp)
    8000355e:	f456                	sd	s5,40(sp)
    80003560:	f05a                	sd	s6,32(sp)
    80003562:	ec5e                	sd	s7,24(sp)
    80003564:	e862                	sd	s8,16(sp)
    80003566:	e466                	sd	s9,8(sp)
    80003568:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000356a:	0001c797          	auipc	a5,0x1c
    8000356e:	5327a783          	lw	a5,1330(a5) # 8001fa9c <sb+0x4>
    80003572:	cff5                	beqz	a5,8000366e <balloc+0x11e>
    80003574:	8baa                	mv	s7,a0
    80003576:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003578:	0001cb17          	auipc	s6,0x1c
    8000357c:	520b0b13          	addi	s6,s6,1312 # 8001fa98 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003580:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003582:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003584:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003586:	6c89                	lui	s9,0x2
    80003588:	a061                	j	80003610 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000358a:	97ca                	add	a5,a5,s2
    8000358c:	8e55                	or	a2,a2,a3
    8000358e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003592:	854a                	mv	a0,s2
    80003594:	00001097          	auipc	ra,0x1
    80003598:	084080e7          	jalr	132(ra) # 80004618 <log_write>
        brelse(bp);
    8000359c:	854a                	mv	a0,s2
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	e22080e7          	jalr	-478(ra) # 800033c0 <brelse>
  bp = bread(dev, bno);
    800035a6:	85a6                	mv	a1,s1
    800035a8:	855e                	mv	a0,s7
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	ce6080e7          	jalr	-794(ra) # 80003290 <bread>
    800035b2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035b4:	40000613          	li	a2,1024
    800035b8:	4581                	li	a1,0
    800035ba:	05850513          	addi	a0,a0,88
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	710080e7          	jalr	1808(ra) # 80000cce <memset>
  log_write(bp);
    800035c6:	854a                	mv	a0,s2
    800035c8:	00001097          	auipc	ra,0x1
    800035cc:	050080e7          	jalr	80(ra) # 80004618 <log_write>
  brelse(bp);
    800035d0:	854a                	mv	a0,s2
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	dee080e7          	jalr	-530(ra) # 800033c0 <brelse>
}
    800035da:	8526                	mv	a0,s1
    800035dc:	60e6                	ld	ra,88(sp)
    800035de:	6446                	ld	s0,80(sp)
    800035e0:	64a6                	ld	s1,72(sp)
    800035e2:	6906                	ld	s2,64(sp)
    800035e4:	79e2                	ld	s3,56(sp)
    800035e6:	7a42                	ld	s4,48(sp)
    800035e8:	7aa2                	ld	s5,40(sp)
    800035ea:	7b02                	ld	s6,32(sp)
    800035ec:	6be2                	ld	s7,24(sp)
    800035ee:	6c42                	ld	s8,16(sp)
    800035f0:	6ca2                	ld	s9,8(sp)
    800035f2:	6125                	addi	sp,sp,96
    800035f4:	8082                	ret
    brelse(bp);
    800035f6:	854a                	mv	a0,s2
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	dc8080e7          	jalr	-568(ra) # 800033c0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003600:	015c87bb          	addw	a5,s9,s5
    80003604:	00078a9b          	sext.w	s5,a5
    80003608:	004b2703          	lw	a4,4(s6)
    8000360c:	06eaf163          	bgeu	s5,a4,8000366e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003610:	41fad79b          	sraiw	a5,s5,0x1f
    80003614:	0137d79b          	srliw	a5,a5,0x13
    80003618:	015787bb          	addw	a5,a5,s5
    8000361c:	40d7d79b          	sraiw	a5,a5,0xd
    80003620:	01cb2583          	lw	a1,28(s6)
    80003624:	9dbd                	addw	a1,a1,a5
    80003626:	855e                	mv	a0,s7
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	c68080e7          	jalr	-920(ra) # 80003290 <bread>
    80003630:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003632:	004b2503          	lw	a0,4(s6)
    80003636:	000a849b          	sext.w	s1,s5
    8000363a:	8762                	mv	a4,s8
    8000363c:	faa4fde3          	bgeu	s1,a0,800035f6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003640:	00777693          	andi	a3,a4,7
    80003644:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003648:	41f7579b          	sraiw	a5,a4,0x1f
    8000364c:	01d7d79b          	srliw	a5,a5,0x1d
    80003650:	9fb9                	addw	a5,a5,a4
    80003652:	4037d79b          	sraiw	a5,a5,0x3
    80003656:	00f90633          	add	a2,s2,a5
    8000365a:	05864603          	lbu	a2,88(a2)
    8000365e:	00c6f5b3          	and	a1,a3,a2
    80003662:	d585                	beqz	a1,8000358a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003664:	2705                	addiw	a4,a4,1
    80003666:	2485                	addiw	s1,s1,1
    80003668:	fd471ae3          	bne	a4,s4,8000363c <balloc+0xec>
    8000366c:	b769                	j	800035f6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000366e:	00005517          	auipc	a0,0x5
    80003672:	f2250513          	addi	a0,a0,-222 # 80008590 <syscalls+0x120>
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	f10080e7          	jalr	-240(ra) # 80000586 <printf>
  return 0;
    8000367e:	4481                	li	s1,0
    80003680:	bfa9                	j	800035da <balloc+0x8a>

0000000080003682 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003682:	7179                	addi	sp,sp,-48
    80003684:	f406                	sd	ra,40(sp)
    80003686:	f022                	sd	s0,32(sp)
    80003688:	ec26                	sd	s1,24(sp)
    8000368a:	e84a                	sd	s2,16(sp)
    8000368c:	e44e                	sd	s3,8(sp)
    8000368e:	e052                	sd	s4,0(sp)
    80003690:	1800                	addi	s0,sp,48
    80003692:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003694:	47ad                	li	a5,11
    80003696:	02b7e863          	bltu	a5,a1,800036c6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000369a:	02059793          	slli	a5,a1,0x20
    8000369e:	01e7d593          	srli	a1,a5,0x1e
    800036a2:	00b504b3          	add	s1,a0,a1
    800036a6:	0504a903          	lw	s2,80(s1)
    800036aa:	06091e63          	bnez	s2,80003726 <bmap+0xa4>
      addr = balloc(ip->dev);
    800036ae:	4108                	lw	a0,0(a0)
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	ea0080e7          	jalr	-352(ra) # 80003550 <balloc>
    800036b8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800036bc:	06090563          	beqz	s2,80003726 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800036c0:	0524a823          	sw	s2,80(s1)
    800036c4:	a08d                	j	80003726 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800036c6:	ff45849b          	addiw	s1,a1,-12
    800036ca:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036ce:	0ff00793          	li	a5,255
    800036d2:	08e7e563          	bltu	a5,a4,8000375c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800036d6:	08052903          	lw	s2,128(a0)
    800036da:	00091d63          	bnez	s2,800036f4 <bmap+0x72>
      addr = balloc(ip->dev);
    800036de:	4108                	lw	a0,0(a0)
    800036e0:	00000097          	auipc	ra,0x0
    800036e4:	e70080e7          	jalr	-400(ra) # 80003550 <balloc>
    800036e8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800036ec:	02090d63          	beqz	s2,80003726 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800036f0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800036f4:	85ca                	mv	a1,s2
    800036f6:	0009a503          	lw	a0,0(s3)
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	b96080e7          	jalr	-1130(ra) # 80003290 <bread>
    80003702:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003704:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003708:	02049713          	slli	a4,s1,0x20
    8000370c:	01e75593          	srli	a1,a4,0x1e
    80003710:	00b784b3          	add	s1,a5,a1
    80003714:	0004a903          	lw	s2,0(s1)
    80003718:	02090063          	beqz	s2,80003738 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000371c:	8552                	mv	a0,s4
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	ca2080e7          	jalr	-862(ra) # 800033c0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003726:	854a                	mv	a0,s2
    80003728:	70a2                	ld	ra,40(sp)
    8000372a:	7402                	ld	s0,32(sp)
    8000372c:	64e2                	ld	s1,24(sp)
    8000372e:	6942                	ld	s2,16(sp)
    80003730:	69a2                	ld	s3,8(sp)
    80003732:	6a02                	ld	s4,0(sp)
    80003734:	6145                	addi	sp,sp,48
    80003736:	8082                	ret
      addr = balloc(ip->dev);
    80003738:	0009a503          	lw	a0,0(s3)
    8000373c:	00000097          	auipc	ra,0x0
    80003740:	e14080e7          	jalr	-492(ra) # 80003550 <balloc>
    80003744:	0005091b          	sext.w	s2,a0
      if(addr){
    80003748:	fc090ae3          	beqz	s2,8000371c <bmap+0x9a>
        a[bn] = addr;
    8000374c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003750:	8552                	mv	a0,s4
    80003752:	00001097          	auipc	ra,0x1
    80003756:	ec6080e7          	jalr	-314(ra) # 80004618 <log_write>
    8000375a:	b7c9                	j	8000371c <bmap+0x9a>
  panic("bmap: out of range");
    8000375c:	00005517          	auipc	a0,0x5
    80003760:	e4c50513          	addi	a0,a0,-436 # 800085a8 <syscalls+0x138>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	dd8080e7          	jalr	-552(ra) # 8000053c <panic>

000000008000376c <iget>:
{
    8000376c:	7179                	addi	sp,sp,-48
    8000376e:	f406                	sd	ra,40(sp)
    80003770:	f022                	sd	s0,32(sp)
    80003772:	ec26                	sd	s1,24(sp)
    80003774:	e84a                	sd	s2,16(sp)
    80003776:	e44e                	sd	s3,8(sp)
    80003778:	e052                	sd	s4,0(sp)
    8000377a:	1800                	addi	s0,sp,48
    8000377c:	89aa                	mv	s3,a0
    8000377e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003780:	0001c517          	auipc	a0,0x1c
    80003784:	33850513          	addi	a0,a0,824 # 8001fab8 <itable>
    80003788:	ffffd097          	auipc	ra,0xffffd
    8000378c:	44a080e7          	jalr	1098(ra) # 80000bd2 <acquire>
  empty = 0;
    80003790:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003792:	0001c497          	auipc	s1,0x1c
    80003796:	33e48493          	addi	s1,s1,830 # 8001fad0 <itable+0x18>
    8000379a:	0001e697          	auipc	a3,0x1e
    8000379e:	dc668693          	addi	a3,a3,-570 # 80021560 <log>
    800037a2:	a039                	j	800037b0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037a4:	02090b63          	beqz	s2,800037da <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037a8:	08848493          	addi	s1,s1,136
    800037ac:	02d48a63          	beq	s1,a3,800037e0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037b0:	449c                	lw	a5,8(s1)
    800037b2:	fef059e3          	blez	a5,800037a4 <iget+0x38>
    800037b6:	4098                	lw	a4,0(s1)
    800037b8:	ff3716e3          	bne	a4,s3,800037a4 <iget+0x38>
    800037bc:	40d8                	lw	a4,4(s1)
    800037be:	ff4713e3          	bne	a4,s4,800037a4 <iget+0x38>
      ip->ref++;
    800037c2:	2785                	addiw	a5,a5,1
    800037c4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037c6:	0001c517          	auipc	a0,0x1c
    800037ca:	2f250513          	addi	a0,a0,754 # 8001fab8 <itable>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	4b8080e7          	jalr	1208(ra) # 80000c86 <release>
      return ip;
    800037d6:	8926                	mv	s2,s1
    800037d8:	a03d                	j	80003806 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037da:	f7f9                	bnez	a5,800037a8 <iget+0x3c>
    800037dc:	8926                	mv	s2,s1
    800037de:	b7e9                	j	800037a8 <iget+0x3c>
  if(empty == 0)
    800037e0:	02090c63          	beqz	s2,80003818 <iget+0xac>
  ip->dev = dev;
    800037e4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800037e8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800037ec:	4785                	li	a5,1
    800037ee:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037f2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037f6:	0001c517          	auipc	a0,0x1c
    800037fa:	2c250513          	addi	a0,a0,706 # 8001fab8 <itable>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	488080e7          	jalr	1160(ra) # 80000c86 <release>
}
    80003806:	854a                	mv	a0,s2
    80003808:	70a2                	ld	ra,40(sp)
    8000380a:	7402                	ld	s0,32(sp)
    8000380c:	64e2                	ld	s1,24(sp)
    8000380e:	6942                	ld	s2,16(sp)
    80003810:	69a2                	ld	s3,8(sp)
    80003812:	6a02                	ld	s4,0(sp)
    80003814:	6145                	addi	sp,sp,48
    80003816:	8082                	ret
    panic("iget: no inodes");
    80003818:	00005517          	auipc	a0,0x5
    8000381c:	da850513          	addi	a0,a0,-600 # 800085c0 <syscalls+0x150>
    80003820:	ffffd097          	auipc	ra,0xffffd
    80003824:	d1c080e7          	jalr	-740(ra) # 8000053c <panic>

0000000080003828 <fsinit>:
fsinit(int dev) {
    80003828:	7179                	addi	sp,sp,-48
    8000382a:	f406                	sd	ra,40(sp)
    8000382c:	f022                	sd	s0,32(sp)
    8000382e:	ec26                	sd	s1,24(sp)
    80003830:	e84a                	sd	s2,16(sp)
    80003832:	e44e                	sd	s3,8(sp)
    80003834:	1800                	addi	s0,sp,48
    80003836:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003838:	4585                	li	a1,1
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	a56080e7          	jalr	-1450(ra) # 80003290 <bread>
    80003842:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003844:	0001c997          	auipc	s3,0x1c
    80003848:	25498993          	addi	s3,s3,596 # 8001fa98 <sb>
    8000384c:	02000613          	li	a2,32
    80003850:	05850593          	addi	a1,a0,88
    80003854:	854e                	mv	a0,s3
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	4d4080e7          	jalr	1236(ra) # 80000d2a <memmove>
  brelse(bp);
    8000385e:	8526                	mv	a0,s1
    80003860:	00000097          	auipc	ra,0x0
    80003864:	b60080e7          	jalr	-1184(ra) # 800033c0 <brelse>
  if(sb.magic != FSMAGIC)
    80003868:	0009a703          	lw	a4,0(s3)
    8000386c:	102037b7          	lui	a5,0x10203
    80003870:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003874:	02f71263          	bne	a4,a5,80003898 <fsinit+0x70>
  initlog(dev, &sb);
    80003878:	0001c597          	auipc	a1,0x1c
    8000387c:	22058593          	addi	a1,a1,544 # 8001fa98 <sb>
    80003880:	854a                	mv	a0,s2
    80003882:	00001097          	auipc	ra,0x1
    80003886:	b2c080e7          	jalr	-1236(ra) # 800043ae <initlog>
}
    8000388a:	70a2                	ld	ra,40(sp)
    8000388c:	7402                	ld	s0,32(sp)
    8000388e:	64e2                	ld	s1,24(sp)
    80003890:	6942                	ld	s2,16(sp)
    80003892:	69a2                	ld	s3,8(sp)
    80003894:	6145                	addi	sp,sp,48
    80003896:	8082                	ret
    panic("invalid file system");
    80003898:	00005517          	auipc	a0,0x5
    8000389c:	d3850513          	addi	a0,a0,-712 # 800085d0 <syscalls+0x160>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	c9c080e7          	jalr	-868(ra) # 8000053c <panic>

00000000800038a8 <iinit>:
{
    800038a8:	7179                	addi	sp,sp,-48
    800038aa:	f406                	sd	ra,40(sp)
    800038ac:	f022                	sd	s0,32(sp)
    800038ae:	ec26                	sd	s1,24(sp)
    800038b0:	e84a                	sd	s2,16(sp)
    800038b2:	e44e                	sd	s3,8(sp)
    800038b4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038b6:	00005597          	auipc	a1,0x5
    800038ba:	d3258593          	addi	a1,a1,-718 # 800085e8 <syscalls+0x178>
    800038be:	0001c517          	auipc	a0,0x1c
    800038c2:	1fa50513          	addi	a0,a0,506 # 8001fab8 <itable>
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	27c080e7          	jalr	636(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038ce:	0001c497          	auipc	s1,0x1c
    800038d2:	21248493          	addi	s1,s1,530 # 8001fae0 <itable+0x28>
    800038d6:	0001e997          	auipc	s3,0x1e
    800038da:	c9a98993          	addi	s3,s3,-870 # 80021570 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038de:	00005917          	auipc	s2,0x5
    800038e2:	d1290913          	addi	s2,s2,-750 # 800085f0 <syscalls+0x180>
    800038e6:	85ca                	mv	a1,s2
    800038e8:	8526                	mv	a0,s1
    800038ea:	00001097          	auipc	ra,0x1
    800038ee:	e12080e7          	jalr	-494(ra) # 800046fc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038f2:	08848493          	addi	s1,s1,136
    800038f6:	ff3498e3          	bne	s1,s3,800038e6 <iinit+0x3e>
}
    800038fa:	70a2                	ld	ra,40(sp)
    800038fc:	7402                	ld	s0,32(sp)
    800038fe:	64e2                	ld	s1,24(sp)
    80003900:	6942                	ld	s2,16(sp)
    80003902:	69a2                	ld	s3,8(sp)
    80003904:	6145                	addi	sp,sp,48
    80003906:	8082                	ret

0000000080003908 <ialloc>:
{
    80003908:	7139                	addi	sp,sp,-64
    8000390a:	fc06                	sd	ra,56(sp)
    8000390c:	f822                	sd	s0,48(sp)
    8000390e:	f426                	sd	s1,40(sp)
    80003910:	f04a                	sd	s2,32(sp)
    80003912:	ec4e                	sd	s3,24(sp)
    80003914:	e852                	sd	s4,16(sp)
    80003916:	e456                	sd	s5,8(sp)
    80003918:	e05a                	sd	s6,0(sp)
    8000391a:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000391c:	0001c717          	auipc	a4,0x1c
    80003920:	18872703          	lw	a4,392(a4) # 8001faa4 <sb+0xc>
    80003924:	4785                	li	a5,1
    80003926:	04e7f863          	bgeu	a5,a4,80003976 <ialloc+0x6e>
    8000392a:	8aaa                	mv	s5,a0
    8000392c:	8b2e                	mv	s6,a1
    8000392e:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003930:	0001ca17          	auipc	s4,0x1c
    80003934:	168a0a13          	addi	s4,s4,360 # 8001fa98 <sb>
    80003938:	00495593          	srli	a1,s2,0x4
    8000393c:	018a2783          	lw	a5,24(s4)
    80003940:	9dbd                	addw	a1,a1,a5
    80003942:	8556                	mv	a0,s5
    80003944:	00000097          	auipc	ra,0x0
    80003948:	94c080e7          	jalr	-1716(ra) # 80003290 <bread>
    8000394c:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000394e:	05850993          	addi	s3,a0,88
    80003952:	00f97793          	andi	a5,s2,15
    80003956:	079a                	slli	a5,a5,0x6
    80003958:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000395a:	00099783          	lh	a5,0(s3)
    8000395e:	cf9d                	beqz	a5,8000399c <ialloc+0x94>
    brelse(bp);
    80003960:	00000097          	auipc	ra,0x0
    80003964:	a60080e7          	jalr	-1440(ra) # 800033c0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003968:	0905                	addi	s2,s2,1
    8000396a:	00ca2703          	lw	a4,12(s4)
    8000396e:	0009079b          	sext.w	a5,s2
    80003972:	fce7e3e3          	bltu	a5,a4,80003938 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003976:	00005517          	auipc	a0,0x5
    8000397a:	c8250513          	addi	a0,a0,-894 # 800085f8 <syscalls+0x188>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	c08080e7          	jalr	-1016(ra) # 80000586 <printf>
  return 0;
    80003986:	4501                	li	a0,0
}
    80003988:	70e2                	ld	ra,56(sp)
    8000398a:	7442                	ld	s0,48(sp)
    8000398c:	74a2                	ld	s1,40(sp)
    8000398e:	7902                	ld	s2,32(sp)
    80003990:	69e2                	ld	s3,24(sp)
    80003992:	6a42                	ld	s4,16(sp)
    80003994:	6aa2                	ld	s5,8(sp)
    80003996:	6b02                	ld	s6,0(sp)
    80003998:	6121                	addi	sp,sp,64
    8000399a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000399c:	04000613          	li	a2,64
    800039a0:	4581                	li	a1,0
    800039a2:	854e                	mv	a0,s3
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	32a080e7          	jalr	810(ra) # 80000cce <memset>
      dip->type = type;
    800039ac:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039b0:	8526                	mv	a0,s1
    800039b2:	00001097          	auipc	ra,0x1
    800039b6:	c66080e7          	jalr	-922(ra) # 80004618 <log_write>
      brelse(bp);
    800039ba:	8526                	mv	a0,s1
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	a04080e7          	jalr	-1532(ra) # 800033c0 <brelse>
      return iget(dev, inum);
    800039c4:	0009059b          	sext.w	a1,s2
    800039c8:	8556                	mv	a0,s5
    800039ca:	00000097          	auipc	ra,0x0
    800039ce:	da2080e7          	jalr	-606(ra) # 8000376c <iget>
    800039d2:	bf5d                	j	80003988 <ialloc+0x80>

00000000800039d4 <iupdate>:
{
    800039d4:	1101                	addi	sp,sp,-32
    800039d6:	ec06                	sd	ra,24(sp)
    800039d8:	e822                	sd	s0,16(sp)
    800039da:	e426                	sd	s1,8(sp)
    800039dc:	e04a                	sd	s2,0(sp)
    800039de:	1000                	addi	s0,sp,32
    800039e0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039e2:	415c                	lw	a5,4(a0)
    800039e4:	0047d79b          	srliw	a5,a5,0x4
    800039e8:	0001c597          	auipc	a1,0x1c
    800039ec:	0c85a583          	lw	a1,200(a1) # 8001fab0 <sb+0x18>
    800039f0:	9dbd                	addw	a1,a1,a5
    800039f2:	4108                	lw	a0,0(a0)
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	89c080e7          	jalr	-1892(ra) # 80003290 <bread>
    800039fc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039fe:	05850793          	addi	a5,a0,88
    80003a02:	40d8                	lw	a4,4(s1)
    80003a04:	8b3d                	andi	a4,a4,15
    80003a06:	071a                	slli	a4,a4,0x6
    80003a08:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a0a:	04449703          	lh	a4,68(s1)
    80003a0e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a12:	04649703          	lh	a4,70(s1)
    80003a16:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a1a:	04849703          	lh	a4,72(s1)
    80003a1e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a22:	04a49703          	lh	a4,74(s1)
    80003a26:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a2a:	44f8                	lw	a4,76(s1)
    80003a2c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a2e:	03400613          	li	a2,52
    80003a32:	05048593          	addi	a1,s1,80
    80003a36:	00c78513          	addi	a0,a5,12
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	2f0080e7          	jalr	752(ra) # 80000d2a <memmove>
  log_write(bp);
    80003a42:	854a                	mv	a0,s2
    80003a44:	00001097          	auipc	ra,0x1
    80003a48:	bd4080e7          	jalr	-1068(ra) # 80004618 <log_write>
  brelse(bp);
    80003a4c:	854a                	mv	a0,s2
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	972080e7          	jalr	-1678(ra) # 800033c0 <brelse>
}
    80003a56:	60e2                	ld	ra,24(sp)
    80003a58:	6442                	ld	s0,16(sp)
    80003a5a:	64a2                	ld	s1,8(sp)
    80003a5c:	6902                	ld	s2,0(sp)
    80003a5e:	6105                	addi	sp,sp,32
    80003a60:	8082                	ret

0000000080003a62 <idup>:
{
    80003a62:	1101                	addi	sp,sp,-32
    80003a64:	ec06                	sd	ra,24(sp)
    80003a66:	e822                	sd	s0,16(sp)
    80003a68:	e426                	sd	s1,8(sp)
    80003a6a:	1000                	addi	s0,sp,32
    80003a6c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a6e:	0001c517          	auipc	a0,0x1c
    80003a72:	04a50513          	addi	a0,a0,74 # 8001fab8 <itable>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	15c080e7          	jalr	348(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003a7e:	449c                	lw	a5,8(s1)
    80003a80:	2785                	addiw	a5,a5,1
    80003a82:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a84:	0001c517          	auipc	a0,0x1c
    80003a88:	03450513          	addi	a0,a0,52 # 8001fab8 <itable>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	1fa080e7          	jalr	506(ra) # 80000c86 <release>
}
    80003a94:	8526                	mv	a0,s1
    80003a96:	60e2                	ld	ra,24(sp)
    80003a98:	6442                	ld	s0,16(sp)
    80003a9a:	64a2                	ld	s1,8(sp)
    80003a9c:	6105                	addi	sp,sp,32
    80003a9e:	8082                	ret

0000000080003aa0 <ilock>:
{
    80003aa0:	1101                	addi	sp,sp,-32
    80003aa2:	ec06                	sd	ra,24(sp)
    80003aa4:	e822                	sd	s0,16(sp)
    80003aa6:	e426                	sd	s1,8(sp)
    80003aa8:	e04a                	sd	s2,0(sp)
    80003aaa:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003aac:	c115                	beqz	a0,80003ad0 <ilock+0x30>
    80003aae:	84aa                	mv	s1,a0
    80003ab0:	451c                	lw	a5,8(a0)
    80003ab2:	00f05f63          	blez	a5,80003ad0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ab6:	0541                	addi	a0,a0,16
    80003ab8:	00001097          	auipc	ra,0x1
    80003abc:	c7e080e7          	jalr	-898(ra) # 80004736 <acquiresleep>
  if(ip->valid == 0){
    80003ac0:	40bc                	lw	a5,64(s1)
    80003ac2:	cf99                	beqz	a5,80003ae0 <ilock+0x40>
}
    80003ac4:	60e2                	ld	ra,24(sp)
    80003ac6:	6442                	ld	s0,16(sp)
    80003ac8:	64a2                	ld	s1,8(sp)
    80003aca:	6902                	ld	s2,0(sp)
    80003acc:	6105                	addi	sp,sp,32
    80003ace:	8082                	ret
    panic("ilock");
    80003ad0:	00005517          	auipc	a0,0x5
    80003ad4:	b4050513          	addi	a0,a0,-1216 # 80008610 <syscalls+0x1a0>
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	a64080e7          	jalr	-1436(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ae0:	40dc                	lw	a5,4(s1)
    80003ae2:	0047d79b          	srliw	a5,a5,0x4
    80003ae6:	0001c597          	auipc	a1,0x1c
    80003aea:	fca5a583          	lw	a1,-54(a1) # 8001fab0 <sb+0x18>
    80003aee:	9dbd                	addw	a1,a1,a5
    80003af0:	4088                	lw	a0,0(s1)
    80003af2:	fffff097          	auipc	ra,0xfffff
    80003af6:	79e080e7          	jalr	1950(ra) # 80003290 <bread>
    80003afa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003afc:	05850593          	addi	a1,a0,88
    80003b00:	40dc                	lw	a5,4(s1)
    80003b02:	8bbd                	andi	a5,a5,15
    80003b04:	079a                	slli	a5,a5,0x6
    80003b06:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b08:	00059783          	lh	a5,0(a1)
    80003b0c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b10:	00259783          	lh	a5,2(a1)
    80003b14:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b18:	00459783          	lh	a5,4(a1)
    80003b1c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b20:	00659783          	lh	a5,6(a1)
    80003b24:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b28:	459c                	lw	a5,8(a1)
    80003b2a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b2c:	03400613          	li	a2,52
    80003b30:	05b1                	addi	a1,a1,12
    80003b32:	05048513          	addi	a0,s1,80
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	1f4080e7          	jalr	500(ra) # 80000d2a <memmove>
    brelse(bp);
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	880080e7          	jalr	-1920(ra) # 800033c0 <brelse>
    ip->valid = 1;
    80003b48:	4785                	li	a5,1
    80003b4a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b4c:	04449783          	lh	a5,68(s1)
    80003b50:	fbb5                	bnez	a5,80003ac4 <ilock+0x24>
      panic("ilock: no type");
    80003b52:	00005517          	auipc	a0,0x5
    80003b56:	ac650513          	addi	a0,a0,-1338 # 80008618 <syscalls+0x1a8>
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	9e2080e7          	jalr	-1566(ra) # 8000053c <panic>

0000000080003b62 <iunlock>:
{
    80003b62:	1101                	addi	sp,sp,-32
    80003b64:	ec06                	sd	ra,24(sp)
    80003b66:	e822                	sd	s0,16(sp)
    80003b68:	e426                	sd	s1,8(sp)
    80003b6a:	e04a                	sd	s2,0(sp)
    80003b6c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b6e:	c905                	beqz	a0,80003b9e <iunlock+0x3c>
    80003b70:	84aa                	mv	s1,a0
    80003b72:	01050913          	addi	s2,a0,16
    80003b76:	854a                	mv	a0,s2
    80003b78:	00001097          	auipc	ra,0x1
    80003b7c:	c58080e7          	jalr	-936(ra) # 800047d0 <holdingsleep>
    80003b80:	cd19                	beqz	a0,80003b9e <iunlock+0x3c>
    80003b82:	449c                	lw	a5,8(s1)
    80003b84:	00f05d63          	blez	a5,80003b9e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b88:	854a                	mv	a0,s2
    80003b8a:	00001097          	auipc	ra,0x1
    80003b8e:	c02080e7          	jalr	-1022(ra) # 8000478c <releasesleep>
}
    80003b92:	60e2                	ld	ra,24(sp)
    80003b94:	6442                	ld	s0,16(sp)
    80003b96:	64a2                	ld	s1,8(sp)
    80003b98:	6902                	ld	s2,0(sp)
    80003b9a:	6105                	addi	sp,sp,32
    80003b9c:	8082                	ret
    panic("iunlock");
    80003b9e:	00005517          	auipc	a0,0x5
    80003ba2:	a8a50513          	addi	a0,a0,-1398 # 80008628 <syscalls+0x1b8>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	996080e7          	jalr	-1642(ra) # 8000053c <panic>

0000000080003bae <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bae:	7179                	addi	sp,sp,-48
    80003bb0:	f406                	sd	ra,40(sp)
    80003bb2:	f022                	sd	s0,32(sp)
    80003bb4:	ec26                	sd	s1,24(sp)
    80003bb6:	e84a                	sd	s2,16(sp)
    80003bb8:	e44e                	sd	s3,8(sp)
    80003bba:	e052                	sd	s4,0(sp)
    80003bbc:	1800                	addi	s0,sp,48
    80003bbe:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003bc0:	05050493          	addi	s1,a0,80
    80003bc4:	08050913          	addi	s2,a0,128
    80003bc8:	a021                	j	80003bd0 <itrunc+0x22>
    80003bca:	0491                	addi	s1,s1,4
    80003bcc:	01248d63          	beq	s1,s2,80003be6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003bd0:	408c                	lw	a1,0(s1)
    80003bd2:	dde5                	beqz	a1,80003bca <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003bd4:	0009a503          	lw	a0,0(s3)
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	8fc080e7          	jalr	-1796(ra) # 800034d4 <bfree>
      ip->addrs[i] = 0;
    80003be0:	0004a023          	sw	zero,0(s1)
    80003be4:	b7dd                	j	80003bca <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003be6:	0809a583          	lw	a1,128(s3)
    80003bea:	e185                	bnez	a1,80003c0a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003bec:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003bf0:	854e                	mv	a0,s3
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	de2080e7          	jalr	-542(ra) # 800039d4 <iupdate>
}
    80003bfa:	70a2                	ld	ra,40(sp)
    80003bfc:	7402                	ld	s0,32(sp)
    80003bfe:	64e2                	ld	s1,24(sp)
    80003c00:	6942                	ld	s2,16(sp)
    80003c02:	69a2                	ld	s3,8(sp)
    80003c04:	6a02                	ld	s4,0(sp)
    80003c06:	6145                	addi	sp,sp,48
    80003c08:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c0a:	0009a503          	lw	a0,0(s3)
    80003c0e:	fffff097          	auipc	ra,0xfffff
    80003c12:	682080e7          	jalr	1666(ra) # 80003290 <bread>
    80003c16:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c18:	05850493          	addi	s1,a0,88
    80003c1c:	45850913          	addi	s2,a0,1112
    80003c20:	a021                	j	80003c28 <itrunc+0x7a>
    80003c22:	0491                	addi	s1,s1,4
    80003c24:	01248b63          	beq	s1,s2,80003c3a <itrunc+0x8c>
      if(a[j])
    80003c28:	408c                	lw	a1,0(s1)
    80003c2a:	dde5                	beqz	a1,80003c22 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c2c:	0009a503          	lw	a0,0(s3)
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	8a4080e7          	jalr	-1884(ra) # 800034d4 <bfree>
    80003c38:	b7ed                	j	80003c22 <itrunc+0x74>
    brelse(bp);
    80003c3a:	8552                	mv	a0,s4
    80003c3c:	fffff097          	auipc	ra,0xfffff
    80003c40:	784080e7          	jalr	1924(ra) # 800033c0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c44:	0809a583          	lw	a1,128(s3)
    80003c48:	0009a503          	lw	a0,0(s3)
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	888080e7          	jalr	-1912(ra) # 800034d4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c54:	0809a023          	sw	zero,128(s3)
    80003c58:	bf51                	j	80003bec <itrunc+0x3e>

0000000080003c5a <iput>:
{
    80003c5a:	1101                	addi	sp,sp,-32
    80003c5c:	ec06                	sd	ra,24(sp)
    80003c5e:	e822                	sd	s0,16(sp)
    80003c60:	e426                	sd	s1,8(sp)
    80003c62:	e04a                	sd	s2,0(sp)
    80003c64:	1000                	addi	s0,sp,32
    80003c66:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c68:	0001c517          	auipc	a0,0x1c
    80003c6c:	e5050513          	addi	a0,a0,-432 # 8001fab8 <itable>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	f62080e7          	jalr	-158(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c78:	4498                	lw	a4,8(s1)
    80003c7a:	4785                	li	a5,1
    80003c7c:	02f70363          	beq	a4,a5,80003ca2 <iput+0x48>
  ip->ref--;
    80003c80:	449c                	lw	a5,8(s1)
    80003c82:	37fd                	addiw	a5,a5,-1
    80003c84:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c86:	0001c517          	auipc	a0,0x1c
    80003c8a:	e3250513          	addi	a0,a0,-462 # 8001fab8 <itable>
    80003c8e:	ffffd097          	auipc	ra,0xffffd
    80003c92:	ff8080e7          	jalr	-8(ra) # 80000c86 <release>
}
    80003c96:	60e2                	ld	ra,24(sp)
    80003c98:	6442                	ld	s0,16(sp)
    80003c9a:	64a2                	ld	s1,8(sp)
    80003c9c:	6902                	ld	s2,0(sp)
    80003c9e:	6105                	addi	sp,sp,32
    80003ca0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ca2:	40bc                	lw	a5,64(s1)
    80003ca4:	dff1                	beqz	a5,80003c80 <iput+0x26>
    80003ca6:	04a49783          	lh	a5,74(s1)
    80003caa:	fbf9                	bnez	a5,80003c80 <iput+0x26>
    acquiresleep(&ip->lock);
    80003cac:	01048913          	addi	s2,s1,16
    80003cb0:	854a                	mv	a0,s2
    80003cb2:	00001097          	auipc	ra,0x1
    80003cb6:	a84080e7          	jalr	-1404(ra) # 80004736 <acquiresleep>
    release(&itable.lock);
    80003cba:	0001c517          	auipc	a0,0x1c
    80003cbe:	dfe50513          	addi	a0,a0,-514 # 8001fab8 <itable>
    80003cc2:	ffffd097          	auipc	ra,0xffffd
    80003cc6:	fc4080e7          	jalr	-60(ra) # 80000c86 <release>
    itrunc(ip);
    80003cca:	8526                	mv	a0,s1
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	ee2080e7          	jalr	-286(ra) # 80003bae <itrunc>
    ip->type = 0;
    80003cd4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003cd8:	8526                	mv	a0,s1
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	cfa080e7          	jalr	-774(ra) # 800039d4 <iupdate>
    ip->valid = 0;
    80003ce2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	00001097          	auipc	ra,0x1
    80003cec:	aa4080e7          	jalr	-1372(ra) # 8000478c <releasesleep>
    acquire(&itable.lock);
    80003cf0:	0001c517          	auipc	a0,0x1c
    80003cf4:	dc850513          	addi	a0,a0,-568 # 8001fab8 <itable>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	eda080e7          	jalr	-294(ra) # 80000bd2 <acquire>
    80003d00:	b741                	j	80003c80 <iput+0x26>

0000000080003d02 <iunlockput>:
{
    80003d02:	1101                	addi	sp,sp,-32
    80003d04:	ec06                	sd	ra,24(sp)
    80003d06:	e822                	sd	s0,16(sp)
    80003d08:	e426                	sd	s1,8(sp)
    80003d0a:	1000                	addi	s0,sp,32
    80003d0c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	e54080e7          	jalr	-428(ra) # 80003b62 <iunlock>
  iput(ip);
    80003d16:	8526                	mv	a0,s1
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	f42080e7          	jalr	-190(ra) # 80003c5a <iput>
}
    80003d20:	60e2                	ld	ra,24(sp)
    80003d22:	6442                	ld	s0,16(sp)
    80003d24:	64a2                	ld	s1,8(sp)
    80003d26:	6105                	addi	sp,sp,32
    80003d28:	8082                	ret

0000000080003d2a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d2a:	1141                	addi	sp,sp,-16
    80003d2c:	e422                	sd	s0,8(sp)
    80003d2e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d30:	411c                	lw	a5,0(a0)
    80003d32:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d34:	415c                	lw	a5,4(a0)
    80003d36:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d38:	04451783          	lh	a5,68(a0)
    80003d3c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d40:	04a51783          	lh	a5,74(a0)
    80003d44:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d48:	04c56783          	lwu	a5,76(a0)
    80003d4c:	e99c                	sd	a5,16(a1)
}
    80003d4e:	6422                	ld	s0,8(sp)
    80003d50:	0141                	addi	sp,sp,16
    80003d52:	8082                	ret

0000000080003d54 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d54:	457c                	lw	a5,76(a0)
    80003d56:	0ed7e963          	bltu	a5,a3,80003e48 <readi+0xf4>
{
    80003d5a:	7159                	addi	sp,sp,-112
    80003d5c:	f486                	sd	ra,104(sp)
    80003d5e:	f0a2                	sd	s0,96(sp)
    80003d60:	eca6                	sd	s1,88(sp)
    80003d62:	e8ca                	sd	s2,80(sp)
    80003d64:	e4ce                	sd	s3,72(sp)
    80003d66:	e0d2                	sd	s4,64(sp)
    80003d68:	fc56                	sd	s5,56(sp)
    80003d6a:	f85a                	sd	s6,48(sp)
    80003d6c:	f45e                	sd	s7,40(sp)
    80003d6e:	f062                	sd	s8,32(sp)
    80003d70:	ec66                	sd	s9,24(sp)
    80003d72:	e86a                	sd	s10,16(sp)
    80003d74:	e46e                	sd	s11,8(sp)
    80003d76:	1880                	addi	s0,sp,112
    80003d78:	8b2a                	mv	s6,a0
    80003d7a:	8bae                	mv	s7,a1
    80003d7c:	8a32                	mv	s4,a2
    80003d7e:	84b6                	mv	s1,a3
    80003d80:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d82:	9f35                	addw	a4,a4,a3
    return 0;
    80003d84:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d86:	0ad76063          	bltu	a4,a3,80003e26 <readi+0xd2>
  if(off + n > ip->size)
    80003d8a:	00e7f463          	bgeu	a5,a4,80003d92 <readi+0x3e>
    n = ip->size - off;
    80003d8e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d92:	0a0a8963          	beqz	s5,80003e44 <readi+0xf0>
    80003d96:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d98:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d9c:	5c7d                	li	s8,-1
    80003d9e:	a82d                	j	80003dd8 <readi+0x84>
    80003da0:	020d1d93          	slli	s11,s10,0x20
    80003da4:	020ddd93          	srli	s11,s11,0x20
    80003da8:	05890613          	addi	a2,s2,88
    80003dac:	86ee                	mv	a3,s11
    80003dae:	963a                	add	a2,a2,a4
    80003db0:	85d2                	mv	a1,s4
    80003db2:	855e                	mv	a0,s7
    80003db4:	ffffe097          	auipc	ra,0xffffe
    80003db8:	7b6080e7          	jalr	1974(ra) # 8000256a <either_copyout>
    80003dbc:	05850d63          	beq	a0,s8,80003e16 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003dc0:	854a                	mv	a0,s2
    80003dc2:	fffff097          	auipc	ra,0xfffff
    80003dc6:	5fe080e7          	jalr	1534(ra) # 800033c0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dca:	013d09bb          	addw	s3,s10,s3
    80003dce:	009d04bb          	addw	s1,s10,s1
    80003dd2:	9a6e                	add	s4,s4,s11
    80003dd4:	0559f763          	bgeu	s3,s5,80003e22 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003dd8:	00a4d59b          	srliw	a1,s1,0xa
    80003ddc:	855a                	mv	a0,s6
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	8a4080e7          	jalr	-1884(ra) # 80003682 <bmap>
    80003de6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003dea:	cd85                	beqz	a1,80003e22 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003dec:	000b2503          	lw	a0,0(s6)
    80003df0:	fffff097          	auipc	ra,0xfffff
    80003df4:	4a0080e7          	jalr	1184(ra) # 80003290 <bread>
    80003df8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dfa:	3ff4f713          	andi	a4,s1,1023
    80003dfe:	40ec87bb          	subw	a5,s9,a4
    80003e02:	413a86bb          	subw	a3,s5,s3
    80003e06:	8d3e                	mv	s10,a5
    80003e08:	2781                	sext.w	a5,a5
    80003e0a:	0006861b          	sext.w	a2,a3
    80003e0e:	f8f679e3          	bgeu	a2,a5,80003da0 <readi+0x4c>
    80003e12:	8d36                	mv	s10,a3
    80003e14:	b771                	j	80003da0 <readi+0x4c>
      brelse(bp);
    80003e16:	854a                	mv	a0,s2
    80003e18:	fffff097          	auipc	ra,0xfffff
    80003e1c:	5a8080e7          	jalr	1448(ra) # 800033c0 <brelse>
      tot = -1;
    80003e20:	59fd                	li	s3,-1
  }
  return tot;
    80003e22:	0009851b          	sext.w	a0,s3
}
    80003e26:	70a6                	ld	ra,104(sp)
    80003e28:	7406                	ld	s0,96(sp)
    80003e2a:	64e6                	ld	s1,88(sp)
    80003e2c:	6946                	ld	s2,80(sp)
    80003e2e:	69a6                	ld	s3,72(sp)
    80003e30:	6a06                	ld	s4,64(sp)
    80003e32:	7ae2                	ld	s5,56(sp)
    80003e34:	7b42                	ld	s6,48(sp)
    80003e36:	7ba2                	ld	s7,40(sp)
    80003e38:	7c02                	ld	s8,32(sp)
    80003e3a:	6ce2                	ld	s9,24(sp)
    80003e3c:	6d42                	ld	s10,16(sp)
    80003e3e:	6da2                	ld	s11,8(sp)
    80003e40:	6165                	addi	sp,sp,112
    80003e42:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e44:	89d6                	mv	s3,s5
    80003e46:	bff1                	j	80003e22 <readi+0xce>
    return 0;
    80003e48:	4501                	li	a0,0
}
    80003e4a:	8082                	ret

0000000080003e4c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e4c:	457c                	lw	a5,76(a0)
    80003e4e:	10d7e863          	bltu	a5,a3,80003f5e <writei+0x112>
{
    80003e52:	7159                	addi	sp,sp,-112
    80003e54:	f486                	sd	ra,104(sp)
    80003e56:	f0a2                	sd	s0,96(sp)
    80003e58:	eca6                	sd	s1,88(sp)
    80003e5a:	e8ca                	sd	s2,80(sp)
    80003e5c:	e4ce                	sd	s3,72(sp)
    80003e5e:	e0d2                	sd	s4,64(sp)
    80003e60:	fc56                	sd	s5,56(sp)
    80003e62:	f85a                	sd	s6,48(sp)
    80003e64:	f45e                	sd	s7,40(sp)
    80003e66:	f062                	sd	s8,32(sp)
    80003e68:	ec66                	sd	s9,24(sp)
    80003e6a:	e86a                	sd	s10,16(sp)
    80003e6c:	e46e                	sd	s11,8(sp)
    80003e6e:	1880                	addi	s0,sp,112
    80003e70:	8aaa                	mv	s5,a0
    80003e72:	8bae                	mv	s7,a1
    80003e74:	8a32                	mv	s4,a2
    80003e76:	8936                	mv	s2,a3
    80003e78:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e7a:	00e687bb          	addw	a5,a3,a4
    80003e7e:	0ed7e263          	bltu	a5,a3,80003f62 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e82:	00043737          	lui	a4,0x43
    80003e86:	0ef76063          	bltu	a4,a5,80003f66 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e8a:	0c0b0863          	beqz	s6,80003f5a <writei+0x10e>
    80003e8e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e90:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e94:	5c7d                	li	s8,-1
    80003e96:	a091                	j	80003eda <writei+0x8e>
    80003e98:	020d1d93          	slli	s11,s10,0x20
    80003e9c:	020ddd93          	srli	s11,s11,0x20
    80003ea0:	05848513          	addi	a0,s1,88
    80003ea4:	86ee                	mv	a3,s11
    80003ea6:	8652                	mv	a2,s4
    80003ea8:	85de                	mv	a1,s7
    80003eaa:	953a                	add	a0,a0,a4
    80003eac:	ffffe097          	auipc	ra,0xffffe
    80003eb0:	714080e7          	jalr	1812(ra) # 800025c0 <either_copyin>
    80003eb4:	07850263          	beq	a0,s8,80003f18 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003eb8:	8526                	mv	a0,s1
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	75e080e7          	jalr	1886(ra) # 80004618 <log_write>
    brelse(bp);
    80003ec2:	8526                	mv	a0,s1
    80003ec4:	fffff097          	auipc	ra,0xfffff
    80003ec8:	4fc080e7          	jalr	1276(ra) # 800033c0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ecc:	013d09bb          	addw	s3,s10,s3
    80003ed0:	012d093b          	addw	s2,s10,s2
    80003ed4:	9a6e                	add	s4,s4,s11
    80003ed6:	0569f663          	bgeu	s3,s6,80003f22 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003eda:	00a9559b          	srliw	a1,s2,0xa
    80003ede:	8556                	mv	a0,s5
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	7a2080e7          	jalr	1954(ra) # 80003682 <bmap>
    80003ee8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003eec:	c99d                	beqz	a1,80003f22 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003eee:	000aa503          	lw	a0,0(s5)
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	39e080e7          	jalr	926(ra) # 80003290 <bread>
    80003efa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003efc:	3ff97713          	andi	a4,s2,1023
    80003f00:	40ec87bb          	subw	a5,s9,a4
    80003f04:	413b06bb          	subw	a3,s6,s3
    80003f08:	8d3e                	mv	s10,a5
    80003f0a:	2781                	sext.w	a5,a5
    80003f0c:	0006861b          	sext.w	a2,a3
    80003f10:	f8f674e3          	bgeu	a2,a5,80003e98 <writei+0x4c>
    80003f14:	8d36                	mv	s10,a3
    80003f16:	b749                	j	80003e98 <writei+0x4c>
      brelse(bp);
    80003f18:	8526                	mv	a0,s1
    80003f1a:	fffff097          	auipc	ra,0xfffff
    80003f1e:	4a6080e7          	jalr	1190(ra) # 800033c0 <brelse>
  }

  if(off > ip->size)
    80003f22:	04caa783          	lw	a5,76(s5)
    80003f26:	0127f463          	bgeu	a5,s2,80003f2e <writei+0xe2>
    ip->size = off;
    80003f2a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f2e:	8556                	mv	a0,s5
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	aa4080e7          	jalr	-1372(ra) # 800039d4 <iupdate>

  return tot;
    80003f38:	0009851b          	sext.w	a0,s3
}
    80003f3c:	70a6                	ld	ra,104(sp)
    80003f3e:	7406                	ld	s0,96(sp)
    80003f40:	64e6                	ld	s1,88(sp)
    80003f42:	6946                	ld	s2,80(sp)
    80003f44:	69a6                	ld	s3,72(sp)
    80003f46:	6a06                	ld	s4,64(sp)
    80003f48:	7ae2                	ld	s5,56(sp)
    80003f4a:	7b42                	ld	s6,48(sp)
    80003f4c:	7ba2                	ld	s7,40(sp)
    80003f4e:	7c02                	ld	s8,32(sp)
    80003f50:	6ce2                	ld	s9,24(sp)
    80003f52:	6d42                	ld	s10,16(sp)
    80003f54:	6da2                	ld	s11,8(sp)
    80003f56:	6165                	addi	sp,sp,112
    80003f58:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f5a:	89da                	mv	s3,s6
    80003f5c:	bfc9                	j	80003f2e <writei+0xe2>
    return -1;
    80003f5e:	557d                	li	a0,-1
}
    80003f60:	8082                	ret
    return -1;
    80003f62:	557d                	li	a0,-1
    80003f64:	bfe1                	j	80003f3c <writei+0xf0>
    return -1;
    80003f66:	557d                	li	a0,-1
    80003f68:	bfd1                	j	80003f3c <writei+0xf0>

0000000080003f6a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f6a:	1141                	addi	sp,sp,-16
    80003f6c:	e406                	sd	ra,8(sp)
    80003f6e:	e022                	sd	s0,0(sp)
    80003f70:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f72:	4639                	li	a2,14
    80003f74:	ffffd097          	auipc	ra,0xffffd
    80003f78:	e2a080e7          	jalr	-470(ra) # 80000d9e <strncmp>
}
    80003f7c:	60a2                	ld	ra,8(sp)
    80003f7e:	6402                	ld	s0,0(sp)
    80003f80:	0141                	addi	sp,sp,16
    80003f82:	8082                	ret

0000000080003f84 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f84:	7139                	addi	sp,sp,-64
    80003f86:	fc06                	sd	ra,56(sp)
    80003f88:	f822                	sd	s0,48(sp)
    80003f8a:	f426                	sd	s1,40(sp)
    80003f8c:	f04a                	sd	s2,32(sp)
    80003f8e:	ec4e                	sd	s3,24(sp)
    80003f90:	e852                	sd	s4,16(sp)
    80003f92:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f94:	04451703          	lh	a4,68(a0)
    80003f98:	4785                	li	a5,1
    80003f9a:	00f71a63          	bne	a4,a5,80003fae <dirlookup+0x2a>
    80003f9e:	892a                	mv	s2,a0
    80003fa0:	89ae                	mv	s3,a1
    80003fa2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fa4:	457c                	lw	a5,76(a0)
    80003fa6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fa8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003faa:	e79d                	bnez	a5,80003fd8 <dirlookup+0x54>
    80003fac:	a8a5                	j	80004024 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fae:	00004517          	auipc	a0,0x4
    80003fb2:	68250513          	addi	a0,a0,1666 # 80008630 <syscalls+0x1c0>
    80003fb6:	ffffc097          	auipc	ra,0xffffc
    80003fba:	586080e7          	jalr	1414(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003fbe:	00004517          	auipc	a0,0x4
    80003fc2:	68a50513          	addi	a0,a0,1674 # 80008648 <syscalls+0x1d8>
    80003fc6:	ffffc097          	auipc	ra,0xffffc
    80003fca:	576080e7          	jalr	1398(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fce:	24c1                	addiw	s1,s1,16
    80003fd0:	04c92783          	lw	a5,76(s2)
    80003fd4:	04f4f763          	bgeu	s1,a5,80004022 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fd8:	4741                	li	a4,16
    80003fda:	86a6                	mv	a3,s1
    80003fdc:	fc040613          	addi	a2,s0,-64
    80003fe0:	4581                	li	a1,0
    80003fe2:	854a                	mv	a0,s2
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	d70080e7          	jalr	-656(ra) # 80003d54 <readi>
    80003fec:	47c1                	li	a5,16
    80003fee:	fcf518e3          	bne	a0,a5,80003fbe <dirlookup+0x3a>
    if(de.inum == 0)
    80003ff2:	fc045783          	lhu	a5,-64(s0)
    80003ff6:	dfe1                	beqz	a5,80003fce <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ff8:	fc240593          	addi	a1,s0,-62
    80003ffc:	854e                	mv	a0,s3
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	f6c080e7          	jalr	-148(ra) # 80003f6a <namecmp>
    80004006:	f561                	bnez	a0,80003fce <dirlookup+0x4a>
      if(poff)
    80004008:	000a0463          	beqz	s4,80004010 <dirlookup+0x8c>
        *poff = off;
    8000400c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004010:	fc045583          	lhu	a1,-64(s0)
    80004014:	00092503          	lw	a0,0(s2)
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	754080e7          	jalr	1876(ra) # 8000376c <iget>
    80004020:	a011                	j	80004024 <dirlookup+0xa0>
  return 0;
    80004022:	4501                	li	a0,0
}
    80004024:	70e2                	ld	ra,56(sp)
    80004026:	7442                	ld	s0,48(sp)
    80004028:	74a2                	ld	s1,40(sp)
    8000402a:	7902                	ld	s2,32(sp)
    8000402c:	69e2                	ld	s3,24(sp)
    8000402e:	6a42                	ld	s4,16(sp)
    80004030:	6121                	addi	sp,sp,64
    80004032:	8082                	ret

0000000080004034 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004034:	711d                	addi	sp,sp,-96
    80004036:	ec86                	sd	ra,88(sp)
    80004038:	e8a2                	sd	s0,80(sp)
    8000403a:	e4a6                	sd	s1,72(sp)
    8000403c:	e0ca                	sd	s2,64(sp)
    8000403e:	fc4e                	sd	s3,56(sp)
    80004040:	f852                	sd	s4,48(sp)
    80004042:	f456                	sd	s5,40(sp)
    80004044:	f05a                	sd	s6,32(sp)
    80004046:	ec5e                	sd	s7,24(sp)
    80004048:	e862                	sd	s8,16(sp)
    8000404a:	e466                	sd	s9,8(sp)
    8000404c:	1080                	addi	s0,sp,96
    8000404e:	84aa                	mv	s1,a0
    80004050:	8b2e                	mv	s6,a1
    80004052:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004054:	00054703          	lbu	a4,0(a0)
    80004058:	02f00793          	li	a5,47
    8000405c:	02f70263          	beq	a4,a5,80004080 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004060:	ffffe097          	auipc	ra,0xffffe
    80004064:	946080e7          	jalr	-1722(ra) # 800019a6 <myproc>
    80004068:	15053503          	ld	a0,336(a0)
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	9f6080e7          	jalr	-1546(ra) # 80003a62 <idup>
    80004074:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004076:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000407a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000407c:	4b85                	li	s7,1
    8000407e:	a875                	j	8000413a <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004080:	4585                	li	a1,1
    80004082:	4505                	li	a0,1
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	6e8080e7          	jalr	1768(ra) # 8000376c <iget>
    8000408c:	8a2a                	mv	s4,a0
    8000408e:	b7e5                	j	80004076 <namex+0x42>
      iunlockput(ip);
    80004090:	8552                	mv	a0,s4
    80004092:	00000097          	auipc	ra,0x0
    80004096:	c70080e7          	jalr	-912(ra) # 80003d02 <iunlockput>
      return 0;
    8000409a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000409c:	8552                	mv	a0,s4
    8000409e:	60e6                	ld	ra,88(sp)
    800040a0:	6446                	ld	s0,80(sp)
    800040a2:	64a6                	ld	s1,72(sp)
    800040a4:	6906                	ld	s2,64(sp)
    800040a6:	79e2                	ld	s3,56(sp)
    800040a8:	7a42                	ld	s4,48(sp)
    800040aa:	7aa2                	ld	s5,40(sp)
    800040ac:	7b02                	ld	s6,32(sp)
    800040ae:	6be2                	ld	s7,24(sp)
    800040b0:	6c42                	ld	s8,16(sp)
    800040b2:	6ca2                	ld	s9,8(sp)
    800040b4:	6125                	addi	sp,sp,96
    800040b6:	8082                	ret
      iunlock(ip);
    800040b8:	8552                	mv	a0,s4
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	aa8080e7          	jalr	-1368(ra) # 80003b62 <iunlock>
      return ip;
    800040c2:	bfe9                	j	8000409c <namex+0x68>
      iunlockput(ip);
    800040c4:	8552                	mv	a0,s4
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	c3c080e7          	jalr	-964(ra) # 80003d02 <iunlockput>
      return 0;
    800040ce:	8a4e                	mv	s4,s3
    800040d0:	b7f1                	j	8000409c <namex+0x68>
  len = path - s;
    800040d2:	40998633          	sub	a2,s3,s1
    800040d6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800040da:	099c5863          	bge	s8,s9,8000416a <namex+0x136>
    memmove(name, s, DIRSIZ);
    800040de:	4639                	li	a2,14
    800040e0:	85a6                	mv	a1,s1
    800040e2:	8556                	mv	a0,s5
    800040e4:	ffffd097          	auipc	ra,0xffffd
    800040e8:	c46080e7          	jalr	-954(ra) # 80000d2a <memmove>
    800040ec:	84ce                	mv	s1,s3
  while(*path == '/')
    800040ee:	0004c783          	lbu	a5,0(s1)
    800040f2:	01279763          	bne	a5,s2,80004100 <namex+0xcc>
    path++;
    800040f6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040f8:	0004c783          	lbu	a5,0(s1)
    800040fc:	ff278de3          	beq	a5,s2,800040f6 <namex+0xc2>
    ilock(ip);
    80004100:	8552                	mv	a0,s4
    80004102:	00000097          	auipc	ra,0x0
    80004106:	99e080e7          	jalr	-1634(ra) # 80003aa0 <ilock>
    if(ip->type != T_DIR){
    8000410a:	044a1783          	lh	a5,68(s4)
    8000410e:	f97791e3          	bne	a5,s7,80004090 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004112:	000b0563          	beqz	s6,8000411c <namex+0xe8>
    80004116:	0004c783          	lbu	a5,0(s1)
    8000411a:	dfd9                	beqz	a5,800040b8 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000411c:	4601                	li	a2,0
    8000411e:	85d6                	mv	a1,s5
    80004120:	8552                	mv	a0,s4
    80004122:	00000097          	auipc	ra,0x0
    80004126:	e62080e7          	jalr	-414(ra) # 80003f84 <dirlookup>
    8000412a:	89aa                	mv	s3,a0
    8000412c:	dd41                	beqz	a0,800040c4 <namex+0x90>
    iunlockput(ip);
    8000412e:	8552                	mv	a0,s4
    80004130:	00000097          	auipc	ra,0x0
    80004134:	bd2080e7          	jalr	-1070(ra) # 80003d02 <iunlockput>
    ip = next;
    80004138:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000413a:	0004c783          	lbu	a5,0(s1)
    8000413e:	01279763          	bne	a5,s2,8000414c <namex+0x118>
    path++;
    80004142:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004144:	0004c783          	lbu	a5,0(s1)
    80004148:	ff278de3          	beq	a5,s2,80004142 <namex+0x10e>
  if(*path == 0)
    8000414c:	cb9d                	beqz	a5,80004182 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000414e:	0004c783          	lbu	a5,0(s1)
    80004152:	89a6                	mv	s3,s1
  len = path - s;
    80004154:	4c81                	li	s9,0
    80004156:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004158:	01278963          	beq	a5,s2,8000416a <namex+0x136>
    8000415c:	dbbd                	beqz	a5,800040d2 <namex+0x9e>
    path++;
    8000415e:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004160:	0009c783          	lbu	a5,0(s3)
    80004164:	ff279ce3          	bne	a5,s2,8000415c <namex+0x128>
    80004168:	b7ad                	j	800040d2 <namex+0x9e>
    memmove(name, s, len);
    8000416a:	2601                	sext.w	a2,a2
    8000416c:	85a6                	mv	a1,s1
    8000416e:	8556                	mv	a0,s5
    80004170:	ffffd097          	auipc	ra,0xffffd
    80004174:	bba080e7          	jalr	-1094(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004178:	9cd6                	add	s9,s9,s5
    8000417a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000417e:	84ce                	mv	s1,s3
    80004180:	b7bd                	j	800040ee <namex+0xba>
  if(nameiparent){
    80004182:	f00b0de3          	beqz	s6,8000409c <namex+0x68>
    iput(ip);
    80004186:	8552                	mv	a0,s4
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	ad2080e7          	jalr	-1326(ra) # 80003c5a <iput>
    return 0;
    80004190:	4a01                	li	s4,0
    80004192:	b729                	j	8000409c <namex+0x68>

0000000080004194 <dirlink>:
{
    80004194:	7139                	addi	sp,sp,-64
    80004196:	fc06                	sd	ra,56(sp)
    80004198:	f822                	sd	s0,48(sp)
    8000419a:	f426                	sd	s1,40(sp)
    8000419c:	f04a                	sd	s2,32(sp)
    8000419e:	ec4e                	sd	s3,24(sp)
    800041a0:	e852                	sd	s4,16(sp)
    800041a2:	0080                	addi	s0,sp,64
    800041a4:	892a                	mv	s2,a0
    800041a6:	8a2e                	mv	s4,a1
    800041a8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041aa:	4601                	li	a2,0
    800041ac:	00000097          	auipc	ra,0x0
    800041b0:	dd8080e7          	jalr	-552(ra) # 80003f84 <dirlookup>
    800041b4:	e93d                	bnez	a0,8000422a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041b6:	04c92483          	lw	s1,76(s2)
    800041ba:	c49d                	beqz	s1,800041e8 <dirlink+0x54>
    800041bc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041be:	4741                	li	a4,16
    800041c0:	86a6                	mv	a3,s1
    800041c2:	fc040613          	addi	a2,s0,-64
    800041c6:	4581                	li	a1,0
    800041c8:	854a                	mv	a0,s2
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	b8a080e7          	jalr	-1142(ra) # 80003d54 <readi>
    800041d2:	47c1                	li	a5,16
    800041d4:	06f51163          	bne	a0,a5,80004236 <dirlink+0xa2>
    if(de.inum == 0)
    800041d8:	fc045783          	lhu	a5,-64(s0)
    800041dc:	c791                	beqz	a5,800041e8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041de:	24c1                	addiw	s1,s1,16
    800041e0:	04c92783          	lw	a5,76(s2)
    800041e4:	fcf4ede3          	bltu	s1,a5,800041be <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800041e8:	4639                	li	a2,14
    800041ea:	85d2                	mv	a1,s4
    800041ec:	fc240513          	addi	a0,s0,-62
    800041f0:	ffffd097          	auipc	ra,0xffffd
    800041f4:	bea080e7          	jalr	-1046(ra) # 80000dda <strncpy>
  de.inum = inum;
    800041f8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041fc:	4741                	li	a4,16
    800041fe:	86a6                	mv	a3,s1
    80004200:	fc040613          	addi	a2,s0,-64
    80004204:	4581                	li	a1,0
    80004206:	854a                	mv	a0,s2
    80004208:	00000097          	auipc	ra,0x0
    8000420c:	c44080e7          	jalr	-956(ra) # 80003e4c <writei>
    80004210:	1541                	addi	a0,a0,-16
    80004212:	00a03533          	snez	a0,a0
    80004216:	40a00533          	neg	a0,a0
}
    8000421a:	70e2                	ld	ra,56(sp)
    8000421c:	7442                	ld	s0,48(sp)
    8000421e:	74a2                	ld	s1,40(sp)
    80004220:	7902                	ld	s2,32(sp)
    80004222:	69e2                	ld	s3,24(sp)
    80004224:	6a42                	ld	s4,16(sp)
    80004226:	6121                	addi	sp,sp,64
    80004228:	8082                	ret
    iput(ip);
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	a30080e7          	jalr	-1488(ra) # 80003c5a <iput>
    return -1;
    80004232:	557d                	li	a0,-1
    80004234:	b7dd                	j	8000421a <dirlink+0x86>
      panic("dirlink read");
    80004236:	00004517          	auipc	a0,0x4
    8000423a:	42250513          	addi	a0,a0,1058 # 80008658 <syscalls+0x1e8>
    8000423e:	ffffc097          	auipc	ra,0xffffc
    80004242:	2fe080e7          	jalr	766(ra) # 8000053c <panic>

0000000080004246 <namei>:

struct inode*
namei(char *path)
{
    80004246:	1101                	addi	sp,sp,-32
    80004248:	ec06                	sd	ra,24(sp)
    8000424a:	e822                	sd	s0,16(sp)
    8000424c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000424e:	fe040613          	addi	a2,s0,-32
    80004252:	4581                	li	a1,0
    80004254:	00000097          	auipc	ra,0x0
    80004258:	de0080e7          	jalr	-544(ra) # 80004034 <namex>
}
    8000425c:	60e2                	ld	ra,24(sp)
    8000425e:	6442                	ld	s0,16(sp)
    80004260:	6105                	addi	sp,sp,32
    80004262:	8082                	ret

0000000080004264 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004264:	1141                	addi	sp,sp,-16
    80004266:	e406                	sd	ra,8(sp)
    80004268:	e022                	sd	s0,0(sp)
    8000426a:	0800                	addi	s0,sp,16
    8000426c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000426e:	4585                	li	a1,1
    80004270:	00000097          	auipc	ra,0x0
    80004274:	dc4080e7          	jalr	-572(ra) # 80004034 <namex>
}
    80004278:	60a2                	ld	ra,8(sp)
    8000427a:	6402                	ld	s0,0(sp)
    8000427c:	0141                	addi	sp,sp,16
    8000427e:	8082                	ret

0000000080004280 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004280:	1101                	addi	sp,sp,-32
    80004282:	ec06                	sd	ra,24(sp)
    80004284:	e822                	sd	s0,16(sp)
    80004286:	e426                	sd	s1,8(sp)
    80004288:	e04a                	sd	s2,0(sp)
    8000428a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000428c:	0001d917          	auipc	s2,0x1d
    80004290:	2d490913          	addi	s2,s2,724 # 80021560 <log>
    80004294:	01892583          	lw	a1,24(s2)
    80004298:	02892503          	lw	a0,40(s2)
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	ff4080e7          	jalr	-12(ra) # 80003290 <bread>
    800042a4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042a6:	02c92603          	lw	a2,44(s2)
    800042aa:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042ac:	00c05f63          	blez	a2,800042ca <write_head+0x4a>
    800042b0:	0001d717          	auipc	a4,0x1d
    800042b4:	2e070713          	addi	a4,a4,736 # 80021590 <log+0x30>
    800042b8:	87aa                	mv	a5,a0
    800042ba:	060a                	slli	a2,a2,0x2
    800042bc:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800042be:	4314                	lw	a3,0(a4)
    800042c0:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800042c2:	0711                	addi	a4,a4,4
    800042c4:	0791                	addi	a5,a5,4
    800042c6:	fec79ce3          	bne	a5,a2,800042be <write_head+0x3e>
  }
  bwrite(buf);
    800042ca:	8526                	mv	a0,s1
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	0b6080e7          	jalr	182(ra) # 80003382 <bwrite>
  brelse(buf);
    800042d4:	8526                	mv	a0,s1
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	0ea080e7          	jalr	234(ra) # 800033c0 <brelse>
}
    800042de:	60e2                	ld	ra,24(sp)
    800042e0:	6442                	ld	s0,16(sp)
    800042e2:	64a2                	ld	s1,8(sp)
    800042e4:	6902                	ld	s2,0(sp)
    800042e6:	6105                	addi	sp,sp,32
    800042e8:	8082                	ret

00000000800042ea <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ea:	0001d797          	auipc	a5,0x1d
    800042ee:	2a27a783          	lw	a5,674(a5) # 8002158c <log+0x2c>
    800042f2:	0af05d63          	blez	a5,800043ac <install_trans+0xc2>
{
    800042f6:	7139                	addi	sp,sp,-64
    800042f8:	fc06                	sd	ra,56(sp)
    800042fa:	f822                	sd	s0,48(sp)
    800042fc:	f426                	sd	s1,40(sp)
    800042fe:	f04a                	sd	s2,32(sp)
    80004300:	ec4e                	sd	s3,24(sp)
    80004302:	e852                	sd	s4,16(sp)
    80004304:	e456                	sd	s5,8(sp)
    80004306:	e05a                	sd	s6,0(sp)
    80004308:	0080                	addi	s0,sp,64
    8000430a:	8b2a                	mv	s6,a0
    8000430c:	0001da97          	auipc	s5,0x1d
    80004310:	284a8a93          	addi	s5,s5,644 # 80021590 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004314:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004316:	0001d997          	auipc	s3,0x1d
    8000431a:	24a98993          	addi	s3,s3,586 # 80021560 <log>
    8000431e:	a00d                	j	80004340 <install_trans+0x56>
    brelse(lbuf);
    80004320:	854a                	mv	a0,s2
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	09e080e7          	jalr	158(ra) # 800033c0 <brelse>
    brelse(dbuf);
    8000432a:	8526                	mv	a0,s1
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	094080e7          	jalr	148(ra) # 800033c0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004334:	2a05                	addiw	s4,s4,1
    80004336:	0a91                	addi	s5,s5,4
    80004338:	02c9a783          	lw	a5,44(s3)
    8000433c:	04fa5e63          	bge	s4,a5,80004398 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004340:	0189a583          	lw	a1,24(s3)
    80004344:	014585bb          	addw	a1,a1,s4
    80004348:	2585                	addiw	a1,a1,1
    8000434a:	0289a503          	lw	a0,40(s3)
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	f42080e7          	jalr	-190(ra) # 80003290 <bread>
    80004356:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004358:	000aa583          	lw	a1,0(s5)
    8000435c:	0289a503          	lw	a0,40(s3)
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	f30080e7          	jalr	-208(ra) # 80003290 <bread>
    80004368:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000436a:	40000613          	li	a2,1024
    8000436e:	05890593          	addi	a1,s2,88
    80004372:	05850513          	addi	a0,a0,88
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	9b4080e7          	jalr	-1612(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000437e:	8526                	mv	a0,s1
    80004380:	fffff097          	auipc	ra,0xfffff
    80004384:	002080e7          	jalr	2(ra) # 80003382 <bwrite>
    if(recovering == 0)
    80004388:	f80b1ce3          	bnez	s6,80004320 <install_trans+0x36>
      bunpin(dbuf);
    8000438c:	8526                	mv	a0,s1
    8000438e:	fffff097          	auipc	ra,0xfffff
    80004392:	10a080e7          	jalr	266(ra) # 80003498 <bunpin>
    80004396:	b769                	j	80004320 <install_trans+0x36>
}
    80004398:	70e2                	ld	ra,56(sp)
    8000439a:	7442                	ld	s0,48(sp)
    8000439c:	74a2                	ld	s1,40(sp)
    8000439e:	7902                	ld	s2,32(sp)
    800043a0:	69e2                	ld	s3,24(sp)
    800043a2:	6a42                	ld	s4,16(sp)
    800043a4:	6aa2                	ld	s5,8(sp)
    800043a6:	6b02                	ld	s6,0(sp)
    800043a8:	6121                	addi	sp,sp,64
    800043aa:	8082                	ret
    800043ac:	8082                	ret

00000000800043ae <initlog>:
{
    800043ae:	7179                	addi	sp,sp,-48
    800043b0:	f406                	sd	ra,40(sp)
    800043b2:	f022                	sd	s0,32(sp)
    800043b4:	ec26                	sd	s1,24(sp)
    800043b6:	e84a                	sd	s2,16(sp)
    800043b8:	e44e                	sd	s3,8(sp)
    800043ba:	1800                	addi	s0,sp,48
    800043bc:	892a                	mv	s2,a0
    800043be:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800043c0:	0001d497          	auipc	s1,0x1d
    800043c4:	1a048493          	addi	s1,s1,416 # 80021560 <log>
    800043c8:	00004597          	auipc	a1,0x4
    800043cc:	2a058593          	addi	a1,a1,672 # 80008668 <syscalls+0x1f8>
    800043d0:	8526                	mv	a0,s1
    800043d2:	ffffc097          	auipc	ra,0xffffc
    800043d6:	770080e7          	jalr	1904(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    800043da:	0149a583          	lw	a1,20(s3)
    800043de:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800043e0:	0109a783          	lw	a5,16(s3)
    800043e4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800043e6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043ea:	854a                	mv	a0,s2
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	ea4080e7          	jalr	-348(ra) # 80003290 <bread>
  log.lh.n = lh->n;
    800043f4:	4d30                	lw	a2,88(a0)
    800043f6:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043f8:	00c05f63          	blez	a2,80004416 <initlog+0x68>
    800043fc:	87aa                	mv	a5,a0
    800043fe:	0001d717          	auipc	a4,0x1d
    80004402:	19270713          	addi	a4,a4,402 # 80021590 <log+0x30>
    80004406:	060a                	slli	a2,a2,0x2
    80004408:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000440a:	4ff4                	lw	a3,92(a5)
    8000440c:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000440e:	0791                	addi	a5,a5,4
    80004410:	0711                	addi	a4,a4,4
    80004412:	fec79ce3          	bne	a5,a2,8000440a <initlog+0x5c>
  brelse(buf);
    80004416:	fffff097          	auipc	ra,0xfffff
    8000441a:	faa080e7          	jalr	-86(ra) # 800033c0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000441e:	4505                	li	a0,1
    80004420:	00000097          	auipc	ra,0x0
    80004424:	eca080e7          	jalr	-310(ra) # 800042ea <install_trans>
  log.lh.n = 0;
    80004428:	0001d797          	auipc	a5,0x1d
    8000442c:	1607a223          	sw	zero,356(a5) # 8002158c <log+0x2c>
  write_head(); // clear the log
    80004430:	00000097          	auipc	ra,0x0
    80004434:	e50080e7          	jalr	-432(ra) # 80004280 <write_head>
}
    80004438:	70a2                	ld	ra,40(sp)
    8000443a:	7402                	ld	s0,32(sp)
    8000443c:	64e2                	ld	s1,24(sp)
    8000443e:	6942                	ld	s2,16(sp)
    80004440:	69a2                	ld	s3,8(sp)
    80004442:	6145                	addi	sp,sp,48
    80004444:	8082                	ret

0000000080004446 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004452:	0001d517          	auipc	a0,0x1d
    80004456:	10e50513          	addi	a0,a0,270 # 80021560 <log>
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	778080e7          	jalr	1912(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004462:	0001d497          	auipc	s1,0x1d
    80004466:	0fe48493          	addi	s1,s1,254 # 80021560 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000446a:	4979                	li	s2,30
    8000446c:	a039                	j	8000447a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000446e:	85a6                	mv	a1,s1
    80004470:	8526                	mv	a0,s1
    80004472:	ffffe097          	auipc	ra,0xffffe
    80004476:	ce4080e7          	jalr	-796(ra) # 80002156 <sleep>
    if(log.committing){
    8000447a:	50dc                	lw	a5,36(s1)
    8000447c:	fbed                	bnez	a5,8000446e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000447e:	5098                	lw	a4,32(s1)
    80004480:	2705                	addiw	a4,a4,1
    80004482:	0027179b          	slliw	a5,a4,0x2
    80004486:	9fb9                	addw	a5,a5,a4
    80004488:	0017979b          	slliw	a5,a5,0x1
    8000448c:	54d4                	lw	a3,44(s1)
    8000448e:	9fb5                	addw	a5,a5,a3
    80004490:	00f95963          	bge	s2,a5,800044a2 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004494:	85a6                	mv	a1,s1
    80004496:	8526                	mv	a0,s1
    80004498:	ffffe097          	auipc	ra,0xffffe
    8000449c:	cbe080e7          	jalr	-834(ra) # 80002156 <sleep>
    800044a0:	bfe9                	j	8000447a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800044a2:	0001d517          	auipc	a0,0x1d
    800044a6:	0be50513          	addi	a0,a0,190 # 80021560 <log>
    800044aa:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	7da080e7          	jalr	2010(ra) # 80000c86 <release>
      break;
    }
  }
}
    800044b4:	60e2                	ld	ra,24(sp)
    800044b6:	6442                	ld	s0,16(sp)
    800044b8:	64a2                	ld	s1,8(sp)
    800044ba:	6902                	ld	s2,0(sp)
    800044bc:	6105                	addi	sp,sp,32
    800044be:	8082                	ret

00000000800044c0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800044c0:	7139                	addi	sp,sp,-64
    800044c2:	fc06                	sd	ra,56(sp)
    800044c4:	f822                	sd	s0,48(sp)
    800044c6:	f426                	sd	s1,40(sp)
    800044c8:	f04a                	sd	s2,32(sp)
    800044ca:	ec4e                	sd	s3,24(sp)
    800044cc:	e852                	sd	s4,16(sp)
    800044ce:	e456                	sd	s5,8(sp)
    800044d0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044d2:	0001d497          	auipc	s1,0x1d
    800044d6:	08e48493          	addi	s1,s1,142 # 80021560 <log>
    800044da:	8526                	mv	a0,s1
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	6f6080e7          	jalr	1782(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    800044e4:	509c                	lw	a5,32(s1)
    800044e6:	37fd                	addiw	a5,a5,-1
    800044e8:	0007891b          	sext.w	s2,a5
    800044ec:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044ee:	50dc                	lw	a5,36(s1)
    800044f0:	e7b9                	bnez	a5,8000453e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044f2:	04091e63          	bnez	s2,8000454e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044f6:	0001d497          	auipc	s1,0x1d
    800044fa:	06a48493          	addi	s1,s1,106 # 80021560 <log>
    800044fe:	4785                	li	a5,1
    80004500:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004502:	8526                	mv	a0,s1
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	782080e7          	jalr	1922(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000450c:	54dc                	lw	a5,44(s1)
    8000450e:	06f04763          	bgtz	a5,8000457c <end_op+0xbc>
    acquire(&log.lock);
    80004512:	0001d497          	auipc	s1,0x1d
    80004516:	04e48493          	addi	s1,s1,78 # 80021560 <log>
    8000451a:	8526                	mv	a0,s1
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	6b6080e7          	jalr	1718(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004524:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004528:	8526                	mv	a0,s1
    8000452a:	ffffe097          	auipc	ra,0xffffe
    8000452e:	c90080e7          	jalr	-880(ra) # 800021ba <wakeup>
    release(&log.lock);
    80004532:	8526                	mv	a0,s1
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	752080e7          	jalr	1874(ra) # 80000c86 <release>
}
    8000453c:	a03d                	j	8000456a <end_op+0xaa>
    panic("log.committing");
    8000453e:	00004517          	auipc	a0,0x4
    80004542:	13250513          	addi	a0,a0,306 # 80008670 <syscalls+0x200>
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	ff6080e7          	jalr	-10(ra) # 8000053c <panic>
    wakeup(&log);
    8000454e:	0001d497          	auipc	s1,0x1d
    80004552:	01248493          	addi	s1,s1,18 # 80021560 <log>
    80004556:	8526                	mv	a0,s1
    80004558:	ffffe097          	auipc	ra,0xffffe
    8000455c:	c62080e7          	jalr	-926(ra) # 800021ba <wakeup>
  release(&log.lock);
    80004560:	8526                	mv	a0,s1
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	724080e7          	jalr	1828(ra) # 80000c86 <release>
}
    8000456a:	70e2                	ld	ra,56(sp)
    8000456c:	7442                	ld	s0,48(sp)
    8000456e:	74a2                	ld	s1,40(sp)
    80004570:	7902                	ld	s2,32(sp)
    80004572:	69e2                	ld	s3,24(sp)
    80004574:	6a42                	ld	s4,16(sp)
    80004576:	6aa2                	ld	s5,8(sp)
    80004578:	6121                	addi	sp,sp,64
    8000457a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000457c:	0001da97          	auipc	s5,0x1d
    80004580:	014a8a93          	addi	s5,s5,20 # 80021590 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004584:	0001da17          	auipc	s4,0x1d
    80004588:	fdca0a13          	addi	s4,s4,-36 # 80021560 <log>
    8000458c:	018a2583          	lw	a1,24(s4)
    80004590:	012585bb          	addw	a1,a1,s2
    80004594:	2585                	addiw	a1,a1,1
    80004596:	028a2503          	lw	a0,40(s4)
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	cf6080e7          	jalr	-778(ra) # 80003290 <bread>
    800045a2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800045a4:	000aa583          	lw	a1,0(s5)
    800045a8:	028a2503          	lw	a0,40(s4)
    800045ac:	fffff097          	auipc	ra,0xfffff
    800045b0:	ce4080e7          	jalr	-796(ra) # 80003290 <bread>
    800045b4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800045b6:	40000613          	li	a2,1024
    800045ba:	05850593          	addi	a1,a0,88
    800045be:	05848513          	addi	a0,s1,88
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	768080e7          	jalr	1896(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800045ca:	8526                	mv	a0,s1
    800045cc:	fffff097          	auipc	ra,0xfffff
    800045d0:	db6080e7          	jalr	-586(ra) # 80003382 <bwrite>
    brelse(from);
    800045d4:	854e                	mv	a0,s3
    800045d6:	fffff097          	auipc	ra,0xfffff
    800045da:	dea080e7          	jalr	-534(ra) # 800033c0 <brelse>
    brelse(to);
    800045de:	8526                	mv	a0,s1
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	de0080e7          	jalr	-544(ra) # 800033c0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045e8:	2905                	addiw	s2,s2,1
    800045ea:	0a91                	addi	s5,s5,4
    800045ec:	02ca2783          	lw	a5,44(s4)
    800045f0:	f8f94ee3          	blt	s2,a5,8000458c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045f4:	00000097          	auipc	ra,0x0
    800045f8:	c8c080e7          	jalr	-884(ra) # 80004280 <write_head>
    install_trans(0); // Now install writes to home locations
    800045fc:	4501                	li	a0,0
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	cec080e7          	jalr	-788(ra) # 800042ea <install_trans>
    log.lh.n = 0;
    80004606:	0001d797          	auipc	a5,0x1d
    8000460a:	f807a323          	sw	zero,-122(a5) # 8002158c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000460e:	00000097          	auipc	ra,0x0
    80004612:	c72080e7          	jalr	-910(ra) # 80004280 <write_head>
    80004616:	bdf5                	j	80004512 <end_op+0x52>

0000000080004618 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004618:	1101                	addi	sp,sp,-32
    8000461a:	ec06                	sd	ra,24(sp)
    8000461c:	e822                	sd	s0,16(sp)
    8000461e:	e426                	sd	s1,8(sp)
    80004620:	e04a                	sd	s2,0(sp)
    80004622:	1000                	addi	s0,sp,32
    80004624:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004626:	0001d917          	auipc	s2,0x1d
    8000462a:	f3a90913          	addi	s2,s2,-198 # 80021560 <log>
    8000462e:	854a                	mv	a0,s2
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	5a2080e7          	jalr	1442(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004638:	02c92603          	lw	a2,44(s2)
    8000463c:	47f5                	li	a5,29
    8000463e:	06c7c563          	blt	a5,a2,800046a8 <log_write+0x90>
    80004642:	0001d797          	auipc	a5,0x1d
    80004646:	f3a7a783          	lw	a5,-198(a5) # 8002157c <log+0x1c>
    8000464a:	37fd                	addiw	a5,a5,-1
    8000464c:	04f65e63          	bge	a2,a5,800046a8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004650:	0001d797          	auipc	a5,0x1d
    80004654:	f307a783          	lw	a5,-208(a5) # 80021580 <log+0x20>
    80004658:	06f05063          	blez	a5,800046b8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000465c:	4781                	li	a5,0
    8000465e:	06c05563          	blez	a2,800046c8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004662:	44cc                	lw	a1,12(s1)
    80004664:	0001d717          	auipc	a4,0x1d
    80004668:	f2c70713          	addi	a4,a4,-212 # 80021590 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000466c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000466e:	4314                	lw	a3,0(a4)
    80004670:	04b68c63          	beq	a3,a1,800046c8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004674:	2785                	addiw	a5,a5,1
    80004676:	0711                	addi	a4,a4,4
    80004678:	fef61be3          	bne	a2,a5,8000466e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000467c:	0621                	addi	a2,a2,8
    8000467e:	060a                	slli	a2,a2,0x2
    80004680:	0001d797          	auipc	a5,0x1d
    80004684:	ee078793          	addi	a5,a5,-288 # 80021560 <log>
    80004688:	97b2                	add	a5,a5,a2
    8000468a:	44d8                	lw	a4,12(s1)
    8000468c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000468e:	8526                	mv	a0,s1
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	dcc080e7          	jalr	-564(ra) # 8000345c <bpin>
    log.lh.n++;
    80004698:	0001d717          	auipc	a4,0x1d
    8000469c:	ec870713          	addi	a4,a4,-312 # 80021560 <log>
    800046a0:	575c                	lw	a5,44(a4)
    800046a2:	2785                	addiw	a5,a5,1
    800046a4:	d75c                	sw	a5,44(a4)
    800046a6:	a82d                	j	800046e0 <log_write+0xc8>
    panic("too big a transaction");
    800046a8:	00004517          	auipc	a0,0x4
    800046ac:	fd850513          	addi	a0,a0,-40 # 80008680 <syscalls+0x210>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	e8c080e7          	jalr	-372(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800046b8:	00004517          	auipc	a0,0x4
    800046bc:	fe050513          	addi	a0,a0,-32 # 80008698 <syscalls+0x228>
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	e7c080e7          	jalr	-388(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800046c8:	00878693          	addi	a3,a5,8
    800046cc:	068a                	slli	a3,a3,0x2
    800046ce:	0001d717          	auipc	a4,0x1d
    800046d2:	e9270713          	addi	a4,a4,-366 # 80021560 <log>
    800046d6:	9736                	add	a4,a4,a3
    800046d8:	44d4                	lw	a3,12(s1)
    800046da:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046dc:	faf609e3          	beq	a2,a5,8000468e <log_write+0x76>
  }
  release(&log.lock);
    800046e0:	0001d517          	auipc	a0,0x1d
    800046e4:	e8050513          	addi	a0,a0,-384 # 80021560 <log>
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	59e080e7          	jalr	1438(ra) # 80000c86 <release>
}
    800046f0:	60e2                	ld	ra,24(sp)
    800046f2:	6442                	ld	s0,16(sp)
    800046f4:	64a2                	ld	s1,8(sp)
    800046f6:	6902                	ld	s2,0(sp)
    800046f8:	6105                	addi	sp,sp,32
    800046fa:	8082                	ret

00000000800046fc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046fc:	1101                	addi	sp,sp,-32
    800046fe:	ec06                	sd	ra,24(sp)
    80004700:	e822                	sd	s0,16(sp)
    80004702:	e426                	sd	s1,8(sp)
    80004704:	e04a                	sd	s2,0(sp)
    80004706:	1000                	addi	s0,sp,32
    80004708:	84aa                	mv	s1,a0
    8000470a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000470c:	00004597          	auipc	a1,0x4
    80004710:	fac58593          	addi	a1,a1,-84 # 800086b8 <syscalls+0x248>
    80004714:	0521                	addi	a0,a0,8
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	42c080e7          	jalr	1068(ra) # 80000b42 <initlock>
  lk->name = name;
    8000471e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004722:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004726:	0204a423          	sw	zero,40(s1)
}
    8000472a:	60e2                	ld	ra,24(sp)
    8000472c:	6442                	ld	s0,16(sp)
    8000472e:	64a2                	ld	s1,8(sp)
    80004730:	6902                	ld	s2,0(sp)
    80004732:	6105                	addi	sp,sp,32
    80004734:	8082                	ret

0000000080004736 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004736:	1101                	addi	sp,sp,-32
    80004738:	ec06                	sd	ra,24(sp)
    8000473a:	e822                	sd	s0,16(sp)
    8000473c:	e426                	sd	s1,8(sp)
    8000473e:	e04a                	sd	s2,0(sp)
    80004740:	1000                	addi	s0,sp,32
    80004742:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004744:	00850913          	addi	s2,a0,8
    80004748:	854a                	mv	a0,s2
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	488080e7          	jalr	1160(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004752:	409c                	lw	a5,0(s1)
    80004754:	cb89                	beqz	a5,80004766 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004756:	85ca                	mv	a1,s2
    80004758:	8526                	mv	a0,s1
    8000475a:	ffffe097          	auipc	ra,0xffffe
    8000475e:	9fc080e7          	jalr	-1540(ra) # 80002156 <sleep>
  while (lk->locked) {
    80004762:	409c                	lw	a5,0(s1)
    80004764:	fbed                	bnez	a5,80004756 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004766:	4785                	li	a5,1
    80004768:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000476a:	ffffd097          	auipc	ra,0xffffd
    8000476e:	23c080e7          	jalr	572(ra) # 800019a6 <myproc>
    80004772:	591c                	lw	a5,48(a0)
    80004774:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004776:	854a                	mv	a0,s2
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	50e080e7          	jalr	1294(ra) # 80000c86 <release>
}
    80004780:	60e2                	ld	ra,24(sp)
    80004782:	6442                	ld	s0,16(sp)
    80004784:	64a2                	ld	s1,8(sp)
    80004786:	6902                	ld	s2,0(sp)
    80004788:	6105                	addi	sp,sp,32
    8000478a:	8082                	ret

000000008000478c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000478c:	1101                	addi	sp,sp,-32
    8000478e:	ec06                	sd	ra,24(sp)
    80004790:	e822                	sd	s0,16(sp)
    80004792:	e426                	sd	s1,8(sp)
    80004794:	e04a                	sd	s2,0(sp)
    80004796:	1000                	addi	s0,sp,32
    80004798:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000479a:	00850913          	addi	s2,a0,8
    8000479e:	854a                	mv	a0,s2
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	432080e7          	jalr	1074(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    800047a8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047ac:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800047b0:	8526                	mv	a0,s1
    800047b2:	ffffe097          	auipc	ra,0xffffe
    800047b6:	a08080e7          	jalr	-1528(ra) # 800021ba <wakeup>
  release(&lk->lk);
    800047ba:	854a                	mv	a0,s2
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	4ca080e7          	jalr	1226(ra) # 80000c86 <release>
}
    800047c4:	60e2                	ld	ra,24(sp)
    800047c6:	6442                	ld	s0,16(sp)
    800047c8:	64a2                	ld	s1,8(sp)
    800047ca:	6902                	ld	s2,0(sp)
    800047cc:	6105                	addi	sp,sp,32
    800047ce:	8082                	ret

00000000800047d0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047d0:	7179                	addi	sp,sp,-48
    800047d2:	f406                	sd	ra,40(sp)
    800047d4:	f022                	sd	s0,32(sp)
    800047d6:	ec26                	sd	s1,24(sp)
    800047d8:	e84a                	sd	s2,16(sp)
    800047da:	e44e                	sd	s3,8(sp)
    800047dc:	1800                	addi	s0,sp,48
    800047de:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047e0:	00850913          	addi	s2,a0,8
    800047e4:	854a                	mv	a0,s2
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	3ec080e7          	jalr	1004(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047ee:	409c                	lw	a5,0(s1)
    800047f0:	ef99                	bnez	a5,8000480e <holdingsleep+0x3e>
    800047f2:	4481                	li	s1,0
  release(&lk->lk);
    800047f4:	854a                	mv	a0,s2
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	490080e7          	jalr	1168(ra) # 80000c86 <release>
  return r;
}
    800047fe:	8526                	mv	a0,s1
    80004800:	70a2                	ld	ra,40(sp)
    80004802:	7402                	ld	s0,32(sp)
    80004804:	64e2                	ld	s1,24(sp)
    80004806:	6942                	ld	s2,16(sp)
    80004808:	69a2                	ld	s3,8(sp)
    8000480a:	6145                	addi	sp,sp,48
    8000480c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000480e:	0284a983          	lw	s3,40(s1)
    80004812:	ffffd097          	auipc	ra,0xffffd
    80004816:	194080e7          	jalr	404(ra) # 800019a6 <myproc>
    8000481a:	5904                	lw	s1,48(a0)
    8000481c:	413484b3          	sub	s1,s1,s3
    80004820:	0014b493          	seqz	s1,s1
    80004824:	bfc1                	j	800047f4 <holdingsleep+0x24>

0000000080004826 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004826:	1141                	addi	sp,sp,-16
    80004828:	e406                	sd	ra,8(sp)
    8000482a:	e022                	sd	s0,0(sp)
    8000482c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000482e:	00004597          	auipc	a1,0x4
    80004832:	e9a58593          	addi	a1,a1,-358 # 800086c8 <syscalls+0x258>
    80004836:	0001d517          	auipc	a0,0x1d
    8000483a:	e7250513          	addi	a0,a0,-398 # 800216a8 <ftable>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	304080e7          	jalr	772(ra) # 80000b42 <initlock>
}
    80004846:	60a2                	ld	ra,8(sp)
    80004848:	6402                	ld	s0,0(sp)
    8000484a:	0141                	addi	sp,sp,16
    8000484c:	8082                	ret

000000008000484e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000484e:	1101                	addi	sp,sp,-32
    80004850:	ec06                	sd	ra,24(sp)
    80004852:	e822                	sd	s0,16(sp)
    80004854:	e426                	sd	s1,8(sp)
    80004856:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004858:	0001d517          	auipc	a0,0x1d
    8000485c:	e5050513          	addi	a0,a0,-432 # 800216a8 <ftable>
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	372080e7          	jalr	882(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004868:	0001d497          	auipc	s1,0x1d
    8000486c:	e5848493          	addi	s1,s1,-424 # 800216c0 <ftable+0x18>
    80004870:	0001e717          	auipc	a4,0x1e
    80004874:	df070713          	addi	a4,a4,-528 # 80022660 <disk>
    if(f->ref == 0){
    80004878:	40dc                	lw	a5,4(s1)
    8000487a:	cf99                	beqz	a5,80004898 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000487c:	02848493          	addi	s1,s1,40
    80004880:	fee49ce3          	bne	s1,a4,80004878 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004884:	0001d517          	auipc	a0,0x1d
    80004888:	e2450513          	addi	a0,a0,-476 # 800216a8 <ftable>
    8000488c:	ffffc097          	auipc	ra,0xffffc
    80004890:	3fa080e7          	jalr	1018(ra) # 80000c86 <release>
  return 0;
    80004894:	4481                	li	s1,0
    80004896:	a819                	j	800048ac <filealloc+0x5e>
      f->ref = 1;
    80004898:	4785                	li	a5,1
    8000489a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000489c:	0001d517          	auipc	a0,0x1d
    800048a0:	e0c50513          	addi	a0,a0,-500 # 800216a8 <ftable>
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	3e2080e7          	jalr	994(ra) # 80000c86 <release>
}
    800048ac:	8526                	mv	a0,s1
    800048ae:	60e2                	ld	ra,24(sp)
    800048b0:	6442                	ld	s0,16(sp)
    800048b2:	64a2                	ld	s1,8(sp)
    800048b4:	6105                	addi	sp,sp,32
    800048b6:	8082                	ret

00000000800048b8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800048b8:	1101                	addi	sp,sp,-32
    800048ba:	ec06                	sd	ra,24(sp)
    800048bc:	e822                	sd	s0,16(sp)
    800048be:	e426                	sd	s1,8(sp)
    800048c0:	1000                	addi	s0,sp,32
    800048c2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800048c4:	0001d517          	auipc	a0,0x1d
    800048c8:	de450513          	addi	a0,a0,-540 # 800216a8 <ftable>
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	306080e7          	jalr	774(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800048d4:	40dc                	lw	a5,4(s1)
    800048d6:	02f05263          	blez	a5,800048fa <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048da:	2785                	addiw	a5,a5,1
    800048dc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048de:	0001d517          	auipc	a0,0x1d
    800048e2:	dca50513          	addi	a0,a0,-566 # 800216a8 <ftable>
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	3a0080e7          	jalr	928(ra) # 80000c86 <release>
  return f;
}
    800048ee:	8526                	mv	a0,s1
    800048f0:	60e2                	ld	ra,24(sp)
    800048f2:	6442                	ld	s0,16(sp)
    800048f4:	64a2                	ld	s1,8(sp)
    800048f6:	6105                	addi	sp,sp,32
    800048f8:	8082                	ret
    panic("filedup");
    800048fa:	00004517          	auipc	a0,0x4
    800048fe:	dd650513          	addi	a0,a0,-554 # 800086d0 <syscalls+0x260>
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	c3a080e7          	jalr	-966(ra) # 8000053c <panic>

000000008000490a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000490a:	7139                	addi	sp,sp,-64
    8000490c:	fc06                	sd	ra,56(sp)
    8000490e:	f822                	sd	s0,48(sp)
    80004910:	f426                	sd	s1,40(sp)
    80004912:	f04a                	sd	s2,32(sp)
    80004914:	ec4e                	sd	s3,24(sp)
    80004916:	e852                	sd	s4,16(sp)
    80004918:	e456                	sd	s5,8(sp)
    8000491a:	0080                	addi	s0,sp,64
    8000491c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000491e:	0001d517          	auipc	a0,0x1d
    80004922:	d8a50513          	addi	a0,a0,-630 # 800216a8 <ftable>
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	2ac080e7          	jalr	684(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000492e:	40dc                	lw	a5,4(s1)
    80004930:	06f05163          	blez	a5,80004992 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004934:	37fd                	addiw	a5,a5,-1
    80004936:	0007871b          	sext.w	a4,a5
    8000493a:	c0dc                	sw	a5,4(s1)
    8000493c:	06e04363          	bgtz	a4,800049a2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004940:	0004a903          	lw	s2,0(s1)
    80004944:	0094ca83          	lbu	s5,9(s1)
    80004948:	0104ba03          	ld	s4,16(s1)
    8000494c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004950:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004954:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004958:	0001d517          	auipc	a0,0x1d
    8000495c:	d5050513          	addi	a0,a0,-688 # 800216a8 <ftable>
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	326080e7          	jalr	806(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004968:	4785                	li	a5,1
    8000496a:	04f90d63          	beq	s2,a5,800049c4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000496e:	3979                	addiw	s2,s2,-2
    80004970:	4785                	li	a5,1
    80004972:	0527e063          	bltu	a5,s2,800049b2 <fileclose+0xa8>
    begin_op();
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	ad0080e7          	jalr	-1328(ra) # 80004446 <begin_op>
    iput(ff.ip);
    8000497e:	854e                	mv	a0,s3
    80004980:	fffff097          	auipc	ra,0xfffff
    80004984:	2da080e7          	jalr	730(ra) # 80003c5a <iput>
    end_op();
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	b38080e7          	jalr	-1224(ra) # 800044c0 <end_op>
    80004990:	a00d                	j	800049b2 <fileclose+0xa8>
    panic("fileclose");
    80004992:	00004517          	auipc	a0,0x4
    80004996:	d4650513          	addi	a0,a0,-698 # 800086d8 <syscalls+0x268>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	ba2080e7          	jalr	-1118(ra) # 8000053c <panic>
    release(&ftable.lock);
    800049a2:	0001d517          	auipc	a0,0x1d
    800049a6:	d0650513          	addi	a0,a0,-762 # 800216a8 <ftable>
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	2dc080e7          	jalr	732(ra) # 80000c86 <release>
  }
}
    800049b2:	70e2                	ld	ra,56(sp)
    800049b4:	7442                	ld	s0,48(sp)
    800049b6:	74a2                	ld	s1,40(sp)
    800049b8:	7902                	ld	s2,32(sp)
    800049ba:	69e2                	ld	s3,24(sp)
    800049bc:	6a42                	ld	s4,16(sp)
    800049be:	6aa2                	ld	s5,8(sp)
    800049c0:	6121                	addi	sp,sp,64
    800049c2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800049c4:	85d6                	mv	a1,s5
    800049c6:	8552                	mv	a0,s4
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	348080e7          	jalr	840(ra) # 80004d10 <pipeclose>
    800049d0:	b7cd                	j	800049b2 <fileclose+0xa8>

00000000800049d2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049d2:	715d                	addi	sp,sp,-80
    800049d4:	e486                	sd	ra,72(sp)
    800049d6:	e0a2                	sd	s0,64(sp)
    800049d8:	fc26                	sd	s1,56(sp)
    800049da:	f84a                	sd	s2,48(sp)
    800049dc:	f44e                	sd	s3,40(sp)
    800049de:	0880                	addi	s0,sp,80
    800049e0:	84aa                	mv	s1,a0
    800049e2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049e4:	ffffd097          	auipc	ra,0xffffd
    800049e8:	fc2080e7          	jalr	-62(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049ec:	409c                	lw	a5,0(s1)
    800049ee:	37f9                	addiw	a5,a5,-2
    800049f0:	4705                	li	a4,1
    800049f2:	04f76763          	bltu	a4,a5,80004a40 <filestat+0x6e>
    800049f6:	892a                	mv	s2,a0
    ilock(f->ip);
    800049f8:	6c88                	ld	a0,24(s1)
    800049fa:	fffff097          	auipc	ra,0xfffff
    800049fe:	0a6080e7          	jalr	166(ra) # 80003aa0 <ilock>
    stati(f->ip, &st);
    80004a02:	fb840593          	addi	a1,s0,-72
    80004a06:	6c88                	ld	a0,24(s1)
    80004a08:	fffff097          	auipc	ra,0xfffff
    80004a0c:	322080e7          	jalr	802(ra) # 80003d2a <stati>
    iunlock(f->ip);
    80004a10:	6c88                	ld	a0,24(s1)
    80004a12:	fffff097          	auipc	ra,0xfffff
    80004a16:	150080e7          	jalr	336(ra) # 80003b62 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a1a:	46e1                	li	a3,24
    80004a1c:	fb840613          	addi	a2,s0,-72
    80004a20:	85ce                	mv	a1,s3
    80004a22:	05093503          	ld	a0,80(s2)
    80004a26:	ffffd097          	auipc	ra,0xffffd
    80004a2a:	c40080e7          	jalr	-960(ra) # 80001666 <copyout>
    80004a2e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a32:	60a6                	ld	ra,72(sp)
    80004a34:	6406                	ld	s0,64(sp)
    80004a36:	74e2                	ld	s1,56(sp)
    80004a38:	7942                	ld	s2,48(sp)
    80004a3a:	79a2                	ld	s3,40(sp)
    80004a3c:	6161                	addi	sp,sp,80
    80004a3e:	8082                	ret
  return -1;
    80004a40:	557d                	li	a0,-1
    80004a42:	bfc5                	j	80004a32 <filestat+0x60>

0000000080004a44 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a44:	7179                	addi	sp,sp,-48
    80004a46:	f406                	sd	ra,40(sp)
    80004a48:	f022                	sd	s0,32(sp)
    80004a4a:	ec26                	sd	s1,24(sp)
    80004a4c:	e84a                	sd	s2,16(sp)
    80004a4e:	e44e                	sd	s3,8(sp)
    80004a50:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a52:	00854783          	lbu	a5,8(a0)
    80004a56:	c3d5                	beqz	a5,80004afa <fileread+0xb6>
    80004a58:	84aa                	mv	s1,a0
    80004a5a:	89ae                	mv	s3,a1
    80004a5c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a5e:	411c                	lw	a5,0(a0)
    80004a60:	4705                	li	a4,1
    80004a62:	04e78963          	beq	a5,a4,80004ab4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a66:	470d                	li	a4,3
    80004a68:	04e78d63          	beq	a5,a4,80004ac2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a6c:	4709                	li	a4,2
    80004a6e:	06e79e63          	bne	a5,a4,80004aea <fileread+0xa6>
    ilock(f->ip);
    80004a72:	6d08                	ld	a0,24(a0)
    80004a74:	fffff097          	auipc	ra,0xfffff
    80004a78:	02c080e7          	jalr	44(ra) # 80003aa0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a7c:	874a                	mv	a4,s2
    80004a7e:	5094                	lw	a3,32(s1)
    80004a80:	864e                	mv	a2,s3
    80004a82:	4585                	li	a1,1
    80004a84:	6c88                	ld	a0,24(s1)
    80004a86:	fffff097          	auipc	ra,0xfffff
    80004a8a:	2ce080e7          	jalr	718(ra) # 80003d54 <readi>
    80004a8e:	892a                	mv	s2,a0
    80004a90:	00a05563          	blez	a0,80004a9a <fileread+0x56>
      f->off += r;
    80004a94:	509c                	lw	a5,32(s1)
    80004a96:	9fa9                	addw	a5,a5,a0
    80004a98:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a9a:	6c88                	ld	a0,24(s1)
    80004a9c:	fffff097          	auipc	ra,0xfffff
    80004aa0:	0c6080e7          	jalr	198(ra) # 80003b62 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004aa4:	854a                	mv	a0,s2
    80004aa6:	70a2                	ld	ra,40(sp)
    80004aa8:	7402                	ld	s0,32(sp)
    80004aaa:	64e2                	ld	s1,24(sp)
    80004aac:	6942                	ld	s2,16(sp)
    80004aae:	69a2                	ld	s3,8(sp)
    80004ab0:	6145                	addi	sp,sp,48
    80004ab2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ab4:	6908                	ld	a0,16(a0)
    80004ab6:	00000097          	auipc	ra,0x0
    80004aba:	3c2080e7          	jalr	962(ra) # 80004e78 <piperead>
    80004abe:	892a                	mv	s2,a0
    80004ac0:	b7d5                	j	80004aa4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ac2:	02451783          	lh	a5,36(a0)
    80004ac6:	03079693          	slli	a3,a5,0x30
    80004aca:	92c1                	srli	a3,a3,0x30
    80004acc:	4725                	li	a4,9
    80004ace:	02d76863          	bltu	a4,a3,80004afe <fileread+0xba>
    80004ad2:	0792                	slli	a5,a5,0x4
    80004ad4:	0001d717          	auipc	a4,0x1d
    80004ad8:	b3470713          	addi	a4,a4,-1228 # 80021608 <devsw>
    80004adc:	97ba                	add	a5,a5,a4
    80004ade:	639c                	ld	a5,0(a5)
    80004ae0:	c38d                	beqz	a5,80004b02 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ae2:	4505                	li	a0,1
    80004ae4:	9782                	jalr	a5
    80004ae6:	892a                	mv	s2,a0
    80004ae8:	bf75                	j	80004aa4 <fileread+0x60>
    panic("fileread");
    80004aea:	00004517          	auipc	a0,0x4
    80004aee:	bfe50513          	addi	a0,a0,-1026 # 800086e8 <syscalls+0x278>
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	a4a080e7          	jalr	-1462(ra) # 8000053c <panic>
    return -1;
    80004afa:	597d                	li	s2,-1
    80004afc:	b765                	j	80004aa4 <fileread+0x60>
      return -1;
    80004afe:	597d                	li	s2,-1
    80004b00:	b755                	j	80004aa4 <fileread+0x60>
    80004b02:	597d                	li	s2,-1
    80004b04:	b745                	j	80004aa4 <fileread+0x60>

0000000080004b06 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004b06:	00954783          	lbu	a5,9(a0)
    80004b0a:	10078e63          	beqz	a5,80004c26 <filewrite+0x120>
{
    80004b0e:	715d                	addi	sp,sp,-80
    80004b10:	e486                	sd	ra,72(sp)
    80004b12:	e0a2                	sd	s0,64(sp)
    80004b14:	fc26                	sd	s1,56(sp)
    80004b16:	f84a                	sd	s2,48(sp)
    80004b18:	f44e                	sd	s3,40(sp)
    80004b1a:	f052                	sd	s4,32(sp)
    80004b1c:	ec56                	sd	s5,24(sp)
    80004b1e:	e85a                	sd	s6,16(sp)
    80004b20:	e45e                	sd	s7,8(sp)
    80004b22:	e062                	sd	s8,0(sp)
    80004b24:	0880                	addi	s0,sp,80
    80004b26:	892a                	mv	s2,a0
    80004b28:	8b2e                	mv	s6,a1
    80004b2a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b2c:	411c                	lw	a5,0(a0)
    80004b2e:	4705                	li	a4,1
    80004b30:	02e78263          	beq	a5,a4,80004b54 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b34:	470d                	li	a4,3
    80004b36:	02e78563          	beq	a5,a4,80004b60 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b3a:	4709                	li	a4,2
    80004b3c:	0ce79d63          	bne	a5,a4,80004c16 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b40:	0ac05b63          	blez	a2,80004bf6 <filewrite+0xf0>
    int i = 0;
    80004b44:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004b46:	6b85                	lui	s7,0x1
    80004b48:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004b4c:	6c05                	lui	s8,0x1
    80004b4e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004b52:	a851                	j	80004be6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004b54:	6908                	ld	a0,16(a0)
    80004b56:	00000097          	auipc	ra,0x0
    80004b5a:	22a080e7          	jalr	554(ra) # 80004d80 <pipewrite>
    80004b5e:	a045                	j	80004bfe <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b60:	02451783          	lh	a5,36(a0)
    80004b64:	03079693          	slli	a3,a5,0x30
    80004b68:	92c1                	srli	a3,a3,0x30
    80004b6a:	4725                	li	a4,9
    80004b6c:	0ad76f63          	bltu	a4,a3,80004c2a <filewrite+0x124>
    80004b70:	0792                	slli	a5,a5,0x4
    80004b72:	0001d717          	auipc	a4,0x1d
    80004b76:	a9670713          	addi	a4,a4,-1386 # 80021608 <devsw>
    80004b7a:	97ba                	add	a5,a5,a4
    80004b7c:	679c                	ld	a5,8(a5)
    80004b7e:	cbc5                	beqz	a5,80004c2e <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004b80:	4505                	li	a0,1
    80004b82:	9782                	jalr	a5
    80004b84:	a8ad                	j	80004bfe <filewrite+0xf8>
      if(n1 > max)
    80004b86:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004b8a:	00000097          	auipc	ra,0x0
    80004b8e:	8bc080e7          	jalr	-1860(ra) # 80004446 <begin_op>
      ilock(f->ip);
    80004b92:	01893503          	ld	a0,24(s2)
    80004b96:	fffff097          	auipc	ra,0xfffff
    80004b9a:	f0a080e7          	jalr	-246(ra) # 80003aa0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b9e:	8756                	mv	a4,s5
    80004ba0:	02092683          	lw	a3,32(s2)
    80004ba4:	01698633          	add	a2,s3,s6
    80004ba8:	4585                	li	a1,1
    80004baa:	01893503          	ld	a0,24(s2)
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	29e080e7          	jalr	670(ra) # 80003e4c <writei>
    80004bb6:	84aa                	mv	s1,a0
    80004bb8:	00a05763          	blez	a0,80004bc6 <filewrite+0xc0>
        f->off += r;
    80004bbc:	02092783          	lw	a5,32(s2)
    80004bc0:	9fa9                	addw	a5,a5,a0
    80004bc2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004bc6:	01893503          	ld	a0,24(s2)
    80004bca:	fffff097          	auipc	ra,0xfffff
    80004bce:	f98080e7          	jalr	-104(ra) # 80003b62 <iunlock>
      end_op();
    80004bd2:	00000097          	auipc	ra,0x0
    80004bd6:	8ee080e7          	jalr	-1810(ra) # 800044c0 <end_op>

      if(r != n1){
    80004bda:	009a9f63          	bne	s5,s1,80004bf8 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004bde:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004be2:	0149db63          	bge	s3,s4,80004bf8 <filewrite+0xf2>
      int n1 = n - i;
    80004be6:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004bea:	0004879b          	sext.w	a5,s1
    80004bee:	f8fbdce3          	bge	s7,a5,80004b86 <filewrite+0x80>
    80004bf2:	84e2                	mv	s1,s8
    80004bf4:	bf49                	j	80004b86 <filewrite+0x80>
    int i = 0;
    80004bf6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004bf8:	033a1d63          	bne	s4,s3,80004c32 <filewrite+0x12c>
    80004bfc:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bfe:	60a6                	ld	ra,72(sp)
    80004c00:	6406                	ld	s0,64(sp)
    80004c02:	74e2                	ld	s1,56(sp)
    80004c04:	7942                	ld	s2,48(sp)
    80004c06:	79a2                	ld	s3,40(sp)
    80004c08:	7a02                	ld	s4,32(sp)
    80004c0a:	6ae2                	ld	s5,24(sp)
    80004c0c:	6b42                	ld	s6,16(sp)
    80004c0e:	6ba2                	ld	s7,8(sp)
    80004c10:	6c02                	ld	s8,0(sp)
    80004c12:	6161                	addi	sp,sp,80
    80004c14:	8082                	ret
    panic("filewrite");
    80004c16:	00004517          	auipc	a0,0x4
    80004c1a:	ae250513          	addi	a0,a0,-1310 # 800086f8 <syscalls+0x288>
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>
    return -1;
    80004c26:	557d                	li	a0,-1
}
    80004c28:	8082                	ret
      return -1;
    80004c2a:	557d                	li	a0,-1
    80004c2c:	bfc9                	j	80004bfe <filewrite+0xf8>
    80004c2e:	557d                	li	a0,-1
    80004c30:	b7f9                	j	80004bfe <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004c32:	557d                	li	a0,-1
    80004c34:	b7e9                	j	80004bfe <filewrite+0xf8>

0000000080004c36 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c36:	7179                	addi	sp,sp,-48
    80004c38:	f406                	sd	ra,40(sp)
    80004c3a:	f022                	sd	s0,32(sp)
    80004c3c:	ec26                	sd	s1,24(sp)
    80004c3e:	e84a                	sd	s2,16(sp)
    80004c40:	e44e                	sd	s3,8(sp)
    80004c42:	e052                	sd	s4,0(sp)
    80004c44:	1800                	addi	s0,sp,48
    80004c46:	84aa                	mv	s1,a0
    80004c48:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c4a:	0005b023          	sd	zero,0(a1)
    80004c4e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c52:	00000097          	auipc	ra,0x0
    80004c56:	bfc080e7          	jalr	-1028(ra) # 8000484e <filealloc>
    80004c5a:	e088                	sd	a0,0(s1)
    80004c5c:	c551                	beqz	a0,80004ce8 <pipealloc+0xb2>
    80004c5e:	00000097          	auipc	ra,0x0
    80004c62:	bf0080e7          	jalr	-1040(ra) # 8000484e <filealloc>
    80004c66:	00aa3023          	sd	a0,0(s4)
    80004c6a:	c92d                	beqz	a0,80004cdc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	e76080e7          	jalr	-394(ra) # 80000ae2 <kalloc>
    80004c74:	892a                	mv	s2,a0
    80004c76:	c125                	beqz	a0,80004cd6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c78:	4985                	li	s3,1
    80004c7a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c7e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c82:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c86:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c8a:	00004597          	auipc	a1,0x4
    80004c8e:	a7e58593          	addi	a1,a1,-1410 # 80008708 <syscalls+0x298>
    80004c92:	ffffc097          	auipc	ra,0xffffc
    80004c96:	eb0080e7          	jalr	-336(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004c9a:	609c                	ld	a5,0(s1)
    80004c9c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ca0:	609c                	ld	a5,0(s1)
    80004ca2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ca6:	609c                	ld	a5,0(s1)
    80004ca8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004cac:	609c                	ld	a5,0(s1)
    80004cae:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004cb2:	000a3783          	ld	a5,0(s4)
    80004cb6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004cba:	000a3783          	ld	a5,0(s4)
    80004cbe:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004cc2:	000a3783          	ld	a5,0(s4)
    80004cc6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004cca:	000a3783          	ld	a5,0(s4)
    80004cce:	0127b823          	sd	s2,16(a5)
  return 0;
    80004cd2:	4501                	li	a0,0
    80004cd4:	a025                	j	80004cfc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004cd6:	6088                	ld	a0,0(s1)
    80004cd8:	e501                	bnez	a0,80004ce0 <pipealloc+0xaa>
    80004cda:	a039                	j	80004ce8 <pipealloc+0xb2>
    80004cdc:	6088                	ld	a0,0(s1)
    80004cde:	c51d                	beqz	a0,80004d0c <pipealloc+0xd6>
    fileclose(*f0);
    80004ce0:	00000097          	auipc	ra,0x0
    80004ce4:	c2a080e7          	jalr	-982(ra) # 8000490a <fileclose>
  if(*f1)
    80004ce8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004cec:	557d                	li	a0,-1
  if(*f1)
    80004cee:	c799                	beqz	a5,80004cfc <pipealloc+0xc6>
    fileclose(*f1);
    80004cf0:	853e                	mv	a0,a5
    80004cf2:	00000097          	auipc	ra,0x0
    80004cf6:	c18080e7          	jalr	-1000(ra) # 8000490a <fileclose>
  return -1;
    80004cfa:	557d                	li	a0,-1
}
    80004cfc:	70a2                	ld	ra,40(sp)
    80004cfe:	7402                	ld	s0,32(sp)
    80004d00:	64e2                	ld	s1,24(sp)
    80004d02:	6942                	ld	s2,16(sp)
    80004d04:	69a2                	ld	s3,8(sp)
    80004d06:	6a02                	ld	s4,0(sp)
    80004d08:	6145                	addi	sp,sp,48
    80004d0a:	8082                	ret
  return -1;
    80004d0c:	557d                	li	a0,-1
    80004d0e:	b7fd                	j	80004cfc <pipealloc+0xc6>

0000000080004d10 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d10:	1101                	addi	sp,sp,-32
    80004d12:	ec06                	sd	ra,24(sp)
    80004d14:	e822                	sd	s0,16(sp)
    80004d16:	e426                	sd	s1,8(sp)
    80004d18:	e04a                	sd	s2,0(sp)
    80004d1a:	1000                	addi	s0,sp,32
    80004d1c:	84aa                	mv	s1,a0
    80004d1e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d20:	ffffc097          	auipc	ra,0xffffc
    80004d24:	eb2080e7          	jalr	-334(ra) # 80000bd2 <acquire>
  if(writable){
    80004d28:	02090d63          	beqz	s2,80004d62 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d2c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d30:	21848513          	addi	a0,s1,536
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	486080e7          	jalr	1158(ra) # 800021ba <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d3c:	2204b783          	ld	a5,544(s1)
    80004d40:	eb95                	bnez	a5,80004d74 <pipeclose+0x64>
    release(&pi->lock);
    80004d42:	8526                	mv	a0,s1
    80004d44:	ffffc097          	auipc	ra,0xffffc
    80004d48:	f42080e7          	jalr	-190(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004d4c:	8526                	mv	a0,s1
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	c96080e7          	jalr	-874(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004d56:	60e2                	ld	ra,24(sp)
    80004d58:	6442                	ld	s0,16(sp)
    80004d5a:	64a2                	ld	s1,8(sp)
    80004d5c:	6902                	ld	s2,0(sp)
    80004d5e:	6105                	addi	sp,sp,32
    80004d60:	8082                	ret
    pi->readopen = 0;
    80004d62:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d66:	21c48513          	addi	a0,s1,540
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	450080e7          	jalr	1104(ra) # 800021ba <wakeup>
    80004d72:	b7e9                	j	80004d3c <pipeclose+0x2c>
    release(&pi->lock);
    80004d74:	8526                	mv	a0,s1
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	f10080e7          	jalr	-240(ra) # 80000c86 <release>
}
    80004d7e:	bfe1                	j	80004d56 <pipeclose+0x46>

0000000080004d80 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d80:	711d                	addi	sp,sp,-96
    80004d82:	ec86                	sd	ra,88(sp)
    80004d84:	e8a2                	sd	s0,80(sp)
    80004d86:	e4a6                	sd	s1,72(sp)
    80004d88:	e0ca                	sd	s2,64(sp)
    80004d8a:	fc4e                	sd	s3,56(sp)
    80004d8c:	f852                	sd	s4,48(sp)
    80004d8e:	f456                	sd	s5,40(sp)
    80004d90:	f05a                	sd	s6,32(sp)
    80004d92:	ec5e                	sd	s7,24(sp)
    80004d94:	e862                	sd	s8,16(sp)
    80004d96:	1080                	addi	s0,sp,96
    80004d98:	84aa                	mv	s1,a0
    80004d9a:	8aae                	mv	s5,a1
    80004d9c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d9e:	ffffd097          	auipc	ra,0xffffd
    80004da2:	c08080e7          	jalr	-1016(ra) # 800019a6 <myproc>
    80004da6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004da8:	8526                	mv	a0,s1
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	e28080e7          	jalr	-472(ra) # 80000bd2 <acquire>
  while(i < n){
    80004db2:	0b405663          	blez	s4,80004e5e <pipewrite+0xde>
  int i = 0;
    80004db6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004db8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004dba:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004dbe:	21c48b93          	addi	s7,s1,540
    80004dc2:	a089                	j	80004e04 <pipewrite+0x84>
      release(&pi->lock);
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	ec0080e7          	jalr	-320(ra) # 80000c86 <release>
      return -1;
    80004dce:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004dd0:	854a                	mv	a0,s2
    80004dd2:	60e6                	ld	ra,88(sp)
    80004dd4:	6446                	ld	s0,80(sp)
    80004dd6:	64a6                	ld	s1,72(sp)
    80004dd8:	6906                	ld	s2,64(sp)
    80004dda:	79e2                	ld	s3,56(sp)
    80004ddc:	7a42                	ld	s4,48(sp)
    80004dde:	7aa2                	ld	s5,40(sp)
    80004de0:	7b02                	ld	s6,32(sp)
    80004de2:	6be2                	ld	s7,24(sp)
    80004de4:	6c42                	ld	s8,16(sp)
    80004de6:	6125                	addi	sp,sp,96
    80004de8:	8082                	ret
      wakeup(&pi->nread);
    80004dea:	8562                	mv	a0,s8
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	3ce080e7          	jalr	974(ra) # 800021ba <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004df4:	85a6                	mv	a1,s1
    80004df6:	855e                	mv	a0,s7
    80004df8:	ffffd097          	auipc	ra,0xffffd
    80004dfc:	35e080e7          	jalr	862(ra) # 80002156 <sleep>
  while(i < n){
    80004e00:	07495063          	bge	s2,s4,80004e60 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004e04:	2204a783          	lw	a5,544(s1)
    80004e08:	dfd5                	beqz	a5,80004dc4 <pipewrite+0x44>
    80004e0a:	854e                	mv	a0,s3
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	5fe080e7          	jalr	1534(ra) # 8000240a <killed>
    80004e14:	f945                	bnez	a0,80004dc4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e16:	2184a783          	lw	a5,536(s1)
    80004e1a:	21c4a703          	lw	a4,540(s1)
    80004e1e:	2007879b          	addiw	a5,a5,512
    80004e22:	fcf704e3          	beq	a4,a5,80004dea <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e26:	4685                	li	a3,1
    80004e28:	01590633          	add	a2,s2,s5
    80004e2c:	faf40593          	addi	a1,s0,-81
    80004e30:	0509b503          	ld	a0,80(s3)
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	8be080e7          	jalr	-1858(ra) # 800016f2 <copyin>
    80004e3c:	03650263          	beq	a0,s6,80004e60 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e40:	21c4a783          	lw	a5,540(s1)
    80004e44:	0017871b          	addiw	a4,a5,1
    80004e48:	20e4ae23          	sw	a4,540(s1)
    80004e4c:	1ff7f793          	andi	a5,a5,511
    80004e50:	97a6                	add	a5,a5,s1
    80004e52:	faf44703          	lbu	a4,-81(s0)
    80004e56:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e5a:	2905                	addiw	s2,s2,1
    80004e5c:	b755                	j	80004e00 <pipewrite+0x80>
  int i = 0;
    80004e5e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e60:	21848513          	addi	a0,s1,536
    80004e64:	ffffd097          	auipc	ra,0xffffd
    80004e68:	356080e7          	jalr	854(ra) # 800021ba <wakeup>
  release(&pi->lock);
    80004e6c:	8526                	mv	a0,s1
    80004e6e:	ffffc097          	auipc	ra,0xffffc
    80004e72:	e18080e7          	jalr	-488(ra) # 80000c86 <release>
  return i;
    80004e76:	bfa9                	j	80004dd0 <pipewrite+0x50>

0000000080004e78 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e78:	715d                	addi	sp,sp,-80
    80004e7a:	e486                	sd	ra,72(sp)
    80004e7c:	e0a2                	sd	s0,64(sp)
    80004e7e:	fc26                	sd	s1,56(sp)
    80004e80:	f84a                	sd	s2,48(sp)
    80004e82:	f44e                	sd	s3,40(sp)
    80004e84:	f052                	sd	s4,32(sp)
    80004e86:	ec56                	sd	s5,24(sp)
    80004e88:	e85a                	sd	s6,16(sp)
    80004e8a:	0880                	addi	s0,sp,80
    80004e8c:	84aa                	mv	s1,a0
    80004e8e:	892e                	mv	s2,a1
    80004e90:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e92:	ffffd097          	auipc	ra,0xffffd
    80004e96:	b14080e7          	jalr	-1260(ra) # 800019a6 <myproc>
    80004e9a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	d34080e7          	jalr	-716(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ea6:	2184a703          	lw	a4,536(s1)
    80004eaa:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004eae:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004eb2:	02f71763          	bne	a4,a5,80004ee0 <piperead+0x68>
    80004eb6:	2244a783          	lw	a5,548(s1)
    80004eba:	c39d                	beqz	a5,80004ee0 <piperead+0x68>
    if(killed(pr)){
    80004ebc:	8552                	mv	a0,s4
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	54c080e7          	jalr	1356(ra) # 8000240a <killed>
    80004ec6:	e949                	bnez	a0,80004f58 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ec8:	85a6                	mv	a1,s1
    80004eca:	854e                	mv	a0,s3
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	28a080e7          	jalr	650(ra) # 80002156 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ed4:	2184a703          	lw	a4,536(s1)
    80004ed8:	21c4a783          	lw	a5,540(s1)
    80004edc:	fcf70de3          	beq	a4,a5,80004eb6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ee0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ee2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ee4:	05505463          	blez	s5,80004f2c <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004ee8:	2184a783          	lw	a5,536(s1)
    80004eec:	21c4a703          	lw	a4,540(s1)
    80004ef0:	02f70e63          	beq	a4,a5,80004f2c <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ef4:	0017871b          	addiw	a4,a5,1
    80004ef8:	20e4ac23          	sw	a4,536(s1)
    80004efc:	1ff7f793          	andi	a5,a5,511
    80004f00:	97a6                	add	a5,a5,s1
    80004f02:	0187c783          	lbu	a5,24(a5)
    80004f06:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f0a:	4685                	li	a3,1
    80004f0c:	fbf40613          	addi	a2,s0,-65
    80004f10:	85ca                	mv	a1,s2
    80004f12:	050a3503          	ld	a0,80(s4)
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	750080e7          	jalr	1872(ra) # 80001666 <copyout>
    80004f1e:	01650763          	beq	a0,s6,80004f2c <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f22:	2985                	addiw	s3,s3,1
    80004f24:	0905                	addi	s2,s2,1
    80004f26:	fd3a91e3          	bne	s5,s3,80004ee8 <piperead+0x70>
    80004f2a:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f2c:	21c48513          	addi	a0,s1,540
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	28a080e7          	jalr	650(ra) # 800021ba <wakeup>
  release(&pi->lock);
    80004f38:	8526                	mv	a0,s1
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	d4c080e7          	jalr	-692(ra) # 80000c86 <release>
  return i;
}
    80004f42:	854e                	mv	a0,s3
    80004f44:	60a6                	ld	ra,72(sp)
    80004f46:	6406                	ld	s0,64(sp)
    80004f48:	74e2                	ld	s1,56(sp)
    80004f4a:	7942                	ld	s2,48(sp)
    80004f4c:	79a2                	ld	s3,40(sp)
    80004f4e:	7a02                	ld	s4,32(sp)
    80004f50:	6ae2                	ld	s5,24(sp)
    80004f52:	6b42                	ld	s6,16(sp)
    80004f54:	6161                	addi	sp,sp,80
    80004f56:	8082                	ret
      release(&pi->lock);
    80004f58:	8526                	mv	a0,s1
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	d2c080e7          	jalr	-724(ra) # 80000c86 <release>
      return -1;
    80004f62:	59fd                	li	s3,-1
    80004f64:	bff9                	j	80004f42 <piperead+0xca>

0000000080004f66 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f66:	1141                	addi	sp,sp,-16
    80004f68:	e422                	sd	s0,8(sp)
    80004f6a:	0800                	addi	s0,sp,16
    80004f6c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f6e:	8905                	andi	a0,a0,1
    80004f70:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004f72:	8b89                	andi	a5,a5,2
    80004f74:	c399                	beqz	a5,80004f7a <flags2perm+0x14>
      perm |= PTE_W;
    80004f76:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f7a:	6422                	ld	s0,8(sp)
    80004f7c:	0141                	addi	sp,sp,16
    80004f7e:	8082                	ret

0000000080004f80 <exec>:

int
exec(char *path, char **argv)
{
    80004f80:	df010113          	addi	sp,sp,-528
    80004f84:	20113423          	sd	ra,520(sp)
    80004f88:	20813023          	sd	s0,512(sp)
    80004f8c:	ffa6                	sd	s1,504(sp)
    80004f8e:	fbca                	sd	s2,496(sp)
    80004f90:	f7ce                	sd	s3,488(sp)
    80004f92:	f3d2                	sd	s4,480(sp)
    80004f94:	efd6                	sd	s5,472(sp)
    80004f96:	ebda                	sd	s6,464(sp)
    80004f98:	e7de                	sd	s7,456(sp)
    80004f9a:	e3e2                	sd	s8,448(sp)
    80004f9c:	ff66                	sd	s9,440(sp)
    80004f9e:	fb6a                	sd	s10,432(sp)
    80004fa0:	f76e                	sd	s11,424(sp)
    80004fa2:	0c00                	addi	s0,sp,528
    80004fa4:	892a                	mv	s2,a0
    80004fa6:	dea43c23          	sd	a0,-520(s0)
    80004faa:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	9f8080e7          	jalr	-1544(ra) # 800019a6 <myproc>
    80004fb6:	84aa                	mv	s1,a0

  begin_op();
    80004fb8:	fffff097          	auipc	ra,0xfffff
    80004fbc:	48e080e7          	jalr	1166(ra) # 80004446 <begin_op>

  if((ip = namei(path)) == 0){
    80004fc0:	854a                	mv	a0,s2
    80004fc2:	fffff097          	auipc	ra,0xfffff
    80004fc6:	284080e7          	jalr	644(ra) # 80004246 <namei>
    80004fca:	c92d                	beqz	a0,8000503c <exec+0xbc>
    80004fcc:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004fce:	fffff097          	auipc	ra,0xfffff
    80004fd2:	ad2080e7          	jalr	-1326(ra) # 80003aa0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fd6:	04000713          	li	a4,64
    80004fda:	4681                	li	a3,0
    80004fdc:	e5040613          	addi	a2,s0,-432
    80004fe0:	4581                	li	a1,0
    80004fe2:	8552                	mv	a0,s4
    80004fe4:	fffff097          	auipc	ra,0xfffff
    80004fe8:	d70080e7          	jalr	-656(ra) # 80003d54 <readi>
    80004fec:	04000793          	li	a5,64
    80004ff0:	00f51a63          	bne	a0,a5,80005004 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004ff4:	e5042703          	lw	a4,-432(s0)
    80004ff8:	464c47b7          	lui	a5,0x464c4
    80004ffc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005000:	04f70463          	beq	a4,a5,80005048 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005004:	8552                	mv	a0,s4
    80005006:	fffff097          	auipc	ra,0xfffff
    8000500a:	cfc080e7          	jalr	-772(ra) # 80003d02 <iunlockput>
    end_op();
    8000500e:	fffff097          	auipc	ra,0xfffff
    80005012:	4b2080e7          	jalr	1202(ra) # 800044c0 <end_op>
  }
  return -1;
    80005016:	557d                	li	a0,-1
}
    80005018:	20813083          	ld	ra,520(sp)
    8000501c:	20013403          	ld	s0,512(sp)
    80005020:	74fe                	ld	s1,504(sp)
    80005022:	795e                	ld	s2,496(sp)
    80005024:	79be                	ld	s3,488(sp)
    80005026:	7a1e                	ld	s4,480(sp)
    80005028:	6afe                	ld	s5,472(sp)
    8000502a:	6b5e                	ld	s6,464(sp)
    8000502c:	6bbe                	ld	s7,456(sp)
    8000502e:	6c1e                	ld	s8,448(sp)
    80005030:	7cfa                	ld	s9,440(sp)
    80005032:	7d5a                	ld	s10,432(sp)
    80005034:	7dba                	ld	s11,424(sp)
    80005036:	21010113          	addi	sp,sp,528
    8000503a:	8082                	ret
    end_op();
    8000503c:	fffff097          	auipc	ra,0xfffff
    80005040:	484080e7          	jalr	1156(ra) # 800044c0 <end_op>
    return -1;
    80005044:	557d                	li	a0,-1
    80005046:	bfc9                	j	80005018 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005048:	8526                	mv	a0,s1
    8000504a:	ffffd097          	auipc	ra,0xffffd
    8000504e:	a86080e7          	jalr	-1402(ra) # 80001ad0 <proc_pagetable>
    80005052:	8b2a                	mv	s6,a0
    80005054:	d945                	beqz	a0,80005004 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005056:	e7042d03          	lw	s10,-400(s0)
    8000505a:	e8845783          	lhu	a5,-376(s0)
    8000505e:	10078463          	beqz	a5,80005166 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005062:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005064:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005066:	6c85                	lui	s9,0x1
    80005068:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000506c:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005070:	6a85                	lui	s5,0x1
    80005072:	a0b5                	j	800050de <exec+0x15e>
      panic("loadseg: address should exist");
    80005074:	00003517          	auipc	a0,0x3
    80005078:	69c50513          	addi	a0,a0,1692 # 80008710 <syscalls+0x2a0>
    8000507c:	ffffb097          	auipc	ra,0xffffb
    80005080:	4c0080e7          	jalr	1216(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005084:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005086:	8726                	mv	a4,s1
    80005088:	012c06bb          	addw	a3,s8,s2
    8000508c:	4581                	li	a1,0
    8000508e:	8552                	mv	a0,s4
    80005090:	fffff097          	auipc	ra,0xfffff
    80005094:	cc4080e7          	jalr	-828(ra) # 80003d54 <readi>
    80005098:	2501                	sext.w	a0,a0
    8000509a:	24a49863          	bne	s1,a0,800052ea <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    8000509e:	012a893b          	addw	s2,s5,s2
    800050a2:	03397563          	bgeu	s2,s3,800050cc <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800050a6:	02091593          	slli	a1,s2,0x20
    800050aa:	9181                	srli	a1,a1,0x20
    800050ac:	95de                	add	a1,a1,s7
    800050ae:	855a                	mv	a0,s6
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	fa6080e7          	jalr	-90(ra) # 80001056 <walkaddr>
    800050b8:	862a                	mv	a2,a0
    if(pa == 0)
    800050ba:	dd4d                	beqz	a0,80005074 <exec+0xf4>
    if(sz - i < PGSIZE)
    800050bc:	412984bb          	subw	s1,s3,s2
    800050c0:	0004879b          	sext.w	a5,s1
    800050c4:	fcfcf0e3          	bgeu	s9,a5,80005084 <exec+0x104>
    800050c8:	84d6                	mv	s1,s5
    800050ca:	bf6d                	j	80005084 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050cc:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050d0:	2d85                	addiw	s11,s11,1
    800050d2:	038d0d1b          	addiw	s10,s10,56
    800050d6:	e8845783          	lhu	a5,-376(s0)
    800050da:	08fdd763          	bge	s11,a5,80005168 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050de:	2d01                	sext.w	s10,s10
    800050e0:	03800713          	li	a4,56
    800050e4:	86ea                	mv	a3,s10
    800050e6:	e1840613          	addi	a2,s0,-488
    800050ea:	4581                	li	a1,0
    800050ec:	8552                	mv	a0,s4
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	c66080e7          	jalr	-922(ra) # 80003d54 <readi>
    800050f6:	03800793          	li	a5,56
    800050fa:	1ef51663          	bne	a0,a5,800052e6 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800050fe:	e1842783          	lw	a5,-488(s0)
    80005102:	4705                	li	a4,1
    80005104:	fce796e3          	bne	a5,a4,800050d0 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005108:	e4043483          	ld	s1,-448(s0)
    8000510c:	e3843783          	ld	a5,-456(s0)
    80005110:	1ef4e863          	bltu	s1,a5,80005300 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005114:	e2843783          	ld	a5,-472(s0)
    80005118:	94be                	add	s1,s1,a5
    8000511a:	1ef4e663          	bltu	s1,a5,80005306 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    8000511e:	df043703          	ld	a4,-528(s0)
    80005122:	8ff9                	and	a5,a5,a4
    80005124:	1e079463          	bnez	a5,8000530c <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005128:	e1c42503          	lw	a0,-484(s0)
    8000512c:	00000097          	auipc	ra,0x0
    80005130:	e3a080e7          	jalr	-454(ra) # 80004f66 <flags2perm>
    80005134:	86aa                	mv	a3,a0
    80005136:	8626                	mv	a2,s1
    80005138:	85ca                	mv	a1,s2
    8000513a:	855a                	mv	a0,s6
    8000513c:	ffffc097          	auipc	ra,0xffffc
    80005140:	2ce080e7          	jalr	718(ra) # 8000140a <uvmalloc>
    80005144:	e0a43423          	sd	a0,-504(s0)
    80005148:	1c050563          	beqz	a0,80005312 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000514c:	e2843b83          	ld	s7,-472(s0)
    80005150:	e2042c03          	lw	s8,-480(s0)
    80005154:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005158:	00098463          	beqz	s3,80005160 <exec+0x1e0>
    8000515c:	4901                	li	s2,0
    8000515e:	b7a1                	j	800050a6 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005160:	e0843903          	ld	s2,-504(s0)
    80005164:	b7b5                	j	800050d0 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005166:	4901                	li	s2,0
  iunlockput(ip);
    80005168:	8552                	mv	a0,s4
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	b98080e7          	jalr	-1128(ra) # 80003d02 <iunlockput>
  end_op();
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	34e080e7          	jalr	846(ra) # 800044c0 <end_op>
  p = myproc();
    8000517a:	ffffd097          	auipc	ra,0xffffd
    8000517e:	82c080e7          	jalr	-2004(ra) # 800019a6 <myproc>
    80005182:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005184:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005188:	6985                	lui	s3,0x1
    8000518a:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000518c:	99ca                	add	s3,s3,s2
    8000518e:	77fd                	lui	a5,0xfffff
    80005190:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005194:	4691                	li	a3,4
    80005196:	6609                	lui	a2,0x2
    80005198:	964e                	add	a2,a2,s3
    8000519a:	85ce                	mv	a1,s3
    8000519c:	855a                	mv	a0,s6
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	26c080e7          	jalr	620(ra) # 8000140a <uvmalloc>
    800051a6:	892a                	mv	s2,a0
    800051a8:	e0a43423          	sd	a0,-504(s0)
    800051ac:	e509                	bnez	a0,800051b6 <exec+0x236>
  if(pagetable)
    800051ae:	e1343423          	sd	s3,-504(s0)
    800051b2:	4a01                	li	s4,0
    800051b4:	aa1d                	j	800052ea <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051b6:	75f9                	lui	a1,0xffffe
    800051b8:	95aa                	add	a1,a1,a0
    800051ba:	855a                	mv	a0,s6
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	478080e7          	jalr	1144(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    800051c4:	7bfd                	lui	s7,0xfffff
    800051c6:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800051c8:	e0043783          	ld	a5,-512(s0)
    800051cc:	6388                	ld	a0,0(a5)
    800051ce:	c52d                	beqz	a0,80005238 <exec+0x2b8>
    800051d0:	e9040993          	addi	s3,s0,-368
    800051d4:	f9040c13          	addi	s8,s0,-112
    800051d8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	c6e080e7          	jalr	-914(ra) # 80000e48 <strlen>
    800051e2:	0015079b          	addiw	a5,a0,1
    800051e6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051ea:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051ee:	13796563          	bltu	s2,s7,80005318 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051f2:	e0043d03          	ld	s10,-512(s0)
    800051f6:	000d3a03          	ld	s4,0(s10)
    800051fa:	8552                	mv	a0,s4
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	c4c080e7          	jalr	-948(ra) # 80000e48 <strlen>
    80005204:	0015069b          	addiw	a3,a0,1
    80005208:	8652                	mv	a2,s4
    8000520a:	85ca                	mv	a1,s2
    8000520c:	855a                	mv	a0,s6
    8000520e:	ffffc097          	auipc	ra,0xffffc
    80005212:	458080e7          	jalr	1112(ra) # 80001666 <copyout>
    80005216:	10054363          	bltz	a0,8000531c <exec+0x39c>
    ustack[argc] = sp;
    8000521a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000521e:	0485                	addi	s1,s1,1
    80005220:	008d0793          	addi	a5,s10,8
    80005224:	e0f43023          	sd	a5,-512(s0)
    80005228:	008d3503          	ld	a0,8(s10)
    8000522c:	c909                	beqz	a0,8000523e <exec+0x2be>
    if(argc >= MAXARG)
    8000522e:	09a1                	addi	s3,s3,8
    80005230:	fb8995e3          	bne	s3,s8,800051da <exec+0x25a>
  ip = 0;
    80005234:	4a01                	li	s4,0
    80005236:	a855                	j	800052ea <exec+0x36a>
  sp = sz;
    80005238:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000523c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000523e:	00349793          	slli	a5,s1,0x3
    80005242:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdc7f0>
    80005246:	97a2                	add	a5,a5,s0
    80005248:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000524c:	00148693          	addi	a3,s1,1
    80005250:	068e                	slli	a3,a3,0x3
    80005252:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005256:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000525a:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000525e:	f57968e3          	bltu	s2,s7,800051ae <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005262:	e9040613          	addi	a2,s0,-368
    80005266:	85ca                	mv	a1,s2
    80005268:	855a                	mv	a0,s6
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	3fc080e7          	jalr	1020(ra) # 80001666 <copyout>
    80005272:	0a054763          	bltz	a0,80005320 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005276:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000527a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000527e:	df843783          	ld	a5,-520(s0)
    80005282:	0007c703          	lbu	a4,0(a5)
    80005286:	cf11                	beqz	a4,800052a2 <exec+0x322>
    80005288:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000528a:	02f00693          	li	a3,47
    8000528e:	a039                	j	8000529c <exec+0x31c>
      last = s+1;
    80005290:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005294:	0785                	addi	a5,a5,1
    80005296:	fff7c703          	lbu	a4,-1(a5)
    8000529a:	c701                	beqz	a4,800052a2 <exec+0x322>
    if(*s == '/')
    8000529c:	fed71ce3          	bne	a4,a3,80005294 <exec+0x314>
    800052a0:	bfc5                	j	80005290 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800052a2:	4641                	li	a2,16
    800052a4:	df843583          	ld	a1,-520(s0)
    800052a8:	158a8513          	addi	a0,s5,344
    800052ac:	ffffc097          	auipc	ra,0xffffc
    800052b0:	b6a080e7          	jalr	-1174(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800052b4:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800052b8:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800052bc:	e0843783          	ld	a5,-504(s0)
    800052c0:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052c4:	058ab783          	ld	a5,88(s5)
    800052c8:	e6843703          	ld	a4,-408(s0)
    800052cc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052ce:	058ab783          	ld	a5,88(s5)
    800052d2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052d6:	85e6                	mv	a1,s9
    800052d8:	ffffd097          	auipc	ra,0xffffd
    800052dc:	894080e7          	jalr	-1900(ra) # 80001b6c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052e0:	0004851b          	sext.w	a0,s1
    800052e4:	bb15                	j	80005018 <exec+0x98>
    800052e6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800052ea:	e0843583          	ld	a1,-504(s0)
    800052ee:	855a                	mv	a0,s6
    800052f0:	ffffd097          	auipc	ra,0xffffd
    800052f4:	87c080e7          	jalr	-1924(ra) # 80001b6c <proc_freepagetable>
  return -1;
    800052f8:	557d                	li	a0,-1
  if(ip){
    800052fa:	d00a0fe3          	beqz	s4,80005018 <exec+0x98>
    800052fe:	b319                	j	80005004 <exec+0x84>
    80005300:	e1243423          	sd	s2,-504(s0)
    80005304:	b7dd                	j	800052ea <exec+0x36a>
    80005306:	e1243423          	sd	s2,-504(s0)
    8000530a:	b7c5                	j	800052ea <exec+0x36a>
    8000530c:	e1243423          	sd	s2,-504(s0)
    80005310:	bfe9                	j	800052ea <exec+0x36a>
    80005312:	e1243423          	sd	s2,-504(s0)
    80005316:	bfd1                	j	800052ea <exec+0x36a>
  ip = 0;
    80005318:	4a01                	li	s4,0
    8000531a:	bfc1                	j	800052ea <exec+0x36a>
    8000531c:	4a01                	li	s4,0
  if(pagetable)
    8000531e:	b7f1                	j	800052ea <exec+0x36a>
  sz = sz1;
    80005320:	e0843983          	ld	s3,-504(s0)
    80005324:	b569                	j	800051ae <exec+0x22e>

0000000080005326 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005326:	7179                	addi	sp,sp,-48
    80005328:	f406                	sd	ra,40(sp)
    8000532a:	f022                	sd	s0,32(sp)
    8000532c:	ec26                	sd	s1,24(sp)
    8000532e:	e84a                	sd	s2,16(sp)
    80005330:	1800                	addi	s0,sp,48
    80005332:	892e                	mv	s2,a1
    80005334:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005336:	fdc40593          	addi	a1,s0,-36
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	acc080e7          	jalr	-1332(ra) # 80002e06 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005342:	fdc42703          	lw	a4,-36(s0)
    80005346:	47bd                	li	a5,15
    80005348:	02e7eb63          	bltu	a5,a4,8000537e <argfd+0x58>
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	65a080e7          	jalr	1626(ra) # 800019a6 <myproc>
    80005354:	fdc42703          	lw	a4,-36(s0)
    80005358:	01a70793          	addi	a5,a4,26
    8000535c:	078e                	slli	a5,a5,0x3
    8000535e:	953e                	add	a0,a0,a5
    80005360:	611c                	ld	a5,0(a0)
    80005362:	c385                	beqz	a5,80005382 <argfd+0x5c>
    return -1;
  if(pfd)
    80005364:	00090463          	beqz	s2,8000536c <argfd+0x46>
    *pfd = fd;
    80005368:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000536c:	4501                	li	a0,0
  if(pf)
    8000536e:	c091                	beqz	s1,80005372 <argfd+0x4c>
    *pf = f;
    80005370:	e09c                	sd	a5,0(s1)
}
    80005372:	70a2                	ld	ra,40(sp)
    80005374:	7402                	ld	s0,32(sp)
    80005376:	64e2                	ld	s1,24(sp)
    80005378:	6942                	ld	s2,16(sp)
    8000537a:	6145                	addi	sp,sp,48
    8000537c:	8082                	ret
    return -1;
    8000537e:	557d                	li	a0,-1
    80005380:	bfcd                	j	80005372 <argfd+0x4c>
    80005382:	557d                	li	a0,-1
    80005384:	b7fd                	j	80005372 <argfd+0x4c>

0000000080005386 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005386:	1101                	addi	sp,sp,-32
    80005388:	ec06                	sd	ra,24(sp)
    8000538a:	e822                	sd	s0,16(sp)
    8000538c:	e426                	sd	s1,8(sp)
    8000538e:	1000                	addi	s0,sp,32
    80005390:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005392:	ffffc097          	auipc	ra,0xffffc
    80005396:	614080e7          	jalr	1556(ra) # 800019a6 <myproc>
    8000539a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000539c:	0d050793          	addi	a5,a0,208
    800053a0:	4501                	li	a0,0
    800053a2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053a4:	6398                	ld	a4,0(a5)
    800053a6:	cb19                	beqz	a4,800053bc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053a8:	2505                	addiw	a0,a0,1
    800053aa:	07a1                	addi	a5,a5,8
    800053ac:	fed51ce3          	bne	a0,a3,800053a4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053b0:	557d                	li	a0,-1
}
    800053b2:	60e2                	ld	ra,24(sp)
    800053b4:	6442                	ld	s0,16(sp)
    800053b6:	64a2                	ld	s1,8(sp)
    800053b8:	6105                	addi	sp,sp,32
    800053ba:	8082                	ret
      p->ofile[fd] = f;
    800053bc:	01a50793          	addi	a5,a0,26
    800053c0:	078e                	slli	a5,a5,0x3
    800053c2:	963e                	add	a2,a2,a5
    800053c4:	e204                	sd	s1,0(a2)
      return fd;
    800053c6:	b7f5                	j	800053b2 <fdalloc+0x2c>

00000000800053c8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053c8:	715d                	addi	sp,sp,-80
    800053ca:	e486                	sd	ra,72(sp)
    800053cc:	e0a2                	sd	s0,64(sp)
    800053ce:	fc26                	sd	s1,56(sp)
    800053d0:	f84a                	sd	s2,48(sp)
    800053d2:	f44e                	sd	s3,40(sp)
    800053d4:	f052                	sd	s4,32(sp)
    800053d6:	ec56                	sd	s5,24(sp)
    800053d8:	e85a                	sd	s6,16(sp)
    800053da:	0880                	addi	s0,sp,80
    800053dc:	8b2e                	mv	s6,a1
    800053de:	89b2                	mv	s3,a2
    800053e0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053e2:	fb040593          	addi	a1,s0,-80
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	e7e080e7          	jalr	-386(ra) # 80004264 <nameiparent>
    800053ee:	84aa                	mv	s1,a0
    800053f0:	14050b63          	beqz	a0,80005546 <create+0x17e>
    return 0;

  ilock(dp);
    800053f4:	ffffe097          	auipc	ra,0xffffe
    800053f8:	6ac080e7          	jalr	1708(ra) # 80003aa0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053fc:	4601                	li	a2,0
    800053fe:	fb040593          	addi	a1,s0,-80
    80005402:	8526                	mv	a0,s1
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	b80080e7          	jalr	-1152(ra) # 80003f84 <dirlookup>
    8000540c:	8aaa                	mv	s5,a0
    8000540e:	c921                	beqz	a0,8000545e <create+0x96>
    iunlockput(dp);
    80005410:	8526                	mv	a0,s1
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	8f0080e7          	jalr	-1808(ra) # 80003d02 <iunlockput>
    ilock(ip);
    8000541a:	8556                	mv	a0,s5
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	684080e7          	jalr	1668(ra) # 80003aa0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005424:	4789                	li	a5,2
    80005426:	02fb1563          	bne	s6,a5,80005450 <create+0x88>
    8000542a:	044ad783          	lhu	a5,68(s5)
    8000542e:	37f9                	addiw	a5,a5,-2
    80005430:	17c2                	slli	a5,a5,0x30
    80005432:	93c1                	srli	a5,a5,0x30
    80005434:	4705                	li	a4,1
    80005436:	00f76d63          	bltu	a4,a5,80005450 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000543a:	8556                	mv	a0,s5
    8000543c:	60a6                	ld	ra,72(sp)
    8000543e:	6406                	ld	s0,64(sp)
    80005440:	74e2                	ld	s1,56(sp)
    80005442:	7942                	ld	s2,48(sp)
    80005444:	79a2                	ld	s3,40(sp)
    80005446:	7a02                	ld	s4,32(sp)
    80005448:	6ae2                	ld	s5,24(sp)
    8000544a:	6b42                	ld	s6,16(sp)
    8000544c:	6161                	addi	sp,sp,80
    8000544e:	8082                	ret
    iunlockput(ip);
    80005450:	8556                	mv	a0,s5
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	8b0080e7          	jalr	-1872(ra) # 80003d02 <iunlockput>
    return 0;
    8000545a:	4a81                	li	s5,0
    8000545c:	bff9                	j	8000543a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000545e:	85da                	mv	a1,s6
    80005460:	4088                	lw	a0,0(s1)
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	4a6080e7          	jalr	1190(ra) # 80003908 <ialloc>
    8000546a:	8a2a                	mv	s4,a0
    8000546c:	c529                	beqz	a0,800054b6 <create+0xee>
  ilock(ip);
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	632080e7          	jalr	1586(ra) # 80003aa0 <ilock>
  ip->major = major;
    80005476:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000547a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000547e:	4905                	li	s2,1
    80005480:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005484:	8552                	mv	a0,s4
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	54e080e7          	jalr	1358(ra) # 800039d4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000548e:	032b0b63          	beq	s6,s2,800054c4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005492:	004a2603          	lw	a2,4(s4)
    80005496:	fb040593          	addi	a1,s0,-80
    8000549a:	8526                	mv	a0,s1
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	cf8080e7          	jalr	-776(ra) # 80004194 <dirlink>
    800054a4:	06054f63          	bltz	a0,80005522 <create+0x15a>
  iunlockput(dp);
    800054a8:	8526                	mv	a0,s1
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	858080e7          	jalr	-1960(ra) # 80003d02 <iunlockput>
  return ip;
    800054b2:	8ad2                	mv	s5,s4
    800054b4:	b759                	j	8000543a <create+0x72>
    iunlockput(dp);
    800054b6:	8526                	mv	a0,s1
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	84a080e7          	jalr	-1974(ra) # 80003d02 <iunlockput>
    return 0;
    800054c0:	8ad2                	mv	s5,s4
    800054c2:	bfa5                	j	8000543a <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054c4:	004a2603          	lw	a2,4(s4)
    800054c8:	00003597          	auipc	a1,0x3
    800054cc:	26858593          	addi	a1,a1,616 # 80008730 <syscalls+0x2c0>
    800054d0:	8552                	mv	a0,s4
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	cc2080e7          	jalr	-830(ra) # 80004194 <dirlink>
    800054da:	04054463          	bltz	a0,80005522 <create+0x15a>
    800054de:	40d0                	lw	a2,4(s1)
    800054e0:	00003597          	auipc	a1,0x3
    800054e4:	25858593          	addi	a1,a1,600 # 80008738 <syscalls+0x2c8>
    800054e8:	8552                	mv	a0,s4
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	caa080e7          	jalr	-854(ra) # 80004194 <dirlink>
    800054f2:	02054863          	bltz	a0,80005522 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800054f6:	004a2603          	lw	a2,4(s4)
    800054fa:	fb040593          	addi	a1,s0,-80
    800054fe:	8526                	mv	a0,s1
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	c94080e7          	jalr	-876(ra) # 80004194 <dirlink>
    80005508:	00054d63          	bltz	a0,80005522 <create+0x15a>
    dp->nlink++;  // for ".."
    8000550c:	04a4d783          	lhu	a5,74(s1)
    80005510:	2785                	addiw	a5,a5,1
    80005512:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	4bc080e7          	jalr	1212(ra) # 800039d4 <iupdate>
    80005520:	b761                	j	800054a8 <create+0xe0>
  ip->nlink = 0;
    80005522:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005526:	8552                	mv	a0,s4
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	4ac080e7          	jalr	1196(ra) # 800039d4 <iupdate>
  iunlockput(ip);
    80005530:	8552                	mv	a0,s4
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	7d0080e7          	jalr	2000(ra) # 80003d02 <iunlockput>
  iunlockput(dp);
    8000553a:	8526                	mv	a0,s1
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	7c6080e7          	jalr	1990(ra) # 80003d02 <iunlockput>
  return 0;
    80005544:	bddd                	j	8000543a <create+0x72>
    return 0;
    80005546:	8aaa                	mv	s5,a0
    80005548:	bdcd                	j	8000543a <create+0x72>

000000008000554a <sys_dup>:
{
    8000554a:	7179                	addi	sp,sp,-48
    8000554c:	f406                	sd	ra,40(sp)
    8000554e:	f022                	sd	s0,32(sp)
    80005550:	ec26                	sd	s1,24(sp)
    80005552:	e84a                	sd	s2,16(sp)
    80005554:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005556:	fd840613          	addi	a2,s0,-40
    8000555a:	4581                	li	a1,0
    8000555c:	4501                	li	a0,0
    8000555e:	00000097          	auipc	ra,0x0
    80005562:	dc8080e7          	jalr	-568(ra) # 80005326 <argfd>
    return -1;
    80005566:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005568:	02054363          	bltz	a0,8000558e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000556c:	fd843903          	ld	s2,-40(s0)
    80005570:	854a                	mv	a0,s2
    80005572:	00000097          	auipc	ra,0x0
    80005576:	e14080e7          	jalr	-492(ra) # 80005386 <fdalloc>
    8000557a:	84aa                	mv	s1,a0
    return -1;
    8000557c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000557e:	00054863          	bltz	a0,8000558e <sys_dup+0x44>
  filedup(f);
    80005582:	854a                	mv	a0,s2
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	334080e7          	jalr	820(ra) # 800048b8 <filedup>
  return fd;
    8000558c:	87a6                	mv	a5,s1
}
    8000558e:	853e                	mv	a0,a5
    80005590:	70a2                	ld	ra,40(sp)
    80005592:	7402                	ld	s0,32(sp)
    80005594:	64e2                	ld	s1,24(sp)
    80005596:	6942                	ld	s2,16(sp)
    80005598:	6145                	addi	sp,sp,48
    8000559a:	8082                	ret

000000008000559c <sys_read>:
{
    8000559c:	7179                	addi	sp,sp,-48
    8000559e:	f406                	sd	ra,40(sp)
    800055a0:	f022                	sd	s0,32(sp)
    800055a2:	1800                	addi	s0,sp,48
  READCOUNT++;
    800055a4:	00003717          	auipc	a4,0x3
    800055a8:	38470713          	addi	a4,a4,900 # 80008928 <READCOUNT>
    800055ac:	631c                	ld	a5,0(a4)
    800055ae:	0785                	addi	a5,a5,1
    800055b0:	e31c                	sd	a5,0(a4)
  argaddr(1, &p);
    800055b2:	fd840593          	addi	a1,s0,-40
    800055b6:	4505                	li	a0,1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	86e080e7          	jalr	-1938(ra) # 80002e26 <argaddr>
  argint(2, &n);
    800055c0:	fe440593          	addi	a1,s0,-28
    800055c4:	4509                	li	a0,2
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	840080e7          	jalr	-1984(ra) # 80002e06 <argint>
  if(argfd(0, 0, &f) < 0)
    800055ce:	fe840613          	addi	a2,s0,-24
    800055d2:	4581                	li	a1,0
    800055d4:	4501                	li	a0,0
    800055d6:	00000097          	auipc	ra,0x0
    800055da:	d50080e7          	jalr	-688(ra) # 80005326 <argfd>
    800055de:	87aa                	mv	a5,a0
    return -1;
    800055e0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055e2:	0007cc63          	bltz	a5,800055fa <sys_read+0x5e>
  return fileread(f, p, n);
    800055e6:	fe442603          	lw	a2,-28(s0)
    800055ea:	fd843583          	ld	a1,-40(s0)
    800055ee:	fe843503          	ld	a0,-24(s0)
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	452080e7          	jalr	1106(ra) # 80004a44 <fileread>
}
    800055fa:	70a2                	ld	ra,40(sp)
    800055fc:	7402                	ld	s0,32(sp)
    800055fe:	6145                	addi	sp,sp,48
    80005600:	8082                	ret

0000000080005602 <sys_write>:
{
    80005602:	7179                	addi	sp,sp,-48
    80005604:	f406                	sd	ra,40(sp)
    80005606:	f022                	sd	s0,32(sp)
    80005608:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000560a:	fd840593          	addi	a1,s0,-40
    8000560e:	4505                	li	a0,1
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	816080e7          	jalr	-2026(ra) # 80002e26 <argaddr>
  argint(2, &n);
    80005618:	fe440593          	addi	a1,s0,-28
    8000561c:	4509                	li	a0,2
    8000561e:	ffffd097          	auipc	ra,0xffffd
    80005622:	7e8080e7          	jalr	2024(ra) # 80002e06 <argint>
  if(argfd(0, 0, &f) < 0)
    80005626:	fe840613          	addi	a2,s0,-24
    8000562a:	4581                	li	a1,0
    8000562c:	4501                	li	a0,0
    8000562e:	00000097          	auipc	ra,0x0
    80005632:	cf8080e7          	jalr	-776(ra) # 80005326 <argfd>
    80005636:	87aa                	mv	a5,a0
    return -1;
    80005638:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000563a:	0007cc63          	bltz	a5,80005652 <sys_write+0x50>
  return filewrite(f, p, n);
    8000563e:	fe442603          	lw	a2,-28(s0)
    80005642:	fd843583          	ld	a1,-40(s0)
    80005646:	fe843503          	ld	a0,-24(s0)
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	4bc080e7          	jalr	1212(ra) # 80004b06 <filewrite>
}
    80005652:	70a2                	ld	ra,40(sp)
    80005654:	7402                	ld	s0,32(sp)
    80005656:	6145                	addi	sp,sp,48
    80005658:	8082                	ret

000000008000565a <sys_close>:
{
    8000565a:	1101                	addi	sp,sp,-32
    8000565c:	ec06                	sd	ra,24(sp)
    8000565e:	e822                	sd	s0,16(sp)
    80005660:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005662:	fe040613          	addi	a2,s0,-32
    80005666:	fec40593          	addi	a1,s0,-20
    8000566a:	4501                	li	a0,0
    8000566c:	00000097          	auipc	ra,0x0
    80005670:	cba080e7          	jalr	-838(ra) # 80005326 <argfd>
    return -1;
    80005674:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005676:	02054463          	bltz	a0,8000569e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000567a:	ffffc097          	auipc	ra,0xffffc
    8000567e:	32c080e7          	jalr	812(ra) # 800019a6 <myproc>
    80005682:	fec42783          	lw	a5,-20(s0)
    80005686:	07e9                	addi	a5,a5,26
    80005688:	078e                	slli	a5,a5,0x3
    8000568a:	953e                	add	a0,a0,a5
    8000568c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005690:	fe043503          	ld	a0,-32(s0)
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	276080e7          	jalr	630(ra) # 8000490a <fileclose>
  return 0;
    8000569c:	4781                	li	a5,0
}
    8000569e:	853e                	mv	a0,a5
    800056a0:	60e2                	ld	ra,24(sp)
    800056a2:	6442                	ld	s0,16(sp)
    800056a4:	6105                	addi	sp,sp,32
    800056a6:	8082                	ret

00000000800056a8 <sys_fstat>:
{
    800056a8:	1101                	addi	sp,sp,-32
    800056aa:	ec06                	sd	ra,24(sp)
    800056ac:	e822                	sd	s0,16(sp)
    800056ae:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800056b0:	fe040593          	addi	a1,s0,-32
    800056b4:	4505                	li	a0,1
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	770080e7          	jalr	1904(ra) # 80002e26 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800056be:	fe840613          	addi	a2,s0,-24
    800056c2:	4581                	li	a1,0
    800056c4:	4501                	li	a0,0
    800056c6:	00000097          	auipc	ra,0x0
    800056ca:	c60080e7          	jalr	-928(ra) # 80005326 <argfd>
    800056ce:	87aa                	mv	a5,a0
    return -1;
    800056d0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056d2:	0007ca63          	bltz	a5,800056e6 <sys_fstat+0x3e>
  return filestat(f, st);
    800056d6:	fe043583          	ld	a1,-32(s0)
    800056da:	fe843503          	ld	a0,-24(s0)
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	2f4080e7          	jalr	756(ra) # 800049d2 <filestat>
}
    800056e6:	60e2                	ld	ra,24(sp)
    800056e8:	6442                	ld	s0,16(sp)
    800056ea:	6105                	addi	sp,sp,32
    800056ec:	8082                	ret

00000000800056ee <sys_link>:
{
    800056ee:	7169                	addi	sp,sp,-304
    800056f0:	f606                	sd	ra,296(sp)
    800056f2:	f222                	sd	s0,288(sp)
    800056f4:	ee26                	sd	s1,280(sp)
    800056f6:	ea4a                	sd	s2,272(sp)
    800056f8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056fa:	08000613          	li	a2,128
    800056fe:	ed040593          	addi	a1,s0,-304
    80005702:	4501                	li	a0,0
    80005704:	ffffd097          	auipc	ra,0xffffd
    80005708:	742080e7          	jalr	1858(ra) # 80002e46 <argstr>
    return -1;
    8000570c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000570e:	10054e63          	bltz	a0,8000582a <sys_link+0x13c>
    80005712:	08000613          	li	a2,128
    80005716:	f5040593          	addi	a1,s0,-176
    8000571a:	4505                	li	a0,1
    8000571c:	ffffd097          	auipc	ra,0xffffd
    80005720:	72a080e7          	jalr	1834(ra) # 80002e46 <argstr>
    return -1;
    80005724:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005726:	10054263          	bltz	a0,8000582a <sys_link+0x13c>
  begin_op();
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	d1c080e7          	jalr	-740(ra) # 80004446 <begin_op>
  if((ip = namei(old)) == 0){
    80005732:	ed040513          	addi	a0,s0,-304
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	b10080e7          	jalr	-1264(ra) # 80004246 <namei>
    8000573e:	84aa                	mv	s1,a0
    80005740:	c551                	beqz	a0,800057cc <sys_link+0xde>
  ilock(ip);
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	35e080e7          	jalr	862(ra) # 80003aa0 <ilock>
  if(ip->type == T_DIR){
    8000574a:	04449703          	lh	a4,68(s1)
    8000574e:	4785                	li	a5,1
    80005750:	08f70463          	beq	a4,a5,800057d8 <sys_link+0xea>
  ip->nlink++;
    80005754:	04a4d783          	lhu	a5,74(s1)
    80005758:	2785                	addiw	a5,a5,1
    8000575a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000575e:	8526                	mv	a0,s1
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	274080e7          	jalr	628(ra) # 800039d4 <iupdate>
  iunlock(ip);
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	3f8080e7          	jalr	1016(ra) # 80003b62 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005772:	fd040593          	addi	a1,s0,-48
    80005776:	f5040513          	addi	a0,s0,-176
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	aea080e7          	jalr	-1302(ra) # 80004264 <nameiparent>
    80005782:	892a                	mv	s2,a0
    80005784:	c935                	beqz	a0,800057f8 <sys_link+0x10a>
  ilock(dp);
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	31a080e7          	jalr	794(ra) # 80003aa0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000578e:	00092703          	lw	a4,0(s2)
    80005792:	409c                	lw	a5,0(s1)
    80005794:	04f71d63          	bne	a4,a5,800057ee <sys_link+0x100>
    80005798:	40d0                	lw	a2,4(s1)
    8000579a:	fd040593          	addi	a1,s0,-48
    8000579e:	854a                	mv	a0,s2
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	9f4080e7          	jalr	-1548(ra) # 80004194 <dirlink>
    800057a8:	04054363          	bltz	a0,800057ee <sys_link+0x100>
  iunlockput(dp);
    800057ac:	854a                	mv	a0,s2
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	554080e7          	jalr	1364(ra) # 80003d02 <iunlockput>
  iput(ip);
    800057b6:	8526                	mv	a0,s1
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	4a2080e7          	jalr	1186(ra) # 80003c5a <iput>
  end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	d00080e7          	jalr	-768(ra) # 800044c0 <end_op>
  return 0;
    800057c8:	4781                	li	a5,0
    800057ca:	a085                	j	8000582a <sys_link+0x13c>
    end_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	cf4080e7          	jalr	-780(ra) # 800044c0 <end_op>
    return -1;
    800057d4:	57fd                	li	a5,-1
    800057d6:	a891                	j	8000582a <sys_link+0x13c>
    iunlockput(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	528080e7          	jalr	1320(ra) # 80003d02 <iunlockput>
    end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	cde080e7          	jalr	-802(ra) # 800044c0 <end_op>
    return -1;
    800057ea:	57fd                	li	a5,-1
    800057ec:	a83d                	j	8000582a <sys_link+0x13c>
    iunlockput(dp);
    800057ee:	854a                	mv	a0,s2
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	512080e7          	jalr	1298(ra) # 80003d02 <iunlockput>
  ilock(ip);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	2a6080e7          	jalr	678(ra) # 80003aa0 <ilock>
  ip->nlink--;
    80005802:	04a4d783          	lhu	a5,74(s1)
    80005806:	37fd                	addiw	a5,a5,-1
    80005808:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000580c:	8526                	mv	a0,s1
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	1c6080e7          	jalr	454(ra) # 800039d4 <iupdate>
  iunlockput(ip);
    80005816:	8526                	mv	a0,s1
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	4ea080e7          	jalr	1258(ra) # 80003d02 <iunlockput>
  end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	ca0080e7          	jalr	-864(ra) # 800044c0 <end_op>
  return -1;
    80005828:	57fd                	li	a5,-1
}
    8000582a:	853e                	mv	a0,a5
    8000582c:	70b2                	ld	ra,296(sp)
    8000582e:	7412                	ld	s0,288(sp)
    80005830:	64f2                	ld	s1,280(sp)
    80005832:	6952                	ld	s2,272(sp)
    80005834:	6155                	addi	sp,sp,304
    80005836:	8082                	ret

0000000080005838 <sys_unlink>:
{
    80005838:	7151                	addi	sp,sp,-240
    8000583a:	f586                	sd	ra,232(sp)
    8000583c:	f1a2                	sd	s0,224(sp)
    8000583e:	eda6                	sd	s1,216(sp)
    80005840:	e9ca                	sd	s2,208(sp)
    80005842:	e5ce                	sd	s3,200(sp)
    80005844:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005846:	08000613          	li	a2,128
    8000584a:	f3040593          	addi	a1,s0,-208
    8000584e:	4501                	li	a0,0
    80005850:	ffffd097          	auipc	ra,0xffffd
    80005854:	5f6080e7          	jalr	1526(ra) # 80002e46 <argstr>
    80005858:	18054163          	bltz	a0,800059da <sys_unlink+0x1a2>
  begin_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	bea080e7          	jalr	-1046(ra) # 80004446 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005864:	fb040593          	addi	a1,s0,-80
    80005868:	f3040513          	addi	a0,s0,-208
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	9f8080e7          	jalr	-1544(ra) # 80004264 <nameiparent>
    80005874:	84aa                	mv	s1,a0
    80005876:	c979                	beqz	a0,8000594c <sys_unlink+0x114>
  ilock(dp);
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	228080e7          	jalr	552(ra) # 80003aa0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005880:	00003597          	auipc	a1,0x3
    80005884:	eb058593          	addi	a1,a1,-336 # 80008730 <syscalls+0x2c0>
    80005888:	fb040513          	addi	a0,s0,-80
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	6de080e7          	jalr	1758(ra) # 80003f6a <namecmp>
    80005894:	14050a63          	beqz	a0,800059e8 <sys_unlink+0x1b0>
    80005898:	00003597          	auipc	a1,0x3
    8000589c:	ea058593          	addi	a1,a1,-352 # 80008738 <syscalls+0x2c8>
    800058a0:	fb040513          	addi	a0,s0,-80
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	6c6080e7          	jalr	1734(ra) # 80003f6a <namecmp>
    800058ac:	12050e63          	beqz	a0,800059e8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058b0:	f2c40613          	addi	a2,s0,-212
    800058b4:	fb040593          	addi	a1,s0,-80
    800058b8:	8526                	mv	a0,s1
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	6ca080e7          	jalr	1738(ra) # 80003f84 <dirlookup>
    800058c2:	892a                	mv	s2,a0
    800058c4:	12050263          	beqz	a0,800059e8 <sys_unlink+0x1b0>
  ilock(ip);
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	1d8080e7          	jalr	472(ra) # 80003aa0 <ilock>
  if(ip->nlink < 1)
    800058d0:	04a91783          	lh	a5,74(s2)
    800058d4:	08f05263          	blez	a5,80005958 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058d8:	04491703          	lh	a4,68(s2)
    800058dc:	4785                	li	a5,1
    800058de:	08f70563          	beq	a4,a5,80005968 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058e2:	4641                	li	a2,16
    800058e4:	4581                	li	a1,0
    800058e6:	fc040513          	addi	a0,s0,-64
    800058ea:	ffffb097          	auipc	ra,0xffffb
    800058ee:	3e4080e7          	jalr	996(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058f2:	4741                	li	a4,16
    800058f4:	f2c42683          	lw	a3,-212(s0)
    800058f8:	fc040613          	addi	a2,s0,-64
    800058fc:	4581                	li	a1,0
    800058fe:	8526                	mv	a0,s1
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	54c080e7          	jalr	1356(ra) # 80003e4c <writei>
    80005908:	47c1                	li	a5,16
    8000590a:	0af51563          	bne	a0,a5,800059b4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000590e:	04491703          	lh	a4,68(s2)
    80005912:	4785                	li	a5,1
    80005914:	0af70863          	beq	a4,a5,800059c4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005918:	8526                	mv	a0,s1
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	3e8080e7          	jalr	1000(ra) # 80003d02 <iunlockput>
  ip->nlink--;
    80005922:	04a95783          	lhu	a5,74(s2)
    80005926:	37fd                	addiw	a5,a5,-1
    80005928:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000592c:	854a                	mv	a0,s2
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	0a6080e7          	jalr	166(ra) # 800039d4 <iupdate>
  iunlockput(ip);
    80005936:	854a                	mv	a0,s2
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	3ca080e7          	jalr	970(ra) # 80003d02 <iunlockput>
  end_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	b80080e7          	jalr	-1152(ra) # 800044c0 <end_op>
  return 0;
    80005948:	4501                	li	a0,0
    8000594a:	a84d                	j	800059fc <sys_unlink+0x1c4>
    end_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	b74080e7          	jalr	-1164(ra) # 800044c0 <end_op>
    return -1;
    80005954:	557d                	li	a0,-1
    80005956:	a05d                	j	800059fc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005958:	00003517          	auipc	a0,0x3
    8000595c:	de850513          	addi	a0,a0,-536 # 80008740 <syscalls+0x2d0>
    80005960:	ffffb097          	auipc	ra,0xffffb
    80005964:	bdc080e7          	jalr	-1060(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005968:	04c92703          	lw	a4,76(s2)
    8000596c:	02000793          	li	a5,32
    80005970:	f6e7f9e3          	bgeu	a5,a4,800058e2 <sys_unlink+0xaa>
    80005974:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005978:	4741                	li	a4,16
    8000597a:	86ce                	mv	a3,s3
    8000597c:	f1840613          	addi	a2,s0,-232
    80005980:	4581                	li	a1,0
    80005982:	854a                	mv	a0,s2
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	3d0080e7          	jalr	976(ra) # 80003d54 <readi>
    8000598c:	47c1                	li	a5,16
    8000598e:	00f51b63          	bne	a0,a5,800059a4 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005992:	f1845783          	lhu	a5,-232(s0)
    80005996:	e7a1                	bnez	a5,800059de <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005998:	29c1                	addiw	s3,s3,16
    8000599a:	04c92783          	lw	a5,76(s2)
    8000599e:	fcf9ede3          	bltu	s3,a5,80005978 <sys_unlink+0x140>
    800059a2:	b781                	j	800058e2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059a4:	00003517          	auipc	a0,0x3
    800059a8:	db450513          	addi	a0,a0,-588 # 80008758 <syscalls+0x2e8>
    800059ac:	ffffb097          	auipc	ra,0xffffb
    800059b0:	b90080e7          	jalr	-1136(ra) # 8000053c <panic>
    panic("unlink: writei");
    800059b4:	00003517          	auipc	a0,0x3
    800059b8:	dbc50513          	addi	a0,a0,-580 # 80008770 <syscalls+0x300>
    800059bc:	ffffb097          	auipc	ra,0xffffb
    800059c0:	b80080e7          	jalr	-1152(ra) # 8000053c <panic>
    dp->nlink--;
    800059c4:	04a4d783          	lhu	a5,74(s1)
    800059c8:	37fd                	addiw	a5,a5,-1
    800059ca:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059ce:	8526                	mv	a0,s1
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	004080e7          	jalr	4(ra) # 800039d4 <iupdate>
    800059d8:	b781                	j	80005918 <sys_unlink+0xe0>
    return -1;
    800059da:	557d                	li	a0,-1
    800059dc:	a005                	j	800059fc <sys_unlink+0x1c4>
    iunlockput(ip);
    800059de:	854a                	mv	a0,s2
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	322080e7          	jalr	802(ra) # 80003d02 <iunlockput>
  iunlockput(dp);
    800059e8:	8526                	mv	a0,s1
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	318080e7          	jalr	792(ra) # 80003d02 <iunlockput>
  end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	ace080e7          	jalr	-1330(ra) # 800044c0 <end_op>
  return -1;
    800059fa:	557d                	li	a0,-1
}
    800059fc:	70ae                	ld	ra,232(sp)
    800059fe:	740e                	ld	s0,224(sp)
    80005a00:	64ee                	ld	s1,216(sp)
    80005a02:	694e                	ld	s2,208(sp)
    80005a04:	69ae                	ld	s3,200(sp)
    80005a06:	616d                	addi	sp,sp,240
    80005a08:	8082                	ret

0000000080005a0a <sys_open>:

uint64
sys_open(void)
{
    80005a0a:	7131                	addi	sp,sp,-192
    80005a0c:	fd06                	sd	ra,184(sp)
    80005a0e:	f922                	sd	s0,176(sp)
    80005a10:	f526                	sd	s1,168(sp)
    80005a12:	f14a                	sd	s2,160(sp)
    80005a14:	ed4e                	sd	s3,152(sp)
    80005a16:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005a18:	f4c40593          	addi	a1,s0,-180
    80005a1c:	4505                	li	a0,1
    80005a1e:	ffffd097          	auipc	ra,0xffffd
    80005a22:	3e8080e7          	jalr	1000(ra) # 80002e06 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a26:	08000613          	li	a2,128
    80005a2a:	f5040593          	addi	a1,s0,-176
    80005a2e:	4501                	li	a0,0
    80005a30:	ffffd097          	auipc	ra,0xffffd
    80005a34:	416080e7          	jalr	1046(ra) # 80002e46 <argstr>
    80005a38:	87aa                	mv	a5,a0
    return -1;
    80005a3a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a3c:	0a07c863          	bltz	a5,80005aec <sys_open+0xe2>

  begin_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	a06080e7          	jalr	-1530(ra) # 80004446 <begin_op>

  if(omode & O_CREATE){
    80005a48:	f4c42783          	lw	a5,-180(s0)
    80005a4c:	2007f793          	andi	a5,a5,512
    80005a50:	cbdd                	beqz	a5,80005b06 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005a52:	4681                	li	a3,0
    80005a54:	4601                	li	a2,0
    80005a56:	4589                	li	a1,2
    80005a58:	f5040513          	addi	a0,s0,-176
    80005a5c:	00000097          	auipc	ra,0x0
    80005a60:	96c080e7          	jalr	-1684(ra) # 800053c8 <create>
    80005a64:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a66:	c951                	beqz	a0,80005afa <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a68:	04449703          	lh	a4,68(s1)
    80005a6c:	478d                	li	a5,3
    80005a6e:	00f71763          	bne	a4,a5,80005a7c <sys_open+0x72>
    80005a72:	0464d703          	lhu	a4,70(s1)
    80005a76:	47a5                	li	a5,9
    80005a78:	0ce7ec63          	bltu	a5,a4,80005b50 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	dd2080e7          	jalr	-558(ra) # 8000484e <filealloc>
    80005a84:	892a                	mv	s2,a0
    80005a86:	c56d                	beqz	a0,80005b70 <sys_open+0x166>
    80005a88:	00000097          	auipc	ra,0x0
    80005a8c:	8fe080e7          	jalr	-1794(ra) # 80005386 <fdalloc>
    80005a90:	89aa                	mv	s3,a0
    80005a92:	0c054a63          	bltz	a0,80005b66 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a96:	04449703          	lh	a4,68(s1)
    80005a9a:	478d                	li	a5,3
    80005a9c:	0ef70563          	beq	a4,a5,80005b86 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005aa0:	4789                	li	a5,2
    80005aa2:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005aa6:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005aaa:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005aae:	f4c42783          	lw	a5,-180(s0)
    80005ab2:	0017c713          	xori	a4,a5,1
    80005ab6:	8b05                	andi	a4,a4,1
    80005ab8:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005abc:	0037f713          	andi	a4,a5,3
    80005ac0:	00e03733          	snez	a4,a4
    80005ac4:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ac8:	4007f793          	andi	a5,a5,1024
    80005acc:	c791                	beqz	a5,80005ad8 <sys_open+0xce>
    80005ace:	04449703          	lh	a4,68(s1)
    80005ad2:	4789                	li	a5,2
    80005ad4:	0cf70063          	beq	a4,a5,80005b94 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005ad8:	8526                	mv	a0,s1
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	088080e7          	jalr	136(ra) # 80003b62 <iunlock>
  end_op();
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	9de080e7          	jalr	-1570(ra) # 800044c0 <end_op>

  return fd;
    80005aea:	854e                	mv	a0,s3
}
    80005aec:	70ea                	ld	ra,184(sp)
    80005aee:	744a                	ld	s0,176(sp)
    80005af0:	74aa                	ld	s1,168(sp)
    80005af2:	790a                	ld	s2,160(sp)
    80005af4:	69ea                	ld	s3,152(sp)
    80005af6:	6129                	addi	sp,sp,192
    80005af8:	8082                	ret
      end_op();
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	9c6080e7          	jalr	-1594(ra) # 800044c0 <end_op>
      return -1;
    80005b02:	557d                	li	a0,-1
    80005b04:	b7e5                	j	80005aec <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005b06:	f5040513          	addi	a0,s0,-176
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	73c080e7          	jalr	1852(ra) # 80004246 <namei>
    80005b12:	84aa                	mv	s1,a0
    80005b14:	c905                	beqz	a0,80005b44 <sys_open+0x13a>
    ilock(ip);
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	f8a080e7          	jalr	-118(ra) # 80003aa0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b1e:	04449703          	lh	a4,68(s1)
    80005b22:	4785                	li	a5,1
    80005b24:	f4f712e3          	bne	a4,a5,80005a68 <sys_open+0x5e>
    80005b28:	f4c42783          	lw	a5,-180(s0)
    80005b2c:	dba1                	beqz	a5,80005a7c <sys_open+0x72>
      iunlockput(ip);
    80005b2e:	8526                	mv	a0,s1
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	1d2080e7          	jalr	466(ra) # 80003d02 <iunlockput>
      end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	988080e7          	jalr	-1656(ra) # 800044c0 <end_op>
      return -1;
    80005b40:	557d                	li	a0,-1
    80005b42:	b76d                	j	80005aec <sys_open+0xe2>
      end_op();
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	97c080e7          	jalr	-1668(ra) # 800044c0 <end_op>
      return -1;
    80005b4c:	557d                	li	a0,-1
    80005b4e:	bf79                	j	80005aec <sys_open+0xe2>
    iunlockput(ip);
    80005b50:	8526                	mv	a0,s1
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	1b0080e7          	jalr	432(ra) # 80003d02 <iunlockput>
    end_op();
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	966080e7          	jalr	-1690(ra) # 800044c0 <end_op>
    return -1;
    80005b62:	557d                	li	a0,-1
    80005b64:	b761                	j	80005aec <sys_open+0xe2>
      fileclose(f);
    80005b66:	854a                	mv	a0,s2
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	da2080e7          	jalr	-606(ra) # 8000490a <fileclose>
    iunlockput(ip);
    80005b70:	8526                	mv	a0,s1
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	190080e7          	jalr	400(ra) # 80003d02 <iunlockput>
    end_op();
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	946080e7          	jalr	-1722(ra) # 800044c0 <end_op>
    return -1;
    80005b82:	557d                	li	a0,-1
    80005b84:	b7a5                	j	80005aec <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005b86:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005b8a:	04649783          	lh	a5,70(s1)
    80005b8e:	02f91223          	sh	a5,36(s2)
    80005b92:	bf21                	j	80005aaa <sys_open+0xa0>
    itrunc(ip);
    80005b94:	8526                	mv	a0,s1
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	018080e7          	jalr	24(ra) # 80003bae <itrunc>
    80005b9e:	bf2d                	j	80005ad8 <sys_open+0xce>

0000000080005ba0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ba0:	7175                	addi	sp,sp,-144
    80005ba2:	e506                	sd	ra,136(sp)
    80005ba4:	e122                	sd	s0,128(sp)
    80005ba6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	89e080e7          	jalr	-1890(ra) # 80004446 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bb0:	08000613          	li	a2,128
    80005bb4:	f7040593          	addi	a1,s0,-144
    80005bb8:	4501                	li	a0,0
    80005bba:	ffffd097          	auipc	ra,0xffffd
    80005bbe:	28c080e7          	jalr	652(ra) # 80002e46 <argstr>
    80005bc2:	02054963          	bltz	a0,80005bf4 <sys_mkdir+0x54>
    80005bc6:	4681                	li	a3,0
    80005bc8:	4601                	li	a2,0
    80005bca:	4585                	li	a1,1
    80005bcc:	f7040513          	addi	a0,s0,-144
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	7f8080e7          	jalr	2040(ra) # 800053c8 <create>
    80005bd8:	cd11                	beqz	a0,80005bf4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	128080e7          	jalr	296(ra) # 80003d02 <iunlockput>
  end_op();
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	8de080e7          	jalr	-1826(ra) # 800044c0 <end_op>
  return 0;
    80005bea:	4501                	li	a0,0
}
    80005bec:	60aa                	ld	ra,136(sp)
    80005bee:	640a                	ld	s0,128(sp)
    80005bf0:	6149                	addi	sp,sp,144
    80005bf2:	8082                	ret
    end_op();
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	8cc080e7          	jalr	-1844(ra) # 800044c0 <end_op>
    return -1;
    80005bfc:	557d                	li	a0,-1
    80005bfe:	b7fd                	j	80005bec <sys_mkdir+0x4c>

0000000080005c00 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c00:	7135                	addi	sp,sp,-160
    80005c02:	ed06                	sd	ra,152(sp)
    80005c04:	e922                	sd	s0,144(sp)
    80005c06:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	83e080e7          	jalr	-1986(ra) # 80004446 <begin_op>
  argint(1, &major);
    80005c10:	f6c40593          	addi	a1,s0,-148
    80005c14:	4505                	li	a0,1
    80005c16:	ffffd097          	auipc	ra,0xffffd
    80005c1a:	1f0080e7          	jalr	496(ra) # 80002e06 <argint>
  argint(2, &minor);
    80005c1e:	f6840593          	addi	a1,s0,-152
    80005c22:	4509                	li	a0,2
    80005c24:	ffffd097          	auipc	ra,0xffffd
    80005c28:	1e2080e7          	jalr	482(ra) # 80002e06 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c2c:	08000613          	li	a2,128
    80005c30:	f7040593          	addi	a1,s0,-144
    80005c34:	4501                	li	a0,0
    80005c36:	ffffd097          	auipc	ra,0xffffd
    80005c3a:	210080e7          	jalr	528(ra) # 80002e46 <argstr>
    80005c3e:	02054b63          	bltz	a0,80005c74 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c42:	f6841683          	lh	a3,-152(s0)
    80005c46:	f6c41603          	lh	a2,-148(s0)
    80005c4a:	458d                	li	a1,3
    80005c4c:	f7040513          	addi	a0,s0,-144
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	778080e7          	jalr	1912(ra) # 800053c8 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c58:	cd11                	beqz	a0,80005c74 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	0a8080e7          	jalr	168(ra) # 80003d02 <iunlockput>
  end_op();
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	85e080e7          	jalr	-1954(ra) # 800044c0 <end_op>
  return 0;
    80005c6a:	4501                	li	a0,0
}
    80005c6c:	60ea                	ld	ra,152(sp)
    80005c6e:	644a                	ld	s0,144(sp)
    80005c70:	610d                	addi	sp,sp,160
    80005c72:	8082                	ret
    end_op();
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	84c080e7          	jalr	-1972(ra) # 800044c0 <end_op>
    return -1;
    80005c7c:	557d                	li	a0,-1
    80005c7e:	b7fd                	j	80005c6c <sys_mknod+0x6c>

0000000080005c80 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c80:	7135                	addi	sp,sp,-160
    80005c82:	ed06                	sd	ra,152(sp)
    80005c84:	e922                	sd	s0,144(sp)
    80005c86:	e526                	sd	s1,136(sp)
    80005c88:	e14a                	sd	s2,128(sp)
    80005c8a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c8c:	ffffc097          	auipc	ra,0xffffc
    80005c90:	d1a080e7          	jalr	-742(ra) # 800019a6 <myproc>
    80005c94:	892a                	mv	s2,a0
  
  begin_op();
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	7b0080e7          	jalr	1968(ra) # 80004446 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c9e:	08000613          	li	a2,128
    80005ca2:	f6040593          	addi	a1,s0,-160
    80005ca6:	4501                	li	a0,0
    80005ca8:	ffffd097          	auipc	ra,0xffffd
    80005cac:	19e080e7          	jalr	414(ra) # 80002e46 <argstr>
    80005cb0:	04054b63          	bltz	a0,80005d06 <sys_chdir+0x86>
    80005cb4:	f6040513          	addi	a0,s0,-160
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	58e080e7          	jalr	1422(ra) # 80004246 <namei>
    80005cc0:	84aa                	mv	s1,a0
    80005cc2:	c131                	beqz	a0,80005d06 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	ddc080e7          	jalr	-548(ra) # 80003aa0 <ilock>
  if(ip->type != T_DIR){
    80005ccc:	04449703          	lh	a4,68(s1)
    80005cd0:	4785                	li	a5,1
    80005cd2:	04f71063          	bne	a4,a5,80005d12 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005cd6:	8526                	mv	a0,s1
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	e8a080e7          	jalr	-374(ra) # 80003b62 <iunlock>
  iput(p->cwd);
    80005ce0:	15093503          	ld	a0,336(s2)
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	f76080e7          	jalr	-138(ra) # 80003c5a <iput>
  end_op();
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	7d4080e7          	jalr	2004(ra) # 800044c0 <end_op>
  p->cwd = ip;
    80005cf4:	14993823          	sd	s1,336(s2)
  return 0;
    80005cf8:	4501                	li	a0,0
}
    80005cfa:	60ea                	ld	ra,152(sp)
    80005cfc:	644a                	ld	s0,144(sp)
    80005cfe:	64aa                	ld	s1,136(sp)
    80005d00:	690a                	ld	s2,128(sp)
    80005d02:	610d                	addi	sp,sp,160
    80005d04:	8082                	ret
    end_op();
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	7ba080e7          	jalr	1978(ra) # 800044c0 <end_op>
    return -1;
    80005d0e:	557d                	li	a0,-1
    80005d10:	b7ed                	j	80005cfa <sys_chdir+0x7a>
    iunlockput(ip);
    80005d12:	8526                	mv	a0,s1
    80005d14:	ffffe097          	auipc	ra,0xffffe
    80005d18:	fee080e7          	jalr	-18(ra) # 80003d02 <iunlockput>
    end_op();
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	7a4080e7          	jalr	1956(ra) # 800044c0 <end_op>
    return -1;
    80005d24:	557d                	li	a0,-1
    80005d26:	bfd1                	j	80005cfa <sys_chdir+0x7a>

0000000080005d28 <sys_exec>:

uint64
sys_exec(void)
{
    80005d28:	7121                	addi	sp,sp,-448
    80005d2a:	ff06                	sd	ra,440(sp)
    80005d2c:	fb22                	sd	s0,432(sp)
    80005d2e:	f726                	sd	s1,424(sp)
    80005d30:	f34a                	sd	s2,416(sp)
    80005d32:	ef4e                	sd	s3,408(sp)
    80005d34:	eb52                	sd	s4,400(sp)
    80005d36:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005d38:	e4840593          	addi	a1,s0,-440
    80005d3c:	4505                	li	a0,1
    80005d3e:	ffffd097          	auipc	ra,0xffffd
    80005d42:	0e8080e7          	jalr	232(ra) # 80002e26 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005d46:	08000613          	li	a2,128
    80005d4a:	f5040593          	addi	a1,s0,-176
    80005d4e:	4501                	li	a0,0
    80005d50:	ffffd097          	auipc	ra,0xffffd
    80005d54:	0f6080e7          	jalr	246(ra) # 80002e46 <argstr>
    80005d58:	87aa                	mv	a5,a0
    return -1;
    80005d5a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d5c:	0c07c263          	bltz	a5,80005e20 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005d60:	10000613          	li	a2,256
    80005d64:	4581                	li	a1,0
    80005d66:	e5040513          	addi	a0,s0,-432
    80005d6a:	ffffb097          	auipc	ra,0xffffb
    80005d6e:	f64080e7          	jalr	-156(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d72:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005d76:	89a6                	mv	s3,s1
    80005d78:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d7a:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d7e:	00391513          	slli	a0,s2,0x3
    80005d82:	e4040593          	addi	a1,s0,-448
    80005d86:	e4843783          	ld	a5,-440(s0)
    80005d8a:	953e                	add	a0,a0,a5
    80005d8c:	ffffd097          	auipc	ra,0xffffd
    80005d90:	fdc080e7          	jalr	-36(ra) # 80002d68 <fetchaddr>
    80005d94:	02054a63          	bltz	a0,80005dc8 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005d98:	e4043783          	ld	a5,-448(s0)
    80005d9c:	c3b9                	beqz	a5,80005de2 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d9e:	ffffb097          	auipc	ra,0xffffb
    80005da2:	d44080e7          	jalr	-700(ra) # 80000ae2 <kalloc>
    80005da6:	85aa                	mv	a1,a0
    80005da8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005dac:	cd11                	beqz	a0,80005dc8 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005dae:	6605                	lui	a2,0x1
    80005db0:	e4043503          	ld	a0,-448(s0)
    80005db4:	ffffd097          	auipc	ra,0xffffd
    80005db8:	006080e7          	jalr	6(ra) # 80002dba <fetchstr>
    80005dbc:	00054663          	bltz	a0,80005dc8 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005dc0:	0905                	addi	s2,s2,1
    80005dc2:	09a1                	addi	s3,s3,8
    80005dc4:	fb491de3          	bne	s2,s4,80005d7e <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dc8:	f5040913          	addi	s2,s0,-176
    80005dcc:	6088                	ld	a0,0(s1)
    80005dce:	c921                	beqz	a0,80005e1e <sys_exec+0xf6>
    kfree(argv[i]);
    80005dd0:	ffffb097          	auipc	ra,0xffffb
    80005dd4:	c14080e7          	jalr	-1004(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dd8:	04a1                	addi	s1,s1,8
    80005dda:	ff2499e3          	bne	s1,s2,80005dcc <sys_exec+0xa4>
  return -1;
    80005dde:	557d                	li	a0,-1
    80005de0:	a081                	j	80005e20 <sys_exec+0xf8>
      argv[i] = 0;
    80005de2:	0009079b          	sext.w	a5,s2
    80005de6:	078e                	slli	a5,a5,0x3
    80005de8:	fd078793          	addi	a5,a5,-48
    80005dec:	97a2                	add	a5,a5,s0
    80005dee:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005df2:	e5040593          	addi	a1,s0,-432
    80005df6:	f5040513          	addi	a0,s0,-176
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	186080e7          	jalr	390(ra) # 80004f80 <exec>
    80005e02:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e04:	f5040993          	addi	s3,s0,-176
    80005e08:	6088                	ld	a0,0(s1)
    80005e0a:	c901                	beqz	a0,80005e1a <sys_exec+0xf2>
    kfree(argv[i]);
    80005e0c:	ffffb097          	auipc	ra,0xffffb
    80005e10:	bd8080e7          	jalr	-1064(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e14:	04a1                	addi	s1,s1,8
    80005e16:	ff3499e3          	bne	s1,s3,80005e08 <sys_exec+0xe0>
  return ret;
    80005e1a:	854a                	mv	a0,s2
    80005e1c:	a011                	j	80005e20 <sys_exec+0xf8>
  return -1;
    80005e1e:	557d                	li	a0,-1
}
    80005e20:	70fa                	ld	ra,440(sp)
    80005e22:	745a                	ld	s0,432(sp)
    80005e24:	74ba                	ld	s1,424(sp)
    80005e26:	791a                	ld	s2,416(sp)
    80005e28:	69fa                	ld	s3,408(sp)
    80005e2a:	6a5a                	ld	s4,400(sp)
    80005e2c:	6139                	addi	sp,sp,448
    80005e2e:	8082                	ret

0000000080005e30 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e30:	7139                	addi	sp,sp,-64
    80005e32:	fc06                	sd	ra,56(sp)
    80005e34:	f822                	sd	s0,48(sp)
    80005e36:	f426                	sd	s1,40(sp)
    80005e38:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e3a:	ffffc097          	auipc	ra,0xffffc
    80005e3e:	b6c080e7          	jalr	-1172(ra) # 800019a6 <myproc>
    80005e42:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005e44:	fd840593          	addi	a1,s0,-40
    80005e48:	4501                	li	a0,0
    80005e4a:	ffffd097          	auipc	ra,0xffffd
    80005e4e:	fdc080e7          	jalr	-36(ra) # 80002e26 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005e52:	fc840593          	addi	a1,s0,-56
    80005e56:	fd040513          	addi	a0,s0,-48
    80005e5a:	fffff097          	auipc	ra,0xfffff
    80005e5e:	ddc080e7          	jalr	-548(ra) # 80004c36 <pipealloc>
    return -1;
    80005e62:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e64:	0c054463          	bltz	a0,80005f2c <sys_pipe+0xfc>
  fd0 = -1;
    80005e68:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e6c:	fd043503          	ld	a0,-48(s0)
    80005e70:	fffff097          	auipc	ra,0xfffff
    80005e74:	516080e7          	jalr	1302(ra) # 80005386 <fdalloc>
    80005e78:	fca42223          	sw	a0,-60(s0)
    80005e7c:	08054b63          	bltz	a0,80005f12 <sys_pipe+0xe2>
    80005e80:	fc843503          	ld	a0,-56(s0)
    80005e84:	fffff097          	auipc	ra,0xfffff
    80005e88:	502080e7          	jalr	1282(ra) # 80005386 <fdalloc>
    80005e8c:	fca42023          	sw	a0,-64(s0)
    80005e90:	06054863          	bltz	a0,80005f00 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e94:	4691                	li	a3,4
    80005e96:	fc440613          	addi	a2,s0,-60
    80005e9a:	fd843583          	ld	a1,-40(s0)
    80005e9e:	68a8                	ld	a0,80(s1)
    80005ea0:	ffffb097          	auipc	ra,0xffffb
    80005ea4:	7c6080e7          	jalr	1990(ra) # 80001666 <copyout>
    80005ea8:	02054063          	bltz	a0,80005ec8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005eac:	4691                	li	a3,4
    80005eae:	fc040613          	addi	a2,s0,-64
    80005eb2:	fd843583          	ld	a1,-40(s0)
    80005eb6:	0591                	addi	a1,a1,4
    80005eb8:	68a8                	ld	a0,80(s1)
    80005eba:	ffffb097          	auipc	ra,0xffffb
    80005ebe:	7ac080e7          	jalr	1964(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ec2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ec4:	06055463          	bgez	a0,80005f2c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ec8:	fc442783          	lw	a5,-60(s0)
    80005ecc:	07e9                	addi	a5,a5,26
    80005ece:	078e                	slli	a5,a5,0x3
    80005ed0:	97a6                	add	a5,a5,s1
    80005ed2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ed6:	fc042783          	lw	a5,-64(s0)
    80005eda:	07e9                	addi	a5,a5,26
    80005edc:	078e                	slli	a5,a5,0x3
    80005ede:	94be                	add	s1,s1,a5
    80005ee0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ee4:	fd043503          	ld	a0,-48(s0)
    80005ee8:	fffff097          	auipc	ra,0xfffff
    80005eec:	a22080e7          	jalr	-1502(ra) # 8000490a <fileclose>
    fileclose(wf);
    80005ef0:	fc843503          	ld	a0,-56(s0)
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	a16080e7          	jalr	-1514(ra) # 8000490a <fileclose>
    return -1;
    80005efc:	57fd                	li	a5,-1
    80005efe:	a03d                	j	80005f2c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005f00:	fc442783          	lw	a5,-60(s0)
    80005f04:	0007c763          	bltz	a5,80005f12 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005f08:	07e9                	addi	a5,a5,26
    80005f0a:	078e                	slli	a5,a5,0x3
    80005f0c:	97a6                	add	a5,a5,s1
    80005f0e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005f12:	fd043503          	ld	a0,-48(s0)
    80005f16:	fffff097          	auipc	ra,0xfffff
    80005f1a:	9f4080e7          	jalr	-1548(ra) # 8000490a <fileclose>
    fileclose(wf);
    80005f1e:	fc843503          	ld	a0,-56(s0)
    80005f22:	fffff097          	auipc	ra,0xfffff
    80005f26:	9e8080e7          	jalr	-1560(ra) # 8000490a <fileclose>
    return -1;
    80005f2a:	57fd                	li	a5,-1
}
    80005f2c:	853e                	mv	a0,a5
    80005f2e:	70e2                	ld	ra,56(sp)
    80005f30:	7442                	ld	s0,48(sp)
    80005f32:	74a2                	ld	s1,40(sp)
    80005f34:	6121                	addi	sp,sp,64
    80005f36:	8082                	ret
	...

0000000080005f40 <kernelvec>:
    80005f40:	7111                	addi	sp,sp,-256
    80005f42:	e006                	sd	ra,0(sp)
    80005f44:	e40a                	sd	sp,8(sp)
    80005f46:	e80e                	sd	gp,16(sp)
    80005f48:	ec12                	sd	tp,24(sp)
    80005f4a:	f016                	sd	t0,32(sp)
    80005f4c:	f41a                	sd	t1,40(sp)
    80005f4e:	f81e                	sd	t2,48(sp)
    80005f50:	fc22                	sd	s0,56(sp)
    80005f52:	e0a6                	sd	s1,64(sp)
    80005f54:	e4aa                	sd	a0,72(sp)
    80005f56:	e8ae                	sd	a1,80(sp)
    80005f58:	ecb2                	sd	a2,88(sp)
    80005f5a:	f0b6                	sd	a3,96(sp)
    80005f5c:	f4ba                	sd	a4,104(sp)
    80005f5e:	f8be                	sd	a5,112(sp)
    80005f60:	fcc2                	sd	a6,120(sp)
    80005f62:	e146                	sd	a7,128(sp)
    80005f64:	e54a                	sd	s2,136(sp)
    80005f66:	e94e                	sd	s3,144(sp)
    80005f68:	ed52                	sd	s4,152(sp)
    80005f6a:	f156                	sd	s5,160(sp)
    80005f6c:	f55a                	sd	s6,168(sp)
    80005f6e:	f95e                	sd	s7,176(sp)
    80005f70:	fd62                	sd	s8,184(sp)
    80005f72:	e1e6                	sd	s9,192(sp)
    80005f74:	e5ea                	sd	s10,200(sp)
    80005f76:	e9ee                	sd	s11,208(sp)
    80005f78:	edf2                	sd	t3,216(sp)
    80005f7a:	f1f6                	sd	t4,224(sp)
    80005f7c:	f5fa                	sd	t5,232(sp)
    80005f7e:	f9fe                	sd	t6,240(sp)
    80005f80:	ccbfc0ef          	jal	ra,80002c4a <kerneltrap>
    80005f84:	6082                	ld	ra,0(sp)
    80005f86:	6122                	ld	sp,8(sp)
    80005f88:	61c2                	ld	gp,16(sp)
    80005f8a:	7282                	ld	t0,32(sp)
    80005f8c:	7322                	ld	t1,40(sp)
    80005f8e:	73c2                	ld	t2,48(sp)
    80005f90:	7462                	ld	s0,56(sp)
    80005f92:	6486                	ld	s1,64(sp)
    80005f94:	6526                	ld	a0,72(sp)
    80005f96:	65c6                	ld	a1,80(sp)
    80005f98:	6666                	ld	a2,88(sp)
    80005f9a:	7686                	ld	a3,96(sp)
    80005f9c:	7726                	ld	a4,104(sp)
    80005f9e:	77c6                	ld	a5,112(sp)
    80005fa0:	7866                	ld	a6,120(sp)
    80005fa2:	688a                	ld	a7,128(sp)
    80005fa4:	692a                	ld	s2,136(sp)
    80005fa6:	69ca                	ld	s3,144(sp)
    80005fa8:	6a6a                	ld	s4,152(sp)
    80005faa:	7a8a                	ld	s5,160(sp)
    80005fac:	7b2a                	ld	s6,168(sp)
    80005fae:	7bca                	ld	s7,176(sp)
    80005fb0:	7c6a                	ld	s8,184(sp)
    80005fb2:	6c8e                	ld	s9,192(sp)
    80005fb4:	6d2e                	ld	s10,200(sp)
    80005fb6:	6dce                	ld	s11,208(sp)
    80005fb8:	6e6e                	ld	t3,216(sp)
    80005fba:	7e8e                	ld	t4,224(sp)
    80005fbc:	7f2e                	ld	t5,232(sp)
    80005fbe:	7fce                	ld	t6,240(sp)
    80005fc0:	6111                	addi	sp,sp,256
    80005fc2:	10200073          	sret
    80005fc6:	00000013          	nop
    80005fca:	00000013          	nop
    80005fce:	0001                	nop

0000000080005fd0 <timervec>:
    80005fd0:	34051573          	csrrw	a0,mscratch,a0
    80005fd4:	e10c                	sd	a1,0(a0)
    80005fd6:	e510                	sd	a2,8(a0)
    80005fd8:	e914                	sd	a3,16(a0)
    80005fda:	6d0c                	ld	a1,24(a0)
    80005fdc:	7110                	ld	a2,32(a0)
    80005fde:	6194                	ld	a3,0(a1)
    80005fe0:	96b2                	add	a3,a3,a2
    80005fe2:	e194                	sd	a3,0(a1)
    80005fe4:	4589                	li	a1,2
    80005fe6:	14459073          	csrw	sip,a1
    80005fea:	6914                	ld	a3,16(a0)
    80005fec:	6510                	ld	a2,8(a0)
    80005fee:	610c                	ld	a1,0(a0)
    80005ff0:	34051573          	csrrw	a0,mscratch,a0
    80005ff4:	30200073          	mret
	...

0000000080005ffa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005ffa:	1141                	addi	sp,sp,-16
    80005ffc:	e422                	sd	s0,8(sp)
    80005ffe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006000:	0c0007b7          	lui	a5,0xc000
    80006004:	4705                	li	a4,1
    80006006:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006008:	c3d8                	sw	a4,4(a5)
}
    8000600a:	6422                	ld	s0,8(sp)
    8000600c:	0141                	addi	sp,sp,16
    8000600e:	8082                	ret

0000000080006010 <plicinithart>:

void
plicinithart(void)
{
    80006010:	1141                	addi	sp,sp,-16
    80006012:	e406                	sd	ra,8(sp)
    80006014:	e022                	sd	s0,0(sp)
    80006016:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	962080e7          	jalr	-1694(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006020:	0085171b          	slliw	a4,a0,0x8
    80006024:	0c0027b7          	lui	a5,0xc002
    80006028:	97ba                	add	a5,a5,a4
    8000602a:	40200713          	li	a4,1026
    8000602e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006032:	00d5151b          	slliw	a0,a0,0xd
    80006036:	0c2017b7          	lui	a5,0xc201
    8000603a:	97aa                	add	a5,a5,a0
    8000603c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006040:	60a2                	ld	ra,8(sp)
    80006042:	6402                	ld	s0,0(sp)
    80006044:	0141                	addi	sp,sp,16
    80006046:	8082                	ret

0000000080006048 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006048:	1141                	addi	sp,sp,-16
    8000604a:	e406                	sd	ra,8(sp)
    8000604c:	e022                	sd	s0,0(sp)
    8000604e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006050:	ffffc097          	auipc	ra,0xffffc
    80006054:	92a080e7          	jalr	-1750(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006058:	00d5151b          	slliw	a0,a0,0xd
    8000605c:	0c2017b7          	lui	a5,0xc201
    80006060:	97aa                	add	a5,a5,a0
  return irq;
}
    80006062:	43c8                	lw	a0,4(a5)
    80006064:	60a2                	ld	ra,8(sp)
    80006066:	6402                	ld	s0,0(sp)
    80006068:	0141                	addi	sp,sp,16
    8000606a:	8082                	ret

000000008000606c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000606c:	1101                	addi	sp,sp,-32
    8000606e:	ec06                	sd	ra,24(sp)
    80006070:	e822                	sd	s0,16(sp)
    80006072:	e426                	sd	s1,8(sp)
    80006074:	1000                	addi	s0,sp,32
    80006076:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	902080e7          	jalr	-1790(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006080:	00d5151b          	slliw	a0,a0,0xd
    80006084:	0c2017b7          	lui	a5,0xc201
    80006088:	97aa                	add	a5,a5,a0
    8000608a:	c3c4                	sw	s1,4(a5)
}
    8000608c:	60e2                	ld	ra,24(sp)
    8000608e:	6442                	ld	s0,16(sp)
    80006090:	64a2                	ld	s1,8(sp)
    80006092:	6105                	addi	sp,sp,32
    80006094:	8082                	ret

0000000080006096 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006096:	1141                	addi	sp,sp,-16
    80006098:	e406                	sd	ra,8(sp)
    8000609a:	e022                	sd	s0,0(sp)
    8000609c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000609e:	479d                	li	a5,7
    800060a0:	04a7cc63          	blt	a5,a0,800060f8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800060a4:	0001c797          	auipc	a5,0x1c
    800060a8:	5bc78793          	addi	a5,a5,1468 # 80022660 <disk>
    800060ac:	97aa                	add	a5,a5,a0
    800060ae:	0187c783          	lbu	a5,24(a5)
    800060b2:	ebb9                	bnez	a5,80006108 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800060b4:	00451693          	slli	a3,a0,0x4
    800060b8:	0001c797          	auipc	a5,0x1c
    800060bc:	5a878793          	addi	a5,a5,1448 # 80022660 <disk>
    800060c0:	6398                	ld	a4,0(a5)
    800060c2:	9736                	add	a4,a4,a3
    800060c4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800060c8:	6398                	ld	a4,0(a5)
    800060ca:	9736                	add	a4,a4,a3
    800060cc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800060d0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800060d4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800060d8:	97aa                	add	a5,a5,a0
    800060da:	4705                	li	a4,1
    800060dc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800060e0:	0001c517          	auipc	a0,0x1c
    800060e4:	59850513          	addi	a0,a0,1432 # 80022678 <disk+0x18>
    800060e8:	ffffc097          	auipc	ra,0xffffc
    800060ec:	0d2080e7          	jalr	210(ra) # 800021ba <wakeup>
}
    800060f0:	60a2                	ld	ra,8(sp)
    800060f2:	6402                	ld	s0,0(sp)
    800060f4:	0141                	addi	sp,sp,16
    800060f6:	8082                	ret
    panic("free_desc 1");
    800060f8:	00002517          	auipc	a0,0x2
    800060fc:	68850513          	addi	a0,a0,1672 # 80008780 <syscalls+0x310>
    80006100:	ffffa097          	auipc	ra,0xffffa
    80006104:	43c080e7          	jalr	1084(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006108:	00002517          	auipc	a0,0x2
    8000610c:	68850513          	addi	a0,a0,1672 # 80008790 <syscalls+0x320>
    80006110:	ffffa097          	auipc	ra,0xffffa
    80006114:	42c080e7          	jalr	1068(ra) # 8000053c <panic>

0000000080006118 <virtio_disk_init>:
{
    80006118:	1101                	addi	sp,sp,-32
    8000611a:	ec06                	sd	ra,24(sp)
    8000611c:	e822                	sd	s0,16(sp)
    8000611e:	e426                	sd	s1,8(sp)
    80006120:	e04a                	sd	s2,0(sp)
    80006122:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006124:	00002597          	auipc	a1,0x2
    80006128:	67c58593          	addi	a1,a1,1660 # 800087a0 <syscalls+0x330>
    8000612c:	0001c517          	auipc	a0,0x1c
    80006130:	65c50513          	addi	a0,a0,1628 # 80022788 <disk+0x128>
    80006134:	ffffb097          	auipc	ra,0xffffb
    80006138:	a0e080e7          	jalr	-1522(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000613c:	100017b7          	lui	a5,0x10001
    80006140:	4398                	lw	a4,0(a5)
    80006142:	2701                	sext.w	a4,a4
    80006144:	747277b7          	lui	a5,0x74727
    80006148:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000614c:	14f71b63          	bne	a4,a5,800062a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006150:	100017b7          	lui	a5,0x10001
    80006154:	43dc                	lw	a5,4(a5)
    80006156:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006158:	4709                	li	a4,2
    8000615a:	14e79463          	bne	a5,a4,800062a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000615e:	100017b7          	lui	a5,0x10001
    80006162:	479c                	lw	a5,8(a5)
    80006164:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006166:	12e79e63          	bne	a5,a4,800062a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000616a:	100017b7          	lui	a5,0x10001
    8000616e:	47d8                	lw	a4,12(a5)
    80006170:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006172:	554d47b7          	lui	a5,0x554d4
    80006176:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000617a:	12f71463          	bne	a4,a5,800062a2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000617e:	100017b7          	lui	a5,0x10001
    80006182:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006186:	4705                	li	a4,1
    80006188:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000618a:	470d                	li	a4,3
    8000618c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000618e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006190:	c7ffe6b7          	lui	a3,0xc7ffe
    80006194:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbfbf>
    80006198:	8f75                	and	a4,a4,a3
    8000619a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000619c:	472d                	li	a4,11
    8000619e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800061a0:	5bbc                	lw	a5,112(a5)
    800061a2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800061a6:	8ba1                	andi	a5,a5,8
    800061a8:	10078563          	beqz	a5,800062b2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800061ac:	100017b7          	lui	a5,0x10001
    800061b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800061b4:	43fc                	lw	a5,68(a5)
    800061b6:	2781                	sext.w	a5,a5
    800061b8:	10079563          	bnez	a5,800062c2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800061bc:	100017b7          	lui	a5,0x10001
    800061c0:	5bdc                	lw	a5,52(a5)
    800061c2:	2781                	sext.w	a5,a5
  if(max == 0)
    800061c4:	10078763          	beqz	a5,800062d2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800061c8:	471d                	li	a4,7
    800061ca:	10f77c63          	bgeu	a4,a5,800062e2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800061ce:	ffffb097          	auipc	ra,0xffffb
    800061d2:	914080e7          	jalr	-1772(ra) # 80000ae2 <kalloc>
    800061d6:	0001c497          	auipc	s1,0x1c
    800061da:	48a48493          	addi	s1,s1,1162 # 80022660 <disk>
    800061de:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800061e0:	ffffb097          	auipc	ra,0xffffb
    800061e4:	902080e7          	jalr	-1790(ra) # 80000ae2 <kalloc>
    800061e8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800061ea:	ffffb097          	auipc	ra,0xffffb
    800061ee:	8f8080e7          	jalr	-1800(ra) # 80000ae2 <kalloc>
    800061f2:	87aa                	mv	a5,a0
    800061f4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800061f6:	6088                	ld	a0,0(s1)
    800061f8:	cd6d                	beqz	a0,800062f2 <virtio_disk_init+0x1da>
    800061fa:	0001c717          	auipc	a4,0x1c
    800061fe:	46e73703          	ld	a4,1134(a4) # 80022668 <disk+0x8>
    80006202:	cb65                	beqz	a4,800062f2 <virtio_disk_init+0x1da>
    80006204:	c7fd                	beqz	a5,800062f2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006206:	6605                	lui	a2,0x1
    80006208:	4581                	li	a1,0
    8000620a:	ffffb097          	auipc	ra,0xffffb
    8000620e:	ac4080e7          	jalr	-1340(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006212:	0001c497          	auipc	s1,0x1c
    80006216:	44e48493          	addi	s1,s1,1102 # 80022660 <disk>
    8000621a:	6605                	lui	a2,0x1
    8000621c:	4581                	li	a1,0
    8000621e:	6488                	ld	a0,8(s1)
    80006220:	ffffb097          	auipc	ra,0xffffb
    80006224:	aae080e7          	jalr	-1362(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006228:	6605                	lui	a2,0x1
    8000622a:	4581                	li	a1,0
    8000622c:	6888                	ld	a0,16(s1)
    8000622e:	ffffb097          	auipc	ra,0xffffb
    80006232:	aa0080e7          	jalr	-1376(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006236:	100017b7          	lui	a5,0x10001
    8000623a:	4721                	li	a4,8
    8000623c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000623e:	4098                	lw	a4,0(s1)
    80006240:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006244:	40d8                	lw	a4,4(s1)
    80006246:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000624a:	6498                	ld	a4,8(s1)
    8000624c:	0007069b          	sext.w	a3,a4
    80006250:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006254:	9701                	srai	a4,a4,0x20
    80006256:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000625a:	6898                	ld	a4,16(s1)
    8000625c:	0007069b          	sext.w	a3,a4
    80006260:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006264:	9701                	srai	a4,a4,0x20
    80006266:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000626a:	4705                	li	a4,1
    8000626c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000626e:	00e48c23          	sb	a4,24(s1)
    80006272:	00e48ca3          	sb	a4,25(s1)
    80006276:	00e48d23          	sb	a4,26(s1)
    8000627a:	00e48da3          	sb	a4,27(s1)
    8000627e:	00e48e23          	sb	a4,28(s1)
    80006282:	00e48ea3          	sb	a4,29(s1)
    80006286:	00e48f23          	sb	a4,30(s1)
    8000628a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000628e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006292:	0727a823          	sw	s2,112(a5)
}
    80006296:	60e2                	ld	ra,24(sp)
    80006298:	6442                	ld	s0,16(sp)
    8000629a:	64a2                	ld	s1,8(sp)
    8000629c:	6902                	ld	s2,0(sp)
    8000629e:	6105                	addi	sp,sp,32
    800062a0:	8082                	ret
    panic("could not find virtio disk");
    800062a2:	00002517          	auipc	a0,0x2
    800062a6:	50e50513          	addi	a0,a0,1294 # 800087b0 <syscalls+0x340>
    800062aa:	ffffa097          	auipc	ra,0xffffa
    800062ae:	292080e7          	jalr	658(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800062b2:	00002517          	auipc	a0,0x2
    800062b6:	51e50513          	addi	a0,a0,1310 # 800087d0 <syscalls+0x360>
    800062ba:	ffffa097          	auipc	ra,0xffffa
    800062be:	282080e7          	jalr	642(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	52e50513          	addi	a0,a0,1326 # 800087f0 <syscalls+0x380>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	272080e7          	jalr	626(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800062d2:	00002517          	auipc	a0,0x2
    800062d6:	53e50513          	addi	a0,a0,1342 # 80008810 <syscalls+0x3a0>
    800062da:	ffffa097          	auipc	ra,0xffffa
    800062de:	262080e7          	jalr	610(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800062e2:	00002517          	auipc	a0,0x2
    800062e6:	54e50513          	addi	a0,a0,1358 # 80008830 <syscalls+0x3c0>
    800062ea:	ffffa097          	auipc	ra,0xffffa
    800062ee:	252080e7          	jalr	594(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800062f2:	00002517          	auipc	a0,0x2
    800062f6:	55e50513          	addi	a0,a0,1374 # 80008850 <syscalls+0x3e0>
    800062fa:	ffffa097          	auipc	ra,0xffffa
    800062fe:	242080e7          	jalr	578(ra) # 8000053c <panic>

0000000080006302 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006302:	7159                	addi	sp,sp,-112
    80006304:	f486                	sd	ra,104(sp)
    80006306:	f0a2                	sd	s0,96(sp)
    80006308:	eca6                	sd	s1,88(sp)
    8000630a:	e8ca                	sd	s2,80(sp)
    8000630c:	e4ce                	sd	s3,72(sp)
    8000630e:	e0d2                	sd	s4,64(sp)
    80006310:	fc56                	sd	s5,56(sp)
    80006312:	f85a                	sd	s6,48(sp)
    80006314:	f45e                	sd	s7,40(sp)
    80006316:	f062                	sd	s8,32(sp)
    80006318:	ec66                	sd	s9,24(sp)
    8000631a:	e86a                	sd	s10,16(sp)
    8000631c:	1880                	addi	s0,sp,112
    8000631e:	8a2a                	mv	s4,a0
    80006320:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006322:	00c52c83          	lw	s9,12(a0)
    80006326:	001c9c9b          	slliw	s9,s9,0x1
    8000632a:	1c82                	slli	s9,s9,0x20
    8000632c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006330:	0001c517          	auipc	a0,0x1c
    80006334:	45850513          	addi	a0,a0,1112 # 80022788 <disk+0x128>
    80006338:	ffffb097          	auipc	ra,0xffffb
    8000633c:	89a080e7          	jalr	-1894(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006340:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006342:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006344:	0001cb17          	auipc	s6,0x1c
    80006348:	31cb0b13          	addi	s6,s6,796 # 80022660 <disk>
  for(int i = 0; i < 3; i++){
    8000634c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000634e:	0001cc17          	auipc	s8,0x1c
    80006352:	43ac0c13          	addi	s8,s8,1082 # 80022788 <disk+0x128>
    80006356:	a095                	j	800063ba <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006358:	00fb0733          	add	a4,s6,a5
    8000635c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006360:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006362:	0207c563          	bltz	a5,8000638c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006366:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006368:	0591                	addi	a1,a1,4
    8000636a:	05560d63          	beq	a2,s5,800063c4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000636e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006370:	0001c717          	auipc	a4,0x1c
    80006374:	2f070713          	addi	a4,a4,752 # 80022660 <disk>
    80006378:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000637a:	01874683          	lbu	a3,24(a4)
    8000637e:	fee9                	bnez	a3,80006358 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006380:	2785                	addiw	a5,a5,1
    80006382:	0705                	addi	a4,a4,1
    80006384:	fe979be3          	bne	a5,s1,8000637a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006388:	57fd                	li	a5,-1
    8000638a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000638c:	00c05e63          	blez	a2,800063a8 <virtio_disk_rw+0xa6>
    80006390:	060a                	slli	a2,a2,0x2
    80006392:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006396:	0009a503          	lw	a0,0(s3)
    8000639a:	00000097          	auipc	ra,0x0
    8000639e:	cfc080e7          	jalr	-772(ra) # 80006096 <free_desc>
      for(int j = 0; j < i; j++)
    800063a2:	0991                	addi	s3,s3,4
    800063a4:	ffa999e3          	bne	s3,s10,80006396 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063a8:	85e2                	mv	a1,s8
    800063aa:	0001c517          	auipc	a0,0x1c
    800063ae:	2ce50513          	addi	a0,a0,718 # 80022678 <disk+0x18>
    800063b2:	ffffc097          	auipc	ra,0xffffc
    800063b6:	da4080e7          	jalr	-604(ra) # 80002156 <sleep>
  for(int i = 0; i < 3; i++){
    800063ba:	f9040993          	addi	s3,s0,-112
{
    800063be:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800063c0:	864a                	mv	a2,s2
    800063c2:	b775                	j	8000636e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063c4:	f9042503          	lw	a0,-112(s0)
    800063c8:	00a50713          	addi	a4,a0,10
    800063cc:	0712                	slli	a4,a4,0x4

  if(write)
    800063ce:	0001c797          	auipc	a5,0x1c
    800063d2:	29278793          	addi	a5,a5,658 # 80022660 <disk>
    800063d6:	00e786b3          	add	a3,a5,a4
    800063da:	01703633          	snez	a2,s7
    800063de:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063e0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800063e4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063e8:	f6070613          	addi	a2,a4,-160
    800063ec:	6394                	ld	a3,0(a5)
    800063ee:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063f0:	00870593          	addi	a1,a4,8
    800063f4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063f6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063f8:	0007b803          	ld	a6,0(a5)
    800063fc:	9642                	add	a2,a2,a6
    800063fe:	46c1                	li	a3,16
    80006400:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006402:	4585                	li	a1,1
    80006404:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006408:	f9442683          	lw	a3,-108(s0)
    8000640c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006410:	0692                	slli	a3,a3,0x4
    80006412:	9836                	add	a6,a6,a3
    80006414:	058a0613          	addi	a2,s4,88
    80006418:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000641c:	0007b803          	ld	a6,0(a5)
    80006420:	96c2                	add	a3,a3,a6
    80006422:	40000613          	li	a2,1024
    80006426:	c690                	sw	a2,8(a3)
  if(write)
    80006428:	001bb613          	seqz	a2,s7
    8000642c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006430:	00166613          	ori	a2,a2,1
    80006434:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006438:	f9842603          	lw	a2,-104(s0)
    8000643c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006440:	00250693          	addi	a3,a0,2
    80006444:	0692                	slli	a3,a3,0x4
    80006446:	96be                	add	a3,a3,a5
    80006448:	58fd                	li	a7,-1
    8000644a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000644e:	0612                	slli	a2,a2,0x4
    80006450:	9832                	add	a6,a6,a2
    80006452:	f9070713          	addi	a4,a4,-112
    80006456:	973e                	add	a4,a4,a5
    80006458:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000645c:	6398                	ld	a4,0(a5)
    8000645e:	9732                	add	a4,a4,a2
    80006460:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006462:	4609                	li	a2,2
    80006464:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006468:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000646c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006470:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006474:	6794                	ld	a3,8(a5)
    80006476:	0026d703          	lhu	a4,2(a3)
    8000647a:	8b1d                	andi	a4,a4,7
    8000647c:	0706                	slli	a4,a4,0x1
    8000647e:	96ba                	add	a3,a3,a4
    80006480:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006484:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006488:	6798                	ld	a4,8(a5)
    8000648a:	00275783          	lhu	a5,2(a4)
    8000648e:	2785                	addiw	a5,a5,1
    80006490:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006494:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006498:	100017b7          	lui	a5,0x10001
    8000649c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064a0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800064a4:	0001c917          	auipc	s2,0x1c
    800064a8:	2e490913          	addi	s2,s2,740 # 80022788 <disk+0x128>
  while(b->disk == 1) {
    800064ac:	4485                	li	s1,1
    800064ae:	00b79c63          	bne	a5,a1,800064c6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800064b2:	85ca                	mv	a1,s2
    800064b4:	8552                	mv	a0,s4
    800064b6:	ffffc097          	auipc	ra,0xffffc
    800064ba:	ca0080e7          	jalr	-864(ra) # 80002156 <sleep>
  while(b->disk == 1) {
    800064be:	004a2783          	lw	a5,4(s4)
    800064c2:	fe9788e3          	beq	a5,s1,800064b2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800064c6:	f9042903          	lw	s2,-112(s0)
    800064ca:	00290713          	addi	a4,s2,2
    800064ce:	0712                	slli	a4,a4,0x4
    800064d0:	0001c797          	auipc	a5,0x1c
    800064d4:	19078793          	addi	a5,a5,400 # 80022660 <disk>
    800064d8:	97ba                	add	a5,a5,a4
    800064da:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800064de:	0001c997          	auipc	s3,0x1c
    800064e2:	18298993          	addi	s3,s3,386 # 80022660 <disk>
    800064e6:	00491713          	slli	a4,s2,0x4
    800064ea:	0009b783          	ld	a5,0(s3)
    800064ee:	97ba                	add	a5,a5,a4
    800064f0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064f4:	854a                	mv	a0,s2
    800064f6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064fa:	00000097          	auipc	ra,0x0
    800064fe:	b9c080e7          	jalr	-1124(ra) # 80006096 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006502:	8885                	andi	s1,s1,1
    80006504:	f0ed                	bnez	s1,800064e6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006506:	0001c517          	auipc	a0,0x1c
    8000650a:	28250513          	addi	a0,a0,642 # 80022788 <disk+0x128>
    8000650e:	ffffa097          	auipc	ra,0xffffa
    80006512:	778080e7          	jalr	1912(ra) # 80000c86 <release>
}
    80006516:	70a6                	ld	ra,104(sp)
    80006518:	7406                	ld	s0,96(sp)
    8000651a:	64e6                	ld	s1,88(sp)
    8000651c:	6946                	ld	s2,80(sp)
    8000651e:	69a6                	ld	s3,72(sp)
    80006520:	6a06                	ld	s4,64(sp)
    80006522:	7ae2                	ld	s5,56(sp)
    80006524:	7b42                	ld	s6,48(sp)
    80006526:	7ba2                	ld	s7,40(sp)
    80006528:	7c02                	ld	s8,32(sp)
    8000652a:	6ce2                	ld	s9,24(sp)
    8000652c:	6d42                	ld	s10,16(sp)
    8000652e:	6165                	addi	sp,sp,112
    80006530:	8082                	ret

0000000080006532 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006532:	1101                	addi	sp,sp,-32
    80006534:	ec06                	sd	ra,24(sp)
    80006536:	e822                	sd	s0,16(sp)
    80006538:	e426                	sd	s1,8(sp)
    8000653a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000653c:	0001c497          	auipc	s1,0x1c
    80006540:	12448493          	addi	s1,s1,292 # 80022660 <disk>
    80006544:	0001c517          	auipc	a0,0x1c
    80006548:	24450513          	addi	a0,a0,580 # 80022788 <disk+0x128>
    8000654c:	ffffa097          	auipc	ra,0xffffa
    80006550:	686080e7          	jalr	1670(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006554:	10001737          	lui	a4,0x10001
    80006558:	533c                	lw	a5,96(a4)
    8000655a:	8b8d                	andi	a5,a5,3
    8000655c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000655e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006562:	689c                	ld	a5,16(s1)
    80006564:	0204d703          	lhu	a4,32(s1)
    80006568:	0027d783          	lhu	a5,2(a5)
    8000656c:	04f70863          	beq	a4,a5,800065bc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006570:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006574:	6898                	ld	a4,16(s1)
    80006576:	0204d783          	lhu	a5,32(s1)
    8000657a:	8b9d                	andi	a5,a5,7
    8000657c:	078e                	slli	a5,a5,0x3
    8000657e:	97ba                	add	a5,a5,a4
    80006580:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006582:	00278713          	addi	a4,a5,2
    80006586:	0712                	slli	a4,a4,0x4
    80006588:	9726                	add	a4,a4,s1
    8000658a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000658e:	e721                	bnez	a4,800065d6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006590:	0789                	addi	a5,a5,2
    80006592:	0792                	slli	a5,a5,0x4
    80006594:	97a6                	add	a5,a5,s1
    80006596:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006598:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000659c:	ffffc097          	auipc	ra,0xffffc
    800065a0:	c1e080e7          	jalr	-994(ra) # 800021ba <wakeup>

    disk.used_idx += 1;
    800065a4:	0204d783          	lhu	a5,32(s1)
    800065a8:	2785                	addiw	a5,a5,1
    800065aa:	17c2                	slli	a5,a5,0x30
    800065ac:	93c1                	srli	a5,a5,0x30
    800065ae:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800065b2:	6898                	ld	a4,16(s1)
    800065b4:	00275703          	lhu	a4,2(a4)
    800065b8:	faf71ce3          	bne	a4,a5,80006570 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800065bc:	0001c517          	auipc	a0,0x1c
    800065c0:	1cc50513          	addi	a0,a0,460 # 80022788 <disk+0x128>
    800065c4:	ffffa097          	auipc	ra,0xffffa
    800065c8:	6c2080e7          	jalr	1730(ra) # 80000c86 <release>
}
    800065cc:	60e2                	ld	ra,24(sp)
    800065ce:	6442                	ld	s0,16(sp)
    800065d0:	64a2                	ld	s1,8(sp)
    800065d2:	6105                	addi	sp,sp,32
    800065d4:	8082                	ret
      panic("virtio_disk_intr status");
    800065d6:	00002517          	auipc	a0,0x2
    800065da:	29250513          	addi	a0,a0,658 # 80008868 <syscalls+0x3f8>
    800065de:	ffffa097          	auipc	ra,0xffffa
    800065e2:	f5e080e7          	jalr	-162(ra) # 8000053c <panic>
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
