module ft245_async_fifo #(
    parameter read_depth=3,
    parameter write_depth=3,
    parameter same_clocks=0
    )
    (
    /* external connections */
    inout [7:0] D,  /* bi-directional data */
    input RXFn,     /* receive full (data to receive) - active low */
    input TXEn,     /* transmit empty (data can be sent) - active low */
    output reg RDn, /* read data from fifo - active low */
    output reg WRn, /* write data to fifo - active low */
    /* internal connections */
    input clk_50mhz,
    input rw_clk,
    input rd_en,
    output [7:0] rd_data,
    output rd_empty,
    input wr_en,
    input [7:0] wr_data,
    output wr_full
    );

    /* read internal fifo */
    wire read_full;
    reg read_wr_en=1'b0;
    if(same_clocks)
        fifo #(.data_width(8), .depth_width(read_depth)) read_fifo
                    (.clk(clk_50mhz), .reset(1'b0),
                     .rd_en(rd_en), .rd_data(rd_data),
                     .wr_en(read_wr_en), .wr_data(D),
                     .full(read_full), .empty(rd_empty));
    else
        async_fifo #(.data_width(8), .depth_width(read_depth)) read_fifo
                    (.reset(1'b0),
                     .rd_clk(rw_clk), .rd_en(rd_en), .rd_data(rd_data),
                     .wr_clk(clk_50mhz), .wr_en(read_wr_en), .wr_data(D),
                     .full(read_full), .empty(rd_empty));

    /* write internal fifo */
    wire write_empty;
    reg write_rd_en=0;
    wire [7:0] D_out;
    if(same_clocks)
        fifo #(.data_width(8), .depth_width(write_depth)) write_fifo
                   (.clk(clk_50mhz), .reset(1'b0),
                    .rd_en(write_rd_en), .rd_data(D_out),
                    .wr_en(wr_en), .wr_data(wr_data),
                    .full(wr_full), .empty(write_empty));
    else
        async_fifo #(.data_width(8), .depth_width(write_depth)) write_fifo
                    (.reset(1'b0),
                     .rd_clk(clk_50mhz), .rd_en(write_rd_en), .rd_data(D_out),
                     .wr_clk(rw_clk), .wr_en(wr_en), .wr_data(wr_data),
                     .full(wr_full), .empty(write_empty));

    assign D=(WR_delay || !WRn)?D_out:8'hz;

    /* write line, delayed by half a clock to meet specification */
    reg WR=1'b0, WR_delay=1'b0;
    always @(posedge clk_50mhz) WR_delay<=WR;
    always @(negedge clk_50mhz) WRn<=!WR_delay;

    /* synchronisers for RXFn and TXEn */
    wire RXFn_sync, TXEn_sync;
    synchroniser #(.width(1), .depth(2), .init_high(1))
                sync_rxfn(.clk(clk_50mhz), .signal(RXFn), .sync_signal(RXFn_sync));
    synchroniser #(.width(1), .depth(2), .init_high(1))
                sync_txen(.clk(clk_50mhz), .signal(TXEn), .sync_signal(TXEn_sync));

    /* register used to keep track of the number of clocks that need to be waited for,
     * before we can return to idle - this is due to the synchronisers */
    reg [1:0] wait_clocks;

    /* state machine */
    localparam STATE_IDLE=2'h0, STATE_READ=2'h1, STATE_WRITE=2'h2, STATE_COMPLETE=2'h3;
    reg [1:0] state=STATE_IDLE;
    always @(posedge clk_50mhz)
    begin
        case(state)
        STATE_IDLE:
        begin
            /* check for reading first */
            if((!read_full)&&(!RXFn_sync)) /* internal not full, external has data */
            begin
                if(WRn)
                begin
                    state <= STATE_READ;
                    RDn <= 1'b0; /* drive read line low */
                    write_rd_en <= 1'b0; /* disable write */
                end
            end
            /* check for writing */
            else if((!write_empty)&&(!TXEn_sync)) /* internal not empty, external ready to receive */
            begin
                state <= STATE_WRITE;
                RDn <= 1'b1; /* ensure read line is high */
                write_rd_en <= 1'b1; /* enable write to external fifo */
                WR <= 1'b1;
            end
            else
            begin
                /* disable read and write */
                RDn <= 1'b1;
                write_rd_en <= 1'b0;
            end
        end
        STATE_READ:
        begin
            /* read data into internal fifo */
            read_wr_en <= 1'b1;
            wait_clocks <= 2'd2;
            state <= STATE_COMPLETE;
        end
        STATE_WRITE:
        begin
            write_rd_en <= 1'b0; /* disable write */
            wait_clocks <= 2'd2;
            state <= STATE_COMPLETE;
        end
        STATE_COMPLETE:
        begin
            /* at this point the data should have been successfully written into the external fifo */
            WR <= 1'b0;
            RDn <= 1'b1; /* return read line high */
            read_wr_en <= 1'b0;

            /* check if we need to wait, otherwise go to the next state */
            if(wait_clocks)
                wait_clocks <= wait_clocks - 1'b1;
            else
                state <= STATE_IDLE;
        end
        endcase
    end

endmodule

