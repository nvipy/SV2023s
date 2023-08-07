;-----------------------------------------------
; Simple YR Player (remove useless chanels)
;-----------------------------------------------
YM_REG_COUNT		=	14

YMBaseRegPtr:		dc.l	0
YMCurRegPtr:		dc.l	0
YMMaxFrameCount:	dc.l	0
YMCurFrame:		dc.l	0

YRMask:			dc.w	0
YRIsLooping:		dc.b	0
YRIsPlaying:		dc.b	0

;-----------------------------------------------
YR_SET_LOOP:	macro
		move.b		#1,YRIsLooping
		endm

YR_SET_ONCE:	macro
		clr.b		YRIsLooping
		endm

;-----------------------------------------------
YR_init:		; A0 = music ptr
	addq.w		#2,a0
	move.l		(a0)+,YMMaxFrameCount	; store number of frames
	move.w		(a0)+,YRMask		; store mask
	move.l		a0,YMBaseRegPtr		; set reg file base 
	move.l 		a0,YMCurRegPtr		; set reg file ptr
	clr.l		YMCurFrame		; clr frame count

	bsr		YR_stop

	moveq		#1,d0
	bsr		AUD_setMixer
	move.b		#1,YRIsPlaying
	rts

;-----------------------------------------------
YR_refresh:
	move.b		YRIsPlaying,d0
	bne.s		.play
	rts
.play:
	lea		$ffff8800.w,a1
	lea		2(a1),a2
	move.l		YMCurRegPtr(pc),a0		; pointer to current music data
	move.l		YMMaxFrameCount(pc),d1
	moveq		#0,d0				; first yammy register
	move.w		YRMask(pc),d2
	moveq		#YM_REG_COUNT-1,d7


.regloop:
	add.w		d2,d2
	bcc.s		.skipreg

	cmp.w		#7,d0
	bne.s		.directAccess

	move.b		d0,(a1)
	move.b		(a1),d6
	and.b		#$c0,d6
	moveq		#$3f,d3
	and.b		(a0),d3
	or.b		d3,d6
	move.b		d6,(a2)

	bra.s		.skipreg

.directAccess:
	move.b		d0,(a1)
	move.b		(a0),(a2)

.skipreg:	
	addq.b		#1,d0
	add.l		d1,a0
	dbra		d7,.regloop
	move.b		#14,(a1)
	move    	#$2300,sr
	
	addq.l  	#1,YMCurRegPtr              ; next set of registers
	move.l		YMCurFrame(pc),d0
	addq.l		#1,d0
	cmp.l		d1,d0
	bne.s		.noend
	moveq		#0,d0
	move.b		YRIsLooping(pc),d1
	bne.s		.setloop
	clr.b		YRIsPlaying
	bsr		YR_stop
	rts
.setloop:
	move.l		YMBaseRegPtr(pc),YMCurRegPtr
.noend:
	move.l		d0,YMCurFrame
	rts



;-----------------------------------------------
YR_stop:
	lea		$ffff8800.w,a1
	lea		2(a1),a2
	move.b		#8,(a1)
	clr.b		(a2)
	move.b		#9,(a1)
	clr.b		(a2)
	move.b		#10,(a1)
	clr.b		(a2)
	rts

;-----------------------------------------------
; Reducer java code 
;-----------------------------------------------
;	public static boolean reduceYM(String _filename, int _regcount)
;	{
;		byte[] data = XFile.load(_filename+".ym");
;		if (data==null) return false;
;		int frameSize = XFile.bytesToInt(data,12);
;		int ofs=34;
;		for (int i=0; i<3; i++)
;			while (data[ofs++]!=0);
;		byte[][] regs =new byte[_regcount][];
;		for (int i=0; i<_regcount; i++)
;		{
;			regs[i] = Arrays.copyOfRange(data, ofs, ofs+frameSize);
;			ofs+=frameSize;
;		}
;		int rmask = 0, rsize=0;
;		for (int i=0; i<_regcount; i++)
;		{
;			int k=0;
;			byte[] r = regs[i];
;			int pv = r[k++]; 
;			while (r[k++]==pv && k<frameSize);
;			rmask<<=1;
;			if (k!=frameSize)
;			{
;				rmask|=1;
;				rsize+=frameSize;
;			}
;		}
;		rmask<<=(16-_regcount);
;		
;		ofs = 0;
;		byte[] out = new byte[2+4+2+rsize];
;		out[ofs++]='Y';
;		out[ofs++]='R';
;		ofs = XFile.intToBytes(frameSize,out,ofs);
;		ofs = XFile.shortToBytes((short)rmask,out,ofs);
;		rmask<<=16;
;		for (int i=0; i<_regcount; i++)
;		{
;			if (rmask<0)
;			{
;				int len = regs[i].length;
;				System.arraycopy(regs[i],0,out,ofs,len);
;				ofs+= len;
;			}
;			rmask<<=1;
;		}
;		return XFile.save(_filename+".YR",out);
;	}
;
;	public static byte[] load(String _filename)
;	{
;		try 
;		{
;			File f = new File(_filename);
;			InputStream is = new FileInputStream(f);
;			byte[] data = new byte[(int)f.length()];
;			is.read(data);
;			is.close();
;			return data;
;		} 
;		catch (Exception e) 
;		{
;			e.printStackTrace();
;		}		
;		return null;
;	}
;	public static boolean save(String _fname, byte[] _data)
;	{
;		try 
;		{
;			File f = new File(_fname);
;			if (f.exists()) f.delete();
;			FileOutputStream os = new FileOutputStream(f);
;			os.write(_data);
;			os.close();
;	        return true;
;		}
;		catch (IOException e) 
;		{
;			e.printStackTrace();
;		}
;		return false;
;	}
;
;	public static int bytesToInt(byte[] _data,int _ofs)
;	{
;		return (_data[_ofs]<<24)|((_data[_ofs+1]&0xff)<<16)|((_data[_ofs+2]&0xff)<<8)|(_data[_ofs+3]&0xff);		
;	}
;	public static int intToBytes(int _value, byte[] _data,int _ofs)
;	{
;		_data[_ofs++] = (byte)(_value>>24);
;		_data[_ofs++] = (byte)(_value>>16);
;		_data[_ofs++] = (byte)(_value>>8);
;		_data[_ofs++] = (byte)_value;
;		return _ofs;
;	}
;	public static int shortToBytes(short _value, byte[] _data,int _ofs)
;	{
;		_data[_ofs++] = (byte)(_value>>8);
;		_data[_ofs++] = (byte)_value;
;		return _ofs;
;	}
;