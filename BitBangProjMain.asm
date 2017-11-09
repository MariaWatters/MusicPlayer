/******************************************************************************
* EE244 Bit Banging Project Part Three
* Description - This project plays a song using bit banging by forcing a delay
* for the duration of a note and uses PWM to drive a speaker on the port of the
* MCU K22F.
* Maria Watters, 3/10/2017
******************************************************************************/
                .syntax unified
                .cpu cortex-m4
                .fpu fpv4-sp-d16
                .globl main

				/*Equates for initialization of Clock and Port D*/
				.equ SIM_SCGC5, 0x40048038
				.equ SIM_PORTD, 0x00001000
				.equ PORTD_PCR2, 0x4004C008
				.equ PORTD_GPIO, 0x00000100
				.equ GPIOD_PDDR, 0x400FF0D4
				.equ PORTD_OUTPUT, 0x00000004
				.equ GPIOD_PDOR, 0x400FF0C0

				/*Equates for notes*/
				.equ C_3, 0x15236
				.equ CS_3, 0x13F3B
				.equ D_3, 0x12D51
				.equ DS_3, 0x11C67
				.equ E_3, 0x10C71
				.equ F_3, 0x0FD5D
				.equ FS_3, 0x0EF24
				.equ G_3, 0x0E1BA
				.equ GS_3, 0x0D50D
				.equ A_3, 0x0C918
				.equ AS_3, 0x0BDCF
				.equ B_3, 0x0A919
				.equ C_4, 0x09F9C
				.equ CS_4, 0x08E30
				.equ D_4, 0x08635
				.equ DS_4, 0x07EAD
				.equ E_4, 0x07790
				.equ F_4, 0x070DB
				.equ FS_4, 0x06A85
				.equ G_4, 0x0648A
				.equ GS_4, 0x05EE5
				.equ A_4, 0x05992
				.equ AS_4, 0x0548A
				.equ B_4, 0x04FCB
				.equ C_5, 0x04B51
				.equ CS_5, 0x04717
				.equ D_5, 0x04319
				.equ DS_5, 0x03F54
				.equ E_5, 0x03BC6
				.equ F_5, 0x0386B
				.equ FS_5, 0x03540
				.equ G_5, 0x03BC6
				.equ GS_5, 0x0386B
				.equ A_5, 0x03540
				.equ AS_5, 0x03243
				.equ B_5, 0x02F71
				.equ C_6, 0x02CC7
				.equ REST, 0x0000

				/*Rhythm equates*/
				.equ WHOLE_NOTE, 0x16E35FC
				.equ HALF_NOTE, 0x0B71AFC
				.equ QUARTER_NOTE, 0x05B8D7C
				.equ EIGHTH_NOTE, 0x02DC6BC
				.equ SIXTEENTH_NOTE, 0x016E35C

				/*Articulation equates*/
				.equ ARTICULATE, 0x005B8D4
				.equ NONE, 0x0

				/*Bit Manipulation Equates*/
				.equ ON, 0x4
				.equ OFF, 0x0
				.equ END, 0x7FFF

                .section .text
main:
				bl IOShieldInit
				ldr r12, =Song			/*Load first note into the program*/
				ldr r11, =REST
				ldr r10, =END 			/*Marks the end of the song has been reached*/
				ldr r9, =ARTICULATE
note:
				ldr r4, [r12], #4		/*Get next note in the song*/

				cmp r4, r10				/*If song is finished, restart*/
				beq main
rhythm:
				ldr r5, [r12], #4		/*Get the articulation of the rhythm*/
				ldr r6, [r12], #4		/*Get the length of the rhythm of the note/rest*/

				cmp r5, r9				/*Is the note articulated?*/
				ittt eq					/*If it is, take a quick delay into account*/
				subeq r6, r5
				udiveq r6, r4
				beq articulate

				cmp r4, r11				/*Is the note a rest?*/
				itt ne					/*If it is not, do not delay note*/
				udivne r6, r4
				bne tone

rest:
				mov r0, r6				/*Passes length of rest to delay subroutine*/
				bl Hold					/*If is, rest*/

				b note

tone:
				mov r0, r4				/*Pass the cycles a frequency completes to Hold*/
				ldr r1, =GPIOD_PDOR
				ldr r2, =ON
				str r2, [r1]			/*On duration of squarewave set to speaker*/
				bl Hold

				mov r0, r4				/*Pass the cycles a frequency completes to Hold*/
				ldr r1, =GPIOD_PDOR
				ldr r2, =OFF
				str r2, [r1]			/*Off duration of squarewave set to speaker*/
				bl Hold

				subs r6, #1				/*Has note length been reached?*/
				bne tone					/*If no, keep playing sound */

                b note					/*If yes, go to next note */
articulate:
				mov r0, r5
				bl Hold
				b tone
/******************************************************************************************
* void IOShieldInit(void) - Initializes the Clock and Port D for use.
*
*Params: none
*Returns: none
*MCU: K22F
*Maria Watters 3/8/2017
******************************************************************************************/
IOShieldInit: 								/*Initialize ports for use*/
				push {lr}
				ldr r0, =SIM_SCGC5			/*Clock configuration*/
				ldr r1, =SIM_PORTD
			 	str r1, [r0]
				ldr r0, =PORTD_PCR2			/*Port D GPIO config via mux*/
				ldr r1, =PORTD_GPIO
				str r1, [r0]
				ldr r0, =GPIOD_PDDR 		/*output configuration*/
				ldr r1, =PORTD_OUTPUT
				str r1, [r0]
				pop {pc}
/******************************************************************************************
* void Hold(INT32U s) - This delay subroutine is passed three possible time durations and
* cycles through a delay loop until the rest is over.
*
*Params: unsigned 32 bits
*Returns: none
*MCU: K22F
*Maria Watters 3/9/2017
******************************************************************************************/
Hold:
				push {lr}
