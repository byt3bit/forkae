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
ENTITY TB_ForkSkinnyRB_EncDec IS
    GENERIC (
        BS : BLOCK_SIZE := BLOCK_SIZE_128; 
        TS : TWEAK_SIZE := TWEAK_SIZE_9o4N
    );
END TB_ForkSkinnyRB_EncDec;
 

-- ARCHITECTURE : BEHAVIOR
----------------------------------------------------------------------------------
ARCHITECTURE Behavior OF TB_ForkSkinnyRB_EncDec IS 

    -- TEST PARAM ----------------------------------------------------------------
    shared variable ENDSIM : boolean := false;
    signal ENC_DEC_MODE : std_logic;

	-- DEBUG ----------------------------------------------------------------------
	CONSTANT DEBUG : STD_LOGIC := '0';
 
	-- CONSTANTS ------------------------------------------------------------------
	CONSTANT N : INTEGER := GET_BLOCK_SIZE(BS);
	CONSTANT T : INTEGER := GET_TWEAK_SIZE(BS, TS);
	CONSTANT W : INTEGER := GET_WORD_SIZE(BS);
	-------------------------------------------------------------------------------
	
	-- TEST VECTORS ---------------------------------------------------------------
	SIGNAL TV_P 	: STD_LOGIC_VECTOR((N - 1) DOWNTO 0);
	SIGNAL TV_C0 	: STD_LOGIC_VECTOR((N - 1) DOWNTO 0);
	SIGNAL TV_C1 	: STD_LOGIC_VECTOR((N - 1) DOWNTO 0);
	SIGNAL TV_K 	: STD_LOGIC_VECTOR(KEY_SIZE-1 DOWNTO 0);
	SIGNAL TV_T 	: STD_LOGIC_VECTOR(T-KEY_SIZE-1 DOWNTO 0);
	-------------------------------------------------------------------------------
	
	-- INPUTS ---------------------------------------------------------------------
    SIGNAL CLK 			: STD_LOGIC := '0';
    SIGNAL GO 			: STD_LOGIC := '0';
    SIGNAL TWEAKEY 			: STD_LOGIC_VECTOR((T - 1) DOWNTO 0);
    SIGNAL PLAINTEXT 	: STD_LOGIC_VECTOR((N - 1) DOWNTO 0);
	-------------------------------------------------------------------------------

	-- OUTPUTS --------------------------------------------------------------------
    SIGNAL DONE_1, DONE_2: STD_LOGIC;
    SIGNAL C0_1, C0_2 : STD_LOGIC_VECTOR((N - 1) DOWNTO 0);
    SIGNAL C1_1, C1_2 : STD_LOGIC_VECTOR((N - 1) DOWNTO 0);
	-------------------------------------------------------------------------------

    -- CLOCK PERIOD DEFINITIONS ---------------------------------------------------
    CONSTANT CLK_PERIOD : TIME := 10 NS;
	------------------------------------------------------------------------------- 
	
