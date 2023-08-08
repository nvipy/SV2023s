	section	text



	bra	run

	include		"INCLUDES/BIOS.I"
	include		"INCLUDES/SYS.I"
	include		"INCLUDES/MATH.I"
	include		"INCLUDES/IMG.I"
	include		"INCLUDES/TASKMAN.I"
	include		"INCLUDES/PROPFONT.I"
 
	section	text
run:

	dc.l		$a000a00a              ;Mouse off
	bsr		SetSuper
	bsr		StopMFP
	bsr		SaveScreen

	move.l		#buffers,d0
	move.l		#256,d1
	bsr		SetSTEBuffers
	
	bsr		SwapSTEBuffers


	lea		Sequence,a0
	lea		SequenceEnd,a1
	bsr		TASK_initSequence	;A0: SequencePtr, A1: end of SequencePtr Set TASK_SeqIsRunning to 1
	
	lea		Vbl,a0
	bsr		SetVbl

;	clr.w		VblStrobe
	
mainloop:

	WAIT_VBL
	TASK_CALL	_TASK_Main		; Task call macro, /1: _TASK_Main or _TASK_Vbl, return -1 if seq finished
	;move.l		#$fff0000,$ffff8240.w


;	tst.w		VblStrobe
;	beq.s		.0

;	bsr.s		PlayRTZ
;	clr.w		VblStrobe

;.0:	
	cmp.b		#$39,$fffc02
	bne.s		mainloop

	bsr		AUD_stop

	bsr		ResetVbl
	move.w 		#$700,$ffff8240.w
	bsr		RestoreHbl	; use a4,a5
	move.w 		#$70,$ffff8240.w
	bsr		RestoreScreen
	move.w 		#$7,$ffff8240.w
	bsr		RestoreMFP
	move.w 		#$fff,$ffff8240.w
	bsr		SetUser
	dc.l		$a000a009               ;Mouse on
	clr.l		-(a7)
	trap		#1

;-----------------------------------------------
Vbl:
	movem.l		d0-d7/a0-a6,-(sp)
	bsr		TASK_runSequence	; Clear TASK_SeqIsRunning when sequence is finished
	TASK_CALL	_TASK_Vbl		; Task call macro, /1: _TASK_Main or _TASK_Vbl, return -1 if seq finished
	movem.l		(sp)+,d0-d7/a0-a6
	rte				


;	addq.w		#1,VblStrobe
;	rte	

;VblStrobe:	dc.w	0

Sequence:
		TASK_MAKE	initTitle,NULL,TASK_MAX_DURATION,0

		TASK_MAKE	initRTZ,initfader01,TASK_MAX_DURATION,0

		;TASK_MAKE	NULL,initfader01,TASK_MAX_DURATION,0
		TASK_MAKE	NULL,fader,TASK_MAX_DURATION,0

		TASK_MAKE	NULL,NULL,30,0

		TASK_MAKE	NULL,introLoop,TASK_MAX_DURATION,0

SeqWaitIntro:
		TASK_MAKE	NULL,initfader12,TASK_MAX_DURATION,0
		TASK_MAKE	NULL,fader,TASK_MAX_DURATION,0
		TASK_MAKE	NULL,initfader23,TASK_MAX_DURATION,0
		TASK_MAKE	NULL,fader,TASK_MAX_DURATION,0
		TASK_MAKE	NULL,initfader32,TASK_MAX_DURATION,0
		TASK_MAKE	NULL,fader,TASK_MAX_DURATION,0
		TASK_MAKE	NULL,initfader21,TASK_MAX_DURATION,0
		TASK_MAKE	NULL,fader,TASK_MAX_DURATION,0

		TASK_MAKE	NULL,NULL,30,0

		TASK_MAKE	NULL,TASK_while,TASK_MAX_DURATION,0

		TASK_MAKE	initfader12,NULL,TASK_MAX_DURATION,0
		TASK_MAKE	fader,NULL,TASK_MAX_DURATION,0
		TASK_MAKE	initfader20,NULL,TASK_MAX_DURATION,0
		TASK_MAKE	fader,NULL,TASK_MAX_DURATION,0

		TASK_MAKE	initRTZScreen,NULL,TASK_MAX_DURATION,0

		TASK_MAKE	NULL,NULL,25,0

		TASK_MAKE	playAudio,NULL,TASK_MAX_DURATION,0
		TASK_MAKE	playOpenRTZ,RTZ_vbl,TASK_MAX_DURATION,0
		TASK_MAKE	playRTZ,RTZ_vbl,TASK_MAX_DURATION,0

		TASK_MAKE	NULL,NULL,TASK_MAX_DURATION,0
