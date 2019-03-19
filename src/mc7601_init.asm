// Init processor

// Magic code value
const MAGIC_CODE_VAL = 6901h;

const PSWR_SET   = 0;
const PSWR_RESET = 0;

extern int_start_prog: label;
extern ARM_HP_int_handler: label;

global start: label;

begin ".text_init"

// Start + 0h
<start>
	skip init;

// Start + 4h
PlaceForIntVecInt: word[80h - 4h]; // Place for internal interrupts vectors

// Start + 80h
	pswr clear 0_0000_01E0h;         // 0, 1 - Запрещение прерываний
	push ar5, gr5;                   // 2    - ar5 - callee saved
	gr5 = pc;                        // 3    - Сохранение номера прерывания
	delayed goto ARM_HP_int_handler; // 4, 5 - Отлож. переход на обработчик
	push gr6;                        // 6    - gr6 - Иногда callee saved
	push gr7;                        // 7    - gr7 - callee saved

// Start + 88h
PlaceForIntVecExt: word[100h - 88h]; // Place for external interrupts vectors

// Loader syncro words
To_ARM:        word = 0; // Start + 100h
From_ARM:      word = 0; // Start + 101h

// User program entry point
User_program:  word = 0; // Start + 102h

// User program return value
Return_value:  word = 0; // Start + 103h

// Syncro blocks for syncro functions
Sync_to_ARM:   word[4];  // Start + 104h
Sync_from_ARM: word[4];  // Start + 108h

// Interrupt status
HP_int_send:   word = 0; // Start + 10Ch
LP_int_send:   word = 0; // Start + 10Dh

// ISR syncro words
ISR_to_ARM:    word = 0; // Start + 10Eh
ISR_from_ARM:  word = 0; // Start + 10Fh

// User HP interrupt ISR entry point
User_ISR:      word = 0; // Start + 110h

// Magic code
Magic_code:    word = 0; // Start + 111h

// NMI hardware vector opcodes
NMI_hard_vect: word[8];  // Start + 112h

__init_INTR_CLEAR: label;
<init>
	// All inits must be HERE

	pswr set PSWR_SET;
	pswr clear PSWR_RESET;

	// Запрещение и сброс внешних прерываний
	intr_mask = -1; // Запрещение
.wait;
	intr_req clear 0FFFFh; // Сброс запросов 
	pc = __init_INTR_CLEAR; // Очистка конвейера по Косорукову
	vnul;	
	vnul;	
<__init_INTR_CLEAR>
	intr clear 3C0h; // Сброс запросов 2

	// Сохранение системного аппаратного вектора NMI
	ar0 = start;
	ar1 = NMI_hard_vect;
.repeat 8;
	gr7 = [ar0++];
	[ar1++] = gr7;
.endrepeat;

	// Размаскирование HPINT
	gr7 = 0_0000_0040h;
	pswr set gr7;
	gr7 = intr_mask;
	gr1 = 0_0000_0001h;
	gr7 = gr7 and not gr1;
	intr_mask = gr7;

	// Установка Magic code
	gr7 = MAGIC_CODE_VAL;
	[Magic_code] = gr7;

	goto int_start_prog;

end ".text_init";
