library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.wr_pkg.all;

entity cute_lhaaso_wrapper is
generic(
    g_sfp0_enable: boolean:= true;
    g_sfp1_enable: boolean:= false
);
port
(
    -- global ports
    clk_20m_i       : in std_logic;   
    clk_sys_i       : in std_logic;   
    clk_dmtd_i      : in std_logic;
    clk_ref_i       : in std_logic;
    clk_sfp0_i      : in std_logic;
    clk_sfp1_i      : in std_logic;
    rst_n_o         : out std_logic;

    led1_o          : out std_logic;
    led2_o          : out std_logic;
    sfp0_led_o      : out std_logic;
    sfp1_led_o      : out std_logic;

    dac_sclk_o      : out std_logic;
    dac_din_o       : out std_logic;
    dac_clr_n_o     : out std_logic;
    dac_ldac_n_o    : out std_logic;
    dac_sync_n_o    : out std_logic;
    eeprom_scl_b    : inout std_logic;
    eeprom_sda_b    : inout std_logic;
    onewire_b       : inout std_logic;      -- 1-wire interface to ds18b20
    -------------------------------------------------------------------------
    -- sfp pins
    -------------------------------------------------------------------------
    sfp0_txp_o          : out   std_logic;
    sfp0_txn_o          : out   std_logic;
    sfp0_rxp_i          : in    std_logic:='0';
    sfp0_rxn_i          : in    std_logic:='0';
    sfp0_mod_def0_b     : in    std_logic:='0';  -- sfp detect
    sfp0_mod_def1_b     : inout std_logic:='0';  -- scl
    sfp0_mod_def2_b     : inout std_logic:='0';  -- sda
    sfp0_tx_fault_i     : in    std_logic:='0';
    sfp0_tx_disable_o   : out   std_logic;
    sfp0_los_i          : in    std_logic:='0';

    sfp1_txp_o          : out   std_logic;
    sfp1_txn_o          : out   std_logic;
    sfp1_rxp_i          : in    std_logic:='0';
    sfp1_rxn_i          : in    std_logic:='0';
    sfp1_mod_def0_b     : in    std_logic:='0';  -- sfp detect
    sfp1_mod_def1_b     : inout std_logic:='0';  -- scl
    sfp1_mod_def2_b     : inout std_logic:='0';  -- sda
    sfp1_tx_fault_i     : in    std_logic:='0';
    sfp1_tx_disable_o   : out   std_logic;
    sfp1_los_i          : in    std_logic:='0';

    pps_o               : out std_logic;
    pps_p1_o            : out std_logic;
    tm_tai_o            : out std_logic_vector(39 downto 0);
    tm_time_valid_o     : out std_logic;
    uart_rxd_i          : in  std_logic;
    uart_txd_o          : out std_logic;

    tcp_rx_data         : out std_logic_vector(7 downto 0);
    tcp_tx_data         : in  std_logic_vector(7 downto 0);
    tcp_tx_cts          : out std_logic;
    tcp_rx_data_valid   : out std_logic;
    tcp_tx_data_valid   : in  std_logic;
	 mpps_o					: out std_logic
);
end cute_lhaaso_wrapper;

architecture rtl of cute_lhaaso_wrapper is

------------------------------------------------------------------------------
-- components declaration
------------------------------------------------------------------------------
component cute_reset_gen is
  port (
    clk_sys_i : in std_logic;
    rst_n_o : out std_logic
  );
end component;

component cute_core_tcpip_top is
port(
    rst_n_i             : in std_logic;
    clk_20m_i           : in std_logic;
    clk_dmtd_i          : in std_logic;
    clk_sys_i           : in std_logic;     
    clk_ref_i           : in std_logic;
    clk_sfp0_i          : in std_logic;
    clk_sfp1_i          : in std_logic;
    dac_hpll_load_p1_o  : out std_logic;
    dac_hpll_data_o     : out std_logic_vector(15 downto 0);
    dac_dpll_load_p1_o  : out std_logic;
    dac_dpll_data_o     : out std_logic_vector(15 downto 0);
    eeprom_scl_i        : in  std_logic;
    eeprom_scl_o        : out std_logic;
    eeprom_sda_i        : in  std_logic;
    eeprom_sda_o        : out std_logic;
    flash_sclk_o        : out std_logic;
    flash_ncs_o         : out std_logic;
    flash_mosi_o        : out std_logic;
    flash_miso_i        : in  std_logic:='1';
    onewire_i           : in  std_logic;
    onewire_oen_o       : out std_logic;      
    uart_rxd_i          : in  std_logic;
    uart_txd_o          : out std_logic;
    sfp0_txp_o          : out std_logic;
    sfp0_txn_o          : out std_logic;
    sfp0_rxp_i          : in  std_logic:='0';
    sfp0_rxn_i          : in  std_logic:='0';
    sfp0_mod_def0_i     : in  std_logic:='0';  -- sfp detect
    sfp0_mod_def1_i     : in  std_logic:='0';  -- scl
    sfp0_mod_def1_o     : out std_logic;  -- scl
    sfp0_mod_def2_i     : in  std_logic:='0';  -- sda
    sfp0_mod_def2_o     : out std_logic;  -- sda
    sfp0_refclk_sel_i   : in std_logic_vector(2 downto 0):="000";
    sfp0_rate_select_o  : out std_logic;
    sfp0_tx_fault_i     : in  std_logic:='0';
    sfp0_tx_disable_o   : out std_logic;
    sfp0_los_i          : in  std_logic:='0';
    sfp0_rx_rbclk_o     : out std_logic;
    sfp1_txp_o          : out std_logic;
    sfp1_txn_o          : out std_logic;
    sfp1_rxp_i          : in  std_logic:='0';
    sfp1_rxn_i          : in  std_logic:='0';
    sfp1_mod_def0_i     : in  std_logic:='0';
    sfp1_mod_def1_i     : in  std_logic:='0';
    sfp1_mod_def1_o     : out std_logic:='0';
    sfp1_mod_def2_i     : in  std_logic:='0';
    sfp1_mod_def2_o     : out std_logic:='0';
    sfp1_rate_select_o  : out std_logic;
    sfp1_tx_fault_i     : in  std_logic:='0';
    sfp1_tx_disable_o   : out std_logic;
    sfp1_los_i          : in  std_logic:='0';
    sfp1_refclk_sel_i   : in std_logic_vector(2 downto 0):="000";
    sfp1_rx_rbclk_o     : out std_logic;
    wb_slave_o          : out t_wishbone_slave_out;
    wb_slave_i          : in  t_wishbone_slave_in := cc_dummy_slave_in;
    aux_master_o        : out t_wishbone_master_out;
    aux_master_i        : in  t_wishbone_master_in := cc_dummy_master_in;
    wrf_src_o           : out t_wrf_source_out;
    wrf_src_i           : in  t_wrf_source_in := c_dummy_src_in;
    wrf_snk_o           : out t_wrf_sink_out;
    wrf_snk_i           : in  t_wrf_sink_in   := c_dummy_snk_in;
    wb_eth_master_o     : out t_wishbone_master_out;
    wb_eth_master_i     : in  t_wishbone_master_in := cc_dummy_master_in;
    tm_link_up_o        : out std_logic;
    tm_time_valid_o     : out std_logic;
    tm_tai_o            : out std_logic_vector(39 downto 0);
    tm_cycles_o         : out std_logic_vector(27 downto 0);
    status_led_o        : out std_logic;
    pps_led_o           : out std_logic;
    link0_led_o         : out std_logic;
    link1_led_o         : out std_logic;
    btn_i               : in  std_logic := '1';
    pps_p_o             : out std_logic;
    pps_csync_o         : out std_logic;
    link_ok_o           : out std_logic
);
end component;

component xwr_com5402 is
generic(
    g_use_wishbone_interface : boolean := true;
      -- use wishbone interface to configure ip/mac addr
    nudptx: integer range 0 to 1:= 0;
    nudprx: integer range 0 to 1:= 0;
      -- number of udp ports enabled for tx and rx
    ntcpstreams: integer range 0 to 255 := 1;  
      -- number of concurrent tcp streams handled by this component
    clk_frequency: integer := 120;
      -- clk frequency in mhZ. needed to compute actual delays.
    tx_idle_timeout: integer range 0 to 50:= 50;  
      -- inactive input timeout, expressed in 4us units. -- 50*4us = 200us 
      -- controls the transmit stream segmentation: data in the elastic buffer will be transmitted if
      -- no input is received within tx_idle_timeout, without waiting for the transmit frame to be filled with mss data bytes.
    simulation: std_logic := '0'
      -- 1 during simulation with wireshark .cap file, '0' otherwise
      -- wireshark many not be able to collect offloaded checksum computations.
      -- when simulation =  '1': (a) ip header checksum is valid if 0000,
      -- (b) tcp checksum computation is forced to a valid 00001 irrespective of the 16-bit checksum
      -- captured by wireshark.
);
port(
    rst_n_i           : in std_logic;
    clk_ref_i         : in std_logic;
    clk_sys_i         : in std_logic;

    snk_i             : in  t_wrf_sink_in:=c_dummy_snk_in;
    snk_o             : out t_wrf_sink_out;
    src_o             : out t_wrf_source_out;
    src_i             : in  t_wrf_source_in:=c_dummy_src_in;

    udp_rx_data       : out std_logic_vector(7 downto 0);
    udp_rx_data_valid : out std_logic;
    udp_rx_sof        : out std_logic;
    udp_rx_eof        : out std_logic;

    udp_tx_data       : in  std_logic_vector(7 downto 0):= (others=>'0');
    udp_tx_data_valid : in  std_logic:= '0';
    udp_tx_sof        : in  std_logic:= '0';
    udp_tx_eof        : in  std_logic:= '0';
    udp_tx_cts        : out std_logic;
    udp_tx_ack        : out std_logic;
    udp_tx_nak        : out std_logic;

    --// user-initiated connection reset for stream i
    connection_reset  : in std_logic_vector((ntcpstreams-1) downto 0);
    tcp_connected_flag: out std_logic_vector((ntcpstreams-1) downto 0);

    tcp_rx_data       : out std_logic_vector(7 downto 0);
    tcp_rx_data_valid : out std_logic;
    tcp_rx_rts        : out std_logic;
    tcp_rx_cts        : in  std_logic:='1';
    tcp_tx_data       : in  std_logic_vector(7 downto 0):= (others=>'0');
    tcp_tx_data_valid : in  std_logic:='0';
    tcp_tx_cts        : out std_logic;

    cfg_slave_in  : in t_wishbone_slave_in:=cc_dummy_slave_in;
    cfg_slave_out : out t_wishbone_slave_out;

    my_mac_addr   : in std_logic_vector(47 downto 0):=x"1234567890ab";
    my_ip_addr    : in std_logic_vector(31 downto 0):=x"c0ab0008";
    my_subnet_mask: in std_logic_vector(31 downto 0):=x"ffff0000";
    my_gateway    : in std_logic_vector(31 downto 0):=x"c0ab0001";
    tcp_local_port_no: in std_logic_vector(15 downto 0):=x"dcba"
);
end component;

component cute_serial_dac_arb is
generic(
  g_invert_sclk    : boolean;
  g_num_extra_bits : integer
  );
port(
  clk_i   : in std_logic;
  rst_n_i : in std_logic;
  val1_i  : in std_logic_vector(15 downto 0);
  load1_i : in std_logic;
  val2_i  : in std_logic_vector(15 downto 0);
  load2_i : in std_logic;
  dac_ldac_n_o : out std_logic;
  dac_clr_n_o  : out std_logic;
  dac_sync_n_o : out std_logic;
  dac_sclk_o   : out std_logic;
  dac_din_o    : out std_logic);

end component;

component mpps_output
generic (
  g_clk_frequency : natural := 125000000);
port (
    clk_i       : in std_logic;
    rst_n_i     : in std_logic;
    pps_i       : in std_logic;
    mpps_o      : out std_logic
);
end component;

signal local_reset_n    : std_logic;

signal dac_hpll_load_p1 : std_logic;
signal dac_dpll_load_p1 : std_logic;
signal dac_hpll_data    : std_logic_vector(15 downto 0);
signal dac_dpll_data    : std_logic_vector(15 downto 0);

signal eeprom_scl_o : std_logic;
signal eeprom_scl_i : std_logic;
signal eeprom_sda_o : std_logic;
signal eeprom_sda_i : std_logic;
signal onewire_i: std_logic;
signal onewire_oen_o: std_logic;

signal sfp0_mod_def1_i,sfp0_mod_def1_o:std_logic;
signal sfp0_mod_def2_i,sfp0_mod_def2_o:std_logic;
signal sfp1_mod_def1_i,sfp1_mod_def1_o:std_logic;
signal sfp1_mod_def2_i,sfp1_mod_def2_o:std_logic;

signal tcpip_snk_i : t_wrf_sink_in;
signal tcpip_snk_o : t_wrf_sink_out;
signal tcpip_src_o : t_wrf_source_out;
signal tcpip_src_i : t_wrf_source_in;  
signal tcpip_slave_in:t_wishbone_slave_in;
signal tcpip_slave_out:t_wishbone_slave_out;

signal pps_p1_b: std_logic;

begin

eeprom_scl_b  <= '0' when eeprom_scl_o = '0' else 'Z';
eeprom_sda_b  <= '0' when eeprom_sda_o = '0' else 'Z';
eeprom_scl_i  <= eeprom_scl_b;
eeprom_sda_i  <= eeprom_sda_b;

sfp0_mod_def1_b <= '0' when sfp0_mod_def1_o = '0' else 'Z';
sfp0_mod_def2_b <= '0' when sfp0_mod_def2_o = '0' else 'Z';
sfp0_mod_def1_i <= sfp0_mod_def1_b;
sfp0_mod_def2_i <= sfp0_mod_def2_b;

sfp1_mod_def1_b <= '0' when sfp1_mod_def1_o = '0' else 'Z';
sfp1_mod_def2_b <= '0' when sfp1_mod_def2_o = '0' else 'Z';
sfp1_mod_def1_i <= sfp1_mod_def1_b;
sfp1_mod_def2_i <= sfp1_mod_def2_b;

onewire_b <= '0' when onewire_oen_o = '1' else 'Z';
onewire_i  <= onewire_b;

pps_p1_o <= pps_p1_b;

rst_n_o <= local_reset_n;

u_reset_gen : cute_reset_gen
  port map (
    clk_sys_i        => clk_sys_i,
    rst_n_o          => local_reset_n
 );