SequenceEnd:



;------------------------------
introLoop:
	bsr		initSound

	lea		SeqWaitIntro,a0
	bsr		TASK_do
	TASK_NEXT
	rts  

;------------------------------
TASK_do:
	move.l		a0,TASK_WhilePoint
	move.w		#1,TASK_WhileValue
	rts

;------------------------------
TASK_while:
	tst.w		TASK_WhileValue
	beq.s		.end
	move.l		TASK_WhilePoint,TASK_SeqPtr
	TASK_NEXT
	rts
.end:
	TASK_NEXT
	rts

TASK_WhilePoint:	dc.l	0
TASK_WhileValue:	dc.w	0

;**********************************************************************
;
;		INTRO
;
;**********************************************************************
;-----------------------------------------------

initTitle:
	move.l		backBuf,a0
	bsr		ClearScreenSTEBuffer	; a0: screen buffer

	move.w		#WSCREEN_PLAN_WORDS,d0
	move.w		#HSCREEN,d1
	move.w		#IMG_CENTER,d2		; little bug
	lea		title,a0
	move.l		backBuf,a1
	lea		48*160(a1),a1
	lea		titleXImgStruct,a6
	bsr		IMG_get4Bits		; d0 = dest word width, d1 = dest height, d2 = flag, a0 = image data, a1 = screens destinations, a6: image struct

	WAIT_VBL
;	lea		titleXImgStruct+_IMG_Cmap,a0
	lea		cmapBlack,a0
	bsr		SetColors		; a0 = palette ptr  
	bsr		SwapSTEBuffers

	lea		cmapBlack,a0
	lea		titleXImgStruct+_IMG_Cmap,a1
	lea		cmaps,a2
	move.l		a2,cmapPtrs
	bsr		.setPal

	lea		titleXImgStruct+_IMG_Cmap,a0
	lea		cmapLigth,a1
	lea		cmaps+17*16*2,a2
	move.l		a2,cmapPtrs+4
	bsr		.setPal

	lea		cmapLigth,a0
	lea		cmapWhite,a1
	lea		cmaps+17*16*2*2,a2
	move.l		a2,cmapPtrs+8
	bsr		.setPal

	lea		cmapLigth,a0
	lea		cmapBlack,a1
	lea		cmaps+17*16*2*3,a2
	move.l		a2,cmapPtrs+12
	bsr		.setPal

	TASK_NEXT

	rts

.setPal:
	move.l		a2,-(sp)
	moveq		#16-1,d5
;	lea		cmapBlack,a0
;	lea		titleXImgStruct+_IMG_Cmap,a1
	bsr		InitInnerShading	; d5 = ncolor-1 (must be <= 16), a0 = cmap0, a1 = cmap1 

	move.l		(sp)+,a4
	rept		17
	moveq		#16-1,d5
	bsr		ShadeInner		; d5 = ncolor-1, a4 = dest, unused: d6-d7/a0-a3/a5-a6 
	endr

	rts

;---------------------------------------------------------
initfader01:
	move.w		#17,faderCounter
	move.l		#cmaps,faderCmap
	move.l		#16*2,faderInc
	TASK_NEXT
	rts

initfader12:
	move.w		#17,faderCounter
	move.l		#cmaps+17*16*2,faderCmap
	move.l		#16*2,faderInc
	TASK_NEXT
	rts

initfader23:
	move.w		#17,faderCounter
	move.l		#cmaps+17*16*2*2,faderCmap
	move.l		#16*2,faderInc
	TASK_NEXT
	rts

