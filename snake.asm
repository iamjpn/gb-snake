INCLUDE "hardware.inc"
INCLUDE "snake_tiles.inc"
VBlankRAM EQU $FF80

SECTION "OAM Data",WRAM0,ALIGN[8] 
OAMData: DS (40 * 4)

SECTION "DIRECTION", WRAM0
XDIRECTION: DS 1
YDIRECTION: DS 1
UPDATEFRAME: DS 1
SNAKELENGTH: DS 1
RANDSEED: DS 1
EATCOUNT: DS 1 
APRESSED: DS 1 

SECTION "SAVE", SRAM, BANK[0]
SAVESCORE: DS 1 
VERIFY: DS 1 

SECTION "Inter", ROM0[$40]
jp VBlankRAM

SECTION "Header", ROM0[$100]
EntryPoint:
    di
    jp Start 


SECTION "Game code", ROM0[$150]
; Need to wait for Vblank before turning the screen off 
Start:
    call InitSRAM
    ;ld hl, SAVESCORE
    ;ld b, $00
    ;call WriteSRAM
    ;ld b, $0
    ;call ReadSRAM


.waitVBlank
    ld a, [rLY]
    cp SCRN_Y    
    jr c, .waitVBlank

    xor a
    ld [rLCDC], a
    

    ; Load the VRAM Tile Data with just FF 
    ld a, $ff
    ld [$8000], a
    ld [$8001], a
    ld [$8002], a
    ld [$8003], a
    ld [$8004], a
    ld [$8005], a
    ld [$8006], a
    ld [$8007], a
    ld [$8008], a
    ld [$8009], a
    ld [$800a], a
    ld [$800b], a
    ld [$800c], a
    ld [$800d], a
    ld [$800e], a
    ld [$800f], a

    ; Load up a few of our actual tiles 
    ld hl, SnakeTiles 
    ld bc, $8000
REPT SnakeTilesLen
    ld a, [hli]
    ld [bc], a
    inc bc
ENDR

    ; set up the window
    ld bc, $9800
    ld a, $11
REPT $400
    ld [bc], a
    inc bc
ENDR











    ; Filing the OAMData wth 0 
    ld hl, OAMData 
    ld bc, $100
.loop
    ld a, $00
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop 

    ; Sprite Attribute Table
    ld a, $20 ; X POS
    ld [OAMData + 0], a

    ld a, $20 ; Y Pos
    ld [OAMData + 1], a

    ld a, $00 ; Tile 
    ld [OAMData + 2], a

    ld a, %000000
    ld [OAMData + 3], a


    ; apple 
Apple: 
    ld a, $30 ; X POS
    ld [OAMData + $9C], a

    ld a, $30 ; Y Pos
    ld [OAMData + $9D], a

    ld a, $05 ; Tile 
    ld [OAMData + $9E], a

    ld a, %000000
    ld [OAMData + $9F], a


    ; Pallete
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a

    ; Window 
    xor a 
    ld [rSCY], a
    ld [rSCX], a

    ld [rNR52], a



    ; cp interupt handler
    ld de, VBlankHandler

    ld hl, VBlankRAM
    
    ld bc, VBlankEnd - VBlankHandler
    call Memcpy

    ld a, 0
    ld [rSCY], a
    ld [rSCX], a

    ; set background
    ld a, $11
    ld hl, $9c00
    ld c, 32
    ld d, 32
.outerl:
.innerl:
    ld [hli], a
    dec d
    jr nz, .innerl

    dec c 
    jr nz, .outerl

    ld a, $06
BG_LINE = 0 
REPT 20 
    ld [$9c00 + (BG_LINE * 32) + 10], a 
BG_LINE = BG_LINE + 1 
ENDR
    ; ld [$9c00 + (11 * 32) + 10 ], a 

SETUPSCORE:
    ld hl, EATCOUNT
    ld [hl], 0
    ld a, $07
    ld [$9c00 + (2 * 32) + 16], a 

    ld a, $12
    ld [$9c00 + (0 * 32) + 12], a 
    ld a, $13
    ld [$9c00 + (0 * 32) + 13], a 
    ld a, $14
    ld [$9c00 + (0 * 32) + 14], a 
    ld a, $15
    ld [$9c00 + (0 * 32) + 15], a 
    ld a, $16
    ld [$9c00 + (0 * 32) + 16], a 
    ld a, $17
    ld [$9c00 + (0 * 32) + 17], a 

    call UpdateHighScore
    ld a, $18
    ld [$9c00 + (6 * 32) + 12], a 
    ld a, $19
    ld [$9c00 + (6 * 32) + 13], a 
    ld a, $1A
    ld [$9c00 + (6 * 32) + 14], a 
    ld a, $18
    ld [$9c00 + (6 * 32) + 15], a 
    ld a, $17
    ld [$9c00 + (6 * 32) + 16], a 


    ; turn on LCD
    ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BG8000 | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_WIN9800 | LCDCF_WINOFF
    
    ld [rLCDC], a

    ; interupts
    ld a, $01 
    ld [rIE], a
    ei
    
    ; set up speed
    ld a, $8
    ld [XDIRECTION], a  
    ld a, $0
    ld [YDIRECTION], a  
    ld a, $8
    ld [UPDATEFRAME], a  

    ld hl, SNAKELENGTH
    ld a, 3 
    ld [hl], a
