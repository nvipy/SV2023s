	section	text



	bra	run

	include		"INCLUDES/BIOS.S"
	include		"INCLUDES/SYS.S"
	include		"INCLUDES/MATH.I"
 
	section	text
run:

	dc.l		$a000a00a              ;Mouse off
	bsr		SetSuper
	;bsr		StopMFP
	bsr		SaveScreen
	
;	bsr		InitRTZ2
	bsr		InitRTZ3

	move.l		#buffers,d0
	move.l		#256,d1
	bsr		SetSTEBuffers
	
	bsr		SwapSTEBuffers
	
	lea		Vbl,a0
	bsr		SetVbl

;run:
;	bsr	SetBuffers
;
;	bsr	InitRTZ2
;
;	bsr	SetSuper
;	bsr	SaveScreen
;
;       move.l 		#$fff,$ffff8240

	lea		cmap,a0
	bsr		SetColors	; a0 = palette ptr  

	clr.w	VblStrobe
	
mainloop:
;	bsr	WaitVbl
	tst.w	VblStrobe
	beq.s	.0

;       move.w 	#$700,$ffff8240
;	bsr	SwapBuffers

	move.w	zoomOfs,d0
	and.w	#4095,d0
	lea	cos,a0
	move.w	2(a0,d0.w),d1
	add.w	#4*3,zoomOfs
	asr.w	#5,d1		; -1024,1024
	add.w	#1280,d1
	move.w	d1,d2
	add.w	#256,d1
	lsr.w	#2,d2
	add.w	#64,d2
	movem.w	d1/d2,xyZoom

	subq.l	#2,backBuf

	bsr	PrepareRTZ
 ;      move.w 	#$007,$ffff8240
	bsr	DrawRTZ2
	addq.w	#4,alpha
	and.w	#$ffc,alpha

 ;       move.w 	#$777,$ffff8240
	bsr	SwapSTEBuffers
	clr.w	VblStrobe

.0:
	cmp.b	#$39,$fffc02
	bne.s	mainloop
	
;	bsr	RestoreScreen
;	bsr	SetUser

;	clr.l	-(a7)
;	trap	#1

	bsr		ResetVbl
        move.w 		#$700,$ffff8240.w
	bsr		RestoreHbl	; use a4,a5
        move.w 		#$70,$ffff8240.w
	bsr		RestoreScreen
        move.w 		#$7,$ffff8240.w
	;bsr		RestoreMFP
        move.w 		#$fff,$ffff8240.w
	bsr		SetUser
	dc.l		$a000a009               ;Mouse on
	clr.l		-(a7)
	trap		#1

;-----------------------------------------------
Vbl:
	addq.w		#1,VblStrobe
	rte	

VblStrobe:	dc.w	0
cmap:		dc.w	0,$111,$222,$333,$444,$555,$666,$777,$888,$999,$aaa,$bbb,$ccc,$ddd,$eee,$fff
;-----------------------------------------------

;SetBuffers:
;	move.l	#buffers,d0
;	add.l	#255,d0
;	clr.b	d0
;	move.l	d0,frontBuf
;	add.l	#32255,d0
;	clr.b	d0
;	move.l	d0,backBuf
;	rts
;
;SwapBuffers:
;	lea	frontBuf,a0
;	move.l	4(a0),d0
;	move.l	(a0),4(a0)
;	move.l	d0,(a0)
;	lea	$ffff8201,a6
;	lsr.w	#8,d0
;	move.b	d0,2(a6)
;	swap	d0
;	move.b	d0,(a6)
;	clr.b	$c(a6)
;	rts
;	
;SetScreenAdrs:	;D0 = screen adrs
;	lea	$ffff8201,a6
;	lsr.w	#8,d0
;	move.b	d0,2(a6)
;	swap	d0
;	move.b	d0,(a6)
;	clr.b	$c(a6)
;	rts

