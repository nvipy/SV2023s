;**********************************************************************
;		IFND		_SYS_S_
;**********************************************************************
;_SYS_S_		=	0

WSCREEN			=	320
HSCREEN			=	200
WSCREEN_BYTES		=	160
WSCREEN_WORDS		=	80
WSCREEN_PLAN_BYTES	=	40
WSCREEN_PLAN_WORDS	=	20
;---------------------------------------------------
NULL		=	0

BGC		macro
		move.w		#\1,$ffff8240.w
		endm


;------------------------------------------------
SYS_mixCmap:	; A0 = 5 colors: background, plan 1 color, plan 2 color, plan 3 color, plan 4 color, A1 = dest
	
	move.l		(a0),(a1)+	; push background, plans color 1 (0,1)
	move.w		4(a0),(a1)+	; push plan colors 2 (2)

	movem.w		2(a0),d0/d1	; get plans colors 1,2
	bsr		SYS_mix2Colors
	move.w		d0,(a1)+	; push mix plans colors 1,2 (3)

	move.w		6(a0),(a1)+	; push plans color 3	(4)

	move.w		2(a0),d0	; get plans colors 1
	move.w		6(a0),d1	; get plans colors 3
	bsr		SYS_mix2Colors
	move.w		d0,(a1)+	; push mix plans colors 1,3 (5)

	move.w		4(a0),d0	; get plans colors 2
	move.w		6(a0),d1	; get plans colors 3
	bsr		SYS_mix2Colors
	move.w		d0,(a1)+	; push mix plans colors 2,3 (6)

	movem.w		2(a0),d0-d2	; get plans colors 1,2,3
	bsr		SYS_mix3Colors
	move.w		d0,(a1)+	; push mix plans colors 1,2,3 (7)

	move.w		8(a0),(a1)+	; push plans color 4	(8)

	move.w		2(a0),d0	; get plans colors 1
	move.w		8(a0),d1	; get plans colors 4
	bsr		SYS_mix2Colors
	move.w		d0,(a1)+	; push mix plans colors 1,4 (9)

	move.w		4(a0),d0	; get plans colors 2
	move.w		8(a0),d1	; get plans colors 4
	bsr		SYS_mix2Colors
	move.w		d0,(a1)+	; push mix plans colors 2,4 (10)

	movem.w		2(a0),d0-d1	; get plans colors 1,2
	move.w		8(a0),d2	; get plans colors 4
	bsr		SYS_mix3Colors
	move.w		d0,(a1)+	; push mix plans colors 1,2,4 (11)

	movem.w		6(a0),d0-d1	; get plans colors 3,4
	bsr		SYS_mix2Colors
	move.w		d0,(a1)+	; push mix plans colors 3,4 (12)

	movem.w		6(a0),d0-d1	; get plans colors 3,4
	move.w		2(a0),d2	; get plans colors 1
	bsr		SYS_mix3Colors
	move.w		d0,(a1)+	; push mix plans colors 1,3,4 (13)

	movem.w		4(a0),d0-d2	; get plans colors 2,3,4
	bsr		SYS_mix3Colors
	move.w		d0,(a1)+	; push mix plans colors 2,3,4 (14)

	movem.w		2(a0),d0-d3	; get plans colors 1,2,3,4
	bsr		SYS_mix4Colors
	move.w		d0,(a1)+	; push mix plans colors 1,2,3,4 (14)

	rts

;------------------------------------------------
SYS_mix2Colors:		; D0 = color 0, D1 = color 1, return D0 = color 
	move.w		d0,d2		; col0
	move.w		d1,d3		; col1
	move.w		#$f0f,d6	; RedBlue mask
	and.w		d6,d0		; rb0
	and.w		d6,d1		; rb1
	add.w		d1,d0		; (rb0+rb1)
	lsr.w		#1,d0		; (rb0+rb1)/2
	and.w		d6,d0		; rb out
	not.w		d6		; Green mask ($0f0)
	and.w		d6,d2		; g0
	and.w		d6,d3		; g1
	add.w		d3,d2		; g0+g1
	lsr.w		#1,d2		; (g0+g1)/2
	and.w		d6,d2		; g out
	or.w		d2,d0		; rgb out.
	and.w		#$fff,d0
	rts

SYS_mix3Colors:		; D0 = color 0, D1 = color 1, D2 = color 2, return D0 = color 
	move.w		#$f0f,d6	; RedBlue mask
	move.w		d0,d4		; col0
	and.w		d6,d4		; rb0
	move.w		d1,d5		; col1
	and.w		d6,d5		; rb1
	add.w		d4,d5		; rb0+rb1
	move.w		d2,d4		; col2
	and.w		d6,d4		; rb2
	add.w		d4,d5		; rb0+rb1+rb2
	moveq		#$3f,d4
	and.l		d5,d4		; b0+b1+b2
	and.l		#$3f00,d5	; r0+r1+r2
	divu		#3,d4		; (b0+b1+b2)/3
	divu		#3,d5		; (r0+r1+r2)/3
	and.w		#$0f,d4		; b
	and.w		#$0f00,d5	; r
	or.w		d4,d5		; rb
	not.w		d6		; Green mask ($0f0)
	and.w		d6,d0		; g0
	and.w		d6,d1		; g1
	and.w		d6,d2		; g2
	add.w		d1,d0		; g1+g0
	add.w		d2,d0		; g2+g1+g0
	ext.l		d0
	divu		#3,d0		; (g2+g1+g0)/3
	and.w		d6,d0		; g out
	or.w		d5,d0		; rgb out
	and.w		#$fff,d0
	rts

SYS_mix4Colors:		; D0 = color 0, D1 = color 1, D2 = color 2, D3 = color 3, return D0 = color 
	move.w		#$f0f,d6	; RedBlue mask
	move.w		d0,d4		; col0
	and.w		d6,d4		; rb0
	move.w		d1,d5		; col1
	and.w		d6,d5		; rb1
	add.w		d5,d4		; rb0+rb1
	move.w		d2,d5		; col2
	and.w		d6,d5		; rb2
	add.w		d5,d4		; rb0+rb1+rb2
	move.w		d3,d5		; col3
	and.w		d6,d5		; rb3
	add.w		d5,d4		; rb0+rb1+rb2+rb4
	lsr.w		#2,d4		; (rb0+rb1+rb2+rb3)/4
	and.w		d6,d4		; rb out
	not.w		d6		; Green mask ($0f0)
	and.w		d6,d0		; g0
	and.w		d6,d1		; g1
	and.w		d6,d2		; g2
	and.w		d6,d3		; g3
	add.w		d1,d0		; g1+g0
	add.w		d2,d0		; g1+g0+g2
	add.w		d3,d0		; g1+g0+g3+g2
	lsr.w		#2,d0		; (g0+g1+g2+g3)/4
	and.w		d6,d0		; g out
	or.w		d4,d0		; rgb out.
	and.w		#$fff,d0
	rts

;-----------------------------------------------
;MATH_getRandom:			; D0 = return rnd number
;	move.l		MATH_RandomSeed(pc),d0
;	move.l		d0,d1
;	swap		d0
;	add.w		d0,d1
;	roxr.l		#3,d1
;	move.l		d1,d0
;	not.l		d1
;	move.l		d1,MATH_RandomSeed
;	rts
;MATH_RandomSeed:	dc.l	0

;-----------------------------------------------
FileAllowOp:		; D0= 0: not allowed, other allowed
	tst.w		d0
	bne.s		.1
	and.b		#$7f,$fffffa09.w
	rts
.1:	or.b		#$80,$fffffa09.w
	rts

;-----------------------------------------------
FileOpen:		; A0=filename, return D0=fileHandle
	move.w		#0,-(sp)
	move.l		a0,-(sp)
	move.w		#61,-(sp)
	trap		#1
	addq.l		#8,sp	
	rts

;-----------------------------------------------
FileClose:		; D0=fileHandle
	move.w		d0,-(sp)
	move.w		#62,-(sp)
	trap		#1
	addq.l		#4,sp	
	rts

;-----------------------------------------------
FileRead:		; D0=fileHandle, A0=buffer, D1=BufSize, return D0 = len or error
	move.l		a0,-(sp)
	move.l		d1,-(sp)
	move.w		d0,-(sp)
	move.w		#63,-(sp)
	trap		#1
	add.w		#12,sp
	rts

;-----------------------------------------------
GetFreeMemory:		; return D0 = free memory size
	moveq		#-1,d0
	move.l		d0,-(sp)
	move.w		#$48,-(sp)
	trap		#1
	addq.l		#6,sp
	rts

