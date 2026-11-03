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
    logic [LOG_DEPTH:0]   cnt;
    logic [WIDTH-1:0]     mem [0:(1<<LOG_DEPTH)-1];
    logic                 full;
    logic                 empty;

    // Synchronizers for control signals
    logic [LOG_DEPTH-1:0] wr_ptr_sync;
    logic [LOG_DEPTH-1:0] rd_ptr_sync;
    logic [LOG_DEPTH:0]   cnt_sync;
    logic                 full_sync;
    logic                 empty_sync;

    // Synchronizers for data
    logic [WIDTH-1:0]     mem_sync [0:(1<<LOG_DEPTH)-1];

    // Clock-domain crossing for write pointer
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
        end else begin
            wr_ptr <= wr_ptr_sync;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_sync <= 0;
        end else begin
            wr_ptr_sync <= wr_ptr;
        end
    end

    // Clock-domain crossing for read pointer
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr <= 0;
        end else begin
            rd_ptr <= rd_ptr_sync;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_sync <= 0;
        end else begin
            rd_ptr_sync <= rd_ptr;
        end
    end

    // Clock-domain crossing for count
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            cnt <= 0;
        end else begin
            cnt <= cnt_sync;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            cnt_sync <= 0;
        end else begin
            cnt_sync <= cnt;
        end
    end

    // Clock-domain crossing for full flag
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            full <= 0;
        end else begin
            full <= full_sync;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            full_sync <= 0;
        end else begin
            full_sync <= full;
        end
    end

    // Clock-domain crossing for empty flag
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            empty <= 1;
        end else begin
            empty <= empty_sync;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            empty_sync <= 1;
        end else begin
            empty_sync <= empty;
        end
    end

    // Clock-domain crossing for memory
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            mem_sync <= '{default: 0};
        end else begin
            mem_sync[wr_ptr] <= src_data_i;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            mem <= '{default: 0};
        end else begin
            mem <= mem_sync;
        end
    end

    // Write logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            cnt <= 0;
            full <= 0;
        end else begin
            if (src_valid_i && src_ready_o && !full) begin
                wr_ptr <= wr_ptr + 1;
                cnt <= cnt + 1;
                if (cnt == (1<<LOG_DEPTH)) begin
                    full <= 1;
                end
            end
        end
    end

    // Read logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            cnt <= 0;
            empty <= 1;
        end else begin
            if (dst_valid_o && dst_ready_i && !empty) begin
                rd_ptr <= rd_ptr + 1;
                cnt <= cnt - 1;
                if (cnt == 0) begin
                    empty <= 1;
                end
            end
        end
    end

    // Output logic
    assign src_ready_o = !full_sync;
    assign dst_data_o = mem_sync[rd_ptr_sync];
    assign dst_valid_o = !empty_sync;

endmodule
