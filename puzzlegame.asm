  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  
;;;;;;;;;;;;;;;
;declaring variables
  .rsset $0000       ; put pointers in zero page
lowb  .rs 1   ; pointer variables are declared in RAM
highb  .rs 1   ; low byte first, high byte immediately after
loopcount .rs 1
looppart .rs 1
tilenumber .rs 1
tileupdown .rs 1
levelpointlo .rs 1
levelpointhi .rs 1
changetilex .rs 1
changetiley .rs 1
buttons .rs 1
playerx .rs 1
playery .rs 1
playerprevx .rs 1
playerprevy .rs 1
playerspeed .rs 1
keypressed .rs 1
updatetilecheck .rs 1
debuggo .rs 1
totaltiles .rs 1
activetiles .rs 1
temp .rs 1
currentlevel .rs 1
    
  .bank 0
  .org $C000 
RESET:

  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem
  LDX #$01
  STX currentlevel
  LDA #LOW(level1) ;LOAD LEVEL 1 POINTER TO MEMORY
  STA levelpointlo 
  LDA #HIGH(level1)
  STA levelpointhi
  LDX #$10
  STX playerspeed

   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2




LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down



LoadSprites:
  LDX #$00              ; start at 0
  STX playerx
  STX playerprevx
  STX playery
  STX playerprevy
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$04              ; Compare X to hex $20, decimal 32
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down


  JSR LoadBackground
              
LoadAttribute:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
LoadAttributeLoop:
  LDA attribute, x      ; load data from address (attribute + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
  BNE LoadAttributeLoop  ; Branch to LoadAttributeLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
              
              

  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000

  LDA #%00001110   ; enable sprites, enable background, no clipping on left side
  STA $2001

Forever:
  
  JMP Forever     ;jump back to Forever, infinite loop
  
  .include "generatebg.asm"



;NMI interrupt, game code
NMI:

  ;copy sprite data from ram to ppu 
  LDA #$00
  STA $2003       
  LDA #$02
  STA $4014        

  ;check controls
  .include "controls.asm"


  ;JSR LoadBackground2
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
  
  RTI             ; return from interrupt
 
;;;;;;;;;;;;;;  
  
  
  
  .bank 1
  .org $E000
palette:
  .db $16,$11,$00,$0F,  $16,$16,$16,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;;background palette
  .db $29,$29,$19,$29,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;;sprite palette

sprites:
     ;vert tile attr horiz
  .db $33, $01, $00, $44   ;sprite 0

  hud:
  .db $27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27
  .db $27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27
  .db $27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27
  .db $27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27
  .db $27,$27,$27,$1D,$12,$15,$0E,$1C,$27,$27,$27,$2C,$27,$27,$27,$27
  .db $27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27
  .db $27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27
  .db $27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27,$27



  
level1:
  .db %00110101
  .db %01011111
  .db %01110111
  .db %01011111
  .db %01110111
  .db %11111111
  .db %01110111
  .db %11111111
  .db %01110111
  .db %11111111
  .db %01110111
  .db %11111111
  .db %01110111
  .db %11111111
  .db %01010111
  .db %11111111



level2:
  .db %00010001, %01010101
  .db %01010001, %01010101
  .db %01010001, %01000000
  .db %01010101, %01010101
  .db %01010101, %01010101
  .db %00000001, %01000101
  .db %01010101, %01000101
  .db %01010101, %01000101

level3:
  .db %00010101
  .db %01010111
  .db %11011111
  .db %11110111
  .db %11010101
  .db %01010111
  .db %11010101
  .db %01010111
  .db %11011101
  .db %01110111
  .db %11011101
  .db %01110111
  .db %11011101
  .db %01110111
  .db %11010101
  .db %01010111


level4:
  .db %00010001
  .db %01111111
  .db %01010001
  .db %01111111
  .db %01010101
  .db %01111111
  .db %11111100
  .db %00111111
  .db %01010101
  .db %01010111
  .db %01010111
  .db %01010111
  .db %01010111
  .db %01010111
  .db %00010111
  .db %01010111



attribute:
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000


  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "graphics.chr"   ;graphics