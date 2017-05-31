  ReadController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
  CLC
ReadControllerLoop:
  LDA $4016
  LSR A           ; bit0 -> Carry
  ROL buttons     ; bit0 <- Carry
  DEX
  BNE ReadControllerLoop

  CLC

  LDX buttons
  CPX #$00
  BEQ nobuttonpressed

  LDX keypressed
  CPX #$01
  BEQ skipcontrol
  LDX #$01
  STX keypressed
  JMP checkcontrols

    nobuttonpressed:
        LDX #$00
        STX keypressed
        skipcontrol:
        JMP checkcontrolsover

  checkcontrols:
  LDA buttons
  AND #%00000001
  BEQ NotR
    ;right painettiin
    LDX playerx
    INX
    LDY playery
    JSR nogoingback
    CPX #$01
    BEQ NotR

    LDA $0203   ; load sprite X (horizontal) position
    CLC         ; make sure the carry flag is clear
    ADC playerspeed    ; A = A + 1
    STA $0203   ; save sprite X (horizontal) position
    LDX playerx
    STX playerprevx
    INX
    STX playerx
    LDX playery
    STX playerprevy

  NotR:
  LDA buttons
  AND #%00000010
  BEQ NotL
  ;left painettiin
    LDX playerx
    DEX
    LDY playery
    JSR nogoingback
    CPX #$01
    BEQ NotL

    LDA $0203  
    SEC         
    SBC playerspeed
    STA $0203   
    LDX playerx
    STX playerprevx
    DEX
    STX playerx
    LDX playery
    STX playerprevy

  NotL:

  LDA buttons
  AND #%00000100
  BEQ NotD
  ;down pressed
    LDX playerx
    LDY playery
    INY
    JSR nogoingback
    CPX #$01
    BEQ NotD

    LDA $0200  
    CLC         
    ADC playerspeed
    STA $0200   
    LDX playery
    STX playerprevy
    INX
    STX playery
    LDX playerx
    STX playerprevx


  NotD:

  LDA buttons
  AND #%00001000
  BEQ NotU
  ;up pressed
    LDX playerx
    LDY playery
    DEY
    JSR nogoingback
    CPX #$01
    BEQ NotU

    LDA $0200   ; load sprite X (horizontal) position
    SEC         ; make sure carry flag is set
    SBC playerspeed    ; A = A - 1
    STA $0200   ; save sprite X (horizontal) position
    LDX playery
    STX playerprevy
    DEX
    STX playery
    LDX playerx
    STX playerprevx

  NotU:

  LDA buttons
  AND #%00010000
  BEQ Notstart
    LDX activetiles
    CPX totaltiles
    BNE LevelNotComplete
    LDX currentlevel
    INX
    STX currentlevel

    LevelNotComplete:
    JMP LoadLevel

  Notstart:

  LDA buttons
  AND #%00100000
  BEQ Notselect

  Notselect:

  LDA buttons
  AND #%01000000
  BEQ NotB

  NotB:

  LDA buttons
  AND #%10000000
  BEQ NotA
    LDX playerx
    STX changetilex
    LDX playery
    STX changetiley
    JSR Changetile
  NotA:

    LDX updatetilecheck
    CPX #$01
    BEQ dontupdatetile
        LDX playerx
        STX changetilex
        LDX playery
        STX changetiley
        JSR Changetile
    dontupdatetile:

  JMP checkcontrolsover


  ;player can't go backwards
  nogoingback:
  CPX playerprevx
  BNE notprev
  CPY playerprevy
  BNE notprev
  send1:
  LDX #$01
  STX updatetilecheck
  RTS
  notprev:
  CLC
  CPX #$08
  BCS send1
  CLC
  CPY #$08
  BCS send1

  TXA
  ;player can't move into walls
  wallchecker2000:
    CPY #$00
    BEQ wallchecker2000done
    DEY
    CLC
    ADC #$08
    JMP wallchecker2000
  wallchecker2000done:
  TAY
  STY debuggo
  LDX $40,y
  CPX #$0C
  BEQ send1
  LDX #$00
  STX updatetilecheck
  RTS

  checkcontrolsover:
  JMP continue
    LoadLevel:
    LDX #$FF
    TXS          ; Set up stack
    INX          ; now X = 0
    STX $2000    ; disable NMI
    STX $2001    ; disable rendering
    LDX currentlevel
    CPX #$01
    BEQ loadlevel1
    CPX #$02
    BEQ loadlevel2
    CPX #$03
    BEQ loadlevel3
    CPX #$04
    BEQ loadlevel4
    loadlevel1:
    LDA #LOW(level1) ;LOAD LEVEL TO MEMORY AND RENDER BACKGROUND
    STA levelpointlo 
    LDA #HIGH(level1)
    STA levelpointhi
    JMP vblankwait2
    loadlevel2:
    LDA #LOW(level2) 
    STA levelpointlo 
    LDA #HIGH(level2)
    STA levelpointhi
    JMP vblankwait2
    loadlevel3:
    LDA #LOW(level3) 
    STA levelpointlo 
    LDA #HIGH(level3)
    STA levelpointhi
    JMP vblankwait2
    loadlevel4:
    LDA #LOW(level4) 
    STA levelpointlo 
    LDA #HIGH(level4)
    STA levelpointhi
    JMP vblankwait2
  continue:
    LDX activetiles
    CPX totaltiles
    BNE continue2
    LDX currentlevel
    INX
    STX currentlevel
    JMP LoadLevel
  continue2:
