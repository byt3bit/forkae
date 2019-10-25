----------------------------------------------------------------------------------
-- Copyright 2019:
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

-------------------
--- FSM FORKSKINNY
-------------------
library ieee;
    use ieee.std_logic_1164.all;
    
entity FSM_ForkSkinny is 
    port (
        -- CLOCK
        CLK : in std_logic;

        -- CONTROL INPUTS
        GO: in std_logic;
        ENC_DEC_MODE: in std_logic;

        -- STATUS INPUTS
        DONE_FSM: in std_logic;

        -- CONTROL OUTPUTS
        MODE_DECRYPT: out std_logic;
        SET_DEC_KEY: out std_logic;
        WE_TK: out std_logic;
        INTERNAL_GO: out std_logic;
        LOAD_IS: out std_logic
    );
end entity FSM_ForkSkinny;

architecture rtl of FSM_ForkSkinny is

	-- Build an enumerated type for the state machine
	type state_type is (INIT, ENCRYPT, DECRYPTION_KEY, DECRYPT, DECRYPT1, RECONSTRUCT, RECONSTRUCT_KEY);
	
	-- Register to hold the current state
	signal state : state_type;

begin
    -- NEXT STATE
    process(clk)
    begin
        if(rising_edge(clk)) then
            case state is 
                when INIT =>
                    if GO = '0' then
                        state <= INIT;
                    elsif ENC_DEC_MODE = '1' then
                        state <= DECRYPTION_KEY;
                    else
                        state <= ENCRYPT;
                    end if;

                when ENCRYPT =>
                    if DONE_FSM = '1' then
                        state <= INIT;
                    else
                        state <= ENCRYPT;
                    end if;

                when DECRYPTION_KEY =>
                    state <= DECRYPT1;

                when DECRYPT1 =>
                    state <= DECRYPT;

                when DECRYPT =>
                    if DONE_FSM = '1' then
                        state <= RECONSTRUCT_KEY;
                    else
                        state <= DECRYPT;
                    end if;

                when RECONSTRUCT_KEY =>
                    state <= RECONSTRUCT;

                when RECONSTRUCT =>
                    if DONE_FSM = '1' then
                        state <= INIT;
                    else
                        state <= RECONSTRUCT;
                    end if;

                when others => -- Should have covered all cases
                    state <= INIT;
            end case;
        end if;
    end process;

    -- OUTPUT 
    process(state)
    begin
        case state is 
            when INIT =>
                MODE_DECRYPT <= '0';
                SET_DEC_KEY <= '0'; 
                WE_TK <= '0';
                INTERNAL_GO <= '1'; --0
                LOAD_IS <= '1';

            when ENCRYPT =>
                MODE_DECRYPT <= '0';
                SET_DEC_KEY <= '0';
                WE_TK <= '1';
                INTERNAL_GO <= '0';
                LOAD_IS <= '0';

            when DECRYPTION_KEY =>
                MODE_DECRYPT <= '1';
                SET_DEC_KEY <= '1';
                WE_TK <= '1';
                INTERNAL_GO <= '1';
                LOAD_IS <= '0';

            when DECRYPT1 => -- Sole purpose is to invert KS one extra
                MODE_DECRYPT <= '1';
                SET_DEC_KEY <= '0';
                WE_TK <= '1';
                INTERNAL_GO <= '1';
                LOAD_IS <= '1';

            when DECRYPT =>
                MODE_DECRYPT <= '1';
                SET_DEC_KEY <= '0';
                WE_TK <= '1';
                INTERNAL_GO <= '0';
                LOAD_IS <= '0';

            when RECONSTRUCT_KEY =>
                MODE_DECRYPT <= '1'; -- This is for the counter
                SET_DEC_KEY <= '1';
                WE_TK <= '1';
                INTERNAL_GO <= '1'; -- This is for the counter
                LOAD_IS <= '0';

            when RECONSTRUCT =>
                MODE_DECRYPT <= '0'; -- Encryption now
                SET_DEC_KEY <= '0';
                WE_TK <= '1';
                INTERNAL_GO <= '0'; -- This is for the counter
                LOAD_IS <= '0';

            when others => -- Should have covered all cases
                MODE_DECRYPT <= '0';
                SET_DEC_KEY <= '0';
                WE_TK <= '0';
                INTERNAL_GO <= '0';
                LOAD_IS <= '0';

        end case;
    end process;

end rtl;


