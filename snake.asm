INCLUDE "hardware.inc"
INCLUDE "tiles.inc"
VBlankRAM EQU $FF80

SECTION "OAM Data",WRAM0,ALIGN[8] 
OAMData: DS (40 * 4)

SECTION "DIRECTION", WRAM0
XDIRECTION: DS 1
YDIRECTION: DS 1
UPDATEFRAME: DS 1
SNAKELENGTH: DS 1
RANDSEED: DS 1

SECTION "Inter", ROM0[$40]
jp VBlankRAM

SECTION "Header", ROM0[$100]
EntryPoint:
    di
    jp Start 


SECTION "Game code", ROM0[$150]
; Need to wait for Vblank before turning the screen off 
Start:
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
    ld hl, TileLabel
    ld bc, $8000
    ld a, [hli]
    ld [bc], a
    inc bc

    ld a, [hli]
    ld [bc], a
    inc bc

    ld a, [hli]
    ld [bc], a
    inc bc

    ld a, [hli]
    ld [bc], a
    inc bc

    ld a, [hli]
    ld [bc], a
    inc bc

    ld a, [hli]
    ld [bc], a
    inc bc

    ld a, [hli]
    ld [bc], a
    inc bc

    ld a, [hli]
    ld [bc], a
    inc bc

    ld a, [hli]
    ld [bc], a
    inc bc

    ld a, [hli]
    ld [bc], a
    inc bc










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
    ld a, $40 ; X POS
    ld [OAMData + 0], a

    ld a, $48 ; Y Pos
    ld [OAMData + 1], a

    ld a, $00 ; Tile 
    ld [OAMData + 2], a

    ld a, %000000
    ld [OAMData + 3], a


    ; apple 
Apple: 
    ld a, $60 ; X POS
    ld [OAMData + $9C], a

    ld a, $60 ; Y Pos
    ld [OAMData + $9D], a

    ld a, $01 ; Tile 
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
    ld a, $1A
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

    ld a, $0
    ld [$9c00 + 10], a 
    ld [$9c00 + (11 * 32) + 10 ], a 


    ; turn on LCD
    ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BG8000 | LCDCF_BGON | LCDCF_BG9C00 
    
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

    ld a, [de]
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

    ld hl, OAMData
    ld a, [YDIRECTION]
    add a,[hl]
    ld [hl], a

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


    ; Randomise apple position 
    ; y 
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


    ; Check if the snake is moved out of bounds
OutOfBoundsY:
    ld a, [OAMData + 0] 
    ; C: Set if no borrow (set if r8 > A).
    cp a, 16
    jp c, DoOutOfBounds

OutOfBoundsX:
    ld a, [OAMData + 1] 
    ; C: Set if no borrow (set if r8 > A).
    cp a, 8 
    jp c, DoOutOfBounds
    jp Main

    
DoOutOfBounds:
    jp DoOutOfBounds

    jp Main




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
    jr z, .done
    ld hl, YDIRECTION
    ld a, 0 
    add a, [HL]
    jr nz, .done
    ld [hl], -8
    ld hl, XDIRECTION
    ld [hl], 0

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










      



