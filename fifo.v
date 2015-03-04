module fifo #(
    parameter data_width=8,
    parameter depth_width=5
    )
    (
    input clk,
    input reset,
    /* read */
    input rd_en,
    output reg [data_width-1:0] rd_data,
    /* write */
    input wr_en,
    input [data_width-1:0] wr_data,
    /* fifo */
    output full,
    output empty
    );

    /* fifo memory */
    (* RAM_STYLE="BLOCK" *)
    reg [data_width-1:0] memory[(1<<depth_width)-1:0];

    /* read and write heads */
    localparam head_width = log2(1<<depth_width);
    reg [head_width:0] rd_head='h0, wr_head='h0;

    /* fifo state
     *
     * The read and write heads are 1 bit larger than that needed to address the memory,
     * the top bit is used to indicate the sign of the head, so we can always tell where
     * the heads are relative to each other. Without this, both full and empty fifos would
     * look the same. The checking for full and empty, therefore, checks both the sign and
     * counter.
     */
    assign empty=reset?1'h0:(rd_head==wr_head);
    assign full=reset?1'h0:((rd_head[head_width-1:0]==wr_head[head_width-1:0])&&(rd_head[head_width]!=wr_head[head_width]));

    /* write */
    always @(posedge clk)
    begin
        if(reset)
            wr_head<=0;
        else if(wr_en && !full)
        begin
            /* write data to fifo */
            memory[wr_head[head_width-1:0]]<=wr_data;
            /* increment head */
            wr_head<=wr_head+1'b1;
        end
    end

    /* read */
    always @(posedge clk)
    begin
        if(reset)
            rd_head<=0;
        else if(rd_en && !empty)
        begin
            /* read data from fifo */
            rd_data<=memory[rd_head[head_width-1:0]];
            /* increment head */
            rd_head<=rd_head+1'b1;
        end
    end

    /* this function is only used during synthesis */
    function integer log2(input integer n);
        integer i;
        begin
            log2=1;
            for(i=0; 2**i<n; i=i+1)
                log2=i+1;
        end
    endfunction
endmodule

