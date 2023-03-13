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
@loop:	lda gorinchem, x  ; Load the message into SPR-RAM
  sta $2004
  inx
  cpx #$1c
  bvc @loop
  rti

gorinchem:
  .byte $3c, $04, $00, $58 ; G
  .byte $46, $02, $00, $62 ; O
  .byte $50, $05, $00, $6c ; R
  .byte $5a, $06, $00, $76 ; I
  .byte $64, $07, $00, $80 ; N
  .byte $6e, $08, $00, $8A ; C
  .byte $78, $09, $00, $94 ; H 
  .byte $82, $01, $00, $9E ; E
  .byte $8c, $00, $00, $A8 ; M WHAT IS YOUR PROBLEM

; meow:
;   .byte $6c, $00, $00, $6c ; M
;   .byte $6c, $01, $00, $76 ; E
;   .byte $6c, $02, $00, $80 ; O
;   .byte $6c, $03, $00, $8A ; W

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

  .byte %01100011	; M (00)
  .byte %01110111
  .byte %01111111
  .byte %01101011
  .byte %01100011
  .byte %01100011
  .byte %01100011
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %01111110	; E (01)
  .byte %01100000
  .byte %01100000
  .byte %01111000
  .byte %01100000
  .byte %01100000
  .byte %01111110
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %00111100 ; O (02)
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %01100011 ; W (03)
  .byte %01100011
  .byte %01100011
  .byte %01101011
  .byte %01111111
  .byte %01110111
  .byte %01100011
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %00111100 ; G (04)
  .byte %01100110
  .byte %01100000
  .byte %01101110
  .byte %01100110
  .byte %01100110
  .byte %00111100
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %01111100 ; R (05)
  .byte %01100110
  .byte %01100110
  .byte %01111100
  .byte %01111000
  .byte %01101100
  .byte %01100110
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %00111100 ; I (06)
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00011000
  .byte %00111100
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %01100110 ; N (07)
  .byte %01110110
  .byte %01111110
  .byte %01111110
  .byte %01101110
  .byte %01100110
  .byte %01100110
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %00111100 ; C (08)
  .byte %01100110
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01100110
  .byte %00111100
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %01100110 ; H (09)
  .byte %01100110
  .byte %01100110
  .byte %01111110
  .byte %01100110
  .byte %01100110
  .byte %01100110
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00