TestMult:
    ld l, 2
    ld e, 3
    call Multiply
SETUPSEED:
    ld a, 1 
    ld [RANDSEED], a  
Pause: 
    halt 
    nop
    call ReadInput
    call TakeA
    cp a, 0
    jr z, Pause
Main:
    halt
    nop
    call ReadInput

    ld hl, UPDATEFRAME
    dec [hl]
    jr nz, Main
    
    ; updating 
    ld a, $8
    ld [UPDATEFRAME], a  

    ; set the hl to the end of the snake 
    ld a, [SNAKELENGTH]
    ld hl, OAMData
    ld b, a
.smallloop:
    ld D, 0 
    ld E, 4 
    add hl, DE ; hl points to the first byte of last body
    dec b 
    jp nz, .smallloop
    ld a, [SNAKELENGTH]
    ld b, a ; b has the count 
.snakebody:
    ; update the body 

    ; use DE for the lower ones 
    ld d, h
    ld e, l
    dec e
    dec e
    dec e
    dec e

    ld a, [de]
    ld [hli], a
    inc de

    ld a, [de]
    ld [hli], a
    inc de

    ;ld a, [de]
    ld a, $02 
    ld [hli], a
    inc de

    ld a, [de]
    ld [hli], a
    inc de

    dec l
    dec l
    dec l
    dec l

    dec l
    dec l
    dec l
    dec l


    dec b 
    jp nz, .snakebody
    

    ; moving head
    ld hl, OAMData + 1
    ld a, [XDIRECTION]
    add a,[hl]
    ld [hl], a
    
    ; change sprite
    ld a, [XDIRECTION]
    ; test negative
    cp a, 0
    jp z, .endnegx
    ld hl, OAMData + 2
    ld [hl], $00
    and a, %10000000
    jr nz, .negx
    ld hl, OAMData + 3
    ld a, ~ OAMF_XFLIP 
    and a, [hl]
    ld [hl], a
    jr .endnegx
.negx:
    ld hl, OAMData + 3
    ld a, OAMF_XFLIP 
    or a, [hl]
    ld [hl], a
.endnegx:

    ld hl, OAMData
    ld a, [YDIRECTION]
    add a,[hl]
    ld [hl], a

    ; change sprite
    ld a, [YDIRECTION]
    ; test negative
    cp a, 0
    jp z, .endnegy
    ld hl, OAMData + 2
    ld [hl], $01
    and a, %10000000
    jr nz, .negy
    ld hl, OAMData + 3
    ld a, ~ OAMF_YFLIP 
    and a, [hl]
    ld [hl], a
    jr .endnegy
.negy:
    ld hl, OAMData + 3
    ld a, OAMF_YFLIP 
    or a, [hl]
    ld [hl], a
.endnegy:



    ; Check if hit an apple
    ld a, [OAMData + 0] 
    ld b, a
    ld a, [OAMData + $9C]
    cp a, b
    jp nz, OutOfBoundsY 
    ld a, [OAMData + 1] 
    ld b, a
    ld a, [OAMData + $9D]
    cp a, b
    jp nz, OutOfBoundsY

    ld hl, SNAKELENGTH
    inc [hl]

    ld hl, EATCOUNT
    inc [hl]
    call WaitVramAccess
    call UpdateScore


    ; Randomise apple position 
    ; y 
.RandApple:
    call XorShift
    ld a, [RANDSEED]
    and a, 16 
    ld l, a
    ld e, $8
    call Multiply
    ld a, l
    add a, 16 

    ld [OAMData + $9C], a

    ; x 
    call XorShift
    ld a, [RANDSEED]
    and a, 9 
    ld l, a
    ld e, $8
    call Multiply
    ld a, l
    add a, 8 

    ld [OAMData + $9D], a

    ; Set up checking for collisions
    ld bc, OAMData + $9C
    ld a, [SNAKELENGTH]
    inc a
    ld d, a
    ld hl, OAMData
    call CheckCollision
    cp a, 1
    jp z, .RandApple




    ; Check if the snake is moved out of bounds
