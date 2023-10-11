
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	84013103          	ld	sp,-1984(sp) # 80008840 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	85070713          	addi	a4,a4,-1968 # 800088a0 <timer_scratch>
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
    80000066:	09e78793          	addi	a5,a5,158 # 80006100 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda84f>
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
    8000012e:	586080e7          	jalr	1414(ra) # 800026b0 <either_copyin>
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
    80000188:	85c50513          	addi	a0,a0,-1956 # 800109e0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	84c48493          	addi	s1,s1,-1972 # 800109e0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	8dc90913          	addi	s2,s2,-1828 # 80010a78 <cons+0x98>
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
    800001c0:	33e080e7          	jalr	830(ra) # 800024fa <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	07c080e7          	jalr	124(ra) # 80002246 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	80270713          	addi	a4,a4,-2046 # 800109e0 <cons>
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
    80000214:	44a080e7          	jalr	1098(ra) # 8000265a <either_copyout>
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
    80000228:	00010517          	auipc	a0,0x10
    8000022c:	7b850513          	addi	a0,a0,1976 # 800109e0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00010517          	auipc	a0,0x10
    80000242:	7a250513          	addi	a0,a0,1954 # 800109e0 <cons>
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
    80000272:	80f72523          	sw	a5,-2038(a4) # 80010a78 <cons+0x98>
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
    800002cc:	71850513          	addi	a0,a0,1816 # 800109e0 <cons>
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
    800002f2:	418080e7          	jalr	1048(ra) # 80002706 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	6ea50513          	addi	a0,a0,1770 # 800109e0 <cons>
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
    8000031e:	6c670713          	addi	a4,a4,1734 # 800109e0 <cons>
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
    80000348:	69c78793          	addi	a5,a5,1692 # 800109e0 <cons>
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
    80000376:	7067a783          	lw	a5,1798(a5) # 80010a78 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	65a70713          	addi	a4,a4,1626 # 800109e0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	64a48493          	addi	s1,s1,1610 # 800109e0 <cons>
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
    800003d6:	60e70713          	addi	a4,a4,1550 # 800109e0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	68f72c23          	sw	a5,1688(a4) # 80010a80 <cons+0xa0>
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
    80000412:	5d278793          	addi	a5,a5,1490 # 800109e0 <cons>
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
    80000436:	64c7a523          	sw	a2,1610(a5) # 80010a7c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	63e50513          	addi	a0,a0,1598 # 80010a78 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	e68080e7          	jalr	-408(ra) # 800022aa <wakeup>
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
    80000460:	58450513          	addi	a0,a0,1412 # 800109e0 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00023797          	auipc	a5,0x23
    80000478:	9a478793          	addi	a5,a5,-1628 # 80022e18 <devsw>
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
    8000054c:	5407ac23          	sw	zero,1368(a5) # 80010aa0 <pr+0x18>
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
    80000580:	2ef72223          	sw	a5,740(a4) # 80008860 <panicked>
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
    800005bc:	4e8dad83          	lw	s11,1256(s11) # 80010aa0 <pr+0x18>
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
    800005fa:	49250513          	addi	a0,a0,1170 # 80010a88 <pr>
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
    80000758:	33450513          	addi	a0,a0,820 # 80010a88 <pr>
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
    80000774:	31848493          	addi	s1,s1,792 # 80010a88 <pr>
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
    800007d4:	2d850513          	addi	a0,a0,728 # 80010aa8 <uart_tx_lock>
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
    80000800:	0647a783          	lw	a5,100(a5) # 80008860 <panicked>
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
    80000838:	0347b783          	ld	a5,52(a5) # 80008868 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	03473703          	ld	a4,52(a4) # 80008870 <uart_tx_w>
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
    80000862:	24aa0a13          	addi	s4,s4,586 # 80010aa8 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	00248493          	addi	s1,s1,2 # 80008868 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	00298993          	addi	s3,s3,2 # 80008870 <uart_tx_w>
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
    80000894:	a1a080e7          	jalr	-1510(ra) # 800022aa <wakeup>
    
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
    800008d0:	1dc50513          	addi	a0,a0,476 # 80010aa8 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	f847a783          	lw	a5,-124(a5) # 80008860 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	f8a73703          	ld	a4,-118(a4) # 80008870 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	f7a7b783          	ld	a5,-134(a5) # 80008868 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	1ae98993          	addi	s3,s3,430 # 80010aa8 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	f6648493          	addi	s1,s1,-154 # 80008868 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	f6690913          	addi	s2,s2,-154 # 80008870 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	92c080e7          	jalr	-1748(ra) # 80002246 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	17848493          	addi	s1,s1,376 # 80010aa8 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f2e7b623          	sd	a4,-212(a5) # 80008870 <uart_tx_w>
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
    800009ba:	0f248493          	addi	s1,s1,242 # 80010aa8 <uart_tx_lock>
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
    800009f8:	00023797          	auipc	a5,0x23
    800009fc:	5b878793          	addi	a5,a5,1464 # 80023fb0 <end>
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
    80000a1c:	0c890913          	addi	s2,s2,200 # 80010ae0 <kmem>
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
    80000aba:	02a50513          	addi	a0,a0,42 # 80010ae0 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00023517          	auipc	a0,0x23
    80000ace:	4e650513          	addi	a0,a0,1254 # 80023fb0 <end>
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
    80000af0:	ff448493          	addi	s1,s1,-12 # 80010ae0 <kmem>
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
    80000b08:	fdc50513          	addi	a0,a0,-36 # 80010ae0 <kmem>
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
    80000b34:	fb050513          	addi	a0,a0,-80 # 80010ae0 <kmem>
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
    80000d42:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdb051>
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
    80000e86:	9f670713          	addi	a4,a4,-1546 # 80008878 <started>
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
    80000ebc:	bb6080e7          	jalr	-1098(ra) # 80002a6e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	280080e7          	jalr	640(ra) # 80006140 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	16e080e7          	jalr	366(ra) # 80002036 <scheduler>
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
    80000f34:	b16080e7          	jalr	-1258(ra) # 80002a46 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	b36080e7          	jalr	-1226(ra) # 80002a6e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	1ea080e7          	jalr	490(ra) # 8000612a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	1f8080e7          	jalr	504(ra) # 80006140 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	3e4080e7          	jalr	996(ra) # 80003334 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	a82080e7          	jalr	-1406(ra) # 800039da <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	9f8080e7          	jalr	-1544(ra) # 80004958 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	2e0080e7          	jalr	736(ra) # 80006248 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	ea8080e7          	jalr	-344(ra) # 80001e18 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	8ef72d23          	sw	a5,-1798(a4) # 80008878 <started>
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
    80000f96:	8ee7b783          	ld	a5,-1810(a5) # 80008880 <kernel_pagetable>
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
    80001010:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdb047>
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
    80001252:	62a7b923          	sd	a0,1586(a5) # 80008880 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdb050>
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
    80001846:	00010497          	auipc	s1,0x10
    8000184a:	38a48493          	addi	s1,s1,906 # 80011bd0 <proc>
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
    80001860:	00017a17          	auipc	s4,0x17
    80001864:	370a0a13          	addi	s4,s4,880 # 80018bd0 <tickslock>
		char* pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	27a080e7          	jalr	634(ra) # 80000ae2 <kalloc>
    80001870:	862a                	mv	a2,a0
		if(pa == 0)
    80001872:	c131                	beqz	a0,800018b6 <proc_mapstacks+0x86>
		uint64 va = KSTACK((int)(p - proc));
    80001874:	416485b3          	sub	a1,s1,s6
    80001878:	8599                	srai	a1,a1,0x6
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
    8000189a:	1c048493          	addi	s1,s1,448
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
		
		queues[i].queue_size = 0 ; 
		queues[i].arr[0] = 0 ;
	}
	#endif
	initlock(&pid_lock, "nextpid");
    800018da:	00007597          	auipc	a1,0x7
    800018de:	90658593          	addi	a1,a1,-1786 # 800081e0 <digits+0x1a0>
    800018e2:	0000f517          	auipc	a0,0xf
    800018e6:	21e50513          	addi	a0,a0,542 # 80010b00 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
	initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	addi	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	21e50513          	addi	a0,a0,542 # 80010b18 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
	for(p = proc; p < &proc[NPROC]; p++)
    8000190a:	00010497          	auipc	s1,0x10
    8000190e:	2c648493          	addi	s1,s1,710 # 80011bd0 <proc>
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
    8000192c:	00017997          	auipc	s3,0x17
    80001930:	2a498993          	addi	s3,s3,676 # 80018bd0 <tickslock>
		initlock(&p->lock, "proc");
    80001934:	85da                	mv	a1,s6
    80001936:	8526                	mv	a0,s1
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20a080e7          	jalr	522(ra) # 80000b42 <initlock>
		p->state = UNUSED;
    80001940:	0004ac23          	sw	zero,24(s1)
		p->kstack = KSTACK((int)(p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	8799                	srai	a5,a5,0x6
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addiw	a5,a5,1
    80001954:	00d7979b          	slliw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
	for(p = proc; p < &proc[NPROC]; p++)
    8000195e:	1c048493          	addi	s1,s1,448
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
    8000199a:	19a50513          	addi	a0,a0,410 # 80010b30 <cpus>
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
    800019c2:	14270713          	addi	a4,a4,322 # 80010b00 <pid_lock>
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
    800019fa:	dfa7a783          	lw	a5,-518(a5) # 800087f0 <first.0>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
		// be run from main().
		first = 0;
		fsinit(ROOTDEV);
	}

	usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	086080e7          	jalr	134(ra) # 80002a86 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	addi	sp,sp,16
    80001a0e:	8082                	ret
		first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	de07a023          	sw	zero,-544(a5) # 800087f0 <first.0>
		fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	f40080e7          	jalr	-192(ra) # 8000395a <fsinit>
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
    80001a34:	0d090913          	addi	s2,s2,208 # 80010b00 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
	pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	db278793          	addi	a5,a5,-590 # 800087f4 <nextpid>
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

0000000080001a6a <queue_remove>:
{
    80001a6a:	1141                	addi	sp,sp,-16
    80001a6c:	e422                	sd	s0,8(sp)
    80001a6e:	0800                	addi	s0,sp,16
	for(i = proc_idx; i < queues[queue_no].queue_size - 1; i++)
    80001a70:	32800713          	li	a4,808
    80001a74:	02e58733          	mul	a4,a1,a4
    80001a78:	0000f797          	auipc	a5,0xf
    80001a7c:	4b878793          	addi	a5,a5,1208 # 80010f30 <queues>
    80001a80:	97ba                	add	a5,a5,a4
    80001a82:	3207a683          	lw	a3,800(a5)
    80001a86:	fff6861b          	addiw	a2,a3,-1 # fff <_entry-0x7ffff001>
    80001a8a:	0006079b          	sext.w	a5,a2
    80001a8e:	02f55463          	bge	a0,a5,80001ab6 <queue_remove+0x4c>
    80001a92:	06500793          	li	a5,101
    80001a96:	02f587b3          	mul	a5,a1,a5
    80001a9a:	97aa                	add	a5,a5,a0
    80001a9c:	078e                	slli	a5,a5,0x3
    80001a9e:	0000f717          	auipc	a4,0xf
    80001aa2:	49270713          	addi	a4,a4,1170 # 80010f30 <queues>
    80001aa6:	97ba                	add	a5,a5,a4
    80001aa8:	36fd                	addiw	a3,a3,-1
		queues[queue_no].arr[i] = queues[queue_no].arr[i + 1];
    80001aaa:	2505                	addiw	a0,a0,1
    80001aac:	6798                	ld	a4,8(a5)
    80001aae:	e398                	sd	a4,0(a5)
	for(i = proc_idx; i < queues[queue_no].queue_size - 1; i++)
    80001ab0:	07a1                	addi	a5,a5,8
    80001ab2:	fed51ce3          	bne	a0,a3,80001aaa <queue_remove+0x40>
	queues[queue_no].queue_size--;
    80001ab6:	32800793          	li	a5,808
    80001aba:	02f585b3          	mul	a1,a1,a5
    80001abe:	0000f797          	auipc	a5,0xf
    80001ac2:	47278793          	addi	a5,a5,1138 # 80010f30 <queues>
    80001ac6:	97ae                	add	a5,a5,a1
    80001ac8:	32c7a023          	sw	a2,800(a5)
}
    80001acc:	6422                	ld	s0,8(sp)
    80001ace:	0141                	addi	sp,sp,16
    80001ad0:	8082                	ret

0000000080001ad2 <queue_add>:
{
    80001ad2:	1141                	addi	sp,sp,-16
    80001ad4:	e422                	sd	s0,8(sp)
    80001ad6:	0800                	addi	s0,sp,16
	int new_process_idx = queues[queue_no].queue_size;
    80001ad8:	0000f617          	auipc	a2,0xf
    80001adc:	45860613          	addi	a2,a2,1112 # 80010f30 <queues>
    80001ae0:	32800713          	li	a4,808
    80001ae4:	02e58733          	mul	a4,a1,a4
    80001ae8:	9732                	add	a4,a4,a2
    80001aea:	32072683          	lw	a3,800(a4)
	queues[queue_no].arr[new_process_idx] = p;
    80001aee:	06500793          	li	a5,101
    80001af2:	02f587b3          	mul	a5,a1,a5
    80001af6:	97b6                	add	a5,a5,a3
    80001af8:	078e                	slli	a5,a5,0x3
    80001afa:	963e                	add	a2,a2,a5
    80001afc:	e208                	sd	a0,0(a2)
	queues[queue_no].queue_size++;
    80001afe:	2685                	addiw	a3,a3,1
    80001b00:	32d72023          	sw	a3,800(a4)
	p->q_run_time = 0;
    80001b04:	1a052a23          	sw	zero,436(a0)
	p->q_wait_time = 0;
    80001b08:	1a052823          	sw	zero,432(a0)
	p->queue_no = queue_no;
    80001b0c:	18b52c23          	sw	a1,408(a0)
}
    80001b10:	6422                	ld	s0,8(sp)
    80001b12:	0141                	addi	sp,sp,16
    80001b14:	8082                	ret

0000000080001b16 <sys_sigalarm>:
{
    80001b16:	1101                	addi	sp,sp,-32
    80001b18:	ec06                	sd	ra,24(sp)
    80001b1a:	e822                	sd	s0,16(sp)
    80001b1c:	1000                	addi	s0,sp,32
	argint(0, &ticks);
    80001b1e:	fec40593          	addi	a1,s0,-20
    80001b22:	4501                	li	a0,0
    80001b24:	00001097          	auipc	ra,0x1
    80001b28:	414080e7          	jalr	1044(ra) # 80002f38 <argint>
	argaddr(1, &handler);
    80001b2c:	fe040593          	addi	a1,s0,-32
    80001b30:	4505                	li	a0,1
    80001b32:	00001097          	auipc	ra,0x1
    80001b36:	426080e7          	jalr	1062(ra) # 80002f58 <argaddr>
	myproc()->is_sigalarm = 0;
    80001b3a:	00000097          	auipc	ra,0x0
    80001b3e:	e6c080e7          	jalr	-404(ra) # 800019a6 <myproc>
    80001b42:	16052a23          	sw	zero,372(a0)
	myproc()->ticks = ticks;
    80001b46:	00000097          	auipc	ra,0x0
    80001b4a:	e60080e7          	jalr	-416(ra) # 800019a6 <myproc>
    80001b4e:	fec42783          	lw	a5,-20(s0)
    80001b52:	16f52e23          	sw	a5,380(a0)
	myproc()->now_ticks = 0;
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	e50080e7          	jalr	-432(ra) # 800019a6 <myproc>
    80001b5e:	18052023          	sw	zero,384(a0)
	myproc()->handler = handler;
    80001b62:	00000097          	auipc	ra,0x0
    80001b66:	e44080e7          	jalr	-444(ra) # 800019a6 <myproc>
    80001b6a:	fe043783          	ld	a5,-32(s0)
    80001b6e:	18f53423          	sd	a5,392(a0)
}
    80001b72:	4501                	li	a0,0
    80001b74:	60e2                	ld	ra,24(sp)
    80001b76:	6442                	ld	s0,16(sp)
    80001b78:	6105                	addi	sp,sp,32
    80001b7a:	8082                	ret

0000000080001b7c <proc_pagetable>:
{
    80001b7c:	1101                	addi	sp,sp,-32
    80001b7e:	ec06                	sd	ra,24(sp)
    80001b80:	e822                	sd	s0,16(sp)
    80001b82:	e426                	sd	s1,8(sp)
    80001b84:	e04a                	sd	s2,0(sp)
    80001b86:	1000                	addi	s0,sp,32
    80001b88:	892a                	mv	s2,a0
	pagetable = uvmcreate();
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	798080e7          	jalr	1944(ra) # 80001322 <uvmcreate>
    80001b92:	84aa                	mv	s1,a0
	if(pagetable == 0)
    80001b94:	c121                	beqz	a0,80001bd4 <proc_pagetable+0x58>
	if(mappages(pagetable, TRAMPOLINE, PGSIZE, (uint64)trampoline, PTE_R | PTE_X) < 0)
    80001b96:	4729                	li	a4,10
    80001b98:	00005697          	auipc	a3,0x5
    80001b9c:	46868693          	addi	a3,a3,1128 # 80007000 <_trampoline>
    80001ba0:	6605                	lui	a2,0x1
    80001ba2:	040005b7          	lui	a1,0x4000
    80001ba6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ba8:	05b2                	slli	a1,a1,0xc
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	4ee080e7          	jalr	1262(ra) # 80001098 <mappages>
    80001bb2:	02054863          	bltz	a0,80001be2 <proc_pagetable+0x66>
	if(mappages(pagetable, TRAPFRAME, PGSIZE, (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
    80001bb6:	4719                	li	a4,6
    80001bb8:	05893683          	ld	a3,88(s2)
    80001bbc:	6605                	lui	a2,0x1
    80001bbe:	020005b7          	lui	a1,0x2000
    80001bc2:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bc4:	05b6                	slli	a1,a1,0xd
    80001bc6:	8526                	mv	a0,s1
    80001bc8:	fffff097          	auipc	ra,0xfffff
    80001bcc:	4d0080e7          	jalr	1232(ra) # 80001098 <mappages>
    80001bd0:	02054163          	bltz	a0,80001bf2 <proc_pagetable+0x76>
}
    80001bd4:	8526                	mv	a0,s1
    80001bd6:	60e2                	ld	ra,24(sp)
    80001bd8:	6442                	ld	s0,16(sp)
    80001bda:	64a2                	ld	s1,8(sp)
    80001bdc:	6902                	ld	s2,0(sp)
    80001bde:	6105                	addi	sp,sp,32
    80001be0:	8082                	ret
		uvmfree(pagetable, 0);
    80001be2:	4581                	li	a1,0
    80001be4:	8526                	mv	a0,s1
    80001be6:	00000097          	auipc	ra,0x0
    80001bea:	942080e7          	jalr	-1726(ra) # 80001528 <uvmfree>
		return 0;
    80001bee:	4481                	li	s1,0
    80001bf0:	b7d5                	j	80001bd4 <proc_pagetable+0x58>
		uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bf2:	4681                	li	a3,0
    80001bf4:	4605                	li	a2,1
    80001bf6:	040005b7          	lui	a1,0x4000
    80001bfa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bfc:	05b2                	slli	a1,a1,0xc
    80001bfe:	8526                	mv	a0,s1
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	65e080e7          	jalr	1630(ra) # 8000125e <uvmunmap>
		uvmfree(pagetable, 0);
    80001c08:	4581                	li	a1,0
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	91c080e7          	jalr	-1764(ra) # 80001528 <uvmfree>
		return 0;
    80001c14:	4481                	li	s1,0
    80001c16:	bf7d                	j	80001bd4 <proc_pagetable+0x58>

0000000080001c18 <proc_freepagetable>:
{
    80001c18:	1101                	addi	sp,sp,-32
    80001c1a:	ec06                	sd	ra,24(sp)
    80001c1c:	e822                	sd	s0,16(sp)
    80001c1e:	e426                	sd	s1,8(sp)
    80001c20:	e04a                	sd	s2,0(sp)
    80001c22:	1000                	addi	s0,sp,32
    80001c24:	84aa                	mv	s1,a0
    80001c26:	892e                	mv	s2,a1
	uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c28:	4681                	li	a3,0
    80001c2a:	4605                	li	a2,1
    80001c2c:	040005b7          	lui	a1,0x4000
    80001c30:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c32:	05b2                	slli	a1,a1,0xc
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	62a080e7          	jalr	1578(ra) # 8000125e <uvmunmap>
	uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c3c:	4681                	li	a3,0
    80001c3e:	4605                	li	a2,1
    80001c40:	020005b7          	lui	a1,0x2000
    80001c44:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c46:	05b6                	slli	a1,a1,0xd
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	614080e7          	jalr	1556(ra) # 8000125e <uvmunmap>
	uvmfree(pagetable, sz);
    80001c52:	85ca                	mv	a1,s2
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	8d2080e7          	jalr	-1838(ra) # 80001528 <uvmfree>
}
    80001c5e:	60e2                	ld	ra,24(sp)
    80001c60:	6442                	ld	s0,16(sp)
    80001c62:	64a2                	ld	s1,8(sp)
    80001c64:	6902                	ld	s2,0(sp)
    80001c66:	6105                	addi	sp,sp,32
    80001c68:	8082                	ret

0000000080001c6a <freeproc>:
{
    80001c6a:	1101                	addi	sp,sp,-32
    80001c6c:	ec06                	sd	ra,24(sp)
    80001c6e:	e822                	sd	s0,16(sp)
    80001c70:	e426                	sd	s1,8(sp)
    80001c72:	1000                	addi	s0,sp,32
    80001c74:	84aa                	mv	s1,a0
	if(p->backup_trapframe)
    80001c76:	19053503          	ld	a0,400(a0)
    80001c7a:	c509                	beqz	a0,80001c84 <freeproc+0x1a>
		kfree((void*)p->backup_trapframe);
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	d68080e7          	jalr	-664(ra) # 800009e4 <kfree>
	if(p->trapframe)
    80001c84:	6ca8                	ld	a0,88(s1)
    80001c86:	c509                	beqz	a0,80001c90 <freeproc+0x26>
		kfree((void*)p->trapframe);
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	d5c080e7          	jalr	-676(ra) # 800009e4 <kfree>
	p->trapframe = 0;
    80001c90:	0404bc23          	sd	zero,88(s1)
	if(p->pagetable)
    80001c94:	68a8                	ld	a0,80(s1)
    80001c96:	c511                	beqz	a0,80001ca2 <freeproc+0x38>
		proc_freepagetable(p->pagetable, p->sz);
    80001c98:	64ac                	ld	a1,72(s1)
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	f7e080e7          	jalr	-130(ra) # 80001c18 <proc_freepagetable>
	p->pagetable = 0;
    80001ca2:	0404b823          	sd	zero,80(s1)
	p->sz = 0;
    80001ca6:	0404b423          	sd	zero,72(s1)
	p->pid = 0;
    80001caa:	0204a823          	sw	zero,48(s1)
	p->parent = 0;
    80001cae:	0204bc23          	sd	zero,56(s1)
	p->name[0] = 0;
    80001cb2:	14048c23          	sb	zero,344(s1)
	p->chan = 0;
    80001cb6:	0204b023          	sd	zero,32(s1)
	p->killed = 0;
    80001cba:	0204a423          	sw	zero,40(s1)
	p->xstate = 0;
    80001cbe:	0204a623          	sw	zero,44(s1)
	p->state = UNUSED;
    80001cc2:	0004ac23          	sw	zero,24(s1)
	p->start_time = 0 ;
    80001cc6:	1604ac23          	sw	zero,376(s1)
		p->queue_no = 0;
    80001cca:	1804ac23          	sw	zero,408(s1)
		p->time_spent[i] = 0;
    80001cce:	1804ae23          	sw	zero,412(s1)
    80001cd2:	1a04a023          	sw	zero,416(s1)
    80001cd6:	1a04a223          	sw	zero,420(s1)
    80001cda:	1a04a423          	sw	zero,424(s1)
}
    80001cde:	60e2                	ld	ra,24(sp)
    80001ce0:	6442                	ld	s0,16(sp)
    80001ce2:	64a2                	ld	s1,8(sp)
    80001ce4:	6105                	addi	sp,sp,32
    80001ce6:	8082                	ret

0000000080001ce8 <allocproc>:
{
    80001ce8:	1101                	addi	sp,sp,-32
    80001cea:	ec06                	sd	ra,24(sp)
    80001cec:	e822                	sd	s0,16(sp)
    80001cee:	e426                	sd	s1,8(sp)
    80001cf0:	e04a                	sd	s2,0(sp)
    80001cf2:	1000                	addi	s0,sp,32
	for(p = proc; p < &proc[NPROC]; p++)
    80001cf4:	00010497          	auipc	s1,0x10
    80001cf8:	edc48493          	addi	s1,s1,-292 # 80011bd0 <proc>
    80001cfc:	00017917          	auipc	s2,0x17
    80001d00:	ed490913          	addi	s2,s2,-300 # 80018bd0 <tickslock>
		acquire(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	ecc080e7          	jalr	-308(ra) # 80000bd2 <acquire>
		if(p->state == UNUSED)
    80001d0e:	4c9c                	lw	a5,24(s1)
    80001d10:	cf81                	beqz	a5,80001d28 <allocproc+0x40>
			release(&p->lock);
    80001d12:	8526                	mv	a0,s1
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	f72080e7          	jalr	-142(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    80001d1c:	1c048493          	addi	s1,s1,448
    80001d20:	ff2492e3          	bne	s1,s2,80001d04 <allocproc+0x1c>
	return 0;
    80001d24:	4481                	li	s1,0
    80001d26:	a05d                	j	80001dcc <allocproc+0xe4>
	p->pid = allocpid();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	cfc080e7          	jalr	-772(ra) # 80001a24 <allocpid>
    80001d30:	d888                	sw	a0,48(s1)
	p->state = USED;
    80001d32:	4785                	li	a5,1
    80001d34:	cc9c                	sw	a5,24(s1)
	if((p->trapframe = (struct trapframe*)kalloc()) == 0)
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	dac080e7          	jalr	-596(ra) # 80000ae2 <kalloc>
    80001d3e:	892a                	mv	s2,a0
    80001d40:	eca8                	sd	a0,88(s1)
    80001d42:	cd41                	beqz	a0,80001dda <allocproc+0xf2>
	if((p->backup_trapframe = (struct trapframe*)kalloc()) == 0)
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	d9e080e7          	jalr	-610(ra) # 80000ae2 <kalloc>
    80001d4c:	892a                	mv	s2,a0
    80001d4e:	18a4b823          	sd	a0,400(s1)
    80001d52:	c145                	beqz	a0,80001df2 <allocproc+0x10a>
	p->pagetable = proc_pagetable(p);
    80001d54:	8526                	mv	a0,s1
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	e26080e7          	jalr	-474(ra) # 80001b7c <proc_pagetable>
    80001d5e:	892a                	mv	s2,a0
    80001d60:	e8a8                	sd	a0,80(s1)
	if(p->pagetable == 0)
    80001d62:	cd59                	beqz	a0,80001e00 <allocproc+0x118>
	memset(&p->context, 0, sizeof(p->context));
    80001d64:	07000613          	li	a2,112
    80001d68:	4581                	li	a1,0
    80001d6a:	06048513          	addi	a0,s1,96
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	f60080e7          	jalr	-160(ra) # 80000cce <memset>
	p->context.ra = (uint64)forkret;
    80001d76:	00000797          	auipc	a5,0x0
    80001d7a:	c6878793          	addi	a5,a5,-920 # 800019de <forkret>
    80001d7e:	f0bc                	sd	a5,96(s1)
	p->context.sp = p->kstack + PGSIZE;
    80001d80:	60bc                	ld	a5,64(s1)
    80001d82:	6705                	lui	a4,0x1
    80001d84:	97ba                	add	a5,a5,a4
    80001d86:	f4bc                	sd	a5,104(s1)
	p->rtime = 0;
    80001d88:	1604a423          	sw	zero,360(s1)
	p->etime = 0;
    80001d8c:	1604a823          	sw	zero,368(s1)
	p->ctime = ticks;
    80001d90:	00007797          	auipc	a5,0x7
    80001d94:	b007a783          	lw	a5,-1280(a5) # 80008890 <ticks>
    80001d98:	16f4a623          	sw	a5,364(s1)
	p->is_sigalarm = 0;
    80001d9c:	1604aa23          	sw	zero,372(s1)
	p->ticks = 0;
    80001da0:	1604ae23          	sw	zero,380(s1)
	p->now_ticks = 0;
    80001da4:	1804a023          	sw	zero,384(s1)
	p->handler = 0;
    80001da8:	1804b423          	sd	zero,392(s1)
	p->start_time = 0 ;
    80001dac:	1604ac23          	sw	zero,376(s1)
	p->q_wait_time = 0;
    80001db0:	1a04a823          	sw	zero,432(s1)
	p->q_run_time = 0;
    80001db4:	1a04aa23          	sw	zero,436(s1)
	p->q_leap = 0;
    80001db8:	1a04ac23          	sw	zero,440(s1)
		p->time_spent[i] = 0;
    80001dbc:	1804ae23          	sw	zero,412(s1)
    80001dc0:	1a04a023          	sw	zero,416(s1)
    80001dc4:	1a04a223          	sw	zero,420(s1)
    80001dc8:	1a04a423          	sw	zero,424(s1)
}
    80001dcc:	8526                	mv	a0,s1
    80001dce:	60e2                	ld	ra,24(sp)
    80001dd0:	6442                	ld	s0,16(sp)
    80001dd2:	64a2                	ld	s1,8(sp)
    80001dd4:	6902                	ld	s2,0(sp)
    80001dd6:	6105                	addi	sp,sp,32
    80001dd8:	8082                	ret
		freeproc(p);
    80001dda:	8526                	mv	a0,s1
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	e8e080e7          	jalr	-370(ra) # 80001c6a <freeproc>
		release(&p->lock);
    80001de4:	8526                	mv	a0,s1
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	ea0080e7          	jalr	-352(ra) # 80000c86 <release>
		return 0;
    80001dee:	84ca                	mv	s1,s2
    80001df0:	bff1                	j	80001dcc <allocproc+0xe4>
		release(&p->lock);
    80001df2:	8526                	mv	a0,s1
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	e92080e7          	jalr	-366(ra) # 80000c86 <release>
		return 0;
    80001dfc:	84ca                	mv	s1,s2
    80001dfe:	b7f9                	j	80001dcc <allocproc+0xe4>
		freeproc(p);
    80001e00:	8526                	mv	a0,s1
    80001e02:	00000097          	auipc	ra,0x0
    80001e06:	e68080e7          	jalr	-408(ra) # 80001c6a <freeproc>
		release(&p->lock);
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	fffff097          	auipc	ra,0xfffff
    80001e10:	e7a080e7          	jalr	-390(ra) # 80000c86 <release>
		return 0;
    80001e14:	84ca                	mv	s1,s2
    80001e16:	bf5d                	j	80001dcc <allocproc+0xe4>

0000000080001e18 <userinit>:
{
    80001e18:	1101                	addi	sp,sp,-32
    80001e1a:	ec06                	sd	ra,24(sp)
    80001e1c:	e822                	sd	s0,16(sp)
    80001e1e:	e426                	sd	s1,8(sp)
    80001e20:	1000                	addi	s0,sp,32
	p = allocproc();
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	ec6080e7          	jalr	-314(ra) # 80001ce8 <allocproc>
    80001e2a:	84aa                	mv	s1,a0
	initproc = p;
    80001e2c:	00007797          	auipc	a5,0x7
    80001e30:	a4a7be23          	sd	a0,-1444(a5) # 80008888 <initproc>
	uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e34:	03400613          	li	a2,52
    80001e38:	00007597          	auipc	a1,0x7
    80001e3c:	9c858593          	addi	a1,a1,-1592 # 80008800 <initcode>
    80001e40:	6928                	ld	a0,80(a0)
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	50e080e7          	jalr	1294(ra) # 80001350 <uvmfirst>
	p->sz = PGSIZE;
    80001e4a:	6785                	lui	a5,0x1
    80001e4c:	e4bc                	sd	a5,72(s1)
	p->trapframe->epc = 0; // user program counter
    80001e4e:	6cb8                	ld	a4,88(s1)
    80001e50:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
	p->trapframe->sp = PGSIZE; // user stack pointer
    80001e54:	6cb8                	ld	a4,88(s1)
    80001e56:	fb1c                	sd	a5,48(a4)
	safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e58:	4641                	li	a2,16
    80001e5a:	00006597          	auipc	a1,0x6
    80001e5e:	3a658593          	addi	a1,a1,934 # 80008200 <digits+0x1c0>
    80001e62:	15848513          	addi	a0,s1,344
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	fb0080e7          	jalr	-80(ra) # 80000e16 <safestrcpy>
	p->cwd = namei("/");
    80001e6e:	00006517          	auipc	a0,0x6
    80001e72:	3a250513          	addi	a0,a0,930 # 80008210 <digits+0x1d0>
    80001e76:	00002097          	auipc	ra,0x2
    80001e7a:	502080e7          	jalr	1282(ra) # 80004378 <namei>
    80001e7e:	14a4b823          	sd	a0,336(s1)
	p->state = RUNNABLE;
    80001e82:	478d                	li	a5,3
    80001e84:	cc9c                	sw	a5,24(s1)
	release(&p->lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	dfe080e7          	jalr	-514(ra) # 80000c86 <release>
}
    80001e90:	60e2                	ld	ra,24(sp)
    80001e92:	6442                	ld	s0,16(sp)
    80001e94:	64a2                	ld	s1,8(sp)
    80001e96:	6105                	addi	sp,sp,32
    80001e98:	8082                	ret

0000000080001e9a <growproc>:
{
    80001e9a:	1101                	addi	sp,sp,-32
    80001e9c:	ec06                	sd	ra,24(sp)
    80001e9e:	e822                	sd	s0,16(sp)
    80001ea0:	e426                	sd	s1,8(sp)
    80001ea2:	e04a                	sd	s2,0(sp)
    80001ea4:	1000                	addi	s0,sp,32
    80001ea6:	892a                	mv	s2,a0
	struct proc* p = myproc();
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	afe080e7          	jalr	-1282(ra) # 800019a6 <myproc>
    80001eb0:	84aa                	mv	s1,a0
	sz = p->sz;
    80001eb2:	652c                	ld	a1,72(a0)
	if(n > 0)
    80001eb4:	01204c63          	bgtz	s2,80001ecc <growproc+0x32>
	else if(n < 0)
    80001eb8:	02094663          	bltz	s2,80001ee4 <growproc+0x4a>
	p->sz = sz;
    80001ebc:	e4ac                	sd	a1,72(s1)
	return 0;
    80001ebe:	4501                	li	a0,0
}
    80001ec0:	60e2                	ld	ra,24(sp)
    80001ec2:	6442                	ld	s0,16(sp)
    80001ec4:	64a2                	ld	s1,8(sp)
    80001ec6:	6902                	ld	s2,0(sp)
    80001ec8:	6105                	addi	sp,sp,32
    80001eca:	8082                	ret
		if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001ecc:	4691                	li	a3,4
    80001ece:	00b90633          	add	a2,s2,a1
    80001ed2:	6928                	ld	a0,80(a0)
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	536080e7          	jalr	1334(ra) # 8000140a <uvmalloc>
    80001edc:	85aa                	mv	a1,a0
    80001ede:	fd79                	bnez	a0,80001ebc <growproc+0x22>
			return -1;
    80001ee0:	557d                	li	a0,-1
    80001ee2:	bff9                	j	80001ec0 <growproc+0x26>
		sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ee4:	00b90633          	add	a2,s2,a1
    80001ee8:	6928                	ld	a0,80(a0)
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	4d8080e7          	jalr	1240(ra) # 800013c2 <uvmdealloc>
    80001ef2:	85aa                	mv	a1,a0
    80001ef4:	b7e1                	j	80001ebc <growproc+0x22>

0000000080001ef6 <fork>:
{
    80001ef6:	7139                	addi	sp,sp,-64
    80001ef8:	fc06                	sd	ra,56(sp)
    80001efa:	f822                	sd	s0,48(sp)
    80001efc:	f426                	sd	s1,40(sp)
    80001efe:	f04a                	sd	s2,32(sp)
    80001f00:	ec4e                	sd	s3,24(sp)
    80001f02:	e852                	sd	s4,16(sp)
    80001f04:	e456                	sd	s5,8(sp)
    80001f06:	0080                	addi	s0,sp,64
	struct proc* p = myproc();
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	a9e080e7          	jalr	-1378(ra) # 800019a6 <myproc>
    80001f10:	8aaa                	mv	s5,a0
	if((np = allocproc()) == 0)
    80001f12:	00000097          	auipc	ra,0x0
    80001f16:	dd6080e7          	jalr	-554(ra) # 80001ce8 <allocproc>
    80001f1a:	10050c63          	beqz	a0,80002032 <fork+0x13c>
    80001f1e:	8a2a                	mv	s4,a0
	if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f20:	048ab603          	ld	a2,72(s5)
    80001f24:	692c                	ld	a1,80(a0)
    80001f26:	050ab503          	ld	a0,80(s5)
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	638080e7          	jalr	1592(ra) # 80001562 <uvmcopy>
    80001f32:	04054863          	bltz	a0,80001f82 <fork+0x8c>
	np->sz = p->sz;
    80001f36:	048ab783          	ld	a5,72(s5)
    80001f3a:	04fa3423          	sd	a5,72(s4)
	*(np->trapframe) = *(p->trapframe);
    80001f3e:	058ab683          	ld	a3,88(s5)
    80001f42:	87b6                	mv	a5,a3
    80001f44:	058a3703          	ld	a4,88(s4)
    80001f48:	12068693          	addi	a3,a3,288
    80001f4c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f50:	6788                	ld	a0,8(a5)
    80001f52:	6b8c                	ld	a1,16(a5)
    80001f54:	6f90                	ld	a2,24(a5)
    80001f56:	01073023          	sd	a6,0(a4)
    80001f5a:	e708                	sd	a0,8(a4)
    80001f5c:	eb0c                	sd	a1,16(a4)
    80001f5e:	ef10                	sd	a2,24(a4)
    80001f60:	02078793          	addi	a5,a5,32
    80001f64:	02070713          	addi	a4,a4,32
    80001f68:	fed792e3          	bne	a5,a3,80001f4c <fork+0x56>
	np->trapframe->a0 = 0;
    80001f6c:	058a3783          	ld	a5,88(s4)
    80001f70:	0607b823          	sd	zero,112(a5)
	for(i = 0; i < NOFILE; i++)
    80001f74:	0d0a8493          	addi	s1,s5,208
    80001f78:	0d0a0913          	addi	s2,s4,208
    80001f7c:	150a8993          	addi	s3,s5,336
    80001f80:	a00d                	j	80001fa2 <fork+0xac>
		freeproc(np);
    80001f82:	8552                	mv	a0,s4
    80001f84:	00000097          	auipc	ra,0x0
    80001f88:	ce6080e7          	jalr	-794(ra) # 80001c6a <freeproc>
		release(&np->lock);
    80001f8c:	8552                	mv	a0,s4
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	cf8080e7          	jalr	-776(ra) # 80000c86 <release>
		return -1;
    80001f96:	597d                	li	s2,-1
    80001f98:	a059                	j	8000201e <fork+0x128>
	for(i = 0; i < NOFILE; i++)
    80001f9a:	04a1                	addi	s1,s1,8
    80001f9c:	0921                	addi	s2,s2,8
    80001f9e:	01348b63          	beq	s1,s3,80001fb4 <fork+0xbe>
		if(p->ofile[i])
    80001fa2:	6088                	ld	a0,0(s1)
    80001fa4:	d97d                	beqz	a0,80001f9a <fork+0xa4>
			np->ofile[i] = filedup(p->ofile[i]);
    80001fa6:	00003097          	auipc	ra,0x3
    80001faa:	a44080e7          	jalr	-1468(ra) # 800049ea <filedup>
    80001fae:	00a93023          	sd	a0,0(s2)
    80001fb2:	b7e5                	j	80001f9a <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001fb4:	150ab503          	ld	a0,336(s5)
    80001fb8:	00002097          	auipc	ra,0x2
    80001fbc:	bdc080e7          	jalr	-1060(ra) # 80003b94 <idup>
    80001fc0:	14aa3823          	sd	a0,336(s4)
	safestrcpy(np->name, p->name, sizeof(p->name));
    80001fc4:	4641                	li	a2,16
    80001fc6:	158a8593          	addi	a1,s5,344
    80001fca:	158a0513          	addi	a0,s4,344
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	e48080e7          	jalr	-440(ra) # 80000e16 <safestrcpy>
	pid = np->pid;
    80001fd6:	030a2903          	lw	s2,48(s4)
	release(&np->lock);
    80001fda:	8552                	mv	a0,s4
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	caa080e7          	jalr	-854(ra) # 80000c86 <release>
	acquire(&wait_lock);
    80001fe4:	0000f497          	auipc	s1,0xf
    80001fe8:	b3448493          	addi	s1,s1,-1228 # 80010b18 <wait_lock>
    80001fec:	8526                	mv	a0,s1
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	be4080e7          	jalr	-1052(ra) # 80000bd2 <acquire>
	np->parent = p;
    80001ff6:	035a3c23          	sd	s5,56(s4)
	release(&wait_lock);
    80001ffa:	8526                	mv	a0,s1
    80001ffc:	fffff097          	auipc	ra,0xfffff
    80002000:	c8a080e7          	jalr	-886(ra) # 80000c86 <release>
	acquire(&np->lock);
    80002004:	8552                	mv	a0,s4
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	bcc080e7          	jalr	-1076(ra) # 80000bd2 <acquire>
	np->state = RUNNABLE;
    8000200e:	478d                	li	a5,3
    80002010:	00fa2c23          	sw	a5,24(s4)
	release(&np->lock);
    80002014:	8552                	mv	a0,s4
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	c70080e7          	jalr	-912(ra) # 80000c86 <release>
}
    8000201e:	854a                	mv	a0,s2
    80002020:	70e2                	ld	ra,56(sp)
    80002022:	7442                	ld	s0,48(sp)
    80002024:	74a2                	ld	s1,40(sp)
    80002026:	7902                	ld	s2,32(sp)
    80002028:	69e2                	ld	s3,24(sp)
    8000202a:	6a42                	ld	s4,16(sp)
    8000202c:	6aa2                	ld	s5,8(sp)
    8000202e:	6121                	addi	sp,sp,64
    80002030:	8082                	ret
		return -1;
    80002032:	597d                	li	s2,-1
    80002034:	b7ed                	j	8000201e <fork+0x128>

0000000080002036 <scheduler>:
{
    80002036:	711d                	addi	sp,sp,-96
    80002038:	ec86                	sd	ra,88(sp)
    8000203a:	e8a2                	sd	s0,80(sp)
    8000203c:	e4a6                	sd	s1,72(sp)
    8000203e:	e0ca                	sd	s2,64(sp)
    80002040:	fc4e                	sd	s3,56(sp)
    80002042:	f852                	sd	s4,48(sp)
    80002044:	f456                	sd	s5,40(sp)
    80002046:	f05a                	sd	s6,32(sp)
    80002048:	ec5e                	sd	s7,24(sp)
    8000204a:	e862                	sd	s8,16(sp)
    8000204c:	e466                	sd	s9,8(sp)
    8000204e:	1080                	addi	s0,sp,96
    80002050:	8792                	mv	a5,tp
	int id = r_tp();
    80002052:	2781                	sext.w	a5,a5
	c->proc = 0;
    80002054:	00779693          	slli	a3,a5,0x7
    80002058:	0000f717          	auipc	a4,0xf
    8000205c:	aa870713          	addi	a4,a4,-1368 # 80010b00 <pid_lock>
    80002060:	9736                	add	a4,a4,a3
    80002062:	02073823          	sd	zero,48(a4)
				swtch(&c->context, &min_p->context);
    80002066:	0000f717          	auipc	a4,0xf
    8000206a:	ad270713          	addi	a4,a4,-1326 # 80010b38 <cpus+0x8>
    8000206e:	00e68cb3          	add	s9,a3,a4
		int min_ctime = 0x7fffffff;
    80002072:	80000b37          	lui	s6,0x80000
    80002076:	fffb4b13          	not	s6,s6
			if(p->state == RUNNABLE && p->ctime < min_ctime)
    8000207a:	490d                	li	s2,3
		for(p = proc; p < &proc[NPROC]; p++)
    8000207c:	00017997          	auipc	s3,0x17
    80002080:	b5498993          	addi	s3,s3,-1196 # 80018bd0 <tickslock>
				c->proc = min_p;
    80002084:	0000fc17          	auipc	s8,0xf
    80002088:	a7cc0c13          	addi	s8,s8,-1412 # 80010b00 <pid_lock>
    8000208c:	9c36                	add	s8,s8,a3
    8000208e:	a04d                	j	80002130 <scheduler+0xfa>
			release(&p->lock);
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	bf4080e7          	jalr	-1036(ra) # 80000c86 <release>
		for(p = proc; p < &proc[NPROC]; p++)
    8000209a:	1c048493          	addi	s1,s1,448
    8000209e:	03348e63          	beq	s1,s3,800020da <scheduler+0xa4>
			acquire(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b2e080e7          	jalr	-1234(ra) # 80000bd2 <acquire>
			if(p->state == RUNNABLE && p->ctime < min_ctime)
    800020ac:	4c9c                	lw	a5,24(s1)
    800020ae:	ff2791e3          	bne	a5,s2,80002090 <scheduler+0x5a>
    800020b2:	16c4a783          	lw	a5,364(s1)
    800020b6:	000a071b          	sext.w	a4,s4
    800020ba:	fce7fbe3          	bgeu	a5,a4,80002090 <scheduler+0x5a>
				min_ctime = p->ctime;
    800020be:	00078a1b          	sext.w	s4,a5
			release(&p->lock);
    800020c2:	8526                	mv	a0,s1
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	bc2080e7          	jalr	-1086(ra) # 80000c86 <release>
		for(p = proc; p < &proc[NPROC]; p++)
    800020cc:	1c048793          	addi	a5,s1,448
    800020d0:	03378563          	beq	a5,s3,800020fa <scheduler+0xc4>
    800020d4:	8aa6                	mv	s5,s1
    800020d6:	84be                	mv	s1,a5
    800020d8:	b7e9                	j	800020a2 <scheduler+0x6c>
		if(min_p != 0)
    800020da:	000a9f63          	bnez	s5,800020f8 <scheduler+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020de:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020e2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020e6:	10079073          	csrw	sstatus,a5
		int min_ctime = 0x7fffffff;
    800020ea:	8a5a                	mv	s4,s6
		struct proc* min_p = 0;
    800020ec:	8ade                	mv	s5,s7
		for(p = proc; p < &proc[NPROC]; p++)
    800020ee:	00010497          	auipc	s1,0x10
    800020f2:	ae248493          	addi	s1,s1,-1310 # 80011bd0 <proc>
    800020f6:	b775                	j	800020a2 <scheduler+0x6c>
    800020f8:	84d6                	mv	s1,s5
			acquire(&min_p->lock);
    800020fa:	8a26                	mv	s4,s1
    800020fc:	8526                	mv	a0,s1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	ad4080e7          	jalr	-1324(ra) # 80000bd2 <acquire>
			if(min_p->state == RUNNABLE)
    80002106:	4c9c                	lw	a5,24(s1)
    80002108:	01279f63          	bne	a5,s2,80002126 <scheduler+0xf0>
				min_p->state = RUNNING;
    8000210c:	4791                	li	a5,4
    8000210e:	cc9c                	sw	a5,24(s1)
				c->proc = min_p;
    80002110:	029c3823          	sd	s1,48(s8)
				swtch(&c->context, &min_p->context);
    80002114:	06048593          	addi	a1,s1,96
    80002118:	8566                	mv	a0,s9
    8000211a:	00001097          	auipc	ra,0x1
    8000211e:	8c2080e7          	jalr	-1854(ra) # 800029dc <swtch>
				c->proc = 0;
    80002122:	020c3823          	sd	zero,48(s8)
			release(&min_p->lock);
    80002126:	8552                	mv	a0,s4
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b5e080e7          	jalr	-1186(ra) # 80000c86 <release>
		struct proc* min_p = 0;
    80002130:	4b81                	li	s7,0
    80002132:	b775                	j	800020de <scheduler+0xa8>

0000000080002134 <sched>:
{
    80002134:	7179                	addi	sp,sp,-48
    80002136:	f406                	sd	ra,40(sp)
    80002138:	f022                	sd	s0,32(sp)
    8000213a:	ec26                	sd	s1,24(sp)
    8000213c:	e84a                	sd	s2,16(sp)
    8000213e:	e44e                	sd	s3,8(sp)
    80002140:	1800                	addi	s0,sp,48
	struct proc* p = myproc();
    80002142:	00000097          	auipc	ra,0x0
    80002146:	864080e7          	jalr	-1948(ra) # 800019a6 <myproc>
    8000214a:	84aa                	mv	s1,a0
	if(!holding(&p->lock))
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	a0c080e7          	jalr	-1524(ra) # 80000b58 <holding>
    80002154:	c93d                	beqz	a0,800021ca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002156:	8792                	mv	a5,tp
	if(mycpu()->noff != 1)
    80002158:	2781                	sext.w	a5,a5
    8000215a:	079e                	slli	a5,a5,0x7
    8000215c:	0000f717          	auipc	a4,0xf
    80002160:	9a470713          	addi	a4,a4,-1628 # 80010b00 <pid_lock>
    80002164:	97ba                	add	a5,a5,a4
    80002166:	0a87a703          	lw	a4,168(a5)
    8000216a:	4785                	li	a5,1
    8000216c:	06f71763          	bne	a4,a5,800021da <sched+0xa6>
	if(p->state == RUNNING)
    80002170:	4c98                	lw	a4,24(s1)
    80002172:	4791                	li	a5,4
    80002174:	06f70b63          	beq	a4,a5,800021ea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002178:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000217c:	8b89                	andi	a5,a5,2
	if(intr_get())
    8000217e:	efb5                	bnez	a5,800021fa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002180:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    80002182:	0000f917          	auipc	s2,0xf
    80002186:	97e90913          	addi	s2,s2,-1666 # 80010b00 <pid_lock>
    8000218a:	2781                	sext.w	a5,a5
    8000218c:	079e                	slli	a5,a5,0x7
    8000218e:	97ca                	add	a5,a5,s2
    80002190:	0ac7a983          	lw	s3,172(a5)
    80002194:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    80002196:	2781                	sext.w	a5,a5
    80002198:	079e                	slli	a5,a5,0x7
    8000219a:	0000f597          	auipc	a1,0xf
    8000219e:	99e58593          	addi	a1,a1,-1634 # 80010b38 <cpus+0x8>
    800021a2:	95be                	add	a1,a1,a5
    800021a4:	06048513          	addi	a0,s1,96
    800021a8:	00001097          	auipc	ra,0x1
    800021ac:	834080e7          	jalr	-1996(ra) # 800029dc <swtch>
    800021b0:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    800021b2:	2781                	sext.w	a5,a5
    800021b4:	079e                	slli	a5,a5,0x7
    800021b6:	993e                	add	s2,s2,a5
    800021b8:	0b392623          	sw	s3,172(s2)
}
    800021bc:	70a2                	ld	ra,40(sp)
    800021be:	7402                	ld	s0,32(sp)
    800021c0:	64e2                	ld	s1,24(sp)
    800021c2:	6942                	ld	s2,16(sp)
    800021c4:	69a2                	ld	s3,8(sp)
    800021c6:	6145                	addi	sp,sp,48
    800021c8:	8082                	ret
		panic("sched p->lock");
    800021ca:	00006517          	auipc	a0,0x6
    800021ce:	04e50513          	addi	a0,a0,78 # 80008218 <digits+0x1d8>
    800021d2:	ffffe097          	auipc	ra,0xffffe
    800021d6:	36a080e7          	jalr	874(ra) # 8000053c <panic>
		panic("sched locks");
    800021da:	00006517          	auipc	a0,0x6
    800021de:	04e50513          	addi	a0,a0,78 # 80008228 <digits+0x1e8>
    800021e2:	ffffe097          	auipc	ra,0xffffe
    800021e6:	35a080e7          	jalr	858(ra) # 8000053c <panic>
		panic("sched running");
    800021ea:	00006517          	auipc	a0,0x6
    800021ee:	04e50513          	addi	a0,a0,78 # 80008238 <digits+0x1f8>
    800021f2:	ffffe097          	auipc	ra,0xffffe
    800021f6:	34a080e7          	jalr	842(ra) # 8000053c <panic>
		panic("sched interruptible");
    800021fa:	00006517          	auipc	a0,0x6
    800021fe:	04e50513          	addi	a0,a0,78 # 80008248 <digits+0x208>
    80002202:	ffffe097          	auipc	ra,0xffffe
    80002206:	33a080e7          	jalr	826(ra) # 8000053c <panic>

000000008000220a <yield>:
{
    8000220a:	1101                	addi	sp,sp,-32
    8000220c:	ec06                	sd	ra,24(sp)
    8000220e:	e822                	sd	s0,16(sp)
    80002210:	e426                	sd	s1,8(sp)
    80002212:	1000                	addi	s0,sp,32
	struct proc* p = myproc();
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	792080e7          	jalr	1938(ra) # 800019a6 <myproc>
    8000221c:	84aa                	mv	s1,a0
	acquire(&p->lock);
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	9b4080e7          	jalr	-1612(ra) # 80000bd2 <acquire>
	p->state = RUNNABLE;
    80002226:	478d                	li	a5,3
    80002228:	cc9c                	sw	a5,24(s1)
	sched();
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	f0a080e7          	jalr	-246(ra) # 80002134 <sched>
	release(&p->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	a52080e7          	jalr	-1454(ra) # 80000c86 <release>
}
    8000223c:	60e2                	ld	ra,24(sp)
    8000223e:	6442                	ld	s0,16(sp)
    80002240:	64a2                	ld	s1,8(sp)
    80002242:	6105                	addi	sp,sp,32
    80002244:	8082                	ret

0000000080002246 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void* chan, struct spinlock* lk)
{
    80002246:	7179                	addi	sp,sp,-48
    80002248:	f406                	sd	ra,40(sp)
    8000224a:	f022                	sd	s0,32(sp)
    8000224c:	ec26                	sd	s1,24(sp)
    8000224e:	e84a                	sd	s2,16(sp)
    80002250:	e44e                	sd	s3,8(sp)
    80002252:	1800                	addi	s0,sp,48
    80002254:	89aa                	mv	s3,a0
    80002256:	892e                	mv	s2,a1
	struct proc* p = myproc();
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	74e080e7          	jalr	1870(ra) # 800019a6 <myproc>
    80002260:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); // DOC: sleeplock1
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	970080e7          	jalr	-1680(ra) # 80000bd2 <acquire>
	release(lk);
    8000226a:	854a                	mv	a0,s2
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a1a080e7          	jalr	-1510(ra) # 80000c86 <release>

	// Go to sleep.
	p->chan = chan;
    80002274:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    80002278:	4789                	li	a5,2
    8000227a:	cc9c                	sw	a5,24(s1)

	sched();
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	eb8080e7          	jalr	-328(ra) # 80002134 <sched>

	// Tidy up.
	p->chan = 0;
    80002284:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	9fc080e7          	jalr	-1540(ra) # 80000c86 <release>
	acquire(lk);
    80002292:	854a                	mv	a0,s2
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	93e080e7          	jalr	-1730(ra) # 80000bd2 <acquire>
}
    8000229c:	70a2                	ld	ra,40(sp)
    8000229e:	7402                	ld	s0,32(sp)
    800022a0:	64e2                	ld	s1,24(sp)
    800022a2:	6942                	ld	s2,16(sp)
    800022a4:	69a2                	ld	s3,8(sp)
    800022a6:	6145                	addi	sp,sp,48
    800022a8:	8082                	ret

00000000800022aa <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void* chan)
{
    800022aa:	7139                	addi	sp,sp,-64
    800022ac:	fc06                	sd	ra,56(sp)
    800022ae:	f822                	sd	s0,48(sp)
    800022b0:	f426                	sd	s1,40(sp)
    800022b2:	f04a                	sd	s2,32(sp)
    800022b4:	ec4e                	sd	s3,24(sp)
    800022b6:	e852                	sd	s4,16(sp)
    800022b8:	e456                	sd	s5,8(sp)
    800022ba:	0080                	addi	s0,sp,64
    800022bc:	8a2a                	mv	s4,a0
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    800022be:	00010497          	auipc	s1,0x10
    800022c2:	91248493          	addi	s1,s1,-1774 # 80011bd0 <proc>
	{
		if(p != myproc())
		{
			acquire(&p->lock);
			if(p->state == SLEEPING && p->chan == chan)
    800022c6:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    800022c8:	4a8d                	li	s5,3
	for(p = proc; p < &proc[NPROC]; p++)
    800022ca:	00017917          	auipc	s2,0x17
    800022ce:	90690913          	addi	s2,s2,-1786 # 80018bd0 <tickslock>
    800022d2:	a811                	j	800022e6 <wakeup+0x3c>
				#ifdef MLFQ
				queue_add(p, p->queue_no);
				#endif
			}
			release(&p->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	9b0080e7          	jalr	-1616(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    800022de:	1c048493          	addi	s1,s1,448
    800022e2:	03248663          	beq	s1,s2,8000230e <wakeup+0x64>
		if(p != myproc())
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	6c0080e7          	jalr	1728(ra) # 800019a6 <myproc>
    800022ee:	fea488e3          	beq	s1,a0,800022de <wakeup+0x34>
			acquire(&p->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	8de080e7          	jalr	-1826(ra) # 80000bd2 <acquire>
			if(p->state == SLEEPING && p->chan == chan)
    800022fc:	4c9c                	lw	a5,24(s1)
    800022fe:	fd379be3          	bne	a5,s3,800022d4 <wakeup+0x2a>
    80002302:	709c                	ld	a5,32(s1)
    80002304:	fd4798e3          	bne	a5,s4,800022d4 <wakeup+0x2a>
				p->state = RUNNABLE;
    80002308:	0154ac23          	sw	s5,24(s1)
    8000230c:	b7e1                	j	800022d4 <wakeup+0x2a>
		}
	}
}
    8000230e:	70e2                	ld	ra,56(sp)
    80002310:	7442                	ld	s0,48(sp)
    80002312:	74a2                	ld	s1,40(sp)
    80002314:	7902                	ld	s2,32(sp)
    80002316:	69e2                	ld	s3,24(sp)
    80002318:	6a42                	ld	s4,16(sp)
    8000231a:	6aa2                	ld	s5,8(sp)
    8000231c:	6121                	addi	sp,sp,64
    8000231e:	8082                	ret

0000000080002320 <reparent>:
{
    80002320:	7179                	addi	sp,sp,-48
    80002322:	f406                	sd	ra,40(sp)
    80002324:	f022                	sd	s0,32(sp)
    80002326:	ec26                	sd	s1,24(sp)
    80002328:	e84a                	sd	s2,16(sp)
    8000232a:	e44e                	sd	s3,8(sp)
    8000232c:	e052                	sd	s4,0(sp)
    8000232e:	1800                	addi	s0,sp,48
    80002330:	892a                	mv	s2,a0
	for(pp = proc; pp < &proc[NPROC]; pp++)
    80002332:	00010497          	auipc	s1,0x10
    80002336:	89e48493          	addi	s1,s1,-1890 # 80011bd0 <proc>
			pp->parent = initproc;
    8000233a:	00006a17          	auipc	s4,0x6
    8000233e:	54ea0a13          	addi	s4,s4,1358 # 80008888 <initproc>
	for(pp = proc; pp < &proc[NPROC]; pp++)
    80002342:	00017997          	auipc	s3,0x17
    80002346:	88e98993          	addi	s3,s3,-1906 # 80018bd0 <tickslock>
    8000234a:	a029                	j	80002354 <reparent+0x34>
    8000234c:	1c048493          	addi	s1,s1,448
    80002350:	01348d63          	beq	s1,s3,8000236a <reparent+0x4a>
		if(pp->parent == p)
    80002354:	7c9c                	ld	a5,56(s1)
    80002356:	ff279be3          	bne	a5,s2,8000234c <reparent+0x2c>
			pp->parent = initproc;
    8000235a:	000a3503          	ld	a0,0(s4)
    8000235e:	fc88                	sd	a0,56(s1)
			wakeup(initproc);
    80002360:	00000097          	auipc	ra,0x0
    80002364:	f4a080e7          	jalr	-182(ra) # 800022aa <wakeup>
    80002368:	b7d5                	j	8000234c <reparent+0x2c>
}
    8000236a:	70a2                	ld	ra,40(sp)
    8000236c:	7402                	ld	s0,32(sp)
    8000236e:	64e2                	ld	s1,24(sp)
    80002370:	6942                	ld	s2,16(sp)
    80002372:	69a2                	ld	s3,8(sp)
    80002374:	6a02                	ld	s4,0(sp)
    80002376:	6145                	addi	sp,sp,48
    80002378:	8082                	ret

000000008000237a <exit>:
{
    8000237a:	7179                	addi	sp,sp,-48
    8000237c:	f406                	sd	ra,40(sp)
    8000237e:	f022                	sd	s0,32(sp)
    80002380:	ec26                	sd	s1,24(sp)
    80002382:	e84a                	sd	s2,16(sp)
    80002384:	e44e                	sd	s3,8(sp)
    80002386:	e052                	sd	s4,0(sp)
    80002388:	1800                	addi	s0,sp,48
    8000238a:	8a2a                	mv	s4,a0
	struct proc* p = myproc();
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	61a080e7          	jalr	1562(ra) # 800019a6 <myproc>
    80002394:	89aa                	mv	s3,a0
	if(p == initproc)
    80002396:	00006797          	auipc	a5,0x6
    8000239a:	4f27b783          	ld	a5,1266(a5) # 80008888 <initproc>
    8000239e:	0d050493          	addi	s1,a0,208
    800023a2:	15050913          	addi	s2,a0,336
    800023a6:	02a79363          	bne	a5,a0,800023cc <exit+0x52>
		panic("init exiting");
    800023aa:	00006517          	auipc	a0,0x6
    800023ae:	eb650513          	addi	a0,a0,-330 # 80008260 <digits+0x220>
    800023b2:	ffffe097          	auipc	ra,0xffffe
    800023b6:	18a080e7          	jalr	394(ra) # 8000053c <panic>
			fileclose(f);
    800023ba:	00002097          	auipc	ra,0x2
    800023be:	682080e7          	jalr	1666(ra) # 80004a3c <fileclose>
			p->ofile[fd] = 0;
    800023c2:	0004b023          	sd	zero,0(s1)
	for(int fd = 0; fd < NOFILE; fd++)
    800023c6:	04a1                	addi	s1,s1,8
    800023c8:	01248563          	beq	s1,s2,800023d2 <exit+0x58>
		if(p->ofile[fd])
    800023cc:	6088                	ld	a0,0(s1)
    800023ce:	f575                	bnez	a0,800023ba <exit+0x40>
    800023d0:	bfdd                	j	800023c6 <exit+0x4c>
	begin_op();
    800023d2:	00002097          	auipc	ra,0x2
    800023d6:	1a6080e7          	jalr	422(ra) # 80004578 <begin_op>
	iput(p->cwd);
    800023da:	1509b503          	ld	a0,336(s3)
    800023de:	00002097          	auipc	ra,0x2
    800023e2:	9ae080e7          	jalr	-1618(ra) # 80003d8c <iput>
	end_op();
    800023e6:	00002097          	auipc	ra,0x2
    800023ea:	20c080e7          	jalr	524(ra) # 800045f2 <end_op>
	p->cwd = 0;
    800023ee:	1409b823          	sd	zero,336(s3)
	acquire(&wait_lock);
    800023f2:	0000e497          	auipc	s1,0xe
    800023f6:	72648493          	addi	s1,s1,1830 # 80010b18 <wait_lock>
    800023fa:	8526                	mv	a0,s1
    800023fc:	ffffe097          	auipc	ra,0xffffe
    80002400:	7d6080e7          	jalr	2006(ra) # 80000bd2 <acquire>
	reparent(p);
    80002404:	854e                	mv	a0,s3
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	f1a080e7          	jalr	-230(ra) # 80002320 <reparent>
	wakeup(p->parent);
    8000240e:	0389b503          	ld	a0,56(s3)
    80002412:	00000097          	auipc	ra,0x0
    80002416:	e98080e7          	jalr	-360(ra) # 800022aa <wakeup>
	acquire(&p->lock);
    8000241a:	854e                	mv	a0,s3
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	7b6080e7          	jalr	1974(ra) # 80000bd2 <acquire>
	p->xstate = status;
    80002424:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    80002428:	4795                	li	a5,5
    8000242a:	00f9ac23          	sw	a5,24(s3)
	p->etime = ticks;
    8000242e:	00006797          	auipc	a5,0x6
    80002432:	4627a783          	lw	a5,1122(a5) # 80008890 <ticks>
    80002436:	16f9a823          	sw	a5,368(s3)
	release(&wait_lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	84a080e7          	jalr	-1974(ra) # 80000c86 <release>
	sched();
    80002444:	00000097          	auipc	ra,0x0
    80002448:	cf0080e7          	jalr	-784(ra) # 80002134 <sched>
	panic("zombie exit");
    8000244c:	00006517          	auipc	a0,0x6
    80002450:	e2450513          	addi	a0,a0,-476 # 80008270 <digits+0x230>
    80002454:	ffffe097          	auipc	ra,0xffffe
    80002458:	0e8080e7          	jalr	232(ra) # 8000053c <panic>

000000008000245c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	1800                	addi	s0,sp,48
    8000246a:	892a                	mv	s2,a0
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    8000246c:	0000f497          	auipc	s1,0xf
    80002470:	76448493          	addi	s1,s1,1892 # 80011bd0 <proc>
    80002474:	00016997          	auipc	s3,0x16
    80002478:	75c98993          	addi	s3,s3,1884 # 80018bd0 <tickslock>
	{
		acquire(&p->lock);
    8000247c:	8526                	mv	a0,s1
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	754080e7          	jalr	1876(ra) # 80000bd2 <acquire>
		if(p->pid == pid)
    80002486:	589c                	lw	a5,48(s1)
    80002488:	01278d63          	beq	a5,s2,800024a2 <kill+0x46>
        #endif
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    8000248c:	8526                	mv	a0,s1
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	7f8080e7          	jalr	2040(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    80002496:	1c048493          	addi	s1,s1,448
    8000249a:	ff3491e3          	bne	s1,s3,8000247c <kill+0x20>
	}
	return -1;
    8000249e:	557d                	li	a0,-1
    800024a0:	a829                	j	800024ba <kill+0x5e>
			p->killed = 1;
    800024a2:	4785                	li	a5,1
    800024a4:	d49c                	sw	a5,40(s1)
			if(p->state == SLEEPING)
    800024a6:	4c98                	lw	a4,24(s1)
    800024a8:	4789                	li	a5,2
    800024aa:	00f70f63          	beq	a4,a5,800024c8 <kill+0x6c>
			release(&p->lock);
    800024ae:	8526                	mv	a0,s1
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	7d6080e7          	jalr	2006(ra) # 80000c86 <release>
			return 0;
    800024b8:	4501                	li	a0,0
}
    800024ba:	70a2                	ld	ra,40(sp)
    800024bc:	7402                	ld	s0,32(sp)
    800024be:	64e2                	ld	s1,24(sp)
    800024c0:	6942                	ld	s2,16(sp)
    800024c2:	69a2                	ld	s3,8(sp)
    800024c4:	6145                	addi	sp,sp,48
    800024c6:	8082                	ret
				p->state = RUNNABLE;
    800024c8:	478d                	li	a5,3
    800024ca:	cc9c                	sw	a5,24(s1)
    800024cc:	b7cd                	j	800024ae <kill+0x52>

00000000800024ce <setkilled>:

void setkilled(struct proc* p)
{
    800024ce:	1101                	addi	sp,sp,-32
    800024d0:	ec06                	sd	ra,24(sp)
    800024d2:	e822                	sd	s0,16(sp)
    800024d4:	e426                	sd	s1,8(sp)
    800024d6:	1000                	addi	s0,sp,32
    800024d8:	84aa                	mv	s1,a0
	acquire(&p->lock);
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	6f8080e7          	jalr	1784(ra) # 80000bd2 <acquire>
	p->killed = 1;
    800024e2:	4785                	li	a5,1
    800024e4:	d49c                	sw	a5,40(s1)
	release(&p->lock);
    800024e6:	8526                	mv	a0,s1
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	79e080e7          	jalr	1950(ra) # 80000c86 <release>
}
    800024f0:	60e2                	ld	ra,24(sp)
    800024f2:	6442                	ld	s0,16(sp)
    800024f4:	64a2                	ld	s1,8(sp)
    800024f6:	6105                	addi	sp,sp,32
    800024f8:	8082                	ret

00000000800024fa <killed>:

int killed(struct proc* p)
{
    800024fa:	1101                	addi	sp,sp,-32
    800024fc:	ec06                	sd	ra,24(sp)
    800024fe:	e822                	sd	s0,16(sp)
    80002500:	e426                	sd	s1,8(sp)
    80002502:	e04a                	sd	s2,0(sp)
    80002504:	1000                	addi	s0,sp,32
    80002506:	84aa                	mv	s1,a0
	int k;

	acquire(&p->lock);
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	6ca080e7          	jalr	1738(ra) # 80000bd2 <acquire>
	k = p->killed;
    80002510:	0284a903          	lw	s2,40(s1)
	release(&p->lock);
    80002514:	8526                	mv	a0,s1
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	770080e7          	jalr	1904(ra) # 80000c86 <release>
	return k;
}
    8000251e:	854a                	mv	a0,s2
    80002520:	60e2                	ld	ra,24(sp)
    80002522:	6442                	ld	s0,16(sp)
    80002524:	64a2                	ld	s1,8(sp)
    80002526:	6902                	ld	s2,0(sp)
    80002528:	6105                	addi	sp,sp,32
    8000252a:	8082                	ret

000000008000252c <wait>:
{
    8000252c:	715d                	addi	sp,sp,-80
    8000252e:	e486                	sd	ra,72(sp)
    80002530:	e0a2                	sd	s0,64(sp)
    80002532:	fc26                	sd	s1,56(sp)
    80002534:	f84a                	sd	s2,48(sp)
    80002536:	f44e                	sd	s3,40(sp)
    80002538:	f052                	sd	s4,32(sp)
    8000253a:	ec56                	sd	s5,24(sp)
    8000253c:	e85a                	sd	s6,16(sp)
    8000253e:	e45e                	sd	s7,8(sp)
    80002540:	e062                	sd	s8,0(sp)
    80002542:	0880                	addi	s0,sp,80
    80002544:	8b2a                	mv	s6,a0
	struct proc* p = myproc();
    80002546:	fffff097          	auipc	ra,0xfffff
    8000254a:	460080e7          	jalr	1120(ra) # 800019a6 <myproc>
    8000254e:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002550:	0000e517          	auipc	a0,0xe
    80002554:	5c850513          	addi	a0,a0,1480 # 80010b18 <wait_lock>
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	67a080e7          	jalr	1658(ra) # 80000bd2 <acquire>
		havekids = 0;
    80002560:	4b81                	li	s7,0
				if(pp->state == ZOMBIE)
    80002562:	4a15                	li	s4,5
				havekids = 1;
    80002564:	4a85                	li	s5,1
		for(pp = proc; pp < &proc[NPROC]; pp++)
    80002566:	00016997          	auipc	s3,0x16
    8000256a:	66a98993          	addi	s3,s3,1642 # 80018bd0 <tickslock>
		sleep(p, &wait_lock); // DOC: wait-sleep
    8000256e:	0000ec17          	auipc	s8,0xe
    80002572:	5aac0c13          	addi	s8,s8,1450 # 80010b18 <wait_lock>
    80002576:	a0d1                	j	8000263a <wait+0x10e>
					pid = pp->pid;
    80002578:	0304a983          	lw	s3,48(s1)
					if(addr != 0 &&
    8000257c:	000b0e63          	beqz	s6,80002598 <wait+0x6c>
					   copyout(p->pagetable, addr, (char*)&pp->xstate, sizeof(pp->xstate)) < 0)
    80002580:	4691                	li	a3,4
    80002582:	02c48613          	addi	a2,s1,44
    80002586:	85da                	mv	a1,s6
    80002588:	05093503          	ld	a0,80(s2)
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	0da080e7          	jalr	218(ra) # 80001666 <copyout>
					if(addr != 0 &&
    80002594:	04054163          	bltz	a0,800025d6 <wait+0xaa>
					freeproc(pp);
    80002598:	8526                	mv	a0,s1
    8000259a:	fffff097          	auipc	ra,0xfffff
    8000259e:	6d0080e7          	jalr	1744(ra) # 80001c6a <freeproc>
					release(&pp->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	6e2080e7          	jalr	1762(ra) # 80000c86 <release>
					release(&wait_lock);
    800025ac:	0000e517          	auipc	a0,0xe
    800025b0:	56c50513          	addi	a0,a0,1388 # 80010b18 <wait_lock>
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	6d2080e7          	jalr	1746(ra) # 80000c86 <release>
}
    800025bc:	854e                	mv	a0,s3
    800025be:	60a6                	ld	ra,72(sp)
    800025c0:	6406                	ld	s0,64(sp)
    800025c2:	74e2                	ld	s1,56(sp)
    800025c4:	7942                	ld	s2,48(sp)
    800025c6:	79a2                	ld	s3,40(sp)
    800025c8:	7a02                	ld	s4,32(sp)
    800025ca:	6ae2                	ld	s5,24(sp)
    800025cc:	6b42                	ld	s6,16(sp)
    800025ce:	6ba2                	ld	s7,8(sp)
    800025d0:	6c02                	ld	s8,0(sp)
    800025d2:	6161                	addi	sp,sp,80
    800025d4:	8082                	ret
						release(&pp->lock);
    800025d6:	8526                	mv	a0,s1
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	6ae080e7          	jalr	1710(ra) # 80000c86 <release>
						release(&wait_lock);
    800025e0:	0000e517          	auipc	a0,0xe
    800025e4:	53850513          	addi	a0,a0,1336 # 80010b18 <wait_lock>
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	69e080e7          	jalr	1694(ra) # 80000c86 <release>
						return -1;
    800025f0:	59fd                	li	s3,-1
    800025f2:	b7e9                	j	800025bc <wait+0x90>
		for(pp = proc; pp < &proc[NPROC]; pp++)
    800025f4:	1c048493          	addi	s1,s1,448
    800025f8:	03348463          	beq	s1,s3,80002620 <wait+0xf4>
			if(pp->parent == p)
    800025fc:	7c9c                	ld	a5,56(s1)
    800025fe:	ff279be3          	bne	a5,s2,800025f4 <wait+0xc8>
				acquire(&pp->lock);
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	5ce080e7          	jalr	1486(ra) # 80000bd2 <acquire>
				if(pp->state == ZOMBIE)
    8000260c:	4c9c                	lw	a5,24(s1)
    8000260e:	f74785e3          	beq	a5,s4,80002578 <wait+0x4c>
				release(&pp->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	672080e7          	jalr	1650(ra) # 80000c86 <release>
				havekids = 1;
    8000261c:	8756                	mv	a4,s5
    8000261e:	bfd9                	j	800025f4 <wait+0xc8>
		if(!havekids || killed(p))
    80002620:	c31d                	beqz	a4,80002646 <wait+0x11a>
    80002622:	854a                	mv	a0,s2
    80002624:	00000097          	auipc	ra,0x0
    80002628:	ed6080e7          	jalr	-298(ra) # 800024fa <killed>
    8000262c:	ed09                	bnez	a0,80002646 <wait+0x11a>
		sleep(p, &wait_lock); // DOC: wait-sleep
    8000262e:	85e2                	mv	a1,s8
    80002630:	854a                	mv	a0,s2
    80002632:	00000097          	auipc	ra,0x0
    80002636:	c14080e7          	jalr	-1004(ra) # 80002246 <sleep>
		havekids = 0;
    8000263a:	875e                	mv	a4,s7
		for(pp = proc; pp < &proc[NPROC]; pp++)
    8000263c:	0000f497          	auipc	s1,0xf
    80002640:	59448493          	addi	s1,s1,1428 # 80011bd0 <proc>
    80002644:	bf65                	j	800025fc <wait+0xd0>
			release(&wait_lock);
    80002646:	0000e517          	auipc	a0,0xe
    8000264a:	4d250513          	addi	a0,a0,1234 # 80010b18 <wait_lock>
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	638080e7          	jalr	1592(ra) # 80000c86 <release>
			return -1;
    80002656:	59fd                	li	s3,-1
    80002658:	b795                	j	800025bc <wait+0x90>

000000008000265a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void* src, uint64 len)
{
    8000265a:	7179                	addi	sp,sp,-48
    8000265c:	f406                	sd	ra,40(sp)
    8000265e:	f022                	sd	s0,32(sp)
    80002660:	ec26                	sd	s1,24(sp)
    80002662:	e84a                	sd	s2,16(sp)
    80002664:	e44e                	sd	s3,8(sp)
    80002666:	e052                	sd	s4,0(sp)
    80002668:	1800                	addi	s0,sp,48
    8000266a:	84aa                	mv	s1,a0
    8000266c:	892e                	mv	s2,a1
    8000266e:	89b2                	mv	s3,a2
    80002670:	8a36                	mv	s4,a3
	struct proc* p = myproc();
    80002672:	fffff097          	auipc	ra,0xfffff
    80002676:	334080e7          	jalr	820(ra) # 800019a6 <myproc>
	if(user_dst)
    8000267a:	c08d                	beqz	s1,8000269c <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    8000267c:	86d2                	mv	a3,s4
    8000267e:	864e                	mv	a2,s3
    80002680:	85ca                	mv	a1,s2
    80002682:	6928                	ld	a0,80(a0)
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	fe2080e7          	jalr	-30(ra) # 80001666 <copyout>
	else
	{
		memmove((char*)dst, src, len);
		return 0;
	}
}
    8000268c:	70a2                	ld	ra,40(sp)
    8000268e:	7402                	ld	s0,32(sp)
    80002690:	64e2                	ld	s1,24(sp)
    80002692:	6942                	ld	s2,16(sp)
    80002694:	69a2                	ld	s3,8(sp)
    80002696:	6a02                	ld	s4,0(sp)
    80002698:	6145                	addi	sp,sp,48
    8000269a:	8082                	ret
		memmove((char*)dst, src, len);
    8000269c:	000a061b          	sext.w	a2,s4
    800026a0:	85ce                	mv	a1,s3
    800026a2:	854a                	mv	a0,s2
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	686080e7          	jalr	1670(ra) # 80000d2a <memmove>
		return 0;
    800026ac:	8526                	mv	a0,s1
    800026ae:	bff9                	j	8000268c <either_copyout+0x32>

00000000800026b0 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void* dst, int user_src, uint64 src, uint64 len)
{
    800026b0:	7179                	addi	sp,sp,-48
    800026b2:	f406                	sd	ra,40(sp)
    800026b4:	f022                	sd	s0,32(sp)
    800026b6:	ec26                	sd	s1,24(sp)
    800026b8:	e84a                	sd	s2,16(sp)
    800026ba:	e44e                	sd	s3,8(sp)
    800026bc:	e052                	sd	s4,0(sp)
    800026be:	1800                	addi	s0,sp,48
    800026c0:	892a                	mv	s2,a0
    800026c2:	84ae                	mv	s1,a1
    800026c4:	89b2                	mv	s3,a2
    800026c6:	8a36                	mv	s4,a3
	struct proc* p = myproc();
    800026c8:	fffff097          	auipc	ra,0xfffff
    800026cc:	2de080e7          	jalr	734(ra) # 800019a6 <myproc>
	if(user_src)
    800026d0:	c08d                	beqz	s1,800026f2 <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    800026d2:	86d2                	mv	a3,s4
    800026d4:	864e                	mv	a2,s3
    800026d6:	85ca                	mv	a1,s2
    800026d8:	6928                	ld	a0,80(a0)
    800026da:	fffff097          	auipc	ra,0xfffff
    800026de:	018080e7          	jalr	24(ra) # 800016f2 <copyin>
	else
	{
		memmove(dst, (char*)src, len);
		return 0;
	}
}
    800026e2:	70a2                	ld	ra,40(sp)
    800026e4:	7402                	ld	s0,32(sp)
    800026e6:	64e2                	ld	s1,24(sp)
    800026e8:	6942                	ld	s2,16(sp)
    800026ea:	69a2                	ld	s3,8(sp)
    800026ec:	6a02                	ld	s4,0(sp)
    800026ee:	6145                	addi	sp,sp,48
    800026f0:	8082                	ret
		memmove(dst, (char*)src, len);
    800026f2:	000a061b          	sext.w	a2,s4
    800026f6:	85ce                	mv	a1,s3
    800026f8:	854a                	mv	a0,s2
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	630080e7          	jalr	1584(ra) # 80000d2a <memmove>
		return 0;
    80002702:	8526                	mv	a0,s1
    80002704:	bff9                	j	800026e2 <either_copyin+0x32>

0000000080002706 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002706:	7179                	addi	sp,sp,-48
    80002708:	f406                	sd	ra,40(sp)
    8000270a:	f022                	sd	s0,32(sp)
    8000270c:	ec26                	sd	s1,24(sp)
    8000270e:	e84a                	sd	s2,16(sp)
    80002710:	e44e                	sd	s3,8(sp)
    80002712:	1800                	addi	s0,sp,48
	
	struct proc* p;
	

	printf("\n");
    80002714:	00006517          	auipc	a0,0x6
    80002718:	9b450513          	addi	a0,a0,-1612 # 800080c8 <digits+0x88>
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	e6a080e7          	jalr	-406(ra) # 80000586 <printf>
	for(p = proc; p < &proc[NPROC]; p++)
    80002724:	0000f497          	auipc	s1,0xf
    80002728:	4ac48493          	addi	s1,s1,1196 # 80011bd0 <proc>
			continue;
		
		#ifdef MLFQ
		#endif
		
		printf("\n");
    8000272c:	00006997          	auipc	s3,0x6
    80002730:	99c98993          	addi	s3,s3,-1636 # 800080c8 <digits+0x88>
	for(p = proc; p < &proc[NPROC]; p++)
    80002734:	00016917          	auipc	s2,0x16
    80002738:	49c90913          	addi	s2,s2,1180 # 80018bd0 <tickslock>
    8000273c:	a029                	j	80002746 <procdump+0x40>
    8000273e:	1c048493          	addi	s1,s1,448
    80002742:	01248a63          	beq	s1,s2,80002756 <procdump+0x50>
		if(p->state == UNUSED)
    80002746:	4c9c                	lw	a5,24(s1)
    80002748:	dbfd                	beqz	a5,8000273e <procdump+0x38>
		printf("\n");
    8000274a:	854e                	mv	a0,s3
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	e3a080e7          	jalr	-454(ra) # 80000586 <printf>
    80002754:	b7ed                	j	8000273e <procdump+0x38>
	}	
}
    80002756:	70a2                	ld	ra,40(sp)
    80002758:	7402                	ld	s0,32(sp)
    8000275a:	64e2                	ld	s1,24(sp)
    8000275c:	6942                	ld	s2,16(sp)
    8000275e:	69a2                	ld	s3,8(sp)
    80002760:	6145                	addi	sp,sp,48
    80002762:	8082                	ret

0000000080002764 <waitx>:

// waitx
int waitx(uint64 addr, uint* wtime, uint* rtime)
{
    80002764:	711d                	addi	sp,sp,-96
    80002766:	ec86                	sd	ra,88(sp)
    80002768:	e8a2                	sd	s0,80(sp)
    8000276a:	e4a6                	sd	s1,72(sp)
    8000276c:	e0ca                	sd	s2,64(sp)
    8000276e:	fc4e                	sd	s3,56(sp)
    80002770:	f852                	sd	s4,48(sp)
    80002772:	f456                	sd	s5,40(sp)
    80002774:	f05a                	sd	s6,32(sp)
    80002776:	ec5e                	sd	s7,24(sp)
    80002778:	e862                	sd	s8,16(sp)
    8000277a:	e466                	sd	s9,8(sp)
    8000277c:	e06a                	sd	s10,0(sp)
    8000277e:	1080                	addi	s0,sp,96
    80002780:	8b2a                	mv	s6,a0
    80002782:	8bae                	mv	s7,a1
    80002784:	8c32                	mv	s8,a2
	struct proc* np;
	int havekids, pid;
	struct proc* p = myproc();
    80002786:	fffff097          	auipc	ra,0xfffff
    8000278a:	220080e7          	jalr	544(ra) # 800019a6 <myproc>
    8000278e:	892a                	mv	s2,a0

	acquire(&wait_lock);
    80002790:	0000e517          	auipc	a0,0xe
    80002794:	38850513          	addi	a0,a0,904 # 80010b18 <wait_lock>
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	43a080e7          	jalr	1082(ra) # 80000bd2 <acquire>

	for(;;)
	{
		// Scan through table looking for exited children.
		havekids = 0;
    800027a0:	4c81                	li	s9,0
			{
				// make sure the child isn't still in exit() or swtch().
				acquire(&np->lock);

				havekids = 1;
				if(np->state == ZOMBIE)
    800027a2:	4a15                	li	s4,5
				havekids = 1;
    800027a4:	4a85                	li	s5,1
		for(np = proc; np < &proc[NPROC]; np++)
    800027a6:	00016997          	auipc	s3,0x16
    800027aa:	42a98993          	addi	s3,s3,1066 # 80018bd0 <tickslock>
			release(&wait_lock);
			return -1;
		}

		// Wait for a child to exit.
		sleep(p, &wait_lock); // DOC: wait-sleep
    800027ae:	0000ed17          	auipc	s10,0xe
    800027b2:	36ad0d13          	addi	s10,s10,874 # 80010b18 <wait_lock>
    800027b6:	a8e9                	j	80002890 <waitx+0x12c>
					pid = np->pid;
    800027b8:	0304a983          	lw	s3,48(s1)
					*rtime = np->rtime;
    800027bc:	1684a783          	lw	a5,360(s1)
    800027c0:	00fc2023          	sw	a5,0(s8)
					*wtime = np->etime - np->ctime - np->rtime;
    800027c4:	16c4a703          	lw	a4,364(s1)
    800027c8:	9f3d                	addw	a4,a4,a5
    800027ca:	1704a783          	lw	a5,368(s1)
    800027ce:	9f99                	subw	a5,a5,a4
    800027d0:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffdb050>
					if(addr != 0 &&
    800027d4:	000b0e63          	beqz	s6,800027f0 <waitx+0x8c>
					   copyout(p->pagetable, addr, (char*)&np->xstate, sizeof(np->xstate)) < 0)
    800027d8:	4691                	li	a3,4
    800027da:	02c48613          	addi	a2,s1,44
    800027de:	85da                	mv	a1,s6
    800027e0:	05093503          	ld	a0,80(s2)
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	e82080e7          	jalr	-382(ra) # 80001666 <copyout>
					if(addr != 0 &&
    800027ec:	04054363          	bltz	a0,80002832 <waitx+0xce>
					freeproc(np);
    800027f0:	8526                	mv	a0,s1
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	478080e7          	jalr	1144(ra) # 80001c6a <freeproc>
					release(&np->lock);
    800027fa:	8526                	mv	a0,s1
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	48a080e7          	jalr	1162(ra) # 80000c86 <release>
					release(&wait_lock);
    80002804:	0000e517          	auipc	a0,0xe
    80002808:	31450513          	addi	a0,a0,788 # 80010b18 <wait_lock>
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	47a080e7          	jalr	1146(ra) # 80000c86 <release>
	}
}
    80002814:	854e                	mv	a0,s3
    80002816:	60e6                	ld	ra,88(sp)
    80002818:	6446                	ld	s0,80(sp)
    8000281a:	64a6                	ld	s1,72(sp)
    8000281c:	6906                	ld	s2,64(sp)
    8000281e:	79e2                	ld	s3,56(sp)
    80002820:	7a42                	ld	s4,48(sp)
    80002822:	7aa2                	ld	s5,40(sp)
    80002824:	7b02                	ld	s6,32(sp)
    80002826:	6be2                	ld	s7,24(sp)
    80002828:	6c42                	ld	s8,16(sp)
    8000282a:	6ca2                	ld	s9,8(sp)
    8000282c:	6d02                	ld	s10,0(sp)
    8000282e:	6125                	addi	sp,sp,96
    80002830:	8082                	ret
						release(&np->lock);
    80002832:	8526                	mv	a0,s1
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	452080e7          	jalr	1106(ra) # 80000c86 <release>
						release(&wait_lock);
    8000283c:	0000e517          	auipc	a0,0xe
    80002840:	2dc50513          	addi	a0,a0,732 # 80010b18 <wait_lock>
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	442080e7          	jalr	1090(ra) # 80000c86 <release>
						return -1;
    8000284c:	59fd                	li	s3,-1
    8000284e:	b7d9                	j	80002814 <waitx+0xb0>
		for(np = proc; np < &proc[NPROC]; np++)
    80002850:	1c048493          	addi	s1,s1,448
    80002854:	03348463          	beq	s1,s3,8000287c <waitx+0x118>
			if(np->parent == p)
    80002858:	7c9c                	ld	a5,56(s1)
    8000285a:	ff279be3          	bne	a5,s2,80002850 <waitx+0xec>
				acquire(&np->lock);
    8000285e:	8526                	mv	a0,s1
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	372080e7          	jalr	882(ra) # 80000bd2 <acquire>
				if(np->state == ZOMBIE)
    80002868:	4c9c                	lw	a5,24(s1)
    8000286a:	f54787e3          	beq	a5,s4,800027b8 <waitx+0x54>
				release(&np->lock);
    8000286e:	8526                	mv	a0,s1
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	416080e7          	jalr	1046(ra) # 80000c86 <release>
				havekids = 1;
    80002878:	8756                	mv	a4,s5
    8000287a:	bfd9                	j	80002850 <waitx+0xec>
		if(!havekids || p->killed)
    8000287c:	c305                	beqz	a4,8000289c <waitx+0x138>
    8000287e:	02892783          	lw	a5,40(s2)
    80002882:	ef89                	bnez	a5,8000289c <waitx+0x138>
		sleep(p, &wait_lock); // DOC: wait-sleep
    80002884:	85ea                	mv	a1,s10
    80002886:	854a                	mv	a0,s2
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	9be080e7          	jalr	-1602(ra) # 80002246 <sleep>
		havekids = 0;
    80002890:	8766                	mv	a4,s9
		for(np = proc; np < &proc[NPROC]; np++)
    80002892:	0000f497          	auipc	s1,0xf
    80002896:	33e48493          	addi	s1,s1,830 # 80011bd0 <proc>
    8000289a:	bf7d                	j	80002858 <waitx+0xf4>
			release(&wait_lock);
    8000289c:	0000e517          	auipc	a0,0xe
    800028a0:	27c50513          	addi	a0,a0,636 # 80010b18 <wait_lock>
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	3e2080e7          	jalr	994(ra) # 80000c86 <release>
			return -1;
    800028ac:	59fd                	li	s3,-1
    800028ae:	b79d                	j	80002814 <waitx+0xb0>

00000000800028b0 <update_time>:

void update_time()
{
    800028b0:	7179                	addi	sp,sp,-48
    800028b2:	f406                	sd	ra,40(sp)
    800028b4:	f022                	sd	s0,32(sp)
    800028b6:	ec26                	sd	s1,24(sp)
    800028b8:	e84a                	sd	s2,16(sp)
    800028ba:	e44e                	sd	s3,8(sp)
    800028bc:	1800                	addi	s0,sp,48
	struct proc* p;
	for(p = proc; p < &proc[NPROC]; p++)
    800028be:	0000f497          	auipc	s1,0xf
    800028c2:	31248493          	addi	s1,s1,786 # 80011bd0 <proc>
	{
		acquire(&p->lock);
		if(p->state == RUNNING)
    800028c6:	4991                	li	s3,4
	for(p = proc; p < &proc[NPROC]; p++)
    800028c8:	00016917          	auipc	s2,0x16
    800028cc:	30890913          	addi	s2,s2,776 # 80018bd0 <tickslock>
    800028d0:	a811                	j	800028e4 <update_time+0x34>
		{
			p->rtime++;
		}
		 	release(&p->lock);
    800028d2:	8526                	mv	a0,s1
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	3b2080e7          	jalr	946(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    800028dc:	1c048493          	addi	s1,s1,448
    800028e0:	03248063          	beq	s1,s2,80002900 <update_time+0x50>
		acquire(&p->lock);
    800028e4:	8526                	mv	a0,s1
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	2ec080e7          	jalr	748(ra) # 80000bd2 <acquire>
		if(p->state == RUNNING)
    800028ee:	4c9c                	lw	a5,24(s1)
    800028f0:	ff3791e3          	bne	a5,s3,800028d2 <update_time+0x22>
			p->rtime++;
    800028f4:	1684a783          	lw	a5,360(s1)
    800028f8:	2785                	addiw	a5,a5,1
    800028fa:	16f4a423          	sw	a5,360(s1)
    800028fe:	bfd1                	j	800028d2 <update_time+0x22>
	}
	
}
    80002900:	70a2                	ld	ra,40(sp)
    80002902:	7402                	ld	s0,32(sp)
    80002904:	64e2                	ld	s1,24(sp)
    80002906:	6942                	ld	s2,16(sp)
    80002908:	69a2                	ld	s3,8(sp)
    8000290a:	6145                	addi	sp,sp,48
    8000290c:	8082                	ret

000000008000290e <set_overshot_proc>:

void set_overshot_proc()
{
    8000290e:	1101                	addi	sp,sp,-32
    80002910:	ec06                	sd	ra,24(sp)
    80002912:	e822                	sd	s0,16(sp)
    80002914:	e426                	sd	s1,8(sp)
    80002916:	1000                	addi	s0,sp,32
	struct proc* p = myproc();
    80002918:	fffff097          	auipc	ra,0xfffff
    8000291c:	08e080e7          	jalr	142(ra) # 800019a6 <myproc>
    80002920:	84aa                	mv	s1,a0
	
		acquire(&p->lock);
    80002922:	ffffe097          	auipc	ra,0xffffe
    80002926:	2b0080e7          	jalr	688(ra) # 80000bd2 <acquire>
		
			p->q_leap = 1;
    8000292a:	4785                	li	a5,1
    8000292c:	1af4ac23          	sw	a5,440(s1)
	p->q_run_time = 0;
    80002930:	1a04aa23          	sw	zero,436(s1)
	p->q_wait_time = 0;
    80002934:	1a04a823          	sw	zero,432(s1)
		release(&p->lock);
    80002938:	8526                	mv	a0,s1
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	34c080e7          	jalr	844(ra) # 80000c86 <release>
	
}
    80002942:	60e2                	ld	ra,24(sp)
    80002944:	6442                	ld	s0,16(sp)
    80002946:	64a2                	ld	s1,8(sp)
    80002948:	6105                	addi	sp,sp,32
    8000294a:	8082                	ret

000000008000294c <update_q_time>:

void update_q_time()
{
    8000294c:	7139                	addi	sp,sp,-64
    8000294e:	fc06                	sd	ra,56(sp)
    80002950:	f822                	sd	s0,48(sp)
    80002952:	f426                	sd	s1,40(sp)
    80002954:	f04a                	sd	s2,32(sp)
    80002956:	ec4e                	sd	s3,24(sp)
    80002958:	e852                	sd	s4,16(sp)
    8000295a:	e456                	sd	s5,8(sp)
    8000295c:	0080                	addi	s0,sp,64
	struct proc* p;
	for(p = proc; p < &proc[NPROC]; p++)
    8000295e:	0000f497          	auipc	s1,0xf
    80002962:	27248493          	addi	s1,s1,626 # 80011bd0 <proc>
	{
		acquire(&p->lock);
		if (p->state == RUNNING)
    80002966:	4991                	li	s3,4
		{
			p->q_run_time++;
		}
		else  if(p->state == RUNNABLE)
    80002968:	4a0d                	li	s4,3
		{
			p->q_wait_time++;
		}
		 if (p->state != ZOMBIE)
    8000296a:	4a95                	li	s5,5
	for(p = proc; p < &proc[NPROC]; p++)
    8000296c:	00016917          	auipc	s2,0x16
    80002970:	26490913          	addi	s2,s2,612 # 80018bd0 <tickslock>
    80002974:	a805                	j	800029a4 <update_q_time+0x58>
			p->q_run_time++;
    80002976:	1b44a783          	lw	a5,436(s1)
    8000297a:	2785                	addiw	a5,a5,1
    8000297c:	1af4aa23          	sw	a5,436(s1)
		 {
			 p->time_spent[p->queue_no]++;
    80002980:	1984a783          	lw	a5,408(s1)
    80002984:	078a                	slli	a5,a5,0x2
    80002986:	97a6                	add	a5,a5,s1
    80002988:	19c7a703          	lw	a4,412(a5)
    8000298c:	2705                	addiw	a4,a4,1
    8000298e:	18e7ae23          	sw	a4,412(a5)
		 }
		release(&p->lock);
    80002992:	8526                	mv	a0,s1
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	2f2080e7          	jalr	754(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    8000299c:	1c048493          	addi	s1,s1,448
    800029a0:	03248563          	beq	s1,s2,800029ca <update_q_time+0x7e>
		acquire(&p->lock);
    800029a4:	8526                	mv	a0,s1
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	22c080e7          	jalr	556(ra) # 80000bd2 <acquire>
		if (p->state == RUNNING)
    800029ae:	4c9c                	lw	a5,24(s1)
    800029b0:	fd3783e3          	beq	a5,s3,80002976 <update_q_time+0x2a>
		else  if(p->state == RUNNABLE)
    800029b4:	01478563          	beq	a5,s4,800029be <update_q_time+0x72>
		 if (p->state != ZOMBIE)
    800029b8:	fd578de3          	beq	a5,s5,80002992 <update_q_time+0x46>
    800029bc:	b7d1                	j	80002980 <update_q_time+0x34>
			p->q_wait_time++;
    800029be:	1b04a783          	lw	a5,432(s1)
    800029c2:	2785                	addiw	a5,a5,1
    800029c4:	1af4a823          	sw	a5,432(s1)
    800029c8:	bf65                	j	80002980 <update_q_time+0x34>
	}
    800029ca:	70e2                	ld	ra,56(sp)
    800029cc:	7442                	ld	s0,48(sp)
    800029ce:	74a2                	ld	s1,40(sp)
    800029d0:	7902                	ld	s2,32(sp)
    800029d2:	69e2                	ld	s3,24(sp)
    800029d4:	6a42                	ld	s4,16(sp)
    800029d6:	6aa2                	ld	s5,8(sp)
    800029d8:	6121                	addi	sp,sp,64
    800029da:	8082                	ret

00000000800029dc <swtch>:
    800029dc:	00153023          	sd	ra,0(a0)
    800029e0:	00253423          	sd	sp,8(a0)
    800029e4:	e900                	sd	s0,16(a0)
    800029e6:	ed04                	sd	s1,24(a0)
    800029e8:	03253023          	sd	s2,32(a0)
    800029ec:	03353423          	sd	s3,40(a0)
    800029f0:	03453823          	sd	s4,48(a0)
    800029f4:	03553c23          	sd	s5,56(a0)
    800029f8:	05653023          	sd	s6,64(a0)
    800029fc:	05753423          	sd	s7,72(a0)
    80002a00:	05853823          	sd	s8,80(a0)
    80002a04:	05953c23          	sd	s9,88(a0)
    80002a08:	07a53023          	sd	s10,96(a0)
    80002a0c:	07b53423          	sd	s11,104(a0)
    80002a10:	0005b083          	ld	ra,0(a1)
    80002a14:	0085b103          	ld	sp,8(a1)
    80002a18:	6980                	ld	s0,16(a1)
    80002a1a:	6d84                	ld	s1,24(a1)
    80002a1c:	0205b903          	ld	s2,32(a1)
    80002a20:	0285b983          	ld	s3,40(a1)
    80002a24:	0305ba03          	ld	s4,48(a1)
    80002a28:	0385ba83          	ld	s5,56(a1)
    80002a2c:	0405bb03          	ld	s6,64(a1)
    80002a30:	0485bb83          	ld	s7,72(a1)
    80002a34:	0505bc03          	ld	s8,80(a1)
    80002a38:	0585bc83          	ld	s9,88(a1)
    80002a3c:	0605bd03          	ld	s10,96(a1)
    80002a40:	0685bd83          	ld	s11,104(a1)
    80002a44:	8082                	ret

0000000080002a46 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002a46:	1141                	addi	sp,sp,-16
    80002a48:	e406                	sd	ra,8(sp)
    80002a4a:	e022                	sd	s0,0(sp)
    80002a4c:	0800                	addi	s0,sp,16
	initlock(&tickslock, "time");
    80002a4e:	00006597          	auipc	a1,0x6
    80002a52:	83258593          	addi	a1,a1,-1998 # 80008280 <digits+0x240>
    80002a56:	00016517          	auipc	a0,0x16
    80002a5a:	17a50513          	addi	a0,a0,378 # 80018bd0 <tickslock>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	0e4080e7          	jalr	228(ra) # 80000b42 <initlock>
}
    80002a66:	60a2                	ld	ra,8(sp)
    80002a68:	6402                	ld	s0,0(sp)
    80002a6a:	0141                	addi	sp,sp,16
    80002a6c:	8082                	ret

0000000080002a6e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002a6e:	1141                	addi	sp,sp,-16
    80002a70:	e422                	sd	s0,8(sp)
    80002a72:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a74:	00003797          	auipc	a5,0x3
    80002a78:	5fc78793          	addi	a5,a5,1532 # 80006070 <kernelvec>
    80002a7c:	10579073          	csrw	stvec,a5
	w_stvec((uint64)kernelvec);
}
    80002a80:	6422                	ld	s0,8(sp)
    80002a82:	0141                	addi	sp,sp,16
    80002a84:	8082                	ret

0000000080002a86 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002a86:	1141                	addi	sp,sp,-16
    80002a88:	e406                	sd	ra,8(sp)
    80002a8a:	e022                	sd	s0,0(sp)
    80002a8c:	0800                	addi	s0,sp,16
	struct proc *p = myproc();
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	f18080e7          	jalr	-232(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a9a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a9c:	10079073          	csrw	sstatus,a5
	// kerneltrap() to usertrap(), so turn off interrupts until
	// we're back in user space, where usertrap() is correct.
	intr_off();

	// send syscalls, interrupts, and exceptions to uservec in trampoline.S
	uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002aa0:	00004697          	auipc	a3,0x4
    80002aa4:	56068693          	addi	a3,a3,1376 # 80007000 <_trampoline>
    80002aa8:	00004717          	auipc	a4,0x4
    80002aac:	55870713          	addi	a4,a4,1368 # 80007000 <_trampoline>
    80002ab0:	8f15                	sub	a4,a4,a3
    80002ab2:	040007b7          	lui	a5,0x4000
    80002ab6:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002ab8:	07b2                	slli	a5,a5,0xc
    80002aba:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002abc:	10571073          	csrw	stvec,a4
	w_stvec(trampoline_uservec);

	// set up trapframe values that uservec will need when
	// the process next traps into the kernel.
	p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ac0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ac2:	18002673          	csrr	a2,satp
    80002ac6:	e310                	sd	a2,0(a4)
	p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ac8:	6d30                	ld	a2,88(a0)
    80002aca:	6138                	ld	a4,64(a0)
    80002acc:	6585                	lui	a1,0x1
    80002ace:	972e                	add	a4,a4,a1
    80002ad0:	e618                	sd	a4,8(a2)
	p->trapframe->kernel_trap = (uint64)usertrap;
    80002ad2:	6d38                	ld	a4,88(a0)
    80002ad4:	00000617          	auipc	a2,0x0
    80002ad8:	14260613          	addi	a2,a2,322 # 80002c16 <usertrap>
    80002adc:	eb10                	sd	a2,16(a4)
	p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002ade:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ae0:	8612                	mv	a2,tp
    80002ae2:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae4:	10002773          	csrr	a4,sstatus
	// set up the registers that trampoline.S's sret will use
	// to get to user space.

	// set S Previous Privilege mode to User.
	unsigned long x = r_sstatus();
	x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ae8:	eff77713          	andi	a4,a4,-257
	x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002aec:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af0:	10071073          	csrw	sstatus,a4
	w_sstatus(x);

	// set S Exception Program Counter to the saved user pc.
	w_sepc(p->trapframe->epc);
    80002af4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002af6:	6f18                	ld	a4,24(a4)
    80002af8:	14171073          	csrw	sepc,a4

	// tell trampoline.S the user page table to switch to.
	uint64 satp = MAKE_SATP(p->pagetable);
    80002afc:	6928                	ld	a0,80(a0)
    80002afe:	8131                	srli	a0,a0,0xc

	// jump to userret in trampoline.S at the top of memory, which
	// switches to the user page table, restores user registers,
	// and switches to user mode with sret.
	uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b00:	00004717          	auipc	a4,0x4
    80002b04:	59c70713          	addi	a4,a4,1436 # 8000709c <userret>
    80002b08:	8f15                	sub	a4,a4,a3
    80002b0a:	97ba                	add	a5,a5,a4
	((void (*)(uint64))trampoline_userret)(satp);
    80002b0c:	577d                	li	a4,-1
    80002b0e:	177e                	slli	a4,a4,0x3f
    80002b10:	8d59                	or	a0,a0,a4
    80002b12:	9782                	jalr	a5
}
    80002b14:	60a2                	ld	ra,8(sp)
    80002b16:	6402                	ld	s0,0(sp)
    80002b18:	0141                	addi	sp,sp,16
    80002b1a:	8082                	ret

0000000080002b1c <clockintr>:
	w_sepc(sepc);
	w_sstatus(sstatus);
}

void clockintr()
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	e04a                	sd	s2,0(sp)
    80002b26:	1000                	addi	s0,sp,32
	

	acquire(&tickslock);
    80002b28:	00016917          	auipc	s2,0x16
    80002b2c:	0a890913          	addi	s2,s2,168 # 80018bd0 <tickslock>
    80002b30:	854a                	mv	a0,s2
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	0a0080e7          	jalr	160(ra) # 80000bd2 <acquire>
	ticks++;
    80002b3a:	00006497          	auipc	s1,0x6
    80002b3e:	d5648493          	addi	s1,s1,-682 # 80008890 <ticks>
    80002b42:	409c                	lw	a5,0(s1)
    80002b44:	2785                	addiw	a5,a5,1
    80002b46:	c09c                	sw	a5,0(s1)
	update_time();
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	d68080e7          	jalr	-664(ra) # 800028b0 <update_time>
	//   // {
	//   //   p->wtime++;
	//   // }
	//   release(&p->lock);
	// }
	wakeup(&ticks);
    80002b50:	8526                	mv	a0,s1
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	758080e7          	jalr	1880(ra) # 800022aa <wakeup>
	// procdump();
	release(&tickslock);
    80002b5a:	854a                	mv	a0,s2
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	12a080e7          	jalr	298(ra) # 80000c86 <release>
}
    80002b64:	60e2                	ld	ra,24(sp)
    80002b66:	6442                	ld	s0,16(sp)
    80002b68:	64a2                	ld	s1,8(sp)
    80002b6a:	6902                	ld	s2,0(sp)
    80002b6c:	6105                	addi	sp,sp,32
    80002b6e:	8082                	ret

0000000080002b70 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b70:	142027f3          	csrr	a5,scause

		return 2;
	}
	else
	{
		return 0;
    80002b74:	4501                	li	a0,0
	if ((scause & 0x8000000000000000L) &&
    80002b76:	0807df63          	bgez	a5,80002c14 <devintr+0xa4>
{
    80002b7a:	1101                	addi	sp,sp,-32
    80002b7c:	ec06                	sd	ra,24(sp)
    80002b7e:	e822                	sd	s0,16(sp)
    80002b80:	e426                	sd	s1,8(sp)
    80002b82:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    80002b84:	0ff7f713          	zext.b	a4,a5
	if ((scause & 0x8000000000000000L) &&
    80002b88:	46a5                	li	a3,9
    80002b8a:	00d70d63          	beq	a4,a3,80002ba4 <devintr+0x34>
	else if (scause == 0x8000000000000001L)
    80002b8e:	577d                	li	a4,-1
    80002b90:	177e                	slli	a4,a4,0x3f
    80002b92:	0705                	addi	a4,a4,1
		return 0;
    80002b94:	4501                	li	a0,0
	else if (scause == 0x8000000000000001L)
    80002b96:	04e78e63          	beq	a5,a4,80002bf2 <devintr+0x82>
	}
}
    80002b9a:	60e2                	ld	ra,24(sp)
    80002b9c:	6442                	ld	s0,16(sp)
    80002b9e:	64a2                	ld	s1,8(sp)
    80002ba0:	6105                	addi	sp,sp,32
    80002ba2:	8082                	ret
		int irq = plic_claim();
    80002ba4:	00003097          	auipc	ra,0x3
    80002ba8:	5d4080e7          	jalr	1492(ra) # 80006178 <plic_claim>
    80002bac:	84aa                	mv	s1,a0
		if (irq == UART0_IRQ)
    80002bae:	47a9                	li	a5,10
    80002bb0:	02f50763          	beq	a0,a5,80002bde <devintr+0x6e>
		else if (irq == VIRTIO0_IRQ)
    80002bb4:	4785                	li	a5,1
    80002bb6:	02f50963          	beq	a0,a5,80002be8 <devintr+0x78>
		return 1;
    80002bba:	4505                	li	a0,1
		else if (irq)
    80002bbc:	dcf9                	beqz	s1,80002b9a <devintr+0x2a>
			printf("unexpected interrupt irq=%d\n", irq);
    80002bbe:	85a6                	mv	a1,s1
    80002bc0:	00005517          	auipc	a0,0x5
    80002bc4:	6c850513          	addi	a0,a0,1736 # 80008288 <digits+0x248>
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	9be080e7          	jalr	-1602(ra) # 80000586 <printf>
			plic_complete(irq);
    80002bd0:	8526                	mv	a0,s1
    80002bd2:	00003097          	auipc	ra,0x3
    80002bd6:	5ca080e7          	jalr	1482(ra) # 8000619c <plic_complete>
		return 1;
    80002bda:	4505                	li	a0,1
    80002bdc:	bf7d                	j	80002b9a <devintr+0x2a>
			uartintr();
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	db6080e7          	jalr	-586(ra) # 80000994 <uartintr>
		if (irq)
    80002be6:	b7ed                	j	80002bd0 <devintr+0x60>
			virtio_disk_intr();
    80002be8:	00004097          	auipc	ra,0x4
    80002bec:	a7a080e7          	jalr	-1414(ra) # 80006662 <virtio_disk_intr>
		if (irq)
    80002bf0:	b7c5                	j	80002bd0 <devintr+0x60>
		if (cpuid() == 0)
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	d88080e7          	jalr	-632(ra) # 8000197a <cpuid>
    80002bfa:	c901                	beqz	a0,80002c0a <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bfc:	144027f3          	csrr	a5,sip
		w_sip(r_sip() & ~2);
    80002c00:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c02:	14479073          	csrw	sip,a5
		return 2;
    80002c06:	4509                	li	a0,2
    80002c08:	bf49                	j	80002b9a <devintr+0x2a>
			clockintr();
    80002c0a:	00000097          	auipc	ra,0x0
    80002c0e:	f12080e7          	jalr	-238(ra) # 80002b1c <clockintr>
    80002c12:	b7ed                	j	80002bfc <devintr+0x8c>
}
    80002c14:	8082                	ret

0000000080002c16 <usertrap>:
{
    80002c16:	1101                	addi	sp,sp,-32
    80002c18:	ec06                	sd	ra,24(sp)
    80002c1a:	e822                	sd	s0,16(sp)
    80002c1c:	e426                	sd	s1,8(sp)
    80002c1e:	e04a                	sd	s2,0(sp)
    80002c20:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c22:	100027f3          	csrr	a5,sstatus
	if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c26:	1007f793          	andi	a5,a5,256
    80002c2a:	e3b1                	bnez	a5,80002c6e <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c2c:	00003797          	auipc	a5,0x3
    80002c30:	44478793          	addi	a5,a5,1092 # 80006070 <kernelvec>
    80002c34:	10579073          	csrw	stvec,a5
	struct proc *p = myproc();
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	d6e080e7          	jalr	-658(ra) # 800019a6 <myproc>
    80002c40:	84aa                	mv	s1,a0
	p->trapframe->epc = r_sepc();
    80002c42:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c44:	14102773          	csrr	a4,sepc
    80002c48:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c4a:	14202773          	csrr	a4,scause
	if (r_scause() == 8)
    80002c4e:	47a1                	li	a5,8
    80002c50:	02f70763          	beq	a4,a5,80002c7e <usertrap+0x68>
	else if ((which_dev = devintr()) != 0)
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	f1c080e7          	jalr	-228(ra) # 80002b70 <devintr>
    80002c5c:	892a                	mv	s2,a0
    80002c5e:	c92d                	beqz	a0,80002cd0 <usertrap+0xba>
	if (killed(p))
    80002c60:	8526                	mv	a0,s1
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	898080e7          	jalr	-1896(ra) # 800024fa <killed>
    80002c6a:	c555                	beqz	a0,80002d16 <usertrap+0x100>
    80002c6c:	a045                	j	80002d0c <usertrap+0xf6>
		panic("usertrap: not from user mode");
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	63a50513          	addi	a0,a0,1594 # 800082a8 <digits+0x268>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	8c6080e7          	jalr	-1850(ra) # 8000053c <panic>
		if (killed(p))
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	87c080e7          	jalr	-1924(ra) # 800024fa <killed>
    80002c86:	ed1d                	bnez	a0,80002cc4 <usertrap+0xae>
		p->trapframe->epc += 4;
    80002c88:	6cb8                	ld	a4,88(s1)
    80002c8a:	6f1c                	ld	a5,24(a4)
    80002c8c:	0791                	addi	a5,a5,4
    80002c8e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c98:	10079073          	csrw	sstatus,a5
		syscall();
    80002c9c:	00000097          	auipc	ra,0x0
    80002ca0:	314080e7          	jalr	788(ra) # 80002fb0 <syscall>
	if (killed(p))
    80002ca4:	8526                	mv	a0,s1
    80002ca6:	00000097          	auipc	ra,0x0
    80002caa:	854080e7          	jalr	-1964(ra) # 800024fa <killed>
    80002cae:	ed31                	bnez	a0,80002d0a <usertrap+0xf4>
	usertrapret();
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	dd6080e7          	jalr	-554(ra) # 80002a86 <usertrapret>
}
    80002cb8:	60e2                	ld	ra,24(sp)
    80002cba:	6442                	ld	s0,16(sp)
    80002cbc:	64a2                	ld	s1,8(sp)
    80002cbe:	6902                	ld	s2,0(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret
			exit(-1);
    80002cc4:	557d                	li	a0,-1
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	6b4080e7          	jalr	1716(ra) # 8000237a <exit>
    80002cce:	bf6d                	j	80002c88 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cd0:	142025f3          	csrr	a1,scause
		printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cd4:	5890                	lw	a2,48(s1)
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	5f250513          	addi	a0,a0,1522 # 800082c8 <digits+0x288>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	8a8080e7          	jalr	-1880(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cea:	14302673          	csrr	a2,stval
		printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cee:	00005517          	auipc	a0,0x5
    80002cf2:	60a50513          	addi	a0,a0,1546 # 800082f8 <digits+0x2b8>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	890080e7          	jalr	-1904(ra) # 80000586 <printf>
		setkilled(p);
    80002cfe:	8526                	mv	a0,s1
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	7ce080e7          	jalr	1998(ra) # 800024ce <setkilled>
    80002d08:	bf71                	j	80002ca4 <usertrap+0x8e>
	if (killed(p))
    80002d0a:	4901                	li	s2,0
		exit(-1);
    80002d0c:	557d                	li	a0,-1
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	66c080e7          	jalr	1644(ra) # 8000237a <exit>
	if (which_dev == 2)
    80002d16:	4789                	li	a5,2
    80002d18:	f8f91ce3          	bne	s2,a5,80002cb0 <usertrap+0x9a>
		p->now_ticks+=1 ;
    80002d1c:	1804a783          	lw	a5,384(s1)
    80002d20:	2785                	addiw	a5,a5,1
    80002d22:	0007871b          	sext.w	a4,a5
    80002d26:	18f4a023          	sw	a5,384(s1)
		if( p-> ticks > 0 && p->now_ticks >= p->ticks && !p->is_sigalarm)
    80002d2a:	17c4a783          	lw	a5,380(s1)
    80002d2e:	f8f051e3          	blez	a5,80002cb0 <usertrap+0x9a>
    80002d32:	f6f74fe3          	blt	a4,a5,80002cb0 <usertrap+0x9a>
    80002d36:	1744a783          	lw	a5,372(s1)
    80002d3a:	fbbd                	bnez	a5,80002cb0 <usertrap+0x9a>
			p->now_ticks = 0;
    80002d3c:	1804a023          	sw	zero,384(s1)
			p->is_sigalarm = 1;
    80002d40:	4785                	li	a5,1
    80002d42:	16f4aa23          	sw	a5,372(s1)
			*(p->backup_trapframe) =*( p->trapframe);
    80002d46:	6cb4                	ld	a3,88(s1)
    80002d48:	87b6                	mv	a5,a3
    80002d4a:	1904b703          	ld	a4,400(s1)
    80002d4e:	12068693          	addi	a3,a3,288
    80002d52:	0007b803          	ld	a6,0(a5)
    80002d56:	6788                	ld	a0,8(a5)
    80002d58:	6b8c                	ld	a1,16(a5)
    80002d5a:	6f90                	ld	a2,24(a5)
    80002d5c:	01073023          	sd	a6,0(a4)
    80002d60:	e708                	sd	a0,8(a4)
    80002d62:	eb0c                	sd	a1,16(a4)
    80002d64:	ef10                	sd	a2,24(a4)
    80002d66:	02078793          	addi	a5,a5,32
    80002d6a:	02070713          	addi	a4,a4,32
    80002d6e:	fed792e3          	bne	a5,a3,80002d52 <usertrap+0x13c>
			p->trapframe->epc = p->handler;
    80002d72:	6cbc                	ld	a5,88(s1)
    80002d74:	1884b703          	ld	a4,392(s1)
    80002d78:	ef98                	sd	a4,24(a5)
    80002d7a:	bf1d                	j	80002cb0 <usertrap+0x9a>

0000000080002d7c <kerneltrap>:
{
    80002d7c:	7179                	addi	sp,sp,-48
    80002d7e:	f406                	sd	ra,40(sp)
    80002d80:	f022                	sd	s0,32(sp)
    80002d82:	ec26                	sd	s1,24(sp)
    80002d84:	e84a                	sd	s2,16(sp)
    80002d86:	e44e                	sd	s3,8(sp)
    80002d88:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d8a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d8e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d92:	142029f3          	csrr	s3,scause
	if ((sstatus & SSTATUS_SPP) == 0)
    80002d96:	1004f793          	andi	a5,s1,256
    80002d9a:	c78d                	beqz	a5,80002dc4 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002da0:	8b89                	andi	a5,a5,2
	if (intr_get() != 0)
    80002da2:	eb8d                	bnez	a5,80002dd4 <kerneltrap+0x58>
	if ((which_dev = devintr()) == 0)
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	dcc080e7          	jalr	-564(ra) # 80002b70 <devintr>
    80002dac:	cd05                	beqz	a0,80002de4 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dae:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002db2:	10049073          	csrw	sstatus,s1
}
    80002db6:	70a2                	ld	ra,40(sp)
    80002db8:	7402                	ld	s0,32(sp)
    80002dba:	64e2                	ld	s1,24(sp)
    80002dbc:	6942                	ld	s2,16(sp)
    80002dbe:	69a2                	ld	s3,8(sp)
    80002dc0:	6145                	addi	sp,sp,48
    80002dc2:	8082                	ret
		panic("kerneltrap: not from supervisor mode");
    80002dc4:	00005517          	auipc	a0,0x5
    80002dc8:	55450513          	addi	a0,a0,1364 # 80008318 <digits+0x2d8>
    80002dcc:	ffffd097          	auipc	ra,0xffffd
    80002dd0:	770080e7          	jalr	1904(ra) # 8000053c <panic>
		panic("kerneltrap: interrupts enabled");
    80002dd4:	00005517          	auipc	a0,0x5
    80002dd8:	56c50513          	addi	a0,a0,1388 # 80008340 <digits+0x300>
    80002ddc:	ffffd097          	auipc	ra,0xffffd
    80002de0:	760080e7          	jalr	1888(ra) # 8000053c <panic>
		printf("scause %p\n", scause);
    80002de4:	85ce                	mv	a1,s3
    80002de6:	00005517          	auipc	a0,0x5
    80002dea:	57a50513          	addi	a0,a0,1402 # 80008360 <digits+0x320>
    80002dee:	ffffd097          	auipc	ra,0xffffd
    80002df2:	798080e7          	jalr	1944(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002df6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dfa:	14302673          	csrr	a2,stval
		printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dfe:	00005517          	auipc	a0,0x5
    80002e02:	57250513          	addi	a0,a0,1394 # 80008370 <digits+0x330>
    80002e06:	ffffd097          	auipc	ra,0xffffd
    80002e0a:	780080e7          	jalr	1920(ra) # 80000586 <printf>
		panic("kerneltrap");
    80002e0e:	00005517          	auipc	a0,0x5
    80002e12:	57a50513          	addi	a0,a0,1402 # 80008388 <digits+0x348>
    80002e16:	ffffd097          	auipc	ra,0xffffd
    80002e1a:	726080e7          	jalr	1830(ra) # 8000053c <panic>

0000000080002e1e <sys_getreadcount>:
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}
uint64 sys_getreadcount(void)
{
    80002e1e:	1141                	addi	sp,sp,-16
    80002e20:	e422                	sd	s0,8(sp)
    80002e22:	0800                	addi	s0,sp,16
  return READCOUNT; 
}
    80002e24:	00006517          	auipc	a0,0x6
    80002e28:	a7453503          	ld	a0,-1420(a0) # 80008898 <READCOUNT>
    80002e2c:	6422                	ld	s0,8(sp)
    80002e2e:	0141                	addi	sp,sp,16
    80002e30:	8082                	ret

0000000080002e32 <argraw>:
{
    80002e32:	1101                	addi	sp,sp,-32
    80002e34:	ec06                	sd	ra,24(sp)
    80002e36:	e822                	sd	s0,16(sp)
    80002e38:	e426                	sd	s1,8(sp)
    80002e3a:	1000                	addi	s0,sp,32
    80002e3c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	b68080e7          	jalr	-1176(ra) # 800019a6 <myproc>
  switch (n) {
    80002e46:	4795                	li	a5,5
    80002e48:	0497e163          	bltu	a5,s1,80002e8a <argraw+0x58>
    80002e4c:	048a                	slli	s1,s1,0x2
    80002e4e:	00005717          	auipc	a4,0x5
    80002e52:	57270713          	addi	a4,a4,1394 # 800083c0 <digits+0x380>
    80002e56:	94ba                	add	s1,s1,a4
    80002e58:	409c                	lw	a5,0(s1)
    80002e5a:	97ba                	add	a5,a5,a4
    80002e5c:	8782                	jr	a5
    return p->trapframe->a0;
    80002e5e:	6d3c                	ld	a5,88(a0)
    80002e60:	7ba8                	ld	a0,112(a5)
}
    80002e62:	60e2                	ld	ra,24(sp)
    80002e64:	6442                	ld	s0,16(sp)
    80002e66:	64a2                	ld	s1,8(sp)
    80002e68:	6105                	addi	sp,sp,32
    80002e6a:	8082                	ret
    return p->trapframe->a1;
    80002e6c:	6d3c                	ld	a5,88(a0)
    80002e6e:	7fa8                	ld	a0,120(a5)
    80002e70:	bfcd                	j	80002e62 <argraw+0x30>
    return p->trapframe->a2;
    80002e72:	6d3c                	ld	a5,88(a0)
    80002e74:	63c8                	ld	a0,128(a5)
    80002e76:	b7f5                	j	80002e62 <argraw+0x30>
    return p->trapframe->a3;
    80002e78:	6d3c                	ld	a5,88(a0)
    80002e7a:	67c8                	ld	a0,136(a5)
    80002e7c:	b7dd                	j	80002e62 <argraw+0x30>
    return p->trapframe->a4;
    80002e7e:	6d3c                	ld	a5,88(a0)
    80002e80:	6bc8                	ld	a0,144(a5)
    80002e82:	b7c5                	j	80002e62 <argraw+0x30>
    return p->trapframe->a5;
    80002e84:	6d3c                	ld	a5,88(a0)
    80002e86:	6fc8                	ld	a0,152(a5)
    80002e88:	bfe9                	j	80002e62 <argraw+0x30>
  panic("argraw");
    80002e8a:	00005517          	auipc	a0,0x5
    80002e8e:	50e50513          	addi	a0,a0,1294 # 80008398 <digits+0x358>
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	6aa080e7          	jalr	1706(ra) # 8000053c <panic>

0000000080002e9a <fetchaddr>:
{
    80002e9a:	1101                	addi	sp,sp,-32
    80002e9c:	ec06                	sd	ra,24(sp)
    80002e9e:	e822                	sd	s0,16(sp)
    80002ea0:	e426                	sd	s1,8(sp)
    80002ea2:	e04a                	sd	s2,0(sp)
    80002ea4:	1000                	addi	s0,sp,32
    80002ea6:	84aa                	mv	s1,a0
    80002ea8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	afc080e7          	jalr	-1284(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002eb2:	653c                	ld	a5,72(a0)
    80002eb4:	02f4f863          	bgeu	s1,a5,80002ee4 <fetchaddr+0x4a>
    80002eb8:	00848713          	addi	a4,s1,8
    80002ebc:	02e7e663          	bltu	a5,a4,80002ee8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ec0:	46a1                	li	a3,8
    80002ec2:	8626                	mv	a2,s1
    80002ec4:	85ca                	mv	a1,s2
    80002ec6:	6928                	ld	a0,80(a0)
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	82a080e7          	jalr	-2006(ra) # 800016f2 <copyin>
    80002ed0:	00a03533          	snez	a0,a0
    80002ed4:	40a00533          	neg	a0,a0
}
    80002ed8:	60e2                	ld	ra,24(sp)
    80002eda:	6442                	ld	s0,16(sp)
    80002edc:	64a2                	ld	s1,8(sp)
    80002ede:	6902                	ld	s2,0(sp)
    80002ee0:	6105                	addi	sp,sp,32
    80002ee2:	8082                	ret
    return -1;
    80002ee4:	557d                	li	a0,-1
    80002ee6:	bfcd                	j	80002ed8 <fetchaddr+0x3e>
    80002ee8:	557d                	li	a0,-1
    80002eea:	b7fd                	j	80002ed8 <fetchaddr+0x3e>

0000000080002eec <fetchstr>:
{
    80002eec:	7179                	addi	sp,sp,-48
    80002eee:	f406                	sd	ra,40(sp)
    80002ef0:	f022                	sd	s0,32(sp)
    80002ef2:	ec26                	sd	s1,24(sp)
    80002ef4:	e84a                	sd	s2,16(sp)
    80002ef6:	e44e                	sd	s3,8(sp)
    80002ef8:	1800                	addi	s0,sp,48
    80002efa:	892a                	mv	s2,a0
    80002efc:	84ae                	mv	s1,a1
    80002efe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	aa6080e7          	jalr	-1370(ra) # 800019a6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002f08:	86ce                	mv	a3,s3
    80002f0a:	864a                	mv	a2,s2
    80002f0c:	85a6                	mv	a1,s1
    80002f0e:	6928                	ld	a0,80(a0)
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	870080e7          	jalr	-1936(ra) # 80001780 <copyinstr>
    80002f18:	00054e63          	bltz	a0,80002f34 <fetchstr+0x48>
  return strlen(buf);
    80002f1c:	8526                	mv	a0,s1
    80002f1e:	ffffe097          	auipc	ra,0xffffe
    80002f22:	f2a080e7          	jalr	-214(ra) # 80000e48 <strlen>
}
    80002f26:	70a2                	ld	ra,40(sp)
    80002f28:	7402                	ld	s0,32(sp)
    80002f2a:	64e2                	ld	s1,24(sp)
    80002f2c:	6942                	ld	s2,16(sp)
    80002f2e:	69a2                	ld	s3,8(sp)
    80002f30:	6145                	addi	sp,sp,48
    80002f32:	8082                	ret
    return -1;
    80002f34:	557d                	li	a0,-1
    80002f36:	bfc5                	j	80002f26 <fetchstr+0x3a>

0000000080002f38 <argint>:
{
    80002f38:	1101                	addi	sp,sp,-32
    80002f3a:	ec06                	sd	ra,24(sp)
    80002f3c:	e822                	sd	s0,16(sp)
    80002f3e:	e426                	sd	s1,8(sp)
    80002f40:	1000                	addi	s0,sp,32
    80002f42:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	eee080e7          	jalr	-274(ra) # 80002e32 <argraw>
    80002f4c:	c088                	sw	a0,0(s1)
}
    80002f4e:	60e2                	ld	ra,24(sp)
    80002f50:	6442                	ld	s0,16(sp)
    80002f52:	64a2                	ld	s1,8(sp)
    80002f54:	6105                	addi	sp,sp,32
    80002f56:	8082                	ret

0000000080002f58 <argaddr>:
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	e426                	sd	s1,8(sp)
    80002f60:	1000                	addi	s0,sp,32
    80002f62:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f64:	00000097          	auipc	ra,0x0
    80002f68:	ece080e7          	jalr	-306(ra) # 80002e32 <argraw>
    80002f6c:	e088                	sd	a0,0(s1)
}
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	64a2                	ld	s1,8(sp)
    80002f74:	6105                	addi	sp,sp,32
    80002f76:	8082                	ret

0000000080002f78 <argstr>:
{
    80002f78:	7179                	addi	sp,sp,-48
    80002f7a:	f406                	sd	ra,40(sp)
    80002f7c:	f022                	sd	s0,32(sp)
    80002f7e:	ec26                	sd	s1,24(sp)
    80002f80:	e84a                	sd	s2,16(sp)
    80002f82:	1800                	addi	s0,sp,48
    80002f84:	84ae                	mv	s1,a1
    80002f86:	8932                	mv	s2,a2
  argaddr(n, &addr);
    80002f88:	fd840593          	addi	a1,s0,-40
    80002f8c:	00000097          	auipc	ra,0x0
    80002f90:	fcc080e7          	jalr	-52(ra) # 80002f58 <argaddr>
  return fetchstr(addr, buf, max);
    80002f94:	864a                	mv	a2,s2
    80002f96:	85a6                	mv	a1,s1
    80002f98:	fd843503          	ld	a0,-40(s0)
    80002f9c:	00000097          	auipc	ra,0x0
    80002fa0:	f50080e7          	jalr	-176(ra) # 80002eec <fetchstr>
}
    80002fa4:	70a2                	ld	ra,40(sp)
    80002fa6:	7402                	ld	s0,32(sp)
    80002fa8:	64e2                	ld	s1,24(sp)
    80002faa:	6942                	ld	s2,16(sp)
    80002fac:	6145                	addi	sp,sp,48
    80002fae:	8082                	ret

0000000080002fb0 <syscall>:

};

void
syscall(void)
{
    80002fb0:	1101                	addi	sp,sp,-32
    80002fb2:	ec06                	sd	ra,24(sp)
    80002fb4:	e822                	sd	s0,16(sp)
    80002fb6:	e426                	sd	s1,8(sp)
    80002fb8:	e04a                	sd	s2,0(sp)
    80002fba:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fbc:	fffff097          	auipc	ra,0xfffff
    80002fc0:	9ea080e7          	jalr	-1558(ra) # 800019a6 <myproc>
    80002fc4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fc6:	05853903          	ld	s2,88(a0)
    80002fca:	0a893783          	ld	a5,168(s2)
    80002fce:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fd2:	37fd                	addiw	a5,a5,-1
    80002fd4:	4761                	li	a4,24
    80002fd6:	00f76f63          	bltu	a4,a5,80002ff4 <syscall+0x44>
    80002fda:	00369713          	slli	a4,a3,0x3
    80002fde:	00005797          	auipc	a5,0x5
    80002fe2:	3fa78793          	addi	a5,a5,1018 # 800083d8 <syscalls>
    80002fe6:	97ba                	add	a5,a5,a4
    80002fe8:	639c                	ld	a5,0(a5)
    80002fea:	c789                	beqz	a5,80002ff4 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002fec:	9782                	jalr	a5
    80002fee:	06a93823          	sd	a0,112(s2)
    80002ff2:	a839                	j	80003010 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ff4:	15848613          	addi	a2,s1,344
    80002ff8:	588c                	lw	a1,48(s1)
    80002ffa:	00005517          	auipc	a0,0x5
    80002ffe:	3a650513          	addi	a0,a0,934 # 800083a0 <digits+0x360>
    80003002:	ffffd097          	auipc	ra,0xffffd
    80003006:	584080e7          	jalr	1412(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000300a:	6cbc                	ld	a5,88(s1)
    8000300c:	577d                	li	a4,-1
    8000300e:	fbb8                	sd	a4,112(a5)
  }
}
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	64a2                	ld	s1,8(sp)
    80003016:	6902                	ld	s2,0(sp)
    80003018:	6105                	addi	sp,sp,32
    8000301a:	8082                	ret

000000008000301c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000301c:	1101                	addi	sp,sp,-32
    8000301e:	ec06                	sd	ra,24(sp)
    80003020:	e822                	sd	s0,16(sp)
    80003022:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003024:	fec40593          	addi	a1,s0,-20
    80003028:	4501                	li	a0,0
    8000302a:	00000097          	auipc	ra,0x0
    8000302e:	f0e080e7          	jalr	-242(ra) # 80002f38 <argint>
  exit(n);
    80003032:	fec42503          	lw	a0,-20(s0)
    80003036:	fffff097          	auipc	ra,0xfffff
    8000303a:	344080e7          	jalr	836(ra) # 8000237a <exit>
  return 0; // not reached
}
    8000303e:	4501                	li	a0,0
    80003040:	60e2                	ld	ra,24(sp)
    80003042:	6442                	ld	s0,16(sp)
    80003044:	6105                	addi	sp,sp,32
    80003046:	8082                	ret

0000000080003048 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003048:	1141                	addi	sp,sp,-16
    8000304a:	e406                	sd	ra,8(sp)
    8000304c:	e022                	sd	s0,0(sp)
    8000304e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003050:	fffff097          	auipc	ra,0xfffff
    80003054:	956080e7          	jalr	-1706(ra) # 800019a6 <myproc>
}
    80003058:	5908                	lw	a0,48(a0)
    8000305a:	60a2                	ld	ra,8(sp)
    8000305c:	6402                	ld	s0,0(sp)
    8000305e:	0141                	addi	sp,sp,16
    80003060:	8082                	ret

0000000080003062 <sys_fork>:

uint64
sys_fork(void)
{
    80003062:	1141                	addi	sp,sp,-16
    80003064:	e406                	sd	ra,8(sp)
    80003066:	e022                	sd	s0,0(sp)
    80003068:	0800                	addi	s0,sp,16
  return fork();
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	e8c080e7          	jalr	-372(ra) # 80001ef6 <fork>
}
    80003072:	60a2                	ld	ra,8(sp)
    80003074:	6402                	ld	s0,0(sp)
    80003076:	0141                	addi	sp,sp,16
    80003078:	8082                	ret

000000008000307a <sys_wait>:

uint64
sys_wait(void)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003082:	fe840593          	addi	a1,s0,-24
    80003086:	4501                	li	a0,0
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	ed0080e7          	jalr	-304(ra) # 80002f58 <argaddr>
  return wait(p);
    80003090:	fe843503          	ld	a0,-24(s0)
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	498080e7          	jalr	1176(ra) # 8000252c <wait>
}
    8000309c:	60e2                	ld	ra,24(sp)
    8000309e:	6442                	ld	s0,16(sp)
    800030a0:	6105                	addi	sp,sp,32
    800030a2:	8082                	ret

00000000800030a4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030a4:	7179                	addi	sp,sp,-48
    800030a6:	f406                	sd	ra,40(sp)
    800030a8:	f022                	sd	s0,32(sp)
    800030aa:	ec26                	sd	s1,24(sp)
    800030ac:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800030ae:	fdc40593          	addi	a1,s0,-36
    800030b2:	4501                	li	a0,0
    800030b4:	00000097          	auipc	ra,0x0
    800030b8:	e84080e7          	jalr	-380(ra) # 80002f38 <argint>
  addr = myproc()->sz;
    800030bc:	fffff097          	auipc	ra,0xfffff
    800030c0:	8ea080e7          	jalr	-1814(ra) # 800019a6 <myproc>
    800030c4:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800030c6:	fdc42503          	lw	a0,-36(s0)
    800030ca:	fffff097          	auipc	ra,0xfffff
    800030ce:	dd0080e7          	jalr	-560(ra) # 80001e9a <growproc>
    800030d2:	00054863          	bltz	a0,800030e2 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030d6:	8526                	mv	a0,s1
    800030d8:	70a2                	ld	ra,40(sp)
    800030da:	7402                	ld	s0,32(sp)
    800030dc:	64e2                	ld	s1,24(sp)
    800030de:	6145                	addi	sp,sp,48
    800030e0:	8082                	ret
    return -1;
    800030e2:	54fd                	li	s1,-1
    800030e4:	bfcd                	j	800030d6 <sys_sbrk+0x32>

00000000800030e6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030e6:	7139                	addi	sp,sp,-64
    800030e8:	fc06                	sd	ra,56(sp)
    800030ea:	f822                	sd	s0,48(sp)
    800030ec:	f426                	sd	s1,40(sp)
    800030ee:	f04a                	sd	s2,32(sp)
    800030f0:	ec4e                	sd	s3,24(sp)
    800030f2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800030f4:	fcc40593          	addi	a1,s0,-52
    800030f8:	4501                	li	a0,0
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	e3e080e7          	jalr	-450(ra) # 80002f38 <argint>
  acquire(&tickslock);
    80003102:	00016517          	auipc	a0,0x16
    80003106:	ace50513          	addi	a0,a0,-1330 # 80018bd0 <tickslock>
    8000310a:	ffffe097          	auipc	ra,0xffffe
    8000310e:	ac8080e7          	jalr	-1336(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80003112:	00005917          	auipc	s2,0x5
    80003116:	77e92903          	lw	s2,1918(s2) # 80008890 <ticks>
  while (ticks - ticks0 < n)
    8000311a:	fcc42783          	lw	a5,-52(s0)
    8000311e:	cf9d                	beqz	a5,8000315c <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003120:	00016997          	auipc	s3,0x16
    80003124:	ab098993          	addi	s3,s3,-1360 # 80018bd0 <tickslock>
    80003128:	00005497          	auipc	s1,0x5
    8000312c:	76848493          	addi	s1,s1,1896 # 80008890 <ticks>
    if (killed(myproc()))
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	876080e7          	jalr	-1930(ra) # 800019a6 <myproc>
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	3c2080e7          	jalr	962(ra) # 800024fa <killed>
    80003140:	ed15                	bnez	a0,8000317c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003142:	85ce                	mv	a1,s3
    80003144:	8526                	mv	a0,s1
    80003146:	fffff097          	auipc	ra,0xfffff
    8000314a:	100080e7          	jalr	256(ra) # 80002246 <sleep>
  while (ticks - ticks0 < n)
    8000314e:	409c                	lw	a5,0(s1)
    80003150:	412787bb          	subw	a5,a5,s2
    80003154:	fcc42703          	lw	a4,-52(s0)
    80003158:	fce7ece3          	bltu	a5,a4,80003130 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000315c:	00016517          	auipc	a0,0x16
    80003160:	a7450513          	addi	a0,a0,-1420 # 80018bd0 <tickslock>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b22080e7          	jalr	-1246(ra) # 80000c86 <release>
  return 0;
    8000316c:	4501                	li	a0,0
}
    8000316e:	70e2                	ld	ra,56(sp)
    80003170:	7442                	ld	s0,48(sp)
    80003172:	74a2                	ld	s1,40(sp)
    80003174:	7902                	ld	s2,32(sp)
    80003176:	69e2                	ld	s3,24(sp)
    80003178:	6121                	addi	sp,sp,64
    8000317a:	8082                	ret
      release(&tickslock);
    8000317c:	00016517          	auipc	a0,0x16
    80003180:	a5450513          	addi	a0,a0,-1452 # 80018bd0 <tickslock>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	b02080e7          	jalr	-1278(ra) # 80000c86 <release>
      return -1;
    8000318c:	557d                	li	a0,-1
    8000318e:	b7c5                	j	8000316e <sys_sleep+0x88>

0000000080003190 <sys_kill>:

uint64
sys_kill(void)
{
    80003190:	1101                	addi	sp,sp,-32
    80003192:	ec06                	sd	ra,24(sp)
    80003194:	e822                	sd	s0,16(sp)
    80003196:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003198:	fec40593          	addi	a1,s0,-20
    8000319c:	4501                	li	a0,0
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	d9a080e7          	jalr	-614(ra) # 80002f38 <argint>
  return kill(pid);
    800031a6:	fec42503          	lw	a0,-20(s0)
    800031aa:	fffff097          	auipc	ra,0xfffff
    800031ae:	2b2080e7          	jalr	690(ra) # 8000245c <kill>
}
    800031b2:	60e2                	ld	ra,24(sp)
    800031b4:	6442                	ld	s0,16(sp)
    800031b6:	6105                	addi	sp,sp,32
    800031b8:	8082                	ret

00000000800031ba <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031ba:	1101                	addi	sp,sp,-32
    800031bc:	ec06                	sd	ra,24(sp)
    800031be:	e822                	sd	s0,16(sp)
    800031c0:	e426                	sd	s1,8(sp)
    800031c2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031c4:	00016517          	auipc	a0,0x16
    800031c8:	a0c50513          	addi	a0,a0,-1524 # 80018bd0 <tickslock>
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	a06080e7          	jalr	-1530(ra) # 80000bd2 <acquire>
  xticks = ticks;
    800031d4:	00005497          	auipc	s1,0x5
    800031d8:	6bc4a483          	lw	s1,1724(s1) # 80008890 <ticks>
  release(&tickslock);
    800031dc:	00016517          	auipc	a0,0x16
    800031e0:	9f450513          	addi	a0,a0,-1548 # 80018bd0 <tickslock>
    800031e4:	ffffe097          	auipc	ra,0xffffe
    800031e8:	aa2080e7          	jalr	-1374(ra) # 80000c86 <release>
  return xticks;
}
    800031ec:	02049513          	slli	a0,s1,0x20
    800031f0:	9101                	srli	a0,a0,0x20
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6105                	addi	sp,sp,32
    800031fa:	8082                	ret

00000000800031fc <sys_waitx>:

uint64
sys_waitx(void)
{
    800031fc:	7139                	addi	sp,sp,-64
    800031fe:	fc06                	sd	ra,56(sp)
    80003200:	f822                	sd	s0,48(sp)
    80003202:	f426                	sd	s1,40(sp)
    80003204:	f04a                	sd	s2,32(sp)
    80003206:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003208:	fd840593          	addi	a1,s0,-40
    8000320c:	4501                	li	a0,0
    8000320e:	00000097          	auipc	ra,0x0
    80003212:	d4a080e7          	jalr	-694(ra) # 80002f58 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003216:	fd040593          	addi	a1,s0,-48
    8000321a:	4505                	li	a0,1
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	d3c080e7          	jalr	-708(ra) # 80002f58 <argaddr>
  argaddr(2, &addr2);
    80003224:	fc840593          	addi	a1,s0,-56
    80003228:	4509                	li	a0,2
    8000322a:	00000097          	auipc	ra,0x0
    8000322e:	d2e080e7          	jalr	-722(ra) # 80002f58 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003232:	fc040613          	addi	a2,s0,-64
    80003236:	fc440593          	addi	a1,s0,-60
    8000323a:	fd843503          	ld	a0,-40(s0)
    8000323e:	fffff097          	auipc	ra,0xfffff
    80003242:	526080e7          	jalr	1318(ra) # 80002764 <waitx>
    80003246:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	75e080e7          	jalr	1886(ra) # 800019a6 <myproc>
    80003250:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003252:	4691                	li	a3,4
    80003254:	fc440613          	addi	a2,s0,-60
    80003258:	fd043583          	ld	a1,-48(s0)
    8000325c:	6928                	ld	a0,80(a0)
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	408080e7          	jalr	1032(ra) # 80001666 <copyout>
    return -1;
    80003266:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003268:	00054f63          	bltz	a0,80003286 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000326c:	4691                	li	a3,4
    8000326e:	fc040613          	addi	a2,s0,-64
    80003272:	fc843583          	ld	a1,-56(s0)
    80003276:	68a8                	ld	a0,80(s1)
    80003278:	ffffe097          	auipc	ra,0xffffe
    8000327c:	3ee080e7          	jalr	1006(ra) # 80001666 <copyout>
    80003280:	00054a63          	bltz	a0,80003294 <sys_waitx+0x98>
    return -1;
  return ret;
    80003284:	87ca                	mv	a5,s2
}
    80003286:	853e                	mv	a0,a5
    80003288:	70e2                	ld	ra,56(sp)
    8000328a:	7442                	ld	s0,48(sp)
    8000328c:	74a2                	ld	s1,40(sp)
    8000328e:	7902                	ld	s2,32(sp)
    80003290:	6121                	addi	sp,sp,64
    80003292:	8082                	ret
    return -1;
    80003294:	57fd                	li	a5,-1
    80003296:	bfc5                	j	80003286 <sys_waitx+0x8a>

0000000080003298 <restore>:
void restore(){
    80003298:	1141                	addi	sp,sp,-16
    8000329a:	e406                	sd	ra,8(sp)
    8000329c:	e022                	sd	s0,0(sp)
    8000329e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800032a0:	ffffe097          	auipc	ra,0xffffe
    800032a4:	706080e7          	jalr	1798(ra) # 800019a6 <myproc>
  p->backup_trapframe->kernel_hartid = p->trapframe->kernel_hartid;
    800032a8:	19053783          	ld	a5,400(a0)
    800032ac:	6d38                	ld	a4,88(a0)
    800032ae:	7318                	ld	a4,32(a4)
    800032b0:	f398                	sd	a4,32(a5)
  p->backup_trapframe->kernel_satp = p->trapframe->kernel_satp;
    800032b2:	19053783          	ld	a5,400(a0)
    800032b6:	6d38                	ld	a4,88(a0)
    800032b8:	6318                	ld	a4,0(a4)
    800032ba:	e398                	sd	a4,0(a5)
  p->backup_trapframe->kernel_sp = p->trapframe->kernel_sp;
    800032bc:	19053783          	ld	a5,400(a0)
    800032c0:	6d38                	ld	a4,88(a0)
    800032c2:	6718                	ld	a4,8(a4)
    800032c4:	e798                	sd	a4,8(a5)
  p->backup_trapframe->kernel_trap = p->trapframe->kernel_trap;
    800032c6:	19053783          	ld	a5,400(a0)
    800032ca:	6d38                	ld	a4,88(a0)
    800032cc:	6b18                	ld	a4,16(a4)
    800032ce:	eb98                	sd	a4,16(a5)
  *(p->trapframe) = *(p->backup_trapframe);
    800032d0:	19053683          	ld	a3,400(a0)
    800032d4:	87b6                	mv	a5,a3
    800032d6:	6d38                	ld	a4,88(a0)
    800032d8:	12068693          	addi	a3,a3,288
    800032dc:	0007b803          	ld	a6,0(a5)
    800032e0:	6788                	ld	a0,8(a5)
    800032e2:	6b8c                	ld	a1,16(a5)
    800032e4:	6f90                	ld	a2,24(a5)
    800032e6:	01073023          	sd	a6,0(a4)
    800032ea:	e708                	sd	a0,8(a4)
    800032ec:	eb0c                	sd	a1,16(a4)
    800032ee:	ef10                	sd	a2,24(a4)
    800032f0:	02078793          	addi	a5,a5,32
    800032f4:	02070713          	addi	a4,a4,32
    800032f8:	fed792e3          	bne	a5,a3,800032dc <restore+0x44>
} 
    800032fc:	60a2                	ld	ra,8(sp)
    800032fe:	6402                	ld	s0,0(sp)
    80003300:	0141                	addi	sp,sp,16
    80003302:	8082                	ret

0000000080003304 <sys_sigreturn>:
uint64 sys_sigreturn(void){
    80003304:	1141                	addi	sp,sp,-16
    80003306:	e406                	sd	ra,8(sp)
    80003308:	e022                	sd	s0,0(sp)
    8000330a:	0800                	addi	s0,sp,16
  restore();
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	f8c080e7          	jalr	-116(ra) # 80003298 <restore>
  myproc()->is_sigalarm = 0;
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	692080e7          	jalr	1682(ra) # 800019a6 <myproc>
    8000331c:	16052a23          	sw	zero,372(a0)
  return myproc()->trapframe->a0;
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	686080e7          	jalr	1670(ra) # 800019a6 <myproc>
    80003328:	6d3c                	ld	a5,88(a0)
    8000332a:	7ba8                	ld	a0,112(a5)
    8000332c:	60a2                	ld	ra,8(sp)
    8000332e:	6402                	ld	s0,0(sp)
    80003330:	0141                	addi	sp,sp,16
    80003332:	8082                	ret

0000000080003334 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003334:	7179                	addi	sp,sp,-48
    80003336:	f406                	sd	ra,40(sp)
    80003338:	f022                	sd	s0,32(sp)
    8000333a:	ec26                	sd	s1,24(sp)
    8000333c:	e84a                	sd	s2,16(sp)
    8000333e:	e44e                	sd	s3,8(sp)
    80003340:	e052                	sd	s4,0(sp)
    80003342:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003344:	00005597          	auipc	a1,0x5
    80003348:	16458593          	addi	a1,a1,356 # 800084a8 <syscalls+0xd0>
    8000334c:	00016517          	auipc	a0,0x16
    80003350:	89c50513          	addi	a0,a0,-1892 # 80018be8 <bcache>
    80003354:	ffffd097          	auipc	ra,0xffffd
    80003358:	7ee080e7          	jalr	2030(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000335c:	0001e797          	auipc	a5,0x1e
    80003360:	88c78793          	addi	a5,a5,-1908 # 80020be8 <bcache+0x8000>
    80003364:	0001e717          	auipc	a4,0x1e
    80003368:	aec70713          	addi	a4,a4,-1300 # 80020e50 <bcache+0x8268>
    8000336c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003370:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003374:	00016497          	auipc	s1,0x16
    80003378:	88c48493          	addi	s1,s1,-1908 # 80018c00 <bcache+0x18>
    b->next = bcache.head.next;
    8000337c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000337e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003380:	00005a17          	auipc	s4,0x5
    80003384:	130a0a13          	addi	s4,s4,304 # 800084b0 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003388:	2b893783          	ld	a5,696(s2)
    8000338c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000338e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003392:	85d2                	mv	a1,s4
    80003394:	01048513          	addi	a0,s1,16
    80003398:	00001097          	auipc	ra,0x1
    8000339c:	496080e7          	jalr	1174(ra) # 8000482e <initsleeplock>
    bcache.head.next->prev = b;
    800033a0:	2b893783          	ld	a5,696(s2)
    800033a4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033a6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033aa:	45848493          	addi	s1,s1,1112
    800033ae:	fd349de3          	bne	s1,s3,80003388 <binit+0x54>
  }
}
    800033b2:	70a2                	ld	ra,40(sp)
    800033b4:	7402                	ld	s0,32(sp)
    800033b6:	64e2                	ld	s1,24(sp)
    800033b8:	6942                	ld	s2,16(sp)
    800033ba:	69a2                	ld	s3,8(sp)
    800033bc:	6a02                	ld	s4,0(sp)
    800033be:	6145                	addi	sp,sp,48
    800033c0:	8082                	ret

00000000800033c2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033c2:	7179                	addi	sp,sp,-48
    800033c4:	f406                	sd	ra,40(sp)
    800033c6:	f022                	sd	s0,32(sp)
    800033c8:	ec26                	sd	s1,24(sp)
    800033ca:	e84a                	sd	s2,16(sp)
    800033cc:	e44e                	sd	s3,8(sp)
    800033ce:	1800                	addi	s0,sp,48
    800033d0:	892a                	mv	s2,a0
    800033d2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033d4:	00016517          	auipc	a0,0x16
    800033d8:	81450513          	addi	a0,a0,-2028 # 80018be8 <bcache>
    800033dc:	ffffd097          	auipc	ra,0xffffd
    800033e0:	7f6080e7          	jalr	2038(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033e4:	0001e497          	auipc	s1,0x1e
    800033e8:	abc4b483          	ld	s1,-1348(s1) # 80020ea0 <bcache+0x82b8>
    800033ec:	0001e797          	auipc	a5,0x1e
    800033f0:	a6478793          	addi	a5,a5,-1436 # 80020e50 <bcache+0x8268>
    800033f4:	02f48f63          	beq	s1,a5,80003432 <bread+0x70>
    800033f8:	873e                	mv	a4,a5
    800033fa:	a021                	j	80003402 <bread+0x40>
    800033fc:	68a4                	ld	s1,80(s1)
    800033fe:	02e48a63          	beq	s1,a4,80003432 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003402:	449c                	lw	a5,8(s1)
    80003404:	ff279ce3          	bne	a5,s2,800033fc <bread+0x3a>
    80003408:	44dc                	lw	a5,12(s1)
    8000340a:	ff3799e3          	bne	a5,s3,800033fc <bread+0x3a>
      b->refcnt++;
    8000340e:	40bc                	lw	a5,64(s1)
    80003410:	2785                	addiw	a5,a5,1
    80003412:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003414:	00015517          	auipc	a0,0x15
    80003418:	7d450513          	addi	a0,a0,2004 # 80018be8 <bcache>
    8000341c:	ffffe097          	auipc	ra,0xffffe
    80003420:	86a080e7          	jalr	-1942(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003424:	01048513          	addi	a0,s1,16
    80003428:	00001097          	auipc	ra,0x1
    8000342c:	440080e7          	jalr	1088(ra) # 80004868 <acquiresleep>
      return b;
    80003430:	a8b9                	j	8000348e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003432:	0001e497          	auipc	s1,0x1e
    80003436:	a664b483          	ld	s1,-1434(s1) # 80020e98 <bcache+0x82b0>
    8000343a:	0001e797          	auipc	a5,0x1e
    8000343e:	a1678793          	addi	a5,a5,-1514 # 80020e50 <bcache+0x8268>
    80003442:	00f48863          	beq	s1,a5,80003452 <bread+0x90>
    80003446:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003448:	40bc                	lw	a5,64(s1)
    8000344a:	cf81                	beqz	a5,80003462 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000344c:	64a4                	ld	s1,72(s1)
    8000344e:	fee49de3          	bne	s1,a4,80003448 <bread+0x86>
  panic("bget: no buffers");
    80003452:	00005517          	auipc	a0,0x5
    80003456:	06650513          	addi	a0,a0,102 # 800084b8 <syscalls+0xe0>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	0e2080e7          	jalr	226(ra) # 8000053c <panic>
      b->dev = dev;
    80003462:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003466:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000346a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000346e:	4785                	li	a5,1
    80003470:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003472:	00015517          	auipc	a0,0x15
    80003476:	77650513          	addi	a0,a0,1910 # 80018be8 <bcache>
    8000347a:	ffffe097          	auipc	ra,0xffffe
    8000347e:	80c080e7          	jalr	-2036(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003482:	01048513          	addi	a0,s1,16
    80003486:	00001097          	auipc	ra,0x1
    8000348a:	3e2080e7          	jalr	994(ra) # 80004868 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000348e:	409c                	lw	a5,0(s1)
    80003490:	cb89                	beqz	a5,800034a2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003492:	8526                	mv	a0,s1
    80003494:	70a2                	ld	ra,40(sp)
    80003496:	7402                	ld	s0,32(sp)
    80003498:	64e2                	ld	s1,24(sp)
    8000349a:	6942                	ld	s2,16(sp)
    8000349c:	69a2                	ld	s3,8(sp)
    8000349e:	6145                	addi	sp,sp,48
    800034a0:	8082                	ret
    virtio_disk_rw(b, 0);
    800034a2:	4581                	li	a1,0
    800034a4:	8526                	mv	a0,s1
    800034a6:	00003097          	auipc	ra,0x3
    800034aa:	f8c080e7          	jalr	-116(ra) # 80006432 <virtio_disk_rw>
    b->valid = 1;
    800034ae:	4785                	li	a5,1
    800034b0:	c09c                	sw	a5,0(s1)
  return b;
    800034b2:	b7c5                	j	80003492 <bread+0xd0>

00000000800034b4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034b4:	1101                	addi	sp,sp,-32
    800034b6:	ec06                	sd	ra,24(sp)
    800034b8:	e822                	sd	s0,16(sp)
    800034ba:	e426                	sd	s1,8(sp)
    800034bc:	1000                	addi	s0,sp,32
    800034be:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034c0:	0541                	addi	a0,a0,16
    800034c2:	00001097          	auipc	ra,0x1
    800034c6:	440080e7          	jalr	1088(ra) # 80004902 <holdingsleep>
    800034ca:	cd01                	beqz	a0,800034e2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034cc:	4585                	li	a1,1
    800034ce:	8526                	mv	a0,s1
    800034d0:	00003097          	auipc	ra,0x3
    800034d4:	f62080e7          	jalr	-158(ra) # 80006432 <virtio_disk_rw>
}
    800034d8:	60e2                	ld	ra,24(sp)
    800034da:	6442                	ld	s0,16(sp)
    800034dc:	64a2                	ld	s1,8(sp)
    800034de:	6105                	addi	sp,sp,32
    800034e0:	8082                	ret
    panic("bwrite");
    800034e2:	00005517          	auipc	a0,0x5
    800034e6:	fee50513          	addi	a0,a0,-18 # 800084d0 <syscalls+0xf8>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	052080e7          	jalr	82(ra) # 8000053c <panic>

00000000800034f2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034f2:	1101                	addi	sp,sp,-32
    800034f4:	ec06                	sd	ra,24(sp)
    800034f6:	e822                	sd	s0,16(sp)
    800034f8:	e426                	sd	s1,8(sp)
    800034fa:	e04a                	sd	s2,0(sp)
    800034fc:	1000                	addi	s0,sp,32
    800034fe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003500:	01050913          	addi	s2,a0,16
    80003504:	854a                	mv	a0,s2
    80003506:	00001097          	auipc	ra,0x1
    8000350a:	3fc080e7          	jalr	1020(ra) # 80004902 <holdingsleep>
    8000350e:	c925                	beqz	a0,8000357e <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003510:	854a                	mv	a0,s2
    80003512:	00001097          	auipc	ra,0x1
    80003516:	3ac080e7          	jalr	940(ra) # 800048be <releasesleep>

  acquire(&bcache.lock);
    8000351a:	00015517          	auipc	a0,0x15
    8000351e:	6ce50513          	addi	a0,a0,1742 # 80018be8 <bcache>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	6b0080e7          	jalr	1712(ra) # 80000bd2 <acquire>
  b->refcnt--;
    8000352a:	40bc                	lw	a5,64(s1)
    8000352c:	37fd                	addiw	a5,a5,-1
    8000352e:	0007871b          	sext.w	a4,a5
    80003532:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003534:	e71d                	bnez	a4,80003562 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003536:	68b8                	ld	a4,80(s1)
    80003538:	64bc                	ld	a5,72(s1)
    8000353a:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000353c:	68b8                	ld	a4,80(s1)
    8000353e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003540:	0001d797          	auipc	a5,0x1d
    80003544:	6a878793          	addi	a5,a5,1704 # 80020be8 <bcache+0x8000>
    80003548:	2b87b703          	ld	a4,696(a5)
    8000354c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000354e:	0001e717          	auipc	a4,0x1e
    80003552:	90270713          	addi	a4,a4,-1790 # 80020e50 <bcache+0x8268>
    80003556:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003558:	2b87b703          	ld	a4,696(a5)
    8000355c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000355e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003562:	00015517          	auipc	a0,0x15
    80003566:	68650513          	addi	a0,a0,1670 # 80018be8 <bcache>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	71c080e7          	jalr	1820(ra) # 80000c86 <release>
}
    80003572:	60e2                	ld	ra,24(sp)
    80003574:	6442                	ld	s0,16(sp)
    80003576:	64a2                	ld	s1,8(sp)
    80003578:	6902                	ld	s2,0(sp)
    8000357a:	6105                	addi	sp,sp,32
    8000357c:	8082                	ret
    panic("brelse");
    8000357e:	00005517          	auipc	a0,0x5
    80003582:	f5a50513          	addi	a0,a0,-166 # 800084d8 <syscalls+0x100>
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	fb6080e7          	jalr	-74(ra) # 8000053c <panic>

000000008000358e <bpin>:

void
bpin(struct buf *b) {
    8000358e:	1101                	addi	sp,sp,-32
    80003590:	ec06                	sd	ra,24(sp)
    80003592:	e822                	sd	s0,16(sp)
    80003594:	e426                	sd	s1,8(sp)
    80003596:	1000                	addi	s0,sp,32
    80003598:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000359a:	00015517          	auipc	a0,0x15
    8000359e:	64e50513          	addi	a0,a0,1614 # 80018be8 <bcache>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	630080e7          	jalr	1584(ra) # 80000bd2 <acquire>
  b->refcnt++;
    800035aa:	40bc                	lw	a5,64(s1)
    800035ac:	2785                	addiw	a5,a5,1
    800035ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035b0:	00015517          	auipc	a0,0x15
    800035b4:	63850513          	addi	a0,a0,1592 # 80018be8 <bcache>
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	6ce080e7          	jalr	1742(ra) # 80000c86 <release>
}
    800035c0:	60e2                	ld	ra,24(sp)
    800035c2:	6442                	ld	s0,16(sp)
    800035c4:	64a2                	ld	s1,8(sp)
    800035c6:	6105                	addi	sp,sp,32
    800035c8:	8082                	ret

00000000800035ca <bunpin>:

void
bunpin(struct buf *b) {
    800035ca:	1101                	addi	sp,sp,-32
    800035cc:	ec06                	sd	ra,24(sp)
    800035ce:	e822                	sd	s0,16(sp)
    800035d0:	e426                	sd	s1,8(sp)
    800035d2:	1000                	addi	s0,sp,32
    800035d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035d6:	00015517          	auipc	a0,0x15
    800035da:	61250513          	addi	a0,a0,1554 # 80018be8 <bcache>
    800035de:	ffffd097          	auipc	ra,0xffffd
    800035e2:	5f4080e7          	jalr	1524(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800035e6:	40bc                	lw	a5,64(s1)
    800035e8:	37fd                	addiw	a5,a5,-1
    800035ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035ec:	00015517          	auipc	a0,0x15
    800035f0:	5fc50513          	addi	a0,a0,1532 # 80018be8 <bcache>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	692080e7          	jalr	1682(ra) # 80000c86 <release>
}
    800035fc:	60e2                	ld	ra,24(sp)
    800035fe:	6442                	ld	s0,16(sp)
    80003600:	64a2                	ld	s1,8(sp)
    80003602:	6105                	addi	sp,sp,32
    80003604:	8082                	ret

0000000080003606 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003606:	1101                	addi	sp,sp,-32
    80003608:	ec06                	sd	ra,24(sp)
    8000360a:	e822                	sd	s0,16(sp)
    8000360c:	e426                	sd	s1,8(sp)
    8000360e:	e04a                	sd	s2,0(sp)
    80003610:	1000                	addi	s0,sp,32
    80003612:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003614:	00d5d59b          	srliw	a1,a1,0xd
    80003618:	0001e797          	auipc	a5,0x1e
    8000361c:	cac7a783          	lw	a5,-852(a5) # 800212c4 <sb+0x1c>
    80003620:	9dbd                	addw	a1,a1,a5
    80003622:	00000097          	auipc	ra,0x0
    80003626:	da0080e7          	jalr	-608(ra) # 800033c2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000362a:	0074f713          	andi	a4,s1,7
    8000362e:	4785                	li	a5,1
    80003630:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003634:	14ce                	slli	s1,s1,0x33
    80003636:	90d9                	srli	s1,s1,0x36
    80003638:	00950733          	add	a4,a0,s1
    8000363c:	05874703          	lbu	a4,88(a4)
    80003640:	00e7f6b3          	and	a3,a5,a4
    80003644:	c69d                	beqz	a3,80003672 <bfree+0x6c>
    80003646:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003648:	94aa                	add	s1,s1,a0
    8000364a:	fff7c793          	not	a5,a5
    8000364e:	8f7d                	and	a4,a4,a5
    80003650:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003654:	00001097          	auipc	ra,0x1
    80003658:	0f6080e7          	jalr	246(ra) # 8000474a <log_write>
  brelse(bp);
    8000365c:	854a                	mv	a0,s2
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	e94080e7          	jalr	-364(ra) # 800034f2 <brelse>
}
    80003666:	60e2                	ld	ra,24(sp)
    80003668:	6442                	ld	s0,16(sp)
    8000366a:	64a2                	ld	s1,8(sp)
    8000366c:	6902                	ld	s2,0(sp)
    8000366e:	6105                	addi	sp,sp,32
    80003670:	8082                	ret
    panic("freeing free block");
    80003672:	00005517          	auipc	a0,0x5
    80003676:	e6e50513          	addi	a0,a0,-402 # 800084e0 <syscalls+0x108>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	ec2080e7          	jalr	-318(ra) # 8000053c <panic>

0000000080003682 <balloc>:
{
    80003682:	711d                	addi	sp,sp,-96
    80003684:	ec86                	sd	ra,88(sp)
    80003686:	e8a2                	sd	s0,80(sp)
    80003688:	e4a6                	sd	s1,72(sp)
    8000368a:	e0ca                	sd	s2,64(sp)
    8000368c:	fc4e                	sd	s3,56(sp)
    8000368e:	f852                	sd	s4,48(sp)
    80003690:	f456                	sd	s5,40(sp)
    80003692:	f05a                	sd	s6,32(sp)
    80003694:	ec5e                	sd	s7,24(sp)
    80003696:	e862                	sd	s8,16(sp)
    80003698:	e466                	sd	s9,8(sp)
    8000369a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000369c:	0001e797          	auipc	a5,0x1e
    800036a0:	c107a783          	lw	a5,-1008(a5) # 800212ac <sb+0x4>
    800036a4:	cff5                	beqz	a5,800037a0 <balloc+0x11e>
    800036a6:	8baa                	mv	s7,a0
    800036a8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036aa:	0001eb17          	auipc	s6,0x1e
    800036ae:	bfeb0b13          	addi	s6,s6,-1026 # 800212a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036b4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036b8:	6c89                	lui	s9,0x2
    800036ba:	a061                	j	80003742 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036bc:	97ca                	add	a5,a5,s2
    800036be:	8e55                	or	a2,a2,a3
    800036c0:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800036c4:	854a                	mv	a0,s2
    800036c6:	00001097          	auipc	ra,0x1
    800036ca:	084080e7          	jalr	132(ra) # 8000474a <log_write>
        brelse(bp);
    800036ce:	854a                	mv	a0,s2
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	e22080e7          	jalr	-478(ra) # 800034f2 <brelse>
  bp = bread(dev, bno);
    800036d8:	85a6                	mv	a1,s1
    800036da:	855e                	mv	a0,s7
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	ce6080e7          	jalr	-794(ra) # 800033c2 <bread>
    800036e4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036e6:	40000613          	li	a2,1024
    800036ea:	4581                	li	a1,0
    800036ec:	05850513          	addi	a0,a0,88
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	5de080e7          	jalr	1502(ra) # 80000cce <memset>
  log_write(bp);
    800036f8:	854a                	mv	a0,s2
    800036fa:	00001097          	auipc	ra,0x1
    800036fe:	050080e7          	jalr	80(ra) # 8000474a <log_write>
  brelse(bp);
    80003702:	854a                	mv	a0,s2
    80003704:	00000097          	auipc	ra,0x0
    80003708:	dee080e7          	jalr	-530(ra) # 800034f2 <brelse>
}
    8000370c:	8526                	mv	a0,s1
    8000370e:	60e6                	ld	ra,88(sp)
    80003710:	6446                	ld	s0,80(sp)
    80003712:	64a6                	ld	s1,72(sp)
    80003714:	6906                	ld	s2,64(sp)
    80003716:	79e2                	ld	s3,56(sp)
    80003718:	7a42                	ld	s4,48(sp)
    8000371a:	7aa2                	ld	s5,40(sp)
    8000371c:	7b02                	ld	s6,32(sp)
    8000371e:	6be2                	ld	s7,24(sp)
    80003720:	6c42                	ld	s8,16(sp)
    80003722:	6ca2                	ld	s9,8(sp)
    80003724:	6125                	addi	sp,sp,96
    80003726:	8082                	ret
    brelse(bp);
    80003728:	854a                	mv	a0,s2
    8000372a:	00000097          	auipc	ra,0x0
    8000372e:	dc8080e7          	jalr	-568(ra) # 800034f2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003732:	015c87bb          	addw	a5,s9,s5
    80003736:	00078a9b          	sext.w	s5,a5
    8000373a:	004b2703          	lw	a4,4(s6)
    8000373e:	06eaf163          	bgeu	s5,a4,800037a0 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003742:	41fad79b          	sraiw	a5,s5,0x1f
    80003746:	0137d79b          	srliw	a5,a5,0x13
    8000374a:	015787bb          	addw	a5,a5,s5
    8000374e:	40d7d79b          	sraiw	a5,a5,0xd
    80003752:	01cb2583          	lw	a1,28(s6)
    80003756:	9dbd                	addw	a1,a1,a5
    80003758:	855e                	mv	a0,s7
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	c68080e7          	jalr	-920(ra) # 800033c2 <bread>
    80003762:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003764:	004b2503          	lw	a0,4(s6)
    80003768:	000a849b          	sext.w	s1,s5
    8000376c:	8762                	mv	a4,s8
    8000376e:	faa4fde3          	bgeu	s1,a0,80003728 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003772:	00777693          	andi	a3,a4,7
    80003776:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000377a:	41f7579b          	sraiw	a5,a4,0x1f
    8000377e:	01d7d79b          	srliw	a5,a5,0x1d
    80003782:	9fb9                	addw	a5,a5,a4
    80003784:	4037d79b          	sraiw	a5,a5,0x3
    80003788:	00f90633          	add	a2,s2,a5
    8000378c:	05864603          	lbu	a2,88(a2)
    80003790:	00c6f5b3          	and	a1,a3,a2
    80003794:	d585                	beqz	a1,800036bc <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003796:	2705                	addiw	a4,a4,1
    80003798:	2485                	addiw	s1,s1,1
    8000379a:	fd471ae3          	bne	a4,s4,8000376e <balloc+0xec>
    8000379e:	b769                	j	80003728 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800037a0:	00005517          	auipc	a0,0x5
    800037a4:	d5850513          	addi	a0,a0,-680 # 800084f8 <syscalls+0x120>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	dde080e7          	jalr	-546(ra) # 80000586 <printf>
  return 0;
    800037b0:	4481                	li	s1,0
    800037b2:	bfa9                	j	8000370c <balloc+0x8a>

00000000800037b4 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800037b4:	7179                	addi	sp,sp,-48
    800037b6:	f406                	sd	ra,40(sp)
    800037b8:	f022                	sd	s0,32(sp)
    800037ba:	ec26                	sd	s1,24(sp)
    800037bc:	e84a                	sd	s2,16(sp)
    800037be:	e44e                	sd	s3,8(sp)
    800037c0:	e052                	sd	s4,0(sp)
    800037c2:	1800                	addi	s0,sp,48
    800037c4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037c6:	47ad                	li	a5,11
    800037c8:	02b7e863          	bltu	a5,a1,800037f8 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800037cc:	02059793          	slli	a5,a1,0x20
    800037d0:	01e7d593          	srli	a1,a5,0x1e
    800037d4:	00b504b3          	add	s1,a0,a1
    800037d8:	0504a903          	lw	s2,80(s1)
    800037dc:	06091e63          	bnez	s2,80003858 <bmap+0xa4>
      addr = balloc(ip->dev);
    800037e0:	4108                	lw	a0,0(a0)
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	ea0080e7          	jalr	-352(ra) # 80003682 <balloc>
    800037ea:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037ee:	06090563          	beqz	s2,80003858 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800037f2:	0524a823          	sw	s2,80(s1)
    800037f6:	a08d                	j	80003858 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800037f8:	ff45849b          	addiw	s1,a1,-12
    800037fc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003800:	0ff00793          	li	a5,255
    80003804:	08e7e563          	bltu	a5,a4,8000388e <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003808:	08052903          	lw	s2,128(a0)
    8000380c:	00091d63          	bnez	s2,80003826 <bmap+0x72>
      addr = balloc(ip->dev);
    80003810:	4108                	lw	a0,0(a0)
    80003812:	00000097          	auipc	ra,0x0
    80003816:	e70080e7          	jalr	-400(ra) # 80003682 <balloc>
    8000381a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000381e:	02090d63          	beqz	s2,80003858 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003822:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003826:	85ca                	mv	a1,s2
    80003828:	0009a503          	lw	a0,0(s3)
    8000382c:	00000097          	auipc	ra,0x0
    80003830:	b96080e7          	jalr	-1130(ra) # 800033c2 <bread>
    80003834:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003836:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000383a:	02049713          	slli	a4,s1,0x20
    8000383e:	01e75593          	srli	a1,a4,0x1e
    80003842:	00b784b3          	add	s1,a5,a1
    80003846:	0004a903          	lw	s2,0(s1)
    8000384a:	02090063          	beqz	s2,8000386a <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000384e:	8552                	mv	a0,s4
    80003850:	00000097          	auipc	ra,0x0
    80003854:	ca2080e7          	jalr	-862(ra) # 800034f2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003858:	854a                	mv	a0,s2
    8000385a:	70a2                	ld	ra,40(sp)
    8000385c:	7402                	ld	s0,32(sp)
    8000385e:	64e2                	ld	s1,24(sp)
    80003860:	6942                	ld	s2,16(sp)
    80003862:	69a2                	ld	s3,8(sp)
    80003864:	6a02                	ld	s4,0(sp)
    80003866:	6145                	addi	sp,sp,48
    80003868:	8082                	ret
      addr = balloc(ip->dev);
    8000386a:	0009a503          	lw	a0,0(s3)
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	e14080e7          	jalr	-492(ra) # 80003682 <balloc>
    80003876:	0005091b          	sext.w	s2,a0
      if(addr){
    8000387a:	fc090ae3          	beqz	s2,8000384e <bmap+0x9a>
        a[bn] = addr;
    8000387e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003882:	8552                	mv	a0,s4
    80003884:	00001097          	auipc	ra,0x1
    80003888:	ec6080e7          	jalr	-314(ra) # 8000474a <log_write>
    8000388c:	b7c9                	j	8000384e <bmap+0x9a>
  panic("bmap: out of range");
    8000388e:	00005517          	auipc	a0,0x5
    80003892:	c8250513          	addi	a0,a0,-894 # 80008510 <syscalls+0x138>
    80003896:	ffffd097          	auipc	ra,0xffffd
    8000389a:	ca6080e7          	jalr	-858(ra) # 8000053c <panic>

000000008000389e <iget>:
{
    8000389e:	7179                	addi	sp,sp,-48
    800038a0:	f406                	sd	ra,40(sp)
    800038a2:	f022                	sd	s0,32(sp)
    800038a4:	ec26                	sd	s1,24(sp)
    800038a6:	e84a                	sd	s2,16(sp)
    800038a8:	e44e                	sd	s3,8(sp)
    800038aa:	e052                	sd	s4,0(sp)
    800038ac:	1800                	addi	s0,sp,48
    800038ae:	89aa                	mv	s3,a0
    800038b0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038b2:	0001e517          	auipc	a0,0x1e
    800038b6:	a1650513          	addi	a0,a0,-1514 # 800212c8 <itable>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	318080e7          	jalr	792(ra) # 80000bd2 <acquire>
  empty = 0;
    800038c2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038c4:	0001e497          	auipc	s1,0x1e
    800038c8:	a1c48493          	addi	s1,s1,-1508 # 800212e0 <itable+0x18>
    800038cc:	0001f697          	auipc	a3,0x1f
    800038d0:	4a468693          	addi	a3,a3,1188 # 80022d70 <log>
    800038d4:	a039                	j	800038e2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038d6:	02090b63          	beqz	s2,8000390c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038da:	08848493          	addi	s1,s1,136
    800038de:	02d48a63          	beq	s1,a3,80003912 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038e2:	449c                	lw	a5,8(s1)
    800038e4:	fef059e3          	blez	a5,800038d6 <iget+0x38>
    800038e8:	4098                	lw	a4,0(s1)
    800038ea:	ff3716e3          	bne	a4,s3,800038d6 <iget+0x38>
    800038ee:	40d8                	lw	a4,4(s1)
    800038f0:	ff4713e3          	bne	a4,s4,800038d6 <iget+0x38>
      ip->ref++;
    800038f4:	2785                	addiw	a5,a5,1
    800038f6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038f8:	0001e517          	auipc	a0,0x1e
    800038fc:	9d050513          	addi	a0,a0,-1584 # 800212c8 <itable>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	386080e7          	jalr	902(ra) # 80000c86 <release>
      return ip;
    80003908:	8926                	mv	s2,s1
    8000390a:	a03d                	j	80003938 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000390c:	f7f9                	bnez	a5,800038da <iget+0x3c>
    8000390e:	8926                	mv	s2,s1
    80003910:	b7e9                	j	800038da <iget+0x3c>
  if(empty == 0)
    80003912:	02090c63          	beqz	s2,8000394a <iget+0xac>
  ip->dev = dev;
    80003916:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000391a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000391e:	4785                	li	a5,1
    80003920:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003924:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003928:	0001e517          	auipc	a0,0x1e
    8000392c:	9a050513          	addi	a0,a0,-1632 # 800212c8 <itable>
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	356080e7          	jalr	854(ra) # 80000c86 <release>
}
    80003938:	854a                	mv	a0,s2
    8000393a:	70a2                	ld	ra,40(sp)
    8000393c:	7402                	ld	s0,32(sp)
    8000393e:	64e2                	ld	s1,24(sp)
    80003940:	6942                	ld	s2,16(sp)
    80003942:	69a2                	ld	s3,8(sp)
    80003944:	6a02                	ld	s4,0(sp)
    80003946:	6145                	addi	sp,sp,48
    80003948:	8082                	ret
    panic("iget: no inodes");
    8000394a:	00005517          	auipc	a0,0x5
    8000394e:	bde50513          	addi	a0,a0,-1058 # 80008528 <syscalls+0x150>
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	bea080e7          	jalr	-1046(ra) # 8000053c <panic>

000000008000395a <fsinit>:
fsinit(int dev) {
    8000395a:	7179                	addi	sp,sp,-48
    8000395c:	f406                	sd	ra,40(sp)
    8000395e:	f022                	sd	s0,32(sp)
    80003960:	ec26                	sd	s1,24(sp)
    80003962:	e84a                	sd	s2,16(sp)
    80003964:	e44e                	sd	s3,8(sp)
    80003966:	1800                	addi	s0,sp,48
    80003968:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000396a:	4585                	li	a1,1
    8000396c:	00000097          	auipc	ra,0x0
    80003970:	a56080e7          	jalr	-1450(ra) # 800033c2 <bread>
    80003974:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003976:	0001e997          	auipc	s3,0x1e
    8000397a:	93298993          	addi	s3,s3,-1742 # 800212a8 <sb>
    8000397e:	02000613          	li	a2,32
    80003982:	05850593          	addi	a1,a0,88
    80003986:	854e                	mv	a0,s3
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	3a2080e7          	jalr	930(ra) # 80000d2a <memmove>
  brelse(bp);
    80003990:	8526                	mv	a0,s1
    80003992:	00000097          	auipc	ra,0x0
    80003996:	b60080e7          	jalr	-1184(ra) # 800034f2 <brelse>
  if(sb.magic != FSMAGIC)
    8000399a:	0009a703          	lw	a4,0(s3)
    8000399e:	102037b7          	lui	a5,0x10203
    800039a2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039a6:	02f71263          	bne	a4,a5,800039ca <fsinit+0x70>
  initlog(dev, &sb);
    800039aa:	0001e597          	auipc	a1,0x1e
    800039ae:	8fe58593          	addi	a1,a1,-1794 # 800212a8 <sb>
    800039b2:	854a                	mv	a0,s2
    800039b4:	00001097          	auipc	ra,0x1
    800039b8:	b2c080e7          	jalr	-1236(ra) # 800044e0 <initlog>
}
    800039bc:	70a2                	ld	ra,40(sp)
    800039be:	7402                	ld	s0,32(sp)
    800039c0:	64e2                	ld	s1,24(sp)
    800039c2:	6942                	ld	s2,16(sp)
    800039c4:	69a2                	ld	s3,8(sp)
    800039c6:	6145                	addi	sp,sp,48
    800039c8:	8082                	ret
    panic("invalid file system");
    800039ca:	00005517          	auipc	a0,0x5
    800039ce:	b6e50513          	addi	a0,a0,-1170 # 80008538 <syscalls+0x160>
    800039d2:	ffffd097          	auipc	ra,0xffffd
    800039d6:	b6a080e7          	jalr	-1174(ra) # 8000053c <panic>

00000000800039da <iinit>:
{
    800039da:	7179                	addi	sp,sp,-48
    800039dc:	f406                	sd	ra,40(sp)
    800039de:	f022                	sd	s0,32(sp)
    800039e0:	ec26                	sd	s1,24(sp)
    800039e2:	e84a                	sd	s2,16(sp)
    800039e4:	e44e                	sd	s3,8(sp)
    800039e6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039e8:	00005597          	auipc	a1,0x5
    800039ec:	b6858593          	addi	a1,a1,-1176 # 80008550 <syscalls+0x178>
    800039f0:	0001e517          	auipc	a0,0x1e
    800039f4:	8d850513          	addi	a0,a0,-1832 # 800212c8 <itable>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	14a080e7          	jalr	330(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a00:	0001e497          	auipc	s1,0x1e
    80003a04:	8f048493          	addi	s1,s1,-1808 # 800212f0 <itable+0x28>
    80003a08:	0001f997          	auipc	s3,0x1f
    80003a0c:	37898993          	addi	s3,s3,888 # 80022d80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a10:	00005917          	auipc	s2,0x5
    80003a14:	b4890913          	addi	s2,s2,-1208 # 80008558 <syscalls+0x180>
    80003a18:	85ca                	mv	a1,s2
    80003a1a:	8526                	mv	a0,s1
    80003a1c:	00001097          	auipc	ra,0x1
    80003a20:	e12080e7          	jalr	-494(ra) # 8000482e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a24:	08848493          	addi	s1,s1,136
    80003a28:	ff3498e3          	bne	s1,s3,80003a18 <iinit+0x3e>
}
    80003a2c:	70a2                	ld	ra,40(sp)
    80003a2e:	7402                	ld	s0,32(sp)
    80003a30:	64e2                	ld	s1,24(sp)
    80003a32:	6942                	ld	s2,16(sp)
    80003a34:	69a2                	ld	s3,8(sp)
    80003a36:	6145                	addi	sp,sp,48
    80003a38:	8082                	ret

0000000080003a3a <ialloc>:
{
    80003a3a:	7139                	addi	sp,sp,-64
    80003a3c:	fc06                	sd	ra,56(sp)
    80003a3e:	f822                	sd	s0,48(sp)
    80003a40:	f426                	sd	s1,40(sp)
    80003a42:	f04a                	sd	s2,32(sp)
    80003a44:	ec4e                	sd	s3,24(sp)
    80003a46:	e852                	sd	s4,16(sp)
    80003a48:	e456                	sd	s5,8(sp)
    80003a4a:	e05a                	sd	s6,0(sp)
    80003a4c:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a4e:	0001e717          	auipc	a4,0x1e
    80003a52:	86672703          	lw	a4,-1946(a4) # 800212b4 <sb+0xc>
    80003a56:	4785                	li	a5,1
    80003a58:	04e7f863          	bgeu	a5,a4,80003aa8 <ialloc+0x6e>
    80003a5c:	8aaa                	mv	s5,a0
    80003a5e:	8b2e                	mv	s6,a1
    80003a60:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a62:	0001ea17          	auipc	s4,0x1e
    80003a66:	846a0a13          	addi	s4,s4,-1978 # 800212a8 <sb>
    80003a6a:	00495593          	srli	a1,s2,0x4
    80003a6e:	018a2783          	lw	a5,24(s4)
    80003a72:	9dbd                	addw	a1,a1,a5
    80003a74:	8556                	mv	a0,s5
    80003a76:	00000097          	auipc	ra,0x0
    80003a7a:	94c080e7          	jalr	-1716(ra) # 800033c2 <bread>
    80003a7e:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a80:	05850993          	addi	s3,a0,88
    80003a84:	00f97793          	andi	a5,s2,15
    80003a88:	079a                	slli	a5,a5,0x6
    80003a8a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a8c:	00099783          	lh	a5,0(s3)
    80003a90:	cf9d                	beqz	a5,80003ace <ialloc+0x94>
    brelse(bp);
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	a60080e7          	jalr	-1440(ra) # 800034f2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a9a:	0905                	addi	s2,s2,1
    80003a9c:	00ca2703          	lw	a4,12(s4)
    80003aa0:	0009079b          	sext.w	a5,s2
    80003aa4:	fce7e3e3          	bltu	a5,a4,80003a6a <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003aa8:	00005517          	auipc	a0,0x5
    80003aac:	ab850513          	addi	a0,a0,-1352 # 80008560 <syscalls+0x188>
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	ad6080e7          	jalr	-1322(ra) # 80000586 <printf>
  return 0;
    80003ab8:	4501                	li	a0,0
}
    80003aba:	70e2                	ld	ra,56(sp)
    80003abc:	7442                	ld	s0,48(sp)
    80003abe:	74a2                	ld	s1,40(sp)
    80003ac0:	7902                	ld	s2,32(sp)
    80003ac2:	69e2                	ld	s3,24(sp)
    80003ac4:	6a42                	ld	s4,16(sp)
    80003ac6:	6aa2                	ld	s5,8(sp)
    80003ac8:	6b02                	ld	s6,0(sp)
    80003aca:	6121                	addi	sp,sp,64
    80003acc:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003ace:	04000613          	li	a2,64
    80003ad2:	4581                	li	a1,0
    80003ad4:	854e                	mv	a0,s3
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	1f8080e7          	jalr	504(ra) # 80000cce <memset>
      dip->type = type;
    80003ade:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ae2:	8526                	mv	a0,s1
    80003ae4:	00001097          	auipc	ra,0x1
    80003ae8:	c66080e7          	jalr	-922(ra) # 8000474a <log_write>
      brelse(bp);
    80003aec:	8526                	mv	a0,s1
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	a04080e7          	jalr	-1532(ra) # 800034f2 <brelse>
      return iget(dev, inum);
    80003af6:	0009059b          	sext.w	a1,s2
    80003afa:	8556                	mv	a0,s5
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	da2080e7          	jalr	-606(ra) # 8000389e <iget>
    80003b04:	bf5d                	j	80003aba <ialloc+0x80>

0000000080003b06 <iupdate>:
{
    80003b06:	1101                	addi	sp,sp,-32
    80003b08:	ec06                	sd	ra,24(sp)
    80003b0a:	e822                	sd	s0,16(sp)
    80003b0c:	e426                	sd	s1,8(sp)
    80003b0e:	e04a                	sd	s2,0(sp)
    80003b10:	1000                	addi	s0,sp,32
    80003b12:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b14:	415c                	lw	a5,4(a0)
    80003b16:	0047d79b          	srliw	a5,a5,0x4
    80003b1a:	0001d597          	auipc	a1,0x1d
    80003b1e:	7a65a583          	lw	a1,1958(a1) # 800212c0 <sb+0x18>
    80003b22:	9dbd                	addw	a1,a1,a5
    80003b24:	4108                	lw	a0,0(a0)
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	89c080e7          	jalr	-1892(ra) # 800033c2 <bread>
    80003b2e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b30:	05850793          	addi	a5,a0,88
    80003b34:	40d8                	lw	a4,4(s1)
    80003b36:	8b3d                	andi	a4,a4,15
    80003b38:	071a                	slli	a4,a4,0x6
    80003b3a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b3c:	04449703          	lh	a4,68(s1)
    80003b40:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b44:	04649703          	lh	a4,70(s1)
    80003b48:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b4c:	04849703          	lh	a4,72(s1)
    80003b50:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b54:	04a49703          	lh	a4,74(s1)
    80003b58:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003b5c:	44f8                	lw	a4,76(s1)
    80003b5e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b60:	03400613          	li	a2,52
    80003b64:	05048593          	addi	a1,s1,80
    80003b68:	00c78513          	addi	a0,a5,12
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	1be080e7          	jalr	446(ra) # 80000d2a <memmove>
  log_write(bp);
    80003b74:	854a                	mv	a0,s2
    80003b76:	00001097          	auipc	ra,0x1
    80003b7a:	bd4080e7          	jalr	-1068(ra) # 8000474a <log_write>
  brelse(bp);
    80003b7e:	854a                	mv	a0,s2
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	972080e7          	jalr	-1678(ra) # 800034f2 <brelse>
}
    80003b88:	60e2                	ld	ra,24(sp)
    80003b8a:	6442                	ld	s0,16(sp)
    80003b8c:	64a2                	ld	s1,8(sp)
    80003b8e:	6902                	ld	s2,0(sp)
    80003b90:	6105                	addi	sp,sp,32
    80003b92:	8082                	ret

0000000080003b94 <idup>:
{
    80003b94:	1101                	addi	sp,sp,-32
    80003b96:	ec06                	sd	ra,24(sp)
    80003b98:	e822                	sd	s0,16(sp)
    80003b9a:	e426                	sd	s1,8(sp)
    80003b9c:	1000                	addi	s0,sp,32
    80003b9e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ba0:	0001d517          	auipc	a0,0x1d
    80003ba4:	72850513          	addi	a0,a0,1832 # 800212c8 <itable>
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	02a080e7          	jalr	42(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003bb0:	449c                	lw	a5,8(s1)
    80003bb2:	2785                	addiw	a5,a5,1
    80003bb4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bb6:	0001d517          	auipc	a0,0x1d
    80003bba:	71250513          	addi	a0,a0,1810 # 800212c8 <itable>
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	0c8080e7          	jalr	200(ra) # 80000c86 <release>
}
    80003bc6:	8526                	mv	a0,s1
    80003bc8:	60e2                	ld	ra,24(sp)
    80003bca:	6442                	ld	s0,16(sp)
    80003bcc:	64a2                	ld	s1,8(sp)
    80003bce:	6105                	addi	sp,sp,32
    80003bd0:	8082                	ret

0000000080003bd2 <ilock>:
{
    80003bd2:	1101                	addi	sp,sp,-32
    80003bd4:	ec06                	sd	ra,24(sp)
    80003bd6:	e822                	sd	s0,16(sp)
    80003bd8:	e426                	sd	s1,8(sp)
    80003bda:	e04a                	sd	s2,0(sp)
    80003bdc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bde:	c115                	beqz	a0,80003c02 <ilock+0x30>
    80003be0:	84aa                	mv	s1,a0
    80003be2:	451c                	lw	a5,8(a0)
    80003be4:	00f05f63          	blez	a5,80003c02 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003be8:	0541                	addi	a0,a0,16
    80003bea:	00001097          	auipc	ra,0x1
    80003bee:	c7e080e7          	jalr	-898(ra) # 80004868 <acquiresleep>
  if(ip->valid == 0){
    80003bf2:	40bc                	lw	a5,64(s1)
    80003bf4:	cf99                	beqz	a5,80003c12 <ilock+0x40>
}
    80003bf6:	60e2                	ld	ra,24(sp)
    80003bf8:	6442                	ld	s0,16(sp)
    80003bfa:	64a2                	ld	s1,8(sp)
    80003bfc:	6902                	ld	s2,0(sp)
    80003bfe:	6105                	addi	sp,sp,32
    80003c00:	8082                	ret
    panic("ilock");
    80003c02:	00005517          	auipc	a0,0x5
    80003c06:	97650513          	addi	a0,a0,-1674 # 80008578 <syscalls+0x1a0>
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	932080e7          	jalr	-1742(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c12:	40dc                	lw	a5,4(s1)
    80003c14:	0047d79b          	srliw	a5,a5,0x4
    80003c18:	0001d597          	auipc	a1,0x1d
    80003c1c:	6a85a583          	lw	a1,1704(a1) # 800212c0 <sb+0x18>
    80003c20:	9dbd                	addw	a1,a1,a5
    80003c22:	4088                	lw	a0,0(s1)
    80003c24:	fffff097          	auipc	ra,0xfffff
    80003c28:	79e080e7          	jalr	1950(ra) # 800033c2 <bread>
    80003c2c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c2e:	05850593          	addi	a1,a0,88
    80003c32:	40dc                	lw	a5,4(s1)
    80003c34:	8bbd                	andi	a5,a5,15
    80003c36:	079a                	slli	a5,a5,0x6
    80003c38:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c3a:	00059783          	lh	a5,0(a1)
    80003c3e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c42:	00259783          	lh	a5,2(a1)
    80003c46:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c4a:	00459783          	lh	a5,4(a1)
    80003c4e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c52:	00659783          	lh	a5,6(a1)
    80003c56:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c5a:	459c                	lw	a5,8(a1)
    80003c5c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c5e:	03400613          	li	a2,52
    80003c62:	05b1                	addi	a1,a1,12
    80003c64:	05048513          	addi	a0,s1,80
    80003c68:	ffffd097          	auipc	ra,0xffffd
    80003c6c:	0c2080e7          	jalr	194(ra) # 80000d2a <memmove>
    brelse(bp);
    80003c70:	854a                	mv	a0,s2
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	880080e7          	jalr	-1920(ra) # 800034f2 <brelse>
    ip->valid = 1;
    80003c7a:	4785                	li	a5,1
    80003c7c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c7e:	04449783          	lh	a5,68(s1)
    80003c82:	fbb5                	bnez	a5,80003bf6 <ilock+0x24>
      panic("ilock: no type");
    80003c84:	00005517          	auipc	a0,0x5
    80003c88:	8fc50513          	addi	a0,a0,-1796 # 80008580 <syscalls+0x1a8>
    80003c8c:	ffffd097          	auipc	ra,0xffffd
    80003c90:	8b0080e7          	jalr	-1872(ra) # 8000053c <panic>

0000000080003c94 <iunlock>:
{
    80003c94:	1101                	addi	sp,sp,-32
    80003c96:	ec06                	sd	ra,24(sp)
    80003c98:	e822                	sd	s0,16(sp)
    80003c9a:	e426                	sd	s1,8(sp)
    80003c9c:	e04a                	sd	s2,0(sp)
    80003c9e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ca0:	c905                	beqz	a0,80003cd0 <iunlock+0x3c>
    80003ca2:	84aa                	mv	s1,a0
    80003ca4:	01050913          	addi	s2,a0,16
    80003ca8:	854a                	mv	a0,s2
    80003caa:	00001097          	auipc	ra,0x1
    80003cae:	c58080e7          	jalr	-936(ra) # 80004902 <holdingsleep>
    80003cb2:	cd19                	beqz	a0,80003cd0 <iunlock+0x3c>
    80003cb4:	449c                	lw	a5,8(s1)
    80003cb6:	00f05d63          	blez	a5,80003cd0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cba:	854a                	mv	a0,s2
    80003cbc:	00001097          	auipc	ra,0x1
    80003cc0:	c02080e7          	jalr	-1022(ra) # 800048be <releasesleep>
}
    80003cc4:	60e2                	ld	ra,24(sp)
    80003cc6:	6442                	ld	s0,16(sp)
    80003cc8:	64a2                	ld	s1,8(sp)
    80003cca:	6902                	ld	s2,0(sp)
    80003ccc:	6105                	addi	sp,sp,32
    80003cce:	8082                	ret
    panic("iunlock");
    80003cd0:	00005517          	auipc	a0,0x5
    80003cd4:	8c050513          	addi	a0,a0,-1856 # 80008590 <syscalls+0x1b8>
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	864080e7          	jalr	-1948(ra) # 8000053c <panic>

0000000080003ce0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ce0:	7179                	addi	sp,sp,-48
    80003ce2:	f406                	sd	ra,40(sp)
    80003ce4:	f022                	sd	s0,32(sp)
    80003ce6:	ec26                	sd	s1,24(sp)
    80003ce8:	e84a                	sd	s2,16(sp)
    80003cea:	e44e                	sd	s3,8(sp)
    80003cec:	e052                	sd	s4,0(sp)
    80003cee:	1800                	addi	s0,sp,48
    80003cf0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cf2:	05050493          	addi	s1,a0,80
    80003cf6:	08050913          	addi	s2,a0,128
    80003cfa:	a021                	j	80003d02 <itrunc+0x22>
    80003cfc:	0491                	addi	s1,s1,4
    80003cfe:	01248d63          	beq	s1,s2,80003d18 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d02:	408c                	lw	a1,0(s1)
    80003d04:	dde5                	beqz	a1,80003cfc <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d06:	0009a503          	lw	a0,0(s3)
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	8fc080e7          	jalr	-1796(ra) # 80003606 <bfree>
      ip->addrs[i] = 0;
    80003d12:	0004a023          	sw	zero,0(s1)
    80003d16:	b7dd                	j	80003cfc <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d18:	0809a583          	lw	a1,128(s3)
    80003d1c:	e185                	bnez	a1,80003d3c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d1e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d22:	854e                	mv	a0,s3
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	de2080e7          	jalr	-542(ra) # 80003b06 <iupdate>
}
    80003d2c:	70a2                	ld	ra,40(sp)
    80003d2e:	7402                	ld	s0,32(sp)
    80003d30:	64e2                	ld	s1,24(sp)
    80003d32:	6942                	ld	s2,16(sp)
    80003d34:	69a2                	ld	s3,8(sp)
    80003d36:	6a02                	ld	s4,0(sp)
    80003d38:	6145                	addi	sp,sp,48
    80003d3a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d3c:	0009a503          	lw	a0,0(s3)
    80003d40:	fffff097          	auipc	ra,0xfffff
    80003d44:	682080e7          	jalr	1666(ra) # 800033c2 <bread>
    80003d48:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d4a:	05850493          	addi	s1,a0,88
    80003d4e:	45850913          	addi	s2,a0,1112
    80003d52:	a021                	j	80003d5a <itrunc+0x7a>
    80003d54:	0491                	addi	s1,s1,4
    80003d56:	01248b63          	beq	s1,s2,80003d6c <itrunc+0x8c>
      if(a[j])
    80003d5a:	408c                	lw	a1,0(s1)
    80003d5c:	dde5                	beqz	a1,80003d54 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d5e:	0009a503          	lw	a0,0(s3)
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	8a4080e7          	jalr	-1884(ra) # 80003606 <bfree>
    80003d6a:	b7ed                	j	80003d54 <itrunc+0x74>
    brelse(bp);
    80003d6c:	8552                	mv	a0,s4
    80003d6e:	fffff097          	auipc	ra,0xfffff
    80003d72:	784080e7          	jalr	1924(ra) # 800034f2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d76:	0809a583          	lw	a1,128(s3)
    80003d7a:	0009a503          	lw	a0,0(s3)
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	888080e7          	jalr	-1912(ra) # 80003606 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d86:	0809a023          	sw	zero,128(s3)
    80003d8a:	bf51                	j	80003d1e <itrunc+0x3e>

0000000080003d8c <iput>:
{
    80003d8c:	1101                	addi	sp,sp,-32
    80003d8e:	ec06                	sd	ra,24(sp)
    80003d90:	e822                	sd	s0,16(sp)
    80003d92:	e426                	sd	s1,8(sp)
    80003d94:	e04a                	sd	s2,0(sp)
    80003d96:	1000                	addi	s0,sp,32
    80003d98:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d9a:	0001d517          	auipc	a0,0x1d
    80003d9e:	52e50513          	addi	a0,a0,1326 # 800212c8 <itable>
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	e30080e7          	jalr	-464(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003daa:	4498                	lw	a4,8(s1)
    80003dac:	4785                	li	a5,1
    80003dae:	02f70363          	beq	a4,a5,80003dd4 <iput+0x48>
  ip->ref--;
    80003db2:	449c                	lw	a5,8(s1)
    80003db4:	37fd                	addiw	a5,a5,-1
    80003db6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003db8:	0001d517          	auipc	a0,0x1d
    80003dbc:	51050513          	addi	a0,a0,1296 # 800212c8 <itable>
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	ec6080e7          	jalr	-314(ra) # 80000c86 <release>
}
    80003dc8:	60e2                	ld	ra,24(sp)
    80003dca:	6442                	ld	s0,16(sp)
    80003dcc:	64a2                	ld	s1,8(sp)
    80003dce:	6902                	ld	s2,0(sp)
    80003dd0:	6105                	addi	sp,sp,32
    80003dd2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dd4:	40bc                	lw	a5,64(s1)
    80003dd6:	dff1                	beqz	a5,80003db2 <iput+0x26>
    80003dd8:	04a49783          	lh	a5,74(s1)
    80003ddc:	fbf9                	bnez	a5,80003db2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003dde:	01048913          	addi	s2,s1,16
    80003de2:	854a                	mv	a0,s2
    80003de4:	00001097          	auipc	ra,0x1
    80003de8:	a84080e7          	jalr	-1404(ra) # 80004868 <acquiresleep>
    release(&itable.lock);
    80003dec:	0001d517          	auipc	a0,0x1d
    80003df0:	4dc50513          	addi	a0,a0,1244 # 800212c8 <itable>
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	e92080e7          	jalr	-366(ra) # 80000c86 <release>
    itrunc(ip);
    80003dfc:	8526                	mv	a0,s1
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	ee2080e7          	jalr	-286(ra) # 80003ce0 <itrunc>
    ip->type = 0;
    80003e06:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e0a:	8526                	mv	a0,s1
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	cfa080e7          	jalr	-774(ra) # 80003b06 <iupdate>
    ip->valid = 0;
    80003e14:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e18:	854a                	mv	a0,s2
    80003e1a:	00001097          	auipc	ra,0x1
    80003e1e:	aa4080e7          	jalr	-1372(ra) # 800048be <releasesleep>
    acquire(&itable.lock);
    80003e22:	0001d517          	auipc	a0,0x1d
    80003e26:	4a650513          	addi	a0,a0,1190 # 800212c8 <itable>
    80003e2a:	ffffd097          	auipc	ra,0xffffd
    80003e2e:	da8080e7          	jalr	-600(ra) # 80000bd2 <acquire>
    80003e32:	b741                	j	80003db2 <iput+0x26>

0000000080003e34 <iunlockput>:
{
    80003e34:	1101                	addi	sp,sp,-32
    80003e36:	ec06                	sd	ra,24(sp)
    80003e38:	e822                	sd	s0,16(sp)
    80003e3a:	e426                	sd	s1,8(sp)
    80003e3c:	1000                	addi	s0,sp,32
    80003e3e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	e54080e7          	jalr	-428(ra) # 80003c94 <iunlock>
  iput(ip);
    80003e48:	8526                	mv	a0,s1
    80003e4a:	00000097          	auipc	ra,0x0
    80003e4e:	f42080e7          	jalr	-190(ra) # 80003d8c <iput>
}
    80003e52:	60e2                	ld	ra,24(sp)
    80003e54:	6442                	ld	s0,16(sp)
    80003e56:	64a2                	ld	s1,8(sp)
    80003e58:	6105                	addi	sp,sp,32
    80003e5a:	8082                	ret

0000000080003e5c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e5c:	1141                	addi	sp,sp,-16
    80003e5e:	e422                	sd	s0,8(sp)
    80003e60:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e62:	411c                	lw	a5,0(a0)
    80003e64:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e66:	415c                	lw	a5,4(a0)
    80003e68:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e6a:	04451783          	lh	a5,68(a0)
    80003e6e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e72:	04a51783          	lh	a5,74(a0)
    80003e76:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e7a:	04c56783          	lwu	a5,76(a0)
    80003e7e:	e99c                	sd	a5,16(a1)
}
    80003e80:	6422                	ld	s0,8(sp)
    80003e82:	0141                	addi	sp,sp,16
    80003e84:	8082                	ret

0000000080003e86 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e86:	457c                	lw	a5,76(a0)
    80003e88:	0ed7e963          	bltu	a5,a3,80003f7a <readi+0xf4>
{
    80003e8c:	7159                	addi	sp,sp,-112
    80003e8e:	f486                	sd	ra,104(sp)
    80003e90:	f0a2                	sd	s0,96(sp)
    80003e92:	eca6                	sd	s1,88(sp)
    80003e94:	e8ca                	sd	s2,80(sp)
    80003e96:	e4ce                	sd	s3,72(sp)
    80003e98:	e0d2                	sd	s4,64(sp)
    80003e9a:	fc56                	sd	s5,56(sp)
    80003e9c:	f85a                	sd	s6,48(sp)
    80003e9e:	f45e                	sd	s7,40(sp)
    80003ea0:	f062                	sd	s8,32(sp)
    80003ea2:	ec66                	sd	s9,24(sp)
    80003ea4:	e86a                	sd	s10,16(sp)
    80003ea6:	e46e                	sd	s11,8(sp)
    80003ea8:	1880                	addi	s0,sp,112
    80003eaa:	8b2a                	mv	s6,a0
    80003eac:	8bae                	mv	s7,a1
    80003eae:	8a32                	mv	s4,a2
    80003eb0:	84b6                	mv	s1,a3
    80003eb2:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003eb4:	9f35                	addw	a4,a4,a3
    return 0;
    80003eb6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003eb8:	0ad76063          	bltu	a4,a3,80003f58 <readi+0xd2>
  if(off + n > ip->size)
    80003ebc:	00e7f463          	bgeu	a5,a4,80003ec4 <readi+0x3e>
    n = ip->size - off;
    80003ec0:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ec4:	0a0a8963          	beqz	s5,80003f76 <readi+0xf0>
    80003ec8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eca:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ece:	5c7d                	li	s8,-1
    80003ed0:	a82d                	j	80003f0a <readi+0x84>
    80003ed2:	020d1d93          	slli	s11,s10,0x20
    80003ed6:	020ddd93          	srli	s11,s11,0x20
    80003eda:	05890613          	addi	a2,s2,88
    80003ede:	86ee                	mv	a3,s11
    80003ee0:	963a                	add	a2,a2,a4
    80003ee2:	85d2                	mv	a1,s4
    80003ee4:	855e                	mv	a0,s7
    80003ee6:	ffffe097          	auipc	ra,0xffffe
    80003eea:	774080e7          	jalr	1908(ra) # 8000265a <either_copyout>
    80003eee:	05850d63          	beq	a0,s8,80003f48 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ef2:	854a                	mv	a0,s2
    80003ef4:	fffff097          	auipc	ra,0xfffff
    80003ef8:	5fe080e7          	jalr	1534(ra) # 800034f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003efc:	013d09bb          	addw	s3,s10,s3
    80003f00:	009d04bb          	addw	s1,s10,s1
    80003f04:	9a6e                	add	s4,s4,s11
    80003f06:	0559f763          	bgeu	s3,s5,80003f54 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f0a:	00a4d59b          	srliw	a1,s1,0xa
    80003f0e:	855a                	mv	a0,s6
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	8a4080e7          	jalr	-1884(ra) # 800037b4 <bmap>
    80003f18:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f1c:	cd85                	beqz	a1,80003f54 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f1e:	000b2503          	lw	a0,0(s6)
    80003f22:	fffff097          	auipc	ra,0xfffff
    80003f26:	4a0080e7          	jalr	1184(ra) # 800033c2 <bread>
    80003f2a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f2c:	3ff4f713          	andi	a4,s1,1023
    80003f30:	40ec87bb          	subw	a5,s9,a4
    80003f34:	413a86bb          	subw	a3,s5,s3
    80003f38:	8d3e                	mv	s10,a5
    80003f3a:	2781                	sext.w	a5,a5
    80003f3c:	0006861b          	sext.w	a2,a3
    80003f40:	f8f679e3          	bgeu	a2,a5,80003ed2 <readi+0x4c>
    80003f44:	8d36                	mv	s10,a3
    80003f46:	b771                	j	80003ed2 <readi+0x4c>
      brelse(bp);
    80003f48:	854a                	mv	a0,s2
    80003f4a:	fffff097          	auipc	ra,0xfffff
    80003f4e:	5a8080e7          	jalr	1448(ra) # 800034f2 <brelse>
      tot = -1;
    80003f52:	59fd                	li	s3,-1
  }
  return tot;
    80003f54:	0009851b          	sext.w	a0,s3
}
    80003f58:	70a6                	ld	ra,104(sp)
    80003f5a:	7406                	ld	s0,96(sp)
    80003f5c:	64e6                	ld	s1,88(sp)
    80003f5e:	6946                	ld	s2,80(sp)
    80003f60:	69a6                	ld	s3,72(sp)
    80003f62:	6a06                	ld	s4,64(sp)
    80003f64:	7ae2                	ld	s5,56(sp)
    80003f66:	7b42                	ld	s6,48(sp)
    80003f68:	7ba2                	ld	s7,40(sp)
    80003f6a:	7c02                	ld	s8,32(sp)
    80003f6c:	6ce2                	ld	s9,24(sp)
    80003f6e:	6d42                	ld	s10,16(sp)
    80003f70:	6da2                	ld	s11,8(sp)
    80003f72:	6165                	addi	sp,sp,112
    80003f74:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f76:	89d6                	mv	s3,s5
    80003f78:	bff1                	j	80003f54 <readi+0xce>
    return 0;
    80003f7a:	4501                	li	a0,0
}
    80003f7c:	8082                	ret

0000000080003f7e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f7e:	457c                	lw	a5,76(a0)
    80003f80:	10d7e863          	bltu	a5,a3,80004090 <writei+0x112>
{
    80003f84:	7159                	addi	sp,sp,-112
    80003f86:	f486                	sd	ra,104(sp)
    80003f88:	f0a2                	sd	s0,96(sp)
    80003f8a:	eca6                	sd	s1,88(sp)
    80003f8c:	e8ca                	sd	s2,80(sp)
    80003f8e:	e4ce                	sd	s3,72(sp)
    80003f90:	e0d2                	sd	s4,64(sp)
    80003f92:	fc56                	sd	s5,56(sp)
    80003f94:	f85a                	sd	s6,48(sp)
    80003f96:	f45e                	sd	s7,40(sp)
    80003f98:	f062                	sd	s8,32(sp)
    80003f9a:	ec66                	sd	s9,24(sp)
    80003f9c:	e86a                	sd	s10,16(sp)
    80003f9e:	e46e                	sd	s11,8(sp)
    80003fa0:	1880                	addi	s0,sp,112
    80003fa2:	8aaa                	mv	s5,a0
    80003fa4:	8bae                	mv	s7,a1
    80003fa6:	8a32                	mv	s4,a2
    80003fa8:	8936                	mv	s2,a3
    80003faa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fac:	00e687bb          	addw	a5,a3,a4
    80003fb0:	0ed7e263          	bltu	a5,a3,80004094 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fb4:	00043737          	lui	a4,0x43
    80003fb8:	0ef76063          	bltu	a4,a5,80004098 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fbc:	0c0b0863          	beqz	s6,8000408c <writei+0x10e>
    80003fc0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fc2:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fc6:	5c7d                	li	s8,-1
    80003fc8:	a091                	j	8000400c <writei+0x8e>
    80003fca:	020d1d93          	slli	s11,s10,0x20
    80003fce:	020ddd93          	srli	s11,s11,0x20
    80003fd2:	05848513          	addi	a0,s1,88
    80003fd6:	86ee                	mv	a3,s11
    80003fd8:	8652                	mv	a2,s4
    80003fda:	85de                	mv	a1,s7
    80003fdc:	953a                	add	a0,a0,a4
    80003fde:	ffffe097          	auipc	ra,0xffffe
    80003fe2:	6d2080e7          	jalr	1746(ra) # 800026b0 <either_copyin>
    80003fe6:	07850263          	beq	a0,s8,8000404a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fea:	8526                	mv	a0,s1
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	75e080e7          	jalr	1886(ra) # 8000474a <log_write>
    brelse(bp);
    80003ff4:	8526                	mv	a0,s1
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	4fc080e7          	jalr	1276(ra) # 800034f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ffe:	013d09bb          	addw	s3,s10,s3
    80004002:	012d093b          	addw	s2,s10,s2
    80004006:	9a6e                	add	s4,s4,s11
    80004008:	0569f663          	bgeu	s3,s6,80004054 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000400c:	00a9559b          	srliw	a1,s2,0xa
    80004010:	8556                	mv	a0,s5
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	7a2080e7          	jalr	1954(ra) # 800037b4 <bmap>
    8000401a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000401e:	c99d                	beqz	a1,80004054 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004020:	000aa503          	lw	a0,0(s5)
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	39e080e7          	jalr	926(ra) # 800033c2 <bread>
    8000402c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000402e:	3ff97713          	andi	a4,s2,1023
    80004032:	40ec87bb          	subw	a5,s9,a4
    80004036:	413b06bb          	subw	a3,s6,s3
    8000403a:	8d3e                	mv	s10,a5
    8000403c:	2781                	sext.w	a5,a5
    8000403e:	0006861b          	sext.w	a2,a3
    80004042:	f8f674e3          	bgeu	a2,a5,80003fca <writei+0x4c>
    80004046:	8d36                	mv	s10,a3
    80004048:	b749                	j	80003fca <writei+0x4c>
      brelse(bp);
    8000404a:	8526                	mv	a0,s1
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	4a6080e7          	jalr	1190(ra) # 800034f2 <brelse>
  }

  if(off > ip->size)
    80004054:	04caa783          	lw	a5,76(s5)
    80004058:	0127f463          	bgeu	a5,s2,80004060 <writei+0xe2>
    ip->size = off;
    8000405c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004060:	8556                	mv	a0,s5
    80004062:	00000097          	auipc	ra,0x0
    80004066:	aa4080e7          	jalr	-1372(ra) # 80003b06 <iupdate>

  return tot;
    8000406a:	0009851b          	sext.w	a0,s3
}
    8000406e:	70a6                	ld	ra,104(sp)
    80004070:	7406                	ld	s0,96(sp)
    80004072:	64e6                	ld	s1,88(sp)
    80004074:	6946                	ld	s2,80(sp)
    80004076:	69a6                	ld	s3,72(sp)
    80004078:	6a06                	ld	s4,64(sp)
    8000407a:	7ae2                	ld	s5,56(sp)
    8000407c:	7b42                	ld	s6,48(sp)
    8000407e:	7ba2                	ld	s7,40(sp)
    80004080:	7c02                	ld	s8,32(sp)
    80004082:	6ce2                	ld	s9,24(sp)
    80004084:	6d42                	ld	s10,16(sp)
    80004086:	6da2                	ld	s11,8(sp)
    80004088:	6165                	addi	sp,sp,112
    8000408a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000408c:	89da                	mv	s3,s6
    8000408e:	bfc9                	j	80004060 <writei+0xe2>
    return -1;
    80004090:	557d                	li	a0,-1
}
    80004092:	8082                	ret
    return -1;
    80004094:	557d                	li	a0,-1
    80004096:	bfe1                	j	8000406e <writei+0xf0>
    return -1;
    80004098:	557d                	li	a0,-1
    8000409a:	bfd1                	j	8000406e <writei+0xf0>

000000008000409c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000409c:	1141                	addi	sp,sp,-16
    8000409e:	e406                	sd	ra,8(sp)
    800040a0:	e022                	sd	s0,0(sp)
    800040a2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040a4:	4639                	li	a2,14
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	cf8080e7          	jalr	-776(ra) # 80000d9e <strncmp>
}
    800040ae:	60a2                	ld	ra,8(sp)
    800040b0:	6402                	ld	s0,0(sp)
    800040b2:	0141                	addi	sp,sp,16
    800040b4:	8082                	ret

00000000800040b6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040b6:	7139                	addi	sp,sp,-64
    800040b8:	fc06                	sd	ra,56(sp)
    800040ba:	f822                	sd	s0,48(sp)
    800040bc:	f426                	sd	s1,40(sp)
    800040be:	f04a                	sd	s2,32(sp)
    800040c0:	ec4e                	sd	s3,24(sp)
    800040c2:	e852                	sd	s4,16(sp)
    800040c4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040c6:	04451703          	lh	a4,68(a0)
    800040ca:	4785                	li	a5,1
    800040cc:	00f71a63          	bne	a4,a5,800040e0 <dirlookup+0x2a>
    800040d0:	892a                	mv	s2,a0
    800040d2:	89ae                	mv	s3,a1
    800040d4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040d6:	457c                	lw	a5,76(a0)
    800040d8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040da:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040dc:	e79d                	bnez	a5,8000410a <dirlookup+0x54>
    800040de:	a8a5                	j	80004156 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040e0:	00004517          	auipc	a0,0x4
    800040e4:	4b850513          	addi	a0,a0,1208 # 80008598 <syscalls+0x1c0>
    800040e8:	ffffc097          	auipc	ra,0xffffc
    800040ec:	454080e7          	jalr	1108(ra) # 8000053c <panic>
      panic("dirlookup read");
    800040f0:	00004517          	auipc	a0,0x4
    800040f4:	4c050513          	addi	a0,a0,1216 # 800085b0 <syscalls+0x1d8>
    800040f8:	ffffc097          	auipc	ra,0xffffc
    800040fc:	444080e7          	jalr	1092(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004100:	24c1                	addiw	s1,s1,16
    80004102:	04c92783          	lw	a5,76(s2)
    80004106:	04f4f763          	bgeu	s1,a5,80004154 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000410a:	4741                	li	a4,16
    8000410c:	86a6                	mv	a3,s1
    8000410e:	fc040613          	addi	a2,s0,-64
    80004112:	4581                	li	a1,0
    80004114:	854a                	mv	a0,s2
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	d70080e7          	jalr	-656(ra) # 80003e86 <readi>
    8000411e:	47c1                	li	a5,16
    80004120:	fcf518e3          	bne	a0,a5,800040f0 <dirlookup+0x3a>
    if(de.inum == 0)
    80004124:	fc045783          	lhu	a5,-64(s0)
    80004128:	dfe1                	beqz	a5,80004100 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000412a:	fc240593          	addi	a1,s0,-62
    8000412e:	854e                	mv	a0,s3
    80004130:	00000097          	auipc	ra,0x0
    80004134:	f6c080e7          	jalr	-148(ra) # 8000409c <namecmp>
    80004138:	f561                	bnez	a0,80004100 <dirlookup+0x4a>
      if(poff)
    8000413a:	000a0463          	beqz	s4,80004142 <dirlookup+0x8c>
        *poff = off;
    8000413e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004142:	fc045583          	lhu	a1,-64(s0)
    80004146:	00092503          	lw	a0,0(s2)
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	754080e7          	jalr	1876(ra) # 8000389e <iget>
    80004152:	a011                	j	80004156 <dirlookup+0xa0>
  return 0;
    80004154:	4501                	li	a0,0
}
    80004156:	70e2                	ld	ra,56(sp)
    80004158:	7442                	ld	s0,48(sp)
    8000415a:	74a2                	ld	s1,40(sp)
    8000415c:	7902                	ld	s2,32(sp)
    8000415e:	69e2                	ld	s3,24(sp)
    80004160:	6a42                	ld	s4,16(sp)
    80004162:	6121                	addi	sp,sp,64
    80004164:	8082                	ret

0000000080004166 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004166:	711d                	addi	sp,sp,-96
    80004168:	ec86                	sd	ra,88(sp)
    8000416a:	e8a2                	sd	s0,80(sp)
    8000416c:	e4a6                	sd	s1,72(sp)
    8000416e:	e0ca                	sd	s2,64(sp)
    80004170:	fc4e                	sd	s3,56(sp)
    80004172:	f852                	sd	s4,48(sp)
    80004174:	f456                	sd	s5,40(sp)
    80004176:	f05a                	sd	s6,32(sp)
    80004178:	ec5e                	sd	s7,24(sp)
    8000417a:	e862                	sd	s8,16(sp)
    8000417c:	e466                	sd	s9,8(sp)
    8000417e:	1080                	addi	s0,sp,96
    80004180:	84aa                	mv	s1,a0
    80004182:	8b2e                	mv	s6,a1
    80004184:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004186:	00054703          	lbu	a4,0(a0)
    8000418a:	02f00793          	li	a5,47
    8000418e:	02f70263          	beq	a4,a5,800041b2 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004192:	ffffe097          	auipc	ra,0xffffe
    80004196:	814080e7          	jalr	-2028(ra) # 800019a6 <myproc>
    8000419a:	15053503          	ld	a0,336(a0)
    8000419e:	00000097          	auipc	ra,0x0
    800041a2:	9f6080e7          	jalr	-1546(ra) # 80003b94 <idup>
    800041a6:	8a2a                	mv	s4,a0
  while(*path == '/')
    800041a8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800041ac:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041ae:	4b85                	li	s7,1
    800041b0:	a875                	j	8000426c <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800041b2:	4585                	li	a1,1
    800041b4:	4505                	li	a0,1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	6e8080e7          	jalr	1768(ra) # 8000389e <iget>
    800041be:	8a2a                	mv	s4,a0
    800041c0:	b7e5                	j	800041a8 <namex+0x42>
      iunlockput(ip);
    800041c2:	8552                	mv	a0,s4
    800041c4:	00000097          	auipc	ra,0x0
    800041c8:	c70080e7          	jalr	-912(ra) # 80003e34 <iunlockput>
      return 0;
    800041cc:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041ce:	8552                	mv	a0,s4
    800041d0:	60e6                	ld	ra,88(sp)
    800041d2:	6446                	ld	s0,80(sp)
    800041d4:	64a6                	ld	s1,72(sp)
    800041d6:	6906                	ld	s2,64(sp)
    800041d8:	79e2                	ld	s3,56(sp)
    800041da:	7a42                	ld	s4,48(sp)
    800041dc:	7aa2                	ld	s5,40(sp)
    800041de:	7b02                	ld	s6,32(sp)
    800041e0:	6be2                	ld	s7,24(sp)
    800041e2:	6c42                	ld	s8,16(sp)
    800041e4:	6ca2                	ld	s9,8(sp)
    800041e6:	6125                	addi	sp,sp,96
    800041e8:	8082                	ret
      iunlock(ip);
    800041ea:	8552                	mv	a0,s4
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	aa8080e7          	jalr	-1368(ra) # 80003c94 <iunlock>
      return ip;
    800041f4:	bfe9                	j	800041ce <namex+0x68>
      iunlockput(ip);
    800041f6:	8552                	mv	a0,s4
    800041f8:	00000097          	auipc	ra,0x0
    800041fc:	c3c080e7          	jalr	-964(ra) # 80003e34 <iunlockput>
      return 0;
    80004200:	8a4e                	mv	s4,s3
    80004202:	b7f1                	j	800041ce <namex+0x68>
  len = path - s;
    80004204:	40998633          	sub	a2,s3,s1
    80004208:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000420c:	099c5863          	bge	s8,s9,8000429c <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004210:	4639                	li	a2,14
    80004212:	85a6                	mv	a1,s1
    80004214:	8556                	mv	a0,s5
    80004216:	ffffd097          	auipc	ra,0xffffd
    8000421a:	b14080e7          	jalr	-1260(ra) # 80000d2a <memmove>
    8000421e:	84ce                	mv	s1,s3
  while(*path == '/')
    80004220:	0004c783          	lbu	a5,0(s1)
    80004224:	01279763          	bne	a5,s2,80004232 <namex+0xcc>
    path++;
    80004228:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000422a:	0004c783          	lbu	a5,0(s1)
    8000422e:	ff278de3          	beq	a5,s2,80004228 <namex+0xc2>
    ilock(ip);
    80004232:	8552                	mv	a0,s4
    80004234:	00000097          	auipc	ra,0x0
    80004238:	99e080e7          	jalr	-1634(ra) # 80003bd2 <ilock>
    if(ip->type != T_DIR){
    8000423c:	044a1783          	lh	a5,68(s4)
    80004240:	f97791e3          	bne	a5,s7,800041c2 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004244:	000b0563          	beqz	s6,8000424e <namex+0xe8>
    80004248:	0004c783          	lbu	a5,0(s1)
    8000424c:	dfd9                	beqz	a5,800041ea <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000424e:	4601                	li	a2,0
    80004250:	85d6                	mv	a1,s5
    80004252:	8552                	mv	a0,s4
    80004254:	00000097          	auipc	ra,0x0
    80004258:	e62080e7          	jalr	-414(ra) # 800040b6 <dirlookup>
    8000425c:	89aa                	mv	s3,a0
    8000425e:	dd41                	beqz	a0,800041f6 <namex+0x90>
    iunlockput(ip);
    80004260:	8552                	mv	a0,s4
    80004262:	00000097          	auipc	ra,0x0
    80004266:	bd2080e7          	jalr	-1070(ra) # 80003e34 <iunlockput>
    ip = next;
    8000426a:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000426c:	0004c783          	lbu	a5,0(s1)
    80004270:	01279763          	bne	a5,s2,8000427e <namex+0x118>
    path++;
    80004274:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004276:	0004c783          	lbu	a5,0(s1)
    8000427a:	ff278de3          	beq	a5,s2,80004274 <namex+0x10e>
  if(*path == 0)
    8000427e:	cb9d                	beqz	a5,800042b4 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004280:	0004c783          	lbu	a5,0(s1)
    80004284:	89a6                	mv	s3,s1
  len = path - s;
    80004286:	4c81                	li	s9,0
    80004288:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    8000428a:	01278963          	beq	a5,s2,8000429c <namex+0x136>
    8000428e:	dbbd                	beqz	a5,80004204 <namex+0x9e>
    path++;
    80004290:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004292:	0009c783          	lbu	a5,0(s3)
    80004296:	ff279ce3          	bne	a5,s2,8000428e <namex+0x128>
    8000429a:	b7ad                	j	80004204 <namex+0x9e>
    memmove(name, s, len);
    8000429c:	2601                	sext.w	a2,a2
    8000429e:	85a6                	mv	a1,s1
    800042a0:	8556                	mv	a0,s5
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	a88080e7          	jalr	-1400(ra) # 80000d2a <memmove>
    name[len] = 0;
    800042aa:	9cd6                	add	s9,s9,s5
    800042ac:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800042b0:	84ce                	mv	s1,s3
    800042b2:	b7bd                	j	80004220 <namex+0xba>
  if(nameiparent){
    800042b4:	f00b0de3          	beqz	s6,800041ce <namex+0x68>
    iput(ip);
    800042b8:	8552                	mv	a0,s4
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	ad2080e7          	jalr	-1326(ra) # 80003d8c <iput>
    return 0;
    800042c2:	4a01                	li	s4,0
    800042c4:	b729                	j	800041ce <namex+0x68>

00000000800042c6 <dirlink>:
{
    800042c6:	7139                	addi	sp,sp,-64
    800042c8:	fc06                	sd	ra,56(sp)
    800042ca:	f822                	sd	s0,48(sp)
    800042cc:	f426                	sd	s1,40(sp)
    800042ce:	f04a                	sd	s2,32(sp)
    800042d0:	ec4e                	sd	s3,24(sp)
    800042d2:	e852                	sd	s4,16(sp)
    800042d4:	0080                	addi	s0,sp,64
    800042d6:	892a                	mv	s2,a0
    800042d8:	8a2e                	mv	s4,a1
    800042da:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042dc:	4601                	li	a2,0
    800042de:	00000097          	auipc	ra,0x0
    800042e2:	dd8080e7          	jalr	-552(ra) # 800040b6 <dirlookup>
    800042e6:	e93d                	bnez	a0,8000435c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e8:	04c92483          	lw	s1,76(s2)
    800042ec:	c49d                	beqz	s1,8000431a <dirlink+0x54>
    800042ee:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f0:	4741                	li	a4,16
    800042f2:	86a6                	mv	a3,s1
    800042f4:	fc040613          	addi	a2,s0,-64
    800042f8:	4581                	li	a1,0
    800042fa:	854a                	mv	a0,s2
    800042fc:	00000097          	auipc	ra,0x0
    80004300:	b8a080e7          	jalr	-1142(ra) # 80003e86 <readi>
    80004304:	47c1                	li	a5,16
    80004306:	06f51163          	bne	a0,a5,80004368 <dirlink+0xa2>
    if(de.inum == 0)
    8000430a:	fc045783          	lhu	a5,-64(s0)
    8000430e:	c791                	beqz	a5,8000431a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004310:	24c1                	addiw	s1,s1,16
    80004312:	04c92783          	lw	a5,76(s2)
    80004316:	fcf4ede3          	bltu	s1,a5,800042f0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000431a:	4639                	li	a2,14
    8000431c:	85d2                	mv	a1,s4
    8000431e:	fc240513          	addi	a0,s0,-62
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	ab8080e7          	jalr	-1352(ra) # 80000dda <strncpy>
  de.inum = inum;
    8000432a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000432e:	4741                	li	a4,16
    80004330:	86a6                	mv	a3,s1
    80004332:	fc040613          	addi	a2,s0,-64
    80004336:	4581                	li	a1,0
    80004338:	854a                	mv	a0,s2
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	c44080e7          	jalr	-956(ra) # 80003f7e <writei>
    80004342:	1541                	addi	a0,a0,-16
    80004344:	00a03533          	snez	a0,a0
    80004348:	40a00533          	neg	a0,a0
}
    8000434c:	70e2                	ld	ra,56(sp)
    8000434e:	7442                	ld	s0,48(sp)
    80004350:	74a2                	ld	s1,40(sp)
    80004352:	7902                	ld	s2,32(sp)
    80004354:	69e2                	ld	s3,24(sp)
    80004356:	6a42                	ld	s4,16(sp)
    80004358:	6121                	addi	sp,sp,64
    8000435a:	8082                	ret
    iput(ip);
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	a30080e7          	jalr	-1488(ra) # 80003d8c <iput>
    return -1;
    80004364:	557d                	li	a0,-1
    80004366:	b7dd                	j	8000434c <dirlink+0x86>
      panic("dirlink read");
    80004368:	00004517          	auipc	a0,0x4
    8000436c:	25850513          	addi	a0,a0,600 # 800085c0 <syscalls+0x1e8>
    80004370:	ffffc097          	auipc	ra,0xffffc
    80004374:	1cc080e7          	jalr	460(ra) # 8000053c <panic>

0000000080004378 <namei>:

struct inode*
namei(char *path)
{
    80004378:	1101                	addi	sp,sp,-32
    8000437a:	ec06                	sd	ra,24(sp)
    8000437c:	e822                	sd	s0,16(sp)
    8000437e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004380:	fe040613          	addi	a2,s0,-32
    80004384:	4581                	li	a1,0
    80004386:	00000097          	auipc	ra,0x0
    8000438a:	de0080e7          	jalr	-544(ra) # 80004166 <namex>
}
    8000438e:	60e2                	ld	ra,24(sp)
    80004390:	6442                	ld	s0,16(sp)
    80004392:	6105                	addi	sp,sp,32
    80004394:	8082                	ret

0000000080004396 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004396:	1141                	addi	sp,sp,-16
    80004398:	e406                	sd	ra,8(sp)
    8000439a:	e022                	sd	s0,0(sp)
    8000439c:	0800                	addi	s0,sp,16
    8000439e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043a0:	4585                	li	a1,1
    800043a2:	00000097          	auipc	ra,0x0
    800043a6:	dc4080e7          	jalr	-572(ra) # 80004166 <namex>
}
    800043aa:	60a2                	ld	ra,8(sp)
    800043ac:	6402                	ld	s0,0(sp)
    800043ae:	0141                	addi	sp,sp,16
    800043b0:	8082                	ret

00000000800043b2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043b2:	1101                	addi	sp,sp,-32
    800043b4:	ec06                	sd	ra,24(sp)
    800043b6:	e822                	sd	s0,16(sp)
    800043b8:	e426                	sd	s1,8(sp)
    800043ba:	e04a                	sd	s2,0(sp)
    800043bc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043be:	0001f917          	auipc	s2,0x1f
    800043c2:	9b290913          	addi	s2,s2,-1614 # 80022d70 <log>
    800043c6:	01892583          	lw	a1,24(s2)
    800043ca:	02892503          	lw	a0,40(s2)
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	ff4080e7          	jalr	-12(ra) # 800033c2 <bread>
    800043d6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043d8:	02c92603          	lw	a2,44(s2)
    800043dc:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043de:	00c05f63          	blez	a2,800043fc <write_head+0x4a>
    800043e2:	0001f717          	auipc	a4,0x1f
    800043e6:	9be70713          	addi	a4,a4,-1602 # 80022da0 <log+0x30>
    800043ea:	87aa                	mv	a5,a0
    800043ec:	060a                	slli	a2,a2,0x2
    800043ee:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800043f0:	4314                	lw	a3,0(a4)
    800043f2:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800043f4:	0711                	addi	a4,a4,4
    800043f6:	0791                	addi	a5,a5,4
    800043f8:	fec79ce3          	bne	a5,a2,800043f0 <write_head+0x3e>
  }
  bwrite(buf);
    800043fc:	8526                	mv	a0,s1
    800043fe:	fffff097          	auipc	ra,0xfffff
    80004402:	0b6080e7          	jalr	182(ra) # 800034b4 <bwrite>
  brelse(buf);
    80004406:	8526                	mv	a0,s1
    80004408:	fffff097          	auipc	ra,0xfffff
    8000440c:	0ea080e7          	jalr	234(ra) # 800034f2 <brelse>
}
    80004410:	60e2                	ld	ra,24(sp)
    80004412:	6442                	ld	s0,16(sp)
    80004414:	64a2                	ld	s1,8(sp)
    80004416:	6902                	ld	s2,0(sp)
    80004418:	6105                	addi	sp,sp,32
    8000441a:	8082                	ret

000000008000441c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000441c:	0001f797          	auipc	a5,0x1f
    80004420:	9807a783          	lw	a5,-1664(a5) # 80022d9c <log+0x2c>
    80004424:	0af05d63          	blez	a5,800044de <install_trans+0xc2>
{
    80004428:	7139                	addi	sp,sp,-64
    8000442a:	fc06                	sd	ra,56(sp)
    8000442c:	f822                	sd	s0,48(sp)
    8000442e:	f426                	sd	s1,40(sp)
    80004430:	f04a                	sd	s2,32(sp)
    80004432:	ec4e                	sd	s3,24(sp)
    80004434:	e852                	sd	s4,16(sp)
    80004436:	e456                	sd	s5,8(sp)
    80004438:	e05a                	sd	s6,0(sp)
    8000443a:	0080                	addi	s0,sp,64
    8000443c:	8b2a                	mv	s6,a0
    8000443e:	0001fa97          	auipc	s5,0x1f
    80004442:	962a8a93          	addi	s5,s5,-1694 # 80022da0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004446:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004448:	0001f997          	auipc	s3,0x1f
    8000444c:	92898993          	addi	s3,s3,-1752 # 80022d70 <log>
    80004450:	a00d                	j	80004472 <install_trans+0x56>
    brelse(lbuf);
    80004452:	854a                	mv	a0,s2
    80004454:	fffff097          	auipc	ra,0xfffff
    80004458:	09e080e7          	jalr	158(ra) # 800034f2 <brelse>
    brelse(dbuf);
    8000445c:	8526                	mv	a0,s1
    8000445e:	fffff097          	auipc	ra,0xfffff
    80004462:	094080e7          	jalr	148(ra) # 800034f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004466:	2a05                	addiw	s4,s4,1
    80004468:	0a91                	addi	s5,s5,4
    8000446a:	02c9a783          	lw	a5,44(s3)
    8000446e:	04fa5e63          	bge	s4,a5,800044ca <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004472:	0189a583          	lw	a1,24(s3)
    80004476:	014585bb          	addw	a1,a1,s4
    8000447a:	2585                	addiw	a1,a1,1
    8000447c:	0289a503          	lw	a0,40(s3)
    80004480:	fffff097          	auipc	ra,0xfffff
    80004484:	f42080e7          	jalr	-190(ra) # 800033c2 <bread>
    80004488:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000448a:	000aa583          	lw	a1,0(s5)
    8000448e:	0289a503          	lw	a0,40(s3)
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	f30080e7          	jalr	-208(ra) # 800033c2 <bread>
    8000449a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000449c:	40000613          	li	a2,1024
    800044a0:	05890593          	addi	a1,s2,88
    800044a4:	05850513          	addi	a0,a0,88
    800044a8:	ffffd097          	auipc	ra,0xffffd
    800044ac:	882080e7          	jalr	-1918(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    800044b0:	8526                	mv	a0,s1
    800044b2:	fffff097          	auipc	ra,0xfffff
    800044b6:	002080e7          	jalr	2(ra) # 800034b4 <bwrite>
    if(recovering == 0)
    800044ba:	f80b1ce3          	bnez	s6,80004452 <install_trans+0x36>
      bunpin(dbuf);
    800044be:	8526                	mv	a0,s1
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	10a080e7          	jalr	266(ra) # 800035ca <bunpin>
    800044c8:	b769                	j	80004452 <install_trans+0x36>
}
    800044ca:	70e2                	ld	ra,56(sp)
    800044cc:	7442                	ld	s0,48(sp)
    800044ce:	74a2                	ld	s1,40(sp)
    800044d0:	7902                	ld	s2,32(sp)
    800044d2:	69e2                	ld	s3,24(sp)
    800044d4:	6a42                	ld	s4,16(sp)
    800044d6:	6aa2                	ld	s5,8(sp)
    800044d8:	6b02                	ld	s6,0(sp)
    800044da:	6121                	addi	sp,sp,64
    800044dc:	8082                	ret
    800044de:	8082                	ret

00000000800044e0 <initlog>:
{
    800044e0:	7179                	addi	sp,sp,-48
    800044e2:	f406                	sd	ra,40(sp)
    800044e4:	f022                	sd	s0,32(sp)
    800044e6:	ec26                	sd	s1,24(sp)
    800044e8:	e84a                	sd	s2,16(sp)
    800044ea:	e44e                	sd	s3,8(sp)
    800044ec:	1800                	addi	s0,sp,48
    800044ee:	892a                	mv	s2,a0
    800044f0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044f2:	0001f497          	auipc	s1,0x1f
    800044f6:	87e48493          	addi	s1,s1,-1922 # 80022d70 <log>
    800044fa:	00004597          	auipc	a1,0x4
    800044fe:	0d658593          	addi	a1,a1,214 # 800085d0 <syscalls+0x1f8>
    80004502:	8526                	mv	a0,s1
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	63e080e7          	jalr	1598(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    8000450c:	0149a583          	lw	a1,20(s3)
    80004510:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004512:	0109a783          	lw	a5,16(s3)
    80004516:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004518:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000451c:	854a                	mv	a0,s2
    8000451e:	fffff097          	auipc	ra,0xfffff
    80004522:	ea4080e7          	jalr	-348(ra) # 800033c2 <bread>
  log.lh.n = lh->n;
    80004526:	4d30                	lw	a2,88(a0)
    80004528:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000452a:	00c05f63          	blez	a2,80004548 <initlog+0x68>
    8000452e:	87aa                	mv	a5,a0
    80004530:	0001f717          	auipc	a4,0x1f
    80004534:	87070713          	addi	a4,a4,-1936 # 80022da0 <log+0x30>
    80004538:	060a                	slli	a2,a2,0x2
    8000453a:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000453c:	4ff4                	lw	a3,92(a5)
    8000453e:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004540:	0791                	addi	a5,a5,4
    80004542:	0711                	addi	a4,a4,4
    80004544:	fec79ce3          	bne	a5,a2,8000453c <initlog+0x5c>
  brelse(buf);
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	faa080e7          	jalr	-86(ra) # 800034f2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004550:	4505                	li	a0,1
    80004552:	00000097          	auipc	ra,0x0
    80004556:	eca080e7          	jalr	-310(ra) # 8000441c <install_trans>
  log.lh.n = 0;
    8000455a:	0001f797          	auipc	a5,0x1f
    8000455e:	8407a123          	sw	zero,-1982(a5) # 80022d9c <log+0x2c>
  write_head(); // clear the log
    80004562:	00000097          	auipc	ra,0x0
    80004566:	e50080e7          	jalr	-432(ra) # 800043b2 <write_head>
}
    8000456a:	70a2                	ld	ra,40(sp)
    8000456c:	7402                	ld	s0,32(sp)
    8000456e:	64e2                	ld	s1,24(sp)
    80004570:	6942                	ld	s2,16(sp)
    80004572:	69a2                	ld	s3,8(sp)
    80004574:	6145                	addi	sp,sp,48
    80004576:	8082                	ret

0000000080004578 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004578:	1101                	addi	sp,sp,-32
    8000457a:	ec06                	sd	ra,24(sp)
    8000457c:	e822                	sd	s0,16(sp)
    8000457e:	e426                	sd	s1,8(sp)
    80004580:	e04a                	sd	s2,0(sp)
    80004582:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004584:	0001e517          	auipc	a0,0x1e
    80004588:	7ec50513          	addi	a0,a0,2028 # 80022d70 <log>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	646080e7          	jalr	1606(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004594:	0001e497          	auipc	s1,0x1e
    80004598:	7dc48493          	addi	s1,s1,2012 # 80022d70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000459c:	4979                	li	s2,30
    8000459e:	a039                	j	800045ac <begin_op+0x34>
      sleep(&log, &log.lock);
    800045a0:	85a6                	mv	a1,s1
    800045a2:	8526                	mv	a0,s1
    800045a4:	ffffe097          	auipc	ra,0xffffe
    800045a8:	ca2080e7          	jalr	-862(ra) # 80002246 <sleep>
    if(log.committing){
    800045ac:	50dc                	lw	a5,36(s1)
    800045ae:	fbed                	bnez	a5,800045a0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045b0:	5098                	lw	a4,32(s1)
    800045b2:	2705                	addiw	a4,a4,1
    800045b4:	0027179b          	slliw	a5,a4,0x2
    800045b8:	9fb9                	addw	a5,a5,a4
    800045ba:	0017979b          	slliw	a5,a5,0x1
    800045be:	54d4                	lw	a3,44(s1)
    800045c0:	9fb5                	addw	a5,a5,a3
    800045c2:	00f95963          	bge	s2,a5,800045d4 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045c6:	85a6                	mv	a1,s1
    800045c8:	8526                	mv	a0,s1
    800045ca:	ffffe097          	auipc	ra,0xffffe
    800045ce:	c7c080e7          	jalr	-900(ra) # 80002246 <sleep>
    800045d2:	bfe9                	j	800045ac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045d4:	0001e517          	auipc	a0,0x1e
    800045d8:	79c50513          	addi	a0,a0,1948 # 80022d70 <log>
    800045dc:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	6a8080e7          	jalr	1704(ra) # 80000c86 <release>
      break;
    }
  }
}
    800045e6:	60e2                	ld	ra,24(sp)
    800045e8:	6442                	ld	s0,16(sp)
    800045ea:	64a2                	ld	s1,8(sp)
    800045ec:	6902                	ld	s2,0(sp)
    800045ee:	6105                	addi	sp,sp,32
    800045f0:	8082                	ret

00000000800045f2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045f2:	7139                	addi	sp,sp,-64
    800045f4:	fc06                	sd	ra,56(sp)
    800045f6:	f822                	sd	s0,48(sp)
    800045f8:	f426                	sd	s1,40(sp)
    800045fa:	f04a                	sd	s2,32(sp)
    800045fc:	ec4e                	sd	s3,24(sp)
    800045fe:	e852                	sd	s4,16(sp)
    80004600:	e456                	sd	s5,8(sp)
    80004602:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004604:	0001e497          	auipc	s1,0x1e
    80004608:	76c48493          	addi	s1,s1,1900 # 80022d70 <log>
    8000460c:	8526                	mv	a0,s1
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	5c4080e7          	jalr	1476(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004616:	509c                	lw	a5,32(s1)
    80004618:	37fd                	addiw	a5,a5,-1
    8000461a:	0007891b          	sext.w	s2,a5
    8000461e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004620:	50dc                	lw	a5,36(s1)
    80004622:	e7b9                	bnez	a5,80004670 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004624:	04091e63          	bnez	s2,80004680 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004628:	0001e497          	auipc	s1,0x1e
    8000462c:	74848493          	addi	s1,s1,1864 # 80022d70 <log>
    80004630:	4785                	li	a5,1
    80004632:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004634:	8526                	mv	a0,s1
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	650080e7          	jalr	1616(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000463e:	54dc                	lw	a5,44(s1)
    80004640:	06f04763          	bgtz	a5,800046ae <end_op+0xbc>
    acquire(&log.lock);
    80004644:	0001e497          	auipc	s1,0x1e
    80004648:	72c48493          	addi	s1,s1,1836 # 80022d70 <log>
    8000464c:	8526                	mv	a0,s1
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	584080e7          	jalr	1412(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004656:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000465a:	8526                	mv	a0,s1
    8000465c:	ffffe097          	auipc	ra,0xffffe
    80004660:	c4e080e7          	jalr	-946(ra) # 800022aa <wakeup>
    release(&log.lock);
    80004664:	8526                	mv	a0,s1
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	620080e7          	jalr	1568(ra) # 80000c86 <release>
}
    8000466e:	a03d                	j	8000469c <end_op+0xaa>
    panic("log.committing");
    80004670:	00004517          	auipc	a0,0x4
    80004674:	f6850513          	addi	a0,a0,-152 # 800085d8 <syscalls+0x200>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	ec4080e7          	jalr	-316(ra) # 8000053c <panic>
    wakeup(&log);
    80004680:	0001e497          	auipc	s1,0x1e
    80004684:	6f048493          	addi	s1,s1,1776 # 80022d70 <log>
    80004688:	8526                	mv	a0,s1
    8000468a:	ffffe097          	auipc	ra,0xffffe
    8000468e:	c20080e7          	jalr	-992(ra) # 800022aa <wakeup>
  release(&log.lock);
    80004692:	8526                	mv	a0,s1
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	5f2080e7          	jalr	1522(ra) # 80000c86 <release>
}
    8000469c:	70e2                	ld	ra,56(sp)
    8000469e:	7442                	ld	s0,48(sp)
    800046a0:	74a2                	ld	s1,40(sp)
    800046a2:	7902                	ld	s2,32(sp)
    800046a4:	69e2                	ld	s3,24(sp)
    800046a6:	6a42                	ld	s4,16(sp)
    800046a8:	6aa2                	ld	s5,8(sp)
    800046aa:	6121                	addi	sp,sp,64
    800046ac:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ae:	0001ea97          	auipc	s5,0x1e
    800046b2:	6f2a8a93          	addi	s5,s5,1778 # 80022da0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046b6:	0001ea17          	auipc	s4,0x1e
    800046ba:	6baa0a13          	addi	s4,s4,1722 # 80022d70 <log>
    800046be:	018a2583          	lw	a1,24(s4)
    800046c2:	012585bb          	addw	a1,a1,s2
    800046c6:	2585                	addiw	a1,a1,1
    800046c8:	028a2503          	lw	a0,40(s4)
    800046cc:	fffff097          	auipc	ra,0xfffff
    800046d0:	cf6080e7          	jalr	-778(ra) # 800033c2 <bread>
    800046d4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046d6:	000aa583          	lw	a1,0(s5)
    800046da:	028a2503          	lw	a0,40(s4)
    800046de:	fffff097          	auipc	ra,0xfffff
    800046e2:	ce4080e7          	jalr	-796(ra) # 800033c2 <bread>
    800046e6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046e8:	40000613          	li	a2,1024
    800046ec:	05850593          	addi	a1,a0,88
    800046f0:	05848513          	addi	a0,s1,88
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	636080e7          	jalr	1590(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800046fc:	8526                	mv	a0,s1
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	db6080e7          	jalr	-586(ra) # 800034b4 <bwrite>
    brelse(from);
    80004706:	854e                	mv	a0,s3
    80004708:	fffff097          	auipc	ra,0xfffff
    8000470c:	dea080e7          	jalr	-534(ra) # 800034f2 <brelse>
    brelse(to);
    80004710:	8526                	mv	a0,s1
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	de0080e7          	jalr	-544(ra) # 800034f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000471a:	2905                	addiw	s2,s2,1
    8000471c:	0a91                	addi	s5,s5,4
    8000471e:	02ca2783          	lw	a5,44(s4)
    80004722:	f8f94ee3          	blt	s2,a5,800046be <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004726:	00000097          	auipc	ra,0x0
    8000472a:	c8c080e7          	jalr	-884(ra) # 800043b2 <write_head>
    install_trans(0); // Now install writes to home locations
    8000472e:	4501                	li	a0,0
    80004730:	00000097          	auipc	ra,0x0
    80004734:	cec080e7          	jalr	-788(ra) # 8000441c <install_trans>
    log.lh.n = 0;
    80004738:	0001e797          	auipc	a5,0x1e
    8000473c:	6607a223          	sw	zero,1636(a5) # 80022d9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004740:	00000097          	auipc	ra,0x0
    80004744:	c72080e7          	jalr	-910(ra) # 800043b2 <write_head>
    80004748:	bdf5                	j	80004644 <end_op+0x52>

000000008000474a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000474a:	1101                	addi	sp,sp,-32
    8000474c:	ec06                	sd	ra,24(sp)
    8000474e:	e822                	sd	s0,16(sp)
    80004750:	e426                	sd	s1,8(sp)
    80004752:	e04a                	sd	s2,0(sp)
    80004754:	1000                	addi	s0,sp,32
    80004756:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004758:	0001e917          	auipc	s2,0x1e
    8000475c:	61890913          	addi	s2,s2,1560 # 80022d70 <log>
    80004760:	854a                	mv	a0,s2
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	470080e7          	jalr	1136(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000476a:	02c92603          	lw	a2,44(s2)
    8000476e:	47f5                	li	a5,29
    80004770:	06c7c563          	blt	a5,a2,800047da <log_write+0x90>
    80004774:	0001e797          	auipc	a5,0x1e
    80004778:	6187a783          	lw	a5,1560(a5) # 80022d8c <log+0x1c>
    8000477c:	37fd                	addiw	a5,a5,-1
    8000477e:	04f65e63          	bge	a2,a5,800047da <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004782:	0001e797          	auipc	a5,0x1e
    80004786:	60e7a783          	lw	a5,1550(a5) # 80022d90 <log+0x20>
    8000478a:	06f05063          	blez	a5,800047ea <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000478e:	4781                	li	a5,0
    80004790:	06c05563          	blez	a2,800047fa <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004794:	44cc                	lw	a1,12(s1)
    80004796:	0001e717          	auipc	a4,0x1e
    8000479a:	60a70713          	addi	a4,a4,1546 # 80022da0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000479e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047a0:	4314                	lw	a3,0(a4)
    800047a2:	04b68c63          	beq	a3,a1,800047fa <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047a6:	2785                	addiw	a5,a5,1
    800047a8:	0711                	addi	a4,a4,4
    800047aa:	fef61be3          	bne	a2,a5,800047a0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047ae:	0621                	addi	a2,a2,8
    800047b0:	060a                	slli	a2,a2,0x2
    800047b2:	0001e797          	auipc	a5,0x1e
    800047b6:	5be78793          	addi	a5,a5,1470 # 80022d70 <log>
    800047ba:	97b2                	add	a5,a5,a2
    800047bc:	44d8                	lw	a4,12(s1)
    800047be:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047c0:	8526                	mv	a0,s1
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	dcc080e7          	jalr	-564(ra) # 8000358e <bpin>
    log.lh.n++;
    800047ca:	0001e717          	auipc	a4,0x1e
    800047ce:	5a670713          	addi	a4,a4,1446 # 80022d70 <log>
    800047d2:	575c                	lw	a5,44(a4)
    800047d4:	2785                	addiw	a5,a5,1
    800047d6:	d75c                	sw	a5,44(a4)
    800047d8:	a82d                	j	80004812 <log_write+0xc8>
    panic("too big a transaction");
    800047da:	00004517          	auipc	a0,0x4
    800047de:	e0e50513          	addi	a0,a0,-498 # 800085e8 <syscalls+0x210>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	d5a080e7          	jalr	-678(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800047ea:	00004517          	auipc	a0,0x4
    800047ee:	e1650513          	addi	a0,a0,-490 # 80008600 <syscalls+0x228>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	d4a080e7          	jalr	-694(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800047fa:	00878693          	addi	a3,a5,8
    800047fe:	068a                	slli	a3,a3,0x2
    80004800:	0001e717          	auipc	a4,0x1e
    80004804:	57070713          	addi	a4,a4,1392 # 80022d70 <log>
    80004808:	9736                	add	a4,a4,a3
    8000480a:	44d4                	lw	a3,12(s1)
    8000480c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000480e:	faf609e3          	beq	a2,a5,800047c0 <log_write+0x76>
  }
  release(&log.lock);
    80004812:	0001e517          	auipc	a0,0x1e
    80004816:	55e50513          	addi	a0,a0,1374 # 80022d70 <log>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	46c080e7          	jalr	1132(ra) # 80000c86 <release>
}
    80004822:	60e2                	ld	ra,24(sp)
    80004824:	6442                	ld	s0,16(sp)
    80004826:	64a2                	ld	s1,8(sp)
    80004828:	6902                	ld	s2,0(sp)
    8000482a:	6105                	addi	sp,sp,32
    8000482c:	8082                	ret

000000008000482e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000482e:	1101                	addi	sp,sp,-32
    80004830:	ec06                	sd	ra,24(sp)
    80004832:	e822                	sd	s0,16(sp)
    80004834:	e426                	sd	s1,8(sp)
    80004836:	e04a                	sd	s2,0(sp)
    80004838:	1000                	addi	s0,sp,32
    8000483a:	84aa                	mv	s1,a0
    8000483c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000483e:	00004597          	auipc	a1,0x4
    80004842:	de258593          	addi	a1,a1,-542 # 80008620 <syscalls+0x248>
    80004846:	0521                	addi	a0,a0,8
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	2fa080e7          	jalr	762(ra) # 80000b42 <initlock>
  lk->name = name;
    80004850:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004854:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004858:	0204a423          	sw	zero,40(s1)
}
    8000485c:	60e2                	ld	ra,24(sp)
    8000485e:	6442                	ld	s0,16(sp)
    80004860:	64a2                	ld	s1,8(sp)
    80004862:	6902                	ld	s2,0(sp)
    80004864:	6105                	addi	sp,sp,32
    80004866:	8082                	ret

0000000080004868 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004868:	1101                	addi	sp,sp,-32
    8000486a:	ec06                	sd	ra,24(sp)
    8000486c:	e822                	sd	s0,16(sp)
    8000486e:	e426                	sd	s1,8(sp)
    80004870:	e04a                	sd	s2,0(sp)
    80004872:	1000                	addi	s0,sp,32
    80004874:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004876:	00850913          	addi	s2,a0,8
    8000487a:	854a                	mv	a0,s2
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	356080e7          	jalr	854(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004884:	409c                	lw	a5,0(s1)
    80004886:	cb89                	beqz	a5,80004898 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004888:	85ca                	mv	a1,s2
    8000488a:	8526                	mv	a0,s1
    8000488c:	ffffe097          	auipc	ra,0xffffe
    80004890:	9ba080e7          	jalr	-1606(ra) # 80002246 <sleep>
  while (lk->locked) {
    80004894:	409c                	lw	a5,0(s1)
    80004896:	fbed                	bnez	a5,80004888 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004898:	4785                	li	a5,1
    8000489a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000489c:	ffffd097          	auipc	ra,0xffffd
    800048a0:	10a080e7          	jalr	266(ra) # 800019a6 <myproc>
    800048a4:	591c                	lw	a5,48(a0)
    800048a6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048a8:	854a                	mv	a0,s2
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	3dc080e7          	jalr	988(ra) # 80000c86 <release>
}
    800048b2:	60e2                	ld	ra,24(sp)
    800048b4:	6442                	ld	s0,16(sp)
    800048b6:	64a2                	ld	s1,8(sp)
    800048b8:	6902                	ld	s2,0(sp)
    800048ba:	6105                	addi	sp,sp,32
    800048bc:	8082                	ret

00000000800048be <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048be:	1101                	addi	sp,sp,-32
    800048c0:	ec06                	sd	ra,24(sp)
    800048c2:	e822                	sd	s0,16(sp)
    800048c4:	e426                	sd	s1,8(sp)
    800048c6:	e04a                	sd	s2,0(sp)
    800048c8:	1000                	addi	s0,sp,32
    800048ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048cc:	00850913          	addi	s2,a0,8
    800048d0:	854a                	mv	a0,s2
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	300080e7          	jalr	768(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    800048da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048de:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048e2:	8526                	mv	a0,s1
    800048e4:	ffffe097          	auipc	ra,0xffffe
    800048e8:	9c6080e7          	jalr	-1594(ra) # 800022aa <wakeup>
  release(&lk->lk);
    800048ec:	854a                	mv	a0,s2
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	398080e7          	jalr	920(ra) # 80000c86 <release>
}
    800048f6:	60e2                	ld	ra,24(sp)
    800048f8:	6442                	ld	s0,16(sp)
    800048fa:	64a2                	ld	s1,8(sp)
    800048fc:	6902                	ld	s2,0(sp)
    800048fe:	6105                	addi	sp,sp,32
    80004900:	8082                	ret

0000000080004902 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004902:	7179                	addi	sp,sp,-48
    80004904:	f406                	sd	ra,40(sp)
    80004906:	f022                	sd	s0,32(sp)
    80004908:	ec26                	sd	s1,24(sp)
    8000490a:	e84a                	sd	s2,16(sp)
    8000490c:	e44e                	sd	s3,8(sp)
    8000490e:	1800                	addi	s0,sp,48
    80004910:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004912:	00850913          	addi	s2,a0,8
    80004916:	854a                	mv	a0,s2
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	2ba080e7          	jalr	698(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004920:	409c                	lw	a5,0(s1)
    80004922:	ef99                	bnez	a5,80004940 <holdingsleep+0x3e>
    80004924:	4481                	li	s1,0
  release(&lk->lk);
    80004926:	854a                	mv	a0,s2
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	35e080e7          	jalr	862(ra) # 80000c86 <release>
  return r;
}
    80004930:	8526                	mv	a0,s1
    80004932:	70a2                	ld	ra,40(sp)
    80004934:	7402                	ld	s0,32(sp)
    80004936:	64e2                	ld	s1,24(sp)
    80004938:	6942                	ld	s2,16(sp)
    8000493a:	69a2                	ld	s3,8(sp)
    8000493c:	6145                	addi	sp,sp,48
    8000493e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004940:	0284a983          	lw	s3,40(s1)
    80004944:	ffffd097          	auipc	ra,0xffffd
    80004948:	062080e7          	jalr	98(ra) # 800019a6 <myproc>
    8000494c:	5904                	lw	s1,48(a0)
    8000494e:	413484b3          	sub	s1,s1,s3
    80004952:	0014b493          	seqz	s1,s1
    80004956:	bfc1                	j	80004926 <holdingsleep+0x24>

0000000080004958 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004958:	1141                	addi	sp,sp,-16
    8000495a:	e406                	sd	ra,8(sp)
    8000495c:	e022                	sd	s0,0(sp)
    8000495e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004960:	00004597          	auipc	a1,0x4
    80004964:	cd058593          	addi	a1,a1,-816 # 80008630 <syscalls+0x258>
    80004968:	0001e517          	auipc	a0,0x1e
    8000496c:	55050513          	addi	a0,a0,1360 # 80022eb8 <ftable>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	1d2080e7          	jalr	466(ra) # 80000b42 <initlock>
}
    80004978:	60a2                	ld	ra,8(sp)
    8000497a:	6402                	ld	s0,0(sp)
    8000497c:	0141                	addi	sp,sp,16
    8000497e:	8082                	ret

0000000080004980 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004980:	1101                	addi	sp,sp,-32
    80004982:	ec06                	sd	ra,24(sp)
    80004984:	e822                	sd	s0,16(sp)
    80004986:	e426                	sd	s1,8(sp)
    80004988:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000498a:	0001e517          	auipc	a0,0x1e
    8000498e:	52e50513          	addi	a0,a0,1326 # 80022eb8 <ftable>
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	240080e7          	jalr	576(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000499a:	0001e497          	auipc	s1,0x1e
    8000499e:	53648493          	addi	s1,s1,1334 # 80022ed0 <ftable+0x18>
    800049a2:	0001f717          	auipc	a4,0x1f
    800049a6:	4ce70713          	addi	a4,a4,1230 # 80023e70 <disk>
    if(f->ref == 0){
    800049aa:	40dc                	lw	a5,4(s1)
    800049ac:	cf99                	beqz	a5,800049ca <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049ae:	02848493          	addi	s1,s1,40
    800049b2:	fee49ce3          	bne	s1,a4,800049aa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049b6:	0001e517          	auipc	a0,0x1e
    800049ba:	50250513          	addi	a0,a0,1282 # 80022eb8 <ftable>
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	2c8080e7          	jalr	712(ra) # 80000c86 <release>
  return 0;
    800049c6:	4481                	li	s1,0
    800049c8:	a819                	j	800049de <filealloc+0x5e>
      f->ref = 1;
    800049ca:	4785                	li	a5,1
    800049cc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049ce:	0001e517          	auipc	a0,0x1e
    800049d2:	4ea50513          	addi	a0,a0,1258 # 80022eb8 <ftable>
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	2b0080e7          	jalr	688(ra) # 80000c86 <release>
}
    800049de:	8526                	mv	a0,s1
    800049e0:	60e2                	ld	ra,24(sp)
    800049e2:	6442                	ld	s0,16(sp)
    800049e4:	64a2                	ld	s1,8(sp)
    800049e6:	6105                	addi	sp,sp,32
    800049e8:	8082                	ret

00000000800049ea <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049ea:	1101                	addi	sp,sp,-32
    800049ec:	ec06                	sd	ra,24(sp)
    800049ee:	e822                	sd	s0,16(sp)
    800049f0:	e426                	sd	s1,8(sp)
    800049f2:	1000                	addi	s0,sp,32
    800049f4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049f6:	0001e517          	auipc	a0,0x1e
    800049fa:	4c250513          	addi	a0,a0,1218 # 80022eb8 <ftable>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	1d4080e7          	jalr	468(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004a06:	40dc                	lw	a5,4(s1)
    80004a08:	02f05263          	blez	a5,80004a2c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a0c:	2785                	addiw	a5,a5,1
    80004a0e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a10:	0001e517          	auipc	a0,0x1e
    80004a14:	4a850513          	addi	a0,a0,1192 # 80022eb8 <ftable>
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	26e080e7          	jalr	622(ra) # 80000c86 <release>
  return f;
}
    80004a20:	8526                	mv	a0,s1
    80004a22:	60e2                	ld	ra,24(sp)
    80004a24:	6442                	ld	s0,16(sp)
    80004a26:	64a2                	ld	s1,8(sp)
    80004a28:	6105                	addi	sp,sp,32
    80004a2a:	8082                	ret
    panic("filedup");
    80004a2c:	00004517          	auipc	a0,0x4
    80004a30:	c0c50513          	addi	a0,a0,-1012 # 80008638 <syscalls+0x260>
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	b08080e7          	jalr	-1272(ra) # 8000053c <panic>

0000000080004a3c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a3c:	7139                	addi	sp,sp,-64
    80004a3e:	fc06                	sd	ra,56(sp)
    80004a40:	f822                	sd	s0,48(sp)
    80004a42:	f426                	sd	s1,40(sp)
    80004a44:	f04a                	sd	s2,32(sp)
    80004a46:	ec4e                	sd	s3,24(sp)
    80004a48:	e852                	sd	s4,16(sp)
    80004a4a:	e456                	sd	s5,8(sp)
    80004a4c:	0080                	addi	s0,sp,64
    80004a4e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a50:	0001e517          	auipc	a0,0x1e
    80004a54:	46850513          	addi	a0,a0,1128 # 80022eb8 <ftable>
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	17a080e7          	jalr	378(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004a60:	40dc                	lw	a5,4(s1)
    80004a62:	06f05163          	blez	a5,80004ac4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a66:	37fd                	addiw	a5,a5,-1
    80004a68:	0007871b          	sext.w	a4,a5
    80004a6c:	c0dc                	sw	a5,4(s1)
    80004a6e:	06e04363          	bgtz	a4,80004ad4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a72:	0004a903          	lw	s2,0(s1)
    80004a76:	0094ca83          	lbu	s5,9(s1)
    80004a7a:	0104ba03          	ld	s4,16(s1)
    80004a7e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a82:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a86:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a8a:	0001e517          	auipc	a0,0x1e
    80004a8e:	42e50513          	addi	a0,a0,1070 # 80022eb8 <ftable>
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	1f4080e7          	jalr	500(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004a9a:	4785                	li	a5,1
    80004a9c:	04f90d63          	beq	s2,a5,80004af6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004aa0:	3979                	addiw	s2,s2,-2
    80004aa2:	4785                	li	a5,1
    80004aa4:	0527e063          	bltu	a5,s2,80004ae4 <fileclose+0xa8>
    begin_op();
    80004aa8:	00000097          	auipc	ra,0x0
    80004aac:	ad0080e7          	jalr	-1328(ra) # 80004578 <begin_op>
    iput(ff.ip);
    80004ab0:	854e                	mv	a0,s3
    80004ab2:	fffff097          	auipc	ra,0xfffff
    80004ab6:	2da080e7          	jalr	730(ra) # 80003d8c <iput>
    end_op();
    80004aba:	00000097          	auipc	ra,0x0
    80004abe:	b38080e7          	jalr	-1224(ra) # 800045f2 <end_op>
    80004ac2:	a00d                	j	80004ae4 <fileclose+0xa8>
    panic("fileclose");
    80004ac4:	00004517          	auipc	a0,0x4
    80004ac8:	b7c50513          	addi	a0,a0,-1156 # 80008640 <syscalls+0x268>
    80004acc:	ffffc097          	auipc	ra,0xffffc
    80004ad0:	a70080e7          	jalr	-1424(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004ad4:	0001e517          	auipc	a0,0x1e
    80004ad8:	3e450513          	addi	a0,a0,996 # 80022eb8 <ftable>
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	1aa080e7          	jalr	426(ra) # 80000c86 <release>
  }
}
    80004ae4:	70e2                	ld	ra,56(sp)
    80004ae6:	7442                	ld	s0,48(sp)
    80004ae8:	74a2                	ld	s1,40(sp)
    80004aea:	7902                	ld	s2,32(sp)
    80004aec:	69e2                	ld	s3,24(sp)
    80004aee:	6a42                	ld	s4,16(sp)
    80004af0:	6aa2                	ld	s5,8(sp)
    80004af2:	6121                	addi	sp,sp,64
    80004af4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004af6:	85d6                	mv	a1,s5
    80004af8:	8552                	mv	a0,s4
    80004afa:	00000097          	auipc	ra,0x0
    80004afe:	348080e7          	jalr	840(ra) # 80004e42 <pipeclose>
    80004b02:	b7cd                	j	80004ae4 <fileclose+0xa8>

0000000080004b04 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b04:	715d                	addi	sp,sp,-80
    80004b06:	e486                	sd	ra,72(sp)
    80004b08:	e0a2                	sd	s0,64(sp)
    80004b0a:	fc26                	sd	s1,56(sp)
    80004b0c:	f84a                	sd	s2,48(sp)
    80004b0e:	f44e                	sd	s3,40(sp)
    80004b10:	0880                	addi	s0,sp,80
    80004b12:	84aa                	mv	s1,a0
    80004b14:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b16:	ffffd097          	auipc	ra,0xffffd
    80004b1a:	e90080e7          	jalr	-368(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b1e:	409c                	lw	a5,0(s1)
    80004b20:	37f9                	addiw	a5,a5,-2
    80004b22:	4705                	li	a4,1
    80004b24:	04f76763          	bltu	a4,a5,80004b72 <filestat+0x6e>
    80004b28:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b2a:	6c88                	ld	a0,24(s1)
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	0a6080e7          	jalr	166(ra) # 80003bd2 <ilock>
    stati(f->ip, &st);
    80004b34:	fb840593          	addi	a1,s0,-72
    80004b38:	6c88                	ld	a0,24(s1)
    80004b3a:	fffff097          	auipc	ra,0xfffff
    80004b3e:	322080e7          	jalr	802(ra) # 80003e5c <stati>
    iunlock(f->ip);
    80004b42:	6c88                	ld	a0,24(s1)
    80004b44:	fffff097          	auipc	ra,0xfffff
    80004b48:	150080e7          	jalr	336(ra) # 80003c94 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b4c:	46e1                	li	a3,24
    80004b4e:	fb840613          	addi	a2,s0,-72
    80004b52:	85ce                	mv	a1,s3
    80004b54:	05093503          	ld	a0,80(s2)
    80004b58:	ffffd097          	auipc	ra,0xffffd
    80004b5c:	b0e080e7          	jalr	-1266(ra) # 80001666 <copyout>
    80004b60:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b64:	60a6                	ld	ra,72(sp)
    80004b66:	6406                	ld	s0,64(sp)
    80004b68:	74e2                	ld	s1,56(sp)
    80004b6a:	7942                	ld	s2,48(sp)
    80004b6c:	79a2                	ld	s3,40(sp)
    80004b6e:	6161                	addi	sp,sp,80
    80004b70:	8082                	ret
  return -1;
    80004b72:	557d                	li	a0,-1
    80004b74:	bfc5                	j	80004b64 <filestat+0x60>

0000000080004b76 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b76:	7179                	addi	sp,sp,-48
    80004b78:	f406                	sd	ra,40(sp)
    80004b7a:	f022                	sd	s0,32(sp)
    80004b7c:	ec26                	sd	s1,24(sp)
    80004b7e:	e84a                	sd	s2,16(sp)
    80004b80:	e44e                	sd	s3,8(sp)
    80004b82:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b84:	00854783          	lbu	a5,8(a0)
    80004b88:	c3d5                	beqz	a5,80004c2c <fileread+0xb6>
    80004b8a:	84aa                	mv	s1,a0
    80004b8c:	89ae                	mv	s3,a1
    80004b8e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b90:	411c                	lw	a5,0(a0)
    80004b92:	4705                	li	a4,1
    80004b94:	04e78963          	beq	a5,a4,80004be6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b98:	470d                	li	a4,3
    80004b9a:	04e78d63          	beq	a5,a4,80004bf4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b9e:	4709                	li	a4,2
    80004ba0:	06e79e63          	bne	a5,a4,80004c1c <fileread+0xa6>
    ilock(f->ip);
    80004ba4:	6d08                	ld	a0,24(a0)
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	02c080e7          	jalr	44(ra) # 80003bd2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bae:	874a                	mv	a4,s2
    80004bb0:	5094                	lw	a3,32(s1)
    80004bb2:	864e                	mv	a2,s3
    80004bb4:	4585                	li	a1,1
    80004bb6:	6c88                	ld	a0,24(s1)
    80004bb8:	fffff097          	auipc	ra,0xfffff
    80004bbc:	2ce080e7          	jalr	718(ra) # 80003e86 <readi>
    80004bc0:	892a                	mv	s2,a0
    80004bc2:	00a05563          	blez	a0,80004bcc <fileread+0x56>
      f->off += r;
    80004bc6:	509c                	lw	a5,32(s1)
    80004bc8:	9fa9                	addw	a5,a5,a0
    80004bca:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bcc:	6c88                	ld	a0,24(s1)
    80004bce:	fffff097          	auipc	ra,0xfffff
    80004bd2:	0c6080e7          	jalr	198(ra) # 80003c94 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bd6:	854a                	mv	a0,s2
    80004bd8:	70a2                	ld	ra,40(sp)
    80004bda:	7402                	ld	s0,32(sp)
    80004bdc:	64e2                	ld	s1,24(sp)
    80004bde:	6942                	ld	s2,16(sp)
    80004be0:	69a2                	ld	s3,8(sp)
    80004be2:	6145                	addi	sp,sp,48
    80004be4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004be6:	6908                	ld	a0,16(a0)
    80004be8:	00000097          	auipc	ra,0x0
    80004bec:	3c2080e7          	jalr	962(ra) # 80004faa <piperead>
    80004bf0:	892a                	mv	s2,a0
    80004bf2:	b7d5                	j	80004bd6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bf4:	02451783          	lh	a5,36(a0)
    80004bf8:	03079693          	slli	a3,a5,0x30
    80004bfc:	92c1                	srli	a3,a3,0x30
    80004bfe:	4725                	li	a4,9
    80004c00:	02d76863          	bltu	a4,a3,80004c30 <fileread+0xba>
    80004c04:	0792                	slli	a5,a5,0x4
    80004c06:	0001e717          	auipc	a4,0x1e
    80004c0a:	21270713          	addi	a4,a4,530 # 80022e18 <devsw>
    80004c0e:	97ba                	add	a5,a5,a4
    80004c10:	639c                	ld	a5,0(a5)
    80004c12:	c38d                	beqz	a5,80004c34 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c14:	4505                	li	a0,1
    80004c16:	9782                	jalr	a5
    80004c18:	892a                	mv	s2,a0
    80004c1a:	bf75                	j	80004bd6 <fileread+0x60>
    panic("fileread");
    80004c1c:	00004517          	auipc	a0,0x4
    80004c20:	a3450513          	addi	a0,a0,-1484 # 80008650 <syscalls+0x278>
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	918080e7          	jalr	-1768(ra) # 8000053c <panic>
    return -1;
    80004c2c:	597d                	li	s2,-1
    80004c2e:	b765                	j	80004bd6 <fileread+0x60>
      return -1;
    80004c30:	597d                	li	s2,-1
    80004c32:	b755                	j	80004bd6 <fileread+0x60>
    80004c34:	597d                	li	s2,-1
    80004c36:	b745                	j	80004bd6 <fileread+0x60>

0000000080004c38 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c38:	00954783          	lbu	a5,9(a0)
    80004c3c:	10078e63          	beqz	a5,80004d58 <filewrite+0x120>
{
    80004c40:	715d                	addi	sp,sp,-80
    80004c42:	e486                	sd	ra,72(sp)
    80004c44:	e0a2                	sd	s0,64(sp)
    80004c46:	fc26                	sd	s1,56(sp)
    80004c48:	f84a                	sd	s2,48(sp)
    80004c4a:	f44e                	sd	s3,40(sp)
    80004c4c:	f052                	sd	s4,32(sp)
    80004c4e:	ec56                	sd	s5,24(sp)
    80004c50:	e85a                	sd	s6,16(sp)
    80004c52:	e45e                	sd	s7,8(sp)
    80004c54:	e062                	sd	s8,0(sp)
    80004c56:	0880                	addi	s0,sp,80
    80004c58:	892a                	mv	s2,a0
    80004c5a:	8b2e                	mv	s6,a1
    80004c5c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c5e:	411c                	lw	a5,0(a0)
    80004c60:	4705                	li	a4,1
    80004c62:	02e78263          	beq	a5,a4,80004c86 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c66:	470d                	li	a4,3
    80004c68:	02e78563          	beq	a5,a4,80004c92 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c6c:	4709                	li	a4,2
    80004c6e:	0ce79d63          	bne	a5,a4,80004d48 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c72:	0ac05b63          	blez	a2,80004d28 <filewrite+0xf0>
    int i = 0;
    80004c76:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004c78:	6b85                	lui	s7,0x1
    80004c7a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004c7e:	6c05                	lui	s8,0x1
    80004c80:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c84:	a851                	j	80004d18 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c86:	6908                	ld	a0,16(a0)
    80004c88:	00000097          	auipc	ra,0x0
    80004c8c:	22a080e7          	jalr	554(ra) # 80004eb2 <pipewrite>
    80004c90:	a045                	j	80004d30 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c92:	02451783          	lh	a5,36(a0)
    80004c96:	03079693          	slli	a3,a5,0x30
    80004c9a:	92c1                	srli	a3,a3,0x30
    80004c9c:	4725                	li	a4,9
    80004c9e:	0ad76f63          	bltu	a4,a3,80004d5c <filewrite+0x124>
    80004ca2:	0792                	slli	a5,a5,0x4
    80004ca4:	0001e717          	auipc	a4,0x1e
    80004ca8:	17470713          	addi	a4,a4,372 # 80022e18 <devsw>
    80004cac:	97ba                	add	a5,a5,a4
    80004cae:	679c                	ld	a5,8(a5)
    80004cb0:	cbc5                	beqz	a5,80004d60 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004cb2:	4505                	li	a0,1
    80004cb4:	9782                	jalr	a5
    80004cb6:	a8ad                	j	80004d30 <filewrite+0xf8>
      if(n1 > max)
    80004cb8:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004cbc:	00000097          	auipc	ra,0x0
    80004cc0:	8bc080e7          	jalr	-1860(ra) # 80004578 <begin_op>
      ilock(f->ip);
    80004cc4:	01893503          	ld	a0,24(s2)
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	f0a080e7          	jalr	-246(ra) # 80003bd2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cd0:	8756                	mv	a4,s5
    80004cd2:	02092683          	lw	a3,32(s2)
    80004cd6:	01698633          	add	a2,s3,s6
    80004cda:	4585                	li	a1,1
    80004cdc:	01893503          	ld	a0,24(s2)
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	29e080e7          	jalr	670(ra) # 80003f7e <writei>
    80004ce8:	84aa                	mv	s1,a0
    80004cea:	00a05763          	blez	a0,80004cf8 <filewrite+0xc0>
        f->off += r;
    80004cee:	02092783          	lw	a5,32(s2)
    80004cf2:	9fa9                	addw	a5,a5,a0
    80004cf4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cf8:	01893503          	ld	a0,24(s2)
    80004cfc:	fffff097          	auipc	ra,0xfffff
    80004d00:	f98080e7          	jalr	-104(ra) # 80003c94 <iunlock>
      end_op();
    80004d04:	00000097          	auipc	ra,0x0
    80004d08:	8ee080e7          	jalr	-1810(ra) # 800045f2 <end_op>

      if(r != n1){
    80004d0c:	009a9f63          	bne	s5,s1,80004d2a <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004d10:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d14:	0149db63          	bge	s3,s4,80004d2a <filewrite+0xf2>
      int n1 = n - i;
    80004d18:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004d1c:	0004879b          	sext.w	a5,s1
    80004d20:	f8fbdce3          	bge	s7,a5,80004cb8 <filewrite+0x80>
    80004d24:	84e2                	mv	s1,s8
    80004d26:	bf49                	j	80004cb8 <filewrite+0x80>
    int i = 0;
    80004d28:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d2a:	033a1d63          	bne	s4,s3,80004d64 <filewrite+0x12c>
    80004d2e:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d30:	60a6                	ld	ra,72(sp)
    80004d32:	6406                	ld	s0,64(sp)
    80004d34:	74e2                	ld	s1,56(sp)
    80004d36:	7942                	ld	s2,48(sp)
    80004d38:	79a2                	ld	s3,40(sp)
    80004d3a:	7a02                	ld	s4,32(sp)
    80004d3c:	6ae2                	ld	s5,24(sp)
    80004d3e:	6b42                	ld	s6,16(sp)
    80004d40:	6ba2                	ld	s7,8(sp)
    80004d42:	6c02                	ld	s8,0(sp)
    80004d44:	6161                	addi	sp,sp,80
    80004d46:	8082                	ret
    panic("filewrite");
    80004d48:	00004517          	auipc	a0,0x4
    80004d4c:	91850513          	addi	a0,a0,-1768 # 80008660 <syscalls+0x288>
    80004d50:	ffffb097          	auipc	ra,0xffffb
    80004d54:	7ec080e7          	jalr	2028(ra) # 8000053c <panic>
    return -1;
    80004d58:	557d                	li	a0,-1
}
    80004d5a:	8082                	ret
      return -1;
    80004d5c:	557d                	li	a0,-1
    80004d5e:	bfc9                	j	80004d30 <filewrite+0xf8>
    80004d60:	557d                	li	a0,-1
    80004d62:	b7f9                	j	80004d30 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004d64:	557d                	li	a0,-1
    80004d66:	b7e9                	j	80004d30 <filewrite+0xf8>

0000000080004d68 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d68:	7179                	addi	sp,sp,-48
    80004d6a:	f406                	sd	ra,40(sp)
    80004d6c:	f022                	sd	s0,32(sp)
    80004d6e:	ec26                	sd	s1,24(sp)
    80004d70:	e84a                	sd	s2,16(sp)
    80004d72:	e44e                	sd	s3,8(sp)
    80004d74:	e052                	sd	s4,0(sp)
    80004d76:	1800                	addi	s0,sp,48
    80004d78:	84aa                	mv	s1,a0
    80004d7a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d7c:	0005b023          	sd	zero,0(a1)
    80004d80:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d84:	00000097          	auipc	ra,0x0
    80004d88:	bfc080e7          	jalr	-1028(ra) # 80004980 <filealloc>
    80004d8c:	e088                	sd	a0,0(s1)
    80004d8e:	c551                	beqz	a0,80004e1a <pipealloc+0xb2>
    80004d90:	00000097          	auipc	ra,0x0
    80004d94:	bf0080e7          	jalr	-1040(ra) # 80004980 <filealloc>
    80004d98:	00aa3023          	sd	a0,0(s4)
    80004d9c:	c92d                	beqz	a0,80004e0e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d9e:	ffffc097          	auipc	ra,0xffffc
    80004da2:	d44080e7          	jalr	-700(ra) # 80000ae2 <kalloc>
    80004da6:	892a                	mv	s2,a0
    80004da8:	c125                	beqz	a0,80004e08 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004daa:	4985                	li	s3,1
    80004dac:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004db0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004db4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004db8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004dbc:	00004597          	auipc	a1,0x4
    80004dc0:	8b458593          	addi	a1,a1,-1868 # 80008670 <syscalls+0x298>
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	d7e080e7          	jalr	-642(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004dcc:	609c                	ld	a5,0(s1)
    80004dce:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dd2:	609c                	ld	a5,0(s1)
    80004dd4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dd8:	609c                	ld	a5,0(s1)
    80004dda:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dde:	609c                	ld	a5,0(s1)
    80004de0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004de4:	000a3783          	ld	a5,0(s4)
    80004de8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dec:	000a3783          	ld	a5,0(s4)
    80004df0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004df4:	000a3783          	ld	a5,0(s4)
    80004df8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dfc:	000a3783          	ld	a5,0(s4)
    80004e00:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e04:	4501                	li	a0,0
    80004e06:	a025                	j	80004e2e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e08:	6088                	ld	a0,0(s1)
    80004e0a:	e501                	bnez	a0,80004e12 <pipealloc+0xaa>
    80004e0c:	a039                	j	80004e1a <pipealloc+0xb2>
    80004e0e:	6088                	ld	a0,0(s1)
    80004e10:	c51d                	beqz	a0,80004e3e <pipealloc+0xd6>
    fileclose(*f0);
    80004e12:	00000097          	auipc	ra,0x0
    80004e16:	c2a080e7          	jalr	-982(ra) # 80004a3c <fileclose>
  if(*f1)
    80004e1a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e1e:	557d                	li	a0,-1
  if(*f1)
    80004e20:	c799                	beqz	a5,80004e2e <pipealloc+0xc6>
    fileclose(*f1);
    80004e22:	853e                	mv	a0,a5
    80004e24:	00000097          	auipc	ra,0x0
    80004e28:	c18080e7          	jalr	-1000(ra) # 80004a3c <fileclose>
  return -1;
    80004e2c:	557d                	li	a0,-1
}
    80004e2e:	70a2                	ld	ra,40(sp)
    80004e30:	7402                	ld	s0,32(sp)
    80004e32:	64e2                	ld	s1,24(sp)
    80004e34:	6942                	ld	s2,16(sp)
    80004e36:	69a2                	ld	s3,8(sp)
    80004e38:	6a02                	ld	s4,0(sp)
    80004e3a:	6145                	addi	sp,sp,48
    80004e3c:	8082                	ret
  return -1;
    80004e3e:	557d                	li	a0,-1
    80004e40:	b7fd                	j	80004e2e <pipealloc+0xc6>

0000000080004e42 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e42:	1101                	addi	sp,sp,-32
    80004e44:	ec06                	sd	ra,24(sp)
    80004e46:	e822                	sd	s0,16(sp)
    80004e48:	e426                	sd	s1,8(sp)
    80004e4a:	e04a                	sd	s2,0(sp)
    80004e4c:	1000                	addi	s0,sp,32
    80004e4e:	84aa                	mv	s1,a0
    80004e50:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e52:	ffffc097          	auipc	ra,0xffffc
    80004e56:	d80080e7          	jalr	-640(ra) # 80000bd2 <acquire>
  if(writable){
    80004e5a:	02090d63          	beqz	s2,80004e94 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e5e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e62:	21848513          	addi	a0,s1,536
    80004e66:	ffffd097          	auipc	ra,0xffffd
    80004e6a:	444080e7          	jalr	1092(ra) # 800022aa <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e6e:	2204b783          	ld	a5,544(s1)
    80004e72:	eb95                	bnez	a5,80004ea6 <pipeclose+0x64>
    release(&pi->lock);
    80004e74:	8526                	mv	a0,s1
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	e10080e7          	jalr	-496(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004e7e:	8526                	mv	a0,s1
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	b64080e7          	jalr	-1180(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004e88:	60e2                	ld	ra,24(sp)
    80004e8a:	6442                	ld	s0,16(sp)
    80004e8c:	64a2                	ld	s1,8(sp)
    80004e8e:	6902                	ld	s2,0(sp)
    80004e90:	6105                	addi	sp,sp,32
    80004e92:	8082                	ret
    pi->readopen = 0;
    80004e94:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e98:	21c48513          	addi	a0,s1,540
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	40e080e7          	jalr	1038(ra) # 800022aa <wakeup>
    80004ea4:	b7e9                	j	80004e6e <pipeclose+0x2c>
    release(&pi->lock);
    80004ea6:	8526                	mv	a0,s1
    80004ea8:	ffffc097          	auipc	ra,0xffffc
    80004eac:	dde080e7          	jalr	-546(ra) # 80000c86 <release>
}
    80004eb0:	bfe1                	j	80004e88 <pipeclose+0x46>

0000000080004eb2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004eb2:	711d                	addi	sp,sp,-96
    80004eb4:	ec86                	sd	ra,88(sp)
    80004eb6:	e8a2                	sd	s0,80(sp)
    80004eb8:	e4a6                	sd	s1,72(sp)
    80004eba:	e0ca                	sd	s2,64(sp)
    80004ebc:	fc4e                	sd	s3,56(sp)
    80004ebe:	f852                	sd	s4,48(sp)
    80004ec0:	f456                	sd	s5,40(sp)
    80004ec2:	f05a                	sd	s6,32(sp)
    80004ec4:	ec5e                	sd	s7,24(sp)
    80004ec6:	e862                	sd	s8,16(sp)
    80004ec8:	1080                	addi	s0,sp,96
    80004eca:	84aa                	mv	s1,a0
    80004ecc:	8aae                	mv	s5,a1
    80004ece:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ed0:	ffffd097          	auipc	ra,0xffffd
    80004ed4:	ad6080e7          	jalr	-1322(ra) # 800019a6 <myproc>
    80004ed8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004eda:	8526                	mv	a0,s1
    80004edc:	ffffc097          	auipc	ra,0xffffc
    80004ee0:	cf6080e7          	jalr	-778(ra) # 80000bd2 <acquire>
  while(i < n){
    80004ee4:	0b405663          	blez	s4,80004f90 <pipewrite+0xde>
  int i = 0;
    80004ee8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eea:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004eec:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ef0:	21c48b93          	addi	s7,s1,540
    80004ef4:	a089                	j	80004f36 <pipewrite+0x84>
      release(&pi->lock);
    80004ef6:	8526                	mv	a0,s1
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	d8e080e7          	jalr	-626(ra) # 80000c86 <release>
      return -1;
    80004f00:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f02:	854a                	mv	a0,s2
    80004f04:	60e6                	ld	ra,88(sp)
    80004f06:	6446                	ld	s0,80(sp)
    80004f08:	64a6                	ld	s1,72(sp)
    80004f0a:	6906                	ld	s2,64(sp)
    80004f0c:	79e2                	ld	s3,56(sp)
    80004f0e:	7a42                	ld	s4,48(sp)
    80004f10:	7aa2                	ld	s5,40(sp)
    80004f12:	7b02                	ld	s6,32(sp)
    80004f14:	6be2                	ld	s7,24(sp)
    80004f16:	6c42                	ld	s8,16(sp)
    80004f18:	6125                	addi	sp,sp,96
    80004f1a:	8082                	ret
      wakeup(&pi->nread);
    80004f1c:	8562                	mv	a0,s8
    80004f1e:	ffffd097          	auipc	ra,0xffffd
    80004f22:	38c080e7          	jalr	908(ra) # 800022aa <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f26:	85a6                	mv	a1,s1
    80004f28:	855e                	mv	a0,s7
    80004f2a:	ffffd097          	auipc	ra,0xffffd
    80004f2e:	31c080e7          	jalr	796(ra) # 80002246 <sleep>
  while(i < n){
    80004f32:	07495063          	bge	s2,s4,80004f92 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f36:	2204a783          	lw	a5,544(s1)
    80004f3a:	dfd5                	beqz	a5,80004ef6 <pipewrite+0x44>
    80004f3c:	854e                	mv	a0,s3
    80004f3e:	ffffd097          	auipc	ra,0xffffd
    80004f42:	5bc080e7          	jalr	1468(ra) # 800024fa <killed>
    80004f46:	f945                	bnez	a0,80004ef6 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f48:	2184a783          	lw	a5,536(s1)
    80004f4c:	21c4a703          	lw	a4,540(s1)
    80004f50:	2007879b          	addiw	a5,a5,512
    80004f54:	fcf704e3          	beq	a4,a5,80004f1c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f58:	4685                	li	a3,1
    80004f5a:	01590633          	add	a2,s2,s5
    80004f5e:	faf40593          	addi	a1,s0,-81
    80004f62:	0509b503          	ld	a0,80(s3)
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	78c080e7          	jalr	1932(ra) # 800016f2 <copyin>
    80004f6e:	03650263          	beq	a0,s6,80004f92 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f72:	21c4a783          	lw	a5,540(s1)
    80004f76:	0017871b          	addiw	a4,a5,1
    80004f7a:	20e4ae23          	sw	a4,540(s1)
    80004f7e:	1ff7f793          	andi	a5,a5,511
    80004f82:	97a6                	add	a5,a5,s1
    80004f84:	faf44703          	lbu	a4,-81(s0)
    80004f88:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f8c:	2905                	addiw	s2,s2,1
    80004f8e:	b755                	j	80004f32 <pipewrite+0x80>
  int i = 0;
    80004f90:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f92:	21848513          	addi	a0,s1,536
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	314080e7          	jalr	788(ra) # 800022aa <wakeup>
  release(&pi->lock);
    80004f9e:	8526                	mv	a0,s1
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	ce6080e7          	jalr	-794(ra) # 80000c86 <release>
  return i;
    80004fa8:	bfa9                	j	80004f02 <pipewrite+0x50>

0000000080004faa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004faa:	715d                	addi	sp,sp,-80
    80004fac:	e486                	sd	ra,72(sp)
    80004fae:	e0a2                	sd	s0,64(sp)
    80004fb0:	fc26                	sd	s1,56(sp)
    80004fb2:	f84a                	sd	s2,48(sp)
    80004fb4:	f44e                	sd	s3,40(sp)
    80004fb6:	f052                	sd	s4,32(sp)
    80004fb8:	ec56                	sd	s5,24(sp)
    80004fba:	e85a                	sd	s6,16(sp)
    80004fbc:	0880                	addi	s0,sp,80
    80004fbe:	84aa                	mv	s1,a0
    80004fc0:	892e                	mv	s2,a1
    80004fc2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fc4:	ffffd097          	auipc	ra,0xffffd
    80004fc8:	9e2080e7          	jalr	-1566(ra) # 800019a6 <myproc>
    80004fcc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fce:	8526                	mv	a0,s1
    80004fd0:	ffffc097          	auipc	ra,0xffffc
    80004fd4:	c02080e7          	jalr	-1022(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fd8:	2184a703          	lw	a4,536(s1)
    80004fdc:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fe0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fe4:	02f71763          	bne	a4,a5,80005012 <piperead+0x68>
    80004fe8:	2244a783          	lw	a5,548(s1)
    80004fec:	c39d                	beqz	a5,80005012 <piperead+0x68>
    if(killed(pr)){
    80004fee:	8552                	mv	a0,s4
    80004ff0:	ffffd097          	auipc	ra,0xffffd
    80004ff4:	50a080e7          	jalr	1290(ra) # 800024fa <killed>
    80004ff8:	e949                	bnez	a0,8000508a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ffa:	85a6                	mv	a1,s1
    80004ffc:	854e                	mv	a0,s3
    80004ffe:	ffffd097          	auipc	ra,0xffffd
    80005002:	248080e7          	jalr	584(ra) # 80002246 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005006:	2184a703          	lw	a4,536(s1)
    8000500a:	21c4a783          	lw	a5,540(s1)
    8000500e:	fcf70de3          	beq	a4,a5,80004fe8 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005012:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005014:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005016:	05505463          	blez	s5,8000505e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000501a:	2184a783          	lw	a5,536(s1)
    8000501e:	21c4a703          	lw	a4,540(s1)
    80005022:	02f70e63          	beq	a4,a5,8000505e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005026:	0017871b          	addiw	a4,a5,1
    8000502a:	20e4ac23          	sw	a4,536(s1)
    8000502e:	1ff7f793          	andi	a5,a5,511
    80005032:	97a6                	add	a5,a5,s1
    80005034:	0187c783          	lbu	a5,24(a5)
    80005038:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000503c:	4685                	li	a3,1
    8000503e:	fbf40613          	addi	a2,s0,-65
    80005042:	85ca                	mv	a1,s2
    80005044:	050a3503          	ld	a0,80(s4)
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	61e080e7          	jalr	1566(ra) # 80001666 <copyout>
    80005050:	01650763          	beq	a0,s6,8000505e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005054:	2985                	addiw	s3,s3,1
    80005056:	0905                	addi	s2,s2,1
    80005058:	fd3a91e3          	bne	s5,s3,8000501a <piperead+0x70>
    8000505c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000505e:	21c48513          	addi	a0,s1,540
    80005062:	ffffd097          	auipc	ra,0xffffd
    80005066:	248080e7          	jalr	584(ra) # 800022aa <wakeup>
  release(&pi->lock);
    8000506a:	8526                	mv	a0,s1
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	c1a080e7          	jalr	-998(ra) # 80000c86 <release>
  return i;
}
    80005074:	854e                	mv	a0,s3
    80005076:	60a6                	ld	ra,72(sp)
    80005078:	6406                	ld	s0,64(sp)
    8000507a:	74e2                	ld	s1,56(sp)
    8000507c:	7942                	ld	s2,48(sp)
    8000507e:	79a2                	ld	s3,40(sp)
    80005080:	7a02                	ld	s4,32(sp)
    80005082:	6ae2                	ld	s5,24(sp)
    80005084:	6b42                	ld	s6,16(sp)
    80005086:	6161                	addi	sp,sp,80
    80005088:	8082                	ret
      release(&pi->lock);
    8000508a:	8526                	mv	a0,s1
    8000508c:	ffffc097          	auipc	ra,0xffffc
    80005090:	bfa080e7          	jalr	-1030(ra) # 80000c86 <release>
      return -1;
    80005094:	59fd                	li	s3,-1
    80005096:	bff9                	j	80005074 <piperead+0xca>

0000000080005098 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005098:	1141                	addi	sp,sp,-16
    8000509a:	e422                	sd	s0,8(sp)
    8000509c:	0800                	addi	s0,sp,16
    8000509e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800050a0:	8905                	andi	a0,a0,1
    800050a2:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800050a4:	8b89                	andi	a5,a5,2
    800050a6:	c399                	beqz	a5,800050ac <flags2perm+0x14>
      perm |= PTE_W;
    800050a8:	00456513          	ori	a0,a0,4
    return perm;
}
    800050ac:	6422                	ld	s0,8(sp)
    800050ae:	0141                	addi	sp,sp,16
    800050b0:	8082                	ret

00000000800050b2 <exec>:

int
exec(char *path, char **argv)
{
    800050b2:	df010113          	addi	sp,sp,-528
    800050b6:	20113423          	sd	ra,520(sp)
    800050ba:	20813023          	sd	s0,512(sp)
    800050be:	ffa6                	sd	s1,504(sp)
    800050c0:	fbca                	sd	s2,496(sp)
    800050c2:	f7ce                	sd	s3,488(sp)
    800050c4:	f3d2                	sd	s4,480(sp)
    800050c6:	efd6                	sd	s5,472(sp)
    800050c8:	ebda                	sd	s6,464(sp)
    800050ca:	e7de                	sd	s7,456(sp)
    800050cc:	e3e2                	sd	s8,448(sp)
    800050ce:	ff66                	sd	s9,440(sp)
    800050d0:	fb6a                	sd	s10,432(sp)
    800050d2:	f76e                	sd	s11,424(sp)
    800050d4:	0c00                	addi	s0,sp,528
    800050d6:	892a                	mv	s2,a0
    800050d8:	dea43c23          	sd	a0,-520(s0)
    800050dc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050e0:	ffffd097          	auipc	ra,0xffffd
    800050e4:	8c6080e7          	jalr	-1850(ra) # 800019a6 <myproc>
    800050e8:	84aa                	mv	s1,a0

  begin_op();
    800050ea:	fffff097          	auipc	ra,0xfffff
    800050ee:	48e080e7          	jalr	1166(ra) # 80004578 <begin_op>

  if((ip = namei(path)) == 0){
    800050f2:	854a                	mv	a0,s2
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	284080e7          	jalr	644(ra) # 80004378 <namei>
    800050fc:	c92d                	beqz	a0,8000516e <exec+0xbc>
    800050fe:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	ad2080e7          	jalr	-1326(ra) # 80003bd2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005108:	04000713          	li	a4,64
    8000510c:	4681                	li	a3,0
    8000510e:	e5040613          	addi	a2,s0,-432
    80005112:	4581                	li	a1,0
    80005114:	8552                	mv	a0,s4
    80005116:	fffff097          	auipc	ra,0xfffff
    8000511a:	d70080e7          	jalr	-656(ra) # 80003e86 <readi>
    8000511e:	04000793          	li	a5,64
    80005122:	00f51a63          	bne	a0,a5,80005136 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005126:	e5042703          	lw	a4,-432(s0)
    8000512a:	464c47b7          	lui	a5,0x464c4
    8000512e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005132:	04f70463          	beq	a4,a5,8000517a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005136:	8552                	mv	a0,s4
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	cfc080e7          	jalr	-772(ra) # 80003e34 <iunlockput>
    end_op();
    80005140:	fffff097          	auipc	ra,0xfffff
    80005144:	4b2080e7          	jalr	1202(ra) # 800045f2 <end_op>
  }
  return -1;
    80005148:	557d                	li	a0,-1
}
    8000514a:	20813083          	ld	ra,520(sp)
    8000514e:	20013403          	ld	s0,512(sp)
    80005152:	74fe                	ld	s1,504(sp)
    80005154:	795e                	ld	s2,496(sp)
    80005156:	79be                	ld	s3,488(sp)
    80005158:	7a1e                	ld	s4,480(sp)
    8000515a:	6afe                	ld	s5,472(sp)
    8000515c:	6b5e                	ld	s6,464(sp)
    8000515e:	6bbe                	ld	s7,456(sp)
    80005160:	6c1e                	ld	s8,448(sp)
    80005162:	7cfa                	ld	s9,440(sp)
    80005164:	7d5a                	ld	s10,432(sp)
    80005166:	7dba                	ld	s11,424(sp)
    80005168:	21010113          	addi	sp,sp,528
    8000516c:	8082                	ret
    end_op();
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	484080e7          	jalr	1156(ra) # 800045f2 <end_op>
    return -1;
    80005176:	557d                	li	a0,-1
    80005178:	bfc9                	j	8000514a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000517a:	8526                	mv	a0,s1
    8000517c:	ffffd097          	auipc	ra,0xffffd
    80005180:	a00080e7          	jalr	-1536(ra) # 80001b7c <proc_pagetable>
    80005184:	8b2a                	mv	s6,a0
    80005186:	d945                	beqz	a0,80005136 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005188:	e7042d03          	lw	s10,-400(s0)
    8000518c:	e8845783          	lhu	a5,-376(s0)
    80005190:	10078463          	beqz	a5,80005298 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005194:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005196:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005198:	6c85                	lui	s9,0x1
    8000519a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000519e:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800051a2:	6a85                	lui	s5,0x1
    800051a4:	a0b5                	j	80005210 <exec+0x15e>
      panic("loadseg: address should exist");
    800051a6:	00003517          	auipc	a0,0x3
    800051aa:	4d250513          	addi	a0,a0,1234 # 80008678 <syscalls+0x2a0>
    800051ae:	ffffb097          	auipc	ra,0xffffb
    800051b2:	38e080e7          	jalr	910(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    800051b6:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051b8:	8726                	mv	a4,s1
    800051ba:	012c06bb          	addw	a3,s8,s2
    800051be:	4581                	li	a1,0
    800051c0:	8552                	mv	a0,s4
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	cc4080e7          	jalr	-828(ra) # 80003e86 <readi>
    800051ca:	2501                	sext.w	a0,a0
    800051cc:	24a49863          	bne	s1,a0,8000541c <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800051d0:	012a893b          	addw	s2,s5,s2
    800051d4:	03397563          	bgeu	s2,s3,800051fe <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800051d8:	02091593          	slli	a1,s2,0x20
    800051dc:	9181                	srli	a1,a1,0x20
    800051de:	95de                	add	a1,a1,s7
    800051e0:	855a                	mv	a0,s6
    800051e2:	ffffc097          	auipc	ra,0xffffc
    800051e6:	e74080e7          	jalr	-396(ra) # 80001056 <walkaddr>
    800051ea:	862a                	mv	a2,a0
    if(pa == 0)
    800051ec:	dd4d                	beqz	a0,800051a6 <exec+0xf4>
    if(sz - i < PGSIZE)
    800051ee:	412984bb          	subw	s1,s3,s2
    800051f2:	0004879b          	sext.w	a5,s1
    800051f6:	fcfcf0e3          	bgeu	s9,a5,800051b6 <exec+0x104>
    800051fa:	84d6                	mv	s1,s5
    800051fc:	bf6d                	j	800051b6 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051fe:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005202:	2d85                	addiw	s11,s11,1
    80005204:	038d0d1b          	addiw	s10,s10,56
    80005208:	e8845783          	lhu	a5,-376(s0)
    8000520c:	08fdd763          	bge	s11,a5,8000529a <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005210:	2d01                	sext.w	s10,s10
    80005212:	03800713          	li	a4,56
    80005216:	86ea                	mv	a3,s10
    80005218:	e1840613          	addi	a2,s0,-488
    8000521c:	4581                	li	a1,0
    8000521e:	8552                	mv	a0,s4
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	c66080e7          	jalr	-922(ra) # 80003e86 <readi>
    80005228:	03800793          	li	a5,56
    8000522c:	1ef51663          	bne	a0,a5,80005418 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005230:	e1842783          	lw	a5,-488(s0)
    80005234:	4705                	li	a4,1
    80005236:	fce796e3          	bne	a5,a4,80005202 <exec+0x150>
    if(ph.memsz < ph.filesz)
    8000523a:	e4043483          	ld	s1,-448(s0)
    8000523e:	e3843783          	ld	a5,-456(s0)
    80005242:	1ef4e863          	bltu	s1,a5,80005432 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005246:	e2843783          	ld	a5,-472(s0)
    8000524a:	94be                	add	s1,s1,a5
    8000524c:	1ef4e663          	bltu	s1,a5,80005438 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80005250:	df043703          	ld	a4,-528(s0)
    80005254:	8ff9                	and	a5,a5,a4
    80005256:	1e079463          	bnez	a5,8000543e <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000525a:	e1c42503          	lw	a0,-484(s0)
    8000525e:	00000097          	auipc	ra,0x0
    80005262:	e3a080e7          	jalr	-454(ra) # 80005098 <flags2perm>
    80005266:	86aa                	mv	a3,a0
    80005268:	8626                	mv	a2,s1
    8000526a:	85ca                	mv	a1,s2
    8000526c:	855a                	mv	a0,s6
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	19c080e7          	jalr	412(ra) # 8000140a <uvmalloc>
    80005276:	e0a43423          	sd	a0,-504(s0)
    8000527a:	1c050563          	beqz	a0,80005444 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000527e:	e2843b83          	ld	s7,-472(s0)
    80005282:	e2042c03          	lw	s8,-480(s0)
    80005286:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000528a:	00098463          	beqz	s3,80005292 <exec+0x1e0>
    8000528e:	4901                	li	s2,0
    80005290:	b7a1                	j	800051d8 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005292:	e0843903          	ld	s2,-504(s0)
    80005296:	b7b5                	j	80005202 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005298:	4901                	li	s2,0
  iunlockput(ip);
    8000529a:	8552                	mv	a0,s4
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	b98080e7          	jalr	-1128(ra) # 80003e34 <iunlockput>
  end_op();
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	34e080e7          	jalr	846(ra) # 800045f2 <end_op>
  p = myproc();
    800052ac:	ffffc097          	auipc	ra,0xffffc
    800052b0:	6fa080e7          	jalr	1786(ra) # 800019a6 <myproc>
    800052b4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052b6:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800052ba:	6985                	lui	s3,0x1
    800052bc:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800052be:	99ca                	add	s3,s3,s2
    800052c0:	77fd                	lui	a5,0xfffff
    800052c2:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052c6:	4691                	li	a3,4
    800052c8:	6609                	lui	a2,0x2
    800052ca:	964e                	add	a2,a2,s3
    800052cc:	85ce                	mv	a1,s3
    800052ce:	855a                	mv	a0,s6
    800052d0:	ffffc097          	auipc	ra,0xffffc
    800052d4:	13a080e7          	jalr	314(ra) # 8000140a <uvmalloc>
    800052d8:	892a                	mv	s2,a0
    800052da:	e0a43423          	sd	a0,-504(s0)
    800052de:	e509                	bnez	a0,800052e8 <exec+0x236>
  if(pagetable)
    800052e0:	e1343423          	sd	s3,-504(s0)
    800052e4:	4a01                	li	s4,0
    800052e6:	aa1d                	j	8000541c <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052e8:	75f9                	lui	a1,0xffffe
    800052ea:	95aa                	add	a1,a1,a0
    800052ec:	855a                	mv	a0,s6
    800052ee:	ffffc097          	auipc	ra,0xffffc
    800052f2:	346080e7          	jalr	838(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    800052f6:	7bfd                	lui	s7,0xfffff
    800052f8:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800052fa:	e0043783          	ld	a5,-512(s0)
    800052fe:	6388                	ld	a0,0(a5)
    80005300:	c52d                	beqz	a0,8000536a <exec+0x2b8>
    80005302:	e9040993          	addi	s3,s0,-368
    80005306:	f9040c13          	addi	s8,s0,-112
    8000530a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000530c:	ffffc097          	auipc	ra,0xffffc
    80005310:	b3c080e7          	jalr	-1220(ra) # 80000e48 <strlen>
    80005314:	0015079b          	addiw	a5,a0,1
    80005318:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000531c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005320:	13796563          	bltu	s2,s7,8000544a <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005324:	e0043d03          	ld	s10,-512(s0)
    80005328:	000d3a03          	ld	s4,0(s10)
    8000532c:	8552                	mv	a0,s4
    8000532e:	ffffc097          	auipc	ra,0xffffc
    80005332:	b1a080e7          	jalr	-1254(ra) # 80000e48 <strlen>
    80005336:	0015069b          	addiw	a3,a0,1
    8000533a:	8652                	mv	a2,s4
    8000533c:	85ca                	mv	a1,s2
    8000533e:	855a                	mv	a0,s6
    80005340:	ffffc097          	auipc	ra,0xffffc
    80005344:	326080e7          	jalr	806(ra) # 80001666 <copyout>
    80005348:	10054363          	bltz	a0,8000544e <exec+0x39c>
    ustack[argc] = sp;
    8000534c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005350:	0485                	addi	s1,s1,1
    80005352:	008d0793          	addi	a5,s10,8
    80005356:	e0f43023          	sd	a5,-512(s0)
    8000535a:	008d3503          	ld	a0,8(s10)
    8000535e:	c909                	beqz	a0,80005370 <exec+0x2be>
    if(argc >= MAXARG)
    80005360:	09a1                	addi	s3,s3,8
    80005362:	fb8995e3          	bne	s3,s8,8000530c <exec+0x25a>
  ip = 0;
    80005366:	4a01                	li	s4,0
    80005368:	a855                	j	8000541c <exec+0x36a>
  sp = sz;
    8000536a:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000536e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005370:	00349793          	slli	a5,s1,0x3
    80005374:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdafe0>
    80005378:	97a2                	add	a5,a5,s0
    8000537a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000537e:	00148693          	addi	a3,s1,1
    80005382:	068e                	slli	a3,a3,0x3
    80005384:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005388:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000538c:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005390:	f57968e3          	bltu	s2,s7,800052e0 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005394:	e9040613          	addi	a2,s0,-368
    80005398:	85ca                	mv	a1,s2
    8000539a:	855a                	mv	a0,s6
    8000539c:	ffffc097          	auipc	ra,0xffffc
    800053a0:	2ca080e7          	jalr	714(ra) # 80001666 <copyout>
    800053a4:	0a054763          	bltz	a0,80005452 <exec+0x3a0>
  p->trapframe->a1 = sp;
    800053a8:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800053ac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053b0:	df843783          	ld	a5,-520(s0)
    800053b4:	0007c703          	lbu	a4,0(a5)
    800053b8:	cf11                	beqz	a4,800053d4 <exec+0x322>
    800053ba:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053bc:	02f00693          	li	a3,47
    800053c0:	a039                	j	800053ce <exec+0x31c>
      last = s+1;
    800053c2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053c6:	0785                	addi	a5,a5,1
    800053c8:	fff7c703          	lbu	a4,-1(a5)
    800053cc:	c701                	beqz	a4,800053d4 <exec+0x322>
    if(*s == '/')
    800053ce:	fed71ce3          	bne	a4,a3,800053c6 <exec+0x314>
    800053d2:	bfc5                	j	800053c2 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800053d4:	4641                	li	a2,16
    800053d6:	df843583          	ld	a1,-520(s0)
    800053da:	158a8513          	addi	a0,s5,344
    800053de:	ffffc097          	auipc	ra,0xffffc
    800053e2:	a38080e7          	jalr	-1480(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800053e6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800053ea:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800053ee:	e0843783          	ld	a5,-504(s0)
    800053f2:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053f6:	058ab783          	ld	a5,88(s5)
    800053fa:	e6843703          	ld	a4,-408(s0)
    800053fe:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005400:	058ab783          	ld	a5,88(s5)
    80005404:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005408:	85e6                	mv	a1,s9
    8000540a:	ffffd097          	auipc	ra,0xffffd
    8000540e:	80e080e7          	jalr	-2034(ra) # 80001c18 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005412:	0004851b          	sext.w	a0,s1
    80005416:	bb15                	j	8000514a <exec+0x98>
    80005418:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000541c:	e0843583          	ld	a1,-504(s0)
    80005420:	855a                	mv	a0,s6
    80005422:	ffffc097          	auipc	ra,0xffffc
    80005426:	7f6080e7          	jalr	2038(ra) # 80001c18 <proc_freepagetable>
  return -1;
    8000542a:	557d                	li	a0,-1
  if(ip){
    8000542c:	d00a0fe3          	beqz	s4,8000514a <exec+0x98>
    80005430:	b319                	j	80005136 <exec+0x84>
    80005432:	e1243423          	sd	s2,-504(s0)
    80005436:	b7dd                	j	8000541c <exec+0x36a>
    80005438:	e1243423          	sd	s2,-504(s0)
    8000543c:	b7c5                	j	8000541c <exec+0x36a>
    8000543e:	e1243423          	sd	s2,-504(s0)
    80005442:	bfe9                	j	8000541c <exec+0x36a>
    80005444:	e1243423          	sd	s2,-504(s0)
    80005448:	bfd1                	j	8000541c <exec+0x36a>
  ip = 0;
    8000544a:	4a01                	li	s4,0
    8000544c:	bfc1                	j	8000541c <exec+0x36a>
    8000544e:	4a01                	li	s4,0
  if(pagetable)
    80005450:	b7f1                	j	8000541c <exec+0x36a>
  sz = sz1;
    80005452:	e0843983          	ld	s3,-504(s0)
    80005456:	b569                	j	800052e0 <exec+0x22e>

0000000080005458 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005458:	7179                	addi	sp,sp,-48
    8000545a:	f406                	sd	ra,40(sp)
    8000545c:	f022                	sd	s0,32(sp)
    8000545e:	ec26                	sd	s1,24(sp)
    80005460:	e84a                	sd	s2,16(sp)
    80005462:	1800                	addi	s0,sp,48
    80005464:	892e                	mv	s2,a1
    80005466:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005468:	fdc40593          	addi	a1,s0,-36
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	acc080e7          	jalr	-1332(ra) # 80002f38 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005474:	fdc42703          	lw	a4,-36(s0)
    80005478:	47bd                	li	a5,15
    8000547a:	02e7eb63          	bltu	a5,a4,800054b0 <argfd+0x58>
    8000547e:	ffffc097          	auipc	ra,0xffffc
    80005482:	528080e7          	jalr	1320(ra) # 800019a6 <myproc>
    80005486:	fdc42703          	lw	a4,-36(s0)
    8000548a:	01a70793          	addi	a5,a4,26
    8000548e:	078e                	slli	a5,a5,0x3
    80005490:	953e                	add	a0,a0,a5
    80005492:	611c                	ld	a5,0(a0)
    80005494:	c385                	beqz	a5,800054b4 <argfd+0x5c>
    return -1;
  if(pfd)
    80005496:	00090463          	beqz	s2,8000549e <argfd+0x46>
    *pfd = fd;
    8000549a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000549e:	4501                	li	a0,0
  if(pf)
    800054a0:	c091                	beqz	s1,800054a4 <argfd+0x4c>
    *pf = f;
    800054a2:	e09c                	sd	a5,0(s1)
}
    800054a4:	70a2                	ld	ra,40(sp)
    800054a6:	7402                	ld	s0,32(sp)
    800054a8:	64e2                	ld	s1,24(sp)
    800054aa:	6942                	ld	s2,16(sp)
    800054ac:	6145                	addi	sp,sp,48
    800054ae:	8082                	ret
    return -1;
    800054b0:	557d                	li	a0,-1
    800054b2:	bfcd                	j	800054a4 <argfd+0x4c>
    800054b4:	557d                	li	a0,-1
    800054b6:	b7fd                	j	800054a4 <argfd+0x4c>

00000000800054b8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054b8:	1101                	addi	sp,sp,-32
    800054ba:	ec06                	sd	ra,24(sp)
    800054bc:	e822                	sd	s0,16(sp)
    800054be:	e426                	sd	s1,8(sp)
    800054c0:	1000                	addi	s0,sp,32
    800054c2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054c4:	ffffc097          	auipc	ra,0xffffc
    800054c8:	4e2080e7          	jalr	1250(ra) # 800019a6 <myproc>
    800054cc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054ce:	0d050793          	addi	a5,a0,208
    800054d2:	4501                	li	a0,0
    800054d4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054d6:	6398                	ld	a4,0(a5)
    800054d8:	cb19                	beqz	a4,800054ee <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054da:	2505                	addiw	a0,a0,1
    800054dc:	07a1                	addi	a5,a5,8
    800054de:	fed51ce3          	bne	a0,a3,800054d6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054e2:	557d                	li	a0,-1
}
    800054e4:	60e2                	ld	ra,24(sp)
    800054e6:	6442                	ld	s0,16(sp)
    800054e8:	64a2                	ld	s1,8(sp)
    800054ea:	6105                	addi	sp,sp,32
    800054ec:	8082                	ret
      p->ofile[fd] = f;
    800054ee:	01a50793          	addi	a5,a0,26
    800054f2:	078e                	slli	a5,a5,0x3
    800054f4:	963e                	add	a2,a2,a5
    800054f6:	e204                	sd	s1,0(a2)
      return fd;
    800054f8:	b7f5                	j	800054e4 <fdalloc+0x2c>

00000000800054fa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054fa:	715d                	addi	sp,sp,-80
    800054fc:	e486                	sd	ra,72(sp)
    800054fe:	e0a2                	sd	s0,64(sp)
    80005500:	fc26                	sd	s1,56(sp)
    80005502:	f84a                	sd	s2,48(sp)
    80005504:	f44e                	sd	s3,40(sp)
    80005506:	f052                	sd	s4,32(sp)
    80005508:	ec56                	sd	s5,24(sp)
    8000550a:	e85a                	sd	s6,16(sp)
    8000550c:	0880                	addi	s0,sp,80
    8000550e:	8b2e                	mv	s6,a1
    80005510:	89b2                	mv	s3,a2
    80005512:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005514:	fb040593          	addi	a1,s0,-80
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	e7e080e7          	jalr	-386(ra) # 80004396 <nameiparent>
    80005520:	84aa                	mv	s1,a0
    80005522:	14050b63          	beqz	a0,80005678 <create+0x17e>
    return 0;

  ilock(dp);
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	6ac080e7          	jalr	1708(ra) # 80003bd2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000552e:	4601                	li	a2,0
    80005530:	fb040593          	addi	a1,s0,-80
    80005534:	8526                	mv	a0,s1
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	b80080e7          	jalr	-1152(ra) # 800040b6 <dirlookup>
    8000553e:	8aaa                	mv	s5,a0
    80005540:	c921                	beqz	a0,80005590 <create+0x96>
    iunlockput(dp);
    80005542:	8526                	mv	a0,s1
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	8f0080e7          	jalr	-1808(ra) # 80003e34 <iunlockput>
    ilock(ip);
    8000554c:	8556                	mv	a0,s5
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	684080e7          	jalr	1668(ra) # 80003bd2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005556:	4789                	li	a5,2
    80005558:	02fb1563          	bne	s6,a5,80005582 <create+0x88>
    8000555c:	044ad783          	lhu	a5,68(s5)
    80005560:	37f9                	addiw	a5,a5,-2
    80005562:	17c2                	slli	a5,a5,0x30
    80005564:	93c1                	srli	a5,a5,0x30
    80005566:	4705                	li	a4,1
    80005568:	00f76d63          	bltu	a4,a5,80005582 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000556c:	8556                	mv	a0,s5
    8000556e:	60a6                	ld	ra,72(sp)
    80005570:	6406                	ld	s0,64(sp)
    80005572:	74e2                	ld	s1,56(sp)
    80005574:	7942                	ld	s2,48(sp)
    80005576:	79a2                	ld	s3,40(sp)
    80005578:	7a02                	ld	s4,32(sp)
    8000557a:	6ae2                	ld	s5,24(sp)
    8000557c:	6b42                	ld	s6,16(sp)
    8000557e:	6161                	addi	sp,sp,80
    80005580:	8082                	ret
    iunlockput(ip);
    80005582:	8556                	mv	a0,s5
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	8b0080e7          	jalr	-1872(ra) # 80003e34 <iunlockput>
    return 0;
    8000558c:	4a81                	li	s5,0
    8000558e:	bff9                	j	8000556c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005590:	85da                	mv	a1,s6
    80005592:	4088                	lw	a0,0(s1)
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	4a6080e7          	jalr	1190(ra) # 80003a3a <ialloc>
    8000559c:	8a2a                	mv	s4,a0
    8000559e:	c529                	beqz	a0,800055e8 <create+0xee>
  ilock(ip);
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	632080e7          	jalr	1586(ra) # 80003bd2 <ilock>
  ip->major = major;
    800055a8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800055ac:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800055b0:	4905                	li	s2,1
    800055b2:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800055b6:	8552                	mv	a0,s4
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	54e080e7          	jalr	1358(ra) # 80003b06 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055c0:	032b0b63          	beq	s6,s2,800055f6 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800055c4:	004a2603          	lw	a2,4(s4)
    800055c8:	fb040593          	addi	a1,s0,-80
    800055cc:	8526                	mv	a0,s1
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	cf8080e7          	jalr	-776(ra) # 800042c6 <dirlink>
    800055d6:	06054f63          	bltz	a0,80005654 <create+0x15a>
  iunlockput(dp);
    800055da:	8526                	mv	a0,s1
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	858080e7          	jalr	-1960(ra) # 80003e34 <iunlockput>
  return ip;
    800055e4:	8ad2                	mv	s5,s4
    800055e6:	b759                	j	8000556c <create+0x72>
    iunlockput(dp);
    800055e8:	8526                	mv	a0,s1
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	84a080e7          	jalr	-1974(ra) # 80003e34 <iunlockput>
    return 0;
    800055f2:	8ad2                	mv	s5,s4
    800055f4:	bfa5                	j	8000556c <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055f6:	004a2603          	lw	a2,4(s4)
    800055fa:	00003597          	auipc	a1,0x3
    800055fe:	09e58593          	addi	a1,a1,158 # 80008698 <syscalls+0x2c0>
    80005602:	8552                	mv	a0,s4
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	cc2080e7          	jalr	-830(ra) # 800042c6 <dirlink>
    8000560c:	04054463          	bltz	a0,80005654 <create+0x15a>
    80005610:	40d0                	lw	a2,4(s1)
    80005612:	00003597          	auipc	a1,0x3
    80005616:	08e58593          	addi	a1,a1,142 # 800086a0 <syscalls+0x2c8>
    8000561a:	8552                	mv	a0,s4
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	caa080e7          	jalr	-854(ra) # 800042c6 <dirlink>
    80005624:	02054863          	bltz	a0,80005654 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005628:	004a2603          	lw	a2,4(s4)
    8000562c:	fb040593          	addi	a1,s0,-80
    80005630:	8526                	mv	a0,s1
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	c94080e7          	jalr	-876(ra) # 800042c6 <dirlink>
    8000563a:	00054d63          	bltz	a0,80005654 <create+0x15a>
    dp->nlink++;  // for ".."
    8000563e:	04a4d783          	lhu	a5,74(s1)
    80005642:	2785                	addiw	a5,a5,1
    80005644:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	4bc080e7          	jalr	1212(ra) # 80003b06 <iupdate>
    80005652:	b761                	j	800055da <create+0xe0>
  ip->nlink = 0;
    80005654:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005658:	8552                	mv	a0,s4
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	4ac080e7          	jalr	1196(ra) # 80003b06 <iupdate>
  iunlockput(ip);
    80005662:	8552                	mv	a0,s4
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	7d0080e7          	jalr	2000(ra) # 80003e34 <iunlockput>
  iunlockput(dp);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	7c6080e7          	jalr	1990(ra) # 80003e34 <iunlockput>
  return 0;
    80005676:	bddd                	j	8000556c <create+0x72>
    return 0;
    80005678:	8aaa                	mv	s5,a0
    8000567a:	bdcd                	j	8000556c <create+0x72>

000000008000567c <sys_dup>:
{
    8000567c:	7179                	addi	sp,sp,-48
    8000567e:	f406                	sd	ra,40(sp)
    80005680:	f022                	sd	s0,32(sp)
    80005682:	ec26                	sd	s1,24(sp)
    80005684:	e84a                	sd	s2,16(sp)
    80005686:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005688:	fd840613          	addi	a2,s0,-40
    8000568c:	4581                	li	a1,0
    8000568e:	4501                	li	a0,0
    80005690:	00000097          	auipc	ra,0x0
    80005694:	dc8080e7          	jalr	-568(ra) # 80005458 <argfd>
    return -1;
    80005698:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000569a:	02054363          	bltz	a0,800056c0 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000569e:	fd843903          	ld	s2,-40(s0)
    800056a2:	854a                	mv	a0,s2
    800056a4:	00000097          	auipc	ra,0x0
    800056a8:	e14080e7          	jalr	-492(ra) # 800054b8 <fdalloc>
    800056ac:	84aa                	mv	s1,a0
    return -1;
    800056ae:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056b0:	00054863          	bltz	a0,800056c0 <sys_dup+0x44>
  filedup(f);
    800056b4:	854a                	mv	a0,s2
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	334080e7          	jalr	820(ra) # 800049ea <filedup>
  return fd;
    800056be:	87a6                	mv	a5,s1
}
    800056c0:	853e                	mv	a0,a5
    800056c2:	70a2                	ld	ra,40(sp)
    800056c4:	7402                	ld	s0,32(sp)
    800056c6:	64e2                	ld	s1,24(sp)
    800056c8:	6942                	ld	s2,16(sp)
    800056ca:	6145                	addi	sp,sp,48
    800056cc:	8082                	ret

00000000800056ce <sys_read>:
{
    800056ce:	7179                	addi	sp,sp,-48
    800056d0:	f406                	sd	ra,40(sp)
    800056d2:	f022                	sd	s0,32(sp)
    800056d4:	1800                	addi	s0,sp,48
  READCOUNT++;
    800056d6:	00003717          	auipc	a4,0x3
    800056da:	1c270713          	addi	a4,a4,450 # 80008898 <READCOUNT>
    800056de:	631c                	ld	a5,0(a4)
    800056e0:	0785                	addi	a5,a5,1
    800056e2:	e31c                	sd	a5,0(a4)
  argaddr(1, &p);
    800056e4:	fd840593          	addi	a1,s0,-40
    800056e8:	4505                	li	a0,1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	86e080e7          	jalr	-1938(ra) # 80002f58 <argaddr>
  argint(2, &n);
    800056f2:	fe440593          	addi	a1,s0,-28
    800056f6:	4509                	li	a0,2
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	840080e7          	jalr	-1984(ra) # 80002f38 <argint>
  if(argfd(0, 0, &f) < 0)
    80005700:	fe840613          	addi	a2,s0,-24
    80005704:	4581                	li	a1,0
    80005706:	4501                	li	a0,0
    80005708:	00000097          	auipc	ra,0x0
    8000570c:	d50080e7          	jalr	-688(ra) # 80005458 <argfd>
    80005710:	87aa                	mv	a5,a0
    return -1;
    80005712:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005714:	0007cc63          	bltz	a5,8000572c <sys_read+0x5e>
  return fileread(f, p, n);
    80005718:	fe442603          	lw	a2,-28(s0)
    8000571c:	fd843583          	ld	a1,-40(s0)
    80005720:	fe843503          	ld	a0,-24(s0)
    80005724:	fffff097          	auipc	ra,0xfffff
    80005728:	452080e7          	jalr	1106(ra) # 80004b76 <fileread>
}
    8000572c:	70a2                	ld	ra,40(sp)
    8000572e:	7402                	ld	s0,32(sp)
    80005730:	6145                	addi	sp,sp,48
    80005732:	8082                	ret

0000000080005734 <sys_write>:
{
    80005734:	7179                	addi	sp,sp,-48
    80005736:	f406                	sd	ra,40(sp)
    80005738:	f022                	sd	s0,32(sp)
    8000573a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000573c:	fd840593          	addi	a1,s0,-40
    80005740:	4505                	li	a0,1
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	816080e7          	jalr	-2026(ra) # 80002f58 <argaddr>
  argint(2, &n);
    8000574a:	fe440593          	addi	a1,s0,-28
    8000574e:	4509                	li	a0,2
    80005750:	ffffd097          	auipc	ra,0xffffd
    80005754:	7e8080e7          	jalr	2024(ra) # 80002f38 <argint>
  if(argfd(0, 0, &f) < 0)
    80005758:	fe840613          	addi	a2,s0,-24
    8000575c:	4581                	li	a1,0
    8000575e:	4501                	li	a0,0
    80005760:	00000097          	auipc	ra,0x0
    80005764:	cf8080e7          	jalr	-776(ra) # 80005458 <argfd>
    80005768:	87aa                	mv	a5,a0
    return -1;
    8000576a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000576c:	0007cc63          	bltz	a5,80005784 <sys_write+0x50>
  return filewrite(f, p, n);
    80005770:	fe442603          	lw	a2,-28(s0)
    80005774:	fd843583          	ld	a1,-40(s0)
    80005778:	fe843503          	ld	a0,-24(s0)
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	4bc080e7          	jalr	1212(ra) # 80004c38 <filewrite>
}
    80005784:	70a2                	ld	ra,40(sp)
    80005786:	7402                	ld	s0,32(sp)
    80005788:	6145                	addi	sp,sp,48
    8000578a:	8082                	ret

000000008000578c <sys_close>:
{
    8000578c:	1101                	addi	sp,sp,-32
    8000578e:	ec06                	sd	ra,24(sp)
    80005790:	e822                	sd	s0,16(sp)
    80005792:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005794:	fe040613          	addi	a2,s0,-32
    80005798:	fec40593          	addi	a1,s0,-20
    8000579c:	4501                	li	a0,0
    8000579e:	00000097          	auipc	ra,0x0
    800057a2:	cba080e7          	jalr	-838(ra) # 80005458 <argfd>
    return -1;
    800057a6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057a8:	02054463          	bltz	a0,800057d0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057ac:	ffffc097          	auipc	ra,0xffffc
    800057b0:	1fa080e7          	jalr	506(ra) # 800019a6 <myproc>
    800057b4:	fec42783          	lw	a5,-20(s0)
    800057b8:	07e9                	addi	a5,a5,26
    800057ba:	078e                	slli	a5,a5,0x3
    800057bc:	953e                	add	a0,a0,a5
    800057be:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800057c2:	fe043503          	ld	a0,-32(s0)
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	276080e7          	jalr	630(ra) # 80004a3c <fileclose>
  return 0;
    800057ce:	4781                	li	a5,0
}
    800057d0:	853e                	mv	a0,a5
    800057d2:	60e2                	ld	ra,24(sp)
    800057d4:	6442                	ld	s0,16(sp)
    800057d6:	6105                	addi	sp,sp,32
    800057d8:	8082                	ret

00000000800057da <sys_fstat>:
{
    800057da:	1101                	addi	sp,sp,-32
    800057dc:	ec06                	sd	ra,24(sp)
    800057de:	e822                	sd	s0,16(sp)
    800057e0:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800057e2:	fe040593          	addi	a1,s0,-32
    800057e6:	4505                	li	a0,1
    800057e8:	ffffd097          	auipc	ra,0xffffd
    800057ec:	770080e7          	jalr	1904(ra) # 80002f58 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800057f0:	fe840613          	addi	a2,s0,-24
    800057f4:	4581                	li	a1,0
    800057f6:	4501                	li	a0,0
    800057f8:	00000097          	auipc	ra,0x0
    800057fc:	c60080e7          	jalr	-928(ra) # 80005458 <argfd>
    80005800:	87aa                	mv	a5,a0
    return -1;
    80005802:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005804:	0007ca63          	bltz	a5,80005818 <sys_fstat+0x3e>
  return filestat(f, st);
    80005808:	fe043583          	ld	a1,-32(s0)
    8000580c:	fe843503          	ld	a0,-24(s0)
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	2f4080e7          	jalr	756(ra) # 80004b04 <filestat>
}
    80005818:	60e2                	ld	ra,24(sp)
    8000581a:	6442                	ld	s0,16(sp)
    8000581c:	6105                	addi	sp,sp,32
    8000581e:	8082                	ret

0000000080005820 <sys_link>:
{
    80005820:	7169                	addi	sp,sp,-304
    80005822:	f606                	sd	ra,296(sp)
    80005824:	f222                	sd	s0,288(sp)
    80005826:	ee26                	sd	s1,280(sp)
    80005828:	ea4a                	sd	s2,272(sp)
    8000582a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000582c:	08000613          	li	a2,128
    80005830:	ed040593          	addi	a1,s0,-304
    80005834:	4501                	li	a0,0
    80005836:	ffffd097          	auipc	ra,0xffffd
    8000583a:	742080e7          	jalr	1858(ra) # 80002f78 <argstr>
    return -1;
    8000583e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005840:	10054e63          	bltz	a0,8000595c <sys_link+0x13c>
    80005844:	08000613          	li	a2,128
    80005848:	f5040593          	addi	a1,s0,-176
    8000584c:	4505                	li	a0,1
    8000584e:	ffffd097          	auipc	ra,0xffffd
    80005852:	72a080e7          	jalr	1834(ra) # 80002f78 <argstr>
    return -1;
    80005856:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005858:	10054263          	bltz	a0,8000595c <sys_link+0x13c>
  begin_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	d1c080e7          	jalr	-740(ra) # 80004578 <begin_op>
  if((ip = namei(old)) == 0){
    80005864:	ed040513          	addi	a0,s0,-304
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	b10080e7          	jalr	-1264(ra) # 80004378 <namei>
    80005870:	84aa                	mv	s1,a0
    80005872:	c551                	beqz	a0,800058fe <sys_link+0xde>
  ilock(ip);
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	35e080e7          	jalr	862(ra) # 80003bd2 <ilock>
  if(ip->type == T_DIR){
    8000587c:	04449703          	lh	a4,68(s1)
    80005880:	4785                	li	a5,1
    80005882:	08f70463          	beq	a4,a5,8000590a <sys_link+0xea>
  ip->nlink++;
    80005886:	04a4d783          	lhu	a5,74(s1)
    8000588a:	2785                	addiw	a5,a5,1
    8000588c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005890:	8526                	mv	a0,s1
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	274080e7          	jalr	628(ra) # 80003b06 <iupdate>
  iunlock(ip);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	3f8080e7          	jalr	1016(ra) # 80003c94 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058a4:	fd040593          	addi	a1,s0,-48
    800058a8:	f5040513          	addi	a0,s0,-176
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	aea080e7          	jalr	-1302(ra) # 80004396 <nameiparent>
    800058b4:	892a                	mv	s2,a0
    800058b6:	c935                	beqz	a0,8000592a <sys_link+0x10a>
  ilock(dp);
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	31a080e7          	jalr	794(ra) # 80003bd2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058c0:	00092703          	lw	a4,0(s2)
    800058c4:	409c                	lw	a5,0(s1)
    800058c6:	04f71d63          	bne	a4,a5,80005920 <sys_link+0x100>
    800058ca:	40d0                	lw	a2,4(s1)
    800058cc:	fd040593          	addi	a1,s0,-48
    800058d0:	854a                	mv	a0,s2
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	9f4080e7          	jalr	-1548(ra) # 800042c6 <dirlink>
    800058da:	04054363          	bltz	a0,80005920 <sys_link+0x100>
  iunlockput(dp);
    800058de:	854a                	mv	a0,s2
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	554080e7          	jalr	1364(ra) # 80003e34 <iunlockput>
  iput(ip);
    800058e8:	8526                	mv	a0,s1
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	4a2080e7          	jalr	1186(ra) # 80003d8c <iput>
  end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	d00080e7          	jalr	-768(ra) # 800045f2 <end_op>
  return 0;
    800058fa:	4781                	li	a5,0
    800058fc:	a085                	j	8000595c <sys_link+0x13c>
    end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	cf4080e7          	jalr	-780(ra) # 800045f2 <end_op>
    return -1;
    80005906:	57fd                	li	a5,-1
    80005908:	a891                	j	8000595c <sys_link+0x13c>
    iunlockput(ip);
    8000590a:	8526                	mv	a0,s1
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	528080e7          	jalr	1320(ra) # 80003e34 <iunlockput>
    end_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	cde080e7          	jalr	-802(ra) # 800045f2 <end_op>
    return -1;
    8000591c:	57fd                	li	a5,-1
    8000591e:	a83d                	j	8000595c <sys_link+0x13c>
    iunlockput(dp);
    80005920:	854a                	mv	a0,s2
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	512080e7          	jalr	1298(ra) # 80003e34 <iunlockput>
  ilock(ip);
    8000592a:	8526                	mv	a0,s1
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	2a6080e7          	jalr	678(ra) # 80003bd2 <ilock>
  ip->nlink--;
    80005934:	04a4d783          	lhu	a5,74(s1)
    80005938:	37fd                	addiw	a5,a5,-1
    8000593a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000593e:	8526                	mv	a0,s1
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	1c6080e7          	jalr	454(ra) # 80003b06 <iupdate>
  iunlockput(ip);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	4ea080e7          	jalr	1258(ra) # 80003e34 <iunlockput>
  end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	ca0080e7          	jalr	-864(ra) # 800045f2 <end_op>
  return -1;
    8000595a:	57fd                	li	a5,-1
}
    8000595c:	853e                	mv	a0,a5
    8000595e:	70b2                	ld	ra,296(sp)
    80005960:	7412                	ld	s0,288(sp)
    80005962:	64f2                	ld	s1,280(sp)
    80005964:	6952                	ld	s2,272(sp)
    80005966:	6155                	addi	sp,sp,304
    80005968:	8082                	ret

000000008000596a <sys_unlink>:
{
    8000596a:	7151                	addi	sp,sp,-240
    8000596c:	f586                	sd	ra,232(sp)
    8000596e:	f1a2                	sd	s0,224(sp)
    80005970:	eda6                	sd	s1,216(sp)
    80005972:	e9ca                	sd	s2,208(sp)
    80005974:	e5ce                	sd	s3,200(sp)
    80005976:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005978:	08000613          	li	a2,128
    8000597c:	f3040593          	addi	a1,s0,-208
    80005980:	4501                	li	a0,0
    80005982:	ffffd097          	auipc	ra,0xffffd
    80005986:	5f6080e7          	jalr	1526(ra) # 80002f78 <argstr>
    8000598a:	18054163          	bltz	a0,80005b0c <sys_unlink+0x1a2>
  begin_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	bea080e7          	jalr	-1046(ra) # 80004578 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005996:	fb040593          	addi	a1,s0,-80
    8000599a:	f3040513          	addi	a0,s0,-208
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	9f8080e7          	jalr	-1544(ra) # 80004396 <nameiparent>
    800059a6:	84aa                	mv	s1,a0
    800059a8:	c979                	beqz	a0,80005a7e <sys_unlink+0x114>
  ilock(dp);
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	228080e7          	jalr	552(ra) # 80003bd2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059b2:	00003597          	auipc	a1,0x3
    800059b6:	ce658593          	addi	a1,a1,-794 # 80008698 <syscalls+0x2c0>
    800059ba:	fb040513          	addi	a0,s0,-80
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	6de080e7          	jalr	1758(ra) # 8000409c <namecmp>
    800059c6:	14050a63          	beqz	a0,80005b1a <sys_unlink+0x1b0>
    800059ca:	00003597          	auipc	a1,0x3
    800059ce:	cd658593          	addi	a1,a1,-810 # 800086a0 <syscalls+0x2c8>
    800059d2:	fb040513          	addi	a0,s0,-80
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	6c6080e7          	jalr	1734(ra) # 8000409c <namecmp>
    800059de:	12050e63          	beqz	a0,80005b1a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059e2:	f2c40613          	addi	a2,s0,-212
    800059e6:	fb040593          	addi	a1,s0,-80
    800059ea:	8526                	mv	a0,s1
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	6ca080e7          	jalr	1738(ra) # 800040b6 <dirlookup>
    800059f4:	892a                	mv	s2,a0
    800059f6:	12050263          	beqz	a0,80005b1a <sys_unlink+0x1b0>
  ilock(ip);
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	1d8080e7          	jalr	472(ra) # 80003bd2 <ilock>
  if(ip->nlink < 1)
    80005a02:	04a91783          	lh	a5,74(s2)
    80005a06:	08f05263          	blez	a5,80005a8a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a0a:	04491703          	lh	a4,68(s2)
    80005a0e:	4785                	li	a5,1
    80005a10:	08f70563          	beq	a4,a5,80005a9a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a14:	4641                	li	a2,16
    80005a16:	4581                	li	a1,0
    80005a18:	fc040513          	addi	a0,s0,-64
    80005a1c:	ffffb097          	auipc	ra,0xffffb
    80005a20:	2b2080e7          	jalr	690(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a24:	4741                	li	a4,16
    80005a26:	f2c42683          	lw	a3,-212(s0)
    80005a2a:	fc040613          	addi	a2,s0,-64
    80005a2e:	4581                	li	a1,0
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	54c080e7          	jalr	1356(ra) # 80003f7e <writei>
    80005a3a:	47c1                	li	a5,16
    80005a3c:	0af51563          	bne	a0,a5,80005ae6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a40:	04491703          	lh	a4,68(s2)
    80005a44:	4785                	li	a5,1
    80005a46:	0af70863          	beq	a4,a5,80005af6 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a4a:	8526                	mv	a0,s1
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	3e8080e7          	jalr	1000(ra) # 80003e34 <iunlockput>
  ip->nlink--;
    80005a54:	04a95783          	lhu	a5,74(s2)
    80005a58:	37fd                	addiw	a5,a5,-1
    80005a5a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a5e:	854a                	mv	a0,s2
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	0a6080e7          	jalr	166(ra) # 80003b06 <iupdate>
  iunlockput(ip);
    80005a68:	854a                	mv	a0,s2
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	3ca080e7          	jalr	970(ra) # 80003e34 <iunlockput>
  end_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	b80080e7          	jalr	-1152(ra) # 800045f2 <end_op>
  return 0;
    80005a7a:	4501                	li	a0,0
    80005a7c:	a84d                	j	80005b2e <sys_unlink+0x1c4>
    end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	b74080e7          	jalr	-1164(ra) # 800045f2 <end_op>
    return -1;
    80005a86:	557d                	li	a0,-1
    80005a88:	a05d                	j	80005b2e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a8a:	00003517          	auipc	a0,0x3
    80005a8e:	c1e50513          	addi	a0,a0,-994 # 800086a8 <syscalls+0x2d0>
    80005a92:	ffffb097          	auipc	ra,0xffffb
    80005a96:	aaa080e7          	jalr	-1366(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a9a:	04c92703          	lw	a4,76(s2)
    80005a9e:	02000793          	li	a5,32
    80005aa2:	f6e7f9e3          	bgeu	a5,a4,80005a14 <sys_unlink+0xaa>
    80005aa6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aaa:	4741                	li	a4,16
    80005aac:	86ce                	mv	a3,s3
    80005aae:	f1840613          	addi	a2,s0,-232
    80005ab2:	4581                	li	a1,0
    80005ab4:	854a                	mv	a0,s2
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	3d0080e7          	jalr	976(ra) # 80003e86 <readi>
    80005abe:	47c1                	li	a5,16
    80005ac0:	00f51b63          	bne	a0,a5,80005ad6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ac4:	f1845783          	lhu	a5,-232(s0)
    80005ac8:	e7a1                	bnez	a5,80005b10 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aca:	29c1                	addiw	s3,s3,16
    80005acc:	04c92783          	lw	a5,76(s2)
    80005ad0:	fcf9ede3          	bltu	s3,a5,80005aaa <sys_unlink+0x140>
    80005ad4:	b781                	j	80005a14 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ad6:	00003517          	auipc	a0,0x3
    80005ada:	bea50513          	addi	a0,a0,-1046 # 800086c0 <syscalls+0x2e8>
    80005ade:	ffffb097          	auipc	ra,0xffffb
    80005ae2:	a5e080e7          	jalr	-1442(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005ae6:	00003517          	auipc	a0,0x3
    80005aea:	bf250513          	addi	a0,a0,-1038 # 800086d8 <syscalls+0x300>
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	a4e080e7          	jalr	-1458(ra) # 8000053c <panic>
    dp->nlink--;
    80005af6:	04a4d783          	lhu	a5,74(s1)
    80005afa:	37fd                	addiw	a5,a5,-1
    80005afc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b00:	8526                	mv	a0,s1
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	004080e7          	jalr	4(ra) # 80003b06 <iupdate>
    80005b0a:	b781                	j	80005a4a <sys_unlink+0xe0>
    return -1;
    80005b0c:	557d                	li	a0,-1
    80005b0e:	a005                	j	80005b2e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b10:	854a                	mv	a0,s2
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	322080e7          	jalr	802(ra) # 80003e34 <iunlockput>
  iunlockput(dp);
    80005b1a:	8526                	mv	a0,s1
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	318080e7          	jalr	792(ra) # 80003e34 <iunlockput>
  end_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	ace080e7          	jalr	-1330(ra) # 800045f2 <end_op>
  return -1;
    80005b2c:	557d                	li	a0,-1
}
    80005b2e:	70ae                	ld	ra,232(sp)
    80005b30:	740e                	ld	s0,224(sp)
    80005b32:	64ee                	ld	s1,216(sp)
    80005b34:	694e                	ld	s2,208(sp)
    80005b36:	69ae                	ld	s3,200(sp)
    80005b38:	616d                	addi	sp,sp,240
    80005b3a:	8082                	ret

0000000080005b3c <sys_open>:

uint64
sys_open(void)
{
    80005b3c:	7131                	addi	sp,sp,-192
    80005b3e:	fd06                	sd	ra,184(sp)
    80005b40:	f922                	sd	s0,176(sp)
    80005b42:	f526                	sd	s1,168(sp)
    80005b44:	f14a                	sd	s2,160(sp)
    80005b46:	ed4e                	sd	s3,152(sp)
    80005b48:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b4a:	f4c40593          	addi	a1,s0,-180
    80005b4e:	4505                	li	a0,1
    80005b50:	ffffd097          	auipc	ra,0xffffd
    80005b54:	3e8080e7          	jalr	1000(ra) # 80002f38 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b58:	08000613          	li	a2,128
    80005b5c:	f5040593          	addi	a1,s0,-176
    80005b60:	4501                	li	a0,0
    80005b62:	ffffd097          	auipc	ra,0xffffd
    80005b66:	416080e7          	jalr	1046(ra) # 80002f78 <argstr>
    80005b6a:	87aa                	mv	a5,a0
    return -1;
    80005b6c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b6e:	0a07c863          	bltz	a5,80005c1e <sys_open+0xe2>

  begin_op();
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	a06080e7          	jalr	-1530(ra) # 80004578 <begin_op>

  if(omode & O_CREATE){
    80005b7a:	f4c42783          	lw	a5,-180(s0)
    80005b7e:	2007f793          	andi	a5,a5,512
    80005b82:	cbdd                	beqz	a5,80005c38 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005b84:	4681                	li	a3,0
    80005b86:	4601                	li	a2,0
    80005b88:	4589                	li	a1,2
    80005b8a:	f5040513          	addi	a0,s0,-176
    80005b8e:	00000097          	auipc	ra,0x0
    80005b92:	96c080e7          	jalr	-1684(ra) # 800054fa <create>
    80005b96:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b98:	c951                	beqz	a0,80005c2c <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b9a:	04449703          	lh	a4,68(s1)
    80005b9e:	478d                	li	a5,3
    80005ba0:	00f71763          	bne	a4,a5,80005bae <sys_open+0x72>
    80005ba4:	0464d703          	lhu	a4,70(s1)
    80005ba8:	47a5                	li	a5,9
    80005baa:	0ce7ec63          	bltu	a5,a4,80005c82 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	dd2080e7          	jalr	-558(ra) # 80004980 <filealloc>
    80005bb6:	892a                	mv	s2,a0
    80005bb8:	c56d                	beqz	a0,80005ca2 <sys_open+0x166>
    80005bba:	00000097          	auipc	ra,0x0
    80005bbe:	8fe080e7          	jalr	-1794(ra) # 800054b8 <fdalloc>
    80005bc2:	89aa                	mv	s3,a0
    80005bc4:	0c054a63          	bltz	a0,80005c98 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bc8:	04449703          	lh	a4,68(s1)
    80005bcc:	478d                	li	a5,3
    80005bce:	0ef70563          	beq	a4,a5,80005cb8 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bd2:	4789                	li	a5,2
    80005bd4:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005bd8:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005bdc:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005be0:	f4c42783          	lw	a5,-180(s0)
    80005be4:	0017c713          	xori	a4,a5,1
    80005be8:	8b05                	andi	a4,a4,1
    80005bea:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bee:	0037f713          	andi	a4,a5,3
    80005bf2:	00e03733          	snez	a4,a4
    80005bf6:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bfa:	4007f793          	andi	a5,a5,1024
    80005bfe:	c791                	beqz	a5,80005c0a <sys_open+0xce>
    80005c00:	04449703          	lh	a4,68(s1)
    80005c04:	4789                	li	a5,2
    80005c06:	0cf70063          	beq	a4,a5,80005cc6 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005c0a:	8526                	mv	a0,s1
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	088080e7          	jalr	136(ra) # 80003c94 <iunlock>
  end_op();
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	9de080e7          	jalr	-1570(ra) # 800045f2 <end_op>

  return fd;
    80005c1c:	854e                	mv	a0,s3
}
    80005c1e:	70ea                	ld	ra,184(sp)
    80005c20:	744a                	ld	s0,176(sp)
    80005c22:	74aa                	ld	s1,168(sp)
    80005c24:	790a                	ld	s2,160(sp)
    80005c26:	69ea                	ld	s3,152(sp)
    80005c28:	6129                	addi	sp,sp,192
    80005c2a:	8082                	ret
      end_op();
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	9c6080e7          	jalr	-1594(ra) # 800045f2 <end_op>
      return -1;
    80005c34:	557d                	li	a0,-1
    80005c36:	b7e5                	j	80005c1e <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005c38:	f5040513          	addi	a0,s0,-176
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	73c080e7          	jalr	1852(ra) # 80004378 <namei>
    80005c44:	84aa                	mv	s1,a0
    80005c46:	c905                	beqz	a0,80005c76 <sys_open+0x13a>
    ilock(ip);
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	f8a080e7          	jalr	-118(ra) # 80003bd2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c50:	04449703          	lh	a4,68(s1)
    80005c54:	4785                	li	a5,1
    80005c56:	f4f712e3          	bne	a4,a5,80005b9a <sys_open+0x5e>
    80005c5a:	f4c42783          	lw	a5,-180(s0)
    80005c5e:	dba1                	beqz	a5,80005bae <sys_open+0x72>
      iunlockput(ip);
    80005c60:	8526                	mv	a0,s1
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	1d2080e7          	jalr	466(ra) # 80003e34 <iunlockput>
      end_op();
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	988080e7          	jalr	-1656(ra) # 800045f2 <end_op>
      return -1;
    80005c72:	557d                	li	a0,-1
    80005c74:	b76d                	j	80005c1e <sys_open+0xe2>
      end_op();
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	97c080e7          	jalr	-1668(ra) # 800045f2 <end_op>
      return -1;
    80005c7e:	557d                	li	a0,-1
    80005c80:	bf79                	j	80005c1e <sys_open+0xe2>
    iunlockput(ip);
    80005c82:	8526                	mv	a0,s1
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	1b0080e7          	jalr	432(ra) # 80003e34 <iunlockput>
    end_op();
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	966080e7          	jalr	-1690(ra) # 800045f2 <end_op>
    return -1;
    80005c94:	557d                	li	a0,-1
    80005c96:	b761                	j	80005c1e <sys_open+0xe2>
      fileclose(f);
    80005c98:	854a                	mv	a0,s2
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	da2080e7          	jalr	-606(ra) # 80004a3c <fileclose>
    iunlockput(ip);
    80005ca2:	8526                	mv	a0,s1
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	190080e7          	jalr	400(ra) # 80003e34 <iunlockput>
    end_op();
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	946080e7          	jalr	-1722(ra) # 800045f2 <end_op>
    return -1;
    80005cb4:	557d                	li	a0,-1
    80005cb6:	b7a5                	j	80005c1e <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005cb8:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005cbc:	04649783          	lh	a5,70(s1)
    80005cc0:	02f91223          	sh	a5,36(s2)
    80005cc4:	bf21                	j	80005bdc <sys_open+0xa0>
    itrunc(ip);
    80005cc6:	8526                	mv	a0,s1
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	018080e7          	jalr	24(ra) # 80003ce0 <itrunc>
    80005cd0:	bf2d                	j	80005c0a <sys_open+0xce>

0000000080005cd2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cd2:	7175                	addi	sp,sp,-144
    80005cd4:	e506                	sd	ra,136(sp)
    80005cd6:	e122                	sd	s0,128(sp)
    80005cd8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	89e080e7          	jalr	-1890(ra) # 80004578 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ce2:	08000613          	li	a2,128
    80005ce6:	f7040593          	addi	a1,s0,-144
    80005cea:	4501                	li	a0,0
    80005cec:	ffffd097          	auipc	ra,0xffffd
    80005cf0:	28c080e7          	jalr	652(ra) # 80002f78 <argstr>
    80005cf4:	02054963          	bltz	a0,80005d26 <sys_mkdir+0x54>
    80005cf8:	4681                	li	a3,0
    80005cfa:	4601                	li	a2,0
    80005cfc:	4585                	li	a1,1
    80005cfe:	f7040513          	addi	a0,s0,-144
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	7f8080e7          	jalr	2040(ra) # 800054fa <create>
    80005d0a:	cd11                	beqz	a0,80005d26 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	128080e7          	jalr	296(ra) # 80003e34 <iunlockput>
  end_op();
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	8de080e7          	jalr	-1826(ra) # 800045f2 <end_op>
  return 0;
    80005d1c:	4501                	li	a0,0
}
    80005d1e:	60aa                	ld	ra,136(sp)
    80005d20:	640a                	ld	s0,128(sp)
    80005d22:	6149                	addi	sp,sp,144
    80005d24:	8082                	ret
    end_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	8cc080e7          	jalr	-1844(ra) # 800045f2 <end_op>
    return -1;
    80005d2e:	557d                	li	a0,-1
    80005d30:	b7fd                	j	80005d1e <sys_mkdir+0x4c>

0000000080005d32 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d32:	7135                	addi	sp,sp,-160
    80005d34:	ed06                	sd	ra,152(sp)
    80005d36:	e922                	sd	s0,144(sp)
    80005d38:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	83e080e7          	jalr	-1986(ra) # 80004578 <begin_op>
  argint(1, &major);
    80005d42:	f6c40593          	addi	a1,s0,-148
    80005d46:	4505                	li	a0,1
    80005d48:	ffffd097          	auipc	ra,0xffffd
    80005d4c:	1f0080e7          	jalr	496(ra) # 80002f38 <argint>
  argint(2, &minor);
    80005d50:	f6840593          	addi	a1,s0,-152
    80005d54:	4509                	li	a0,2
    80005d56:	ffffd097          	auipc	ra,0xffffd
    80005d5a:	1e2080e7          	jalr	482(ra) # 80002f38 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d5e:	08000613          	li	a2,128
    80005d62:	f7040593          	addi	a1,s0,-144
    80005d66:	4501                	li	a0,0
    80005d68:	ffffd097          	auipc	ra,0xffffd
    80005d6c:	210080e7          	jalr	528(ra) # 80002f78 <argstr>
    80005d70:	02054b63          	bltz	a0,80005da6 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d74:	f6841683          	lh	a3,-152(s0)
    80005d78:	f6c41603          	lh	a2,-148(s0)
    80005d7c:	458d                	li	a1,3
    80005d7e:	f7040513          	addi	a0,s0,-144
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	778080e7          	jalr	1912(ra) # 800054fa <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d8a:	cd11                	beqz	a0,80005da6 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d8c:	ffffe097          	auipc	ra,0xffffe
    80005d90:	0a8080e7          	jalr	168(ra) # 80003e34 <iunlockput>
  end_op();
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	85e080e7          	jalr	-1954(ra) # 800045f2 <end_op>
  return 0;
    80005d9c:	4501                	li	a0,0
}
    80005d9e:	60ea                	ld	ra,152(sp)
    80005da0:	644a                	ld	s0,144(sp)
    80005da2:	610d                	addi	sp,sp,160
    80005da4:	8082                	ret
    end_op();
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	84c080e7          	jalr	-1972(ra) # 800045f2 <end_op>
    return -1;
    80005dae:	557d                	li	a0,-1
    80005db0:	b7fd                	j	80005d9e <sys_mknod+0x6c>

0000000080005db2 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005db2:	7135                	addi	sp,sp,-160
    80005db4:	ed06                	sd	ra,152(sp)
    80005db6:	e922                	sd	s0,144(sp)
    80005db8:	e526                	sd	s1,136(sp)
    80005dba:	e14a                	sd	s2,128(sp)
    80005dbc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dbe:	ffffc097          	auipc	ra,0xffffc
    80005dc2:	be8080e7          	jalr	-1048(ra) # 800019a6 <myproc>
    80005dc6:	892a                	mv	s2,a0
  
  begin_op();
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	7b0080e7          	jalr	1968(ra) # 80004578 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dd0:	08000613          	li	a2,128
    80005dd4:	f6040593          	addi	a1,s0,-160
    80005dd8:	4501                	li	a0,0
    80005dda:	ffffd097          	auipc	ra,0xffffd
    80005dde:	19e080e7          	jalr	414(ra) # 80002f78 <argstr>
    80005de2:	04054b63          	bltz	a0,80005e38 <sys_chdir+0x86>
    80005de6:	f6040513          	addi	a0,s0,-160
    80005dea:	ffffe097          	auipc	ra,0xffffe
    80005dee:	58e080e7          	jalr	1422(ra) # 80004378 <namei>
    80005df2:	84aa                	mv	s1,a0
    80005df4:	c131                	beqz	a0,80005e38 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005df6:	ffffe097          	auipc	ra,0xffffe
    80005dfa:	ddc080e7          	jalr	-548(ra) # 80003bd2 <ilock>
  if(ip->type != T_DIR){
    80005dfe:	04449703          	lh	a4,68(s1)
    80005e02:	4785                	li	a5,1
    80005e04:	04f71063          	bne	a4,a5,80005e44 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e08:	8526                	mv	a0,s1
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	e8a080e7          	jalr	-374(ra) # 80003c94 <iunlock>
  iput(p->cwd);
    80005e12:	15093503          	ld	a0,336(s2)
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	f76080e7          	jalr	-138(ra) # 80003d8c <iput>
  end_op();
    80005e1e:	ffffe097          	auipc	ra,0xffffe
    80005e22:	7d4080e7          	jalr	2004(ra) # 800045f2 <end_op>
  p->cwd = ip;
    80005e26:	14993823          	sd	s1,336(s2)
  return 0;
    80005e2a:	4501                	li	a0,0
}
    80005e2c:	60ea                	ld	ra,152(sp)
    80005e2e:	644a                	ld	s0,144(sp)
    80005e30:	64aa                	ld	s1,136(sp)
    80005e32:	690a                	ld	s2,128(sp)
    80005e34:	610d                	addi	sp,sp,160
    80005e36:	8082                	ret
    end_op();
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	7ba080e7          	jalr	1978(ra) # 800045f2 <end_op>
    return -1;
    80005e40:	557d                	li	a0,-1
    80005e42:	b7ed                	j	80005e2c <sys_chdir+0x7a>
    iunlockput(ip);
    80005e44:	8526                	mv	a0,s1
    80005e46:	ffffe097          	auipc	ra,0xffffe
    80005e4a:	fee080e7          	jalr	-18(ra) # 80003e34 <iunlockput>
    end_op();
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	7a4080e7          	jalr	1956(ra) # 800045f2 <end_op>
    return -1;
    80005e56:	557d                	li	a0,-1
    80005e58:	bfd1                	j	80005e2c <sys_chdir+0x7a>

0000000080005e5a <sys_exec>:

uint64
sys_exec(void)
{
    80005e5a:	7121                	addi	sp,sp,-448
    80005e5c:	ff06                	sd	ra,440(sp)
    80005e5e:	fb22                	sd	s0,432(sp)
    80005e60:	f726                	sd	s1,424(sp)
    80005e62:	f34a                	sd	s2,416(sp)
    80005e64:	ef4e                	sd	s3,408(sp)
    80005e66:	eb52                	sd	s4,400(sp)
    80005e68:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e6a:	e4840593          	addi	a1,s0,-440
    80005e6e:	4505                	li	a0,1
    80005e70:	ffffd097          	auipc	ra,0xffffd
    80005e74:	0e8080e7          	jalr	232(ra) # 80002f58 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e78:	08000613          	li	a2,128
    80005e7c:	f5040593          	addi	a1,s0,-176
    80005e80:	4501                	li	a0,0
    80005e82:	ffffd097          	auipc	ra,0xffffd
    80005e86:	0f6080e7          	jalr	246(ra) # 80002f78 <argstr>
    80005e8a:	87aa                	mv	a5,a0
    return -1;
    80005e8c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e8e:	0c07c263          	bltz	a5,80005f52 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005e92:	10000613          	li	a2,256
    80005e96:	4581                	li	a1,0
    80005e98:	e5040513          	addi	a0,s0,-432
    80005e9c:	ffffb097          	auipc	ra,0xffffb
    80005ea0:	e32080e7          	jalr	-462(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ea4:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005ea8:	89a6                	mv	s3,s1
    80005eaa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005eac:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005eb0:	00391513          	slli	a0,s2,0x3
    80005eb4:	e4040593          	addi	a1,s0,-448
    80005eb8:	e4843783          	ld	a5,-440(s0)
    80005ebc:	953e                	add	a0,a0,a5
    80005ebe:	ffffd097          	auipc	ra,0xffffd
    80005ec2:	fdc080e7          	jalr	-36(ra) # 80002e9a <fetchaddr>
    80005ec6:	02054a63          	bltz	a0,80005efa <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005eca:	e4043783          	ld	a5,-448(s0)
    80005ece:	c3b9                	beqz	a5,80005f14 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ed0:	ffffb097          	auipc	ra,0xffffb
    80005ed4:	c12080e7          	jalr	-1006(ra) # 80000ae2 <kalloc>
    80005ed8:	85aa                	mv	a1,a0
    80005eda:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ede:	cd11                	beqz	a0,80005efa <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ee0:	6605                	lui	a2,0x1
    80005ee2:	e4043503          	ld	a0,-448(s0)
    80005ee6:	ffffd097          	auipc	ra,0xffffd
    80005eea:	006080e7          	jalr	6(ra) # 80002eec <fetchstr>
    80005eee:	00054663          	bltz	a0,80005efa <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005ef2:	0905                	addi	s2,s2,1
    80005ef4:	09a1                	addi	s3,s3,8
    80005ef6:	fb491de3          	bne	s2,s4,80005eb0 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005efa:	f5040913          	addi	s2,s0,-176
    80005efe:	6088                	ld	a0,0(s1)
    80005f00:	c921                	beqz	a0,80005f50 <sys_exec+0xf6>
    kfree(argv[i]);
    80005f02:	ffffb097          	auipc	ra,0xffffb
    80005f06:	ae2080e7          	jalr	-1310(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f0a:	04a1                	addi	s1,s1,8
    80005f0c:	ff2499e3          	bne	s1,s2,80005efe <sys_exec+0xa4>
  return -1;
    80005f10:	557d                	li	a0,-1
    80005f12:	a081                	j	80005f52 <sys_exec+0xf8>
      argv[i] = 0;
    80005f14:	0009079b          	sext.w	a5,s2
    80005f18:	078e                	slli	a5,a5,0x3
    80005f1a:	fd078793          	addi	a5,a5,-48
    80005f1e:	97a2                	add	a5,a5,s0
    80005f20:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005f24:	e5040593          	addi	a1,s0,-432
    80005f28:	f5040513          	addi	a0,s0,-176
    80005f2c:	fffff097          	auipc	ra,0xfffff
    80005f30:	186080e7          	jalr	390(ra) # 800050b2 <exec>
    80005f34:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f36:	f5040993          	addi	s3,s0,-176
    80005f3a:	6088                	ld	a0,0(s1)
    80005f3c:	c901                	beqz	a0,80005f4c <sys_exec+0xf2>
    kfree(argv[i]);
    80005f3e:	ffffb097          	auipc	ra,0xffffb
    80005f42:	aa6080e7          	jalr	-1370(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f46:	04a1                	addi	s1,s1,8
    80005f48:	ff3499e3          	bne	s1,s3,80005f3a <sys_exec+0xe0>
  return ret;
    80005f4c:	854a                	mv	a0,s2
    80005f4e:	a011                	j	80005f52 <sys_exec+0xf8>
  return -1;
    80005f50:	557d                	li	a0,-1
}
    80005f52:	70fa                	ld	ra,440(sp)
    80005f54:	745a                	ld	s0,432(sp)
    80005f56:	74ba                	ld	s1,424(sp)
    80005f58:	791a                	ld	s2,416(sp)
    80005f5a:	69fa                	ld	s3,408(sp)
    80005f5c:	6a5a                	ld	s4,400(sp)
    80005f5e:	6139                	addi	sp,sp,448
    80005f60:	8082                	ret

0000000080005f62 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f62:	7139                	addi	sp,sp,-64
    80005f64:	fc06                	sd	ra,56(sp)
    80005f66:	f822                	sd	s0,48(sp)
    80005f68:	f426                	sd	s1,40(sp)
    80005f6a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f6c:	ffffc097          	auipc	ra,0xffffc
    80005f70:	a3a080e7          	jalr	-1478(ra) # 800019a6 <myproc>
    80005f74:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f76:	fd840593          	addi	a1,s0,-40
    80005f7a:	4501                	li	a0,0
    80005f7c:	ffffd097          	auipc	ra,0xffffd
    80005f80:	fdc080e7          	jalr	-36(ra) # 80002f58 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f84:	fc840593          	addi	a1,s0,-56
    80005f88:	fd040513          	addi	a0,s0,-48
    80005f8c:	fffff097          	auipc	ra,0xfffff
    80005f90:	ddc080e7          	jalr	-548(ra) # 80004d68 <pipealloc>
    return -1;
    80005f94:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f96:	0c054463          	bltz	a0,8000605e <sys_pipe+0xfc>
  fd0 = -1;
    80005f9a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f9e:	fd043503          	ld	a0,-48(s0)
    80005fa2:	fffff097          	auipc	ra,0xfffff
    80005fa6:	516080e7          	jalr	1302(ra) # 800054b8 <fdalloc>
    80005faa:	fca42223          	sw	a0,-60(s0)
    80005fae:	08054b63          	bltz	a0,80006044 <sys_pipe+0xe2>
    80005fb2:	fc843503          	ld	a0,-56(s0)
    80005fb6:	fffff097          	auipc	ra,0xfffff
    80005fba:	502080e7          	jalr	1282(ra) # 800054b8 <fdalloc>
    80005fbe:	fca42023          	sw	a0,-64(s0)
    80005fc2:	06054863          	bltz	a0,80006032 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fc6:	4691                	li	a3,4
    80005fc8:	fc440613          	addi	a2,s0,-60
    80005fcc:	fd843583          	ld	a1,-40(s0)
    80005fd0:	68a8                	ld	a0,80(s1)
    80005fd2:	ffffb097          	auipc	ra,0xffffb
    80005fd6:	694080e7          	jalr	1684(ra) # 80001666 <copyout>
    80005fda:	02054063          	bltz	a0,80005ffa <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fde:	4691                	li	a3,4
    80005fe0:	fc040613          	addi	a2,s0,-64
    80005fe4:	fd843583          	ld	a1,-40(s0)
    80005fe8:	0591                	addi	a1,a1,4
    80005fea:	68a8                	ld	a0,80(s1)
    80005fec:	ffffb097          	auipc	ra,0xffffb
    80005ff0:	67a080e7          	jalr	1658(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ff4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ff6:	06055463          	bgez	a0,8000605e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ffa:	fc442783          	lw	a5,-60(s0)
    80005ffe:	07e9                	addi	a5,a5,26
    80006000:	078e                	slli	a5,a5,0x3
    80006002:	97a6                	add	a5,a5,s1
    80006004:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006008:	fc042783          	lw	a5,-64(s0)
    8000600c:	07e9                	addi	a5,a5,26
    8000600e:	078e                	slli	a5,a5,0x3
    80006010:	94be                	add	s1,s1,a5
    80006012:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006016:	fd043503          	ld	a0,-48(s0)
    8000601a:	fffff097          	auipc	ra,0xfffff
    8000601e:	a22080e7          	jalr	-1502(ra) # 80004a3c <fileclose>
    fileclose(wf);
    80006022:	fc843503          	ld	a0,-56(s0)
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	a16080e7          	jalr	-1514(ra) # 80004a3c <fileclose>
    return -1;
    8000602e:	57fd                	li	a5,-1
    80006030:	a03d                	j	8000605e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006032:	fc442783          	lw	a5,-60(s0)
    80006036:	0007c763          	bltz	a5,80006044 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000603a:	07e9                	addi	a5,a5,26
    8000603c:	078e                	slli	a5,a5,0x3
    8000603e:	97a6                	add	a5,a5,s1
    80006040:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006044:	fd043503          	ld	a0,-48(s0)
    80006048:	fffff097          	auipc	ra,0xfffff
    8000604c:	9f4080e7          	jalr	-1548(ra) # 80004a3c <fileclose>
    fileclose(wf);
    80006050:	fc843503          	ld	a0,-56(s0)
    80006054:	fffff097          	auipc	ra,0xfffff
    80006058:	9e8080e7          	jalr	-1560(ra) # 80004a3c <fileclose>
    return -1;
    8000605c:	57fd                	li	a5,-1
}
    8000605e:	853e                	mv	a0,a5
    80006060:	70e2                	ld	ra,56(sp)
    80006062:	7442                	ld	s0,48(sp)
    80006064:	74a2                	ld	s1,40(sp)
    80006066:	6121                	addi	sp,sp,64
    80006068:	8082                	ret
    8000606a:	0000                	unimp
    8000606c:	0000                	unimp
	...

0000000080006070 <kernelvec>:
    80006070:	7111                	addi	sp,sp,-256
    80006072:	e006                	sd	ra,0(sp)
    80006074:	e40a                	sd	sp,8(sp)
    80006076:	e80e                	sd	gp,16(sp)
    80006078:	ec12                	sd	tp,24(sp)
    8000607a:	f016                	sd	t0,32(sp)
    8000607c:	f41a                	sd	t1,40(sp)
    8000607e:	f81e                	sd	t2,48(sp)
    80006080:	fc22                	sd	s0,56(sp)
    80006082:	e0a6                	sd	s1,64(sp)
    80006084:	e4aa                	sd	a0,72(sp)
    80006086:	e8ae                	sd	a1,80(sp)
    80006088:	ecb2                	sd	a2,88(sp)
    8000608a:	f0b6                	sd	a3,96(sp)
    8000608c:	f4ba                	sd	a4,104(sp)
    8000608e:	f8be                	sd	a5,112(sp)
    80006090:	fcc2                	sd	a6,120(sp)
    80006092:	e146                	sd	a7,128(sp)
    80006094:	e54a                	sd	s2,136(sp)
    80006096:	e94e                	sd	s3,144(sp)
    80006098:	ed52                	sd	s4,152(sp)
    8000609a:	f156                	sd	s5,160(sp)
    8000609c:	f55a                	sd	s6,168(sp)
    8000609e:	f95e                	sd	s7,176(sp)
    800060a0:	fd62                	sd	s8,184(sp)
    800060a2:	e1e6                	sd	s9,192(sp)
    800060a4:	e5ea                	sd	s10,200(sp)
    800060a6:	e9ee                	sd	s11,208(sp)
    800060a8:	edf2                	sd	t3,216(sp)
    800060aa:	f1f6                	sd	t4,224(sp)
    800060ac:	f5fa                	sd	t5,232(sp)
    800060ae:	f9fe                	sd	t6,240(sp)
    800060b0:	ccdfc0ef          	jal	ra,80002d7c <kerneltrap>
    800060b4:	6082                	ld	ra,0(sp)
    800060b6:	6122                	ld	sp,8(sp)
    800060b8:	61c2                	ld	gp,16(sp)
    800060ba:	7282                	ld	t0,32(sp)
    800060bc:	7322                	ld	t1,40(sp)
    800060be:	73c2                	ld	t2,48(sp)
    800060c0:	7462                	ld	s0,56(sp)
    800060c2:	6486                	ld	s1,64(sp)
    800060c4:	6526                	ld	a0,72(sp)
    800060c6:	65c6                	ld	a1,80(sp)
    800060c8:	6666                	ld	a2,88(sp)
    800060ca:	7686                	ld	a3,96(sp)
    800060cc:	7726                	ld	a4,104(sp)
    800060ce:	77c6                	ld	a5,112(sp)
    800060d0:	7866                	ld	a6,120(sp)
    800060d2:	688a                	ld	a7,128(sp)
    800060d4:	692a                	ld	s2,136(sp)
    800060d6:	69ca                	ld	s3,144(sp)
    800060d8:	6a6a                	ld	s4,152(sp)
    800060da:	7a8a                	ld	s5,160(sp)
    800060dc:	7b2a                	ld	s6,168(sp)
    800060de:	7bca                	ld	s7,176(sp)
    800060e0:	7c6a                	ld	s8,184(sp)
    800060e2:	6c8e                	ld	s9,192(sp)
    800060e4:	6d2e                	ld	s10,200(sp)
    800060e6:	6dce                	ld	s11,208(sp)
    800060e8:	6e6e                	ld	t3,216(sp)
    800060ea:	7e8e                	ld	t4,224(sp)
    800060ec:	7f2e                	ld	t5,232(sp)
    800060ee:	7fce                	ld	t6,240(sp)
    800060f0:	6111                	addi	sp,sp,256
    800060f2:	10200073          	sret
    800060f6:	00000013          	nop
    800060fa:	00000013          	nop
    800060fe:	0001                	nop

0000000080006100 <timervec>:
    80006100:	34051573          	csrrw	a0,mscratch,a0
    80006104:	e10c                	sd	a1,0(a0)
    80006106:	e510                	sd	a2,8(a0)
    80006108:	e914                	sd	a3,16(a0)
    8000610a:	6d0c                	ld	a1,24(a0)
    8000610c:	7110                	ld	a2,32(a0)
    8000610e:	6194                	ld	a3,0(a1)
    80006110:	96b2                	add	a3,a3,a2
    80006112:	e194                	sd	a3,0(a1)
    80006114:	4589                	li	a1,2
    80006116:	14459073          	csrw	sip,a1
    8000611a:	6914                	ld	a3,16(a0)
    8000611c:	6510                	ld	a2,8(a0)
    8000611e:	610c                	ld	a1,0(a0)
    80006120:	34051573          	csrrw	a0,mscratch,a0
    80006124:	30200073          	mret
	...

000000008000612a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000612a:	1141                	addi	sp,sp,-16
    8000612c:	e422                	sd	s0,8(sp)
    8000612e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006130:	0c0007b7          	lui	a5,0xc000
    80006134:	4705                	li	a4,1
    80006136:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006138:	c3d8                	sw	a4,4(a5)
}
    8000613a:	6422                	ld	s0,8(sp)
    8000613c:	0141                	addi	sp,sp,16
    8000613e:	8082                	ret

0000000080006140 <plicinithart>:

void
plicinithart(void)
{
    80006140:	1141                	addi	sp,sp,-16
    80006142:	e406                	sd	ra,8(sp)
    80006144:	e022                	sd	s0,0(sp)
    80006146:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	832080e7          	jalr	-1998(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006150:	0085171b          	slliw	a4,a0,0x8
    80006154:	0c0027b7          	lui	a5,0xc002
    80006158:	97ba                	add	a5,a5,a4
    8000615a:	40200713          	li	a4,1026
    8000615e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006162:	00d5151b          	slliw	a0,a0,0xd
    80006166:	0c2017b7          	lui	a5,0xc201
    8000616a:	97aa                	add	a5,a5,a0
    8000616c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006170:	60a2                	ld	ra,8(sp)
    80006172:	6402                	ld	s0,0(sp)
    80006174:	0141                	addi	sp,sp,16
    80006176:	8082                	ret

0000000080006178 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006178:	1141                	addi	sp,sp,-16
    8000617a:	e406                	sd	ra,8(sp)
    8000617c:	e022                	sd	s0,0(sp)
    8000617e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	7fa080e7          	jalr	2042(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006188:	00d5151b          	slliw	a0,a0,0xd
    8000618c:	0c2017b7          	lui	a5,0xc201
    80006190:	97aa                	add	a5,a5,a0
  return irq;
}
    80006192:	43c8                	lw	a0,4(a5)
    80006194:	60a2                	ld	ra,8(sp)
    80006196:	6402                	ld	s0,0(sp)
    80006198:	0141                	addi	sp,sp,16
    8000619a:	8082                	ret

000000008000619c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000619c:	1101                	addi	sp,sp,-32
    8000619e:	ec06                	sd	ra,24(sp)
    800061a0:	e822                	sd	s0,16(sp)
    800061a2:	e426                	sd	s1,8(sp)
    800061a4:	1000                	addi	s0,sp,32
    800061a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061a8:	ffffb097          	auipc	ra,0xffffb
    800061ac:	7d2080e7          	jalr	2002(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061b0:	00d5151b          	slliw	a0,a0,0xd
    800061b4:	0c2017b7          	lui	a5,0xc201
    800061b8:	97aa                	add	a5,a5,a0
    800061ba:	c3c4                	sw	s1,4(a5)
}
    800061bc:	60e2                	ld	ra,24(sp)
    800061be:	6442                	ld	s0,16(sp)
    800061c0:	64a2                	ld	s1,8(sp)
    800061c2:	6105                	addi	sp,sp,32
    800061c4:	8082                	ret

00000000800061c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061c6:	1141                	addi	sp,sp,-16
    800061c8:	e406                	sd	ra,8(sp)
    800061ca:	e022                	sd	s0,0(sp)
    800061cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061ce:	479d                	li	a5,7
    800061d0:	04a7cc63          	blt	a5,a0,80006228 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800061d4:	0001e797          	auipc	a5,0x1e
    800061d8:	c9c78793          	addi	a5,a5,-868 # 80023e70 <disk>
    800061dc:	97aa                	add	a5,a5,a0
    800061de:	0187c783          	lbu	a5,24(a5)
    800061e2:	ebb9                	bnez	a5,80006238 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061e4:	00451693          	slli	a3,a0,0x4
    800061e8:	0001e797          	auipc	a5,0x1e
    800061ec:	c8878793          	addi	a5,a5,-888 # 80023e70 <disk>
    800061f0:	6398                	ld	a4,0(a5)
    800061f2:	9736                	add	a4,a4,a3
    800061f4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800061f8:	6398                	ld	a4,0(a5)
    800061fa:	9736                	add	a4,a4,a3
    800061fc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006200:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006204:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006208:	97aa                	add	a5,a5,a0
    8000620a:	4705                	li	a4,1
    8000620c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006210:	0001e517          	auipc	a0,0x1e
    80006214:	c7850513          	addi	a0,a0,-904 # 80023e88 <disk+0x18>
    80006218:	ffffc097          	auipc	ra,0xffffc
    8000621c:	092080e7          	jalr	146(ra) # 800022aa <wakeup>
}
    80006220:	60a2                	ld	ra,8(sp)
    80006222:	6402                	ld	s0,0(sp)
    80006224:	0141                	addi	sp,sp,16
    80006226:	8082                	ret
    panic("free_desc 1");
    80006228:	00002517          	auipc	a0,0x2
    8000622c:	4c050513          	addi	a0,a0,1216 # 800086e8 <syscalls+0x310>
    80006230:	ffffa097          	auipc	ra,0xffffa
    80006234:	30c080e7          	jalr	780(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006238:	00002517          	auipc	a0,0x2
    8000623c:	4c050513          	addi	a0,a0,1216 # 800086f8 <syscalls+0x320>
    80006240:	ffffa097          	auipc	ra,0xffffa
    80006244:	2fc080e7          	jalr	764(ra) # 8000053c <panic>

0000000080006248 <virtio_disk_init>:
{
    80006248:	1101                	addi	sp,sp,-32
    8000624a:	ec06                	sd	ra,24(sp)
    8000624c:	e822                	sd	s0,16(sp)
    8000624e:	e426                	sd	s1,8(sp)
    80006250:	e04a                	sd	s2,0(sp)
    80006252:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006254:	00002597          	auipc	a1,0x2
    80006258:	4b458593          	addi	a1,a1,1204 # 80008708 <syscalls+0x330>
    8000625c:	0001e517          	auipc	a0,0x1e
    80006260:	d3c50513          	addi	a0,a0,-708 # 80023f98 <disk+0x128>
    80006264:	ffffb097          	auipc	ra,0xffffb
    80006268:	8de080e7          	jalr	-1826(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000626c:	100017b7          	lui	a5,0x10001
    80006270:	4398                	lw	a4,0(a5)
    80006272:	2701                	sext.w	a4,a4
    80006274:	747277b7          	lui	a5,0x74727
    80006278:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000627c:	14f71b63          	bne	a4,a5,800063d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006280:	100017b7          	lui	a5,0x10001
    80006284:	43dc                	lw	a5,4(a5)
    80006286:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006288:	4709                	li	a4,2
    8000628a:	14e79463          	bne	a5,a4,800063d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000628e:	100017b7          	lui	a5,0x10001
    80006292:	479c                	lw	a5,8(a5)
    80006294:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006296:	12e79e63          	bne	a5,a4,800063d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000629a:	100017b7          	lui	a5,0x10001
    8000629e:	47d8                	lw	a4,12(a5)
    800062a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062a2:	554d47b7          	lui	a5,0x554d4
    800062a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062aa:	12f71463          	bne	a4,a5,800063d2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062ae:	100017b7          	lui	a5,0x10001
    800062b2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062b6:	4705                	li	a4,1
    800062b8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062ba:	470d                	li	a4,3
    800062bc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062be:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062c0:	c7ffe6b7          	lui	a3,0xc7ffe
    800062c4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fda7af>
    800062c8:	8f75                	and	a4,a4,a3
    800062ca:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062cc:	472d                	li	a4,11
    800062ce:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800062d0:	5bbc                	lw	a5,112(a5)
    800062d2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800062d6:	8ba1                	andi	a5,a5,8
    800062d8:	10078563          	beqz	a5,800063e2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062dc:	100017b7          	lui	a5,0x10001
    800062e0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800062e4:	43fc                	lw	a5,68(a5)
    800062e6:	2781                	sext.w	a5,a5
    800062e8:	10079563          	bnez	a5,800063f2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062ec:	100017b7          	lui	a5,0x10001
    800062f0:	5bdc                	lw	a5,52(a5)
    800062f2:	2781                	sext.w	a5,a5
  if(max == 0)
    800062f4:	10078763          	beqz	a5,80006402 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800062f8:	471d                	li	a4,7
    800062fa:	10f77c63          	bgeu	a4,a5,80006412 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800062fe:	ffffa097          	auipc	ra,0xffffa
    80006302:	7e4080e7          	jalr	2020(ra) # 80000ae2 <kalloc>
    80006306:	0001e497          	auipc	s1,0x1e
    8000630a:	b6a48493          	addi	s1,s1,-1174 # 80023e70 <disk>
    8000630e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006310:	ffffa097          	auipc	ra,0xffffa
    80006314:	7d2080e7          	jalr	2002(ra) # 80000ae2 <kalloc>
    80006318:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000631a:	ffffa097          	auipc	ra,0xffffa
    8000631e:	7c8080e7          	jalr	1992(ra) # 80000ae2 <kalloc>
    80006322:	87aa                	mv	a5,a0
    80006324:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006326:	6088                	ld	a0,0(s1)
    80006328:	cd6d                	beqz	a0,80006422 <virtio_disk_init+0x1da>
    8000632a:	0001e717          	auipc	a4,0x1e
    8000632e:	b4e73703          	ld	a4,-1202(a4) # 80023e78 <disk+0x8>
    80006332:	cb65                	beqz	a4,80006422 <virtio_disk_init+0x1da>
    80006334:	c7fd                	beqz	a5,80006422 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006336:	6605                	lui	a2,0x1
    80006338:	4581                	li	a1,0
    8000633a:	ffffb097          	auipc	ra,0xffffb
    8000633e:	994080e7          	jalr	-1644(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006342:	0001e497          	auipc	s1,0x1e
    80006346:	b2e48493          	addi	s1,s1,-1234 # 80023e70 <disk>
    8000634a:	6605                	lui	a2,0x1
    8000634c:	4581                	li	a1,0
    8000634e:	6488                	ld	a0,8(s1)
    80006350:	ffffb097          	auipc	ra,0xffffb
    80006354:	97e080e7          	jalr	-1666(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006358:	6605                	lui	a2,0x1
    8000635a:	4581                	li	a1,0
    8000635c:	6888                	ld	a0,16(s1)
    8000635e:	ffffb097          	auipc	ra,0xffffb
    80006362:	970080e7          	jalr	-1680(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006366:	100017b7          	lui	a5,0x10001
    8000636a:	4721                	li	a4,8
    8000636c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000636e:	4098                	lw	a4,0(s1)
    80006370:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006374:	40d8                	lw	a4,4(s1)
    80006376:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000637a:	6498                	ld	a4,8(s1)
    8000637c:	0007069b          	sext.w	a3,a4
    80006380:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006384:	9701                	srai	a4,a4,0x20
    80006386:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000638a:	6898                	ld	a4,16(s1)
    8000638c:	0007069b          	sext.w	a3,a4
    80006390:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006394:	9701                	srai	a4,a4,0x20
    80006396:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000639a:	4705                	li	a4,1
    8000639c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000639e:	00e48c23          	sb	a4,24(s1)
    800063a2:	00e48ca3          	sb	a4,25(s1)
    800063a6:	00e48d23          	sb	a4,26(s1)
    800063aa:	00e48da3          	sb	a4,27(s1)
    800063ae:	00e48e23          	sb	a4,28(s1)
    800063b2:	00e48ea3          	sb	a4,29(s1)
    800063b6:	00e48f23          	sb	a4,30(s1)
    800063ba:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800063be:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800063c2:	0727a823          	sw	s2,112(a5)
}
    800063c6:	60e2                	ld	ra,24(sp)
    800063c8:	6442                	ld	s0,16(sp)
    800063ca:	64a2                	ld	s1,8(sp)
    800063cc:	6902                	ld	s2,0(sp)
    800063ce:	6105                	addi	sp,sp,32
    800063d0:	8082                	ret
    panic("could not find virtio disk");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	34650513          	addi	a0,a0,838 # 80008718 <syscalls+0x340>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	162080e7          	jalr	354(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800063e2:	00002517          	auipc	a0,0x2
    800063e6:	35650513          	addi	a0,a0,854 # 80008738 <syscalls+0x360>
    800063ea:	ffffa097          	auipc	ra,0xffffa
    800063ee:	152080e7          	jalr	338(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800063f2:	00002517          	auipc	a0,0x2
    800063f6:	36650513          	addi	a0,a0,870 # 80008758 <syscalls+0x380>
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	142080e7          	jalr	322(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006402:	00002517          	auipc	a0,0x2
    80006406:	37650513          	addi	a0,a0,886 # 80008778 <syscalls+0x3a0>
    8000640a:	ffffa097          	auipc	ra,0xffffa
    8000640e:	132080e7          	jalr	306(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006412:	00002517          	auipc	a0,0x2
    80006416:	38650513          	addi	a0,a0,902 # 80008798 <syscalls+0x3c0>
    8000641a:	ffffa097          	auipc	ra,0xffffa
    8000641e:	122080e7          	jalr	290(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006422:	00002517          	auipc	a0,0x2
    80006426:	39650513          	addi	a0,a0,918 # 800087b8 <syscalls+0x3e0>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	112080e7          	jalr	274(ra) # 8000053c <panic>

0000000080006432 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006432:	7159                	addi	sp,sp,-112
    80006434:	f486                	sd	ra,104(sp)
    80006436:	f0a2                	sd	s0,96(sp)
    80006438:	eca6                	sd	s1,88(sp)
    8000643a:	e8ca                	sd	s2,80(sp)
    8000643c:	e4ce                	sd	s3,72(sp)
    8000643e:	e0d2                	sd	s4,64(sp)
    80006440:	fc56                	sd	s5,56(sp)
    80006442:	f85a                	sd	s6,48(sp)
    80006444:	f45e                	sd	s7,40(sp)
    80006446:	f062                	sd	s8,32(sp)
    80006448:	ec66                	sd	s9,24(sp)
    8000644a:	e86a                	sd	s10,16(sp)
    8000644c:	1880                	addi	s0,sp,112
    8000644e:	8a2a                	mv	s4,a0
    80006450:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006452:	00c52c83          	lw	s9,12(a0)
    80006456:	001c9c9b          	slliw	s9,s9,0x1
    8000645a:	1c82                	slli	s9,s9,0x20
    8000645c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006460:	0001e517          	auipc	a0,0x1e
    80006464:	b3850513          	addi	a0,a0,-1224 # 80023f98 <disk+0x128>
    80006468:	ffffa097          	auipc	ra,0xffffa
    8000646c:	76a080e7          	jalr	1898(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006470:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006472:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006474:	0001eb17          	auipc	s6,0x1e
    80006478:	9fcb0b13          	addi	s6,s6,-1540 # 80023e70 <disk>
  for(int i = 0; i < 3; i++){
    8000647c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000647e:	0001ec17          	auipc	s8,0x1e
    80006482:	b1ac0c13          	addi	s8,s8,-1254 # 80023f98 <disk+0x128>
    80006486:	a095                	j	800064ea <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006488:	00fb0733          	add	a4,s6,a5
    8000648c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006490:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006492:	0207c563          	bltz	a5,800064bc <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006496:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006498:	0591                	addi	a1,a1,4
    8000649a:	05560d63          	beq	a2,s5,800064f4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000649e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    800064a0:	0001e717          	auipc	a4,0x1e
    800064a4:	9d070713          	addi	a4,a4,-1584 # 80023e70 <disk>
    800064a8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    800064aa:	01874683          	lbu	a3,24(a4)
    800064ae:	fee9                	bnez	a3,80006488 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800064b0:	2785                	addiw	a5,a5,1
    800064b2:	0705                	addi	a4,a4,1
    800064b4:	fe979be3          	bne	a5,s1,800064aa <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800064b8:	57fd                	li	a5,-1
    800064ba:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800064bc:	00c05e63          	blez	a2,800064d8 <virtio_disk_rw+0xa6>
    800064c0:	060a                	slli	a2,a2,0x2
    800064c2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800064c6:	0009a503          	lw	a0,0(s3)
    800064ca:	00000097          	auipc	ra,0x0
    800064ce:	cfc080e7          	jalr	-772(ra) # 800061c6 <free_desc>
      for(int j = 0; j < i; j++)
    800064d2:	0991                	addi	s3,s3,4
    800064d4:	ffa999e3          	bne	s3,s10,800064c6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064d8:	85e2                	mv	a1,s8
    800064da:	0001e517          	auipc	a0,0x1e
    800064de:	9ae50513          	addi	a0,a0,-1618 # 80023e88 <disk+0x18>
    800064e2:	ffffc097          	auipc	ra,0xffffc
    800064e6:	d64080e7          	jalr	-668(ra) # 80002246 <sleep>
  for(int i = 0; i < 3; i++){
    800064ea:	f9040993          	addi	s3,s0,-112
{
    800064ee:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800064f0:	864a                	mv	a2,s2
    800064f2:	b775                	j	8000649e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064f4:	f9042503          	lw	a0,-112(s0)
    800064f8:	00a50713          	addi	a4,a0,10
    800064fc:	0712                	slli	a4,a4,0x4

  if(write)
    800064fe:	0001e797          	auipc	a5,0x1e
    80006502:	97278793          	addi	a5,a5,-1678 # 80023e70 <disk>
    80006506:	00e786b3          	add	a3,a5,a4
    8000650a:	01703633          	snez	a2,s7
    8000650e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006510:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006514:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006518:	f6070613          	addi	a2,a4,-160
    8000651c:	6394                	ld	a3,0(a5)
    8000651e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006520:	00870593          	addi	a1,a4,8
    80006524:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006526:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006528:	0007b803          	ld	a6,0(a5)
    8000652c:	9642                	add	a2,a2,a6
    8000652e:	46c1                	li	a3,16
    80006530:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006532:	4585                	li	a1,1
    80006534:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006538:	f9442683          	lw	a3,-108(s0)
    8000653c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006540:	0692                	slli	a3,a3,0x4
    80006542:	9836                	add	a6,a6,a3
    80006544:	058a0613          	addi	a2,s4,88
    80006548:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000654c:	0007b803          	ld	a6,0(a5)
    80006550:	96c2                	add	a3,a3,a6
    80006552:	40000613          	li	a2,1024
    80006556:	c690                	sw	a2,8(a3)
  if(write)
    80006558:	001bb613          	seqz	a2,s7
    8000655c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006560:	00166613          	ori	a2,a2,1
    80006564:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006568:	f9842603          	lw	a2,-104(s0)
    8000656c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006570:	00250693          	addi	a3,a0,2
    80006574:	0692                	slli	a3,a3,0x4
    80006576:	96be                	add	a3,a3,a5
    80006578:	58fd                	li	a7,-1
    8000657a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000657e:	0612                	slli	a2,a2,0x4
    80006580:	9832                	add	a6,a6,a2
    80006582:	f9070713          	addi	a4,a4,-112
    80006586:	973e                	add	a4,a4,a5
    80006588:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000658c:	6398                	ld	a4,0(a5)
    8000658e:	9732                	add	a4,a4,a2
    80006590:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006592:	4609                	li	a2,2
    80006594:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006598:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000659c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800065a0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065a4:	6794                	ld	a3,8(a5)
    800065a6:	0026d703          	lhu	a4,2(a3)
    800065aa:	8b1d                	andi	a4,a4,7
    800065ac:	0706                	slli	a4,a4,0x1
    800065ae:	96ba                	add	a3,a3,a4
    800065b0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800065b4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065b8:	6798                	ld	a4,8(a5)
    800065ba:	00275783          	lhu	a5,2(a4)
    800065be:	2785                	addiw	a5,a5,1
    800065c0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065c4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065c8:	100017b7          	lui	a5,0x10001
    800065cc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065d0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800065d4:	0001e917          	auipc	s2,0x1e
    800065d8:	9c490913          	addi	s2,s2,-1596 # 80023f98 <disk+0x128>
  while(b->disk == 1) {
    800065dc:	4485                	li	s1,1
    800065de:	00b79c63          	bne	a5,a1,800065f6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800065e2:	85ca                	mv	a1,s2
    800065e4:	8552                	mv	a0,s4
    800065e6:	ffffc097          	auipc	ra,0xffffc
    800065ea:	c60080e7          	jalr	-928(ra) # 80002246 <sleep>
  while(b->disk == 1) {
    800065ee:	004a2783          	lw	a5,4(s4)
    800065f2:	fe9788e3          	beq	a5,s1,800065e2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800065f6:	f9042903          	lw	s2,-112(s0)
    800065fa:	00290713          	addi	a4,s2,2
    800065fe:	0712                	slli	a4,a4,0x4
    80006600:	0001e797          	auipc	a5,0x1e
    80006604:	87078793          	addi	a5,a5,-1936 # 80023e70 <disk>
    80006608:	97ba                	add	a5,a5,a4
    8000660a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000660e:	0001e997          	auipc	s3,0x1e
    80006612:	86298993          	addi	s3,s3,-1950 # 80023e70 <disk>
    80006616:	00491713          	slli	a4,s2,0x4
    8000661a:	0009b783          	ld	a5,0(s3)
    8000661e:	97ba                	add	a5,a5,a4
    80006620:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006624:	854a                	mv	a0,s2
    80006626:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000662a:	00000097          	auipc	ra,0x0
    8000662e:	b9c080e7          	jalr	-1124(ra) # 800061c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006632:	8885                	andi	s1,s1,1
    80006634:	f0ed                	bnez	s1,80006616 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006636:	0001e517          	auipc	a0,0x1e
    8000663a:	96250513          	addi	a0,a0,-1694 # 80023f98 <disk+0x128>
    8000663e:	ffffa097          	auipc	ra,0xffffa
    80006642:	648080e7          	jalr	1608(ra) # 80000c86 <release>
}
    80006646:	70a6                	ld	ra,104(sp)
    80006648:	7406                	ld	s0,96(sp)
    8000664a:	64e6                	ld	s1,88(sp)
    8000664c:	6946                	ld	s2,80(sp)
    8000664e:	69a6                	ld	s3,72(sp)
    80006650:	6a06                	ld	s4,64(sp)
    80006652:	7ae2                	ld	s5,56(sp)
    80006654:	7b42                	ld	s6,48(sp)
    80006656:	7ba2                	ld	s7,40(sp)
    80006658:	7c02                	ld	s8,32(sp)
    8000665a:	6ce2                	ld	s9,24(sp)
    8000665c:	6d42                	ld	s10,16(sp)
    8000665e:	6165                	addi	sp,sp,112
    80006660:	8082                	ret

0000000080006662 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006662:	1101                	addi	sp,sp,-32
    80006664:	ec06                	sd	ra,24(sp)
    80006666:	e822                	sd	s0,16(sp)
    80006668:	e426                	sd	s1,8(sp)
    8000666a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000666c:	0001e497          	auipc	s1,0x1e
    80006670:	80448493          	addi	s1,s1,-2044 # 80023e70 <disk>
    80006674:	0001e517          	auipc	a0,0x1e
    80006678:	92450513          	addi	a0,a0,-1756 # 80023f98 <disk+0x128>
    8000667c:	ffffa097          	auipc	ra,0xffffa
    80006680:	556080e7          	jalr	1366(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006684:	10001737          	lui	a4,0x10001
    80006688:	533c                	lw	a5,96(a4)
    8000668a:	8b8d                	andi	a5,a5,3
    8000668c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000668e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006692:	689c                	ld	a5,16(s1)
    80006694:	0204d703          	lhu	a4,32(s1)
    80006698:	0027d783          	lhu	a5,2(a5)
    8000669c:	04f70863          	beq	a4,a5,800066ec <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800066a0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066a4:	6898                	ld	a4,16(s1)
    800066a6:	0204d783          	lhu	a5,32(s1)
    800066aa:	8b9d                	andi	a5,a5,7
    800066ac:	078e                	slli	a5,a5,0x3
    800066ae:	97ba                	add	a5,a5,a4
    800066b0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066b2:	00278713          	addi	a4,a5,2
    800066b6:	0712                	slli	a4,a4,0x4
    800066b8:	9726                	add	a4,a4,s1
    800066ba:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800066be:	e721                	bnez	a4,80006706 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066c0:	0789                	addi	a5,a5,2
    800066c2:	0792                	slli	a5,a5,0x4
    800066c4:	97a6                	add	a5,a5,s1
    800066c6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800066c8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066cc:	ffffc097          	auipc	ra,0xffffc
    800066d0:	bde080e7          	jalr	-1058(ra) # 800022aa <wakeup>

    disk.used_idx += 1;
    800066d4:	0204d783          	lhu	a5,32(s1)
    800066d8:	2785                	addiw	a5,a5,1
    800066da:	17c2                	slli	a5,a5,0x30
    800066dc:	93c1                	srli	a5,a5,0x30
    800066de:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066e2:	6898                	ld	a4,16(s1)
    800066e4:	00275703          	lhu	a4,2(a4)
    800066e8:	faf71ce3          	bne	a4,a5,800066a0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800066ec:	0001e517          	auipc	a0,0x1e
    800066f0:	8ac50513          	addi	a0,a0,-1876 # 80023f98 <disk+0x128>
    800066f4:	ffffa097          	auipc	ra,0xffffa
    800066f8:	592080e7          	jalr	1426(ra) # 80000c86 <release>
}
    800066fc:	60e2                	ld	ra,24(sp)
    800066fe:	6442                	ld	s0,16(sp)
    80006700:	64a2                	ld	s1,8(sp)
    80006702:	6105                	addi	sp,sp,32
    80006704:	8082                	ret
      panic("virtio_disk_intr status");
    80006706:	00002517          	auipc	a0,0x2
    8000670a:	0ca50513          	addi	a0,a0,202 # 800087d0 <syscalls+0x3f8>
    8000670e:	ffffa097          	auipc	ra,0xffffa
    80006712:	e2e080e7          	jalr	-466(ra) # 8000053c <panic>
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
