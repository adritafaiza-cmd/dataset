module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    reg [WIDTH-1:0]         fifo [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0]     wr_ptr;
    reg [LOG_DEPTH-1:0]     rd_ptr;
    reg [LOG_DEPTH-1:0]     wr_ptr_gray;
    reg [LOG_DEPTH-1:0]     rd_ptr_gray;
    reg [LOG_DEPTH-1:0]     wr_ptr_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0]     rd_ptr_sync [SYNC_STAGES-1:0];
    reg [WIDTH-1:0]         data_sync [SYNC_STAGES-1:0];
    reg                     src_clear_pending;
    reg                     dst_clear_pending;
    reg                     src_empty;
    reg                     dst_empty;
    reg                     src_full;
    reg                     dst_valid;
    reg                     src_ready;

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;
    assign src_ready_o = src_ready;
    assign dst_data_o = data_sync[SYNC_STAGES-1];
    assign dst_valid_o = dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b1;
            src_empty <= 1'b1;
            src_full <= 1'b0;
            src_ready <= 1'b0;
            wr_ptr <= {LOG_DEPTH{1'b0}};
            wr_ptr_gray <= {LOG_DEPTH{1'b0}};
        end else if (src_clear_i) begin
            src_clear_pending <= 1'b1;
            src_empty <= 1'b1;
            src_full <= 1'b0;
            src_ready <= 1'b0;
            wr_ptr <= {LOG_DEPTH{1'b0}};
            wr_ptr_gray <= {LOG_DEPTH{1'b0}};
        end else begin
            if (src_valid_i && src_ready) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1'b1;
                wr_ptr_gray <= gray_encode(wr_ptr);
                if (wr_ptr == {LOG_DEPTH{1'b1}} - 1'b1) begin
                    src_full <= 1'b1;
                end else begin
                    src_full <= 1'b0;
                end
            end
            if (src_empty &&!src_valid_i) begin
                src_empty <= 1'b1;
            end else if (src_valid_i && src_ready) begin
                src_empty <= 1'b0;
            end
            if (!src_clear_i && src_empty &&!src_valid_i) begin
                src_clear_pending <= 1'b0;
            end
            if (src_empty || src_full) begin
                src_ready <= 1'b0;
            end else begin
                src_ready <= 1'b1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b1;
            dst_empty <= 1'b1;
            dst_valid <= 1'b0;
        end else if (dst_clear_i) begin
            dst_clear_pending <= 1'b1;
            dst_empty <= 1'b1;
            dst_valid <= 1'b0;
        end else begin
            if (dst_ready_i && dst_valid) begin
                rd_ptr <= rd_ptr + 1'b1;
                rd_ptr_gray <= gray_encode(rd_ptr);
                if (rd_ptr == {LOG_DEPTH{1'b1}} - 1'b1) begin
                    dst_empty <= 1'b1;
                end else begin
                    dst_empty <= 1'b0;
                end
            end
            if (dst_empty &&!dst_ready_i) begin
                dst_empty <= 1'b1;
            end else if (dst_ready_i && dst_valid) begin
                dst_empty <= 1'b0;
            end
            if (!dst_clear_i && dst_empty &&!dst_ready_i) begin
                dst_clear_pending <= 1'b0;
            end
            if (dst_empty) begin
                dst_valid <= 1'b0;
            end else begin
                dst_valid <= 1'b1;
            end
        end
    end

    always @(posedge src_clk_i) begin
        if (src_clear_i) begin
            wr_ptr_sync[0] <= {LOG_DEPTH{1'b0}};
        end else begin
            wr_ptr_sync[0] <= wr_ptr_gray;
        end
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin
            always @(posedge dst_clk_i) begin
                wr_ptr_sync[i] <= wr_ptr_sync[i-1];
            end
        end
    endgenerate

    always @(posedge dst_clk_i) begin
        if (dst_clear_i) begin
            rd_ptr_sync[0] <= {LOG_DEPTH{1'b0}};
        end else begin
            rd_ptr_sync[0] <= rd_ptr_gray;
        end
    end

    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin
            always @(posedge src_clk_i) begin
                rd_ptr_sync[i] <= rd_ptr_sync[i-1];
            end
        end
    endgenerate

    always @(posedge src_clk_i) begin
        if (src_clear_i) begin
            data_sync[0] <= {WIDTH{1'b0}};
        end else if (src_valid_i && src_ready) begin
            data_sync[0] <= src_data_i;
        end
    end

    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin
            always @(posedge dst_clk_i) begin
                data_sync[i] <= data_sync[i-1];
            end
        end
    endgenerate

    function [LOG_DEPTH-1:0] gray_encode;
        input [LOG_DEPTH-1:0] bin;
        reg [LOG_DEPTH-1:0] gray;
        begin
            gray = bin ^ (bin >> 1);
            gray_encode = gray;
        end
    endfunction

endmodule
