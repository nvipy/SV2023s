;-------------------------------

IMG_CENTER		=	$00
IMG_TOP			=	$20
IMG_BOTTOM		=	$10
IMG_LEFT		=	$80
IMG_RIGHT		=	$40
IMG_TOPLEFT		=	IMG_TOP!IMG_LEFT

IMG_ANCHOR_MASK		=	$f0
IMG_DIRECT_CMAP		=	$01
IMG_DIRECT_CMAP_B	=	0

IMG_GCMAP_SIZE		=	256*2

			rsreset
_IMG_WordWidth:		rs.w		1
_IMG_Height:		rs.w		1
IMG_HStruct_Size:	rs.b		0

			rsreset
			rs.b		IMG_HStruct_Size
_IMG_Cmap:		rs.w		16
IMG_Struct_Size		rs.b		0

			rsreset
			rs.b		IMG_HStruct_Size
_IMG_CmapLength:	rs.w		1
_IMG_GCmapLength:	rs.w		1
_IMG_GCmaps:		rs.w		0
IMG_XStruct_Size	rs.b		1

			rsreset
_IMGFILE_WordWidth:	rs.b		1
_IMGFILE_Height:	rs.b		1
_IMGFILE_Type:		rs.b		1	; 'C'=Chunky, 'B'=Bitmap
_IMGFILE_CmapLenght:	rs.b		1
_IMGFILE_Cmap:		rs.w		16
IMGFILE_Struct_Size	rs.b		0

;-----------------------------------------------------------------------------------------------------------------------------------
IMG_getInfo:		; A0 = image data, A6 = returned image struct, Return D3.b = type (C/B), d4 = wordwidth, d5 = height, use d7
	clr.w		d4
	move.b		(a0)+,d4		; width in word
	bmi.s		.extendHeader
	move.w		d4,_IMG_WordWidth(a6)
	clr.w		d5
	move.b		(a0)+,d5
	move.w		d5,_IMG_Height(a6)	; height

	move.b		(a0)+,d3		; type
	moveq		#0,d7
	move.b		(a0)+,d7		; cmap len
	lea		_IMG_Cmap(a6),a2
.4:
	move.w		(a0)+,(a2)+
	dbra		d7,.4

	and.w		#IMG_ANCHOR_MASK,d2

	rts

.extendHeader:
	move.b		(a0)+,d4		; width in word
	move.w		d4,_IMG_WordWidth(a6)
	move.w		(a0)+,d5
	move.w		d5,_IMG_Height(a6)	; height (16bits)
	addq.l		#1,a0			; skip 'X'
	moveq		#0,d7
	move.b		(a0)+,d7
	move.w		d7,_IMG_CmapLength(a6)
	mulu		d5,d7			; cmap id len
	move.w		(a0)+,d6		; Gmap len
	move.w		d6,_IMG_GCmapLength(a6)	; Gmap len

	move.l		a0,a2
	movem.w		d0-d2,-(sp)
	move.w		d6,d0
	subq.w		#1,d0
.convloop:
	move.w		(a2),d1
	move.w		d1,d2
	and.w		#$111,d1
	and.w		#$eee,d2
	lsl.w		#3,d1
	lsr.w		#1,d2
	or.w		d2,d1
	move.w		d1,(a2)+
	dbra		d0,.convloop
	movem.w		(sp)+,d0-d2

	lea		_IMG_GCmaps(a6),a2

	btst		#IMG_DIRECT_CMAP_B,d2
	bne.s		.directCmap

	subq.w		#1,d6
.gcmaploop:
	move.w		(a0)+,(a2)+
	dbra		d6,.gcmaploop

	subq.l		#1,d7
.cmapidloop:
	moveq		#0,d6
	move.b		(a0)+,d6
	add.w		d6,d6
	move.w		d6,(a2)+
	dbra		d7,.cmapidloop
	bra.s		.end

.directCmap:
	move.l		a0,a3
	add.w		d6,d6
	add.w		d6,a0

	subq.l		#1,d7
.cmaploop:
	moveq		#0,d6
	move.b		(a0)+,d6
	add.w		d6,d6
	move.w		(a3,d6.w),(a2)+
	dbra		d7,.cmaploop

.end:
	and.w		#IMG_ANCHOR_MASK,d2
	move.b		#'C',d3			; fake type
	rts

;-----------------------------------------------------------------------------------------------------------------------------------
IMG_justify:		; private
	move.w		d2,d6
	move.w		d0,d2	; screen word width
	add.w		d0,d0	; screen byte width
	sub.w		d4,d2	; word width mod = screen word width - image word width

	add.b		d6,d6	;
	bcc.s		.noLeft
	;add.w		d2,d2	; byte width mod
	lsl.w		#3,d2	; byte width mod
	bra.s		.addwmod
