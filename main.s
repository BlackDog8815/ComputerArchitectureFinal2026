@ CmpE 3780 Final Project: The Dungeon Crawl
@ Team Members:
@ Spencer Wilkins
@ Ethan 
@ Nadine 
@ Description:
@   Text-based dungeon survival game written in ARM Assembly.
@   The player navigates through rooms, survives encounters,
@   manages health, and attempts to reach the dungeon exit.

.data

@ TITLE SCREEN STRINGS---------
title_line1: .asciz "\n****************************************\n"
title_line2: .asciz "*        THE PLATTEVILLE CRAWL         *\n"
title_line3: .asciz "*   By: Spencer, Ethan, and Nadine     *\n"
title_line4: .asciz "*      CmpE 3780 - Spring 2026         *\n"
title_line5: .asciz "****************************************\n\n"

start_msg:
.asciz "Game Loading... Please wait.\n"

ready_msg:
.asciz "Your journey begins now!\n\n"

win_msg:
.asciz "\nCongratulations! You escaped the dungeon!\n"

lose_msg:
.asciz "\nYou have died in the dungeon.\n"

.text
.global main
.extern printf
.extern sleep

@ MAIN PROGRAM----------
main:

    @ Save callee-saved registers and return address
    PUSH {R4-R8, LR}
    
    @ 1. DISPLAY TITLE SCREEN
    @ Print decorative border
    LDR R0, =title_line1
    BL  printf
    @ Print game title
    LDR R0, =title_line2
    BL  printf
    @ Print author names
    LDR R0, =title_line3
    BL  printf
    @ Print course information
    LDR R0, =title_line4
    BL  printf
    @ Print bottom border
    LDR R0, =title_line5
    BL  printf
    @ Print loading message
    LDR R0, =start_msg
    BL  printf
	
    @ 2. TIME DELAY
    @ Required by project specifications
    @ sleep(3)
    @ Delays execution for 3 seconds before game starts
    MOV R0, #3
    BL  sleep

    @ Print game start message
    LDR R0, =ready_msg
    BL  printf
    
    @ 3. INITIALIZE GAME STATE VARIABLES
    @ Register Usage Convention
    @ R4 = Player X-coordinate
    @ R5 = Player Y-coordinate
    @ R6 = Player Health
    @ R7 = Reserved for future game state usage
	
    @ Initialize player X position
    MOV R4, #0

    @ Initialize player Y position
    MOV R5, #0

    @ Initialize player health
    MOV R6, #100

@ MAIN GAME LOOP-------
game_loop:

    @ ETHAN'S SECTION
    @ Movement / Map Logic
    
    @ Inputs:
    @   R0 = Current X-coordinate
    @   R1 = Current Y-coordinate
    @
    @ Expected Outputs:
    @   R0 = Updated X-coordinate
    @   R1 = Updated Y-coordinate
    

    MOV R0, R4
    MOV R1, R5

    BL  movement_subroutine

    @ Save updated coordinates
    MOV R4, R0
    MOV R5, R1
    
    @ NADINE'S SECTION
    @ Health / Attributes / Damage System
    
    @ Input:
    @   R0 = Current Health
    @
    @ Expected Output:
    @   R0 = Updated Health
    
    MOV R0, R6

    BL  attribute_subroutine

    @ Save updated health
    MOV R6, R0
    
    @ 4. CHECK LOSE CONDITION
    
    @ If health <= 0, player loses
    CMP R6, #0
    BLE lose_game

    @ 5. CHECK WIN CONDITION
    
    @ Example win condition:
    @ Reach coordinates (4,4)
    
    CMP R4, #4
    BNE continue_game

    CMP R5, #4
    BEQ win_game

continue_game:

    @ Repeat game loop
    B game_loop

@ WIN CONDITION---------

win_game:

    LDR R0, =win_msg
    BL  printf
    B end_program

@ LOSE CONDITION---------

lose_game:

    LDR R0, =lose_msg
    BL  printf

    B end_program

@ END PROGRAM---------

end_program:

    @ Return 0 to operating system
    MOV R0, #0

    @ Restore saved registers and return
    POP {R4-R8, PC}