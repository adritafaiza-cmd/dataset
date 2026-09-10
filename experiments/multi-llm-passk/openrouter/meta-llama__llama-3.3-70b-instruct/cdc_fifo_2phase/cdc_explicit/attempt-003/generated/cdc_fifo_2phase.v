module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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

    reg [WIDTH-1:0] fifo [DEPTH-1:0];
    reg [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
    reg [LOG_DEPTH-1:0] wr_ptr_gray, rd_ptr_gray;
    reg [LOG_DEPTH-1:0] wr_ptr_sync, rd_ptr_sync;
    reg full, empty;
    reg [WIDTH-1:0] data_out;
    reg valid_out;

    // Gray encoding
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_gray <= 0;
        end else begin
            wr_ptr_gray <= (wr_ptr + 1) ^ wr_ptr;
        end
    end

    // Synchronize wr_ptr_gray to destination clock domain
    reg [1:0] wr_ptr_sync_reg;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_sync_reg <= 0;
        end else begin
            wr_ptr_sync_reg[0] <= wr_ptr_gray;
            wr_ptr_sync_reg[1] <= wr_ptr_sync_reg[0];
        end
    end
    assign wr_ptr_sync = wr_ptr_sync_reg[1];

    // Gray decoding
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else if (wr_ptr_sync != rd_ptr_gray) begin
            rd_ptr <= wr_ptr_sync ^ (rd_ptr_gray + 1);
        end
    end

    // Gray encoding
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_gray <= 0;
        end else begin
            rd_ptr_gray <= (rd_ptr + 1) ^ rd_ptr;
        end
    end

    // Synchronize rd_ptr_gray to source clock domain
    reg [1:0] rd_ptr_sync_reg;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_sync_reg <= 0;
        end else begin
            rd_ptr_sync_reg[0] <= rd_ptr_gray;
            rd_ptr_sync_reg[1] <= rd_ptr_sync_reg[0];
        end
    end
    assign rd_ptr_sync = rd_ptr_sync_reg[1];

    // FIFO write logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            full <= 0;
        end else if (src_valid_i && !full) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
            if (wr_ptr == DEPTH - 1) begin
                full <= 1;
            end
        end
    end

    // FIFO read logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            empty <= 1;
            valid_out <= 0;
            data_out <= 0;
        end else if (dst_ready_i && !empty) begin
            data_out <= fifo[rd_ptr];
            valid_out <= 1;
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == DEPTH - 1) begin
                rd_ptr <= 0;
            end
            if (rd_ptr == wr_ptr_sync) begin
                empty <= 1;
                valid_out <= 0;
            end
        end else if (empty && !valid_out) begin
            valid_out <= 0;
        end
    end

    // Output logic
    assign dst_data_o = data_out;
    assign dst_valid_o = valid_out;

    // Input logic
    assign src_ready_o = !full && (rd_ptr_sync != wr_ptr);

endmodule
