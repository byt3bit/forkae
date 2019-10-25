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

package ForkSkinnyPKG is

	-- Define blocksize, tweakey size and key size --------------------------------
	type BLOCK_SIZE is (BLOCK_SIZE_64, BLOCK_SIZE_128);
	type TWEAK_SIZE is (TWEAK_SIZE_1N, TWEAK_SIZE_3o2N, TWEAK_SIZE_2N, TWEAK_SIZE_9o4N, TWEAK_SIZE_3N);
    constant KEY_SIZE : integer := 128;
	-------------------------------------------------------------------------------
		
    type ENC_DEC is (ENCRYPTION, ENCRYPTION_DECRYPTION);
    
    -- Function definitions -------------------------------------------------------
	function GET_WORD_SIZE  (BS : BLOCK_SIZE) return integer;		
	function GET_BLOCK_SIZE (BS : BLOCK_SIZE) return integer;
	function GET_TWEAK_FACT (TS : TWEAK_SIZE) return integer;
	function GET_TWEAK_SIZE (BS : BLOCK_SIZE; TS : TWEAK_SIZE) return integer;
	-------------------------------------------------------------------------------
	
end ForkSkinnyPKG;

package body ForkSkinnyPKG is

	-- FUNCTION: RETURN WORD SIZE -------------------------------------------------
	FUNCTION GET_WORD_SIZE (BS : BLOCK_SIZE) RETURN INTEGER IS
	BEGIN
			IF BS = BLOCK_SIZE_64 THEN
				RETURN 4;
			ELSE
				RETURN 8;
			END IF;
	END GET_WORD_SIZE;
	-------------------------------------------------------------------------------
	
	-- FUNCTION: RETURN BLOCK SIZE ------------------------------------------------
	FUNCTION GET_BLOCK_SIZE (BS : BLOCK_SIZE) RETURN INTEGER IS
	BEGIN
			IF BS = BLOCK_SIZE_64 THEN
				RETURN 64;
			ELSE
				RETURN 128;
			END IF;
	END GET_BLOCK_SIZE;
	-------------------------------------------------------------------------------
	
	-- FUNCTION: RETURN TWEAK FACTOR ----------------------------------------------
	FUNCTION GET_TWEAK_FACT (TS : TWEAK_SIZE) RETURN INTEGER IS
	BEGIN
			IF    TS = TWEAK_SIZE_1N THEN
				RETURN 1;
			ELSIF TS = TWEAK_SIZE_2N THEN
				RETURN 2;
			ELSE
				RETURN 3;
			END IF;
	END GET_TWEAK_FACT;
	-------------------------------------------------------------------------------
	
	-- FUNCTION: RETURN TWEAK SIZE ------------------------------------------------
	FUNCTION GET_TWEAK_SIZE (BS : BLOCK_SIZE; TS : TWEAK_SIZE) RETURN INTEGER IS
	BEGIN
        if TS = TWEAK_SIZE_3o2N then
            return 192;
        elsif TS = TWEAK_SIZE_9o4N then
            return 320; -- This implementation pads zeros to fill half of the TK3 state
        else
            RETURN GET_BLOCK_SIZE(BS) * GET_TWEAK_FACT(TS);
        end if;
			
	END GET_TWEAK_SIZE;
	-------------------------------------------------------------------------------
	
	
end ForkSkinnyPKG;
