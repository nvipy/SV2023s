;**********************************************************************
;		IFND		_CKFDRL_S_
;**********************************************************************
;_CKFDRL_S_	=		0
;-----------------------------------------------
; CROSS KEYFRAMES DIGITS RUN LENGHT
; Format
; Header
;  .L:    File size
;  .B:    keyframes count 
;  .B[3]: RLE Code size in bytes
;  .L:    RLE Code count
;
; RLE Codes table
;  .B[]:  RLE codes
;    Bits: 7.6.543210 76543210
;          | | ====== ======== 
;          | |   |       |
;          | |   |       +8 bits : extra length: extend to 14 bits length 
;          | |   |
;          | |   +6 bits length
;          | |
;          | +Select direct copy or repeat (0 = copy, 1 = repeat)
;          | 
;          +Select 6 or 14 bits length (0 = 6bits,1 = 14bits)
;          
; Digits array
;  .B[]:  4 bits Left and 4 bits right digits
;    Bits: 7654 3210
;          ==== ====
;           |    |
;           |    +second digit (color index frame 1)
;           |
;           + first digit (color index frame 2)
;
; RPK_MAX_FRAMES = max keyframes in the sequence, needs to generate unrolled loop codes.
;

; TODO: protect main call with movems

RPK_MAX_FRAMES	=	40
RPK_depack:		; A0 = rle data ptr, A2 = dst buffer ptr, D1 = frame byte size 
	movem.l		d0/d2-d7/a1/a3-a6,-(sp)
	addq.l		#4,a0			; all data size
	moveq		#0,d6
	move.b		(a0),d6			; d6 = framecount-1
	move.w		d6,d3
	move.l		d6,d0
	addq.w		#1,d0
	mulu		d1,d0
	move.l		d0,a4			; a4 = dest size (all frames)
	lea		-1(a4),a3
	move.l		(a0)+,d0		; rle code size  (in bytes)
	move.l		(a0)+,d7		; rle code count (in rle codes)
	and.l		#$00ffffff,d0
	lea		(a0,d0.l),a5		; digits ptr
	moveq		#0,d5			; byte digits buffer
	moveq		#0,d4			; Hi/Lo state (0,-1)
	move.l		d1,a1			; frame byte size, use to go to next frame

rleLoop:
	move.b		(a0)+,d0		; Rle code
	move.b		d0,d1
	bmi.s		.wordLen		; jmp if word lenght 
	and.w		#$3f,d1			; get byte lenghtcode
	add.b		d0,d0			; test if fill or duplicate
	bpl		copyDigits
	bra.s		dupDigits
.wordLen:
	move.b		d1,-(sp)		; lsl.w	#8,d1
	move.w		(sp)+,d1		; 
	move.b		(a0)+,d1		; 
	and.w		#$3fff,d1		; get word lenghtcode
	add.b		d0,d0			; test if fill or duplicate
	bpl		copyDigits

;......................................
; Duplicate a digit from the stream
;......................................
dupDigits:
	tst.w		d4
	bmi		dupLoDigits

dupHiDigits:
	tst.w		d5
	bmi.s		.loDigit
.hiDigit:
	moveq		#-1,d5
	move.b		(a5)+,d5
	moveq		#$fffffff0,d0
	and.b		d5,d0
	bra.s		dupHiDigitsLoop
.loDigit:
	move.b		d5,d0
	lsl.b		#4,d0
	moveq		#0,d5

dupHiDigitsLoop:
	cmp.w		d6,d1
	bpl		.noShortDupHiLoop
	sub.w		d1,d6
	subq.w		#1,d6
.shortDupHiLoop:
	moveq		#RPK_MAX_FRAMES-1,d2
	sub.w		d1,d2
	add.w		d2,d2
	add.w		d2,d2
	jmp		.unrollShortHiDup(pc,d2.w)
.unrollShortHiDup:
	rept		RPK_MAX_FRAMES
	move.b		d0,(a2)
	add.l		a1,a2
	endr
	dbra		d7,rleLoop
	bra		RPK_endDepack
	;rts
.noShortDupHiLoop:	
	sub.w		d6,d1
	moveq		#RPK_MAX_FRAMES-1,d2
	sub.w		d6,d2
	add.w		d2,d2
	add.w		d2,d2
	jmp		.unrollHiDup(pc,d2.w)
.unrollHiDup:
	rept		RPK_MAX_FRAMES	; set max depth define !
	move.b		d0,(a2)
	add.l		a1,a2
	endr
	move.w		d3,d6
	sub.l		a4,a2
	moveq		#-1,d4
	lsr.b		#4,d0
	dbra		d1,dupLoDigitsLoop
	dbra		d7,rleLoop
	bra		RPK_endDepack

dupLoDigits:
	tst.w		d5
	bmi.s		.loDigit
