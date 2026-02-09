`timescale 1ns/1ps

module tb_sample_buffer;

    reg clk = 0;
    always #5 clk = ~clk;

    reg rst;
    reg sample_valid;
    reg [15:0] sample_in;
    reg [7:0] read_addr;
    wire [15:0] sample_out;

    sample_buffer dut (
        .clk(clk),
        .rst(rst),
        .sample_valid(sample_valid),
        .sample_in(sample_in),
        .read_addr(read_addr),
        .sample_out(sample_out)
    );

    integer i;

    initial begin
        $dumpfile("tb_sample_buffer.vcd");
        $dumpvars(0, tb_sample_buffer);

        rst = 1;
        sample_valid = 0;
        sample_in = 0;
        read_addr = 0;

        repeat (3) @(posedge clk);
        rst = 0;

        // Write MORE than 256 samples
        for (i = 0; i < 270; i = i + 1) begin
            @(posedge clk);
            sample_valid = 1;
            sample_in = i;
        end

        sample_valid = 0;

        // Read back a few locations
        @(posedge clk); read_addr = 8'd0;
        @(posedge clk); read_addr = 8'd1;
        @(posedge clk); read_addr = 8'd2;

        #50;
        $finish;
    end

endmodule
