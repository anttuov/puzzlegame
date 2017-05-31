LoadBackground: ;first time -> load to ram
    LDY #$00
    ;parses and loads the level data to ram from rom (addresses 0040-007F)
    leveltoram:
    LDA [levelpointlo], y
    TAX
    TYA
    CLC
    ASL A
    ASL A
    TAY
    TXA
    CLC
    AND #%00000011
    ASL A
    ASL A
    STA $43,y
    TXA
    CLC
    AND #%00001100
    STA $42,y
    TXA
    CLC
    AND #%00110000
    LSR A
    LSR A
    STA $41,y
    TXA
    CLC
    AND #%11000000
    LSR A
    LSR A
    LSR A
    LSR A
    STA $40,y

    TYA
    CLC
    LSR A
    LSR A
    TAY

    INY
    CPY #$10
    BNE leveltoram


                         
    


LoadBackground2: ;after ram
    
  ;draws the "black" under hud 
    DrawHUD:
    LDA $2002              
    LDA #$20
    STA $2006             
    LDA #$00
    STA $2006             
    LDX #$00             
  DrawHUDLoop:
    LDA hud,x      
    STA $2007             
    INX
    CPX #$80  ;loop count 
    BNE DrawHUDLoop 
    LDA #$37  
    LDX #$0
    LDY #$0
    Blackoutloop:
    STA $2007
    INX
    CPX #$40  ;loop count 
    BNE Blackoutloop 
    INY
    CPY #$04
    BNE Blackoutloop  


    JSR calctilesonload
    JSR UpdateActiveTilesHUD
    ;starting from address 20A8(+32) 
    LDX #$00
    STX looppart
    STX tilenumber
    STX tileupdown
    STX loopcount
    LDA #$A8
    STA lowb
    LDA #$20
    STA highb    

LoadBackgroundLoop2:
    ;add 32 to current address, for next tile
    ;lowb, highb -> address to be written in ppu
    LDA lowb      ; load low 8 bits of 16 bit value
    CLC              
    ;16 bit addition
    ADC #$20         
    STA lowb      
    LDA highb    
    ADC #$00         
    STA highb      

    LDA $2002            
    LDA highb
    STA $2006            
    LDA lowb
    STA $2006           
    LDY #$00
    STY tileupdown
    CLC
    LDX looppart ;looppart -> currently drawing upper or lower part of tiles
    INX
    STX looppart
    CPX #$02
    BEQ resetbgloopupdownwtf 
    JMP LoadBackgroundLoop1
resetbgloopupdownwtf: 
    LDX #$02
    STX tileupdown
    LDX #$00
    STX looppart
    CLC
    LDA tilenumber
    SBC #$07
    STA tilenumber
    
  LoadBackgroundLoop1:
    CLC
    LDX tilenumber
    INX
    STX tilenumber
    LDA $3F, X
    ADC tileupdown
    ADC #$4B
    STA $2007             ; write to PPU
    ADC #$01
    STA $2007             
    INY
    CPY #$08
    BNE LoadBackgroundLoop1  
  LDY loopcount ; loop 16 times, 8 tiles in total
  INY
  STY loopcount
  CPY #$10
  BNE LoadBackgroundLoop2
  RTS


  ;flip the tile on/off when the player moves on it
  Changetile:
    CLC
    LDA #$C8
    ADC changetilex
    ADC changetilex
    STA lowb
    LDA #$20
    ADC #$00   
    STA highb
    CLC
    LDX changetiley
    LDA #$00
    STA looppart
    ADC changetilex
    STA tilenumber
    
    calcy:
        CPX #$00
        BEQ donecalc
        CLC
        LDA tilenumber
        ADC #$08
        STA tilenumber
        CLC
        LDA lowb
        ADC #$40
        STA lowb
        LDA highb
        ADC #$00
        STA highb
        DEX
        JMP calcy
    ;write the changes to ram
    donecalc:
    LDY tilenumber
    LDX $40, y
    CPX #$04
    BEQ on
      LDA #$04
      STX temp
      LDX activetiles
      DEX
      STX activetiles
      LDX temp
      STA $40, y
      JMP donecheck
    on:
      LDA #$00
      STA $40, y
      STX temp
      LDX activetiles
      INX
      STX activetiles
      LDX temp

    donecheck:
    LDX #$01
    drawtiles:
    LDA $2002             ; read PPU status to reset the high/low latch
    LDA highb
    STA $2006             
    LDA lowb
    STA $2006            
    CLC
    LDA #$4B
    ADC $40, y
    ADC looppart
    STA $2007             ; write to PPU
    ADC #$01
    STA $2007             ; write to PPU
    CPX #$00
    BEQ tilesdrawn
      CLC
      LDA #$02
      STA looppart
      LDA lowb
      ADC #$20
      STA lowb
      LDA highb
      ADC #$00
      STA highb
      DEX
      JMP drawtiles
    tilesdrawn:
    JSR UpdateActiveTilesHUD
    RTS

    ;how many total/active tiles are on the level 
    calctilesonload:
      LDX #$00
      STX totaltiles
      STX activetiles
      CLC
      calctileloop:
        ;check if the tile is inactive
        LDA #$04
        CMP $40,x
        BNE notemptytile
        LDY totaltiles
        INY
        STY totaltiles
        JMP notvalidtile
        ;check if the tile is active
        notemptytile:
        LDA #$00
        CMP $40,x
        BNE notvalidtile
        LDY totaltiles
        INY
        STY totaltiles
        LDY activetiles
        INY
        STY activetiles
        ;after checks increase loop count
        notvalidtile:
        INX
        CPX #$40
        BNE calctileloop
        ;draw total tiles to hud
        LDA $2002              
        LDA #$20
        STA $2006             
        LDA #$4C
        STA $2006                 
        LDA totaltiles
        AND #%11110000
        LSR A
        LSR A
        LSR A
        LSR A

        STA $2007     
        LDA totaltiles
        AND #%00001111
        STA $2007   


    RTS

    UpdateActiveTilesHUD:
    LDA $2002              
    LDA #$20
    STA $2006             
    LDA #$49
    STA $2006                 
    LDA activetiles
    AND #%11110000
    LSR A
    LSR A
    LSR A
    LSR A

    STA $2007     
    LDA activetiles
    AND #%00001111
    STA $2007       

    RTS


      