delay:			cmp r0, #0
				itt ne
				subne r0, #1
				bne delay
				pop {pc}

                .section .rodata
	Song:		.word REST, NONE, WHOLE_NOTE, A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, A_4, ARTICULATE, QUARTER_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, EIGHTH_NOTE
				.word G_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, A_4, ARTICULATE, QUARTER_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, EIGHTH_NOTE
				.word G_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, A_4, ARTICULATE, QUARTER_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, EIGHTH_NOTE
				.word G_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, A_4, ARTICULATE, QUARTER_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, EIGHTH_NOTE
				.word G_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, REST, NONE, EIGHTH_NOTE
				.word E_3, ARTICULATE, EIGHTH_NOTE, G_3, ARTICULATE, SIXTEENTH_NOTE
				.word E_3, ARTICULATE, SIXTEENTH_NOTE, A_3, ARTICULATE, EIGHTH_NOTE
				.word REST, NONE, EIGHTH_NOTE, E_4, ARTICULATE, EIGHTH_NOTE
				.word G_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, REST, NONE, EIGHTH_NOTE
				.word E_5, ARTICULATE, EIGHTH_NOTE, G_5, ARTICULATE, SIXTEENTH_NOTE
				.word E_5, ARTICULATE, SIXTEENTH_NOTE, A_5, ARTICULATE, EIGHTH_NOTE
				.word REST, NONE, EIGHTH_NOTE, REST, NONE, QUARTER_NOTE
				.word E_5, ARTICULATE, QUARTER_NOTE, D_5, ARTICULATE, QUARTER_NOTE
				.word E_5, ARTICULATE, QUARTER_NOTE, E_5, NONE, EIGHTH_NOTE
				.word C_5, ARTICULATE, EIGHTH_NOTE, D_5, ARTICULATE, QUARTER_NOTE
				.word B_4, ARTICULATE, QUARTER_NOTE, E_5, ARTICULATE, HALF_NOTE
				.word C_5, ARTICULATE, QUARTER_NOTE, B_4, ARTICULATE, QUARTER_NOTE
				.word C_5, ARTICULATE, QUARTER_NOTE, C_5, NONE, EIGHTH_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, B_4, ARTICULATE, QUARTER_NOTE
				.word A_4, ARTICULATE, QUARTER_NOTE, C_5, ARTICULATE, HALF_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, A_4, ARTICULATE, QUARTER_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, EIGHTH_NOTE
				.word G_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, A_4, ARTICULATE, QUARTER_NOTE
				.word A_4, ARTICULATE, EIGHTH_NOTE, C_5, ARTICULATE, SIXTEENTH_NOTE
				.word A_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, EIGHTH_NOTE
				.word G_4, ARTICULATE, SIXTEENTH_NOTE, E_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_3, ARTICULATE, EIGHTH_NOTE, C_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_3, ARTICULATE, SIXTEENTH_NOTE, A_3, ARTICULATE, QUARTER_NOTE
				.word A_3, ARTICULATE, EIGHTH_NOTE, D_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_3, ARTICULATE, SIXTEENTH_NOTE, A_3, ARTICULATE, QUARTER_NOTE
				.word A_3, ARTICULATE, EIGHTH_NOTE, E_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_3, ARTICULATE, SIXTEENTH_NOTE, A_3, ARTICULATE, QUARTER_NOTE
				.word A_3, ARTICULATE, EIGHTH_NOTE, F_4, ARTICULATE, SIXTEENTH_NOTE
				.word A_3, ARTICULATE, SIXTEENTH_NOTE, A_3, ARTICULATE, QUARTER_NOTE
				.word A_4, ARTICULATE, QUARTER_NOTE, C_5, NONE, QUARTER_NOTE
				.word E_4, ARTICULATE, QUARTER_NOTE, E_4, NONE, EIGHTH_NOTE
				.word B_4, NONE, EIGHTH_NOTE, D_5, ARTICULATE, QUARTER_NOTE
				.word D_5, NONE, HALF_NOTE, D_5, NONE, QUARTER_NOTE
				.word A_4, ARTICULATE, QUARTER_NOTE, A_4, NONE, EIGHTH_NOTE
				.word D_5, NONE, SIXTEENTH_NOTE, C_5, NONE, SIXTEENTH_NOTE
				.word B_4, ARTICULATE, QUARTER_NOTE, C_5, NONE, QUARTER_NOTE
				.word A_4, ARTICULATE, WHOLE_NOTE, A_4, ARTICULATE, QUARTER_NOTE
				.word B_4, NONE, QUARTER_NOTE, A_4, ARTICULATE, QUARTER_NOTE
				.word A_4, NONE, EIGHTH_NOTE, D_5, NONE, EIGHTH_NOTE
				.word FS_5, ARTICULATE, QUARTER_NOTE, D_5, NONE, HALF_NOTE
				.word A_5, ARTICULATE, HALF_NOTE, A_5, NONE, EIGHTH_NOTE
				.word G_5, ARTICULATE, EIGHTH_NOTE, C_5, NONE, EIGHTH_NOTE
				.word F_5, NONE, EIGHTH_NOTE, D_5, ARTICULATE, HALF_NOTE
				.word D_5, ARTICULATE, HALF_NOTE, F_5, ARTICULATE, HALF_NOTE
				.word F_5, NONE, QUARTER_NOTE, E_5, ARTICULATE, QUARTER_NOTE
				.word E_4, ARTICULATE, EIGHTH_NOTE, E_4, NONE, SIXTEENTH_NOTE
				.word D_5, NONE, SIXTEENTH_NOTE, B_4, ARTICULATE, WHOLE_NOTE, END

                .section .bss
