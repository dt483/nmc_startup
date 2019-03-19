// Main loop and ARM HPINT handler

const DEBUG = 0;

import from mc7601_def.mlb;

global int_start_prog: label;
global ARM_HP_int_handler: label;

NMC_DEF(); // Define constants for loader and sync functions

nobits ".bss"

LoaderStack: long[20];

end ".bss";

begin ".text"

//----------------------------------------------------------------------------//
// ARM HPINT handler                                                          //
//----------------------------------------------------------------------------//

<ARM_HP_int_handler>

	push gr4, ar4;
	push gr5, ar5;
	push gr6, ar6;

<ISR_main_loop>

	gr7 = ISR_READY_FOR_COMMAND;
	[ISR_TO_ARM] = gr7;

	gr7 = ISR_ALL_COMMAND;

	gr4 = false;
	gr5 = false;
	gr6 = false;

<ISR_wait_command>

//-Debug begin------------------------------------------------------------------
.if DEBUG;
	push gr2;
	push gr3;

	// Second LED off
	gr3 = nmscu;
	gr2 = 40h;
	gr3 = gr3 or gr2;
	nmscu = gr3;

	gr2 = 200000h;
<Second_LED_off_loop>
	gr2--;
	if > skip Second_LED_off_loop;

	// Second LED on
	gr3 = nmscu;
	gr2 = 40h;
	gr3 = gr3 and not gr2;
	nmscu = gr3;

	gr2 = 200000h;
<Second_LED_on_loop>
	gr2--;
	if > skip Second_LED_on_loop;

	pop gr3;
	pop gr2;
.endif;
//-Debug end--------------------------------------------------------------------

	gr4 = gr4 + gr5;
	gr5 = gr6 + gr5;
	gr4 = gr4 + gr5;
	gr5 = gr6 + gr5;

	gr4 = [ISR_FROM_ARM];
	with gr4 = gr4 and gr7;
	if =0 skip ISR_wait_command;

	// ��������� �������

	gr7 = false;
	[ISR_FROM_ARM] = gr7;

	gr7 = ISR_NULL_OPERATION;
	with gr7 = gr4 xor gr7;
	if =0 skip ISR_null_operation;

	gr7 = ISR_CALL_USER_ISR;
	with gr7 = gr4 xor gr7;
	if =0 skip ISR_call_user_ISR;

	gr7 = ISR_FINISH;
	with gr7 = gr4 xor gr7;
	if =0 skip Finish;

	skip ISR_main_loop;

//----------------------------------------------------------------------------//
// Null operation                                                             //
//----------------------------------------------------------------------------//

<ISR_null_operation>
	skip ISR_main_loop;

//----------------------------------------------------------------------------//
// Call user ISR                                                              //
//----------------------------------------------------------------------------//

<ISR_call_user_ISR>

	gr7 = [LIBINT_INT_MANAGER_ADDR];
	with gr7;
	if =0 skip Finish;

	pop gr6, ar6;
	pop gr5, ar5;
	pop gr4, ar4;

	goto gr7;

//----------------------------------------------------------------------------//
// Finish                                                                     //
//----------------------------------------------------------------------------//

<Finish>

	pop gr6, ar6;
	pop gr5, ar5;
	pop gr4, ar4;

.align;
	pop gr7; // push'� � �������
	pop gr6;
	pop ar5, gr5;
	ireturn;

//==============================================================================

<int_start_prog>

	ar7 = LoaderStack;

	// Размаскирование HPINT
	gr7 = 0_0000_0040h;
	pswr set gr7;
	gr7 = intr_mask;
	gr1 = 0_0000_0001h;
	gr7 = gr7 and not gr1;
	intr_mask = gr7;

	

//----------------------------------------------------------------------------//
// Main loop:                                                                 //
// - Wait command                                                             //
// - Execute command                                                          //
//----------------------------------------------------------------------------//

<Main_loop>

	gr4 = false;
	gr5 = false;
	gr6 = false;

	// �������� ���������� ������� ����������
// <Wait_HP_int_free>
// 	gr4 = gr4 + gr5;
// 	gr5 = gr6 + gr5;
// 	gr4 = gr4 + gr5;
// 	gr5 = gr6 + gr5;
// 	gr7 = [HP_INT_SEND];
// 	with gr7;
// 	if <>0 skip Wait_HP_int_free;

	// ��������� ������� ���������� � ����� �������
	gr7 = READY_FOR_COMMAND;
	[TO_ARM] = gr7;

	// ������� HPINT
//	gr7 = 1;
//	[HP_INT_SEND] = gr7;
//	gr7 = nmscu;
//	gr1 = 4h;
//	gr7 = gr7 or gr1;
//	nmscu = gr7;

	gr7 = ANY_COMMAND;

	// �������� �������

<Wait_command>

//-Debug begin------------------------------------------------------------------
.if DEBUG;
	// First LED off
	gr3 = nmscu;
	gr2 = 20h;
	gr3 = gr3 or gr2;
	nmscu = gr3;

	gr2 = 200000h;
<First_LED_off_loop>
	gr2--;
	if > skip First_LED_off_loop;

	// First LED on
	gr3 = nmscu;
	gr2 = 20h;
	gr3 = gr3 and not gr2;
	nmscu = gr3;

	gr2 = 200000h;
<First_LED_on_loop>
	gr2--;
	if > skip First_LED_on_loop;
.endif;
//-Debug end--------------------------------------------------------------------

	//wait
	gr4 = gr4 + gr5;
	gr5 = gr6 + gr5;
	gr4 = gr4 + gr5;
	gr5 = gr6 + gr5; 

	gr4 = [FROM_ARM];
	with gr4 = gr4 and gr7;
	if =0 skip Wait_command;

	// ��������� �������

	gr7 = false;
	[FROM_ARM] = gr7;

//	gr7 = NULL_OPERATION;
//	with gr7 = gr4 xor gr7;
//	if =0 skip Null_operation;
//
//	gr7 = RUN_PROGRAM;
//	with gr7 = gr4 xor gr7;
//	if =0 skip Run_program;

    gr1 = RUN_PROGRAM;
    with gr1 = gr4 and gr1;
    if <>0 skip Run_program;

	skip Main_loop;

        //------------------
        // End of Main Loop.
        //------------------
//----------------------------------------------------------------------------//
// Null operation                                                             //
//----------------------------------------------------------------------------//
//
//<Null_operation>
//	skip Main_loop;
//



//----------------------------------------------------------------------------//
// Run program                                                                //
//----------------------------------------------------------------------------//

<Run_program>

        // ����� ����� ���������������� ���������
//	ar4 = [USER_PROGRAM];


	// Mark running program.
	// Ending program is marked by READY_FOR_COMMAND
	gr0 = PROGRAM_STOPPED;
	[TO_ARM] = gr0;

   // Original Address of program entry point.
    ar4 = [SYNC_FROM_ARM + offset( SyncroBlock, array_addr )];

	// ����� ���������������� ���������
	call ar4;

	goto int_start_prog;



end ".text";
