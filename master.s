@ CmpE 3780 Final Project: The Dungeon Crawl
@ Combined Master File
@ Team: Spencer, Ethan, Nadine

.data
@ --- SPENCER'S DATA ---
@ .asciz: Allocates memory for a string and appends a 0x00 (Null) byte.
@ This is crucial because C functions like 'printf' scan memory until they hit 0x00.
title_line1: .asciz "\n****************************************\n"
title_line2: .asciz "*         THE PLATTEVILLE CRAWL        *\n"
title_line3: .asciz "*    By: Spencer, Ethan, and Nadine    *\n"
title_line4: .asciz "*       CmpE 3780 - Spring 2026        *\n"
title_line5: .asciz "****************************************\n\n"
start_msg:   .asciz "Game Loading... Please wait.\n"
ready_msg:   .asciz "Your journey begins now!\n\n"
win_msg:     .asciz "\nCongratulations! You escaped the dungeon!\n"
lose_msg:    .asciz "\nYou have died in the dungeon.\n"

@ --- NADINE'S DATA ---
@ %d: Tells printf to pop a value from a register (R1, R2, etc.) and convert 
@ the binary integer into ASCII text for the monitor.
fmt_health:  .asciz "Health: %d\n"
fmt_damage:  .asciz "You took %d damage!\n"
fmt_heal:    .asciz "You gained %d health!\n"

@ --- ETHAN'S DATA ---
@ .byte: Allocates exactly 8 bits.
@ .word: Allocates 32 bits. 
format:      .asciz " %c"  @ ADDED SPACE BEFORE %C TO SKIP NEWLINES IN SCANF
input:       .byte 0
inventory:   .word 0, 0, 0 @ ADDED MISSING INVENTORY SPACE
wall_msg:    .asciz "You hit a wall\n"
go_right:    .asciz "You go one room right\n"
go_left:     .asciz "You go one room left\n"
go_up:       .asciz "You go one room up\n"
go_down:     .asciz "You go one room down\n"
inv_title:   .asciz "Inventory:\n"
inv_sword:   .asciz "- Sword\n"
inv_potion:  .asciz "- Potion\n"
inv_key:     .asciz "- Key\n"
inv_empty:   .asciz "- Empty\n"

.text
.global main
.extern printf
.extern sleep
.extern scanf

@ MAIN PROGRAM (Spencer)

main:
    @ --- STACK INITIALIZATION ---
    @ PUSH {registers, LR}: Creates a stack frame. 
    @ LR (Link Register) must be saved because 'BL' will overwrite it.
    PUSH {R4-R8, LR}
    
    @ --- PRINTF INTERFACING ---
    @ LDR R0, =label: Loads the memory ADDRESS of the string into R0.
    @ R0 is the 'First Argument' register in AAPCS.
    
    @ 1. DISPLAY TITLE SCREEN
    LDR R0, =title_line1
    BL  printf
    LDR R0, =title_line2
    BL  printf
    LDR R0, =title_line3
    BL  printf
    LDR R0, =title_line4
    BL  printf
    LDR R0, =title_line5
    BL  printf
    LDR R0, =start_msg
    BL  printf
    
    @ 2. TIME DELAY
    @ --- SYSTEM CALLS (Delay) ---
    MOV R0, #3      @ Argument for sleep() is seconds.
    BL  sleep

    LDR R0, =ready_msg
    BL  printf
    
    @ 3. INITIALIZE STATE
    @ --- REGISTER ALIASING (Game State) ---
    @ R4: Health Accumulator (Varies 0-100)
    @ R6: X-Coordinate (Varies -4 to 4)
    @ R7: Y-Coordinate (Varies -4 to 4)
    BL  Init_Stats
    MOV R6, #0      @ Initialize X at origin
    MOV R7, #0      @ Initialize Y at origin


