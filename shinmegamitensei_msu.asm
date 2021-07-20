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

!TrackIndexOffset = #$38

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

; TODO: can't really do only this if we want it to work when MSU isn't available...
; TODO: need to restore this original code when MSU is not available
org $00c8086
cmp !TrackIndexOffset

org $00c8084
nop
nop  ; remove bmi $808a in order to jump to our hook even when $FD and $FF are passed

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
	TAX ; Save calculated index to X
	lda #$FF
	sta !MSU_VOLUME
	bank noassume
	lda TrackMap, X
	bank auto
	sta !MSU_TRACK ; store calculated track index
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

; TODO: update for new hook location
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

; Maps the calculated track index to the actual PCM track index
;
; Tracklisting:
;	- 1. Enemy Appear (no intro)
;	- 2. Enemy Appear (39 version)
;	- 3. Enemy Appear (3A version)
;	- 4. Enemy Appear (3B version)
;	- 5. Battle
;	- 6. Level Up
;	- 7. Enemy Appear (3F version)
;	- 8. Enemy Appear (42 version)
;	- 9. Enemy Appear (43 version)
;	- 10. Mansion of Heresey
;	- 11. Law
;	- 12. Chaos
;	- 13. Neutral
;	- 14. Ginza
;	- 15. Cathedral
;	- 16. Shibuya
;	- 17. Palace of the Four Heavenly Kings
;	- 18. Embassy
;	- 19. Arcade Street
;	- 20. Kichijoji
;	- 21. Ruins
;	- 22. Shop
;	- 23. Boss Battle
;	- 24. Dream
;	- 25. Home
;	- 26. Pascal
;	- 27. Game Over
; 	- 28. Unknown Song
;	- 29. Terminal
;	- 30. Epilogue
;	- 31. Demo
;	- 32. Title
;
TrackMap:
db $01,$02,$03,$04,$05,$06,$06,$07,$07,$07
db $08,$09,$0A,$0B,$0C,$0D,$0E,$0F,$10,$11
db $12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B
db $1C,$1D,$1E,$0E,$0E,$0E,$0E,$1F,$20,$20