;-----------------------------------------------
BFHandle:		dc.w	0
BFFileOffsetPtr:	dc.l	0
BFFat:
BFVersion:		dc.b	0
BFFlags:		dc.b	0
BFFileCount:		dc.b	0,0
BFFileOffsets:		ds.l	128-1	; 126 files max, the last file offset is the end of file
;-----------------------------------------------
BF_open:				; A0=filename
	movem.l		d1-d2/a0-a2,-(sp)

	clr.w		-(sp)
	move.l		a0,-(sp)
	move.w		#61,-(sp)
	trap		#1
	addq.l		#8,sp
	move.w		d0,BFHandle

	pea		BFFat
	move.l		#512,-(sp)
	move.w		d0,-(sp)
	move.w		#63,-(sp)
	trap		#1
	add.w		#12,sp

	move.l		#BFFileOffsets,BFFileOffsetPtr

	movem.l		(sp)+,d1-d2/a0-a2
	rts

;-----------------------------------------------
BF_read:		; A0=buffer, return D0 = len or error
	movem.l		d1-d2/a0-a2,-(sp)

	move.l		BFFileOffsetPtr(pc),a1
	move.l		(a1)+,d1
	sub.l		(a1),d1
	neg.l		d1
	move.l		a1,BFFileOffsetPtr

	move.l		a0,-(sp)
	move.l		d1,-(sp)
	move.w		BFHandle(pc),-(sp)
	move.w		#63,-(sp)
	trap		#1
	add.w		#12,sp

	movem.l		(sp)+,d1-d2/a0-a2
	rts

;-----------------------------------------------
BF_reads:		; A0=buffer, D7=file count-1, return A1=ptrs array (count+1), return D0=len or error
	movem.l		d1-d2/a0-a2,-(sp)

	move.l		BFFileOffsetPtr(pc),a2
.0:
	move.l		(a2)+,d1
	sub.l		(a2),d1
	neg.l		d1

	move.l		a0,(a1)+
	add.l		d1,a0

	move.l		a0,-(sp)
	move.l		d1,-(sp)
	move.w		BFHandle(pc),-(sp)
	move.w		#63,-(sp)
	trap		#1
	add.w		#12,sp
	tst.w		d0
	dbpl		d7,.0

	move.l		a0,(a1)+
	move.l		a2,BFFileOffsetPtr

	movem.l		(sp)+,d1-d2/a0-a2
	rts

;-----------------------------------------------
BF_close:
	movem.l		d1-d2/a0-a2,-(sp)
	move.w		BFHandle(pc),-(sp)
	move.w		#62,-(sp)
	trap		#1
	addq.l		#4,sp	
	movem.l		(sp)+,d1-d2/a0-a2
	rts

;-----------------------------------------------
RelocateCollection:	; A0 = collection , return A0 = end of collection catalogue ; use d0/d1/a1
	move.l		a0,d1
	cmp.l		2(a0),a0
	bmi.s		.1		; already relocate	
	move.w		(a0)+,d0
.0:
	add.l		d1,(a0)+
	dbra		d0,.0
.1:
	rts


;-----------------------------------------------
SetScreenAdrsSTE:	;D0 = screen adrs
	lea		$ffff8201.w,a0
	move.b		d0,d1
	lsr.w		#8,d0
	move.b		d0,2(a0)
	swap		d0
	move.b		d0,(a0)
	move.b		d1,$c(a0)

;	move.w		d0,-(sp)
;	move.b		(sp)+,$ffff8207.w ; 7
;	swap		d0
;	move.b		d0,$ffff8205.w ; 5
;	swap		d0
;	move.b		d0,$ffff8209.w ; 9

	rts

;-----------------------------------------------
SetSTEBuffers:	; D0 : Double screen buffers adress, D1: bytes between front and back screen
	move.l	d0,frontBuf
	move.l	d0,UpBuf
	add.l	#32000,d1
	add.l	d1,d0
	move.l	d0,backBuf
	move.l	d0,DownBuf
	rts

;-----------------------------------------------
SwapSTEBuffers:
	lea	frontBuf(pc),a0
	move.l	4(a0),d0
	move.l	(a0),4(a0)
	move.l	d0,(a0)
	move.w	d0,d1	;
	move.w	d0,-(sp)
	move.b	(sp)+,$ffff8203.w ; 7
	swap	d0
	move.b	d0,$ffff8201.w ; 5
	move.b	d1,$ffff820d.w ; 9

