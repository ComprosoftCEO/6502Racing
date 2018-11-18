;Comprosoft Intro
LDA #$28
STA $00
LDA #$03
STA $01

LDY #$81
STY $02

JSR ComUnderscoreControl

LDA #$05
STA $0329
STA $032A
STA $032B
STA $0348
STA $0368
STA $0388
STA $03A9
STA $03AA
STA $03AB

LDY #$85
STY $02
JSR ComUnderscoreControl

LDA #$05
STA $034D
STA $038D

LDY #$88
STY $02
JSR ComUnderscoreControl

LDA #$05
STA $032F
STA $034F
STA $0370
STA $0391
STA $03B1

LDY #$8B
STY $02
JSR ComUnderscoreControl

LDA #$05
STA $0333
STA $0354
STA $0375
STA $0394
STA $03B3

LDY #$8F
STY $02
JSR ComUnderscoreControl


LDX #$00
LDY #$00

ComPresents:
LDA ComPresentsText,X
LSR
LSR
LSR
LSR
STA $0420,Y
LDA ComPresentsText,X
AND #$0F
INY
STA $0420,Y
INX
INY
CPX #$50
BNE ComPresents

LDX #$00
LDY #$00
JSR ComWait
LDX #$00
LDY #$00
JSR ComWait
JMP reset

ComUnderscoreControl:
LDA #$05
LDY $02
JSR ComDrawUnderscore
LDX #$00
LDY #$00
JSR ComWait
LDA #$00
LDY $02
JSR ComDrawUnderscore
RTS

ComDrawUnderscore:
STA ($00),Y 
INY
STA ($00),Y 
INY
STA ($00),Y 
RTS

ComWait:
INX
CPX #$00
BNE ComWait
INY
CPY #$20
BNE ComWait
RTS

ComPresentsText:
DCB $05,$50,$05,$50,$05,$55,$00,$55,$05,$50,$55,$00,$55,$50,$05,$50
DCB $05,$05,$05,$05,$05,$00,$05,$00,$05,$00,$50,$50,$05,$00,$50,$00
DCB $05,$50,$05,$50,$05,$50,$00,$50,$05,$50,$50,$50,$05,$00,$05,$00
DCB $05,$00,$05,$05,$05,$00,$00,$05,$05,$00,$50,$50,$05,$00,$00,$50
DCB $05,$00,$05,$05,$05,$55,$05,$50,$05,$50,$50,$50,$05,$00,$55,$00

reset:
;Define variables
;-----------------------
;Memory Slot Locations:
;0 / 1 - Draw screen data and compare data (0)
;2 / 3 - Location of current screen
;8     - Winning horse
;9     - Horse that won
;10 - 2A - Horse positions

LDA #$01
STA $04

;load the horses
LDX #$00
horse_load1:
TXA
ASL
TAX
LDA #$04
STA $11,X
TXA
LSR
TAX
INX
CPX #$04
BNE horse_load1

horse_load2:
TXA
ASL
TAX
LDA #$05
STA $11,X
TXA
LSR
TAX
INX
CPX #$07
BNE horse_load2


LDA #$02
LDX #$00
horse_start_pos_loop:
STA $10,X
CLC
ADC #$40
INX
INX
CPX #$0E
BNE horse_start_pos_loop

;make a copy for checking values later on
LDA #$02
LDX #$00
horse_copy_loop:
STA $20,X
CLC
ADC #$40
INX
INX
CPX #$0E
BNE horse_copy_loop

;Load the position of the title screen into memory
LDA #$00
STA $02
LDA #$a0
STA $03
JSR show_screen

;reset the control info
LDA #$00
STA $FF

;wait for user input
tinput:
LDA $FF
CMP #$73
BNE tinput

;load the color select screen
LDA #$00
STA $02
LDA #$a2
STA $03
JSR show_screen

;reset the control info
LDA #$00
STA $FF

;wait for user to input a number
ninput:
LDA $FF

LDX #$30
STX $00

ninput_loop:
CMP $00
BNE ninput_next
;if the key is pressed, set the selected horse and load the game
LDA $00	
SEC
SBC #$30
STA $08
JMP load_race
ninput_next:
INC $00
INX
CPX #$38
BNE ninput_loop
JMP ninput


;load the track into memory and run
load_race:
LDA #$00
STA $02
LDA #$a4
STA $03
JSR show_screen

;place the racers one by one
LDX #$00
LDY #$00
place1_loop:
LDA $e000, X
STA $0402,Y
INX
STX $00
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
LDX $00
TYA
CLC
ADC #$40
TAY
CPX #$04
BNE place1_loop

