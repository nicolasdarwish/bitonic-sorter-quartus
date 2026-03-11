module Bitonic_Sort3 #(parameter BITWIDTH = 16, parameter ELEMENTS = 8)(
    input clk,
    input rst_n,
    input en_i,
    input [ELEMENTS*BITWIDTH-1:0] in,
    output reg done_o,
    output reg [ELEMENTS*BITWIDTH-1:0] out
);

    // FSM states
    localparam  START       = 3'b000,
                SETUP       = 3'b001,
                SORT        = 3'b010,
                DONE        = 3'b011,
                IDLE        = 3'b111;

    reg [2:0] state;
    reg [2:0] sort_step; // Tracks current sorting step (0-5)
    reg [BITWIDTH-1:0] d[0:ELEMENTS-1]; // Internal data array

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 0;
            done_o <= 0;
            state <= START;
            sort_step <= 0;
            // Initialize array to avoid latches
            for (int i = 0; i < ELEMENTS; i++) d[i] <= 0;
        end else begin
            case (state)
                START: begin
                    done_o <= 0;
                    out <= 0;
                    sort_step <= 0;
                    if (en_i) state <= SETUP;
                end
                SETUP: begin
                    // Load input into internal array
                    for (int i = 0; i < ELEMENTS; i++) begin
                        d[i] <= in[i*BITWIDTH +: BITWIDTH];
                    end
                    state <= SORT;
                end
                SORT: begin
                    case (sort_step)
                        // Step 1: Sort adjacent pairs (ascending)
                        0: begin
                            for (int i = 0; i < ELEMENTS; i += 2) begin
                                if (d[i] > d[i+1]) begin
                                    {d[i], d[i+1]} <= {d[i+1], d[i]};
                                end
                            end
                            sort_step <= 1;
                        end
                        // Step 2: Merge into size 4 (first half ascending, second half descending)
                        1: begin
                            // First half (0-3): compare distance 2 (ascending)
                            if (d[0] > d[2]) {d[0], d[2]} <= {d[2], d[0]};
                            if (d[1] > d[3]) {d[1], d[3]} <= {d[3], d[1]};
                            // Second half (4-7): compare distance 2 (descending)
                            if (d[4] < d[6]) {d[4], d[6]} <= {d[6], d[4]};
                            if (d[5] < d[7]) {d[5], d[7]} <= {d[7], d[5]};
                            sort_step <= 2;
                        end
                        // Step 3: Sort adjacent pairs (first half ascending, second half descending)
                        2: begin
                            for (int i = 0; i < ELEMENTS; i += 2) begin
                                if (i < ELEMENTS/2) begin
                                    // First half: ascending
                                    if (d[i] > d[i+1]) {d[i], d[i+1]} <= {d[i+1], d[i]};
                                end else begin
                                    // Second half: descending
                                    if (d[i] < d[i+1]) {d[i], d[i+1]} <= {d[i+1], d[i]};
                                end
                            end
                            sort_step <= 3;
                        end
                        // Step 4: Merge into size 8 (ascending)
                        3: begin
                            for (int i = 0; i < ELEMENTS/2; i++) begin
                                if (d[i] > d[i+4]) {d[i], d[i+4]} <= {d[i+4], d[i]};
                            end
                            sort_step <= 4;
                        end
                        // Step 5: Merge into size 4 (ascending)
                        4: begin
                            for (int i = 0; i < ELEMENTS; i += 4) begin
                                // Compare distance 2
                                if (d[i] > d[i+2]) {d[i], d[i+2]} <= {d[i+2], d[i]};
                                if (d[i+1] > d[i+3]) {d[i+1], d[i+3]} <= {d[i+3], d[i+1]};
                            end
                            sort_step <= 5;
                        end
                        // Step 6: Final adjacent sort (ascending)
                        5: begin
                            for (int i = 0; i < ELEMENTS; i += 2) begin
                                if (d[i] > d[i+1]) {d[i], d[i+1]} <= {d[i+1], d[i]};
                            end
                            state <= DONE;
                        end
                    endcase
                end
                DONE: begin
                    // Output sorted array
                    out <= {d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7]};
                    done_o <= 1;
                    state <= IDLE;
                end
                IDLE: begin
                    // Remain idle until reset
                end
                default: state <= START;
            endcase
        end
    end
endmodule