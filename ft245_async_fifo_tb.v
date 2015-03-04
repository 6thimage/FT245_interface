`timescale 1ns / 1ps

module ft245_async_fifo_tb;

	// Inputs
	reg RXFn;
	reg TXEn;
	reg clk;
	reg rd_en;
	reg wr_en;
	reg [7:0] wr_data;

	// Outputs
	wire RDn;
	wire WRn;
	wire [7:0] rd_data;
	wire rd_empty;
	wire wr_full;

	// Bidirs
	wire [7:0] D;

	// Instantiate the Unit Under Test (UUT)
	ft245_async_fifo #(.read_depth(3), .write_depth(3), .same_clocks(1)) uut (
		.D(D),
		.RXFn(RXFn),
		.TXEn(TXEn),
		.RDn(RDn),
		.WRn(WRn),
		.clk_50mhz(clk),
        .rw_clk(clk),
		.rd_en(rd_en),
		.rd_data(rd_data),
		.rd_empty(rd_empty),
		.wr_en(wr_en),
		.wr_data(wr_data),
		.wr_full(wr_full)
	);

    reg [7:0] D_in;
    wire [7:0] D_out;
    assign D=(~RDn&WRn)?D_in:'bz;
    assign D_out=(~WRn&RDn)?D:'bz;

    always #10 clk<=~clk;
	initial begin
		// Initialize Inputs
		RXFn = 1;
		TXEn = 1;
		clk = 1;
		rd_en = 0;
		wr_en = 0;
		wr_data = 0;

		// Wait 100 ns for global reset to finish
		#100;

		// Add stimulus here

        ///* data available at fifo */
        //RXFn = 0;
        //D_in = 1;
        //#40 D_in = 2;
        //#40 D_in = 3;
        //#40 D_in = 4;
        //#40 D_in = 5;
        //#40 D_in = 6;
        //#40 D_in = 7;
        //#40 D_in = 8;
        ///* enable reading */
        //rd_en = 1;
        //#40 D_in = 9;
        //#40 D_in = 10;
        //#40 D_in = 11;
        //#40 D_in = 12;
        //#40 RXFn = 1;
        //#400 rd_en = 0;
        //
        ///* transmit data */
        //wr_en = 1;
        //wr_data = 8'h10;
        //#20 wr_data = 8'h20;
        //#20 wr_data = 8'h30;
        //#20 wr_data = 8'h40;
        //#20 wr_data = 8'h50;
        //#20 wr_data = 8'h60;
        //#20 wr_data = 8'h70;
        //#20 wr_data = 8'h80;
        //#20 wr_en = 0;
        //
        //#400;
        //
        ///* short write test */
        //wr_en = 1;
        //wr_data = 1;
        //#20 wr_en = 0;
        //
        //#400;

        /* transmit data, with read being possible */
        //wr_en = 1;
        //wr_data = 8'h10;
        //#20 wr_data = 8'h20;
        //#20 wr_data = 8'h30;
        //#20 wr_data = 8'h40;
        //RXFn = 0;
        //D_in = 1;
        //#20 wr_data = 8'h50;
        //#20 wr_data = 8'h60;
        //D_in = 3;
        //#20 wr_data = 8'h70;
        //#20 wr_data = 8'h80;
        //RXFn = 1;
        //#20 wr_en = 0;
        //
        //#600;

        /* read test according to spec */
        RXFn = 0;
        D_in = 7;
        @(posedge RDn) #14 RXFn = 1;
        #6;

        #400;

        /* write test according to spec */
        wr_en = 1;
        wr_data = 8'h10;
        #20 wr_data = 8'h20;
        #20 wr_en = 0;
        #20 TXEn = 0;
        @(negedge WRn) #14 TXEn = 1;
        #49 TXEn = 0;

        #400;

        $finish;
	end

endmodule

