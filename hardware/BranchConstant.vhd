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


-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE WORK.FORKSKINNYPKG.ALL;

-- Explicit combinational implementation of the branch constant logic (using NOT gates)
entity BranchConstant is
    generic (
                BS: BLOCK_SIZE
    );
    port (
        L: in std_logic_vector((GET_BLOCK_SIZE(BS) - 1) downto 0);
        BRANCH_CONSTANT: out std_logic_vector((GET_BLOCK_SIZE(BS) - 1) downto 0)
    );
end entity BranchConstant;

architecture behav of BranchConstant is

begin
	BC64 : IF BS = BLOCK_SIZE_64 GENERATE
        BRANCH_CONSTANT(63) <= L(63);
        BRANCH_CONSTANT(62) <= L(62);
        BRANCH_CONSTANT(61) <= L(61);
        BRANCH_CONSTANT(60) <= not L(60);
        BRANCH_CONSTANT(59) <= L(59);
        BRANCH_CONSTANT(58) <= L(58);
        BRANCH_CONSTANT(57) <= not L(57);
        BRANCH_CONSTANT(56) <= L(56);
        BRANCH_CONSTANT(55) <= L(55);
        BRANCH_CONSTANT(54) <= not L(54);
        BRANCH_CONSTANT(53) <= L(53);
        BRANCH_CONSTANT(52) <= L(52);
        BRANCH_CONSTANT(51) <= not L(51);
        BRANCH_CONSTANT(50) <= L(50);
        BRANCH_CONSTANT(49) <= L(49);
        BRANCH_CONSTANT(48) <= not L(48);
        BRANCH_CONSTANT(47) <= L(47);
        BRANCH_CONSTANT(46) <= L(46);
        BRANCH_CONSTANT(45) <= not L(45);
        BRANCH_CONSTANT(44) <= not L(44);
        BRANCH_CONSTANT(43) <= L(43);
        BRANCH_CONSTANT(42) <= not L(42);
        BRANCH_CONSTANT(41) <= not L(41);
        BRANCH_CONSTANT(40) <= L(40);
        BRANCH_CONSTANT(39) <= not L(39);
        BRANCH_CONSTANT(38) <= not L(38);
        BRANCH_CONSTANT(37) <= L(37);
        BRANCH_CONSTANT(36) <= not L(36);
        BRANCH_CONSTANT(35) <= not L(35);
        BRANCH_CONSTANT(34) <= L(34);
        BRANCH_CONSTANT(33) <= not L(33);
        BRANCH_CONSTANT(32) <= L(32);
        BRANCH_CONSTANT(31) <= L(31);
        BRANCH_CONSTANT(30) <= not L(30);
        BRANCH_CONSTANT(29) <= L(29);
        BRANCH_CONSTANT(28) <= not L(28);
        BRANCH_CONSTANT(27) <= not L(27);
        BRANCH_CONSTANT(26) <= L(26);
        BRANCH_CONSTANT(25) <= not L(25);
        BRANCH_CONSTANT(24) <= not L(24);
        BRANCH_CONSTANT(23) <= L(23);
        BRANCH_CONSTANT(22) <= not L(22);
        BRANCH_CONSTANT(21) <= not L(21);
        BRANCH_CONSTANT(20) <= not L(20);
        BRANCH_CONSTANT(19) <= not L(19);
        BRANCH_CONSTANT(18) <= not L(18);
        BRANCH_CONSTANT(17) <= not L(17);
        BRANCH_CONSTANT(16) <= not L(16);
        BRANCH_CONSTANT(15) <= not L(15);
        BRANCH_CONSTANT(14) <= not L(14);
        BRANCH_CONSTANT(13) <= not L(13);
        BRANCH_CONSTANT(12) <= L(12);
        BRANCH_CONSTANT(11) <= not L(11);
        BRANCH_CONSTANT(10) <= not L(10);
        BRANCH_CONSTANT(9) <= L(9);
        BRANCH_CONSTANT(8) <= L(8);
        BRANCH_CONSTANT(7) <= not L(7);
        BRANCH_CONSTANT(6) <= L(6);
        BRANCH_CONSTANT(5) <= L(5);
        BRANCH_CONSTANT(4) <= L(4);
        BRANCH_CONSTANT(3) <= L(3);
        BRANCH_CONSTANT(2) <= L(2);
        BRANCH_CONSTANT(1) <= L(1);
        BRANCH_CONSTANT(0) <= not L(0);
	END GENERATE;

    BC128 : IF BS = BLOCK_SIZE_128 GENERATE
        BRANCH_CONSTANT(127) <= L(127);
        BRANCH_CONSTANT(126) <= L(126);
        BRANCH_CONSTANT(125) <= L(125);
        BRANCH_CONSTANT(124) <= L(124);
        BRANCH_CONSTANT(123) <= L(123);
        BRANCH_CONSTANT(122) <= L(122);
        BRANCH_CONSTANT(121) <= L(121);
        BRANCH_CONSTANT(120) <= not L(120);
        BRANCH_CONSTANT(119) <= L(119);
        BRANCH_CONSTANT(118) <= L(118);
        BRANCH_CONSTANT(117) <= L(117);
        BRANCH_CONSTANT(116) <= L(116);
        BRANCH_CONSTANT(115) <= L(115);
        BRANCH_CONSTANT(114) <= L(114);
        BRANCH_CONSTANT(113) <= not L(113);
        BRANCH_CONSTANT(112) <= L(112);
        BRANCH_CONSTANT(111) <= L(111);
        BRANCH_CONSTANT(110) <= L(110);
        BRANCH_CONSTANT(109) <= L(109);
        BRANCH_CONSTANT(108) <= L(108);
        BRANCH_CONSTANT(107) <= L(107);
        BRANCH_CONSTANT(106) <= not L(106);
        BRANCH_CONSTANT(105) <= L(105);
        BRANCH_CONSTANT(104) <= L(104);
        BRANCH_CONSTANT(103) <= L(103);
        BRANCH_CONSTANT(102) <= L(102);
        BRANCH_CONSTANT(101) <= L(101);
        BRANCH_CONSTANT(100) <= L(100);
        BRANCH_CONSTANT(99) <= not L(99);
        BRANCH_CONSTANT(98) <= L(98);
        BRANCH_CONSTANT(97) <= L(97);
        BRANCH_CONSTANT(96) <= L(96);
        BRANCH_CONSTANT(95) <= L(95);
        BRANCH_CONSTANT(94) <= L(94);
        BRANCH_CONSTANT(93) <= L(93);
        BRANCH_CONSTANT(92) <= not L(92);
        BRANCH_CONSTANT(91) <= L(91);
        BRANCH_CONSTANT(90) <= L(90);
        BRANCH_CONSTANT(89) <= L(89);
        BRANCH_CONSTANT(88) <= L(88);
        BRANCH_CONSTANT(87) <= L(87);
        BRANCH_CONSTANT(86) <= L(86);
        BRANCH_CONSTANT(85) <= not L(85);
        BRANCH_CONSTANT(84) <= L(84);
        BRANCH_CONSTANT(83) <= L(83);
        BRANCH_CONSTANT(82) <= L(82);
        BRANCH_CONSTANT(81) <= L(81);
        BRANCH_CONSTANT(80) <= L(80);
        BRANCH_CONSTANT(79) <= L(79);
        BRANCH_CONSTANT(78) <= not L(78);
        BRANCH_CONSTANT(77) <= L(77);
        BRANCH_CONSTANT(76) <= L(76);
        BRANCH_CONSTANT(75) <= L(75);
        BRANCH_CONSTANT(74) <= L(74);
        BRANCH_CONSTANT(73) <= L(73);
        BRANCH_CONSTANT(72) <= not L(72);
        BRANCH_CONSTANT(71) <= not L(71);
        BRANCH_CONSTANT(70) <= L(70);
        BRANCH_CONSTANT(69) <= L(69);
        BRANCH_CONSTANT(68) <= L(68);
        BRANCH_CONSTANT(67) <= L(67);
        BRANCH_CONSTANT(66) <= L(66);
        BRANCH_CONSTANT(65) <= not L(65);
        BRANCH_CONSTANT(64) <= L(64);
        BRANCH_CONSTANT(63) <= L(63);
        BRANCH_CONSTANT(62) <= L(62);
        BRANCH_CONSTANT(61) <= L(61);
        BRANCH_CONSTANT(60) <= L(60);
        BRANCH_CONSTANT(59) <= L(59);
        BRANCH_CONSTANT(58) <= not L(58);
        BRANCH_CONSTANT(57) <= L(57);
        BRANCH_CONSTANT(56) <= not L(56);
        BRANCH_CONSTANT(55) <= L(55);
        BRANCH_CONSTANT(54) <= L(54);
        BRANCH_CONSTANT(53) <= L(53);
        BRANCH_CONSTANT(52) <= L(52);
        BRANCH_CONSTANT(51) <= not L(51);
        BRANCH_CONSTANT(50) <= L(50);
        BRANCH_CONSTANT(49) <= not L(49);
        BRANCH_CONSTANT(48) <= L(48);
        BRANCH_CONSTANT(47) <= L(47);
        BRANCH_CONSTANT(46) <= L(46);
        BRANCH_CONSTANT(45) <= L(45);
        BRANCH_CONSTANT(44) <= not L(44);
        BRANCH_CONSTANT(43) <= L(43);
        BRANCH_CONSTANT(42) <= not L(42);
        BRANCH_CONSTANT(41) <= L(41);
        BRANCH_CONSTANT(40) <= L(40);
        BRANCH_CONSTANT(39) <= L(39);
        BRANCH_CONSTANT(38) <= L(38);
        BRANCH_CONSTANT(37) <= not L(37);
        BRANCH_CONSTANT(36) <= L(36);
        BRANCH_CONSTANT(35) <= not L(35);
        BRANCH_CONSTANT(34) <= L(34);
        BRANCH_CONSTANT(33) <= L(33);
        BRANCH_CONSTANT(32) <= L(32);
        BRANCH_CONSTANT(31) <= L(31);
        BRANCH_CONSTANT(30) <= not L(30);
        BRANCH_CONSTANT(29) <= L(29);
        BRANCH_CONSTANT(28) <= not L(28);
        BRANCH_CONSTANT(27) <= L(27);
        BRANCH_CONSTANT(26) <= L(26);
        BRANCH_CONSTANT(25) <= L(25);
        BRANCH_CONSTANT(24) <= not L(24);
        BRANCH_CONSTANT(23) <= not L(23);
        BRANCH_CONSTANT(22) <= L(22);
        BRANCH_CONSTANT(21) <= not L(21);
        BRANCH_CONSTANT(20) <= L(20);
        BRANCH_CONSTANT(19) <= L(19);
        BRANCH_CONSTANT(18) <= L(18);
        BRANCH_CONSTANT(17) <= not L(17);
        BRANCH_CONSTANT(16) <= L(16);
        BRANCH_CONSTANT(15) <= L(15);
        BRANCH_CONSTANT(14) <= not L(14);
        BRANCH_CONSTANT(13) <= L(13);
        BRANCH_CONSTANT(12) <= L(12);
        BRANCH_CONSTANT(11) <= L(11);
        BRANCH_CONSTANT(10) <= not L(10);
        BRANCH_CONSTANT(9) <= L(9);
        BRANCH_CONSTANT(8) <= L(8);
        BRANCH_CONSTANT(7) <= not L(7);
        BRANCH_CONSTANT(6) <= L(6);
        BRANCH_CONSTANT(5) <= L(5);
        BRANCH_CONSTANT(4) <= L(4);
        BRANCH_CONSTANT(3) <= not L(3);
        BRANCH_CONSTANT(2) <= L(2);
        BRANCH_CONSTANT(1) <= L(1);
        BRANCH_CONSTANT(0) <= L(0);
	END GENERATE;
end behav;


