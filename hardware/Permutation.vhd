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

USE WORK.ForkSKINNYPKG.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY Permutation is
	GENERIC (BS : BLOCK_SIZE);
	PORT ( X : IN  STD_LOGIC_VECTOR ((GET_BLOCK_SIZE(BS) - 1) DOWNTO 0);
          Y : OUT STD_LOGIC_VECTOR ((GET_BLOCK_SIZE(BS) - 1) DOWNTO 0));
END Permutation;



-- ARCHITECTURE : DATAFLOW
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF Permutation IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);
	
BEGIN

	-- ROW 1 ----------------------------------------------------------------------
	Y((16 * W - 1) DOWNTO (15 * W)) <= X(( 7 * W - 1) DOWNTO ( 6 * W));
	Y((15 * W - 1) DOWNTO (14 * W)) <= X(( 1 * W - 1) DOWNTO ( 0 * W));
	Y((14 * W - 1) DOWNTO (13 * W)) <= X(( 8 * W - 1) DOWNTO ( 7 * W));
	Y((13 * W - 1) DOWNTO (12 * W)) <= X(( 3 * W - 1) DOWNTO ( 2 * W));
	-------------------------------------------------------------------------------

	-- ROW 2 ----------------------------------------------------------------------	
	Y((12 * W - 1) DOWNTO (11 * W)) <= X(( 6 * W - 1) DOWNTO ( 5 * W));
	Y((11 * W - 1) DOWNTO (10 * W)) <= X(( 2 * W - 1) DOWNTO ( 1 * W));
	Y((10 * W - 1) DOWNTO ( 9 * W)) <= X(( 4 * W - 1) DOWNTO ( 3 * W));
	Y(( 9 * W - 1) DOWNTO ( 8 * W)) <= X(( 5 * W - 1) DOWNTO ( 4 * W));
	-------------------------------------------------------------------------------

	-- ROW 3 ----------------------------------------------------------------------	
	Y(( 8 * W - 1) DOWNTO ( 7 * W)) <= X((16 * W - 1) DOWNTO (15 * W));
	Y(( 7 * W - 1) DOWNTO ( 6 * W)) <= X((15 * W - 1) DOWNTO (14 * W));
	Y(( 6 * W - 1) DOWNTO ( 5 * W)) <= X((14 * W - 1) DOWNTO (13 * W));
	Y(( 5 * W - 1) DOWNTO ( 4 * W)) <= X((13 * W - 1) DOWNTO (12 * W));
	-------------------------------------------------------------------------------

	-- ROW 4 ----------------------------------------------------------------------	
	Y(( 4 * W - 1) DOWNTO ( 3 * W)) <= X((12 * W - 1) DOWNTO (11 * W));
	Y(( 3 * W - 1) DOWNTO ( 2 * W)) <= X((11 * W - 1) DOWNTO (10 * W));
	Y(( 2 * W - 1) DOWNTO ( 1 * W)) <= X((10 * W - 1) DOWNTO ( 9 * W));
	Y(( 1 * W - 1) DOWNTO ( 0 * W)) <= X(( 9 * W - 1) DOWNTO ( 8 * W));
	-------------------------------------------------------------------------------

END Dataflow;


-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE WORK.ForkSKINNYPKG.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY InversePermutation is
	GENERIC (BS : BLOCK_SIZE);
	PORT ( X : IN  STD_LOGIC_VECTOR ((GET_BLOCK_SIZE(BS) - 1) DOWNTO 0);
          Y : OUT STD_LOGIC_VECTOR ((GET_BLOCK_SIZE(BS) - 1) DOWNTO 0));
END InversePermutation;



-- ARCHITECTURE : DATAFLOW
----------------------------------------------------------------------------------
-- This is permutation P_T. Mind the I/O order: cell 9 goes to 0, cell 15 goes to 1, ...
-- Recall also that state [0 1 2 3; 4 5 6 7; 8 9 10 11; 12 13 14 15] is encoded as [0 1 2 3 ... 14 15] where 0 has the highest indices.
ARCHITECTURE Dataflow OF InversePermutation IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);
	
