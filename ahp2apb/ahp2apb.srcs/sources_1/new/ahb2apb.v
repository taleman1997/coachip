`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/19 22:30:20
// Design Name: 
// Module Name: ahb2apb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ahb2apb #(
		parameter AHB_DATA_WIDTH  = 32,
		parameter AHB_ADDR_WIDTH  = 32,
		parameter APB_DATA_WIDTH  = 32,
		parameter APB_ADDR_WIDTH  = 32
		)(
		//AHB BUS
		input                       ahb_hclk   ,
		input                       ahb_hrstn  ,
		input                       ahb_hsel   ,
		input  [1:0]                ahb_htrans ,
		input  [AHB_ADDR_WIDTH-1:0] ahb_haddr  ,
		input  [AHB_DATA_WIDTH-1:0] ahb_hwdata ,
		input                       ahb_hwrite ,
		output                      ahb_hready ,	//set high as default
		output [AHB_DATA_WIDTH-1:0] ahb_hrdata ,
		//APB BUS
		input                       apb_pclk   ,
		input                       apb_prstn  ,
		output                      apb_psel   ,
		output                      apb_pwrite ,
		output reg                  apb_penable,
		output [APB_ADDR_WIDTH-1:0] apb_paddr  ,
		output [APB_DATA_WIDTH-1:0] apb_pwdata  ,
		input                       apb_pready ,
		input  [APB_DATA_WIDTH-1:0] apb_prdata 
	);

	//define the parameter for fifo instination
	localparam FIFO_DEPTH = 4;
	localparam FIFO_AFULL = FIFO_DEPTH - 1;
	localparam FIFO_AEMPTY = 1;
	localparam FIFO_CMD_DATA_WIDTH = AHB_DATA_WIDTH + AHB_ADDR_WIDTH + 1'b1;
	localparam FIFO_READ_DATA_WIDTH = APB_DATA_WIDTH;


	wire ahb_write_enable;
	wire ahb_read_enable ;

	wire fifo_cmd_write_enable;
	wire fifo_cmd_read_enable;

	wire [FIFO_CMD_DATA_WIDTH - 1 : 0] fifo_cmd_write_data;
	wire [FIFO_CMD_DATA_WIDTH - 1 : 0] fifo_cmd_read_data;

	wire fifo_data_write_enable;
	wire fifo_data_read_enable;

	wire [FIFO_READ_DATA_WIDTH - 1 : 0] fifo_data_write_data;
	wire [FIFO_READ_DATA_WIDTH - 1 : 0] fifo_data_read_data;


	wire fifo_cmd_afull;
	wire fifo_cmd_full;
	wire fifo_cmd_empty;
	wire fifo_cmd_aempty;

	wire fifo_data_afull;
	wire fifo_data_full;
	wire fifo_data_empty;
	wire fifo_data_aempty;

	reg 							ahb_write_enable_delay;
	reg 							ahb_read_enable_delay;
	reg [AHB_ADDR_WIDTH - 1 : 0] 	ahb_haddr_delay;

	// the enable signal here is combinational according to the address
	// ahb is a pipeline type protocal. The 
	assign ahb_write_enable = ahb_hsel && ahb_hwrite && ahb_htrans[1] && ahb_hready;

	assign ahb_read_enable  = ahb_hsel && !ahb_hwrite && ahb_htrans[1] && ahb_hready;

	assign fifo_cmd_write_enable = ahb_write_enable_delay || ahb_read_enable_delay;

	assign fifo_cmd_read_enable = !fifo_cmd_empty && apb_ready_to_update;		//read when the fifo is not empty and ap b finish transmit of last data.

	assign fifo_cmd_write_data = {ahb_write_enable_delay, ahb_haddr_delay, ahb_hwdata};

	assign fifo_data_write_enable = apb_penable && apb_pready;

	assign fifo_data_write_data = apb_prdata;

	assign fifo_data_read_enable = !fifo_data_empty;

	assign ahb_hready = ahb_write_ready && ahb_read_ready;


	// delay one clk cycle on addr(enable and addr, in the protocal, addr is before data one clk)
	// then we do this to make data and addr valid at the same clk cycle.
	// therefore, when the ahb_write_enable_delay is high we can write the data(data and addr are valid)
	// the enable signal here can be used in the fifo
	always @(posedge ahb_hclk or negedge ahb_hrstn) begin
		if(!ahb_hrstn)begin
			ahb_write_enable_delay <= 1'b0;
			ahb_read_enable_delay <= 1'b0;
			ahb_haddr_delay <= 32'd0;
		end

		else begin
			ahb_write_enable_delay <= ahb_write_enable;
			ahb_read_enable_delay <= ahb_read_enable;
			ahb_haddr_delay <= ahb_haddr;
		end
	end

	reg apb_ready_to_update;
	always @(posedge apb_pclk or negedge apb_prstn) begin
		if(!apb_prstn)
			apb_ready_to_update <= 1'b1;
		else if(apb_penable && apb_pready)
			apb_ready_to_update <= 1'b1;
		else if(fifo_cmd_read_enable)
			apb_ready_to_update <= 1'b0;
	end

	//apb output
	always @(posedge apb_pclk or negedge apb_prstn) begin
		if(!apb_prstn)
			apb_penable <= 1'b0;
		else if(apb_penable && apb_pready)
			apb_penable <= 1'b0;
		else if(apb_psel)
			apb_penable <= 1'b1;
	end

//	always @(posedge apb_pclk or negedge apb_prstn) begin
//		if(!apb_prstn)begin
//			apb_psel 	<= 1'b0;
//			apb_pwrite 	<= 1'b0;
//			apb_paddr 	<= 32'd0;
//			apb_pwdata 	<= 32'd0;
//		end
//		else if(fifo_cmd_read_enable)begin
//			apb_psel 	<= 1'b1;
//			apb_pwrite 	<= fifo_cmd_read_data[64];
//			apb_paddr 	<= fifo_cmd_read_data[63:32];
//			apb_pwdata 	<= fifo_cmd_read_data[31:0];
//		end
//	end

    assign apb_psel     = fifo_cmd_read_enable;
    assign apb_pwrite   = fifo_cmd_read_enable ? fifo_cmd_read_data[64] : 1'b0;
    assign apb_paddr    = fifo_cmd_read_enable ? fifo_cmd_read_data[63:32] : 32'd0;
    assign apb_pwdata   = fifo_cmd_read_enable ? fifo_cmd_read_data[31:0] : 32'd0;
    

	reg ahb_write_ready;
	reg ahb_read_ready;

	// or we can use wire ahb_write_ready
	//assign ahb_write_ready = ~fifo_cmd_full;
	always @(posedge ahb_hclk or negedge ahb_hrstn) begin
		if(!ahb_hrstn)
			ahb_write_ready <= 1'b1;
		else if(!fifo_cmd_afull)
			ahb_write_ready <= 1'b1;
		else
			ahb_write_ready <= 1'b0;
	end

	always @(posedge ahb_hclk or negedge ahb_hrstn) begin
		if(!ahb_hrstn)
			ahb_read_ready <= 1'b1;
		else if(fifo_data_read_enable)
			ahb_read_ready <= 1'b1;
		else if(ahb_read_enable) 
			ahb_read_ready <= 1'b0;
		else 
			ahb_read_ready <= 1'b1;
	end

	reg [AHB_DATA_WIDTH - 1 : 0] ahb_read_data_delay;
	always @(posedge ahb_hclk or negedge ahb_hrstn ) begin
		if(!ahb_hrstn)
			ahb_read_data_delay <= 32'd0;
		else 
			ahb_read_data_delay <= fifo_data_read_data;
	end

	assign ahb_hrdata = ahb_read_data_delay;



	//there are three parts need to write into the fifo(wr_flag, data, addr)
	// when fifo is full, then the ahb part can not receive a new data number.
	async_fifo #(
		.DATA_WIDTH 	(FIFO_CMD_DATA_WIDTH	),
		.FIFO_DEPTH 	 (FIFO_DEPTH				),
		.FIFO_ALMOST_FULL 	(FIFO_AFULL				),
		.FIFO_ALMOST_EMPTY	(FIFO_AEMPTY			)
	)async_fifo_cmd_inst(
		.write_clk			(ahb_hclk				),
		.write_rst_n		(ahb_hrstn				),
		.write_en			(fifo_cmd_write_enable	),
		.write_data		(fifo_cmd_write_data	),
		.read_clk			(apb_pclk				),
		.read_rst_n		(apb_prstn				),
		.read_en			(fifo_cmd_read_enable	),
		.read_data		(fifo_cmd_read_data		),
		.full			(fifo_cmd_full			),
		.almost_full			(fifo_cmd_afull			),
		.empty			(fifo_cmd_empty		),
		.almost_empty			(fifo_cmd_aempty			)
	);

	async_fifo #(
		.DATA_WIDTH 	(FIFO_READ_DATA_WIDTH	),
		.FIFO_DEPTH 	(FIFO_DEPTH				),
		.FIFO_ALMOST_FULL 	(FIFO_AFULL				),
		.FIFO_ALMOST_EMPTY	(FIFO_AEMPTY			)
	)async_fifo_read_inst(
		.write_clk			(apb_pclk				),
		.write_rst_n		(apb_prstn				),
		.write_en			(fifo_data_write_enable	),
		.write_data		(fifo_data_write_data	),
		.read_clk			(ahb_hclk				),
		.read_rst_n		(ahb_hrstn				),
		.read_en			(fifo_data_read_enable	),
		.read_data		(fifo_data_read_data	),
		.full			(fifo_data_full			),
		.almost_full			(fifo_data_afull		),
		.empty			(fifo_data_empty		),
		.almost_empty			(fifo_data_aempty		)
	);


endmodule
