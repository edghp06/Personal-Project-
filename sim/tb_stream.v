`timescale 1ns/1ps

module tb_stream;

    localparam integer CLK_HZ = 10_000_000;
    localparam integer BAUD   = 115_200;
    localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;
    localparam integer NSAMP  = 256;

    reg clk = 0;
    always #50 clk = ~clk; // 10 MHz

    reg rst = 1;

    reg uart_rx_i = 1'b1;
    wire uart_tx_o;

    reg        sample_wr_en = 0;
    reg [15:0] sample_wr_data = 16'd0;

    top_fpga_dsp dut (
    .clk(clk),
    .rst(rst),
    .uart_rx_i(uart_rx_i),
    .uart_tx_o(uart_tx_o),
    .sample_wr_en(sample_wr_en),
    .sample_wr_data(sample_wr_data)
    );

    initial begin
        $dumpfile("sim/wave.vcd");
        $dumpvars(0, tb_stream);
    end

    integer fd;
    initial begin
        fd = $fopen("sim/stream_bytes.hex", "w");
    end

    // ---- simple sample fill ----
    integer i;
    initial begin
        #500;
        rst = 0;

        for (i = 0; i < NSAMP; i = i + 1) begin
            @(posedge clk);
            sample_wr_en   = 1'b1;
            sample_wr_data = 16'h1000 + i[15:0];
        end
        @(posedge clk);
        sample_wr_en = 1'b0;

        // wait long enough for streaming to finish
        #5_000_000;
        $finish;
    end

endmodule