;WaitVbl:
;	move.w	#37,-(sp)
;	trap	#14
;	addq.l	#2,sp
;	rts
;
;SetSuper:
; 
;	clr.l	-(a7)                   ; clear stack
;	move.w  #32,-(a7)               ; prepare for user mode
;	trap    #1                      ; call gemdos
;	addq.l  #6,a7                   ; clean up stack
;	move.l  d0,old_stack            ; backup old stack pointer
;
;	rts
;
;SaveScreen:
;
;	move.l  #old_palette,a0         ; put backup address in a0
;	movem.l $ffff8240,d0-d7         ; all palettes in d0-d7
;	movem.l d0-d7,(a0)              ; move data into old_palette

;        move.w  #2,-(a7)                ; get physbase
;        trap    #14
;        addq.l  #2,a7
;        move.l  d0,old_screen           ; save old screen address
;
;        move.w  #4,-(a7)                ; get resolution
;        trap    #14
;        addq.l  #2,a7
;        move.w  d0,old_resolution       ; save resolution
;                
;        move.w  #0,-(a7)                ; low resolution
;        move.l  #-1,-(a7)               ; keep physbase
;        move.l  #-1,-(a7)               ; keep logbase
;        move.w  #5,-(a7)                ; change screen
;        trap    #14
;        add.l   #12,a7  
;
;        rts
;
;RestoreScreen:
;        move.w  old_resolution,d0       ; res in d0
;        move.w  d0,-(a7)                ; push resolution
;        move.l  old_screen,d0           ; screen in d0
;        move.l  d0,-(a7)                ; push physbase
;        move.l  d0,-(a7)                ; push logbase
;        move.w  #5,-(a7)                ; change screen
;        trap    #14
;        add.l   #12,a7
;
;        move.l  #old_palette,a0         ; palette pointer in a0
;        movem.l (a0),d0-d7              ; move palette data
;        movem.l d0-d7,$ffff8240         ; smack palette in
;
;	rts
;
;SetUser:
;        move.l  old_stack,-(a7)         ; restore old stack pointer
;        move.w  #32,-(a7)               ; back to user mode
;        trap    #1                      ; call gemdos
;        addq.l  #6,a7                   ; clear stack
;  
;        rts
;    
;;-----------------------------------------------
;PrintByte:		; a6=adress d7=colorplan d6=x,y d5=byte
;	movem.l	d0-d1/d3-d4/a3-a4,-(sp)
;	move.l	d5,d4
;	moveq.l	#1,d3
;.bloop
;	rol.b	#4,d4
;	moveq.l	#0,d5
;	move.b	d4,d5
;	and.b	#$f,d5
;	cmp.b	#9,d5
;	ble.s	.num
;	add.b	#'A'-10,d5
;	bra.s	.alpha
;.num
;	add.b	#'0',d5
;.alpha
;	bsr	PrintChar
;	add.l	#$10000,d6
;	dbra	d3,.bloop
;.end:
;	movem.l	(sp)+,d0-d1/d3-d4/a3-a4
;	rts
;
;PrintWord:		; a6=adress d7=colorplan d6=x,y d5=byte
;	movem.l	d0-d1/d3-d4/a3-a4,-(sp)
;	move.l	d5,d4
;	moveq.l	#3,d3
;.bloop
;	rol.w	#4,d4
;	moveq.l	#0,d5
;	move.b	d4,d5
;	and.b	#$f,d5
;	cmp.b	#9,d5
;	ble.s	.num
;	add.b	#'A'-10,d5
;	bra.s	.alpha
;.num
;	add.b	#'0',d5
;.alpha
;	bsr	PrintChar
;	add.l	#$10000,d6
;	dbra	d3,.bloop
;.end:
;	movem.l	(sp)+,d0-d1/d3-d4/a3-a4
;	rts
;
;PrintLong:		; a6=adress d7=colorplan d6=x,y d5=byte
;	movem.l	d0-d1/d3-d4/a3-a4,-(sp)
;	move.l	d5,d4
;	moveq.l	#7,d3
;.bloop
;	rol.l	#4,d4
;	moveq.l	#0,d5
;	move.b	d4,d5
;	and.b	#$f,d5
;	cmp.b	#9,d5
;	ble.s	.num
;	add.b	#'A'-10,d5
;	bra.s	.alpha
;.num
;	add.b	#'0',d5
;.alpha
;	bsr	PrintChar
;	add.l	#$10000,d6
;	dbra	d3,.bloop
;.end:
;	movem.l	(sp)+,d0-d1/d3-d4/a3-a4
;	rts
;
;PrintText:		; a6=adress a5=text d7=colorplan d6=x,y
;	movem.l	d0-d1/d5/a3-a4,-(sp)
;	move.b	(a6)+,d5
;	beq.s	.end
;	bsr	PrintChar
;	add.l	#$10000,d6
;	bra.s	PrintText
;.end:
;	movem.l	(sp)+,d0-d1/d5/a3-a4
;	rts
;
;PrintChar:		; a6=adress d7=colorplan d6=x,y d5=char
;	move.l	d6,-(sp)
;
;	lsl.w	#8,d6	; y*256
;	move.w	d6,d0
;	add.w	d6,d6
;	add.w	d6,d6	; y*1024
;	add.w	d6,d0	; y*1280
;	swap	d6
;	move.w	d6,d1
;	and.w	#1,d1
;	and.w	#$fe,d6
;	add.w	d6,d6
;	add.w	d6,d6
;	add.w	d1,d6
;	add.w	d6,d0
;	add.w	d7,d0
;	add.w	d7,d0
;	lea	(a6,d0.w),a4
;
;	move.w	d5,d0
;	lsl.w	#3,d0
;	lea	font,a3
;	lea	(a3,d0.w),a3
;
;	move.b	(a3)+,(a4)
;	move.b	(a3)+,160(a4)
;	move.b	(a3)+,320(a4)
;	move.b	(a3)+,480(a4)
;	move.b	(a3)+,640(a4)
;	move.b	(a3)+,800(a4)
;	move.b	(a3)+,960(a4)
;	move.b	(a3),1120(a4)
;
;	move.l	(sp)+,d6
;	rts
;
;
;LCopy:			; a0=src,a1=dst,d0=length/256
;	movem.l		d1-d7/a2-a3,-(sp)
;	move.w		#256,a3
;.lcloop:
;	movem.l		(a0)+,d1-d7/a2 	;8 longs: 32 bytes
;	movem.l		d1-d7/a2,(a1)
;	movem.l		(a0)+,d1-d7/a2
;	movem.l		d1-d7/a2,32(a1)
;	movem.l		(a0)+,d1-d7/a2
;	movem.l		d1-d7/a2,64(a1)
;	movem.l		(a0)+,d1-d7/a2
;	movem.l		d1-d7/a2,96(a1)
;	movem.l		(a0)+,d1-d7/a2
;	movem.l		d1-d7/a2,128(a1)
;	movem.l		(a0)+,d1-d7/a2
;	movem.l		d1-d7/a2,160(a1)
;	movem.l		(a0)+,d1-d7/a2
;	movem.l		d1-d7/a2,192(a1)
;	movem.l		(a0)+,d1-d7/a2
;	movem.l		d1-d7/a2,224(a1)
;	add.l		a3,a1
;	dbra		d0,.lcloop
;	movem.l		(sp)+,d1-d7/a2-a3
;
;	rts

