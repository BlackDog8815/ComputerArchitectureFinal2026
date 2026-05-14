@ CmpE 3780 FINAL PROJECT: THE PLATTEVILLE CRAWL - STABLE MASTER
@ Authors: Spencer, Ethan, Nadine
@ Date: May 12, 2026
@ Architecture: ARMv7 (32-bit Little Endian)

.data
@ --- SECTION 1: SPENCER'S DATA SEGMENT (Global Memory) ---
@ .asciz allocates bytes for a string and adds a null-terminator (0x00).
@ Hardware Context: Libc functions like printf scan memory until they find 0x00.

title_line1: .asciz "\n****************************************\n"
title_line2: .asciz "*          THE PLATTEVILLE CRAWL        *\n"
title_line3: .asciz "*    By: Spencer, Ethan, and Nadine    *\n"
title_line4: .asciz "*       CmpE 3780 - Spring 2026        *\n"
title_line5: .asciz "****************************************\n\n"
start_msg:   .asciz "Game Loading... Please wait.\n"

@ Control scheme instructions for the user.
intro_msg:   .asciz "HOW TO PLAY:\n - Use 'w', 'a', 's', 'd' to move\n - 'q' to Quit\n - Press 'Enter' after every key\n\n"

@ MAP LEGEND: Critical coordinates for the quest.
legend_msg:  .asciz "Map Legend:\n - Bounds: (-4,-4) to (4,4)\n - Items: Sword(-2,2), Potion(2,-2), Key(0,3)\n - Goal: Collect all 3 & reach (4,4)\n\n"

@ HUD STRINGS: %d is a token for signed decimal integers converted to ASCII by printf.
move_msg:    .asciz "Moves remaining: %d | Position: (%d, %d)\n"
trap_msg:    .asciz "!!!! TRAP TRIGGERED !!!!\n"
ready_msg:   .asciz "Your journey begins now!\n\n"
win_msg:     .asciz "\nCongratulations! You escaped the dungeon!\n"
lose_msg:    .asciz "\nYou have died in the dungeon.\n"
need_items:  .asciz "The exit at (4,4) is locked! You need all 3 items to leave.\n"

@ SPECIFIC ITEM FEEDBACK
found_sword:  .asciz ">>> You found the Legendary Sword! <<<\n"
found_potion: .asciz ">>> You found a Healing Potion! <<<\n"
found_key:    .asciz ">>> You found the Dungeon Key! <<<\n"

@ --- SECTION 2: NADINE'S DATA (Formatting & Health) ---
fmt_health:  .asciz "Health: %d\n"
fmt_damage:  .asciz "You took %d damage!\n"

@ --- SECTION 3: ETHAN'S DATA (Input & Storage) ---
@ " %c": The space is a directive for scanf to discard leading whitespace/newlines.
format:      .asciz " %c"  
input:       .byte 0       @ Allocates exactly 8 bits for single character input buffer.
inventory:   .word 0, 0, 0 @ 32-bit words: [0]=Sword, [1]=Potion, [2]=Key. Offset 4 bytes each.

wall_msg:    .asciz "You hit a wall!\n"
inv_title:   .asciz "Inventory:\n"
inv_sword:   .asciz "- Sword\n"
inv_potion:  .asciz "- Potion\n"
inv_key:     .asciz "- Key\n"
inv_empty:   .asciz "- Empty\n"

go_up:       .asciz "You go North\n"
go_down:     .asciz "You go South\n"
go_left:     .asciz "You go West\n"
go_right:    .asciz "You go East\n"

.text
.global main
.extern printf
.extern sleep
.extern scanf


@ MAIN PROGRAM (Spencer)

main:
    @ --- STACK INITIALIZATION ---
    @ PUSH {R4-R11, LR}: Saves callee-saved registers to comply with AAPCS.
    @ LR (Link Register) is saved so that BL calls don't lose the return address to the OS.
    PUSH {R4-R11, LR}
    
    @ --- DISPLAY BOOT SCREEN ---
    @ LDR R0, =label: Loads the 32-bit address of the string into R0 (1st argument register).
    LDR R0, =title_line1
    BL  printf           @ Branch with Link: PC jumps to printf, LR saves next line address.
    LDR R0, =title_line2
    BL  printf
    LDR R0, =title_line3
    BL  printf
    LDR R0, =title_line4
    BL  printf
    LDR R0, =title_line5
    BL  printf
    LDR R0, =intro_msg
    BL  printf
    LDR R0, =legend_msg
    BL  printf
    
    @ --- TIME DELAY (Requirement) ---
    MOV R0, #3           @ Load immediate value 3 (seconds) for sleep parameter.
    BL  sleep

    @ --- INITIALIZE GAME STATE (Register Aliasing) ---
    @ R4: Global Health tracker (Preserved across function calls).
    @ R6: Global X-Coordinate.
    @ R7: Global Y-Coordinate.
    @ R8: Move Limit Counter.
    BL  Init_Stats
    MOV R6, #0           @ Set initial X to origin.
    MOV R7, #0           @ Set initial Y to origin.
    MOV R8, #50          @ Set move budget to 50.

