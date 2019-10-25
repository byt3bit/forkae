----------------------------------------------------------------------------------
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

-- Inverse round function, fully combinational
ENTITY InverseRoundFunction IS	
	GENERIC (BS : BLOCK_SIZE; TS : TWEAK_SIZE);
	PORT ( CLK				: IN  STD_LOGIC;
			 -- CONTROL PORTS --------------------------------
			 CONST			: IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
			 -- KEY PORT -------------------------------------
			 ROUND_KEY		: IN	STD_LOGIC_VECTOR((GET_TWEAK_SIZE(BS, TS) - 1) DOWNTO 0);
			 ROUND_IN		: IN	STD_LOGIC_VECTOR((GET_BLOCK_SIZE(BS)	  - 1) DOWNTO 0);
			 ROUND_OUT		: OUT	STD_LOGIC_VECTOR((GET_BLOCK_SIZE(BS)	  - 1) DOWNTO 0));
END InverseRoundFunction;



-- ARCHITECTURE : MIXED
----------------------------------------------------------------------------------
ARCHITECTURE Mixed OF InverseRoundFunction IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT N : INTEGER := GET_BLOCK_SIZE(BS);
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL CONST_ADDITION, KEY_ADDITION, MIXCOLUMNS, SHIFTROWS	: STD_LOGIC_VECTOR((N - 1) DOWNTO 0); -- Intermediates
	SIGNAL C1_Y1Y3, C2_Y1Y3, C3_Y1Y3, C4_Y1Y3: STD_LOGIC_VECTOR((W - 1) DOWNTO 0);
	SIGNAL C1_Y0Y3, C2_Y0Y3, C3_Y0Y3, C4_Y0Y3: STD_LOGIC_VECTOR((W - 1) DOWNTO 0);

