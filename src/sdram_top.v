module sdram_top (
	input					sclk,
	input					srst_n,
	// SDRAM
	output	wire			sdram_clk,
	output	wire			sdram_cke,
	output	wire			sdram_cs_n,
	output	wire	[ 1:0]	sdram_bank,
	output	reg		[11:0]	sdram_addr,
	output	wire			sdram_ras_n,
	output	wire			sdram_cas_n,
	output	wire			sdram_we_n,
	output	wire	[ 1:0]	sdram_dqm,
	inout			[15:0]	sdram_dq,
    // Test
    input   wire            wr_trig,
    input   wire    [ 7:0]  wr_len,
    input   wire    [15:0]  wr_data,
    input   wire    [20:0]  wr_addr,
    output 	wire            wr_data_en
);
/****************************************
* Parameter and Internal Signals
****************************************/
// state
localparam	S_IDLE	=	4'b0001;
localparam	S_ARBIT	=	4'b0010;
localparam	S_AREF	=	4'b0100;
localparam  S_WRITE =   4'b1000;

reg		[ 3:0]			state;

reg		[ 3:0]			sdram_cmd;
// SDRAM init
wire					flag_init_end;
wire	[ 3:0]			init_cmd;
wire	[11:0]			init_addr;
// SDRAM auto refresh
wire					aref_en;
wire					flag_aref_ask;
wire					flag_aref_end;
wire	[ 3:0]			aref_cmd;
wire	[11:0]			aref_addr;
// SDRAM write
wire                    wr_en;
wire 	                flag_wr_ask;
wire 	                flag_wr_end;

wire    [3:0]	        write_cmd;
wire    [11:0]	        write_addr;
wire    [1:0]	        write_bank;
wire    [15:0]	        write_data;

/***************************************
* Main Code
***************************************/
assign	sdram_clk	=	~sclk;		// ？
assign	sdram_cke	=	1'b1;
assign	sdram_dqm	=	2'b00;		// 令DQ无效

assign	{sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n}	=	sdram_cmd;
assign  sdram_dq    =   (state == S_WRITE) ? write_data : {24{1'bz}};
assign  sdram_bank  =   2'd0;

always @(posedge sclk or negedge srst_n) begin
	if (!srst_n)
		state <= S_IDLE;
	else case (state)
		S_IDLE:     state <= flag_init_end ? S_ARBIT : S_IDLE;
		S_ARBIT:    begin
            if (flag_aref_ask)
                state <= S_AREF;
            else if (flag_wr_ask)
                state <= S_WRITE;
            else
                state <= S_ARBIT;
        end
		S_AREF:     state <= flag_aref_end ? S_ARBIT : S_AREF;
        S_WRITE:    state <= flag_wr_end ? S_ARBIT : S_WRITE;
		default:    state <= state;
	endcase
end

always @(*) begin
	case (state)
		S_IDLE: begin
			sdram_cmd 	=	init_cmd;
			sdram_addr	=	init_addr;
		end
		S_AREF: begin
			sdram_cmd 	=	aref_cmd;
			sdram_addr	=	aref_addr;
		end
        S_WRITE: begin
            sdram_cmd   =   write_cmd;
            sdram_addr  =   write_addr;
        end
		default: begin
			sdram_cmd 	=	4'b0111;
			sdram_addr	=	'd0;
		end
	endcase
end

assign	aref_en		=	state == S_AREF;
assign  wr_en       =   flag_aref_ask ? 1'b0 : (state == S_WRITE);

sdram_init	sdram_init_inst(
	.sclk				(sclk			),
	.rstn				(srst_n			),
	.cmd_reg			(init_cmd		),
	.sdram_addr			(init_addr		),
	.flag_init_end		(flag_init_end	)
);

sdram_aref sdram_aref_inst(
	.sclk          		(sclk          	),
	.srst_n        		(srst_n        	),
	.aref_en       		(aref_en       	),
	.sdram_cmd     		(aref_cmd     	),
	.sdram_addr    		(aref_addr    	),
	.flag_aref_ask 		(flag_aref_ask 	),
	.flag_aref_end 		(flag_aref_end 	)
);

sdram_write sdram_write_inst(
	.sclk        		(sclk        	),
	.srst_n      		(srst_n      	),
	.wr_en       		(wr_en       	),
	.flag_wr_ask 		(flag_wr_ask 	),
	.flag_wr_end 		(flag_wr_end 	),
	.wr_trig     		(wr_trig     	),
	.wr_len      		(wr_len      	),
	.wr_data     		(wr_data     	),
	.wr_addr     		(wr_addr     	),
	.wr_data_en  		(wr_data_en  	),
	.sdram_cmd   		(write_cmd   	),
	.sdram_addr  		(write_addr  	),
	.sdram_bank  		(write_bank  	),
	.sdram_data  		(write_data  	)
);

endmodule