OutOfBoundsY:
    ld a, [OAMData + 0] 
    ; C: Set if no borrow (set if r8 > A).
    cp a, 16
    jp c, DoOutOfBounds
    cp a, 160
    jp nc, DoOutOfBounds

OutOfBoundsX:
    ld a, [OAMData + 1] 
    ; C: Set if no borrow (set if r8 > A).
    cp a, 8 
    jp c, DoOutOfBounds
    cp a, 88 
    jp nc, DoOutOfBounds

SelfCollision:
    ld bc, OAMData 
    ld a, [SNAKELENGTH]
    ld d, a
    ld hl, OAMData + 4
    call CheckCollision
    cp a, 1
    jp nz, Main
    ld c, 0
    jp GameOver

    
DoOutOfBounds:
    ld c, 0
    jp GameOver
    ;jp DoOutOfBounds

    ;jp Main

GameOver:
    halt
    nop

    ld hl, UPDATEFRAME
    dec [hl]
    jr nz, GameOver
    ld a, $4
    ld [UPDATEFRAME], a  

    ld a, [SNAKELENGTH]
    add a, 1
    cp a, c
    jp z, .erased
    ld hl, OAMData
    ld b, c
    ld a, c
    cp a, 0
    jp z, .loopend
.smallloop:
    ld D, 0 
    ld E, 4 
    add hl, DE ; hl points to the first byte of last body
    dec b 
    jp nz, .smallloop
.loopend:
    ld a, [SNAKELENGTH]
    ld b, a ; b has the count 
    ld a, 0
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a

    inc c
    



    jp GameOver



.erased:
    call NewHighScore
    call BlankScreen

Testgo:
    jp EntryPoint 



VBlankHandler:
    push af
    push bc
    push de 
    push hl

    ld a,  ~ $01
    ld hl, rIF
    and a, [hl]

    ld a, (OAMData / $100)
    ld [rDMA], a
    ld a, $28
.wait
    dec a
    jr nz, .wait
    pop hl
    pop de
    pop bc
    pop af
    reti
VBlankEnd:

; We need  a copy function: takes from address, to address and size
; de from
; hl to
; bc count
Memcpy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, Memcpy
    ret

; Copy a string up to but not including the first NUL character
; @param de A pointer to the string to be copied
; @param hl A pointer to the beginning of the destination buffer
; @return de A pointer to the byte after the source string's terminating byte
; @return hl A pointer to the byte after the last copied byte
; @return a Zero
; @return flags C reset, Z set
Strcpy:
    ld a, [de]
    inc de
    and a
    ret z
    ld [hli], a
    jr Strcpy

ReadInput:
    ld a, P1F_5 
    ld [rP1], a
    ld a, [rP1]

    cpl 
    ld b, a
    and %00000001
    ; left
    jr z, .checkright
    ld hl, XDIRECTION
    ld a, 0 
    add a, [HL]
    jr nz, .checkright
    ld [hl], 8
    ld hl, YDIRECTION
    ld [hl], 0 
.checkright:
    ld a, b
    and %00000010
    ; right
    jr z, .checkup
    ld hl, XDIRECTION
    ld a, 0 
    add a, [HL]
    jr nz, .checkup
    ld [hl], -8
    ld hl, YDIRECTION
    ld [hl], 0 
.checkup:
    ld a, b
    and %00001000
    ; right
    jr z, .checkdown
    ld hl, YDIRECTION
    ld a, 0 
    add a, [HL]
    jr nz, .checkdown
    ld [hl], 8
    ld hl, XDIRECTION
    ld [hl], 0
.checkdown:
    ld a, b
    and %00000100
    ; right
    jr z, .checka
    ld hl, YDIRECTION
    ld a, 0 
    add a, [HL]
    jr nz, .checka
    ld [hl], -8
    ld hl, XDIRECTION
    ld [hl], 0

.checka:
    ld a, P1F_5 
    cpl 
    ld [rP1], a
    ld a, [rP1]

    cpl 
    ld b, a

    ld a, b
    and %00000001
    jr z, .done
    ld a, 1
    ld [APRESSED], a

.done:
    ret


; x * y
; x = l
; y = e 
; result in hl 
Multiply:
    ld a, 0
.loop
    add a, e
    dec l
    jp nz, .loop
    ld l, a
    ret

; RANDSEED updated with new value 
; destroys a,b, hl
XorShift:
    ; y8 ^= (y8 << 7);
    ; y8 ^= (y8 >> 5);
    ; return y8 ^= (y8 << 3);
    ld hl, RANDSEED
    ld a, [hl] 
    ld b, $7
