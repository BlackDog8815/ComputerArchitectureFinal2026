.data
	x_coord: 		.space 4
	y_coord: 		.space 4
	input: 			.byte 0
	format: 		.asciz "%c"
	wall_msg: 		.asciz "You hit a wall\n"
	go_right: 		.asciz "You go one room right\n"
	go_left: 		.asciz "You go one room left\n"
	go_up: 			.asciz "You go one room up\n"
	go_down: 		.asciz "You go one room down\n"
	inv_title:      .asciz "Inventory:\n"
	inv_sword:      .asciz "- Sword\n"
	inv_potion:     .asciz "- Potion\n"
	inv_key:        .asciz "- Key\n"
	inv_empty:      .asciz "- Empty\n"
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

	cmp r0, #'p' @status check
	beq _status

	cmp r0, #'q' @quit game
	beq _quit
	
	b _end
	
_inventory:
    push {lr}

    ldr r0, =inv_title
    bl printf

    ldr r1, =inventory

    @ sword
    ldr r2, [r1]
    cmp r2, #1
    bne _check_potion

    ldr r0, =inv_sword
    bl printf

_check_potion:
    ldr r2, [r1, #4]
    cmp r2, #1
    bne _check_key

    ldr r0, =inv_potion
    bl printf

_check_key:
    ldr r2, [r1, #8]
    cmp r2, #1
    bne _check_empty

    ldr r0, =inv_key
    bl printf
    b _inventory_done

_check_empty:
    ldr r2, [r1]
    ldr r3, [r1, #4]
    ldr r4, [r1, #8]

    add r2, r2, r3
    add r2, r2, r4

    cmp r2, #0
    bne _inventory_done

    ldr r0, =inv_empty
    bl printf

_inventory_done:
    pop {lr}
    b _end
	
_up:
	cmp r2, #4
	bge _wall
	add r2, r2, #1
	ldr r0, =go_up
	bl printf
	str r2, =y_coord
	b _end

_left:
	cmp r3, #-4
	ble _wall
	sub r3, r3, #1
	ldr r0, =go_left
	bl printf
	str r3, =x_coord
	b _end

_down:
	cmp r2, #-4
	ble _wall
	sub r2, r2, #1
	ldr r0, =go_down
	bl printf
	str r2, =y_coord
	b _end

_right:
	cmp r3, #4
	bge _wall
	add r3, r3, #1
	ldr r0, =go_right
	bl printf
	str r3, =x_coord
	b _end

_wall:
	ldr r0, =wall_msg
	bl printf
	b _end

_end:
	pop{pc}
