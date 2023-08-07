;-----------------------------------------------
; Simple YM Player
;-----------------------------------------------
YM_REG_COUNT	=	14

YMBaseRegPtr:		dc.l	0
YMCurRegPtr:		dc.l	0
YMMaxFrameCount:	dc.l	0
YMCurFrame:		dc.l	0

;-----------------------------------------------
YM_init:		; A0 = music ptr
	move.l		12(a0),YMMaxFrameCount	; store number of frames
	add.l		#34,a0                   ; beginning of text
	moveq		#3-1,d7
.skips:
	move.b   	(a0)+,d0                 ; search for 0s
	bne.s     	.skips
	dbra		d7,.skips

	move.l  	a0,YMBaseRegPtr
	move.l  	a0,YMCurRegPtr
	clr.l		YMCurFrame
	rts

;-----------------------------------------------
YM_refresh:
        lea		$ffff8800.w,a1
        lea		2(a1),a2
        move.l  	YMCurRegPtr(pc),a0		; pointer to current music data
        move.l		YMMaxFrameCount(pc),d1
        moveq.l 	#0,d0				; first yammy register
        moveq		#YM_REG_COUNT-1,d7
.regloop:
	move.b		d0,(a1)
	move.b		(a0),(a2)
	addq.b		#1,d0
	add.l		d1,a0
	dbra		d7,.regloop
	
        addq.l  	#1,YMCurRegPtr              ; next set of registers
        move.l		YMCurFrame(pc),d0
        addq.l		#1,d0
        cmp.l		d1,d0
        bne.s		.noend
        moveq		#0,d0
        move.l		YMBaseRegPtr(pc),YMCurRegPtr
.noend:
        move.l		d0,YMCurFrame
        rts

;-----------------------------------------------
YM_stop:
        lea		$ffff8800.w,a1
        lea		2(a1),a2
        move.b		#8,(a1)
        clr.b		(a2)
        move.b		#9,(a1)
        clr.b		(a2)
        move.b		#10,(a1)
        clr.b		(a2)
        rts