BEGIN

	-- INVERSE MIX COLUMNS ----------------------------------------------------------------

		-- Y0 XOR Y3 ---------------------------------------------------------------
		C1_Y0Y3 <= ROUND_IN((16 * W - 1) DOWNTO (15 * W)) XOR ROUND_IN(( 4 * W - 1) DOWNTO ( 3 * W));
		C2_Y0Y3 <= ROUND_IN((15 * W - 1) DOWNTO (14 * W)) XOR ROUND_IN(( 3 * W - 1) DOWNTO ( 2 * W));
		C3_Y0Y3 <= ROUND_IN((14 * W - 1) DOWNTO (13 * W)) XOR ROUND_IN(( 2 * W - 1) DOWNTO ( 1 * W));
		C4_Y0Y3 <= ROUND_IN((13 * W - 1) DOWNTO (12 * W)) XOR ROUND_IN(( 1 * W - 1) DOWNTO ( 0 * W));
		----------------------------------------------------------------------------

		-- Y1 XOR Y3 ---------------------------------------------------------------
		C1_Y1Y3 <= ROUND_IN((12 * W - 1) DOWNTO (11 * W)) XOR ROUND_IN(( 4 * W - 1) DOWNTO ( 3 * W));
		C2_Y1Y3 <= ROUND_IN((11 * W - 1) DOWNTO (10 * W)) XOR ROUND_IN(( 3 * W - 1) DOWNTO ( 2 * W));
		C3_Y1Y3 <= ROUND_IN((10 * W - 1) DOWNTO (9 * W)) XOR ROUND_IN(( 2 * W - 1) DOWNTO ( 1 * W));
		C4_Y1Y3 <= ROUND_IN((9 * W - 1) DOWNTO (8 * W)) XOR ROUND_IN(( 1 * W - 1) DOWNTO ( 0 * W));
		----------------------------------------------------------------------------
		
		-- COLUMN 1 ----------------------------------------------------------------
		MIXCOLUMNS((16 * W - 1) DOWNTO (15 * W)) <= ROUND_IN((12 * W - 1) DOWNTO (11 * W));
		MIXCOLUMNS((12 * W - 1) DOWNTO (11 * W)) <= C1_Y1Y3 XOR ROUND_IN(( 8 * W - 1) DOWNTO ( 7 * W));
		MIXCOLUMNS(( 8 * W - 1) DOWNTO ( 7 * W)) <= C1_Y1Y3;
		MIXCOLUMNS(( 4 * W - 1) DOWNTO ( 3 * W)) <= C1_Y0Y3;
		----------------------------------------------------------------------------

		-- COLUMN 2 ----------------------------------------------------------------
		MIXCOLUMNS((15 * W - 1) DOWNTO (14 * W)) <= ROUND_IN((11 * W - 1) DOWNTO (10 * W));
		MIXCOLUMNS((11 * W - 1) DOWNTO (10 * W)) <= C2_Y1Y3 XOR ROUND_IN(( 7 * W - 1) DOWNTO ( 6 * W));
		MIXCOLUMNS(( 7 * W - 1) DOWNTO ( 6 * W)) <= C2_Y1Y3;
		MIXCOLUMNS(( 3 * W - 1) DOWNTO ( 2 * W)) <= C2_Y0Y3;
		----------------------------------------------------------------------------
		
		-- COLUMN 3 ----------------------------------------------------------------
		MIXCOLUMNS((14 * W - 1) DOWNTO (13 * W)) <= ROUND_IN((10 * W - 1) DOWNTO (9 * W));
		MIXCOLUMNS((10 * W - 1) DOWNTO (9 * W)) <= C3_Y1Y3 XOR ROUND_IN(( 6 * W - 1) DOWNTO ( 5 * W));
		MIXCOLUMNS(( 6 * W - 1) DOWNTO ( 5 * W)) <= C3_Y1Y3;
		MIXCOLUMNS(( 2 * W - 1) DOWNTO ( 1 * W)) <= C3_Y0Y3;
		----------------------------------------------------------------------------

		-- COLUMN 4 ----------------------------------------------------------------
		MIXCOLUMNS((13 * W - 1) DOWNTO (12 * W)) <= ROUND_IN((9 * W - 1) DOWNTO (8 * W));
		MIXCOLUMNS((9 * W - 1) DOWNTO (8 * W)) <= C4_Y1Y3 XOR ROUND_IN(( 5 * W - 1) DOWNTO ( 4 * W));
		MIXCOLUMNS(( 5 * W - 1) DOWNTO ( 4 * W)) <= C4_Y1Y3;
		MIXCOLUMNS(( 1 * W - 1) DOWNTO ( 0 * W)) <= C4_Y0Y3;
		----------------------------------------------------------------------------

        -- INVERSE SHIFT ROWS -----------------------------------------------------------------
		-- ROW 1 --------------------------------------------------------------------
		-- No changes.
		SHIFTROWS((16 * W - 1) DOWNTO (12 * W)) <= MIXCOLUMNS((16 * W - 1) DOWNTO (12 * W));
		----------------------------------------------------------------------------
		
		-- ROW 2 -------------------------------------------------------------------
		-- Shift one cell to the LEFT.
		SHIFTROWS((12 * W - 1) DOWNTO ( 8 * W)) <= MIXCOLUMNS(( 11 * W - 1) DOWNTO ( 8 * W)) & MIXCOLUMNS((12 * W - 1) DOWNTO ( 11 * W));
		----------------------------------------------------------------------------
		
		-- ROW 3 -------------------------------------------------------------------
		-- Shift two cells to the LEFT.
		SHIFTROWS(( 8 * W - 1) DOWNTO ( 4 * W)) <= MIXCOLUMNS(( 6 * W - 1) DOWNTO ( 4 * W)) & MIXCOLUMNS(( 8 * W - 1) DOWNTO ( 6 * W));
		----------------------------------------------------------------------------
		
		-- ROW 4 -------------------------------------------------------------------
		-- Shift three cells to the LEFT.
		SHIFTROWS(( 4 * W - 1) DOWNTO ( 0 * W)) <= MIXCOLUMNS(( 1 * W - 1) DOWNTO ( 0 * W)) & MIXCOLUMNS(( 4 * W - 1) DOWNTO ( 1 * W));
		----------------------------------------------------------------------------
		
	-------------------------------------------------------------------------------

    -- INVERSE SUBKEY ADDITION ------------------------------------------------------------
    -- Note: identical to encryption.
    -- Add the round subkey to the top two rows. Depending on the tweakey size, XOR once twice or thrice.
	T2N : IF TS = TWEAK_SIZE_2N GENERATE
		KEY_ADDITION((16 * W - 1) DOWNTO (12 * W)) <= SHIFTROWS((16 * W - 1) DOWNTO (12 * W)) XOR ROUND_KEY((1 * N + 16 * W - 1) DOWNTO (1 * N + 12 * W)) XOR ROUND_KEY((16 * W - 1) DOWNTO (12 * W));
		KEY_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) <= SHIFTROWS((12 * W - 1) DOWNTO ( 8 * W)) XOR ROUND_KEY((1 * N + 12 * W - 1) DOWNTO (1 * N +  8 * W)) XOR ROUND_KEY((12 * W - 1) DOWNTO ( 8 * W));	
	END GENERATE;

    T3o2N: if TS = TWEAK_SIZE_3o2N generate
        -- ROUND_KEY = [TK1 & TK2], where TK1 is 191 downto 64; TK2 is 63 downto 0
        -- The TK2 part will be zeroed out for odd rounds (this happens in ForkSkinnyRB.vhd)
		KEY_ADDITION((16 * W - 1) DOWNTO (12 * W)) <= SHIFTROWS((16 * W - 1) DOWNTO (12 * W)) XOR ROUND_KEY((1 * N + 8 * W - 1) DOWNTO (1 * N + 4 * W)) XOR ROUND_KEY((8 * W - 1) DOWNTO (4 * W));
		KEY_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) <= SHIFTROWS((12 * W - 1) DOWNTO ( 8 * W)) XOR ROUND_KEY((1 * N + 4 * W - 1) DOWNTO (1 * N +  0 * W)) XOR ROUND_KEY((4 * W - 1) DOWNTO ( 0 * W));	
    end generate;

    T9o4N: if TS = TWEAK_SIZE_9o4N generate
        -- ROUND_KEY = [TK1 & TK2 & TK3], where TK1 is 319 downto 192; TK2 is 191 downto 64; TK3 is 63 downto 0
        -- The TK3 part will be zeroed out for odd rounds (this happens in ForkSkinnyRB.vhd)
		KEY_ADDITION((16 * W - 1) DOWNTO (12 * W)) <= SHIFTROWS((16 * W - 1) DOWNTO (12 * W)) XOR ROUND_KEY((2 * N + 8 * W - 1) DOWNTO (2 * N + 4 * W)) XOR ROUND_KEY((1 * N + 8 * W - 1) DOWNTO (1 * N + 4 * W)) XOR ROUND_KEY((8 * W - 1) DOWNTO (4 * W));
		KEY_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) <= SHIFTROWS((12 * W - 1) DOWNTO ( 8 * W)) XOR ROUND_KEY((2 * N + 4 * W - 1) DOWNTO (2 * N + 0 * W)) XOR ROUND_KEY((1 * N + 4 * W - 1) DOWNTO (1 * N +  0 * W)) XOR ROUND_KEY((4 * W - 1) DOWNTO ( 0 * W));	
    end generate;
	
	T3N : IF TS = TWEAK_SIZE_3N GENERATE
		KEY_ADDITION((16 * W - 1) DOWNTO (12 * W)) <= SHIFTROWS((16 * W - 1) DOWNTO (12 * W)) XOR ROUND_KEY((2 * N + 16 * W - 1) DOWNTO (2 * N + 12 * W)) XOR ROUND_KEY((1 * N + 16 * W - 1) DOWNTO (1 * N + 12 * W)) XOR ROUND_KEY((16 * W - 1) DOWNTO (12 * W));
		KEY_ADDITION((12 * W - 1) DOWNTO ( 8 * W)) <= SHIFTROWS((12 * W - 1) DOWNTO ( 8 * W)) XOR ROUND_KEY((2 * N + 12 * W - 1) DOWNTO (2 * N +  8 * W)) XOR ROUND_KEY((1 * N + 12 * W - 1) DOWNTO (1 * N +  8 * W)) XOR ROUND_KEY((12 * W - 1) DOWNTO ( 8 * W));	
	END GENERATE;
	
    --  Bottom two rows are unchanged.
	KEY_ADDITION(( 8 * W - 1) DOWNTO ( 4 * W)) <= SHIFTROWS(( 8 * W - 1) DOWNTO ( 4 * W));
	KEY_ADDITION(( 4 * W - 1) DOWNTO ( 0 * W)) <= SHIFTROWS(( 4 * W - 1) DOWNTO ( 0 * W));
	-------------------------------------------------------------------------------

	-- INVERSE CONSTANT ADDITION ----------------------------------------------------------
    -- Note: identical to encryption.
    -- Add round constant (c0, c1, c2), where c2 is fixed and c0, c1 are contained in the input CONST
	N64 : IF BS = BLOCK_SIZE_64 GENERATE
		CONST_ADDITION(63 DOWNTO 60) <= KEY_ADDITION(63 DOWNTO 60) XOR CONST(3 DOWNTO 0); -- Round constant c0
		CONST_ADDITION(59 DOWNTO 54) <= KEY_ADDITION(59 DOWNTO 54);
        CONST_ADDITION(53) 	     	  <= NOT(KEY_ADDITION(53)); -- Bit to indicate tweakey material
		CONST_ADDITION(52 DOWNTO 47) <= KEY_ADDITION(52 DOWNTO 47);
		CONST_ADDITION(46 DOWNTO 44) <= KEY_ADDITION(46 DOWNTO 44) XOR CONST(6 DOWNTO 4); -- Round constant c1
		CONST_ADDITION(43 DOWNTO 30) <= KEY_ADDITION(43 DOWNTO 30);
        CONST_ADDITION(29) 	     	  <= NOT(KEY_ADDITION(29)); -- XOR with c2 = 2
		CONST_ADDITION(28 DOWNTO  0) <= KEY_ADDITION(28 DOWNTO  0);
	END GENERATE;
	
	N128 : IF BS = BLOCK_SIZE_128 GENERATE
		CONST_ADDITION(127 DOWNTO 124) <= KEY_ADDITION(127 DOWNTO 124);
		CONST_ADDITION(123 DOWNTO 120) <= KEY_ADDITION(123 DOWNTO 120) XOR CONST(3 DOWNTO 0);
		CONST_ADDITION(119 DOWNTO  106) <= KEY_ADDITION(119 DOWNTO  106);
        CONST_ADDITION(105) 	     	  <= NOT(KEY_ADDITION(105)); -- Bit to indicate tweakey material
		CONST_ADDITION(104 DOWNTO  91) <= KEY_ADDITION(104 DOWNTO  91);
		CONST_ADDITION( 90 DOWNTO  88) <= KEY_ADDITION( 90 DOWNTO  88) XOR CONST(6 DOWNTO 4);
		CONST_ADDITION( 87 DOWNTO  58) <= KEY_ADDITION( 87 DOWNTO  58);
		CONST_ADDITION(57) 	    	    <= NOT(KEY_ADDITION(57)); -- This is the XOR with c2 = 2
		CONST_ADDITION( 56 DOWNTO   0) <= KEY_ADDITION( 56 DOWNTO   0);	
	END GENERATE;
	-------------------------------------------------------------------------------

	-- INVERSE S-BOX ----------------------------------------------------------------------
	-- Simply apply inverse SBox to every cell of the state
	GEN : FOR I IN 0 TO 15 GENERATE
		S : ENTITY work.SBoxInverse GENERIC MAP (BS => BS) PORT MAP (CONST_ADDITION((W * (I + 1) - 1) DOWNTO (W * I)), ROUND_OUT((W * (I + 1) - 1) DOWNTO (W * I)));
	END GENERATE;
	-------------------------------------------------------------------------------

END Mixed;

