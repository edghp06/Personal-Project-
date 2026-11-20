module clock_enable #(
    parameter DIVIDER = 50_000_000
)(
    input  wire clk,
    output reg  clk_en
);

    reg [$clog2(DIVIDER)-1:0] count = 0;

    always @(posedge clk) begin
        if (count == DIVIDER - 1) begin
            count  <= 0;
            clk_en <= 1'b1;   // one-cycle enable pulse
        end else begin
            count  <= count + 1;
            clk_en <= 1'b0;
        end
    end

endmodule