game_loop:
    @ HUD
	@ 1. STATUS OUTPUT
    @ Subroutine uses R4 to display vitality status.
    BL  Print_Status

    @ 4. MOVEMENT (Ethan)
	@ 2. DATA HANDOFF (Context Switching)
    @ Ethan's code expects data in R2 and R3. We "hand off" our state.
    @ ETHAN'S CODE USES R2/R3 INTERNALLY, SO WE LOAD COORDINATES THERE
    MOV R2, R7 @ R2 = Y
    MOV R3, R6 @ R3 = X
    BL  handle_input
	
	@ 3. STATE UPDATE
    @ We retrieve the modified coordinates from the "worker" registers.
    MOV R7, R2 @ UPDATE Y FROM ETHAN'S R2
    MOV R6, R3 @ UPDATE X FROM ETHAN'S R3
    
    @ 5. STATUS CHECK (Nadine)
    @ 4. CONDITION FLAG CHECKING
    @ BL Check_Death updates R0. 
    BL  Check_Death
    CMP R0, #1      @ CMP performs a subtraction (R0 - 1) and updates CPSR flags.
    BEQ lose_game   @ BEQ checks the 'Z' (Zero) flag in the CPSR.


    @ 5. WIN CONDITION (Double Comparison)
    @ To win, both X and Y must be 4. This is an "AND" logic gate.
    CMP R6, #4      
    BNE game_loop   @ If X != 4, restart loop immediately (Branch Not Equal).
    CMP R7, #4      
    BEQ win_game    @ If X was 4 AND Y is 4, exit loop to win.
    
    B   game_loop   @ Default branch (Unconditional).

win_game:
    LDR R0, =win_msg
    BL  printf
    B   end_program

lose_game:
    LDR R0, =lose_msg
    BL  printf
    B   end_program

end_program:
    @ --- CLEAN EXIT ---
    MOV R0, #0      @ Return code 0 (Success).
    @ POP {PC}: Pops the saved LR directly into the Program Counter.
    @ This causes the CPU to jump back to the OS instruction that called 'main'.
    POP {R4-R8, PC} 

@ ATTRIBUTES SECTION (Nadine)

Init_Stats:
@    PUSH    {R4, R5, LR}
    @ !!! IMPORTANT FIX: REMOVED R4 AND R5 FROM POP !!!
    @ IF WE POP R4/R5 HERE, WE OVERWRITE THE 100 WE JUST SET WITH OLD DATA.
    @ TO MAKE HEALTH "STICK", WE ONLY PUSH/POP THE LINK REGISTER (LR).
    PUSH    {LR}
    MOV     R4, #100    @ Current HP
    MOV     R5, #100    @ Max HP limit
	POP     {PC}        @ Return to main with R4/R5 intact.
@   POP     {R4, R5, LR} @ !!! CHANGED: THIS WIPES DATA, RECOMEND REMOVING R4,R5 FROM POP !!!
@   BX      LR          @ BX LR: Branch Exchange to the address in the Link Register.

Apply_Hazard:
    PUSH    {R4, R5, LR} 
    MOV     R2, R0       @ R0 is volatile; move damage amount to R2 for safekeeping.
    SUB     R4, R4, R0   @ Arithmetic: Health = Health - Damage.
	
    @ --- CLAMPING (Hard Limits) ---
    CMP     R4, #0      
    BGE     ah_no_clamp  @ BGE: Branch if Greater or Equal (checks N and V flags).
    MOV     R4, #0       @ If negative, overwrite R4 with 0.
	
ah_no_clamp:
    LDR     R0, =fmt_damage     
    MOV     R1, R2       @ Move saved damage to R1 for printf display.
    BL      printf
    POP     {R4, R5, LR} @ !!! CHANGED: REMOVED ONE REGISTER FROM POP TO MATCH PUSH AND PREVENT CRASH !!!
    BX      LR

Apply_Refill:
    PUSH    {R4, R5, LR} @ !!! CHANGED: PUSHED LR TO MATCH THE POP AT END !!!
    MOV     R2, R0
    ADD     R4, R4, R0

    @ --- OVERFLOW PREVENTION ---
    CMP     R4, R5       @ Compare new health to Max Health (100).
    BLE     ar_no_clamp  @ BLE: Branch if Less or Equal.
    MOV     R4, R5       @ Cap health at the value in R5.
     
ar_no_clamp:
    LDR     R0, =fmt_heal
    MOV     R1, R2
    BL      printf
    POP     {R4, R5, LR} @ !!! CHANGED: BALANCED THE STACK TO PREVENT SEGFAULT !!!
    BX      LR

Print_Status:
    PUSH    {R4, R5, LR}
    LDR     R0, =fmt_health
    MOV     R1, R4
    BL      printf
    POP     {R4, R5, LR} @ !!! CHANGED: BALANCED STACK SO PRINT DOES NOT CRASH !!!
    BX      LR

