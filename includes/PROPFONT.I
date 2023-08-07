

;	lea		FText,a0
;	lea		Screen+322,a1
;	moveq		#WSCREEN/8,d0
;	moveq		#-1,d1
;	bsr		PROPFONT_print		; A0 = string, A1 = destination, D0 = dest width, D1 = string length, Return D3 = chr count

;	lea		VSCROLL_Text,a0
;	moveq		#20-1,d7
;	bsr		VSCROLL_drawPage	; A0 = txt, D7 line count -1

;------------------------------------------------------------------
;VSCROLL_drawPage:	; A0 = txt, D7 line count -1
;	pea		Screen
;	move.l		a0,a6
;.lineloop:
;	move.w		#WSCREEN,d3
;	bsr		PROPFONT_getLineLen	; A0 = string, D0 = end of string symbol, Return D2 = string length in pixels, use a0,a1,d0,d1
;	move.w		d0,d1
;	beq.s		.nextline
;	move.w		#WSCREEN/8,d0
;	move.l		a6,a0
;	add.w		d1,a6
;	move.l		(sp),a1
;	moveq		#PROPFONT_HEIGHT-1,d2
;	bsr		PROPFONT_print		; A0 = string, A1 = destination, D0 = dest width, D1 = string length, D2 = font height-1, Return D3 = chr count
;.nextline:
;	add.l		#WSCREEN*(PROPFONT_HEIGHT+1)/8,(sp)
;	add.w		#1,a6
;	move.l		a6,a0
;	dbra		d7,.lineloop
;	addq.w		#4,sp
;	rts

;------------------------------------------------------------------
PROPFONT_HEIGHT			=	8
PROPFONT_InvAscii:		ds.l	256
PROPFONT_FontImage:		dc.l	0
PROPFONT_FontTextPtrs:		dc.l	0
;-----------------------------------------------
PROPFONT_initFontAndStrings:				; A0 = FontDesc data
	move.l		a0,a2
	bsr		RelocateCollection		; A0 = collection , return A0 = end of collection's refs table
	move.w		(a2)+,d6			; file count
	subq.w		#4,d6				; file count - 3 - 1
	
	move.l		(a2),PROPFONT_FontImage
	move.l		12(a2),PROPFONT_FontTextPtrs

	move.l		4(a2),a0			; ascii list (file1 ptr)
	move.l		8(a2),a4			; lens
	move.l		a4,d7				; 
	sub.l		a0,d7				; ascii list length
	subq.w		#1,d7				; ascii list length - 1
	lea		PROPFONT_InvAscii,a1		; inv ascii
	moveq		#0,d1				; 
.chrloop:
	moveq		#0,d0				; image offset = 0
	move.b		(a0)+,d0			; asciicode
	add.w		d0,d0				; index = asciicode * 2
	add.w		d0,d0				; index = asciicode * 4
	moveq		#0,d2				; length = 0
	move.b		(a4)+,d2			; length
	swap		d2				; len.????
	move.w		d1,d2				; len.ofs
	move.l		d2,(a1,d0.w)			; store chr image length.offset
	addq.w		#8,d1				; image offset += 8
	dbra		d7,.chrloop			;

	rts

;-----------------------------------------------
PROPFONT_print:		; A0 = string, A1 = destination, D0 = dest width, D1 = string length, D2 = font height-1, Return D3 = chr count
	move.w		d2,-(sp)
	move.l		a1,d2
	and.w		#1,d2
	sub.w		d2,a1
	lsl.w		#3,d2

	lea		PROPFONT_InvAscii,a2
	move.l		PROPFONT_FontImage,a3
	moveq		#0,d3
	subq.w		#1,d1
.chrloop:
	moveq		#0,d4
	move.b		(a0)+,d4
	beq.s		.end
	cmp.b		#$a,d4
	beq.s		.endloop
	cmp.b		#$d,d4
	beq.s		.endloop
	addq.w		#1,d3
	add.w		d4,d4
	add.w		d4,d4
	move.l		(a2,d4.w),d4	; ofs
	lea		(a3,d4.w),a4
	swap		d4		; len

	moveq		#7,d5		; 7
	and.w		d2,d5		; x = px & 7
	move.w		d4,d6		; len
	add.w		d5,d6		; e = len+px

	cmp.w		#8,d6
	bgt.s		.testDrawWord

	move.w		d2,d6
	lsr.w		#3,d6
	lea		(a1,d6.w),a5

	swap		d3
	move.w		(sp),d3
