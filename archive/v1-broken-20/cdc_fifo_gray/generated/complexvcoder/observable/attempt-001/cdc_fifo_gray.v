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

    // Internal signals
    logic [WIDTH-1:0]      fifo_mem [2**LOG_DEPTH-1:0];
    logic [LOG_DEPTH:0]    wr_ptr, rd_ptr;
    logic                  wr_en, rd_en;
    logic                  full, empty;
    logic [SYNC_STAGES-1:0] src_valid_sync, src_ready_sync;
    logic [SYNC_STAGES-1:0] dst_valid_sync, dst_ready_sync;

    // Source clock domain logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            full <= 0;
        end else begin
            if (src_valid_i && src_ready_o && !full) begin
                fifo_mem[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == 2**LOG_DEPTH - 1) begin
                    wr_ptr <= 0;
                end
                full <= wr_ptr == rd_ptr;
            end
        end
    end

    // Destination clock domain logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            empty <= 1;
        end else begin
            if (dst_valid_o && dst_ready_i && !empty) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == 2**LOG_DEPTH - 1) begin
                    rd_ptr <= 0;
                end
                empty <= wr_ptr == rd_ptr;
            end
        end
    end

    // Flow control
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;

    // Synchronization for signals crossing clock domains
    generate
        generate
            if (SYNC_STAGES > 0) begin
                sync_block #(.WIDTH(1)) src_valid_sync_inst (
                    .clk_i(src_clk_i),
                    .rst_ni(src_rst_ni),
                    .data_i(src_valid_i),
                    .data_o(src_valid_sync[0])
                );
                sync_block #(.WIDTH(1)) src_ready_sync_inst (
                    .clk_i(src_clk_i),
                    .rst_ni(src_rst_ni),
                    .data_i(src_ready_o),
                    .data_o(src_ready_sync[0])
                );
                sync_block #(.WIDTH(1)) dst_valid_sync_inst (
                    .clk_i(dst_clk_i),
                    .rst_ni(dst_rst_ni),
                    .data_i(dst_valid_o),
                    .data_o(dst_valid_sync[0])
                );
                sync_block #(.WIDTH(1)) dst_ready_sync_inst (
                    .clk_i(dst_clk_i),
                    .rst_ni(dst_rst_ni),
                    .data_i(dst_ready_i),
                    .data_o(dst_ready_sync[0])
                );
                // Additional synchronization stages if needed
                generate
                    generate
                        if (SYNC_STAGES > 1) begin
                            sync_block #(.WIDTH(1)) src_valid_sync_inst2 (
                                .clk_i(src_clk_i),
                                .rst_ni(src_rst_ni),
                                .data_i(src_valid_sync[0]),
                                .data_o(src_valid_sync[1])
                            );
                            sync_block #(.WIDTH(1)) src_ready_sync_inst2 (
                                .clk_i(src_clk_i),
                                .rst_ni(src_rst_ni),
                                .data_i(src_ready_sync[0]),
                                .data_o(src_ready_sync[1])
                            );
                            sync_block #(.WIDTH(1)) dst_valid_sync_inst2 (
                                .clk_i(dst_clk_i),
                                .rst_ni(dst_rst_ni),
                                .data_i(dst_valid_sync[0]),
                                .data_o(dst_valid_sync[1])
                            );
                            sync_block #(.WIDTH(1)) dst_ready_sync_inst2 (
                                .clk_i(dst_clk_i),
                                .rst_ni(dst_rst_ni),
                                .data_i(dst_ready_sync[0]),
                                .data_o(dst_ready_sync[1])
                            );
                        end
                    end
                endgenerate
            end
        end
    endgenerate

    // Output data
    assign dst_data_o = fifo_mem[rd_ptr];

endmodule

module sync_block #(
    parameter WIDTH = 1
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     data_i,
    output reg [WIDTH-1:0] data_o
);
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_o <= 0;
        end else begin
            data_o <= data_i;
        end
    end
endmodule