initfader20:
	move.w		#17,faderCounter
	move.l		#cmaps+17*16*2*3,faderCmap
	move.l		#16*2,faderInc
	TASK_NEXT
	rts

initfader21:
	move.w		#17,faderCounter
	move.l		#cmaps+17*16*2*2-16*2,faderCmap
	move.l		#-16*2,faderInc
	TASK_NEXT
	rts

initfader32:
	move.w		#17,faderCounter
	move.l		#cmaps+17*16*2*3-16*2,faderCmap
	move.l		#-16*2,faderInc
	TASK_NEXT
	rts

;---------------------------------------------------------
fader:
    bsr         updateSound

	subq.w		#1,faderCounter
	bmi.s		.endfade
	move.l		faderCmap,a0
	move.l		a0,a1
	add.l		faderInc,a1
	move.l		a1,faderCmap
;	bsr		SetColors		; a0 = palette ptr 

	lea		$ffff8240.w,a1
	rept		8
	move.l		(a0)+,(a1)+
	endr

	rts
.endfade
	TASK_NEXT
	rts

;---------------------------------------------------------
faderCmap:	dc.l	0		; selected cmapRTZ 
faderInc:	dc.l	0		
faderCounter:	dc.w	0		
cmapPtrs:	ds.l	4	

;**********************************************************************
;
;		ROTO
;
;**********************************************************************

;---------------------------------------------------------
initRTZ:	
	bsr		MakeAdpcm
	bsr		decodeMono
	bsr		makeStereo

	bsr		initRTZ3

	move.w		#160*96,rzTopOfs
	move.w		#0,rzHeight

	lea		font,a0
	bsr		PROPFONT_initFontAndStrings				; A0 = FontDesc data

	lea		text,a0
	lea		textImg,a1
	move.l		#2048,d0
	move.l		#textEnd-text,d1
	moveq		#8-1,d2
	bsr		PROPFONT_print		; A0 = string, A1 = destination, D0 = dest width, D1 = string length, D2 = font height-1, Return D3 = chr count

	clr.w		TASK_WhileValue
	rts

;---------------------------------------------------------
playAudio:
	bsr		AUD_play
	TASK_NEXT
	rts

;---------------------------------------------------------
initRTZScreen:
	move.b		#7,$ffff8800.w
    move.b      sndRegSav,d0
    or.b        #%111111,d0
    move.b      d0,$ffff8802.w    ; switch off all sound & noise channels, restore original PORT values

	bsr		ClearAllScreenSTEBuffer
	lea		cmapRTZ,a0
	bsr		SetColors	; a0 = palette ptr  
	TASK_NEXT
	rts

;---------------------------------------------------------
playRTZ:
;	move.w		#$700,$ffff8240

	move.w		zoomOfs,d0
	and.w		#4095,d0
	lea		cos,a0
	move.w		2(a0,d0.w),d1
	add.w		#4*3,zoomOfs
	asr.w		#5,d1		; -1024,1024
	add.w		#1280,d1
	move.w		d1,d2
	add.w		#256,d1
	lsr.w		#2,d2
	add.w		#64,d2
	movem.w		d1/d2,xyZoom

	subq.l		#2,backBuf

	bsr		PrepareRTZ

 ;	move.w		#$007,$ffff8240
	bsr		DrawRTZ2
	addq.w		#4,alpha
	and.w		#$ffc,alpha

 ;	move.w		#$777,$ffff8240
	bsr		SwapSTEBuffers

	rts

