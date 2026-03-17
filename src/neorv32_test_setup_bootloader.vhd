-- ================================================================================ --
-- NEORV32 - Test Setup Using The UART-Bootloader To Upload And Run Executables     --
-- -------------------------------------------------------------------------------- --
-- The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              --
-- Copyright (c) NEORV32 contributors.                                              --
-- Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  --
-- Licensed under the BSD-3-Clause license, see LICENSE for details.                --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_test_setup_bootloader is
  generic (
    -- adapt these for your setup --
    CLOCK_FREQUENCY   : natural := 100000000; -- clock frequency of clk_i in Hz
    MEM_INT_IMEM_SIZE : natural := 16*1024;   -- size of processor-internal instruction memory in bytes
    MEM_INT_DMEM_SIZE : natural := 16*1024     -- size of processor-internal data memory in bytes
  );
  port (
    -- Global control --
    clk_i       : in  std_ulogic; -- global clock, rising edge
    rstn_i      : in  std_ulogic; -- global reset, low-active, async
    -- GPIO --
    gpio_o      : out std_ulogic_vector(7 downto 0); -- parallel output
    -- UART0 --
    uart0_txd_o : out std_ulogic; -- UART0 send data
    uart0_rxd_i : in  std_ulogic;  -- UART0 receive data
    -- Visualizador 7 Segmentos --
    temp_sel    : in  std_logic;
    volt_sel    : in  std_logic;
    vram_sel    : in  std_logic;
    an          : out std_logic_vector(7 downto 0);
    ca          : out std_logic;
    cb          : out std_logic;
    cc          : out std_logic;
    cd          : out std_logic;
    ce          : out std_logic;
    cf          : out std_logic;
    cg          : out std_logic;
    dp          : out std_logic
  );
end entity;

architecture neorv32_test_setup_bootloader_rtl of neorv32_test_setup_bootloader is

  signal con_gpio_out : std_ulogic_vector(31 downto 0);
  -- Señales intermedias CFS --
  signal cfs_in_i_s   : std_ulogic_vector(2 downto 0);
  signal cfs_out_o_s   : std_ulogic_vector(15 downto 0);
begin

  -- The Core Of The Problem ----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  neorv32_top_inst: neorv32_top
  generic map (
    -- Clocking --
    CLOCK_FREQUENCY   => CLOCK_FREQUENCY,   -- clock frequency of clk_i in Hz
    -- Boot Configuration --
    BOOT_MODE_SELECT  => 0,                 -- boot via internal bootloader
    -- RISC-V CPU Extensions --
    RISCV_ISA_C       => false,              -- implement compressed extension?
    RISCV_ISA_M       => true,              -- implement mul/div extension?
    RISCV_ISA_Zicntr  => true,              -- implement base counters?
    -- Internal Instruction memory --
    MEM_INT_IMEM_EN   => true,              -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE => MEM_INT_IMEM_SIZE, -- size of processor-internal instruction memory in bytes
    -- Internal Data memory --
    MEM_INT_DMEM_EN   => true,              -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE => MEM_INT_DMEM_SIZE, -- size of processor-internal data memory in bytes
    -- Processor peripherals --
    IO_GPIO_NUM       => 8,                 -- number of GPIO input/output pairs (0..32)
    IO_CLINT_EN       => true,              -- implement core local interruptor (CLINT)?
    IO_UART0_EN       => true,              -- implement primary universal asynchronous receiver/transmitter (UART0)?
    -- CFS --
    IO_CFS_EN         => true,
    IO_CFS_IN_SIZE    => 3,
    IO_CFS_OUT_SIZE   => 16,
    -- AES extension --
    RISCV_ISA_Zknd    => true,
    RISCV_ISA_Zkne    => true
  )
  port map (
    -- Global control --
    clk_i       => clk_i,        -- global clock, rising edge
    rstn_i      => rstn_i,       -- global reset, low-active, async
    -- GPIO (available if IO_GPIO_NUM > 0) --
    gpio_o      => con_gpio_out, -- parallel output
    -- primary UART0 (available if IO_UART0_EN = true) --
    uart0_txd_o => uart0_txd_o,  -- UART0 send data
    uart0_rxd_i => uart0_rxd_i,   -- UART0 receive data
    -- CFS --
    cfs_in_i    => cfs_in_i_s,
    cfs_out_o   => cfs_out_o_s
  );

  -- GPIO output --
  gpio_o <= con_gpio_out(7 downto 0);
  -- Extración de bits CFS Conduit --
   -- entradas --
   cfs_in_i_s(0)  <= temp_sel;
   cfs_in_i_s(1)  <= volt_sel;
   cfs_in_i_s(2)  <= vram_sel;
   -- salidas --
   an  <= std_logic_vector(cfs_out_o_s(15 downto 8));
   ca  <= cfs_out_o_s(7);
   cb  <= cfs_out_o_s(6);
   cc  <= cfs_out_o_s(5);
   cd  <= cfs_out_o_s(4);
   ce  <= cfs_out_o_s(3);
   cf  <= cfs_out_o_s(2);
   cg  <= cfs_out_o_s(1);
   dp  <= cfs_out_o_s(0);
  

end architecture;
