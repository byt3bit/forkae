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



----------------------------------------------------
-- RoundConstant for encryption-only implementation
----------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity RoundConstantEnc is
    port (CLK    : in  std_logic;
          INIT	 : in  std_logic;
          CONST  : out std_logic_vector(6 downto 0));
end RoundConstantEnc;

architecture behav of RoundConstantEnc is

	-- Signals 
	signal STATE, UPDATE : std_logic_vector(6 downto 0);

BEGIN
	-- STATE ----------------------------------------------------------------------
	REG_X : process(CLK)
	begin
        if RISING_EDGE(CLK) then
			if (INIT = '1') then
				STATE <= (others => '0');
			else
				STATE <= UPDATE;
			end if;
		end if;
	end process;
	-------------------------------------------------------------------------------

	-- UPDATE FUNCTION ------------------------------------------------------------
    -- Apply update function before using the round constant
	UPDATE(6 downto 0) <= STATE(5 downto 0) & (STATE(6) xnor STATE(5));
	-------------------------------------------------------------------------------

	-- OUTPUT ---------------------------------------------------------------------
	CONST <= UPDATE;
	-------------------------------------------------------------------------------
  
END behav;


----------------------------------------------------------
-- RoundConstant for encryption-decryption implementation
----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.forkskinnypkg.all;

entity RoundConstantEncDec is
    generic (BS: BLOCK_SIZE; TS: TWEAK_SIZE);
    port (CLK         : in  std_logic;
          INIT	      : in  std_logic;
          DECRYPT     : in  std_logic;
          CONST_ENC   : out std_logic_vector(6 downto 0);
          CONST_DEC   : out std_logic_vector(6 downto 0));
end RoundConstantEncDec;

architecture behav of RoundConstantEncDec is

	-- Signals 
	signal STATE, UPDATE, INV_UPDATE, DECRYPTION_RC : std_logic_vector(6 downto 0);

BEGIN
	-- STATE ----------------------------------------------------------------------
	REG_X : process(CLK)
	begin
        if RISING_EDGE(CLK) then
			if (INIT = '1' and DECRYPT='0') then
				STATE <= (others => '0');
			elsif (INIT = '1' and DECRYPT='1') then
                STATE <= DECRYPTION_RC;
            elsif (DECRYPT = '1') then
                STATE <= INV_UPDATE;
			else
				STATE <= UPDATE;
			end if;
		end if;
	end process;
	-------------------------------------------------------------------------------

	-- UPDATE, INVERSE UPDATE and DECRYPTION RC FUNCTIONS -------------------------

	UPDATE(6 downto 0) <= STATE(5 downto 0) & (STATE(6) xnor STATE(5));

	INV_UPDATE(6 downto 0) <= (STATE(6) xnor STATE(0)) & STATE(6 downto 1);

    GEN_SET_DECRYPTION_RC_0: if BS = BLOCK_SIZE_64 generate
        DECRYPTION_RC <= "1010011"; 
    end generate;

    GEN_SET_DECRYPTION_RC_1: if BS = BLOCK_SIZE_128 and (TS = TWEAK_SIZE_2N or TS = TWEAK_SIZE_3o2N) generate
        DECRYPTION_RC <= "0010101"; 
    end generate;

    GEN_SET_DECRYPTION_RC_2: if BS = BLOCK_SIZE_128 and (TS = TWEAK_SIZE_9o4N) generate
        DECRYPTION_RC <= "0000010"; 
    end generate;
	-------------------------------------------------------------------------------

	-- OUTPUT ---------------------------------------------------------------------

    -- Apply update function before using the round constant
	CONST_ENC <= UPDATE;

    -- Apply inverse update function AFTER using the round constant
    CONST_DEC <= STATE;
	-------------------------------------------------------------------------------
  
END behav;

------------------------------------------------------
-- RoundConstant Fast Forward for parallel encryption
------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.forkskinnypkg.all;

entity RoundConstantFF is
    generic (BS: BLOCK_SIZE; TS: TWEAK_SIZE);
    port ( CONST : in std_logic_vector (6 downto 0);
           CONST_FF : out std_logic_vector (6 downto 0)
          );
end RoundConstantFF;

architecture behav of RoundConstantFF is

begin

    -- FS-64-192
    RC_FF_64_192: IF (BS = BLOCK_SIZE_64 AND TS = TWEAK_SIZE_3N) GENERATE
        CONST_FF(6 downto 0) <= ( CONST(1) xor CONST(2) xor CONST(3) xor CONST(4) xor '1') & ( CONST(0) xor CONST(1) xor CONST(2) xor CONST(3) xor '1') & ( CONST(0) xor CONST(1) xor CONST(2) xor CONST(5) xor CONST(6) ) & ( CONST(0) xor CONST(1) xor CONST(4) xor CONST(6) xor '1') & ( CONST(0) xor CONST(3) xor CONST(6) ) & ( CONST(2) xor CONST(6) xor '1') & ( CONST(1) xor CONST(5) xor '1');
    end generate;

    -- FS-128-192 and FS-128-256
    RC_FF_128_256: IF (BS = BLOCK_SIZE_128 AND (TS = TWEAK_SIZE_2N or TS = TWEAK_SIZE_3o2N)) GENERATE
        CONST_FF(6 downto 0) <= ( CONST(0) xor CONST(3) xor CONST(6) ) & ( CONST(2) xor CONST(6) xor '1') & ( CONST(1) xor CONST(5) xor '1')  & ( CONST(0) xor CONST(4) xor '1' ) & ( CONST(3) xor CONST(5) xor CONST(6) ) & ( CONST(2) xor CONST(4) xor CONST(5) ) & ( CONST(1) xor CONST(3) xor CONST(4) );
    end generate;

    -- FS-128-288
    RC_FF_128_288: IF (BS = BLOCK_SIZE_128 AND (TS = TWEAK_SIZE_9o4N or TS = TWEAK_SIZE_3N)) GENERATE
        CONST_FF(6 downto 0) <= ( CONST(3) xor CONST(5) xor CONST(6) ) & ( CONST(2) xor CONST(4) xor CONST(5) ) & ( CONST(1) xor CONST(3) xor CONST(4) ) & ( CONST(0) xor CONST(2) xor CONST(3) ) & ( CONST(1) xor CONST(2) xor CONST(5) xor CONST(6) xor '1' ) & ( CONST(0) xor CONST(1) xor CONST(4) xor CONST(5) xor '1' ) & ( CONST(0) xor CONST(3) xor CONST(4) xor CONST(5) xor CONST(6) );
    end generate;