game_loop:
    @ --- HUD RENDERING ---
    LDR R0, =move_msg
    MOV R1, R8           @ Register R1: 2nd argument (decimal moves). updates "d%" so you can print message again 
    MOV R2, R6           @ Register R2: 3rd argument (X position).
    MOV R3, R7           @ Register R3: 4th argument (Y position).
    BL  printf

    BL  Print_Status     @ Displays health status via R4.

    @ --- PLAYER ACTION (Ethan) ---
    BL  handle_input     @ Call the input dispatcher subroutine.
    
    @ --- UPDATE GAME CLOCK ---
    SUB R8, R8, #1       @ Arithmetic subtraction: Decrement moves remaining.
    CMP R8, #0           @ Compare current moves to zero to update CPSR flags.
    BLE lose_game        @ Branch if Less or Equal: Player is out of moves.

    @ --- COLLISION & TRIGGER SCAN (Spencer) ---
    BL  check_tiles      @ Subroutine to check current (X,Y) for pickups/traps.
    
    @ --- STATUS CHECK (Nadine) ---
    BL  Check_Death
    CMP R0, #1           @ Boolean return in R0: 1 = dead, 0 = alive.
    BEQ lose_game

    @ --- WIN CONDITION: EXIT PORTAL AT (4,4) ---
    @ Logic: Nested comparisons simulate a logical AND gate.
    CMP R6, #4           @ Check if X coordinate is 4.
    BNE game_loop        @ If X != 4, reset the loop for next input.
    CMP R7, #4           @ If X is 4, check if Y is 4.
    BNE game_loop        @ If Y != 4, reset the loop.

    @ --- QUEST ITEM GATE ---
    @ Verifies the player has set the flags for all 3 items in memory.
    LDR R1, =inventory   @ Load the base address of the inventory array.
    LDR R2, [R1]         @ Load Sword status (Index 0).
    LDR R3, [R1, #4]     @ Load Potion status (Index 1 - 4 byte offset).
    LDR R5, [R1, #8]     @ Load Key status (Index 2 - 8 byte offset).
    
    AND R2, R2, R3       @ Logical AND: Accumulate bits.
    AND R2, R2, R5       @ Result is 1 only if all three items were found (1).
    CMP R2, #1           @ Compare the result of the AND accumulation to 1.
    BEQ win_game
    
    @ Fall-through: Reached (4,4) without collecting all quest items.
    LDR R0, =need_items
    BL  printf
    B   game_loop        @ Restart turn.

win_game:
    LDR R0, =win_msg
    BL  printf
    B   end_program      @ Terminate game.

lose_game:
    LDR R0, =lose_msg
    BL  printf
    B   end_program      @ Terminate game.

@ EXIT LOGIC: SYSTEM CLEANUP

end_program:
    @ --- CLEAN EXIT (Linux EABI) ---
    MOV R0, #0           @ Load Success status code (0) into R0.
    MOV R7, #1           @ Load Linux syscall number for sys_exit (1) into R7.
    SVC 0                @ Supervisor Call: Transfers control to kernel to quit.

@ SUBROUTINES: TILE LOGIC & HAZARDS (Spencer)

check_tiles:
    PUSH {LR}            @ Subroutines calling printf MUST save the Link Register.
    LDR  R1, =inventory
    
    @ --- SWORD Pickup Logic at (-2, 2) ---
    CMP R6, #-2
    BNE _skip_sword
    CMP R7, #2
    BNE _skip_sword
    LDR R2, [R1]         @ Check if Sword is already in inventory.
    CMP R2, #1            @Boolean statement 1 = have sword, 0 = no sword 
    BEQ _skip_sword      @ If item exists, skip re-pickup.
    MOV R2, #1           @ puts sword in 
    STR R2, [R1]         @ Store Word: Write 1 to the first slot of inventory.
    LDR R0, =found_sword
    BL  printf
_skip_sword:

    @ --- POTION Pickup Logic at (2, -2) ---
    CMP R6, #2
    BNE _skip_potion
    CMP R7, #-2
    BNE _skip_potion
    LDR R2, [R1, #4]     @ Use offset to check Potion slot.
    CMP R2, #1
    BEQ _skip_potion
    MOV R2, #1
    STR R2, [R1, #4]     @ Update Potion status in RAM.
    LDR R0, =found_potion
    BL  printf
_skip_potion:

    @ --- KEY Pickup Logic at (0, 3) ---
    CMP R6, #0
    BNE _chk_trap
    CMP R7, #3
    BNE _chk_trap
    LDR R2, [R1, #8]     @ Check Key slot via 8-byte offset.
    CMP R2, #1
    BEQ _chk_trap
    MOV R2, #1
    STR R2, [R1, #8]     @ Update Key status in RAM.
    LDR R0, =found_key
    BL  printf

_chk_trap:
    @ --- TRAP Hazard Logic at (2, 2) ---
    CMP R6, #2
    BNE _skip_all
    CMP R7, #2
    BNE _skip_all
    LDR R0, =trap_msg
    BL  printf
    MOV R0, #15          @ Load damage amount into R0 for the hazard routine.
    BL  Apply_Hazard     @ Jump to Nadine's vitality module.

_skip_all:
    POP {PC}             @ Restore LR directly into Program Counter to return.

@ SUBROUTINES: ATTRIBUTES & VITALITY (Nadine)

Init_Stats:
    PUSH    {LR}        @ save the return address so we can return the main 
    MOV     R4, #100     @ Initialize Global Health (R4 is preserved by printf).
    MOV     R5, #100     @ Max Health Constant (used for clamping). (changed?)
    POP     {PC}        @ returns info back to main. pops the program counter to where the LR was and starts working instantly with update.

Apply_Hazard:
    PUSH    {R0, R1, LR} @ Save damage value (R0) and return address. R1 is push to keep the invetnory so it's not lost. 
    @ better version: MOV R1, R0 so you dont have to push R0. not added due to needing a running program. 
    @ better version: PUSH {R1, LR} which would change the SUB R4, R4, R1
    SUB     R4, R4, R0   @ Perform subtraction: R4 = R4 - R0.
    
    @ --- CLAMPING: Prevent Negative Health ---
    CMP     R4, #0
    MOVLT   R4, #0       @ Conditional Move: If health < 0, set to 0.
    
    MOV     R1, R0       @ Copy damage value to R1 for conversion in printf.
    LDR     R0, =fmt_damage    @ prints meesage for the amount of damage taken.
    BL      printf
    POP     {R0, R1, PC}    @ pc is poped to return to main function. 

Print_Status:
    PUSH    {LR}        @ saves return address 
    LDR     R0, =fmt_health
    MOV     R1, R4       @ Load vitality(current amount of health) from R4 into 2nd argument register due to not linked to inventory yet. 
    BL      printf
    POP     {PC}        @ return to main function

Check_Death:
    @ returns 1 (Dead) or 0 (Alive) based on CPSR flags(N/Z).
    CMP     R4, #0
    MOVLE   R0, #1       @ Move if Less or Equal to zero. labels it as 1 meaning dead 
    MOVGT   R0, #0       @ Move if Greater Than zero. labels it as 0 meaning alive
    BX      LR           @ Branch Exchange: Faster return for simple flags. returning to main without pop due to no pushing. (not a subrountine)


@ SUBROUTINES: INPUT & MOVEMENT (Ethan)

_input_handler:
    @ --- LIBC WRAPPER FOR USER INPUT ---
    PUSH {lr}
    LDR r0, =format      @ Load address of " %c".
    LDR r1, =input       @ Load address of the 1-byte storage buffer.
    BL  scanf            @ Standard C library call: scanf("%c", &input).
    LDR r0, =input
    LDRB r0, [r0]        @ Load Byte: Get the ASCII character back into R0.
    POP {pc}

handle_input:
    PUSH {LR}
    BL _input_handler    @ Call input wrapper; char returned in R0.

    @ --- DISPATCHER TABLE (Branch Selector) ---
    CMP r0, #'w'         @ Compare char in R0 to literal ASCII 'w'.
    BEQ _up              @ Branch if Equal.
    CMP r0, #'a'         @ Compare to ASCII 'a'.
    BEQ _left
    CMP r0, #'s'         @ Compare to ASCII 's'.
    BEQ _down
    CMP r0, #'d'         @ Compare to ASCII 'd'.
    BEQ _right
    CMP r0, #'i'         @ Compare to ASCII 'i'.
    BEQ _end             @ Redirected to prevent crashes from old inventory code.
    CMP r0, #'q'         @ Compare to ASCII 'q'.
    BEQ end_program
    B   _end             @ Branch if no match (Unknown key).

_up:
    @ --- Y-AXIS BOUNDARY CHECK ---
    CMP R7, #4           @ Check if player is already at North limit (4).
    BGE _wall            @ If Y >= 4, branch to wall collision message.
    ADD R7, R7, #1       @ If safe, increment Y coordinate.
    LDR r0, =go_up
    BL  printf
    B   _end

_left:
    @ --- X-AXIS BOUNDARY CHECK ---
    CMP R6, #-4          @ Check West limit (-4).
    BLE _wall            @ If X <= -4, branch to wall collision message.
    SUB R6, R6, #1       @ Decrement X coordinate.
    LDR r0, =go_left
    BL  printf
    B   _end

_down:
    @ --- Y-AXIS BOUNDARY CHECK ---
    CMP R7, #-4          @ Check South limit (-4).
    BLE _wall
    SUB R7, R7, #1
    LDR r0, =go_down
    BL  printf
    B   _end

_right:
    @ --- X-AXIS BOUNDARY CHECK ---
    CMP R6, #4           @ Check East limit (4).
    BGE _wall
    ADD R6, R6, #1
    LDR r0, =go_right
    BL  printf
    B   _end

_wall:
    @ Boundary feedback for the player.
    LDR r0, =wall_msg
    BL  printf

_end:
    POP {PC}             @ Exit subroutine; return control to the game_loop.
