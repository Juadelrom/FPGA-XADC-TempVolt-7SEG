--------------------------------------------------------------------------------
-- Archivo:     visu7seg.vhd
-- Autor:       Juan Manuel Delgado Romero
-- Fecha:       Febrero 2026
--
-- Institución: Universidad de Sevilla - Escuela Politécnica Superior
-- Titulación:  Grado en Ingeniería Electrónica Industrial
-- Proyecto:    Trabajo Fin de Grado (TFG)
-- Licencia:    MIT (Ver archivo LICENSE)
--
-- Descripción: 
-- Controlador hardware para el display de 7 segmentos (Ánodo Común). 
-- Gestiona la decodificación BCD a 7 segmentos, el multiplexado temporal de 
-- los ánodos, la posición dinámica del punto fijo decimal y la estabilización 
-- de la lectura para evitar efectos de segmentos fantasma.
-- Para más detalle veáse el apartado 7.7 del Capítulo 7 de la memoria de este
-- trabajo.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity visu7seg is
   port(clk,reset: in std_logic;
        bcd_0,bcd_1,bcd_2,bcd_3: in std_logic_vector(3 downto 0);
        temp_sel: in std_logic;
        volt_sel: in std_logic;
        an: out std_logic_vector(7 downto 0);
        ca,cb,cc,cd,ce,cf,cg,dp: out std_logic
        );
end visu7seg;

architecture Behavioral of visu7seg is
   signal cont: unsigned(24 downto 0);
   signal s_int: std_logic_vector(3 downto 0);
   signal visu: std_logic_vector(6 downto 0);
   signal bcd_int0 ,bcd_int1, bcd_int2, bcd_int3: std_logic_vector(3 downto 0);
begin
--------------------------------------
  cont_proc: process(reset,clk)
  begin
    if reset = '1' then
     cont <= (others => '0');
     bcd_int0 <= X"A";
     bcd_int1 <= X"A";
     bcd_int2 <= X"A";
     bcd_int3 <= X"A";    
    elsif rising_edge(clk) then
     cont <= cont + 1;
     if cont = 0 then
       bcd_int0 <= bcd_0;
       bcd_int1 <= bcd_1;
       bcd_int2 <= bcd_2;
       bcd_int3 <= bcd_3;
       if temp_sel = '0' and volt_sel = '0' then
         bcd_int0 <= X"A";
         bcd_int1 <= X"A";
         bcd_int2 <= X"A";
         bcd_int3 <= X"A";
       end if;
     end if;
    end if;
  end process;
---------------------------------------
---------------------------------------
  an(3 downto 0) <= "1110" when (cont(18 downto 17)= "00" and reset = '0') else
                    "1101" when (cont(18 downto 17)= "01" and reset = '0') else
                    "1011" when (cont(18 downto 17)= "10" and reset = '0') else
                    "0111" when (cont(18 downto 17)= "11" and reset = '0') else
                    "1111"; 
----------------------------------------                    
  an(7 downto 4) <= "1111"; -- No mostramos segmento superior nunca
  
  
  s_int <= bcd_int0 when (cont(18 downto 17)= "00") else
           bcd_int1 when (cont(18 downto 17)= "01") else
           bcd_int2 when (cont(18 downto 17)= "10") else
           bcd_int3;
           
    with s_int select
    visu <= "0000001" when "0000",  -- 0
            "1001111" when "0001",  -- 1  
            "0010010" when "0010",  -- 2
            "0000110" when "0011",  -- 3
            "1001100" when "0100",  -- 4
            "0100100" when "0101",  -- 5
            "0100000" when "0110",  -- 6
            "0001111" when "0111",  -- 7
            "0000000" when "1000",  -- 8
            "0000100" when "1001",  -- 9
            "1111110" when "1010",  -- A, gestión del modo reposo -> [----]
            "1111111" when others;  -- apagado
            
  ca <= visu(6);
  cb <= visu(5);
  cc <= visu(4);
  cd <= visu(3);
  ce <= visu(2);
  cf <= visu(1);
  cg <= visu(0);
  dp <= '0' when (temp_sel = '1' and cont(18 downto 17)= "01" and reset = '0') else
        '0' when (volt_sel = '1' and temp_sel = '0' and cont(18 downto 17)= "11" and reset = '0') else 
        '1';
        
end Behavioral;

