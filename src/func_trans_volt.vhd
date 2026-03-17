--------------------------------------------------------------------------------
-- Archivo:     func_trans_volt.vhd
-- Autor:       Juan Manuel Delgado Romero
-- Fecha:       Febrero 2026
--
-- Institución: Universidad de Sevilla - Escuela Politécnica Superior
-- Titulación:  Grado en Ingeniería Electrónica Industrial
-- Proyecto:    Trabajo Fin de Grado (TFG)
-- Licencia:    MIT (Ver archivo LICENSE)
--
-- Descripción: 
-- Bloque aritmético que implementa la función de transferencia para los 
-- voltajes internos (VCCINT y VCCBRAM). Transforma el valor digital del XADC 
-- a milivoltios (mV) mediante el uso de constantes escaladas y 
-- desplazamientos lógicos, evitando el cálculo en coma flotante.
-- Para más detalle veáse el apartado 7.4 del Capítulo 7 de la memoria de este
-- trabajo.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity func_trans_volt is
  Port (
    clk, reset: in  std_ulogic;
    drdy:       in  std_logic;
    volt_sel:   in  std_logic;
    dato_val:   out std_logic;
    volt_adc:   in  std_logic_vector(11 downto 0);
    volt_mv:    out std_logic_vector(19 downto 0)    
  );
end func_trans_volt;

architecture Behavioral of func_trans_volt is
  constant mul_3000   : unsigned(11 downto 0) := to_unsigned(3000,12);
  signal   res_int    : unsigned(23 downto 0);
  signal   adc_valor  : unsigned(11 downto 0);
  type     tipo_estado is (espera, calculo, fin);
  signal   estado    : tipo_estado;
begin

  P1: process(clk, reset)
  begin
    if reset = '1' then
      dato_val  <= '0';
      adc_valor <= (others => '0');
      volt_mv   <= (others => '0');
      estado <= espera;
    elsif rising_edge(clk) then
      dato_val <= '0';
      case estado is 
        when espera =>
          if drdy = '1' and volt_sel = '1' then
            adc_valor <= unsigned(volt_adc);
            estado    <= calculo;
          end if;
        when calculo =>
          res_int <= adc_valor*mul_3000;
          estado  <= fin;
        when fin =>
          volt_mv  <= std_logic_vector(X"00" & res_int(23 downto 12)); -- /4096 extendindo a 20 bits
          dato_val <= '1';
          estado   <= espera;
      end case;
    end if;
  end process;

end Behavioral;
