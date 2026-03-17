--------------------------------------------------------------------------------
-- Archivo:     bin2bcd.vhd
-- Autor:       Juan Manuel Delgado Romero
-- Fecha:       Febrero 2026
--
-- Institución: Universidad de Sevilla - Escuela Politécnica Superior
-- Titulación:  Grado en Ingeniería Electrónica Industrial
-- Proyecto:    Trabajo Fin de Grado (TFG)
-- Licencia:    MIT (Ver archivo LICENSE)
--
-- Descripción: 
-- Conversor de binario natural a formato BCD (Decimal Codificado en Binario) 
-- mediante la implementación del algoritmo Double Dabble (Shift-and-Add-3). 
-- Emplea una máquina de estados finitos (FSM) y lógica combinacional de 
-- corrección para transformar un valor de hasta 20 bits en 6 dígitos decimales.
-- Para más detalle veáse el apartado 7.6 del Capítulo 7 de la memoria de este
-- trabajo.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity bin2bcd is
    generic(N: positive := 20);
    port(
        clk, reset : in  std_logic;
        start      : in  std_logic; 
        binary_in  : in  std_logic_vector(N-1 downto 0);
        
        -- Salidas BCD
        bcd0, bcd1, bcd2, bcd3, bcd4, bcd5 : out std_logic_vector(3 downto 0);
        ready      : out std_logic
    );
end bin2bcd;

architecture behaviour of bin2bcd is
    type states is (idle, shift, done);
    signal state, state_next: states;

    signal binary, binary_next: std_logic_vector(N-1 downto 0);
    signal bcds, bcds_reg, bcds_next: std_logic_vector(23 downto 0);
    signal bcds_out_reg, bcds_out_reg_next: std_logic_vector(23 downto 0);
    signal shift_counter, shift_counter_next: natural range 0 to N;

begin

    -- Registro Secuencial
    process(clk, reset)
    begin
        if reset = '1' then
            binary <= (others => '0');
            bcds <= (others => '0');
            state <= idle;
            bcds_out_reg <= (others => '0');
            shift_counter <= 0;
        elsif rising_edge(clk) then
            binary <= binary_next;
            bcds <= bcds_next;
            state <= state_next;
            bcds_out_reg <= bcds_out_reg_next;
            shift_counter <= shift_counter_next;
        end if;
    end process;

    -- Lógica Combinacional de la FSM
    process(state, start, binary, binary_in, bcds, bcds_reg, shift_counter, bcds_out_reg)
    begin
        state_next <= state;
        bcds_next <= bcds;
        binary_next <= binary;
        shift_counter_next <= shift_counter;
        bcds_out_reg_next <= bcds_out_reg;
        ready <= '0';

        case state is
            when idle =>
                ready <= '1'; 
                -- Solo pasamos al estado shift si start='1'
                if start = '1' then
                    state_next <= shift;
                    binary_next <= binary_in;  
                    bcds_next <= (others => '0');
                    shift_counter_next <= 0;
                    ready <= '0'; 
                end if;

            when shift =>
                if shift_counter = N then
                    state_next <= done;
                else
                    binary_next <= binary(N-2 downto 0) & '0';
                    bcds_next <= bcds_reg(22 downto 0) & binary(N-1);
                    shift_counter_next <= shift_counter + 1;
                end if;

            when done =>
                bcds_out_reg_next <= bcds;
                state_next <= idle;
        end case;
    end process;

    -- Lógica "Add-3" (Corrección BCD)
    bcds_reg(23 downto 20) <= bcds(23 downto 20) + 3 when bcds(23 downto 20) > 4 else bcds(23 downto 20);
    bcds_reg(19 downto 16) <= bcds(19 downto 16) + 3 when bcds(19 downto 16) > 4 else bcds(19 downto 16);
    bcds_reg(15 downto 12) <= bcds(15 downto 12) + 3 when bcds(15 downto 12) > 4 else bcds(15 downto 12);
    bcds_reg(11 downto 8)  <= bcds(11 downto 8) + 3  when bcds(11 downto 8) > 4  else bcds(11 downto 8);
    bcds_reg(7 downto 4)   <= bcds(7 downto 4) + 3   when bcds(7 downto 4) > 4   else bcds(7 downto 4);
    bcds_reg(3 downto 0)   <= bcds(3 downto 0) + 3   when bcds(3 downto 0) > 4   else bcds(3 downto 0);

    -- Salidas
    bcd5 <= bcds_out_reg(23 downto 20);
    bcd4 <= bcds_out_reg(19 downto 16);
    bcd3 <= bcds_out_reg(15 downto 12);
    bcd2 <= bcds_out_reg(11 downto 8);
    bcd1 <= bcds_out_reg(7 downto 4);
    bcd0 <= bcds_out_reg(3 downto 0);

end behaviour;