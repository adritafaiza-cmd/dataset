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
    reg [WIDTH-1:0]         mem [0:(2**LOG_DEPTH)-1];
    reg [LOG_DEPTH:0]       wr_ptr;
    reg [LOG_DEPTH:0]       rd_ptr;
    reg                     full;
    reg                     empty;

    // Source domain logic
    reg [WIDTH-1:0]         src_data_reg;
    reg                     src_valid_reg;
    reg                     src_ready_reg;

    // Destination domain logic
    reg [WIDTH-1:0]         dst_data_reg;
    reg                     dst_valid_reg;
    reg                     dst_ready_reg;

    // FIFO control logic
    reg                     wr_en;
    reg                     rd_en;

    // Gray encoding signals
    reg [LOG_DEPTH-1:0]     wr_gray;
    reg [LOG_DEPTH-1:0]     rd_gray;

    // Clock domain crossing for write pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
        end else begin
            if (wr_en && !full) begin
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    // Clock domain crossing for read pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else begin
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // Clock domain crossing for write enable
    assign wr_gray = (wr_ptr >> 1) ^ wr_ptr;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_en <= 0;
        end else begin
            wr_en <= (wr_gray == rd_gray) && src_valid_i && src_ready_o;
        end
    end

    // Clock domain crossing for read enable
    assign rd_gray = (rd_ptr >> 1) ^ rd_ptr;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_en <= 0;
        end else begin
            rd_en <= (wr_gray == rd_gray) && dst_ready_i;
        end
    end

    // FIFO memory and control logic
    assign full = (wr_ptr == rd_ptr) && !empty;
    assign empty = (wr_ptr == rd_ptr) && empty;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            mem <= {WIDTH{1'b0}};
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= src_data_i;
            end
        end
    end

    assign dst_data_o = mem[rd_ptr];
    assign dst_valid_o = !empty;

    // Output logic
    assign src_ready_o = !full;

endmodule