Check_Death:
    @ Logic: Returns a "boolean" (1 or 0) in R0.
    PUSH    {R4, R5, LR} 
    CMP     R4, #0       
    MOVLE   R0, #1       @ MOVLE: Conditional Move (Move if Less or Equal).
    MOVGT   R0, #0       @ MOVGT: Conditional Move (Move if Greater Than).
    POP     {R4, R5, LR}
    BX      LR


@ MOVEMENT SECTION (Ethan)

_input_handler:
    @ --- LIBC INPUT WRAPPER ---
    PUSH {lr}
    LDR r0, =format      @ Point to " %c"
    LDR r1, =input       @ Point to memory address for storage.
    BL  scanf            @ scanf(format, &input)
    LDR r0, =input       
    LDRB r0, [r0]        @ LDRB: Load Byte. Retrieves the ASCII value from memory.
    POP {pc} 
    
handle_input:
    PUSH {lr}
    BL _input_handler    @ Character now sits in R0.

    @ --- DISPATCHER TABLE (Pseudo-Switch) ---
    CMP r0, #'w'         @ Compare to ASCII hex for 'w'.
    BEQ _up
    CMP r0, #'a'
    BEQ _left
    CMP r0, #'s'
    BEQ _down
    CMP r0, #'d'
    BEQ _right
    CMP r0, #'i'         
    BEQ _inventory
    B   _end             @ Default case (Invalid input).
    
_inventory:
    @ --- MEMORY OFFSETTING ---
    PUSH {lr}
    LDR r0, =inv_title
    BL printf
    LDR r1, =inventory
    
    @ Check Index 0 (Sword)
    LDR r2, [r1]         @ Load word from base address.
    CMP r2, #1
    BNE _check_potion
    LDR r0, =inv_sword
    BL printf
	
_check_potion:
    @ Check Index 1 (Potion)
    LDR r2, [r1, #4]     @ Load word from address (Base + 4 bytes).
    CMP r2, #1
    BNE _check_key
    LDR r0, =inv_potion
    BL printf
	
_check_key:
    @ Check Index 2 (Key)
    LDR r2, [r1, #8]     @ Load word from address (Base + 8 bytes).
    CMP r2, #1
    BNE _check_empty
    LDR r0, =inv_key
    BL printf
	
    @ !!! IMPORTANT FIX: MODULAR RETURN !!!
    @ INSTEAD OF BRANCHING TO _END (WHICH HAS AN EXTRA POP), WE POP HERE.
    POP {lr}
    B _end
	
_check_empty:
    @ Summation logic: If R2+R3+R4 == 0, no items are present.
    @ !!! IMPORTANT FIX: CHANGED R4 TO R8 !!!
    @ R4 IS YOUR GLOBAL HEALTH REGISTER. IF YOU LOAD THE KEY INTO R4, 
    @ THE PLAYER'S HEALTH WILL BECOME '1' OR '0' IMMEDIATELY.
    LDR r2, [r1]
    LDR r3, [r1, #4]
    LDR r8, [r1, #8]     @ Use R8 instead of R4 to protect player health.
    ADD r2, r2, r3
    ADD r2, r2, r8       @ Sum with R8.
    
    CMP r2, #0
    BNE _inventory_done
    LDR r0, =inv_empty
    BL printf
	
_inventory_done:
    POP {lr}
    B _end
    
_up:
    @ --- BOUNDARY VALIDATION ---
    CMP r2, #4           @ Boundary: Coordinate Max.
    BGE _wall            @ BGE: Branch if Greater or Equal. Prevents going to Y=5.
    ADD r2, r2, #1       
    LDR r0, =go_up
    BL  printf
    B   _end
	
_left:
    CMP r3, #-4          @ Boundary: Coordinate Min.
    BLE _wall            @ BLE: Branch if Less or Equal. Prevents going to X=-5.
    SUB r3, r3, #1       
    LDR r0, =go_left
    BL  printf
    B   _end

	
_down:
    CMP r2, #-4
    BLE _wall
    SUB r2, r2, #1
    LDR r0, =go_down
    BL  printf
    B   _end
	
_right:
    CMP r3, #4
    BGE _wall
    ADD r3, r3, #1
    LDR r0, =go_right
    BL  printf
    B   _end
	
_wall:
    @ UI Feedback for out-of-bounds error.
    LDR r0, =wall_msg
    BL printf

_end:
    @ --- RETURN TO CALLER ---
    POP {pc}