.hiDigit:
	moveq		#-1,d5
	move.b		(a5)+,d5
	move.b		d5,d0
	lsr.b		#4,d0
	bra.s		dupLoDigitsLoop
.loDigit:
	and.w		#$f,d5
	move.b		d5,d0
dupLoDigitsLoop:
	cmp.w		d6,d1
	bpl		.noShortDupLoLoop
	sub.w		d1,d6
	subq.w		#1,d6
.shortDupLoLoop:
	moveq		#RPK_MAX_FRAMES-1,d2
	sub.w		d1,d2
	add.w		d2,d2
	add.w		d2,d2
	jmp		.unrollShortLoDup(pc,d2.w)
.unrollShortLoDup:
	rept		RPK_MAX_FRAMES	; set max depth define !
	or.b		d0,(a2)
	add.l		a1,a2
	endr
	dbra		d7,rleLoop
	bra		RPK_endDepack

.noShortDupLoLoop:	
	sub.w		d6,d1
	moveq		#RPK_MAX_FRAMES-1,d2
	sub.w		d6,d2
	add.w		d2,d2
	add.w		d2,d2
	jmp		.unrollLoDup(pc,d2.w)
.unrollLoDup:
	rept		RPK_MAX_FRAMES	; set max depth define !
	or.b		d0,(a2)
	add.l		a1,a2
	endr
	move.w		d3,d6
	sub.l		a3,a2
	moveq		#0,d4
	lsl.b		#4,d0
	dbra		d1,dupHiDigitsLoop
	dbra		d7,rleLoop
	bra		RPK_endDepack

;......................................
; Copy digits from the stream
;......................................
copyDigits:
	moveq		#$f,d2
	tst.w		d4
	bmi.s		copyLoDigitsLoop

copyHiDigitsLoop:
	tst.w		d5
	bmi.s		hiCopyLoDigit
hiCopyHiDigit:
	move.b		(a5)+,d5
	moveq		#$fffffff0,d0
	and.b		d5,d0
	move.b		d0,(a2)
	add.l		a1,a2
	dbra		d6,noHiCopyHiFrameBack
	move.w		d3,d6
	sub.l		a4,a2
	dbra		d1,loCopyLoDigit
	moveq		#-1,d4
	or.w		#$ff00,d5
	dbra		d7,rleLoop
	bra		RPK_endDepack

noHiCopyHiFrameBack:
	dbra		d1,hiCopyLoDigit
	moveq		#0,d4
	or.w		#$ff00,d5
	dbra		d7,rleLoop
	bra		RPK_endDepack

hiCopyLoDigit:
	lsl.b		#4,d5
	move.b		d5,(a2)
	add.l		a1,a2
	dbra		d6,noHiCopyLoFrameBack
	move.w		d3,d6
	sub.l		a4,a2
	dbra		d1,loCopyHiDigit
	moveq		#-1,d4
	moveq		#0,d5
	dbra		d7,rleLoop
	bra.s		RPK_endDepack

noHiCopyLoFrameBack:
	dbra		d1,hiCopyHiDigit
	moveq		#0,d4
	moveq		#0,d5
	dbra		d7,rleLoop
	bra.s		RPK_endDepack

copyLoDigitsLoop:
	tst.w		d5
	bmi.s		loCopyLoDigit
loCopyHiDigit:
	move.b		(a5)+,d5
	move.b		d5,d0
	lsr.b		#4,d0
	or.b		d0,(a2)
	add.l		a1,a2
	dbra		d6,noLoCopyHiFrameBack
	move.w		d3,d6
	sub.l		a3,a2
	dbra		d1,hiCopyLoDigit
	moveq		#0,d4
	or.w		#$ff00,d5
	dbra		d7,rleLoop
	bra.s		RPK_endDepack

noLoCopyHiFrameBack:
	dbra		d1,loCopyLoDigit
	moveq		#-1,d4
	or.w		#$ff00,d5
	dbra		d7,rleLoop
	bra.s		RPK_endDepack

loCopyLoDigit:
	and.w		d2,d5
	or.b		d5,(a2)
	add.l		a1,a2
	dbra		d6,noLoCopyLoFrameBack
	move.w		d3,d6
	sub.l		a3,a2
	dbra		d1,hiCopyHiDigit
	moveq		#0,d4
	dbra		d7,rleLoop
	bra.s		RPK_endDepack

noLoCopyLoFrameBack:
	dbra		d1,loCopyHiDigit
	moveq		#-1,d4
	dbra		d7,rleLoop
	bra		RPK_endDepack

;......................................
RPK_endDepack:
	movem.l		(sp)+,d0/d2-d7/a1/a3-a6
	rts

;**********************************************************************
;		ENDC		_CKFDRL_S_
;**********************************************************************
