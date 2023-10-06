
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	90013103          	ld	sp,-1792(sp) # 80008900 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	91070713          	addi	a4,a4,-1776 # 80008960 <timer_scratch>
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
    80000066:	0ae78793          	addi	a5,a5,174 # 80006110 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb1cf>
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
    8000012e:	5d4080e7          	jalr	1492(ra) # 800026fe <either_copyin>
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
    80000188:	91c50513          	addi	a0,a0,-1764 # 80010aa0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	90c48493          	addi	s1,s1,-1780 # 80010aa0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	99c90913          	addi	s2,s2,-1636 # 80010b38 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	81a080e7          	jalr	-2022(ra) # 800019ce <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	38c080e7          	jalr	908(ra) # 80002548 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	0ca080e7          	jalr	202(ra) # 80002294 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	8c270713          	addi	a4,a4,-1854 # 80010aa0 <cons>
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
    80000214:	498080e7          	jalr	1176(ra) # 800026a8 <either_copyout>
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
    8000022c:	87850513          	addi	a0,a0,-1928 # 80010aa0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	86250513          	addi	a0,a0,-1950 # 80010aa0 <cons>
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
    80000272:	8cf72523          	sw	a5,-1846(a4) # 80010b38 <cons+0x98>
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
    800002cc:	7d850513          	addi	a0,a0,2008 # 80010aa0 <cons>
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
    800002f2:	466080e7          	jalr	1126(ra) # 80002754 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	7aa50513          	addi	a0,a0,1962 # 80010aa0 <cons>
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
    8000031e:	78670713          	addi	a4,a4,1926 # 80010aa0 <cons>
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
    80000348:	75c78793          	addi	a5,a5,1884 # 80010aa0 <cons>
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
    80000376:	7c67a783          	lw	a5,1990(a5) # 80010b38 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	71a70713          	addi	a4,a4,1818 # 80010aa0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	70a48493          	addi	s1,s1,1802 # 80010aa0 <cons>
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
    800003d6:	6ce70713          	addi	a4,a4,1742 # 80010aa0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	74f72c23          	sw	a5,1880(a4) # 80010b40 <cons+0xa0>
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
    80000412:	69278793          	addi	a5,a5,1682 # 80010aa0 <cons>
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
    80000436:	70c7a523          	sw	a2,1802(a5) # 80010b3c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	6fe50513          	addi	a0,a0,1790 # 80010b38 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	eb6080e7          	jalr	-330(ra) # 800022f8 <wakeup>
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
    80000460:	64450513          	addi	a0,a0,1604 # 80010aa0 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00022797          	auipc	a5,0x22
    80000478:	02478793          	addi	a5,a5,36 # 80022498 <devsw>
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
    8000054c:	6007ac23          	sw	zero,1560(a5) # 80010b60 <pr+0x18>
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
    80000580:	3af72223          	sw	a5,932(a4) # 80008920 <panicked>
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
    800005bc:	5a8dad83          	lw	s11,1448(s11) # 80010b60 <pr+0x18>
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
    800005fa:	55250513          	addi	a0,a0,1362 # 80010b48 <pr>
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
    80000758:	3f450513          	addi	a0,a0,1012 # 80010b48 <pr>
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
    80000774:	3d848493          	addi	s1,s1,984 # 80010b48 <pr>
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
    800007d4:	39850513          	addi	a0,a0,920 # 80010b68 <uart_tx_lock>
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
    80000800:	1247a783          	lw	a5,292(a5) # 80008920 <panicked>
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
    80000838:	0f47b783          	ld	a5,244(a5) # 80008928 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0f473703          	ld	a4,244(a4) # 80008930 <uart_tx_w>
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
    80000862:	30aa0a13          	addi	s4,s4,778 # 80010b68 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	0c248493          	addi	s1,s1,194 # 80008928 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	0c298993          	addi	s3,s3,194 # 80008930 <uart_tx_w>
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
    80000894:	a68080e7          	jalr	-1432(ra) # 800022f8 <wakeup>
    
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
    800008d0:	29c50513          	addi	a0,a0,668 # 80010b68 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0447a783          	lw	a5,68(a5) # 80008920 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	04a73703          	ld	a4,74(a4) # 80008930 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	03a7b783          	ld	a5,58(a5) # 80008928 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	26e98993          	addi	s3,s3,622 # 80010b68 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	02648493          	addi	s1,s1,38 # 80008928 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	02690913          	addi	s2,s2,38 # 80008930 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	97a080e7          	jalr	-1670(ra) # 80002294 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	23848493          	addi	s1,s1,568 # 80010b68 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	fee7b623          	sd	a4,-20(a5) # 80008930 <uart_tx_w>
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
    800009ba:	1b248493          	addi	s1,s1,434 # 80010b68 <uart_tx_lock>
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
    800009fc:	c3878793          	addi	a5,a5,-968 # 80023630 <end>
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
    80000a1c:	18890913          	addi	s2,s2,392 # 80010ba0 <kmem>
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
    80000aba:	0ea50513          	addi	a0,a0,234 # 80010ba0 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00023517          	auipc	a0,0x23
    80000ace:	b6650513          	addi	a0,a0,-1178 # 80023630 <end>
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
    80000af0:	0b448493          	addi	s1,s1,180 # 80010ba0 <kmem>
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
    80000b08:	09c50513          	addi	a0,a0,156 # 80010ba0 <kmem>
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
    80000b34:	07050513          	addi	a0,a0,112 # 80010ba0 <kmem>
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
    80000b70:	e46080e7          	jalr	-442(ra) # 800019b2 <mycpu>
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
    80000ba2:	e14080e7          	jalr	-492(ra) # 800019b2 <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	e08080e7          	jalr	-504(ra) # 800019b2 <mycpu>
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
    80000bc6:	df0080e7          	jalr	-528(ra) # 800019b2 <mycpu>
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
    80000c06:	db0080e7          	jalr	-592(ra) # 800019b2 <mycpu>
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
    80000c32:	d84080e7          	jalr	-636(ra) # 800019b2 <mycpu>
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
    80000d42:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdb9d1>
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
    80000e7e:	b28080e7          	jalr	-1240(ra) # 800019a2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	ab670713          	addi	a4,a4,-1354 # 80008938 <started>
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
    80000e9a:	b0c080e7          	jalr	-1268(ra) # 800019a2 <cpuid>
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
    80000ebc:	b88080e7          	jalr	-1144(ra) # 80002a40 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	290080e7          	jalr	656(ra) # 80006150 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	190080e7          	jalr	400(ra) # 80002058 <scheduler>
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
    80000f34:	ae8080e7          	jalr	-1304(ra) # 80002a18 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	b08080e7          	jalr	-1272(ra) # 80002a40 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	1fa080e7          	jalr	506(ra) # 8000613a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	208080e7          	jalr	520(ra) # 80006150 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	3f0080e7          	jalr	1008(ra) # 80003340 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	a8e080e7          	jalr	-1394(ra) # 800039e6 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	a04080e7          	jalr	-1532(ra) # 80004964 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	2f0080e7          	jalr	752(ra) # 80006258 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	e22080e7          	jalr	-478(ra) # 80001d92 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	9af72d23          	sw	a5,-1606(a4) # 80008938 <started>
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
    80000f96:	9ae7b783          	ld	a5,-1618(a5) # 80008940 <kernel_pagetable>
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
    80001010:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdb9c7>
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
    80001252:	6ea7b923          	sd	a0,1778(a5) # 80008940 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdb9d0>
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
    8000184a:	e0a48493          	addi	s1,s1,-502 # 80011650 <proc>
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
    80001864:	9f0a0a13          	addi	s4,s4,-1552 # 80018250 <tickslock>
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
    8000189a:	1b048493          	addi	s1,s1,432
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
	int i ; 
	for(i=0;i<NUM_OF_QUEUES;i++)
	{
		//check if queue exists 
		
		queues[i].queue_size = 0 ; 
    800018da:	0000f797          	auipc	a5,0xf
    800018de:	2e678793          	addi	a5,a5,742 # 80010bc0 <queues>
    800018e2:	1807a823          	sw	zero,400(a5)
		queues[i].arr[0] = 0 ;
    800018e6:	0007b023          	sd	zero,0(a5)
		queues[i].queue_size = 0 ; 
    800018ea:	3207a423          	sw	zero,808(a5)
		queues[i].arr[0] = 0 ;
    800018ee:	1807bc23          	sd	zero,408(a5)
		queues[i].queue_size = 0 ; 
    800018f2:	4c07a023          	sw	zero,1216(a5)
		queues[i].arr[0] = 0 ;
    800018f6:	3207b823          	sd	zero,816(a5)
		queues[i].queue_size = 0 ; 
    800018fa:	6407ac23          	sw	zero,1624(a5)
		queues[i].arr[0] = 0 ;
    800018fe:	4c07b423          	sd	zero,1224(a5)
	}
	#endif
	initlock(&pid_lock, "nextpid");
    80001902:	00007597          	auipc	a1,0x7
    80001906:	8de58593          	addi	a1,a1,-1826 # 800081e0 <digits+0x1a0>
    8000190a:	00010517          	auipc	a0,0x10
    8000190e:	91650513          	addi	a0,a0,-1770 # 80011220 <pid_lock>
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	230080e7          	jalr	560(ra) # 80000b42 <initlock>
	initlock(&wait_lock, "wait_lock");
    8000191a:	00007597          	auipc	a1,0x7
    8000191e:	8ce58593          	addi	a1,a1,-1842 # 800081e8 <digits+0x1a8>
    80001922:	00010517          	auipc	a0,0x10
    80001926:	91650513          	addi	a0,a0,-1770 # 80011238 <wait_lock>
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	218080e7          	jalr	536(ra) # 80000b42 <initlock>
	for(p = proc; p < &proc[NPROC]; p++)
    80001932:	00010497          	auipc	s1,0x10
    80001936:	d1e48493          	addi	s1,s1,-738 # 80011650 <proc>
	{
		initlock(&p->lock, "proc");
    8000193a:	00007b17          	auipc	s6,0x7
    8000193e:	8beb0b13          	addi	s6,s6,-1858 # 800081f8 <digits+0x1b8>
		p->state = UNUSED;
		p->kstack = KSTACK((int)(p - proc));
    80001942:	8aa6                	mv	s5,s1
    80001944:	00006a17          	auipc	s4,0x6
    80001948:	6bca0a13          	addi	s4,s4,1724 # 80008000 <etext>
    8000194c:	04000937          	lui	s2,0x4000
    80001950:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001952:	0932                	slli	s2,s2,0xc
	for(p = proc; p < &proc[NPROC]; p++)
    80001954:	00017997          	auipc	s3,0x17
    80001958:	8fc98993          	addi	s3,s3,-1796 # 80018250 <tickslock>
		initlock(&p->lock, "proc");
    8000195c:	85da                	mv	a1,s6
    8000195e:	8526                	mv	a0,s1
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	1e2080e7          	jalr	482(ra) # 80000b42 <initlock>
		p->state = UNUSED;
    80001968:	0004ac23          	sw	zero,24(s1)
		p->kstack = KSTACK((int)(p - proc));
    8000196c:	415487b3          	sub	a5,s1,s5
    80001970:	8791                	srai	a5,a5,0x4
    80001972:	000a3703          	ld	a4,0(s4)
    80001976:	02e787b3          	mul	a5,a5,a4
    8000197a:	2785                	addiw	a5,a5,1
    8000197c:	00d7979b          	slliw	a5,a5,0xd
    80001980:	40f907b3          	sub	a5,s2,a5
    80001984:	e0bc                	sd	a5,64(s1)
	for(p = proc; p < &proc[NPROC]; p++)
    80001986:	1b048493          	addi	s1,s1,432
    8000198a:	fd3499e3          	bne	s1,s3,8000195c <procinit+0x96>
	}


}
    8000198e:	70e2                	ld	ra,56(sp)
    80001990:	7442                	ld	s0,48(sp)
    80001992:	74a2                	ld	s1,40(sp)
    80001994:	7902                	ld	s2,32(sp)
    80001996:	69e2                	ld	s3,24(sp)
    80001998:	6a42                	ld	s4,16(sp)
    8000199a:	6aa2                	ld	s5,8(sp)
    8000199c:	6b02                	ld	s6,0(sp)
    8000199e:	6121                	addi	sp,sp,64
    800019a0:	8082                	ret

00000000800019a2 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    800019a2:	1141                	addi	sp,sp,-16
    800019a4:	e422                	sd	s0,8(sp)
    800019a6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a8:	8512                	mv	a0,tp
	int id = r_tp();
	return id;
}
    800019aa:	2501                	sext.w	a0,a0
    800019ac:	6422                	ld	s0,8(sp)
    800019ae:	0141                	addi	sp,sp,16
    800019b0:	8082                	ret

00000000800019b2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu* mycpu(void)
{
    800019b2:	1141                	addi	sp,sp,-16
    800019b4:	e422                	sd	s0,8(sp)
    800019b6:	0800                	addi	s0,sp,16
    800019b8:	8792                	mv	a5,tp
	int id = cpuid();
	struct cpu* c = &cpus[id];
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
	return c;
}
    800019be:	00010517          	auipc	a0,0x10
    800019c2:	89250513          	addi	a0,a0,-1902 # 80011250 <cpus>
    800019c6:	953e                	add	a0,a0,a5
    800019c8:	6422                	ld	s0,8(sp)
    800019ca:	0141                	addi	sp,sp,16
    800019cc:	8082                	ret

00000000800019ce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc* myproc(void)
{
    800019ce:	1101                	addi	sp,sp,-32
    800019d0:	ec06                	sd	ra,24(sp)
    800019d2:	e822                	sd	s0,16(sp)
    800019d4:	e426                	sd	s1,8(sp)
    800019d6:	1000                	addi	s0,sp,32
	push_off();
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	1ae080e7          	jalr	430(ra) # 80000b86 <push_off>
    800019e0:	8792                	mv	a5,tp
	struct cpu* c = mycpu();
	struct proc* p = c->proc;
    800019e2:	2781                	sext.w	a5,a5
    800019e4:	079e                	slli	a5,a5,0x7
    800019e6:	0000f717          	auipc	a4,0xf
    800019ea:	1da70713          	addi	a4,a4,474 # 80010bc0 <queues>
    800019ee:	97ba                	add	a5,a5,a4
    800019f0:	6907b483          	ld	s1,1680(a5)
	pop_off();
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	232080e7          	jalr	562(ra) # 80000c26 <pop_off>
	return p;
}
    800019fc:	8526                	mv	a0,s1
    800019fe:	60e2                	ld	ra,24(sp)
    80001a00:	6442                	ld	s0,16(sp)
    80001a02:	64a2                	ld	s1,8(sp)
    80001a04:	6105                	addi	sp,sp,32
    80001a06:	8082                	ret

0000000080001a08 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a08:	1141                	addi	sp,sp,-16
    80001a0a:	e406                	sd	ra,8(sp)
    80001a0c:	e022                	sd	s0,0(sp)
    80001a0e:	0800                	addi	s0,sp,16
	static int first = 1;

	// Still holding p->lock from scheduler.
	release(&myproc()->lock);
    80001a10:	00000097          	auipc	ra,0x0
    80001a14:	fbe080e7          	jalr	-66(ra) # 800019ce <myproc>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	26e080e7          	jalr	622(ra) # 80000c86 <release>

	if(first)
    80001a20:	00007797          	auipc	a5,0x7
    80001a24:	e907a783          	lw	a5,-368(a5) # 800088b0 <first.1>
    80001a28:	eb89                	bnez	a5,80001a3a <forkret+0x32>
		// be run from main().
		first = 0;
		fsinit(ROOTDEV);
	}

	usertrapret();
    80001a2a:	00001097          	auipc	ra,0x1
    80001a2e:	02e080e7          	jalr	46(ra) # 80002a58 <usertrapret>
}
    80001a32:	60a2                	ld	ra,8(sp)
    80001a34:	6402                	ld	s0,0(sp)
    80001a36:	0141                	addi	sp,sp,16
    80001a38:	8082                	ret
		first = 0;
    80001a3a:	00007797          	auipc	a5,0x7
    80001a3e:	e607ab23          	sw	zero,-394(a5) # 800088b0 <first.1>
		fsinit(ROOTDEV);
    80001a42:	4505                	li	a0,1
    80001a44:	00002097          	auipc	ra,0x2
    80001a48:	f22080e7          	jalr	-222(ra) # 80003966 <fsinit>
    80001a4c:	bff9                	j	80001a2a <forkret+0x22>

0000000080001a4e <allocpid>:
{
    80001a4e:	1101                	addi	sp,sp,-32
    80001a50:	ec06                	sd	ra,24(sp)
    80001a52:	e822                	sd	s0,16(sp)
    80001a54:	e426                	sd	s1,8(sp)
    80001a56:	e04a                	sd	s2,0(sp)
    80001a58:	1000                	addi	s0,sp,32
	acquire(&pid_lock);
    80001a5a:	0000f917          	auipc	s2,0xf
    80001a5e:	7c690913          	addi	s2,s2,1990 # 80011220 <pid_lock>
    80001a62:	854a                	mv	a0,s2
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	16e080e7          	jalr	366(ra) # 80000bd2 <acquire>
	pid = nextpid;
    80001a6c:	00007797          	auipc	a5,0x7
    80001a70:	e4878793          	addi	a5,a5,-440 # 800088b4 <nextpid>
    80001a74:	4384                	lw	s1,0(a5)
	nextpid = nextpid + 1;
    80001a76:	0014871b          	addiw	a4,s1,1
    80001a7a:	c398                	sw	a4,0(a5)
	release(&pid_lock);
    80001a7c:	854a                	mv	a0,s2
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	208080e7          	jalr	520(ra) # 80000c86 <release>
}
    80001a86:	8526                	mv	a0,s1
    80001a88:	60e2                	ld	ra,24(sp)
    80001a8a:	6442                	ld	s0,16(sp)
    80001a8c:	64a2                	ld	s1,8(sp)
    80001a8e:	6902                	ld	s2,0(sp)
    80001a90:	6105                	addi	sp,sp,32
    80001a92:	8082                	ret

0000000080001a94 <sys_sigalarm>:
{
    80001a94:	1101                	addi	sp,sp,-32
    80001a96:	ec06                	sd	ra,24(sp)
    80001a98:	e822                	sd	s0,16(sp)
    80001a9a:	1000                	addi	s0,sp,32
	argint(0, &ticks);
    80001a9c:	fec40593          	addi	a1,s0,-20
    80001aa0:	4501                	li	a0,0
    80001aa2:	00001097          	auipc	ra,0x1
    80001aa6:	4a2080e7          	jalr	1186(ra) # 80002f44 <argint>
	argaddr(1, &handler);
    80001aaa:	fe040593          	addi	a1,s0,-32
    80001aae:	4505                	li	a0,1
    80001ab0:	00001097          	auipc	ra,0x1
    80001ab4:	4b4080e7          	jalr	1204(ra) # 80002f64 <argaddr>
	myproc()->is_sigalarm = 0;
    80001ab8:	00000097          	auipc	ra,0x0
    80001abc:	f16080e7          	jalr	-234(ra) # 800019ce <myproc>
    80001ac0:	16052a23          	sw	zero,372(a0)
	myproc()->ticks = ticks;
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	f0a080e7          	jalr	-246(ra) # 800019ce <myproc>
    80001acc:	fec42783          	lw	a5,-20(s0)
    80001ad0:	18f52023          	sw	a5,384(a0)
	myproc()->now_ticks = 0;
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	efa080e7          	jalr	-262(ra) # 800019ce <myproc>
    80001adc:	18052223          	sw	zero,388(a0)
	myproc()->handler = handler;
    80001ae0:	00000097          	auipc	ra,0x0
    80001ae4:	eee080e7          	jalr	-274(ra) # 800019ce <myproc>
    80001ae8:	fe043783          	ld	a5,-32(s0)
    80001aec:	18f53423          	sd	a5,392(a0)
}
    80001af0:	4501                	li	a0,0
    80001af2:	60e2                	ld	ra,24(sp)
    80001af4:	6442                	ld	s0,16(sp)
    80001af6:	6105                	addi	sp,sp,32
    80001af8:	8082                	ret

0000000080001afa <proc_pagetable>:
{
    80001afa:	1101                	addi	sp,sp,-32
    80001afc:	ec06                	sd	ra,24(sp)
    80001afe:	e822                	sd	s0,16(sp)
    80001b00:	e426                	sd	s1,8(sp)
    80001b02:	e04a                	sd	s2,0(sp)
    80001b04:	1000                	addi	s0,sp,32
    80001b06:	892a                	mv	s2,a0
	pagetable = uvmcreate();
    80001b08:	00000097          	auipc	ra,0x0
    80001b0c:	81a080e7          	jalr	-2022(ra) # 80001322 <uvmcreate>
    80001b10:	84aa                	mv	s1,a0
	if(pagetable == 0)
    80001b12:	c121                	beqz	a0,80001b52 <proc_pagetable+0x58>
	if(mappages(pagetable, TRAMPOLINE, PGSIZE, (uint64)trampoline, PTE_R | PTE_X) < 0)
    80001b14:	4729                	li	a4,10
    80001b16:	00005697          	auipc	a3,0x5
    80001b1a:	4ea68693          	addi	a3,a3,1258 # 80007000 <_trampoline>
    80001b1e:	6605                	lui	a2,0x1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	570080e7          	jalr	1392(ra) # 80001098 <mappages>
    80001b30:	02054863          	bltz	a0,80001b60 <proc_pagetable+0x66>
	if(mappages(pagetable, TRAPFRAME, PGSIZE, (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
    80001b34:	4719                	li	a4,6
    80001b36:	05893683          	ld	a3,88(s2)
    80001b3a:	6605                	lui	a2,0x1
    80001b3c:	020005b7          	lui	a1,0x2000
    80001b40:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b42:	05b6                	slli	a1,a1,0xd
    80001b44:	8526                	mv	a0,s1
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	552080e7          	jalr	1362(ra) # 80001098 <mappages>
    80001b4e:	02054163          	bltz	a0,80001b70 <proc_pagetable+0x76>
}
    80001b52:	8526                	mv	a0,s1
    80001b54:	60e2                	ld	ra,24(sp)
    80001b56:	6442                	ld	s0,16(sp)
    80001b58:	64a2                	ld	s1,8(sp)
    80001b5a:	6902                	ld	s2,0(sp)
    80001b5c:	6105                	addi	sp,sp,32
    80001b5e:	8082                	ret
		uvmfree(pagetable, 0);
    80001b60:	4581                	li	a1,0
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9c4080e7          	jalr	-1596(ra) # 80001528 <uvmfree>
		return 0;
    80001b6c:	4481                	li	s1,0
    80001b6e:	b7d5                	j	80001b52 <proc_pagetable+0x58>
		uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b70:	4681                	li	a3,0
    80001b72:	4605                	li	a2,1
    80001b74:	040005b7          	lui	a1,0x4000
    80001b78:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b7a:	05b2                	slli	a1,a1,0xc
    80001b7c:	8526                	mv	a0,s1
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	6e0080e7          	jalr	1760(ra) # 8000125e <uvmunmap>
		uvmfree(pagetable, 0);
    80001b86:	4581                	li	a1,0
    80001b88:	8526                	mv	a0,s1
    80001b8a:	00000097          	auipc	ra,0x0
    80001b8e:	99e080e7          	jalr	-1634(ra) # 80001528 <uvmfree>
		return 0;
    80001b92:	4481                	li	s1,0
    80001b94:	bf7d                	j	80001b52 <proc_pagetable+0x58>

0000000080001b96 <proc_freepagetable>:
{
    80001b96:	1101                	addi	sp,sp,-32
    80001b98:	ec06                	sd	ra,24(sp)
    80001b9a:	e822                	sd	s0,16(sp)
    80001b9c:	e426                	sd	s1,8(sp)
    80001b9e:	e04a                	sd	s2,0(sp)
    80001ba0:	1000                	addi	s0,sp,32
    80001ba2:	84aa                	mv	s1,a0
    80001ba4:	892e                	mv	s2,a1
	uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ba6:	4681                	li	a3,0
    80001ba8:	4605                	li	a2,1
    80001baa:	040005b7          	lui	a1,0x4000
    80001bae:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bb0:	05b2                	slli	a1,a1,0xc
    80001bb2:	fffff097          	auipc	ra,0xfffff
    80001bb6:	6ac080e7          	jalr	1708(ra) # 8000125e <uvmunmap>
	uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bba:	4681                	li	a3,0
    80001bbc:	4605                	li	a2,1
    80001bbe:	020005b7          	lui	a1,0x2000
    80001bc2:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bc4:	05b6                	slli	a1,a1,0xd
    80001bc6:	8526                	mv	a0,s1
    80001bc8:	fffff097          	auipc	ra,0xfffff
    80001bcc:	696080e7          	jalr	1686(ra) # 8000125e <uvmunmap>
	uvmfree(pagetable, sz);
    80001bd0:	85ca                	mv	a1,s2
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	00000097          	auipc	ra,0x0
    80001bd8:	954080e7          	jalr	-1708(ra) # 80001528 <uvmfree>
}
    80001bdc:	60e2                	ld	ra,24(sp)
    80001bde:	6442                	ld	s0,16(sp)
    80001be0:	64a2                	ld	s1,8(sp)
    80001be2:	6902                	ld	s2,0(sp)
    80001be4:	6105                	addi	sp,sp,32
    80001be6:	8082                	ret

0000000080001be8 <freeproc>:
{
    80001be8:	1101                	addi	sp,sp,-32
    80001bea:	ec06                	sd	ra,24(sp)
    80001bec:	e822                	sd	s0,16(sp)
    80001bee:	e426                	sd	s1,8(sp)
    80001bf0:	1000                	addi	s0,sp,32
    80001bf2:	84aa                	mv	s1,a0
	if(p->backup_trapframe)
    80001bf4:	19053503          	ld	a0,400(a0)
    80001bf8:	c509                	beqz	a0,80001c02 <freeproc+0x1a>
		kfree((void*)p->backup_trapframe);
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	dea080e7          	jalr	-534(ra) # 800009e4 <kfree>
	p->trapframe = 0;
    80001c02:	0404bc23          	sd	zero,88(s1)
	if(p->pagetable)
    80001c06:	68a8                	ld	a0,80(s1)
    80001c08:	c511                	beqz	a0,80001c14 <freeproc+0x2c>
		proc_freepagetable(p->pagetable, p->sz);
    80001c0a:	64ac                	ld	a1,72(s1)
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	f8a080e7          	jalr	-118(ra) # 80001b96 <proc_freepagetable>
	p->pagetable = 0;
    80001c14:	0404b823          	sd	zero,80(s1)
	p->sz = 0;
    80001c18:	0404b423          	sd	zero,72(s1)
	p->pid = 0;
    80001c1c:	0204a823          	sw	zero,48(s1)
	p->parent = 0;
    80001c20:	0204bc23          	sd	zero,56(s1)
	p->name[0] = 0;
    80001c24:	14048c23          	sb	zero,344(s1)
	p->chan = 0;
    80001c28:	0204b023          	sd	zero,32(s1)
	p->killed = 0;
    80001c2c:	0204a423          	sw	zero,40(s1)
	p->xstate = 0;
    80001c30:	0204a623          	sw	zero,44(s1)
	p->state = UNUSED;
    80001c34:	0004ac23          	sw	zero,24(s1)
	p->sched_count = 0;
    80001c38:	1604ae23          	sw	zero,380(s1)
	p->start_time = 0 ;
    80001c3c:	1604ac23          	sw	zero,376(s1)
}
    80001c40:	60e2                	ld	ra,24(sp)
    80001c42:	6442                	ld	s0,16(sp)
    80001c44:	64a2                	ld	s1,8(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret

0000000080001c4a <allocproc>:
{
    80001c4a:	1101                	addi	sp,sp,-32
    80001c4c:	ec06                	sd	ra,24(sp)
    80001c4e:	e822                	sd	s0,16(sp)
    80001c50:	e426                	sd	s1,8(sp)
    80001c52:	e04a                	sd	s2,0(sp)
    80001c54:	1000                	addi	s0,sp,32
	for(p = proc; p < &proc[NPROC]; p++)
    80001c56:	00010497          	auipc	s1,0x10
    80001c5a:	9fa48493          	addi	s1,s1,-1542 # 80011650 <proc>
    80001c5e:	00016917          	auipc	s2,0x16
    80001c62:	5f290913          	addi	s2,s2,1522 # 80018250 <tickslock>
		acquire(&p->lock);
    80001c66:	8526                	mv	a0,s1
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	f6a080e7          	jalr	-150(ra) # 80000bd2 <acquire>
		if(p->state == UNUSED)
    80001c70:	4c9c                	lw	a5,24(s1)
    80001c72:	cf81                	beqz	a5,80001c8a <allocproc+0x40>
			release(&p->lock);
    80001c74:	8526                	mv	a0,s1
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	010080e7          	jalr	16(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    80001c7e:	1b048493          	addi	s1,s1,432
    80001c82:	ff2492e3          	bne	s1,s2,80001c66 <allocproc+0x1c>
	return 0;
    80001c86:	4481                	li	s1,0
    80001c88:	a87d                	j	80001d46 <allocproc+0xfc>
	p->pid = allocpid();
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	dc4080e7          	jalr	-572(ra) # 80001a4e <allocpid>
    80001c92:	d888                	sw	a0,48(s1)
	p->state = USED;
    80001c94:	4785                	li	a5,1
    80001c96:	cc9c                	sw	a5,24(s1)
	if((p->trapframe = (struct trapframe*)kalloc()) == 0)
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	e4a080e7          	jalr	-438(ra) # 80000ae2 <kalloc>
    80001ca0:	892a                	mv	s2,a0
    80001ca2:	eca8                	sd	a0,88(s1)
    80001ca4:	c945                	beqz	a0,80001d54 <allocproc+0x10a>
	if((p->backup_trapframe = (struct trapframe*)kalloc()) == 0)
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	e3c080e7          	jalr	-452(ra) # 80000ae2 <kalloc>
    80001cae:	892a                	mv	s2,a0
    80001cb0:	18a4b823          	sd	a0,400(s1)
    80001cb4:	cd45                	beqz	a0,80001d6c <allocproc+0x122>
	p->pagetable = proc_pagetable(p);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	e42080e7          	jalr	-446(ra) # 80001afa <proc_pagetable>
    80001cc0:	892a                	mv	s2,a0
    80001cc2:	e8a8                	sd	a0,80(s1)
	if(p->pagetable == 0)
    80001cc4:	c95d                	beqz	a0,80001d7a <allocproc+0x130>
	int new_process_idx = queues[0].queue_size;
    80001cc6:	0000f917          	auipc	s2,0xf
    80001cca:	efa90913          	addi	s2,s2,-262 # 80010bc0 <queues>
    80001cce:	19092783          	lw	a5,400(s2)
	queues[0].arr[new_process_idx] = p;
    80001cd2:	00379713          	slli	a4,a5,0x3
    80001cd6:	974a                	add	a4,a4,s2
    80001cd8:	e304                	sd	s1,0(a4)
	queues[0].queue_size++;
    80001cda:	2785                	addiw	a5,a5,1
    80001cdc:	18f92823          	sw	a5,400(s2)
	memset(&p->context, 0, sizeof(p->context));
    80001ce0:	07000613          	li	a2,112
    80001ce4:	4581                	li	a1,0
    80001ce6:	06048513          	addi	a0,s1,96
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	fe4080e7          	jalr	-28(ra) # 80000cce <memset>
	p->context.ra = (uint64)forkret;
    80001cf2:	00000797          	auipc	a5,0x0
    80001cf6:	d1678793          	addi	a5,a5,-746 # 80001a08 <forkret>
    80001cfa:	f0bc                	sd	a5,96(s1)
	p->context.sp = p->kstack + PGSIZE;
    80001cfc:	60bc                	ld	a5,64(s1)
    80001cfe:	6705                	lui	a4,0x1
    80001d00:	97ba                	add	a5,a5,a4
    80001d02:	f4bc                	sd	a5,104(s1)
	p->rtime = 0;
    80001d04:	1604a423          	sw	zero,360(s1)
	p->etime = 0;
    80001d08:	1604a823          	sw	zero,368(s1)
	p->ctime = ticks;
    80001d0c:	00007797          	auipc	a5,0x7
    80001d10:	c447a783          	lw	a5,-956(a5) # 80008950 <ticks>
    80001d14:	16f4a623          	sw	a5,364(s1)
	p->is_sigalarm = 0;
    80001d18:	1604aa23          	sw	zero,372(s1)
	p->ticks = 0;
    80001d1c:	1804a023          	sw	zero,384(s1)
	p->now_ticks = 0;
    80001d20:	1804a223          	sw	zero,388(s1)
	p->handler = 0;
    80001d24:	1804b423          	sd	zero,392(s1)
	p->sched_count = 0;
    80001d28:	1604ae23          	sw	zero,380(s1)
	p->start_time = 0 ;
    80001d2c:	1604ac23          	sw	zero,376(s1)
	p->queue_no = 0 ; 
    80001d30:	1804ac23          	sw	zero,408(s1)
	queues[0].arr[queues[0].queue_size] = p;
    80001d34:	19092783          	lw	a5,400(s2)
    80001d38:	00379713          	slli	a4,a5,0x3
    80001d3c:	974a                	add	a4,a4,s2
    80001d3e:	e304                	sd	s1,0(a4)
	queues[0].queue_size++;
    80001d40:	2785                	addiw	a5,a5,1
    80001d42:	18f92823          	sw	a5,400(s2)
}
    80001d46:	8526                	mv	a0,s1
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6902                	ld	s2,0(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret
		freeproc(p);
    80001d54:	8526                	mv	a0,s1
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	e92080e7          	jalr	-366(ra) # 80001be8 <freeproc>
		release(&p->lock);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	f26080e7          	jalr	-218(ra) # 80000c86 <release>
		return 0;
    80001d68:	84ca                	mv	s1,s2
    80001d6a:	bff1                	j	80001d46 <allocproc+0xfc>
		release(&p->lock);
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	f18080e7          	jalr	-232(ra) # 80000c86 <release>
		return 0;
    80001d76:	84ca                	mv	s1,s2
    80001d78:	b7f9                	j	80001d46 <allocproc+0xfc>
		freeproc(p);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	e6c080e7          	jalr	-404(ra) # 80001be8 <freeproc>
		release(&p->lock);
    80001d84:	8526                	mv	a0,s1
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	f00080e7          	jalr	-256(ra) # 80000c86 <release>
		return 0;
    80001d8e:	84ca                	mv	s1,s2
    80001d90:	bf5d                	j	80001d46 <allocproc+0xfc>

0000000080001d92 <userinit>:
{
    80001d92:	1101                	addi	sp,sp,-32
    80001d94:	ec06                	sd	ra,24(sp)
    80001d96:	e822                	sd	s0,16(sp)
    80001d98:	e426                	sd	s1,8(sp)
    80001d9a:	1000                	addi	s0,sp,32
	p = allocproc();
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	eae080e7          	jalr	-338(ra) # 80001c4a <allocproc>
    80001da4:	84aa                	mv	s1,a0
	initproc = p;
    80001da6:	00007797          	auipc	a5,0x7
    80001daa:	baa7b123          	sd	a0,-1118(a5) # 80008948 <initproc>
	uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001dae:	03400613          	li	a2,52
    80001db2:	00007597          	auipc	a1,0x7
    80001db6:	b0e58593          	addi	a1,a1,-1266 # 800088c0 <initcode>
    80001dba:	6928                	ld	a0,80(a0)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	594080e7          	jalr	1428(ra) # 80001350 <uvmfirst>
	p->sz = PGSIZE;
    80001dc4:	6785                	lui	a5,0x1
    80001dc6:	e4bc                	sd	a5,72(s1)
	p->trapframe->epc = 0; // user program counter
    80001dc8:	6cb8                	ld	a4,88(s1)
    80001dca:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
	p->trapframe->sp = PGSIZE; // user stack pointer
    80001dce:	6cb8                	ld	a4,88(s1)
    80001dd0:	fb1c                	sd	a5,48(a4)
	safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dd2:	4641                	li	a2,16
    80001dd4:	00006597          	auipc	a1,0x6
    80001dd8:	42c58593          	addi	a1,a1,1068 # 80008200 <digits+0x1c0>
    80001ddc:	15848513          	addi	a0,s1,344
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	036080e7          	jalr	54(ra) # 80000e16 <safestrcpy>
	p->cwd = namei("/");
    80001de8:	00006517          	auipc	a0,0x6
    80001dec:	42850513          	addi	a0,a0,1064 # 80008210 <digits+0x1d0>
    80001df0:	00002097          	auipc	ra,0x2
    80001df4:	594080e7          	jalr	1428(ra) # 80004384 <namei>
    80001df8:	14a4b823          	sd	a0,336(s1)
	p->state = RUNNABLE;
    80001dfc:	478d                	li	a5,3
    80001dfe:	cc9c                	sw	a5,24(s1)
	release(&p->lock);
    80001e00:	8526                	mv	a0,s1
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	e84080e7          	jalr	-380(ra) # 80000c86 <release>
}
    80001e0a:	60e2                	ld	ra,24(sp)
    80001e0c:	6442                	ld	s0,16(sp)
    80001e0e:	64a2                	ld	s1,8(sp)
    80001e10:	6105                	addi	sp,sp,32
    80001e12:	8082                	ret

0000000080001e14 <growproc>:
{
    80001e14:	1101                	addi	sp,sp,-32
    80001e16:	ec06                	sd	ra,24(sp)
    80001e18:	e822                	sd	s0,16(sp)
    80001e1a:	e426                	sd	s1,8(sp)
    80001e1c:	e04a                	sd	s2,0(sp)
    80001e1e:	1000                	addi	s0,sp,32
    80001e20:	892a                	mv	s2,a0
	struct proc* p = myproc();
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	bac080e7          	jalr	-1108(ra) # 800019ce <myproc>
    80001e2a:	84aa                	mv	s1,a0
	sz = p->sz;
    80001e2c:	652c                	ld	a1,72(a0)
	if(n > 0)
    80001e2e:	01204c63          	bgtz	s2,80001e46 <growproc+0x32>
	else if(n < 0)
    80001e32:	02094663          	bltz	s2,80001e5e <growproc+0x4a>
	p->sz = sz;
    80001e36:	e4ac                	sd	a1,72(s1)
	return 0;
    80001e38:	4501                	li	a0,0
}
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6902                	ld	s2,0(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret
		if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001e46:	4691                	li	a3,4
    80001e48:	00b90633          	add	a2,s2,a1
    80001e4c:	6928                	ld	a0,80(a0)
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	5bc080e7          	jalr	1468(ra) # 8000140a <uvmalloc>
    80001e56:	85aa                	mv	a1,a0
    80001e58:	fd79                	bnez	a0,80001e36 <growproc+0x22>
			return -1;
    80001e5a:	557d                	li	a0,-1
    80001e5c:	bff9                	j	80001e3a <growproc+0x26>
		sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e5e:	00b90633          	add	a2,s2,a1
    80001e62:	6928                	ld	a0,80(a0)
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	55e080e7          	jalr	1374(ra) # 800013c2 <uvmdealloc>
    80001e6c:	85aa                	mv	a1,a0
    80001e6e:	b7e1                	j	80001e36 <growproc+0x22>

0000000080001e70 <fork>:
{
    80001e70:	7139                	addi	sp,sp,-64
    80001e72:	fc06                	sd	ra,56(sp)
    80001e74:	f822                	sd	s0,48(sp)
    80001e76:	f426                	sd	s1,40(sp)
    80001e78:	f04a                	sd	s2,32(sp)
    80001e7a:	ec4e                	sd	s3,24(sp)
    80001e7c:	e852                	sd	s4,16(sp)
    80001e7e:	e456                	sd	s5,8(sp)
    80001e80:	0080                	addi	s0,sp,64
	struct proc* p = myproc();
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	b4c080e7          	jalr	-1204(ra) # 800019ce <myproc>
    80001e8a:	8aaa                	mv	s5,a0
	if((np = allocproc()) == 0)
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	dbe080e7          	jalr	-578(ra) # 80001c4a <allocproc>
    80001e94:	10050c63          	beqz	a0,80001fac <fork+0x13c>
    80001e98:	8a2a                	mv	s4,a0
	if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e9a:	048ab603          	ld	a2,72(s5)
    80001e9e:	692c                	ld	a1,80(a0)
    80001ea0:	050ab503          	ld	a0,80(s5)
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	6be080e7          	jalr	1726(ra) # 80001562 <uvmcopy>
    80001eac:	04054863          	bltz	a0,80001efc <fork+0x8c>
	np->sz = p->sz;
    80001eb0:	048ab783          	ld	a5,72(s5)
    80001eb4:	04fa3423          	sd	a5,72(s4)
	*(np->trapframe) = *(p->trapframe);
    80001eb8:	058ab683          	ld	a3,88(s5)
    80001ebc:	87b6                	mv	a5,a3
    80001ebe:	058a3703          	ld	a4,88(s4)
    80001ec2:	12068693          	addi	a3,a3,288
    80001ec6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001eca:	6788                	ld	a0,8(a5)
    80001ecc:	6b8c                	ld	a1,16(a5)
    80001ece:	6f90                	ld	a2,24(a5)
    80001ed0:	01073023          	sd	a6,0(a4)
    80001ed4:	e708                	sd	a0,8(a4)
    80001ed6:	eb0c                	sd	a1,16(a4)
    80001ed8:	ef10                	sd	a2,24(a4)
    80001eda:	02078793          	addi	a5,a5,32
    80001ede:	02070713          	addi	a4,a4,32
    80001ee2:	fed792e3          	bne	a5,a3,80001ec6 <fork+0x56>
	np->trapframe->a0 = 0;
    80001ee6:	058a3783          	ld	a5,88(s4)
    80001eea:	0607b823          	sd	zero,112(a5)
	for(i = 0; i < NOFILE; i++)
    80001eee:	0d0a8493          	addi	s1,s5,208
    80001ef2:	0d0a0913          	addi	s2,s4,208
    80001ef6:	150a8993          	addi	s3,s5,336
    80001efa:	a00d                	j	80001f1c <fork+0xac>
		freeproc(np);
    80001efc:	8552                	mv	a0,s4
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	cea080e7          	jalr	-790(ra) # 80001be8 <freeproc>
		release(&np->lock);
    80001f06:	8552                	mv	a0,s4
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d7e080e7          	jalr	-642(ra) # 80000c86 <release>
		return -1;
    80001f10:	597d                	li	s2,-1
    80001f12:	a059                	j	80001f98 <fork+0x128>
	for(i = 0; i < NOFILE; i++)
    80001f14:	04a1                	addi	s1,s1,8
    80001f16:	0921                	addi	s2,s2,8
    80001f18:	01348b63          	beq	s1,s3,80001f2e <fork+0xbe>
		if(p->ofile[i])
    80001f1c:	6088                	ld	a0,0(s1)
    80001f1e:	d97d                	beqz	a0,80001f14 <fork+0xa4>
			np->ofile[i] = filedup(p->ofile[i]);
    80001f20:	00003097          	auipc	ra,0x3
    80001f24:	ad6080e7          	jalr	-1322(ra) # 800049f6 <filedup>
    80001f28:	00a93023          	sd	a0,0(s2)
    80001f2c:	b7e5                	j	80001f14 <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001f2e:	150ab503          	ld	a0,336(s5)
    80001f32:	00002097          	auipc	ra,0x2
    80001f36:	c6e080e7          	jalr	-914(ra) # 80003ba0 <idup>
    80001f3a:	14aa3823          	sd	a0,336(s4)
	safestrcpy(np->name, p->name, sizeof(p->name));
    80001f3e:	4641                	li	a2,16
    80001f40:	158a8593          	addi	a1,s5,344
    80001f44:	158a0513          	addi	a0,s4,344
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	ece080e7          	jalr	-306(ra) # 80000e16 <safestrcpy>
	pid = np->pid;
    80001f50:	030a2903          	lw	s2,48(s4)
	release(&np->lock);
    80001f54:	8552                	mv	a0,s4
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	d30080e7          	jalr	-720(ra) # 80000c86 <release>
	acquire(&wait_lock);
    80001f5e:	0000f497          	auipc	s1,0xf
    80001f62:	2da48493          	addi	s1,s1,730 # 80011238 <wait_lock>
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	c6a080e7          	jalr	-918(ra) # 80000bd2 <acquire>
	np->parent = p;
    80001f70:	035a3c23          	sd	s5,56(s4)
	release(&wait_lock);
    80001f74:	8526                	mv	a0,s1
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	d10080e7          	jalr	-752(ra) # 80000c86 <release>
	acquire(&np->lock);
    80001f7e:	8552                	mv	a0,s4
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	c52080e7          	jalr	-942(ra) # 80000bd2 <acquire>
	np->state = RUNNABLE;
    80001f88:	478d                	li	a5,3
    80001f8a:	00fa2c23          	sw	a5,24(s4)
	release(&np->lock);
    80001f8e:	8552                	mv	a0,s4
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	cf6080e7          	jalr	-778(ra) # 80000c86 <release>
}
    80001f98:	854a                	mv	a0,s2
    80001f9a:	70e2                	ld	ra,56(sp)
    80001f9c:	7442                	ld	s0,48(sp)
    80001f9e:	74a2                	ld	s1,40(sp)
    80001fa0:	7902                	ld	s2,32(sp)
    80001fa2:	69e2                	ld	s3,24(sp)
    80001fa4:	6a42                	ld	s4,16(sp)
    80001fa6:	6aa2                	ld	s5,8(sp)
    80001fa8:	6121                	addi	sp,sp,64
    80001faa:	8082                	ret
		return -1;
    80001fac:	597d                	li	s2,-1
    80001fae:	b7ed                	j	80001f98 <fork+0x128>

0000000080001fb0 <queue_remove>:
{
    80001fb0:	1141                	addi	sp,sp,-16
    80001fb2:	e422                	sd	s0,8(sp)
    80001fb4:	0800                	addi	s0,sp,16
	for(i = proc_idx; i < queues[queue_no].queue_size - 1; i++)
    80001fb6:	19800713          	li	a4,408
    80001fba:	02e58733          	mul	a4,a1,a4
    80001fbe:	0000f797          	auipc	a5,0xf
    80001fc2:	c0278793          	addi	a5,a5,-1022 # 80010bc0 <queues>
    80001fc6:	97ba                	add	a5,a5,a4
    80001fc8:	1907a683          	lw	a3,400(a5)
    80001fcc:	fff6861b          	addiw	a2,a3,-1
    80001fd0:	0006079b          	sext.w	a5,a2
    80001fd4:	02f55663          	bge	a0,a5,80002000 <queue_remove+0x50>
    80001fd8:	00159793          	slli	a5,a1,0x1
    80001fdc:	97ae                	add	a5,a5,a1
    80001fde:	00479713          	slli	a4,a5,0x4
    80001fe2:	973e                	add	a4,a4,a5
    80001fe4:	972a                	add	a4,a4,a0
    80001fe6:	070e                	slli	a4,a4,0x3
    80001fe8:	0000f797          	auipc	a5,0xf
    80001fec:	bd878793          	addi	a5,a5,-1064 # 80010bc0 <queues>
    80001ff0:	97ba                	add	a5,a5,a4
    80001ff2:	36fd                	addiw	a3,a3,-1
		queues[queue_no].arr[i] = queues[queue_no].arr[i + 1];
    80001ff4:	2505                	addiw	a0,a0,1
    80001ff6:	6798                	ld	a4,8(a5)
    80001ff8:	e398                	sd	a4,0(a5)
	for(i = proc_idx; i < queues[queue_no].queue_size - 1; i++)
    80001ffa:	07a1                	addi	a5,a5,8
    80001ffc:	fed51ce3          	bne	a0,a3,80001ff4 <queue_remove+0x44>
	queues[queue_no].queue_size--;
    80002000:	19800793          	li	a5,408
    80002004:	02f585b3          	mul	a1,a1,a5
    80002008:	0000f797          	auipc	a5,0xf
    8000200c:	bb878793          	addi	a5,a5,-1096 # 80010bc0 <queues>
    80002010:	97ae                	add	a5,a5,a1
    80002012:	18c7a823          	sw	a2,400(a5)
}
    80002016:	6422                	ld	s0,8(sp)
    80002018:	0141                	addi	sp,sp,16
    8000201a:	8082                	ret

000000008000201c <queue_add>:
{
    8000201c:	1141                	addi	sp,sp,-16
    8000201e:	e422                	sd	s0,8(sp)
    80002020:	0800                	addi	s0,sp,16
	int new_process_idx = queues[queue_no].queue_size;
    80002022:	0000f617          	auipc	a2,0xf
    80002026:	b9e60613          	addi	a2,a2,-1122 # 80010bc0 <queues>
    8000202a:	19800713          	li	a4,408
    8000202e:	02e58733          	mul	a4,a1,a4
    80002032:	9732                	add	a4,a4,a2
    80002034:	19072683          	lw	a3,400(a4)
	queues[queue_no].arr[new_process_idx] = p;
    80002038:	00159793          	slli	a5,a1,0x1
    8000203c:	95be                	add	a1,a1,a5
    8000203e:	00459793          	slli	a5,a1,0x4
    80002042:	95be                	add	a1,a1,a5
    80002044:	95b6                	add	a1,a1,a3
    80002046:	058e                	slli	a1,a1,0x3
    80002048:	962e                	add	a2,a2,a1
    8000204a:	e208                	sd	a0,0(a2)
	queues[queue_no].queue_size++;
    8000204c:	2685                	addiw	a3,a3,1
    8000204e:	18d72823          	sw	a3,400(a4)
}
    80002052:	6422                	ld	s0,8(sp)
    80002054:	0141                	addi	sp,sp,16
    80002056:	8082                	ret

0000000080002058 <scheduler>:
{
    80002058:	7119                	addi	sp,sp,-128
    8000205a:	fc86                	sd	ra,120(sp)
    8000205c:	f8a2                	sd	s0,112(sp)
    8000205e:	f4a6                	sd	s1,104(sp)
    80002060:	f0ca                	sd	s2,96(sp)
    80002062:	ecce                	sd	s3,88(sp)
    80002064:	e8d2                	sd	s4,80(sp)
    80002066:	e4d6                	sd	s5,72(sp)
    80002068:	e0da                	sd	s6,64(sp)
    8000206a:	fc5e                	sd	s7,56(sp)
    8000206c:	f862                	sd	s8,48(sp)
    8000206e:	f466                	sd	s9,40(sp)
    80002070:	f06a                	sd	s10,32(sp)
    80002072:	ec6e                	sd	s11,24(sp)
    80002074:	0100                	addi	s0,sp,128
    80002076:	8792                	mv	a5,tp
	int id = r_tp();
    80002078:	2781                	sext.w	a5,a5
	c->proc = 0;
    8000207a:	00779693          	slli	a3,a5,0x7
    8000207e:	0000f717          	auipc	a4,0xf
    80002082:	b4270713          	addi	a4,a4,-1214 # 80010bc0 <queues>
    80002086:	9736                	add	a4,a4,a3
    80002088:	68073823          	sd	zero,1680(a4)
				swtch(&c->context, &executable->context);
    8000208c:	0000f717          	auipc	a4,0xf
    80002090:	1cc70713          	addi	a4,a4,460 # 80011258 <cpus+0x8>
    80002094:	9736                	add	a4,a4,a3
    80002096:	f8e43423          	sd	a4,-120(s0)
		for(i=0;i<NUM_OF_QUEUES;i++)
    8000209a:	4c81                	li	s9,0
    8000209c:	4c11                	li	s8,4
					if( queues[i].arr[j]->state == RUNNABLE)
    8000209e:	4b8d                	li	s7,3
						release(&queues[i].arr[j]->lock);
    800020a0:	0000fd17          	auipc	s10,0xf
    800020a4:	b20d0d13          	addi	s10,s10,-1248 # 80010bc0 <queues>
				c->proc = executable;
    800020a8:	00dd0db3          	add	s11,s10,a3
    800020ac:	a8a5                	j	80002124 <scheduler+0xcc>
						queue_remove(j,i);
    800020ae:	85da                	mv	a1,s6
    800020b0:	854e                	mv	a0,s3
    800020b2:	00000097          	auipc	ra,0x0
    800020b6:	efe080e7          	jalr	-258(ra) # 80001fb0 <queue_remove>
						printf("process %d is running in queue %d\n",temp->pid,i);
    800020ba:	865a                	mv	a2,s6
    800020bc:	03092583          	lw	a1,48(s2)
    800020c0:	00006517          	auipc	a0,0x6
    800020c4:	15850513          	addi	a0,a0,344 # 80008218 <digits+0x1d8>
    800020c8:	ffffe097          	auipc	ra,0xffffe
    800020cc:	4be080e7          	jalr	1214(ra) # 80000586 <printf>
						release(&queues[i].arr[j]->lock);
    800020d0:	001b1793          	slli	a5,s6,0x1
    800020d4:	97da                	add	a5,a5,s6
    800020d6:	00479713          	slli	a4,a5,0x4
    800020da:	97ba                	add	a5,a5,a4
    800020dc:	97ce                	add	a5,a5,s3
    800020de:	078e                	slli	a5,a5,0x3
    800020e0:	97ea                	add	a5,a5,s10
    800020e2:	6388                	ld	a0,0(a5)
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba2080e7          	jalr	-1118(ra) # 80000c86 <release>
			acquire(&executable->lock);
    800020ec:	854a                	mv	a0,s2
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	ae4080e7          	jalr	-1308(ra) # 80000bd2 <acquire>
			if(executable->state == RUNNABLE)
    800020f6:	01892783          	lw	a5,24(s2)
    800020fa:	03779063          	bne	a5,s7,8000211a <scheduler+0xc2>
				executable->state = RUNNING;
    800020fe:	01892c23          	sw	s8,24(s2)
				c->proc = executable;
    80002102:	692db823          	sd	s2,1680(s11)
				swtch(&c->context, &executable->context);
    80002106:	06090593          	addi	a1,s2,96
    8000210a:	f8843503          	ld	a0,-120(s0)
    8000210e:	00001097          	auipc	ra,0x1
    80002112:	8a0080e7          	jalr	-1888(ra) # 800029ae <swtch>
				c->proc = 0;
    80002116:	680db823          	sd	zero,1680(s11)
			release(&executable->lock);
    8000211a:	854a                	mv	a0,s2
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	b6a080e7          	jalr	-1174(ra) # 80000c86 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002124:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002128:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000212c:	10079073          	csrw	sstatus,a5
		for(i=0;i<NUM_OF_QUEUES;i++)
    80002130:	0000fa17          	auipc	s4,0xf
    80002134:	a90a0a13          	addi	s4,s4,-1392 # 80010bc0 <queues>
    80002138:	8b66                	mv	s6,s9
    8000213a:	a031                	j	80002146 <scheduler+0xee>
    8000213c:	2b05                	addiw	s6,s6,1
    8000213e:	198a0a13          	addi	s4,s4,408
    80002142:	ff8b01e3          	beq	s6,s8,80002124 <scheduler+0xcc>
			if(queues[i].queue_size>0)
    80002146:	8ad2                	mv	s5,s4
    80002148:	190a2783          	lw	a5,400(s4)
    8000214c:	fef058e3          	blez	a5,8000213c <scheduler+0xe4>
    80002150:	84d2                	mv	s1,s4
				for (int j = 0; j < queues[i].queue_size; j++)
    80002152:	89e6                	mv	s3,s9
					acquire(&queues[i].arr[j]->lock);
    80002154:	6088                	ld	a0,0(s1)
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	a7c080e7          	jalr	-1412(ra) # 80000bd2 <acquire>
					struct proc* temp = queues[i].arr[j] ; 
    8000215e:	0004b903          	ld	s2,0(s1)
					if( queues[i].arr[j]->state == RUNNABLE)
    80002162:	01892783          	lw	a5,24(s2)
    80002166:	f57784e3          	beq	a5,s7,800020ae <scheduler+0x56>
					release(&queues[i].arr[j]->lock);
    8000216a:	854a                	mv	a0,s2
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b1a080e7          	jalr	-1254(ra) # 80000c86 <release>
				for (int j = 0; j < queues[i].queue_size; j++)
    80002174:	2985                	addiw	s3,s3,1
    80002176:	04a1                	addi	s1,s1,8
    80002178:	190aa783          	lw	a5,400(s5)
    8000217c:	fcf9cce3          	blt	s3,a5,80002154 <scheduler+0xfc>
    80002180:	bf75                	j	8000213c <scheduler+0xe4>

0000000080002182 <sched>:
{
    80002182:	7179                	addi	sp,sp,-48
    80002184:	f406                	sd	ra,40(sp)
    80002186:	f022                	sd	s0,32(sp)
    80002188:	ec26                	sd	s1,24(sp)
    8000218a:	e84a                	sd	s2,16(sp)
    8000218c:	e44e                	sd	s3,8(sp)
    8000218e:	1800                	addi	s0,sp,48
	struct proc* p = myproc();
    80002190:	00000097          	auipc	ra,0x0
    80002194:	83e080e7          	jalr	-1986(ra) # 800019ce <myproc>
    80002198:	84aa                	mv	s1,a0
	if(!holding(&p->lock))
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	9be080e7          	jalr	-1602(ra) # 80000b58 <holding>
    800021a2:	c93d                	beqz	a0,80002218 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021a4:	8792                	mv	a5,tp
	if(mycpu()->noff != 1)
    800021a6:	2781                	sext.w	a5,a5
    800021a8:	079e                	slli	a5,a5,0x7
    800021aa:	0000f717          	auipc	a4,0xf
    800021ae:	a1670713          	addi	a4,a4,-1514 # 80010bc0 <queues>
    800021b2:	97ba                	add	a5,a5,a4
    800021b4:	7087a703          	lw	a4,1800(a5)
    800021b8:	4785                	li	a5,1
    800021ba:	06f71763          	bne	a4,a5,80002228 <sched+0xa6>
	if(p->state == RUNNING)
    800021be:	4c98                	lw	a4,24(s1)
    800021c0:	4791                	li	a5,4
    800021c2:	06f70b63          	beq	a4,a5,80002238 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021c6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021ca:	8b89                	andi	a5,a5,2
	if(intr_get())
    800021cc:	efb5                	bnez	a5,80002248 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021ce:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    800021d0:	0000f917          	auipc	s2,0xf
    800021d4:	9f090913          	addi	s2,s2,-1552 # 80010bc0 <queues>
    800021d8:	2781                	sext.w	a5,a5
    800021da:	079e                	slli	a5,a5,0x7
    800021dc:	97ca                	add	a5,a5,s2
    800021de:	70c7a983          	lw	s3,1804(a5)
    800021e2:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    800021e4:	2781                	sext.w	a5,a5
    800021e6:	079e                	slli	a5,a5,0x7
    800021e8:	0000f597          	auipc	a1,0xf
    800021ec:	07058593          	addi	a1,a1,112 # 80011258 <cpus+0x8>
    800021f0:	95be                	add	a1,a1,a5
    800021f2:	06048513          	addi	a0,s1,96
    800021f6:	00000097          	auipc	ra,0x0
    800021fa:	7b8080e7          	jalr	1976(ra) # 800029ae <swtch>
    800021fe:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    80002200:	2781                	sext.w	a5,a5
    80002202:	079e                	slli	a5,a5,0x7
    80002204:	993e                	add	s2,s2,a5
    80002206:	71392623          	sw	s3,1804(s2)
}
    8000220a:	70a2                	ld	ra,40(sp)
    8000220c:	7402                	ld	s0,32(sp)
    8000220e:	64e2                	ld	s1,24(sp)
    80002210:	6942                	ld	s2,16(sp)
    80002212:	69a2                	ld	s3,8(sp)
    80002214:	6145                	addi	sp,sp,48
    80002216:	8082                	ret
		panic("sched p->lock");
    80002218:	00006517          	auipc	a0,0x6
    8000221c:	02850513          	addi	a0,a0,40 # 80008240 <digits+0x200>
    80002220:	ffffe097          	auipc	ra,0xffffe
    80002224:	31c080e7          	jalr	796(ra) # 8000053c <panic>
		panic("sched locks");
    80002228:	00006517          	auipc	a0,0x6
    8000222c:	02850513          	addi	a0,a0,40 # 80008250 <digits+0x210>
    80002230:	ffffe097          	auipc	ra,0xffffe
    80002234:	30c080e7          	jalr	780(ra) # 8000053c <panic>
		panic("sched running");
    80002238:	00006517          	auipc	a0,0x6
    8000223c:	02850513          	addi	a0,a0,40 # 80008260 <digits+0x220>
    80002240:	ffffe097          	auipc	ra,0xffffe
    80002244:	2fc080e7          	jalr	764(ra) # 8000053c <panic>
		panic("sched interruptible");
    80002248:	00006517          	auipc	a0,0x6
    8000224c:	02850513          	addi	a0,a0,40 # 80008270 <digits+0x230>
    80002250:	ffffe097          	auipc	ra,0xffffe
    80002254:	2ec080e7          	jalr	748(ra) # 8000053c <panic>

0000000080002258 <yield>:
{
    80002258:	1101                	addi	sp,sp,-32
    8000225a:	ec06                	sd	ra,24(sp)
    8000225c:	e822                	sd	s0,16(sp)
    8000225e:	e426                	sd	s1,8(sp)
    80002260:	1000                	addi	s0,sp,32
	struct proc* p = myproc();
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	76c080e7          	jalr	1900(ra) # 800019ce <myproc>
    8000226a:	84aa                	mv	s1,a0
	acquire(&p->lock);
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	966080e7          	jalr	-1690(ra) # 80000bd2 <acquire>
	p->state = RUNNABLE;
    80002274:	478d                	li	a5,3
    80002276:	cc9c                	sw	a5,24(s1)
	sched();
    80002278:	00000097          	auipc	ra,0x0
    8000227c:	f0a080e7          	jalr	-246(ra) # 80002182 <sched>
	release(&p->lock);
    80002280:	8526                	mv	a0,s1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	a04080e7          	jalr	-1532(ra) # 80000c86 <release>
}
    8000228a:	60e2                	ld	ra,24(sp)
    8000228c:	6442                	ld	s0,16(sp)
    8000228e:	64a2                	ld	s1,8(sp)
    80002290:	6105                	addi	sp,sp,32
    80002292:	8082                	ret

0000000080002294 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void* chan, struct spinlock* lk)
{
    80002294:	7179                	addi	sp,sp,-48
    80002296:	f406                	sd	ra,40(sp)
    80002298:	f022                	sd	s0,32(sp)
    8000229a:	ec26                	sd	s1,24(sp)
    8000229c:	e84a                	sd	s2,16(sp)
    8000229e:	e44e                	sd	s3,8(sp)
    800022a0:	1800                	addi	s0,sp,48
    800022a2:	89aa                	mv	s3,a0
    800022a4:	892e                	mv	s2,a1
	struct proc* p = myproc();
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	728080e7          	jalr	1832(ra) # 800019ce <myproc>
    800022ae:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); // DOC: sleeplock1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	922080e7          	jalr	-1758(ra) # 80000bd2 <acquire>
	release(lk);
    800022b8:	854a                	mv	a0,s2
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	9cc080e7          	jalr	-1588(ra) # 80000c86 <release>

	// Go to sleep.
	p->chan = chan;
    800022c2:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    800022c6:	4789                	li	a5,2
    800022c8:	cc9c                	sw	a5,24(s1)

	sched();
    800022ca:	00000097          	auipc	ra,0x0
    800022ce:	eb8080e7          	jalr	-328(ra) # 80002182 <sched>

	// Tidy up.
	p->chan = 0;
    800022d2:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	9ae080e7          	jalr	-1618(ra) # 80000c86 <release>
	acquire(lk);
    800022e0:	854a                	mv	a0,s2
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	8f0080e7          	jalr	-1808(ra) # 80000bd2 <acquire>
}
    800022ea:	70a2                	ld	ra,40(sp)
    800022ec:	7402                	ld	s0,32(sp)
    800022ee:	64e2                	ld	s1,24(sp)
    800022f0:	6942                	ld	s2,16(sp)
    800022f2:	69a2                	ld	s3,8(sp)
    800022f4:	6145                	addi	sp,sp,48
    800022f6:	8082                	ret

00000000800022f8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void* chan)
{
    800022f8:	7139                	addi	sp,sp,-64
    800022fa:	fc06                	sd	ra,56(sp)
    800022fc:	f822                	sd	s0,48(sp)
    800022fe:	f426                	sd	s1,40(sp)
    80002300:	f04a                	sd	s2,32(sp)
    80002302:	ec4e                	sd	s3,24(sp)
    80002304:	e852                	sd	s4,16(sp)
    80002306:	e456                	sd	s5,8(sp)
    80002308:	0080                	addi	s0,sp,64
    8000230a:	8a2a                	mv	s4,a0
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    8000230c:	0000f497          	auipc	s1,0xf
    80002310:	34448493          	addi	s1,s1,836 # 80011650 <proc>
	{
		if(p != myproc())
		{
			acquire(&p->lock);
			if(p->state == SLEEPING && p->chan == chan)
    80002314:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    80002316:	4a8d                	li	s5,3
	for(p = proc; p < &proc[NPROC]; p++)
    80002318:	00016917          	auipc	s2,0x16
    8000231c:	f3890913          	addi	s2,s2,-200 # 80018250 <tickslock>
    80002320:	a811                	j	80002334 <wakeup+0x3c>
			}
			release(&p->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	962080e7          	jalr	-1694(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    8000232c:	1b048493          	addi	s1,s1,432
    80002330:	03248663          	beq	s1,s2,8000235c <wakeup+0x64>
		if(p != myproc())
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	69a080e7          	jalr	1690(ra) # 800019ce <myproc>
    8000233c:	fea488e3          	beq	s1,a0,8000232c <wakeup+0x34>
			acquire(&p->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	890080e7          	jalr	-1904(ra) # 80000bd2 <acquire>
			if(p->state == SLEEPING && p->chan == chan)
    8000234a:	4c9c                	lw	a5,24(s1)
    8000234c:	fd379be3          	bne	a5,s3,80002322 <wakeup+0x2a>
    80002350:	709c                	ld	a5,32(s1)
    80002352:	fd4798e3          	bne	a5,s4,80002322 <wakeup+0x2a>
				p->state = RUNNABLE;
    80002356:	0154ac23          	sw	s5,24(s1)
    8000235a:	b7e1                	j	80002322 <wakeup+0x2a>
		}
	}
}
    8000235c:	70e2                	ld	ra,56(sp)
    8000235e:	7442                	ld	s0,48(sp)
    80002360:	74a2                	ld	s1,40(sp)
    80002362:	7902                	ld	s2,32(sp)
    80002364:	69e2                	ld	s3,24(sp)
    80002366:	6a42                	ld	s4,16(sp)
    80002368:	6aa2                	ld	s5,8(sp)
    8000236a:	6121                	addi	sp,sp,64
    8000236c:	8082                	ret

000000008000236e <reparent>:
{
    8000236e:	7179                	addi	sp,sp,-48
    80002370:	f406                	sd	ra,40(sp)
    80002372:	f022                	sd	s0,32(sp)
    80002374:	ec26                	sd	s1,24(sp)
    80002376:	e84a                	sd	s2,16(sp)
    80002378:	e44e                	sd	s3,8(sp)
    8000237a:	e052                	sd	s4,0(sp)
    8000237c:	1800                	addi	s0,sp,48
    8000237e:	892a                	mv	s2,a0
	for(pp = proc; pp < &proc[NPROC]; pp++)
    80002380:	0000f497          	auipc	s1,0xf
    80002384:	2d048493          	addi	s1,s1,720 # 80011650 <proc>
			pp->parent = initproc;
    80002388:	00006a17          	auipc	s4,0x6
    8000238c:	5c0a0a13          	addi	s4,s4,1472 # 80008948 <initproc>
	for(pp = proc; pp < &proc[NPROC]; pp++)
    80002390:	00016997          	auipc	s3,0x16
    80002394:	ec098993          	addi	s3,s3,-320 # 80018250 <tickslock>
    80002398:	a029                	j	800023a2 <reparent+0x34>
    8000239a:	1b048493          	addi	s1,s1,432
    8000239e:	01348d63          	beq	s1,s3,800023b8 <reparent+0x4a>
		if(pp->parent == p)
    800023a2:	7c9c                	ld	a5,56(s1)
    800023a4:	ff279be3          	bne	a5,s2,8000239a <reparent+0x2c>
			pp->parent = initproc;
    800023a8:	000a3503          	ld	a0,0(s4)
    800023ac:	fc88                	sd	a0,56(s1)
			wakeup(initproc);
    800023ae:	00000097          	auipc	ra,0x0
    800023b2:	f4a080e7          	jalr	-182(ra) # 800022f8 <wakeup>
    800023b6:	b7d5                	j	8000239a <reparent+0x2c>
}
    800023b8:	70a2                	ld	ra,40(sp)
    800023ba:	7402                	ld	s0,32(sp)
    800023bc:	64e2                	ld	s1,24(sp)
    800023be:	6942                	ld	s2,16(sp)
    800023c0:	69a2                	ld	s3,8(sp)
    800023c2:	6a02                	ld	s4,0(sp)
    800023c4:	6145                	addi	sp,sp,48
    800023c6:	8082                	ret

00000000800023c8 <exit>:
{
    800023c8:	7179                	addi	sp,sp,-48
    800023ca:	f406                	sd	ra,40(sp)
    800023cc:	f022                	sd	s0,32(sp)
    800023ce:	ec26                	sd	s1,24(sp)
    800023d0:	e84a                	sd	s2,16(sp)
    800023d2:	e44e                	sd	s3,8(sp)
    800023d4:	e052                	sd	s4,0(sp)
    800023d6:	1800                	addi	s0,sp,48
    800023d8:	8a2a                	mv	s4,a0
	struct proc* p = myproc();
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	5f4080e7          	jalr	1524(ra) # 800019ce <myproc>
    800023e2:	89aa                	mv	s3,a0
	if(p == initproc)
    800023e4:	00006797          	auipc	a5,0x6
    800023e8:	5647b783          	ld	a5,1380(a5) # 80008948 <initproc>
    800023ec:	0d050493          	addi	s1,a0,208
    800023f0:	15050913          	addi	s2,a0,336
    800023f4:	02a79363          	bne	a5,a0,8000241a <exit+0x52>
		panic("init exiting");
    800023f8:	00006517          	auipc	a0,0x6
    800023fc:	e9050513          	addi	a0,a0,-368 # 80008288 <digits+0x248>
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	13c080e7          	jalr	316(ra) # 8000053c <panic>
			fileclose(f);
    80002408:	00002097          	auipc	ra,0x2
    8000240c:	640080e7          	jalr	1600(ra) # 80004a48 <fileclose>
			p->ofile[fd] = 0;
    80002410:	0004b023          	sd	zero,0(s1)
	for(int fd = 0; fd < NOFILE; fd++)
    80002414:	04a1                	addi	s1,s1,8
    80002416:	01248563          	beq	s1,s2,80002420 <exit+0x58>
		if(p->ofile[fd])
    8000241a:	6088                	ld	a0,0(s1)
    8000241c:	f575                	bnez	a0,80002408 <exit+0x40>
    8000241e:	bfdd                	j	80002414 <exit+0x4c>
	begin_op();
    80002420:	00002097          	auipc	ra,0x2
    80002424:	164080e7          	jalr	356(ra) # 80004584 <begin_op>
	iput(p->cwd);
    80002428:	1509b503          	ld	a0,336(s3)
    8000242c:	00002097          	auipc	ra,0x2
    80002430:	96c080e7          	jalr	-1684(ra) # 80003d98 <iput>
	end_op();
    80002434:	00002097          	auipc	ra,0x2
    80002438:	1ca080e7          	jalr	458(ra) # 800045fe <end_op>
	p->cwd = 0;
    8000243c:	1409b823          	sd	zero,336(s3)
	acquire(&wait_lock);
    80002440:	0000f497          	auipc	s1,0xf
    80002444:	df848493          	addi	s1,s1,-520 # 80011238 <wait_lock>
    80002448:	8526                	mv	a0,s1
    8000244a:	ffffe097          	auipc	ra,0xffffe
    8000244e:	788080e7          	jalr	1928(ra) # 80000bd2 <acquire>
	reparent(p);
    80002452:	854e                	mv	a0,s3
    80002454:	00000097          	auipc	ra,0x0
    80002458:	f1a080e7          	jalr	-230(ra) # 8000236e <reparent>
	wakeup(p->parent);
    8000245c:	0389b503          	ld	a0,56(s3)
    80002460:	00000097          	auipc	ra,0x0
    80002464:	e98080e7          	jalr	-360(ra) # 800022f8 <wakeup>
	acquire(&p->lock);
    80002468:	854e                	mv	a0,s3
    8000246a:	ffffe097          	auipc	ra,0xffffe
    8000246e:	768080e7          	jalr	1896(ra) # 80000bd2 <acquire>
	p->xstate = status;
    80002472:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    80002476:	4795                	li	a5,5
    80002478:	00f9ac23          	sw	a5,24(s3)
	p->etime = ticks;
    8000247c:	00006797          	auipc	a5,0x6
    80002480:	4d47a783          	lw	a5,1236(a5) # 80008950 <ticks>
    80002484:	16f9a823          	sw	a5,368(s3)
	release(&wait_lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	7fc080e7          	jalr	2044(ra) # 80000c86 <release>
	sched();
    80002492:	00000097          	auipc	ra,0x0
    80002496:	cf0080e7          	jalr	-784(ra) # 80002182 <sched>
	panic("zombie exit");
    8000249a:	00006517          	auipc	a0,0x6
    8000249e:	dfe50513          	addi	a0,a0,-514 # 80008298 <digits+0x258>
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	09a080e7          	jalr	154(ra) # 8000053c <panic>

00000000800024aa <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800024aa:	7179                	addi	sp,sp,-48
    800024ac:	f406                	sd	ra,40(sp)
    800024ae:	f022                	sd	s0,32(sp)
    800024b0:	ec26                	sd	s1,24(sp)
    800024b2:	e84a                	sd	s2,16(sp)
    800024b4:	e44e                	sd	s3,8(sp)
    800024b6:	1800                	addi	s0,sp,48
    800024b8:	892a                	mv	s2,a0
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    800024ba:	0000f497          	auipc	s1,0xf
    800024be:	19648493          	addi	s1,s1,406 # 80011650 <proc>
    800024c2:	00016997          	auipc	s3,0x16
    800024c6:	d8e98993          	addi	s3,s3,-626 # 80018250 <tickslock>
	{
		acquire(&p->lock);
    800024ca:	8526                	mv	a0,s1
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	706080e7          	jalr	1798(ra) # 80000bd2 <acquire>
		if(p->pid == pid)
    800024d4:	589c                	lw	a5,48(s1)
    800024d6:	01278d63          	beq	a5,s2,800024f0 <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    800024da:	8526                	mv	a0,s1
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	7aa080e7          	jalr	1962(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    800024e4:	1b048493          	addi	s1,s1,432
    800024e8:	ff3491e3          	bne	s1,s3,800024ca <kill+0x20>
	}
	return -1;
    800024ec:	557d                	li	a0,-1
    800024ee:	a829                	j	80002508 <kill+0x5e>
			p->killed = 1;
    800024f0:	4785                	li	a5,1
    800024f2:	d49c                	sw	a5,40(s1)
			if(p->state == SLEEPING)
    800024f4:	4c98                	lw	a4,24(s1)
    800024f6:	4789                	li	a5,2
    800024f8:	00f70f63          	beq	a4,a5,80002516 <kill+0x6c>
			release(&p->lock);
    800024fc:	8526                	mv	a0,s1
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	788080e7          	jalr	1928(ra) # 80000c86 <release>
			return 0;
    80002506:	4501                	li	a0,0
}
    80002508:	70a2                	ld	ra,40(sp)
    8000250a:	7402                	ld	s0,32(sp)
    8000250c:	64e2                	ld	s1,24(sp)
    8000250e:	6942                	ld	s2,16(sp)
    80002510:	69a2                	ld	s3,8(sp)
    80002512:	6145                	addi	sp,sp,48
    80002514:	8082                	ret
				p->state = RUNNABLE;
    80002516:	478d                	li	a5,3
    80002518:	cc9c                	sw	a5,24(s1)
    8000251a:	b7cd                	j	800024fc <kill+0x52>

000000008000251c <setkilled>:

void setkilled(struct proc* p)
{
    8000251c:	1101                	addi	sp,sp,-32
    8000251e:	ec06                	sd	ra,24(sp)
    80002520:	e822                	sd	s0,16(sp)
    80002522:	e426                	sd	s1,8(sp)
    80002524:	1000                	addi	s0,sp,32
    80002526:	84aa                	mv	s1,a0
	acquire(&p->lock);
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	6aa080e7          	jalr	1706(ra) # 80000bd2 <acquire>
	p->killed = 1;
    80002530:	4785                	li	a5,1
    80002532:	d49c                	sw	a5,40(s1)
	release(&p->lock);
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	750080e7          	jalr	1872(ra) # 80000c86 <release>
}
    8000253e:	60e2                	ld	ra,24(sp)
    80002540:	6442                	ld	s0,16(sp)
    80002542:	64a2                	ld	s1,8(sp)
    80002544:	6105                	addi	sp,sp,32
    80002546:	8082                	ret

0000000080002548 <killed>:

int killed(struct proc* p)
{
    80002548:	1101                	addi	sp,sp,-32
    8000254a:	ec06                	sd	ra,24(sp)
    8000254c:	e822                	sd	s0,16(sp)
    8000254e:	e426                	sd	s1,8(sp)
    80002550:	e04a                	sd	s2,0(sp)
    80002552:	1000                	addi	s0,sp,32
    80002554:	84aa                	mv	s1,a0
	int k;

	acquire(&p->lock);
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	67c080e7          	jalr	1660(ra) # 80000bd2 <acquire>
	k = p->killed;
    8000255e:	0284a903          	lw	s2,40(s1)
	release(&p->lock);
    80002562:	8526                	mv	a0,s1
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	722080e7          	jalr	1826(ra) # 80000c86 <release>
	return k;
}
    8000256c:	854a                	mv	a0,s2
    8000256e:	60e2                	ld	ra,24(sp)
    80002570:	6442                	ld	s0,16(sp)
    80002572:	64a2                	ld	s1,8(sp)
    80002574:	6902                	ld	s2,0(sp)
    80002576:	6105                	addi	sp,sp,32
    80002578:	8082                	ret

000000008000257a <wait>:
{
    8000257a:	715d                	addi	sp,sp,-80
    8000257c:	e486                	sd	ra,72(sp)
    8000257e:	e0a2                	sd	s0,64(sp)
    80002580:	fc26                	sd	s1,56(sp)
    80002582:	f84a                	sd	s2,48(sp)
    80002584:	f44e                	sd	s3,40(sp)
    80002586:	f052                	sd	s4,32(sp)
    80002588:	ec56                	sd	s5,24(sp)
    8000258a:	e85a                	sd	s6,16(sp)
    8000258c:	e45e                	sd	s7,8(sp)
    8000258e:	e062                	sd	s8,0(sp)
    80002590:	0880                	addi	s0,sp,80
    80002592:	8b2a                	mv	s6,a0
	struct proc* p = myproc();
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	43a080e7          	jalr	1082(ra) # 800019ce <myproc>
    8000259c:	892a                	mv	s2,a0
	acquire(&wait_lock);
    8000259e:	0000f517          	auipc	a0,0xf
    800025a2:	c9a50513          	addi	a0,a0,-870 # 80011238 <wait_lock>
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	62c080e7          	jalr	1580(ra) # 80000bd2 <acquire>
		havekids = 0;
    800025ae:	4b81                	li	s7,0
				if(pp->state == ZOMBIE)
    800025b0:	4a15                	li	s4,5
				havekids = 1;
    800025b2:	4a85                	li	s5,1
		for(pp = proc; pp < &proc[NPROC]; pp++)
    800025b4:	00016997          	auipc	s3,0x16
    800025b8:	c9c98993          	addi	s3,s3,-868 # 80018250 <tickslock>
		sleep(p, &wait_lock); // DOC: wait-sleep
    800025bc:	0000fc17          	auipc	s8,0xf
    800025c0:	c7cc0c13          	addi	s8,s8,-900 # 80011238 <wait_lock>
    800025c4:	a0d1                	j	80002688 <wait+0x10e>
					pid = pp->pid;
    800025c6:	0304a983          	lw	s3,48(s1)
					if(addr != 0 &&
    800025ca:	000b0e63          	beqz	s6,800025e6 <wait+0x6c>
					   copyout(p->pagetable, addr, (char*)&pp->xstate, sizeof(pp->xstate)) < 0)
    800025ce:	4691                	li	a3,4
    800025d0:	02c48613          	addi	a2,s1,44
    800025d4:	85da                	mv	a1,s6
    800025d6:	05093503          	ld	a0,80(s2)
    800025da:	fffff097          	auipc	ra,0xfffff
    800025de:	08c080e7          	jalr	140(ra) # 80001666 <copyout>
					if(addr != 0 &&
    800025e2:	04054163          	bltz	a0,80002624 <wait+0xaa>
					freeproc(pp);
    800025e6:	8526                	mv	a0,s1
    800025e8:	fffff097          	auipc	ra,0xfffff
    800025ec:	600080e7          	jalr	1536(ra) # 80001be8 <freeproc>
					release(&pp->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	694080e7          	jalr	1684(ra) # 80000c86 <release>
					release(&wait_lock);
    800025fa:	0000f517          	auipc	a0,0xf
    800025fe:	c3e50513          	addi	a0,a0,-962 # 80011238 <wait_lock>
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	684080e7          	jalr	1668(ra) # 80000c86 <release>
}
    8000260a:	854e                	mv	a0,s3
    8000260c:	60a6                	ld	ra,72(sp)
    8000260e:	6406                	ld	s0,64(sp)
    80002610:	74e2                	ld	s1,56(sp)
    80002612:	7942                	ld	s2,48(sp)
    80002614:	79a2                	ld	s3,40(sp)
    80002616:	7a02                	ld	s4,32(sp)
    80002618:	6ae2                	ld	s5,24(sp)
    8000261a:	6b42                	ld	s6,16(sp)
    8000261c:	6ba2                	ld	s7,8(sp)
    8000261e:	6c02                	ld	s8,0(sp)
    80002620:	6161                	addi	sp,sp,80
    80002622:	8082                	ret
						release(&pp->lock);
    80002624:	8526                	mv	a0,s1
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	660080e7          	jalr	1632(ra) # 80000c86 <release>
						release(&wait_lock);
    8000262e:	0000f517          	auipc	a0,0xf
    80002632:	c0a50513          	addi	a0,a0,-1014 # 80011238 <wait_lock>
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	650080e7          	jalr	1616(ra) # 80000c86 <release>
						return -1;
    8000263e:	59fd                	li	s3,-1
    80002640:	b7e9                	j	8000260a <wait+0x90>
		for(pp = proc; pp < &proc[NPROC]; pp++)
    80002642:	1b048493          	addi	s1,s1,432
    80002646:	03348463          	beq	s1,s3,8000266e <wait+0xf4>
			if(pp->parent == p)
    8000264a:	7c9c                	ld	a5,56(s1)
    8000264c:	ff279be3          	bne	a5,s2,80002642 <wait+0xc8>
				acquire(&pp->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	580080e7          	jalr	1408(ra) # 80000bd2 <acquire>
				if(pp->state == ZOMBIE)
    8000265a:	4c9c                	lw	a5,24(s1)
    8000265c:	f74785e3          	beq	a5,s4,800025c6 <wait+0x4c>
				release(&pp->lock);
    80002660:	8526                	mv	a0,s1
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	624080e7          	jalr	1572(ra) # 80000c86 <release>
				havekids = 1;
    8000266a:	8756                	mv	a4,s5
    8000266c:	bfd9                	j	80002642 <wait+0xc8>
		if(!havekids || killed(p))
    8000266e:	c31d                	beqz	a4,80002694 <wait+0x11a>
    80002670:	854a                	mv	a0,s2
    80002672:	00000097          	auipc	ra,0x0
    80002676:	ed6080e7          	jalr	-298(ra) # 80002548 <killed>
    8000267a:	ed09                	bnez	a0,80002694 <wait+0x11a>
		sleep(p, &wait_lock); // DOC: wait-sleep
    8000267c:	85e2                	mv	a1,s8
    8000267e:	854a                	mv	a0,s2
    80002680:	00000097          	auipc	ra,0x0
    80002684:	c14080e7          	jalr	-1004(ra) # 80002294 <sleep>
		havekids = 0;
    80002688:	875e                	mv	a4,s7
		for(pp = proc; pp < &proc[NPROC]; pp++)
    8000268a:	0000f497          	auipc	s1,0xf
    8000268e:	fc648493          	addi	s1,s1,-58 # 80011650 <proc>
    80002692:	bf65                	j	8000264a <wait+0xd0>
			release(&wait_lock);
    80002694:	0000f517          	auipc	a0,0xf
    80002698:	ba450513          	addi	a0,a0,-1116 # 80011238 <wait_lock>
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	5ea080e7          	jalr	1514(ra) # 80000c86 <release>
			return -1;
    800026a4:	59fd                	li	s3,-1
    800026a6:	b795                	j	8000260a <wait+0x90>

00000000800026a8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void* src, uint64 len)
{
    800026a8:	7179                	addi	sp,sp,-48
    800026aa:	f406                	sd	ra,40(sp)
    800026ac:	f022                	sd	s0,32(sp)
    800026ae:	ec26                	sd	s1,24(sp)
    800026b0:	e84a                	sd	s2,16(sp)
    800026b2:	e44e                	sd	s3,8(sp)
    800026b4:	e052                	sd	s4,0(sp)
    800026b6:	1800                	addi	s0,sp,48
    800026b8:	84aa                	mv	s1,a0
    800026ba:	892e                	mv	s2,a1
    800026bc:	89b2                	mv	s3,a2
    800026be:	8a36                	mv	s4,a3
	struct proc* p = myproc();
    800026c0:	fffff097          	auipc	ra,0xfffff
    800026c4:	30e080e7          	jalr	782(ra) # 800019ce <myproc>
	if(user_dst)
    800026c8:	c08d                	beqz	s1,800026ea <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    800026ca:	86d2                	mv	a3,s4
    800026cc:	864e                	mv	a2,s3
    800026ce:	85ca                	mv	a1,s2
    800026d0:	6928                	ld	a0,80(a0)
    800026d2:	fffff097          	auipc	ra,0xfffff
    800026d6:	f94080e7          	jalr	-108(ra) # 80001666 <copyout>
	else
	{
		memmove((char*)dst, src, len);
		return 0;
	}
}
    800026da:	70a2                	ld	ra,40(sp)
    800026dc:	7402                	ld	s0,32(sp)
    800026de:	64e2                	ld	s1,24(sp)
    800026e0:	6942                	ld	s2,16(sp)
    800026e2:	69a2                	ld	s3,8(sp)
    800026e4:	6a02                	ld	s4,0(sp)
    800026e6:	6145                	addi	sp,sp,48
    800026e8:	8082                	ret
		memmove((char*)dst, src, len);
    800026ea:	000a061b          	sext.w	a2,s4
    800026ee:	85ce                	mv	a1,s3
    800026f0:	854a                	mv	a0,s2
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	638080e7          	jalr	1592(ra) # 80000d2a <memmove>
		return 0;
    800026fa:	8526                	mv	a0,s1
    800026fc:	bff9                	j	800026da <either_copyout+0x32>

00000000800026fe <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void* dst, int user_src, uint64 src, uint64 len)
{
    800026fe:	7179                	addi	sp,sp,-48
    80002700:	f406                	sd	ra,40(sp)
    80002702:	f022                	sd	s0,32(sp)
    80002704:	ec26                	sd	s1,24(sp)
    80002706:	e84a                	sd	s2,16(sp)
    80002708:	e44e                	sd	s3,8(sp)
    8000270a:	e052                	sd	s4,0(sp)
    8000270c:	1800                	addi	s0,sp,48
    8000270e:	892a                	mv	s2,a0
    80002710:	84ae                	mv	s1,a1
    80002712:	89b2                	mv	s3,a2
    80002714:	8a36                	mv	s4,a3
	struct proc* p = myproc();
    80002716:	fffff097          	auipc	ra,0xfffff
    8000271a:	2b8080e7          	jalr	696(ra) # 800019ce <myproc>
	if(user_src)
    8000271e:	c08d                	beqz	s1,80002740 <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    80002720:	86d2                	mv	a3,s4
    80002722:	864e                	mv	a2,s3
    80002724:	85ca                	mv	a1,s2
    80002726:	6928                	ld	a0,80(a0)
    80002728:	fffff097          	auipc	ra,0xfffff
    8000272c:	fca080e7          	jalr	-54(ra) # 800016f2 <copyin>
	else
	{
		memmove(dst, (char*)src, len);
		return 0;
	}
}
    80002730:	70a2                	ld	ra,40(sp)
    80002732:	7402                	ld	s0,32(sp)
    80002734:	64e2                	ld	s1,24(sp)
    80002736:	6942                	ld	s2,16(sp)
    80002738:	69a2                	ld	s3,8(sp)
    8000273a:	6a02                	ld	s4,0(sp)
    8000273c:	6145                	addi	sp,sp,48
    8000273e:	8082                	ret
		memmove(dst, (char*)src, len);
    80002740:	000a061b          	sext.w	a2,s4
    80002744:	85ce                	mv	a1,s3
    80002746:	854a                	mv	a0,s2
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	5e2080e7          	jalr	1506(ra) # 80000d2a <memmove>
		return 0;
    80002750:	8526                	mv	a0,s1
    80002752:	bff9                	j	80002730 <either_copyin+0x32>

0000000080002754 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002754:	715d                	addi	sp,sp,-80
    80002756:	e486                	sd	ra,72(sp)
    80002758:	e0a2                	sd	s0,64(sp)
    8000275a:	fc26                	sd	s1,56(sp)
    8000275c:	f84a                	sd	s2,48(sp)
    8000275e:	f44e                	sd	s3,40(sp)
    80002760:	f052                	sd	s4,32(sp)
    80002762:	ec56                	sd	s5,24(sp)
    80002764:	e85a                	sd	s6,16(sp)
    80002766:	e45e                	sd	s7,8(sp)
    80002768:	0880                	addi	s0,sp,80
							 [RUNNING] "run   ",
							 [ZOMBIE] "zombie"};
	struct proc* p;
	char* state;

	printf("\n");
    8000276a:	00006517          	auipc	a0,0x6
    8000276e:	95e50513          	addi	a0,a0,-1698 # 800080c8 <digits+0x88>
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	e14080e7          	jalr	-492(ra) # 80000586 <printf>
	for(p = proc; p < &proc[NPROC]; p++)
    8000277a:	0000f497          	auipc	s1,0xf
    8000277e:	02e48493          	addi	s1,s1,46 # 800117a8 <proc+0x158>
    80002782:	00016917          	auipc	s2,0x16
    80002786:	c2690913          	addi	s2,s2,-986 # 800183a8 <bcache+0x140>
	{
		if(p->state == UNUSED)
			continue;
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000278a:	4b15                	li	s6,5
			state = states[p->state];
		else
			state = "???";
    8000278c:	00006997          	auipc	s3,0x6
    80002790:	b1c98993          	addi	s3,s3,-1252 # 800082a8 <digits+0x268>
		printf("%d %s %s", p->pid, state, p->name);
    80002794:	00006a97          	auipc	s5,0x6
    80002798:	b1ca8a93          	addi	s5,s5,-1252 # 800082b0 <digits+0x270>
		printf("\n");
    8000279c:	00006a17          	auipc	s4,0x6
    800027a0:	92ca0a13          	addi	s4,s4,-1748 # 800080c8 <digits+0x88>
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027a4:	00006b97          	auipc	s7,0x6
    800027a8:	b4cb8b93          	addi	s7,s7,-1204 # 800082f0 <states.0>
    800027ac:	a00d                	j	800027ce <procdump+0x7a>
		printf("%d %s %s", p->pid, state, p->name);
    800027ae:	ed86a583          	lw	a1,-296(a3)
    800027b2:	8556                	mv	a0,s5
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	dd2080e7          	jalr	-558(ra) # 80000586 <printf>
		printf("\n");
    800027bc:	8552                	mv	a0,s4
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	dc8080e7          	jalr	-568(ra) # 80000586 <printf>
	for(p = proc; p < &proc[NPROC]; p++)
    800027c6:	1b048493          	addi	s1,s1,432
    800027ca:	03248263          	beq	s1,s2,800027ee <procdump+0x9a>
		if(p->state == UNUSED)
    800027ce:	86a6                	mv	a3,s1
    800027d0:	ec04a783          	lw	a5,-320(s1)
    800027d4:	dbed                	beqz	a5,800027c6 <procdump+0x72>
			state = "???";
    800027d6:	864e                	mv	a2,s3
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027d8:	fcfb6be3          	bltu	s6,a5,800027ae <procdump+0x5a>
    800027dc:	02079713          	slli	a4,a5,0x20
    800027e0:	01d75793          	srli	a5,a4,0x1d
    800027e4:	97de                	add	a5,a5,s7
    800027e6:	6390                	ld	a2,0(a5)
    800027e8:	f279                	bnez	a2,800027ae <procdump+0x5a>
			state = "???";
    800027ea:	864e                	mv	a2,s3
    800027ec:	b7c9                	j	800027ae <procdump+0x5a>
	}	
}
    800027ee:	60a6                	ld	ra,72(sp)
    800027f0:	6406                	ld	s0,64(sp)
    800027f2:	74e2                	ld	s1,56(sp)
    800027f4:	7942                	ld	s2,48(sp)
    800027f6:	79a2                	ld	s3,40(sp)
    800027f8:	7a02                	ld	s4,32(sp)
    800027fa:	6ae2                	ld	s5,24(sp)
    800027fc:	6b42                	ld	s6,16(sp)
    800027fe:	6ba2                	ld	s7,8(sp)
    80002800:	6161                	addi	sp,sp,80
    80002802:	8082                	ret

0000000080002804 <waitx>:

// waitx
int waitx(uint64 addr, uint* wtime, uint* rtime)
{
    80002804:	711d                	addi	sp,sp,-96
    80002806:	ec86                	sd	ra,88(sp)
    80002808:	e8a2                	sd	s0,80(sp)
    8000280a:	e4a6                	sd	s1,72(sp)
    8000280c:	e0ca                	sd	s2,64(sp)
    8000280e:	fc4e                	sd	s3,56(sp)
    80002810:	f852                	sd	s4,48(sp)
    80002812:	f456                	sd	s5,40(sp)
    80002814:	f05a                	sd	s6,32(sp)
    80002816:	ec5e                	sd	s7,24(sp)
    80002818:	e862                	sd	s8,16(sp)
    8000281a:	e466                	sd	s9,8(sp)
    8000281c:	e06a                	sd	s10,0(sp)
    8000281e:	1080                	addi	s0,sp,96
    80002820:	8b2a                	mv	s6,a0
    80002822:	8bae                	mv	s7,a1
    80002824:	8c32                	mv	s8,a2
	struct proc* np;
	int havekids, pid;
	struct proc* p = myproc();
    80002826:	fffff097          	auipc	ra,0xfffff
    8000282a:	1a8080e7          	jalr	424(ra) # 800019ce <myproc>
    8000282e:	892a                	mv	s2,a0

	acquire(&wait_lock);
    80002830:	0000f517          	auipc	a0,0xf
    80002834:	a0850513          	addi	a0,a0,-1528 # 80011238 <wait_lock>
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	39a080e7          	jalr	922(ra) # 80000bd2 <acquire>

	for(;;)
	{
		// Scan through table looking for exited children.
		havekids = 0;
    80002840:	4c81                	li	s9,0
			{
				// make sure the child isn't still in exit() or swtch().
				acquire(&np->lock);

				havekids = 1;
				if(np->state == ZOMBIE)
    80002842:	4a15                	li	s4,5
				havekids = 1;
    80002844:	4a85                	li	s5,1
		for(np = proc; np < &proc[NPROC]; np++)
    80002846:	00016997          	auipc	s3,0x16
    8000284a:	a0a98993          	addi	s3,s3,-1526 # 80018250 <tickslock>
			release(&wait_lock);
			return -1;
		}

		// Wait for a child to exit.
		sleep(p, &wait_lock); // DOC: wait-sleep
    8000284e:	0000fd17          	auipc	s10,0xf
    80002852:	9ead0d13          	addi	s10,s10,-1558 # 80011238 <wait_lock>
    80002856:	a8e9                	j	80002930 <waitx+0x12c>
					pid = np->pid;
    80002858:	0304a983          	lw	s3,48(s1)
					*rtime = np->rtime;
    8000285c:	1684a783          	lw	a5,360(s1)
    80002860:	00fc2023          	sw	a5,0(s8)
					*wtime = np->etime - np->ctime - np->rtime;
    80002864:	16c4a703          	lw	a4,364(s1)
    80002868:	9f3d                	addw	a4,a4,a5
    8000286a:	1704a783          	lw	a5,368(s1)
    8000286e:	9f99                	subw	a5,a5,a4
    80002870:	00fba023          	sw	a5,0(s7)
					if(addr != 0 &&
    80002874:	000b0e63          	beqz	s6,80002890 <waitx+0x8c>
					   copyout(p->pagetable, addr, (char*)&np->xstate, sizeof(np->xstate)) < 0)
    80002878:	4691                	li	a3,4
    8000287a:	02c48613          	addi	a2,s1,44
    8000287e:	85da                	mv	a1,s6
    80002880:	05093503          	ld	a0,80(s2)
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	de2080e7          	jalr	-542(ra) # 80001666 <copyout>
					if(addr != 0 &&
    8000288c:	04054363          	bltz	a0,800028d2 <waitx+0xce>
					freeproc(np);
    80002890:	8526                	mv	a0,s1
    80002892:	fffff097          	auipc	ra,0xfffff
    80002896:	356080e7          	jalr	854(ra) # 80001be8 <freeproc>
					release(&np->lock);
    8000289a:	8526                	mv	a0,s1
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	3ea080e7          	jalr	1002(ra) # 80000c86 <release>
					release(&wait_lock);
    800028a4:	0000f517          	auipc	a0,0xf
    800028a8:	99450513          	addi	a0,a0,-1644 # 80011238 <wait_lock>
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	3da080e7          	jalr	986(ra) # 80000c86 <release>
	}
}
    800028b4:	854e                	mv	a0,s3
    800028b6:	60e6                	ld	ra,88(sp)
    800028b8:	6446                	ld	s0,80(sp)
    800028ba:	64a6                	ld	s1,72(sp)
    800028bc:	6906                	ld	s2,64(sp)
    800028be:	79e2                	ld	s3,56(sp)
    800028c0:	7a42                	ld	s4,48(sp)
    800028c2:	7aa2                	ld	s5,40(sp)
    800028c4:	7b02                	ld	s6,32(sp)
    800028c6:	6be2                	ld	s7,24(sp)
    800028c8:	6c42                	ld	s8,16(sp)
    800028ca:	6ca2                	ld	s9,8(sp)
    800028cc:	6d02                	ld	s10,0(sp)
    800028ce:	6125                	addi	sp,sp,96
    800028d0:	8082                	ret
						release(&np->lock);
    800028d2:	8526                	mv	a0,s1
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	3b2080e7          	jalr	946(ra) # 80000c86 <release>
						release(&wait_lock);
    800028dc:	0000f517          	auipc	a0,0xf
    800028e0:	95c50513          	addi	a0,a0,-1700 # 80011238 <wait_lock>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	3a2080e7          	jalr	930(ra) # 80000c86 <release>
						return -1;
    800028ec:	59fd                	li	s3,-1
    800028ee:	b7d9                	j	800028b4 <waitx+0xb0>
		for(np = proc; np < &proc[NPROC]; np++)
    800028f0:	1b048493          	addi	s1,s1,432
    800028f4:	03348463          	beq	s1,s3,8000291c <waitx+0x118>
			if(np->parent == p)
    800028f8:	7c9c                	ld	a5,56(s1)
    800028fa:	ff279be3          	bne	a5,s2,800028f0 <waitx+0xec>
				acquire(&np->lock);
    800028fe:	8526                	mv	a0,s1
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	2d2080e7          	jalr	722(ra) # 80000bd2 <acquire>
				if(np->state == ZOMBIE)
    80002908:	4c9c                	lw	a5,24(s1)
    8000290a:	f54787e3          	beq	a5,s4,80002858 <waitx+0x54>
				release(&np->lock);
    8000290e:	8526                	mv	a0,s1
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	376080e7          	jalr	886(ra) # 80000c86 <release>
				havekids = 1;
    80002918:	8756                	mv	a4,s5
    8000291a:	bfd9                	j	800028f0 <waitx+0xec>
		if(!havekids || p->killed)
    8000291c:	c305                	beqz	a4,8000293c <waitx+0x138>
    8000291e:	02892783          	lw	a5,40(s2)
    80002922:	ef89                	bnez	a5,8000293c <waitx+0x138>
		sleep(p, &wait_lock); // DOC: wait-sleep
    80002924:	85ea                	mv	a1,s10
    80002926:	854a                	mv	a0,s2
    80002928:	00000097          	auipc	ra,0x0
    8000292c:	96c080e7          	jalr	-1684(ra) # 80002294 <sleep>
		havekids = 0;
    80002930:	8766                	mv	a4,s9
		for(np = proc; np < &proc[NPROC]; np++)
    80002932:	0000f497          	auipc	s1,0xf
    80002936:	d1e48493          	addi	s1,s1,-738 # 80011650 <proc>
    8000293a:	bf7d                	j	800028f8 <waitx+0xf4>
			release(&wait_lock);
    8000293c:	0000f517          	auipc	a0,0xf
    80002940:	8fc50513          	addi	a0,a0,-1796 # 80011238 <wait_lock>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	342080e7          	jalr	834(ra) # 80000c86 <release>
			return -1;
    8000294c:	59fd                	li	s3,-1
    8000294e:	b79d                	j	800028b4 <waitx+0xb0>

0000000080002950 <update_time>:

void update_time()
{
    80002950:	7179                	addi	sp,sp,-48
    80002952:	f406                	sd	ra,40(sp)
    80002954:	f022                	sd	s0,32(sp)
    80002956:	ec26                	sd	s1,24(sp)
    80002958:	e84a                	sd	s2,16(sp)
    8000295a:	e44e                	sd	s3,8(sp)
    8000295c:	1800                	addi	s0,sp,48
	struct proc* p;
	for(p = proc; p < &proc[NPROC]; p++)
    8000295e:	0000f497          	auipc	s1,0xf
    80002962:	cf248493          	addi	s1,s1,-782 # 80011650 <proc>
	{
		acquire(&p->lock);
		if(p->state == RUNNING)
    80002966:	4991                	li	s3,4
	for(p = proc; p < &proc[NPROC]; p++)
    80002968:	00016917          	auipc	s2,0x16
    8000296c:	8e890913          	addi	s2,s2,-1816 # 80018250 <tickslock>
    80002970:	a811                	j	80002984 <update_time+0x34>
		{
			p->rtime++;
		}
		release(&p->lock);
    80002972:	8526                	mv	a0,s1
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	312080e7          	jalr	786(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    8000297c:	1b048493          	addi	s1,s1,432
    80002980:	03248063          	beq	s1,s2,800029a0 <update_time+0x50>
		acquire(&p->lock);
    80002984:	8526                	mv	a0,s1
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	24c080e7          	jalr	588(ra) # 80000bd2 <acquire>
		if(p->state == RUNNING)
    8000298e:	4c9c                	lw	a5,24(s1)
    80002990:	ff3791e3          	bne	a5,s3,80002972 <update_time+0x22>
			p->rtime++;
    80002994:	1684a783          	lw	a5,360(s1)
    80002998:	2785                	addiw	a5,a5,1
    8000299a:	16f4a423          	sw	a5,360(s1)
    8000299e:	bfd1                	j	80002972 <update_time+0x22>
	}
}
    800029a0:	70a2                	ld	ra,40(sp)
    800029a2:	7402                	ld	s0,32(sp)
    800029a4:	64e2                	ld	s1,24(sp)
    800029a6:	6942                	ld	s2,16(sp)
    800029a8:	69a2                	ld	s3,8(sp)
    800029aa:	6145                	addi	sp,sp,48
    800029ac:	8082                	ret

00000000800029ae <swtch>:
    800029ae:	00153023          	sd	ra,0(a0)
    800029b2:	00253423          	sd	sp,8(a0)
    800029b6:	e900                	sd	s0,16(a0)
    800029b8:	ed04                	sd	s1,24(a0)
    800029ba:	03253023          	sd	s2,32(a0)
    800029be:	03353423          	sd	s3,40(a0)
    800029c2:	03453823          	sd	s4,48(a0)
    800029c6:	03553c23          	sd	s5,56(a0)
    800029ca:	05653023          	sd	s6,64(a0)
    800029ce:	05753423          	sd	s7,72(a0)
    800029d2:	05853823          	sd	s8,80(a0)
    800029d6:	05953c23          	sd	s9,88(a0)
    800029da:	07a53023          	sd	s10,96(a0)
    800029de:	07b53423          	sd	s11,104(a0)
    800029e2:	0005b083          	ld	ra,0(a1)
    800029e6:	0085b103          	ld	sp,8(a1)
    800029ea:	6980                	ld	s0,16(a1)
    800029ec:	6d84                	ld	s1,24(a1)
    800029ee:	0205b903          	ld	s2,32(a1)
    800029f2:	0285b983          	ld	s3,40(a1)
    800029f6:	0305ba03          	ld	s4,48(a1)
    800029fa:	0385ba83          	ld	s5,56(a1)
    800029fe:	0405bb03          	ld	s6,64(a1)
    80002a02:	0485bb83          	ld	s7,72(a1)
    80002a06:	0505bc03          	ld	s8,80(a1)
    80002a0a:	0585bc83          	ld	s9,88(a1)
    80002a0e:	0605bd03          	ld	s10,96(a1)
    80002a12:	0685bd83          	ld	s11,104(a1)
    80002a16:	8082                	ret

0000000080002a18 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002a18:	1141                	addi	sp,sp,-16
    80002a1a:	e406                	sd	ra,8(sp)
    80002a1c:	e022                	sd	s0,0(sp)
    80002a1e:	0800                	addi	s0,sp,16
	initlock(&tickslock, "time");
    80002a20:	00006597          	auipc	a1,0x6
    80002a24:	90058593          	addi	a1,a1,-1792 # 80008320 <states.0+0x30>
    80002a28:	00016517          	auipc	a0,0x16
    80002a2c:	82850513          	addi	a0,a0,-2008 # 80018250 <tickslock>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	112080e7          	jalr	274(ra) # 80000b42 <initlock>
}
    80002a38:	60a2                	ld	ra,8(sp)
    80002a3a:	6402                	ld	s0,0(sp)
    80002a3c:	0141                	addi	sp,sp,16
    80002a3e:	8082                	ret

0000000080002a40 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002a40:	1141                	addi	sp,sp,-16
    80002a42:	e422                	sd	s0,8(sp)
    80002a44:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a46:	00003797          	auipc	a5,0x3
    80002a4a:	63a78793          	addi	a5,a5,1594 # 80006080 <kernelvec>
    80002a4e:	10579073          	csrw	stvec,a5
	w_stvec((uint64)kernelvec);
}
    80002a52:	6422                	ld	s0,8(sp)
    80002a54:	0141                	addi	sp,sp,16
    80002a56:	8082                	ret

0000000080002a58 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002a58:	1141                	addi	sp,sp,-16
    80002a5a:	e406                	sd	ra,8(sp)
    80002a5c:	e022                	sd	s0,0(sp)
    80002a5e:	0800                	addi	s0,sp,16
	struct proc *p = myproc();
    80002a60:	fffff097          	auipc	ra,0xfffff
    80002a64:	f6e080e7          	jalr	-146(ra) # 800019ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a68:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a6c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a6e:	10079073          	csrw	sstatus,a5
	// kerneltrap() to usertrap(), so turn off interrupts until
	// we're back in user space, where usertrap() is correct.
	intr_off();

	// send syscalls, interrupts, and exceptions to uservec in trampoline.S
	uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a72:	00004697          	auipc	a3,0x4
    80002a76:	58e68693          	addi	a3,a3,1422 # 80007000 <_trampoline>
    80002a7a:	00004717          	auipc	a4,0x4
    80002a7e:	58670713          	addi	a4,a4,1414 # 80007000 <_trampoline>
    80002a82:	8f15                	sub	a4,a4,a3
    80002a84:	040007b7          	lui	a5,0x4000
    80002a88:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002a8a:	07b2                	slli	a5,a5,0xc
    80002a8c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a8e:	10571073          	csrw	stvec,a4
	w_stvec(trampoline_uservec);

	// set up trapframe values that uservec will need when
	// the process next traps into the kernel.
	p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a92:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a94:	18002673          	csrr	a2,satp
    80002a98:	e310                	sd	a2,0(a4)
	p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a9a:	6d30                	ld	a2,88(a0)
    80002a9c:	6138                	ld	a4,64(a0)
    80002a9e:	6585                	lui	a1,0x1
    80002aa0:	972e                	add	a4,a4,a1
    80002aa2:	e618                	sd	a4,8(a2)
	p->trapframe->kernel_trap = (uint64)usertrap;
    80002aa4:	6d38                	ld	a4,88(a0)
    80002aa6:	00000617          	auipc	a2,0x0
    80002aaa:	14260613          	addi	a2,a2,322 # 80002be8 <usertrap>
    80002aae:	eb10                	sd	a2,16(a4)
	p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002ab0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ab2:	8612                	mv	a2,tp
    80002ab4:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab6:	10002773          	csrr	a4,sstatus
	// set up the registers that trampoline.S's sret will use
	// to get to user space.

	// set S Previous Privilege mode to User.
	unsigned long x = r_sstatus();
	x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002aba:	eff77713          	andi	a4,a4,-257
	x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002abe:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ac2:	10071073          	csrw	sstatus,a4
	w_sstatus(x);

	// set S Exception Program Counter to the saved user pc.
	w_sepc(p->trapframe->epc);
    80002ac6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ac8:	6f18                	ld	a4,24(a4)
    80002aca:	14171073          	csrw	sepc,a4

	// tell trampoline.S the user page table to switch to.
	uint64 satp = MAKE_SATP(p->pagetable);
    80002ace:	6928                	ld	a0,80(a0)
    80002ad0:	8131                	srli	a0,a0,0xc

	// jump to userret in trampoline.S at the top of memory, which
	// switches to the user page table, restores user registers,
	// and switches to user mode with sret.
	uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002ad2:	00004717          	auipc	a4,0x4
    80002ad6:	5ca70713          	addi	a4,a4,1482 # 8000709c <userret>
    80002ada:	8f15                	sub	a4,a4,a3
    80002adc:	97ba                	add	a5,a5,a4
	((void (*)(uint64))trampoline_userret)(satp);
    80002ade:	577d                	li	a4,-1
    80002ae0:	177e                	slli	a4,a4,0x3f
    80002ae2:	8d59                	or	a0,a0,a4
    80002ae4:	9782                	jalr	a5
}
    80002ae6:	60a2                	ld	ra,8(sp)
    80002ae8:	6402                	ld	s0,0(sp)
    80002aea:	0141                	addi	sp,sp,16
    80002aec:	8082                	ret

0000000080002aee <clockintr>:
	w_sepc(sepc);
	w_sstatus(sstatus);
}

void clockintr()
{
    80002aee:	1101                	addi	sp,sp,-32
    80002af0:	ec06                	sd	ra,24(sp)
    80002af2:	e822                	sd	s0,16(sp)
    80002af4:	e426                	sd	s1,8(sp)
    80002af6:	e04a                	sd	s2,0(sp)
    80002af8:	1000                	addi	s0,sp,32
	acquire(&tickslock);
    80002afa:	00015917          	auipc	s2,0x15
    80002afe:	75690913          	addi	s2,s2,1878 # 80018250 <tickslock>
    80002b02:	854a                	mv	a0,s2
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	0ce080e7          	jalr	206(ra) # 80000bd2 <acquire>
	ticks++;
    80002b0c:	00006497          	auipc	s1,0x6
    80002b10:	e4448493          	addi	s1,s1,-444 # 80008950 <ticks>
    80002b14:	409c                	lw	a5,0(s1)
    80002b16:	2785                	addiw	a5,a5,1
    80002b18:	c09c                	sw	a5,0(s1)
	update_time();
    80002b1a:	00000097          	auipc	ra,0x0
    80002b1e:	e36080e7          	jalr	-458(ra) # 80002950 <update_time>
	//   // {
	//   //   p->wtime++;
	//   // }
	//   release(&p->lock);
	// }
	wakeup(&ticks);
    80002b22:	8526                	mv	a0,s1
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	7d4080e7          	jalr	2004(ra) # 800022f8 <wakeup>
	release(&tickslock);
    80002b2c:	854a                	mv	a0,s2
    80002b2e:	ffffe097          	auipc	ra,0xffffe
    80002b32:	158080e7          	jalr	344(ra) # 80000c86 <release>
}
    80002b36:	60e2                	ld	ra,24(sp)
    80002b38:	6442                	ld	s0,16(sp)
    80002b3a:	64a2                	ld	s1,8(sp)
    80002b3c:	6902                	ld	s2,0(sp)
    80002b3e:	6105                	addi	sp,sp,32
    80002b40:	8082                	ret

0000000080002b42 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b42:	142027f3          	csrr	a5,scause

		return 2;
	}
	else
	{
		return 0;
    80002b46:	4501                	li	a0,0
	if ((scause & 0x8000000000000000L) &&
    80002b48:	0807df63          	bgez	a5,80002be6 <devintr+0xa4>
{
    80002b4c:	1101                	addi	sp,sp,-32
    80002b4e:	ec06                	sd	ra,24(sp)
    80002b50:	e822                	sd	s0,16(sp)
    80002b52:	e426                	sd	s1,8(sp)
    80002b54:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    80002b56:	0ff7f713          	zext.b	a4,a5
	if ((scause & 0x8000000000000000L) &&
    80002b5a:	46a5                	li	a3,9
    80002b5c:	00d70d63          	beq	a4,a3,80002b76 <devintr+0x34>
	else if (scause == 0x8000000000000001L)
    80002b60:	577d                	li	a4,-1
    80002b62:	177e                	slli	a4,a4,0x3f
    80002b64:	0705                	addi	a4,a4,1
		return 0;
    80002b66:	4501                	li	a0,0
	else if (scause == 0x8000000000000001L)
    80002b68:	04e78e63          	beq	a5,a4,80002bc4 <devintr+0x82>
	}
}
    80002b6c:	60e2                	ld	ra,24(sp)
    80002b6e:	6442                	ld	s0,16(sp)
    80002b70:	64a2                	ld	s1,8(sp)
    80002b72:	6105                	addi	sp,sp,32
    80002b74:	8082                	ret
		int irq = plic_claim();
    80002b76:	00003097          	auipc	ra,0x3
    80002b7a:	612080e7          	jalr	1554(ra) # 80006188 <plic_claim>
    80002b7e:	84aa                	mv	s1,a0
		if (irq == UART0_IRQ)
    80002b80:	47a9                	li	a5,10
    80002b82:	02f50763          	beq	a0,a5,80002bb0 <devintr+0x6e>
		else if (irq == VIRTIO0_IRQ)
    80002b86:	4785                	li	a5,1
    80002b88:	02f50963          	beq	a0,a5,80002bba <devintr+0x78>
		return 1;
    80002b8c:	4505                	li	a0,1
		else if (irq)
    80002b8e:	dcf9                	beqz	s1,80002b6c <devintr+0x2a>
			printf("unexpected interrupt irq=%d\n", irq);
    80002b90:	85a6                	mv	a1,s1
    80002b92:	00005517          	auipc	a0,0x5
    80002b96:	79650513          	addi	a0,a0,1942 # 80008328 <states.0+0x38>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	9ec080e7          	jalr	-1556(ra) # 80000586 <printf>
			plic_complete(irq);
    80002ba2:	8526                	mv	a0,s1
    80002ba4:	00003097          	auipc	ra,0x3
    80002ba8:	608080e7          	jalr	1544(ra) # 800061ac <plic_complete>
		return 1;
    80002bac:	4505                	li	a0,1
    80002bae:	bf7d                	j	80002b6c <devintr+0x2a>
			uartintr();
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	de4080e7          	jalr	-540(ra) # 80000994 <uartintr>
		if (irq)
    80002bb8:	b7ed                	j	80002ba2 <devintr+0x60>
			virtio_disk_intr();
    80002bba:	00004097          	auipc	ra,0x4
    80002bbe:	ab8080e7          	jalr	-1352(ra) # 80006672 <virtio_disk_intr>
		if (irq)
    80002bc2:	b7c5                	j	80002ba2 <devintr+0x60>
		if (cpuid() == 0)
    80002bc4:	fffff097          	auipc	ra,0xfffff
    80002bc8:	dde080e7          	jalr	-546(ra) # 800019a2 <cpuid>
    80002bcc:	c901                	beqz	a0,80002bdc <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bce:	144027f3          	csrr	a5,sip
		w_sip(r_sip() & ~2);
    80002bd2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bd4:	14479073          	csrw	sip,a5
		return 2;
    80002bd8:	4509                	li	a0,2
    80002bda:	bf49                	j	80002b6c <devintr+0x2a>
			clockintr();
    80002bdc:	00000097          	auipc	ra,0x0
    80002be0:	f12080e7          	jalr	-238(ra) # 80002aee <clockintr>
    80002be4:	b7ed                	j	80002bce <devintr+0x8c>
}
    80002be6:	8082                	ret

0000000080002be8 <usertrap>:
{
    80002be8:	7179                	addi	sp,sp,-48
    80002bea:	f406                	sd	ra,40(sp)
    80002bec:	f022                	sd	s0,32(sp)
    80002bee:	ec26                	sd	s1,24(sp)
    80002bf0:	e84a                	sd	s2,16(sp)
    80002bf2:	e44e                	sd	s3,8(sp)
    80002bf4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bf6:	100027f3          	csrr	a5,sstatus
	if((r_sstatus() & SSTATUS_SPP) != 0)
    80002bfa:	1007f793          	andi	a5,a5,256
    80002bfe:	e3b1                	bnez	a5,80002c42 <usertrap+0x5a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c00:	00003797          	auipc	a5,0x3
    80002c04:	48078793          	addi	a5,a5,1152 # 80006080 <kernelvec>
    80002c08:	10579073          	csrw	stvec,a5
	struct proc *p = myproc();
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	dc2080e7          	jalr	-574(ra) # 800019ce <myproc>
    80002c14:	84aa                	mv	s1,a0
	p->trapframe->epc = r_sepc();
    80002c16:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c18:	14102773          	csrr	a4,sepc
    80002c1c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c1e:	14202773          	csrr	a4,scause
	if (r_scause() == 8)
    80002c22:	47a1                	li	a5,8
    80002c24:	02f70763          	beq	a4,a5,80002c52 <usertrap+0x6a>
	else if ((which_dev = devintr()) != 0)
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	f1a080e7          	jalr	-230(ra) # 80002b42 <devintr>
    80002c30:	892a                	mv	s2,a0
    80002c32:	c159                	beqz	a0,80002cb8 <usertrap+0xd0>
	if (killed(p))
    80002c34:	8526                	mv	a0,s1
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	912080e7          	jalr	-1774(ra) # 80002548 <killed>
    80002c3e:	c929                	beqz	a0,80002c90 <usertrap+0xa8>
    80002c40:	a099                	j	80002c86 <usertrap+0x9e>
		panic("usertrap: not from user mode");
    80002c42:	00005517          	auipc	a0,0x5
    80002c46:	70650513          	addi	a0,a0,1798 # 80008348 <states.0+0x58>
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	8f2080e7          	jalr	-1806(ra) # 8000053c <panic>
		if (killed(p))
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	8f6080e7          	jalr	-1802(ra) # 80002548 <killed>
    80002c5a:	e929                	bnez	a0,80002cac <usertrap+0xc4>
		p->trapframe->epc += 4;
    80002c5c:	6cb8                	ld	a4,88(s1)
    80002c5e:	6f1c                	ld	a5,24(a4)
    80002c60:	0791                	addi	a5,a5,4
    80002c62:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c6c:	10079073          	csrw	sstatus,a5
		syscall();
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	34c080e7          	jalr	844(ra) # 80002fbc <syscall>
	if (killed(p))
    80002c78:	8526                	mv	a0,s1
    80002c7a:	00000097          	auipc	ra,0x0
    80002c7e:	8ce080e7          	jalr	-1842(ra) # 80002548 <killed>
    80002c82:	c911                	beqz	a0,80002c96 <usertrap+0xae>
    80002c84:	4901                	li	s2,0
		exit(-1);
    80002c86:	557d                	li	a0,-1
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	740080e7          	jalr	1856(ra) # 800023c8 <exit>
	if (which_dev == 2)
    80002c90:	4789                	li	a5,2
    80002c92:	06f90063          	beq	s2,a5,80002cf2 <usertrap+0x10a>
	usertrapret();
    80002c96:	00000097          	auipc	ra,0x0
    80002c9a:	dc2080e7          	jalr	-574(ra) # 80002a58 <usertrapret>
}
    80002c9e:	70a2                	ld	ra,40(sp)
    80002ca0:	7402                	ld	s0,32(sp)
    80002ca2:	64e2                	ld	s1,24(sp)
    80002ca4:	6942                	ld	s2,16(sp)
    80002ca6:	69a2                	ld	s3,8(sp)
    80002ca8:	6145                	addi	sp,sp,48
    80002caa:	8082                	ret
			exit(-1);
    80002cac:	557d                	li	a0,-1
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	71a080e7          	jalr	1818(ra) # 800023c8 <exit>
    80002cb6:	b75d                	j	80002c5c <usertrap+0x74>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb8:	142025f3          	csrr	a1,scause
		printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cbc:	5890                	lw	a2,48(s1)
    80002cbe:	00005517          	auipc	a0,0x5
    80002cc2:	6aa50513          	addi	a0,a0,1706 # 80008368 <states.0+0x78>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	8c0080e7          	jalr	-1856(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cd2:	14302673          	csrr	a2,stval
		printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	6c250513          	addi	a0,a0,1730 # 80008398 <states.0+0xa8>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	8a8080e7          	jalr	-1880(ra) # 80000586 <printf>
		setkilled(p);
    80002ce6:	8526                	mv	a0,s1
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	834080e7          	jalr	-1996(ra) # 8000251c <setkilled>
    80002cf0:	b761                	j	80002c78 <usertrap+0x90>
		p->now_ticks+=1 ;
    80002cf2:	1844a783          	lw	a5,388(s1)
    80002cf6:	2785                	addiw	a5,a5,1
    80002cf8:	18f4a223          	sw	a5,388(s1)
printf("proc %d , cpu %d , ctime %d\n",myproc()->pid,cpuid(),myproc()->ctime); 
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	cd2080e7          	jalr	-814(ra) # 800019ce <myproc>
    80002d04:	03052983          	lw	s3,48(a0)
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	c9a080e7          	jalr	-870(ra) # 800019a2 <cpuid>
    80002d10:	892a                	mv	s2,a0
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	cbc080e7          	jalr	-836(ra) # 800019ce <myproc>
    80002d1a:	16c52683          	lw	a3,364(a0)
    80002d1e:	864a                	mv	a2,s2
    80002d20:	85ce                	mv	a1,s3
    80002d22:	00005517          	auipc	a0,0x5
    80002d26:	69650513          	addi	a0,a0,1686 # 800083b8 <states.0+0xc8>
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	85c080e7          	jalr	-1956(ra) # 80000586 <printf>
		if( p-> ticks > 0 && p->now_ticks >= p->ticks && !p->is_sigalarm)
    80002d32:	1804a783          	lw	a5,384(s1)
    80002d36:	f6f050e3          	blez	a5,80002c96 <usertrap+0xae>
    80002d3a:	1844a703          	lw	a4,388(s1)
    80002d3e:	f4f74ce3          	blt	a4,a5,80002c96 <usertrap+0xae>
    80002d42:	1744a783          	lw	a5,372(s1)
    80002d46:	fba1                	bnez	a5,80002c96 <usertrap+0xae>
			p->now_ticks = 0;
    80002d48:	1804a223          	sw	zero,388(s1)
			p->is_sigalarm = 1;
    80002d4c:	4785                	li	a5,1
    80002d4e:	16f4aa23          	sw	a5,372(s1)
			*(p->backup_trapframe) =*( p->trapframe);
    80002d52:	6cb4                	ld	a3,88(s1)
    80002d54:	87b6                	mv	a5,a3
    80002d56:	1904b703          	ld	a4,400(s1)
    80002d5a:	12068693          	addi	a3,a3,288
    80002d5e:	0007b803          	ld	a6,0(a5)
    80002d62:	6788                	ld	a0,8(a5)
    80002d64:	6b8c                	ld	a1,16(a5)
    80002d66:	6f90                	ld	a2,24(a5)
    80002d68:	01073023          	sd	a6,0(a4)
    80002d6c:	e708                	sd	a0,8(a4)
    80002d6e:	eb0c                	sd	a1,16(a4)
    80002d70:	ef10                	sd	a2,24(a4)
    80002d72:	02078793          	addi	a5,a5,32
    80002d76:	02070713          	addi	a4,a4,32
    80002d7a:	fed792e3          	bne	a5,a3,80002d5e <usertrap+0x176>
			p->trapframe->epc = p->handler;
    80002d7e:	6cbc                	ld	a5,88(s1)
    80002d80:	1884b703          	ld	a4,392(s1)
    80002d84:	ef98                	sd	a4,24(a5)
    80002d86:	bf01                	j	80002c96 <usertrap+0xae>

0000000080002d88 <kerneltrap>:
{
    80002d88:	7179                	addi	sp,sp,-48
    80002d8a:	f406                	sd	ra,40(sp)
    80002d8c:	f022                	sd	s0,32(sp)
    80002d8e:	ec26                	sd	s1,24(sp)
    80002d90:	e84a                	sd	s2,16(sp)
    80002d92:	e44e                	sd	s3,8(sp)
    80002d94:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d96:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d9a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d9e:	142029f3          	csrr	s3,scause
	if ((sstatus & SSTATUS_SPP) == 0)
    80002da2:	1004f793          	andi	a5,s1,256
    80002da6:	c78d                	beqz	a5,80002dd0 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002da8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002dac:	8b89                	andi	a5,a5,2
	if (intr_get() != 0)
    80002dae:	eb8d                	bnez	a5,80002de0 <kerneltrap+0x58>
	if ((which_dev = devintr()) == 0)
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	d92080e7          	jalr	-622(ra) # 80002b42 <devintr>
    80002db8:	cd05                	beqz	a0,80002df0 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dba:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dbe:	10049073          	csrw	sstatus,s1
}
    80002dc2:	70a2                	ld	ra,40(sp)
    80002dc4:	7402                	ld	s0,32(sp)
    80002dc6:	64e2                	ld	s1,24(sp)
    80002dc8:	6942                	ld	s2,16(sp)
    80002dca:	69a2                	ld	s3,8(sp)
    80002dcc:	6145                	addi	sp,sp,48
    80002dce:	8082                	ret
		panic("kerneltrap: not from supervisor mode");
    80002dd0:	00005517          	auipc	a0,0x5
    80002dd4:	60850513          	addi	a0,a0,1544 # 800083d8 <states.0+0xe8>
    80002dd8:	ffffd097          	auipc	ra,0xffffd
    80002ddc:	764080e7          	jalr	1892(ra) # 8000053c <panic>
		panic("kerneltrap: interrupts enabled");
    80002de0:	00005517          	auipc	a0,0x5
    80002de4:	62050513          	addi	a0,a0,1568 # 80008400 <states.0+0x110>
    80002de8:	ffffd097          	auipc	ra,0xffffd
    80002dec:	754080e7          	jalr	1876(ra) # 8000053c <panic>
		printf("scause %p\n", scause);
    80002df0:	85ce                	mv	a1,s3
    80002df2:	00005517          	auipc	a0,0x5
    80002df6:	62e50513          	addi	a0,a0,1582 # 80008420 <states.0+0x130>
    80002dfa:	ffffd097          	auipc	ra,0xffffd
    80002dfe:	78c080e7          	jalr	1932(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e02:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e06:	14302673          	csrr	a2,stval
		printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e0a:	00005517          	auipc	a0,0x5
    80002e0e:	62650513          	addi	a0,a0,1574 # 80008430 <states.0+0x140>
    80002e12:	ffffd097          	auipc	ra,0xffffd
    80002e16:	774080e7          	jalr	1908(ra) # 80000586 <printf>
		panic("kerneltrap");
    80002e1a:	00005517          	auipc	a0,0x5
    80002e1e:	62e50513          	addi	a0,a0,1582 # 80008448 <states.0+0x158>
    80002e22:	ffffd097          	auipc	ra,0xffffd
    80002e26:	71a080e7          	jalr	1818(ra) # 8000053c <panic>

0000000080002e2a <sys_getreadcount>:
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}
uint64 sys_getreadcount(void)
{
    80002e2a:	1141                	addi	sp,sp,-16
    80002e2c:	e422                	sd	s0,8(sp)
    80002e2e:	0800                	addi	s0,sp,16
  return READCOUNT; 
}
    80002e30:	00006517          	auipc	a0,0x6
    80002e34:	b2853503          	ld	a0,-1240(a0) # 80008958 <READCOUNT>
    80002e38:	6422                	ld	s0,8(sp)
    80002e3a:	0141                	addi	sp,sp,16
    80002e3c:	8082                	ret

0000000080002e3e <argraw>:
{
    80002e3e:	1101                	addi	sp,sp,-32
    80002e40:	ec06                	sd	ra,24(sp)
    80002e42:	e822                	sd	s0,16(sp)
    80002e44:	e426                	sd	s1,8(sp)
    80002e46:	1000                	addi	s0,sp,32
    80002e48:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	b84080e7          	jalr	-1148(ra) # 800019ce <myproc>
  switch (n) {
    80002e52:	4795                	li	a5,5
    80002e54:	0497e163          	bltu	a5,s1,80002e96 <argraw+0x58>
    80002e58:	048a                	slli	s1,s1,0x2
    80002e5a:	00005717          	auipc	a4,0x5
    80002e5e:	62670713          	addi	a4,a4,1574 # 80008480 <states.0+0x190>
    80002e62:	94ba                	add	s1,s1,a4
    80002e64:	409c                	lw	a5,0(s1)
    80002e66:	97ba                	add	a5,a5,a4
    80002e68:	8782                	jr	a5
    return p->trapframe->a0;
    80002e6a:	6d3c                	ld	a5,88(a0)
    80002e6c:	7ba8                	ld	a0,112(a5)
}
    80002e6e:	60e2                	ld	ra,24(sp)
    80002e70:	6442                	ld	s0,16(sp)
    80002e72:	64a2                	ld	s1,8(sp)
    80002e74:	6105                	addi	sp,sp,32
    80002e76:	8082                	ret
    return p->trapframe->a1;
    80002e78:	6d3c                	ld	a5,88(a0)
    80002e7a:	7fa8                	ld	a0,120(a5)
    80002e7c:	bfcd                	j	80002e6e <argraw+0x30>
    return p->trapframe->a2;
    80002e7e:	6d3c                	ld	a5,88(a0)
    80002e80:	63c8                	ld	a0,128(a5)
    80002e82:	b7f5                	j	80002e6e <argraw+0x30>
    return p->trapframe->a3;
    80002e84:	6d3c                	ld	a5,88(a0)
    80002e86:	67c8                	ld	a0,136(a5)
    80002e88:	b7dd                	j	80002e6e <argraw+0x30>
    return p->trapframe->a4;
    80002e8a:	6d3c                	ld	a5,88(a0)
    80002e8c:	6bc8                	ld	a0,144(a5)
    80002e8e:	b7c5                	j	80002e6e <argraw+0x30>
    return p->trapframe->a5;
    80002e90:	6d3c                	ld	a5,88(a0)
    80002e92:	6fc8                	ld	a0,152(a5)
    80002e94:	bfe9                	j	80002e6e <argraw+0x30>
  panic("argraw");
    80002e96:	00005517          	auipc	a0,0x5
    80002e9a:	5c250513          	addi	a0,a0,1474 # 80008458 <states.0+0x168>
    80002e9e:	ffffd097          	auipc	ra,0xffffd
    80002ea2:	69e080e7          	jalr	1694(ra) # 8000053c <panic>

0000000080002ea6 <fetchaddr>:
{
    80002ea6:	1101                	addi	sp,sp,-32
    80002ea8:	ec06                	sd	ra,24(sp)
    80002eaa:	e822                	sd	s0,16(sp)
    80002eac:	e426                	sd	s1,8(sp)
    80002eae:	e04a                	sd	s2,0(sp)
    80002eb0:	1000                	addi	s0,sp,32
    80002eb2:	84aa                	mv	s1,a0
    80002eb4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	b18080e7          	jalr	-1256(ra) # 800019ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ebe:	653c                	ld	a5,72(a0)
    80002ec0:	02f4f863          	bgeu	s1,a5,80002ef0 <fetchaddr+0x4a>
    80002ec4:	00848713          	addi	a4,s1,8
    80002ec8:	02e7e663          	bltu	a5,a4,80002ef4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ecc:	46a1                	li	a3,8
    80002ece:	8626                	mv	a2,s1
    80002ed0:	85ca                	mv	a1,s2
    80002ed2:	6928                	ld	a0,80(a0)
    80002ed4:	fffff097          	auipc	ra,0xfffff
    80002ed8:	81e080e7          	jalr	-2018(ra) # 800016f2 <copyin>
    80002edc:	00a03533          	snez	a0,a0
    80002ee0:	40a00533          	neg	a0,a0
}
    80002ee4:	60e2                	ld	ra,24(sp)
    80002ee6:	6442                	ld	s0,16(sp)
    80002ee8:	64a2                	ld	s1,8(sp)
    80002eea:	6902                	ld	s2,0(sp)
    80002eec:	6105                	addi	sp,sp,32
    80002eee:	8082                	ret
    return -1;
    80002ef0:	557d                	li	a0,-1
    80002ef2:	bfcd                	j	80002ee4 <fetchaddr+0x3e>
    80002ef4:	557d                	li	a0,-1
    80002ef6:	b7fd                	j	80002ee4 <fetchaddr+0x3e>

0000000080002ef8 <fetchstr>:
{
    80002ef8:	7179                	addi	sp,sp,-48
    80002efa:	f406                	sd	ra,40(sp)
    80002efc:	f022                	sd	s0,32(sp)
    80002efe:	ec26                	sd	s1,24(sp)
    80002f00:	e84a                	sd	s2,16(sp)
    80002f02:	e44e                	sd	s3,8(sp)
    80002f04:	1800                	addi	s0,sp,48
    80002f06:	892a                	mv	s2,a0
    80002f08:	84ae                	mv	s1,a1
    80002f0a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f0c:	fffff097          	auipc	ra,0xfffff
    80002f10:	ac2080e7          	jalr	-1342(ra) # 800019ce <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002f14:	86ce                	mv	a3,s3
    80002f16:	864a                	mv	a2,s2
    80002f18:	85a6                	mv	a1,s1
    80002f1a:	6928                	ld	a0,80(a0)
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	864080e7          	jalr	-1948(ra) # 80001780 <copyinstr>
    80002f24:	00054e63          	bltz	a0,80002f40 <fetchstr+0x48>
  return strlen(buf);
    80002f28:	8526                	mv	a0,s1
    80002f2a:	ffffe097          	auipc	ra,0xffffe
    80002f2e:	f1e080e7          	jalr	-226(ra) # 80000e48 <strlen>
}
    80002f32:	70a2                	ld	ra,40(sp)
    80002f34:	7402                	ld	s0,32(sp)
    80002f36:	64e2                	ld	s1,24(sp)
    80002f38:	6942                	ld	s2,16(sp)
    80002f3a:	69a2                	ld	s3,8(sp)
    80002f3c:	6145                	addi	sp,sp,48
    80002f3e:	8082                	ret
    return -1;
    80002f40:	557d                	li	a0,-1
    80002f42:	bfc5                	j	80002f32 <fetchstr+0x3a>

0000000080002f44 <argint>:
{
    80002f44:	1101                	addi	sp,sp,-32
    80002f46:	ec06                	sd	ra,24(sp)
    80002f48:	e822                	sd	s0,16(sp)
    80002f4a:	e426                	sd	s1,8(sp)
    80002f4c:	1000                	addi	s0,sp,32
    80002f4e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	eee080e7          	jalr	-274(ra) # 80002e3e <argraw>
    80002f58:	c088                	sw	a0,0(s1)
}
    80002f5a:	60e2                	ld	ra,24(sp)
    80002f5c:	6442                	ld	s0,16(sp)
    80002f5e:	64a2                	ld	s1,8(sp)
    80002f60:	6105                	addi	sp,sp,32
    80002f62:	8082                	ret

0000000080002f64 <argaddr>:
{
    80002f64:	1101                	addi	sp,sp,-32
    80002f66:	ec06                	sd	ra,24(sp)
    80002f68:	e822                	sd	s0,16(sp)
    80002f6a:	e426                	sd	s1,8(sp)
    80002f6c:	1000                	addi	s0,sp,32
    80002f6e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	ece080e7          	jalr	-306(ra) # 80002e3e <argraw>
    80002f78:	e088                	sd	a0,0(s1)
}
    80002f7a:	60e2                	ld	ra,24(sp)
    80002f7c:	6442                	ld	s0,16(sp)
    80002f7e:	64a2                	ld	s1,8(sp)
    80002f80:	6105                	addi	sp,sp,32
    80002f82:	8082                	ret

0000000080002f84 <argstr>:
{
    80002f84:	7179                	addi	sp,sp,-48
    80002f86:	f406                	sd	ra,40(sp)
    80002f88:	f022                	sd	s0,32(sp)
    80002f8a:	ec26                	sd	s1,24(sp)
    80002f8c:	e84a                	sd	s2,16(sp)
    80002f8e:	1800                	addi	s0,sp,48
    80002f90:	84ae                	mv	s1,a1
    80002f92:	8932                	mv	s2,a2
  argaddr(n, &addr);
    80002f94:	fd840593          	addi	a1,s0,-40
    80002f98:	00000097          	auipc	ra,0x0
    80002f9c:	fcc080e7          	jalr	-52(ra) # 80002f64 <argaddr>
  return fetchstr(addr, buf, max);
    80002fa0:	864a                	mv	a2,s2
    80002fa2:	85a6                	mv	a1,s1
    80002fa4:	fd843503          	ld	a0,-40(s0)
    80002fa8:	00000097          	auipc	ra,0x0
    80002fac:	f50080e7          	jalr	-176(ra) # 80002ef8 <fetchstr>
}
    80002fb0:	70a2                	ld	ra,40(sp)
    80002fb2:	7402                	ld	s0,32(sp)
    80002fb4:	64e2                	ld	s1,24(sp)
    80002fb6:	6942                	ld	s2,16(sp)
    80002fb8:	6145                	addi	sp,sp,48
    80002fba:	8082                	ret

0000000080002fbc <syscall>:

};

void
syscall(void)
{
    80002fbc:	1101                	addi	sp,sp,-32
    80002fbe:	ec06                	sd	ra,24(sp)
    80002fc0:	e822                	sd	s0,16(sp)
    80002fc2:	e426                	sd	s1,8(sp)
    80002fc4:	e04a                	sd	s2,0(sp)
    80002fc6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fc8:	fffff097          	auipc	ra,0xfffff
    80002fcc:	a06080e7          	jalr	-1530(ra) # 800019ce <myproc>
    80002fd0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fd2:	05853903          	ld	s2,88(a0)
    80002fd6:	0a893783          	ld	a5,168(s2)
    80002fda:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fde:	37fd                	addiw	a5,a5,-1
    80002fe0:	4761                	li	a4,24
    80002fe2:	00f76f63          	bltu	a4,a5,80003000 <syscall+0x44>
    80002fe6:	00369713          	slli	a4,a3,0x3
    80002fea:	00005797          	auipc	a5,0x5
    80002fee:	4ae78793          	addi	a5,a5,1198 # 80008498 <syscalls>
    80002ff2:	97ba                	add	a5,a5,a4
    80002ff4:	639c                	ld	a5,0(a5)
    80002ff6:	c789                	beqz	a5,80003000 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002ff8:	9782                	jalr	a5
    80002ffa:	06a93823          	sd	a0,112(s2)
    80002ffe:	a839                	j	8000301c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003000:	15848613          	addi	a2,s1,344
    80003004:	588c                	lw	a1,48(s1)
    80003006:	00005517          	auipc	a0,0x5
    8000300a:	45a50513          	addi	a0,a0,1114 # 80008460 <states.0+0x170>
    8000300e:	ffffd097          	auipc	ra,0xffffd
    80003012:	578080e7          	jalr	1400(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003016:	6cbc                	ld	a5,88(s1)
    80003018:	577d                	li	a4,-1
    8000301a:	fbb8                	sd	a4,112(a5)
  }
}
    8000301c:	60e2                	ld	ra,24(sp)
    8000301e:	6442                	ld	s0,16(sp)
    80003020:	64a2                	ld	s1,8(sp)
    80003022:	6902                	ld	s2,0(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret

0000000080003028 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003030:	fec40593          	addi	a1,s0,-20
    80003034:	4501                	li	a0,0
    80003036:	00000097          	auipc	ra,0x0
    8000303a:	f0e080e7          	jalr	-242(ra) # 80002f44 <argint>
  exit(n);
    8000303e:	fec42503          	lw	a0,-20(s0)
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	386080e7          	jalr	902(ra) # 800023c8 <exit>
  return 0; // not reached
}
    8000304a:	4501                	li	a0,0
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	6105                	addi	sp,sp,32
    80003052:	8082                	ret

0000000080003054 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003054:	1141                	addi	sp,sp,-16
    80003056:	e406                	sd	ra,8(sp)
    80003058:	e022                	sd	s0,0(sp)
    8000305a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	972080e7          	jalr	-1678(ra) # 800019ce <myproc>
}
    80003064:	5908                	lw	a0,48(a0)
    80003066:	60a2                	ld	ra,8(sp)
    80003068:	6402                	ld	s0,0(sp)
    8000306a:	0141                	addi	sp,sp,16
    8000306c:	8082                	ret

000000008000306e <sys_fork>:

uint64
sys_fork(void)
{
    8000306e:	1141                	addi	sp,sp,-16
    80003070:	e406                	sd	ra,8(sp)
    80003072:	e022                	sd	s0,0(sp)
    80003074:	0800                	addi	s0,sp,16
  return fork();
    80003076:	fffff097          	auipc	ra,0xfffff
    8000307a:	dfa080e7          	jalr	-518(ra) # 80001e70 <fork>
}
    8000307e:	60a2                	ld	ra,8(sp)
    80003080:	6402                	ld	s0,0(sp)
    80003082:	0141                	addi	sp,sp,16
    80003084:	8082                	ret

0000000080003086 <sys_wait>:

uint64
sys_wait(void)
{
    80003086:	1101                	addi	sp,sp,-32
    80003088:	ec06                	sd	ra,24(sp)
    8000308a:	e822                	sd	s0,16(sp)
    8000308c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000308e:	fe840593          	addi	a1,s0,-24
    80003092:	4501                	li	a0,0
    80003094:	00000097          	auipc	ra,0x0
    80003098:	ed0080e7          	jalr	-304(ra) # 80002f64 <argaddr>
  return wait(p);
    8000309c:	fe843503          	ld	a0,-24(s0)
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	4da080e7          	jalr	1242(ra) # 8000257a <wait>
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	6105                	addi	sp,sp,32
    800030ae:	8082                	ret

00000000800030b0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030b0:	7179                	addi	sp,sp,-48
    800030b2:	f406                	sd	ra,40(sp)
    800030b4:	f022                	sd	s0,32(sp)
    800030b6:	ec26                	sd	s1,24(sp)
    800030b8:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800030ba:	fdc40593          	addi	a1,s0,-36
    800030be:	4501                	li	a0,0
    800030c0:	00000097          	auipc	ra,0x0
    800030c4:	e84080e7          	jalr	-380(ra) # 80002f44 <argint>
  addr = myproc()->sz;
    800030c8:	fffff097          	auipc	ra,0xfffff
    800030cc:	906080e7          	jalr	-1786(ra) # 800019ce <myproc>
    800030d0:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800030d2:	fdc42503          	lw	a0,-36(s0)
    800030d6:	fffff097          	auipc	ra,0xfffff
    800030da:	d3e080e7          	jalr	-706(ra) # 80001e14 <growproc>
    800030de:	00054863          	bltz	a0,800030ee <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030e2:	8526                	mv	a0,s1
    800030e4:	70a2                	ld	ra,40(sp)
    800030e6:	7402                	ld	s0,32(sp)
    800030e8:	64e2                	ld	s1,24(sp)
    800030ea:	6145                	addi	sp,sp,48
    800030ec:	8082                	ret
    return -1;
    800030ee:	54fd                	li	s1,-1
    800030f0:	bfcd                	j	800030e2 <sys_sbrk+0x32>

00000000800030f2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030f2:	7139                	addi	sp,sp,-64
    800030f4:	fc06                	sd	ra,56(sp)
    800030f6:	f822                	sd	s0,48(sp)
    800030f8:	f426                	sd	s1,40(sp)
    800030fa:	f04a                	sd	s2,32(sp)
    800030fc:	ec4e                	sd	s3,24(sp)
    800030fe:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003100:	fcc40593          	addi	a1,s0,-52
    80003104:	4501                	li	a0,0
    80003106:	00000097          	auipc	ra,0x0
    8000310a:	e3e080e7          	jalr	-450(ra) # 80002f44 <argint>
  acquire(&tickslock);
    8000310e:	00015517          	auipc	a0,0x15
    80003112:	14250513          	addi	a0,a0,322 # 80018250 <tickslock>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	abc080e7          	jalr	-1348(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    8000311e:	00006917          	auipc	s2,0x6
    80003122:	83292903          	lw	s2,-1998(s2) # 80008950 <ticks>
  while (ticks - ticks0 < n)
    80003126:	fcc42783          	lw	a5,-52(s0)
    8000312a:	cf9d                	beqz	a5,80003168 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000312c:	00015997          	auipc	s3,0x15
    80003130:	12498993          	addi	s3,s3,292 # 80018250 <tickslock>
    80003134:	00006497          	auipc	s1,0x6
    80003138:	81c48493          	addi	s1,s1,-2020 # 80008950 <ticks>
    if (killed(myproc()))
    8000313c:	fffff097          	auipc	ra,0xfffff
    80003140:	892080e7          	jalr	-1902(ra) # 800019ce <myproc>
    80003144:	fffff097          	auipc	ra,0xfffff
    80003148:	404080e7          	jalr	1028(ra) # 80002548 <killed>
    8000314c:	ed15                	bnez	a0,80003188 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000314e:	85ce                	mv	a1,s3
    80003150:	8526                	mv	a0,s1
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	142080e7          	jalr	322(ra) # 80002294 <sleep>
  while (ticks - ticks0 < n)
    8000315a:	409c                	lw	a5,0(s1)
    8000315c:	412787bb          	subw	a5,a5,s2
    80003160:	fcc42703          	lw	a4,-52(s0)
    80003164:	fce7ece3          	bltu	a5,a4,8000313c <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003168:	00015517          	auipc	a0,0x15
    8000316c:	0e850513          	addi	a0,a0,232 # 80018250 <tickslock>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	b16080e7          	jalr	-1258(ra) # 80000c86 <release>
  return 0;
    80003178:	4501                	li	a0,0
}
    8000317a:	70e2                	ld	ra,56(sp)
    8000317c:	7442                	ld	s0,48(sp)
    8000317e:	74a2                	ld	s1,40(sp)
    80003180:	7902                	ld	s2,32(sp)
    80003182:	69e2                	ld	s3,24(sp)
    80003184:	6121                	addi	sp,sp,64
    80003186:	8082                	ret
      release(&tickslock);
    80003188:	00015517          	auipc	a0,0x15
    8000318c:	0c850513          	addi	a0,a0,200 # 80018250 <tickslock>
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	af6080e7          	jalr	-1290(ra) # 80000c86 <release>
      return -1;
    80003198:	557d                	li	a0,-1
    8000319a:	b7c5                	j	8000317a <sys_sleep+0x88>

000000008000319c <sys_kill>:

uint64
sys_kill(void)
{
    8000319c:	1101                	addi	sp,sp,-32
    8000319e:	ec06                	sd	ra,24(sp)
    800031a0:	e822                	sd	s0,16(sp)
    800031a2:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800031a4:	fec40593          	addi	a1,s0,-20
    800031a8:	4501                	li	a0,0
    800031aa:	00000097          	auipc	ra,0x0
    800031ae:	d9a080e7          	jalr	-614(ra) # 80002f44 <argint>
  return kill(pid);
    800031b2:	fec42503          	lw	a0,-20(s0)
    800031b6:	fffff097          	auipc	ra,0xfffff
    800031ba:	2f4080e7          	jalr	756(ra) # 800024aa <kill>
}
    800031be:	60e2                	ld	ra,24(sp)
    800031c0:	6442                	ld	s0,16(sp)
    800031c2:	6105                	addi	sp,sp,32
    800031c4:	8082                	ret

00000000800031c6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	e426                	sd	s1,8(sp)
    800031ce:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031d0:	00015517          	auipc	a0,0x15
    800031d4:	08050513          	addi	a0,a0,128 # 80018250 <tickslock>
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	9fa080e7          	jalr	-1542(ra) # 80000bd2 <acquire>
  xticks = ticks;
    800031e0:	00005497          	auipc	s1,0x5
    800031e4:	7704a483          	lw	s1,1904(s1) # 80008950 <ticks>
  release(&tickslock);
    800031e8:	00015517          	auipc	a0,0x15
    800031ec:	06850513          	addi	a0,a0,104 # 80018250 <tickslock>
    800031f0:	ffffe097          	auipc	ra,0xffffe
    800031f4:	a96080e7          	jalr	-1386(ra) # 80000c86 <release>
  return xticks;
}
    800031f8:	02049513          	slli	a0,s1,0x20
    800031fc:	9101                	srli	a0,a0,0x20
    800031fe:	60e2                	ld	ra,24(sp)
    80003200:	6442                	ld	s0,16(sp)
    80003202:	64a2                	ld	s1,8(sp)
    80003204:	6105                	addi	sp,sp,32
    80003206:	8082                	ret

0000000080003208 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003208:	7139                	addi	sp,sp,-64
    8000320a:	fc06                	sd	ra,56(sp)
    8000320c:	f822                	sd	s0,48(sp)
    8000320e:	f426                	sd	s1,40(sp)
    80003210:	f04a                	sd	s2,32(sp)
    80003212:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003214:	fd840593          	addi	a1,s0,-40
    80003218:	4501                	li	a0,0
    8000321a:	00000097          	auipc	ra,0x0
    8000321e:	d4a080e7          	jalr	-694(ra) # 80002f64 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003222:	fd040593          	addi	a1,s0,-48
    80003226:	4505                	li	a0,1
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	d3c080e7          	jalr	-708(ra) # 80002f64 <argaddr>
  argaddr(2, &addr2);
    80003230:	fc840593          	addi	a1,s0,-56
    80003234:	4509                	li	a0,2
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	d2e080e7          	jalr	-722(ra) # 80002f64 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000323e:	fc040613          	addi	a2,s0,-64
    80003242:	fc440593          	addi	a1,s0,-60
    80003246:	fd843503          	ld	a0,-40(s0)
    8000324a:	fffff097          	auipc	ra,0xfffff
    8000324e:	5ba080e7          	jalr	1466(ra) # 80002804 <waitx>
    80003252:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003254:	ffffe097          	auipc	ra,0xffffe
    80003258:	77a080e7          	jalr	1914(ra) # 800019ce <myproc>
    8000325c:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000325e:	4691                	li	a3,4
    80003260:	fc440613          	addi	a2,s0,-60
    80003264:	fd043583          	ld	a1,-48(s0)
    80003268:	6928                	ld	a0,80(a0)
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	3fc080e7          	jalr	1020(ra) # 80001666 <copyout>
    return -1;
    80003272:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003274:	00054f63          	bltz	a0,80003292 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003278:	4691                	li	a3,4
    8000327a:	fc040613          	addi	a2,s0,-64
    8000327e:	fc843583          	ld	a1,-56(s0)
    80003282:	68a8                	ld	a0,80(s1)
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	3e2080e7          	jalr	994(ra) # 80001666 <copyout>
    8000328c:	00054a63          	bltz	a0,800032a0 <sys_waitx+0x98>
    return -1;
  return ret;
    80003290:	87ca                	mv	a5,s2
}
    80003292:	853e                	mv	a0,a5
    80003294:	70e2                	ld	ra,56(sp)
    80003296:	7442                	ld	s0,48(sp)
    80003298:	74a2                	ld	s1,40(sp)
    8000329a:	7902                	ld	s2,32(sp)
    8000329c:	6121                	addi	sp,sp,64
    8000329e:	8082                	ret
    return -1;
    800032a0:	57fd                	li	a5,-1
    800032a2:	bfc5                	j	80003292 <sys_waitx+0x8a>

00000000800032a4 <restore>:
void restore(){
    800032a4:	1141                	addi	sp,sp,-16
    800032a6:	e406                	sd	ra,8(sp)
    800032a8:	e022                	sd	s0,0(sp)
    800032aa:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800032ac:	ffffe097          	auipc	ra,0xffffe
    800032b0:	722080e7          	jalr	1826(ra) # 800019ce <myproc>
  p->backup_trapframe->kernel_hartid = p->trapframe->kernel_hartid;
    800032b4:	19053783          	ld	a5,400(a0)
    800032b8:	6d38                	ld	a4,88(a0)
    800032ba:	7318                	ld	a4,32(a4)
    800032bc:	f398                	sd	a4,32(a5)
  p->backup_trapframe->kernel_satp = p->trapframe->kernel_satp;
    800032be:	19053783          	ld	a5,400(a0)
    800032c2:	6d38                	ld	a4,88(a0)
    800032c4:	6318                	ld	a4,0(a4)
    800032c6:	e398                	sd	a4,0(a5)
  p->backup_trapframe->kernel_sp = p->trapframe->kernel_sp;
    800032c8:	19053783          	ld	a5,400(a0)
    800032cc:	6d38                	ld	a4,88(a0)
    800032ce:	6718                	ld	a4,8(a4)
    800032d0:	e798                	sd	a4,8(a5)
  p->backup_trapframe->kernel_trap = p->trapframe->kernel_trap;
    800032d2:	19053783          	ld	a5,400(a0)
    800032d6:	6d38                	ld	a4,88(a0)
    800032d8:	6b18                	ld	a4,16(a4)
    800032da:	eb98                	sd	a4,16(a5)
  *(p->trapframe) = *(p->backup_trapframe);
    800032dc:	19053683          	ld	a3,400(a0)
    800032e0:	87b6                	mv	a5,a3
    800032e2:	6d38                	ld	a4,88(a0)
    800032e4:	12068693          	addi	a3,a3,288
    800032e8:	0007b803          	ld	a6,0(a5)
    800032ec:	6788                	ld	a0,8(a5)
    800032ee:	6b8c                	ld	a1,16(a5)
    800032f0:	6f90                	ld	a2,24(a5)
    800032f2:	01073023          	sd	a6,0(a4)
    800032f6:	e708                	sd	a0,8(a4)
    800032f8:	eb0c                	sd	a1,16(a4)
    800032fa:	ef10                	sd	a2,24(a4)
    800032fc:	02078793          	addi	a5,a5,32
    80003300:	02070713          	addi	a4,a4,32
    80003304:	fed792e3          	bne	a5,a3,800032e8 <restore+0x44>
} 
    80003308:	60a2                	ld	ra,8(sp)
    8000330a:	6402                	ld	s0,0(sp)
    8000330c:	0141                	addi	sp,sp,16
    8000330e:	8082                	ret

0000000080003310 <sys_sigreturn>:
uint64 sys_sigreturn(void){
    80003310:	1141                	addi	sp,sp,-16
    80003312:	e406                	sd	ra,8(sp)
    80003314:	e022                	sd	s0,0(sp)
    80003316:	0800                	addi	s0,sp,16
  restore();
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	f8c080e7          	jalr	-116(ra) # 800032a4 <restore>
  myproc()->is_sigalarm = 0;
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	6ae080e7          	jalr	1710(ra) # 800019ce <myproc>
    80003328:	16052a23          	sw	zero,372(a0)
  return myproc()->trapframe->a0;
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	6a2080e7          	jalr	1698(ra) # 800019ce <myproc>
    80003334:	6d3c                	ld	a5,88(a0)
    80003336:	7ba8                	ld	a0,112(a5)
    80003338:	60a2                	ld	ra,8(sp)
    8000333a:	6402                	ld	s0,0(sp)
    8000333c:	0141                	addi	sp,sp,16
    8000333e:	8082                	ret

0000000080003340 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003340:	7179                	addi	sp,sp,-48
    80003342:	f406                	sd	ra,40(sp)
    80003344:	f022                	sd	s0,32(sp)
    80003346:	ec26                	sd	s1,24(sp)
    80003348:	e84a                	sd	s2,16(sp)
    8000334a:	e44e                	sd	s3,8(sp)
    8000334c:	e052                	sd	s4,0(sp)
    8000334e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003350:	00005597          	auipc	a1,0x5
    80003354:	21858593          	addi	a1,a1,536 # 80008568 <syscalls+0xd0>
    80003358:	00015517          	auipc	a0,0x15
    8000335c:	f1050513          	addi	a0,a0,-240 # 80018268 <bcache>
    80003360:	ffffd097          	auipc	ra,0xffffd
    80003364:	7e2080e7          	jalr	2018(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003368:	0001d797          	auipc	a5,0x1d
    8000336c:	f0078793          	addi	a5,a5,-256 # 80020268 <bcache+0x8000>
    80003370:	0001d717          	auipc	a4,0x1d
    80003374:	16070713          	addi	a4,a4,352 # 800204d0 <bcache+0x8268>
    80003378:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000337c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003380:	00015497          	auipc	s1,0x15
    80003384:	f0048493          	addi	s1,s1,-256 # 80018280 <bcache+0x18>
    b->next = bcache.head.next;
    80003388:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000338a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000338c:	00005a17          	auipc	s4,0x5
    80003390:	1e4a0a13          	addi	s4,s4,484 # 80008570 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003394:	2b893783          	ld	a5,696(s2)
    80003398:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000339a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000339e:	85d2                	mv	a1,s4
    800033a0:	01048513          	addi	a0,s1,16
    800033a4:	00001097          	auipc	ra,0x1
    800033a8:	496080e7          	jalr	1174(ra) # 8000483a <initsleeplock>
    bcache.head.next->prev = b;
    800033ac:	2b893783          	ld	a5,696(s2)
    800033b0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033b2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033b6:	45848493          	addi	s1,s1,1112
    800033ba:	fd349de3          	bne	s1,s3,80003394 <binit+0x54>
  }
}
    800033be:	70a2                	ld	ra,40(sp)
    800033c0:	7402                	ld	s0,32(sp)
    800033c2:	64e2                	ld	s1,24(sp)
    800033c4:	6942                	ld	s2,16(sp)
    800033c6:	69a2                	ld	s3,8(sp)
    800033c8:	6a02                	ld	s4,0(sp)
    800033ca:	6145                	addi	sp,sp,48
    800033cc:	8082                	ret

00000000800033ce <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033ce:	7179                	addi	sp,sp,-48
    800033d0:	f406                	sd	ra,40(sp)
    800033d2:	f022                	sd	s0,32(sp)
    800033d4:	ec26                	sd	s1,24(sp)
    800033d6:	e84a                	sd	s2,16(sp)
    800033d8:	e44e                	sd	s3,8(sp)
    800033da:	1800                	addi	s0,sp,48
    800033dc:	892a                	mv	s2,a0
    800033de:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033e0:	00015517          	auipc	a0,0x15
    800033e4:	e8850513          	addi	a0,a0,-376 # 80018268 <bcache>
    800033e8:	ffffd097          	auipc	ra,0xffffd
    800033ec:	7ea080e7          	jalr	2026(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033f0:	0001d497          	auipc	s1,0x1d
    800033f4:	1304b483          	ld	s1,304(s1) # 80020520 <bcache+0x82b8>
    800033f8:	0001d797          	auipc	a5,0x1d
    800033fc:	0d878793          	addi	a5,a5,216 # 800204d0 <bcache+0x8268>
    80003400:	02f48f63          	beq	s1,a5,8000343e <bread+0x70>
    80003404:	873e                	mv	a4,a5
    80003406:	a021                	j	8000340e <bread+0x40>
    80003408:	68a4                	ld	s1,80(s1)
    8000340a:	02e48a63          	beq	s1,a4,8000343e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000340e:	449c                	lw	a5,8(s1)
    80003410:	ff279ce3          	bne	a5,s2,80003408 <bread+0x3a>
    80003414:	44dc                	lw	a5,12(s1)
    80003416:	ff3799e3          	bne	a5,s3,80003408 <bread+0x3a>
      b->refcnt++;
    8000341a:	40bc                	lw	a5,64(s1)
    8000341c:	2785                	addiw	a5,a5,1
    8000341e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003420:	00015517          	auipc	a0,0x15
    80003424:	e4850513          	addi	a0,a0,-440 # 80018268 <bcache>
    80003428:	ffffe097          	auipc	ra,0xffffe
    8000342c:	85e080e7          	jalr	-1954(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003430:	01048513          	addi	a0,s1,16
    80003434:	00001097          	auipc	ra,0x1
    80003438:	440080e7          	jalr	1088(ra) # 80004874 <acquiresleep>
      return b;
    8000343c:	a8b9                	j	8000349a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000343e:	0001d497          	auipc	s1,0x1d
    80003442:	0da4b483          	ld	s1,218(s1) # 80020518 <bcache+0x82b0>
    80003446:	0001d797          	auipc	a5,0x1d
    8000344a:	08a78793          	addi	a5,a5,138 # 800204d0 <bcache+0x8268>
    8000344e:	00f48863          	beq	s1,a5,8000345e <bread+0x90>
    80003452:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003454:	40bc                	lw	a5,64(s1)
    80003456:	cf81                	beqz	a5,8000346e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003458:	64a4                	ld	s1,72(s1)
    8000345a:	fee49de3          	bne	s1,a4,80003454 <bread+0x86>
  panic("bget: no buffers");
    8000345e:	00005517          	auipc	a0,0x5
    80003462:	11a50513          	addi	a0,a0,282 # 80008578 <syscalls+0xe0>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	0d6080e7          	jalr	214(ra) # 8000053c <panic>
      b->dev = dev;
    8000346e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003472:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003476:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000347a:	4785                	li	a5,1
    8000347c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000347e:	00015517          	auipc	a0,0x15
    80003482:	dea50513          	addi	a0,a0,-534 # 80018268 <bcache>
    80003486:	ffffe097          	auipc	ra,0xffffe
    8000348a:	800080e7          	jalr	-2048(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    8000348e:	01048513          	addi	a0,s1,16
    80003492:	00001097          	auipc	ra,0x1
    80003496:	3e2080e7          	jalr	994(ra) # 80004874 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000349a:	409c                	lw	a5,0(s1)
    8000349c:	cb89                	beqz	a5,800034ae <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000349e:	8526                	mv	a0,s1
    800034a0:	70a2                	ld	ra,40(sp)
    800034a2:	7402                	ld	s0,32(sp)
    800034a4:	64e2                	ld	s1,24(sp)
    800034a6:	6942                	ld	s2,16(sp)
    800034a8:	69a2                	ld	s3,8(sp)
    800034aa:	6145                	addi	sp,sp,48
    800034ac:	8082                	ret
    virtio_disk_rw(b, 0);
    800034ae:	4581                	li	a1,0
    800034b0:	8526                	mv	a0,s1
    800034b2:	00003097          	auipc	ra,0x3
    800034b6:	f90080e7          	jalr	-112(ra) # 80006442 <virtio_disk_rw>
    b->valid = 1;
    800034ba:	4785                	li	a5,1
    800034bc:	c09c                	sw	a5,0(s1)
  return b;
    800034be:	b7c5                	j	8000349e <bread+0xd0>

00000000800034c0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034c0:	1101                	addi	sp,sp,-32
    800034c2:	ec06                	sd	ra,24(sp)
    800034c4:	e822                	sd	s0,16(sp)
    800034c6:	e426                	sd	s1,8(sp)
    800034c8:	1000                	addi	s0,sp,32
    800034ca:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034cc:	0541                	addi	a0,a0,16
    800034ce:	00001097          	auipc	ra,0x1
    800034d2:	440080e7          	jalr	1088(ra) # 8000490e <holdingsleep>
    800034d6:	cd01                	beqz	a0,800034ee <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034d8:	4585                	li	a1,1
    800034da:	8526                	mv	a0,s1
    800034dc:	00003097          	auipc	ra,0x3
    800034e0:	f66080e7          	jalr	-154(ra) # 80006442 <virtio_disk_rw>
}
    800034e4:	60e2                	ld	ra,24(sp)
    800034e6:	6442                	ld	s0,16(sp)
    800034e8:	64a2                	ld	s1,8(sp)
    800034ea:	6105                	addi	sp,sp,32
    800034ec:	8082                	ret
    panic("bwrite");
    800034ee:	00005517          	auipc	a0,0x5
    800034f2:	0a250513          	addi	a0,a0,162 # 80008590 <syscalls+0xf8>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	046080e7          	jalr	70(ra) # 8000053c <panic>

00000000800034fe <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034fe:	1101                	addi	sp,sp,-32
    80003500:	ec06                	sd	ra,24(sp)
    80003502:	e822                	sd	s0,16(sp)
    80003504:	e426                	sd	s1,8(sp)
    80003506:	e04a                	sd	s2,0(sp)
    80003508:	1000                	addi	s0,sp,32
    8000350a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000350c:	01050913          	addi	s2,a0,16
    80003510:	854a                	mv	a0,s2
    80003512:	00001097          	auipc	ra,0x1
    80003516:	3fc080e7          	jalr	1020(ra) # 8000490e <holdingsleep>
    8000351a:	c925                	beqz	a0,8000358a <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000351c:	854a                	mv	a0,s2
    8000351e:	00001097          	auipc	ra,0x1
    80003522:	3ac080e7          	jalr	940(ra) # 800048ca <releasesleep>

  acquire(&bcache.lock);
    80003526:	00015517          	auipc	a0,0x15
    8000352a:	d4250513          	addi	a0,a0,-702 # 80018268 <bcache>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	6a4080e7          	jalr	1700(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003536:	40bc                	lw	a5,64(s1)
    80003538:	37fd                	addiw	a5,a5,-1
    8000353a:	0007871b          	sext.w	a4,a5
    8000353e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003540:	e71d                	bnez	a4,8000356e <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003542:	68b8                	ld	a4,80(s1)
    80003544:	64bc                	ld	a5,72(s1)
    80003546:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003548:	68b8                	ld	a4,80(s1)
    8000354a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000354c:	0001d797          	auipc	a5,0x1d
    80003550:	d1c78793          	addi	a5,a5,-740 # 80020268 <bcache+0x8000>
    80003554:	2b87b703          	ld	a4,696(a5)
    80003558:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000355a:	0001d717          	auipc	a4,0x1d
    8000355e:	f7670713          	addi	a4,a4,-138 # 800204d0 <bcache+0x8268>
    80003562:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003564:	2b87b703          	ld	a4,696(a5)
    80003568:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000356a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000356e:	00015517          	auipc	a0,0x15
    80003572:	cfa50513          	addi	a0,a0,-774 # 80018268 <bcache>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	710080e7          	jalr	1808(ra) # 80000c86 <release>
}
    8000357e:	60e2                	ld	ra,24(sp)
    80003580:	6442                	ld	s0,16(sp)
    80003582:	64a2                	ld	s1,8(sp)
    80003584:	6902                	ld	s2,0(sp)
    80003586:	6105                	addi	sp,sp,32
    80003588:	8082                	ret
    panic("brelse");
    8000358a:	00005517          	auipc	a0,0x5
    8000358e:	00e50513          	addi	a0,a0,14 # 80008598 <syscalls+0x100>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	faa080e7          	jalr	-86(ra) # 8000053c <panic>

000000008000359a <bpin>:

void
bpin(struct buf *b) {
    8000359a:	1101                	addi	sp,sp,-32
    8000359c:	ec06                	sd	ra,24(sp)
    8000359e:	e822                	sd	s0,16(sp)
    800035a0:	e426                	sd	s1,8(sp)
    800035a2:	1000                	addi	s0,sp,32
    800035a4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035a6:	00015517          	auipc	a0,0x15
    800035aa:	cc250513          	addi	a0,a0,-830 # 80018268 <bcache>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	624080e7          	jalr	1572(ra) # 80000bd2 <acquire>
  b->refcnt++;
    800035b6:	40bc                	lw	a5,64(s1)
    800035b8:	2785                	addiw	a5,a5,1
    800035ba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035bc:	00015517          	auipc	a0,0x15
    800035c0:	cac50513          	addi	a0,a0,-852 # 80018268 <bcache>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	6c2080e7          	jalr	1730(ra) # 80000c86 <release>
}
    800035cc:	60e2                	ld	ra,24(sp)
    800035ce:	6442                	ld	s0,16(sp)
    800035d0:	64a2                	ld	s1,8(sp)
    800035d2:	6105                	addi	sp,sp,32
    800035d4:	8082                	ret

00000000800035d6 <bunpin>:

void
bunpin(struct buf *b) {
    800035d6:	1101                	addi	sp,sp,-32
    800035d8:	ec06                	sd	ra,24(sp)
    800035da:	e822                	sd	s0,16(sp)
    800035dc:	e426                	sd	s1,8(sp)
    800035de:	1000                	addi	s0,sp,32
    800035e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035e2:	00015517          	auipc	a0,0x15
    800035e6:	c8650513          	addi	a0,a0,-890 # 80018268 <bcache>
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	5e8080e7          	jalr	1512(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800035f2:	40bc                	lw	a5,64(s1)
    800035f4:	37fd                	addiw	a5,a5,-1
    800035f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035f8:	00015517          	auipc	a0,0x15
    800035fc:	c7050513          	addi	a0,a0,-912 # 80018268 <bcache>
    80003600:	ffffd097          	auipc	ra,0xffffd
    80003604:	686080e7          	jalr	1670(ra) # 80000c86 <release>
}
    80003608:	60e2                	ld	ra,24(sp)
    8000360a:	6442                	ld	s0,16(sp)
    8000360c:	64a2                	ld	s1,8(sp)
    8000360e:	6105                	addi	sp,sp,32
    80003610:	8082                	ret

0000000080003612 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003612:	1101                	addi	sp,sp,-32
    80003614:	ec06                	sd	ra,24(sp)
    80003616:	e822                	sd	s0,16(sp)
    80003618:	e426                	sd	s1,8(sp)
    8000361a:	e04a                	sd	s2,0(sp)
    8000361c:	1000                	addi	s0,sp,32
    8000361e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003620:	00d5d59b          	srliw	a1,a1,0xd
    80003624:	0001d797          	auipc	a5,0x1d
    80003628:	3207a783          	lw	a5,800(a5) # 80020944 <sb+0x1c>
    8000362c:	9dbd                	addw	a1,a1,a5
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	da0080e7          	jalr	-608(ra) # 800033ce <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003636:	0074f713          	andi	a4,s1,7
    8000363a:	4785                	li	a5,1
    8000363c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003640:	14ce                	slli	s1,s1,0x33
    80003642:	90d9                	srli	s1,s1,0x36
    80003644:	00950733          	add	a4,a0,s1
    80003648:	05874703          	lbu	a4,88(a4)
    8000364c:	00e7f6b3          	and	a3,a5,a4
    80003650:	c69d                	beqz	a3,8000367e <bfree+0x6c>
    80003652:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003654:	94aa                	add	s1,s1,a0
    80003656:	fff7c793          	not	a5,a5
    8000365a:	8f7d                	and	a4,a4,a5
    8000365c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003660:	00001097          	auipc	ra,0x1
    80003664:	0f6080e7          	jalr	246(ra) # 80004756 <log_write>
  brelse(bp);
    80003668:	854a                	mv	a0,s2
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	e94080e7          	jalr	-364(ra) # 800034fe <brelse>
}
    80003672:	60e2                	ld	ra,24(sp)
    80003674:	6442                	ld	s0,16(sp)
    80003676:	64a2                	ld	s1,8(sp)
    80003678:	6902                	ld	s2,0(sp)
    8000367a:	6105                	addi	sp,sp,32
    8000367c:	8082                	ret
    panic("freeing free block");
    8000367e:	00005517          	auipc	a0,0x5
    80003682:	f2250513          	addi	a0,a0,-222 # 800085a0 <syscalls+0x108>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	eb6080e7          	jalr	-330(ra) # 8000053c <panic>

000000008000368e <balloc>:
{
    8000368e:	711d                	addi	sp,sp,-96
    80003690:	ec86                	sd	ra,88(sp)
    80003692:	e8a2                	sd	s0,80(sp)
    80003694:	e4a6                	sd	s1,72(sp)
    80003696:	e0ca                	sd	s2,64(sp)
    80003698:	fc4e                	sd	s3,56(sp)
    8000369a:	f852                	sd	s4,48(sp)
    8000369c:	f456                	sd	s5,40(sp)
    8000369e:	f05a                	sd	s6,32(sp)
    800036a0:	ec5e                	sd	s7,24(sp)
    800036a2:	e862                	sd	s8,16(sp)
    800036a4:	e466                	sd	s9,8(sp)
    800036a6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036a8:	0001d797          	auipc	a5,0x1d
    800036ac:	2847a783          	lw	a5,644(a5) # 8002092c <sb+0x4>
    800036b0:	cff5                	beqz	a5,800037ac <balloc+0x11e>
    800036b2:	8baa                	mv	s7,a0
    800036b4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036b6:	0001db17          	auipc	s6,0x1d
    800036ba:	272b0b13          	addi	s6,s6,626 # 80020928 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036be:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036c0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036c2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036c4:	6c89                	lui	s9,0x2
    800036c6:	a061                	j	8000374e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036c8:	97ca                	add	a5,a5,s2
    800036ca:	8e55                	or	a2,a2,a3
    800036cc:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800036d0:	854a                	mv	a0,s2
    800036d2:	00001097          	auipc	ra,0x1
    800036d6:	084080e7          	jalr	132(ra) # 80004756 <log_write>
        brelse(bp);
    800036da:	854a                	mv	a0,s2
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	e22080e7          	jalr	-478(ra) # 800034fe <brelse>
  bp = bread(dev, bno);
    800036e4:	85a6                	mv	a1,s1
    800036e6:	855e                	mv	a0,s7
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	ce6080e7          	jalr	-794(ra) # 800033ce <bread>
    800036f0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036f2:	40000613          	li	a2,1024
    800036f6:	4581                	li	a1,0
    800036f8:	05850513          	addi	a0,a0,88
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	5d2080e7          	jalr	1490(ra) # 80000cce <memset>
  log_write(bp);
    80003704:	854a                	mv	a0,s2
    80003706:	00001097          	auipc	ra,0x1
    8000370a:	050080e7          	jalr	80(ra) # 80004756 <log_write>
  brelse(bp);
    8000370e:	854a                	mv	a0,s2
    80003710:	00000097          	auipc	ra,0x0
    80003714:	dee080e7          	jalr	-530(ra) # 800034fe <brelse>
}
    80003718:	8526                	mv	a0,s1
    8000371a:	60e6                	ld	ra,88(sp)
    8000371c:	6446                	ld	s0,80(sp)
    8000371e:	64a6                	ld	s1,72(sp)
    80003720:	6906                	ld	s2,64(sp)
    80003722:	79e2                	ld	s3,56(sp)
    80003724:	7a42                	ld	s4,48(sp)
    80003726:	7aa2                	ld	s5,40(sp)
    80003728:	7b02                	ld	s6,32(sp)
    8000372a:	6be2                	ld	s7,24(sp)
    8000372c:	6c42                	ld	s8,16(sp)
    8000372e:	6ca2                	ld	s9,8(sp)
    80003730:	6125                	addi	sp,sp,96
    80003732:	8082                	ret
    brelse(bp);
    80003734:	854a                	mv	a0,s2
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	dc8080e7          	jalr	-568(ra) # 800034fe <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000373e:	015c87bb          	addw	a5,s9,s5
    80003742:	00078a9b          	sext.w	s5,a5
    80003746:	004b2703          	lw	a4,4(s6)
    8000374a:	06eaf163          	bgeu	s5,a4,800037ac <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000374e:	41fad79b          	sraiw	a5,s5,0x1f
    80003752:	0137d79b          	srliw	a5,a5,0x13
    80003756:	015787bb          	addw	a5,a5,s5
    8000375a:	40d7d79b          	sraiw	a5,a5,0xd
    8000375e:	01cb2583          	lw	a1,28(s6)
    80003762:	9dbd                	addw	a1,a1,a5
    80003764:	855e                	mv	a0,s7
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	c68080e7          	jalr	-920(ra) # 800033ce <bread>
    8000376e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003770:	004b2503          	lw	a0,4(s6)
    80003774:	000a849b          	sext.w	s1,s5
    80003778:	8762                	mv	a4,s8
    8000377a:	faa4fde3          	bgeu	s1,a0,80003734 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000377e:	00777693          	andi	a3,a4,7
    80003782:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003786:	41f7579b          	sraiw	a5,a4,0x1f
    8000378a:	01d7d79b          	srliw	a5,a5,0x1d
    8000378e:	9fb9                	addw	a5,a5,a4
    80003790:	4037d79b          	sraiw	a5,a5,0x3
    80003794:	00f90633          	add	a2,s2,a5
    80003798:	05864603          	lbu	a2,88(a2)
    8000379c:	00c6f5b3          	and	a1,a3,a2
    800037a0:	d585                	beqz	a1,800036c8 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037a2:	2705                	addiw	a4,a4,1
    800037a4:	2485                	addiw	s1,s1,1
    800037a6:	fd471ae3          	bne	a4,s4,8000377a <balloc+0xec>
    800037aa:	b769                	j	80003734 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800037ac:	00005517          	auipc	a0,0x5
    800037b0:	e0c50513          	addi	a0,a0,-500 # 800085b8 <syscalls+0x120>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	dd2080e7          	jalr	-558(ra) # 80000586 <printf>
  return 0;
    800037bc:	4481                	li	s1,0
    800037be:	bfa9                	j	80003718 <balloc+0x8a>

00000000800037c0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800037c0:	7179                	addi	sp,sp,-48
    800037c2:	f406                	sd	ra,40(sp)
    800037c4:	f022                	sd	s0,32(sp)
    800037c6:	ec26                	sd	s1,24(sp)
    800037c8:	e84a                	sd	s2,16(sp)
    800037ca:	e44e                	sd	s3,8(sp)
    800037cc:	e052                	sd	s4,0(sp)
    800037ce:	1800                	addi	s0,sp,48
    800037d0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037d2:	47ad                	li	a5,11
    800037d4:	02b7e863          	bltu	a5,a1,80003804 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800037d8:	02059793          	slli	a5,a1,0x20
    800037dc:	01e7d593          	srli	a1,a5,0x1e
    800037e0:	00b504b3          	add	s1,a0,a1
    800037e4:	0504a903          	lw	s2,80(s1)
    800037e8:	06091e63          	bnez	s2,80003864 <bmap+0xa4>
      addr = balloc(ip->dev);
    800037ec:	4108                	lw	a0,0(a0)
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	ea0080e7          	jalr	-352(ra) # 8000368e <balloc>
    800037f6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037fa:	06090563          	beqz	s2,80003864 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800037fe:	0524a823          	sw	s2,80(s1)
    80003802:	a08d                	j	80003864 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003804:	ff45849b          	addiw	s1,a1,-12
    80003808:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000380c:	0ff00793          	li	a5,255
    80003810:	08e7e563          	bltu	a5,a4,8000389a <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003814:	08052903          	lw	s2,128(a0)
    80003818:	00091d63          	bnez	s2,80003832 <bmap+0x72>
      addr = balloc(ip->dev);
    8000381c:	4108                	lw	a0,0(a0)
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	e70080e7          	jalr	-400(ra) # 8000368e <balloc>
    80003826:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000382a:	02090d63          	beqz	s2,80003864 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000382e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003832:	85ca                	mv	a1,s2
    80003834:	0009a503          	lw	a0,0(s3)
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	b96080e7          	jalr	-1130(ra) # 800033ce <bread>
    80003840:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003842:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003846:	02049713          	slli	a4,s1,0x20
    8000384a:	01e75593          	srli	a1,a4,0x1e
    8000384e:	00b784b3          	add	s1,a5,a1
    80003852:	0004a903          	lw	s2,0(s1)
    80003856:	02090063          	beqz	s2,80003876 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000385a:	8552                	mv	a0,s4
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	ca2080e7          	jalr	-862(ra) # 800034fe <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003864:	854a                	mv	a0,s2
    80003866:	70a2                	ld	ra,40(sp)
    80003868:	7402                	ld	s0,32(sp)
    8000386a:	64e2                	ld	s1,24(sp)
    8000386c:	6942                	ld	s2,16(sp)
    8000386e:	69a2                	ld	s3,8(sp)
    80003870:	6a02                	ld	s4,0(sp)
    80003872:	6145                	addi	sp,sp,48
    80003874:	8082                	ret
      addr = balloc(ip->dev);
    80003876:	0009a503          	lw	a0,0(s3)
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	e14080e7          	jalr	-492(ra) # 8000368e <balloc>
    80003882:	0005091b          	sext.w	s2,a0
      if(addr){
    80003886:	fc090ae3          	beqz	s2,8000385a <bmap+0x9a>
        a[bn] = addr;
    8000388a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000388e:	8552                	mv	a0,s4
    80003890:	00001097          	auipc	ra,0x1
    80003894:	ec6080e7          	jalr	-314(ra) # 80004756 <log_write>
    80003898:	b7c9                	j	8000385a <bmap+0x9a>
  panic("bmap: out of range");
    8000389a:	00005517          	auipc	a0,0x5
    8000389e:	d3650513          	addi	a0,a0,-714 # 800085d0 <syscalls+0x138>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	c9a080e7          	jalr	-870(ra) # 8000053c <panic>

00000000800038aa <iget>:
{
    800038aa:	7179                	addi	sp,sp,-48
    800038ac:	f406                	sd	ra,40(sp)
    800038ae:	f022                	sd	s0,32(sp)
    800038b0:	ec26                	sd	s1,24(sp)
    800038b2:	e84a                	sd	s2,16(sp)
    800038b4:	e44e                	sd	s3,8(sp)
    800038b6:	e052                	sd	s4,0(sp)
    800038b8:	1800                	addi	s0,sp,48
    800038ba:	89aa                	mv	s3,a0
    800038bc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038be:	0001d517          	auipc	a0,0x1d
    800038c2:	08a50513          	addi	a0,a0,138 # 80020948 <itable>
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	30c080e7          	jalr	780(ra) # 80000bd2 <acquire>
  empty = 0;
    800038ce:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038d0:	0001d497          	auipc	s1,0x1d
    800038d4:	09048493          	addi	s1,s1,144 # 80020960 <itable+0x18>
    800038d8:	0001f697          	auipc	a3,0x1f
    800038dc:	b1868693          	addi	a3,a3,-1256 # 800223f0 <log>
    800038e0:	a039                	j	800038ee <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038e2:	02090b63          	beqz	s2,80003918 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038e6:	08848493          	addi	s1,s1,136
    800038ea:	02d48a63          	beq	s1,a3,8000391e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038ee:	449c                	lw	a5,8(s1)
    800038f0:	fef059e3          	blez	a5,800038e2 <iget+0x38>
    800038f4:	4098                	lw	a4,0(s1)
    800038f6:	ff3716e3          	bne	a4,s3,800038e2 <iget+0x38>
    800038fa:	40d8                	lw	a4,4(s1)
    800038fc:	ff4713e3          	bne	a4,s4,800038e2 <iget+0x38>
      ip->ref++;
    80003900:	2785                	addiw	a5,a5,1
    80003902:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003904:	0001d517          	auipc	a0,0x1d
    80003908:	04450513          	addi	a0,a0,68 # 80020948 <itable>
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	37a080e7          	jalr	890(ra) # 80000c86 <release>
      return ip;
    80003914:	8926                	mv	s2,s1
    80003916:	a03d                	j	80003944 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003918:	f7f9                	bnez	a5,800038e6 <iget+0x3c>
    8000391a:	8926                	mv	s2,s1
    8000391c:	b7e9                	j	800038e6 <iget+0x3c>
  if(empty == 0)
    8000391e:	02090c63          	beqz	s2,80003956 <iget+0xac>
  ip->dev = dev;
    80003922:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003926:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000392a:	4785                	li	a5,1
    8000392c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003930:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003934:	0001d517          	auipc	a0,0x1d
    80003938:	01450513          	addi	a0,a0,20 # 80020948 <itable>
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	34a080e7          	jalr	842(ra) # 80000c86 <release>
}
    80003944:	854a                	mv	a0,s2
    80003946:	70a2                	ld	ra,40(sp)
    80003948:	7402                	ld	s0,32(sp)
    8000394a:	64e2                	ld	s1,24(sp)
    8000394c:	6942                	ld	s2,16(sp)
    8000394e:	69a2                	ld	s3,8(sp)
    80003950:	6a02                	ld	s4,0(sp)
    80003952:	6145                	addi	sp,sp,48
    80003954:	8082                	ret
    panic("iget: no inodes");
    80003956:	00005517          	auipc	a0,0x5
    8000395a:	c9250513          	addi	a0,a0,-878 # 800085e8 <syscalls+0x150>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	bde080e7          	jalr	-1058(ra) # 8000053c <panic>

0000000080003966 <fsinit>:
fsinit(int dev) {
    80003966:	7179                	addi	sp,sp,-48
    80003968:	f406                	sd	ra,40(sp)
    8000396a:	f022                	sd	s0,32(sp)
    8000396c:	ec26                	sd	s1,24(sp)
    8000396e:	e84a                	sd	s2,16(sp)
    80003970:	e44e                	sd	s3,8(sp)
    80003972:	1800                	addi	s0,sp,48
    80003974:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003976:	4585                	li	a1,1
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	a56080e7          	jalr	-1450(ra) # 800033ce <bread>
    80003980:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003982:	0001d997          	auipc	s3,0x1d
    80003986:	fa698993          	addi	s3,s3,-90 # 80020928 <sb>
    8000398a:	02000613          	li	a2,32
    8000398e:	05850593          	addi	a1,a0,88
    80003992:	854e                	mv	a0,s3
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	396080e7          	jalr	918(ra) # 80000d2a <memmove>
  brelse(bp);
    8000399c:	8526                	mv	a0,s1
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	b60080e7          	jalr	-1184(ra) # 800034fe <brelse>
  if(sb.magic != FSMAGIC)
    800039a6:	0009a703          	lw	a4,0(s3)
    800039aa:	102037b7          	lui	a5,0x10203
    800039ae:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039b2:	02f71263          	bne	a4,a5,800039d6 <fsinit+0x70>
  initlog(dev, &sb);
    800039b6:	0001d597          	auipc	a1,0x1d
    800039ba:	f7258593          	addi	a1,a1,-142 # 80020928 <sb>
    800039be:	854a                	mv	a0,s2
    800039c0:	00001097          	auipc	ra,0x1
    800039c4:	b2c080e7          	jalr	-1236(ra) # 800044ec <initlog>
}
    800039c8:	70a2                	ld	ra,40(sp)
    800039ca:	7402                	ld	s0,32(sp)
    800039cc:	64e2                	ld	s1,24(sp)
    800039ce:	6942                	ld	s2,16(sp)
    800039d0:	69a2                	ld	s3,8(sp)
    800039d2:	6145                	addi	sp,sp,48
    800039d4:	8082                	ret
    panic("invalid file system");
    800039d6:	00005517          	auipc	a0,0x5
    800039da:	c2250513          	addi	a0,a0,-990 # 800085f8 <syscalls+0x160>
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	b5e080e7          	jalr	-1186(ra) # 8000053c <panic>

00000000800039e6 <iinit>:
{
    800039e6:	7179                	addi	sp,sp,-48
    800039e8:	f406                	sd	ra,40(sp)
    800039ea:	f022                	sd	s0,32(sp)
    800039ec:	ec26                	sd	s1,24(sp)
    800039ee:	e84a                	sd	s2,16(sp)
    800039f0:	e44e                	sd	s3,8(sp)
    800039f2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039f4:	00005597          	auipc	a1,0x5
    800039f8:	c1c58593          	addi	a1,a1,-996 # 80008610 <syscalls+0x178>
    800039fc:	0001d517          	auipc	a0,0x1d
    80003a00:	f4c50513          	addi	a0,a0,-180 # 80020948 <itable>
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	13e080e7          	jalr	318(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a0c:	0001d497          	auipc	s1,0x1d
    80003a10:	f6448493          	addi	s1,s1,-156 # 80020970 <itable+0x28>
    80003a14:	0001f997          	auipc	s3,0x1f
    80003a18:	9ec98993          	addi	s3,s3,-1556 # 80022400 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a1c:	00005917          	auipc	s2,0x5
    80003a20:	bfc90913          	addi	s2,s2,-1028 # 80008618 <syscalls+0x180>
    80003a24:	85ca                	mv	a1,s2
    80003a26:	8526                	mv	a0,s1
    80003a28:	00001097          	auipc	ra,0x1
    80003a2c:	e12080e7          	jalr	-494(ra) # 8000483a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a30:	08848493          	addi	s1,s1,136
    80003a34:	ff3498e3          	bne	s1,s3,80003a24 <iinit+0x3e>
}
    80003a38:	70a2                	ld	ra,40(sp)
    80003a3a:	7402                	ld	s0,32(sp)
    80003a3c:	64e2                	ld	s1,24(sp)
    80003a3e:	6942                	ld	s2,16(sp)
    80003a40:	69a2                	ld	s3,8(sp)
    80003a42:	6145                	addi	sp,sp,48
    80003a44:	8082                	ret

0000000080003a46 <ialloc>:
{
    80003a46:	7139                	addi	sp,sp,-64
    80003a48:	fc06                	sd	ra,56(sp)
    80003a4a:	f822                	sd	s0,48(sp)
    80003a4c:	f426                	sd	s1,40(sp)
    80003a4e:	f04a                	sd	s2,32(sp)
    80003a50:	ec4e                	sd	s3,24(sp)
    80003a52:	e852                	sd	s4,16(sp)
    80003a54:	e456                	sd	s5,8(sp)
    80003a56:	e05a                	sd	s6,0(sp)
    80003a58:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a5a:	0001d717          	auipc	a4,0x1d
    80003a5e:	eda72703          	lw	a4,-294(a4) # 80020934 <sb+0xc>
    80003a62:	4785                	li	a5,1
    80003a64:	04e7f863          	bgeu	a5,a4,80003ab4 <ialloc+0x6e>
    80003a68:	8aaa                	mv	s5,a0
    80003a6a:	8b2e                	mv	s6,a1
    80003a6c:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a6e:	0001da17          	auipc	s4,0x1d
    80003a72:	ebaa0a13          	addi	s4,s4,-326 # 80020928 <sb>
    80003a76:	00495593          	srli	a1,s2,0x4
    80003a7a:	018a2783          	lw	a5,24(s4)
    80003a7e:	9dbd                	addw	a1,a1,a5
    80003a80:	8556                	mv	a0,s5
    80003a82:	00000097          	auipc	ra,0x0
    80003a86:	94c080e7          	jalr	-1716(ra) # 800033ce <bread>
    80003a8a:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a8c:	05850993          	addi	s3,a0,88
    80003a90:	00f97793          	andi	a5,s2,15
    80003a94:	079a                	slli	a5,a5,0x6
    80003a96:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a98:	00099783          	lh	a5,0(s3)
    80003a9c:	cf9d                	beqz	a5,80003ada <ialloc+0x94>
    brelse(bp);
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	a60080e7          	jalr	-1440(ra) # 800034fe <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003aa6:	0905                	addi	s2,s2,1
    80003aa8:	00ca2703          	lw	a4,12(s4)
    80003aac:	0009079b          	sext.w	a5,s2
    80003ab0:	fce7e3e3          	bltu	a5,a4,80003a76 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003ab4:	00005517          	auipc	a0,0x5
    80003ab8:	b6c50513          	addi	a0,a0,-1172 # 80008620 <syscalls+0x188>
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	aca080e7          	jalr	-1334(ra) # 80000586 <printf>
  return 0;
    80003ac4:	4501                	li	a0,0
}
    80003ac6:	70e2                	ld	ra,56(sp)
    80003ac8:	7442                	ld	s0,48(sp)
    80003aca:	74a2                	ld	s1,40(sp)
    80003acc:	7902                	ld	s2,32(sp)
    80003ace:	69e2                	ld	s3,24(sp)
    80003ad0:	6a42                	ld	s4,16(sp)
    80003ad2:	6aa2                	ld	s5,8(sp)
    80003ad4:	6b02                	ld	s6,0(sp)
    80003ad6:	6121                	addi	sp,sp,64
    80003ad8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003ada:	04000613          	li	a2,64
    80003ade:	4581                	li	a1,0
    80003ae0:	854e                	mv	a0,s3
    80003ae2:	ffffd097          	auipc	ra,0xffffd
    80003ae6:	1ec080e7          	jalr	492(ra) # 80000cce <memset>
      dip->type = type;
    80003aea:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003aee:	8526                	mv	a0,s1
    80003af0:	00001097          	auipc	ra,0x1
    80003af4:	c66080e7          	jalr	-922(ra) # 80004756 <log_write>
      brelse(bp);
    80003af8:	8526                	mv	a0,s1
    80003afa:	00000097          	auipc	ra,0x0
    80003afe:	a04080e7          	jalr	-1532(ra) # 800034fe <brelse>
      return iget(dev, inum);
    80003b02:	0009059b          	sext.w	a1,s2
    80003b06:	8556                	mv	a0,s5
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	da2080e7          	jalr	-606(ra) # 800038aa <iget>
    80003b10:	bf5d                	j	80003ac6 <ialloc+0x80>

0000000080003b12 <iupdate>:
{
    80003b12:	1101                	addi	sp,sp,-32
    80003b14:	ec06                	sd	ra,24(sp)
    80003b16:	e822                	sd	s0,16(sp)
    80003b18:	e426                	sd	s1,8(sp)
    80003b1a:	e04a                	sd	s2,0(sp)
    80003b1c:	1000                	addi	s0,sp,32
    80003b1e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b20:	415c                	lw	a5,4(a0)
    80003b22:	0047d79b          	srliw	a5,a5,0x4
    80003b26:	0001d597          	auipc	a1,0x1d
    80003b2a:	e1a5a583          	lw	a1,-486(a1) # 80020940 <sb+0x18>
    80003b2e:	9dbd                	addw	a1,a1,a5
    80003b30:	4108                	lw	a0,0(a0)
    80003b32:	00000097          	auipc	ra,0x0
    80003b36:	89c080e7          	jalr	-1892(ra) # 800033ce <bread>
    80003b3a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b3c:	05850793          	addi	a5,a0,88
    80003b40:	40d8                	lw	a4,4(s1)
    80003b42:	8b3d                	andi	a4,a4,15
    80003b44:	071a                	slli	a4,a4,0x6
    80003b46:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b48:	04449703          	lh	a4,68(s1)
    80003b4c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b50:	04649703          	lh	a4,70(s1)
    80003b54:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b58:	04849703          	lh	a4,72(s1)
    80003b5c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b60:	04a49703          	lh	a4,74(s1)
    80003b64:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003b68:	44f8                	lw	a4,76(s1)
    80003b6a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b6c:	03400613          	li	a2,52
    80003b70:	05048593          	addi	a1,s1,80
    80003b74:	00c78513          	addi	a0,a5,12
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	1b2080e7          	jalr	434(ra) # 80000d2a <memmove>
  log_write(bp);
    80003b80:	854a                	mv	a0,s2
    80003b82:	00001097          	auipc	ra,0x1
    80003b86:	bd4080e7          	jalr	-1068(ra) # 80004756 <log_write>
  brelse(bp);
    80003b8a:	854a                	mv	a0,s2
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	972080e7          	jalr	-1678(ra) # 800034fe <brelse>
}
    80003b94:	60e2                	ld	ra,24(sp)
    80003b96:	6442                	ld	s0,16(sp)
    80003b98:	64a2                	ld	s1,8(sp)
    80003b9a:	6902                	ld	s2,0(sp)
    80003b9c:	6105                	addi	sp,sp,32
    80003b9e:	8082                	ret

0000000080003ba0 <idup>:
{
    80003ba0:	1101                	addi	sp,sp,-32
    80003ba2:	ec06                	sd	ra,24(sp)
    80003ba4:	e822                	sd	s0,16(sp)
    80003ba6:	e426                	sd	s1,8(sp)
    80003ba8:	1000                	addi	s0,sp,32
    80003baa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bac:	0001d517          	auipc	a0,0x1d
    80003bb0:	d9c50513          	addi	a0,a0,-612 # 80020948 <itable>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	01e080e7          	jalr	30(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003bbc:	449c                	lw	a5,8(s1)
    80003bbe:	2785                	addiw	a5,a5,1
    80003bc0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bc2:	0001d517          	auipc	a0,0x1d
    80003bc6:	d8650513          	addi	a0,a0,-634 # 80020948 <itable>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	0bc080e7          	jalr	188(ra) # 80000c86 <release>
}
    80003bd2:	8526                	mv	a0,s1
    80003bd4:	60e2                	ld	ra,24(sp)
    80003bd6:	6442                	ld	s0,16(sp)
    80003bd8:	64a2                	ld	s1,8(sp)
    80003bda:	6105                	addi	sp,sp,32
    80003bdc:	8082                	ret

0000000080003bde <ilock>:
{
    80003bde:	1101                	addi	sp,sp,-32
    80003be0:	ec06                	sd	ra,24(sp)
    80003be2:	e822                	sd	s0,16(sp)
    80003be4:	e426                	sd	s1,8(sp)
    80003be6:	e04a                	sd	s2,0(sp)
    80003be8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bea:	c115                	beqz	a0,80003c0e <ilock+0x30>
    80003bec:	84aa                	mv	s1,a0
    80003bee:	451c                	lw	a5,8(a0)
    80003bf0:	00f05f63          	blez	a5,80003c0e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bf4:	0541                	addi	a0,a0,16
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	c7e080e7          	jalr	-898(ra) # 80004874 <acquiresleep>
  if(ip->valid == 0){
    80003bfe:	40bc                	lw	a5,64(s1)
    80003c00:	cf99                	beqz	a5,80003c1e <ilock+0x40>
}
    80003c02:	60e2                	ld	ra,24(sp)
    80003c04:	6442                	ld	s0,16(sp)
    80003c06:	64a2                	ld	s1,8(sp)
    80003c08:	6902                	ld	s2,0(sp)
    80003c0a:	6105                	addi	sp,sp,32
    80003c0c:	8082                	ret
    panic("ilock");
    80003c0e:	00005517          	auipc	a0,0x5
    80003c12:	a2a50513          	addi	a0,a0,-1494 # 80008638 <syscalls+0x1a0>
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	926080e7          	jalr	-1754(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c1e:	40dc                	lw	a5,4(s1)
    80003c20:	0047d79b          	srliw	a5,a5,0x4
    80003c24:	0001d597          	auipc	a1,0x1d
    80003c28:	d1c5a583          	lw	a1,-740(a1) # 80020940 <sb+0x18>
    80003c2c:	9dbd                	addw	a1,a1,a5
    80003c2e:	4088                	lw	a0,0(s1)
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	79e080e7          	jalr	1950(ra) # 800033ce <bread>
    80003c38:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c3a:	05850593          	addi	a1,a0,88
    80003c3e:	40dc                	lw	a5,4(s1)
    80003c40:	8bbd                	andi	a5,a5,15
    80003c42:	079a                	slli	a5,a5,0x6
    80003c44:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c46:	00059783          	lh	a5,0(a1)
    80003c4a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c4e:	00259783          	lh	a5,2(a1)
    80003c52:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c56:	00459783          	lh	a5,4(a1)
    80003c5a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c5e:	00659783          	lh	a5,6(a1)
    80003c62:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c66:	459c                	lw	a5,8(a1)
    80003c68:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c6a:	03400613          	li	a2,52
    80003c6e:	05b1                	addi	a1,a1,12
    80003c70:	05048513          	addi	a0,s1,80
    80003c74:	ffffd097          	auipc	ra,0xffffd
    80003c78:	0b6080e7          	jalr	182(ra) # 80000d2a <memmove>
    brelse(bp);
    80003c7c:	854a                	mv	a0,s2
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	880080e7          	jalr	-1920(ra) # 800034fe <brelse>
    ip->valid = 1;
    80003c86:	4785                	li	a5,1
    80003c88:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c8a:	04449783          	lh	a5,68(s1)
    80003c8e:	fbb5                	bnez	a5,80003c02 <ilock+0x24>
      panic("ilock: no type");
    80003c90:	00005517          	auipc	a0,0x5
    80003c94:	9b050513          	addi	a0,a0,-1616 # 80008640 <syscalls+0x1a8>
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	8a4080e7          	jalr	-1884(ra) # 8000053c <panic>

0000000080003ca0 <iunlock>:
{
    80003ca0:	1101                	addi	sp,sp,-32
    80003ca2:	ec06                	sd	ra,24(sp)
    80003ca4:	e822                	sd	s0,16(sp)
    80003ca6:	e426                	sd	s1,8(sp)
    80003ca8:	e04a                	sd	s2,0(sp)
    80003caa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cac:	c905                	beqz	a0,80003cdc <iunlock+0x3c>
    80003cae:	84aa                	mv	s1,a0
    80003cb0:	01050913          	addi	s2,a0,16
    80003cb4:	854a                	mv	a0,s2
    80003cb6:	00001097          	auipc	ra,0x1
    80003cba:	c58080e7          	jalr	-936(ra) # 8000490e <holdingsleep>
    80003cbe:	cd19                	beqz	a0,80003cdc <iunlock+0x3c>
    80003cc0:	449c                	lw	a5,8(s1)
    80003cc2:	00f05d63          	blez	a5,80003cdc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	00001097          	auipc	ra,0x1
    80003ccc:	c02080e7          	jalr	-1022(ra) # 800048ca <releasesleep>
}
    80003cd0:	60e2                	ld	ra,24(sp)
    80003cd2:	6442                	ld	s0,16(sp)
    80003cd4:	64a2                	ld	s1,8(sp)
    80003cd6:	6902                	ld	s2,0(sp)
    80003cd8:	6105                	addi	sp,sp,32
    80003cda:	8082                	ret
    panic("iunlock");
    80003cdc:	00005517          	auipc	a0,0x5
    80003ce0:	97450513          	addi	a0,a0,-1676 # 80008650 <syscalls+0x1b8>
    80003ce4:	ffffd097          	auipc	ra,0xffffd
    80003ce8:	858080e7          	jalr	-1960(ra) # 8000053c <panic>

0000000080003cec <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cec:	7179                	addi	sp,sp,-48
    80003cee:	f406                	sd	ra,40(sp)
    80003cf0:	f022                	sd	s0,32(sp)
    80003cf2:	ec26                	sd	s1,24(sp)
    80003cf4:	e84a                	sd	s2,16(sp)
    80003cf6:	e44e                	sd	s3,8(sp)
    80003cf8:	e052                	sd	s4,0(sp)
    80003cfa:	1800                	addi	s0,sp,48
    80003cfc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cfe:	05050493          	addi	s1,a0,80
    80003d02:	08050913          	addi	s2,a0,128
    80003d06:	a021                	j	80003d0e <itrunc+0x22>
    80003d08:	0491                	addi	s1,s1,4
    80003d0a:	01248d63          	beq	s1,s2,80003d24 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d0e:	408c                	lw	a1,0(s1)
    80003d10:	dde5                	beqz	a1,80003d08 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d12:	0009a503          	lw	a0,0(s3)
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	8fc080e7          	jalr	-1796(ra) # 80003612 <bfree>
      ip->addrs[i] = 0;
    80003d1e:	0004a023          	sw	zero,0(s1)
    80003d22:	b7dd                	j	80003d08 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d24:	0809a583          	lw	a1,128(s3)
    80003d28:	e185                	bnez	a1,80003d48 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d2a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d2e:	854e                	mv	a0,s3
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	de2080e7          	jalr	-542(ra) # 80003b12 <iupdate>
}
    80003d38:	70a2                	ld	ra,40(sp)
    80003d3a:	7402                	ld	s0,32(sp)
    80003d3c:	64e2                	ld	s1,24(sp)
    80003d3e:	6942                	ld	s2,16(sp)
    80003d40:	69a2                	ld	s3,8(sp)
    80003d42:	6a02                	ld	s4,0(sp)
    80003d44:	6145                	addi	sp,sp,48
    80003d46:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d48:	0009a503          	lw	a0,0(s3)
    80003d4c:	fffff097          	auipc	ra,0xfffff
    80003d50:	682080e7          	jalr	1666(ra) # 800033ce <bread>
    80003d54:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d56:	05850493          	addi	s1,a0,88
    80003d5a:	45850913          	addi	s2,a0,1112
    80003d5e:	a021                	j	80003d66 <itrunc+0x7a>
    80003d60:	0491                	addi	s1,s1,4
    80003d62:	01248b63          	beq	s1,s2,80003d78 <itrunc+0x8c>
      if(a[j])
    80003d66:	408c                	lw	a1,0(s1)
    80003d68:	dde5                	beqz	a1,80003d60 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d6a:	0009a503          	lw	a0,0(s3)
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	8a4080e7          	jalr	-1884(ra) # 80003612 <bfree>
    80003d76:	b7ed                	j	80003d60 <itrunc+0x74>
    brelse(bp);
    80003d78:	8552                	mv	a0,s4
    80003d7a:	fffff097          	auipc	ra,0xfffff
    80003d7e:	784080e7          	jalr	1924(ra) # 800034fe <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d82:	0809a583          	lw	a1,128(s3)
    80003d86:	0009a503          	lw	a0,0(s3)
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	888080e7          	jalr	-1912(ra) # 80003612 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d92:	0809a023          	sw	zero,128(s3)
    80003d96:	bf51                	j	80003d2a <itrunc+0x3e>

0000000080003d98 <iput>:
{
    80003d98:	1101                	addi	sp,sp,-32
    80003d9a:	ec06                	sd	ra,24(sp)
    80003d9c:	e822                	sd	s0,16(sp)
    80003d9e:	e426                	sd	s1,8(sp)
    80003da0:	e04a                	sd	s2,0(sp)
    80003da2:	1000                	addi	s0,sp,32
    80003da4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003da6:	0001d517          	auipc	a0,0x1d
    80003daa:	ba250513          	addi	a0,a0,-1118 # 80020948 <itable>
    80003dae:	ffffd097          	auipc	ra,0xffffd
    80003db2:	e24080e7          	jalr	-476(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003db6:	4498                	lw	a4,8(s1)
    80003db8:	4785                	li	a5,1
    80003dba:	02f70363          	beq	a4,a5,80003de0 <iput+0x48>
  ip->ref--;
    80003dbe:	449c                	lw	a5,8(s1)
    80003dc0:	37fd                	addiw	a5,a5,-1
    80003dc2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dc4:	0001d517          	auipc	a0,0x1d
    80003dc8:	b8450513          	addi	a0,a0,-1148 # 80020948 <itable>
    80003dcc:	ffffd097          	auipc	ra,0xffffd
    80003dd0:	eba080e7          	jalr	-326(ra) # 80000c86 <release>
}
    80003dd4:	60e2                	ld	ra,24(sp)
    80003dd6:	6442                	ld	s0,16(sp)
    80003dd8:	64a2                	ld	s1,8(sp)
    80003dda:	6902                	ld	s2,0(sp)
    80003ddc:	6105                	addi	sp,sp,32
    80003dde:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003de0:	40bc                	lw	a5,64(s1)
    80003de2:	dff1                	beqz	a5,80003dbe <iput+0x26>
    80003de4:	04a49783          	lh	a5,74(s1)
    80003de8:	fbf9                	bnez	a5,80003dbe <iput+0x26>
    acquiresleep(&ip->lock);
    80003dea:	01048913          	addi	s2,s1,16
    80003dee:	854a                	mv	a0,s2
    80003df0:	00001097          	auipc	ra,0x1
    80003df4:	a84080e7          	jalr	-1404(ra) # 80004874 <acquiresleep>
    release(&itable.lock);
    80003df8:	0001d517          	auipc	a0,0x1d
    80003dfc:	b5050513          	addi	a0,a0,-1200 # 80020948 <itable>
    80003e00:	ffffd097          	auipc	ra,0xffffd
    80003e04:	e86080e7          	jalr	-378(ra) # 80000c86 <release>
    itrunc(ip);
    80003e08:	8526                	mv	a0,s1
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	ee2080e7          	jalr	-286(ra) # 80003cec <itrunc>
    ip->type = 0;
    80003e12:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e16:	8526                	mv	a0,s1
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	cfa080e7          	jalr	-774(ra) # 80003b12 <iupdate>
    ip->valid = 0;
    80003e20:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e24:	854a                	mv	a0,s2
    80003e26:	00001097          	auipc	ra,0x1
    80003e2a:	aa4080e7          	jalr	-1372(ra) # 800048ca <releasesleep>
    acquire(&itable.lock);
    80003e2e:	0001d517          	auipc	a0,0x1d
    80003e32:	b1a50513          	addi	a0,a0,-1254 # 80020948 <itable>
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	d9c080e7          	jalr	-612(ra) # 80000bd2 <acquire>
    80003e3e:	b741                	j	80003dbe <iput+0x26>

0000000080003e40 <iunlockput>:
{
    80003e40:	1101                	addi	sp,sp,-32
    80003e42:	ec06                	sd	ra,24(sp)
    80003e44:	e822                	sd	s0,16(sp)
    80003e46:	e426                	sd	s1,8(sp)
    80003e48:	1000                	addi	s0,sp,32
    80003e4a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	e54080e7          	jalr	-428(ra) # 80003ca0 <iunlock>
  iput(ip);
    80003e54:	8526                	mv	a0,s1
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	f42080e7          	jalr	-190(ra) # 80003d98 <iput>
}
    80003e5e:	60e2                	ld	ra,24(sp)
    80003e60:	6442                	ld	s0,16(sp)
    80003e62:	64a2                	ld	s1,8(sp)
    80003e64:	6105                	addi	sp,sp,32
    80003e66:	8082                	ret

0000000080003e68 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e68:	1141                	addi	sp,sp,-16
    80003e6a:	e422                	sd	s0,8(sp)
    80003e6c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e6e:	411c                	lw	a5,0(a0)
    80003e70:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e72:	415c                	lw	a5,4(a0)
    80003e74:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e76:	04451783          	lh	a5,68(a0)
    80003e7a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e7e:	04a51783          	lh	a5,74(a0)
    80003e82:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e86:	04c56783          	lwu	a5,76(a0)
    80003e8a:	e99c                	sd	a5,16(a1)
}
    80003e8c:	6422                	ld	s0,8(sp)
    80003e8e:	0141                	addi	sp,sp,16
    80003e90:	8082                	ret

0000000080003e92 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e92:	457c                	lw	a5,76(a0)
    80003e94:	0ed7e963          	bltu	a5,a3,80003f86 <readi+0xf4>
{
    80003e98:	7159                	addi	sp,sp,-112
    80003e9a:	f486                	sd	ra,104(sp)
    80003e9c:	f0a2                	sd	s0,96(sp)
    80003e9e:	eca6                	sd	s1,88(sp)
    80003ea0:	e8ca                	sd	s2,80(sp)
    80003ea2:	e4ce                	sd	s3,72(sp)
    80003ea4:	e0d2                	sd	s4,64(sp)
    80003ea6:	fc56                	sd	s5,56(sp)
    80003ea8:	f85a                	sd	s6,48(sp)
    80003eaa:	f45e                	sd	s7,40(sp)
    80003eac:	f062                	sd	s8,32(sp)
    80003eae:	ec66                	sd	s9,24(sp)
    80003eb0:	e86a                	sd	s10,16(sp)
    80003eb2:	e46e                	sd	s11,8(sp)
    80003eb4:	1880                	addi	s0,sp,112
    80003eb6:	8b2a                	mv	s6,a0
    80003eb8:	8bae                	mv	s7,a1
    80003eba:	8a32                	mv	s4,a2
    80003ebc:	84b6                	mv	s1,a3
    80003ebe:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ec0:	9f35                	addw	a4,a4,a3
    return 0;
    80003ec2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ec4:	0ad76063          	bltu	a4,a3,80003f64 <readi+0xd2>
  if(off + n > ip->size)
    80003ec8:	00e7f463          	bgeu	a5,a4,80003ed0 <readi+0x3e>
    n = ip->size - off;
    80003ecc:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ed0:	0a0a8963          	beqz	s5,80003f82 <readi+0xf0>
    80003ed4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ed6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003eda:	5c7d                	li	s8,-1
    80003edc:	a82d                	j	80003f16 <readi+0x84>
    80003ede:	020d1d93          	slli	s11,s10,0x20
    80003ee2:	020ddd93          	srli	s11,s11,0x20
    80003ee6:	05890613          	addi	a2,s2,88
    80003eea:	86ee                	mv	a3,s11
    80003eec:	963a                	add	a2,a2,a4
    80003eee:	85d2                	mv	a1,s4
    80003ef0:	855e                	mv	a0,s7
    80003ef2:	ffffe097          	auipc	ra,0xffffe
    80003ef6:	7b6080e7          	jalr	1974(ra) # 800026a8 <either_copyout>
    80003efa:	05850d63          	beq	a0,s8,80003f54 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003efe:	854a                	mv	a0,s2
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	5fe080e7          	jalr	1534(ra) # 800034fe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f08:	013d09bb          	addw	s3,s10,s3
    80003f0c:	009d04bb          	addw	s1,s10,s1
    80003f10:	9a6e                	add	s4,s4,s11
    80003f12:	0559f763          	bgeu	s3,s5,80003f60 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f16:	00a4d59b          	srliw	a1,s1,0xa
    80003f1a:	855a                	mv	a0,s6
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	8a4080e7          	jalr	-1884(ra) # 800037c0 <bmap>
    80003f24:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f28:	cd85                	beqz	a1,80003f60 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f2a:	000b2503          	lw	a0,0(s6)
    80003f2e:	fffff097          	auipc	ra,0xfffff
    80003f32:	4a0080e7          	jalr	1184(ra) # 800033ce <bread>
    80003f36:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f38:	3ff4f713          	andi	a4,s1,1023
    80003f3c:	40ec87bb          	subw	a5,s9,a4
    80003f40:	413a86bb          	subw	a3,s5,s3
    80003f44:	8d3e                	mv	s10,a5
    80003f46:	2781                	sext.w	a5,a5
    80003f48:	0006861b          	sext.w	a2,a3
    80003f4c:	f8f679e3          	bgeu	a2,a5,80003ede <readi+0x4c>
    80003f50:	8d36                	mv	s10,a3
    80003f52:	b771                	j	80003ede <readi+0x4c>
      brelse(bp);
    80003f54:	854a                	mv	a0,s2
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	5a8080e7          	jalr	1448(ra) # 800034fe <brelse>
      tot = -1;
    80003f5e:	59fd                	li	s3,-1
  }
  return tot;
    80003f60:	0009851b          	sext.w	a0,s3
}
    80003f64:	70a6                	ld	ra,104(sp)
    80003f66:	7406                	ld	s0,96(sp)
    80003f68:	64e6                	ld	s1,88(sp)
    80003f6a:	6946                	ld	s2,80(sp)
    80003f6c:	69a6                	ld	s3,72(sp)
    80003f6e:	6a06                	ld	s4,64(sp)
    80003f70:	7ae2                	ld	s5,56(sp)
    80003f72:	7b42                	ld	s6,48(sp)
    80003f74:	7ba2                	ld	s7,40(sp)
    80003f76:	7c02                	ld	s8,32(sp)
    80003f78:	6ce2                	ld	s9,24(sp)
    80003f7a:	6d42                	ld	s10,16(sp)
    80003f7c:	6da2                	ld	s11,8(sp)
    80003f7e:	6165                	addi	sp,sp,112
    80003f80:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f82:	89d6                	mv	s3,s5
    80003f84:	bff1                	j	80003f60 <readi+0xce>
    return 0;
    80003f86:	4501                	li	a0,0
}
    80003f88:	8082                	ret

0000000080003f8a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f8a:	457c                	lw	a5,76(a0)
    80003f8c:	10d7e863          	bltu	a5,a3,8000409c <writei+0x112>
{
    80003f90:	7159                	addi	sp,sp,-112
    80003f92:	f486                	sd	ra,104(sp)
    80003f94:	f0a2                	sd	s0,96(sp)
    80003f96:	eca6                	sd	s1,88(sp)
    80003f98:	e8ca                	sd	s2,80(sp)
    80003f9a:	e4ce                	sd	s3,72(sp)
    80003f9c:	e0d2                	sd	s4,64(sp)
    80003f9e:	fc56                	sd	s5,56(sp)
    80003fa0:	f85a                	sd	s6,48(sp)
    80003fa2:	f45e                	sd	s7,40(sp)
    80003fa4:	f062                	sd	s8,32(sp)
    80003fa6:	ec66                	sd	s9,24(sp)
    80003fa8:	e86a                	sd	s10,16(sp)
    80003faa:	e46e                	sd	s11,8(sp)
    80003fac:	1880                	addi	s0,sp,112
    80003fae:	8aaa                	mv	s5,a0
    80003fb0:	8bae                	mv	s7,a1
    80003fb2:	8a32                	mv	s4,a2
    80003fb4:	8936                	mv	s2,a3
    80003fb6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fb8:	00e687bb          	addw	a5,a3,a4
    80003fbc:	0ed7e263          	bltu	a5,a3,800040a0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fc0:	00043737          	lui	a4,0x43
    80003fc4:	0ef76063          	bltu	a4,a5,800040a4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fc8:	0c0b0863          	beqz	s6,80004098 <writei+0x10e>
    80003fcc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fce:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fd2:	5c7d                	li	s8,-1
    80003fd4:	a091                	j	80004018 <writei+0x8e>
    80003fd6:	020d1d93          	slli	s11,s10,0x20
    80003fda:	020ddd93          	srli	s11,s11,0x20
    80003fde:	05848513          	addi	a0,s1,88
    80003fe2:	86ee                	mv	a3,s11
    80003fe4:	8652                	mv	a2,s4
    80003fe6:	85de                	mv	a1,s7
    80003fe8:	953a                	add	a0,a0,a4
    80003fea:	ffffe097          	auipc	ra,0xffffe
    80003fee:	714080e7          	jalr	1812(ra) # 800026fe <either_copyin>
    80003ff2:	07850263          	beq	a0,s8,80004056 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ff6:	8526                	mv	a0,s1
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	75e080e7          	jalr	1886(ra) # 80004756 <log_write>
    brelse(bp);
    80004000:	8526                	mv	a0,s1
    80004002:	fffff097          	auipc	ra,0xfffff
    80004006:	4fc080e7          	jalr	1276(ra) # 800034fe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000400a:	013d09bb          	addw	s3,s10,s3
    8000400e:	012d093b          	addw	s2,s10,s2
    80004012:	9a6e                	add	s4,s4,s11
    80004014:	0569f663          	bgeu	s3,s6,80004060 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004018:	00a9559b          	srliw	a1,s2,0xa
    8000401c:	8556                	mv	a0,s5
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	7a2080e7          	jalr	1954(ra) # 800037c0 <bmap>
    80004026:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000402a:	c99d                	beqz	a1,80004060 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000402c:	000aa503          	lw	a0,0(s5)
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	39e080e7          	jalr	926(ra) # 800033ce <bread>
    80004038:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000403a:	3ff97713          	andi	a4,s2,1023
    8000403e:	40ec87bb          	subw	a5,s9,a4
    80004042:	413b06bb          	subw	a3,s6,s3
    80004046:	8d3e                	mv	s10,a5
    80004048:	2781                	sext.w	a5,a5
    8000404a:	0006861b          	sext.w	a2,a3
    8000404e:	f8f674e3          	bgeu	a2,a5,80003fd6 <writei+0x4c>
    80004052:	8d36                	mv	s10,a3
    80004054:	b749                	j	80003fd6 <writei+0x4c>
      brelse(bp);
    80004056:	8526                	mv	a0,s1
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	4a6080e7          	jalr	1190(ra) # 800034fe <brelse>
  }

  if(off > ip->size)
    80004060:	04caa783          	lw	a5,76(s5)
    80004064:	0127f463          	bgeu	a5,s2,8000406c <writei+0xe2>
    ip->size = off;
    80004068:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000406c:	8556                	mv	a0,s5
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	aa4080e7          	jalr	-1372(ra) # 80003b12 <iupdate>

  return tot;
    80004076:	0009851b          	sext.w	a0,s3
}
    8000407a:	70a6                	ld	ra,104(sp)
    8000407c:	7406                	ld	s0,96(sp)
    8000407e:	64e6                	ld	s1,88(sp)
    80004080:	6946                	ld	s2,80(sp)
    80004082:	69a6                	ld	s3,72(sp)
    80004084:	6a06                	ld	s4,64(sp)
    80004086:	7ae2                	ld	s5,56(sp)
    80004088:	7b42                	ld	s6,48(sp)
    8000408a:	7ba2                	ld	s7,40(sp)
    8000408c:	7c02                	ld	s8,32(sp)
    8000408e:	6ce2                	ld	s9,24(sp)
    80004090:	6d42                	ld	s10,16(sp)
    80004092:	6da2                	ld	s11,8(sp)
    80004094:	6165                	addi	sp,sp,112
    80004096:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004098:	89da                	mv	s3,s6
    8000409a:	bfc9                	j	8000406c <writei+0xe2>
    return -1;
    8000409c:	557d                	li	a0,-1
}
    8000409e:	8082                	ret
    return -1;
    800040a0:	557d                	li	a0,-1
    800040a2:	bfe1                	j	8000407a <writei+0xf0>
    return -1;
    800040a4:	557d                	li	a0,-1
    800040a6:	bfd1                	j	8000407a <writei+0xf0>

00000000800040a8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040a8:	1141                	addi	sp,sp,-16
    800040aa:	e406                	sd	ra,8(sp)
    800040ac:	e022                	sd	s0,0(sp)
    800040ae:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040b0:	4639                	li	a2,14
    800040b2:	ffffd097          	auipc	ra,0xffffd
    800040b6:	cec080e7          	jalr	-788(ra) # 80000d9e <strncmp>
}
    800040ba:	60a2                	ld	ra,8(sp)
    800040bc:	6402                	ld	s0,0(sp)
    800040be:	0141                	addi	sp,sp,16
    800040c0:	8082                	ret

00000000800040c2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040c2:	7139                	addi	sp,sp,-64
    800040c4:	fc06                	sd	ra,56(sp)
    800040c6:	f822                	sd	s0,48(sp)
    800040c8:	f426                	sd	s1,40(sp)
    800040ca:	f04a                	sd	s2,32(sp)
    800040cc:	ec4e                	sd	s3,24(sp)
    800040ce:	e852                	sd	s4,16(sp)
    800040d0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040d2:	04451703          	lh	a4,68(a0)
    800040d6:	4785                	li	a5,1
    800040d8:	00f71a63          	bne	a4,a5,800040ec <dirlookup+0x2a>
    800040dc:	892a                	mv	s2,a0
    800040de:	89ae                	mv	s3,a1
    800040e0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e2:	457c                	lw	a5,76(a0)
    800040e4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040e6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e8:	e79d                	bnez	a5,80004116 <dirlookup+0x54>
    800040ea:	a8a5                	j	80004162 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040ec:	00004517          	auipc	a0,0x4
    800040f0:	56c50513          	addi	a0,a0,1388 # 80008658 <syscalls+0x1c0>
    800040f4:	ffffc097          	auipc	ra,0xffffc
    800040f8:	448080e7          	jalr	1096(ra) # 8000053c <panic>
      panic("dirlookup read");
    800040fc:	00004517          	auipc	a0,0x4
    80004100:	57450513          	addi	a0,a0,1396 # 80008670 <syscalls+0x1d8>
    80004104:	ffffc097          	auipc	ra,0xffffc
    80004108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000410c:	24c1                	addiw	s1,s1,16
    8000410e:	04c92783          	lw	a5,76(s2)
    80004112:	04f4f763          	bgeu	s1,a5,80004160 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004116:	4741                	li	a4,16
    80004118:	86a6                	mv	a3,s1
    8000411a:	fc040613          	addi	a2,s0,-64
    8000411e:	4581                	li	a1,0
    80004120:	854a                	mv	a0,s2
    80004122:	00000097          	auipc	ra,0x0
    80004126:	d70080e7          	jalr	-656(ra) # 80003e92 <readi>
    8000412a:	47c1                	li	a5,16
    8000412c:	fcf518e3          	bne	a0,a5,800040fc <dirlookup+0x3a>
    if(de.inum == 0)
    80004130:	fc045783          	lhu	a5,-64(s0)
    80004134:	dfe1                	beqz	a5,8000410c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004136:	fc240593          	addi	a1,s0,-62
    8000413a:	854e                	mv	a0,s3
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	f6c080e7          	jalr	-148(ra) # 800040a8 <namecmp>
    80004144:	f561                	bnez	a0,8000410c <dirlookup+0x4a>
      if(poff)
    80004146:	000a0463          	beqz	s4,8000414e <dirlookup+0x8c>
        *poff = off;
    8000414a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000414e:	fc045583          	lhu	a1,-64(s0)
    80004152:	00092503          	lw	a0,0(s2)
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	754080e7          	jalr	1876(ra) # 800038aa <iget>
    8000415e:	a011                	j	80004162 <dirlookup+0xa0>
  return 0;
    80004160:	4501                	li	a0,0
}
    80004162:	70e2                	ld	ra,56(sp)
    80004164:	7442                	ld	s0,48(sp)
    80004166:	74a2                	ld	s1,40(sp)
    80004168:	7902                	ld	s2,32(sp)
    8000416a:	69e2                	ld	s3,24(sp)
    8000416c:	6a42                	ld	s4,16(sp)
    8000416e:	6121                	addi	sp,sp,64
    80004170:	8082                	ret

0000000080004172 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004172:	711d                	addi	sp,sp,-96
    80004174:	ec86                	sd	ra,88(sp)
    80004176:	e8a2                	sd	s0,80(sp)
    80004178:	e4a6                	sd	s1,72(sp)
    8000417a:	e0ca                	sd	s2,64(sp)
    8000417c:	fc4e                	sd	s3,56(sp)
    8000417e:	f852                	sd	s4,48(sp)
    80004180:	f456                	sd	s5,40(sp)
    80004182:	f05a                	sd	s6,32(sp)
    80004184:	ec5e                	sd	s7,24(sp)
    80004186:	e862                	sd	s8,16(sp)
    80004188:	e466                	sd	s9,8(sp)
    8000418a:	1080                	addi	s0,sp,96
    8000418c:	84aa                	mv	s1,a0
    8000418e:	8b2e                	mv	s6,a1
    80004190:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004192:	00054703          	lbu	a4,0(a0)
    80004196:	02f00793          	li	a5,47
    8000419a:	02f70263          	beq	a4,a5,800041be <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000419e:	ffffe097          	auipc	ra,0xffffe
    800041a2:	830080e7          	jalr	-2000(ra) # 800019ce <myproc>
    800041a6:	15053503          	ld	a0,336(a0)
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	9f6080e7          	jalr	-1546(ra) # 80003ba0 <idup>
    800041b2:	8a2a                	mv	s4,a0
  while(*path == '/')
    800041b4:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800041b8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041ba:	4b85                	li	s7,1
    800041bc:	a875                	j	80004278 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800041be:	4585                	li	a1,1
    800041c0:	4505                	li	a0,1
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	6e8080e7          	jalr	1768(ra) # 800038aa <iget>
    800041ca:	8a2a                	mv	s4,a0
    800041cc:	b7e5                	j	800041b4 <namex+0x42>
      iunlockput(ip);
    800041ce:	8552                	mv	a0,s4
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	c70080e7          	jalr	-912(ra) # 80003e40 <iunlockput>
      return 0;
    800041d8:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041da:	8552                	mv	a0,s4
    800041dc:	60e6                	ld	ra,88(sp)
    800041de:	6446                	ld	s0,80(sp)
    800041e0:	64a6                	ld	s1,72(sp)
    800041e2:	6906                	ld	s2,64(sp)
    800041e4:	79e2                	ld	s3,56(sp)
    800041e6:	7a42                	ld	s4,48(sp)
    800041e8:	7aa2                	ld	s5,40(sp)
    800041ea:	7b02                	ld	s6,32(sp)
    800041ec:	6be2                	ld	s7,24(sp)
    800041ee:	6c42                	ld	s8,16(sp)
    800041f0:	6ca2                	ld	s9,8(sp)
    800041f2:	6125                	addi	sp,sp,96
    800041f4:	8082                	ret
      iunlock(ip);
    800041f6:	8552                	mv	a0,s4
    800041f8:	00000097          	auipc	ra,0x0
    800041fc:	aa8080e7          	jalr	-1368(ra) # 80003ca0 <iunlock>
      return ip;
    80004200:	bfe9                	j	800041da <namex+0x68>
      iunlockput(ip);
    80004202:	8552                	mv	a0,s4
    80004204:	00000097          	auipc	ra,0x0
    80004208:	c3c080e7          	jalr	-964(ra) # 80003e40 <iunlockput>
      return 0;
    8000420c:	8a4e                	mv	s4,s3
    8000420e:	b7f1                	j	800041da <namex+0x68>
  len = path - s;
    80004210:	40998633          	sub	a2,s3,s1
    80004214:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004218:	099c5863          	bge	s8,s9,800042a8 <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000421c:	4639                	li	a2,14
    8000421e:	85a6                	mv	a1,s1
    80004220:	8556                	mv	a0,s5
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	b08080e7          	jalr	-1272(ra) # 80000d2a <memmove>
    8000422a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000422c:	0004c783          	lbu	a5,0(s1)
    80004230:	01279763          	bne	a5,s2,8000423e <namex+0xcc>
    path++;
    80004234:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004236:	0004c783          	lbu	a5,0(s1)
    8000423a:	ff278de3          	beq	a5,s2,80004234 <namex+0xc2>
    ilock(ip);
    8000423e:	8552                	mv	a0,s4
    80004240:	00000097          	auipc	ra,0x0
    80004244:	99e080e7          	jalr	-1634(ra) # 80003bde <ilock>
    if(ip->type != T_DIR){
    80004248:	044a1783          	lh	a5,68(s4)
    8000424c:	f97791e3          	bne	a5,s7,800041ce <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004250:	000b0563          	beqz	s6,8000425a <namex+0xe8>
    80004254:	0004c783          	lbu	a5,0(s1)
    80004258:	dfd9                	beqz	a5,800041f6 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000425a:	4601                	li	a2,0
    8000425c:	85d6                	mv	a1,s5
    8000425e:	8552                	mv	a0,s4
    80004260:	00000097          	auipc	ra,0x0
    80004264:	e62080e7          	jalr	-414(ra) # 800040c2 <dirlookup>
    80004268:	89aa                	mv	s3,a0
    8000426a:	dd41                	beqz	a0,80004202 <namex+0x90>
    iunlockput(ip);
    8000426c:	8552                	mv	a0,s4
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	bd2080e7          	jalr	-1070(ra) # 80003e40 <iunlockput>
    ip = next;
    80004276:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004278:	0004c783          	lbu	a5,0(s1)
    8000427c:	01279763          	bne	a5,s2,8000428a <namex+0x118>
    path++;
    80004280:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004282:	0004c783          	lbu	a5,0(s1)
    80004286:	ff278de3          	beq	a5,s2,80004280 <namex+0x10e>
  if(*path == 0)
    8000428a:	cb9d                	beqz	a5,800042c0 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000428c:	0004c783          	lbu	a5,0(s1)
    80004290:	89a6                	mv	s3,s1
  len = path - s;
    80004292:	4c81                	li	s9,0
    80004294:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004296:	01278963          	beq	a5,s2,800042a8 <namex+0x136>
    8000429a:	dbbd                	beqz	a5,80004210 <namex+0x9e>
    path++;
    8000429c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000429e:	0009c783          	lbu	a5,0(s3)
    800042a2:	ff279ce3          	bne	a5,s2,8000429a <namex+0x128>
    800042a6:	b7ad                	j	80004210 <namex+0x9e>
    memmove(name, s, len);
    800042a8:	2601                	sext.w	a2,a2
    800042aa:	85a6                	mv	a1,s1
    800042ac:	8556                	mv	a0,s5
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	a7c080e7          	jalr	-1412(ra) # 80000d2a <memmove>
    name[len] = 0;
    800042b6:	9cd6                	add	s9,s9,s5
    800042b8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800042bc:	84ce                	mv	s1,s3
    800042be:	b7bd                	j	8000422c <namex+0xba>
  if(nameiparent){
    800042c0:	f00b0de3          	beqz	s6,800041da <namex+0x68>
    iput(ip);
    800042c4:	8552                	mv	a0,s4
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	ad2080e7          	jalr	-1326(ra) # 80003d98 <iput>
    return 0;
    800042ce:	4a01                	li	s4,0
    800042d0:	b729                	j	800041da <namex+0x68>

00000000800042d2 <dirlink>:
{
    800042d2:	7139                	addi	sp,sp,-64
    800042d4:	fc06                	sd	ra,56(sp)
    800042d6:	f822                	sd	s0,48(sp)
    800042d8:	f426                	sd	s1,40(sp)
    800042da:	f04a                	sd	s2,32(sp)
    800042dc:	ec4e                	sd	s3,24(sp)
    800042de:	e852                	sd	s4,16(sp)
    800042e0:	0080                	addi	s0,sp,64
    800042e2:	892a                	mv	s2,a0
    800042e4:	8a2e                	mv	s4,a1
    800042e6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042e8:	4601                	li	a2,0
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	dd8080e7          	jalr	-552(ra) # 800040c2 <dirlookup>
    800042f2:	e93d                	bnez	a0,80004368 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f4:	04c92483          	lw	s1,76(s2)
    800042f8:	c49d                	beqz	s1,80004326 <dirlink+0x54>
    800042fa:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042fc:	4741                	li	a4,16
    800042fe:	86a6                	mv	a3,s1
    80004300:	fc040613          	addi	a2,s0,-64
    80004304:	4581                	li	a1,0
    80004306:	854a                	mv	a0,s2
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	b8a080e7          	jalr	-1142(ra) # 80003e92 <readi>
    80004310:	47c1                	li	a5,16
    80004312:	06f51163          	bne	a0,a5,80004374 <dirlink+0xa2>
    if(de.inum == 0)
    80004316:	fc045783          	lhu	a5,-64(s0)
    8000431a:	c791                	beqz	a5,80004326 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000431c:	24c1                	addiw	s1,s1,16
    8000431e:	04c92783          	lw	a5,76(s2)
    80004322:	fcf4ede3          	bltu	s1,a5,800042fc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004326:	4639                	li	a2,14
    80004328:	85d2                	mv	a1,s4
    8000432a:	fc240513          	addi	a0,s0,-62
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	aac080e7          	jalr	-1364(ra) # 80000dda <strncpy>
  de.inum = inum;
    80004336:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000433a:	4741                	li	a4,16
    8000433c:	86a6                	mv	a3,s1
    8000433e:	fc040613          	addi	a2,s0,-64
    80004342:	4581                	li	a1,0
    80004344:	854a                	mv	a0,s2
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	c44080e7          	jalr	-956(ra) # 80003f8a <writei>
    8000434e:	1541                	addi	a0,a0,-16
    80004350:	00a03533          	snez	a0,a0
    80004354:	40a00533          	neg	a0,a0
}
    80004358:	70e2                	ld	ra,56(sp)
    8000435a:	7442                	ld	s0,48(sp)
    8000435c:	74a2                	ld	s1,40(sp)
    8000435e:	7902                	ld	s2,32(sp)
    80004360:	69e2                	ld	s3,24(sp)
    80004362:	6a42                	ld	s4,16(sp)
    80004364:	6121                	addi	sp,sp,64
    80004366:	8082                	ret
    iput(ip);
    80004368:	00000097          	auipc	ra,0x0
    8000436c:	a30080e7          	jalr	-1488(ra) # 80003d98 <iput>
    return -1;
    80004370:	557d                	li	a0,-1
    80004372:	b7dd                	j	80004358 <dirlink+0x86>
      panic("dirlink read");
    80004374:	00004517          	auipc	a0,0x4
    80004378:	30c50513          	addi	a0,a0,780 # 80008680 <syscalls+0x1e8>
    8000437c:	ffffc097          	auipc	ra,0xffffc
    80004380:	1c0080e7          	jalr	448(ra) # 8000053c <panic>

0000000080004384 <namei>:

struct inode*
namei(char *path)
{
    80004384:	1101                	addi	sp,sp,-32
    80004386:	ec06                	sd	ra,24(sp)
    80004388:	e822                	sd	s0,16(sp)
    8000438a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000438c:	fe040613          	addi	a2,s0,-32
    80004390:	4581                	li	a1,0
    80004392:	00000097          	auipc	ra,0x0
    80004396:	de0080e7          	jalr	-544(ra) # 80004172 <namex>
}
    8000439a:	60e2                	ld	ra,24(sp)
    8000439c:	6442                	ld	s0,16(sp)
    8000439e:	6105                	addi	sp,sp,32
    800043a0:	8082                	ret

00000000800043a2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043a2:	1141                	addi	sp,sp,-16
    800043a4:	e406                	sd	ra,8(sp)
    800043a6:	e022                	sd	s0,0(sp)
    800043a8:	0800                	addi	s0,sp,16
    800043aa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043ac:	4585                	li	a1,1
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	dc4080e7          	jalr	-572(ra) # 80004172 <namex>
}
    800043b6:	60a2                	ld	ra,8(sp)
    800043b8:	6402                	ld	s0,0(sp)
    800043ba:	0141                	addi	sp,sp,16
    800043bc:	8082                	ret

00000000800043be <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043be:	1101                	addi	sp,sp,-32
    800043c0:	ec06                	sd	ra,24(sp)
    800043c2:	e822                	sd	s0,16(sp)
    800043c4:	e426                	sd	s1,8(sp)
    800043c6:	e04a                	sd	s2,0(sp)
    800043c8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043ca:	0001e917          	auipc	s2,0x1e
    800043ce:	02690913          	addi	s2,s2,38 # 800223f0 <log>
    800043d2:	01892583          	lw	a1,24(s2)
    800043d6:	02892503          	lw	a0,40(s2)
    800043da:	fffff097          	auipc	ra,0xfffff
    800043de:	ff4080e7          	jalr	-12(ra) # 800033ce <bread>
    800043e2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043e4:	02c92603          	lw	a2,44(s2)
    800043e8:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043ea:	00c05f63          	blez	a2,80004408 <write_head+0x4a>
    800043ee:	0001e717          	auipc	a4,0x1e
    800043f2:	03270713          	addi	a4,a4,50 # 80022420 <log+0x30>
    800043f6:	87aa                	mv	a5,a0
    800043f8:	060a                	slli	a2,a2,0x2
    800043fa:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800043fc:	4314                	lw	a3,0(a4)
    800043fe:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004400:	0711                	addi	a4,a4,4
    80004402:	0791                	addi	a5,a5,4
    80004404:	fec79ce3          	bne	a5,a2,800043fc <write_head+0x3e>
  }
  bwrite(buf);
    80004408:	8526                	mv	a0,s1
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	0b6080e7          	jalr	182(ra) # 800034c0 <bwrite>
  brelse(buf);
    80004412:	8526                	mv	a0,s1
    80004414:	fffff097          	auipc	ra,0xfffff
    80004418:	0ea080e7          	jalr	234(ra) # 800034fe <brelse>
}
    8000441c:	60e2                	ld	ra,24(sp)
    8000441e:	6442                	ld	s0,16(sp)
    80004420:	64a2                	ld	s1,8(sp)
    80004422:	6902                	ld	s2,0(sp)
    80004424:	6105                	addi	sp,sp,32
    80004426:	8082                	ret

0000000080004428 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004428:	0001e797          	auipc	a5,0x1e
    8000442c:	ff47a783          	lw	a5,-12(a5) # 8002241c <log+0x2c>
    80004430:	0af05d63          	blez	a5,800044ea <install_trans+0xc2>
{
    80004434:	7139                	addi	sp,sp,-64
    80004436:	fc06                	sd	ra,56(sp)
    80004438:	f822                	sd	s0,48(sp)
    8000443a:	f426                	sd	s1,40(sp)
    8000443c:	f04a                	sd	s2,32(sp)
    8000443e:	ec4e                	sd	s3,24(sp)
    80004440:	e852                	sd	s4,16(sp)
    80004442:	e456                	sd	s5,8(sp)
    80004444:	e05a                	sd	s6,0(sp)
    80004446:	0080                	addi	s0,sp,64
    80004448:	8b2a                	mv	s6,a0
    8000444a:	0001ea97          	auipc	s5,0x1e
    8000444e:	fd6a8a93          	addi	s5,s5,-42 # 80022420 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004452:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004454:	0001e997          	auipc	s3,0x1e
    80004458:	f9c98993          	addi	s3,s3,-100 # 800223f0 <log>
    8000445c:	a00d                	j	8000447e <install_trans+0x56>
    brelse(lbuf);
    8000445e:	854a                	mv	a0,s2
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	09e080e7          	jalr	158(ra) # 800034fe <brelse>
    brelse(dbuf);
    80004468:	8526                	mv	a0,s1
    8000446a:	fffff097          	auipc	ra,0xfffff
    8000446e:	094080e7          	jalr	148(ra) # 800034fe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004472:	2a05                	addiw	s4,s4,1
    80004474:	0a91                	addi	s5,s5,4
    80004476:	02c9a783          	lw	a5,44(s3)
    8000447a:	04fa5e63          	bge	s4,a5,800044d6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000447e:	0189a583          	lw	a1,24(s3)
    80004482:	014585bb          	addw	a1,a1,s4
    80004486:	2585                	addiw	a1,a1,1
    80004488:	0289a503          	lw	a0,40(s3)
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	f42080e7          	jalr	-190(ra) # 800033ce <bread>
    80004494:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004496:	000aa583          	lw	a1,0(s5)
    8000449a:	0289a503          	lw	a0,40(s3)
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	f30080e7          	jalr	-208(ra) # 800033ce <bread>
    800044a6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044a8:	40000613          	li	a2,1024
    800044ac:	05890593          	addi	a1,s2,88
    800044b0:	05850513          	addi	a0,a0,88
    800044b4:	ffffd097          	auipc	ra,0xffffd
    800044b8:	876080e7          	jalr	-1930(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    800044bc:	8526                	mv	a0,s1
    800044be:	fffff097          	auipc	ra,0xfffff
    800044c2:	002080e7          	jalr	2(ra) # 800034c0 <bwrite>
    if(recovering == 0)
    800044c6:	f80b1ce3          	bnez	s6,8000445e <install_trans+0x36>
      bunpin(dbuf);
    800044ca:	8526                	mv	a0,s1
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	10a080e7          	jalr	266(ra) # 800035d6 <bunpin>
    800044d4:	b769                	j	8000445e <install_trans+0x36>
}
    800044d6:	70e2                	ld	ra,56(sp)
    800044d8:	7442                	ld	s0,48(sp)
    800044da:	74a2                	ld	s1,40(sp)
    800044dc:	7902                	ld	s2,32(sp)
    800044de:	69e2                	ld	s3,24(sp)
    800044e0:	6a42                	ld	s4,16(sp)
    800044e2:	6aa2                	ld	s5,8(sp)
    800044e4:	6b02                	ld	s6,0(sp)
    800044e6:	6121                	addi	sp,sp,64
    800044e8:	8082                	ret
    800044ea:	8082                	ret

00000000800044ec <initlog>:
{
    800044ec:	7179                	addi	sp,sp,-48
    800044ee:	f406                	sd	ra,40(sp)
    800044f0:	f022                	sd	s0,32(sp)
    800044f2:	ec26                	sd	s1,24(sp)
    800044f4:	e84a                	sd	s2,16(sp)
    800044f6:	e44e                	sd	s3,8(sp)
    800044f8:	1800                	addi	s0,sp,48
    800044fa:	892a                	mv	s2,a0
    800044fc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044fe:	0001e497          	auipc	s1,0x1e
    80004502:	ef248493          	addi	s1,s1,-270 # 800223f0 <log>
    80004506:	00004597          	auipc	a1,0x4
    8000450a:	18a58593          	addi	a1,a1,394 # 80008690 <syscalls+0x1f8>
    8000450e:	8526                	mv	a0,s1
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	632080e7          	jalr	1586(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004518:	0149a583          	lw	a1,20(s3)
    8000451c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000451e:	0109a783          	lw	a5,16(s3)
    80004522:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004524:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004528:	854a                	mv	a0,s2
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	ea4080e7          	jalr	-348(ra) # 800033ce <bread>
  log.lh.n = lh->n;
    80004532:	4d30                	lw	a2,88(a0)
    80004534:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004536:	00c05f63          	blez	a2,80004554 <initlog+0x68>
    8000453a:	87aa                	mv	a5,a0
    8000453c:	0001e717          	auipc	a4,0x1e
    80004540:	ee470713          	addi	a4,a4,-284 # 80022420 <log+0x30>
    80004544:	060a                	slli	a2,a2,0x2
    80004546:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004548:	4ff4                	lw	a3,92(a5)
    8000454a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000454c:	0791                	addi	a5,a5,4
    8000454e:	0711                	addi	a4,a4,4
    80004550:	fec79ce3          	bne	a5,a2,80004548 <initlog+0x5c>
  brelse(buf);
    80004554:	fffff097          	auipc	ra,0xfffff
    80004558:	faa080e7          	jalr	-86(ra) # 800034fe <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000455c:	4505                	li	a0,1
    8000455e:	00000097          	auipc	ra,0x0
    80004562:	eca080e7          	jalr	-310(ra) # 80004428 <install_trans>
  log.lh.n = 0;
    80004566:	0001e797          	auipc	a5,0x1e
    8000456a:	ea07ab23          	sw	zero,-330(a5) # 8002241c <log+0x2c>
  write_head(); // clear the log
    8000456e:	00000097          	auipc	ra,0x0
    80004572:	e50080e7          	jalr	-432(ra) # 800043be <write_head>
}
    80004576:	70a2                	ld	ra,40(sp)
    80004578:	7402                	ld	s0,32(sp)
    8000457a:	64e2                	ld	s1,24(sp)
    8000457c:	6942                	ld	s2,16(sp)
    8000457e:	69a2                	ld	s3,8(sp)
    80004580:	6145                	addi	sp,sp,48
    80004582:	8082                	ret

0000000080004584 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004584:	1101                	addi	sp,sp,-32
    80004586:	ec06                	sd	ra,24(sp)
    80004588:	e822                	sd	s0,16(sp)
    8000458a:	e426                	sd	s1,8(sp)
    8000458c:	e04a                	sd	s2,0(sp)
    8000458e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004590:	0001e517          	auipc	a0,0x1e
    80004594:	e6050513          	addi	a0,a0,-416 # 800223f0 <log>
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	63a080e7          	jalr	1594(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    800045a0:	0001e497          	auipc	s1,0x1e
    800045a4:	e5048493          	addi	s1,s1,-432 # 800223f0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045a8:	4979                	li	s2,30
    800045aa:	a039                	j	800045b8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800045ac:	85a6                	mv	a1,s1
    800045ae:	8526                	mv	a0,s1
    800045b0:	ffffe097          	auipc	ra,0xffffe
    800045b4:	ce4080e7          	jalr	-796(ra) # 80002294 <sleep>
    if(log.committing){
    800045b8:	50dc                	lw	a5,36(s1)
    800045ba:	fbed                	bnez	a5,800045ac <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045bc:	5098                	lw	a4,32(s1)
    800045be:	2705                	addiw	a4,a4,1
    800045c0:	0027179b          	slliw	a5,a4,0x2
    800045c4:	9fb9                	addw	a5,a5,a4
    800045c6:	0017979b          	slliw	a5,a5,0x1
    800045ca:	54d4                	lw	a3,44(s1)
    800045cc:	9fb5                	addw	a5,a5,a3
    800045ce:	00f95963          	bge	s2,a5,800045e0 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045d2:	85a6                	mv	a1,s1
    800045d4:	8526                	mv	a0,s1
    800045d6:	ffffe097          	auipc	ra,0xffffe
    800045da:	cbe080e7          	jalr	-834(ra) # 80002294 <sleep>
    800045de:	bfe9                	j	800045b8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045e0:	0001e517          	auipc	a0,0x1e
    800045e4:	e1050513          	addi	a0,a0,-496 # 800223f0 <log>
    800045e8:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	69c080e7          	jalr	1692(ra) # 80000c86 <release>
      break;
    }
  }
}
    800045f2:	60e2                	ld	ra,24(sp)
    800045f4:	6442                	ld	s0,16(sp)
    800045f6:	64a2                	ld	s1,8(sp)
    800045f8:	6902                	ld	s2,0(sp)
    800045fa:	6105                	addi	sp,sp,32
    800045fc:	8082                	ret

00000000800045fe <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045fe:	7139                	addi	sp,sp,-64
    80004600:	fc06                	sd	ra,56(sp)
    80004602:	f822                	sd	s0,48(sp)
    80004604:	f426                	sd	s1,40(sp)
    80004606:	f04a                	sd	s2,32(sp)
    80004608:	ec4e                	sd	s3,24(sp)
    8000460a:	e852                	sd	s4,16(sp)
    8000460c:	e456                	sd	s5,8(sp)
    8000460e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004610:	0001e497          	auipc	s1,0x1e
    80004614:	de048493          	addi	s1,s1,-544 # 800223f0 <log>
    80004618:	8526                	mv	a0,s1
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	5b8080e7          	jalr	1464(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004622:	509c                	lw	a5,32(s1)
    80004624:	37fd                	addiw	a5,a5,-1
    80004626:	0007891b          	sext.w	s2,a5
    8000462a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000462c:	50dc                	lw	a5,36(s1)
    8000462e:	e7b9                	bnez	a5,8000467c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004630:	04091e63          	bnez	s2,8000468c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004634:	0001e497          	auipc	s1,0x1e
    80004638:	dbc48493          	addi	s1,s1,-580 # 800223f0 <log>
    8000463c:	4785                	li	a5,1
    8000463e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004640:	8526                	mv	a0,s1
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	644080e7          	jalr	1604(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000464a:	54dc                	lw	a5,44(s1)
    8000464c:	06f04763          	bgtz	a5,800046ba <end_op+0xbc>
    acquire(&log.lock);
    80004650:	0001e497          	auipc	s1,0x1e
    80004654:	da048493          	addi	s1,s1,-608 # 800223f0 <log>
    80004658:	8526                	mv	a0,s1
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	578080e7          	jalr	1400(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004662:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004666:	8526                	mv	a0,s1
    80004668:	ffffe097          	auipc	ra,0xffffe
    8000466c:	c90080e7          	jalr	-880(ra) # 800022f8 <wakeup>
    release(&log.lock);
    80004670:	8526                	mv	a0,s1
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	614080e7          	jalr	1556(ra) # 80000c86 <release>
}
    8000467a:	a03d                	j	800046a8 <end_op+0xaa>
    panic("log.committing");
    8000467c:	00004517          	auipc	a0,0x4
    80004680:	01c50513          	addi	a0,a0,28 # 80008698 <syscalls+0x200>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	eb8080e7          	jalr	-328(ra) # 8000053c <panic>
    wakeup(&log);
    8000468c:	0001e497          	auipc	s1,0x1e
    80004690:	d6448493          	addi	s1,s1,-668 # 800223f0 <log>
    80004694:	8526                	mv	a0,s1
    80004696:	ffffe097          	auipc	ra,0xffffe
    8000469a:	c62080e7          	jalr	-926(ra) # 800022f8 <wakeup>
  release(&log.lock);
    8000469e:	8526                	mv	a0,s1
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	5e6080e7          	jalr	1510(ra) # 80000c86 <release>
}
    800046a8:	70e2                	ld	ra,56(sp)
    800046aa:	7442                	ld	s0,48(sp)
    800046ac:	74a2                	ld	s1,40(sp)
    800046ae:	7902                	ld	s2,32(sp)
    800046b0:	69e2                	ld	s3,24(sp)
    800046b2:	6a42                	ld	s4,16(sp)
    800046b4:	6aa2                	ld	s5,8(sp)
    800046b6:	6121                	addi	sp,sp,64
    800046b8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ba:	0001ea97          	auipc	s5,0x1e
    800046be:	d66a8a93          	addi	s5,s5,-666 # 80022420 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046c2:	0001ea17          	auipc	s4,0x1e
    800046c6:	d2ea0a13          	addi	s4,s4,-722 # 800223f0 <log>
    800046ca:	018a2583          	lw	a1,24(s4)
    800046ce:	012585bb          	addw	a1,a1,s2
    800046d2:	2585                	addiw	a1,a1,1
    800046d4:	028a2503          	lw	a0,40(s4)
    800046d8:	fffff097          	auipc	ra,0xfffff
    800046dc:	cf6080e7          	jalr	-778(ra) # 800033ce <bread>
    800046e0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046e2:	000aa583          	lw	a1,0(s5)
    800046e6:	028a2503          	lw	a0,40(s4)
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	ce4080e7          	jalr	-796(ra) # 800033ce <bread>
    800046f2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046f4:	40000613          	li	a2,1024
    800046f8:	05850593          	addi	a1,a0,88
    800046fc:	05848513          	addi	a0,s1,88
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	62a080e7          	jalr	1578(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004708:	8526                	mv	a0,s1
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	db6080e7          	jalr	-586(ra) # 800034c0 <bwrite>
    brelse(from);
    80004712:	854e                	mv	a0,s3
    80004714:	fffff097          	auipc	ra,0xfffff
    80004718:	dea080e7          	jalr	-534(ra) # 800034fe <brelse>
    brelse(to);
    8000471c:	8526                	mv	a0,s1
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	de0080e7          	jalr	-544(ra) # 800034fe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004726:	2905                	addiw	s2,s2,1
    80004728:	0a91                	addi	s5,s5,4
    8000472a:	02ca2783          	lw	a5,44(s4)
    8000472e:	f8f94ee3          	blt	s2,a5,800046ca <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004732:	00000097          	auipc	ra,0x0
    80004736:	c8c080e7          	jalr	-884(ra) # 800043be <write_head>
    install_trans(0); // Now install writes to home locations
    8000473a:	4501                	li	a0,0
    8000473c:	00000097          	auipc	ra,0x0
    80004740:	cec080e7          	jalr	-788(ra) # 80004428 <install_trans>
    log.lh.n = 0;
    80004744:	0001e797          	auipc	a5,0x1e
    80004748:	cc07ac23          	sw	zero,-808(a5) # 8002241c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000474c:	00000097          	auipc	ra,0x0
    80004750:	c72080e7          	jalr	-910(ra) # 800043be <write_head>
    80004754:	bdf5                	j	80004650 <end_op+0x52>

0000000080004756 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004756:	1101                	addi	sp,sp,-32
    80004758:	ec06                	sd	ra,24(sp)
    8000475a:	e822                	sd	s0,16(sp)
    8000475c:	e426                	sd	s1,8(sp)
    8000475e:	e04a                	sd	s2,0(sp)
    80004760:	1000                	addi	s0,sp,32
    80004762:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004764:	0001e917          	auipc	s2,0x1e
    80004768:	c8c90913          	addi	s2,s2,-884 # 800223f0 <log>
    8000476c:	854a                	mv	a0,s2
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	464080e7          	jalr	1124(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004776:	02c92603          	lw	a2,44(s2)
    8000477a:	47f5                	li	a5,29
    8000477c:	06c7c563          	blt	a5,a2,800047e6 <log_write+0x90>
    80004780:	0001e797          	auipc	a5,0x1e
    80004784:	c8c7a783          	lw	a5,-884(a5) # 8002240c <log+0x1c>
    80004788:	37fd                	addiw	a5,a5,-1
    8000478a:	04f65e63          	bge	a2,a5,800047e6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000478e:	0001e797          	auipc	a5,0x1e
    80004792:	c827a783          	lw	a5,-894(a5) # 80022410 <log+0x20>
    80004796:	06f05063          	blez	a5,800047f6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000479a:	4781                	li	a5,0
    8000479c:	06c05563          	blez	a2,80004806 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047a0:	44cc                	lw	a1,12(s1)
    800047a2:	0001e717          	auipc	a4,0x1e
    800047a6:	c7e70713          	addi	a4,a4,-898 # 80022420 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047aa:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047ac:	4314                	lw	a3,0(a4)
    800047ae:	04b68c63          	beq	a3,a1,80004806 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047b2:	2785                	addiw	a5,a5,1
    800047b4:	0711                	addi	a4,a4,4
    800047b6:	fef61be3          	bne	a2,a5,800047ac <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047ba:	0621                	addi	a2,a2,8
    800047bc:	060a                	slli	a2,a2,0x2
    800047be:	0001e797          	auipc	a5,0x1e
    800047c2:	c3278793          	addi	a5,a5,-974 # 800223f0 <log>
    800047c6:	97b2                	add	a5,a5,a2
    800047c8:	44d8                	lw	a4,12(s1)
    800047ca:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047cc:	8526                	mv	a0,s1
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	dcc080e7          	jalr	-564(ra) # 8000359a <bpin>
    log.lh.n++;
    800047d6:	0001e717          	auipc	a4,0x1e
    800047da:	c1a70713          	addi	a4,a4,-998 # 800223f0 <log>
    800047de:	575c                	lw	a5,44(a4)
    800047e0:	2785                	addiw	a5,a5,1
    800047e2:	d75c                	sw	a5,44(a4)
    800047e4:	a82d                	j	8000481e <log_write+0xc8>
    panic("too big a transaction");
    800047e6:	00004517          	auipc	a0,0x4
    800047ea:	ec250513          	addi	a0,a0,-318 # 800086a8 <syscalls+0x210>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	d4e080e7          	jalr	-690(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800047f6:	00004517          	auipc	a0,0x4
    800047fa:	eca50513          	addi	a0,a0,-310 # 800086c0 <syscalls+0x228>
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	d3e080e7          	jalr	-706(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004806:	00878693          	addi	a3,a5,8
    8000480a:	068a                	slli	a3,a3,0x2
    8000480c:	0001e717          	auipc	a4,0x1e
    80004810:	be470713          	addi	a4,a4,-1052 # 800223f0 <log>
    80004814:	9736                	add	a4,a4,a3
    80004816:	44d4                	lw	a3,12(s1)
    80004818:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000481a:	faf609e3          	beq	a2,a5,800047cc <log_write+0x76>
  }
  release(&log.lock);
    8000481e:	0001e517          	auipc	a0,0x1e
    80004822:	bd250513          	addi	a0,a0,-1070 # 800223f0 <log>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	460080e7          	jalr	1120(ra) # 80000c86 <release>
}
    8000482e:	60e2                	ld	ra,24(sp)
    80004830:	6442                	ld	s0,16(sp)
    80004832:	64a2                	ld	s1,8(sp)
    80004834:	6902                	ld	s2,0(sp)
    80004836:	6105                	addi	sp,sp,32
    80004838:	8082                	ret

000000008000483a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000483a:	1101                	addi	sp,sp,-32
    8000483c:	ec06                	sd	ra,24(sp)
    8000483e:	e822                	sd	s0,16(sp)
    80004840:	e426                	sd	s1,8(sp)
    80004842:	e04a                	sd	s2,0(sp)
    80004844:	1000                	addi	s0,sp,32
    80004846:	84aa                	mv	s1,a0
    80004848:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000484a:	00004597          	auipc	a1,0x4
    8000484e:	e9658593          	addi	a1,a1,-362 # 800086e0 <syscalls+0x248>
    80004852:	0521                	addi	a0,a0,8
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	2ee080e7          	jalr	750(ra) # 80000b42 <initlock>
  lk->name = name;
    8000485c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004860:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004864:	0204a423          	sw	zero,40(s1)
}
    80004868:	60e2                	ld	ra,24(sp)
    8000486a:	6442                	ld	s0,16(sp)
    8000486c:	64a2                	ld	s1,8(sp)
    8000486e:	6902                	ld	s2,0(sp)
    80004870:	6105                	addi	sp,sp,32
    80004872:	8082                	ret

0000000080004874 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004874:	1101                	addi	sp,sp,-32
    80004876:	ec06                	sd	ra,24(sp)
    80004878:	e822                	sd	s0,16(sp)
    8000487a:	e426                	sd	s1,8(sp)
    8000487c:	e04a                	sd	s2,0(sp)
    8000487e:	1000                	addi	s0,sp,32
    80004880:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004882:	00850913          	addi	s2,a0,8
    80004886:	854a                	mv	a0,s2
    80004888:	ffffc097          	auipc	ra,0xffffc
    8000488c:	34a080e7          	jalr	842(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004890:	409c                	lw	a5,0(s1)
    80004892:	cb89                	beqz	a5,800048a4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004894:	85ca                	mv	a1,s2
    80004896:	8526                	mv	a0,s1
    80004898:	ffffe097          	auipc	ra,0xffffe
    8000489c:	9fc080e7          	jalr	-1540(ra) # 80002294 <sleep>
  while (lk->locked) {
    800048a0:	409c                	lw	a5,0(s1)
    800048a2:	fbed                	bnez	a5,80004894 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048a4:	4785                	li	a5,1
    800048a6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048a8:	ffffd097          	auipc	ra,0xffffd
    800048ac:	126080e7          	jalr	294(ra) # 800019ce <myproc>
    800048b0:	591c                	lw	a5,48(a0)
    800048b2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048b4:	854a                	mv	a0,s2
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	3d0080e7          	jalr	976(ra) # 80000c86 <release>
}
    800048be:	60e2                	ld	ra,24(sp)
    800048c0:	6442                	ld	s0,16(sp)
    800048c2:	64a2                	ld	s1,8(sp)
    800048c4:	6902                	ld	s2,0(sp)
    800048c6:	6105                	addi	sp,sp,32
    800048c8:	8082                	ret

00000000800048ca <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048ca:	1101                	addi	sp,sp,-32
    800048cc:	ec06                	sd	ra,24(sp)
    800048ce:	e822                	sd	s0,16(sp)
    800048d0:	e426                	sd	s1,8(sp)
    800048d2:	e04a                	sd	s2,0(sp)
    800048d4:	1000                	addi	s0,sp,32
    800048d6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048d8:	00850913          	addi	s2,a0,8
    800048dc:	854a                	mv	a0,s2
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	2f4080e7          	jalr	756(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    800048e6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048ea:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048ee:	8526                	mv	a0,s1
    800048f0:	ffffe097          	auipc	ra,0xffffe
    800048f4:	a08080e7          	jalr	-1528(ra) # 800022f8 <wakeup>
  release(&lk->lk);
    800048f8:	854a                	mv	a0,s2
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	38c080e7          	jalr	908(ra) # 80000c86 <release>
}
    80004902:	60e2                	ld	ra,24(sp)
    80004904:	6442                	ld	s0,16(sp)
    80004906:	64a2                	ld	s1,8(sp)
    80004908:	6902                	ld	s2,0(sp)
    8000490a:	6105                	addi	sp,sp,32
    8000490c:	8082                	ret

000000008000490e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000490e:	7179                	addi	sp,sp,-48
    80004910:	f406                	sd	ra,40(sp)
    80004912:	f022                	sd	s0,32(sp)
    80004914:	ec26                	sd	s1,24(sp)
    80004916:	e84a                	sd	s2,16(sp)
    80004918:	e44e                	sd	s3,8(sp)
    8000491a:	1800                	addi	s0,sp,48
    8000491c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000491e:	00850913          	addi	s2,a0,8
    80004922:	854a                	mv	a0,s2
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	2ae080e7          	jalr	686(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000492c:	409c                	lw	a5,0(s1)
    8000492e:	ef99                	bnez	a5,8000494c <holdingsleep+0x3e>
    80004930:	4481                	li	s1,0
  release(&lk->lk);
    80004932:	854a                	mv	a0,s2
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	352080e7          	jalr	850(ra) # 80000c86 <release>
  return r;
}
    8000493c:	8526                	mv	a0,s1
    8000493e:	70a2                	ld	ra,40(sp)
    80004940:	7402                	ld	s0,32(sp)
    80004942:	64e2                	ld	s1,24(sp)
    80004944:	6942                	ld	s2,16(sp)
    80004946:	69a2                	ld	s3,8(sp)
    80004948:	6145                	addi	sp,sp,48
    8000494a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000494c:	0284a983          	lw	s3,40(s1)
    80004950:	ffffd097          	auipc	ra,0xffffd
    80004954:	07e080e7          	jalr	126(ra) # 800019ce <myproc>
    80004958:	5904                	lw	s1,48(a0)
    8000495a:	413484b3          	sub	s1,s1,s3
    8000495e:	0014b493          	seqz	s1,s1
    80004962:	bfc1                	j	80004932 <holdingsleep+0x24>

0000000080004964 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004964:	1141                	addi	sp,sp,-16
    80004966:	e406                	sd	ra,8(sp)
    80004968:	e022                	sd	s0,0(sp)
    8000496a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000496c:	00004597          	auipc	a1,0x4
    80004970:	d8458593          	addi	a1,a1,-636 # 800086f0 <syscalls+0x258>
    80004974:	0001e517          	auipc	a0,0x1e
    80004978:	bc450513          	addi	a0,a0,-1084 # 80022538 <ftable>
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	1c6080e7          	jalr	454(ra) # 80000b42 <initlock>
}
    80004984:	60a2                	ld	ra,8(sp)
    80004986:	6402                	ld	s0,0(sp)
    80004988:	0141                	addi	sp,sp,16
    8000498a:	8082                	ret

000000008000498c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000498c:	1101                	addi	sp,sp,-32
    8000498e:	ec06                	sd	ra,24(sp)
    80004990:	e822                	sd	s0,16(sp)
    80004992:	e426                	sd	s1,8(sp)
    80004994:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004996:	0001e517          	auipc	a0,0x1e
    8000499a:	ba250513          	addi	a0,a0,-1118 # 80022538 <ftable>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	234080e7          	jalr	564(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049a6:	0001e497          	auipc	s1,0x1e
    800049aa:	baa48493          	addi	s1,s1,-1110 # 80022550 <ftable+0x18>
    800049ae:	0001f717          	auipc	a4,0x1f
    800049b2:	b4270713          	addi	a4,a4,-1214 # 800234f0 <disk>
    if(f->ref == 0){
    800049b6:	40dc                	lw	a5,4(s1)
    800049b8:	cf99                	beqz	a5,800049d6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049ba:	02848493          	addi	s1,s1,40
    800049be:	fee49ce3          	bne	s1,a4,800049b6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049c2:	0001e517          	auipc	a0,0x1e
    800049c6:	b7650513          	addi	a0,a0,-1162 # 80022538 <ftable>
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	2bc080e7          	jalr	700(ra) # 80000c86 <release>
  return 0;
    800049d2:	4481                	li	s1,0
    800049d4:	a819                	j	800049ea <filealloc+0x5e>
      f->ref = 1;
    800049d6:	4785                	li	a5,1
    800049d8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049da:	0001e517          	auipc	a0,0x1e
    800049de:	b5e50513          	addi	a0,a0,-1186 # 80022538 <ftable>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	2a4080e7          	jalr	676(ra) # 80000c86 <release>
}
    800049ea:	8526                	mv	a0,s1
    800049ec:	60e2                	ld	ra,24(sp)
    800049ee:	6442                	ld	s0,16(sp)
    800049f0:	64a2                	ld	s1,8(sp)
    800049f2:	6105                	addi	sp,sp,32
    800049f4:	8082                	ret

00000000800049f6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049f6:	1101                	addi	sp,sp,-32
    800049f8:	ec06                	sd	ra,24(sp)
    800049fa:	e822                	sd	s0,16(sp)
    800049fc:	e426                	sd	s1,8(sp)
    800049fe:	1000                	addi	s0,sp,32
    80004a00:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a02:	0001e517          	auipc	a0,0x1e
    80004a06:	b3650513          	addi	a0,a0,-1226 # 80022538 <ftable>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	1c8080e7          	jalr	456(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004a12:	40dc                	lw	a5,4(s1)
    80004a14:	02f05263          	blez	a5,80004a38 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a18:	2785                	addiw	a5,a5,1
    80004a1a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a1c:	0001e517          	auipc	a0,0x1e
    80004a20:	b1c50513          	addi	a0,a0,-1252 # 80022538 <ftable>
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	262080e7          	jalr	610(ra) # 80000c86 <release>
  return f;
}
    80004a2c:	8526                	mv	a0,s1
    80004a2e:	60e2                	ld	ra,24(sp)
    80004a30:	6442                	ld	s0,16(sp)
    80004a32:	64a2                	ld	s1,8(sp)
    80004a34:	6105                	addi	sp,sp,32
    80004a36:	8082                	ret
    panic("filedup");
    80004a38:	00004517          	auipc	a0,0x4
    80004a3c:	cc050513          	addi	a0,a0,-832 # 800086f8 <syscalls+0x260>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	afc080e7          	jalr	-1284(ra) # 8000053c <panic>

0000000080004a48 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a48:	7139                	addi	sp,sp,-64
    80004a4a:	fc06                	sd	ra,56(sp)
    80004a4c:	f822                	sd	s0,48(sp)
    80004a4e:	f426                	sd	s1,40(sp)
    80004a50:	f04a                	sd	s2,32(sp)
    80004a52:	ec4e                	sd	s3,24(sp)
    80004a54:	e852                	sd	s4,16(sp)
    80004a56:	e456                	sd	s5,8(sp)
    80004a58:	0080                	addi	s0,sp,64
    80004a5a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a5c:	0001e517          	auipc	a0,0x1e
    80004a60:	adc50513          	addi	a0,a0,-1316 # 80022538 <ftable>
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	16e080e7          	jalr	366(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004a6c:	40dc                	lw	a5,4(s1)
    80004a6e:	06f05163          	blez	a5,80004ad0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a72:	37fd                	addiw	a5,a5,-1
    80004a74:	0007871b          	sext.w	a4,a5
    80004a78:	c0dc                	sw	a5,4(s1)
    80004a7a:	06e04363          	bgtz	a4,80004ae0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a7e:	0004a903          	lw	s2,0(s1)
    80004a82:	0094ca83          	lbu	s5,9(s1)
    80004a86:	0104ba03          	ld	s4,16(s1)
    80004a8a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a8e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a92:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a96:	0001e517          	auipc	a0,0x1e
    80004a9a:	aa250513          	addi	a0,a0,-1374 # 80022538 <ftable>
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	1e8080e7          	jalr	488(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004aa6:	4785                	li	a5,1
    80004aa8:	04f90d63          	beq	s2,a5,80004b02 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004aac:	3979                	addiw	s2,s2,-2
    80004aae:	4785                	li	a5,1
    80004ab0:	0527e063          	bltu	a5,s2,80004af0 <fileclose+0xa8>
    begin_op();
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	ad0080e7          	jalr	-1328(ra) # 80004584 <begin_op>
    iput(ff.ip);
    80004abc:	854e                	mv	a0,s3
    80004abe:	fffff097          	auipc	ra,0xfffff
    80004ac2:	2da080e7          	jalr	730(ra) # 80003d98 <iput>
    end_op();
    80004ac6:	00000097          	auipc	ra,0x0
    80004aca:	b38080e7          	jalr	-1224(ra) # 800045fe <end_op>
    80004ace:	a00d                	j	80004af0 <fileclose+0xa8>
    panic("fileclose");
    80004ad0:	00004517          	auipc	a0,0x4
    80004ad4:	c3050513          	addi	a0,a0,-976 # 80008700 <syscalls+0x268>
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	a64080e7          	jalr	-1436(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004ae0:	0001e517          	auipc	a0,0x1e
    80004ae4:	a5850513          	addi	a0,a0,-1448 # 80022538 <ftable>
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	19e080e7          	jalr	414(ra) # 80000c86 <release>
  }
}
    80004af0:	70e2                	ld	ra,56(sp)
    80004af2:	7442                	ld	s0,48(sp)
    80004af4:	74a2                	ld	s1,40(sp)
    80004af6:	7902                	ld	s2,32(sp)
    80004af8:	69e2                	ld	s3,24(sp)
    80004afa:	6a42                	ld	s4,16(sp)
    80004afc:	6aa2                	ld	s5,8(sp)
    80004afe:	6121                	addi	sp,sp,64
    80004b00:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b02:	85d6                	mv	a1,s5
    80004b04:	8552                	mv	a0,s4
    80004b06:	00000097          	auipc	ra,0x0
    80004b0a:	348080e7          	jalr	840(ra) # 80004e4e <pipeclose>
    80004b0e:	b7cd                	j	80004af0 <fileclose+0xa8>

0000000080004b10 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b10:	715d                	addi	sp,sp,-80
    80004b12:	e486                	sd	ra,72(sp)
    80004b14:	e0a2                	sd	s0,64(sp)
    80004b16:	fc26                	sd	s1,56(sp)
    80004b18:	f84a                	sd	s2,48(sp)
    80004b1a:	f44e                	sd	s3,40(sp)
    80004b1c:	0880                	addi	s0,sp,80
    80004b1e:	84aa                	mv	s1,a0
    80004b20:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	eac080e7          	jalr	-340(ra) # 800019ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b2a:	409c                	lw	a5,0(s1)
    80004b2c:	37f9                	addiw	a5,a5,-2
    80004b2e:	4705                	li	a4,1
    80004b30:	04f76763          	bltu	a4,a5,80004b7e <filestat+0x6e>
    80004b34:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b36:	6c88                	ld	a0,24(s1)
    80004b38:	fffff097          	auipc	ra,0xfffff
    80004b3c:	0a6080e7          	jalr	166(ra) # 80003bde <ilock>
    stati(f->ip, &st);
    80004b40:	fb840593          	addi	a1,s0,-72
    80004b44:	6c88                	ld	a0,24(s1)
    80004b46:	fffff097          	auipc	ra,0xfffff
    80004b4a:	322080e7          	jalr	802(ra) # 80003e68 <stati>
    iunlock(f->ip);
    80004b4e:	6c88                	ld	a0,24(s1)
    80004b50:	fffff097          	auipc	ra,0xfffff
    80004b54:	150080e7          	jalr	336(ra) # 80003ca0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b58:	46e1                	li	a3,24
    80004b5a:	fb840613          	addi	a2,s0,-72
    80004b5e:	85ce                	mv	a1,s3
    80004b60:	05093503          	ld	a0,80(s2)
    80004b64:	ffffd097          	auipc	ra,0xffffd
    80004b68:	b02080e7          	jalr	-1278(ra) # 80001666 <copyout>
    80004b6c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b70:	60a6                	ld	ra,72(sp)
    80004b72:	6406                	ld	s0,64(sp)
    80004b74:	74e2                	ld	s1,56(sp)
    80004b76:	7942                	ld	s2,48(sp)
    80004b78:	79a2                	ld	s3,40(sp)
    80004b7a:	6161                	addi	sp,sp,80
    80004b7c:	8082                	ret
  return -1;
    80004b7e:	557d                	li	a0,-1
    80004b80:	bfc5                	j	80004b70 <filestat+0x60>

0000000080004b82 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b82:	7179                	addi	sp,sp,-48
    80004b84:	f406                	sd	ra,40(sp)
    80004b86:	f022                	sd	s0,32(sp)
    80004b88:	ec26                	sd	s1,24(sp)
    80004b8a:	e84a                	sd	s2,16(sp)
    80004b8c:	e44e                	sd	s3,8(sp)
    80004b8e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b90:	00854783          	lbu	a5,8(a0)
    80004b94:	c3d5                	beqz	a5,80004c38 <fileread+0xb6>
    80004b96:	84aa                	mv	s1,a0
    80004b98:	89ae                	mv	s3,a1
    80004b9a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b9c:	411c                	lw	a5,0(a0)
    80004b9e:	4705                	li	a4,1
    80004ba0:	04e78963          	beq	a5,a4,80004bf2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ba4:	470d                	li	a4,3
    80004ba6:	04e78d63          	beq	a5,a4,80004c00 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004baa:	4709                	li	a4,2
    80004bac:	06e79e63          	bne	a5,a4,80004c28 <fileread+0xa6>
    ilock(f->ip);
    80004bb0:	6d08                	ld	a0,24(a0)
    80004bb2:	fffff097          	auipc	ra,0xfffff
    80004bb6:	02c080e7          	jalr	44(ra) # 80003bde <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bba:	874a                	mv	a4,s2
    80004bbc:	5094                	lw	a3,32(s1)
    80004bbe:	864e                	mv	a2,s3
    80004bc0:	4585                	li	a1,1
    80004bc2:	6c88                	ld	a0,24(s1)
    80004bc4:	fffff097          	auipc	ra,0xfffff
    80004bc8:	2ce080e7          	jalr	718(ra) # 80003e92 <readi>
    80004bcc:	892a                	mv	s2,a0
    80004bce:	00a05563          	blez	a0,80004bd8 <fileread+0x56>
      f->off += r;
    80004bd2:	509c                	lw	a5,32(s1)
    80004bd4:	9fa9                	addw	a5,a5,a0
    80004bd6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bd8:	6c88                	ld	a0,24(s1)
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	0c6080e7          	jalr	198(ra) # 80003ca0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004be2:	854a                	mv	a0,s2
    80004be4:	70a2                	ld	ra,40(sp)
    80004be6:	7402                	ld	s0,32(sp)
    80004be8:	64e2                	ld	s1,24(sp)
    80004bea:	6942                	ld	s2,16(sp)
    80004bec:	69a2                	ld	s3,8(sp)
    80004bee:	6145                	addi	sp,sp,48
    80004bf0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bf2:	6908                	ld	a0,16(a0)
    80004bf4:	00000097          	auipc	ra,0x0
    80004bf8:	3c2080e7          	jalr	962(ra) # 80004fb6 <piperead>
    80004bfc:	892a                	mv	s2,a0
    80004bfe:	b7d5                	j	80004be2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c00:	02451783          	lh	a5,36(a0)
    80004c04:	03079693          	slli	a3,a5,0x30
    80004c08:	92c1                	srli	a3,a3,0x30
    80004c0a:	4725                	li	a4,9
    80004c0c:	02d76863          	bltu	a4,a3,80004c3c <fileread+0xba>
    80004c10:	0792                	slli	a5,a5,0x4
    80004c12:	0001e717          	auipc	a4,0x1e
    80004c16:	88670713          	addi	a4,a4,-1914 # 80022498 <devsw>
    80004c1a:	97ba                	add	a5,a5,a4
    80004c1c:	639c                	ld	a5,0(a5)
    80004c1e:	c38d                	beqz	a5,80004c40 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c20:	4505                	li	a0,1
    80004c22:	9782                	jalr	a5
    80004c24:	892a                	mv	s2,a0
    80004c26:	bf75                	j	80004be2 <fileread+0x60>
    panic("fileread");
    80004c28:	00004517          	auipc	a0,0x4
    80004c2c:	ae850513          	addi	a0,a0,-1304 # 80008710 <syscalls+0x278>
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	90c080e7          	jalr	-1780(ra) # 8000053c <panic>
    return -1;
    80004c38:	597d                	li	s2,-1
    80004c3a:	b765                	j	80004be2 <fileread+0x60>
      return -1;
    80004c3c:	597d                	li	s2,-1
    80004c3e:	b755                	j	80004be2 <fileread+0x60>
    80004c40:	597d                	li	s2,-1
    80004c42:	b745                	j	80004be2 <fileread+0x60>

0000000080004c44 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c44:	00954783          	lbu	a5,9(a0)
    80004c48:	10078e63          	beqz	a5,80004d64 <filewrite+0x120>
{
    80004c4c:	715d                	addi	sp,sp,-80
    80004c4e:	e486                	sd	ra,72(sp)
    80004c50:	e0a2                	sd	s0,64(sp)
    80004c52:	fc26                	sd	s1,56(sp)
    80004c54:	f84a                	sd	s2,48(sp)
    80004c56:	f44e                	sd	s3,40(sp)
    80004c58:	f052                	sd	s4,32(sp)
    80004c5a:	ec56                	sd	s5,24(sp)
    80004c5c:	e85a                	sd	s6,16(sp)
    80004c5e:	e45e                	sd	s7,8(sp)
    80004c60:	e062                	sd	s8,0(sp)
    80004c62:	0880                	addi	s0,sp,80
    80004c64:	892a                	mv	s2,a0
    80004c66:	8b2e                	mv	s6,a1
    80004c68:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c6a:	411c                	lw	a5,0(a0)
    80004c6c:	4705                	li	a4,1
    80004c6e:	02e78263          	beq	a5,a4,80004c92 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c72:	470d                	li	a4,3
    80004c74:	02e78563          	beq	a5,a4,80004c9e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c78:	4709                	li	a4,2
    80004c7a:	0ce79d63          	bne	a5,a4,80004d54 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c7e:	0ac05b63          	blez	a2,80004d34 <filewrite+0xf0>
    int i = 0;
    80004c82:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004c84:	6b85                	lui	s7,0x1
    80004c86:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004c8a:	6c05                	lui	s8,0x1
    80004c8c:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c90:	a851                	j	80004d24 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c92:	6908                	ld	a0,16(a0)
    80004c94:	00000097          	auipc	ra,0x0
    80004c98:	22a080e7          	jalr	554(ra) # 80004ebe <pipewrite>
    80004c9c:	a045                	j	80004d3c <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c9e:	02451783          	lh	a5,36(a0)
    80004ca2:	03079693          	slli	a3,a5,0x30
    80004ca6:	92c1                	srli	a3,a3,0x30
    80004ca8:	4725                	li	a4,9
    80004caa:	0ad76f63          	bltu	a4,a3,80004d68 <filewrite+0x124>
    80004cae:	0792                	slli	a5,a5,0x4
    80004cb0:	0001d717          	auipc	a4,0x1d
    80004cb4:	7e870713          	addi	a4,a4,2024 # 80022498 <devsw>
    80004cb8:	97ba                	add	a5,a5,a4
    80004cba:	679c                	ld	a5,8(a5)
    80004cbc:	cbc5                	beqz	a5,80004d6c <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004cbe:	4505                	li	a0,1
    80004cc0:	9782                	jalr	a5
    80004cc2:	a8ad                	j	80004d3c <filewrite+0xf8>
      if(n1 > max)
    80004cc4:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004cc8:	00000097          	auipc	ra,0x0
    80004ccc:	8bc080e7          	jalr	-1860(ra) # 80004584 <begin_op>
      ilock(f->ip);
    80004cd0:	01893503          	ld	a0,24(s2)
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	f0a080e7          	jalr	-246(ra) # 80003bde <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cdc:	8756                	mv	a4,s5
    80004cde:	02092683          	lw	a3,32(s2)
    80004ce2:	01698633          	add	a2,s3,s6
    80004ce6:	4585                	li	a1,1
    80004ce8:	01893503          	ld	a0,24(s2)
    80004cec:	fffff097          	auipc	ra,0xfffff
    80004cf0:	29e080e7          	jalr	670(ra) # 80003f8a <writei>
    80004cf4:	84aa                	mv	s1,a0
    80004cf6:	00a05763          	blez	a0,80004d04 <filewrite+0xc0>
        f->off += r;
    80004cfa:	02092783          	lw	a5,32(s2)
    80004cfe:	9fa9                	addw	a5,a5,a0
    80004d00:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d04:	01893503          	ld	a0,24(s2)
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	f98080e7          	jalr	-104(ra) # 80003ca0 <iunlock>
      end_op();
    80004d10:	00000097          	auipc	ra,0x0
    80004d14:	8ee080e7          	jalr	-1810(ra) # 800045fe <end_op>

      if(r != n1){
    80004d18:	009a9f63          	bne	s5,s1,80004d36 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004d1c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d20:	0149db63          	bge	s3,s4,80004d36 <filewrite+0xf2>
      int n1 = n - i;
    80004d24:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004d28:	0004879b          	sext.w	a5,s1
    80004d2c:	f8fbdce3          	bge	s7,a5,80004cc4 <filewrite+0x80>
    80004d30:	84e2                	mv	s1,s8
    80004d32:	bf49                	j	80004cc4 <filewrite+0x80>
    int i = 0;
    80004d34:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d36:	033a1d63          	bne	s4,s3,80004d70 <filewrite+0x12c>
    80004d3a:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d3c:	60a6                	ld	ra,72(sp)
    80004d3e:	6406                	ld	s0,64(sp)
    80004d40:	74e2                	ld	s1,56(sp)
    80004d42:	7942                	ld	s2,48(sp)
    80004d44:	79a2                	ld	s3,40(sp)
    80004d46:	7a02                	ld	s4,32(sp)
    80004d48:	6ae2                	ld	s5,24(sp)
    80004d4a:	6b42                	ld	s6,16(sp)
    80004d4c:	6ba2                	ld	s7,8(sp)
    80004d4e:	6c02                	ld	s8,0(sp)
    80004d50:	6161                	addi	sp,sp,80
    80004d52:	8082                	ret
    panic("filewrite");
    80004d54:	00004517          	auipc	a0,0x4
    80004d58:	9cc50513          	addi	a0,a0,-1588 # 80008720 <syscalls+0x288>
    80004d5c:	ffffb097          	auipc	ra,0xffffb
    80004d60:	7e0080e7          	jalr	2016(ra) # 8000053c <panic>
    return -1;
    80004d64:	557d                	li	a0,-1
}
    80004d66:	8082                	ret
      return -1;
    80004d68:	557d                	li	a0,-1
    80004d6a:	bfc9                	j	80004d3c <filewrite+0xf8>
    80004d6c:	557d                	li	a0,-1
    80004d6e:	b7f9                	j	80004d3c <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004d70:	557d                	li	a0,-1
    80004d72:	b7e9                	j	80004d3c <filewrite+0xf8>

0000000080004d74 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d74:	7179                	addi	sp,sp,-48
    80004d76:	f406                	sd	ra,40(sp)
    80004d78:	f022                	sd	s0,32(sp)
    80004d7a:	ec26                	sd	s1,24(sp)
    80004d7c:	e84a                	sd	s2,16(sp)
    80004d7e:	e44e                	sd	s3,8(sp)
    80004d80:	e052                	sd	s4,0(sp)
    80004d82:	1800                	addi	s0,sp,48
    80004d84:	84aa                	mv	s1,a0
    80004d86:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d88:	0005b023          	sd	zero,0(a1)
    80004d8c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d90:	00000097          	auipc	ra,0x0
    80004d94:	bfc080e7          	jalr	-1028(ra) # 8000498c <filealloc>
    80004d98:	e088                	sd	a0,0(s1)
    80004d9a:	c551                	beqz	a0,80004e26 <pipealloc+0xb2>
    80004d9c:	00000097          	auipc	ra,0x0
    80004da0:	bf0080e7          	jalr	-1040(ra) # 8000498c <filealloc>
    80004da4:	00aa3023          	sd	a0,0(s4)
    80004da8:	c92d                	beqz	a0,80004e1a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	d38080e7          	jalr	-712(ra) # 80000ae2 <kalloc>
    80004db2:	892a                	mv	s2,a0
    80004db4:	c125                	beqz	a0,80004e14 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004db6:	4985                	li	s3,1
    80004db8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004dbc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004dc0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004dc4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004dc8:	00004597          	auipc	a1,0x4
    80004dcc:	96858593          	addi	a1,a1,-1688 # 80008730 <syscalls+0x298>
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	d72080e7          	jalr	-654(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004dd8:	609c                	ld	a5,0(s1)
    80004dda:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dde:	609c                	ld	a5,0(s1)
    80004de0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004de4:	609c                	ld	a5,0(s1)
    80004de6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dea:	609c                	ld	a5,0(s1)
    80004dec:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004df0:	000a3783          	ld	a5,0(s4)
    80004df4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004df8:	000a3783          	ld	a5,0(s4)
    80004dfc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e00:	000a3783          	ld	a5,0(s4)
    80004e04:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e08:	000a3783          	ld	a5,0(s4)
    80004e0c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e10:	4501                	li	a0,0
    80004e12:	a025                	j	80004e3a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e14:	6088                	ld	a0,0(s1)
    80004e16:	e501                	bnez	a0,80004e1e <pipealloc+0xaa>
    80004e18:	a039                	j	80004e26 <pipealloc+0xb2>
    80004e1a:	6088                	ld	a0,0(s1)
    80004e1c:	c51d                	beqz	a0,80004e4a <pipealloc+0xd6>
    fileclose(*f0);
    80004e1e:	00000097          	auipc	ra,0x0
    80004e22:	c2a080e7          	jalr	-982(ra) # 80004a48 <fileclose>
  if(*f1)
    80004e26:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e2a:	557d                	li	a0,-1
  if(*f1)
    80004e2c:	c799                	beqz	a5,80004e3a <pipealloc+0xc6>
    fileclose(*f1);
    80004e2e:	853e                	mv	a0,a5
    80004e30:	00000097          	auipc	ra,0x0
    80004e34:	c18080e7          	jalr	-1000(ra) # 80004a48 <fileclose>
  return -1;
    80004e38:	557d                	li	a0,-1
}
    80004e3a:	70a2                	ld	ra,40(sp)
    80004e3c:	7402                	ld	s0,32(sp)
    80004e3e:	64e2                	ld	s1,24(sp)
    80004e40:	6942                	ld	s2,16(sp)
    80004e42:	69a2                	ld	s3,8(sp)
    80004e44:	6a02                	ld	s4,0(sp)
    80004e46:	6145                	addi	sp,sp,48
    80004e48:	8082                	ret
  return -1;
    80004e4a:	557d                	li	a0,-1
    80004e4c:	b7fd                	j	80004e3a <pipealloc+0xc6>

0000000080004e4e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e4e:	1101                	addi	sp,sp,-32
    80004e50:	ec06                	sd	ra,24(sp)
    80004e52:	e822                	sd	s0,16(sp)
    80004e54:	e426                	sd	s1,8(sp)
    80004e56:	e04a                	sd	s2,0(sp)
    80004e58:	1000                	addi	s0,sp,32
    80004e5a:	84aa                	mv	s1,a0
    80004e5c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e5e:	ffffc097          	auipc	ra,0xffffc
    80004e62:	d74080e7          	jalr	-652(ra) # 80000bd2 <acquire>
  if(writable){
    80004e66:	02090d63          	beqz	s2,80004ea0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e6a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e6e:	21848513          	addi	a0,s1,536
    80004e72:	ffffd097          	auipc	ra,0xffffd
    80004e76:	486080e7          	jalr	1158(ra) # 800022f8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e7a:	2204b783          	ld	a5,544(s1)
    80004e7e:	eb95                	bnez	a5,80004eb2 <pipeclose+0x64>
    release(&pi->lock);
    80004e80:	8526                	mv	a0,s1
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	e04080e7          	jalr	-508(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	b58080e7          	jalr	-1192(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004e94:	60e2                	ld	ra,24(sp)
    80004e96:	6442                	ld	s0,16(sp)
    80004e98:	64a2                	ld	s1,8(sp)
    80004e9a:	6902                	ld	s2,0(sp)
    80004e9c:	6105                	addi	sp,sp,32
    80004e9e:	8082                	ret
    pi->readopen = 0;
    80004ea0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ea4:	21c48513          	addi	a0,s1,540
    80004ea8:	ffffd097          	auipc	ra,0xffffd
    80004eac:	450080e7          	jalr	1104(ra) # 800022f8 <wakeup>
    80004eb0:	b7e9                	j	80004e7a <pipeclose+0x2c>
    release(&pi->lock);
    80004eb2:	8526                	mv	a0,s1
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	dd2080e7          	jalr	-558(ra) # 80000c86 <release>
}
    80004ebc:	bfe1                	j	80004e94 <pipeclose+0x46>

0000000080004ebe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ebe:	711d                	addi	sp,sp,-96
    80004ec0:	ec86                	sd	ra,88(sp)
    80004ec2:	e8a2                	sd	s0,80(sp)
    80004ec4:	e4a6                	sd	s1,72(sp)
    80004ec6:	e0ca                	sd	s2,64(sp)
    80004ec8:	fc4e                	sd	s3,56(sp)
    80004eca:	f852                	sd	s4,48(sp)
    80004ecc:	f456                	sd	s5,40(sp)
    80004ece:	f05a                	sd	s6,32(sp)
    80004ed0:	ec5e                	sd	s7,24(sp)
    80004ed2:	e862                	sd	s8,16(sp)
    80004ed4:	1080                	addi	s0,sp,96
    80004ed6:	84aa                	mv	s1,a0
    80004ed8:	8aae                	mv	s5,a1
    80004eda:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004edc:	ffffd097          	auipc	ra,0xffffd
    80004ee0:	af2080e7          	jalr	-1294(ra) # 800019ce <myproc>
    80004ee4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ee6:	8526                	mv	a0,s1
    80004ee8:	ffffc097          	auipc	ra,0xffffc
    80004eec:	cea080e7          	jalr	-790(ra) # 80000bd2 <acquire>
  while(i < n){
    80004ef0:	0b405663          	blez	s4,80004f9c <pipewrite+0xde>
  int i = 0;
    80004ef4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ef6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ef8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004efc:	21c48b93          	addi	s7,s1,540
    80004f00:	a089                	j	80004f42 <pipewrite+0x84>
      release(&pi->lock);
    80004f02:	8526                	mv	a0,s1
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	d82080e7          	jalr	-638(ra) # 80000c86 <release>
      return -1;
    80004f0c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f0e:	854a                	mv	a0,s2
    80004f10:	60e6                	ld	ra,88(sp)
    80004f12:	6446                	ld	s0,80(sp)
    80004f14:	64a6                	ld	s1,72(sp)
    80004f16:	6906                	ld	s2,64(sp)
    80004f18:	79e2                	ld	s3,56(sp)
    80004f1a:	7a42                	ld	s4,48(sp)
    80004f1c:	7aa2                	ld	s5,40(sp)
    80004f1e:	7b02                	ld	s6,32(sp)
    80004f20:	6be2                	ld	s7,24(sp)
    80004f22:	6c42                	ld	s8,16(sp)
    80004f24:	6125                	addi	sp,sp,96
    80004f26:	8082                	ret
      wakeup(&pi->nread);
    80004f28:	8562                	mv	a0,s8
    80004f2a:	ffffd097          	auipc	ra,0xffffd
    80004f2e:	3ce080e7          	jalr	974(ra) # 800022f8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f32:	85a6                	mv	a1,s1
    80004f34:	855e                	mv	a0,s7
    80004f36:	ffffd097          	auipc	ra,0xffffd
    80004f3a:	35e080e7          	jalr	862(ra) # 80002294 <sleep>
  while(i < n){
    80004f3e:	07495063          	bge	s2,s4,80004f9e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f42:	2204a783          	lw	a5,544(s1)
    80004f46:	dfd5                	beqz	a5,80004f02 <pipewrite+0x44>
    80004f48:	854e                	mv	a0,s3
    80004f4a:	ffffd097          	auipc	ra,0xffffd
    80004f4e:	5fe080e7          	jalr	1534(ra) # 80002548 <killed>
    80004f52:	f945                	bnez	a0,80004f02 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f54:	2184a783          	lw	a5,536(s1)
    80004f58:	21c4a703          	lw	a4,540(s1)
    80004f5c:	2007879b          	addiw	a5,a5,512
    80004f60:	fcf704e3          	beq	a4,a5,80004f28 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f64:	4685                	li	a3,1
    80004f66:	01590633          	add	a2,s2,s5
    80004f6a:	faf40593          	addi	a1,s0,-81
    80004f6e:	0509b503          	ld	a0,80(s3)
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	780080e7          	jalr	1920(ra) # 800016f2 <copyin>
    80004f7a:	03650263          	beq	a0,s6,80004f9e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f7e:	21c4a783          	lw	a5,540(s1)
    80004f82:	0017871b          	addiw	a4,a5,1
    80004f86:	20e4ae23          	sw	a4,540(s1)
    80004f8a:	1ff7f793          	andi	a5,a5,511
    80004f8e:	97a6                	add	a5,a5,s1
    80004f90:	faf44703          	lbu	a4,-81(s0)
    80004f94:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f98:	2905                	addiw	s2,s2,1
    80004f9a:	b755                	j	80004f3e <pipewrite+0x80>
  int i = 0;
    80004f9c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f9e:	21848513          	addi	a0,s1,536
    80004fa2:	ffffd097          	auipc	ra,0xffffd
    80004fa6:	356080e7          	jalr	854(ra) # 800022f8 <wakeup>
  release(&pi->lock);
    80004faa:	8526                	mv	a0,s1
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	cda080e7          	jalr	-806(ra) # 80000c86 <release>
  return i;
    80004fb4:	bfa9                	j	80004f0e <pipewrite+0x50>

0000000080004fb6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fb6:	715d                	addi	sp,sp,-80
    80004fb8:	e486                	sd	ra,72(sp)
    80004fba:	e0a2                	sd	s0,64(sp)
    80004fbc:	fc26                	sd	s1,56(sp)
    80004fbe:	f84a                	sd	s2,48(sp)
    80004fc0:	f44e                	sd	s3,40(sp)
    80004fc2:	f052                	sd	s4,32(sp)
    80004fc4:	ec56                	sd	s5,24(sp)
    80004fc6:	e85a                	sd	s6,16(sp)
    80004fc8:	0880                	addi	s0,sp,80
    80004fca:	84aa                	mv	s1,a0
    80004fcc:	892e                	mv	s2,a1
    80004fce:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fd0:	ffffd097          	auipc	ra,0xffffd
    80004fd4:	9fe080e7          	jalr	-1538(ra) # 800019ce <myproc>
    80004fd8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fda:	8526                	mv	a0,s1
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	bf6080e7          	jalr	-1034(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fe4:	2184a703          	lw	a4,536(s1)
    80004fe8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fec:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ff0:	02f71763          	bne	a4,a5,8000501e <piperead+0x68>
    80004ff4:	2244a783          	lw	a5,548(s1)
    80004ff8:	c39d                	beqz	a5,8000501e <piperead+0x68>
    if(killed(pr)){
    80004ffa:	8552                	mv	a0,s4
    80004ffc:	ffffd097          	auipc	ra,0xffffd
    80005000:	54c080e7          	jalr	1356(ra) # 80002548 <killed>
    80005004:	e949                	bnez	a0,80005096 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005006:	85a6                	mv	a1,s1
    80005008:	854e                	mv	a0,s3
    8000500a:	ffffd097          	auipc	ra,0xffffd
    8000500e:	28a080e7          	jalr	650(ra) # 80002294 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005012:	2184a703          	lw	a4,536(s1)
    80005016:	21c4a783          	lw	a5,540(s1)
    8000501a:	fcf70de3          	beq	a4,a5,80004ff4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000501e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005020:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005022:	05505463          	blez	s5,8000506a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005026:	2184a783          	lw	a5,536(s1)
    8000502a:	21c4a703          	lw	a4,540(s1)
    8000502e:	02f70e63          	beq	a4,a5,8000506a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005032:	0017871b          	addiw	a4,a5,1
    80005036:	20e4ac23          	sw	a4,536(s1)
    8000503a:	1ff7f793          	andi	a5,a5,511
    8000503e:	97a6                	add	a5,a5,s1
    80005040:	0187c783          	lbu	a5,24(a5)
    80005044:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005048:	4685                	li	a3,1
    8000504a:	fbf40613          	addi	a2,s0,-65
    8000504e:	85ca                	mv	a1,s2
    80005050:	050a3503          	ld	a0,80(s4)
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	612080e7          	jalr	1554(ra) # 80001666 <copyout>
    8000505c:	01650763          	beq	a0,s6,8000506a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005060:	2985                	addiw	s3,s3,1
    80005062:	0905                	addi	s2,s2,1
    80005064:	fd3a91e3          	bne	s5,s3,80005026 <piperead+0x70>
    80005068:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000506a:	21c48513          	addi	a0,s1,540
    8000506e:	ffffd097          	auipc	ra,0xffffd
    80005072:	28a080e7          	jalr	650(ra) # 800022f8 <wakeup>
  release(&pi->lock);
    80005076:	8526                	mv	a0,s1
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	c0e080e7          	jalr	-1010(ra) # 80000c86 <release>
  return i;
}
    80005080:	854e                	mv	a0,s3
    80005082:	60a6                	ld	ra,72(sp)
    80005084:	6406                	ld	s0,64(sp)
    80005086:	74e2                	ld	s1,56(sp)
    80005088:	7942                	ld	s2,48(sp)
    8000508a:	79a2                	ld	s3,40(sp)
    8000508c:	7a02                	ld	s4,32(sp)
    8000508e:	6ae2                	ld	s5,24(sp)
    80005090:	6b42                	ld	s6,16(sp)
    80005092:	6161                	addi	sp,sp,80
    80005094:	8082                	ret
      release(&pi->lock);
    80005096:	8526                	mv	a0,s1
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	bee080e7          	jalr	-1042(ra) # 80000c86 <release>
      return -1;
    800050a0:	59fd                	li	s3,-1
    800050a2:	bff9                	j	80005080 <piperead+0xca>

00000000800050a4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800050a4:	1141                	addi	sp,sp,-16
    800050a6:	e422                	sd	s0,8(sp)
    800050a8:	0800                	addi	s0,sp,16
    800050aa:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800050ac:	8905                	andi	a0,a0,1
    800050ae:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800050b0:	8b89                	andi	a5,a5,2
    800050b2:	c399                	beqz	a5,800050b8 <flags2perm+0x14>
      perm |= PTE_W;
    800050b4:	00456513          	ori	a0,a0,4
    return perm;
}
    800050b8:	6422                	ld	s0,8(sp)
    800050ba:	0141                	addi	sp,sp,16
    800050bc:	8082                	ret

00000000800050be <exec>:

int
exec(char *path, char **argv)
{
    800050be:	df010113          	addi	sp,sp,-528
    800050c2:	20113423          	sd	ra,520(sp)
    800050c6:	20813023          	sd	s0,512(sp)
    800050ca:	ffa6                	sd	s1,504(sp)
    800050cc:	fbca                	sd	s2,496(sp)
    800050ce:	f7ce                	sd	s3,488(sp)
    800050d0:	f3d2                	sd	s4,480(sp)
    800050d2:	efd6                	sd	s5,472(sp)
    800050d4:	ebda                	sd	s6,464(sp)
    800050d6:	e7de                	sd	s7,456(sp)
    800050d8:	e3e2                	sd	s8,448(sp)
    800050da:	ff66                	sd	s9,440(sp)
    800050dc:	fb6a                	sd	s10,432(sp)
    800050de:	f76e                	sd	s11,424(sp)
    800050e0:	0c00                	addi	s0,sp,528
    800050e2:	892a                	mv	s2,a0
    800050e4:	dea43c23          	sd	a0,-520(s0)
    800050e8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050ec:	ffffd097          	auipc	ra,0xffffd
    800050f0:	8e2080e7          	jalr	-1822(ra) # 800019ce <myproc>
    800050f4:	84aa                	mv	s1,a0

  begin_op();
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	48e080e7          	jalr	1166(ra) # 80004584 <begin_op>

  if((ip = namei(path)) == 0){
    800050fe:	854a                	mv	a0,s2
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	284080e7          	jalr	644(ra) # 80004384 <namei>
    80005108:	c92d                	beqz	a0,8000517a <exec+0xbc>
    8000510a:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	ad2080e7          	jalr	-1326(ra) # 80003bde <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005114:	04000713          	li	a4,64
    80005118:	4681                	li	a3,0
    8000511a:	e5040613          	addi	a2,s0,-432
    8000511e:	4581                	li	a1,0
    80005120:	8552                	mv	a0,s4
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	d70080e7          	jalr	-656(ra) # 80003e92 <readi>
    8000512a:	04000793          	li	a5,64
    8000512e:	00f51a63          	bne	a0,a5,80005142 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005132:	e5042703          	lw	a4,-432(s0)
    80005136:	464c47b7          	lui	a5,0x464c4
    8000513a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000513e:	04f70463          	beq	a4,a5,80005186 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005142:	8552                	mv	a0,s4
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	cfc080e7          	jalr	-772(ra) # 80003e40 <iunlockput>
    end_op();
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	4b2080e7          	jalr	1202(ra) # 800045fe <end_op>
  }
  return -1;
    80005154:	557d                	li	a0,-1
}
    80005156:	20813083          	ld	ra,520(sp)
    8000515a:	20013403          	ld	s0,512(sp)
    8000515e:	74fe                	ld	s1,504(sp)
    80005160:	795e                	ld	s2,496(sp)
    80005162:	79be                	ld	s3,488(sp)
    80005164:	7a1e                	ld	s4,480(sp)
    80005166:	6afe                	ld	s5,472(sp)
    80005168:	6b5e                	ld	s6,464(sp)
    8000516a:	6bbe                	ld	s7,456(sp)
    8000516c:	6c1e                	ld	s8,448(sp)
    8000516e:	7cfa                	ld	s9,440(sp)
    80005170:	7d5a                	ld	s10,432(sp)
    80005172:	7dba                	ld	s11,424(sp)
    80005174:	21010113          	addi	sp,sp,528
    80005178:	8082                	ret
    end_op();
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	484080e7          	jalr	1156(ra) # 800045fe <end_op>
    return -1;
    80005182:	557d                	li	a0,-1
    80005184:	bfc9                	j	80005156 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005186:	8526                	mv	a0,s1
    80005188:	ffffd097          	auipc	ra,0xffffd
    8000518c:	972080e7          	jalr	-1678(ra) # 80001afa <proc_pagetable>
    80005190:	8b2a                	mv	s6,a0
    80005192:	d945                	beqz	a0,80005142 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005194:	e7042d03          	lw	s10,-400(s0)
    80005198:	e8845783          	lhu	a5,-376(s0)
    8000519c:	10078463          	beqz	a5,800052a4 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051a0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051a2:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800051a4:	6c85                	lui	s9,0x1
    800051a6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051aa:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800051ae:	6a85                	lui	s5,0x1
    800051b0:	a0b5                	j	8000521c <exec+0x15e>
      panic("loadseg: address should exist");
    800051b2:	00003517          	auipc	a0,0x3
    800051b6:	58650513          	addi	a0,a0,1414 # 80008738 <syscalls+0x2a0>
    800051ba:	ffffb097          	auipc	ra,0xffffb
    800051be:	382080e7          	jalr	898(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    800051c2:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051c4:	8726                	mv	a4,s1
    800051c6:	012c06bb          	addw	a3,s8,s2
    800051ca:	4581                	li	a1,0
    800051cc:	8552                	mv	a0,s4
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	cc4080e7          	jalr	-828(ra) # 80003e92 <readi>
    800051d6:	2501                	sext.w	a0,a0
    800051d8:	24a49863          	bne	s1,a0,80005428 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800051dc:	012a893b          	addw	s2,s5,s2
    800051e0:	03397563          	bgeu	s2,s3,8000520a <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800051e4:	02091593          	slli	a1,s2,0x20
    800051e8:	9181                	srli	a1,a1,0x20
    800051ea:	95de                	add	a1,a1,s7
    800051ec:	855a                	mv	a0,s6
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	e68080e7          	jalr	-408(ra) # 80001056 <walkaddr>
    800051f6:	862a                	mv	a2,a0
    if(pa == 0)
    800051f8:	dd4d                	beqz	a0,800051b2 <exec+0xf4>
    if(sz - i < PGSIZE)
    800051fa:	412984bb          	subw	s1,s3,s2
    800051fe:	0004879b          	sext.w	a5,s1
    80005202:	fcfcf0e3          	bgeu	s9,a5,800051c2 <exec+0x104>
    80005206:	84d6                	mv	s1,s5
    80005208:	bf6d                	j	800051c2 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000520a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000520e:	2d85                	addiw	s11,s11,1
    80005210:	038d0d1b          	addiw	s10,s10,56
    80005214:	e8845783          	lhu	a5,-376(s0)
    80005218:	08fdd763          	bge	s11,a5,800052a6 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000521c:	2d01                	sext.w	s10,s10
    8000521e:	03800713          	li	a4,56
    80005222:	86ea                	mv	a3,s10
    80005224:	e1840613          	addi	a2,s0,-488
    80005228:	4581                	li	a1,0
    8000522a:	8552                	mv	a0,s4
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	c66080e7          	jalr	-922(ra) # 80003e92 <readi>
    80005234:	03800793          	li	a5,56
    80005238:	1ef51663          	bne	a0,a5,80005424 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    8000523c:	e1842783          	lw	a5,-488(s0)
    80005240:	4705                	li	a4,1
    80005242:	fce796e3          	bne	a5,a4,8000520e <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005246:	e4043483          	ld	s1,-448(s0)
    8000524a:	e3843783          	ld	a5,-456(s0)
    8000524e:	1ef4e863          	bltu	s1,a5,8000543e <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005252:	e2843783          	ld	a5,-472(s0)
    80005256:	94be                	add	s1,s1,a5
    80005258:	1ef4e663          	bltu	s1,a5,80005444 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    8000525c:	df043703          	ld	a4,-528(s0)
    80005260:	8ff9                	and	a5,a5,a4
    80005262:	1e079463          	bnez	a5,8000544a <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005266:	e1c42503          	lw	a0,-484(s0)
    8000526a:	00000097          	auipc	ra,0x0
    8000526e:	e3a080e7          	jalr	-454(ra) # 800050a4 <flags2perm>
    80005272:	86aa                	mv	a3,a0
    80005274:	8626                	mv	a2,s1
    80005276:	85ca                	mv	a1,s2
    80005278:	855a                	mv	a0,s6
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	190080e7          	jalr	400(ra) # 8000140a <uvmalloc>
    80005282:	e0a43423          	sd	a0,-504(s0)
    80005286:	1c050563          	beqz	a0,80005450 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000528a:	e2843b83          	ld	s7,-472(s0)
    8000528e:	e2042c03          	lw	s8,-480(s0)
    80005292:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005296:	00098463          	beqz	s3,8000529e <exec+0x1e0>
    8000529a:	4901                	li	s2,0
    8000529c:	b7a1                	j	800051e4 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000529e:	e0843903          	ld	s2,-504(s0)
    800052a2:	b7b5                	j	8000520e <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052a4:	4901                	li	s2,0
  iunlockput(ip);
    800052a6:	8552                	mv	a0,s4
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	b98080e7          	jalr	-1128(ra) # 80003e40 <iunlockput>
  end_op();
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	34e080e7          	jalr	846(ra) # 800045fe <end_op>
  p = myproc();
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	716080e7          	jalr	1814(ra) # 800019ce <myproc>
    800052c0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052c2:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800052c6:	6985                	lui	s3,0x1
    800052c8:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800052ca:	99ca                	add	s3,s3,s2
    800052cc:	77fd                	lui	a5,0xfffff
    800052ce:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052d2:	4691                	li	a3,4
    800052d4:	6609                	lui	a2,0x2
    800052d6:	964e                	add	a2,a2,s3
    800052d8:	85ce                	mv	a1,s3
    800052da:	855a                	mv	a0,s6
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	12e080e7          	jalr	302(ra) # 8000140a <uvmalloc>
    800052e4:	892a                	mv	s2,a0
    800052e6:	e0a43423          	sd	a0,-504(s0)
    800052ea:	e509                	bnez	a0,800052f4 <exec+0x236>
  if(pagetable)
    800052ec:	e1343423          	sd	s3,-504(s0)
    800052f0:	4a01                	li	s4,0
    800052f2:	aa1d                	j	80005428 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052f4:	75f9                	lui	a1,0xffffe
    800052f6:	95aa                	add	a1,a1,a0
    800052f8:	855a                	mv	a0,s6
    800052fa:	ffffc097          	auipc	ra,0xffffc
    800052fe:	33a080e7          	jalr	826(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80005302:	7bfd                	lui	s7,0xfffff
    80005304:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005306:	e0043783          	ld	a5,-512(s0)
    8000530a:	6388                	ld	a0,0(a5)
    8000530c:	c52d                	beqz	a0,80005376 <exec+0x2b8>
    8000530e:	e9040993          	addi	s3,s0,-368
    80005312:	f9040c13          	addi	s8,s0,-112
    80005316:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	b30080e7          	jalr	-1232(ra) # 80000e48 <strlen>
    80005320:	0015079b          	addiw	a5,a0,1
    80005324:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005328:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000532c:	13796563          	bltu	s2,s7,80005456 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005330:	e0043d03          	ld	s10,-512(s0)
    80005334:	000d3a03          	ld	s4,0(s10)
    80005338:	8552                	mv	a0,s4
    8000533a:	ffffc097          	auipc	ra,0xffffc
    8000533e:	b0e080e7          	jalr	-1266(ra) # 80000e48 <strlen>
    80005342:	0015069b          	addiw	a3,a0,1
    80005346:	8652                	mv	a2,s4
    80005348:	85ca                	mv	a1,s2
    8000534a:	855a                	mv	a0,s6
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	31a080e7          	jalr	794(ra) # 80001666 <copyout>
    80005354:	10054363          	bltz	a0,8000545a <exec+0x39c>
    ustack[argc] = sp;
    80005358:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000535c:	0485                	addi	s1,s1,1
    8000535e:	008d0793          	addi	a5,s10,8
    80005362:	e0f43023          	sd	a5,-512(s0)
    80005366:	008d3503          	ld	a0,8(s10)
    8000536a:	c909                	beqz	a0,8000537c <exec+0x2be>
    if(argc >= MAXARG)
    8000536c:	09a1                	addi	s3,s3,8
    8000536e:	fb8995e3          	bne	s3,s8,80005318 <exec+0x25a>
  ip = 0;
    80005372:	4a01                	li	s4,0
    80005374:	a855                	j	80005428 <exec+0x36a>
  sp = sz;
    80005376:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000537a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000537c:	00349793          	slli	a5,s1,0x3
    80005380:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdb960>
    80005384:	97a2                	add	a5,a5,s0
    80005386:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000538a:	00148693          	addi	a3,s1,1
    8000538e:	068e                	slli	a3,a3,0x3
    80005390:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005394:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80005398:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000539c:	f57968e3          	bltu	s2,s7,800052ec <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053a0:	e9040613          	addi	a2,s0,-368
    800053a4:	85ca                	mv	a1,s2
    800053a6:	855a                	mv	a0,s6
    800053a8:	ffffc097          	auipc	ra,0xffffc
    800053ac:	2be080e7          	jalr	702(ra) # 80001666 <copyout>
    800053b0:	0a054763          	bltz	a0,8000545e <exec+0x3a0>
  p->trapframe->a1 = sp;
    800053b4:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800053b8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053bc:	df843783          	ld	a5,-520(s0)
    800053c0:	0007c703          	lbu	a4,0(a5)
    800053c4:	cf11                	beqz	a4,800053e0 <exec+0x322>
    800053c6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053c8:	02f00693          	li	a3,47
    800053cc:	a039                	j	800053da <exec+0x31c>
      last = s+1;
    800053ce:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053d2:	0785                	addi	a5,a5,1
    800053d4:	fff7c703          	lbu	a4,-1(a5)
    800053d8:	c701                	beqz	a4,800053e0 <exec+0x322>
    if(*s == '/')
    800053da:	fed71ce3          	bne	a4,a3,800053d2 <exec+0x314>
    800053de:	bfc5                	j	800053ce <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800053e0:	4641                	li	a2,16
    800053e2:	df843583          	ld	a1,-520(s0)
    800053e6:	158a8513          	addi	a0,s5,344
    800053ea:	ffffc097          	auipc	ra,0xffffc
    800053ee:	a2c080e7          	jalr	-1492(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800053f2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800053f6:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800053fa:	e0843783          	ld	a5,-504(s0)
    800053fe:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005402:	058ab783          	ld	a5,88(s5)
    80005406:	e6843703          	ld	a4,-408(s0)
    8000540a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000540c:	058ab783          	ld	a5,88(s5)
    80005410:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005414:	85e6                	mv	a1,s9
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	780080e7          	jalr	1920(ra) # 80001b96 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000541e:	0004851b          	sext.w	a0,s1
    80005422:	bb15                	j	80005156 <exec+0x98>
    80005424:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005428:	e0843583          	ld	a1,-504(s0)
    8000542c:	855a                	mv	a0,s6
    8000542e:	ffffc097          	auipc	ra,0xffffc
    80005432:	768080e7          	jalr	1896(ra) # 80001b96 <proc_freepagetable>
  return -1;
    80005436:	557d                	li	a0,-1
  if(ip){
    80005438:	d00a0fe3          	beqz	s4,80005156 <exec+0x98>
    8000543c:	b319                	j	80005142 <exec+0x84>
    8000543e:	e1243423          	sd	s2,-504(s0)
    80005442:	b7dd                	j	80005428 <exec+0x36a>
    80005444:	e1243423          	sd	s2,-504(s0)
    80005448:	b7c5                	j	80005428 <exec+0x36a>
    8000544a:	e1243423          	sd	s2,-504(s0)
    8000544e:	bfe9                	j	80005428 <exec+0x36a>
    80005450:	e1243423          	sd	s2,-504(s0)
    80005454:	bfd1                	j	80005428 <exec+0x36a>
  ip = 0;
    80005456:	4a01                	li	s4,0
    80005458:	bfc1                	j	80005428 <exec+0x36a>
    8000545a:	4a01                	li	s4,0
  if(pagetable)
    8000545c:	b7f1                	j	80005428 <exec+0x36a>
  sz = sz1;
    8000545e:	e0843983          	ld	s3,-504(s0)
    80005462:	b569                	j	800052ec <exec+0x22e>

0000000080005464 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005464:	7179                	addi	sp,sp,-48
    80005466:	f406                	sd	ra,40(sp)
    80005468:	f022                	sd	s0,32(sp)
    8000546a:	ec26                	sd	s1,24(sp)
    8000546c:	e84a                	sd	s2,16(sp)
    8000546e:	1800                	addi	s0,sp,48
    80005470:	892e                	mv	s2,a1
    80005472:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005474:	fdc40593          	addi	a1,s0,-36
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	acc080e7          	jalr	-1332(ra) # 80002f44 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005480:	fdc42703          	lw	a4,-36(s0)
    80005484:	47bd                	li	a5,15
    80005486:	02e7eb63          	bltu	a5,a4,800054bc <argfd+0x58>
    8000548a:	ffffc097          	auipc	ra,0xffffc
    8000548e:	544080e7          	jalr	1348(ra) # 800019ce <myproc>
    80005492:	fdc42703          	lw	a4,-36(s0)
    80005496:	01a70793          	addi	a5,a4,26
    8000549a:	078e                	slli	a5,a5,0x3
    8000549c:	953e                	add	a0,a0,a5
    8000549e:	611c                	ld	a5,0(a0)
    800054a0:	c385                	beqz	a5,800054c0 <argfd+0x5c>
    return -1;
  if(pfd)
    800054a2:	00090463          	beqz	s2,800054aa <argfd+0x46>
    *pfd = fd;
    800054a6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054aa:	4501                	li	a0,0
  if(pf)
    800054ac:	c091                	beqz	s1,800054b0 <argfd+0x4c>
    *pf = f;
    800054ae:	e09c                	sd	a5,0(s1)
}
    800054b0:	70a2                	ld	ra,40(sp)
    800054b2:	7402                	ld	s0,32(sp)
    800054b4:	64e2                	ld	s1,24(sp)
    800054b6:	6942                	ld	s2,16(sp)
    800054b8:	6145                	addi	sp,sp,48
    800054ba:	8082                	ret
    return -1;
    800054bc:	557d                	li	a0,-1
    800054be:	bfcd                	j	800054b0 <argfd+0x4c>
    800054c0:	557d                	li	a0,-1
    800054c2:	b7fd                	j	800054b0 <argfd+0x4c>

00000000800054c4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054c4:	1101                	addi	sp,sp,-32
    800054c6:	ec06                	sd	ra,24(sp)
    800054c8:	e822                	sd	s0,16(sp)
    800054ca:	e426                	sd	s1,8(sp)
    800054cc:	1000                	addi	s0,sp,32
    800054ce:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054d0:	ffffc097          	auipc	ra,0xffffc
    800054d4:	4fe080e7          	jalr	1278(ra) # 800019ce <myproc>
    800054d8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054da:	0d050793          	addi	a5,a0,208
    800054de:	4501                	li	a0,0
    800054e0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054e2:	6398                	ld	a4,0(a5)
    800054e4:	cb19                	beqz	a4,800054fa <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054e6:	2505                	addiw	a0,a0,1
    800054e8:	07a1                	addi	a5,a5,8
    800054ea:	fed51ce3          	bne	a0,a3,800054e2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054ee:	557d                	li	a0,-1
}
    800054f0:	60e2                	ld	ra,24(sp)
    800054f2:	6442                	ld	s0,16(sp)
    800054f4:	64a2                	ld	s1,8(sp)
    800054f6:	6105                	addi	sp,sp,32
    800054f8:	8082                	ret
      p->ofile[fd] = f;
    800054fa:	01a50793          	addi	a5,a0,26
    800054fe:	078e                	slli	a5,a5,0x3
    80005500:	963e                	add	a2,a2,a5
    80005502:	e204                	sd	s1,0(a2)
      return fd;
    80005504:	b7f5                	j	800054f0 <fdalloc+0x2c>

0000000080005506 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005506:	715d                	addi	sp,sp,-80
    80005508:	e486                	sd	ra,72(sp)
    8000550a:	e0a2                	sd	s0,64(sp)
    8000550c:	fc26                	sd	s1,56(sp)
    8000550e:	f84a                	sd	s2,48(sp)
    80005510:	f44e                	sd	s3,40(sp)
    80005512:	f052                	sd	s4,32(sp)
    80005514:	ec56                	sd	s5,24(sp)
    80005516:	e85a                	sd	s6,16(sp)
    80005518:	0880                	addi	s0,sp,80
    8000551a:	8b2e                	mv	s6,a1
    8000551c:	89b2                	mv	s3,a2
    8000551e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005520:	fb040593          	addi	a1,s0,-80
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	e7e080e7          	jalr	-386(ra) # 800043a2 <nameiparent>
    8000552c:	84aa                	mv	s1,a0
    8000552e:	14050b63          	beqz	a0,80005684 <create+0x17e>
    return 0;

  ilock(dp);
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	6ac080e7          	jalr	1708(ra) # 80003bde <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000553a:	4601                	li	a2,0
    8000553c:	fb040593          	addi	a1,s0,-80
    80005540:	8526                	mv	a0,s1
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	b80080e7          	jalr	-1152(ra) # 800040c2 <dirlookup>
    8000554a:	8aaa                	mv	s5,a0
    8000554c:	c921                	beqz	a0,8000559c <create+0x96>
    iunlockput(dp);
    8000554e:	8526                	mv	a0,s1
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	8f0080e7          	jalr	-1808(ra) # 80003e40 <iunlockput>
    ilock(ip);
    80005558:	8556                	mv	a0,s5
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	684080e7          	jalr	1668(ra) # 80003bde <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005562:	4789                	li	a5,2
    80005564:	02fb1563          	bne	s6,a5,8000558e <create+0x88>
    80005568:	044ad783          	lhu	a5,68(s5)
    8000556c:	37f9                	addiw	a5,a5,-2
    8000556e:	17c2                	slli	a5,a5,0x30
    80005570:	93c1                	srli	a5,a5,0x30
    80005572:	4705                	li	a4,1
    80005574:	00f76d63          	bltu	a4,a5,8000558e <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005578:	8556                	mv	a0,s5
    8000557a:	60a6                	ld	ra,72(sp)
    8000557c:	6406                	ld	s0,64(sp)
    8000557e:	74e2                	ld	s1,56(sp)
    80005580:	7942                	ld	s2,48(sp)
    80005582:	79a2                	ld	s3,40(sp)
    80005584:	7a02                	ld	s4,32(sp)
    80005586:	6ae2                	ld	s5,24(sp)
    80005588:	6b42                	ld	s6,16(sp)
    8000558a:	6161                	addi	sp,sp,80
    8000558c:	8082                	ret
    iunlockput(ip);
    8000558e:	8556                	mv	a0,s5
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	8b0080e7          	jalr	-1872(ra) # 80003e40 <iunlockput>
    return 0;
    80005598:	4a81                	li	s5,0
    8000559a:	bff9                	j	80005578 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000559c:	85da                	mv	a1,s6
    8000559e:	4088                	lw	a0,0(s1)
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	4a6080e7          	jalr	1190(ra) # 80003a46 <ialloc>
    800055a8:	8a2a                	mv	s4,a0
    800055aa:	c529                	beqz	a0,800055f4 <create+0xee>
  ilock(ip);
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	632080e7          	jalr	1586(ra) # 80003bde <ilock>
  ip->major = major;
    800055b4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800055b8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800055bc:	4905                	li	s2,1
    800055be:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800055c2:	8552                	mv	a0,s4
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	54e080e7          	jalr	1358(ra) # 80003b12 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055cc:	032b0b63          	beq	s6,s2,80005602 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800055d0:	004a2603          	lw	a2,4(s4)
    800055d4:	fb040593          	addi	a1,s0,-80
    800055d8:	8526                	mv	a0,s1
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	cf8080e7          	jalr	-776(ra) # 800042d2 <dirlink>
    800055e2:	06054f63          	bltz	a0,80005660 <create+0x15a>
  iunlockput(dp);
    800055e6:	8526                	mv	a0,s1
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	858080e7          	jalr	-1960(ra) # 80003e40 <iunlockput>
  return ip;
    800055f0:	8ad2                	mv	s5,s4
    800055f2:	b759                	j	80005578 <create+0x72>
    iunlockput(dp);
    800055f4:	8526                	mv	a0,s1
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	84a080e7          	jalr	-1974(ra) # 80003e40 <iunlockput>
    return 0;
    800055fe:	8ad2                	mv	s5,s4
    80005600:	bfa5                	j	80005578 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005602:	004a2603          	lw	a2,4(s4)
    80005606:	00003597          	auipc	a1,0x3
    8000560a:	15258593          	addi	a1,a1,338 # 80008758 <syscalls+0x2c0>
    8000560e:	8552                	mv	a0,s4
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	cc2080e7          	jalr	-830(ra) # 800042d2 <dirlink>
    80005618:	04054463          	bltz	a0,80005660 <create+0x15a>
    8000561c:	40d0                	lw	a2,4(s1)
    8000561e:	00003597          	auipc	a1,0x3
    80005622:	14258593          	addi	a1,a1,322 # 80008760 <syscalls+0x2c8>
    80005626:	8552                	mv	a0,s4
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	caa080e7          	jalr	-854(ra) # 800042d2 <dirlink>
    80005630:	02054863          	bltz	a0,80005660 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005634:	004a2603          	lw	a2,4(s4)
    80005638:	fb040593          	addi	a1,s0,-80
    8000563c:	8526                	mv	a0,s1
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	c94080e7          	jalr	-876(ra) # 800042d2 <dirlink>
    80005646:	00054d63          	bltz	a0,80005660 <create+0x15a>
    dp->nlink++;  // for ".."
    8000564a:	04a4d783          	lhu	a5,74(s1)
    8000564e:	2785                	addiw	a5,a5,1
    80005650:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005654:	8526                	mv	a0,s1
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	4bc080e7          	jalr	1212(ra) # 80003b12 <iupdate>
    8000565e:	b761                	j	800055e6 <create+0xe0>
  ip->nlink = 0;
    80005660:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005664:	8552                	mv	a0,s4
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	4ac080e7          	jalr	1196(ra) # 80003b12 <iupdate>
  iunlockput(ip);
    8000566e:	8552                	mv	a0,s4
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	7d0080e7          	jalr	2000(ra) # 80003e40 <iunlockput>
  iunlockput(dp);
    80005678:	8526                	mv	a0,s1
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	7c6080e7          	jalr	1990(ra) # 80003e40 <iunlockput>
  return 0;
    80005682:	bddd                	j	80005578 <create+0x72>
    return 0;
    80005684:	8aaa                	mv	s5,a0
    80005686:	bdcd                	j	80005578 <create+0x72>

0000000080005688 <sys_dup>:
{
    80005688:	7179                	addi	sp,sp,-48
    8000568a:	f406                	sd	ra,40(sp)
    8000568c:	f022                	sd	s0,32(sp)
    8000568e:	ec26                	sd	s1,24(sp)
    80005690:	e84a                	sd	s2,16(sp)
    80005692:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005694:	fd840613          	addi	a2,s0,-40
    80005698:	4581                	li	a1,0
    8000569a:	4501                	li	a0,0
    8000569c:	00000097          	auipc	ra,0x0
    800056a0:	dc8080e7          	jalr	-568(ra) # 80005464 <argfd>
    return -1;
    800056a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056a6:	02054363          	bltz	a0,800056cc <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800056aa:	fd843903          	ld	s2,-40(s0)
    800056ae:	854a                	mv	a0,s2
    800056b0:	00000097          	auipc	ra,0x0
    800056b4:	e14080e7          	jalr	-492(ra) # 800054c4 <fdalloc>
    800056b8:	84aa                	mv	s1,a0
    return -1;
    800056ba:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056bc:	00054863          	bltz	a0,800056cc <sys_dup+0x44>
  filedup(f);
    800056c0:	854a                	mv	a0,s2
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	334080e7          	jalr	820(ra) # 800049f6 <filedup>
  return fd;
    800056ca:	87a6                	mv	a5,s1
}
    800056cc:	853e                	mv	a0,a5
    800056ce:	70a2                	ld	ra,40(sp)
    800056d0:	7402                	ld	s0,32(sp)
    800056d2:	64e2                	ld	s1,24(sp)
    800056d4:	6942                	ld	s2,16(sp)
    800056d6:	6145                	addi	sp,sp,48
    800056d8:	8082                	ret

00000000800056da <sys_read>:
{
    800056da:	7179                	addi	sp,sp,-48
    800056dc:	f406                	sd	ra,40(sp)
    800056de:	f022                	sd	s0,32(sp)
    800056e0:	1800                	addi	s0,sp,48
  READCOUNT++;
    800056e2:	00003717          	auipc	a4,0x3
    800056e6:	27670713          	addi	a4,a4,630 # 80008958 <READCOUNT>
    800056ea:	631c                	ld	a5,0(a4)
    800056ec:	0785                	addi	a5,a5,1
    800056ee:	e31c                	sd	a5,0(a4)
  argaddr(1, &p);
    800056f0:	fd840593          	addi	a1,s0,-40
    800056f4:	4505                	li	a0,1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	86e080e7          	jalr	-1938(ra) # 80002f64 <argaddr>
  argint(2, &n);
    800056fe:	fe440593          	addi	a1,s0,-28
    80005702:	4509                	li	a0,2
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	840080e7          	jalr	-1984(ra) # 80002f44 <argint>
  if(argfd(0, 0, &f) < 0)
    8000570c:	fe840613          	addi	a2,s0,-24
    80005710:	4581                	li	a1,0
    80005712:	4501                	li	a0,0
    80005714:	00000097          	auipc	ra,0x0
    80005718:	d50080e7          	jalr	-688(ra) # 80005464 <argfd>
    8000571c:	87aa                	mv	a5,a0
    return -1;
    8000571e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005720:	0007cc63          	bltz	a5,80005738 <sys_read+0x5e>
  return fileread(f, p, n);
    80005724:	fe442603          	lw	a2,-28(s0)
    80005728:	fd843583          	ld	a1,-40(s0)
    8000572c:	fe843503          	ld	a0,-24(s0)
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	452080e7          	jalr	1106(ra) # 80004b82 <fileread>
}
    80005738:	70a2                	ld	ra,40(sp)
    8000573a:	7402                	ld	s0,32(sp)
    8000573c:	6145                	addi	sp,sp,48
    8000573e:	8082                	ret

0000000080005740 <sys_write>:
{
    80005740:	7179                	addi	sp,sp,-48
    80005742:	f406                	sd	ra,40(sp)
    80005744:	f022                	sd	s0,32(sp)
    80005746:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005748:	fd840593          	addi	a1,s0,-40
    8000574c:	4505                	li	a0,1
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	816080e7          	jalr	-2026(ra) # 80002f64 <argaddr>
  argint(2, &n);
    80005756:	fe440593          	addi	a1,s0,-28
    8000575a:	4509                	li	a0,2
    8000575c:	ffffd097          	auipc	ra,0xffffd
    80005760:	7e8080e7          	jalr	2024(ra) # 80002f44 <argint>
  if(argfd(0, 0, &f) < 0)
    80005764:	fe840613          	addi	a2,s0,-24
    80005768:	4581                	li	a1,0
    8000576a:	4501                	li	a0,0
    8000576c:	00000097          	auipc	ra,0x0
    80005770:	cf8080e7          	jalr	-776(ra) # 80005464 <argfd>
    80005774:	87aa                	mv	a5,a0
    return -1;
    80005776:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005778:	0007cc63          	bltz	a5,80005790 <sys_write+0x50>
  return filewrite(f, p, n);
    8000577c:	fe442603          	lw	a2,-28(s0)
    80005780:	fd843583          	ld	a1,-40(s0)
    80005784:	fe843503          	ld	a0,-24(s0)
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	4bc080e7          	jalr	1212(ra) # 80004c44 <filewrite>
}
    80005790:	70a2                	ld	ra,40(sp)
    80005792:	7402                	ld	s0,32(sp)
    80005794:	6145                	addi	sp,sp,48
    80005796:	8082                	ret

0000000080005798 <sys_close>:
{
    80005798:	1101                	addi	sp,sp,-32
    8000579a:	ec06                	sd	ra,24(sp)
    8000579c:	e822                	sd	s0,16(sp)
    8000579e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057a0:	fe040613          	addi	a2,s0,-32
    800057a4:	fec40593          	addi	a1,s0,-20
    800057a8:	4501                	li	a0,0
    800057aa:	00000097          	auipc	ra,0x0
    800057ae:	cba080e7          	jalr	-838(ra) # 80005464 <argfd>
    return -1;
    800057b2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057b4:	02054463          	bltz	a0,800057dc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057b8:	ffffc097          	auipc	ra,0xffffc
    800057bc:	216080e7          	jalr	534(ra) # 800019ce <myproc>
    800057c0:	fec42783          	lw	a5,-20(s0)
    800057c4:	07e9                	addi	a5,a5,26
    800057c6:	078e                	slli	a5,a5,0x3
    800057c8:	953e                	add	a0,a0,a5
    800057ca:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800057ce:	fe043503          	ld	a0,-32(s0)
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	276080e7          	jalr	630(ra) # 80004a48 <fileclose>
  return 0;
    800057da:	4781                	li	a5,0
}
    800057dc:	853e                	mv	a0,a5
    800057de:	60e2                	ld	ra,24(sp)
    800057e0:	6442                	ld	s0,16(sp)
    800057e2:	6105                	addi	sp,sp,32
    800057e4:	8082                	ret

00000000800057e6 <sys_fstat>:
{
    800057e6:	1101                	addi	sp,sp,-32
    800057e8:	ec06                	sd	ra,24(sp)
    800057ea:	e822                	sd	s0,16(sp)
    800057ec:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800057ee:	fe040593          	addi	a1,s0,-32
    800057f2:	4505                	li	a0,1
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	770080e7          	jalr	1904(ra) # 80002f64 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800057fc:	fe840613          	addi	a2,s0,-24
    80005800:	4581                	li	a1,0
    80005802:	4501                	li	a0,0
    80005804:	00000097          	auipc	ra,0x0
    80005808:	c60080e7          	jalr	-928(ra) # 80005464 <argfd>
    8000580c:	87aa                	mv	a5,a0
    return -1;
    8000580e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005810:	0007ca63          	bltz	a5,80005824 <sys_fstat+0x3e>
  return filestat(f, st);
    80005814:	fe043583          	ld	a1,-32(s0)
    80005818:	fe843503          	ld	a0,-24(s0)
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	2f4080e7          	jalr	756(ra) # 80004b10 <filestat>
}
    80005824:	60e2                	ld	ra,24(sp)
    80005826:	6442                	ld	s0,16(sp)
    80005828:	6105                	addi	sp,sp,32
    8000582a:	8082                	ret

000000008000582c <sys_link>:
{
    8000582c:	7169                	addi	sp,sp,-304
    8000582e:	f606                	sd	ra,296(sp)
    80005830:	f222                	sd	s0,288(sp)
    80005832:	ee26                	sd	s1,280(sp)
    80005834:	ea4a                	sd	s2,272(sp)
    80005836:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005838:	08000613          	li	a2,128
    8000583c:	ed040593          	addi	a1,s0,-304
    80005840:	4501                	li	a0,0
    80005842:	ffffd097          	auipc	ra,0xffffd
    80005846:	742080e7          	jalr	1858(ra) # 80002f84 <argstr>
    return -1;
    8000584a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000584c:	10054e63          	bltz	a0,80005968 <sys_link+0x13c>
    80005850:	08000613          	li	a2,128
    80005854:	f5040593          	addi	a1,s0,-176
    80005858:	4505                	li	a0,1
    8000585a:	ffffd097          	auipc	ra,0xffffd
    8000585e:	72a080e7          	jalr	1834(ra) # 80002f84 <argstr>
    return -1;
    80005862:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005864:	10054263          	bltz	a0,80005968 <sys_link+0x13c>
  begin_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	d1c080e7          	jalr	-740(ra) # 80004584 <begin_op>
  if((ip = namei(old)) == 0){
    80005870:	ed040513          	addi	a0,s0,-304
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	b10080e7          	jalr	-1264(ra) # 80004384 <namei>
    8000587c:	84aa                	mv	s1,a0
    8000587e:	c551                	beqz	a0,8000590a <sys_link+0xde>
  ilock(ip);
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	35e080e7          	jalr	862(ra) # 80003bde <ilock>
  if(ip->type == T_DIR){
    80005888:	04449703          	lh	a4,68(s1)
    8000588c:	4785                	li	a5,1
    8000588e:	08f70463          	beq	a4,a5,80005916 <sys_link+0xea>
  ip->nlink++;
    80005892:	04a4d783          	lhu	a5,74(s1)
    80005896:	2785                	addiw	a5,a5,1
    80005898:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	274080e7          	jalr	628(ra) # 80003b12 <iupdate>
  iunlock(ip);
    800058a6:	8526                	mv	a0,s1
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	3f8080e7          	jalr	1016(ra) # 80003ca0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058b0:	fd040593          	addi	a1,s0,-48
    800058b4:	f5040513          	addi	a0,s0,-176
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	aea080e7          	jalr	-1302(ra) # 800043a2 <nameiparent>
    800058c0:	892a                	mv	s2,a0
    800058c2:	c935                	beqz	a0,80005936 <sys_link+0x10a>
  ilock(dp);
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	31a080e7          	jalr	794(ra) # 80003bde <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058cc:	00092703          	lw	a4,0(s2)
    800058d0:	409c                	lw	a5,0(s1)
    800058d2:	04f71d63          	bne	a4,a5,8000592c <sys_link+0x100>
    800058d6:	40d0                	lw	a2,4(s1)
    800058d8:	fd040593          	addi	a1,s0,-48
    800058dc:	854a                	mv	a0,s2
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	9f4080e7          	jalr	-1548(ra) # 800042d2 <dirlink>
    800058e6:	04054363          	bltz	a0,8000592c <sys_link+0x100>
  iunlockput(dp);
    800058ea:	854a                	mv	a0,s2
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	554080e7          	jalr	1364(ra) # 80003e40 <iunlockput>
  iput(ip);
    800058f4:	8526                	mv	a0,s1
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	4a2080e7          	jalr	1186(ra) # 80003d98 <iput>
  end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	d00080e7          	jalr	-768(ra) # 800045fe <end_op>
  return 0;
    80005906:	4781                	li	a5,0
    80005908:	a085                	j	80005968 <sys_link+0x13c>
    end_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	cf4080e7          	jalr	-780(ra) # 800045fe <end_op>
    return -1;
    80005912:	57fd                	li	a5,-1
    80005914:	a891                	j	80005968 <sys_link+0x13c>
    iunlockput(ip);
    80005916:	8526                	mv	a0,s1
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	528080e7          	jalr	1320(ra) # 80003e40 <iunlockput>
    end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	cde080e7          	jalr	-802(ra) # 800045fe <end_op>
    return -1;
    80005928:	57fd                	li	a5,-1
    8000592a:	a83d                	j	80005968 <sys_link+0x13c>
    iunlockput(dp);
    8000592c:	854a                	mv	a0,s2
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	512080e7          	jalr	1298(ra) # 80003e40 <iunlockput>
  ilock(ip);
    80005936:	8526                	mv	a0,s1
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	2a6080e7          	jalr	678(ra) # 80003bde <ilock>
  ip->nlink--;
    80005940:	04a4d783          	lhu	a5,74(s1)
    80005944:	37fd                	addiw	a5,a5,-1
    80005946:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000594a:	8526                	mv	a0,s1
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	1c6080e7          	jalr	454(ra) # 80003b12 <iupdate>
  iunlockput(ip);
    80005954:	8526                	mv	a0,s1
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	4ea080e7          	jalr	1258(ra) # 80003e40 <iunlockput>
  end_op();
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	ca0080e7          	jalr	-864(ra) # 800045fe <end_op>
  return -1;
    80005966:	57fd                	li	a5,-1
}
    80005968:	853e                	mv	a0,a5
    8000596a:	70b2                	ld	ra,296(sp)
    8000596c:	7412                	ld	s0,288(sp)
    8000596e:	64f2                	ld	s1,280(sp)
    80005970:	6952                	ld	s2,272(sp)
    80005972:	6155                	addi	sp,sp,304
    80005974:	8082                	ret

0000000080005976 <sys_unlink>:
{
    80005976:	7151                	addi	sp,sp,-240
    80005978:	f586                	sd	ra,232(sp)
    8000597a:	f1a2                	sd	s0,224(sp)
    8000597c:	eda6                	sd	s1,216(sp)
    8000597e:	e9ca                	sd	s2,208(sp)
    80005980:	e5ce                	sd	s3,200(sp)
    80005982:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005984:	08000613          	li	a2,128
    80005988:	f3040593          	addi	a1,s0,-208
    8000598c:	4501                	li	a0,0
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	5f6080e7          	jalr	1526(ra) # 80002f84 <argstr>
    80005996:	18054163          	bltz	a0,80005b18 <sys_unlink+0x1a2>
  begin_op();
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	bea080e7          	jalr	-1046(ra) # 80004584 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059a2:	fb040593          	addi	a1,s0,-80
    800059a6:	f3040513          	addi	a0,s0,-208
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	9f8080e7          	jalr	-1544(ra) # 800043a2 <nameiparent>
    800059b2:	84aa                	mv	s1,a0
    800059b4:	c979                	beqz	a0,80005a8a <sys_unlink+0x114>
  ilock(dp);
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	228080e7          	jalr	552(ra) # 80003bde <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059be:	00003597          	auipc	a1,0x3
    800059c2:	d9a58593          	addi	a1,a1,-614 # 80008758 <syscalls+0x2c0>
    800059c6:	fb040513          	addi	a0,s0,-80
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	6de080e7          	jalr	1758(ra) # 800040a8 <namecmp>
    800059d2:	14050a63          	beqz	a0,80005b26 <sys_unlink+0x1b0>
    800059d6:	00003597          	auipc	a1,0x3
    800059da:	d8a58593          	addi	a1,a1,-630 # 80008760 <syscalls+0x2c8>
    800059de:	fb040513          	addi	a0,s0,-80
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	6c6080e7          	jalr	1734(ra) # 800040a8 <namecmp>
    800059ea:	12050e63          	beqz	a0,80005b26 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059ee:	f2c40613          	addi	a2,s0,-212
    800059f2:	fb040593          	addi	a1,s0,-80
    800059f6:	8526                	mv	a0,s1
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	6ca080e7          	jalr	1738(ra) # 800040c2 <dirlookup>
    80005a00:	892a                	mv	s2,a0
    80005a02:	12050263          	beqz	a0,80005b26 <sys_unlink+0x1b0>
  ilock(ip);
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	1d8080e7          	jalr	472(ra) # 80003bde <ilock>
  if(ip->nlink < 1)
    80005a0e:	04a91783          	lh	a5,74(s2)
    80005a12:	08f05263          	blez	a5,80005a96 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a16:	04491703          	lh	a4,68(s2)
    80005a1a:	4785                	li	a5,1
    80005a1c:	08f70563          	beq	a4,a5,80005aa6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a20:	4641                	li	a2,16
    80005a22:	4581                	li	a1,0
    80005a24:	fc040513          	addi	a0,s0,-64
    80005a28:	ffffb097          	auipc	ra,0xffffb
    80005a2c:	2a6080e7          	jalr	678(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a30:	4741                	li	a4,16
    80005a32:	f2c42683          	lw	a3,-212(s0)
    80005a36:	fc040613          	addi	a2,s0,-64
    80005a3a:	4581                	li	a1,0
    80005a3c:	8526                	mv	a0,s1
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	54c080e7          	jalr	1356(ra) # 80003f8a <writei>
    80005a46:	47c1                	li	a5,16
    80005a48:	0af51563          	bne	a0,a5,80005af2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a4c:	04491703          	lh	a4,68(s2)
    80005a50:	4785                	li	a5,1
    80005a52:	0af70863          	beq	a4,a5,80005b02 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a56:	8526                	mv	a0,s1
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	3e8080e7          	jalr	1000(ra) # 80003e40 <iunlockput>
  ip->nlink--;
    80005a60:	04a95783          	lhu	a5,74(s2)
    80005a64:	37fd                	addiw	a5,a5,-1
    80005a66:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a6a:	854a                	mv	a0,s2
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	0a6080e7          	jalr	166(ra) # 80003b12 <iupdate>
  iunlockput(ip);
    80005a74:	854a                	mv	a0,s2
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	3ca080e7          	jalr	970(ra) # 80003e40 <iunlockput>
  end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	b80080e7          	jalr	-1152(ra) # 800045fe <end_op>
  return 0;
    80005a86:	4501                	li	a0,0
    80005a88:	a84d                	j	80005b3a <sys_unlink+0x1c4>
    end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	b74080e7          	jalr	-1164(ra) # 800045fe <end_op>
    return -1;
    80005a92:	557d                	li	a0,-1
    80005a94:	a05d                	j	80005b3a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a96:	00003517          	auipc	a0,0x3
    80005a9a:	cd250513          	addi	a0,a0,-814 # 80008768 <syscalls+0x2d0>
    80005a9e:	ffffb097          	auipc	ra,0xffffb
    80005aa2:	a9e080e7          	jalr	-1378(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aa6:	04c92703          	lw	a4,76(s2)
    80005aaa:	02000793          	li	a5,32
    80005aae:	f6e7f9e3          	bgeu	a5,a4,80005a20 <sys_unlink+0xaa>
    80005ab2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ab6:	4741                	li	a4,16
    80005ab8:	86ce                	mv	a3,s3
    80005aba:	f1840613          	addi	a2,s0,-232
    80005abe:	4581                	li	a1,0
    80005ac0:	854a                	mv	a0,s2
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	3d0080e7          	jalr	976(ra) # 80003e92 <readi>
    80005aca:	47c1                	li	a5,16
    80005acc:	00f51b63          	bne	a0,a5,80005ae2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ad0:	f1845783          	lhu	a5,-232(s0)
    80005ad4:	e7a1                	bnez	a5,80005b1c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ad6:	29c1                	addiw	s3,s3,16
    80005ad8:	04c92783          	lw	a5,76(s2)
    80005adc:	fcf9ede3          	bltu	s3,a5,80005ab6 <sys_unlink+0x140>
    80005ae0:	b781                	j	80005a20 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ae2:	00003517          	auipc	a0,0x3
    80005ae6:	c9e50513          	addi	a0,a0,-866 # 80008780 <syscalls+0x2e8>
    80005aea:	ffffb097          	auipc	ra,0xffffb
    80005aee:	a52080e7          	jalr	-1454(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005af2:	00003517          	auipc	a0,0x3
    80005af6:	ca650513          	addi	a0,a0,-858 # 80008798 <syscalls+0x300>
    80005afa:	ffffb097          	auipc	ra,0xffffb
    80005afe:	a42080e7          	jalr	-1470(ra) # 8000053c <panic>
    dp->nlink--;
    80005b02:	04a4d783          	lhu	a5,74(s1)
    80005b06:	37fd                	addiw	a5,a5,-1
    80005b08:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b0c:	8526                	mv	a0,s1
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	004080e7          	jalr	4(ra) # 80003b12 <iupdate>
    80005b16:	b781                	j	80005a56 <sys_unlink+0xe0>
    return -1;
    80005b18:	557d                	li	a0,-1
    80005b1a:	a005                	j	80005b3a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b1c:	854a                	mv	a0,s2
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	322080e7          	jalr	802(ra) # 80003e40 <iunlockput>
  iunlockput(dp);
    80005b26:	8526                	mv	a0,s1
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	318080e7          	jalr	792(ra) # 80003e40 <iunlockput>
  end_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	ace080e7          	jalr	-1330(ra) # 800045fe <end_op>
  return -1;
    80005b38:	557d                	li	a0,-1
}
    80005b3a:	70ae                	ld	ra,232(sp)
    80005b3c:	740e                	ld	s0,224(sp)
    80005b3e:	64ee                	ld	s1,216(sp)
    80005b40:	694e                	ld	s2,208(sp)
    80005b42:	69ae                	ld	s3,200(sp)
    80005b44:	616d                	addi	sp,sp,240
    80005b46:	8082                	ret

0000000080005b48 <sys_open>:

uint64
sys_open(void)
{
    80005b48:	7131                	addi	sp,sp,-192
    80005b4a:	fd06                	sd	ra,184(sp)
    80005b4c:	f922                	sd	s0,176(sp)
    80005b4e:	f526                	sd	s1,168(sp)
    80005b50:	f14a                	sd	s2,160(sp)
    80005b52:	ed4e                	sd	s3,152(sp)
    80005b54:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b56:	f4c40593          	addi	a1,s0,-180
    80005b5a:	4505                	li	a0,1
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	3e8080e7          	jalr	1000(ra) # 80002f44 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b64:	08000613          	li	a2,128
    80005b68:	f5040593          	addi	a1,s0,-176
    80005b6c:	4501                	li	a0,0
    80005b6e:	ffffd097          	auipc	ra,0xffffd
    80005b72:	416080e7          	jalr	1046(ra) # 80002f84 <argstr>
    80005b76:	87aa                	mv	a5,a0
    return -1;
    80005b78:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b7a:	0a07c863          	bltz	a5,80005c2a <sys_open+0xe2>

  begin_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	a06080e7          	jalr	-1530(ra) # 80004584 <begin_op>

  if(omode & O_CREATE){
    80005b86:	f4c42783          	lw	a5,-180(s0)
    80005b8a:	2007f793          	andi	a5,a5,512
    80005b8e:	cbdd                	beqz	a5,80005c44 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005b90:	4681                	li	a3,0
    80005b92:	4601                	li	a2,0
    80005b94:	4589                	li	a1,2
    80005b96:	f5040513          	addi	a0,s0,-176
    80005b9a:	00000097          	auipc	ra,0x0
    80005b9e:	96c080e7          	jalr	-1684(ra) # 80005506 <create>
    80005ba2:	84aa                	mv	s1,a0
    if(ip == 0){
    80005ba4:	c951                	beqz	a0,80005c38 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ba6:	04449703          	lh	a4,68(s1)
    80005baa:	478d                	li	a5,3
    80005bac:	00f71763          	bne	a4,a5,80005bba <sys_open+0x72>
    80005bb0:	0464d703          	lhu	a4,70(s1)
    80005bb4:	47a5                	li	a5,9
    80005bb6:	0ce7ec63          	bltu	a5,a4,80005c8e <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	dd2080e7          	jalr	-558(ra) # 8000498c <filealloc>
    80005bc2:	892a                	mv	s2,a0
    80005bc4:	c56d                	beqz	a0,80005cae <sys_open+0x166>
    80005bc6:	00000097          	auipc	ra,0x0
    80005bca:	8fe080e7          	jalr	-1794(ra) # 800054c4 <fdalloc>
    80005bce:	89aa                	mv	s3,a0
    80005bd0:	0c054a63          	bltz	a0,80005ca4 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bd4:	04449703          	lh	a4,68(s1)
    80005bd8:	478d                	li	a5,3
    80005bda:	0ef70563          	beq	a4,a5,80005cc4 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bde:	4789                	li	a5,2
    80005be0:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005be4:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005be8:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005bec:	f4c42783          	lw	a5,-180(s0)
    80005bf0:	0017c713          	xori	a4,a5,1
    80005bf4:	8b05                	andi	a4,a4,1
    80005bf6:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bfa:	0037f713          	andi	a4,a5,3
    80005bfe:	00e03733          	snez	a4,a4
    80005c02:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c06:	4007f793          	andi	a5,a5,1024
    80005c0a:	c791                	beqz	a5,80005c16 <sys_open+0xce>
    80005c0c:	04449703          	lh	a4,68(s1)
    80005c10:	4789                	li	a5,2
    80005c12:	0cf70063          	beq	a4,a5,80005cd2 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005c16:	8526                	mv	a0,s1
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	088080e7          	jalr	136(ra) # 80003ca0 <iunlock>
  end_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	9de080e7          	jalr	-1570(ra) # 800045fe <end_op>

  return fd;
    80005c28:	854e                	mv	a0,s3
}
    80005c2a:	70ea                	ld	ra,184(sp)
    80005c2c:	744a                	ld	s0,176(sp)
    80005c2e:	74aa                	ld	s1,168(sp)
    80005c30:	790a                	ld	s2,160(sp)
    80005c32:	69ea                	ld	s3,152(sp)
    80005c34:	6129                	addi	sp,sp,192
    80005c36:	8082                	ret
      end_op();
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	9c6080e7          	jalr	-1594(ra) # 800045fe <end_op>
      return -1;
    80005c40:	557d                	li	a0,-1
    80005c42:	b7e5                	j	80005c2a <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005c44:	f5040513          	addi	a0,s0,-176
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	73c080e7          	jalr	1852(ra) # 80004384 <namei>
    80005c50:	84aa                	mv	s1,a0
    80005c52:	c905                	beqz	a0,80005c82 <sys_open+0x13a>
    ilock(ip);
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	f8a080e7          	jalr	-118(ra) # 80003bde <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c5c:	04449703          	lh	a4,68(s1)
    80005c60:	4785                	li	a5,1
    80005c62:	f4f712e3          	bne	a4,a5,80005ba6 <sys_open+0x5e>
    80005c66:	f4c42783          	lw	a5,-180(s0)
    80005c6a:	dba1                	beqz	a5,80005bba <sys_open+0x72>
      iunlockput(ip);
    80005c6c:	8526                	mv	a0,s1
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	1d2080e7          	jalr	466(ra) # 80003e40 <iunlockput>
      end_op();
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	988080e7          	jalr	-1656(ra) # 800045fe <end_op>
      return -1;
    80005c7e:	557d                	li	a0,-1
    80005c80:	b76d                	j	80005c2a <sys_open+0xe2>
      end_op();
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	97c080e7          	jalr	-1668(ra) # 800045fe <end_op>
      return -1;
    80005c8a:	557d                	li	a0,-1
    80005c8c:	bf79                	j	80005c2a <sys_open+0xe2>
    iunlockput(ip);
    80005c8e:	8526                	mv	a0,s1
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	1b0080e7          	jalr	432(ra) # 80003e40 <iunlockput>
    end_op();
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	966080e7          	jalr	-1690(ra) # 800045fe <end_op>
    return -1;
    80005ca0:	557d                	li	a0,-1
    80005ca2:	b761                	j	80005c2a <sys_open+0xe2>
      fileclose(f);
    80005ca4:	854a                	mv	a0,s2
    80005ca6:	fffff097          	auipc	ra,0xfffff
    80005caa:	da2080e7          	jalr	-606(ra) # 80004a48 <fileclose>
    iunlockput(ip);
    80005cae:	8526                	mv	a0,s1
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	190080e7          	jalr	400(ra) # 80003e40 <iunlockput>
    end_op();
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	946080e7          	jalr	-1722(ra) # 800045fe <end_op>
    return -1;
    80005cc0:	557d                	li	a0,-1
    80005cc2:	b7a5                	j	80005c2a <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005cc4:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005cc8:	04649783          	lh	a5,70(s1)
    80005ccc:	02f91223          	sh	a5,36(s2)
    80005cd0:	bf21                	j	80005be8 <sys_open+0xa0>
    itrunc(ip);
    80005cd2:	8526                	mv	a0,s1
    80005cd4:	ffffe097          	auipc	ra,0xffffe
    80005cd8:	018080e7          	jalr	24(ra) # 80003cec <itrunc>
    80005cdc:	bf2d                	j	80005c16 <sys_open+0xce>

0000000080005cde <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cde:	7175                	addi	sp,sp,-144
    80005ce0:	e506                	sd	ra,136(sp)
    80005ce2:	e122                	sd	s0,128(sp)
    80005ce4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	89e080e7          	jalr	-1890(ra) # 80004584 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cee:	08000613          	li	a2,128
    80005cf2:	f7040593          	addi	a1,s0,-144
    80005cf6:	4501                	li	a0,0
    80005cf8:	ffffd097          	auipc	ra,0xffffd
    80005cfc:	28c080e7          	jalr	652(ra) # 80002f84 <argstr>
    80005d00:	02054963          	bltz	a0,80005d32 <sys_mkdir+0x54>
    80005d04:	4681                	li	a3,0
    80005d06:	4601                	li	a2,0
    80005d08:	4585                	li	a1,1
    80005d0a:	f7040513          	addi	a0,s0,-144
    80005d0e:	fffff097          	auipc	ra,0xfffff
    80005d12:	7f8080e7          	jalr	2040(ra) # 80005506 <create>
    80005d16:	cd11                	beqz	a0,80005d32 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	128080e7          	jalr	296(ra) # 80003e40 <iunlockput>
  end_op();
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	8de080e7          	jalr	-1826(ra) # 800045fe <end_op>
  return 0;
    80005d28:	4501                	li	a0,0
}
    80005d2a:	60aa                	ld	ra,136(sp)
    80005d2c:	640a                	ld	s0,128(sp)
    80005d2e:	6149                	addi	sp,sp,144
    80005d30:	8082                	ret
    end_op();
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	8cc080e7          	jalr	-1844(ra) # 800045fe <end_op>
    return -1;
    80005d3a:	557d                	li	a0,-1
    80005d3c:	b7fd                	j	80005d2a <sys_mkdir+0x4c>

0000000080005d3e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d3e:	7135                	addi	sp,sp,-160
    80005d40:	ed06                	sd	ra,152(sp)
    80005d42:	e922                	sd	s0,144(sp)
    80005d44:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d46:	fffff097          	auipc	ra,0xfffff
    80005d4a:	83e080e7          	jalr	-1986(ra) # 80004584 <begin_op>
  argint(1, &major);
    80005d4e:	f6c40593          	addi	a1,s0,-148
    80005d52:	4505                	li	a0,1
    80005d54:	ffffd097          	auipc	ra,0xffffd
    80005d58:	1f0080e7          	jalr	496(ra) # 80002f44 <argint>
  argint(2, &minor);
    80005d5c:	f6840593          	addi	a1,s0,-152
    80005d60:	4509                	li	a0,2
    80005d62:	ffffd097          	auipc	ra,0xffffd
    80005d66:	1e2080e7          	jalr	482(ra) # 80002f44 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d6a:	08000613          	li	a2,128
    80005d6e:	f7040593          	addi	a1,s0,-144
    80005d72:	4501                	li	a0,0
    80005d74:	ffffd097          	auipc	ra,0xffffd
    80005d78:	210080e7          	jalr	528(ra) # 80002f84 <argstr>
    80005d7c:	02054b63          	bltz	a0,80005db2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d80:	f6841683          	lh	a3,-152(s0)
    80005d84:	f6c41603          	lh	a2,-148(s0)
    80005d88:	458d                	li	a1,3
    80005d8a:	f7040513          	addi	a0,s0,-144
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	778080e7          	jalr	1912(ra) # 80005506 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d96:	cd11                	beqz	a0,80005db2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d98:	ffffe097          	auipc	ra,0xffffe
    80005d9c:	0a8080e7          	jalr	168(ra) # 80003e40 <iunlockput>
  end_op();
    80005da0:	fffff097          	auipc	ra,0xfffff
    80005da4:	85e080e7          	jalr	-1954(ra) # 800045fe <end_op>
  return 0;
    80005da8:	4501                	li	a0,0
}
    80005daa:	60ea                	ld	ra,152(sp)
    80005dac:	644a                	ld	s0,144(sp)
    80005dae:	610d                	addi	sp,sp,160
    80005db0:	8082                	ret
    end_op();
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	84c080e7          	jalr	-1972(ra) # 800045fe <end_op>
    return -1;
    80005dba:	557d                	li	a0,-1
    80005dbc:	b7fd                	j	80005daa <sys_mknod+0x6c>

0000000080005dbe <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dbe:	7135                	addi	sp,sp,-160
    80005dc0:	ed06                	sd	ra,152(sp)
    80005dc2:	e922                	sd	s0,144(sp)
    80005dc4:	e526                	sd	s1,136(sp)
    80005dc6:	e14a                	sd	s2,128(sp)
    80005dc8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dca:	ffffc097          	auipc	ra,0xffffc
    80005dce:	c04080e7          	jalr	-1020(ra) # 800019ce <myproc>
    80005dd2:	892a                	mv	s2,a0
  
  begin_op();
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	7b0080e7          	jalr	1968(ra) # 80004584 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ddc:	08000613          	li	a2,128
    80005de0:	f6040593          	addi	a1,s0,-160
    80005de4:	4501                	li	a0,0
    80005de6:	ffffd097          	auipc	ra,0xffffd
    80005dea:	19e080e7          	jalr	414(ra) # 80002f84 <argstr>
    80005dee:	04054b63          	bltz	a0,80005e44 <sys_chdir+0x86>
    80005df2:	f6040513          	addi	a0,s0,-160
    80005df6:	ffffe097          	auipc	ra,0xffffe
    80005dfa:	58e080e7          	jalr	1422(ra) # 80004384 <namei>
    80005dfe:	84aa                	mv	s1,a0
    80005e00:	c131                	beqz	a0,80005e44 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e02:	ffffe097          	auipc	ra,0xffffe
    80005e06:	ddc080e7          	jalr	-548(ra) # 80003bde <ilock>
  if(ip->type != T_DIR){
    80005e0a:	04449703          	lh	a4,68(s1)
    80005e0e:	4785                	li	a5,1
    80005e10:	04f71063          	bne	a4,a5,80005e50 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e14:	8526                	mv	a0,s1
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	e8a080e7          	jalr	-374(ra) # 80003ca0 <iunlock>
  iput(p->cwd);
    80005e1e:	15093503          	ld	a0,336(s2)
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	f76080e7          	jalr	-138(ra) # 80003d98 <iput>
  end_op();
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	7d4080e7          	jalr	2004(ra) # 800045fe <end_op>
  p->cwd = ip;
    80005e32:	14993823          	sd	s1,336(s2)
  return 0;
    80005e36:	4501                	li	a0,0
}
    80005e38:	60ea                	ld	ra,152(sp)
    80005e3a:	644a                	ld	s0,144(sp)
    80005e3c:	64aa                	ld	s1,136(sp)
    80005e3e:	690a                	ld	s2,128(sp)
    80005e40:	610d                	addi	sp,sp,160
    80005e42:	8082                	ret
    end_op();
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	7ba080e7          	jalr	1978(ra) # 800045fe <end_op>
    return -1;
    80005e4c:	557d                	li	a0,-1
    80005e4e:	b7ed                	j	80005e38 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e50:	8526                	mv	a0,s1
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	fee080e7          	jalr	-18(ra) # 80003e40 <iunlockput>
    end_op();
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	7a4080e7          	jalr	1956(ra) # 800045fe <end_op>
    return -1;
    80005e62:	557d                	li	a0,-1
    80005e64:	bfd1                	j	80005e38 <sys_chdir+0x7a>

0000000080005e66 <sys_exec>:

uint64
sys_exec(void)
{
    80005e66:	7121                	addi	sp,sp,-448
    80005e68:	ff06                	sd	ra,440(sp)
    80005e6a:	fb22                	sd	s0,432(sp)
    80005e6c:	f726                	sd	s1,424(sp)
    80005e6e:	f34a                	sd	s2,416(sp)
    80005e70:	ef4e                	sd	s3,408(sp)
    80005e72:	eb52                	sd	s4,400(sp)
    80005e74:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e76:	e4840593          	addi	a1,s0,-440
    80005e7a:	4505                	li	a0,1
    80005e7c:	ffffd097          	auipc	ra,0xffffd
    80005e80:	0e8080e7          	jalr	232(ra) # 80002f64 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e84:	08000613          	li	a2,128
    80005e88:	f5040593          	addi	a1,s0,-176
    80005e8c:	4501                	li	a0,0
    80005e8e:	ffffd097          	auipc	ra,0xffffd
    80005e92:	0f6080e7          	jalr	246(ra) # 80002f84 <argstr>
    80005e96:	87aa                	mv	a5,a0
    return -1;
    80005e98:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e9a:	0c07c263          	bltz	a5,80005f5e <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005e9e:	10000613          	li	a2,256
    80005ea2:	4581                	li	a1,0
    80005ea4:	e5040513          	addi	a0,s0,-432
    80005ea8:	ffffb097          	auipc	ra,0xffffb
    80005eac:	e26080e7          	jalr	-474(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005eb0:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005eb4:	89a6                	mv	s3,s1
    80005eb6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005eb8:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ebc:	00391513          	slli	a0,s2,0x3
    80005ec0:	e4040593          	addi	a1,s0,-448
    80005ec4:	e4843783          	ld	a5,-440(s0)
    80005ec8:	953e                	add	a0,a0,a5
    80005eca:	ffffd097          	auipc	ra,0xffffd
    80005ece:	fdc080e7          	jalr	-36(ra) # 80002ea6 <fetchaddr>
    80005ed2:	02054a63          	bltz	a0,80005f06 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005ed6:	e4043783          	ld	a5,-448(s0)
    80005eda:	c3b9                	beqz	a5,80005f20 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005edc:	ffffb097          	auipc	ra,0xffffb
    80005ee0:	c06080e7          	jalr	-1018(ra) # 80000ae2 <kalloc>
    80005ee4:	85aa                	mv	a1,a0
    80005ee6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005eea:	cd11                	beqz	a0,80005f06 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005eec:	6605                	lui	a2,0x1
    80005eee:	e4043503          	ld	a0,-448(s0)
    80005ef2:	ffffd097          	auipc	ra,0xffffd
    80005ef6:	006080e7          	jalr	6(ra) # 80002ef8 <fetchstr>
    80005efa:	00054663          	bltz	a0,80005f06 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005efe:	0905                	addi	s2,s2,1
    80005f00:	09a1                	addi	s3,s3,8
    80005f02:	fb491de3          	bne	s2,s4,80005ebc <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f06:	f5040913          	addi	s2,s0,-176
    80005f0a:	6088                	ld	a0,0(s1)
    80005f0c:	c921                	beqz	a0,80005f5c <sys_exec+0xf6>
    kfree(argv[i]);
    80005f0e:	ffffb097          	auipc	ra,0xffffb
    80005f12:	ad6080e7          	jalr	-1322(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f16:	04a1                	addi	s1,s1,8
    80005f18:	ff2499e3          	bne	s1,s2,80005f0a <sys_exec+0xa4>
  return -1;
    80005f1c:	557d                	li	a0,-1
    80005f1e:	a081                	j	80005f5e <sys_exec+0xf8>
      argv[i] = 0;
    80005f20:	0009079b          	sext.w	a5,s2
    80005f24:	078e                	slli	a5,a5,0x3
    80005f26:	fd078793          	addi	a5,a5,-48
    80005f2a:	97a2                	add	a5,a5,s0
    80005f2c:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005f30:	e5040593          	addi	a1,s0,-432
    80005f34:	f5040513          	addi	a0,s0,-176
    80005f38:	fffff097          	auipc	ra,0xfffff
    80005f3c:	186080e7          	jalr	390(ra) # 800050be <exec>
    80005f40:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f42:	f5040993          	addi	s3,s0,-176
    80005f46:	6088                	ld	a0,0(s1)
    80005f48:	c901                	beqz	a0,80005f58 <sys_exec+0xf2>
    kfree(argv[i]);
    80005f4a:	ffffb097          	auipc	ra,0xffffb
    80005f4e:	a9a080e7          	jalr	-1382(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f52:	04a1                	addi	s1,s1,8
    80005f54:	ff3499e3          	bne	s1,s3,80005f46 <sys_exec+0xe0>
  return ret;
    80005f58:	854a                	mv	a0,s2
    80005f5a:	a011                	j	80005f5e <sys_exec+0xf8>
  return -1;
    80005f5c:	557d                	li	a0,-1
}
    80005f5e:	70fa                	ld	ra,440(sp)
    80005f60:	745a                	ld	s0,432(sp)
    80005f62:	74ba                	ld	s1,424(sp)
    80005f64:	791a                	ld	s2,416(sp)
    80005f66:	69fa                	ld	s3,408(sp)
    80005f68:	6a5a                	ld	s4,400(sp)
    80005f6a:	6139                	addi	sp,sp,448
    80005f6c:	8082                	ret

0000000080005f6e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f6e:	7139                	addi	sp,sp,-64
    80005f70:	fc06                	sd	ra,56(sp)
    80005f72:	f822                	sd	s0,48(sp)
    80005f74:	f426                	sd	s1,40(sp)
    80005f76:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	a56080e7          	jalr	-1450(ra) # 800019ce <myproc>
    80005f80:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f82:	fd840593          	addi	a1,s0,-40
    80005f86:	4501                	li	a0,0
    80005f88:	ffffd097          	auipc	ra,0xffffd
    80005f8c:	fdc080e7          	jalr	-36(ra) # 80002f64 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f90:	fc840593          	addi	a1,s0,-56
    80005f94:	fd040513          	addi	a0,s0,-48
    80005f98:	fffff097          	auipc	ra,0xfffff
    80005f9c:	ddc080e7          	jalr	-548(ra) # 80004d74 <pipealloc>
    return -1;
    80005fa0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fa2:	0c054463          	bltz	a0,8000606a <sys_pipe+0xfc>
  fd0 = -1;
    80005fa6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005faa:	fd043503          	ld	a0,-48(s0)
    80005fae:	fffff097          	auipc	ra,0xfffff
    80005fb2:	516080e7          	jalr	1302(ra) # 800054c4 <fdalloc>
    80005fb6:	fca42223          	sw	a0,-60(s0)
    80005fba:	08054b63          	bltz	a0,80006050 <sys_pipe+0xe2>
    80005fbe:	fc843503          	ld	a0,-56(s0)
    80005fc2:	fffff097          	auipc	ra,0xfffff
    80005fc6:	502080e7          	jalr	1282(ra) # 800054c4 <fdalloc>
    80005fca:	fca42023          	sw	a0,-64(s0)
    80005fce:	06054863          	bltz	a0,8000603e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fd2:	4691                	li	a3,4
    80005fd4:	fc440613          	addi	a2,s0,-60
    80005fd8:	fd843583          	ld	a1,-40(s0)
    80005fdc:	68a8                	ld	a0,80(s1)
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	688080e7          	jalr	1672(ra) # 80001666 <copyout>
    80005fe6:	02054063          	bltz	a0,80006006 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fea:	4691                	li	a3,4
    80005fec:	fc040613          	addi	a2,s0,-64
    80005ff0:	fd843583          	ld	a1,-40(s0)
    80005ff4:	0591                	addi	a1,a1,4
    80005ff6:	68a8                	ld	a0,80(s1)
    80005ff8:	ffffb097          	auipc	ra,0xffffb
    80005ffc:	66e080e7          	jalr	1646(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006000:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006002:	06055463          	bgez	a0,8000606a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006006:	fc442783          	lw	a5,-60(s0)
    8000600a:	07e9                	addi	a5,a5,26
    8000600c:	078e                	slli	a5,a5,0x3
    8000600e:	97a6                	add	a5,a5,s1
    80006010:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006014:	fc042783          	lw	a5,-64(s0)
    80006018:	07e9                	addi	a5,a5,26
    8000601a:	078e                	slli	a5,a5,0x3
    8000601c:	94be                	add	s1,s1,a5
    8000601e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006022:	fd043503          	ld	a0,-48(s0)
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	a22080e7          	jalr	-1502(ra) # 80004a48 <fileclose>
    fileclose(wf);
    8000602e:	fc843503          	ld	a0,-56(s0)
    80006032:	fffff097          	auipc	ra,0xfffff
    80006036:	a16080e7          	jalr	-1514(ra) # 80004a48 <fileclose>
    return -1;
    8000603a:	57fd                	li	a5,-1
    8000603c:	a03d                	j	8000606a <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000603e:	fc442783          	lw	a5,-60(s0)
    80006042:	0007c763          	bltz	a5,80006050 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006046:	07e9                	addi	a5,a5,26
    80006048:	078e                	slli	a5,a5,0x3
    8000604a:	97a6                	add	a5,a5,s1
    8000604c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006050:	fd043503          	ld	a0,-48(s0)
    80006054:	fffff097          	auipc	ra,0xfffff
    80006058:	9f4080e7          	jalr	-1548(ra) # 80004a48 <fileclose>
    fileclose(wf);
    8000605c:	fc843503          	ld	a0,-56(s0)
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	9e8080e7          	jalr	-1560(ra) # 80004a48 <fileclose>
    return -1;
    80006068:	57fd                	li	a5,-1
}
    8000606a:	853e                	mv	a0,a5
    8000606c:	70e2                	ld	ra,56(sp)
    8000606e:	7442                	ld	s0,48(sp)
    80006070:	74a2                	ld	s1,40(sp)
    80006072:	6121                	addi	sp,sp,64
    80006074:	8082                	ret
	...

0000000080006080 <kernelvec>:
    80006080:	7111                	addi	sp,sp,-256
    80006082:	e006                	sd	ra,0(sp)
    80006084:	e40a                	sd	sp,8(sp)
    80006086:	e80e                	sd	gp,16(sp)
    80006088:	ec12                	sd	tp,24(sp)
    8000608a:	f016                	sd	t0,32(sp)
    8000608c:	f41a                	sd	t1,40(sp)
    8000608e:	f81e                	sd	t2,48(sp)
    80006090:	fc22                	sd	s0,56(sp)
    80006092:	e0a6                	sd	s1,64(sp)
    80006094:	e4aa                	sd	a0,72(sp)
    80006096:	e8ae                	sd	a1,80(sp)
    80006098:	ecb2                	sd	a2,88(sp)
    8000609a:	f0b6                	sd	a3,96(sp)
    8000609c:	f4ba                	sd	a4,104(sp)
    8000609e:	f8be                	sd	a5,112(sp)
    800060a0:	fcc2                	sd	a6,120(sp)
    800060a2:	e146                	sd	a7,128(sp)
    800060a4:	e54a                	sd	s2,136(sp)
    800060a6:	e94e                	sd	s3,144(sp)
    800060a8:	ed52                	sd	s4,152(sp)
    800060aa:	f156                	sd	s5,160(sp)
    800060ac:	f55a                	sd	s6,168(sp)
    800060ae:	f95e                	sd	s7,176(sp)
    800060b0:	fd62                	sd	s8,184(sp)
    800060b2:	e1e6                	sd	s9,192(sp)
    800060b4:	e5ea                	sd	s10,200(sp)
    800060b6:	e9ee                	sd	s11,208(sp)
    800060b8:	edf2                	sd	t3,216(sp)
    800060ba:	f1f6                	sd	t4,224(sp)
    800060bc:	f5fa                	sd	t5,232(sp)
    800060be:	f9fe                	sd	t6,240(sp)
    800060c0:	cc9fc0ef          	jal	ra,80002d88 <kerneltrap>
    800060c4:	6082                	ld	ra,0(sp)
    800060c6:	6122                	ld	sp,8(sp)
    800060c8:	61c2                	ld	gp,16(sp)
    800060ca:	7282                	ld	t0,32(sp)
    800060cc:	7322                	ld	t1,40(sp)
    800060ce:	73c2                	ld	t2,48(sp)
    800060d0:	7462                	ld	s0,56(sp)
    800060d2:	6486                	ld	s1,64(sp)
    800060d4:	6526                	ld	a0,72(sp)
    800060d6:	65c6                	ld	a1,80(sp)
    800060d8:	6666                	ld	a2,88(sp)
    800060da:	7686                	ld	a3,96(sp)
    800060dc:	7726                	ld	a4,104(sp)
    800060de:	77c6                	ld	a5,112(sp)
    800060e0:	7866                	ld	a6,120(sp)
    800060e2:	688a                	ld	a7,128(sp)
    800060e4:	692a                	ld	s2,136(sp)
    800060e6:	69ca                	ld	s3,144(sp)
    800060e8:	6a6a                	ld	s4,152(sp)
    800060ea:	7a8a                	ld	s5,160(sp)
    800060ec:	7b2a                	ld	s6,168(sp)
    800060ee:	7bca                	ld	s7,176(sp)
    800060f0:	7c6a                	ld	s8,184(sp)
    800060f2:	6c8e                	ld	s9,192(sp)
    800060f4:	6d2e                	ld	s10,200(sp)
    800060f6:	6dce                	ld	s11,208(sp)
    800060f8:	6e6e                	ld	t3,216(sp)
    800060fa:	7e8e                	ld	t4,224(sp)
    800060fc:	7f2e                	ld	t5,232(sp)
    800060fe:	7fce                	ld	t6,240(sp)
    80006100:	6111                	addi	sp,sp,256
    80006102:	10200073          	sret
    80006106:	00000013          	nop
    8000610a:	00000013          	nop
    8000610e:	0001                	nop

0000000080006110 <timervec>:
    80006110:	34051573          	csrrw	a0,mscratch,a0
    80006114:	e10c                	sd	a1,0(a0)
    80006116:	e510                	sd	a2,8(a0)
    80006118:	e914                	sd	a3,16(a0)
    8000611a:	6d0c                	ld	a1,24(a0)
    8000611c:	7110                	ld	a2,32(a0)
    8000611e:	6194                	ld	a3,0(a1)
    80006120:	96b2                	add	a3,a3,a2
    80006122:	e194                	sd	a3,0(a1)
    80006124:	4589                	li	a1,2
    80006126:	14459073          	csrw	sip,a1
    8000612a:	6914                	ld	a3,16(a0)
    8000612c:	6510                	ld	a2,8(a0)
    8000612e:	610c                	ld	a1,0(a0)
    80006130:	34051573          	csrrw	a0,mscratch,a0
    80006134:	30200073          	mret
	...

000000008000613a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000613a:	1141                	addi	sp,sp,-16
    8000613c:	e422                	sd	s0,8(sp)
    8000613e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006140:	0c0007b7          	lui	a5,0xc000
    80006144:	4705                	li	a4,1
    80006146:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006148:	c3d8                	sw	a4,4(a5)
}
    8000614a:	6422                	ld	s0,8(sp)
    8000614c:	0141                	addi	sp,sp,16
    8000614e:	8082                	ret

0000000080006150 <plicinithart>:

void
plicinithart(void)
{
    80006150:	1141                	addi	sp,sp,-16
    80006152:	e406                	sd	ra,8(sp)
    80006154:	e022                	sd	s0,0(sp)
    80006156:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006158:	ffffc097          	auipc	ra,0xffffc
    8000615c:	84a080e7          	jalr	-1974(ra) # 800019a2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006160:	0085171b          	slliw	a4,a0,0x8
    80006164:	0c0027b7          	lui	a5,0xc002
    80006168:	97ba                	add	a5,a5,a4
    8000616a:	40200713          	li	a4,1026
    8000616e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006172:	00d5151b          	slliw	a0,a0,0xd
    80006176:	0c2017b7          	lui	a5,0xc201
    8000617a:	97aa                	add	a5,a5,a0
    8000617c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006180:	60a2                	ld	ra,8(sp)
    80006182:	6402                	ld	s0,0(sp)
    80006184:	0141                	addi	sp,sp,16
    80006186:	8082                	ret

0000000080006188 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006188:	1141                	addi	sp,sp,-16
    8000618a:	e406                	sd	ra,8(sp)
    8000618c:	e022                	sd	s0,0(sp)
    8000618e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006190:	ffffc097          	auipc	ra,0xffffc
    80006194:	812080e7          	jalr	-2030(ra) # 800019a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006198:	00d5151b          	slliw	a0,a0,0xd
    8000619c:	0c2017b7          	lui	a5,0xc201
    800061a0:	97aa                	add	a5,a5,a0
  return irq;
}
    800061a2:	43c8                	lw	a0,4(a5)
    800061a4:	60a2                	ld	ra,8(sp)
    800061a6:	6402                	ld	s0,0(sp)
    800061a8:	0141                	addi	sp,sp,16
    800061aa:	8082                	ret

00000000800061ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061ac:	1101                	addi	sp,sp,-32
    800061ae:	ec06                	sd	ra,24(sp)
    800061b0:	e822                	sd	s0,16(sp)
    800061b2:	e426                	sd	s1,8(sp)
    800061b4:	1000                	addi	s0,sp,32
    800061b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061b8:	ffffb097          	auipc	ra,0xffffb
    800061bc:	7ea080e7          	jalr	2026(ra) # 800019a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061c0:	00d5151b          	slliw	a0,a0,0xd
    800061c4:	0c2017b7          	lui	a5,0xc201
    800061c8:	97aa                	add	a5,a5,a0
    800061ca:	c3c4                	sw	s1,4(a5)
}
    800061cc:	60e2                	ld	ra,24(sp)
    800061ce:	6442                	ld	s0,16(sp)
    800061d0:	64a2                	ld	s1,8(sp)
    800061d2:	6105                	addi	sp,sp,32
    800061d4:	8082                	ret

00000000800061d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061d6:	1141                	addi	sp,sp,-16
    800061d8:	e406                	sd	ra,8(sp)
    800061da:	e022                	sd	s0,0(sp)
    800061dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061de:	479d                	li	a5,7
    800061e0:	04a7cc63          	blt	a5,a0,80006238 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800061e4:	0001d797          	auipc	a5,0x1d
    800061e8:	30c78793          	addi	a5,a5,780 # 800234f0 <disk>
    800061ec:	97aa                	add	a5,a5,a0
    800061ee:	0187c783          	lbu	a5,24(a5)
    800061f2:	ebb9                	bnez	a5,80006248 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061f4:	00451693          	slli	a3,a0,0x4
    800061f8:	0001d797          	auipc	a5,0x1d
    800061fc:	2f878793          	addi	a5,a5,760 # 800234f0 <disk>
    80006200:	6398                	ld	a4,0(a5)
    80006202:	9736                	add	a4,a4,a3
    80006204:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006208:	6398                	ld	a4,0(a5)
    8000620a:	9736                	add	a4,a4,a3
    8000620c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006210:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006214:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006218:	97aa                	add	a5,a5,a0
    8000621a:	4705                	li	a4,1
    8000621c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006220:	0001d517          	auipc	a0,0x1d
    80006224:	2e850513          	addi	a0,a0,744 # 80023508 <disk+0x18>
    80006228:	ffffc097          	auipc	ra,0xffffc
    8000622c:	0d0080e7          	jalr	208(ra) # 800022f8 <wakeup>
}
    80006230:	60a2                	ld	ra,8(sp)
    80006232:	6402                	ld	s0,0(sp)
    80006234:	0141                	addi	sp,sp,16
    80006236:	8082                	ret
    panic("free_desc 1");
    80006238:	00002517          	auipc	a0,0x2
    8000623c:	57050513          	addi	a0,a0,1392 # 800087a8 <syscalls+0x310>
    80006240:	ffffa097          	auipc	ra,0xffffa
    80006244:	2fc080e7          	jalr	764(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006248:	00002517          	auipc	a0,0x2
    8000624c:	57050513          	addi	a0,a0,1392 # 800087b8 <syscalls+0x320>
    80006250:	ffffa097          	auipc	ra,0xffffa
    80006254:	2ec080e7          	jalr	748(ra) # 8000053c <panic>

0000000080006258 <virtio_disk_init>:
{
    80006258:	1101                	addi	sp,sp,-32
    8000625a:	ec06                	sd	ra,24(sp)
    8000625c:	e822                	sd	s0,16(sp)
    8000625e:	e426                	sd	s1,8(sp)
    80006260:	e04a                	sd	s2,0(sp)
    80006262:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006264:	00002597          	auipc	a1,0x2
    80006268:	56458593          	addi	a1,a1,1380 # 800087c8 <syscalls+0x330>
    8000626c:	0001d517          	auipc	a0,0x1d
    80006270:	3ac50513          	addi	a0,a0,940 # 80023618 <disk+0x128>
    80006274:	ffffb097          	auipc	ra,0xffffb
    80006278:	8ce080e7          	jalr	-1842(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000627c:	100017b7          	lui	a5,0x10001
    80006280:	4398                	lw	a4,0(a5)
    80006282:	2701                	sext.w	a4,a4
    80006284:	747277b7          	lui	a5,0x74727
    80006288:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000628c:	14f71b63          	bne	a4,a5,800063e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006290:	100017b7          	lui	a5,0x10001
    80006294:	43dc                	lw	a5,4(a5)
    80006296:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006298:	4709                	li	a4,2
    8000629a:	14e79463          	bne	a5,a4,800063e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000629e:	100017b7          	lui	a5,0x10001
    800062a2:	479c                	lw	a5,8(a5)
    800062a4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062a6:	12e79e63          	bne	a5,a4,800063e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062aa:	100017b7          	lui	a5,0x10001
    800062ae:	47d8                	lw	a4,12(a5)
    800062b0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062b2:	554d47b7          	lui	a5,0x554d4
    800062b6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062ba:	12f71463          	bne	a4,a5,800063e2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062be:	100017b7          	lui	a5,0x10001
    800062c2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062c6:	4705                	li	a4,1
    800062c8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062ca:	470d                	li	a4,3
    800062cc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062ce:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062d0:	c7ffe6b7          	lui	a3,0xc7ffe
    800062d4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb12f>
    800062d8:	8f75                	and	a4,a4,a3
    800062da:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062dc:	472d                	li	a4,11
    800062de:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800062e0:	5bbc                	lw	a5,112(a5)
    800062e2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800062e6:	8ba1                	andi	a5,a5,8
    800062e8:	10078563          	beqz	a5,800063f2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062ec:	100017b7          	lui	a5,0x10001
    800062f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800062f4:	43fc                	lw	a5,68(a5)
    800062f6:	2781                	sext.w	a5,a5
    800062f8:	10079563          	bnez	a5,80006402 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062fc:	100017b7          	lui	a5,0x10001
    80006300:	5bdc                	lw	a5,52(a5)
    80006302:	2781                	sext.w	a5,a5
  if(max == 0)
    80006304:	10078763          	beqz	a5,80006412 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006308:	471d                	li	a4,7
    8000630a:	10f77c63          	bgeu	a4,a5,80006422 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000630e:	ffffa097          	auipc	ra,0xffffa
    80006312:	7d4080e7          	jalr	2004(ra) # 80000ae2 <kalloc>
    80006316:	0001d497          	auipc	s1,0x1d
    8000631a:	1da48493          	addi	s1,s1,474 # 800234f0 <disk>
    8000631e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006320:	ffffa097          	auipc	ra,0xffffa
    80006324:	7c2080e7          	jalr	1986(ra) # 80000ae2 <kalloc>
    80006328:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	7b8080e7          	jalr	1976(ra) # 80000ae2 <kalloc>
    80006332:	87aa                	mv	a5,a0
    80006334:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006336:	6088                	ld	a0,0(s1)
    80006338:	cd6d                	beqz	a0,80006432 <virtio_disk_init+0x1da>
    8000633a:	0001d717          	auipc	a4,0x1d
    8000633e:	1be73703          	ld	a4,446(a4) # 800234f8 <disk+0x8>
    80006342:	cb65                	beqz	a4,80006432 <virtio_disk_init+0x1da>
    80006344:	c7fd                	beqz	a5,80006432 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006346:	6605                	lui	a2,0x1
    80006348:	4581                	li	a1,0
    8000634a:	ffffb097          	auipc	ra,0xffffb
    8000634e:	984080e7          	jalr	-1660(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006352:	0001d497          	auipc	s1,0x1d
    80006356:	19e48493          	addi	s1,s1,414 # 800234f0 <disk>
    8000635a:	6605                	lui	a2,0x1
    8000635c:	4581                	li	a1,0
    8000635e:	6488                	ld	a0,8(s1)
    80006360:	ffffb097          	auipc	ra,0xffffb
    80006364:	96e080e7          	jalr	-1682(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006368:	6605                	lui	a2,0x1
    8000636a:	4581                	li	a1,0
    8000636c:	6888                	ld	a0,16(s1)
    8000636e:	ffffb097          	auipc	ra,0xffffb
    80006372:	960080e7          	jalr	-1696(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006376:	100017b7          	lui	a5,0x10001
    8000637a:	4721                	li	a4,8
    8000637c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000637e:	4098                	lw	a4,0(s1)
    80006380:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006384:	40d8                	lw	a4,4(s1)
    80006386:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000638a:	6498                	ld	a4,8(s1)
    8000638c:	0007069b          	sext.w	a3,a4
    80006390:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006394:	9701                	srai	a4,a4,0x20
    80006396:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000639a:	6898                	ld	a4,16(s1)
    8000639c:	0007069b          	sext.w	a3,a4
    800063a0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800063a4:	9701                	srai	a4,a4,0x20
    800063a6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800063aa:	4705                	li	a4,1
    800063ac:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800063ae:	00e48c23          	sb	a4,24(s1)
    800063b2:	00e48ca3          	sb	a4,25(s1)
    800063b6:	00e48d23          	sb	a4,26(s1)
    800063ba:	00e48da3          	sb	a4,27(s1)
    800063be:	00e48e23          	sb	a4,28(s1)
    800063c2:	00e48ea3          	sb	a4,29(s1)
    800063c6:	00e48f23          	sb	a4,30(s1)
    800063ca:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800063ce:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800063d2:	0727a823          	sw	s2,112(a5)
}
    800063d6:	60e2                	ld	ra,24(sp)
    800063d8:	6442                	ld	s0,16(sp)
    800063da:	64a2                	ld	s1,8(sp)
    800063dc:	6902                	ld	s2,0(sp)
    800063de:	6105                	addi	sp,sp,32
    800063e0:	8082                	ret
    panic("could not find virtio disk");
    800063e2:	00002517          	auipc	a0,0x2
    800063e6:	3f650513          	addi	a0,a0,1014 # 800087d8 <syscalls+0x340>
    800063ea:	ffffa097          	auipc	ra,0xffffa
    800063ee:	152080e7          	jalr	338(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800063f2:	00002517          	auipc	a0,0x2
    800063f6:	40650513          	addi	a0,a0,1030 # 800087f8 <syscalls+0x360>
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	142080e7          	jalr	322(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006402:	00002517          	auipc	a0,0x2
    80006406:	41650513          	addi	a0,a0,1046 # 80008818 <syscalls+0x380>
    8000640a:	ffffa097          	auipc	ra,0xffffa
    8000640e:	132080e7          	jalr	306(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006412:	00002517          	auipc	a0,0x2
    80006416:	42650513          	addi	a0,a0,1062 # 80008838 <syscalls+0x3a0>
    8000641a:	ffffa097          	auipc	ra,0xffffa
    8000641e:	122080e7          	jalr	290(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006422:	00002517          	auipc	a0,0x2
    80006426:	43650513          	addi	a0,a0,1078 # 80008858 <syscalls+0x3c0>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	112080e7          	jalr	274(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006432:	00002517          	auipc	a0,0x2
    80006436:	44650513          	addi	a0,a0,1094 # 80008878 <syscalls+0x3e0>
    8000643a:	ffffa097          	auipc	ra,0xffffa
    8000643e:	102080e7          	jalr	258(ra) # 8000053c <panic>

0000000080006442 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006442:	7159                	addi	sp,sp,-112
    80006444:	f486                	sd	ra,104(sp)
    80006446:	f0a2                	sd	s0,96(sp)
    80006448:	eca6                	sd	s1,88(sp)
    8000644a:	e8ca                	sd	s2,80(sp)
    8000644c:	e4ce                	sd	s3,72(sp)
    8000644e:	e0d2                	sd	s4,64(sp)
    80006450:	fc56                	sd	s5,56(sp)
    80006452:	f85a                	sd	s6,48(sp)
    80006454:	f45e                	sd	s7,40(sp)
    80006456:	f062                	sd	s8,32(sp)
    80006458:	ec66                	sd	s9,24(sp)
    8000645a:	e86a                	sd	s10,16(sp)
    8000645c:	1880                	addi	s0,sp,112
    8000645e:	8a2a                	mv	s4,a0
    80006460:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006462:	00c52c83          	lw	s9,12(a0)
    80006466:	001c9c9b          	slliw	s9,s9,0x1
    8000646a:	1c82                	slli	s9,s9,0x20
    8000646c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006470:	0001d517          	auipc	a0,0x1d
    80006474:	1a850513          	addi	a0,a0,424 # 80023618 <disk+0x128>
    80006478:	ffffa097          	auipc	ra,0xffffa
    8000647c:	75a080e7          	jalr	1882(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006480:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006482:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006484:	0001db17          	auipc	s6,0x1d
    80006488:	06cb0b13          	addi	s6,s6,108 # 800234f0 <disk>
  for(int i = 0; i < 3; i++){
    8000648c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000648e:	0001dc17          	auipc	s8,0x1d
    80006492:	18ac0c13          	addi	s8,s8,394 # 80023618 <disk+0x128>
    80006496:	a095                	j	800064fa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006498:	00fb0733          	add	a4,s6,a5
    8000649c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800064a0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800064a2:	0207c563          	bltz	a5,800064cc <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800064a6:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800064a8:	0591                	addi	a1,a1,4
    800064aa:	05560d63          	beq	a2,s5,80006504 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800064ae:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    800064b0:	0001d717          	auipc	a4,0x1d
    800064b4:	04070713          	addi	a4,a4,64 # 800234f0 <disk>
    800064b8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    800064ba:	01874683          	lbu	a3,24(a4)
    800064be:	fee9                	bnez	a3,80006498 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800064c0:	2785                	addiw	a5,a5,1
    800064c2:	0705                	addi	a4,a4,1
    800064c4:	fe979be3          	bne	a5,s1,800064ba <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800064c8:	57fd                	li	a5,-1
    800064ca:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800064cc:	00c05e63          	blez	a2,800064e8 <virtio_disk_rw+0xa6>
    800064d0:	060a                	slli	a2,a2,0x2
    800064d2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800064d6:	0009a503          	lw	a0,0(s3)
    800064da:	00000097          	auipc	ra,0x0
    800064de:	cfc080e7          	jalr	-772(ra) # 800061d6 <free_desc>
      for(int j = 0; j < i; j++)
    800064e2:	0991                	addi	s3,s3,4
    800064e4:	ffa999e3          	bne	s3,s10,800064d6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064e8:	85e2                	mv	a1,s8
    800064ea:	0001d517          	auipc	a0,0x1d
    800064ee:	01e50513          	addi	a0,a0,30 # 80023508 <disk+0x18>
    800064f2:	ffffc097          	auipc	ra,0xffffc
    800064f6:	da2080e7          	jalr	-606(ra) # 80002294 <sleep>
  for(int i = 0; i < 3; i++){
    800064fa:	f9040993          	addi	s3,s0,-112
{
    800064fe:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006500:	864a                	mv	a2,s2
    80006502:	b775                	j	800064ae <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006504:	f9042503          	lw	a0,-112(s0)
    80006508:	00a50713          	addi	a4,a0,10
    8000650c:	0712                	slli	a4,a4,0x4

  if(write)
    8000650e:	0001d797          	auipc	a5,0x1d
    80006512:	fe278793          	addi	a5,a5,-30 # 800234f0 <disk>
    80006516:	00e786b3          	add	a3,a5,a4
    8000651a:	01703633          	snez	a2,s7
    8000651e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006520:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006524:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006528:	f6070613          	addi	a2,a4,-160
    8000652c:	6394                	ld	a3,0(a5)
    8000652e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006530:	00870593          	addi	a1,a4,8
    80006534:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006536:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006538:	0007b803          	ld	a6,0(a5)
    8000653c:	9642                	add	a2,a2,a6
    8000653e:	46c1                	li	a3,16
    80006540:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006542:	4585                	li	a1,1
    80006544:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006548:	f9442683          	lw	a3,-108(s0)
    8000654c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006550:	0692                	slli	a3,a3,0x4
    80006552:	9836                	add	a6,a6,a3
    80006554:	058a0613          	addi	a2,s4,88
    80006558:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000655c:	0007b803          	ld	a6,0(a5)
    80006560:	96c2                	add	a3,a3,a6
    80006562:	40000613          	li	a2,1024
    80006566:	c690                	sw	a2,8(a3)
  if(write)
    80006568:	001bb613          	seqz	a2,s7
    8000656c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006570:	00166613          	ori	a2,a2,1
    80006574:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006578:	f9842603          	lw	a2,-104(s0)
    8000657c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006580:	00250693          	addi	a3,a0,2
    80006584:	0692                	slli	a3,a3,0x4
    80006586:	96be                	add	a3,a3,a5
    80006588:	58fd                	li	a7,-1
    8000658a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000658e:	0612                	slli	a2,a2,0x4
    80006590:	9832                	add	a6,a6,a2
    80006592:	f9070713          	addi	a4,a4,-112
    80006596:	973e                	add	a4,a4,a5
    80006598:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000659c:	6398                	ld	a4,0(a5)
    8000659e:	9732                	add	a4,a4,a2
    800065a0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065a2:	4609                	li	a2,2
    800065a4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800065a8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065ac:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800065b0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065b4:	6794                	ld	a3,8(a5)
    800065b6:	0026d703          	lhu	a4,2(a3)
    800065ba:	8b1d                	andi	a4,a4,7
    800065bc:	0706                	slli	a4,a4,0x1
    800065be:	96ba                	add	a3,a3,a4
    800065c0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800065c4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065c8:	6798                	ld	a4,8(a5)
    800065ca:	00275783          	lhu	a5,2(a4)
    800065ce:	2785                	addiw	a5,a5,1
    800065d0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065d4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065d8:	100017b7          	lui	a5,0x10001
    800065dc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065e0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800065e4:	0001d917          	auipc	s2,0x1d
    800065e8:	03490913          	addi	s2,s2,52 # 80023618 <disk+0x128>
  while(b->disk == 1) {
    800065ec:	4485                	li	s1,1
    800065ee:	00b79c63          	bne	a5,a1,80006606 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800065f2:	85ca                	mv	a1,s2
    800065f4:	8552                	mv	a0,s4
    800065f6:	ffffc097          	auipc	ra,0xffffc
    800065fa:	c9e080e7          	jalr	-866(ra) # 80002294 <sleep>
  while(b->disk == 1) {
    800065fe:	004a2783          	lw	a5,4(s4)
    80006602:	fe9788e3          	beq	a5,s1,800065f2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006606:	f9042903          	lw	s2,-112(s0)
    8000660a:	00290713          	addi	a4,s2,2
    8000660e:	0712                	slli	a4,a4,0x4
    80006610:	0001d797          	auipc	a5,0x1d
    80006614:	ee078793          	addi	a5,a5,-288 # 800234f0 <disk>
    80006618:	97ba                	add	a5,a5,a4
    8000661a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000661e:	0001d997          	auipc	s3,0x1d
    80006622:	ed298993          	addi	s3,s3,-302 # 800234f0 <disk>
    80006626:	00491713          	slli	a4,s2,0x4
    8000662a:	0009b783          	ld	a5,0(s3)
    8000662e:	97ba                	add	a5,a5,a4
    80006630:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006634:	854a                	mv	a0,s2
    80006636:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000663a:	00000097          	auipc	ra,0x0
    8000663e:	b9c080e7          	jalr	-1124(ra) # 800061d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006642:	8885                	andi	s1,s1,1
    80006644:	f0ed                	bnez	s1,80006626 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006646:	0001d517          	auipc	a0,0x1d
    8000664a:	fd250513          	addi	a0,a0,-46 # 80023618 <disk+0x128>
    8000664e:	ffffa097          	auipc	ra,0xffffa
    80006652:	638080e7          	jalr	1592(ra) # 80000c86 <release>
}
    80006656:	70a6                	ld	ra,104(sp)
    80006658:	7406                	ld	s0,96(sp)
    8000665a:	64e6                	ld	s1,88(sp)
    8000665c:	6946                	ld	s2,80(sp)
    8000665e:	69a6                	ld	s3,72(sp)
    80006660:	6a06                	ld	s4,64(sp)
    80006662:	7ae2                	ld	s5,56(sp)
    80006664:	7b42                	ld	s6,48(sp)
    80006666:	7ba2                	ld	s7,40(sp)
    80006668:	7c02                	ld	s8,32(sp)
    8000666a:	6ce2                	ld	s9,24(sp)
    8000666c:	6d42                	ld	s10,16(sp)
    8000666e:	6165                	addi	sp,sp,112
    80006670:	8082                	ret

0000000080006672 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006672:	1101                	addi	sp,sp,-32
    80006674:	ec06                	sd	ra,24(sp)
    80006676:	e822                	sd	s0,16(sp)
    80006678:	e426                	sd	s1,8(sp)
    8000667a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000667c:	0001d497          	auipc	s1,0x1d
    80006680:	e7448493          	addi	s1,s1,-396 # 800234f0 <disk>
    80006684:	0001d517          	auipc	a0,0x1d
    80006688:	f9450513          	addi	a0,a0,-108 # 80023618 <disk+0x128>
    8000668c:	ffffa097          	auipc	ra,0xffffa
    80006690:	546080e7          	jalr	1350(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006694:	10001737          	lui	a4,0x10001
    80006698:	533c                	lw	a5,96(a4)
    8000669a:	8b8d                	andi	a5,a5,3
    8000669c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000669e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066a2:	689c                	ld	a5,16(s1)
    800066a4:	0204d703          	lhu	a4,32(s1)
    800066a8:	0027d783          	lhu	a5,2(a5)
    800066ac:	04f70863          	beq	a4,a5,800066fc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800066b0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066b4:	6898                	ld	a4,16(s1)
    800066b6:	0204d783          	lhu	a5,32(s1)
    800066ba:	8b9d                	andi	a5,a5,7
    800066bc:	078e                	slli	a5,a5,0x3
    800066be:	97ba                	add	a5,a5,a4
    800066c0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066c2:	00278713          	addi	a4,a5,2
    800066c6:	0712                	slli	a4,a4,0x4
    800066c8:	9726                	add	a4,a4,s1
    800066ca:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800066ce:	e721                	bnez	a4,80006716 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066d0:	0789                	addi	a5,a5,2
    800066d2:	0792                	slli	a5,a5,0x4
    800066d4:	97a6                	add	a5,a5,s1
    800066d6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800066d8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066dc:	ffffc097          	auipc	ra,0xffffc
    800066e0:	c1c080e7          	jalr	-996(ra) # 800022f8 <wakeup>

    disk.used_idx += 1;
    800066e4:	0204d783          	lhu	a5,32(s1)
    800066e8:	2785                	addiw	a5,a5,1
    800066ea:	17c2                	slli	a5,a5,0x30
    800066ec:	93c1                	srli	a5,a5,0x30
    800066ee:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066f2:	6898                	ld	a4,16(s1)
    800066f4:	00275703          	lhu	a4,2(a4)
    800066f8:	faf71ce3          	bne	a4,a5,800066b0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800066fc:	0001d517          	auipc	a0,0x1d
    80006700:	f1c50513          	addi	a0,a0,-228 # 80023618 <disk+0x128>
    80006704:	ffffa097          	auipc	ra,0xffffa
    80006708:	582080e7          	jalr	1410(ra) # 80000c86 <release>
}
    8000670c:	60e2                	ld	ra,24(sp)
    8000670e:	6442                	ld	s0,16(sp)
    80006710:	64a2                	ld	s1,8(sp)
    80006712:	6105                	addi	sp,sp,32
    80006714:	8082                	ret
      panic("virtio_disk_intr status");
    80006716:	00002517          	auipc	a0,0x2
    8000671a:	17a50513          	addi	a0,a0,378 # 80008890 <syscalls+0x3f8>
    8000671e:	ffffa097          	auipc	ra,0xffffa
    80006722:	e1e080e7          	jalr	-482(ra) # 8000053c <panic>
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
