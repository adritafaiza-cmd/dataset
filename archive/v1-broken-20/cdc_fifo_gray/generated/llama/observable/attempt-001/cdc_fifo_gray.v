module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0]         mem [DEPTH-1:0];
    reg [LOG_DEPTH-1:0]     src_ptr;
    reg [LOG_DEPTH-1:0]     dst_ptr;
    reg [LOG_DEPTH-1:0]     src_ptr_gray;
    reg [LOG_DEPTH-1:0]     dst_ptr_gray;
    reg [SYNC_STAGES-1:0]   src_ptr_sync;
    reg [SYNC_STAGES-1:0]   dst_ptr_sync;
    reg [WIDTH-1:0]         data_out;
    reg                     full;
    reg                     empty;

    assign src_ready_o = ~full;
    assign dst_valid_o = ~empty;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_ptr <= 0;
            src_ptr_gray <= 0;
            full <= 0;
        end else begin
            if (src_valid_i && ~full) begin
                mem[src_ptr] <= src_data_i;
                src_ptr <= src_ptr + 1;
                if (src_ptr == DEPTH - 1) begin
                    full <= 1;
                end
            end
            src_ptr_gray <= src_ptr_gray + (src_ptr ^ (src_ptr >> 1));
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            dst_ptr <= 0;
            dst_ptr_gray <= 0;
            empty <= 1;
        end else begin
            if (dst_ready_i && ~empty) begin
                dst_data_o <= mem[dst_ptr];
                dst_ptr <= dst_ptr + 1;
                if (dst_ptr == DEPTH - 1) begin
                    empty <= 0;
                end
            end
            dst_ptr_gray <= dst_ptr_gray + (dst_ptr ^ (dst_ptr >> 1));
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_ptr_sync <= 0;
        end else begin
            src_ptr_sync[0] <= src_ptr_gray;
            for (genvar i = 1; i < SYNC_STAGES; i++) begin
                src_ptr_sync[i] <= src_ptr_sync[i-1];
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            dst_ptr_sync <= 0;
        end else begin
            dst_ptr_sync[0] <= dst_ptr_gray;
            for (genvar i = 1; i < SYNC_STAGES; i++) begin
                dst_ptr_sync[i] <= dst_ptr_sync[i-1];
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            empty <= 1;
        end else if (dst_ready_i && ~empty) begin
            if (dst_ptr_sync[SYNC_STAGES-1] == src_ptr_sync[SYNC_STAGES-1]) begin
                empty <= 1;
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            full <= 0;
        end else if (src_valid_i && ~full) begin
            if (dst_ptr_sync[SYNC_STAGES-1] == src_ptr_sync[SYNC_STAGES-1] - 1) begin
                full <= 1;
            end
        end
    end

endmodule
