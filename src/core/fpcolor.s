# Begin asmlist al_procedures

.text
	.align 4
_FPCOLOR_$$_CLAMPBYTE$LONGINT$$BYTE:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#16
	str	w0,[sp]
	ldr	w0,[sp]
	cmp	w0,#0
	b.lt	Lj5
	b	Lj6
Lj5:
	strb	wzr,[sp, #8]
	b	Lj3
Lj6:
	ldr	w0,[sp]
	cmp	w0,#255
	b.gt	Lj7
	b	Lj8
Lj7:
	movz	w0,#255
	strb	w0,[sp, #8]
	b	Lj3
Lj8:
	ldrb	w0,[sp]
	strb	w0,[sp, #8]
Lj3:
	ldrb	w0,[sp, #8]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPCOLOR_$$_RGBA$BYTE$BYTE$BYTE$BYTE$$TRGBA32
_FPCOLOR_$$_RGBA$BYTE$BYTE$BYTE$BYTE$$TRGBA32:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#48
	strb	w0,[sp]
	strb	w1,[sp, #8]
	strb	w2,[sp, #16]
	strb	w3,[sp, #24]
	ldrb	w0,[sp]
	strb	w0,[sp, #34]
	ldrb	w0,[sp, #8]
	strb	w0,[sp, #33]
	ldrb	w0,[sp, #16]
	strb	w0,[sp, #32]
	ldrb	w0,[sp, #24]
	strb	w0,[sp, #35]
	ldr	w0,[sp, #32]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPCOLOR_$$_TRANSPARENTCOLOR$$TRGBA32
_FPCOLOR_$$_TRANSPARENTCOLOR$$TRGBA32:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#16
	movz	w3,#0
	movz	w2,#0
	movz	w1,#0
	movz	w0,#0
	bl	_FPCOLOR_$$_RGBA$BYTE$BYTE$BYTE$BYTE$$TRGBA32
	str	w0,[sp]
	ldr	w0,[sp]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPCOLOR_$$_INTCOLORTORGBA$LONGINT$BYTE$$TRGBA32
_FPCOLOR_$$_INTCOLORTORGBA$LONGINT$BYTE$$TRGBA32:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	w0,[sp]
	strb	w1,[sp, #8]
	ldr	w0,[sp]
	and	w0,w0,#255
	uxtb	w0,w0
	strb	w0,[sp, #18]
	ldr	w0,[sp]
	lsr	w0,w0,#8
	and	w0,w0,#255
	uxtb	w0,w0
	strb	w0,[sp, #17]
	ldr	w0,[sp]
	lsr	w0,w0,#16
	and	w0,w0,#255
	uxtb	w0,w0
	strb	w0,[sp, #16]
	ldrb	w0,[sp, #8]
	strb	w0,[sp, #19]
	ldr	w0,[sp, #16]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPCOLOR_$$_RGBAEQUAL$TRGBA32$TRGBA32$$BOOLEAN
_FPCOLOR_$$_RGBAEQUAL$TRGBA32$TRGBA32$$BOOLEAN:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	w0,[sp]
	str	w1,[sp, #8]
	ldrb	w1,[sp, #2]
	ldrb	w0,[sp, #10]
	cmp	w1,w0
	b.eq	Lj17
	b	Lj18
Lj17:
	ldrb	w0,[sp, #1]
	ldrb	w1,[sp, #9]
	cmp	w0,w1
	b.eq	Lj19
	b	Lj18
Lj19:
	ldrb	w0,[sp]
	ldrb	w1,[sp, #8]
	cmp	w0,w1
	b.eq	Lj20
	b	Lj18
Lj20:
	ldrb	w0,[sp, #3]
	ldrb	w1,[sp, #11]
	cmp	w0,w1
	b.eq	Lj21
	b	Lj18
Lj21:
	movz	w0,#1
	strb	w0,[sp, #16]
	b	Lj22
Lj18:
	strb	wzr,[sp, #16]
Lj22:
	ldrb	w0,[sp, #16]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPCOLOR_$$_BLENDNORMAL$TRGBA32$TRGBA32$BYTE$$TRGBA32
_FPCOLOR_$$_BLENDNORMAL$TRGBA32$TRGBA32$BYTE$$TRGBA32:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#48
	str	w0,[sp]
	str	w1,[sp, #8]
	strb	w2,[sp, #16]
	ldrb	w1,[sp, #3]
	ldrb	w0,[sp, #16]
	mul	w0,w0,w1
	add	w0,w0,#127
	movz	w1,#255
	udiv	w0,w0,w1
	str	w0,[sp, #28]
	ldr	w0,[sp, #28]
	cmp	w0,#0
	b.le	Lj25
	b	Lj26
Lj25:
	ldr	w0,[sp, #8]
	str	w0,[sp, #24]
	b	Lj23
Lj26:
	ldr	w0,[sp, #28]
	cmp	w0,#255
	b.ge	Lj27
	b	Lj28
Lj27:
	ldrb	w0,[sp, #16]
	cmp	w0,#255
	b.hs	Lj29
	b	Lj28
Lj29:
	ldr	w0,[sp]
	str	w0,[sp, #24]
	b	Lj23
Lj28:
	ldr	w0,[sp, #28]
	movz	w1,#255
	sub	w0,w1,w0
	str	w0,[sp, #32]
	ldrb	w1,[sp, #2]
	ldrb	w0,[sp, #16]
	umull	x0,w1,w0
	add	x0,x0,#127
	movz	x1,#255
	udiv	x2,x0,x1
	ldrb	w0,[sp, #10]
	ldrsw	x1,[sp, #32]
	mul	x0,x1,x0
	add	x0,x0,#127
	movz	x1,#255
	sdiv	x0,x0,x1
	add	x0,x0,x2
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #36]
	ldr	w0,[sp, #36]
	cmp	w0,#0
	b.lt	Lj31
	b	Lj32
Lj31:
	movz	w0,#0
	b	Lj30
Lj32:
	ldr	w1,[sp, #36]
	cmp	w1,#255
	b.gt	Lj33
	b	Lj34
Lj33:
	movz	w0,#255
	b	Lj30
Lj34:
	ldrb	w0,[sp, #36]
Lj30:
	strb	w0,[sp, #26]
	ldrb	w1,[sp, #1]
	ldrb	w0,[sp, #16]
	umull	x0,w1,w0
	add	x0,x0,#127
	movz	x1,#255
	udiv	x2,x0,x1
	ldrb	w1,[sp, #9]
	ldrsw	x0,[sp, #32]
	mul	x0,x0,x1
	add	x0,x0,#127
	movz	x1,#255
	sdiv	x0,x0,x1
	add	x0,x0,x2
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #36]
	ldr	w0,[sp, #36]
	cmp	w0,#0
	b.lt	Lj36
	b	Lj37
Lj36:
	movz	w0,#0
	b	Lj35
Lj37:
	ldr	w1,[sp, #36]
	cmp	w1,#255
	b.gt	Lj38
	b	Lj39
Lj38:
	movz	w0,#255
	b	Lj35
Lj39:
	ldrb	w0,[sp, #36]
Lj35:
	strb	w0,[sp, #25]
	ldrb	w0,[sp]
	ldrb	w1,[sp, #16]
	umull	x0,w0,w1
	add	x0,x0,#127
	movz	x1,#255
	udiv	x2,x0,x1
	ldrb	w0,[sp, #8]
	ldrsw	x1,[sp, #32]
	mul	x0,x1,x0
	add	x0,x0,#127
	movz	x1,#255
	sdiv	x0,x0,x1
	add	x0,x0,x2
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #36]
	ldr	w0,[sp, #36]
	cmp	w0,#0
	b.lt	Lj41
	b	Lj42
Lj41:
	movz	w0,#0
	b	Lj40
Lj42:
	ldr	w1,[sp, #36]
	cmp	w1,#255
	b.gt	Lj43
	b	Lj44
Lj43:
	movz	w0,#255
	b	Lj40
Lj44:
	ldrb	w0,[sp, #36]
Lj40:
	strb	w0,[sp, #24]
	ldrb	w0,[sp, #11]
	ldrsw	x1,[sp, #32]
	mul	x0,x1,x0
	add	x0,x0,#127
	movz	x1,#255
	sdiv	x1,x0,x1
	ldrsw	x0,[sp, #28]
	add	x0,x0,x1
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #36]
	ldr	w0,[sp, #36]
	cmp	w0,#0
	b.lt	Lj46
	b	Lj47
Lj46:
	movz	w0,#0
	b	Lj45
Lj47:
	ldr	w1,[sp, #36]
	cmp	w1,#255
	b.gt	Lj48
	b	Lj49
Lj48:
	movz	w0,#255
	b	Lj45
Lj49:
	ldrb	w0,[sp, #36]
Lj45:
	strb	w0,[sp, #27]
Lj23:
	ldr	w0,[sp, #24]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPCOLOR_$$_LERPCOLOR$TRGBA32$TRGBA32$DOUBLE$$TRGBA32
_FPCOLOR_$$_LERPCOLOR$TRGBA32$TRGBA32$DOUBLE$$TRGBA32:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#48
	str	w0,[sp]
	str	w1,[sp, #8]
	str	d0,[sp, #16]
	ldr	d1,[sp, #16]
	adrp	x0,_$FPCOLOR$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPCOLOR$_Ld1@GOTPAGEOFF]
	ldur	d0,[x0]
	fcmpe	d1,d0
	b.lo	Lj53
	b	Lj54
Lj53:
	adrp	x0,_$FPCOLOR$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPCOLOR$_Ld1@GOTPAGEOFF]
	ldur	d1,[x0]
Lj54:
	adrp	x0,_$FPCOLOR$_Ld2@GOTPAGE
	ldr	x0,[x0, _$FPCOLOR$_Ld2@GOTPAGEOFF]
	ldur	d0,[x0]
	fcmpe	d1,d0
	b.gt	Lj55
	b	Lj56
Lj55:
	adrp	x0,_$FPCOLOR$_Ld2@GOTPAGE
	ldr	x0,[x0, _$FPCOLOR$_Ld2@GOTPAGEOFF]
	ldur	d1,[x0]
Lj56:
	str	d1,[sp, #32]
	ldrb	w0,[sp, #2]
	ucvtf	d2,w0
	ldrb	w0,[sp, #10]
	ldrb	w1,[sp, #2]
	sub	x0,x0,x1
	scvtf	d1,x0
	ldr	d0,[sp, #32]
	fmul	d0,d1,d0
	fadd	d0,d2,d0
	frintx	d0,d0
	fcvtzs	x0,d0
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #40]
	ldr	w0,[sp, #40]
	cmp	w0,#0
	b.lt	Lj58
	b	Lj59
Lj58:
	movz	w0,#0
	b	Lj57
Lj59:
	ldr	w1,[sp, #40]
	cmp	w1,#255
	b.gt	Lj60
	b	Lj61
Lj60:
	movz	w0,#255
	b	Lj57
Lj61:
	ldrb	w0,[sp, #40]
Lj57:
	strb	w0,[sp, #26]
	ldrb	w0,[sp, #1]
	ucvtf	d2,w0
	ldrb	w0,[sp, #9]
	ldrb	w1,[sp, #1]
	sub	x0,x0,x1
	scvtf	d1,x0
	ldr	d0,[sp, #32]
	fmul	d0,d1,d0
	fadd	d0,d2,d0
	frintx	d0,d0
	fcvtzs	x0,d0
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #40]
	ldr	w0,[sp, #40]
	cmp	w0,#0
	b.lt	Lj63
	b	Lj64
Lj63:
	movz	w1,#0
	b	Lj62
Lj64:
	ldr	w0,[sp, #40]
	cmp	w0,#255
	b.gt	Lj65
	b	Lj66
Lj65:
	movz	w1,#255
	b	Lj62
Lj66:
	ldrb	w1,[sp, #40]
Lj62:
	strb	w1,[sp, #25]
	ldrb	w0,[sp]
	ucvtf	d2,w0
	ldrb	w1,[sp, #8]
	ldrb	w0,[sp]
	sub	x0,x1,x0
	scvtf	d1,x0
	ldr	d0,[sp, #32]
	fmul	d0,d1,d0
	fadd	d0,d2,d0
	frintx	d0,d0
	fcvtzs	x0,d0
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #40]
	ldr	w0,[sp, #40]
	cmp	w0,#0
	b.lt	Lj68
	b	Lj69
Lj68:
	movz	w0,#0
	b	Lj67
Lj69:
	ldr	w1,[sp, #40]
	cmp	w1,#255
	b.gt	Lj70
	b	Lj71
Lj70:
	movz	w0,#255
	b	Lj67
Lj71:
	ldrb	w0,[sp, #40]
Lj67:
	strb	w0,[sp, #24]
	ldrb	w0,[sp, #3]
	ucvtf	d2,w0
	ldrb	w0,[sp, #11]
	ldrb	w1,[sp, #3]
	sub	x0,x0,x1
	scvtf	d1,x0
	ldr	d0,[sp, #32]
	fmul	d0,d1,d0
	fadd	d0,d2,d0
	frintx	d0,d0
	fcvtzs	x0,d0
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #40]
	ldr	w0,[sp, #40]
	cmp	w0,#0
	b.lt	Lj73
	b	Lj74
Lj73:
	movz	w0,#0
	b	Lj72
Lj74:
	ldr	w1,[sp, #40]
	cmp	w1,#255
	b.gt	Lj75
	b	Lj76
Lj75:
	movz	w0,#255
	b	Lj72
Lj76:
	ldrb	w0,[sp, #40]
Lj72:
	strb	w0,[sp, #27]
	ldr	w0,[sp, #24]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPCOLOR_$$_PREMULTIPLY$TRGBA32$$TRGBA32
_FPCOLOR_$$_PREMULTIPLY$TRGBA32$$TRGBA32:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#16
	str	w0,[sp]
	ldrb	w0,[sp, #3]
	cmp	w0,#0
	b.eq	Lj79
	b	Lj80
Lj79:
	bl	_FPCOLOR_$$_TRANSPARENTCOLOR$$TRGBA32
	str	w0,[sp, #8]
	b	Lj77
Lj80:
	ldrb	w0,[sp, #3]
	cmp	w0,#255
	b.eq	Lj81
	b	Lj82
Lj81:
	ldr	w0,[sp]
	str	w0,[sp, #8]
	b	Lj77
Lj82:
	ldrb	w0,[sp, #2]
	ldrb	w1,[sp, #3]
	mul	w0,w1,w0
	add	w0,w0,#127
	movz	w1,#255
	udiv	w0,w0,w1
	uxtb	w0,w0
	strb	w0,[sp, #10]
	ldrb	w0,[sp, #1]
	ldrb	w1,[sp, #3]
	mul	w0,w1,w0
	add	w0,w0,#127
	movz	w1,#255
	udiv	w0,w0,w1
	uxtb	w0,w0
	strb	w0,[sp, #9]
	ldrb	w0,[sp]
	ldrb	w1,[sp, #3]
	mul	w0,w1,w0
	add	w0,w0,#127
	movz	w1,#255
	udiv	w0,w0,w1
	uxtb	w0,w0
	strb	w0,[sp, #8]
	ldrb	w0,[sp, #3]
	strb	w0,[sp, #11]
Lj77:
	ldr	w0,[sp, #8]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPCOLOR_$$_UNPREMULTIPLY$TRGBA32$$TRGBA32
_FPCOLOR_$$_UNPREMULTIPLY$TRGBA32$$TRGBA32:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#16
	str	w0,[sp]
	ldrb	w0,[sp, #3]
	cmp	w0,#0
	b.eq	Lj85
	b	Lj86
Lj85:
	bl	_FPCOLOR_$$_TRANSPARENTCOLOR$$TRGBA32
	str	w0,[sp, #8]
	b	Lj83
Lj86:
	ldrb	w0,[sp, #3]
	cmp	w0,#255
	b.eq	Lj87
	b	Lj88
Lj87:
	ldr	w0,[sp]
	str	w0,[sp, #8]
	b	Lj83
Lj88:
	ldrb	w0,[sp, #2]
	movz	w1,#255
	umull	x2,w0,w1
	ldrb	w0,[sp, #3]
	movz	x1,#2
	sdiv	x0,x0,x1
	add	x0,x0,x2
	ldrb	w1,[sp, #3]
	sdiv	x0,x0,x1
	cmp	x1,#0
	b.ne	Lj89
	bl	FPC_DIVBYZERO
Lj89:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #12]
	ldr	w0,[sp, #12]
	cmp	w0,#0
	b.lt	Lj91
	b	Lj92
Lj91:
	movz	w0,#0
	b	Lj90
Lj92:
	ldr	w1,[sp, #12]
	cmp	w1,#255
	b.gt	Lj93
	b	Lj94
Lj93:
	movz	w0,#255
	b	Lj90
Lj94:
	ldrb	w0,[sp, #12]
Lj90:
	strb	w0,[sp, #10]
	ldrb	w0,[sp, #1]
	movz	w1,#255
	umull	x2,w0,w1
	ldrb	w0,[sp, #3]
	movz	x1,#2
	sdiv	x0,x0,x1
	add	x0,x0,x2
	ldrb	w1,[sp, #3]
	sdiv	x0,x0,x1
	cmp	x1,#0
	b.ne	Lj95
	bl	FPC_DIVBYZERO
Lj95:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #12]
	ldr	w0,[sp, #12]
	cmp	w0,#0
	b.lt	Lj97
	b	Lj98
Lj97:
	movz	w0,#0
	b	Lj96
Lj98:
	ldr	w1,[sp, #12]
	cmp	w1,#255
	b.gt	Lj99
	b	Lj100
Lj99:
	movz	w0,#255
	b	Lj96
Lj100:
	ldrb	w0,[sp, #12]
Lj96:
	strb	w0,[sp, #9]
	ldrb	w0,[sp]
	movz	w1,#255
	umull	x2,w0,w1
	ldrb	w0,[sp, #3]
	movz	x1,#2
	sdiv	x0,x0,x1
	add	x0,x0,x2
	ldrb	w1,[sp, #3]
	sdiv	x0,x0,x1
	cmp	x1,#0
	b.ne	Lj101
	bl	FPC_DIVBYZERO
Lj101:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #12]
	ldr	w0,[sp, #12]
	cmp	w0,#0
	b.lt	Lj103
	b	Lj104
Lj103:
	movz	w1,#0
	b	Lj102
Lj104:
	ldr	w0,[sp, #12]
	cmp	w0,#255
	b.gt	Lj105
	b	Lj106
Lj105:
	movz	w1,#255
	b	Lj102
Lj106:
	ldrb	w1,[sp, #12]
Lj102:
	strb	w1,[sp, #8]
	ldrb	w0,[sp, #3]
	strb	w0,[sp, #11]
Lj83:
	ldr	w0,[sp, #8]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPCOLOR_$$_RGBA_PREMUL$BYTE$BYTE$BYTE$BYTE$$TRGBA32
_FPCOLOR_$$_RGBA_PREMUL$BYTE$BYTE$BYTE$BYTE$$TRGBA32:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#48
	strb	w0,[sp]
	strb	w1,[sp, #8]
	strb	w2,[sp, #16]
	strb	w3,[sp, #24]
	ldrb	w0,[sp, #24]
	cmp	w0,#0
	b.eq	Lj109
	b	Lj110
Lj109:
	bl	_FPCOLOR_$$_TRANSPARENTCOLOR$$TRGBA32
	str	w0,[sp, #32]
	b	Lj107
Lj110:
	ldrb	w0,[sp, #24]
	cmp	w0,#255
	b.eq	Lj111
	b	Lj112
Lj111:
	ldrb	w0,[sp]
	strb	w0,[sp, #34]
	ldrb	w0,[sp, #8]
	strb	w0,[sp, #33]
	ldrb	w0,[sp, #16]
	strb	w0,[sp, #32]
	movz	w0,#255
	strb	w0,[sp, #35]
	b	Lj107
Lj112:
	ldrb	w0,[sp]
	ldrb	w1,[sp, #24]
	mul	w0,w1,w0
	add	w0,w0,#127
	movz	w1,#255
	udiv	w0,w0,w1
	uxtb	w0,w0
	strb	w0,[sp, #34]
	ldrb	w0,[sp, #8]
	ldrb	w1,[sp, #24]
	mul	w0,w1,w0
	add	w0,w0,#127
	movz	w1,#255
	udiv	w0,w0,w1
	uxtb	w0,w0
	strb	w0,[sp, #33]
	ldrb	w0,[sp, #16]
	ldrb	w1,[sp, #24]
	mul	w0,w1,w0
	add	w0,w0,#127
	movz	w1,#255
	udiv	w0,w0,w1
	uxtb	w0,w0
	strb	w0,[sp, #32]
	ldrb	w0,[sp, #24]
	strb	w0,[sp, #35]
Lj107:
	ldr	w0,[sp, #32]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret
# End asmlist al_procedures
# Begin asmlist al_typedconsts

.const
	.align 3
.globl	_$FPCOLOR$_Ld1
_$FPCOLOR$_Ld1:
	.byte	0,0,0,0,0,0,0,0

.const
	.align 3
.globl	_$FPCOLOR$_Ld2
_$FPCOLOR$_Ld2:
	.byte	0,0,0,0,0,0,240,63
# End asmlist al_typedconsts
# Begin asmlist al_rtti

.const_data
	.align 3
.globl	_INIT_$FPCOLOR_$$_TRGBA32
_INIT_$FPCOLOR_$$_TRGBA32:
	.byte	13,7
	.ascii	"TRGBA32"
	.byte	0,0,0,0,0,0,0
	.quad	0
	.long	4
	.byte	0,0,0,0
	.quad	0,0
	.long	0
	.byte	0,0,0,0

.const_data
	.align 3
.globl	_RTTI_$FPCOLOR_$$_TRGBA32
_RTTI_$FPCOLOR_$$_TRGBA32:
	.byte	13,7
	.ascii	"TRGBA32"
	.byte	0,0,0,0,0,0,0
	.quad	_INIT_$FPCOLOR_$$_TRGBA32
	.long	4,4
	.quad	_RTTI_$SYSTEM_$$_BYTE$indirect
	.quad	0
	.quad	_RTTI_$SYSTEM_$$_BYTE$indirect
	.quad	1
	.quad	_RTTI_$SYSTEM_$$_BYTE$indirect
	.quad	2
	.quad	_RTTI_$SYSTEM_$$_BYTE$indirect
	.quad	3
# End asmlist al_rtti
# Begin asmlist al_indirectglobals

.const_data
	.align 3
.globl	_INIT_$FPCOLOR_$$_TRGBA32$indirect
_INIT_$FPCOLOR_$$_TRGBA32$indirect:
	.quad	_INIT_$FPCOLOR_$$_TRGBA32

.const_data
	.align 3
.globl	_RTTI_$FPCOLOR_$$_TRGBA32$indirect
_RTTI_$FPCOLOR_$$_TRGBA32$indirect:
	.quad	_RTTI_$FPCOLOR_$$_TRGBA32
# End asmlist al_indirectglobals
	.subsections_via_symbols