;	move.b	(sp)+,$ffff8207.w ; 7
;	swap	d0
;	move.b	d0,$ffff8205.w ; 5
;	swap	d0
;	move.b	d0,$ffff8209.w ; 9

	rts

;-----------------------------------------------
frontBuf:	dc.l	0
backBuf:	dc.l	0
UpBuf:		dc.l	0
DownBuf:	dc.l	0

;-----------------------------------------------
ClearScreenSTEBuffer:	; a0: screen buffer
	lea		$ffff8a28.w,a1			; First register needed
	moveq		#-1,d0
	move.l		d0,(a1)+
	move.w		d0,(a1)+
	moveq		#2,d0				; DstXinc.DstYinc
	move.l		d0,(a1)+			; DstXinc.DstYinc
	move.l		a0,(a1)+			; DstPtr
	move.l		#(1<<16)+200*80,(a1)+		; Width.Height
	move.l		#$0000c000,(a1)			; Hop 
	rts

;-----------------------------------------------
ClearAllScreenSTEBuffer:
	lea		$ffff8a28.w,a1			; First register needed
	moveq		#-1,d0
	move.l		d0,(a1)+
	move.w		d0,(a1)+
	moveq		#2,d0				; DstXinc.DstYinc
	move.l		d0,(a1)+			; DstXinc.DstYinc
	move.l		UpBuf(pc),(a1)+			; DstPtr
	move.l		#(1<<16)+32767,(a1)+		; Width.Height
	move.l		#$0000c000,(a1)			; Hop 
	rts

;-----------------------------------------------
CopyScreenSTEBuffer:	; a0 = source buffer, a1: dest screen buffer 
	lea		$ffff8a20.w,a2			; First register needed
	moveq		#2,d0				; DstXinc.DstYinc
	move.l		d0,(a2)+
	move.l		a0,(a2)+
	moveq		#-1,d0
	move.l		d0,(a2)+
	move.w		d0,(a2)+
	moveq		#2,d0				; DstXinc.DstYinc
	move.l		d0,(a2)+			; DstXinc.DstYinc
	move.l		a1,(a2)+			; DstPtr
	move.l		#(1<<16)+200*80,(a2)+		; Width.Height
	move.l		#$0203c000,(a2)			; Hop 

	rts

;-----------------------------------------------
; Convert and set RGB 12 bits cmap to STE cmap
SetColors:	; a0 = palette ptr  
	lea		$ffff8240.w,a1
	move.l		#$0eee0eee,d1
	move.l		#$01110111,d2
	rept		8
	move.l		(a0)+,d0
	move.l		d0,d3
	and.l		d1,d0
	lsr.l		#1,d0
	and.l		d2,d3
	lsl.l		#3,d3
	or.l		d3,d0
	move.l		d0,(a1)+
	endr
	rts

;-----------------------------------------------
ColorSpread:		; D0 = color0.color15, A4 = Dest
	lea		SpreadedColors(pc),a0
	lea		2(a0),a1
	move.l		d0,(a0)
	moveq		#0,d5
	bsr.s		InitInnerShading	; d5 = ncolor-1 (must be < 16), a0 = cmap0, a1 = cmap1
	moveq		#0,d5
	bra.s		ShadeInner		; d5 = ncolor-1, a4 = dest, unused: d6-d7/a0-a3/a5-a6 

;-----------------------------------------------
InitPalShading:		; d0:speed, a0:srcpal, a1:destpal
	lea		palShdCount(pc),a2
	move.w		d0,(a2)+	; counter
	move.w		#17,(a2)+	; increment 0-15
	move.w		d0,(a2)		; counter0
	moveq		#15,d5

;-----------------------------------------------
InitInnerShading:	; d5 = ncolor-1 (must be <= 16), a0 = cmap0, a1 = cmap1 
	lea		palShdData(pc),a2
	lea		palShdInc(pc),a3

;-----------------------------------------------
InitColorShading:	; d5 = ncolor-1, a0 = cmap0, a1 = cmap1, a2 = Shade color data, a3 = Shade color increment
	move.w		#$f00,d4
	move.w		#$f0,d6
	moveq		#$f,d7
