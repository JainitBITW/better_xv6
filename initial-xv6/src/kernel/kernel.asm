
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	8d070713          	addi	a4,a4,-1840 # 80008920 <timer_scratch>
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
    80000066:	30e78793          	addi	a5,a5,782 # 80006370 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda7cf>
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
    8000012e:	6c0080e7          	jalr	1728(ra) # 800027ea <either_copyin>
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
    80000188:	8dc50513          	addi	a0,a0,-1828 # 80010a60 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8cc48493          	addi	s1,s1,-1844 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	95c90913          	addi	s2,s2,-1700 # 80010af8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	822080e7          	jalr	-2014(ra) # 800019d6 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	478080e7          	jalr	1144(ra) # 80002634 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	19a080e7          	jalr	410(ra) # 80002364 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	88270713          	addi	a4,a4,-1918 # 80010a60 <cons>
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
    80000214:	584080e7          	jalr	1412(ra) # 80002794 <either_copyout>
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
    8000022c:	83850513          	addi	a0,a0,-1992 # 80010a60 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	82250513          	addi	a0,a0,-2014 # 80010a60 <cons>
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
    80000272:	88f72523          	sw	a5,-1910(a4) # 80010af8 <cons+0x98>
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
    800002cc:	79850513          	addi	a0,a0,1944 # 80010a60 <cons>
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
    800002f2:	552080e7          	jalr	1362(ra) # 80002840 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	76a50513          	addi	a0,a0,1898 # 80010a60 <cons>
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
    8000031e:	74670713          	addi	a4,a4,1862 # 80010a60 <cons>
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
    80000348:	71c78793          	addi	a5,a5,1820 # 80010a60 <cons>
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
    80000376:	7867a783          	lw	a5,1926(a5) # 80010af8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6da70713          	addi	a4,a4,1754 # 80010a60 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6ca48493          	addi	s1,s1,1738 # 80010a60 <cons>
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
    800003d6:	68e70713          	addi	a4,a4,1678 # 80010a60 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	70f72c23          	sw	a5,1816(a4) # 80010b00 <cons+0xa0>
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
    80000412:	65278793          	addi	a5,a5,1618 # 80010a60 <cons>
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
    80000436:	6cc7a523          	sw	a2,1738(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	6be50513          	addi	a0,a0,1726 # 80010af8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	f86080e7          	jalr	-122(ra) # 800023c8 <wakeup>
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
    80000460:	60450513          	addi	a0,a0,1540 # 80010a60 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00023797          	auipc	a5,0x23
    80000478:	a2478793          	addi	a5,a5,-1500 # 80022e98 <devsw>
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
    8000054c:	5c07ac23          	sw	zero,1496(a5) # 80010b20 <pr+0x18>
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
    80000580:	36f72223          	sw	a5,868(a4) # 800088e0 <panicked>
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
    800005bc:	568dad83          	lw	s11,1384(s11) # 80010b20 <pr+0x18>
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
    800005fa:	51250513          	addi	a0,a0,1298 # 80010b08 <pr>
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
    80000758:	3b450513          	addi	a0,a0,948 # 80010b08 <pr>
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
    80000774:	39848493          	addi	s1,s1,920 # 80010b08 <pr>
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
    800007d4:	35850513          	addi	a0,a0,856 # 80010b28 <uart_tx_lock>
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
    80000800:	0e47a783          	lw	a5,228(a5) # 800088e0 <panicked>
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
    80000838:	0b47b783          	ld	a5,180(a5) # 800088e8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0b473703          	ld	a4,180(a4) # 800088f0 <uart_tx_w>
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
    80000862:	2caa0a13          	addi	s4,s4,714 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	08248493          	addi	s1,s1,130 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	08298993          	addi	s3,s3,130 # 800088f0 <uart_tx_w>
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
    80000894:	b38080e7          	jalr	-1224(ra) # 800023c8 <wakeup>
    
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
    800008d0:	25c50513          	addi	a0,a0,604 # 80010b28 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0047a783          	lw	a5,4(a5) # 800088e0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	00a73703          	ld	a4,10(a4) # 800088f0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	ffa7b783          	ld	a5,-6(a5) # 800088e8 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	22e98993          	addi	s3,s3,558 # 80010b28 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fe648493          	addi	s1,s1,-26 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fe690913          	addi	s2,s2,-26 # 800088f0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	a4a080e7          	jalr	-1462(ra) # 80002364 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1f848493          	addi	s1,s1,504 # 80010b28 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	fae7b623          	sd	a4,-84(a5) # 800088f0 <uart_tx_w>
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
    800009ba:	17248493          	addi	s1,s1,370 # 80010b28 <uart_tx_lock>
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
    800009fc:	63878793          	addi	a5,a5,1592 # 80024030 <end>
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
    80000a1c:	14890913          	addi	s2,s2,328 # 80010b60 <kmem>
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
    80000aba:	0aa50513          	addi	a0,a0,170 # 80010b60 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00023517          	auipc	a0,0x23
    80000ace:	56650513          	addi	a0,a0,1382 # 80024030 <end>
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
    80000af0:	07448493          	addi	s1,s1,116 # 80010b60 <kmem>
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
    80000b08:	05c50513          	addi	a0,a0,92 # 80010b60 <kmem>
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
    80000b34:	03050513          	addi	a0,a0,48 # 80010b60 <kmem>
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
    80000b70:	e4e080e7          	jalr	-434(ra) # 800019ba <mycpu>
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
    80000ba2:	e1c080e7          	jalr	-484(ra) # 800019ba <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	e10080e7          	jalr	-496(ra) # 800019ba <mycpu>
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
    80000bc6:	df8080e7          	jalr	-520(ra) # 800019ba <mycpu>
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
    80000c06:	db8080e7          	jalr	-584(ra) # 800019ba <mycpu>
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
    80000c32:	d8c080e7          	jalr	-628(ra) # 800019ba <mycpu>
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
    80000d42:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdafd1>
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
    80000e7e:	b30080e7          	jalr	-1232(ra) # 800019aa <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	a7670713          	addi	a4,a4,-1418 # 800088f8 <started>
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
    80000e9a:	b14080e7          	jalr	-1260(ra) # 800019aa <cpuid>
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
    80000ebc:	d72080e7          	jalr	-654(ra) # 80002c2a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	4f0080e7          	jalr	1264(ra) # 800063b0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	06a080e7          	jalr	106(ra) # 80001f32 <scheduler>
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
    80000f34:	cd2080e7          	jalr	-814(ra) # 80002c02 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	cf2080e7          	jalr	-782(ra) # 80002c2a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	45a080e7          	jalr	1114(ra) # 8000639a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	468080e7          	jalr	1128(ra) # 800063b0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	64e080e7          	jalr	1614(ra) # 8000359e <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	cec080e7          	jalr	-788(ra) # 80003c44 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	c62080e7          	jalr	-926(ra) # 80004bc2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	550080e7          	jalr	1360(ra) # 800064b8 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	ed8080e7          	jalr	-296(ra) # 80001e48 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	96f72d23          	sw	a5,-1670(a4) # 800088f8 <started>
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
    80000f96:	96e7b783          	ld	a5,-1682(a5) # 80008900 <kernel_pagetable>
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
    80001010:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdafc7>
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
    80001252:	6aa7b923          	sd	a0,1714(a5) # 80008900 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdafd0>
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
    8000184a:	40a48493          	addi	s1,s1,1034 # 80011c50 <proc>
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
    80001864:	3f0a0a13          	addi	s4,s4,1008 # 80018c50 <tickslock>
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
	int i ; 
	for(i=0;i<NUM_OF_QUEUES;i++)
	{
		//check if queue exists 
		
		queues[i].queue_size = 0 ; 
    800018da:	0000f797          	auipc	a5,0xf
    800018de:	6d678793          	addi	a5,a5,1750 # 80010fb0 <queues>
    800018e2:	3207a023          	sw	zero,800(a5)
		queues[i].arr[0] = 0 ;
    800018e6:	0007b023          	sd	zero,0(a5)
		queues[i].queue_size = 0 ; 
    800018ea:	6407a423          	sw	zero,1608(a5)
		queues[i].arr[0] = 0 ;
    800018ee:	3207b423          	sd	zero,808(a5)
		queues[i].queue_size = 0 ; 
    800018f2:	00010717          	auipc	a4,0x10
    800018f6:	6be70713          	addi	a4,a4,1726 # 80011fb0 <proc+0x360>
    800018fa:	96072823          	sw	zero,-1680(a4)
		queues[i].arr[0] = 0 ;
    800018fe:	6407b823          	sd	zero,1616(a5)
		queues[i].queue_size = 0 ; 
    80001902:	c8072c23          	sw	zero,-872(a4)
		queues[i].arr[0] = 0 ;
    80001906:	96073c23          	sd	zero,-1672(a4)
	}
	#endif
	initlock(&pid_lock, "nextpid");
    8000190a:	00007597          	auipc	a1,0x7
    8000190e:	8d658593          	addi	a1,a1,-1834 # 800081e0 <digits+0x1a0>
    80001912:	0000f517          	auipc	a0,0xf
    80001916:	26e50513          	addi	a0,a0,622 # 80010b80 <pid_lock>
    8000191a:	fffff097          	auipc	ra,0xfffff
    8000191e:	228080e7          	jalr	552(ra) # 80000b42 <initlock>
	initlock(&wait_lock, "wait_lock");
    80001922:	00007597          	auipc	a1,0x7
    80001926:	8c658593          	addi	a1,a1,-1850 # 800081e8 <digits+0x1a8>
    8000192a:	0000f517          	auipc	a0,0xf
    8000192e:	26e50513          	addi	a0,a0,622 # 80010b98 <wait_lock>
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	210080e7          	jalr	528(ra) # 80000b42 <initlock>
	for(p = proc; p < &proc[NPROC]; p++)
    8000193a:	00010497          	auipc	s1,0x10
    8000193e:	31648493          	addi	s1,s1,790 # 80011c50 <proc>
	{
		initlock(&p->lock, "proc");
    80001942:	00007b17          	auipc	s6,0x7
    80001946:	8b6b0b13          	addi	s6,s6,-1866 # 800081f8 <digits+0x1b8>
		p->state = UNUSED;
		p->kstack = KSTACK((int)(p - proc));
    8000194a:	8aa6                	mv	s5,s1
    8000194c:	00006a17          	auipc	s4,0x6
    80001950:	6b4a0a13          	addi	s4,s4,1716 # 80008000 <etext>
    80001954:	04000937          	lui	s2,0x4000
    80001958:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000195a:	0932                	slli	s2,s2,0xc
	for(p = proc; p < &proc[NPROC]; p++)
    8000195c:	00017997          	auipc	s3,0x17
    80001960:	2f498993          	addi	s3,s3,756 # 80018c50 <tickslock>
		initlock(&p->lock, "proc");
    80001964:	85da                	mv	a1,s6
    80001966:	8526                	mv	a0,s1
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	1da080e7          	jalr	474(ra) # 80000b42 <initlock>
		p->state = UNUSED;
    80001970:	0004ac23          	sw	zero,24(s1)
		p->kstack = KSTACK((int)(p - proc));
    80001974:	415487b3          	sub	a5,s1,s5
    80001978:	8799                	srai	a5,a5,0x6
    8000197a:	000a3703          	ld	a4,0(s4)
    8000197e:	02e787b3          	mul	a5,a5,a4
    80001982:	2785                	addiw	a5,a5,1
    80001984:	00d7979b          	slliw	a5,a5,0xd
    80001988:	40f907b3          	sub	a5,s2,a5
    8000198c:	e0bc                	sd	a5,64(s1)
	for(p = proc; p < &proc[NPROC]; p++)
    8000198e:	1c048493          	addi	s1,s1,448
    80001992:	fd3499e3          	bne	s1,s3,80001964 <procinit+0x9e>
	}


}
    80001996:	70e2                	ld	ra,56(sp)
    80001998:	7442                	ld	s0,48(sp)
    8000199a:	74a2                	ld	s1,40(sp)
    8000199c:	7902                	ld	s2,32(sp)
    8000199e:	69e2                	ld	s3,24(sp)
    800019a0:	6a42                	ld	s4,16(sp)
    800019a2:	6aa2                	ld	s5,8(sp)
    800019a4:	6b02                	ld	s6,0(sp)
    800019a6:	6121                	addi	sp,sp,64
    800019a8:	8082                	ret

00000000800019aa <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019b0:	8512                	mv	a0,tp
	int id = r_tp();
	return id;
}
    800019b2:	2501                	sext.w	a0,a0
    800019b4:	6422                	ld	s0,8(sp)
    800019b6:	0141                	addi	sp,sp,16
    800019b8:	8082                	ret

00000000800019ba <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu* mycpu(void)
{
    800019ba:	1141                	addi	sp,sp,-16
    800019bc:	e422                	sd	s0,8(sp)
    800019be:	0800                	addi	s0,sp,16
    800019c0:	8792                	mv	a5,tp
	int id = cpuid();
	struct cpu* c = &cpus[id];
    800019c2:	2781                	sext.w	a5,a5
    800019c4:	079e                	slli	a5,a5,0x7
	return c;
}
    800019c6:	0000f517          	auipc	a0,0xf
    800019ca:	1ea50513          	addi	a0,a0,490 # 80010bb0 <cpus>
    800019ce:	953e                	add	a0,a0,a5
    800019d0:	6422                	ld	s0,8(sp)
    800019d2:	0141                	addi	sp,sp,16
    800019d4:	8082                	ret

00000000800019d6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc* myproc(void)
{
    800019d6:	1101                	addi	sp,sp,-32
    800019d8:	ec06                	sd	ra,24(sp)
    800019da:	e822                	sd	s0,16(sp)
    800019dc:	e426                	sd	s1,8(sp)
    800019de:	1000                	addi	s0,sp,32
	push_off();
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	1a6080e7          	jalr	422(ra) # 80000b86 <push_off>
    800019e8:	8792                	mv	a5,tp
	struct cpu* c = mycpu();
	struct proc* p = c->proc;
    800019ea:	2781                	sext.w	a5,a5
    800019ec:	079e                	slli	a5,a5,0x7
    800019ee:	0000f717          	auipc	a4,0xf
    800019f2:	19270713          	addi	a4,a4,402 # 80010b80 <pid_lock>
    800019f6:	97ba                	add	a5,a5,a4
    800019f8:	7b84                	ld	s1,48(a5)
	pop_off();
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	22c080e7          	jalr	556(ra) # 80000c26 <pop_off>
	return p;
}
    80001a02:	8526                	mv	a0,s1
    80001a04:	60e2                	ld	ra,24(sp)
    80001a06:	6442                	ld	s0,16(sp)
    80001a08:	64a2                	ld	s1,8(sp)
    80001a0a:	6105                	addi	sp,sp,32
    80001a0c:	8082                	ret

0000000080001a0e <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a0e:	1141                	addi	sp,sp,-16
    80001a10:	e406                	sd	ra,8(sp)
    80001a12:	e022                	sd	s0,0(sp)
    80001a14:	0800                	addi	s0,sp,16
	static int first = 1;

	// Still holding p->lock from scheduler.
	release(&myproc()->lock);
    80001a16:	00000097          	auipc	ra,0x0
    80001a1a:	fc0080e7          	jalr	-64(ra) # 800019d6 <myproc>
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	268080e7          	jalr	616(ra) # 80000c86 <release>

	if(first)
    80001a26:	00007797          	auipc	a5,0x7
    80001a2a:	e4a7a783          	lw	a5,-438(a5) # 80008870 <first.1>
    80001a2e:	eb89                	bnez	a5,80001a40 <forkret+0x32>
		// be run from main().
		first = 0;
		fsinit(ROOTDEV);
	}

	usertrapret();
    80001a30:	00001097          	auipc	ra,0x1
    80001a34:	212080e7          	jalr	530(ra) # 80002c42 <usertrapret>
}
    80001a38:	60a2                	ld	ra,8(sp)
    80001a3a:	6402                	ld	s0,0(sp)
    80001a3c:	0141                	addi	sp,sp,16
    80001a3e:	8082                	ret
		first = 0;
    80001a40:	00007797          	auipc	a5,0x7
    80001a44:	e207a823          	sw	zero,-464(a5) # 80008870 <first.1>
		fsinit(ROOTDEV);
    80001a48:	4505                	li	a0,1
    80001a4a:	00002097          	auipc	ra,0x2
    80001a4e:	17a080e7          	jalr	378(ra) # 80003bc4 <fsinit>
    80001a52:	bff9                	j	80001a30 <forkret+0x22>

0000000080001a54 <allocpid>:
{
    80001a54:	1101                	addi	sp,sp,-32
    80001a56:	ec06                	sd	ra,24(sp)
    80001a58:	e822                	sd	s0,16(sp)
    80001a5a:	e426                	sd	s1,8(sp)
    80001a5c:	e04a                	sd	s2,0(sp)
    80001a5e:	1000                	addi	s0,sp,32
	acquire(&pid_lock);
    80001a60:	0000f917          	auipc	s2,0xf
    80001a64:	12090913          	addi	s2,s2,288 # 80010b80 <pid_lock>
    80001a68:	854a                	mv	a0,s2
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	168080e7          	jalr	360(ra) # 80000bd2 <acquire>
	pid = nextpid;
    80001a72:	00007797          	auipc	a5,0x7
    80001a76:	e0278793          	addi	a5,a5,-510 # 80008874 <nextpid>
    80001a7a:	4384                	lw	s1,0(a5)
	nextpid = nextpid + 1;
    80001a7c:	0014871b          	addiw	a4,s1,1
    80001a80:	c398                	sw	a4,0(a5)
	release(&pid_lock);
    80001a82:	854a                	mv	a0,s2
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	202080e7          	jalr	514(ra) # 80000c86 <release>
}
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	60e2                	ld	ra,24(sp)
    80001a90:	6442                	ld	s0,16(sp)
    80001a92:	64a2                	ld	s1,8(sp)
    80001a94:	6902                	ld	s2,0(sp)
    80001a96:	6105                	addi	sp,sp,32
    80001a98:	8082                	ret

0000000080001a9a <queue_remove>:
{
    80001a9a:	1141                	addi	sp,sp,-16
    80001a9c:	e422                	sd	s0,8(sp)
    80001a9e:	0800                	addi	s0,sp,16
	for(i = proc_idx; i < queues[queue_no].queue_size - 1; i++)
    80001aa0:	32800713          	li	a4,808
    80001aa4:	02e58733          	mul	a4,a1,a4
    80001aa8:	0000f797          	auipc	a5,0xf
    80001aac:	50878793          	addi	a5,a5,1288 # 80010fb0 <queues>
    80001ab0:	97ba                	add	a5,a5,a4
    80001ab2:	3207a683          	lw	a3,800(a5)
    80001ab6:	fff6861b          	addiw	a2,a3,-1 # fff <_entry-0x7ffff001>
    80001aba:	0006079b          	sext.w	a5,a2
    80001abe:	02f55463          	bge	a0,a5,80001ae6 <queue_remove+0x4c>
    80001ac2:	06500793          	li	a5,101
    80001ac6:	02f587b3          	mul	a5,a1,a5
    80001aca:	97aa                	add	a5,a5,a0
    80001acc:	078e                	slli	a5,a5,0x3
    80001ace:	0000f717          	auipc	a4,0xf
    80001ad2:	4e270713          	addi	a4,a4,1250 # 80010fb0 <queues>
    80001ad6:	97ba                	add	a5,a5,a4
    80001ad8:	36fd                	addiw	a3,a3,-1
		queues[queue_no].arr[i] = queues[queue_no].arr[i + 1];
    80001ada:	2505                	addiw	a0,a0,1
    80001adc:	6798                	ld	a4,8(a5)
    80001ade:	e398                	sd	a4,0(a5)
	for(i = proc_idx; i < queues[queue_no].queue_size - 1; i++)
    80001ae0:	07a1                	addi	a5,a5,8
    80001ae2:	fed51ce3          	bne	a0,a3,80001ada <queue_remove+0x40>
	queues[queue_no].queue_size--;
    80001ae6:	32800793          	li	a5,808
    80001aea:	02f585b3          	mul	a1,a1,a5
    80001aee:	0000f797          	auipc	a5,0xf
    80001af2:	4c278793          	addi	a5,a5,1218 # 80010fb0 <queues>
    80001af6:	97ae                	add	a5,a5,a1
    80001af8:	32c7a023          	sw	a2,800(a5)
}
    80001afc:	6422                	ld	s0,8(sp)
    80001afe:	0141                	addi	sp,sp,16
    80001b00:	8082                	ret

0000000080001b02 <queue_add>:
{
    80001b02:	1141                	addi	sp,sp,-16
    80001b04:	e422                	sd	s0,8(sp)
    80001b06:	0800                	addi	s0,sp,16
	int new_process_idx = queues[queue_no].queue_size;
    80001b08:	0000f617          	auipc	a2,0xf
    80001b0c:	4a860613          	addi	a2,a2,1192 # 80010fb0 <queues>
    80001b10:	32800713          	li	a4,808
    80001b14:	02e58733          	mul	a4,a1,a4
    80001b18:	9732                	add	a4,a4,a2
    80001b1a:	32072683          	lw	a3,800(a4)
	queues[queue_no].arr[new_process_idx] = p;
    80001b1e:	06500793          	li	a5,101
    80001b22:	02f587b3          	mul	a5,a1,a5
    80001b26:	97b6                	add	a5,a5,a3
    80001b28:	078e                	slli	a5,a5,0x3
    80001b2a:	963e                	add	a2,a2,a5
    80001b2c:	e208                	sd	a0,0(a2)
	queues[queue_no].queue_size++;
    80001b2e:	2685                	addiw	a3,a3,1
    80001b30:	32d72023          	sw	a3,800(a4)
	p->q_run_time = 0;
    80001b34:	1a052a23          	sw	zero,436(a0)
	p->q_wait_time = 0;
    80001b38:	1a052823          	sw	zero,432(a0)
	p->queue_no = queue_no;
    80001b3c:	18b52c23          	sw	a1,408(a0)
}
    80001b40:	6422                	ld	s0,8(sp)
    80001b42:	0141                	addi	sp,sp,16
    80001b44:	8082                	ret

0000000080001b46 <sys_sigalarm>:
{
    80001b46:	1101                	addi	sp,sp,-32
    80001b48:	ec06                	sd	ra,24(sp)
    80001b4a:	e822                	sd	s0,16(sp)
    80001b4c:	1000                	addi	s0,sp,32
	argint(0, &ticks);
    80001b4e:	fec40593          	addi	a1,s0,-20
    80001b52:	4501                	li	a0,0
    80001b54:	00001097          	auipc	ra,0x1
    80001b58:	64e080e7          	jalr	1614(ra) # 800031a2 <argint>
	argaddr(1, &handler);
    80001b5c:	fe040593          	addi	a1,s0,-32
    80001b60:	4505                	li	a0,1
    80001b62:	00001097          	auipc	ra,0x1
    80001b66:	660080e7          	jalr	1632(ra) # 800031c2 <argaddr>
	myproc()->is_sigalarm = 0;
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	e6c080e7          	jalr	-404(ra) # 800019d6 <myproc>
    80001b72:	16052a23          	sw	zero,372(a0)
	myproc()->ticks = ticks;
    80001b76:	00000097          	auipc	ra,0x0
    80001b7a:	e60080e7          	jalr	-416(ra) # 800019d6 <myproc>
    80001b7e:	fec42783          	lw	a5,-20(s0)
    80001b82:	16f52e23          	sw	a5,380(a0)
	myproc()->now_ticks = 0;
    80001b86:	00000097          	auipc	ra,0x0
    80001b8a:	e50080e7          	jalr	-432(ra) # 800019d6 <myproc>
    80001b8e:	18052023          	sw	zero,384(a0)
	myproc()->handler = handler;
    80001b92:	00000097          	auipc	ra,0x0
    80001b96:	e44080e7          	jalr	-444(ra) # 800019d6 <myproc>
    80001b9a:	fe043783          	ld	a5,-32(s0)
    80001b9e:	18f53423          	sd	a5,392(a0)
}
    80001ba2:	4501                	li	a0,0
    80001ba4:	60e2                	ld	ra,24(sp)
    80001ba6:	6442                	ld	s0,16(sp)
    80001ba8:	6105                	addi	sp,sp,32
    80001baa:	8082                	ret

0000000080001bac <proc_pagetable>:
{
    80001bac:	1101                	addi	sp,sp,-32
    80001bae:	ec06                	sd	ra,24(sp)
    80001bb0:	e822                	sd	s0,16(sp)
    80001bb2:	e426                	sd	s1,8(sp)
    80001bb4:	e04a                	sd	s2,0(sp)
    80001bb6:	1000                	addi	s0,sp,32
    80001bb8:	892a                	mv	s2,a0
	pagetable = uvmcreate();
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	768080e7          	jalr	1896(ra) # 80001322 <uvmcreate>
    80001bc2:	84aa                	mv	s1,a0
	if(pagetable == 0)
    80001bc4:	c121                	beqz	a0,80001c04 <proc_pagetable+0x58>
	if(mappages(pagetable, TRAMPOLINE, PGSIZE, (uint64)trampoline, PTE_R | PTE_X) < 0)
    80001bc6:	4729                	li	a4,10
    80001bc8:	00005697          	auipc	a3,0x5
    80001bcc:	43868693          	addi	a3,a3,1080 # 80007000 <_trampoline>
    80001bd0:	6605                	lui	a2,0x1
    80001bd2:	040005b7          	lui	a1,0x4000
    80001bd6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bd8:	05b2                	slli	a1,a1,0xc
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	4be080e7          	jalr	1214(ra) # 80001098 <mappages>
    80001be2:	02054863          	bltz	a0,80001c12 <proc_pagetable+0x66>
	if(mappages(pagetable, TRAPFRAME, PGSIZE, (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
    80001be6:	4719                	li	a4,6
    80001be8:	05893683          	ld	a3,88(s2)
    80001bec:	6605                	lui	a2,0x1
    80001bee:	020005b7          	lui	a1,0x2000
    80001bf2:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bf4:	05b6                	slli	a1,a1,0xd
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	4a0080e7          	jalr	1184(ra) # 80001098 <mappages>
    80001c00:	02054163          	bltz	a0,80001c22 <proc_pagetable+0x76>
}
    80001c04:	8526                	mv	a0,s1
    80001c06:	60e2                	ld	ra,24(sp)
    80001c08:	6442                	ld	s0,16(sp)
    80001c0a:	64a2                	ld	s1,8(sp)
    80001c0c:	6902                	ld	s2,0(sp)
    80001c0e:	6105                	addi	sp,sp,32
    80001c10:	8082                	ret
		uvmfree(pagetable, 0);
    80001c12:	4581                	li	a1,0
    80001c14:	8526                	mv	a0,s1
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	912080e7          	jalr	-1774(ra) # 80001528 <uvmfree>
		return 0;
    80001c1e:	4481                	li	s1,0
    80001c20:	b7d5                	j	80001c04 <proc_pagetable+0x58>
		uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c22:	4681                	li	a3,0
    80001c24:	4605                	li	a2,1
    80001c26:	040005b7          	lui	a1,0x4000
    80001c2a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c2c:	05b2                	slli	a1,a1,0xc
    80001c2e:	8526                	mv	a0,s1
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	62e080e7          	jalr	1582(ra) # 8000125e <uvmunmap>
		uvmfree(pagetable, 0);
    80001c38:	4581                	li	a1,0
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	00000097          	auipc	ra,0x0
    80001c40:	8ec080e7          	jalr	-1812(ra) # 80001528 <uvmfree>
		return 0;
    80001c44:	4481                	li	s1,0
    80001c46:	bf7d                	j	80001c04 <proc_pagetable+0x58>

0000000080001c48 <proc_freepagetable>:
{
    80001c48:	1101                	addi	sp,sp,-32
    80001c4a:	ec06                	sd	ra,24(sp)
    80001c4c:	e822                	sd	s0,16(sp)
    80001c4e:	e426                	sd	s1,8(sp)
    80001c50:	e04a                	sd	s2,0(sp)
    80001c52:	1000                	addi	s0,sp,32
    80001c54:	84aa                	mv	s1,a0
    80001c56:	892e                	mv	s2,a1
	uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c58:	4681                	li	a3,0
    80001c5a:	4605                	li	a2,1
    80001c5c:	040005b7          	lui	a1,0x4000
    80001c60:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c62:	05b2                	slli	a1,a1,0xc
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	5fa080e7          	jalr	1530(ra) # 8000125e <uvmunmap>
	uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c6c:	4681                	li	a3,0
    80001c6e:	4605                	li	a2,1
    80001c70:	020005b7          	lui	a1,0x2000
    80001c74:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c76:	05b6                	slli	a1,a1,0xd
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	5e4080e7          	jalr	1508(ra) # 8000125e <uvmunmap>
	uvmfree(pagetable, sz);
    80001c82:	85ca                	mv	a1,s2
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	8a2080e7          	jalr	-1886(ra) # 80001528 <uvmfree>
}
    80001c8e:	60e2                	ld	ra,24(sp)
    80001c90:	6442                	ld	s0,16(sp)
    80001c92:	64a2                	ld	s1,8(sp)
    80001c94:	6902                	ld	s2,0(sp)
    80001c96:	6105                	addi	sp,sp,32
    80001c98:	8082                	ret

0000000080001c9a <freeproc>:
{
    80001c9a:	1101                	addi	sp,sp,-32
    80001c9c:	ec06                	sd	ra,24(sp)
    80001c9e:	e822                	sd	s0,16(sp)
    80001ca0:	e426                	sd	s1,8(sp)
    80001ca2:	1000                	addi	s0,sp,32
    80001ca4:	84aa                	mv	s1,a0
	if(p->backup_trapframe)
    80001ca6:	19053503          	ld	a0,400(a0)
    80001caa:	c509                	beqz	a0,80001cb4 <freeproc+0x1a>
		kfree((void*)p->backup_trapframe);
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	d38080e7          	jalr	-712(ra) # 800009e4 <kfree>
	if(p->trapframe)
    80001cb4:	6ca8                	ld	a0,88(s1)
    80001cb6:	c509                	beqz	a0,80001cc0 <freeproc+0x26>
		kfree((void*)p->trapframe);
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	d2c080e7          	jalr	-724(ra) # 800009e4 <kfree>
	p->trapframe = 0;
    80001cc0:	0404bc23          	sd	zero,88(s1)
	if(p->pagetable)
    80001cc4:	68a8                	ld	a0,80(s1)
    80001cc6:	c511                	beqz	a0,80001cd2 <freeproc+0x38>
		proc_freepagetable(p->pagetable, p->sz);
    80001cc8:	64ac                	ld	a1,72(s1)
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	f7e080e7          	jalr	-130(ra) # 80001c48 <proc_freepagetable>
	p->pagetable = 0;
    80001cd2:	0404b823          	sd	zero,80(s1)
	p->sz = 0;
    80001cd6:	0404b423          	sd	zero,72(s1)
	p->pid = 0;
    80001cda:	0204a823          	sw	zero,48(s1)
	p->parent = 0;
    80001cde:	0204bc23          	sd	zero,56(s1)
	p->name[0] = 0;
    80001ce2:	14048c23          	sb	zero,344(s1)
	p->chan = 0;
    80001ce6:	0204b023          	sd	zero,32(s1)
	p->killed = 0;
    80001cea:	0204a423          	sw	zero,40(s1)
	p->xstate = 0;
    80001cee:	0204a623          	sw	zero,44(s1)
	p->state = UNUSED;
    80001cf2:	0004ac23          	sw	zero,24(s1)
	p->start_time = 0 ;
    80001cf6:	1604ac23          	sw	zero,376(s1)
		p->queue_no = 0;
    80001cfa:	1804ac23          	sw	zero,408(s1)
		p->time_spent[i] = 0;
    80001cfe:	1804ae23          	sw	zero,412(s1)
    80001d02:	1a04a023          	sw	zero,416(s1)
    80001d06:	1a04a223          	sw	zero,420(s1)
    80001d0a:	1a04a423          	sw	zero,424(s1)
}
    80001d0e:	60e2                	ld	ra,24(sp)
    80001d10:	6442                	ld	s0,16(sp)
    80001d12:	64a2                	ld	s1,8(sp)
    80001d14:	6105                	addi	sp,sp,32
    80001d16:	8082                	ret

0000000080001d18 <allocproc>:
{
    80001d18:	1101                	addi	sp,sp,-32
    80001d1a:	ec06                	sd	ra,24(sp)
    80001d1c:	e822                	sd	s0,16(sp)
    80001d1e:	e426                	sd	s1,8(sp)
    80001d20:	e04a                	sd	s2,0(sp)
    80001d22:	1000                	addi	s0,sp,32
	for(p = proc; p < &proc[NPROC]; p++)
    80001d24:	00010497          	auipc	s1,0x10
    80001d28:	f2c48493          	addi	s1,s1,-212 # 80011c50 <proc>
    80001d2c:	00017917          	auipc	s2,0x17
    80001d30:	f2490913          	addi	s2,s2,-220 # 80018c50 <tickslock>
		acquire(&p->lock);
    80001d34:	8526                	mv	a0,s1
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	e9c080e7          	jalr	-356(ra) # 80000bd2 <acquire>
		if(p->state == UNUSED)
    80001d3e:	4c9c                	lw	a5,24(s1)
    80001d40:	cf81                	beqz	a5,80001d58 <allocproc+0x40>
			release(&p->lock);
    80001d42:	8526                	mv	a0,s1
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	f42080e7          	jalr	-190(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    80001d4c:	1c048493          	addi	s1,s1,448
    80001d50:	ff2492e3          	bne	s1,s2,80001d34 <allocproc+0x1c>
	return 0;
    80001d54:	4481                	li	s1,0
    80001d56:	a05d                	j	80001dfc <allocproc+0xe4>
	p->pid = allocpid();
    80001d58:	00000097          	auipc	ra,0x0
    80001d5c:	cfc080e7          	jalr	-772(ra) # 80001a54 <allocpid>
    80001d60:	d888                	sw	a0,48(s1)
	p->state = USED;
    80001d62:	4785                	li	a5,1
    80001d64:	cc9c                	sw	a5,24(s1)
	if((p->trapframe = (struct trapframe*)kalloc()) == 0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	d7c080e7          	jalr	-644(ra) # 80000ae2 <kalloc>
    80001d6e:	892a                	mv	s2,a0
    80001d70:	eca8                	sd	a0,88(s1)
    80001d72:	cd41                	beqz	a0,80001e0a <allocproc+0xf2>
	if((p->backup_trapframe = (struct trapframe*)kalloc()) == 0)
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	d6e080e7          	jalr	-658(ra) # 80000ae2 <kalloc>
    80001d7c:	892a                	mv	s2,a0
    80001d7e:	18a4b823          	sd	a0,400(s1)
    80001d82:	c145                	beqz	a0,80001e22 <allocproc+0x10a>
	p->pagetable = proc_pagetable(p);
    80001d84:	8526                	mv	a0,s1
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	e26080e7          	jalr	-474(ra) # 80001bac <proc_pagetable>
    80001d8e:	892a                	mv	s2,a0
    80001d90:	e8a8                	sd	a0,80(s1)
	if(p->pagetable == 0)
    80001d92:	cd59                	beqz	a0,80001e30 <allocproc+0x118>
	memset(&p->context, 0, sizeof(p->context));
    80001d94:	07000613          	li	a2,112
    80001d98:	4581                	li	a1,0
    80001d9a:	06048513          	addi	a0,s1,96
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	f30080e7          	jalr	-208(ra) # 80000cce <memset>
	p->context.ra = (uint64)forkret;
    80001da6:	00000797          	auipc	a5,0x0
    80001daa:	c6878793          	addi	a5,a5,-920 # 80001a0e <forkret>
    80001dae:	f0bc                	sd	a5,96(s1)
	p->context.sp = p->kstack + PGSIZE;
    80001db0:	60bc                	ld	a5,64(s1)
    80001db2:	6705                	lui	a4,0x1
    80001db4:	97ba                	add	a5,a5,a4
    80001db6:	f4bc                	sd	a5,104(s1)
	p->rtime = 0;
    80001db8:	1604a423          	sw	zero,360(s1)
	p->etime = 0;
    80001dbc:	1604a823          	sw	zero,368(s1)
	p->ctime = ticks;
    80001dc0:	00007797          	auipc	a5,0x7
    80001dc4:	b507a783          	lw	a5,-1200(a5) # 80008910 <ticks>
    80001dc8:	16f4a623          	sw	a5,364(s1)
	p->is_sigalarm = 0;
    80001dcc:	1604aa23          	sw	zero,372(s1)
	p->ticks = 0;
    80001dd0:	1604ae23          	sw	zero,380(s1)
	p->now_ticks = 0;
    80001dd4:	1804a023          	sw	zero,384(s1)
	p->handler = 0;
    80001dd8:	1804b423          	sd	zero,392(s1)
	p->start_time = 0 ;
    80001ddc:	1604ac23          	sw	zero,376(s1)
	p->q_wait_time = 0;
    80001de0:	1a04a823          	sw	zero,432(s1)
	p->q_run_time = 0;
    80001de4:	1a04aa23          	sw	zero,436(s1)
	p->q_leap = 0;
    80001de8:	1a04ac23          	sw	zero,440(s1)
		p->time_spent[i] = 0;
    80001dec:	1804ae23          	sw	zero,412(s1)
    80001df0:	1a04a023          	sw	zero,416(s1)
    80001df4:	1a04a223          	sw	zero,420(s1)
    80001df8:	1a04a423          	sw	zero,424(s1)
}
    80001dfc:	8526                	mv	a0,s1
    80001dfe:	60e2                	ld	ra,24(sp)
    80001e00:	6442                	ld	s0,16(sp)
    80001e02:	64a2                	ld	s1,8(sp)
    80001e04:	6902                	ld	s2,0(sp)
    80001e06:	6105                	addi	sp,sp,32
    80001e08:	8082                	ret
		freeproc(p);
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	e8e080e7          	jalr	-370(ra) # 80001c9a <freeproc>
		release(&p->lock);
    80001e14:	8526                	mv	a0,s1
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	e70080e7          	jalr	-400(ra) # 80000c86 <release>
		return 0;
    80001e1e:	84ca                	mv	s1,s2
    80001e20:	bff1                	j	80001dfc <allocproc+0xe4>
		release(&p->lock);
    80001e22:	8526                	mv	a0,s1
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	e62080e7          	jalr	-414(ra) # 80000c86 <release>
		return 0;
    80001e2c:	84ca                	mv	s1,s2
    80001e2e:	b7f9                	j	80001dfc <allocproc+0xe4>
		freeproc(p);
    80001e30:	8526                	mv	a0,s1
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	e68080e7          	jalr	-408(ra) # 80001c9a <freeproc>
		release(&p->lock);
    80001e3a:	8526                	mv	a0,s1
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	e4a080e7          	jalr	-438(ra) # 80000c86 <release>
		return 0;
    80001e44:	84ca                	mv	s1,s2
    80001e46:	bf5d                	j	80001dfc <allocproc+0xe4>

0000000080001e48 <userinit>:
{
    80001e48:	1101                	addi	sp,sp,-32
    80001e4a:	ec06                	sd	ra,24(sp)
    80001e4c:	e822                	sd	s0,16(sp)
    80001e4e:	e426                	sd	s1,8(sp)
    80001e50:	1000                	addi	s0,sp,32
	p = allocproc();
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	ec6080e7          	jalr	-314(ra) # 80001d18 <allocproc>
    80001e5a:	84aa                	mv	s1,a0
	initproc = p;
    80001e5c:	00007797          	auipc	a5,0x7
    80001e60:	aaa7b623          	sd	a0,-1364(a5) # 80008908 <initproc>
	uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e64:	03400613          	li	a2,52
    80001e68:	00007597          	auipc	a1,0x7
    80001e6c:	a1858593          	addi	a1,a1,-1512 # 80008880 <initcode>
    80001e70:	6928                	ld	a0,80(a0)
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	4de080e7          	jalr	1246(ra) # 80001350 <uvmfirst>
	p->sz = PGSIZE;
    80001e7a:	6785                	lui	a5,0x1
    80001e7c:	e4bc                	sd	a5,72(s1)
	p->trapframe->epc = 0; // user program counter
    80001e7e:	6cb8                	ld	a4,88(s1)
    80001e80:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
	p->trapframe->sp = PGSIZE; // user stack pointer
    80001e84:	6cb8                	ld	a4,88(s1)
    80001e86:	fb1c                	sd	a5,48(a4)
	safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e88:	4641                	li	a2,16
    80001e8a:	00006597          	auipc	a1,0x6
    80001e8e:	37658593          	addi	a1,a1,886 # 80008200 <digits+0x1c0>
    80001e92:	15848513          	addi	a0,s1,344
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	f80080e7          	jalr	-128(ra) # 80000e16 <safestrcpy>
	p->cwd = namei("/");
    80001e9e:	00006517          	auipc	a0,0x6
    80001ea2:	37250513          	addi	a0,a0,882 # 80008210 <digits+0x1d0>
    80001ea6:	00002097          	auipc	ra,0x2
    80001eaa:	73c080e7          	jalr	1852(ra) # 800045e2 <namei>
    80001eae:	14a4b823          	sd	a0,336(s1)
	p->state = RUNNABLE;
    80001eb2:	478d                	li	a5,3
    80001eb4:	cc9c                	sw	a5,24(s1)
	release(&p->lock);
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	dce080e7          	jalr	-562(ra) # 80000c86 <release>
	queue_add(p, 0);
    80001ec0:	4581                	li	a1,0
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	00000097          	auipc	ra,0x0
    80001ec8:	c3e080e7          	jalr	-962(ra) # 80001b02 <queue_add>
}
    80001ecc:	60e2                	ld	ra,24(sp)
    80001ece:	6442                	ld	s0,16(sp)
    80001ed0:	64a2                	ld	s1,8(sp)
    80001ed2:	6105                	addi	sp,sp,32
    80001ed4:	8082                	ret

0000000080001ed6 <growproc>:
{
    80001ed6:	1101                	addi	sp,sp,-32
    80001ed8:	ec06                	sd	ra,24(sp)
    80001eda:	e822                	sd	s0,16(sp)
    80001edc:	e426                	sd	s1,8(sp)
    80001ede:	e04a                	sd	s2,0(sp)
    80001ee0:	1000                	addi	s0,sp,32
    80001ee2:	892a                	mv	s2,a0
	struct proc* p = myproc();
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	af2080e7          	jalr	-1294(ra) # 800019d6 <myproc>
    80001eec:	84aa                	mv	s1,a0
	sz = p->sz;
    80001eee:	652c                	ld	a1,72(a0)
	if(n > 0)
    80001ef0:	01204c63          	bgtz	s2,80001f08 <growproc+0x32>
	else if(n < 0)
    80001ef4:	02094663          	bltz	s2,80001f20 <growproc+0x4a>
	p->sz = sz;
    80001ef8:	e4ac                	sd	a1,72(s1)
	return 0;
    80001efa:	4501                	li	a0,0
}
    80001efc:	60e2                	ld	ra,24(sp)
    80001efe:	6442                	ld	s0,16(sp)
    80001f00:	64a2                	ld	s1,8(sp)
    80001f02:	6902                	ld	s2,0(sp)
    80001f04:	6105                	addi	sp,sp,32
    80001f06:	8082                	ret
		if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f08:	4691                	li	a3,4
    80001f0a:	00b90633          	add	a2,s2,a1
    80001f0e:	6928                	ld	a0,80(a0)
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	4fa080e7          	jalr	1274(ra) # 8000140a <uvmalloc>
    80001f18:	85aa                	mv	a1,a0
    80001f1a:	fd79                	bnez	a0,80001ef8 <growproc+0x22>
			return -1;
    80001f1c:	557d                	li	a0,-1
    80001f1e:	bff9                	j	80001efc <growproc+0x26>
		sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f20:	00b90633          	add	a2,s2,a1
    80001f24:	6928                	ld	a0,80(a0)
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	49c080e7          	jalr	1180(ra) # 800013c2 <uvmdealloc>
    80001f2e:	85aa                	mv	a1,a0
    80001f30:	b7e1                	j	80001ef8 <growproc+0x22>

0000000080001f32 <scheduler>:
{
    80001f32:	7119                	addi	sp,sp,-128
    80001f34:	fc86                	sd	ra,120(sp)
    80001f36:	f8a2                	sd	s0,112(sp)
    80001f38:	f4a6                	sd	s1,104(sp)
    80001f3a:	f0ca                	sd	s2,96(sp)
    80001f3c:	ecce                	sd	s3,88(sp)
    80001f3e:	e8d2                	sd	s4,80(sp)
    80001f40:	e4d6                	sd	s5,72(sp)
    80001f42:	e0da                	sd	s6,64(sp)
    80001f44:	fc5e                	sd	s7,56(sp)
    80001f46:	f862                	sd	s8,48(sp)
    80001f48:	f466                	sd	s9,40(sp)
    80001f4a:	f06a                	sd	s10,32(sp)
    80001f4c:	ec6e                	sd	s11,24(sp)
    80001f4e:	0100                	addi	s0,sp,128
    80001f50:	8792                	mv	a5,tp
	int id = r_tp();
    80001f52:	2781                	sext.w	a5,a5
	c->proc = 0;
    80001f54:	00779693          	slli	a3,a5,0x7
    80001f58:	0000f717          	auipc	a4,0xf
    80001f5c:	c2870713          	addi	a4,a4,-984 # 80010b80 <pid_lock>
    80001f60:	9736                	add	a4,a4,a3
    80001f62:	02073823          	sd	zero,48(a4)
				swtch(&c->context, &executable->context);
    80001f66:	0000f717          	auipc	a4,0xf
    80001f6a:	c5270713          	addi	a4,a4,-942 # 80010bb8 <cpus+0x8>
    80001f6e:	9736                	add	a4,a4,a3
    80001f70:	f8e43423          	sd	a4,-120(s0)
				acquire(&queues[i].arr[j]->lock);
    80001f74:	0000fb97          	auipc	s7,0xf
    80001f78:	03cb8b93          	addi	s7,s7,60 # 80010fb0 <queues>
				c->proc = executable;
    80001f7c:	0000f717          	auipc	a4,0xf
    80001f80:	c0470713          	addi	a4,a4,-1020 # 80010b80 <pid_lock>
    80001f84:	00d707b3          	add	a5,a4,a3
    80001f88:	f8f43023          	sd	a5,-128(s0)
    80001f8c:	a8c9                	j	8000205e <scheduler+0x12c>
					release(&temp->lock);
    80001f8e:	8526                	mv	a0,s1
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	cf6080e7          	jalr	-778(ra) # 80000c86 <release>
			for (int j = 0; j < queues[i].queue_size; j++)
    80001f98:	2905                	addiw	s2,s2,1
    80001f9a:	648a2783          	lw	a5,1608(s4)
    80001f9e:	04f95063          	bge	s2,a5,80001fde <scheduler+0xac>
				acquire(&queues[i].arr[j]->lock);
    80001fa2:	012a84b3          	add	s1,s5,s2
    80001fa6:	048e                	slli	s1,s1,0x3
    80001fa8:	94de                	add	s1,s1,s7
    80001faa:	6088                	ld	a0,0(s1)
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	c26080e7          	jalr	-986(ra) # 80000bd2 <acquire>
				struct proc* temp = queues[i].arr[j] ; 
    80001fb4:	6084                	ld	s1,0(s1)
				if( temp->q_wait_time >= AGE_MAX  && i>0 )
    80001fb6:	1b04a783          	lw	a5,432(s1)
    80001fba:	fcfb7ae3          	bgeu	s6,a5,80001f8e <scheduler+0x5c>
    80001fbe:	fd3058e3          	blez	s3,80001f8e <scheduler+0x5c>
					queue_remove(j,i);
    80001fc2:	85ce                	mv	a1,s3
    80001fc4:	854a                	mv	a0,s2
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	ad4080e7          	jalr	-1324(ra) # 80001a9a <queue_remove>
					queue_add(temp,i-1);
    80001fce:	85e6                	mv	a1,s9
    80001fd0:	8526                	mv	a0,s1
    80001fd2:	00000097          	auipc	ra,0x0
    80001fd6:	b30080e7          	jalr	-1232(ra) # 80001b02 <queue_add>
					j--;
    80001fda:	397d                	addiw	s2,s2,-1
    80001fdc:	bf4d                	j	80001f8e <scheduler+0x5c>
		for(i= 1 ; i<NUM_OF_QUEUES;i++)
    80001fde:	2985                	addiw	s3,s3,1
    80001fe0:	0d85                	addi	s11,s11,1
    80001fe2:	328d0d13          	addi	s10,s10,808
    80001fe6:	4791                	li	a5,4
    80001fe8:	00f98f63          	beq	s3,a5,80002006 <scheduler+0xd4>
			for (int j = 0; j < queues[i].queue_size; j++)
    80001fec:	8a6a                	mv	s4,s10
    80001fee:	648d2783          	lw	a5,1608(s10)
    80001ff2:	4901                	li	s2,0
    80001ff4:	fef055e3          	blez	a5,80001fde <scheduler+0xac>
				acquire(&queues[i].arr[j]->lock);
    80001ff8:	06500793          	li	a5,101
    80001ffc:	02f98ab3          	mul	s5,s3,a5
					queue_add(temp,i-1);
    80002000:	000d8c9b          	sext.w	s9,s11
    80002004:	bf79                	j	80001fa2 <scheduler+0x70>
		for(i=0;i<NUM_OF_QUEUES;i++)
    80002006:	4a81                	li	s5,0
					if( queues[i].arr[j]->state == RUNNABLE)
    80002008:	4c8d                	li	s9,3
		for(i=0;i<NUM_OF_QUEUES;i++)
    8000200a:	4d11                	li	s10,4
    8000200c:	a8b5                	j	80002088 <scheduler+0x156>
						queue_remove(j,i); // we are removiing so that it can be added to the end of the queue or removed permanently
    8000200e:	85d6                	mv	a1,s5
    80002010:	854e                	mv	a0,s3
    80002012:	00000097          	auipc	ra,0x0
    80002016:	a88080e7          	jalr	-1400(ra) # 80001a9a <queue_remove>
			if(executable->state == RUNNABLE)
    8000201a:	01892703          	lw	a4,24(s2)
    8000201e:	478d                	li	a5,3
    80002020:	02f71a63          	bne	a4,a5,80002054 <scheduler+0x122>
				executable->state = RUNNING;
    80002024:	4791                	li	a5,4
    80002026:	00f92c23          	sw	a5,24(s2)
				executable->q_wait_time = 0;
    8000202a:	1a092823          	sw	zero,432(s2)
				c->proc = executable;
    8000202e:	f8043483          	ld	s1,-128(s0)
    80002032:	0324b823          	sd	s2,48(s1)
				swtch(&c->context, &executable->context);
    80002036:	06090593          	addi	a1,s2,96
    8000203a:	f8843503          	ld	a0,-120(s0)
    8000203e:	00001097          	auipc	ra,0x1
    80002042:	b5a080e7          	jalr	-1190(ra) # 80002b98 <swtch>
				c->proc = 0;
    80002046:	0204b823          	sd	zero,48(s1)
				if(executable-> state == RUNNABLE)
    8000204a:	01892703          	lw	a4,24(s2)
    8000204e:	478d                	li	a5,3
    80002050:	06f70a63          	beq	a4,a5,800020c4 <scheduler+0x192>
			release(&executable->lock);
    80002054:	854a                	mv	a0,s2
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	c30080e7          	jalr	-976(ra) # 80000c86 <release>
				if( temp->q_wait_time >= AGE_MAX  && i>0 )
    8000205e:	03100b13          	li	s6,49
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002062:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002066:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000206a:	10079073          	csrw	sstatus,a5
		for(i= 1 ; i<NUM_OF_QUEUES;i++)
    8000206e:	0000fc17          	auipc	s8,0xf
    80002072:	f42c0c13          	addi	s8,s8,-190 # 80010fb0 <queues>
    80002076:	8d62                	mv	s10,s8
    80002078:	4d81                	li	s11,0
    8000207a:	4985                	li	s3,1
    8000207c:	bf85                	j	80001fec <scheduler+0xba>
		for(i=0;i<NUM_OF_QUEUES;i++)
    8000207e:	2a85                	addiw	s5,s5,1
    80002080:	328c0c13          	addi	s8,s8,808
    80002084:	fdaa8fe3          	beq	s5,s10,80002062 <scheduler+0x130>
			if(queues[i].queue_size>0)
    80002088:	8a62                	mv	s4,s8
    8000208a:	320c2783          	lw	a5,800(s8)
    8000208e:	fef058e3          	blez	a5,8000207e <scheduler+0x14c>
    80002092:	84e2                	mv	s1,s8
				for (int j = 0; j < queues[i].queue_size; j++)
    80002094:	4981                	li	s3,0
					acquire(&queues[i].arr[j]->lock);
    80002096:	6088                	ld	a0,0(s1)
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	b3a080e7          	jalr	-1222(ra) # 80000bd2 <acquire>
					struct proc* temp = queues[i].arr[j] ; 
    800020a0:	0004b903          	ld	s2,0(s1)
					if( queues[i].arr[j]->state == RUNNABLE)
    800020a4:	01892783          	lw	a5,24(s2)
    800020a8:	f79783e3          	beq	a5,s9,8000200e <scheduler+0xdc>
					release(&temp->lock);
    800020ac:	854a                	mv	a0,s2
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bd8080e7          	jalr	-1064(ra) # 80000c86 <release>
				for (int j = 0; j < queues[i].queue_size; j++)
    800020b6:	2985                	addiw	s3,s3,1
    800020b8:	04a1                	addi	s1,s1,8
    800020ba:	320a2783          	lw	a5,800(s4)
    800020be:	fcf9cce3          	blt	s3,a5,80002096 <scheduler+0x164>
    800020c2:	bf75                	j	8000207e <scheduler+0x14c>
					if(executable->q_leap == 1)
    800020c4:	1b892703          	lw	a4,440(s2)
    800020c8:	4785                	li	a5,1
    800020ca:	00f70a63          	beq	a4,a5,800020de <scheduler+0x1ac>
				queue_add(executable, executable->queue_no);
    800020ce:	19892583          	lw	a1,408(s2)
    800020d2:	854a                	mv	a0,s2
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	a2e080e7          	jalr	-1490(ra) # 80001b02 <queue_add>
    800020dc:	bfa5                	j	80002054 <scheduler+0x122>
						if(executable->queue_no != NUM_OF_QUEUES - 1)
    800020de:	19892783          	lw	a5,408(s2)
    800020e2:	470d                	li	a4,3
    800020e4:	00e78563          	beq	a5,a4,800020ee <scheduler+0x1bc>
							executable->queue_no++;
    800020e8:	2785                	addiw	a5,a5,1 # 1001 <_entry-0x7fffefff>
    800020ea:	18f92c23          	sw	a5,408(s2)
						executable->q_leap = 0;
    800020ee:	1a092c23          	sw	zero,440(s2)
    800020f2:	bff1                	j	800020ce <scheduler+0x19c>

00000000800020f4 <sched>:
{
    800020f4:	7179                	addi	sp,sp,-48
    800020f6:	f406                	sd	ra,40(sp)
    800020f8:	f022                	sd	s0,32(sp)
    800020fa:	ec26                	sd	s1,24(sp)
    800020fc:	e84a                	sd	s2,16(sp)
    800020fe:	e44e                	sd	s3,8(sp)
    80002100:	1800                	addi	s0,sp,48
	struct proc* p = myproc();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	8d4080e7          	jalr	-1836(ra) # 800019d6 <myproc>
    8000210a:	84aa                	mv	s1,a0
	if(!holding(&p->lock))
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	a4c080e7          	jalr	-1460(ra) # 80000b58 <holding>
    80002114:	c93d                	beqz	a0,8000218a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002116:	8792                	mv	a5,tp
	if(mycpu()->noff != 1)
    80002118:	2781                	sext.w	a5,a5
    8000211a:	079e                	slli	a5,a5,0x7
    8000211c:	0000f717          	auipc	a4,0xf
    80002120:	a6470713          	addi	a4,a4,-1436 # 80010b80 <pid_lock>
    80002124:	97ba                	add	a5,a5,a4
    80002126:	0a87a703          	lw	a4,168(a5)
    8000212a:	4785                	li	a5,1
    8000212c:	06f71763          	bne	a4,a5,8000219a <sched+0xa6>
	if(p->state == RUNNING)
    80002130:	4c98                	lw	a4,24(s1)
    80002132:	4791                	li	a5,4
    80002134:	06f70b63          	beq	a4,a5,800021aa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002138:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000213c:	8b89                	andi	a5,a5,2
	if(intr_get())
    8000213e:	efb5                	bnez	a5,800021ba <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002140:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    80002142:	0000f917          	auipc	s2,0xf
    80002146:	a3e90913          	addi	s2,s2,-1474 # 80010b80 <pid_lock>
    8000214a:	2781                	sext.w	a5,a5
    8000214c:	079e                	slli	a5,a5,0x7
    8000214e:	97ca                	add	a5,a5,s2
    80002150:	0ac7a983          	lw	s3,172(a5)
    80002154:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    80002156:	2781                	sext.w	a5,a5
    80002158:	079e                	slli	a5,a5,0x7
    8000215a:	0000f597          	auipc	a1,0xf
    8000215e:	a5e58593          	addi	a1,a1,-1442 # 80010bb8 <cpus+0x8>
    80002162:	95be                	add	a1,a1,a5
    80002164:	06048513          	addi	a0,s1,96
    80002168:	00001097          	auipc	ra,0x1
    8000216c:	a30080e7          	jalr	-1488(ra) # 80002b98 <swtch>
    80002170:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    80002172:	2781                	sext.w	a5,a5
    80002174:	079e                	slli	a5,a5,0x7
    80002176:	993e                	add	s2,s2,a5
    80002178:	0b392623          	sw	s3,172(s2)
}
    8000217c:	70a2                	ld	ra,40(sp)
    8000217e:	7402                	ld	s0,32(sp)
    80002180:	64e2                	ld	s1,24(sp)
    80002182:	6942                	ld	s2,16(sp)
    80002184:	69a2                	ld	s3,8(sp)
    80002186:	6145                	addi	sp,sp,48
    80002188:	8082                	ret
		panic("sched p->lock");
    8000218a:	00006517          	auipc	a0,0x6
    8000218e:	08e50513          	addi	a0,a0,142 # 80008218 <digits+0x1d8>
    80002192:	ffffe097          	auipc	ra,0xffffe
    80002196:	3aa080e7          	jalr	938(ra) # 8000053c <panic>
		panic("sched locks");
    8000219a:	00006517          	auipc	a0,0x6
    8000219e:	08e50513          	addi	a0,a0,142 # 80008228 <digits+0x1e8>
    800021a2:	ffffe097          	auipc	ra,0xffffe
    800021a6:	39a080e7          	jalr	922(ra) # 8000053c <panic>
		panic("sched running");
    800021aa:	00006517          	auipc	a0,0x6
    800021ae:	08e50513          	addi	a0,a0,142 # 80008238 <digits+0x1f8>
    800021b2:	ffffe097          	auipc	ra,0xffffe
    800021b6:	38a080e7          	jalr	906(ra) # 8000053c <panic>
		panic("sched interruptible");
    800021ba:	00006517          	auipc	a0,0x6
    800021be:	08e50513          	addi	a0,a0,142 # 80008248 <digits+0x208>
    800021c2:	ffffe097          	auipc	ra,0xffffe
    800021c6:	37a080e7          	jalr	890(ra) # 8000053c <panic>

00000000800021ca <yield>:
{
    800021ca:	1101                	addi	sp,sp,-32
    800021cc:	ec06                	sd	ra,24(sp)
    800021ce:	e822                	sd	s0,16(sp)
    800021d0:	e426                	sd	s1,8(sp)
    800021d2:	1000                	addi	s0,sp,32
	struct proc* p = myproc();
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	802080e7          	jalr	-2046(ra) # 800019d6 <myproc>
    800021dc:	84aa                	mv	s1,a0
	acquire(&p->lock);
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	9f4080e7          	jalr	-1548(ra) # 80000bd2 <acquire>
	p->state = RUNNABLE;
    800021e6:	478d                	li	a5,3
    800021e8:	cc9c                	sw	a5,24(s1)
	sched();
    800021ea:	00000097          	auipc	ra,0x0
    800021ee:	f0a080e7          	jalr	-246(ra) # 800020f4 <sched>
	release(&p->lock);
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	a92080e7          	jalr	-1390(ra) # 80000c86 <release>
}
    800021fc:	60e2                	ld	ra,24(sp)
    800021fe:	6442                	ld	s0,16(sp)
    80002200:	64a2                	ld	s1,8(sp)
    80002202:	6105                	addi	sp,sp,32
    80002204:	8082                	ret

0000000080002206 <fork>:
{
    80002206:	7139                	addi	sp,sp,-64
    80002208:	fc06                	sd	ra,56(sp)
    8000220a:	f822                	sd	s0,48(sp)
    8000220c:	f426                	sd	s1,40(sp)
    8000220e:	f04a                	sd	s2,32(sp)
    80002210:	ec4e                	sd	s3,24(sp)
    80002212:	e852                	sd	s4,16(sp)
    80002214:	e456                	sd	s5,8(sp)
    80002216:	0080                	addi	s0,sp,64
	struct proc* p = myproc();
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	7be080e7          	jalr	1982(ra) # 800019d6 <myproc>
    80002220:	8aaa                	mv	s5,a0
	if((np = allocproc()) == 0)
    80002222:	00000097          	auipc	ra,0x0
    80002226:	af6080e7          	jalr	-1290(ra) # 80001d18 <allocproc>
    8000222a:	12050b63          	beqz	a0,80002360 <fork+0x15a>
    8000222e:	89aa                	mv	s3,a0
	if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002230:	048ab603          	ld	a2,72(s5)
    80002234:	692c                	ld	a1,80(a0)
    80002236:	050ab503          	ld	a0,80(s5)
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	328080e7          	jalr	808(ra) # 80001562 <uvmcopy>
    80002242:	04054863          	bltz	a0,80002292 <fork+0x8c>
	np->sz = p->sz;
    80002246:	048ab783          	ld	a5,72(s5)
    8000224a:	04f9b423          	sd	a5,72(s3)
	*(np->trapframe) = *(p->trapframe);
    8000224e:	058ab683          	ld	a3,88(s5)
    80002252:	87b6                	mv	a5,a3
    80002254:	0589b703          	ld	a4,88(s3)
    80002258:	12068693          	addi	a3,a3,288
    8000225c:	0007b803          	ld	a6,0(a5)
    80002260:	6788                	ld	a0,8(a5)
    80002262:	6b8c                	ld	a1,16(a5)
    80002264:	6f90                	ld	a2,24(a5)
    80002266:	01073023          	sd	a6,0(a4)
    8000226a:	e708                	sd	a0,8(a4)
    8000226c:	eb0c                	sd	a1,16(a4)
    8000226e:	ef10                	sd	a2,24(a4)
    80002270:	02078793          	addi	a5,a5,32
    80002274:	02070713          	addi	a4,a4,32
    80002278:	fed792e3          	bne	a5,a3,8000225c <fork+0x56>
	np->trapframe->a0 = 0;
    8000227c:	0589b783          	ld	a5,88(s3)
    80002280:	0607b823          	sd	zero,112(a5)
	for(i = 0; i < NOFILE; i++)
    80002284:	0d0a8493          	addi	s1,s5,208
    80002288:	0d098913          	addi	s2,s3,208
    8000228c:	150a8a13          	addi	s4,s5,336
    80002290:	a00d                	j	800022b2 <fork+0xac>
		freeproc(np);
    80002292:	854e                	mv	a0,s3
    80002294:	00000097          	auipc	ra,0x0
    80002298:	a06080e7          	jalr	-1530(ra) # 80001c9a <freeproc>
		release(&np->lock);
    8000229c:	854e                	mv	a0,s3
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	9e8080e7          	jalr	-1560(ra) # 80000c86 <release>
		return -1;
    800022a6:	597d                	li	s2,-1
    800022a8:	a869                	j	80002342 <fork+0x13c>
	for(i = 0; i < NOFILE; i++)
    800022aa:	04a1                	addi	s1,s1,8
    800022ac:	0921                	addi	s2,s2,8
    800022ae:	01448b63          	beq	s1,s4,800022c4 <fork+0xbe>
		if(p->ofile[i])
    800022b2:	6088                	ld	a0,0(s1)
    800022b4:	d97d                	beqz	a0,800022aa <fork+0xa4>
			np->ofile[i] = filedup(p->ofile[i]);
    800022b6:	00003097          	auipc	ra,0x3
    800022ba:	99e080e7          	jalr	-1634(ra) # 80004c54 <filedup>
    800022be:	00a93023          	sd	a0,0(s2)
    800022c2:	b7e5                	j	800022aa <fork+0xa4>
	np->cwd = idup(p->cwd);
    800022c4:	150ab503          	ld	a0,336(s5)
    800022c8:	00002097          	auipc	ra,0x2
    800022cc:	b36080e7          	jalr	-1226(ra) # 80003dfe <idup>
    800022d0:	14a9b823          	sd	a0,336(s3)
	safestrcpy(np->name, p->name, sizeof(p->name));
    800022d4:	4641                	li	a2,16
    800022d6:	158a8593          	addi	a1,s5,344
    800022da:	15898513          	addi	a0,s3,344
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	b38080e7          	jalr	-1224(ra) # 80000e16 <safestrcpy>
	pid = np->pid;
    800022e6:	0309a903          	lw	s2,48(s3)
	release(&np->lock);
    800022ea:	854e                	mv	a0,s3
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	99a080e7          	jalr	-1638(ra) # 80000c86 <release>
	acquire(&wait_lock);
    800022f4:	0000f497          	auipc	s1,0xf
    800022f8:	8a448493          	addi	s1,s1,-1884 # 80010b98 <wait_lock>
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	8d4080e7          	jalr	-1836(ra) # 80000bd2 <acquire>
	np->parent = p;
    80002306:	0359bc23          	sd	s5,56(s3)
	release(&wait_lock);
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	97a080e7          	jalr	-1670(ra) # 80000c86 <release>
	acquire(&np->lock);
    80002314:	854e                	mv	a0,s3
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	8bc080e7          	jalr	-1860(ra) # 80000bd2 <acquire>
	np->state = RUNNABLE;
    8000231e:	478d                	li	a5,3
    80002320:	00f9ac23          	sw	a5,24(s3)
	release(&np->lock);
    80002324:	854e                	mv	a0,s3
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	960080e7          	jalr	-1696(ra) # 80000c86 <release>
	queue_add(np, 0);
    8000232e:	4581                	li	a1,0
    80002330:	854e                	mv	a0,s3
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	7d0080e7          	jalr	2000(ra) # 80001b02 <queue_add>
	if(p!= 0&&p->queue_no>0 )
    8000233a:	198aa783          	lw	a5,408(s5)
    8000233e:	00f04c63          	bgtz	a5,80002356 <fork+0x150>
}
    80002342:	854a                	mv	a0,s2
    80002344:	70e2                	ld	ra,56(sp)
    80002346:	7442                	ld	s0,48(sp)
    80002348:	74a2                	ld	s1,40(sp)
    8000234a:	7902                	ld	s2,32(sp)
    8000234c:	69e2                	ld	s3,24(sp)
    8000234e:	6a42                	ld	s4,16(sp)
    80002350:	6aa2                	ld	s5,8(sp)
    80002352:	6121                	addi	sp,sp,64
    80002354:	8082                	ret
			yield();	
    80002356:	00000097          	auipc	ra,0x0
    8000235a:	e74080e7          	jalr	-396(ra) # 800021ca <yield>
    8000235e:	b7d5                	j	80002342 <fork+0x13c>
		return -1;
    80002360:	597d                	li	s2,-1
    80002362:	b7c5                	j	80002342 <fork+0x13c>

0000000080002364 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void* chan, struct spinlock* lk)
{
    80002364:	7179                	addi	sp,sp,-48
    80002366:	f406                	sd	ra,40(sp)
    80002368:	f022                	sd	s0,32(sp)
    8000236a:	ec26                	sd	s1,24(sp)
    8000236c:	e84a                	sd	s2,16(sp)
    8000236e:	e44e                	sd	s3,8(sp)
    80002370:	1800                	addi	s0,sp,48
    80002372:	89aa                	mv	s3,a0
    80002374:	892e                	mv	s2,a1
	struct proc* p = myproc();
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	660080e7          	jalr	1632(ra) # 800019d6 <myproc>
    8000237e:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); // DOC: sleeplock1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	852080e7          	jalr	-1966(ra) # 80000bd2 <acquire>
	release(lk);
    80002388:	854a                	mv	a0,s2
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	8fc080e7          	jalr	-1796(ra) # 80000c86 <release>

	// Go to sleep.
	p->chan = chan;
    80002392:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    80002396:	4789                	li	a5,2
    80002398:	cc9c                	sw	a5,24(s1)

	sched();
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	d5a080e7          	jalr	-678(ra) # 800020f4 <sched>

	// Tidy up.
	p->chan = 0;
    800023a2:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	8de080e7          	jalr	-1826(ra) # 80000c86 <release>
	acquire(lk);
    800023b0:	854a                	mv	a0,s2
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	820080e7          	jalr	-2016(ra) # 80000bd2 <acquire>
}
    800023ba:	70a2                	ld	ra,40(sp)
    800023bc:	7402                	ld	s0,32(sp)
    800023be:	64e2                	ld	s1,24(sp)
    800023c0:	6942                	ld	s2,16(sp)
    800023c2:	69a2                	ld	s3,8(sp)
    800023c4:	6145                	addi	sp,sp,48
    800023c6:	8082                	ret

00000000800023c8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void* chan)
{
    800023c8:	7139                	addi	sp,sp,-64
    800023ca:	fc06                	sd	ra,56(sp)
    800023cc:	f822                	sd	s0,48(sp)
    800023ce:	f426                	sd	s1,40(sp)
    800023d0:	f04a                	sd	s2,32(sp)
    800023d2:	ec4e                	sd	s3,24(sp)
    800023d4:	e852                	sd	s4,16(sp)
    800023d6:	e456                	sd	s5,8(sp)
    800023d8:	0080                	addi	s0,sp,64
    800023da:	8a2a                	mv	s4,a0
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    800023dc:	00010497          	auipc	s1,0x10
    800023e0:	87448493          	addi	s1,s1,-1932 # 80011c50 <proc>
	{
		if(p != myproc())
		{
			acquire(&p->lock);
			if(p->state == SLEEPING && p->chan == chan)
    800023e4:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    800023e6:	4a8d                	li	s5,3
	for(p = proc; p < &proc[NPROC]; p++)
    800023e8:	00017917          	auipc	s2,0x17
    800023ec:	86890913          	addi	s2,s2,-1944 # 80018c50 <tickslock>
    800023f0:	a811                	j	80002404 <wakeup+0x3c>
				#ifdef MLFQ
				queue_add(p, p->queue_no);
				#endif
			}
			release(&p->lock);
    800023f2:	8526                	mv	a0,s1
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	892080e7          	jalr	-1902(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    800023fc:	1c048493          	addi	s1,s1,448
    80002400:	03248d63          	beq	s1,s2,8000243a <wakeup+0x72>
		if(p != myproc())
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	5d2080e7          	jalr	1490(ra) # 800019d6 <myproc>
    8000240c:	fea488e3          	beq	s1,a0,800023fc <wakeup+0x34>
			acquire(&p->lock);
    80002410:	8526                	mv	a0,s1
    80002412:	ffffe097          	auipc	ra,0xffffe
    80002416:	7c0080e7          	jalr	1984(ra) # 80000bd2 <acquire>
			if(p->state == SLEEPING && p->chan == chan)
    8000241a:	4c9c                	lw	a5,24(s1)
    8000241c:	fd379be3          	bne	a5,s3,800023f2 <wakeup+0x2a>
    80002420:	709c                	ld	a5,32(s1)
    80002422:	fd4798e3          	bne	a5,s4,800023f2 <wakeup+0x2a>
				p->state = RUNNABLE;
    80002426:	0154ac23          	sw	s5,24(s1)
				queue_add(p, p->queue_no);
    8000242a:	1984a583          	lw	a1,408(s1)
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	6d2080e7          	jalr	1746(ra) # 80001b02 <queue_add>
    80002438:	bf6d                	j	800023f2 <wakeup+0x2a>
		}
	}
}
    8000243a:	70e2                	ld	ra,56(sp)
    8000243c:	7442                	ld	s0,48(sp)
    8000243e:	74a2                	ld	s1,40(sp)
    80002440:	7902                	ld	s2,32(sp)
    80002442:	69e2                	ld	s3,24(sp)
    80002444:	6a42                	ld	s4,16(sp)
    80002446:	6aa2                	ld	s5,8(sp)
    80002448:	6121                	addi	sp,sp,64
    8000244a:	8082                	ret

000000008000244c <reparent>:
{
    8000244c:	7179                	addi	sp,sp,-48
    8000244e:	f406                	sd	ra,40(sp)
    80002450:	f022                	sd	s0,32(sp)
    80002452:	ec26                	sd	s1,24(sp)
    80002454:	e84a                	sd	s2,16(sp)
    80002456:	e44e                	sd	s3,8(sp)
    80002458:	e052                	sd	s4,0(sp)
    8000245a:	1800                	addi	s0,sp,48
    8000245c:	892a                	mv	s2,a0
	for(pp = proc; pp < &proc[NPROC]; pp++)
    8000245e:	0000f497          	auipc	s1,0xf
    80002462:	7f248493          	addi	s1,s1,2034 # 80011c50 <proc>
			pp->parent = initproc;
    80002466:	00006a17          	auipc	s4,0x6
    8000246a:	4a2a0a13          	addi	s4,s4,1186 # 80008908 <initproc>
	for(pp = proc; pp < &proc[NPROC]; pp++)
    8000246e:	00016997          	auipc	s3,0x16
    80002472:	7e298993          	addi	s3,s3,2018 # 80018c50 <tickslock>
    80002476:	a029                	j	80002480 <reparent+0x34>
    80002478:	1c048493          	addi	s1,s1,448
    8000247c:	01348d63          	beq	s1,s3,80002496 <reparent+0x4a>
		if(pp->parent == p)
    80002480:	7c9c                	ld	a5,56(s1)
    80002482:	ff279be3          	bne	a5,s2,80002478 <reparent+0x2c>
			pp->parent = initproc;
    80002486:	000a3503          	ld	a0,0(s4)
    8000248a:	fc88                	sd	a0,56(s1)
			wakeup(initproc);
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	f3c080e7          	jalr	-196(ra) # 800023c8 <wakeup>
    80002494:	b7d5                	j	80002478 <reparent+0x2c>
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6a02                	ld	s4,0(sp)
    800024a2:	6145                	addi	sp,sp,48
    800024a4:	8082                	ret

00000000800024a6 <exit>:
{
    800024a6:	7179                	addi	sp,sp,-48
    800024a8:	f406                	sd	ra,40(sp)
    800024aa:	f022                	sd	s0,32(sp)
    800024ac:	ec26                	sd	s1,24(sp)
    800024ae:	e84a                	sd	s2,16(sp)
    800024b0:	e44e                	sd	s3,8(sp)
    800024b2:	e052                	sd	s4,0(sp)
    800024b4:	1800                	addi	s0,sp,48
    800024b6:	8a2a                	mv	s4,a0
	struct proc* p = myproc();
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	51e080e7          	jalr	1310(ra) # 800019d6 <myproc>
    800024c0:	89aa                	mv	s3,a0
	if(p == initproc)
    800024c2:	00006797          	auipc	a5,0x6
    800024c6:	4467b783          	ld	a5,1094(a5) # 80008908 <initproc>
    800024ca:	0d050493          	addi	s1,a0,208
    800024ce:	15050913          	addi	s2,a0,336
    800024d2:	02a79363          	bne	a5,a0,800024f8 <exit+0x52>
		panic("init exiting");
    800024d6:	00006517          	auipc	a0,0x6
    800024da:	d8a50513          	addi	a0,a0,-630 # 80008260 <digits+0x220>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	05e080e7          	jalr	94(ra) # 8000053c <panic>
			fileclose(f);
    800024e6:	00002097          	auipc	ra,0x2
    800024ea:	7c0080e7          	jalr	1984(ra) # 80004ca6 <fileclose>
			p->ofile[fd] = 0;
    800024ee:	0004b023          	sd	zero,0(s1)
	for(int fd = 0; fd < NOFILE; fd++)
    800024f2:	04a1                	addi	s1,s1,8
    800024f4:	01248563          	beq	s1,s2,800024fe <exit+0x58>
		if(p->ofile[fd])
    800024f8:	6088                	ld	a0,0(s1)
    800024fa:	f575                	bnez	a0,800024e6 <exit+0x40>
    800024fc:	bfdd                	j	800024f2 <exit+0x4c>
	begin_op();
    800024fe:	00002097          	auipc	ra,0x2
    80002502:	2e4080e7          	jalr	740(ra) # 800047e2 <begin_op>
	iput(p->cwd);
    80002506:	1509b503          	ld	a0,336(s3)
    8000250a:	00002097          	auipc	ra,0x2
    8000250e:	aec080e7          	jalr	-1300(ra) # 80003ff6 <iput>
	end_op();
    80002512:	00002097          	auipc	ra,0x2
    80002516:	34a080e7          	jalr	842(ra) # 8000485c <end_op>
	p->cwd = 0;
    8000251a:	1409b823          	sd	zero,336(s3)
	acquire(&wait_lock);
    8000251e:	0000e497          	auipc	s1,0xe
    80002522:	67a48493          	addi	s1,s1,1658 # 80010b98 <wait_lock>
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	6aa080e7          	jalr	1706(ra) # 80000bd2 <acquire>
	reparent(p);
    80002530:	854e                	mv	a0,s3
    80002532:	00000097          	auipc	ra,0x0
    80002536:	f1a080e7          	jalr	-230(ra) # 8000244c <reparent>
	wakeup(p->parent);
    8000253a:	0389b503          	ld	a0,56(s3)
    8000253e:	00000097          	auipc	ra,0x0
    80002542:	e8a080e7          	jalr	-374(ra) # 800023c8 <wakeup>
	acquire(&p->lock);
    80002546:	854e                	mv	a0,s3
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	68a080e7          	jalr	1674(ra) # 80000bd2 <acquire>
	p->xstate = status;
    80002550:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    80002554:	4795                	li	a5,5
    80002556:	00f9ac23          	sw	a5,24(s3)
	p->etime = ticks;
    8000255a:	00006797          	auipc	a5,0x6
    8000255e:	3b67a783          	lw	a5,950(a5) # 80008910 <ticks>
    80002562:	16f9a823          	sw	a5,368(s3)
	release(&wait_lock);
    80002566:	8526                	mv	a0,s1
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	71e080e7          	jalr	1822(ra) # 80000c86 <release>
	sched();
    80002570:	00000097          	auipc	ra,0x0
    80002574:	b84080e7          	jalr	-1148(ra) # 800020f4 <sched>
	panic("zombie exit");
    80002578:	00006517          	auipc	a0,0x6
    8000257c:	cf850513          	addi	a0,a0,-776 # 80008270 <digits+0x230>
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	fbc080e7          	jalr	-68(ra) # 8000053c <panic>

0000000080002588 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002588:	7179                	addi	sp,sp,-48
    8000258a:	f406                	sd	ra,40(sp)
    8000258c:	f022                	sd	s0,32(sp)
    8000258e:	ec26                	sd	s1,24(sp)
    80002590:	e84a                	sd	s2,16(sp)
    80002592:	e44e                	sd	s3,8(sp)
    80002594:	1800                	addi	s0,sp,48
    80002596:	892a                	mv	s2,a0
	struct proc* p;

	for(p = proc; p < &proc[NPROC]; p++)
    80002598:	0000f497          	auipc	s1,0xf
    8000259c:	6b848493          	addi	s1,s1,1720 # 80011c50 <proc>
    800025a0:	00016997          	auipc	s3,0x16
    800025a4:	6b098993          	addi	s3,s3,1712 # 80018c50 <tickslock>
	{
		acquire(&p->lock);
    800025a8:	8526                	mv	a0,s1
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	628080e7          	jalr	1576(ra) # 80000bd2 <acquire>
		if(p->pid == pid)
    800025b2:	589c                	lw	a5,48(s1)
    800025b4:	01278d63          	beq	a5,s2,800025ce <kill+0x46>
        #endif
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    800025b8:	8526                	mv	a0,s1
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	6cc080e7          	jalr	1740(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    800025c2:	1c048493          	addi	s1,s1,448
    800025c6:	ff3491e3          	bne	s1,s3,800025a8 <kill+0x20>
	}
	return -1;
    800025ca:	557d                	li	a0,-1
    800025cc:	a829                	j	800025e6 <kill+0x5e>
			p->killed = 1;
    800025ce:	4785                	li	a5,1
    800025d0:	d49c                	sw	a5,40(s1)
			if(p->state == SLEEPING)
    800025d2:	4c98                	lw	a4,24(s1)
    800025d4:	4789                	li	a5,2
    800025d6:	00f70f63          	beq	a4,a5,800025f4 <kill+0x6c>
			release(&p->lock);
    800025da:	8526                	mv	a0,s1
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	6aa080e7          	jalr	1706(ra) # 80000c86 <release>
			return 0;
    800025e4:	4501                	li	a0,0
}
    800025e6:	70a2                	ld	ra,40(sp)
    800025e8:	7402                	ld	s0,32(sp)
    800025ea:	64e2                	ld	s1,24(sp)
    800025ec:	6942                	ld	s2,16(sp)
    800025ee:	69a2                	ld	s3,8(sp)
    800025f0:	6145                	addi	sp,sp,48
    800025f2:	8082                	ret
				p->state = RUNNABLE;
    800025f4:	478d                	li	a5,3
    800025f6:	cc9c                	sw	a5,24(s1)
          queue_add(p, p->queue_no);
    800025f8:	1984a583          	lw	a1,408(s1)
    800025fc:	8526                	mv	a0,s1
    800025fe:	fffff097          	auipc	ra,0xfffff
    80002602:	504080e7          	jalr	1284(ra) # 80001b02 <queue_add>
    80002606:	bfd1                	j	800025da <kill+0x52>

0000000080002608 <setkilled>:

void setkilled(struct proc* p)
{
    80002608:	1101                	addi	sp,sp,-32
    8000260a:	ec06                	sd	ra,24(sp)
    8000260c:	e822                	sd	s0,16(sp)
    8000260e:	e426                	sd	s1,8(sp)
    80002610:	1000                	addi	s0,sp,32
    80002612:	84aa                	mv	s1,a0
	acquire(&p->lock);
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	5be080e7          	jalr	1470(ra) # 80000bd2 <acquire>
	p->killed = 1;
    8000261c:	4785                	li	a5,1
    8000261e:	d49c                	sw	a5,40(s1)
	release(&p->lock);
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	664080e7          	jalr	1636(ra) # 80000c86 <release>
}
    8000262a:	60e2                	ld	ra,24(sp)
    8000262c:	6442                	ld	s0,16(sp)
    8000262e:	64a2                	ld	s1,8(sp)
    80002630:	6105                	addi	sp,sp,32
    80002632:	8082                	ret

0000000080002634 <killed>:

int killed(struct proc* p)
{
    80002634:	1101                	addi	sp,sp,-32
    80002636:	ec06                	sd	ra,24(sp)
    80002638:	e822                	sd	s0,16(sp)
    8000263a:	e426                	sd	s1,8(sp)
    8000263c:	e04a                	sd	s2,0(sp)
    8000263e:	1000                	addi	s0,sp,32
    80002640:	84aa                	mv	s1,a0
	int k;

	acquire(&p->lock);
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	590080e7          	jalr	1424(ra) # 80000bd2 <acquire>
	k = p->killed;
    8000264a:	0284a903          	lw	s2,40(s1)
	release(&p->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	636080e7          	jalr	1590(ra) # 80000c86 <release>
	return k;
}
    80002658:	854a                	mv	a0,s2
    8000265a:	60e2                	ld	ra,24(sp)
    8000265c:	6442                	ld	s0,16(sp)
    8000265e:	64a2                	ld	s1,8(sp)
    80002660:	6902                	ld	s2,0(sp)
    80002662:	6105                	addi	sp,sp,32
    80002664:	8082                	ret

0000000080002666 <wait>:
{
    80002666:	715d                	addi	sp,sp,-80
    80002668:	e486                	sd	ra,72(sp)
    8000266a:	e0a2                	sd	s0,64(sp)
    8000266c:	fc26                	sd	s1,56(sp)
    8000266e:	f84a                	sd	s2,48(sp)
    80002670:	f44e                	sd	s3,40(sp)
    80002672:	f052                	sd	s4,32(sp)
    80002674:	ec56                	sd	s5,24(sp)
    80002676:	e85a                	sd	s6,16(sp)
    80002678:	e45e                	sd	s7,8(sp)
    8000267a:	e062                	sd	s8,0(sp)
    8000267c:	0880                	addi	s0,sp,80
    8000267e:	8b2a                	mv	s6,a0
	struct proc* p = myproc();
    80002680:	fffff097          	auipc	ra,0xfffff
    80002684:	356080e7          	jalr	854(ra) # 800019d6 <myproc>
    80002688:	892a                	mv	s2,a0
	acquire(&wait_lock);
    8000268a:	0000e517          	auipc	a0,0xe
    8000268e:	50e50513          	addi	a0,a0,1294 # 80010b98 <wait_lock>
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	540080e7          	jalr	1344(ra) # 80000bd2 <acquire>
		havekids = 0;
    8000269a:	4b81                	li	s7,0
				if(pp->state == ZOMBIE)
    8000269c:	4a15                	li	s4,5
				havekids = 1;
    8000269e:	4a85                	li	s5,1
		for(pp = proc; pp < &proc[NPROC]; pp++)
    800026a0:	00016997          	auipc	s3,0x16
    800026a4:	5b098993          	addi	s3,s3,1456 # 80018c50 <tickslock>
		sleep(p, &wait_lock); // DOC: wait-sleep
    800026a8:	0000ec17          	auipc	s8,0xe
    800026ac:	4f0c0c13          	addi	s8,s8,1264 # 80010b98 <wait_lock>
    800026b0:	a0d1                	j	80002774 <wait+0x10e>
					pid = pp->pid;
    800026b2:	0304a983          	lw	s3,48(s1)
					if(addr != 0 &&
    800026b6:	000b0e63          	beqz	s6,800026d2 <wait+0x6c>
					   copyout(p->pagetable, addr, (char*)&pp->xstate, sizeof(pp->xstate)) < 0)
    800026ba:	4691                	li	a3,4
    800026bc:	02c48613          	addi	a2,s1,44
    800026c0:	85da                	mv	a1,s6
    800026c2:	05093503          	ld	a0,80(s2)
    800026c6:	fffff097          	auipc	ra,0xfffff
    800026ca:	fa0080e7          	jalr	-96(ra) # 80001666 <copyout>
					if(addr != 0 &&
    800026ce:	04054163          	bltz	a0,80002710 <wait+0xaa>
					freeproc(pp);
    800026d2:	8526                	mv	a0,s1
    800026d4:	fffff097          	auipc	ra,0xfffff
    800026d8:	5c6080e7          	jalr	1478(ra) # 80001c9a <freeproc>
					release(&pp->lock);
    800026dc:	8526                	mv	a0,s1
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	5a8080e7          	jalr	1448(ra) # 80000c86 <release>
					release(&wait_lock);
    800026e6:	0000e517          	auipc	a0,0xe
    800026ea:	4b250513          	addi	a0,a0,1202 # 80010b98 <wait_lock>
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	598080e7          	jalr	1432(ra) # 80000c86 <release>
}
    800026f6:	854e                	mv	a0,s3
    800026f8:	60a6                	ld	ra,72(sp)
    800026fa:	6406                	ld	s0,64(sp)
    800026fc:	74e2                	ld	s1,56(sp)
    800026fe:	7942                	ld	s2,48(sp)
    80002700:	79a2                	ld	s3,40(sp)
    80002702:	7a02                	ld	s4,32(sp)
    80002704:	6ae2                	ld	s5,24(sp)
    80002706:	6b42                	ld	s6,16(sp)
    80002708:	6ba2                	ld	s7,8(sp)
    8000270a:	6c02                	ld	s8,0(sp)
    8000270c:	6161                	addi	sp,sp,80
    8000270e:	8082                	ret
						release(&pp->lock);
    80002710:	8526                	mv	a0,s1
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	574080e7          	jalr	1396(ra) # 80000c86 <release>
						release(&wait_lock);
    8000271a:	0000e517          	auipc	a0,0xe
    8000271e:	47e50513          	addi	a0,a0,1150 # 80010b98 <wait_lock>
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	564080e7          	jalr	1380(ra) # 80000c86 <release>
						return -1;
    8000272a:	59fd                	li	s3,-1
    8000272c:	b7e9                	j	800026f6 <wait+0x90>
		for(pp = proc; pp < &proc[NPROC]; pp++)
    8000272e:	1c048493          	addi	s1,s1,448
    80002732:	03348463          	beq	s1,s3,8000275a <wait+0xf4>
			if(pp->parent == p)
    80002736:	7c9c                	ld	a5,56(s1)
    80002738:	ff279be3          	bne	a5,s2,8000272e <wait+0xc8>
				acquire(&pp->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	494080e7          	jalr	1172(ra) # 80000bd2 <acquire>
				if(pp->state == ZOMBIE)
    80002746:	4c9c                	lw	a5,24(s1)
    80002748:	f74785e3          	beq	a5,s4,800026b2 <wait+0x4c>
				release(&pp->lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	538080e7          	jalr	1336(ra) # 80000c86 <release>
				havekids = 1;
    80002756:	8756                	mv	a4,s5
    80002758:	bfd9                	j	8000272e <wait+0xc8>
		if(!havekids || killed(p))
    8000275a:	c31d                	beqz	a4,80002780 <wait+0x11a>
    8000275c:	854a                	mv	a0,s2
    8000275e:	00000097          	auipc	ra,0x0
    80002762:	ed6080e7          	jalr	-298(ra) # 80002634 <killed>
    80002766:	ed09                	bnez	a0,80002780 <wait+0x11a>
		sleep(p, &wait_lock); // DOC: wait-sleep
    80002768:	85e2                	mv	a1,s8
    8000276a:	854a                	mv	a0,s2
    8000276c:	00000097          	auipc	ra,0x0
    80002770:	bf8080e7          	jalr	-1032(ra) # 80002364 <sleep>
		havekids = 0;
    80002774:	875e                	mv	a4,s7
		for(pp = proc; pp < &proc[NPROC]; pp++)
    80002776:	0000f497          	auipc	s1,0xf
    8000277a:	4da48493          	addi	s1,s1,1242 # 80011c50 <proc>
    8000277e:	bf65                	j	80002736 <wait+0xd0>
			release(&wait_lock);
    80002780:	0000e517          	auipc	a0,0xe
    80002784:	41850513          	addi	a0,a0,1048 # 80010b98 <wait_lock>
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	4fe080e7          	jalr	1278(ra) # 80000c86 <release>
			return -1;
    80002790:	59fd                	li	s3,-1
    80002792:	b795                	j	800026f6 <wait+0x90>

0000000080002794 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void* src, uint64 len)
{
    80002794:	7179                	addi	sp,sp,-48
    80002796:	f406                	sd	ra,40(sp)
    80002798:	f022                	sd	s0,32(sp)
    8000279a:	ec26                	sd	s1,24(sp)
    8000279c:	e84a                	sd	s2,16(sp)
    8000279e:	e44e                	sd	s3,8(sp)
    800027a0:	e052                	sd	s4,0(sp)
    800027a2:	1800                	addi	s0,sp,48
    800027a4:	84aa                	mv	s1,a0
    800027a6:	892e                	mv	s2,a1
    800027a8:	89b2                	mv	s3,a2
    800027aa:	8a36                	mv	s4,a3
	struct proc* p = myproc();
    800027ac:	fffff097          	auipc	ra,0xfffff
    800027b0:	22a080e7          	jalr	554(ra) # 800019d6 <myproc>
	if(user_dst)
    800027b4:	c08d                	beqz	s1,800027d6 <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    800027b6:	86d2                	mv	a3,s4
    800027b8:	864e                	mv	a2,s3
    800027ba:	85ca                	mv	a1,s2
    800027bc:	6928                	ld	a0,80(a0)
    800027be:	fffff097          	auipc	ra,0xfffff
    800027c2:	ea8080e7          	jalr	-344(ra) # 80001666 <copyout>
	else
	{
		memmove((char*)dst, src, len);
		return 0;
	}
}
    800027c6:	70a2                	ld	ra,40(sp)
    800027c8:	7402                	ld	s0,32(sp)
    800027ca:	64e2                	ld	s1,24(sp)
    800027cc:	6942                	ld	s2,16(sp)
    800027ce:	69a2                	ld	s3,8(sp)
    800027d0:	6a02                	ld	s4,0(sp)
    800027d2:	6145                	addi	sp,sp,48
    800027d4:	8082                	ret
		memmove((char*)dst, src, len);
    800027d6:	000a061b          	sext.w	a2,s4
    800027da:	85ce                	mv	a1,s3
    800027dc:	854a                	mv	a0,s2
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	54c080e7          	jalr	1356(ra) # 80000d2a <memmove>
		return 0;
    800027e6:	8526                	mv	a0,s1
    800027e8:	bff9                	j	800027c6 <either_copyout+0x32>

00000000800027ea <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void* dst, int user_src, uint64 src, uint64 len)
{
    800027ea:	7179                	addi	sp,sp,-48
    800027ec:	f406                	sd	ra,40(sp)
    800027ee:	f022                	sd	s0,32(sp)
    800027f0:	ec26                	sd	s1,24(sp)
    800027f2:	e84a                	sd	s2,16(sp)
    800027f4:	e44e                	sd	s3,8(sp)
    800027f6:	e052                	sd	s4,0(sp)
    800027f8:	1800                	addi	s0,sp,48
    800027fa:	892a                	mv	s2,a0
    800027fc:	84ae                	mv	s1,a1
    800027fe:	89b2                	mv	s3,a2
    80002800:	8a36                	mv	s4,a3
	struct proc* p = myproc();
    80002802:	fffff097          	auipc	ra,0xfffff
    80002806:	1d4080e7          	jalr	468(ra) # 800019d6 <myproc>
	if(user_src)
    8000280a:	c08d                	beqz	s1,8000282c <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    8000280c:	86d2                	mv	a3,s4
    8000280e:	864e                	mv	a2,s3
    80002810:	85ca                	mv	a1,s2
    80002812:	6928                	ld	a0,80(a0)
    80002814:	fffff097          	auipc	ra,0xfffff
    80002818:	ede080e7          	jalr	-290(ra) # 800016f2 <copyin>
	else
	{
		memmove(dst, (char*)src, len);
		return 0;
	}
}
    8000281c:	70a2                	ld	ra,40(sp)
    8000281e:	7402                	ld	s0,32(sp)
    80002820:	64e2                	ld	s1,24(sp)
    80002822:	6942                	ld	s2,16(sp)
    80002824:	69a2                	ld	s3,8(sp)
    80002826:	6a02                	ld	s4,0(sp)
    80002828:	6145                	addi	sp,sp,48
    8000282a:	8082                	ret
		memmove(dst, (char*)src, len);
    8000282c:	000a061b          	sext.w	a2,s4
    80002830:	85ce                	mv	a1,s3
    80002832:	854a                	mv	a0,s2
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	4f6080e7          	jalr	1270(ra) # 80000d2a <memmove>
		return 0;
    8000283c:	8526                	mv	a0,s1
    8000283e:	bff9                	j	8000281c <either_copyin+0x32>

0000000080002840 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002840:	711d                	addi	sp,sp,-96
    80002842:	ec86                	sd	ra,88(sp)
    80002844:	e8a2                	sd	s0,80(sp)
    80002846:	e4a6                	sd	s1,72(sp)
    80002848:	e0ca                	sd	s2,64(sp)
    8000284a:	fc4e                	sd	s3,56(sp)
    8000284c:	f852                	sd	s4,48(sp)
    8000284e:	f456                	sd	s5,40(sp)
    80002850:	f05a                	sd	s6,32(sp)
    80002852:	ec5e                	sd	s7,24(sp)
    80002854:	e862                	sd	s8,16(sp)
    80002856:	e466                	sd	s9,8(sp)
    80002858:	e06a                	sd	s10,0(sp)
    8000285a:	1080                	addi	s0,sp,96
							 [RUNNING] "run   ",
							 [ZOMBIE] "zombie"};
	struct proc* p;
	char* state;

	printf("\n");
    8000285c:	00006517          	auipc	a0,0x6
    80002860:	86c50513          	addi	a0,a0,-1940 # 800080c8 <digits+0x88>
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	d22080e7          	jalr	-734(ra) # 80000586 <printf>
	for(p = proc; p < &proc[NPROC]; p++)
    8000286c:	0000f497          	auipc	s1,0xf
    80002870:	3e448493          	addi	s1,s1,996 # 80011c50 <proc>
	{
		if(p->state == UNUSED)
			continue;
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002874:	4c15                	li	s8,5
			state = states[p->state];
		else
			state = "???";
    80002876:	00006997          	auipc	s3,0x6
    8000287a:	a0a98993          	addi	s3,s3,-1526 # 80008280 <digits+0x240>
		#ifdef MLFQ
		printf("\tq0\tq1\tq2\tq3\tq4");
    8000287e:	00006b97          	auipc	s7,0x6
    80002882:	a0ab8b93          	addi	s7,s7,-1526 # 80008288 <digits+0x248>
		#endif
		 printf("%d\t", p->pid);
    80002886:	00006b17          	auipc	s6,0x6
    8000288a:	a12b0b13          	addi	s6,s6,-1518 # 80008298 <digits+0x258>
      int priority=p->curr_queue;
      if(p->state==ZOMBIE)
        priority = -1;
      printf("%d\t\t", priority);
    #endif
	printf("%s\t", state);
    8000288e:	00006a97          	auipc	s5,0x6
    80002892:	a12a8a93          	addi	s5,s5,-1518 # 800082a0 <digits+0x260>
	 #if SCHEDULER==3
    for(int x=0;x<NUM_OF_QUEUES;x++)
    printf("%d\t", p->time_spent_queues[x]);
    #endif
		// printf("%d %s %s", p->pid, state, p->name);
		printf("\n");
    80002896:	00006a17          	auipc	s4,0x6
    8000289a:	832a0a13          	addi	s4,s4,-1998 # 800080c8 <digits+0x88>
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000289e:	00006c97          	auipc	s9,0x6
    800028a2:	a3ac8c93          	addi	s9,s9,-1478 # 800082d8 <states.0>
	for(p = proc; p < &proc[NPROC]; p++)
    800028a6:	00016917          	auipc	s2,0x16
    800028aa:	3aa90913          	addi	s2,s2,938 # 80018c50 <tickslock>
    800028ae:	a81d                	j	800028e4 <procdump+0xa4>
		printf("\tq0\tq1\tq2\tq3\tq4");
    800028b0:	855e                	mv	a0,s7
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	cd4080e7          	jalr	-812(ra) # 80000586 <printf>
		 printf("%d\t", p->pid);
    800028ba:	588c                	lw	a1,48(s1)
    800028bc:	855a                	mv	a0,s6
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	cc8080e7          	jalr	-824(ra) # 80000586 <printf>
	printf("%s\t", state);
    800028c6:	85ea                	mv	a1,s10
    800028c8:	8556                	mv	a0,s5
    800028ca:	ffffe097          	auipc	ra,0xffffe
    800028ce:	cbc080e7          	jalr	-836(ra) # 80000586 <printf>
		printf("\n");
    800028d2:	8552                	mv	a0,s4
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	cb2080e7          	jalr	-846(ra) # 80000586 <printf>
	for(p = proc; p < &proc[NPROC]; p++)
    800028dc:	1c048493          	addi	s1,s1,448
    800028e0:	03248263          	beq	s1,s2,80002904 <procdump+0xc4>
		if(p->state == UNUSED)
    800028e4:	4c9c                	lw	a5,24(s1)
    800028e6:	dbfd                	beqz	a5,800028dc <procdump+0x9c>
			state = "???";
    800028e8:	8d4e                	mv	s10,s3
		if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ea:	fcfc63e3          	bltu	s8,a5,800028b0 <procdump+0x70>
    800028ee:	02079713          	slli	a4,a5,0x20
    800028f2:	01d75793          	srli	a5,a4,0x1d
    800028f6:	97e6                	add	a5,a5,s9
    800028f8:	0007bd03          	ld	s10,0(a5)
    800028fc:	fa0d1ae3          	bnez	s10,800028b0 <procdump+0x70>
			state = "???";
    80002900:	8d4e                	mv	s10,s3
    80002902:	b77d                	j	800028b0 <procdump+0x70>
	}	
}
    80002904:	60e6                	ld	ra,88(sp)
    80002906:	6446                	ld	s0,80(sp)
    80002908:	64a6                	ld	s1,72(sp)
    8000290a:	6906                	ld	s2,64(sp)
    8000290c:	79e2                	ld	s3,56(sp)
    8000290e:	7a42                	ld	s4,48(sp)
    80002910:	7aa2                	ld	s5,40(sp)
    80002912:	7b02                	ld	s6,32(sp)
    80002914:	6be2                	ld	s7,24(sp)
    80002916:	6c42                	ld	s8,16(sp)
    80002918:	6ca2                	ld	s9,8(sp)
    8000291a:	6d02                	ld	s10,0(sp)
    8000291c:	6125                	addi	sp,sp,96
    8000291e:	8082                	ret

0000000080002920 <waitx>:

// waitx
int waitx(uint64 addr, uint* wtime, uint* rtime)
{
    80002920:	711d                	addi	sp,sp,-96
    80002922:	ec86                	sd	ra,88(sp)
    80002924:	e8a2                	sd	s0,80(sp)
    80002926:	e4a6                	sd	s1,72(sp)
    80002928:	e0ca                	sd	s2,64(sp)
    8000292a:	fc4e                	sd	s3,56(sp)
    8000292c:	f852                	sd	s4,48(sp)
    8000292e:	f456                	sd	s5,40(sp)
    80002930:	f05a                	sd	s6,32(sp)
    80002932:	ec5e                	sd	s7,24(sp)
    80002934:	e862                	sd	s8,16(sp)
    80002936:	e466                	sd	s9,8(sp)
    80002938:	e06a                	sd	s10,0(sp)
    8000293a:	1080                	addi	s0,sp,96
    8000293c:	8b2a                	mv	s6,a0
    8000293e:	8bae                	mv	s7,a1
    80002940:	8c32                	mv	s8,a2
	struct proc* np;
	int havekids, pid;
	struct proc* p = myproc();
    80002942:	fffff097          	auipc	ra,0xfffff
    80002946:	094080e7          	jalr	148(ra) # 800019d6 <myproc>
    8000294a:	892a                	mv	s2,a0

	acquire(&wait_lock);
    8000294c:	0000e517          	auipc	a0,0xe
    80002950:	24c50513          	addi	a0,a0,588 # 80010b98 <wait_lock>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	27e080e7          	jalr	638(ra) # 80000bd2 <acquire>

	for(;;)
	{
		// Scan through table looking for exited children.
		havekids = 0;
    8000295c:	4c81                	li	s9,0
			{
				// make sure the child isn't still in exit() or swtch().
				acquire(&np->lock);

				havekids = 1;
				if(np->state == ZOMBIE)
    8000295e:	4a15                	li	s4,5
				havekids = 1;
    80002960:	4a85                	li	s5,1
		for(np = proc; np < &proc[NPROC]; np++)
    80002962:	00016997          	auipc	s3,0x16
    80002966:	2ee98993          	addi	s3,s3,750 # 80018c50 <tickslock>
			release(&wait_lock);
			return -1;
		}

		// Wait for a child to exit.
		sleep(p, &wait_lock); // DOC: wait-sleep
    8000296a:	0000ed17          	auipc	s10,0xe
    8000296e:	22ed0d13          	addi	s10,s10,558 # 80010b98 <wait_lock>
    80002972:	a8e9                	j	80002a4c <waitx+0x12c>
					pid = np->pid;
    80002974:	0304a983          	lw	s3,48(s1)
					*rtime = np->rtime;
    80002978:	1684a783          	lw	a5,360(s1)
    8000297c:	00fc2023          	sw	a5,0(s8)
					*wtime = np->etime - np->ctime - np->rtime;
    80002980:	16c4a703          	lw	a4,364(s1)
    80002984:	9f3d                	addw	a4,a4,a5
    80002986:	1704a783          	lw	a5,368(s1)
    8000298a:	9f99                	subw	a5,a5,a4
    8000298c:	00fba023          	sw	a5,0(s7)
					if(addr != 0 &&
    80002990:	000b0e63          	beqz	s6,800029ac <waitx+0x8c>
					   copyout(p->pagetable, addr, (char*)&np->xstate, sizeof(np->xstate)) < 0)
    80002994:	4691                	li	a3,4
    80002996:	02c48613          	addi	a2,s1,44
    8000299a:	85da                	mv	a1,s6
    8000299c:	05093503          	ld	a0,80(s2)
    800029a0:	fffff097          	auipc	ra,0xfffff
    800029a4:	cc6080e7          	jalr	-826(ra) # 80001666 <copyout>
					if(addr != 0 &&
    800029a8:	04054363          	bltz	a0,800029ee <waitx+0xce>
					freeproc(np);
    800029ac:	8526                	mv	a0,s1
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	2ec080e7          	jalr	748(ra) # 80001c9a <freeproc>
					release(&np->lock);
    800029b6:	8526                	mv	a0,s1
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	2ce080e7          	jalr	718(ra) # 80000c86 <release>
					release(&wait_lock);
    800029c0:	0000e517          	auipc	a0,0xe
    800029c4:	1d850513          	addi	a0,a0,472 # 80010b98 <wait_lock>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	2be080e7          	jalr	702(ra) # 80000c86 <release>
	}
}
    800029d0:	854e                	mv	a0,s3
    800029d2:	60e6                	ld	ra,88(sp)
    800029d4:	6446                	ld	s0,80(sp)
    800029d6:	64a6                	ld	s1,72(sp)
    800029d8:	6906                	ld	s2,64(sp)
    800029da:	79e2                	ld	s3,56(sp)
    800029dc:	7a42                	ld	s4,48(sp)
    800029de:	7aa2                	ld	s5,40(sp)
    800029e0:	7b02                	ld	s6,32(sp)
    800029e2:	6be2                	ld	s7,24(sp)
    800029e4:	6c42                	ld	s8,16(sp)
    800029e6:	6ca2                	ld	s9,8(sp)
    800029e8:	6d02                	ld	s10,0(sp)
    800029ea:	6125                	addi	sp,sp,96
    800029ec:	8082                	ret
						release(&np->lock);
    800029ee:	8526                	mv	a0,s1
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	296080e7          	jalr	662(ra) # 80000c86 <release>
						release(&wait_lock);
    800029f8:	0000e517          	auipc	a0,0xe
    800029fc:	1a050513          	addi	a0,a0,416 # 80010b98 <wait_lock>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	286080e7          	jalr	646(ra) # 80000c86 <release>
						return -1;
    80002a08:	59fd                	li	s3,-1
    80002a0a:	b7d9                	j	800029d0 <waitx+0xb0>
		for(np = proc; np < &proc[NPROC]; np++)
    80002a0c:	1c048493          	addi	s1,s1,448
    80002a10:	03348463          	beq	s1,s3,80002a38 <waitx+0x118>
			if(np->parent == p)
    80002a14:	7c9c                	ld	a5,56(s1)
    80002a16:	ff279be3          	bne	a5,s2,80002a0c <waitx+0xec>
				acquire(&np->lock);
    80002a1a:	8526                	mv	a0,s1
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	1b6080e7          	jalr	438(ra) # 80000bd2 <acquire>
				if(np->state == ZOMBIE)
    80002a24:	4c9c                	lw	a5,24(s1)
    80002a26:	f54787e3          	beq	a5,s4,80002974 <waitx+0x54>
				release(&np->lock);
    80002a2a:	8526                	mv	a0,s1
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	25a080e7          	jalr	602(ra) # 80000c86 <release>
				havekids = 1;
    80002a34:	8756                	mv	a4,s5
    80002a36:	bfd9                	j	80002a0c <waitx+0xec>
		if(!havekids || p->killed)
    80002a38:	c305                	beqz	a4,80002a58 <waitx+0x138>
    80002a3a:	02892783          	lw	a5,40(s2)
    80002a3e:	ef89                	bnez	a5,80002a58 <waitx+0x138>
		sleep(p, &wait_lock); // DOC: wait-sleep
    80002a40:	85ea                	mv	a1,s10
    80002a42:	854a                	mv	a0,s2
    80002a44:	00000097          	auipc	ra,0x0
    80002a48:	920080e7          	jalr	-1760(ra) # 80002364 <sleep>
		havekids = 0;
    80002a4c:	8766                	mv	a4,s9
		for(np = proc; np < &proc[NPROC]; np++)
    80002a4e:	0000f497          	auipc	s1,0xf
    80002a52:	20248493          	addi	s1,s1,514 # 80011c50 <proc>
    80002a56:	bf7d                	j	80002a14 <waitx+0xf4>
			release(&wait_lock);
    80002a58:	0000e517          	auipc	a0,0xe
    80002a5c:	14050513          	addi	a0,a0,320 # 80010b98 <wait_lock>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	226080e7          	jalr	550(ra) # 80000c86 <release>
			return -1;
    80002a68:	59fd                	li	s3,-1
    80002a6a:	b79d                	j	800029d0 <waitx+0xb0>

0000000080002a6c <update_time>:

void update_time()
{
    80002a6c:	7179                	addi	sp,sp,-48
    80002a6e:	f406                	sd	ra,40(sp)
    80002a70:	f022                	sd	s0,32(sp)
    80002a72:	ec26                	sd	s1,24(sp)
    80002a74:	e84a                	sd	s2,16(sp)
    80002a76:	e44e                	sd	s3,8(sp)
    80002a78:	1800                	addi	s0,sp,48
	struct proc* p;
	for(p = proc; p < &proc[NPROC]; p++)
    80002a7a:	0000f497          	auipc	s1,0xf
    80002a7e:	1d648493          	addi	s1,s1,470 # 80011c50 <proc>
	{
		acquire(&p->lock);
		if(p->state == RUNNING)
    80002a82:	4991                	li	s3,4
	for(p = proc; p < &proc[NPROC]; p++)
    80002a84:	00016917          	auipc	s2,0x16
    80002a88:	1cc90913          	addi	s2,s2,460 # 80018c50 <tickslock>
    80002a8c:	a811                	j	80002aa0 <update_time+0x34>
		{
			p->rtime++;
		}
		 	release(&p->lock);
    80002a8e:	8526                	mv	a0,s1
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	1f6080e7          	jalr	502(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    80002a98:	1c048493          	addi	s1,s1,448
    80002a9c:	03248063          	beq	s1,s2,80002abc <update_time+0x50>
		acquire(&p->lock);
    80002aa0:	8526                	mv	a0,s1
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	130080e7          	jalr	304(ra) # 80000bd2 <acquire>
		if(p->state == RUNNING)
    80002aaa:	4c9c                	lw	a5,24(s1)
    80002aac:	ff3791e3          	bne	a5,s3,80002a8e <update_time+0x22>
			p->rtime++;
    80002ab0:	1684a783          	lw	a5,360(s1)
    80002ab4:	2785                	addiw	a5,a5,1
    80002ab6:	16f4a423          	sw	a5,360(s1)
    80002aba:	bfd1                	j	80002a8e <update_time+0x22>
	}
	
}
    80002abc:	70a2                	ld	ra,40(sp)
    80002abe:	7402                	ld	s0,32(sp)
    80002ac0:	64e2                	ld	s1,24(sp)
    80002ac2:	6942                	ld	s2,16(sp)
    80002ac4:	69a2                	ld	s3,8(sp)
    80002ac6:	6145                	addi	sp,sp,48
    80002ac8:	8082                	ret

0000000080002aca <set_overshot_proc>:

void set_overshot_proc()
{
    80002aca:	1101                	addi	sp,sp,-32
    80002acc:	ec06                	sd	ra,24(sp)
    80002ace:	e822                	sd	s0,16(sp)
    80002ad0:	e426                	sd	s1,8(sp)
    80002ad2:	1000                	addi	s0,sp,32
	struct proc* p = myproc();
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	f02080e7          	jalr	-254(ra) # 800019d6 <myproc>
    80002adc:	84aa                	mv	s1,a0
	
		acquire(&p->lock);
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	0f4080e7          	jalr	244(ra) # 80000bd2 <acquire>
		
			p->q_leap = 1;
    80002ae6:	4785                	li	a5,1
    80002ae8:	1af4ac23          	sw	a5,440(s1)
	p->q_run_time = 0;
    80002aec:	1a04aa23          	sw	zero,436(s1)
	p->q_wait_time = 0;
    80002af0:	1a04a823          	sw	zero,432(s1)
		release(&p->lock);
    80002af4:	8526                	mv	a0,s1
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	190080e7          	jalr	400(ra) # 80000c86 <release>
	
}
    80002afe:	60e2                	ld	ra,24(sp)
    80002b00:	6442                	ld	s0,16(sp)
    80002b02:	64a2                	ld	s1,8(sp)
    80002b04:	6105                	addi	sp,sp,32
    80002b06:	8082                	ret

0000000080002b08 <update_q_wtime>:

void update_q_wtime()
{
    80002b08:	7139                	addi	sp,sp,-64
    80002b0a:	fc06                	sd	ra,56(sp)
    80002b0c:	f822                	sd	s0,48(sp)
    80002b0e:	f426                	sd	s1,40(sp)
    80002b10:	f04a                	sd	s2,32(sp)
    80002b12:	ec4e                	sd	s3,24(sp)
    80002b14:	e852                	sd	s4,16(sp)
    80002b16:	e456                	sd	s5,8(sp)
    80002b18:	0080                	addi	s0,sp,64
	struct proc* p;
	for(p = proc; p < &proc[NPROC]; p++)
    80002b1a:	0000f497          	auipc	s1,0xf
    80002b1e:	13648493          	addi	s1,s1,310 # 80011c50 <proc>
	{
		acquire(&p->lock);
		if (p->state == RUNNING)
    80002b22:	4991                	li	s3,4
		{
			p->q_run_time++;
		}
		else  if(p->state == RUNNABLE)
    80002b24:	4a0d                	li	s4,3
		{
			p->q_wait_time++;
		}
		 if (p->state != ZOMBIE)
    80002b26:	4a95                	li	s5,5
	for(p = proc; p < &proc[NPROC]; p++)
    80002b28:	00016917          	auipc	s2,0x16
    80002b2c:	12890913          	addi	s2,s2,296 # 80018c50 <tickslock>
    80002b30:	a805                	j	80002b60 <update_q_wtime+0x58>
			p->q_run_time++;
    80002b32:	1b44a783          	lw	a5,436(s1)
    80002b36:	2785                	addiw	a5,a5,1
    80002b38:	1af4aa23          	sw	a5,436(s1)
		 {
			 p->time_spent[p->queue_no]++;
    80002b3c:	1984a783          	lw	a5,408(s1)
    80002b40:	078a                	slli	a5,a5,0x2
    80002b42:	97a6                	add	a5,a5,s1
    80002b44:	19c7a703          	lw	a4,412(a5)
    80002b48:	2705                	addiw	a4,a4,1
    80002b4a:	18e7ae23          	sw	a4,412(a5)
		 }
		release(&p->lock);
    80002b4e:	8526                	mv	a0,s1
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	136080e7          	jalr	310(ra) # 80000c86 <release>
	for(p = proc; p < &proc[NPROC]; p++)
    80002b58:	1c048493          	addi	s1,s1,448
    80002b5c:	03248563          	beq	s1,s2,80002b86 <update_q_wtime+0x7e>
		acquire(&p->lock);
    80002b60:	8526                	mv	a0,s1
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	070080e7          	jalr	112(ra) # 80000bd2 <acquire>
		if (p->state == RUNNING)
    80002b6a:	4c9c                	lw	a5,24(s1)
    80002b6c:	fd3783e3          	beq	a5,s3,80002b32 <update_q_wtime+0x2a>
		else  if(p->state == RUNNABLE)
    80002b70:	01478563          	beq	a5,s4,80002b7a <update_q_wtime+0x72>
		 if (p->state != ZOMBIE)
    80002b74:	fd578de3          	beq	a5,s5,80002b4e <update_q_wtime+0x46>
    80002b78:	b7d1                	j	80002b3c <update_q_wtime+0x34>
			p->q_wait_time++;
    80002b7a:	1b04a783          	lw	a5,432(s1)
    80002b7e:	2785                	addiw	a5,a5,1
    80002b80:	1af4a823          	sw	a5,432(s1)
    80002b84:	bf65                	j	80002b3c <update_q_wtime+0x34>
	}
    80002b86:	70e2                	ld	ra,56(sp)
    80002b88:	7442                	ld	s0,48(sp)
    80002b8a:	74a2                	ld	s1,40(sp)
    80002b8c:	7902                	ld	s2,32(sp)
    80002b8e:	69e2                	ld	s3,24(sp)
    80002b90:	6a42                	ld	s4,16(sp)
    80002b92:	6aa2                	ld	s5,8(sp)
    80002b94:	6121                	addi	sp,sp,64
    80002b96:	8082                	ret

0000000080002b98 <swtch>:
    80002b98:	00153023          	sd	ra,0(a0)
    80002b9c:	00253423          	sd	sp,8(a0)
    80002ba0:	e900                	sd	s0,16(a0)
    80002ba2:	ed04                	sd	s1,24(a0)
    80002ba4:	03253023          	sd	s2,32(a0)
    80002ba8:	03353423          	sd	s3,40(a0)
    80002bac:	03453823          	sd	s4,48(a0)
    80002bb0:	03553c23          	sd	s5,56(a0)
    80002bb4:	05653023          	sd	s6,64(a0)
    80002bb8:	05753423          	sd	s7,72(a0)
    80002bbc:	05853823          	sd	s8,80(a0)
    80002bc0:	05953c23          	sd	s9,88(a0)
    80002bc4:	07a53023          	sd	s10,96(a0)
    80002bc8:	07b53423          	sd	s11,104(a0)
    80002bcc:	0005b083          	ld	ra,0(a1)
    80002bd0:	0085b103          	ld	sp,8(a1)
    80002bd4:	6980                	ld	s0,16(a1)
    80002bd6:	6d84                	ld	s1,24(a1)
    80002bd8:	0205b903          	ld	s2,32(a1)
    80002bdc:	0285b983          	ld	s3,40(a1)
    80002be0:	0305ba03          	ld	s4,48(a1)
    80002be4:	0385ba83          	ld	s5,56(a1)
    80002be8:	0405bb03          	ld	s6,64(a1)
    80002bec:	0485bb83          	ld	s7,72(a1)
    80002bf0:	0505bc03          	ld	s8,80(a1)
    80002bf4:	0585bc83          	ld	s9,88(a1)
    80002bf8:	0605bd03          	ld	s10,96(a1)
    80002bfc:	0685bd83          	ld	s11,104(a1)
    80002c00:	8082                	ret

0000000080002c02 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002c02:	1141                	addi	sp,sp,-16
    80002c04:	e406                	sd	ra,8(sp)
    80002c06:	e022                	sd	s0,0(sp)
    80002c08:	0800                	addi	s0,sp,16
	initlock(&tickslock, "time");
    80002c0a:	00005597          	auipc	a1,0x5
    80002c0e:	6fe58593          	addi	a1,a1,1790 # 80008308 <states.0+0x30>
    80002c12:	00016517          	auipc	a0,0x16
    80002c16:	03e50513          	addi	a0,a0,62 # 80018c50 <tickslock>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	f28080e7          	jalr	-216(ra) # 80000b42 <initlock>
}
    80002c22:	60a2                	ld	ra,8(sp)
    80002c24:	6402                	ld	s0,0(sp)
    80002c26:	0141                	addi	sp,sp,16
    80002c28:	8082                	ret

0000000080002c2a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002c2a:	1141                	addi	sp,sp,-16
    80002c2c:	e422                	sd	s0,8(sp)
    80002c2e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c30:	00003797          	auipc	a5,0x3
    80002c34:	6b078793          	addi	a5,a5,1712 # 800062e0 <kernelvec>
    80002c38:	10579073          	csrw	stvec,a5
	w_stvec((uint64)kernelvec);
}
    80002c3c:	6422                	ld	s0,8(sp)
    80002c3e:	0141                	addi	sp,sp,16
    80002c40:	8082                	ret

0000000080002c42 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002c42:	1141                	addi	sp,sp,-16
    80002c44:	e406                	sd	ra,8(sp)
    80002c46:	e022                	sd	s0,0(sp)
    80002c48:	0800                	addi	s0,sp,16
	struct proc *p = myproc();
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	d8c080e7          	jalr	-628(ra) # 800019d6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c56:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c58:	10079073          	csrw	sstatus,a5
	// kerneltrap() to usertrap(), so turn off interrupts until
	// we're back in user space, where usertrap() is correct.
	intr_off();

	// send syscalls, interrupts, and exceptions to uservec in trampoline.S
	uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c5c:	00004697          	auipc	a3,0x4
    80002c60:	3a468693          	addi	a3,a3,932 # 80007000 <_trampoline>
    80002c64:	00004717          	auipc	a4,0x4
    80002c68:	39c70713          	addi	a4,a4,924 # 80007000 <_trampoline>
    80002c6c:	8f15                	sub	a4,a4,a3
    80002c6e:	040007b7          	lui	a5,0x4000
    80002c72:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002c74:	07b2                	slli	a5,a5,0xc
    80002c76:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c78:	10571073          	csrw	stvec,a4
	w_stvec(trampoline_uservec);

	// set up trapframe values that uservec will need when
	// the process next traps into the kernel.
	p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c7c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c7e:	18002673          	csrr	a2,satp
    80002c82:	e310                	sd	a2,0(a4)
	p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c84:	6d30                	ld	a2,88(a0)
    80002c86:	6138                	ld	a4,64(a0)
    80002c88:	6585                	lui	a1,0x1
    80002c8a:	972e                	add	a4,a4,a1
    80002c8c:	e618                	sd	a4,8(a2)
	p->trapframe->kernel_trap = (uint64)usertrap;
    80002c8e:	6d38                	ld	a4,88(a0)
    80002c90:	00000617          	auipc	a2,0x0
    80002c94:	14a60613          	addi	a2,a2,330 # 80002dda <usertrap>
    80002c98:	eb10                	sd	a2,16(a4)
	p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002c9a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c9c:	8612                	mv	a2,tp
    80002c9e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca0:	10002773          	csrr	a4,sstatus
	// set up the registers that trampoline.S's sret will use
	// to get to user space.

	// set S Previous Privilege mode to User.
	unsigned long x = r_sstatus();
	x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ca4:	eff77713          	andi	a4,a4,-257
	x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ca8:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cac:	10071073          	csrw	sstatus,a4
	w_sstatus(x);

	// set S Exception Program Counter to the saved user pc.
	w_sepc(p->trapframe->epc);
    80002cb0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cb2:	6f18                	ld	a4,24(a4)
    80002cb4:	14171073          	csrw	sepc,a4

	// tell trampoline.S the user page table to switch to.
	uint64 satp = MAKE_SATP(p->pagetable);
    80002cb8:	6928                	ld	a0,80(a0)
    80002cba:	8131                	srli	a0,a0,0xc

	// jump to userret in trampoline.S at the top of memory, which
	// switches to the user page table, restores user registers,
	// and switches to user mode with sret.
	uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002cbc:	00004717          	auipc	a4,0x4
    80002cc0:	3e070713          	addi	a4,a4,992 # 8000709c <userret>
    80002cc4:	8f15                	sub	a4,a4,a3
    80002cc6:	97ba                	add	a5,a5,a4
	((void (*)(uint64))trampoline_userret)(satp);
    80002cc8:	577d                	li	a4,-1
    80002cca:	177e                	slli	a4,a4,0x3f
    80002ccc:	8d59                	or	a0,a0,a4
    80002cce:	9782                	jalr	a5
}
    80002cd0:	60a2                	ld	ra,8(sp)
    80002cd2:	6402                	ld	s0,0(sp)
    80002cd4:	0141                	addi	sp,sp,16
    80002cd6:	8082                	ret

0000000080002cd8 <clockintr>:
	w_sepc(sepc);
	w_sstatus(sstatus);
}

void clockintr()
{
    80002cd8:	1101                	addi	sp,sp,-32
    80002cda:	ec06                	sd	ra,24(sp)
    80002cdc:	e822                	sd	s0,16(sp)
    80002cde:	e426                	sd	s1,8(sp)
    80002ce0:	e04a                	sd	s2,0(sp)
    80002ce2:	1000                	addi	s0,sp,32
	

	acquire(&tickslock);
    80002ce4:	00016917          	auipc	s2,0x16
    80002ce8:	f6c90913          	addi	s2,s2,-148 # 80018c50 <tickslock>
    80002cec:	854a                	mv	a0,s2
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	ee4080e7          	jalr	-284(ra) # 80000bd2 <acquire>
	ticks++;
    80002cf6:	00006497          	auipc	s1,0x6
    80002cfa:	c1a48493          	addi	s1,s1,-998 # 80008910 <ticks>
    80002cfe:	409c                	lw	a5,0(s1)
    80002d00:	2785                	addiw	a5,a5,1
    80002d02:	c09c                	sw	a5,0(s1)
	update_time();
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	d68080e7          	jalr	-664(ra) # 80002a6c <update_time>
	#ifdef MLFQ
	update_q_wtime();
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	dfc080e7          	jalr	-516(ra) # 80002b08 <update_q_wtime>
	//   // {
	//   //   p->wtime++;
	//   // }
	//   release(&p->lock);
	// }
	wakeup(&ticks);
    80002d14:	8526                	mv	a0,s1
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	6b2080e7          	jalr	1714(ra) # 800023c8 <wakeup>
	// procdump();
	release(&tickslock);
    80002d1e:	854a                	mv	a0,s2
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	f66080e7          	jalr	-154(ra) # 80000c86 <release>
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6902                	ld	s2,0(sp)
    80002d30:	6105                	addi	sp,sp,32
    80002d32:	8082                	ret

0000000080002d34 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d34:	142027f3          	csrr	a5,scause

		return 2;
	}
	else
	{
		return 0;
    80002d38:	4501                	li	a0,0
	if ((scause & 0x8000000000000000L) &&
    80002d3a:	0807df63          	bgez	a5,80002dd8 <devintr+0xa4>
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    80002d48:	0ff7f713          	zext.b	a4,a5
	if ((scause & 0x8000000000000000L) &&
    80002d4c:	46a5                	li	a3,9
    80002d4e:	00d70d63          	beq	a4,a3,80002d68 <devintr+0x34>
	else if (scause == 0x8000000000000001L)
    80002d52:	577d                	li	a4,-1
    80002d54:	177e                	slli	a4,a4,0x3f
    80002d56:	0705                	addi	a4,a4,1
		return 0;
    80002d58:	4501                	li	a0,0
	else if (scause == 0x8000000000000001L)
    80002d5a:	04e78e63          	beq	a5,a4,80002db6 <devintr+0x82>
	}
}
    80002d5e:	60e2                	ld	ra,24(sp)
    80002d60:	6442                	ld	s0,16(sp)
    80002d62:	64a2                	ld	s1,8(sp)
    80002d64:	6105                	addi	sp,sp,32
    80002d66:	8082                	ret
		int irq = plic_claim();
    80002d68:	00003097          	auipc	ra,0x3
    80002d6c:	680080e7          	jalr	1664(ra) # 800063e8 <plic_claim>
    80002d70:	84aa                	mv	s1,a0
		if (irq == UART0_IRQ)
    80002d72:	47a9                	li	a5,10
    80002d74:	02f50763          	beq	a0,a5,80002da2 <devintr+0x6e>
		else if (irq == VIRTIO0_IRQ)
    80002d78:	4785                	li	a5,1
    80002d7a:	02f50963          	beq	a0,a5,80002dac <devintr+0x78>
		return 1;
    80002d7e:	4505                	li	a0,1
		else if (irq)
    80002d80:	dcf9                	beqz	s1,80002d5e <devintr+0x2a>
			printf("unexpected interrupt irq=%d\n", irq);
    80002d82:	85a6                	mv	a1,s1
    80002d84:	00005517          	auipc	a0,0x5
    80002d88:	58c50513          	addi	a0,a0,1420 # 80008310 <states.0+0x38>
    80002d8c:	ffffd097          	auipc	ra,0xffffd
    80002d90:	7fa080e7          	jalr	2042(ra) # 80000586 <printf>
			plic_complete(irq);
    80002d94:	8526                	mv	a0,s1
    80002d96:	00003097          	auipc	ra,0x3
    80002d9a:	676080e7          	jalr	1654(ra) # 8000640c <plic_complete>
		return 1;
    80002d9e:	4505                	li	a0,1
    80002da0:	bf7d                	j	80002d5e <devintr+0x2a>
			uartintr();
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	bf2080e7          	jalr	-1038(ra) # 80000994 <uartintr>
		if (irq)
    80002daa:	b7ed                	j	80002d94 <devintr+0x60>
			virtio_disk_intr();
    80002dac:	00004097          	auipc	ra,0x4
    80002db0:	b26080e7          	jalr	-1242(ra) # 800068d2 <virtio_disk_intr>
		if (irq)
    80002db4:	b7c5                	j	80002d94 <devintr+0x60>
		if (cpuid() == 0)
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	bf4080e7          	jalr	-1036(ra) # 800019aa <cpuid>
    80002dbe:	c901                	beqz	a0,80002dce <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002dc0:	144027f3          	csrr	a5,sip
		w_sip(r_sip() & ~2);
    80002dc4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dc6:	14479073          	csrw	sip,a5
		return 2;
    80002dca:	4509                	li	a0,2
    80002dcc:	bf49                	j	80002d5e <devintr+0x2a>
			clockintr();
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	f0a080e7          	jalr	-246(ra) # 80002cd8 <clockintr>
    80002dd6:	b7ed                	j	80002dc0 <devintr+0x8c>
}
    80002dd8:	8082                	ret

0000000080002dda <usertrap>:
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	e426                	sd	s1,8(sp)
    80002de2:	e04a                	sd	s2,0(sp)
    80002de4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002de6:	100027f3          	csrr	a5,sstatus
	if((r_sstatus() & SSTATUS_SPP) != 0)
    80002dea:	1007f793          	andi	a5,a5,256
    80002dee:	e3b1                	bnez	a5,80002e32 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002df0:	00003797          	auipc	a5,0x3
    80002df4:	4f078793          	addi	a5,a5,1264 # 800062e0 <kernelvec>
    80002df8:	10579073          	csrw	stvec,a5
	struct proc *p = myproc();
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	bda080e7          	jalr	-1062(ra) # 800019d6 <myproc>
    80002e04:	84aa                	mv	s1,a0
	p->trapframe->epc = r_sepc();
    80002e06:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e08:	14102773          	csrr	a4,sepc
    80002e0c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e0e:	14202773          	csrr	a4,scause
	if (r_scause() == 8)
    80002e12:	47a1                	li	a5,8
    80002e14:	02f70763          	beq	a4,a5,80002e42 <usertrap+0x68>
	else if ((which_dev = devintr()) != 0)
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	f1c080e7          	jalr	-228(ra) # 80002d34 <devintr>
    80002e20:	892a                	mv	s2,a0
    80002e22:	c92d                	beqz	a0,80002e94 <usertrap+0xba>
	if (killed(p))
    80002e24:	8526                	mv	a0,s1
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	80e080e7          	jalr	-2034(ra) # 80002634 <killed>
    80002e2e:	c555                	beqz	a0,80002eda <usertrap+0x100>
    80002e30:	a045                	j	80002ed0 <usertrap+0xf6>
		panic("usertrap: not from user mode");
    80002e32:	00005517          	auipc	a0,0x5
    80002e36:	4fe50513          	addi	a0,a0,1278 # 80008330 <states.0+0x58>
    80002e3a:	ffffd097          	auipc	ra,0xffffd
    80002e3e:	702080e7          	jalr	1794(ra) # 8000053c <panic>
		if (killed(p))
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	7f2080e7          	jalr	2034(ra) # 80002634 <killed>
    80002e4a:	ed1d                	bnez	a0,80002e88 <usertrap+0xae>
		p->trapframe->epc += 4;
    80002e4c:	6cb8                	ld	a4,88(s1)
    80002e4e:	6f1c                	ld	a5,24(a4)
    80002e50:	0791                	addi	a5,a5,4
    80002e52:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e54:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e58:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e5c:	10079073          	csrw	sstatus,a5
		syscall();
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	3ba080e7          	jalr	954(ra) # 8000321a <syscall>
	if (killed(p))
    80002e68:	8526                	mv	a0,s1
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	7ca080e7          	jalr	1994(ra) # 80002634 <killed>
    80002e72:	ed31                	bnez	a0,80002ece <usertrap+0xf4>
	usertrapret();
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	dce080e7          	jalr	-562(ra) # 80002c42 <usertrapret>
}
    80002e7c:	60e2                	ld	ra,24(sp)
    80002e7e:	6442                	ld	s0,16(sp)
    80002e80:	64a2                	ld	s1,8(sp)
    80002e82:	6902                	ld	s2,0(sp)
    80002e84:	6105                	addi	sp,sp,32
    80002e86:	8082                	ret
			exit(-1);
    80002e88:	557d                	li	a0,-1
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	61c080e7          	jalr	1564(ra) # 800024a6 <exit>
    80002e92:	bf6d                	j	80002e4c <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e94:	142025f3          	csrr	a1,scause
		printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e98:	5890                	lw	a2,48(s1)
    80002e9a:	00005517          	auipc	a0,0x5
    80002e9e:	4b650513          	addi	a0,a0,1206 # 80008350 <states.0+0x78>
    80002ea2:	ffffd097          	auipc	ra,0xffffd
    80002ea6:	6e4080e7          	jalr	1764(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eaa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eae:	14302673          	csrr	a2,stval
		printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002eb2:	00005517          	auipc	a0,0x5
    80002eb6:	4ce50513          	addi	a0,a0,1230 # 80008380 <states.0+0xa8>
    80002eba:	ffffd097          	auipc	ra,0xffffd
    80002ebe:	6cc080e7          	jalr	1740(ra) # 80000586 <printf>
		setkilled(p);
    80002ec2:	8526                	mv	a0,s1
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	744080e7          	jalr	1860(ra) # 80002608 <setkilled>
    80002ecc:	bf71                	j	80002e68 <usertrap+0x8e>
	if (killed(p))
    80002ece:	4901                	li	s2,0
		exit(-1);
    80002ed0:	557d                	li	a0,-1
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	5d4080e7          	jalr	1492(ra) # 800024a6 <exit>
	if (which_dev == 2)
    80002eda:	4789                	li	a5,2
    80002edc:	f8f91ce3          	bne	s2,a5,80002e74 <usertrap+0x9a>
		p->now_ticks+=1 ;
    80002ee0:	1804a783          	lw	a5,384(s1)
    80002ee4:	2785                	addiw	a5,a5,1
    80002ee6:	0007871b          	sext.w	a4,a5
    80002eea:	18f4a023          	sw	a5,384(s1)
		if( p-> ticks > 0 && p->now_ticks >= p->ticks && !p->is_sigalarm)
    80002eee:	17c4a783          	lw	a5,380(s1)
    80002ef2:	04f05663          	blez	a5,80002f3e <usertrap+0x164>
    80002ef6:	04f74463          	blt	a4,a5,80002f3e <usertrap+0x164>
    80002efa:	1744a783          	lw	a5,372(s1)
    80002efe:	e3a1                	bnez	a5,80002f3e <usertrap+0x164>
			p->now_ticks = 0;
    80002f00:	1804a023          	sw	zero,384(s1)
			p->is_sigalarm = 1;
    80002f04:	4785                	li	a5,1
    80002f06:	16f4aa23          	sw	a5,372(s1)
			*(p->backup_trapframe) =*( p->trapframe);
    80002f0a:	6cb4                	ld	a3,88(s1)
    80002f0c:	87b6                	mv	a5,a3
    80002f0e:	1904b703          	ld	a4,400(s1)
    80002f12:	12068693          	addi	a3,a3,288
    80002f16:	0007b803          	ld	a6,0(a5)
    80002f1a:	6788                	ld	a0,8(a5)
    80002f1c:	6b8c                	ld	a1,16(a5)
    80002f1e:	6f90                	ld	a2,24(a5)
    80002f20:	01073023          	sd	a6,0(a4)
    80002f24:	e708                	sd	a0,8(a4)
    80002f26:	eb0c                	sd	a1,16(a4)
    80002f28:	ef10                	sd	a2,24(a4)
    80002f2a:	02078793          	addi	a5,a5,32
    80002f2e:	02070713          	addi	a4,a4,32
    80002f32:	fed792e3          	bne	a5,a3,80002f16 <usertrap+0x13c>
			p->trapframe->epc = p->handler;
    80002f36:	6cbc                	ld	a5,88(s1)
    80002f38:	1884b703          	ld	a4,392(s1)
    80002f3c:	ef98                	sd	a4,24(a5)
switch (myproc()->queue_no)
    80002f3e:	fffff097          	auipc	ra,0xfffff
    80002f42:	a98080e7          	jalr	-1384(ra) # 800019d6 <myproc>
    80002f46:	19852783          	lw	a5,408(a0)
    80002f4a:	4705                	li	a4,1
	max_ticks_for_queue = 3;
    80002f4c:	448d                	li	s1,3
switch (myproc()->queue_no)
    80002f4e:	00e78963          	beq	a5,a4,80002f60 <usertrap+0x186>
    80002f52:	4709                	li	a4,2
	max_ticks_for_queue = 9;
    80002f54:	44a5                	li	s1,9
switch (myproc()->queue_no)
    80002f56:	00e78563          	beq	a5,a4,80002f60 <usertrap+0x186>
    80002f5a:	4485                	li	s1,1
    80002f5c:	c391                	beqz	a5,80002f60 <usertrap+0x186>
int max_ticks_for_queue = 15;
    80002f5e:	44bd                	li	s1,15
if ( myproc()->q_run_time >= max_ticks_for_queue){
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	a76080e7          	jalr	-1418(ra) # 800019d6 <myproc>
    80002f68:	1b452783          	lw	a5,436(a0)
    80002f6c:	f097e4e3          	bltu	a5,s1,80002e74 <usertrap+0x9a>
	set_overshot_proc();
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	b5a080e7          	jalr	-1190(ra) # 80002aca <set_overshot_proc>
	yield();
    80002f78:	fffff097          	auipc	ra,0xfffff
    80002f7c:	252080e7          	jalr	594(ra) # 800021ca <yield>
    80002f80:	bdd5                	j	80002e74 <usertrap+0x9a>

0000000080002f82 <kerneltrap>:
{
    80002f82:	7179                	addi	sp,sp,-48
    80002f84:	f406                	sd	ra,40(sp)
    80002f86:	f022                	sd	s0,32(sp)
    80002f88:	ec26                	sd	s1,24(sp)
    80002f8a:	e84a                	sd	s2,16(sp)
    80002f8c:	e44e                	sd	s3,8(sp)
    80002f8e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f90:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f94:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f98:	142029f3          	csrr	s3,scause
	if ((sstatus & SSTATUS_SPP) == 0)
    80002f9c:	1004f793          	andi	a5,s1,256
    80002fa0:	cb85                	beqz	a5,80002fd0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fa2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fa6:	8b89                	andi	a5,a5,2
	if (intr_get() != 0)
    80002fa8:	ef85                	bnez	a5,80002fe0 <kerneltrap+0x5e>
	if ((which_dev = devintr()) == 0)
    80002faa:	00000097          	auipc	ra,0x0
    80002fae:	d8a080e7          	jalr	-630(ra) # 80002d34 <devintr>
    80002fb2:	cd1d                	beqz	a0,80002ff0 <kerneltrap+0x6e>
if(which_dev == 2  && myproc()!=0  && myproc()->state == RUNNING)
    80002fb4:	4789                	li	a5,2
    80002fb6:	06f50a63          	beq	a0,a5,8000302a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fba:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fbe:	10049073          	csrw	sstatus,s1
}
    80002fc2:	70a2                	ld	ra,40(sp)
    80002fc4:	7402                	ld	s0,32(sp)
    80002fc6:	64e2                	ld	s1,24(sp)
    80002fc8:	6942                	ld	s2,16(sp)
    80002fca:	69a2                	ld	s3,8(sp)
    80002fcc:	6145                	addi	sp,sp,48
    80002fce:	8082                	ret
		panic("kerneltrap: not from supervisor mode");
    80002fd0:	00005517          	auipc	a0,0x5
    80002fd4:	3d050513          	addi	a0,a0,976 # 800083a0 <states.0+0xc8>
    80002fd8:	ffffd097          	auipc	ra,0xffffd
    80002fdc:	564080e7          	jalr	1380(ra) # 8000053c <panic>
		panic("kerneltrap: interrupts enabled");
    80002fe0:	00005517          	auipc	a0,0x5
    80002fe4:	3e850513          	addi	a0,a0,1000 # 800083c8 <states.0+0xf0>
    80002fe8:	ffffd097          	auipc	ra,0xffffd
    80002fec:	554080e7          	jalr	1364(ra) # 8000053c <panic>
		printf("scause %p\n", scause);
    80002ff0:	85ce                	mv	a1,s3
    80002ff2:	00005517          	auipc	a0,0x5
    80002ff6:	3f650513          	addi	a0,a0,1014 # 800083e8 <states.0+0x110>
    80002ffa:	ffffd097          	auipc	ra,0xffffd
    80002ffe:	58c080e7          	jalr	1420(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003002:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003006:	14302673          	csrr	a2,stval
		printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000300a:	00005517          	auipc	a0,0x5
    8000300e:	3ee50513          	addi	a0,a0,1006 # 800083f8 <states.0+0x120>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	574080e7          	jalr	1396(ra) # 80000586 <printf>
		panic("kerneltrap");
    8000301a:	00005517          	auipc	a0,0x5
    8000301e:	3f650513          	addi	a0,a0,1014 # 80008410 <states.0+0x138>
    80003022:	ffffd097          	auipc	ra,0xffffd
    80003026:	51a080e7          	jalr	1306(ra) # 8000053c <panic>
if(which_dev == 2  && myproc()!=0  && myproc()->state == RUNNING)
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	9ac080e7          	jalr	-1620(ra) # 800019d6 <myproc>
    80003032:	d541                	beqz	a0,80002fba <kerneltrap+0x38>
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	9a2080e7          	jalr	-1630(ra) # 800019d6 <myproc>
    8000303c:	4d18                	lw	a4,24(a0)
    8000303e:	4791                	li	a5,4
    80003040:	f6f71de3          	bne	a4,a5,80002fba <kerneltrap+0x38>
switch (myproc()->queue_no)
    80003044:	fffff097          	auipc	ra,0xfffff
    80003048:	992080e7          	jalr	-1646(ra) # 800019d6 <myproc>
    8000304c:	19852783          	lw	a5,408(a0)
    80003050:	4705                	li	a4,1
	max_ticks_for_queue = 3;
    80003052:	498d                	li	s3,3
switch (myproc()->queue_no)
    80003054:	00e78963          	beq	a5,a4,80003066 <kerneltrap+0xe4>
    80003058:	4709                	li	a4,2
	max_ticks_for_queue = 9;
    8000305a:	49a5                	li	s3,9
switch (myproc()->queue_no)
    8000305c:	00e78563          	beq	a5,a4,80003066 <kerneltrap+0xe4>
    80003060:	4985                	li	s3,1
    80003062:	c391                	beqz	a5,80003066 <kerneltrap+0xe4>
{int max_ticks_for_queue = 15;
    80003064:	49bd                	li	s3,15
if ( myproc()->q_run_time >= max_ticks_for_queue){
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	970080e7          	jalr	-1680(ra) # 800019d6 <myproc>
    8000306e:	1b452783          	lw	a5,436(a0)
    80003072:	f537e4e3          	bltu	a5,s3,80002fba <kerneltrap+0x38>
	set_overshot_proc();
    80003076:	00000097          	auipc	ra,0x0
    8000307a:	a54080e7          	jalr	-1452(ra) # 80002aca <set_overshot_proc>
	yield();
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	14c080e7          	jalr	332(ra) # 800021ca <yield>
    80003086:	bf15                	j	80002fba <kerneltrap+0x38>

0000000080003088 <sys_getreadcount>:
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}
uint64 sys_getreadcount(void)
{
    80003088:	1141                	addi	sp,sp,-16
    8000308a:	e422                	sd	s0,8(sp)
    8000308c:	0800                	addi	s0,sp,16
  return READCOUNT; 
}
    8000308e:	00006517          	auipc	a0,0x6
    80003092:	88a53503          	ld	a0,-1910(a0) # 80008918 <READCOUNT>
    80003096:	6422                	ld	s0,8(sp)
    80003098:	0141                	addi	sp,sp,16
    8000309a:	8082                	ret

000000008000309c <argraw>:
{
    8000309c:	1101                	addi	sp,sp,-32
    8000309e:	ec06                	sd	ra,24(sp)
    800030a0:	e822                	sd	s0,16(sp)
    800030a2:	e426                	sd	s1,8(sp)
    800030a4:	1000                	addi	s0,sp,32
    800030a6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030a8:	fffff097          	auipc	ra,0xfffff
    800030ac:	92e080e7          	jalr	-1746(ra) # 800019d6 <myproc>
  switch (n) {
    800030b0:	4795                	li	a5,5
    800030b2:	0497e163          	bltu	a5,s1,800030f4 <argraw+0x58>
    800030b6:	048a                	slli	s1,s1,0x2
    800030b8:	00005717          	auipc	a4,0x5
    800030bc:	39070713          	addi	a4,a4,912 # 80008448 <states.0+0x170>
    800030c0:	94ba                	add	s1,s1,a4
    800030c2:	409c                	lw	a5,0(s1)
    800030c4:	97ba                	add	a5,a5,a4
    800030c6:	8782                	jr	a5
    return p->trapframe->a0;
    800030c8:	6d3c                	ld	a5,88(a0)
    800030ca:	7ba8                	ld	a0,112(a5)
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret
    return p->trapframe->a1;
    800030d6:	6d3c                	ld	a5,88(a0)
    800030d8:	7fa8                	ld	a0,120(a5)
    800030da:	bfcd                	j	800030cc <argraw+0x30>
    return p->trapframe->a2;
    800030dc:	6d3c                	ld	a5,88(a0)
    800030de:	63c8                	ld	a0,128(a5)
    800030e0:	b7f5                	j	800030cc <argraw+0x30>
    return p->trapframe->a3;
    800030e2:	6d3c                	ld	a5,88(a0)
    800030e4:	67c8                	ld	a0,136(a5)
    800030e6:	b7dd                	j	800030cc <argraw+0x30>
    return p->trapframe->a4;
    800030e8:	6d3c                	ld	a5,88(a0)
    800030ea:	6bc8                	ld	a0,144(a5)
    800030ec:	b7c5                	j	800030cc <argraw+0x30>
    return p->trapframe->a5;
    800030ee:	6d3c                	ld	a5,88(a0)
    800030f0:	6fc8                	ld	a0,152(a5)
    800030f2:	bfe9                	j	800030cc <argraw+0x30>
  panic("argraw");
    800030f4:	00005517          	auipc	a0,0x5
    800030f8:	32c50513          	addi	a0,a0,812 # 80008420 <states.0+0x148>
    800030fc:	ffffd097          	auipc	ra,0xffffd
    80003100:	440080e7          	jalr	1088(ra) # 8000053c <panic>

0000000080003104 <fetchaddr>:
{
    80003104:	1101                	addi	sp,sp,-32
    80003106:	ec06                	sd	ra,24(sp)
    80003108:	e822                	sd	s0,16(sp)
    8000310a:	e426                	sd	s1,8(sp)
    8000310c:	e04a                	sd	s2,0(sp)
    8000310e:	1000                	addi	s0,sp,32
    80003110:	84aa                	mv	s1,a0
    80003112:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	8c2080e7          	jalr	-1854(ra) # 800019d6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000311c:	653c                	ld	a5,72(a0)
    8000311e:	02f4f863          	bgeu	s1,a5,8000314e <fetchaddr+0x4a>
    80003122:	00848713          	addi	a4,s1,8
    80003126:	02e7e663          	bltu	a5,a4,80003152 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000312a:	46a1                	li	a3,8
    8000312c:	8626                	mv	a2,s1
    8000312e:	85ca                	mv	a1,s2
    80003130:	6928                	ld	a0,80(a0)
    80003132:	ffffe097          	auipc	ra,0xffffe
    80003136:	5c0080e7          	jalr	1472(ra) # 800016f2 <copyin>
    8000313a:	00a03533          	snez	a0,a0
    8000313e:	40a00533          	neg	a0,a0
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	64a2                	ld	s1,8(sp)
    80003148:	6902                	ld	s2,0(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret
    return -1;
    8000314e:	557d                	li	a0,-1
    80003150:	bfcd                	j	80003142 <fetchaddr+0x3e>
    80003152:	557d                	li	a0,-1
    80003154:	b7fd                	j	80003142 <fetchaddr+0x3e>

0000000080003156 <fetchstr>:
{
    80003156:	7179                	addi	sp,sp,-48
    80003158:	f406                	sd	ra,40(sp)
    8000315a:	f022                	sd	s0,32(sp)
    8000315c:	ec26                	sd	s1,24(sp)
    8000315e:	e84a                	sd	s2,16(sp)
    80003160:	e44e                	sd	s3,8(sp)
    80003162:	1800                	addi	s0,sp,48
    80003164:	892a                	mv	s2,a0
    80003166:	84ae                	mv	s1,a1
    80003168:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000316a:	fffff097          	auipc	ra,0xfffff
    8000316e:	86c080e7          	jalr	-1940(ra) # 800019d6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003172:	86ce                	mv	a3,s3
    80003174:	864a                	mv	a2,s2
    80003176:	85a6                	mv	a1,s1
    80003178:	6928                	ld	a0,80(a0)
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	606080e7          	jalr	1542(ra) # 80001780 <copyinstr>
    80003182:	00054e63          	bltz	a0,8000319e <fetchstr+0x48>
  return strlen(buf);
    80003186:	8526                	mv	a0,s1
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	cc0080e7          	jalr	-832(ra) # 80000e48 <strlen>
}
    80003190:	70a2                	ld	ra,40(sp)
    80003192:	7402                	ld	s0,32(sp)
    80003194:	64e2                	ld	s1,24(sp)
    80003196:	6942                	ld	s2,16(sp)
    80003198:	69a2                	ld	s3,8(sp)
    8000319a:	6145                	addi	sp,sp,48
    8000319c:	8082                	ret
    return -1;
    8000319e:	557d                	li	a0,-1
    800031a0:	bfc5                	j	80003190 <fetchstr+0x3a>

00000000800031a2 <argint>:
{
    800031a2:	1101                	addi	sp,sp,-32
    800031a4:	ec06                	sd	ra,24(sp)
    800031a6:	e822                	sd	s0,16(sp)
    800031a8:	e426                	sd	s1,8(sp)
    800031aa:	1000                	addi	s0,sp,32
    800031ac:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	eee080e7          	jalr	-274(ra) # 8000309c <argraw>
    800031b6:	c088                	sw	a0,0(s1)
}
    800031b8:	60e2                	ld	ra,24(sp)
    800031ba:	6442                	ld	s0,16(sp)
    800031bc:	64a2                	ld	s1,8(sp)
    800031be:	6105                	addi	sp,sp,32
    800031c0:	8082                	ret

00000000800031c2 <argaddr>:
{
    800031c2:	1101                	addi	sp,sp,-32
    800031c4:	ec06                	sd	ra,24(sp)
    800031c6:	e822                	sd	s0,16(sp)
    800031c8:	e426                	sd	s1,8(sp)
    800031ca:	1000                	addi	s0,sp,32
    800031cc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031ce:	00000097          	auipc	ra,0x0
    800031d2:	ece080e7          	jalr	-306(ra) # 8000309c <argraw>
    800031d6:	e088                	sd	a0,0(s1)
}
    800031d8:	60e2                	ld	ra,24(sp)
    800031da:	6442                	ld	s0,16(sp)
    800031dc:	64a2                	ld	s1,8(sp)
    800031de:	6105                	addi	sp,sp,32
    800031e0:	8082                	ret

00000000800031e2 <argstr>:
{
    800031e2:	7179                	addi	sp,sp,-48
    800031e4:	f406                	sd	ra,40(sp)
    800031e6:	f022                	sd	s0,32(sp)
    800031e8:	ec26                	sd	s1,24(sp)
    800031ea:	e84a                	sd	s2,16(sp)
    800031ec:	1800                	addi	s0,sp,48
    800031ee:	84ae                	mv	s1,a1
    800031f0:	8932                	mv	s2,a2
  argaddr(n, &addr);
    800031f2:	fd840593          	addi	a1,s0,-40
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	fcc080e7          	jalr	-52(ra) # 800031c2 <argaddr>
  return fetchstr(addr, buf, max);
    800031fe:	864a                	mv	a2,s2
    80003200:	85a6                	mv	a1,s1
    80003202:	fd843503          	ld	a0,-40(s0)
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	f50080e7          	jalr	-176(ra) # 80003156 <fetchstr>
}
    8000320e:	70a2                	ld	ra,40(sp)
    80003210:	7402                	ld	s0,32(sp)
    80003212:	64e2                	ld	s1,24(sp)
    80003214:	6942                	ld	s2,16(sp)
    80003216:	6145                	addi	sp,sp,48
    80003218:	8082                	ret

000000008000321a <syscall>:

};

void
syscall(void)
{
    8000321a:	1101                	addi	sp,sp,-32
    8000321c:	ec06                	sd	ra,24(sp)
    8000321e:	e822                	sd	s0,16(sp)
    80003220:	e426                	sd	s1,8(sp)
    80003222:	e04a                	sd	s2,0(sp)
    80003224:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003226:	ffffe097          	auipc	ra,0xffffe
    8000322a:	7b0080e7          	jalr	1968(ra) # 800019d6 <myproc>
    8000322e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003230:	05853903          	ld	s2,88(a0)
    80003234:	0a893783          	ld	a5,168(s2)
    80003238:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000323c:	37fd                	addiw	a5,a5,-1
    8000323e:	4761                	li	a4,24
    80003240:	00f76f63          	bltu	a4,a5,8000325e <syscall+0x44>
    80003244:	00369713          	slli	a4,a3,0x3
    80003248:	00005797          	auipc	a5,0x5
    8000324c:	21878793          	addi	a5,a5,536 # 80008460 <syscalls>
    80003250:	97ba                	add	a5,a5,a4
    80003252:	639c                	ld	a5,0(a5)
    80003254:	c789                	beqz	a5,8000325e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003256:	9782                	jalr	a5
    80003258:	06a93823          	sd	a0,112(s2)
    8000325c:	a839                	j	8000327a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000325e:	15848613          	addi	a2,s1,344
    80003262:	588c                	lw	a1,48(s1)
    80003264:	00005517          	auipc	a0,0x5
    80003268:	1c450513          	addi	a0,a0,452 # 80008428 <states.0+0x150>
    8000326c:	ffffd097          	auipc	ra,0xffffd
    80003270:	31a080e7          	jalr	794(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003274:	6cbc                	ld	a5,88(s1)
    80003276:	577d                	li	a4,-1
    80003278:	fbb8                	sd	a4,112(a5)
  }
}
    8000327a:	60e2                	ld	ra,24(sp)
    8000327c:	6442                	ld	s0,16(sp)
    8000327e:	64a2                	ld	s1,8(sp)
    80003280:	6902                	ld	s2,0(sp)
    80003282:	6105                	addi	sp,sp,32
    80003284:	8082                	ret

0000000080003286 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003286:	1101                	addi	sp,sp,-32
    80003288:	ec06                	sd	ra,24(sp)
    8000328a:	e822                	sd	s0,16(sp)
    8000328c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000328e:	fec40593          	addi	a1,s0,-20
    80003292:	4501                	li	a0,0
    80003294:	00000097          	auipc	ra,0x0
    80003298:	f0e080e7          	jalr	-242(ra) # 800031a2 <argint>
  exit(n);
    8000329c:	fec42503          	lw	a0,-20(s0)
    800032a0:	fffff097          	auipc	ra,0xfffff
    800032a4:	206080e7          	jalr	518(ra) # 800024a6 <exit>
  return 0; // not reached
}
    800032a8:	4501                	li	a0,0
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	6105                	addi	sp,sp,32
    800032b0:	8082                	ret

00000000800032b2 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032b2:	1141                	addi	sp,sp,-16
    800032b4:	e406                	sd	ra,8(sp)
    800032b6:	e022                	sd	s0,0(sp)
    800032b8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	71c080e7          	jalr	1820(ra) # 800019d6 <myproc>
}
    800032c2:	5908                	lw	a0,48(a0)
    800032c4:	60a2                	ld	ra,8(sp)
    800032c6:	6402                	ld	s0,0(sp)
    800032c8:	0141                	addi	sp,sp,16
    800032ca:	8082                	ret

00000000800032cc <sys_fork>:

uint64
sys_fork(void)
{
    800032cc:	1141                	addi	sp,sp,-16
    800032ce:	e406                	sd	ra,8(sp)
    800032d0:	e022                	sd	s0,0(sp)
    800032d2:	0800                	addi	s0,sp,16
  return fork();
    800032d4:	fffff097          	auipc	ra,0xfffff
    800032d8:	f32080e7          	jalr	-206(ra) # 80002206 <fork>
}
    800032dc:	60a2                	ld	ra,8(sp)
    800032de:	6402                	ld	s0,0(sp)
    800032e0:	0141                	addi	sp,sp,16
    800032e2:	8082                	ret

00000000800032e4 <sys_wait>:

uint64
sys_wait(void)
{
    800032e4:	1101                	addi	sp,sp,-32
    800032e6:	ec06                	sd	ra,24(sp)
    800032e8:	e822                	sd	s0,16(sp)
    800032ea:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800032ec:	fe840593          	addi	a1,s0,-24
    800032f0:	4501                	li	a0,0
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	ed0080e7          	jalr	-304(ra) # 800031c2 <argaddr>
  return wait(p);
    800032fa:	fe843503          	ld	a0,-24(s0)
    800032fe:	fffff097          	auipc	ra,0xfffff
    80003302:	368080e7          	jalr	872(ra) # 80002666 <wait>
}
    80003306:	60e2                	ld	ra,24(sp)
    80003308:	6442                	ld	s0,16(sp)
    8000330a:	6105                	addi	sp,sp,32
    8000330c:	8082                	ret

000000008000330e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000330e:	7179                	addi	sp,sp,-48
    80003310:	f406                	sd	ra,40(sp)
    80003312:	f022                	sd	s0,32(sp)
    80003314:	ec26                	sd	s1,24(sp)
    80003316:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003318:	fdc40593          	addi	a1,s0,-36
    8000331c:	4501                	li	a0,0
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	e84080e7          	jalr	-380(ra) # 800031a2 <argint>
  addr = myproc()->sz;
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	6b0080e7          	jalr	1712(ra) # 800019d6 <myproc>
    8000332e:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003330:	fdc42503          	lw	a0,-36(s0)
    80003334:	fffff097          	auipc	ra,0xfffff
    80003338:	ba2080e7          	jalr	-1118(ra) # 80001ed6 <growproc>
    8000333c:	00054863          	bltz	a0,8000334c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003340:	8526                	mv	a0,s1
    80003342:	70a2                	ld	ra,40(sp)
    80003344:	7402                	ld	s0,32(sp)
    80003346:	64e2                	ld	s1,24(sp)
    80003348:	6145                	addi	sp,sp,48
    8000334a:	8082                	ret
    return -1;
    8000334c:	54fd                	li	s1,-1
    8000334e:	bfcd                	j	80003340 <sys_sbrk+0x32>

0000000080003350 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003350:	7139                	addi	sp,sp,-64
    80003352:	fc06                	sd	ra,56(sp)
    80003354:	f822                	sd	s0,48(sp)
    80003356:	f426                	sd	s1,40(sp)
    80003358:	f04a                	sd	s2,32(sp)
    8000335a:	ec4e                	sd	s3,24(sp)
    8000335c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000335e:	fcc40593          	addi	a1,s0,-52
    80003362:	4501                	li	a0,0
    80003364:	00000097          	auipc	ra,0x0
    80003368:	e3e080e7          	jalr	-450(ra) # 800031a2 <argint>
  acquire(&tickslock);
    8000336c:	00016517          	auipc	a0,0x16
    80003370:	8e450513          	addi	a0,a0,-1820 # 80018c50 <tickslock>
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	85e080e7          	jalr	-1954(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    8000337c:	00005917          	auipc	s2,0x5
    80003380:	59492903          	lw	s2,1428(s2) # 80008910 <ticks>
  while (ticks - ticks0 < n)
    80003384:	fcc42783          	lw	a5,-52(s0)
    80003388:	cf9d                	beqz	a5,800033c6 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000338a:	00016997          	auipc	s3,0x16
    8000338e:	8c698993          	addi	s3,s3,-1850 # 80018c50 <tickslock>
    80003392:	00005497          	auipc	s1,0x5
    80003396:	57e48493          	addi	s1,s1,1406 # 80008910 <ticks>
    if (killed(myproc()))
    8000339a:	ffffe097          	auipc	ra,0xffffe
    8000339e:	63c080e7          	jalr	1596(ra) # 800019d6 <myproc>
    800033a2:	fffff097          	auipc	ra,0xfffff
    800033a6:	292080e7          	jalr	658(ra) # 80002634 <killed>
    800033aa:	ed15                	bnez	a0,800033e6 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800033ac:	85ce                	mv	a1,s3
    800033ae:	8526                	mv	a0,s1
    800033b0:	fffff097          	auipc	ra,0xfffff
    800033b4:	fb4080e7          	jalr	-76(ra) # 80002364 <sleep>
  while (ticks - ticks0 < n)
    800033b8:	409c                	lw	a5,0(s1)
    800033ba:	412787bb          	subw	a5,a5,s2
    800033be:	fcc42703          	lw	a4,-52(s0)
    800033c2:	fce7ece3          	bltu	a5,a4,8000339a <sys_sleep+0x4a>
  }
  release(&tickslock);
    800033c6:	00016517          	auipc	a0,0x16
    800033ca:	88a50513          	addi	a0,a0,-1910 # 80018c50 <tickslock>
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	8b8080e7          	jalr	-1864(ra) # 80000c86 <release>
  return 0;
    800033d6:	4501                	li	a0,0
}
    800033d8:	70e2                	ld	ra,56(sp)
    800033da:	7442                	ld	s0,48(sp)
    800033dc:	74a2                	ld	s1,40(sp)
    800033de:	7902                	ld	s2,32(sp)
    800033e0:	69e2                	ld	s3,24(sp)
    800033e2:	6121                	addi	sp,sp,64
    800033e4:	8082                	ret
      release(&tickslock);
    800033e6:	00016517          	auipc	a0,0x16
    800033ea:	86a50513          	addi	a0,a0,-1942 # 80018c50 <tickslock>
    800033ee:	ffffe097          	auipc	ra,0xffffe
    800033f2:	898080e7          	jalr	-1896(ra) # 80000c86 <release>
      return -1;
    800033f6:	557d                	li	a0,-1
    800033f8:	b7c5                	j	800033d8 <sys_sleep+0x88>

00000000800033fa <sys_kill>:

uint64
sys_kill(void)
{
    800033fa:	1101                	addi	sp,sp,-32
    800033fc:	ec06                	sd	ra,24(sp)
    800033fe:	e822                	sd	s0,16(sp)
    80003400:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003402:	fec40593          	addi	a1,s0,-20
    80003406:	4501                	li	a0,0
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	d9a080e7          	jalr	-614(ra) # 800031a2 <argint>
  return kill(pid);
    80003410:	fec42503          	lw	a0,-20(s0)
    80003414:	fffff097          	auipc	ra,0xfffff
    80003418:	174080e7          	jalr	372(ra) # 80002588 <kill>
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	6105                	addi	sp,sp,32
    80003422:	8082                	ret

0000000080003424 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003424:	1101                	addi	sp,sp,-32
    80003426:	ec06                	sd	ra,24(sp)
    80003428:	e822                	sd	s0,16(sp)
    8000342a:	e426                	sd	s1,8(sp)
    8000342c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000342e:	00016517          	auipc	a0,0x16
    80003432:	82250513          	addi	a0,a0,-2014 # 80018c50 <tickslock>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	79c080e7          	jalr	1948(ra) # 80000bd2 <acquire>
  xticks = ticks;
    8000343e:	00005497          	auipc	s1,0x5
    80003442:	4d24a483          	lw	s1,1234(s1) # 80008910 <ticks>
  release(&tickslock);
    80003446:	00016517          	auipc	a0,0x16
    8000344a:	80a50513          	addi	a0,a0,-2038 # 80018c50 <tickslock>
    8000344e:	ffffe097          	auipc	ra,0xffffe
    80003452:	838080e7          	jalr	-1992(ra) # 80000c86 <release>
  return xticks;
}
    80003456:	02049513          	slli	a0,s1,0x20
    8000345a:	9101                	srli	a0,a0,0x20
    8000345c:	60e2                	ld	ra,24(sp)
    8000345e:	6442                	ld	s0,16(sp)
    80003460:	64a2                	ld	s1,8(sp)
    80003462:	6105                	addi	sp,sp,32
    80003464:	8082                	ret

0000000080003466 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003466:	7139                	addi	sp,sp,-64
    80003468:	fc06                	sd	ra,56(sp)
    8000346a:	f822                	sd	s0,48(sp)
    8000346c:	f426                	sd	s1,40(sp)
    8000346e:	f04a                	sd	s2,32(sp)
    80003470:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003472:	fd840593          	addi	a1,s0,-40
    80003476:	4501                	li	a0,0
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	d4a080e7          	jalr	-694(ra) # 800031c2 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003480:	fd040593          	addi	a1,s0,-48
    80003484:	4505                	li	a0,1
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	d3c080e7          	jalr	-708(ra) # 800031c2 <argaddr>
  argaddr(2, &addr2);
    8000348e:	fc840593          	addi	a1,s0,-56
    80003492:	4509                	li	a0,2
    80003494:	00000097          	auipc	ra,0x0
    80003498:	d2e080e7          	jalr	-722(ra) # 800031c2 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000349c:	fc040613          	addi	a2,s0,-64
    800034a0:	fc440593          	addi	a1,s0,-60
    800034a4:	fd843503          	ld	a0,-40(s0)
    800034a8:	fffff097          	auipc	ra,0xfffff
    800034ac:	478080e7          	jalr	1144(ra) # 80002920 <waitx>
    800034b0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800034b2:	ffffe097          	auipc	ra,0xffffe
    800034b6:	524080e7          	jalr	1316(ra) # 800019d6 <myproc>
    800034ba:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800034bc:	4691                	li	a3,4
    800034be:	fc440613          	addi	a2,s0,-60
    800034c2:	fd043583          	ld	a1,-48(s0)
    800034c6:	6928                	ld	a0,80(a0)
    800034c8:	ffffe097          	auipc	ra,0xffffe
    800034cc:	19e080e7          	jalr	414(ra) # 80001666 <copyout>
    return -1;
    800034d0:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800034d2:	00054f63          	bltz	a0,800034f0 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800034d6:	4691                	li	a3,4
    800034d8:	fc040613          	addi	a2,s0,-64
    800034dc:	fc843583          	ld	a1,-56(s0)
    800034e0:	68a8                	ld	a0,80(s1)
    800034e2:	ffffe097          	auipc	ra,0xffffe
    800034e6:	184080e7          	jalr	388(ra) # 80001666 <copyout>
    800034ea:	00054a63          	bltz	a0,800034fe <sys_waitx+0x98>
    return -1;
  return ret;
    800034ee:	87ca                	mv	a5,s2
}
    800034f0:	853e                	mv	a0,a5
    800034f2:	70e2                	ld	ra,56(sp)
    800034f4:	7442                	ld	s0,48(sp)
    800034f6:	74a2                	ld	s1,40(sp)
    800034f8:	7902                	ld	s2,32(sp)
    800034fa:	6121                	addi	sp,sp,64
    800034fc:	8082                	ret
    return -1;
    800034fe:	57fd                	li	a5,-1
    80003500:	bfc5                	j	800034f0 <sys_waitx+0x8a>

0000000080003502 <restore>:
void restore(){
    80003502:	1141                	addi	sp,sp,-16
    80003504:	e406                	sd	ra,8(sp)
    80003506:	e022                	sd	s0,0(sp)
    80003508:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000350a:	ffffe097          	auipc	ra,0xffffe
    8000350e:	4cc080e7          	jalr	1228(ra) # 800019d6 <myproc>
  p->backup_trapframe->kernel_hartid = p->trapframe->kernel_hartid;
    80003512:	19053783          	ld	a5,400(a0)
    80003516:	6d38                	ld	a4,88(a0)
    80003518:	7318                	ld	a4,32(a4)
    8000351a:	f398                	sd	a4,32(a5)
  p->backup_trapframe->kernel_satp = p->trapframe->kernel_satp;
    8000351c:	19053783          	ld	a5,400(a0)
    80003520:	6d38                	ld	a4,88(a0)
    80003522:	6318                	ld	a4,0(a4)
    80003524:	e398                	sd	a4,0(a5)
  p->backup_trapframe->kernel_sp = p->trapframe->kernel_sp;
    80003526:	19053783          	ld	a5,400(a0)
    8000352a:	6d38                	ld	a4,88(a0)
    8000352c:	6718                	ld	a4,8(a4)
    8000352e:	e798                	sd	a4,8(a5)
  p->backup_trapframe->kernel_trap = p->trapframe->kernel_trap;
    80003530:	19053783          	ld	a5,400(a0)
    80003534:	6d38                	ld	a4,88(a0)
    80003536:	6b18                	ld	a4,16(a4)
    80003538:	eb98                	sd	a4,16(a5)
  *(p->trapframe) = *(p->backup_trapframe);
    8000353a:	19053683          	ld	a3,400(a0)
    8000353e:	87b6                	mv	a5,a3
    80003540:	6d38                	ld	a4,88(a0)
    80003542:	12068693          	addi	a3,a3,288
    80003546:	0007b803          	ld	a6,0(a5)
    8000354a:	6788                	ld	a0,8(a5)
    8000354c:	6b8c                	ld	a1,16(a5)
    8000354e:	6f90                	ld	a2,24(a5)
    80003550:	01073023          	sd	a6,0(a4)
    80003554:	e708                	sd	a0,8(a4)
    80003556:	eb0c                	sd	a1,16(a4)
    80003558:	ef10                	sd	a2,24(a4)
    8000355a:	02078793          	addi	a5,a5,32
    8000355e:	02070713          	addi	a4,a4,32
    80003562:	fed792e3          	bne	a5,a3,80003546 <restore+0x44>
} 
    80003566:	60a2                	ld	ra,8(sp)
    80003568:	6402                	ld	s0,0(sp)
    8000356a:	0141                	addi	sp,sp,16
    8000356c:	8082                	ret

000000008000356e <sys_sigreturn>:
uint64 sys_sigreturn(void){
    8000356e:	1141                	addi	sp,sp,-16
    80003570:	e406                	sd	ra,8(sp)
    80003572:	e022                	sd	s0,0(sp)
    80003574:	0800                	addi	s0,sp,16
  restore();
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	f8c080e7          	jalr	-116(ra) # 80003502 <restore>
  myproc()->is_sigalarm = 0;
    8000357e:	ffffe097          	auipc	ra,0xffffe
    80003582:	458080e7          	jalr	1112(ra) # 800019d6 <myproc>
    80003586:	16052a23          	sw	zero,372(a0)
  return myproc()->trapframe->a0;
    8000358a:	ffffe097          	auipc	ra,0xffffe
    8000358e:	44c080e7          	jalr	1100(ra) # 800019d6 <myproc>
    80003592:	6d3c                	ld	a5,88(a0)
    80003594:	7ba8                	ld	a0,112(a5)
    80003596:	60a2                	ld	ra,8(sp)
    80003598:	6402                	ld	s0,0(sp)
    8000359a:	0141                	addi	sp,sp,16
    8000359c:	8082                	ret

000000008000359e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000359e:	7179                	addi	sp,sp,-48
    800035a0:	f406                	sd	ra,40(sp)
    800035a2:	f022                	sd	s0,32(sp)
    800035a4:	ec26                	sd	s1,24(sp)
    800035a6:	e84a                	sd	s2,16(sp)
    800035a8:	e44e                	sd	s3,8(sp)
    800035aa:	e052                	sd	s4,0(sp)
    800035ac:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800035ae:	00005597          	auipc	a1,0x5
    800035b2:	f8258593          	addi	a1,a1,-126 # 80008530 <syscalls+0xd0>
    800035b6:	00015517          	auipc	a0,0x15
    800035ba:	6b250513          	addi	a0,a0,1714 # 80018c68 <bcache>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	584080e7          	jalr	1412(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035c6:	0001d797          	auipc	a5,0x1d
    800035ca:	6a278793          	addi	a5,a5,1698 # 80020c68 <bcache+0x8000>
    800035ce:	0001e717          	auipc	a4,0x1e
    800035d2:	90270713          	addi	a4,a4,-1790 # 80020ed0 <bcache+0x8268>
    800035d6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035da:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035de:	00015497          	auipc	s1,0x15
    800035e2:	6a248493          	addi	s1,s1,1698 # 80018c80 <bcache+0x18>
    b->next = bcache.head.next;
    800035e6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035e8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035ea:	00005a17          	auipc	s4,0x5
    800035ee:	f4ea0a13          	addi	s4,s4,-178 # 80008538 <syscalls+0xd8>
    b->next = bcache.head.next;
    800035f2:	2b893783          	ld	a5,696(s2)
    800035f6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035f8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035fc:	85d2                	mv	a1,s4
    800035fe:	01048513          	addi	a0,s1,16
    80003602:	00001097          	auipc	ra,0x1
    80003606:	496080e7          	jalr	1174(ra) # 80004a98 <initsleeplock>
    bcache.head.next->prev = b;
    8000360a:	2b893783          	ld	a5,696(s2)
    8000360e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003610:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003614:	45848493          	addi	s1,s1,1112
    80003618:	fd349de3          	bne	s1,s3,800035f2 <binit+0x54>
  }
}
    8000361c:	70a2                	ld	ra,40(sp)
    8000361e:	7402                	ld	s0,32(sp)
    80003620:	64e2                	ld	s1,24(sp)
    80003622:	6942                	ld	s2,16(sp)
    80003624:	69a2                	ld	s3,8(sp)
    80003626:	6a02                	ld	s4,0(sp)
    80003628:	6145                	addi	sp,sp,48
    8000362a:	8082                	ret

000000008000362c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000362c:	7179                	addi	sp,sp,-48
    8000362e:	f406                	sd	ra,40(sp)
    80003630:	f022                	sd	s0,32(sp)
    80003632:	ec26                	sd	s1,24(sp)
    80003634:	e84a                	sd	s2,16(sp)
    80003636:	e44e                	sd	s3,8(sp)
    80003638:	1800                	addi	s0,sp,48
    8000363a:	892a                	mv	s2,a0
    8000363c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000363e:	00015517          	auipc	a0,0x15
    80003642:	62a50513          	addi	a0,a0,1578 # 80018c68 <bcache>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	58c080e7          	jalr	1420(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000364e:	0001e497          	auipc	s1,0x1e
    80003652:	8d24b483          	ld	s1,-1838(s1) # 80020f20 <bcache+0x82b8>
    80003656:	0001e797          	auipc	a5,0x1e
    8000365a:	87a78793          	addi	a5,a5,-1926 # 80020ed0 <bcache+0x8268>
    8000365e:	02f48f63          	beq	s1,a5,8000369c <bread+0x70>
    80003662:	873e                	mv	a4,a5
    80003664:	a021                	j	8000366c <bread+0x40>
    80003666:	68a4                	ld	s1,80(s1)
    80003668:	02e48a63          	beq	s1,a4,8000369c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000366c:	449c                	lw	a5,8(s1)
    8000366e:	ff279ce3          	bne	a5,s2,80003666 <bread+0x3a>
    80003672:	44dc                	lw	a5,12(s1)
    80003674:	ff3799e3          	bne	a5,s3,80003666 <bread+0x3a>
      b->refcnt++;
    80003678:	40bc                	lw	a5,64(s1)
    8000367a:	2785                	addiw	a5,a5,1
    8000367c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000367e:	00015517          	auipc	a0,0x15
    80003682:	5ea50513          	addi	a0,a0,1514 # 80018c68 <bcache>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	600080e7          	jalr	1536(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    8000368e:	01048513          	addi	a0,s1,16
    80003692:	00001097          	auipc	ra,0x1
    80003696:	440080e7          	jalr	1088(ra) # 80004ad2 <acquiresleep>
      return b;
    8000369a:	a8b9                	j	800036f8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000369c:	0001e497          	auipc	s1,0x1e
    800036a0:	87c4b483          	ld	s1,-1924(s1) # 80020f18 <bcache+0x82b0>
    800036a4:	0001e797          	auipc	a5,0x1e
    800036a8:	82c78793          	addi	a5,a5,-2004 # 80020ed0 <bcache+0x8268>
    800036ac:	00f48863          	beq	s1,a5,800036bc <bread+0x90>
    800036b0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036b2:	40bc                	lw	a5,64(s1)
    800036b4:	cf81                	beqz	a5,800036cc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036b6:	64a4                	ld	s1,72(s1)
    800036b8:	fee49de3          	bne	s1,a4,800036b2 <bread+0x86>
  panic("bget: no buffers");
    800036bc:	00005517          	auipc	a0,0x5
    800036c0:	e8450513          	addi	a0,a0,-380 # 80008540 <syscalls+0xe0>
    800036c4:	ffffd097          	auipc	ra,0xffffd
    800036c8:	e78080e7          	jalr	-392(ra) # 8000053c <panic>
      b->dev = dev;
    800036cc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800036d0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800036d4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036d8:	4785                	li	a5,1
    800036da:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036dc:	00015517          	auipc	a0,0x15
    800036e0:	58c50513          	addi	a0,a0,1420 # 80018c68 <bcache>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	5a2080e7          	jalr	1442(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800036ec:	01048513          	addi	a0,s1,16
    800036f0:	00001097          	auipc	ra,0x1
    800036f4:	3e2080e7          	jalr	994(ra) # 80004ad2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036f8:	409c                	lw	a5,0(s1)
    800036fa:	cb89                	beqz	a5,8000370c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036fc:	8526                	mv	a0,s1
    800036fe:	70a2                	ld	ra,40(sp)
    80003700:	7402                	ld	s0,32(sp)
    80003702:	64e2                	ld	s1,24(sp)
    80003704:	6942                	ld	s2,16(sp)
    80003706:	69a2                	ld	s3,8(sp)
    80003708:	6145                	addi	sp,sp,48
    8000370a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000370c:	4581                	li	a1,0
    8000370e:	8526                	mv	a0,s1
    80003710:	00003097          	auipc	ra,0x3
    80003714:	f92080e7          	jalr	-110(ra) # 800066a2 <virtio_disk_rw>
    b->valid = 1;
    80003718:	4785                	li	a5,1
    8000371a:	c09c                	sw	a5,0(s1)
  return b;
    8000371c:	b7c5                	j	800036fc <bread+0xd0>

000000008000371e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000371e:	1101                	addi	sp,sp,-32
    80003720:	ec06                	sd	ra,24(sp)
    80003722:	e822                	sd	s0,16(sp)
    80003724:	e426                	sd	s1,8(sp)
    80003726:	1000                	addi	s0,sp,32
    80003728:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000372a:	0541                	addi	a0,a0,16
    8000372c:	00001097          	auipc	ra,0x1
    80003730:	440080e7          	jalr	1088(ra) # 80004b6c <holdingsleep>
    80003734:	cd01                	beqz	a0,8000374c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003736:	4585                	li	a1,1
    80003738:	8526                	mv	a0,s1
    8000373a:	00003097          	auipc	ra,0x3
    8000373e:	f68080e7          	jalr	-152(ra) # 800066a2 <virtio_disk_rw>
}
    80003742:	60e2                	ld	ra,24(sp)
    80003744:	6442                	ld	s0,16(sp)
    80003746:	64a2                	ld	s1,8(sp)
    80003748:	6105                	addi	sp,sp,32
    8000374a:	8082                	ret
    panic("bwrite");
    8000374c:	00005517          	auipc	a0,0x5
    80003750:	e0c50513          	addi	a0,a0,-500 # 80008558 <syscalls+0xf8>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	de8080e7          	jalr	-536(ra) # 8000053c <panic>

000000008000375c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000375c:	1101                	addi	sp,sp,-32
    8000375e:	ec06                	sd	ra,24(sp)
    80003760:	e822                	sd	s0,16(sp)
    80003762:	e426                	sd	s1,8(sp)
    80003764:	e04a                	sd	s2,0(sp)
    80003766:	1000                	addi	s0,sp,32
    80003768:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000376a:	01050913          	addi	s2,a0,16
    8000376e:	854a                	mv	a0,s2
    80003770:	00001097          	auipc	ra,0x1
    80003774:	3fc080e7          	jalr	1020(ra) # 80004b6c <holdingsleep>
    80003778:	c925                	beqz	a0,800037e8 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000377a:	854a                	mv	a0,s2
    8000377c:	00001097          	auipc	ra,0x1
    80003780:	3ac080e7          	jalr	940(ra) # 80004b28 <releasesleep>

  acquire(&bcache.lock);
    80003784:	00015517          	auipc	a0,0x15
    80003788:	4e450513          	addi	a0,a0,1252 # 80018c68 <bcache>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	446080e7          	jalr	1094(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003794:	40bc                	lw	a5,64(s1)
    80003796:	37fd                	addiw	a5,a5,-1
    80003798:	0007871b          	sext.w	a4,a5
    8000379c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000379e:	e71d                	bnez	a4,800037cc <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037a0:	68b8                	ld	a4,80(s1)
    800037a2:	64bc                	ld	a5,72(s1)
    800037a4:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800037a6:	68b8                	ld	a4,80(s1)
    800037a8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037aa:	0001d797          	auipc	a5,0x1d
    800037ae:	4be78793          	addi	a5,a5,1214 # 80020c68 <bcache+0x8000>
    800037b2:	2b87b703          	ld	a4,696(a5)
    800037b6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037b8:	0001d717          	auipc	a4,0x1d
    800037bc:	71870713          	addi	a4,a4,1816 # 80020ed0 <bcache+0x8268>
    800037c0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037c2:	2b87b703          	ld	a4,696(a5)
    800037c6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037c8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037cc:	00015517          	auipc	a0,0x15
    800037d0:	49c50513          	addi	a0,a0,1180 # 80018c68 <bcache>
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	4b2080e7          	jalr	1202(ra) # 80000c86 <release>
}
    800037dc:	60e2                	ld	ra,24(sp)
    800037de:	6442                	ld	s0,16(sp)
    800037e0:	64a2                	ld	s1,8(sp)
    800037e2:	6902                	ld	s2,0(sp)
    800037e4:	6105                	addi	sp,sp,32
    800037e6:	8082                	ret
    panic("brelse");
    800037e8:	00005517          	auipc	a0,0x5
    800037ec:	d7850513          	addi	a0,a0,-648 # 80008560 <syscalls+0x100>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	d4c080e7          	jalr	-692(ra) # 8000053c <panic>

00000000800037f8 <bpin>:

void
bpin(struct buf *b) {
    800037f8:	1101                	addi	sp,sp,-32
    800037fa:	ec06                	sd	ra,24(sp)
    800037fc:	e822                	sd	s0,16(sp)
    800037fe:	e426                	sd	s1,8(sp)
    80003800:	1000                	addi	s0,sp,32
    80003802:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003804:	00015517          	auipc	a0,0x15
    80003808:	46450513          	addi	a0,a0,1124 # 80018c68 <bcache>
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	3c6080e7          	jalr	966(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003814:	40bc                	lw	a5,64(s1)
    80003816:	2785                	addiw	a5,a5,1
    80003818:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000381a:	00015517          	auipc	a0,0x15
    8000381e:	44e50513          	addi	a0,a0,1102 # 80018c68 <bcache>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	464080e7          	jalr	1124(ra) # 80000c86 <release>
}
    8000382a:	60e2                	ld	ra,24(sp)
    8000382c:	6442                	ld	s0,16(sp)
    8000382e:	64a2                	ld	s1,8(sp)
    80003830:	6105                	addi	sp,sp,32
    80003832:	8082                	ret

0000000080003834 <bunpin>:

void
bunpin(struct buf *b) {
    80003834:	1101                	addi	sp,sp,-32
    80003836:	ec06                	sd	ra,24(sp)
    80003838:	e822                	sd	s0,16(sp)
    8000383a:	e426                	sd	s1,8(sp)
    8000383c:	1000                	addi	s0,sp,32
    8000383e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003840:	00015517          	auipc	a0,0x15
    80003844:	42850513          	addi	a0,a0,1064 # 80018c68 <bcache>
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	38a080e7          	jalr	906(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003850:	40bc                	lw	a5,64(s1)
    80003852:	37fd                	addiw	a5,a5,-1
    80003854:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003856:	00015517          	auipc	a0,0x15
    8000385a:	41250513          	addi	a0,a0,1042 # 80018c68 <bcache>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	428080e7          	jalr	1064(ra) # 80000c86 <release>
}
    80003866:	60e2                	ld	ra,24(sp)
    80003868:	6442                	ld	s0,16(sp)
    8000386a:	64a2                	ld	s1,8(sp)
    8000386c:	6105                	addi	sp,sp,32
    8000386e:	8082                	ret

0000000080003870 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003870:	1101                	addi	sp,sp,-32
    80003872:	ec06                	sd	ra,24(sp)
    80003874:	e822                	sd	s0,16(sp)
    80003876:	e426                	sd	s1,8(sp)
    80003878:	e04a                	sd	s2,0(sp)
    8000387a:	1000                	addi	s0,sp,32
    8000387c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000387e:	00d5d59b          	srliw	a1,a1,0xd
    80003882:	0001e797          	auipc	a5,0x1e
    80003886:	ac27a783          	lw	a5,-1342(a5) # 80021344 <sb+0x1c>
    8000388a:	9dbd                	addw	a1,a1,a5
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	da0080e7          	jalr	-608(ra) # 8000362c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003894:	0074f713          	andi	a4,s1,7
    80003898:	4785                	li	a5,1
    8000389a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000389e:	14ce                	slli	s1,s1,0x33
    800038a0:	90d9                	srli	s1,s1,0x36
    800038a2:	00950733          	add	a4,a0,s1
    800038a6:	05874703          	lbu	a4,88(a4)
    800038aa:	00e7f6b3          	and	a3,a5,a4
    800038ae:	c69d                	beqz	a3,800038dc <bfree+0x6c>
    800038b0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038b2:	94aa                	add	s1,s1,a0
    800038b4:	fff7c793          	not	a5,a5
    800038b8:	8f7d                	and	a4,a4,a5
    800038ba:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800038be:	00001097          	auipc	ra,0x1
    800038c2:	0f6080e7          	jalr	246(ra) # 800049b4 <log_write>
  brelse(bp);
    800038c6:	854a                	mv	a0,s2
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	e94080e7          	jalr	-364(ra) # 8000375c <brelse>
}
    800038d0:	60e2                	ld	ra,24(sp)
    800038d2:	6442                	ld	s0,16(sp)
    800038d4:	64a2                	ld	s1,8(sp)
    800038d6:	6902                	ld	s2,0(sp)
    800038d8:	6105                	addi	sp,sp,32
    800038da:	8082                	ret
    panic("freeing free block");
    800038dc:	00005517          	auipc	a0,0x5
    800038e0:	c8c50513          	addi	a0,a0,-884 # 80008568 <syscalls+0x108>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	c58080e7          	jalr	-936(ra) # 8000053c <panic>

00000000800038ec <balloc>:
{
    800038ec:	711d                	addi	sp,sp,-96
    800038ee:	ec86                	sd	ra,88(sp)
    800038f0:	e8a2                	sd	s0,80(sp)
    800038f2:	e4a6                	sd	s1,72(sp)
    800038f4:	e0ca                	sd	s2,64(sp)
    800038f6:	fc4e                	sd	s3,56(sp)
    800038f8:	f852                	sd	s4,48(sp)
    800038fa:	f456                	sd	s5,40(sp)
    800038fc:	f05a                	sd	s6,32(sp)
    800038fe:	ec5e                	sd	s7,24(sp)
    80003900:	e862                	sd	s8,16(sp)
    80003902:	e466                	sd	s9,8(sp)
    80003904:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003906:	0001e797          	auipc	a5,0x1e
    8000390a:	a267a783          	lw	a5,-1498(a5) # 8002132c <sb+0x4>
    8000390e:	cff5                	beqz	a5,80003a0a <balloc+0x11e>
    80003910:	8baa                	mv	s7,a0
    80003912:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003914:	0001eb17          	auipc	s6,0x1e
    80003918:	a14b0b13          	addi	s6,s6,-1516 # 80021328 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000391c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000391e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003920:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003922:	6c89                	lui	s9,0x2
    80003924:	a061                	j	800039ac <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003926:	97ca                	add	a5,a5,s2
    80003928:	8e55                	or	a2,a2,a3
    8000392a:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000392e:	854a                	mv	a0,s2
    80003930:	00001097          	auipc	ra,0x1
    80003934:	084080e7          	jalr	132(ra) # 800049b4 <log_write>
        brelse(bp);
    80003938:	854a                	mv	a0,s2
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	e22080e7          	jalr	-478(ra) # 8000375c <brelse>
  bp = bread(dev, bno);
    80003942:	85a6                	mv	a1,s1
    80003944:	855e                	mv	a0,s7
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	ce6080e7          	jalr	-794(ra) # 8000362c <bread>
    8000394e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003950:	40000613          	li	a2,1024
    80003954:	4581                	li	a1,0
    80003956:	05850513          	addi	a0,a0,88
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	374080e7          	jalr	884(ra) # 80000cce <memset>
  log_write(bp);
    80003962:	854a                	mv	a0,s2
    80003964:	00001097          	auipc	ra,0x1
    80003968:	050080e7          	jalr	80(ra) # 800049b4 <log_write>
  brelse(bp);
    8000396c:	854a                	mv	a0,s2
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	dee080e7          	jalr	-530(ra) # 8000375c <brelse>
}
    80003976:	8526                	mv	a0,s1
    80003978:	60e6                	ld	ra,88(sp)
    8000397a:	6446                	ld	s0,80(sp)
    8000397c:	64a6                	ld	s1,72(sp)
    8000397e:	6906                	ld	s2,64(sp)
    80003980:	79e2                	ld	s3,56(sp)
    80003982:	7a42                	ld	s4,48(sp)
    80003984:	7aa2                	ld	s5,40(sp)
    80003986:	7b02                	ld	s6,32(sp)
    80003988:	6be2                	ld	s7,24(sp)
    8000398a:	6c42                	ld	s8,16(sp)
    8000398c:	6ca2                	ld	s9,8(sp)
    8000398e:	6125                	addi	sp,sp,96
    80003990:	8082                	ret
    brelse(bp);
    80003992:	854a                	mv	a0,s2
    80003994:	00000097          	auipc	ra,0x0
    80003998:	dc8080e7          	jalr	-568(ra) # 8000375c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000399c:	015c87bb          	addw	a5,s9,s5
    800039a0:	00078a9b          	sext.w	s5,a5
    800039a4:	004b2703          	lw	a4,4(s6)
    800039a8:	06eaf163          	bgeu	s5,a4,80003a0a <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800039ac:	41fad79b          	sraiw	a5,s5,0x1f
    800039b0:	0137d79b          	srliw	a5,a5,0x13
    800039b4:	015787bb          	addw	a5,a5,s5
    800039b8:	40d7d79b          	sraiw	a5,a5,0xd
    800039bc:	01cb2583          	lw	a1,28(s6)
    800039c0:	9dbd                	addw	a1,a1,a5
    800039c2:	855e                	mv	a0,s7
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	c68080e7          	jalr	-920(ra) # 8000362c <bread>
    800039cc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ce:	004b2503          	lw	a0,4(s6)
    800039d2:	000a849b          	sext.w	s1,s5
    800039d6:	8762                	mv	a4,s8
    800039d8:	faa4fde3          	bgeu	s1,a0,80003992 <balloc+0xa6>
      m = 1 << (bi % 8);
    800039dc:	00777693          	andi	a3,a4,7
    800039e0:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800039e4:	41f7579b          	sraiw	a5,a4,0x1f
    800039e8:	01d7d79b          	srliw	a5,a5,0x1d
    800039ec:	9fb9                	addw	a5,a5,a4
    800039ee:	4037d79b          	sraiw	a5,a5,0x3
    800039f2:	00f90633          	add	a2,s2,a5
    800039f6:	05864603          	lbu	a2,88(a2)
    800039fa:	00c6f5b3          	and	a1,a3,a2
    800039fe:	d585                	beqz	a1,80003926 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a00:	2705                	addiw	a4,a4,1
    80003a02:	2485                	addiw	s1,s1,1
    80003a04:	fd471ae3          	bne	a4,s4,800039d8 <balloc+0xec>
    80003a08:	b769                	j	80003992 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003a0a:	00005517          	auipc	a0,0x5
    80003a0e:	b7650513          	addi	a0,a0,-1162 # 80008580 <syscalls+0x120>
    80003a12:	ffffd097          	auipc	ra,0xffffd
    80003a16:	b74080e7          	jalr	-1164(ra) # 80000586 <printf>
  return 0;
    80003a1a:	4481                	li	s1,0
    80003a1c:	bfa9                	j	80003976 <balloc+0x8a>

0000000080003a1e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a1e:	7179                	addi	sp,sp,-48
    80003a20:	f406                	sd	ra,40(sp)
    80003a22:	f022                	sd	s0,32(sp)
    80003a24:	ec26                	sd	s1,24(sp)
    80003a26:	e84a                	sd	s2,16(sp)
    80003a28:	e44e                	sd	s3,8(sp)
    80003a2a:	e052                	sd	s4,0(sp)
    80003a2c:	1800                	addi	s0,sp,48
    80003a2e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a30:	47ad                	li	a5,11
    80003a32:	02b7e863          	bltu	a5,a1,80003a62 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003a36:	02059793          	slli	a5,a1,0x20
    80003a3a:	01e7d593          	srli	a1,a5,0x1e
    80003a3e:	00b504b3          	add	s1,a0,a1
    80003a42:	0504a903          	lw	s2,80(s1)
    80003a46:	06091e63          	bnez	s2,80003ac2 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003a4a:	4108                	lw	a0,0(a0)
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	ea0080e7          	jalr	-352(ra) # 800038ec <balloc>
    80003a54:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a58:	06090563          	beqz	s2,80003ac2 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003a5c:	0524a823          	sw	s2,80(s1)
    80003a60:	a08d                	j	80003ac2 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003a62:	ff45849b          	addiw	s1,a1,-12
    80003a66:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a6a:	0ff00793          	li	a5,255
    80003a6e:	08e7e563          	bltu	a5,a4,80003af8 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003a72:	08052903          	lw	s2,128(a0)
    80003a76:	00091d63          	bnez	s2,80003a90 <bmap+0x72>
      addr = balloc(ip->dev);
    80003a7a:	4108                	lw	a0,0(a0)
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	e70080e7          	jalr	-400(ra) # 800038ec <balloc>
    80003a84:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a88:	02090d63          	beqz	s2,80003ac2 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a8c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a90:	85ca                	mv	a1,s2
    80003a92:	0009a503          	lw	a0,0(s3)
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	b96080e7          	jalr	-1130(ra) # 8000362c <bread>
    80003a9e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003aa0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003aa4:	02049713          	slli	a4,s1,0x20
    80003aa8:	01e75593          	srli	a1,a4,0x1e
    80003aac:	00b784b3          	add	s1,a5,a1
    80003ab0:	0004a903          	lw	s2,0(s1)
    80003ab4:	02090063          	beqz	s2,80003ad4 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003ab8:	8552                	mv	a0,s4
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	ca2080e7          	jalr	-862(ra) # 8000375c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ac2:	854a                	mv	a0,s2
    80003ac4:	70a2                	ld	ra,40(sp)
    80003ac6:	7402                	ld	s0,32(sp)
    80003ac8:	64e2                	ld	s1,24(sp)
    80003aca:	6942                	ld	s2,16(sp)
    80003acc:	69a2                	ld	s3,8(sp)
    80003ace:	6a02                	ld	s4,0(sp)
    80003ad0:	6145                	addi	sp,sp,48
    80003ad2:	8082                	ret
      addr = balloc(ip->dev);
    80003ad4:	0009a503          	lw	a0,0(s3)
    80003ad8:	00000097          	auipc	ra,0x0
    80003adc:	e14080e7          	jalr	-492(ra) # 800038ec <balloc>
    80003ae0:	0005091b          	sext.w	s2,a0
      if(addr){
    80003ae4:	fc090ae3          	beqz	s2,80003ab8 <bmap+0x9a>
        a[bn] = addr;
    80003ae8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003aec:	8552                	mv	a0,s4
    80003aee:	00001097          	auipc	ra,0x1
    80003af2:	ec6080e7          	jalr	-314(ra) # 800049b4 <log_write>
    80003af6:	b7c9                	j	80003ab8 <bmap+0x9a>
  panic("bmap: out of range");
    80003af8:	00005517          	auipc	a0,0x5
    80003afc:	aa050513          	addi	a0,a0,-1376 # 80008598 <syscalls+0x138>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	a3c080e7          	jalr	-1476(ra) # 8000053c <panic>

0000000080003b08 <iget>:
{
    80003b08:	7179                	addi	sp,sp,-48
    80003b0a:	f406                	sd	ra,40(sp)
    80003b0c:	f022                	sd	s0,32(sp)
    80003b0e:	ec26                	sd	s1,24(sp)
    80003b10:	e84a                	sd	s2,16(sp)
    80003b12:	e44e                	sd	s3,8(sp)
    80003b14:	e052                	sd	s4,0(sp)
    80003b16:	1800                	addi	s0,sp,48
    80003b18:	89aa                	mv	s3,a0
    80003b1a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b1c:	0001e517          	auipc	a0,0x1e
    80003b20:	82c50513          	addi	a0,a0,-2004 # 80021348 <itable>
    80003b24:	ffffd097          	auipc	ra,0xffffd
    80003b28:	0ae080e7          	jalr	174(ra) # 80000bd2 <acquire>
  empty = 0;
    80003b2c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b2e:	0001e497          	auipc	s1,0x1e
    80003b32:	83248493          	addi	s1,s1,-1998 # 80021360 <itable+0x18>
    80003b36:	0001f697          	auipc	a3,0x1f
    80003b3a:	2ba68693          	addi	a3,a3,698 # 80022df0 <log>
    80003b3e:	a039                	j	80003b4c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b40:	02090b63          	beqz	s2,80003b76 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b44:	08848493          	addi	s1,s1,136
    80003b48:	02d48a63          	beq	s1,a3,80003b7c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b4c:	449c                	lw	a5,8(s1)
    80003b4e:	fef059e3          	blez	a5,80003b40 <iget+0x38>
    80003b52:	4098                	lw	a4,0(s1)
    80003b54:	ff3716e3          	bne	a4,s3,80003b40 <iget+0x38>
    80003b58:	40d8                	lw	a4,4(s1)
    80003b5a:	ff4713e3          	bne	a4,s4,80003b40 <iget+0x38>
      ip->ref++;
    80003b5e:	2785                	addiw	a5,a5,1
    80003b60:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b62:	0001d517          	auipc	a0,0x1d
    80003b66:	7e650513          	addi	a0,a0,2022 # 80021348 <itable>
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	11c080e7          	jalr	284(ra) # 80000c86 <release>
      return ip;
    80003b72:	8926                	mv	s2,s1
    80003b74:	a03d                	j	80003ba2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b76:	f7f9                	bnez	a5,80003b44 <iget+0x3c>
    80003b78:	8926                	mv	s2,s1
    80003b7a:	b7e9                	j	80003b44 <iget+0x3c>
  if(empty == 0)
    80003b7c:	02090c63          	beqz	s2,80003bb4 <iget+0xac>
  ip->dev = dev;
    80003b80:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b84:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b88:	4785                	li	a5,1
    80003b8a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b8e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b92:	0001d517          	auipc	a0,0x1d
    80003b96:	7b650513          	addi	a0,a0,1974 # 80021348 <itable>
    80003b9a:	ffffd097          	auipc	ra,0xffffd
    80003b9e:	0ec080e7          	jalr	236(ra) # 80000c86 <release>
}
    80003ba2:	854a                	mv	a0,s2
    80003ba4:	70a2                	ld	ra,40(sp)
    80003ba6:	7402                	ld	s0,32(sp)
    80003ba8:	64e2                	ld	s1,24(sp)
    80003baa:	6942                	ld	s2,16(sp)
    80003bac:	69a2                	ld	s3,8(sp)
    80003bae:	6a02                	ld	s4,0(sp)
    80003bb0:	6145                	addi	sp,sp,48
    80003bb2:	8082                	ret
    panic("iget: no inodes");
    80003bb4:	00005517          	auipc	a0,0x5
    80003bb8:	9fc50513          	addi	a0,a0,-1540 # 800085b0 <syscalls+0x150>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	980080e7          	jalr	-1664(ra) # 8000053c <panic>

0000000080003bc4 <fsinit>:
fsinit(int dev) {
    80003bc4:	7179                	addi	sp,sp,-48
    80003bc6:	f406                	sd	ra,40(sp)
    80003bc8:	f022                	sd	s0,32(sp)
    80003bca:	ec26                	sd	s1,24(sp)
    80003bcc:	e84a                	sd	s2,16(sp)
    80003bce:	e44e                	sd	s3,8(sp)
    80003bd0:	1800                	addi	s0,sp,48
    80003bd2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bd4:	4585                	li	a1,1
    80003bd6:	00000097          	auipc	ra,0x0
    80003bda:	a56080e7          	jalr	-1450(ra) # 8000362c <bread>
    80003bde:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003be0:	0001d997          	auipc	s3,0x1d
    80003be4:	74898993          	addi	s3,s3,1864 # 80021328 <sb>
    80003be8:	02000613          	li	a2,32
    80003bec:	05850593          	addi	a1,a0,88
    80003bf0:	854e                	mv	a0,s3
    80003bf2:	ffffd097          	auipc	ra,0xffffd
    80003bf6:	138080e7          	jalr	312(ra) # 80000d2a <memmove>
  brelse(bp);
    80003bfa:	8526                	mv	a0,s1
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	b60080e7          	jalr	-1184(ra) # 8000375c <brelse>
  if(sb.magic != FSMAGIC)
    80003c04:	0009a703          	lw	a4,0(s3)
    80003c08:	102037b7          	lui	a5,0x10203
    80003c0c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c10:	02f71263          	bne	a4,a5,80003c34 <fsinit+0x70>
  initlog(dev, &sb);
    80003c14:	0001d597          	auipc	a1,0x1d
    80003c18:	71458593          	addi	a1,a1,1812 # 80021328 <sb>
    80003c1c:	854a                	mv	a0,s2
    80003c1e:	00001097          	auipc	ra,0x1
    80003c22:	b2c080e7          	jalr	-1236(ra) # 8000474a <initlog>
}
    80003c26:	70a2                	ld	ra,40(sp)
    80003c28:	7402                	ld	s0,32(sp)
    80003c2a:	64e2                	ld	s1,24(sp)
    80003c2c:	6942                	ld	s2,16(sp)
    80003c2e:	69a2                	ld	s3,8(sp)
    80003c30:	6145                	addi	sp,sp,48
    80003c32:	8082                	ret
    panic("invalid file system");
    80003c34:	00005517          	auipc	a0,0x5
    80003c38:	98c50513          	addi	a0,a0,-1652 # 800085c0 <syscalls+0x160>
    80003c3c:	ffffd097          	auipc	ra,0xffffd
    80003c40:	900080e7          	jalr	-1792(ra) # 8000053c <panic>

0000000080003c44 <iinit>:
{
    80003c44:	7179                	addi	sp,sp,-48
    80003c46:	f406                	sd	ra,40(sp)
    80003c48:	f022                	sd	s0,32(sp)
    80003c4a:	ec26                	sd	s1,24(sp)
    80003c4c:	e84a                	sd	s2,16(sp)
    80003c4e:	e44e                	sd	s3,8(sp)
    80003c50:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c52:	00005597          	auipc	a1,0x5
    80003c56:	98658593          	addi	a1,a1,-1658 # 800085d8 <syscalls+0x178>
    80003c5a:	0001d517          	auipc	a0,0x1d
    80003c5e:	6ee50513          	addi	a0,a0,1774 # 80021348 <itable>
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	ee0080e7          	jalr	-288(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c6a:	0001d497          	auipc	s1,0x1d
    80003c6e:	70648493          	addi	s1,s1,1798 # 80021370 <itable+0x28>
    80003c72:	0001f997          	auipc	s3,0x1f
    80003c76:	18e98993          	addi	s3,s3,398 # 80022e00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c7a:	00005917          	auipc	s2,0x5
    80003c7e:	96690913          	addi	s2,s2,-1690 # 800085e0 <syscalls+0x180>
    80003c82:	85ca                	mv	a1,s2
    80003c84:	8526                	mv	a0,s1
    80003c86:	00001097          	auipc	ra,0x1
    80003c8a:	e12080e7          	jalr	-494(ra) # 80004a98 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c8e:	08848493          	addi	s1,s1,136
    80003c92:	ff3498e3          	bne	s1,s3,80003c82 <iinit+0x3e>
}
    80003c96:	70a2                	ld	ra,40(sp)
    80003c98:	7402                	ld	s0,32(sp)
    80003c9a:	64e2                	ld	s1,24(sp)
    80003c9c:	6942                	ld	s2,16(sp)
    80003c9e:	69a2                	ld	s3,8(sp)
    80003ca0:	6145                	addi	sp,sp,48
    80003ca2:	8082                	ret

0000000080003ca4 <ialloc>:
{
    80003ca4:	7139                	addi	sp,sp,-64
    80003ca6:	fc06                	sd	ra,56(sp)
    80003ca8:	f822                	sd	s0,48(sp)
    80003caa:	f426                	sd	s1,40(sp)
    80003cac:	f04a                	sd	s2,32(sp)
    80003cae:	ec4e                	sd	s3,24(sp)
    80003cb0:	e852                	sd	s4,16(sp)
    80003cb2:	e456                	sd	s5,8(sp)
    80003cb4:	e05a                	sd	s6,0(sp)
    80003cb6:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb8:	0001d717          	auipc	a4,0x1d
    80003cbc:	67c72703          	lw	a4,1660(a4) # 80021334 <sb+0xc>
    80003cc0:	4785                	li	a5,1
    80003cc2:	04e7f863          	bgeu	a5,a4,80003d12 <ialloc+0x6e>
    80003cc6:	8aaa                	mv	s5,a0
    80003cc8:	8b2e                	mv	s6,a1
    80003cca:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ccc:	0001da17          	auipc	s4,0x1d
    80003cd0:	65ca0a13          	addi	s4,s4,1628 # 80021328 <sb>
    80003cd4:	00495593          	srli	a1,s2,0x4
    80003cd8:	018a2783          	lw	a5,24(s4)
    80003cdc:	9dbd                	addw	a1,a1,a5
    80003cde:	8556                	mv	a0,s5
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	94c080e7          	jalr	-1716(ra) # 8000362c <bread>
    80003ce8:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003cea:	05850993          	addi	s3,a0,88
    80003cee:	00f97793          	andi	a5,s2,15
    80003cf2:	079a                	slli	a5,a5,0x6
    80003cf4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003cf6:	00099783          	lh	a5,0(s3)
    80003cfa:	cf9d                	beqz	a5,80003d38 <ialloc+0x94>
    brelse(bp);
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	a60080e7          	jalr	-1440(ra) # 8000375c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d04:	0905                	addi	s2,s2,1
    80003d06:	00ca2703          	lw	a4,12(s4)
    80003d0a:	0009079b          	sext.w	a5,s2
    80003d0e:	fce7e3e3          	bltu	a5,a4,80003cd4 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003d12:	00005517          	auipc	a0,0x5
    80003d16:	8d650513          	addi	a0,a0,-1834 # 800085e8 <syscalls+0x188>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	86c080e7          	jalr	-1940(ra) # 80000586 <printf>
  return 0;
    80003d22:	4501                	li	a0,0
}
    80003d24:	70e2                	ld	ra,56(sp)
    80003d26:	7442                	ld	s0,48(sp)
    80003d28:	74a2                	ld	s1,40(sp)
    80003d2a:	7902                	ld	s2,32(sp)
    80003d2c:	69e2                	ld	s3,24(sp)
    80003d2e:	6a42                	ld	s4,16(sp)
    80003d30:	6aa2                	ld	s5,8(sp)
    80003d32:	6b02                	ld	s6,0(sp)
    80003d34:	6121                	addi	sp,sp,64
    80003d36:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003d38:	04000613          	li	a2,64
    80003d3c:	4581                	li	a1,0
    80003d3e:	854e                	mv	a0,s3
    80003d40:	ffffd097          	auipc	ra,0xffffd
    80003d44:	f8e080e7          	jalr	-114(ra) # 80000cce <memset>
      dip->type = type;
    80003d48:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d4c:	8526                	mv	a0,s1
    80003d4e:	00001097          	auipc	ra,0x1
    80003d52:	c66080e7          	jalr	-922(ra) # 800049b4 <log_write>
      brelse(bp);
    80003d56:	8526                	mv	a0,s1
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	a04080e7          	jalr	-1532(ra) # 8000375c <brelse>
      return iget(dev, inum);
    80003d60:	0009059b          	sext.w	a1,s2
    80003d64:	8556                	mv	a0,s5
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	da2080e7          	jalr	-606(ra) # 80003b08 <iget>
    80003d6e:	bf5d                	j	80003d24 <ialloc+0x80>

0000000080003d70 <iupdate>:
{
    80003d70:	1101                	addi	sp,sp,-32
    80003d72:	ec06                	sd	ra,24(sp)
    80003d74:	e822                	sd	s0,16(sp)
    80003d76:	e426                	sd	s1,8(sp)
    80003d78:	e04a                	sd	s2,0(sp)
    80003d7a:	1000                	addi	s0,sp,32
    80003d7c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d7e:	415c                	lw	a5,4(a0)
    80003d80:	0047d79b          	srliw	a5,a5,0x4
    80003d84:	0001d597          	auipc	a1,0x1d
    80003d88:	5bc5a583          	lw	a1,1468(a1) # 80021340 <sb+0x18>
    80003d8c:	9dbd                	addw	a1,a1,a5
    80003d8e:	4108                	lw	a0,0(a0)
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	89c080e7          	jalr	-1892(ra) # 8000362c <bread>
    80003d98:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d9a:	05850793          	addi	a5,a0,88
    80003d9e:	40d8                	lw	a4,4(s1)
    80003da0:	8b3d                	andi	a4,a4,15
    80003da2:	071a                	slli	a4,a4,0x6
    80003da4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003da6:	04449703          	lh	a4,68(s1)
    80003daa:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003dae:	04649703          	lh	a4,70(s1)
    80003db2:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003db6:	04849703          	lh	a4,72(s1)
    80003dba:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003dbe:	04a49703          	lh	a4,74(s1)
    80003dc2:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003dc6:	44f8                	lw	a4,76(s1)
    80003dc8:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003dca:	03400613          	li	a2,52
    80003dce:	05048593          	addi	a1,s1,80
    80003dd2:	00c78513          	addi	a0,a5,12
    80003dd6:	ffffd097          	auipc	ra,0xffffd
    80003dda:	f54080e7          	jalr	-172(ra) # 80000d2a <memmove>
  log_write(bp);
    80003dde:	854a                	mv	a0,s2
    80003de0:	00001097          	auipc	ra,0x1
    80003de4:	bd4080e7          	jalr	-1068(ra) # 800049b4 <log_write>
  brelse(bp);
    80003de8:	854a                	mv	a0,s2
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	972080e7          	jalr	-1678(ra) # 8000375c <brelse>
}
    80003df2:	60e2                	ld	ra,24(sp)
    80003df4:	6442                	ld	s0,16(sp)
    80003df6:	64a2                	ld	s1,8(sp)
    80003df8:	6902                	ld	s2,0(sp)
    80003dfa:	6105                	addi	sp,sp,32
    80003dfc:	8082                	ret

0000000080003dfe <idup>:
{
    80003dfe:	1101                	addi	sp,sp,-32
    80003e00:	ec06                	sd	ra,24(sp)
    80003e02:	e822                	sd	s0,16(sp)
    80003e04:	e426                	sd	s1,8(sp)
    80003e06:	1000                	addi	s0,sp,32
    80003e08:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e0a:	0001d517          	auipc	a0,0x1d
    80003e0e:	53e50513          	addi	a0,a0,1342 # 80021348 <itable>
    80003e12:	ffffd097          	auipc	ra,0xffffd
    80003e16:	dc0080e7          	jalr	-576(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003e1a:	449c                	lw	a5,8(s1)
    80003e1c:	2785                	addiw	a5,a5,1
    80003e1e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e20:	0001d517          	auipc	a0,0x1d
    80003e24:	52850513          	addi	a0,a0,1320 # 80021348 <itable>
    80003e28:	ffffd097          	auipc	ra,0xffffd
    80003e2c:	e5e080e7          	jalr	-418(ra) # 80000c86 <release>
}
    80003e30:	8526                	mv	a0,s1
    80003e32:	60e2                	ld	ra,24(sp)
    80003e34:	6442                	ld	s0,16(sp)
    80003e36:	64a2                	ld	s1,8(sp)
    80003e38:	6105                	addi	sp,sp,32
    80003e3a:	8082                	ret

0000000080003e3c <ilock>:
{
    80003e3c:	1101                	addi	sp,sp,-32
    80003e3e:	ec06                	sd	ra,24(sp)
    80003e40:	e822                	sd	s0,16(sp)
    80003e42:	e426                	sd	s1,8(sp)
    80003e44:	e04a                	sd	s2,0(sp)
    80003e46:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e48:	c115                	beqz	a0,80003e6c <ilock+0x30>
    80003e4a:	84aa                	mv	s1,a0
    80003e4c:	451c                	lw	a5,8(a0)
    80003e4e:	00f05f63          	blez	a5,80003e6c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e52:	0541                	addi	a0,a0,16
    80003e54:	00001097          	auipc	ra,0x1
    80003e58:	c7e080e7          	jalr	-898(ra) # 80004ad2 <acquiresleep>
  if(ip->valid == 0){
    80003e5c:	40bc                	lw	a5,64(s1)
    80003e5e:	cf99                	beqz	a5,80003e7c <ilock+0x40>
}
    80003e60:	60e2                	ld	ra,24(sp)
    80003e62:	6442                	ld	s0,16(sp)
    80003e64:	64a2                	ld	s1,8(sp)
    80003e66:	6902                	ld	s2,0(sp)
    80003e68:	6105                	addi	sp,sp,32
    80003e6a:	8082                	ret
    panic("ilock");
    80003e6c:	00004517          	auipc	a0,0x4
    80003e70:	79450513          	addi	a0,a0,1940 # 80008600 <syscalls+0x1a0>
    80003e74:	ffffc097          	auipc	ra,0xffffc
    80003e78:	6c8080e7          	jalr	1736(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e7c:	40dc                	lw	a5,4(s1)
    80003e7e:	0047d79b          	srliw	a5,a5,0x4
    80003e82:	0001d597          	auipc	a1,0x1d
    80003e86:	4be5a583          	lw	a1,1214(a1) # 80021340 <sb+0x18>
    80003e8a:	9dbd                	addw	a1,a1,a5
    80003e8c:	4088                	lw	a0,0(s1)
    80003e8e:	fffff097          	auipc	ra,0xfffff
    80003e92:	79e080e7          	jalr	1950(ra) # 8000362c <bread>
    80003e96:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e98:	05850593          	addi	a1,a0,88
    80003e9c:	40dc                	lw	a5,4(s1)
    80003e9e:	8bbd                	andi	a5,a5,15
    80003ea0:	079a                	slli	a5,a5,0x6
    80003ea2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ea4:	00059783          	lh	a5,0(a1)
    80003ea8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003eac:	00259783          	lh	a5,2(a1)
    80003eb0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003eb4:	00459783          	lh	a5,4(a1)
    80003eb8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ebc:	00659783          	lh	a5,6(a1)
    80003ec0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ec4:	459c                	lw	a5,8(a1)
    80003ec6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ec8:	03400613          	li	a2,52
    80003ecc:	05b1                	addi	a1,a1,12
    80003ece:	05048513          	addi	a0,s1,80
    80003ed2:	ffffd097          	auipc	ra,0xffffd
    80003ed6:	e58080e7          	jalr	-424(ra) # 80000d2a <memmove>
    brelse(bp);
    80003eda:	854a                	mv	a0,s2
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	880080e7          	jalr	-1920(ra) # 8000375c <brelse>
    ip->valid = 1;
    80003ee4:	4785                	li	a5,1
    80003ee6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ee8:	04449783          	lh	a5,68(s1)
    80003eec:	fbb5                	bnez	a5,80003e60 <ilock+0x24>
      panic("ilock: no type");
    80003eee:	00004517          	auipc	a0,0x4
    80003ef2:	71a50513          	addi	a0,a0,1818 # 80008608 <syscalls+0x1a8>
    80003ef6:	ffffc097          	auipc	ra,0xffffc
    80003efa:	646080e7          	jalr	1606(ra) # 8000053c <panic>

0000000080003efe <iunlock>:
{
    80003efe:	1101                	addi	sp,sp,-32
    80003f00:	ec06                	sd	ra,24(sp)
    80003f02:	e822                	sd	s0,16(sp)
    80003f04:	e426                	sd	s1,8(sp)
    80003f06:	e04a                	sd	s2,0(sp)
    80003f08:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f0a:	c905                	beqz	a0,80003f3a <iunlock+0x3c>
    80003f0c:	84aa                	mv	s1,a0
    80003f0e:	01050913          	addi	s2,a0,16
    80003f12:	854a                	mv	a0,s2
    80003f14:	00001097          	auipc	ra,0x1
    80003f18:	c58080e7          	jalr	-936(ra) # 80004b6c <holdingsleep>
    80003f1c:	cd19                	beqz	a0,80003f3a <iunlock+0x3c>
    80003f1e:	449c                	lw	a5,8(s1)
    80003f20:	00f05d63          	blez	a5,80003f3a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f24:	854a                	mv	a0,s2
    80003f26:	00001097          	auipc	ra,0x1
    80003f2a:	c02080e7          	jalr	-1022(ra) # 80004b28 <releasesleep>
}
    80003f2e:	60e2                	ld	ra,24(sp)
    80003f30:	6442                	ld	s0,16(sp)
    80003f32:	64a2                	ld	s1,8(sp)
    80003f34:	6902                	ld	s2,0(sp)
    80003f36:	6105                	addi	sp,sp,32
    80003f38:	8082                	ret
    panic("iunlock");
    80003f3a:	00004517          	auipc	a0,0x4
    80003f3e:	6de50513          	addi	a0,a0,1758 # 80008618 <syscalls+0x1b8>
    80003f42:	ffffc097          	auipc	ra,0xffffc
    80003f46:	5fa080e7          	jalr	1530(ra) # 8000053c <panic>

0000000080003f4a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f4a:	7179                	addi	sp,sp,-48
    80003f4c:	f406                	sd	ra,40(sp)
    80003f4e:	f022                	sd	s0,32(sp)
    80003f50:	ec26                	sd	s1,24(sp)
    80003f52:	e84a                	sd	s2,16(sp)
    80003f54:	e44e                	sd	s3,8(sp)
    80003f56:	e052                	sd	s4,0(sp)
    80003f58:	1800                	addi	s0,sp,48
    80003f5a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f5c:	05050493          	addi	s1,a0,80
    80003f60:	08050913          	addi	s2,a0,128
    80003f64:	a021                	j	80003f6c <itrunc+0x22>
    80003f66:	0491                	addi	s1,s1,4
    80003f68:	01248d63          	beq	s1,s2,80003f82 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f6c:	408c                	lw	a1,0(s1)
    80003f6e:	dde5                	beqz	a1,80003f66 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f70:	0009a503          	lw	a0,0(s3)
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	8fc080e7          	jalr	-1796(ra) # 80003870 <bfree>
      ip->addrs[i] = 0;
    80003f7c:	0004a023          	sw	zero,0(s1)
    80003f80:	b7dd                	j	80003f66 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f82:	0809a583          	lw	a1,128(s3)
    80003f86:	e185                	bnez	a1,80003fa6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f88:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f8c:	854e                	mv	a0,s3
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	de2080e7          	jalr	-542(ra) # 80003d70 <iupdate>
}
    80003f96:	70a2                	ld	ra,40(sp)
    80003f98:	7402                	ld	s0,32(sp)
    80003f9a:	64e2                	ld	s1,24(sp)
    80003f9c:	6942                	ld	s2,16(sp)
    80003f9e:	69a2                	ld	s3,8(sp)
    80003fa0:	6a02                	ld	s4,0(sp)
    80003fa2:	6145                	addi	sp,sp,48
    80003fa4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003fa6:	0009a503          	lw	a0,0(s3)
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	682080e7          	jalr	1666(ra) # 8000362c <bread>
    80003fb2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003fb4:	05850493          	addi	s1,a0,88
    80003fb8:	45850913          	addi	s2,a0,1112
    80003fbc:	a021                	j	80003fc4 <itrunc+0x7a>
    80003fbe:	0491                	addi	s1,s1,4
    80003fc0:	01248b63          	beq	s1,s2,80003fd6 <itrunc+0x8c>
      if(a[j])
    80003fc4:	408c                	lw	a1,0(s1)
    80003fc6:	dde5                	beqz	a1,80003fbe <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003fc8:	0009a503          	lw	a0,0(s3)
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	8a4080e7          	jalr	-1884(ra) # 80003870 <bfree>
    80003fd4:	b7ed                	j	80003fbe <itrunc+0x74>
    brelse(bp);
    80003fd6:	8552                	mv	a0,s4
    80003fd8:	fffff097          	auipc	ra,0xfffff
    80003fdc:	784080e7          	jalr	1924(ra) # 8000375c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fe0:	0809a583          	lw	a1,128(s3)
    80003fe4:	0009a503          	lw	a0,0(s3)
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	888080e7          	jalr	-1912(ra) # 80003870 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ff0:	0809a023          	sw	zero,128(s3)
    80003ff4:	bf51                	j	80003f88 <itrunc+0x3e>

0000000080003ff6 <iput>:
{
    80003ff6:	1101                	addi	sp,sp,-32
    80003ff8:	ec06                	sd	ra,24(sp)
    80003ffa:	e822                	sd	s0,16(sp)
    80003ffc:	e426                	sd	s1,8(sp)
    80003ffe:	e04a                	sd	s2,0(sp)
    80004000:	1000                	addi	s0,sp,32
    80004002:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004004:	0001d517          	auipc	a0,0x1d
    80004008:	34450513          	addi	a0,a0,836 # 80021348 <itable>
    8000400c:	ffffd097          	auipc	ra,0xffffd
    80004010:	bc6080e7          	jalr	-1082(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004014:	4498                	lw	a4,8(s1)
    80004016:	4785                	li	a5,1
    80004018:	02f70363          	beq	a4,a5,8000403e <iput+0x48>
  ip->ref--;
    8000401c:	449c                	lw	a5,8(s1)
    8000401e:	37fd                	addiw	a5,a5,-1
    80004020:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004022:	0001d517          	auipc	a0,0x1d
    80004026:	32650513          	addi	a0,a0,806 # 80021348 <itable>
    8000402a:	ffffd097          	auipc	ra,0xffffd
    8000402e:	c5c080e7          	jalr	-932(ra) # 80000c86 <release>
}
    80004032:	60e2                	ld	ra,24(sp)
    80004034:	6442                	ld	s0,16(sp)
    80004036:	64a2                	ld	s1,8(sp)
    80004038:	6902                	ld	s2,0(sp)
    8000403a:	6105                	addi	sp,sp,32
    8000403c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000403e:	40bc                	lw	a5,64(s1)
    80004040:	dff1                	beqz	a5,8000401c <iput+0x26>
    80004042:	04a49783          	lh	a5,74(s1)
    80004046:	fbf9                	bnez	a5,8000401c <iput+0x26>
    acquiresleep(&ip->lock);
    80004048:	01048913          	addi	s2,s1,16
    8000404c:	854a                	mv	a0,s2
    8000404e:	00001097          	auipc	ra,0x1
    80004052:	a84080e7          	jalr	-1404(ra) # 80004ad2 <acquiresleep>
    release(&itable.lock);
    80004056:	0001d517          	auipc	a0,0x1d
    8000405a:	2f250513          	addi	a0,a0,754 # 80021348 <itable>
    8000405e:	ffffd097          	auipc	ra,0xffffd
    80004062:	c28080e7          	jalr	-984(ra) # 80000c86 <release>
    itrunc(ip);
    80004066:	8526                	mv	a0,s1
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	ee2080e7          	jalr	-286(ra) # 80003f4a <itrunc>
    ip->type = 0;
    80004070:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004074:	8526                	mv	a0,s1
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	cfa080e7          	jalr	-774(ra) # 80003d70 <iupdate>
    ip->valid = 0;
    8000407e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004082:	854a                	mv	a0,s2
    80004084:	00001097          	auipc	ra,0x1
    80004088:	aa4080e7          	jalr	-1372(ra) # 80004b28 <releasesleep>
    acquire(&itable.lock);
    8000408c:	0001d517          	auipc	a0,0x1d
    80004090:	2bc50513          	addi	a0,a0,700 # 80021348 <itable>
    80004094:	ffffd097          	auipc	ra,0xffffd
    80004098:	b3e080e7          	jalr	-1218(ra) # 80000bd2 <acquire>
    8000409c:	b741                	j	8000401c <iput+0x26>

000000008000409e <iunlockput>:
{
    8000409e:	1101                	addi	sp,sp,-32
    800040a0:	ec06                	sd	ra,24(sp)
    800040a2:	e822                	sd	s0,16(sp)
    800040a4:	e426                	sd	s1,8(sp)
    800040a6:	1000                	addi	s0,sp,32
    800040a8:	84aa                	mv	s1,a0
  iunlock(ip);
    800040aa:	00000097          	auipc	ra,0x0
    800040ae:	e54080e7          	jalr	-428(ra) # 80003efe <iunlock>
  iput(ip);
    800040b2:	8526                	mv	a0,s1
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	f42080e7          	jalr	-190(ra) # 80003ff6 <iput>
}
    800040bc:	60e2                	ld	ra,24(sp)
    800040be:	6442                	ld	s0,16(sp)
    800040c0:	64a2                	ld	s1,8(sp)
    800040c2:	6105                	addi	sp,sp,32
    800040c4:	8082                	ret

00000000800040c6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040c6:	1141                	addi	sp,sp,-16
    800040c8:	e422                	sd	s0,8(sp)
    800040ca:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040cc:	411c                	lw	a5,0(a0)
    800040ce:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040d0:	415c                	lw	a5,4(a0)
    800040d2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040d4:	04451783          	lh	a5,68(a0)
    800040d8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040dc:	04a51783          	lh	a5,74(a0)
    800040e0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040e4:	04c56783          	lwu	a5,76(a0)
    800040e8:	e99c                	sd	a5,16(a1)
}
    800040ea:	6422                	ld	s0,8(sp)
    800040ec:	0141                	addi	sp,sp,16
    800040ee:	8082                	ret

00000000800040f0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040f0:	457c                	lw	a5,76(a0)
    800040f2:	0ed7e963          	bltu	a5,a3,800041e4 <readi+0xf4>
{
    800040f6:	7159                	addi	sp,sp,-112
    800040f8:	f486                	sd	ra,104(sp)
    800040fa:	f0a2                	sd	s0,96(sp)
    800040fc:	eca6                	sd	s1,88(sp)
    800040fe:	e8ca                	sd	s2,80(sp)
    80004100:	e4ce                	sd	s3,72(sp)
    80004102:	e0d2                	sd	s4,64(sp)
    80004104:	fc56                	sd	s5,56(sp)
    80004106:	f85a                	sd	s6,48(sp)
    80004108:	f45e                	sd	s7,40(sp)
    8000410a:	f062                	sd	s8,32(sp)
    8000410c:	ec66                	sd	s9,24(sp)
    8000410e:	e86a                	sd	s10,16(sp)
    80004110:	e46e                	sd	s11,8(sp)
    80004112:	1880                	addi	s0,sp,112
    80004114:	8b2a                	mv	s6,a0
    80004116:	8bae                	mv	s7,a1
    80004118:	8a32                	mv	s4,a2
    8000411a:	84b6                	mv	s1,a3
    8000411c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000411e:	9f35                	addw	a4,a4,a3
    return 0;
    80004120:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004122:	0ad76063          	bltu	a4,a3,800041c2 <readi+0xd2>
  if(off + n > ip->size)
    80004126:	00e7f463          	bgeu	a5,a4,8000412e <readi+0x3e>
    n = ip->size - off;
    8000412a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000412e:	0a0a8963          	beqz	s5,800041e0 <readi+0xf0>
    80004132:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004134:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004138:	5c7d                	li	s8,-1
    8000413a:	a82d                	j	80004174 <readi+0x84>
    8000413c:	020d1d93          	slli	s11,s10,0x20
    80004140:	020ddd93          	srli	s11,s11,0x20
    80004144:	05890613          	addi	a2,s2,88
    80004148:	86ee                	mv	a3,s11
    8000414a:	963a                	add	a2,a2,a4
    8000414c:	85d2                	mv	a1,s4
    8000414e:	855e                	mv	a0,s7
    80004150:	ffffe097          	auipc	ra,0xffffe
    80004154:	644080e7          	jalr	1604(ra) # 80002794 <either_copyout>
    80004158:	05850d63          	beq	a0,s8,800041b2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000415c:	854a                	mv	a0,s2
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	5fe080e7          	jalr	1534(ra) # 8000375c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004166:	013d09bb          	addw	s3,s10,s3
    8000416a:	009d04bb          	addw	s1,s10,s1
    8000416e:	9a6e                	add	s4,s4,s11
    80004170:	0559f763          	bgeu	s3,s5,800041be <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004174:	00a4d59b          	srliw	a1,s1,0xa
    80004178:	855a                	mv	a0,s6
    8000417a:	00000097          	auipc	ra,0x0
    8000417e:	8a4080e7          	jalr	-1884(ra) # 80003a1e <bmap>
    80004182:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004186:	cd85                	beqz	a1,800041be <readi+0xce>
    bp = bread(ip->dev, addr);
    80004188:	000b2503          	lw	a0,0(s6)
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	4a0080e7          	jalr	1184(ra) # 8000362c <bread>
    80004194:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004196:	3ff4f713          	andi	a4,s1,1023
    8000419a:	40ec87bb          	subw	a5,s9,a4
    8000419e:	413a86bb          	subw	a3,s5,s3
    800041a2:	8d3e                	mv	s10,a5
    800041a4:	2781                	sext.w	a5,a5
    800041a6:	0006861b          	sext.w	a2,a3
    800041aa:	f8f679e3          	bgeu	a2,a5,8000413c <readi+0x4c>
    800041ae:	8d36                	mv	s10,a3
    800041b0:	b771                	j	8000413c <readi+0x4c>
      brelse(bp);
    800041b2:	854a                	mv	a0,s2
    800041b4:	fffff097          	auipc	ra,0xfffff
    800041b8:	5a8080e7          	jalr	1448(ra) # 8000375c <brelse>
      tot = -1;
    800041bc:	59fd                	li	s3,-1
  }
  return tot;
    800041be:	0009851b          	sext.w	a0,s3
}
    800041c2:	70a6                	ld	ra,104(sp)
    800041c4:	7406                	ld	s0,96(sp)
    800041c6:	64e6                	ld	s1,88(sp)
    800041c8:	6946                	ld	s2,80(sp)
    800041ca:	69a6                	ld	s3,72(sp)
    800041cc:	6a06                	ld	s4,64(sp)
    800041ce:	7ae2                	ld	s5,56(sp)
    800041d0:	7b42                	ld	s6,48(sp)
    800041d2:	7ba2                	ld	s7,40(sp)
    800041d4:	7c02                	ld	s8,32(sp)
    800041d6:	6ce2                	ld	s9,24(sp)
    800041d8:	6d42                	ld	s10,16(sp)
    800041da:	6da2                	ld	s11,8(sp)
    800041dc:	6165                	addi	sp,sp,112
    800041de:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041e0:	89d6                	mv	s3,s5
    800041e2:	bff1                	j	800041be <readi+0xce>
    return 0;
    800041e4:	4501                	li	a0,0
}
    800041e6:	8082                	ret

00000000800041e8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041e8:	457c                	lw	a5,76(a0)
    800041ea:	10d7e863          	bltu	a5,a3,800042fa <writei+0x112>
{
    800041ee:	7159                	addi	sp,sp,-112
    800041f0:	f486                	sd	ra,104(sp)
    800041f2:	f0a2                	sd	s0,96(sp)
    800041f4:	eca6                	sd	s1,88(sp)
    800041f6:	e8ca                	sd	s2,80(sp)
    800041f8:	e4ce                	sd	s3,72(sp)
    800041fa:	e0d2                	sd	s4,64(sp)
    800041fc:	fc56                	sd	s5,56(sp)
    800041fe:	f85a                	sd	s6,48(sp)
    80004200:	f45e                	sd	s7,40(sp)
    80004202:	f062                	sd	s8,32(sp)
    80004204:	ec66                	sd	s9,24(sp)
    80004206:	e86a                	sd	s10,16(sp)
    80004208:	e46e                	sd	s11,8(sp)
    8000420a:	1880                	addi	s0,sp,112
    8000420c:	8aaa                	mv	s5,a0
    8000420e:	8bae                	mv	s7,a1
    80004210:	8a32                	mv	s4,a2
    80004212:	8936                	mv	s2,a3
    80004214:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004216:	00e687bb          	addw	a5,a3,a4
    8000421a:	0ed7e263          	bltu	a5,a3,800042fe <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000421e:	00043737          	lui	a4,0x43
    80004222:	0ef76063          	bltu	a4,a5,80004302 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004226:	0c0b0863          	beqz	s6,800042f6 <writei+0x10e>
    8000422a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000422c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004230:	5c7d                	li	s8,-1
    80004232:	a091                	j	80004276 <writei+0x8e>
    80004234:	020d1d93          	slli	s11,s10,0x20
    80004238:	020ddd93          	srli	s11,s11,0x20
    8000423c:	05848513          	addi	a0,s1,88
    80004240:	86ee                	mv	a3,s11
    80004242:	8652                	mv	a2,s4
    80004244:	85de                	mv	a1,s7
    80004246:	953a                	add	a0,a0,a4
    80004248:	ffffe097          	auipc	ra,0xffffe
    8000424c:	5a2080e7          	jalr	1442(ra) # 800027ea <either_copyin>
    80004250:	07850263          	beq	a0,s8,800042b4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004254:	8526                	mv	a0,s1
    80004256:	00000097          	auipc	ra,0x0
    8000425a:	75e080e7          	jalr	1886(ra) # 800049b4 <log_write>
    brelse(bp);
    8000425e:	8526                	mv	a0,s1
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	4fc080e7          	jalr	1276(ra) # 8000375c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004268:	013d09bb          	addw	s3,s10,s3
    8000426c:	012d093b          	addw	s2,s10,s2
    80004270:	9a6e                	add	s4,s4,s11
    80004272:	0569f663          	bgeu	s3,s6,800042be <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004276:	00a9559b          	srliw	a1,s2,0xa
    8000427a:	8556                	mv	a0,s5
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	7a2080e7          	jalr	1954(ra) # 80003a1e <bmap>
    80004284:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004288:	c99d                	beqz	a1,800042be <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000428a:	000aa503          	lw	a0,0(s5)
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	39e080e7          	jalr	926(ra) # 8000362c <bread>
    80004296:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004298:	3ff97713          	andi	a4,s2,1023
    8000429c:	40ec87bb          	subw	a5,s9,a4
    800042a0:	413b06bb          	subw	a3,s6,s3
    800042a4:	8d3e                	mv	s10,a5
    800042a6:	2781                	sext.w	a5,a5
    800042a8:	0006861b          	sext.w	a2,a3
    800042ac:	f8f674e3          	bgeu	a2,a5,80004234 <writei+0x4c>
    800042b0:	8d36                	mv	s10,a3
    800042b2:	b749                	j	80004234 <writei+0x4c>
      brelse(bp);
    800042b4:	8526                	mv	a0,s1
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	4a6080e7          	jalr	1190(ra) # 8000375c <brelse>
  }

  if(off > ip->size)
    800042be:	04caa783          	lw	a5,76(s5)
    800042c2:	0127f463          	bgeu	a5,s2,800042ca <writei+0xe2>
    ip->size = off;
    800042c6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042ca:	8556                	mv	a0,s5
    800042cc:	00000097          	auipc	ra,0x0
    800042d0:	aa4080e7          	jalr	-1372(ra) # 80003d70 <iupdate>

  return tot;
    800042d4:	0009851b          	sext.w	a0,s3
}
    800042d8:	70a6                	ld	ra,104(sp)
    800042da:	7406                	ld	s0,96(sp)
    800042dc:	64e6                	ld	s1,88(sp)
    800042de:	6946                	ld	s2,80(sp)
    800042e0:	69a6                	ld	s3,72(sp)
    800042e2:	6a06                	ld	s4,64(sp)
    800042e4:	7ae2                	ld	s5,56(sp)
    800042e6:	7b42                	ld	s6,48(sp)
    800042e8:	7ba2                	ld	s7,40(sp)
    800042ea:	7c02                	ld	s8,32(sp)
    800042ec:	6ce2                	ld	s9,24(sp)
    800042ee:	6d42                	ld	s10,16(sp)
    800042f0:	6da2                	ld	s11,8(sp)
    800042f2:	6165                	addi	sp,sp,112
    800042f4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042f6:	89da                	mv	s3,s6
    800042f8:	bfc9                	j	800042ca <writei+0xe2>
    return -1;
    800042fa:	557d                	li	a0,-1
}
    800042fc:	8082                	ret
    return -1;
    800042fe:	557d                	li	a0,-1
    80004300:	bfe1                	j	800042d8 <writei+0xf0>
    return -1;
    80004302:	557d                	li	a0,-1
    80004304:	bfd1                	j	800042d8 <writei+0xf0>

0000000080004306 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004306:	1141                	addi	sp,sp,-16
    80004308:	e406                	sd	ra,8(sp)
    8000430a:	e022                	sd	s0,0(sp)
    8000430c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000430e:	4639                	li	a2,14
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	a8e080e7          	jalr	-1394(ra) # 80000d9e <strncmp>
}
    80004318:	60a2                	ld	ra,8(sp)
    8000431a:	6402                	ld	s0,0(sp)
    8000431c:	0141                	addi	sp,sp,16
    8000431e:	8082                	ret

0000000080004320 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004320:	7139                	addi	sp,sp,-64
    80004322:	fc06                	sd	ra,56(sp)
    80004324:	f822                	sd	s0,48(sp)
    80004326:	f426                	sd	s1,40(sp)
    80004328:	f04a                	sd	s2,32(sp)
    8000432a:	ec4e                	sd	s3,24(sp)
    8000432c:	e852                	sd	s4,16(sp)
    8000432e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004330:	04451703          	lh	a4,68(a0)
    80004334:	4785                	li	a5,1
    80004336:	00f71a63          	bne	a4,a5,8000434a <dirlookup+0x2a>
    8000433a:	892a                	mv	s2,a0
    8000433c:	89ae                	mv	s3,a1
    8000433e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004340:	457c                	lw	a5,76(a0)
    80004342:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004344:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004346:	e79d                	bnez	a5,80004374 <dirlookup+0x54>
    80004348:	a8a5                	j	800043c0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000434a:	00004517          	auipc	a0,0x4
    8000434e:	2d650513          	addi	a0,a0,726 # 80008620 <syscalls+0x1c0>
    80004352:	ffffc097          	auipc	ra,0xffffc
    80004356:	1ea080e7          	jalr	490(ra) # 8000053c <panic>
      panic("dirlookup read");
    8000435a:	00004517          	auipc	a0,0x4
    8000435e:	2de50513          	addi	a0,a0,734 # 80008638 <syscalls+0x1d8>
    80004362:	ffffc097          	auipc	ra,0xffffc
    80004366:	1da080e7          	jalr	474(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000436a:	24c1                	addiw	s1,s1,16
    8000436c:	04c92783          	lw	a5,76(s2)
    80004370:	04f4f763          	bgeu	s1,a5,800043be <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004374:	4741                	li	a4,16
    80004376:	86a6                	mv	a3,s1
    80004378:	fc040613          	addi	a2,s0,-64
    8000437c:	4581                	li	a1,0
    8000437e:	854a                	mv	a0,s2
    80004380:	00000097          	auipc	ra,0x0
    80004384:	d70080e7          	jalr	-656(ra) # 800040f0 <readi>
    80004388:	47c1                	li	a5,16
    8000438a:	fcf518e3          	bne	a0,a5,8000435a <dirlookup+0x3a>
    if(de.inum == 0)
    8000438e:	fc045783          	lhu	a5,-64(s0)
    80004392:	dfe1                	beqz	a5,8000436a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004394:	fc240593          	addi	a1,s0,-62
    80004398:	854e                	mv	a0,s3
    8000439a:	00000097          	auipc	ra,0x0
    8000439e:	f6c080e7          	jalr	-148(ra) # 80004306 <namecmp>
    800043a2:	f561                	bnez	a0,8000436a <dirlookup+0x4a>
      if(poff)
    800043a4:	000a0463          	beqz	s4,800043ac <dirlookup+0x8c>
        *poff = off;
    800043a8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043ac:	fc045583          	lhu	a1,-64(s0)
    800043b0:	00092503          	lw	a0,0(s2)
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	754080e7          	jalr	1876(ra) # 80003b08 <iget>
    800043bc:	a011                	j	800043c0 <dirlookup+0xa0>
  return 0;
    800043be:	4501                	li	a0,0
}
    800043c0:	70e2                	ld	ra,56(sp)
    800043c2:	7442                	ld	s0,48(sp)
    800043c4:	74a2                	ld	s1,40(sp)
    800043c6:	7902                	ld	s2,32(sp)
    800043c8:	69e2                	ld	s3,24(sp)
    800043ca:	6a42                	ld	s4,16(sp)
    800043cc:	6121                	addi	sp,sp,64
    800043ce:	8082                	ret

00000000800043d0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043d0:	711d                	addi	sp,sp,-96
    800043d2:	ec86                	sd	ra,88(sp)
    800043d4:	e8a2                	sd	s0,80(sp)
    800043d6:	e4a6                	sd	s1,72(sp)
    800043d8:	e0ca                	sd	s2,64(sp)
    800043da:	fc4e                	sd	s3,56(sp)
    800043dc:	f852                	sd	s4,48(sp)
    800043de:	f456                	sd	s5,40(sp)
    800043e0:	f05a                	sd	s6,32(sp)
    800043e2:	ec5e                	sd	s7,24(sp)
    800043e4:	e862                	sd	s8,16(sp)
    800043e6:	e466                	sd	s9,8(sp)
    800043e8:	1080                	addi	s0,sp,96
    800043ea:	84aa                	mv	s1,a0
    800043ec:	8b2e                	mv	s6,a1
    800043ee:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043f0:	00054703          	lbu	a4,0(a0)
    800043f4:	02f00793          	li	a5,47
    800043f8:	02f70263          	beq	a4,a5,8000441c <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	5da080e7          	jalr	1498(ra) # 800019d6 <myproc>
    80004404:	15053503          	ld	a0,336(a0)
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	9f6080e7          	jalr	-1546(ra) # 80003dfe <idup>
    80004410:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004412:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004416:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004418:	4b85                	li	s7,1
    8000441a:	a875                	j	800044d6 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000441c:	4585                	li	a1,1
    8000441e:	4505                	li	a0,1
    80004420:	fffff097          	auipc	ra,0xfffff
    80004424:	6e8080e7          	jalr	1768(ra) # 80003b08 <iget>
    80004428:	8a2a                	mv	s4,a0
    8000442a:	b7e5                	j	80004412 <namex+0x42>
      iunlockput(ip);
    8000442c:	8552                	mv	a0,s4
    8000442e:	00000097          	auipc	ra,0x0
    80004432:	c70080e7          	jalr	-912(ra) # 8000409e <iunlockput>
      return 0;
    80004436:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004438:	8552                	mv	a0,s4
    8000443a:	60e6                	ld	ra,88(sp)
    8000443c:	6446                	ld	s0,80(sp)
    8000443e:	64a6                	ld	s1,72(sp)
    80004440:	6906                	ld	s2,64(sp)
    80004442:	79e2                	ld	s3,56(sp)
    80004444:	7a42                	ld	s4,48(sp)
    80004446:	7aa2                	ld	s5,40(sp)
    80004448:	7b02                	ld	s6,32(sp)
    8000444a:	6be2                	ld	s7,24(sp)
    8000444c:	6c42                	ld	s8,16(sp)
    8000444e:	6ca2                	ld	s9,8(sp)
    80004450:	6125                	addi	sp,sp,96
    80004452:	8082                	ret
      iunlock(ip);
    80004454:	8552                	mv	a0,s4
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	aa8080e7          	jalr	-1368(ra) # 80003efe <iunlock>
      return ip;
    8000445e:	bfe9                	j	80004438 <namex+0x68>
      iunlockput(ip);
    80004460:	8552                	mv	a0,s4
    80004462:	00000097          	auipc	ra,0x0
    80004466:	c3c080e7          	jalr	-964(ra) # 8000409e <iunlockput>
      return 0;
    8000446a:	8a4e                	mv	s4,s3
    8000446c:	b7f1                	j	80004438 <namex+0x68>
  len = path - s;
    8000446e:	40998633          	sub	a2,s3,s1
    80004472:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004476:	099c5863          	bge	s8,s9,80004506 <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000447a:	4639                	li	a2,14
    8000447c:	85a6                	mv	a1,s1
    8000447e:	8556                	mv	a0,s5
    80004480:	ffffd097          	auipc	ra,0xffffd
    80004484:	8aa080e7          	jalr	-1878(ra) # 80000d2a <memmove>
    80004488:	84ce                	mv	s1,s3
  while(*path == '/')
    8000448a:	0004c783          	lbu	a5,0(s1)
    8000448e:	01279763          	bne	a5,s2,8000449c <namex+0xcc>
    path++;
    80004492:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004494:	0004c783          	lbu	a5,0(s1)
    80004498:	ff278de3          	beq	a5,s2,80004492 <namex+0xc2>
    ilock(ip);
    8000449c:	8552                	mv	a0,s4
    8000449e:	00000097          	auipc	ra,0x0
    800044a2:	99e080e7          	jalr	-1634(ra) # 80003e3c <ilock>
    if(ip->type != T_DIR){
    800044a6:	044a1783          	lh	a5,68(s4)
    800044aa:	f97791e3          	bne	a5,s7,8000442c <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800044ae:	000b0563          	beqz	s6,800044b8 <namex+0xe8>
    800044b2:	0004c783          	lbu	a5,0(s1)
    800044b6:	dfd9                	beqz	a5,80004454 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044b8:	4601                	li	a2,0
    800044ba:	85d6                	mv	a1,s5
    800044bc:	8552                	mv	a0,s4
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	e62080e7          	jalr	-414(ra) # 80004320 <dirlookup>
    800044c6:	89aa                	mv	s3,a0
    800044c8:	dd41                	beqz	a0,80004460 <namex+0x90>
    iunlockput(ip);
    800044ca:	8552                	mv	a0,s4
    800044cc:	00000097          	auipc	ra,0x0
    800044d0:	bd2080e7          	jalr	-1070(ra) # 8000409e <iunlockput>
    ip = next;
    800044d4:	8a4e                	mv	s4,s3
  while(*path == '/')
    800044d6:	0004c783          	lbu	a5,0(s1)
    800044da:	01279763          	bne	a5,s2,800044e8 <namex+0x118>
    path++;
    800044de:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044e0:	0004c783          	lbu	a5,0(s1)
    800044e4:	ff278de3          	beq	a5,s2,800044de <namex+0x10e>
  if(*path == 0)
    800044e8:	cb9d                	beqz	a5,8000451e <namex+0x14e>
  while(*path != '/' && *path != 0)
    800044ea:	0004c783          	lbu	a5,0(s1)
    800044ee:	89a6                	mv	s3,s1
  len = path - s;
    800044f0:	4c81                	li	s9,0
    800044f2:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800044f4:	01278963          	beq	a5,s2,80004506 <namex+0x136>
    800044f8:	dbbd                	beqz	a5,8000446e <namex+0x9e>
    path++;
    800044fa:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800044fc:	0009c783          	lbu	a5,0(s3)
    80004500:	ff279ce3          	bne	a5,s2,800044f8 <namex+0x128>
    80004504:	b7ad                	j	8000446e <namex+0x9e>
    memmove(name, s, len);
    80004506:	2601                	sext.w	a2,a2
    80004508:	85a6                	mv	a1,s1
    8000450a:	8556                	mv	a0,s5
    8000450c:	ffffd097          	auipc	ra,0xffffd
    80004510:	81e080e7          	jalr	-2018(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004514:	9cd6                	add	s9,s9,s5
    80004516:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000451a:	84ce                	mv	s1,s3
    8000451c:	b7bd                	j	8000448a <namex+0xba>
  if(nameiparent){
    8000451e:	f00b0de3          	beqz	s6,80004438 <namex+0x68>
    iput(ip);
    80004522:	8552                	mv	a0,s4
    80004524:	00000097          	auipc	ra,0x0
    80004528:	ad2080e7          	jalr	-1326(ra) # 80003ff6 <iput>
    return 0;
    8000452c:	4a01                	li	s4,0
    8000452e:	b729                	j	80004438 <namex+0x68>

0000000080004530 <dirlink>:
{
    80004530:	7139                	addi	sp,sp,-64
    80004532:	fc06                	sd	ra,56(sp)
    80004534:	f822                	sd	s0,48(sp)
    80004536:	f426                	sd	s1,40(sp)
    80004538:	f04a                	sd	s2,32(sp)
    8000453a:	ec4e                	sd	s3,24(sp)
    8000453c:	e852                	sd	s4,16(sp)
    8000453e:	0080                	addi	s0,sp,64
    80004540:	892a                	mv	s2,a0
    80004542:	8a2e                	mv	s4,a1
    80004544:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004546:	4601                	li	a2,0
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	dd8080e7          	jalr	-552(ra) # 80004320 <dirlookup>
    80004550:	e93d                	bnez	a0,800045c6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004552:	04c92483          	lw	s1,76(s2)
    80004556:	c49d                	beqz	s1,80004584 <dirlink+0x54>
    80004558:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000455a:	4741                	li	a4,16
    8000455c:	86a6                	mv	a3,s1
    8000455e:	fc040613          	addi	a2,s0,-64
    80004562:	4581                	li	a1,0
    80004564:	854a                	mv	a0,s2
    80004566:	00000097          	auipc	ra,0x0
    8000456a:	b8a080e7          	jalr	-1142(ra) # 800040f0 <readi>
    8000456e:	47c1                	li	a5,16
    80004570:	06f51163          	bne	a0,a5,800045d2 <dirlink+0xa2>
    if(de.inum == 0)
    80004574:	fc045783          	lhu	a5,-64(s0)
    80004578:	c791                	beqz	a5,80004584 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000457a:	24c1                	addiw	s1,s1,16
    8000457c:	04c92783          	lw	a5,76(s2)
    80004580:	fcf4ede3          	bltu	s1,a5,8000455a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004584:	4639                	li	a2,14
    80004586:	85d2                	mv	a1,s4
    80004588:	fc240513          	addi	a0,s0,-62
    8000458c:	ffffd097          	auipc	ra,0xffffd
    80004590:	84e080e7          	jalr	-1970(ra) # 80000dda <strncpy>
  de.inum = inum;
    80004594:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004598:	4741                	li	a4,16
    8000459a:	86a6                	mv	a3,s1
    8000459c:	fc040613          	addi	a2,s0,-64
    800045a0:	4581                	li	a1,0
    800045a2:	854a                	mv	a0,s2
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	c44080e7          	jalr	-956(ra) # 800041e8 <writei>
    800045ac:	1541                	addi	a0,a0,-16
    800045ae:	00a03533          	snez	a0,a0
    800045b2:	40a00533          	neg	a0,a0
}
    800045b6:	70e2                	ld	ra,56(sp)
    800045b8:	7442                	ld	s0,48(sp)
    800045ba:	74a2                	ld	s1,40(sp)
    800045bc:	7902                	ld	s2,32(sp)
    800045be:	69e2                	ld	s3,24(sp)
    800045c0:	6a42                	ld	s4,16(sp)
    800045c2:	6121                	addi	sp,sp,64
    800045c4:	8082                	ret
    iput(ip);
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	a30080e7          	jalr	-1488(ra) # 80003ff6 <iput>
    return -1;
    800045ce:	557d                	li	a0,-1
    800045d0:	b7dd                	j	800045b6 <dirlink+0x86>
      panic("dirlink read");
    800045d2:	00004517          	auipc	a0,0x4
    800045d6:	07650513          	addi	a0,a0,118 # 80008648 <syscalls+0x1e8>
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	f62080e7          	jalr	-158(ra) # 8000053c <panic>

00000000800045e2 <namei>:

struct inode*
namei(char *path)
{
    800045e2:	1101                	addi	sp,sp,-32
    800045e4:	ec06                	sd	ra,24(sp)
    800045e6:	e822                	sd	s0,16(sp)
    800045e8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045ea:	fe040613          	addi	a2,s0,-32
    800045ee:	4581                	li	a1,0
    800045f0:	00000097          	auipc	ra,0x0
    800045f4:	de0080e7          	jalr	-544(ra) # 800043d0 <namex>
}
    800045f8:	60e2                	ld	ra,24(sp)
    800045fa:	6442                	ld	s0,16(sp)
    800045fc:	6105                	addi	sp,sp,32
    800045fe:	8082                	ret

0000000080004600 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004600:	1141                	addi	sp,sp,-16
    80004602:	e406                	sd	ra,8(sp)
    80004604:	e022                	sd	s0,0(sp)
    80004606:	0800                	addi	s0,sp,16
    80004608:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000460a:	4585                	li	a1,1
    8000460c:	00000097          	auipc	ra,0x0
    80004610:	dc4080e7          	jalr	-572(ra) # 800043d0 <namex>
}
    80004614:	60a2                	ld	ra,8(sp)
    80004616:	6402                	ld	s0,0(sp)
    80004618:	0141                	addi	sp,sp,16
    8000461a:	8082                	ret

000000008000461c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000461c:	1101                	addi	sp,sp,-32
    8000461e:	ec06                	sd	ra,24(sp)
    80004620:	e822                	sd	s0,16(sp)
    80004622:	e426                	sd	s1,8(sp)
    80004624:	e04a                	sd	s2,0(sp)
    80004626:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004628:	0001e917          	auipc	s2,0x1e
    8000462c:	7c890913          	addi	s2,s2,1992 # 80022df0 <log>
    80004630:	01892583          	lw	a1,24(s2)
    80004634:	02892503          	lw	a0,40(s2)
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	ff4080e7          	jalr	-12(ra) # 8000362c <bread>
    80004640:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004642:	02c92603          	lw	a2,44(s2)
    80004646:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004648:	00c05f63          	blez	a2,80004666 <write_head+0x4a>
    8000464c:	0001e717          	auipc	a4,0x1e
    80004650:	7d470713          	addi	a4,a4,2004 # 80022e20 <log+0x30>
    80004654:	87aa                	mv	a5,a0
    80004656:	060a                	slli	a2,a2,0x2
    80004658:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000465a:	4314                	lw	a3,0(a4)
    8000465c:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000465e:	0711                	addi	a4,a4,4
    80004660:	0791                	addi	a5,a5,4
    80004662:	fec79ce3          	bne	a5,a2,8000465a <write_head+0x3e>
  }
  bwrite(buf);
    80004666:	8526                	mv	a0,s1
    80004668:	fffff097          	auipc	ra,0xfffff
    8000466c:	0b6080e7          	jalr	182(ra) # 8000371e <bwrite>
  brelse(buf);
    80004670:	8526                	mv	a0,s1
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	0ea080e7          	jalr	234(ra) # 8000375c <brelse>
}
    8000467a:	60e2                	ld	ra,24(sp)
    8000467c:	6442                	ld	s0,16(sp)
    8000467e:	64a2                	ld	s1,8(sp)
    80004680:	6902                	ld	s2,0(sp)
    80004682:	6105                	addi	sp,sp,32
    80004684:	8082                	ret

0000000080004686 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004686:	0001e797          	auipc	a5,0x1e
    8000468a:	7967a783          	lw	a5,1942(a5) # 80022e1c <log+0x2c>
    8000468e:	0af05d63          	blez	a5,80004748 <install_trans+0xc2>
{
    80004692:	7139                	addi	sp,sp,-64
    80004694:	fc06                	sd	ra,56(sp)
    80004696:	f822                	sd	s0,48(sp)
    80004698:	f426                	sd	s1,40(sp)
    8000469a:	f04a                	sd	s2,32(sp)
    8000469c:	ec4e                	sd	s3,24(sp)
    8000469e:	e852                	sd	s4,16(sp)
    800046a0:	e456                	sd	s5,8(sp)
    800046a2:	e05a                	sd	s6,0(sp)
    800046a4:	0080                	addi	s0,sp,64
    800046a6:	8b2a                	mv	s6,a0
    800046a8:	0001ea97          	auipc	s5,0x1e
    800046ac:	778a8a93          	addi	s5,s5,1912 # 80022e20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046b0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046b2:	0001e997          	auipc	s3,0x1e
    800046b6:	73e98993          	addi	s3,s3,1854 # 80022df0 <log>
    800046ba:	a00d                	j	800046dc <install_trans+0x56>
    brelse(lbuf);
    800046bc:	854a                	mv	a0,s2
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	09e080e7          	jalr	158(ra) # 8000375c <brelse>
    brelse(dbuf);
    800046c6:	8526                	mv	a0,s1
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	094080e7          	jalr	148(ra) # 8000375c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046d0:	2a05                	addiw	s4,s4,1
    800046d2:	0a91                	addi	s5,s5,4
    800046d4:	02c9a783          	lw	a5,44(s3)
    800046d8:	04fa5e63          	bge	s4,a5,80004734 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046dc:	0189a583          	lw	a1,24(s3)
    800046e0:	014585bb          	addw	a1,a1,s4
    800046e4:	2585                	addiw	a1,a1,1
    800046e6:	0289a503          	lw	a0,40(s3)
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	f42080e7          	jalr	-190(ra) # 8000362c <bread>
    800046f2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046f4:	000aa583          	lw	a1,0(s5)
    800046f8:	0289a503          	lw	a0,40(s3)
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	f30080e7          	jalr	-208(ra) # 8000362c <bread>
    80004704:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004706:	40000613          	li	a2,1024
    8000470a:	05890593          	addi	a1,s2,88
    8000470e:	05850513          	addi	a0,a0,88
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	618080e7          	jalr	1560(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000471a:	8526                	mv	a0,s1
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	002080e7          	jalr	2(ra) # 8000371e <bwrite>
    if(recovering == 0)
    80004724:	f80b1ce3          	bnez	s6,800046bc <install_trans+0x36>
      bunpin(dbuf);
    80004728:	8526                	mv	a0,s1
    8000472a:	fffff097          	auipc	ra,0xfffff
    8000472e:	10a080e7          	jalr	266(ra) # 80003834 <bunpin>
    80004732:	b769                	j	800046bc <install_trans+0x36>
}
    80004734:	70e2                	ld	ra,56(sp)
    80004736:	7442                	ld	s0,48(sp)
    80004738:	74a2                	ld	s1,40(sp)
    8000473a:	7902                	ld	s2,32(sp)
    8000473c:	69e2                	ld	s3,24(sp)
    8000473e:	6a42                	ld	s4,16(sp)
    80004740:	6aa2                	ld	s5,8(sp)
    80004742:	6b02                	ld	s6,0(sp)
    80004744:	6121                	addi	sp,sp,64
    80004746:	8082                	ret
    80004748:	8082                	ret

000000008000474a <initlog>:
{
    8000474a:	7179                	addi	sp,sp,-48
    8000474c:	f406                	sd	ra,40(sp)
    8000474e:	f022                	sd	s0,32(sp)
    80004750:	ec26                	sd	s1,24(sp)
    80004752:	e84a                	sd	s2,16(sp)
    80004754:	e44e                	sd	s3,8(sp)
    80004756:	1800                	addi	s0,sp,48
    80004758:	892a                	mv	s2,a0
    8000475a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000475c:	0001e497          	auipc	s1,0x1e
    80004760:	69448493          	addi	s1,s1,1684 # 80022df0 <log>
    80004764:	00004597          	auipc	a1,0x4
    80004768:	ef458593          	addi	a1,a1,-268 # 80008658 <syscalls+0x1f8>
    8000476c:	8526                	mv	a0,s1
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	3d4080e7          	jalr	980(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004776:	0149a583          	lw	a1,20(s3)
    8000477a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000477c:	0109a783          	lw	a5,16(s3)
    80004780:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004782:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004786:	854a                	mv	a0,s2
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	ea4080e7          	jalr	-348(ra) # 8000362c <bread>
  log.lh.n = lh->n;
    80004790:	4d30                	lw	a2,88(a0)
    80004792:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004794:	00c05f63          	blez	a2,800047b2 <initlog+0x68>
    80004798:	87aa                	mv	a5,a0
    8000479a:	0001e717          	auipc	a4,0x1e
    8000479e:	68670713          	addi	a4,a4,1670 # 80022e20 <log+0x30>
    800047a2:	060a                	slli	a2,a2,0x2
    800047a4:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800047a6:	4ff4                	lw	a3,92(a5)
    800047a8:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047aa:	0791                	addi	a5,a5,4
    800047ac:	0711                	addi	a4,a4,4
    800047ae:	fec79ce3          	bne	a5,a2,800047a6 <initlog+0x5c>
  brelse(buf);
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	faa080e7          	jalr	-86(ra) # 8000375c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047ba:	4505                	li	a0,1
    800047bc:	00000097          	auipc	ra,0x0
    800047c0:	eca080e7          	jalr	-310(ra) # 80004686 <install_trans>
  log.lh.n = 0;
    800047c4:	0001e797          	auipc	a5,0x1e
    800047c8:	6407ac23          	sw	zero,1624(a5) # 80022e1c <log+0x2c>
  write_head(); // clear the log
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	e50080e7          	jalr	-432(ra) # 8000461c <write_head>
}
    800047d4:	70a2                	ld	ra,40(sp)
    800047d6:	7402                	ld	s0,32(sp)
    800047d8:	64e2                	ld	s1,24(sp)
    800047da:	6942                	ld	s2,16(sp)
    800047dc:	69a2                	ld	s3,8(sp)
    800047de:	6145                	addi	sp,sp,48
    800047e0:	8082                	ret

00000000800047e2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047e2:	1101                	addi	sp,sp,-32
    800047e4:	ec06                	sd	ra,24(sp)
    800047e6:	e822                	sd	s0,16(sp)
    800047e8:	e426                	sd	s1,8(sp)
    800047ea:	e04a                	sd	s2,0(sp)
    800047ec:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047ee:	0001e517          	auipc	a0,0x1e
    800047f2:	60250513          	addi	a0,a0,1538 # 80022df0 <log>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	3dc080e7          	jalr	988(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    800047fe:	0001e497          	auipc	s1,0x1e
    80004802:	5f248493          	addi	s1,s1,1522 # 80022df0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004806:	4979                	li	s2,30
    80004808:	a039                	j	80004816 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000480a:	85a6                	mv	a1,s1
    8000480c:	8526                	mv	a0,s1
    8000480e:	ffffe097          	auipc	ra,0xffffe
    80004812:	b56080e7          	jalr	-1194(ra) # 80002364 <sleep>
    if(log.committing){
    80004816:	50dc                	lw	a5,36(s1)
    80004818:	fbed                	bnez	a5,8000480a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000481a:	5098                	lw	a4,32(s1)
    8000481c:	2705                	addiw	a4,a4,1
    8000481e:	0027179b          	slliw	a5,a4,0x2
    80004822:	9fb9                	addw	a5,a5,a4
    80004824:	0017979b          	slliw	a5,a5,0x1
    80004828:	54d4                	lw	a3,44(s1)
    8000482a:	9fb5                	addw	a5,a5,a3
    8000482c:	00f95963          	bge	s2,a5,8000483e <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004830:	85a6                	mv	a1,s1
    80004832:	8526                	mv	a0,s1
    80004834:	ffffe097          	auipc	ra,0xffffe
    80004838:	b30080e7          	jalr	-1232(ra) # 80002364 <sleep>
    8000483c:	bfe9                	j	80004816 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000483e:	0001e517          	auipc	a0,0x1e
    80004842:	5b250513          	addi	a0,a0,1458 # 80022df0 <log>
    80004846:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	43e080e7          	jalr	1086(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004850:	60e2                	ld	ra,24(sp)
    80004852:	6442                	ld	s0,16(sp)
    80004854:	64a2                	ld	s1,8(sp)
    80004856:	6902                	ld	s2,0(sp)
    80004858:	6105                	addi	sp,sp,32
    8000485a:	8082                	ret

000000008000485c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000485c:	7139                	addi	sp,sp,-64
    8000485e:	fc06                	sd	ra,56(sp)
    80004860:	f822                	sd	s0,48(sp)
    80004862:	f426                	sd	s1,40(sp)
    80004864:	f04a                	sd	s2,32(sp)
    80004866:	ec4e                	sd	s3,24(sp)
    80004868:	e852                	sd	s4,16(sp)
    8000486a:	e456                	sd	s5,8(sp)
    8000486c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000486e:	0001e497          	auipc	s1,0x1e
    80004872:	58248493          	addi	s1,s1,1410 # 80022df0 <log>
    80004876:	8526                	mv	a0,s1
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	35a080e7          	jalr	858(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004880:	509c                	lw	a5,32(s1)
    80004882:	37fd                	addiw	a5,a5,-1
    80004884:	0007891b          	sext.w	s2,a5
    80004888:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000488a:	50dc                	lw	a5,36(s1)
    8000488c:	e7b9                	bnez	a5,800048da <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000488e:	04091e63          	bnez	s2,800048ea <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004892:	0001e497          	auipc	s1,0x1e
    80004896:	55e48493          	addi	s1,s1,1374 # 80022df0 <log>
    8000489a:	4785                	li	a5,1
    8000489c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000489e:	8526                	mv	a0,s1
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	3e6080e7          	jalr	998(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048a8:	54dc                	lw	a5,44(s1)
    800048aa:	06f04763          	bgtz	a5,80004918 <end_op+0xbc>
    acquire(&log.lock);
    800048ae:	0001e497          	auipc	s1,0x1e
    800048b2:	54248493          	addi	s1,s1,1346 # 80022df0 <log>
    800048b6:	8526                	mv	a0,s1
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	31a080e7          	jalr	794(ra) # 80000bd2 <acquire>
    log.committing = 0;
    800048c0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048c4:	8526                	mv	a0,s1
    800048c6:	ffffe097          	auipc	ra,0xffffe
    800048ca:	b02080e7          	jalr	-1278(ra) # 800023c8 <wakeup>
    release(&log.lock);
    800048ce:	8526                	mv	a0,s1
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	3b6080e7          	jalr	950(ra) # 80000c86 <release>
}
    800048d8:	a03d                	j	80004906 <end_op+0xaa>
    panic("log.committing");
    800048da:	00004517          	auipc	a0,0x4
    800048de:	d8650513          	addi	a0,a0,-634 # 80008660 <syscalls+0x200>
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	c5a080e7          	jalr	-934(ra) # 8000053c <panic>
    wakeup(&log);
    800048ea:	0001e497          	auipc	s1,0x1e
    800048ee:	50648493          	addi	s1,s1,1286 # 80022df0 <log>
    800048f2:	8526                	mv	a0,s1
    800048f4:	ffffe097          	auipc	ra,0xffffe
    800048f8:	ad4080e7          	jalr	-1324(ra) # 800023c8 <wakeup>
  release(&log.lock);
    800048fc:	8526                	mv	a0,s1
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	388080e7          	jalr	904(ra) # 80000c86 <release>
}
    80004906:	70e2                	ld	ra,56(sp)
    80004908:	7442                	ld	s0,48(sp)
    8000490a:	74a2                	ld	s1,40(sp)
    8000490c:	7902                	ld	s2,32(sp)
    8000490e:	69e2                	ld	s3,24(sp)
    80004910:	6a42                	ld	s4,16(sp)
    80004912:	6aa2                	ld	s5,8(sp)
    80004914:	6121                	addi	sp,sp,64
    80004916:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004918:	0001ea97          	auipc	s5,0x1e
    8000491c:	508a8a93          	addi	s5,s5,1288 # 80022e20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004920:	0001ea17          	auipc	s4,0x1e
    80004924:	4d0a0a13          	addi	s4,s4,1232 # 80022df0 <log>
    80004928:	018a2583          	lw	a1,24(s4)
    8000492c:	012585bb          	addw	a1,a1,s2
    80004930:	2585                	addiw	a1,a1,1
    80004932:	028a2503          	lw	a0,40(s4)
    80004936:	fffff097          	auipc	ra,0xfffff
    8000493a:	cf6080e7          	jalr	-778(ra) # 8000362c <bread>
    8000493e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004940:	000aa583          	lw	a1,0(s5)
    80004944:	028a2503          	lw	a0,40(s4)
    80004948:	fffff097          	auipc	ra,0xfffff
    8000494c:	ce4080e7          	jalr	-796(ra) # 8000362c <bread>
    80004950:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004952:	40000613          	li	a2,1024
    80004956:	05850593          	addi	a1,a0,88
    8000495a:	05848513          	addi	a0,s1,88
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	3cc080e7          	jalr	972(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004966:	8526                	mv	a0,s1
    80004968:	fffff097          	auipc	ra,0xfffff
    8000496c:	db6080e7          	jalr	-586(ra) # 8000371e <bwrite>
    brelse(from);
    80004970:	854e                	mv	a0,s3
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	dea080e7          	jalr	-534(ra) # 8000375c <brelse>
    brelse(to);
    8000497a:	8526                	mv	a0,s1
    8000497c:	fffff097          	auipc	ra,0xfffff
    80004980:	de0080e7          	jalr	-544(ra) # 8000375c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004984:	2905                	addiw	s2,s2,1
    80004986:	0a91                	addi	s5,s5,4
    80004988:	02ca2783          	lw	a5,44(s4)
    8000498c:	f8f94ee3          	blt	s2,a5,80004928 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004990:	00000097          	auipc	ra,0x0
    80004994:	c8c080e7          	jalr	-884(ra) # 8000461c <write_head>
    install_trans(0); // Now install writes to home locations
    80004998:	4501                	li	a0,0
    8000499a:	00000097          	auipc	ra,0x0
    8000499e:	cec080e7          	jalr	-788(ra) # 80004686 <install_trans>
    log.lh.n = 0;
    800049a2:	0001e797          	auipc	a5,0x1e
    800049a6:	4607ad23          	sw	zero,1146(a5) # 80022e1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049aa:	00000097          	auipc	ra,0x0
    800049ae:	c72080e7          	jalr	-910(ra) # 8000461c <write_head>
    800049b2:	bdf5                	j	800048ae <end_op+0x52>

00000000800049b4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049b4:	1101                	addi	sp,sp,-32
    800049b6:	ec06                	sd	ra,24(sp)
    800049b8:	e822                	sd	s0,16(sp)
    800049ba:	e426                	sd	s1,8(sp)
    800049bc:	e04a                	sd	s2,0(sp)
    800049be:	1000                	addi	s0,sp,32
    800049c0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049c2:	0001e917          	auipc	s2,0x1e
    800049c6:	42e90913          	addi	s2,s2,1070 # 80022df0 <log>
    800049ca:	854a                	mv	a0,s2
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	206080e7          	jalr	518(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049d4:	02c92603          	lw	a2,44(s2)
    800049d8:	47f5                	li	a5,29
    800049da:	06c7c563          	blt	a5,a2,80004a44 <log_write+0x90>
    800049de:	0001e797          	auipc	a5,0x1e
    800049e2:	42e7a783          	lw	a5,1070(a5) # 80022e0c <log+0x1c>
    800049e6:	37fd                	addiw	a5,a5,-1
    800049e8:	04f65e63          	bge	a2,a5,80004a44 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049ec:	0001e797          	auipc	a5,0x1e
    800049f0:	4247a783          	lw	a5,1060(a5) # 80022e10 <log+0x20>
    800049f4:	06f05063          	blez	a5,80004a54 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049f8:	4781                	li	a5,0
    800049fa:	06c05563          	blez	a2,80004a64 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049fe:	44cc                	lw	a1,12(s1)
    80004a00:	0001e717          	auipc	a4,0x1e
    80004a04:	42070713          	addi	a4,a4,1056 # 80022e20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a08:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a0a:	4314                	lw	a3,0(a4)
    80004a0c:	04b68c63          	beq	a3,a1,80004a64 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a10:	2785                	addiw	a5,a5,1
    80004a12:	0711                	addi	a4,a4,4
    80004a14:	fef61be3          	bne	a2,a5,80004a0a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a18:	0621                	addi	a2,a2,8
    80004a1a:	060a                	slli	a2,a2,0x2
    80004a1c:	0001e797          	auipc	a5,0x1e
    80004a20:	3d478793          	addi	a5,a5,980 # 80022df0 <log>
    80004a24:	97b2                	add	a5,a5,a2
    80004a26:	44d8                	lw	a4,12(s1)
    80004a28:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a2a:	8526                	mv	a0,s1
    80004a2c:	fffff097          	auipc	ra,0xfffff
    80004a30:	dcc080e7          	jalr	-564(ra) # 800037f8 <bpin>
    log.lh.n++;
    80004a34:	0001e717          	auipc	a4,0x1e
    80004a38:	3bc70713          	addi	a4,a4,956 # 80022df0 <log>
    80004a3c:	575c                	lw	a5,44(a4)
    80004a3e:	2785                	addiw	a5,a5,1
    80004a40:	d75c                	sw	a5,44(a4)
    80004a42:	a82d                	j	80004a7c <log_write+0xc8>
    panic("too big a transaction");
    80004a44:	00004517          	auipc	a0,0x4
    80004a48:	c2c50513          	addi	a0,a0,-980 # 80008670 <syscalls+0x210>
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	af0080e7          	jalr	-1296(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004a54:	00004517          	auipc	a0,0x4
    80004a58:	c3450513          	addi	a0,a0,-972 # 80008688 <syscalls+0x228>
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	ae0080e7          	jalr	-1312(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004a64:	00878693          	addi	a3,a5,8
    80004a68:	068a                	slli	a3,a3,0x2
    80004a6a:	0001e717          	auipc	a4,0x1e
    80004a6e:	38670713          	addi	a4,a4,902 # 80022df0 <log>
    80004a72:	9736                	add	a4,a4,a3
    80004a74:	44d4                	lw	a3,12(s1)
    80004a76:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a78:	faf609e3          	beq	a2,a5,80004a2a <log_write+0x76>
  }
  release(&log.lock);
    80004a7c:	0001e517          	auipc	a0,0x1e
    80004a80:	37450513          	addi	a0,a0,884 # 80022df0 <log>
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	202080e7          	jalr	514(ra) # 80000c86 <release>
}
    80004a8c:	60e2                	ld	ra,24(sp)
    80004a8e:	6442                	ld	s0,16(sp)
    80004a90:	64a2                	ld	s1,8(sp)
    80004a92:	6902                	ld	s2,0(sp)
    80004a94:	6105                	addi	sp,sp,32
    80004a96:	8082                	ret

0000000080004a98 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a98:	1101                	addi	sp,sp,-32
    80004a9a:	ec06                	sd	ra,24(sp)
    80004a9c:	e822                	sd	s0,16(sp)
    80004a9e:	e426                	sd	s1,8(sp)
    80004aa0:	e04a                	sd	s2,0(sp)
    80004aa2:	1000                	addi	s0,sp,32
    80004aa4:	84aa                	mv	s1,a0
    80004aa6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004aa8:	00004597          	auipc	a1,0x4
    80004aac:	c0058593          	addi	a1,a1,-1024 # 800086a8 <syscalls+0x248>
    80004ab0:	0521                	addi	a0,a0,8
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	090080e7          	jalr	144(ra) # 80000b42 <initlock>
  lk->name = name;
    80004aba:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004abe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ac2:	0204a423          	sw	zero,40(s1)
}
    80004ac6:	60e2                	ld	ra,24(sp)
    80004ac8:	6442                	ld	s0,16(sp)
    80004aca:	64a2                	ld	s1,8(sp)
    80004acc:	6902                	ld	s2,0(sp)
    80004ace:	6105                	addi	sp,sp,32
    80004ad0:	8082                	ret

0000000080004ad2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ad2:	1101                	addi	sp,sp,-32
    80004ad4:	ec06                	sd	ra,24(sp)
    80004ad6:	e822                	sd	s0,16(sp)
    80004ad8:	e426                	sd	s1,8(sp)
    80004ada:	e04a                	sd	s2,0(sp)
    80004adc:	1000                	addi	s0,sp,32
    80004ade:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ae0:	00850913          	addi	s2,a0,8
    80004ae4:	854a                	mv	a0,s2
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	0ec080e7          	jalr	236(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004aee:	409c                	lw	a5,0(s1)
    80004af0:	cb89                	beqz	a5,80004b02 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004af2:	85ca                	mv	a1,s2
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffe097          	auipc	ra,0xffffe
    80004afa:	86e080e7          	jalr	-1938(ra) # 80002364 <sleep>
  while (lk->locked) {
    80004afe:	409c                	lw	a5,0(s1)
    80004b00:	fbed                	bnez	a5,80004af2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b02:	4785                	li	a5,1
    80004b04:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b06:	ffffd097          	auipc	ra,0xffffd
    80004b0a:	ed0080e7          	jalr	-304(ra) # 800019d6 <myproc>
    80004b0e:	591c                	lw	a5,48(a0)
    80004b10:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b12:	854a                	mv	a0,s2
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	172080e7          	jalr	370(ra) # 80000c86 <release>
}
    80004b1c:	60e2                	ld	ra,24(sp)
    80004b1e:	6442                	ld	s0,16(sp)
    80004b20:	64a2                	ld	s1,8(sp)
    80004b22:	6902                	ld	s2,0(sp)
    80004b24:	6105                	addi	sp,sp,32
    80004b26:	8082                	ret

0000000080004b28 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b28:	1101                	addi	sp,sp,-32
    80004b2a:	ec06                	sd	ra,24(sp)
    80004b2c:	e822                	sd	s0,16(sp)
    80004b2e:	e426                	sd	s1,8(sp)
    80004b30:	e04a                	sd	s2,0(sp)
    80004b32:	1000                	addi	s0,sp,32
    80004b34:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b36:	00850913          	addi	s2,a0,8
    80004b3a:	854a                	mv	a0,s2
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	096080e7          	jalr	150(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004b44:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b48:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	ffffe097          	auipc	ra,0xffffe
    80004b52:	87a080e7          	jalr	-1926(ra) # 800023c8 <wakeup>
  release(&lk->lk);
    80004b56:	854a                	mv	a0,s2
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	12e080e7          	jalr	302(ra) # 80000c86 <release>
}
    80004b60:	60e2                	ld	ra,24(sp)
    80004b62:	6442                	ld	s0,16(sp)
    80004b64:	64a2                	ld	s1,8(sp)
    80004b66:	6902                	ld	s2,0(sp)
    80004b68:	6105                	addi	sp,sp,32
    80004b6a:	8082                	ret

0000000080004b6c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b6c:	7179                	addi	sp,sp,-48
    80004b6e:	f406                	sd	ra,40(sp)
    80004b70:	f022                	sd	s0,32(sp)
    80004b72:	ec26                	sd	s1,24(sp)
    80004b74:	e84a                	sd	s2,16(sp)
    80004b76:	e44e                	sd	s3,8(sp)
    80004b78:	1800                	addi	s0,sp,48
    80004b7a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b7c:	00850913          	addi	s2,a0,8
    80004b80:	854a                	mv	a0,s2
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	050080e7          	jalr	80(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b8a:	409c                	lw	a5,0(s1)
    80004b8c:	ef99                	bnez	a5,80004baa <holdingsleep+0x3e>
    80004b8e:	4481                	li	s1,0
  release(&lk->lk);
    80004b90:	854a                	mv	a0,s2
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	0f4080e7          	jalr	244(ra) # 80000c86 <release>
  return r;
}
    80004b9a:	8526                	mv	a0,s1
    80004b9c:	70a2                	ld	ra,40(sp)
    80004b9e:	7402                	ld	s0,32(sp)
    80004ba0:	64e2                	ld	s1,24(sp)
    80004ba2:	6942                	ld	s2,16(sp)
    80004ba4:	69a2                	ld	s3,8(sp)
    80004ba6:	6145                	addi	sp,sp,48
    80004ba8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004baa:	0284a983          	lw	s3,40(s1)
    80004bae:	ffffd097          	auipc	ra,0xffffd
    80004bb2:	e28080e7          	jalr	-472(ra) # 800019d6 <myproc>
    80004bb6:	5904                	lw	s1,48(a0)
    80004bb8:	413484b3          	sub	s1,s1,s3
    80004bbc:	0014b493          	seqz	s1,s1
    80004bc0:	bfc1                	j	80004b90 <holdingsleep+0x24>

0000000080004bc2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004bc2:	1141                	addi	sp,sp,-16
    80004bc4:	e406                	sd	ra,8(sp)
    80004bc6:	e022                	sd	s0,0(sp)
    80004bc8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004bca:	00004597          	auipc	a1,0x4
    80004bce:	aee58593          	addi	a1,a1,-1298 # 800086b8 <syscalls+0x258>
    80004bd2:	0001e517          	auipc	a0,0x1e
    80004bd6:	36650513          	addi	a0,a0,870 # 80022f38 <ftable>
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	f68080e7          	jalr	-152(ra) # 80000b42 <initlock>
}
    80004be2:	60a2                	ld	ra,8(sp)
    80004be4:	6402                	ld	s0,0(sp)
    80004be6:	0141                	addi	sp,sp,16
    80004be8:	8082                	ret

0000000080004bea <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bea:	1101                	addi	sp,sp,-32
    80004bec:	ec06                	sd	ra,24(sp)
    80004bee:	e822                	sd	s0,16(sp)
    80004bf0:	e426                	sd	s1,8(sp)
    80004bf2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bf4:	0001e517          	auipc	a0,0x1e
    80004bf8:	34450513          	addi	a0,a0,836 # 80022f38 <ftable>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fd6080e7          	jalr	-42(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c04:	0001e497          	auipc	s1,0x1e
    80004c08:	34c48493          	addi	s1,s1,844 # 80022f50 <ftable+0x18>
    80004c0c:	0001f717          	auipc	a4,0x1f
    80004c10:	2e470713          	addi	a4,a4,740 # 80023ef0 <disk>
    if(f->ref == 0){
    80004c14:	40dc                	lw	a5,4(s1)
    80004c16:	cf99                	beqz	a5,80004c34 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c18:	02848493          	addi	s1,s1,40
    80004c1c:	fee49ce3          	bne	s1,a4,80004c14 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c20:	0001e517          	auipc	a0,0x1e
    80004c24:	31850513          	addi	a0,a0,792 # 80022f38 <ftable>
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	05e080e7          	jalr	94(ra) # 80000c86 <release>
  return 0;
    80004c30:	4481                	li	s1,0
    80004c32:	a819                	j	80004c48 <filealloc+0x5e>
      f->ref = 1;
    80004c34:	4785                	li	a5,1
    80004c36:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c38:	0001e517          	auipc	a0,0x1e
    80004c3c:	30050513          	addi	a0,a0,768 # 80022f38 <ftable>
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	046080e7          	jalr	70(ra) # 80000c86 <release>
}
    80004c48:	8526                	mv	a0,s1
    80004c4a:	60e2                	ld	ra,24(sp)
    80004c4c:	6442                	ld	s0,16(sp)
    80004c4e:	64a2                	ld	s1,8(sp)
    80004c50:	6105                	addi	sp,sp,32
    80004c52:	8082                	ret

0000000080004c54 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c54:	1101                	addi	sp,sp,-32
    80004c56:	ec06                	sd	ra,24(sp)
    80004c58:	e822                	sd	s0,16(sp)
    80004c5a:	e426                	sd	s1,8(sp)
    80004c5c:	1000                	addi	s0,sp,32
    80004c5e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c60:	0001e517          	auipc	a0,0x1e
    80004c64:	2d850513          	addi	a0,a0,728 # 80022f38 <ftable>
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	f6a080e7          	jalr	-150(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004c70:	40dc                	lw	a5,4(s1)
    80004c72:	02f05263          	blez	a5,80004c96 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c76:	2785                	addiw	a5,a5,1
    80004c78:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c7a:	0001e517          	auipc	a0,0x1e
    80004c7e:	2be50513          	addi	a0,a0,702 # 80022f38 <ftable>
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	004080e7          	jalr	4(ra) # 80000c86 <release>
  return f;
}
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	60e2                	ld	ra,24(sp)
    80004c8e:	6442                	ld	s0,16(sp)
    80004c90:	64a2                	ld	s1,8(sp)
    80004c92:	6105                	addi	sp,sp,32
    80004c94:	8082                	ret
    panic("filedup");
    80004c96:	00004517          	auipc	a0,0x4
    80004c9a:	a2a50513          	addi	a0,a0,-1494 # 800086c0 <syscalls+0x260>
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	89e080e7          	jalr	-1890(ra) # 8000053c <panic>

0000000080004ca6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ca6:	7139                	addi	sp,sp,-64
    80004ca8:	fc06                	sd	ra,56(sp)
    80004caa:	f822                	sd	s0,48(sp)
    80004cac:	f426                	sd	s1,40(sp)
    80004cae:	f04a                	sd	s2,32(sp)
    80004cb0:	ec4e                	sd	s3,24(sp)
    80004cb2:	e852                	sd	s4,16(sp)
    80004cb4:	e456                	sd	s5,8(sp)
    80004cb6:	0080                	addi	s0,sp,64
    80004cb8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004cba:	0001e517          	auipc	a0,0x1e
    80004cbe:	27e50513          	addi	a0,a0,638 # 80022f38 <ftable>
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	f10080e7          	jalr	-240(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004cca:	40dc                	lw	a5,4(s1)
    80004ccc:	06f05163          	blez	a5,80004d2e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cd0:	37fd                	addiw	a5,a5,-1
    80004cd2:	0007871b          	sext.w	a4,a5
    80004cd6:	c0dc                	sw	a5,4(s1)
    80004cd8:	06e04363          	bgtz	a4,80004d3e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cdc:	0004a903          	lw	s2,0(s1)
    80004ce0:	0094ca83          	lbu	s5,9(s1)
    80004ce4:	0104ba03          	ld	s4,16(s1)
    80004ce8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cec:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cf0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cf4:	0001e517          	auipc	a0,0x1e
    80004cf8:	24450513          	addi	a0,a0,580 # 80022f38 <ftable>
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	f8a080e7          	jalr	-118(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004d04:	4785                	li	a5,1
    80004d06:	04f90d63          	beq	s2,a5,80004d60 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d0a:	3979                	addiw	s2,s2,-2
    80004d0c:	4785                	li	a5,1
    80004d0e:	0527e063          	bltu	a5,s2,80004d4e <fileclose+0xa8>
    begin_op();
    80004d12:	00000097          	auipc	ra,0x0
    80004d16:	ad0080e7          	jalr	-1328(ra) # 800047e2 <begin_op>
    iput(ff.ip);
    80004d1a:	854e                	mv	a0,s3
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	2da080e7          	jalr	730(ra) # 80003ff6 <iput>
    end_op();
    80004d24:	00000097          	auipc	ra,0x0
    80004d28:	b38080e7          	jalr	-1224(ra) # 8000485c <end_op>
    80004d2c:	a00d                	j	80004d4e <fileclose+0xa8>
    panic("fileclose");
    80004d2e:	00004517          	auipc	a0,0x4
    80004d32:	99a50513          	addi	a0,a0,-1638 # 800086c8 <syscalls+0x268>
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	806080e7          	jalr	-2042(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004d3e:	0001e517          	auipc	a0,0x1e
    80004d42:	1fa50513          	addi	a0,a0,506 # 80022f38 <ftable>
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	f40080e7          	jalr	-192(ra) # 80000c86 <release>
  }
}
    80004d4e:	70e2                	ld	ra,56(sp)
    80004d50:	7442                	ld	s0,48(sp)
    80004d52:	74a2                	ld	s1,40(sp)
    80004d54:	7902                	ld	s2,32(sp)
    80004d56:	69e2                	ld	s3,24(sp)
    80004d58:	6a42                	ld	s4,16(sp)
    80004d5a:	6aa2                	ld	s5,8(sp)
    80004d5c:	6121                	addi	sp,sp,64
    80004d5e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d60:	85d6                	mv	a1,s5
    80004d62:	8552                	mv	a0,s4
    80004d64:	00000097          	auipc	ra,0x0
    80004d68:	348080e7          	jalr	840(ra) # 800050ac <pipeclose>
    80004d6c:	b7cd                	j	80004d4e <fileclose+0xa8>

0000000080004d6e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d6e:	715d                	addi	sp,sp,-80
    80004d70:	e486                	sd	ra,72(sp)
    80004d72:	e0a2                	sd	s0,64(sp)
    80004d74:	fc26                	sd	s1,56(sp)
    80004d76:	f84a                	sd	s2,48(sp)
    80004d78:	f44e                	sd	s3,40(sp)
    80004d7a:	0880                	addi	s0,sp,80
    80004d7c:	84aa                	mv	s1,a0
    80004d7e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	c56080e7          	jalr	-938(ra) # 800019d6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d88:	409c                	lw	a5,0(s1)
    80004d8a:	37f9                	addiw	a5,a5,-2
    80004d8c:	4705                	li	a4,1
    80004d8e:	04f76763          	bltu	a4,a5,80004ddc <filestat+0x6e>
    80004d92:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d94:	6c88                	ld	a0,24(s1)
    80004d96:	fffff097          	auipc	ra,0xfffff
    80004d9a:	0a6080e7          	jalr	166(ra) # 80003e3c <ilock>
    stati(f->ip, &st);
    80004d9e:	fb840593          	addi	a1,s0,-72
    80004da2:	6c88                	ld	a0,24(s1)
    80004da4:	fffff097          	auipc	ra,0xfffff
    80004da8:	322080e7          	jalr	802(ra) # 800040c6 <stati>
    iunlock(f->ip);
    80004dac:	6c88                	ld	a0,24(s1)
    80004dae:	fffff097          	auipc	ra,0xfffff
    80004db2:	150080e7          	jalr	336(ra) # 80003efe <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004db6:	46e1                	li	a3,24
    80004db8:	fb840613          	addi	a2,s0,-72
    80004dbc:	85ce                	mv	a1,s3
    80004dbe:	05093503          	ld	a0,80(s2)
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	8a4080e7          	jalr	-1884(ra) # 80001666 <copyout>
    80004dca:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dce:	60a6                	ld	ra,72(sp)
    80004dd0:	6406                	ld	s0,64(sp)
    80004dd2:	74e2                	ld	s1,56(sp)
    80004dd4:	7942                	ld	s2,48(sp)
    80004dd6:	79a2                	ld	s3,40(sp)
    80004dd8:	6161                	addi	sp,sp,80
    80004dda:	8082                	ret
  return -1;
    80004ddc:	557d                	li	a0,-1
    80004dde:	bfc5                	j	80004dce <filestat+0x60>

0000000080004de0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004de0:	7179                	addi	sp,sp,-48
    80004de2:	f406                	sd	ra,40(sp)
    80004de4:	f022                	sd	s0,32(sp)
    80004de6:	ec26                	sd	s1,24(sp)
    80004de8:	e84a                	sd	s2,16(sp)
    80004dea:	e44e                	sd	s3,8(sp)
    80004dec:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dee:	00854783          	lbu	a5,8(a0)
    80004df2:	c3d5                	beqz	a5,80004e96 <fileread+0xb6>
    80004df4:	84aa                	mv	s1,a0
    80004df6:	89ae                	mv	s3,a1
    80004df8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dfa:	411c                	lw	a5,0(a0)
    80004dfc:	4705                	li	a4,1
    80004dfe:	04e78963          	beq	a5,a4,80004e50 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e02:	470d                	li	a4,3
    80004e04:	04e78d63          	beq	a5,a4,80004e5e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e08:	4709                	li	a4,2
    80004e0a:	06e79e63          	bne	a5,a4,80004e86 <fileread+0xa6>
    ilock(f->ip);
    80004e0e:	6d08                	ld	a0,24(a0)
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	02c080e7          	jalr	44(ra) # 80003e3c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e18:	874a                	mv	a4,s2
    80004e1a:	5094                	lw	a3,32(s1)
    80004e1c:	864e                	mv	a2,s3
    80004e1e:	4585                	li	a1,1
    80004e20:	6c88                	ld	a0,24(s1)
    80004e22:	fffff097          	auipc	ra,0xfffff
    80004e26:	2ce080e7          	jalr	718(ra) # 800040f0 <readi>
    80004e2a:	892a                	mv	s2,a0
    80004e2c:	00a05563          	blez	a0,80004e36 <fileread+0x56>
      f->off += r;
    80004e30:	509c                	lw	a5,32(s1)
    80004e32:	9fa9                	addw	a5,a5,a0
    80004e34:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e36:	6c88                	ld	a0,24(s1)
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	0c6080e7          	jalr	198(ra) # 80003efe <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e40:	854a                	mv	a0,s2
    80004e42:	70a2                	ld	ra,40(sp)
    80004e44:	7402                	ld	s0,32(sp)
    80004e46:	64e2                	ld	s1,24(sp)
    80004e48:	6942                	ld	s2,16(sp)
    80004e4a:	69a2                	ld	s3,8(sp)
    80004e4c:	6145                	addi	sp,sp,48
    80004e4e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e50:	6908                	ld	a0,16(a0)
    80004e52:	00000097          	auipc	ra,0x0
    80004e56:	3c2080e7          	jalr	962(ra) # 80005214 <piperead>
    80004e5a:	892a                	mv	s2,a0
    80004e5c:	b7d5                	j	80004e40 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e5e:	02451783          	lh	a5,36(a0)
    80004e62:	03079693          	slli	a3,a5,0x30
    80004e66:	92c1                	srli	a3,a3,0x30
    80004e68:	4725                	li	a4,9
    80004e6a:	02d76863          	bltu	a4,a3,80004e9a <fileread+0xba>
    80004e6e:	0792                	slli	a5,a5,0x4
    80004e70:	0001e717          	auipc	a4,0x1e
    80004e74:	02870713          	addi	a4,a4,40 # 80022e98 <devsw>
    80004e78:	97ba                	add	a5,a5,a4
    80004e7a:	639c                	ld	a5,0(a5)
    80004e7c:	c38d                	beqz	a5,80004e9e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e7e:	4505                	li	a0,1
    80004e80:	9782                	jalr	a5
    80004e82:	892a                	mv	s2,a0
    80004e84:	bf75                	j	80004e40 <fileread+0x60>
    panic("fileread");
    80004e86:	00004517          	auipc	a0,0x4
    80004e8a:	85250513          	addi	a0,a0,-1966 # 800086d8 <syscalls+0x278>
    80004e8e:	ffffb097          	auipc	ra,0xffffb
    80004e92:	6ae080e7          	jalr	1710(ra) # 8000053c <panic>
    return -1;
    80004e96:	597d                	li	s2,-1
    80004e98:	b765                	j	80004e40 <fileread+0x60>
      return -1;
    80004e9a:	597d                	li	s2,-1
    80004e9c:	b755                	j	80004e40 <fileread+0x60>
    80004e9e:	597d                	li	s2,-1
    80004ea0:	b745                	j	80004e40 <fileread+0x60>

0000000080004ea2 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004ea2:	00954783          	lbu	a5,9(a0)
    80004ea6:	10078e63          	beqz	a5,80004fc2 <filewrite+0x120>
{
    80004eaa:	715d                	addi	sp,sp,-80
    80004eac:	e486                	sd	ra,72(sp)
    80004eae:	e0a2                	sd	s0,64(sp)
    80004eb0:	fc26                	sd	s1,56(sp)
    80004eb2:	f84a                	sd	s2,48(sp)
    80004eb4:	f44e                	sd	s3,40(sp)
    80004eb6:	f052                	sd	s4,32(sp)
    80004eb8:	ec56                	sd	s5,24(sp)
    80004eba:	e85a                	sd	s6,16(sp)
    80004ebc:	e45e                	sd	s7,8(sp)
    80004ebe:	e062                	sd	s8,0(sp)
    80004ec0:	0880                	addi	s0,sp,80
    80004ec2:	892a                	mv	s2,a0
    80004ec4:	8b2e                	mv	s6,a1
    80004ec6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ec8:	411c                	lw	a5,0(a0)
    80004eca:	4705                	li	a4,1
    80004ecc:	02e78263          	beq	a5,a4,80004ef0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ed0:	470d                	li	a4,3
    80004ed2:	02e78563          	beq	a5,a4,80004efc <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ed6:	4709                	li	a4,2
    80004ed8:	0ce79d63          	bne	a5,a4,80004fb2 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004edc:	0ac05b63          	blez	a2,80004f92 <filewrite+0xf0>
    int i = 0;
    80004ee0:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004ee2:	6b85                	lui	s7,0x1
    80004ee4:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ee8:	6c05                	lui	s8,0x1
    80004eea:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004eee:	a851                	j	80004f82 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004ef0:	6908                	ld	a0,16(a0)
    80004ef2:	00000097          	auipc	ra,0x0
    80004ef6:	22a080e7          	jalr	554(ra) # 8000511c <pipewrite>
    80004efa:	a045                	j	80004f9a <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004efc:	02451783          	lh	a5,36(a0)
    80004f00:	03079693          	slli	a3,a5,0x30
    80004f04:	92c1                	srli	a3,a3,0x30
    80004f06:	4725                	li	a4,9
    80004f08:	0ad76f63          	bltu	a4,a3,80004fc6 <filewrite+0x124>
    80004f0c:	0792                	slli	a5,a5,0x4
    80004f0e:	0001e717          	auipc	a4,0x1e
    80004f12:	f8a70713          	addi	a4,a4,-118 # 80022e98 <devsw>
    80004f16:	97ba                	add	a5,a5,a4
    80004f18:	679c                	ld	a5,8(a5)
    80004f1a:	cbc5                	beqz	a5,80004fca <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004f1c:	4505                	li	a0,1
    80004f1e:	9782                	jalr	a5
    80004f20:	a8ad                	j	80004f9a <filewrite+0xf8>
      if(n1 > max)
    80004f22:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004f26:	00000097          	auipc	ra,0x0
    80004f2a:	8bc080e7          	jalr	-1860(ra) # 800047e2 <begin_op>
      ilock(f->ip);
    80004f2e:	01893503          	ld	a0,24(s2)
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	f0a080e7          	jalr	-246(ra) # 80003e3c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f3a:	8756                	mv	a4,s5
    80004f3c:	02092683          	lw	a3,32(s2)
    80004f40:	01698633          	add	a2,s3,s6
    80004f44:	4585                	li	a1,1
    80004f46:	01893503          	ld	a0,24(s2)
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	29e080e7          	jalr	670(ra) # 800041e8 <writei>
    80004f52:	84aa                	mv	s1,a0
    80004f54:	00a05763          	blez	a0,80004f62 <filewrite+0xc0>
        f->off += r;
    80004f58:	02092783          	lw	a5,32(s2)
    80004f5c:	9fa9                	addw	a5,a5,a0
    80004f5e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f62:	01893503          	ld	a0,24(s2)
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	f98080e7          	jalr	-104(ra) # 80003efe <iunlock>
      end_op();
    80004f6e:	00000097          	auipc	ra,0x0
    80004f72:	8ee080e7          	jalr	-1810(ra) # 8000485c <end_op>

      if(r != n1){
    80004f76:	009a9f63          	bne	s5,s1,80004f94 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004f7a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f7e:	0149db63          	bge	s3,s4,80004f94 <filewrite+0xf2>
      int n1 = n - i;
    80004f82:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004f86:	0004879b          	sext.w	a5,s1
    80004f8a:	f8fbdce3          	bge	s7,a5,80004f22 <filewrite+0x80>
    80004f8e:	84e2                	mv	s1,s8
    80004f90:	bf49                	j	80004f22 <filewrite+0x80>
    int i = 0;
    80004f92:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f94:	033a1d63          	bne	s4,s3,80004fce <filewrite+0x12c>
    80004f98:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f9a:	60a6                	ld	ra,72(sp)
    80004f9c:	6406                	ld	s0,64(sp)
    80004f9e:	74e2                	ld	s1,56(sp)
    80004fa0:	7942                	ld	s2,48(sp)
    80004fa2:	79a2                	ld	s3,40(sp)
    80004fa4:	7a02                	ld	s4,32(sp)
    80004fa6:	6ae2                	ld	s5,24(sp)
    80004fa8:	6b42                	ld	s6,16(sp)
    80004faa:	6ba2                	ld	s7,8(sp)
    80004fac:	6c02                	ld	s8,0(sp)
    80004fae:	6161                	addi	sp,sp,80
    80004fb0:	8082                	ret
    panic("filewrite");
    80004fb2:	00003517          	auipc	a0,0x3
    80004fb6:	73650513          	addi	a0,a0,1846 # 800086e8 <syscalls+0x288>
    80004fba:	ffffb097          	auipc	ra,0xffffb
    80004fbe:	582080e7          	jalr	1410(ra) # 8000053c <panic>
    return -1;
    80004fc2:	557d                	li	a0,-1
}
    80004fc4:	8082                	ret
      return -1;
    80004fc6:	557d                	li	a0,-1
    80004fc8:	bfc9                	j	80004f9a <filewrite+0xf8>
    80004fca:	557d                	li	a0,-1
    80004fcc:	b7f9                	j	80004f9a <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004fce:	557d                	li	a0,-1
    80004fd0:	b7e9                	j	80004f9a <filewrite+0xf8>

0000000080004fd2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fd2:	7179                	addi	sp,sp,-48
    80004fd4:	f406                	sd	ra,40(sp)
    80004fd6:	f022                	sd	s0,32(sp)
    80004fd8:	ec26                	sd	s1,24(sp)
    80004fda:	e84a                	sd	s2,16(sp)
    80004fdc:	e44e                	sd	s3,8(sp)
    80004fde:	e052                	sd	s4,0(sp)
    80004fe0:	1800                	addi	s0,sp,48
    80004fe2:	84aa                	mv	s1,a0
    80004fe4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fe6:	0005b023          	sd	zero,0(a1)
    80004fea:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fee:	00000097          	auipc	ra,0x0
    80004ff2:	bfc080e7          	jalr	-1028(ra) # 80004bea <filealloc>
    80004ff6:	e088                	sd	a0,0(s1)
    80004ff8:	c551                	beqz	a0,80005084 <pipealloc+0xb2>
    80004ffa:	00000097          	auipc	ra,0x0
    80004ffe:	bf0080e7          	jalr	-1040(ra) # 80004bea <filealloc>
    80005002:	00aa3023          	sd	a0,0(s4)
    80005006:	c92d                	beqz	a0,80005078 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	ada080e7          	jalr	-1318(ra) # 80000ae2 <kalloc>
    80005010:	892a                	mv	s2,a0
    80005012:	c125                	beqz	a0,80005072 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005014:	4985                	li	s3,1
    80005016:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000501a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000501e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005022:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005026:	00003597          	auipc	a1,0x3
    8000502a:	6d258593          	addi	a1,a1,1746 # 800086f8 <syscalls+0x298>
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	b14080e7          	jalr	-1260(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80005036:	609c                	ld	a5,0(s1)
    80005038:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000503c:	609c                	ld	a5,0(s1)
    8000503e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005042:	609c                	ld	a5,0(s1)
    80005044:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005048:	609c                	ld	a5,0(s1)
    8000504a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000504e:	000a3783          	ld	a5,0(s4)
    80005052:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005056:	000a3783          	ld	a5,0(s4)
    8000505a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000505e:	000a3783          	ld	a5,0(s4)
    80005062:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005066:	000a3783          	ld	a5,0(s4)
    8000506a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000506e:	4501                	li	a0,0
    80005070:	a025                	j	80005098 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005072:	6088                	ld	a0,0(s1)
    80005074:	e501                	bnez	a0,8000507c <pipealloc+0xaa>
    80005076:	a039                	j	80005084 <pipealloc+0xb2>
    80005078:	6088                	ld	a0,0(s1)
    8000507a:	c51d                	beqz	a0,800050a8 <pipealloc+0xd6>
    fileclose(*f0);
    8000507c:	00000097          	auipc	ra,0x0
    80005080:	c2a080e7          	jalr	-982(ra) # 80004ca6 <fileclose>
  if(*f1)
    80005084:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005088:	557d                	li	a0,-1
  if(*f1)
    8000508a:	c799                	beqz	a5,80005098 <pipealloc+0xc6>
    fileclose(*f1);
    8000508c:	853e                	mv	a0,a5
    8000508e:	00000097          	auipc	ra,0x0
    80005092:	c18080e7          	jalr	-1000(ra) # 80004ca6 <fileclose>
  return -1;
    80005096:	557d                	li	a0,-1
}
    80005098:	70a2                	ld	ra,40(sp)
    8000509a:	7402                	ld	s0,32(sp)
    8000509c:	64e2                	ld	s1,24(sp)
    8000509e:	6942                	ld	s2,16(sp)
    800050a0:	69a2                	ld	s3,8(sp)
    800050a2:	6a02                	ld	s4,0(sp)
    800050a4:	6145                	addi	sp,sp,48
    800050a6:	8082                	ret
  return -1;
    800050a8:	557d                	li	a0,-1
    800050aa:	b7fd                	j	80005098 <pipealloc+0xc6>

00000000800050ac <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050ac:	1101                	addi	sp,sp,-32
    800050ae:	ec06                	sd	ra,24(sp)
    800050b0:	e822                	sd	s0,16(sp)
    800050b2:	e426                	sd	s1,8(sp)
    800050b4:	e04a                	sd	s2,0(sp)
    800050b6:	1000                	addi	s0,sp,32
    800050b8:	84aa                	mv	s1,a0
    800050ba:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	b16080e7          	jalr	-1258(ra) # 80000bd2 <acquire>
  if(writable){
    800050c4:	02090d63          	beqz	s2,800050fe <pipeclose+0x52>
    pi->writeopen = 0;
    800050c8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050cc:	21848513          	addi	a0,s1,536
    800050d0:	ffffd097          	auipc	ra,0xffffd
    800050d4:	2f8080e7          	jalr	760(ra) # 800023c8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050d8:	2204b783          	ld	a5,544(s1)
    800050dc:	eb95                	bnez	a5,80005110 <pipeclose+0x64>
    release(&pi->lock);
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	ba6080e7          	jalr	-1114(ra) # 80000c86 <release>
    kfree((char*)pi);
    800050e8:	8526                	mv	a0,s1
    800050ea:	ffffc097          	auipc	ra,0xffffc
    800050ee:	8fa080e7          	jalr	-1798(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    800050f2:	60e2                	ld	ra,24(sp)
    800050f4:	6442                	ld	s0,16(sp)
    800050f6:	64a2                	ld	s1,8(sp)
    800050f8:	6902                	ld	s2,0(sp)
    800050fa:	6105                	addi	sp,sp,32
    800050fc:	8082                	ret
    pi->readopen = 0;
    800050fe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005102:	21c48513          	addi	a0,s1,540
    80005106:	ffffd097          	auipc	ra,0xffffd
    8000510a:	2c2080e7          	jalr	706(ra) # 800023c8 <wakeup>
    8000510e:	b7e9                	j	800050d8 <pipeclose+0x2c>
    release(&pi->lock);
    80005110:	8526                	mv	a0,s1
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	b74080e7          	jalr	-1164(ra) # 80000c86 <release>
}
    8000511a:	bfe1                	j	800050f2 <pipeclose+0x46>

000000008000511c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000511c:	711d                	addi	sp,sp,-96
    8000511e:	ec86                	sd	ra,88(sp)
    80005120:	e8a2                	sd	s0,80(sp)
    80005122:	e4a6                	sd	s1,72(sp)
    80005124:	e0ca                	sd	s2,64(sp)
    80005126:	fc4e                	sd	s3,56(sp)
    80005128:	f852                	sd	s4,48(sp)
    8000512a:	f456                	sd	s5,40(sp)
    8000512c:	f05a                	sd	s6,32(sp)
    8000512e:	ec5e                	sd	s7,24(sp)
    80005130:	e862                	sd	s8,16(sp)
    80005132:	1080                	addi	s0,sp,96
    80005134:	84aa                	mv	s1,a0
    80005136:	8aae                	mv	s5,a1
    80005138:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000513a:	ffffd097          	auipc	ra,0xffffd
    8000513e:	89c080e7          	jalr	-1892(ra) # 800019d6 <myproc>
    80005142:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005144:	8526                	mv	a0,s1
    80005146:	ffffc097          	auipc	ra,0xffffc
    8000514a:	a8c080e7          	jalr	-1396(ra) # 80000bd2 <acquire>
  while(i < n){
    8000514e:	0b405663          	blez	s4,800051fa <pipewrite+0xde>
  int i = 0;
    80005152:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005154:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005156:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000515a:	21c48b93          	addi	s7,s1,540
    8000515e:	a089                	j	800051a0 <pipewrite+0x84>
      release(&pi->lock);
    80005160:	8526                	mv	a0,s1
    80005162:	ffffc097          	auipc	ra,0xffffc
    80005166:	b24080e7          	jalr	-1244(ra) # 80000c86 <release>
      return -1;
    8000516a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000516c:	854a                	mv	a0,s2
    8000516e:	60e6                	ld	ra,88(sp)
    80005170:	6446                	ld	s0,80(sp)
    80005172:	64a6                	ld	s1,72(sp)
    80005174:	6906                	ld	s2,64(sp)
    80005176:	79e2                	ld	s3,56(sp)
    80005178:	7a42                	ld	s4,48(sp)
    8000517a:	7aa2                	ld	s5,40(sp)
    8000517c:	7b02                	ld	s6,32(sp)
    8000517e:	6be2                	ld	s7,24(sp)
    80005180:	6c42                	ld	s8,16(sp)
    80005182:	6125                	addi	sp,sp,96
    80005184:	8082                	ret
      wakeup(&pi->nread);
    80005186:	8562                	mv	a0,s8
    80005188:	ffffd097          	auipc	ra,0xffffd
    8000518c:	240080e7          	jalr	576(ra) # 800023c8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005190:	85a6                	mv	a1,s1
    80005192:	855e                	mv	a0,s7
    80005194:	ffffd097          	auipc	ra,0xffffd
    80005198:	1d0080e7          	jalr	464(ra) # 80002364 <sleep>
  while(i < n){
    8000519c:	07495063          	bge	s2,s4,800051fc <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800051a0:	2204a783          	lw	a5,544(s1)
    800051a4:	dfd5                	beqz	a5,80005160 <pipewrite+0x44>
    800051a6:	854e                	mv	a0,s3
    800051a8:	ffffd097          	auipc	ra,0xffffd
    800051ac:	48c080e7          	jalr	1164(ra) # 80002634 <killed>
    800051b0:	f945                	bnez	a0,80005160 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051b2:	2184a783          	lw	a5,536(s1)
    800051b6:	21c4a703          	lw	a4,540(s1)
    800051ba:	2007879b          	addiw	a5,a5,512
    800051be:	fcf704e3          	beq	a4,a5,80005186 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051c2:	4685                	li	a3,1
    800051c4:	01590633          	add	a2,s2,s5
    800051c8:	faf40593          	addi	a1,s0,-81
    800051cc:	0509b503          	ld	a0,80(s3)
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	522080e7          	jalr	1314(ra) # 800016f2 <copyin>
    800051d8:	03650263          	beq	a0,s6,800051fc <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051dc:	21c4a783          	lw	a5,540(s1)
    800051e0:	0017871b          	addiw	a4,a5,1
    800051e4:	20e4ae23          	sw	a4,540(s1)
    800051e8:	1ff7f793          	andi	a5,a5,511
    800051ec:	97a6                	add	a5,a5,s1
    800051ee:	faf44703          	lbu	a4,-81(s0)
    800051f2:	00e78c23          	sb	a4,24(a5)
      i++;
    800051f6:	2905                	addiw	s2,s2,1
    800051f8:	b755                	j	8000519c <pipewrite+0x80>
  int i = 0;
    800051fa:	4901                	li	s2,0
  wakeup(&pi->nread);
    800051fc:	21848513          	addi	a0,s1,536
    80005200:	ffffd097          	auipc	ra,0xffffd
    80005204:	1c8080e7          	jalr	456(ra) # 800023c8 <wakeup>
  release(&pi->lock);
    80005208:	8526                	mv	a0,s1
    8000520a:	ffffc097          	auipc	ra,0xffffc
    8000520e:	a7c080e7          	jalr	-1412(ra) # 80000c86 <release>
  return i;
    80005212:	bfa9                	j	8000516c <pipewrite+0x50>

0000000080005214 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005214:	715d                	addi	sp,sp,-80
    80005216:	e486                	sd	ra,72(sp)
    80005218:	e0a2                	sd	s0,64(sp)
    8000521a:	fc26                	sd	s1,56(sp)
    8000521c:	f84a                	sd	s2,48(sp)
    8000521e:	f44e                	sd	s3,40(sp)
    80005220:	f052                	sd	s4,32(sp)
    80005222:	ec56                	sd	s5,24(sp)
    80005224:	e85a                	sd	s6,16(sp)
    80005226:	0880                	addi	s0,sp,80
    80005228:	84aa                	mv	s1,a0
    8000522a:	892e                	mv	s2,a1
    8000522c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000522e:	ffffc097          	auipc	ra,0xffffc
    80005232:	7a8080e7          	jalr	1960(ra) # 800019d6 <myproc>
    80005236:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005238:	8526                	mv	a0,s1
    8000523a:	ffffc097          	auipc	ra,0xffffc
    8000523e:	998080e7          	jalr	-1640(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005242:	2184a703          	lw	a4,536(s1)
    80005246:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000524a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000524e:	02f71763          	bne	a4,a5,8000527c <piperead+0x68>
    80005252:	2244a783          	lw	a5,548(s1)
    80005256:	c39d                	beqz	a5,8000527c <piperead+0x68>
    if(killed(pr)){
    80005258:	8552                	mv	a0,s4
    8000525a:	ffffd097          	auipc	ra,0xffffd
    8000525e:	3da080e7          	jalr	986(ra) # 80002634 <killed>
    80005262:	e949                	bnez	a0,800052f4 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005264:	85a6                	mv	a1,s1
    80005266:	854e                	mv	a0,s3
    80005268:	ffffd097          	auipc	ra,0xffffd
    8000526c:	0fc080e7          	jalr	252(ra) # 80002364 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005270:	2184a703          	lw	a4,536(s1)
    80005274:	21c4a783          	lw	a5,540(s1)
    80005278:	fcf70de3          	beq	a4,a5,80005252 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000527c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000527e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005280:	05505463          	blez	s5,800052c8 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005284:	2184a783          	lw	a5,536(s1)
    80005288:	21c4a703          	lw	a4,540(s1)
    8000528c:	02f70e63          	beq	a4,a5,800052c8 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005290:	0017871b          	addiw	a4,a5,1
    80005294:	20e4ac23          	sw	a4,536(s1)
    80005298:	1ff7f793          	andi	a5,a5,511
    8000529c:	97a6                	add	a5,a5,s1
    8000529e:	0187c783          	lbu	a5,24(a5)
    800052a2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052a6:	4685                	li	a3,1
    800052a8:	fbf40613          	addi	a2,s0,-65
    800052ac:	85ca                	mv	a1,s2
    800052ae:	050a3503          	ld	a0,80(s4)
    800052b2:	ffffc097          	auipc	ra,0xffffc
    800052b6:	3b4080e7          	jalr	948(ra) # 80001666 <copyout>
    800052ba:	01650763          	beq	a0,s6,800052c8 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052be:	2985                	addiw	s3,s3,1
    800052c0:	0905                	addi	s2,s2,1
    800052c2:	fd3a91e3          	bne	s5,s3,80005284 <piperead+0x70>
    800052c6:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052c8:	21c48513          	addi	a0,s1,540
    800052cc:	ffffd097          	auipc	ra,0xffffd
    800052d0:	0fc080e7          	jalr	252(ra) # 800023c8 <wakeup>
  release(&pi->lock);
    800052d4:	8526                	mv	a0,s1
    800052d6:	ffffc097          	auipc	ra,0xffffc
    800052da:	9b0080e7          	jalr	-1616(ra) # 80000c86 <release>
  return i;
}
    800052de:	854e                	mv	a0,s3
    800052e0:	60a6                	ld	ra,72(sp)
    800052e2:	6406                	ld	s0,64(sp)
    800052e4:	74e2                	ld	s1,56(sp)
    800052e6:	7942                	ld	s2,48(sp)
    800052e8:	79a2                	ld	s3,40(sp)
    800052ea:	7a02                	ld	s4,32(sp)
    800052ec:	6ae2                	ld	s5,24(sp)
    800052ee:	6b42                	ld	s6,16(sp)
    800052f0:	6161                	addi	sp,sp,80
    800052f2:	8082                	ret
      release(&pi->lock);
    800052f4:	8526                	mv	a0,s1
    800052f6:	ffffc097          	auipc	ra,0xffffc
    800052fa:	990080e7          	jalr	-1648(ra) # 80000c86 <release>
      return -1;
    800052fe:	59fd                	li	s3,-1
    80005300:	bff9                	j	800052de <piperead+0xca>

0000000080005302 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005302:	1141                	addi	sp,sp,-16
    80005304:	e422                	sd	s0,8(sp)
    80005306:	0800                	addi	s0,sp,16
    80005308:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000530a:	8905                	andi	a0,a0,1
    8000530c:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000530e:	8b89                	andi	a5,a5,2
    80005310:	c399                	beqz	a5,80005316 <flags2perm+0x14>
      perm |= PTE_W;
    80005312:	00456513          	ori	a0,a0,4
    return perm;
}
    80005316:	6422                	ld	s0,8(sp)
    80005318:	0141                	addi	sp,sp,16
    8000531a:	8082                	ret

000000008000531c <exec>:

int
exec(char *path, char **argv)
{
    8000531c:	df010113          	addi	sp,sp,-528
    80005320:	20113423          	sd	ra,520(sp)
    80005324:	20813023          	sd	s0,512(sp)
    80005328:	ffa6                	sd	s1,504(sp)
    8000532a:	fbca                	sd	s2,496(sp)
    8000532c:	f7ce                	sd	s3,488(sp)
    8000532e:	f3d2                	sd	s4,480(sp)
    80005330:	efd6                	sd	s5,472(sp)
    80005332:	ebda                	sd	s6,464(sp)
    80005334:	e7de                	sd	s7,456(sp)
    80005336:	e3e2                	sd	s8,448(sp)
    80005338:	ff66                	sd	s9,440(sp)
    8000533a:	fb6a                	sd	s10,432(sp)
    8000533c:	f76e                	sd	s11,424(sp)
    8000533e:	0c00                	addi	s0,sp,528
    80005340:	892a                	mv	s2,a0
    80005342:	dea43c23          	sd	a0,-520(s0)
    80005346:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000534a:	ffffc097          	auipc	ra,0xffffc
    8000534e:	68c080e7          	jalr	1676(ra) # 800019d6 <myproc>
    80005352:	84aa                	mv	s1,a0

  begin_op();
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	48e080e7          	jalr	1166(ra) # 800047e2 <begin_op>

  if((ip = namei(path)) == 0){
    8000535c:	854a                	mv	a0,s2
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	284080e7          	jalr	644(ra) # 800045e2 <namei>
    80005366:	c92d                	beqz	a0,800053d8 <exec+0xbc>
    80005368:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	ad2080e7          	jalr	-1326(ra) # 80003e3c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005372:	04000713          	li	a4,64
    80005376:	4681                	li	a3,0
    80005378:	e5040613          	addi	a2,s0,-432
    8000537c:	4581                	li	a1,0
    8000537e:	8552                	mv	a0,s4
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	d70080e7          	jalr	-656(ra) # 800040f0 <readi>
    80005388:	04000793          	li	a5,64
    8000538c:	00f51a63          	bne	a0,a5,800053a0 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005390:	e5042703          	lw	a4,-432(s0)
    80005394:	464c47b7          	lui	a5,0x464c4
    80005398:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000539c:	04f70463          	beq	a4,a5,800053e4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053a0:	8552                	mv	a0,s4
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	cfc080e7          	jalr	-772(ra) # 8000409e <iunlockput>
    end_op();
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	4b2080e7          	jalr	1202(ra) # 8000485c <end_op>
  }
  return -1;
    800053b2:	557d                	li	a0,-1
}
    800053b4:	20813083          	ld	ra,520(sp)
    800053b8:	20013403          	ld	s0,512(sp)
    800053bc:	74fe                	ld	s1,504(sp)
    800053be:	795e                	ld	s2,496(sp)
    800053c0:	79be                	ld	s3,488(sp)
    800053c2:	7a1e                	ld	s4,480(sp)
    800053c4:	6afe                	ld	s5,472(sp)
    800053c6:	6b5e                	ld	s6,464(sp)
    800053c8:	6bbe                	ld	s7,456(sp)
    800053ca:	6c1e                	ld	s8,448(sp)
    800053cc:	7cfa                	ld	s9,440(sp)
    800053ce:	7d5a                	ld	s10,432(sp)
    800053d0:	7dba                	ld	s11,424(sp)
    800053d2:	21010113          	addi	sp,sp,528
    800053d6:	8082                	ret
    end_op();
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	484080e7          	jalr	1156(ra) # 8000485c <end_op>
    return -1;
    800053e0:	557d                	li	a0,-1
    800053e2:	bfc9                	j	800053b4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053e4:	8526                	mv	a0,s1
    800053e6:	ffffc097          	auipc	ra,0xffffc
    800053ea:	7c6080e7          	jalr	1990(ra) # 80001bac <proc_pagetable>
    800053ee:	8b2a                	mv	s6,a0
    800053f0:	d945                	beqz	a0,800053a0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053f2:	e7042d03          	lw	s10,-400(s0)
    800053f6:	e8845783          	lhu	a5,-376(s0)
    800053fa:	10078463          	beqz	a5,80005502 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053fe:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005400:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005402:	6c85                	lui	s9,0x1
    80005404:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005408:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000540c:	6a85                	lui	s5,0x1
    8000540e:	a0b5                	j	8000547a <exec+0x15e>
      panic("loadseg: address should exist");
    80005410:	00003517          	auipc	a0,0x3
    80005414:	2f050513          	addi	a0,a0,752 # 80008700 <syscalls+0x2a0>
    80005418:	ffffb097          	auipc	ra,0xffffb
    8000541c:	124080e7          	jalr	292(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005420:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005422:	8726                	mv	a4,s1
    80005424:	012c06bb          	addw	a3,s8,s2
    80005428:	4581                	li	a1,0
    8000542a:	8552                	mv	a0,s4
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	cc4080e7          	jalr	-828(ra) # 800040f0 <readi>
    80005434:	2501                	sext.w	a0,a0
    80005436:	24a49863          	bne	s1,a0,80005686 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    8000543a:	012a893b          	addw	s2,s5,s2
    8000543e:	03397563          	bgeu	s2,s3,80005468 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005442:	02091593          	slli	a1,s2,0x20
    80005446:	9181                	srli	a1,a1,0x20
    80005448:	95de                	add	a1,a1,s7
    8000544a:	855a                	mv	a0,s6
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	c0a080e7          	jalr	-1014(ra) # 80001056 <walkaddr>
    80005454:	862a                	mv	a2,a0
    if(pa == 0)
    80005456:	dd4d                	beqz	a0,80005410 <exec+0xf4>
    if(sz - i < PGSIZE)
    80005458:	412984bb          	subw	s1,s3,s2
    8000545c:	0004879b          	sext.w	a5,s1
    80005460:	fcfcf0e3          	bgeu	s9,a5,80005420 <exec+0x104>
    80005464:	84d6                	mv	s1,s5
    80005466:	bf6d                	j	80005420 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005468:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000546c:	2d85                	addiw	s11,s11,1
    8000546e:	038d0d1b          	addiw	s10,s10,56
    80005472:	e8845783          	lhu	a5,-376(s0)
    80005476:	08fdd763          	bge	s11,a5,80005504 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000547a:	2d01                	sext.w	s10,s10
    8000547c:	03800713          	li	a4,56
    80005480:	86ea                	mv	a3,s10
    80005482:	e1840613          	addi	a2,s0,-488
    80005486:	4581                	li	a1,0
    80005488:	8552                	mv	a0,s4
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	c66080e7          	jalr	-922(ra) # 800040f0 <readi>
    80005492:	03800793          	li	a5,56
    80005496:	1ef51663          	bne	a0,a5,80005682 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    8000549a:	e1842783          	lw	a5,-488(s0)
    8000549e:	4705                	li	a4,1
    800054a0:	fce796e3          	bne	a5,a4,8000546c <exec+0x150>
    if(ph.memsz < ph.filesz)
    800054a4:	e4043483          	ld	s1,-448(s0)
    800054a8:	e3843783          	ld	a5,-456(s0)
    800054ac:	1ef4e863          	bltu	s1,a5,8000569c <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054b0:	e2843783          	ld	a5,-472(s0)
    800054b4:	94be                	add	s1,s1,a5
    800054b6:	1ef4e663          	bltu	s1,a5,800056a2 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800054ba:	df043703          	ld	a4,-528(s0)
    800054be:	8ff9                	and	a5,a5,a4
    800054c0:	1e079463          	bnez	a5,800056a8 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054c4:	e1c42503          	lw	a0,-484(s0)
    800054c8:	00000097          	auipc	ra,0x0
    800054cc:	e3a080e7          	jalr	-454(ra) # 80005302 <flags2perm>
    800054d0:	86aa                	mv	a3,a0
    800054d2:	8626                	mv	a2,s1
    800054d4:	85ca                	mv	a1,s2
    800054d6:	855a                	mv	a0,s6
    800054d8:	ffffc097          	auipc	ra,0xffffc
    800054dc:	f32080e7          	jalr	-206(ra) # 8000140a <uvmalloc>
    800054e0:	e0a43423          	sd	a0,-504(s0)
    800054e4:	1c050563          	beqz	a0,800056ae <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054e8:	e2843b83          	ld	s7,-472(s0)
    800054ec:	e2042c03          	lw	s8,-480(s0)
    800054f0:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054f4:	00098463          	beqz	s3,800054fc <exec+0x1e0>
    800054f8:	4901                	li	s2,0
    800054fa:	b7a1                	j	80005442 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054fc:	e0843903          	ld	s2,-504(s0)
    80005500:	b7b5                	j	8000546c <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005502:	4901                	li	s2,0
  iunlockput(ip);
    80005504:	8552                	mv	a0,s4
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	b98080e7          	jalr	-1128(ra) # 8000409e <iunlockput>
  end_op();
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	34e080e7          	jalr	846(ra) # 8000485c <end_op>
  p = myproc();
    80005516:	ffffc097          	auipc	ra,0xffffc
    8000551a:	4c0080e7          	jalr	1216(ra) # 800019d6 <myproc>
    8000551e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005520:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005524:	6985                	lui	s3,0x1
    80005526:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005528:	99ca                	add	s3,s3,s2
    8000552a:	77fd                	lui	a5,0xfffff
    8000552c:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005530:	4691                	li	a3,4
    80005532:	6609                	lui	a2,0x2
    80005534:	964e                	add	a2,a2,s3
    80005536:	85ce                	mv	a1,s3
    80005538:	855a                	mv	a0,s6
    8000553a:	ffffc097          	auipc	ra,0xffffc
    8000553e:	ed0080e7          	jalr	-304(ra) # 8000140a <uvmalloc>
    80005542:	892a                	mv	s2,a0
    80005544:	e0a43423          	sd	a0,-504(s0)
    80005548:	e509                	bnez	a0,80005552 <exec+0x236>
  if(pagetable)
    8000554a:	e1343423          	sd	s3,-504(s0)
    8000554e:	4a01                	li	s4,0
    80005550:	aa1d                	j	80005686 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005552:	75f9                	lui	a1,0xffffe
    80005554:	95aa                	add	a1,a1,a0
    80005556:	855a                	mv	a0,s6
    80005558:	ffffc097          	auipc	ra,0xffffc
    8000555c:	0dc080e7          	jalr	220(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80005560:	7bfd                	lui	s7,0xfffff
    80005562:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005564:	e0043783          	ld	a5,-512(s0)
    80005568:	6388                	ld	a0,0(a5)
    8000556a:	c52d                	beqz	a0,800055d4 <exec+0x2b8>
    8000556c:	e9040993          	addi	s3,s0,-368
    80005570:	f9040c13          	addi	s8,s0,-112
    80005574:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005576:	ffffc097          	auipc	ra,0xffffc
    8000557a:	8d2080e7          	jalr	-1838(ra) # 80000e48 <strlen>
    8000557e:	0015079b          	addiw	a5,a0,1
    80005582:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005586:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000558a:	13796563          	bltu	s2,s7,800056b4 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000558e:	e0043d03          	ld	s10,-512(s0)
    80005592:	000d3a03          	ld	s4,0(s10)
    80005596:	8552                	mv	a0,s4
    80005598:	ffffc097          	auipc	ra,0xffffc
    8000559c:	8b0080e7          	jalr	-1872(ra) # 80000e48 <strlen>
    800055a0:	0015069b          	addiw	a3,a0,1
    800055a4:	8652                	mv	a2,s4
    800055a6:	85ca                	mv	a1,s2
    800055a8:	855a                	mv	a0,s6
    800055aa:	ffffc097          	auipc	ra,0xffffc
    800055ae:	0bc080e7          	jalr	188(ra) # 80001666 <copyout>
    800055b2:	10054363          	bltz	a0,800056b8 <exec+0x39c>
    ustack[argc] = sp;
    800055b6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055ba:	0485                	addi	s1,s1,1
    800055bc:	008d0793          	addi	a5,s10,8
    800055c0:	e0f43023          	sd	a5,-512(s0)
    800055c4:	008d3503          	ld	a0,8(s10)
    800055c8:	c909                	beqz	a0,800055da <exec+0x2be>
    if(argc >= MAXARG)
    800055ca:	09a1                	addi	s3,s3,8
    800055cc:	fb8995e3          	bne	s3,s8,80005576 <exec+0x25a>
  ip = 0;
    800055d0:	4a01                	li	s4,0
    800055d2:	a855                	j	80005686 <exec+0x36a>
  sp = sz;
    800055d4:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800055d8:	4481                	li	s1,0
  ustack[argc] = 0;
    800055da:	00349793          	slli	a5,s1,0x3
    800055de:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdaf60>
    800055e2:	97a2                	add	a5,a5,s0
    800055e4:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800055e8:	00148693          	addi	a3,s1,1
    800055ec:	068e                	slli	a3,a3,0x3
    800055ee:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800055f2:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800055f6:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800055fa:	f57968e3          	bltu	s2,s7,8000554a <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800055fe:	e9040613          	addi	a2,s0,-368
    80005602:	85ca                	mv	a1,s2
    80005604:	855a                	mv	a0,s6
    80005606:	ffffc097          	auipc	ra,0xffffc
    8000560a:	060080e7          	jalr	96(ra) # 80001666 <copyout>
    8000560e:	0a054763          	bltz	a0,800056bc <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005612:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005616:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000561a:	df843783          	ld	a5,-520(s0)
    8000561e:	0007c703          	lbu	a4,0(a5)
    80005622:	cf11                	beqz	a4,8000563e <exec+0x322>
    80005624:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005626:	02f00693          	li	a3,47
    8000562a:	a039                	j	80005638 <exec+0x31c>
      last = s+1;
    8000562c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005630:	0785                	addi	a5,a5,1
    80005632:	fff7c703          	lbu	a4,-1(a5)
    80005636:	c701                	beqz	a4,8000563e <exec+0x322>
    if(*s == '/')
    80005638:	fed71ce3          	bne	a4,a3,80005630 <exec+0x314>
    8000563c:	bfc5                	j	8000562c <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    8000563e:	4641                	li	a2,16
    80005640:	df843583          	ld	a1,-520(s0)
    80005644:	158a8513          	addi	a0,s5,344
    80005648:	ffffb097          	auipc	ra,0xffffb
    8000564c:	7ce080e7          	jalr	1998(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005650:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005654:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005658:	e0843783          	ld	a5,-504(s0)
    8000565c:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005660:	058ab783          	ld	a5,88(s5)
    80005664:	e6843703          	ld	a4,-408(s0)
    80005668:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000566a:	058ab783          	ld	a5,88(s5)
    8000566e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005672:	85e6                	mv	a1,s9
    80005674:	ffffc097          	auipc	ra,0xffffc
    80005678:	5d4080e7          	jalr	1492(ra) # 80001c48 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000567c:	0004851b          	sext.w	a0,s1
    80005680:	bb15                	j	800053b4 <exec+0x98>
    80005682:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005686:	e0843583          	ld	a1,-504(s0)
    8000568a:	855a                	mv	a0,s6
    8000568c:	ffffc097          	auipc	ra,0xffffc
    80005690:	5bc080e7          	jalr	1468(ra) # 80001c48 <proc_freepagetable>
  return -1;
    80005694:	557d                	li	a0,-1
  if(ip){
    80005696:	d00a0fe3          	beqz	s4,800053b4 <exec+0x98>
    8000569a:	b319                	j	800053a0 <exec+0x84>
    8000569c:	e1243423          	sd	s2,-504(s0)
    800056a0:	b7dd                	j	80005686 <exec+0x36a>
    800056a2:	e1243423          	sd	s2,-504(s0)
    800056a6:	b7c5                	j	80005686 <exec+0x36a>
    800056a8:	e1243423          	sd	s2,-504(s0)
    800056ac:	bfe9                	j	80005686 <exec+0x36a>
    800056ae:	e1243423          	sd	s2,-504(s0)
    800056b2:	bfd1                	j	80005686 <exec+0x36a>
  ip = 0;
    800056b4:	4a01                	li	s4,0
    800056b6:	bfc1                	j	80005686 <exec+0x36a>
    800056b8:	4a01                	li	s4,0
  if(pagetable)
    800056ba:	b7f1                	j	80005686 <exec+0x36a>
  sz = sz1;
    800056bc:	e0843983          	ld	s3,-504(s0)
    800056c0:	b569                	j	8000554a <exec+0x22e>

00000000800056c2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056c2:	7179                	addi	sp,sp,-48
    800056c4:	f406                	sd	ra,40(sp)
    800056c6:	f022                	sd	s0,32(sp)
    800056c8:	ec26                	sd	s1,24(sp)
    800056ca:	e84a                	sd	s2,16(sp)
    800056cc:	1800                	addi	s0,sp,48
    800056ce:	892e                	mv	s2,a1
    800056d0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800056d2:	fdc40593          	addi	a1,s0,-36
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	acc080e7          	jalr	-1332(ra) # 800031a2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056de:	fdc42703          	lw	a4,-36(s0)
    800056e2:	47bd                	li	a5,15
    800056e4:	02e7eb63          	bltu	a5,a4,8000571a <argfd+0x58>
    800056e8:	ffffc097          	auipc	ra,0xffffc
    800056ec:	2ee080e7          	jalr	750(ra) # 800019d6 <myproc>
    800056f0:	fdc42703          	lw	a4,-36(s0)
    800056f4:	01a70793          	addi	a5,a4,26
    800056f8:	078e                	slli	a5,a5,0x3
    800056fa:	953e                	add	a0,a0,a5
    800056fc:	611c                	ld	a5,0(a0)
    800056fe:	c385                	beqz	a5,8000571e <argfd+0x5c>
    return -1;
  if(pfd)
    80005700:	00090463          	beqz	s2,80005708 <argfd+0x46>
    *pfd = fd;
    80005704:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005708:	4501                	li	a0,0
  if(pf)
    8000570a:	c091                	beqz	s1,8000570e <argfd+0x4c>
    *pf = f;
    8000570c:	e09c                	sd	a5,0(s1)
}
    8000570e:	70a2                	ld	ra,40(sp)
    80005710:	7402                	ld	s0,32(sp)
    80005712:	64e2                	ld	s1,24(sp)
    80005714:	6942                	ld	s2,16(sp)
    80005716:	6145                	addi	sp,sp,48
    80005718:	8082                	ret
    return -1;
    8000571a:	557d                	li	a0,-1
    8000571c:	bfcd                	j	8000570e <argfd+0x4c>
    8000571e:	557d                	li	a0,-1
    80005720:	b7fd                	j	8000570e <argfd+0x4c>

0000000080005722 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005722:	1101                	addi	sp,sp,-32
    80005724:	ec06                	sd	ra,24(sp)
    80005726:	e822                	sd	s0,16(sp)
    80005728:	e426                	sd	s1,8(sp)
    8000572a:	1000                	addi	s0,sp,32
    8000572c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000572e:	ffffc097          	auipc	ra,0xffffc
    80005732:	2a8080e7          	jalr	680(ra) # 800019d6 <myproc>
    80005736:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005738:	0d050793          	addi	a5,a0,208
    8000573c:	4501                	li	a0,0
    8000573e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005740:	6398                	ld	a4,0(a5)
    80005742:	cb19                	beqz	a4,80005758 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005744:	2505                	addiw	a0,a0,1
    80005746:	07a1                	addi	a5,a5,8
    80005748:	fed51ce3          	bne	a0,a3,80005740 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000574c:	557d                	li	a0,-1
}
    8000574e:	60e2                	ld	ra,24(sp)
    80005750:	6442                	ld	s0,16(sp)
    80005752:	64a2                	ld	s1,8(sp)
    80005754:	6105                	addi	sp,sp,32
    80005756:	8082                	ret
      p->ofile[fd] = f;
    80005758:	01a50793          	addi	a5,a0,26
    8000575c:	078e                	slli	a5,a5,0x3
    8000575e:	963e                	add	a2,a2,a5
    80005760:	e204                	sd	s1,0(a2)
      return fd;
    80005762:	b7f5                	j	8000574e <fdalloc+0x2c>

0000000080005764 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005764:	715d                	addi	sp,sp,-80
    80005766:	e486                	sd	ra,72(sp)
    80005768:	e0a2                	sd	s0,64(sp)
    8000576a:	fc26                	sd	s1,56(sp)
    8000576c:	f84a                	sd	s2,48(sp)
    8000576e:	f44e                	sd	s3,40(sp)
    80005770:	f052                	sd	s4,32(sp)
    80005772:	ec56                	sd	s5,24(sp)
    80005774:	e85a                	sd	s6,16(sp)
    80005776:	0880                	addi	s0,sp,80
    80005778:	8b2e                	mv	s6,a1
    8000577a:	89b2                	mv	s3,a2
    8000577c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000577e:	fb040593          	addi	a1,s0,-80
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	e7e080e7          	jalr	-386(ra) # 80004600 <nameiparent>
    8000578a:	84aa                	mv	s1,a0
    8000578c:	14050b63          	beqz	a0,800058e2 <create+0x17e>
    return 0;

  ilock(dp);
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	6ac080e7          	jalr	1708(ra) # 80003e3c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005798:	4601                	li	a2,0
    8000579a:	fb040593          	addi	a1,s0,-80
    8000579e:	8526                	mv	a0,s1
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	b80080e7          	jalr	-1152(ra) # 80004320 <dirlookup>
    800057a8:	8aaa                	mv	s5,a0
    800057aa:	c921                	beqz	a0,800057fa <create+0x96>
    iunlockput(dp);
    800057ac:	8526                	mv	a0,s1
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	8f0080e7          	jalr	-1808(ra) # 8000409e <iunlockput>
    ilock(ip);
    800057b6:	8556                	mv	a0,s5
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	684080e7          	jalr	1668(ra) # 80003e3c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057c0:	4789                	li	a5,2
    800057c2:	02fb1563          	bne	s6,a5,800057ec <create+0x88>
    800057c6:	044ad783          	lhu	a5,68(s5)
    800057ca:	37f9                	addiw	a5,a5,-2
    800057cc:	17c2                	slli	a5,a5,0x30
    800057ce:	93c1                	srli	a5,a5,0x30
    800057d0:	4705                	li	a4,1
    800057d2:	00f76d63          	bltu	a4,a5,800057ec <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800057d6:	8556                	mv	a0,s5
    800057d8:	60a6                	ld	ra,72(sp)
    800057da:	6406                	ld	s0,64(sp)
    800057dc:	74e2                	ld	s1,56(sp)
    800057de:	7942                	ld	s2,48(sp)
    800057e0:	79a2                	ld	s3,40(sp)
    800057e2:	7a02                	ld	s4,32(sp)
    800057e4:	6ae2                	ld	s5,24(sp)
    800057e6:	6b42                	ld	s6,16(sp)
    800057e8:	6161                	addi	sp,sp,80
    800057ea:	8082                	ret
    iunlockput(ip);
    800057ec:	8556                	mv	a0,s5
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	8b0080e7          	jalr	-1872(ra) # 8000409e <iunlockput>
    return 0;
    800057f6:	4a81                	li	s5,0
    800057f8:	bff9                	j	800057d6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800057fa:	85da                	mv	a1,s6
    800057fc:	4088                	lw	a0,0(s1)
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	4a6080e7          	jalr	1190(ra) # 80003ca4 <ialloc>
    80005806:	8a2a                	mv	s4,a0
    80005808:	c529                	beqz	a0,80005852 <create+0xee>
  ilock(ip);
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	632080e7          	jalr	1586(ra) # 80003e3c <ilock>
  ip->major = major;
    80005812:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005816:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000581a:	4905                	li	s2,1
    8000581c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005820:	8552                	mv	a0,s4
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	54e080e7          	jalr	1358(ra) # 80003d70 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000582a:	032b0b63          	beq	s6,s2,80005860 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000582e:	004a2603          	lw	a2,4(s4)
    80005832:	fb040593          	addi	a1,s0,-80
    80005836:	8526                	mv	a0,s1
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	cf8080e7          	jalr	-776(ra) # 80004530 <dirlink>
    80005840:	06054f63          	bltz	a0,800058be <create+0x15a>
  iunlockput(dp);
    80005844:	8526                	mv	a0,s1
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	858080e7          	jalr	-1960(ra) # 8000409e <iunlockput>
  return ip;
    8000584e:	8ad2                	mv	s5,s4
    80005850:	b759                	j	800057d6 <create+0x72>
    iunlockput(dp);
    80005852:	8526                	mv	a0,s1
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	84a080e7          	jalr	-1974(ra) # 8000409e <iunlockput>
    return 0;
    8000585c:	8ad2                	mv	s5,s4
    8000585e:	bfa5                	j	800057d6 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005860:	004a2603          	lw	a2,4(s4)
    80005864:	00003597          	auipc	a1,0x3
    80005868:	ebc58593          	addi	a1,a1,-324 # 80008720 <syscalls+0x2c0>
    8000586c:	8552                	mv	a0,s4
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	cc2080e7          	jalr	-830(ra) # 80004530 <dirlink>
    80005876:	04054463          	bltz	a0,800058be <create+0x15a>
    8000587a:	40d0                	lw	a2,4(s1)
    8000587c:	00003597          	auipc	a1,0x3
    80005880:	eac58593          	addi	a1,a1,-340 # 80008728 <syscalls+0x2c8>
    80005884:	8552                	mv	a0,s4
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	caa080e7          	jalr	-854(ra) # 80004530 <dirlink>
    8000588e:	02054863          	bltz	a0,800058be <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005892:	004a2603          	lw	a2,4(s4)
    80005896:	fb040593          	addi	a1,s0,-80
    8000589a:	8526                	mv	a0,s1
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	c94080e7          	jalr	-876(ra) # 80004530 <dirlink>
    800058a4:	00054d63          	bltz	a0,800058be <create+0x15a>
    dp->nlink++;  // for ".."
    800058a8:	04a4d783          	lhu	a5,74(s1)
    800058ac:	2785                	addiw	a5,a5,1
    800058ae:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	4bc080e7          	jalr	1212(ra) # 80003d70 <iupdate>
    800058bc:	b761                	j	80005844 <create+0xe0>
  ip->nlink = 0;
    800058be:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800058c2:	8552                	mv	a0,s4
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	4ac080e7          	jalr	1196(ra) # 80003d70 <iupdate>
  iunlockput(ip);
    800058cc:	8552                	mv	a0,s4
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	7d0080e7          	jalr	2000(ra) # 8000409e <iunlockput>
  iunlockput(dp);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	7c6080e7          	jalr	1990(ra) # 8000409e <iunlockput>
  return 0;
    800058e0:	bddd                	j	800057d6 <create+0x72>
    return 0;
    800058e2:	8aaa                	mv	s5,a0
    800058e4:	bdcd                	j	800057d6 <create+0x72>

00000000800058e6 <sys_dup>:
{
    800058e6:	7179                	addi	sp,sp,-48
    800058e8:	f406                	sd	ra,40(sp)
    800058ea:	f022                	sd	s0,32(sp)
    800058ec:	ec26                	sd	s1,24(sp)
    800058ee:	e84a                	sd	s2,16(sp)
    800058f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058f2:	fd840613          	addi	a2,s0,-40
    800058f6:	4581                	li	a1,0
    800058f8:	4501                	li	a0,0
    800058fa:	00000097          	auipc	ra,0x0
    800058fe:	dc8080e7          	jalr	-568(ra) # 800056c2 <argfd>
    return -1;
    80005902:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005904:	02054363          	bltz	a0,8000592a <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005908:	fd843903          	ld	s2,-40(s0)
    8000590c:	854a                	mv	a0,s2
    8000590e:	00000097          	auipc	ra,0x0
    80005912:	e14080e7          	jalr	-492(ra) # 80005722 <fdalloc>
    80005916:	84aa                	mv	s1,a0
    return -1;
    80005918:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000591a:	00054863          	bltz	a0,8000592a <sys_dup+0x44>
  filedup(f);
    8000591e:	854a                	mv	a0,s2
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	334080e7          	jalr	820(ra) # 80004c54 <filedup>
  return fd;
    80005928:	87a6                	mv	a5,s1
}
    8000592a:	853e                	mv	a0,a5
    8000592c:	70a2                	ld	ra,40(sp)
    8000592e:	7402                	ld	s0,32(sp)
    80005930:	64e2                	ld	s1,24(sp)
    80005932:	6942                	ld	s2,16(sp)
    80005934:	6145                	addi	sp,sp,48
    80005936:	8082                	ret

0000000080005938 <sys_read>:
{
    80005938:	7179                	addi	sp,sp,-48
    8000593a:	f406                	sd	ra,40(sp)
    8000593c:	f022                	sd	s0,32(sp)
    8000593e:	1800                	addi	s0,sp,48
  READCOUNT++;
    80005940:	00003717          	auipc	a4,0x3
    80005944:	fd870713          	addi	a4,a4,-40 # 80008918 <READCOUNT>
    80005948:	631c                	ld	a5,0(a4)
    8000594a:	0785                	addi	a5,a5,1
    8000594c:	e31c                	sd	a5,0(a4)
  argaddr(1, &p);
    8000594e:	fd840593          	addi	a1,s0,-40
    80005952:	4505                	li	a0,1
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	86e080e7          	jalr	-1938(ra) # 800031c2 <argaddr>
  argint(2, &n);
    8000595c:	fe440593          	addi	a1,s0,-28
    80005960:	4509                	li	a0,2
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	840080e7          	jalr	-1984(ra) # 800031a2 <argint>
  if(argfd(0, 0, &f) < 0)
    8000596a:	fe840613          	addi	a2,s0,-24
    8000596e:	4581                	li	a1,0
    80005970:	4501                	li	a0,0
    80005972:	00000097          	auipc	ra,0x0
    80005976:	d50080e7          	jalr	-688(ra) # 800056c2 <argfd>
    8000597a:	87aa                	mv	a5,a0
    return -1;
    8000597c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000597e:	0007cc63          	bltz	a5,80005996 <sys_read+0x5e>
  return fileread(f, p, n);
    80005982:	fe442603          	lw	a2,-28(s0)
    80005986:	fd843583          	ld	a1,-40(s0)
    8000598a:	fe843503          	ld	a0,-24(s0)
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	452080e7          	jalr	1106(ra) # 80004de0 <fileread>
}
    80005996:	70a2                	ld	ra,40(sp)
    80005998:	7402                	ld	s0,32(sp)
    8000599a:	6145                	addi	sp,sp,48
    8000599c:	8082                	ret

000000008000599e <sys_write>:
{
    8000599e:	7179                	addi	sp,sp,-48
    800059a0:	f406                	sd	ra,40(sp)
    800059a2:	f022                	sd	s0,32(sp)
    800059a4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800059a6:	fd840593          	addi	a1,s0,-40
    800059aa:	4505                	li	a0,1
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	816080e7          	jalr	-2026(ra) # 800031c2 <argaddr>
  argint(2, &n);
    800059b4:	fe440593          	addi	a1,s0,-28
    800059b8:	4509                	li	a0,2
    800059ba:	ffffd097          	auipc	ra,0xffffd
    800059be:	7e8080e7          	jalr	2024(ra) # 800031a2 <argint>
  if(argfd(0, 0, &f) < 0)
    800059c2:	fe840613          	addi	a2,s0,-24
    800059c6:	4581                	li	a1,0
    800059c8:	4501                	li	a0,0
    800059ca:	00000097          	auipc	ra,0x0
    800059ce:	cf8080e7          	jalr	-776(ra) # 800056c2 <argfd>
    800059d2:	87aa                	mv	a5,a0
    return -1;
    800059d4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059d6:	0007cc63          	bltz	a5,800059ee <sys_write+0x50>
  return filewrite(f, p, n);
    800059da:	fe442603          	lw	a2,-28(s0)
    800059de:	fd843583          	ld	a1,-40(s0)
    800059e2:	fe843503          	ld	a0,-24(s0)
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	4bc080e7          	jalr	1212(ra) # 80004ea2 <filewrite>
}
    800059ee:	70a2                	ld	ra,40(sp)
    800059f0:	7402                	ld	s0,32(sp)
    800059f2:	6145                	addi	sp,sp,48
    800059f4:	8082                	ret

00000000800059f6 <sys_close>:
{
    800059f6:	1101                	addi	sp,sp,-32
    800059f8:	ec06                	sd	ra,24(sp)
    800059fa:	e822                	sd	s0,16(sp)
    800059fc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059fe:	fe040613          	addi	a2,s0,-32
    80005a02:	fec40593          	addi	a1,s0,-20
    80005a06:	4501                	li	a0,0
    80005a08:	00000097          	auipc	ra,0x0
    80005a0c:	cba080e7          	jalr	-838(ra) # 800056c2 <argfd>
    return -1;
    80005a10:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a12:	02054463          	bltz	a0,80005a3a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a16:	ffffc097          	auipc	ra,0xffffc
    80005a1a:	fc0080e7          	jalr	-64(ra) # 800019d6 <myproc>
    80005a1e:	fec42783          	lw	a5,-20(s0)
    80005a22:	07e9                	addi	a5,a5,26
    80005a24:	078e                	slli	a5,a5,0x3
    80005a26:	953e                	add	a0,a0,a5
    80005a28:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005a2c:	fe043503          	ld	a0,-32(s0)
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	276080e7          	jalr	630(ra) # 80004ca6 <fileclose>
  return 0;
    80005a38:	4781                	li	a5,0
}
    80005a3a:	853e                	mv	a0,a5
    80005a3c:	60e2                	ld	ra,24(sp)
    80005a3e:	6442                	ld	s0,16(sp)
    80005a40:	6105                	addi	sp,sp,32
    80005a42:	8082                	ret

0000000080005a44 <sys_fstat>:
{
    80005a44:	1101                	addi	sp,sp,-32
    80005a46:	ec06                	sd	ra,24(sp)
    80005a48:	e822                	sd	s0,16(sp)
    80005a4a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005a4c:	fe040593          	addi	a1,s0,-32
    80005a50:	4505                	li	a0,1
    80005a52:	ffffd097          	auipc	ra,0xffffd
    80005a56:	770080e7          	jalr	1904(ra) # 800031c2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005a5a:	fe840613          	addi	a2,s0,-24
    80005a5e:	4581                	li	a1,0
    80005a60:	4501                	li	a0,0
    80005a62:	00000097          	auipc	ra,0x0
    80005a66:	c60080e7          	jalr	-928(ra) # 800056c2 <argfd>
    80005a6a:	87aa                	mv	a5,a0
    return -1;
    80005a6c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a6e:	0007ca63          	bltz	a5,80005a82 <sys_fstat+0x3e>
  return filestat(f, st);
    80005a72:	fe043583          	ld	a1,-32(s0)
    80005a76:	fe843503          	ld	a0,-24(s0)
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	2f4080e7          	jalr	756(ra) # 80004d6e <filestat>
}
    80005a82:	60e2                	ld	ra,24(sp)
    80005a84:	6442                	ld	s0,16(sp)
    80005a86:	6105                	addi	sp,sp,32
    80005a88:	8082                	ret

0000000080005a8a <sys_link>:
{
    80005a8a:	7169                	addi	sp,sp,-304
    80005a8c:	f606                	sd	ra,296(sp)
    80005a8e:	f222                	sd	s0,288(sp)
    80005a90:	ee26                	sd	s1,280(sp)
    80005a92:	ea4a                	sd	s2,272(sp)
    80005a94:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a96:	08000613          	li	a2,128
    80005a9a:	ed040593          	addi	a1,s0,-304
    80005a9e:	4501                	li	a0,0
    80005aa0:	ffffd097          	auipc	ra,0xffffd
    80005aa4:	742080e7          	jalr	1858(ra) # 800031e2 <argstr>
    return -1;
    80005aa8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aaa:	10054e63          	bltz	a0,80005bc6 <sys_link+0x13c>
    80005aae:	08000613          	li	a2,128
    80005ab2:	f5040593          	addi	a1,s0,-176
    80005ab6:	4505                	li	a0,1
    80005ab8:	ffffd097          	auipc	ra,0xffffd
    80005abc:	72a080e7          	jalr	1834(ra) # 800031e2 <argstr>
    return -1;
    80005ac0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ac2:	10054263          	bltz	a0,80005bc6 <sys_link+0x13c>
  begin_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	d1c080e7          	jalr	-740(ra) # 800047e2 <begin_op>
  if((ip = namei(old)) == 0){
    80005ace:	ed040513          	addi	a0,s0,-304
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	b10080e7          	jalr	-1264(ra) # 800045e2 <namei>
    80005ada:	84aa                	mv	s1,a0
    80005adc:	c551                	beqz	a0,80005b68 <sys_link+0xde>
  ilock(ip);
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	35e080e7          	jalr	862(ra) # 80003e3c <ilock>
  if(ip->type == T_DIR){
    80005ae6:	04449703          	lh	a4,68(s1)
    80005aea:	4785                	li	a5,1
    80005aec:	08f70463          	beq	a4,a5,80005b74 <sys_link+0xea>
  ip->nlink++;
    80005af0:	04a4d783          	lhu	a5,74(s1)
    80005af4:	2785                	addiw	a5,a5,1
    80005af6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005afa:	8526                	mv	a0,s1
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	274080e7          	jalr	628(ra) # 80003d70 <iupdate>
  iunlock(ip);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	3f8080e7          	jalr	1016(ra) # 80003efe <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b0e:	fd040593          	addi	a1,s0,-48
    80005b12:	f5040513          	addi	a0,s0,-176
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	aea080e7          	jalr	-1302(ra) # 80004600 <nameiparent>
    80005b1e:	892a                	mv	s2,a0
    80005b20:	c935                	beqz	a0,80005b94 <sys_link+0x10a>
  ilock(dp);
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	31a080e7          	jalr	794(ra) # 80003e3c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b2a:	00092703          	lw	a4,0(s2)
    80005b2e:	409c                	lw	a5,0(s1)
    80005b30:	04f71d63          	bne	a4,a5,80005b8a <sys_link+0x100>
    80005b34:	40d0                	lw	a2,4(s1)
    80005b36:	fd040593          	addi	a1,s0,-48
    80005b3a:	854a                	mv	a0,s2
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	9f4080e7          	jalr	-1548(ra) # 80004530 <dirlink>
    80005b44:	04054363          	bltz	a0,80005b8a <sys_link+0x100>
  iunlockput(dp);
    80005b48:	854a                	mv	a0,s2
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	554080e7          	jalr	1364(ra) # 8000409e <iunlockput>
  iput(ip);
    80005b52:	8526                	mv	a0,s1
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	4a2080e7          	jalr	1186(ra) # 80003ff6 <iput>
  end_op();
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	d00080e7          	jalr	-768(ra) # 8000485c <end_op>
  return 0;
    80005b64:	4781                	li	a5,0
    80005b66:	a085                	j	80005bc6 <sys_link+0x13c>
    end_op();
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	cf4080e7          	jalr	-780(ra) # 8000485c <end_op>
    return -1;
    80005b70:	57fd                	li	a5,-1
    80005b72:	a891                	j	80005bc6 <sys_link+0x13c>
    iunlockput(ip);
    80005b74:	8526                	mv	a0,s1
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	528080e7          	jalr	1320(ra) # 8000409e <iunlockput>
    end_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	cde080e7          	jalr	-802(ra) # 8000485c <end_op>
    return -1;
    80005b86:	57fd                	li	a5,-1
    80005b88:	a83d                	j	80005bc6 <sys_link+0x13c>
    iunlockput(dp);
    80005b8a:	854a                	mv	a0,s2
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	512080e7          	jalr	1298(ra) # 8000409e <iunlockput>
  ilock(ip);
    80005b94:	8526                	mv	a0,s1
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	2a6080e7          	jalr	678(ra) # 80003e3c <ilock>
  ip->nlink--;
    80005b9e:	04a4d783          	lhu	a5,74(s1)
    80005ba2:	37fd                	addiw	a5,a5,-1
    80005ba4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ba8:	8526                	mv	a0,s1
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	1c6080e7          	jalr	454(ra) # 80003d70 <iupdate>
  iunlockput(ip);
    80005bb2:	8526                	mv	a0,s1
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	4ea080e7          	jalr	1258(ra) # 8000409e <iunlockput>
  end_op();
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	ca0080e7          	jalr	-864(ra) # 8000485c <end_op>
  return -1;
    80005bc4:	57fd                	li	a5,-1
}
    80005bc6:	853e                	mv	a0,a5
    80005bc8:	70b2                	ld	ra,296(sp)
    80005bca:	7412                	ld	s0,288(sp)
    80005bcc:	64f2                	ld	s1,280(sp)
    80005bce:	6952                	ld	s2,272(sp)
    80005bd0:	6155                	addi	sp,sp,304
    80005bd2:	8082                	ret

0000000080005bd4 <sys_unlink>:
{
    80005bd4:	7151                	addi	sp,sp,-240
    80005bd6:	f586                	sd	ra,232(sp)
    80005bd8:	f1a2                	sd	s0,224(sp)
    80005bda:	eda6                	sd	s1,216(sp)
    80005bdc:	e9ca                	sd	s2,208(sp)
    80005bde:	e5ce                	sd	s3,200(sp)
    80005be0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005be2:	08000613          	li	a2,128
    80005be6:	f3040593          	addi	a1,s0,-208
    80005bea:	4501                	li	a0,0
    80005bec:	ffffd097          	auipc	ra,0xffffd
    80005bf0:	5f6080e7          	jalr	1526(ra) # 800031e2 <argstr>
    80005bf4:	18054163          	bltz	a0,80005d76 <sys_unlink+0x1a2>
  begin_op();
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	bea080e7          	jalr	-1046(ra) # 800047e2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c00:	fb040593          	addi	a1,s0,-80
    80005c04:	f3040513          	addi	a0,s0,-208
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	9f8080e7          	jalr	-1544(ra) # 80004600 <nameiparent>
    80005c10:	84aa                	mv	s1,a0
    80005c12:	c979                	beqz	a0,80005ce8 <sys_unlink+0x114>
  ilock(dp);
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	228080e7          	jalr	552(ra) # 80003e3c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c1c:	00003597          	auipc	a1,0x3
    80005c20:	b0458593          	addi	a1,a1,-1276 # 80008720 <syscalls+0x2c0>
    80005c24:	fb040513          	addi	a0,s0,-80
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	6de080e7          	jalr	1758(ra) # 80004306 <namecmp>
    80005c30:	14050a63          	beqz	a0,80005d84 <sys_unlink+0x1b0>
    80005c34:	00003597          	auipc	a1,0x3
    80005c38:	af458593          	addi	a1,a1,-1292 # 80008728 <syscalls+0x2c8>
    80005c3c:	fb040513          	addi	a0,s0,-80
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	6c6080e7          	jalr	1734(ra) # 80004306 <namecmp>
    80005c48:	12050e63          	beqz	a0,80005d84 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c4c:	f2c40613          	addi	a2,s0,-212
    80005c50:	fb040593          	addi	a1,s0,-80
    80005c54:	8526                	mv	a0,s1
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	6ca080e7          	jalr	1738(ra) # 80004320 <dirlookup>
    80005c5e:	892a                	mv	s2,a0
    80005c60:	12050263          	beqz	a0,80005d84 <sys_unlink+0x1b0>
  ilock(ip);
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	1d8080e7          	jalr	472(ra) # 80003e3c <ilock>
  if(ip->nlink < 1)
    80005c6c:	04a91783          	lh	a5,74(s2)
    80005c70:	08f05263          	blez	a5,80005cf4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c74:	04491703          	lh	a4,68(s2)
    80005c78:	4785                	li	a5,1
    80005c7a:	08f70563          	beq	a4,a5,80005d04 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c7e:	4641                	li	a2,16
    80005c80:	4581                	li	a1,0
    80005c82:	fc040513          	addi	a0,s0,-64
    80005c86:	ffffb097          	auipc	ra,0xffffb
    80005c8a:	048080e7          	jalr	72(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c8e:	4741                	li	a4,16
    80005c90:	f2c42683          	lw	a3,-212(s0)
    80005c94:	fc040613          	addi	a2,s0,-64
    80005c98:	4581                	li	a1,0
    80005c9a:	8526                	mv	a0,s1
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	54c080e7          	jalr	1356(ra) # 800041e8 <writei>
    80005ca4:	47c1                	li	a5,16
    80005ca6:	0af51563          	bne	a0,a5,80005d50 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005caa:	04491703          	lh	a4,68(s2)
    80005cae:	4785                	li	a5,1
    80005cb0:	0af70863          	beq	a4,a5,80005d60 <sys_unlink+0x18c>
  iunlockput(dp);
    80005cb4:	8526                	mv	a0,s1
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	3e8080e7          	jalr	1000(ra) # 8000409e <iunlockput>
  ip->nlink--;
    80005cbe:	04a95783          	lhu	a5,74(s2)
    80005cc2:	37fd                	addiw	a5,a5,-1
    80005cc4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005cc8:	854a                	mv	a0,s2
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	0a6080e7          	jalr	166(ra) # 80003d70 <iupdate>
  iunlockput(ip);
    80005cd2:	854a                	mv	a0,s2
    80005cd4:	ffffe097          	auipc	ra,0xffffe
    80005cd8:	3ca080e7          	jalr	970(ra) # 8000409e <iunlockput>
  end_op();
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	b80080e7          	jalr	-1152(ra) # 8000485c <end_op>
  return 0;
    80005ce4:	4501                	li	a0,0
    80005ce6:	a84d                	j	80005d98 <sys_unlink+0x1c4>
    end_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	b74080e7          	jalr	-1164(ra) # 8000485c <end_op>
    return -1;
    80005cf0:	557d                	li	a0,-1
    80005cf2:	a05d                	j	80005d98 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005cf4:	00003517          	auipc	a0,0x3
    80005cf8:	a3c50513          	addi	a0,a0,-1476 # 80008730 <syscalls+0x2d0>
    80005cfc:	ffffb097          	auipc	ra,0xffffb
    80005d00:	840080e7          	jalr	-1984(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d04:	04c92703          	lw	a4,76(s2)
    80005d08:	02000793          	li	a5,32
    80005d0c:	f6e7f9e3          	bgeu	a5,a4,80005c7e <sys_unlink+0xaa>
    80005d10:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d14:	4741                	li	a4,16
    80005d16:	86ce                	mv	a3,s3
    80005d18:	f1840613          	addi	a2,s0,-232
    80005d1c:	4581                	li	a1,0
    80005d1e:	854a                	mv	a0,s2
    80005d20:	ffffe097          	auipc	ra,0xffffe
    80005d24:	3d0080e7          	jalr	976(ra) # 800040f0 <readi>
    80005d28:	47c1                	li	a5,16
    80005d2a:	00f51b63          	bne	a0,a5,80005d40 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d2e:	f1845783          	lhu	a5,-232(s0)
    80005d32:	e7a1                	bnez	a5,80005d7a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d34:	29c1                	addiw	s3,s3,16
    80005d36:	04c92783          	lw	a5,76(s2)
    80005d3a:	fcf9ede3          	bltu	s3,a5,80005d14 <sys_unlink+0x140>
    80005d3e:	b781                	j	80005c7e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d40:	00003517          	auipc	a0,0x3
    80005d44:	a0850513          	addi	a0,a0,-1528 # 80008748 <syscalls+0x2e8>
    80005d48:	ffffa097          	auipc	ra,0xffffa
    80005d4c:	7f4080e7          	jalr	2036(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005d50:	00003517          	auipc	a0,0x3
    80005d54:	a1050513          	addi	a0,a0,-1520 # 80008760 <syscalls+0x300>
    80005d58:	ffffa097          	auipc	ra,0xffffa
    80005d5c:	7e4080e7          	jalr	2020(ra) # 8000053c <panic>
    dp->nlink--;
    80005d60:	04a4d783          	lhu	a5,74(s1)
    80005d64:	37fd                	addiw	a5,a5,-1
    80005d66:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d6a:	8526                	mv	a0,s1
    80005d6c:	ffffe097          	auipc	ra,0xffffe
    80005d70:	004080e7          	jalr	4(ra) # 80003d70 <iupdate>
    80005d74:	b781                	j	80005cb4 <sys_unlink+0xe0>
    return -1;
    80005d76:	557d                	li	a0,-1
    80005d78:	a005                	j	80005d98 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d7a:	854a                	mv	a0,s2
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	322080e7          	jalr	802(ra) # 8000409e <iunlockput>
  iunlockput(dp);
    80005d84:	8526                	mv	a0,s1
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	318080e7          	jalr	792(ra) # 8000409e <iunlockput>
  end_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	ace080e7          	jalr	-1330(ra) # 8000485c <end_op>
  return -1;
    80005d96:	557d                	li	a0,-1
}
    80005d98:	70ae                	ld	ra,232(sp)
    80005d9a:	740e                	ld	s0,224(sp)
    80005d9c:	64ee                	ld	s1,216(sp)
    80005d9e:	694e                	ld	s2,208(sp)
    80005da0:	69ae                	ld	s3,200(sp)
    80005da2:	616d                	addi	sp,sp,240
    80005da4:	8082                	ret

0000000080005da6 <sys_open>:

uint64
sys_open(void)
{
    80005da6:	7131                	addi	sp,sp,-192
    80005da8:	fd06                	sd	ra,184(sp)
    80005daa:	f922                	sd	s0,176(sp)
    80005dac:	f526                	sd	s1,168(sp)
    80005dae:	f14a                	sd	s2,160(sp)
    80005db0:	ed4e                	sd	s3,152(sp)
    80005db2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005db4:	f4c40593          	addi	a1,s0,-180
    80005db8:	4505                	li	a0,1
    80005dba:	ffffd097          	auipc	ra,0xffffd
    80005dbe:	3e8080e7          	jalr	1000(ra) # 800031a2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005dc2:	08000613          	li	a2,128
    80005dc6:	f5040593          	addi	a1,s0,-176
    80005dca:	4501                	li	a0,0
    80005dcc:	ffffd097          	auipc	ra,0xffffd
    80005dd0:	416080e7          	jalr	1046(ra) # 800031e2 <argstr>
    80005dd4:	87aa                	mv	a5,a0
    return -1;
    80005dd6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005dd8:	0a07c863          	bltz	a5,80005e88 <sys_open+0xe2>

  begin_op();
    80005ddc:	fffff097          	auipc	ra,0xfffff
    80005de0:	a06080e7          	jalr	-1530(ra) # 800047e2 <begin_op>

  if(omode & O_CREATE){
    80005de4:	f4c42783          	lw	a5,-180(s0)
    80005de8:	2007f793          	andi	a5,a5,512
    80005dec:	cbdd                	beqz	a5,80005ea2 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005dee:	4681                	li	a3,0
    80005df0:	4601                	li	a2,0
    80005df2:	4589                	li	a1,2
    80005df4:	f5040513          	addi	a0,s0,-176
    80005df8:	00000097          	auipc	ra,0x0
    80005dfc:	96c080e7          	jalr	-1684(ra) # 80005764 <create>
    80005e00:	84aa                	mv	s1,a0
    if(ip == 0){
    80005e02:	c951                	beqz	a0,80005e96 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e04:	04449703          	lh	a4,68(s1)
    80005e08:	478d                	li	a5,3
    80005e0a:	00f71763          	bne	a4,a5,80005e18 <sys_open+0x72>
    80005e0e:	0464d703          	lhu	a4,70(s1)
    80005e12:	47a5                	li	a5,9
    80005e14:	0ce7ec63          	bltu	a5,a4,80005eec <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	dd2080e7          	jalr	-558(ra) # 80004bea <filealloc>
    80005e20:	892a                	mv	s2,a0
    80005e22:	c56d                	beqz	a0,80005f0c <sys_open+0x166>
    80005e24:	00000097          	auipc	ra,0x0
    80005e28:	8fe080e7          	jalr	-1794(ra) # 80005722 <fdalloc>
    80005e2c:	89aa                	mv	s3,a0
    80005e2e:	0c054a63          	bltz	a0,80005f02 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e32:	04449703          	lh	a4,68(s1)
    80005e36:	478d                	li	a5,3
    80005e38:	0ef70563          	beq	a4,a5,80005f22 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e3c:	4789                	li	a5,2
    80005e3e:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005e42:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005e46:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005e4a:	f4c42783          	lw	a5,-180(s0)
    80005e4e:	0017c713          	xori	a4,a5,1
    80005e52:	8b05                	andi	a4,a4,1
    80005e54:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e58:	0037f713          	andi	a4,a5,3
    80005e5c:	00e03733          	snez	a4,a4
    80005e60:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e64:	4007f793          	andi	a5,a5,1024
    80005e68:	c791                	beqz	a5,80005e74 <sys_open+0xce>
    80005e6a:	04449703          	lh	a4,68(s1)
    80005e6e:	4789                	li	a5,2
    80005e70:	0cf70063          	beq	a4,a5,80005f30 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005e74:	8526                	mv	a0,s1
    80005e76:	ffffe097          	auipc	ra,0xffffe
    80005e7a:	088080e7          	jalr	136(ra) # 80003efe <iunlock>
  end_op();
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	9de080e7          	jalr	-1570(ra) # 8000485c <end_op>

  return fd;
    80005e86:	854e                	mv	a0,s3
}
    80005e88:	70ea                	ld	ra,184(sp)
    80005e8a:	744a                	ld	s0,176(sp)
    80005e8c:	74aa                	ld	s1,168(sp)
    80005e8e:	790a                	ld	s2,160(sp)
    80005e90:	69ea                	ld	s3,152(sp)
    80005e92:	6129                	addi	sp,sp,192
    80005e94:	8082                	ret
      end_op();
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	9c6080e7          	jalr	-1594(ra) # 8000485c <end_op>
      return -1;
    80005e9e:	557d                	li	a0,-1
    80005ea0:	b7e5                	j	80005e88 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005ea2:	f5040513          	addi	a0,s0,-176
    80005ea6:	ffffe097          	auipc	ra,0xffffe
    80005eaa:	73c080e7          	jalr	1852(ra) # 800045e2 <namei>
    80005eae:	84aa                	mv	s1,a0
    80005eb0:	c905                	beqz	a0,80005ee0 <sys_open+0x13a>
    ilock(ip);
    80005eb2:	ffffe097          	auipc	ra,0xffffe
    80005eb6:	f8a080e7          	jalr	-118(ra) # 80003e3c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005eba:	04449703          	lh	a4,68(s1)
    80005ebe:	4785                	li	a5,1
    80005ec0:	f4f712e3          	bne	a4,a5,80005e04 <sys_open+0x5e>
    80005ec4:	f4c42783          	lw	a5,-180(s0)
    80005ec8:	dba1                	beqz	a5,80005e18 <sys_open+0x72>
      iunlockput(ip);
    80005eca:	8526                	mv	a0,s1
    80005ecc:	ffffe097          	auipc	ra,0xffffe
    80005ed0:	1d2080e7          	jalr	466(ra) # 8000409e <iunlockput>
      end_op();
    80005ed4:	fffff097          	auipc	ra,0xfffff
    80005ed8:	988080e7          	jalr	-1656(ra) # 8000485c <end_op>
      return -1;
    80005edc:	557d                	li	a0,-1
    80005ede:	b76d                	j	80005e88 <sys_open+0xe2>
      end_op();
    80005ee0:	fffff097          	auipc	ra,0xfffff
    80005ee4:	97c080e7          	jalr	-1668(ra) # 8000485c <end_op>
      return -1;
    80005ee8:	557d                	li	a0,-1
    80005eea:	bf79                	j	80005e88 <sys_open+0xe2>
    iunlockput(ip);
    80005eec:	8526                	mv	a0,s1
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	1b0080e7          	jalr	432(ra) # 8000409e <iunlockput>
    end_op();
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	966080e7          	jalr	-1690(ra) # 8000485c <end_op>
    return -1;
    80005efe:	557d                	li	a0,-1
    80005f00:	b761                	j	80005e88 <sys_open+0xe2>
      fileclose(f);
    80005f02:	854a                	mv	a0,s2
    80005f04:	fffff097          	auipc	ra,0xfffff
    80005f08:	da2080e7          	jalr	-606(ra) # 80004ca6 <fileclose>
    iunlockput(ip);
    80005f0c:	8526                	mv	a0,s1
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	190080e7          	jalr	400(ra) # 8000409e <iunlockput>
    end_op();
    80005f16:	fffff097          	auipc	ra,0xfffff
    80005f1a:	946080e7          	jalr	-1722(ra) # 8000485c <end_op>
    return -1;
    80005f1e:	557d                	li	a0,-1
    80005f20:	b7a5                	j	80005e88 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005f22:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005f26:	04649783          	lh	a5,70(s1)
    80005f2a:	02f91223          	sh	a5,36(s2)
    80005f2e:	bf21                	j	80005e46 <sys_open+0xa0>
    itrunc(ip);
    80005f30:	8526                	mv	a0,s1
    80005f32:	ffffe097          	auipc	ra,0xffffe
    80005f36:	018080e7          	jalr	24(ra) # 80003f4a <itrunc>
    80005f3a:	bf2d                	j	80005e74 <sys_open+0xce>

0000000080005f3c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f3c:	7175                	addi	sp,sp,-144
    80005f3e:	e506                	sd	ra,136(sp)
    80005f40:	e122                	sd	s0,128(sp)
    80005f42:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f44:	fffff097          	auipc	ra,0xfffff
    80005f48:	89e080e7          	jalr	-1890(ra) # 800047e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f4c:	08000613          	li	a2,128
    80005f50:	f7040593          	addi	a1,s0,-144
    80005f54:	4501                	li	a0,0
    80005f56:	ffffd097          	auipc	ra,0xffffd
    80005f5a:	28c080e7          	jalr	652(ra) # 800031e2 <argstr>
    80005f5e:	02054963          	bltz	a0,80005f90 <sys_mkdir+0x54>
    80005f62:	4681                	li	a3,0
    80005f64:	4601                	li	a2,0
    80005f66:	4585                	li	a1,1
    80005f68:	f7040513          	addi	a0,s0,-144
    80005f6c:	fffff097          	auipc	ra,0xfffff
    80005f70:	7f8080e7          	jalr	2040(ra) # 80005764 <create>
    80005f74:	cd11                	beqz	a0,80005f90 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	128080e7          	jalr	296(ra) # 8000409e <iunlockput>
  end_op();
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	8de080e7          	jalr	-1826(ra) # 8000485c <end_op>
  return 0;
    80005f86:	4501                	li	a0,0
}
    80005f88:	60aa                	ld	ra,136(sp)
    80005f8a:	640a                	ld	s0,128(sp)
    80005f8c:	6149                	addi	sp,sp,144
    80005f8e:	8082                	ret
    end_op();
    80005f90:	fffff097          	auipc	ra,0xfffff
    80005f94:	8cc080e7          	jalr	-1844(ra) # 8000485c <end_op>
    return -1;
    80005f98:	557d                	li	a0,-1
    80005f9a:	b7fd                	j	80005f88 <sys_mkdir+0x4c>

0000000080005f9c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f9c:	7135                	addi	sp,sp,-160
    80005f9e:	ed06                	sd	ra,152(sp)
    80005fa0:	e922                	sd	s0,144(sp)
    80005fa2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	83e080e7          	jalr	-1986(ra) # 800047e2 <begin_op>
  argint(1, &major);
    80005fac:	f6c40593          	addi	a1,s0,-148
    80005fb0:	4505                	li	a0,1
    80005fb2:	ffffd097          	auipc	ra,0xffffd
    80005fb6:	1f0080e7          	jalr	496(ra) # 800031a2 <argint>
  argint(2, &minor);
    80005fba:	f6840593          	addi	a1,s0,-152
    80005fbe:	4509                	li	a0,2
    80005fc0:	ffffd097          	auipc	ra,0xffffd
    80005fc4:	1e2080e7          	jalr	482(ra) # 800031a2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fc8:	08000613          	li	a2,128
    80005fcc:	f7040593          	addi	a1,s0,-144
    80005fd0:	4501                	li	a0,0
    80005fd2:	ffffd097          	auipc	ra,0xffffd
    80005fd6:	210080e7          	jalr	528(ra) # 800031e2 <argstr>
    80005fda:	02054b63          	bltz	a0,80006010 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fde:	f6841683          	lh	a3,-152(s0)
    80005fe2:	f6c41603          	lh	a2,-148(s0)
    80005fe6:	458d                	li	a1,3
    80005fe8:	f7040513          	addi	a0,s0,-144
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	778080e7          	jalr	1912(ra) # 80005764 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ff4:	cd11                	beqz	a0,80006010 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ff6:	ffffe097          	auipc	ra,0xffffe
    80005ffa:	0a8080e7          	jalr	168(ra) # 8000409e <iunlockput>
  end_op();
    80005ffe:	fffff097          	auipc	ra,0xfffff
    80006002:	85e080e7          	jalr	-1954(ra) # 8000485c <end_op>
  return 0;
    80006006:	4501                	li	a0,0
}
    80006008:	60ea                	ld	ra,152(sp)
    8000600a:	644a                	ld	s0,144(sp)
    8000600c:	610d                	addi	sp,sp,160
    8000600e:	8082                	ret
    end_op();
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	84c080e7          	jalr	-1972(ra) # 8000485c <end_op>
    return -1;
    80006018:	557d                	li	a0,-1
    8000601a:	b7fd                	j	80006008 <sys_mknod+0x6c>

000000008000601c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000601c:	7135                	addi	sp,sp,-160
    8000601e:	ed06                	sd	ra,152(sp)
    80006020:	e922                	sd	s0,144(sp)
    80006022:	e526                	sd	s1,136(sp)
    80006024:	e14a                	sd	s2,128(sp)
    80006026:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006028:	ffffc097          	auipc	ra,0xffffc
    8000602c:	9ae080e7          	jalr	-1618(ra) # 800019d6 <myproc>
    80006030:	892a                	mv	s2,a0
  
  begin_op();
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	7b0080e7          	jalr	1968(ra) # 800047e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000603a:	08000613          	li	a2,128
    8000603e:	f6040593          	addi	a1,s0,-160
    80006042:	4501                	li	a0,0
    80006044:	ffffd097          	auipc	ra,0xffffd
    80006048:	19e080e7          	jalr	414(ra) # 800031e2 <argstr>
    8000604c:	04054b63          	bltz	a0,800060a2 <sys_chdir+0x86>
    80006050:	f6040513          	addi	a0,s0,-160
    80006054:	ffffe097          	auipc	ra,0xffffe
    80006058:	58e080e7          	jalr	1422(ra) # 800045e2 <namei>
    8000605c:	84aa                	mv	s1,a0
    8000605e:	c131                	beqz	a0,800060a2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006060:	ffffe097          	auipc	ra,0xffffe
    80006064:	ddc080e7          	jalr	-548(ra) # 80003e3c <ilock>
  if(ip->type != T_DIR){
    80006068:	04449703          	lh	a4,68(s1)
    8000606c:	4785                	li	a5,1
    8000606e:	04f71063          	bne	a4,a5,800060ae <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006072:	8526                	mv	a0,s1
    80006074:	ffffe097          	auipc	ra,0xffffe
    80006078:	e8a080e7          	jalr	-374(ra) # 80003efe <iunlock>
  iput(p->cwd);
    8000607c:	15093503          	ld	a0,336(s2)
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	f76080e7          	jalr	-138(ra) # 80003ff6 <iput>
  end_op();
    80006088:	ffffe097          	auipc	ra,0xffffe
    8000608c:	7d4080e7          	jalr	2004(ra) # 8000485c <end_op>
  p->cwd = ip;
    80006090:	14993823          	sd	s1,336(s2)
  return 0;
    80006094:	4501                	li	a0,0
}
    80006096:	60ea                	ld	ra,152(sp)
    80006098:	644a                	ld	s0,144(sp)
    8000609a:	64aa                	ld	s1,136(sp)
    8000609c:	690a                	ld	s2,128(sp)
    8000609e:	610d                	addi	sp,sp,160
    800060a0:	8082                	ret
    end_op();
    800060a2:	ffffe097          	auipc	ra,0xffffe
    800060a6:	7ba080e7          	jalr	1978(ra) # 8000485c <end_op>
    return -1;
    800060aa:	557d                	li	a0,-1
    800060ac:	b7ed                	j	80006096 <sys_chdir+0x7a>
    iunlockput(ip);
    800060ae:	8526                	mv	a0,s1
    800060b0:	ffffe097          	auipc	ra,0xffffe
    800060b4:	fee080e7          	jalr	-18(ra) # 8000409e <iunlockput>
    end_op();
    800060b8:	ffffe097          	auipc	ra,0xffffe
    800060bc:	7a4080e7          	jalr	1956(ra) # 8000485c <end_op>
    return -1;
    800060c0:	557d                	li	a0,-1
    800060c2:	bfd1                	j	80006096 <sys_chdir+0x7a>

00000000800060c4 <sys_exec>:

uint64
sys_exec(void)
{
    800060c4:	7121                	addi	sp,sp,-448
    800060c6:	ff06                	sd	ra,440(sp)
    800060c8:	fb22                	sd	s0,432(sp)
    800060ca:	f726                	sd	s1,424(sp)
    800060cc:	f34a                	sd	s2,416(sp)
    800060ce:	ef4e                	sd	s3,408(sp)
    800060d0:	eb52                	sd	s4,400(sp)
    800060d2:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800060d4:	e4840593          	addi	a1,s0,-440
    800060d8:	4505                	li	a0,1
    800060da:	ffffd097          	auipc	ra,0xffffd
    800060de:	0e8080e7          	jalr	232(ra) # 800031c2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800060e2:	08000613          	li	a2,128
    800060e6:	f5040593          	addi	a1,s0,-176
    800060ea:	4501                	li	a0,0
    800060ec:	ffffd097          	auipc	ra,0xffffd
    800060f0:	0f6080e7          	jalr	246(ra) # 800031e2 <argstr>
    800060f4:	87aa                	mv	a5,a0
    return -1;
    800060f6:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800060f8:	0c07c263          	bltz	a5,800061bc <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    800060fc:	10000613          	li	a2,256
    80006100:	4581                	li	a1,0
    80006102:	e5040513          	addi	a0,s0,-432
    80006106:	ffffb097          	auipc	ra,0xffffb
    8000610a:	bc8080e7          	jalr	-1080(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000610e:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80006112:	89a6                	mv	s3,s1
    80006114:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006116:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000611a:	00391513          	slli	a0,s2,0x3
    8000611e:	e4040593          	addi	a1,s0,-448
    80006122:	e4843783          	ld	a5,-440(s0)
    80006126:	953e                	add	a0,a0,a5
    80006128:	ffffd097          	auipc	ra,0xffffd
    8000612c:	fdc080e7          	jalr	-36(ra) # 80003104 <fetchaddr>
    80006130:	02054a63          	bltz	a0,80006164 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80006134:	e4043783          	ld	a5,-448(s0)
    80006138:	c3b9                	beqz	a5,8000617e <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000613a:	ffffb097          	auipc	ra,0xffffb
    8000613e:	9a8080e7          	jalr	-1624(ra) # 80000ae2 <kalloc>
    80006142:	85aa                	mv	a1,a0
    80006144:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006148:	cd11                	beqz	a0,80006164 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000614a:	6605                	lui	a2,0x1
    8000614c:	e4043503          	ld	a0,-448(s0)
    80006150:	ffffd097          	auipc	ra,0xffffd
    80006154:	006080e7          	jalr	6(ra) # 80003156 <fetchstr>
    80006158:	00054663          	bltz	a0,80006164 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    8000615c:	0905                	addi	s2,s2,1
    8000615e:	09a1                	addi	s3,s3,8
    80006160:	fb491de3          	bne	s2,s4,8000611a <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006164:	f5040913          	addi	s2,s0,-176
    80006168:	6088                	ld	a0,0(s1)
    8000616a:	c921                	beqz	a0,800061ba <sys_exec+0xf6>
    kfree(argv[i]);
    8000616c:	ffffb097          	auipc	ra,0xffffb
    80006170:	878080e7          	jalr	-1928(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006174:	04a1                	addi	s1,s1,8
    80006176:	ff2499e3          	bne	s1,s2,80006168 <sys_exec+0xa4>
  return -1;
    8000617a:	557d                	li	a0,-1
    8000617c:	a081                	j	800061bc <sys_exec+0xf8>
      argv[i] = 0;
    8000617e:	0009079b          	sext.w	a5,s2
    80006182:	078e                	slli	a5,a5,0x3
    80006184:	fd078793          	addi	a5,a5,-48
    80006188:	97a2                	add	a5,a5,s0
    8000618a:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    8000618e:	e5040593          	addi	a1,s0,-432
    80006192:	f5040513          	addi	a0,s0,-176
    80006196:	fffff097          	auipc	ra,0xfffff
    8000619a:	186080e7          	jalr	390(ra) # 8000531c <exec>
    8000619e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061a0:	f5040993          	addi	s3,s0,-176
    800061a4:	6088                	ld	a0,0(s1)
    800061a6:	c901                	beqz	a0,800061b6 <sys_exec+0xf2>
    kfree(argv[i]);
    800061a8:	ffffb097          	auipc	ra,0xffffb
    800061ac:	83c080e7          	jalr	-1988(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061b0:	04a1                	addi	s1,s1,8
    800061b2:	ff3499e3          	bne	s1,s3,800061a4 <sys_exec+0xe0>
  return ret;
    800061b6:	854a                	mv	a0,s2
    800061b8:	a011                	j	800061bc <sys_exec+0xf8>
  return -1;
    800061ba:	557d                	li	a0,-1
}
    800061bc:	70fa                	ld	ra,440(sp)
    800061be:	745a                	ld	s0,432(sp)
    800061c0:	74ba                	ld	s1,424(sp)
    800061c2:	791a                	ld	s2,416(sp)
    800061c4:	69fa                	ld	s3,408(sp)
    800061c6:	6a5a                	ld	s4,400(sp)
    800061c8:	6139                	addi	sp,sp,448
    800061ca:	8082                	ret

00000000800061cc <sys_pipe>:

uint64
sys_pipe(void)
{
    800061cc:	7139                	addi	sp,sp,-64
    800061ce:	fc06                	sd	ra,56(sp)
    800061d0:	f822                	sd	s0,48(sp)
    800061d2:	f426                	sd	s1,40(sp)
    800061d4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061d6:	ffffc097          	auipc	ra,0xffffc
    800061da:	800080e7          	jalr	-2048(ra) # 800019d6 <myproc>
    800061de:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800061e0:	fd840593          	addi	a1,s0,-40
    800061e4:	4501                	li	a0,0
    800061e6:	ffffd097          	auipc	ra,0xffffd
    800061ea:	fdc080e7          	jalr	-36(ra) # 800031c2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800061ee:	fc840593          	addi	a1,s0,-56
    800061f2:	fd040513          	addi	a0,s0,-48
    800061f6:	fffff097          	auipc	ra,0xfffff
    800061fa:	ddc080e7          	jalr	-548(ra) # 80004fd2 <pipealloc>
    return -1;
    800061fe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006200:	0c054463          	bltz	a0,800062c8 <sys_pipe+0xfc>
  fd0 = -1;
    80006204:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006208:	fd043503          	ld	a0,-48(s0)
    8000620c:	fffff097          	auipc	ra,0xfffff
    80006210:	516080e7          	jalr	1302(ra) # 80005722 <fdalloc>
    80006214:	fca42223          	sw	a0,-60(s0)
    80006218:	08054b63          	bltz	a0,800062ae <sys_pipe+0xe2>
    8000621c:	fc843503          	ld	a0,-56(s0)
    80006220:	fffff097          	auipc	ra,0xfffff
    80006224:	502080e7          	jalr	1282(ra) # 80005722 <fdalloc>
    80006228:	fca42023          	sw	a0,-64(s0)
    8000622c:	06054863          	bltz	a0,8000629c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006230:	4691                	li	a3,4
    80006232:	fc440613          	addi	a2,s0,-60
    80006236:	fd843583          	ld	a1,-40(s0)
    8000623a:	68a8                	ld	a0,80(s1)
    8000623c:	ffffb097          	auipc	ra,0xffffb
    80006240:	42a080e7          	jalr	1066(ra) # 80001666 <copyout>
    80006244:	02054063          	bltz	a0,80006264 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006248:	4691                	li	a3,4
    8000624a:	fc040613          	addi	a2,s0,-64
    8000624e:	fd843583          	ld	a1,-40(s0)
    80006252:	0591                	addi	a1,a1,4
    80006254:	68a8                	ld	a0,80(s1)
    80006256:	ffffb097          	auipc	ra,0xffffb
    8000625a:	410080e7          	jalr	1040(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000625e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006260:	06055463          	bgez	a0,800062c8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006264:	fc442783          	lw	a5,-60(s0)
    80006268:	07e9                	addi	a5,a5,26
    8000626a:	078e                	slli	a5,a5,0x3
    8000626c:	97a6                	add	a5,a5,s1
    8000626e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006272:	fc042783          	lw	a5,-64(s0)
    80006276:	07e9                	addi	a5,a5,26
    80006278:	078e                	slli	a5,a5,0x3
    8000627a:	94be                	add	s1,s1,a5
    8000627c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006280:	fd043503          	ld	a0,-48(s0)
    80006284:	fffff097          	auipc	ra,0xfffff
    80006288:	a22080e7          	jalr	-1502(ra) # 80004ca6 <fileclose>
    fileclose(wf);
    8000628c:	fc843503          	ld	a0,-56(s0)
    80006290:	fffff097          	auipc	ra,0xfffff
    80006294:	a16080e7          	jalr	-1514(ra) # 80004ca6 <fileclose>
    return -1;
    80006298:	57fd                	li	a5,-1
    8000629a:	a03d                	j	800062c8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000629c:	fc442783          	lw	a5,-60(s0)
    800062a0:	0007c763          	bltz	a5,800062ae <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800062a4:	07e9                	addi	a5,a5,26
    800062a6:	078e                	slli	a5,a5,0x3
    800062a8:	97a6                	add	a5,a5,s1
    800062aa:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800062ae:	fd043503          	ld	a0,-48(s0)
    800062b2:	fffff097          	auipc	ra,0xfffff
    800062b6:	9f4080e7          	jalr	-1548(ra) # 80004ca6 <fileclose>
    fileclose(wf);
    800062ba:	fc843503          	ld	a0,-56(s0)
    800062be:	fffff097          	auipc	ra,0xfffff
    800062c2:	9e8080e7          	jalr	-1560(ra) # 80004ca6 <fileclose>
    return -1;
    800062c6:	57fd                	li	a5,-1
}
    800062c8:	853e                	mv	a0,a5
    800062ca:	70e2                	ld	ra,56(sp)
    800062cc:	7442                	ld	s0,48(sp)
    800062ce:	74a2                	ld	s1,40(sp)
    800062d0:	6121                	addi	sp,sp,64
    800062d2:	8082                	ret
	...

00000000800062e0 <kernelvec>:
    800062e0:	7111                	addi	sp,sp,-256
    800062e2:	e006                	sd	ra,0(sp)
    800062e4:	e40a                	sd	sp,8(sp)
    800062e6:	e80e                	sd	gp,16(sp)
    800062e8:	ec12                	sd	tp,24(sp)
    800062ea:	f016                	sd	t0,32(sp)
    800062ec:	f41a                	sd	t1,40(sp)
    800062ee:	f81e                	sd	t2,48(sp)
    800062f0:	fc22                	sd	s0,56(sp)
    800062f2:	e0a6                	sd	s1,64(sp)
    800062f4:	e4aa                	sd	a0,72(sp)
    800062f6:	e8ae                	sd	a1,80(sp)
    800062f8:	ecb2                	sd	a2,88(sp)
    800062fa:	f0b6                	sd	a3,96(sp)
    800062fc:	f4ba                	sd	a4,104(sp)
    800062fe:	f8be                	sd	a5,112(sp)
    80006300:	fcc2                	sd	a6,120(sp)
    80006302:	e146                	sd	a7,128(sp)
    80006304:	e54a                	sd	s2,136(sp)
    80006306:	e94e                	sd	s3,144(sp)
    80006308:	ed52                	sd	s4,152(sp)
    8000630a:	f156                	sd	s5,160(sp)
    8000630c:	f55a                	sd	s6,168(sp)
    8000630e:	f95e                	sd	s7,176(sp)
    80006310:	fd62                	sd	s8,184(sp)
    80006312:	e1e6                	sd	s9,192(sp)
    80006314:	e5ea                	sd	s10,200(sp)
    80006316:	e9ee                	sd	s11,208(sp)
    80006318:	edf2                	sd	t3,216(sp)
    8000631a:	f1f6                	sd	t4,224(sp)
    8000631c:	f5fa                	sd	t5,232(sp)
    8000631e:	f9fe                	sd	t6,240(sp)
    80006320:	c63fc0ef          	jal	ra,80002f82 <kerneltrap>
    80006324:	6082                	ld	ra,0(sp)
    80006326:	6122                	ld	sp,8(sp)
    80006328:	61c2                	ld	gp,16(sp)
    8000632a:	7282                	ld	t0,32(sp)
    8000632c:	7322                	ld	t1,40(sp)
    8000632e:	73c2                	ld	t2,48(sp)
    80006330:	7462                	ld	s0,56(sp)
    80006332:	6486                	ld	s1,64(sp)
    80006334:	6526                	ld	a0,72(sp)
    80006336:	65c6                	ld	a1,80(sp)
    80006338:	6666                	ld	a2,88(sp)
    8000633a:	7686                	ld	a3,96(sp)
    8000633c:	7726                	ld	a4,104(sp)
    8000633e:	77c6                	ld	a5,112(sp)
    80006340:	7866                	ld	a6,120(sp)
    80006342:	688a                	ld	a7,128(sp)
    80006344:	692a                	ld	s2,136(sp)
    80006346:	69ca                	ld	s3,144(sp)
    80006348:	6a6a                	ld	s4,152(sp)
    8000634a:	7a8a                	ld	s5,160(sp)
    8000634c:	7b2a                	ld	s6,168(sp)
    8000634e:	7bca                	ld	s7,176(sp)
    80006350:	7c6a                	ld	s8,184(sp)
    80006352:	6c8e                	ld	s9,192(sp)
    80006354:	6d2e                	ld	s10,200(sp)
    80006356:	6dce                	ld	s11,208(sp)
    80006358:	6e6e                	ld	t3,216(sp)
    8000635a:	7e8e                	ld	t4,224(sp)
    8000635c:	7f2e                	ld	t5,232(sp)
    8000635e:	7fce                	ld	t6,240(sp)
    80006360:	6111                	addi	sp,sp,256
    80006362:	10200073          	sret
    80006366:	00000013          	nop
    8000636a:	00000013          	nop
    8000636e:	0001                	nop

0000000080006370 <timervec>:
    80006370:	34051573          	csrrw	a0,mscratch,a0
    80006374:	e10c                	sd	a1,0(a0)
    80006376:	e510                	sd	a2,8(a0)
    80006378:	e914                	sd	a3,16(a0)
    8000637a:	6d0c                	ld	a1,24(a0)
    8000637c:	7110                	ld	a2,32(a0)
    8000637e:	6194                	ld	a3,0(a1)
    80006380:	96b2                	add	a3,a3,a2
    80006382:	e194                	sd	a3,0(a1)
    80006384:	4589                	li	a1,2
    80006386:	14459073          	csrw	sip,a1
    8000638a:	6914                	ld	a3,16(a0)
    8000638c:	6510                	ld	a2,8(a0)
    8000638e:	610c                	ld	a1,0(a0)
    80006390:	34051573          	csrrw	a0,mscratch,a0
    80006394:	30200073          	mret
	...

000000008000639a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000639a:	1141                	addi	sp,sp,-16
    8000639c:	e422                	sd	s0,8(sp)
    8000639e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063a0:	0c0007b7          	lui	a5,0xc000
    800063a4:	4705                	li	a4,1
    800063a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063a8:	c3d8                	sw	a4,4(a5)
}
    800063aa:	6422                	ld	s0,8(sp)
    800063ac:	0141                	addi	sp,sp,16
    800063ae:	8082                	ret

00000000800063b0 <plicinithart>:

void
plicinithart(void)
{
    800063b0:	1141                	addi	sp,sp,-16
    800063b2:	e406                	sd	ra,8(sp)
    800063b4:	e022                	sd	s0,0(sp)
    800063b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063b8:	ffffb097          	auipc	ra,0xffffb
    800063bc:	5f2080e7          	jalr	1522(ra) # 800019aa <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063c0:	0085171b          	slliw	a4,a0,0x8
    800063c4:	0c0027b7          	lui	a5,0xc002
    800063c8:	97ba                	add	a5,a5,a4
    800063ca:	40200713          	li	a4,1026
    800063ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063d2:	00d5151b          	slliw	a0,a0,0xd
    800063d6:	0c2017b7          	lui	a5,0xc201
    800063da:	97aa                	add	a5,a5,a0
    800063dc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800063e0:	60a2                	ld	ra,8(sp)
    800063e2:	6402                	ld	s0,0(sp)
    800063e4:	0141                	addi	sp,sp,16
    800063e6:	8082                	ret

00000000800063e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063e8:	1141                	addi	sp,sp,-16
    800063ea:	e406                	sd	ra,8(sp)
    800063ec:	e022                	sd	s0,0(sp)
    800063ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063f0:	ffffb097          	auipc	ra,0xffffb
    800063f4:	5ba080e7          	jalr	1466(ra) # 800019aa <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063f8:	00d5151b          	slliw	a0,a0,0xd
    800063fc:	0c2017b7          	lui	a5,0xc201
    80006400:	97aa                	add	a5,a5,a0
  return irq;
}
    80006402:	43c8                	lw	a0,4(a5)
    80006404:	60a2                	ld	ra,8(sp)
    80006406:	6402                	ld	s0,0(sp)
    80006408:	0141                	addi	sp,sp,16
    8000640a:	8082                	ret

000000008000640c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000640c:	1101                	addi	sp,sp,-32
    8000640e:	ec06                	sd	ra,24(sp)
    80006410:	e822                	sd	s0,16(sp)
    80006412:	e426                	sd	s1,8(sp)
    80006414:	1000                	addi	s0,sp,32
    80006416:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006418:	ffffb097          	auipc	ra,0xffffb
    8000641c:	592080e7          	jalr	1426(ra) # 800019aa <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006420:	00d5151b          	slliw	a0,a0,0xd
    80006424:	0c2017b7          	lui	a5,0xc201
    80006428:	97aa                	add	a5,a5,a0
    8000642a:	c3c4                	sw	s1,4(a5)
}
    8000642c:	60e2                	ld	ra,24(sp)
    8000642e:	6442                	ld	s0,16(sp)
    80006430:	64a2                	ld	s1,8(sp)
    80006432:	6105                	addi	sp,sp,32
    80006434:	8082                	ret

0000000080006436 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006436:	1141                	addi	sp,sp,-16
    80006438:	e406                	sd	ra,8(sp)
    8000643a:	e022                	sd	s0,0(sp)
    8000643c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000643e:	479d                	li	a5,7
    80006440:	04a7cc63          	blt	a5,a0,80006498 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006444:	0001e797          	auipc	a5,0x1e
    80006448:	aac78793          	addi	a5,a5,-1364 # 80023ef0 <disk>
    8000644c:	97aa                	add	a5,a5,a0
    8000644e:	0187c783          	lbu	a5,24(a5)
    80006452:	ebb9                	bnez	a5,800064a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006454:	00451693          	slli	a3,a0,0x4
    80006458:	0001e797          	auipc	a5,0x1e
    8000645c:	a9878793          	addi	a5,a5,-1384 # 80023ef0 <disk>
    80006460:	6398                	ld	a4,0(a5)
    80006462:	9736                	add	a4,a4,a3
    80006464:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006468:	6398                	ld	a4,0(a5)
    8000646a:	9736                	add	a4,a4,a3
    8000646c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006470:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006474:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006478:	97aa                	add	a5,a5,a0
    8000647a:	4705                	li	a4,1
    8000647c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006480:	0001e517          	auipc	a0,0x1e
    80006484:	a8850513          	addi	a0,a0,-1400 # 80023f08 <disk+0x18>
    80006488:	ffffc097          	auipc	ra,0xffffc
    8000648c:	f40080e7          	jalr	-192(ra) # 800023c8 <wakeup>
}
    80006490:	60a2                	ld	ra,8(sp)
    80006492:	6402                	ld	s0,0(sp)
    80006494:	0141                	addi	sp,sp,16
    80006496:	8082                	ret
    panic("free_desc 1");
    80006498:	00002517          	auipc	a0,0x2
    8000649c:	2d850513          	addi	a0,a0,728 # 80008770 <syscalls+0x310>
    800064a0:	ffffa097          	auipc	ra,0xffffa
    800064a4:	09c080e7          	jalr	156(ra) # 8000053c <panic>
    panic("free_desc 2");
    800064a8:	00002517          	auipc	a0,0x2
    800064ac:	2d850513          	addi	a0,a0,728 # 80008780 <syscalls+0x320>
    800064b0:	ffffa097          	auipc	ra,0xffffa
    800064b4:	08c080e7          	jalr	140(ra) # 8000053c <panic>

00000000800064b8 <virtio_disk_init>:
{
    800064b8:	1101                	addi	sp,sp,-32
    800064ba:	ec06                	sd	ra,24(sp)
    800064bc:	e822                	sd	s0,16(sp)
    800064be:	e426                	sd	s1,8(sp)
    800064c0:	e04a                	sd	s2,0(sp)
    800064c2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064c4:	00002597          	auipc	a1,0x2
    800064c8:	2cc58593          	addi	a1,a1,716 # 80008790 <syscalls+0x330>
    800064cc:	0001e517          	auipc	a0,0x1e
    800064d0:	b4c50513          	addi	a0,a0,-1204 # 80024018 <disk+0x128>
    800064d4:	ffffa097          	auipc	ra,0xffffa
    800064d8:	66e080e7          	jalr	1646(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064dc:	100017b7          	lui	a5,0x10001
    800064e0:	4398                	lw	a4,0(a5)
    800064e2:	2701                	sext.w	a4,a4
    800064e4:	747277b7          	lui	a5,0x74727
    800064e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064ec:	14f71b63          	bne	a4,a5,80006642 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064f0:	100017b7          	lui	a5,0x10001
    800064f4:	43dc                	lw	a5,4(a5)
    800064f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064f8:	4709                	li	a4,2
    800064fa:	14e79463          	bne	a5,a4,80006642 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064fe:	100017b7          	lui	a5,0x10001
    80006502:	479c                	lw	a5,8(a5)
    80006504:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006506:	12e79e63          	bne	a5,a4,80006642 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000650a:	100017b7          	lui	a5,0x10001
    8000650e:	47d8                	lw	a4,12(a5)
    80006510:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006512:	554d47b7          	lui	a5,0x554d4
    80006516:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000651a:	12f71463          	bne	a4,a5,80006642 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000651e:	100017b7          	lui	a5,0x10001
    80006522:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006526:	4705                	li	a4,1
    80006528:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000652a:	470d                	li	a4,3
    8000652c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000652e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006530:	c7ffe6b7          	lui	a3,0xc7ffe
    80006534:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fda72f>
    80006538:	8f75                	and	a4,a4,a3
    8000653a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000653c:	472d                	li	a4,11
    8000653e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006540:	5bbc                	lw	a5,112(a5)
    80006542:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006546:	8ba1                	andi	a5,a5,8
    80006548:	10078563          	beqz	a5,80006652 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000654c:	100017b7          	lui	a5,0x10001
    80006550:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006554:	43fc                	lw	a5,68(a5)
    80006556:	2781                	sext.w	a5,a5
    80006558:	10079563          	bnez	a5,80006662 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000655c:	100017b7          	lui	a5,0x10001
    80006560:	5bdc                	lw	a5,52(a5)
    80006562:	2781                	sext.w	a5,a5
  if(max == 0)
    80006564:	10078763          	beqz	a5,80006672 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006568:	471d                	li	a4,7
    8000656a:	10f77c63          	bgeu	a4,a5,80006682 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000656e:	ffffa097          	auipc	ra,0xffffa
    80006572:	574080e7          	jalr	1396(ra) # 80000ae2 <kalloc>
    80006576:	0001e497          	auipc	s1,0x1e
    8000657a:	97a48493          	addi	s1,s1,-1670 # 80023ef0 <disk>
    8000657e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006580:	ffffa097          	auipc	ra,0xffffa
    80006584:	562080e7          	jalr	1378(ra) # 80000ae2 <kalloc>
    80006588:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000658a:	ffffa097          	auipc	ra,0xffffa
    8000658e:	558080e7          	jalr	1368(ra) # 80000ae2 <kalloc>
    80006592:	87aa                	mv	a5,a0
    80006594:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006596:	6088                	ld	a0,0(s1)
    80006598:	cd6d                	beqz	a0,80006692 <virtio_disk_init+0x1da>
    8000659a:	0001e717          	auipc	a4,0x1e
    8000659e:	95e73703          	ld	a4,-1698(a4) # 80023ef8 <disk+0x8>
    800065a2:	cb65                	beqz	a4,80006692 <virtio_disk_init+0x1da>
    800065a4:	c7fd                	beqz	a5,80006692 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800065a6:	6605                	lui	a2,0x1
    800065a8:	4581                	li	a1,0
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	724080e7          	jalr	1828(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    800065b2:	0001e497          	auipc	s1,0x1e
    800065b6:	93e48493          	addi	s1,s1,-1730 # 80023ef0 <disk>
    800065ba:	6605                	lui	a2,0x1
    800065bc:	4581                	li	a1,0
    800065be:	6488                	ld	a0,8(s1)
    800065c0:	ffffa097          	auipc	ra,0xffffa
    800065c4:	70e080e7          	jalr	1806(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    800065c8:	6605                	lui	a2,0x1
    800065ca:	4581                	li	a1,0
    800065cc:	6888                	ld	a0,16(s1)
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	700080e7          	jalr	1792(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800065d6:	100017b7          	lui	a5,0x10001
    800065da:	4721                	li	a4,8
    800065dc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800065de:	4098                	lw	a4,0(s1)
    800065e0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800065e4:	40d8                	lw	a4,4(s1)
    800065e6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800065ea:	6498                	ld	a4,8(s1)
    800065ec:	0007069b          	sext.w	a3,a4
    800065f0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800065f4:	9701                	srai	a4,a4,0x20
    800065f6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800065fa:	6898                	ld	a4,16(s1)
    800065fc:	0007069b          	sext.w	a3,a4
    80006600:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006604:	9701                	srai	a4,a4,0x20
    80006606:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000660a:	4705                	li	a4,1
    8000660c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000660e:	00e48c23          	sb	a4,24(s1)
    80006612:	00e48ca3          	sb	a4,25(s1)
    80006616:	00e48d23          	sb	a4,26(s1)
    8000661a:	00e48da3          	sb	a4,27(s1)
    8000661e:	00e48e23          	sb	a4,28(s1)
    80006622:	00e48ea3          	sb	a4,29(s1)
    80006626:	00e48f23          	sb	a4,30(s1)
    8000662a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000662e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006632:	0727a823          	sw	s2,112(a5)
}
    80006636:	60e2                	ld	ra,24(sp)
    80006638:	6442                	ld	s0,16(sp)
    8000663a:	64a2                	ld	s1,8(sp)
    8000663c:	6902                	ld	s2,0(sp)
    8000663e:	6105                	addi	sp,sp,32
    80006640:	8082                	ret
    panic("could not find virtio disk");
    80006642:	00002517          	auipc	a0,0x2
    80006646:	15e50513          	addi	a0,a0,350 # 800087a0 <syscalls+0x340>
    8000664a:	ffffa097          	auipc	ra,0xffffa
    8000664e:	ef2080e7          	jalr	-270(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006652:	00002517          	auipc	a0,0x2
    80006656:	16e50513          	addi	a0,a0,366 # 800087c0 <syscalls+0x360>
    8000665a:	ffffa097          	auipc	ra,0xffffa
    8000665e:	ee2080e7          	jalr	-286(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006662:	00002517          	auipc	a0,0x2
    80006666:	17e50513          	addi	a0,a0,382 # 800087e0 <syscalls+0x380>
    8000666a:	ffffa097          	auipc	ra,0xffffa
    8000666e:	ed2080e7          	jalr	-302(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006672:	00002517          	auipc	a0,0x2
    80006676:	18e50513          	addi	a0,a0,398 # 80008800 <syscalls+0x3a0>
    8000667a:	ffffa097          	auipc	ra,0xffffa
    8000667e:	ec2080e7          	jalr	-318(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006682:	00002517          	auipc	a0,0x2
    80006686:	19e50513          	addi	a0,a0,414 # 80008820 <syscalls+0x3c0>
    8000668a:	ffffa097          	auipc	ra,0xffffa
    8000668e:	eb2080e7          	jalr	-334(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006692:	00002517          	auipc	a0,0x2
    80006696:	1ae50513          	addi	a0,a0,430 # 80008840 <syscalls+0x3e0>
    8000669a:	ffffa097          	auipc	ra,0xffffa
    8000669e:	ea2080e7          	jalr	-350(ra) # 8000053c <panic>

00000000800066a2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066a2:	7159                	addi	sp,sp,-112
    800066a4:	f486                	sd	ra,104(sp)
    800066a6:	f0a2                	sd	s0,96(sp)
    800066a8:	eca6                	sd	s1,88(sp)
    800066aa:	e8ca                	sd	s2,80(sp)
    800066ac:	e4ce                	sd	s3,72(sp)
    800066ae:	e0d2                	sd	s4,64(sp)
    800066b0:	fc56                	sd	s5,56(sp)
    800066b2:	f85a                	sd	s6,48(sp)
    800066b4:	f45e                	sd	s7,40(sp)
    800066b6:	f062                	sd	s8,32(sp)
    800066b8:	ec66                	sd	s9,24(sp)
    800066ba:	e86a                	sd	s10,16(sp)
    800066bc:	1880                	addi	s0,sp,112
    800066be:	8a2a                	mv	s4,a0
    800066c0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800066c2:	00c52c83          	lw	s9,12(a0)
    800066c6:	001c9c9b          	slliw	s9,s9,0x1
    800066ca:	1c82                	slli	s9,s9,0x20
    800066cc:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800066d0:	0001e517          	auipc	a0,0x1e
    800066d4:	94850513          	addi	a0,a0,-1720 # 80024018 <disk+0x128>
    800066d8:	ffffa097          	auipc	ra,0xffffa
    800066dc:	4fa080e7          	jalr	1274(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    800066e0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800066e2:	44a1                	li	s1,8
      disk.free[i] = 0;
    800066e4:	0001eb17          	auipc	s6,0x1e
    800066e8:	80cb0b13          	addi	s6,s6,-2036 # 80023ef0 <disk>
  for(int i = 0; i < 3; i++){
    800066ec:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066ee:	0001ec17          	auipc	s8,0x1e
    800066f2:	92ac0c13          	addi	s8,s8,-1750 # 80024018 <disk+0x128>
    800066f6:	a095                	j	8000675a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800066f8:	00fb0733          	add	a4,s6,a5
    800066fc:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006700:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006702:	0207c563          	bltz	a5,8000672c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006706:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006708:	0591                	addi	a1,a1,4
    8000670a:	05560d63          	beq	a2,s5,80006764 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000670e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006710:	0001d717          	auipc	a4,0x1d
    80006714:	7e070713          	addi	a4,a4,2016 # 80023ef0 <disk>
    80006718:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000671a:	01874683          	lbu	a3,24(a4)
    8000671e:	fee9                	bnez	a3,800066f8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006720:	2785                	addiw	a5,a5,1
    80006722:	0705                	addi	a4,a4,1
    80006724:	fe979be3          	bne	a5,s1,8000671a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006728:	57fd                	li	a5,-1
    8000672a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000672c:	00c05e63          	blez	a2,80006748 <virtio_disk_rw+0xa6>
    80006730:	060a                	slli	a2,a2,0x2
    80006732:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006736:	0009a503          	lw	a0,0(s3)
    8000673a:	00000097          	auipc	ra,0x0
    8000673e:	cfc080e7          	jalr	-772(ra) # 80006436 <free_desc>
      for(int j = 0; j < i; j++)
    80006742:	0991                	addi	s3,s3,4
    80006744:	ffa999e3          	bne	s3,s10,80006736 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006748:	85e2                	mv	a1,s8
    8000674a:	0001d517          	auipc	a0,0x1d
    8000674e:	7be50513          	addi	a0,a0,1982 # 80023f08 <disk+0x18>
    80006752:	ffffc097          	auipc	ra,0xffffc
    80006756:	c12080e7          	jalr	-1006(ra) # 80002364 <sleep>
  for(int i = 0; i < 3; i++){
    8000675a:	f9040993          	addi	s3,s0,-112
{
    8000675e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006760:	864a                	mv	a2,s2
    80006762:	b775                	j	8000670e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006764:	f9042503          	lw	a0,-112(s0)
    80006768:	00a50713          	addi	a4,a0,10
    8000676c:	0712                	slli	a4,a4,0x4

  if(write)
    8000676e:	0001d797          	auipc	a5,0x1d
    80006772:	78278793          	addi	a5,a5,1922 # 80023ef0 <disk>
    80006776:	00e786b3          	add	a3,a5,a4
    8000677a:	01703633          	snez	a2,s7
    8000677e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006780:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006784:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006788:	f6070613          	addi	a2,a4,-160
    8000678c:	6394                	ld	a3,0(a5)
    8000678e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006790:	00870593          	addi	a1,a4,8
    80006794:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006796:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006798:	0007b803          	ld	a6,0(a5)
    8000679c:	9642                	add	a2,a2,a6
    8000679e:	46c1                	li	a3,16
    800067a0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800067a2:	4585                	li	a1,1
    800067a4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800067a8:	f9442683          	lw	a3,-108(s0)
    800067ac:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800067b0:	0692                	slli	a3,a3,0x4
    800067b2:	9836                	add	a6,a6,a3
    800067b4:	058a0613          	addi	a2,s4,88
    800067b8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800067bc:	0007b803          	ld	a6,0(a5)
    800067c0:	96c2                	add	a3,a3,a6
    800067c2:	40000613          	li	a2,1024
    800067c6:	c690                	sw	a2,8(a3)
  if(write)
    800067c8:	001bb613          	seqz	a2,s7
    800067cc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067d0:	00166613          	ori	a2,a2,1
    800067d4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800067d8:	f9842603          	lw	a2,-104(s0)
    800067dc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067e0:	00250693          	addi	a3,a0,2
    800067e4:	0692                	slli	a3,a3,0x4
    800067e6:	96be                	add	a3,a3,a5
    800067e8:	58fd                	li	a7,-1
    800067ea:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067ee:	0612                	slli	a2,a2,0x4
    800067f0:	9832                	add	a6,a6,a2
    800067f2:	f9070713          	addi	a4,a4,-112
    800067f6:	973e                	add	a4,a4,a5
    800067f8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800067fc:	6398                	ld	a4,0(a5)
    800067fe:	9732                	add	a4,a4,a2
    80006800:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006802:	4609                	li	a2,2
    80006804:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006808:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000680c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006810:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006814:	6794                	ld	a3,8(a5)
    80006816:	0026d703          	lhu	a4,2(a3)
    8000681a:	8b1d                	andi	a4,a4,7
    8000681c:	0706                	slli	a4,a4,0x1
    8000681e:	96ba                	add	a3,a3,a4
    80006820:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006824:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006828:	6798                	ld	a4,8(a5)
    8000682a:	00275783          	lhu	a5,2(a4)
    8000682e:	2785                	addiw	a5,a5,1
    80006830:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006834:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006838:	100017b7          	lui	a5,0x10001
    8000683c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006840:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006844:	0001d917          	auipc	s2,0x1d
    80006848:	7d490913          	addi	s2,s2,2004 # 80024018 <disk+0x128>
  while(b->disk == 1) {
    8000684c:	4485                	li	s1,1
    8000684e:	00b79c63          	bne	a5,a1,80006866 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006852:	85ca                	mv	a1,s2
    80006854:	8552                	mv	a0,s4
    80006856:	ffffc097          	auipc	ra,0xffffc
    8000685a:	b0e080e7          	jalr	-1266(ra) # 80002364 <sleep>
  while(b->disk == 1) {
    8000685e:	004a2783          	lw	a5,4(s4)
    80006862:	fe9788e3          	beq	a5,s1,80006852 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006866:	f9042903          	lw	s2,-112(s0)
    8000686a:	00290713          	addi	a4,s2,2
    8000686e:	0712                	slli	a4,a4,0x4
    80006870:	0001d797          	auipc	a5,0x1d
    80006874:	68078793          	addi	a5,a5,1664 # 80023ef0 <disk>
    80006878:	97ba                	add	a5,a5,a4
    8000687a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000687e:	0001d997          	auipc	s3,0x1d
    80006882:	67298993          	addi	s3,s3,1650 # 80023ef0 <disk>
    80006886:	00491713          	slli	a4,s2,0x4
    8000688a:	0009b783          	ld	a5,0(s3)
    8000688e:	97ba                	add	a5,a5,a4
    80006890:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006894:	854a                	mv	a0,s2
    80006896:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000689a:	00000097          	auipc	ra,0x0
    8000689e:	b9c080e7          	jalr	-1124(ra) # 80006436 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068a2:	8885                	andi	s1,s1,1
    800068a4:	f0ed                	bnez	s1,80006886 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800068a6:	0001d517          	auipc	a0,0x1d
    800068aa:	77250513          	addi	a0,a0,1906 # 80024018 <disk+0x128>
    800068ae:	ffffa097          	auipc	ra,0xffffa
    800068b2:	3d8080e7          	jalr	984(ra) # 80000c86 <release>
}
    800068b6:	70a6                	ld	ra,104(sp)
    800068b8:	7406                	ld	s0,96(sp)
    800068ba:	64e6                	ld	s1,88(sp)
    800068bc:	6946                	ld	s2,80(sp)
    800068be:	69a6                	ld	s3,72(sp)
    800068c0:	6a06                	ld	s4,64(sp)
    800068c2:	7ae2                	ld	s5,56(sp)
    800068c4:	7b42                	ld	s6,48(sp)
    800068c6:	7ba2                	ld	s7,40(sp)
    800068c8:	7c02                	ld	s8,32(sp)
    800068ca:	6ce2                	ld	s9,24(sp)
    800068cc:	6d42                	ld	s10,16(sp)
    800068ce:	6165                	addi	sp,sp,112
    800068d0:	8082                	ret

00000000800068d2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068d2:	1101                	addi	sp,sp,-32
    800068d4:	ec06                	sd	ra,24(sp)
    800068d6:	e822                	sd	s0,16(sp)
    800068d8:	e426                	sd	s1,8(sp)
    800068da:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068dc:	0001d497          	auipc	s1,0x1d
    800068e0:	61448493          	addi	s1,s1,1556 # 80023ef0 <disk>
    800068e4:	0001d517          	auipc	a0,0x1d
    800068e8:	73450513          	addi	a0,a0,1844 # 80024018 <disk+0x128>
    800068ec:	ffffa097          	auipc	ra,0xffffa
    800068f0:	2e6080e7          	jalr	742(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068f4:	10001737          	lui	a4,0x10001
    800068f8:	533c                	lw	a5,96(a4)
    800068fa:	8b8d                	andi	a5,a5,3
    800068fc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068fe:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006902:	689c                	ld	a5,16(s1)
    80006904:	0204d703          	lhu	a4,32(s1)
    80006908:	0027d783          	lhu	a5,2(a5)
    8000690c:	04f70863          	beq	a4,a5,8000695c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006910:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006914:	6898                	ld	a4,16(s1)
    80006916:	0204d783          	lhu	a5,32(s1)
    8000691a:	8b9d                	andi	a5,a5,7
    8000691c:	078e                	slli	a5,a5,0x3
    8000691e:	97ba                	add	a5,a5,a4
    80006920:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006922:	00278713          	addi	a4,a5,2
    80006926:	0712                	slli	a4,a4,0x4
    80006928:	9726                	add	a4,a4,s1
    8000692a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000692e:	e721                	bnez	a4,80006976 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006930:	0789                	addi	a5,a5,2
    80006932:	0792                	slli	a5,a5,0x4
    80006934:	97a6                	add	a5,a5,s1
    80006936:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006938:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000693c:	ffffc097          	auipc	ra,0xffffc
    80006940:	a8c080e7          	jalr	-1396(ra) # 800023c8 <wakeup>

    disk.used_idx += 1;
    80006944:	0204d783          	lhu	a5,32(s1)
    80006948:	2785                	addiw	a5,a5,1
    8000694a:	17c2                	slli	a5,a5,0x30
    8000694c:	93c1                	srli	a5,a5,0x30
    8000694e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006952:	6898                	ld	a4,16(s1)
    80006954:	00275703          	lhu	a4,2(a4)
    80006958:	faf71ce3          	bne	a4,a5,80006910 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000695c:	0001d517          	auipc	a0,0x1d
    80006960:	6bc50513          	addi	a0,a0,1724 # 80024018 <disk+0x128>
    80006964:	ffffa097          	auipc	ra,0xffffa
    80006968:	322080e7          	jalr	802(ra) # 80000c86 <release>
}
    8000696c:	60e2                	ld	ra,24(sp)
    8000696e:	6442                	ld	s0,16(sp)
    80006970:	64a2                	ld	s1,8(sp)
    80006972:	6105                	addi	sp,sp,32
    80006974:	8082                	ret
      panic("virtio_disk_intr status");
    80006976:	00002517          	auipc	a0,0x2
    8000697a:	ee250513          	addi	a0,a0,-286 # 80008858 <syscalls+0x3f8>
    8000697e:	ffffa097          	auipc	ra,0xffffa
    80006982:	bbe080e7          	jalr	-1090(ra) # 8000053c <panic>
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