.bytecopy:
	move.b		(a4)+,d6
	lsr.b		d5,d6		; motif >> x
	or.b		d6,(a5)
	add.w		d0,a5
	dbra		d3,.bytecopy
	swap		d3

	add.w		d4,d2
	addq.w		#1,d2
.endloop:	
	dbra		d1,.chrloop
.end:
	addq.l		#2,sp	
	rts

.testDrawWord:
	moveq		#-16,d6
	and.w		d2,d6
	lsr.w		#3,d6
	lea		(a1,d6.w),a5

	moveq		#15,d5		; 15
	and.w		d2,d5		; x = px & 15
	move.w		d4,d6		; len
	add.w		d5,d6		; e = len+px

	cmp.w		#16,d6
	bgt.s		.drawDWord

	subq.w		#8,d5
	neg.w		d5

	swap		d3
	move.w		(sp),d3
.wordcopy:
	moveq		#0,d6
	move.b		(a4)+,d6
	lsl.w		d5,d6		; motif >> x
	or.w		d6,(a5)
	add.w		d0,a5
	dbra		d3,.wordcopy
	swap		d3

	add.w		d4,d2
	addq.w		#1,d2
	dbra		d1,.chrloop
	addq.l		#2,sp	
	rts

.drawDWord:
	moveq		#-16,d6
	and.w		d2,d6
	lsr.w		#3,d6
	lea		(a1,d6.w),a5

	moveq		#15,d5		; 31
	and.w		d2,d5		; x = px & 31

	sub.w		#24,d5
	neg.w		d5

	swap		d3
	move.w		(sp),d3
.dwordcopy:
	moveq		#0,d6
	move.b		(a4)+,d6
	lsl.l		d5,d6		; motif >> x
	or.l		d6,(a5)
	add.w		d0,a5
	dbra		d3,.dwordcopy
	swap		d3

	add.w		d4,d2
	addq.w		#1,d2
	dbra		d1,.chrloop
	addq.l		#2,sp	
	rts

;-----------------------------------------------
PROPFONT_getStrLen:	; A0 = string, D0 = end of string symbol, Return D2 = string length in pixels, use a0,a1,d0,d1
	lea		PROPFONT_InvAscii,a1	; len.ofs
.loop:
	moveq		#0,d1
	move.b		(a0)+,d1
	cmp.b		#$a,d1
	beq.s		.loop
	tst.w		d1
	beq.s		.endloop
	cmp.b		#$d,d1
	beq.s		.endloop
	cmp.b		d0,d1
	beq.s		.endloop
	add.w		d1,d1
	add.w		d1,d1
	add.w		(a1,d1.w),d2
	addq.w		#1,d2
	bra.s		.loop
.endloop:
	rts

;-----------------------------------------------
PROPFONT_getLineLen:	; A0 = string, Return D0 = string line length, D3 = line lenght in pixel, use d0,d1,d2,a0,a1,a2
	move.l		a0,-(sp)
	moveq		#0,d2
.loop:
	move.b		(a0)+,d1
	cmp.b		#$a,d1
	beq.s		.loop
	cmp.b		#0,d1
	beq.s		.endloop
	cmp.b		#$d,d1
	beq.s		.endloop
	cmp.b		#$20,d1
	beq.s		.loop
.strlen:
	subq.l		#1,a0
	move.l		a0,a2
	moveq		#$20,d0
	bsr		PROPFONT_getStrLen		; A0 = string, D0 = end of string symbol, Return D2 = string length in pixels, use a0,a1,d0,d1
	cmp.w		d3,d2
	bgt.s		.endloop2			; ble ?
	subq.l		#1,a0
	add.w		PROPFONT_InvAscii+$20*4,d2	; space len
	addq.w		#1,d2
	bra.s		.loop
.endloop2:
	subq.w		#1,a2
	move.l		a2,d0
	sub.l		(sp)+,d0
	rts
.endloop:
	subq.w		#1,a0
	move.l		a0,d0
	sub.l		(sp)+,d0
	rts