.noLeft:
	add.b		d6,d6	;
	bcc.s		.noRight
	;add.w		d2,d2	; byte width mod
	lsl.w		#3,d2	; byte width mod
	add.w		d2,a1	; add word width mod (byte mod/2)
	bra.s		.addwmod
.noRight:			; w center !
	lsl.w		#2,d2	; byte width mod
	add.w		d2,a1	; add word width mod (byte mod/2)
	add.w		d2,d2	; byte width mod
.addwmod:
	move.w		d2,a2	; width mod 

	move.w		d1,d2	; screen height
	sub.w		d5,d2	; height mod = screen height - image height

	add.b		d6,d6	;
	bcs.s		.endaddhmod
.noTop:
	add.b		d6,d6	;
	bcc.s		.noBottom
	bra.s		.endaddhmod
	mulu		d0,d2	; top.y * screen raster width in byte
	add.w		d2,a1	; add height mod/2
.noBottom:		; h center !
	lsr.w		#1,d2	; height mod/2
	mulu		d0,d2	; height mod/2 * screen raster width in byte
	add.w		d2,a1	; add height mod/2
.endaddhmod:

	;move.w		d1,d3	; 
	;mulu		d0,d3	; screen size

	subq.w		#1,d4	; image width in word - 1
	move.l		d4,a3	; image width in word - 1
	subq.w		#1,d5	; image height - 1
	move.w		d5,d1	; image height - 1
	rts

;-----------------------------------------------------------------------------------------------------------------------------------
IMG_get4Bits:		; d0 = dest word width, d1 = dest height, d2 = flag, a0 = image data, a1 = screens destinations, a6: image struct
	bsr		IMG_getInfo

	cmp.b		#'C',d3
	beq.s		.3
	rts
.3:
	move.l		a6,-(sp)

	bsr		IMG_justify

	;lea		(a1,d3.l),a4
	;lea		(a4,d3.l),a5
	;lea		(a5,d3.l),a6
.5:
	move.w		a3,d0
.6:
	moveq		#3,d2
.7:
	move.w		(a0)+,d3
	rept		4
	add.w		d3,d3
	addx.w		d7,d7
	add.w		d3,d3
	addx.w		d6,d6
	add.w		d3,d3
	addx.w		d5,d5
	add.w		d3,d3
	addx.w		d4,d4
	endr
	dbra		d2,.7
	movem.w		d4-d7,(a1)
	addq.l		#8,a1
	dbra		d0,.6
	add.l		a2,a1
	dbra		d1,.5

	move.l		(sp)+,a6
	rts

;-----------------------------------------------------------------------------------------------------------------------------------
IMG_get2Bits:		; d0 = dest word width, d1 = dest height, d2 = flag, a0 = image data, a1 = screens destinations, a6: image struct
	bsr		IMG_getInfo

	cmp.b		#'C',d3
	beq.s		.3
	rts
.3:
	bsr		IMG_justify

	;lea		(a1,d3.w),a4
.5:
	move.w		a3,d0
.6:
	moveq		#1,d2
.7:
	move.w		(a0)+,d3
	rept		8
	add.w		d3,d3
	addx.w		d5,d5
	add.w		d3,d3
	addx.w		d4,d4
	endr
	dbra		d2,.7
	movem.w		d4/d5,(a1)
	addq.l		#8,a1
	dbra		d0,.6
	add.l		a2,a1
	dbra		d1,.5
	rts

;-----------------------------------------------------------------------------------------------------------------------------------
IMG_get3Bits:		; d0 = dest word width, d1 = dest height, d2 = flag, a0 = image data, a1 = screens destinations, a6: image struct
	bsr		IMG_getInfo

	cmp.b		#'C',d3
	beq.s		.3
	rts
.3:
	move.l		a6,-(sp)

	bsr		IMG_justify

	;lea		(a1,d3.w),a4
	;lea		(a4,d3.w),a5
.5:
	move.w		a3,d0
.6:
	moveq		#3,d2
.7:
	move.w		(a0)+,d3
	rept		4
	add.w		d3,d3
	add.w		d3,d3
	addx.w		d6,d6
	add.w		d3,d3
	addx.w		d5,d5
	add.w		d3,d3
	addx.w		d4,d4
	endr
	dbra		d2,.7
	movem.w		d4-d6,(a1)
	addq.l		#8,a1
	dbra		d0,.6
	add.l		a2,a1
	dbra		d1,.5

	move.l		(sp)+,a6
	rts
