	CPU		6502
	ORG		$8000
	BINCLUDE	"prg.orig"

ROM_FREE = $9576

IN1 = $8000
IN2 = $8001
IN3 = $8002
DSWA = $8003
DSWB = $8004

R_WAIT_X_FRAMES = $A0D1
R_NOPLOOP = $A2CE
R_TOGGLE_INTS = $A006

CreditCount = $0A

; Boomer Rang'r uses $1B bit 0 to indicate whether or not the second player is
; playing, and acts upon this to flip the screen or not.

; Show the license screen for three seconds instead of 3 frames.
	ORG	$A378
	ldx	#180
.wait_top:
	jsr	wait_vblank
	dex
	bne	.wait_top
	jmp	$A389

; Screen flip hacks ===========================================================

; Intro / credit screen text flip.
	ORG	$A0DC
	lda	#$05

; Set flip at reset for license screen. Caused a problem in early HW testing?
	ORG	$A2F9
	ora	#$05

; Sets screen flip based on player in action, right after reading inputs.
	ORG	$A10F
	jsr	player_action_flip_a10f
	nop

; Flip screen based on which player. Occurs at end of game.
	ORG	$A6AB
	jmp	player_choice_a6ab

; Set flip for right before title. Useless?
	ORG	$ED02
	lda	#$15

; Flip for high score table.
	ORG	$F5C7
	ora	#$21

; Flip for title screen.
	ORG	$FB70
	lda	#$11

; Flip for something after the title. Useless?
	ORG	$FBA2
	lda	#$15

; Flip for Today's High Scores.
	ORG	$FDCE
	lda	#$05

; Free play hacks =============================================================

; Extension of vblank wait to look for player input.
;	ORG	$A00D
;	jsr	start_jump_hack
;	jsr	wait_vblank
;	jmp	$A021

; Skip IRQ checking for coin switches on free play
;	ORG	$A21F
;	jmp	irq_coin_check

; Don't insert coins if in free play.
;	ORG	$A29D
;	jmp	irq_coin_add

; Go to start screen if start is pressed, in free play
;	ORG	$A4B2
;	jmp	start_transition_hack

; Credit checks on start screen removed in free play
;	ORG	$A4EF
;	jmp	start_credit_check_hack

; New routines ================================================================

	ORG	ROM_FREE

start_transition_hack:
	jsr	check_free
	bne	.free_en
	lda	CreditCount
	bne	.start_screen

.attract_loop:
	jmp	$A4B6

.free_en:
	; Check start buttons
	byt	$13, $AD
	byt	$8F, 01
	lda	IN3
	eor	#$FF
	byt	$8F, 00
	and	#$0C
	beq	.attract_loop
	; Start is pushed.

.start_screen:
	jmp	$A4D9

irq_coin_add:
	tax
	jsr	check_free
	bne	.free_en
	txa
	sed
	clc
	adc	CreditCount
	cld
	jmp	$A2A2

.free_en:
	lda	#$01
	jmp	$A2A8

; A = free play enabled
check_free:
	byt	$13, $AD
	byt	$8F, 01

	lda	DSWA ; Read DSWA
	eor	#$FF
	and	#$10 ; Check free play switch
	beq	.no_freeplay
	lda	#$01
.no_freeplay:
	byt	$8f, 00
	rts

start_jump_hack:
	pha
	jsr	check_free
	beq	.exit

	; Check start button
	byt	$13, $AD
	byt	$8F, 01
	lda	IN3
	eor	#$FF
	byt	$8F, 00
	and	#$0C
	beq	.exit
	brk	; If start is pushed, trigger IRQ
.exit
	pla
	rts

start_credit_check_hack:
	jsr	R_TOGGLE_INTS
	jsr	check_free
	; Stick free play bit in X.
	tax

	byt	$13, $AD
	byt	$8F, $01

	lda	IN3
	eor	#$FF

	byt	$8F, $00

	cpx	#$00
	beq	.notfree

	and	#$0C
	beq	.start_not_pressed

	and	#$08
	bne	.start_2p_pressed
	lda	#$00
	sta	$18
	lda	#$80
	sta	$19
	jmp	$A526
.start_2p_pressed:
	lda	#$80
	sta	$18
	lda	#$00
	sta	$19
	jmp	$A256

	; Use original coin check routine.
.notfree:
	jmp	$A4FD

.start_not_pressed:
	jmp	start_credit_check_hack


player_action_flip_a10f:
	lda	$1B
	eor	#$01
	sta	$8006
	rts

player_choice_a6ab:
	lda	$1B
	and	#$FE
	eor	#$01
	sta	$8006
	jmp	$A6B2

wait_vblank:
	pha
	lda	#$00
.wait1_top:
	byt	$67, $85
	cli
	nop
	nop
	and	#$04
	sei
	bne	.wait1_top
.wait2_top:
	byt	$67, $85
	cli
	nop
	nop
	and	#$04
	sei
	beq	.wait2_top
	pla
	rts

credit_in_delay_patch:
	jsr	check_free
	bne	.free_en
	ldx	#$1C
	jsr	R_WAIT_X_FRAMES
.free_en:
	rts

irq_coin_check:
	jsr	check_free
	bne	.free_en
	jsr	R_NOPLOOP
	jmp	$A222
.free_en:
	jmp	$A26C