.0:
	move.w		(a0)+,d2	; src col
	move.w		(a1)+,d3	; dst col

	move.w		d2,d0
	and.w		d4,d0	; Rsrc
	move.w		d3,d1
	and.w		d4,d1	; Rdst
	sub.w		d0,d1		; Rdst-Rsrc
	lsl.w		#4,d0		; Rsrc.0.0.0
	move.w		d0,(a2)+	; X.Rdst.0.0
	move.w		d1,(a3)+	; Rsrc.0.0.0

	move.w		d2,d0
	and.w		d6,d0
	move.w		d3,d1
	and.w		d6,d1
	sub.w		d0,d1
	lsl.w		#4,d0
	move.w		d0,(a2)+
	move.w		d1,(a3)+

	and.w		d7,d2
	and.w		d7,d3
	sub.w		d2,d3
	lsl.w		#4,d2
	move.w		d2,(a2)+
	move.w		d3,(a3)+

	dbf		d5,.0
	rts

;-----------------------------------------------
ShadePal:		; a4 = dest,  Return d0: d0=0 continue, d0=-1 end
	lea		palShdCount(pc),a2
	subq.w		#1,(a2)		; counter--
	bmi.s		.2
	moveq		#0,d0
	rts
.2:
	move.w		4(a2),(a2)	; counter = counter0
	subq.w		#1,2(a2)	; color increment
	bpl.s		.3
	moveq		#-1,d0
	rts
.3:
	moveq		#15,d5

;-----------------------------------------------
ShadeInner:		; d5 = ncolor-1, a4 = dest, unused: d6-d7/a0-a3/a5-a6 
	lea		palShdData(pc),a2
	lea		palShdInc(pc),a3

;-----------------------------------------------
ShadeColors:		; d5 = ncolor-1, a2 = Shade color data, a3 = Shade color increment, a4 = dest, unused: d6-d7/a0-a1/a5-a6 
	move.l		#$f0000ff0,d2	; msk r0000gb0
	move.l		#$0888,d3
	move.l		#$0777,d4
.0:
	move.l		(a2),d0		;R.r.0.0.0.G.g.0 
	move.b		5(a2),d0	;R.r.0.0.0.G.B.b
	and.l		d2,d0		;R.0.0.0.0.G.B.0
	move.l		d0,d1
	swap		d1		;0.G.B.0.R.0.0.0
	or.w		d1,d0		;R.G.B.0
	move.w		d0,d1
	lsr.w		#1,d0
	and.w		d3,d0
	lsr.w		#5,d1
	and.w		d4,d1
	or.w		d1,d0		;0.R.G.B
	move.w		d0,(a4)+
	move.l		(a3)+,d0
	add.l		d0,(a2)+
	move.w		(a3)+,d0
	add.w		d0,(a2)+
	dbf		d5,.0
	moveq		#0,d0
	rts


;-----------------------------------------------
IncPal:			;  Return d0: d0=0 continue, d0=-1 end
	lea		palShdCount(pc),a2
	subq.w		#1,(a2)		; counter--
	bmi.s		.2
	moveq		#0,d0
	rts
.2:
	move.w		4(a2),(a2)	; counter = counter0
	subq.w		#1,2(a2)	; color increment
	bpl.s		.3
	moveq		#-1,d0
	rts
.3:
	lea		palShdData(pc),a2
	lea		palShdInc(pc),a3
	moveq		#15,d5

;-----------------------------------------------
IncShade:		; d5 = ncolor-1, a2 = Shade color data, a3 = Shade color increment
	move.l		(a3)+,d0
	add.l		d0,(a2)+
	move.w		(a3)+,d0
	add.w		d0,(a2)+
	dbf		d5,IncShade
	moveq		#0,d0
	rts

SpreadedColors:	dc.l	0
palShdCount:	ds.w	3
palShdData:	ds.w	16*3
palShdInc:	ds.w	16*3

;-----------------------------------------------
LCopy:			; a0=src,a1=dst,d0=(length/256)-1
	movem.l		d1-d7/a2-a3,-(sp)
	move.w		#256,a3
