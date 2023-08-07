;**********************************************************************
;		IFND		_TASKMAN_S_
;**********************************************************************
;_TASKMAN_S_	=		0

;**********************************************
;		TASK (SEQUENCE MANAGER)
;**********************************************

;-----------------------------------------------
TASK_END		=	0
TASK_MAX_DURATION	=	$7fff

_TASK_Struct:		rsreset
_TASK_Main:		rs.l	1
_TASK_Vbl:		rs.l	1
_TASK_Duration:		rs.w	1
_TASK_Flag:		rs.w	1
_TASK_Struct_Size:	rs.b	1

TASK_Task:		ds.b	_TASK_Struct_Size
TASK_SeqPtr:		dc.l	0
TASK_SeqEndPtr:		dc.l	0
TASK_SeqIsRunning:	dc.w	0

;-----------------------------------------------
; A0: SequencePtr, A1: end of SequencePtr Set TASK_SeqIsRunning to 1
TASK_initSequence:
		move.w		#1,TASK_SeqIsRunning
		move.l		a1,TASK_SeqEndPtr
		lea		TASK_Task(pc),a1
		move.l		(a0)+,(a1)+
		move.l		(a0)+,(a1)+
		move.l		(a0)+,(a1)+
		move.l		a0,TASK_SeqPtr
		clr.w		VblStrobe
		rts

;-----------------------------------------------
; Clear TASK_SeqIsRunning and return d0=-1 when sequence is finished, return -1 when finish
TASK_runSequence:
		moveq		#0,d0
		lea		TASK_Task(pc),a0
		btst.b		#TASK_END,_TASK_Flag+1(a0)
		bne.s		.2
		subq.w		#1,_TASK_Duration(a0)
		bpl.s		.1
.2:
		move.l		TASK_SeqPtr(pc),a1
		cmp.l		TASK_SeqEndPtr(pc),a1
		bne.s		.0
		clr.w		TASK_SeqIsRunning
		moveq		#-1,d0
		rts
.0:
		move.l		(a1)+,(a0)+
		move.l		(a1)+,(a0)+
		move.l		(a1)+,(a0)+
		move.l		a1,TASK_SeqPtr	
.1:
		rts

;-----------------------------------------------
; Task call macro, \1: _TASK_Main or _TASK_Vbl, return d0=-1 if seq finished
TASK_CALL:	macro
		ifeq		\1-_TASK_Vbl
		addq.w		#1,VblStrobe
		endc
		tst.w		TASK_SeqIsRunning
		bne.s		.TASK_CUR
		moveq		#-1,d0
		bra.s		.TASK_ENDCALL
.TASK_CUR:	move.l		TASK_Task+\1(pc),d0
		beq.s		.TASK_ENDCALL
		move.l		d0,a0
		jsr		(a0)
		moveq		#0,d0
.TASK_ENDCALL:		
		endm

;-----------------------------------------------
; Get current countdown, Return in \1 
TASK_GET_TIME:	macro
		move.w		TASK_Task+_TASK_Duration,\1
		endm

;-----------------------------------------------
; Set current task, \1: _TASK_Main or _TASK_Vbl \2: adresse ptr, can be #NULL
TASK_SET:	macro
		move.l		\2,TASK_Task+\1
		endm
		
;-----------------------------------------------
; Set current task, \1: _TASK_Main or _TASK_Vbl \2: adresse ptr, can be #NULL
TASK_GET:	macro
		move.l		TASK_Task+\1,\2
		endm
		
;-----------------------------------------------
; Macro used to force next task
TASK_NEXT:	macro
		bset.b		#TASK_END,TASK_Task+_TASK_Flag+1
		endm

;-----------------------------------------------
; Helper to push Task structure
TASK_MAKE:	macro
		dc.l		\1,\2
		dc.w		\3,\4
		endm

;-----------------------------------------------
WAIT_VBL:	macro
		clr.w		VblStrobe
.WAIT_VBL_LOOP\@:
		tst.w		VblStrobe
		beq.s		.WAIT_VBL_LOOP\@
		endm

;-----------------------------------------------
STORBE_VBL:	macro
		addq.w		#1,VblStrobe
		endm

;-----------------------------------------------
VblStrobe:	dc.w		0

;**********************************************************************
;		ENDC		_TASKMAN_S_
;**********************************************************************
