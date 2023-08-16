; The AY-3-8910 offers three sound channels, which may be set to produce a square wave, a noise signal, or both at once. Square waves are configured much like the SN76489, and with the Atari’s 2Mhz clock, the formula for a target frequency is V=125,000/f. This results in a 12-bit value that goes into a pair of registers (0-1 for channel A, 2-3 for B, and 4-5 for C.)
; To play Middle C (261.5 Hz) at full volume, we would first divide it into 125,000 for a register value of 478 (01DE hex). We set the frequency by writing $DE to register 0, $01 to register 1

DELAY_BETWEEN_NOTES = 8
NOTES_TONE_INTERVAL = 160; 128
CHORD_START			 = 20
SNDFADEOUT 			= 290
STOP_NOISE			= 32*8
END_FADEOUT		    = 90

initSound:
    move.w     #7,(a0)
    move.b     (a0),sndRegSav+soundvars
initSoundEnd:
    ; init sound
    lea        $ffff8800,a0
    lea        2(a0),a1
    lea        soundvars,a2

	move.w	   #-2,prevNoteChan(a2)
    moveq      #7,d0
	clr.w	   chanAFreq(a2)
	clr.w	   noteCnter(a2)

    move.w     d0,noise(a2)
    clr.w      framecnt(a2)

	move.b	   #%1000000,d4
    move.b     #%10011100,d5
    clr.b      (a0)            	  ; channel A freq low
    move.b     d4,(a1)
    move.b     #1,(a0)            ; channel A freq hi
    move.b     d5,(a1)
    move.b     #2,(a0)            ; channel B freq low
    move.b     d4,(a1)
    move.b     #3,(a0)            ; channel B freq hi
    move.b     d5,(a1)
    move.b     #4,(a0)            ; channel C freq low
    move.b     d4,(a1)
    move.b     #5,(a0)            ; channel C freq hi
    move.b     d5,(a1)

    move.b     #11,(a0)           ; volume over time LOW
    move.b     #%1100,(a1)        ; volume over time
    move.b     #12,(a0)           ; volume over time HI
    move.b     #%1,(a1)           ; volume over time

    move.b     #13,(a0)           ; envelope
    move.b     #%1010,(a1)        ; sine

    move.b     #6,(a0)            ; NOISE
    move.b     #100,(a1)

    move.b     d0,(a0)            ; access Yamaha register 7
    move.b     #%111110,(a1)    ; turn on channel A, no noise

    move.b     #8,(a0)            ; channel A volume
    clr.b      (a1)

    rts



updateSound:
        lea        soundvars,a2
	    lea        $ffff8800,a0
	    lea        2(a0),a1
		moveq		#12,d3

        ; RAMP UP VOLUME
        move.w     framecnt(a2),d2
		move.w	   d2,d7
        addq.w     #1,d2
        move.w     d2,framecnt(a2)
		cmp.w	   #SNDFADEOUT,d2 ; fade out
		bge.b	   fadeout
        lsr.w      #4,d2
        addq.w     #4,d2 ; start volume
        cmp.w      d3,d2
        ble.b      noclampvol
        move.w     d3,d2
		bra.s	   noclampvol
fadeout:
		sub.w		#SNDFADEOUT,d2
		lsr.w		#2,d2
		sub.w		d3,d2
		bge.b		zerosnd
		neg.w		d2
		bra.b		noclampvol
zerosnd:
	    moveq		#0,d2		
noclampvol:
        move.b     #8,(a0)            ; channel A volume
        move.b     d2,(a1)

        move.w     noise(a2),d0
        addq.w     #1,d0
        move.w     d0,noise(a2)
        and.w      #31,d0
        move.w     #%110110,d1         ; channel A + noise
		cmp.w	   #STOP_NOISE,d7
		bge.b		.nonoise
        cmp.w      #8,d0
        ble.b      .donoise
.nonoise:
        move.b     #%111110,d1       ; clear noise
.donoise:
        move.b     #7,(a0)            ; access Yamaha register 7
        move.b     d1,(a1)            ; turn on channel A

        rts


END_initSound:
	clr.b		$ffff8901.w	; AUD STOP
	bsr		   initSoundEnd

    move.b     #8,(a0)            ; channel A volume
    clr.b      (a1)
    move.b     #9,(a0)            ; channel B volume
    clr.b      (a1)
    move.b     #10,(a0)            ; channel C volume
    clr.b      (a1)
	rts


; d6 = NOTES_TONE_INTERVAL
; d7 = DELAY_BETWEEN_NOTES
END_updateSound:

	lea        soundvars,a2
	lea        $ffff8800,a0
	lea        2(a0),a1

	movem.l	   a0-a2,-(sp)

	move.w     framecnt(a2),d2
	addq.w     #1,d2
	move.w     d2,framecnt(a2)

	move.w		d2,d0
	lsr.w		#1,d0
	add.w		#20,d0
	cmp.w	   #40,d0
	bge.b	   .doneRampUp
	bsr		AUD_setVolume
.doneRampUp:
	movem.l	   (sp)+,a0-a2

LOGO_updateSoundLand:
	move.w	   chanAFreq(a2),d0
;	and.w	   #4095,d0				; notes wrapping		
	move.w	   noteCnter(a2),d1
	bne.b	   notnewnote
	add.w	   d6,d0
	move.w	   d7,d1

	move.w	   d0,chanAFreq(a2)
	sub.w	   #20000,d0		; base note
	neg.w	   d0


	move.w	   prevNoteChan(a2),d2
	addq.w	   #2,d2
	cmp.w	   #4,d2
	ble.b	   endregwrap
	moveq	   #0,d2
endregwrap:
	move.w 	   d2,prevNoteChan(a2)	; 0, 2 or 4
	move.w	   d2,d3
	lsr.w	   #1,d3			  ; 0, 1 or 2
	addq.w	   #8,d3			  ; 8, 9 or 10
    move.b     d3,(a0)            ; select channel volume
    move.b     #12,(a1)
	
	move.b     d2,(a0)            ; select channel - LOW
	move.b     d0,(a1) 			  ; freq low
	addq.w	   #1,d2
	move.b     d2,(a0)            ; select channel - HI
	lsr.w	   #8,d0
	move.b     d0,(a1)    		  ; freq hi
notnewnote:
	subq.w	   #1,d1
	move.w	   d1,noteCnter(a2)

    move.b     #7,(a0)
    move.b     #%111000,(a1)      ; turn on channels A,B & C, no noise

	rts

AUD_stop:
	clr.b		$ffff8901.w	; AUD STOP
EXIT_sound:
	move.b		#7,$ffff8800.w
	moveq		#%111111,d0
	or.b		soundvars+sndRegSav,d0
	move.b		d0,$ffff8802.w    ; switch off all sound & noise channels, restore original PORT values
	rts

LOGO_initSound:
	lea		  soundvars,a2
	move.w	   #-2,prevNoteChan(a2)
	move.w     #0,framecnt(a2)

	move.w	   chanAFreq(a2),d0
	sub.w	   #20000,d0		; base note
	neg.w	   d0
	move.w	   d0,d1
	lsr.w	   #8,d1
	moveq	   #0,d2
	move.w	   #2,d7
.lp:	
	move.b     d2,(a0)            ; select channel - LOW
	move.b     d0,(a1) 			  ; freq low
	addq.w	   #1,d2
	move.b     d2,(a0)            ; select channel - HI
	move.b     d1,(a1)    		  ; freq hi
	dbra	   d7,.lp

	moveq	#40,d0
	bsr		AUD_setVolume
	rts

LOGO_updateSound:
	lea        soundvars,a2
	lea        $ffff8800,a0
	lea        2(a0),a1
	move.w     framecnt(a2),d2
	addq.w     #1,d2
	move.w     d2,framecnt(a2)
	move.w	framecnt(a2),d0
	cmp.w   #END_FADEOUT,d0
	ble.b	.notfinished
	sub.w	#END_FADEOUT,d0
	lsr.w	#4,d0
	sub.w	#40,d0
	neg.w	d0
	ble.b   .notfinished
	bsr		AUD_setVolume
.notfinished:

	move.w	#NOTES_TONE_INTERVAL+64,d6
	move.w	#DELAY_BETWEEN_NOTES*5,d7
	bsr		LOGO_updateSoundLand
	rts

sndStruct
noise     rs.w       1
framecnt  rs.w       1
sndRegSav rs.w       1 
chanAFreq rs.w       1 
noteCnter rs.w       1
prevNoteChan rs.w	 1 
sndStruct_len rs.w	 1