;-----------------------------------------------
wt 	= 	128;128
ht 	= 	64;16

dt 	=	wt*8

;InitRTZ:
;	lea	image,a0
;	lea	texture,a1
;	move.l	#$c0300c03,d4
;	move.w	#ht-1,d3
;.yloop
;	move.w	#wt-1,d2
;.xloop
;	move.b	(a0)+,d0
;	move.l	d4,d1
;	cmp.b	#'A',d0
;	beq.s	.notransp
;	moveq.l	#0,d1
;.notransp
;	move.l	d1,(a1)
;	move.l	d1,4(a1)
;	move.l	d1,dt(a1)
;	move.l	d1,dt+4(a1)
;	addq.l	#8,a1
;	dbra	d2,.xloop
;
;	add.l	#dt,a1
;	dbra	d3,.yloop
;	
;	lea	texture,a0
;	lea	(a0),a1
;	add.l	#32768,a1
;	lea	(a1),a2
;	add.l	#32768,a2
;	lea	(a2),a3
;	add.l	#32768,a3
;	move.w	#1024-1,d0
;.copy
;	rept	8
;		move.l	(a0)+,d1
;		move.l	d1,(a1)+
;		move.l	d1,(a2)+
;		move.l	d1,(a3)+
;	endr
;	dbf	d0,.copy
;	rts

