module Bitonic_Sort2 #(
    parameter BITWIDTH = 16,
    parameter ELEMENTS = 8
)(
    input clk,
    input rst_low,
    input enable,
    input [ELEMENTS*BITWIDTH-1:0] input_data,
    output reg done_Sort,
    output reg [ELEMENTS*BITWIDTH-1:0] data_out
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

    always @(posedge clk or negedge rst_low) begin
        if (!rst_low) begin
            data_out <= 0;
            done_Sort <= 0;
            state <= START;
            sort_step <= 0;
            // Initialize array to avoid latches
            for (int i = 0; i < ELEMENTS; i++) 
                d[i] <= 0;
        end else begin
            case (state)
                START: begin
                    done_Sort <= 0;
                    data_out <= 0;
                    sort_step <= 0;
                    if (enable) state <= SETUP;
                end
                
                SETUP: begin
                    // Load input into internal array
                    for (int i = 0; i < ELEMENTS; i++) begin
                        d[i] <= input_data[i*BITWIDTH +: BITWIDTH];
                    end
                    state <= SORT;
                end
                
                SORT: begin
                    case (sort_step)
                        // Step 0: Create alternating increasing/decreasing pairs
                        0: begin
                            for (int i = 0; i < ELEMENTS; i += 4) begin
                                // First pair in group (increasing)
                                if (d[i] > d[i+1]) begin
                                    {d[i], d[i+1]} <= {d[i+1], d[i]};
                                end
                                // Second pair in group (decreasing)
                                if (d[i+2] < d[i+3]) begin
                                    {d[i+2], d[i+3]} <= {d[i+3], d[i+2]};
                                end
                            end
                            sort_step <= 1;
                        end
                        
                        // Step 1: Merge into size 4 bitonic sequences
                        1: begin
                            // First half (0-3): create bitonic sequence
                            if (d[0] > d[2]) {d[0], d[2]} <= {d[2], d[0]};
                            if (d[1] > d[3]) {d[1], d[3]} <= {d[3], d[1]};
                            
                            // Second half (4-7): create bitonic sequence
                            if (d[4] < d[6]) {d[4], d[6]} <= {d[6], d[4]};
                            if (d[5] < d[7]) {d[5], d[7]} <= {d[7], d[5]};
                            
                            sort_step <= 2;
                        end
                        
                        // Step 2: Sort the size 4 sequences
                        2: begin
                            // First half (0-3): ascending sort
                            if (d[0] > d[1]) {d[0], d[1]} <= {d[1], d[0]};
                            if (d[2] > d[3]) {d[2], d[3]} <= {d[3], d[2]};
                            
                            // Second half (4-7): descending sort
                            if (d[4] < d[5]) {d[4], d[5]} <= {d[5], d[4]};
                            if (d[6] < d[7]) {d[6], d[7]} <= {d[7], d[6]};
                            
                            sort_step <= 3;
                        end
                        
                        // Step 3: Merge into single bitonic sequence of size 8
                        3: begin
                            for (int i = 0; i < 4; i++) begin
                                if (d[i] > d[i+4]) begin
                                    {d[i], d[i+4]} <= {d[i+4], d[i]};
                                end
                            end
                            sort_step <= 4;
                        end
                        
                        // Step 4: Sort the first and second halves
                        4: begin
                            // First half (0-3): compare distance 2
                            if (d[0] > d[2]) {d[0], d[2]} <= {d[2], d[0]};
                            if (d[1] > d[3]) {d[1], d[3]} <= {d[3], d[1]};
                            
                            // Second half (4-7): compare distance 2
                            if (d[4] > d[6]) {d[4], d[6]} <= {d[6], d[4]};
                            if (d[5] > d[7]) {d[5], d[7]} <= {d[7], d[5]};
                            
                            sort_step <= 5;
                        end
                        
                        // Step 5: Final adjacent sort
                        5: begin
                            for (int i = 0; i < ELEMENTS; i += 2) begin
                                if (d[i] > d[i+1]) begin
                                    {d[i], d[i+1]} <= {d[i+1], d[i]};
                                end
                            end
                            state <= DONE;
                        end
                    endcase
                end
                
                DONE: begin
                    // Output sorted array
                    data_out <= {d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7]};
                    done_Sort <= 1;
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

