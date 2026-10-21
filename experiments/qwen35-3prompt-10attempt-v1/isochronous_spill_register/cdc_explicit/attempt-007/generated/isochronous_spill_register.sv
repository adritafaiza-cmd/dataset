```verilog
module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output reg [WIDTH-1:0] dst_data_o
);

    // Internal signals for CDC-safe state storage
    // Using 2-deep FIFO logic:
    // src_domain: stores valid and data until ready is asserted
    // dst_domain: stores valid and data until ready is consumed
    
    reg src_valid_reg;
    reg [WIDTH-1:0] src_data_reg;
    reg dst_valid_reg;
    reg [WIDTH-1:0] dst_data_reg;
    
    // State machine for source domain to manage ready handshake
    // States: IDLE, WAIT_FOR_DST
    reg [1:0] src_state;
    parameter IDLE = 2'b00, WAIT_FOR_DST = 2'b01;
    
    // State machine for destination domain to manage valid assertion
    // States: IDLE, WAIT_FOR_SRC
    reg [1:0] dst_state;
    parameter DST_IDLE = 2'b00, DST_WAIT_FOR_SRC = 2'b01;

    // Source Domain Logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
            src_data_reg <= 1'b0;
            src_state <= IDLE;
            src_ready_o <= 1'b0;
        end else begin
            case (src_state)
                IDLE: begin
                    if (src_valid_i) begin
                        src_valid_reg <= 1'b1;
                        src_data_reg <= src_data_i;
                        src_state <= WAIT_FOR_DST;
                    end
                    src_ready_o <= 1'b0;
                end
                
                WAIT_FOR_DST: begin
                    if (src_valid_reg && dst_ready_i) begin
                        src_valid_reg <= 1'b0;
                        src_state <= IDLE;
                        src_ready_o <= 1'b1;
                    end else if (src_valid_reg && !dst_ready_i) begin
                        src_ready_o <= 1'b0;
                    end else begin
                        src_ready_o <= 1'b0;
                    end
                end
            endcase
        end
    end

    // Destination Domain Logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            dst_data_reg <= 1'b0;
            dst_state <= DST_IDLE;
            dst_valid_o <= 1'b0;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    if (src_valid_reg) begin
                        dst_valid_reg <= 1'b1;
                        dst_data_reg <= src_data_reg;
                        dst_state <= DST_WAIT_FOR_SRC;
                    end
                    dst_valid_o <= 1'b0;
                end
                
                DST_WAIT_FOR_SRC: begin
                    if (dst_valid_reg && dst_ready_i) begin
                        dst_valid_reg <= 1'b0;
                        dst_state <= DST_IDLE;
                        dst_valid_o <= 1'b1;
                    end else if (dst_valid_reg && !dst_ready_i) begin
                        dst_valid_o <= 1'b0;
                    end else begin
                        dst_valid_o <= 1'b0;
                    end
                end
            endcase
        end
    end

    // Output assignment for destination data
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 1'b0;
        end else begin
            dst_data_o <= dst_data_reg;
        end
    end

endmodule
```<|im_end|>
