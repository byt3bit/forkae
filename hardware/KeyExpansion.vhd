----------------------------------------------------------------------------------
-- Copyright 2016:
--     Amir Moradi & Pascal Sasdrich for the SKINNY Team
--     https://sites.google.com/site/skinnycipher/
--
-- Copyright 2019 (for decryption and forkcipher):
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


-- Key schedules: unrolled to give synthesis tool maximal freedom


------------------------
-- Forward Key Schedule
------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.Forkskinnypkg.all;

ENTITY ForwardKeySchedule IS
	GENERIC (BS : BLOCK_SIZE; TS : TWEAK_SIZE);
    PORT ( KEY			: IN  STD_LOGIC_VECTOR ((GET_TWEAK_SIZE(BS, TS) - 1) DOWNTO 0);
           NEXT_KEY	: OUT STD_LOGIC_VECTOR ((GET_TWEAK_SIZE(BS, TS) - 1) DOWNTO 0));
END ForwardKeySchedule;


ARCHITECTURE behav OF ForwardKeySchedule IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT N : INTEGER := GET_BLOCK_SIZE(BS);
	CONSTANT T : INTEGER := GET_TWEAK_SIZE(BS, TS);
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);
	
	-- SIGNALS --------------------------------------------------------------------
	SIGNAL PERMUTED_KEY: STD_LOGIC_VECTOR((T - 1) DOWNTO 0);

BEGIN

	-- TWEAKEY ARRAY PERMUTATIONS : TK1 -------------------------------------------

		-- PERMUTATION -------------------------------------------------------------
		P1 : ENTITY work.Permutation
		GENERIC MAP (BS => BS) PORT MAP (
			KEY ((T - 0 * N - 1) DOWNTO (T - 1 * N)), 
			PERMUTED_KEY((T - 0 * N - 1) DOWNTO (T - 1 * N))
		); 
		
		-- NO LFSR -----------------------------------------------------------------
		NEXT_KEY((T - 0 * N - 1) DOWNTO (T - 1 * N)) <= PERMUTED_KEY((T - 0 * N - 1) DOWNTO (T - 1 * N));
		
	-------------------------------------------------------------------------------
	
	-- TWEAKEY ARRAY PERMUTATIONS : TK2 -------------------------------------------
	TK2 : IF TS = TWEAK_SIZE_2N OR TS = TWEAK_SIZE_3N or TS = TWEAK_SIZE_9o4N GENERATE 
	
		-- PERMUTATION -------------------------------------------------------------
		P2 : ENTITY work.Permutation
		GENERIC MAP (BS => BS) PORT MAP (
			KEY ((T - 1 * N - 1) DOWNTO (T - 2 * N)), 
			PERMUTED_KEY((T - 1 * N - 1) DOWNTO (T - 2 * N))
		); 
		
		-- LFSR --------------------------------------------------------------------
		LFSR2 : FOR I IN 0 TO 3 GENERATE
			NEXT_KEY((T + W * (I + 13) - 2 * N - 1) DOWNTO (T + W * (I + 12) - 2 * N)) <= PERMUTED_KEY((T + W * (I + 13) - 2 * N - 2) DOWNTO (T + W * (I + 12) - 2 * N)) & (PERMUTED_KEY(T + W * (I + 13) - 2 * N - 1) XOR PERMUTED_KEY(T + W * (I + 13) - 2 * N - (W / 4) - 1));
			NEXT_KEY((T + W * (I +  9) - 2 * N - 1) DOWNTO (T + W * (I +  8) - 2 * N)) <= PERMUTED_KEY((T + W * (I +  9) - 2 * N - 2) DOWNTO (T + W * (I +  8) - 2 * N)) & (PERMUTED_KEY(T + W * (I +  9) - 2 * N - 1) XOR PERMUTED_KEY(T + W * (I +  9) - 2 * N - (W / 4) - 1));
			NEXT_KEY((T + W * (I +  5) - 2 * N - 1) DOWNTO (T + W * (I +  4) - 2 * N)) <= PERMUTED_KEY((T + W * (I +  5) - 2 * N - 1) DOWNTO (T + W * (I +  4) - 2 * N));
			NEXT_KEY((T + W * (I +  1) - 2 * N - 1) DOWNTO (T + W * (I +  0) - 2 * N)) <= PERMUTED_KEY((T + W * (I +  1) - 2 * N - 1) DOWNTO (T + W * (I +  0) - 2 * N));		
		END GENERATE;
		
	END GENERATE;

    TK3o2 : if TS = TWEAK_SIZE_3o2N generate 

		-- PERMUTATION -------------------------------------------------------------
		P2 : ENTITY work.HalfPermutation
		GENERIC MAP (BS => BS) PORT MAP (
			KEY (63 DOWNTO 0), 
			PERMUTED_KEY(63 DOWNTO 0)
		); 

		-- LFSR --------------------------------------------------------------------
		LFSR2 : FOR I IN 0 TO 3 GENERATE
        NEXT_KEY((W * (I + 5) - 1) DOWNTO (W * (I + 4))) <= PERMUTED_KEY((W * (I + 5) - 2) DOWNTO (W * (I + 4))) & (PERMUTED_KEY(W * (I + 5) - 1) XOR PERMUTED_KEY(W * (I + 5) - (W / 4) - 1));
        NEXT_KEY((W * (I + 1) - 1) DOWNTO (W * (I + 0))) <= PERMUTED_KEY((W * (I + 1) - 2) DOWNTO (W * (I + 0))) & (PERMUTED_KEY(W * (I + 1) - 1) XOR PERMUTED_KEY(W * (I + 1) - (W / 4) - 1));
		END GENERATE;

    end generate;
	-------------------------------------------------------------------------------
	
	-- TWEAKEY ARRAY PERMUTATIONS : TK3 -------------------------------------------
	TK3 : IF TS = TWEAK_SIZE_3N GENERATE 
	
		-- PERMUTATION -------------------------------------------------------------
		P3 : ENTITY work.Permutation
		GENERIC MAP (BS => BS) PORT MAP (
			KEY ((T - 2 * N - 1) DOWNTO (T - 3 * N)),
			PERMUTED_KEY((T - 2 * N - 1) DOWNTO (T - 3 * N))
		); 
	
		-- LFSR --------------------------------------------------------------------
		LFSR3 : FOR I IN 0 TO 3 GENERATE
			NEXT_KEY((T + W * (I + 13) - 3 * N - 1) DOWNTO (T + W * (I + 12) - 3 * N)) <= (PERMUTED_KEY(T + W * (I + 12) - 3 * N) XOR PERMUTED_KEY(T + W * (I + 13) - 3 * N - (W / 4))) & PERMUTED_KEY((T + W * (I + 13) - 3 * N - 1) DOWNTO (T + W * (I + 12) - 3 * N + 1));
			NEXT_KEY((T + W * (I +  9) - 3 * N - 1) DOWNTO (T + W * (I +  8) - 3 * N)) <= (PERMUTED_KEY(T + W * (I +  8) - 3 * N) XOR PERMUTED_KEY(T + W * (I +  9) - 3 * N - (W / 4))) & PERMUTED_KEY((T + W * (I +  9) - 3 * N - 1) DOWNTO (T + W * (I +  8) - 3 * N + 1));
			NEXT_KEY((T + W * (I +  5) - 3 * N - 1) DOWNTO (T + W * (I +  4) - 3 * N)) <= PERMUTED_KEY((T + W * (I +  5) - 3 * N - 1) DOWNTO (T + W * (I +  4) - 3 * N));
			NEXT_KEY((T + W * (I +  1) - 3 * N - 1) DOWNTO (T + W * (I +  0) - 3 * N)) <= PERMUTED_KEY((T + W * (I +  1) - 3 * N - 1) DOWNTO (T + W * (I +  0) - 3 * N));		
		END GENERATE;
		
	END GENERATE;


	TK9o4N : IF TS = TWEAK_SIZE_9o4N GENERATE 
	
		-- PERMUTATION -------------------------------------------------------------
		P3 : ENTITY work.HalfPermutation
		GENERIC MAP (BS => BS) PORT MAP (
			KEY (63 DOWNTO 0),
			PERMUTED_KEY(63 DOWNTO 0)
		); 
	
		-- LFSR --------------------------------------------------------------------
		LFSR3 : FOR I IN 0 TO 3 GENERATE
			NEXT_KEY((W * (I + 5) - 1) DOWNTO (W * (I + 4))) <= (PERMUTED_KEY(W * (I + 4)) XOR PERMUTED_KEY(W * (I + 5) - (W / 4))) & PERMUTED_KEY((W * (I + 5) - 1) DOWNTO (W * (I + 4) + 1));
			NEXT_KEY((W * (I + 1) - 1) DOWNTO (W * (I + 0))) <= (PERMUTED_KEY(W * (I + 0)) XOR PERMUTED_KEY(W * (I + 1) - (W / 4))) & PERMUTED_KEY((W * (I + 1) - 1) DOWNTO (W * (I + 0) + 1));
		END GENERATE;
		
	END GENERATE;
	-------------------------------------------------------------------------------
	
END behav;




------------------------
-- Inverse Key Schedule
------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.forkskinnypkg.all;

ENTITY InverseKeySchedule IS
	GENERIC (BS : BLOCK_SIZE; TS : TWEAK_SIZE);
    PORT ( KEY			: IN  STD_LOGIC_VECTOR ((GET_TWEAK_SIZE(BS, TS) - 1) DOWNTO 0);
           NEXT_KEY	: OUT STD_LOGIC_VECTOR ((GET_TWEAK_SIZE(BS, TS) - 1) DOWNTO 0));
END InverseKeySchedule;



-- ARCHITECTURE : MIXED
----------------------------------------------------------------------------------
ARCHITECTURE behav OF InverseKeySchedule IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT N : INTEGER := GET_BLOCK_SIZE(BS);
	CONSTANT T : INTEGER := GET_TWEAK_SIZE(BS, TS);
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);
	
	-- SIGNALS --------------------------------------------------------------------
	SIGNAL LFSR	: STD_LOGIC_VECTOR((T - 1) DOWNTO 0);

BEGIN

	-- TWEAKEY ARRAY PERMUTATIONS : TK1 -------------------------------------------

		-- NO LFSR -----------------------------------------------------------------
		
		-- INVERSE PERMUTATION ----------------------------------------------------
		P1 : ENTITY work.InversePermutation
		GENERIC MAP (BS => BS) PORT MAP (
			KEY ((T - 0 * N - 1) DOWNTO (T - 1 * N)), 
			NEXT_KEY((T - 0 * N - 1) DOWNTO (T - 1 * N))
		); 
		
		
	-------------------------------------------------------------------------------
	
	-- TWEAKEY ARRAY PERMUTATIONS : TK2 -------------------------------------------
	TK2 : IF TS = TWEAK_SIZE_2N OR TS = TWEAK_SIZE_3N or TS = TWEAK_SIZE_9o4N GENERATE 

        -- INVERSE LFSR 2 = FORWARD LFSR 3 ----------------------------------------
        -- LFSR one column I at a time.
		LFSR3 : FOR I IN 0 TO 3 GENERATE
            -- Top rows enter the LFSR
			LFSR((T + W * (I + 13) - 2 * N - 1) DOWNTO (T + W * (I + 12) - 2 * N)) <= (KEY(T + W * (I + 12) - 2 * N) XOR KEY(T + W * (I + 13) - 2 * N - (W / 4))) & KEY((T + W * (I + 13) - 2 * N - 1) DOWNTO (T + W * (I + 12) - 2 * N + 1));
			LFSR((T + W * (I +  9) - 2 * N - 1) DOWNTO (T + W * (I +  8) - 2 * N)) <= (KEY(T + W * (I +  8) - 2 * N) XOR KEY(T + W * (I +  9) - 2 * N - (W / 4))) & KEY((T + W * (I +  9) - 2 * N - 1) DOWNTO (T + W * (I +  8) - 2 * N + 1));
            -- Bottom rows don't enter the LFSR.
			LFSR((T + W * (I +  5) - 2 * N - 1) DOWNTO (T + W * (I +  4) - 2 * N)) <= KEY((T + W * (I +  5) - 2 * N - 1) DOWNTO (T + W * (I +  4) - 2 * N));
			LFSR((T + W * (I +  1) - 2 * N - 1) DOWNTO (T + W * (I +  0) - 2 * N)) <= KEY((T + W * (I +  1) - 2 * N - 1) DOWNTO (T + W * (I +  0) - 2 * N));		
		END GENERATE;
	
		-- INVERSE PERMUTATION ----------------------------------------------------
		P2 : ENTITY work.InversePermutation
		GENERIC MAP (BS => BS) PORT MAP (
			LFSR ((T - 1 * N - 1) DOWNTO (T - 2 * N)), 
			NEXT_KEY((T - 1 * N - 1) DOWNTO (T - 2 * N))
		); 
		
	END GENERATE;

    TK3o2 : IF TS = TWEAK_SIZE_3o2N GENERATE 

        -- INVERSE LFSR 2 = FORWARD LFSR 3 ----------------------------------------
		LFSR3 : FOR I IN 0 TO 3 GENERATE
			LFSR((W * (I + 5) - 1) DOWNTO (W * (I + 4))) <= (KEY(W * (I + 4)) XOR KEY(W * (I + 5) - (W / 4))) & KEY((W * (I + 5) - 1) DOWNTO (W * (I + 4) + 1));
			LFSR((W * (I + 1) - 1) DOWNTO (W * (I + 0))) <= (KEY(W * (I + 0)) XOR KEY(W * (I + 1) - (W / 4))) & KEY((W * (I + 1) - 1) DOWNTO (W * (I + 0) + 1));
		END GENERATE;
	
		-- INVERSE PERMUTATION ----------------------------------------------------
		P2 : ENTITY work.InverseHalfPermutation
		GENERIC MAP (BS => BS) PORT MAP (
			LFSR (63 downto 0), 
			NEXT_KEY(63 downto 0)
		); 
		
	END GENERATE;

	-------------------------------------------------------------------------------
	
	-- TWEAKEY ARRAY PERMUTATIONS : TK3 -------------------------------------------
	TK3 : IF TS = TWEAK_SIZE_3N GENERATE 
	
        -- INVERSE LFSR 3 = FORWARD LFSR 2 ----------------------------------------
        -- LFSR one column I at a time.
		LFSR2 : FOR I IN 0 TO 3 GENERATE
            -- Top rows enter the LFSR
			LFSR((T + W * (I + 13) - 3 * N - 1) DOWNTO (T + W * (I + 12) - 3 * N)) <= KEY((T + W * (I + 13) - 3 * N - 2) DOWNTO (T + W * (I + 12) - 3 * N)) & (KEY(T + W * (I + 13) - 3 * N - 1) XOR KEY(T + W * (I + 13) - 3 * N - (W / 4) - 1));
			LFSR((T + W * (I +  9) - 3 * N - 1) DOWNTO (T + W * (I +  8) - 3 * N)) <= KEY((T + W * (I +  9) - 3 * N - 2) DOWNTO (T + W * (I +  8) - 3 * N)) & (KEY(T + W * (I +  9) - 3 * N - 1) XOR KEY(T + W * (I +  9) - 3 * N - (W / 4) - 1));
            -- Bottom rows don't enter the LFSR.
			LFSR((T + W * (I +  5) - 3 * N - 1) DOWNTO (T + W * (I +  4) - 3 * N)) <= KEY((T + W * (I +  5) - 3 * N - 1) DOWNTO (T + W * (I +  4) - 3 * N));
			LFSR((T + W * (I +  1) - 3 * N - 1) DOWNTO (T + W * (I +  0) - 3 * N)) <= KEY((T + W * (I +  1) - 3 * N - 1) DOWNTO (T + W * (I +  0) - 3 * N));		
		END GENERATE;

		-- INVERSE PERMUTATION ----------------------------------------------------
		P3 : ENTITY work.InversePermutation
		GENERIC MAP (BS => BS) PORT MAP (
			LFSR ((T - 2 * N - 1) DOWNTO (T - 3 * N)),
			NEXT_KEY((T - 2 * N - 1) DOWNTO (T - 3 * N))
		); 
		
	END GENERATE;


    TK9o4 : IF TS = TWEAK_SIZE_9o4N GENERATE 

        -- INVERSE LFSR 3 = FORWARD LFSR 2 ----------------------------------------
		LFSR3 : FOR I IN 0 TO 3 GENERATE
            LFSR((W * (I + 5) - 1) DOWNTO (W * (I + 4))) <= KEY((W * (I + 5) - 2) DOWNTO (W * (I + 4))) & (KEY(W * (I + 5) - 1) XOR KEY(W * (I + 5) - (W / 4) - 1));
            LFSR((W * (I + 1) - 1) DOWNTO (W * (I + 0))) <= KEY((W * (I + 1) - 2) DOWNTO (W * (I + 0))) & (KEY(W * (I + 1) - 1) XOR KEY(W * (I + 1) - (W / 4) - 1));
		END GENERATE;
	
		-- INVERSE PERMUTATION ----------------------------------------------------
		P2 : ENTITY work.InverseHalfPermutation
		GENERIC MAP (BS => BS) PORT MAP (
			LFSR (63 downto 0), 
			NEXT_KEY(63 downto 0)
		); 
		
	END GENERATE;
	-------------------------------------------------------------------------------
	
END behav;




--------------------------
-- Compute decryption key
--------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.forkskinnypkg.all;

ENTITY DecryptionKey IS
	GENERIC (BS : BLOCK_SIZE; TS : TWEAK_SIZE);
    PORT ( KEY			: IN  STD_LOGIC_VECTOR ((GET_TWEAK_SIZE(BS, TS) - 1) DOWNTO 0);
           NEXT_KEY	: OUT STD_LOGIC_VECTOR ((GET_TWEAK_SIZE(BS, TS) - 1) DOWNTO 0));
