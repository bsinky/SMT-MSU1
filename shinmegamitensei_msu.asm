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

macro PushState()
	PHP
	PHX
	PHY
	PHA
endmacro

macro PullState()
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
org !OriginalMusicSubroutineStart
;; overwriting 3 bytes php sep #$30
autoclean JML MSUHook

freecode

MSUHook:
	%Set16BitMode()
	%PushState()
	%Set8BitMode()
	TAX
	%JumpIfNoMSU(.NoMSU) ; MSU not available, fallback
	; Else, MSU was found, continue on
	
.MSUFound:
	TXA			; Grab the original passed in A value again
	CPX #$FF ; original code passes #$FF to stop the current track
	BCS .StopMSUTrack
	TXA			; Grab the original passed in A value again
	SEC
	SBC !TrackIndexOffset
	BCC .NoMSU ; Fallback to original music if A minus TrackIndexOffset <= 0 (sound effects use this)
	TAY ; Save calculated index to Y
	lda #$FF
	sta !MSU_VOLUME
	sty !MSU_TRACK ; store calculated track index
	stz !MSU_TRACK+1
	lda #$01	; Set audio state to play, no repeat.
	sta !MSU_CONTROL
	; The MSU1 will now start playing.
	; Use lda #$03 to play a song repeatedly.
	; TODO: not sure how to determine whether the requested track should loop or not
	%Set16BitMode()
	%PullState()
	JML !OriginalMusicSubroutineReturn

.StopMSUTrack:
	lda #$00
	sta !MSU_CONTROL
	%Set16BitMode()
	%PullState()
	JML !OriginalMusicSubroutineReturn

.NoMSU:
	%Set16BitMode()
	%PullState()
	; run original overwritten code and return to subroutine
	php
	%Set8BitMode()
	ldy $0f83
	sta $0f84, Y
	JML !OriginalMusicSubroutineAfterHook