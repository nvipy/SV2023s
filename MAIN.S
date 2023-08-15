	section	text



	bra	run

	include		"INCLUDES/BIOS.I"
	include		"INCLUDES/SYS.I"
	include		"INCLUDES/MATH.I"
	include		"INCLUDES/IMG.I"
	include		"INCLUDES/TASKMAN.I"
	include		"INCLUDES/PROPFONT.I"
 	include		"SOUND.S"

run:

	dc.l		$a000a00a              ;Mouse off
	bsr		SetSuper
	bsr		StopMFP
	bsr		SaveScreen

	move.l		#buffers,d0
	move.l		#WSCREEN_BYTES*8,d1
	bsr		SetSTEBuffers
	
	bsr		SwapSTEBuffers

	moveq		#40,d0
	bsr		AUD_setVolume

	lea		Sequence,a0
	lea		SequenceEnd,a1
	bsr		TASK_initSequence	;A0: SequencePtr, A1: end of SequencePtr Set TASK_SeqIsRunning to 1
	
	lea		Vbl,a0
	bsr		SetVbl

mainloop:

	WAIT_VBL
	TASK_CALL	_TASK_Main		; Task call macro, /1: _TASK_Main or _TASK_Vbl, return -1 if seq finished

	cmp.b		#$39,$fffc02
	bne.s		mainloop

	bsr		AUD_stop

	bsr		ResetVbl
	move.w 		#$700,$ffff8240.w

	bsr		BIOS_WaitVbl
	bsr		RestoreScreen
	move.w 		#$7,$ffff8240.w
	bsr		BIOS_WaitVbl
	bsr		RestoreMFP
	move.w 		#$fff,$ffff8240.w
	bsr		BIOS_WaitVbl
	bsr		SetUser
	dc.l		$a000a009               ;Mouse on
	bsr		BIOS_WaitVbl
	clr.l		-(a7)
	trap		#1

;-----------------------------------------------
Vbl:
	movem.l		d0-d7/a0-a6,-(sp)
	bsr		TASK_runSequence	; Clear TASK_SeqIsRunning when sequence is finished
	TASK_CALL	_TASK_Vbl		; Task call macro, /1: _TASK_Main or _TASK_Vbl, return -1 if seq finished
	movem.l		(sp)+,d0-d7/a0-a6
	rte				



;-----------------------------------------------
Sequence:
		TASK_MAKE	initTitle,NULL,TASK_MAX_DURATION,0
		;TASK_MAKE	initRTZ,initfader01,TASK_MAX_DURATION,0
		TASK_MAKE	initAll,initfader01,TASK_MAX_DURATION,0

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

		TASK_MAKE	deadTime,initfader12,TASK_MAX_DURATION,0
		TASK_MAKE	deadTime,fader,TASK_MAX_DURATION,0
		TASK_MAKE	deadTime,initfader20,TASK_MAX_DURATION,0
		TASK_MAKE	deadTime,fader,TASK_MAX_DURATION,0

		TASK_MAKE	initRTZScreen,NULL,TASK_MAX_DURATION,0

		TASK_MAKE	deadTime,NULL,50,0

		TASK_MAKE	deadTime,playAudio,TASK_MAX_DURATION,0
		TASK_MAKE	playOpenRTZ,RTZ_vbl,TASK_MAX_DURATION,0
		TASK_MAKE	playRTZ,RTZ_vbl,25*100,0
		TASK_MAKE	playCloseRTZ,RTZ_vbl,TASK_MAX_DURATION,0

		TASK_MAKE	END_iter,NULL,TASK_MAX_DURATION,0
		TASK_MAKE	END_play,NULL,TASK_MAX_DURATION,0
		TASK_MAKE	END_initLogo,NULL,TASK_MAX_DURATION,0
		TASK_MAKE	END_playLogo,NULL,TASK_MAX_DURATION,0

		TASK_MAKE	NULL,endLoop,TASK_MAX_DURATION,0
