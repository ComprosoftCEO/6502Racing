; --6502 Racing--
;
;	Created by Bryan McClain


;=========================Variables=======================

*=$0000
ScreenIndirect:		;2 Bytes - Used for loading a full screen (32x32 pixels)
ScreenIndirectL:	;Low byte of indirect screen access
*=$0001
ScreenIndirectH:	;High byte of indirect screen access

*=$0002
ScreenData:			;2 Bytes - Where the screen data is stored in memory
ScreenDataL:		;Low byte of indirect screen data access
*=$0003
ScreenDataH:		;High byte of indirect screen data access

*=$0004
ScreenIdx:			;Index in ScreenIndirect
HorseIdx:			;Index of the current horse in the main loop
*=$0005
ScreenDataIdx:		;Index in ScreenData


*=$0006
PlayerHorse:		;What color horse did the player choose to win (0 to 6)
*=$0007
WinningHorse:		;What color horse actually won the race? (0 to 6)

*=$0008
HorseIndirect:		;14 Bytes - Stores indirect pointers to all of the horses on the screen
HorseIndirectL:		;Low byte for indirect horse access
*=$0009
HorseIndirectH:		;High byte for indirect horse access

*=$0016
HorseSpotColor:		;7 Bytes - Color of the current spot for the horse



;=========================Registers=======================

*=$00fe
Random:				;$FE = Random number generator (special memory address)
*=$00ff
Keyboard:			;$FF = Keyboard input (special memory address)





;======================Main Function======================

*=$0600							;Code starts at $0600
Reset:

	JSR ComprosoftIntro			;Program always starts with the Comprosoft Intro

__replay:
	JSR TitleScreen				;Show the Title Screen for the race
	JSR ChooseHorseColor		;Let the player bet on a horse
	JSR ResetRaceData			;Reset everything needed to run the race
	JSR RaceIntro				;Cool animation where the horses come out to play
	JSR DoRace					;Moves the horses along the track
	JSR RaceEnd					;Displays the "You Win" or "You Lose" signs
	JMP __replay





;=======================Comprosoft Intro======================
ComprosoftIntro:

	LDY #$A9	;First underscore starts at $03A9
	JSR ComShowUnderscore

	LDA #$05	;Draw the "C"
	STA $0329	; .XXX
	STA $032A	; X...
	STA $032B	; X...
	STA $0348	; X...
	STA $0368	; .XXX
	STA $0388
	STA $03A9
	STA $03AA
	STA $03AB

	LDY #$AD	;Second underscore starts at $03AD
	JSR ComShowUnderscore

	LDA #$05	;Draw the ":"
	STA $034D	; ...
	STA $038D	; .X.
				; ...
				; .X.
				; ...

	LDY #$B0	;Third underscore starts at $03B0
	JSR ComShowUnderscore

	LDA #$05	;Draw the "\"
	STA $032F	; X..
	STA $034F	; X..
	STA $0370	; .X.
	STA $0391	; ..X
	STA $03B1	; ..X

	LDY #$B3	;Fourth underscore starts at $03B3
	JSR ComShowUnderscore

	LDA #$05	;Draw the ">"
	STA $0333	; X..
	STA $0354	; .X.
	STA $0375	; ..X
	STA $0394	; .X.
	STA $03B3	; X..

	LDY #$B7	;Final underscore starts at $03B7
	JSR ComShowUnderscore


	;Draw the text for "Presents"
	LDX #$00
	LDY #$00
ComPresents:
	LDA ComPresentsText,X		;Load a color from the data
	LSR							;Extract the left color by shifting right 4 bits
	LSR
	LSR
	LSR
	STA $0420,Y					;Store the color to the screen
	LDA ComPresentsText,X		;Load a color from the data
	AND #$0F					;Extract the right color using a bitwise AND with 0x0F
	INY
	STA $0420,Y					;Store the color to the screen
	INX
	INY
	CPX #$50					;We repeat this loop 80 times
	BNE ComPresents

	LDX #$00					;Wait two more times before starting the main code
	LDY #$00
	JSR ComWait
	LDX #$00
	LDY #$00
	JSR ComWait
	RTS							;Return out of this subroutine (and back to the main program)

;Temporarily flash the underscore
;	Y = Starting coordinate in $0300
ComShowUnderscore:
	LDA #$05			;Set color to light green
	STA $0300, Y		;Draw "_" symbol
	STA $0301, Y
	STA $0302, Y

	STY $00				;Store Y in a temporary spot
	LDX #$00
	LDY #$00
	JSR ComWait			;Do a short delay
	LDY $00				;Restore Y from the temporary spot

	LDA #$00			;Set color to black
	STA $0300, Y		;Draw "_" symbol
	STA $0301, Y
	STA $0302, Y
	RTS


;Short delay function for the Comprosoft intro
ComWait:
	INX
	CPX #$00
	BNE ComWait
	INY
	CPY #$20
	BNE ComWait
	RTS


;Byte code data for the text "Presents"
;	Each byte stores two colors
ComPresentsText:
	DCB $05,$50,$05,$50,$05,$55,$00,$55,$05,$50,$55,$00,$55,$50,$05,$50
	DCB $05,$05,$05,$05,$05,$00,$05,$00,$05,$00,$50,$50,$05,$00,$50,$00
	DCB $05,$50,$05,$50,$05,$50,$00,$50,$05,$50,$50,$50,$05,$00,$05,$00
	DCB $05,$00,$05,$05,$05,$00,$00,$05,$05,$00,$50,$50,$05,$00,$00,$50
	DCB $05,$00,$05,$05,$05,$55,$05,$50,$05,$50,$50,$50,$05,$00,$55,$00





;======================Show Title Screen======================
TitleScreen:
	;Load the Title Screen image
	LDA #<Screen_Title
	STA ScreenDataL
	LDA #>Screen_Title
	STA ScreenDataH
	JSR DrawScreen

	;Wait for the user to push the "S" key on the keyboard
	LDA #$00
	STA Keyboard			;Reset the user input