place2_loop:
LDA $e000, X
STA $0502,Y
INX
STX $00
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
LDX $00
TYA
CLC
ADC #$40
TAY
CPX #$07
BNE place2_loop

;now, get rid of the wall
LDA #$07
LDX #$00
STA $03e3
wall_loop1:
LDA #$07
STA $0403,X
TXA
CLC
ADC #$20
TAX
CPX #$00
BNE wall_loop1

wall_loop2:
LDA #$07
STA $0503,X
TXA
CLC
ADC #$20
TAX
CPX #$C0
BNE wall_loop2

;run a loop for all 7 horses
LDX #$00
horse_loop:
LDA $FE
AND #$01
CMP #$01
BNE horse_nomove
TXA
ASL
TAX
LDA #$07
STA ($10,X)
LDA $10,X
CLC
ADC #$01
STA $10,X
TXA
LSR
TAX
LDA $e000,X
STA $00
TXA 
ASL
TAX
LDA $00
STA ($10,X)
LDA $10,X
SEC
SBC $20,X
STA $00
TXA
LSR 
TAX
LDA $00
CMP #$19
BNE horse_nomove
INX
STX $09
JMP end_race
horse_nomove:
STX $00
JSR wait
JSR wait
LDX $00
INX
CPX #$07
BNE horse_loop
LDX #$00
JMP horse_loop


end_race:
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait
JSR wait

;find out if your horse won
LDX $08
CPX $09
BEQ load_win
JMP load_loss

load_win:
;Load the win screen
LDA #$00
STA $02
LDA #$a6
STA $03
JSR show_screen
LDA #$00
STA $FF
JMP key_wait

load_loss:
;Load the lose screen
LDA #$00
STA $02
LDA #$a8
STA $03
JSR show_screen
LDA #$00
STA $FF
JMP key_wait

key_wait:
LDA $FF
CMP #$00
BEQ key_wait
JMP reset


;subroutine to wait
wait:
LDX #$00
wait_loop:
INX
CPX #$00
BNE wait_loop
RTS



;subroutine to load the screen
show_screen:
LDA #$00
STA $0
LDA #$02
STA $01
LDX #$00
LDY #$00
screen:
STY $04
TXA
TAY
LDA ($02),Y
LSR
LSR
LSR
LSR
LDY $04
STA ($00),Y
TXA
TAY
LDA ($02),Y
ASL
ASL
ASL
ASL
LSR
LSR
LSR
LSR
LDY $04
INY
STA ($00),Y
INX
INY
CPY #$00
BNE screen
LDY $01
INY
STY $01
TYA
LDY #$00
CMP #$06
BEQ end_screen
CMP #$04
BNE screen
LDA $03
CLC
ADC #$01
STA $03
JMP screen

end_screen:
RTS


;=====Full Screens======

;Title Screen
*=$a000
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

;Choose Color
*=$a200
DCB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
DCB $EE,$EB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BE,$EE
DCB $EE,$BB,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$BB,$EE
DCB $EE,$BC,$00,$0C,$0C,$0C,$00,$0C,$00,$0C,$C0,$0C,$00,$0C,$CB,$EE
DCB $EE,$BC,$0C,$CC,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$CC,$0C,$CC,$CB,$EE
DCB $EE,$BC,$0C,$CC,$00,$0C,$0C,$0C,$0C,$0C,$C0,$CC,$00,$CC,$CB,$EE
DCB $EE,$BC,$0C,$CC,$0C,$0C,$0C,$0C,$0C,$0C,$CC,$0C,$0C,$CC,$CB,$EE
DCB $EE,$BC,$00,$0C,$0C,$0C,$00,$0C,$00,$0C,$00,$CC,$00,$0C,$CB,$EE
DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
DCB $EE,$BC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CB,$EE
DCB $EF,$BC,$CC,$AA,$AC,$88,$8C,$7C,$CC,$EE,$EC,$DD,$DC,$CC,$CB,$FE
DCB $5F,$BC,$CC,$AC,$CC,$8C,$8C,$7C,$CC,$EC,$EC,$DC,$DC,$0C,$CB,$F5
DCB $55,$BC,$CC,$AC,$CC,$8C,$8C,$7C,$CC,$EC,$EC,$DD,$CC,$CC,$CB,$55
DCB $55,$BC,$CC,$AC,$CC,$8C,$8C,$7C,$CC,$EC,$EC,$DC,$DC,$0C,$CB,$55
DCB $5D,$BC,$CC,$AA,$AC,$88,$8C,$77,$7C,$EE,$EC,$DC,$DC,$CC,$CB,$D5
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

;Completed track
*=$a400
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

;you win
*=$a600
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

;you lose
*=$a800
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

;horse races color
*=$e000
DCB $0A,$0E,$05,$08,$02,$09,$0C