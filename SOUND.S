DELAY_BETWEEN_NOTES1 = 8
NOTES_TONE_INTERVAL = 128
CHORD_START			 = 20
SNDFADEOUT 			= 250

initSound:
    ; init sound
    lea        $ffff8800,a0
    lea        2(a0),a1
    lea        soundvars,a2

	move.w	   #-2,prevNoteChan(a2)
    moveq      #7,d0
    move.w     d0,(a0)
    move.b     (a0),sndRegSav(a2)
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
	;	move.b     #6,(a0)            ; NOISE
	;	move.b     d2,(a1)

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
        cmp.w      #8,d0
        ble.b      .donoise
        move.b     #%111110,d1       ; clear noise
.donoise
        move.b     #7,(a0)            ; access Yamaha register 7
        move.b     d1,(a1)            ; turn on channel A

        rts


END_initSound:
	bsr		   initSound

    move.b     #8,(a0)            ; channel A volume
    clr.b      (a1)
    move.b     #9,(a0)            ; channel B volume
    clr.b      (a1)
    move.b     #10,(a0)            ; channel C volume
    clr.b      (a1)


	rts

END_updateSound:
	lea        soundvars,a2
	lea        $ffff8800,a0
	lea        2(a0),a1

	move.w     framecnt(a2),d2
	addq.w     #1,d2
	move.w     d2,framecnt(a2)

	move.w	   chanAFreq(a2),d0
;	and.w	   #4095,d0				; notes wrapping		
	move.w	   noteCnter(a2),d1
	bne.b	   notnewnote
	add.w	   #NOTES_TONE_INTERVAL,d0
	move.w	   #DELAY_BETWEEN_NOTES1,d1

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
	move.b     d2,(a0)            ; select channel - LOW
	move.b     d0,(a1) 			  ; freq low
	addq.w	   #1,d2
	move.b     d2,(a0)            ; select channel - HI
	lsr.w	   #8,d0
	move.b     d0,(a1)    		  ; freq hi
    move.b     d3,(a0)            ; select channel volume
    move.b     #12,(a1)
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

sndStruct
noise     rs.w       1
framecnt  rs.w       1
sndRegSav rs.w       1 
chanAFreq rs.w       1 
noteCnter rs.w       1
prevNoteChan rs.w	 1 
sndStruct_len rs.w	 1