END DecryptionKey;


ARCHITECTURE behav OF DecryptionKey IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT N : INTEGER := GET_BLOCK_SIZE(BS);
	CONSTANT T : INTEGER := GET_TWEAK_SIZE(BS, TS);
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);
	
	-- SIGNALS --------------------------------------------------------------------
	SIGNAL TK1, TK2, TK2_PERMUTED, TK3, TK3_PERMUTED          : STD_LOGIC_VECTOR((N - 1) DOWNTO 0);

BEGIN
    B64T192: if BS = BLOCK_SIZE_64 generate

        -- TK1: compute TK1^40
		TK1 <= KEY(191 downto 128);

        -- Generating the following permutation: [5, 6, 3, 2, 7, 0, 1, 4, 13, 14, 11, 10, 15, 8, 9, 12]
        NEXT_KEY((128 + 16 * W - 1) downto (128 + 15 * W)) <= TK1((11 * W - 1) downto (10 * W));
        NEXT_KEY((128 + 15 * W - 1) downto (128 + 14 * W)) <= TK1((10 * W - 1) downto (9 * W));
        NEXT_KEY((128 + 14 * W - 1) downto (128 + 13 * W)) <= TK1((13 * W - 1) downto (12 * W));
        NEXT_KEY((128 + 13 * W - 1) downto (128 + 12 * W)) <= TK1((14 * W - 1) downto (13 * W));
        NEXT_KEY((128 + 12 * W - 1) downto (128 + 11 * W)) <= TK1((9 * W - 1) downto (8 * W));
        NEXT_KEY((128 + 11 * W - 1) downto (128 + 10 * W)) <= TK1((16 * W - 1) downto (15 * W));
        NEXT_KEY((128 + 10 * W - 1) downto (128 + 9 * W)) <= TK1((15 * W - 1) downto (14 * W));
        NEXT_KEY((128 + 9 * W - 1) downto (128 + 8 * W)) <= TK1((12 * W - 1) downto (11 * W));
        NEXT_KEY((128 + 8 * W - 1) downto (128 + 7 * W)) <= TK1((3 * W - 1) downto (2 * W));
        NEXT_KEY((128 + 7 * W - 1) downto (128 + 6 * W)) <= TK1((2 * W - 1) downto (1 * W));
        NEXT_KEY((128 + 6 * W - 1) downto (128 + 5 * W)) <= TK1((5 * W - 1) downto (4 * W));
        NEXT_KEY((128 + 5 * W - 1) downto (128 + 4 * W)) <= TK1((6 * W - 1) downto (5 * W));
        NEXT_KEY((128 + 4 * W - 1) downto (128 + 3 * W)) <= TK1((1 * W - 1) downto (0 * W));
        NEXT_KEY((128 + 3 * W - 1) downto (128 + 2 * W)) <= TK1((8 * W - 1) downto (7 * W));
        NEXT_KEY((128 + 2 * W - 1) downto (128 + 1 * W)) <= TK1((7 * W - 1) downto (6 * W));
        NEXT_KEY((128 + 1 * W - 1) downto (128 + 0 * W)) <= TK1((4 * W - 1) downto (3 * W));


        -- TK2: compute TK2^40
        TK2 <= KEY(127 downto 64);

        -- Generating the following permutation: [5, 6, 3, 2, 7, 0, 1, 4, 13, 14, 11, 10, 15, 8, 9, 12]
        TK2_PERMUTED((16 * W - 1) downto (15 * W)) <= TK2((11 * W - 1) downto (10 * W));
        TK2_PERMUTED((15 * W - 1) downto (14 * W)) <= TK2((10 * W - 1) downto (9 * W));
        TK2_PERMUTED((14 * W - 1) downto (13 * W)) <= TK2((13 * W - 1) downto (12 * W));
        TK2_PERMUTED((13 * W - 1) downto (12 * W)) <= TK2((14 * W - 1) downto (13 * W));
        TK2_PERMUTED((12 * W - 1) downto (11 * W)) <= TK2((9 * W - 1) downto (8 * W));
        TK2_PERMUTED((11 * W - 1) downto (10 * W)) <= TK2((16 * W - 1) downto (15 * W));
        TK2_PERMUTED((10 * W - 1) downto (9 * W)) <= TK2((15 * W - 1) downto (14 * W));
        TK2_PERMUTED((9 * W - 1) downto (8 * W)) <= TK2((12 * W - 1) downto (11 * W));
        TK2_PERMUTED((8 * W - 1) downto (7 * W)) <= TK2((3 * W - 1) downto (2 * W));
        TK2_PERMUTED((7 * W - 1) downto (6 * W)) <= TK2((2 * W - 1) downto (1 * W));
        TK2_PERMUTED((6 * W - 1) downto (5 * W)) <= TK2((5 * W - 1) downto (4 * W));
        TK2_PERMUTED((5 * W - 1) downto (4 * W)) <= TK2((6 * W - 1) downto (5 * W));
        TK2_PERMUTED((4 * W - 1) downto (3 * W)) <= TK2((1 * W - 1) downto (0 * W));
        TK2_PERMUTED((3 * W - 1) downto (2 * W)) <= TK2((8 * W - 1) downto (7 * W));
        TK2_PERMUTED((2 * W - 1) downto (1 * W)) <= TK2((7 * W - 1) downto (6 * W));
        TK2_PERMUTED((1 * W - 1) downto (0 * W)) <= TK2((4 * W - 1) downto (3 * W));

        -- Upper half of the state
        NEXT_KEY(99 downto 96) <= ( TK2_PERMUTED(33) xor TK2_PERMUTED(34) ) & ( TK2_PERMUTED(32) xor TK2_PERMUTED(33) ) & ( TK2_PERMUTED(32) xor TK2_PERMUTED(34) xor TK2_PERMUTED(35) ) & ( TK2_PERMUTED(33) xor TK2_PERMUTED(35) );
        NEXT_KEY(103 downto 100) <= ( TK2_PERMUTED(37) xor TK2_PERMUTED(38) ) & ( TK2_PERMUTED(36) xor TK2_PERMUTED(37) ) & ( TK2_PERMUTED(36) xor TK2_PERMUTED(38) xor TK2_PERMUTED(39) ) & ( TK2_PERMUTED(37) xor TK2_PERMUTED(39) );
        NEXT_KEY(107 downto 104) <= ( TK2_PERMUTED(41) xor TK2_PERMUTED(42) ) & ( TK2_PERMUTED(40) xor TK2_PERMUTED(41) ) & ( TK2_PERMUTED(40) xor TK2_PERMUTED(42) xor TK2_PERMUTED(43) ) & ( TK2_PERMUTED(41) xor TK2_PERMUTED(43) );
        NEXT_KEY(111 downto 108) <= ( TK2_PERMUTED(45) xor TK2_PERMUTED(46) ) & ( TK2_PERMUTED(44) xor TK2_PERMUTED(45) ) & ( TK2_PERMUTED(44) xor TK2_PERMUTED(46) xor TK2_PERMUTED(47) ) & ( TK2_PERMUTED(45) xor TK2_PERMUTED(47) );
        NEXT_KEY(115 downto 112) <= ( TK2_PERMUTED(49) xor TK2_PERMUTED(50) ) & ( TK2_PERMUTED(48) xor TK2_PERMUTED(49) ) & ( TK2_PERMUTED(48) xor TK2_PERMUTED(50) xor TK2_PERMUTED(51) ) & ( TK2_PERMUTED(49) xor TK2_PERMUTED(51) );
        NEXT_KEY(119 downto 116) <= ( TK2_PERMUTED(53) xor TK2_PERMUTED(54) ) & ( TK2_PERMUTED(52) xor TK2_PERMUTED(53) ) & ( TK2_PERMUTED(52) xor TK2_PERMUTED(54) xor TK2_PERMUTED(55) ) & ( TK2_PERMUTED(53) xor TK2_PERMUTED(55) );
        NEXT_KEY(123 downto 120) <= ( TK2_PERMUTED(57) xor TK2_PERMUTED(58) ) & ( TK2_PERMUTED(56) xor TK2_PERMUTED(57) ) & ( TK2_PERMUTED(56) xor TK2_PERMUTED(58) xor TK2_PERMUTED(59) ) & ( TK2_PERMUTED(57) xor TK2_PERMUTED(59) );
        NEXT_KEY(127 downto 124) <= ( TK2_PERMUTED(61) xor TK2_PERMUTED(62) ) & ( TK2_PERMUTED(60) xor TK2_PERMUTED(61) ) & ( TK2_PERMUTED(60) xor TK2_PERMUTED(62) xor TK2_PERMUTED(63) ) & ( TK2_PERMUTED(61) xor TK2_PERMUTED(63) );
        -- Lower half of the state
        NEXT_KEY(67 downto 64) <= ( TK2_PERMUTED(1) xor TK2_PERMUTED(2) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(1) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(2) xor TK2_PERMUTED(3) ) & ( TK2_PERMUTED(1) xor TK2_PERMUTED(3) );
        NEXT_KEY(71 downto 68) <= ( TK2_PERMUTED(5) xor TK2_PERMUTED(6) ) & ( TK2_PERMUTED(4) xor TK2_PERMUTED(5) ) & ( TK2_PERMUTED(4) xor TK2_PERMUTED(6) xor TK2_PERMUTED(7) ) & ( TK2_PERMUTED(5) xor TK2_PERMUTED(7) );
        NEXT_KEY(75 downto 72) <= ( TK2_PERMUTED(9) xor TK2_PERMUTED(10) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(9) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(10) xor TK2_PERMUTED(11) ) & ( TK2_PERMUTED(9) xor TK2_PERMUTED(11) );
        NEXT_KEY(79 downto 76) <= ( TK2_PERMUTED(13) xor TK2_PERMUTED(14) ) & ( TK2_PERMUTED(12) xor TK2_PERMUTED(13) ) & ( TK2_PERMUTED(12) xor TK2_PERMUTED(14) xor TK2_PERMUTED(15) ) & ( TK2_PERMUTED(13) xor TK2_PERMUTED(15) );
        NEXT_KEY(83 downto 80) <= ( TK2_PERMUTED(17) xor TK2_PERMUTED(18) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(17) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(18) xor TK2_PERMUTED(19) ) & ( TK2_PERMUTED(17) xor TK2_PERMUTED(19) );
        NEXT_KEY(87 downto 84) <= ( TK2_PERMUTED(21) xor TK2_PERMUTED(22) ) & ( TK2_PERMUTED(20) xor TK2_PERMUTED(21) ) & ( TK2_PERMUTED(20) xor TK2_PERMUTED(22) xor TK2_PERMUTED(23) ) & ( TK2_PERMUTED(21) xor TK2_PERMUTED(23) );
        NEXT_KEY(91 downto 88) <= ( TK2_PERMUTED(25) xor TK2_PERMUTED(26) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(25) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(26) xor TK2_PERMUTED(27) ) & ( TK2_PERMUTED(25) xor TK2_PERMUTED(27) );
        NEXT_KEY(95 downto 92) <= ( TK2_PERMUTED(29) xor TK2_PERMUTED(30) ) & ( TK2_PERMUTED(28) xor TK2_PERMUTED(29) ) & ( TK2_PERMUTED(28) xor TK2_PERMUTED(30) xor TK2_PERMUTED(31) ) & ( TK2_PERMUTED(29) xor TK2_PERMUTED(31) );
        

        -- TK3: compute TK3^40
        TK3 <= KEY(63 downto 0);

        -- Generating the following permutation: [5, 6, 3, 2, 7, 0, 1, 4, 13, 14, 11, 10, 15, 8, 9, 12]
        TK3_PERMUTED((16 * W - 1) downto (15 * W)) <= TK3((11 * W - 1) downto (10 * W));
        TK3_PERMUTED((15 * W - 1) downto (14 * W)) <= TK3((10 * W - 1) downto (9 * W));
        TK3_PERMUTED((14 * W - 1) downto (13 * W)) <= TK3((13 * W - 1) downto (12 * W));
        TK3_PERMUTED((13 * W - 1) downto (12 * W)) <= TK3((14 * W - 1) downto (13 * W));
        TK3_PERMUTED((12 * W - 1) downto (11 * W)) <= TK3((9 * W - 1) downto (8 * W));
        TK3_PERMUTED((11 * W - 1) downto (10 * W)) <= TK3((16 * W - 1) downto (15 * W));
        TK3_PERMUTED((10 * W - 1) downto (9 * W)) <= TK3((15 * W - 1) downto (14 * W));
        TK3_PERMUTED((9 * W - 1) downto (8 * W)) <= TK3((12 * W - 1) downto (11 * W));
        TK3_PERMUTED((8 * W - 1) downto (7 * W)) <= TK3((3 * W - 1) downto (2 * W));
        TK3_PERMUTED((7 * W - 1) downto (6 * W)) <= TK3((2 * W - 1) downto (1 * W));
        TK3_PERMUTED((6 * W - 1) downto (5 * W)) <= TK3((5 * W - 1) downto (4 * W));
        TK3_PERMUTED((5 * W - 1) downto (4 * W)) <= TK3((6 * W - 1) downto (5 * W));
        TK3_PERMUTED((4 * W - 1) downto (3 * W)) <= TK3((1 * W - 1) downto (0 * W));
        TK3_PERMUTED((3 * W - 1) downto (2 * W)) <= TK3((8 * W - 1) downto (7 * W));
        TK3_PERMUTED((2 * W - 1) downto (1 * W)) <= TK3((7 * W - 1) downto (6 * W));
        TK3_PERMUTED((1 * W - 1) downto (0 * W)) <= TK3((4 * W - 1) downto (3 * W));

        -- Upper half of the state
        NEXT_KEY(35 downto 32) <= ( TK3_PERMUTED(33) xor TK3_PERMUTED(34) xor TK3_PERMUTED(35) ) & ( TK3_PERMUTED(32) xor TK3_PERMUTED(33) xor TK3_PERMUTED(34) ) & ( TK3_PERMUTED(32) xor TK3_PERMUTED(33) xor TK3_PERMUTED(34) xor TK3_PERMUTED(35) ) & ( TK3_PERMUTED(32) xor TK3_PERMUTED(33) xor TK3_PERMUTED(35) );
        NEXT_KEY(39 downto 36) <= ( TK3_PERMUTED(37) xor TK3_PERMUTED(38) xor TK3_PERMUTED(39) ) & ( TK3_PERMUTED(36) xor TK3_PERMUTED(37) xor TK3_PERMUTED(38) ) & ( TK3_PERMUTED(36) xor TK3_PERMUTED(37) xor TK3_PERMUTED(38) xor TK3_PERMUTED(39) ) & ( TK3_PERMUTED(36) xor TK3_PERMUTED(37) xor TK3_PERMUTED(39) );
        NEXT_KEY(43 downto 40) <= ( TK3_PERMUTED(41) xor TK3_PERMUTED(42) xor TK3_PERMUTED(43) ) & ( TK3_PERMUTED(40) xor TK3_PERMUTED(41) xor TK3_PERMUTED(42) ) & ( TK3_PERMUTED(40) xor TK3_PERMUTED(41) xor TK3_PERMUTED(42) xor TK3_PERMUTED(43) ) & ( TK3_PERMUTED(40) xor TK3_PERMUTED(41) xor TK3_PERMUTED(43) );
        NEXT_KEY(47 downto 44) <= ( TK3_PERMUTED(45) xor TK3_PERMUTED(46) xor TK3_PERMUTED(47) ) & ( TK3_PERMUTED(44) xor TK3_PERMUTED(45) xor TK3_PERMUTED(46) ) & ( TK3_PERMUTED(44) xor TK3_PERMUTED(45) xor TK3_PERMUTED(46) xor TK3_PERMUTED(47) ) & ( TK3_PERMUTED(44) xor TK3_PERMUTED(45) xor TK3_PERMUTED(47) );
        NEXT_KEY(51 downto 48) <= ( TK3_PERMUTED(49) xor TK3_PERMUTED(50) xor TK3_PERMUTED(51) ) & ( TK3_PERMUTED(48) xor TK3_PERMUTED(49) xor TK3_PERMUTED(50) ) & ( TK3_PERMUTED(48) xor TK3_PERMUTED(49) xor TK3_PERMUTED(50) xor TK3_PERMUTED(51) ) & ( TK3_PERMUTED(48) xor TK3_PERMUTED(49) xor TK3_PERMUTED(51) );
        NEXT_KEY(55 downto 52) <= ( TK3_PERMUTED(53) xor TK3_PERMUTED(54) xor TK3_PERMUTED(55) ) & ( TK3_PERMUTED(52) xor TK3_PERMUTED(53) xor TK3_PERMUTED(54) ) & ( TK3_PERMUTED(52) xor TK3_PERMUTED(53) xor TK3_PERMUTED(54) xor TK3_PERMUTED(55) ) & ( TK3_PERMUTED(52) xor TK3_PERMUTED(53) xor TK3_PERMUTED(55) );
        NEXT_KEY(59 downto 56) <= ( TK3_PERMUTED(57) xor TK3_PERMUTED(58) xor TK3_PERMUTED(59) ) & ( TK3_PERMUTED(56) xor TK3_PERMUTED(57) xor TK3_PERMUTED(58) ) & ( TK3_PERMUTED(56) xor TK3_PERMUTED(57) xor TK3_PERMUTED(58) xor TK3_PERMUTED(59) ) & ( TK3_PERMUTED(56) xor TK3_PERMUTED(57) xor TK3_PERMUTED(59) );
        NEXT_KEY(63 downto 60) <= ( TK3_PERMUTED(61) xor TK3_PERMUTED(62) xor TK3_PERMUTED(63) ) & ( TK3_PERMUTED(60) xor TK3_PERMUTED(61) xor TK3_PERMUTED(62) ) & ( TK3_PERMUTED(60) xor TK3_PERMUTED(61) xor TK3_PERMUTED(62) xor TK3_PERMUTED(63) ) & ( TK3_PERMUTED(60) xor TK3_PERMUTED(61) xor TK3_PERMUTED(63) );
        -- Lower half of the state
        NEXT_KEY(3 downto 0) <= ( TK3_PERMUTED(1) xor TK3_PERMUTED(2) xor TK3_PERMUTED(3) ) & ( TK3_PERMUTED(0) xor TK3_PERMUTED(1) xor TK3_PERMUTED(2) ) & ( TK3_PERMUTED(0) xor TK3_PERMUTED(1) xor TK3_PERMUTED(2) xor TK3_PERMUTED(3) ) & ( TK3_PERMUTED(0) xor TK3_PERMUTED(1) xor TK3_PERMUTED(3) );
        NEXT_KEY(7 downto 4) <= ( TK3_PERMUTED(5) xor TK3_PERMUTED(6) xor TK3_PERMUTED(7) ) & ( TK3_PERMUTED(4) xor TK3_PERMUTED(5) xor TK3_PERMUTED(6) ) & ( TK3_PERMUTED(4) xor TK3_PERMUTED(5) xor TK3_PERMUTED(6) xor TK3_PERMUTED(7) ) & ( TK3_PERMUTED(4) xor TK3_PERMUTED(5) xor TK3_PERMUTED(7) );
        NEXT_KEY(11 downto 8) <= ( TK3_PERMUTED(9) xor TK3_PERMUTED(10) xor TK3_PERMUTED(11) ) & ( TK3_PERMUTED(8) xor TK3_PERMUTED(9) xor TK3_PERMUTED(10) ) & ( TK3_PERMUTED(8) xor TK3_PERMUTED(9) xor TK3_PERMUTED(10) xor TK3_PERMUTED(11) ) & ( TK3_PERMUTED(8) xor TK3_PERMUTED(9) xor TK3_PERMUTED(11) );
        NEXT_KEY(15 downto 12) <= ( TK3_PERMUTED(13) xor TK3_PERMUTED(14) xor TK3_PERMUTED(15) ) & ( TK3_PERMUTED(12) xor TK3_PERMUTED(13) xor TK3_PERMUTED(14) ) & ( TK3_PERMUTED(12) xor TK3_PERMUTED(13) xor TK3_PERMUTED(14) xor TK3_PERMUTED(15) ) & ( TK3_PERMUTED(12) xor TK3_PERMUTED(13) xor TK3_PERMUTED(15) );
        NEXT_KEY(19 downto 16) <= ( TK3_PERMUTED(17) xor TK3_PERMUTED(18) xor TK3_PERMUTED(19) ) & ( TK3_PERMUTED(16) xor TK3_PERMUTED(17) xor TK3_PERMUTED(18) ) & ( TK3_PERMUTED(16) xor TK3_PERMUTED(17) xor TK3_PERMUTED(18) xor TK3_PERMUTED(19) ) & ( TK3_PERMUTED(16) xor TK3_PERMUTED(17) xor TK3_PERMUTED(19) );
        NEXT_KEY(23 downto 20) <= ( TK3_PERMUTED(21) xor TK3_PERMUTED(22) xor TK3_PERMUTED(23) ) & ( TK3_PERMUTED(20) xor TK3_PERMUTED(21) xor TK3_PERMUTED(22) ) & ( TK3_PERMUTED(20) xor TK3_PERMUTED(21) xor TK3_PERMUTED(22) xor TK3_PERMUTED(23) ) & ( TK3_PERMUTED(20) xor TK3_PERMUTED(21) xor TK3_PERMUTED(23) );
        NEXT_KEY(27 downto 24) <= ( TK3_PERMUTED(25) xor TK3_PERMUTED(26) xor TK3_PERMUTED(27) ) & ( TK3_PERMUTED(24) xor TK3_PERMUTED(25) xor TK3_PERMUTED(26) ) & ( TK3_PERMUTED(24) xor TK3_PERMUTED(25) xor TK3_PERMUTED(26) xor TK3_PERMUTED(27) ) & ( TK3_PERMUTED(24) xor TK3_PERMUTED(25) xor TK3_PERMUTED(27) );
        NEXT_KEY(31 downto 28) <= ( TK3_PERMUTED(29) xor TK3_PERMUTED(30) xor TK3_PERMUTED(31) ) & ( TK3_PERMUTED(28) xor TK3_PERMUTED(29) xor TK3_PERMUTED(30) ) & ( TK3_PERMUTED(28) xor TK3_PERMUTED(29) xor TK3_PERMUTED(30) xor TK3_PERMUTED(31) ) & ( TK3_PERMUTED(28) xor TK3_PERMUTED(29) xor TK3_PERMUTED(31) );



    end generate;

    B128T256: if BS = BLOCK_SIZE_128 and TS = TWEAK_SIZE_2N generate

        -- TK1: compute TK1^48 === do nothing
		NEXT_KEY((T - 0 * N - 1) DOWNTO (T - 1 * N)) <= KEY((T - 0 * N - 1) DOWNTO (T - 1 * N));

            -- TK2: compute TK2^48 ===  no permutation, 48 LFSR applications
        TK2 <= KEY((T - 1 * N - 1) DOWNTO (T - 2 * N));

        -- Upper half of the state
        NEXT_KEY(71 downto 64) <= ( TK2(65) xor TK2(67) xor TK2(69) xor TK2(71) ) & ( TK2(64) xor TK2(66) xor TK2(68) xor TK2(70) ) & ( TK2(65) xor TK2(67) xor TK2(71) ) & ( TK2(64) xor TK2(66) xor TK2(70) ) & ( TK2(65) xor TK2(71) ) & ( TK2(64) xor TK2(70) ) & TK2(71) & TK2(70);
        NEXT_KEY(79 downto 72) <= ( TK2(73) xor TK2(75) xor TK2(77) xor TK2(79) ) & ( TK2(72) xor TK2(74) xor TK2(76) xor TK2(78) ) & ( TK2(73) xor TK2(75) xor TK2(79) ) & ( TK2(72) xor TK2(74) xor TK2(78) ) & ( TK2(73) xor TK2(79) ) & ( TK2(72) xor TK2(78) ) & TK2(79) & TK2(78);
        NEXT_KEY(87 downto 80) <= ( TK2(81) xor TK2(83) xor TK2(85) xor TK2(87) ) & ( TK2(80) xor TK2(82) xor TK2(84) xor TK2(86) ) & ( TK2(81) xor TK2(83) xor TK2(87) ) & ( TK2(80) xor TK2(82) xor TK2(86) ) & ( TK2(81) xor TK2(87) ) & ( TK2(80) xor TK2(86) ) & TK2(87) & TK2(86);
        NEXT_KEY(95 downto 88) <= ( TK2(89) xor TK2(91) xor TK2(93) xor TK2(95) ) & ( TK2(88) xor TK2(90) xor TK2(92) xor TK2(94) ) & ( TK2(89) xor TK2(91) xor TK2(95) ) & ( TK2(88) xor TK2(90) xor TK2(94) ) & ( TK2(89) xor TK2(95) ) & ( TK2(88) xor TK2(94) ) & TK2(95) & TK2(94);
        NEXT_KEY(103 downto 96) <= ( TK2(97) xor TK2(99) xor TK2(101) xor TK2(103) ) & ( TK2(96) xor TK2(98) xor TK2(100) xor TK2(102) ) & ( TK2(97) xor TK2(99) xor TK2(103) ) & ( TK2(96) xor TK2(98) xor TK2(102) ) & ( TK2(97) xor TK2(103) ) & ( TK2(96) xor TK2(102) ) & TK2(103) & TK2(102);
        NEXT_KEY(111 downto 104) <= ( TK2(105) xor TK2(107) xor TK2(109) xor TK2(111) ) & ( TK2(104) xor TK2(106) xor TK2(108) xor TK2(110) ) & ( TK2(105) xor TK2(107) xor TK2(111) ) & ( TK2(104) xor TK2(106) xor TK2(110) ) & ( TK2(105) xor TK2(111) ) & ( TK2(104) xor TK2(110) ) & TK2(111) & TK2(110);
        NEXT_KEY(119 downto 112) <= ( TK2(113) xor TK2(115) xor TK2(117) xor TK2(119) ) & ( TK2(112) xor TK2(114) xor TK2(116) xor TK2(118) ) & ( TK2(113) xor TK2(115) xor TK2(119) ) & ( TK2(112) xor TK2(114) xor TK2(118) ) & ( TK2(113) xor TK2(119) ) & ( TK2(112) xor TK2(118) ) & TK2(119) & TK2(118);
        NEXT_KEY(127 downto 120) <= ( TK2(121) xor TK2(123) xor TK2(125) xor TK2(127) ) & ( TK2(120) xor TK2(122) xor TK2(124) xor TK2(126) ) & ( TK2(121) xor TK2(123) xor TK2(127) ) & ( TK2(120) xor TK2(122) xor TK2(126) ) & ( TK2(121) xor TK2(127) ) & ( TK2(120) xor TK2(126) ) & TK2(127) & TK2(126);
        -- Lower half of the state
        NEXT_KEY(7 downto 0) <= ( TK2(1) xor TK2(3) xor TK2(5) xor TK2(7) ) & ( TK2(0) xor TK2(2) xor TK2(4) xor TK2(6) ) & ( TK2(1) xor TK2(3) xor TK2(7) ) & ( TK2(0) xor TK2(2) xor TK2(6) ) & ( TK2(1) xor TK2(7) ) & ( TK2(0) xor TK2(6) ) & TK2(7) & TK2(6);
        NEXT_KEY(15 downto 8) <= ( TK2(9) xor TK2(11) xor TK2(13) xor TK2(15) ) & ( TK2(8) xor TK2(10) xor TK2(12) xor TK2(14) ) & ( TK2(9) xor TK2(11) xor TK2(15) ) & ( TK2(8) xor TK2(10) xor TK2(14) ) & ( TK2(9) xor TK2(15) ) & ( TK2(8) xor TK2(14) ) & TK2(15) & TK2(14);
        NEXT_KEY(23 downto 16) <= ( TK2(17) xor TK2(19) xor TK2(21) xor TK2(23) ) & ( TK2(16) xor TK2(18) xor TK2(20) xor TK2(22) ) & ( TK2(17) xor TK2(19) xor TK2(23) ) & ( TK2(16) xor TK2(18) xor TK2(22) ) & ( TK2(17) xor TK2(23) ) & ( TK2(16) xor TK2(22) ) & TK2(23) & TK2(22);
        NEXT_KEY(31 downto 24) <= ( TK2(25) xor TK2(27) xor TK2(29) xor TK2(31) ) & ( TK2(24) xor TK2(26) xor TK2(28) xor TK2(30) ) & ( TK2(25) xor TK2(27) xor TK2(31) ) & ( TK2(24) xor TK2(26) xor TK2(30) ) & ( TK2(25) xor TK2(31) ) & ( TK2(24) xor TK2(30) ) & TK2(31) & TK2(30);
        NEXT_KEY(39 downto 32) <= ( TK2(33) xor TK2(35) xor TK2(37) xor TK2(39) ) & ( TK2(32) xor TK2(34) xor TK2(36) xor TK2(38) ) & ( TK2(33) xor TK2(35) xor TK2(39) ) & ( TK2(32) xor TK2(34) xor TK2(38) ) & ( TK2(33) xor TK2(39) ) & ( TK2(32) xor TK2(38) ) & TK2(39) & TK2(38);
        NEXT_KEY(47 downto 40) <= ( TK2(41) xor TK2(43) xor TK2(45) xor TK2(47) ) & ( TK2(40) xor TK2(42) xor TK2(44) xor TK2(46) ) & ( TK2(41) xor TK2(43) xor TK2(47) ) & ( TK2(40) xor TK2(42) xor TK2(46) ) & ( TK2(41) xor TK2(47) ) & ( TK2(40) xor TK2(46) ) & TK2(47) & TK2(46);
        NEXT_KEY(55 downto 48) <= ( TK2(49) xor TK2(51) xor TK2(53) xor TK2(55) ) & ( TK2(48) xor TK2(50) xor TK2(52) xor TK2(54) ) & ( TK2(49) xor TK2(51) xor TK2(55) ) & ( TK2(48) xor TK2(50) xor TK2(54) ) & ( TK2(49) xor TK2(55) ) & ( TK2(48) xor TK2(54) ) & TK2(55) & TK2(54);
        NEXT_KEY(63 downto 56) <= ( TK2(57) xor TK2(59) xor TK2(61) xor TK2(63) ) & ( TK2(56) xor TK2(58) xor TK2(60) xor TK2(62) ) & ( TK2(57) xor TK2(59) xor TK2(63) ) & ( TK2(56) xor TK2(58) xor TK2(62) ) & ( TK2(57) xor TK2(63) ) & ( TK2(56) xor TK2(62) ) & TK2(63) & TK2(62);


        end generate;

    B128T192: if BS = BLOCK_SIZE_128 and TS = TWEAK_SIZE_3o2N generate

        -- TK1: compute TK1^48 === do nothing
		NEXT_KEY((T - 0 * N - 1) DOWNTO (T - 1 * N)) <= KEY((T - 0 * N - 1) DOWNTO (T - 1 * N));

        -- TK2: compute TK2^24 ===  no permutatation,  (24 because of half-state)
        TK2(63 downto 0) <= KEY(63 downto 0);

        -- LFSR only on half a state
        NEXT_KEY(7 downto 0) <= ( TK2(1) xor TK2(3) xor TK2(5) xor TK2(7) ) & ( TK2(0) xor TK2(2) xor TK2(4) xor TK2(6) ) & ( TK2(1) xor TK2(3) xor TK2(7) ) & ( TK2(0) xor TK2(2) xor TK2(6) ) & ( TK2(1) xor TK2(7) ) & ( TK2(0) xor TK2(6) ) & TK2(7) & TK2(6);
        NEXT_KEY(15 downto 8) <= ( TK2(9) xor TK2(11) xor TK2(13) xor TK2(15) ) & ( TK2(8) xor TK2(10) xor TK2(12) xor TK2(14) ) & ( TK2(9) xor TK2(11) xor TK2(15) ) & ( TK2(8) xor TK2(10) xor TK2(14) ) & ( TK2(9) xor TK2(15) ) & ( TK2(8) xor TK2(14) ) & TK2(15) & TK2(14);
        NEXT_KEY(23 downto 16) <= ( TK2(17) xor TK2(19) xor TK2(21) xor TK2(23) ) & ( TK2(16) xor TK2(18) xor TK2(20) xor TK2(22) ) & ( TK2(17) xor TK2(19) xor TK2(23) ) & ( TK2(16) xor TK2(18) xor TK2(22) ) & ( TK2(17) xor TK2(23) ) & ( TK2(16) xor TK2(22) ) & TK2(23) & TK2(22);
        NEXT_KEY(31 downto 24) <= ( TK2(25) xor TK2(27) xor TK2(29) xor TK2(31) ) & ( TK2(24) xor TK2(26) xor TK2(28) xor TK2(30) ) & ( TK2(25) xor TK2(27) xor TK2(31) ) & ( TK2(24) xor TK2(26) xor TK2(30) ) & ( TK2(25) xor TK2(31) ) & ( TK2(24) xor TK2(30) ) & TK2(31) & TK2(30);
        NEXT_KEY(39 downto 32) <= ( TK2(33) xor TK2(35) xor TK2(37) xor TK2(39) ) & ( TK2(32) xor TK2(34) xor TK2(36) xor TK2(38) ) & ( TK2(33) xor TK2(35) xor TK2(39) ) & ( TK2(32) xor TK2(34) xor TK2(38) ) & ( TK2(33) xor TK2(39) ) & ( TK2(32) xor TK2(38) ) & TK2(39) & TK2(38);
        NEXT_KEY(47 downto 40) <= ( TK2(41) xor TK2(43) xor TK2(45) xor TK2(47) ) & ( TK2(40) xor TK2(42) xor TK2(44) xor TK2(46) ) & ( TK2(41) xor TK2(43) xor TK2(47) ) & ( TK2(40) xor TK2(42) xor TK2(46) ) & ( TK2(41) xor TK2(47) ) & ( TK2(40) xor TK2(46) ) & TK2(47) & TK2(46);
        NEXT_KEY(55 downto 48) <= ( TK2(49) xor TK2(51) xor TK2(53) xor TK2(55) ) & ( TK2(48) xor TK2(50) xor TK2(52) xor TK2(54) ) & ( TK2(49) xor TK2(51) xor TK2(55) ) & ( TK2(48) xor TK2(50) xor TK2(54) ) & ( TK2(49) xor TK2(55) ) & ( TK2(48) xor TK2(54) ) & TK2(55) & TK2(54);
        NEXT_KEY(63 downto 56) <= ( TK2(57) xor TK2(59) xor TK2(61) xor TK2(63) ) & ( TK2(56) xor TK2(58) xor TK2(60) xor TK2(62) ) & ( TK2(57) xor TK2(59) xor TK2(63) ) & ( TK2(56) xor TK2(58) xor TK2(62) ) & ( TK2(57) xor TK2(63) ) & ( TK2(56) xor TK2(62) ) & TK2(63) & TK2(62);

    end generate;
        

    B128T288: if BS = BLOCK_SIZE_128 and TS = TWEAK_SIZE_9o4N generate

    -- TK1^56
    -- Generating the following permutation: [5, 6, 3, 2, 7, 0, 1, 4, 13, 14, 11, 10, 15, 8, 9, 12]
    TK1 <= KEY(T-1 downto T-N);
	NEXT_KEY((T-N + 16 * W - 1) downto (T-N + 15 * W)) <= TK1((11 * W - 1) downto (10 * W));
	NEXT_KEY((T-N + 15 * W - 1) downto (T-N + 14 * W)) <= TK1((10 * W - 1) downto (9 * W));
	NEXT_KEY((T-N + 14 * W - 1) downto (T-N + 13 * W)) <= TK1((13 * W - 1) downto (12 * W));
	NEXT_KEY((T-N + 13 * W - 1) downto (T-N + 12 * W)) <= TK1((14 * W - 1) downto (13 * W));
	NEXT_KEY((T-N + 12 * W - 1) downto (T-N + 11 * W)) <= TK1((9 * W - 1) downto (8 * W));
	NEXT_KEY((T-N + 11 * W - 1) downto (T-N + 10 * W)) <= TK1((16 * W - 1) downto (15 * W));
	NEXT_KEY((T-N + 10 * W - 1) downto (T-N + 9 * W)) <= TK1((15 * W - 1) downto (14 * W));
	NEXT_KEY((T-N + 9 * W - 1) downto (T-N + 8 * W)) <= TK1((12 * W - 1) downto (11 * W));
	NEXT_KEY((T-N + 8 * W - 1) downto (T-N + 7 * W)) <= TK1((3 * W - 1) downto (2 * W));
	NEXT_KEY((T-N + 7 * W - 1) downto (T-N + 6 * W)) <= TK1((2 * W - 1) downto (1 * W));
	NEXT_KEY((T-N + 6 * W - 1) downto (T-N + 5 * W)) <= TK1((5 * W - 1) downto (4 * W));
	NEXT_KEY((T-N + 5 * W - 1) downto (T-N + 4 * W)) <= TK1((6 * W - 1) downto (5 * W));
	NEXT_KEY((T-N + 4 * W - 1) downto (T-N + 3 * W)) <= TK1((1 * W - 1) downto (0 * W));
	NEXT_KEY((T-N + 3 * W - 1) downto (T-N + 2 * W)) <= TK1((8 * W - 1) downto (7 * W));
	NEXT_KEY((T-N + 2 * W - 1) downto (T-N + 1 * W)) <= TK1((7 * W - 1) downto (6 * W));
	NEXT_KEY((T-N + 1 * W - 1) downto (T-N + 0 * W)) <= TK1((4 * W - 1) downto (3 * W));

    -- TK2^56
	-- Generating the following permutation: [5, 6, 3, 2, 7, 0, 1, 4, 13, 14, 11, 10, 15, 8, 9, 12]
    TK2 <= KEY((T - 1 * N - 1) DOWNTO (T - 2 * N));
	TK2_PERMUTED((16 * W - 1) downto (15 * W)) <= TK2((11 * W - 1) downto (10 * W));
	TK2_PERMUTED((15 * W - 1) downto (14 * W)) <= TK2((10 * W - 1) downto (9 * W));
	TK2_PERMUTED((14 * W - 1) downto (13 * W)) <= TK2((13 * W - 1) downto (12 * W));
	TK2_PERMUTED((13 * W - 1) downto (12 * W)) <= TK2((14 * W - 1) downto (13 * W));
	TK2_PERMUTED((12 * W - 1) downto (11 * W)) <= TK2((9 * W - 1) downto (8 * W));
	TK2_PERMUTED((11 * W - 1) downto (10 * W)) <= TK2((16 * W - 1) downto (15 * W));
	TK2_PERMUTED((10 * W - 1) downto (9 * W)) <= TK2((15 * W - 1) downto (14 * W));
	TK2_PERMUTED((9 * W - 1) downto (8 * W)) <= TK2((12 * W - 1) downto (11 * W));
	TK2_PERMUTED((8 * W - 1) downto (7 * W)) <= TK2((3 * W - 1) downto (2 * W));
	TK2_PERMUTED((7 * W - 1) downto (6 * W)) <= TK2((2 * W - 1) downto (1 * W));
	TK2_PERMUTED((6 * W - 1) downto (5 * W)) <= TK2((5 * W - 1) downto (4 * W));
	TK2_PERMUTED((5 * W - 1) downto (4 * W)) <= TK2((6 * W - 1) downto (5 * W));
	TK2_PERMUTED((4 * W - 1) downto (3 * W)) <= TK2((1 * W - 1) downto (0 * W));
	TK2_PERMUTED((3 * W - 1) downto (2 * W)) <= TK2((8 * W - 1) downto (7 * W));
	TK2_PERMUTED((2 * W - 1) downto (1 * W)) <= TK2((7 * W - 1) downto (6 * W));
	TK2_PERMUTED((1 * W - 1) downto (0 * W)) <= TK2((4 * W - 1) downto (3 * W));

    -- Upper half of the state
    NEXT_KEY(135 downto 128) <= ( TK2_PERMUTED(65) xor TK2_PERMUTED(71) ) & ( TK2_PERMUTED(64) xor TK2_PERMUTED(70) ) & TK2_PERMUTED(71) & TK2_PERMUTED(70) & TK2_PERMUTED(69) & TK2_PERMUTED(68) & TK2_PERMUTED(67) & TK2_PERMUTED(66);
    NEXT_KEY(143 downto 136) <= ( TK2_PERMUTED(73) xor TK2_PERMUTED(79) ) & ( TK2_PERMUTED(72) xor TK2_PERMUTED(78) ) & TK2_PERMUTED(79) & TK2_PERMUTED(78) & TK2_PERMUTED(77) & TK2_PERMUTED(76) & TK2_PERMUTED(75) & TK2_PERMUTED(74);
    NEXT_KEY(151 downto 144) <= ( TK2_PERMUTED(81) xor TK2_PERMUTED(87) ) & ( TK2_PERMUTED(80) xor TK2_PERMUTED(86) ) & TK2_PERMUTED(87) & TK2_PERMUTED(86) & TK2_PERMUTED(85) & TK2_PERMUTED(84) & TK2_PERMUTED(83) & TK2_PERMUTED(82);
    NEXT_KEY(159 downto 152) <= ( TK2_PERMUTED(89) xor TK2_PERMUTED(95) ) & ( TK2_PERMUTED(88) xor TK2_PERMUTED(94) ) & TK2_PERMUTED(95) & TK2_PERMUTED(94) & TK2_PERMUTED(93) & TK2_PERMUTED(92) & TK2_PERMUTED(91) & TK2_PERMUTED(90);
    NEXT_KEY(167 downto 160) <= ( TK2_PERMUTED(97) xor TK2_PERMUTED(103) ) & ( TK2_PERMUTED(96) xor TK2_PERMUTED(102) ) & TK2_PERMUTED(103) & TK2_PERMUTED(102) & TK2_PERMUTED(101) & TK2_PERMUTED(100) & TK2_PERMUTED(99) & TK2_PERMUTED(98);
    NEXT_KEY(175 downto 168) <= ( TK2_PERMUTED(105) xor TK2_PERMUTED(111) ) & ( TK2_PERMUTED(104) xor TK2_PERMUTED(110) ) & TK2_PERMUTED(111) & TK2_PERMUTED(110) & TK2_PERMUTED(109) & TK2_PERMUTED(108) & TK2_PERMUTED(107) & TK2_PERMUTED(106);
    NEXT_KEY(183 downto 176) <= ( TK2_PERMUTED(113) xor TK2_PERMUTED(119) ) & ( TK2_PERMUTED(112) xor TK2_PERMUTED(118) ) & TK2_PERMUTED(119) & TK2_PERMUTED(118) & TK2_PERMUTED(117) & TK2_PERMUTED(116) & TK2_PERMUTED(115) & TK2_PERMUTED(114);
    NEXT_KEY(191 downto 184) <= ( TK2_PERMUTED(121) xor TK2_PERMUTED(127) ) & ( TK2_PERMUTED(120) xor TK2_PERMUTED(126) ) & TK2_PERMUTED(127) & TK2_PERMUTED(126) & TK2_PERMUTED(125) & TK2_PERMUTED(124) & TK2_PERMUTED(123) & TK2_PERMUTED(122);

    -- Lower half of the state
    NEXT_KEY(71 downto 64) <= ( TK2_PERMUTED(1) xor TK2_PERMUTED(7) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(6) ) & TK2_PERMUTED(7) & TK2_PERMUTED(6) & TK2_PERMUTED(5) & TK2_PERMUTED(4) & TK2_PERMUTED(3) & TK2_PERMUTED(2);
    NEXT_KEY(79 downto 72) <= ( TK2_PERMUTED(9) xor TK2_PERMUTED(15) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(14) ) & TK2_PERMUTED(15) & TK2_PERMUTED(14) & TK2_PERMUTED(13) & TK2_PERMUTED(12) & TK2_PERMUTED(11) & TK2_PERMUTED(10);
    NEXT_KEY(87 downto 80) <= ( TK2_PERMUTED(17) xor TK2_PERMUTED(23) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(22) ) & TK2_PERMUTED(23) & TK2_PERMUTED(22) & TK2_PERMUTED(21) & TK2_PERMUTED(20) & TK2_PERMUTED(19) & TK2_PERMUTED(18);
    NEXT_KEY(95 downto 88) <= ( TK2_PERMUTED(25) xor TK2_PERMUTED(31) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(30) ) & TK2_PERMUTED(31) & TK2_PERMUTED(30) & TK2_PERMUTED(29) & TK2_PERMUTED(28) & TK2_PERMUTED(27) & TK2_PERMUTED(26);
    NEXT_KEY(103 downto 96) <= ( TK2_PERMUTED(33) xor TK2_PERMUTED(39) ) & ( TK2_PERMUTED(32) xor TK2_PERMUTED(38) ) & TK2_PERMUTED(39) & TK2_PERMUTED(38) & TK2_PERMUTED(37) & TK2_PERMUTED(36) & TK2_PERMUTED(35) & TK2_PERMUTED(34);
    NEXT_KEY(111 downto 104) <= ( TK2_PERMUTED(41) xor TK2_PERMUTED(47) ) & ( TK2_PERMUTED(40) xor TK2_PERMUTED(46) ) & TK2_PERMUTED(47) & TK2_PERMUTED(46) & TK2_PERMUTED(45) & TK2_PERMUTED(44) & TK2_PERMUTED(43) & TK2_PERMUTED(42);
    NEXT_KEY(119 downto 112) <= ( TK2_PERMUTED(49) xor TK2_PERMUTED(55) ) & ( TK2_PERMUTED(48) xor TK2_PERMUTED(54) ) & TK2_PERMUTED(55) & TK2_PERMUTED(54) & TK2_PERMUTED(53) & TK2_PERMUTED(52) & TK2_PERMUTED(51) & TK2_PERMUTED(50);
    NEXT_KEY(127 downto 120) <= ( TK2_PERMUTED(57) xor TK2_PERMUTED(63) ) & ( TK2_PERMUTED(56) xor TK2_PERMUTED(62) ) & TK2_PERMUTED(63) & TK2_PERMUTED(62) & TK2_PERMUTED(61) & TK2_PERMUTED(60) & TK2_PERMUTED(59) & TK2_PERMUTED(58);

    -- TK3^28
    TK3(63 downto 0) <= KEY(63 DOWNTO 0);
    -- Generating the following permutation: [5, 6, 3, 2, 7, 0, 1, 4, 13, 14, 11, 10, 15, 8, 9, 12]
	TK3_PERMUTED((8 * W - 1) downto (7 * W)) <= TK3((3 * W - 1) downto (2 * W));
	TK3_PERMUTED((7 * W - 1) downto (6 * W)) <= TK3((2 * W - 1) downto (1 * W));
	TK3_PERMUTED((6 * W - 1) downto (5 * W)) <= TK3((5 * W - 1) downto (4 * W));
	TK3_PERMUTED((5 * W - 1) downto (4 * W)) <= TK3((6 * W - 1) downto (5 * W));
	TK3_PERMUTED((4 * W - 1) downto (3 * W)) <= TK3((1 * W - 1) downto (0 * W));
	TK3_PERMUTED((3 * W - 1) downto (2 * W)) <= TK3((8 * W - 1) downto (7 * W));
	TK3_PERMUTED((2 * W - 1) downto (1 * W)) <= TK3((7 * W - 1) downto (6 * W));
	TK3_PERMUTED((1 * W - 1) downto (0 * W)) <= TK3((4 * W - 1) downto (3 * W));

    -- Lower half of the state
    NEXT_KEY(7 downto 0) <= TK3_PERMUTED(5) & TK3_PERMUTED(4) & TK3_PERMUTED(3) & TK3_PERMUTED(2) & TK3_PERMUTED(1) & TK3_PERMUTED(0) & ( TK3_PERMUTED(5) xor TK3_PERMUTED(7) ) & ( TK3_PERMUTED(4) xor TK3_PERMUTED(6) );
    NEXT_KEY(15 downto 8) <= TK3_PERMUTED(13) & TK3_PERMUTED(12) & TK3_PERMUTED(11) & TK3_PERMUTED(10) & TK3_PERMUTED(9) & TK3_PERMUTED(8) & ( TK3_PERMUTED(13) xor TK3_PERMUTED(15) ) & ( TK3_PERMUTED(12) xor TK3_PERMUTED(14) );
    NEXT_KEY(23 downto 16) <= TK3_PERMUTED(21) & TK3_PERMUTED(20) & TK3_PERMUTED(19) & TK3_PERMUTED(18) & TK3_PERMUTED(17) & TK3_PERMUTED(16) & ( TK3_PERMUTED(21) xor TK3_PERMUTED(23) ) & ( TK3_PERMUTED(20) xor TK3_PERMUTED(22) );
    NEXT_KEY(31 downto 24) <= TK3_PERMUTED(29) & TK3_PERMUTED(28) & TK3_PERMUTED(27) & TK3_PERMUTED(26) & TK3_PERMUTED(25) & TK3_PERMUTED(24) & ( TK3_PERMUTED(29) xor TK3_PERMUTED(31) ) & ( TK3_PERMUTED(28) xor TK3_PERMUTED(30) );
    NEXT_KEY(39 downto 32) <= TK3_PERMUTED(37) & TK3_PERMUTED(36) & TK3_PERMUTED(35) & TK3_PERMUTED(34) & TK3_PERMUTED(33) & TK3_PERMUTED(32) & ( TK3_PERMUTED(37) xor TK3_PERMUTED(39) ) & ( TK3_PERMUTED(36) xor TK3_PERMUTED(38) );
    NEXT_KEY(47 downto 40) <= TK3_PERMUTED(45) & TK3_PERMUTED(44) & TK3_PERMUTED(43) & TK3_PERMUTED(42) & TK3_PERMUTED(41) & TK3_PERMUTED(40) & ( TK3_PERMUTED(45) xor TK3_PERMUTED(47) ) & ( TK3_PERMUTED(44) xor TK3_PERMUTED(46) );
    NEXT_KEY(55 downto 48) <= TK3_PERMUTED(53) & TK3_PERMUTED(52) & TK3_PERMUTED(51) & TK3_PERMUTED(50) & TK3_PERMUTED(49) & TK3_PERMUTED(48) & ( TK3_PERMUTED(53) xor TK3_PERMUTED(55) ) & ( TK3_PERMUTED(52) xor TK3_PERMUTED(54) );
    NEXT_KEY(63 downto 56) <= TK3_PERMUTED(61) & TK3_PERMUTED(60) & TK3_PERMUTED(59) & TK3_PERMUTED(58) & TK3_PERMUTED(57) & TK3_PERMUTED(56) & ( TK3_PERMUTED(61) xor TK3_PERMUTED(63) ) & ( TK3_PERMUTED(60) xor TK3_PERMUTED(62) );
    end generate;

	
