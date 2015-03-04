module synchroniser #(
    parameter width=1,
    parameter depth=2,
    parameter init_high=0
    )
    (
    input clk,
    input [width-1:0] signal,
    output [width-1:0] sync_signal
    );

    reg [width-1:0] sync[depth-1:0];

    assign sync_signal=sync[depth-1];

    integer i;
    initial
    begin
        for(i=0; i<depth; i=i+1)
            sync[i]=(init_high)?{width{1'b1}}:'d0;
    end

    always @(posedge clk)
    begin
        sync[0] <= signal;
        for(i=1; i<depth; i=i+1)
            sync[i] <= sync[i-1];
    end

endmodule