;---------------------------------------------------------
;InitRTZ2:
;	lea	image,a0
;	lea	texture,a2
;	move.l	#65536*2,d0
;	lea	(a2,d0.l),a3
;	lea	(a3,d0.l),a4
;	lea	(a4,d0.l),a5
;	move.w	#ht-1,d7
;.yloop2
;	move.w	#wt-1,d6
;.xloop2
;	move.b	(a0)+,d0
;	moveq.l	#0,d2
;	moveq.l	#0,d3
;	moveq.l	#0,d4
;	moveq.l	#0,d5
;	cmp.b	#'A',d0
;	bne.s	.transp2
;	move.l	#$000c0003,d5
;	move.l	#$00c00030,d4
;	move.l	#$0c000300,d3
;	move.l	#$c0003000,d2
;.transp2
;	move.l	d2,(a2)
;	move.l	d2,4(a2)
;	move.l	d2,dt(a2)
;	move.l	d2,dt+4(a2)
;	addq.l	#8,a2
;
;	move.l	d3,(a3)
;	move.l	d3,4(a3)
;	move.l	d3,dt(a3)
;	move.l	d3,dt+4(a3)
;	addq.l	#8,a3
;
;	move.l	d4,(a4)
;	move.l	d4,4(a4)
;	move.l	d4,dt(a4)
;	move.l	d4,dt+4(a4)
;	addq.l	#8,a4
;
;	move.l	d5,(a5)
;	move.l	d5,4(a5)
;	move.l	d5,dt(a5)
;	move.l	d5,dt+4(a5)
;	addq.l	#8,a5
;
;	dbra	d6,.xloop2
;
;	add.w	#dt,a2
;	add.w	#dt,a3
;	add.w	#dt,a4
;	add.w	#dt,a5
;	dbra	d7,.yloop2
;
;	move.l	#65536*2,d0
;	lea	texture+32768,a2
;	lea	(a2,d0.l),a3
;	lea	(a3,d0.l),a4
;	lea	(a4,d0.l),a5
;	move.l	#-32768,d0
;	
;	move.w	#1024-1,d1
;.copy2
;	rept	8
;		move.l	(a2,d0.l),(a2)+
;		move.l	(a3,d0.l),(a3)+
;		move.l	(a4,d0.l),(a4)+
;		move.l	(a5,d0.l),(a5)+
;	endr
;	dbf	d1,.copy2
;
;	move.l	#65536*2,d0
;	lea	texture+32768*2,a2
;	lea	(a2,d0.l),a3
;	lea	(a3,d0.l),a4
;	lea	(a4,d0.l),a5
;	move.l	#-32768*2,d0
;	
;	move.w	#1024*2-1,d1
;.copy3
;	rept	8
;		move.l	(a2,d0.l),(a2)+
;		move.l	(a3,d0.l),(a3)+
;		move.l	(a4,d0.l),(a4)+
;		move.l	(a5,d0.l),(a5)+
;	endr
;	dbf	d1,.copy3
;
;	rts

;---------------------------------------------------------
InitRTZ3:
	lea	rzimg,a0
	lea	texture,a2
	move.l	#65536*2,d0
	lea	(a2,d0.l),a3
	lea	(a3,d0.l),a4
	lea	(a4,d0.l),a5

	move.l	#$000c0003,d5
	move.l	#$00c00030,d4
	move.l	#$0c000300,d3
	move.l	#$c0003000,d2

	move.w	#ht-1,d7
.yloop2
	move.w	#wt/8-1,d6
