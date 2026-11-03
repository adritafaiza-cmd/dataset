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

    // Internal signals
    logic [LOG_DEPTH-1:0] wr_ptr;
    logic [LOG_DEPTH-1:0] rd_ptr;
    logic [LOG_DEPTH:0]   count;
    logic                 full;
    logic                 empty;
    logic [WIDTH-1:0]     mem [0:2**LOG_DEPTH-1];

    // Source domain logic
    logic [LOG_DEPTH-1:0] wr_ptr_reg;
    logic                 wr_en;
    logic                 wr_ack;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_reg <= 0;
        end else begin
            if (wr_en && wr_ack) begin
                wr_ptr_reg <= wr_ptr_reg + 1;
            end
        end
    end

    assign wr_en = src_valid_i && src_ready_o && !full;
    assign wr_ack = !empty;

    // Destination domain logic
    logic [LOG_DEPTH-1:0] rd_ptr_reg;
    logic                 rd_en;
    logic                 rd_ack;

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_reg <= 0;
        end else begin
            if (rd_en && rd_ack) begin
                rd_ptr_reg <= rd_ptr_reg + 1;
            end
        end
    end

    assign rd_en = dst_ready_i && dst_valid_o && !empty;
    assign rd_ack = !full;

    // FIFO full and empty flags
    assign full = count == 2**LOG_DEPTH;
    assign empty = count == 0;

    // FIFO count
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            count <= 0;
        end else begin
            if (wr_en && wr_ack) begin
                count <= count + 1;
            end else if (rd_en && rd_ack) begin
                count <= count - 1;
            end
        end
    end

    // Memory read/write
    assign mem[wr_ptr] = src_data_i;
    assign dst_data_o = mem[rd_ptr];

    // Ready signals
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;

endmodule
