--------------------------------------------------------------------------------
-- Archivo:     valor_abs.vhd
-- Autor:       Juan Manuel Delgado Romero
-- Fecha:       Febrero 2026
--
-- Institución: Universidad de Sevilla - Escuela Politécnica Superior
-- Titulación:  Grado en Ingeniería Electrónica Industrial
-- Proyecto:    Trabajo Fin de Grado (TFG)
-- Licencia:    MIT (Ver archivo LICENSE)
--
-- Descripción: 
-- Entidad de acondicionamiento para el cálculo del valor absoluto de la 
-- temperatura. Detecta valores negativos (evaluando el MSB) e invierte el 
-- Ca2 para entregar un dato binario natural positivo apto para su posterior
-- conversión a BCD. Si el dato es negativo lo señaliza con signo_o.
-- Para más detalle veáse el apartado 7.5 del Capítulo 7 de la memoria de este
-- trabajo.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity valor_abs is
  port( 
    clk       : in  std_logic;
    reset     : in  std_logic;
    dato_val_i: in  std_logic;
    temp_in   : in  std_logic_vector(19 downto 0);
    dato_val_o: out std_logic;
    temp_out  : out std_logic_vector(19 downto 0);
    signo_o   : out std_logic
  );
end valor_abs;

architecture Behavioral of valor_abs is
begin
  
  P1: process(clk,reset)
  begin
    if reset = '1' then
      dato_val_o <= '0';
      signo_o    <= '0';
      temp_out   <= (others => '0');
    elsif rising_edge(clk) then
      dato_val_o <= dato_val_i;
           
      if dato_val_i = '1' and temp_in(19) = '1' then
        temp_out   <= std_logic_vector(- signed(temp_in));
        signo_o    <= '1';
      elsif dato_val_i = '1' then
        temp_out   <= temp_in;
        signo_o    <= '0';
      end if;
    end if;
  end process;

end Behavioral;
