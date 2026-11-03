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
    logic [WIDTH-1:0]       mem [0:2**LOG_DEPTH-1];
    logic [LOG_DEPTH:0]     wr_ptr_gray, rd_ptr_gray;
    logic [LOG_DEPTH:0]     wr_ptr_gray_sync [0:SYNC_STAGES-1];
    logic [LOG_DEPTH:0]     rd_ptr_gray_sync [0:SYNC_STAGES-1];
    logic [LOG_DEPTH:0]     wr_ptr_gray_synced, rd_ptr_gray_synced;
    logic                   full, empty;
    logic                   wr_en, rd_en;

    // Gray code conversion functions
    function [LOG_DEPTH:0] to_gray;
        input [LOG_DEPTH:0] in;
        return in ^ (in >> 1);
    endfunction

    function [LOG_DEPTH:0] from_gray;
        input [LOG_DEPTH:0] in;
        logic [LOG_DEPTH:0] temp;
        temp = in;
        for (int i = 1; i <= LOG_DEPTH; i = i + 1)
            temp = temp ^ (temp >> i);
        return temp;
    endfunction

    // FIFO logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_gray <= {LOG_DEPTH{1'b0}};
            rd_ptr_gray <= {LOG_DEPTH{1'b0}};
        end else begin
            if (src_valid_i && src_ready_o && !full) begin
                mem[to_gray(wr_ptr_gray)] <= src_data_i;
                wr_ptr_gray <= wr_ptr_gray + 1;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_gray_synced <= {LOG_DEPTH{1'b0}};
            rd_ptr_gray_synced <= {LOG_DEPTH{1'b0}};
        end else begin
            wr_ptr_gray_synced <= wr_ptr_gray_sync[SYNC_STAGES-1];
            rd_ptr_gray_synced <= rd_ptr_gray_sync[SYNC_STAGES-1];
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_gray_sync <= {SYNC_STAGES{to_gray({LOG_DEPTH{1'b0}})}};
            rd_ptr_gray_sync <= {SYNC_STAGES{to_gray({LOG_DEPTH{1'b0}})}};
        end else begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                wr_ptr_gray_sync[i] <= wr_ptr_gray_sync[i+1];
                rd_ptr_gray_sync[i] <= rd_ptr_gray_sync[i+1];
            end
            wr_ptr_gray_sync[SYNC_STAGES-1] <= to_gray(wr_ptr_gray);
            rd_ptr_gray_sync[SYNC_STAGES-1] <= to_gray(rd_ptr_gray);
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            full <= 1'b0;
            empty <= 1'b1;
        end else begin
            if (rd_ptr_gray_synced == wr_ptr_gray_synced) begin
                full <= 1'b0;
                empty <= 1'b1;
            end else if (rd_ptr_gray_synced == (wr_ptr_gray_synced - 1)) begin
                full <= 1'b1;
                empty <= 1'b0;
            end else begin
                full <= 1'b0;
                empty <= 1'b0;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
            dst_valid_o <= 1'b0;
        end else begin
            if (dst_valid_i && dst_ready_o && !empty) begin
                dst_data_o <= mem[from_gray(rd_ptr_gray_synced)];
                rd_ptr_gray_synced <= rd_ptr_gray_synced + 1;
                dst_valid_o <= 1'b1;
            end else begin
                dst_valid_o <= 1'b0;
            end
        end
    end

    // Flow control
    assign src_ready_o = !full;
    assign dst_ready_i = !empty;

endmodule