;-----------------------------------------------
RTZ_vbl
	move.l		backBuf,a1
	lea		(HSCREEN-9)*WSCREEN_BYTES(a1),a1

	lea		$ffff8a28.w,a2			; First register needed
	moveq		#-1,d0
	move.l		d0,(a2)+
	move.w		d0,(a2)+
	moveq		#2,d0				; DstXinc.DstYinc
	move.l		d0,(a2)+			; DstXinc.DstYinc
	move.l		a1,(a2)+			; DstPtr
	move.l		#(1<<16)+9*80,(a2)+		; Width.Height
	move.l		#$0000c000,(a2)			; Hop 

	lea		textImg,a0

	lea		160+6(a1),a1

	moveq		#2,d0
	swap		d0
	move.l		#$02030000,d1

	move.w		txtpos,d2
	move.w		d2,d0
	and.w		#$3c,d2
	lsr.w		#6,d0
	add.w		d0,d0
	add.w		d0,a0
	addq.w		#4,txtpos

	move.w		sftInc(pc,d2.w),d0
	move.w		sftInc+2(pc,d2.w),d1

	lea		$ffff8a20.w,a2			; First register needed
	moveq		#-1,d2				; msk
	move.l		d0,(a2)+			; SrcXinc.SrcYinc
	move.l		a0,(a2)+			; SrcPtr
	move.l		d2,(a2)+			; Fmsk.Mmsk
	move.w		d2,(a2)+			; Lmsk
	move.l		#$00080008,(a2)+		; DstXinc.DstYinc
	move.l		a1,(a2)+			; DstPtr
	move.l		#$00140008,(a2)+		; Width.Height
	move.l		d1,(a2)				; Hop 
	rts

txtpos:		dc.w	0
sftInc:		dc.w	2010,$c000,2008,$c08f,2008,$c08e,2008,$c08d,2008,$c08c,2008,$c08b,2008,$c08a,2008,$c089	;	2+2048-40-2
		dc.w	2008,$c088,2008,$c087,2008,$c086,2008,$c085,2008,$c084,2008,$c083,2008,$c082,2008,$c081	;	2+2048-40-2



;	lea		textImg,a0
;	move.l		frontBuf,a1
;	lea		(HSCREEN-8)*WSCREEN_BYTES(a1),a1

;	lea		$ffff8a20.w,a2			; First register needed
;	moveq		#-1,d2				; msk
;	move.l		#$00020002+2048-40-2,(a2)+	; SrcXinc.SrcYinc
;	move.l		a0,(a2)+			; SrcPtr
;	move.l		d2,(a2)+			; Fmsk.Mmsk
;	move.w		d2,(a2)+			; Lmsk
;	move.l		#$00080008,(a2)+		; DstXinc.DstYinc
;	move.l		a1,(a2)+			; DstPtr
;	move.l		#$00140008,(a2)+		; Width.Height
;	move.l		#$0203c08f,(a2)			; Hop 
;	rts

;-----------------------------------------------
playOpenRTZ:
	move.w		rzTopOfs,d0
	sub.w		#160*2,d0
	bmi.s		.next
	move.w		d0,rzTopOfs
	add.w		#2,rzHeight
	bsr		playRTZ
	rts
.next:
	TASK_NEXT
	rts	

;-----------------------------------------------
wt 	= 	128;128
ht 	= 	64;16

;---------------------------------------------------------
initRTZ3:
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

;-----------------------------------------------------------------
SetRaster2:
TEXEL2	macro
		move.w	d5,d7	; iHy.iLy
		move.b	d6,d7	; iHy.iHx
		add.w	d7,d7	; iHy.iHx * 4
		and.w	d0,d7
		add.l	d1,d5	; iLx.00.iHy.iLy += Lx.00.Hy.Ly
		addx.b	d2,d6	; iHx + = Hx
	endm

	movem.l	d0/d3/d4/d6/d7,-(sp)

	moveq	#40-4,d3
	moveq	#wordCount-1,d4
	moveq	#0,d5
	moveq	#0,d6
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

;-----------------------------------------------
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

;-----------------------------------------------
DrawRTZ2:
	lea		LxHLy(pc),a1
	move.b		8(a1),d2	; ??.??.??.Hx
	move.l		(a1),d1		; LxHLy

	bsr		SetRaster2

	move.b		9(a1),d2	; ??.??.??.Hx
	move.l		4(a1),d1	; LxHLy

	lea		texture+32768*2,a6
	move.l		backBuf,a4
	add.w		rzTopOfs,a4
	add.w		#(20-wordCount)*4,a4
	lea		160(a4),a5
;	moveq.		#rowCount-1,d3
	move.w		rzHeight,d3
