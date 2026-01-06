// rtl/fx_mul_q15.v
// Fixed-point multiplier: Q1.15 × Q1.15 → Q1.15
// Signed arithmetic, truncation scaling

module fx_mul_q15 (
    input  wire signed [15:0] a_q15,
    input  wire signed [15:0] b_q15,
    output wire signed [15:0] y_q15
);

    // Full precision product: Q2.30
    wire signed [31:0] prod_q30;

    assign prod_q30 = a_q15 * b_q15;

    // Scale back to Q1.15 by right shift
    // Take bits [30:15]
    assign y_q15 = prod_q30[30:15];

endmodule
