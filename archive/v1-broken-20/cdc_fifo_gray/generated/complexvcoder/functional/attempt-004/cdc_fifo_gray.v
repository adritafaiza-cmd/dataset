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

    localparam DEPTH = 2**LOG_DEPTH;

    // Internal signals
    logic [WIDTH-1:0] src_gray_out;
    logic [WIDTH-1:0] dst_gray_in;
    logic [LOG_DEPTH-1:0] src_ptr;
    logic [LOG_DEPTH-1:0] dst_ptr;
    logic [LOG_DEPTH-1:0] src_count;
    logic [LOG_DEPTH-1:0] dst_count;
    logic [LOG_DEPTH-1:0] src_gray_ptr;
    logic [LOG_DEPTH-1:0] dst_gray_ptr;
    logic [LOG_DEPTH-1:0] sync_cnt;

    // Gray encoder and decoder
    logic [WIDTH-1:0] gray_code;
    logic [WIDTH-1:0] inv_gray_code;

    // FIFOs
    logic [WIDTH-1:0] fifo [0:DEPTH-1];
    logic [LOG_DEPTH-1:0] read_ptr;
    logic [LOG_DEPTH-1:0] write_ptr;

    // Clock domain crossing for src_gray_out
    logic [WIDTH-1:0] src_gray_out_sync [0:SYNC_STAGES-1];
    logic [WIDTH-1:0] src_gray_out_gray [0:SYNC_STAGES-1];

    // Clock domain crossing for dst_gray_in
    logic [WIDTH-1:0] dst_gray_in_sync [0:SYNC_STAGES-1];
    logic [WIDTH-1:0] dst_gray_in_gray [0:SYNC_STAGES-1];

    // Clock domain crossing for src_ptr and dst_ptr
    logic [LOG_DEPTH-1:0] src_ptr_sync [0:SYNC_STAGES-1];
    logic [LOG_DEPTH-1:0] dst_ptr_sync [0:SYNC_STAGES-1];

    // Clock domain crossing for src_count and dst_count
    logic [LOG_DEPTH-1:0] src_count_sync [0:SYNC_STAGES-1];
    logic [LOG_DEPTH-1:0] dst_count_sync [0:SYNC_STAGES-1];

    // Clock domain crossing for read_ptr and write_ptr
    logic [LOG_DEPTH-1:0] read_ptr_sync [0:SYNC_STAGES-1];
    logic [LOG_DEPTH-1:0] write_ptr_sync [0:SYNC_STAGES-1];

    // Gray encoder
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_out <= 0;
        end else begin
            src_gray_out <= gray_code;
        end
    end

    assign gray_code = src_data_i ^ (src_data_i >> 1);

    // Gray decoder
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_in <= 0;
        end else begin
            dst_gray_in <= inv_gray_code;
        end
    end

    assign inv_gray_code = dst_gray_in ^ (dst_gray_in >> 1);

    // FIFO write and read pointers
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr <= 0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                write_ptr <= write_ptr + 1;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr <= 0;
        end else begin
            if (dst_ready_i && dst_valid_o) begin
                read_ptr <= read_ptr + 1;
            end
        end
    end

    // FIFO data storage
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo[write_ptr] <= 0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                fifo[write_ptr] <= src_gray_out;
            end
        end
    end

    // FIFO output
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else begin
            if (dst_valid_o) begin
                dst_data_o <= fifo[read_ptr];
            end
        end
    end

    // Sync stages for src_gray_out
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_gray_out
            always_ff @(posedge src_clk_i) begin
                src_gray_out_sync[i] <= src_gray_out;
            end
            always_ff @(posedge dst_clk_i) begin
                src_gray_out_gray[i] <= src_gray_out_sync[i];
            end
        end
    endgenerate

    // Sync stages for dst_gray_in
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_gray_in
            always_ff @(posedge dst_clk_i) begin
                dst_gray_in_sync[i] <= dst_gray_in;
            end
            always_ff @(posedge src_clk_i) begin
                dst_gray_in_gray[i] <= dst_gray_in_sync[i];
            end
        end
    endgenerate

    // Sync stages for src_ptr and dst_ptr
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_ptr
            always_ff @(posedge src_clk_i) begin
                src_ptr_sync[i] <= src_ptr;
            end
            always_ff @(posedge dst_clk_i) begin
                src_ptr_gray[i] <= src_ptr_sync[i];
            end
        end
    endgenerate

    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_ptr
            always_ff @(posedge dst_clk_i) begin
                dst_ptr_sync[i] <= dst_ptr;
            end
            always_ff @(posedge src_clk_i) begin
                dst_ptr_gray[i] <= dst_ptr_sync[i];
            end
        end
    endgenerate

    // Sync stages for src_count and dst_count
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_count
            always_ff @(posedge src_clk_i) begin
                src_count_sync[i] <= src_count;
            end
            always_ff @(posedge dst_clk_i) begin
                src_count_gray[i] <= src_count_sync[i];
            end
        end
    endgenerate

    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_count
            always_ff @(posedge dst_clk_i) begin
                dst_count_sync[i] <= dst_count;
            end
            always_ff @(posedge src_clk_i) begin
                dst_count_gray[i] <= dst_count_sync[i];
            end
        end
    endgenerate

    // Sync stages for read_ptr and write_ptr
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_ptr
            always_ff @(posedge src_clk_i) begin
                read_ptr_sync[i] <= read_ptr;
            end
            always_ff @(posedge dst_clk_i) begin
                read_ptr_gray[i] <= read_ptr_sync[i];
            end
        end
    endgenerate

    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_ptr
            always_ff @(posedge dst_clk_i) begin
                write_ptr_sync[i] <= write_ptr;
            end
            always_ff @(posedge src_clk_i) begin
                write_ptr_gray[i] <= write_ptr_sync[i];
            end
        end
    endgenerate

    // Ready and valid logic
    assign src_ready_o = (src_count < DEPTH);
    assign dst_valid_o = (dst_count > 0);

endmodule
