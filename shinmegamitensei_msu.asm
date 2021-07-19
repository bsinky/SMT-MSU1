;; ======================================
;; Shin Megami Tensei MSU1 ASM
;; ======================================
@asar 1.81
math pri on
lorom

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

!OriginalMusicSubroutineStart = $000c80a7
!OriginalMusicSubroutineAfterHook = $00c80b7
!OriginalMusicSubroutineReturn = $000c809a

!SomeMusicTrackRelatedMemoryAddress = $000f83 ; Not sure what this is used for exactly

!TrackIndexOffset = #$3B

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

macro Set8BitA()
	SEP #$20
endmacro

macro Set16BitA()
	REP #$20
endmacro

macro Set8BitXY()
	SEP #$10
endmacro

macro Set16BitXY()
	REP #$10
endmacro

macro PushState()
	PHP
	%Set16BitMode()
	PHX
	PHY
	PHA
endmacro

macro PullState()
	%Set16BitMode()
	PLA
	PLY
	PLX
	PLP
endmacro

macro JumpIfMSU(labelToJump)
	LDA $2002
	CMP #$53
	BEQ <labelToJump>
endmacro

macro JumpIfNoMSU(labelToJump)
	LDA $2002
	CMP #$53
	BNE <labelToJump>
endmacro

;; =====================================
;; Main MSU-1 hook
;; =====================================

;org $00c8086
;cmp !TrackIndexOffset ; TODO: hopefully changing this index is okay... ; Update: it was not very okay
; TODO: enemy encounter, battle, and resuming map music after battle appear to work diffrently somehow
; TODO: debug how those work in the original ROM some more.

org !OriginalMusicSubroutineStart
autoclean JML MSUHook

freecode

MSUHook:
	%PushState()
	%Set8BitMode()
	TAX
	%JumpIfNoMSU(.NoMSU) ; MSU not available, fallback
	; Else, MSU was found, continue on
	
.MSUFound:
	;TXA			; Grab the original passed in A value again
	; TODO: not sure how to handle music stop when hooking at this alternate location
	;CPX #$FF ; original code passes #$FF to stop the current track
	;BCS .StopMSUTrack
	TXA			; Grab the original passed in A value again
	SEC
	SBC !TrackIndexOffset
	;BCC .NoMSU ; Fallback to original music if A minus TrackIndexOffset <= 0 (sound effects use this)
	TAY ; Save calculated index to Y
	lda #$FF
	sta !MSU_VOLUME
	sty !MSU_TRACK ; store calculated track index
	stz !MSU_TRACK+1
	lda #$03	; Set audio state to play, no repeat.
	sta !MSU_CONTROL
	; The MSU1 will now start playing.
	; Use lda #$03 to play a song repeatedly.
	; TODO: not sure how to determine whether the requested track should loop or not. Loops always?
	%PullState()
	; TODO: not sure what the value of Y should be...
	ldy #$00
	JML !OriginalMusicSubroutineReturn

.StopMSUTrack:
	lda #$00
	sta !MSU_CONTROL
	%PullState()
	JML !OriginalMusicSubroutineReturn

.NoMSU:
	%PullState()
	; run original overwritten code and return to subroutine
	sec
	sbc #$44
	asl
	tax
	lda $0c814c, X
	sta $0090
	lda $0c814d, X
	JML !OriginalMusicSubroutineAfterHook