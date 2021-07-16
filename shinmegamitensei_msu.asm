; Shin Megami Tensei MSU1 ASM

;; ======================================
;; Defines
;; ======================================
!True			= 1
!False			= 0
!MSU_STATUS		= $2000
!MSU_READ		= $2001
!MSU_ID			= $2002
!MSU_SEEK		= $2000
!MSU_TRACK		= $2004
!MSU_VOLUME		= $2006
!MSU_CONTROL	= $2007

!OriginalMusicSubroutineStart = $000c807a
!OriginalMusicSubroutineAfterHook = $00c807d
!OriginalMusicSubroutineReturn = $000c80a6

!TrackIndexOffset = #$3C

;; =====================================
;; Macros
;; =====================================

; Sets A, X, and Y to 8-bit mode
macro Set8BitMode()
	SEP #$30
endmacro

; Sets A, X, and Y to 16-bit mode
macro Set16BitMode()
	REP #$30
endmacro

;; =====================================
;; Main MSU-1 hook
;; =====================================
org !OriginalMusicSubroutineStart
;; overwriting 5 bytes here: 38 e9 44 0a aa = SEC SBC #$44 ASL TAX
;; 3 bytes php sep #$30
autoclean JML CheckForMSU

freecode

CheckForMSU:
	PHP
	%Set8BitMode()
	TAX
	lda !MSU_ID
	cmp #$53	; 'S'
	bne .NoMSU	; Stop checking if it's wrong
	lda !MSU_ID+1
	cmp #$2D	; '-'
	bne .NoMSU
	lda !MSU_ID+2
	cmp #$4D	; 'M'
	bne .NoMSU
	lda !MSU_ID+3
	cmp #$53	; 'S'
	bne .NoMSU
	lda !MSU_ID+4
	cmp #$55	; 'U'
	bne .NoMSU
	lda !MSU_ID+5
	cmp #$31	; '1'
	bne .NoMSU
	TXA			; Grab the original passed in A value again
	CPX #$FF ; original code passes #$FF to stop the current track
	BCS .StopMSUTrack
	TXA			; Grab the original passed in A value again
	SEC
	SBC !TrackIndexOffset
	BCC .NoMSU ; Fallback to original music if A minus TrackIndexOffset <= 0
	TAY ; Save calculated index to Y
	
.MSUFound:
	lda #$FF
	sta !MSU_VOLUME
	TYX ; move the calculated index value from Y back to X
	stx !MSU_TRACK
	stz !MSU_TRACK+1
	lda #$01	; Set audio state to play, no repeat.
	sta !MSU_CONTROL
	; The MSU1 will now start playing.
	; Use lda #$03 to play a song repeatedly.
	; TODO: not sure how to determine whether the requested track should loop or not
	PLP
	JML !OriginalMusicSubroutineReturn

.StopMSUTrack:
	lda #$00
	sta !MSU_CONTROL
	PLP
	JML !OriginalMusicSubroutineReturn
	
; TODO: sound effects are broken, so the fallback to regular sound must not be entirely working
.NoMSU:
	PLP
	; restore value of A
	TXA
	; run original overwritten code and return to subroutine
	php
	ldy $0f83
	JML !OriginalMusicSubroutineAfterHook