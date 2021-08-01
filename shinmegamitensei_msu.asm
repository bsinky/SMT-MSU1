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
!OriginalResumeMusicAfterBattleBra = $000c8078 ; Original code: BRA $808a

!SomeMusicTrackRelatedMemoryAddress = $0f83 ; Not sure what this is used for exactly
!LastPlayedOffset = $0f83 ; Memory location of the offset used to calculate where to
						  ; store the last played audio (3 = music)
!LastPlayed = $0f84	; (indirect indexed) Stores the raw value of the last played song
!FreeRAM1 = $0452 ; Doesn't appear to be used once past the initialization code
!FadeVolume = !FreeRAM1

!TrackIndexOffset = #$38

!EnableMutipleBattleThemes = !True ; Change this to !False for a more vanilla battle BGM experience
!NumBattleThemes = #$04 ; Number of battle themes including the original theme. Should be set to a power of 2.
!NumFinalTrack = #$22 ; Track index of the final regular track before the extra battle theme tracks
                      ; (you shouldn't need to update this)

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

org $008241 ; Hook onto game loop for fadeout logic
autoclean JML CheckFade

; TODO: another thing to restore when MSU is not available
org !OriginalResumeMusicAfterBattleBra
bra MSUHookMusicComparison

; TODO: can't really do only this if we want it to work when MSU isn't available...
; TODO: need to restore this original code when MSU is not available
org $00c8086
MSUHookMusicComparison:
	cmp !TrackIndexOffset

org $00c8084
nop
nop  ; remove bmi $808a in order to jump to our hook even when $FD and $FF are passed

; TODO handle FD (fade music) better in MSU-1 code

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
	CPX #$FF
	BEQ .StopMSUTrack
	CPX #$FD
	BEQ .FadeMusic
	TXA	; Grab the original passed in A value again
	SEC
	SBC !TrackIndexOffset
	TAX ; Save calculated index to X
	if !EnableMutipleBattleThemes
	CPX #$04 ; original Battle music calculated index is $04
	BNE .SetVolumeAndPlayTrack
	TXY ; Save calculated index to Y
	; as long as the number of extra tracks is a power of 2, we can
	; use this algorithm to calculate modulo quickly: x & (y - 1)
	; https://stackoverflow.com/a/8022107/4276832
	LDA $0451 ; this appears to be an incrementing counter, might be random enough since you'd
			  ; have to hit this code on the exact same frame of the sequence in order to predictably
			  ; get the same song
	AND !NumBattleThemes-1
	BEQ .PlayOriginalBattleBGM
.ChooseBattleTrack
	; A should have a number between 1 and 3 in it now
	; all we need to do is add that to the index of the final track
	CLC
	ADC !NumFinalTrack
	STA !MSU_TRACK
	stz !MSU_TRACK+1
	lda #$FF
	sta !MSU_VOLUME
	bra .SetMSUStateToPlay
.PlayOriginalBattleBGM
	; it was zero, so we're going to play the original track
	TXA ; bring back original calculated index from X
	BRA .SetVolumeAndPlayTrack
	endif
.SetVolumeAndPlayTrack
	lda #$FF
	sta !MSU_VOLUME
	stz !FadeVolume ; Stop fading music if it's in the middle of a fade
	bank noassume
	lda TrackMap, X
	bank auto
	sta !MSU_TRACK ; store calculated track index
	stz !MSU_TRACK+1
	cmp #$22 ; Ending track
	bne .SetMSUStateToPlay
	lda #$01	; Set audio state to play, no repeat
	sta !MSU_CONTROL
	bra .Return
.SetMSUStateToPlay
	lda #$03	; Set audio state to play, with repeat.
	sta !MSU_CONTROL
.Return
	%PullState()
	; TODO: not sure what the value of Y should be...
	ldy #$00
	JML !OriginalMusicSubroutineReturn
	
.FadeMusic
	lda #$FF
	sta !FadeVolume
	JMP .Return

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

CheckFade:
	php
	%Set8BitA()
	%JumpIfNoMSU(.CheckFadeReturn)
	lda !FadeVolume ; Get the last recorded volume during fade
	CMP #$00
	BEQ .CheckFadeReturn ; Volume already faded to 0, skip
	rep 2 : DEC A ; decrement volume 2 times (1 per call wasn't noticeable enough)
	STA !MSU_VOLUME
	STA !FadeVolume
.CheckFadeReturn:
	plp
	; restore original subroutine code
	lda $0f2d
	and $0f2f
	eor $0f2d
	sta $0f2b
	lda $0f33
	and $0f35
	eor $0f33
	sta $0f31
	JML $00008259 ; jump to original subroutine return

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
; 	- 27. Unknown Song
;	- 28. Game Over
;	- 29. Terminal
;	- 30. Epilogue
;	- 31. Demo
;	- 32. Title
;	- 33. Fusion
;	- 34. Ending
;
; 33. Fusion is out of place because I originally missed it, and by the time I found
; the value for it I had already plotted out this tracklist, and it was easy to just
; put it on the end
TrackMap:
db $01,$02,$03,$04,$05,$06,$06,$07,$21,$07
db $08,$09,$0A,$0B,$0C,$0D,$0E,$0F,$10,$11
db $12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B
db $1C,$1D,$1E,$0E,$0E,$0E,$0E,$1F,$20,$22