
;-----------------------------------------------
MATH_random:		; RETURN D0 = rnd number ; USE D1
	move.l		MATH_RandomSeed(pc),d0
	move.l		d0,d1
	swap		d0
	add.w		d0,d1
	roxr.l		#3,d1
	eor.l		d1,d0
	not.l		d1
	move.l		d1,MATH_RandomSeed
	rts

MATH_RandomSeed:	dc.l	$deffac1e

;------------------------------------------------------------------
; A0 = destination, sinus word array ptr
; D0 = destination depth (length = 2^depth)
; D1 = phase [-32768,32768[ : [-PI/2,PI/2[, use -32768 for Sinus, use 0 for Cosinus
; RETURN A1 = end of array
MATH_makeSins:
        moveq		#1,d4
        lsl.w		d0,d4        	; half tab ofs
        lea		(a0,d4.w),a1    ; half tab ptr
        lsr.w		d4        	; count
        subq.w		#1,d4        	; count-1
        moveq		#2,d3
        swap		d3
        lsr.l		d0,d3        	; step = 265536 / 2^depth
.nextSin:
        move.w		d1,d0
        muls		d0,d0
        swap		d0
        move.w		#3516*4,d2
        muls		d0,d2
        swap		d2
        neg.w		d2
        add.w		#19900,d2
        muls		d0,d2
        swap		d2
        neg.w		d2
        add.w		#4096,d2
        move.w		d2,(a0)+
        neg.w		d2
        move.w		d2,(a1)+
        add.w		d3,d1
        dbra		d4,.nextSin
        rts
