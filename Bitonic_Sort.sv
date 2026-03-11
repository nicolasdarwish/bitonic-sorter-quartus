// Modular Bitonic Sort Implementation for 8 Elements
// Top Module: BitonicSorter
// Submodules: BitonicSortStage, BitonicMergeStage

module Bitonic_Sort #(
    parameter BITWIDTH = 16,
    parameter ELEMENTS = 8
)(
    input logic clk,
    input logic rst_n,
    input logic enable,
    input logic [ELEMENTS*BITWIDTH-1:0] input_data,
    output logic done_Sort,
    output logic [ELEMENTS*BITWIDTH-1:0] out_data
);

    typedef enum logic [2:0] { IDLE, LOAD, SORT, MERGE, DONE } state_t;
    state_t state;

    logic [BITWIDTH-1:0] buffer [0:ELEMENTS-1];
    logic [BITWIDTH-1:0] sort_out [0:ELEMENTS-1];
    logic [BITWIDTH-1:0] merge_out [0:ELEMENTS-1];
    logic sort_done, merge_done;
    logic start_sort, start_merge;

    BitonicSortStage #(.BITWIDTH(BITWIDTH), .ELEMENTS(ELEMENTS)) sort_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_sort),
        .input_data(buffer),
        .done(sort_done),
        .out_data(sort_out)
    );

    BitonicMergeStage #(.BITWIDTH(BITWIDTH), .ELEMENTS(ELEMENTS)) merge_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_merge),
        .input_data(sort_out),
        .done(merge_done),
        .out_data(merge_out)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done_Sort <= 0;
            start_sort <= 0;
            start_merge <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done_Sort <= 0;
                    if (enable) begin
                        for (int i = 0; i < ELEMENTS; i++)
                            buffer[i] <= input_data[i*BITWIDTH +: BITWIDTH];
                        start_sort <= 1;
                        state <= SORT;
                    end
                end

                SORT: begin
                    start_sort <= 0;
                    if (sort_done) begin
                        start_merge <= 1;
                        state <= MERGE;
                    end
                end

                MERGE: begin
                    start_merge <= 0;
                    if (merge_done) begin
                        for (int i = 0; i < ELEMENTS; i++)
                            out_data[i*BITWIDTH +: BITWIDTH] <= merge_out[i];
                        done_Sort <= 1;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule

module BitonicSortStage #(
    parameter BITWIDTH = 16,
    parameter ELEMENTS = 8
)(
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic [BITWIDTH-1:0] input_data [0:ELEMENTS-1],
    output logic done,
    output logic [BITWIDTH-1:0] out_data [0:ELEMENTS-1]
);
    logic [2:0] phase;
    logic [BITWIDTH-1:0] data [0:ELEMENTS-1];

    function void compare_swap(
        inout logic [BITWIDTH-1:0] a,
        inout logic [BITWIDTH-1:0] b
    );
        logic [BITWIDTH-1:0] temp;
        if (a > b) begin
            temp = a;
            a = b;
            b = temp;
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < ELEMENTS; i++) data[i] <= 0;
            phase <= 0;
            done <= 0;
        end else begin
            if (start) begin
                case (phase)
                    0: begin
                        for (int i = 0; i < ELEMENTS; i++)
                            data[i] <= input_data[i];
                        phase <= 1;
                    end
                    1: begin
                        for (int i = 0; i < ELEMENTS/2; i++)
                            compare_swap(data[i], data[i+ELEMENTS/2]);
                        phase <= 2;
                    end
                    2: begin
                        for (int i = 0; i < ELEMENTS; i++)
                            compare_swap(data[i^(1)], data[i]);
                        phase <= 3;
                    end
                    3: begin
                        for (int i = 0; i < ELEMENTS; i++)
                            out_data[i] <= data[i];
                        done <= 1;
                    end
                endcase
            end else begin
                done <= 0;
            end
        end
    end
endmodule

module BitonicMergeStage #(
    parameter BITWIDTH = 16,
    parameter ELEMENTS = 8
)(
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic [BITWIDTH-1:0] input_data [0:ELEMENTS-1],
    output logic done,
    output logic [BITWIDTH-1:0] out_data [0:ELEMENTS-1]
);
    logic [2:0] stage;
    logic [BITWIDTH-1:0] data [0:ELEMENTS-1];

    function void compare_swap(
        inout logic [BITWIDTH-1:0] a,
        inout logic [BITWIDTH-1:0] b
    );
        logic [BITWIDTH-1:0] temp;
        if (a > b) begin
            temp = a;
            a = b;
            b = temp;
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < ELEMENTS; i++) data[i] <= 0;
            stage <= 0;
            done <= 0;
        end else begin
            if (start) begin
                case (stage)
                    0: begin
                        for (int i = 0; i < ELEMENTS; i++)
                            data[i] <= input_data[i];
                        stage <= 1;
                    end
                    1: begin
                        compare_swap(data[0], data[1]);
                        compare_swap(data[2], data[3]);
                        compare_swap(data[4], data[5]);
                        compare_swap(data[6], data[7]);
                        stage <= 2;
                    end
                    2: begin
                        compare_swap(data[0], data[2]);
                        compare_swap(data[1], data[3]);
                        compare_swap(data[4], data[6]);
                        compare_swap(data[5], data[7]);
                        stage <= 3;
                    end
                    3: begin
                        compare_swap(data[0], data[4]);
                        compare_swap(data[1], data[5]);
                        compare_swap(data[2], data[6]);
                        compare_swap(data[3], data[7]);
                        stage <= 4;
                    end
                    4: begin
                        for (int i = 0; i < ELEMENTS; i++)
                            out_data[i] <= data[i];
                        done <= 1;
                    end
                endcase
            end else begin
                done <= 0;
            end
        end
    end
endmodule