;	moveq.		#0,d5
;	moveq.		#0,d6
	moveq		#0,d5
	move.w		xyCenter,d5
	lsl.l		#8,d5
	swap		d5
	move.b		d5,d6
	move.w		xyCenter+2,d5
	lea		160+(20-wordCount)*8.w,a5
	move.l		#65536*2,d4

.drtzloop2
	move.w		d5,d7	; iHy.iLy
	move.b		d6,d7	; iHy.iHx
	add.w		d7,d7	; iHy.iHx * 4
	and.w		#$7ffc,d7
	add.l		d1,d5	; iLx.00.iHy.iLy += Lx.00.Hy.Ly
	addx.b		d2,d6	; iHx + = Hx

	lea		(a6,d7.w),a0
	lea		(a0,d4.l),a1
	lea		(a1,d4.l),a2
	lea		(a2,d4.l),a3
	bsr		Rasterize2
	;add.w		#160+(20-wordCount)*8,a4
	add.w		a5,a4
	;add.w		#160+(20-wordCount)*8,a5

	dbra		d3,.drtzloop2

	move.l		backBuf,a0		; SrcPtr
	lea		$ffff8a20.w,a6		; First register needed by us
	move.l		#$80000+168,(a6)+	; SrcXinc.SrcYinc
	move.l		a0,(a6)+		; SrcPtr
	move.l		#-1,(a6)+		; Fmsk.Mmsk
	move.w		#-1,(a6)+		; Lmsk
	move.l		#$80000+168,(a6)+	; DstXinc.DstYinc
	lea		160(a0),a0
	move.l		a0,(a6)+		; DstPtr
	move.l		#(20<<16)!95,(a6)+	; Width.Height
	move.l		#$0203c000,(a6)

	rts

;-----------------------------------------------------------------
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
		addq.l	#6,a4
	endr
	rts

;-----------------------------------------------
alpha:		dc.w	2048+512
zoomOfs:	dc.w	0
xyZoom:		dc.w	256,64
xyCenter:	dc.w	0,0
rzTopOfs:	dc.w	0
rzHeight:	dc.w	0
LxHLy:		dc.l	0,0
Hx:		dc.b	0,0

;**********************************************************************
;
;		AUDIO
;
;**********************************************************************

initSound:
    ; init sound
    lea        $ffff8800,a0
    lea        2(a0),a1
    lea        soundvars,a2

    move.w      #7,(a0)
    move.b      (a0),4(a2)         ; sndRegSav

    move.w     #7,(a2)
    move.w     #0,2(a2)           ; framecnt

    move.b     #0,(a0)            ; channel A freq low
    move.b     #%1000000,(a1)     ; freq low
    move.b     #1,(a0)            ; channel A freq hi
    move.b     #%10011100,(a1)    ; freq hi

    move.b     #11,(a0)           ; volume over time LOW
    move.b     #%1100,(a1)        ; volume over time
    move.b     #12,(a0)           ; volume over time HI
    move.b     #%1,(a1)           ; volume over time

    move.b     #13,(a0)           ; envelope
    move.b     #%1010,(a1)        ; sine

    move.b     #6,(a0)            ; NOISE
    move.b     #100,(a1)

    move.b     #7,(a0)            ; access Yamaha register 7
    move.b     #%111110,(a1)    ; turn on channel A, no noise

    move.b     #8,(a0)            ; channel A volume
    move.b     #0,(a1)

    rts

updateSound:
        lea        soundvars,a2

        ; RAMP UP VOLUME
        move.w     2(a2),d2
        addq.w     #1,d2
        move.w     d2,2(a2)
        lsr.w      #4,d2
        add.w      #4,d2 ; start volume
        cmp.w      #12,d2
        ble.b      noclampvol
        move.w     #12,d2
noclampvol:		  
        move.b     #8,$ffff8800.w            ; channel A volume
        move.b     d2,$ffff8802.w


        move.w     (a2),d0
        addq.w     #1,d0
        move.w     d0,(a2)
        and.w      #31,d0
        move.w     #%110110,d1         ; channel A + noise
        cmp.w      #8,d0
        ble.b      .donoise
        move.b      #%111110,d1       ; clear noise
