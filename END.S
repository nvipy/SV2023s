
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
	
	bsr		SwapSTEBuffers

	;-------------------
	bsr		END_init
	;-------------------
.iter:
	bsr		END_calcIterDot
	tst.w		END_Dot
	beq.s		.iter
	bsr		END_cleanFrames
	;-------------------

	lea		Vbl,a0
	bsr		SetVbl
	
	move.w		#1,VblStrobe
mainloop:	
	tst.w		VblStrobe
	bpl.s		mainloop
	move.w		#1,VblStrobe

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
END_FRAME_COUNT	=	128
END_IMG_WIDTH	=	192
END_IMG_HEIGHT	=	80

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

	lea		cmapRTZ,a0
	bsr		SetColors

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
	move.l		END_FramePtr,a1
	move.l		(a1)+,a0
	move.l		a0,d0
	bne.s		.next
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
                section data

END_Logo:	incbin	"data/ngc.img"
cmapRTZ:	dc.w	0,$111,$222,$333,$444,$555,$666,$777,$888,$999,$aaa,$bbb,$ccc,$ddd,$eee,$fff

;-----------------------------------------------
                section bss

sin:
END_Wxs:	ds.l	WSCREEN*3
END_RowsOfs:	ds.w	HSCREEN*3

sins:		ds.b	4*256*END_FRAME_COUNT

END_LogoImgSt:	ds.b	IMG_Struct_Size
END_Points:	ds.l	END_IMG_WIDTH*END_IMG_HEIGHT

END_Frames:	ds.b	40*200*END_FRAME_COUNT

		ds.b	16384
buffers:	ds.b	65536