.lcloop:
	movem.l		(a0)+,d1-d7/a2 	;8 longs: 32 bytes
	movem.l		d1-d7/a2,(a1)
	movem.l		(a0)+,d1-d7/a2
	movem.l		d1-d7/a2,32(a1)
	movem.l		(a0)+,d1-d7/a2
	movem.l		d1-d7/a2,64(a1)
	movem.l		(a0)+,d1-d7/a2
	movem.l		d1-d7/a2,96(a1)
	movem.l		(a0)+,d1-d7/a2
	movem.l		d1-d7/a2,128(a1)
	movem.l		(a0)+,d1-d7/a2
	movem.l		d1-d7/a2,160(a1)
	movem.l		(a0)+,d1-d7/a2
	movem.l		d1-d7/a2,192(a1)
	movem.l		(a0)+,d1-d7/a2
	movem.l		d1-d7/a2,224(a1)
	add.l		a3,a1
	dbra		d0,.lcloop
	movem.l		(sp)+,d1-d7/a2-a3

	rts

;-----------------------------------------------
Clear:			; A0: dest, D0.L: word height.width ???????? use in stars ????
	movem.l		d0-d1/a1,-(sp)
	lea		$ffff8a28.w,a1			; First register needed
	moveq		#-1,d1
	move.l		d1,(a1)+
	move.w		d1,(a1)+
	moveq		#0,d1
	move.w		d0,d1
	swap		d0
	add.w		d1,d1
	move.l		d1,(a1)+			; DstXinc.DstYinc
	move.l		a0,(a1)+			; DstPtr
	move.l		d0,(a1)+			; Width.Height
	move.l		#$0000c000,(a1)			; Hop 
	movem.l		(sp)+,d0-d1/a1
	rts

;-----------------------------------------------
Copy:			; A0: src, A1: dest, D0.L: word height.width
	movem.l		d0-d2/a2,-(sp)
	lea		$ffff8a20.w,a2			; First register needed
	moveq		#-1,d2
	moveq		#0,d1
	move.w		d0,d1
	swap		d0
	add.w		d1,d1
	move.l		d1,(a2)+			; SrcXinc.SrcYinc
	move.l		a0,(a2)+			; SrcPtr
	move.l		d2,(a2)+			; Fmsk.Mmsk
	move.w		d2,(a2)+			; Lmsk
	move.l		d1,(a2)+			; DstXinc.DstYinc
	move.l		a1,(a2)+			; DstPtr
	move.l		d0,(a2)+			; Width.Height
	move.l		#$0203c000,(a2)			; Hop 
	movem.l		(sp)+,d0-d2/a2
	rts

;-----------------------------------------------
WCopy:			; A0: src, A1: dest, D0.L: word height.width
	movem.l		d0-d2/a2,-(sp)
	lea		$ffff8a20.w,a2			; First register needed
	moveq		#-1,d2				; msk
	move.l		#$00020002,d1			; Xinc=2.Yinc=2
	move.l		d1,(a2)+			; SrcXinc.SrcYinc
	move.l		a0,(a2)+			; SrcPtr
	move.l		d2,(a2)+			; Fmsk.Mmsk
	move.w		d2,(a2)+			; Lmsk
	move.l		d1,(a2)+			; DstXinc.DstYinc
	move.l		a1,(a2)+			; DstPtr
	move.l		d0,(a2)+			; Width.Height
	move.l		#$0203c000,(a2)			; Hop 
	movem.l		(sp)+,d0-d2/a2
	rts


