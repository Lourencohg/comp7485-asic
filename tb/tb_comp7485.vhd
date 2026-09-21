-- =============================================================================
-- File    : tb_comp7485.vhd
-- Design  : Testbench for the 7485 4-bit magnitude comparator
-- Author  : Lourenco
-- Date    : 2026
--
-- Description:
--   Self-checking, exhaustive testbench. Applies all 2^11 = 2048 input
--   combinations (A: 16 x B: 16 x cascade: 8) to the DUT and compares the
--   outputs against an independent reference model:
--     - A /= B : integer comparison of A and B
--     - A  = B : cascade truth table taken directly from the TI datasheet
--   Prints every mismatch and a final PASSED / FAILED summary.
-- =============================================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- A testbench has no ports: it is the top level of the simulation
ENTITY tb_comp7485 IS
END ENTITY tb_comp7485;

ARCHITECTURE sim OF tb_comp7485 IS

    -- -------------------------------------------------------------------------
    -- Signals connected to the DUT pins ("wires" on the breadboard)
    -- -------------------------------------------------------------------------
    SIGNAL A, B   : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL i_AGB  : STD_LOGIC := '0';
    SIGNAL i_ALB  : STD_LOGIC := '0';
    SIGNAL i_AEB  : STD_LOGIC := '0';
    SIGNAL o_AGB  : STD_LOGIC;
    SIGNAL o_ALB  : STD_LOGIC;
    SIGNAL o_AEB  : STD_LOGIC;

    -- Time given to the combinational logic to settle before checking
    CONSTANT T_SETTLE : TIME := 10 ns;

BEGIN

    -- -------------------------------------------------------------------------
    -- Device Under Test
    -- -------------------------------------------------------------------------
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

    -- -------------------------------------------------------------------------
    -- Stimulus + checking process
    -- -------------------------------------------------------------------------
    stimulus : PROCESS
        -- Bit order used for the 3-bit vectors below: (AGB, ALB, AEB)
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

                    -- ---------------------------------------------------------
                    -- 1. Apply stimulus
                    -- ---------------------------------------------------------
                    cascade := STD_LOGIC_VECTOR(TO_UNSIGNED(c_val, 3));
                    A     <= STD_LOGIC_VECTOR(TO_UNSIGNED(a_val, 4));
                    B     <= STD_LOGIC_VECTOR(TO_UNSIGNED(b_val, 4));
                    i_AGB <= cascade(2);
                    i_ALB <= cascade(1);
                    i_AEB <= cascade(0);

                    -- ---------------------------------------------------------
                    -- 2. Reference model (independent of the RTL equations)
                    -- ---------------------------------------------------------
                    IF a_val > b_val THEN
                        expected := "100";
                    ELSIF a_val < b_val THEN
                        expected := "010";
                    ELSE
                        -- A = B: datasheet cascade truth table
                        --   cascade = i_AGB i_ALB i_AEB
                        --   expected = o_AGB o_ALB o_AEB
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

                    -- ---------------------------------------------------------
                    -- 3. Wait for the outputs to settle, then compare
                    -- ---------------------------------------------------------
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

        -- ---------------------------------------------------------------------
        -- 4. Final report
        -- ---------------------------------------------------------------------
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
