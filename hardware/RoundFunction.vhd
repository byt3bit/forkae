----------------------------------------------------------------------------------
-- Copyright 2016:
--     Amir Moradi & Pascal Sasdrich for the SKINNY Team
--     https://sites.google.com/site/skinnycipher/
--
-- Copyright 2019 (for modifications):
--     Antoon Purnal for the ForkAE team
--     https://www.esat.kuleuven.be/cosic/forkae/
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License as
-- published by the Free Software Foundation; either version 2 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
-- General Public License for more details.
----------------------------------------------------------------------------------

-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE WORK.FORKSKINNYPKG.ALL;


-- Round function, fully combinational
ENTITY RoundFunction IS
	GENERIC (BS : BLOCK_SIZE; TS : TWEAK_SIZE);
	PORT ( CLK				: IN  STD_LOGIC;
			 -- CONTROL PORTS --------------------------------
			 CONST				: IN	STD_LOGIC_VECTOR(6 downto 0);
			 -- KEY PORT -------------------------------------
			 ROUND_KEY		: IN	STD_LOGIC_VECTOR((GET_TWEAK_SIZE(BS, TS) - 1) DOWNTO 0);
			 ROUND_IN		: IN	STD_LOGIC_VECTOR((GET_BLOCK_SIZE(BS) 	  - 1) DOWNTO 0);
			 ROUND_OUT		: OUT	STD_LOGIC_VECTOR((GET_BLOCK_SIZE(BS)	  - 1) DOWNTO 0));
END RoundFunction;



-- ARCHITECTURE : MIXED
----------------------------------------------------------------------------------
ARCHITECTURE Mixed OF RoundFunction IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT N : INTEGER := GET_BLOCK_SIZE(BS);
	CONSTANT T : INTEGER := GET_TWEAK_SIZE(BS, TS);
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);
	
	-- SIGNALS --------------------------------------------------------------------
	SIGNAL NEXT_STATE, KEY_ADDITION,
			 CONST_ADDITION, SUBSTITUTION, SHIFTROWS	: STD_LOGIC_VECTOR((N - 1) DOWNTO 0);

	-- MixColumns -----------------------------------------------------------------
	SIGNAL C1_X2X0, C2_X2X0, C3_X2X0, C4_X2X0	: STD_LOGIC_VECTOR((W - 1) DOWNTO 0);
	SIGNAL C1_X2X1, C2_X2X1, C3_X2X1, C4_X2X1	: STD_LOGIC_VECTOR((W - 1) DOWNTO 0);

