`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/20 09:06:03
// Design Name: 
// Module Name: ahb2apb_tb
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




module ahb2apb_tb (
    
);

    parameter AHB_DATA_WIDTH  = 32;
    parameter AHB_ADDR_WIDTH  = 32;
    parameter APB_DATA_WIDTH  = 32;
    parameter APB_ADDR_WIDTH  = 32;
    
    reg                         ahb_hclk   ;
    reg                         ahb_hrstn  ;
    reg                         ahb_hsel   ;
    reg  [1:0]                  ahb_htrans ;
    reg  [AHB_ADDR_WIDTH-1:0]   ahb_haddr  ;
    reg  [AHB_DATA_WIDTH-1:0]   ahb_hwdata ;
    reg                         ahb_hwrite ;
    wire                        ahb_hready ;	
    wire [AHB_DATA_WIDTH-1:0]   ahb_hrdata ;
    reg                         apb_pclk   ;
    reg                         apb_prstn  ;
    wire                        apb_psel   ;
    wire                        apb_pwrite ;
    wire                        apb_penable;
    wire [APB_ADDR_WIDTH-1:0]   apb_paddr  ;
    wire [APB_DATA_WIDTH-1:0]   apb_pwdata ;
    reg                         apb_pready ;
    reg  [APB_DATA_WIDTH-1:0]   apb_prdata ;
    
    
    ahb2apb inst_ahb2apb(
		.ahb_hclk       (ahb_hclk   ),
		.ahb_hrstn      (ahb_hrstn  ),
		.ahb_hsel       (ahb_hsel   ),
		.ahb_htrans     (ahb_htrans ),
		.ahb_haddr      (ahb_haddr  ),
		.ahb_hwdata     (ahb_hwdata ),
		.ahb_hwrite     (ahb_hwrite ),
		.ahb_hready     (ahb_hready ),	
		.ahb_hrdata     (ahb_hrdata ),
		.apb_pclk       (apb_pclk   ),
		.apb_prstn      (apb_prstn  ),
		.apb_psel       (apb_psel   ),
		.apb_pwrite     (apb_pwrite ),
		.apb_penable    (apb_penable),
		.apb_paddr      (apb_paddr  ),
		.apb_pwdata     (apb_pwdata ),
		.apb_pready     (apb_pready ),
		.apb_prdata     (apb_prdata )
	);


    always #3 ahb_hclk = ~ahb_hclk;
    always #5 apb_pclk = ~apb_pclk;

    initial begin
        ahb_hclk        = 1'b0;
        ahb_hrstn       = 1'b0;
        ahb_hsel        = 1'b0;
        ahb_htrans      = 2'd0;
        ahb_haddr       = 32'd0;
        ahb_hwdata      = 32'd0;
        ahb_hwrite      = 1'b0;
        apb_pclk        = 1'b0;
        apb_prstn       = 1'b0;
        apb_pready      = 1'b0;
        apb_prdata      = 32'd0;
    end

    initial begin
        #30;
        ahb_hrstn = 1'b1;
        apb_prstn = 1'b1;
        #30;
        ahb_write(32'd1314,32'd1016);
        //ahb_read(32'd1016);
        #100;
        $finish;
    end


    //task define
    task ahb_write;
    input [31:0] write_data;
    input [31:0] write_addr;

        begin
            @(posedge ahb_hclk)begin
                ahb_hwrite <= 1'b1;
                ahb_hsel <= 1'b1;
                ahb_htrans <= 2'b10;
                ahb_haddr <=write_addr;
            end
            @(posedge ahb_hclk) begin
                ahb_hwdata <= write_data;
            end
            @(posedge apb_pclk) begin
                apb_pready <= 1'b1;
            end
        end 
    endtask
    
    
    task ahb_read;
    input [31:0] read_addr;
    
        begin
             @(posedge ahb_hclk)begin
                ahb_hwrite <= 1'b0;
                ahb_hsel <= 1'b1;
                ahb_htrans <= 2'b10;
                ahb_haddr <=read_addr;
            end
            @(posedge apb_pclk) begin
                apb_prdata <= 32'd1010;
            end
            @(posedge apb_pclk) begin
                apb_pready <= 1'b1;
            end            
                           
        end
    
    endtask




endmodule