u_wrpc_sfp0: if (g_sfp0_enable = true and g_sfp1_enable=false) generate

 u_wr_core : cute_core_tcpip_top
  port map (
    rst_n_i            => local_reset_n,
    clk_20m_i          => clk_20m_i,
    clk_sys_i          => clk_sys_i,
    clk_dmtd_i         => clk_dmtd_i,
    clk_ref_i          => clk_ref_i,
    clk_sfp0_i         => clk_sfp0_i,
    clk_sfp1_i         => clk_sfp1_i,
    dac_hpll_load_p1_o => dac_hpll_load_p1,
    dac_hpll_data_o    => dac_hpll_data,
    dac_dpll_load_p1_o => dac_dpll_load_p1,
    dac_dpll_data_o    => dac_dpll_data,
    eeprom_scl_i       => eeprom_scl_i,
    eeprom_scl_o       => eeprom_scl_o,
    eeprom_sda_i       => eeprom_sda_i,
    eeprom_sda_o       => eeprom_sda_o,
    onewire_i          => onewire_i,
    onewire_oen_o      => onewire_oen_o,
    uart_rxd_i         => uart_rxd_i,
    uart_txd_o         => uart_txd_o,  
    sfp0_txp_o         => sfp0_txp_o,
    sfp0_txn_o         => sfp0_txn_o,
    sfp0_rxp_i         => sfp0_rxp_i,
    sfp0_rxn_i         => sfp0_rxn_i,
    sfp0_mod_def0_i    => sfp0_mod_def0_b,
    sfp0_mod_def1_i    => sfp0_mod_def1_i,
    sfp0_mod_def1_o    => sfp0_mod_def1_o,
    sfp0_mod_def2_i    => sfp0_mod_def2_i,
    sfp0_mod_def2_o    => sfp0_mod_def2_o,
    sfp0_rate_select_o => open,
    sfp0_tx_fault_i    => sfp0_tx_fault_i,
    sfp0_tx_disable_o  => sfp0_tx_disable_o,
    sfp0_los_i         => sfp0_los_i,
    sfp0_rx_rbclk_o    => open,
    sfp0_refclk_sel_i  => "000",
    aux_master_i       => tcpip_slave_out,
    aux_master_o       => tcpip_slave_in,
    wrf_snk_i          => tcpip_src_o,
    wrf_snk_o          => tcpip_src_i,
    wrf_src_o          => tcpip_snk_i,
    wrf_src_i          => tcpip_snk_o,
    tm_link_up_o       => open,
    tm_time_valid_o    => tm_time_valid_o,
    tm_tai_o           => tm_tai_o,
    tm_cycles_o        => open,
    status_led_o       => led1_o,
    pps_led_o          => led2_o,
    link0_led_o        => sfp0_led_o,
    link1_led_o        => sfp1_led_o,
    pps_p_o            => pps_o,
    pps_csync_o        => pps_p1_b,
    link_ok_o          => open
 );
end generate;

u_xwr_com5402: xwr_com5402
port map(
  rst_n_i           => local_reset_n,
  clk_ref_i         => clk_ref_i,
  clk_sys_i         => clk_sys_i,

  snk_i             => tcpip_snk_i,
  snk_o             => tcpip_snk_o,
  src_o             => tcpip_src_o,
  src_i             => tcpip_src_i,

--    udp_rx_data       => udp_rx_data,
--    udp_rx_data_valid => udp_rx_data_valid,
--    udp_rx_sof        => udp_rx_sof,
--    udp_rx_eof        => udp_rx_eof,
--
--    udp_tx_data       => udp_tx_data,
--    udp_tx_data_valid => udp_tx_data_valid,
--    udp_tx_sof        => udp_tx_sof,
--    udp_tx_eof        => udp_tx_eof,
--    udp_tx_cts        => udp_tx_cts,
--    udp_tx_ack        => udp_tx_ack,
--    udp_tx_nak        => udp_tx_nak,
  connection_reset  => (others=>'0'),
  tcp_connected_flag=> open,
  tcp_rx_data       => tcp_rx_data,
  tcp_rx_data_valid => tcp_rx_data_valid,  
  tcp_tx_data       => tcp_tx_data,
  tcp_tx_data_valid => tcp_tx_data_valid,
  tcp_tx_cts        => tcp_tx_cts,

  cfg_slave_in      => tcpip_slave_in,
  cfg_slave_out     => tcpip_slave_out
);

u_dac_arb : cute_serial_dac_arb
generic map (
    g_invert_sclk    => false,
    g_num_extra_bits => 8)
port map (
    clk_i            => clk_sys_i,
    rst_n_i          => local_reset_n,
    val1_i           => dac_dpll_data,
    load1_i          => dac_dpll_load_p1,
    val2_i           => dac_hpll_data,
    load2_i          => dac_hpll_load_p1,
    dac_sync_n_o     => dac_sync_n_o,
    dac_ldac_n_o     => dac_ldac_n_o,
    dac_clr_n_o      => dac_clr_n_o,
    dac_sclk_o       => dac_sclk_o,
    dac_din_o        => dac_din_o
);

u_mpps: mpps_output
generic map(
  g_clk_frequency => 125000000)
port map(
    clk_i          => clk_ref_i,
    rst_n_i        => local_reset_n,
    pps_i          => pps_p1_b,
    mpps_o         => mpps_o
);

end rtl;
