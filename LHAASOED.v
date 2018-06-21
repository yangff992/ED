`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:55:48 04/01/2015 
// Design Name: 
// Module Name:    LHAASOED 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module LHAASOED(clkin_125M_P,clkin_125M_N,clk_20m_vcxo_i,IO_DA,IO_DB,IO_DCOA,IO_DCOB,adc_clk_p_o,adc_clk_n_o,fpga_pll_ref_clk_101_p_i,fpga_pll_ref_clk_101_n_i,sfp1_rxp_i,sfp1_rxn_i,hit_p,hit_n,
					 sfp1_mod_def0_b,sfp1_tx_fault_i,sfp1_los_i,uart_rxd_i,fpga_scl_b,fpga_sda_b,thermo_id_b,sfp1_mod_def1_b,
	             sfp1_mod_def2_b,dac_sclk_o,dac_din_o,dac_clr_n_o,dac_ldac_n_o,dac_sync_n_o,sfp1_txp_o,sfp1_txn_o,
					 sfp1_tx_disable_o,uart_txd_o,SDA_56972,SCL_56972,SDA_56971,SCL_56971,tanoe,adndata,caliswT,caliswQ,
					 SPIconfigQin_i,SPI_CSB_o,SPI_CLKO_o,SPI_DATAOUT_o,mpps_o,power_rxd_i,power_txd_o,second_packege_req,fpga_pll_ref_clk_123_p_i,fpga_pll_ref_clk_123_n_i
    );
//-------------------------------------------------
//------------CLOCK GENERATER----------------------+
//-------------------------------------------------
input clkin_125M_P;
input clkin_125M_N;
input clk_20m_vcxo_i;
output adc_clk_p_o;
output adc_clk_n_o;
wire out_clk_tdc_250M0;
wire out_clk_tdc_250M90;
wire out_clk_tdc_250M180;
wire out_clk_tdc_250M270;
wire CLK_10M_SPI;
wire clk_dmtd_i;
wire clk125M_WR;
wire clk62M5_WR;

clock instance_name (
    .out_clk_tdc_250M0(out_clk_tdc_250M0), 
    .out_clk_tdc_250M90(out_clk_tdc_250M90), 
    .out_clk_tdc_250M180(out_clk_tdc_250M180), 
    .out_clk_tdc_250M270(out_clk_tdc_250M270), 
    .adc_clk_p_o(adc_clk_p_o), 
    .adc_clk_n_o(adc_clk_n_o), 
    .CLK_20M(clk_20m_vcxo_i), 
    .CLK_10M_SPI(CLK_10M_SPI), 
    .clk_125M_pllref_p_i(clkin_125M_P), 
    .clk_125M_pllref_n_i(clkin_125M_N), 
    .clk_dmtd_i(clk_dmtd_i), 
    .clk125M_WR(clk125M_WR), 
    .clk62M5_WR(clk62M5_WR)
    );
//-------------------------------------------------
//--------------------mpps out----------------------
//-------------------------------------------------
wire pps_p1_o;
reg pps_p1_o_d;
wire pps_p1_d;
assign pps_p1_d=pps_p1_o_d;

always@(posedge clk125M_WR)begin
	pps_p1_o_d <= pps_p1_o;
end

output mpps_o;	  

//-------------------------------------------------
//------------------------TDC----------------------
//-------------------------------------------------

wire cute_reset;
wire RSTtoproject;
wire [63:0]wire_timeout;
wire time_ready;
(* KEEP = "TRUE" *)wire [39:0]wire_tm_utc_io;
wire [39:0]utcfromTDC;
wire [26:0]counterfromTDC;
wire hitbuf;
wire wire_nomalEN;
wire T_valid;
input hit_p;
input hit_n;
wire hitforPF;
IBUFDS IBUFDS_hit (.O(hitbuf),.I(hit_p),.IB(hit_n));
TDC hittime (
    .tdcpps(pps_p1_d), 
    .tdchit(hitbuf), 
    .clk_tdc_sys(clk125M_WR), 
    .TDC_RESET(~cute_reset), 
    .timeout(wire_timeout), 
    .clk_tdc_250M0(out_clk_tdc_250M0), 
    .clk_tdc_250M90(out_clk_tdc_250M90), 
    .clk_tdc_250M180(out_clk_tdc_250M180), 
    .clk_tdc_250M270(out_clk_tdc_250M270), 
    .TDC_tdcready(time_ready), 
    .tm_utc_io(wire_tm_utc_io),
	 .utcfromTDC(utcfromTDC),
	 .counterfromTDC(counterfromTDC),
	 .wire_nomalEN(wire_nomalEN),
	 .T_valid(T_valid),
	 .hitforPF(hitforPF)
    );


//-------------------------------------------------
//----------------PEAK FINDER----------------------
//-------------------------------------------------	
wire [67:0]Peakout;
wire [11:0]ADCdataA;
wire [11:0]ADCdataB;
wire PF_WriteEN;
wire wire_Hit_sync62M5_delayed;
wire newtimewindow;
PF peakfinder (
    .hit(hitbuf), 
    .CLK_HIT(clk62M5_WR), 
    .RESET(cute_reset), 
    .ADCdataA(ADCdataA), 
    .ADCdataB(ADCdataB), 
    .Peakout(Peakout), 
    .WriteEN(PF_WriteEN), 
    .Hit_sync62M5_delayed(wire_Hit_sync62M5_delayed),
	 .wire_nomalEN(wire_nomalEN),
	 .newtimewindow(newtimewindow),
	 .PF_TDCready(time_ready)
    );

//-------------------------------------------------
//----------------ADC data receiver----------------
//-------------------------------------------------	
input [11:0]IO_DA;
input [11:0]IO_DB;
input IO_DCOA;
input IO_DCOB;
ADCdatareceiver ADCdatamanager (
    .IO_DA(IO_DA), 
    .IO_DB(IO_DB), 
    .IO_DCOA(IO_DCOA), 
    .IO_DCOB(IO_DCOB), 
    .CLK(clk62M5_WR), 
    .RST(cute_reset), 
    .ADCdataB(ADCdataB), 
    .ADCdataA(ADCdataA)
    );
//-------------------------------------------------
//-----slow control packege-----------------------                                                                                                                               ----------------
//-------------------------------------------------
wire wire_tan_test_3;
wire [31:0]brd_temp_o;
wire brd_temp_valid_o;
wire wire_tanready;
wire test_erro;
wire wire_datafrom_power_ready;
(* KEEP = "TRUE" *)wire reg_second_packege_req;
wire [159:0]reg_second_packege;
wire [31:0]tandataout;
wire wire_pps_CLR;
wire req_done;
wire [79:0]wire_datafrom_power;
wire tm_time_valid_o;
output second_packege_req;
assign second_packege_req=wire_datafrom_power_ready;
slowcontrolpackge slowcontrolpackge (
    .wire_brd_temp_valid(brd_temp_valid_o), 
    .wire_brd_temp(brd_temp_o), 
    .sys_62M5_clk(clk62M5_WR), 
    .RST(cute_reset), 
    .wire_tan_test_3(wire_tan_test_3), 
    .wire_tanready(wire_tanready), 
    .test_erro(test_erro), 
    .wire_datafrom_power_ready(wire_datafrom_power_ready), 
    .reg_second_packege_req(reg_second_packege_req), 
    .reg_second_packege(reg_second_packege), 
    .wire_tm_utc_io(wire_tm_utc_io), 
    .tandataout(tandataout), 
    .wire_pps_CLR(wire_pps_CLR),
	 .req_done(req_done),
	 .wire_datafrom_power(wire_datafrom_power),
	 .tm_time_valid_o(tm_time_valid_o)
    );
//-------------------------------------------------
//-----calibration Q&T-----------------------------                                                                                                                               ----------------
//-------------------------------------------------
//output pps_caliT;
output caliswT;
output caliswQ;
wire caliT_EN;
wire caliQ_EN;
//assign pps_caliT=cali_T;

calibration QandT (
    .RST(cute_reset), 
    .caliQ_EN(caliQ_EN), 
    .clk_62M5(clk62M5_WR), 
    .caliswT(caliswT), 
    .caliswQ(caliswQ)
    );
//-------------------------------------------------
//-----regesiture read period----------------------                                                                                                                               ----------------
//-------------------------------------------------
wire wire_tanrst_3;
wire [15:0]wire_reg_reading_period;
updateperiod updateperiod (
    .wire_pps(pps_p1_d), 
    .wire_reg_reading_period(wire_reg_reading_period), 
    .sys_62M5_clk(clk62M5_WR), 
    .wire_tan_test_3(wire_tan_test_3), 
    .wire_tanrst_3(wire_tanrst_3),
	 .RST(cute_reset),
	 .wire_nomalEN(wire_nomalEN),
	 .wire_pps_CLR(wire_pps_CLR)
    );
//-------------------------------------------------
//-----Temperature&humidity in PMT housing---------                                                                                                                               ----------------
//-------------------------------------------------	 
inout adndata;	
output tanoe;
wire adndatain;
wire adnshakeout;
IOBUF tan (.O(adndatain),.IO(adndata),.I(adnshakeout),.T(adnshakeout)); 
TandHinhousing TandHinhousing (
    .clk(clk62M5_WR), 
    .reset(~cute_reset), 
    .startsamp(wire_tan_test_3), 
    .shakeout(adnshakeout), 
    .oe_o(tanoe), 
    .datain(adndatain), 
    .dataout(tandataout), 
    .erro(test_erro), 
    .tanready(wire_tanready), 
    .THSM_o(), 
    .tanstop(wire_tanrst_3)
    );
//-------------------------------------------------
//----------------Q&T conbination------------------
//-------------------------------------------------
wire wire_RST_forfifo;
wire QandTfifo_wren;
wire [131:0]QandTfifo_din;
QT QTconbination (
    .CLK_125M(clk125M_WR), 
    .CLK_62M5(clk62M5_WR), 
    .wire_RST_forfifo(wire_RST_forfifo), 
    .PF_WriteEN(PF_WriteEN), 
    .time_ready(time_ready), 
    .RST(cute_reset), 
    .Peak(Peakout), 
    .wire_timeout(wire_timeout), 
    .T_valid(T_valid), 
    .wire_Hit_sync62M5_delayed(wire_Hit_sync62M5_delayed), 
    .QandTfifo_wren(QandTfifo_wren), 
    .QandTfifo_din(QandTfifo_din),
	 .newtimewindow(newtimewindow)
    );	 

//-------------------------------------------------
//----------------CSR receiver---------------------
//-------------------------------------------------	
(* KEEP = "TRUE" *)wire  [7:0]TCP_RX_DATA;
(* KEEP = "TRUE" *)wire  wire_TCP_RX_DATA_VALID; 
(* KEEP = "TRUE" *) wire [31:0]datatoAD56971;
(* KEEP = "TRUE" *) wire [31:0]datatoAD56972;
(* KEEP = "TRUE" *) wire pedAdataready;
(* KEEP = "TRUE" *) wire caliQdataready;
(* KEEP = "TRUE" *) wire THdataready;
(* KEEP = "TRUE" *) wire pedDdataready;
(* KEEP = "TRUE" *) wire wire_normalEN;
(* KEEP = "TRUE" *) wire ADC_altimeEN;
wire [63:0]regreaddatatowr;
wire regreaddatatowr_req1;
wire user_reset_n_o;
wire SPI_erase_req;
wire SPI_program_req;
wire SPI_read_req;
wire SPI_reload_req;
wire SPIfifo_wren;
wire [255:0]configdata1x32bytes;
wire [255:0]configdata2x32bytes;
wire [255:0]configdata3x32bytes;
wire [255:0]configdata4x32bytes;
wire [255:0]configdata5x32bytes;
wire [255:0]configdata6x32bytes;
wire [255:0]configdata7x32bytes;
wire [255:0]configdata8x32bytes;
wire configdataready;
wire SPIfifo_wren_feedback_req;
wire feedback_req;
wire eraseonly_req;
wire readonly_req;
wire resetppaddr;
wire [27:0]CSR_dataforpower;
wire CSR_dataforpowerEN;
wire ms_req;
wire [23:0]ms_req_num;
wire	ms_req_num_ready;
wire start_trigger;
CSR CSRmanager (
    .wire_TCP_RX_DATA_VALID(wire_TCP_RX_DATA_VALID), 
    .TCP_RX_DATA(TCP_RX_DATA), 
    .clk_125M(clk125M_WR), 
    .clk_62M5(clk62M5_WR), 
    .RST(cute_reset), 
    .datatoAD56971(datatoAD56971), 
    .datatoAD56972(datatoAD56972), 
    .pedAdataready(pedAdataready), 
    .caliQdataready(caliQdataready), 
    .THdataready(THdataready), 
    .pedDdataready(pedDdataready), 
    .normalEN(wire_nomalEN), 
    .caliQEN(caliQ_EN), 
    .ADC_altimeEN(ADC_altimeEN), 
    .caliTEN(caliT_EN),
	 .regreaddatatowr(regreaddatatowr), 
    .regreaddatatowr_req1(regreaddatatowr_req1), 
    .req_done(req_done),
	 .wire_reg_reading_period(wire_reg_reading_period),
	 .RSTtoproject(RSTtoproject),
	 .wire_RST_forfifo(wire_RST_forfifo),
	 .SPI_erase_req(SPI_erase_req),
	 .SPI_program_req(SPI_program_req),
	 .SPI_read_req(SPI_read_req),
	 .SPI_reload_req(SPI_reload_req),
	 .SPIfifo_wren(SPIfifo_wren),
	 .configdata1x32bytes(configdata1x32bytes),
	 .configdata2x32bytes(configdata2x32bytes),
	 .configdata3x32bytes(configdata3x32bytes),
	 .configdata4x32bytes(configdata4x32bytes),
	 .configdata5x32bytes(configdata5x32bytes),
	 .configdata6x32bytes(configdata6x32bytes),
	 .configdata7x32bytes(configdata7x32bytes),
	 .configdata8x32bytes(configdata8x32bytes),
	 .configdataready(configdataready),
	 .SPIfifo_wren_feedback_req(SPIfifo_wren_feedback_req),
	 .feedback_req(feedback_req),
	 .eraseonly_req(eraseonly_req),
	 .readonly_req(readonly_req),
	 .resetppaddr(resetppaddr),
	 .CSR_dataforpower(CSR_dataforpower),
	 .CSR_dataforpowerEN(CSR_dataforpowerEN),
	 .ADCdataB(ADCdataB), 
    .ADCdataA(ADCdataA),
	 .ms_req(ms_req),
	 .ms_req_num(ms_req_num),
	 .ms_req_num_ready(ms_req_num_ready),
	 .start_trigger(start_trigger)
    );
//-------------------------------------------------
//----------------high voltage power manager-------
//-------------------------------------------------
input power_rxd_i;
output power_txd_o;
powercontrol powermanager (
    .RST(cute_reset), 
    .clk_62M5(clk62M5_WR), 
    .CSR_dataforpowerEN(CSR_dataforpowerEN), 
    .CSR_dataforpower(CSR_dataforpower), 
    .wire_tan_test_3(wire_tan_test_3), 
    .datafrom_power_ready(wire_datafrom_power_ready), 
    .wire_datafrom_power(wire_datafrom_power), 
    .power_rxd_i(power_rxd_i), 
    .power_txd_o(power_txd_o)
    );	 
//-------------------------------------------------
//----------------pedA&&caliQ manager--------------
//-------------------------------------------------

IPROG reload (
	 .CLK(CLK_10M_SPI), 
	 .reload_req(SPI_reload_req), 
	 .reload_rst(cute_reset)
	 );
//-------------------------------------------------
//----------------pedA&&caliQ manager--------------
//-------------------------------------------------
wire DAC1data_ready;
assign DAC1data_ready=pedAdataready|caliQdataready;
output SDA_56971;
output SCL_56971;
	
ADR5697 DAC1 (
    .clk(clk62M5_WR), 
    .rst(cute_reset), 
    .SDA(SDA_56971), 
    .SCL(SCL_56971), 
    .CSR_dataready(DAC1data_ready), 
    .CSR_data5697(datatoAD56971)
    );
//-------------------------------------------------
//----------------TH&&pedD manager-----------------
//-------------------------------------------------
wire DAC2data_ready;
assign DAC2data_ready=THdataready|pedDdataready;
output SDA_56972;
output SCL_56972;
		
ADR5697 DAC2 (
    .clk(clk62M5_WR), 
    .rst(cute_reset), 
    .SDA(SDA_56972), 
    .SCL(SCL_56972), 
    .CSR_dataready(DAC2data_ready), 
    .CSR_data5697(datatoAD56972)
    );
//-------------------------------------------------
//----------------DATA manager---------------------
//-------------------------------------------------

wire TCP_TX_CTS;
wire TCP_TX_DATA_VALID;
wire [7:0]TCP_TX_DATA;
wire SEover_answer;
wire [9:0]datafifo_data_count;
wire datafiford_en;
wire [279:0]datafifo_out;
wire datafifo_empty;
wire PPover_answer_req;
wire [7:0]PPover_answer;
DATA DATA (
    .clk_125M(clk125M_WR), 
    .QTfifodata(QandTfifo_din), 
    .rst(cute_reset), 
    .datatoWRvalid(TCP_TX_DATA_VALID), 
    .datatoWR(TCP_TX_DATA), 
    .slowcontrol_req(reg_second_packege_req), 
    .regread_req(regreaddatatowr_req1), 
    .regreaddata(regreaddatatowr), 
    .slowcontroldata(reg_second_packege), 
    .counterfromTDC(counterfromTDC), 
    .utcfromTDC(utcfromTDC), 
    .wire_RST_forfifo(wire_RST_forfifo), 
    .clk_62M5(clk62M5_WR), 
    .QandTfifo_wren(QandTfifo_wren), 
    .req_done(req_done),
	 .TCP_TX_CTS(TCP_TX_CTS),
	 .SPIfifo_wren(SPIfifo_wren),
	 .SEover_answer(SEover_answer),
	 .datafiford_en(datafiford_en),
	 .datafifo_out(datafifo_out),
	 .datafifo_empty(datafifo_empty),
	 .datafifo_data_count(datafifo_data_count),
	 .readonly_req(readonly_req),
    .PPover_answer_req(PPover_answer_req),
	 .PPover_answer(PPover_answer),
	 .SPIfifo_wren_feedback_req(SPIfifo_wren_feedback_req),
	 .feedback_req(feedback_req),
	 .ms_req(ms_req),
	 .ms_req_num(ms_req_num),
	 .ms_req_num_ready(ms_req_num_ready),
	 .start_trigger(start_trigger)
    );
	 
////////////////////SPIconfig//////////////////////////////////////////	
wire verify_error_o;
input SPIconfigQin_i;
output  SPI_CSB_o;
output  SPI_CLKO_o;
output  SPI_DATAOUT_o;
wire wire_configdataready;
wire [255:0]wire_BYTEdata1x32;
wire [255:0]wire_BYTEdata2x32;
wire [255:0]wire_BYTEdata3x32;
wire [255:0]wire_BYTEdata4x32;
wire [255:0]wire_BYTEdata5x32;
wire [255:0]wire_BYTEdata6x32;
wire [255:0]wire_BYTEdata7x32;
wire [255:0]wire_BYTEdata8x32;
SPIconfig flashconfig (
    .SPIcongfigCLK(CLK_10M_SPI), 
    .SPIconfigQin(SPIconfigQin_i), 
    .BYTEdata1x32(configdata1x32bytes), 
    .BYTEdata2x32(configdata2x32bytes), 
    .BYTEdata3x32(configdata3x32bytes), 
    .BYTEdata4x32(configdata4x32bytes), 
    .BYTEdata5x32(configdata5x32bytes), 
    .BYTEdata6x32(configdata6x32bytes), 
    .BYTEdata7x32(configdata7x32bytes), 
    .BYTEdata8x32(configdata8x32bytes), 
    .verify_error(verify_error_o),
    .SPIaddr(), 
    .SPI_CSB(SPI_CSB_o), 
    .SPI_CLKO(SPI_CLKO_o), 
    .SPI_DATAOUT(SPI_DATAOUT_o),
	 .configdataready(configdataready),
	 .SPI_erase_req(SPI_erase_req),
	 .SPI_program_req(SPI_program_req),
	 .SPI_read_req(SPI_read_req),
	 .SEover_answer(SEover_answer),
	 .clk125(clk125M_WR),
	 .datafiford_en(datafiford_en),
	 .datafifo_out(datafifo_out),
	 .datafifo_empty(datafifo_empty),
	 .datafifo_data_count(datafifo_data_count),
    .PPover_answer_req(PPover_answer_req),
	 .PPover_answer(PPover_answer),
	 .eraseonly_req(eraseonly_req),
	 .readonly_req(readonly_req),
	 .SPIconfigreset(cute_reset),
	 .resetppaddr(resetppaddr)
    );	 
	 
	 
//-------------------------------------------------
//-------------WR&&TCP manager---------------------
//-------------------------------------------------
input fpga_pll_ref_clk_101_p_i;
input fpga_pll_ref_clk_101_n_i;
input fpga_pll_ref_clk_123_p_i;
input fpga_pll_ref_clk_123_n_i;
input sfp1_rxp_i;
input sfp1_rxn_i;
input sfp1_mod_def0_b;
input sfp1_tx_fault_i;
input sfp1_los_i;
input uart_rxd_i;

inout fpga_scl_b;
inout fpga_sda_b;
inout thermo_id_b;

inout sfp1_mod_def1_b;
inout sfp1_mod_def2_b;

output dac_sclk_o;
output dac_din_o;
output dac_clr_n_o;
output dac_ldac_n_o;
output dac_sync_n_o;

output sfp1_txp_o;
output sfp1_txn_o;
output sfp1_tx_disable_o;
output uart_txd_o;
wire TCP_RX_RTS; 
wire gtp_dedicated_clk;
wire clk_sfp0_i;
wire clk_sfp1_i;

IBUFGDS IBUFGDS_clk_gtp0_i (.O(clk_sfp0_i),.I(fpga_pll_ref_clk_101_p_i),.IB(fpga_pll_ref_clk_101_n_i));
IBUFGDS IBUFGDS_clk_gtp1_i (.O(clk_sfp1_i),.I(fpga_pll_ref_clk_123_p_i),.IB(fpga_pll_ref_clk_123_n_i));

cute_lhaaso_wrapper cute_core (
    .clk_20m_i(clk_20m_i), 
    .clk_sys_i(clk62M5_WR), 
    .clk_dmtd_i(clk_dmtd_i), 
    .clk_ref_i(clk125M_WR), 
    .clk_sfp0_i(clk_sfp0_i),
    .clk_sfp1_i(clk_sfp1_i),
    .rst_n_o(cute_reset), 
    .led1_o(), 
    .led2_o(), 
    .sfp0_led_o(), 
    .sfp1_led_o(), 
    .dac_sclk_o(dac_sclk_o), 
    .dac_din_o(dac_din_o), 
    .dac_clr_n_o(dac_clr_n_o), 
    .dac_ldac_n_o(dac_ldac_n_o), 
    .dac_sync_n_o(dac_sync_n_o), 
    .eeprom_scl_b(fpga_scl_b), 
    .eeprom_sda_b(fpga_sda_b), 
    .onewire_b(thermo_id_b), 
    .sfp0_txp_o(sfp1_txp_o), 
    .sfp0_txn_o(sfp1_txn_o), 
    .sfp0_rxp_i(sfp1_rxp_i), 
    .sfp0_rxn_i(sfp1_rxn_i), 
    .sfp0_mod_def0_b(sfp1_mod_def0_b), 
    .sfp0_mod_def1_b(sfp1_mod_def1_b), 
    .sfp0_mod_def2_b(sfp1_mod_def2_b), 
    .sfp0_tx_fault_i(sfp1_tx_fault_i), 
    .sfp0_tx_disable_o(sfp1_tx_disable_o), 
    .sfp0_los_i(sfp1_los_i), 
//    .sfp1_txp_o(sfp1_txp_o), 
//    .sfp1_txn_o(sfp1_txn_o), 
//    .sfp1_rxp_i(sfp1_rxp_i), 
//    .sfp1_rxn_i(sfp1_rxn_i), 
//    .sfp1_mod_def0_b(sfp1_mod_def0_b), 
//    .sfp1_mod_def1_b(sfp1_mod_def1_b), 
//    .sfp1_mod_def2_b(sfp1_mod_def2_b), 
//    .sfp1_tx_fault_i(sfp1_tx_fault_i), 
//    .sfp1_tx_disable_o(sfp1_tx_disable_o), 
//    .sfp1_los_i(sfp1_los_i), 
    .pps_o(pps_o), 
	 .pps_p1_o(pps_p1_o),
    .tm_tai_o(wire_tm_utc_io), 
    .tm_time_valid_o(tm_time_valid_o), 
    .uart_rxd_i(uart_rxd_i), 
    .uart_txd_o(uart_txd_o), 
    .tcp_rx_data(TCP_RX_DATA), 
    .tcp_tx_data(TCP_TX_DATA), 
    .tcp_tx_cts(TCP_TX_CTS), 
    .tcp_rx_data_valid(wire_TCP_RX_DATA_VALID), 
    .tcp_tx_data_valid(TCP_TX_DATA_VALID),
	 .mpps_o(mpps_o)
    );
endmodule