.donoise
        move.b     #7,$ffff8800.w            ; access Yamaha register 7
        move.b     d1,$ffff8802.w            ; turn on channel A

        rts

;------------------------------------------------------------------------------
; create Diff.Indice table
MakeAdpcm:
		lea		Diffs(pc),a0	; stepSizeTable8bits
		lea		Indices(pc),a1	; shiftedIndexTable
		move.l		#DiffIndices,a2 ; fastStepSizeIndices8bits
		moveq		#0,d0		; index
		moveq		#AUDIO_DIFFS_SIZE-1,d7	; index loop counter
.3:
		moveq		#0,d1
		move.b		(a0)+,d1	; int step = stepSizeTable8bits[index>>4]
		move.w		d1,d2
		add.w		d2,d2		; int dstep = step<<1;
		move.l		a1,a3		; shiftedIndexTable
		moveq		#7,d6		; delta loop counter
.4:
		move.w		d1,d3			; step
		lsr.w		#3,d3			; int vpdiff = step>>3;
		add.w		d2,d1			; step += dstep;

		move.w		d0,d4			; newIndex
		add.w		(a3)+,d4		; newIndex=index+shiftedIndexTable[delta];
		bpl.s		.5			; if (newIndex<0)
		moveq		#0,d4			;	newIndex=0;
		bra.s		.6
.5:
		cmp.w		#(AUDIO_DIFFS_SIZE-1)<<4,d4	;
		ble.s		.6			; else if (newIndex>sstlen)
		move.w		#(AUDIO_DIFFS_SIZE-1)<<4,d4	;	newIndex=sstlen;
.6:
		move.w		d3,(a2)+
		move.w		d4,(a2)+		; fastStepSizeIndices8bits[ofs++] = (vpdiff<<16)|newIndex;
		neg.w		d3
		move.w		d3,28(a2)
		move.w		d4,30(a2)		; fastStepSizeIndices8bits[ofs++] = (-vpdiff<<16)|newIndex;

		dbra		d6,.4

		add.w		#16,d0			; index += 16
		lea		32(a2),a2		; ofs += 8;

		dbra		d7,.3
iapart2:
		move.l		#DiffIndices,a0
		move.l		#DblDiffIndices,a1

		moveq		#0,d0 		; delta1 | delta0
		moveq		#AUDIO_DIFFS_SIZE-1,d2	; 
.1:
		swap		d2		;
		moveq		#15,d6		;
.2:
		moveq		#0,d7		; 00 | 00 | 00 | 00
		move.w		d0,d1		; delta0
		or.w		d2,d1		; ..index0<<4 | delta0
		add.w		d1,d1		; ..index0<<5 | delta0<<1
		add.w		d1,d1		; ..index0<<6 | delta0<<2
		move.l		(a0,d1.w),d1	; vpdiff<<16|newIndex
		swap		d1		; index1<<20 | diff0
	 	move.b		d1,d7		; 00 | 00 | 00 | diff0
		swap		d1		; diff0<<16 | index1<<4

		swap		d0 		; delta0 | delta1
		clr.w		d0		; delta0 | delta1 = 0
		swap		d6
		move.w		#15,d6
.3:
		swap		d7		; 00 | diff0 | 00 | 00
		move.w		d0,d3		; delta1
		or.w		d1,d3		; ..index1<<4 | delta1
		add.w		d3,d3		; ..index1<<5 | delta1<<1
		add.w		d3,d3		; ..index1<<6 | delta1<<2
		move.l		(a0,d3.w),d3	;  vpdiff<<16|newIndex

		lsl.w		#4,d3		; index2<<8
		move.w		d3,d7
		swap		d3
		move.b		d3,d7
		swap		d7		; index2 | diff1 | 00 | diff0
		move.l		d7,(a1)+
		addq.w		#1,d0
		dbf		d6,.3

		swap		d0
		addq.w		#1,d0
		swap		d6
		dbf		d6,.2

		add.w		#16,d2
		swap		d2
		dbf		d2,.1

		rts


