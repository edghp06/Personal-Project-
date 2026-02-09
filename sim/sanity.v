`timescale 1ns/1ps

module sanity;

    reg clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/sanity.vcd");
        $dumpvars(0, sanity);
        #100;
        $finish;
    end

endmodule
