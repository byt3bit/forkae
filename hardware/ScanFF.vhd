----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2016 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Embedded Security
-- AUTHOR:					Amir Moradi
--
-- CREATE DATA:			27/01/2016
-- MODULE NAME:			ScanFF
--
--	REVISION:				1.00 - File created
--
-- LICENCE: 				Please look at licence.txt
-- USAGE INFORMATION:	Please look at readme.txt. If licence.txt or readme.txt
--								are missing or	if you have questions regarding the code
--								please contact Amir Moradi(amir.moradi@rub.de)
--
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY 
-- KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.
----------------------------------------------------------------------------------




-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY ScanFF IS
    GENERIC (SIZE : INTEGER);
	PORT ( CLK	: IN  STD_LOGIC;
          SE 	: IN  STD_LOGIC;
          D  	: IN 	STD_LOGIC_VECTOR((SIZE - 1) DOWNTO 0);
          DS  	: IN 	STD_LOGIC_VECTOR((SIZE - 1) DOWNTO 0);
          Q  	: OUT 	STD_LOGIC_VECTOR((SIZE - 1) DOWNTO 0));
END ScanFF;



-- ARCHITECTURE
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF ScanFF IS	

-- STRUCTURAL
----------------------------------------------------------------------------------
BEGIN
	
	-------------------------------------------------------------------------------
	PROCESS(CLK) BEGIN
		IF RISING_EDGE(CLK) THEN
			IF (SE = '0') THEN
				Q <= D;
			ELSE
				Q <= DS;
			END IF;
		END IF;
	END PROCESS;
	-------------------------------------------------------------------------------

END Structural;