Indices:	dc.w		-1<<4, -1<<4, -1<<4, -1<<4, 2<<4, 4<<4, 6<<4, 8<<4
Diffs:		dc.b		8,9,10,11, 12,14,15,17 
		dc.b		19,20,23,25, 27,30,33,37 
		dc.b		40,44,49,54, 59,65,72,79 
		dc.b		87,96,105,116, 127
DiffsEnd:
		even

;-----------------------------------------------
AUDIO_DIFFS_SIZE		=	DiffsEnd-Diffs
AUDIO_DIFF_INDICES_SIZE		=	(AUDIO_DIFFS_SIZE*16)*4	; use only for init, can use scrath memory
AUDIO_DBL_DIFF_INDICES_SIZE	=	(AUDIO_DIFFS_SIZE*256)*4

;-----------------------------------------------
decodeMono:
;		lea		sample,a0
;		move.w		#MUSIC_LENGTH/2-1,d7
;.0
;		clr.l		(a0)+
;		clr.l		(a0)+
;		clr.l		(a0)+
;		clr.l		(a0)+
;		dbra		d7,.0

		lea		music+8,a4
		lea		sample,a5
		lea		DblDiffIndices,a6
		moveq		#0,d1
		moveq		#0,d3
		moveq		#0,d6
		moveq		#0,d7

		move.l		(a4)+,d0
		lsr.l		#3,d0
		subq.w		#1,d0

		;move.w		#MUSIC_LENGTH/4-1,d0
.decloop:
u		set		0
		rept		4

		move.b		(a4)+,d7	; 8  ; ( code0 | code1 )
		add.w		d7,d7		; 4  ; ( code0 | code1 )<<1
		add.w		d7,d7		; 4  ; ( code0 | code1 )<<2
		move.l		(a6,d7.w),d7	; 18 ; index | diff1 | 00 | diff0 

		add.b		d7,d6		; if overflow set carry
		move.b		d6,d1
		ext.w		d1
		add.w		d1,d3
		asr.w		#1,d3
		move.b		d3,u(a5)		; 8					S1
		move.b		d6,u+2(a5)	; 8  ; store value			S2

		swap		d7

		add.b		d7,d6		; if overflow set carry
		move.b		d6,d3
		ext.w		d3
		add.w		d3,d1
		asr.w		#1,d1
		move.b		d1,u+4(a5)	; 8					S1
		move.b		d6,u+6(a5)	; 8  ; store value			S2

u		set		u+8
		endr
		lea		32(a5),a5
		dbra		d0,.decloop

		move.l		a5,endSamplePtr
		rts

endSamplePtr:	dc.l		0

;-----------------------------------------------
makeStereo:
		move.l		endSamplePtr,a5
		lea		-256*2(a5),a0
		lea		sample,a1
		move.w		#256/4-1,d7
.topstereo
		movep.l		0(a0),d0
		movep.l		d0,1(a1)
		addq.l		#8,a0
		addq.l		#8,a1
		dbra		d7,.topstereo

		lea		sample,a0

		move.l		music+8,d7
		lsr.l		#2,d7
		sub.w		#256/4+1,d7

		;move.w		#(MUSIC_LENGTH)/2-256/4-1,d7
.remstereo
		movep.l		0(a0),d0
		movep.l		d0,1(a1)
		movep.l		8+0(a0),d0
		movep.l		d0,8+1(a1)
		lea		16(a0),a0
		lea		16(a1),a1
		dbra		d7,.remstereo

		rts

;------------------------------------------------------------------
AUD_play:
		lea		$ffff8900.w,a0
		clr.b		1(a0)

		lea		$22(a0),a1
		lea		$24(a0),a2
		move.w		#%11111111111,d0
		move.w		d0,(a2)
		move.w		#%10000000001,(a1)		; set mix
.0:		cmp.w		(a2),d0
		bne.s		.0
		move.w		#%10011101000,(a1)		; master volume
.1:		cmp.w		(a2),d0
		bne.s		.1
		move.w		#%10101010100,(a1)		; left channel volume
.2:		cmp.w		(a2),d0
		bne.s		.2
		move.w		#%10100010100,(a1)		; right channel volume