__tinput:
	LDA Keyboard
	CMP #$73				; "S" key = 115
	BNE __tinput
	RTS


	
	
;===================Color Select Screen======================
ChooseHorseColor:
	;Load the color select screen image
	LDA #<Screen_ChooseColor
	STA ScreenDataL
	LDA #>Screen_ChooseColor
	STA ScreenDataH
	JSR DrawScreen

	;Wait for user to input a number
	LDA #$00
	STA Keyboard		;Reset the keyboard input
__ninput:
	
	;Somehow, there is a glitch on 6502asm.com with the Carry Flag
	; Therefore, I have to write an ugly work around :(
	;
	;Old Code: (Very elegant and *should* work)
	;  LDA Keyboard		;Load a key from the keyboard
	;  CMP #$31			;Test keyboard against "1" key ($31)
	;  BCC __ninput		;If Acc < $31, then carry flag is clear
	;  CMP #$38			;Test keyboard against "8" key ($37)
	;  BCS	__ninput	;If Acc >= $38, then carry flag is set
	
	LDA Keyboard
	CMP #$31			; Case "1"
	BEQ __nvalid
	CMP #$32			; Case "2"
	BEQ __nvalid
	CMP #$33			; Case "3"
	BEQ __nvalid
	CMP #$34			; Case "4"
	BEQ __nvalid
	CMP #$35			; Case "5"
	BEQ __nvalid
	CMP #$36			; Case "6"
	BEQ __nvalid
	CMP #$37			; Case "7"
	BEQ __nvalid
	JMP __ninput
	
__nvalid:
	;We know that this is a valid horse (1 to 7)
	SEC
	SBC #$31			;Subtract $31 ("1") to make the horse a number from 0 to 6
	STA PlayerHorse
	RTS


;=======================Reset all Race Data======================	
	
ResetRaceData:
	LDA #$00
	TAX							;X = Counter that increases by 1 each time
	TAY							;Y = Counter that increases by 2 each time
__reset_loop:
	LDA #$07					;$07 = Color of the race track
	STA HorseSpotColor, X		;Reset the color of the current spot where the horse is
	LDA HorseOffsetL, X
	STA HorseIndirectL, Y		;Reset low indirect offset
	LDA HorseOffsetH, X
	STA HorseIndirectH, Y		;Reset the high indirect offset
	INY							;Add 2 to the Y counter
	INY
	INX							;Add 1 to the X counter
	CPX #7						;Loop through all 7 horses
	BNE __reset_loop
	RTS

	
	
;=======================Race Intro Animation=====================

;Cute little animation to start the race
RaceIntro:

	;Draw the track screen
	LDA #<Screen_Track
	STA ScreenDataL
	LDA #>Screen_Track
	STA ScreenDataH
	JSR DrawScreen

	;Place the racers one by one
	LDX #$00				;X = Counter that increases by 2
	LDY #$00				;Y = Counter that increases by 1
__place_horse_loop:
	LDA HorseColors, Y
	STA ($08, X)			;$08 = Horse Indirect (won't assembly otherwise)
	
	TXA						;Store X temporarily in A
	JSR LongWait			;Add some delay for the animation to work
	TAX						;Restore X from A
	
	INX						;Add 2 to X
	INX
	INY						;Add 1 to Y
	CPY #7					;Loop through all 7 horses
	BNE __place_horse_loop
	
	;Now, get rid of the walls in front of the horses
	LDA #$07				;$07 = Color of the floor under the track
	STA $03E3				;First wall is at $03E3
	LDX #$00
__wall_loop1:
	LDA #$07				;Next walls are at $0403, $0423, $0443, etc.
	STA $0403,X
	TXA
	CLC
	ADC #$20
	TAX
	CPX #$00
	BNE __wall_loop1
__wall_loop2:				;Final walls are at $0503, 0523, 0543, etc.
	LDA #$07
	STA $0503, X
	TXA
	CLC
	ADC #$20
	TAX
	CPX #$C0
	BNE __wall_loop2
	RTS

	
	
;=======================Run the Race=====================	

DoRace:
	
	;Run a loop for all 7 horses
	LDX #$00
__horse_loop:
	LDA Random				;Get a random number from 0x00 to 0xFF
	AND #$01				;Bitwise AND to get a number from 0 to 1
	BEQ __horse_nomove		;0 (False) = Do not move this horse
	
	;Update the horse by modifying the colors on the screen
	;  Old Space    = Stored Color
	;  Stored Color = New Space
	;  New Space    = Horse Color
	
	STX HorseIdx			;Store the horse index (Register X) in a temporary variable
	LDA HorseSpotColor, X	;Load the current color of this spot
	TAY						;Y = Temporary place to store the current spot color
	TXA
	ASL						;Multiply X by 2
	TAX
	TYA						;Restore A from Y
	STA ($08, X)			;Draw the previous color back ($08 = HorseIndirect)
	
	INC HorseIndirectL, X	;Add 1 to the Low indirect address to move horse to the next spot
	
	LDA ($08, X)			;Load the color of the new spot for the horse  ($08 = HorseIndirect)
	LDY HorseIdx			;Y = Current Horse
	STA HorseSpotColor, Y	;Store this new color into the spot color for the current horse
	LDA HorseColors, Y		;Get the color for this horse
	STA ($08, X)			;Store the horse color into this spot ($08 = HorseIndirect)
	
	;Figure out if the horse has won
	LDA HorseIndirectL, X	;Grab the low position
	LDX HorseIdx			;Reset X from the temporary variable
	AND #$1F				;Bitwise AND with first 5 bits (X coordinate of horse)
	CMP #29					;The horse wins if it gets past the finish line (X coordinate 29)
	BNE __horse_nomove
	
	STX WinningHorse
	JSR LongWait			;Wait for awhile
	RTS
	
__horse_nomove:
	TXA						;Temporarily store X in the Accumulator
	JSR Wait				;Add a bit of delay between horses (nice animation)
	JSR Wait				;Restore X from the accumulator
	TAX
	INX						;Go to the next horse
	CPX #$07				;Loop through all 7 horses
	BNE __horse_loop
	LDX #$00				;Reset the horse counter
	JMP __horse_loop		;Run the loop again


	
;=======================End of the Race=====================		
	
RaceEnd:

	JSR DrawHorseWin		;Display a popup to tell us which horse won the race

	JSR SuperLongWait		;Delay before showing what horse you bet on
	JSR SuperLongWait

	JSR DrawYouBet

	JSR SuperLongWait		;Delay before showing the win or lose screen
	JSR SuperLongWait
	
	;Find out if your horse won
	LDA PlayerHorse
	CMP WinningHorse
	BNE __load_loss

__load_win:
	;Load the win screen
	LDA #<Screen_YouWin
	STA ScreenDataL
	LDA #>Screen_YouWin
	STA ScreenDataH
	JSR DrawScreen
	JMP __end_wait
	
__load_loss:
	;Load the lose screen
	LDA #<Screen_YouLose
	STA ScreenDataL
	LDA #>Screen_YouLose
	STA ScreenDataH
	JSR DrawScreen

__end_wait:
	JSR SuperLongWait		;Delay before returning to the title screen
	JSR SuperLongWait
	RTS
	
;=======================Wait Routine======================

;Subroutine to wait some cycles
;	Modifies X, but not Y
Wait:
	LDX #$00
	_wait_loop:
	INX
	CPX #$00
	BNE _wait_loop
	RTS

;Wait for a longer time than a single call to "Wait"
LongWait:
	JSR Wait
	JSR Wait
	JSR Wait
	JSR Wait
	JSR Wait
	JSR Wait
	JSR Wait
	JSR Wait
	JSR Wait
	JSR Wait
	JSR Wait
	JSR Wait
	RTS

;Extremely long delay
SuperLongWait:
	JSR LongWait
	JSR LongWait
	JSR LongWait
	JSR LongWait
	JSR LongWait
	JSR LongWait
	JSR LongWait
	JSR LongWait
	JSR LongWait
	RTS
	
;Wait for the user to press a key
WaitKeyPress:
	LDA #$00
	STA Keyboard			;Reset the keyboard
__wait_key_loop:
	LDA Keyboard
	BEQ __wait_key_loop		;Keep looping until the keyboard isn't NULL
	RTS
	
	
;=======================Draw Full Screen======================

;Subroutine to draw a full page screen
;	Store the address of the data to load in ScreenData
DrawScreen:
	LDA #$00					;Screen starts at $0200
	STA ScreenIndirectL			;Low Byte: $00
	LDA #$02
	STA ScreenIndirectH			;High Byte: $02

	;Reset all of the counters
	LDA #$00
	STA ScreenIdx
	STA ScreenDataIdx
__screen_loop:
	LDY ScreenDataIdx
	LDA ($02), Y				;Grab the data byte from ScreenData ($02 = ScreenData)
	LSR							;Extract the left color by shifting right 4 bits
	LSR
	LSR
	LSR
	LDY ScreenIdx
	STA ($00), Y				;Store to the screen ($00 = ScreenIndirect)
	INC ScreenIdx				;Move to the next position in the screen
	LDY ScreenDataIdx
	LDA ($02), Y				;Grab the data byte from ScreenData ($02 = ScreenData)
	AND #$0F					;Extract the right color using a bitwise AND with 0x0F
	LDY ScreenIdx
	STA ($00), Y				;Store to the screen ($00 = ScreenIndirect)
	INC ScreenIdx				;Move to the next position in the screen
	BNE __screen_noinc			;If there is no overflow, then skip the next step
	INC ScreenIndirectH			;Add 1 to the high byte of screen indirect access
__screen_noinc:
	INC ScreenDataIdx			;Move to the next data byte
	BNE __screen_nodinc			;If there is no overflow, then skip the next step
	INC ScreenDataH				;Add 1 to the high byte of the screen data indirect access
__screen_nodinc:
	LDA ScreenIndirectH
	CMP #$06					;Screen ends at $0600
	BNE __screen_loop
	RTS
	
	
;=======================Draw Top Win Scren=====================	
	
DrawHorseWin:
	LDA #$20					;"Horse Win" popup starts at $0220
	STA ScreenIndirectL			;Low Byte: $20
	LDA #$02
	STA ScreenIndirectH			;High Byte: $02

	;Figure out the horse screen to load:
	;	Normally I would do this with a lookup table, but unfortunately
	;	6502asm.com doesn't support the syntax
	;
	;	So, instead I will use a massive if statement (*sorry*)
	LDX WinningHorse
	BEQ __swin1			;Case "Horse 1"
	DEX
	BEQ __swin2			;Case "Horse 2"	
	DEX
	BEQ __swin3			;Case "Horse 3"
	DEX
	BEQ __swin4			;Case "Horse 4"
	DEX
	BEQ __swin5			;Case "Horse 5"
	DEX
	BEQ __swin6			;Case "Horse 6"
	JMP __swin7			;Case Default ("Horse 7")

__swin1:
	LDA #<Screen_Horse1Win		;Horse 1 Win screen
	STA ScreenDataL
	LDA #>Screen_Horse1Win
	STA ScreenDataH
	JMP __swin_start

__swin2:
	LDA #<Screen_Horse2Win		;Horse 2 Win screen
	STA ScreenDataL
	LDA #>Screen_Horse2Win
	STA ScreenDataH
	JMP __swin_start

__swin3:
	LDA #<Screen_Horse3Win		;Horse 3 Win screen
	STA ScreenDataL
	LDA #>Screen_Horse3Win
	STA ScreenDataH
	JMP __swin_start

__swin4:
	LDA #<Screen_Horse4Win		;Horse 4 Win screen
	STA ScreenDataL
	LDA #>Screen_Horse4Win
	STA ScreenDataH
	JMP __swin_start

__swin5:
	LDA #<Screen_Horse5Win		;Horse 5 Win screen
	STA ScreenDataL
	LDA #>Screen_Horse5Win
	STA ScreenDataH
	JMP __swin_start

__swin6:
	LDA #<Screen_Horse6Win		;Horse 6 Win screen
	STA ScreenDataL
	LDA #>Screen_Horse6Win
	STA ScreenDataH
	JMP __swin_start

__swin7:
	LDA #<Screen_Horse7Win		;Horse 7 Win screen
	STA ScreenDataL
	LDA #>Screen_Horse7Win
	STA ScreenDataH
	
__swin_start:
	
	;Reset all of the counters
	LDA #$00
	STA ScreenIdx
	STA ScreenDataIdx
__swin_loop:
	LDY ScreenDataIdx
	LDA ($02), Y				;Grab the data byte from ScreenData ($02 = ScreenData)
	LSR							;Extract the left color by shifting right 4 bits
	LSR
	LSR
	LSR
	LDY ScreenIdx
	STA ($00), Y				;Store to the screen ($00 = ScreenIndirect)
	INC ScreenIdx				;Move to the next position in the screen
	LDY ScreenDataIdx
	LDA ($02), Y				;Grab the data byte from ScreenData ($02 = ScreenData)
	AND #$0F					;Extract the right color using a bitwise AND with 0x0F
	LDY ScreenIdx
	STA ($00), Y				;Store to the screen ($00 = ScreenIndirect)
	INC ScreenIdx				;Move to the next position in the screen
	BNE __swin_noinc			;If there is no overflow, then skip the next step
	INC ScreenIndirectH			;Add 1 to the high byte of screen indirect access
__swin_noinc:
	INC ScreenDataIdx			;Move to the next data byte
	BNE __swin_nodinc			;If there is no overflow, then skip the next step
	INC ScreenDataH				;Add 1 to the high byte of the screen data indirect access
__swin_nodinc:
	LDA ScreenIndirectH
	CMP #$03					;Screen ends on data $0300
	BNE __swin_loop
	LDA ScreenIdx
	CMP #$20					;Screen ends when the index is past 32 bytes (final line)
	BNE __swin_loop
	RTS

	
	
;=======================Draw Bottom "You Bet" Scren=====================	

DrawYouBet:
	LDA #$A0					;Screen starts at _________
	STA ScreenIndirectL			;Low Byte:
	LDA #$03
	STA ScreenIndirectH			;High Byte: 

	;Load the "You Bet" screen (same for all horses)
	LDA #<Screen_YouBet
	STA ScreenDataL
	LDA #>Screen_YouBet
	STA ScreenDataH
	
	;Reset all of the counters
	LDA #$00
	STA ScreenIdx
	STA ScreenDataIdx
__syb_loop:
	LDY ScreenDataIdx
	LDA ($02), Y				;Grab the data byte from ScreenData ($02 = ScreenData)
	LSR							;Extract the left color by shifting right 4 bits
	LSR
	LSR
	LSR
	LDY ScreenIdx
	STA ($00), Y				;Store to the screen ($00 = ScreenIndirect)
	INC ScreenIdx				;Move to the next position in the screen
	LDY ScreenDataIdx
	LDA ($02), Y				;Grab the data byte from ScreenData ($02 = ScreenData)
	AND #$0F					;Extract the right color using a bitwise AND with 0x0F
	LDY ScreenIdx
	STA ($00), Y				;Store to the screen ($00 = ScreenIndirect)
	INC ScreenIdx				;Move to the next position in the screen
	BNE __syb_noinc				;If there is no overflow, then skip the next step
	INC ScreenIndirectH			;Add 1 to the high byte of screen indirect access
__syb_noinc:
	INC ScreenDataIdx			;Move to the next data byte
	BNE __syb_nodinc			;If there is no overflow, then skip the next step
	INC ScreenDataH				;Add 1 to the high byte of the screen data indirect access
__syb_nodinc:
	LDA ScreenIndirectH
	CMP #$04					;Screen ends within $0400 range
	BNE __syb_loop
	LDA ScreenIdx
	CMP #96						;Ends after three more lines (32*3 = 96 Bytes)
	BNE __syb_loop
	
	
	;Now draw the actual horse that won
	;	Once again, use an ugly "If" statement 
	;	*Because 6502asm.com doesn't support lookup tables*
	LDX PlayerHorse
	BEQ __syb1			;Case "Horse 1"
	DEX
	BEQ __syb2			;Case "Horse 2"
	DEX
	BEQ __syb3			;Case "Horse 3"
	DEX
	BEQ __syb4			;Case "Horse 4"
	DEX
	BEQ __syb5			;Case "Horse 5"
	DEX
	BEQ __syb6			;Case "Horse 6"
	JMP __syb7			;Case Default ("Horse 7")

__syb1:
	LDA #<Screen_BetHorse1		;Bet Horse 1 screen
	STA ScreenDataL
	LDA #>Screen_BetHorse1
	STA ScreenDataH
	JMP __syb_hloop

__syb2:
	LDA #<Screen_BetHorse2		;Bet Horse 2 screen
	STA ScreenDataL
	LDA #>Screen_BetHorse2
	STA ScreenDataH
	JMP __syb_hloop

__syb3:
	LDA #<Screen_BetHorse3		;Bet Horse 3 screen
	STA ScreenDataL
	LDA #>Screen_BetHorse3
	STA ScreenDataH
	JMP __syb_hloop
	
__syb4:
	LDA #<Screen_BetHorse4		;Bet Horse 4 screen
	STA ScreenDataL
	LDA #>Screen_BetHorse4
	STA ScreenDataH
	JMP __syb_hloop
	
__syb5:
	LDA #<Screen_BetHorse5		;Bet Horse 5 screen
	STA ScreenDataL
	LDA #>Screen_BetHorse5
	STA ScreenDataH
	JMP __syb_hloop
	
__syb6:
	LDA #<Screen_BetHorse6		;Bet Horse 6 screen
	STA ScreenDataL
	LDA #>Screen_BetHorse6
	STA ScreenDataH
	JMP __syb_hloop
	
__syb7:
	LDA #<Screen_BetHorse7		;Bet Horse 7 screen
	STA ScreenDataL
	LDA #>Screen_BetHorse7
	STA ScreenDataH

__syb_hloop:

	LDX #$00				;X = Counter on the screen
	LDY #$00				;Y = Counter in ScreenData
__syb_hlp:
	LDA ($02), Y			;Grab the data byte from ScreenData ($02 = ScreenData)
	LSR						;Extract the left color by shifting right 4 bits
	LSR
	LSR
	LSR
	STA $0500, X			;We can use indexed indexing because we are copying less than 256 bytes
	INX						;Move to the next position in the screen
	LDA ($02), Y			;Grab the data byte from ScreenData ($02 = ScreenData)
	AND #$0F				;Extract the right color using a bitwise AND with 0x0F
	STA $0500, X
	INX						;Move to next position in the screen
	INY						;Move to next byte in the screen
	CPY #$70				;We copy 7 rows of 16 bytes (or 32*7 = 224 pixels)
	BNE __syb_hlp	
	RTS


;=======================Full Screens======================

;Maybe in a future project, I could write an algorithm to compress all
; of the screen data. It takes up quite a few bytes right now :)
;
; Each byte of data holds two pixels on the screen (one color per nibble)

Screen_Title:
	DCB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$B3,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$3B,$EE
	DCB $EE,$B3,$33,$33,$00,$03,$00,$03,$00,$03,$00,$03,$33,$33,$3B,$EE
	DCB $EE,$B3,$33,$33,$03,$33,$03,$33,$03,$03,$33,$03,$33,$33,$3B,$EE
	DCB $EE,$B3,$33,$33,$00,$03,$00,$03,$03,$03,$00,$03,$33,$33,$3B,$EE
	DCB $EE,$B3,$33,$33,$03,$03,$33,$03,$03,$03,$03,$33,$33,$33,$3B,$EE
	DCB $EE,$B3,$33,$33,$00,$03,$00,$03,$00,$03,$00,$03,$33,$33,$3B,$EE
	DCB $EE,$B3,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$3B,$EE
	DCB $EE,$B3,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$00,$03,$3B,$EE
	DCB $EF,$B3,$03,$03,$03,$03,$03,$33,$30,$33,$03,$03,$03,$33,$3B,$FE
	DCB $5F,$B3,$00,$33,$00,$03,$03,$33,$30,$33,$03,$03,$03,$03,$3B,$F5
	DCB $55,$B3,$03,$03,$03,$03,$03,$33,$30,$33,$03,$03,$03,$03,$3B,$55
	DCB $55,$B3,$03,$03,$03,$03,$00,$03,$00,$03,$03,$03,$00,$03,$3B,$55
	DCB $5D,$B3,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$33,$3B,$D5
	DCB $5D,$7B,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B7,$D5
	DCB $5D,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$D5
	DCB $5D,$7B,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B7,$D5
	DCB $5D,$BB,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$BB,$D5
	DCB $5D,$BA,$AA,$00,$00,$0A,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AB,$D5
	DCB $5D,$BA,$A0,$06,$66,$00,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AB,$D5
	DCB $5D,$BA,$A0,$66,$55,$60,$A0,$00,$A0,$00,$A0,$00,$A0,$00,$AB,$D5
	DCB $5D,$BA,$A0,$65,$66,$60,$AA,$0A,$A0,$A0,$A0,$A0,$AA,$0A,$AB,$D5
	DCB $5D,$BA,$A0,$66,$56,$60,$AA,$0A,$A0,$00,$A0,$0A,$AA,$0A,$AB,$D5
	DCB $5D,$BA,$A0,$66,$65,$60,$AA,$0A,$A0,$A0,$A0,$A0,$AA,$0A,$AB,$D5
	DCB $5D,$BA,$A0,$65,$56,$60,$AA,$0A,$A0,$A0,$A0,$A0,$AA,$0A,$AB,$D5
	DCB $5D,$BA,$A0,$06,$66,$00,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AB,$D5
	DCB $5D,$BA,$AA,$00,$00,$0A,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AB,$D5
	DCB $5D,$BB,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$BB,$D5
	DCB $5D,$7B,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B7,$D5
	DCB $5D,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$D5
	DCB $55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55

Screen_ChooseColor:
	DCB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
	DCB $EE,$BC,$C7,$7C,$C7,$77,$C7,$77,$CC,$CC,$77,$7C,$77,$7C,$CB,$EE
	DCB $EE,$BC,$C7,$C7,$C7,$CC,$CC,$7C,$CC,$CC,$7C,$7C,$7C,$7C,$CB,$EE
	DCB $EE,$BC,$C7,$7C,$C7,$7C,$CC,$7C,$CC,$CC,$7C,$7C,$7C,$7C,$CB,$EE
	DCB $EE,$BC,$C7,$C7,$C7,$CC,$CC,$7C,$CC,$CC,$7C,$7C,$7C,$7C,$CB,$EE
	DCB $EE,$BC,$C7,$7C,$C7,$77,$CC,$7C,$CC,$CC,$77,$7C,$7C,$7C,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EF,$BC,$CC,$3C,$3C,$33,$3C,$33,$3C,$C3,$3C,$33,$3C,$CC,$CB,$FE
	DCB $5F,$BC,$CC,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$CC,$3C,$CC,$3C,$CB,$F5
	DCB $55,$BC,$CC,$33,$3C,$3C,$3C,$33,$CC,$C3,$CC,$33,$CC,$CC,$CB,$55
	DCB $55,$BC,$CC,$3C,$3C,$3C,$3C,$3C,$3C,$CC,$3C,$3C,$CC,$3C,$CB,$55
	DCB $5D,$BC,$CC,$3C,$3C,$33,$3C,$3C,$3C,$33,$CC,$33,$3C,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$AA,$CC,$EE,$EC,$55,$5C,$8C,$8C,$22,$2C,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CA,$CC,$CC,$EC,$CC,$5C,$8C,$8C,$2C,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CA,$CC,$EE,$EC,$C5,$5C,$88,$8C,$22,$2C,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CA,$CC,$EC,$CC,$CC,$5C,$CC,$8C,$CC,$2C,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$AA,$AC,$EE,$EC,$55,$5C,$CC,$8C,$22,$2C,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$99,$9C,$BB,$BC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$9C,$CC,$CC,$BC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$99,$9C,$CC,$BC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$9C,$9C,$CC,$BC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$99,$9C,$CC,$BC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$DB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BD,$D5
	DCB $55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55


Screen_Track:
	DCB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
	DCB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
	DCB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
	DCB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
	DCB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
	DCB $EE,$EE,$EE,$F7,$F7,$FF,$7F,$F7,$F7,$F7,$FF,$7F,$F7,$EE,$EE,$EE
	DCB $EE,$EE,$EF,$CA,$C8,$CC,$4C,$C6,$C5,$C2,$CC,$8C,$CA,$FE,$EE,$EE
	DCB $EE,$EE,$F7,$FF,$7F,$F7,$F7,$F7,$FF,$7F,$7F,$F7,$F7,$F7,$EE,$EE
	DCB $EE,$EF,$C6,$CC,$5C,$C2,$C1,$CA,$CC,$7C,$4C,$C3,$C1,$C5,$FE,$EE
	DCB $EE,$F7,$FF,$7F,$7F,$F7,$FF,$7F,$7F,$F7,$F7,$FF,$7F,$7F,$F7,$EE
	DCB $EF,$C3,$CC,$8C,$4C,$C6,$CC,$3C,$1C,$C8,$C2,$CC,$6C,$3C,$CA,$FE
	DCB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F5
	DCB $55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55
	DCB $55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55
	DCB $5D,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$70,$17,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$71,$07,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$70,$17,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$71,$07,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$70,$17,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$71,$07,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$70,$17,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$71,$07,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$70,$17,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$71,$07,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$70,$17,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$71,$07,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$70,$17,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$71,$07,$D5
	DCB $5D,$70,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$70,$17,$D5
	DCB $5D,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$D5
	DCB $55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55


Screen_YouWin:
	DCB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EF,$BC,$CC,$CC,$CC,$0C,$0C,$00,$0C,$0C,$0C,$CC,$CC,$CC,$CB,$FE
	DCB $5F,$BC,$CC,$CC,$CC,$0C,$0C,$0C,$0C,$0C,$0C,$CC,$CC,$CC,$CB,$F5
	DCB $55,$BC,$CC,$CC,$CC,$C0,$CC,$0C,$0C,$0C,$0C,$CC,$CC,$CC,$CB,$55
	DCB $55,$BC,$CC,$CC,$CC,$C0,$CC,$0C,$0C,$0C,$0C,$CC,$CC,$CC,$CB,$55
	DCB $5D,$BC,$CC,$CC,$CC,$C0,$CC,$00,$0C,$00,$0C,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CD,$CC,$CD,$CD,$DD,$CD,$DD,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CD,$CC,$CD,$CC,$DC,$CD,$CD,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CD,$CD,$CD,$CC,$DC,$CD,$CD,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CD,$CD,$CD,$CC,$DC,$CD,$CD,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$DC,$DC,$CD,$DD,$CD,$CD,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$DB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BD,$D5
	DCB $55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55

Screen_YouLose:
	DCB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EF,$BC,$CC,$CC,$CC,$0C,$0C,$00,$0C,$0C,$0C,$CC,$CC,$CC,$CB,$FE
	DCB $5F,$BC,$CC,$CC,$CC,$0C,$0C,$0C,$0C,$0C,$0C,$CC,$CC,$CC,$CB,$F5
	DCB $55,$BC,$CC,$CC,$CC,$C0,$CC,$0C,$0C,$0C,$0C,$CC,$CC,$CC,$CB,$55
	DCB $55,$BC,$CC,$CC,$CC,$C0,$CC,$0C,$0C,$0C,$0C,$CC,$CC,$CC,$CB,$55
	DCB $5D,$BC,$CC,$CC,$CC,$C0,$CC,$00,$0C,$00,$0C,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CA,$CC,$CA,$AA,$CC,$AA,$CA,$AA,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CA,$CC,$CA,$CA,$CA,$CC,$CA,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CA,$CC,$CA,$CA,$CC,$AC,$CA,$AC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CA,$CC,$CA,$CA,$CC,$CA,$CA,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CA,$AA,$CA,$AA,$CA,$AC,$CA,$AA,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$DB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BD,$D5
	DCB $55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55

	
	
;=======================Horse Win Screens======================

Screen_Horse1Win:
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
	DCB $EE,$BC,$AC,$AC,$AA,$AC,$AA,$AC,$CA,$AC,$AA,$AC,$CA,$AC,$CB,$EE
	DCB $EE,$BC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$CC,$AC,$CC,$CC,$AC,$CB,$EE
	DCB $EE,$BC,$AA,$AC,$AC,$AC,$AA,$CC,$CA,$CC,$AA,$CC,$CC,$AC,$CB,$EE
	DCB $EE,$BC,$AC,$AC,$AC,$AC,$AC,$AC,$CC,$AC,$AC,$CC,$CC,$AC,$CB,$EE
	DCB $EE,$BC,$AC,$AC,$AA,$AC,$AC,$AC,$AA,$CC,$AA,$AC,$CA,$AA,$CB,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$FB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B7,$EE
	
Screen_Horse2Win:
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
	DCB $EE,$BC,$EC,$EC,$EE,$EC,$EE,$EC,$CE,$EC,$EE,$EC,$CE,$EE,$CB,$EE
	DCB $EE,$BC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$CC,$EC,$CC,$CC,$CE,$CB,$EE
	DCB $EE,$BC,$EE,$EC,$EC,$EC,$EE,$CC,$CE,$CC,$EE,$CC,$CE,$EE,$CB,$EE
	DCB $EE,$BC,$EC,$EC,$EC,$EC,$EC,$EC,$CC,$EC,$EC,$CC,$CE,$CC,$CB,$EE
	DCB $EE,$BC,$EC,$EC,$EE,$EC,$EC,$EC,$EE,$CC,$EE,$EC,$CE,$EE,$CB,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$FB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B7,$EE

Screen_Horse3Win:
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
	DCB $EE,$BC,$5C,$5C,$55,$5C,$55,$5C,$C5,$5C,$55,$5C,$C5,$55,$CB,$EE
	DCB $EE,$BC,$5C,$5C,$5C,$5C,$5C,$5C,$5C,$CC,$5C,$CC,$CC,$C5,$CB,$EE
	DCB $EE,$BC,$55,$5C,$5C,$5C,$55,$CC,$C5,$CC,$55,$CC,$CC,$55,$CB,$EE
	DCB $EE,$BC,$5C,$5C,$5C,$5C,$5C,$5C,$CC,$5C,$5C,$CC,$CC,$C5,$CB,$EE
	DCB $EE,$BC,$5C,$5C,$55,$5C,$5C,$5C,$55,$CC,$55,$5C,$C5,$55,$CB,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$FB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B7,$EE

Screen_Horse4Win:
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
	DCB $EE,$BC,$8C,$8C,$88,$8C,$88,$8C,$C8,$8C,$88,$8C,$C8,$C8,$CB,$EE
	DCB $EE,$BC,$8C,$8C,$8C,$8C,$8C,$8C,$8C,$CC,$8C,$CC,$C8,$C8,$CB,$EE
	DCB $EE,$BC,$88,$8C,$8C,$8C,$88,$CC,$C8,$CC,$88,$CC,$C8,$88,$CB,$EE
	DCB $EE,$BC,$8C,$8C,$8C,$8C,$8C,$8C,$CC,$8C,$8C,$CC,$CC,$C8,$CB,$EE
	DCB $EE,$BC,$8C,$8C,$88,$8C,$8C,$8C,$88,$CC,$88,$8C,$CC,$C8,$CB,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$FB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B7,$EE

Screen_Horse5Win:
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
	DCB $EE,$BC,$2C,$2C,$22,$2C,$22,$2C,$C2,$2C,$22,$2C,$C2,$22,$CB,$EE
	DCB $EE,$BC,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$CC,$2C,$CC,$C2,$CC,$CB,$EE
	DCB $EE,$BC,$22,$2C,$2C,$2C,$22,$CC,$C2,$CC,$22,$CC,$C2,$22,$CB,$EE
	DCB $EE,$BC,$2C,$2C,$2C,$2C,$2C,$2C,$CC,$2C,$2C,$CC,$CC,$C2,$CB,$EE
	DCB $EE,$BC,$2C,$2C,$22,$2C,$2C,$2C,$22,$CC,$22,$2C,$C2,$22,$CB,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$FB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B7,$EE

Screen_Horse6Win:
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
	DCB $EE,$BC,$9C,$9C,$99,$9C,$99,$9C,$C9,$9C,$99,$9C,$C9,$99,$CB,$EE
	DCB $EE,$BC,$9C,$9C,$9C,$9C,$9C,$9C,$9C,$CC,$9C,$CC,$C9,$CC,$CB,$EE
	DCB $EE,$BC,$99,$9C,$9C,$9C,$99,$CC,$C9,$CC,$99,$CC,$C9,$99,$CB,$EE
	DCB $EE,$BC,$9C,$9C,$9C,$9C,$9C,$9C,$CC,$9C,$9C,$CC,$C9,$C9,$CB,$EE
	DCB $EE,$BC,$9C,$9C,$99,$9C,$9C,$9C,$99,$CC,$99,$9C,$C9,$99,$CB,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$FB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B7,$EE

Screen_Horse7Win:
	DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
	DCB $EE,$BC,$BC,$BC,$BB,$BC,$BB,$BC,$CB,$BC,$BB,$BC,$CB,$BB,$CB,$EE
	DCB $EE,$BC,$BC,$BC,$BC,$BC,$BC,$BC,$BC,$CC,$BC,$CC,$CC,$CB,$CB,$EE
	DCB $EE,$BC,$BB,$BC,$BC,$BC,$BB,$CC,$CB,$CC,$BB,$CC,$CC,$CB,$CB,$EE
	DCB $EE,$BC,$BC,$BC,$BC,$BC,$BC,$BC,$CC,$BC,$BC,$CC,$CC,$CB,$CB,$EE
	DCB $EE,$BC,$BC,$BC,$BB,$BC,$BC,$BC,$BB,$CC,$BB,$BC,$CC,$CB,$CB,$EE
	DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
	DCB $EE,$FB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B7,$EE

	
	
;=======================You Bet Screens=====================	
	
Screen_YouBet:
	DCB $55,$5B,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B5,$55
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$BC,$3C,$3C,$33,$3C,$3C,$3C,$C7,$7C,$C7,$77,$C7,$77,$CB,$D5
	DCB $5D,$BC,$3C,$3C,$3C,$3C,$3C,$3C,$C7,$C7,$C7,$CC,$CC,$7C,$CB,$D5
	DCB $5D,$BC,$C3,$CC,$3C,$3C,$3C,$3C,$C7,$7C,$C7,$7C,$CC,$7C,$CB,$D5
	DCB $5D,$BC,$C3,$CC,$3C,$3C,$3C,$3C,$C7,$C7,$C7,$CC,$CC,$7C,$CB,$D5
	DCB $5D,$BC,$C3,$CC,$33,$3C,$33,$3C,$C7,$7C,$C7,$77,$CC,$7C,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5
	DCB $5D,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$D5

	
Screen_BetHorse1:
	DCB $5D,$BC,$AC,$AC,$AA,$AC,$AA,$AC,$CA,$AC,$AA,$AC,$CA,$AC,$CB,$D5
	DCB $5D,$BC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$CC,$AC,$CC,$CC,$AC,$CB,$D5
	DCB $5D,$BC,$AA,$AC,$AC,$AC,$AA,$CC,$CA,$CC,$AA,$CC,$CC,$AC,$CB,$D5
	DCB $5D,$BC,$AC,$AC,$AC,$AC,$AC,$AC,$CC,$AC,$AC,$CC,$CC,$AC,$CB,$D5
	DCB $5D,$BC,$AC,$AC,$AA,$AC,$AC,$AC,$AA,$CC,$AA,$AC,$CA,$AA,$CB,$D5
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$DB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BD,$D5

Screen_BetHorse2:
	DCB $5D,$BC,$EC,$EC,$EE,$EC,$EE,$EC,$CE,$EC,$EE,$EC,$CE,$EE,$CB,$D5
	DCB $5D,$BC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$CC,$EC,$CC,$CC,$CE,$CB,$D5
	DCB $5D,$BC,$EE,$EC,$EC,$EC,$EE,$CC,$CE,$CC,$EE,$CC,$CE,$EE,$CB,$D5
	DCB $5D,$BC,$EC,$EC,$EC,$EC,$EC,$EC,$CC,$EC,$EC,$CC,$CE,$CC,$CB,$D5
	DCB $5D,$BC,$EC,$EC,$EE,$EC,$EC,$EC,$EE,$CC,$EE,$EC,$CE,$EE,$CB,$D5
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$DB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BD,$D5

Screen_BetHorse3:
	DCB $5D,$BC,$5C,$5C,$55,$5C,$55,$5C,$C5,$5C,$55,$5C,$C5,$55,$CB,$D5
	DCB $5D,$BC,$5C,$5C,$5C,$5C,$5C,$5C,$5C,$CC,$5C,$CC,$CC,$C5,$CB,$D5
	DCB $5D,$BC,$55,$5C,$5C,$5C,$55,$CC,$C5,$CC,$55,$CC,$CC,$55,$CB,$D5
	DCB $5D,$BC,$5C,$5C,$5C,$5C,$5C,$5C,$CC,$5C,$5C,$CC,$CC,$C5,$CB,$D5
	DCB $5D,$BC,$5C,$5C,$55,$5C,$5C,$5C,$55,$CC,$55,$5C,$C5,$55,$CB,$D5
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$DB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BD,$D5

Screen_BetHorse4:
	DCB $5D,$BC,$8C,$8C,$88,$8C,$88,$8C,$C8,$8C,$88,$8C,$C8,$C8,$CB,$D5
	DCB $5D,$BC,$8C,$8C,$8C,$8C,$8C,$8C,$8C,$CC,$8C,$CC,$C8,$C8,$CB,$D5
	DCB $5D,$BC,$88,$8C,$8C,$8C,$88,$CC,$C8,$CC,$88,$CC,$C8,$88,$CB,$D5
	DCB $5D,$BC,$8C,$8C,$8C,$8C,$8C,$8C,$CC,$8C,$8C,$CC,$CC,$C8,$CB,$D5
	DCB $5D,$BC,$8C,$8C,$88,$8C,$8C,$8C,$88,$CC,$88,$8C,$CC,$C8,$CB,$D5
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$DB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BD,$D5

Screen_BetHorse5:
	DCB $5D,$BC,$2C,$2C,$22,$2C,$22,$2C,$C2,$2C,$22,$2C,$C2,$22,$CB,$D5
	DCB $5D,$BC,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$CC,$2C,$CC,$C2,$CC,$CB,$D5
	DCB $5D,$BC,$22,$2C,$2C,$2C,$22,$CC,$C2,$CC,$22,$CC,$C2,$22,$CB,$D5
	DCB $5D,$BC,$2C,$2C,$2C,$2C,$2C,$2C,$CC,$2C,$2C,$CC,$CC,$C2,$CB,$D5
	DCB $5D,$BC,$2C,$2C,$22,$2C,$2C,$2C,$22,$CC,$22,$2C,$C2,$22,$CB,$D5
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$DB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BD,$D5

Screen_BetHorse6:
	DCB $5D,$BC,$9C,$9C,$99,$9C,$99,$9C,$C9,$9C,$99,$9C,$C9,$99,$CB,$D5
	DCB $5D,$BC,$9C,$9C,$9C,$9C,$9C,$9C,$9C,$CC,$9C,$CC,$C9,$CC,$CB,$D5
	DCB $5D,$BC,$99,$9C,$9C,$9C,$99,$CC,$C9,$CC,$99,$CC,$C9,$99,$CB,$D5
	DCB $5D,$BC,$9C,$9C,$9C,$9C,$9C,$9C,$CC,$9C,$9C,$CC,$C9,$C9,$CB,$D5
	DCB $5D,$BC,$9C,$9C,$99,$9C,$9C,$9C,$99,$CC,$99,$9C,$C9,$99,$CB,$D5
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$DB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BD,$D5

Screen_BetHorse7:
	DCB $5D,$BC,$BC,$BC,$BB,$BC,$BB,$BC,$CB,$BC,$BB,$BC,$CB,$BB,$CB,$D5
	DCB $5D,$BC,$BC,$BC,$BC,$BC,$BC,$BC,$BC,$CC,$BC,$CC,$CC,$CB,$CB,$D5
	DCB $5D,$BC,$BB,$BC,$BC,$BC,$BB,$CC,$CB,$CC,$BB,$CC,$CC,$CB,$CB,$D5
	DCB $5D,$BC,$BC,$BC,$BC,$BC,$BC,$BC,$CC,$BC,$BC,$CC,$CC,$CB,$CB,$D5
	DCB $5D,$BC,$BC,$BC,$BB,$BC,$BC,$BC,$BB,$CC,$BB,$BC,$CC,$CB,$CB,$D5
	DCB $5D,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$D5
	DCB $5D,$DB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BD,$D5


;=======================Other Data======================		

HorseColors:	;Colors of the horses (0 to 6)
	DCB $0A,$0E,$05,$08,$02,$09,$0C
	
HorseOffsetL:	;Low byte offsets of the horses on the screen
	DCB $02,$42,$82,$c2,$02,$42,$82

HorseOffsetH:	;High byte offset of the horses on the screen
	DCB $04,$04,$04,$04,$05,$05,$05 
	
Walls:			;Screen offsets to remove the walls (Not Used)
	DCB $E3,$03 $03,$04,$23,$04,$43,$04,$63,$04,$83,$04,$A3,$04,$C3,$04
	DCB $E3,$04,$03,$05,$23,$05,$43,$05,$63,$05,$83,$05,$A3,$05 