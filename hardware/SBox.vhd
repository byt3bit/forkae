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



-- ENTITY
----------------------------------------------------------------------------------
ENTITY SBox IS	
	GENERIC (BS : BLOCK_SIZE);
	PORT ( X : IN	STD_LOGIC_VECTOR ((GET_WORD_SIZE(BS) - 1) DOWNTO 0);
          Y : OUT	STD_LOGIC_VECTOR ((GET_WORD_SIZE(BS) - 1) DOWNTO 0));
END SBox;



-- ARCHITECTURE : DATAFLOW
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF SBox IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL NO3, XO3, NO2, XO2, NO1, XO1, NO0, XO0 : STD_LOGIC;
	SIGNAL O, P												 : STD_LOGIC_VECTOR(39 DOWNTO 0);

-- DATAFLOW
----------------------------------------------------------------------------------
BEGIN

	-- 4-BIT S-BOX ----------------------------------------------------------------
	S4 : IF BS = BLOCK_SIZE_64 GENERATE
		NO3 <= X(3) NOR X(2);
		XO3 <= X(0) XOR NO3;
		
		NO2 <= X(2) NOR X(1);
		XO2 <= X(3) XOR NO2;
		
		NO1 <= X(1) NOR XO3;
		XO1 <= X(2) XOR NO1;
		
		NO0 <= XO3 NOR XO2;
		XO0 <= X(1) XOR NO0;
		
		Y <= XO3 & XO2 & XO1 & XO0;
	END GENERATE;
	-------------------------------------------------------------------------------
	
	-- 8-BIT S-BOX ----------------------------------------------------------------
	S8 : IF BS = BLOCK_SIZE_128 GENERATE
		P(7 DOWNTO 0) <= X;

		GEN : FOR I IN 0 TO 3 GENERATE
			O((8 * I +  7) DOWNTO (8 * I + 4)) <= P((8 * I + 7) DOWNTO (8 * I + 5)) & (P(8 * I + 4) XOR (P(8 * I + 7) NOR P(8 * I + 6)));
			O((8 * I +  3) DOWNTO (8 * I + 0)) <= P((8 * I + 3) DOWNTO (8 * I + 1)) & (P(8 * I + 0) XOR (P(8 * I + 3) NOR P(8 * I + 2)));		
			P((8 * I + 15) DOWNTO (8 * I + 8)) <= O((8 * I + 2)) & O((8 * I + 1)) & O((8 * I + 7)) & O((8 * I + 6)) & O((8 * I + 4)) & O((8 * I + 0)) & O((8 * I + 3)) & O((8 * I + 5));
		END GENERATE;

		Y <= O(31 DOWNTO 27) & O(25) & O(26) & O(24);	
	END GENERATE;
	-------------------------------------------------------------------------------
	
END Dataflow;

-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE WORK.FORKSKINNYPKG.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY SBoxInverse IS	
	GENERIC (BS : BLOCK_SIZE);
	PORT ( X : IN	STD_LOGIC_VECTOR ((GET_WORD_SIZE(BS) - 1) DOWNTO 0);
          Y : OUT	STD_LOGIC_VECTOR ((GET_WORD_SIZE(BS) - 1) DOWNTO 0));
END SBoxInverse;


-- ARCHITECTURE : DATAFLOW
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF SBoxInverse IS

	-- SIGNALS --------------------------------------------------------------------
	SIGNAL NO3, XO3, NO2, XO2, NO1, XO1, NO0, XO0 : STD_LOGIC;
	SIGNAL O, P: STD_LOGIC_VECTOR(39 DOWNTO 0);

-- DATAFLOW
----------------------------------------------------------------------------------
BEGIN

	-- 4-BIT S-BOX ----------------------------------------------------------------
	S4 : IF BS = BLOCK_SIZE_64 GENERATE
        -- X1 = Y0+NOR(Y2, Y3)
		NO1 <= X(3) NOR X(2);
		XO1 <= X(0) XOR NO1;
		
        -- X2 = Y1+NOR(X1, Y3)
		NO2 <= XO1 NOR X(3);
		XO2 <= X(1) XOR NO2;
		
        -- X3 = Y2+NOR(X2, X1)
		NO3 <= XO2 NOR XO1;
		XO3 <= X(2) XOR NO3;
		
        -- X0 = Y3+NOR(X3, X2)
		NO0 <= XO3 NOR XO2;
		XO0 <= X(3) XOR NO0;
		
		Y <= XO3 & XO2 & XO1 & XO0; -- Computed bits separately, now concatenate
	END GENERATE;
	-------------------------------------------------------------------------------
	
	-- 8-BIT S-BOX ----------------------------------------------------------------
	S8 : IF BS = BLOCK_SIZE_128 GENERATE
        
        -- Bit swap between x1 and x2
        O(39 downto 32) <= X(7 DOWNTO 3) & X(1) & X(2) & X(0); -- Inverse permutation is its own inverse

		--GEN : FOR I IN 0 TO 3 GENERATE
		GEN : FOR I IN 3 DOWNTO 0 GENERATE

            -- Invert this one layer of transformation (is its own inverse)
			P((8 * I +  7) DOWNTO (8 * I + 4)) <= O((8 * I + 15) DOWNTO (8 * I + 13)) & (O(8 * I + 12) XOR (O(8 * I + 15) NOR O(8 * I + 14)));
			P((8 * I +  3) DOWNTO (8 * I + 0)) <= O((8 * I + 11) DOWNTO (8 * I + 9)) & (O(8 * I + 8) XOR (O(8 * I + 11) NOR O(8 * I + 10)));		

            -- Inverted bit permutation (last result is discarded)
			O((8 * I + 7) DOWNTO (8 * I + 0)) <= P((8 * I + 5)) & P((8 * I + 4)) & P((8 * I + 0)) & P((8 * I + 3)) & P((8 * I + 1)) & P((8 * I + 7)) & P((8 * I + 6)) & P((8 * I + 2));

		END GENERATE;

        Y <= P(7 downto 0);

	END GENERATE;
	-------------------------------------------------------------------------------
	
END Dataflow;
