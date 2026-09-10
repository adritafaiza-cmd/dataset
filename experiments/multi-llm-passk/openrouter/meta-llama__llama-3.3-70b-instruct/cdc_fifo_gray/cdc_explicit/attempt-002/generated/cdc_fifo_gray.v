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

    reg [WIDTH-1:0]         fifo_data [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0]    fifo_ptr_wr;
    reg [LOG_DEPTH-1:0]    fifo_ptr_rd;
    reg [LOG_DEPTH-1:0]    fifo_ptr_rd_gray;
    reg [LOG_DEPTH-1:0]    fifo_ptr_wr_gray;
    reg [LOG_DEPTH:0]      fifo_cnt;
    reg                    src_ready_int;
    reg                    dst_valid_int;
    reg [WIDTH-1:0]         dst_data_int;
    reg [SYNC_STAGES-1:0]  src_valid_sync;
    reg [SYNC_STAGES-1:0]  dst_ready_sync;
    reg [SYNC_STAGES-1:0]  src_rst_ni_sync;
    reg [SYNC_STAGES-1:0]  dst_rst_ni_sync;

    assign src_ready_o = src_ready_int;
    assign dst_data_o = dst_data_int;
    assign dst_valid_o = dst_valid_int;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_valid_sync[0] <= src_valid_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_valid_sync[i] <= src_valid_sync[i-1];
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ready_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_ready_sync[0] <= dst_ready_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_ready_sync[i] <= dst_ready_sync[i-1];
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rst_ni_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_rst_ni_sync[0] <= src_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_rst_ni_sync[i] <= src_rst_ni_sync[i-1];
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rst_ni_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_rst_ni_sync[0] <= dst_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_rst_ni_sync[i] <= dst_rst_ni_sync[i-1];
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_ptr_wr <= {LOG_DEPTH{1'b0}};
            fifo_ptr_wr_gray <= {LOG_DEPTH{1'b0}};
            fifo_cnt <= {LOG_DEPTH+1{1'b0}};
            src_ready_int <= 1'b1;
        end else if (src_valid_i && src_ready_int) begin
            fifo_data[fifo_ptr_wr] <= src_data_i;
            fifo_ptr_wr <= fifo_ptr_wr + 1'b1;
            fifo_ptr_wr_gray <= gray_encode(fifo_ptr_wr);
            fifo_cnt <= fifo_cnt + 1'b1;
            if (fifo_cnt == 2**LOG_DEPTH) begin
                src_ready_int <= 1'b0;
            end
        end else if (!src_valid_i && src_ready_int) begin
            if (fifo_cnt == 2**LOG_DEPTH) begin
                src_ready_int <= 1'b0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            fifo_ptr_rd <= {LOG_DEPTH{1'b0}};
            fifo_ptr_rd_gray <= {LOG_DEPTH{1'b0}};
            dst_valid_int <= 1'b0;
            dst_data_int <= {WIDTH{1'b0}};
        end else if (dst_ready_i && dst_valid_int) begin
            fifo_ptr_rd <= fifo_ptr_rd + 1'b1;
            fifo_ptr_rd_gray <= gray_encode(fifo_ptr_rd);
            fifo_cnt <= fifo_cnt - 1'b1;
            dst_valid_int <= (fifo_cnt > 1'b0);
            dst_data_int <= fifo_data[fifo_ptr_rd];
        end else if (!dst_ready_i && dst_valid_int) begin
            dst_valid_int <= (fifo_cnt > 1'b0);
        end
    end

    function [LOG_DEPTH-1:0] gray_encode;
        input [LOG_DEPTH-1:0] bin;
        reg [LOG_DEPTH-1:0] gray;
        begin
            gray = bin ^ (bin >> 1);
            gray_encode = gray;
        end
    endfunction

    function [LOG_DEPTH-1:0] gray_decode;
        input [LOG_DEPTH-1:0] gray;
        reg [LOG_DEPTH-1:0] bin;
        begin
            bin[0] = gray[0];
            for (int i = 1; i < LOG_DEPTH; i++) begin
                bin[i] = gray[i] ^ bin[i-1];
            end
            gray_decode = bin;
        end
    endfunction

endmodule
