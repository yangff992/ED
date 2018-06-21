`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:23:18 04/22/2015 
// Design Name: 
// Module Name:    DATA 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
//	This moduler is used to assemble Q&T, slow_control, register_read data, then transmit them to TCP/IP.
//	It contains 3 FSM:
//	1.Assembling Data:
//	2.Tranmit data from final_fifo to TCP fifo ,and data feedback for REMOTE UPDATE
//	3.Tranmit data from TCP fifo to TCP(COM5402)
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// 2018.05.30	CHANGE TRANSMISSION MODE 
//////////////////////////////////////////////////////////////////////////////////
module DATA(
	input clk_125M,
	input [131:0]QTfifodata,
	input rst,
	output reg datatoWRvalid,
	output reg [7:0]datatoWR,
	input slowcontrol_req,
	input regread_req,
	input [63:0]regreaddata,
	input [159:0]slowcontroldata,
	input [26:0]counterfromTDC,
	input [39:0]utcfromTDC,
	input wire_RST_forfifo,
	input clk_62M5,
	input QandTfifo_wren,
	output reg req_done,
	input TCP_TX_CTS,
	input SPIfifo_wren,
	input SEover_answer,
	output reg datafiford_en,
	input [279:0]datafifo_out,
	input datafifo_empty,
	input [9:0]datafifo_data_count,
	input readonly_req,
	input PPover_answer_req,
	input [7:0]PPover_answer,
	input SPIfifo_wren_feedback_req,
	input feedback_req,
	output reg ms_req,
	input[23:0] ms_req_num,
	input ms_req_num_ready,
	input start_trigger
    );
wire SEover_answer_0;
wire SEover_answer_1;
FDCE FDCE_SEover_answer  (.Q(SEover_answer_0),.C(SEover_answer),.CE(1'b1),.CLR(SEover_answer_1),.D(1'b1));
FDCE FDCE_SEover_answer_0  (.Q(SEover_answer_1),.C(clk_125M),.CE(1'b1),.CLR(1'b0),.D(SEover_answer_0));

//------------------------------------------------------------------------------//
// counter for transmission interval(1ms 10ms 100ms) 
//------------------------------------------------------------------------------//
reg [23:0]cnt_ms;
reg halfms_req;
reg[23:0] DATA_ms_req_num;
reg ms_req_start;
reg no_req_interval;

wire DATA_ms_req_num_ready;
assign DATA_ms_req_num_ready=ms_req_num_ready;

always@(posedge clk_125M)begin
if(~rst)begin
	DATA_ms_req_num[23:0] <= 24'hFFFFFF;
	ms_req_start<=1'b0;
	no_req_interval <= 1'b0;
end
else begin 
	if(DATA_ms_req_num_ready)begin
		if(ms_req_num[23:0]==24'h0)begin
			no_req_interval <= 1'b1;
			ms_req_start<=1'b1;
			DATA_ms_req_num[23:0] <= 24'd124999;
		end
		else begin
			no_req_interval <= 1'b0;
			ms_req_start<=1'b1;
			DATA_ms_req_num[23:0] <= ms_req_num[23:0];
		end
	end
	else begin
		DATA_ms_req_num[23:0] <= 24'hFFFFFF;
		ms_req_start<=1'b0;
		no_req_interval <= 1'b0;			
	end
end
end

always@(posedge clk_125M)begin
if(~rst) begin
	cnt_ms[23:0]<=24'b0;
	ms_req<=1'b0;
end
else begin
	if((~no_req_interval) && ms_req_start)begin
		if(cnt_ms[23:0] == DATA_ms_req_num[23:0])begin
			cnt_ms[23:0]<=24'b0;
			ms_req<=1'b1;
		end
		else begin
			cnt_ms[23:0]<=cnt_ms[23:0]+24'b1;
			ms_req<=1'b0;
		end
	end
	else if(no_req_interval && ms_req_start)begin
		if(cnt_ms[23:0] == DATA_ms_req_num[23:0])begin
			cnt_ms[23:0]<=24'b0;
			ms_req<=1'b1;
		end
		else begin
			cnt_ms[23:0]<=cnt_ms[23:0]+24'b1;
			ms_req<=1'b1;
		end
	end
	else begin
		cnt_ms[23:0]<=cnt_ms[23:0]+24'b1;
		ms_req<=1'b0;
	end
end
end
//------------------------------------------------------------------------------//
// slow_control or register read detect
//------------------------------------------------------------------------------//
(* KEEP = "TRUE" *)wire sloworreg_req;
assign sloworreg_req=halfms_req&&(slowcontrol_req||regread_req);
always@(posedge clk_125M)begin
if(~rst) halfms_req<=1'b0;
else if(cnt_ms[23:0] ==24'd62499) halfms_req<=1'b1;
else halfms_req<=1'b0;
end
//------------------------------------------------------------------------------//
//states and signals for ASSEMBLING FINAL DATA
//------------------------------------------------------------------------------//
(* KEEP = "TRUE" *)reg [2:0]state;
parameter state_idle=3'b0001;//01
parameter state_s0  =3'b0010;//02
parameter state_s1  =3'b0100;//04
reg flag_S1;
reg [11:0] hold_QTfifo_data_count;
//------------------------------------------------------------------------------//
//------------------------------------------------------------------------------//
wire 	[131:0]QTfifodout;
reg 	QTfiforden;
wire 	QTfifo_empty;
wire 	QT_fifo_full;
wire 	QT_fifo_almost_full;
wire	[10:0] QTfifo_data_count;
reg	[10:0] QTfifo_data_count_D;
reg 	[14:0] cnt_LH_local; //caculate lost hits
reg [15:0]num_hit;
//------------------------------------------------------------------------------//
//signals for FINAL_FIFO
//------------------------------------------------------------------------------//
reg finalfifowren;
reg [175:0]finalfifodin;
reg [175:0]finalfifodin_sl;
wire [175:0]finalfifodout;
wire [11:0]finalfifodatacount;
reg [175:0]finalfifodouthold;
reg finalfiforden;
wire finalfifofull;
wire finalfifoempty;
//------------------------------------------------------------------------------//
//states and signals for DATA TRANSMISSION FORM FINAL_FIFO TO TCP_FIFO
//------------------------------------------------------------------------------//
(* KEEP = "TRUE" *)reg[1:0] state_Final_to_TCP;
parameter state_Final_to_TCP_idle =2'b01;//01
parameter state_Final_to_TCP_transmit =2'b10;//04
reg	[4:0]cnt_shift;
//------------------------------------------------------------------------------//
//states and signals for REMOTE UPDATE
//------------------------------------------------------------------------------//
reg [1:0]state1;
parameter state1_idle=2'b01;
parameter state1_s0  =2'b10;
reg [279:0]datafifo_outhold;
reg [5:0]cnt_shiftfifo;
//------------------------------------------------------------------------------//
//states and signals for TCP fifo (A SMALL FIFO BEFOR COM5402,USED AS AN INTERFACE BETWEEN USER LAYER AND TRANSMISSION LAYER)
//------------------------------------------------------------------------------//
(* KEEP = "TRUE" *)reg [11:0]cnt_for1460;
reg 	[7:0]	newfifocounter;
reg 	[7:0]	tcp_fifo_data_in;
wire 	[7:0]	tcp_fifo_data_out;
reg 			tcp_fifo_wr_en;
reg 			tcp_fifo_rd_en;
wire 			tcp_fifo_almost_full;
wire 			tcp_fifo_full;
wire 			tcp_fifo_empty;
wire 			tcp_prog_full;
wire [10:0]	tcp_fifo_data_count;


reg [1:0] state_before5402;
parameter state_before5402_idle=2'b00;
parameter state_before5402_ready=2'b01;
parameter state_before5402_normal=2'b10;
parameter state_before5402_wait=2'b11;
//------------------------------------------------------------------------------//
//QTfifo:store hit,PEAK VALUE[131:64] TIME[63:0]
//------------------------------------------------------------------------------//
fifo2048x128 fifo2048x132 (
  .clk(clk_125M), // input clk
  .rst(wire_RST_forfifo), // input rst
  .din(QTfifodata), // input [131 : 0] din
  .wr_en((~SPIfifo_wren)&&QandTfifo_wren&&(~QT_fifo_almost_full)), // input wr_en
  .rd_en(QTfiforden), // input rd_en
  .dout(QTfifodout), // output [131 : 0] dout
  .full(QT_fifo_full), // output full
  .almost_full(QT_fifo_almost_full), // output almost_full
  .empty(QTfifo_empty), // output empty
  .data_count(QTfifo_data_count) // output [10 : 0] data_count
);
//------------------------------------------------------------------------------//
//counter for lost hits
//------------------------------------------------------------------------------//
always@(posedge clk_125M)begin
	if((~rst) || start_trigger) begin
		cnt_LH_local[14:0] <= 15'b0;
	end
	else begin
		if(QT_fifo_almost_full && QandTfifo_wren) cnt_LH_local[14:0] <= cnt_LH_local[14:0] +1'b1;
		else cnt_LH_local[14:0] <= cnt_LH_local[14:0];
	end
end
//------------------------------------------------------------------------------//
//final_fifo :store assembled data according to data format
//------------------------------------------------------------------------------//
finalfifo2048x176 finalfifo2048x176 (
  .clk(clk_125M), // input clk
  .rst(wire_RST_forfifo), // input rst
  .din(finalfifodin), // input [175 : 0] din
  .wr_en(finalfifowren&&(~finalfifofull)), // input wr_en
  .rd_en(finalfiforden), // input rd_en
  .dout(finalfifodout), // output [175 : 0] dout
  .full(finalfifofull), // output full
  .empty(finalfifoempty), // output empty
  .data_count(finalfifodatacount) // output [11 : 0] data_count
);

//------------------------------------------------------------------------------//
//state machine 
//1. data transmission from QTfifo to final_fifo
//2. assemble data into packet: hit,slow control or remote update
//------------------------------------------------------------------------------//
always@(posedge clk_125M)begin
if(~rst) begin
		QTfiforden<=0;
		finalfifowren<=0;
		num_hit<=16'b0;
		finalfifodin<=0;
		req_done<=1'b0;
		flag_S1<=1'b0;
		hold_QTfifo_data_count[11:0] <= 12'b0;
		state<=state_idle;
		end
else begin 
if (~readonly_req)begin
case (state) 
		state_idle:begin
			QTfiforden<=0;
			finalfifowren<=0;
			finalfifodin<=0;
			req_done<=1'b0;
			flag_S1<=1'b0;
			if(ms_req && (~(sloworreg_req||SPIfifo_wren))) begin
				hold_QTfifo_data_count[11:0]<={1'b0,QTfifo_data_count[10:0]};
				state<=state_s0;
			end
			else if(sloworreg_req||SPIfifo_wren)begin
				state<=state_s1;
			end
			else begin 
				state<=state_idle;
			end
		end

		state_s0:begin
			if(~finalfifofull)begin
				if (hold_QTfifo_data_count > 12'b0)begin
					QTfiforden <= 1'b1;
					finalfifodin[175:0]<={8'h01,num_hit[15:0],1'b0,QTfifodout[131:125],4'b0000,QTfifodout[124:113],1'b0,QTfifodout[112:98],1'b0,QTfifodout[97:91],4'b0000,QTfifodout[90:79],1'b0,QTfifodout[78:64],QTfifodout[63:0],8'haa};
					num_hit<=num_hit+16'b1;
					finalfifowren<=1'b1;
					hold_QTfifo_data_count <= hold_QTfifo_data_count - 1'b1;
					state<=state_s0;
				end
				else begin
					QTfiforden <= 1'b0;
					finalfifowren<=1'b0;
					state<=state_idle;
				end
			end
			else begin
				finalfifodin[175:0]<=finalfifodin[175:0];
				finalfifowren<=1'b0;
				hold_QTfifo_data_count <= hold_QTfifo_data_count;
				state<=state_s0;
			end
		end
		
		
		state_s1:begin
			if(~finalfifofull)begin
				if(flag_S1==1'b0)begin
					if(regread_req	&&	(~SPIfifo_wren))begin
						finalfifodin[175:0]<={8'hff,96'b0,regreaddata[63:0],8'hAA};
						req_done<=1'b1;
						flag_S1<=1'b1;
						finalfifowren<=1'b1;
						state<=state_s1;
					end			
					else if((~regread_req)	&&	slowcontrol_req && (~SPIfifo_wren))begin
						finalfifodin[175:0]<={8'h02,slowcontroldata[159:31],cnt_LH_local[14:0],slowcontroldata[15:0],8'hAA};
						req_done<=1'b1;
						flag_S1<=1'b1;
						finalfifowren<=1'b1;
						state<=state_s1;
					end
					if(SPIfifo_wren_feedback_req||feedback_req)begin
						finalfifodin[175:0]<={8'hff,96'b0,8'hff,8'h00,48'b0,8'hAA};
						req_done<=1'b1;
						flag_S1<=1'b1;
						finalfifowren<=1'b1;
						state<=state_s1;	
					end
					else if(SEover_answer_1)begin
						finalfifodin[175:0]<={8'hff,96'b0,8'h05,8'h0F,48'b0,8'hAA};
						req_done<=1'b1;
						flag_S1<=1'b1;
						finalfifowren<=1'b1;
						state<=state_s1;			 
					end
					else if(PPover_answer_req)begin
						finalfifodin[175:0]<={8'hff,96'b0,8'h05,PPover_answer[7:0],48'b0,8'hAA};
						req_done<=1'b1;
						flag_S1<=1'b1;
						finalfifowren<=1'b1;
						state<=state_s1;	
					end
				end
				else begin
					finalfifowren<=1'b0;
					flag_S1<=1'b0;
					state<=state_idle;
				end
			end
			else begin
				finalfifodin[175:0]<=finalfifodin[175:0];
				finalfifowren<=1'b0;
				state<=state_s1;
			end
		end
		
		default : state<=state_idle;
	endcase
end
else begin
	QTfiforden<=0;
	finalfifowren<=0;
	num_hit<=16'b0;
	finalfifodin<=0;
	req_done<=1'b0;
	flag_S1<=1'b0;
	hold_QTfifo_data_count[11:0] <= 12'b0;
	state<=state_idle;
end
end 
end
//------------------------------------------------------------------------------//
//state machine for data transmition from final_fifo to tcp_fifo
//------------------------------------------------------------------------------//
always@(posedge clk_125M)begin
if(~rst)begin
	cnt_shift<=0;
	finalfiforden<=1'b0;
	tcp_fifo_wr_en	<= 1'b0;
	tcp_fifo_data_in <= 8'b0;
	finalfifodouthold[175:0]<= 176'b0;
	state_Final_to_TCP <= state_Final_to_TCP_idle;
	datafiford_en<=1'b0;
	cnt_shiftfifo<=0;
	datafifo_outhold<=0;
	state1<=state1_idle;
end
else begin	
if (~readonly_req)begin 
	case(state_Final_to_TCP)
		state_Final_to_TCP_idle:begin
			cnt_shift<=0;
			finalfiforden<=1'b0;
			tcp_fifo_wr_en	<= 1'b0;
			finalfifodouthold[175:0]<=0;
			if((~finalfifoempty) && (tcp_fifo_data_count[10:0] < 11'd1900))begin
				finalfiforden<=1'b1;
				finalfifodouthold[175:0]<=finalfifodout[175:0];
				state_Final_to_TCP <= state_Final_to_TCP_transmit;
			end
			else begin
				state_Final_to_TCP<=state_Final_to_TCP_idle;
			end
		end
		
		state_Final_to_TCP_transmit:begin
			finalfiforden<=1'b0;
			if(tcp_fifo_data_count[10:0] < 11'd1900)begin
				if(cnt_shift < 5'd22)begin
					tcp_fifo_data_in[7:0]<=finalfifodouthold[175:168];
					finalfifodouthold[175:0]<={finalfifodouthold[167:0],8'b0};
					cnt_shift<=cnt_shift+5'b1;
					tcp_fifo_wr_en	<= 1'b1;
					state_Final_to_TCP <= state_Final_to_TCP_transmit;
				end
				else begin
					cnt_shift<=0;
					finalfifodouthold[175:0]<=176'b0;
					tcp_fifo_wr_en	<= 1'b0;
					state_Final_to_TCP<=state_Final_to_TCP_idle;
				end
			end
			else begin
				cnt_shift<=cnt_shift;
				tcp_fifo_data_in[7:0]<=tcp_fifo_data_in[7:0];
				finalfifodouthold[175:0]<=finalfifodouthold[175:0];
				tcp_fifo_wr_en	<= 1'b0;
				finalfiforden<=1'b0;
				state_Final_to_TCP <= state_Final_to_TCP_transmit;
			end
		end
		
		default: state_Final_to_TCP<=state_Final_to_TCP_idle;
	endcase
end
else begin
	case (state1)

	  state1_idle:begin
	  datafiford_en<=1'b0;
	  tcp_fifo_wr_en<=1'b0;
	  tcp_fifo_data_in[7:0]<=8'b0;
	  if((~datafifo_empty)&&(tcp_fifo_data_count<=11'd1024))begin
	  datafifo_outhold[279:0]<=datafifo_out[279:0];
	  datafiford_en<=1'b1;
	  state1<=state1_s0;
	  end
	  else state1<=state1_idle;
	  end
	  
	  state1_s0:begin
	  datafiford_en<=1'b0;
			if(cnt_shiftfifo<6'd35)begin
			tcp_fifo_data_in[7:0]<=datafifo_outhold[279:272];
			tcp_fifo_wr_en<=1'b1;
			datafifo_outhold[279:0]<={datafifo_outhold[271:0],8'b0};
			cnt_shiftfifo<=cnt_shiftfifo+5'b1;
			state1<=state1_s0;
			end
			else begin
			tcp_fifo_wr_en<=1'b0;
			tcp_fifo_data_in[7:0]<=8'b0;
			cnt_shiftfifo<=0;
			state1<=state1_idle;
			end 
		end
	
		default:state1<=state1_idle;
		endcase
	end
end
end	

//------------------------------------------------------------------------------//
//------------------------------------------------------------------------------//
fifo_befor5402 fifo2048x8 (
  .clk(clk_125M), // input clk
  .srst(wire_RST_forfifo), // input srst
  .din(tcp_fifo_data_in[7:0]), // input [7 : 0] din
  .wr_en(tcp_fifo_wr_en &&(~tcp_fifo_full)), // input wr_en
  .rd_en(tcp_fifo_rd_en), // input rd_en
  .dout(tcp_fifo_data_out[7:0]), // output [7 : 0] dout
  .full(tcp_fifo_full), // output full
  .almost_full(almost_full), // output almost_full
  .empty(tcp_fifo_empty), // output empty
  .data_count(tcp_fifo_data_count[10:0]), // output [10 : 0] data_count
  .prog_full(tcp_prog_full) // output prog_full
);

always@(posedge clk_125M)begin
if(~rst )begin
		datatoWR				<=	8'b0;
		datatoWRvalid		<=	1'b0;
		tcp_fifo_rd_en 	<= 1'b0;
		cnt_for1460  		<= 12'b0;
		newfifocounter 	<= 8'b0;
		state_before5402	<=	state_before5402_idle;
end
else begin
		case (state_before5402)
			state_before5402_idle: begin	
				datatoWR				<=	8'b0;
				datatoWRvalid		<=	1'b0;
				cnt_for1460  	<= 12'b0;
				if(TCP_TX_CTS &&  (~tcp_fifo_empty))begin
					tcp_fifo_rd_en    <= 1'b1;
					state_before5402	<=	state_before5402_ready;
				end
				else
					state_before5402	<=	state_before5402_idle;
			end
			
			state_before5402_ready:begin
				if(tcp_fifo_rd_en)begin
					state_before5402	<=	state_before5402_normal;
				end
			end
				
			state_before5402_normal:begin				
				datatoWR[7:0] <= tcp_fifo_data_out[7:0];
				datatoWRvalid <= 1'b1;
				cnt_for1460 <= cnt_for1460+1'b1;
				if(tcp_fifo_empty)begin
					datatoWR[7:0] <= tcp_fifo_data_out[7:0];
					datatoWRvalid <= 1'b1;
					cnt_for1460  	<= 12'b0;
					tcp_fifo_rd_en <= 1'b0;
					state_before5402	<=	state_before5402_idle;
				end
				else if((cnt_for1460 == 12'd21)||(~TCP_TX_CTS))begin
					datatoWR[7:0] <= tcp_fifo_data_out[7:0];
					datatoWRvalid <= 1'b1;
					cnt_for1460  	<= 12'b0;
					tcp_fifo_rd_en <= 1'b0;
					state_before5402 <= state_before5402_wait;
				end 
				else state_before5402 <= state_before5402_normal;
			end
			
			state_before5402_wait: begin
				if(newfifocounter==8'd125)begin
					datatoWRvalid		<=		1'b0;
					newfifocounter		<=		8'b0;
					if(~TCP_TX_CTS)
					state_before5402	<=	state_before5402_wait;
					else begin 
						tcp_fifo_rd_en    <= 1'b1;
						state_before5402	<=	state_before5402_normal;
					end
				end
				else begin
					datatoWR[7:0]		<=		datatoWR[7:0];
					datatoWRvalid		<=		1'b0;
					newfifocounter		<=		newfifocounter+1'b1;
					state_before5402	<=		state_before5402_wait;
				end				
			end
			
			default:state_before5402 <=	state_before5402_idle;
		endcase
	end
end
endmodule