.loop1:
    sla a 
    dec b
    jp nz, .loop1

    xor a, [hl]
    ld [hl], a

    ld b, $5
.loop2:
    sra a 
    dec b
    jp nz, .loop2
        
    xor a, [hl]
    ld [hl], a

    ld b, $3
.loop3:
    sla a 
    dec b
    jp nz, .loop3

    xor a, [hl]
    ld [hl], a
    ret


; Take an object we care about comparing with 
; Begining of objects we want to check 
; Amount of objects we have  
; BC = needle 
; HL = haystack 
; d = length to check 
CheckCollision:
.loop: 
    ld a, d
    cp a, 0
    jp z, .loopend
    ; check y 
    ld a, [bc]
    cp a, [hl] 
    jp z, .checkx
    inc hl
    inc hl
    inc hl
    inc hl
    dec d
    jr .loop

    ; check x
.checkx
    inc c
    inc hl
    ld a, [bc]
    cp a, [hl] 
    jp z, .hit

    ; ready for the next sprite 
    dec c
    inc hl
    inc hl
    inc hl

    dec d
    jp .loop
.loopend:

    ld a, 0
    ret
.hit: 
    ld a, 1
    ret 

WaitVramAccess:
    ld hl, rSTAT
.wait1:
    bit 1, [hl]
    jr z, .wait1
.wait2:
    bit 1, [hl]
    jr nz, .wait2
    ret

UpdateScore:
    ld hl, EATCOUNT 
    ;ld a, [hl]
    ld a, [hl]
    ld d, a
    ld e, 10
    call ModDiv
    add a, 7 ; where the numbers start
    ld hl, $9c00 + (2 * 32) + 16 
    ;ld [$9c00 + (BG_LINE * 32) + 10], a 

    ;inc [hl]
    ld [hl], a
    dec hl
    ld a, d
    add a, 7 ; where the numbers start
    ld [hl], a
    ret

NewHighScore:
    ld hl, SAVESCORE
    call ReadSRAM
    ld a, [EATCOUNT]
    cp a, b
    jr c, .end ; b > a
    ld hl, SAVESCORE
    ld b, a
    call WriteSRAM
    call UpdateHighScore


.end:
    ret

UpdateHighScore:
    ld hl, SAVESCORE 
    call ReadSRAM
    ld d, b
    ld e, 10
    call ModDiv
    add a, 7 ; where the numbers start
    ld hl, $9c00 + (8 * 32) + 16 
    ;ld [$9c00 + (BG_LINE * 32) + 10], a 

    ;inc [hl]
    ld [hl], a
    dec hl
    ld a, d
    add a, 7 ; where the numbers start
    ld [hl], a
    ret

; divides d by e
;places the quotient in d and the remainder in a 
; http://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Division
ModDiv:
   xor	a
   ld	b, 8

_loop:
   sla	d
   rla
   cp	e
   jr	c, .j 
   sub	e
   inc	d
.j:   
   dec b
   jp nz, _loop
   
   ret

BlankScreen: 
    ld a, 0
    ld [$ff4a], a
    ld a, 7
    ld [$ff4b], a

    call WaitVramAccess
    ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BG8000 | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_WIN9800 | LCDCF_WINON
    ld [rLCDC], a

    ld c, 2

    ld hl, $9800
.outer:
    ld b, $ff 
    dec c
    jr z, .end
.inner:
    halt
    nop
    ld d, h
    ld e, l
    call WaitVramAccess
    ld h, d
    ld l, e
    ld a, 2
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ;ld [$9800], a
    dec b
    jp nz, .inner
    jp .outer

.end:
    ret

InitSRAM:

    ld a, $0a
    ld [$0000], a
    ld a, BANK(VERIFY)
	ld [$4000], a
    ;call EnableSRAM
    ld a, [VERIFY]
    cp $42 
    jp z, .already
    ld a, $42
    ld [VERIFY], a
    ld a, $00
    ld [SAVESCORE], a

.already:
    ;call DisableSRAM
    ld a, $00
    ld [$0000], a
    ret


; b to hl
WriteSRAM:
    ld a, $0a
    ld [$0000], a
    
    ld [hl], b

    ld a, $00
    ld [$0000], a
    ret

; b from hl
ReadSRAM:
    ld a, $0a
    ld [$0000], a

    ld b, [hl] 

    ld a, $00
    ld [$0000], a
    ret

; a = 1 if 'A' pressed
TakeA: 
    ld a, [APRESSED] 
    cp a, 0
    jr z, .done
    ld a, 0
    ld [APRESSED], a
    ld a, 1
.done
    ret













      




