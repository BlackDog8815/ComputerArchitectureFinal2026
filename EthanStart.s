.data
	format: .asciz "%c"
	input: .byte 0
	wall_msg: .asciz "You hit a wall\n"
	go_right: .asciz "You go one room right\n"
	go_left: .asciz "You go one room left\n"
	go_up: .asciz "You go one room up\n"
	go_down: .asciz "You go one room down\n"
	
.text
.extern printf
.extern scanf
.global _input_handler
_input_handler:
	push {lr}

	ldr r0, =format
	ldr r1, =input
	bl scanf

	ldr r0, =input @loading the register the input
	ldrb r0, [r0]

	pop {pc}
	
.global handle_input
handle_input:
	push{lr}
	bl _input_handler

	cmp r0, #'w' @movement up
	beq _up

	cmp r0, #'a' @movement left
	beq _left

	cmp r0, #'s' @movement down
	beq _down

	cmp r0, #'d' @movement right
	beq _right

	cmp r0, #'i' @inventory check
	beq _inventory

	cmp r0, #'s' @status check
	beq _status

	cmp r0, #'q' @quit game
	beq _quit
	
	b _end

_up:
	cmp r2, #4
	bge _wall
	add r2, r2, #1
	ldr r0, =go_up
	bl printf
	b _end

_left:
	cmp r3, #-4
	ble _wall
	sub r3, r3, #1
	ldr r0, =go_left
	bl printf
	b _end

_down:
	cmp r2, #-4
	ble _wall
	sub r2, r2, #1
	ldr r0, =go_down
	bl printf
	b _end

_right:
	cmp r3, #4
	bge _wall
	add r3, r3, #1
	ldr r0, =go_right
	bl printf
	b _end

_wall:
	ldr r0, =wall_msg
	bl printf
	b _end

_end:
	pop{pc}
