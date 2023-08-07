;**********************************************************************
;		IFND		_BIOS_S_
;**********************************************************************
;_BIOS_S_	=		0

;-----------------------------------------------
AvailableMemory:
	move.l		#-1,-(sp)
	move.w		#$48,-(sp)
	trap		#1
	addq.l		#6,sp
	rts

;-----------------------------------------------
StopMFP:
	move.w	#$2700,sr
	move.b	$fffffa07.w,IntEnableA
	move.b	$fffffa09.w,IntEnableB
	clr.b	$fffffa07.w
	clr.b	$fffffa09.w
	move.w	#$2300,sr
	rts

RestoreMFP:
	move.w	#$2700,sr
	move.b	IntEnableA,$fffffa07.w
	move.b	IntEnableB,$fffffa09.w
	move.w	#$2300,sr
	rts

IntEnableA:	dc.b 0
IntEnableB:	dc.b 0

;-----------------------------------------------
SetVbl:		;A0=vbl
	move.w	#$2700,sr
	move.l	$70.w,oldVbl
	move.l	a0,$70.w			
	move.w	#$2300,sr		
	rts

ResetVbl:
	move.w #$2700,sr
	move.l oldVbl(pc),$70.w			
	move.w #$2300,sr		
	rts

oldVbl dc.l	0


;;-----------------------------------------------
SetSysVbl:		;A0=vbl
	move.w	#$2700,sr
	move.l	$4d2.w,oldSysVbl
	move.l	a0,$4d2.w			
	move.w	#$2300,sr		
	rts

ResetSysVbl:
	move.w #$2700,sr
	move.l oldSysVbl(pc),$4d2.w			
	move.w #$2300,sr		
	rts

oldSysVbl dc.l	0

;-----------------------------------------------
SetHbl:		; a0 = hbl ptr, use a5
	move    	#$2700,sr
	lea		$fffffa00.w,a5
	move.l 		a0,$120.w
	bset		#0,$07(a5)
	bset		#0,$13(a5)
	clr.b 		$1b(a5)
	move    	#$2300,sr
	rts

SaveHbl:	; use a4,a5
	lea		$fffffa00.w,a5
	lea		oldIntAEna(pc),a4
	move.b		$07(a5),(a4)+
	move.b		$13(a5),(a4)+
	move.b 		$1b(a5),(a4)+
	move.b 		$21(a5),(a4)+
	move.b 		$0f(a5),(a4)+
	move.b 		$1b(a5),(a4)+
	move.l 		$120.w,(a4)+
	rts

RestoreHbl:	; use a4,a5
	move    	#$2700,sr
	lea		$fffffa00.w,a5
	lea		oldIntAEna(pc),a4
	clr.b 		$1b(a5)
	move.b		(a4)+,$07(a5)
	move.b		(a4)+,$13(a5)
	move.b 		(a4)+,$1b(a5)
	move.b 		(a4)+,$21(a5)
	move.b 		(a4)+,$0f(a5)
	move.b 		(a4)+,$1b(a5)
	move.l 		(a4)+,$120.w
	move    	#$2300,sr
	rts


;-----------------------------------------------
BIOS_WaitVbl:
	move.w	#37,-(sp)
	trap	#14
	addq.l	#2,sp
	rts

;-----------------------------------------------
SetSuper:  
	clr.l	-(a7)                   ; clear stack
	move.w  #32,-(a7)               ; prepare for user mode
	trap    #1                      ; call gemdos
	addq.l  #6,a7                   ; clean up stack
	move.l  d0,old_stack            ; backup old stack pointer

	rts

SetUser:
        move.l  old_stack,-(a7)         ; restore old stack pointer
        move.w  #32,-(a7)               ; back to user mode
        trap    #1                      ; call gemdos
        addq.l  #6,a7                   ; clear stack
  
        rts

old_stack       dc.l    0



;-----------------------------------------------
SaveScreen:

	move.b	$ffff820a.w,old_vfrq
	or.b	#2,$ffff820a.w

	lea	$ffff8240.w,a0
	lea	old_palette(pc),a1	; palette pointer in a0
	bsr.s	CopyColors

        move.w  #2,-(a7)                ; get physbase
        trap    #14
        addq.l  #2,a7
        move.l  d0,old_screen           ; save old screen address

        move.w  #4,-(a7)                ; get resolution
        trap    #14
        addq.l  #2,a7
        move.w  d0,old_resolution       ; save resolution

        move.w  #0,-(a7)                ; low resolution
        move.l  #-1,-(a7)               ; keep physbase
        move.l  #-1,-(a7)               ; keep logbase
        move.w  #5,-(a7)                ; change screen
        trap    #14
        add.l   #12,a7  

        rts

RestoreScreen:
        move.w  old_resolution(pc),d0       ; res in d0
        move.w  d0,-(a7)                ; push resolution
        move.l  old_screen(pc),d0           ; screen in d0
        move.l  d0,-(a7)                ; push physbase
        move.l  d0,-(a7)                ; push logbase
        move.w  #5,-(a7)                ; change screen
        trap    #14
        add.l   #12,a7

	lea	old_palette(pc),a0	; palette pointer in a0
	lea	$ffff8240.w,a1
	bsr.s	CopyColors

	move.b	old_vfrq(pc),$ffff820a.w

	rts

CopyColors:
	rept	8
	move.l	(a0)+,(a1)+
	endr
	rts

;-----------------------------------------------

oldIntAEna:	dc.b	0
oldIntAMsk:	dc.b	0
oldTBCtrl:	dc.b	0
oldTBData:	dc.b	0
oldTB0f:	dc.b	0
oldTB1b:	dc.b	0
old_vfrq:	dc.b	0
		even
oldHbl:		dc.l	0
old_palette     ds.l    8
old_resolution  dc.w    0
old_screen      dc.l    0

























;-----------------------------------------------
;	move.l		#$eeeeeeee,d4
;	move.l		d0,d2	; A = 8 x 4 bits vector
;	move.l		d1,d3	; B = 8 x 4 bits vector
;	and.l		d4,d0	; remove lowest bits from A
;	and.l		d4,d1	; remove lowest bits from B
;	sub.l		d1,d3	; retrieve lowest bits from A
;	and.l		d3,d2	; carries from lowest bits of A+B
;	add.l		d1,d0	; A+B
;	roxr.l		#1,d0	; (A+B)/2
;	add.l		d2,d0	; (A+B)/2 + carries vector


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

;-----------------------------------------------
;SBlit:					
;	lea		$ffff8a20.w,a6	; First register needed by us
;	move.l		d0,(a6)+	; SrcXinc.SrcYinc
;	move.l		a0,(a6)+	; SrcPtr
;	move.l		d2,(a6)+	; Fmsk.Mmsk
;	move.w		d2,(a6)+	; Lmsk
;	move.l		d1,(a6)+	; DstXinc.DstYinc
;	move.l		a1,(a6)+	; DstPtr
;	move.l		d3,(a6)+	; Width.Height
;	move.l		d4,(a6)
;	addq.l		#2,a6
;.restart:
;	bset.b		d5,(a6)		; Restart BLiTTER and test the BUSY
;	nop				; flag state.  The "nop" is executed
;	bne.s  		.restart	; prior to the BLiTTER restarting.
;					; Quit if the BUSY flag was clear.  
;	rts

;**********************************************************************
;		ENDC		_BIOS_S_
;**********************************************************************