end behav;




---- IMPORTS
------------------------------------------------------------------------------------
--LIBRARY IEEE;
--USE IEEE.STD_LOGIC_1164.ALL;
--
--USE WORK.SKINNYPKG.ALL;
--
---- ENTITY
------------------------------------------------------------------------------------
--ENTITY ConstGeneratorFF IS
    --generic(BS: BLOCK_SIZE; TS: TWEAK_SIZE);
  --PORT (CLK    : IN  STD_LOGIC;
        --INIT	: IN  STD_LOGIC;
        --CONST  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        --FAST_FORWARD  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
--END ConstGeneratorFF;
--
--
---- ARCHITECTURE : DATAFLOW
------------------------------------------------------------------------------------
--ARCHITECTURE Dataflow OF ConstGeneratorFF IS
--
	---- SIGNALS --------------------------------------------------------------------
	--SIGNAL STATE, UPDATE : STD_LOGIC_VECTOR(6 DOWNTO 0);
--
---- DATAFLOW
------------------------------------------------------------------------------------
--BEGIN
	---- STATE ----------------------------------------------------------------------
	--REG : PROCESS(CLK)
	--BEGIN
		--IF RISING_EDGE(CLK) THEN
			--IF (INIT = '1') THEN
				--STATE <= "0000000";
			--ELSE
				--STATE <= UPDATE;
			--END IF;
		--END IF;
	--END PROCESS;
	---------------------------------------------------------------------------------
--
	---- UPDATE FUNCTION ------------------------------------------------------------
    ---- Apply update function before using the round constant
	--UPDATE(6 DOWNTO 0) <= STATE(5 DOWNTO 0) & (STATE(6) XNOR STATE(5));
	---------------------------------------------------------------------------------
--
    ---- FAST FORWARD FUNCTION ------------------------------------------------------
    ---- Apply update function r1 times 
	--UPDATE(6 DOWNTO 0) <= STATE(5 DOWNTO 0) & (STATE(6) XNOR STATE(5));
--
    ---- FS-64-192
    --RC_FF_64_192: IF (BS = BLOCK_SIZE_64 AND TS = TWEAK_SIZE_3N) GENERATE
        --FAST_FORWARD(6 downto 0) <= ( UPDATE(1) xor UPDATE(2) xor UPDATE(3) xor UPDATE(4) xor '1') & ( UPDATE(0) xor UPDATE(1) xor UPDATE(2) xor UPDATE(3) xor '1') & ( UPDATE(0) xor UPDATE(1) xor UPDATE(2) xor UPDATE(5) xor UPDATE(6) ) & ( UPDATE(0) xor UPDATE(1) xor UPDATE(4) xor UPDATE(6) xor '1') & ( UPDATE(0) xor UPDATE(3) xor UPDATE(6) ) & ( UPDATE(2) xor UPDATE(6) xor '1') & ( UPDATE(1) xor UPDATE(5) xor '1');
    --end generate;
--
    ---- FS-128-256
    --RC_FF_128_256: IF (BS = BLOCK_SIZE_128 AND (TS = TWEAK_SIZE_2N or TS = TWEAK_SIZE_3o2N)) GENERATE
        --FAST_FORWARD(6 downto 0) <= ( UPDATE(0) xor UPDATE(3) xor UPDATE(6) ) & ( UPDATE(2) xor UPDATE(6) xor '1') & ( UPDATE(1) xor UPDATE(5) xor '1')  & ( UPDATE(0) xor UPDATE(4) xor '1' ) & ( UPDATE(3) xor UPDATE(5) xor UPDATE(6) ) & ( UPDATE(2) xor UPDATE(4) xor UPDATE(5) ) & ( UPDATE(1) xor UPDATE(3) xor UPDATE(4) );
    --end generate;
--
    ---- FS-128-288
    --RC_FF_128_288: IF (BS = BLOCK_SIZE_128 AND (TS = TWEAK_SIZE_9o4N or TS = TWEAK_SIZE_3N)) GENERATE
        --FAST_FORWARD(6 downto 0) <= ( UPDATE(3) xor UPDATE(5) xor UPDATE(6) ) & ( UPDATE(2) xor UPDATE(4) xor UPDATE(5) ) & ( UPDATE(1) xor UPDATE(3) xor UPDATE(4) ) & ( UPDATE(0) xor UPDATE(2) xor UPDATE(3) ) & ( UPDATE(1) xor UPDATE(2) xor UPDATE(5) xor UPDATE(6) xor '1' ) & ( UPDATE(0) xor UPDATE(1) xor UPDATE(4) xor UPDATE(5) xor '1' ) & ( UPDATE(0) xor UPDATE(3) xor UPDATE(4) xor UPDATE(5) xor UPDATE(6) );
    --end generate;
--
	---------------------------------------------------------------------------------
--
	---- OUTPUTS --------------------------------------------------------------------
	--CONST <= UPDATE;
	---------------------------------------------------------------------------------
  --
--END Dataflow;