.3:		cmp.w		(a2),d0
		bne.s		.3

		move.l		#sample,d0
		move.l		endSamplePtr,d1

		movep.w		d0,5(a0)
		swap		d0
		move.b		d0,3(a0)
		movep.w		d1,$11(a0)
		swap		d1
		move.b		d1,$f(a0)

		move.b		#1,$21(a0) 		; freq, mono/stereo
		move.b		#3,1(a0)
		rts

;-----------------------------------------------
AUD_stop:
		clr.b		$ffff8901.w
		rts

;-----------------------------------------------
                section data

cmapRTZ:	dc.w	0,$111,$222,$333,$444,$555,$666,$777,$888,$999,$aaa,$bbb,$ccc,$ddd,$eee,$fff
;cmapRTZ:	dc.w	000,$fff,$eee,$ddd,$ccc,$bbb,$aaa,$999,$888,$777,$666,$555,$444,$333,$222,$111
cmapBlack:	dc.w	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
cmapWhite:	dc.w	$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff
cmapLigth:	dc.w	$300,$410,$520,$630,$740,$852,$974,$a96,$aa8,$bb9,$cca,$eeb,$ffc,$ffd,$ffe,$fff

font:		incbin	"data/rtz.pft"
rzimg:		incbin	"data/rzimg.dta"
title		incbin	"data/title.img"
music:		incbin	"data/music.xdp"
musicend:

MUSIC_LENGTH	=	musicend-music

text:			dc.b	""
			dc.b	"LADY MACBETH They met me in the day of success: and I have "
			dc.b	"learned by the perfectest report, they have more in "
			dc.b	"them than mortal knowledge. When I burned in desire "
			dc.b	"to question them further, they made themselves air, "
			dc.b	"into which they vanished. Whiles I stood rapt in "
			dc.b	"the wonder of it, came missives from the king, who "
			dc.b	"all-hailed me 'Thane of Cawdor' by which title, "
			dc.b	"before, these weird sisters saluted me, and referred "
			dc.b	"me to the coming on of time, with 'Hail, king that "
			dc.b	"shalt be!' This have I thought good to deliver "
			dc.b	"thee, my dearest partner of greatness, that thou "
			dc.b	"mightst not lose the dues of rejoicing, by being "
			dc.b	"ignorant of what greatness is promised thee. Lay it "
			dc.b	"to thy heart, and farewell. "
			dc.b	"Glamis thou art, and Cawdor; and shalt be "
			dc.b	"What thou art promised: yet do I fear thy nature; "
			dc.b	"It is too full o' the milk of human kindness "
			dc.b	"To catch the nearest way:  thou wouldst be great; "
			dc.b	"Art not without ambition, but without "
			dc.b	"The illness should attend it: what thou wouldst highly, "
			dc.b	"That wouldst thou holily; wouldst not play false, "
			dc.b	"And yet wouldst wrongly win: thou'ldst have, great Glamis, "
			dc.b	"That which cries 'Thus thou must do, if thou have it; "
			dc.b	"And that which rather thou dost fear to do "
			dc.b	"Than wishest should be undone.' Hie thee hither, "
			dc.b	"That I may pour my spirits in thine ear; "
			dc.b	"And chastise with the valour of my tongue "
			dc.b	"All that impedes thee from the golden round, "
			dc.b	"Which fate and metaphysical aid doth seem "
			dc.b	"To have thee crown'd withal. "
textEnd:		even

;---------------------------------------------------------
                section bss
                even
soundvars:
noise     ds.w       1
framecnt  ds.w       1
sndRegSav ds.w       1 

textImg:		ds.b	2048*8

cmaps:			ds.w	16*17*4

titleXImgStruct:	ds.b	IMG_Struct_Size

DiffIndices:		ds.b	AUDIO_DIFF_INDICES_SIZE
DblDiffIndices:		ds.b	AUDIO_DBL_DIFF_INDICES_SIZE

sin:			ds.b	1024*2
cos:			ds.b	1024*4
			ds.b	32768
buffers:		ds.b	65536
texture:		ds.b	65536*8
sample:			ds.b	MUSIC_LENGTH*8
endsample:	


	end