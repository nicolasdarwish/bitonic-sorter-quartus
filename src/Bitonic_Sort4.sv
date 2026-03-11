// Bitonic Sort Scalable - Fully Pipelined Sort & Merge for ELEMENTS (Default 64), Based on Original Verilog GitHub Version
module Bitonic_Sort4 #(parameter BITWIDTH = 16, parameter ELEMENTS = 16)(
    input logic clk,
    input logic rst_n,
    input logic en_i,
    input logic [ELEMENTS*BITWIDTH-1:0] in,
    output logic done_o,
    output logic [ELEMENTS*BITWIDTH-1:0] out
);

    typedef enum logic [2:0] {
        START = 3'd0,
        SETUP = 3'd1,
        SORT = 3'd2,
        MERGE_SETUP = 3'd3,
        MERGE = 3'd4,
        DONE = 3'd5,
        IDLE = 3'd7
    } state_t;

    state_t state;

    logic [BITWIDTH-1:0] d[0:7];
    logic [2:0] step;
    logic [$clog2(ELEMENTS)-1:0] stage;

    logic [$clog2(ELEMENTS):0] compare;
    logic [$clog2(ELEMENTS)-1:0] i_MERGE;
    logic [$clog2(ELEMENTS)-1:0] sum;
    logic [$clog2(ELEMENTS)-1:0] sum_max;
    logic [$clog2(ELEMENTS):0] STAGES = ELEMENTS/16;
    logic [$clog2(ELEMENTS):0] STAGES_FIXED = ELEMENTS/16;
    logic positive;
    logic [BITWIDTH-1:0] t;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= '0;
            step <= 0;
            done_o <= 0;
            state <= START;
            stage <= 0;
        end else begin
            case (state)
                START: begin
                    step <= 0;
                    done_o <= 0;
                    compare <= ELEMENTS;
                    i_MERGE <= 0;
                    positive <= 1;
                    sum <= 8;
                    sum_max <= 8;
                    out <= in;
                    if (en_i) begin
                        state <= SETUP;
                        stage <= 0;
                    end
                end

                SETUP: begin
                    if (stage <= (ELEMENTS/8)) begin
                        for (int k = 0; k < 8; k++) begin
                            d[k] <= in[stage*8*BITWIDTH + k*BITWIDTH +: BITWIDTH];
                        end
                        state <= SORT;
                    end else begin
                        state <= START;
                    end
                end

                SORT: begin
                    case (step)
                        0: begin
                            if (d[0] > d[1]) begin t = d[0]; d[0] = d[1]; d[1] = t; end
                            if (d[2] < d[3]) begin t = d[2]; d[2] = d[3]; d[3] = t; end
                            if (d[4] > d[5]) begin t = d[4]; d[4] = d[5]; d[5] = t; end
                            if (d[6] < d[7]) begin t = d[6]; d[6] = d[7]; d[7] = t; end
                            step <= step + 1;
                        end
                        1: begin
                            if (d[0] > d[2]) begin t = d[0]; d[0] = d[2]; d[2] = t; end
                            if (d[1] > d[3]) begin t = d[1]; d[1] = d[3]; d[3] = t; end
                            if (d[4] < d[6]) begin t = d[4]; d[4] = d[6]; d[6] = t; end
                            if (d[5] < d[7]) begin t = d[5]; d[5] = d[7]; d[7] = t; end
                            step <= step + 1;
                        end
                        2: begin
                            if (d[0] > d[1]) begin t = d[0]; d[0] = d[1]; d[1] = t; end
                            if (d[2] > d[3]) begin t = d[2]; d[2] = d[3]; d[3] = t; end
                            if (d[4] < d[5]) begin t = d[4]; d[4] = d[5]; d[5] = t; end
                            if (d[6] < d[7]) begin t = d[6]; d[6] = d[7]; d[7] = t; end
                            step <= step + 1;
                        end
                        3: begin
                            if (stage % 2 == 0) begin
                                for (int k = 0; k < 4; k++) begin
                                    if (d[k] > d[k+4]) begin t = d[k]; d[k] = d[k+4]; d[k+4] = t; end
                                end
                            end else begin
                                for (int k = 0; k < 4; k++) begin
                                    if (d[k] < d[k+4]) begin t = d[k]; d[k] = d[k+4]; d[k+4] = t; end
                                end
                            end
                            step <= step + 1;
                        end
                        4: begin
                            if (stage % 2 == 0) begin
                                if (d[0] > d[2]) begin t = d[0]; d[0] = d[2]; d[2] = t; end
                                if (d[1] > d[3]) begin t = d[1]; d[1] = d[3]; d[3] = t; end
                                if (d[4] > d[6]) begin t = d[4]; d[4] = d[6]; d[6] = t; end
                                if (d[5] > d[7]) begin t = d[5]; d[5] = d[7]; d[7] = t; end
                            end else begin
                                if (d[0] < d[2]) begin t = d[0]; d[0] = d[2]; d[2] = t; end
                                if (d[1] < d[3]) begin t = d[1]; d[1] = d[3]; d[3] = t; end
                                if (d[4] < d[6]) begin t = d[4]; d[4] = d[6]; d[6] = t; end
                                if (d[5] < d[7]) begin t = d[5]; d[5] = d[7]; d[7] = t; end
                            end
                            step <= step + 1;
                        end
                        5: begin
                            if (stage % 2 == 0) begin
                                for (int k = 0; k < 7; k += 2) begin
                                    if (d[k] > d[k+1]) begin t = d[k]; d[k] = d[k+1]; d[k+1] = t; end
                                end
                            end else begin
                                for (int k = 0; k < 7; k += 2) begin
                                    if (d[k] < d[k+1]) begin t = d[k]; d[k] = d[k+1]; d[k+1] = t; end
                                end
                            end
                            step <= 0;
                            state <= DONE;
                        end
                        default: step <= 0;
                    endcase
                end

                DONE: begin
                    for (int k = 0; k < 8; k++) begin
                        out[stage*8*BITWIDTH + k*BITWIDTH +: BITWIDTH] <= d[k];
                    end
                    if (stage == (ELEMENTS/8 - 1)) begin
                        state <= IDLE;
                        done_o <= 1;
                    end else begin
                        stage <= stage + 1;
                        state <= SETUP;
                    end
                end

                default: state <= START;
            endcase
        end
    end
endmodule