SeqWaitEnd:
		TASK_MAKE	END_setLightLogo,NULL,TASK_MAX_DURATION,0
		TASK_MAKE	END_playLogo,NULL,TASK_MAX_DURATION,0
		TASK_MAKE	END_setDarkLogo,NULL,TASK_MAX_DURATION,0
		TASK_MAKE	END_playLogo,NULL,TASK_MAX_DURATION,0

		TASK_MAKE	NULL,TASK_while,TASK_MAX_DURATION,0

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
endLoop:
	lea		SeqWaitEnd,a0
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
;vv:
	TASK_NEXT
	rts

TASK_WhilePoint:	dc.l	0
TASK_WhileValue:	dc.w	0

;-----------------------------------------------
initAll:
	bsr		END_init
	bsr		initRTZ
uu:
	clr.w		TASK_WhileValue
	rts

;-----------------------------------------------
deadTime:
;	BGC		$000
	rept		9
;	addq.w		#1,$ffff8240.w
	bsr		END_calcIterDot
	endr
;	BGC		$0f0
	rts

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
	bsr		updateSound

	subq.w		#1,faderCounter
	bmi.s		.endfade
	move.l		faderCmap,a0
	move.l		a0,a1
	add.l		faderInc,a1
	move.l		a1,faderCmap

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
	lea		sin,a0
	moveq		#10,d0
	move.l		#$8000,d1
	bsr		MATH_makeSins	; A0 = destination, sinus word array ptr, D0 = destination depth (length = 2^depth), D1 = phase [-32768,32768[ : [-PI/2,PI/2[, use -32768 for Sinus, use 0 for Cosinus

	bsr		MakeAdpcm
	bsr		decodeMono
	bsr		makeStereo

	bsr		initRTZ3

	move.w		#160*96,rzTopOfs
	clr.w		rzHeight

	lea		font,a0
	bsr		PROPFONT_initFontAndStrings				; A0 = FontDesc data

	lea		text,a0
	lea		textImg,a1
	move.l		#2048,d0
	move.l		#textEnd-text,d1
	moveq		#8-1,d2
	bsr		PROPFONT_print		; A0 = string, A1 = destination, D0 = dest width, D1 = string length, D2 = font height-1, Return D3 = chr count

	move.w		#36*20,RasterizeRtsOfs
	move.w		#160+(20-wordCount)*8,RasterizeMod
	move.w		#0,RasterizeScrOfs

	move.w		#(HSCREEN-9)*WSCREEN_BYTES,YClr
	move.w		#(HSCREEN-9)*WSCREEN_BYTES,YScroll

	move.w		#480-1,d7
.iter:
;	addq.w		#1,$ffff8240.w
	bsr		END_calcIterDot
	tst.w		END_Dot
	bne.s		.enditer
	dbra		d7,.iter
.enditer	
;	BGC		$f00


	rts


;---------------------------------------------------------
playAudio:
	bsr		AUD_play
	moveq		#40,d0
	bsr		AUD_setVolume

	TASK_NEXT
	rts

;---------------------------------------------------------
initRTZScreen:
	move.b		#7,$ffff8800.w
	moveq		#%111111,d0
	or.b		sndRegSav,d0
	move.b		d0,$ffff8802.w    ; switch off all sound & noise channels, restore original PORT values

	bsr		ClearAllScreenSTEBuffer
	lea		cmapRTZ,a0
	bsr		SetColors	; a0 = palette ptr  

	moveq		#40,d0
	moveq		#0,d1
	move.w		#256,d2
	bsr		AUD_setFadeVol	; d0 = start, d1 = end [0..40], d2 = step

	TASK_NEXT
	rts

;-----------------------------------------------
playOpenRTZ:
	move.w		rzTopOfs,d0
	sub.w		#160*2,d0
	bmi.s		.next
	move.w		d0,rzTopOfs
	add.w		#2,rzHeight
	bsr.s		playRTZ
	rts
.next:
	TASK_NEXT
	rts	

;---------------------------------------------------------
playRTZ:
	BGC		$000

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

	bsr		DrawRTZ2
	addq.w		#4,alpha
	and.w		#$ffc,alpha


	;BGC		$f00
.wait2vbl:
;	addq.w		#1,$ffff8240.w
	bsr		END_calcIterDot

	move.w		VblStrobe,d0
	subq.w		#2,d0
	bmi.s		.wait2vbl

	bsr		SwapSTEBuffers

	;BGC		$0f0
	bsr		END_calcIterDot
	;BGC		$000

	rts


;-----------------------------------------------
playCloseRTZ:
	bsr		AUD_fadeVol

	sub.w		#1,rzHeight

	move.w		YScroll,d0
	move.w		d0,YClr
	sub.w		#WSCREEN_BYTES*2,d0
	move.w		d0,YScroll
	add.w		#9*WSCREEN_BYTES,d0
	beq.s		.next

	bsr		playRTZ

	rts
.next:
	moveq		#0,d0
	bsr		AUD_setVolume
	bsr		playRTZ
	TASK_NEXT
	rts	

RasterizeRtsOfs:	dc.w	0
RasterizeMod:		dc.w	0
RasterizeScrOfs:	dc.w	0
YClr:			dc.w	0
YScroll:		dc.w	0

;-----------------------------------------------
RTZ_vbl
	move.l		frontBuf,a1
	move.l		a1,a3
	add.w		YClr,a1

	lea		$ffff8a28.w,a2			; First register needed
	moveq		#-1,d0
	move.l		d0,(a2)+
	move.w		d0,(a2)+
	moveq		#2,d0				; DstXinc.DstYinc
	move.l		d0,(a2)+			; DstXinc.DstYinc
	move.l		a1,(a2)+			; DstPtr
	move.l		#(1<<16)+12*80,(a2)+		; Width.Height
	move.l		#$0000c000,(a2)			; Hop 

	lea		textImg,a0

	add.w		YScroll,a3
	lea		160+6(a3),a3

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
	move.l		a3,(a2)+			; DstPtr
	move.l		#$00140008,(a2)+		; Width.Height
	move.l		d1,(a2)				; Hop 
	rts

txtpos:		dc.w	0
sftInc:		dc.w	2010,$c000,2008,$c08f,2008,$c08e,2008,$c08d,2008,$c08c,2008,$c08b,2008,$c08a,2008,$c089	;	2+2048-40-2
		dc.w	2008,$c088,2008,$c087,2008,$c086,2008,$c085,2008,$c084,2008,$c083,2008,$c082,2008,$c081	;	2+2048-40-2

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
	add.w		RasterizeScrOfs,a4
	add.w		#(20-wordCount)*4,a4
	lea		160(a4),a5
;	moveq.		#rowCount-1,d3
	move.w		RasterizeMod,a5
	move.w		rzHeight,d3
	bpl.s		.draw
	rts
.draw:
	moveq		#0,d5
	move.w		xyCenter,d5
	lsl.l		#8,d5
	swap		d5
	move.b		d5,d6
	move.w		xyCenter+2,d5
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
	bsr.s		Rasterize2
	add.w		a5,a4

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
;		ENDING
;
;**********************************************************************

;-----------------------------------------------
END_FRAME_COUNT	=	128
END_IMG_WIDTH	=	192
END_IMG_HEIGHT	=	80

;-----------------------------------------------
END_initLogo:

	lea		END_Frames,a0
	bsr		ClearScreenSTEBuffer

	move.w		#WSCREEN_PLAN_WORDS,d0
	move.w		#HSCREEN,d1
	move.w		#IMG_CENTER,d2		; little bug
	lea		END_Logo,a0
	lea		END_Frames,a1
	lea		45*160(a1),a1
	lea		END_LogoXImgStruct,a6
	bsr		IMG_get4Bits		; d0 = dest word width, d1 = dest height, d2 = flag, a0 = image data, a1 = screens destinations, a6: image struct

	move.l		#END_Frames,d0
	bsr		SetScreenAdrsSTE	;D0 = screen adrs

	WAIT_VBL

	lea		cmapBaseLogo,a0
	bsr		SetColors

	moveq		#0,d0
	lea		cmapBaseLogo,a0
	lea		cmapLogo,a1
	bsr		InitPalShading		; d0:speed, a0:srcpal, a1:destpal
	;ShadePal:		; a4 = dest,  Return d0: d0=0 continue, d0=-1 end

	TASK_NEXT

	rts

;-----------------------------------------------
END_playLogo:
	lea		$ffff8240.w,a4
	bsr		ShadePal		; a4 = dest,  Return d0: d0=0 continue, d0=-1 end
	tst.w		d0
	beq.s		.next
	TASK_NEXT
.next
	rts

;-----------------------------------------------
END_setLightLogo:
	moveq		#2,d0
	lea		cmapLogo,a0
	lea		cmaplightLogo,a1
	bsr		InitPalShading		; d0:speed, a0:srcpal, a1:destpal
	TASK_NEXT
	rts

;-----------------------------------------------
END_setDarkLogo:
	moveq		#2,d0
	lea		cmaplightLogo,a0
	lea		cmapLogo,a1
	bsr		InitPalShading		; d0:speed, a0:srcpal, a1:destpal
	TASK_NEXT
	rts
	

;-----------------------------------------------
cmapBaseLogo:	dc.w	0,0,0,0,0,$fff,$fff,$fff
cmapLogo:	dc.w	0,$222,$444,$666,$888,$aaa,$ccc,$eee
cmaplightLogo:	dc.w	$002,$77a,$99b,$bbc,$ccd,$dde,$eef,$fff


;-----------------------------------------------
END_iter:
	lea		cmapBlack,a0
	bsr		SetColors
;uu:
.iter:
	;addq.w		#1,$ffff8240.w
	bsr		END_calcIterDot
	tst.w		END_Dot
	beq.s		.iter
	bsr		END_cleanFrames

	move.l		#buffers,d0
	move.l		#WSCREEN_BYTES*8,d1
	bsr		SetSTEBuffers

	move.l		backBuf,a0
	bsr		ClearScreenSTEBuffer
	move.l		frontBuf,a0
	bsr		ClearScreenSTEBuffer

	lea		END_Frames,a0
	bsr		END_draw		; a0 = buffer
	bsr		SwapSTEBuffers
	lea		END_Frames,a0
	bsr		END_draw		; a0 = buffer
	bsr		SwapSTEBuffers


	WAIT_VBL
	lea		cmapRTZ,a0
	bsr		SetColors

	TASK_NEXT

	rts

;-----------------------------------------------
END_init:
	bsr		END_initCosSin
	bsr		END_createPoints

	lea		END_RowsOfs,a0
	lea		END_Wxs,a1
	move.w		#HSCREEN-1,d0
	move.w		#WSCREEN,d1
	move.w		#HSCREEN,d2
	move.w		#WSCREEN,d3
	moveq		#$2,d5
	bsr		STD_initPlot	; A0 = rows, A1 = wxs, D0 = rowcount-1, D1 = width, D2 = row overflow, D3 = width overflow, D5 = ganularity between horz words

	bsr		END_initPlay

	bsr		END_initIterDot

	rts

;-----------------------------------------------
END_initPlay:
	lea		END_Frames,a0
	lea		END_FramePtrs,a1
	moveq		#END_FRAME_COUNT-1-1,d7
.frmloop:
	move.l		a0,(a1)+
	lea		40*HSCREEN(a0),a0
	dbra		d7,.frmloop
	rept		8
	move.l		a0,(a1)+
	endr
	clr.l		(a1)

	move.l		#END_FramePtrs,END_FramePtr

	rts

END_FramePtr:	dc.l	0
END_FramePtrs:	ds.l	END_FRAME_COUNT+16

;-----------------------------------------------
END_play:
;uu:	;BGC		-1

	WAIT_VBL
;	addq.w		#1,$ffff8240.w
	move.l		END_FramePtr,a1
	move.l		(a1)+,a0
	move.l		a0,d0
	bne.s		.next
	TASK_NEXT
	rts
.next:
	move.l		a1,END_FramePtr
	subq.l		#2,backBuf
	bsr		END_draw
	bsr		SwapSTEBuffers
	rts

;-----------------------------------------------
END_draw:		; a0 = buffer
	lea		$ffff8a20.w,a6		; First register needed by us
	move.l		#$20002,(a6)+		; SrcXinc.SrcYinc
	move.l		a0,(a6)+		; SrcPtr
	moveq		#-1,d0
	move.l		d0,(a6)+		; Fmsk.Mmsk
	move.w		d0,(a6)+		; Lmsk
	move.l		#$80008,(a6)+		; DstXinc.DstYinc
	move.l		backBuf,(a6)+		; DstPtr
	move.l		#(20<<16)!200,(a6)+	; Width.Height
	move.l		#$0203c000,(a6)
	rts

;-----------------------------------------------
			rsreset
_END_DotIsEmpty:	rs.w	1
_END_DotAlpha:		rs.w	1
_END_DotPointPtr:	rs.l	1
_END_Dot_StructSize:	rs.b	0

END_PointCount:		dc.w	0
END_Dot:		ds.b	_END_Dot_StructSize

;-----------------------------------------------
END_initIterDot:	; a6 = DotStruct
	lea		END_Dot,a6
	clr.w		(a6)+
	clr.w		(a6)+
	move.l		#END_Points,(a6)+
	rts

;-----------------------------------------------
END_calcIterDot:	; a6 = DotStruct
	lea		END_Dot,a6
	tst.w		(a6)+
	beq.s		.next
	rts
.next:
	move.w		(a6),d2
	subq.w		#4,(a6)+
	move.l		(a6),a5
	movem.w		(a5)+,d0-d1
	move.l		a5,(a6)+

	lea		END_Frames+HSCREEN*40*(END_FRAME_COUNT-1),a0
	lea		END_Wxs+WSCREEN*4,a1
	lea		END_RowsOfs+HSCREEN*2,a2
	lea		4*256.w,a3
	lea		-HSCREEN*40,a4
	lea		sins,a6
	move.w		#$3fc,d6

	;BGC		$0f0
	rept		END_FRAME_COUNT
	and.w		d6,d2		; alpha [0..510]
	movem.w		(a6,d2.w),d4-d5	; x += sins[alpha]
	add.w		d0,d4
	add.w		d1,d5
	movem.w		(a1,d4.w),d3-d4	; col_ofs, mask
	add.w		(a2,d5.w),d3	; col_ofs += row_ofs
	or.w		d4,(a0,d3.w)	; 
	add.l		a3,a6
	add.l		a4,a0
	addq.w		#8,d2		; alpha+=2
	endr
	;BGC		$f00

	subq.w		#1,END_PointCount
	bgt.s		.loop
	subq.w		#1,END_Dot
.loop:
	rts

;-----------------------------------------------
END_cleanFrames:
	lea		END_Frames,a0
	moveq		#END_FRAME_COUNT-1,d7
.frmloop:	
	rept		10
	clr.l		(a0)+
	endr
	lea		(HSCREEN-1)*40(a0),a0
	dbra		d7,.frmloop
	rts

;-----------------------------------------------
END_initCosSin:
	lea		sin,a0
	moveq		#10,d0
	move.l		#$8000,d1
	bsr		MATH_makeSins	; A0 = destination, sinus word array ptr, D0 = destination depth (length = 2^depth), D1 = phase [-32768,32768[ : [-PI/2,PI/2[, use -32768 for Sinus, use 0 for Cosinus

	lea		sin,a0
	move.w		#$fff,d1	; change when change END_FRAME_COUNT
	move.w		#1024-1,d7
.crt:
	move.w		(a0),d0
	muls		d1,d0
	swap		d0
	move.w		d0,(a0)+
	dbra		d7,.crt

	lea		sin,a0
	lea		sins,a1
	move.w		#256-1,d7
.sin:
	moveq		#0,d0
	move.w		(a0,d3.w),d1	

	move.l		a1,a2
	moveq		#END_FRAME_COUNT-1,d6
.scl:
	move.w		d0,d2
	asr.w		#6,d2
	and.w		#$fffc,d2
	move.w		d2,(a2)
	add.w		d1,d0
	lea		4*256(a2),a2
	dbra		d6,.scl

	add.w		#12,d3
	and.w		#$7fe,d3

	addq.l		#4,a1
	dbra		d7,.sin

	lea		sins,a1
	moveq		#END_FRAME_COUNT-1,d7
.cos:
	lea		4*64(a1),a2
	lea		2(a1),a3
	move.w		#256-64-1,d6
.cpy0:
	move.w		(a2),d0
	asr.w		#1,d0
	move.w		d0,(a3)
	addq.l		#4,a2
	addq.l		#4,a3
	dbra		d6,.cpy0

	move.l		a1,a2
	move.w		#64-1,d6
.cpy1:
	move.w		(a2),d0
	asr.w		#1,d0
	move.w		d0,(a3)
	addq.l		#4,a2
	addq.l		#4,a3
	dbra		d6,.cpy1

	lea		4*256(a1),a1
	dbra		d7,.cos


	rts

;-----------------------------------------------
END_createPoints:
	lea		END_Logo+IMG_HStruct_Size+8*2,a0
	lea		END_Points,a1
	move.l		#(((HSCREEN-END_IMG_HEIGHT)/2)<<17)!(((WSCREEN-END_IMG_WIDTH)/2)*4),d5
	move.w		#END_IMG_HEIGHT-1,d7
.yloop:
	move.w		#END_IMG_WIDTH/2-1,d6
.xloop:
	move.b		(a0)+,d0
	moveq		#$fffffff0,d1
	and.b		d0,d1
	cmp.b		#$40,d1
	ble.s		.noleftpt
	swap		d5
	move.l		d5,(a1)+
	swap		d5
.noleftpt:
	addq.w		#4,d5
	and.b		#$0f,d0
	cmp.b		#$04,d0
	ble.s		.norightpt
	swap		d5
	move.l		d5,(a1)+
	swap		d5
.norightpt:
	addq.w		#4,d5
	dbra		d6,.xloop

	move.w		#((WSCREEN-END_IMG_WIDTH)/2)*4,d5
	add.l		#$20000,d5

	dbra		d7,.yloop
	sub.l		#END_Points,a1
	move.w		a1,d0
	lsr.w		#2,d0
	move.w		d0,END_PointCount
	rts

;------------------------------------------------------------------
STD_initPlot:		; A0 = rows, A1 = wxs, D0 = rowcount-1, D1 = width, D2 = row overflow, D3 = width overflow, D5 = ganularity between horz words
	swap		d5
	clr.w		d5

	add.w		d2,d2		; 2 * row overflow
	move.l		a0,a2
	lea		(a2,d2.w),a0
	add.w		d0,d2		; 2 * row overflow + rowcount-1
.rowclr:
	clr.w		(a2)+
	dbra		d2,.rowclr

	add.w		d3,d3		; 2 * width overflow
	move.w		d3,d4
	add.w		d4,d4		; 4 * width overflow
	move.l		a1,a2
	lea		(a2,d4.w),a1
	add.w		d1,d3		; 2 * width overflow + width
	subq.w		#1,d3
.wxsclr:
	clr.l		(a2)+
	dbra		d3,.wxsclr

	lsr.w		#3,d1		; width/8
	move.w		d1,d3		

	moveq		#0,d2
.rowloop:
	move.w		d2,(a0)+
	add.w		d1,d2
	dbra		d0,.rowloop

	lsr.w		#1,d3		; width/16
	subq.w		#1,d3

	move.l		#$8000,d0
.wordloop:
	moveq		#16-1,d7
.bitloop:
	move.l		d0,(a1)+	; xword.msk
	ror.w		#1,d0
	dbra		d7,.bitloop
	add.l		d5,d0
	dbra		d3,.wordloop
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
AUD_setVolume:	; d0 = volume [0..40]
		lea		$ffff8900.w,a0
		lea		$22(a0),a1
		lea		$24(a0),a2
		move.w		#%11111111111,d2
		move.w		d2,(a2)
		move.w		#%10011000000,d1
		or.b		d0,d1
		move.w		d1,(a1)				; master volume
.1:		cmp.w		(a2),d2
		bne.s		.1
		rts
;------------------------------------------------------------------
AUD_setFadeVol:	; d0 = start, d1 = end [0..40], d2 = step
		lsl.w		#8,d0
		lsl.w		#8,d1
		sub.w		d0,d1
		ext.l		d1
		divs		d2,d1
		movem.w		d0-d2,AUD_Volume
		rts

;------------------------------------------------------------------
AUD_fadeVol:
		lea		AUD_Volume,a0
		move.w		4(a0),d0
		dbra		d0,.setvol
		moveq		#-1,d0
		rts
.setvol:
		move.w		d0,4(a0)
		move.w		(a0)+,d1
		move.w		d1,d0
		add.w		(a0),d1
		move.w		d1,-(a0)
		lsr.w		#8,d0
		bsr.s		AUD_setVolume
		moveq		#0,d0
		rts

AUD_Volume:	dc.w		0,0,0	; cur, inc, step

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
		move.w		#%10011000000,(a1)		; master volume, max = #%10011101000
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
cmapBlack:	dc.w	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
cmapWhite:	dc.w	$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff
cmapLigth:	dc.w	$300,$410,$520,$630,$740,$852,$974,$a96,$aa8,$bb9,$cca,$eeb,$ffc,$ffd,$ffe,$fff

END_Logo:	incbin	"data/ngc.img"
title		incbin	"data/title.img"
music:		incbin	"data/music.xdp"
font:		incbin	"data/rtz.pft"
rzimg:		incbin	"data/rzimg.dta"

musicend:

MUSIC_LENGTH	=	musicend-music

text:			dc.b	""
			dc.b	"                                                             "
			dc.b	"NGC salutes the Atari community with this little compo filler. "
			dc.b	"Code and GFX by Viper - Original music by Jester of Sanity "
			dc.b	"(tortured to elevator jazz by Soundy). "
			dc.b	"Greets to: Leonard, MajorX, Gadget, Dan, Dascon, Virgill, "
			dc.b	"Facet, Erk, Made, Prowler, NoRecess, Merry, Platon42, Rez, Ok3nos, "
			dc.b	"ntsc_, hugs go to TRSI, we'll miss Spotter"
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


soundvars: ds.b       sndStruct_len


textImg:		ds.b	2048*8

cmaps:			ds.w	16*17*4

titleXImgStruct:	ds.b	IMG_Struct_Size

DiffIndices:		ds.b	AUDIO_DIFF_INDICES_SIZE
DblDiffIndices:		ds.b	AUDIO_DBL_DIFF_INDICES_SIZE

sin:			ds.b	1024*2
cos:			ds.b	1024*4
			ds.b	2*50*120
buffers:		ds.b	WSCREEN_BYTES*(HSCREEN*2+64)
texture:		ds.b	65536*8
sample:			ds.b	MUSIC_LENGTH*8
endsample:	
			ds.b	16384
;sin:
END_Wxs:		ds.l	WSCREEN*3
END_RowsOfs:		ds.w	HSCREEN*3

sins:			ds.b	4*256*END_FRAME_COUNT

END_LogoXImgStruct:	ds.b	IMG_Struct_Size
END_Points:		ds.l	END_IMG_WIDTH*END_IMG_HEIGHT

END_Frames:		ds.b	40*200*END_FRAME_COUNT

	end