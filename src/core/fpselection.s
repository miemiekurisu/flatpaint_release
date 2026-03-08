# Begin asmlist al_procedures

.text
	.align 4
_FPSELECTION_$$_POINTINSIDEPOLYGON$array_of_TPOINT$DOUBLE$DOUBLE$$BOOLEAN:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#80
	str	x0,[sp]
	str	x1,[sp, #24]
	str	d0,[sp, #8]
	str	d1,[sp, #16]
	strb	wzr,[sp, #32]
	ldr	x0,[sp, #24]
	add	x0,x0,#1
	cmp	x0,#3
	b.lt	Lj5
	b	Lj6
Lj5:
	b	Lj3
Lj6:
	ldr	w0,[sp, #24]
	str	w0,[sp, #40]
	ldr	w2,[sp, #24]
	cmp	w2,#0
	b.ge	Lj7
	b	Lj8
Lj7:
	movn	w0,#0
	str	w0,[sp, #36]
	.align 2
Lj9:
	ldr	w0,[sp, #36]
	add	w0,w0,#1
	str	w0,[sp, #36]
	ldr	x0,[sp]
	ldrsw	x1,[sp, #36]
	add	x0,x0,x1,lsl #3
	ldur	w0,[x0]
	scvtf	s0,w0
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s1,[x0]
	fadd	s0,s0,s1
	fcvt	d0,s0
	str	d0,[sp, #48]
	ldr	x0,[sp]
	ldrsw	x1,[sp, #36]
	add	x0,x0,x1,lsl #3
	ldur	w0,[x0, #4]
	scvtf	s0,w0
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s1,[x0]
	fadd	s0,s0,s1
	fcvt	d0,s0
	str	d0,[sp, #56]
	ldr	x0,[sp]
	ldrsw	x1,[sp, #40]
	add	x0,x0,x1,lsl #3
	ldur	w0,[x0]
	scvtf	s0,w0
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s1,[x0]
	fadd	s0,s0,s1
	fcvt	d0,s0
	str	d0,[sp, #64]
	ldr	x0,[sp]
	ldrsw	x1,[sp, #40]
	add	x0,x0,x1,lsl #3
	ldur	w0,[x0, #4]
	scvtf	s0,w0
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s1,[x0]
	fadd	s0,s0,s1
	fcvt	d0,s0
	str	d0,[sp, #72]
	ldr	d0,[sp, #56]
	ldr	d1,[sp, #16]
	fcmpe	d0,d1
	cset	w0,gt
	ldr	d0,[sp, #72]
	ldr	d1,[sp, #16]
	fcmpe	d0,d1
	cset	w1,gt
	cmp	w0,w1
	b.ne	Lj12
	b	Lj13
Lj12:
	ldr	d0,[sp, #64]
	ldr	d1,[sp, #48]
	fsub	d2,d0,d1
	ldr	d1,[sp, #16]
	ldr	d0,[sp, #56]
	fsub	d0,d1,d0
	fmul	d2,d2,d0
	ldr	d1,[sp, #72]
	ldr	d0,[sp, #56]
	fsub	d0,d1,d0
	fdiv	d0,d2,d0
	ldr	d1,[sp, #48]
	fadd	d0,d0,d1
	ldr	d1,[sp, #8]
	fcmpe	d1,d0
	b.lo	Lj14
	b	Lj13
Lj14:
	ldrb	w0,[sp, #32]
	cmp	w0,#0
	cset	w0,eq
	strb	w0,[sp, #32]
Lj13:
	ldr	w0,[sp, #36]
	str	w0,[sp, #40]
	ldr	w0,[sp, #36]
	cmp	w0,w2
	b.ge	Lj11
	b	Lj9
Lj11:
Lj8:
Lj3:
	ldrb	w0,[sp, #32]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CREATE$LONGINT$LONGINT$$TSELECTIONMASK
_FPSELECTION$_$TSELECTIONMASK_$__$$_CREATE$LONGINT$LONGINT$$TSELECTIONMASK:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#448
	str	x0,[sp, #24]
	str	x1,[sp, #16]
	str	w2,[sp]
	str	w3,[sp, #8]
	ldr	x0,[sp, #16]
	cmp	x0,#1
	b.eq	Lj17
	b	Lj18
Lj17:
	ldr	x0,[sp, #24]
	ldr	x1,[sp, #24]
	ldr	x1,[x1, #104]
	blr	x1
	str	x0,[sp, #24]
Lj18:
	ldr	x0,[sp, #24]
	cmp	x0,#0
	b.eq	Lj19
	b	Lj20
Lj19:
	b	Lj15
Lj20:
	add	x2,sp,#40
	add	x1,sp,#64
	movz	w0,#1
	bl	fpc_pushexceptaddr
	bl	fpc_setjmp
	sxtw	x1,w0
	str	x1,[sp, #232]
	cmp	w0,#0
	b.ne	Lj25
	movn	x0,#0
	str	x0,[sp, #32]
	ldr	x0,[sp, #24]
	movz	x1,#0
	bl	_SYSTEM$_$TOBJECT_$__$$_CREATE$$TOBJECT
	ldr	w2,[sp, #8]
	ldr	w1,[sp]
	ldr	x0,[sp, #24]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSIZE$LONGINT$LONGINT
	movz	x0,#1
	str	x0,[sp, #32]
	ldr	x0,[sp, #24]
	cmp	x0,#0
	b.ne	Lj27
	b	Lj28
Lj27:
	ldr	x0,[sp, #16]
	cmp	x0,#0
	b.ne	Lj29
	b	Lj28
Lj29:
	ldr	x0,[sp, #24]
	ldr	x1,[sp, #24]
	ldr	x1,[x1]
	ldr	x1,[x1, #136]
	blr	x1
Lj28:
Lj25:
	bl	fpc_popaddrstack
	ldr	x0,[sp, #232]
	cmp	x0,#0
	b.eq	Lj23
	add	x2,sp,#240
	add	x1,sp,#264
	movz	w0,#1
	bl	fpc_pushexceptaddr
	bl	fpc_setjmp
	sxtw	x1,w0
	str	x1,[sp, #432]
	cmp	w0,#0
	b.ne	Lj30
	ldr	x0,[sp, #16]
	cmp	x0,#0
	b.ne	Lj31
	b	Lj32
Lj31:
	ldr	x1,[sp, #32]
	ldr	x0,[sp, #24]
	ldr	x2,[sp, #24]
	ldr	x2,[x2]
	ldr	x2,[x2, #96]
	blr	x2
Lj32:
	bl	fpc_popaddrstack
	bl	fpc_reraise
Lj30:
	bl	fpc_popaddrstack
	ldr	x0,[sp, #432]
	cmp	x0,#0
	b.eq	Lj33
	bl	fpc_raise_nested
Lj33:
	bl	fpc_doneexception
	b	Lj23
Lj23:
Lj15:
	ldr	x0,[sp, #24]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_INDEXOF$LONGINT$LONGINT$$LONGINT
_FPSELECTION$_$TSELECTIONMASK_$__$$_INDEXOF$LONGINT$LONGINT$$LONGINT:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	x0,[sp, #16]
	str	w1,[sp]
	str	w2,[sp, #8]
	ldr	x0,[sp, #16]
	ldr	w1,[x0, #8]
	ldr	w0,[sp, #8]
	mul	w0,w0,w1
	ldr	w1,[sp]
	add	w0,w1,w0
	str	w0,[sp, #24]
	ldr	w0,[sp, #24]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSIZE$LONGINT$LONGINT
_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSIZE$LONGINT$LONGINT:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	x0,[sp, #16]
	str	w1,[sp]
	str	w2,[sp, #8]
	ldr	w0,[sp]
	cmp	w0,#1
	b.lt	Lj38
	b	Lj39
Lj38:
	movz	w0,#1
	b	Lj40
Lj39:
	ldr	w0,[sp]
Lj40:
	ldr	x1,[sp, #16]
	str	w0,[x1, #8]
	ldr	w0,[sp, #8]
	cmp	w0,#1
	b.lt	Lj41
	b	Lj42
Lj41:
	movz	w0,#1
	b	Lj43
Lj42:
	ldr	w0,[sp, #8]
Lj43:
	ldr	x1,[sp, #16]
	str	w0,[x1, #12]
	ldr	x0,[sp, #16]
	ldr	x2,[sp, #16]
	ldr	w1,[x0, #8]
	ldr	w0,[x2, #12]
	smull	x0,w1,w0
	str	x0,[sp, #24]
	adrp	x1,_RTTI_$FPSELECTION_$$_def00000002@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def00000002@GOTPAGEOFF]
	ldr	x0,[sp, #16]
	add	x0,x0,#16
	add	x3,sp,#24
	movz	x2,#1
	bl	fpc_dynarray_setlength
	ldr	x0,[sp, #16]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CLEAR
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CLEAR
_FPSELECTION$_$TSELECTIONMASK_$__$$_CLEAR:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#16
	str	x0,[sp]
	ldr	x0,[sp]
	ldr	x0,[x0, #16]
	cmp	x0,#0
	b.eq	Lj46
	ldur	x0,[x0, #-8]
	add	x0,x0,#1
Lj46:
	cmp	x0,#0
	b.gt	Lj47
	b	Lj48
Lj47:
	ldr	x0,[sp]
	ldr	x1,[x0, #16]
	cmp	x1,#0
	b.eq	Lj49
	ldur	x1,[x1, #-8]
	add	x1,x1,#1
Lj49:
	ldr	x0,[sp]
	ldr	x0,[x0, #16]
	movz	w2,#0
	bl	_SYSTEM_$$_FILLCHAR$formal$INT64$BYTE
Lj48:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTALL
_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTALL:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#16
	str	x0,[sp]
	ldr	x0,[sp]
	ldr	x0,[x0, #16]
	cmp	x0,#0
	b.eq	Lj52
	ldur	x0,[x0, #-8]
	add	x0,x0,#1
Lj52:
	cmp	x0,#0
	b.gt	Lj53
	b	Lj54
Lj53:
	ldr	x0,[sp]
	ldr	x1,[x0, #16]
	cmp	x1,#0
	b.eq	Lj55
	ldur	x1,[x1, #-8]
	add	x1,x1,#1
Lj55:
	ldr	x0,[sp]
	ldr	x0,[x0, #16]
	movz	w2,#255
	bl	_SYSTEM_$$_FILLCHAR$formal$INT64$BYTE
Lj54:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_INVERT
_FPSELECTION$_$TSELECTIONMASK_$__$$_INVERT:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#16
	str	x0,[sp]
	ldr	x0,[sp]
	ldr	x0,[x0, #16]
	bl	fpc_dynarray_high
	ubfiz	x0,x0,#0,#32
	cmp	w0,#0
	b.ge	Lj58
	b	Lj59
Lj58:
	movn	w1,#0
	str	w1,[sp, #8]
	.align 2
Lj60:
	ldr	w1,[sp, #8]
	add	w1,w1,#1
	str	w1,[sp, #8]
	ldr	x1,[sp]
	ldr	x1,[x1, #16]
	ldrsw	x2,[sp, #8]
	ldrb	w1,[x1, x2]
	movz	w2,#255
	sub	w1,w2,w1
	uxtb	w3,w1
	ldr	x1,[sp]
	ldr	x1,[x1, #16]
	ldrsw	x2,[sp, #8]
	strb	w3,[x1, x2]
	ldr	w1,[sp, #8]
	cmp	w1,w0
	b.ge	Lj62
	b	Lj60
Lj62:
Lj59:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_ASSIGN$TSELECTIONMASK
_FPSELECTION$_$TSELECTIONMASK_$__$$_ASSIGN$TSELECTIONMASK:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	x0,[sp, #8]
	str	x1,[sp]
	ldr	x0,[sp]
	cmp	x0,#0
	b.eq	Lj65
	b	Lj66
Lj65:
	b	Lj63
Lj66:
	ldr	x1,[sp, #8]
	ldr	x0,[sp]
	ldr	w0,[x0, #8]
	str	w0,[x1, #8]
	ldr	x1,[sp, #8]
	ldr	x0,[sp]
	ldr	w0,[x0, #12]
	str	w0,[x1, #12]
	ldr	x0,[sp]
	ldr	x0,[x0, #16]
	cmp	x0,#0
	b.eq	Lj67
	ldur	x0,[x0, #-8]
	add	x0,x0,#1
Lj67:
	str	x0,[sp, #16]
	adrp	x1,_RTTI_$FPSELECTION_$$_def00000002@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def00000002@GOTPAGEOFF]
	ldr	x0,[sp, #8]
	add	x0,x0,#16
	add	x3,sp,#16
	movz	x2,#1
	bl	fpc_dynarray_setlength
	ldr	x0,[sp, #8]
	ldr	x0,[x0, #16]
	cmp	x0,#0
	b.eq	Lj68
	ldur	x0,[x0, #-8]
	add	x0,x0,#1
Lj68:
	cmp	x0,#0
	b.gt	Lj69
	b	Lj70
Lj69:
	ldr	x0,[sp, #8]
	ldr	x2,[x0, #16]
	cmp	x2,#0
	b.eq	Lj71
	ldur	x2,[x2, #-8]
	add	x2,x2,#1
Lj71:
	ldr	x0,[sp, #8]
	ldr	x1,[x0, #16]
	ldr	x0,[sp]
	ldr	x0,[x0, #16]
	bl	_SYSTEM_$$_MOVE$formal$formal$INT64
Lj70:
Lj63:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CLONE$$TSELECTIONMASK
_FPSELECTION$_$TSELECTIONMASK_$__$$_CLONE$$TSELECTIONMASK:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#16
	str	x0,[sp]
	ldr	x0,[sp]
	ldr	w3,[x0, #12]
	ldr	x0,[sp]
	ldr	w2,[x0, #8]
	movz	x1,#1
	adrp	x0,_VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGE
	ldr	x0,[x0, _VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGEOFF]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CREATE$LONGINT$LONGINT$$TSELECTIONMASK
	str	x0,[sp, #8]
	ldr	x1,[sp]
	ldr	x0,[sp, #8]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_ASSIGN$TSELECTIONMASK
	ldr	x0,[sp, #8]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_INTERSECTWITH$TSELECTIONMASK
_FPSELECTION$_$TSELECTIONMASK_$__$$_INTERSECTWITH$TSELECTIONMASK:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	stp	x19,x20,[sp, #-16]!
	sub	sp,sp,#32
	str	x0,[sp, #8]
	str	x1,[sp]
	ldr	x0,[sp]
	cmp	x0,#0
	b.eq	Lj76
	b	Lj77
Lj76:
	ldr	x0,[sp, #8]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CLEAR
	b	Lj74
Lj77:
	ldr	x0,[sp, #8]
	ldr	w0,[x0, #12]
	sub	w19,w0,#1
	cmp	w19,#0
	b.ge	Lj78
	b	Lj79
Lj78:
	movn	w0,#0
	str	w0,[sp, #20]
	.align 2
Lj80:
	ldr	w0,[sp, #20]
	add	w0,w0,#1
	str	w0,[sp, #20]
	ldr	x0,[sp, #8]
	ldr	w0,[x0, #8]
	sub	w20,w0,#1
	cmp	w20,#0
	b.ge	Lj83
	b	Lj84
Lj83:
	movn	w0,#0
	str	w0,[sp, #16]
	.align 2
Lj85:
	ldr	w0,[sp, #16]
	add	w0,w0,#1
	str	w0,[sp, #16]
	ldr	w2,[sp, #20]
	ldr	w1,[sp, #16]
	ldr	x0,[sp]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_COVERAGE$LONGINT$LONGINT$$BYTE
	str	w0,[sp, #24]
	ldr	x0,[sp, #8]
	ldr	x2,[x0, #16]
	ldr	x0,[sp, #8]
	ldr	w0,[x0, #8]
	ldr	w1,[sp, #20]
	mul	w0,w1,w0
	ldr	w1,[sp, #16]
	add	w0,w1,w0
	sxtw	x0,w0
	ldrb	w0,[x2, x0]
	str	w0,[sp, #28]
	ldr	w0,[sp, #28]
	ldr	w1,[sp, #24]
	cmp	w0,w1
	b.lt	Lj88
	b	Lj89
Lj88:
	ldr	w0,[sp, #28]
	b	Lj90
Lj89:
	ldr	w0,[sp, #24]
Lj90:
	uxtb	w3,w0
	ldr	x0,[sp, #8]
	ldr	x2,[x0, #16]
	ldr	x0,[sp, #8]
	ldr	w0,[x0, #8]
	ldr	w1,[sp, #20]
	mul	w0,w1,w0
	ldr	w1,[sp, #16]
	add	w0,w1,w0
	sxtw	x0,w0
	strb	w3,[x2, x0]
	ldr	w0,[sp, #16]
	cmp	w0,w20
	b.ge	Lj87
	b	Lj85
Lj87:
Lj84:
	ldr	w0,[sp, #20]
	cmp	w0,w19
	b.ge	Lj82
	b	Lj80
Lj82:
Lj79:
Lj74:
	add	sp,sp,#32
	ldp	x19,x20,[sp], #16
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_INBOUNDS$LONGINT$LONGINT$$BOOLEAN
_FPSELECTION$_$TSELECTIONMASK_$__$$_INBOUNDS$LONGINT$LONGINT$$BOOLEAN:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	x0,[sp, #16]
	str	w1,[sp]
	str	w2,[sp, #8]
	ldr	w0,[sp]
	cmp	w0,#0
	b.ge	Lj93
	b	Lj94
Lj93:
	ldr	w0,[sp, #8]
	cmp	w0,#0
	b.ge	Lj95
	b	Lj94
Lj95:
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #8]
	ldr	w1,[sp]
	cmp	w0,w1
	b.gt	Lj96
	b	Lj94
Lj96:
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #12]
	ldr	w1,[sp, #8]
	cmp	w0,w1
	b.gt	Lj97
	b	Lj94
Lj97:
	movz	w0,#1
	strb	w0,[sp, #24]
	b	Lj98
Lj94:
	strb	wzr,[sp, #24]
Lj98:
	ldrb	w0,[sp, #24]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_GETSELECTED$LONGINT$LONGINT$$BOOLEAN
_FPSELECTION$_$TSELECTIONMASK_$__$$_GETSELECTED$LONGINT$LONGINT$$BOOLEAN:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	x0,[sp, #16]
	str	w1,[sp]
	str	w2,[sp, #8]
	ldr	w0,[sp]
	cmp	w0,#0
	b.ge	Lj101
	b	Lj102
Lj101:
	ldr	w0,[sp, #8]
	cmp	w0,#0
	b.ge	Lj103
	b	Lj102
Lj103:
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #8]
	ldr	w1,[sp]
	cmp	w0,w1
	b.gt	Lj104
	b	Lj102
Lj104:
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #12]
	ldr	w1,[sp, #8]
	cmp	w0,w1
	b.gt	Lj105
	b	Lj102
Lj105:
	movz	w0,#1
	b	Lj106
Lj102:
	movz	w0,#0
Lj106:
	cmp	w0,#0
	b.eq	Lj107
	b	Lj108
Lj107:
	strb	wzr,[sp, #24]
	b	Lj99
Lj108:
	ldr	x0,[sp, #16]
	ldr	x2,[x0, #16]
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #8]
	ldr	w1,[sp, #8]
	mul	w0,w1,w0
	ldr	w1,[sp]
	add	w0,w1,w0
	sxtw	x0,w0
	ldrb	w0,[x2, x0]
	cmp	w0,#0
	cset	w0,ne
	strb	w0,[sp, #24]
Lj99:
	ldrb	w0,[sp, #24]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSELECTED$LONGINT$LONGINT$BOOLEAN
_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSELECTED$LONGINT$LONGINT$BOOLEAN:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	x0,[sp, #24]
	str	w1,[sp]
	str	w2,[sp, #8]
	strb	w3,[sp, #16]
	ldr	w0,[sp]
	cmp	w0,#0
	b.ge	Lj111
	b	Lj112
Lj111:
	ldr	w0,[sp, #8]
	cmp	w0,#0
	b.ge	Lj113
	b	Lj112
Lj113:
	ldr	x0,[sp, #24]
	ldr	w0,[x0, #8]
	ldr	w1,[sp]
	cmp	w0,w1
	b.gt	Lj114
	b	Lj112
Lj114:
	ldr	x0,[sp, #24]
	ldr	w1,[x0, #12]
	ldr	w0,[sp, #8]
	cmp	w1,w0
	b.gt	Lj115
	b	Lj112
Lj115:
	movz	w0,#1
	b	Lj116
Lj112:
	movz	w0,#0
Lj116:
	cmp	w0,#0
	b.eq	Lj117
	b	Lj118
Lj117:
	b	Lj109
Lj118:
	ldrb	w0,[sp, #16]
	cmp	w0,#0
	b.ne	Lj119
	b	Lj120
Lj119:
	ldr	x0,[sp, #24]
	ldr	x2,[x0, #16]
	ldr	x0,[sp, #24]
	ldr	w1,[x0, #8]
	ldr	w0,[sp, #8]
	mul	w0,w0,w1
	ldr	w1,[sp]
	add	w0,w1,w0
	sxtw	x0,w0
	movz	w1,#255
	strb	w1,[x2, x0]
	b	Lj121
Lj120:
	ldr	x0,[sp, #24]
	ldr	x2,[x0, #16]
	ldr	x0,[sp, #24]
	ldr	w1,[x0, #8]
	ldr	w0,[sp, #8]
	mul	w0,w0,w1
	ldr	w1,[sp]
	add	w0,w1,w0
	sxtw	x0,w0
	strb	wzr,[x2, x0]
Lj121:
Lj109:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_HASSELECTION$$BOOLEAN
_FPSELECTION$_$TSELECTIONMASK_$__$$_HASSELECTION$$BOOLEAN:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#16
	str	x0,[sp]
	ldr	x0,[sp]
	ldr	x0,[x0, #16]
	bl	fpc_dynarray_high
	ubfiz	x0,x0,#0,#32
	cmp	w0,#0
	b.ge	Lj124
	b	Lj125
Lj124:
	movn	w1,#0
	str	w1,[sp, #12]
	.align 2
Lj126:
	ldr	w1,[sp, #12]
	add	w1,w1,#1
	str	w1,[sp, #12]
	ldr	x1,[sp]
	ldr	x2,[x1, #16]
	ldrsw	x1,[sp, #12]
	ldrb	w1,[x2, x1]
	cmp	w1,#0
	b.ne	Lj129
	b	Lj130
Lj129:
	movz	w1,#1
	strb	w1,[sp, #8]
	b	Lj122
Lj130:
	ldr	w1,[sp, #12]
	cmp	w1,w0
	b.ge	Lj128
	b	Lj126
Lj128:
Lj125:
	strb	wzr,[sp, #8]
Lj122:
	ldrb	w0,[sp, #8]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_COVERAGE$LONGINT$LONGINT$$BYTE
_FPSELECTION$_$TSELECTIONMASK_$__$$_COVERAGE$LONGINT$LONGINT$$BYTE:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	x0,[sp, #16]
	str	w1,[sp]
	str	w2,[sp, #8]
	ldr	w0,[sp]
	cmp	w0,#0
	b.ge	Lj133
	b	Lj134
Lj133:
	ldr	w0,[sp, #8]
	cmp	w0,#0
	b.ge	Lj135
	b	Lj134
Lj135:
	ldr	x0,[sp, #16]
	ldr	w1,[x0, #8]
	ldr	w0,[sp]
	cmp	w1,w0
	b.gt	Lj136
	b	Lj134
Lj136:
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #12]
	ldr	w1,[sp, #8]
	cmp	w0,w1
	b.gt	Lj137
	b	Lj134
Lj137:
	movz	w0,#1
	b	Lj138
Lj134:
	movz	w0,#0
Lj138:
	cmp	w0,#0
	b.eq	Lj139
	b	Lj140
Lj139:
	strb	wzr,[sp, #24]
	b	Lj131
Lj140:
	ldr	x0,[sp, #16]
	ldr	x2,[x0, #16]
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #8]
	ldr	w1,[sp, #8]
	mul	w0,w1,w0
	ldr	w1,[sp]
	add	w0,w1,w0
	sxtw	x0,w0
	ldrb	w0,[x2, x0]
	strb	w0,[sp, #24]
Lj131:
	ldrb	w0,[sp, #24]
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETCOVERAGE$LONGINT$LONGINT$BYTE
_FPSELECTION$_$TSELECTIONMASK_$__$$_SETCOVERAGE$LONGINT$LONGINT$BYTE:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	x0,[sp, #24]
	str	w1,[sp]
	str	w2,[sp, #8]
	strb	w3,[sp, #16]
	ldr	w0,[sp]
	cmp	w0,#0
	b.ge	Lj143
	b	Lj144
Lj143:
	ldr	w0,[sp, #8]
	cmp	w0,#0
	b.ge	Lj145
	b	Lj144
Lj145:
	ldr	x0,[sp, #24]
	ldr	w0,[x0, #8]
	ldr	w1,[sp]
	cmp	w0,w1
	b.gt	Lj146
	b	Lj144
Lj146:
	ldr	x0,[sp, #24]
	ldr	w0,[x0, #12]
	ldr	w1,[sp, #8]
	cmp	w0,w1
	b.gt	Lj147
	b	Lj144
Lj147:
	movz	w0,#1
	b	Lj148
Lj144:
	movz	w0,#0
Lj148:
	cmp	w0,#0
	b.eq	Lj149
	b	Lj150
Lj149:
	b	Lj141
Lj150:
	ldr	x0,[sp, #24]
	ldr	x2,[x0, #16]
	ldr	x0,[sp, #24]
	ldr	w1,[x0, #8]
	ldr	w0,[sp, #8]
	mul	w0,w0,w1
	ldr	w1,[sp]
	add	w0,w1,w0
	sxtw	x1,w0
	ldrb	w0,[sp, #16]
	strb	w0,[x2, x1]
Lj141:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_FEATHER$LONGINT
_FPSELECTION$_$TSELECTIONMASK_$__$$_FEATHER$LONGINT:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#288
	str	x0,[sp, #8]
	str	w1,[sp]
	str	xzr,[sp, #32]
	str	xzr,[sp, #40]
	str	xzr,[sp, #48]
	add	x2,sp,#72
	add	x1,sp,#96
	movz	w0,#1
	bl	fpc_pushexceptaddr
	bl	fpc_setjmp
	sxtw	x1,w0
	str	x1,[sp, #264]
	cmp	w0,#0
	b.ne	Lj154
	ldr	w0,[sp]
	cmp	w0,#0
	b.lt	Lj155
	b	Lj156
Lj155:
	movz	w0,#0
	b	Lj157
Lj156:
	ldr	w0,[sp]
Lj157:
	str	w0,[sp, #16]
	ldr	x0,[sp, #8]
	ldr	x0,[x0, #16]
	cmp	x0,#0
	b.eq	Lj158
	ldur	x0,[x0, #-8]
	add	x0,x0,#1
Lj158:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #20]
	ldr	w0,[sp, #16]
	cmp	w0,#0
	b.le	Lj159
	b	Lj160
Lj160:
	ldr	w0,[sp, #20]
	cmp	w0,#0
	b.eq	Lj159
	b	Lj161
Lj159:
	b	Lj154
Lj161:
	ldrsw	x0,[sp, #20]
	str	x0,[sp, #272]
	adrp	x1,_RTTI_$FPSELECTION_$$_def00000035@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def00000035@GOTPAGEOFF]
	add	x3,sp,#272
	add	x0,sp,#32
	movz	x2,#1
	bl	fpc_dynarray_setlength
	ldrsw	x0,[sp, #20]
	str	x0,[sp, #272]
	adrp	x1,_RTTI_$FPSELECTION_$$_def00000036@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def00000036@GOTPAGEOFF]
	add	x3,sp,#272
	add	x0,sp,#40
	movz	x2,#1
	bl	fpc_dynarray_setlength
	ldrsw	x0,[sp, #20]
	str	x0,[sp, #272]
	adrp	x1,_RTTI_$FPSELECTION_$$_def00000037@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def00000037@GOTPAGEOFF]
	add	x3,sp,#272
	add	x0,sp,#48
	movz	x2,#1
	bl	fpc_dynarray_setlength
	ldr	w0,[sp, #20]
	sub	w0,w0,#1
	cmp	w0,#0
	b.ge	Lj162
	b	Lj163
Lj162:
	movn	w1,#0
	str	w1,[sp, #24]
	.align 2
Lj164:
	ldr	w1,[sp, #24]
	add	w1,w1,#1
	str	w1,[sp, #24]
	ldr	x3,[sp, #48]
	ldrsw	x4,[sp, #24]
	ldr	x1,[sp, #8]
	ldr	x1,[x1, #16]
	ldrsw	x2,[sp, #24]
	ldrb	w1,[x1, x2]
	cmp	w1,#0
	cset	w1,ne
	strb	w1,[x3, x4]
	ldr	x2,[sp, #48]
	ldrsw	x1,[sp, #24]
	ldrb	w1,[x2, x1]
	cmp	w1,#0
	b.ne	Lj167
	b	Lj168
Lj167:
	ldr	x2,[sp, #32]
	ldrsw	x3,[sp, #24]
	movz	w1,#16,lsl #16
	str	w1,[x2, x3, lsl #2]
	ldr	x2,[sp, #40]
	ldrsw	x1,[sp, #24]
	str	wzr,[x2, x1, lsl #2]
	b	Lj169
Lj168:
	ldr	x2,[sp, #32]
	ldrsw	x1,[sp, #24]
	str	wzr,[x2, x1, lsl #2]
	ldr	x1,[sp, #40]
	ldrsw	x2,[sp, #24]
	movz	w3,#16,lsl #16
	str	w3,[x1, x2, lsl #2]
Lj169:
	ldr	w1,[sp, #24]
	cmp	w1,w0
	b.ge	Lj166
	b	Lj164
Lj166:
Lj163:
	ldr	x0,[sp, #8]
	ldr	w0,[x0, #12]
	sub	w0,w0,#1
	cmp	w0,#0
	b.ge	Lj170
	b	Lj171
Lj170:
	movn	w1,#0
	str	w1,[sp, #60]
	.align 2
Lj172:
	ldr	w1,[sp, #60]
	add	w1,w1,#1
	str	w1,[sp, #60]
	ldr	x1,[sp, #8]
	ldr	w1,[x1, #8]
	sub	w1,w1,#1
	cmp	w1,#0
	b.ge	Lj175
	b	Lj176
Lj175:
	movn	w2,#0
	str	w2,[sp, #56]
	.align 2
Lj177:
	ldr	w2,[sp, #56]
	add	w2,w2,#1
	str	w2,[sp, #56]
	ldr	x2,[sp, #8]
	ldr	w2,[x2, #8]
	ldr	w3,[sp, #60]
	mul	w2,w3,w2
	ldr	w3,[sp, #56]
	add	w2,w3,w2
	str	w2,[sp, #64]
	ldr	w2,[sp, #56]
	cmp	w2,#0
	b.gt	Lj180
	b	Lj181
Lj180:
	ldr	x3,[sp, #32]
	ldrsw	x2,[sp, #64]
	sub	x2,x2,#1
	ldrsw	x2,[x3, x2, lsl #2]
	add	x2,x2,#1
	str	x2,[sp, #272]
	ldr	x3,[sp, #32]
	ldrsw	x2,[sp, #64]
	ldrsw	x2,[x3, x2, lsl #2]
	str	x2,[sp, #280]
	ldr	x3,[sp, #280]
	ldr	x2,[sp, #272]
	cmp	x3,x2
	b.lt	Lj182
	b	Lj183
Lj182:
	ldr	x2,[sp, #280]
	b	Lj184
Lj183:
	ldr	x2,[sp, #272]
Lj184:
	ubfiz	x2,x2,#0,#32
	ldr	x4,[sp, #32]
	ldrsw	x3,[sp, #64]
	str	w2,[x4, x3, lsl #2]
Lj181:
	ldr	w2,[sp, #60]
	cmp	w2,#0
	b.gt	Lj185
	b	Lj186
Lj185:
	ldr	x4,[sp, #32]
	ldr	x2,[sp, #8]
	ldrsw	x3,[x2, #8]
	ldrsw	x2,[sp, #64]
	sub	x2,x2,x3
	ldrsw	x2,[x4, x2, lsl #2]
	add	x2,x2,#1
	str	x2,[sp, #272]
	ldr	x2,[sp, #32]
	ldrsw	x3,[sp, #64]
	ldrsw	x2,[x2, x3, lsl #2]
	str	x2,[sp, #280]
	ldr	x3,[sp, #280]
	ldr	x2,[sp, #272]
	cmp	x3,x2
	b.lt	Lj187
	b	Lj188
Lj187:
	ldr	x2,[sp, #280]
	b	Lj189
Lj188:
	ldr	x2,[sp, #272]
Lj189:
	ubfiz	x2,x2,#0,#32
	ldr	x3,[sp, #32]
	ldrsw	x4,[sp, #64]
	str	w2,[x3, x4, lsl #2]
Lj186:
	ldr	w2,[sp, #56]
	cmp	w2,#0
	b.gt	Lj190
	b	Lj191
Lj190:
	ldr	x3,[sp, #40]
	ldrsw	x2,[sp, #64]
	sub	x2,x2,#1
	ldrsw	x2,[x3, x2, lsl #2]
	add	x2,x2,#1
	str	x2,[sp, #272]
	ldr	x3,[sp, #40]
	ldrsw	x2,[sp, #64]
	ldrsw	x2,[x3, x2, lsl #2]
	str	x2,[sp, #280]
	ldr	x3,[sp, #280]
	ldr	x2,[sp, #272]
	cmp	x3,x2
	b.lt	Lj192
	b	Lj193
Lj192:
	ldr	x2,[sp, #280]
	b	Lj194
Lj193:
	ldr	x2,[sp, #272]
Lj194:
	ubfiz	x2,x2,#0,#32
	ldr	x3,[sp, #40]
	ldrsw	x4,[sp, #64]
	str	w2,[x3, x4, lsl #2]
Lj191:
	ldr	w2,[sp, #60]
	cmp	w2,#0
	b.gt	Lj195
	b	Lj196
Lj195:
	ldr	x4,[sp, #40]
	ldr	x2,[sp, #8]
	ldrsw	x3,[x2, #8]
	ldrsw	x2,[sp, #64]
	sub	x2,x2,x3
	ldrsw	x2,[x4, x2, lsl #2]
	add	x2,x2,#1
	str	x2,[sp, #272]
	ldr	x2,[sp, #40]
	ldrsw	x3,[sp, #64]
	ldrsw	x2,[x2, x3, lsl #2]
	str	x2,[sp, #280]
	ldr	x3,[sp, #280]
	ldr	x2,[sp, #272]
	cmp	x3,x2
	b.lt	Lj197
	b	Lj198
Lj197:
	ldr	x2,[sp, #280]
	b	Lj199
Lj198:
	ldr	x2,[sp, #272]
Lj199:
	ubfiz	x3,x2,#0,#32
	ldr	x2,[sp, #40]
	ldrsw	x4,[sp, #64]
	str	w3,[x2, x4, lsl #2]
Lj196:
	ldr	w2,[sp, #56]
	cmp	w2,w1
	b.ge	Lj179
	b	Lj177
Lj179:
Lj176:
	ldr	w1,[sp, #60]
	cmp	w1,w0
	b.ge	Lj174
	b	Lj172
Lj174:
Lj171:
	ldr	x0,[sp, #8]
	ldr	w0,[x0, #12]
	sub	w0,w0,#1
	cmp	w0,#0
	b.ge	Lj200
	b	Lj201
Lj200:
	str	w0,[sp, #60]
	ldr	w0,[sp, #60]
	add	w0,w0,#1
	str	w0,[sp, #60]
	.align 2
Lj202:
	ldr	w0,[sp, #60]
	sub	w0,w0,#1
	str	w0,[sp, #60]
	ldr	x0,[sp, #8]
	ldr	w0,[x0, #8]
	sub	w0,w0,#1
	cmp	w0,#0
	b.ge	Lj205
	b	Lj206
Lj205:
	str	w0,[sp, #56]
	ldr	w0,[sp, #56]
	add	w0,w0,#1
	str	w0,[sp, #56]
	.align 2
Lj207:
	ldr	w0,[sp, #56]
	sub	w0,w0,#1
	str	w0,[sp, #56]
	ldr	x0,[sp, #8]
	ldr	w1,[x0, #8]
	ldr	w0,[sp, #60]
	mul	w1,w0,w1
	ldr	w0,[sp, #56]
	add	w0,w0,w1
	str	w0,[sp, #64]
	ldr	x0,[sp, #8]
	ldrsw	x0,[x0, #8]
	sub	x0,x0,#1
	ldrsw	x1,[sp, #56]
	cmp	x0,x1
	b.gt	Lj210
	b	Lj211
Lj210:
	ldr	x1,[sp, #32]
	ldrsw	x0,[sp, #64]
	add	x0,x0,#1
	ldrsw	x0,[x1, x0, lsl #2]
	add	x0,x0,#1
	str	x0,[sp, #272]
	ldr	x1,[sp, #32]
	ldrsw	x0,[sp, #64]
	ldrsw	x0,[x1, x0, lsl #2]
	str	x0,[sp, #280]
	ldr	x0,[sp, #280]
	ldr	x1,[sp, #272]
	cmp	x0,x1
	b.lt	Lj212
	b	Lj213
Lj212:
	ldr	x0,[sp, #280]
	b	Lj214
Lj213:
	ldr	x0,[sp, #272]
Lj214:
	ubfiz	x0,x0,#0,#32
	ldr	x2,[sp, #32]
	ldrsw	x1,[sp, #64]
	str	w0,[x2, x1, lsl #2]
Lj211:
	ldr	x0,[sp, #8]
	ldrsw	x0,[x0, #12]
	sub	x0,x0,#1
	ldrsw	x1,[sp, #60]
	cmp	x0,x1
	b.gt	Lj215
	b	Lj216
Lj215:
	ldr	x2,[sp, #32]
	ldr	x0,[sp, #8]
	ldrsw	x1,[x0, #8]
	ldrsw	x0,[sp, #64]
	add	x0,x0,x1
	ldrsw	x0,[x2, x0, lsl #2]
	add	x0,x0,#1
	str	x0,[sp, #272]
	ldr	x0,[sp, #32]
	ldrsw	x1,[sp, #64]
	ldrsw	x0,[x0, x1, lsl #2]
	str	x0,[sp, #280]
	ldr	x0,[sp, #280]
	ldr	x1,[sp, #272]
	cmp	x0,x1
	b.lt	Lj217
	b	Lj218
Lj217:
	ldr	x0,[sp, #280]
	b	Lj219
Lj218:
	ldr	x0,[sp, #272]
Lj219:
	ubfiz	x0,x0,#0,#32
	ldr	x1,[sp, #32]
	ldrsw	x2,[sp, #64]
	str	w0,[x1, x2, lsl #2]
Lj216:
	ldr	x0,[sp, #8]
	ldrsw	x0,[x0, #8]
	sub	x0,x0,#1
	ldrsw	x1,[sp, #56]
	cmp	x0,x1
	b.gt	Lj220
	b	Lj221
Lj220:
	ldr	x1,[sp, #40]
	ldrsw	x0,[sp, #64]
	add	x0,x0,#1
	ldrsw	x0,[x1, x0, lsl #2]
	add	x0,x0,#1
	str	x0,[sp, #272]
	ldr	x1,[sp, #40]
	ldrsw	x0,[sp, #64]
	ldrsw	x0,[x1, x0, lsl #2]
	str	x0,[sp, #280]
	ldr	x0,[sp, #280]
	ldr	x1,[sp, #272]
	cmp	x0,x1
	b.lt	Lj222
	b	Lj223
Lj222:
	ldr	x0,[sp, #280]
	b	Lj224
Lj223:
	ldr	x0,[sp, #272]
Lj224:
	ubfiz	x0,x0,#0,#32
	ldr	x2,[sp, #40]
	ldrsw	x1,[sp, #64]
	str	w0,[x2, x1, lsl #2]
Lj221:
	ldr	x0,[sp, #8]
	ldrsw	x0,[x0, #12]
	sub	x0,x0,#1
	ldrsw	x1,[sp, #60]
	cmp	x0,x1
	b.gt	Lj225
	b	Lj226
Lj225:
	ldr	x2,[sp, #40]
	ldr	x0,[sp, #8]
	ldrsw	x0,[x0, #8]
	ldrsw	x1,[sp, #64]
	add	x0,x1,x0
	ldrsw	x0,[x2, x0, lsl #2]
	add	x0,x0,#1
	str	x0,[sp, #272]
	ldr	x1,[sp, #40]
	ldrsw	x0,[sp, #64]
	ldrsw	x0,[x1, x0, lsl #2]
	str	x0,[sp, #280]
	ldr	x0,[sp, #280]
	ldr	x1,[sp, #272]
	cmp	x0,x1
	b.lt	Lj227
	b	Lj228
Lj227:
	ldr	x0,[sp, #280]
	b	Lj229
Lj228:
	ldr	x0,[sp, #272]
Lj229:
	ubfiz	x0,x0,#0,#32
	ldr	x2,[sp, #40]
	ldrsw	x1,[sp, #64]
	str	w0,[x2, x1, lsl #2]
Lj226:
	ldr	w0,[sp, #56]
	cmp	w0,#0
	b.le	Lj209
	b	Lj207
Lj209:
Lj206:
	ldr	w0,[sp, #60]
	cmp	w0,#0
	b.le	Lj204
	b	Lj202
Lj204:
Lj201:
	ldr	w0,[sp, #20]
	sub	w0,w0,#1
	cmp	w0,#0
	b.ge	Lj230
	b	Lj231
Lj230:
	movn	w1,#0
	str	w1,[sp, #24]
	.align 2
Lj232:
	ldr	w1,[sp, #24]
	add	w1,w1,#1
	str	w1,[sp, #24]
	ldr	x2,[sp, #48]
	ldrsw	x1,[sp, #24]
	ldrb	w1,[x2, x1]
	cmp	w1,#0
	b.ne	Lj235
	b	Lj236
Lj235:
	ldr	x1,[sp, #32]
	ldrsw	x2,[sp, #24]
	add	x1,x1,x2,lsl #2
	ldr	w2,[x1]
	ldr	w3,[sp, #16]
	cmp	w2,w3
	b.lt	Lj237
	b	Lj238
Lj237:
	ldr	w2,[x1]
	b	Lj239
Lj238:
	ldr	w2,[sp, #16]
Lj239:
	scvtf	s0,w2
	adrp	x1,_$FPSELECTION$_Ld2@GOTPAGE
	ldr	x1,[x1, _$FPSELECTION$_Ld2@GOTPAGEOFF]
	ldur	s1,[x1]
	fmul	s0,s1,s0
	ldr	w1,[sp, #16]
	scvtf	s1,w1
	fdiv	s0,s0,s1
	fcvt	d0,s0
	frintx	d0,d0
	fcvtzs	x1,d0
	ubfiz	x1,x1,#0,#32
	str	w1,[sp, #68]
	b	Lj240
Lj236:
	ldr	x2,[sp, #40]
	ldrsw	x1,[sp, #24]
	ldr	w1,[x2, x1, lsl #2]
	ldr	w2,[sp, #16]
	cmp	w1,w2
	b.le	Lj241
	b	Lj242
Lj241:
	ldr	x2,[sp, #40]
	ldrsw	x1,[sp, #24]
	ldr	w1,[x2, x1, lsl #2]
	scvtf	s0,w1
	adrp	x1,_$FPSELECTION$_Ld2@GOTPAGE
	ldr	x1,[x1, _$FPSELECTION$_Ld2@GOTPAGEOFF]
	ldur	s1,[x1]
	fmul	s1,s1,s0
	ldr	w1,[sp, #16]
	scvtf	s0,w1
	fdiv	s0,s1,s0
	fcvt	d0,s0
	frintx	d0,d0
	fcvtzs	x1,d0
	movz	x2,#255
	sub	x1,x2,x1
	ubfiz	x1,x1,#0,#32
	str	w1,[sp, #68]
	b	Lj243
Lj242:
	str	wzr,[sp, #68]
Lj243:
Lj240:
	ldr	w1,[sp, #68]
	cmp	w1,#0
	b.lt	Lj245
	b	Lj246
Lj245:
	movz	w1,#0
Lj246:
	cmp	w1,#255
	b.gt	Lj247
	b	Lj248
Lj247:
	movz	w1,#255
Lj248:
	uxtb	w3,w1
	ldr	x1,[sp, #8]
	ldr	x1,[x1, #16]
	ldrsw	x2,[sp, #24]
	strb	w3,[x1, x2]
	ldr	w1,[sp, #24]
	cmp	w1,w0
	b.ge	Lj234
	b	Lj232
Lj234:
Lj231:
Lj154:
	bl	fpc_popaddrstack
	adrp	x1,_RTTI_$FPSELECTION_$$_def00000035@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def00000035@GOTPAGEOFF]
	add	x0,sp,#32
	bl	fpc_finalize
	adrp	x1,_RTTI_$FPSELECTION_$$_def00000036@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def00000036@GOTPAGEOFF]
	add	x0,sp,#40
	bl	fpc_finalize
	adrp	x1,_RTTI_$FPSELECTION_$$_def00000037@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def00000037@GOTPAGEOFF]
	add	x0,sp,#48
	bl	fpc_finalize
	ldr	x0,[sp, #264]
	cmp	x0,#0
	b.eq	Lj153
	bl	fpc_reraise
Lj153:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTRECTANGLE$crc860ABC53
_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTRECTANGLE$crc860ABC53:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	stp	x19,x20,[sp, #-16]!
	sub	sp,sp,#288
	str	x0,[sp, #40]
	str	w1,[sp]
	str	w2,[sp, #8]
	str	w3,[sp, #16]
	str	w4,[sp, #24]
	str	w5,[sp, #32]
	ldr	w0,[sp, #32]
	cmp	w0,#3
	b.eq	Lj251
	b	Lj252
Lj251:
	ldr	x0,[sp, #40]
	ldr	w3,[x0, #12]
	ldr	x0,[sp, #40]
	ldr	w2,[x0, #8]
	movz	x1,#1
	adrp	x0,_VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGE
	ldr	x0,[x0, _VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGEOFF]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CREATE$LONGINT$LONGINT$$TSELECTIONMASK
	str	x0,[sp, #48]
	add	x2,sp,#80
	add	x1,sp,#104
	movz	w0,#1
	bl	fpc_pushexceptaddr
	bl	fpc_setjmp
	sxtw	x1,w0
	str	x1,[sp, #272]
	cmp	w0,#0
	b.ne	Lj254
	ldr	w4,[sp, #24]
	ldr	w3,[sp, #16]
	ldr	w2,[sp, #8]
	ldr	w1,[sp]
	ldr	x0,[sp, #48]
	movz	w5,#0
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTRECTANGLE$crc860ABC53
	ldr	x1,[sp, #48]
	ldr	x0,[sp, #40]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_INTERSECTWITH$TSELECTIONMASK
Lj254:
	bl	fpc_popaddrstack
	ldr	x0,[sp, #48]
	bl	_SYSTEM$_$TOBJECT_$__$$_FREE
	ldr	x0,[sp, #272]
	cmp	x0,#0
	b.eq	Lj253
	bl	fpc_reraise
Lj253:
	b	Lj249
Lj252:
	ldr	w1,[sp]
	ldr	w0,[sp, #16]
	cmp	w1,w0
	b.lt	Lj256
	b	Lj257
Lj256:
	ldr	w0,[sp]
	b	Lj258
Lj257:
	ldr	w0,[sp, #16]
Lj258:
	str	w0,[sp, #80]
	ldr	w0,[sp, #80]
	cmp	w0,#0
	b.lt	Lj259
	b	Lj260
Lj259:
	movz	w0,#0
	b	Lj261
Lj260:
	ldr	w0,[sp, #80]
Lj261:
	str	w0,[sp, #56]
	ldr	w0,[sp]
	ldr	w1,[sp, #16]
	cmp	w0,w1
	b.gt	Lj262
	b	Lj263
Lj262:
	ldr	w0,[sp]
	b	Lj264
Lj263:
	ldr	w0,[sp, #16]
Lj264:
	sxtw	x0,w0
	str	x0,[sp, #272]
	ldr	x0,[sp, #40]
	ldrsw	x0,[x0, #8]
	sub	x0,x0,#1
	str	x0,[sp, #80]
	ldr	x1,[sp, #80]
	ldr	x0,[sp, #272]
	cmp	x1,x0
	b.lt	Lj265
	b	Lj266
Lj265:
	ldr	x0,[sp, #80]
	b	Lj267
Lj266:
	ldr	x0,[sp, #272]
Lj267:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #60]
	ldr	w0,[sp, #8]
	ldr	w1,[sp, #24]
	cmp	w0,w1
	b.lt	Lj268
	b	Lj269
Lj268:
	ldr	w0,[sp, #8]
	b	Lj270
Lj269:
	ldr	w0,[sp, #24]
Lj270:
	str	w0,[sp, #80]
	ldr	w0,[sp, #80]
	cmp	w0,#0
	b.lt	Lj271
	b	Lj272
Lj271:
	movz	w0,#0
	b	Lj273
Lj272:
	ldr	w0,[sp, #80]
Lj273:
	str	w0,[sp, #64]
	ldr	w0,[sp, #8]
	ldr	w1,[sp, #24]
	cmp	w0,w1
	b.gt	Lj274
	b	Lj275
Lj274:
	ldr	w0,[sp, #8]
	b	Lj276
Lj275:
	ldr	w0,[sp, #24]
Lj276:
	sxtw	x0,w0
	str	x0,[sp, #272]
	ldr	x0,[sp, #40]
	ldrsw	x0,[x0, #12]
	sub	x0,x0,#1
	str	x0,[sp, #80]
	ldr	x1,[sp, #80]
	ldr	x0,[sp, #272]
	cmp	x1,x0
	b.lt	Lj277
	b	Lj278
Lj277:
	ldr	x0,[sp, #80]
	b	Lj279
Lj278:
	ldr	x0,[sp, #272]
Lj279:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #68]
	ldr	w0,[sp, #32]
	cmp	w0,#0
	b.eq	Lj280
	b	Lj281
Lj280:
	ldr	x0,[sp, #40]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CLEAR
Lj281:
	ldr	w20,[sp, #68]
	ldr	w0,[sp, #64]
	cmp	w0,w20
	b.le	Lj282
	b	Lj283
Lj282:
	ldr	w0,[sp, #64]
	sub	w0,w0,#1
	str	w0,[sp, #76]
	.align 2
Lj284:
	ldr	w0,[sp, #76]
	add	w0,w0,#1
	str	w0,[sp, #76]
	ldr	w19,[sp, #60]
	ldr	w0,[sp, #56]
	cmp	w0,w19
	b.le	Lj287
	b	Lj288
Lj287:
	ldr	w0,[sp, #56]
	sub	w0,w0,#1
	str	w0,[sp, #72]
	.align 2
Lj289:
	ldr	w0,[sp, #72]
	add	w0,w0,#1
	str	w0,[sp, #72]
	ldr	w1,[sp, #32]
	mov	w0,w1
	sub	w1,w1,#1
	cmp	w0,#1
	b.ls	Lj294
	mov	w0,w1
	sub	w1,w1,#1
	cmp	w0,#1
	b.eq	Lj295
	b	Lj293
Lj294:
	ldr	w2,[sp, #76]
	ldr	w1,[sp, #72]
	ldr	x0,[sp, #40]
	movz	w3,#1
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSELECTED$LONGINT$LONGINT$BOOLEAN
	b	Lj292
Lj295:
	ldr	w2,[sp, #76]
	ldr	w1,[sp, #72]
	ldr	x0,[sp, #40]
	movz	w3,#0
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSELECTED$LONGINT$LONGINT$BOOLEAN
	b	Lj292
Lj293:
Lj292:
	ldr	w0,[sp, #72]
	cmp	w0,w19
	b.ge	Lj291
	b	Lj289
Lj291:
Lj288:
	ldr	w0,[sp, #76]
	cmp	w0,w20
	b.ge	Lj286
	b	Lj284
Lj286:
Lj283:
Lj249:
	add	sp,sp,#288
	ldp	x19,x20,[sp], #16
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTELLIPSE$crc860ABC53
_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTELLIPSE$crc860ABC53:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	stp	x19,x20,[sp, #-16]!
	sub	sp,sp,#336
	str	x0,[sp, #40]
	str	w1,[sp]
	str	w2,[sp, #8]
	str	w3,[sp, #16]
	str	w4,[sp, #24]
	str	w5,[sp, #32]
	ldr	w0,[sp, #32]
	cmp	w0,#3
	b.eq	Lj298
	b	Lj299
Lj298:
	ldr	x0,[sp, #40]
	ldr	w3,[x0, #12]
	ldr	x0,[sp, #40]
	ldr	w2,[x0, #8]
	movz	x1,#1
	adrp	x0,_VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGE
	ldr	x0,[x0, _VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGEOFF]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CREATE$LONGINT$LONGINT$$TSELECTIONMASK
	str	x0,[sp, #48]
	add	x2,sp,#128
	add	x1,sp,#152
	movz	w0,#1
	bl	fpc_pushexceptaddr
	bl	fpc_setjmp
	sxtw	x1,w0
	str	x1,[sp, #320]
	cmp	w0,#0
	b.ne	Lj301
	ldr	w4,[sp, #24]
	ldr	w3,[sp, #16]
	ldr	w2,[sp, #8]
	ldr	w1,[sp]
	ldr	x0,[sp, #48]
	movz	w5,#0
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTELLIPSE$crc860ABC53
	ldr	x1,[sp, #48]
	ldr	x0,[sp, #40]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_INTERSECTWITH$TSELECTIONMASK
Lj301:
	bl	fpc_popaddrstack
	ldr	x0,[sp, #48]
	bl	_SYSTEM$_$TOBJECT_$__$$_FREE
	ldr	x0,[sp, #320]
	cmp	x0,#0
	b.eq	Lj300
	bl	fpc_reraise
Lj300:
	b	Lj296
Lj299:
	ldr	w0,[sp]
	ldr	w1,[sp, #16]
	cmp	w0,w1
	b.lt	Lj303
	b	Lj304
Lj303:
	ldr	w0,[sp]
	b	Lj305
Lj304:
	ldr	w0,[sp, #16]
Lj305:
	str	w0,[sp, #128]
	ldr	w0,[sp, #128]
	cmp	w0,#0
	b.lt	Lj306
	b	Lj307
Lj306:
	movz	w0,#0
	b	Lj308
Lj307:
	ldr	w0,[sp, #128]
Lj308:
	str	w0,[sp, #56]
	ldr	w0,[sp]
	ldr	w1,[sp, #16]
	cmp	w0,w1
	b.gt	Lj309
	b	Lj310
Lj309:
	ldr	w0,[sp]
	b	Lj311
Lj310:
	ldr	w0,[sp, #16]
Lj311:
	sxtw	x0,w0
	str	x0,[sp, #320]
	ldr	x0,[sp, #40]
	ldrsw	x0,[x0, #8]
	sub	x0,x0,#1
	str	x0,[sp, #128]
	ldr	x0,[sp, #128]
	ldr	x1,[sp, #320]
	cmp	x0,x1
	b.lt	Lj312
	b	Lj313
Lj312:
	ldr	x0,[sp, #128]
	b	Lj314
Lj313:
	ldr	x0,[sp, #320]
Lj314:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #60]
	ldr	w0,[sp, #8]
	ldr	w1,[sp, #24]
	cmp	w0,w1
	b.lt	Lj315
	b	Lj316
Lj315:
	ldr	w0,[sp, #8]
	b	Lj317
Lj316:
	ldr	w0,[sp, #24]
Lj317:
	str	w0,[sp, #128]
	ldr	w0,[sp, #128]
	cmp	w0,#0
	b.lt	Lj318
	b	Lj319
Lj318:
	movz	w0,#0
	b	Lj320
Lj319:
	ldr	w0,[sp, #128]
Lj320:
	str	w0,[sp, #64]
	ldr	w0,[sp, #8]
	ldr	w1,[sp, #24]
	cmp	w0,w1
	b.gt	Lj321
	b	Lj322
Lj321:
	ldr	w0,[sp, #8]
	b	Lj323
Lj322:
	ldr	w0,[sp, #24]
Lj323:
	sxtw	x0,w0
	str	x0,[sp, #320]
	ldr	x0,[sp, #40]
	ldrsw	x0,[x0, #12]
	sub	x0,x0,#1
	str	x0,[sp, #128]
	ldr	x1,[sp, #128]
	ldr	x0,[sp, #320]
	cmp	x1,x0
	b.lt	Lj324
	b	Lj325
Lj324:
	ldr	x0,[sp, #128]
	b	Lj326
Lj325:
	ldr	x0,[sp, #320]
Lj326:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #68]
	ldr	w0,[sp, #32]
	cmp	w0,#0
	b.eq	Lj327
	b	Lj328
Lj327:
	ldr	x0,[sp, #40]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CLEAR
Lj328:
	ldrsw	x1,[sp, #56]
	ldrsw	x0,[sp, #60]
	add	x0,x0,x1
	add	x0,x0,#1
	scvtf	s1,x0
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s0,[x0]
	fmul	s0,s1,s0
	fcvt	d0,s0
	str	d0,[sp, #72]
	ldrsw	x1,[sp, #64]
	ldrsw	x0,[sp, #68]
	add	x0,x0,x1
	add	x0,x0,#1
	scvtf	s0,x0
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s1,[x0]
	fmul	s0,s0,s1
	fcvt	d0,s0
	str	d0,[sp, #80]
	ldrsw	x0,[sp, #60]
	ldrsw	x1,[sp, #56]
	sub	x0,x0,x1
	add	x0,x0,#1
	scvtf	s0,x0
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s1,[x0]
	fmul	s0,s0,s1
	str	s0,[sp, #128]
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s0,[x0]
	ldr	s1,[sp, #128]
	fcmpe	s0,s1
	b.gt	Lj329
	b	Lj330
Lj329:
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s0,[x0]
	b	Lj331
Lj330:
	ldr	s0,[sp, #128]
Lj331:
	fcvt	d0,s0
	str	d0,[sp, #88]
	ldrsw	x0,[sp, #68]
	ldrsw	x1,[sp, #64]
	sub	x0,x0,x1
	add	x0,x0,#1
	scvtf	s1,x0
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s0,[x0]
	fmul	s0,s1,s0
	str	s0,[sp, #128]
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s0,[x0]
	ldr	s1,[sp, #128]
	fcmpe	s0,s1
	b.gt	Lj332
	b	Lj333
Lj332:
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s0,[x0]
	b	Lj334
Lj333:
	ldr	s0,[sp, #128]
Lj334:
	fcvt	d0,s0
	str	d0,[sp, #96]
	ldr	w20,[sp, #68]
	ldr	w0,[sp, #64]
	cmp	w0,w20
	b.le	Lj335
	b	Lj336
Lj335:
	ldr	w0,[sp, #64]
	sub	w0,w0,#1
	str	w0,[sp, #124]
	.align 2
Lj337:
	ldr	w0,[sp, #124]
	add	w0,w0,#1
	str	w0,[sp, #124]
	ldr	w19,[sp, #60]
	ldr	w0,[sp, #56]
	cmp	w0,w19
	b.le	Lj340
	b	Lj341
Lj340:
	ldr	w0,[sp, #56]
	sub	w0,w0,#1
	str	w0,[sp, #120]
	.align 2
Lj342:
	ldr	w0,[sp, #120]
	add	w0,w0,#1
	str	w0,[sp, #120]
	ldr	w0,[sp, #120]
	scvtf	s0,w0
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s1,[x0]
	fadd	s0,s0,s1
	fcvt	d0,s0
	ldr	d1,[sp, #72]
	fsub	d0,d0,d1
	ldr	d1,[sp, #88]
	fdiv	d0,d0,d1
	str	d0,[sp, #104]
	ldr	w0,[sp, #124]
	scvtf	s0,w0
	adrp	x0,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s1,[x0]
	fadd	s0,s0,s1
	fcvt	d0,s0
	ldr	d1,[sp, #80]
	fsub	d0,d0,d1
	ldr	d1,[sp, #96]
	fdiv	d0,d0,d1
	str	d0,[sp, #112]
	ldr	d0,[sp, #104]
	ldr	d1,[sp, #104]
	fmul	d2,d0,d1
	ldr	d1,[sp, #112]
	ldr	d0,[sp, #112]
	fmul	d0,d1,d0
	fadd	d0,d2,d0
	adrp	x0,_$FPSELECTION$_Ld3@GOTPAGE
	ldr	x0,[x0, _$FPSELECTION$_Ld3@GOTPAGEOFF]
	ldur	d1,[x0]
	fcmpe	d0,d1
	b.ls	Lj345
	b	Lj346
Lj345:
	ldr	w1,[sp, #32]
	mov	w0,w1
	sub	w1,w1,#1
	cmp	w0,#1
	b.ls	Lj349
	mov	w0,w1
	sub	w1,w1,#1
	cmp	w0,#1
	b.eq	Lj350
	b	Lj348
Lj349:
	ldr	w2,[sp, #124]
	ldr	w1,[sp, #120]
	ldr	x0,[sp, #40]
	movz	w3,#1
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSELECTED$LONGINT$LONGINT$BOOLEAN
	b	Lj347
Lj350:
	ldr	w2,[sp, #124]
	ldr	w1,[sp, #120]
	ldr	x0,[sp, #40]
	movz	w3,#0
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSELECTED$LONGINT$LONGINT$BOOLEAN
	b	Lj347
Lj348:
Lj347:
Lj346:
	ldr	w0,[sp, #120]
	cmp	w0,w19
	b.ge	Lj344
	b	Lj342
Lj344:
Lj341:
	ldr	w0,[sp, #124]
	cmp	w0,w20
	b.ge	Lj339
	b	Lj337
Lj339:
Lj336:
Lj296:
	add	sp,sp,#336
	ldp	x19,x20,[sp], #16
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTPOLYGON$array_of_TPOINT$TSELECTIONCOMBINEMODE
_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTPOLYGON$array_of_TPOINT$TSELECTIONCOMBINEMODE:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	stp	x19,x20,[sp, #-16]!
	sub	sp,sp,#272
	str	x0,[sp, #24]
	str	x1,[sp]
	str	x2,[sp, #16]
	str	w3,[sp, #8]
	ldr	w0,[sp, #8]
	cmp	w0,#3
	b.eq	Lj357
	b	Lj358
Lj357:
	ldr	x0,[sp, #24]
	ldr	w3,[x0, #12]
	ldr	x0,[sp, #24]
	ldr	w2,[x0, #8]
	movz	x1,#1
	adrp	x0,_VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGE
	ldr	x0,[x0, _VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGEOFF]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CREATE$LONGINT$LONGINT$$TSELECTIONMASK
	str	x0,[sp, #32]
	add	x2,sp,#72
	add	x1,sp,#96
	movz	w0,#1
	bl	fpc_pushexceptaddr
	bl	fpc_setjmp
	sxtw	x1,w0
	str	x1,[sp, #264]
	cmp	w0,#0
	b.ne	Lj360
	ldr	x1,[sp]
	ldr	x2,[sp, #16]
	ldr	x0,[sp, #32]
	movz	w3,#0
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SELECTPOLYGON$array_of_TPOINT$TSELECTIONCOMBINEMODE
	ldr	x1,[sp, #32]
	ldr	x0,[sp, #24]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_INTERSECTWITH$TSELECTIONMASK
Lj360:
	bl	fpc_popaddrstack
	ldr	x0,[sp, #32]
	bl	_SYSTEM$_$TOBJECT_$__$$_FREE
	ldr	x0,[sp, #264]
	cmp	x0,#0
	b.eq	Lj359
	bl	fpc_reraise
Lj359:
	b	Lj351
Lj358:
	ldr	w0,[sp, #8]
	cmp	w0,#0
	b.eq	Lj362
	b	Lj363
Lj362:
	ldr	x0,[sp, #24]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CLEAR
Lj363:
	ldr	x0,[sp, #16]
	add	x0,x0,#1
	cmp	x0,#0
	b.eq	Lj364
	b	Lj365
Lj364:
	b	Lj351
Lj365:
	ldr	x0,[sp]
	ldr	w0,[x0]
	str	w0,[sp, #40]
	ldr	x0,[sp]
	ldr	w0,[x0]
	str	w0,[sp, #44]
	ldr	x0,[sp]
	ldr	w0,[x0, #4]
	str	w0,[sp, #48]
	ldr	x0,[sp]
	ldr	w0,[x0, #4]
	str	w0,[sp, #52]
	ldr	w2,[sp, #16]
	cmp	w2,#1
	b.ge	Lj366
	b	Lj367
Lj366:
	str	wzr,[sp, #56]
	.align 2
Lj368:
	ldr	w0,[sp, #56]
	add	w0,w0,#1
	str	w0,[sp, #56]
	ldr	x1,[sp]
	ldrsw	x0,[sp, #56]
	add	x0,x1,x0,lsl #3
	ldur	w0,[x0]
	str	w0,[sp, #72]
	ldr	w0,[sp, #40]
	ldr	w1,[sp, #72]
	cmp	w0,w1
	b.lt	Lj371
	b	Lj372
Lj371:
	ldr	w0,[sp, #40]
	b	Lj373
Lj372:
	ldr	w0,[sp, #72]
Lj373:
	str	w0,[sp, #40]
	ldr	x0,[sp]
	ldrsw	x1,[sp, #56]
	add	x0,x0,x1,lsl #3
	ldur	w0,[x0]
	str	w0,[sp, #72]
	ldr	w0,[sp, #44]
	ldr	w1,[sp, #72]
	cmp	w0,w1
	b.gt	Lj374
	b	Lj375
Lj374:
	ldr	w0,[sp, #44]
	b	Lj376
Lj375:
	ldr	w0,[sp, #72]
Lj376:
	str	w0,[sp, #44]
	ldr	x1,[sp]
	ldrsw	x0,[sp, #56]
	add	x0,x1,x0,lsl #3
	ldur	w0,[x0, #4]
	str	w0,[sp, #72]
	ldr	w1,[sp, #48]
	ldr	w0,[sp, #72]
	cmp	w1,w0
	b.lt	Lj377
	b	Lj378
Lj377:
	ldr	w0,[sp, #48]
	b	Lj379
Lj378:
	ldr	w0,[sp, #72]
Lj379:
	str	w0,[sp, #48]
	ldr	x0,[sp]
	ldrsw	x1,[sp, #56]
	add	x0,x0,x1,lsl #3
	ldur	w0,[x0, #4]
	str	w0,[sp, #72]
	ldr	w1,[sp, #52]
	ldr	w0,[sp, #72]
	cmp	w1,w0
	b.gt	Lj380
	b	Lj381
Lj380:
	ldr	w0,[sp, #52]
	b	Lj382
Lj381:
	ldr	w0,[sp, #72]
Lj382:
	str	w0,[sp, #52]
	ldr	w0,[sp, #56]
	cmp	w0,w2
	b.ge	Lj370
	b	Lj368
Lj370:
Lj367:
	ldr	w0,[sp, #40]
	cmp	w0,#0
	b.lt	Lj383
	b	Lj384
Lj383:
	movz	w0,#0
	b	Lj385
Lj384:
	ldr	w0,[sp, #40]
Lj385:
	str	w0,[sp, #40]
	ldrsw	x0,[sp, #44]
	str	x0,[sp, #72]
	ldr	x0,[sp, #24]
	ldrsw	x0,[x0, #8]
	sub	x0,x0,#1
	str	x0,[sp, #80]
	ldr	x1,[sp, #80]
	ldr	x0,[sp, #72]
	cmp	x1,x0
	b.lt	Lj386
	b	Lj387
Lj386:
	ldr	x0,[sp, #80]
	b	Lj388
Lj387:
	ldr	x0,[sp, #72]
Lj388:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #44]
	ldr	w0,[sp, #48]
	cmp	w0,#0
	b.lt	Lj389
	b	Lj390
Lj389:
	movz	w0,#0
	b	Lj391
Lj390:
	ldr	w0,[sp, #48]
Lj391:
	str	w0,[sp, #48]
	ldrsw	x0,[sp, #52]
	str	x0,[sp, #72]
	ldr	x0,[sp, #24]
	ldrsw	x0,[x0, #12]
	sub	x0,x0,#1
	str	x0,[sp, #80]
	ldr	x1,[sp, #80]
	ldr	x0,[sp, #72]
	cmp	x1,x0
	b.lt	Lj392
	b	Lj393
Lj392:
	ldr	x0,[sp, #80]
	b	Lj394
Lj393:
	ldr	x0,[sp, #72]
Lj394:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #52]
	ldr	w0,[sp, #40]
	ldr	w1,[sp, #44]
	cmp	w0,w1
	b.gt	Lj395
	b	Lj396
Lj396:
	ldr	w1,[sp, #48]
	ldr	w0,[sp, #52]
	cmp	w1,w0
	b.gt	Lj395
	b	Lj397
Lj395:
	b	Lj351
Lj397:
	ldr	x0,[sp, #16]
	add	x0,x0,#1
	cmp	x0,#3
	b.ge	Lj398
	b	Lj399
Lj398:
	ldr	w20,[sp, #52]
	ldr	w0,[sp, #48]
	cmp	w0,w20
	b.le	Lj400
	b	Lj401
Lj400:
	ldr	w0,[sp, #48]
	sub	w0,w0,#1
	str	w0,[sp, #64]
	.align 2
Lj402:
	ldr	w0,[sp, #64]
	add	w0,w0,#1
	str	w0,[sp, #64]
	ldr	w19,[sp, #44]
	ldr	w0,[sp, #40]
	cmp	w0,w19
	b.le	Lj405
	b	Lj406
Lj405:
	ldr	w0,[sp, #40]
	sub	w0,w0,#1
	str	w0,[sp, #60]
	.align 2
Lj407:
	ldr	w0,[sp, #60]
	add	w0,w0,#1
	str	w0,[sp, #60]
	ldr	x0,[sp]
	ldr	w1,[sp, #64]
	scvtf	s1,w1
	adrp	x1,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x1,[x1, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s0,[x1]
	fadd	s0,s1,s0
	fcvt	d1,s0
	ldr	w1,[sp, #60]
	scvtf	s2,w1
	adrp	x1,_$FPSELECTION$_Ld1@GOTPAGE
	ldr	x1,[x1, _$FPSELECTION$_Ld1@GOTPAGEOFF]
	ldur	s0,[x1]
	fadd	s0,s2,s0
	fcvt	d0,s0
	ldr	x1,[sp, #16]
	bl	_FPSELECTION_$$_POINTINSIDEPOLYGON$array_of_TPOINT$DOUBLE$DOUBLE$$BOOLEAN
	cmp	w0,#0
	b.ne	Lj410
	b	Lj411
Lj410:
	ldr	w2,[sp, #64]
	ldr	w1,[sp, #60]
	mov	x0,x29
	bl	_FPSELECTION$_$TSELECTIONMASK_$_SELECTPOLYGON$array_of_TPOINT$TSELECTIONCOMBINEMODE_$$_APPLYSELECTIONAT$crc42AA5AF5
Lj411:
	ldr	w0,[sp, #60]
	cmp	w0,w19
	b.ge	Lj409
	b	Lj407
Lj409:
Lj406:
	ldr	w0,[sp, #64]
	cmp	w0,w20
	b.ge	Lj404
	b	Lj402
Lj404:
Lj401:
Lj399:
	ldr	w19,[sp, #16]
	cmp	w19,#0
	b.ge	Lj412
	b	Lj413
Lj412:
	movn	w0,#0
	str	w0,[sp, #56]
	.align 2
Lj414:
	ldr	w0,[sp, #56]
	add	w0,w0,#1
	str	w0,[sp, #56]
	ldr	x4,[sp]
	ldrsw	x0,[sp, #56]
	add	x0,x0,#1
	ldr	x1,[sp, #16]
	add	x1,x1,#1
	sdiv	x3,x0,x1
	cmp	x1,#0
	b.ne	Lj417
	bl	FPC_DIVBYZERO
Lj417:
	msub	x3,x3,x1,x0
	add	x0,x4,x3,lsl #3
	ldur	w2,[x0]
	add	x0,x4,x3,lsl #3
	ldur	w0,[x0, #4]
	bfi	x2,x0,#32,#32
	ldr	x3,[sp]
	ldrsw	x4,[sp, #56]
	add	x0,x3,x4,lsl #3
	ldur	w1,[x0]
	add	x0,x3,x4,lsl #3
	ldur	w0,[x0, #4]
	bfi	x1,x0,#32,#32
	mov	x0,x29
	bl	_FPSELECTION$_$TSELECTIONMASK_$_SELECTPOLYGON$array_of_TPOINT$TSELECTIONCOMBINEMODE_$$_RASTERIZEEDGE$crcDBD7025A
	ldr	w0,[sp, #56]
	cmp	w0,w19
	b.ge	Lj416
	b	Lj414
Lj416:
Lj413:
Lj351:
	add	sp,sp,#272
	ldp	x19,x20,[sp], #16
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
_FPSELECTION$_$TSELECTIONMASK_$_SELECTPOLYGON$array_of_TPOINT$TSELECTIONCOMBINEMODE_$$_RASTERIZEEDGE$crcDBD7025A:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#64
	str	x0,[sp, #16]
	str	x1,[sp]
	str	x2,[sp, #8]
	ldr	w0,[sp]
	str	w0,[sp, #24]
	ldr	w0,[sp, #4]
	str	w0,[sp, #28]
	ldrsw	x0,[sp, #8]
	ldrsw	x1,[sp]
	sub	x0,x0,x1
	negs	x1,x0
	csel	x1,x1,x0,ge
	ubfiz	x0,x1,#0,#32
	str	w0,[sp, #32]
	ldrsw	x0,[sp, #12]
	ldrsw	x1,[sp, #4]
	sub	x0,x0,x1
	negs	x1,x0
	csel	x1,x1,x0,ge
	ubfiz	x0,x1,#0,#32
	str	w0,[sp, #36]
	ldr	w0,[sp]
	ldr	w1,[sp, #8]
	cmp	w0,w1
	b.lt	Lj418
	b	Lj419
Lj418:
	movz	w0,#1
	str	w0,[sp, #40]
	b	Lj420
Lj419:
	movn	w0,#0
	str	w0,[sp, #40]
Lj420:
	ldr	w0,[sp, #4]
	ldr	w1,[sp, #12]
	cmp	w0,w1
	b.lt	Lj421
	b	Lj422
Lj421:
	movz	w0,#1
	str	w0,[sp, #44]
	b	Lj423
Lj422:
	movn	w0,#0
	str	w0,[sp, #44]
Lj423:
	ldr	w0,[sp, #32]
	ldr	w1,[sp, #36]
	sub	w0,w0,w1
	str	w0,[sp, #48]
	b	Lj425
	.align 2
Lj424:
	ldr	w2,[sp, #28]
	ldr	w1,[sp, #24]
	ldr	x0,[sp, #16]
	bl	_FPSELECTION$_$TSELECTIONMASK_$_SELECTPOLYGON$array_of_TPOINT$TSELECTIONCOMBINEMODE_$$_APPLYSELECTIONAT$crc42AA5AF5
	ldr	w1,[sp, #8]
	ldr	w0,[sp, #24]
	cmp	w1,w0
	b.eq	Lj427
	b	Lj428
Lj427:
	ldr	w0,[sp, #12]
	ldr	w1,[sp, #28]
	cmp	w0,w1
	b.eq	Lj429
	b	Lj428
Lj429:
	b	Lj426
Lj428:
	ldr	w0,[sp, #48]
	lsl	w0,w0,#1
	str	w0,[sp, #52]
	ldrsw	x0,[sp, #36]
	neg	x0,x0
	ldrsw	x1,[sp, #52]
	cmp	x0,x1
	b.lt	Lj430
	b	Lj431
Lj430:
	ldr	w0,[sp, #48]
	ldr	w1,[sp, #36]
	sub	w0,w0,w1
	str	w0,[sp, #48]
	ldr	w0,[sp, #24]
	ldr	w1,[sp, #40]
	add	w0,w1,w0
	str	w0,[sp, #24]
Lj431:
	ldr	w0,[sp, #52]
	ldr	w1,[sp, #32]
	cmp	w0,w1
	b.lt	Lj432
	b	Lj433
Lj432:
	ldr	w0,[sp, #48]
	ldr	w1,[sp, #32]
	add	w0,w1,w0
	str	w0,[sp, #48]
	ldr	w0,[sp, #28]
	ldr	w1,[sp, #44]
	add	w0,w1,w0
	str	w0,[sp, #28]
Lj433:
Lj425:
	b	Lj424
Lj426:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
_FPSELECTION$_$TSELECTIONMASK_$_SELECTPOLYGON$array_of_TPOINT$TSELECTIONCOMBINEMODE_$$_APPLYSELECTIONAT$crc42AA5AF5:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#32
	str	x0,[sp, #16]
	str	w1,[sp]
	str	w2,[sp, #8]
	ldr	x0,[sp, #16]
	sub	x1,x0,#1,lsl #12
	add	x1,x1,#3832
	ldr	w0,[sp]
	cmp	w0,#0
	b.ge	Lj434
	b	Lj435
Lj434:
	ldr	w0,[sp, #8]
	cmp	w0,#0
	b.ge	Lj436
	b	Lj435
Lj436:
	ldr	x0,[x1]
	ldr	w2,[sp]
	ldr	w0,[x0, #8]
	cmp	w2,w0
	b.lt	Lj437
	b	Lj435
Lj437:
	ldr	x0,[x1]
	ldr	w2,[sp, #8]
	ldr	w0,[x0, #12]
	cmp	w2,w0
	b.lt	Lj438
	b	Lj435
Lj438:
	movz	w0,#1
	b	Lj439
Lj435:
	movz	w0,#0
Lj439:
	cmp	w0,#0
	b.eq	Lj440
	b	Lj441
Lj440:
	b	Lj353
Lj441:
	ldr	x0,[sp, #16]
	sub	x0,x0,#1,lsl #12
	ldr	w1,[x0, #3816]
	mov	w0,w1
	sub	w1,w1,#1
	cmp	w0,#1
	b.ls	Lj444
	mov	w0,w1
	sub	w1,w1,#1
	cmp	w0,#1
	b.eq	Lj445
	b	Lj443
Lj444:
	ldr	x0,[sp, #16]
	sub	x0,x0,#1,lsl #12
	ldr	x0,[x0, #3832]
	ldr	w2,[sp, #8]
	ldr	w1,[sp]
	movz	w3,#1
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSELECTED$LONGINT$LONGINT$BOOLEAN
	b	Lj442
Lj445:
	ldr	x0,[sp, #16]
	sub	x0,x0,#1,lsl #12
	ldr	x0,[x0, #3832]
	ldr	w2,[sp, #8]
	ldr	w1,[sp]
	movz	w3,#0
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETSELECTED$LONGINT$LONGINT$BOOLEAN
	b	Lj442
Lj443:
Lj442:
Lj353:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_MOVEBY$LONGINT$LONGINT
_FPSELECTION$_$TSELECTIONMASK_$__$$_MOVEBY$LONGINT$LONGINT:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	stp	x19,x20,[sp, #-16]!
	sub	sp,sp,#256
	str	x0,[sp, #16]
	str	w1,[sp]
	str	w2,[sp, #8]
	str	xzr,[sp, #24]
	add	x2,sp,#48
	add	x1,sp,#72
	movz	w0,#1
	bl	fpc_pushexceptaddr
	bl	fpc_setjmp
	sxtw	x1,w0
	str	x1,[sp, #240]
	cmp	w0,#0
	b.ne	Lj449
	str	xzr,[sp, #248]
	adrp	x1,_RTTI_$FPSELECTION_$$_def0000003C@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def0000003C@GOTPAGEOFF]
	add	x3,sp,#248
	add	x0,sp,#24
	movz	x2,#1
	bl	fpc_dynarray_setlength
	ldr	x0,[sp, #16]
	ldr	x0,[x0, #16]
	cmp	x0,#0
	b.eq	Lj450
	ldur	x0,[x0, #-8]
	add	x0,x0,#1
Lj450:
	str	x0,[sp, #248]
	adrp	x1,_RTTI_$FPSELECTION_$$_def0000003C@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def0000003C@GOTPAGEOFF]
	add	x3,sp,#248
	add	x0,sp,#24
	movz	x2,#1
	bl	fpc_dynarray_setlength
	ldr	x0,[sp, #24]
	cmp	x0,#0
	b.eq	Lj451
	ldur	x0,[x0, #-8]
	add	x0,x0,#1
Lj451:
	cmp	x0,#0
	b.gt	Lj452
	b	Lj453
Lj452:
	ldr	x1,[sp, #24]
	cmp	x1,#0
	b.eq	Lj454
	ldur	x1,[x1, #-8]
	add	x1,x1,#1
Lj454:
	ldr	x0,[sp, #24]
	movz	w2,#0
	bl	_SYSTEM_$$_FILLCHAR$formal$INT64$BYTE
Lj453:
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #12]
	sub	w19,w0,#1
	cmp	w19,#0
	b.ge	Lj455
	b	Lj456
Lj455:
	movn	w0,#0
	str	w0,[sp, #36]
	.align 2
Lj457:
	ldr	w0,[sp, #36]
	add	w0,w0,#1
	str	w0,[sp, #36]
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #8]
	sub	w20,w0,#1
	cmp	w20,#0
	b.ge	Lj460
	b	Lj461
Lj460:
	movn	w0,#0
	str	w0,[sp, #32]
	.align 2
Lj462:
	ldr	w0,[sp, #32]
	add	w0,w0,#1
	str	w0,[sp, #32]
	ldr	w0,[sp, #32]
	ldr	w1,[sp]
	sub	w0,w0,w1
	str	w0,[sp, #40]
	ldr	w0,[sp, #36]
	ldr	w1,[sp, #8]
	sub	w0,w0,w1
	str	w0,[sp, #44]
	ldr	w0,[sp, #40]
	cmp	w0,#0
	b.ge	Lj465
	b	Lj466
Lj465:
	ldr	w0,[sp, #44]
	cmp	w0,#0
	b.ge	Lj467
	b	Lj466
Lj467:
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #8]
	ldr	w1,[sp, #40]
	cmp	w0,w1
	b.gt	Lj468
	b	Lj466
Lj468:
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #12]
	ldr	w1,[sp, #44]
	cmp	w0,w1
	b.gt	Lj469
	b	Lj466
Lj469:
	movz	w0,#1
	b	Lj470
Lj466:
	movz	w0,#0
Lj470:
	cmp	w0,#0
	b.ne	Lj471
	b	Lj472
Lj471:
	ldr	w2,[sp, #44]
	ldr	w1,[sp, #40]
	ldr	x0,[sp, #16]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_COVERAGE$LONGINT$LONGINT$$BYTE
	ldr	x3,[sp, #24]
	ldr	x1,[sp, #16]
	ldr	w1,[x1, #8]
	ldr	w2,[sp, #36]
	mul	w1,w2,w1
	ldr	w2,[sp, #32]
	add	w1,w2,w1
	sxtw	x1,w1
	strb	w0,[x3, x1]
Lj472:
	ldr	w0,[sp, #32]
	cmp	w0,w20
	b.ge	Lj464
	b	Lj462
Lj464:
Lj461:
	ldr	w0,[sp, #36]
	cmp	w0,w19
	b.ge	Lj459
	b	Lj457
Lj459:
Lj456:
	ldr	x0,[sp, #16]
	ldr	x0,[x0, #16]
	cmp	x0,#0
	b.eq	Lj473
	ldur	x0,[x0, #-8]
	add	x0,x0,#1
Lj473:
	cmp	x0,#0
	b.gt	Lj474
	b	Lj475
Lj474:
	ldr	x0,[sp, #16]
	ldr	x2,[x0, #16]
	cmp	x2,#0
	b.eq	Lj476
	ldur	x2,[x2, #-8]
	add	x2,x2,#1
Lj476:
	ldr	x0,[sp, #16]
	ldr	x1,[x0, #16]
	ldr	x0,[sp, #24]
	bl	_SYSTEM_$$_MOVE$formal$formal$INT64
Lj475:
Lj449:
	bl	fpc_popaddrstack
	adrp	x1,_RTTI_$FPSELECTION_$$_def0000003C@GOTPAGE
	ldr	x1,[x1, _RTTI_$FPSELECTION_$$_def0000003C@GOTPAGEOFF]
	add	x0,sp,#24
	bl	fpc_finalize
	ldr	x0,[sp, #240]
	cmp	x0,#0
	b.eq	Lj448
	bl	fpc_reraise
Lj448:
	add	sp,sp,#256
	ldp	x19,x20,[sp], #16
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_FLIPHORIZONTAL
_FPSELECTION$_$TSELECTIONMASK_$__$$_FLIPHORIZONTAL:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#48
	str	x0,[sp]
	ldr	x0,[sp]
	ldrsw	x0,[x0, #8]
	movz	x1,#2
	sdiv	x0,x0,x1
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #16]
	ldr	x0,[sp]
	ldr	w0,[x0, #12]
	sub	w0,w0,#1
	cmp	w0,#0
	b.ge	Lj479
	b	Lj480
Lj479:
	movn	w1,#0
	str	w1,[sp, #12]
	.align 2
Lj481:
	ldr	w1,[sp, #12]
	add	w1,w1,#1
	str	w1,[sp, #12]
	ldr	w1,[sp, #16]
	sub	w1,w1,#1
	cmp	w1,#0
	b.ge	Lj484
	b	Lj485
Lj484:
	movn	w2,#0
	str	w2,[sp, #8]
	.align 2
Lj486:
	ldr	w2,[sp, #8]
	add	w2,w2,#1
	str	w2,[sp, #8]
	ldr	x2,[sp]
	ldr	w2,[x2, #8]
	ldr	w3,[sp, #12]
	mul	w3,w3,w2
	ldr	w2,[sp, #8]
	add	w2,w2,w3
	str	w2,[sp, #20]
	ldr	x2,[sp]
	ldr	w2,[x2, #8]
	sub	w2,w2,#1
	ldr	w3,[sp, #8]
	sub	w2,w2,w3
	str	w2,[sp, #32]
	ldr	x2,[sp]
	ldr	w3,[x2, #8]
	ldr	w2,[sp, #12]
	mul	w2,w2,w3
	ldr	w3,[sp, #32]
	add	w2,w3,w2
	str	w2,[sp, #24]
	ldr	x2,[sp]
	ldr	x3,[x2, #16]
	ldrsw	x2,[sp, #20]
	ldrb	w2,[x3, x2]
	strb	w2,[sp, #28]
	ldr	x2,[sp]
	ldr	x4,[x2, #16]
	ldrsw	x5,[sp, #20]
	ldr	x2,[sp]
	ldr	x3,[x2, #16]
	ldrsw	x2,[sp, #24]
	ldrb	w2,[x3, x2]
	strb	w2,[x4, x5]
	ldr	x2,[sp]
	ldr	x4,[x2, #16]
	ldrsw	x3,[sp, #24]
	ldrb	w2,[sp, #28]
	strb	w2,[x4, x3]
	ldr	w2,[sp, #8]
	cmp	w2,w1
	b.ge	Lj488
	b	Lj486
Lj488:
Lj485:
	ldr	w1,[sp, #12]
	cmp	w1,w0
	b.ge	Lj483
	b	Lj481
Lj483:
Lj480:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_FLIPVERTICAL
_FPSELECTION$_$TSELECTIONMASK_$__$$_FLIPVERTICAL:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	sub	sp,sp,#48
	str	x0,[sp]
	ldr	x0,[sp]
	ldrsw	x0,[x0, #12]
	movz	x1,#2
	sdiv	x0,x0,x1
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #16]
	ldr	w0,[sp, #16]
	sub	w0,w0,#1
	cmp	w0,#0
	b.ge	Lj491
	b	Lj492
Lj491:
	movn	w1,#0
	str	w1,[sp, #12]
	.align 2
Lj493:
	ldr	w1,[sp, #12]
	add	w1,w1,#1
	str	w1,[sp, #12]
	ldr	x1,[sp]
	ldr	w1,[x1, #8]
	sub	w1,w1,#1
	cmp	w1,#0
	b.ge	Lj496
	b	Lj497
Lj496:
	movn	w2,#0
	str	w2,[sp, #8]
	.align 2
Lj498:
	ldr	w2,[sp, #8]
	add	w2,w2,#1
	str	w2,[sp, #8]
	ldr	x2,[sp]
	ldr	w2,[x2, #8]
	ldr	w3,[sp, #12]
	mul	w3,w3,w2
	ldr	w2,[sp, #8]
	add	w2,w2,w3
	str	w2,[sp, #20]
	ldr	x2,[sp]
	ldr	w2,[x2, #12]
	sub	w2,w2,#1
	ldr	w3,[sp, #12]
	sub	w2,w2,w3
	str	w2,[sp, #32]
	ldr	x2,[sp]
	ldr	w3,[x2, #8]
	ldr	w2,[sp, #32]
	mul	w2,w2,w3
	ldr	w3,[sp, #8]
	add	w2,w3,w2
	str	w2,[sp, #24]
	ldr	x2,[sp]
	ldr	x3,[x2, #16]
	ldrsw	x2,[sp, #20]
	ldrb	w2,[x3, x2]
	strb	w2,[sp, #28]
	ldr	x2,[sp]
	ldr	x4,[x2, #16]
	ldrsw	x5,[sp, #20]
	ldr	x2,[sp]
	ldr	x3,[x2, #16]
	ldrsw	x2,[sp, #24]
	ldrb	w2,[x3, x2]
	strb	w2,[x4, x5]
	ldr	x2,[sp]
	ldr	x4,[x2, #16]
	ldrsw	x3,[sp, #24]
	ldrb	w2,[sp, #28]
	strb	w2,[x4, x3]
	ldr	w2,[sp, #8]
	cmp	w2,w1
	b.ge	Lj500
	b	Lj498
Lj500:
Lj497:
	ldr	w1,[sp, #12]
	cmp	w1,w0
	b.ge	Lj495
	b	Lj493
Lj495:
Lj492:
	mov	sp,x29
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_ROTATE90CLOCKWISE
_FPSELECTION$_$TSELECTIONMASK_$__$$_ROTATE90CLOCKWISE:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	stp	x19,x20,[sp, #-16]!
	sub	sp,sp,#224
	str	x0,[sp]
	ldr	x0,[sp]
	ldr	w3,[x0, #8]
	ldr	x0,[sp]
	ldr	w2,[x0, #12]
	movz	x1,#1
	adrp	x0,_VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGE
	ldr	x0,[x0, _VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGEOFF]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CREATE$LONGINT$LONGINT$$TSELECTIONMASK
	str	x0,[sp, #8]
	add	x2,sp,#24
	add	x1,sp,#48
	movz	w0,#1
	bl	fpc_pushexceptaddr
	bl	fpc_setjmp
	sxtw	x1,w0
	str	x1,[sp, #216]
	cmp	w0,#0
	b.ne	Lj504
	ldr	x0,[sp]
	ldr	w0,[x0, #12]
	sub	w19,w0,#1
	cmp	w19,#0
	b.ge	Lj506
	b	Lj507
Lj506:
	movn	w0,#0
	str	w0,[sp, #20]
	.align 2
Lj508:
	ldr	w0,[sp, #20]
	add	w0,w0,#1
	str	w0,[sp, #20]
	ldr	x0,[sp]
	ldr	w0,[x0, #8]
	sub	w20,w0,#1
	cmp	w20,#0
	b.ge	Lj511
	b	Lj512
Lj511:
	movn	w0,#0
	str	w0,[sp, #16]
	.align 2
Lj513:
	ldr	w0,[sp, #16]
	add	w0,w0,#1
	str	w0,[sp, #16]
	ldr	w2,[sp, #20]
	ldr	w1,[sp, #16]
	ldr	x0,[sp]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_COVERAGE$LONGINT$LONGINT$$BYTE
	mov	w3,w0
	ldr	x0,[sp]
	ldr	w0,[x0, #12]
	sub	w0,w0,#1
	ldr	w1,[sp, #20]
	sub	w1,w0,w1
	ldr	w2,[sp, #16]
	ldr	x0,[sp, #8]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETCOVERAGE$LONGINT$LONGINT$BYTE
	ldr	w0,[sp, #16]
	cmp	w0,w20
	b.ge	Lj515
	b	Lj513
Lj515:
Lj512:
	ldr	w0,[sp, #20]
	cmp	w0,w19
	b.ge	Lj510
	b	Lj508
Lj510:
Lj507:
	ldr	x1,[sp, #8]
	ldr	x0,[sp]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_ASSIGN$TSELECTIONMASK
Lj504:
	bl	fpc_popaddrstack
	ldr	x0,[sp, #8]
	bl	_SYSTEM$_$TOBJECT_$__$$_FREE
	ldr	x0,[sp, #216]
	cmp	x0,#0
	b.eq	Lj503
	bl	fpc_reraise
Lj503:
	add	sp,sp,#224
	ldp	x19,x20,[sp], #16
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_ROTATE90COUNTERCLOCKWISE
_FPSELECTION$_$TSELECTIONMASK_$__$$_ROTATE90COUNTERCLOCKWISE:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	stp	x19,x20,[sp, #-16]!
	sub	sp,sp,#224
	str	x0,[sp]
	ldr	x0,[sp]
	ldr	w3,[x0, #8]
	ldr	x0,[sp]
	ldr	w2,[x0, #12]
	movz	x1,#1
	adrp	x0,_VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGE
	ldr	x0,[x0, _VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGEOFF]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CREATE$LONGINT$LONGINT$$TSELECTIONMASK
	str	x0,[sp, #8]
	add	x2,sp,#24
	add	x1,sp,#48
	movz	w0,#1
	bl	fpc_pushexceptaddr
	bl	fpc_setjmp
	sxtw	x1,w0
	str	x1,[sp, #216]
	cmp	w0,#0
	b.ne	Lj519
	ldr	x0,[sp]
	ldr	w0,[x0, #12]
	sub	w19,w0,#1
	cmp	w19,#0
	b.ge	Lj521
	b	Lj522
Lj521:
	movn	w0,#0
	str	w0,[sp, #20]
	.align 2
Lj523:
	ldr	w0,[sp, #20]
	add	w0,w0,#1
	str	w0,[sp, #20]
	ldr	x0,[sp]
	ldr	w0,[x0, #8]
	sub	w20,w0,#1
	cmp	w20,#0
	b.ge	Lj526
	b	Lj527
Lj526:
	movn	w0,#0
	str	w0,[sp, #16]
	.align 2
Lj528:
	ldr	w0,[sp, #16]
	add	w0,w0,#1
	str	w0,[sp, #16]
	ldr	w2,[sp, #20]
	ldr	w1,[sp, #16]
	ldr	x0,[sp]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_COVERAGE$LONGINT$LONGINT$$BYTE
	mov	w3,w0
	ldr	x0,[sp]
	ldr	w0,[x0, #8]
	sub	w0,w0,#1
	ldr	w1,[sp, #16]
	sub	w2,w0,w1
	ldr	w1,[sp, #20]
	ldr	x0,[sp, #8]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETCOVERAGE$LONGINT$LONGINT$BYTE
	ldr	w0,[sp, #16]
	cmp	w0,w20
	b.ge	Lj530
	b	Lj528
Lj530:
Lj527:
	ldr	w0,[sp, #20]
	cmp	w0,w19
	b.ge	Lj525
	b	Lj523
Lj525:
Lj522:
	ldr	x1,[sp, #8]
	ldr	x0,[sp]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_ASSIGN$TSELECTIONMASK
Lj519:
	bl	fpc_popaddrstack
	ldr	x0,[sp, #8]
	bl	_SYSTEM$_$TOBJECT_$__$$_FREE
	ldr	x0,[sp, #216]
	cmp	x0,#0
	b.eq	Lj518
	bl	fpc_reraise
Lj518:
	add	sp,sp,#224
	ldp	x19,x20,[sp], #16
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CROP$LONGINT$LONGINT$LONGINT$LONGINT$$TSELECTIONMASK
_FPSELECTION$_$TSELECTIONMASK_$__$$_CROP$LONGINT$LONGINT$LONGINT$LONGINT$$TSELECTIONMASK:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	stp	x19,x20,[sp, #-16]!
	sub	sp,sp,#64
	str	x0,[sp, #32]
	str	w1,[sp]
	str	w2,[sp, #8]
	str	w3,[sp, #16]
	str	w4,[sp, #24]
	ldr	w0,[sp, #16]
	cmp	w0,#1
	b.lt	Lj533
	b	Lj534
Lj533:
	movz	w0,#1
	b	Lj535
Lj534:
	ldr	w0,[sp, #16]
Lj535:
	str	w0,[sp, #16]
	ldr	w0,[sp, #24]
	cmp	w0,#1
	b.lt	Lj536
	b	Lj537
Lj536:
	movz	w0,#1
	b	Lj538
Lj537:
	ldr	w0,[sp, #24]
Lj538:
	str	w0,[sp, #24]
	ldr	w3,[sp, #24]
	ldr	w2,[sp, #16]
	movz	x1,#1
	adrp	x0,_VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGE
	ldr	x0,[x0, _VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGEOFF]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CREATE$LONGINT$LONGINT$$TSELECTIONMASK
	str	x0,[sp, #40]
	ldr	w0,[sp, #24]
	sub	w19,w0,#1
	cmp	w19,#0
	b.ge	Lj539
	b	Lj540
Lj539:
	movn	w0,#0
	str	w0,[sp, #52]
	.align 2
Lj541:
	ldr	w0,[sp, #52]
	add	w0,w0,#1
	str	w0,[sp, #52]
	ldr	w0,[sp, #8]
	ldr	w1,[sp, #52]
	add	w0,w1,w0
	str	w0,[sp, #60]
	ldr	w0,[sp, #60]
	cmp	w0,#0
	b.lt	Lj544
	b	Lj545
Lj545:
	ldr	x0,[sp, #32]
	ldr	w1,[x0, #12]
	ldr	w0,[sp, #60]
	cmp	w1,w0
	b.le	Lj544
	b	Lj546
Lj544:
	b	Lj542
Lj546:
	ldr	w0,[sp, #16]
	sub	w20,w0,#1
	cmp	w20,#0
	b.ge	Lj547
	b	Lj548
Lj547:
	movn	w0,#0
	str	w0,[sp, #48]
	.align 2
Lj549:
	ldr	w0,[sp, #48]
	add	w0,w0,#1
	str	w0,[sp, #48]
	ldr	w1,[sp]
	ldr	w0,[sp, #48]
	add	w0,w0,w1
	str	w0,[sp, #56]
	ldr	w0,[sp, #56]
	cmp	w0,#0
	b.lt	Lj552
	b	Lj553
Lj553:
	ldr	x0,[sp, #32]
	ldr	w1,[x0, #8]
	ldr	w0,[sp, #56]
	cmp	w1,w0
	b.le	Lj552
	b	Lj554
Lj552:
	b	Lj550
Lj554:
	ldr	w2,[sp, #60]
	ldr	w1,[sp, #56]
	ldr	x0,[sp, #32]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_COVERAGE$LONGINT$LONGINT$$BYTE
	mov	w3,w0
	ldr	w2,[sp, #52]
	ldr	w1,[sp, #48]
	ldr	x0,[sp, #40]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETCOVERAGE$LONGINT$LONGINT$BYTE
Lj550:
	ldr	w0,[sp, #48]
	cmp	w0,w20
	b.ge	Lj551
	b	Lj549
Lj551:
Lj548:
Lj542:
	ldr	w0,[sp, #52]
	cmp	w0,w19
	b.ge	Lj543
	b	Lj541
Lj543:
Lj540:
	ldr	x0,[sp, #40]
	add	sp,sp,#64
	ldp	x19,x20,[sp], #16
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_RESIZENEAREST$LONGINT$LONGINT$$TSELECTIONMASK
_FPSELECTION$_$TSELECTIONMASK_$__$$_RESIZENEAREST$LONGINT$LONGINT$$TSELECTIONMASK:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	stp	x19,x20,[sp, #-16]!
	sub	sp,sp,#64
	str	x0,[sp, #16]
	str	w1,[sp]
	str	w2,[sp, #8]
	ldr	w0,[sp]
	cmp	w0,#1
	b.lt	Lj557
	b	Lj558
Lj557:
	movz	w0,#1
	b	Lj559
Lj558:
	ldr	w0,[sp]
Lj559:
	str	w0,[sp]
	ldr	w0,[sp, #8]
	cmp	w0,#1
	b.lt	Lj560
	b	Lj561
Lj560:
	movz	w0,#1
	b	Lj562
Lj561:
	ldr	w0,[sp, #8]
Lj562:
	str	w0,[sp, #8]
	ldr	w3,[sp, #8]
	ldr	w2,[sp]
	movz	x1,#1
	adrp	x0,_VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGE
	ldr	x0,[x0, _VMT_$FPSELECTION_$$_TSELECTIONMASK@GOTPAGEOFF]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_CREATE$LONGINT$LONGINT$$TSELECTIONMASK
	str	x0,[sp, #24]
	ldr	w0,[sp, #8]
	sub	w19,w0,#1
	cmp	w19,#0
	b.ge	Lj563
	b	Lj564
Lj563:
	movn	w0,#0
	str	w0,[sp, #36]
	.align 2
Lj565:
	ldr	w0,[sp, #36]
	add	w0,w0,#1
	str	w0,[sp, #36]
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #12]
	ldr	w1,[sp, #36]
	smull	x0,w0,w1
	ldrsw	x1,[sp, #8]
	sdiv	x0,x0,x1
	cmp	x1,#0
	b.ne	Lj568
	bl	FPC_DIVBYZERO
Lj568:
	str	x0,[sp, #48]
	ldr	x0,[sp, #16]
	ldrsw	x0,[x0, #12]
	sub	x0,x0,#1
	str	x0,[sp, #56]
	ldr	x0,[sp, #56]
	ldr	x1,[sp, #48]
	cmp	x0,x1
	b.lt	Lj569
	b	Lj570
Lj569:
	ldr	x0,[sp, #56]
	b	Lj571
Lj570:
	ldr	x0,[sp, #48]
Lj571:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #44]
	ldr	w0,[sp]
	sub	w20,w0,#1
	cmp	w20,#0
	b.ge	Lj572
	b	Lj573
Lj572:
	movn	w0,#0
	str	w0,[sp, #32]
	.align 2
Lj574:
	ldr	w0,[sp, #32]
	add	w0,w0,#1
	str	w0,[sp, #32]
	ldr	x0,[sp, #16]
	ldr	w0,[x0, #8]
	ldr	w1,[sp, #32]
	smull	x0,w0,w1
	ldrsw	x1,[sp]
	sdiv	x0,x0,x1
	cmp	x1,#0
	b.ne	Lj577
	bl	FPC_DIVBYZERO
Lj577:
	str	x0,[sp, #48]
	ldr	x0,[sp, #16]
	ldrsw	x0,[x0, #8]
	sub	x0,x0,#1
	str	x0,[sp, #56]
	ldr	x0,[sp, #56]
	ldr	x1,[sp, #48]
	cmp	x0,x1
	b.lt	Lj578
	b	Lj579
Lj578:
	ldr	x0,[sp, #56]
	b	Lj580
Lj579:
	ldr	x0,[sp, #48]
Lj580:
	ubfiz	x0,x0,#0,#32
	str	w0,[sp, #40]
	ldr	w2,[sp, #44]
	ldr	w1,[sp, #40]
	ldr	x0,[sp, #16]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_COVERAGE$LONGINT$LONGINT$$BYTE
	mov	w3,w0
	ldr	w2,[sp, #36]
	ldr	w1,[sp, #32]
	ldr	x0,[sp, #24]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_SETCOVERAGE$LONGINT$LONGINT$BYTE
	ldr	w0,[sp, #32]
	cmp	w0,w20
	b.ge	Lj576
	b	Lj574
Lj576:
Lj573:
	ldr	w0,[sp, #36]
	cmp	w0,w19
	b.ge	Lj567
	b	Lj565
Lj567:
Lj564:
	ldr	x0,[sp, #24]
	add	sp,sp,#64
	ldp	x19,x20,[sp], #16
	ldp	x29,x30,[sp], #16
	ret

.text
	.align 4
.globl	_FPSELECTION$_$TSELECTIONMASK_$__$$_BOUNDSRECT$$TRECT
_FPSELECTION$_$TSELECTIONMASK_$__$$_BOUNDSRECT$$TRECT:
	stp	x29,x30,[sp, #-16]!
	mov	x29,sp
	stp	x19,x20,[sp, #-16]!
	sub	sp,sp,#64
	str	x0,[sp]
	ldr	x0,[sp]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_HASSELECTION$$BOOLEAN
	cmp	w0,#0
	b.eq	Lj583
	b	Lj584
Lj583:
	str	wzr,[sp, #8]
	str	wzr,[sp, #12]
	str	wzr,[sp, #16]
	str	wzr,[sp, #20]
	b	Lj581
Lj584:
	ldr	x0,[sp]
	ldr	w0,[x0, #8]
	sub	w0,w0,#1
	str	w0,[sp, #24]
	ldr	x0,[sp]
	ldr	w0,[x0, #12]
	sub	w0,w0,#1
	str	w0,[sp, #28]
	str	wzr,[sp, #32]
	str	wzr,[sp, #36]
	ldr	x0,[sp]
	ldr	w0,[x0, #12]
	sub	w19,w0,#1
	cmp	w19,#0
	b.ge	Lj586
	b	Lj587
Lj586:
	movn	w0,#0
	str	w0,[sp, #44]
	.align 2
Lj588:
	ldr	w0,[sp, #44]
	add	w0,w0,#1
	str	w0,[sp, #44]
	ldr	x0,[sp]
	ldr	w0,[x0, #8]
	sub	w20,w0,#1
	cmp	w20,#0
	b.ge	Lj591
	b	Lj592
Lj591:
	movn	w0,#0
	str	w0,[sp, #40]
	.align 2
Lj593:
	ldr	w0,[sp, #40]
	add	w0,w0,#1
	str	w0,[sp, #40]
	ldr	w2,[sp, #44]
	ldr	w1,[sp, #40]
	ldr	x0,[sp]
	bl	_FPSELECTION$_$TSELECTIONMASK_$__$$_GETSELECTED$LONGINT$LONGINT$$BOOLEAN
	cmp	w0,#0
	b.ne	Lj596
	b	Lj597
Lj596:
	ldr	w0,[sp, #40]
	ldr	w1,[sp, #24]
	cmp	w0,w1
	b.lt	Lj598
	b	Lj599
Lj598:
	ldr	w0,[sp, #40]
	str	w0,[sp, #24]
Lj599:
	ldr	w0,[sp, #44]
	ldr	w1,[sp, #28]
	cmp	w0,w1
	b.lt	Lj600
	b	Lj601
Lj600:
	ldr	w0,[sp, #44]
	str	w0,[sp, #28]
Lj601:
	ldr	w1,[sp, #40]
	ldr	w0,[sp, #32]
	cmp	w1,w0
	b.gt	Lj602
	b	Lj603
Lj602:
	ldr	w0,[sp, #40]
	str	w0,[sp, #32]
Lj603:
	ldr	w0,[sp, #44]
	ldr	w1,[sp, #36]
	cmp	w0,w1
	b.gt	Lj604
	b	Lj605
Lj604:
	ldr	w0,[sp, #44]
	str	w0,[sp, #36]
Lj605:
Lj597:
	ldr	w0,[sp, #40]
	cmp	w0,w20
	b.ge	Lj595
	b	Lj593
Lj595:
Lj592:
	ldr	w0,[sp, #44]
	cmp	w0,w19
	b.ge	Lj590
	b	Lj588
Lj590:
Lj587:
	ldr	w0,[sp, #36]
	add	w0,w0,#1
	str	w0,[sp, #48]
	ldr	w0,[sp, #32]
	add	w0,w0,#1
	str	w0,[sp, #52]
	ldr	w0,[sp, #24]
	str	w0,[sp, #8]
	ldr	w0,[sp, #28]
	str	w0,[sp, #12]
	ldr	w0,[sp, #52]
	str	w0,[sp, #16]
	ldr	w0,[sp, #48]
	str	w0,[sp, #20]
Lj581:
	ldp	w1,w2,[sp, #8]
	mov	w0,w1
	bfi	x0,x2,#32,#32
	ldp	w2,w3,[sp, #16]
	mov	w1,w2
	bfi	x1,x3,#32,#32
	add	sp,sp,#64
	ldp	x19,x20,[sp], #16
	ldp	x29,x30,[sp], #16
	ret
# End asmlist al_procedures
# Begin asmlist al_globals

.const_data
	.align 3
.globl	_VMT_$FPSELECTION_$$_TSELECTIONMASK
_VMT_$FPSELECTION_$$_TSELECTIONMASK:
	.quad	24,-24
	.quad	_VMT_$SYSTEM_$$_TOBJECT$indirect
	.quad	_$$fpclocal$_ld4
	.quad	0,0,0
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONMASK
	.quad	_INIT_$FPSELECTION_$$_TSELECTIONMASK
	.quad	0,0,0
	.quad	_SYSTEM$_$TOBJECT_$__$$_DESTROY
	.quad	_SYSTEM$_$TOBJECT_$__$$_NEWINSTANCE$$TOBJECT
	.quad	_SYSTEM$_$TOBJECT_$__$$_FREEINSTANCE
	.quad	_SYSTEM$_$TOBJECT_$__$$_SAFECALLEXCEPTION$TOBJECT$POINTER$$HRESULT
	.quad	_SYSTEM$_$TOBJECT_$__$$_DEFAULTHANDLER$formal
	.quad	_SYSTEM$_$TOBJECT_$__$$_AFTERCONSTRUCTION
	.quad	_SYSTEM$_$TOBJECT_$__$$_BEFOREDESTRUCTION
	.quad	_SYSTEM$_$TOBJECT_$__$$_DEFAULTHANDLERSTR$formal
	.quad	_SYSTEM$_$TOBJECT_$__$$_DISPATCH$formal
	.quad	_SYSTEM$_$TOBJECT_$__$$_DISPATCHSTR$formal
	.quad	_SYSTEM$_$TOBJECT_$__$$_EQUALS$TOBJECT$$BOOLEAN
	.quad	_SYSTEM$_$TOBJECT_$__$$_GETHASHCODE$$INT64
	.quad	_SYSTEM$_$TOBJECT_$__$$_TOSTRING$$ANSISTRING
	.quad	0
# End asmlist al_globals
# Begin asmlist al_const

.const_data
	.align 3
_$$fpclocal$_ld4:
	.byte	14
	.ascii	"TSelectionMask"
# End asmlist al_const
# Begin asmlist al_typedconsts

.const
	.align 2
.globl	_$FPSELECTION$_Ld1
_$FPSELECTION$_Ld1:
	.byte	0,0,0,63

.const
	.align 2
.globl	_$FPSELECTION$_Ld2
_$FPSELECTION$_Ld2:
	.byte	0,0,127,67

.const
	.align 3
.globl	_$FPSELECTION$_Ld3
_$FPSELECTION$_Ld3:
	.byte	0,0,0,0,0,0,240,63
# End asmlist al_typedconsts
# Begin asmlist al_rtti

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE
_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE:
	.byte	3,21
	.ascii	"TSelectionCombineMode"
	.byte	0,5,0,0,0,0,0,0,0
	.long	0,3
	.quad	0
	.byte	9
	.ascii	"scReplace"
	.byte	5
	.ascii	"scAdd"
	.byte	10
	.ascii	"scSubtract"
	.byte	11
	.ascii	"scIntersect"
	.byte	11
	.ascii	"FPSelection"
	.byte	0,0,0,0,0

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE_s2o
_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE_s2o:
	.long	4
	.byte	0,0,0,0
	.long	1
	.byte	0,0,0,0
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE+58
	.long	3
	.byte	0,0,0,0
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE+75
	.long	0
	.byte	0,0,0,0
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE+48
	.long	2
	.byte	0,0,0,0
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE+64

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE_o2s
_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE_o2s:
	.long	0
	.byte	0,0,0,0
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE+48
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE+58
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE+64
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE+75

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_def00000002
_RTTI_$FPSELECTION_$$_def00000002:
	.byte	21,0,0,0,0,0,0,0
	.quad	1
	.quad	_RTTI_$SYSTEM_$$_BYTE$indirect
	.long	17
	.byte	0,0,0,0
	.quad	0
	.byte	11
	.ascii	"FPSelection"
	.byte	0,0,0,0

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_def0000003C
_RTTI_$FPSELECTION_$$_def0000003C:
	.byte	21,0,0,0,0,0,0,0
	.quad	1
	.quad	_RTTI_$SYSTEM_$$_BYTE$indirect
	.long	17
	.byte	0,0,0,0
	.quad	0
	.byte	11
	.ascii	"FPSelection"
	.byte	0,0,0,0

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_def00000035
_RTTI_$FPSELECTION_$$_def00000035:
	.byte	21,0,0,0,0,0,0,0
	.quad	4
	.quad	_RTTI_$SYSTEM_$$_LONGINT$indirect
	.long	3
	.byte	0,0,0,0
	.quad	0
	.byte	11
	.ascii	"FPSelection"
	.byte	0,0,0,0

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_def00000036
_RTTI_$FPSELECTION_$$_def00000036:
	.byte	21,0,0,0,0,0,0,0
	.quad	4
	.quad	_RTTI_$SYSTEM_$$_LONGINT$indirect
	.long	3
	.byte	0,0,0,0
	.quad	0
	.byte	11
	.ascii	"FPSelection"
	.byte	0,0,0,0

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_def00000037
_RTTI_$FPSELECTION_$$_def00000037:
	.byte	21,0,0,0,0,0,0,0
	.quad	1
	.quad	_RTTI_$SYSTEM_$$_BOOLEAN$indirect
	.long	11
	.byte	0,0,0,0
	.quad	0
	.byte	11
	.ascii	"FPSelection"
	.byte	0,0,0,0

.const_data
	.align 3
.globl	_INIT_$FPSELECTION_$$_TSELECTIONMASK
_INIT_$FPSELECTION_$$_TSELECTIONMASK:
	.byte	15,14
	.ascii	"TSelectionMask"
	.quad	0
	.long	8
	.byte	0,0,0,0
	.quad	0,0
	.long	1
	.byte	0,0,0,0
	.quad	_RTTI_$FPSELECTION_$$_def00000002$indirect
	.quad	16

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_TSELECTIONMASK
_RTTI_$FPSELECTION_$$_TSELECTIONMASK:
	.byte	15,14
	.ascii	"TSelectionMask"
	.quad	_VMT_$FPSELECTION_$$_TSELECTIONMASK
	.quad	_RTTI_$SYSTEM_$$_TOBJECT$indirect
	.short	0
	.byte	11
	.ascii	"FPSelection"
	.byte	0,0
	.short	0
	.byte	0,0,0,0,0,0
# End asmlist al_rtti
# Begin asmlist al_indirectglobals

.const_data
	.align 3
.globl	_VMT_$FPSELECTION_$$_TSELECTIONMASK$indirect
_VMT_$FPSELECTION_$$_TSELECTIONMASK$indirect:
	.quad	_VMT_$FPSELECTION_$$_TSELECTIONMASK

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE$indirect
_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE$indirect:
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE_s2o$indirect
_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE_s2o$indirect:
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE_s2o

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE_o2s$indirect
_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE_o2s$indirect:
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONCOMBINEMODE_o2s

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_def00000002$indirect
_RTTI_$FPSELECTION_$$_def00000002$indirect:
	.quad	_RTTI_$FPSELECTION_$$_def00000002

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_def0000003C$indirect
_RTTI_$FPSELECTION_$$_def0000003C$indirect:
	.quad	_RTTI_$FPSELECTION_$$_def0000003C

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_def00000035$indirect
_RTTI_$FPSELECTION_$$_def00000035$indirect:
	.quad	_RTTI_$FPSELECTION_$$_def00000035

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_def00000036$indirect
_RTTI_$FPSELECTION_$$_def00000036$indirect:
	.quad	_RTTI_$FPSELECTION_$$_def00000036

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_def00000037$indirect
_RTTI_$FPSELECTION_$$_def00000037$indirect:
	.quad	_RTTI_$FPSELECTION_$$_def00000037

.const_data
	.align 3
.globl	_INIT_$FPSELECTION_$$_TSELECTIONMASK$indirect
_INIT_$FPSELECTION_$$_TSELECTIONMASK$indirect:
	.quad	_INIT_$FPSELECTION_$$_TSELECTIONMASK

.const_data
	.align 3
.globl	_RTTI_$FPSELECTION_$$_TSELECTIONMASK$indirect
_RTTI_$FPSELECTION_$$_TSELECTIONMASK$indirect:
	.quad	_RTTI_$FPSELECTION_$$_TSELECTIONMASK
# End asmlist al_indirectglobals
	.subsections_via_symbols