.xloop2
	move.b	(a0)+,d0
	moveq	#8-1,d1
.bloop2
	add.w	d0,d0
	bcc.s	.set
.clr
	clr.l	(a2)+
	clr.l	(a3)+
	clr.l	(a4)+
	clr.l	(a5)+
	bra.s	.endset
.set	
	move.l	d2,(a2)+
	move.l	d3,(a3)+
	move.l	d4,(a4)+
	move.l	d5,(a5)+
.endset
	dbra	d1,.bloop2
	dbra	d6,.xloop2
	dbra	d7,.yloop2

	move.l	#65536*2,d0
	lea	texture+32768,a2
	lea	(a2,d0.l),a3
	lea	(a3,d0.l),a4
	lea	(a4,d0.l),a5
	move.l	#-32768,d0
	
	move.w	#1024-1,d1
.copy2
	rept	8
		move.l	(a2,d0.l),(a2)+
		move.l	(a3,d0.l),(a3)+
		move.l	(a4,d0.l),(a4)+
		move.l	(a5,d0.l),(a5)+
	endr
	dbf	d1,.copy2

	move.l	#65536*2,d0
	lea	texture+32768*2,a2
	lea	(a2,d0.l),a3
	lea	(a3,d0.l),a4
	lea	(a4,d0.l),a5
	move.l	#-32768*2,d0
	
	move.w	#1024*2-1,d1
.copy3
	rept	8
		move.l	(a2,d0.l),(a2)+
		move.l	(a3,d0.l),(a3)+
		move.l	(a4,d0.l),(a4)+
		move.l	(a5,d0.l),(a5)+
	endr
	dbf	d1,.copy3

