module top_level_test #(parameter BITWIDTH = 16, parameter ELEMENTS = 16)(
    input  logic clk,
    input  logic rst_n,
    input  logic en_i,
    output logic done_o,
    input  logic [ELEMENTS*BITWIDTH-1:0] in,
    output logic [ELEMENTS*BITWIDTH-1:0] out
);

    // Instantiate the sorting module
    Bitonic_Sort4 #(
        .BITWIDTH(BITWIDTH),
        .ELEMENTS(ELEMENTS)
    ) sorter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en_i(en_i),
        .in(in),
        .done_o(done_o),
        .out(out)
    );
	 
//	     Bitonic_Sort2 #(
//        .BITWIDTH(BITWIDTH),
//        .ELEMENTS(ELEMENTS)
//    ) sorter_inst (
//        .clk(clk),
//        .rst_low(rst_n),
//        .enable(en_i),
//        .input_data(in),
//        .done_Sort(done_o),
//        .data_out(out)
//    );

endmodule

