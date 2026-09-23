-- testbench for the 7485 4-bit magnitude comparator
--
--  Applies all 2^11 = 2048 input combinations (A: 16 x B: 16 x cascade 8) to the DUT and compares the outputs against reference model:
--     - A /= B : integer comparison of A and B
--     - A  = B : cascade truth table taken directly from the TI datasheet



LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY tb_comp7485 IS
END ENTITY tb_comp7485;

ARCHITECTURE sim OF tb_comp7485 IS

    


    SIGNAL A, B   : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL i_AGB  : STD_LOGIC := '0';
    SIGNAL i_ALB  : STD_LOGIC := '0';
    SIGNAL i_AEB  : STD_LOGIC := '0';
    SIGNAL o_AGB  : STD_LOGIC;
    SIGNAL o_ALB  : STD_LOGIC;
    SIGNAL o_AEB  : STD_LOGIC;


    CONSTANT T_SETTLE : TIME := 10 ns;

BEGIN

  
    -- Under Test
    DUT : ENTITY work.comp7485
        PORT MAP (
            A     => A,
            B     => B,
            i_AGB => i_AGB,
            i_AEB => i_AEB,
            i_ALB => i_ALB,
            o_AGB => o_AGB,
            o_AEB => o_AEB,
            o_ALB => o_ALB
        );




    stimulus : PROCESS

        VARIABLE cascade  : STD_LOGIC_VECTOR(2 DOWNTO 0);
        VARIABLE expected : STD_LOGIC_VECTOR(2 DOWNTO 0);
        VARIABLE obtained : STD_LOGIC_VECTOR(2 DOWNTO 0);
        VARIABLE n_tests  : NATURAL := 0;
        VARIABLE n_errors : NATURAL := 0;
    BEGIN
        REPORT "Starting exhaustive test of comp7485 (2048 vectors)";

        FOR a_val IN 0 TO 15 LOOP
            FOR b_val IN 0 TO 15 LOOP
                FOR c_val IN 0 TO 7 LOOP

                    --
                    -- Stimulus

                    cascade := STD_LOGIC_VECTOR(TO_UNSIGNED(c_val, 3));
                    A     <= STD_LOGIC_VECTOR(TO_UNSIGNED(a_val, 4));
                    B     <= STD_LOGIC_VECTOR(TO_UNSIGNED(b_val, 4));
                    i_AGB <= cascade(2);
                    i_ALB <= cascade(1);
                    i_AEB <= cascade(0);



                    IF a_val > b_val THEN
                        expected := "100";
                    ELSIF a_val < b_val THEN
                        expected := "010";
                    ELSE

                        CASE cascade IS
                            WHEN "100" => expected := "100";  -- prev A > B
                            WHEN "010" => expected := "010";  -- prev A < B
                            WHEN "001" | "011" | "101" | "111"
                                       => expected := "001";  -- i_AEB dominates
                            WHEN "110" => expected := "000";  -- illegal
                            WHEN "000" => expected := "110";  -- illegal
                            WHEN OTHERS => expected := "XXX";
                        END CASE;
                    END IF;




                    WAIT FOR T_SETTLE;

                    obtained := o_AGB & o_ALB & o_AEB;
                    n_tests  := n_tests + 1;

                    IF obtained /= expected THEN
                        n_errors := n_errors + 1;
                        REPORT "MISMATCH: A=" & INTEGER'IMAGE(a_val) &
                               " B="          & INTEGER'IMAGE(b_val) &
                               " cascade(AGB,ALB,AEB)=" & TO_STRING(cascade) &
                               " expected="   & TO_STRING(expected) &
                               " obtained="   & TO_STRING(obtained)
                            SEVERITY ERROR;
                    END IF;

                END LOOP;
            END LOOP;
        END LOOP;


        -- Report
        REPORT "Tests run: " & INTEGER'IMAGE(n_tests) &
               "   Errors: " & INTEGER'IMAGE(n_errors);

        IF n_errors = 0 THEN
            REPORT "SIMULATION PASSED";
        ELSE
            REPORT "SIMULATION FAILED" SEVERITY ERROR;
        END IF;

        WAIT;   -- stop this process forever -> simulation ends
    END PROCESS stimulus;

END ARCHITECTURE sim;
