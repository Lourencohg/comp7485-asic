-- Author  : Lourenco
-- Date    : 2026
--
--   VHDL model of the 7485 4-bit magnitude comparator. datasheet;. https://www.ti.com/lit/ds/symlink/sn54ls85.pdf?ts=1789998123297&ref_url=https%253A%252F%252Fwww.google.com%252F
--   Compares two 4-bit operands and produces three outputs:
--     o_AGB  =>  A > B
--     o_AEB  =>  A = B
--     o_ALB  =>  A < B
--
--   Along three cascading inputs (i_AGB, i_AEB, i_ALB) for chaining multiple
--   7485 devices to compare wider values. 
--
--



LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;



ENTITY comp7485 IS
    PORT (
        A      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        B      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);

        i_AGB  : IN  STD_LOGIC;   -- input: A greater than B
        i_AEB  : IN  STD_LOGIC;   -- input: A equal to B
        i_ALB  : IN  STD_LOGIC;   -- input: A less than B

        o_AGB  : OUT STD_LOGIC;   -- output: A greater than B
        o_AEB  : OUT STD_LOGIC;   -- output: A equal to B
        o_ALB  : OUT STD_LOGIC    -- output: A less than B
    );
END ENTITY comp7485;


-- -----------------------------------------------------------------------------


ARCHITECTURE rtl OF comp7485 IS

    SIGNAL X0, X1, X2, X3 : STD_LOGIC; -- Signals for reciving XNOR operations using A and B 

    SIGNAL A_equal_B   : STD_LOGIC; -- Intermediate comparison results
    SIGNAL A_greater_B : STD_LOGIC;
    SIGNAL A_lower_B   : STD_LOGIC;

BEGIN

    X3 <= A(3) XNOR B(3);
    X2 <= A(2) XNOR B(2);
    X1 <= A(1) XNOR B(1);
    X0 <= A(0) XNOR B(0);


    A_equal_B <= X3 AND X2 AND X1 AND X0;


    A_greater_B <=
        ( A(3) AND NOT B(3) )                                    OR
        ( X3 AND  A(2) AND NOT B(2) )                            OR
        ( X3 AND X2 AND  A(1) AND NOT B(1) )                     OR
        ( X3 AND X2 AND X1 AND  A(0) AND NOT B(0) );


    A_lower_B <=
        ( B(3) AND NOT A(3) )                                    OR
        ( X3 AND  B(2) AND NOT A(2) )                            OR
        ( X3 AND X2 AND  B(1) AND NOT A(1) )                     OR
        ( X3 AND X2 AND X1 AND  B(0) AND NOT A(0) );

    -- -------------------------------------------------------------------------
    -- If A /= B the local comparison decides and the cascade signals are ignored
    -- but if A = B the cascade truth table is the one that is applied:
    --
    --   i_AGB  i_ALB  i_AEB  |  o_AGB  o_ALB  o_AEB
    --   -----------------------------------------------
    --     1      0      0    |    1      0      0
    --     0      1      0    |    0      1      0
    --     x      x      1    |    0      0      1
    --     1      1      0    |    0      0      0
    --     0      0      0    |    1      1      0
    -- -------------------------------------------------------------------------
    
    o_AGB <= A_greater_B OR (A_equal_B AND NOT i_ALB AND NOT i_AEB);
    o_ALB <= A_lower_B   OR (A_equal_B AND NOT i_AGB AND NOT i_AEB);
    o_AEB <= A_equal_B   AND i_AEB;

END ARCHITECTURE rtl;
