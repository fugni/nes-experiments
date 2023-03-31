.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

; Main code segment for the program
.segment "CODE"

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx $2000	; disable NMI
  stx $2001 	; disable rendering
  stx $4010 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
  bpl vblankwait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit $2002
  bpl vblankwait2

main:
load_palettes:
  lda $2002
  lda #$3f
  sta $2006
  lda #$00
  sta $2006
  ldx #$00
@loop:
  lda palettes, x
  sta $2007
  inx
  cpx #$20
  bne @loop

enable_rendering:
  lda #%10000000	; Enable NMI
  sta $2000
  lda #%00010000	; Enable Sprites
  sta $2001

forever:
  jmp forever

nmi:
  ldx #$00 	; Set SPR-RAM address to 0
  stx $2003
  
@loop:	
  lda circle, x
  sta $2004
  inx
  cpx #$1c
  bvc @loop

  lda cross, x 
  sta $2004
  inx
  cpx #$1c
  bvc @loop
  
  rti


circle:
  .byte $10, $00, $00, $08 ; O 1
  .byte $10, $01, $00, $10 ; O 2
  .byte $18, $02, $00, $08 ; O 3
  .byte $18, $03, $00, $10 ; O 4

cross:
  .byte $10, $04, $00, $18 ; X 1
  .byte $10, $05, $00, $20 ; X 2
  .byte $18, $06, $00, $18 ; X 3
  .byte $18, $07, $00, $20 ; X 4
  rti

palettes:
  ; Background Palette
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

  ; Sprite Palette
  .byte $0f, $20, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

; Character memory
.segment "CHARS"

  .byte %00000111	; O part 1 (00)
  .byte %00011100
  .byte %00110000
  .byte %01100000
  .byte %01000000
  .byte %11000000
  .byte %10000000
  .byte %10000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %11100000	; O part 2 (01)
  .byte %00111000
  .byte %00001100
  .byte %00000110
  .byte %00000010
  .byte %00000011
  .byte %00000001
  .byte %00000001
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %10000000   ; O part 3 (02)
  .byte %10000000
  .byte %11000000
  .byte %01000000
  .byte %01100000
  .byte %00110000
  .byte %00011100
  .byte %00000111
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %00000001   ; O part 4 (03)
  .byte %00000001
  .byte %00000011
  .byte %00000010
  .byte %00000110
  .byte %00001100
  .byte %00111000
  .byte %11100000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %11000000   ; X part 1 (04)
  .byte %11100000
  .byte %01110000
  .byte %00111000
  .byte %00011100
  .byte %00001110
  .byte %00000111
  .byte %00000011
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %00000011   ; X part 2 (05)
  .byte %00000111
  .byte %00001110
  .byte %00011100
  .byte %00111000
  .byte %01110000
  .byte %11100000
  .byte %11000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %00000011   ; X part 3 (06)
  .byte %00000111
  .byte %00001110
  .byte %00011100
  .byte %00111000
  .byte %01110000
  .byte %11100000
  .byte %11000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %11000000   ; X part 4 (07)
  .byte %11100000
  .byte %01110000
  .byte %00111000
  .byte %00011100
  .byte %00001110
  .byte %00000111
  .byte %00000011
  .byte $00, $00, $00, $00, $00, $00, $00, $00