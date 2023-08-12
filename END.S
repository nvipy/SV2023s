
	section	text

	bra	run

	include		"INCLUDES/BIOS.I"
	include		"INCLUDES/SYS.I"
	include		"INCLUDES/MATH.I"
	include		"INCLUDES/IMG.I"
 
run:

	dc.l		$a000a00a              ;Mouse off
	bsr		SetSuper
	;bsr		StopMFP
	bsr		SaveScreen
	
	move.l		#buffers,d0
	moveq		#0,d1
	bsr		SetSTEBuffers
;	bsr		ClearAllScreenSTEBuffer
	
	bsr		SwapSTEBuffers

	lea		END_RowsOfs,a0
	lea		END_Wxs,a1
	move.w		#HSCREEN-1,d0
	move.w		#WSCREEN,d1
	move.w		#HSCREEN,d2
	move.w		#WSCREEN,d3
	moveq		#$2,d5
	bsr		STD_initPlot	; A0 = rows, A1 = wxs, D0 = rowcount-1, D1 = width, D2 = row overflow, D3 = width overflow, D5 = ganularity between horz words

	bsr		END_init
	bsr		END_calcAllDots
	lea		frames+HSCREEN*40,a0
	;bsr		END_draw

	;bsr		SwapSTEBuffers

	lea		$ffff8240.w,a0
	move.l		#$fff,(a0)+
	rept		7
	move.l		#-1,(a0)+
	endr

	lea		Vbl,a0
	bsr		SetVbl
	
	move.w		#1,VblStrobe
mainloop:	
	tst.w		VblStrobe
	bpl.s		mainloop
	move.w		#1,VblStrobe

;	bsr		STD_waitVBL
	bsr		END_play

	cmp.b		#$39,$fffffc02.w
	bne		mainloop

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
	subq.w		#1,VblStrobe
	rte	

VblStrobe	dc.w	0
;-----------------------------------------------
END_FRAME_COUNT	=	64
END_IMG_WIDTH	=	192
END_IMG_HEIGHT	=	80

