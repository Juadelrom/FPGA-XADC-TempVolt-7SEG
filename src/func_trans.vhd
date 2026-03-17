--------------------------------------------------------------------------------
-- Archivo:     func_trans.vhd
-- Autor:       Juan Manuel Delgado Romero
-- Fecha:       Febrero 2026
--
-- Institución: Universidad de Sevilla - Escuela Politécnica Superior
-- Titulación:  Grado en Ingeniería Electrónica Industrial
-- Proyecto:    Trabajo Fin de Grado (TFG)
-- Licencia:    MIT (Ver archivo LICENSE)
--
-- Descripción: 
-- Bloque aritmético que implementa la función de transferencia para la 
-- temperatura interna de la FPGA. Escala el dato crudo de 12 bits del XADC 
-- transformándolo a miligrados centígrados (m°C) en complemento a dos, 
-- utilizando exclusivamente aritmética de enteros para optimizar recursos.
-- Para más detalle veáse el apartado 7.3 del Capítulo 7 de la memoria de este
-- trabajo.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity func_trans is
  Port (
    clk, reset: in  std_ulogic;
    drdy:       in  std_logic;
    temp_sel:   in  std_logic;
    temp_adc:   in  std_logic_vector(11 downto 0);
    dato_val:   out std_logic;
    temp_grad:  out std_logic_vector(19 downto 0)    
  );
end func_trans;

architecture Behavioral of func_trans is
  constant mul_123   : signed(7 downto 0) := to_signed(123,8);
  constant kelvin_0  : signed(20 downto 0) := to_signed(-273150,21); 
  signal   adc_valor : signed(12 downto 0);
  signal   res_int   : signed(20 downto 0);
  type     tipo_estado is (espera, calculo, fin);
  signal   estado    : tipo_estado;
begin

  P1: process(clk, reset)
  begin
    if reset = '1' then
      dato_val  <= '0';
      adc_valor <= (others => '0');
      temp_grad <= (others => '0');
      estado <= espera;
    elsif rising_edge(clk) then
      dato_val  <= '0';
      case estado is 
        when espera =>
          if drdy = '1' and temp_sel = '1' then
            adc_valor <= signed('0' & temp_adc);
            estado    <= calculo;
          end if;
        when calculo =>
          res_int <= adc_valor*mul_123 + kelvin_0;
          estado  <= fin;
        when fin =>
          temp_grad <= std_logic_vector(res_int(19 downto 0));
          dato_val <= '1';
          estado   <= espera;
      end case;
    end if;
  end process;

end Behavioral;