uu:
	lea		sin,a0
	moveq		#10,d0
	move.l		#$8000,d1
	bsr		MATH_makeSins	; A0 = destination, sinus word array ptr, D0 = destination depth (length = 2^depth), D1 = phase [-32768,32768[ : [-PI/2,PI/2[, use -32768 for Sinus, use 0 for Cosinus

	lea		sin,a0
	move.l		a0,a2
	lea		cos,a1
	move.w		#512*1,d0
	move.w		#1024-1,d7
.cosloop:	
	move.w		(a0,d0),d1
	cmp.w		#$1000,d1
	bne.s		.0a
	subq.w		#1,d1
.0a
	cmp.w		#$F000,d1
	bne.s		.1a
	addq.w		#1,d1
.1a
	asl.w		#3,d1
	move.w		d1,(a1)+

	move.w		(a2)+,d1
	cmp.w		#$1000,d1
	bne.s		.0b
	subq.w		#1,d1
.0b
	cmp.w		#$F000,d1
	bne.s		.1b
	addq.w		#1,d1
.1b
	asl.w		#3,d1
	move.w		d1,(a1)+

	addq.w		#2,d0
	and.w		#2047,d0
	dbra		d7,.cosloop

	rts

rowCount	=	100
wordCount	=	20
colCount	=	wordCount*8

;SetRaster:
;TEXEL	macro
;		move.w	d5,d7	; iHy.iLy
;		move.b	d6,d7	; iHy.iHx
;		add.w	d7,d7
;		add.w	d7,d7	; iHy.iHx * 4
;		add.l	d1,d5	; iLx.00.iHy.iLy += Lx.00.Hy.Ly
;		addx.b	d2,d6	; iHx + = Hx
;	endm
;
;	movem.l	d3/d4/d6/d7,-(sp)
;
;	moveq.l	#38,d3
;	moveq.l	#wordCount-1,d4
;	moveq.l	#0,d5
;	moveq.l	#0,d6
;
;	lea	Rasterize+2,a6
;.rloop
;	TEXEL
;	move.w	d7,(a6)
;	TEXEL
;	addq.w	#1,d7
;	move.w	d7,4(a6)
;	TEXEL
;	addq.w	#2,d7
;	move.w	d7,8(a6)
;	TEXEL
;	addq.w	#3,d7
;	move.w	d7,12(a6)
;	TEXEL
;	move.w	d7,18(a6)
;	TEXEL
;	addq.w	#1,d7
;	move.w	d7,22(a6)
;	TEXEL
;	addq.w	#2,d7
;	move.w	d7,26(a6)
;	TEXEL
;	addq.w	#3,d7
;	move.w	d7,30(a6)
;	add.l	d3,a6
;	dbf	d4,.rloop
;
;	movem.l	(sp)+,d3/d4/d6/d7
;
;	rts
;
;Rasterize:
;	rept	wordCount
;		move.b	$1000(a0),d0
;		or.b	$1001(a0),d0
;		or.b	$1002(a0),d0
;		or.b	$1003(a0),d0
;		move.b	d0,(a1)+
;		move.b	$1000(a0),d0
;		or.b	$1001(a0),d0
;		or.b	$1002(a0),d0
;		or.b	$1003(a0),d0
;		move.b	d0,(a1)+
;		addq.l	#6,a1
;	endr
;	rts

SetRaster2:
TEXEL2	macro
		move.w	d5,d7	; iHy.iLy
		move.b	d6,d7	; iHy.iHx
;		add.w	d7,d7
		add.w	d7,d7	; iHy.iHx * 4
		and.w	d0,d7
		add.l	d1,d5	; iLx.00.iHy.iLy += Lx.00.Hy.Ly
		addx.b	d2,d6	; iHx + = Hx
	endm

	movem.l	d0/d3/d4/d6/d7,-(sp)

	moveq.l	#40-4,d3
	moveq.l	#wordCount-1,d4
	moveq.l	#0,d5
	moveq.l	#0,d6
	move.w	#$7ffc,d0

	lea	Rasterize2+2,a6
.rloop2
	TEXEL2
	move.w	d7,(a6)
	TEXEL2
	addq.w	#2,d7
	move.w	d7,4(a6)
	TEXEL2
	move.w	d7,8(a6)
	TEXEL2
	addq.w	#2,d7
	move.w	d7,12(a6)
	TEXEL2
	move.w	d7,16(a6)
	TEXEL2
	addq.w	#2,d7
	move.w	d7,20(a6)
	TEXEL2
	move.w	d7,24(a6)
	TEXEL2
	addq.w	#2,d7
	move.w	d7,28(a6)
	TEXEL2

	add.l	d3,a6
	dbf	d4,.rloop2

	movem.l	(sp)+,d0/d3/d4/d6/d7

	rts

Rasterize2:
	rept	wordCount
		move.w	$1000(a0),d0
		or.w	$1002(a0),d0
		or.w	$1000(a1),d0
		or.w	$1002(a1),d0
		or.w	$1000(a2),d0
		or.w	$1002(a2),d0
		or.w	$1000(a3),d0
		or.w	$1002(a3),d0
		move.w	d0,(a4)+
		;move.w	d0,(a5)+
		addq.l	#6,a4
		;addq.l	#6,a5
	endr
	rts

alpha		dc.w	2048+512
zoomOfs		dc.w	0
xyZoom		dc.w	256,64 
xyCenter 	dc.w	0,0	; no yet implemented
LxHLy:		dc.l	0,0
Hx:		dc.b	0,0

PrepareRTZ:
	lea	LxHLy(pc),a1
	move.w	alpha(pc),d0
	lea	cos,a0

	move.l	xyZoom(pc),d6
	move.w	d6,d7	; ry
	swap	d6	; rx

	move.l	(a0,d0.w),d3
	move.w	d3,d4	; sin0
	swap	d3	; cos0
	muls	d6,d3	; x0=ry*sin0
	muls	d7,d4	; y0=rx*cos0

	add.w	#1024,d0
	and.w	#$ffc,d0
	move.l	(a0,d0.w),d1
	move.w	d1,d2	; sin1
	swap	d1	; cos1
	muls	d6,d1	; x1=ry*sin1
	muls	d7,d2	; y1=rx*cos1

	sub.l	d3,d1	; vx=x1-x0
	sub.l	d4,d2	; vy=y1-y0
	asr.l	#8,d1	; ??.Hx.Hx.Lx
	asr.l	#8,d2	; ??.Hy.Hy.Ly
	divs	#colCount,d1 ; ux=vx/160
	divs	#colCount,d2 ; uy=vy/160

	lsl.l	#8,d1		; ??.Hx.Lx.00
	swap	d1		; Lx.00.??.Hx
	move.b	d1,8(a1)	; ??.??.??.Hx
	move.w	d2,d1		; Lx.00.Hy.Ly
	move.l	d1,(a1)		; LxHLy

	sub.w	#2048,d0
	and.w	#$ffc,d0
	move.l	(a0,d0.w),d1
	move.w	d1,d2	; sin2
	swap	d1	; cos2
	muls	d6,d1	; x2=ry*sin1
	muls	d7,d2	; y2=rx*cos1

	move.w	d1,d5
	asr.w	#2,d5
	add.w	d5,d1
	move.w	d2,d5
	asr.w	#2,d5
	add.w	d5,d2

	sub.l	d3,d1	; vx=x2-x0
	sub.l	d4,d2	; vy=y2-y0
	asr.l	#8,d1	; ss.Hx.Hx.Lx
	asr.l	#8,d2	; ss.Hy.Hy.Ly
	divs	#rowCount,d1 ; ux=vx/100
	divs	#rowCount,d2 ; uy=vy/100

	lsl.l	#8,d1		; ??.Hx.Lx.00
	swap	d1		; Lx.00.??.Hx
	move.b	d1,9(a1)	; ??.??.??.Hx
	move.w	d2,d1		; Lx.00.Hy.Ly
	move.l	d1,4(a1)	; LxHLy

	rts

;DrawRTZ:
;	lea	LxHLy(pc),a1
;	move.b	8(a1),d2	; ??.??.??.Hx
;	move.l	(a1),d1		; LxHLy
;
;	bsr	SetRaster
;
;	move.b	9(a1),d2	; ??.??.??.Hx
;	move.l	4(a1),d1	; LxHLy
;
;	lea	texture+65536,a2
;	move.l	backBuf,a1
;	add.w	#(20-wordCount)*4,a1
;	moveq.l	#rowCount-1,d3
;	move.w	#160+(20-wordCount)*8,a3
;	moveq.l	#0,d5
;	moveq.l	#0,d6
;
;.drtzloop
;	move.w	d5,d7	; iHy.iLy
;	move.b	d6,d7	; iHy.iHx
;	add.w	d7,d7
;	add.w	d7,d7	; iHy.iHx * 4
;	add.l	d1,d5	; iLx.00.iHy.iLy += Lx.00.Hy.Ly
;	addx.b	d2,d6	; iHx + = Hx
;
;	lea	(a2,d7.w),a0
;	bsr	Rasterize
;	add.l	a3,a1
;
;	dbra	d3,.drtzloop
;
;	rts

DrawRTZ2:
	lea	LxHLy(pc),a1
	move.b	8(a1),d2	; ??.??.??.Hx
	move.l	(a1),d1		; LxHLy

	bsr	SetRaster2

	move.b	9(a1),d2	; ??.??.??.Hx
	move.l	4(a1),d1	; LxHLy

	lea	texture+32768*2,a6
	move.l	backBuf,a4
	add.w	#(20-wordCount)*4,a4
	lea	160(a4),a5
	moveq.l	#rowCount-1,d3
	moveq.l	#0,d5
	moveq.l	#0,d6
	move.l	#65536*2,d4

.drtzloop2
	move.w	d5,d7	; iHy.iLy
	move.b	d6,d7	; iHy.iHx
;	add.w	d7,d7
	add.w	d7,d7	; iHy.iHx * 4
	and.w	#$7ffc,d7
	add.l	d1,d5	; iLx.00.iHy.iLy += Lx.00.Hy.Ly
	addx.b	d2,d6	; iHx + = Hx

	lea	(a6,d7.w),a0
	lea	(a0,d4.l),a1
	lea	(a1,d4.l),a2
	lea	(a2,d4.l),a3
	bsr	Rasterize2
	add.w	#160+(20-wordCount)*8,a4
	add.w	#160+(20-wordCount)*8,a5

	dbra	d3,.drtzloop2

;-----------------------------------------------
; STE Blitter
; D0: srcIncX,srcModulo
; D1: dstIncY,scrModulo
; D2: msk
; D3: width in word, height
; D4: start flag : fast #$0203c000/ slow #$02038000
; D5: Set to 7  
; A0: source ptr
; A1: dest ptr
;-----------------------------------------------

	move.l		backBuf,a0		; SrcPtr
	lea		$ffff8a20.w,a6		; First register needed by us
	move.l		#$80000+168,(a6)+	; SrcXinc.SrcYinc
	move.l		a0,(a6)+		; SrcPtr
	move.l		#-1,(a6)+		; Fmsk.Mmsk
	move.w		#-1,(a6)+		; Lmsk
	move.l		#$80000+168,(a6)+	; DstXinc.DstYinc
	lea		160(a0),a0
	move.l		a0,(a6)+		; DstPtr
	move.l		#(20<<16)!100,(a6)+	; Width.Height
	move.l		#$0203c000,(a6)

	rts

;-----------------------------------------------
                section data

;old_resolution  dc.w    0
;old_stack       dc.l    0
;old_screen      dc.l    0

;frontBuf	dc.l	0
;backBuf		dc.l	0
;image:		dc.b	"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
;		dc.b	"                                                                                                                                "
;		dc.b	"     AAAA                                         AAAAAAAAAA                                                 AA AA AA           "
;		dc.b	"   AAA  AAA                                       AAA      AAA                                               AA AA AA           "
;		dc.b	"  AAA    AAA                                      AAA       AAA           AAA                                AA AA AA           "
;		dc.b	" AAA      AAA  AAA                         AAA    AAA       AAA           AAA                                AA AA AA           "
;		dc.b	" AAA      AAA  AAA                         AAA    AAA       AAA           AAA                                AA AA AA           "
;		dc.b	" AAA      AAA  AAA                                AAA      AAA            AAA                               AAA AA AAA          "
;		dc.b	" AAAAAAAAAAAA AAAAAA   AAAAAAA   AAAAAAAA  AAA    AAAAAAAAAAA   AAA   AAA AAA  AAAAAAA   AAAAAAA           AAA  AA  AAA         "
;		dc.b	" AAA      AAA  AAA    AAA   AAA  AAA   AAA AAA    AAA      AAA  AAA   AAA AAA AAA   AAA AAA   AAA         AAAA  AA   AAAA       "
;		dc.b	" AAA      AAA  AAA          AAA  AAA       AAA    AAA       AAA AAA   AAA AAA AAA   AAA AAA              AAAA   AA    AAAA      "
;		dc.b	" AAA      AAA  AAA     AAAAAAAA  AAA       AAA    AAA       AAA AAA   AAA AAA AAAAAAAA   AAAAAAA       AAAAA    AA     AAAAA    "
;		dc.b	" AAA      AAA  AAA    AAA   AAA  AAA       AAA    AAA       AAA AAA   AAA AAA AAA             AAA   AAAAAAA     AA      AAAAAAA "
;		dc.b	" AAA      AAA  AAA    AAA   AAA  AAA       AAA    AAA       AAA AAA   AAA AAA AAA   AAA AAA   AAA   AAAAA       AA       AAAAAA "
;		dc.b	" AAA      AAA   AAAAA  AAAAAA AA AAA      AAAAA   AAA       AAA  AAAAAAA  AAA  AAAAAAA   AAAAAAA    AAA         AA         AAAA "
;		dc.b	"                                                                                                                                "
;cos:		incbin	"data/cossin.dta"
rzimg:		incbin	"data/rzimg.dta"

;-----------------------------------------------
                section bss
                even
;old_palette     ds.l    8
sin:		ds.b	1024*2
cos:		ds.b	1024*4
		ds.b	32768
buffers		ds.b	65536
texture		ds.b	65536*8

	end