;-------------------------------
;			rsreset
;_IMG_WordWidth:		rs.w		1
;_IMG_Height:		rs.w		1
;_IMG_Cmap:		rs.w		16
;IMG_Struct_Size		rs.b		1
;
;
;			rsreset
;_IMGFILE_WordWidth:	rs.b		1
;_IMGFILE_Height:	rs.b		1
;_IMGFILE_Type:		rs.b		1	; 'C'=Chunky, 'B'=Bitmap
;_IMGFILE_CmapLenght:	rs.b		1
;_IMGFILE_Cmap:		rs.w		16
;IMGFILE_Struct_Size	rs.b		1
;
;IMG_getInfo:		; A0 = image data, A6 = return image struct, Return D3.b = type (C/B), d4 = wordwidth, d5 = height, use d2
;	clr.w		d4
;	clr.w		d5
;	move.b		(a0)+,d4		; width in word
;	move.w		d4,_IMG_WordWidth(a6)
;	move.b		(a0)+,d5
;	move.w		d5,_IMG_Height(a6)	; height
;
;	move.b		(a0)+,d3		; type
;	moveq		#0,d2
;	move.b		(a0)+,d2		; cmap len
;	lea		_IMG_Cmap(a6),a2
;.4:
;	move.w		(a0)+,(a2)+
;	dbra		d2,.4
;
;	rts
;
;IMG_get4Bits:	; d0 = dest word width, d1 = dest height, a0 = image data, a1 = screens destinations, a6: image struct
;	bsr.s		IMG_getInfo
;
;	cmp.b		#'C',d3
;	beq.s		.3
;	rts
;.3:
;	move.w		d0,d2			; screen word width
;	lsl.w		#3,d0			; screen raster width in byte = word width * 8
;	sub.w		d4,d2
;
;	add.w		d2,d2	; mod 1 word-> 2 bytes 
;	add.w		d2,d2	; mod 1 word-> 4 bytes 
;	add.w		d2,a1	; add mod/2
;	add.w		d2,d2	; mod 1 word-> 8 bytes 
;	move.w		d2,a2	; mod qword
;	move.w		d1,d2	; SCREEN_HEIGHT,d2
;	sub.w		d5,d2
;	lsr.w		#1,d2
;	mulu		d0,d2	; top.y * screen raster width in byte
;	add.w		d2,a1
;	subq.w		#1,d4	; width in word - 1
;	move.l		d4,a3
;	subq.w		#1,d5	; height
;	move.w		d5,d1
;.5:
;	move.l		a3,d0
;.6:
;	moveq		#3,d2
;.7:
;	move.w		(a0)+,d3
;	rept		4
;	add.w		d3,d3
;	addx.w		d7,d7
;	add.w		d3,d3
;	addx.w		d6,d6
;	add.w		d3,d3
;	addx.w		d5,d5
;	add.w		d3,d3
;	addx.w		d4,d4
;	endr
;	dbra		d2,.7
;	movem.w		d4-d7,(a1)
;	addq.l		#8,a1
;	dbra		d0,.6
;	add.l		a2,a1
;	dbra		d1,.5
;	rts
;
;IMG_getLinear2bits:	; A0 = image data, A1 = destinations, A6 = image struct, can be use source as dest A0=A1, use D2-D7/A2
;	bsr		IMG_getInfo ; return D4 = width in word, D5 = height, D3 = type 
;
;	cmp.b		#'C',d3
;	beq.s		.0
;	rts
;.0:
;	mulu		d5,d4
;IMG_get2bitsRaw:		; A0 = image data, A1 = destinations, D4 = size in long (16 * 2bits pixel)	
;	subq.w		#1,d4
;.1:
;	move.l		(a0)+,d3
;	rept		16
;	add.l		d3,d3
;	addx.w		d7,d7
;	add.l		d3,d3
;	addx.w		d6,d6
;	endr
;	move.w		d6,(a1)+
;	move.w		d7,(a1)+
;	dbra		d4,.1
;	rts
;
;IMG_get2BitsInterleave:	; d0 = dest word width, d1 = dest height, a0 = image data, a1 = screens destinations, a6: image struct
;	bsr		IMG_getInfo
;
;	cmp.b		#'C',d3
;	beq.s		.3
;	rts
;.3:
;	move.w		d0,d2			; screen word width
;	lsl.w		#3,d0			; screen raster width in byte = word width * 8
;	sub.w		d4,d2
;
;	add.w		d2,d2	; mod 1 word-> 2 bytes 
;	add.w		d2,d2	; mod 1 word-> 4 bytes 
;	add.w		d2,a1	; add mod/2
;	add.w		d2,d2	; mod 1 word-> 8 bytes 
;	move.w		d2,a2	; mod qword
;	move.w		d1,d2	; SCREEN_HEIGHT,d2
;	sub.w		d5,d2
;	lsr.w		#1,d2
;	mulu		d0,d2	; top.y * screen raster width in byte
;	add.w		d2,a1
;	subq.w		#1,d4	; width in word - 1
;	move.l		d4,a3
;	subq.w		#1,d5	; height
;	move.w		d5,d1
;.5:
;	move.l		a3,d0
;.6:
;	move.l		(a0)+,d3
;	rept		16
;	add.l		d3,d3
;	addx.w		d7,d7
;	add.l		d3,d3
;	addx.w		d6,d6
;	endr
;	move.w		d6,(a1)
;	move.w		d7,4(a1)
;	addq.l		#8,a1
;	dbra		d0,.6
;	add.l		a2,a1
;	dbra		d1,.5
;	rts
;
;;**********************************************************************
;;		ENDC		_SYS_S_
;;**********************************************************************
;
;