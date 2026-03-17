--------------------------------------------------------------------------------
-- Archivo:     adc_top_level.vhd
-- Autor:       Juan Manuel Delgado Romero
-- Fecha:       Febrero 2026
--
-- Institución: Universidad de Sevilla - Escuela Politécnica Superior
-- Titulación:  Grado en Ingeniería Electrónica Industrial
-- Proyecto:    Trabajo Fin de Grado (TFG)
-- Licencia:    MIT (Ver archivo LICENSE)
--
-- Descripción: 
-- Entidad de jerarquía superior (top-level) del sistema de adquisición y 
-- visualización multiplexada de magnitudes físicas. Instancia el bloque XADC
-- y todas las entidades necesarias para el procesado de los datos. Incluye  
-- el proceso de control (Process P1) para el enrutado dinámico de las señales.
-- Para más detalle veánse los apartados 7.1, 7.8 y 7.9 del Capítulo 7 de la 
-- memoria de este trabajo.
--------------------------------------------------------------------------------

library work;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adc_top_level is
  port( 
    clk     :  in std_logic;
    reset   :  in std_logic;
    temp_sel:  in std_logic;
    volt_sel:  in std_logic;
    vram_sel:  in std_logic;
    an      :  out std_logic_vector(7 downto 0);
    ca,cb,cc,cd,ce,cf,cg,dp: out std_logic    
  );
end adc_top_level;

architecture Behavioral of adc_top_level is

COMPONENT xadc_wiz_0
  PORT (
    di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    den_in : IN STD_LOGIC;
    dwe_in : IN STD_LOGIC;
    drdy_out : OUT STD_LOGIC;
    do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dclk_in : IN STD_LOGIC;
    reset_in : IN STD_LOGIC;
    vp_in : IN STD_LOGIC;
    vn_in : IN STD_LOGIC;
    channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    eoc_out : OUT STD_LOGIC;
    alarm_out : OUT STD_LOGIC;
    eos_out : OUT STD_LOGIC;
    busy_out : OUT STD_LOGIC 
  );
END COMPONENT;

-- Señales intermedias para conexión de instancias
-- -----------------------------------------------
  -- Entidad XADC
  signal enable : std_logic; -- realimentación entrada DEN_IN y salida EOC_OUT entidad xadc_wiz_0
  signal daddr_in: std_logic_vector(6 downto 0); -- dirección registro de estado a seleccionar
  signal do_out: std_logic_vector(15 downto 0);  -- salida valor ADC, 16 bits, 12 útiles
  signal drdy_out: std_logic; -- salida de indicación de dato válido
  -- Entidad func_trans (Función de transferencia para Temperatura)
  signal do_in_temp: std_logic_vector(11 downto 0); -- Valor adc para temperatura
  signal drdy_in_temp: std_logic;  -- entrada indicación dato válido para temperatura
  signal dato_val_temp: std_logic; -- salida indicación dato válido para temperatura
  signal temp_grad: std_logic_vector(19 downto 0);  -- salida temperatura en grados con signo
  -- Entidad func_trans_volt (Función de transferencia para Voltaje)
  signal do_in_volt: std_logic_vector(11 downto 0); -- Valor adc para voltaje
  signal drdy_in_volt: std_logic;  -- entrada indicación dato válido para voltaje
  signal dato_val_volt: std_logic; -- salida indicación dato válido para voltaje
  signal volt_mv: std_logic_vector(19 downto 0);  -- salida voltaje en mV sin signo (unipolar)
  -- Entidad valor_abs (Cálculo valor absoluto para temperatura)
  signal temp_abs: std_logic_vector(19 downto 0);
  signal dato_val_temp_abs: std_logic;
  -- Entidad bin2bcd (Algotitmo Binario a BCD con 20 bits)
  signal start_bcd: std_logic; -- entrada comienzo bin a bcd
  signal binary_in_bcd: std_logic_vector(19 downto 0); -- entrada binaria para conversión a bcd
  signal bcd0,bcd1,bcd2,bcd3,bcd4,bcd5: std_logic_vector(3 downto 0);
  -- Entidad visu7seg (BCD a 7 Segmentos)
  signal bcd0_visu: std_logic_vector(3 downto 0);
  signal bcd1_visu: std_logic_vector(3 downto 0);
  signal bcd2_visu: std_logic_vector(3 downto 0);
  signal bcd3_visu: std_logic_vector(3 downto 0);   
  
  
