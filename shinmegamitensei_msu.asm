; Shin Megami Tensei MSU1 ASM

!True			= 1
!False			= 0
!MSU_STATUS		= $2000
!MSU_READ		= $2001
!MSU_ID			= $2002
!MSU_SEEK		= $2000
!MSU_TRACK		= $2004
!MSU_VOLUME		= $2006
!MSU_CONTROL	= $2007

;; Main MSU-1 hook
	
org $0c80a7
;; overwriting 5 bytes here: 38 e9 44 0a aa = SEC SBC #$44 ASL TAX
autoclean JSL CheckForMSU
RTL

freecode

CheckForMSU:
	;; First save off the original value of A
	TAX
	lda !MSU_ID
	cmp #$53	; 'S'
	bne NoMSU	; Stop checking if it's wrong
	lda !MSU_ID+1
	cmp #$2D	; '-'
	bne NoMSU
	lda !MSU_ID+2
	cmp #$4D	; 'M'
	bne NoMSU
	lda !MSU_ID+3
	cmp #$53	; 'S'
	bne NoMSU
	lda !MSU_ID+4
	cmp #$55	; 'U'
	bne NoMSU
	lda !MSU_ID+5
	cmp #$31	; '1'
	beq NoMSU
	
MSUFound:
	; Do something with this fact here.
	JSL MSUPlayTrack
	RTL
NoMSU:
	; restore value of A
	TXA
	; run original overwritten code and return to subroutine
	SEC
	SBC #$44
	ASL
	TAX
	JML $0C80AC ;  back to playmusic routine after the overwritten code
	
MSUPlayTrack:
	lda #$FF
	sta !MSU_VOLUME
	ldx #$0005	; Writing a 16-bit value will automatically
	stx !MSU_TRACK	; set $2005 as well, so this is easy.
	lda #$01	; Set audio state to play, no repeat.
	sta !MSU_CONTROL
	; The MSU1 will now start playing.
	; Use lda #$03 to play a song repeatedly.
	RTL
	