END behav;



-----------------------------
-- Fast Forward Key Schedule
-----------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

use work.Forkskinnypkg.all;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY KeyExpansionFF IS
	GENERIC (BS : BLOCK_SIZE; TS : TWEAK_SIZE);
	PORT (KEY			: IN  STD_LOGIC_VECTOR ((GET_TWEAK_SIZE(BS, TS) - 1) DOWNTO 0);
          KEY_FF	: OUT STD_LOGIC_VECTOR ((GET_TWEAK_SIZE(BS, TS) - 1) DOWNTO 0));
END KeyExpansionFF;

ARCHITECTURE Mixed OF KeyExpansionFF IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT N : INTEGER := GET_BLOCK_SIZE(BS);
	CONSTANT T : INTEGER := GET_TWEAK_SIZE(BS, TS);
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);
	
	-- SIGNALS --------------------------------------------------------------------
	SIGNAL TK1, TK1_FF, TK2, TK2_FF, TK2_PERMUTED : STD_LOGIC_VECTOR((N - 1) DOWNTO 0);
	SIGNAL TK3, TK3_FF, TK3_PERMUTED : STD_LOGIC_VECTOR((N - 1) DOWNTO 0);

begin

    -- Input assigment
    TK1 <= KEY(T-1 downto T-N);

    -- Assign to output
    KEY_FF(T-1 downto T-N) <= TK1_FF;

    ASSIGN_TK2: if TS = TWEAK_SIZE_2N or TS = TWEAK_SIZE_3o2N generate
        TK2(T-N-1 downto 0) <= KEY(T-N-1 downto 0);
        KEY_FF(T-N-1 downto 0) <= TK2_FF(T-N-1 downto 0);
    end generate;

    ASSIGN_TK3: if TS = TWEAK_SIZE_3N or TS = TWEAK_SIZE_9o4N generate
        TK2 <= KEY(T-N-1 downto T-2*N);
        TK3(T-2*N-1 downto 0) <= KEY(T-2*N-1 downto 0);
        KEY_FF(T-N-1 downto T-2*N) <= TK2_FF;
        KEY_FF(T-2*N-1 downto 0) <= TK3_FF(T-2*N-1 downto 0);
    end generate;


    FF_64_192 : IF (BS = BLOCK_SIZE_64 AND TS = TWEAK_SIZE_3N) GENERATE

        -- Generating the following permutation: [13, 14, 11, 10, 15, 8, 9, 12, 3, 5, 7, 4, 1, 2, 0, 6]
        TK1_FF((16 * W - 1) downto (15 * W)) <= TK1((3 * W - 1) downto (2 * W));
        TK1_FF((15 * W - 1) downto (14 * W)) <= TK1((2 * W - 1) downto (1 * W));
        TK1_FF((14 * W - 1) downto (13 * W)) <= TK1((5 * W - 1) downto (4 * W));
        TK1_FF((13 * W - 1) downto (12 * W)) <= TK1((6 * W - 1) downto (5 * W));
        TK1_FF((12 * W - 1) downto (11 * W)) <= TK1((1 * W - 1) downto (0 * W));
        TK1_FF((11 * W - 1) downto (10 * W)) <= TK1((8 * W - 1) downto (7 * W));
        TK1_FF((10 * W - 1) downto (9 * W)) <= TK1((7 * W - 1) downto (6 * W));
        TK1_FF((9 * W - 1) downto (8 * W)) <= TK1((4 * W - 1) downto (3 * W));
        TK1_FF((8 * W - 1) downto (7 * W)) <= TK1((13 * W - 1) downto (12 * W));
        TK1_FF((7 * W - 1) downto (6 * W)) <= TK1((11 * W - 1) downto (10 * W));
        TK1_FF((6 * W - 1) downto (5 * W)) <= TK1((9 * W - 1) downto (8 * W));
        TK1_FF((5 * W - 1) downto (4 * W)) <= TK1((12 * W - 1) downto (11 * W));
        TK1_FF((4 * W - 1) downto (3 * W)) <= TK1((15 * W - 1) downto (14 * W));
        TK1_FF((3 * W - 1) downto (2 * W)) <= TK1((14 * W - 1) downto (13 * W));
        TK1_FF((2 * W - 1) downto (1 * W)) <= TK1((16 * W - 1) downto (15 * W));
        TK1_FF((1 * W - 1) downto (0 * W)) <= TK1((10 * W - 1) downto (9 * W));

        -- Generating the following permutation: [13, 14, 11, 10, 15, 8, 9, 12, 3, 5, 7, 4, 1, 2, 0, 6]
        TK2_PERMUTED((16 * W - 1) downto (15 * W)) <= TK2((3 * W - 1) downto (2 * W));
        TK2_PERMUTED((15 * W - 1) downto (14 * W)) <= TK2((2 * W - 1) downto (1 * W));
        TK2_PERMUTED((14 * W - 1) downto (13 * W)) <= TK2((5 * W - 1) downto (4 * W));
        TK2_PERMUTED((13 * W - 1) downto (12 * W)) <= TK2((6 * W - 1) downto (5 * W));
        TK2_PERMUTED((12 * W - 1) downto (11 * W)) <= TK2((1 * W - 1) downto (0 * W));
        TK2_PERMUTED((11 * W - 1) downto (10 * W)) <= TK2((8 * W - 1) downto (7 * W));
        TK2_PERMUTED((10 * W - 1) downto (9 * W)) <= TK2((7 * W - 1) downto (6 * W));
        TK2_PERMUTED((9 * W - 1) downto (8 * W)) <= TK2((4 * W - 1) downto (3 * W));
        TK2_PERMUTED((8 * W - 1) downto (7 * W)) <= TK2((13 * W - 1) downto (12 * W));
        TK2_PERMUTED((7 * W - 1) downto (6 * W)) <= TK2((11 * W - 1) downto (10 * W));
        TK2_PERMUTED((6 * W - 1) downto (5 * W)) <= TK2((9 * W - 1) downto (8 * W));
        TK2_PERMUTED((5 * W - 1) downto (4 * W)) <= TK2((12 * W - 1) downto (11 * W));
        TK2_PERMUTED((4 * W - 1) downto (3 * W)) <= TK2((15 * W - 1) downto (14 * W));
        TK2_PERMUTED((3 * W - 1) downto (2 * W)) <= TK2((14 * W - 1) downto (13 * W));
        TK2_PERMUTED((2 * W - 1) downto (1 * W)) <= TK2((16 * W - 1) downto (15 * W));
        TK2_PERMUTED((1 * W - 1) downto (0 * W)) <= TK2((10 * W - 1) downto (9 * W));

    -- Upper half of the state
    TK2_FF(35 downto 32) <= ( TK2_PERMUTED(32) xor TK2_PERMUTED(33) xor TK2_PERMUTED(34) xor TK2_PERMUTED(35) ) & ( TK2_PERMUTED(32) xor TK2_PERMUTED(33) xor TK2_PERMUTED(35) ) & ( TK2_PERMUTED(32) xor TK2_PERMUTED(35) ) & TK2_PERMUTED(35);
    TK2_FF(39 downto 36) <= ( TK2_PERMUTED(36) xor TK2_PERMUTED(37) xor TK2_PERMUTED(38) xor TK2_PERMUTED(39) ) & ( TK2_PERMUTED(36) xor TK2_PERMUTED(37) xor TK2_PERMUTED(39) ) & ( TK2_PERMUTED(36) xor TK2_PERMUTED(39) ) & TK2_PERMUTED(39);
    TK2_FF(43 downto 40) <= ( TK2_PERMUTED(40) xor TK2_PERMUTED(41) xor TK2_PERMUTED(42) xor TK2_PERMUTED(43) ) & ( TK2_PERMUTED(40) xor TK2_PERMUTED(41) xor TK2_PERMUTED(43) ) & ( TK2_PERMUTED(40) xor TK2_PERMUTED(43) ) & TK2_PERMUTED(43);
    TK2_FF(47 downto 44) <= ( TK2_PERMUTED(44) xor TK2_PERMUTED(45) xor TK2_PERMUTED(46) xor TK2_PERMUTED(47) ) & ( TK2_PERMUTED(44) xor TK2_PERMUTED(45) xor TK2_PERMUTED(47) ) & ( TK2_PERMUTED(44) xor TK2_PERMUTED(47) ) & TK2_PERMUTED(47);
    TK2_FF(51 downto 48) <= ( TK2_PERMUTED(48) xor TK2_PERMUTED(49) xor TK2_PERMUTED(50) xor TK2_PERMUTED(51) ) & ( TK2_PERMUTED(48) xor TK2_PERMUTED(49) xor TK2_PERMUTED(51) ) & ( TK2_PERMUTED(48) xor TK2_PERMUTED(51) ) & TK2_PERMUTED(51);
    TK2_FF(55 downto 52) <= ( TK2_PERMUTED(52) xor TK2_PERMUTED(53) xor TK2_PERMUTED(54) xor TK2_PERMUTED(55) ) & ( TK2_PERMUTED(52) xor TK2_PERMUTED(53) xor TK2_PERMUTED(55) ) & ( TK2_PERMUTED(52) xor TK2_PERMUTED(55) ) & TK2_PERMUTED(55);
    TK2_FF(59 downto 56) <= ( TK2_PERMUTED(56) xor TK2_PERMUTED(57) xor TK2_PERMUTED(58) xor TK2_PERMUTED(59) ) & ( TK2_PERMUTED(56) xor TK2_PERMUTED(57) xor TK2_PERMUTED(59) ) & ( TK2_PERMUTED(56) xor TK2_PERMUTED(59) ) & TK2_PERMUTED(59);
    TK2_FF(63 downto 60) <= ( TK2_PERMUTED(60) xor TK2_PERMUTED(61) xor TK2_PERMUTED(62) xor TK2_PERMUTED(63) ) & ( TK2_PERMUTED(60) xor TK2_PERMUTED(61) xor TK2_PERMUTED(63) ) & ( TK2_PERMUTED(60) xor TK2_PERMUTED(63) ) & TK2_PERMUTED(63);
    -- Lower half of the state
    TK2_FF(3 downto 0) <= ( TK2_PERMUTED(0) xor TK2_PERMUTED(1) xor TK2_PERMUTED(2) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(1) xor TK2_PERMUTED(2) xor TK2_PERMUTED(3) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(1) xor TK2_PERMUTED(3) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(3) );
    TK2_FF(7 downto 4) <= ( TK2_PERMUTED(4) xor TK2_PERMUTED(5) xor TK2_PERMUTED(6) ) & ( TK2_PERMUTED(4) xor TK2_PERMUTED(5) xor TK2_PERMUTED(6) xor TK2_PERMUTED(7) ) & ( TK2_PERMUTED(4) xor TK2_PERMUTED(5) xor TK2_PERMUTED(7) ) & ( TK2_PERMUTED(4) xor TK2_PERMUTED(7) );
    TK2_FF(11 downto 8) <= ( TK2_PERMUTED(8) xor TK2_PERMUTED(9) xor TK2_PERMUTED(10) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(9) xor TK2_PERMUTED(10) xor TK2_PERMUTED(11) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(9) xor TK2_PERMUTED(11) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(11) );
    TK2_FF(15 downto 12) <= ( TK2_PERMUTED(12) xor TK2_PERMUTED(13) xor TK2_PERMUTED(14) ) & ( TK2_PERMUTED(12) xor TK2_PERMUTED(13) xor TK2_PERMUTED(14) xor TK2_PERMUTED(15) ) & ( TK2_PERMUTED(12) xor TK2_PERMUTED(13) xor TK2_PERMUTED(15) ) & ( TK2_PERMUTED(12) xor TK2_PERMUTED(15) );
    TK2_FF(19 downto 16) <= ( TK2_PERMUTED(16) xor TK2_PERMUTED(17) xor TK2_PERMUTED(18) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(17) xor TK2_PERMUTED(18) xor TK2_PERMUTED(19) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(17) xor TK2_PERMUTED(19) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(19) );
    TK2_FF(23 downto 20) <= ( TK2_PERMUTED(20) xor TK2_PERMUTED(21) xor TK2_PERMUTED(22) ) & ( TK2_PERMUTED(20) xor TK2_PERMUTED(21) xor TK2_PERMUTED(22) xor TK2_PERMUTED(23) ) & ( TK2_PERMUTED(20) xor TK2_PERMUTED(21) xor TK2_PERMUTED(23) ) & ( TK2_PERMUTED(20) xor TK2_PERMUTED(23) );
    TK2_FF(27 downto 24) <= ( TK2_PERMUTED(24) xor TK2_PERMUTED(25) xor TK2_PERMUTED(26) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(25) xor TK2_PERMUTED(26) xor TK2_PERMUTED(27) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(25) xor TK2_PERMUTED(27) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(27) );
    TK2_FF(31 downto 28) <= ( TK2_PERMUTED(28) xor TK2_PERMUTED(29) xor TK2_PERMUTED(30) ) & ( TK2_PERMUTED(28) xor TK2_PERMUTED(29) xor TK2_PERMUTED(30) xor TK2_PERMUTED(31) ) & ( TK2_PERMUTED(28) xor TK2_PERMUTED(29) xor TK2_PERMUTED(31) ) & ( TK2_PERMUTED(28) xor TK2_PERMUTED(31) );


    -- Generating the following permutation: [13, 14, 11, 10, 15, 8, 9, 12, 3, 5, 7, 4, 1, 2, 0, 6]
	TK3_PERMUTED((16 * W - 1) downto (15 * W)) <= TK3((3 * W - 1) downto (2 * W));
	TK3_PERMUTED((15 * W - 1) downto (14 * W)) <= TK3((2 * W - 1) downto (1 * W));
	TK3_PERMUTED((14 * W - 1) downto (13 * W)) <= TK3((5 * W - 1) downto (4 * W));
	TK3_PERMUTED((13 * W - 1) downto (12 * W)) <= TK3((6 * W - 1) downto (5 * W));
	TK3_PERMUTED((12 * W - 1) downto (11 * W)) <= TK3((1 * W - 1) downto (0 * W));
	TK3_PERMUTED((11 * W - 1) downto (10 * W)) <= TK3((8 * W - 1) downto (7 * W));
	TK3_PERMUTED((10 * W - 1) downto (9 * W)) <= TK3((7 * W - 1) downto (6 * W));
	TK3_PERMUTED((9 * W - 1) downto (8 * W)) <= TK3((4 * W - 1) downto (3 * W));
	TK3_PERMUTED((8 * W - 1) downto (7 * W)) <= TK3((13 * W - 1) downto (12 * W));
	TK3_PERMUTED((7 * W - 1) downto (6 * W)) <= TK3((11 * W - 1) downto (10 * W));
	TK3_PERMUTED((6 * W - 1) downto (5 * W)) <= TK3((9 * W - 1) downto (8 * W));
	TK3_PERMUTED((5 * W - 1) downto (4 * W)) <= TK3((12 * W - 1) downto (11 * W));
	TK3_PERMUTED((4 * W - 1) downto (3 * W)) <= TK3((15 * W - 1) downto (14 * W));
	TK3_PERMUTED((3 * W - 1) downto (2 * W)) <= TK3((14 * W - 1) downto (13 * W));
	TK3_PERMUTED((2 * W - 1) downto (1 * W)) <= TK3((16 * W - 1) downto (15 * W));
	TK3_PERMUTED((1 * W - 1) downto (0 * W)) <= TK3((10 * W - 1) downto (9 * W));
    
    -- Upper half of the state
    TK3_FF(35 downto 32) <= TK3_PERMUTED(32) & ( TK3_PERMUTED(34) xor TK3_PERMUTED(35) ) & ( TK3_PERMUTED(33) xor TK3_PERMUTED(34) ) & ( TK3_PERMUTED(32) xor TK3_PERMUTED(33) );
    TK3_FF(39 downto 36) <= TK3_PERMUTED(36) & ( TK3_PERMUTED(38) xor TK3_PERMUTED(39) ) & ( TK3_PERMUTED(37) xor TK3_PERMUTED(38) ) & ( TK3_PERMUTED(36) xor TK3_PERMUTED(37) );
    TK3_FF(43 downto 40) <= TK3_PERMUTED(40) & ( TK3_PERMUTED(42) xor TK3_PERMUTED(43) ) & ( TK3_PERMUTED(41) xor TK3_PERMUTED(42) ) & ( TK3_PERMUTED(40) xor TK3_PERMUTED(41) );
    TK3_FF(47 downto 44) <= TK3_PERMUTED(44) & ( TK3_PERMUTED(46) xor TK3_PERMUTED(47) ) & ( TK3_PERMUTED(45) xor TK3_PERMUTED(46) ) & ( TK3_PERMUTED(44) xor TK3_PERMUTED(45) );
    TK3_FF(51 downto 48) <= TK3_PERMUTED(48) & ( TK3_PERMUTED(50) xor TK3_PERMUTED(51) ) & ( TK3_PERMUTED(49) xor TK3_PERMUTED(50) ) & ( TK3_PERMUTED(48) xor TK3_PERMUTED(49) );
    TK3_FF(55 downto 52) <= TK3_PERMUTED(52) & ( TK3_PERMUTED(54) xor TK3_PERMUTED(55) ) & ( TK3_PERMUTED(53) xor TK3_PERMUTED(54) ) & ( TK3_PERMUTED(52) xor TK3_PERMUTED(53) );
    TK3_FF(59 downto 56) <= TK3_PERMUTED(56) & ( TK3_PERMUTED(58) xor TK3_PERMUTED(59) ) & ( TK3_PERMUTED(57) xor TK3_PERMUTED(58) ) & ( TK3_PERMUTED(56) xor TK3_PERMUTED(57) );
    TK3_FF(63 downto 60) <= TK3_PERMUTED(60) & ( TK3_PERMUTED(62) xor TK3_PERMUTED(63) ) & ( TK3_PERMUTED(61) xor TK3_PERMUTED(62) ) & ( TK3_PERMUTED(60) xor TK3_PERMUTED(61) );
    -- Lower half of the state
    TK3_FF(3 downto 0) <= ( TK3_PERMUTED(2) xor TK3_PERMUTED(3) ) & ( TK3_PERMUTED(1) xor TK3_PERMUTED(2) ) & ( TK3_PERMUTED(0) xor TK3_PERMUTED(1) ) & ( TK3_PERMUTED(0) xor TK3_PERMUTED(2) xor TK3_PERMUTED(3) );
    TK3_FF(7 downto 4) <= ( TK3_PERMUTED(6) xor TK3_PERMUTED(7) ) & ( TK3_PERMUTED(5) xor TK3_PERMUTED(6) ) & ( TK3_PERMUTED(4) xor TK3_PERMUTED(5) ) & ( TK3_PERMUTED(4) xor TK3_PERMUTED(6) xor TK3_PERMUTED(7) );
    TK3_FF(11 downto 8) <= ( TK3_PERMUTED(10) xor TK3_PERMUTED(11) ) & ( TK3_PERMUTED(9) xor TK3_PERMUTED(10) ) & ( TK3_PERMUTED(8) xor TK3_PERMUTED(9) ) & ( TK3_PERMUTED(8) xor TK3_PERMUTED(10) xor TK3_PERMUTED(11) );
    TK3_FF(15 downto 12) <= ( TK3_PERMUTED(14) xor TK3_PERMUTED(15) ) & ( TK3_PERMUTED(13) xor TK3_PERMUTED(14) ) & ( TK3_PERMUTED(12) xor TK3_PERMUTED(13) ) & ( TK3_PERMUTED(12) xor TK3_PERMUTED(14) xor TK3_PERMUTED(15) );
    TK3_FF(19 downto 16) <= ( TK3_PERMUTED(18) xor TK3_PERMUTED(19) ) & ( TK3_PERMUTED(17) xor TK3_PERMUTED(18) ) & ( TK3_PERMUTED(16) xor TK3_PERMUTED(17) ) & ( TK3_PERMUTED(16) xor TK3_PERMUTED(18) xor TK3_PERMUTED(19) );
    TK3_FF(23 downto 20) <= ( TK3_PERMUTED(22) xor TK3_PERMUTED(23) ) & ( TK3_PERMUTED(21) xor TK3_PERMUTED(22) ) & ( TK3_PERMUTED(20) xor TK3_PERMUTED(21) ) & ( TK3_PERMUTED(20) xor TK3_PERMUTED(22) xor TK3_PERMUTED(23) );
    TK3_FF(27 downto 24) <= ( TK3_PERMUTED(26) xor TK3_PERMUTED(27) ) & ( TK3_PERMUTED(25) xor TK3_PERMUTED(26) ) & ( TK3_PERMUTED(24) xor TK3_PERMUTED(25) ) & ( TK3_PERMUTED(24) xor TK3_PERMUTED(26) xor TK3_PERMUTED(27) );
    TK3_FF(31 downto 28) <= ( TK3_PERMUTED(30) xor TK3_PERMUTED(31) ) & ( TK3_PERMUTED(29) xor TK3_PERMUTED(30) ) & ( TK3_PERMUTED(28) xor TK3_PERMUTED(29) ) & ( TK3_PERMUTED(28) xor TK3_PERMUTED(30) xor TK3_PERMUTED(31) );
    end generate;


    FF_128_192 : IF (BS = BLOCK_SIZE_128 AND TS = TWEAK_SIZE_3o2N) GENERATE



        -- 27-times FORWARD application of TK1 schedule
        -- Generating the following permutation: [12, 10, 14, 9, 13, 15, 11, 8, 6, 4, 5, 0, 3, 1, 7, 2]
        TK1_FF((16 * W - 1) downto (15 * W)) <= TK1((4 * W - 1) downto (3 * W));
        TK1_FF((15 * W - 1) downto (14 * W)) <= TK1((6 * W - 1) downto (5 * W));
        TK1_FF((14 * W - 1) downto (13 * W)) <= TK1((2 * W - 1) downto (1 * W));
        TK1_FF((13 * W - 1) downto (12 * W)) <= TK1((7 * W - 1) downto (6 * W));
        TK1_FF((12 * W - 1) downto (11 * W)) <= TK1((3 * W - 1) downto (2 * W));
        TK1_FF((11 * W - 1) downto (10 * W)) <= TK1((1 * W - 1) downto (0 * W));
        TK1_FF((10 * W - 1) downto (9 * W)) <= TK1((5 * W - 1) downto (4 * W));
        TK1_FF((9 * W - 1) downto (8 * W)) <= TK1((8 * W - 1) downto (7 * W));
        TK1_FF((8 * W - 1) downto (7 * W)) <= TK1((10 * W - 1) downto (9 * W));
        TK1_FF((7 * W - 1) downto (6 * W)) <= TK1((12 * W - 1) downto (11 * W));
        TK1_FF((6 * W - 1) downto (5 * W)) <= TK1((11 * W - 1) downto (10 * W));
        TK1_FF((5 * W - 1) downto (4 * W)) <= TK1((16 * W - 1) downto (15 * W));
        TK1_FF((4 * W - 1) downto (3 * W)) <= TK1((13 * W - 1) downto (12 * W));
        TK1_FF((3 * W - 1) downto (2 * W)) <= TK1((15 * W - 1) downto (14 * W));
        TK1_FF((2 * W - 1) downto (1 * W)) <= TK1((9 * W - 1) downto (8 * W));
        TK1_FF((1 * W - 1) downto (0 * W)) <= TK1((14 * W - 1) downto (13 * W));



        -- 26-times FORWARD application of TK2 schedule (note the 26 instead of 27)
        -- Generating the following permutation: [6, 4, 5, 0, 3, 1, 7, 2]
        TK2_PERMUTED((8 * W - 1) downto (7 * W)) <= TK2((2 * W - 1) downto (1 * W));
        TK2_PERMUTED((7 * W - 1) downto (6 * W)) <= TK2((4 * W - 1) downto (3 * W));
        TK2_PERMUTED((6 * W - 1) downto (5 * W)) <= TK2((3 * W - 1) downto (2 * W));
        TK2_PERMUTED((5 * W - 1) downto (4 * W)) <= TK2((8 * W - 1) downto (7 * W));
        TK2_PERMUTED((4 * W - 1) downto (3 * W)) <= TK2((5 * W - 1) downto (4 * W));
        TK2_PERMUTED((3 * W - 1) downto (2 * W)) <= TK2((7 * W - 1) downto (6 * W));
        TK2_PERMUTED((2 * W - 1) downto (1 * W)) <= TK2((1 * W - 1) downto (0 * W));
        TK2_PERMUTED((1 * W - 1) downto (0 * W)) <= TK2((6 * W - 1) downto (5 * W));
        
        -- Half of the state
        TK2_FF(7 downto 0) <= ( TK2_PERMUTED(0) xor TK2_PERMUTED(2) ) & ( TK2_PERMUTED(1) xor TK2_PERMUTED(5) xor TK2_PERMUTED(7) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(4) xor TK2_PERMUTED(6) ) & ( TK2_PERMUTED(3) xor TK2_PERMUTED(7) ) & ( TK2_PERMUTED(2) xor TK2_PERMUTED(6) ) & ( TK2_PERMUTED(1) xor TK2_PERMUTED(5) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(4) ) & ( TK2_PERMUTED(3) xor TK2_PERMUTED(5) xor TK2_PERMUTED(7) );
        TK2_FF(15 downto 8) <= ( TK2_PERMUTED(8) xor TK2_PERMUTED(10) ) & ( TK2_PERMUTED(9) xor TK2_PERMUTED(13) xor TK2_PERMUTED(15) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(12) xor TK2_PERMUTED(14) ) & ( TK2_PERMUTED(11) xor TK2_PERMUTED(15) ) & ( TK2_PERMUTED(10) xor TK2_PERMUTED(14) ) & ( TK2_PERMUTED(9) xor TK2_PERMUTED(13) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(12) ) & ( TK2_PERMUTED(11) xor TK2_PERMUTED(13) xor TK2_PERMUTED(15) );
        TK2_FF(23 downto 16) <= ( TK2_PERMUTED(16) xor TK2_PERMUTED(18) ) & ( TK2_PERMUTED(17) xor TK2_PERMUTED(21) xor TK2_PERMUTED(23) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(20) xor TK2_PERMUTED(22) ) & ( TK2_PERMUTED(19) xor TK2_PERMUTED(23) ) & ( TK2_PERMUTED(18) xor TK2_PERMUTED(22) ) & ( TK2_PERMUTED(17) xor TK2_PERMUTED(21) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(20) ) & ( TK2_PERMUTED(19) xor TK2_PERMUTED(21) xor TK2_PERMUTED(23) );
        TK2_FF(31 downto 24) <= ( TK2_PERMUTED(24) xor TK2_PERMUTED(26) ) & ( TK2_PERMUTED(25) xor TK2_PERMUTED(29) xor TK2_PERMUTED(31) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(28) xor TK2_PERMUTED(30) ) & ( TK2_PERMUTED(27) xor TK2_PERMUTED(31) ) & ( TK2_PERMUTED(26) xor TK2_PERMUTED(30) ) & ( TK2_PERMUTED(25) xor TK2_PERMUTED(29) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(28) ) & ( TK2_PERMUTED(27) xor TK2_PERMUTED(29) xor TK2_PERMUTED(31) );
        TK2_FF(39 downto 32) <= ( TK2_PERMUTED(32) xor TK2_PERMUTED(34) ) & ( TK2_PERMUTED(33) xor TK2_PERMUTED(37) xor TK2_PERMUTED(39) ) & ( TK2_PERMUTED(32) xor TK2_PERMUTED(36) xor TK2_PERMUTED(38) ) & ( TK2_PERMUTED(35) xor TK2_PERMUTED(39) ) & ( TK2_PERMUTED(34) xor TK2_PERMUTED(38) ) & ( TK2_PERMUTED(33) xor TK2_PERMUTED(37) ) & ( TK2_PERMUTED(32) xor TK2_PERMUTED(36) ) & ( TK2_PERMUTED(35) xor TK2_PERMUTED(37) xor TK2_PERMUTED(39) );
        TK2_FF(47 downto 40) <= ( TK2_PERMUTED(40) xor TK2_PERMUTED(42) ) & ( TK2_PERMUTED(41) xor TK2_PERMUTED(45) xor TK2_PERMUTED(47) ) & ( TK2_PERMUTED(40) xor TK2_PERMUTED(44) xor TK2_PERMUTED(46) ) & ( TK2_PERMUTED(43) xor TK2_PERMUTED(47) ) & ( TK2_PERMUTED(42) xor TK2_PERMUTED(46) ) & ( TK2_PERMUTED(41) xor TK2_PERMUTED(45) ) & ( TK2_PERMUTED(40) xor TK2_PERMUTED(44) ) & ( TK2_PERMUTED(43) xor TK2_PERMUTED(45) xor TK2_PERMUTED(47) );
        TK2_FF(55 downto 48) <= ( TK2_PERMUTED(48) xor TK2_PERMUTED(50) ) & ( TK2_PERMUTED(49) xor TK2_PERMUTED(53) xor TK2_PERMUTED(55) ) & ( TK2_PERMUTED(48) xor TK2_PERMUTED(52) xor TK2_PERMUTED(54) ) & ( TK2_PERMUTED(51) xor TK2_PERMUTED(55) ) & ( TK2_PERMUTED(50) xor TK2_PERMUTED(54) ) & ( TK2_PERMUTED(49) xor TK2_PERMUTED(53) ) & ( TK2_PERMUTED(48) xor TK2_PERMUTED(52) ) & ( TK2_PERMUTED(51) xor TK2_PERMUTED(53) xor TK2_PERMUTED(55) );
        TK2_FF(63 downto 56) <= ( TK2_PERMUTED(56) xor TK2_PERMUTED(58) ) & ( TK2_PERMUTED(57) xor TK2_PERMUTED(61) xor TK2_PERMUTED(63) ) & ( TK2_PERMUTED(56) xor TK2_PERMUTED(60) xor TK2_PERMUTED(62) ) & ( TK2_PERMUTED(59) xor TK2_PERMUTED(63) ) & ( TK2_PERMUTED(58) xor TK2_PERMUTED(62) ) & ( TK2_PERMUTED(57) xor TK2_PERMUTED(61) ) & ( TK2_PERMUTED(56) xor TK2_PERMUTED(60) ) & ( TK2_PERMUTED(59) xor TK2_PERMUTED(61) xor TK2_PERMUTED(63) );




    end generate;


    FF_128_256 : IF (BS = BLOCK_SIZE_128 AND TS = TWEAK_SIZE_2N) GENERATE

        -- Generating the following permutation: [12, 10, 14, 9, 13, 15, 11, 8, 6, 4, 5, 0, 3, 1, 7, 2]
        TK1_FF((16 * W - 1) downto (15 * W)) <= TK1((4 * W - 1) downto (3 * W));
        TK1_FF((15 * W - 1) downto (14 * W)) <= TK1((6 * W - 1) downto (5 * W));
        TK1_FF((14 * W - 1) downto (13 * W)) <= TK1((2 * W - 1) downto (1 * W));
        TK1_FF((13 * W - 1) downto (12 * W)) <= TK1((7 * W - 1) downto (6 * W));
        TK1_FF((12 * W - 1) downto (11 * W)) <= TK1((3 * W - 1) downto (2 * W));
        TK1_FF((11 * W - 1) downto (10 * W)) <= TK1((1 * W - 1) downto (0 * W));
        TK1_FF((10 * W - 1) downto (9 * W)) <= TK1((5 * W - 1) downto (4 * W));
        TK1_FF((9 * W - 1) downto (8 * W)) <= TK1((8 * W - 1) downto (7 * W));
        TK1_FF((8 * W - 1) downto (7 * W)) <= TK1((10 * W - 1) downto (9 * W));
        TK1_FF((7 * W - 1) downto (6 * W)) <= TK1((12 * W - 1) downto (11 * W));
        TK1_FF((6 * W - 1) downto (5 * W)) <= TK1((11 * W - 1) downto (10 * W));
        TK1_FF((5 * W - 1) downto (4 * W)) <= TK1((16 * W - 1) downto (15 * W));
        TK1_FF((4 * W - 1) downto (3 * W)) <= TK1((13 * W - 1) downto (12 * W));
        TK1_FF((3 * W - 1) downto (2 * W)) <= TK1((15 * W - 1) downto (14 * W));
        TK1_FF((2 * W - 1) downto (1 * W)) <= TK1((9 * W - 1) downto (8 * W));
        TK1_FF((1 * W - 1) downto (0 * W)) <= TK1((14 * W - 1) downto (13 * W));

        -- Generating the following permutation: [12, 10, 14, 9, 13, 15, 11, 8, 6, 4, 5, 0, 3, 1, 7, 2]
        TK2_PERMUTED((16 * W - 1) downto (15 * W)) <= TK2((4 * W - 1) downto (3 * W));
        TK2_PERMUTED((15 * W - 1) downto (14 * W)) <= TK2((6 * W - 1) downto (5 * W));
        TK2_PERMUTED((14 * W - 1) downto (13 * W)) <= TK2((2 * W - 1) downto (1 * W));
        TK2_PERMUTED((13 * W - 1) downto (12 * W)) <= TK2((7 * W - 1) downto (6 * W));
        TK2_PERMUTED((12 * W - 1) downto (11 * W)) <= TK2((3 * W - 1) downto (2 * W));
        TK2_PERMUTED((11 * W - 1) downto (10 * W)) <= TK2((1 * W - 1) downto (0 * W));
        TK2_PERMUTED((10 * W - 1) downto (9 * W)) <= TK2((5 * W - 1) downto (4 * W));
        TK2_PERMUTED((9 * W - 1) downto (8 * W)) <= TK2((8 * W - 1) downto (7 * W));
        TK2_PERMUTED((8 * W - 1) downto (7 * W)) <= TK2((10 * W - 1) downto (9 * W));
        TK2_PERMUTED((7 * W - 1) downto (6 * W)) <= TK2((12 * W - 1) downto (11 * W));
        TK2_PERMUTED((6 * W - 1) downto (5 * W)) <= TK2((11 * W - 1) downto (10 * W));
        TK2_PERMUTED((5 * W - 1) downto (4 * W)) <= TK2((16 * W - 1) downto (15 * W));
        TK2_PERMUTED((4 * W - 1) downto (3 * W)) <= TK2((13 * W - 1) downto (12 * W));
        TK2_PERMUTED((3 * W - 1) downto (2 * W)) <= TK2((15 * W - 1) downto (14 * W));
        TK2_PERMUTED((2 * W - 1) downto (1 * W)) <= TK2((9 * W - 1) downto (8 * W));
        TK2_PERMUTED((1 * W - 1) downto (0 * W)) <= TK2((14 * W - 1) downto (13 * W));

        -- Upper half of the state
        TK2_FF(71 downto 64) <= ( TK2_PERMUTED(65) xor TK2_PERMUTED(69) xor TK2_PERMUTED(71) ) & ( TK2_PERMUTED(64) xor TK2_PERMUTED(68) xor TK2_PERMUTED(70) ) & ( TK2_PERMUTED(67) xor TK2_PERMUTED(71) ) & ( TK2_PERMUTED(66) xor TK2_PERMUTED(70) ) & ( TK2_PERMUTED(65) xor TK2_PERMUTED(69) ) & ( TK2_PERMUTED(64) xor TK2_PERMUTED(68) ) & ( TK2_PERMUTED(67) xor TK2_PERMUTED(69) xor TK2_PERMUTED(71) ) & ( TK2_PERMUTED(66) xor TK2_PERMUTED(68) xor TK2_PERMUTED(70) );
        TK2_FF(79 downto 72) <= ( TK2_PERMUTED(73) xor TK2_PERMUTED(77) xor TK2_PERMUTED(79) ) & ( TK2_PERMUTED(72) xor TK2_PERMUTED(76) xor TK2_PERMUTED(78) ) & ( TK2_PERMUTED(75) xor TK2_PERMUTED(79) ) & ( TK2_PERMUTED(74) xor TK2_PERMUTED(78) ) & ( TK2_PERMUTED(73) xor TK2_PERMUTED(77) ) & ( TK2_PERMUTED(72) xor TK2_PERMUTED(76) ) & ( TK2_PERMUTED(75) xor TK2_PERMUTED(77) xor TK2_PERMUTED(79) ) & ( TK2_PERMUTED(74) xor TK2_PERMUTED(76) xor TK2_PERMUTED(78) );
        TK2_FF(87 downto 80) <= ( TK2_PERMUTED(81) xor TK2_PERMUTED(85) xor TK2_PERMUTED(87) ) & ( TK2_PERMUTED(80) xor TK2_PERMUTED(84) xor TK2_PERMUTED(86) ) & ( TK2_PERMUTED(83) xor TK2_PERMUTED(87) ) & ( TK2_PERMUTED(82) xor TK2_PERMUTED(86) ) & ( TK2_PERMUTED(81) xor TK2_PERMUTED(85) ) & ( TK2_PERMUTED(80) xor TK2_PERMUTED(84) ) & ( TK2_PERMUTED(83) xor TK2_PERMUTED(85) xor TK2_PERMUTED(87) ) & ( TK2_PERMUTED(82) xor TK2_PERMUTED(84) xor TK2_PERMUTED(86) );
        TK2_FF(95 downto 88) <= ( TK2_PERMUTED(89) xor TK2_PERMUTED(93) xor TK2_PERMUTED(95) ) & ( TK2_PERMUTED(88) xor TK2_PERMUTED(92) xor TK2_PERMUTED(94) ) & ( TK2_PERMUTED(91) xor TK2_PERMUTED(95) ) & ( TK2_PERMUTED(90) xor TK2_PERMUTED(94) ) & ( TK2_PERMUTED(89) xor TK2_PERMUTED(93) ) & ( TK2_PERMUTED(88) xor TK2_PERMUTED(92) ) & ( TK2_PERMUTED(91) xor TK2_PERMUTED(93) xor TK2_PERMUTED(95) ) & ( TK2_PERMUTED(90) xor TK2_PERMUTED(92) xor TK2_PERMUTED(94) );
        TK2_FF(103 downto 96) <= ( TK2_PERMUTED(97) xor TK2_PERMUTED(101) xor TK2_PERMUTED(103) ) & ( TK2_PERMUTED(96) xor TK2_PERMUTED(100) xor TK2_PERMUTED(102) ) & ( TK2_PERMUTED(99) xor TK2_PERMUTED(103) ) & ( TK2_PERMUTED(98) xor TK2_PERMUTED(102) ) & ( TK2_PERMUTED(97) xor TK2_PERMUTED(101) ) & ( TK2_PERMUTED(96) xor TK2_PERMUTED(100) ) & ( TK2_PERMUTED(99) xor TK2_PERMUTED(101) xor TK2_PERMUTED(103) ) & ( TK2_PERMUTED(98) xor TK2_PERMUTED(100) xor TK2_PERMUTED(102) );
        TK2_FF(111 downto 104) <= ( TK2_PERMUTED(105) xor TK2_PERMUTED(109) xor TK2_PERMUTED(111) ) & ( TK2_PERMUTED(104) xor TK2_PERMUTED(108) xor TK2_PERMUTED(110) ) & ( TK2_PERMUTED(107) xor TK2_PERMUTED(111) ) & ( TK2_PERMUTED(106) xor TK2_PERMUTED(110) ) & ( TK2_PERMUTED(105) xor TK2_PERMUTED(109) ) & ( TK2_PERMUTED(104) xor TK2_PERMUTED(108) ) & ( TK2_PERMUTED(107) xor TK2_PERMUTED(109) xor TK2_PERMUTED(111) ) & ( TK2_PERMUTED(106) xor TK2_PERMUTED(108) xor TK2_PERMUTED(110) );
        TK2_FF(119 downto 112) <= ( TK2_PERMUTED(113) xor TK2_PERMUTED(117) xor TK2_PERMUTED(119) ) & ( TK2_PERMUTED(112) xor TK2_PERMUTED(116) xor TK2_PERMUTED(118) ) & ( TK2_PERMUTED(115) xor TK2_PERMUTED(119) ) & ( TK2_PERMUTED(114) xor TK2_PERMUTED(118) ) & ( TK2_PERMUTED(113) xor TK2_PERMUTED(117) ) & ( TK2_PERMUTED(112) xor TK2_PERMUTED(116) ) & ( TK2_PERMUTED(115) xor TK2_PERMUTED(117) xor TK2_PERMUTED(119) ) & ( TK2_PERMUTED(114) xor TK2_PERMUTED(116) xor TK2_PERMUTED(118) );
        TK2_FF(127 downto 120) <= ( TK2_PERMUTED(121) xor TK2_PERMUTED(125) xor TK2_PERMUTED(127) ) & ( TK2_PERMUTED(120) xor TK2_PERMUTED(124) xor TK2_PERMUTED(126) ) & ( TK2_PERMUTED(123) xor TK2_PERMUTED(127) ) & ( TK2_PERMUTED(122) xor TK2_PERMUTED(126) ) & ( TK2_PERMUTED(121) xor TK2_PERMUTED(125) ) & ( TK2_PERMUTED(120) xor TK2_PERMUTED(124) ) & ( TK2_PERMUTED(123) xor TK2_PERMUTED(125) xor TK2_PERMUTED(127) ) & ( TK2_PERMUTED(122) xor TK2_PERMUTED(124) xor TK2_PERMUTED(126) );
        -- Lower half of the state
        TK2_FF(7 downto 0) <= ( TK2_PERMUTED(0) xor TK2_PERMUTED(2) ) & ( TK2_PERMUTED(1) xor TK2_PERMUTED(5) xor TK2_PERMUTED(7) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(4) xor TK2_PERMUTED(6) ) & ( TK2_PERMUTED(3) xor TK2_PERMUTED(7) ) & ( TK2_PERMUTED(2) xor TK2_PERMUTED(6) ) & ( TK2_PERMUTED(1) xor TK2_PERMUTED(5) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(4) ) & ( TK2_PERMUTED(3) xor TK2_PERMUTED(5) xor TK2_PERMUTED(7) );
        TK2_FF(15 downto 8) <= ( TK2_PERMUTED(8) xor TK2_PERMUTED(10) ) & ( TK2_PERMUTED(9) xor TK2_PERMUTED(13) xor TK2_PERMUTED(15) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(12) xor TK2_PERMUTED(14) ) & ( TK2_PERMUTED(11) xor TK2_PERMUTED(15) ) & ( TK2_PERMUTED(10) xor TK2_PERMUTED(14) ) & ( TK2_PERMUTED(9) xor TK2_PERMUTED(13) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(12) ) & ( TK2_PERMUTED(11) xor TK2_PERMUTED(13) xor TK2_PERMUTED(15) );
        TK2_FF(23 downto 16) <= ( TK2_PERMUTED(16) xor TK2_PERMUTED(18) ) & ( TK2_PERMUTED(17) xor TK2_PERMUTED(21) xor TK2_PERMUTED(23) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(20) xor TK2_PERMUTED(22) ) & ( TK2_PERMUTED(19) xor TK2_PERMUTED(23) ) & ( TK2_PERMUTED(18) xor TK2_PERMUTED(22) ) & ( TK2_PERMUTED(17) xor TK2_PERMUTED(21) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(20) ) & ( TK2_PERMUTED(19) xor TK2_PERMUTED(21) xor TK2_PERMUTED(23) );
        TK2_FF(31 downto 24) <= ( TK2_PERMUTED(24) xor TK2_PERMUTED(26) ) & ( TK2_PERMUTED(25) xor TK2_PERMUTED(29) xor TK2_PERMUTED(31) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(28) xor TK2_PERMUTED(30) ) & ( TK2_PERMUTED(27) xor TK2_PERMUTED(31) ) & ( TK2_PERMUTED(26) xor TK2_PERMUTED(30) ) & ( TK2_PERMUTED(25) xor TK2_PERMUTED(29) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(28) ) & ( TK2_PERMUTED(27) xor TK2_PERMUTED(29) xor TK2_PERMUTED(31) );
        TK2_FF(39 downto 32) <= ( TK2_PERMUTED(32) xor TK2_PERMUTED(34) ) & ( TK2_PERMUTED(33) xor TK2_PERMUTED(37) xor TK2_PERMUTED(39) ) & ( TK2_PERMUTED(32) xor TK2_PERMUTED(36) xor TK2_PERMUTED(38) ) & ( TK2_PERMUTED(35) xor TK2_PERMUTED(39) ) & ( TK2_PERMUTED(34) xor TK2_PERMUTED(38) ) & ( TK2_PERMUTED(33) xor TK2_PERMUTED(37) ) & ( TK2_PERMUTED(32) xor TK2_PERMUTED(36) ) & ( TK2_PERMUTED(35) xor TK2_PERMUTED(37) xor TK2_PERMUTED(39) );
        TK2_FF(47 downto 40) <= ( TK2_PERMUTED(40) xor TK2_PERMUTED(42) ) & ( TK2_PERMUTED(41) xor TK2_PERMUTED(45) xor TK2_PERMUTED(47) ) & ( TK2_PERMUTED(40) xor TK2_PERMUTED(44) xor TK2_PERMUTED(46) ) & ( TK2_PERMUTED(43) xor TK2_PERMUTED(47) ) & ( TK2_PERMUTED(42) xor TK2_PERMUTED(46) ) & ( TK2_PERMUTED(41) xor TK2_PERMUTED(45) ) & ( TK2_PERMUTED(40) xor TK2_PERMUTED(44) ) & ( TK2_PERMUTED(43) xor TK2_PERMUTED(45) xor TK2_PERMUTED(47) );
        TK2_FF(55 downto 48) <= ( TK2_PERMUTED(48) xor TK2_PERMUTED(50) ) & ( TK2_PERMUTED(49) xor TK2_PERMUTED(53) xor TK2_PERMUTED(55) ) & ( TK2_PERMUTED(48) xor TK2_PERMUTED(52) xor TK2_PERMUTED(54) ) & ( TK2_PERMUTED(51) xor TK2_PERMUTED(55) ) & ( TK2_PERMUTED(50) xor TK2_PERMUTED(54) ) & ( TK2_PERMUTED(49) xor TK2_PERMUTED(53) ) & ( TK2_PERMUTED(48) xor TK2_PERMUTED(52) ) & ( TK2_PERMUTED(51) xor TK2_PERMUTED(53) xor TK2_PERMUTED(55) );
        TK2_FF(63 downto 56) <= ( TK2_PERMUTED(56) xor TK2_PERMUTED(58) ) & ( TK2_PERMUTED(57) xor TK2_PERMUTED(61) xor TK2_PERMUTED(63) ) & ( TK2_PERMUTED(56) xor TK2_PERMUTED(60) xor TK2_PERMUTED(62) ) & ( TK2_PERMUTED(59) xor TK2_PERMUTED(63) ) & ( TK2_PERMUTED(58) xor TK2_PERMUTED(62) ) & ( TK2_PERMUTED(57) xor TK2_PERMUTED(61) ) & ( TK2_PERMUTED(56) xor TK2_PERMUTED(60) ) & ( TK2_PERMUTED(59) xor TK2_PERMUTED(61) xor TK2_PERMUTED(63) );
    end generate;



    FF_128_288 : IF (BS = BLOCK_SIZE_128 AND (TS = TWEAK_SIZE_3N or TS = TWEAK_SIZE_9o4N)) GENERATE

        -- 31-times FORWARD application of TK1 schedule
        -- Generating the following permutation: [8, 9, 10, 11, 12, 13, 14, 15, 2, 0, 4, 7, 6, 3, 5, 1]
        TK1_FF((16 * W - 1) downto (15 * W)) <= TK1((8 * W - 1) downto (7 * W));
        TK1_FF((15 * W - 1) downto (14 * W)) <= TK1((7 * W - 1) downto (6 * W));
        TK1_FF((14 * W - 1) downto (13 * W)) <= TK1((6 * W - 1) downto (5 * W));
        TK1_FF((13 * W - 1) downto (12 * W)) <= TK1((5 * W - 1) downto (4 * W));
        TK1_FF((12 * W - 1) downto (11 * W)) <= TK1((4 * W - 1) downto (3 * W));
        TK1_FF((11 * W - 1) downto (10 * W)) <= TK1((3 * W - 1) downto (2 * W));
        TK1_FF((10 * W - 1) downto (9 * W)) <= TK1((2 * W - 1) downto (1 * W));
        TK1_FF((9 * W - 1) downto (8 * W)) <= TK1((1 * W - 1) downto (0 * W));
        TK1_FF((8 * W - 1) downto (7 * W)) <= TK1((14 * W - 1) downto (13 * W));
        TK1_FF((7 * W - 1) downto (6 * W)) <= TK1((16 * W - 1) downto (15 * W));
        TK1_FF((6 * W - 1) downto (5 * W)) <= TK1((12 * W - 1) downto (11 * W));
        TK1_FF((5 * W - 1) downto (4 * W)) <= TK1((9 * W - 1) downto (8 * W));
        TK1_FF((4 * W - 1) downto (3 * W)) <= TK1((10 * W - 1) downto (9 * W));
        TK1_FF((3 * W - 1) downto (2 * W)) <= TK1((13 * W - 1) downto (12 * W));
        TK1_FF((2 * W - 1) downto (1 * W)) <= TK1((11 * W - 1) downto (10 * W));
        TK1_FF((1 * W - 1) downto (0 * W)) <= TK1((15 * W - 1) downto (14 * W));

        -- 31-times FORWARD application of TK2 schedule
        -- Generating the following permutation: [8, 9, 10, 11, 12, 13, 14, 15, 2, 0, 4, 7, 6, 3, 5, 1]
        TK2_PERMUTED((16 * W - 1) downto (15 * W)) <= TK2((8 * W - 1) downto (7 * W));
        TK2_PERMUTED((15 * W - 1) downto (14 * W)) <= TK2((7 * W - 1) downto (6 * W));
        TK2_PERMUTED((14 * W - 1) downto (13 * W)) <= TK2((6 * W - 1) downto (5 * W));
        TK2_PERMUTED((13 * W - 1) downto (12 * W)) <= TK2((5 * W - 1) downto (4 * W));
        TK2_PERMUTED((12 * W - 1) downto (11 * W)) <= TK2((4 * W - 1) downto (3 * W));
        TK2_PERMUTED((11 * W - 1) downto (10 * W)) <= TK2((3 * W - 1) downto (2 * W));
        TK2_PERMUTED((10 * W - 1) downto (9 * W)) <= TK2((2 * W - 1) downto (1 * W));
        TK2_PERMUTED((9 * W - 1) downto (8 * W)) <= TK2((1 * W - 1) downto (0 * W));
        TK2_PERMUTED((8 * W - 1) downto (7 * W)) <= TK2((14 * W - 1) downto (13 * W));
        TK2_PERMUTED((7 * W - 1) downto (6 * W)) <= TK2((16 * W - 1) downto (15 * W));
        TK2_PERMUTED((6 * W - 1) downto (5 * W)) <= TK2((12 * W - 1) downto (11 * W));
        TK2_PERMUTED((5 * W - 1) downto (4 * W)) <= TK2((9 * W - 1) downto (8 * W));
        TK2_PERMUTED((4 * W - 1) downto (3 * W)) <= TK2((10 * W - 1) downto (9 * W));
        TK2_PERMUTED((3 * W - 1) downto (2 * W)) <= TK2((13 * W - 1) downto (12 * W));
        TK2_PERMUTED((2 * W - 1) downto (1 * W)) <= TK2((11 * W - 1) downto (10 * W));
        TK2_PERMUTED((1 * W - 1) downto (0 * W)) <= TK2((15 * W - 1) downto (14 * W));

        -- Upper half of the state
        TK2_FF(71 downto 64) <= ( TK2_PERMUTED(67) xor TK2_PERMUTED(71) ) & ( TK2_PERMUTED(66) xor TK2_PERMUTED(70) ) & ( TK2_PERMUTED(65) xor TK2_PERMUTED(69) ) & ( TK2_PERMUTED(64) xor TK2_PERMUTED(68) ) & ( TK2_PERMUTED(67) xor TK2_PERMUTED(69) xor TK2_PERMUTED(71) ) & ( TK2_PERMUTED(66) xor TK2_PERMUTED(68) xor TK2_PERMUTED(70) ) & ( TK2_PERMUTED(65) xor TK2_PERMUTED(67) xor TK2_PERMUTED(69) ) & ( TK2_PERMUTED(64) xor TK2_PERMUTED(66) xor TK2_PERMUTED(68) );
        TK2_FF(79 downto 72) <= ( TK2_PERMUTED(75) xor TK2_PERMUTED(79) ) & ( TK2_PERMUTED(74) xor TK2_PERMUTED(78) ) & ( TK2_PERMUTED(73) xor TK2_PERMUTED(77) ) & ( TK2_PERMUTED(72) xor TK2_PERMUTED(76) ) & ( TK2_PERMUTED(75) xor TK2_PERMUTED(77) xor TK2_PERMUTED(79) ) & ( TK2_PERMUTED(74) xor TK2_PERMUTED(76) xor TK2_PERMUTED(78) ) & ( TK2_PERMUTED(73) xor TK2_PERMUTED(75) xor TK2_PERMUTED(77) ) & ( TK2_PERMUTED(72) xor TK2_PERMUTED(74) xor TK2_PERMUTED(76) );
        TK2_FF(87 downto 80) <= ( TK2_PERMUTED(83) xor TK2_PERMUTED(87) ) & ( TK2_PERMUTED(82) xor TK2_PERMUTED(86) ) & ( TK2_PERMUTED(81) xor TK2_PERMUTED(85) ) & ( TK2_PERMUTED(80) xor TK2_PERMUTED(84) ) & ( TK2_PERMUTED(83) xor TK2_PERMUTED(85) xor TK2_PERMUTED(87) ) & ( TK2_PERMUTED(82) xor TK2_PERMUTED(84) xor TK2_PERMUTED(86) ) & ( TK2_PERMUTED(81) xor TK2_PERMUTED(83) xor TK2_PERMUTED(85) ) & ( TK2_PERMUTED(80) xor TK2_PERMUTED(82) xor TK2_PERMUTED(84) );
        TK2_FF(95 downto 88) <= ( TK2_PERMUTED(91) xor TK2_PERMUTED(95) ) & ( TK2_PERMUTED(90) xor TK2_PERMUTED(94) ) & ( TK2_PERMUTED(89) xor TK2_PERMUTED(93) ) & ( TK2_PERMUTED(88) xor TK2_PERMUTED(92) ) & ( TK2_PERMUTED(91) xor TK2_PERMUTED(93) xor TK2_PERMUTED(95) ) & ( TK2_PERMUTED(90) xor TK2_PERMUTED(92) xor TK2_PERMUTED(94) ) & ( TK2_PERMUTED(89) xor TK2_PERMUTED(91) xor TK2_PERMUTED(93) ) & ( TK2_PERMUTED(88) xor TK2_PERMUTED(90) xor TK2_PERMUTED(92) );
        TK2_FF(103 downto 96) <= ( TK2_PERMUTED(99) xor TK2_PERMUTED(103) ) & ( TK2_PERMUTED(98) xor TK2_PERMUTED(102) ) & ( TK2_PERMUTED(97) xor TK2_PERMUTED(101) ) & ( TK2_PERMUTED(96) xor TK2_PERMUTED(100) ) & ( TK2_PERMUTED(99) xor TK2_PERMUTED(101) xor TK2_PERMUTED(103) ) & ( TK2_PERMUTED(98) xor TK2_PERMUTED(100) xor TK2_PERMUTED(102) ) & ( TK2_PERMUTED(97) xor TK2_PERMUTED(99) xor TK2_PERMUTED(101) ) & ( TK2_PERMUTED(96) xor TK2_PERMUTED(98) xor TK2_PERMUTED(100) );
        TK2_FF(111 downto 104) <= ( TK2_PERMUTED(107) xor TK2_PERMUTED(111) ) & ( TK2_PERMUTED(106) xor TK2_PERMUTED(110) ) & ( TK2_PERMUTED(105) xor TK2_PERMUTED(109) ) & ( TK2_PERMUTED(104) xor TK2_PERMUTED(108) ) & ( TK2_PERMUTED(107) xor TK2_PERMUTED(109) xor TK2_PERMUTED(111) ) & ( TK2_PERMUTED(106) xor TK2_PERMUTED(108) xor TK2_PERMUTED(110) ) & ( TK2_PERMUTED(105) xor TK2_PERMUTED(107) xor TK2_PERMUTED(109) ) & ( TK2_PERMUTED(104) xor TK2_PERMUTED(106) xor TK2_PERMUTED(108) );
        TK2_FF(119 downto 112) <= ( TK2_PERMUTED(115) xor TK2_PERMUTED(119) ) & ( TK2_PERMUTED(114) xor TK2_PERMUTED(118) ) & ( TK2_PERMUTED(113) xor TK2_PERMUTED(117) ) & ( TK2_PERMUTED(112) xor TK2_PERMUTED(116) ) & ( TK2_PERMUTED(115) xor TK2_PERMUTED(117) xor TK2_PERMUTED(119) ) & ( TK2_PERMUTED(114) xor TK2_PERMUTED(116) xor TK2_PERMUTED(118) ) & ( TK2_PERMUTED(113) xor TK2_PERMUTED(115) xor TK2_PERMUTED(117) ) & ( TK2_PERMUTED(112) xor TK2_PERMUTED(114) xor TK2_PERMUTED(116) );
        TK2_FF(127 downto 120) <= ( TK2_PERMUTED(123) xor TK2_PERMUTED(127) ) & ( TK2_PERMUTED(122) xor TK2_PERMUTED(126) ) & ( TK2_PERMUTED(121) xor TK2_PERMUTED(125) ) & ( TK2_PERMUTED(120) xor TK2_PERMUTED(124) ) & ( TK2_PERMUTED(123) xor TK2_PERMUTED(125) xor TK2_PERMUTED(127) ) & ( TK2_PERMUTED(122) xor TK2_PERMUTED(124) xor TK2_PERMUTED(126) ) & ( TK2_PERMUTED(121) xor TK2_PERMUTED(123) xor TK2_PERMUTED(125) ) & ( TK2_PERMUTED(120) xor TK2_PERMUTED(122) xor TK2_PERMUTED(124) );
        -- Lower half of the state
        TK2_FF(7 downto 0) <= ( TK2_PERMUTED(0) xor TK2_PERMUTED(4) xor TK2_PERMUTED(6) ) & ( TK2_PERMUTED(3) xor TK2_PERMUTED(7) ) & ( TK2_PERMUTED(2) xor TK2_PERMUTED(6) ) & ( TK2_PERMUTED(1) xor TK2_PERMUTED(5) ) & ( TK2_PERMUTED(0) xor TK2_PERMUTED(4) ) & ( TK2_PERMUTED(3) xor TK2_PERMUTED(5) xor TK2_PERMUTED(7) ) & ( TK2_PERMUTED(2) xor TK2_PERMUTED(4) xor TK2_PERMUTED(6) ) & ( TK2_PERMUTED(1) xor TK2_PERMUTED(3) xor TK2_PERMUTED(5) );
        TK2_FF(15 downto 8) <= ( TK2_PERMUTED(8) xor TK2_PERMUTED(12) xor TK2_PERMUTED(14) ) & ( TK2_PERMUTED(11) xor TK2_PERMUTED(15) ) & ( TK2_PERMUTED(10) xor TK2_PERMUTED(14) ) & ( TK2_PERMUTED(9) xor TK2_PERMUTED(13) ) & ( TK2_PERMUTED(8) xor TK2_PERMUTED(12) ) & ( TK2_PERMUTED(11) xor TK2_PERMUTED(13) xor TK2_PERMUTED(15) ) & ( TK2_PERMUTED(10) xor TK2_PERMUTED(12) xor TK2_PERMUTED(14) ) & ( TK2_PERMUTED(9) xor TK2_PERMUTED(11) xor TK2_PERMUTED(13) );
        TK2_FF(23 downto 16) <= ( TK2_PERMUTED(16) xor TK2_PERMUTED(20) xor TK2_PERMUTED(22) ) & ( TK2_PERMUTED(19) xor TK2_PERMUTED(23) ) & ( TK2_PERMUTED(18) xor TK2_PERMUTED(22) ) & ( TK2_PERMUTED(17) xor TK2_PERMUTED(21) ) & ( TK2_PERMUTED(16) xor TK2_PERMUTED(20) ) & ( TK2_PERMUTED(19) xor TK2_PERMUTED(21) xor TK2_PERMUTED(23) ) & ( TK2_PERMUTED(18) xor TK2_PERMUTED(20) xor TK2_PERMUTED(22) ) & ( TK2_PERMUTED(17) xor TK2_PERMUTED(19) xor TK2_PERMUTED(21) );
        TK2_FF(31 downto 24) <= ( TK2_PERMUTED(24) xor TK2_PERMUTED(28) xor TK2_PERMUTED(30) ) & ( TK2_PERMUTED(27) xor TK2_PERMUTED(31) ) & ( TK2_PERMUTED(26) xor TK2_PERMUTED(30) ) & ( TK2_PERMUTED(25) xor TK2_PERMUTED(29) ) & ( TK2_PERMUTED(24) xor TK2_PERMUTED(28) ) & ( TK2_PERMUTED(27) xor TK2_PERMUTED(29) xor TK2_PERMUTED(31) ) & ( TK2_PERMUTED(26) xor TK2_PERMUTED(28) xor TK2_PERMUTED(30) ) & ( TK2_PERMUTED(25) xor TK2_PERMUTED(27) xor TK2_PERMUTED(29) );
        TK2_FF(39 downto 32) <= ( TK2_PERMUTED(32) xor TK2_PERMUTED(36) xor TK2_PERMUTED(38) ) & ( TK2_PERMUTED(35) xor TK2_PERMUTED(39) ) & ( TK2_PERMUTED(34) xor TK2_PERMUTED(38) ) & ( TK2_PERMUTED(33) xor TK2_PERMUTED(37) ) & ( TK2_PERMUTED(32) xor TK2_PERMUTED(36) ) & ( TK2_PERMUTED(35) xor TK2_PERMUTED(37) xor TK2_PERMUTED(39) ) & ( TK2_PERMUTED(34) xor TK2_PERMUTED(36) xor TK2_PERMUTED(38) ) & ( TK2_PERMUTED(33) xor TK2_PERMUTED(35) xor TK2_PERMUTED(37) );
        TK2_FF(47 downto 40) <= ( TK2_PERMUTED(40) xor TK2_PERMUTED(44) xor TK2_PERMUTED(46) ) & ( TK2_PERMUTED(43) xor TK2_PERMUTED(47) ) & ( TK2_PERMUTED(42) xor TK2_PERMUTED(46) ) & ( TK2_PERMUTED(41) xor TK2_PERMUTED(45) ) & ( TK2_PERMUTED(40) xor TK2_PERMUTED(44) ) & ( TK2_PERMUTED(43) xor TK2_PERMUTED(45) xor TK2_PERMUTED(47) ) & ( TK2_PERMUTED(42) xor TK2_PERMUTED(44) xor TK2_PERMUTED(46) ) & ( TK2_PERMUTED(41) xor TK2_PERMUTED(43) xor TK2_PERMUTED(45) );
        TK2_FF(55 downto 48) <= ( TK2_PERMUTED(48) xor TK2_PERMUTED(52) xor TK2_PERMUTED(54) ) & ( TK2_PERMUTED(51) xor TK2_PERMUTED(55) ) & ( TK2_PERMUTED(50) xor TK2_PERMUTED(54) ) & ( TK2_PERMUTED(49) xor TK2_PERMUTED(53) ) & ( TK2_PERMUTED(48) xor TK2_PERMUTED(52) ) & ( TK2_PERMUTED(51) xor TK2_PERMUTED(53) xor TK2_PERMUTED(55) ) & ( TK2_PERMUTED(50) xor TK2_PERMUTED(52) xor TK2_PERMUTED(54) ) & ( TK2_PERMUTED(49) xor TK2_PERMUTED(51) xor TK2_PERMUTED(53) );
        TK2_FF(63 downto 56) <= ( TK2_PERMUTED(56) xor TK2_PERMUTED(60) xor TK2_PERMUTED(62) ) & ( TK2_PERMUTED(59) xor TK2_PERMUTED(63) ) & ( TK2_PERMUTED(58) xor TK2_PERMUTED(62) ) & ( TK2_PERMUTED(57) xor TK2_PERMUTED(61) ) & ( TK2_PERMUTED(56) xor TK2_PERMUTED(60) ) & ( TK2_PERMUTED(59) xor TK2_PERMUTED(61) xor TK2_PERMUTED(63) ) & ( TK2_PERMUTED(58) xor TK2_PERMUTED(60) xor TK2_PERMUTED(62) ) & ( TK2_PERMUTED(57) xor TK2_PERMUTED(59) xor TK2_PERMUTED(61) );


    -- 30-times FORWARD application of TK3 schedule (note the 30, not 31)
    -- Generating the following permutation: [2, 0, 4, 7, 6, 3, 5, 1, 10, 8, 12, 15, 14, 11, 13, 9]
	TK3_PERMUTED((8 * W - 1) downto (7 * W)) <= TK3((6 * W - 1) downto (5 * W));
	TK3_PERMUTED((7 * W - 1) downto (6 * W)) <= TK3((8 * W - 1) downto (7 * W));
	TK3_PERMUTED((6 * W - 1) downto (5 * W)) <= TK3((4 * W - 1) downto (3 * W));
	TK3_PERMUTED((5 * W - 1) downto (4 * W)) <= TK3((1 * W - 1) downto (0 * W));
	TK3_PERMUTED((4 * W - 1) downto (3 * W)) <= TK3((2 * W - 1) downto (1 * W));
	TK3_PERMUTED((3 * W - 1) downto (2 * W)) <= TK3((5 * W - 1) downto (4 * W));
	TK3_PERMUTED((2 * W - 1) downto (1 * W)) <= TK3((3 * W - 1) downto (2 * W));
	TK3_PERMUTED((1 * W - 1) downto (0 * W)) <= TK3((7 * W - 1) downto (6 * W));

    -- Lower half of the state
    TK3_FF(7 downto 0) <= ( TK3_PERMUTED(0) xor TK3_PERMUTED(4) xor TK3_PERMUTED(6) ) & ( TK3_PERMUTED(3) xor TK3_PERMUTED(7) ) & ( TK3_PERMUTED(2) xor TK3_PERMUTED(6) ) & ( TK3_PERMUTED(1) xor TK3_PERMUTED(5) ) & ( TK3_PERMUTED(0) xor TK3_PERMUTED(4) ) & ( TK3_PERMUTED(3) xor TK3_PERMUTED(5) xor TK3_PERMUTED(7) ) & ( TK3_PERMUTED(2) xor TK3_PERMUTED(4) xor TK3_PERMUTED(6) ) & ( TK3_PERMUTED(1) xor TK3_PERMUTED(3) xor TK3_PERMUTED(5) );
    TK3_FF(15 downto 8) <= ( TK3_PERMUTED(8) xor TK3_PERMUTED(12) xor TK3_PERMUTED(14) ) & ( TK3_PERMUTED(11) xor TK3_PERMUTED(15) ) & ( TK3_PERMUTED(10) xor TK3_PERMUTED(14) ) & ( TK3_PERMUTED(9) xor TK3_PERMUTED(13) ) & ( TK3_PERMUTED(8) xor TK3_PERMUTED(12) ) & ( TK3_PERMUTED(11) xor TK3_PERMUTED(13) xor TK3_PERMUTED(15) ) & ( TK3_PERMUTED(10) xor TK3_PERMUTED(12) xor TK3_PERMUTED(14) ) & ( TK3_PERMUTED(9) xor TK3_PERMUTED(11) xor TK3_PERMUTED(13) );
    TK3_FF(23 downto 16) <= ( TK3_PERMUTED(16) xor TK3_PERMUTED(20) xor TK3_PERMUTED(22) ) & ( TK3_PERMUTED(19) xor TK3_PERMUTED(23) ) & ( TK3_PERMUTED(18) xor TK3_PERMUTED(22) ) & ( TK3_PERMUTED(17) xor TK3_PERMUTED(21) ) & ( TK3_PERMUTED(16) xor TK3_PERMUTED(20) ) & ( TK3_PERMUTED(19) xor TK3_PERMUTED(21) xor TK3_PERMUTED(23) ) & ( TK3_PERMUTED(18) xor TK3_PERMUTED(20) xor TK3_PERMUTED(22) ) & ( TK3_PERMUTED(17) xor TK3_PERMUTED(19) xor TK3_PERMUTED(21) );
    TK3_FF(31 downto 24) <= ( TK3_PERMUTED(24) xor TK3_PERMUTED(28) xor TK3_PERMUTED(30) ) & ( TK3_PERMUTED(27) xor TK3_PERMUTED(31) ) & ( TK3_PERMUTED(26) xor TK3_PERMUTED(30) ) & ( TK3_PERMUTED(25) xor TK3_PERMUTED(29) ) & ( TK3_PERMUTED(24) xor TK3_PERMUTED(28) ) & ( TK3_PERMUTED(27) xor TK3_PERMUTED(29) xor TK3_PERMUTED(31) ) & ( TK3_PERMUTED(26) xor TK3_PERMUTED(28) xor TK3_PERMUTED(30) ) & ( TK3_PERMUTED(25) xor TK3_PERMUTED(27) xor TK3_PERMUTED(29) );
    TK3_FF(39 downto 32) <= ( TK3_PERMUTED(32) xor TK3_PERMUTED(36) xor TK3_PERMUTED(38) ) & ( TK3_PERMUTED(35) xor TK3_PERMUTED(39) ) & ( TK3_PERMUTED(34) xor TK3_PERMUTED(38) ) & ( TK3_PERMUTED(33) xor TK3_PERMUTED(37) ) & ( TK3_PERMUTED(32) xor TK3_PERMUTED(36) ) & ( TK3_PERMUTED(35) xor TK3_PERMUTED(37) xor TK3_PERMUTED(39) ) & ( TK3_PERMUTED(34) xor TK3_PERMUTED(36) xor TK3_PERMUTED(38) ) & ( TK3_PERMUTED(33) xor TK3_PERMUTED(35) xor TK3_PERMUTED(37) );
    TK3_FF(47 downto 40) <= ( TK3_PERMUTED(40) xor TK3_PERMUTED(44) xor TK3_PERMUTED(46) ) & ( TK3_PERMUTED(43) xor TK3_PERMUTED(47) ) & ( TK3_PERMUTED(42) xor TK3_PERMUTED(46) ) & ( TK3_PERMUTED(41) xor TK3_PERMUTED(45) ) & ( TK3_PERMUTED(40) xor TK3_PERMUTED(44) ) & ( TK3_PERMUTED(43) xor TK3_PERMUTED(45) xor TK3_PERMUTED(47) ) & ( TK3_PERMUTED(42) xor TK3_PERMUTED(44) xor TK3_PERMUTED(46) ) & ( TK3_PERMUTED(41) xor TK3_PERMUTED(43) xor TK3_PERMUTED(45) );
    TK3_FF(55 downto 48) <= ( TK3_PERMUTED(48) xor TK3_PERMUTED(52) xor TK3_PERMUTED(54) ) & ( TK3_PERMUTED(51) xor TK3_PERMUTED(55) ) & ( TK3_PERMUTED(50) xor TK3_PERMUTED(54) ) & ( TK3_PERMUTED(49) xor TK3_PERMUTED(53) ) & ( TK3_PERMUTED(48) xor TK3_PERMUTED(52) ) & ( TK3_PERMUTED(51) xor TK3_PERMUTED(53) xor TK3_PERMUTED(55) ) & ( TK3_PERMUTED(50) xor TK3_PERMUTED(52) xor TK3_PERMUTED(54) ) & ( TK3_PERMUTED(49) xor TK3_PERMUTED(51) xor TK3_PERMUTED(53) );
    TK3_FF(63 downto 56) <= ( TK3_PERMUTED(56) xor TK3_PERMUTED(60) xor TK3_PERMUTED(62) ) & ( TK3_PERMUTED(59) xor TK3_PERMUTED(63) ) & ( TK3_PERMUTED(58) xor TK3_PERMUTED(62) ) & ( TK3_PERMUTED(57) xor TK3_PERMUTED(61) ) & ( TK3_PERMUTED(56) xor TK3_PERMUTED(60) ) & ( TK3_PERMUTED(59) xor TK3_PERMUTED(61) xor TK3_PERMUTED(63) ) & ( TK3_PERMUTED(58) xor TK3_PERMUTED(60) xor TK3_PERMUTED(62) ) & ( TK3_PERMUTED(57) xor TK3_PERMUTED(59) xor TK3_PERMUTED(61) );


    end generate;


end ARCHITECTURE;
