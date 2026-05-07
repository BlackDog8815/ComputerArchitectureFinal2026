.data
	format: .asciz "%c"
	input: .byte 0
	wall_msg db "You hit a wall"
.text
_input_handler:
	push {lr}

	ldr r0, =format
	ldr r1, =input
	bl scanf

	ldr r0, =input @loading the register the input
	ldrb r0, [r0]

	pop {pc}


bl _input_handler

	cmp r0, #'w' @movement up
	beq _up

	cmp r0, #'a' @movement left
	beq _left

	cmp r0, #'s' @movement down
	beq _down

	cmp r0, #'d' @movement right
	beq _right

_up:
	cmp r2, #4
	beq _wall
	add r2, r2, #1
	pop {lr}

_left:
	cmp r3, #-4
	beq _wall
	sub r3, r3, #1
	pop {lr}

_down:
	cmp r2, #-4
	beq _wall
	sub r2, r2, #1
	pop {lr}

_right:
	cmp r3, #4
	beq _wall
	add r3, r3, #1
	pop {lr}

_wall:
	bl printf
	pop {lr}
