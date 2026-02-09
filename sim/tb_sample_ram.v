`timescale 1ns/1ps

module tb_sample_ram;

    reg clk = 0;
    always #5 clk = ~clk;

    reg we;
    reg [7:0] waddr, raddr;
    reg [15:0] wdata;
    wire [15:0] rdata;

    sample_ram dut (
        .clk(clk),
        .we(we),
        .waddr(waddr),
        .wdata(wdata),
        .raddr(raddr),
        .rdata(rdata)
    );

    initial begin
        $dumpfile("tb_sample_ram.vcd");
        $dumpvars(0, tb_sample_ram);

        we = 0;
        waddr = 0;
        raddr = 0;
        wdata = 0;

        // write samples
        @(posedge clk);
        we = 1; waddr = 8'd0; wdata = 16'h1234;
        @(posedge clk);
        waddr = 8'd1; wdata = 16'h5678;
        @(posedge clk);
        we = 0;

        // read them back
        @(posedge clk);
        raddr = 8'd0;
        @(posedge clk);
        raddr = 8'd1;

        #50;
        $finish;
    end
endmodule
