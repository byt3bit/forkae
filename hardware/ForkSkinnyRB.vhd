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

library ieee;
use ieee.std_logic_1164.all;

use work.forkskinnypkg.all;


entity ForkSkinnyRB IS
    GENERIC (   BS : BLOCK_SIZE := BLOCK_SIZE_64; -- Block size: see ForkSkinnyPKG
                TS : TWEAK_SIZE := TWEAK_SIZE_3N; -- Tweakey size: see ForkSkinnyPKG
                ARCH: ENC_DEC := ENCRYPTION; -- Encryption-only (ENCRYPTION) or encryption-decryption (ENCRYPTION_DECRYPTION) architecture?
                PARALLEL_ENC : std_logic := '0'; -- Branches after forking in parallel?
                INSTANCE_SPECIFIC : std_logic := '0' -- Enable or disable instance-specific optimization (trades off area for critical path)
                );
    PORT ( CLK			    : in  std_logic;
           -- CONTROL PORTS --------------------------------
           GO		        : in  std_logic;
           ENC_DEC_MODE     : in  std_logic; -- Encryption (0) or decryption (1)
           DONE			    : out std_logic;
           -- DATA PORTS -----------------------------------
           KEY			    : in  std_logic_vector ((GET_TWEAK_SIZE(BS, TS) - 1) downto 0); 
           PLAINTEXT	    : in  std_logic_vector ((GET_BLOCK_SIZE(BS) - 1) downto 0); -- Input for M (or C0 in case of decryption)
           C1	            : out std_logic_vector ((GET_BLOCK_SIZE(BS)	- 1) downto 0); -- Output for C1
           C0	            : out std_logic_vector ((GET_BLOCK_SIZE(BS)	- 1) downto 0)); -- Output for C0 (or M in case of decryption)
END ForkSkinnyRB;



ARCHITECTURE behav OF ForkSkinnyRB IS

	-- CONSTANTS ------------------------------------------------------------------
	constant N : integer := GET_BLOCK_SIZE(BS);
	constant T : integer := GET_TWEAK_SIZE(BS, TS);

	
	-- SIGNALS --------------------------------------------------------------------

    -- State intermediates
    SIGNAL CURRENT_STATE, NEXT_STATE, FORWARD_ROUND_OUT, INVERSE_ROUND_OUT, BRANCH_CONSTANT, BRANCH_CONSTANT2, FORWARD_ROUND_OUT2 : STD_LOGIC_VECTOR((N - 1) DOWNTO 0);
    signal FORKING_STATE, FORKING_IN: std_logic_vector(N-1 downto 0);
    signal MUX_FORWARD_INVERSE: std_logic_vector(N-1 downto 0);

    -- Keys
    signal CURRENT_KEY, NEXT_KEY, KEY_FORWARD, KEY_INVERSE, KEY_DECRYPT, KEY_FF, KEY_FF_INTERMEDIATE: std_logic_vector(T-1 downto 0);
    signal ROUND_KEY: std_logic_vector(T-1 downto 0);
    signal ZEROIZED, ZEROIZED_FF: std_logic_vector(63 downto 0);
    signal TK1, NEXT_TK1 : std_logic_vector (N-1 downto 0);
    signal TK2, NEXT_TK2 : std_logic_vector (N-1 downto 0);
    signal TK3, NEXT_TK3 : std_logic_vector (N-1 downto 0);
	
    -- Control
    signal MODE_DECRYPT, WE_FORK, WE_TK, WE_TK_AUGMENTED, SET_DECRYPTION_KEY, SET_DECRYPTION_KEY_AUGMENTED, INTERNAL_GO, LOAD_IS, SEL_IS: std_logic;
    signal IS_SELECT, KEY_SELECT : std_logic_vector(1 downto 0); -- 2-bit MUX select
    signal FORK_CONDITION : std_logic;
    signal EVEN_ROUND, UNEVEN_ROUND: std_logic;
    signal WE_TK1_AUGMENTED, WE_TK2_AUGMENTED, WE_TK3_AUGMENTED: std_logic;

    -- Status 
    signal DONE_BEFORE_FORK, DONE_C1_BRANCH, DONE_C0_BRANCH_ENC, DONE_C0_BRANCH_DEC, DONE_PLAINTEXT, DONE_FSM : std_logic;
    signal DONE_PLAINTEXT_INTERNAL: std_logic; 

    -- Round constant
    signal CONST_ENC, CONST_DEC, CONST_FF : std_logic_vector(6 downto 0);

BEGIN

    
    ------------------
    -- FSM for EncDec
    ------------------

    FSM_EncDec_X: if ARCH = ENCRYPTION_DECRYPTION generate

        FSM_X: entity work.FSM_ForkSkinny
        port map(CLK => CLK,
                 GO => GO,
                 ENC_DEC_MODE => ENC_DEC_MODE,
                 DONE_FSM => DONE_FSM,
                 MODE_DECRYPT => MODE_DECRYPT,
                 SET_DEC_KEY => SET_DECRYPTION_KEY,
                 WE_TK => WE_TK,
                 INTERNAL_GO => INTERNAL_GO,
                 LOAD_IS => LOAD_IS
                );
    end generate;


    -------------------------
    -- Internal cipher state
    -------------------------

    -- State register in encryption architecure
    GEN_IS_ENC_X: if ARCH = ENCRYPTION generate
        REG_INTERNAL_STATE : ENTITY work.ScanFF
        GENERIC MAP (SIZE => N)
        PORT MAP (
            CLK 	=> CLK,
            SE		=> SEL_IS, 
            D		=> FORWARD_ROUND_OUT,
            DS		=> NEXT_STATE,
            Q		=> CURRENT_STATE
        );
    end generate;

    -- State register in encryption architecure
    GEN_IS_ENCDEC_X: if ARCH = ENCRYPTION_DECRYPTION generate
        REG_INTERNAL_STATE : ENTITY work.ScanFF
        GENERIC MAP (SIZE => N)
        PORT MAP (
            CLK 	=> CLK,
            SE		=> SEL_IS, 
            D		=> NEXT_STATE,
            DS		=> INVERSE_ROUND_OUT,
            Q		=> CURRENT_STATE
        );
    end generate;


    ------------------
    -- Round Constant
    ------------------

    -- Encryption only
    CONSTANT_ENC_X: if ARCH = ENCRYPTION generate
        ConstGen : ENTITY work.RoundConstantEnc
        PORT MAP (
            CLK	=> CLK,
            INIT	=> GO,
            CONST	=> CONST_ENC
        );
    end generate;

    -- Encryption/Decryption
    CONSTANT_ENC_DEC_X: if ARCH = ENCRYPTION_DECRYPTION generate
        ConstGen : ENTITY work.RoundConstantEncDec
        generic map (BS => BS, TS => TS)
        PORT MAP (
            CLK	=> CLK,
            INIT	=> INTERNAL_GO,
            DECRYPT	=> MODE_DECRYPT,
            CONST_ENC	=> CONST_ENC,
            CONST_DEC	=> CONST_DEC
        );
    end generate;

    -- Fast Forward functionality in case parallel encryption is enabled
    GEN_RC_FF_X: if PARALLEL_ENC = '1' generate
        RC_FF_X: entity work.RoundConstantFF 
        generic map (BS => BS, TS => TS)
        port map(CONST => CONST_ENC,
                 CONST_FF => CONST_FF);
    end generate;

    
    -----------------
    -- Forking state
    -----------------

    GEN_FORKING_STATE_SPECIAL: if PARALLEL_ENC = '1' and ARCH = ENCRYPTION generate 
        -- Register at the fork
        L : ENTITY work.ScanFF -- For the encryption-only and parallel architecture, the forking state does not require a WE.
        GENERIC MAP (SIZE => N)
        PORT MAP (
            CLK 	=> CLK,
            SE		=> DONE_BEFORE_FORK,
            D		=> FORWARD_ROUND_OUT2,
            DS		=> BRANCH_CONSTANT,
            Q		=> FORKING_STATE
        );
    end generate; 

    GEN_FORKING_STATE_REGULAR: if PARALLEL_ENC = '0' or ARCH = ENCRYPTION_DECRYPTION generate
        -- Register at the fork
        L : ENTITY work.ScanFF -- All other architectures require write enable at the forking stage
        GENERIC MAP (SIZE => N)
        PORT MAP (
            CLK 	=> CLK,
            SE		=> WE_FORK,
            D		=> FORKING_STATE,
            DS		=> FORKING_IN,
            Q		=> FORKING_STATE
        );
    end generate; 


    -- Second forward round function for parallel versions
    FORK_PARALLEL_X: if PARALLEL_ENC = '1' generate
        RoundFunction2_X : ENTITY work.RoundFunction 
        GENERIC MAP (BS => BS, TS => TS)
        PORT MAP (
            CLK			=> CLK,
            CONST			=> CONST_FF,
            ROUND_KEY	=> KEY_FF,
            ROUND_IN		=> FORKING_STATE,
            ROUND_OUT	=> FORWARD_ROUND_OUT2
        );
    end generate;

    
    --------------------
    -- Tweakey schedule
    --------------------

    -- Register for TK1, present for all ForkSkinny members
    REG_TK1 : ENTITY work.ScanFF
    GENERIC MAP (SIZE => N)
    PORT MAP (
        CLK 	=> CLK,
        SE		=> WE_TK1_AUGMENTED, 
        D		=> TK1,
        DS		=> NEXT_TK1,
        Q		=> TK1
    );

    -- Full TK2?
    GEN_FULL_TK2_X: if TS = TWEAK_SIZE_2N or TS = TWEAK_SIZE_9o4N or TS = TWEAK_SIZE_3N generate
        REG_TK2 : ENTITY work.ScanFF
        GENERIC MAP (SIZE => N)
        PORT MAP (
            CLK 	=> CLK,
            SE		=> WE_TK2_AUGMENTED, 
            D		=> TK2,
            DS		=> NEXT_TK2,
            Q		=> TK2
        );
    end generate;

    -- Half full TK2?
    GEN_HALF_TK2_X: if TS = TWEAK_SIZE_3o2N generate
        REG_TK2 : ENTITY work.ScanFF
        GENERIC MAP (SIZE => N/2)
        PORT MAP (
            CLK 	=> CLK,
            SE		=> WE_TK2_AUGMENTED, 
            D		=> TK2(N/2 - 1 downto 0),
            DS		=> NEXT_TK2(N/2 - 1 downto 0),
            Q		=> TK2(N/2 - 1 downto 0)
        );
    end generate;

    -- Full TK3?
    GEN_FULL_TK3_X: if TS = TWEAK_SIZE_3N generate
        REG_TK2 : ENTITY work.ScanFF
        GENERIC MAP (SIZE => N)
        PORT MAP (
            CLK 	=> CLK,
            SE		=> WE_TK3_AUGMENTED, 
            D		=> TK3,
            DS		=> NEXT_TK3,
            Q		=> TK3
        );
    end generate;

    -- Half full TK3?
    GEN_HALF_TK3_X: if TS = TWEAK_SIZE_9o4N generate
        REG_TK3 : ENTITY work.ScanFF
        GENERIC MAP (SIZE => N/2)
        PORT MAP (
            CLK 	=> CLK,
            SE		=> WE_TK3_AUGMENTED, 
            D		=> TK3(N/2 - 1 downto 0),
            DS		=> NEXT_TK3(N/2 - 1 downto 0),
            Q		=> TK3(N/2 - 1 downto 0)
        );
    end generate;


    -- Assignment of TK inputs and outputs
    NEXT_TK1 <= NEXT_KEY(T-1 downto T - N);

    GEN_TK2_X: if TS = TWEAK_SIZE_2N or TS = TWEAK_SIZE_3o2N generate
        NEXT_TK2(T-N-1 downto 0) <= NEXT_KEY(T-N-1 downto 0);
        CURRENT_KEY <= TK1 & TK2(T-N-1 downto 0);
    end generate;

    GEN_TK3_X: if TS = TWEAK_SIZE_3N or TS = TWEAK_SIZE_9o4N generate
        NEXT_TK2 <= NEXT_KEY(T-N-1 downto T-2*N);
        NEXT_TK3(T-2*N-1 downto 0) <= NEXT_KEY(T-2*N-1 downto 0);
        CURRENT_KEY <= TK1 & TK2 & TK3(T-2*N-1 downto 0);
    end generate;


    --------------------------------------
    -- Forward and Inverse Round Function
    --------------------------------------

	RoundFunction : ENTITY work.RoundFunction
	GENERIC MAP (BS => BS, TS => TS)
	PORT MAP (
		CLK			=> CLK,
		CONST			=> CONST_ENC,
        ROUND_KEY	=> ROUND_KEY,
		ROUND_IN		=> CURRENT_STATE,
        ROUND_OUT	=> FORWARD_ROUND_OUT
	);
    
    INVERSE_ROUND_FUNCTION_X: if ARCH = ENCRYPTION_DECRYPTION generate
        InverseRoundFunction_X : ENTITY work.InverseRoundFunction  -- Inverse Round Function if necessary (EncDec architecture)
            GENERIC MAP (BS => BS, TS => TS)
            PORT MAP (
                CLK			=> CLK,
                CONST			=> CONST_DEC,
                ROUND_KEY	=> ROUND_KEY,
                ROUND_IN		=> CURRENT_STATE,
                ROUND_OUT	=> INVERSE_ROUND_OUT
            );
    end generate;


    -------------------
    -- Branch Constant
    -------------------

    GEN_BC_BEFORE: if ARCH = ENCRYPTION and PARALLEL_ENC = '1' generate
        -- Branch constant BEFORE forking state
        BranchConstant: entity work.BranchConstant
        generic map (BS => BS)
        port map (
            L => FORWARD_ROUND_OUT,
            BRANCH_CONSTANT => BRANCH_CONSTANT 
        );
    end generate;

    GEN_BC_DOUBLE: if ARCH = ENCRYPTION_DECRYPTION and PARALLEL_ENC = '1' generate
         
        BranchConstant: entity work.BranchConstant -- Branch constant BEFORE forking state for encryption
        generic map (BS => BS)
        port map (
            L => FORWARD_ROUND_OUT,
            BRANCH_CONSTANT => BRANCH_CONSTANT
        );

        BranchConstant2: entity work.BranchConstant -- Branch constant AFTER forking state for decryption
        generic map (BS => BS)
        port map (
            L => FORKING_STATE,
            BRANCH_CONSTANT => BRANCH_CONSTANT2
        );
    end generate;

    GEN_BC_AFTER: if PARALLEL_ENC = '0' generate
        -- Branch constant AFTER forking state
        BranchConstant: entity work.BranchConstant
        generic map (BS => BS)
        port map (
            L => FORKING_STATE,
            BRANCH_CONSTANT => BRANCH_CONSTANT 
        );
    end generate;
	

    -----------------
	-- Key Expansion 
    -----------------

    -- Forward Key Schedule
    KS_Forward_X : ENTITY work.ForwardKeySchedule
	GENERIC MAP (BS => BS, TS => TS)
	PORT MAP (
		KEY			=> CURRENT_KEY,
		NEXT_KEY	=> KEY_FORWARD
	);

    KS_DEC_X: if ARCH = ENCRYPTION_DECRYPTION generate

        -- Inverse Key Schedule
        KS_Inverse_X : ENTITY work.InverseKeySchedule
        GENERIC MAP (BS => BS, TS => TS)
        PORT MAP (
            KEY			=> CURRENT_KEY,
            NEXT_KEY	=> KEY_INVERSE
        );

        -- Compute decryption key
        KS_Decryption_Key_X : ENTITY work.DecryptionKey
        GENERIC MAP (BS => BS, TS => TS)
        PORT MAP (
            KEY			=> CURRENT_KEY,
            NEXT_KEY	=> KEY_DECRYPT
        );

    end generate;





    -----------------------------------------------------
    -- State reduction for FSki-128-192 and FSki-128-288
    -----------------------------------------------------

    -- Keep track of EVEN rounds, zeroize TK2 (for 128-192) or TK3 (for 128-288) in odd rounds
    GEN_EVEN_ROUNDS_X: if BS = BLOCK_SIZE_128 and (TS = TWEAK_SIZE_3o2N or TS = TWEAK_SIZE_9o4N) generate

       GEN_EVEN_ROUNDS_ENC_DEC: if ARCH = ENCRYPTION_DECRYPTION generate
           process (clk)
           begin
               if (rising_edge (clk)) then
                   if GO = '1' and INTERNAL_GO = '1' then
                       EVEN_ROUND <= not ENC_DEC_MODE; 
                   elsif ((DONE_PLAINTEXT and MODE_DECRYPT) = '1') then
                       EVEN_ROUND <= EVEN_ROUND;
                   else 
                       EVEN_ROUND <= not EVEN_ROUND;
                   end if;
               end if;
           end process;

           process (clk)
           begin
               if (rising_edge (clk)) then
                   if GO = '1' and INTERNAL_GO = '1' then
                      UNEVEN_ROUND <= ENC_DEC_MODE; 
                   elsif ((DONE_PLAINTEXT and MODE_DECRYPT) = '1') then
                      UNEVEN_ROUND <= UNEVEN_ROUND;
                   else 
                      UNEVEN_ROUND <= EVEN_ROUND; 
                   end if;
               end if;
           end process;

       end generate;

       GEN_EVEN_ROUNDS_ENC: if ARCH = ENCRYPTION generate
           process (clk)
           begin
               if (rising_edge (clk)) then
                   if GO = '1' then
                       EVEN_ROUND <= '1'; 
                   else 
                       EVEN_ROUND <= not EVEN_ROUND;
                   end if;
               end if;
           end process;

           process (clk)
           begin
               if (rising_edge (clk)) then
                   if GO = '1' then
                       UNEVEN_ROUND <= '0'; 
                   else
                       UNEVEN_ROUND <= EVEN_ROUND; 
                   end if;
               end if;
           end process;
       end generate;

       


       Control_EncDec_X: if ARCH = ENCRYPTION_DECRYPTION generate

           GEN_EVEN_ROUNDS_192: if TS = TWEAK_SIZE_3o2N generate
               WE_TK2_AUGMENTED <= (GO and not MODE_DECRYPT) or SET_DECRYPTION_KEY or EVEN_ROUND; 
           end generate;

           GEN_EVEN_ROUNDS_288: if TS = TWEAK_SIZE_9o4N generate
               WE_TK1_AUGMENTED <= WE_TK_AUGMENTED; -- TK1 can always be written
               WE_TK2_AUGMENTED <= WE_TK_AUGMENTED;
               WE_TK3_AUGMENTED <= (GO and not MODE_DECRYPT) or SET_DECRYPTION_KEY or EVEN_ROUND; 
           end generate;

       end generate;

       Control_Enc_X: if ARCH = ENCRYPTION generate
            INTERNAL_GO <= '1';

            GEN_EVEN_ROUNDS_192: if TS = TWEAK_SIZE_3o2N generate
                WE_TK2_AUGMENTED <= GO or EVEN_ROUND; 
            end generate;

           GEN_EVEN_ROUNDS_288: if TS = TWEAK_SIZE_9o4N generate
                WE_TK2_AUGMENTED <= WE_TK_AUGMENTED; 
                WE_TK3_AUGMENTED <= GO or EVEN_ROUND; 
            end generate;
        end generate;

       ZEROIZED <= CURRENT_KEY(63 downto 0) when UNEVEN_ROUND = '0' else (others => '0'); -- Synthesized to AND, not MUX
       ROUND_KEY <= CURRENT_KEY(T-1 downto 64) & ZEROIZED;

    end generate;

    -- FS-128-192 parallel encryption: zeroization logic for the second branch
    GEN_ZEROIZATION: if PARALLEL_ENC = '1' and (TS = TWEAK_SIZE_3o2N or TS = TWEAK_SIZE_9o4N) generate
        ZEROIZED_FF <= KEY_FF_INTERMEDIATE(63 downto 0) when EVEN_ROUND = '0' else (others => '0');
        KEY_FF <= KEY_FF_INTERMEDIATE(T-1 downto 64) & ZEROIZED_FF;
    end generate;
    GEN_NO_ZEROIZATION: if PARALLEL_ENC = '1' and (TS /= TWEAK_SIZE_3o2N and TS /= TWEAK_SIZE_9o4N) generate
        KEY_FF <= KEY_FF_INTERMEDIATE;
    end generate;


    -------------------------------
    -- Selection signals and MUXes
    -------------------------------

    SELECTION_ENC: if ARCH = ENCRYPTION generate

        NEXT_KEY <= KEY when GO = '1' else KEY_FORWARD;

        SELECTION_ENC_PARA: if PARALLEL_ENC = '1' generate
            NEXT_STATE <= PLAINTEXT; -- Parallel encryption: no mux
            SEL_IS <= GO; -- NO FSM, so assign this manually
            KEY_FF_X: entity work.KeyExpansionFF generic map (BS => BS, TS => TS) port map(KEY => CURRENT_KEY, KEY_FF => KEY_FF_INTERMEDIATE); -- Fast-forwarding the key schedule
        end generate;


        SELECTION_ENC_NOT_PARA: if PARALLEL_ENC = '0' generate
            NEXT_STATE <= BRANCH_CONSTANT when DONE_C0_BRANCH_ENC = '1' else PLAINTEXT; -- Non-parallel encryption: MUX to load forking state when needed
            SEL_IS <= GO or DONE_C0_BRANCH_ENC; 
            FORKING_IN <= FORWARD_ROUND_OUT; -- No MUX
            WE_FORK <= DONE_BEFORE_FORK or DONE_C0_BRANCH_ENC; -- Write enable
        end generate;

    end generate;

    SELECTION_ENCDEC: if ARCH = ENCRYPTION_DECRYPTION generate

        SET_DECRYPTION_KEY_AUGMENTED <= (MODE_DECRYPT and (SET_DECRYPTION_KEY or DONE_PLAINTEXT));
        KEY_SELECT <= (SET_DECRYPTION_KEY or (MODE_DECRYPT and not GO)) & (SET_DECRYPTION_KEY_AUGMENTED or GO); -- Uses external GO, SET_DECRYPTION_KEY takes preference
        WE_TK_AUGMENTED <= WE_TK or GO;

        -- For TK1 of FS-128-192 and FS-128-256, the set decryption key operation is equal to doing nothing
        GEN_REDUCED_TK_MUX: if BS = BLOCK_SIZE_128 and (TS = TWEAK_SIZE_2N or TS = TWEAK_SIZE_3o2N) generate

            NO_GEN_INST_SPECIFIC: if INSTANCE_SPECIFIC = '0' generate
                WITH KEY_SELECT select
                    NEXT_KEY <= KEY_INVERSE when "10",
                                KEY_DECRYPT when "11",
                                KEY_FORWARD when "00",
                                KEY when others; -- 01
            end generate;

            -- Save multiplexer
            GEN_INST_SPECIFIC: if INSTANCE_SPECIFIC = '1' generate
                WITH KEY_SELECT select
                    NEXT_KEY(T - 1 downto T - N) <= KEY_INVERSE(T - 1 downto T - N) when "10",
                                KEY_FORWARD(T - 1 downto T - N) when "00",
                                KEY(T - 1 downto T - N) when others; -- 01 (WE_TK1 should be 0 when 11)
                WITH KEY_SELECT select
                    NEXT_KEY(T - N - 1 downto 0) <= KEY_INVERSE(T - N - 1 downto 0) when "10",
                                KEY_DECRYPT(T - N - 1 downto 0) when "11",
                                KEY_FORWARD(T - N - 1 downto 0) when "00",
                                KEY(T - N - 1 downto 0) when others; -- 01
            end generate;
        end generate;

        -- For the other instances, we do need the extra MUX option
        GEN_FULL_TK_MUX: if BS = BLOCK_SIZE_64 or TS = TWEAK_SIZE_9o4N generate
            WITH KEY_SELECT select
                NEXT_KEY <= KEY_INVERSE when "10",
                            KEY_DECRYPT when "11",
                            KEY_FORWARD when "00",
                            KEY when others; -- 01
        end generate;

        SELECTION_ENCDEC_PARA: if PARALLEL_ENC = '1' generate

            SEL_IS <= not LOAD_IS and (MODE_DECRYPT and not DONE_PLAINTEXT);
            IS_SELECT <= (LOAD_IS or (MODE_DECRYPT and DONE_PLAINTEXT)) & LOAD_IS;
            with IS_SELECT select
                NEXT_STATE <= FORWARD_ROUND_OUT when "00",
                          BRANCH_CONSTANT2 when "10",
                          PLAINTEXT when others; 
            FORK_CONDITION <= (not MODE_DECRYPT and DONE_BEFORE_FORK) or (MODE_DECRYPT and (DONE_C0_BRANCH_DEC or DONE_PLAINTEXT)); -- Mux selection signal
            MUX_FORWARD_INVERSE <= BRANCH_CONSTANT when MODE_DECRYPT = '0' else INVERSE_ROUND_OUT; -- MUX
            FORKING_IN <= MUX_FORWARD_INVERSE when FORK_CONDITION = '1' else FORWARD_ROUND_OUT2; -- MUX
            WE_FORK <= not MODE_DECRYPT or (MODE_DECRYPT and (DONE_C0_BRANCH_DEC or DONE_PLAINTEXT)); -- WE always on when encrypting parallel, only for storage when decrypting

            KEY_FF_X: entity work.KeyExpansionFF generic map (BS => BS, TS => TS) port map(KEY => CURRENT_KEY, KEY_FF => KEY_FF_INTERMEDIATE); 

        end generate;

        SELECTION_ENCDEC_NOT_PARA: if PARALLEL_ENC = '0' generate

            SEL_IS <= not LOAD_IS and (MODE_DECRYPT and not DONE_PLAINTEXT);
            IS_SELECT <= LOAD_IS & ((not MODE_DECRYPT and DONE_C0_BRANCH_ENC) or (MODE_DECRYPT and DONE_PLAINTEXT));
            with IS_SELECT select
                NEXT_STATE <= FORWARD_ROUND_OUT when "00",
                              BRANCH_CONSTANT when "01",
                              PLAINTEXT when others;

            FORKING_IN <= FORWARD_ROUND_OUT when MODE_DECRYPT = '0' else INVERSE_ROUND_OUT; -- MUX
            WE_FORK <= (MODE_DECRYPT and (DONE_C0_BRANCH_DEC or DONE_PLAINTEXT)) or (not MODE_DECRYPT and (DONE_BEFORE_FORK or DONE_C0_BRANCH_ENC)); -- WE
            
        end generate;

    end generate;


    WE_TK1_128: if BS = BLOCK_SIZE_128 and (TS = TWEAK_SIZE_3o2N or TS = TWEAK_SIZE_2N) generate
        WE_TK1_AUGMENTED <= not SET_DECRYPTION_KEY_AUGMENTED; -- TK1^48 === not updating the key schedule
    end generate;

    NORMAL_TK_X: if (TS /= TWEAK_SIZE_3o2N and TS /= TWEAK_SIZE_9o4N) generate
       GEN_ENC_WE_TK1: if ARCH = ENCRYPTION or BS = BLOCK_SIZE_64 generate
           WE_TK_AUGMENTED <= WE_TK_AUGMENTED;
       end generate;
       WE_TK2_AUGMENTED <= WE_TK_AUGMENTED; 
       WE_TK3_AUGMENTED <= WE_TK_AUGMENTED;
       ROUND_KEY <= CURRENT_KEY;
    end generate;



    ------------------
    -- Status signals
    ------------------

    STATUS_64 : IF BS = BLOCK_SIZE_64 AND TS = TWEAK_SIZE_3N GENERATE
        -- Encryption
        DONE_BEFORE_FORK <= '1' WHEN (CONST_ENC = "1100111") ELSE '0'; -- RC 17
        DONE_C0_BRANCH_ENC <= '1' WHEN (CONST_ENC = "1010011") ELSE '0'; -- RC 40
        DONE_C1_BRANCH <= '1' WHEN (CONST_ENC = "1110001") ELSE '0'; -- RC 63 + 1 (+1 because we the output is now register and not next_round)
        
        -- Decryption (if necessary)
        STATUS_DEC_X: if ARCH = ENCRYPTION_DECRYPTION generate 
            DONE_C0_BRANCH_DEC <= '1' WHEN (CONST_DEC = "1001111") ELSE '0'; -- RC 18
            DONE_PLAINTEXT <= '1' WHEN (CONST_DEC = "0000001") ELSE '0'; -- RC 1
            DONE_PLAINTEXT_INTERNAL <= '1' WHEN (CONST_DEC = "0000011") ELSE '0'; -- RC 2
        end generate;
    end generate;

    STATUS_128_2 : IF BS = BLOCK_SIZE_128 AND (TS = TWEAK_SIZE_2N or TS = TWEAK_SIZE_3o2N) GENERATE
        -- Encryption
        DONE_BEFORE_FORK <= '1' WHEN (CONST_ENC = "1111010") ELSE '0'; -- RC 21
        DONE_C0_BRANCH_ENC <= '1' WHEN (CONST_ENC = "0010101") ELSE '0'; -- RC 48 
        DONE_C1_BRANCH <= '1' WHEN (CONST_ENC = "0110010") ELSE '0'; -- RC 75 + 1 (+1 because we the output is now register and not next_round)

        -- Decryption (if necessary)
        STATUS_DEC_X: if ARCH = ENCRYPTION_DECRYPTION generate
            DONE_C0_BRANCH_DEC <= '1' WHEN (CONST_DEC = "1110101") ELSE '0'; -- RC 22
            DONE_PLAINTEXT <= '1' WHEN (CONST_DEC = "0000001") ELSE '0'; -- RC 1
            DONE_PLAINTEXT_INTERNAL <= '1' WHEN (CONST_DEC = "0000011") ELSE '0'; -- RC 2
        end generate;
    end generate;

	STATUS_128_3 : IF BS = BLOCK_SIZE_128 AND (TS = TWEAK_SIZE_9o4N or TS = TWEAK_SIZE_3N) GENERATE 
        -- Encryption
        DONE_BEFORE_FORK <= '1' WHEN (CONST_ENC = "0101110") ELSE '0'; -- RC 25
        DONE_C0_BRANCH_ENC <= '1' WHEN (CONST_ENC = "0000010") ELSE '0'; -- RC 56
        DONE_C1_BRANCH <= '1' WHEN (CONST_ENC = "0100001") ELSE '0'; -- RC 87 + 1 (+1 because we the output is now register and not next_round)

        -- Decryption (if necessary)
        STATUS_DEC_X: if ARCH = ENCRYPTION_DECRYPTION generate
            DONE_C0_BRANCH_DEC <= '1' WHEN (CONST_DEC = "1011100") ELSE '0'; -- RC 26
            DONE_PLAINTEXT <= '1' WHEN (CONST_DEC = "0000001") ELSE '0'; -- RC 1
            DONE_PLAINTEXT_INTERNAL <= '1' WHEN (CONST_DEC = "0000011") ELSE '0'; -- RC 2
        end generate;
    end generate;


    -----------
    -- Outputs 
    -----------

    -- Encapsulate the fact that different architectures produce the outputs at different locations in the circuit
    NO_OUTPUT_REMAP: if PARALLEL_ENC = '0' generate
        C1 <= CURRENT_STATE;
        C0 <= FORKING_STATE;
        end generate;
    GEN_OUTPUT_REMAP: if PARALLEL_ENC = '1' generate
        C1 <= FORKING_STATE;
        C0 <= CURRENT_STATE;
    end generate;
    ------

    -- Generate DONE signals
    DONE_X: if ARCH = ENCRYPTION generate
        DONE <= DONE_C1_BRANCH or DONE_C0_BRANCH_ENC;
    end generate;

    DONE_ED_X: if ARCH = ENCRYPTION_DECRYPTION generate

        DONE <= (DONE_PLAINTEXT and MODE_DECRYPT) or ((DONE_C1_BRANCH or DONE_C0_BRANCH_ENC) and not MODE_DECRYPT);
        DONE_ED_NP: if PARALLEL_ENC = '0' generate
            DONE_FSM <= DONE_C1_BRANCH or (DONE_PLAINTEXT_INTERNAL and MODE_DECRYPT); 
        end generate;

        DONE_ED_P: if PARALLEL_ENC = '1' generate
            DONE_FSM <= (not MODE_DECRYPT and (DONE_C0_BRANCH_ENC or DONE_C1_BRANCH)) or (DONE_PLAINTEXT_INTERNAL and MODE_DECRYPT); 
        end generate;

    end generate;

end behav;