BEGIN


	-- ROW 1 ----------------------------------------------------------------------
	Y(( 16 * W - 1) DOWNTO ( 15 * W)) <= X((8 * W - 1) DOWNTO (7 * W));
	Y(( 15 * W - 1) DOWNTO ( 14 * W)) <= X((7 * W - 1) DOWNTO (6 * W));
	Y(( 14 * W - 1) DOWNTO ( 13 * W)) <= X((6 * W - 1) DOWNTO (5 * W));
	Y(( 13 * W - 1) DOWNTO ( 12 * W)) <= X((5 * W - 1) DOWNTO (4 * W));
	-------------------------------------------------------------------------------

	-- ROW 2 ----------------------------------------------------------------------	
	Y((12 * W - 1) DOWNTO (11 * W)) <= X(( 4 * W - 1) DOWNTO ( 3 * W));
	Y((11 * W - 1) DOWNTO (10 * W)) <= X(( 3 * W - 1) DOWNTO ( 2 * W));
	Y((10 * W - 1) DOWNTO ( 9 * W)) <= X(( 2 * W - 1) DOWNTO ( 1 * W));
	Y(( 9 * W - 1) DOWNTO ( 8 * W)) <= X(( 1 * W - 1) DOWNTO ( 0 * W));
	-------------------------------------------------------------------------------


	-- ROW 3 ----------------------------------------------------------------------	
	Y(( 8 * W - 1) DOWNTO ( 7 * W)) <= X((14 * W - 1) DOWNTO (13 * W));
	Y(( 7 * W - 1) DOWNTO ( 6 * W)) <= X((16 * W - 1) DOWNTO (15 * W));
	Y(( 6 * W - 1) DOWNTO ( 5 * W)) <= X((12 * W - 1) DOWNTO (11 * W));
	Y(( 5 * W - 1) DOWNTO ( 4 * W)) <= X((9 * W - 1) DOWNTO (8 * W));
	-------------------------------------------------------------------------------

	-- ROW 4 ----------------------------------------------------------------------	
	Y(( 4 * W - 1) DOWNTO ( 3 * W)) <= X((10 * W - 1) DOWNTO (9 * W));
	Y(( 3 * W - 1) DOWNTO ( 2 * W)) <= X((13 * W - 1) DOWNTO (12 * W));
	Y(( 2 * W - 1) DOWNTO ( 1 * W)) <= X((11 * W - 1) DOWNTO ( 10 * W));
	Y(( 1 * W - 1) DOWNTO ( 0 * W)) <= X((15 * W - 1) DOWNTO ( 14 * W));
	-------------------------------------------------------------------------------

END Dataflow;

-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE WORK.ForkSKINNYPKG.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY HalfPermutation is
	GENERIC (BS : BLOCK_SIZE);
	PORT ( X : IN  STD_LOGIC_VECTOR ((GET_BLOCK_SIZE(BS)/2 - 1) DOWNTO 0);
          Y : OUT STD_LOGIC_VECTOR ((GET_BLOCK_SIZE(BS)/2 - 1) DOWNTO 0));
END HalfPermutation;



-- ARCHITECTURE : DATAFLOW
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF HalfPermutation IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);
	
BEGIN

    -- Permutation: [1, 7, 0, 5, 2, 6, 4, 3]
	Y((8 * W - 1) downto (7 * W)) <= X((7 * W - 1) downto (6 * W));
	Y((7 * W - 1) downto (6 * W)) <= X((1 * W - 1) downto (0 * W));
	Y((6 * W - 1) downto (5 * W)) <= X((8 * W - 1) downto (7 * W));
	Y((5 * W - 1) downto (4 * W)) <= X((3 * W - 1) downto (2 * W));
	Y((4 * W - 1) downto (3 * W)) <= X((6 * W - 1) downto (5 * W));
	Y((3 * W - 1) downto (2 * W)) <= X((2 * W - 1) downto (1 * W));
	Y((2 * W - 1) downto (1 * W)) <= X((4 * W - 1) downto (3 * W));
	Y((1 * W - 1) downto (0 * W)) <= X((5 * W - 1) downto (4 * W));

END Dataflow;


-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE WORK.ForkSKINNYPKG.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY InverseHalfPermutation is
	GENERIC (BS : BLOCK_SIZE);
	PORT ( X : IN  STD_LOGIC_VECTOR ((GET_BLOCK_SIZE(BS)/2 - 1) DOWNTO 0);
          Y : OUT STD_LOGIC_VECTOR ((GET_BLOCK_SIZE(BS)/2 - 1) DOWNTO 0));
END InverseHalfPermutation;


-- ARCHITECTURE : DATAFLOW
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF InverseHalfPermutation IS

	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);
	
BEGIN
    -- Permutation: [2, 0, 4, 7, 6, 3, 5, 1]
	Y((8 * W - 1) downto (7 * W)) <= X((6 * W - 1) downto (5 * W));
	Y((7 * W - 1) downto (6 * W)) <= X((8 * W - 1) downto (7 * W));
	Y((6 * W - 1) downto (5 * W)) <= X((4 * W - 1) downto (3 * W));
	Y((5 * W - 1) downto (4 * W)) <= X((1 * W - 1) downto (0 * W));
	Y((4 * W - 1) downto (3 * W)) <= X((2 * W - 1) downto (1 * W));
	Y((3 * W - 1) downto (2 * W)) <= X((5 * W - 1) downto (4 * W));
	Y((2 * W - 1) downto (1 * W)) <= X((3 * W - 1) downto (2 * W));
	Y((1 * W - 1) downto (0 * W)) <= X((7 * W - 1) downto (6 * W));
END Dataflow;