BEGIN

	-- S-BOX ----------------------------------------------------------------------
	GEN : FOR I IN 0 TO 15 GENERATE
		S : ENTITY work.SBox GENERIC MAP (BS => BS) PORT MAP (ROUND_IN((W * (I + 1) - 1) DOWNTO (W * I)), SUBSTITUTION((W * (I + 1) - 1) DOWNTO (W * I)));
	END GENERATE;
	-------------------------------------------------------------------------------

	-- ADD CONSTANTS --------------------------------------------------------------
	N64 : IF BS = BLOCK_SIZE_64 GENERATE
		CONST_ADDITION(63 DOWNTO 60) <= SUBSTITUTION(63 DOWNTO 60) XOR CONST(3 DOWNTO 0);
		CONST_ADDITION(59 DOWNTO 54) <= SUBSTITUTION(59 DOWNTO 54);
        CONST_ADDITION(53) 	     	  <= NOT(SUBSTITUTION(53)); -- Bit to indicate tweakey material
		CONST_ADDITION(52 DOWNTO 47) <= SUBSTITUTION(52 DOWNTO 47);
		CONST_ADDITION(46 DOWNTO 44) <= SUBSTITUTION(46 DOWNTO 44) XOR CONST(6 DOWNTO 4);
		CONST_ADDITION(43 DOWNTO 30) <= SUBSTITUTION(43 DOWNTO 30);
        CONST_ADDITION(29) 	     	  <= NOT(SUBSTITUTION(29)); -- This is the XOR with c2 = 2
		CONST_ADDITION(28 DOWNTO  0) <= SUBSTITUTION(28 DOWNTO  0);
	END GENERATE;
	
	N128 : IF BS = BLOCK_SIZE_128 GENERATE
		CONST_ADDITION(127 DOWNTO 124) <= SUBSTITUTION(127 DOWNTO 124);
		CONST_ADDITION(123 DOWNTO 120) <= SUBSTITUTION(123 DOWNTO 120) XOR CONST(3 DOWNTO 0);
		CONST_ADDITION(119 DOWNTO  106) <= SUBSTITUTION(119 DOWNTO  106);
        CONST_ADDITION(105) 	     	  <= NOT(SUBSTITUTION(105)); -- Bit to indicate tweakey material
		CONST_ADDITION(104 DOWNTO  91) <= SUBSTITUTION(104 DOWNTO  91);
		CONST_ADDITION( 90 DOWNTO  88) <= SUBSTITUTION( 90 DOWNTO  88) XOR CONST(6 DOWNTO 4);
		CONST_ADDITION( 87 DOWNTO  58) <= SUBSTITUTION( 87 DOWNTO  58);
		CONST_ADDITION(57) 	    	    <= NOT(SUBSTITUTION(57)); -- This is the XOR with c2 = 2
		CONST_ADDITION( 56 DOWNTO   0) <= SUBSTITUTION( 56 DOWNTO   0);	
	END GENERATE;
	-------------------------------------------------------------------------------


	-- SUBKEY ADDITION ------------------------------------------------------------
	T2N : IF TS = TWEAK_SIZE_2N GENERATE
		KEY_ADDITION((16 * W - 1) DOWNTO (12 * W)) <= CONST_ADDITION((16 * W - 1) DOWNTO (12 * W)) XOR ROUND_KEY((1 * N + 16 * W - 1) DOWNTO (1 * N + 12 * W)) XOR ROUND_KEY((16 * W - 1) DOWNTO (12 * W));
		KEY_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) <= CONST_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) XOR ROUND_KEY((1 * N + 12 * W - 1) DOWNTO (1 * N +  8 * W)) XOR ROUND_KEY((12 * W - 1) DOWNTO ( 8 * W));	
	END GENERATE;

    T3o2N: if TS = TWEAK_SIZE_3o2N generate
        -- ROUND_KEY = [TK1 & TK2], where TK1 is 191 downto 64; TK2 is 63 downto 0
        -- The TK2 part will be zeroed out for odd rounds (this happens in ForkSkinnyRB.vhd)
		KEY_ADDITION((16 * W - 1) DOWNTO (12 * W)) <= CONST_ADDITION((16 * W - 1) DOWNTO (12 * W)) XOR ROUND_KEY((1 * N + 8 * W - 1) DOWNTO (1 * N + 4 * W)) XOR ROUND_KEY((8 * W - 1) DOWNTO (4 * W));
		KEY_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) <= CONST_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) XOR ROUND_KEY((1 * N + 4 * W - 1) DOWNTO (1 * N +  0 * W)) XOR ROUND_KEY((4 * W - 1) DOWNTO ( 0 * W));	
    end generate;


    T9o4N: if TS = TWEAK_SIZE_9o4N generate
        -- ROUND_KEY = [TK1 & TK2 & TK3], where TK1 is 319 downto 192; TK2 is 191 downto 64; TK3 is 63 downto 0
        -- The TK3 part will be zeroed out for odd rounds (this happens in ForkSkinnyRB.vhd)
		KEY_ADDITION((16 * W - 1) DOWNTO (12 * W)) <= CONST_ADDITION((16 * W - 1) DOWNTO (12 * W)) XOR ROUND_KEY((2 * N + 8 * W - 1) DOWNTO (2 * N + 4 * W)) XOR ROUND_KEY((1 * N + 8 * W - 1) DOWNTO (1 * N + 4 * W)) XOR ROUND_KEY((8 * W - 1) DOWNTO (4 * W));
		KEY_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) <= CONST_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) XOR ROUND_KEY((2 * N + 4 * W - 1) DOWNTO (2 * N + 0 * W)) XOR ROUND_KEY((1 * N + 4 * W - 1) DOWNTO (1 * N +  0 * W)) XOR ROUND_KEY((4 * W - 1) DOWNTO ( 0 * W));	
    end generate;

	
	T3N : IF TS = TWEAK_SIZE_3N GENERATE 
		KEY_ADDITION((16 * W - 1) DOWNTO (12 * W)) <= CONST_ADDITION((16 * W - 1) DOWNTO (12 * W)) XOR ROUND_KEY((2 * N + 16 * W - 1) DOWNTO (2 * N + 12 * W)) XOR ROUND_KEY((1 * N + 16 * W - 1) DOWNTO (1 * N + 12 * W)) XOR ROUND_KEY((16 * W - 1) DOWNTO (12 * W));
		KEY_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) <= CONST_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) XOR ROUND_KEY((2 * N + 12 * W - 1) DOWNTO (2 * N +  8 * W)) XOR ROUND_KEY((1 * N + 12 * W - 1) DOWNTO (1 * N +  8 * W)) XOR ROUND_KEY((12 * W - 1) DOWNTO ( 8 * W));	
	END GENERATE;
	
	KEY_ADDITION(( 8 * W - 1) DOWNTO ( 4 * W)) <= CONST_ADDITION(( 8 * W - 1) DOWNTO ( 4 * W));
	KEY_ADDITION(( 4 * W - 1) DOWNTO ( 0 * W)) <= CONST_ADDITION(( 4 * W - 1) DOWNTO ( 0 * W));
	-------------------------------------------------------------------------------
	
	-- SHIFT ROWS -----------------------------------------------------------------
	SHIFTROWS((16 * W - 1) DOWNTO (12 * W)) <= KEY_ADDITION((16 * W - 1) DOWNTO (12 * W));
	SHIFTROWS((12 * W - 1) DOWNTO ( 8 * W)) <= KEY_ADDITION(( 9 * W - 1) DOWNTO ( 8 * W)) & KEY_ADDITION((12 * W - 1) DOWNTO ( 9 * W));
	SHIFTROWS(( 8 * W - 1) DOWNTO ( 4 * W)) <= KEY_ADDITION(( 6 * W - 1) DOWNTO ( 4 * W)) & KEY_ADDITION(( 8 * W - 1) DOWNTO ( 6 * W));
	SHIFTROWS(( 4 * W - 1) DOWNTO ( 0 * W)) <= KEY_ADDITION(( 3 * W - 1) DOWNTO ( 0 * W)) & KEY_ADDITION(( 4 * W - 1) DOWNTO ( 3 * W));
	-------------------------------------------------------------------------------


    -- MIX COLUMNS ----------------------------------------------------------------

	-- X2 XOR X1 
	C1_X2X1 <= SHIFTROWS((12 * W - 1) DOWNTO (11 * W)) XOR SHIFTROWS(( 8 * W - 1) DOWNTO ( 7 * W));
	C2_X2X1 <= SHIFTROWS((11 * W - 1) DOWNTO (10 * W)) XOR SHIFTROWS(( 7 * W - 1) DOWNTO ( 6 * W));
	C3_X2X1 <= SHIFTROWS((10 * W - 1) DOWNTO ( 9 * W)) XOR SHIFTROWS(( 6 * W - 1) DOWNTO ( 5 * W));
	C4_X2X1 <= SHIFTROWS(( 9 * W - 1) DOWNTO ( 8 * W)) XOR SHIFTROWS(( 5 * W - 1) DOWNTO ( 4 * W));

	-- X2 XOR X0 
	C1_X2X0 <= SHIFTROWS((16 * W - 1) DOWNTO (15 * W)) XOR SHIFTROWS(( 8 * W - 1) DOWNTO ( 7 * W));
	C2_X2X0 <= SHIFTROWS((15 * W - 1) DOWNTO (14 * W)) XOR SHIFTROWS(( 7 * W - 1) DOWNTO ( 6 * W));
	C3_X2X0 <= SHIFTROWS((14 * W - 1) DOWNTO (13 * W)) XOR SHIFTROWS(( 6 * W - 1) DOWNTO ( 5 * W));
	C4_X2X0 <= SHIFTROWS((13 * W - 1) DOWNTO (12 * W)) XOR SHIFTROWS(( 5 * W - 1) DOWNTO ( 4 * W));
	
	-- COLUMN 1
	NEXT_STATE((16 * W - 1) DOWNTO (15 * W)) <= C1_X2X0 XOR SHIFTROWS(( 4 * W - 1) DOWNTO ( 3 * W));
	NEXT_STATE((12 * W - 1) DOWNTO (11 * W)) <= SHIFTROWS((16 * W - 1) DOWNTO (15 * W));
	NEXT_STATE(( 8 * W - 1) DOWNTO ( 7 * W)) <= C1_X2X1;
	NEXT_STATE(( 4 * W - 1) DOWNTO ( 3 * W)) <= C1_X2X0;

	-- COLUMN 2
	NEXT_STATE((15 * W - 1) DOWNTO (14 * W)) <= C2_X2X0 XOR SHIFTROWS(( 3 * W - 1) DOWNTO ( 2 * W));
	NEXT_STATE((11 * W - 1) DOWNTO (10 * W)) <= SHIFTROWS((15 * W - 1) DOWNTO (14 * W));
	NEXT_STATE(( 7 * W - 1) DOWNTO ( 6 * W)) <= C2_X2X1;
	NEXT_STATE(( 3 * W - 1) DOWNTO ( 2 * W)) <= C2_X2X0;
	
	-- COLUMN 3
	NEXT_STATE((14 * W - 1) DOWNTO (13 * W)) <= C3_X2X0 XOR SHIFTROWS(( 2 * W - 1) DOWNTO ( 1 * W));
	NEXT_STATE((10 * W - 1) DOWNTO ( 9 * W)) <= SHIFTROWS((14 * W - 1) DOWNTO (13 * W));
	NEXT_STATE(( 6 * W - 1) DOWNTO ( 5 * W)) <= C3_X2X1;
	NEXT_STATE(( 2 * W - 1) DOWNTO ( 1 * W)) <= C3_X2X0;
	
	-- COLUMN 4
	NEXT_STATE((13 * W - 1) DOWNTO (12 * W)) <= C4_X2X0 XOR SHIFTROWS(( 1 * W - 1) DOWNTO ( 0 * W));
	NEXT_STATE(( 9 * W - 1) DOWNTO ( 8 * W)) <= SHIFTROWS((13 * W - 1) DOWNTO (12 * W));
	NEXT_STATE(( 5 * W - 1) DOWNTO ( 4 * W)) <= C4_X2X1;
	NEXT_STATE(( 1 * W - 1) DOWNTO ( 0 * W)) <= C4_X2X0;
	-------------------------------------------------------------------------------
	
	-- ROUND OUTPUT ---------------------------------------------------------------
	ROUND_OUT <= NEXT_STATE;
	-------------------------------------------------------------------------------
	
END Mixed;

