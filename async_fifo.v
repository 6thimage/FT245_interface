module async_fifo #(
    parameter data_width=8,
    parameter depth_width=5
    )
    (
    input reset,
    /* read */
    input rd_clk,
    input rd_en,
    output reg [data_width-1:0] rd_data,
    /* write */
    input wr_clk,
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
    /* binary to gray conversion */
    wire [head_width:0] rd_head_gray, wr_head_gray;
    assign rd_head_gray=binary_to_gray(rd_head);
    assign wr_head_gray=binary_to_gray(wr_head);
    /* synchronisers */
    wire [head_width:0] rd_head_sync_gray, wr_head_sync_gray;
    synchroniser #(.width(head_width+1), .depth(3)) rd_head_wr_clk(.clk(wr_clk), .signal(rd_head_gray), .sync_signal(rd_head_sync_gray));
    synchroniser #(.width(head_width+1), .depth(3)) wr_head_rd_clk(.clk(rd_clk), .signal(wr_head_gray), .sync_signal(wr_head_sync_gray));
    /* gray to binary conversion */
    wire [head_width:0] rd_head_sync, wr_head_sync;
    assign rd_head_sync=gray_to_binary(rd_head_sync_gray);
    assign wr_head_sync=gray_to_binary(wr_head_sync_gray);

    /* fifo state */
    assign empty=reset?1'h0:(rd_head==wr_head_sync);
    assign full=reset?1'h0:((rd_head_sync[head_width-1:0]==wr_head[head_width-1:0])&&(rd_head_sync[head_width]!=wr_head[head_width]));

    /* write */
    always @(posedge wr_clk)
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
    always @(posedge rd_clk)
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

    function [head_width:0] binary_to_gray(input [head_width:0] binary);
        integer i;
        begin
            for(i=0; i<head_width; i=i+1)
                binary_to_gray[i] = binary[i+1] ^ binary[i];
            binary_to_gray[head_width] = binary[head_width];
        end
    endfunction

    function [head_width:0] gray_to_binary(input [head_width:0] gray);
        integer i;
        begin
            gray_to_binary[head_width] = gray[head_width];
            for(i=(head_width-1); i>=0; i=i-1)
                gray_to_binary[i] = gray_to_binary[i+1] ^ gray[i];
        end
    endfunction

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