;-----------------------------------------------
END_init:
	lea		sin,a0
	moveq		#10,d0
	move.l		#$8000,d1
	bsr		MATH_makeSins	; A0 = destination, sinus word array ptr, D0 = destination depth (length = 2^depth), D1 = phase [-32768,32768[ : [-PI/2,PI/2[, use -32768 for Sinus, use 0 for Cosinus

	lea		sin,a0
	move.w		#$3fff,d1
	move.w		#1024-1,d7
.crt:
	move.w		(a0),d0
	muls		d1,d0
	swap		d0
	move.w		d0,(a0)+
	dbra		d7,.crt

uu:
	lea		sin,a0
	lea		sins,a1
	move.w		#256-1,d7
.sin:
	moveq		#0,d0
	move.w		(a0),d1	
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

	addq.w		#8,a0
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

	move.l		#frames,END_CurFrame
	rts

;-----------------------------------------------
END_init2:
	lea		sin,a0
	moveq		#10,d0
	move.l		#$8000,d1
	bsr		MATH_makeSins	; A0 = destination, sinus word array ptr, D0 = destination depth (length = 2^depth), D1 = phase [-32768,32768[ : [-PI/2,PI/2[, use -32768 for Sinus, use 0 for Cosinus

	lea		sin,a0
	move.w		#$3fff,d1
	move.w		#1024-1,d7
.crt:
	move.w		(a0),d0
	muls		d1,d0
	swap		d0
	move.w		d0,(a0)+
	dbra		d7,.crt

	lea		sin,a0
	lea		sins,a1
	move.w		#1024/4-1,d7
.sin:
	moveq		#0,d0
	move.w		(a0),d1
	addq.w		#8,a0
	move.l		a1,a2
	addq.l		#2,a1

	moveq		#END_FRAME_COUNT-1,d6
.scl:
	move.w		d0,d2
	asr.w		#8,d2
	move.w		d2,(a2)
	add.w		d1,d0
	lea		2*1024/4(a2),a2
	dbra		d6,.scl

	dbra		d7,.sin

	move.l		#frames,END_CurFrame
	rts

;-----------------------------------------------
END_play:
	move.l		END_CurFrame,a0
	bsr		END_draw
	lea		HSCREEN*40(a0),a0
	cmp.l		#frames+HSCREEN*40*END_FRAME_COUNT,a0
	ble.s		.noloop
	;lea		frames,a0
	;bsr		SwapSTEBuffers
	rts
.noloop:	
	move.l		a0,END_CurFrame
	bsr		SwapSTEBuffers

	rts

END_CurFrame:	dc.l	0

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
END_calcAllDots:
	lea		END_Wxs+WSCREEN*4,a1
	lea		END_RowsOfs+HSCREEN*2,a2
	lea		frames+HSCREEN*40*(END_FRAME_COUNT-1),a3
	sub.l		a4,a4

	move.w		#END_IMG_WIDTH-1,d0
.xloop:
	moveq		#END_IMG_HEIGHT-1,d1
.yloop:
	move.l		a3,a0
	move.w		a4,d2
	;sub.w		#6,a4
	sub.w		#12,a4

	bsr		END_calcOneDot	; D0 = x, D1 = y, D2 = alpha, A0 = dest, A1 = wxs, A2 = rowsptr

	dbra		d1,.yloop

	;add.w		#64,a4
	add.w		#128,a4
;uu:
	dbra		d0,.xloop

	rts

;-----------------------------------------------
		rsreset
_END_DotX:	rs.w	0
_END_DotY:	rs.w	0
_END_DotAlpha:	rs.w	0


;-----------------------------------------------
END_calcIterDot:	; a6 = DotStruct
	lea		END_Wxs+WSCREEN*4,a1
	lea		END_RowsOfs+HSCREEN*2,a2
	lea		frames+HSCREEN*40*(END_FRAME_COUNT-1),a0
	movem.w		(a6)+,d0-d2


;-----------------------------------------------
END_calcOneDot:		; D0 = x, D1 = y, D2 = alpha, A0 = dest, A1 = wxs, A2 = rowsptr

	lea		sins,a6

	BGC		$0f0

	movem.l		d0-d1/a3-a4,-(sp)

	move.w		#$3fc,d6
	lea		4*256.w,a3
	lea		-HSCREEN*40,a4

	add.w		#WSCREEN/2-END_IMG_WIDTH/2,d0
	add.w		d0,d0
	add.w		d0,d0
	add.w		#HSCREEN/2-END_IMG_HEIGHT/2,d1
	add.w		d1,d1
;	moveq		#END_FRAME_COUNT-1,d6
.floop:
	rept		END_FRAME_COUNT
;	move.w		d0,d4		; x
;	and.w		#$1fe,d2	; alpha [0..510]
;	add.w		(a6,d2.w),d4	; x += sins[alpha]
;	move.w		d1,d5		; y
;	move.w		d2,d3		; beta
;	add.w		#64*2,d3	; beta += PI/4
;	and.w		#$1fe,d3	; beta [0..510]
;	add.w		(a6,d3.w),d5	; y += cos[beta]

;	and.w		#$3fc,d2	; alpha [0..510]
	and.w		d6,d2		; alpha [0..510]
	movem.w		(a6,d2.w),d4-d5	; x += sins[alpha]
	add.w		d0,d4
	add.w		d1,d5

;	add.w		d4,d4
;	add.w		d4,d4		; x *= 4
;	add.w		d5,d5		; y *= 2

	movem.w		(a1,d4.w),d3-d4	; col_ofs, mask
	add.w		(a2,d5.w),d3	; col_ofs += row_ofs
	or.w		d4,(a0,d3.w)	; 

	;lea		2*1024/4(a6),a6
	;lea		4*256(a6),a6
	;lea		-HSCREEN*40(a0),a0	; 
	add.l		a3,a6
	add.l		a4,a0

	;add.w		#2,d2		; alpha+=2
	addq.w		#4,d2		; alpha+=2

;	dbra		d6,.floop
	endr

	movem.l		(sp)+,d0-d1/a3-a4
	;sub.w		#WSCREEN/2-END_IMG_WIDTH/2,d0
	;sub.w		#HSCREEN/2-END_IMG_HEIGHT/2,d1

	BGC		$000

	rts

;-----------------------------------------------
END_calcAllDots2:
	lea		END_Wxs+WSCREEN*4,a1
	lea		END_RowsOfs+HSCREEN*2,a2
	lea		frames+HSCREEN*40*(END_FRAME_COUNT-1),a3
	sub.l		a4,a4

	move.w		#END_IMG_WIDTH-1,d0
xloop:
	moveq		#END_IMG_HEIGHT-1,d1
yloop:
	move.l		a3,a0
	move.w		a4,d2
	sub.w		#6,a4

	bsr		END_calcOneDot	; D0 = x, D1 = y, D2 = alpha, A0 = dest, A1 = wxs, A2 = rowsptr

	dbra		d1,yloop

	add.w		#64,a4
;uu:
	dbra		d0,xloop

	rts

;-----------------------------------------------
END_calcOneDot2:		; D0 = x, D1 = y, D2 = alpha, A0 = dest, A1 = wxs, A2 = rowsptr

	BGC		$0f0

	lea		sins,a6

	add.w		#WSCREEN/2-END_IMG_WIDTH/2,d0
	add.w		#HSCREEN/2-END_IMG_HEIGHT/2,d1
	moveq		#END_FRAME_COUNT-1,d6

;	lea		4*2*1024/4(a6),a6
;uu:

.floop:
	move.w		d0,d4		; x
	and.w		#$1fe,d2	; alpha [0..510]
	add.w		(a6,d2.w),d4	; x += sins[alpha]
	move.w		d1,d5		; y
	move.w		d2,d3		; beta
	add.w		#64*2,d3	; beta += PI/4
	and.w		#$1fe,d3	; beta [0..510]
	add.w		(a6,d3.w),d5	; y += cos[beta]
	add.w		#2,d2		; alpha+=2

	add.w		d4,d4
	add.w		d4,d4		; x *= 4
	add.w		d5,d5		; y *= 2

	movem.w		(a1,d4.w),d3-d4	; col_ofs, mask
	add.w		(a2,d5.w),d3	; col_ofs += row_ofs
	or.w		d4,(a0,d3.w)	; 

	lea		2*1024/4(a6),a6
	lea		-HSCREEN*40(a0),a0	; 

	dbra		d6,.floop

	sub.w		#WSCREEN/2-END_IMG_WIDTH/2,d0
	sub.w		#HSCREEN/2-END_IMG_HEIGHT/2,d1

	BGC		$000

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
vv:
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

;-----------------------------------------------
END_createMasks:
	lea		END_Logo+IMG_Struct_Size,a0
	lea		END_Masks,a1
	move.w		#END_IMG_WIDTH*END_IMG_HEIGHT/16-1,d7
.loop:
	move.w		#16-1,d6
.wloop:
	move.w		(a0)+,d0
	moveq		#$f,d1
	rol.w		#4,d0
	and.b		d0,d1
	sne		d2
	add.b		d2,d2
	addx.w		d3,d3
	dbra		d6,.wloop
	move.w		d3,(a1)+
	dbra		d7,.loop

	rts

;-----------------------------------------------
;STD_PLOT: macro	; a0 = dest, a1 = rowsptr, a2 = wxs, d0 = x*4, d1 = y*2
;	movem.w		(a2,d0.w),d0/d2
;	add.w		(a1,d1.w),d0
;	or.w		d2,(a0,d0.w)
;	endm


;-----------------------------------------------
                section data

END_Logo:	incbin	"data/ngc.img"


;-----------------------------------------------
                section bss

END_LogoImgSt:	ds.b	IMG_Struct_Size

END_Masks:	ds.l	END_IMG_WIDTH*END_IMG_HEIGHT/32

END_Wxs:	ds.l	WSCREEN*3
END_RowsOfs:	ds.w	HSCREEN*3

sin:
frames:		ds.b	40*200*END_FRAME_COUNT
sins:		ds.b	4*256*64

buffers:	ds.b	65536


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
;FBlit:					
;	lea		$ffff8a20.w,a6	; First register needed by us
;	move.l		d0,(a6)+	; SrcXinc.SrcYinc
;	move.l		a0,(a6)+	; SrcPtr
;	move.l		d2,(a6)+	; Fmsk.Mmsk
;	move.w		d2,(a6)+	; Lmsk
;	move.l		d1,(a6)+	; DstXinc.DstYinc
;	move.l		a1,(a6)+	; DstPtr
;	move.l		d3,(a6)+	; Width.Height
;	move.l		d4,(a6)
;	rts