BEGIN

 
	-------------------------------------
    -- INSTANTIATE UNITS UNDER TEST (UUT) 
	-------------------------------------

    -- Non-parallel encryption-decryption architecture
    UUT1 : ENTITY work.ForkSkinnyRB
	GENERIC MAP (BS => BS, TS => TS, ARCH => ENCRYPTION_DECRYPTION, PARALLEL_ENC => '0', INSTANCE_SPECIFIC => '0')
	PORT MAP (
		CLK 			=> CLK,
        GO => GO,
        ENC_DEC_MODE => ENC_DEC_MODE,
        KEY => TWEAKEY,
        PLAINTEXT => PLAINTEXT,
        C1 => C1_1,
        C0 => C0_1,
        DONE => DONE_1
	);

    -- Parallel encryption-decryption architecture
    UUT2 : ENTITY work.ForkSkinnyRB
	GENERIC MAP (BS => BS, TS => TS, ARCH => ENCRYPTION_DECRYPTION, PARALLEL_ENC => '1', INSTANCE_SPECIFIC => '0')
	PORT MAP (
		CLK => CLK,
        GO => GO,
        ENC_DEC_MODE => ENC_DEC_MODE,
        KEY => TWEAKEY,
        PLAINTEXT => PLAINTEXT,
        C1 => C1_2,
        C0 => C0_2,
        DONE => DONE_2
	);

	-------------------------------------------------------------------------------

   -- CLOCK PROCESS --------------------------------------------------------------
   CLK_PROCESS : PROCESS
	BEGIN
        if ENDSIM = false then
            CLK <= '0'; WAIT FOR CLK_PERIOD/2;
            CLK <= '1'; WAIT FOR CLK_PERIOD/2;
        else
            wait;
        end if;
   END PROCESS;
	-------------------------------------------------------------------------------
 
   -- STIMULUS PROCESS -----------------------------------------------------------
   STIM_PROCESS : PROCESS

       BEGIN			
	
		----------------------------------------------------------------------------
		IF BS = BLOCK_SIZE_64 THEN
            TV_P <= X"530c61d35e8663c3";
            TV_K <= X"ed00c85b120d68618753e24bfd908f60";
            TV_T <= X"b2dbb41b422dfcd0";
            TV_C1 <= X"959ad62cf52c61ce";
            TV_C0 <= X"9756661a49bfca0c";
		ELSE
			IF TS = TWEAK_SIZE_2N THEN
                TV_P <= X"3a0c47767a26a68dd382a695e7022e25";
                TV_K <= X"009cec81605d4ac1d2ae9e3085d7a1f3";
                TV_T <= X"1ac123ebfc00fddcf01046ceeddfcab3";
                TV_C1 <= X"117243f2b023f2c7c4a4dd1e6358f05b";
                TV_C0 <= X"5455b78dbaaa132e4796c53a8ddb41f8";
            ELSIF TS = TWEAK_SIZE_3o2N THEN
                TV_P <= X"f4ff8a30ad6325fc8d285456d8e04f48";
                TV_K <= X"fc8f7f8bc0c9e5308739c22e6fffe59d";
                TV_T <= X"4a59177e1fd92001";
                TV_C1 <= X"eb5a0503ba8e28ca9e4b01a13506c36f";
                TV_C0 <= X"3588773541a323616b85fc28dc466b55";
            ELSIF TS = TWEAK_SIZE_9o4N then
                TV_P <= X"f4ff8a30ad6325fc8d285456d8e04f48";
                TV_K <= X"009cec81605d4ac1d2ae9e3085d7a1f3";
                TV_T <= X"1ac123ebfc00fddcf01046ceeddfcab3deadbeef00000000";
                TV_C1 <= X"02a6bad60993f59f619ceda4057104e1";
                TV_C0 <= X"0b54959b86ef32023a4df92d69a71353";
			END IF;	
		END IF;
		----------------------------------------------------------------------------
		
		wait for clk_period;	
		
        -- Decryption stimuli
		----------------------------------------------------------------------------
		TWEAKEY			<= TV_K & TV_T;
		PLAINTEXT	<= TV_C0; 
		----------------------------------------------------------------------------

        wait until ENC_DEC_MODE = '0';

        -- Encryption stimuli
		----------------------------------------------------------------------------
		TWEAKEY			<= TV_K & TV_T;
		PLAINTEXT	<= TV_P;
		----------------------------------------------------------------------------

         wait;

    end PROCESS;



    CHECKER_PROCESS: process 

        -- WATCHDOG TIMER
        VARIABLE WATCHDOG : INTEGER := 1000;

        procedure advance_time is
        begin
            WATCHDOG := WATCHDOG - 1;
            if WATCHDOG <= 0 then
                assert false report "Watchdog time exceeded" severity failure;
            end if;
            wait for CLK_PERIOD;
        end procedure advance_time;

    begin


		wait for clk_period;

        report " ";
        report "Testing decryption/reconstruction...";
        report " ";


        ----------------------------------------------------------------------------
        ENC_DEC_MODE <= '1';
        GO <= '1';
        wait for clk_period;
        GO <= '0';
        ----------------------------------------------------------------------------
    
        -- WAIT FOR RESULT AND TEST
        while (DONE_1 = '0') loop
            advance_time;
        end loop;

        -- P (decryption)
        ----------------------------------------------------------------------------
        WAIT FOR CLK_PERIOD;
        ASSERT (C0_1 = TV_P) REPORT "TESTBENCH FAILED SERIAL P" SEVERITY FAILURE; 
        report "Serial Decryption -- P OK";
        ASSERT (C1_2 = TV_P) REPORT "TESTBENCH FAILED PARALLEL P" SEVERITY FAILURE; 
        report "Parallel Decryption -- P OK";
        ----------------------------------------------------------------------------

        -- If the implementation is not parallel, the results don't come at the same time
        while (DONE_1 = '0') loop
            advance_time;
        end loop;

        -- C1 (reconstruction)
        ----------------------------------------------------------------------------
        ASSERT (C1_1 = TV_C1) REPORT "TESTBENCH FAILED SERIAL C1" SEVERITY FAILURE;
        report "Serial Decryption -- C1 OK";
        ASSERT (C0_2 = TV_C1) REPORT "TESTBENCH FAILED PARALLEL C1" SEVERITY FAILURE;
        report "Paralllel Decryption -- C1 OK";
        ----------------------------------------------------------------------------


        report " ";
        report "Testing encryption...";
        report " ";

        ----------------------------------------------------------------------------
        wait for clk_period;
        ENC_DEC_MODE <= '0';
        GO <= '1';
        wait for clk_period;
        GO <= '0';
        ----------------------------------------------------------------------------
    
        -- WAIT FOR RESULT AND TEST
        while (DONE_1 = '0') loop
            advance_time;
        end loop;

        -- C0 
        ----------------------------------------------------------------------------
        wait for clk_period;
        ASSERT (C0_1 = TV_C0) REPORT "TESTBENCH FAILED SERIAL C0" SEVERITY FAILURE; 
        report "Serial Encryption -- C0 OK";
        ASSERT (C0_2 = TV_C0) REPORT "TESTBENCH FAILED PARALLEL C0" SEVERITY FAILURE; 
        report "Parallel Encryption -- C0 OK";
        ASSERT (C1_2 = TV_C1) REPORT "TESTBENCH FAILED PARALLEL C1" SEVERITY FAILURE;
        report "Parallel Encryption -- C1 OK";
        ----------------------------------------------------------------------------

        -- If the implementation is not parallel, the results don't come at the same time
        while (DONE_1 = '0') loop
            advance_time;
        end loop;

        -- C1
        ----------------------------------------------------------------------------
        ASSERT (C1_1 = TV_C1) REPORT "TESTBENCH FAILED C1" SEVERITY FAILURE;
        report "Serial Encryption -- C1 OK";
        ----------------------------------------------------------------------------

        wait for CLK_PERIOD;


        -- Finish the simulation
        ----------------------------------------------------------------------------
        ENDSIM := true;
        report "Simulation finished successfully.";
        wait;
        -------------------------------------------------------------------------------

    end process;

END;