begin

  Ins_func_trans: entity work.func_trans
  port map(
    clk       => clk,
    reset     => reset,
    drdy      => drdy_in_temp,
    temp_sel  => temp_sel,
    temp_adc  => do_in_temp,
    dato_val  => dato_val_temp,
    temp_grad => temp_grad 
  );
  
  Ins_func_trans_volt: entity work.func_trans_volt
  port map(
    clk       => clk,
    reset     => reset,
    drdy      => drdy_in_volt,
    volt_sel  => volt_sel,
    volt_adc  => do_in_volt,
    dato_val  => dato_val_volt,
    volt_mv   => volt_mv
  );
  
  Inst_valor_abs: entity work.valor_abs
  port map( 
    clk        => clk,
    reset      => reset,
    dato_val_i => dato_val_temp,
    temp_in    => temp_grad,
    dato_val_o => dato_val_temp_abs,
    temp_out   => temp_abs,
    signo_o    => open
  );

    Inst_bin2bcd: entity work.bin2bcd
    generic map(N => 20)
    port map(
        clk       => clk,
        reset     => reset,
        start     => start_bcd,
        binary_in => binary_in_bcd,
        bcd0      => bcd0,
        bcd1      => bcd1,
        bcd2      => bcd2,
        bcd3      => bcd3,
        bcd4      => bcd4,
        bcd5      => bcd5,
        ready     => open
        );

   Inst_visu7seg: entity work.visu7seg
   port map(
        clk      => clk,
        reset    => reset,
        bcd_0    => bcd0_visu,
        bcd_1    => bcd1_visu,
        bcd_2    => bcd2_visu,
        bcd_3    => bcd3_visu,
        temp_sel => temp_sel,
        volt_sel => volt_sel,
        an       => an,
        ca       => ca,
        cb       => cb,
        cc       => cc,
        cd       => cd,
        ce       => ce,
        cf       => cf,
        cg       => cg,
        dp       => dp
        );
  Inst_xadc_wiz_0 : xadc_wiz_0
  PORT MAP (
    di_in       => (others => '0'),
    daddr_in    => daddr_in,
    den_in      => enable,
    dwe_in      => '0',
    drdy_out    => drdy_out,
    do_out      => do_out,
    dclk_in     => clk,
    reset_in    => reset,
    vp_in       => '0',
    vn_in       => '0',
    channel_out => open,
    eoc_out     => enable,
    alarm_out   => open,
    eos_out     => open,
    busy_out    => open
  );
  
  P1: process(clk, reset)
  begin
    if reset = '1' then
      drdy_in_temp  <= '0';
      do_in_temp    <= (others => '0');
      daddr_in      <= "0000000"; -- 0x00, registro de estado temperatura
      binary_in_bcd <= (others => '0');
      start_bcd     <= '0';
      drdy_in_volt  <= '0';
      do_in_volt    <= (others => '0');
    elsif rising_edge(clk) then
      if temp_sel = '1' then
        drdy_in_temp  <= drdy_out;
        do_in_temp    <= do_out(15 downto 4);
        daddr_in      <= "0000000"; -- 0x00, registro de estado temperatura
        binary_in_bcd <= temp_abs;
        start_bcd     <= dato_val_temp_abs;
        bcd0_visu     <= bcd2;
        bcd1_visu     <= bcd3;
        bcd2_visu     <= bcd4;
        bcd3_visu     <= bcd5;
        -- do_in_volt    <= (others => '0');
        drdy_in_volt  <= '0';
      elsif volt_sel = '1' then
        drdy_in_volt  <= drdy_out;
        do_in_volt    <= do_out(15 downto 4);
        binary_in_bcd <= volt_mv;
        start_bcd     <= dato_val_volt;
        bcd0_visu     <= bcd0;
        bcd1_visu     <= bcd1;
        bcd2_visu     <= bcd2;
        bcd3_visu     <= bcd3;
        drdy_in_temp  <= '0';
        if vram_sel = '1' then
          daddr_in <= "0000110"; -- 0x06
        else
          daddr_in <= "0000001"; -- 0x01
        end if;
      end if;             
    end if;
  end process;        
        
end Behavioral;
