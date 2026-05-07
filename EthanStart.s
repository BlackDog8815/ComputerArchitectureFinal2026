.data
	format: .asciz "%c"
	input: .space 4
_input_handler:
	push {lr}

	ldr r0, =format
	ldr r1, =input
	bl scanf	
	
	ldr r1, =input
	ldr r1, [r1]
	
	cmp r1, #'w' @movement up
	beq _up

	cmp r1, #'a' @movement left
	beq _left

	cmp r1, #'s' @movement down
	beq _down

	cmp r1, #'d' @movement right
	beq _right

_up:
	add r0, r0, #1
	pop {lr}

_left:
	sub r1, r1, #1
	pop {lr}

_down:
	sub r0, r0, #1
	pop {lr}

_right:
	add r1, r1, #1
	pop {lr}
